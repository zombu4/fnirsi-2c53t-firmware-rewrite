@ slot_11.s - code that only the slot build of the bootloader has (make slot): the bootloader started by
@ the starter from slot F, A or B (BOOTLOADER_DESIGN.md revision 2, section 4).  The stock build
@ (make, make check) assembles this file to nothing.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
@
@ Called from the stock code (each call is under .ifdef SLOT there):
@   copy_region   scatter-load handler of region table entry 0 (rodata.s): copies the RAM image
@   slot_app_ok   fn_08002784, before the application is started: checks it
@   slot_confirm  fn_08002784 (application start) and main after the USB start: TRIAL -> OK
@   slot_quiesce  fn_08002784, just before the jump: every NVIC interrupt and SysTick off

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

.ifdef SLOT
	.include "common/layout.inc"

	.section .text.slot,"ax",%progbits
	.p2align 2

@ ----------------------------------------------------------------------------
@ copy_region - scatter-load handler: r0 = source, r1 = destination, r2 = byte count (a multiple
@ of 4, not 0).  Copies word by word.  Clobbers r0-r3.  copy_region_addr is a plain label on the
@ same address: the region table needs the even address (an odd handler word is taken as an offset
@ by scatter_load_regions, 0x080001AA).
@ ----------------------------------------------------------------------------
	.global	copy_region
	.global	copy_region_addr
	.thumb_func
	.type	copy_region, %function
copy_region:
copy_region_addr:
1:	subs	r2, #4
	itt	cs
	ldrcs	r3, [r0], #4
	strcs	r3, [r1], #4
	bhi	1b
	bx	lr

@ ----------------------------------------------------------------------------
@ slot_app_ok - r0 = address of the application's vector table (0x08007000, or the "A"+hex target).
@ Returns 1 when the application may be started, else 0:
@   - the "8KTA" word is at 0x08006800 (the stock bootloader erases it when an update starts and
@     programs it when the whole file is written: an interrupted update leaves it erased);
@   - APP_BASE <= table and table + 8 <= APP_END;
@   - stack pointer (word 0): RAM_LO < sp <= RAM_HI;
@   - reset vector (word 1): odd, and table <= (vector - 1) < APP_END.
@ ----------------------------------------------------------------------------
	.global	slot_app_ok
	.thumb_func
	.type	slot_app_ok, %function
slot_app_ok:
	ldr	r1, =KTA_ADDR
	ldr	r1, [r1]
	ldr	r2, =KTA_WORD
	cmp	r1, r2
	bne	9f
	ldr	r1, =APP_BASE
	cmp	r0, r1
	blo	9f
	ldr	r3, =APP_END		@ r3 = end of the application area
	add	r1, r0, #8
	cmp	r1, r3
	bhi	9f
	ldr	r1, [r0, #0]		@ stack pointer
	ldr	r2, =RAM_LO
	cmp	r1, r2
	bls	9f
	ldr	r2, =RAM_HI
	cmp	r1, r2
	bhi	9f
	ldr	r1, [r0, #4]		@ reset vector
	tst	r1, #1
	beq	9f
	bic	r1, r1, #1
	cmp	r1, r0
	blo	9f
	cmp	r1, r3
	bhs	9f
	movs	r0, #1
	bx	lr
9:	movs	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ slot_confirm - when the newest valid record is TRIAL for the slot this image runs in, appends OK
@ for it (sequence + 1).  Nothing otherwise (no record, OK / INSTALL, another slot, or this image
@ is not in a slot id the records know).  The slot is the one whose image starts at this image's
@ vector table: vectors - SLOT_IMAGE_OFS.
@ ----------------------------------------------------------------------------
	.global	slot_confirm
	.thumb_func
	.type	slot_confirm, %function
slot_confirm:
	push	{r4, r5, r6, lr}
	sub	sp, #16			@ scan state
	mov	r0, sp
	bl	rec_scan
	ldr	r4, [sp, #0]		@ r4 = newest valid record or 0
	cbz	r4, 9f
	ldrb	r0, [r4, #REC_STATE_OFS]
	cmp	r0, #ST_TRIAL
	bne	9f
	ldr	r5, =vectors		@ r5 = this image's slot base
	sub	r5, r5, #SLOT_IMAGE_OFS
	ldrb	r6, [r4, #REC_SLOT_OFS]	@ r6 = slot id of the TRIAL record
	mov	r0, r6
	bl	slot_base_of
	cmp	r0, r5
	bne	9f			@ TRIAL of another slot (or an unknown id: base 0)
	movs	r0, #ST_OK
	mov	r1, r6
	ldr	r2, [r4, #REC_SEQ_OFS]
	adds	r2, r2, #1
	mov	r3, sp
	bl	rec_append
9:	add	sp, #16
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ slot_quiesce - disables and clears every NVIC interrupt (ICER0..7 0xE000E180, ICPR0..7 0xE000E280),
@ stops SysTick (CTRL 0xE000E010 = 0) and clears a pending SysTick (ICSR 0xE000ED04 bit 25), then
@ leaves PRIMASK clear as after a reset.  The application starts with no interrupt of this
@ bootloader enabled or pending (BOOTLOADER_DESIGN.md rev 2 (9)).
@ ----------------------------------------------------------------------------
	.global	slot_quiesce
	.thumb_func
	.type	slot_quiesce, %function
slot_quiesce:
	cpsid	i
	ldr	r0, =0xE000E180		@ ICER0
	mvn	r1, #0
	movs	r2, #8
1:	str	r1, [r0]		@ ICERn: disable
	str	r1, [r0, #0x100]	@ ICPRn: clear pending
	adds	r0, #4
	subs	r2, #1
	bne	1b
	ldr	r0, =0xE000E010		@ SysTick CTRL
	movs	r1, #0
	str	r1, [r0]
	ldr	r0, =0xE000ED04		@ ICSR
	mov	r1, #0x02000000		@ PENDSTCLR
	str	r1, [r0]
	dsb
	isb
	cpsie	i
	bx	lr

@ ============================================================================
@ Version 2: staged updates and the hand-over to the application (CONTROL_DESIGN.md revision 2,
@ items 3 and 4; PROTOCOL.md FW_* commands).
@ ============================================================================

@ ----------------------------------------------------------------------------
@ iwdg_feed - reloads the independent watchdog (0xAAAA to 0x40003000). The application starts it and a
@ system reset does not stop it, so the bootloader feeds it whenever it was entered by the
@ application's reset. Writing the key to a watchdog that was never started has no effect.
@ Clobbers r0, r1.
@ ----------------------------------------------------------------------------
	.global	iwdg_feed
	.thumb_func
	.type	iwdg_feed, %function
iwdg_feed:
	ldr	r1, =IWDG_KEY
	movw	r0, #0xAAAA
	str	r0, [r1]
	bx	lr

@ ----------------------------------------------------------------------------
@ own_slot_id - returns the slot id of this image (from vectors - SLOT_IMAGE_OFS), 0xFF if none.
@ Clobbers r0-r3, r12.
@ ----------------------------------------------------------------------------
	.thumb_func
own_slot_id:
	push	{r4, r5, r6, lr}
	ldr	r5, =vectors		@ r5 = this image's slot base
	sub	r5, r5, #SLOT_IMAGE_OFS
	movs	r4, #0			@ r4 = slot id tried
1:	mov	r0, r4
	bl	slot_base_of
	cmp	r0, r5
	beq	2f
	adds	r4, #1
	cmp	r4, #3
	blo	1b
	movs	r4, #0xFF
2:	mov	r0, r4
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ slot_handover - writes the hand-over block at HANDOVER_ADDR for the application: magic, slot id,
@ bootloader version (HDR_VERSION of this slot's header), the update result word at +12 is kept
@ (slot_staged_update writes it). Called just before the application is started. Clobbers r0-r3.
@ ----------------------------------------------------------------------------
	.global	slot_handover
	.thumb_func
	.type	slot_handover, %function
slot_handover:
	push	{r4, lr}
	ldr	r4, =HANDOVER_ADDR
	bl	own_slot_id
	str	r0, [r4, #4]
	ldr	r0, =vectors
	sub	r0, r0, #SLOT_IMAGE_OFS
	ldr	r0, [r0, #HDR_VERSION]
	str	r0, [r4, #8]
	ldr	r0, =HANDOVER_MAGIC
	str	r0, [r4, #0]
	dsb
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ spi_init - serial flash interface as the application sets it up (src/serial_flash_52.s
@ serial_device_interface_init / fn_0803d848): clocks APB1 bit 14 (0x4002101C) and APB2 bits 0, 3
@ (0x40021018); PB12 push-pull output (chip select, high = idle), PB13..PB15 alternate push-pull
@ (0x40010C04 nibbles 4..7 = 1, 9, 9, 9); control 0x40003800 = master, software select, mode 3,
@ 8 bit, clock divider /8 (the application uses /2), then enabled (bit 6). Clobbers r0-r2.
@ ----------------------------------------------------------------------------
	.thumb_func
spi_init:
	ldr	r1, =0x4002101C
	ldr	r0, [r1]
	orr	r0, r0, #0x4000
	str	r0, [r1]
	ldr	r1, =0x40021018
	ldr	r0, [r1]
	orr	r0, r0, #0x09
	str	r0, [r1]
	ldr	r1, =0x40010C10		@ PB12 high before it becomes an output
	mov	r0, #0x1000
	str	r0, [r1]
	ldr	r1, =0x40010C04
	ldr	r0, [r1]
	bic	r0, r0, #0xFF0000
	bic	r0, r0, #0xFF000000
	ldr	r2, =0x99910000
	orr	r0, r0, r2
	str	r0, [r1]
	ldr	r1, =SPI2_BASE
	movw	r0, #0x0317		@ SSM | SSI | MSTR | BR=/8 | CPOL | CPHA
	str	r0, [r1, #0]
	orr	r0, r0, #0x40		@ SPE
	str	r0, [r1, #0]
	bx	lr

@ spi_xfer - r0 = byte out; returns the byte in. Waits for TXE (status bit 1), writes the data
@ register, waits for RXNE (bit 0), reads it. Clobbers r0-r2.
	.thumb_func
spi_xfer:
	ldr	r1, =SPI2_BASE
1:	ldr	r2, [r1, #8]
	tst	r2, #2
	beq	1b
	str	r0, [r1, #0x0C]
2:	ldr	r2, [r1, #8]
	tst	r2, #1
	beq	2b
	ldr	r0, [r1, #0x0C]
	uxtb	r0, r0
	bx	lr

@ ----------------------------------------------------------------------------
@ spi_read - r0 = serial flash address, r1 = buffer, r2 = byte count. Command 03 (read) with three
@ address bytes, then the bytes. Clobbers r0-r3, r12.
@ ----------------------------------------------------------------------------
	.thumb_func
spi_read:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	mov	r6, r2
	ldr	r1, =0x40010C14		@ chip select low
	mov	r0, #0x1000
	str	r0, [r1]
	movs	r0, #3
	bl	spi_xfer
	lsr	r0, r4, #16
	bl	spi_xfer
	lsr	r0, r4, #8
	bl	spi_xfer
	mov	r0, r4
	bl	spi_xfer
1:	cbz	r6, 2f
	movs	r0, #0xFF
	bl	spi_xfer
	strb	r0, [r5], #1
	subs	r6, #1
	b	1b
2:	ldr	r1, =0x40010C10		@ chip select high
	mov	r0, #0x1000
	str	r0, [r1]
	pop	{r4, r5, r6, pc}

@ spi_read32 / spi_read16 - r0 = serial flash address; returns the little-endian word / halfword.
	.thumb_func
spi_read32:
	push	{r0, lr}		@ r0 slot doubles as the 4-byte buffer
	mov	r1, sp
	movs	r2, #4
	bl	spi_read
	pop	{r0, pc}

	.thumb_func
spi_read16:
	push	{r0, lr}
	mov	r1, sp
	movs	r2, #2
	bl	spi_read
	pop	{r0, lr}
	uxth	r0, r0
	bx	lr

@ ----------------------------------------------------------------------------
@ crc_update - r0 = CRC register (start 0xFFFFFFFF), r1 = address, r2 = byte count; returns the new
@ register (the CRC-32 of zlib is the final register inverted). Bitwise. Clobbers r0-r3, r12.
@ ----------------------------------------------------------------------------
	.thumb_func
crc_update:
	ldr	r12, =0xEDB88320
1:	cbz	r2, 3f
	ldrb	r3, [r1], #1
	eors	r0, r0, r3
	movs	r3, #8
2:	lsrs	r0, r0, #1
	it	cs
	eorcs	r0, r0, r12
	subs	r3, #1
	bne	2b
	subs	r2, #1
	b	1b
3:	bx	lr

@ ----------------------------------------------------------------------------
@ FAT volume of drive "2:" (serial flash VOL2_BASE, 4096-byte sectors). The volume block r11 (32
@ bytes on the caller's stack):
@   [0] FAT address, [4] address of cluster 2, [8] bytes per cluster, [12] 12 or 16 (FAT type),
@   [16] root directory address, [20] root directory entries
@ ----------------------------------------------------------------------------
	.equ	V_FAT, 0
	.equ	V_DATA, 4
	.equ	V_CLUS, 8
	.equ	V_TYPE, 12
	.equ	V_ROOT, 16
	.equ	V_NROOT, 20

@ fat_mount - fills the volume block from the boot sector; returns 0, or 1 when the boot sector is not a
@ FAT12/16 volume with 4096-byte sectors. Registers r4-r8 saved.
	.thumb_func
fat_mount:
	push	{r4, r5, r6, r7, r8, lr}
	ldr	r0, =VOL2_BASE + 0x0B
	bl	spi_read16
	cmp	r0, #0x1000		@ bytes per sector
	bne	9f
	ldr	r0, =VOL2_BASE + 0x0D
	bl	spi_read16
	uxtb	r4, r0			@ r4 = sectors per cluster
	cmp	r4, #0
	beq	9f
	ldr	r0, =VOL2_BASE + 0x0E
	bl	spi_read16
	mov	r5, r0			@ r5 = reserved sectors
	ldr	r0, =VOL2_BASE + 0x10
	bl	spi_read16
	uxtb	r6, r0			@ r6 = number of FATs
	lsrs	r7, r0, #8		@ low byte of the root entry count (0x11)
	ldr	r0, =VOL2_BASE + 0x12
	bl	spi_read16
	uxtb	r0, r0
	orr	r7, r7, r0, lsl #8	@ r7 = root directory entries
	str	r7, [r11, #V_NROOT]
	ldr	r0, =VOL2_BASE + 0x16
	bl	spi_read16
	mov	r8, r0			@ r8 = sectors per FAT
	cmp	r8, #0
	beq	9f			@ FAT32 (sectors per FAT 0 here) is not supported
	ldr	r0, =VOL2_BASE + 0x13
	bl	spi_read16
	cbnz	r0, 1f
	ldr	r0, =VOL2_BASE + 0x20
	bl	spi_read32
1:	mov	r3, r0			@ r3 = total sectors
	lsls	r0, r5, #12		@ FAT address = base + reserved * 4096
	ldr	r1, =VOL2_BASE
	add	r0, r0, r1
	str	r0, [r11, #V_FAT]
	mla	r2, r6, r8, r5		@ r2 = root directory sector = reserved + FATs * sectors per FAT
	lsls	r0, r2, #12
	add	r0, r0, r1
	str	r0, [r11, #V_ROOT]
	lsls	r0, r7, #5		@ root directory sectors = (entries * 32 + 4095) / 4096
	add	r0, r0, #0xFF0
	adds	r0, r0, #0xF
	lsrs	r0, r0, #12
	add	r2, r2, r0		@ r2 = first data sector
	lsls	r0, r2, #12
	add	r0, r0, r1
	str	r0, [r11, #V_DATA]
	lsls	r0, r4, #12
	str	r0, [r11, #V_CLUS]
	subs	r3, r3, r2		@ data sectors
	udiv	r3, r3, r4		@ clusters
	movw	r0, #4085
	cmp	r3, r0
	ite	lo
	movlo	r0, #12
	movhs	r0, #16
	str	r0, [r11, #V_TYPE]
	movw	r0, #65525
	cmp	r3, r0
	bhs	9f			@ FAT32 by cluster count
	movs	r0, #0
	pop	{r4, r5, r6, r7, r8, pc}
9:	movs	r0, #1
	pop	{r4, r5, r6, r7, r8, pc}

@ fat_next - r0 = cluster; returns the next cluster of the chain (0x0FFFFFFF for the end of the chain
@ or a reserved / bad value). Clobbers r0-r3, r12.
	.thumb_func
fat_next:
	push	{r4, lr}
	mov	r4, r0
	ldr	r1, [r11, #V_TYPE]
	cmp	r1, #12
	bne	2f
	add	r0, r4, r4, lsr #1	@ FAT12: offset = cluster * 1.5
	ldr	r1, [r11, #V_FAT]
	add	r0, r0, r1
	bl	spi_read16
	tst	r4, #1
	ite	ne
	lsrne	r0, r0, #4
	ubfxeq	r0, r0, #0, #12
	movw	r1, #0xFF7
	b	3f
2:	lsls	r0, r4, #1		@ FAT16: offset = cluster * 2
	ldr	r1, [r11, #V_FAT]
	add	r0, r0, r1
	bl	spi_read16
	movw	r1, #0xFFF7
3:	cmp	r0, #2
	blo	4f
	cmp	r0, r1
	bhs	4f
	pop	{r4, pc}
4:	mvn	r0, #0xF0000000		@ 0x0FFFFFFF: end of the chain
	pop	{r4, pc}

@ cluster_addr - r0 = cluster; returns the serial flash address of its first byte.
	.thumb_func
cluster_addr:
	subs	r0, r0, #2
	ldr	r1, [r11, #V_CLUS]
	ldr	r2, [r11, #V_DATA]
	mla	r0, r0, r1, r2
	bx	lr

@ ----------------------------------------------------------------------------
@ dir_find - r0 = first cluster of a directory (0 = root), r1 = 11-byte 8.3 name (in this image),
@ r2 = 1 to find a directory, 0 to find a file; returns the serial flash address of the directory
@ entry, or 0. Long-name entries (attribute 0x0F), deleted entries and the volume label are
@ skipped; an entry whose first byte is 0 ends the directory.
@ Registers: r4 entry address, r5 end of the current run, r6 name, r7 want-directory, r8 cluster.
@ ----------------------------------------------------------------------------
	.thumb_func
dir_find:
	push	{r4, r5, r6, r7, r8, r9, r10, lr}
	sub	sp, #32			@ one directory entry
	mov	r6, r1
	mov	r7, r2
	mov	r8, r0
	cbnz	r0, 1f
	ldr	r4, [r11, #V_ROOT]	@ root: one run of entries * 32 bytes
	ldr	r5, [r11, #V_NROOT]
	add	r5, r4, r5, lsl #5
	b	2f
1:	mov	r0, r8
	bl	cluster_addr
	mov	r4, r0
	ldr	r5, [r11, #V_CLUS]
	add	r5, r5, r4
2:	cmp	r4, r5
	bhs	6f
	mov	r0, r4
	mov	r1, sp
	movs	r2, #32
	bl	spi_read
	ldrb	r0, [sp, #0]
	cmp	r0, #0
	beq	8f			@ end of the directory
	cmp	r0, #0xE5
	beq	5f			@ deleted
	ldrb	r0, [sp, #11]		@ attributes
	cmp	r0, #0x0F
	beq	5f			@ long-name part
	tst	r0, #0x08
	bne	5f			@ volume label
	lsrs	r0, r0, #4		@ directory bit
	and	r0, r0, #1
	cmp	r0, r7
	bne	5f
	movs	r1, #0			@ compare the 11 name bytes
3:	ldrb	r2, [sp, r1]
	ldrb	r3, [r6, r1]
	cmp	r2, r3
	bne	5f
	adds	r1, #1
	cmp	r1, #11
	blo	3b
	mov	r0, r4			@ found
	b	9f
5:	adds	r4, #32
	b	2b
6:	cmp	r8, #0			@ end of a run: next cluster of a sub-directory
	beq	8f
	mov	r0, r8
	bl	fat_next
	mov	r8, r0
	mvn	r1, #0xF0000000
	cmp	r0, r1
	bne	1b
8:	movs	r0, #0
9:	add	sp, #32
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}

@ ----------------------------------------------------------------------------
@ file_pass - r0 = first cluster, r1 = byte count, r2 = mode (0: CRC-32 over the file, 1: program
@ the file to the application area from APP_BASE), r3 = 256-byte buffer. Returns the CRC register
@ after mode 0 (start 0xFFFFFFFF), 0 after mode 1. Feeds the watchdog per cluster.
@ Registers: r4 cluster, r5 bytes left, r6 mode, r7 buffer, r8 flash address (mode 1), r9 serial
@ flash address, r10 bytes left in the cluster, r12 / stack CRC register.
@ ----------------------------------------------------------------------------
	.thumb_func
file_pass:
	push	{r4, r5, r6, r7, r8, r9, r10, lr}
	sub	sp, #8			@ [sp] = CRC register
	mov	r4, r0
	mov	r5, r1
	mov	r6, r2
	mov	r7, r3
	ldr	r8, =APP_BASE
	mvn	r0, #0
	str	r0, [sp]
1:	cbz	r5, 8f
	mvn	r1, #0xF0000000
	cmp	r4, r1
	beq	9f			@ the chain ended before the file: treat as an error (CRC wrong)
	bl	iwdg_feed
	mov	r0, r4
	bl	cluster_addr
	mov	r9, r0
	ldr	r10, [r11, #V_CLUS]
2:	cbz	r5, 8f
	cmp	r10, #0
	beq	6f
	mov	r2, #256		@ chunk = min(256, bytes left)
	cmp	r5, r2
	it	lo
	movlo	r2, r5
	push	{r2}
	mov	r0, r9
	mov	r1, r7
	bl	spi_read
	pop	{r2}
	cbnz	r6, 3f
	ldr	r0, [sp]		@ mode 0: CRC
	mov	r1, r7
	push	{r2}
	bl	crc_update
	pop	{r2}
	str	r0, [sp]
	b	5f
3:	push	{r2}			@ mode 1: program the chunk word by word (length multiple of 4)
	movs	r3, #0
4:	cmp	r3, r2
	bhs	41f
	push	{r2, r3}
	add	r0, r8, r3
	ldr	r1, [r7, r3]
	bl	flash_program_word
	pop	{r2, r3}
	adds	r3, #4
	b	4b
41:	pop	{r2}
	add	r8, r8, r2
5:	add	r9, r9, r2
	sub	r5, r5, r2
	sub	r10, r10, r2
	b	2b
6:	mov	r0, r4			@ next cluster
	bl	fat_next
	mov	r4, r0
	b	1b
8:	ldr	r0, [sp]
	cmp	r6, #0
	it	ne
	movne	r0, #0
	add	sp, #8
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}
9:	movs	r0, #0			@ broken chain: a CRC register of 0 never matches a request CRC
	add	sp, #8
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}

@ ----------------------------------------------------------------------------
@ slot_staged_update - called by main before the key test. Without a valid update request at REQ_ADDR
@ it writes UPD_NONE to the hand-over result word and returns. With one it clears the request
@ first (a failure never repeats itself), holds the power (PC9 high, as the update mode does), feeds
@ the watchdog, and installs 2:/UPDATE/APP.BIN only when its length equals the request, its CRC-32
@ equals the request and its first two words are a stack pointer in RAM and an odd reset vector inside
@ the image. Then: erase the "8KTA" page and the application pages, program the file, compare the
@ application with the CRC-32, program "8KTA". The result goes to HANDOVER_ADDR + 12 (UPD_*); the
@ application reports it (PROTOCOL.md INFO). Returns r0 = the result.
@ Frame: [sp + 0..255] buffer, [sp + 256..287] volume block (r11).
@ ----------------------------------------------------------------------------
	.global	slot_staged_update
	.thumb_func
	.type	slot_staged_update, %function
slot_staged_update:
	push	{r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	sub	sp, #288
	add	r11, sp, #256
	ldr	r4, =REQ_ADDR
	ldr	r0, [r4, #0]
	ldr	r1, =REQ_MAGIC
	cmp	r0, r1
	bne	.Lsu_none
	ldr	r0, [r4, #12]
	mvn	r1, r1
	cmp	r0, r1
	bne	.Lsu_none
	ldr	r5, [r4, #4]		@ r5 = image CRC-32
	ldr	r6, [r4, #8]		@ r6 = image length
	movs	r0, #0			@ the request is used once
	str	r0, [r4, #0]
	str	r0, [r4, #12]
	dsb
	ldr	r1, =0x40011010		@ hold the power: PC9 high (pin set up by main before)
	mov	r0, #0x200
	str	r0, [r1]
	bl	iwdg_feed
	bl	spi_init
	bl	fat_mount
	cmp	r0, #0
	bne	.Lsu_nofile
	movs	r0, #0
	adr	r1, .Lname_update
	movs	r2, #1
	bl	dir_find
	cmp	r0, #0
	beq	.Lsu_nofile
	adds	r0, #0x1A
	bl	spi_read16		@ first cluster of the directory
	cmp	r0, #0
	beq	.Lsu_nofile
	adr	r1, .Lname_app
	movs	r2, #0
	bl	dir_find
	cmp	r0, #0
	beq	.Lsu_nofile
	mov	r7, r0			@ r7 = directory entry address
	adds	r0, #0x1C
	bl	spi_read32
	cmp	r0, r6			@ file size == request length
	bne	.Lsu_bad
	mov	r0, r7
	adds	r0, #0x1A
	bl	spi_read16
	mov	r7, r0			@ r7 = first cluster of the file
	cmp	r6, #8			@ 8 <= length <= application area, multiple of 4
	blo	.Lsu_bad
	tst	r6, #3
	bne	.Lsu_bad
	ldr	r0, =APP_END - APP_BASE
	cmp	r6, r0
	bhi	.Lsu_bad
	mov	r0, r7			@ vector table: SP in RAM, reset odd inside the image
	bl	cluster_addr
	mov	r8, r0
	bl	spi_read32
	ldr	r1, =RAM_LO
	cmp	r0, r1
	bls	.Lsu_bad
	ldr	r1, =RAM_HI
	cmp	r0, r1
	bhi	.Lsu_bad
	add	r0, r8, #4
	bl	spi_read32
	tst	r0, #1
	beq	.Lsu_bad
	bic	r0, r0, #1
	ldr	r1, =APP_BASE
	cmp	r0, r1
	blo	.Lsu_bad
	add	r1, r1, r6
	cmp	r0, r1
	bhs	.Lsu_bad
	mov	r0, r7			@ CRC-32 of the staged file
	mov	r1, r6
	movs	r2, #0
	mov	r3, sp
	bl	file_pass
	mvn	r0, r0
	cmp	r0, r5
	bne	.Lsu_bad
	bl	flash_unlock_keys	@ the file is complete and correct: install it
	bl	iwdg_feed
	ldr	r0, =KTA_ADDR
	bl	flash_erase_sector
	ldr	r8, =APP_BASE
	add	r9, r8, r6
1:	cmp	r8, r9
	bhs	2f
	bl	iwdg_feed
	mov	r0, r8
	bl	flash_erase_sector
	add	r8, r8, #0x800
	b	1b
2:	mov	r0, r7
	mov	r1, r6
	movs	r2, #1
	mov	r3, sp
	bl	file_pass
	bl	fn_080020f8		@ lock
	bl	iwdg_feed
	mvn	r0, #0			@ compare the programmed application with the CRC-32
	ldr	r1, =APP_BASE
	mov	r2, r6
	bl	crc_update
	mvn	r0, r0
	cmp	r0, r5
	bne	.Lsu_flash
	bl	flash_unlock_keys
	ldr	r0, =KTA_ADDR
	ldr	r1, =KTA_WORD
	bl	flash_program_word
	bl	fn_080020f8
	movs	r0, #UPD_OK
	b	.Lsu_result
.Lsu_none:
	movs	r0, #UPD_NONE
	b	.Lsu_result
.Lsu_nofile:
	movs	r0, #UPD_NO_FILE
	b	.Lsu_result
.Lsu_bad:
	movs	r0, #UPD_BAD_IMAGE
	b	.Lsu_result
.Lsu_flash:
	movs	r0, #UPD_FLASH_FAIL
.Lsu_result:
	ldr	r1, =HANDOVER_ADDR
	str	r0, [r1, #12]
	add	sp, #288
	pop	{r4, r5, r6, r7, r8, r9, r10, r11, r12, pc}

	.p2align 2
.Lname_update:
	.ascii	"UPDATE     "		@ 8.3 name of the directory
	.p2align 2
.Lname_app:
	.ascii	"APP     BIN"		@ 8.3 name of the staged image
	.p2align 2			@ code follows: back to an instruction boundary

	.include "common/records.inc"

	.ltorg
.endif
