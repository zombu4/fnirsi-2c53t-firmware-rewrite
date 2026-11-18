@ draw_waveform_display_p6.inc - part 6 of 7 of draw_waveform_display (fragment included by part 1).
@ Continues the instructions of draw_waveform_display from 0x0801b5aa to 0x0801c5ac.
.L0801b5aa:
	ldrb.w	r0, [r9, #0x2e]
	add.w	r1, r9, #0x15
	cmp	r0, #0
	it	eq
	addweq	r1, r9, #0xdbf
	ldrb	r0, [r1]
	and	r1, r0, #0xf
	cmp.w	r1, r0, lsr #4
	str	r1, [sp, #0x20]
	bls.w	.L0801b800
	vldr	s16, .L0801b948
	movw	r8, #0xf8
	lsrs	r1, r0, #4
	vmov.f32	s18, #1.000000e+00
	vmov.f32	s20, #9.000000e+00
	vmov.f32	s22, #1.000000e+01
	movt	r8, #0x2000
	b.n	.L0801b5fc
	.byte	0x00, 0xbf	@ padding (never reached)
.L0801b5e8:
	mov	r11, r3
.L0801b5ea:
	ldr	r1, [sp, #0x28]
	ldr	r0, [sp, #0x20]
	adds	r1, #1
	cmp	r1, r0
	movw	r10, #0xf81f
	mov	r3, r11
	beq.w	.L0801b800
.L0801b5fc:
	cmp	r3, #2
	str	r1, [sp, #0x28]
	bcc.n	.L0801b5e8
	ldrb.w	r0, [r8, #0x2e]
	cmp	r0, #0
	bne.w	.L0801b738
	ldr.w	r5, [r8, #0xe08]
	ldr.w	r6, [r8, #0xe0c]
	subs.w	r0, r5, #0x3e8
	sbcs.w	r0, r6, #0
	bcc.w	.L0801b738
	add.w	r0, r8, r1, lsl #2
	addw	r0, r0, #0xdfc
	movs	r4, #0
	str	r0, [sp, #0x24]
.L0801b62c:
	uxth	r1, r3
	umull	r0, r2, r5, r1
	mla	r1, r6, r1, r2
	mov.w	r2, #0x3e8
	mov	r11, r3
	movs	r3, #0
	str	r4, [sp, #0x2c]
	uxth	r7, r4
	mov	r4, r6
	bl	divide_u64
	ldr	r2, [sp, #0x24]
	ldrb.w	r9, [r8, #0xe04]
	ldr.w	r10, [r2]
	mov	r2, r9
	cmp.w	r10, #0
	it	eq
	moveq	r2, #1
	umull	r0, r3, r2, r0
	ldrh.w	r6, [r8, #0xde0]
	mla	r1, r2, r1, r3
	movw	r2, #0x12d
	subs	r2, r2, r6
	subs	r3, r0, r2
	sbcs.w	r3, r1, r2, asr #31
	mov.w	r3, #0
	it	cc
	movcc	r3, #1
	cmp	r3, #0
	ite	eq
	asreq	r1, r2, #31
	movne	r2, r0
	subs	r0, r2, #1
	sbc.w	r1, r1, #0
	subs	r0, r7, r0
	mov.w	r0, #0
	sbcs	r0, r1
	movw	r6, #0x12d
	bcs.n	.L0801b5ea
	vmov	s0, r7
	mov	r0, r5
	mov	r1, r4
	vcvt.f32.u32	s24, s0
	bl	u64_to_float
	vmov	s0, r0
	vdiv.f32	s0, s0, s16
	vmov	s2, r9
	vcvt.f32.u32	s2, s2
	cmp.w	r10, #0
	it	eq
	vmoveq.f32	s2, s18
	ldr	r5, [sp, #0x28]
	ldr	r4, [sp, #0x2c]
	mla	r1, r5, r6, r8
	ldrh.w	r0, [r8, #0xdb4]
	uxtah	r1, r1, r4
	ldrb.w	r3, [r1, #0x356]
	ldrb.w	r7, [r1, #0x357]
	ldrb.w	r6, [r8, #0xf63]
	rsb.w	r1, r3, #0xf8
	vmul.f32	s0, s0, s2
	vdiv.f32	s0, s24, s0
	vmov	s2, r0
	vcvt.f32.u32	s2, s2
	movw	r3, #:lower16:d_080bb40c
	movt	r3, #:upper16:d_080bb40c
	add.w	r3, r3, r6, lsl #2
	ldrh.w	r6, [r3, r5, lsl #1]
	rsb.w	r3, r7, #0xf8
	str	r6, [sp]
	vadd.f32	s0, s0, s2
	vadd.f32	s2, s0, s20
	vadd.f32	s0, s0, s22
	vcvt.s32.f32	s2, s2
	vcvt.s32.f32	s0, s0
	vmov	r0, s2
	vmov	r2, s0
	bl	fn_0801fea8
	ldrh.w	r3, [r8, #0xdb6]
	ldr.w	r5, [r8, #0xe08]
	ldr.w	r6, [r8, #0xe0c]
	adds	r4, #1
	b.n	.L0801b62c
.L0801b738:
	ldrh.w	r0, [r8, #0xdb4]
	mov	r11, r3
	adds	r1, r0, r3
	subs	r1, #1
	cmp	r1, r0
	movw	r6, #0x12d
	ble.w	.L0801b5ea
	ldr	r5, [sp, #0x28]
	movw	r9, #:lower16:d_080bb40c
	mov	r4, r0
	movt	r9, #:upper16:d_080bb40c
.L0801b758:
	mla	r1, r5, r6, r8
	ldrb.w	r3, [r8, #0xf63]
	add	r0, r1
	ldrb.w	r1, [r0, #0x356]
	ldrb.w	r0, [r0, #0x357]
	add.w	r3, r9, r3, lsl #2
	add.w	r2, r4, #9
	add.w	r7, r4, #0xa
	ldrh.w	r6, [r3, r5, lsl #1]
	rsb.w	r1, r1, #0xf8
	rsb.w	r3, r0, #0xf8
	sxth	r0, r2
	sxth	r2, r7
	str	r6, [sp]
	movw	r6, #0x12d
	bl	fn_0801fea8
	ldrh.w	r1, [r8, #0xdb4]
	ldrh.w	r11, [r8, #0xdb6]
	adds	r4, #1
	add	r1, r11
	uxth	r0, r4
	subs	r1, #1
	cmp	r1, r0
	bgt.n	.L0801b758
	b.n	.L0801b5ea
.L0801b7a6:
	ldrh.w	r2, [r9, #0xdb4]
	adds	r0, r2, r3
	subs	r0, #1
	cmp	r0, r2
	ble.n	.L0801b800
	movw	r0, #0xf8
	movt	r0, #0x2000
	addw	r4, r0, #0x356
	addw	r5, r0, #0x483
	mov	r6, r2
.L0801b7c4:
	ldrb	r0, [r4, r2]
	ldrb	r1, [r5, r2]
	adds	r2, #1
	ldrb	r3, [r4, r2]
	ldrb	r7, [r5, r2]
	adds	r0, #0x1f
	rsb.w	r1, r1, #0xf8
	add.w	r2, r3, #0x1f
	rsb.w	r3, r7, #0xf8
	str.w	r10, [sp]
	bl	draw_line
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldrh.w	r0, [r1, #0xdb4]
	ldrh.w	r1, [r1, #0xdb6]
	adds	r6, #1
	add	r0, r1
	uxth	r2, r6
	subs	r0, #1
	cmp	r0, r2
	bgt.n	.L0801b7c4
.L0801b800:
	movw	r9, #0xf8
	movt	r9, #0x2000
	ldrb.w	r0, [r9, #0x34]
	cmp	r0, #0
	bne.n	.L0801b8ec
	ldrb.w	r0, [r9, #0x2e]
	add.w	r1, r9, #0x15
	cmp	r0, #0
	it	eq
	addweq	r1, r9, #0xdbf
	ldrb	r0, [r1]
	and	r8, r0, #0xf
	cmp.w	r8, r0, lsr #4
	bls.n	.L0801b882
	lsrs	r5, r0, #4
	movs	r0, #9
	movs	r1, #0xad
	smlabb	r6, r5, r1, r0
	b.n	.L0801b842
.L0801b838:
	adds	r5, #1
	cmp	r5, r8
	add.w	r6, r6, #0xad
	beq.n	.L0801b87c
.L0801b842:
	add.w	r0, r9, r5
	ldrb	r0, [r0, #0xa]
	cmp	r0, #0
	beq.n	.L0801b838
	add.w	r7, r9, r5, lsl #2
	ldr.w	r0, [r7, #0xc]!
	cmp	r0, #0
	beq.n	.L0801b838
	movs	r4, #0
	nop
.L0801b85c:
	ldrb	r0, [r0, r4]
	adds	r1, r6, r4
	rsb.w	r3, r0, #0x46
	sxth	r0, r1
	movs	r1, #0x46
	mov	r2, r0
	str.w	r10, [sp]
	bl	fn_0801fea8
	cmp	r4, #0x7f
	beq.n	.L0801b838
	ldr	r0, [r7]
	adds	r4, #1
	b.n	.L0801b85c
.L0801b87c:
	ldrb.w	r0, [r9, #0x34]
	cbnz	r0, .L0801b8ec
.L0801b882:
	ldrsh.w	r0, [r9, #0x1a]
	cmp	r0, #0x92
	blt.n	.L0801b8a6
	movs	r0, #0x19
	movw	r1, #0x135
	movw	r7, #0x7e2
	strd	r1, r0, [sp]
	mov.w	r0, #0x12e
	movs	r1, #0x14
	mov.w	r2, #0x12e
	movs	r3, #0x1e
	b.n	.L0801b8e6
.L0801b8a6:
	add.w	r1, r10, #0x750
	sxth	r1, r1
	cmp	r0, r1
	bge.n	.L0801b8c6
	movs	r0, #0x19
	movs	r1, #9
	movw	r7, #0x7e2
	strd	r1, r0, [sp]
	movs	r0, #0x10
	movs	r1, #0x14
	movs	r2, #0x10
	movs	r3, #0x1e
	b.n	.L0801b8e6
.L0801b8c6:
	add.w	r1, r0, #0x9f
	add.w	r2, r0, #0x9a
	add.w	r3, r0, #0xa4
	movs	r0, #0x1b
	sxth	r1, r1
	movw	r7, #0x7e2
	strd	r1, r0, [sp]
	sxth	r0, r2
	sxth	r2, r3
	movs	r1, #0x14
	movs	r3, #0x14
.L0801b8e6:
	str	r7, [sp, #8]
	bl	fill_triangle
.L0801b8ec:
	ldr.w	r0, [r9, #0x4c]
	ldrb.w	r1, [r9, #0x34]
	cmp	r0, #0
	beq.w	.L0801bc4c
	cmp	r1, #0
	bne.w	.L0801bc4c
	ldrb.w	r2, [r9, #0x14]
	cmp	r2, #0
	beq.w	.L0801bc4c
	ldrb.w	r3, [r9, #0x48]
	cmp	r3, #0
	bne.w	.L0801bc4c
	movs	r1, #0x10
	lsls	r3, r2, #0x1e
	bic.w	r6, r1, r2, lsl #4
	mov.w	r2, #0
	mov.w	r1, #0
	bmi.n	.L0801b94c
	nop
.L0801b928:
	lsls	r3, r2, #0x18
	it	eq
	moveq	r2, r6
	uxtb	r3, r2
	cmp	r3, #0x10
	beq.n	.L0801b99c
	lsr.w	r7, r0, r3
	lsls	r7, r7, #0x1f
	it	ne
	addne	r1, #1
	cmp	r3, #0x1f
	add.w	r2, r2, #1
	bcc.n	.L0801b928
	b.n	.L0801b99c
.L0801b948:
	.word	0x447a0000
.L0801b94c:
	lsls	r3, r2, #0x18
	it	eq
	moveq	r2, r6
	uxtb	r3, r2
	lsr.w	r7, r0, r3
	lsls	r7, r7, #0x1f
	it	ne
	addne	r1, #1
	cmp	r3, #0x1f
	bcs.n	.L0801b99c
	adds	r7, r2, #1
	uxtb	r7, r7
	lsr.w	r7, r0, r7
	lsls	r7, r7, #0x1f
	it	ne
	addne	r1, #1
	cmp	r3, #0x1e
	beq.n	.L0801b99c
	adds	r7, r2, #2
	uxtb	r7, r7
	lsr.w	r7, r0, r7
	lsls	r7, r7, #0x1f
	it	ne
	addne	r1, #1
	cmp	r3, #0x1c
	bhi.n	.L0801b99c
	adds	r7, r2, #3
	uxtb	r7, r7
	lsr.w	r7, r0, r7
	lsls	r7, r7, #0x1f
	it	ne
	addne	r1, #1
	cmp	r3, #0x1c
	add.w	r2, r2, #4
	bne.n	.L0801b94c
.L0801b99c:
	lsls	r2, r1, #0x18
	beq.w	.L0801bc52
	movw	r2, #0xaaab
	uxtb	r7, r1
	movt	r2, #0xaaaa
	umull	r2, r3, r7, r2
	ldrb.w	r2, [r9, #0xf60]
	movw	lr, #0x423f
	subs	r2, #1
	clz	r2, r2
	lsrs	r2, r2, #5
	str	r2, [sp, #0x1c]
	mov.w	r2, #0xffffffff
	uxtab	r1, r2, r1
	movw	r2, #0x5556
	movt	r2, #0x5555
	smmul	r1, r1, r2
	movw	r2, #0xffff
	add.w	r1, r1, r1, lsr #31
	subs	r2, #0xe
	muls	r1, r2, r1
	add.w	r4, r1, #0xcc
	lsrs	r1, r3, #1
	add.w	r1, r1, r1, lsl #1
	subs	r1, r7, r1
	uxtb	r1, r1
	str	r1, [sp, #0x18]
	clz	r1, r1
	movw	r10, #0x4dd3
	vldr	s16, .L0801bd00
	vldr	s18, .L0801b948
	movt	lr, #0xf
	lsrs	r1, r1, #5
	movt	r10, #0x1062
	mov.w	r11, #0
	movs	r5, #0xc
	str	r7, [sp, #0x20]
	str	r1, [sp, #0x14]
	nop
.L0801ba18:
	ldr	r2, [sp, #0x18]
	uxtb.w	r1, r11
	subs	r1, r2, r1
	it	ne
	movne	r1, #1
	ldr	r2, [sp, #0x14]
	orrs	r1, r2
	mov.w	r1, #0xc
	add.w	r2, r6, #1
	itt	eq
	moveq	r5, r1
	addeq	r4, #0xf
	uxtb	r1, r2
	cmp	r1, #0x20
	mov	r1, r6
	it	ls
	movls	r2, #0x20
.L0801ba40:
	uxtb	r3, r1
	lsr.w	r3, r0, r3
	lsls	r3, r3, #0x1f
	bne.n	.L0801ba8a
	adds	r3, r1, #1
	uxtb	r7, r3
	cmp	r7, #0x20
	bcs.n	.L0801ba82
	lsr.w	r7, r0, r7
	lsls	r7, r7, #0x1f
	bne.n	.L0801ba88
	adds	r3, r1, #2
	uxtb	r7, r3
	cmp	r7, #0x1f
	bhi.n	.L0801ba82
	lsr.w	r7, r0, r7
	lsls	r7, r7, #0x1f
	bne.n	.L0801ba88
	adds	r3, r1, #3
	uxtb	r7, r3
	cmp	r7, #0x1f
	bhi.n	.L0801ba82
	lsr.w	r7, r0, r7
	lsls	r7, r7, #0x1f
	bne.n	.L0801ba88
	adds	r1, #4
	uxtb	r3, r1
	cmp	r3, #0x1f
	bls.n	.L0801ba40
.L0801ba82:
	add.w	r12, r2, #1
	b.n	.L0801ba96
.L0801ba88:
	mov	r1, r3
.L0801ba8a:
	uxtb	r0, r1
	cmp	r0, #0x10
	add.w	r12, r1, #1
	bcc.n	.L0801baa8
	mov	r2, r1
.L0801ba96:
	sub.w	r1, r2, #0x10
	uxtb	r0, r1
	add.w	r0, r9, r0, lsl #2
	add.w	r0, r0, #0x140
	movs	r2, #1
	b.n	.L0801bab2
.L0801baa8:
	add.w	r0, r9, r0, lsl #2
	add.w	r0, r0, #0x110
	movs	r2, #0
.L0801bab2:
	ldr	r0, [r0]
	strd	r5, r4, [sp, #0x28]
	smmul	r5, r0, r10
	cmp	r0, #0
	mov	r3, r0
	mov.w	r4, #0
	asr.w	r6, r5, #6
	ldrb.w	r7, [r9, #0xf63]
	itt	le
	movle	r3, #0
	qsuble	r3, r3, r0
	cmp	r3, lr
	it	gt
	movgt	r4, #1
	it	gt
	addgt.w	r0, r6, r5, lsr #31
	movw	r6, #:lower16:d_080bb40c
	cmp	r0, #0
	mov	r5, r0
	movt	r6, #:upper16:d_080bb40c
	itt	le
	movle	r5, #0
	qsuble	r5, r5, r0
	add.w	r7, r6, r7, lsl #2
	cmp	r3, lr
	mov.w	r3, #1
	str.w	r12, [sp, #0x24]
	ldrh.w	r9, [r7, r2, lsl #1]
	smmul	r2, r0, r10
	it	gt
	movgt	r3, #2
	cmp	r5, lr
	asr.w	r7, r2, #6
	itt	gt
	addgt.w	r0, r7, r2, lsr #31
	movgt	r4, r3
	cmp	r0, #0
	mov	r2, r0
	smmul	r3, r0, r10
	itt	le
	movle	r2, #0
	qsuble	r2, r2, r0
	asrs	r7, r3, #6
	cmp	r2, lr
	it	gt
	addgt.w	r0, r7, r3, lsr #31
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	and	r0, r1, #0xfe
	vdiv.f32	s2, s0, s16
	it	gt
	addgt	r4, #1
	cmp	r0, #2
	mvn	r0, #5
	it	eq
	vmoveq.f32	s0, s2
	vdiv.f32	s2, s0, s18
	uxtab	r0, r0, r1
	cmp	r0, #6
	it	lo
	vmovlo.f32	s0, s2
	vabs.f32	s2, s0
	vdiv.f32	s4, s0, s18
	vdiv.f32	s20, s2, s18
	vcmp.f32	s2, s18
	vmrs	APSR_nzcv, fpscr
	itte	lt
	vmovlt.f32	s4, s0
	vmovlt.f32	s20, s2
	addge	r4, #1
	ldr	r0, [sp, #0x1c]
	uxtb	r6, r1
	movw	r1, #:lower16:d_0804bf28
	orr.w	r0, r0, r0, lsl #1
	movt	r1, #:upper16:d_0804bf28
	add.w	r0, r1, r0, lsl #4
	ldr.w	r5, [r0, r6, lsl #2]
	vmov	r0, s4
	mov	r8, r10
	mov	r10, lr
	bl	float_to_double
	adr.w	r2, .L0801ca18
	ldrb	r2, [r2, r6]
	vmov	d0, r0, r1
	adr.w	r0, .L0801ca24
	add.w	r0, r0, r2, lsl #4
	ldr.w	r0, [r0, r4, lsl #2]
	movw	r4, #0x8360
	vcmp.f32	s20, s16
	adr.w	r1, .L0801ca70
	adr.w	r2, .L0801ca64
	movt	r4, #0x2000
	vmrs	APSR_nzcv, fpscr
	it	lt
	movlt	r1, r2
	str	r0, [sp, #8]
	mov	r0, r4
	mov	r2, r5
	vstr	d0, [sp]
	bl	format_to_buffer_080073b4
	str	r4, [sp]
	movw	r0, #0x10b4
	ldr	r5, [sp, #0x28]
	ldr	r4, [sp, #0x2c]
	movt	r0, #0x2000
	strd	r0, r9, [sp, #4]
	sxth	r0, r5
	sxth	r1, r4
	movs	r2, #0x64
	movs	r3, #0xf
	movs	r7, #0
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add.w	r11, r11, #1
	ldr	r1, [sp, #0x20]
	uxtb.w	r0, r11
	cmp	r0, r1
	bcs.n	.L0801bc40
	add.w	r0, r5, #0x64
	movw	r9, #0xf8
	sxth	r5, r0
	movt	r9, #0x2000
	cmp.w	r5, #0x138
	it	ge
	addge	r4, #0xf
	ldr.w	r0, [r9, #0x4c]
	it	ge
	movge	r5, #0xc
	ldr	r6, [sp, #0x24]
	mov	lr, r10
	mov	r10, r8
	b.n	.L0801ba18
.L0801bc40:
	movw	r9, #0xf8
	movt	r9, #0x2000
	ldrb.w	r1, [r9, #0x34]
.L0801bc4c:
	cmp	r1, #0
	bne.w	.L0801bdbe
.L0801bc52:
	ldrb.w	r0, [r9, #0x23a]
	movw	r4, #0xf81f
	lsls	r1, r0, #0x1f
	bne.n	.L0801bc66
	lsls	r1, r0, #0x1e
	bmi.n	.L0801bc96
.L0801bc62:
	cbnz	r0, .L0801bcce
	b.n	.L0801bdbe
.L0801bc66:
	ldrh.w	r0, [r9, #0x232]
	movs	r1, #0x14
	adds	r0, #0x9f
	sxth	r0, r0
	mov	r2, r0
	movs	r3, #0xdc
	str	r4, [sp]
	bl	fn_0801fea8
	ldrh.w	r0, [r9, #0x234]
	movs	r1, #0x14
	adds	r0, #0x9f
	sxth	r0, r0
	mov	r2, r0
	movs	r3, #0xdc
	str	r4, [sp]
	bl	fn_0801fea8
	ldrb.w	r0, [r9, #0x23a]
	lsls	r1, r0, #0x1e
	bpl.n	.L0801bc62
.L0801bc96:
	ldrh.w	r0, [r9, #0x236]
	movw	r2, #0x135
	rsb.w	r0, r0, #0x78
	sxth	r1, r0
	movs	r0, #9
	mov	r3, r1
	str	r4, [sp]
	bl	draw_line
	ldrh.w	r0, [r9, #0x238]
	movw	r2, #0x135
	rsb.w	r0, r0, #0x78
	sxth	r1, r0
	movs	r0, #9
	mov	r3, r1
	str	r4, [sp]
	bl	draw_line
	ldrb.w	r0, [r9, #0x23a]
	cmp	r0, #0
	beq.n	.L0801bdbe
.L0801bcce:
	mov.w	r11, #0x19
	movs	r1, #0
	movs	r4, #0
	lsls	r2, r0, #0x1f
	bne.n	.L0801bd06
	b.n	.L0801bcec
.L0801bcdc:
	ldrb.w	r0, [r9, #0x23a]
	add.w	r1, r10, #1
	add.w	r11, r11, #0xc
	lsls	r2, r0, #0x1f
	bne.n	.L0801bd06
.L0801bcec:
	uxtb	r2, r1
	cbz	r2, .L0801bd04
	movw	r9, #0xf8
	cmp	r2, #6
	movt	r9, #0x2000
	bne.n	.L0801bd06
	b.n	.L0801bdbe
	.byte	0x00, 0xbf	@ padding (never reached)
.L0801bd00:
	.word	0x42c80000
.L0801bd04:
	movs	r1, #3
.L0801bd06:
	uxtb	r2, r1
	cmp	r2, #3
	mov	r10, r1
	it	eq
	moveq.w	r10, #6
	lsls	r0, r0, #0x1e
	it	mi
	movmi	r10, r1
	uxtb.w	r8, r10
	adr.w	r0, .L0801ca7c
	ldr.w	r0, [r0, r8, lsl #2]
	movw	r5, #0x10e4
	str	r0, [sp]
	movw	r0, #0xf81f
	sxth.w	r6, r11
	movt	r5, #0x2000
	str	r0, [sp, #8]
	movs	r0, #0xe
	mov	r1, r6
	movs	r2, #0x32
	movs	r3, #0x10
	str	r5, [sp, #4]
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r9, #0xf8
	movt	r9, #0x2000
	add.w	r0, r9, r8, lsl #2
	ldr.w	r0, [r0, #0x23c]
	bl	float_to_double
	mov	r2, r0
	adr.w	r0, .L0801ca98
	ldrb.w	r0, [r0, r8]
	uxtab	r3, r9, r10
	movw	r7, #:lower16:d_0804bf88
	ldrb.w	r3, [r3, #0x258]
	movt	r7, #:upper16:d_0804bf88
	add.w	r0, r7, r0, lsl #4
	movw	r5, #0x8360
	ldr.w	r7, [r0, r3, lsl #2]
	mov	r3, r1
	movt	r5, #0x2000
	movw	r1, #:lower16:t_080bcc11
	mov	r0, r5
	movt	r1, #:upper16:t_080bcc11
	str	r7, [sp]
	bl	format_to_buffer_080073b4
	movw	r0, #0x10e4
	movt	r0, #0x2000
	str	r0, [sp, #4]
	movw	r0, #0xf81f
	str	r0, [sp, #8]
	movs	r0, #0x40
	mov	r1, r6
	movs	r2, #0x64
	movs	r3, #0x10
	str	r5, [sp]
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	cmp.w	r8, #5
	bls.n	.L0801bcdc
.L0801bdbe:
	ldrb.w	r0, [r9, #0x35]
	cmp	r0, #0
	beq.w	.L0801bf8a
	ldr.w	r1, [r9, #0x38]
	cmp	r1, #0
	beq.w	.L0801bf8a
	ldrb.w	r0, [r9, #0x34]
	cmp	r0, #0
	bne.w	.L0801bf8a
	ldrh.w	r0, [r9, #0xdb6]
	cmp	r0, #2
	bcc.w	.L0801bf8a
	ldrb.w	r2, [r9, #0x2e]
	cbnz	r2, .L0801be2a
	ldr.w	r11, [r9, #0xe08]
	ldr.w	r10, [r9, #0xe0c]
	subs.w	r2, r11, #0x3e8
	sbcs.w	r2, r10, #0
	bcc.n	.L0801be2a
	ldrb.w	r1, [r9, #0xdbf]
	lsrs	r2, r1, #4
	and	r3, r1, #0xf
	movs	r1, #0
	nop
.L0801be0c:
	cmp	r2, r3
	bcs.n	.L0801be80
	adds	r1, r2, #1
	cmp	r1, r3
	bcs.n	.L0801be7e
	adds	r7, r2, #2
	cmp	r7, r3
	bcs.n	.L0801be80
	adds	r1, r2, #3
	cmp	r1, r3
	add.w	r2, r2, #4
	bcc.n	.L0801be0c
	mov	r1, r7
	b.n	.L0801be80
.L0801be2a:
	ldrh.w	r2, [r9, #0xdb4]
	add	r0, r2
	subs	r0, #1
	cmp	r0, r2
	ble.w	.L0801bf8a
	mov	r4, r2
	nop
.L0801be3c:
	ldrsb	r3, [r1, r2]
	add	r2, r1
	ldrsb.w	r2, [r2, #1]
	add.w	r0, r4, #9
	add.w	r7, r4, #0xa
	rsb.w	r1, r3, #0x78
	rsb.w	r3, r2, #0x78
	sxth	r0, r0
	sxth	r2, r7
	movw	r7, #0xf81f
	str	r7, [sp]
	bl	fn_0801fea8
	ldrh.w	r0, [r9, #0xdb4]
	ldrh.w	r1, [r9, #0xdb6]
	adds	r4, #1
	add	r0, r1
	uxth	r2, r4
	subs	r0, #1
	cmp	r0, r2
	ble.w	.L0801bf8a
	ldr.w	r1, [r9, #0x38]
	b.n	.L0801be3c
.L0801be7e:
	mov	r1, r2
.L0801be80:
	movw	r9, #0xf8
	movt	r9, #0x2000
	add.w	r1, r9, r1, lsl #2
	vldr	s16, .L0801bfd0
	addw	r1, r1, #0xdfc
	vmov.f32	s18, #1.000000e+00
	vmov.f32	s20, #9.000000e+00
	vmov.f32	s22, #1.000000e+01
	movs	r6, #0
	str	r1, [sp, #0x2c]
.L0801bea4:
	uxth	r1, r0
	umull	r0, r2, r11, r1
	mla	r1, r10, r1, r2
	mov.w	r2, #0x3e8
	movs	r3, #0
	uxth	r4, r6
	bl	divide_u64
	ldr	r2, [sp, #0x2c]
	ldrb.w	r8, [r9, #0xe04]
	ldr	r7, [r2]
	mov	r2, r8
	cmp	r7, #0
	it	eq
	moveq	r2, #1
	umull	r0, r3, r2, r0
	ldrh.w	r5, [r9, #0xde0]
	mla	r1, r2, r1, r3
	movw	r2, #0x12d
	subs	r2, r2, r5
	subs	r3, r0, r2
	sbcs.w	r3, r1, r2, asr #31
	mov.w	r3, #0
	it	cc
	movcc	r3, #1
	cmp	r3, #0
	ite	eq
	asreq	r1, r2, #31
	movne	r2, r0
	subs	r0, r2, #1
	sbc.w	r1, r1, #0
	subs	r0, r4, r0
	mov.w	r0, #0
	sbcs	r0, r1
	bcs.n	.L0801bf8a
	vmov	s0, r4
	mov	r0, r11
	mov	r1, r10
	vcvt.f32.u32	s24, s0
	bl	u64_to_float
	vmov	s0, r0
	vdiv.f32	s0, s0, s16
	vmov	s2, r8
	vcvt.f32.u32	s2, s2
	cmp	r7, #0
	it	eq
	vmoveq.f32	s2, s18
	ldrh.w	r0, [r9, #0xdb4]
	ldr.w	r1, [r9, #0x38]
	ldrsb	r3, [r1, r4]
	uxtah	r1, r1, r6
	ldrsb.w	r7, [r1, #1]
	rsb.w	r1, r3, #0x78
	rsb.w	r3, r7, #0x78
	movw	r7, #0xf81f
	vmul.f32	s0, s0, s2
	vdiv.f32	s0, s24, s0
	vmov	s2, r0
	vcvt.f32.u32	s2, s2
	str	r7, [sp]
	vadd.f32	s0, s0, s2
	vadd.f32	s2, s0, s20
	vadd.f32	s0, s0, s22
	vcvt.s32.f32	s2, s2
	vcvt.s32.f32	s0, s0
	vmov	r0, s2
	vmov	r2, s0
	bl	fn_0801fea8
	ldrh.w	r0, [r9, #0xdb6]
	ldr.w	r11, [r9, #0xe08]
	ldr.w	r10, [r9, #0xe0c]
	adds	r6, #1
	b.n	.L0801bea4
.L0801bf8a:
	ldrh.w	r1, [r9, #0x2a]
	ldrb.w	r0, [r9, #0x34]
	cmp	r1, #0
	beq.w	.L0801c2fc
	cmp	r0, #0
	bne.w	.L0801c2fc
	ldrh.w	r1, [r9, #0x1c]
	movs	r6, #0
	add.w	r0, r1, #0x64
	uxth	r2, r0
	rsb.w	r9, r2, #0xdc
	cmp	r2, #0xc8
	it	hi
	movhi.w	r9, #0x14
	cmp	r2, #0xc8
	it	ls
	movls	r2, #0xc8
	subs	r1, r2, r1
	subs	r1, #0x50
	sxth.w	r0, r9
	sxth	r1, r1
	movs	r2, #0xc
	movw	r12, #0x7e2
	b.n	.L0801bfe0
	.byte	0x00, 0xbf	@ padding (never reached)
.L0801bfd0:
	.word	0x447a0000
.L0801bfd4:
	adds	r6, #1
	uxth	r3, r6
	cmp	r3, #4
	it	hi
	movhi	r6, #0
	adds	r2, #4
.L0801bfe0:
	uxth	r7, r6
	cmp	r7, #2
	bhi.n	.L0801c048
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r5, [r3]
	subs	r7, r2, #3
	cmp	r7, r5
	bcc.n	.L0801c048
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r5, [r3]
	ldrh	r4, [r3, #4]
	add	r5, r4
	cmp	r5, r7
	bls.n	.L0801c048
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r7, [r3, #2]
	cmp	r0, r7
	blt.n	.L0801c048
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r7, [r3, #2]
	ldrh	r5, [r3, #6]
	add	r7, r5
	cmp	r7, r0
	ble.n	.L0801c048
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldr	r7, [r3, #8]
	ldrh	r5, [r3]
	ldrh	r4, [r3, #2]
	ldrh	r3, [r3, #4]
	subs	r4, r1, r4
	muls	r3, r4, r3
	subs	r3, r3, r5
	add	r3, r2
	add.w	r3, r7, r3, lsl #1
	strh.w	r12, [r3, #-6]
.L0801c048:
	adds	r6, #1
	uxth	r3, r6
	cmp	r3, #4
	it	hi
	movhi	r6, #0
	cmp.w	r2, #0x138
	beq.w	.L0801c1b0
	uxth	r3, r6
	cmp	r3, #2
	bhi.n	.L0801c0c4
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r3, [r3]
	subs	r7, r2, #2
	cmp	r7, r3
	bcc.n	.L0801c0c4
	movw	r5, #0x8350
	movt	r5, #0x2000
	ldrh	r3, [r5]
	ldrh	r5, [r5, #4]
	add	r3, r5
	cmp	r3, r7
	bls.n	.L0801c0c4
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r3, [r3, #2]
	cmp	r0, r3
	blt.n	.L0801c0c4
	movw	r7, #0x8350
	movt	r7, #0x2000
	ldrh	r3, [r7, #2]
	ldrh	r7, [r7, #6]
	add	r3, r7
	cmp	r3, r0
	ble.n	.L0801c0c4
	movw	r4, #0x8350
	movt	r4, #0x2000
	ldr	r3, [r4, #8]
	ldrh	r7, [r4]
	ldrh	r5, [r4, #2]
	ldrh	r4, [r4, #4]
	subs	r5, r1, r5
	muls	r5, r4, r5
	subs	r7, r5, r7
	add	r7, r2
	add.w	r3, r3, r7, lsl #1
	strh.w	r12, [r3, #-4]
	nop
.L0801c0c4:
	adds	r6, #1
	uxth	r3, r6
	cmp	r3, #4
	it	hi
	movhi	r6, #0
	uxth	r3, r6
	cmp	r3, #2
	bhi.n	.L0801c138
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r3, [r3]
	subs	r7, r2, #1
	cmp	r7, r3
	bcc.n	.L0801c138
	movw	r5, #0x8350
	movt	r5, #0x2000
	ldrh	r3, [r5]
	ldrh	r5, [r5, #4]
	add	r3, r5
	cmp	r3, r7
	bls.n	.L0801c138
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r3, [r3, #2]
	cmp	r0, r3
	blt.n	.L0801c138
	movw	r7, #0x8350
	movt	r7, #0x2000
	ldrh	r3, [r7, #2]
	ldrh	r7, [r7, #6]
	add	r3, r7
	cmp	r3, r0
	ble.n	.L0801c138
	movw	r4, #0x8350
	movt	r4, #0x2000
	ldr	r3, [r4, #8]
	ldrh	r7, [r4]
	ldrh	r5, [r4, #2]
	ldrh	r4, [r4, #4]
	subs	r5, r1, r5
	muls	r5, r4, r5
	subs	r7, r5, r7
	add	r7, r2
	add.w	r3, r3, r7, lsl #1
	strh.w	r12, [r3, #-2]
	nop
.L0801c138:
	adds	r6, #1
	uxth	r3, r6
	cmp	r3, #4
	it	hi
	movhi	r6, #0
	uxth	r3, r6
	cmp	r3, #2
	bhi.w	.L0801bfd4
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r3, [r3]
	cmp	r2, r3
	bcc.w	.L0801bfd4
	movw	r7, #0x8350
	movt	r7, #0x2000
	ldrh	r3, [r7]
	ldrh	r7, [r7, #4]
	add	r3, r7
	cmp	r3, r2
	bls.w	.L0801bfd4
	movw	r3, #0x8350
	movt	r3, #0x2000
	ldrh	r3, [r3, #2]
	cmp	r0, r3
	blt.w	.L0801bfd4
	movw	r7, #0x8350
	movt	r7, #0x2000
	ldrh	r3, [r7, #2]
	ldrh	r7, [r7, #6]
	add	r3, r7
	cmp	r3, r0
	ble.w	.L0801bfd4
	movw	r4, #0x8350
	movt	r4, #0x2000
	ldr	r3, [r4, #8]
	ldrh	r7, [r4]
	ldrh	r5, [r4, #2]
	ldrh	r4, [r4, #4]
	subs	r5, r1, r5
	muls	r5, r4, r5
	subs	r7, r5, r7
	add	r7, r2
	strh.w	r12, [r3, r7, lsl #1]
	b.n	.L0801bfd4
.L0801c1b0:
	movw	r8, #0xf8
	movt	r8, #0x2000
	ldrb.w	r0, [r8, #0x16]
	movw	r3, #0xaaab
	add	r0, r8
	ldrb	r1, [r0, #2]
	movt	r3, #0xaaaa
	uxtb	r2, r1
	umull	r2, r3, r2, r3
	ldrsh.w	r2, [r8, #0x1c]
	ldrsb.w	r0, [r0, #4]
	lsrs	r4, r3, #1
	subs	r0, r2, r0
	vmov	s0, r0
	sub.w	r0, r4, r4, lsl #2
	add	r0, r1
	movw	r1, #:lower16:d_0804bfb8
	uxtb	r0, r0
	movt	r1, #:upper16:d_0804bfb8
	ldrh.w	r0, [r1, r0, lsl #1]
	vcvt.f32.s32	s18, s0
	bl	u32_to_double
	mov	r5, r0
	mov	r0, r4
	mov	r6, r1
	bl	u32_to_double
	vldr	d8, .L0801c328
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r5
	mov	r3, r6
	bl	double_mul
	ldrb.w	r2, [r8, #0x16]
	mov	r4, r0
	add.w	r0, r8, r2
	ldrb	r0, [r0, #6]
	mov	r5, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r2, r3, d0
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	vldr	d0, .L0801c330
	vmov	r2, r3, d0
	bl	double_div
	mov	r4, r0
	vmov	r0, s18
	mov	r5, r1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	bl	double_to_float
	vldr	s0, .L0801bfd0
	vmov	s2, r0
	vabs.f32	s6, s2
	vdiv.f32	s4, s2, s0
	vcmp.f32	s6, s0
	adr.w	r0, .L0801caa0
	adr.w	r4, .L0801caa8
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s2
	it	lt
	movlt	r4, r0
	vmov	r0, s4
	bl	float_to_double
	movw	r5, #0x8360
	movt	r5, #0x2000
	mov	r2, r0
	mov	r3, r1
	mov	r0, r5
	mov	r1, r4
	bl	format_to_buffer_080073b4
	sub.w	r0, r9, #0xa
	cmp.w	r9, #0xd6
	it	gt
	movgt	r0, #0xca
	movw	r2, #0x1144
	cmp.w	r9, #0x1e
	it	lt
	movlt	r0, #0x14
	movs	r1, #2
	movt	r2, #0x2000
	strd	r5, r2, [sp]
	str	r1, [sp, #0xc]
	sxth	r1, r0
	movs	r0, #0xa0
	movs	r2, #0x7d
	movs	r3, #0x14
	movw	r7, #0xffff
	mov	r9, r8
	str	r7, [sp, #8]
	bl	draw_wrapped_text_in_box
	ldrb.w	r0, [r8, #0x34]
.L0801c2fc:
	ldrh.w	r1, [r9, #0x28]
	cmp	r1, #0
	beq.w	.L0801c68c
	cmp	r0, #0
	bne.w	.L0801c68c
	ldrh.w	r0, [r9, #0x1a]
	movw	r6, #0x8350
	adds	r0, #0x9f
	sxth	r0, r0
	movs	r3, #0
	movs	r1, #0x1f
	movw	r2, #0x7e2
	movt	r6, #0x2000
	b.n	.L0801c354
	.byte	0x00, 0xbf	@ padding (never reached)
.L0801c328:
	.word	0x00000000, 0x40240000	@ double 10.0
.L0801c330:
	.word	0x00000000, 0x408f4000	@ double 1000.0
.L0801c338:
	.word	0x00000000, 0x40040000	@ double 2.5
.L0801c340:
	.word	0x00000000, 0x00000000	@ double 0.0
.L0801c348:
	adds	r3, #1
	uxth	r7, r3
	cmp	r7, #4
	it	hi
	movhi	r3, #0
	adds	r1, #4
.L0801c354:
	uxth	r7, r3
	cmp	r7, #2
	bhi.n	.L0801c3ec
	ldrh	r7, [r6]
	cmp	r0, r7
	blt.n	.L0801c3ec
	ldrh	r7, [r6]
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r6, [r6, #4]
	add	r7, r6
	movw	r6, #0x8350
	movt	r6, #0x2000
	cmp	r7, r0
	ble.n	.L0801c3ec
	movw	r7, #0x8350
	movt	r7, #0x2000
	ldrh	r6, [r7, #2]
	subs	r7, r1, #3
	cmp	r7, r6
	movw	r6, #0x8350
	movt	r6, #0x2000
	bcc.n	.L0801c3ec
	movw	r6, #0x8350
	movw	r5, #0x8350
	movt	r6, #0x2000
	movt	r5, #0x2000
	ldrh	r6, [r6, #2]
	ldrh	r5, [r5, #6]
	add	r6, r5
	cmp	r6, r7
	movw	r6, #0x8350
	movt	r6, #0x2000
	bls.n	.L0801c3ec
	ldr	r7, [r6, #8]
	movw	r6, #0x8350
	movw	r5, #0x8350
	movt	r6, #0x2000
	movt	r5, #0x2000
	ldrh	r6, [r6]
	ldrh	r5, [r5, #2]
	movw	r4, #0x8350
	movt	r4, #0x2000
	subs	r5, r1, r5
	ldrh	r4, [r4, #4]
	subs	r6, r0, r6
	subs	r5, #3
	mla	r6, r5, r4, r6
	strh.w	r2, [r7, r6, lsl #1]
	movw	r6, #0x8350
	movt	r6, #0x2000
	nop
.L0801c3ec:
	adds	r3, #1
	uxth	r7, r3
	cmp	r7, #4
	it	hi
	movhi	r3, #0
	cmp	r1, #0xdf
	beq.w	.L0801c5c4
	uxth	r7, r3
	cmp	r7, #2
	bhi.n	.L0801c494
	ldrh	r7, [r6]
	cmp	r0, r7
	blt.n	.L0801c494
	ldrh	r7, [r6]
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r6, [r6, #4]
	add	r7, r6
	movw	r6, #0x8350
	movt	r6, #0x2000
	cmp	r7, r0
	ble.n	.L0801c494
	movw	r7, #0x8350
	movt	r7, #0x2000
	ldrh	r6, [r7, #2]
	subs	r7, r1, #2
	cmp	r7, r6
	movw	r6, #0x8350
	movt	r6, #0x2000
	bcc.n	.L0801c494
	movw	r6, #0x8350
	movw	r5, #0x8350
	movt	r6, #0x2000
	movt	r5, #0x2000
	ldrh	r6, [r6, #2]
	ldrh	r5, [r5, #6]
	add	r6, r5
	cmp	r6, r7
	movw	r6, #0x8350
	movt	r6, #0x2000
	bls.n	.L0801c494
	ldr	r7, [r6, #8]
	movw	r6, #0x8350
	movw	r5, #0x8350
	movt	r6, #0x2000
	movt	r5, #0x2000
	ldrh	r6, [r6]
	ldrh	r5, [r5, #2]
	movw	r4, #0x8350
	movt	r4, #0x2000
	subs	r5, r1, r5
	ldrh	r4, [r4, #4]
	subs	r6, r0, r6
	subs	r5, #2
	mla	r6, r5, r4, r6
	strh.w	r2, [r7, r6, lsl #1]
	movw	r6, #0x8350
	movt	r6, #0x2000
	nop
.L0801c494:
	adds	r3, #1
	uxth	r7, r3
	cmp	r7, #4
	it	hi
	movhi	r3, #0
	uxth	r7, r3
	cmp	r7, #2
	bhi.n	.L0801c534
	ldrh	r7, [r6]
	cmp	r0, r7
	blt.n	.L0801c534
	ldrh	r7, [r6]
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r6, [r6, #4]
	add	r7, r6
	movw	r6, #0x8350
	movt	r6, #0x2000
	cmp	r7, r0
	ble.n	.L0801c534
	movw	r7, #0x8350
	movt	r7, #0x2000
	ldrh	r6, [r7, #2]
	subs	r7, r1, #1
	cmp	r7, r6
	movw	r6, #0x8350
	movt	r6, #0x2000
	bcc.n	.L0801c534
	movw	r6, #0x8350
	movw	r5, #0x8350
	movt	r6, #0x2000
	movt	r5, #0x2000
	ldrh	r6, [r6, #2]
	ldrh	r5, [r5, #6]
	add	r6, r5
	cmp	r6, r7
	movw	r6, #0x8350
	movt	r6, #0x2000
	bls.n	.L0801c534
	ldr	r7, [r6, #8]
	movw	r6, #0x8350
	movw	r5, #0x8350
	movt	r6, #0x2000
	movt	r5, #0x2000
	ldrh	r6, [r6]
	ldrh	r5, [r5, #2]
	movw	r4, #0x8350
	movt	r4, #0x2000
	mvns	r5, r5
	ldrh	r4, [r4, #4]
	subs	r6, r0, r6
	add	r5, r1
	mla	r6, r5, r4, r6
	strh.w	r2, [r7, r6, lsl #1]
	movw	r6, #0x8350
	movt	r6, #0x2000
.L0801c534:
	adds	r3, #1
	uxth	r7, r3
	cmp	r7, #4
	it	hi
	movhi	r3, #0
	uxth	r7, r3
	cmp	r7, #2
	bhi.w	.L0801c348
	ldrh	r7, [r6]
	cmp	r0, r7
	blt.w	.L0801c348
	ldrh	r7, [r6]
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r6, [r6, #4]
	add	r7, r6
	movw	r6, #0x8350
	movt	r6, #0x2000
	cmp	r7, r0
	ble.w	.L0801c348
	ldrh	r7, [r6, #2]
	cmp	r1, r7
	bcc.w	.L0801c348
	ldrh	r7, [r6, #2]
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r6, [r6, #6]
	add	r7, r6
	movw	r6, #0x8350
	movt	r6, #0x2000
	cmp	r7, r1
	bls.w	.L0801c348
	ldr	r7, [r6, #8]
	movw	r6, #0x8350
	movw	r5, #0x8350
	movt	r6, #0x2000
	movt	r5, #0x2000
	movw	r4, #0x8350
	ldrh	r6, [r6]
	ldrh	r5, [r5, #2]
	movt	r4, #0x2000
