@ ui_pages_80.s - draw_language_list, draw_percent_bar, fn_0801f8e0, fn_0801f924 (UI page drawing routines)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ draw_language_list - draws a two-entry language choice ("中文", "English").
@ No parameters, no return value.
@ Row 1 (y 0x42): when byte 0x20001058 == 1, calls 08039f6c
@ (decode_image_file_with_offset) with "3:/System file/152.jpg", 0x44, 0x42 and
@ uses colour index 2; otherwise it fills solid colour 0x18c3 over x 0x45..0xfa,
@ y 0x43..0x5a (every pixel clipped to the halfwords 0x20008350/52/54/56 =
@ x, y, w, h; frame buffer pointer word at 0x20008358, RGB565 halfwords) and
@ uses colour index 1.
@ Then calls 0800f154 (draw_wrapped_text_in_box) with (0x44, 0x42, 0xb8, 0x1a,
@ text word 0x080bd09b ("中文"), font block 0x20001144, colour halfword
@ 0x0804c180 + idx*2, flag 1).
@ Row 2 (y 0x78): the same with byte 0x20001058 == 2, image at (0x44, 0x78),
@ fill y 0x79..0x90, text "English" (0x080bc6ae) at (0x44, 0x78, 0xb8, 0x1a).
@ Colour table 0x0804c180: idx 1 = 0xffff, idx 2 = 0x055f.
@ Purpose: the entry equal to byte 0x20001058 is highlighted by 152.jpg.
@ ----------------------------------------------------------------------------
	.section .text.draw_language_list,"ax",%progbits
	.p2align 2
	.global draw_language_list
	.thumb_func
	.type draw_language_list, %function
draw_language_list:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	sub	sp, #0x10
	movw	r9, #0xf8
	movt	r9, #0x2000
	ldrb.w	r0, [r9, #0xf60]	@ byte 0x20001058
	movw	r4, #0x8350
	cmp	r0, #0x1
	movt	r4, #0x2000		@ r4 = clip rectangle 0x20008350
	bne.n	.L0801f356
	movw	r0, #:lower16:t_080bc482
	movt	r0, #:upper16:t_080bc482
	movs	r1, #0x44
	movs	r2, #0x42
	bl	decode_image_file_with_offset
	movs	r0, #0x2
	b.n	.L0801f472
.L0801f356:
	movs	r0, #0x43
	mov.w	lr, #0x44
	movw	r12, #0x18c3
	b.n	.L0801f370
	.short	0xbf00			@ padding
.L0801f364:
	adds	r0, #0x2
	cmp	r0, #0x5b
	add.w	lr, lr, #0x2
	beq.w	.L0801f470
.L0801f370:
	movs	r3, #0x46
	b.n	.L0801f37a
.L0801f374:
	adds	r3, #0x2
	cmp	r3, #0xfc
	beq.n	.L0801f3ec
.L0801f37a:
	ldrh	r6, [r4, #0x0]
	subs	r7, r3, #0x1
	cmp	r7, r6
	bcc.n	.L0801f3b4
	ldrh	r6, [r4, #0x0]
	ldrh	r5, [r4, #0x4]
	add	r6, r5
	cmp	r6, r7
	bls.n	.L0801f3b4
	ldrh	r7, [r4, #0x2]
	cmp	r0, r7
	bcc.n	.L0801f3b4
	ldrh	r7, [r4, #0x2]
	ldrh	r6, [r4, #0x6]
	add	r7, r6
	cmp	r7, r0
	bls.n	.L0801f3b4
	ldr	r7, [r4, #0x8]
	ldrh	r6, [r4, #0x0]
	ldrh	r5, [r4, #0x2]
	ldrh	r2, [r4, #0x4]
	subs	r5, r0, r5
	muls	r2, r5
	subs	r2, r2, r6
	add	r2, r3
	add.w	r2, r7, r2, lsl #0x1
	strh.w	r12, [r2, #-0x2]
.L0801f3b4:
	ldrh	r2, [r4, #0x0]
	cmp	r3, r2
	bcc.n	.L0801f374
	ldrh	r2, [r4, #0x0]
	ldrh	r7, [r4, #0x4]
	add	r2, r7
	cmp	r2, r3
	bls.n	.L0801f374
	ldrh	r2, [r4, #0x2]
	cmp	r0, r2
	bcc.n	.L0801f374
	ldrh	r2, [r4, #0x2]
	ldrh	r7, [r4, #0x6]
	add	r2, r7
	cmp	r2, r0
	bls.n	.L0801f374
	ldr	r2, [r4, #0x8]
	ldrh	r7, [r4, #0x0]
	ldrh	r6, [r4, #0x2]
	ldrh	r5, [r4, #0x4]
	subs	r6, r0, r6
	muls	r6, r5
	subs	r7, r6, r7
	add	r7, r3
	strh.w	r12, [r2, r7, lsl #0x1]
	b.n	.L0801f374
	.short	0xbf00			@ padding
.L0801f3ec:
	adds	r3, r0, #0x1
	movs	r7, #0x46
	b.n	.L0801f3fa
	.short	0xbf00			@ padding
.L0801f3f4:
	adds	r7, #0x2
	cmp	r7, #0xfc
	beq.n	.L0801f364
.L0801f3fa:
	ldrh	r2, [r4, #0x0]
	subs	r6, r7, #0x1
	cmp	r6, r2
	bcc.n	.L0801f438
	ldrh	r2, [r4, #0x0]
	ldrh	r5, [r4, #0x4]
	add	r2, r5
	cmp	r2, r6
	bls.n	.L0801f438
	ldrh	r2, [r4, #0x2]
	cmp	r3, r2
	bcc.n	.L0801f438
	ldrh	r2, [r4, #0x2]
	ldrh	r6, [r4, #0x6]
	add	r2, r6
	cmp	r2, r3
	bls.n	.L0801f438
	ldr	r2, [r4, #0x8]
	ldrh	r6, [r4, #0x0]
	ldrh	r5, [r4, #0x2]
	ldrh	r1, [r4, #0x4]
	sub.w	r5, lr, r5
	muls	r1, r5
	subs	r1, r1, r6
	add	r1, r7
	add.w	r1, r2, r1, lsl #0x1
	strh.w	r12, [r1, #-0x2]
	nop
.L0801f438:
	ldrh	r1, [r4, #0x0]
	cmp	r7, r1
	bcc.n	.L0801f3f4
	ldrh	r1, [r4, #0x0]
	ldrh	r2, [r4, #0x4]
	add	r1, r2
	cmp	r1, r7
	bls.n	.L0801f3f4
	ldrh	r1, [r4, #0x2]
	cmp	r3, r1
	bcc.n	.L0801f3f4
	ldrh	r1, [r4, #0x2]
	ldrh	r2, [r4, #0x6]
	add	r1, r2
	cmp	r1, r3
	bls.n	.L0801f3f4
	ldr	r1, [r4, #0x8]
	ldrh	r2, [r4, #0x0]
	ldrh	r5, [r4, #0x2]
	ldrh	r6, [r4, #0x4]
	sub.w	r5, lr, r5
	muls	r5, r6
	subs	r2, r5, r2
	add	r2, r7
	strh.w	r12, [r1, r2, lsl #0x1]
	b.n	.L0801f3f4
.L0801f470:
	movs	r0, #0x1
.L0801f472:
	movw	r10, #:lower16:d_0804c180
	movt	r10, #:upper16:d_0804c180
	ldrh.w	r0, [r10, r0, lsl #0x1]	@ colour halfword idx*2
	movw	r2, #:lower16:t_080bd09b
	movs	r1, #0x1
	movw	r8, #0x1144
	movt	r2, #:upper16:t_080bd09b
	movt	r8, #0x2000		@ r8 = font block 0x20001144
	str	r2, [sp, #0x0]
	strd	r0, r1, [sp, #0x8]
	movs	r0, #0x44
	movs	r1, #0x42
	movs	r2, #0xb8
	movs	r3, #0x1a
	str.w	r8, [sp, #0x4]
	bl	draw_wrapped_text_in_box
	ldrb.w	r0, [r9, #0xf60]
	cmp	r0, #0x2
	bne.n	.L0801f4c2
	movw	r0, #:lower16:t_080bc482
	movt	r0, #:upper16:t_080bc482
	movs	r1, #0x44
	movs	r2, #0x78
	bl	decode_image_file_with_offset
	movs	r0, #0x2
	b.n	.L0801f5de
.L0801f4c2:
	movs	r0, #0x79
	mov.w	lr, #0x7a
	movw	r12, #0x18c3
	b.n	.L0801f4dc
	.short	0xbf00			@ padding
.L0801f4d0:
	adds	r0, #0x2
	cmp	r0, #0x91
	add.w	lr, lr, #0x2
	beq.w	.L0801f5dc
.L0801f4dc:
	movs	r3, #0x46
	b.n	.L0801f4e6
.L0801f4e0:
	adds	r3, #0x2
	cmp	r3, #0xfc
	beq.n	.L0801f558
.L0801f4e6:
	ldrh	r6, [r4, #0x0]
	subs	r5, r3, #0x1
	cmp	r5, r6
	bcc.n	.L0801f520
	ldrh	r6, [r4, #0x0]
	ldrh	r7, [r4, #0x4]
	add	r7, r6
	cmp	r7, r5
	bls.n	.L0801f520
	ldrh	r7, [r4, #0x2]
	cmp	r0, r7
	bcc.n	.L0801f520
	ldrh	r7, [r4, #0x2]
	ldrh	r6, [r4, #0x6]
	add	r7, r6
	cmp	r7, r0
	bls.n	.L0801f520
	ldr	r7, [r4, #0x8]
	ldrh	r6, [r4, #0x0]
	ldrh	r5, [r4, #0x2]
	ldrh	r2, [r4, #0x4]
	subs	r5, r0, r5
	muls	r2, r5
	subs	r2, r2, r6
	add	r2, r3
	add.w	r2, r7, r2, lsl #0x1
	strh.w	r12, [r2, #-0x2]
.L0801f520:
	ldrh	r2, [r4, #0x0]
	cmp	r3, r2
	bcc.n	.L0801f4e0
	ldrh	r2, [r4, #0x0]
	ldrh	r7, [r4, #0x4]
	add	r2, r7
	cmp	r2, r3
	bls.n	.L0801f4e0
	ldrh	r2, [r4, #0x2]
	cmp	r0, r2
	bcc.n	.L0801f4e0
	ldrh	r2, [r4, #0x2]
	ldrh	r7, [r4, #0x6]
	add	r2, r7
	cmp	r2, r0
	bls.n	.L0801f4e0
	ldr	r2, [r4, #0x8]
	ldrh	r7, [r4, #0x0]
	ldrh	r6, [r4, #0x2]
	ldrh	r5, [r4, #0x4]
	subs	r6, r0, r6
	muls	r6, r5
	subs	r7, r6, r7
	add	r7, r3
	strh.w	r12, [r2, r7, lsl #0x1]
	b.n	.L0801f4e0
	.short	0xbf00			@ padding
.L0801f558:
	adds	r3, r0, #0x1
	movs	r5, #0x46
	b.n	.L0801f566
	.short	0xbf00			@ padding
.L0801f560:
	adds	r5, #0x2
	cmp	r5, #0xfc
	beq.n	.L0801f4d0
.L0801f566:
	ldrh	r2, [r4, #0x0]
	subs	r6, r5, #0x1
	cmp	r6, r2
	bcc.n	.L0801f5a4
	ldrh	r2, [r4, #0x0]
	ldrh	r7, [r4, #0x4]
	add	r2, r7
	cmp	r2, r6
	bls.n	.L0801f5a4
	ldrh	r2, [r4, #0x2]
	cmp	r3, r2
	bcc.n	.L0801f5a4
	ldrh	r2, [r4, #0x2]
	ldrh	r7, [r4, #0x6]
	add	r2, r7
	cmp	r2, r3
	bls.n	.L0801f5a4
	ldr	r2, [r4, #0x8]
	ldrh	r7, [r4, #0x0]
	ldrh	r6, [r4, #0x2]
	ldrh	r1, [r4, #0x4]
	sub.w	r6, lr, r6
	muls	r1, r6
	subs	r1, r1, r7
	add	r1, r5
	add.w	r1, r2, r1, lsl #0x1
	strh.w	r12, [r1, #-0x2]
	nop
.L0801f5a4:
	ldrh	r1, [r4, #0x0]
	cmp	r5, r1
	bcc.n	.L0801f560
	ldrh	r1, [r4, #0x0]
	ldrh	r2, [r4, #0x4]
	add	r1, r2
	cmp	r1, r5
	bls.n	.L0801f560
	ldrh	r1, [r4, #0x2]
	cmp	r3, r1
	bcc.n	.L0801f560
	ldrh	r1, [r4, #0x2]
	ldrh	r2, [r4, #0x6]
	add	r1, r2
	cmp	r1, r3
	bls.n	.L0801f560
	ldr	r1, [r4, #0x8]
	ldrh	r2, [r4, #0x0]
	ldrh	r6, [r4, #0x2]
	ldrh	r7, [r4, #0x4]
	sub.w	r6, lr, r6
	muls	r6, r7
	subs	r2, r6, r2
	add	r2, r5
	strh.w	r12, [r1, r2, lsl #0x1]
	b.n	.L0801f560
.L0801f5dc:
	movs	r0, #0x1
.L0801f5de:
	ldrh.w	r0, [r10, r0, lsl #0x1]	@ colour halfword idx*2
	movw	r1, #:lower16:t_080bc6ae
	movt	r1, #:upper16:t_080bc6ae
	movs	r7, #0x1
	strd	r1, r8, [sp, #0x0]
	str	r0, [sp, #0x8]
	movs	r0, #0x44
	movs	r1, #0x78
	movs	r2, #0xb8
	movs	r3, #0x1a
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add	sp, #0x10
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ draw_percent_bar - draws a 14x6 pixel bar filled in proportion to a byte.
@ No parameters, no return value.
@ Every pixel write uses the clip rectangle at 0x20008350/52/54/56 (x, y, w, h
@ halfwords) and the buffer pointer at 0x20008358 (RGB565 halfwords, address =
@ buf + ((y - clipY) * clipW + (x - clipX)) * 2); a write outside the clip is
@ skipped.
@ Step 1: fills the rectangle x 0x122..0x12f, y 7..12 (outer loop y = 7, 9, 11
@ writing rows y and y + 1) with colour 0x422.
@ Step 2: v = byte 0x2000105f; returns when v <= 10; colour 0xffff, or 0xfb80
@ when v < 0x3d; xe = (int)(v / 100.0 * 14.0 + 290.0 - 1.0) (float); returns
@ when xe < 0x122; otherwise fills x 0x122..xe, y 7..12 (groups of rows y, y+1,
@ y+2 for y = 7, 10) with that colour.
@ What byte 0x2000105f measures is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.draw_percent_bar,"ax",%progbits
	.p2align 2
	.global draw_percent_bar
	.thumb_func
	.type draw_percent_bar, %function
draw_percent_bar:
	push	{r4, r5, r6, r7, lr}
	movw	r0, #0x8350
	movs	r1, #0x7
	mov.w	lr, #0x8
	movt	r0, #0x2000		@ r0 = clip rectangle 0x20008350
	movw	r12, #0x422
	b.n	.L0801f684
	.short	0xbf00			@ padding
.L0801f678:
	adds	r1, #0x2
	cmp	r1, #0xd
	add.w	lr, lr, #0x2
	beq.w	.L0801f78a
.L0801f684:
	mov.w	r3, #0x122
	b.n	.L0801f694
	.short	0xbf00			@ padding
.L0801f68c:
	adds	r3, #0x2
	cmp.w	r3, #0x130
	beq.n	.L0801f704
.L0801f694:
	ldrh	r2, [r0, #0x0]
	cmp	r3, r2
	bcc.n	.L0801f6c8
	ldrh	r2, [r0, #0x0]
	ldrh	r4, [r0, #0x4]
	add	r2, r4
	cmp	r2, r3
	bls.n	.L0801f6c8
	ldrh	r2, [r0, #0x2]
	cmp	r1, r2
	bcc.n	.L0801f6c8
	ldrh	r2, [r0, #0x2]
	ldrh	r4, [r0, #0x6]
	add	r2, r4
	cmp	r2, r1
	bls.n	.L0801f6c8
	ldr	r2, [r0, #0x8]
	ldrh	r4, [r0, #0x0]
	ldrh	r5, [r0, #0x2]
	ldrh	r6, [r0, #0x4]
	subs	r5, r1, r5
	muls	r5, r6
	subs	r4, r5, r4
	add	r4, r3
	strh.w	r12, [r2, r4, lsl #0x1]
.L0801f6c8:
	ldrh	r4, [r0, #0x0]
	adds	r2, r3, #0x1
	cmp	r2, r4
	bcc.n	.L0801f68c
	ldrh	r4, [r0, #0x0]
	ldrh	r5, [r0, #0x4]
	add	r4, r5
	cmp	r4, r2
	bls.n	.L0801f68c
	ldrh	r2, [r0, #0x2]
	cmp	r1, r2
	bcc.n	.L0801f68c
	ldrh	r2, [r0, #0x2]
	ldrh	r4, [r0, #0x6]
	add	r2, r4
	cmp	r2, r1
	bls.n	.L0801f68c
	ldr	r2, [r0, #0x8]
	ldrh	r4, [r0, #0x0]
	ldrh	r5, [r0, #0x2]
	ldrh	r6, [r0, #0x4]
	subs	r5, r1, r5
	muls	r5, r6
	subs	r4, r5, r4
	add	r4, r3
	add.w	r2, r2, r4, lsl #0x1
	strh.w	r12, [r2, #0x2]
	b.n	.L0801f68c
.L0801f704:
	adds	r3, r1, #0x1
	mov.w	r2, #0x122
	b.n	.L0801f714
.L0801f70c:
	adds	r2, #0x2
	cmp.w	r2, #0x130
	beq.n	.L0801f678
.L0801f714:
	ldrh	r4, [r0, #0x0]
	cmp	r2, r4
	bcc.n	.L0801f74c
	ldrh	r4, [r0, #0x0]
	ldrh	r5, [r0, #0x4]
	add	r4, r5
	cmp	r4, r2
	bls.n	.L0801f74c
	ldrh	r4, [r0, #0x2]
	cmp	r3, r4
	bcc.n	.L0801f74c
	ldrh	r4, [r0, #0x2]
	ldrh	r5, [r0, #0x6]
	add	r4, r5
	cmp	r4, r3
	bls.n	.L0801f74c
	ldr	r4, [r0, #0x8]
	ldrh	r5, [r0, #0x0]
	ldrh	r6, [r0, #0x2]
	ldrh	r7, [r0, #0x4]
	sub.w	r6, lr, r6
	muls	r6, r7
	subs	r5, r6, r5
	add	r5, r2
	strh.w	r12, [r4, r5, lsl #0x1]
	nop
.L0801f74c:
	ldrh	r5, [r0, #0x0]
	adds	r4, r2, #0x1
	cmp	r4, r5
	bcc.n	.L0801f70c
	ldrh	r5, [r0, #0x0]
	ldrh	r6, [r0, #0x4]
	add	r5, r6
	cmp	r5, r4
	bls.n	.L0801f70c
	ldrh	r4, [r0, #0x2]
	cmp	r3, r4
	bcc.n	.L0801f70c
	ldrh	r4, [r0, #0x2]
	ldrh	r5, [r0, #0x6]
	add	r4, r5
	cmp	r4, r3
	bls.n	.L0801f70c
	ldr	r4, [r0, #0x8]
	ldrh	r5, [r0, #0x0]
	ldrh	r6, [r0, #0x2]
	ldrh	r7, [r0, #0x4]
	sub.w	r6, lr, r6
	muls	r6, r7
	subs	r5, r6, r5
	add	r5, r2
	add.w	r4, r4, r5, lsl #0x1
	strh.w	r12, [r4, #0x2]
	b.n	.L0801f70c
.L0801f78a:
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldrb.w	r2, [r1, #0xf67]	@ byte 0x2000105f
	cmp	r2, #0xb
	bcs.n	.L0801f79c
.L0801f79a:
	pop	{r4, r5, r6, r7, pc}
.L0801f79c:
	vmov	s0, r2
	vldr	s2, .L0801f8d8		@ 100.0
	vcvt.f32.u32	s0, s0
	vdiv.f32	s0, s0, s2
	vmov.f32	s2, #14.0
	vldr	s4, .L0801f8dc		@ 290.0
	mov.w	r12, #0xffffffff
	cmp	r2, #0x3d
	itt	cc
	movwcc	r12, #0xfb80
	movtcc	r12, #0xffff
	vmul.f32	s0, s0, s2
	vadd.f32	s0, s0, s4
	vmov.f32	s2, #-1.0
	vadd.f32	s0, s0, s2
	vcvt.s32.f32	s0, s0
	vmov	r1, s0			@ r1 = xe
	cmp.w	r1, #0x122
	it	lt
	poplt	{r4, r5, r6, r7, pc}
	mov.w	lr, #0x7
	b.n	.L0801f7f6
	.short	0xbf00			@ padding
.L0801f7ec:
	add.w	lr, lr, #0x3
	cmp.w	lr, #0xd
	beq.n	.L0801f79a
.L0801f7f6:
	mov.w	r2, #0x122
	b.n	.L0801f804
.L0801f7fc:
	adds	r2, #0x1
	sxth	r2, r2
	cmp	r2, r1
	bgt.n	.L0801f840
.L0801f804:
	ldrh	r4, [r0, #0x0]
	sxth	r3, r2
	cmp	r3, r4
	blt.n	.L0801f7fc
	ldrh	r4, [r0, #0x0]
	ldrh	r5, [r0, #0x4]
	add	r4, r5
	cmp	r4, r3
	ble.n	.L0801f7fc
	ldrh	r4, [r0, #0x2]
	cmp	lr, r4
	bcc.n	.L0801f7fc
	ldrh	r4, [r0, #0x2]
	ldrh	r5, [r0, #0x6]
	add	r4, r5
	cmp	r4, lr
	bls.n	.L0801f7fc
	ldr	r4, [r0, #0x8]
	ldrh	r5, [r0, #0x0]
	subs	r3, r3, r5
	ldrh	r5, [r0, #0x2]
	ldrh	r6, [r0, #0x4]
	sub.w	r5, lr, r5
	mla	r3, r5, r6, r3
	strh.w	r12, [r4, r3, lsl #0x1]
	b.n	.L0801f7fc
	.short	0xbf00			@ padding
.L0801f840:
	add.w	r2, lr, #0x1
	mov.w	r3, #0x122
	b.n	.L0801f854
	.short	0xbf00			@ padding
.L0801f84c:
	adds	r3, #0x1
	sxth	r3, r3
	cmp	r3, r1
	bgt.n	.L0801f88c
.L0801f854:
	ldrh	r5, [r0, #0x0]
	sxth	r4, r3
	cmp	r4, r5
	blt.n	.L0801f84c
	ldrh	r5, [r0, #0x0]
	ldrh	r6, [r0, #0x4]
	add	r5, r6
	cmp	r5, r4
	ble.n	.L0801f84c
	ldrh	r5, [r0, #0x2]
	cmp	r2, r5
	bcc.n	.L0801f84c
	ldrh	r5, [r0, #0x2]
	ldrh	r6, [r0, #0x6]
	add	r5, r6
	cmp	r5, r2
	bls.n	.L0801f84c
	ldr	r5, [r0, #0x8]
	ldrh	r6, [r0, #0x0]
	subs	r4, r4, r6
	ldrh	r6, [r0, #0x2]
	ldrh	r7, [r0, #0x4]
	subs	r6, r2, r6
	mla	r4, r6, r7, r4
	strh.w	r12, [r5, r4, lsl #0x1]
	b.n	.L0801f84c
.L0801f88c:
	add.w	r2, lr, #0x2
	mov.w	r3, #0x122
	b.n	.L0801f8a0
	.short	0xbf00			@ padding
.L0801f898:
	adds	r3, #0x1
	sxth	r3, r3
	cmp	r3, r1
	bgt.n	.L0801f7ec
.L0801f8a0:
	ldrh	r5, [r0, #0x0]
	sxth	r4, r3
	cmp	r4, r5
	blt.n	.L0801f898
	ldrh	r5, [r0, #0x0]
	ldrh	r6, [r0, #0x4]
	add	r5, r6
	cmp	r5, r4
	ble.n	.L0801f898
	ldrh	r5, [r0, #0x2]
	cmp	r2, r5
	bcc.n	.L0801f898
	ldrh	r5, [r0, #0x2]
	ldrh	r6, [r0, #0x6]
	add	r5, r6
	cmp	r5, r2
	bls.n	.L0801f898
	ldr	r5, [r0, #0x8]
	ldrh	r6, [r0, #0x0]
	subs	r4, r4, r6
	ldrh	r6, [r0, #0x2]
	ldrh	r7, [r0, #0x4]
	subs	r6, r2, r6
	mla	r4, r6, r7, r4
	strh.w	r12, [r5, r4, lsl #0x1]
	b.n	.L0801f898
.L0801f8d8:
	.word	0x42c80000		@ 100.0f
.L0801f8dc:
	.word	0x43910000		@ 290.0f

@ ----------------------------------------------------------------------------
@ fn_0801f8e0 - builds a numbered image file path and hands it to the loader.
@ No parameters, no return value.
@ n = byte 0x20000f51 - 13 * byte 0x20000f50 + 0x17 (ldrb at 0x0801f8ea /
@ 0x0801f8ee, smlabb with -13 at 0x0801f8fa, add 0x17 at 0x0801f906).
@ Calls 080073b4 (format_to_buffer_080073b4) with destination 0x20008360,
@ format string at 0x080bc681 (text 3:/System file/%d.jpg) and n; then
@ tail-branches to 08039f6c (decode_image_file_with_offset) with
@ (0x20008360, 0, 0) (path string, x = 0, y = 0).
@ The meaning of the two source bytes is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0801f8e0,"ax",%progbits
	.p2align 2
	.global fn_0801f8e0
	.thumb_func
	.type fn_0801f8e0, %function
fn_0801f8e0:
	push	{r4, lr}
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r1, [r0, #0xe58]	@ byte 0x20000f50
	ldrb.w	r0, [r0, #0xe59]	@ byte 0x20000f51
	mvn.w	r2, #0xc		@ r2 = -13
	movw	r4, #0x8360
	smlabb	r0, r1, r2, r0
	movt	r4, #0x2000		@ r4 = destination 0x20008360
	movw	r1, #:lower16:t_080bc681
	add.w	r2, r0, #0x17		@ n
	movt	r1, #:upper16:t_080bc681
	mov	r0, r4
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0x0
	movs	r2, #0x0
	pop.w	{r4, lr}
	b.w	decode_image_file_with_offset
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0801f924 - selects one of two fixed image paths and hands it to the loader.
@ No parameters, no return value.
@ path = string at 0x080bc51e (3:/System file/5.jpg); when byte 0x2000105f
@ (ldrb at 0x0801f92c) is <= 10 (cmp #10, bhi at 0x0801f930) and bit 7 of the
@ word at 0x40011008 is set (lsls #24 at 0x0801f946, movmi at 0x0801f950), path
@ = string at 0x080bc576 (3:/System file/6.jpg). Tail-branches to 08039f6c
@ (decode_image_file_with_offset) with (path, 0x10c, 0) (x = 0x10c, y = 0).
@ What the two paths stand for is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0801f924,"ax",%progbits
	.p2align 2
	.global fn_0801f924
	.thumb_func
	.type fn_0801f924, %function
fn_0801f924:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf67]	@ byte 0x2000105f
	cmp	r0, #0xa
	movw	r0, #:lower16:t_080bc51e
	movt	r0, #:upper16:t_080bc51e
	bhi.n	.L0801f954
	movw	r1, #0x1008
	movt	r1, #0x4001
	ldr	r1, [r1, #0x0]		@ word 0x40011008
	lsls	r1, r1, #0x18		@ bit 7 to the sign flag
	movw	r1, #:lower16:t_080bc576
	movt	r1, #:upper16:t_080bc576
	it	mi
	movmi	r0, r1
.L0801f954:
	mov.w	r1, #0x10c
	movs	r2, #0x0
	b.w	decode_image_file_with_offset
	.short	0x0000			@ padding
