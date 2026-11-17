@ waveform_92.s - channel offset marker drawing: tail-branch thunk, one triangle marker, per-channel marker drawing
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ draw_channel_offset_markers_0801f608 - No parameters, no return value of its
@ own: its only instruction is b.w 0x08028b40, a tail branch to
@ draw_channel_offset_markers_08028b40 (thunk); the callee's behaviour is
@ documented there. Purpose not determined from the code beyond forwarding.
@ ----------------------------------------------------------------------------
	.section .text.draw_channel_offset_markers_0801f608,"ax",%progbits
	.p2align 2
	.global draw_channel_offset_markers_0801f608
	.thumb_func
	.type draw_channel_offset_markers_0801f608, %function
draw_channel_offset_markers_0801f608:
	b.w	draw_channel_offset_markers_08028b40

@ ----------------------------------------------------------------------------
@ fn_0801f60c - No parameters, no return value.
@ Returns at once if byte 0x2000012c is nonzero (ldrb at 0x0801f618, cbz at
@ 0x0801f61c). Otherwise h = halfword 0x20000114 (ldrh at 0x0801f622);
@ y = 0x78 - h; if (h + 100) as an unsigned 16-bit value is above 200 (cmp at
@ 0x0801f632) y = 0x14. Calls fill_triangle (08020af8) with vertices
@ (0x136,y), (0x13d,y+5), (0x13d,y-5) and colour 0x7e2, i.e. draws a small
@ triangle marker (tip x 0x136, base x 0x13d) at row y; what the marker
@ represents is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0801f60c,"ax",%progbits
	.p2align 2
	.global fn_0801f60c
	.thumb_func
	.type fn_0801f60c, %function
fn_0801f60c:
	push	{r7, lr}
	sub	sp, #0x10
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r1, [r0, #0x34]
	cbz	r1, .L0801f622
	add	sp, #0x10
	pop	{r7, pc}
.L0801f622:
	ldrh	r0, [r0, #0x1c]
	movw	r3, #0x13d
	add.w	r1, r0, #0x64
	uxth	r1, r1
	rsb.w	r0, r0, #0x78
	cmp	r1, #0xc8
	it	hi
	movhi	r0, #0x14
	subs	r1, r0, #5
	adds	r2, r0, #5
	sxth	r1, r1
	movw	r12, #0x7e2
	strd	r3, r1, [sp]
	sxth	r1, r0
	sxth	r3, r2
	mov.w	r0, #0x136
	movw	r2, #0x13d
	str.w	r12, [sp, #8]
	bl	fill_triangle
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ draw_channel_offset_markers_08028b40 - No parameters, no return value.
@ If byte 0x2000012c is 0: for each channel ch from the high nibble of byte
@ 0x2000010d to below the low nibble, with o = s8 0x200000fc+ch, calls
@ fill_triangle (08020af8) (4, 0x74-o, 4, 0x7c-o, 8, 0x78-o, colour) where
@ colour = halfword at 0x080bb40c + ch*2 + byte(0x2000105b)*4 (the x shift of
@ 0x32 times byte 0x2000012c is always 0 in this branch), then writes the same
@ colour pixel by pixel into the 16-bit clip buffer (pointer 0x20008358,
@ origin x u16 0x20008350, y u16 0x20008352, width u16 0x20008354, height u16
@ 0x20008356, only where inside the rectangle) at columns x = 0..3 for rows
@ 0x74-o .. 0x7c-o.
@ If byte 0x2000012c is non-zero: draws fill_triangle(0x9a+o0, 0x14, 0xa4+o0,
@ 0x14, 0x9f+o0, 0x1b, halfword 0x080bb40c + byte(0x2000105b)*4) with
@ o0 = s8 0x200000fc and fill_triangle(0x33, 0x73-o1, 0x33, 0x7d-o1, 0x3a,
@ 0x78-o1, halfword 0x080bb40e + byte(0x2000105b)*4) with o1 = s8 0x200000fd.
@ Purpose: draws the per-channel offset marker triangles (x 4..8, rows 0x74-o
@ .. 0x7c-o with o = s8 0x200000fc+ch) or, when byte 0x2000012c != 0, one
@ triangle at x 0x9a+o0..0xa4+o0, y 0x14..0x1b and one at x 0x33..0x3a, y
@ 0x73-o1..0x7d-o1, proven by the fill_triangle calls and clip-buffer stores;
@ which screen edges these coordinates are is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.draw_channel_offset_markers_08028b40,"ax",%progbits
	.p2align 2
	.global draw_channel_offset_markers_08028b40
	.thumb_func
	.type draw_channel_offset_markers_08028b40, %function
draw_channel_offset_markers_08028b40:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0xc
	movw	r8, #0xf8
	movt	r8, #0x2000
	ldrb.w	r0, [r8, #0x34]
	cbz	r0, .L08028bb0
	ldrsb.w	r1, [r8, #4]
	ldrb.w	r2, [r8, #0xf63]
	movw	r4, #:lower16:d_080bb40c
	movt	r4, #:upper16:d_080bb40c
	add.w	r3, r1, #0x9f
	add.w	r0, r1, #0x9a
	ldrh.w	r7, [r4, r2, lsl #2]
	add.w	r2, r1, #0xa4
	movs	r1, #0x1b
	strd	r3, r1, [sp]
	movs	r1, #0x14
	movs	r3, #0x14
	str	r7, [sp, #8]
	bl	fill_triangle
	ldrb.w	r3, [r8, #0xf63]
	ldrsb.w	r0, [r8, #5]
	add.w	r3, r4, r3, lsl #2
	rsb.w	r2, r0, #0x78
	rsb.w	r1, r0, #0x73
	ldrh	r7, [r3, #2]
	rsb.w	r3, r0, #0x7d
	movs	r0, #0x3a
	strd	r0, r2, [sp]
	movs	r0, #0x33
	movs	r2, #0x33
	str	r7, [sp, #8]
	bl	fill_triangle
	b.n	.L08028d40
.L08028bb0:
	ldrb.w	r0, [r8, #0x15]
	and.w	r1, r0, #0xf
	cmp.w	r1, r0, lsr #4
	bls.w	.L08028d40
	ldrb.w	r12, [r8, #0xf63]
	movw	r6, #0x8350
	lsr.w	r9, r0, #4
	mov.w	lr, #0
	movt	r6, #0x2000
	b.n	.L08028bea
	.byte	0x00, 0xbf	@ padding
.L08028bd8:
	ldrb.w	r0, [r8, #0x15]
	add.w	r9, r9, #1
	and.w	r0, r0, #0xf
	cmp	r9, r0
	bcs.w	.L08028d40
.L08028bea:
	add.w	r4, r8, r9
	movw	r11, #:lower16:d_080bb40c
	ldrsb.w	r3, [r4, #4]
	uxtb.w	r5, r12
	movt	r11, #:upper16:d_080bb40c
	uxtb.w	r2, lr
	movs	r0, #4
	mov.w	r10, #0x32
	add.w	r5, r11, r5, lsl #2
	movs	r7, #8
	smlabb	r0, r2, r10, r0
	rsb.w	lr, r3, #0x78
	ldrh.w	r5, [r5, r9, lsl #1]
	smlabb	r2, r2, r10, r7
	rsb.w	r1, r3, #0x74
	rsb.w	r3, r3, #0x7c
	strd	r2, lr, [sp]
	mov	r2, r0
	str	r5, [sp, #8]
	bl	fill_triangle
	ldrb.w	r12, [r8, #0xf63]
	ldrb.w	lr, [r8, #0x34]
	ldrsb.w	r0, [r4, #4]
	add.w	r2, r11, r12, lsl #2
	ldrh.w	r11, [r2, r9, lsl #1]
	rsb.w	r1, r0, #0x7c
	mul	r7, lr, r10
	rsb.w	r4, r0, #0x74
	b.n	.L08028c5c
.L08028c54:
	cmp	r4, r1
	add.w	r4, r4, #1
	bge.n	.L08028bd8
.L08028c5c:
	ldrh	r0, [r6]
	cmp	r7, r0
	bcc.n	.L08028c94
	ldrh	r0, [r6]
	ldrh	r2, [r6, #4]
	add	r0, r2
	cmp	r0, r7
	bls.n	.L08028c94
	ldrh	r0, [r6, #2]
	cmp	r4, r0
	blt.n	.L08028c94
	ldrh	r0, [r6, #2]
	ldrh	r2, [r6, #6]
	add	r0, r2
	cmp	r0, r4
	ble.n	.L08028c94
	ldr	r0, [r6, #8]
	ldrh	r2, [r6]
	ldrh	r5, [r6, #2]
	ldrh.w	r10, [r6, #4]
	subs	r2, r7, r2
	subs	r5, r4, r5
	mla	r2, r5, r10, r2
	strh.w	r11, [r0, r2, lsl #1]
	nop
.L08028c94:
	ldrh	r0, [r6]
	orr.w	r2, r7, #1
	cmp	r2, r0
	bcc.n	.L08028cd0
	ldrh	r0, [r6]
	ldrh	r5, [r6, #4]
	add	r0, r5
	cmp	r0, r2
	bls.n	.L08028cd0
	ldrh	r0, [r6, #2]
	cmp	r4, r0
	blt.n	.L08028cd0
	ldrh	r0, [r6, #2]
	ldrh	r5, [r6, #6]
	add	r0, r5
	cmp	r0, r4
	ble.n	.L08028cd0
	ldr.w	r10, [r6, #8]
	ldrh	r5, [r6]
	ldrh	r3, [r6, #2]
	ldrh	r0, [r6, #4]
	subs	r5, r2, r5
	subs	r3, r4, r3
	mla	r0, r3, r0, r5
	strh.w	r11, [r10, r0, lsl #1]
	nop
.L08028cd0:
	ldrh	r3, [r6]
	adds	r0, r2, #1
	cmp	r0, r3
	bcc.n	.L08028d08
	ldrh	r3, [r6]
	ldrh	r5, [r6, #4]
	add	r3, r5
	cmp	r3, r0
	bls.n	.L08028d08
	ldrh	r3, [r6, #2]
	cmp	r4, r3
	blt.n	.L08028d08
	ldrh	r3, [r6, #2]
	ldrh	r5, [r6, #6]
	add	r3, r5
	cmp	r3, r4
	ble.n	.L08028d08
	ldr.w	r10, [r6, #8]
	ldrh	r5, [r6]
	subs	r0, r0, r5
	ldrh	r5, [r6, #2]
	ldrh	r3, [r6, #4]
	subs	r5, r4, r5
	mla	r0, r5, r3, r0
	strh.w	r11, [r10, r0, lsl #1]
.L08028d08:
	ldrh	r3, [r6]
	adds	r0, r2, #2
	cmp	r0, r3
	bcc.n	.L08028c54
	ldrh	r2, [r6]
	ldrh	r3, [r6, #4]
	add	r2, r3
	cmp	r2, r0
	bls.n	.L08028c54
	ldrh	r2, [r6, #2]
	cmp	r4, r2
	blt.n	.L08028c54
	ldrh	r2, [r6, #2]
	ldrh	r3, [r6, #6]
	add	r2, r3
	cmp	r2, r4
	ble.n	.L08028c54
	ldr	r2, [r6, #8]
	ldrh	r3, [r6]
	subs	r0, r0, r3
	ldrh	r3, [r6, #2]
	ldrh	r5, [r6, #4]
	subs	r3, r4, r3
	mla	r0, r3, r5, r0
	strh.w	r11, [r2, r0, lsl #1]
	b.n	.L08028c54
.L08028d40:
	add	sp, #0xc
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short	0x0000	@ padding
	.short	0x0000	@ padding
	.short	0x0000	@ padding
	.short	0x0000	@ padding
	.short	0x0000	@ padding
