@ gfx_11.s - graphics: RGB565 shade table builder and the text column drawer with a highlighted character.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_080092dc - builds a table of 16 shades of one RGB565 colour.
@ r0 = packed 16-bit value with three fields (bits 15..11, bits 10..5, bits 4..0).
@ r1 = output array of 16 halfwords. Entry 0 is 0; entry k (1..15) is each field
@ multiplied by k/16 (constants 0.0625 .. 0.9375, float, converted back to integer
@ by truncation) and repacked into the same 5-6-5 layout (field masks 0x1f / 0x3f / 0x1f).
@ The constant 0.0625 is the literal word at 0x0800966c.
@ ----------------------------------------------------------------------------
	.section .text.fn_080092dc,"ax",%progbits
	.global fn_080092dc
	.thumb_func
	.type fn_080092dc, %function
fn_080092dc:
	lsrs	r2, r0, #11
	vmov	s0, r2
	vldr	s6, .L0800966c
	vcvt.f32.s32	s0, s0
	ubfx	r2, r0, #5, #6
	and	r0, r0, #0x1f
	vmov	s2, r2
	vmov	s4, r0
	vmul.f32	s8, s0, s6
	vcvt.f32.s32	s2, s2
	vcvt.f32.s32	s4, s4
	movs	r0, #0
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #0]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.125
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #2]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.1875
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #4]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.25
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #6]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.3125
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #8]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.375
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #10]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.4375
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #12]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.5
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #14]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.5625
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #16]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.625
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #18]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.6875
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #20]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.75
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #22]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.8125
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #24]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.875
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s8, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s8, s8
	strh	r0, [r1, #26]
	vmov	r0, s8
	vmul.f32	s8, s2, s6
	vmul.f32	s6, s4, s6
	vcvt.s32.f32	s6, s6
	vcvt.s32.f32	s8, s8
	vmov	r3, s6
	vmov	r2, s8
	and	r3, r3, #0x1f
	vmov.f32	s6, #0.9375
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	vmul.f32	s0, s0, s6
	orr.w	r0, r0, r2, lsl #5
	vcvt.s32.f32	s0, s0
	strh	r0, [r1, #28]
	vmov	r0, s0
	vmul.f32	s0, s2, s6
	vcvt.s32.f32	s0, s0
	vmov	r2, s0
	vmul.f32	s0, s4, s6
	vcvt.s32.f32	s0, s0
	vmov	r3, s0
	and	r3, r3, #0x1f
	and	r2, r2, #0x3f
	orr.w	r0, r3, r0, lsl #11
	orr.w	r0, r0, r2, lsl #5
	strh	r0, [r1, #30]
	bx	lr
	.short	0xbf00	@ padding
.L0800966c:
	.word	0x3d800000	@ float 0.0625

@ ----------------------------------------------------------------------------
@ draw_text_column_with_char_highlight - draws the text buffer as a word-wrapped,
@ horizontally centred text column with one highlighted character.
@ r0 = y of the first line; r1 = index of the highlighted character (bit 7 selects
@ the highlight kind); r2 = colour; no return value.
@ Reads the text from the buffer 0x20008360. First pass: decodes characters with
@ decode_utf8_char (0803a40c) and measures each with the callback [0x20001114]
@ (0x20001114 is the font object) until a character 0, 0x0a or 0x0d or a callback
@ result of 0, counting n. Allocates 4*n bytes (code points) and 12*n bytes (metric
@ records) with alloc_units_of_32_bytes (0803acfc); returns if the first allocation
@ fails, frees it if the second fails. Second pass fills the arrays.
@ Word-wraps at 0x42 pixels (break at space 0x20, a trailing space is dropped);
@ each line is centred horizontally in the column starting at x=0xcc
@ (x=0xcc+(0x42-linewidth)/2; this rewrite, V1.2.0: 0x5e from x=0xb0). Font: 0x20001144 (20 px;
@ this rewrite, V1.2.0 0x20001114 18 px; the 0x2000111c / [0x20001114] below read 0x2000114c /
@ [0x20001144] now), line step [0x2000111c]; when the whole text is lower
@ than 0x16 pixels the first y is moved down by (0x16-height)/2. Draws each glyph
@ with blend_glyph_into_region_buffer (0800fb90): (x, y, metric record, code point,
@ 0x20001114, colour).
@ Highlight: the character whose running index equals (r1&0x7f) is drawn in colour 0;
@ when bit 7 of r1 is clear its cell (width from the metric record, height
@ [0x2000111c]) is first filled with 0x55f in the region buffer [0x20008358], clipped
@ to the region record [0x20008350..56]; when bit 7 is set no fill is made.
@ At the end frees both arrays (callback (*[0x20001070])(0) if [0x20001080]==0, else
@ 080082bc on the entry range of table [0x2000107c] when the offset test
@ (blk-[0x20001078])<0x2bc00 / >>10<0xaf passes).
@ ----------------------------------------------------------------------------
	.section .text.draw_text_column_with_char_highlight,"ax",%progbits
	.global draw_text_column_with_char_highlight
	.thumb_func
	.type draw_text_column_with_char_highlight, %function
draw_text_column_with_char_highlight:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, sp, #0x5c
	movw	r6, #0x8360
	movs	r5, #0
	movt	r6, #0x2000
	add	r7, sp, #0x4c
	add.w	r10, sp, #0x50
	mov.w	r8, #1
	movw	r9, #0x2401
	str	r2, [sp, #0x48]
	str	r1, [sp, #0x18]
	str	r0, [sp, #0x40]
	str	r5, [sp, #0x4c]
	nop
.L0800e674:
	mov	r0, r6
	mov	r1, r7
	bl	decode_utf8_char
	mov	r2, r0
	cmp	r0, #0xd
	bhi.n	.L0800e68c
	lsl.w	r0, r8, r2
	tst.w	r0, r9
	bne.n	.L0800e6a2
.L0800e68c:
	movw	r0, #0x1144
	movt	r0, #0x2000
	ldr	r4, [r0, #0]
	mov	r1, r10
	movs	r3, #0
	blx	r4
	cbz	r0, .L0800e6a2
	adds	r5, #1
	b.n	.L0800e674
.L0800e6a2:
	uxth	r4, r5
	lsls	r0, r4, #2
	bl	alloc_units_of_32_bytes
	cmp	r0, #0
	beq.w	.L0800f14e
	str	r0, [sp, #0x3c]
	add.w	r0, r4, r4, lsl #1
	lsls	r0, r0, #2
	str	r4, [sp, #0x2c]
	bl	alloc_units_of_32_bytes
	movw	r4, #0x1070
	cmp	r0, #0
	movt	r4, #0x2000
	str	r0, [sp, #0x38]
	beq.w	.L0800f118
	movs	r0, #0
	lsls.w	r8, r5, #16
	str	r0, [sp, #0x4c]
	beq.w	.L0800e7ea
	ldr	r0, [sp, #0x3c]
	movw	r9, #0x8360
	ldr	r7, [sp, #0x38]
	ldr	r4, [sp, #0x2c]
	movw	r11, #0x1144
	subs	r6, r0, #4
	movt	r9, #0x2000
	add.w	r10, sp, #0x4c
	movt	r11, #0x2000
	nop
.L0800e6f8:
	mov	r0, r9
	mov	r1, r10
	bl	decode_utf8_char
	str.w	r0, [r6, #4]!
	ldr.w	r5, [r11, #0]
	mov	r2, r0
	mov	r0, r11
	mov	r1, r7
	movs	r3, #0
	blx	r5
	subs	r4, #1
	add.w	r7, r7, #0xc
	bne	.L0800e6f8
	ldrh.w	r12, [r11, #8]
	ldr.w	r11, [sp, #0x2c]
	ldrd	r0, lr, [sp, #0x38]
	movs	r6, #0
	movs	r2, #0
	movs	r3, #0
	mov	r1, r12
	movs	r7, #0
	b.n	.L0800e742
.L0800e732:
	mov	r2, r3
.L0800e734:
	add	r1, r12
	movs	r7, #0
	movs	r3, #0
.L0800e73a:
	adds	r2, #1
	uxtb	r6, r2
	cmp	r6, r11
	bcs.n	.L0800e79e
.L0800e742:
	add.w	r5, r6, r6, lsl #1
	ldrh.w	r5, [r0, r5, lsl #2]
	ldr.w	r6, [lr, r6, lsl #2]
	uxtah	r7, r5, r7
	cmp	r6, #0x20
	uxth	r5, r7
	it	eq
	moveq	r3, #1
	cmp	r5, #0x5f
	bcc.n	.L0800e73a
	cmp	r6, #0x20
	beq.n	.L0800e734
	lsls	r3, r3, #24
	beq.n	.L0800e79a
	nop
.L0800e768:
	subs	r3, r2, #1
	uxtb	r7, r3
	ldr.w	r7, [lr, r7, lsl #2]
	cmp	r7, #0x20
	beq.n	.L0800e732
	subs	r3, r2, #2
	uxtb	r7, r3
	ldr.w	r7, [lr, r7, lsl #2]
	cmp	r7, #0x20
	beq.n	.L0800e732
	subs	r3, r2, #3
	uxtb	r7, r3
	ldr.w	r7, [lr, r7, lsl #2]
	cmp	r7, #0x20
	beq.n	.L0800e732
	subs	r2, #4
	uxtb	r3, r2
	ldr.w	r3, [lr, r3, lsl #2]
	cmp	r3, #0x20
	bne.n	.L0800e768
	b.n	.L0800e734
.L0800e79a:
	subs	r2, #1
	b.n	.L0800e734
.L0800e79e:
	sxth	r1, r1
	ldr	r0, [sp, #0x48]
	cmp	r1, #0x16
	ble.n	.L0800e816
	ldr	r4, [sp, #0x38]
	cmp.w	r8, #0
	beq.w	.L0800ec5a
	movs	r7, #0
	movs	r2, #0
	mov	r1, r12
	movs	r3, #0
	b.n	.L0800e7c6
	.short	0xbf00	@ padding
.L0800e7bc:
	adds	r2, #1
	uxtb	r7, r2
	cmp	r7, r11
	bcs.w	.L0800ec5c
.L0800e7c6:
	add.w	r6, r7, r7, lsl #1
	ldrh.w	r6, [r4, r6, lsl #2]
	uxtah	r3, r6, r3
	uxth	r6, r3
	cmp	r6, #0x5f
	bcc.n	.L0800e7bc
	ldr.w	r3, [lr, r7, lsl #2]
	add	r1, r12
	cmp	r3, #0x20
	mov.w	r3, #0
	it	ne
	subne	r2, #1
	b.n	.L0800e7bc
.L0800e7ea:
	movw	r0, #0x1144
	movt	r0, #0x2000
	ldrsh.w	r1, [r0, #8]
	ldr.w	r11, [sp, #0x2c]
	ldrd	r4, lr, [sp, #0x38]
	cmp	r1, #0x16
	bgt.w	.L0800ec5c
	rsb.w	r0, r1, #0x16
	ldr	r1, [sp, #0x40]
	add.w	r0, r0, r0, lsr #31
	add.w	r0, r1, r0, lsr #1
	str	r0, [sp, #0x30]
	b.n	.L0800eaf8
.L0800e816:
	mov	r12, r0
	rsb.w	r0, r1, #0x16
	ldr	r1, [sp, #0x40]
	add.w	r0, r0, r0, lsr #31
	ldr	r5, [sp, #0x38]
	cmp.w	r8, #0
	add.w	r0, r1, r0, lsr #1
	str	r0, [sp, #0x30]
	beq.w	.L0800eaf8
	ldr	r0, [sp, #0x18]
	movw	r9, #0x8350
	and.w	r10, r0, #0x7f
	and.w	r0, r0, #0x80
	str	r0, [sp, #0x20]
	movs	r0, #0
	movs	r2, #0
	movt	r9, #0x2000
	movs	r6, #0
	movs	r1, #0
	str	r0, [sp, #0x44]
	movs	r0, #0
	movs	r3, #0
	str	r3, [sp, #0x40]
	b.n	.L0800e866
.L0800e858:
	mov	r6, r7
	adds	r6, r7, #1
.L0800e85c:
	mov	r0, r3
.L0800e85e:
	uxtb	r2, r6
	cmp	r2, r11
	bcs.w	.L0800eb02
.L0800e866:
	add.w	r3, r2, r2, lsl #1
	ldrh.w	r3, [r5, r3, lsl #2]
	ldr.w	r2, [lr, r2, lsl #2]
	add	r3, r0
	mov	r7, r6
	uxth	r6, r3
	cmp	r2, #0x20
	it	eq
	moveq	r1, #1
	cmp	r6, #0x42			@ column width (this rewrite: 0x42 from x 0xcc; V1.2.0 0x5e from 0xb0)
	bls.n	.L0800e858
	cmp	r2, #0x20
	mov	r4, r7
	beq.n	.L0800e900
	lsls	r1, r1, #24
	sub.w	r4, r4, #1
	beq.n	.L0800e900
	uxtb	r1, r4
	ldr.w	r2, [lr, r1, lsl #2]
	cmp	r2, #0x20
	beq.n	.L0800e906
	nop
.L0800e89c:
	subs	r2, r4, #1
	add.w	r3, r1, r1, lsl #1
	uxtb	r1, r2
	ldr.w	r6, [lr, r1, lsl #2]
	ldrh.w	r3, [r5, r3, lsl #2]
	cmp	r6, #0x20
	sub.w	r0, r0, r3
	beq.n	.L0800e904
	subs	r2, r4, #2
	add.w	r3, r1, r1, lsl #1
	uxtb	r1, r2
	ldr.w	r7, [lr, r1, lsl #2]
	ldrh.w	r3, [r5, r3, lsl #2]
	cmp	r7, #0x20
	sub.w	r0, r0, r3
	beq.n	.L0800e904
	subs	r2, r4, #3
	add.w	r3, r1, r1, lsl #1
	uxtb	r1, r2
	ldr.w	r7, [lr, r1, lsl #2]
	ldrh.w	r3, [r5, r3, lsl #2]
	cmp	r7, #0x20
	sub.w	r0, r0, r3
	beq.n	.L0800e904
	subs	r4, #4
	add.w	r2, r1, r1, lsl #1
	uxtb	r1, r4
	ldr.w	r3, [lr, r1, lsl #2]
	ldrh.w	r2, [r5, r2, lsl #2]
	cmp	r3, #0x20
	sub.w	r0, r0, r2
	bne.n	.L0800e89c
	b.n	.L0800e906
	.short	0xbf00	@ padding
.L0800e900:
	ldr	r1, [sp, #0x40]
	b.n	.L0800e914
.L0800e904:
	mov	r4, r2
.L0800e906:
	add.w	r1, r1, r1, lsl #1
	ldrh.w	r1, [r5, r1, lsl #2]
	subs	r0, r0, r1
	ldr	r1, [sp, #0x40]
	adds	r1, #1
.L0800e914:
	ldr	r2, [sp, #0x44]
	uxtb	r3, r4
	uxtb.w	r12, r2
	cmp	r3, r12
	mov	r7, r10
	str	r4, [sp, #0x24]
	bcs.n	.L0800e934
	ldr.w	r10, [sp, #0x30]
	movw	r8, #0x1144
	ldr	r6, [sp, #0x48]
	movt	r8, #0x2000
	b.n	.L0800ead4
.L0800e934:
	uxth	r0, r0
	ldr	r2, [sp, #0x20]
	rsb.w	r0, r0, #0x42			@ centred in the value column x 0xcc..0x10d (the generator rows'
	add.w	r0, r0, r0, lsr #31		@ labels have 0x7a..0xcb, src/ui_pages_76.s)
	cmp	r2, #0
	mov.w	r2, #0xcc
	add.w	r11, r2, r0, lsr #1
	str	r3, [sp, #0x34]
	bne.w	.L0800ea7c
	ldr	r0, [sp, #0x30]
	ldrd	r3, r6, [sp, #0x44]
	subs	r0, #1
	str	r0, [sp, #0x28]
	b.n	.L0800e9aa
.L0800e95c:
	movs	r6, #0
.L0800e95e:
	ldr	r0, [sp, #0x3c]
	ldr	r5, [sp, #0x38]
	mov	r7, r10
	ldr.w	r10, [sp, #0x30]
	add.w	r4, r12, r12, lsl #1
	ldr.w	r3, [r0, r12, lsl #2]
	movw	r8, #0x1144
	add.w	r2, r5, r4, lsl #2
	sxth.w	r0, r11
	sxth.w	r1, r10
	movt	r8, #0x2000
	str	r6, [sp, #4]
	str.w	r8, [sp, #0]
	bl	blend_glyph_into_region_buffer
	ldr	r3, [sp, #0x44]
	ldr	r1, [sp, #0x40]
	ldrh.w	r0, [r5, r4, lsl #2]
	adds	r3, #1
	ldr	r2, [sp, #0x34]
	uxtb.w	r12, r3
	ldr	r6, [sp, #0x48]
	adds	r1, #1
	cmp	r2, r12
	add	r11, r0
	bcc.w	.L0800ead4
.L0800e9aa:
	uxtb	r0, r1
	cmp	r7, r0
	mov	r10, r7
	strd	r1, r3, [sp, #0x40]
	bne.n	.L0800e95e
	movw	r0, #0x1144
	movt	r0, #0x2000
	ldrh	r0, [r0, #8]
	ldr	r1, [sp, #0x28]
	add	r0, r1
	ldr	r1, [sp, #0x30]
	sxth.w	lr, r0
	sxth	r2, r1
	cmp	r2, lr
	bgt.n	.L0800e95c
	ldr	r0, [sp, #0x38]
	add.w	r2, r12, r12, lsl #1
	ldrh.w	r2, [r0, r2, lsl #2]
	sxth.w	r3, r11
	add	r2, r11
	subs	r2, #1
	sxth	r2, r2
	cmp	r3, r2
	mov	r3, r1
	ble.n	.L0800ea1c
	ldr	r2, [sp, #0x30]
.L0800e9ec:
	adds	r3, r2, #1
	sxth	r3, r3
	cmp	r3, lr
	mov.w	r6, #0
	bgt.n	.L0800e95e
	adds	r3, r2, #2
	sxth	r3, r3
	cmp	r3, lr
	bgt.n	.L0800e95e
	adds	r3, r2, #3
	sxth	r3, r3
	cmp	r3, lr
	bgt.n	.L0800e95e
	adds	r2, #4
	sxth	r2, r2
	cmp	r2, lr
	ble.n	.L0800e9ec
	b.n	.L0800e95e
	.short	0xbf00	@ padding
.L0800ea14:
	adds	r3, #1
	sxth	r3, r3
	cmp	r3, lr
	bgt.n	.L0800e95c
.L0800ea1c:
	sxth	r6, r3
	mov	r5, r11
	b.n	.L0800ea2c
	.short	0xbf00	@ padding
.L0800ea24:
	adds	r0, r5, #1
	sxth	r5, r0
	cmp	r5, r2
	bgt.n	.L0800ea14
.L0800ea2c:
	ldrh.w	r7, [r9, #0]
	sxth	r4, r5
	cmp	r4, r7
	blt.n	.L0800ea24
	ldrh.w	r7, [r9, #0]
	ldrh.w	r1, [r9, #4]
	add	r1, r7
	cmp	r1, r4
	ble.n	.L0800ea24
	ldrh.w	r1, [r9, #2]
	cmp	r6, r1
	blt.n	.L0800ea24
	ldrh.w	r1, [r9, #2]
	ldrh.w	r7, [r9, #6]
	add	r1, r7
	cmp	r1, r6
	ble.n	.L0800ea24
	ldr.w	r1, [r9, #8]
	ldrh.w	r7, [r9, #0]
	subs	r7, r4, r7
	ldrh.w	r4, [r9, #2]
	ldrh.w	r0, [r9, #4]
	subs	r4, r6, r4
	mla	r0, r4, r0, r7
	movw	r4, #0x55f
	strh.w	r4, [r1, r0, lsl #1]
	b.n	.L0800ea24
.L0800ea7c:
	ldr	r5, [sp, #0x38]
	ldr.w	r10, [sp, #0x30]
	movw	r8, #0x1144
	ldrd	r3, r6, [sp, #0x44]
	movt	r8, #0x2000
	nop
.L0800ea90:
	strd	r1, r3, [sp, #0x40]
	uxtb	r0, r1
	ldr	r1, [sp, #0x3c]
	subs	r0, r7, r0
	add.w	r4, r12, r12, lsl #1
	ldr.w	r3, [r1, r12, lsl #2]
	it	ne
	movne	r0, r6
	add.w	r2, r5, r4, lsl #2
	str	r0, [sp, #4]
	sxth.w	r0, r11
	sxth.w	r1, r10
	str.w	r8, [sp, #0]
	bl	blend_glyph_into_region_buffer
	add	r6, sp, #0x40
	ldmia	r6, {r1, r3, r6}
	ldrh.w	r0, [r5, r4, lsl #2]
	adds	r3, #1
	ldr	r2, [sp, #0x34]
	uxtb.w	r12, r3
	adds	r1, #1
	cmp	r2, r12
	add	r11, r0
	bcs.n	.L0800ea90
.L0800ead4:
	mov	r12, r6
	ldrh.w	r0, [r8, #8]
	ldr	r6, [sp, #0x24]
	add	r10, r0
	adds	r6, #1
	ldr.w	lr, [sp, #0x3c]
	ldr.w	r11, [sp, #0x2c]
	str	r1, [sp, #0x40]
	str.w	r10, [sp, #0x30]
	movs	r0, #0
	str	r6, [sp, #0x44]
	movs	r1, #0
	mov	r10, r7
	b.n	.L0800e85e
.L0800eaf8:
	movs	r0, #0
	movs	r1, #0
	str	r0, [sp, #0x40]
	movs	r0, #0
	str	r1, [sp, #0x44]
.L0800eb02:
	ldr.w	r8, [sp, #0x44]
	ldr	r2, [sp, #0x40]
	uxtb.w	r12, r8
	cmp	r12, r11
	bcs.w	.L0800f0e4
	uxth	r0, r0
	rsb.w	r0, r0, #0x42			@ value column 0xcc..0x10d (V1.2.0 0x5e from 0xb0)
	add.w	r0, r0, r0, lsr #31
	movs	r1, #0xcc
	add.w	r9, r1, r0, lsr #1
	ldr	r1, [sp, #0x18]
	mov	r3, r8
	lsls	r0, r1, #24
	and.w	r1, r1, #0x7f
	str	r1, [sp, #0x34]
	bmi.w	.L0800f036
	ldr	r0, [sp, #0x30]
	movw	r5, #0x8350
	subs	r7, r0, #1
	str	r7, [sp, #0x24]
	ldr	r6, [sp, #0x48]
	movw	r7, #0x1144
	sxth	r0, r0
	movt	r5, #0x2000
	movt	r7, #0x2000
	mov	r8, r3
	str	r0, [sp, #0x28]
	b.n	.L0800eb94
	.short	0xbf00	@ padding
.L0800eb54:
	movs	r6, #0
.L0800eb56:
	ldr	r0, [sp, #0x3c]
	ldr	r4, [sp, #0x38]
	add.w	r11, r12, r12, lsl #1
	ldr.w	r3, [r0, r12, lsl #2]
	ldr	r1, [sp, #0x28]
	add.w	r2, r4, r11, lsl #2
	sxth.w	r0, r9
	str	r7, [sp, #0]
	str	r6, [sp, #4]
	bl	blend_glyph_into_region_buffer
	add.w	r8, r8, #1
	ldr	r1, [sp, #0x2c]
	ldrh.w	r0, [r4, r11, lsl #2]
	uxtb.w	r12, r8
	mov	r2, r10
	cmp	r12, r1
	ldr	r6, [sp, #0x48]
	ldr	r1, [sp, #0x34]
	add.w	r2, r10, #1
	add	r9, r0
	bcs.w	.L0800f0e4
.L0800eb94:
	uxtb	r0, r2
	mov	r10, r2
	cmp	r1, r0
	bne.n	.L0800eb56
	ldrh	r0, [r7, #8]
	ldr	r1, [sp, #0x24]
	add	r0, r1
	sxth.w	lr, r0
	ldr	r0, [sp, #0x28]
	cmp	r0, lr
	bgt.n	.L0800eb54
	ldr	r0, [sp, #0x38]
	add.w	r1, r12, r12, lsl #1
	ldrh.w	r1, [r0, r1, lsl #2]
	ldr	r3, [sp, #0x30]
	add	r1, r9
	subs	r1, #1
	sxth	r2, r1
	sxth.w	r1, r9
	cmp	r1, r2
	ble.n	.L0800ec00
	ldr	r1, [sp, #0x30]
	movw	r7, #0x1144
	movt	r7, #0x2000
.L0800ebd0:
	adds	r2, r1, #1
	sxth	r2, r2
	cmp	r2, lr
	mov.w	r6, #0
	bgt.n	.L0800eb56
	adds	r2, r1, #2
	sxth	r2, r2
	cmp	r2, lr
	bgt.n	.L0800eb56
	adds	r2, r1, #3
	sxth	r2, r2
	cmp	r2, lr
	bgt.n	.L0800eb56
	adds	r1, #4
	sxth	r1, r1
	cmp	r1, lr
	ble.n	.L0800ebd0
	b.n	.L0800eb56
	.short	0xbf00	@ padding
.L0800ebf8:
	adds	r1, r3, #1
	sxth	r3, r1
	cmp	r3, lr
	bgt.n	.L0800ec4e
.L0800ec00:
	sxth	r6, r3
	mov	r1, r9
	b.n	.L0800ec10
	.short	0xbf00	@ padding
.L0800ec08:
	adds	r0, r1, #1
	sxth	r1, r0
	cmp	r1, r2
	bgt.n	.L0800ebf8
.L0800ec10:
	ldrh	r7, [r5, #0]
	sxth	r4, r1
	cmp	r4, r7
	blt.n	.L0800ec08
	ldrh	r7, [r5, #0]
	ldrh	r0, [r5, #4]
	add	r0, r7
	cmp	r0, r4
	ble.n	.L0800ec08
	ldrh	r0, [r5, #2]
	cmp	r6, r0
	blt.n	.L0800ec08
	ldrh	r0, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r0, r7
	cmp	r0, r6
	ble.n	.L0800ec08
	ldr	r0, [r5, #8]
	ldrh	r7, [r5, #0]
	subs	r4, r4, r7
	ldrh	r7, [r5, #2]
	ldrh.w	r11, [r5, #4]
	subs	r7, r6, r7
	mla	r4, r7, r11, r4
	movw	r7, #0x55f
	strh.w	r7, [r0, r4, lsl #1]
	b.n	.L0800ec08
.L0800ec4e:
	movw	r7, #0x1144
	movs	r6, #0
	movt	r7, #0x2000
	b.n	.L0800eb56
.L0800ec5a:
	mov	r1, r12
.L0800ec5c:
	sxth	r0, r1
	rsb.w	r1, r0, #0x16
	cmp	r0, #0x16
	ldr	r6, [sp, #0x40]
	add.w	r1, r1, r1, lsr #31
	it	lt
	addlt.w	r6, r6, r1, lsr #1
	cmp.w	r8, #0
	beq.w	.L0800eee2
	ldr	r0, [sp, #0x18]
	movw	r10, #0x8350
	and.w	r1, r0, #0x7f
	and.w	r0, r0, #0x80
	str	r0, [sp, #0x14]
	sub.w	r0, r4, #0xc
	str	r0, [sp, #0x10]
	sub.w	r0, lr, #4
	movw	r7, #0x1144
	mov	r12, r4
	str	r0, [sp, #0xc]
	movs	r5, #0
	movt	r10, #0x2000
	movs	r4, #0
	movs	r3, #0
	movs	r0, #0
	mov.w	r8, #0
	movt	r7, #0x2000
	str	r1, [sp, #0x44]
	b.n	.L0800ecf4
.L0800ecb2:
	ldr	r0, [sp, #0x28]
	ldr	r1, [sp, #0x1c]
	ldr.w	r11, [sp, #0x2c]
	mov	r12, r5
	sub.w	r8, r1, r0
.L0800ecc0:
	ldrd	r5, r4, [sp, #0x20]
.L0800ecc4:
	ldrh	r0, [r7, #8]
	ldr.w	r1, [lr, r5, lsl #2]
	add	r6, r0
	subs.w	r0, r1, #0x20
	sub.w	r1, r1, #0x20
	clz	r1, r1
	lsr.w	r1, r1, #5
	it	ne
	movne	r0, #1
	add	r8, r1
	adds	r3, r4, r1
	subs	r4, r4, r0
	movs	r1, #0
.L0800ece8:
	adds	r4, #1
	uxtb	r5, r4
	cmp	r5, r11
	mov	r0, r1
	bcs.w	.L0800eeea
.L0800ecf4:
	add.w	r1, r5, r5, lsl #1
	ldrh.w	r1, [r12, r1, lsl #2]
	add	r1, r0
	uxth	r2, r1
	cmp	r2, #0x5f
	bcc.n	.L0800ece8
	lsls	r1, r4, #24
	beq.n	.L0800ed1c
	subs	r1, r5, #1
	ldr.w	r2, [lr, r1, lsl #2]
	cmp	r2, #0x20
	bne.n	.L0800ed1c
	add.w	r1, r1, r1, lsl #1
	ldrh.w	r1, [r12, r1, lsl #2]
	subs	r0, r0, r1
.L0800ed1c:
	uxtb.w	r9, r3
	uxtb	r1, r4
	cmp	r9, r1
	str	r1, [sp, #0x34]
	bcs.n	.L0800ecc4
	uxth	r0, r0
	rsb.w	r0, r0, #0x42			@ value column 0xcc..0x10d (V1.2.0 0x5e from 0xb0)
	add.w	r0, r0, r0, lsr #31
	movs	r1, #0xcc
	add.w	r11, r1, r0, lsr #1
	ldr	r0, [sp, #0x14]
	str	r5, [sp, #0x20]
	cmp	r0, #0
	add.w	r0, r8, r4
	str	r3, [sp, #0x28]
	str	r4, [sp, #0x24]
	str	r0, [sp, #0x1c]
	str	r6, [sp, #0x40]
	bne.w	.L0800ee70
	subs	r0, r6, #1
	mov	r5, r12
	str	r0, [sp, #0x30]
	b.n	.L0800ed8c
	.short	0xbf00	@ padding
.L0800ed58:
	movs	r1, #0
.L0800ed5a:
	add.w	r4, r9, r9, lsl #1
	ldr.w	r3, [lr, r9, lsl #2]
	add.w	r2, r5, r4, lsl #2
	str	r1, [sp, #4]
	sxth.w	r0, r11
	sxth	r1, r6
	str	r7, [sp, #0]
	bl	blend_glyph_into_region_buffer
	ldrh.w	r0, [r5, r4, lsl #2]
	ldr	r1, [sp, #0x34]
	ldr.w	lr, [sp, #0x3c]
	add.w	r9, r9, #1
	add.w	r8, r8, #1
	cmp	r9, r1
	add	r11, r0
	beq.n	.L0800ecb2
.L0800ed8c:
	ldr	r1, [sp, #0x44]
	uxtb.w	r0, r8
	cmp	r1, r0
	ldr	r1, [sp, #0x48]
	bne.n	.L0800ed5a
	ldrh	r0, [r7, #8]
	ldr	r1, [sp, #0x30]
	add	r0, r1
	sxth.w	r12, r0
	sxth	r1, r6
	cmp	r1, r12
	bgt.n	.L0800ed58
	add.w	r1, r9, r9, lsl #1
	ldrh.w	r1, [r5, r1, lsl #2]
	sxth.w	r2, r11
	add	r1, r11
	subs	r1, #1
	sxth	r1, r1
	cmp	r2, r1
	mov	r2, r6
	ble.n	.L0800ee00
	ldr	r6, [sp, #0x40]
	movw	r7, #0x1144
	ldr	r5, [sp, #0x38]
	mov	r2, r6
	movt	r7, #0x2000
	nop
.L0800edd0:
	adds	r1, r2, #1
	sxth	r1, r1
	cmp	r1, r12
	mov.w	r1, #0
	bgt.n	.L0800ed5a
	adds	r3, r2, #2
	sxth	r3, r3
	cmp	r3, r12
	bgt.n	.L0800ed5a
	adds	r3, r2, #3
	sxth	r3, r3
	cmp	r3, r12
	bgt.n	.L0800ed5a
	adds	r2, #4
	sxth	r2, r2
	cmp	r2, r12
	ble.n	.L0800edd0
	b.n	.L0800ed5a
	.short	0xbf00	@ padding
.L0800edf8:
	adds	r2, #1
	sxth	r2, r2
	cmp	r2, r12
	bgt.n	.L0800ee60
.L0800ee00:
	sxth	r3, r2
	mov	r6, r11
	b.n	.L0800ee10
	.short	0xbf00	@ padding
.L0800ee08:
	adds	r0, r6, #1
	sxth	r6, r0
	cmp	r6, r1
	bgt.n	.L0800edf8
.L0800ee10:
	ldrh.w	r5, [r10, #0]
	sxth	r7, r6
	cmp	r7, r5
	blt.n	.L0800ee08
	ldrh.w	r5, [r10, #0]
	ldrh.w	r4, [r10, #4]
	add	r5, r4
	cmp	r5, r7
	ble.n	.L0800ee08
	ldrh.w	r5, [r10, #2]
	cmp	r3, r5
	blt.n	.L0800ee08
	ldrh.w	r5, [r10, #2]
	ldrh.w	r4, [r10, #6]
	add	r5, r4
	cmp	r5, r3
	ble.n	.L0800ee08
	ldr.w	r5, [r10, #8]
	ldrh.w	r4, [r10, #0]
	subs	r7, r7, r4
	ldrh.w	r4, [r10, #2]
	ldrh.w	r0, [r10, #4]
	subs	r4, r3, r4
	mla	r0, r4, r0, r7
	movw	r4, #0x55f
	strh.w	r4, [r5, r0, lsl #1]
	b.n	.L0800ee08
.L0800ee60:
	movw	r7, #0x1144
	ldr	r5, [sp, #0x38]
	ldr	r6, [sp, #0x40]
	movs	r1, #0
	movt	r7, #0x2000
	b.n	.L0800ed5a
.L0800ee70:
	ldr	r0, [sp, #0x34]
	ldr	r1, [sp, #0x10]
	sub.w	r5, r0, r9
	add.w	r0, r9, r9, lsl #1
	add.w	r6, r1, r0, lsl #2
	ldr	r0, [sp, #0xc]
	add.w	r7, r0, r9, lsl #2
	nop
.L0800ee88:
	ldr	r1, [sp, #0x44]
	uxtb.w	r0, r8
	subs	r0, r1, r0
	ldr	r1, [sp, #0x48]
	ldr.w	r3, [r7, #4]!
	it	ne
	movne	r0, r1
	ldr	r1, [sp, #0x40]
	add.w	r9, r6, #0xc
	movw	r4, #0x1144
	str	r0, [sp, #4]
	sxth.w	r0, r11
	sxth	r1, r1
	mov	r2, r9
	movt	r4, #0x2000
	str	r4, [sp, #0]
	bl	blend_glyph_into_region_buffer
	ldrh	r0, [r6, #0xc]
	add.w	r8, r8, #1
	add	r11, r0
	subs	r5, #1
	mov	r6, r9
	bne.n	.L0800ee88
	ldr	r0, [sp, #0x28]
	ldr	r1, [sp, #0x1c]
	movw	r7, #0x1144
	ldr.w	r11, [sp, #0x2c]
	ldrd	r12, lr, [sp, #0x38]
	ldr	r6, [sp, #0x40]
	sub.w	r8, r1, r0
	movt	r7, #0x2000
	b.n	.L0800ecc0
.L0800eee2:
	mov.w	r8, #0
	movs	r1, #0
	movs	r3, #0
.L0800eeea:
	uxtb.w	r12, r3
	cmp	r12, r11
	str	r6, [sp, #0x40]
	bcs.w	.L0800f0e4
	uxth	r0, r1
	rsb.w	r0, r0, #0x42			@ value column 0xcc..0x10d (V1.2.0 0x5e from 0xb0)
	add.w	r0, r0, r0, lsr #31
	movs	r1, #0xcc
	add.w	r9, r1, r0, lsr #1
	ldr	r1, [sp, #0x18]
	lsls	r0, r1, #24
	and.w	r1, r1, #0x7f
	str	r1, [sp, #0x44]
	bmi.w	.L0800f08e
	ldr	r0, [sp, #0x40]
	movw	r4, #0x8350
	ldr	r7, [sp, #0x48]
	subs	r2, r0, #1
	sxth	r0, r0
	movt	r4, #0x2000
	movw	r11, #0x55f
	str	r2, [sp, #0x30]
	str	r0, [sp, #0x34]
	b.n	.L0800ef76
.L0800ef2e:
	ldr	r1, [sp, #0x48]
.L0800ef30:
	movs	r6, #0
.L0800ef32:
	ldr	r0, [sp, #0x3c]
	ldr	r5, [sp, #0x38]
	ldr.w	r3, [r0, r12, lsl #2]
	movw	r0, #0x1144
	mov	r7, r1
	add.w	r10, r12, r12, lsl #1
	movt	r0, #0x2000
	ldr	r1, [sp, #0x34]
	add.w	r2, r5, r10, lsl #2
	str	r0, [sp, #0]
	sxth.w	r0, r9
	str	r6, [sp, #4]
	bl	blend_glyph_into_region_buffer
	ldr	r3, [sp, #0x28]
	ldr	r1, [sp, #0x2c]
	adds	r3, #1
	ldrh.w	r0, [r5, r10, lsl #2]
	uxtb.w	r12, r3
	cmp	r12, r1
	ldr	r1, [sp, #0x44]
	add.w	r8, r8, #1
	add	r9, r0
	bcs.w	.L0800f0e4
.L0800ef76:
	uxtb.w	r0, r8
	cmp	r1, r0
	mov	r6, r7
	mov	r1, r7
	str	r3, [sp, #0x28]
	bne.n	.L0800ef32
	movw	r0, #0x1144
	movt	r0, #0x2000
	ldrh	r0, [r0, #8]
	ldr	r2, [sp, #0x30]
	add	r0, r2
	sxth.w	lr, r0
	ldr	r0, [sp, #0x34]
	cmp	r0, lr
	bgt.n	.L0800ef30
	ldr	r1, [sp, #0x38]
	add.w	r0, r12, r12, lsl #1
	ldrh.w	r0, [r1, r0, lsl #2]
	ldr	r3, [sp, #0x40]
	add	r0, r9
	subs	r0, #1
	sxth	r2, r0
	sxth.w	r0, r9
	cmp	r0, r2
	ble.n	.L0800efec
	ldr	r2, [sp, #0x40]
	ldr	r1, [sp, #0x48]
	nop
.L0800efbc:
	adds	r0, r2, #1
	sxth	r0, r0
	cmp	r0, lr
	mov.w	r6, #0
	bgt.n	.L0800ef32
	adds	r0, r2, #2
	sxth	r0, r0
	cmp	r0, lr
	bgt.n	.L0800ef32
	adds	r0, r2, #3
	sxth	r0, r0
	cmp	r0, lr
	bgt.n	.L0800ef32
	adds	r0, r2, #4
	sxth	r2, r0
	cmp	r2, lr
	ble.n	.L0800efbc
	b.n	.L0800ef32
	.short	0xbf00	@ padding
.L0800efe4:
	adds	r0, r3, #1
	sxth	r3, r0
	cmp	r3, lr
	bgt.n	.L0800ef2e
.L0800efec:
	sxth	r6, r3
	mov	r5, r9
	b.n	.L0800effc
	.short	0xbf00	@ padding
.L0800eff4:
	adds	r0, r5, #1
	sxth	r5, r0
	cmp	r5, r2
	bgt.n	.L0800efe4
.L0800effc:
	ldrh	r7, [r4, #0]
	sxth	r0, r5
	cmp	r0, r7
	blt.n	.L0800eff4
	ldrh	r7, [r4, #0]
	ldrh	r1, [r4, #4]
	add	r1, r7
	cmp	r1, r0
	ble.n	.L0800eff4
	ldrh	r1, [r4, #2]
	cmp	r6, r1
	blt.n	.L0800eff4
	ldrh	r1, [r4, #2]
	ldrh	r7, [r4, #6]
	add	r1, r7
	cmp	r1, r6
	ble.n	.L0800eff4
	ldr	r1, [r4, #8]
	ldrh	r7, [r4, #0]
	subs	r0, r0, r7
	ldrh	r7, [r4, #2]
	ldrh.w	r10, [r4, #4]
	subs	r7, r6, r7
	mla	r0, r7, r10, r0
	strh.w	r11, [r1, r0, lsl #1]
	b.n	.L0800eff4
.L0800f036:
	ldr	r0, [sp, #0x30]
	ldr.w	r8, [sp, #0x2c]
	ldrd	r10, r11, [sp, #0x38]
	sxth	r0, r0
	mov	r6, r3
	str	r0, [sp, #0x30]
	nop
.L0800f048:
	uxtb	r0, r2
	subs	r7, r1, r0
	ldr	r0, [sp, #0x48]
	ldr.w	r3, [r11, r12, lsl #2]
	it	ne
	movne	r7, r0
	movw	r0, #0x1144
	add.w	r4, r12, r12, lsl #1
	movt	r0, #0x2000
	ldr	r1, [sp, #0x30]
	mov	r5, r2
	add.w	r2, r10, r4, lsl #2
	str	r0, [sp, #0]
	sxth.w	r0, r9
	str	r7, [sp, #4]
	bl	blend_glyph_into_region_buffer
	ldrh.w	r0, [r10, r4, lsl #2]
	adds	r6, #1
	ldr	r1, [sp, #0x34]
	mov	r2, r5
	uxtb.w	r12, r6
	adds	r2, r5, #1
	cmp	r12, r8
	add	r9, r0
	bcc.n	.L0800f048
	b.n	.L0800f0e4
.L0800f08e:
	ldr	r0, [sp, #0x40]
	ldr.w	r10, [sp, #0x2c]
	ldrd	r11, r4, [sp, #0x38]
	sxth	r0, r0
	str	r0, [sp, #0x40]
.L0800f09c:
	uxtb.w	r0, r8
	subs	r7, r1, r0
	ldr	r0, [sp, #0x48]
	mov	r6, r3
	ldr.w	r3, [r4, r12, lsl #2]
	it	ne
	movne	r7, r0
	movw	r0, #0x1144
	add.w	r5, r12, r12, lsl #1
	movt	r0, #0x2000
	ldr	r1, [sp, #0x40]
	add.w	r2, r11, r5, lsl #2
	str	r0, [sp, #0]
	sxth.w	r0, r9
	str	r7, [sp, #4]
	bl	blend_glyph_into_region_buffer
	mov	r3, r6
	ldrh.w	r0, [r11, r5, lsl #2]
	adds	r3, r6, #1
	ldr	r1, [sp, #0x44]
	uxtb.w	r12, r3
	add.w	r8, r8, #1
	cmp	r12, r10
	add	r9, r0
	bcc.n	.L0800f09c
.L0800f0e4:
	movw	r4, #0x1070
	movt	r4, #0x2000
	ldrb	r0, [r4, #0x10]
	cbz	r0, .L0800f112
	ldr	r1, [r4, #8]
	ldr	r0, [sp, #0x38]
	subs	r0, r0, r1
	cmp.w	r0, #0x2bc00
	bcs.n	.L0800f130
	ldr	r2, [r4, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cbz	r1, .L0800f118
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	bl	zero_bytes
	b.n	.L0800f118
.L0800f112:
	ldr	r1, [r4, #0]
	movs	r0, #0
	blx	r1
.L0800f118:
	ldrb	r0, [r4, #0x10]
	cbz	r0, .L0800f124
	ldr	r0, [r4, #8]
	ldr	r1, [sp, #0x3c]
	subs	r0, r1, r0
	b.n	.L0800f134
.L0800f124:
	ldr	r1, [r4, #0]
	movs	r0, #0
	blx	r1
	add	sp, sp, #0x5c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0800f130:
	ldr	r0, [sp, #0x3c]
	subs	r0, r0, r1
.L0800f134:
	lsrs	r1, r0, #10
	cmp	r1, #0xae
	bhi.n	.L0800f14e
	ldr	r2, [r4, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cbz	r1, .L0800f14e
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	bl	zero_bytes
.L0800f14e:
	add	sp, sp, #0x5c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}

