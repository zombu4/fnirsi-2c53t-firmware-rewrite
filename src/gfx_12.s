@ gfx_12.s - graphics: wrapped text box drawing, glyph blending into the region buffer, a no-op stub, sub-pixel point blending and degree-based arc drawing.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ draw_wrapped_text_in_box - draws a text string word-wrapped inside a box.
@ Parameters: r0 = x, r1 = y, r2 = width, r3 = height.
@ Stack (caller's frame): [sp] = text pointer (read with decode_utf8_char,
@ 0803a40c), [sp+4] = font object (word 0 = metrics callback, [+4] = bitmap
@ callback used by blend_glyph_into_region_buffer 0800fb90, halfword [+8] =
@ line height), [sp+8] = colour, [sp+12] = flags. No return value.
@ First pass: counts characters until a 0, 0x0a or 0x0d code point or until the
@ metrics callback returns 0. Then allocates 4*n bytes and 12*n bytes with
@ alloc_units_of_32_bytes (0803acfc; returns at once if the first allocation
@ fails) and fills the code point array and the metric record array.
@ Word wrap inside the width: the counting pass backs up to a space (0x20,
@ .L0800f26c); a trailing space is dropped. The drawing passes break where the
@ width is reached, inside a word (on the meter, 2026-11-18: "Parameter M /
@ easurement", "previ / ous"): texts are chosen to fit their boxes.
@ Flags: bit 7 set = lines start at y with no vertical centring and the low
@ nibble selects the alignment (1 = centre each line horizontally, 2 = right
@ align, other = left). Bit 7 clear = the whole flags word is compared (== 1
@ centre, == 2 right align, any other value left) and the block is centred
@ vertically in the height when the lines fit (when they do not fit the first
@ line is at y).
@ Draws every glyph with blend_glyph_into_region_buffer(x, y, metric record,
@ code point, font object, colour).
@ At the end frees both arrays: callback (*[0x20001070])(0) if [0x20001080] == 0,
@ else zero_bytes (080082bc) on the entry range of the table at [0x2000107c]
@ when (blk - [0x20001078]) < 0x2bc00 respectively (blk - [0x20001078]) >> 10
@ < 0xaf.
@ ----------------------------------------------------------------------------
	.section .text.draw_wrapped_text_in_box,"ax",%progbits
	.global draw_wrapped_text_in_box
	.thumb_func
	.type draw_wrapped_text_in_box, %function
draw_wrapped_text_in_box:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x4c
	ldrd r9, r10, [sp, #0x70]
	movs r7, #0
	add r6, sp, #0x3c
	add r5, sp, #0x40
	mov.w r8, #1
	movw r11, #0x2401
	str r3, [sp, #0x1c]
	str r2, [sp, #0x28]
	str r1, [sp, #0x38]
	str r0, [sp, #0x30]
	str r7, [sp, #0x3c]
	nop
.L0800f178:
	mov r0, r9
	mov r1, r6
	bl decode_utf8_char
	mov r2, r0
	cmp r0, #0xd
	bhi.n .L0800f190
	lsl.w r0, r8, r2
	tst.w r0, r11
	bne.n .L0800f1a2
.L0800f190:
	ldr.w r4, [r10, #0]
	mov r0, r10
	mov r1, r5
	movs r3, #0
	blx r4
	cbz r0, .L0800f1a2
	adds r7, #1
	b.n .L0800f178
.L0800f1a2:
	uxth r4, r7
	lsls r0, r4, #2
	bl alloc_units_of_32_bytes
	cmp r0, #0
	beq.w .L0800f952
	mov r11, r0
	add.w r0, r4, r4, lsl #1
	lsls r0, r0, #2
	str r4, [sp, #0x2c]
	bl alloc_units_of_32_bytes
	movw r4, #0x1070
	cmp r0, #0
	movt r4, #0x2000
	beq.w .L0800f91a
	mov lr, r0
	movs r0, #0
	lsls.w r8, r7, #0x10
	str r0, [sp, #0x3c]
	str.w r11, [sp, #0x24]
	str.w lr, [sp, #0x34]
	beq.n .L0800f2a2
	ldr r6, [sp, #0x2c]
	sub.w r4, r11, #4
	add r5, sp, #0x3c
	mov r11, lr
	nop
.L0800f1ec:
	mov r0, r9
	mov r1, r5
	bl decode_utf8_char
	str.w r0, [r4, #4]!
	ldr.w r7, [r10, #0]
	mov r2, r0
	mov r0, r10
	mov r1, r11
	movs r3, #0
	blx r7
	subs r6, #1
	add.w r11, r11, #0xc
	bne.n .L0800f1ec
	ldr r2, [sp, #0x7c]
	add.w r1, r10, #8
	lsls r0, r2, #0x18
	bmi.n .L0800f2c6
	ldrh.w r9, [r1, #0]
	ldr.w r12, [sp, #0x2c]
	ldr.w lr, [sp, #0x34]
	ldrd r11, r4, [sp, #0x24]
	str r1, [sp, #0x20]
	movs r6, #0
	movs r2, #0
	movs r3, #0
	mov r1, r9
	movs r7, #0
	b.n .L0800f246
.L0800f236:
	mov r2, r3
.L0800f238:
	add r1, r9
	movs r7, #0
	movs r3, #0
.L0800f23e:
	adds r2, #1
	uxth r6, r2
	cmp r6, r12
	bcs.n .L0800f2d2
.L0800f246:
	add.w r5, r6, r6, lsl #1
	ldrh.w r5, [lr, r5, lsl #2]
	ldr.w r6, [r11, r6, lsl #2]
	uxtah r7, r5, r7
	cmp r6, #0x20
	uxth r5, r7
	it eq
	moveq r3, #1
	cmp r5, r4
	bls.n .L0800f23e
	cmp r6, #0x20
	beq.n .L0800f238
	lsls r3, r3, #0x18
	beq.n .L0800f29e
	nop
.L0800f26c:
	subs r3, r2, #1
	uxth r7, r3
	ldr.w r7, [r11, r7, lsl #2]
	cmp r7, #0x20
	beq.n .L0800f236
	subs r3, r2, #2
	uxth r7, r3
	ldr.w r7, [r11, r7, lsl #2]
	cmp r7, #0x20
	beq.n .L0800f236
	subs r3, r2, #3
	uxth r7, r3
	ldr.w r7, [r11, r7, lsl #2]
	cmp r7, #0x20
	beq.n .L0800f236
	subs r2, #4
	uxth r3, r2
	ldr.w r3, [r11, r3, lsl #2]
	cmp r3, #0x20
	bne.n .L0800f26c
	b.n .L0800f238
.L0800f29e:
	subs r2, #1
	b.n .L0800f238
.L0800f2a2:
	ldr r2, [sp, #0x7c]
	ldr r4, [sp, #0x28]
	lsls r0, r2, #0x18
	add.w r1, r10, #8
	bmi.n .L0800f31e
	ldrsh.w r0, [r1, #0]
	ldr r3, [sp, #0x1c]
	cmp r3, r0
	bge.w .L0800f6b0
	uxth.w r9, r0
	ldr.w r12, [sp, #0x2c]
	str r1, [sp, #0x20]
	b.n .L0800f752
.L0800f2c6:
	ldr r7, [sp, #0x2c]
	ldr.w lr, [sp, #0x34]
	ldrd r11, r4, [sp, #0x24]
	b.n .L0800f320
.L0800f2d2:
	ldr r3, [sp, #0x1c]
	sxth r1, r1
	cmp r3, r1
	bge.w .L0800f534
	cmp.w r8, #0
	beq.w .L0800f750
	movs r7, #0
	movs r2, #0
	mov r1, r9
	movs r3, #0
	b.n .L0800f2fa
	.short 0xbf00	@ padding (bytes 00 bf)
.L0800f2f0:
	adds r2, #1
	uxth r7, r2
	cmp r7, r12
	bcs.w .L0800f6aa
.L0800f2fa:
	add.w r6, r7, r7, lsl #1
	ldrh.w r6, [lr, r6, lsl #2]
	uxtah r3, r6, r3
	uxth r6, r3
	cmp r6, r4
	bls.n .L0800f2f0
	ldr.w r3, [r11, r7, lsl #2]
	add r1, r9
	cmp r3, #0x20
	mov.w r3, #0
	it ne
	subne r2, #1
	b.n .L0800f2f0
.L0800f31e:
	ldr r7, [sp, #0x2c]
.L0800f320:
	ldr.w r12, [sp, #0x38]
	and.w r0, r2, #0xf
	cmp r0, #1
	str r1, [sp, #0x20]
	bne.w .L0800f430
	sub.w r0, r11, #4
	str r0, [sp, #0x18]
	sub.w r0, lr, #0xc
	str r0, [sp, #0x14]
	movs r1, #0
	movs r0, #0
	movs r5, #0
	b.n .L0800f370
.L0800f344:
	ldr r0, [sp, #0x20]
	ldr.w r11, [sp, #0x24]
	ldrh r0, [r0, #0]
	ldr r5, [sp, #0x1c]
	ldr.w r1, [r11, r7, lsl #2]
	add r12, r0
	mov r0, r5
	cmp r1, #0x20
	it eq
	addeq r0, #1
	ldr.w lr, [sp, #0x34]
	ldrd r4, r7, [sp, #0x28]
	movs r1, #0
.L0800f366:
	adds r5, #1
	uxth r2, r5
	cmp r2, r7
	bhi.w .L0800f8e2
.L0800f370:
	uxth r2, r5
	cmp r2, r7
	bcs.n .L0800f380
	add.w r3, r2, r2, lsl #1
	ldrh.w r3, [lr, r3, lsl #2]
	add r1, r3
.L0800f380:
	cmp r2, r7
	beq.n .L0800f38a
	uxth r3, r1
	cmp r3, r4
	bls.n .L0800f366
.L0800f38a:
	uxth r3, r1
	cmp r3, r4
	bls.n .L0800f3bc
	add.w r2, r2, r2, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	lsls r3, r5, #0x10
	sub.w r1, r1, r2
	beq.n .L0800f3b8
	subs r5, #1
	uxth r2, r5
	ldr.w r3, [r11, r2, lsl #2]
	cmp r3, #0x20
	bne.n .L0800f3bc
	add.w r2, r2, r2, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	subs r1, r1, r2
	b.n .L0800f3bc
.L0800f3b8:
	movs r5, #0
	nop
.L0800f3bc:
	uxth r7, r5
	uxth r2, r0
	ldrd r11, lr, [sp, #0x74]
	cmp r2, r7
	str r5, [sp, #0x1c]
	bcs.n .L0800f344
	ldr r3, [sp, #0x28]
	uxth r1, r1
	subs r1, r3, r1
	ldr r3, [sp, #0x30]
	add.w r1, r1, r1, lsr #31
	add.w r6, r3, r1, lsr #1
	movs r1, #1
	uxtah r9, r1, r0
	ldr r1, [sp, #0x18]
	add.w r4, r1, r2, lsl #2
	lsls r1, r2, #1
	uxtah r0, r1, r0
	ldr r1, [sp, #0x14]
	add.w r5, r1, r0, lsl #2
	nop
.L0800f3f4:
	ldr.w r3, [r4, #4]!
	add.w r2, r5, #0xc
	sxth r0, r6
	sxth.w r1, r12
	str r2, [sp, #0x38]
	str.w r11, [sp, #0]
	str.w lr, [sp, #4]
	mov r8, r11
	mov r10, r12
	mov r11, lr
	bl blend_glyph_into_region_buffer
	ldrh r0, [r5, #0xc]
	ldr r5, [sp, #0x38]
	add r6, r0
	uxth.w r0, r9
	mov lr, r11
	mov r12, r10
	mov r11, r8
	add.w r9, r9, #1
	cmp r7, r0
	bne.n .L0800f3f4
	b.n .L0800f344
.L0800f430:
	str r0, [sp, #0x18]
	ldr r0, [sp, #0x30]
	movs r1, #0
	add r0, r4
	str r0, [sp, #0x14]
	sub.w r0, r11, #4
	str r0, [sp, #0x10]
	sub.w r0, lr, #0xc
	str r0, [sp, #0xc]
	movs r0, #0
	movs r5, #0
	b.n .L0800f478
.L0800f44c:
	ldr r0, [sp, #0x20]
	ldr.w r11, [sp, #0x24]
	ldrh r0, [r0, #0]
	ldr r5, [sp, #0x1c]
	ldr.w r1, [r11, r7, lsl #2]
	add r12, r0
	mov r0, r5
	cmp r1, #0x20
	it eq
	addeq r0, #1
	ldr.w lr, [sp, #0x34]
	ldrd r4, r7, [sp, #0x28]
	movs r1, #0
.L0800f46e:
	adds r5, #1
	uxth r2, r5
	cmp r2, r7
	bhi.w .L0800f8e2
.L0800f478:
	uxth r2, r5
	cmp r2, r7
	bcs.n .L0800f488
	add.w r3, r2, r2, lsl #1
	ldrh.w r3, [lr, r3, lsl #2]
	add r1, r3
.L0800f488:
	cmp r2, r7
	beq.n .L0800f492
	uxth r3, r1
	cmp r3, r4
	bls.n .L0800f46e
.L0800f492:
	uxth r3, r1
	cmp r3, r4
	bls.n .L0800f4c4
	add.w r2, r2, r2, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	lsls r3, r5, #0x10
	sub.w r1, r1, r2
	beq.n .L0800f4c0
	subs r5, #1
	uxth r2, r5
	ldr.w r3, [r11, r2, lsl #2]
	cmp r3, #0x20
	bne.n .L0800f4c4
	add.w r2, r2, r2, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	subs r1, r1, r2
	b.n .L0800f4c4
.L0800f4c0:
	movs r5, #0
	nop
.L0800f4c4:
	uxth r7, r5
	uxth r2, r0
	ldrd r11, lr, [sp, #0x74]
	cmp r2, r7
	str r5, [sp, #0x1c]
	bcs.n .L0800f44c
	ldr r3, [sp, #0x18]
	ldr r6, [sp, #0x30]
	cmp r3, #2
	ldr r3, [sp, #0x14]
	it eq
	subeq r6, r3, r1
	movs r1, #1
	uxtah r9, r1, r0
	ldr r1, [sp, #0x10]
	add.w r4, r1, r2, lsl #2
	lsls r1, r2, #1
	uxtah r0, r1, r0
	ldr r1, [sp, #0xc]
	add.w r5, r1, r0, lsl #2
	nop
.L0800f4f8:
	ldr.w r3, [r4, #4]!
	add.w r2, r5, #0xc
	sxth r0, r6
	sxth.w r1, r12
	str r2, [sp, #0x38]
	str.w r11, [sp, #0]
	str.w lr, [sp, #4]
	mov r8, r11
	mov r10, r12
	mov r11, lr
	bl blend_glyph_into_region_buffer
	ldrh r0, [r5, #0xc]
	ldr r5, [sp, #0x38]
	add r6, r0
	uxth.w r0, r9
	mov lr, r11
	mov r12, r10
	mov r11, r8
	add.w r9, r9, #1
	cmp r7, r0
	bne.n .L0800f4f8
	b.n .L0800f44c
.L0800f534:
	subs r1, r3, r1
	ldr r0, [sp, #0x38]
	add.w r1, r1, r1, lsr #31
	cmp.w r8, #0
	add.w r8, r0, r1, lsr #1
	beq.w .L0800f6c0
	ldr r0, [sp, #0x7c]
	ldr.w r10, [sp, #0x78]
	cmp r0, #1
	str.w r9, [sp, #0x38]
	bne.w .L0800fa48
	movs r3, #0
	mov.w r9, #0
	movs r2, #0
	movs r5, #0
	movs r1, #0
	b.n .L0800f584
	.short 0xbf00	@ padding (bytes 00 bf)
.L0800f568:
	ldr r0, [sp, #0x38]
	add.w r9, r9, #1
	add r8, r0
	movs r1, #0
	mov r5, r9
	movs r2, #0
.L0800f576:
	ldr.w r12, [sp, #0x2c]
	uxth.w r3, r9
	cmp r3, r12
	bcs.w .L0800f6c4
.L0800f584:
	ldr r0, [sp, #0x24]
	add.w r6, r3, r3, lsl #1
	ldrh.w r6, [lr, r6, lsl #2]
	ldr.w r3, [r0, r3, lsl #2]
	add r6, r1
	cmp r3, #0x20
	it eq
	moveq r2, #1
	ldr r7, [sp, #0x28]
	uxth r4, r6
	cmp r4, r7
	bls.n .L0800f628
	cmp r3, #0x20
	beq.n .L0800f63c
	lsls r2, r2, #0x18
	sub.w r9, r9, #1
	beq.n .L0800f63c
	uxth.w r2, r9
	ldr.w r3, [r0, r2, lsl #2]
	cmp r3, #0x20
	beq.n .L0800f632
	nop
.L0800f5bc:
	sub.w r3, r9, #1
	add.w r6, r2, r2, lsl #1
	uxth r2, r3
	ldr.w r4, [r0, r2, lsl #2]
	ldrh.w r6, [lr, r6, lsl #2]
	cmp r4, #0x20
	sub.w r1, r1, r6
	beq.n .L0800f630
	sub.w r3, r9, #2
	add.w r7, r2, r2, lsl #1
	uxth r2, r3
	ldr.w r6, [r0, r2, lsl #2]
	ldrh.w r7, [lr, r7, lsl #2]
	cmp r6, #0x20
	sub.w r1, r1, r7
	beq.n .L0800f630
	sub.w r3, r9, #3
	add.w r7, r2, r2, lsl #1
	uxth r2, r3
	ldr.w r6, [r0, r2, lsl #2]
	ldrh.w r7, [lr, r7, lsl #2]
	cmp r6, #0x20
	sub.w r1, r1, r7
	beq.n .L0800f630
	sub.w r9, r9, #4
	add.w r3, r2, r2, lsl #1
	uxth.w r2, r9
	ldr.w r7, [r0, r2, lsl #2]
	ldrh.w r3, [lr, r3, lsl #2]
	cmp r7, #0x20
	sub.w r1, r1, r3
	bne.n .L0800f5bc
	b.n .L0800f632
.L0800f628:
	add.w r9, r9, #1
	mov r1, r6
	b.n .L0800f576
.L0800f630:
	mov r9, r3
.L0800f632:
	add.w r2, r2, r2, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	subs r1, r1, r2
.L0800f63c:
	uxth r2, r5
	uxth.w r10, r9
	cmp r10, r2
	bcc.n .L0800f568
	uxth r0, r1
	ldr r1, [sp, #0x28]
	str.w r9, [sp, #0x1c]
	subs r0, r1, r0
	ldr r1, [sp, #0x30]
	add.w r0, r0, r0, lsr #31
	ldr.w r11, [sp, #0x74]
	ldr r6, [sp, #0x24]
	mov r9, r8
	ldr.w r8, [sp, #0x78]
	add.w r4, r1, r0, lsr #1
	nop
.L0800f668:
	uxth r0, r5
	lsls r1, r0, #1
	uxtah r7, r1, r5
	ldr.w r3, [r6, r0, lsl #2]
	add.w r2, lr, r7, lsl #2
	sxth r0, r4
	sxth.w r1, r9
	str.w r11, [sp, #0]
	str.w r8, [sp, #4]
	bl blend_glyph_into_region_buffer
	ldr.w lr, [sp, #0x34]
	adds r5, #1
	ldrh.w r0, [lr, r7, lsl #2]
	uxth r1, r5
	cmp r10, r1
	add r4, r0
	bcs.n .L0800f668
	ldr r0, [sp, #0x20]
	mov r8, r9
	ldrh r0, [r0, #0]
	ldr.w r9, [sp, #0x1c]
	str r0, [sp, #0x38]
	b.n .L0800f568
.L0800f6aa:
	ldr r2, [sp, #0x7c]
	ldr r3, [sp, #0x1c]
	b.n .L0800f754
.L0800f6b0:
	subs r0, r3, r0
	ldr r1, [sp, #0x38]
	add.w r0, r0, r0, lsr #31
	ldr.w r12, [sp, #0x2c]
	add.w r8, r1, r0, lsr #1
.L0800f6c0:
	movs r1, #0
	movs r5, #0
.L0800f6c4:
	ldr r0, [sp, #0x7c]
	cmp r0, #1
	beq.n .L0800f6dc
	ldrd r11, r2, [sp, #0x24]
	cmp r0, #2
	bne.n .L0800f6f2
	ldr r0, [sp, #0x30]
	add r0, r2
	subs r0, r0, r1
	str r0, [sp, #0x30]
	b.n .L0800f6f2
.L0800f6dc:
	uxth r0, r1
	ldr r1, [sp, #0x28]
	ldr.w r11, [sp, #0x24]
	subs r0, r1, r0
	ldr r1, [sp, #0x30]
	add.w r0, r0, r0, lsr #31
	add.w r1, r1, r0, lsr #1
	str r1, [sp, #0x30]
.L0800f6f2:
	uxth r0, r5
	cmp r0, r12
	bcs.w .L0800f8e2
	movs r1, #1
	uxtah r6, r1, r5
	add.w r1, r11, r0, lsl #2
	lsls r0, r0, #1
	uxtah r0, r0, r5
	add.w r0, lr, r0, lsl #2
	sub.w r10, r1, #4
	sub.w r5, r0, #0xc
	sxth.w r8, r8
	nop
.L0800f71c:
	ldr r0, [sp, #0x74]
	ldr r4, [sp, #0x30]
	ldr.w r3, [r10, #4]!
	add.w r9, r5, #0xc
	ldr r7, [sp, #0x78]
	str r0, [sp, #0]
	sxth r0, r4
	mov r1, r8
	mov r2, r9
	str r7, [sp, #4]
	bl blend_glyph_into_region_buffer
	ldrh r0, [r5, #0xc]
	ldr r1, [sp, #0x2c]
	ldr.w lr, [sp, #0x34]
	add r4, r0
	uxth r0, r6
	adds r6, #1
	cmp r1, r0
	mov r5, r9
	str r4, [sp, #0x30]
	bne.n .L0800f71c
	b.n .L0800f8e2
.L0800f750:
	ldr r2, [sp, #0x7c]
.L0800f752:
	mov r1, r9
.L0800f754:
	sxth r1, r1
	subs r1, r3, r1
	ldr r0, [sp, #0x38]
	add.w r1, r1, r1, lsr #31
	it gt
	addgt.w r0, r0, r1, lsr #1
	cmp.w r8, #0
	str r0, [sp, #0x38]
	beq.n .L0800f860
	cmp r2, #1
	bne.w .L0800f958
	sub.w r0, r11, #4
	str r0, [sp, #0x14]
	sub.w r0, lr, #0xc
	str r0, [sp, #0x10]
	movs r0, #0
	movs r5, #0
	movs r1, #0
	movs r3, #0
	b.n .L0800f7b4
.L0800f788:
	ldr.w r1, [r11, r0, lsl #2]
	ldr r0, [sp, #0x38]
	subs.w r2, r1, #0x20
	add r0, r9
	str r0, [sp, #0x38]
	it ne
	movne r2, #1
	cmp r1, #0x20
	sub.w r3, r5, r2
	it eq
	addeq r5, #1
	movs r2, #0
	mov r1, r5
	mov r5, r3
.L0800f7aa:
	adds r5, #1
	uxth r0, r5
	cmp r0, r12
	mov r3, r2
	bcs.n .L0800f864
.L0800f7b4:
	add.w r2, r0, r0, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	add r2, r3
	uxth r7, r2
	cmp r7, r4
	bls.n .L0800f7aa
	lsls r2, r5, #0x10
	beq.n .L0800f7dc
	subs r2, r0, #1
	ldr.w r7, [r11, r2, lsl #2]
	cmp r7, #0x20
	bne.n .L0800f7dc
	add.w r2, r2, r2, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	subs r3, r3, r2
.L0800f7dc:
	uxth r6, r5
	uxth r2, r1
	cmp r2, r6
	bcs.n .L0800f788
	strd r0, r5, [sp, #0x18]
	uxth r0, r3
	subs r0, r4, r0
	ldr r3, [sp, #0x30]
	add.w r0, r0, r0, lsr #31
	add.w r7, r3, r0, lsr #1
	movs r0, #1
	uxtah r8, r0, r1
	ldr r0, [sp, #0x14]
	mov r11, r10
	add.w r4, r0, r2, lsl #2
	lsls r0, r2, #1
	uxtah r0, r0, r1
	ldr r1, [sp, #0x10]
	ldr.w r10, [sp, #0x38]
	add.w r5, r1, r0, lsl #2
.L0800f814:
	ldr.w r3, [r4, #4]!
	add.w r9, r5, #0xc
	mov r12, r6
	ldr r6, [sp, #0x78]
	sxth r0, r7
	sxth.w r1, r10
	mov r2, r9
	str.w r11, [sp, #0]
	str r6, [sp, #4]
	mov r6, r12
	bl blend_glyph_into_region_buffer
	ldrh r0, [r5, #0xc]
	mov r5, r9
	add r7, r0
	uxth.w r0, r8
	add.w r8, r8, #1
	cmp r6, r0
	bne.n .L0800f814
	ldr r0, [sp, #0x20]
	mov r10, r11
	ldrh.w r9, [r0, #0]
	ldr.w r12, [sp, #0x2c]
	ldr.w lr, [sp, #0x34]
	ldrd r11, r4, [sp, #0x24]
	ldrd r0, r5, [sp, #0x18]
	b.n .L0800f788
.L0800f860:
	movs r2, #0
	movs r1, #0
.L0800f864:
	ldr r0, [sp, #0x7c]
	cmp r0, #1
	beq.n .L0800f878
	cmp r0, #2
	bne.n .L0800f888
	ldr r0, [sp, #0x30]
	add r0, r4
	subs r0, r0, r2
	str r0, [sp, #0x30]
	b.n .L0800f888
.L0800f878:
	uxth r0, r2
	subs r0, r4, r0
	ldr r2, [sp, #0x30]
	add.w r0, r0, r0, lsr #31
	add.w r2, r2, r0, lsr #1
	str r2, [sp, #0x30]
.L0800f888:
	uxth r0, r1
	ldr r3, [sp, #0x38]
	cmp r0, r12
	bcs.n .L0800f8e2
	movs r2, #1
	uxtah r6, r2, r1
	add.w r2, r11, r0, lsl #2
	lsls r0, r0, #1
	uxtah r0, r0, r1
	add.w r0, lr, r0, lsl #2
	sub.w r10, r2, #4
	sub.w r5, r0, #0xc
	sxth.w r8, r3
.L0800f8b0:
	ldr r0, [sp, #0x74]
	ldr r4, [sp, #0x30]
	ldr.w r3, [r10, #4]!
	add.w r9, r5, #0xc
	ldr r7, [sp, #0x78]
	str r0, [sp, #0]
	sxth r0, r4
	mov r1, r8
	mov r2, r9
	str r7, [sp, #4]
	bl blend_glyph_into_region_buffer
	ldrh r0, [r5, #0xc]
	ldr r1, [sp, #0x2c]
	ldr.w lr, [sp, #0x34]
	add r4, r0
	uxth r0, r6
	adds r6, #1
	cmp r1, r0
	mov r5, r9
	str r4, [sp, #0x30]
	bne.n .L0800f8b0
.L0800f8e2:
	movw r2, #0x1070
	movt r2, #0x2000
	ldrb r0, [r2, #0x10]
	cbz r0, .L0800f912
	ldr r1, [r2, #8]
	sub.w r0, lr, r1
	cmp.w r0, #0x2bc00
	bcs.n .L0800f934
	mov r4, r2
	ldr r2, [r2, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800f91a
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800f91a
.L0800f912:
	ldr r1, [r2, #0]
	movs r0, #0
	mov r4, r2
	blx r1
.L0800f91a:
	ldrb r0, [r4, #0x10]
	mov r2, r4
	cbz r0, .L0800f928
	ldr r0, [r2, #8]
	sub.w r0, r11, r0
	b.n .L0800f938
.L0800f928:
	ldr r1, [r2, #0]
	movs r0, #0
	blx r1
	add sp, #0x4c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0800f934:
	sub.w r0, r11, r1
.L0800f938:
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800f952
	ldr r2, [r2, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800f952
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L0800f952:
	add sp, #0x4c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0800f958:
	ldr r1, [sp, #0x30]
	movs r5, #0
	adds r0, r4, r1
	str r0, [sp, #0x14]
	sub.w r0, r11, #4
	str r0, [sp, #0x10]
	sub.w r0, lr, #0xc
	str r0, [sp, #0xc]
	movs r0, #0
	movs r1, #0
	movs r3, #0
	b.n .L0800f9a2
.L0800f974:
	ldr.w r1, [r11, r0, lsl #2]
	ldr r0, [sp, #0x38]
	subs.w r2, r1, #0x20
	add r0, r9
	str r0, [sp, #0x38]
	it ne
	movne r2, #1
	cmp r1, #0x20
	sub.w r3, r5, r2
	it eq
	addeq r5, #1
	movs r2, #0
	mov r1, r5
	mov r5, r3
.L0800f996:
	adds r5, #1
	uxth r0, r5
	cmp r0, r12
	mov r3, r2
	bcs.w .L0800f864
.L0800f9a2:
	add.w r2, r0, r0, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	add r2, r3
	uxth r7, r2
	cmp r7, r4
	bls.n .L0800f996
	lsls r2, r5, #0x10
	beq.n .L0800f9ca
	subs r2, r0, #1
	ldr.w r7, [r11, r2, lsl #2]
	cmp r7, #0x20
	bne.n .L0800f9ca
	add.w r2, r2, r2, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	subs r3, r3, r2
.L0800f9ca:
	uxth r6, r5
	uxth r2, r1
	cmp r2, r6
	bcs.n .L0800f974
	strd r0, r5, [sp, #0x18]
	ldr r0, [sp, #0x7c]
	ldr r7, [sp, #0x30]
	cmp r0, #2
	ldr r0, [sp, #0x14]
	it eq
	subeq r7, r0, r3
	movs r0, #1
	uxtah r4, r0, r1
	ldr r0, [sp, #0x10]
	mov r9, r10
	add.w r8, r0, r2, lsl #2
	lsls r0, r2, #1
	uxtah r0, r0, r1
	ldr r1, [sp, #0xc]
	ldr.w r10, [sp, #0x38]
	add.w r5, r1, r0, lsl #2
.L0800fa00:
	ldr.w r3, [r8, #4]!
	add.w r11, r5, #0xc
	mov r12, r6
	ldr r6, [sp, #0x78]
	sxth r0, r7
	sxth.w r1, r10
	mov r2, r11
	str.w r9, [sp, #0]
	str r6, [sp, #4]
	mov r6, r12
	bl blend_glyph_into_region_buffer
	ldrh r0, [r5, #0xc]
	mov r5, r11
	add r7, r0
	uxth r0, r4
	adds r4, #1
	cmp r6, r0
	bne.n .L0800fa00
	ldr r0, [sp, #0x20]
	mov r10, r9
	ldrh r0, [r0, #0]
	ldr.w r12, [sp, #0x2c]
	mov r9, r0
	ldr.w lr, [sp, #0x34]
	ldrd r11, r4, [sp, #0x24]
	ldrd r0, r5, [sp, #0x18]
	b.n .L0800f974
.L0800fa48:
	ldr r1, [sp, #0x30]
	movs r3, #0
	adds r0, r4, r1
	movs r4, #0
	movs r2, #0
	movs r5, #0
	movs r1, #0
	str r0, [sp, #0x1c]
	b.n .L0800fa68
	.short 0xbf00	@ padding (bytes 00 bf)
.L0800fa5c:
	adds r4, #1
	mov r1, r7
.L0800fa60:
	uxth r3, r4
	cmp r3, r12
	bcs.w .L0800f6c4
.L0800fa68:
	ldr r0, [sp, #0x24]
	add.w r7, r3, r3, lsl #1
	ldrh.w r7, [lr, r7, lsl #2]
	ldr.w r3, [r0, r3, lsl #2]
	add r7, r1
	cmp r3, #0x20
	it eq
	moveq r2, #1
	ldr r0, [sp, #0x28]
	uxth r6, r7
	cmp r6, r0
	bls.n .L0800fa5c
	cmp r3, #0x20
	beq.n .L0800fb08
	lsls r2, r2, #0x18
	sub.w r4, r4, #1
	beq.n .L0800fb08
	ldr r0, [sp, #0x24]
	uxth r2, r4
	ldr.w r3, [r0, r2, lsl #2]
	ldr.w r9, [sp, #0x38]
	cmp r3, #0x20
	beq.n .L0800fb10
	nop
.L0800faa4:
	subs r3, r4, #1
	add.w r7, r2, r2, lsl #1
	uxth r2, r3
	ldr.w r6, [r0, r2, lsl #2]
	ldrh.w r7, [lr, r7, lsl #2]
	cmp r6, #0x20
	sub.w r1, r1, r7
	beq.n .L0800fb0e
	subs r3, r4, #2
	add.w r7, r2, r2, lsl #1
	uxth r2, r3
	ldr.w r6, [r0, r2, lsl #2]
	ldrh.w r7, [lr, r7, lsl #2]
	cmp r6, #0x20
	sub.w r1, r1, r7
	beq.n .L0800fb0e
	subs r3, r4, #3
	add.w r7, r2, r2, lsl #1
	uxth r2, r3
	ldr.w r6, [r0, r2, lsl #2]
	ldrh.w r7, [lr, r7, lsl #2]
	cmp r6, #0x20
	sub.w r1, r1, r7
	beq.n .L0800fb0e
	subs r4, #4
	add.w r3, r2, r2, lsl #1
	uxth r2, r4
	ldr.w r7, [r0, r2, lsl #2]
	ldrh.w r3, [lr, r3, lsl #2]
	cmp r7, #0x20
	sub.w r1, r1, r3
	bne.n .L0800faa4
	b.n .L0800fb10
	.short 0xbf00	@ padding (bytes 00 bf)
.L0800fb08:
	ldr.w r9, [sp, #0x38]
	b.n .L0800fb1a
.L0800fb0e:
	mov r4, r3
.L0800fb10:
	add.w r2, r2, r2, lsl #1
	ldrh.w r2, [lr, r2, lsl #2]
	subs r1, r1, r2
.L0800fb1a:
	uxth r2, r5
	uxth r6, r4
	cmp r6, r2
	bcc.n .L0800fb80
	ldr r0, [sp, #0x7c]
	ldr r7, [sp, #0x30]
	str r4, [sp, #0x38]
	cmp r0, #2
	ldr r0, [sp, #0x1c]
	it eq
	subeq r7, r0, r1
	ldr.w r9, [sp, #0x74]
	mov r11, r8
	mov r8, r10
	ldr.w r10, [sp, #0x24]
.L0800fb3c:
	uxth r0, r5
	lsls r1, r0, #1
	uxtah r4, r1, r5
	ldr.w r3, [r10, r0, lsl #2]
	add.w r2, lr, r4, lsl #2
	sxth r0, r7
	sxth.w r1, r11
	str.w r9, [sp, #0]
	str.w r8, [sp, #4]
	bl blend_glyph_into_region_buffer
	ldr.w lr, [sp, #0x34]
	adds r5, #1
	ldrh.w r0, [lr, r4, lsl #2]
	uxth r1, r5
	cmp r6, r1
	add r7, r0
	bcs.n .L0800fb3c
	ldr r0, [sp, #0x20]
	ldr.w r12, [sp, #0x2c]
	ldrh.w r9, [r0, #0]
	ldr r4, [sp, #0x38]
	mov r10, r8
	mov r8, r11
.L0800fb80:
	adds r4, #1
	str.w r9, [sp, #0x38]
	add r8, r9
	movs r1, #0
	mov r5, r4
	movs r2, #0
	b.n .L0800fa60

@ ----------------------------------------------------------------------------
@ blend_glyph_into_region_buffer - draws one glyph bitmap into the region buffer.
@ Parameters: r0 = x, r1 = y (halfwords), r2 = metric record (halfword [+2] =
@ width, [+4] = height, [+6] = x offset, [+8] = baseline, byte [+10] = bits
@ per pixel), r3 = glyph key. Stack: [sp] = font object, [sp+4] = colour. No
@ return value.
@ Gets the bitmap pointer from the callback at [font+4](font, key). Rows run
@ from y + [font+8] - [r2+8] - [r2+4] for [r2+4] rows, columns from
@ x + [r2+6]/2 + ([r2+6] & 1) for [r2+2] columns.
@ Each pixel takes bpp bits (MSB first) from the bitmap (a new byte after 8
@ bits, a row ends on a byte boundary). Coverage = value / (2^bpp - 1) * 255
@ (VFP): below 16 keeps the buffer pixel, above 240 writes the colour,
@ otherwise blends RGB565 with
@ ((bg & 0xf81f) + (((fg & 0xfffff81f) - (bg & 0xf81f)) * (cov >> 2) >> 6)
@ & 0xf81f) + ((bg & 0x7e0) + (((fg & 0x7e0) - (bg & 0x7e0)) * cov >> 8)
@ & 0x7e0).
@ Reads and writes only inside the region record [0x20008350..56] of the
@ region buffer [0x20008358].
@ ----------------------------------------------------------------------------
	.section .text.blend_glyph_into_region_buffer,"ax",%progbits
	.global blend_glyph_into_region_buffer
	.thumb_func
	.type blend_glyph_into_region_buffer, %function
blend_glyph_into_region_buffer:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x14
	ldr	r4, [sp, #0x3c]			@ this rewrite: white text (colour 0xFFFF) is drawn in the
	uxth	r4, r4				@ halfword text_colour, or in TEXT_WARM when that is 0 (owner,
	movw	r5, #0xFFFF			@ 2026-11-18: pure white smears on this LCD; TEXT_COLOUR,
	cmp	r4, r5				@ src/usb_remote.s); every text routine draws its glyphs here
	bne	1f
	movw	r5, #:lower16:text_colour
	movt	r5, #:upper16:text_colour
	ldrh	r5, [r5]
	cbnz	r5, 2f
	movw	r5, #0xFF9A			@ TEXT_WARM: RGB 255 / 240 / 215 in RGB565
2:	str	r5, [sp, #0x3c]
	nop					@ 32 bytes added: the vldr literals below stay word-aligned
1:	ldr r6, [sp, #0x38]
	mov r4, r2
	ldr r2, [r6, #4]
	mov r7, r1
	mov r5, r0
	mov r0, r6
	mov r1, r3
	blx r2
	ldrh r1, [r6, #8]
	ldrh r2, [r4, #8]
	add r1, r7
	subs r1, r1, r2
	ldrh r2, [r4, #4]
	sxth r3, r1
	subs r1, r1, r2
	sxth.w r8, r1
	cmp r8, r3
	str r3, [sp, #8]
	bge.w .L0800fd2a
	ldrh r1, [r4, #6]
	ldrh r2, [r4, #2]
	add.w r3, r1, r1, lsr #15
	sxth r3, r3
	add.w r3, r5, r3, asr #1
	and.w r1, r1, #1
	add r2, r3
	add r2, r1
	add r1, r3
	sxth.w r10, r2
	sxth r1, r1
	cmp r1, r10
	str r1, [sp, #4]
	bge.w .L0800fd2a
	ldrb.w r11, [r4, #0xa]
	movs r1, #0xff
	lsl.w r1, r1, r11
	ldr r2, [sp, #0x3c]
	mvns r1, r1
	uxtb r1, r1
	vmov s0, r1
	bic.w r1, r2, #0x7e0
	movw r6, #0x8350
	vldr s2, .L0800fd30
	vcvt.f32.s32 s0, s0
	str r1, [sp, #0x10]
	and.w r1, r2, #0x7e0
	rsb.w r9, r11, #8
	movt r6, #0x2000
	str r1, [sp, #0xc]
	b.n .L0800fc2e
.L0800fc1c:
	lsls r1, r4, #0x18
	it ne
	addne r0, #1
	ldr r1, [sp, #8]
	add.w r8, r8, #1
	cmp r8, r1
	beq.w .L0800fd2a
.L0800fc2e:
	ldr r7, [sp, #4]
	movs r4, #0
	b.n .L0800fc48
.L0800fc34:
	add r4, r11
	uxtb r1, r4
	cmp r1, #7
	add.w r7, r7, #1
	itt hi
	movhi r4, #0
	addhi r0, #1
	cmp r10, r7
	beq.n .L0800fc1c
.L0800fc48:
	ldrb.w r12, [r0, #0]
	ldrh r2, [r6, #0]
	cmp r7, r2
	blt.n .L0800fc90
	ldrh r2, [r6, #0]
	ldrh r3, [r6, #4]
	add r2, r3
	cmp r2, r7
	ble.n .L0800fc90
	ldrh r2, [r6, #2]
	cmp r8, r2
	blt.n .L0800fc90
	ldrh r2, [r6, #2]
	ldrh r3, [r6, #6]
	add r2, r3
	cmp r2, r8
	ble.n .L0800fc90
	ldr.w lr, [r6, #8]
	ldrh r3, [r6, #0]
	ldrh r2, [r6, #2]
	mov r1, r10
	ldrh.w r10, [r6, #4]
	sub.w r2, r8, r2
	mul r2, r2, r10
	subs r2, r2, r3
	add r2, r7
	ldrh.w lr, [lr, r2, lsl #1]
	mov r10, r1
	b.n .L0800fc94
	.short 0xbf00	@ padding (bytes 00 bf)
.L0800fc90:
	mov.w lr, #0
.L0800fc94:
	uxtb r2, r4
	lsl.w r2, r12, r2
	uxtb r2, r2
	lsr.w r2, r2, r9
	vmov s4, r2
	vcvt.f32.u32 s4, s4
	vdiv.f32 s4, s4, s0
	vmul.f32 s4, s4, s2
	vcvt.s32.f32 s4, s4
	vmov r2, s4
	cmp r2, #0x10
	bcs.n .L0800fcc0
	mov r3, lr
	b.n .L0800fcf0
.L0800fcc0:
	ldr r3, [sp, #0x3c]
	cmp r2, #0xf0
	bhi.n .L0800fcf0
	ldr r1, [sp, #0x10]
	bic.w r3, lr, #0x7e0
	subs r5, r1, r3
	lsrs r1, r2, #2
	muls r1, r5, r1
	ldr r5, [sp, #0xc]
	add.w r1, r3, r1, lsr #6
	and.w r3, lr, #0x7e0
	subs r5, r5, r3
	muls r2, r5, r2
	add.w r2, r3, r2, lsr #8
	movw r3, #0xf81f
	ands r1, r3
	and.w r2, r2, #0x7e0
	adds r3, r1, r2
.L0800fcf0:
	ldrh r1, [r6, #0]
	cmp r7, r1
	blt.n .L0800fc34
	ldrh r1, [r6, #0]
	ldrh r2, [r6, #4]
	add r1, r2
	cmp r1, r7
	ble.n .L0800fc34
	ldrh r1, [r6, #2]
	cmp r8, r1
	blt.n .L0800fc34
	ldrh r1, [r6, #2]
	ldrh r2, [r6, #6]
	add r1, r2
	cmp r1, r8
	ble.n .L0800fc34
	ldr.w r12, [r6, #8]
	ldrh r2, [r6, #0]
	ldrh r5, [r6, #2]
	ldrh r1, [r6, #4]
	sub.w r5, r8, r5
	muls r1, r5, r1
	subs r1, r1, r2
	add r1, r7
	strh.w r3, [r12, r1, lsl #1]
	b.n .L0800fc34
.L0800fd2a:
	add sp, #0x14
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0800fd30:
	.word 0x437f0000	@ 255.0f

@ ----------------------------------------------------------------------------
@ return_void_2 - empty function: no parameters, no return value. Its only
@ instruction is bx lr at 0x0801f960 (returns immediately, no side effect).
@ ----------------------------------------------------------------------------
	.section .text.return_void_2,"ax",%progbits
	.global return_void_2
	.thumb_func
	.type return_void_2, %function
return_void_2:
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ blend_subpixel_point - draws one anti-aliased point at fractional coordinates.
@ Takes float x (s0), float y (s1) and RGB565 colour (r0); no return value.
@ ix = (int)x, iy = (int)y, fx = x - float(ix), fy = y - float(iy), w = fx*fy.
@ ix1 = (int)(x + 1.0) and iy1 = (int)(y + 1.0) (vadd of 1.0 then vcvt.s32 at
@ 0x0801f9f0..0x0801f9f4 and 0x0801fa42..0x0801fa48; not ix+1 / iy+1 for a
@ negative fractional input).
@ For each of the pixels (ix,iy), (ix1,iy), (ix,iy1), (ix1,iy1) the old pixel
@ is read from the buffer at [0x20008358] (value 0 when outside the clip
@ rectangle at 0x20008350/52/54/56) and blend_pixel_rgb565 (0801fcb0) is
@ called with the weights (1-w), fx*(1-w), fy*(1-w) and w respectively (the
@ fourth call, a tail branch, uses ix1 and iy1).
@ ----------------------------------------------------------------------------
	.section .text.blend_subpixel_point,"ax",%progbits
	.global blend_subpixel_point
	.thumb_func
	.type blend_subpixel_point, %function
blend_subpixel_point:
	push.w {r4, r5, r6, r7, r8, lr}
	vpush {d8, d9, d10, d11, d12, d13, d14}
	vmov.f32 s22, s0
	vcvt.s32.f32 s0, s0
	vcvt.f32.u32 s2, s0
	vmov r5, s0
	vcvt.s32.f32 s0, s1
	movw r4, #0x8350
	vcvt.f32.u32 s4, s0
	movt r4, #0x2000
	mov r8, r0
	vsub.f32 s28, s22, s2
	vsub.f32 s24, s1, s4
	ldrh r0, [r4, #0]
	vmul.f32 s16, s28, s24
	vmov.f32 s26, #1.0
	vmov.f32 s18, s1
	vmov r7, s0
	cmp r5, r0
	vsub.f32 s20, s26, s16
	blt.n .L0801f9e0
	ldrh r0, [r4, #0]
	ldrh r1, [r4, #4]
	add r0, r1
	cmp r0, r5
	ble.n .L0801f9e0
	ldrh r0, [r4, #2]
	cmp r7, r0
	blt.n .L0801f9e0
	ldrh r0, [r4, #2]
	ldrh r1, [r4, #6]
	add r0, r1
	cmp r0, r7
	ble.n .L0801f9e0
	ldr r0, [r4, #8]
	ldrh r1, [r4, #0]
	ldrh r2, [r4, #2]
	ldrh r3, [r4, #4]
	subs r1, r5, r1
	subs r2, r7, r2
	mla r1, r2, r3, r1
	ldrh.w r3, [r0, r1, lsl #1]
	b.n .L0801f9e2
.L0801f9e0:
	movs r3, #0
.L0801f9e2:
	mov r0, r5
	mov r1, r7
	mov r2, r8
	vmov.f32 s0, s20
	bl blend_pixel_rgb565
	vadd.f32 s0, s22, s26
	vcvt.s32.f32 s0, s0
	ldrh r0, [r4, #0]
	vmov r6, s0
	cmp r6, r0
	vmul.f32 s0, s28, s20
	blt.n .L0801fa36
	ldrh r0, [r4, #0]
	ldrh r1, [r4, #4]
	add r0, r1
	cmp r0, r6
	ble.n .L0801fa36
	ldrh r0, [r4, #2]
	cmp r7, r0
	blt.n .L0801fa36
	ldrh r0, [r4, #2]
	ldrh r1, [r4, #6]
	add r0, r1
	cmp r0, r7
	ble.n .L0801fa36
	ldr r0, [r4, #8]
	ldrh r1, [r4, #0]
	ldrh r2, [r4, #2]
	ldrh r3, [r4, #4]
	subs r1, r6, r1
	subs r2, r7, r2
	mla r1, r2, r3, r1
	ldrh.w r3, [r0, r1, lsl #1]
	b.n .L0801fa38
.L0801fa36:
	movs r3, #0
.L0801fa38:
	mov r0, r6
	mov r1, r7
	mov r2, r8
	bl blend_pixel_rgb565
	vadd.f32 s2, s18, s26
	ldrh r0, [r4, #0]
	vcvt.s32.f32 s2, s2
	vmul.f32 s0, s24, s20
	cmp r5, r0
	vmov r7, s2
	blt.n .L0801fa88
	ldrh r0, [r4, #0]
	ldrh r1, [r4, #4]
	add r0, r1
	cmp r0, r5
	ble.n .L0801fa88
	ldrh r0, [r4, #2]
	cmp r7, r0
	blt.n .L0801fa88
	ldrh r0, [r4, #2]
	ldrh r1, [r4, #6]
	add r0, r1
	cmp r0, r7
	ble.n .L0801fa88
	ldr r0, [r4, #8]
	ldrh r1, [r4, #0]
	ldrh r2, [r4, #2]
	ldrh r3, [r4, #4]
	subs r1, r5, r1
	subs r2, r7, r2
	mla r1, r2, r3, r1
	ldrh.w r3, [r0, r1, lsl #1]
	b.n .L0801fa8a
.L0801fa88:
	movs r3, #0
.L0801fa8a:
	mov r0, r5
	mov r1, r7
	mov r2, r8
	bl blend_pixel_rgb565
	ldrh r0, [r4, #0]
	cmp r6, r0
	bge.n .L0801fa9e
	movs r3, #0
	b.n .L0801fad8
.L0801fa9e:
	ldrh r0, [r4, #0]
	ldrh r1, [r4, #4]
	add r0, r1
	cmp r0, r6
	ble.n .L0801fab2
	ldrh r0, [r4, #2]
	cmp r7, r0
	bge.n .L0801fab6
	movs r3, #0
	b.n .L0801fad8
.L0801fab2:
	movs r3, #0
	b.n .L0801fad8
.L0801fab6:
	ldrh r0, [r4, #2]
	ldrh r1, [r4, #6]
	add r0, r1
	cmp r0, r7
	ble.n .L0801fad6
	ldr r0, [r4, #8]
	ldrh r1, [r4, #0]
	ldrh r2, [r4, #2]
	ldrh r3, [r4, #4]
	subs r1, r6, r1
	subs r2, r7, r2
	mla r1, r2, r3, r1
	ldrh.w r3, [r0, r1, lsl #1]
	b.n .L0801fad8
.L0801fad6:
	movs r3, #0
.L0801fad8:
	mov r0, r6
	mov r1, r7
	mov r2, r8
	vmov.f32 s0, s16
	vpop {d8, d9, d10, d11, d12, d13, d14}
	pop.w {r4, r5, r6, r7, r8, lr}
	b.w blend_pixel_rgb565
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ draw_arc_degrees - draws an anti-aliased circular arc of radius 190 around
@ (160,225). Takes start angle a1 (s0) and end angle a2 (s1) in degrees and the
@ colour (r0); no return value.
@ Each angle is reduced with float_remainder_sign_fixup (0804382e)(angle,
@ 360.0 = 0x43b40000), a float remainder routine, and increased by 360.0 when
@ negative (vcmp / vmovlt at 0x0801fb10..0x0801fb1a and 0x0801fb2e..0x0801fb3c).
@ Nothing is drawn when a1 >= a2 (bge at 0x0801fb48).
@ Loop: t = a1 * 3.1415927 / 180 * 0.15915494 (turns); the x index comes from
@ frac(t + 0.25) * 512, the y index from frac(t) * 512 (index wrapped to 0 when
@ >= 512); each coordinate is linearly interpolated between the table floats
@ at 0x0806e670 + 4*index and +4 (a sine table of 513 floats, first values
@ 0.0, 0.012271538, last -0.0; the +0.25 turn phase makes the x value a
@ cosine). Calls blend_subpixel_point (0801f964) with x = v1*190.0 + 160.0,
@ y = v2*190.0 + 225.0 and the colour, then a1 += 0.1, repeating while
@ a1 < a2.
@ ----------------------------------------------------------------------------
	.section .text.draw_arc_degrees,"ax",%progbits
	.global draw_arc_degrees
	.thumb_func
	.type draw_arc_degrees, %function
draw_arc_degrees:
	push {r4, r5, r6, lr}
	vpush {d8, d9, d10, d11, d12, d13, d14, d15}
	vldr s20, .L0801fc88
	vmov.f32 s18, s1
	vmov.f32 s1, s20
	mov r4, r0
	bl float_remainder_sign_fixup
	vmov.f32 s16, s0
	vadd.f32 s0, s0, s20
	vcmp.f32 s16, #0
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s16, s0
	vmov.f32 s0, s18
	vmov.f32 s1, s20
	bl float_remainder_sign_fixup
	vmov.f32 s18, s0
	vcmp.f32 s18, #0
	vadd.f32 s0, s0, s20
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s18, s0
	vcmp.f32 s16, s18
	vmrs APSR_nzcv, fpscr
	bge.w .L0801fc80
	vldr s20, .L0801fc8c
	vldr s22, .L0801fc90
	vldr s24, .L0801fc94
	vldr s28, .L0801fc98
	vldr s30, .L0801fc9c
	movw r6, #:lower16:d_0806e670
	vldr s17, .L0801fca0
	vldr s19, .L0801fca4
	vldr s21, .L0801fca8
	vldr s23, .L0801fcac
	vmov.f32 s26, #0.25
	movs r5, #0
	movt r6, #:upper16:d_0806e670
	vmov.f32 s25, #1.0
	nop
.L0801fb84:
	vmul.f32 s0, s16, s20
	vdiv.f32 s0, s0, s22
	vmul.f32 s0, s0, s24
	vadd.f32 s2, s0, s26
	vcvt.s32.f32 s4, s2
	vmov r0, s4
	vcmp.f32 s2, #0
	vmrs APSR_nzcv, fpscr
	it lt
	sublt r0, #1
	vmov s4, r0
	vcvt.f32.s32 s4, s4
	vsub.f32 s2, s2, s4
	vmul.f32 s2, s2, s28
	vcvt.s32.f32 s4, s2
	vmov r0, s4
	vadd.f32 s4, s2, s30
	cmp.w r5, r0, lsr #9
	itt ne
	vmovne.f32 s2, s4
	movne r0, #0
	vmov s4, r0
	vcvt.f32.u32 s4, s4
	add.w r0, r6, r0, lsl #2
	vsub.f32 s2, s2, s4
	vldr s4, [r0]
	vldr s6, [r0, #4]
	vsub.f32 s8, s25, s2
	vmul.f32 s4, s8, s4
	vmul.f32 s2, s2, s6
	vadd.f32 s2, s4, s2
	vcvt.s32.f32 s4, s0
	vmov r0, s4
	vcmp.f32 s0, #0
	vmrs APSR_nzcv, fpscr
	it lt
	sublt r0, #1
	vmov s4, r0
	vcvt.f32.s32 s4, s4
	vsub.f32 s0, s0, s4
	vmul.f32 s0, s0, s28
	vcvt.s32.f32 s4, s0
	vmov r0, s4
	vadd.f32 s4, s0, s30
	cmp.w r5, r0, lsr #9
	itt ne
	vmovne.f32 s0, s4
	movne r0, #0
	vmov s4, r0
	vcvt.f32.u32 s4, s4
	add.w r0, r6, r0, lsl #2
	vsub.f32 s0, s0, s4
	vldr s4, [r0]
	vldr s6, [r0, #4]
	vsub.f32 s8, s25, s0
	vmul.f32 s4, s8, s4
	vmul.f32 s0, s0, s6
	vadd.f32 s4, s4, s0
	vmul.f32 s0, s2, s17
	vmul.f32 s2, s4, s17
	vadd.f32 s0, s0, s19
	vadd.f32 s1, s2, s21
	mov r0, r4
	bl blend_subpixel_point
	vadd.f32 s16, s16, s23
	vcmp.f32 s16, s18
	vmrs APSR_nzcv, fpscr
	blt.n .L0801fb84
.L0801fc80:
	vpop {d8, d9, d10, d11, d12, d13, d14, d15}
	pop {r4, r5, r6, pc}
	.short 0xbf00	@ padding (bytes 00 bf)
.L0801fc88:
	.word 0x43b40000	@ 360.0f
.L0801fc8c:
	.word 0x40490fdb	@ 3.1415927f
.L0801fc90:
	.word 0x43340000	@ 180.0f
.L0801fc94:
	.word 0x3e22f983	@ 0.15915494f
.L0801fc98:
	.word 0x44000000	@ 512.0f
.L0801fc9c:
	.word 0xc4000000	@ -512.0f
.L0801fca0:
	.word 0x433e0000	@ 190.0f
.L0801fca4:
	.word 0x43200000	@ 160.0f
.L0801fca8:
	.word 0x43610000	@ 225.0f
.L0801fcac:
	.word 0x3dcccccd	@ 0.1f
