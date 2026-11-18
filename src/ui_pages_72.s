@ ui_pages_72.s - fn_08012ff4: draws the header strip of a page (image, "H=" text, V/H or X/Y labels, markers)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08012ff4 - No parameters, no return value.
@ Draws "3:/System file/2.jpg" ("4.jpg" when byte [0x20000126]==0) at (0x34,0)
@ with decode_image_file_with_offset (08039f6c); formats "H=%s" with the string
@ pointer at 0x0804c988+4*[0x20000125] into 0x20008360 (format_to_buffer_080073b4)
@ and draws it with draw_wrapped_text_in_box (0800f154) as
@ (0x34,0,0x48,0x14,0x20008360,0x20001114,0xffff,1).
@ Then a switch on [0x2000044c]&0xf; colour c = halfword at
@ 0x080bb40c+4*[0x2000105b]+2*(bit7 of [0x2000044c]).
@ case 0: 0800f154(0xc4,0,0x24,0x14,"V",0x20001144,c,1) and "H" at
@   (0xe8,0,0x24,0x14) in 0xffff, flag 1.
@ case 1: fill_triangle 08020af8(0xd5,5,0xd5,0xd,0xd9,9,c), writes c into the
@   region-buffer pixels of rows 5..13 at columns 0xd1..0xd4 (bounds tested),
@   then fill_triangle(0xf5,6,0xff,6,0xfa,0xd,0x7e2).
@ case 2: fill_triangle(0xd1,9,0xd8,4,0xd8,0xe,0x7e2) then
@   fill_triangle(0xf5,6,0xff,6,0xfa,0xd,0x7e2).
@ case 3: by [0x20000332]: 1 draws "X1" at (0xc4,0,0x24,0x14) and "X2" at
@   (0xe8,0,0x24,0x14); 2 draws "Y1" and "Y2"; 3 draws "X1","Y1" when bit7 of
@   [0x2000044c] is clear, otherwise "X2","Y2"; other values draw nothing
@   (text style 0x20001144, colour 0xffff, flag 1).
@ Other values of [0x2000044c]&0xf: return.
@ ----------------------------------------------------------------------------
	.section .text.fn_08012ff4,"ax",%progbits
	.p2align 2
	.global fn_08012ff4
	.thumb_func
	.type fn_08012ff4, %function
fn_08012ff4:
	push	{r4, r5, r6, lr}
	sub	sp, #0x10
	movw	r6, #0xf8
	movt	r6, #0x2000
	ldrb.w	r1, [r6, #0x2e]
	adr	r2, .L080132fc
	adr	r0, .L08013314
	cmp	r1, #0
	it	eq
	moveq	r0, r2
	movs	r1, #0x34
	movs	r2, #0
	movw	r5, #0xffff
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r6, #0x2d]
	movw	r1, #:lower16:d_0804c988
	movt	r1, #:upper16:d_0804c988
	movw	r4, #0x8360
	ldr.w	r2, [r1, r0, lsl #2]
	movt	r4, #0x2000
	adr	r1, .L0801332c
	mov	r0, r4
	bl	format_to_buffer_080073b4
	movw	r1, #0x1114
	movs	r0, #1
	movt	r1, #0x2000
	strd	r4, r1, [sp]
	str	r0, [sp, #0xc]
	movs	r0, #0x34
	movs	r1, #0
	movs	r2, #0x48
	movs	r3, #0x14
	str	r5, [sp, #8]
	bl	draw_wrapped_text_in_box
	ldrb.w	r0, [r6, #0x354]
	and.w	r1, r0, #0xf
	cmp	r1, #3
	bhi.w	.L08013254
	tbb	[pc, r1]
.L0801306a:
	.byte	(.L0801306e - .L0801306a)/2
	.byte	(.L080130de - .L0801306a)/2
	.byte	(.L080130b0 - .L0801306a)/2
	.byte	(.L08013214 - .L0801306a)/2
.L0801306e:
	ldrb.w	r1, [r6, #0xf63]
	movw	r2, #:lower16:d_080bb40c
	movt	r2, #:upper16:d_080bb40c
	ubfx	r0, r0, #7, #1
	add.w	r1, r2, r1, lsl #2
	ldrh.w	r0, [r1, r0, lsl #1]
	movw	r6, #0x1144
	movw	r1, #:lower16:t_080bbd2e
	movt	r6, #0x2000
	movt	r1, #:upper16:t_080bbd2e
	movs	r4, #1
	strd	r1, r6, [sp]
	str	r0, [sp, #8]
	movs	r0, #0xc4
	movs	r1, #0
	movs	r2, #0x24
	movs	r3, #0x14
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	adr	r0, .L08013334
	b.n	.L080132e2
.L080130b0:
	movs	r0, #0xe
	movs	r1, #0xd8
	movw	r4, #0x7e2
	strd	r1, r0, [sp]
	movs	r0, #0xd1
	movs	r1, #9
	movs	r2, #0xd8
	movs	r3, #4
	str	r4, [sp, #8]
	bl	fill_triangle
	movs	r0, #0xd
	movs	r1, #0xfa
	strd	r1, r0, [sp]
	movs	r0, #0xf5
	movs	r1, #6
	movs	r2, #0xff
	movs	r3, #6
	str	r4, [sp, #8]
	b.n	.L0801326e
.L080130de:
	ldrb.w	r1, [r6, #0xf63]
	movw	r5, #:lower16:d_080bb40c
	movt	r5, #:upper16:d_080bb40c
	ubfx	r0, r0, #7, #1
	add.w	r1, r5, r1, lsl #2
	ldrh.w	r0, [r1, r0, lsl #1]
	movs	r1, #9
	movs	r2, #0xd9
	strd	r2, r1, [sp]
	str	r0, [sp, #8]
	movs	r0, #0xd5
	movs	r1, #5
	movs	r2, #0xd5
	movs	r3, #0xd
	movs	r4, #5
	bl	fill_triangle
	ldrb.w	r0, [r6, #0x354]
	ldrb.w	r1, [r6, #0xf63]
	ubfx	r0, r0, #7, #1
	add.w	r1, r5, r1, lsl #2
	ldrh.w	r0, [r1, r0, lsl #1]
	movw	r1, #0x8350
	movt	r1, #0x2000
	b.n	.L08013134
.L0801312c:
	adds	r4, #1
	cmp	r4, #0xe
	beq.w	.L08013258
.L08013134:
	ldrh	r2, [r1]
	cmp	r2, #0xd1
	bhi.n	.L0801316c
	ldrh	r2, [r1]
	ldrh	r3, [r1, #4]
	add	r2, r3
	cmp	r2, #0xd2
	bcc.n	.L0801316c
	ldrh	r2, [r1, #2]
	cmp	r4, r2
	bcc.n	.L0801316c
	ldrh	r2, [r1, #2]
	ldrh	r3, [r1, #6]
	add	r2, r3
	cmp	r2, r4
	bls.n	.L0801316c
	ldr	r2, [r1, #8]
	ldrh	r3, [r1]
	ldrh	r6, [r1, #2]
	ldrh	r5, [r1, #4]
	subs	r6, r4, r6
	muls	r6, r5, r6
	subs	r3, r6, r3
	add.w	r2, r2, r3, lsl #1
	strh.w	r0, [r2, #0x1a2]
	nop
.L0801316c:
	ldrh	r2, [r1]
	cmp	r2, #0xd2
	bhi.n	.L080131a4
	ldrh	r2, [r1]
	ldrh	r3, [r1, #4]
	add	r2, r3
	cmp	r2, #0xd3
	bcc.n	.L080131a4
	ldrh	r2, [r1, #2]
	cmp	r4, r2
	bcc.n	.L080131a4
	ldrh	r2, [r1, #2]
	ldrh	r3, [r1, #6]
	add	r2, r3
	cmp	r2, r4
	bls.n	.L080131a4
	ldr	r2, [r1, #8]
	ldrh	r3, [r1]
	ldrh	r6, [r1, #2]
	ldrh	r5, [r1, #4]
	subs	r6, r4, r6
	muls	r6, r5, r6
	subs	r3, r6, r3
	add.w	r2, r2, r3, lsl #1
	strh.w	r0, [r2, #0x1a4]
	nop
.L080131a4:
	ldrh	r2, [r1]
	cmp	r2, #0xd3
	bhi.n	.L080131dc
	ldrh	r2, [r1]
	ldrh	r3, [r1, #4]
	add	r2, r3
	cmp	r2, #0xd4
	bcc.n	.L080131dc
	ldrh	r2, [r1, #2]
	cmp	r4, r2
	bcc.n	.L080131dc
	ldrh	r2, [r1, #2]
	ldrh	r3, [r1, #6]
	add	r2, r3
	cmp	r2, r4
	bls.n	.L080131dc
	ldr	r2, [r1, #8]
	ldrh	r3, [r1]
	ldrh	r6, [r1, #2]
	ldrh	r5, [r1, #4]
	subs	r6, r4, r6
	muls	r6, r5, r6
	subs	r3, r6, r3
	add.w	r2, r2, r3, lsl #1
	strh.w	r0, [r2, #0x1a6]
	nop
.L080131dc:
	ldrh	r2, [r1]
	cmp	r2, #0xd4
	bhi.n	.L0801312c
	ldrh	r2, [r1]
	ldrh	r3, [r1, #4]
	add	r2, r3
	cmp	r2, #0xd5
	bcc.n	.L0801312c
	ldrh	r2, [r1, #2]
	cmp	r4, r2
	bcc.n	.L0801312c
	ldrh	r2, [r1, #2]
	ldrh	r3, [r1, #6]
	add	r2, r3
	cmp	r2, r4
	bls.n	.L0801312c
	ldr	r2, [r1, #8]
	ldrh	r3, [r1]
	ldrh	r6, [r1, #2]
	ldrh	r5, [r1, #4]
	subs	r6, r4, r6
	muls	r6, r5, r6
	subs	r3, r6, r3
	add.w	r2, r2, r3, lsl #1
	strh.w	r0, [r2, #0x1a8]
	b.n	.L0801312c
.L08013214:
	ldrb.w	r1, [r6, #0x23a]
	cmp	r1, #3
	beq.n	.L0801328a
	cmp	r1, #2
	beq.n	.L08013276
	cmp	r1, #1
	bne.n	.L08013254
	movw	r6, #0x1144
	movw	r0, #:lower16:t_080bb979
	movt	r6, #0x2000
	movt	r0, #:upper16:t_080bb979
	movs	r4, #1
	strd	r0, r6, [sp]
	movs	r0, #0xc4
	movs	r1, #0
	movs	r2, #0x24
	movs	r3, #0x14
	str	r5, [sp, #8]
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r0, #:lower16:t_080bb9e4
	movt	r0, #:upper16:t_080bb9e4
	b.n	.L080132e2
.L08013254:
	add	sp, #0x10
	pop	{r4, r5, r6, pc}
.L08013258:
	movs	r0, #0xd
	movs	r1, #0xfa
	movw	r6, #0x7e2
	strd	r1, r0, [sp]
	movs	r0, #0xf5
	movs	r1, #6
	movs	r2, #0xff
	movs	r3, #6
	str	r6, [sp, #8]
.L0801326e:
	bl	fill_triangle
	add	sp, #0x10
	pop	{r4, r5, r6, pc}
.L08013276:
	movw	r6, #0x1144
	movw	r0, #:lower16:t_080bb97c
	movs	r4, #1
	movt	r6, #0x2000
	movt	r0, #:upper16:t_080bb97c
	b.n	.L080132c6
.L0801328a:
	movw	r6, #0x1144
	movs	r4, #1
	movt	r6, #0x2000
	lsls	r0, r0, #24
	bmi.n	.L080132be
	movw	r0, #:lower16:t_080bb979
	movt	r0, #:upper16:t_080bb979
	strd	r0, r6, [sp]
	movs	r0, #0xc4
	movs	r1, #0
	movs	r2, #0x24
	movs	r3, #0x14
	str	r5, [sp, #8]
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r0, #:lower16:t_080bb97c
	movt	r0, #:upper16:t_080bb97c
	b.n	.L080132e2
.L080132be:
	movw	r0, #:lower16:t_080bb9e4
	movt	r0, #:upper16:t_080bb9e4
.L080132c6:
	strd	r0, r6, [sp]
	movs	r0, #0xc4
	movs	r1, #0
	movs	r2, #0x24
	movs	r3, #0x14
	str	r5, [sp, #8]
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r0, #:lower16:t_080bb9e7
	movt	r0, #:upper16:t_080bb9e7
.L080132e2:
	strd	r0, r6, [sp]
	movs	r0, #0xe8
	movs	r1, #0
	movs	r2, #0x24
	movs	r3, #0x14
	str	r5, [sp, #8]
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add	sp, #0x10
	pop	{r4, r5, r6, pc}
	.byte	0x00, 0xbf	@ padding
.L080132fc:
	.asciz	"3:/System file/4.jpg"
	.byte	0x00, 0x00, 0x00	@ padding
.L08013314:
	.asciz	"3:/System file/2.jpg"
	.byte	0x00, 0x00, 0x00	@ padding
.L0801332c:
	.asciz	"H=%s"
	.byte	0x00, 0x00, 0x00	@ padding
.L08013334:
	.asciz	"H"
	.short	0x0000	@ padding
