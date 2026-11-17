@ ui_pages_77.s - draw_page_by_selector_nibble, part 1 of 2 (part 2 is included at the end of this file)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ draw_page_by_selector_nibble - no parameters, no return value. Switch on
@ (byte 0x20001062 & 0xf); values 7..15 return immediately.
@ Common items: sel = byte 0x20001063, edit = byte 0x20001061, lang = byte
@ 0x20001058. A row is highlighted when edit != 0 and sel == row. An unselected
@ row is a solid fill of colour 0x18c3 over x 0x7a..0x12f (pixel pairs, clipped
@ to the halfwords 0x20008350/52/54/56, buffer word 0x20008358); a highlighted
@ row has no fill. With top = first fill row of the row: radio image 74.jpg (on)
@ or 77.jpg (off) at (0xa6, top+9) in a normal row; a highlighted row draws
@ 72.jpg at (0x79, top-1) and radio 75.jpg (on, x 0xa6) or 78.jpg (off, x 0xa5)
@ at y top+7. Label colour = halfword at 0x0804c180 + idx*2 (idx 1 normal =
@ 0xffff, idx 2 highlighted = 0x055f).
@ Case 0: row y=0x3e (fill y 0x3e..0x5d, highlighted when sel==0) with radio on
@   when lang==1 and label word 0x080bd09b ("中文") at (0xb6,0x3d,0x5c,0x22);
@   row y=0x86 (fill 0x86..0xa5, sel==1) radio on when lang==2, label "English"
@   at (0xb6,0x85,0x5c,0x22).
@ Case 1: 136.jpg at (0x9d,0x54), 137.jpg at (0x7c,0x4f) (or 139.jpg at
@   (0x7a,0x4d) when edit!=0 and sel==0), then 08020ce8(0x9d,0x54,
@   int(byte 0x2000105a*15.5),0xf,0x861,colour); 136.jpg at (0x9d,0x9c),
@   138.jpg at (0x7c,0x95) (or 140.jpg at (0x7b,0x94) when sel==1),
@   08020ce8(0x9d,0x9c,int((byte 0x20001059-0x19)*3.12),0xf,0x861,colour)
@   (080455da, 0804550a, 0804577c, 08045450).
@ Case 2: four rows i=0..3 (fill y 0x3e+0x24*i, 32 rows) with radio on when
@   byte 0x2000105c==i; the radio images 74/77/75/78 (not 72.jpg and not the
@   label) are shifted left by 0x18 in x when lang!=1; label 0800f154(0xa2,
@   i*0x24+0x3d,0x82,0x22, word at (word 0x0804c208+i*4)+lang*4-4 (arrays
@   0x0804c338,0x0804c358,0x0804c378,0x0804c398), font 0x20001114, colour, 1).
@ Case 3: four rows "OFF" (y 0x3d), "15min" (0x61), "30min" (0x85), "1hour"
@   (0xa9) with fills at 0x3e, 0x62, 0x86, 0xaa and radio on when byte
@   0x2000105d==0,1,2,3, highlighted when sel==0..3, labels at
@   (0xb6,y,0x5c,0x22,flag 1).
@ Case 4: one row, fill y 0x70..0x8f when edit==0 with 77.jpg at (0xa6,0x79),
@   else 72.jpg (0x79,0x6f) and 78.jpg (0xa5,0x77); label "ON" at
@   (0xb6,0x6f,0x5c,0x22).
@ Case 5: 141.jpg at (0x72,0x30); texts word at 0x0804c210+lang*8 at
@   (0x82,0xa0,0x5a,0x14) and word at 0x0804c214+lang*8 at (0x82,0xc4,0x5a,0x14)
@   (colour 0xffff, flag 0); "V%s" of "1.2.0" at (0xdc,0xa0,0x5a,0x14); writes
@   "APP_2C53T" plus zero into 0x20008360..0x20008369 (word 0x5f505041, word
@   0x33354332, halfword 0x54) and draws the text from 0x20008364 ("2C53T") at
@   (0xdc,0xc4,0x5a,0x14).
@ Case 6: 142.jpg at (0x70,0x30), text from a pointer table in the code (entry
@   lang-1, base 0x0801e13c) at (0xd2,0x35,0x5a,0x14), text word
@   0x0801e158+lang*4 at (0x75,0x4c,0xbe,0x50,flag 0x81); two button rows: fill
@   (x 0x72..0x135, y 0x9c..0xb9, and y 0xc0..0xdd) when not highlighted
@   (sel!=0 / sel!=1 or edit==0), otherwise 143.jpg at (0x70,0x9a) / (0x70,0xbe);
@   labels word 0x0804c254+lang*28 at (0x78,0x9a,0xb8,0x22) and word at
@   0x0801e41c+lang*4 at (0x78,0xbe,0xb8,0x22).
@ Purpose: draws one of seven pages selected by the low nibble of byte
@ 0x20001062 (cases 0..6 as listed: two text rows, two bars, four rows, four
@ rows labelled OFF/15min/30min/1hour, one row labelled ON, a page with a
@ version string text, a page with two button rows); what the pages are for is
@ not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.draw_page_by_selector_nibble,"ax",%progbits
	.p2align 2
	.global draw_page_by_selector_nibble
	.thumb_func
	.type draw_page_by_selector_nibble, %function
draw_page_by_selector_nibble:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0x2c
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0xf6a]	@ byte 0x20001062
	and	r0, r0, #0xf
	cmp	r0, #6
	bhi.w	.L0801d28c
	tbh	[pc, r0, lsl #1]
.L0801cf70:
	.short	(.L0801cf7e - .L0801cf70)/2
	.short	(.L0801cfc2 - .L0801cf70)/2
	.short	(.L0801d002 - .L0801cf70)/2
	.short	(.L0801d292 - .L0801cf70)/2
	.short	(.L0801d2d0 - .L0801cf70)/2
	.short	(.L0801d300 - .L0801cf70)/2
	.short	(.L0801d3ca - .L0801cf70)/2
.L0801cf7e:
	ldrb.w	r0, [r3, #0xf69]
	cmp	r0, #0
	beq.w	.L0801d480
	ldrb.w	r0, [r3, #0xf6b]
	cmp	r0, #0
	bne.w	.L0801d480
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x3d
	bl	decode_image_file_with_offset
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf60]
	cmp	r0, #1
	bne.w	.L0801dc1c
	movw	r0, #:lower16:d_080bc54a
	movt	r0, #:upper16:d_080bc54a
	movs	r1, #0xa6
	b.w	.L0801dc26
.L0801cfc2:
	movw	r0, #:lower16:d_080bc58a+1
	movt	r0, #:upper16:d_080bc58a+1
	movs	r1, #0x9d
	movs	r2, #0x54
	bl	decode_image_file_with_offset
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldrb.w	r0, [r1, #0xf69]
	cmp	r0, #0
	beq.w	.L0801d5a6
	ldrb.w	r0, [r1, #0xf6b]
	cmp	r0, #0
	bne.w	.L0801d5a6
	movw	r0, #:lower16:d_080bc628
	movt	r0, #:upper16:d_080bc628
	movs	r1, #0x7a
	movs	r2, #0x4d
	bl	decode_image_file_with_offset
	movs	r5, #2
	b.n	.L0801d5b8
.L0801d002:
	ldrb.w	r0, [r3, #0xf60]
	movw	r4, #0x8350
	subs	r0, #1
	it	ne
	movne	r0, #0x18
	rsb.w	r1, r0, #0xa6
	str	r1, [sp, #0x18]
	rsb.w	r1, r0, #0xa5
	movs	r0, #0
	movs	r2, #0x3e
	mov.w	r9, #0x5e
	mov.w	r8, #0x3f
	uxth	r1, r1
	movt	r4, #0x2000
	movw	r11, #0x131
	movw	r10, #0x18c3
	movs	r6, #0
	str	r2, [sp, #0x28]
	str	r1, [sp, #0x14]
	b.n	.L0801d05e
.L0801d03c:
	ldr	r2, [sp, #0x28]
	uxtb	r1, r6
	adds	r6, #1
	movw	r3, #0xf8
	uxtb	r0, r6
	adds	r2, #0x24
	add.w	r9, r9, #0x24
	cmp	r1, #3
	add.w	r8, r8, #0x24
	movt	r3, #0x2000
	str	r2, [sp, #0x28]
	bcs.w	.L0801d28c
.L0801d05e:
	ldrb.w	r1, [r3, #0xf69]
	str	r6, [sp, #0x24]
	cbz	r1, .L0801d0b0
	ldrb.w	r1, [r3, #0xf6b]
	uxtb	r7, r6
	cmp	r1, r7
	bne.n	.L0801d0b0
	mov	r6, r8
	add.w	r8, r0, r0, lsl #3
	movs	r0, #0x3d
	add.w	r0, r0, r8, lsl #2
	uxth	r2, r0
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	mov	r5, r3
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r5, #0xf64]
	cmp	r0, r7
	mov.w	r0, #0x45
	add.w	r0, r0, r8, lsl #2
	bne.w	.L0801d210
	ldr	r1, [sp, #0x18]
	uxth	r2, r0
	movw	r0, #:lower16:d_080bc54a
	uxth	r1, r1
	movt	r0, #:upper16:d_080bc54a
	b.n	.L0801d21c
.L0801d0b0:
	uxtb.w	lr, r6
	lsl.w	r0, lr, #3
	uxtab	r0, r0, r6
	ldr	r3, [sp, #0x28]
	lsls	r0, r0, #2
	strd	r0, r8, [sp, #0x1c]
	b.n	.L0801d0d4
	.short	0xbf00	@ padding
.L0801d0c8:
	adds	r3, #2
	cmp	r3, r9
	add.w	r8, r8, #2
	beq.w	.L0801d1d8
.L0801d0d4:
	movs	r7, #0x7b
	b.n	.L0801d0de
.L0801d0d8:
	adds	r7, #2
	cmp	r7, r11
	beq.n	.L0801d150
.L0801d0de:
	ldrh	r0, [r4, #0]
	subs	r1, r7, #1
	cmp	r1, r0
	bcc.n	.L0801d118
	ldrh	r0, [r4, #0]
	ldrh	r5, [r4, #4]
	add	r0, r5
	cmp	r0, r1
	bls.n	.L0801d118
	ldrh	r0, [r4, #2]
	cmp	r3, r0
	bcc.n	.L0801d118
	ldrh	r0, [r4, #2]
	ldrh	r1, [r4, #6]
	add	r0, r1
	cmp	r0, r3
	bls.n	.L0801d118
	ldr	r0, [r4, #8]
	ldrh	r1, [r4, #0]
	ldrh	r5, [r4, #2]
	ldrh	r2, [r4, #4]
	subs	r5, r3, r5
	muls	r2, r5, r2
	subs	r1, r2, r1
	add	r1, r7
	add.w	r0, r0, r1, lsl #1
	strh	r10, [r0, #-2]
.L0801d118:
	ldrh	r0, [r4, #0]
	cmp	r7, r0
	bcc.n	.L0801d0d8
	ldrh	r0, [r4, #0]
	ldrh	r1, [r4, #4]
	add	r0, r1
	cmp	r0, r7
	bls.n	.L0801d0d8
	ldrh	r0, [r4, #2]
	cmp	r3, r0
	bcc.n	.L0801d0d8
	ldrh	r0, [r4, #2]
	ldrh	r1, [r4, #6]
	add	r0, r1
	cmp	r0, r3
	bls.n	.L0801d0d8
	ldr	r0, [r4, #8]
	ldrh	r1, [r4, #0]
	ldrh	r2, [r4, #2]
	ldrh	r5, [r4, #4]
	subs	r2, r3, r2
	muls	r2, r5, r2
	subs	r1, r2, r1
	add	r1, r7
	strh.w	r10, [r0, r1, lsl #1]
	b.n	.L0801d0d8
	.short	0xbf00	@ padding
.L0801d150:
	orr	r7, r3, #1
	movs	r1, #0x7b
	b.n	.L0801d15e
.L0801d158:
	adds	r1, #2
	cmp	r1, r11
	beq.n	.L0801d0c8
.L0801d15e:
	ldrh	r2, [r4, #0]
	subs	r0, r1, #1
	cmp	r0, r2
	bcc.n	.L0801d1a0
	ldrh	r2, [r4, #0]
	ldrh	r5, [r4, #4]
	add	r2, r5
	cmp	r2, r0
	bls.n	.L0801d1a0
	ldrh	r0, [r4, #2]
	cmp	r7, r0
	bcc.n	.L0801d1a0
	ldrh	r0, [r4, #2]
	ldrh	r2, [r4, #6]
	add	r0, r2
	cmp	r0, r7
	bls.n	.L0801d1a0
	ldr	r0, [r4, #8]
	ldrh	r2, [r4, #0]
	ldrh	r5, [r4, #2]
	ldrh.w	r12, [r4, #4]
	sub.w	r5, r8, r5
	mul	r5, r5, r12
	subs	r2, r5, r2
	add	r2, r1
	add.w	r0, r0, r2, lsl #1
	strh	r10, [r0, #-2]
	nop
.L0801d1a0:
	ldrh	r0, [r4, #0]
	cmp	r1, r0
	bcc.n	.L0801d158
	ldrh	r0, [r4, #0]
	ldrh	r2, [r4, #4]
	add	r0, r2
	cmp	r0, r1
	bls.n	.L0801d158
	ldrh	r0, [r4, #2]
	cmp	r7, r0
	bcc.n	.L0801d158
	ldrh	r0, [r4, #2]
	ldrh	r2, [r4, #6]
	add	r0, r2
	cmp	r0, r7
	bls.n	.L0801d158
	ldr	r0, [r4, #8]
	ldrh	r2, [r4, #0]
	ldrh	r5, [r4, #2]
	ldrh	r6, [r4, #4]
	sub.w	r5, r8, r5
	muls	r6, r5, r6
	subs	r2, r6, r2
	add	r2, r1
	strh.w	r10, [r0, r2, lsl #1]
	b.n	.L0801d158
.L0801d1d8:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf64]
	cmp	r0, lr
	ldr	r0, [sp, #0x1c]
	add.w	r2, r0, #0x47
	ldr	r0, [sp, #0x18]
	uxth	r1, r0
	ittee	ne
	movwne	r0, #:lower16:d_080bc5ce+1
	movtne	r0, #:upper16:d_080bc5ce+1
	movweq	r0, #:lower16:d_080bc4f2
	movteq	r0, #:upper16:d_080bc4f2
	bl	decode_image_file_with_offset
	ldr.w	r8, [sp, #0x20]
	movs	r0, #1
	b.n	.L0801d224
	.short	0xbf00	@ padding
.L0801d210:
	uxth	r2, r0
	movw	r0, #:lower16:d_080bc5fc
	ldr	r1, [sp, #0x14]
	movt	r0, #:upper16:d_080bc5fc
.L0801d21c:
	bl	decode_image_file_with_offset
	movs	r0, #2
	mov	r8, r6
.L0801d224:
	ldr	r6, [sp, #0x24]
	and	r1, r6, #0x7f
	cmp	r1, #3
	bhi.w	.L0801d03c
	movw	r2, #:lower16:d_0804c208
	movw	r3, #0xf8
	sbfx	r1, r6, #0, #7
	movt	r2, #:upper16:d_0804c208
	movt	r3, #0x2000
	ldr.w	r1, [r2, r1, lsl #2]
	ldrb.w	r3, [r3, #0xf60]
	uxtb	r2, r6
	add.w	r1, r1, r3, lsl #2
	ldr.w	r3, [r1, #-4]
	movw	r1, #:lower16:d_0804c180
	lsls	r2, r2, #3
	movt	r1, #:upper16:d_0804c180
	uxtab	r2, r2, r6
	ldrh.w	r0, [r1, r0, lsl #1]
	movs	r1, #0x3d
	add.w	r1, r1, r2, lsl #2
	movw	r2, #0x1114
	movt	r2, #0x2000
	str	r3, [sp, #0]
	strd	r2, r0, [sp, #4]
	movs	r0, #0xa2
	movs	r2, #0x82
	movs	r3, #0x22
	movs	r7, #1
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	b.n	.L0801d03c
.L0801d28c:
	add	sp, #0x2c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0801d292:
	ldrb.w	r0, [r3, #0xf69]
	cmp	r0, #0
	beq.w	.L0801d630
	ldrb.w	r0, [r3, #0xf6b]
	cmp	r0, #0
	bne.w	.L0801d630
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x3d
	mov	r4, r3
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r4, #0xf65]
	cmp	r0, #0
	beq.w	.L0801de1e
	movw	r0, #:lower16:d_080bc5fc
	movt	r0, #:upper16:d_080bc5fc
	movs	r1, #0xa5
	b.w	.L0801de28
.L0801d2d0:
	ldrb.w	r0, [r3, #0xf69]
	cmp	r0, #0
	beq.w	.L0801dab6
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x6f
	bl	decode_image_file_with_offset
	movw	r0, #:lower16:d_080bc5fc
	movt	r0, #:upper16:d_080bc5fc
	movs	r1, #0xa5
	movs	r2, #0x77
	bl	decode_image_file_with_offset
	movs	r0, #2
	b.w	.L0801dbf0
.L0801d300:
	movw	r0, #:lower16:d_080bc43e+1
	movt	r0, #:upper16:d_080bc43e+1
	movs	r1, #0x72
	movs	r2, #0x30
	mov	r5, r3
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r5, #0xf60]
	movw	r4, #:lower16:d_0804c218
	movt	r4, #:upper16:d_0804c218
	add.w	r0, r4, r0, lsl #3
	ldr.w	r0, [r0, #-8]
	movw	r7, #0x1114
	movt	r7, #0x2000
	mov.w	r8, #0
	movw	r6, #0xffff
	strd	r0, r7, [sp, #0]
	movs	r0, #0x82
	movs	r1, #0xa0
	movs	r2, #0x5a
	movs	r3, #0x14
	str	r6, [sp, #8]
	str.w	r8, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb.w	r0, [r5, #0xf60]
	movs	r1, #0xc4
	add.w	r0, r4, r0, lsl #3
	ldr.w	r0, [r0, #-4]
	movs	r2, #0x5a
	strd	r0, r7, [sp, #0]
	movs	r0, #0x82
	movs	r3, #0x14
	str	r6, [sp, #8]
	str.w	r8, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r4, #0x8360
	movt	r4, #0x2000
	adr.w	r1, .L0801e118
	adr.w	r2, .L0801e11c
	mov	r0, r4
	bl	format_to_buffer_080073b4
	movs	r0, #0xdc
	movs	r1, #0xa0
	movs	r2, #0x5a
	movs	r3, #0x14
	strd	r4, r7, [sp, #0]
	str	r6, [sp, #8]
	str.w	r8, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movs	r0, #0x54
	strh	r0, [r4, #8]
	movw	r0, #0x5041
	movt	r0, #0x5f50
	str	r0, [r4, #0]
	movw	r0, #0x4332
	movt	r0, #0x3335
	str.w	r0, [r4, #4]!
	strd	r4, r7, [sp, #0]
	str	r6, [sp, #8]
	movs	r0, #0xdc
	movs	r1, #0xc4
	movs	r2, #0x5a
	movs	r3, #0x14
	str.w	r8, [sp, #0xc]
	b.w	.L0801e414
.L0801d3ca:
	adr.w	r0, .L0801e124
	movs	r1, #0x70
	movs	r2, #0x30
	bl	decode_image_file_with_offset
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf60]
	adr.w	r1, .L0801e13c
	add.w	r0, r1, r0, lsl #2
	ldr.w	r0, [r0, #-4]
	movw	r8, #0x1114
	movs	r1, #0
	movt	r8, #0x2000
	movw	r5, #0xffff
	strd	r0, r8, [sp, #0]
	str	r1, [sp, #0xc]
	movs	r0, #0xd2
	movs	r1, #0x35
	movs	r2, #0x5a
	movs	r3, #0x14
	str	r5, [sp, #8]
	bl	draw_wrapped_text_in_box
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf60]
	adr.w	r1, .L0801e15c
	add.w	r0, r1, r0, lsl #2
	ldr.w	r0, [r0, #-4]
	movs	r1, #0x81
	str	r0, [sp, #0]
	strd	r5, r1, [sp, #8]
	movs	r0, #0x75
	movs	r1, #0x4c
	movs	r2, #0xbe
	movs	r3, #0x50
	str.w	r8, [sp, #4]
	bl	draw_wrapped_text_in_box
	movw	lr, #0xf8
	movt	lr, #0x2000
	ldrb.w	r0, [lr, #0xf69]
	movw	r6, #0x8350
	cmp	r0, #0
	movt	r6, #0x2000
	beq.w	.L0801d766
	ldrb.w	r0, [lr, #0xf6b]
	cmp	r0, #0
	bne.w	.L0801d766
	movw	r0, #:lower16:d_080bc4c4+1
	movt	r0, #:upper16:d_080bc4c4+1
	movs	r1, #0x70
	movs	r2, #0x9a
	bl	decode_image_file_with_offset
	movw	lr, #0xf8
	movt	lr, #0x2000
	movs	r0, #2
	b.n	.L0801d91a
.L0801d480:
	movw	r2, #0x8350
	movs	r0, #0x3e
	mov.w	lr, #0x3f
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L0801d4a4
.L0801d498:
	adds	r0, #2
	cmp	r0, #0x5e
	add.w	lr, lr, #2
	beq.w	.L0801d86e
.L0801d4a4:
	movs	r6, #0x7b
	b.n	.L0801d4ae
.L0801d4a8:
	adds	r6, #2
	cmp	r6, r3
	beq.n	.L0801d520
.L0801d4ae:
	ldrh	r4, [r2, #0]
	subs	r5, r6, #1
	cmp	r5, r4
	bcc.n	.L0801d4e8
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r4
	cmp	r7, r5
	bls.n	.L0801d4e8
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	bcc.n	.L0801d4e8
	ldrh	r7, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L0801d4e8
	ldr	r7, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r6
	add.w	r1, r7, r1, lsl #1
	strh	r12, [r1, #-2]
.L0801d4e8:
	ldrh	r1, [r2, #0]
	cmp	r6, r1
	bcc.n	.L0801d4a8
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801d4a8
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L0801d4a8
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L0801d4a8
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r5, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r5, r0, r5
	muls	r5, r7, r5
	subs	r4, r5, r4
	add	r4, r6
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L0801d4a8
	.short	0xbf00	@ padding
.L0801d520:
	orr	r6, r0, #1
	movs	r5, #0x7b
	b.n	.L0801d52e
.L0801d528:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L0801d498
.L0801d52e:
	ldrh	r1, [r2, #0]
	subs	r4, r5, #1
	cmp	r4, r1
	bcc.n	.L0801d56c
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r4
	bls.n	.L0801d56c
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L0801d56c
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801d56c
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	add.w	r1, r8, r1, lsl #1
	strh	r12, [r1, #-2]
.L0801d56c:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	bcc.n	.L0801d528
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L0801d528
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L0801d528
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801d528
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	strh.w	r12, [r8, r1, lsl #1]
	b.n	.L0801d528
.L0801d5a6:
	movw	r0, #:lower16:d_080bc5b8
	movt	r0, #:upper16:d_080bc5b8
	movs	r1, #0x7c
	movs	r2, #0x4f
	bl	decode_image_file_with_offset
	movs	r5, #1
.L0801d5b8:
	movw	r6, #0xf8
	movt	r6, #0x2000
	ldrb.w	r0, [r6, #0xf62]
	bl	u32_to_double
	vldr	d0, .L0801d658
	vmov	r2, r3, d0
	bl	double_mul
	bl	double_to_i32
	movw	r4, #:lower16:d_0804c180
	movt	r4, #:upper16:d_0804c180
	ldrh.w	r7, [r4, r5, lsl #1]
	mov	r2, r0
	movw	r0, #0x861
	str	r0, [sp, #0]
	movs	r0, #0x9d
	movs	r1, #0x54
	movs	r3, #0xf
	str	r7, [sp, #4]
	bl	recolor_rect_above_threshold
	movw	r0, #:lower16:d_080bc58a+1
	movt	r0, #:upper16:d_080bc58a+1
	movs	r1, #0x9d
	movs	r2, #0x9c
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r6, #0xf69]
	cmp	r0, #0
	beq.w	.L0801d89a
	ldrb.w	r0, [r6, #0xf6b]
	cmp	r0, #1
	bne.w	.L0801d89a
	movw	r0, #:lower16:d_080bc412
	movt	r0, #:upper16:d_080bc412
	movs	r1, #0x7b
	movs	r2, #0x94
	bl	decode_image_file_with_offset
	movs	r5, #2
	b.n	.L0801d8ac
.L0801d630:
	movw	r2, #0x8350
	movs	r0, #0x3e
	mov.w	lr, #0x3f
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L0801d654
.L0801d648:
	adds	r0, #2
	cmp	r0, #0x5e
	add.w	lr, lr, #2
	beq.w	.L0801d8ec
.L0801d654:
	movs	r6, #0x7b
	b.n	.L0801d66e
.L0801d658:
	.word	0x00000000, 0x402f0000	@ 8-byte literal at 0801d658 (double 15.5)
.L0801d660:
	.word	0x28f5c28f, 0x40008f5c	@ 8-byte literal at 0801d660 (bytes as in the image)
.L0801d668:
	adds	r6, #2
	cmp	r6, r3
	beq.n	.L0801d6e0
.L0801d66e:
	ldrh	r4, [r2, #0]
	subs	r5, r6, #1
	cmp	r5, r4
	bcc.n	.L0801d6a8
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r4
	cmp	r7, r5
	bls.n	.L0801d6a8
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	bcc.n	.L0801d6a8
	ldrh	r7, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L0801d6a8
	ldr	r7, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r6
	add.w	r1, r7, r1, lsl #1
	strh	r12, [r1, #-2]
.L0801d6a8:
	ldrh	r1, [r2, #0]
	cmp	r6, r1
	bcc.n	.L0801d668
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801d668
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L0801d668
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L0801d668
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r5, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r5, r0, r5
	muls	r5, r7, r5
	subs	r4, r5, r4
	add	r4, r6
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L0801d668
	.short	0xbf00	@ padding
.L0801d6e0:
	orr	r6, r0, #1
	movs	r5, #0x7b
	b.n	.L0801d6ee
.L0801d6e8:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L0801d648
.L0801d6ee:
	ldrh	r1, [r2, #0]
	subs	r4, r5, #1
	cmp	r4, r1
	bcc.n	.L0801d72c
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r4
	bls.n	.L0801d72c
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L0801d72c
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801d72c
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	add.w	r1, r8, r1, lsl #1
	strh	r12, [r1, #-2]
.L0801d72c:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	bcc.n	.L0801d6e8
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L0801d6e8
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L0801d6e8
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801d6e8
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	strh.w	r12, [r8, r1, lsl #1]
	b.n	.L0801d6e8
.L0801d766:
	movs	r0, #0x9c
	movw	r1, #0x139
	movw	r12, #0x18c3
	b.n	.L0801d77c
	.short	0xbf00	@ padding
.L0801d774:
	adds	r0, #1
	cmp	r0, #0xba
	beq.w	.L0801d918
.L0801d77c:
	movs	r3, #0x75
	b.n	.L0801d786
.L0801d780:
	adds	r3, #4
	cmp	r3, r1
	beq.n	.L0801d774
.L0801d786:
	ldrh	r5, [r6, #0]
	subs	r7, r3, #3
	cmp	r7, r5
	bcc.n	.L0801d7c0
	ldrh	r5, [r6, #0]
	ldrh	r4, [r6, #4]
	add	r5, r4
	cmp	r5, r7
	bls.n	.L0801d7c0
	ldrh	r7, [r6, #2]
	cmp	r0, r7
	bcc.n	.L0801d7c0
	ldrh	r7, [r6, #2]
	ldrh	r5, [r6, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L0801d7c0
	ldr	r7, [r6, #8]
	ldrh	r5, [r6, #0]
	ldrh	r4, [r6, #2]
	ldrh	r2, [r6, #4]
	subs	r4, r0, r4
	muls	r2, r4, r2
	subs	r2, r2, r5
	add	r2, r3
	add.w	r2, r7, r2, lsl #1
	strh	r12, [r2, #-6]
.L0801d7c0:
	ldrh	r2, [r6, #0]
	subs	r7, r3, #2
	cmp	r7, r2
	bcc.n	.L0801d7fc
	ldrh	r2, [r6, #0]
	ldrh	r5, [r6, #4]
	add	r2, r5
	cmp	r2, r7
	bls.n	.L0801d7fc
	ldrh	r2, [r6, #2]
	cmp	r0, r2
	bcc.n	.L0801d7fc
	ldrh	r2, [r6, #2]
	ldrh	r7, [r6, #6]
	add	r2, r7
	cmp	r2, r0
	bls.n	.L0801d7fc
	ldr	r2, [r6, #8]
	ldrh	r7, [r6, #0]
	ldrh	r5, [r6, #2]
	ldrh	r4, [r6, #4]
	subs	r5, r0, r5
	muls	r5, r4, r5
	subs	r7, r5, r7
	add	r7, r3
	add.w	r2, r2, r7, lsl #1
	strh	r12, [r2, #-4]
	nop
.L0801d7fc:
	ldrh	r2, [r6, #0]
	subs	r7, r3, #1
	cmp	r7, r2
	bcc.n	.L0801d838
	ldrh	r2, [r6, #0]
	ldrh	r5, [r6, #4]
	add	r2, r5
	cmp	r2, r7
	bls.n	.L0801d838
	ldrh	r2, [r6, #2]
	cmp	r0, r2
	bcc.n	.L0801d838
	ldrh	r2, [r6, #2]
	ldrh	r7, [r6, #6]
	add	r2, r7
	cmp	r2, r0
	bls.n	.L0801d838
	ldr	r2, [r6, #8]
	ldrh	r7, [r6, #0]
	ldrh	r5, [r6, #2]
	ldrh	r4, [r6, #4]
	subs	r5, r0, r5
	muls	r5, r4, r5
	subs	r7, r5, r7
	add	r7, r3
	add.w	r2, r2, r7, lsl #1
	strh	r12, [r2, #-2]
	nop
.L0801d838:
	ldrh	r2, [r6, #0]
	cmp	r3, r2
	bcc.n	.L0801d780
	ldrh	r2, [r6, #0]
	ldrh	r7, [r6, #4]
	add	r2, r7
	cmp	r2, r3
	bls.n	.L0801d780
	ldrh	r2, [r6, #2]
	cmp	r0, r2
	bcc.n	.L0801d780
	ldrh	r2, [r6, #2]
	ldrh	r7, [r6, #6]
	add	r2, r7
	cmp	r2, r0
	bls.n	.L0801d780
	ldr	r2, [r6, #8]
	ldrh	r7, [r6, #0]
	ldrh	r5, [r6, #2]
	ldrh	r4, [r6, #4]
	subs	r5, r0, r5
	muls	r5, r4, r5
	subs	r7, r5, r7
	add	r7, r3
	strh.w	r12, [r2, r7, lsl #1]
	b.n	.L0801d780
.L0801d86e:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf60]
	movs	r1, #0xa6
	movs	r2, #0x47
	cmp	r0, #1
	ittee	ne
	movwne	r0, #:lower16:d_080bc5ce+1
	movtne	r0, #:upper16:d_080bc5ce+1
	movweq	r0, #:lower16:d_080bc4f2
	movteq	r0, #:upper16:d_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.n	.L0801dc2e
.L0801d89a:
	movw	r0, #:lower16:d_080bc5e4+1
	movt	r0, #:upper16:d_080bc5e4+1
	movs	r1, #0x7c
	movs	r2, #0x95
	bl	decode_image_file_with_offset
	movs	r5, #1
.L0801d8ac:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf61]
	subs	r0, #0x19
	bl	i32_to_double
	vldr	d0, .L0801d660
	vmov	r2, r3, d0
	bl	double_mul
	bl	double_to_i32
	ldrh.w	r7, [r4, r5, lsl #1]
	mov	r2, r0
	movw	r0, #0x861
	str	r0, [sp, #0]
	movs	r0, #0x9d
	movs	r1, #0x9c
	movs	r3, #0xf
	str	r7, [sp, #4]
	bl	recolor_rect_above_threshold
	add	sp, #0x2c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0801d8ec:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf65]
	movs	r1, #0xa6
	movs	r2, #0x47
	cmp	r0, #0
	ittee	ne
	movwne	r0, #:lower16:d_080bc5ce+1
	movtne	r0, #:upper16:d_080bc5ce+1
	movweq	r0, #:lower16:d_080bc4f2
	movteq	r0, #:upper16:d_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.n	.L0801de30
.L0801d918:
	movs	r0, #1
.L0801d91a:
	ldrb.w	r1, [lr, #0xf60]
	movw	r2, #:lower16:d_0804c258
	rsb	r1, r1, r1, lsl #3
	movt	r2, #:upper16:d_0804c258
	movw	r9, #:lower16:d_0804c180
	add.w	r1, r2, r1, lsl #2
	movt	r9, #:upper16:d_0804c180
	ldr.w	r1, [r1, #-4]
	ldrh.w	r0, [r9, r0, lsl #1]
	movs	r2, #1
	str	r1, [sp, #0]
	strd	r0, r2, [sp, #8]
	movs	r0, #0x78
	movs	r1, #0x9a
	movs	r2, #0xb8
	movs	r3, #0x22
	str.w	r8, [sp, #4]
	bl	draw_wrapped_text_in_box
	movw	lr, #0xf8
	movt	lr, #0x2000
	ldrb.w	r0, [lr, #0xf69]
	cbz	r0, .L0801d988
	ldrb.w	r0, [lr, #0xf6b]
	cmp	r0, #1
	bne.n	.L0801d988
	movw	r0, #:lower16:d_080bc4c4+1
	movt	r0, #:upper16:d_080bc4c4+1
	movs	r1, #0x70
	movs	r2, #0xbe
	bl	decode_image_file_with_offset
	movw	lr, #0xf8
	movt	lr, #0x2000
	movs	r0, #2
	b.n	.L0801da90
.L0801d988:
	movs	r0, #0xc0
	movw	r1, #0x139
	movw	r12, #0x18c3
	b.n	.L0801d99a
.L0801d994:
	adds	r0, #1
	cmp	r0, #0xde
	beq.n	.L0801da8e
.L0801d99a:
	movs	r3, #0x75
	b.n	.L0801d9a6
	.short	0xbf00	@ padding
.L0801d9a0:
	adds	r3, #4
	cmp	r3, r1
	beq.n	.L0801d994
.L0801d9a6:
	ldrh	r4, [r6, #0]
	subs	r7, r3, #3
	cmp	r7, r4
	bcc.n	.L0801d9e0
	ldrh	r4, [r6, #0]
	ldrh	r5, [r6, #4]
	add	r5, r4
	cmp	r5, r7
	bls.n	.L0801d9e0
	ldrh	r7, [r6, #2]
	cmp	r0, r7
	bcc.n	.L0801d9e0
	ldrh	r7, [r6, #2]
	ldrh	r5, [r6, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L0801d9e0
	ldr	r7, [r6, #8]
	ldrh	r5, [r6, #0]
	ldrh	r4, [r6, #2]
	ldrh	r2, [r6, #4]
	subs	r4, r0, r4
	muls	r2, r4, r2
	subs	r2, r2, r5
	add	r2, r3
	add.w	r2, r7, r2, lsl #1
	strh	r12, [r2, #-6]
.L0801d9e0:
	ldrh	r2, [r6, #0]
	subs	r7, r3, #2
	cmp	r7, r2
	bcc.n	.L0801da1c
	ldrh	r2, [r6, #0]
	ldrh	r5, [r6, #4]
	add	r2, r5
	cmp	r2, r7
	bls.n	.L0801da1c
	ldrh	r2, [r6, #2]
	cmp	r0, r2
	bcc.n	.L0801da1c
	ldrh	r2, [r6, #2]
	ldrh	r7, [r6, #6]
	add	r2, r7
	cmp	r2, r0
	bls.n	.L0801da1c
	ldr	r2, [r6, #8]
	ldrh	r7, [r6, #0]
	ldrh	r5, [r6, #2]
	ldrh	r4, [r6, #4]
	subs	r5, r0, r5
	muls	r5, r4, r5
	subs	r7, r5, r7
	add	r7, r3
	add.w	r2, r2, r7, lsl #1
	strh	r12, [r2, #-4]
	nop
.L0801da1c:
	ldrh	r2, [r6, #0]
	subs	r7, r3, #1
	cmp	r7, r2
	bcc.n	.L0801da58
	ldrh	r2, [r6, #0]
	ldrh	r5, [r6, #4]
	add	r2, r5
	cmp	r2, r7
	bls.n	.L0801da58
	ldrh	r2, [r6, #2]
	cmp	r0, r2
	bcc.n	.L0801da58
	ldrh	r2, [r6, #2]
	ldrh	r7, [r6, #6]
	add	r2, r7
	cmp	r2, r0
	bls.n	.L0801da58
	ldr	r2, [r6, #8]
	ldrh	r7, [r6, #0]
	ldrh	r5, [r6, #2]
	ldrh	r4, [r6, #4]
	subs	r5, r0, r5
	muls	r5, r4, r5
	subs	r7, r5, r7
	add	r7, r3
	add.w	r2, r2, r7, lsl #1
	strh	r12, [r2, #-2]
	nop
.L0801da58:
	ldrh	r2, [r6, #0]
	cmp	r3, r2
	bcc.n	.L0801d9a0
	ldrh	r2, [r6, #0]
	ldrh	r7, [r6, #4]
	add	r2, r7
	cmp	r2, r3
	bls.n	.L0801d9a0
	ldrh	r2, [r6, #2]
	cmp	r0, r2
	bcc.n	.L0801d9a0
	ldrh	r2, [r6, #2]
	ldrh	r7, [r6, #6]
	add	r2, r7
	cmp	r2, r0
	bls.n	.L0801d9a0
	ldr	r2, [r6, #8]
	ldrh	r7, [r6, #0]
	ldrh	r5, [r6, #2]
	ldrh	r4, [r6, #4]
	subs	r5, r0, r5
	muls	r5, r4, r5
	subs	r7, r5, r7
	add	r7, r3
	strh.w	r12, [r2, r7, lsl #1]
	b.n	.L0801d9a0
.L0801da8e:
	movs	r0, #1
.L0801da90:
	ldrb.w	r1, [lr, #0xf60]
	adr.w	r2, .L0801e420
	add.w	r1, r2, r1, lsl #2
	ldr.w	r1, [r1, #-4]
	ldrh.w	r0, [r9, r0, lsl #1]
	movs	r7, #1
	strd	r1, r8, [sp, #0]
	str	r0, [sp, #8]
	movs	r0, #0x78
	movs	r1, #0xbe
	movs	r2, #0xb8
	b.w	.L0801e410
.L0801dab6:
	movw	r2, #0x8350
	movs	r0, #0x70
	mov.w	lr, #0x71
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L0801dadc
	.short	0xbf00	@ padding
.L0801dad0:
	adds	r0, #2
	cmp	r0, #0x90
	add.w	lr, lr, #2
	beq.w	.L0801dbde
.L0801dadc:
	movs	r6, #0x7b
	b.n	.L0801dae6
.L0801dae0:
	adds	r6, #2
	cmp	r6, r3
	beq.n	.L0801db58
.L0801dae6:
	ldrh	r4, [r2, #0]
	subs	r5, r6, #1
	cmp	r5, r4
	bcc.n	.L0801db20
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r4
	cmp	r7, r5
	bls.n	.L0801db20
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	bcc.n	.L0801db20
	ldrh	r7, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L0801db20
	ldr	r7, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r6
	add.w	r1, r7, r1, lsl #1
	strh	r12, [r1, #-2]
.L0801db20:
	ldrh	r1, [r2, #0]
	cmp	r6, r1
	bcc.n	.L0801dae0
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801dae0
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L0801dae0
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L0801dae0
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r5, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r5, r0, r5
	muls	r5, r7, r5
	subs	r4, r5, r4
	add	r4, r6
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L0801dae0
	.short	0xbf00	@ padding
.L0801db58:
	orr	r6, r0, #1
	movs	r5, #0x7b
	b.n	.L0801db66
.L0801db60:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L0801dad0
.L0801db66:
	ldrh	r1, [r2, #0]
	subs	r4, r5, #1
	cmp	r4, r1
	bcc.n	.L0801dba4
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r4
	bls.n	.L0801dba4
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L0801dba4
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801dba4
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	add.w	r1, r8, r1, lsl #1
	strh	r12, [r1, #-2]
.L0801dba4:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	bcc.n	.L0801db60
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L0801db60
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L0801db60
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801db60
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	strh.w	r12, [r8, r1, lsl #1]
	b.n	.L0801db60
.L0801dbde:
	movw	r0, #:lower16:d_080bc5ce+1
	movt	r0, #:upper16:d_080bc5ce+1
	movs	r1, #0xa6
	movs	r2, #0x79
	bl	decode_image_file_with_offset
	movs	r0, #1
.L0801dbf0:
	movw	r1, #:lower16:d_0804c180
	movt	r1, #:upper16:d_0804c180
	ldrh.w	r0, [r1, r0, lsl #1]
	movw	r1, #0x1114
	movw	r2, #:lower16:d_080bbc54+1
	movt	r1, #0x2000
	movt	r2, #:upper16:d_080bbc54+1
	movs	r7, #1
	strd	r2, r1, [sp, #0]
	str	r0, [sp, #8]
	movs	r0, #0xb6
	movs	r1, #0x6f
	b.w	.L0801e40e
.L0801dc1c:
	movw	r0, #:lower16:d_080bc5fc
	movt	r0, #:upper16:d_080bc5fc
	movs	r1, #0xa5
.L0801dc26:
	movs	r2, #0x45
	bl	decode_image_file_with_offset
	movs	r0, #2
.L0801dc2e:
	movw	r9, #:lower16:d_0804c180
	movt	r9, #:upper16:d_0804c180
	ldrh.w	r0, [r9, r0, lsl #1]
	movw	r2, #:lower16:d_080bd09a+1
	movs	r1, #1
	movw	r8, #0x1114
	movt	r2, #:upper16:d_080bd09a+1
	movt	r8, #0x2000
	str	r2, [sp, #0]
	strd	r0, r1, [sp, #8]
	movs	r0, #0xb6
	movs	r1, #0x3d
	movs	r2, #0x5c
	movs	r3, #0x22
	str.w	r8, [sp, #4]
	bl	draw_wrapped_text_in_box
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0xf69]
	cbz	r0, .L0801dca0
	ldrb.w	r0, [r3, #0xf6b]
	cmp	r0, #1
	bne.n	.L0801dca0
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x85
	mov	r4, r3
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r4, #0xf60]
	cmp	r0, #2
	bne.w	.L0801ddf2
	movw	r0, #:lower16:d_080bc54a
	movt	r0, #:upper16:d_080bc54a
	movs	r1, #0xa6
	b.n	.L0801ddfc
.L0801dca0:
	movw	r2, #0x8350
	movs	r0, #0x86
	mov.w	lr, #0x87
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L0801dcc4
.L0801dcb8:
	adds	r0, #2
	cmp	r0, #0xa6
	add.w	lr, lr, #2
	beq.w	.L0801ddc6
.L0801dcc4:
	movs	r6, #0x7b
	b.n	.L0801dcce
.L0801dcc8:
	adds	r6, #2
	cmp	r6, r3
	beq.n	.L0801dd40
.L0801dcce:
	ldrh	r5, [r2, #0]
	subs	r4, r6, #1
	cmp	r4, r5
	bcc.n	.L0801dd08
	ldrh	r5, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r5
	cmp	r7, r4
	bls.n	.L0801dd08
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	bcc.n	.L0801dd08
	ldrh	r7, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L0801dd08
	ldr	r7, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r6
	add.w	r1, r7, r1, lsl #1
	strh	r12, [r1, #-2]
.L0801dd08:
	ldrh	r1, [r2, #0]
	cmp	r6, r1
	bcc.n	.L0801dcc8
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L0801dcc8
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L0801dcc8
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L0801dcc8
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r5, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r5, r0, r5
	muls	r5, r7, r5
	subs	r4, r5, r4
	add	r4, r6
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L0801dcc8
	.short	0xbf00	@ padding
.L0801dd40:
	orr	r6, r0, #1
	movs	r4, #0x7b
	b.n	.L0801dd4e
.L0801dd48:
	adds	r4, #2
	cmp	r4, r3
	beq.n	.L0801dcb8
.L0801dd4e:
	ldrh	r1, [r2, #0]
	subs	r5, r4, #1
	cmp	r5, r1
	bcc.n	.L0801dd8c
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r5
	bls.n	.L0801dd8c
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L0801dd8c
	ldrh	r1, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r1, r5
	cmp	r1, r6
	bls.n	.L0801dd8c
	ldr.w	r10, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r5
	add	r1, r4
	add.w	r1, r10, r1, lsl #1
	strh	r12, [r1, #-2]
.L0801dd8c:
	ldrh	r1, [r2, #0]
	cmp	r4, r1
	bcc.n	.L0801dd48
	ldrh	r1, [r2, #0]
	ldrh	r5, [r2, #4]
	add	r1, r5
	cmp	r1, r4
	bls.n	.L0801dd48
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L0801dd48
	ldrh	r1, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r1, r5
	cmp	r1, r6
	bls.n	.L0801dd48
	ldr.w	r10, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r5
	add	r1, r4
	strh.w	r12, [r10, r1, lsl #1]
	b.n	.L0801dd48
.L0801ddc6:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf60]
	movs	r1, #0xa6
	movs	r2, #0x8f
	cmp	r0, #2
	ittee	ne
	movwne	r0, #:lower16:d_080bc5ce+1
	movtne	r0, #:upper16:d_080bc5ce+1
	movweq	r0, #:lower16:d_080bc4f2
	movteq	r0, #:upper16:d_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.n	.L0801de04
.L0801ddf2:
	movw	r0, #:lower16:d_080bc5fc
	movt	r0, #:upper16:d_080bc5fc
	movs	r1, #0xa5
.L0801ddfc:
	movs	r2, #0x8d
	bl	decode_image_file_with_offset
	movs	r0, #2
.L0801de04:
	ldrh.w	r0, [r9, r0, lsl #1]
	movw	r1, #:lower16:d_080bc6ae
	movt	r1, #:upper16:d_080bc6ae
	movs	r7, #1
	strd	r1, r8, [sp, #0]
	str	r0, [sp, #8]
	movs	r0, #0xb6
	movs	r1, #0x85
	b.n	.L0801e40e
.L0801de1e:
	movw	r0, #:lower16:d_080bc54a
	movt	r0, #:upper16:d_080bc54a
	movs	r1, #0xa6
.L0801de28:
	movs	r2, #0x45
	bl	decode_image_file_with_offset
	movs	r0, #2
.L0801de30:
	movw	r9, #:lower16:d_0804c180
	movt	r9, #:upper16:d_0804c180
	ldrh.w	r0, [r9, r0, lsl #1]
	movw	r2, #:lower16:d_080bbc36+1
	movs	r1, #1
	movw	r8, #0x1114
	movt	r2, #:upper16:d_080bbc36+1
	movt	r8, #0x2000
	str	r2, [sp, #0]
	strd	r0, r1, [sp, #8]
	movs	r0, #0xb6
	movs	r1, #0x3d
	movs	r2, #0x5c
	movs	r3, #0x22
	str.w	r8, [sp, #4]
	bl	draw_wrapped_text_in_box
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldrb.w	r0, [r1, #0xf69]
	cbz	r0, .L0801dea8
	ldrb.w	r0, [r1, #0xf6b]
	cmp	r0, #1
	bne.n	.L0801dea8
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x61
	bl	decode_image_file_with_offset
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf65]
	cmp	r0, #1
	bne.w	.L0801dffa
	movw	r0, #:lower16:d_080bc54a
	movt	r0, #:upper16:d_080bc54a
	movs	r1, #0xa6
	b.n	.L0801e004
.L0801dea8:
	movw	r2, #0x8350
	movs	r0, #0x62
	mov.w	lr, #0x63
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L0801decc
.L0801dec0:
	adds	r0, #2
	cmp	r0, #0x82
	add.w	lr, lr, #2
	beq.w	.L0801dfce
.L0801decc:
	movs	r5, #0x7b
	b.n	.L0801ded6
.L0801ded0:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L0801df48
.L0801ded6:
	ldrh	r6, [r2, #0]
	subs	r4, r5, #1
	cmp	r4, r6
	bcc.n	.L0801df10
	ldrh	r6, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r6
	cmp	r7, r4
	bls.n	.L0801df10
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	bcc.n	.L0801df10
	ldrh	r7, [r2, #2]
	ldrh	r6, [r2, #6]
	add	r7, r6
	cmp	r7, r0
	bls.n	.L0801df10
	ldr	r7, [r2, #8]
	ldrh	r6, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r6
	add	r1, r5
	add.w	r1, r7, r1, lsl #1
	strh	r12, [r1, #-2]
.L0801df10:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	bcc.n	.L0801ded0
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L0801ded0
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L0801ded0
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L0801ded0
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r6, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r6, r0, r6
	muls	r6, r7, r6
	subs	r4, r6, r4
	add	r4, r5
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L0801ded0
	.short	0xbf00	@ padding
.L0801df48:
	orr	r5, r0, #1
	movs	r4, #0x7b
	b.n	.L0801df56
	.include "src/parts/draw_page_by_selector_nibble_p2.inc"
