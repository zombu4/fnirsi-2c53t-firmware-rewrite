@ fn_08020e98_p3.inc - part 3 of 4 of fn_08020e98 (0x08022e98..0x08023e9a):
@ acquisition-state update blocks working on the RAM structure at 0x200000f8.
@ Included by part 1; no header or section lines. Contents, in address order:
@  - a loop of 25 steps (step 0x14, r1 = 0..0x1e0) that sums 20 bytes per step
@    (offsets 0x6aa..0x6bd) from the row at (r6 + (r10 & 0xff) * 0x400) as
@    floats, then divides the float sum by s18;
@  - float range tests (via float_to_double / double_ge / double_lt) of the
@    value in s27 that select an entry of the u16 tables at 0x260.., 0x274..,
@    0x288.., 0x29c.., 0x2b0.., 0x2c4.., 0x2d8.., 0x2ec.., 0x300.., 0x314..,
@    0x328.., 0x33c.. (offsets from 0x200000f8) and adjust it;
@  - blocks that convert the difference of two table entries to float, scale it
@    and write the result to the registers at 0x40001c34 / 0x40007404 (a
@    float to u32 conversion stored with vstr / bfi), and set bit 0 of the
@    control word at [r8];
@  - queue_send_timeout calls (queue handles at 0x20002d78 and 0x20002d6c) and
@    writes of 4 / 2 to 0x40011010 / 0x40011014 / 0x40011410;
@  - a second pair of loops (20 steps of 0x19, r1 = 0..0x1e0, 25 bytes per
@    step at offsets 0xaaa.. or 0x6aa.. of 0x200000f8, chosen by byte 0x14 == 1)
@    that add the bytes up in r3; the sum is multiplied with smmul by 0x10624dd3,
@    shifted right by 5 (the usual divide-by-1000 sequence), plus 0x1c, and
@    stored to byte 0x350 of the structure at r8;
@  - float constants 200.0 (0x08023d38), 0.3 and -0.1 (doubles), 150.0.
@ Byte 0x30 of the structure is the state byte (low nibble: index, high
@ nibble: flags); byte 0x2d, byte 0x14, bytes 4 and 5 (signed) are read as
@ selectors / offsets exactly as the instructions below show.
	movw	r6, #0xf8
	cmp	r9, r7
	movt	r6, #0x2000		@ r6 = 0x200000f8
	bls.w	.L080240a4
.L08022ea6:
	uxtb.w	r0, r10
	add.w	r0, r6, r0, lsl #10
	movs	r1, #0
	vmov.f32	s0, s16
.L08022eb4:
	adds	r2, r0, r1
	ldrb.w	r3, [r2, #0x6aa]
	ldrb.w	r6, [r2, #0x6ab]
	vmov	s2, r3
	vcvt.f32.u32	s2, s2
	ldrb.w	r5, [r2, #0x6ac]
	vadd.f32	s0, s0, s2
	vmov	s2, r6
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
	bne.w	.L08022eb4
	vdiv.f32	s0, s0, s18
	movw	r0, #0xf8
	movt	r0, #0x2000
	add.w	r11, r0, r7
	ldrb.w	r0, [r11, #4]!
	cmp	r0, #0x9c
	bne.n	.L08023074
	vadd.f32	s27, s0, s20
	vmov	r0, s27
	bl	float_to_double
	vmov	r2, r3, d11
	mov	r6, r0
	mov	r5, r1
	bl	double_ge
	cbnz	r0, .L08023040
	vmov	r2, r3, d15
	mov	r0, r6
	mov	r1, r5
	bl	double_ge
	cbnz	r0, .L0802309c
.L08023040:
	vcmp.f32	s27, #0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L080230e8
	vcmp.f32	s27, s24
	vmrs	APSR_nzcv, fpscr
	bge.n	.L080230e8
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0x30]
	ldr	r2, [sp, #0x54]
	rsb	r1, r7, r7, lsl #4
	and.w	r0, r0, #0xf
	add.w	r1, r3, r1, lsl #3
	orr.w	r2, r2, r2, lsl #2
	b.n	.L080230d8
.L08023074:
	vadd.f32	s27, s0, s25
	vmov	r0, s27
	bl	float_to_double
	vmov	r2, r3, d11
	mov	r6, r0
	mov	r5, r1
	bl	double_ge
	cbnz	r0, .L080230a6
	vmov	r2, r3, d15
	mov	r0, r6
	mov	r1, r5
	bl	double_ge
	cbz	r0, .L080230a6
.L0802309c:
	movw	r3, #0xf8
	movt	r3, #0x2000
	b.n	.L08023244
.L080230a6:
	vcmp.f32	s27, #0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L0802311c
	vcmp.f32	s27, s24
	vmrs	APSR_nzcv, fpscr
	bge.n	.L0802311c
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0x30]
	ldr	r2, [sp, #0x50]
	rsb	r1, r7, r7, lsl #4
	and.w	r0, r0, #0xf
	add.w	r1, r3, r1, lsl #3
	add.w	r2, r2, r2, lsl #2
.L080230d8:
	add.w	r1, r1, r2, lsl #2
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x260]
	subs	r1, #1
	b.n	.L08023240
.L080230e8:
	vcmp.f32	s27, #0
	vmrs	APSR_nzcv, fpscr
	bge.n	.L0802315e
	vcmp.f32	s27, s26
	vmrs	APSR_nzcv, fpscr
	ble.n	.L0802315e
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0x30]
	ldr	r2, [sp, #0x54]
	rsb	r1, r7, r7, lsl #4
	and.w	r0, r0, #0xf
	add.w	r1, r3, r1, lsl #3
	orr.w	r2, r2, r2, lsl #2
	b.n	.L0802314e
.L0802311c:
	vcmp.f32	s27, #0
	vmrs	APSR_nzcv, fpscr
	bge.n	.L08023192
	vcmp.f32	s27, s26
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08023192
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0x30]
	ldr	r2, [sp, #0x50]
	rsb	r1, r7, r7, lsl #4
	and.w	r0, r0, #0xf
	add.w	r1, r3, r1, lsl #3
	add.w	r2, r2, r2, lsl #2
.L0802314e:
	add.w	r1, r1, r2, lsl #2
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x260]
	adds	r1, #1
	b.n	.L08023240
.L0802315e:
	vcmp.f32	s27, s28
	vmrs	APSR_nzcv, fpscr
	bgt.n	.L080231de
	vcmp.f32	s27, s17
	vmrs	APSR_nzcv, fpscr
	blt.n	.L080231de
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0x30]
	ldr	r2, [sp, #0x54]
	rsb	r1, r7, r7, lsl #4
	and.w	r0, r0, #0xf
	add.w	r1, r3, r1, lsl #3
	orr.w	r2, r2, r2, lsl #2
	b.n	.L080231c4
.L08023192:
	vcmp.f32	s27, s28
	vmrs	APSR_nzcv, fpscr
	bgt.n	.L080231fe
	vcmp.f32	s27, s17
	vmrs	APSR_nzcv, fpscr
	blt.n	.L080231fe
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0x30]
	ldr	r2, [sp, #0x50]
	rsb	r1, r7, r7, lsl #4
	and.w	r0, r0, #0xf
	add.w	r1, r3, r1, lsl #3
	add.w	r2, r2, r2, lsl #2
.L080231c4:
	add.w	r1, r1, r2, lsl #2
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x260]
	vmov	s0, r1
	vcvt.f32.u32	s0, s0
	vsub.f32	s0, s0, s27
	b.n	.L08023238
.L080231de:
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0x30]
	ldr	r2, [sp, #0x54]
	rsb	r1, r7, r7, lsl #4
	and.w	r0, r0, #0xf
	add.w	r1, r3, r1, lsl #3
	orr.w	r2, r2, r2, lsl #2
	b.n	.L0802321c
.L080231fe:
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0x30]
	ldr	r2, [sp, #0x50]
	rsb	r1, r7, r7, lsl #4
	and.w	r0, r0, #0xf
	add.w	r1, r3, r1, lsl #3
	add.w	r2, r2, r2, lsl #2
.L0802321c:
	add.w	r1, r1, r2, lsl #2
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x260]
	vmul.f32	s0, s27, s19
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s2, s0
.L08023238:
	vcvt.s32.f32	s0, s0
	vmov	r1, s0
.L08023240:
	strh.w	r1, [r0, #0x260]
.L08023244:
	ldrb.w	r0, [r3, #0x30]
	ldrb.w	r1, [r3, #0x2d]
	lsls.w	r2, r10, #24
	and.w	r0, r0, #0xf
	beq.n	.L08023270
	cmp	r1, #5
	bcc.n	.L0802328a
	movw	r2, #0xf8
	movt	r2, #0x2000
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L080232d6
.L08023270:
	cmp	r1, #5
	bcc.n	.L080232aa
	movw	r2, #0xf8
	movt	r2, #0x2000
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L08023324
.L0802328a:
	movw	r2, #0xf8
	cmp	r1, #4
	movt	r2, #0x2000
	beq.n	.L080232ca
	ldrb	r1, [r2, #0x14]
	cmp	r1, #3
	beq.n	.L080232ca
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L080232d6
.L080232aa:
	movw	r2, #0xf8
	cmp	r1, #4
	movt	r2, #0x2000
	beq.n	.L08023318
	ldrb	r1, [r2, #0x14]
	cmp	r1, #3
	beq.n	.L08023318
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L08023324
.L080232ca:
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L080232d6:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s21
	ldrsb.w	r0, [r2, #5]
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
	b.n	.L08023376
.L08023318:
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L08023324:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s21
	ldrsb.w	r0, [r2, #4]
	adds	r0, #0x64
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	ldr.w	r0, [r8, #4]
	lsrs	r0, r0, #12
	vmul.f32	s0, s0, s2
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vcvt.u32.f32	s0, s0
	vmov	r1, s0
	bfi	r1, r0, #12, #20
	str.w	r1, [r8, #4]
	ldr.w	r0, [r8]
	orr.w	r0, r0, #1
	str.w	r0, [r8]
.L08023376:
	vmov	r0, s27
	bl	float_to_double
	vmov	r2, r3, d11
	mov	r6, r0
	mov	r5, r1
	bl	double_ge
	cmp	r0, #0
	bne.w	.L08022e90
	vmov	r2, r3, d15
	mov	r0, r6
	mov	r1, r5
	bl	double_lt
	cmp	r0, #0
	bne.w	.L08022e90
	movw	r4, #0xf8
	movt	r4, #0x2000
	ldrb.w	r0, [r4, #0x30]
	cmp	r0, #0x40
	bcc.w	.L08022e88
	and.w	r0, r0, #0x3f
	adds	r0, #1
	and.w	r1, r0, #0xf
	cmp	r1, #0xa
	strb.w	r0, [r4, #0x30]
	bne.w	.L080237c4
	ldrb.w	r1, [r11]
	movw	r4, #0xf8
	movt	r4, #0x2000
	cmp	r1, #0x9c
	bne.n	.L080233f8
	movw	r1, #0x6464
	strh	r1, [r4, #4]
	ldrb.w	r1, [r4, #0x2d]
	and.w	r0, r0, #0x70
	cmp	r1, #4
	strb.w	r0, [r4, #0x30]
	bls.n	.L08023414
	add.w	r0, r4, #0x29c
	add.w	r1, r4, #0x260
	b.n	.L0802342e
.L080233f8:
	movw	r1, #0x9c9c
	strh	r1, [r4, #4]
	ldrb.w	r1, [r4, #0x2d]
	and.w	r0, r0, #0x70
	cmp	r1, #4
	strb.w	r0, [r4, #0x30]
	bls.n	.L08023490
	add.w	r0, r4, #0x260
	b.n	.L080234a6
.L08023414:
	add.w	r0, r4, #0x2b0
	cmp	r1, #4
	add.w	r1, r4, #0x274
	beq.n	.L0802342e
	ldrb	r2, [r4, #0x14]
	cmp	r2, #3
	itt	ne
	addne.w	r0, r4, #0x2c4
	addne.w	r1, r4, #0x288
.L0802342e:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s21
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	ldr.w	r0, [r8, #4]
	lsrs	r0, r0, #12
	vmul.f32	s0, s0, s21
	vadd.f32	s0, s0, s2
	vcvt.u32.f32	s0, s0
	vmov	r1, s0
	bfi	r1, r0, #12, #20
	str.w	r1, [r8, #4]
	ldr.w	r0, [r8]
	orr.w	r0, r0, #1
	str.w	r0, [r8]
	ldrb.w	r1, [r4, #0x2d]
	ldrb.w	r0, [r4, #0x30]
	cmp	r1, #5
	and.w	r0, r0, #0xf
	bcc.n	.L080234de
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L0802351a
.L08023490:
	ldrb	r0, [r4, #0x14]
	add.w	r2, r4, #0x274
	cmp	r0, #3
	mov	r0, r2
	it	ne
	addne.w	r0, r4, #0x288
	cmp	r1, #4
	it	eq
	moveq	r0, r2
.L080234a6:
	ldrh	r0, [r0]
	ldr.w	r1, [r8, #4]
	bfi	r1, r0, #0, #12
	str.w	r1, [r8, #4]
	ldr.w	r0, [r8]
	orr.w	r0, r0, #1
	str.w	r0, [r8]
	ldrb.w	r1, [r4, #0x2d]
	ldrb.w	r0, [r4, #0x30]
	cmp	r1, #5
	and.w	r0, r0, #0xf
	bcc.n	.L080234f6
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L08023568
.L080234de:
	cmp	r1, #4
	beq.n	.L0802350e
	ldrb	r1, [r4, #0x14]
	cmp	r1, #3
	beq.n	.L0802350e
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L0802351a
.L080234f6:
	cmp	r1, #4
	beq.n	.L0802355c
	ldrb	r1, [r4, #0x14]
	cmp	r1, #3
	beq.n	.L0802355c
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L08023568
.L0802350e:
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L0802351a:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s21
	ldrsb.w	r0, [r4, #5]
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
	b.n	.L080237c4
.L0802355c:
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L08023568:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s21
	ldrsb.w	r0, [r4, #5]
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
	ldrb.w	r0, [r4, #0x30]
	lsls	r0, r0, #26
	bmi.n	.L080235be
	movs	r0, #0x20
	strb.w	r0, [r4, #0x30]
	movs	r0, #4
	strb.w	r0, [r4, #0x2d]
	b.n	.L08023784
.L080235be:
	movs	r0, #0x30
	strb.w	r0, [r4, #0x30]
	movs	r0, #3
	strb.w	r0, [r4, #0x2d]
	movw	r0, #0x101
	strh	r0, [r4, #0x14]
	movw	r0, #0x2d78
	movt	r0, #0x2000
	ldr	r0, [r0]
	movs	r1, #6
	strb.w	r1, [sp, #0x5e]
	add.w	r1, sp, #0x5e
	mov.w	r2, #-1
	bl	queue_send_timeout
	movw	r1, #0x1014
	movs	r0, #4
	movt	r1, #0x4001
	str.w	r0, [r1, #0x3fc]
	ldrb.w	r1, [r4, #0x2d]
	ldrb.w	r0, [r4, #0x30]
	cmp	r1, #5
	and.w	r0, r0, #0xf
	bcc.n	.L08023618
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L08023654
.L08023618:
	cmp	r1, #4
	beq.n	.L08023640
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldrb	r1, [r1, #0x14]
	cmp	r1, #3
	beq.n	.L08023640
	movw	r4, #0xf8
	movt	r4, #0x2000
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L08023654
.L08023640:
	movw	r4, #0xf8
	movt	r4, #0x2000
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L08023654:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s21
	ldrsb.w	r0, [r4, #4]
	adds	r0, #0x64
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	ldr.w	r0, [r8, #4]
	lsrs	r0, r0, #12
	vmul.f32	s0, s0, s2
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vcvt.u32.f32	s0, s0
	vmov	r1, s0
	bfi	r1, r0, #12, #20
	str.w	r1, [r8, #4]
	ldr.w	r0, [r8]
	orr.w	r0, r0, #1
	str.w	r0, [r8]
	ldrb.w	r1, [r4, #0x2d]
	ldrb.w	r0, [r4, #0x30]
	cmp	r1, #5
	and.w	r0, r0, #0xf
	bcc.n	.L080236c4
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L08023700
.L080236c4:
	cmp	r1, #4
	beq.n	.L080236ec
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldrb	r1, [r1, #0x14]
	cmp	r1, #3
	beq.n	.L080236ec
	movw	r4, #0xf8
	movt	r4, #0x2000
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L08023700
.L080236ec:
	movw	r4, #0xf8
	movt	r4, #0x2000
	add.w	r1, r4, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L08023700:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s21
	ldrsb.w	r0, [r4, #5]
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
	ldrb	r0, [r4, #0x14]
	cmp	r0, #3
	beq.n	.L08023764
	cmp	r0, #2
	beq.n	.L08023774
	cmp	r0, #1
	bne.n	.L08023784
	movw	r1, #0x1014
	movs	r0, #4
	movt	r1, #0x4001
	str.w	r0, [r1, #-4]
	movs	r0, #2
	str.w	r0, [r1, #-4]
	b.n	.L08023784
.L08023764:
	movw	r1, #0x1014
	movs	r0, #4
	movt	r1, #0x4001
	str.w	r0, [r1, #-4]
	b.n	.L08023780
.L08023774:
	movw	r1, #0x1014
	movs	r0, #4
	movt	r1, #0x4001
	str	r0, [r1]
.L08023780:
	movs	r0, #2
	str	r0, [r1]
.L08023784:
	movw	r0, #0x2d78
	movt	r0, #0x2000
	ldr	r0, [r0]
	movs	r1, #1
	strb.w	r1, [sp, #0x5e]
	add.w	r1, sp, #0x5e
	mov.w	r2, #-1
	bl	queue_send_timeout
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	ldr	r0, [r0]
	movs	r1, #2
	strb.w	r1, [sp, #0x5f]
	add.w	r1, sp, #0x5f
	mov.w	r2, #-1
	bl	queue_send_timeout
	movw	r4, #0xf8
	movt	r4, #0x2000
.L080237c4:
	ldrb.w	r0, [r4, #0x30]
	and.w	r0, r0, #0xf
	bl	fn_080088a4
	ldrb.w	r0, [r4, #0x30]
	and.w	r0, r0, #0xf
	bl	fn_08008a58
	b.w	.L08022e90
.L080237e0:
	vmov.f32	s0, #1.5
	vcmp.f32	s16, s0
	vmrs	APSR_nzcv, fpscr
	bgt.n	.L0802386c
	vmov.f32	s0, #-1.5
	vcmp.f32	s16, s0
	vmrs	APSR_nzcv, fpscr
	blt.n	.L0802386c
	movw	r2, #0xf8
	rsb	r1, r7, r7, lsl #4
	movt	r2, #0x2000
	and.w	r0, r11, #0xf
	add.w	r1, r2, r1, lsl #3
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x288]
	vmov	s0, r1
	vcvt.f32.u32	s0, s0
	vsub.f32	s0, s0, s16
	b.n	.L0802389c
.L08023826:
	vmov.f32	s0, #1.5
	vcmp.f32	s16, s0
	vmrs	APSR_nzcv, fpscr
	bgt.n	.L080238aa
	vmov.f32	s0, #-1.5
	vcmp.f32	s16, s0
	vmrs	APSR_nzcv, fpscr
	blt.n	.L080238aa
	movw	r2, #0xf8
	rsb	r1, r7, r7, lsl #4
	movt	r2, #0x2000
	and.w	r0, r11, #0xf
	add.w	r1, r2, r1, lsl #3
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x2c4]
	vmov	s0, r1
	vcvt.f32.u32	s0, s0
	vsub.f32	s0, s0, s16
	b.n	.L080238da
.L0802386c:
	movw	r2, #0xf8
	rsb	r1, r7, r7, lsl #4
	movt	r2, #0x2000
	and.w	r0, r11, #0xf
	add.w	r1, r2, r1, lsl #3
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x288]
	vmov.f32	s0, #-8.0
	vmov	s2, r1
	vmul.f32	s0, s16, s0
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s2, s0
.L0802389c:
	vcvt.s32.f32	s0, s0
	vmov	r1, s0
	strh.w	r1, [r0, #0x288]
	b.n	.L080238e6
.L080238aa:
	movw	r2, #0xf8
	rsb	r1, r7, r7, lsl #4
	movt	r2, #0x2000
	and.w	r0, r11, #0xf
	add.w	r1, r2, r1, lsl #3
	add.w	r0, r1, r0, lsl #1
	ldrh.w	r1, [r0, #0x2c4]
	vmov.f32	s0, #-8.0
	vmov	s2, r1
	vmul.f32	s0, s16, s0
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s2, s0
.L080238da:
	vcvt.s32.f32	s0, s0
	vmov	r1, s0
.L080238e2:
	strh.w	r1, [r0, #0x2c4]
.L080238e6:
	ldrb.w	r1, [r2, #0x2d]
	cmp.w	r9, #1
	and.w	r0, r11, #0xf
	bne.n	.L0802390e
	cmp	r1, #5
	bcc.n	.L08023928
	movw	r2, #0xf8
	movt	r2, #0x2000
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L08023974
.L0802390e:
	cmp	r1, #5
	bcc.n	.L08023948
	movw	r2, #0xf8
	movt	r2, #0x2000
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L080239d8
.L08023928:
	movw	r2, #0xf8
	cmp	r1, #4
	movt	r2, #0x2000
	beq.n	.L08023968
	ldrb	r1, [r2, #0x14]
	cmp	r1, #3
	beq.n	.L08023968
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L08023974
.L08023948:
	movw	r2, #0xf8
	cmp	r1, #4
	movt	r2, #0x2000
	beq.n	.L080239cc
	ldrb	r1, [r2, #0x14]
	cmp	r1, #3
	beq.n	.L080239cc
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L080239d8
.L08023968:
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L08023974:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	vldr	s2, .L08023d38
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s2
	ldrsb.w	r0, [r2, #4]
	adds	r0, #0x64
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	movw	r0, #0x7404
	movt	r0, #0x4000
	vmul.f32	s0, s0, s2
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	ldr	r1, [r0, #4]
	vcvt.u32.f32	s0, s0
	vmov	r2, s0
	lsrs	r1, r1, #12
	bfi	r2, r1, #12, #20
	str	r2, [r0, #4]
	ldr	r1, [r0]
	orr.w	r1, r1, #1
	str	r1, [r0]
	b.n	.L08023a1c
.L080239cc:
	add.w	r1, r2, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L080239d8:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	vldr	s2, .L08023d38
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s2
	ldrsb.w	r0, [r2, #5]
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
.L08023a1c:
	vmov	r0, s16
	bl	float_to_double
	vldr	d0, .L08023d40
	mov	r4, r0
	vmov	r2, r3, d0
	mov	r5, r1
	bl	double_ge
	movw	r6, #0xf8
	cmp	r0, #0
	movt	r6, #0x2000
	bne.w	.L080240a4
	vldr	d0, .L08023d48
	mov	r0, r4
	vmov	r2, r3, d0
	mov	r1, r5
	bl	double_lt
	cmp	r0, #0
	bne.w	.L080240a4
	ldrb.w	r0, [r6, #0x30]
	adds	r0, #1
	and.w	r1, r0, #0xf
	cmp	r1, #0xa
	strb.w	r0, [r6, #0x30]
	bne.w	.L0802408c
	ldrb.w	r0, [r10]
	cmp	r0, #0x9c
	bne.n	.L08023aaa
	movs	r0, #0x64
	movw	r3, #0xf8
	strb.w	r0, [r10]
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0x30]
	ldrb.w	r1, [r3, #0x2d]
	and.w	r0, r0, #0xf0
	cmp.w	r9, #1
	strb.w	r0, [r3, #0x30]
	bne.w	.L08023c60
	cmp	r1, #4
	bls.w	.L08023cc4
	add.w	r0, r3, #0x29c
	add.w	r1, r3, #0x260
	b.n	.L08023cde
.L08023aaa:
	movw	r9, #0xf8
	movt	r9, #0x2000
	ldrb.w	r0, [r9, #0x14]
	movs	r1, #0
	movs	r3, #0
	cmp	r0, #1
	bne.n	.L08023b62
.L08023abe:
	add.w	r2, r9, r1
	ldrb.w	r7, [r2, #0xaaa]
	ldrb.w	r6, [r2, #0xaab]
	ldrb.w	r5, [r2, #0xaac]
	add	r3, r7
	ldrb.w	r4, [r2, #0xaad]
	add	r3, r6
	add	r3, r5
	ldrb.w	r7, [r2, #0xaae]
	add	r3, r4
	ldrb.w	r6, [r2, #0xaaf]
	add	r3, r7
	ldrb.w	r7, [r2, #0xab0]
	add	r3, r6
	ldrb.w	r6, [r2, #0xab1]
	add	r3, r7
	ldrb.w	r7, [r2, #0xab2]
	add	r3, r6
	ldrb.w	r6, [r2, #0xab3]
	add	r3, r7
	ldrb.w	r7, [r2, #0xab4]
	add	r3, r6
	ldrb.w	r6, [r2, #0xab5]
	add	r3, r7
	ldrb.w	r7, [r2, #0xab6]
	add	r3, r6
	ldrb.w	r6, [r2, #0xab7]
	add	r3, r7
	ldrb.w	r7, [r2, #0xab8]
	add	r3, r6
	ldrb.w	r6, [r2, #0xab9]
	add	r3, r7
	ldrb.w	r7, [r2, #0xaba]
	add	r3, r6
	ldrb.w	r6, [r2, #0xabb]
	add	r3, r7
	ldrb.w	r7, [r2, #0xabc]
	add	r3, r6
	ldrb.w	r6, [r2, #0xabd]
	add	r3, r7
	ldrb.w	r7, [r2, #0xabe]
	add	r3, r6
	ldrb.w	r6, [r2, #0xabf]
	add	r3, r7
	ldrb.w	r7, [r2, #0xac0]
	add	r3, r6
	ldrb.w	r6, [r2, #0xac1]
	add	r3, r7
	ldrb.w	r2, [r2, #0xac2]
	add	r3, r6
	adds	r1, #0x19
	cmp.w	r1, #0x1f4
	add	r3, r2
	bne.n	.L08023abe
	b.n	.L08023c04
.L08023b62:
	add.w	r2, r9, r1
	ldrb.w	r7, [r2, #0x6aa]
	ldrb.w	r6, [r2, #0x6ab]
	ldrb.w	r5, [r2, #0x6ac]
	add	r3, r7
	ldrb.w	r4, [r2, #0x6ad]
	add	r3, r6
	add	r3, r5
	ldrb.w	r7, [r2, #0x6ae]
	add	r3, r4
	ldrb.w	r6, [r2, #0x6af]
	add	r3, r7
	ldrb.w	r7, [r2, #0x6b0]
	add	r3, r6
	ldrb.w	r6, [r2, #0x6b1]
	add	r3, r7
	ldrb.w	r7, [r2, #0x6b2]
	add	r3, r6
	ldrb.w	r6, [r2, #0x6b3]
	add	r3, r7
	ldrb.w	r7, [r2, #0x6b4]
	add	r3, r6
	ldrb.w	r6, [r2, #0x6b5]
	add	r3, r7
	ldrb.w	r7, [r2, #0x6b6]
	add	r3, r6
	ldrb.w	r6, [r2, #0x6b7]
	add	r3, r7
	ldrb.w	r7, [r2, #0x6b8]
	add	r3, r6
	ldrb.w	r6, [r2, #0x6b9]
	add	r3, r7
	ldrb.w	r7, [r2, #0x6ba]
	add	r3, r6
	ldrb.w	r6, [r2, #0x6bb]
	add	r3, r7
	ldrb.w	r7, [r2, #0x6bc]
	add	r3, r6
	ldrb.w	r6, [r2, #0x6bd]
	add	r3, r7
	ldrb.w	r7, [r2, #0x6be]
	add	r3, r6
	ldrb.w	r6, [r2, #0x6bf]
	add	r3, r7
	ldrb.w	r7, [r2, #0x6c0]
	add	r3, r6
	ldrb.w	r6, [r2, #0x6c1]
	add	r3, r7
	ldrb.w	r2, [r2, #0x6c2]
	add	r3, r6
	adds	r1, #0x19
	cmp.w	r1, #0x1f4
	add	r3, r2
	bne.n	.L08023b62
.L08023c04:
	movw	r1, #0x4dd3
	movt	r1, #0x1062
	smmul	r1, r3, r1
	lsrs	r2, r1, #5
	add.w	r1, r2, r1, lsr #31
	adds	r1, #0x1c
	cmp	r0, #2
	strb.w	r1, [r8, #0x350]
	bne.n	.L08023c6e
	movw	r0, #0x1014
	movs	r1, #0
	movt	r0, #0x4001
	strb.w	r1, [r9, #0x30]
	movw	r1, #0x203
	movs	r2, #4
	strh.w	r1, [r9, #0x14]
	str.w	r2, [r0, #0x3fc]
	ldrb.w	r1, [r9, #0x14]
	cmp	r1, #3
	beq.w	.L08023db6
	cmp	r1, #2
	beq.w	.L08023dbc
	cmp	r1, #1
	bne.w	.L08023dc4
	movs	r1, #4
	str.w	r1, [r0, #-4]
	movs	r1, #2
	str.w	r1, [r0, #-4]
	b.n	.L08023dc4
.L08023c60:
	cmp	r1, #4
	bls.n	.L08023d54
	add.w	r0, r3, #0x314
	add.w	r1, r3, #0x2d8
	b.n	.L08023d6e
.L08023c6e:
	movw	r0, #0x1202
	strh.w	r0, [r9, #0x14]
	movw	r0, #0x2d78
	movt	r0, #0x2000
	movs	r1, #6
	ldr	r0, [r0]
	strb.w	r1, [sp, #0x5e]
	add.w	r1, sp, #0x5e
	mov.w	r2, #-1
	bl	queue_send_timeout
	ldrb.w	r0, [r9, #0x14]
	movs	r1, #0x30
	cmp	r0, #3
	strb.w	r1, [r9, #0x30]
	beq.w	.L08023e0c
	cmp	r0, #2
	beq.w	.L08023e1c
	cmp	r0, #1
	bne.w	.L08023e2c
	movw	r0, #0x1014
	movt	r0, #0x4001
	movs	r1, #4
	str.w	r1, [r0, #-4]
	movs	r1, #2
	str.w	r1, [r0, #-4]
	b.n	.L08023e2c
.L08023cc4:
	add.w	r0, r3, #0x2b0
	cmp	r1, #4
	add.w	r1, r3, #0x274
	beq.n	.L08023cde
	ldrb	r2, [r3, #0x14]
	cmp	r2, #3
	itt	ne
	addne.w	r0, r3, #0x2c4
	addne.w	r1, r3, #0x288
.L08023cde:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	vldr	s2, .L08023d38
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s2
	ldrsb.w	r0, [r3, #4]
	mov	r6, r3
	adds	r0, #0x64
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	movw	r0, #0x7404
	movt	r0, #0x4000
	vmul.f32	s0, s0, s2
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	ldr	r1, [r0, #4]
	vcvt.u32.f32	s0, s0
	vmov	r2, s0
	lsrs	r1, r1, #12
	bfi	r2, r1, #12, #20
	str	r2, [r0, #4]
	ldr	r1, [r0]
	orr.w	r1, r1, #1
	str	r1, [r0]
	b.n	.L0802408c
.L08023d38:
	.word	0x43480000		@ 200.0f
	.short	0xbf00			@ padding
	.short	0xbf00			@ padding
.L08023d40:
	.word	0x33333333, 0x3fd33333	@ double 0.3
.L08023d48:
	.word	0x9999999a, 0xbfb99999	@ double -0.1
.L08023d50:
	.word	0x43160000		@ 150.0f
.L08023d54:
	add.w	r0, r3, #0x328
	cmp	r1, #4
	add.w	r1, r3, #0x2ec
	beq.n	.L08023d6e
	ldrb	r2, [r3, #0x14]
	cmp	r2, #3
	itt	ne
	addne.w	r0, r3, #0x33c
	addne.w	r1, r3, #0x300
.L08023d6e:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	vldr	s2, .L08023d38
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s2
	ldrsb.w	r0, [r3, #5]
	mov	r6, r3
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
	b.n	.L0802408c
.L08023db6:
	str.w	r2, [r0, #-4]
	b.n	.L08023dc0
.L08023dbc:
	movs	r1, #4
	str	r1, [r0]
.L08023dc0:
	movs	r1, #2
	str	r1, [r0]
.L08023dc4:
	movw	r0, #0xce32
	mov	r2, r9
	strh.w	r0, [r2, #4]!
	movs	r0, #0
	ldrb	r3, [r2, #0x12]
	strh	r0, [r2, #0x16]
	ldrb.w	r1, [r2, #0x29]
	ldrb.w	r0, [r2, #-2]
	ldrsb	r3, [r2, r3]
	cmp	r1, #5
	strh	r3, [r2, #0x18]
	bcc.n	.L08023df2
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L08023e70
.L08023df2:
	cmp	r1, #4
	beq.n	.L08023e64
	ldrb.w	r1, [r9, #0x14]
	cmp	r1, #3
	beq.n	.L08023e64
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L08023e70
.L08023e0c:
	movw	r0, #0x1014
	movt	r0, #0x4001
	movs	r1, #4
	str.w	r1, [r0, #-4]
	b.n	.L08023e28
.L08023e1c:
	movw	r0, #0x1014
	movt	r0, #0x4001
	movs	r1, #4
	str	r1, [r0]
.L08023e28:
	movs	r1, #2
	str	r1, [r0]
.L08023e2c:
	ldrb.w	r1, [r9, #0x2d]
	ldrb.w	r0, [r9, #0x30]
	cmp	r1, #5
	and.w	r0, r0, #0xf
	bcc.n	.L08023e4a
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L08023efc
.L08023e4a:
	cmp	r1, #4
	beq.n	.L08023ef0
	ldrb.w	r1, [r9, #0x14]
	cmp	r1, #3
	beq.n	.L08023ef0
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L08023efc
.L08023e64:
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L08023e70:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	vldr	s0, .L08023d38
	subs	r0, r0, r1
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vdiv.f32	s2, s2, s0
	vldr	s4, .L08023d50
	movw	r0, #0x7404
	movt	r0, #0x4000
	vmul.f32	s2, s2, s4
	vmov	s4, r1
