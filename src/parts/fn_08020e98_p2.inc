@ fn_08020e98_p2.inc - part 2 of 4 of fn_08020e98 (0x08021e98..0x08022e98, 4096 bytes)
@ Fragment included by part 1: continues the instructions of the scope
@ acquisition function in module scope_acq. It holds branch targets of the
@ other parts (.L08021ea6 .L08021eda .L08021ee0 .L08021ef0 .L08021faa
@ .L08021fbc .L08021fc4 .L080220c8 .L080221be .L080224ac .L080224b2
@ .L080224d4 .L080224e0 .L0802261c .L08022624 .L08022ae4 .L08022e88
@ .L08022e90) and calls fir_filter_rows, zero_bytes and fn_08008c60.
	cmp	r7, #1
	lsr.w	r2, r4, #1
	bne.n	.L08021ec4
	cmp	r3, #0
	bne.n	.L08021dd4
	b.n	.L08021ebc
.L08021ea6:
	ldrb.w	r7, [r10, #0x16]
	uxth	r4, r2
	cmp.w	r0, r4, lsr #10
	it	ne
	subwne	r2, r3, #0x407
	lsls	r3, r7, #10
	uxtah	r2, r3, r2
.L08021ebc:
	add	r2, r10
	ldrb.w	r2, [r2, #0x5b0]
	b.n	.L08021de0
.L08021ec4:
	cbnz	r3, .L08021ed2
	add	r2, r10
	ldrb.w	r2, [r2, #0x5b0]
	ldrb.w	r3, [r10, #0x351]
	b.n	.L08021dde
.L08021ed2:
	add	r2, r10
	ldrb.w	r2, [r2, #0x9b0]
	b.n	.L08021de0
.L08021eda:
	ldr.w	lr, [sp, #0x38]
	b.n	.L080221ca
.L08021ee0:
	cmp	r0, #0xff
	bne.n	.L08021f78
	ldrb.w	r0, [r10, #0x32]
	cmp	r0, #0xc8
	bhs.n	.L08021f82
	b.w	.L08022ae4
.L08021ef0:
	mov	r0, r9
	mov	r1, r5
	movs	r2, #0x19
	mov	r3, r6
	bl	fir_filter_rows
	cmp	r6, #0
	beq.w	.L080227ba
	ldrb.w	r3, [r10, #0x18]
	ldrb.w	r0, [r10, #0xdc6]
	cmp	r3, #0
	eor	r1, r0, #0x80
	beq.w	.L0802262c
	cmp	r3, #2
	bne.w	.L08022692
	movs	r0, #0
	b.n	.L08021f26
.L08021f1e:
	adds	r0, #1
	cmp	r6, r0
	beq.w	.L080227ba
.L08021f26:
	ldrb.w	r2, [r9, r0]
	cmp	r2, r1
	bhi.n	.L08021f3a
	add.w	r3, r9, r0
	ldrb	r3, [r3, #1]
	cmp	r3, r1
	bhi.w	.L08022890
.L08021f3a:
	cmp	r2, r1
	blo.n	.L08021f1e
	add.w	r2, r9, r0
	ldrb	r2, [r2, #1]
	cmp	r2, r1
	bhs.n	.L08021f1e
	b.w	.L08022890
	ldrb.w	r0, [r10, #0x32]
	cmp	r0, #0x64
	blo.w	.L08022ae4
	ldrb.w	r0, [r10, #0x16]
	add.w	r0, r0, r0, lsl #1
	add.w	r0, r10, r0, lsl #4
	ldr	r1, [r0, #0x50]
	movw	r0, #0xc37f
	movt	r0, #0x1c9
	cmp	r1, r0
	ble.w	.L0802260a
	movs	r0, #0
	b.w	.L0802297c
.L08021f78:
	ldrb.w	r0, [r10, #0x32]
	cmp	r0, #0x28
	blo.w	.L08022ae4
.L08021f82:
	movs	r0, #0
	strb.w	r0, [r10, #0x32]
	bl	fn_08008c60
	b.w	.L08022ae4
	ldrb.w	r0, [r10, #0x32]
	cmp	r0, #0x64
	blo.w	.L08022ae4
	movs	r0, #0
	strb.w	r0, [r10, #0x32]
	movs	r0, #0x11
	strb.w	r0, [r10, #0x2f]
	b.w	.L08022ae4
.L08021faa:
	movw	r0, #0x1070
	movt	r0, #0x2000
	ldrb	r1, [r0, #0x10]
	cbz	r1, .L08021fbc
	ldr	r1, [r0, #8]
	subs	r1, r5, r1
	b.n	.L08021d88
.L08021fbc:
	ldr	r1, [r0, #0]
	movs	r0, #0
	blx	r1
	b.n	.L080224b2
.L08021fc4:
	ldr	r2, [sp, #0x2c]
	lsls	r0, r2, #16
	beq.w	.L080226d4
	mov.w	r0, #0xffffffff
	mov	r1, r10
	uxtah	r10, r0, r2
	movw	r0, #0xfffc
	and.w	r6, r2, r0
	ldr	r0, [sp, #0x3c]
	and	r8, r2, #3
	movw	r2, #0x12d
	smlabb	r0, r9, r2, r0
	adds	r7, r1, r0
	ldr	r0, [sp, #0x50]
	lsl.w	r4, r11, #2
	add	r0, r12
	str	r0, [sp, #0x54]
	b.n	.L0802201c
.L08021ffa:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xdbf]
	mov	r1, r9
	add.w	r1, r9, #1
	and	r0, r0, #0xf
	mov	r9, r1
	cmp	r1, r0
	addw	r7, r7, #0x12d
	bhs.w	.L080221be
.L0802201c:
	ldr	r3, [sp, #0x30]
	mov	r0, r12
	mov	r1, lr
	mov	r2, r5
	bl	fir_filter_rows
	movs	r0, #0
	cmp.w	r10, #3
	blo.n	.L0802205e
	ldr	r1, [sp, #0x54]
	nop
.L08022034:
	ldrb	r2, [r1, #0]
	adds	r3, r7, r0
	strb.w	r2, [r3, #0x356]
	ldrb.w	r2, [r1, r11]
	adds	r0, #4
	strb.w	r2, [r3, #0x357]
	ldrb.w	r2, [r1, r11, lsl #1]
	cmp	r6, r0
	strb.w	r2, [r3, #0x358]
	add.w	r2, r11, r11, lsl #1
	ldrb	r2, [r1, r2]
	add	r1, r4
	strb.w	r2, [r3, #0x359]
	bne.n	.L08022034
.L0802205e:
	ldrd	r12, lr, [sp, #0x34]
	cmp.w	r8, #0
	beq.n	.L08021ffa
	ldr	r1, [sp, #0x50]
	movw	r3, #0x12d
	mla	r1, r0, r11, r1
	cmp.w	r8, #1
	ldrb.w	r2, [r12, r1]
	movw	r1, #0xf8
	movt	r1, #0x2000
	mla	r1, r9, r3, r1
	ldr	r3, [sp, #0x3c]
	add	r3, r0
	add	r3, r1
	strb.w	r2, [r3, #0x356]
	beq.n	.L08021ffa
	ldr	r3, [sp, #0x50]
	adds	r2, r0, #1
	mla	r3, r2, r11, r3
	ldr	r5, [sp, #0x3c]
	ldrb.w	r3, [r12, r3]
	add	r2, r5
	ldr	r5, [sp, #0x4c]
	add	r2, r1
	cmp.w	r8, #2
	strb.w	r3, [r2, #0x356]
	beq.n	.L08021ffa
	ldr	r2, [sp, #0x50]
	adds	r0, #2
	mla	r2, r0, r11, r2
	ldr	r3, [sp, #0x3c]
	ldrb.w	r2, [r12, r2]
	add	r0, r3
	add	r0, r1
	strb.w	r2, [r0, #0x356]
	b.n	.L08021ffa
.L080220c8:
	ldr	r0, [sp, #0x2c]
	lsls	r0, r0, #16
	beq.w	.L080226f8
	ldr	r0, [sp, #0x3c]
	mov	r1, r10
	movw	r10, #0x12d
	mov	r2, r6
	smlabb	r0, r9, r10, r0
	subs	r5, r4, #1
	and	r8, r4, #3
	bic	r6, r4, #3
	adds	r7, r1, r0
	add.w	r0, r12, r2
	lsl.w	r4, r11, #2
	str	r2, [sp, #0x18]
	str	r0, [sp, #0x54]
	b.n	.L08022114
.L080220f8:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xdbf]
	add.w	r9, r9, #1
	and	r0, r0, #0xf
	cmp	r9, r0
	addw	r7, r7, #0x12d
	bhs.n	.L080221be
.L08022114:
	ldr	r2, [sp, #0x20]
	ldr	r3, [sp, #0x30]
	mov	r0, r12
	mov	r1, lr
	bl	fir_filter_rows
	movs	r0, #0
	cmp	r5, #3
	blo.n	.L08022152
.L08022126:
	ldr	r1, [sp, #0x54]
.L08022128:
	ldrb	r2, [r1, #0]
	adds	r3, r7, r0
	strb.w	r2, [r3, #0x356]
	ldrb.w	r2, [r1, r11]
	adds	r0, #4
	strb.w	r2, [r3, #0x357]
	ldrb.w	r2, [r1, r11, lsl #1]
	cmp	r6, r0
	strb.w	r2, [r3, #0x358]
	add.w	r2, r11, r11, lsl #1
	ldrb	r2, [r1, r2]
	add	r1, r4
	strb.w	r2, [r3, #0x359]
	bne.n	.L08022128
.L08022152:
	ldrd	r12, lr, [sp, #0x34]
	cmp.w	r8, #0
	beq.n	.L080220f8
	ldr	r1, [sp, #0x18]
	ldr	r3, [sp, #0x3c]
	mla	r1, r0, r11, r1
	add	r3, r0
	ldrb.w	r2, [r12, r1]
	movw	r1, #0xf8
	movt	r1, #0x2000
	mla	r1, r9, r10, r1
	cmp.w	r8, #1
	add	r3, r1
	strb.w	r2, [r3, #0x356]
	beq.n	.L080220f8
	ldr	r3, [sp, #0x18]
	adds	r2, r0, #1
	mla	r3, r2, r11, r3
	mov	r10, r5
	ldr	r5, [sp, #0x3c]
	ldrb.w	r3, [r12, r3]
	add	r2, r5
	mov	r5, r10
	movw	r10, #0x12d
	add	r2, r1
	cmp.w	r8, #2
	strb.w	r3, [r2, #0x356]
	beq.n	.L080220f8
	ldr	r2, [sp, #0x18]
	adds	r0, #2
	mla	r2, r0, r11, r2
	ldr	r3, [sp, #0x3c]
	ldrb.w	r2, [r12, r2]
	add	r0, r3
	add	r0, r1
	strb.w	r2, [r0, #0x356]
	b.n	.L080220f8
.L080221be:
	movw	r10, #0xf8
	ldr.w	r8, [sp, #0x24]
.L080221c6:
	movt	r10, #0x2000
.L080221ca:
	movw	r4, #0x1070
	movt	r4, #0x2000
	ldrb	r0, [r4, #0x10]
	cbz	r0, .L08022200
	ldr	r5, [r4, #8]
	sub.w	r0, r12, r5
	cmp.w	r0, #0x2bc00
	bhs.n	.L080221fa
	ldr	r2, [r4, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cbz	r1, .L080221fa
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	mov	r6, lr
	bl	zero_bytes
	mov	lr, r6
.L080221fa:
	sub.w	r0, lr, r5
	b.n	.L08022210
.L08022200:
	ldr	r1, [r4, #0]
	movs	r0, #0
	mov	r5, lr
	blx	r1
	ldrb	r0, [r4, #0x10]
	cbz	r0, .L0802222c
	ldr	r0, [r4, #8]
	subs	r0, r5, r0
.L08022210:
	lsrs	r1, r0, #10
	cmp	r1, #0xae
	bhi.n	.L08022232
	ldr	r2, [r4, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cbz	r1, .L08022232
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	bl	zero_bytes
	b.n	.L08022232
.L0802222c:
	ldr	r1, [r4, #0]
	movs	r0, #0
	blx	r1
.L08022232:
	ldrb.w	r0, [r10, #0xdc0]
	cmp	r0, #3
	bhi.w	.L080223ae
	bne.n	.L08022248
	ldrb.w	r0, [r10, #0xdbe]
	cmp	r0, #3
	bne.w	.L080223ae
.L08022248:
	ldrb.w	r0, [r10, #0xdbf]
	and	r1, r0, #0xf
	cmp.w	r1, r0, lsr #4
	bls.w	.L080223ae
	lsrs	r4, r0, #4
	movw	r5, #0x12d
	smlabb	r0, r4, r5, r10
	addw	r6, r0, #0x36f
	b.n	.L0802227c
.L08022268:
	ldrb.w	r0, [r10, #0xdbf]
	adds	r4, #1
	and	r0, r0, #0xf
	cmp	r4, r0
	addw	r6, r6, #0x12d
	bhs.w	.L080223ae
.L0802227c:
	add.w	r0, r10, r4, lsl #2
	ldr.w	r1, [r0, #0xdfc]
	cmp	r1, #0
	bne.n	.L08022268
	addw	r7, r0, #0xdfc
	movw	r0, #0x12d
	bl	alloc_units_of_32_bytes
	cmp	r0, #0
	str	r0, [r7, #0]
	beq.n	.L08022268
	mla	r1, r4, r5, r10
	ldrb.w	r1, [r1, #0x356]
	strb	r1, [r0, #0]
	movs	r0, #0
	nop
.L080222a8:
	ldr	r2, [r7, #0]
	adds	r1, r6, r0
	ldrb.w	r3, [r1, #-0x18]
	add	r2, r0
	strb	r3, [r2, #1]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x17]
	add	r2, r0
	strb	r3, [r2, #2]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x16]
	add	r2, r0
	strb	r3, [r2, #3]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x15]
	add	r2, r0
	strb	r3, [r2, #4]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x14]
	add	r2, r0
	strb	r3, [r2, #5]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x13]
	add	r2, r0
	strb	r3, [r2, #6]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x12]
	add	r2, r0
	strb	r3, [r2, #7]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x11]
	add	r2, r0
	strb	r3, [r2, #8]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x10]
	add	r2, r0
	strb	r3, [r2, #9]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0xf]
	add	r2, r0
	strb	r3, [r2, #0xa]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0xe]
	add	r2, r0
	strb	r3, [r2, #0xb]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0xd]
	add	r2, r0
	strb	r3, [r2, #0xc]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0xc]
	add	r2, r0
	strb	r3, [r2, #0xd]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0xb]
	add	r2, r0
	strb	r3, [r2, #0xe]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0xa]
	add	r2, r0
	strb	r3, [r2, #0xf]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x9]
	add	r2, r0
	strb	r3, [r2, #0x10]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x8]
	add	r2, r0
	strb	r3, [r2, #0x11]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x7]
	add	r2, r0
	strb	r3, [r2, #0x12]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x6]
	add	r2, r0
	strb	r3, [r2, #0x13]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x5]
	add	r2, r0
	strb	r3, [r2, #0x14]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x4]
	add	r2, r0
	strb	r3, [r2, #0x15]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x3]
	add	r2, r0
	strb	r3, [r2, #0x16]
	ldr	r2, [r7, #0]
	ldrb.w	r3, [r1, #-0x2]
	add	r2, r0
	strb	r3, [r2, #0x17]
	ldr	r2, [r7, #0]
	ldrb.w	r1, [r1, #-0x1]
	add	r2, r0
	strb	r1, [r2, #0x18]
	ldr	r1, [r7, #0]
	ldrb	r2, [r6, r0]
	add	r1, r0
	adds	r0, #0x19
	cmp.w	r0, #0x12c
	strb	r2, [r1, #0x19]
	bne.w	.L080222a8
	b.n	.L08022268
.L080223ae:
	ldrb.w	r0, [r10, #0xdbf]
	ldr	r2, [sp, #0x2c]
	and	r1, r0, #0xf
	cmp.w	r1, r0, lsr #4
	mov	r11, r10
	bls.n	.L080224ac
	movw	r1, #0xffff
	tst	r2, r1
	beq.n	.L080224ac
	ldr	r1, [sp, #0x3c]
	movw	lr, #:lower16:d_080465cc
	vldr	s0, .L0802273c
	vldr	s2, .L08022740
	vldr	s4, .L08022744
	lsrs	r0, r0, #4
	uxtah	r1, r1, r2
	movt	lr, #:upper16:d_080465cc
	movw	r12, #0x12d
	vmov.f32	s6, #28.0
	b.n	.L080223fc
.L080223ee:
	ldrb.w	r2, [r11, #0xdbf]
	adds	r0, #1
	and	r2, r2, #0xf
	cmp	r0, r2
	bhs.n	.L080224ac
.L080223fc:
	add.w	r5, r11, r0
	ldrb	r4, [r5, #2]
	addw	r7, r5, #0xdc1
	addw	r6, r5, #0xdc3
	ldrh.w	r4, [lr, r4, lsl #1]
	ldrsb.w	r5, [r5, #4]
	vmov	s8, r4
	vmov	s10, r5
	ldr	r4, [sp, #0x3c]
	vcvt.f32.u32	s8, s8
	vcvt.f32.s32	s10, s10
	mov	r5, r8
	b.n	.L0802243e
.L08022428:
	adds	r5, #1
	addw	r3, r4, #0x356
	vcvt.s32.f32	s12, s12
	uxth	r4, r5
	vmov	r2, s12
	cmp	r1, r4
	strb	r2, [r3, #0]
	bls.n	.L080223ee
.L0802243e:
	ldrb	r3, [r7, #0]
	ldrh.w	r3, [lr, r3, lsl #1]
	vmov	s12, r3
	vcvt.f32.u32	s12, s12
	vdiv.f32	s12, s12, s8
	mla	r3, r0, r12, r11
	add	r4, r3
	ldrb.w	r3, [r4, #0x356]
	vmov	s14, r3
	ldrsb.w	r3, [r6, #0]
	vcvt.f32.u32	s14, s14
	vmov	s1, r3
	vadd.f32	s14, s14, s0
	vcvt.f32.s32	s1, s1
	vsub.f32	s14, s14, s1
	vmul.f32	s12, s12, s14
	vadd.f32	s12, s12, s2
	vadd.f32	s12, s12, s1
	vadd.f32	s12, s12, s10
	vsub.f32	s14, s12, s1
	vcmp.f32	s14, s4
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s12, s4
	bgt.n	.L08022428
	vcmp.f32	s14, s6
	vmov.f32	s12, s14
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s12, s6
	b.n	.L08022428
.L080224ac:
	bl	compute_math_trace
	mov	r10, r11
.L080224b2:
	ldrb.w	r0, [r10, #0xf68]
	cmp	r0, #2
	bne.n	.L080224d4
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movs	r1, #3
	ldr	r0, [r0, #0]
	strb.w	r1, [sp, #0x58]
	add	r1, sp, #0x58
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
.L080224d4:
	add	sp, #0x60
	vpop	{d8, d9, d10, d11, d12, d13, d14, d15}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080224e0:
	and	r1, r5, #0xfc
	add.w	r0, r0, r9, lsl #10
	and	r12, r5, #3
	str	r1, [sp, #0x50]
	mov	r1, r9
	addw	r11, r0, #0x12d
	addw	r8, r0, #0x12f
	add.w	r9, lr, #1
	mov	lr, r0
	b.n	.L0802252a
.L08022500:
	ldr	r2, [sp, #0x4c]
	ldr	r3, [sp, #0x30]
	mov	r4, r12
	bl	fir_filter_rows
	ldrb.w	r0, [r10, #0xdbf]
	ldr	r1, [sp, #0x54]
	and	r0, r0, #0xf
	adds	r1, #1
	mov	lr, r7
	mov	r12, r4
	add.w	lr, r7, #0x400
	add.w	r11, r11, #0x400
	cmp	r1, r0
	add.w	r8, r8, #0x400
	bhs.n	.L080225fc
.L0802252a:
	ldr	r0, [sp, #0x48]
	movw	r10, #0xf8
	movs	r5, #0
	movt	r10, #0x2000
	cmp	r0, #3
	str	r1, [sp, #0x54]
	bhs.n	.L08022542
	ldrd	r0, r1, [sp, #0x34]
	b.n	.L0802259e
.L08022542:
	ldrd	r0, r1, [sp, #0x34]
	ldr	r7, [sp, #0x50]
.L08022548:
	add.w	r4, lr, r5
	mov	r2, r4
	cmp.w	r4, #0xffffffff
	it	le
	addle.w	r2, r11, r5
	add.w	r3, r10, #0x5b0
	ldrb	r2, [r3, r2]
	add.w	r6, r9, r5
	strb.w	r2, [r6, #-0x1]
	adds	r2, r4, #1
	cmp.w	r2, #0xffffffff
	it	le
	addle.w	r2, r4, #0x12e
	ldrb	r2, [r3, r2]
	strb.w	r2, [r9, r5]
	adds	r2, r4, #2
	cmp.w	r2, #0xffffffff
	it	le
	addle.w	r2, r8, r5
	ldrb	r2, [r3, r2]
	adds	r5, #4
	strb	r2, [r6, #1]
	adds	r2, r4, #3
	cmp.w	r2, #0xffffffff
	it	le
	addle.w	r2, r4, #0x130
	ldrb	r2, [r3, r2]
	cmp	r7, r5
	strb	r2, [r6, #2]
	bne.n	.L08022548
.L0802259e:
	mov	r7, lr
	cmp.w	r12, #0
	beq.n	.L08022500
	ldr	r2, [sp, #0x54]
	ldr	r3, [sp, #0x40]
	add.w	r6, r3, r2, lsl #10
	adds	r2, r5, r6
	cmp.w	r2, #0xffffffff
	it	le
	addwle	r2, r2, #0x12d
	add	r2, r10
	ldrb.w	r2, [r2, #0x5b0]
	cmp.w	r12, #1
	strb	r2, [r1, r5]
	beq.n	.L08022500
	adds	r2, r5, #1
	adds	r3, r2, r6
	cmp.w	r3, #0xffffffff
	it	le
	addwle	r3, r3, #0x12d
	add	r3, r10
	ldrb.w	r3, [r3, #0x5b0]
	cmp.w	r12, #2
	strb	r3, [r1, r2]
	beq.n	.L08022500
	adds	r3, r5, #2
	adds	r2, r3, r6
	cmp.w	r2, #0xffffffff
	it	le
	addwle	r2, r2, #0x12d
	add	r2, r10
	ldrb.w	r2, [r2, #0x5b0]
	strb	r2, [r1, r3]
	b.n	.L08022500
.L080225fc:
	movw	r10, #0xf8
	ldr.w	r8, [sp, #0x24]
	ldrd	r12, lr, [sp, #0x34]
	b.n	.L080221c6
.L0802260a:
	movw	r0, #0x967f
	movt	r0, #0x98
	cmp	r1, r0
	ble.w	.L0802271c
	movs	r0, #1
	b.n	.L0802297c
.L0802261c:
	lsls.w	r0, r12, #31
	beq.w	.L08022ae4
.L08022624:
	movs	r0, #2
	strb.w	r0, [r10, #0x2f]
	b.n	.L08022ae4
.L0802262c:
	rsbs	r2, r6, #0
	movs	r0, #0
	b.n	.L0802263a
.L08022632:
	adds	r0, #4
	adds	r3, r2, r0
	beq.w	.L080227ba
.L0802263a:
	ldrb.w	r3, [r9, r0]
	cmp	r3, r1
	bhi.n	.L0802264e
	add.w	r3, r9, r0
	ldrb	r3, [r3, #1]
	cmp	r3, r1
	bhi.w	.L08022890
.L0802264e:
	adds	r7, r2, r0
	adds	r3, r7, #1
	beq.w	.L080227ba
	add.w	r3, r9, r0
	ldrb	r4, [r3, #1]
	cmp	r4, r1
	bhi.n	.L08022668
	ldrb	r4, [r3, #2]
	cmp	r4, r1
	bhi.w	.L08022846
.L08022668:
	adds	r4, r7, #2
	beq.w	.L080227ba
	ldrb	r4, [r3, #2]
	cmp	r4, r1
	bhi.n	.L0802267c
	ldrb	r4, [r3, #3]
	cmp	r4, r1
	bhi.w	.L0802284a
.L0802267c:
	adds	r7, #3
	beq.w	.L080227ba
	ldrb	r7, [r3, #3]
	cmp	r7, r1
	bhi.n	.L08022632
	ldrb	r3, [r3, #4]
	cmp	r3, r1
	bls.n	.L08022632
.L0802268e:
	adds	r0, #3
	b.n	.L08022890
.L08022692:
	subs	r0, r3, #1
	cmp	r0, #1
	bhi.n	.L0802272c
	movs	r0, #0
	orr	r2, r3, #2
	b.n	.L080226a8
.L080226a0:
	adds	r0, #1
	cmp	r6, r0
	beq.w	.L080227ba
.L080226a8:
	cmp	r2, #2
	bne.n	.L080226c0
	ldrb.w	r3, [r9, r0]
	cmp	r3, r1
	bhi.n	.L080226c4
	add.w	r7, r9, r0
	ldrb	r7, [r7, #1]
	cmp	r7, r1
	bls.n	.L080226c4
	b.n	.L08022890
.L080226c0:
	ldrb.w	r3, [r9, r0]
.L080226c4:
	cmp	r3, r1
	blo.n	.L080226a0
	add.w	r3, r9, r0
	ldrb	r3, [r3, #1]
	cmp	r3, r1
	bhs.n	.L080226a0
	b.n	.L08022890
.L080226d4:
	ldr	r4, [sp, #0x30]
.L080226d6:
	mov	r0, r12
	mov	r1, lr
	mov	r2, r5
	mov	r3, r4
	bl	fir_filter_rows
	ldrb.w	r0, [r10, #0xdbf]
	ldrd	r12, lr, [sp, #0x34]
	add.w	r9, r9, #1
	and	r0, r0, #0xf
	cmp	r9, r0
	blo.n	.L080226d6
	b.n	.L080221ca
.L080226f8:
	ldr	r4, [sp, #0x20]
.L080226fa:
	mov	r0, r12
	mov	r1, lr
	mov	r2, r4
	mov	r3, r5
	bl	fir_filter_rows
	ldrb.w	r0, [r10, #0xdbf]
	ldrd	r12, lr, [sp, #0x34]
	add.w	r9, r9, #1
	and	r0, r0, #0xf
	cmp	r9, r0
	blo.n	.L080226fa
	b.n	.L080221ca
.L0802271c:
	movw	r0, #0x4b3f
	movt	r0, #0x4c
	cmp	r1, r0
	ble.n	.L080227be
	movs	r0, #2
	b.n	.L0802297c
.L0802272c:
	cmp	r3, #0
	beq.n	.L080227ce
	rsb.w	r12, r6, #0
	movs	r0, #0
	orr	r3, r3, #2
	b.n	.L08022754
.L0802273c:
	.word	0xc3000000
.L08022740:
	.word	0x43000000
.L08022744:
	.word	0x43640000
.L08022748:
	.word	0x43480000
.L0802274c:
	adds	r0, #4
	adds.w	r2, r12, r0
	beq.n	.L080227ba
.L08022754:
	cmp	r3, #2
	bne.n	.L0802276c
	ldrb.w	r7, [r9, r0]
	cmp	r7, r1
	bhi.n	.L0802276c
	add.w	r7, r9, r0
	ldrb	r7, [r7, #1]
	cmp	r7, r1
	bhi.w	.L08022890
.L0802276c:
	add.w	r7, r12, r0
	adds	r4, r7, #1
	beq.n	.L080227ba
	cmp	r3, #2
	bne.n	.L08022788
	add.w	r4, r9, r0
	ldrb	r2, [r4, #1]
	cmp	r2, r1
	bhi.n	.L08022788
	ldrb	r2, [r4, #2]
	cmp	r2, r1
	bhi.n	.L08022846
.L08022788:
	adds	r2, r7, #2
	beq.n	.L080227ba
	cmp	r3, #2
	bne.n	.L080227a0
	add.w	r4, r9, r0
	ldrb	r2, [r4, #2]
	cmp	r2, r1
	bhi.n	.L080227a0
	ldrb	r2, [r4, #3]
	cmp	r2, r1
	bhi.n	.L0802284a
.L080227a0:
	adds	r2, r7, #3
	beq.n	.L080227ba
	cmp	r3, #2
	bne.n	.L0802274c
	add.w	r7, r9, r0
	ldrb	r2, [r7, #3]
	cmp	r2, r1
	bhi.n	.L0802274c
	ldrb	r2, [r7, #4]
	cmp	r2, r1
	bls.n	.L0802274c
	b.n	.L0802268e
.L080227ba:
	ldr	r6, [sp, #0x54]
	b.n	.L08022896
.L080227be:
	movw	r0, #0xc6bf
	movt	r0, #0x2d
	cmp	r1, r0
	ble.n	.L08022826
	movs	r0, #3
	b.n	.L0802297c
.L080227ce:
	rsbs	r2, r6, #0
	movs	r0, #0
	b.n	.L080227da
.L080227d4:
	adds	r0, #4
	adds	r3, r2, r0
	beq.n	.L08022836
.L080227da:
	ldrb.w	r3, [r9, r0]
	cmp	r3, r1
	bhi.n	.L080227ec
	add.w	r3, r9, r0
	ldrb	r3, [r3, #1]
	cmp	r3, r1
	bhi.n	.L08022884
.L080227ec:
	adds	r7, r2, r0
	adds	r3, r7, #1
	beq.n	.L08022836
	add.w	r3, r9, r0
	ldrb	r4, [r3, #1]
	cmp	r4, r1
	bhi.n	.L08022802
	ldrb	r4, [r3, #2]
	cmp	r4, r1
	bhi.n	.L0802287e
.L08022802:
	adds	r4, r7, #2
	beq.n	.L08022836
	ldrb	r4, [r3, #2]
	cmp	r4, r1
	bhi.n	.L08022812
	ldrb	r4, [r3, #3]
	cmp	r4, r1
	bhi.n	.L08022882
.L08022812:
	adds	r7, #3
	beq.n	.L08022836
	ldrb	r7, [r3, #3]
	cmp	r7, r1
	bhi.n	.L080227d4
	ldrb	r3, [r3, #4]
	cmp	r3, r1
	bls.n	.L080227d4
	adds	r0, #3
	b.n	.L08022884
.L08022826:
	movw	r0, #0x423f
	movt	r0, #0xf
	cmp	r1, r0
	ble.n	.L0802284e
	movs	r0, #4
	b.n	.L08022974
.L08022836:
	movw	r10, #0xf8
	ldr.w	r8, [sp, #0x24]
	ldr	r6, [sp, #0x54]
	movt	r10, #0x2000
	b.n	.L08022896
.L08022846:
	adds	r0, #1
	b.n	.L08022890
.L0802284a:
	adds	r0, #2
	b.n	.L08022890
.L0802284e:
	movw	r0, #0xa11f
	movt	r0, #7
	cmp	r1, r0
	ble.n	.L0802285e
	movs	r0, #5
	b.n	.L08022974
.L0802285e:
	movw	r0, #0x93df
	movt	r0, #4
	cmp	r1, r0
	ble.n	.L0802286e
	movs	r0, #6
	b.n	.L08022974
.L0802286e:
	movw	r0, #0x869f
	movt	r0, #1
	cmp	r1, r0
	ble.n	.L08022902
	movs	r0, #7
	b.n	.L08022974
.L0802287e:
	adds	r0, #1
	b.n	.L08022884
.L08022882:
	adds	r0, #2
.L08022884:
	movw	r10, #0xf8
	ldr.w	r8, [sp, #0x24]
	movt	r10, #0x2000
.L08022890:
	ldr	r6, [sp, #0x54]
	uxtab	r6, r6, r0
.L08022896:
	movw	r4, #0x1070
	movt	r4, #0x2000
	ldrb	r0, [r4, #0x10]
	cbz	r0, .L080228c6
	ldr	r7, [r4, #8]
	sub.w	r0, r9, r7
	cmp.w	r0, #0x2bc00
	bhs.n	.L080228c2
	ldr	r2, [r4, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cbz	r1, .L080228c2
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	bl	zero_bytes
.L080228c2:
	subs	r0, r5, r7
	b.n	.L080228d4
.L080228c6:
	ldr	r1, [r4, #0]
	movs	r0, #0
	blx	r1
	ldrb	r0, [r4, #0x10]
	cbz	r0, .L080228f8
	ldr	r0, [r4, #8]
	subs	r0, r5, r0
.L080228d4:
	lsrs	r1, r0, #10
	cmp	r1, #0xae
	bhi.w	.L080219b4
	ldr	r2, [r4, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cmp	r1, #0
	beq.w	.L080219b4
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	bl	zero_bytes
	b.w	.L080219b4
.L080228f8:
	ldr	r1, [r4, #0]
	movs	r0, #0
	blx	r1
	b.w	.L080219b4
.L08022902:
	movw	r0, #0xc34f
	cmp	r1, r0
	ble.n	.L0802290e
	movs	r0, #8
	b.n	.L08022974
.L0802290e:
	movw	r0, #0x752f
	cmp	r1, r0
	ble.n	.L0802291a
	movs	r0, #9
	b.n	.L08022974
.L0802291a:
	movw	r0, #0x270f
	cmp	r1, r0
	ble.n	.L08022926
	movs	r0, #0xa
	b.n	.L08022974
.L08022926:
	movw	r0, #0x1387
	cmp	r1, r0
	ble.n	.L08022932
	movs	r0, #0xb
	b.n	.L08022974
.L08022932:
	movw	r0, #0xbb7
	cmp	r1, r0
	ble.n	.L0802293e
	movs	r0, #0xc
	b.n	.L08022974
.L0802293e:
	cmp.w	r1, #0x3e8
	blt.n	.L08022948
	movs	r0, #0xd
	b.n	.L08022974
.L08022948:
	cmp.w	r1, #0x1f4
	blt.n	.L08022952
	movs	r0, #0xe
	b.n	.L08022974
.L08022952:
	cmp.w	r1, #0x12c
	blt.n	.L0802295c
	movs	r0, #0xf
	b.n	.L08022974
.L0802295c:
	cmp	r1, #0x63
	ble.n	.L08022964
	movs	r0, #0x10
	b.n	.L08022974
.L08022964:
	cmp	r1, #0x31
	ble.n	.L0802296c
	movs	r0, #0x11
	b.n	.L08022974
.L0802296c:
	movs	r0, #0x13
	cmp	r1, #0x1d
	it	gt
	movgt	r0, #0x12
.L08022974:
	movw	r10, #0xf8
	movt	r10, #0x2000
.L0802297c:
	strb.w	r0, [r10, #0x2d]
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movs	r1, #2
	ldr	r0, [r0, #0]
	strb.w	r1, [sp, #0x5d]
	add.w	r1, sp, #0x5d
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movw	r0, #0x2d78
	movt	r0, #0x2000
	movs	r1, #1
	ldr	r0, [r0, #0]
	strb.w	r1, [sp, #0x5c]
	add	r1, sp, #0x5c
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r0, #3
	strb.w	r0, [r10, #0x2f]
	movw	r0, #0x1014
	movt	r0, #0x4001
	movs	r1, #4
	str.w	r1, [r0, #0x3fc]
	bl	fn_08030a70
	ldrb.w	r1, [r10, #0x2d]
	ldrb.w	r0, [r10, #2]
	cmp	r1, #5
	blo.n	.L080229e8
	add.w	r1, r10, r0, lsl #1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L08022a0e
.L080229e8:
	cmp	r1, #4
	beq.n	.L08022a02
	ldrb.w	r1, [r10, #0x14]
	cmp	r1, #3
	beq.n	.L08022a02
	add.w	r1, r10, r0, lsl #1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L08022a0e
.L08022a02:
	add.w	r1, r10, r0, lsl #1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L08022a0e:
	ldrh	r0, [r0, #0]
	ldrh	r1, [r1, #0]
	vldr	s0, .L08022748
	subs	r0, r0, r1
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vdiv.f32	s2, s2, s0
	ldrsb.w	r0, [r10, #4]
	adds	r0, #0x64
	vmov	s4, r0
	vcvt.f32.s32	s4, s4
	movw	r0, #0x7404
	movt	r0, #0x4000
	vmul.f32	s2, s2, s4
	vmov	s4, r1
	vcvt.f32.u32	s4, s4
	vadd.f32	s2, s2, s4
	ldr	r1, [r0, #4]
	vcvt.u32.f32	s2, s2
	vmov	r2, s2
	lsrs	r1, r1, #12
	bfi	r2, r1, #12, #20
	str	r2, [r0, #4]
	ldr	r1, [r0, #0]
	orr	r1, r1, #1
	str	r1, [r0, #0]
	ldrb.w	r1, [r10, #0x2d]
	ldrb.w	r0, [r10, #3]
	cmp	r1, #5
	blo.n	.L08022a7e
	add.w	r1, r10, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L08022aa4
.L08022a7e:
	cmp	r1, #4
	beq.n	.L08022a98
	ldrb.w	r1, [r10, #0x14]
	cmp	r1, #3
	beq.n	.L08022a98
	add.w	r1, r10, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L08022aa4
.L08022a98:
	add.w	r1, r10, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L08022aa4:
	ldrh	r0, [r0, #0]
	ldrh	r1, [r1, #0]
	subs	r0, r0, r1
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vdiv.f32	s0, s2, s0
	ldrsb.w	r0, [r10, #5]
	adds	r0, #0x64
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	movw	r0, #0x1c34
	movt	r0, #0x4000
	vmul.f32	s0, s0, s2
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vcvt.u32.f32	s0, s0
	vstr	s0, [r0]
.L08022ae4:
	ldrb.w	r0, [r10, #0x32]
	mov	r6, r10
	cmp	r0, #0x28
	blo.w	.L080240a4
	ldrb.w	r11, [r6, #0x30]
	cmp.w	r11, #0
	beq.w	.L080240a4
	sub.w	r1, r11, #0x30
	movs	r0, #0
	cmp	r1, #0xa
	strb.w	r0, [r6, #0x32]
	bhs.w	.L08022d78
	ldrb.w	r9, [r6, #0x14]
	vldr	s0, .L08022e68
	mov	r0, r6
	movs	r1, #0
	cmp.w	r9, #1
	it	ne
	addne.w	r0, r0, #0x400
.L08022b22:
	adds	r2, r0, r1
	ldrb.w	r3, [r2, #0x6aa]
	ldrb.w	r7, [r2, #0x6ab]
	vmov	s2, r3
	vcvt.f32.u32	s2, s2
	ldrb.w	r5, [r2, #0x6ac]
	vadd.f32	s0, s0, s2
	vmov	s2, r7
	vcvt.f32.u32	s2, s2
	ldrb.w	r4, [r2, #0x6ad]
	vadd.f32	s0, s0, s2
	vmov	s2, r5
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r4
	ldrb.w	r3, [r2, #0x6ae]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6af]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b0]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b1]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b2]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b3]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b4]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b5]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b6]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b7]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b8]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6b9]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6ba]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6bb]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r3, [r2, #0x6bc]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r3
	ldrb.w	r2, [r2, #0x6bd]
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vmov	s2, r2
	vcvt.f32.u32	s2, s2
	adds	r1, #0x14
	cmp.w	r1, #0x1f4
	vadd.f32	s0, s0, s2
	bne.w	.L08022b22
	vldr	s2, .L08022e6c
	subs.w	r7, r9, #1
	vdiv.f32	s0, s0, s2
	it	ne
	movne	r7, #1
	add.w	r8, r6, r7
	mov	r10, r8
	ldrb.w	r0, [r10, #4]!
	cmp	r0, #0x9c
	bne.n	.L08022cfe
	vmov.f32	s2, #-28.0
	vadd.f32	s16, s0, s2
	vmov	r0, s16
	bl	float_to_double
	vldr	d0, .L08022e70
	mov	r4, r0
	vmov	r2, r3, d0
	mov	r5, r1
	bl	double_ge
	cbnz	r0, .L08022cc0
	vldr	d0, .L08022e78
	mov	r0, r4
	vmov	r2, r3, d0
	mov	r1, r5
	bl	double_ge
	cbnz	r0, .L08022d32
.L08022cc0:
	vcmp.f32	s16, #0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08022d88
	vmov.f32	s0, #1.0
	vcmp.f32	s16, s0
	vmrs	APSR_nzcv, fpscr
	bge.n	.L08022d88
	movw	r2, #0xf8
	rsb	r1, r7, r7, lsl #4
	movt	r2, #0x2000
	and	r0, r11, #0xf
	add.w	r1, r2, r1, lsl #3
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x288]
	subs	r1, #1
	strh.w	r1, [r0, #0x288]
	b.w	.L080238e6
.L08022cfe:
	vldr	s2, .L08022e80
	vadd.f32	s16, s0, s2
	vmov	r0, s16
	bl	float_to_double
	vldr	d0, .L08022e70
	mov	r4, r0
	vmov	r2, r3, d0
	mov	r5, r1
	bl	double_ge
	cbnz	r0, .L08022d3e
	vldr	d0, .L08022e78
	mov	r0, r4
	vmov	r2, r3, d0
	mov	r1, r5
	bl	double_ge
	cbz	r0, .L08022d3e
.L08022d32:
	movw	r2, #0xf8
	movt	r2, #0x2000
	b.w	.L080238e6
.L08022d3e:
	vcmp.f32	s16, #0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08022dca
	vmov.f32	s0, #1.0
	vcmp.f32	s16, s0
	vmrs	APSR_nzcv, fpscr
	bge.n	.L08022dca
	movw	r2, #0xf8
	rsb	r1, r7, r7, lsl #4
	movt	r2, #0x2000
	and	r0, r11, #0xf
	add.w	r1, r2, r1, lsl #3
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x2c4]
	subs	r1, #1
	b.w	.L080238e2
.L08022d78:
	cmp.w	r11, #1
	bne.n	.L08022e08
	movs	r0, #0x10
	strb.w	r0, [r6, #0x30]
	b.w	.L080240a4
.L08022d88:
	vcmp.f32	s16, #0
	vmrs	APSR_nzcv, fpscr
	bge.w	.L080237e0
	vmov.f32	s0, #-1.0
	vcmp.f32	s16, s0
	vmrs	APSR_nzcv, fpscr
	ble.w	.L080237e0
	movw	r2, #0xf8
	rsb	r1, r7, r7, lsl #4
	movt	r2, #0x2000
	and	r0, r11, #0xf
	add.w	r1, r2, r1, lsl #3
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x288]
	adds	r1, #1
	strh.w	r1, [r0, #0x288]
	b.w	.L080238e6
.L08022dca:
	vcmp.f32	s16, #0
	vmrs	APSR_nzcv, fpscr
	bge.w	.L08023826
	vmov.f32	s0, #-1.0
	vcmp.f32	s16, s0
	vmrs	APSR_nzcv, fpscr
	ble.w	.L08023826
	movw	r2, #0xf8
	rsb	r1, r7, r7, lsl #4
	movt	r2, #0x2000
	and	r0, r11, #0xf
	add.w	r1, r2, r1, lsl #3
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x2c4]
	adds	r1, #1
	b.w	.L080238e2
.L08022e08:
	lsls.w	r0, r11, #25
	mov.w	r9, #1
	it	pl
	movpl.w	r9, #2
	cmp.w	r9, r11, lsr #7
	bls.w	.L080240a4
	lsr.w	r7, r11, #7
	ubfx	r0, r11, #5, #1
	movw	r8, #0x7404
	vldr	s16, .L08022e68
	vldr	s18, .L08022e6c
	vldr	d11, .L08022e70
	vldr	d15, .L08022e78
	vldr	s21, .L08022e84
	vldr	s25, .L08022e80
	movt	r8, #0x4000
	str	r0, [sp, #0x54]
	adds	r0, #3
	vmov.f32	s20, #-28.0
	vmov.f32	s24, #1.0
	vmov.f32	s26, #-1.0
	vmov.f32	s28, #1.5
	vmov.f32	s19, #-8.0
	vmov.f32	s17, #-1.5
	mov	r10, r7
	str	r0, [sp, #0x50]
	b.n	.L08022ea6
.L08022e68:
	.word	0x00000000
.L08022e6c:
	.word	0x43fa0000
.L08022e70:
	.word	0x33333333, 0x3fd33333	@ double 0.3
.L08022e78:
	.word	0x9999999a, 0xbfb99999	@ double -0.1
.L08022e80:
	.word	0xc3640000
.L08022e84:
	.word	0x43480000
.L08022e88:
	orr.w	r0, r0, r10, lsl #6
	strb.w	r0, [r4, #0x30]
.L08022e90:
	add.w	r10, r10, #1
	uxtb.w	r7, r10
