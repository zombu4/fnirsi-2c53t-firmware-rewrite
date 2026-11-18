@ serial_flash_52.s - serial flash device driver: sector run write, command senders, interface init, read, byte transfer, status wait, merge write, chunked write, page write
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ write_sector_run - writes whole sectors of a volume to the serial device.
@ Writes (r3 & 0xf) << 12 bytes from buffer r1 to the serial device with
@ serial_device_write_merge(r1, address, (r3 & 0xf) << 12).
@ r0 = volume type: r0 < 2 returns 1; r0 == 3 uses r2 << 12 as address;
@ r0 == 2 uses r2 * 0x1000 + 0x200000 as address; any other r0 returns 4.
@ r2 = sector number, r3 = number of 0x1000-byte sectors (low 4 bits).
@ Returns 0 after the call.
@ ----------------------------------------------------------------------------
	.section .text.write_sector_run,"ax",%progbits
	.global write_sector_run
	.thumb_func
	.type write_sector_run, %function
write_sector_run:
	push	{r4, r5, r6, lr}
	cmp	r0, #2
	bcc.n	.L08033f5a
	mov	r5, r3
	mov	r6, r2
	mov	r4, r1
	cmp	r0, #3
	beq.n	.L08033f5e
	cmp	r0, #2
	bne.n	.L08033f78
	nop.w
	mov.w	r0, #0x200000
	add.w	r6, r0, r6, lsl #12
	b.n	.L08033f64
.L08033f5a:
	movs	r0, #1
	pop	{r4, r5, r6, pc}
.L08033f5e:
	nop.w
	lsls	r6, r6, #12
.L08033f64:
	nop.w
	lsls	r0, r5, #12
	uxth	r2, r0
	mov	r0, r4
	mov	r1, r6
	bl	serial_device_write_merge
	movs	r0, #0
	pop	{r4, r5, r6, pc}
.L08033f78:
	movs	r0, #4
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ serial_device_command_20_with_address - sends command byte 0x20 with the
@ 3-byte address r0 and waits for the status bit.
@ Sends a 4-byte command to the serial device on 0x40003800 with chip select
@ line 0x40010c14 (select) / 0x40010c10 (deselect) = 0x1000: first calls
@ serial_device_send_command_6, then writes bytes 0x20, bits 23..16, 15..8,
@ 7..0 of r0 through serial_device_transfer_byte, deselects and calls
@ serial_device_wait_status_bit0_clear to wait for ready.
@ Called by serial_device_write_merge with block << 12 before it writes a whole
@ 0x1000-byte block back (the effect of the command on the device is not
@ determined from the code).
@ ----------------------------------------------------------------------------
	.section .text.serial_device_command_20_with_address,"ax",%progbits
	.global serial_device_command_20_with_address
	.thumb_func
	.type serial_device_command_20_with_address, %function
serial_device_command_20_with_address:
	push	{r4, lr}
	sub	sp, #8
	str	r0, [sp, #4]
	bl	serial_device_send_command_6
	movw	r4, #0xc00
	movt	r4, #0x4001
	mov	r0, r4
	mov.w	r1, #0x1000
	str	r1, [r0, #0x14]			@ select (0x40010c14 = 0x1000)
	nop
	movs	r0, #0x20
	bl	serial_device_transfer_byte
	ldrb.w	r0, [sp, #6]			@ address bits 23..16
	bl	serial_device_transfer_byte
	ldrb.w	r0, [sp, #5]			@ address bits 15..8
	bl	serial_device_transfer_byte
	ldrb.w	r0, [sp, #4]			@ address bits 7..0
	bl	serial_device_transfer_byte
	mov	r0, r4
	mov.w	r1, #0x1000
	str	r1, [r0, #0x10]			@ deselect (0x40010c10 = 0x1000)
	nop
	bl	serial_device_wait_status_bit0_clear
	add	sp, #8
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ serial_device_command_90_clock_two_bytes - sends command byte 0x90 with a
@ zero address and clocks two bytes out, discarding both.
@ Pulls 0x40010c14 = 0x1000 (select), sends bytes 0x90, 0, 0, 0 with
@ serial_device_transfer_byte, then calls serial_device_clock_byte twice (two
@ 0xff transfers, results discarded) and writes 0x40010c10 = 0x1000 (deselect).
@ The code does not use the two bytes.
@ ----------------------------------------------------------------------------
	.section .text.serial_device_command_90_clock_two_bytes,"ax",%progbits
	.global serial_device_command_90_clock_two_bytes
	.thumb_func
	.type serial_device_command_90_clock_two_bytes, %function
serial_device_command_90_clock_two_bytes:
	push	{r4, lr}
	sub	sp, #8
	movs	r0, #0
	strh.w	r0, [sp, #6]
	movw	r4, #0xc00
	movt	r4, #0x4001
	mov	r0, r4
	mov.w	r1, #0x1000
	str	r1, [r0, #0x14]			@ select
	nop
	movs	r0, #0x90
	bl	serial_device_transfer_byte
	movs	r0, #0
	bl	serial_device_transfer_byte
	movs	r0, #0
	bl	serial_device_transfer_byte
	movs	r0, #0
	bl	serial_device_transfer_byte
	bl	serial_device_clock_byte
	ldrh.w	r1, [sp, #6]
	orr.w	r0, r1, r0, lsl #8
	strh.w	r0, [sp, #6]
	bl	serial_device_clock_byte
	ldrh.w	r1, [sp, #6]
	orrs	r0, r1
	strh.w	r0, [sp, #6]
	mov	r0, r4
	mov.w	r1, #0x1000
	str	r1, [r0, #0x10]			@ deselect
	nop
	add	sp, #8
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ serial_device_interface_init - initialisation of the serial device interface.
@ Calls set_bit_in_register with 0x1c000e, 0x180000 and four times 0x180003,
@ fills an 8-byte block (word pin mask at +0, then bytes +4 = 0, +5 = 0x18,
@ +6 = 0x10 for mask 0x1000 or 8 for the others, +7 = 1) and calls
@ set_nibble_fields_from_bit_mask(0x40010c00, &{0x1000, 0x2000, 0x4000,
@ 0x8000}) for each bit mask.
@ Writes 0x1000 to 0x40010c10, calls fn_0803d820 on a local 8-byte block,
@ stores the 8 bytes below in it and calls fn_0803d848(0x40003800, 8 bytes
@ 0,1,0,0,0,1,1,1), set_bit6(0x40003800) and then
@ serial_device_command_90_clock_two_bytes.
@ Masks 0x2000, 0x4000, 0x8000 get nibble 9 and 0x1000 gets nibble 1 from
@ set_nibble_fields_from_bit_mask ((byte+7 & 3) + (byte+4 & 4) + (byte+6 & 8)).
@ Purpose: sets the nibble fields of the 0x40010c00 block for the masks
@ 0x1000..0x8000 and initialises the 0x40003800 interface used by
@ serial_device_transfer_byte.
@ ----------------------------------------------------------------------------
	.section .text.serial_device_interface_init,"ax",%progbits
	.global serial_device_interface_init_unlocked
	.thumb_func
	.type serial_device_interface_init_unlocked, %function
serial_device_interface_init_unlocked:
	push.w	{r4, r5, r6, r7, r8, r9, lr}
	sub	sp, #0x14
	movs	r0, #0xe
	movt	r0, #0x1c
	bl	set_bit_in_register
	mov.w	r0, #0x180000
	bl	set_bit_in_register
	movs	r4, #3
	movt	r4, #0x18
	mov	r0, r4
	bl	set_bit_in_register
	mov	r0, r4
	bl	set_bit_in_register
	mov	r0, r4
	bl	set_bit_in_register
	mov	r0, r4
	bl	set_bit_in_register
	mov.w	r8, #0
	strb.w	r8, [sp, #0x10]
	movs	r6, #0x18
	strb.w	r6, [sp, #0x11]
	movs	r0, #0x10
	strb.w	r0, [sp, #0x12]
	mov.w	r9, #1
	strb.w	r9, [sp, #0x13]
	mov.w	r0, #0x1000
	str	r0, [sp, #0xc]			@ mask 0x1000
	movw	r4, #0xc00
	movt	r4, #0x4001
	add	r5, sp, #0xc
	mov	r0, r4
	mov	r1, r5
	bl	set_nibble_fields_from_bit_mask
	strb.w	r6, [sp, #0x11]
	movs	r7, #8
	strb.w	r7, [sp, #0x12]
	mov.w	r0, #0x2000
	str	r0, [sp, #0xc]			@ mask 0x2000
	mov	r0, r4
	mov	r1, r5
	bl	set_nibble_fields_from_bit_mask
	strb.w	r6, [sp, #0x11]
	strb.w	r7, [sp, #0x12]
	mov.w	r0, #0x4000
	str	r0, [sp, #0xc]			@ mask 0x4000
	mov	r0, r4
	mov	r1, r5
	bl	set_nibble_fields_from_bit_mask
	strb.w	r6, [sp, #0x11]
	strb.w	r7, [sp, #0x12]
	mov.w	r0, #0x8000
	str	r0, [sp, #0xc]			@ mask 0x8000
	mov	r0, r4
	mov	r1, r5
	bl	set_nibble_fields_from_bit_mask
	mov	r0, r4
	mov.w	r1, #0x1000
	str	r1, [r0, #0x10]			@ 0x40010c10 = 0x1000
	nop
	add	r4, sp, #4
	mov	r0, r4
	bl	fn_0803d820
	strb.w	r8, [sp, #4]
	strb.w	r9, [sp, #5]
	strb.w	r8, [sp, #6]
	strb.w	r8, [sp, #7]
	strb.w	r8, [sp, #8]
	strb.w	r9, [sp, #9]
	strb.w	r9, [sp, #0xa]
	strb.w	r9, [sp, #0xb]
	movw	r5, #0x3800
	movt	r5, #0x4000
	mov	r0, r5
	mov	r1, r4
	bl	fn_0803d848
	mov	r0, r5
	bl	set_bit6
	bl	serial_device_command_90_clock_two_bytes
	add	sp, #0x14
	pop.w	{r4, r5, r6, r7, r8, r9, pc}

@ ----------------------------------------------------------------------------
@ serial_device_read - reads r2 bytes from the serial device address r1 into
@ buffer r0 (command byte 3).
@ The low 16 bits of r2 are the byte count. Select (0x40010c14 = 0x1000),
@ sends command byte 3, then the address bytes (r1 >> 16, r1 >> 8, r1) with
@ serial_device_transfer_byte, then r2 times stores the result of
@ serial_device_transfer_byte(0xff) into the buffer, deselect
@ (0x40010c10 = 0x1000).
@ ----------------------------------------------------------------------------
	.section .text.serial_device_read,"ax",%progbits
	.global serial_device_read_unlocked
	.thumb_func
	.type serial_device_read_unlocked, %function
serial_device_read_unlocked:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0xc]
	str	r1, [sp, #8]
	strh.w	r2, [sp, #6]
	movw	r0, #0xc00
	movt	r0, #0x4001
	mov.w	r1, #0x1000
	str	r1, [r0, #0x14]			@ select
	nop
	movs	r0, #3
	bl	serial_device_transfer_byte
	ldrb.w	r0, [sp, #0xa]
	bl	serial_device_transfer_byte
	ldrb.w	r0, [sp, #9]
	bl	serial_device_transfer_byte
	ldrb.w	r0, [sp, #8]
	bl	serial_device_transfer_byte
	b.n	.L08036084
.L08036084:
	ldrh.w	r0, [sp, #6]
	subs	r1, r0, #1
	strh.w	r1, [sp, #6]
	cbz	r0, .L080360a4
	b.n	.L08036092
.L08036092:
	movs	r0, #0xff
	bl	serial_device_transfer_byte
	ldr	r1, [sp, #0xc]
	strb	r0, [r1, #0]
	ldr	r0, [sp, #0xc]
	adds	r0, #1
	str	r0, [sp, #0xc]
	b.n	.L08036084
.L080360a4:
	movw	r0, #0xc00
	movt	r0, #0x4001
	mov.w	r1, #0x1000
	str	r1, [r0, #0x10]			@ deselect
	nop
	add	sp, #0x10
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ serial_device_clock_byte - calls serial_device_transfer_byte(0xff) and
@ discards the result.
@ ----------------------------------------------------------------------------
	.section .text.serial_device_clock_byte,"ax",%progbits
	.global serial_device_clock_byte
	.thumb_func
	.type serial_device_clock_byte, %function
serial_device_clock_byte:
	push	{r7, lr}
	movs	r0, #0xff
	bl	serial_device_transfer_byte
	pop	{r7, pc}
	.short	0x0000				@ padding (aligns the next function)

@ ----------------------------------------------------------------------------
@ serial_device_transfer_byte - transfers one byte r0 on the interface at
@ 0x40003800 and returns the byte read.
@ Waits until word8_any_bit_set(0x40003800, 2) is nonzero, writes r0 to
@ 0x4000380c, waits until word8_any_bit_set(0x40003800, 1) is nonzero, and
@ returns the low byte read from 0x4000380c.
@ ----------------------------------------------------------------------------
	.section .text.serial_device_transfer_byte,"ax",%progbits
	.global serial_device_transfer_byte
	.thumb_func
	.type serial_device_transfer_byte, %function
serial_device_transfer_byte:
	push	{r7, lr}
	sub	sp, #8
	strb.w	r0, [sp, #7]
	b.n	.L080360ce
.L080360ce:
	movw	r0, #0x3800
	movt	r0, #0x4000
	movs	r1, #2
	bl	word8_any_bit_set
	cbnz	r0, .L080360e2
	b.n	.L080360e0
.L080360e0:
	b.n	.L080360ce
.L080360e2:
	ldrb.w	r1, [sp, #7]
	movw	r0, #0x3800
	movt	r0, #0x4000
	str	r1, [r0, #0xc]			@ write the byte to 0x4000380c
	nop
	b.n	.L080360f4
.L080360f4:
	movw	r0, #0x3800
	movt	r0, #0x4000
	movs	r1, #1
	bl	word8_any_bit_set
	cbnz	r0, .L08036108
	b.n	.L08036106
.L08036106:
	b.n	.L080360f4
.L08036108:
	movw	r0, #0x3800
	movt	r0, #0x4000
	ldr	r0, [r0, #0xc]			@ read the byte from 0x4000380c
	uxth	r0, r0
	uxtb	r0, r0
	add	sp, #8
	pop	{r7, pc}
	.short	0x0000				@ padding (aligns the next function)

@ ----------------------------------------------------------------------------
@ serial_device_wait_status_bit0_clear - waits for the serial device to become
@ ready.
@ Select (0x40010c14 = 0x1000), sends 5 with serial_device_transfer_byte,
@ repeats serial_device_transfer_byte(0xff) while bit 0 of the returned byte
@ is set, deselect (0x40010c10 = 0x1000). Polls the status byte of the serial
@ device (command 5) until bit 0 is clear.
@ ----------------------------------------------------------------------------
	.section .text.serial_device_wait_status_bit0_clear,"ax",%progbits
	.global serial_device_wait_status_bit0_clear
	.thumb_func
	.type serial_device_wait_status_bit0_clear, %function
serial_device_wait_status_bit0_clear:
	push	{r7, lr}
	sub	sp, #8
	movs	r0, #0
	strb.w	r0, [sp, #7]
	movw	r0, #0xc00
	movt	r0, #0x4001
	mov.w	r1, #0x1000
	str	r1, [r0, #0x14]			@ select
	nop
	movs	r0, #5
	bl	serial_device_transfer_byte
	b.n	.L0803613e
.L0803613e:
	movs	r0, #0xff
	bl	serial_device_transfer_byte
	strb.w	r0, [sp, #7]
	b.n	.L0803614a
.L0803614a:
	ldrb.w	r0, [sp, #7]
	lsls	r0, r0, #31			@ bit 0 into the sign bit
	cmp	r0, #0
	bne.n	.L0803613e
	b.n	.L08036156
.L08036156:
	movw	r0, #0xc00
	movt	r0, #0x4001
	mov.w	r1, #0x1000
	str	r1, [r0, #0x10]			@ deselect
	nop
	add	sp, #8
	pop	{r7, pc}
	.short	0x0000				@ padding (aligns the next function)

@ ----------------------------------------------------------------------------
@ serial_device_write_merge - writes r2 (ushort) bytes from buffer r0 to the
@ serial device address r1, one 0x1000-byte block at a time (first step limited
@ to 0x1000 - (r1 & 0xfff) bytes).
@ Per block: reads the whole block into 0x200012c0 with
@ serial_device_read(0x200012c0, block << 12, 0x1000); when all target bytes
@ in it read 0xff it writes only the range from the caller buffer directly with
@ serial_device_write_chunks(r0, r1, count), otherwise it calls
@ serial_device_command_20_with_address(block << 12), copies the range into the
@ 0x200012c0 buffer and writes the whole block with
@ serial_device_write_chunks(0x200012c0, block << 12, 0x1000).
@ Continues with the next block until the length is used. When every target
@ byte of the block already reads 0xff the range is written directly, otherwise
@ the block is written back whole with the range replaced (read-modify-write
@ of the 0x1000-byte block).
@ ----------------------------------------------------------------------------
	.section .text.serial_device_write_merge,"ax",%progbits
	.global serial_device_write_merge_unlocked
	.thumb_func
	.type serial_device_write_merge_unlocked, %function
serial_device_write_merge_unlocked:
	push	{r7, lr}
	sub	sp, #0x20
	str	r0, [sp, #0x1c]
	str	r1, [sp, #0x18]
	strh.w	r2, [sp, #0x16]
	movs	r0, #0
	str	r0, [sp, #0x10]
	ldr	r0, [sp, #0x18]
	lsrs	r0, r0, #12
	str	r0, [sp, #0xc]			@ block number
	ldr	r0, [sp, #0x18]
	bfc	r0, #12, #20
	str	r0, [sp, #8]			@ offset in block
	ldr	r0, [sp, #8]
	rsb.w	r0, r0, #0x1000
	str	r0, [sp, #4]			@ bytes left in block
	ldrh.w	r0, [sp, #0x16]
	ldr	r1, [sp, #4]
	cmp	r0, r1
	bhi.n	.L080361a6
	b.n	.L0803619e
.L0803619e:
	ldrh.w	r0, [sp, #0x16]
	str	r0, [sp, #4]
	b.n	.L080361a6
.L080361a6:
	b.n	.L080361a8
.L080361a8:
	ldr	r0, [sp, #0xc]
	lsls	r1, r0, #12
	movw	r0, #0x12c0
	movt	r0, #0x2000
	mov.w	r2, #0x1000
	bl	serial_device_read
	movs	r0, #0
	str	r0, [sp, #0x10]
	b.n	.L080361c2
.L080361c2:
	ldr	r0, [sp, #0x10]
	ldr	r1, [sp, #4]
	cmp	r0, r1
	bhs.n	.L080361ee
	b.n	.L080361cc
.L080361cc:
	ldr	r0, [sp, #8]
	ldr	r1, [sp, #0x10]
	add	r0, r1
	movw	r1, #0x12c0
	movt	r1, #0x2000
	ldrb	r0, [r1, r0]
	cmp	r0, #0xff
	beq.n	.L080361e4
	b.n	.L080361e2
.L080361e2:
	b.n	.L080361f0
.L080361e4:
	b.n	.L080361e6
.L080361e6:
	ldr	r0, [sp, #0x10]
	adds	r0, #1
	str	r0, [sp, #0x10]
	b.n	.L080361c2
.L080361ee:
	b.n	.L080361f0
.L080361f0:
	ldr	r0, [sp, #0x10]
	ldr	r1, [sp, #4]
	cmp	r0, r1
	bhs.n	.L08036246
	b.n	.L080361fa
.L080361fa:
	ldr	r0, [sp, #0xc]
	lsls	r0, r0, #12
	bl	serial_device_command_20_with_address
	movs	r0, #0
	str	r0, [sp, #0x10]
	b.n	.L08036208
.L08036208:
	ldr	r0, [sp, #0x10]
	ldr	r1, [sp, #4]
	cmp	r0, r1
	bhs.n	.L08036230
	b.n	.L08036212
.L08036212:
	ldr	r0, [sp, #0x1c]
	ldr	r1, [sp, #0x10]
	ldrb	r0, [r0, r1]
	ldr	r2, [sp, #8]
	add	r1, r2
	movw	r2, #0x12c0
	movt	r2, #0x2000
	strb	r0, [r2, r1]
	b.n	.L08036228
.L08036228:
	ldr	r0, [sp, #0x10]
	adds	r0, #1
	str	r0, [sp, #0x10]
	b.n	.L08036208
.L08036230:
	ldr	r0, [sp, #0xc]
	lsls	r1, r0, #12
	movw	r0, #0x12c0
	movt	r0, #0x2000
	mov.w	r2, #0x1000
	bl	serial_device_write_chunks
	b.n	.L08036254
.L08036246:
	ldr	r0, [sp, #0x1c]
	ldr	r1, [sp, #0x18]
	ldrh.w	r2, [sp, #4]
	bl	serial_device_write_chunks
	b.n	.L08036254
.L08036254:
	ldr	r0, [sp, #4]
	ldrh.w	r1, [sp, #0x16]
	cmp	r0, r1
	bne.n	.L08036262
	b.n	.L08036260
.L08036260:
	b.n	.L080362a8
.L08036262:
	ldr	r0, [sp, #0xc]
	adds	r0, #1
	str	r0, [sp, #0xc]
	movs	r0, #0
	str	r0, [sp, #8]
	ldr	r0, [sp, #4]
	ldr	r1, [sp, #0x1c]
	add	r0, r1
	str	r0, [sp, #0x1c]
	ldr	r0, [sp, #4]
	ldr	r1, [sp, #0x18]
	add	r0, r1
	str	r0, [sp, #0x18]
	ldr	r0, [sp, #4]
	ldrh.w	r1, [sp, #0x16]
	subs	r0, r1, r0
	strh.w	r0, [sp, #0x16]
	ldrh.w	r0, [sp, #0x16]
	cmp.w	r0, #0x1000
	ble.n	.L0803629c
	b.n	.L08036294
.L08036294:
	mov.w	r0, #0x1000
	str	r0, [sp, #4]
	b.n	.L080362a4
.L0803629c:
	ldrh.w	r0, [sp, #0x16]
	str	r0, [sp, #4]
	b.n	.L080362a4
.L080362a4:
	b.n	.L080362a6
.L080362a6:
	b.n	.L080361a8
.L080362a8:
	add	sp, #0x20
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ serial_device_write_chunks - splits a write of r2 (ushort) bytes from r0 to
@ address r1 into chunks of at most 0x100 bytes that do not cross a 0x100
@ boundary (first chunk 0x100 - (r1 & 0xff)) and calls
@ serial_device_write_bytes for each chunk.
@ ----------------------------------------------------------------------------
	.section .text.serial_device_write_chunks,"ax",%progbits
	.global serial_device_write_chunks
	.thumb_func
	.type serial_device_write_chunks, %function
serial_device_write_chunks:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0xc]
	str	r1, [sp, #8]
	strh.w	r2, [sp, #6]
	ldrb.w	r0, [sp, #8]
	rsb.w	r0, r0, #0x100
	strh.w	r0, [sp, #4]			@ first chunk size
	ldrh.w	r0, [sp, #6]
	ldrh.w	r1, [sp, #4]
	cmp	r0, r1
	bgt.n	.L080362dc
	b.n	.L080362d2
.L080362d2:
	ldrh.w	r0, [sp, #6]
	strh.w	r0, [sp, #4]
	b.n	.L080362dc
.L080362dc:
	b.n	.L080362de
.L080362de:
	ldr	r0, [sp, #0xc]
	ldr	r1, [sp, #8]
	ldrh.w	r2, [sp, #4]
	bl	serial_device_write_bytes
	ldrh.w	r0, [sp, #4]
	ldrh.w	r1, [sp, #6]
	cmp	r0, r1
	bne.n	.L080362fa
	b.n	.L080362f8
.L080362f8:
	b.n	.L08036340
.L080362fa:
	ldrh.w	r0, [sp, #4]
	ldr	r1, [sp, #0xc]
	add	r0, r1
	str	r0, [sp, #0xc]
	ldrh.w	r0, [sp, #4]
	ldr	r1, [sp, #8]
	add	r0, r1
	str	r0, [sp, #8]
	ldrh.w	r0, [sp, #4]
	ldrh.w	r1, [sp, #6]
	subs	r0, r1, r0
	strh.w	r0, [sp, #6]
	ldrh.w	r0, [sp, #6]
	cmp.w	r0, #0x100
	ble.n	.L08036332
	b.n	.L08036328
.L08036328:
	mov.w	r0, #0x100
	strh.w	r0, [sp, #4]
	b.n	.L0803633c
.L08036332:
	ldrh.w	r0, [sp, #6]
	strh.w	r0, [sp, #4]
	b.n	.L0803633c
.L0803633c:
	b.n	.L0803633e
.L0803633e:
	b.n	.L080362de
.L08036340:
	add	sp, #0x10
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ serial_device_send_command_6 - sends command byte 6.
@ Select (0x40010c14 = 0x1000), sends byte 6 with serial_device_transfer_byte,
@ deselect (0x40010c10 = 0x1000). Its effect on the device is not determined
@ from the code.
@ ----------------------------------------------------------------------------
	.section .text.serial_device_send_command_6,"ax",%progbits
	.global serial_device_send_command_6
	.thumb_func
	.type serial_device_send_command_6, %function
serial_device_send_command_6:
	push	{r4, lr}
	movw	r4, #0xc00
	movt	r4, #0x4001
	mov	r0, r4
	mov.w	r1, #0x1000
	str	r1, [r0, #0x14]			@ select
	nop
	movs	r0, #6
	bl	serial_device_transfer_byte
	mov	r0, r4
	mov.w	r1, #0x1000
	str	r1, [r0, #0x10]			@ deselect
	nop
	pop	{r4, pc}
	.short	0x0000				@ padding (aligns the next function)

@ ----------------------------------------------------------------------------
@ serial_device_write_bytes - writes the low 16 bits of r2 as byte count from
@ buffer r0 to the serial device address r1.
@ Calls serial_device_send_command_6, selects (0x40010c14 = 0x1000), sends
@ command byte 2, the address bytes (r1 >> 16, r1 >> 8, r1) and then the data
@ bytes with serial_device_transfer_byte, deselects (0x40010c10 = 0x1000) and
@ calls serial_device_wait_status_bit0_clear to wait for status bit 0 to clear.
@ ----------------------------------------------------------------------------
	.section .text.serial_device_write_bytes,"ax",%progbits
	.global serial_device_write_bytes
	.thumb_func
	.type serial_device_write_bytes, %function
serial_device_write_bytes:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0xc]
	str	r1, [sp, #8]
	strh.w	r2, [sp, #6]
	bl	serial_device_send_command_6
	movw	r0, #0xc00
	movt	r0, #0x4001
	mov.w	r1, #0x1000
	str	r1, [r0, #0x14]			@ select
	nop
	movs	r0, #2
	bl	serial_device_transfer_byte
	ldrb.w	r0, [sp, #0xa]
	bl	serial_device_transfer_byte
	ldrb.w	r0, [sp, #9]
	bl	serial_device_transfer_byte
	ldrb.w	r0, [sp, #8]
	bl	serial_device_transfer_byte
	b.n	.L080363ac
.L080363ac:
	ldrh.w	r0, [sp, #6]
	subs	r1, r0, #1
	strh.w	r1, [sp, #6]
	cbz	r0, .L080363ca
	b.n	.L080363ba
.L080363ba:
	ldr	r0, [sp, #0xc]
	ldrb	r0, [r0, #0]
	bl	serial_device_transfer_byte
	ldr	r0, [sp, #0xc]
	adds	r0, #1
	str	r0, [sp, #0xc]
	b.n	.L080363ac
.L080363ca:
	movw	r0, #0xc00
	movt	r0, #0x4001
	mov.w	r1, #0x1000
	str	r1, [r0, #0x10]			@ deselect
	nop
	bl	serial_device_wait_status_bit0_clear
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000				@ padding (aligns the next function)
