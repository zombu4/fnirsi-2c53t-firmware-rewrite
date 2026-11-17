@ image_17.s - show_bmp_file_fullscreen (draws a full-screen 16-bit image file) and file_read_or_skip_bytes (read or skip bytes of a file).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ show_bmp_file_fullscreen - draws a full-screen 16-bit image file.
@ No parameters, no return value.
@ A file object is allocated with alloc_units_of_32_bytes(0x102c); 0 ends the
@ function. file_open(obj, path pointer 0x20008360, mode 1) opens the file (the
@ caller 08011d08 formats the .bmp path into 0x20008360 per its own entry).
@ On success: file_read(obj, stack, 0x36, ..) skips a 0x36-byte header, then a
@ buffer = alloc_units_of_32_bytes(0x800). If the buffer is not 0:
@ write_window_xy_60020000(0,0,0x140,0xf0) sets the 320 x 240 window,
@ write_halfword_6001fffe_from_20008348() writes the halfword at 0x20008348 to
@ 0x6001fffe, then 0x4b times: file_read(obj, buffer, 0x800, ..) and for each of
@ the 0x400 halfwords v it rewrites it to
@ ((v & 0x7fff) >> 10) << 11 | ((v & 0x3ff) >> 5) << 6 | (v & 0x1f)
@ (5-5-5 source to 5-6-5 layout with green low bit 0) and passes it to
@ write_halfword_60020000 (write to 0x60020000); 0x4b * 0x400 = 76800 =
@ 320 * 240 pixels. Then the buffer is freed with free_units_of_32_bytes.
@ Always (also when open failed) it calls file_close(obj) and
@ free_units_of_32_bytes(obj).
@ ----------------------------------------------------------------------------
	.section .text.show_bmp_file_fullscreen,"ax",%progbits
	.global show_bmp_file_fullscreen
	.thumb_func
	.type show_bmp_file_fullscreen, %function
show_bmp_file_fullscreen:
	push	{r4, lr}
	sub	sp, #0x60
	movw	r0, #0x8360
	movt	r0, #0x2000
	str	r0, [sp, #0x5c]			@ path pointer 0x20008360
	movw	r0, #0x102c
	bl	alloc_units_of_32_bytes		@ file object
	str	r0, [sp, #0x58]
	ldr	r0, [sp, #0x58]
	cmp	r0, #0
	beq.w	.L08031660			@ allocation failed: return
	b.n	.L08031556
.L08031556:
	ldr	r0, [sp, #0x58]
	ldr	r1, [sp, #0x5c]
	movs	r2, #1				@ mode 1
	bl	file_open
	strb.w	r0, [sp, #0x57]
	ldrb.w	r0, [sp, #0x57]
	cmp	r0, #0
	bne.n	.L08031652			@ open failed: close and free
	b.n	.L0803156e
.L0803156e:
	ldr	r0, [sp, #0x58]
	add.w	r1, sp, #0x1a
	add	r3, sp, #0x50
	movs	r2, #0x36			@ skip the 0x36-byte header
	bl	file_read
	mov.w	r0, #0x800
	bl	alloc_units_of_32_bytes		@ pixel buffer
	str	r0, [sp, #0x10]
	ldr	r0, [sp, #0x10]
	cmp	r0, #0
	beq.n	.L08031650			@ no buffer
	b.n	.L0803158e
.L0803158e:
	mov.w	r0, #0x800
	str	r0, [sp, #0x14]			@ chunk size 0x800
	movs	r4, #0
	movs	r0, #0
	movs	r1, #0
	mov.w	r2, #0x140
	movs	r3, #0xf0
	bl	write_window_xy_60020000	@ 320 x 240 window
	bl	write_halfword_6001fffe_from_20008348
	str	r4, [sp, #0xc]			@ chunk counter = 0
	b.n	.L080315ac
.L080315ac:
	ldr	r0, [sp, #0xc]
	cmp	r0, #0x4a
	bhi.n	.L08031648			@ more than 0x4b chunks done
	b.n	.L080315b4
.L080315b4:
	ldr	r0, [sp, #0x58]
	ldr	r1, [sp, #0x10]
	ldr	r2, [sp, #0x14]
	add	r3, sp, #0x50
	bl	file_read			@ read 0x800 bytes
	movs	r0, #0
	str	r0, [sp, #0x8]			@ halfword index = 0
	b.n	.L080315c6
.L080315c6:
	ldr	r0, [sp, #0x8]
	movs	r1, #0
	cmp.w	r1, r0, lsr #10
	bne.n	.L0803163e			@ index >= 0x400: next chunk
	b.n	.L080315d2
.L080315d2:
	ldr	r0, [sp, #0x10]
	ldr	r1, [sp, #0x8]
	ldrh.w	r0, [r0, r1, lsl #1]
	strh.w	r0, [sp, #0x6]			@ v
	ldrh.w	r0, [sp, #0x6]
	ubfx	r0, r0, #10, #5			@ red
	strh.w	r0, [sp, #0x4]
	ldrh.w	r0, [sp, #0x6]
	ubfx	r0, r0, #5, #5			@ green
	strh.w	r0, [sp, #0x2]
	ldrh.w	r0, [sp, #0x6]
	and	r0, r0, #0x1f			@ blue
	strh.w	r0, [sp, #0x0]
	ldrh.w	r0, [sp, #0x2]
	lsls	r0, r0, #1			@ green << 1 (low bit 0)
	strh.w	r0, [sp, #0x2]
	ldrh.w	r0, [sp, #0x4]
	lsls	r0, r0, #11			@ red << 11
	ldrh.w	r1, [sp, #0x2]
	orr.w	r0, r0, r1, lsl #5		@ | green << 5
	ldrh.w	r1, [sp, #0x0]
	orrs	r0, r1				@ | blue
	ldr	r1, [sp, #0x10]
	ldr	r2, [sp, #0x8]
	strh.w	r0, [r1, r2, lsl #1]		@ rewritten halfword stored back
	ldr	r0, [sp, #0x10]
	ldr	r1, [sp, #0x8]
	ldrh.w	r0, [r0, r1, lsl #1]
	bl	write_halfword_60020000		@ write to 0x60020000
	b.n	.L08031636
.L08031636:
	ldr	r0, [sp, #0x8]
	adds	r0, #1
	str	r0, [sp, #0x8]
	b.n	.L080315c6
.L0803163e:
	b.n	.L08031640
.L08031640:
	ldr	r0, [sp, #0xc]
	adds	r0, #1
	str	r0, [sp, #0xc]
	b.n	.L080315ac
.L08031648:
	ldr	r0, [sp, #0x10]
	bl	free_units_of_32_bytes		@ free the pixel buffer
	b.n	.L08031650
.L08031650:
	b.n	.L08031652
.L08031652:
	ldr	r0, [sp, #0x58]
	bl	file_close
	ldr	r0, [sp, #0x58]
	bl	free_units_of_32_bytes		@ free the file object
	b.n	.L08031660
.L08031660:
	add	sp, #0x60
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ file_read_or_skip_bytes - read or skip bytes of a file.
@ With r0 holding a pointer chain (file object = **(r0+0x78)):
@ when r1 is 0 it calls file_seek(file, file[5]+r2) (080341e8) and returns r2,
@ or 0 when that call returned nonzero;
@ when r1 is non-null it calls file_read(file, r1, r2, &count) (08034cbc) and
@ returns the count read, or 0 when that call returned nonzero.
@ Purpose of the pointer chain at r0+0x78 not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.file_read_or_skip_bytes,"ax",%progbits
	.global file_read_or_skip_bytes
	.thumb_func
	.type file_read_or_skip_bytes, %function
file_read_or_skip_bytes:
	push	{r4, lr}
	sub	sp, #0x8
	ldr	r0, [r0, #0x78]
	ldr	r0, [r0, #0x0]			@ file object
	mov	r4, r2
	cbz	r1, .L0803750e			@ r1 == 0: seek
	add	r3, sp, #0x4			@ &count
	mov	r2, r4
	bl	file_read
	ldr	r4, [sp, #0x4]			@ count read
	cmp	r0, #0
	it	ne
	movne	r4, #0				@ read failed: 0
	b.n	.L0803751c
.L0803750e:
	ldr	r1, [r0, #0x14]
	add	r1, r4
	bl	file_seek
	cmp	r0, #0
	it	ne
	movne	r4, #0				@ seek failed: 0
.L0803751c:
	mov	r0, r4
	add	sp, #0x8
	pop	{r4, pc}
	.short	0x0000				@ padding
