@ measure_32.s - spectrum byte computation (compute_spectrum_bytes) and the measurement scaling code fn_08025fc0
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ compute_spectrum_bytes - builds per-channel 128-byte magnitude spectra (peak
@ scaled to 50) from the sample ring at 0x200006a8.
@ No parameters, no return value.
@ Loops channel index i from the high nibble of byte 0x2000010d (decompiled as
@ [0x2000010c] byte 1) up to but excluding its low nibble.
@ release(p): if byte 0x20001080 is 0 calls the function pointer at 0x20001070
@ with 0 (the decompiled call shows no pointer argument); otherwise, when
@ (p - word 0x20001078) >> 10 < 0xaf, takes the halfword count at
@ word(0x2000107c) + ((p - word(0x20001078)) >> 5)*2 and, when it is non-zero,
@ clears count*2 bytes there with 0x080082bc zero_bytes.
@ If byte 0x20000102+i is 0 or byte 0x2000012c is non-zero: release(slot word
@ 0x20000104+i*4) when the slot is non-zero, then stores 0 in the slot.
@ Otherwise allocates A = 0x400 bytes and B = 0x200 bytes with 0x0803acfc
@ alloc_units_of_32_bytes, and 0x80 bytes into the slot only when the slot is
@ 0; a failed A skips the channel, a failed B or slot allocation releases A
@ (and B) and skips the channel.
@ Fills A with 256 floats A[k] = (byte - 128.0) - (signed byte 0x200000fc+i),
@ k = 0..255, sample index s = u16 0x20000eb4 + k, idx = s & 0x7fff minus 0x400
@ once when idx >= 0x400: when byte 0x2000010c is 3, or byte 0x20000125 >= 4,
@ the byte is read at 0x200006a8 + i*0x400 + idx; otherwise (byte 0x20000125 < 4,
@ mode not 3) idx is instead reduced by 0x800 when idx >= 0x800 (idx already
@ masked with & 0x7fff) and the byte comes from 0x200006a8[idx>>1] for even idx
@ or 0x20000aa8[idx>>1] for odd idx, with the byte 0x20000449 subtracted for
@ even idx when byte 0x2000010c != 1, and the byte 0x20000448 subtracted for odd
@ idx when byte 0x2000010c == 1 (the other parity is read raw).
@ Runs 16 butterfly iterations over the four 0x100-byte quarters of A (offsets
@ 0, 0x100, 0x200, 0x300): sums and differences, then multiplies by 4 floats
@ per iteration read from the table at 0x0806e0c0 (the table pointer advances
@ 0x10 per iteration, reads at +0x10, +0x14, +0x18, +0x1c).
@ Calls 0x0802fb80 fft64_radix8_in_place on A and on A+0x200, then performs 104
@ swaps of 8-byte entries (26 passes of 4 swaps) at byte offsets
@ (halfword & ~3) taken from the table at 0x0806e4d0 (0x1a0 bytes).
@ Then B[j] = sqrt(re*re + im*im) for the 128 float pairs of A, calling
@ 0x08044c1e sqrt_f32_checked only when the hardware square root gives NaN.
@ Scale = max(|max B|, |min B|) / 50.0 (NaN-aware compares; there is no zero
@ test, so an all-zero B divides by 0.0); slot byte j = (signed char)(int)
@ (B[j] / scale) for j = 0..127.
@ Finally release(B) and then release(A) (a failed B or slot allocation reaches
@ the same release code).
@ Evidence of purpose: the butterfly, the 0x0802fb80 call, the swap table, the
@ sqrt of re^2+im^2 and the peak/50.0 scaling.
@ ----------------------------------------------------------------------------
	.section .text.compute_spectrum_bytes,"ax",%progbits
	.global compute_spectrum_bytes
	.thumb_func
	.type compute_spectrum_bytes, %function
compute_spectrum_bytes:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #4
	vpush	{d8, d9}
	sub	sp, #0x10
	movw	r2, #0xf8
	movt	r2, #0x2000
	ldrb	r0, [r2, #0x15]
	and.w	r1, r0, #0xf
	cmp.w	r1, r0, lsr #4
	bls.w	.L08025a9e
	lsrs	r5, r0, #4
	movw	r0, #:lower16:d_0806e0d0
	movw	r7, #0x1070
	vldr	s16, .L08025230
	movt	r0, #:upper16:d_0806e0d0
	vldr	s18, .L08025234
	movw	r8, #0xf8
	movt	r7, #0x2000
	subs	r0, #0x10
	movt	r8, #0x2000
	str	r0, [sp, #4]
	b.n	.L08025258
	.short	0xbf00			@ padding
.L08025230:
	.word	0xc3000000		@ -128.0f
.L08025234:
	.word	0x42480000		@ 50.0f
.L08025238:
	ldr	r1, [r7]
	movs	r0, #0
	blx	r1
.L0802523e:
	movs	r0, #0
	str	r0, [r4]
.L08025242:
	movw	r2, #0xf8
	movt	r2, #0x2000
	ldrb	r0, [r2, #0x15]
	adds	r5, #1
	and.w	r0, r0, #0xf
	cmp	r5, r0
	bhs.w	.L08025a9e
.L08025258:
	adds	r6, r2, r5
	ldrb	r0, [r6, #0xa]
	cmp	r0, #0
	beq.w	.L080256dc
	ldrb.w	r0, [r2, #0x34]
	cmp	r0, #0
	bne.w	.L080256dc
	mov.w	r0, #0x400
	bl	alloc_units_of_32_bytes
	cmp	r0, #0
	beq.n	.L08025242
	mov	r11, r0
	mov.w	r0, #0x200
	bl	alloc_units_of_32_bytes
	cmp	r0, #0
	beq.w	.L08025a60
	add.w	r9, r8, r5, lsl #2
	ldr.w	r1, [r9, #0xc]!
	str	r0, [sp, #0xc]
	cbnz	r1, .L080252a6
	movs	r0, #0x80
	bl	alloc_units_of_32_bytes
	ldr	r4, [sp, #0xc]
	cmp	r0, #0
	str.w	r0, [r9]
	beq.w	.L080258ee
.L080252a6:
	ldrb.w	r12, [r8, #0x14]
	ldrh.w	lr, [r8, #0xdbc]
	lsl.w	r10, r5, #0xa
	cmp.w	r12, #3
	add.w	r2, r6, #4
	str	r5, [sp, #8]
	bne.w	.L0802591c
	sub.w	r7, r11, #0x10
	movs	r3, #0
	nop
.L080252c8:
	add.w	r5, lr, r3
	mov	r6, r5
	and.w	r0, r5, #0x7c00
	bfc	r6, #0xf, #0x11
	movs	r4, #0
	cmp.w	r4, r0, lsr #10
	it	ne
	subne.w	r6, r6, #0x400
	uxtah	r6, r10, r6
	add.w	r0, r8, #0x5b0
	ldrb	r6, [r0, r6]
	adds	r1, r5, #1
	vmov	s0, r6
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vstr	s0, [r7, #0x10]
	ldrsb.w	r6, [r2]
	adds	r3, #4
	vmov	s2, r6
	vcvt.f32.s32	s2, s2
	vsub.f32	s0, s0, s2
	and.w	r6, r1, #0x7c00
	bfc	r1, #0xf, #0x11
	vstr	s0, [r7, #0x10]
	cmp.w	r4, r6, lsr #10
	it	ne
	subne.w	r1, r1, #0x400
	uxtah	r1, r10, r1
	ldrb	r1, [r0, r1]
	adds	r6, r5, #2
	vmov	s0, r1
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vstr	s0, [r7, #0x14]
	ldrsb.w	r1, [r2]
	vmov	s2, r1
	vcvt.f32.s32	s2, s2
	vsub.f32	s0, s0, s2
	and.w	r1, r6, #0x7c00
	bfc	r6, #0xf, #0x11
	vstr	s0, [r7, #0x14]
	cmp.w	r4, r1, lsr #10
	it	ne
	subne.w	r6, r6, #0x400
	uxtah	r1, r10, r6
	ldrb	r1, [r0, r1]
	adds	r6, r5, #3
	vmov	s0, r1
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vstr	s0, [r7, #0x18]
	ldrsb.w	r1, [r2]
	vmov	s2, r1
	vcvt.f32.s32	s2, s2
	vsub.f32	s0, s0, s2
	and.w	r1, r6, #0x7c00
	bfc	r6, #0xf, #0x11
	vstr	s0, [r7, #0x18]
	cmp.w	r4, r1, lsr #10
	it	ne
	subne.w	r6, r6, #0x400
	uxtah	r1, r10, r6
	ldrb	r0, [r0, r1]
	cmp.w	r3, #0x100
	vmov	s0, r0
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vstr	s0, [r7, #0x1c]
	ldrsb.w	r0, [r2]
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vsub.f32	s0, s0, s2
	vstr	s0, [r7, #0x1c]
	add.w	r7, r7, #0x10
	bne.w	.L080252c8
.L080253d8:
	ldr	r2, [sp, #4]
	add.w	r6, r11, #0x200
	sub.w	r1, r11, #0x10
	mvn	r0, #0xf
	nop
.L080253e8:
	vldr	s0, [r1, #0x10]
	vldr	s8, [r1, #0x210]
	vldr	s2, [r1, #0x14]
	vldr	s10, [r1, #0x214]
	vldr	s4, [r1, #0x18]
	vldr	s12, [r1, #0x218]
	vadd.f32	s9, s0, s8
	vldr	s6, [r1, #0x1c]
	vldr	s14, [r1, #0x21c]
	vstr	s9, [r1, #0x10]
	vadd.f32	s9, s2, s10
	vstr	s9, [r1, #0x14]
	vadd.f32	s9, s4, s12
	vstr	s9, [r1, #0x18]
	vadd.f32	s9, s6, s14
	vldr	s1, [r1, #0x110]
	vstr	s9, [r1, #0x1c]
	vldr	s9, [r1, #0x310]
	vldr	s3, [r1, #0x114]
	vsub.f32	s0, s0, s8
	vldr	s8, [r1, #0x314]
	vldr	s5, [r1, #0x118]
	vsub.f32	s2, s2, s10
	vldr	s10, [r1, #0x318]
	vsub.f32	s6, s6, s14
	vadd.f32	s14, s1, s9
	vldr	s7, [r1, #0x11c]
	vsub.f32	s4, s4, s12
	vldr	s12, [r1, #0x31c]
	vstr	s14, [r1, #0x110]
	vadd.f32	s14, s3, s8
	vstr	s14, [r1, #0x114]
	vadd.f32	s14, s5, s10
	vstr	s14, [r1, #0x118]
	vadd.f32	s14, s7, s12
	vstr	s14, [r1, #0x11c]
	vsub.f32	s14, s9, s1
	vsub.f32	s8, s8, s3
	vldr	s1, [r2, #0x10]
	vldr	s3, [r2, #0x14]
	vsub.f32	s10, s10, s5
	vsub.f32	s12, s12, s7
	vmul.f32	s5, s0, s1
	vmul.f32	s7, s2, s3
	vmul.f32	s2, s2, s1
	vmul.f32	s0, s0, s3
	vsub.f32	s0, s2, s0
	vstr	s0, [r1, #0x214]
	vmul.f32	s0, s14, s3
	vmul.f32	s2, s8, s3
	vmul.f32	s8, s8, s1
	vmul.f32	s14, s14, s1
	vsub.f32	s0, s0, s8
	vadd.f32	s5, s5, s7
	vstr	s0, [r1, #0x310]
	vadd.f32	s0, s14, s2
	vstr	s5, [r1, #0x210]
	vstr	s0, [r1, #0x314]
	vldr	s0, [r2, #0x18]
	vldr	s2, [r2, #0x1c]
	vmul.f32	s8, s4, s0
	vmul.f32	s14, s6, s2
	vmul.f32	s6, s6, s0
	vmul.f32	s4, s4, s2
	vsub.f32	s4, s6, s4
	vstr	s4, [r1, #0x21c]
	vmul.f32	s4, s10, s2
	vmul.f32	s2, s12, s2
	vmul.f32	s6, s12, s0
	vmul.f32	s0, s10, s0
	vadd.f32	s8, s8, s14
	vsub.f32	s4, s4, s6
	vadd.f32	s0, s0, s2
	vstr	s8, [r1, #0x218]
	vstr	s4, [r1, #0x318]
	vstr	s0, [r1, #0x31c]
	adds	r2, #0x10
	adds	r1, #0x10
	adds	r0, #1
	blo.w	.L080253e8
	mov	r0, r11
	bl	fft64_radix8_in_place
	mov	r0, r6
	bl	fft64_radix8_in_place
	movw	r12, #:lower16:d_0806e4d0
	movs	r0, #0
	movt	r12, #:upper16:d_0806e4d0
.L08025538:
	add.w	r1, r12, r0
	ldrh.w	r2, [r12, r0]
	ldrh	r3, [r1, #2]
	bic.w	r2, r2, #3
	bic.w	r3, r3, #3
	ldr.w	r6, [r11, r2]
	ldr.w	r5, [r11, r3]
	add.w	r7, r11, r2
	add.w	r4, r11, r3
	str.w	r5, [r11, r2]
	str.w	r6, [r11, r3]
	ldr	r2, [r4, #4]
	ldr	r3, [r7, #4]
	str	r2, [r7, #4]
	str	r3, [r4, #4]
	ldrh	r2, [r1, #4]
	ldrh	r3, [r1, #6]
	bic.w	r2, r2, #3
	bic.w	r3, r3, #3
	ldr.w	r6, [r11, r2]
	ldr.w	r5, [r11, r3]
	add.w	r7, r11, r2
	add.w	r4, r11, r3
	str.w	r5, [r11, r2]
	str.w	r6, [r11, r3]
	ldr	r2, [r4, #4]
	ldr	r3, [r7, #4]
	str	r2, [r7, #4]
	str	r3, [r4, #4]
	ldrh	r3, [r1, #0xa]
	ldrh	r2, [r1, #8]
	bic.w	r3, r3, #3
	ldr.w	r5, [r11, r3]
	bic.w	r2, r2, #3
	ldr.w	r6, [r11, r2]
	add.w	r4, r11, r3
	str.w	r5, [r11, r2]
	add.w	r7, r11, r2
	ldr	r2, [r4, #4]
	str.w	r6, [r11, r3]
	ldr	r3, [r7, #4]
	str	r2, [r7, #4]
	ldrh	r2, [r1, #0xc]
	ldrh	r1, [r1, #0xe]
	str	r3, [r4, #4]
	bic.w	r2, r2, #3
	bic.w	r1, r1, #3
	ldr.w	r7, [r11, r2]
	ldr.w	r6, [r11, r1]
	add.w	r3, r11, r2
	add.w	r5, r11, r1
	str.w	r6, [r11, r2]
	str.w	r7, [r11, r1]
	ldr	r1, [r5, #4]
	ldr	r2, [r3, #4]
	adds	r0, #0x10
	cmp.w	r0, #0x1a0
	str	r1, [r3, #4]
	str	r2, [r5, #4]
	bne.n	.L08025538
	ldr	r4, [sp, #0xc]
	sub.w	r6, r11, #0x20
	mvn	r7, #0xf
.L08025600:
	vldr	s0, [r6, #0x20]
	vldr	s2, [r6, #0x24]
	vmul.f32	s0, s0, s0
	vmul.f32	s2, s2, s2
	vadd.f32	s2, s0, s2
	vsqrt.f32	s0, s2
	vcmp.f32	s0, s0
	vmrs	APSR_nzcv, fpscr
	bvs.n	.L080256aa
.L08025622:
	add.w	r10, r4, r7
	vstr	s0, [r10, #0x10]
	vldr	s0, [r6, #0x28]
	vldr	s2, [r6, #0x2c]
	vmul.f32	s0, s0, s0
	vmul.f32	s2, s2, s2
	vadd.f32	s2, s0, s2
	vsqrt.f32	s0, s2
	vcmp.f32	s0, s0
	vmrs	APSR_nzcv, fpscr
	bvs.n	.L080256b6
.L0802564c:
	vstr	s0, [r10, #0x14]
	vldr	s0, [r6, #0x30]
	vldr	s2, [r6, #0x34]
	vmul.f32	s0, s0, s0
	vmul.f32	s2, s2, s2
	vadd.f32	s2, s0, s2
	vsqrt.f32	s0, s2
	vcmp.f32	s0, s0
	vmrs	APSR_nzcv, fpscr
	bvs.n	.L080256c2
.L08025672:
	vstr	s0, [r10, #0x18]
	vldr	s0, [r6, #0x38]
	vldr	s2, [r6, #0x3c]
	vmul.f32	s0, s0, s0
	vmul.f32	s2, s2, s2
	vadd.f32	s2, s0, s2
	vsqrt.f32	s0, s2
	vcmp.f32	s0, s0
	vmrs	APSR_nzcv, fpscr
	bvs.n	.L080256ce
.L08025698:
	adds	r7, #0x10
	cmp.w	r7, #0x1f0
	add.w	r6, r6, #0x20
	vstr	s0, [r10, #0x1c]
	bne.n	.L08025600
	b.n	.L08025718
.L080256aa:
	vmov.f32	s0, s2
	bl	sqrt_f32_checked
	ldr	r4, [sp, #0xc]
	b.n	.L08025622
.L080256b6:
	vmov.f32	s0, s2
	bl	sqrt_f32_checked
	ldr	r4, [sp, #0xc]
	b.n	.L0802564c
.L080256c2:
	vmov.f32	s0, s2
	bl	sqrt_f32_checked
	ldr	r4, [sp, #0xc]
	b.n	.L08025672
.L080256ce:
	vmov.f32	s0, s2
	bl	sqrt_f32_checked
	ldr	r4, [sp, #0xc]
	b.n	.L08025698
	.short	0xbf00			@ padding
.L080256dc:
	add.w	r4, r2, r5, lsl #2
	ldr.w	r0, [r4, #0xc]!
	cmp	r0, #0
	beq.w	.L08025242
	ldrb	r1, [r7, #0x10]
	cmp	r1, #0
	beq.w	.L08025238
	ldr	r1, [r7, #8]
	subs	r0, r0, r1
	lsrs	r1, r0, #10
	cmp	r1, #0xae
	bhi.w	.L0802523e
	ldr	r2, [r7, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cmp	r1, #0
	beq.w	.L0802523e
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	bl	zero_bytes
	b.n	.L0802523e
.L08025718:
	vldr	s0, [r4]
	mvn	r0, #0xf
	vmov.f32	s2, s0
.L08025724:
	adds	r1, r4, r0
	vldr	s4, [r1, #0x14]
	vldr	s6, [r1, #0x18]
	vldr	s8, [r1, #0x1c]
	vcmp.f32	s2, s4
	vldr	s10, [r1, #0x20]
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s2, s4
	vcmp.f32	s2, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s2, s6
	vcmp.f32	s2, s8
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s2, s8
	vcmp.f32	s2, s10
	vmrs	APSR_nzcv, fpscr
	add.w	r0, r0, #0x10
	it	lt
	vmovlt.f32	s2, s10
	cmp.w	r0, #0x1e0
	bne.n	.L08025724
	vldr	s4, [r4, #0x1f4]
	vldr	s8, [r4, #0x1f8]
	vcmp.f32	s2, s4
	vldr	s6, [r4, #0x1fc]
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s2, s4
	vcmp.f32	s2, s8
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s2, s8
	ldr	r5, [sp, #8]
	movw	r7, #0x1070
	mvn	r0, #0xf
	vmov.f32	s4, s0
	movt	r7, #0x2000
	nop
.L080257b4:
	adds	r1, r4, r0
	vldr	s8, [r1, #0x14]
	vldr	s10, [r1, #0x18]
	vldr	s12, [r1, #0x1c]
	vcmp.f32	s4, s8
	vldr	s14, [r1, #0x20]
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s4, s8
	vcmp.f32	s4, s10
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s4, s10
	vcmp.f32	s4, s12
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s4, s12
	vcmp.f32	s4, s14
	vmrs	APSR_nzcv, fpscr
	add.w	r0, r0, #0x10
	it	gt
	vmovgt.f32	s4, s14
	cmp.w	r0, #0x1e0
	bne.n	.L080257b4
	vcmp.f32	s2, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s2, s6
	vldr	s6, [r4, #0x1f4]
	vldr	s8, [r4, #0x1f8]
	vldr	s10, [r4, #0x1fc]
	vcmp.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s4, s6
	vcmp.f32	s4, s8
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s4, s8
	vcmp.f32	s4, s10
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s4, s10
	vabs.f32	s2, s2
	vabs.f32	s4, s4
	vcmp.f32	s2, s4
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s4, s2
	vdiv.f32	s2, s4, s18
	ldr.w	r0, [r9]
	vdiv.f32	s0, s0, s2
	vcvt.s32.f32	s0, s0
	vmov	r1, s0
	strb	r1, [r0]
	add.w	r0, r4, #8
	movs	r1, #4
	nop
.L08025880:
	vldr	s0, [r0, #-4]
	ldr.w	r2, [r9]
	vdiv.f32	s0, s0, s2
	add	r2, r1
	cmp	r1, #0x80
	vcvt.s32.f32	s0, s0
	vmov	r3, s0
	strb.w	r3, [r2, #-3]
	vldr	s0, [r0]
	ldr.w	r2, [r9]
	vdiv.f32	s0, s0, s2
	add	r2, r1
	vcvt.s32.f32	s0, s0
	vmov	r3, s0
	strb.w	r3, [r2, #-2]
	vldr	s0, [r0, #4]
	ldr.w	r2, [r9]
	vdiv.f32	s0, s0, s2
	add	r2, r1
	vcvt.s32.f32	s0, s0
	vmov	r3, s0
	strb.w	r3, [r2, #-1]
	beq.n	.L080258ee
	vldr	s0, [r0, #8]
	ldr.w	r2, [r9]
	vdiv.f32	s0, s0, s2
	adds	r0, #0x10
	vcvt.s32.f32	s0, s0
	vmov	r3, s0
	strb	r3, [r2, r1]
	adds	r1, #4
	b.n	.L08025880
.L080258ee:
	ldrb	r0, [r7, #0x10]
	cmp	r0, #0
	beq.w	.L08025a5a
	ldr	r1, [r7, #8]
	subs	r0, r4, r1
	cmp.w	r0, #0x2bc00
	bhs.w	.L08025a76
	ldr	r2, [r7, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cmp	r1, #0
	beq.w	.L08025a60
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	bl	zero_bytes
	b.n	.L08025a60
.L0802591c:
	add.w	r6, r11, #4
	movs	r7, #0
	b.n	.L08025964
.L08025924:
	add	r0, r8
	ldrb.w	r0, [r0, #0x9b0]
	ldrb.w	r1, [r8, #0x350]
.L0802592e:
	subs	r0, r0, r1
.L08025930:
	uxtb	r0, r0
	vmov	s0, r0
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vstr	s0, [r6]
	ldrsb.w	r0, [r2]
	adds	r7, #2
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vsub.f32	s0, s0, s2
	vstr	s0, [r6]
	cmp.w	r7, #0x100
	add.w	r6, r6, #8
	beq.w	.L080253d8
.L08025964:
	add.w	r3, lr, r7
	ldrb.w	r1, [r8, #0x2d]
	mov	r0, r3
	cmp	r1, #4
	bfc	r0, #0xf, #0x11
	mov.w	r1, #0
	blo.n	.L0802598c
	cmp.w	r1, r0, lsr #10
	it	ne
	subne.w	r0, r0, #0x400
	uxtah	r0, r10, r0
	b.n	.L080259a8
	.short	0xbf00			@ padding
.L0802598c:
	cmp.w	r1, r0, lsr #11
	it	ne
	subne.w	r0, r0, #0x800
	uxth	r1, r0
	and.w	r5, r0, #1
	cmp.w	r12, #1
	lsr.w	r0, r1, #1
	bne.n	.L080259b0
	cbnz	r5, .L080259be
.L080259a8:
	add	r0, r8
	ldrb.w	r0, [r0, #0x5b0]
	b.n	.L080259d4
.L080259b0:
	cbnz	r5, .L080259cc
	add	r0, r8
	ldrb.w	r0, [r0, #0x5b0]
	ldrb.w	r1, [r8, #0x351]
	b.n	.L080259c8
.L080259be:
	add	r0, r8
	ldrb.w	r0, [r0, #0x9b0]
	ldrb.w	r1, [r8, #0x350]
.L080259c8:
	subs	r0, r0, r1
	b.n	.L080259d4
.L080259cc:
	add	r0, r8
	ldrb.w	r0, [r0, #0x9b0]
	nop
.L080259d4:
	uxtb	r0, r0
	vmov	s0, r0
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vstr	s0, [r6, #-4]
	ldrsb.w	r0, [r2]
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vsub.f32	s0, s0, s2
	vstr	s0, [r6, #-4]
	ldrb.w	r1, [r8, #0x2d]
	adds	r0, r3, #1
	cmp	r1, #3
	bfc	r0, #0xf, #0x11
	mov.w	r1, #0
	bls.n	.L08025a1c
	cmp.w	r1, r0, lsr #10
	it	ne
	subne.w	r0, r0, #0x400
	uxtah	r0, r10, r0
	b.n	.L08025a3c
.L08025a1c:
	cmp.w	r1, r0, lsr #11
	it	ne
	subne.w	r0, r0, #0x800
	uxth	r1, r0
	and.w	r3, r0, #1
	cmp.w	r12, #1
	lsr.w	r0, r1, #1
	bne.n	.L08025a44
	cmp	r3, #0
	bne.w	.L08025924
.L08025a3c:
	add	r0, r8
	ldrb.w	r0, [r0, #0x5b0]
	b.n	.L08025930
.L08025a44:
	cbnz	r3, .L08025a52
	add	r0, r8
	ldrb.w	r0, [r0, #0x5b0]
	ldrb.w	r1, [r8, #0x351]
	b.n	.L0802592e
.L08025a52:
	add	r0, r8
	ldrb.w	r0, [r0, #0x9b0]
	b.n	.L08025930
.L08025a5a:
	ldr	r1, [r7]
	movs	r0, #0
	blx	r1
.L08025a60:
	ldrb	r0, [r7, #0x10]
	cbz	r0, .L08025a6c
	ldr	r0, [r7, #8]
	sub.w	r0, r11, r0
	b.n	.L08025a7a
.L08025a6c:
	ldr	r1, [r7]
	movs	r0, #0
	blx	r1
	b.w	.L08025242
.L08025a76:
	sub.w	r0, r11, r1
.L08025a7a:
	lsrs	r1, r0, #10
	cmp	r1, #0xae
	bhi.w	.L08025242
	ldr	r2, [r7, #0xc]
	lsrs	r0, r0, #5
	ldrh.w	r1, [r2, r0, lsl #1]
	cmp	r1, #0
	beq.w	.L08025242
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #1
	bl	zero_bytes
	b.w	.L08025242
.L08025a9e:
	add	sp, #0x10
	vpop	{d8, d9}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_08025fc0 - converts the s16 values 0x2000032a..0x20000330 into scaled
@ floats with unit-step bytes; what the display does with them is not
@ determined from the code.
@ Takes two parameters (r0 unused; the second is passed through to the double
@ helpers 0x080438e0); no return value.
@ Does nothing unless byte 0x2000012c is 0.
@ If bit 0 of byte 0x20000332 is set: float 0x20000334 = float(s16 0x2000032a -
@ s16 0x20000112) / 25.0; float 0x20000338 = float(s16 0x2000032c - s16
@ 0x20000112); float 0x2000033c = 0x20000338 - float(s16 0x2000032a - s16
@ 0x20000112) (taken before the division by 25.0).
@ For each of the three floats (the second and third are first divided by
@ 25.0): with b = byte 0x20000125, step byte = ((b/3 + 1) / 3) stored in
@ 0x20000350 / 0x20000351 / 0x20000352, the float is converted to double
@ (0x08045d70) and multiplied (0x0804577c) by double(byte table 0x080465c8
@ [b mod 3]) (0x080455da) times double_pow 0x080438e0(10.0, double((b/3 + 1)
@ mod 3)) (base 10.0 loaded from 0x080263b0, exponent via 0x0804550a), narrowed
@ back to float with 0x08044f48; when |x| >= 1000.0 it is divided by 1000.0
@ once and the step byte is incremented by 1 (the disassembly at
@ 0x080261f4..0x08026202 shows vabs, vcmp with 1000.0, blt skip, vdiv).
@ Then if 0x2000033c == 0.0 stores 0 in float 0x2000034c and byte 0x20000356;
@ otherwise divides 1e9 (double 0x41cdcd6500000000, or 1e9 divided by
@ double_pow 0x080438e0(1000.0, double(byte 0x20000352)) (literal 1000.0 at
@ 0x080263c0) when that byte is non-zero) by |0x2000033c| with 0x08045124 and
@ then, while x >= 1000.0 (0x08045e0c is a less-than test, 0x08045df0 a
@ greater-or-equal test, double 0x408f400000000000 = 1000.0 at 0x080263c0),
@ each step divides x by 1000.0 (0x08045124) and increments byte 0x20000356
@ only while the incremented count is <= 2, otherwise x is divided by 1000.0
@ twice in that step and the count stays; the loop ends when x < 1000.0; byte
@ 0x20000356 is 0 first; then stores float(x) in 0x2000034c.
@ If bit 1 of byte 0x20000332 is set: with idx = byte 0x2000010e, a =
@ float(s16 0x2000032e - signed byte 0x200000fc[idx]) and c = float(s16
@ 0x20000330 - signed byte 0x200000fc[idx]): 0x20000344 = c, 0x20000348 = a -
@ c, 0x20000340 = a; each of the three is multiplied by float(table 0x080465c8
@ [byte 0x200000fa[idx] mod 3] << 2), then divided by 10.0 when byte
@ 0x200000fa[idx] < 3, otherwise multiplied (double_pow 0x080438e0(10.0,
@ double(short((0x200000fa[idx] - 3)/3))) applied through doubles), then
@ multiplied by double_pow 0x080438e0(10.0, double(byte 0x200000fe[idx]))
@ (literal 10.0 at 0x080266e8); bytes 0x20000353 and 0x20000354 are set to 1
@ (and 0x20000340 / 0x20000344 divided by 1000.0) when the value is >= 1000.0
@ in magnitude, else 0; byte 0x20000355 is set to 1 (and 0x20000348 divided by
@ 1000.0) when |0x20000348| >= 1000.0, else 0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08025fc0,"ax",%progbits
	.global fn_08025fc0
	.thumb_func
	.type fn_08025fc0, %function
fn_08025fc0:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #4
	vpush	{d8, d9}
	sub	sp, #8
	movw	r6, #0xf8
	movt	r6, #0x2000
	ldrb.w	r0, [r6, #0x34]
	cmp	r0, #0
	bne.w	.L080266da
	ldrb.w	r0, [r6, #0x23a]
	lsls	r1, r0, #0x1f
	beq.w	.L080263ee
	ldrsh.w	r0, [r6, #0x232]
	ldrsh.w	r1, [r6, #0x1a]
	vmov.f32	s16, #25.0
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s2, s0, s16
	ldrb.w	r0, [r6, #0x2d]
	movw	r10, #0xaaab
	uxtb	r2, r0
	movt	r10, #0xaaaa
	umull	r2, r3, r2, r10
	ldrsh.w	r2, [r6, #0x234]
	mov.w	r9, #1
	subs	r1, r2, r1
	vmov	s4, r1
	lsrs	r1, r3, #1
	sub.w	r1, r1, r1, lsl #2
	add	r0, r1
	movw	r8, #:lower16:d_080465c8
	add.w	r7, r9, r3, lsr #1
	uxtb	r0, r0
	movt	r8, #:upper16:d_080465c8
	umull	r5, r4, r7, r10
	vcvt.f32.s32	s4, s4
	ldrb.w	r0, [r8, r0]
	vsub.f32	s0, s4, s0
	lsrs	r4, r4, #1
	vstr	s2, [r6, #0x23c]
	vstr	s4, [r6, #0x240]
	vstr	s0, [r6, #0x244]
	strb.w	r4, [r6, #0x258]
	bl	u32_to_double
	mov	r11, r0
	add.w	r0, r4, r4, lsl #1
	uxtb	r0, r0
	subs	r0, r7, r0
	mov	r5, r1
	bl	i32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080263b0
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r11
	mov	r3, r5
	bl	double_mul
	mov	r4, r0
	ldr.w	r0, [r6, #0x23c]
	mov	r5, r1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	bl	double_to_float
	vmov	s0, r0
	vldr	s18, .L080263b8
	vabs.f32	s2, s0
	vcmp.f32	s2, s18
	vmrs	APSR_nzcv, fpscr
	str.w	r0, [r6, #0x23c]
	blt.n	.L080260ce
	vdiv.f32	s0, s0, s18
	ldrb.w	r0, [r6, #0x258]
	adds	r0, #1
	strb.w	r0, [r6, #0x258]
	vstr	s0, [r6, #0x23c]
.L080260ce:
	vldr	s0, [r6, #0x240]
	ldrb.w	r0, [r6, #0x2d]
	vdiv.f32	s0, s0, s16
	uxtb	r1, r0
	umull	r1, r2, r1, r10
	add.w	r4, r9, r2, lsr #1
	umull	r1, r3, r4, r10
	lsrs	r1, r2, #1
	sub.w	r1, r1, r1, lsl #2
	add	r0, r1
	uxtb	r0, r0
	ldrb.w	r0, [r8, r0]
	lsrs	r7, r3, #1
	strb.w	r7, [r6, #0x259]
	vstr	s0, [r6, #0x240]
	bl	u32_to_double
	mov	r9, r0
	add.w	r0, r7, r7, lsl #1
	uxtb	r0, r0
	subs	r0, r4, r0
	mov	r5, r1
	bl	i32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080263b0
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r9
	mov	r3, r5
	bl	double_mul
	mov	r4, r0
	ldr.w	r0, [r6, #0x240]
	mov	r5, r1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	bl	double_to_float
	vmov	s0, r0
	vabs.f32	s2, s0
	vcmp.f32	s2, s18
	vmrs	APSR_nzcv, fpscr
	str.w	r0, [r6, #0x240]
	blt.n	.L08026170
	vdiv.f32	s0, s0, s18
	ldrb.w	r0, [r6, #0x259]
	adds	r0, #1
	strb.w	r0, [r6, #0x259]
	vstr	s0, [r6, #0x240]
.L08026170:
	vldr	s0, [r6, #0x244]
	ldrb.w	r0, [r6, #0x2d]
	vdiv.f32	s0, s0, s16
	uxtb	r1, r0
	umull	r1, r2, r1, r10
	movs	r1, #1
	add.w	r4, r1, r2, lsr #1
	umull	r1, r3, r4, r10
	lsrs	r1, r2, #1
	sub.w	r1, r1, r1, lsl #2
	add	r0, r1
	uxtb	r0, r0
	ldrb.w	r0, [r8, r0]
	lsrs	r7, r3, #1
	vstr	s0, [r6, #0x244]
	strb.w	r7, [r6, #0x25a]
	bl	u32_to_double
	mov	r8, r0
	add.w	r0, r7, r7, lsl #1
	uxtb	r0, r0
	subs	r0, r4, r0
	mov	r5, r1
	bl	i32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080263b0
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r8
	mov	r3, r5
	bl	double_mul
	mov	r4, r0
	ldr.w	r0, [r6, #0x244]
	mov	r5, r1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	bl	double_to_float
	vmov	s0, r0
	vabs.f32	s2, s0
	vcmp.f32	s2, s18
	vmrs	APSR_nzcv, fpscr
	str.w	r0, [r6, #0x244]
	blt.n	.L08026214
	vdiv.f32	s0, s0, s18
	ldrb.w	r0, [r6, #0x25a]
	adds	r0, #1
	strb.w	r0, [r6, #0x25a]
	vstr	s0, [r6, #0x244]
.L08026214:
	vcmp.f32	s0, #0.0
	vmrs	APSR_nzcv, fpscr
	bne.n	.L0802622a
	movs	r0, #0
	str.w	r0, [r6, #0x254]
	strb.w	r0, [r6, #0x25e]
	b.n	.L080263ea
.L0802622a:
	ldrb.w	r0, [r6, #0x25a]
	vabs.f32	s16, s0
	cbz	r0, .L0802625a
	bl	u32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080263c0
	bl	double_pow
	vmov	r2, r3, d0
	vldr	d0, .L080263c8
	vmov	r0, r1, d0
	bl	double_div
	vmov	d9, r0, r1
	b.n	.L0802625e
.L0802625a:
	vldr	d9, .L080263c8
.L0802625e:
	vmov	r0, s16
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_div
	vldr	d0, .L080263c0
	movs	r2, #0
	vmov	r8, r9, d0
	strb.w	r2, [r6, #0x25e]
	mov	r2, r8
	mov	r3, r9
	vmov	d8, r0, r1
	bl	double_lt
	cmp	r0, #0
	bne.w	.L080263de
	movs	r4, #0
.L08026294:
	add.w	r10, r4, #1
	uxtb.w	r0, r10
	str	r0, [sp, #4]
	vmov	r0, r1, d8
	mov	r2, r8
	mov	r3, r9
	bl	double_div
	mov	r2, r8
	mov	r3, r9
	mov	r11, r0
	mov	r5, r1
	bl	double_div
	mov	r6, r0
	ldr	r0, [sp, #4]
	mov	r7, r1
	cmp	r0, #2
	itt	ls
	movls	r7, r5
	movls	r6, r11
	mov	r0, r6
	mov	r1, r7
	mov	r2, r8
	mov	r3, r9
	vmov	d8, r6, r7
	it	ls
	movls	r4, r10
	bl	double_ge
	cmp	r0, #0
	beq.n	.L080263d2
	add.w	r10, r4, #1
	uxtb.w	r0, r10
	str	r0, [sp, #4]
	mov	r0, r6
	mov	r1, r7
	mov	r2, r8
	mov	r3, r9
	bl	double_div
	mov	r2, r8
	mov	r3, r9
	mov	r11, r0
	mov	r5, r1
	bl	double_div
	mov	r6, r0
	ldr	r0, [sp, #4]
	mov	r7, r1
	cmp	r0, #2
	itt	ls
	movls	r7, r5
	movls	r6, r11
	mov	r0, r6
	mov	r1, r7
	mov	r2, r8
	mov	r3, r9
	vmov	d8, r6, r7
	it	ls
	movls	r4, r10
	bl	double_lt
	cmp	r0, #0
	bne.n	.L080263d2
	add.w	r10, r4, #1
	uxtb.w	r0, r10
	str	r0, [sp, #4]
	mov	r0, r6
	mov	r1, r7
	mov	r2, r8
	mov	r3, r9
	bl	double_div
	mov	r2, r8
	mov	r3, r9
	mov	r11, r0
	mov	r5, r1
	bl	double_div
	mov	r6, r0
	ldr	r0, [sp, #4]
	mov	r7, r1
	cmp	r0, #2
	itt	ls
	movls	r7, r5
	movls	r6, r11
	mov	r0, r6
	mov	r1, r7
	mov	r2, r8
	mov	r3, r9
	vmov	d8, r6, r7
	it	hi
	movhi	r10, r4
	bl	double_lt
	cbnz	r0, .L080263d0
	add.w	r4, r10, #1
	mov	r0, r6
	mov	r1, r7
	mov	r2, r8
	mov	r3, r9
	uxtb.w	r11, r4
	bl	double_div
	mov	r2, r8
	mov	r3, r9
	mov	r6, r0
	mov	r5, r1
	bl	double_div
	mov	r2, r8
	mov	r3, r9
	cmp.w	r11, #2
	itt	ls
	movls	r1, r5
	movls	r0, r6
	vmov	d8, r0, r1
	it	hi
	movhi	r4, r10
	bl	double_lt
	cmp	r0, #0
	beq.w	.L08026294
	b.n	.L080263d2
	.short	0xbf00, 0xbf00		@ padding
.L080263b0:
	.word	0x00000000, 0x40240000	@ double 10.0
.L080263b8:
	.word	0x447a0000		@ float 1000.0
	.short	0xbf00, 0xbf00		@ padding
.L080263c0:
	.word	0x00000000, 0x408f4000	@ double 1000.0
.L080263c8:
	.word	0x00000000, 0x41cdcd65	@ double 1e9
.L080263d0:
	mov	r4, r10
.L080263d2:
	movw	r6, #0xf8
	movt	r6, #0x2000
	strb.w	r4, [r6, #0x25e]
.L080263de:
	vmov	r0, r1, d8
	bl	double_to_float
	str.w	r0, [r6, #0x254]
.L080263ea:
	ldrb.w	r0, [r6, #0x23a]
.L080263ee:
	lsls	r0, r0, #0x1e
	bpl.w	.L080266da
	ldrb	r1, [r6, #0x16]
	ldrsh.w	r0, [r6, #0x236]
	adds	r2, r6, r1
	ldrsb.w	r3, [r2, #4]
	movw	r5, #0xaaab
	subs	r0, r0, r3
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vstr	s0, [r6, #0x248]
	ldrsh.w	r0, [r6, #0x238]
	ldrsb.w	r3, [r2, #4]
	movt	r5, #0xaaaa
	subs	r0, r0, r3
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vstr	s2, [r6, #0x24c]
	vsub.f32	s2, s0, s2
	vstr	s2, [r6, #0x250]
	ldrb	r0, [r2, #2]
	movw	r4, #:lower16:d_080465c8
	umull	r3, r7, r0, r5
	lsrs	r3, r7, #1
	add.w	r3, r3, r3, lsl #1
	subs	r0, r0, r3
	movt	r4, #:upper16:d_080465c8
	ldrb	r0, [r4, r0]
	movw	r8, #0x5556
	lsls	r0, r0, #2
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vmul.f32	s0, s0, s2
	vstr	s0, [r6, #0x248]
	ldrb	r0, [r2, #2]
	movt	r8, #0x5555
	cmp	r0, #2
	bhi.n	.L08026476
	vmov.f32	s2, #10.0
	vdiv.f32	s0, s0, s2
	b.n	.L080264b8
.L08026476:
	subs	r0, #3
	smmul	r0, r0, r8
	add.w	r0, r0, r0, lsr #31
	sxth	r0, r0
	bl	i32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080266e8
	bl	double_pow
	ldr.w	r0, [r6, #0x248]
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_mul
	bl	double_to_float
	ldrb	r1, [r6, #0x16]
	vmov	s0, r0
.L080264b8:
	vstr	s0, [r6, #0x248]
	adds	r0, r6, r1
	ldrb	r0, [r0, #6]
	bl	u32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080266e8
	bl	double_pow
	ldr.w	r0, [r6, #0x248]
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_mul
	bl	double_to_float
	vmov	s0, r0
	vldr	s18, .L080266f0
	vabs.f32	s2, s0
	vcmp.f32	s2, s18
	str.w	r0, [r6, #0x248]
	movs	r0, #0
	vmrs	APSR_nzcv, fpscr
	strb.w	r0, [r6, #0x25b]
	blt.n	.L0802651e
	vdiv.f32	s0, s0, s18
	movs	r0, #1
	strb.w	r0, [r6, #0x25b]
	vstr	s0, [r6, #0x248]
.L0802651e:
	ldrb	r1, [r6, #0x16]
	vldr	s2, [r6, #0x24c]
	adds	r0, r6, r1
	ldrb	r2, [r0, #2]
	umull	r3, r7, r2, r5
	lsrs	r3, r7, #1
	add.w	r3, r3, r3, lsl #1
	subs	r2, r2, r3
	ldrb	r2, [r4, r2]
	lsls	r2, r2, #2
	vmov	s0, r2
	vcvt.f32.s32	s0, s0
	vmul.f32	s0, s2, s0
	vstr	s0, [r6, #0x24c]
	ldrb	r0, [r0, #2]
	cmp	r0, #3
	bhs.n	.L08026558
	vmov.f32	s2, #10.0
	vdiv.f32	s0, s0, s2
	b.n	.L0802659a
.L08026558:
	subs	r0, #3
	smmul	r0, r0, r8
	add.w	r0, r0, r0, lsr #31
	sxth	r0, r0
	bl	i32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080266e8
	bl	double_pow
	ldr.w	r0, [r6, #0x24c]
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_mul
	bl	double_to_float
	ldrb	r1, [r6, #0x16]
	vmov	s0, r0
.L0802659a:
	vstr	s0, [r6, #0x24c]
	adds	r0, r6, r1
	ldrb	r0, [r0, #6]
	bl	u32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080266e8
	bl	double_pow
	ldr.w	r0, [r6, #0x24c]
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_mul
	bl	double_to_float
	vmov	s0, r0
	vabs.f32	s2, s0
	vcmp.f32	s2, s18
	str.w	r0, [r6, #0x24c]
	movs	r0, #0
	vmrs	APSR_nzcv, fpscr
	strb.w	r0, [r6, #0x25c]
	blt.n	.L080265fc
	vdiv.f32	s0, s0, s18
	movs	r0, #1
	strb.w	r0, [r6, #0x25c]
	vstr	s0, [r6, #0x24c]
.L080265fc:
	ldrb	r1, [r6, #0x16]
	vldr	s2, [r6, #0x250]
	adds	r0, r6, r1
	ldrb	r2, [r0, #2]
	umull	r3, r7, r2, r5
	lsrs	r3, r7, #1
	add.w	r3, r3, r3, lsl #1
	subs	r2, r2, r3
	ldrb	r2, [r4, r2]
	lsls	r2, r2, #2
	vmov	s0, r2
	vcvt.f32.s32	s0, s0
	vmul.f32	s0, s2, s0
	vstr	s0, [r6, #0x250]
	ldrb	r0, [r0, #2]
	cmp	r0, #3
	bhs.n	.L08026636
	vmov.f32	s2, #10.0
	vdiv.f32	s0, s0, s2
	b.n	.L08026678
.L08026636:
	subs	r0, #3
	smmul	r0, r0, r8
	add.w	r0, r0, r0, lsr #31
	sxth	r0, r0
	bl	i32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080266e8
	bl	double_pow
	ldr.w	r0, [r6, #0x250]
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_mul
	bl	double_to_float
	ldrb	r1, [r6, #0x16]
	vmov	s0, r0
.L08026678:
	vstr	s0, [r6, #0x250]
	adds	r0, r6, r1
	ldrb	r0, [r0, #6]
	bl	u32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L080266e8
	bl	double_pow
	ldr.w	r0, [r6, #0x250]
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	bl	float_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_mul
	bl	double_to_float
	vmov	s0, r0
	vabs.f32	s2, s0
	vcmp.f32	s2, s18
	str.w	r0, [r6, #0x250]
	movs	r0, #0
	vmrs	APSR_nzcv, fpscr
	strb.w	r0, [r6, #0x25d]
	blt.n	.L080266da
	vdiv.f32	s0, s0, s18
	movs	r0, #1
	strb.w	r0, [r6, #0x25d]
	vstr	s0, [r6, #0x250]
.L080266da:
	add	sp, #8
	vpop	{d8, d9}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short	0xbf00			@ padding
.L080266e8:
	.word	0x00000000, 0x40240000	@ double 10.0
.L080266f0:
	.word	0x447a0000		@ float 1000.0
	.word	0x00000000		@ padding
