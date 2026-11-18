@ storage.s - one lock for the external SPI flash and the FAT file system, and the storage side of
@ sharing the drive, powering off and resetting. Part of the FNIRSI 2C53T firmware rewrite.
@
@ Why (research 2026-11-18, STORAGE_DESIGN.md in the development tree): the vendor flash driver
@ (serial_flash_52.s) and FAT code (filesystem_0x.s) have no lock; the tasks and, in the vendor
@ firmware, the USB mass-storage handler in the USB interrupt share the SPI port 0x40003800, the chip
@ select PB12 and the 4 KB merge buffer 0x200012C0 of serial_device_write_merge, and the FAT volume
@ objects (2: 0x20002DA8, 3: 0x20003DDC) cache the boot data and a 4 KB window. Interleaved accesses
@ erase a sector and program another sector's data into it, abort commands half way, or return wrong
@ data; a reset or power-off between a sector erase and its last page program leaves the sector 0xFF.
@
@ - storage_lock / storage_unlock: recursive, owner = the current task record (word 0x200061E0, the
@   kernel's current-task pointer, written by psp_context_save_restore), count; the bookkeeping runs
@   with interrupts off; a task that finds the lock owned by another task sleeps 1 tick and retries.
@   Task context only (in this firmware no interrupt uses the flash: the mass-storage handler runs in
@   the usb task, usb_ctl.s msc_service). Before the scheduler starts there is one context only.
@ - Locked entry points: every flash / FAT function used outside its own file has its vendor body
@   renamed *_unlocked; the function of the old name below takes the lock, calls the body with r0..r3
@   unchanged (none of them takes stack arguments), releases the lock and returns r0. Calls inside the
@   FAT code nest the lock.
@ - storage_quiesce: before power-off and reset: takes the lock for good, writes back the window of
@   every mounted volume (fat_sync_volume) and takes the meter off the USB bus.
@ - storage_share / storage_unshare: before the drive is given to the host (open FILE_WRITE file
@   closed, volumes written back, V_HOSTDRV set) and after it is taken back (V_HOSTDRV cleared, the
@   volume the host had marked unmounted, so it is mounted again from the flash). While V_HOSTDRV is
@   set nothing on the meter writes the host's area of the flash: serial_device_write_merge refuses
@   it unless the mass-storage handler itself writes (V_INMSC), file_open refuses write modes there
@   (7, denied) and the volume is not written back.
@ - msc_service: the vendor mass-storage handler, in the usb task instead of the interrupt.
@ Rule: the usb task never holds the storage lock while it waits for a job (run_job): a job in the
@ display task takes the lock itself.

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

	.include "common/layout.inc"
	.include "src/parts/usb_ctl.inc"

	.equ	CURRENT_TASK,	0x200061E0	@ kernel: current task record
	.equ	VOLUMES,	0x20005FCC	@ volume object per drive digit 0..3 (0 = none)
	.equ	MSC_AREA_FLAG,	0x20001066	@ 0: the host sees drive 2:, else drive 3: (usb_82.s)
	.equ	USB_CFG,	0x40005C60	@ bit 1: D+ pull-up off

	.equ	storage_owner,	LOCK_VARS	@ owner task record (usb_ctl.inc: above the control variables,
	.equ	storage_count,	LOCK_VARS + 4	@ not cleared by usb_ctl_install; set up at start below)

	.section .text.usb_ctl,"ax",%progbits
	.p2align 2

@ storage_lock - waits until the lock is free or held by this task, then takes it (count + 1).
@ Keeps r0..r3 (the wrappers rely on it).
	.global	storage_lock
	.thumb_func
	.type	storage_lock, %function
storage_lock:
	push	{r0, r1, r2, r3, r4, lr}
1:	mrs	r4, primask
	cpsid	i
	ldr	r0, =storage_owner
	ldr	r1, [r0, #0]
	ldr	r2, =CURRENT_TASK
	ldr	r2, [r2]
	ldr	r3, [r0, #4]
	cbz	r3, 2f				@ free
	cmp	r1, r2
	beq	3f				@ this task already holds it
	msr	primask, r4			@ another task holds it: sleep 1 tick, try again
	movs	r0, #1
	bl	fn_08041390
	b	1b
2:	str	r2, [r0, #0]
3:	adds	r3, #1
	str	r3, [r0, #4]
	msr	primask, r4
	pop	{r0, r1, r2, r3, r4, pc}

@ storage_unlock - count - 1; the lock is free at 0. Keeps r0..r3.
	.global	storage_unlock
	.thumb_func
	.type	storage_unlock, %function
storage_unlock:
	push	{r0, r1, r2, r3, r4, lr}
	mrs	r4, primask
	cpsid	i
	ldr	r0, =storage_owner
	ldr	r3, [r0, #4]
	subs	r3, #1
	str	r3, [r0, #4]
	bne	1f
	str	r3, [r0, #0]
1:	msr	primask, r4
	pop	{r0, r1, r2, r3, r4, pc}

@ serial_device_interface_init - first flash call at start (system_bring_up, before
@ filesystem_startup_setup): clears the lock (its RAM is not initialised at power-on), then the vendor
@ interface set-up.
	.global	serial_device_interface_init
	.thumb_func
	.type	serial_device_interface_init, %function
serial_device_interface_init:
	ldr	r0, =storage_owner
	movs	r1, #0
	str	r1, [r0, #0]
	str	r1, [r0, #4]
	ldr	r0, =V				@ the drive belongs to the meter (V is cleared later,
	strb	r1, [r0, #V_HOSTDRV]		@ by usb_ctl_install)
	strb	r1, [r0, #V_INMSC]
	b	serial_device_interface_init_unlocked

@ LOCKED name - the function "name": storage_lock, name_unlocked(r0..r3), storage_unlock, r0.
	.macro	LOCKED name
	.global	\name
	.thumb_func
	.type	\name, %function
\name:
	push	{r4, lr}
	bl	storage_lock
	bl	\name\()_unlocked
	mov	r4, r0
	bl	storage_unlock
	mov	r0, r4
	pop	{r4, pc}
	.endm

	LOCKED	serial_device_read
	LOCKED	file_read
	LOCKED	file_write
	LOCKED	file_close
	LOCKED	file_seek
	LOCKED	dir_open
	LOCKED	dir_read_entry
	LOCKED	dir_create
	LOCKED	path_delete
	LOCKED	fat_sync_volume
	LOCKED	object_release
	LOCKED	filesystem_startup_setup
	LOCKED	fn_08033fbc

@ serial_device_write_merge - r0 = data, r1 = flash address, r2 = count: the vendor write, locked;
@ refused (nothing written, returns 0) while the host has the drive and the address is in its area,
@ unless the mass-storage handler writes for the host.
	.global	serial_device_write_merge
	.thumb_func
	.type	serial_device_write_merge, %function
serial_device_write_merge:
	push	{r4, lr}
	bl	storage_lock
	ldr	r4, =V
	ldrb	r3, [r4, #V_HOSTDRV]
	cbz	r3, 1f
	ldrb	r3, [r4, #V_INMSC]
	cbnz	r3, 1f
	mov	r3, r1
	bl	host_area			@ r12 = 1 when address r3 is in the host's area
	cmp	r12, #0
	beq	1f
	bl	storage_unlock
	movs	r0, #0
	pop	{r4, pc}
1:	bl	serial_device_write_merge_unlocked
	mov	r4, r0
	bl	storage_unlock
	mov	r0, r4
	pop	{r4, pc}

@ host_area - r3 = flash address; r12 = 1 when it lies in the area of the drive the host sees (2:
@ from 0x200000 when byte 0x20001066 is 0, else 3: below 0x200000). Keeps r0..r3.
	.thumb_func
host_area:
	ldr	r12, =MSC_AREA_FLAG
	ldrb	r12, [r12]
	cmp	r12, #0
	bne	1f
	cmp	r3, #0x200000
	ite	hs
	movhs	r12, #1
	movlo	r12, #0
	bx	lr
1:	cmp	r3, #0x200000
	ite	lo
	movlo	r12, #1
	movhs	r12, #0
	bx	lr

@ exposed_drive - r0 = the drive digit the host sees while it has the drive (2 or 3), 0xFF when the
@ meter has it. Keeps r1..r3.
	.thumb_func
exposed_drive:
	ldr	r0, =V
	ldrb	r0, [r0, #V_HOSTDRV]
	cbz	r0, 1f
	ldr	r0, =MSC_AREA_FLAG
	ldrb	r0, [r0]
	cmp	r0, #0
	ite	eq
	moveq	r0, #2
	movne	r0, #3
	bx	lr
1:	movs	r0, #0xFF
	bx	lr

@ file_open - r0 = file object, r1 = path, r2 = mode: the vendor open, locked; a mode with write or
@ create bits (0x1E) on the drive the host has answers 7 (denied).
	.global	file_open
	.thumb_func
	.type	file_open, %function
file_open:
	push	{r0, r1, r2, r4, r5, lr}
	bl	storage_lock
	tst	r2, #0x1E
	beq	1f
	bl	exposed_drive			@ r0 = drive the host has (keeps r1..r3)
	ldrb	r3, [r1, #1]			@ drive digit of "d:..." (no prefix: drive 0)
	cmp	r3, #':'
	ite	eq
	ldrbeq	r3, [r1, #0]
	movne	r3, #'0'
	sub	r3, r3, #'0'
	cmp	r3, r0
	bne	1f
	bl	storage_unlock
	movs	r0, #7
	b	9f
1:	ldmia	sp, {r0, r1, r2}
	bl	file_open_unlocked
	mov	r4, r0
	bl	storage_unlock
	mov	r0, r4
9:	add	sp, #12
	pop	{r4, r5, pc}

@ sync_volumes - fat_sync_volume for every mounted volume (object present, type byte non-zero), the
@ volume the host has excepted. The caller holds the lock.
	.thumb_func
sync_volumes:
	push	{r4, r5, r6, lr}
	ldr	r4, =VOLUMES
	movs	r5, #0
	bl	exposed_drive
	mov	r6, r0				@ r6 = drive not to write
1:	cmp	r5, r6
	beq	2f
	ldr	r0, [r4, r5, lsl #2]
	cbz	r0, 2f
	ldrb	r1, [r0, #0]
	cbz	r1, 2f
	bl	fat_sync_volume_unlocked
2:	adds	r5, #1
	cmp	r5, #4
	blo	1b
	pop	{r4, r5, r6, pc}

@ storage_quiesce - before power-off or reset: waits for the flash and file system to be idle and
@ keeps them (the lock is never released), closes the FILE_WRITE file and a staged-image transfer,
@ writes back every mounted
@ volume (not the one the host has), D+ pull-up off (the host stops). Runs before the vendor power-off
@ routine, which takes USB off the bus and turns interrupts off itself.
	.global	storage_quiesce
	.thumb_func
	.type	storage_quiesce, %function
storage_quiesce:
	push	{r0, r1, r2, r3, r4, lr}
	bl	storage_lock
	bl	write_close
	bl	read_close			@ usb_remote.s: FILE_READ file
	bl	fw_close			@ usb_ctl.s: a staged image being transferred is closed
	bl	sync_volumes
	ldr	r0, =USB_CFG
	ldr	r1, [r0]
	orr	r1, r1, #2
	str	r1, [r0]
	pop	{r0, r1, r2, r3, r4, pc}

@ power_off_request - the timer callbacks' power-off (auto shutdown fn_080406c8, low battery
@ fn_08009c78, keys_26.s): they run in the timer task, at the tick wrap with the scheduler suspended
@ (kernel_23.s timer_process_wrap), where waiting for the storage lock would halt. They post key code
@ 1 (power off, fn_08009fe0) to the key queue without waiting and return; the key task powers off.
@ A full queue loses the request: the callbacks repeat it at their next run (the counters stay past
@ their limits).
	.global	power_off_request
	.thumb_func
	.type	power_off_request, %function
power_off_request:
	push	{r0, lr}
	movs	r0, #1
	str	r0, [sp]
	ldr	r0, =KEY_QUEUE
	ldr	r0, [r0]
	mov	r1, sp
	movs	r2, #0
	bl	queue_send_timeout
	pop	{r0, pc}

@ save_settings_to_flash - every power-off (power key, auto shutdown, low battery, SETTINGS_SAVE) ends
@ here: storage_quiesce first, then the vendor routine (settings_53.s save_settings_to_flash_body,
@ which turns interrupts off and does not return). r0 (the settings marker) is kept.
	.global	save_settings_to_flash
	.thumb_func
	.type	save_settings_to_flash, %function
save_settings_to_flash:
	push	{r4, lr}
	bl	storage_quiesce
	pop	{r4, lr}
	b	save_settings_to_flash_body

@ settings_buffer_alloc - r0 = size (0x200): alloc_units_of_32_bytes, then (when it worked) the
@ first 0x200 bytes of the settings page 0x08006000 copied into the buffer. Returns the buffer or 0.
	.global	settings_buffer_alloc
	.thumb_func
	.type	settings_buffer_alloc, %function
settings_buffer_alloc:
	push	{r4, lr}
	bl	alloc_units_of_32_bytes
	cbz	r0, 9f
	ldr	r1, =0x08006000
	movs	r2, #0
1:	ldr	r3, [r1, r2]
	str	r3, [r0, r2]
	adds	r2, #4
	cmp	r2, #0x200
	blo	1b
9:	pop	{r4, pc}

@ settings_pack_done - in save_settings_to_flash_body, r10 = buffer, r1 = the last packed word:
@ stores it at +0x12C, compares the 0x200 buffer bytes with the page 0x08006000. Equal: Z set and
@ r4 = 0x40015434 (what the body's skip label .L08029d0c expects); different: Z clear, r4 kept. r0..r3
@ kept (the body's flash part writes r4 before it reads it).
	.global	settings_pack_done
	.thumb_func
	.type	settings_pack_done, %function
settings_pack_done:
	str	r1, [r10, #0x12C]
	push	{r0, r1, r2, r3, r5, lr}
	ldr	r0, =0x08006000
	movs	r1, #0
1:	ldr	r2, [r0, r1]
	ldr	r3, [r10, r1]
	cmp	r2, r3
	bne	2f
	adds	r1, #4
	cmp	r1, #0x200			@ Z set at the end: all equal
	blo	1b
	movw	r4, #0x5434
	movt	r4, #0x4001
2:	pop	{r0, r1, r2, r3, r5, pc}

@ storage_share - before the drive is given to the host: FILE_WRITE file and a staged-image transfer
@ closed (the transfer is void: V_FWOK and the position cleared), every mounted volume written back,
@ then V_HOSTDRV set (from here on the meter does not write the host's area).
	.global	storage_share
	.thumb_func
	.type	storage_share, %function
storage_share:
	push	{r4, lr}
	bl	storage_lock
	bl	write_close
	bl	read_close			@ usb_remote.s: FILE_READ file
	bl	fw_close			@ a staged image transfer ends: FW_END will refuse it
	ldr	r0, =V
	movs	r1, #0
	strb	r1, [r0, #V_FWOK]
	str	r1, [r0, #V_FWPOS]
	bl	sync_volumes
	ldr	r0, =V
	movs	r1, #1
	strb	r1, [r0, #V_HOSTDRV]
	bl	storage_unlock
	pop	{r4, pc}

@ storage_unshare - after the host gave the drive back: the volume it saw is marked unmounted (type
@ byte 0), so the next access mounts it again from the flash instead of the cached state; then
@ V_HOSTDRV cleared.
	.global	storage_unshare
	.thumb_func
	.type	storage_unshare, %function
storage_unshare:
	push	{r4, lr}
	bl	storage_lock
	bl	exposed_drive
	cmp	r0, #0xFF
	beq	1f
	ldr	r1, =VOLUMES
	ldr	r0, [r1, r0, lsl #2]
	cbz	r0, 1f
	movs	r1, #0
	strb	r1, [r0, #0]
1:	ldr	r0, =V
	movs	r1, #0
	strb	r1, [r0, #V_HOSTDRV]
	bl	storage_unlock
	pop	{r4, pc}

@ msc_service - usb task, every pass and while it waits: runs the mass-storage events the interrupt
@ recorded (cdc_out_done / cdc_in_done, usb_ctl.s), with the storage lock held and the USB interrupt
@ (IRQ 20) masked, so the vendor handler runs in one context as it was written. The events are read
@ and cleared only after the mask (the interrupt clears them on configuration, deconfiguration and
@ mass-storage class requests); they are carried out only while configured with the drive; the
@ transfer-complete event before a new command block.
	.global	msc_service
	.thumb_func
	.type	msc_service, %function
msc_service:
	push	{r4, r5, r6, lr}
	ldr	r4, =V
	ldrh	r0, [r4, #V_MSCOUT]
	cbz	r0, 9f
	bl	storage_lock
	ldr	r5, =0xE000E180			@ NVIC clear-enable: IRQ 20
	mov	r6, #0x100000
	str	r6, [r5]
	dsb
	isb
	ldrb	r0, [r4, #V_CONF]
	ldrb	r1, [r4, #V_SHARED]
	ands	r0, r0, r1
	bne	1f
	movs	r0, #0				@ not configured with the drive: events void
	strh	r0, [r4, #V_MSCOUT]
	b	8f
1:	movs	r0, #1
	strb	r0, [r4, #V_INMSC]
	ldrb	r0, [r4, #V_MSCIN]
	cbz	r0, 2f
	movs	r0, #0
	strb	r0, [r4, #V_MSCIN]
	ldr	r0, =USB_DEV
	movs	r1, #1
	bl	send_status_block_after_data
2:	ldrb	r1, [r4, #V_MSCOUT]
	cbz	r1, 3f
	movs	r0, #0
	strb	r0, [r4, #V_MSCOUT]
	subs	r1, #1
	ldr	r0, =USB_DEV
	bl	handle_command_block_or_write_data
3:	movs	r0, #0
	strb	r0, [r4, #V_INMSC]
8:	ldr	r5, =0xE000E100			@ NVIC set-enable: IRQ 20
	str	r6, [r5]
	bl	storage_unlock
9:	pop	{r4, r5, r6, pc}

	.ltorg
