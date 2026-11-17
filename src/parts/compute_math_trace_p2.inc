@ compute_math_trace_p2.inc - part 2 of 2 of compute_math_trace
@ (0x08028930..0x08028b40): tail of the function. For each of the byte offsets
@ 0..5 of the trace record (r2 + 0x484 + n are the source bytes, r4 + 0x38 is
@ the destination base, r0 the index added to it, r4 + 5 a signed byte offset
@ value) it computes s6 = |(float)signed(r4[5]) + (s0 - (float)src[n])| +
@ (float)signed(r4[5]), then clamps the result into the range [s4, s2]
@ (s8 = s2 when s6 > s2, otherwise s6 raised to s4 when below), converts it
@ to an integer (vcvt.s32.f32) and stores the byte at [[r4 + 0x38] + r0 + n].
@ The first store (offset 0) comes from s6 as staged by part 1. The final clamp
@ (offset 5 is the last stored byte, offset 6 of the source is handled in the
@ block that ends at the branch back to .L080288cc in part 1) branches back to
@ part 1 at 0x080288cc. Followed by three float literals read by part 1:
@ 0x43000000 (128.0), 0x42c80000 (100.0), 0xc2c80000 (-100.0).
	ldr	r3, [r4, #0x38]
	vmov	r1, s6
	strb	r1, [r3, r0]
	ldrb.w	r1, [r2, #0x484]
	vmov	s6, r1
	ldrsb.w	r1, [r4, #5]
	vcvt.f32.u32	s6, s6
	vmov	s8, r1
	vsub.f32	s6, s0, s6
	vcvt.f32.s32	s8, s8
	vadd.f32	s6, s8, s6
	vabs.f32	s6, s6
	vadd.f32	s6, s6, s8
	vcmp.f32	s6, s2
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s8, s2
	bgt.n	.L08028980
	vcmp.f32	s6, s4
	vmov.f32	s8, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s8, s4
.L08028980:
	ldr	r1, [r4, #0x38]
	vcvt.s32.f32	s6, s8
	vmov	r3, s6
	add	r1, r0
	strb	r3, [r1, #1]
	ldrb.w	r1, [r2, #0x485]
	vmov	s6, r1
	ldrsb.w	r1, [r4, #5]
	vcvt.f32.u32	s6, s6
	vmov	s8, r1
	vsub.f32	s6, s0, s6
	vcvt.f32.s32	s8, s8
	vadd.f32	s6, s8, s6
	vabs.f32	s6, s6
	vadd.f32	s6, s6, s8
	vcmp.f32	s6, s2
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s8, s2
	bgt.n	.L080289d6
	vcmp.f32	s6, s4
	vmov.f32	s8, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s8, s4
.L080289d6:
	ldr	r1, [r4, #0x38]
	vcvt.s32.f32	s6, s8
	vmov	r3, s6
	add	r1, r0
	strb	r3, [r1, #2]
	ldrb.w	r1, [r2, #0x486]
	vmov	s6, r1
	ldrsb.w	r1, [r4, #5]
	vcvt.f32.u32	s6, s6
	vmov	s8, r1
	vsub.f32	s6, s0, s6
	vcvt.f32.s32	s8, s8
	vadd.f32	s6, s8, s6
	vabs.f32	s6, s6
	vadd.f32	s6, s6, s8
	vcmp.f32	s6, s2
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s8, s2
	bgt.n	.L08028a2c
	vcmp.f32	s6, s4
	vmov.f32	s8, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s8, s4
.L08028a2c:
	ldr	r1, [r4, #0x38]
	vcvt.s32.f32	s6, s8
	vmov	r3, s6
	add	r1, r0
	strb	r3, [r1, #3]
	ldrb.w	r1, [r2, #0x487]
	vmov	s6, r1
	ldrsb.w	r1, [r4, #5]
	vcvt.f32.u32	s6, s6
	vmov	s8, r1
	vsub.f32	s6, s0, s6
	vcvt.f32.s32	s8, s8
	vadd.f32	s6, s8, s6
	vabs.f32	s6, s6
	vadd.f32	s6, s6, s8
	vcmp.f32	s6, s2
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s8, s2
	bgt.n	.L08028a82
	vcmp.f32	s6, s4
	vmov.f32	s8, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s8, s4
.L08028a82:
	ldr	r1, [r4, #0x38]
	vcvt.s32.f32	s6, s8
	vmov	r3, s6
	add	r1, r0
	strb	r3, [r1, #4]
	ldrb.w	r1, [r2, #0x488]
	vmov	s6, r1
	ldrsb.w	r1, [r4, #5]
	vcvt.f32.u32	s6, s6
	vmov	s8, r1
	vsub.f32	s6, s0, s6
	vcvt.f32.s32	s8, s8
	vadd.f32	s6, s8, s6
	vabs.f32	s6, s6
	vadd.f32	s6, s6, s8
	vcmp.f32	s6, s2
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s8, s2
	bgt.n	.L08028ad8
	vcmp.f32	s6, s4
	vmov.f32	s8, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s8, s4
.L08028ad8:
	ldr	r1, [r4, #0x38]
	vcvt.s32.f32	s6, s8
	vmov	r3, s6
	add	r1, r0
	strb	r3, [r1, #5]
	ldrb.w	r1, [r2, #0x489]
	vmov	s6, r1
	ldrsb.w	r1, [r4, #5]
	vcvt.f32.u32	s6, s6
	vmov	s8, r1
	vsub.f32	s6, s0, s6
	vcvt.f32.s32	s8, s8
	vadd.f32	s6, s8, s6
	vabs.f32	s6, s6
	vadd.f32	s6, s6, s8
	vcmp.f32	s6, s2
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s8, s2
	bgt.w	.L080288cc
	vcmp.f32	s6, s4
	vmov.f32	s8, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s8, s4
	b.n	.L080288cc
	.short	0xbf00	@ padding (bytes 00 bf)
.L08028b34:
	.word	0x43000000
.L08028b38:
	.word	0x42c80000
.L08028b3c:
	.word	0xc2c80000
