@ ui_pages_79.s - UI page drawing routines: image + texts page, top-of-screen image/text, page position bar, bottom strip
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ draw_image_two_texts_and_s_value - no parameters, no return value.
@ Calls decode_image_file_with_offset("3:/System file/145.jpg", 0x46, 0x43).
@ Then draw_wrapped_text_in_box(0x48, 0x48, 0xb0, 0x14, "Battery low, charge
@ now", font block 0x200010e4, colour 0, flag 1) and
@ draw_wrapped_text_in_box(0x48, 0x7a, 0xb0, 0x28, "Auto shutdown soon", font
@ 0x200010e4, colour 0xf800, flag 0x81).
@ Formats "%ds" of (0xe - byte 0x2000105e) with format_to_buffer_080073b4 into
@ 0x20008360 and draws it with draw_wrapped_text_in_box(0x48, 0x61, 0xb0, 0x19,
@ 0x20008360, font 0x20001174, colour 0xf800, flag 0x81).
@ Purpose: draws an image, the two warning texts and the text "%ds" of
@ (0xe - byte 0x2000105e); what the count is for is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.draw_image_two_texts_and_s_value,"ax",%progbits
	.p2align 2
	.global draw_image_two_texts_and_s_value
	.thumb_func
	.type draw_image_two_texts_and_s_value, %function
draw_image_two_texts_and_s_value:
	push	{r4, r5, r6, r7, lr}
	sub	sp, #0x14
	movw	r0, #:lower16:t_080bc533
	movt	r0, #:upper16:t_080bc533
	movs	r1, #0x46
	movs	r2, #0x43
	bl	decode_image_file_with_offset
	movw	r4, #0xf8
	movt	r4, #0x2000
	movw	r0, #:lower16:t_080bceb4	@ "Battery low, charge now"
	movt	r0, #:upper16:t_080bceb4
	movs	r1, #0x1
	movs	r2, #0x0
	movw	r6, #0x10e4
	movt	r6, #0x2000
	str	r0, [sp, #0x0]
	strd	r2, r1, [sp, #0x8]
	movs	r0, #0x48
	movs	r1, #0x48
	movs	r2, #0xb0
	movs	r3, #0x14
	str	r6, [sp, #0x4]
	bl	draw_wrapped_text_in_box
	movw	r0, #:lower16:t_080bc8ae	@ "Auto shutdown soon"
	movt	r0, #:upper16:t_080bc8ae
	movs	r5, #0x81
	mov.w	r7, #0xf800
	stm.w	sp, {r0, r6, r7}
	movs	r0, #0x48
	movs	r1, #0x7a
	movs	r2, #0xb0
	movs	r3, #0x28
	str	r5, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb.w	r0, [r4, #0xf66]
	movw	r4, #0x8360
	movt	r4, #0x2000
	movw	r1, #:lower16:t_080bcc3f
	rsb.w	r2, r0, #0xe
	movt	r1, #:upper16:t_080bcc3f
	mov	r0, r4
	bl	format_to_buffer_080073b4
	movw	r0, #0x1174
	movt	r0, #0x2000
	strd	r4, r0, [sp, #0x0]
	movs	r0, #0x48
	movs	r1, #0x61
	movs	r2, #0xb0
	movs	r3, #0x19
	str	r7, [sp, #0x8]
	str	r5, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add	sp, #0x14
	pop	{r4, r5, r6, r7, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0801e514 - no parameters, no return value.
@ Calls decode_image_file_with_offset("3:/System file/71.jpg", 0, 0), then
@ draw_wrapped_text_in_box(0x34, 0, 0xd8, 0x14, "Image Viewer", font block
@ 0x20001144, colour 0xffff, flag 1).
@ Purpose: draws an image file and the title "Image Viewer" at the top of the
@ screen.
@ ----------------------------------------------------------------------------
	.section .text.fn_0801e514,"ax",%progbits
	.p2align 2
	.global fn_0801e514
	.thumb_func
	.type fn_0801e514, %function
fn_0801e514:
	push	{r7, lr}
	sub	sp, #0x10
	movw	r0, #:lower16:t_080bc456
	movt	r0, #:upper16:t_080bc456
	movs	r1, #0x0
	movs	r2, #0x0
	bl	decode_image_file_with_offset
	movw	r0, #:lower16:t_080bcb6e	@ "Image Viewer"
	movt	r0, #:upper16:t_080bcb6e
	movw	r2, #0x1144
	movw	r1, #0xffff
	movt	r2, #0x2000
	mov.w	r12, #0x1
	strd	r0, r2, [sp, #0x0]
	str	r1, [sp, #0x8]
	movs	r0, #0x34
	movs	r1, #0x0
	movs	r2, #0xd8
	movs	r3, #0x14
	str.w	r12, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ draw_page_position_bar - no parameters, no return value.
@ n = byte 0x20000f13 (count), pages = ceil(n/6) (n/6, plus 1 when n%6 != 0),
@ page = byte 0x20000f15 / 6, h = udiv(0xad, pages) (pages == 0 divides by zero:
@ result depends on the core divide-by-zero setting, not determined from the
@ code), start = h*page, end = h*(page+1).
@ Draws a 2-pixel wide vertical bar of colour 0x8c73 at x=0x13a and x=0x13b
@ (clipped to halfwords 0x20008350/52/54/56, buffer word 0x20008358) for
@ y = start+0x1d .. end+0x1c (the first row alone when h is odd, then two rows
@ per loop pass; nothing when h == 1 after that row).
@ Purpose: draws a 2-pixel wide vertical bar of height 173/pages (integer
@ divide) at offset page*height for byte 0x20000f13 items counted 6 per page,
@ page = byte 0x20000f15 / 6.
@ ----------------------------------------------------------------------------
	.section .text.draw_page_position_bar,"ax",%progbits
	.p2align 2
	.global draw_page_position_bar
	.thumb_func
	.type draw_page_position_bar, %function
draw_page_position_bar:
	push	{r4, r5, r6, lr}
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	lr, [r0, #0xe1b]
	movw	r12, #0xaaab
	ldrb.w	r0, [r0, #0xe1d]
	uxtb.w	r2, lr
	movt	r12, #0xaaaa
	umull	r2, r3, r2, r12
	umull	r0, r2, r0, r12
	lsrs	r0, r3, #2
	sub.w	r1, r0, r0, lsl #2
	lsls	r1, r1, #1
	uxtb.w	r12, r1
	rsb.w	r1, lr, #0
	uxtb	r1, r1
	cmp	r12, r1
	mov.w	r1, #0xad
	mov.w	lr, #1
	it	ne
	addne.w	r0, lr, r3, lsr #2
	udiv	r1, r1, r0
	lsrs	r0, r2, #2
	add.w	r2, lr, r2, lsr #2
	mul	r3, r1, r0
	mul	lr, r2, r1
	add.w	r0, r3, #0x1d
	add.w	r2, lr, #0x1c
	cmp	r0, r2
	bls.n	.L0801e5d8
.L0801e5d6:
	pop	{r4, r5, r6, pc}
.L0801e5d8:
	lsls	r1, r1, #0x1f
	movw	r1, #0x8350
	add.w	r12, r3, #1
	movt	r1, #0x2000
	beq.n	.L0801e670
	ldrh	r2, [r1, #0x0]
	cmp.w	r2, #0x13a
	bhi.n	.L0801e62a
	ldrh	r2, [r1, #0x0]
	ldrh	r4, [r1, #4]
	add	r2, r4
	cmp.w	r2, #0x13a
	bls.n	.L0801e62a
	ldrh	r2, [r1, #2]
	cmp	r0, r2
	bcc.n	.L0801e62a
	ldrh	r2, [r1, #2]
	ldrh	r4, [r1, #6]
	add	r2, r4
	cmp	r2, r0
	bls.n	.L0801e62a
	ldr	r2, [r1, #8]
	ldrh	r4, [r1, #0x0]
	ldrh	r5, [r1, #2]
	ldrh	r6, [r1, #4]
	subs	r5, r0, r5
	muls	r5, r6, r5
	subs	r4, r5, r4
	add.w	r2, r2, r4, lsl #1
	movw	r4, #0x8c73
	movt	r4, #0xffff
	strh.w	r4, [r2, #0x274]
.L0801e62a:
	ldrh	r2, [r1, #0x0]
	lsrs	r2, r2, #2
	cmp	r2, #0x4e
	bhi.n	.L0801e66c
	ldrh	r2, [r1, #0x0]
	ldrh	r4, [r1, #4]
	add	r2, r4
	cmp.w	r2, #0x13c
	bcc.n	.L0801e66c
	ldrh	r2, [r1, #2]
	cmp	r0, r2
	bcc.n	.L0801e66c
	ldrh	r2, [r1, #2]
	ldrh	r4, [r1, #6]
	add	r2, r4
	cmp	r2, r0
	bls.n	.L0801e66c
	ldr	r2, [r1, #8]
	ldrh	r4, [r1, #0x0]
	ldrh	r5, [r1, #2]
	ldrh	r6, [r1, #4]
	subs	r0, r0, r5
	muls	r0, r6, r0
	subs	r0, r0, r4
	add.w	r0, r2, r0, lsl #1
	movw	r2, #0x8c73
	movt	r2, #0xffff
	strh.w	r2, [r0, #0x276]
.L0801e66c:
	add.w	r0, r3, #0x1e
.L0801e670:
	cmp	lr, r12
	it	eq
	popeq	{r4, r5, r6, pc}
	movw	r12, #0x8c73
	add.w	r3, lr, #0x1b
	b.n	.L0801e688
.L0801e680:
	cmp	r0, r3
	add.w	r0, r0, #0x2
	beq.n	.L0801e5d6
.L0801e688:
	ldrh	r2, [r1, #0x0]
	cmp.w	r2, #0x13a
	bhi.n	.L0801e6c4
	ldrh	r2, [r1, #0x0]
	ldrh	r6, [r1, #4]
	add	r2, r6
	cmp.w	r2, #0x13a
	bls.n	.L0801e6c4
	ldrh	r2, [r1, #2]
	cmp	r0, r2
	bcc.n	.L0801e6c4
	ldrh	r2, [r1, #2]
	ldrh	r6, [r1, #6]
	add	r2, r6
	cmp	r2, r0
	bls.n	.L0801e6c4
	ldr	r2, [r1, #8]
	ldrh	r6, [r1, #0x0]
	ldrh	r5, [r1, #2]
	ldrh	r4, [r1, #4]
	subs	r5, r0, r5
	muls	r5, r4, r5
	subs	r6, r5, r6
	add.w	r2, r2, r6, lsl #1
	strh.w	r12, [r2, #0x274]
	nop
.L0801e6c4:
	ldrh	r2, [r1, #0x0]
	lsrs	r2, r2, #2
	cmp	r2, #0x4e
	bhi.n	.L0801e700
	ldrh	r2, [r1, #0x0]
	ldrh	r6, [r1, #4]
	add	r2, r6
	cmp.w	r2, #0x13c
	bcc.n	.L0801e700
	ldrh	r2, [r1, #2]
	cmp	r0, r2
	bcc.n	.L0801e700
	ldrh	r2, [r1, #2]
	ldrh	r6, [r1, #6]
	add	r2, r6
	cmp	r2, r0
	bls.n	.L0801e700
	ldr	r2, [r1, #8]
	ldrh	r6, [r1, #0x0]
	ldrh	r5, [r1, #2]
	ldrh	r4, [r1, #4]
	subs	r5, r0, r5
	muls	r5, r4, r5
	subs	r6, r5, r6
	add.w	r2, r2, r6, lsl #1
	strh.w	r12, [r2, #0x276]
	nop
.L0801e700:
	ldrh	r2, [r1, #0x0]
	cmp.w	r2, #0x13a
	add.w	r2, r0, #1
	bhi.n	.L0801e744
	ldrh	r6, [r1, #0x0]
	ldrh	r5, [r1, #4]
	add	r6, r5
	cmp.w	r6, #0x13a
	bls.n	.L0801e744
	ldrh	r6, [r1, #2]
	cmp	r2, r6
	bcc.n	.L0801e744
	ldrh	r6, [r1, #2]
	ldrh	r5, [r1, #6]
	add	r6, r5
	cmp	r6, r2
	bls.n	.L0801e744
	ldr.w	lr, [r1, #8]
	ldrh	r5, [r1, #0x0]
	ldrh	r4, [r1, #2]
	ldrh	r6, [r1, #4]
	subs	r4, r0, r4
	adds	r4, #1
	muls	r4, r6, r4
	subs	r4, r4, r5
	add.w	r6, lr, r4, lsl #1
	strh.w	r12, [r6, #0x274]
	nop
.L0801e744:
	ldrh	r6, [r1, #0x0]
	lsrs	r6, r6, #2
	cmp	r6, #0x4e
	bhi.n	.L0801e680
	ldrh	r6, [r1, #0x0]
	ldrh	r5, [r1, #4]
	add	r6, r5
	cmp.w	r6, #0x13c
	bcc.n	.L0801e680
	ldrh	r6, [r1, #2]
	cmp	r2, r6
	bcc.n	.L0801e680
	ldrh	r6, [r1, #2]
	ldrh	r5, [r1, #6]
	add	r6, r5
	cmp	r6, r2
	bls.w	.L0801e680
	ldr	r2, [r1, #8]
	ldrh	r6, [r1, #0x0]
	ldrh	r5, [r1, #2]
	ldrh	r4, [r1, #4]
	subs	r5, r0, r5
	adds	r5, #1
	muls	r5, r4, r5
	subs	r6, r5, r6
	add.w	r2, r2, r6, lsl #1
	strh.w	r12, [r2, #0x276]
	b.n	.L0801e680

@ ----------------------------------------------------------------------------
@ draw_bottom_strip - no parameters, no return value.
@ This rewrite (V1.4.14): cells for the 20 px font: left x 0 width 0x69, centre x 0x6c width 0x67,
@ right x 0xd7 width 0x69 (V1.2.0: 0 / 0x5d, 0x7f / 0x56, 0xe3 / 0x5d; "500mV X10 DC" is 97 px,
@ "Normal" + icon + "CH2" 96 px); 3.jpg has its separators in the gaps. The coordinates below are
@ V1.2.0's.
@ Calls decode_image_file_with_offset("3:/System file/3.jpg", 0, 0xdd).
@ Left cell (x 0, width 0x5d, y 0xdd, h 0x13, font block 0x20001114, flag 0):
@ word at 0x0804c954+(byte 0x200000fe*3+byte 0x200000fa)*4, colour halfword at
@ 0x080bb40c+byte(0x2000105b)*4; right cell at x 0xe3: word at
@ 0x0804c954+(byte 0x200000ff*3+byte 0x200000fb)*4, colour halfword at
@ 0x080bb40e+byte(0x2000105b)*4.
@ Text widths are measured with a loop of decode_utf8_char (0803a40c) and the
@ glyph callback word 0x20001114 (adds the 16-bit width, stops at code 0, 10 or
@ 13 (mask 0x2401 for codes <= 0xd) or when the callback returns 0).
@ Left cell also: word at 0x0804c7bc+byte(0x200000fe)*4 drawn at x = width of
@ the left text, width 0x5d - width(left text) - width(word
@ 0x0804c7c4+byte(0x200000f8)*4), colour 0xffff, flag 1, and the word
@ 0x0804c7c4+byte(0x200000f8)*4 right-aligned (flag 2) over the whole cell;
@ right cell identically with bytes 0x200000ff, 0x200000f9 and x+0xe3.
@ Centre: word byte(0x2000010f) of the English mode table d_0804c7e4 at
@ (0x7f, 0xdd, 0x56, 0x13, colour 0xffff, flag 0); then a 16x16 1-bit bitmap at
@ 0x0804d7d3+byte(0x20000110)*0x20 (2 bytes per row, most significant bit
@ first, rows y=0xdf..0xee) is plotted pixel by pixel (set bits only, clipped
@ to halfwords 0x20008350/52/54/56, buffer word 0x20008358) at
@ x = w+(0x56-w-width(word 0x0804c7fc+byte(0x2000010e)*4))/2+0x77 with w the
@ width of the centre text, colour halfword at
@ 0x080bb40c+byte(0x2000010e)*2+byte(0x2000105b)*4; last, the word
@ 0x0804c7fc+byte(0x2000010e)*4 right-aligned (flag 2) at
@ (0x7f, 0xdd, 0x56, 0x13, 0xffff).
@ Purpose: draws, over 3.jpg at y 0xdd, two side cells each with a text, a
@ second text placed after it and a third text right-aligned, and a centre cell
@ with a text, a 16x16 1-bit bitmap and a text, as listed; the meaning of the
@ bytes 0x200000f8..0x200000ff and 0x2000010e..0x20000110 is not determined
@ from the code.
@ ----------------------------------------------------------------------------
	.section .text.draw_bottom_strip,"ax",%progbits
	.p2align 2
	.global draw_bottom_strip
	.thumb_func
	.type draw_bottom_strip, %function
draw_bottom_strip:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0x2c
	adr.w	r0, .L0801edd0
	movs	r1, #0x0
	movs	r2, #0xdd
	mov.w	r8, #0x0
	bl	decode_image_file_with_offset
	movw	r4, #0xf8
	movt	r4, #0x2000
	ldrb	r0, [r4, #6]
	ldrb	r1, [r4, #2]
	add.w	r0, r0, r0, lsl #1
	add	r0, r1
	movw	r7, #:lower16:d_0804c954
	ldrb.w	r1, [r4, #0xf63]
	movw	r5, #:lower16:d_080bb40c
	movt	r7, #:upper16:d_0804c954
	movt	r5, #:upper16:d_080bb40c
	ldr.w	r0, [r7, r0, lsl #2]
	ldrh.w	r1, [r5, r1, lsl #2]
	movw	r6, #0x1144			@ 20 px font (this rewrite; V1.2.0 18 px 0x20001114): texts and their measuring
	movt	r6, #0x2000
	strd	r0, r6, [sp, #0x0]
	str	r1, [sp, #8]
	movs	r0, #0x0
	movs	r1, #0xdd
	movs	r2, #0x69
	movs	r3, #0x13
	str.w	r8, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb	r0, [r4, #7]
	ldrb	r1, [r4, #3]
	add.w	r0, r0, r0, lsl #1
	add	r0, r1
	ldrb.w	r1, [r4, #0xf63]
	ldr.w	r0, [r7, r0, lsl #2]
	add.w	r1, r5, r1, lsl #2
	ldrh	r1, [r1, #2]
	strd	r0, r6, [sp, #0x0]
	str	r1, [sp, #8]
	movs	r0, #0xd7
	movs	r1, #0xdd
	movs	r2, #0x69
	movs	r3, #0x13
	str.w	r8, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb	r0, [r4, #6]
	ldrb	r1, [r4, #2]
	add.w	r0, r0, r0, lsl #1
	add	r0, r1
	ldr.w	r5, [r7, r0, lsl #2]
	add	r7, sp, #0x1c
	add.w	r10, sp, #0x20
	mov.w	r9, #0x1
	movw	r11, #0x2401
	str.w	r8, [sp, #0x1c]
.L0801e834:
	mov	r0, r5
	mov	r1, r7
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0801e84c
	lsl.w	r0, r9, r2
	tst.w	r0, r11
	bne.n	.L0801e860
.L0801e84c:
	ldr	r4, [r6]
	mov	r0, r6
	mov	r1, r10
	movs	r3, #0x0
	blx	r4
	cbz	r0, .L0801e860
	ldrh.w	r0, [sp, #0x20]
	add	r8, r0
	b.n	.L0801e834
.L0801e860:
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldrb	r0, [r1, #6]
	ldrb	r1, [r1, #2]
	add.w	r0, r0, r0, lsl #1
	add	r0, r1
	movw	r1, #:lower16:d_0804c954
	movt	r1, #:upper16:d_0804c954
	ldr.w	r5, [r1, r0, lsl #2]
	movs	r4, #0x0
	add.w	r10, sp, #0x1c
	add.w	r11, sp, #0x20
	movw	r9, #0x2401
	str	r4, [sp, #0x1c]
	nop
.L0801e890:
	mov	r0, r5
	mov	r1, r10
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0801e8a8
	movs	r0, #0x1
	lsls	r0, r2
	tst.w	r0, r9
	bne.n	.L0801e8bc
.L0801e8a8:
	ldr	r7, [r6]
	mov	r0, r6
	mov	r1, r11
	movs	r3, #0x0
	blx	r7
	cbz	r0, .L0801e8bc
	ldrh.w	r0, [sp, #0x20]
	add	r4, r0
	b.n	.L0801e890
.L0801e8bc:
	rsb.w	r0, r4, #0x69
	str	r0, [sp, #0x18]
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb	r0, [r0]
	movw	r1, #:lower16:d_0804c7c4
	movt	r1, #:upper16:d_0804c7c4
	ldr.w	r5, [r1, r0, lsl #2]
	mov.w	r11, #0x0
	add	r7, sp, #0x1c
	add.w	r10, sp, #0x20
	movw	r9, #0x2401
	str.w	r11, [sp, #0x1c]
	nop
.L0801e8ec:
	mov	r0, r5
	mov	r1, r7
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0801e904
	movs	r0, #0x1
	lsls	r0, r2
	tst.w	r0, r9
	bne.n	.L0801e918
.L0801e904:
	ldr	r4, [r6]
	mov	r0, r6
	mov	r1, r10
	movs	r3, #0x0
	blx	r4
	cbz	r0, .L0801e918
	ldrh.w	r0, [sp, #0x20]
	add	r11, r0
	b.n	.L0801e8ec
.L0801e918:
	movw	r4, #0xf8
	movt	r4, #0x2000
	ldrb	r0, [r4, #6]
	movw	r1, #:lower16:d_0804c7bc
	movt	r1, #:upper16:d_0804c7bc
	ldr.w	r0, [r1, r0, lsl #2]
	ldr	r1, [sp, #0x18]
	movw	r2, #0xffff
	sub.w	r1, r1, r11
	mov.w	r11, #0x1
	strd	r0, r6, [sp, #0x0]
	str	r2, [sp, #8]
	uxth	r2, r1
	sxth.w	r0, r8
	movs	r1, #0xdd
	movs	r3, #0x13
	str.w	r11, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb	r0, [r4, #7]
	ldrb	r1, [r4, #3]
	add.w	r0, r0, r0, lsl #1
	add	r0, r1
	movw	r1, #:lower16:d_0804c954
	movt	r1, #:upper16:d_0804c954
	ldr.w	r5, [r1, r0, lsl #2]
	movs	r4, #0x0
	add.w	r10, sp, #0x1c
	add.w	r9, sp, #0x20
	movw	r8, #0x2401
	str	r4, [sp, #0x1c]
	nop
.L0801e97c:
	mov	r0, r5
	mov	r1, r10
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0801e994
	lsl.w	r0, r11, r2
	tst.w	r0, r8
	bne.n	.L0801e9a8
.L0801e994:
	ldr	r7, [r6]
	mov	r0, r6
	mov	r1, r9
	movs	r3, #0x0
	blx	r7
	cbz	r0, .L0801e9a8
	ldrh.w	r0, [sp, #0x20]
	add	r4, r0
	b.n	.L0801e97c
.L0801e9a8:
	movw	r1, #0xf8
	add.w	r0, r4, #0xd7
	movt	r1, #0x2000
	str	r0, [sp, #0x18]
	ldrb	r0, [r1, #7]
	ldrb	r1, [r1, #3]
	add.w	r0, r0, r0, lsl #1
	add	r0, r1
	movw	r1, #:lower16:d_0804c954
	movt	r1, #:upper16:d_0804c954
	ldr.w	r5, [r1, r0, lsl #2]
	movs	r4, #0x0
	add.w	r10, sp, #0x1c
	add.w	r8, sp, #0x20
	mov.w	r9, #0x1
	movw	r11, #0x2401
	str	r4, [sp, #0x1c]
.L0801e9e0:
	mov	r0, r5
	mov	r1, r10
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0801e9f8
	lsl.w	r0, r9, r2
	tst.w	r0, r11
	bne.n	.L0801ea0c
.L0801e9f8:
	ldr	r7, [r6]
	mov	r0, r6
	mov	r1, r8
	movs	r3, #0x0
	blx	r7
	cbz	r0, .L0801ea0c
	ldrh.w	r0, [sp, #0x20]
	add	r4, r0
	b.n	.L0801e9e0
.L0801ea0c:
	movw	r0, #0xf8
	movt	r0, #0x2000
	rsb.w	r1, r4, #0x69
	ldrb	r0, [r0, #1]
	str	r1, [sp, #0x14]
	movw	r1, #:lower16:d_0804c7c4
	movt	r1, #:upper16:d_0804c7c4
	ldr.w	r5, [r1, r0, lsl #2]
	movs	r4, #0x0
	add.w	r10, sp, #0x1c
	add.w	r11, sp, #0x20
	mov.w	r9, #0x1
	movw	r8, #0x2401
	str	r4, [sp, #0x1c]
.L0801ea3c:
	mov	r0, r5
	mov	r1, r10
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0801ea54
	lsl.w	r0, r9, r2
	tst.w	r0, r8
	bne.n	.L0801ea68
.L0801ea54:
	ldr	r7, [r6]
	mov	r0, r6
	mov	r1, r11
	movs	r3, #0x0
	blx	r7
	cbz	r0, .L0801ea68
	ldrh.w	r0, [sp, #0x20]
	add	r4, r0
	b.n	.L0801ea3c
.L0801ea68:
	movw	r7, #0xf8
	movt	r7, #0x2000
	ldrb	r0, [r7, #7]
	movw	r1, #:lower16:d_0804c7bc
	movt	r1, #:upper16:d_0804c7bc
	ldr.w	r0, [r1, r0, lsl #2]
	ldr	r1, [sp, #0x14]
	strd	r0, r6, [sp, #0x0]
	ldr	r0, [sp, #0x18]
	subs	r1, r1, r4
	movs	r5, #0x1
	movw	r9, #0xffff
	uxth	r2, r1
	sxth	r0, r0
	movs	r1, #0xdd
	movs	r3, #0x13
	str.w	r9, [sp, #0x8]
	str	r5, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb	r0, [r7, #0x0]
	movw	r5, #:lower16:d_0804c7c4
	movt	r5, #:upper16:d_0804c7c4
	ldr.w	r0, [r5, r0, lsl #2]
	mov.w	r8, #0x2
	stm.w	sp, {r0, r6, r9}
	movs	r0, #0x0
	movs	r1, #0xdd
	movs	r2, #0x69
	movs	r3, #0x13
	str.w	r8, [sp, #0xc]
	movs	r4, #0x0
	bl	draw_wrapped_text_in_box
	ldrb	r0, [r7, #0x1]
	movs	r1, #0xdd
	ldr.w	r0, [r5, r0, lsl #2]
	movs	r2, #0x69
	strd	r0, r6, [sp, #0x0]
	movs	r0, #0xd7
	movs	r3, #0x13
	str.w	r8, [sp, #0xc]
	str.w	r9, [sp, #8]
	bl	draw_wrapped_text_in_box
	movw	r5, #:lower16:d_0804c7e4	@ English trigger mode names
	ldrb	r0, [r7, #0x17]			@ mode byte 0x2000010f
	movt	r5, #:upper16:d_0804c7e4
	ldr.w	r0, [r5, r0, lsl #2]
	movs	r1, #0xdd
	stm.w	sp, {r0, r6, r9}
	movs	r0, #0x6c
	movs	r2, #0x67
	movs	r3, #0x13
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb	r0, [r7, #0x17]
	add.w	r10, sp, #0x1c
	ldr.w	r5, [r5, r0, lsl #2]
	add.w	r11, sp, #0x20
	movw	r9, #0x2401
	str	r4, [sp, #0x1c]
.L0801eb30:
	mov	r0, r5
	mov	r1, r10
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0801eb48
	movs	r0, #0x1
	lsls	r0, r2
	tst.w	r0, r9
	bne.n	.L0801eb5c
.L0801eb48:
	ldr	r7, [r6]
	mov	r0, r6
	mov	r1, r11
	movs	r3, #0x0
	blx	r7
	cbz	r0, .L0801eb5c
	ldrh.w	r0, [sp, #0x20]
	add	r4, r0
	b.n	.L0801eb30
.L0801eb5c:
	movs	r0, #0x6c
	uxtah	r0, r0, r4
	str	r0, [sp, #0x18]
	movw	r0, #0xf8
	movt	r0, #0x2000
	movw	r2, #:lower16:d_0804c7e4
	ldrb	r0, [r0, #0x17]
	movt	r2, #:upper16:d_0804c7e4
	ldr.w	r5, [r2, r0, lsl #2]
	movs	r4, #0x0
	add.w	r10, sp, #0x1c
	add.w	r11, sp, #0x20
	mov.w	r8, #0x1
	movw	r9, #0x2401
	str	r4, [sp, #0x1c]
	nop
.L0801eb98:
	mov	r0, r5
	mov	r1, r10
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0801ebb0
	lsl.w	r0, r8, r2
	tst.w	r0, r9
	bne.n	.L0801ebc4
.L0801ebb0:
	ldr	r7, [r6]
	mov	r0, r6
	mov	r1, r11
	movs	r3, #0x0
	blx	r7
	cbz	r0, .L0801ebc4
	ldrh.w	r0, [sp, #0x20]
	add	r4, r0
	b.n	.L0801eb98
.L0801ebc4:
	uxth	r0, r4
	rsb.w	r0, r0, #0x67
	str	r0, [sp, #0x14]
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb	r0, [r0, #0x16]
	movw	r1, #:lower16:d_0804c7fc
	movt	r1, #:upper16:d_0804c7fc
	ldr.w	r5, [r1, r0, lsl #2]
	movs	r4, #0x0
	add.w	r10, sp, #0x1c
	add.w	r8, sp, #0x20
	mov.w	r9, #0x1
	movw	r11, #0x2401
	str	r4, [sp, #0x1c]
	nop
.L0801ebf8:
	mov	r0, r5
	mov	r1, r10
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0801ec10
	lsl.w	r0, r9, r2
	tst.w	r0, r11
	bne.n	.L0801ec24
.L0801ec10:
	ldr	r7, [r6]
	mov	r0, r6
	mov	r1, r8
	movs	r3, #0x0
	blx	r7
	cbz	r0, .L0801ec24
	ldrh.w	r0, [sp, #0x20]
	add	r4, r0
	b.n	.L0801ebf8
.L0801ec24:
	ldr	r1, [sp, #0x14]
	uxth	r0, r4
	subs	r0, r1, r0
	ldr	r1, [sp, #0x18]
	add.w	r0, r0, r0, lsr #0x1f
	add.w	r0, r1, r0, lsr #1
	movw	r1, #0xf8
	movt	r1, #0x2000
	sub.w	r3, r0, #0x8
	ldrb.w	r0, [r1, #0xf63]
	movw	r2, #:lower16:d_080bb40c
	ldrb	r7, [r1, #0x16]
	movt	r2, #:upper16:d_080bb40c
	ldrb	r1, [r1, #0x18]
	add.w	r0, r2, r0, lsl #2
	movw	r2, #:lower16:d_0804d7d3	@ own label of the 1-bit rows at 0x0804d7d3 (was d_0804d7d2+1)
	ldrh.w	r11, [r0, r7, lsl #1]
	sxth.w	r8, r3
	movt	r2, #:upper16:d_0804d7d3	@ own label of the 1-bit rows at 0x0804d7d3 (was d_0804d7d2+1)
	movw	r10, #0x8350
	str	r7, [sp, #0x14]
	add.w	r7, r8, #0x10
	movs	r0, #0x0
	mov.w	r12, #0xdf
	add.w	r5, r2, r1, lsl #5
	movt	r10, #0x2000
	movs	r4, #0x0
	str	r3, [sp, #0x18]
	b.n	.L0801ec90
	.byte	0x00, 0xbf	@ padding
.L0801ec84:
	add.w	r12, r12, #0x2
	cmp.w	r12, #0xef
	beq.w	.L0801ed9a
.L0801ec90:
	lsls	r0, r0, #0x18
	it	ne
	addne	r4, #1
	ldr	r2, [sp, #0x18]
	movs	r0, #0x0
	mov	r3, r8
	b.n	.L0801ecb4
	.byte	0x00, 0xbf	@ padding
.L0801eca0:
	adds	r0, #1
	uxtb	r1, r0
	adds	r2, #1
	cmp	r1, #7
	sxth	r3, r2
	itt	hi
	addhi	r4, #1
	movhi	r0, #0x0
	cmp	r7, r3
	ble.n	.L0801ed14
.L0801ecb4:
	uxth	r6, r4
	ldrb	r6, [r5, r6]
	uxtb	r1, r0
	rsb.w	r1, r1, #7
	lsr.w	r1, r6, r1
	lsls	r1, r1, #0x1f
	beq.n	.L0801eca0
	ldrh.w	r1, [r10]
	cmp	r3, r1
	blt.n	.L0801eca0
	ldrh.w	r1, [r10, #0x0]
	ldrh.w	r6, [r10, #4]
	add	r1, r6
	cmp	r1, r3
	ble.n	.L0801eca0
	ldrh.w	r1, [r10, #2]
	cmp	r12, r1
	bcc.n	.L0801eca0
	ldrh.w	r1, [r10, #2]
	ldrh.w	r6, [r10, #6]
	add	r1, r6
	cmp	r1, r12
	bls.n	.L0801eca0
	ldr.w	r9, [r10, #8]
	ldrh.w	r6, [r10]
	subs	r3, r3, r6
	ldrh.w	r6, [r10, #2]
	ldrh.w	r1, [r10, #4]
	sub.w	r6, r12, r6
	mla	r1, r6, r1, r3
	strh.w	r11, [r9, r1, lsl #1]
	b.n	.L0801eca0
	.byte	0x00, 0xbf	@ padding
.L0801ed14:
	lsls	r0, r0, #0x18
	it	ne
	addne	r4, #1
	ldr	r2, [sp, #0x18]
	add.w	r3, r12, #1
	movs	r0, #0x0
	mov	r9, r8
	b.n	.L0801ed3e
	.byte	0x00, 0xbf	@ padding
.L0801ed28:
	adds	r0, #1
	uxtb	r1, r0
	adds	r2, #1
	cmp	r1, #7
	sxth.w	r9, r2
	itt	hi
	addhi	r4, #1
	movhi	r0, #0x0
	cmp	r7, r9
	ble.n	.L0801ec84
.L0801ed3e:
	uxth	r1, r4
	ldrb	r1, [r5, r1]
	uxtb	r6, r0
	rsb.w	r6, r6, #7
	lsrs	r1, r6
	lsls	r1, r1, #0x1f
	beq.n	.L0801ed28
	ldrh.w	r1, [r10]
	cmp	r9, r1
	blt.n	.L0801ed28
	ldrh.w	r1, [r10]
	ldrh.w	r6, [r10, #4]
	add	r1, r6
	cmp	r1, r9
	ble.n	.L0801ed28
	ldrh.w	r1, [r10, #2]
	cmp	r3, r1
	bcc.n	.L0801ed28
	ldrh.w	r1, [r10, #2]
	ldrh.w	r6, [r10, #6]
	add	r1, r6
	cmp	r1, r3
	bls.n	.L0801ed28
	ldr.w	r1, [r10, #8]
	ldrh.w	r6, [r10]
	sub.w	r9, r9, r6
	ldrh.w	r6, [r10, #2]
	ldrh.w	lr, [r10, #4]
	subs	r6, r3, r6
	mla	r6, r6, lr, r9
	strh.w	r11, [r1, r6, lsl #1]
	b.n	.L0801ed28
.L0801ed9a:
	movw	r0, #:lower16:d_0804c7fc
	ldr	r1, [sp, #0x14]
	movt	r0, #:upper16:d_0804c7fc
	ldr.w	r0, [r0, r1, lsl #2]
	movs	r7, #0x2
	str	r0, [sp]
	movw	r0, #0x1114
	movt	r0, #0x2000
	str	r0, [sp, #4]
	movw	r0, #0xffff
	str	r0, [sp, #8]
	movs	r0, #0x6c
	movs	r1, #0xdd
	movs	r2, #0x67
	movs	r3, #0x13
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add	sp, #0x2c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0801edd0:
	.asciz	"3:/System file/3.jpg"
	.byte	0x00, 0x00, 0x00	@ padding

@ ----------------------------------------------------------------------------
@ draw_thumbnail_grid - no parameters, no return value.
@ page = byte 0x20000f15 / 6; for cell k=0..5 the index idx = page*6+k; returns
@ when idx >= byte 0x20000f13; file id = byte 0x20000f1d[idx]; calls
@ read_numbered_bin_file(id) (0803a310, reads the 0x25f-byte record into the
@ buffer pointer word 0x20000f18).
@ Record fields: start = bswap16(halfword at buf+0x25b), type = byte buf+0x25a,
@ count = bswap16(halfword at buf+0x25d); type 2 draws channel 1 only, type 3
@ channels 0 and 1, type 4 draws an XY line plot, any other value is used
@ directly as the nibble pair (hi = value>>4, lo = value&0xf; type 0 draws
@ nothing, type 1 gives hi=0, lo=1 and draws channel 0 only).
@ Cell origin x0 = (k%3)*0x68, y0 = (k/3)*0x56; channel mode: for
@ i = start..start+count-2 0801fea8(x0+(i/3)+1, y0+0x60+D(s[i]-0x1c),
@ x0+(i/3)+2, y0+0x60+D(s[i+1]-0x1c), colour halfword at
@ 0x080bb40c+ch*2+byte(0x2000105b)*4), where D(v) = (h-v)/2 rounded toward zero
@ and h = high word of the signed product v*0x55555555 (smmul) with
@ s = buf[ch*0x12d+i]; XY mode: draw_line(x0+buf[i]/3+0x12,
@ y0+0x60+D(buf[i+0x12d]-0x1c), next point, 0xf81f).
@ Then frees the buffer: byte 0x20001080 == 0 calls the callback word
@ 0x20001070(0), else clears the table entry of words 0x20001078/0x2000107c
@ with zero_bytes 080082bc (when (buf-0x20001078)>>10 < 0xaf).
@ Frame: four draw_lines around (x0,y0+0x1d)-(x0+0x66,y0+0x61), colour 0x55f
@ when k == byte 0x20000f15 % 6 else 0x8c73; text "%d.bmp" of the file id via
@ 080073b4 into 0x20008360 at draw_wrapped_text_in_box(x0, y0+0x5e, 0x66, 0x14,
@ font 0x20001144, same colour, 1); when byte 0x20000f12 != 0 an image at
@ (x0|1, y0+0x1e): "3:/System file/153.jpg" when bit k of byte
@ 0x20000f0a[page] is 0, "154.jpg" when it is 1.
@ Purpose: draws a page of up to six cells, each with a trace preview (x/3)
@ taken from the 0x25f-byte record, a four-line frame, the text "%d.bmp" of the
@ file id and optionally one of two images; the frame and text of the cell whose
@ index equals byte 0x20000f15 % 6 use colour 0x55f.
@ ----------------------------------------------------------------------------
	.section .text.draw_thumbnail_grid,"ax",%progbits
	.p2align 2
	.global draw_thumbnail_grid
	.thumb_func
	.type draw_thumbnail_grid, %function
draw_thumbnail_grid:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0x2c
	movw	r6, #0xf8
	movt	r6, #0x2000
	ldrb.w	r0, [r6, #0xe1d]
	movw	r1, #0xaaab
	movt	r1, #0xaaaa
	umull	r0, r1, r0, r1
	lsrs	r0, r1, #2
	add.w	r0, r0, r0, lsl #1
	lsls	r0, r0, #1
	mov.w	r8, #0x0
	str	r0, [sp, #0x14]
	b.n	.L0801ee24
	.byte	0x00, 0xbf	@ padding
.L0801ee18:
	add.w	r8, r8, #1
	cmp.w	r8, #6
	beq.w	.L0801f166
.L0801ee24:
	ldr	r0, [sp, #0x14]
	ldrb.w	r1, [r6, #0xe1b]
	add	r0, r8
	cmp	r0, r1
	bcs.w	.L0801f166
	add	r0, r6
	ldrb.w	r0, [r0, #0xe25]
	bl	read_numbered_bin_file
	ldr.w	r0, [r6, #0xe20]
	str.w	r8, [sp, #0x18]
	ldrh.w	r1, [r0, #0x25b]
	ldrh.w	r2, [r0, #0x25d]
	rev	r1, r1
	lsrs	r5, r1, #0x10
	ldrb.w	r1, [r0, #0x25a]
	rev	r2, r2
	cmp	r1, #2
	lsr.w	r2, r2, #0x10
	beq.n	.L0801ef0c
	movw	r6, #0xaaab
	cmp	r1, #3
	movt	r6, #0xaaaa
	beq.n	.L0801ef18
	cmp	r1, #4
	bne.n	.L0801ef1a
	adds	r1, r5, r2
	sub.w	r10, r1, #1
	cmp	r10, r5
	ble.w	.L0801eff0
	ldr	r3, [sp, #0x18]
	uxtb	r1, r3
	umull	r1, r2, r1, r6
	lsrs	r1, r2, #1
	add.w	r2, r1, r1, lsl #1
	subs	r2, r3, r2
	uxtb	r2, r2
	movs	r3, #0x68
	mul	r8, r2, r3
	movs	r2, #0x56
	muls	r1, r2, r1
	add.w	r9, r1, #0x60
	mov	r1, r5
.L0801ee9c:
	ldrb	r2, [r0, r1]
	add	r0, r1
	ldrb	r1, [r0, #1]
	umull	r2, r3, r2, r6
	umull	r1, r2, r1, r6
	add.w	r1, r8, r3, lsr #1
	add.w	r7, r1, #0x12
	ldrb.w	r1, [r0, #0x12d]
	mov.w	r4, #0x55555555
	subs	r1, #0x1c
	ldrb.w	r0, [r0, #0x12e]
	smmul	r3, r1, r4
	subs	r1, r3, r1
	lsrs	r3, r1, #1
	subs	r0, #0x1c
	add.w	r1, r3, r1, lsr #0x1f
	smmul	r3, r0, r4
	subs	r0, r3, r0
	lsrs	r3, r0, #1
	add.w	r2, r8, r2, lsr #1
	add.w	r0, r3, r0, lsr #0x1f
	add	r1, r9
	adds	r2, #0x12
	add	r0, r9
	sxth	r1, r1
	sxth	r3, r0
	sxth	r0, r7
	sxth	r2, r2
	movw	r7, #0xf81f
	str	r7, [sp]
	bl	draw_line
	adds	r5, #1
	uxth	r1, r5
	cmp	r10, r1
	ble.n	.L0801eff0
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldr.w	r0, [r0, #0xe20]
	b.n	.L0801ee9c
.L0801ef0c:
	movw	r6, #0xaaab
	movs	r1, #0x12
	movt	r6, #0xaaaa
	b.n	.L0801ef1a
.L0801ef18:
	movs	r1, #0x2
.L0801ef1a:
	and.w	r0, r1, #0xf
	cmp.w	r0, r1, lsr #4
	str	r0, [sp, #0x20]
	bls.n	.L0801eff0
	adds	r0, r5, r2
	subs	r4, r0, #1
	cmp	r4, r5
	ble.n	.L0801eff0
	ldr	r0, [sp, #0x18]
	lsrs	r1, r1, #4
	uxtb	r0, r0
	umull	r2, r3, r0, r6
	str	r1, [sp, #0x28]
	lsrs	r1, r3, #1
	movs	r2, #0x56
	muls	r2, r1, r2
	add.w	r1, r1, r1, lsl #1
	subs	r0, r0, r1
	movs	r1, #0x68
	add.w	r10, r2, #0x60
	mul	r9, r0, r1
	str	r5, [sp, #0x1c]
	nop
.L0801ef54:
	ldr	r1, [sp, #0x28]
	movw	r0, #0x12d
	muls	r0, r1, r0
	movw	r8, #0xf8
	str	r0, [sp, #0x24]
	mov	r0, r5
	mov	r7, r5
	movt	r8, #0x2000
	mov.w	r11, #0x55555555
	nop
.L0801ef70:
	uxth	r1, r7
	umull	r1, r2, r1, r6
	ldr	r6, [sp, #0x24]
	ldr.w	r3, [r8, #0xe20]
	add	r0, r6
	ldrb	r6, [r3, r0]
	add	r0, r3
	sub.w	r3, r6, #0x1c
	smmul	r6, r3, r11
	ldrb	r0, [r0, #1]
	subs	r3, r6, r3
	lsrs	r6, r3, #1
	subs	r0, #0x1c
	add.w	r3, r6, r3, lsr #0x1f
	smmul	r6, r0, r11
	subs	r0, r6, r0
	add.w	r1, r9, r2, lsr #1
	lsrs	r6, r0, #1
	adds	r2, r1, #1
	add.w	r0, r6, r0, lsr #0x1f
	ldrb.w	r6, [r8, #0xf63]
	adds	r5, r1, #2
	movw	r1, #:lower16:d_080bb40c
	movt	r1, #:upper16:d_080bb40c
	add.w	r1, r1, r6, lsl #2
	ldr	r6, [sp, #0x28]
	add	r3, r10
	ldrh.w	r6, [r1, r6, lsl #1]
	add	r0, r10
	sxth	r1, r3
	sxth	r3, r0
	sxth	r0, r2
	sxth	r2, r5
	str	r6, [sp]
	movw	r6, #0xaaab
	movt	r6, #0xaaaa
	bl	fn_0801fea8
	adds	r7, #1
	uxth	r0, r7
	cmp	r4, r0
	bgt.n	.L0801ef70
	ldr	r1, [sp, #0x28]
	ldr	r0, [sp, #0x20]
	adds	r1, #1
	ldr	r5, [sp, #0x1c]
	cmp	r1, r0
	str	r1, [sp, #0x28]
	bne.n	.L0801ef54
.L0801eff0:
	movw	r6, #0xf8
	movt	r6, #0x2000
	ldr.w	r0, [r6, #0xe20]
	ldr.w	r8, [sp, #0x18]
	cbz	r0, .L0801f03e
	movw	r2, #0x1070
	movt	r2, #0x2000
	ldrb	r1, [r2, #0x10]
	cbz	r1, .L0801f038
	ldr	r1, [r2, #8]
	subs	r0, r0, r1
	lsrs	r1, r0, #0xa
	cmp	r1, #0xae
	bhi.n	.L0801f03e
	movw	r1, #0x1070
	movt	r1, #0x2000
	ldr	r2, [r1, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cbz	r1, .L0801f03e
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	bl	zero_bytes
	b.n	.L0801f03e
	.byte	0x00, 0xbf	@ padding
.L0801f038:
	ldr	r1, [r2]
	movs	r0, #0x0
	blx	r1
.L0801f03e:
	ldrb.w	r0, [r6, #0xe1d]
	movw	r7, #0xaaab
	movt	r7, #0xaaaa
	umull	r1, r2, r0, r7
	umull	r1, r3, r8, r7
	lsrs	r1, r2, #2
	add.w	r1, r1, r1, lsl #1
	sub.w	r0, r0, r1, lsl #1
	lsrs	r1, r3, #1
	sub.w	r2, r1, r1, lsl #2
	add	r2, r8
	movs	r3, #0x68
	muls	r3, r2, r3
	movs	r2, #0x56
	mul	r9, r1, r2
	add.w	r1, r9, #0x1d
	add.w	r2, r3, #0x66
	movw	r10, #0x8c73
	sxth.w	r11, r1
	sxth	r7, r3
	sxth	r5, r2
	cmp	r8, r0
	it	eq
	movweq	r10, #0x55f
	str	r3, [sp, #0x28]
	mov	r0, r7
	mov	r1, r11
	mov	r2, r5
	mov	r3, r11
	str.w	r10, [sp]
	bl	draw_line
	add.w	r0, r9, #0x61
	sxth	r4, r0
	mov	r0, r7
	mov	r1, r4
	mov	r2, r5
	mov	r3, r4
	str.w	r10, [sp]
	bl	draw_line
	mov	r0, r7
	mov	r1, r11
	mov	r2, r7
	mov	r3, r4
	str.w	r10, [sp]
	bl	draw_line
	mov	r0, r5
	mov	r1, r11
	movw	r11, #0xaaab
	mov	r2, r5
	mov	r3, r4
	movt	r11, #0xaaaa
	str.w	r10, [sp]
	bl	draw_line
	ldrb.w	r0, [r6, #0xe1d]
	movw	r4, #0x8360
	umull	r0, r1, r0, r11
	lsrs	r0, r1, #2
	add.w	r0, r0, r0, lsl #1
	add.w	r0, r8, r0, lsl #1
	add	r0, r6
	ldrb.w	r2, [r0, #0xe25]
	movt	r4, #0x2000
	movw	r1, #:lower16:t_080bcae5
	mov	r0, r4
	movt	r1, #:upper16:t_080bcae5
	bl	format_to_buffer_080073b4
	movw	r1, #0x1144
	add.w	r0, r9, #0x5e
	movt	r1, #0x2000
	strd	r1, r10, [sp, #4]
	sxth	r1, r0
	mov	r0, r7
	movs	r2, #0x66
	movs	r3, #0x14
	movs	r5, #0x1
	str	r4, [sp]
	str	r5, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb.w	r0, [r6, #0xe1a]
	cmp	r0, #0
	beq.w	.L0801ee18
	ldrb.w	r0, [r6, #0xe1d]
	add.w	r2, r9, #0x1e
	umull	r0, r1, r0, r11
	add.w	r0, r6, r1, lsr #2
	ldrb.w	r0, [r0, #0xe12]
	ldr	r1, [sp, #0x28]
	lsr.w	r0, r0, r8
	orr.w	r1, r1, #1
	lsls	r0, r0, #0x1f
	adr	r0, .L0801f184
	uxth	r1, r1
	uxth	r2, r2
	adr	r3, .L0801f16c
	it	eq
	moveq	r0, r3
	bl	decode_image_file_with_offset
	b.n	.L0801ee18
.L0801f166:
	add	sp, #0x2c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0801f16c:
	.asciz	"3:/System file/153.jpg"
	.byte	0x00	@ padding
.L0801f184:
	.asciz	"3:/System file/154.jpg"
	.byte	0x00	@ padding

@ ----------------------------------------------------------------------------
@ draw_image_and_three_texts - no parameters, no return value.
@ Formats "3:/System file/%d.jpg" with (byte 0x20000f14 + 0x94) into 0x20008360
@ (format_to_buffer_080073b4) and draws it with decode_image_file_with_offset
@ at (0x3d, 0x32).
@ Three texts with draw_wrapped_text_in_box(0x3f, y, 0xc2, 0x14, word, font
@ block 0x20001144, colour, 1): y=0x30 "Delete" colour 0; y=0x5c "Confirm"
@ colour 0x55f when byte 0x20000f14 == 1 else 0xffff; y=0x83 "Cancel" colour
@ 0xffff when byte 0x20000f14 == 1 else 0x55f. (V1.2.0 took the three texts
@ from 8-word language tables after the code.)
@ Purpose: draws image (0x94 + byte 0x20000f14).jpg and the three dialog
@ texts; with byte 0x20000f14 == 1 the second text uses colour 0x55f and the
@ third 0xffff, otherwise the reverse; what they are for is not determined from
@ the code.
@ ----------------------------------------------------------------------------
	.section .text.draw_image_and_three_texts,"ax",%progbits
	.p2align 2
	.global draw_image_and_three_texts
	.thumb_func
	.type draw_image_and_three_texts, %function
draw_image_and_three_texts:
	push	{r4, r5, r6, r7, lr}
	sub	sp, #0x14
	movw	r5, #0xf8
	movt	r5, #0x2000
	ldrb.w	r0, [r5, #0xe1c]
	movw	r4, #0x8360
	movt	r4, #0x2000
	movw	r1, #:lower16:t_080bc681
	add.w	r2, r0, #0x94
	movt	r1, #:upper16:t_080bc681
	mov	r0, r4
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0x3d
	movs	r2, #0x32
	bl	decode_image_file_with_offset
	movw	r0, #:lower16:t_080bc25e	@ "Delete"
	movt	r0, #:upper16:t_080bc25e
	movw	r6, #0x1144
	movs	r1, #0x0
	movt	r6, #0x2000
	movs	r4, #0x1
	strd	r0, r6, [sp, #0x0]
	str	r1, [sp, #8]
	movs	r0, #0x3f
	movs	r1, #0x30
	movs	r2, #0xc2
	movs	r3, #0x14
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r0, #:lower16:t_080bc767	@ "Confirm"
	ldrb.w	r7, [r5, #0xe1c]
	movt	r0, #:upper16:t_080bc767
	movw	r1, #0xffff
	cmp	r7, #1
	it	eq
	movweq	r1, #0x55f
	strd	r0, r6, [sp, #0x0]
	str	r1, [sp, #8]
	movs	r0, #0x3f
	movs	r1, #0x5c
	movs	r2, #0xc2
	movs	r3, #0x14
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r5, #:lower16:t_080bc70e	@ "Cancel"
	movt	r5, #:upper16:t_080bc70e
	movw	r0, #0x55f
	cmp	r7, #1
	it	eq
	movweq	r0, #0xffff
	strd	r6, r0, [sp, #4]
	movs	r0, #0x3f
	movs	r1, #0x83
	movs	r2, #0xc2
	movs	r3, #0x14
	str	r4, [sp, #0xc]
	str	r5, [sp]
	bl	draw_wrapped_text_in_box
	add	sp, #0x14
	pop	{r4, r5, r6, r7, pc}

@ ----------------------------------------------------------------------------
@ draw_bitmap_and_text - no parameters, no return value.
@ Calls draw_4bpp_bitmap 0801ffcc(0x3d, 0x50, 0xc6, 0x53, bitmap 0x0804fd00,
@ colour 0x55f), then draw_wrapped_text_in_box(0x3f, 0x6d, 0xc2, 0x14,
@ "Deleting...", font block 0x20001144, colour 0x55f, flag 1).
@ Purpose: draws the 4bpp message box bitmap 0x0804fd00 and "Deleting..." over it.
@ ----------------------------------------------------------------------------
	.section .text.draw_bitmap_and_text,"ax",%progbits
	.p2align 2
	.global draw_bitmap_and_text
	.thumb_func
	.type draw_bitmap_and_text, %function
draw_bitmap_and_text:
	push	{r4, lr}
	sub	sp, #0x10
	movw	r0, #:lower16:d_0804fd00
	movt	r0, #:upper16:d_0804fd00
	movw	r4, #0x55f
	str	r0, [sp]
	movs	r0, #0x3d
	movs	r1, #0x50
	movs	r2, #0xc6
	movs	r3, #0x53
	str	r4, [sp, #4]
	bl	draw_4bpp_bitmap
	movw	r0, #:lower16:t_080bb682	@ "Deleting..."
	movt	r0, #:upper16:t_080bb682
	movw	r1, #0x1144
	movt	r1, #0x2000
	mov.w	r12, #0x1
	stm.w	sp, {r0, r1, r4}
	movs	r0, #0x3f
	movs	r1, #0x6d
	movs	r2, #0xc2
	movs	r3, #0x14
	str.w	r12, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add	sp, #0x10
	pop	{r4, pc}

