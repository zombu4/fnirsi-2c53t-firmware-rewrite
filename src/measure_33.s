@ measure_33.s - compute_channel_measurements, part 1 (part 2 is included at the end)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ compute_channel_measurements - per-channel measurement values (frequency word,
@ period, duty ratio, high / low time, max, min, peak-to-peak, minimum of the
@ last 10 peak-to-peak values, root of mean square, mean) with optional
@ averaging; the display use is not determined.
@ Takes two parameters (r0 unused, r1 reaches only the double helpers); no
@ return value.
@
@ Time scale T (double) = (100.0 / double(u16 table 0x0804bce0[(0x1c - b) mod 3]))
@ * double_pow 0x080438e0(10.0, double((b+1)/3)) with b = byte 0x20000125
@ (10.0 is loaded from 0x08026ac8; helpers 0x080455da, 0x08045124, 0x0804577c).
@
@ For each channel ch from the high nibble of byte 0x2000010d to below the low
@ nibble: scans the 301 bytes 0x2000044e+ch*0x12d .. +0x12c for min and max
@ (stack copies), mid = min + (max-min)/2, then scans bytes 1..300 with a state
@ machine (a run ends at the first sample of the other side or after index 300):
@  - when byte 0 <= mid the initial run of samples <= mid is skipped, high =
@    number of samples > mid in the next run and low = number of samples <= mid
@    in the run after it;
@  - when byte 0 > mid the initial run of samples > mid is skipped, low = number
@    of samples <= mid in the next run and high = number of samples > mid in the
@    run after it.
@
@ Record at 0x20000148 + ch*0x30 (words):
@  +0    = 1000000000 / period
@  +4    = period = int(sample_count * T) (0x08045450 truncation)
@  +8    = int(high/count * 10000.0)
@  +0xc  = 10000 - that
@  +0x10 = int(high/count * period)
@  +0x14 = period - that
@ When no period is measured (high < 3 or low < 3) count = 0x12d and the words
@ +0/+4 keep their old values; when the old period word is non-zero and not
@ (word +0 < 0x3d4 and byte 0x20000125 > 0xd) count = int(old period / T)
@ clamped to 0x12d when > 300 or < 2 and high is the count of the first count
@ samples at or above mid.
@
@ Record at 0x20000160 + ch*0x30 (words):
@  +0    = max byte, +4 = min byte, each minus signed byte 0x200000fc+ch minus
@          0x80, scaled to int by u16 table 0x0804bfb8[b mod 3] *
@          double_pow 0x080438e0(10.0, double(b/3)) * value (b = byte
@          0x200000fa+ch) and then multiplied by double_pow 0x080438e0(10.0,
@          double(byte 0x200000fe+ch)) (10.0 literal at 0x08026ac8)
@  +8    = +0 minus +4
@  +0xc  = smallest of the last 10 values of +8 (10-word ring at
@          0x20004e20+ch*0x28, index byte 0x20004e70+ch wrapping at 10, nine
@          bubble passes on a stack copy, element 0 taken)
@  +0x10 = 0x08044ba4 (a wrapper that calls 0x080459fc double_sqrt) applied to
@          the mean of squares of (sample - offset - 0x80) over count samples
@          (sum with 0x08044fac, divide 0x08045124), scaled like +0
@  +0x14 = mean of the first count samples (unsigned integer division) minus
@          offset minus 0x80, scaled like +0
@
@ After the channel loop: if byte 0x20000126 is 0 copies the 24 words
@ 0x20000148..0x200001a4 to 0x20000208..0x20000264; otherwise adds each of those
@ 24 words as signed 64-bit values into the sums at 0x20000268..0x20000324 and
@ increments byte 0x20000329; when byte 0x20000329 is 0 at entry (it is not reset
@ in this function) first stores sum/(signed byte 0x20000328) for each of the 24
@ sums into 0x200001a8..0x20000204 with 0x08008732 divide_s64 and clears the
@ sums, or when byte 0x20000328 is 0 clears 0xc0 bytes at 0x20000268 with
@ 0x0800857c zero_bytes_aligned; then copies the 24 words 0x200001a8..0x20000204
@ to 0x20000208..0x20000264.
@ Finally stores the word 0x20000204 (or 0x200001a4 in the unaveraged case) into
@ 0x20000264.
@ ----------------------------------------------------------------------------
	.section .text.compute_channel_measurements,"ax",%progbits
	.global compute_channel_measurements
	.thumb_func
	.type compute_channel_measurements, %function
compute_channel_measurements:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #4
	vpush	{d8, d9, d10, d11}
	sub	sp, #0x68
	movw	r8, #0xf8
	movt	r8, #0x2000			@ r8 = 0x200000f8 (settings block)
	ldrb.w	r4, [r8, #0x2d]			@ b = byte 0x20000125
	movw	r1, #0x5556
	rsb.w	r0, r4, #0x1c
	movt	r1, #0x5555
	smmul	r1, r0, r1
	add.w	r1, r1, r1, lsr #31
	add.w	r1, r1, r1, lsl #1
	subs	r0, r0, r1			@ (0x1c - b) mod 3
	movw	r1, #:lower16:d_0804bce0
	sxth	r0, r0
	movt	r1, #:upper16:d_0804bce0
	ldrh.w	r0, [r1, r0, lsl #1]
	bl	u32_to_double
	vldr	d0, .L08026ac0			@ 100.0
	mov	r2, r0
	vmov	r5, r7, d0
	mov	r3, r1
	mov	r0, r5
	mov	r1, r7
	bl	double_div
	movw	r11, #0xaaab
	adds	r2, r4, #1
	movt	r11, #0xaaaa
	umull	r2, r3, r2, r11
	mov	r4, r0
	lsrs	r0, r3, #1			@ (b+1)/3
	mov	r6, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L08026ac8			@ 10.0
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r4
	mov	r3, r6
	bl	double_mul			@ T
	ldrb.w	r3, [r8, #0x15]			@ byte 0x2000010d (channel nibbles)
	mov	lr, r8
	and	r2, r3, #0xf
	cmp.w	r2, r3, lsr #4
	lsr.w	r8, r3, #4			@ r8 = channel index
	str	r3, [sp, #0x2c]
	bls.w	.L08026c3a
	strd	r1, r0, [sp, #0x18]		@ T saved
	movw	r0, #0x12d
	smlabb	r0, r8, r0, lr
	vldr	d8, .L08026ac8			@ d8 = 10.0
	vldr	d9, .L08026ad0			@ d9 = 10000.0
	vldr	d10, .L08026ad8			@ d10 = 0.0
	addw	r9, r0, #0x356
	addw	r11, r0, #0x357
	add.w	r10, sp, #0x66
	strd	r7, r5, [sp, #0x20]		@ 100.0 / u16 saved
	b.n	.L0802690e
	.short	0xbf00				@ padding
.L080267c4:
	ldrb.w	r5, [lr, #0x2d]
	add.w	r10, r1, r0
	add	r0, sp, #0x60
	movw	r1, #0x5556
	strh.w	r10, [r0, r8, lsl #1]
	rsb.w	r0, r5, #0x1c
	movt	r1, #0x5555
	smmul	r1, r0, r1
	add.w	r1, r1, r1, lsr #31
	add.w	r1, r1, r1, lsl #1
	subs	r0, r0, r1
	movw	r2, #:lower16:d_0804bce0
	sxth	r0, r0
	movt	r2, #:upper16:d_0804bce0
	ldrh.w	r0, [r2, r0, lsl #1]
	uxth.w	r1, r10
	str.w	r1, [r9, #0]
	str	r3, [sp, #0x34]
	bl	u32_to_double
	mov	r2, r0
	mov	r3, r1
	ldrd	r1, r0, [sp, #0x20]
	bl	double_div
	movw	r3, #0xaaab
	adds	r2, r5, #1
	movt	r3, #0xaaaa
	umull	r2, r3, r2, r3
	mov	r7, r6
	mov	r6, r0
	lsrs	r0, r3, #1
	mov	r5, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r6
	mov	r3, r5
	bl	double_mul
	mov	r5, r0
	ldr.w	r0, [r9, #0]
	mov	r6, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r5
	mov	r1, r6
	mov	r6, r7
	bl	double_mul
	bl	double_to_i32
	mov	r7, r0
	movw	r0, #0xca00
	movt	r0, #0x3b9a			@ 1000000000
	sdiv	r0, r0, r7
	ldr	r1, [sp, #0x34]
	str.w	r7, [r9, #0]
	str	r0, [r1, #0]
	mov	r0, r4
	bl	u32_to_double
	vmov	d11, r0, r1
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb	r0, [r0, #0x15]
	ldr.w	r9, [sp, #0x30]
	str	r0, [sp, #0x2c]
.L08026898:
	uxth.w	r0, r10
	bl	u32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d11
	bl	double_div
	vmov	d11, r0, r1
.L080268b0:
	mov	r0, r7
	bl	i32_to_double
	vmov	r4, r5, d11
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	bl	double_to_i32
	subs	r1, r7, r0
	strd	r0, r1, [r6, #0x60]
	vmov	r2, r3, d9
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	bl	double_to_i32
	movw	r1, #0x2710
	subs	r1, r1, r0
	strd	r0, r1, [r6, #0x58]
	ldr	r0, [sp, #0x2c]
	add.w	r8, r8, #1
	and	r2, r0, #0xf
	movw	lr, #0xf8
	addw	r9, r9, #0x12d
	cmp	r8, r2
	addw	r11, r11, #0x12d
	movt	lr, #0x2000
	add.w	r10, sp, #0x66
	bcs.w	.L08026c2c
.L0802690e:
	movw	r0, #0x12d
	mla	r0, r8, r0, lr
	mov.w	r1, #0x12c
	ldrb.w	r2, [r0, #0x356]
	str	r0, [sp, #0x28]
	add	r0, sp, #0x64
	strb.w	r2, [r0, r8]
	mov	r3, r9
	mov	r0, r2
	strb.w	r2, [r10, r8]
	str	r2, [sp, #0x34]
.L08026930:
	ldrb.w	r12, [r3, #0xf]!
	ldrb.w	r6, [r3, #-0xe]
	ldrb.w	r4, [r3, #-0xd]
	cmp	r2, r6
	ldrb.w	r5, [r3, #-0xc]
	ldrb.w	r7, [r3, #-0xb]
	it	lo
	movlo	r2, r6
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r2, r4
	it	lo
	movlo	r2, r4
	cmp	r0, r4
	it	hi
	movhi	r0, r4
	cmp	r2, r5
	it	lo
	movlo	r2, r5
	cmp	r0, r5
	it	hi
	movhi	r0, r5
	cmp	r2, r7
	it	lo
	movlo	r2, r7
	ldrb.w	r6, [r3, #-0xa]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r2, r6
	it	lo
	movlo	r2, r6
	ldrb.w	r7, [r3, #-9]
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r2, r7
	it	lo
	movlo	r2, r7
	ldrb.w	r6, [r3, #-8]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r2, r6
	it	lo
	movlo	r2, r6
	ldrb.w	r7, [r3, #-7]
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r2, r7
	it	lo
	movlo	r2, r7
	ldrb.w	r6, [r3, #-6]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r2, r6
	it	lo
	movlo	r2, r6
	ldrb.w	r7, [r3, #-5]
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r2, r7
	it	lo
	movlo	r2, r7
	ldrb.w	r6, [r3, #-4]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r2, r6
	it	lo
	movlo	r2, r6
	ldrb.w	r7, [r3, #-3]
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r2, r7
	it	lo
	movlo	r2, r7
	ldrb.w	r6, [r3, #-2]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r2, r6
	it	lo
	movlo	r2, r6
	ldrb.w	r7, [r3, #-1]
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r2, r7
	it	lo
	movlo	r2, r7
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r2, r12
	it	lo
	movlo	r2, r12
	cmp	r0, r12
	it	hi
	movhi	r0, r12
	subs	r1, #0xf
	bne.n	.L08026930
	subs	r1, r2, r0			@ max - min
	strb.w	r2, [r10, r8]
	uxth	r2, r1
	add.w	r1, r1, r2, lsr #15
	sxth	r1, r1
	ldr	r5, [sp, #0x34]
	add.w	r4, r0, r1, asr #1		@ mid = min + (max-min)/2
	add	r1, sp, #0x64
	cmp	r4, r5
	strb.w	r0, [r1, r8]
	mov.w	r0, #0
	mov.w	r1, #0
	mov.w	r2, #0
	mov.w	r3, #0
	str.w	r9, [sp, #0x30]
	bge.n	.L08026a8c
.L08026a56:
	cmp	r2, #0
	it	ne
	movne	r2, #1
	add	r0, r2
	lsls	r2, r2, #1
.L08026a60:
	and	r7, r2, #3
.L08026a64:
	cmp.w	r3, #0x12c
	beq.n	.L08026ae8
	ldrb.w	r6, [r11, r3]
	adds	r3, #1
	cmp	r4, r6
	blt.n	.L08026a56
	sbfx	r6, r7, #0, #2
	cmp.w	r6, #0xffffffff
	bgt.n	.L08026a84
	cmp	r7, #2
	bne.n	.L08026a64
	b.n	.L08026ae8
.L08026a84:
	adds	r1, #1
	movs	r2, #1
	b.n	.L08026a60
	.short	0xbf00				@ padding
.L08026a8c:
	cmp	r2, #0
	it	ne
	movne	r2, #1
	add	r1, r2
	lsls	r2, r2, #1
.L08026a96:
	and	r7, r2, #3
	nop
.L08026a9c:
	cmp.w	r3, #0x12c
	beq.n	.L08026ae8
	ldrb.w	r6, [r11, r3]
	adds	r3, #1
	cmp	r4, r6
	bge.n	.L08026a8c
	sbfx	r6, r7, #0, #2
	cmp.w	r6, #0xffffffff
	bgt.n	.L08026ae0
	cmp	r7, #2
	bne.n	.L08026a9c
	b.n	.L08026ae8
	.short	0xbf00, 0xbf00			@ padding
.L08026ac0:
	.word	0x00000000, 0x40590000		@ 100.0
.L08026ac8:
	.word	0x00000000, 0x40240000		@ 10.0
.L08026ad0:
	.word	0x00000000, 0x40c38800		@ 10000.0
.L08026ad8:
	.word	0x00000000, 0x00000000		@ 0.0
.L08026ae0:
	adds	r0, #1
	movs	r2, #1
	b.n	.L08026a96
	.short	0xbf00				@ padding
.L08026ae8:
	add.w	r2, r8, r8, lsl #1
	add.w	r6, lr, r2, lsl #4		@ r6 = 0x20000148 + ch*0x30 area base
	mov	r9, r6
	ldr.w	r7, [r9, #0x54]!		@ old period word
	sub.w	r3, r9, #4
	cbz	r7, .L08026b0c
	ldr	r2, [r3, #0]
	cmp.w	r2, #0x3d4
	bge.n	.L08026b2c
	ldrb.w	r2, [lr, #0x2d]
	cmp	r2, #0xe
	blo.n	.L08026b2c
.L08026b0c:
	uxth	r4, r0				@ high
	cmp	r4, #3
	blo.n	.L08026b1a
	uxth	r2, r1				@ low
	cmp	r2, #3
	bhs.w	.L080267c4
.L08026b1a:
	movw	r10, #0x12d
	add	r1, sp, #0x60
	ldr.w	r9, [sp, #0x30]
	strh.w	r10, [r1, r8, lsl #1]
	b.n	.L08026c18
	.short	0xbf00				@ padding
.L08026b2c:
	mov	r0, r7
	bl	i32_to_double
	ldrd	r3, r2, [sp, #0x18]
	bl	double_div
	bl	double_to_i32
	mov	r10, r0
	cmp.w	r0, #0x12c
	movw	r0, #0x12d
	it	hi
	movhi	r10, r0
	cmp.w	r10, #2
	it	lo
	movwlo	r10, #0x12d
	cmp.w	r10, #0
	add	r0, sp, #0x60
	strh.w	r10, [r0, r8, lsl #1]
	beq.n	.L08026b7c
	cmp	r4, r5
	mov.w	r0, #0
	it	le
	movle	r0, #1
	cmp.w	r10, #1
	bne.n	.L08026b8a
	ldr.w	r9, [sp, #0x30]
	mov.w	r10, #1
	b.n	.L08026c18
.L08026b7c:
	vmov.f32	s22, s20
	ldr.w	r9, [sp, #0x30]
	vmov.f32	s23, s21
	b.n	.L080268b0
.L08026b8a:
	sub.w	r1, r10, #2
	ldr.w	r9, [sp, #0x30]
	cmp	r1, #3
	sub.w	lr, r10, #1
	bcs.n	.L08026ba4
	movs	r2, #1
	ands	r1, lr, #3
	bne.n	.L08026bee
	b.n	.L08026c18
.L08026ba4:
	bic	r12, lr, #3
	rsb.w	r3, r12, #0
	mov	r5, r9
	str	r7, [sp, #0x14]
	str	r6, [sp, #0x34]
	nop
.L08026bb4:
	ldrb.w	r2, [r5, #4]!
	ldrb.w	r1, [r5, #-3]
	ldrb.w	r6, [r5, #-2]
	ldrb.w	r7, [r5, #-1]
	cmp	r4, r1
	it	le
	addle	r0, #1
	cmp	r4, r6
	it	le
	addle	r0, #1
	cmp	r4, r7
	it	le
	addle	r0, #1
	cmp	r4, r2
	it	le
	addle	r0, #1
	adds	r3, #4
	bne.n	.L08026bb4
	ldr	r6, [sp, #0x34]
	ldr	r7, [sp, #0x14]
	orr	r2, r12, #1
	ands	r1, lr, #3
	beq.n	.L08026c18
.L08026bee:
	ldr	r3, [sp, #0x28]
	add	r2, r3
	ldrb.w	r3, [r2, #0x356]
	cmp	r4, r3
	it	le
	addle	r0, #1
	cmp	r1, #1
	beq.n	.L08026c18
	ldrb.w	r3, [r2, #0x357]
	cmp	r4, r3
	it	le
	addle	r0, #1
	cmp	r1, #2
	beq.n	.L08026c18
	ldrb.w	r1, [r2, #0x358]
	cmp	r4, r1
	it	le
	addle	r0, #1
.L08026c18:
	uxth	r4, r0
	mov	r0, r4
	bl	u32_to_double
	vmov	d11, r0, r1
	cmp	r4, #0
	bne.w	.L08026898
	b.n	.L080268b0
.L08026c2c:
	ldr	r0, [sp, #0x2c]
	movw	r11, #0xaaab
	lsr.w	r8, r0, #4
	movt	r11, #0xaaaa
.L08026c3a:
	cmp	r8, r2
	bcs.w	.L0802730a
	ldr	r0, [sp, #0x2c]
	vldr	d8, .L08026ac8			@ d8 = 10.0
	lsr.w	r10, r0, #4
	movw	r0, #0x12d
	mla	r0, r10, r0, lr
	vldr	d10, .L08026ad8			@ d10 = 0.0
	addw	r0, r0, #0x355
	movs	r6, #0
	add.w	r9, sp, #0x38
	str.w	r10, [sp, #0x14]
	b.n	.L08026d60
	.short	0xbf00				@ padding
.L08026c68:
	mov	r0, r7
	mov	r8, r10
	bl	u32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_div
	vmov	d0, r0, r1
	bl	double_sqrt_checked
	vmov	r0, r1, d0
	bl	double_to_i32
	ldr	r1, [sp, #0x28]
	movw	r7, #0xaaab
	ldrb	r1, [r1, #0]
	movt	r7, #0xaaaa
	uxtb	r2, r1
	umull	r2, r3, r2, r7
	lsrs	r4, r3, #1
	sub.w	r2, r4, r4, lsl #2
	add	r1, r2
	movw	r2, #:lower16:d_0804bfb8
	uxtb	r1, r1
	movt	r2, #:upper16:d_0804bfb8
	mov	r11, r7
	ldrh.w	r1, [r2, r1, lsl #1]
	ldr	r7, [sp, #0x2c]
	ldr.w	r10, [sp, #0x20]
	str	r0, [r7, #0x78]
	mov	r0, r1
	bl	u32_to_double
	mov	r5, r0
	mov	r0, r4
	mov	r6, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r5
	mov	r3, r6
	bl	double_mul
	mov	r4, r0
	ldr	r0, [r7, #0x78]
	mov	r5, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	bl	double_to_i32
	ldr	r1, [sp, #0x30]
	str	r0, [r7, #0x78]
	ldrb	r1, [r1, #0]
	mov	r0, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	ldr	r0, [r7, #0x78]
	vmov.f32	s18, s0
	vmov.f32	s19, s1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_mul
	bl	double_to_i32
	str	r0, [r7, #0x78]
	ldrb.w	r0, [r8, #0x15]
	add.w	r10, r10, #1
	and	r0, r0, #0xf
	ldr	r6, [sp, #0x1c]
	cmp	r10, r0
	ldr	r0, [sp, #0x24]
	mov	lr, r8
	add.w	r6, r6, #1
	addw	r0, r0, #0x12d
	bcs.w	.L0802730a
.L08026d60:
	add.w	r8, lr, r10
	mov	r3, r8
	str	r0, [sp, #0x24]
	add.w	r0, sp, #0x66
	str.w	r8, [sp, #0x30]
	ldrb.w	r1, [r8, #2]!
	ldrsb.w	r2, [r3, #4]!
	ldrb.w	r0, [r0, r10]
	str	r3, [sp, #0x34]
	uxtb	r3, r1
	umull	r3, r7, r3, r11
	subs	r0, r0, r2
	add.w	r2, r10, r10, lsl #1
	add.w	r11, lr, r2, lsl #4
	subs	r0, #0x80
	lsrs	r4, r7, #1
	str.w	r0, [r11, #0x68]
	sub.w	r0, r4, r4, lsl #2
	add	r0, r1
	ldr	r1, [sp, #0x14]
	movw	r2, #:lower16:d_0804bfb8
	uxtb	r0, r0
	movt	r2, #:upper16:d_0804bfb8
	add	r1, r6
	ldrh.w	r0, [r2, r0, lsl #1]
	movw	r2, #0x4e20
	add.w	r1, r1, r1, lsl #2
	movt	r2, #0x2000
	add.w	r1, r2, r1, lsl #3
	str	r6, [sp, #0x1c]
	str	r1, [sp, #0x18]
	bl	u32_to_double
	mov	r5, r0
	mov	r0, r4
	mov	r6, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r5
	mov	r3, r6
	bl	double_mul
	mov	r4, r0
	ldr.w	r0, [r11, #0x68]
	mov	r5, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	bl	double_to_i32
	ldr	r2, [sp, #0x30]
	str.w	r0, [r11, #0x68]
	ldrb.w	r1, [r2, #6]!
	mov	r0, r1
	str	r2, [sp, #0x30]
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	ldr.w	r0, [r11, #0x68]
	vmov.f32	s18, s0
	vmov.f32	s19, s1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_mul
	bl	double_to_i32
	ldrb.w	r1, [r8]
	movw	r3, #0xaaab
	uxtb	r2, r1
	movt	r3, #0xaaaa
	umull	r2, r3, r2, r3
	ldr	r7, [sp, #0x34]
	lsrs	r4, r3, #1
	add	r2, sp, #0x64
	sub.w	r3, r4, r4, lsl #2
	ldrb.w	r2, [r2, r10]
	ldrsb.w	r7, [r7]
	add	r1, r3
	movw	r3, #:lower16:d_0804bfb8
	uxtb	r1, r1
	movt	r3, #:upper16:d_0804bfb8
	subs	r2, r2, r7
	ldrh.w	r1, [r3, r1, lsl #1]
	subs	r2, #0x80
	strd	r0, r2, [r11, #0x68]
	mov	r0, r1
	str.w	r8, [sp, #0x28]
	bl	u32_to_double
	mov	r5, r0
	mov	r0, r4
	mov	r6, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r5
	mov	r3, r6
	bl	double_mul
	mov	r4, r0
	ldr.w	r0, [r11, #0x6c]
	mov	r5, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	bl	double_mul
	bl	double_to_i32
	ldr	r1, [sp, #0x30]
	str.w	r0, [r11, #0x6c]
	ldrb	r1, [r1, #0]
	mov	r0, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	ldrd	r4, r0, [r11, #0x68]
	vmov.f32	s18, s0
	vmov.f32	s19, s1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_mul
	bl	double_to_i32
	add	r1, sp, #0x60
	ldrh.w	r8, [r1, r10, lsl #1]		@ sample count
	str.w	r0, [r11, #0x6c]
	subs	r0, r4, r0
	str.w	r11, [sp, #0x2c]
	cmp.w	r8, #0
	str.w	r0, [r11, #0x70]!
	beq.n	.L08026f3c
	sub.w	r0, r8, #1
	ldr	r3, [sp, #0x24]
	cmp	r0, #3
	bcs.n	.L08026f48
	mov.w	r12, #0
	movs	r0, #0
	b.n	.L08026f70
.L08026f3c:
	movw	r6, #:lower16:d_0804bfb8
	movs	r0, #0
	movt	r6, #:upper16:d_0804bfb8
	b.n	.L08026fb8
.L08026f48:
	bic	r12, r8, #3
	rsb.w	r2, r12, #0
	movs	r0, #0
	nop
.L08026f54:
	ldrb.w	r7, [r3, #4]!
	adds	r2, #4
	ldrb.w	r6, [r3, #-3]
	ldrb.w	r5, [r3, #-2]
	ldrb.w	r1, [r3, #-1]
	add	r0, r6
	add	r0, r5
	add	r0, r1
	add	r0, r7
	bne.n	.L08026f54
.L08026f70:
	movw	r6, #:lower16:d_0804bfb8
	movt	r6, #:upper16:d_0804bfb8
	ands	r3, r8, #3
	beq.n	.L08026fb8
	movw	r1, #0xf8
	movt	r1, #0x2000
	movw	r2, #0x12d
	mla	r2, r10, r2, r1
	cmp	r3, #1
	add.w	r7, r2, r12
	ldrb.w	r7, [r7, #0x356]
	add	r0, r7
	beq.n	.L08026fb8
	orr	r1, r12, #1
	add	r1, r2
	ldrb.w	r1, [r1, #0x356]
	cmp	r3, #2
	add	r0, r1
	beq.n	.L08026fb8
	orr	r1, r12, #2
	add	r1, r2
	ldrb.w	r1, [r1, #0x356]
	add	r0, r1
.L08026fb8:
	ldr	r1, [sp, #0x28]
	ldr	r2, [sp, #0x34]
	ldrb	r1, [r1, #0]
	movw	r7, #0xaaab
	uxtb	r3, r1
	movt	r7, #0xaaaa
	udiv	r0, r0, r8
	ldrsb.w	r2, [r2]
	umull	r3, r7, r3, r7
	lsrs	r5, r7, #1
	subs	r0, r0, r2
	sub.w	r2, r5, r5, lsl #2
	add	r1, r2
	sub.w	r2, r0, #0x80
	uxtb	r0, r1
	ldrh.w	r0, [r6, r0, lsl #1]
	ldr	r4, [sp, #0x2c]
	str	r2, [r4, #0x7c]
	bl	u32_to_double
	mov	r6, r0
	mov	r0, r5
	mov	r7, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r6
	mov	r3, r7
	bl	double_mul
	mov	r5, r0
	ldr	r0, [r4, #0x7c]
	mov	r6, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r5
	mov	r1, r6
	bl	double_mul
	bl	double_to_i32
	ldr	r1, [sp, #0x30]
	str	r0, [r4, #0x7c]
	ldrb	r1, [r1, #0]
	mov	r0, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	ldr	r0, [r4, #0x7c]
	vmov.f32	s18, s0
	vmov.f32	s19, s1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_mul
	bl	double_to_i32
	movw	r7, #0x4e70
	movt	r7, #0x2000
	movw	r3, #0x4e20
	str	r0, [r4, #0x7c]
	ldr.w	r0, [r11]
	ldrb.w	r1, [r7, r10]
	add.w	r2, r10, r10, lsl #2
	movt	r3, #0x2000
	add.w	r2, r3, r2, lsl #3
	str.w	r0, [r2, r1, lsl #2]
	adds	r0, r1, #1
	uxtb	r1, r0
	cmp	r1, #9
	it	hi
	movhi	r0, #0
	ldr	r1, [sp, #0x18]
	strb.w	r0, [r7, r10]
	ldrd	r0, r12, [r1]
	add.w	r7, r1, #8
	ldmia	r7, {r2, r3, r7}
	strd	r0, r12, [sp, #0x38]
	add	r0, sp, #0x40
	ldrd	r6, r5, [r1, #0x14]
	ldr	r4, [r1, #0x1c]
	stmia	r0!, {r2, r3, r7}
	ldrd	r0, r1, [r1, #0x20]
	str.w	r10, [sp, #0x20]
	movw	r10, #0xf8
	strd	r0, r1, [sp, #0x58]
	movs	r0, #0
	movt	r10, #0x2000
	strd	r6, r5, [sp, #0x4c]
	str	r4, [sp, #0x54]
.L080270d4:
	rsb.w	r1, r0, #9
	movs	r3, #0
	movs	r2, #0
.L080270dc:
	adds	r6, r3, #1
	ldr.w	r7, [r9, r3, lsl #2]
	ldr.w	r5, [r9, r6, lsl #2]
	adds	r2, #1
	cmp	r7, r5
	itt	gt
	strgt.w	r5, [r9, r3, lsl #2]
	strgt.w	r7, [r9, r6, lsl #2]
	uxtb	r3, r2
	cmp	r1, r3
	bhi.n	.L080270dc
	rsb.w	r1, r0, #8
	movs	r3, #0
	movs	r2, #0
	nop
.L08027104:
	adds	r6, r3, #1
	ldr.w	r7, [r9, r3, lsl #2]
	ldr.w	r5, [r9, r6, lsl #2]
	adds	r2, #1
	cmp	r7, r5
	itt	gt
	strgt.w	r5, [r9, r3, lsl #2]
	strgt.w	r7, [r9, r6, lsl #2]
	uxtb	r3, r2
	cmp	r1, r3
	bhi.n	.L08027104
	rsb.w	r1, r0, #7
	movs	r3, #0
	movs	r2, #0
	nop
.L0802712c:
	adds	r6, r3, #1
	ldr.w	r7, [r9, r3, lsl #2]
	ldr.w	r5, [r9, r6, lsl #2]
	adds	r2, #1
	cmp	r7, r5
	itt	gt
	strgt.w	r5, [r9, r3, lsl #2]
	strgt.w	r7, [r9, r6, lsl #2]
	uxtb	r3, r2
	cmp	r1, r3
	bhi.n	.L0802712c
	adds	r0, #3
	cmp	r0, #9
	bne.n	.L080270d4
	ldr	r0, [sp, #0x38]			@ element 0 = smallest
	ldr	r1, [sp, #0x2c]
	vmov.f32	s18, s20
	cmp.w	r8, #0
	vmov.f32	s19, s21
	mov	r7, r8
	str	r0, [r1, #0x74]
	beq.w	.L08026c68
	ldr	r0, [sp, #0x34]
	subs	r1, r7, #1
	ldrsb.w	r0, [r0]
	cmp	r1, #3
	mvn	r1, #0x7f
	sub.w	r1, r1, r0
	bcs.n	.L08027190
	vmov.f32	s18, s20
	mov.w	r8, #0
	vmov.f32	s19, s21
	ands	r4, r7, #3
	bne.n	.L08027256
	b.n	.L08026c68
.L08027190:
	bic	r0, r7, #3
	ldr.w	r10, [sp, #0x24]
	vmov.f32	s18, s20
	rsbs	r4, r0, #0
	vmov.f32	s19, s21
	str	r7, [sp, #0x18]
	str	r0, [sp, #0x10]
	nop
.L080271a8:
	ldrb.w	r0, [r10, #4]!
	mov	r8, r1
	str	r0, [sp, #0x34]
	ldrb.w	r0, [r10, #-3]
	ldrb.w	r7, [r10, #-2]
	ldrb.w	r11, [r10, #-1]
	add	r0, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	bl	double_mul
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_add
	mov	r5, r0
	add.w	r0, r8, r7
	mov	r6, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	bl	double_mul
	mov	r2, r0
	mov	r3, r1
	mov	r0, r5
	mov	r1, r6
	bl	double_add
	mov	r5, r0
	add.w	r0, r8, r11
	mov	r6, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	bl	double_mul
	mov	r2, r0
	mov	r3, r1
	mov	r0, r5
	mov	r1, r6
	bl	double_add
	mov	r5, r0
	ldr	r0, [sp, #0x34]
	mov	r6, r1
	add	r0, r8
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	bl	double_mul
	mov	r2, r0
	mov	r3, r1
	mov	r0, r5
	mov	r1, r6
	bl	double_add
	vmov	d9, r0, r1
	mov	r1, r8
	adds	r4, #4
	bne.n	.L080271a8
	movw	r10, #0xf8
	ldr	r7, [sp, #0x18]
	ldr.w	r8, [sp, #0x10]
	movt	r10, #0x2000
	ands	r4, r7, #3
	beq.w	.L08026c68
.L08027256:
	ldr	r2, [sp, #0x20]
	movw	r0, #0x12d
	mla	r0, r2, r0, r10
	mov	r11, r1
	str	r0, [sp, #0x34]
	add	r0, r8
	ldrb.w	r0, [r0, #0x356]
	add	r0, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	bl	double_mul
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_add
	movw	r10, #0xf8
	vmov	d9, r0, r1
	movt	r10, #0x2000
	mov	r6, r1
	cmp	r4, #1
	beq.w	.L08026c68
	ldr	r2, [sp, #0x34]
	mov	r5, r0
	orr	r0, r8, #1
	add	r0, r2
	ldrb.w	r0, [r0, #0x356]
	add	r0, r11
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	bl	double_mul
	mov	r2, r0
	mov	r3, r1
	mov	r0, r5
	mov	r1, r6
	bl	double_add
	movw	r10, #0xf8
	vmov	d9, r0, r1
	movt	r10, #0x2000
	cmp	r4, #2
	beq.w	.L08026c68
	mov	r6, r1
	ldr	r1, [sp, #0x34]
	mov	r5, r0
	orr	r0, r8, #2
	add	r0, r1
	ldrb.w	r0, [r0, #0x356]
	add	r0, r11
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	bl	double_mul
	mov	r2, r0
	mov	r3, r1
	mov	r0, r5
	mov	r1, r6
	bl	double_add
	movw	r10, #0xf8
	movt	r10, #0x2000
	vmov	d9, r0, r1
	b.n	.L08026c68
.L0802730a:
	ldrb.w	r0, [lr, #0x2e]			@ byte 0x20000126
	cbz	r0, .L0802737a
	ldrb.w	r7, [lr, #0x231]		@ byte 0x20000329
	cmp	r7, #0
	beq.n	.L080273d2
	mov	r10, lr
	ldr.w	r0, [r10, #0x1a8]
	ldrd	r11, r5, [lr, #0x190]
	str	r0, [sp, #8]
	ldr.w	r0, [r10, #0x1ac]
	ldr.w	r9, [lr, #0x198]
	str	r0, [sp, #4]
	ldr.w	r0, [r10, #0x1b0]
	add.w	lr, lr, #0x19c
	str	r0, [sp, #0x10]
	ldr.w	r0, [r10, #0x1b4]
	ldm.w	lr, {r3, r12, lr}
	str	r0, [sp, #0xc]
	ldr.w	r0, [r10, #0x1b8]
	str	r0, [sp, #0x18]
	ldr.w	r0, [r10, #0x1bc]
	str	r0, [sp, #0x14]
	ldr.w	r0, [r10, #0x1c0]
	str	r0, [sp, #0x20]
	ldr.w	r0, [r10, #0x1c4]
	str	r0, [sp, #0x1c]
	ldr.w	r0, [r10, #0x1c8]
	str	r0, [sp, #0x28]
	ldr.w	r0, [r10, #0x1cc]
	str	r0, [sp, #0x24]
	ldr.w	r0, [r10, #0x1d0]
	str	r0, [sp, #0x30]
	ldr.w	r0, [r10, #0x1d4]
	str	r0, [sp, #0x2c]
	ldrd	r8, r0, [r10, #0x1d8]
	str	r0, [sp, #0x34]
	b.n	.L08027670
.L0802737a:
	add.w	r7, lr, #0x50
	ldmia	r7, {r0, r1, r2, r3, r7}
	add.w	r12, lr, #0x110
	ldrd	r6, r5, [lr, #0x64]
	stm.w	r12, {r0, r1, r2, r3, r7}
	add.w	r7, lr, #0x70
	ldmia	r7, {r0, r1, r2, r3, r7}
	ldr.w	r4, [lr, #0x6c]
	strd	r6, r5, [lr, #0x124]
	ldrd	r6, r5, [lr, #0x84]
	add.w	r12, lr, #0x130
	stm.w	r12, {r0, r1, r2, r3, r7}
	add.w	r7, lr, #0x90
	str.w	r4, [lr, #0x12c]
	ldr.w	r4, [lr, #0x8c]
	strd	r6, r5, [lr, #0x144]
	ldmia	r7, {r0, r1, r2, r3, r7}
	ldrd	r6, r5, [lr, #0xa4]
	add.w	r12, lr, #0x150
	str.w	r4, [lr, #0x14c]
	stm.w	r12, {r0, r1, r2, r3, r7}
	strd	r6, r5, [lr, #0x164]
	add.w	r0, lr, #0xac
	b.n	.L0802791c
.L080273d2:
	ldrb.w	r4, [lr, #0x230]		@ byte 0x20000328
	cmp	r4, #0
	beq.w	.L08027618
	add.w	r6, lr, #0x170
	ldmia	r6, {r0, r1, r5, r6}
	mov	r2, r4
	movs	r3, #0
	mov.w	r8, #0
	mov	r10, lr
	bl	divide_s64
	str.w	r0, [r10, #0xb0]
	mov	r0, r5
	mov	r1, r6
	mov	r2, r4
	movs	r3, #0
	strd	r8, r8, [r10, #0x170]
	bl	divide_s64
	str.w	r0, [r10, #0xb4]
	ldrd	r0, r1, [r10, #0x180]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x178]
	str.w	r8, [r10, #0x17c]
	bl	divide_s64
	str.w	r0, [r10, #0xb8]
	ldrd	r0, r1, [r10, #0x188]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x180]
	str.w	r8, [r10, #0x184]
	bl	divide_s64
	str.w	r0, [r10, #0xbc]
	ldrd	r0, r1, [r10, #0x190]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x188]
	str.w	r8, [r10, #0x18c]
	bl	divide_s64
	str.w	r0, [r10, #0xc0]
	ldrd	r0, r1, [r10, #0x198]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x190]
	str.w	r8, [r10, #0x194]
	bl	divide_s64
	str.w	r0, [r10, #0xc4]
	ldrd	r0, r1, [r10, #0x1a0]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x198]
	str.w	r8, [r10, #0x19c]
	bl	divide_s64
	add.w	r6, r10, #0x1a8
	str.w	r0, [r10, #0xc8]
	ldmia	r6, {r0, r1, r5, r6}
	mov	r2, r4
	movs	r3, #0
	strd	r8, r8, [r10, #0x1a0]
	bl	divide_s64
	str.w	r0, [r10, #0xcc]
	mov	r0, r5
	mov	r1, r6
	mov	r2, r4
	movs	r3, #0
	strd	r8, r8, [r10, #0x1a8]
	bl	divide_s64
	str.w	r0, [r10, #0xd0]
	ldrd	r0, r1, [r10, #0x1b8]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1b0]
	str.w	r8, [r10, #0x1b4]
	bl	divide_s64
	str.w	r0, [r10, #0xd4]
	ldrd	r0, r1, [r10, #0x1c0]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1b8]
	str.w	r8, [r10, #0x1bc]
	bl	divide_s64
	str.w	r0, [r10, #0xd8]
	ldrd	r0, r1, [r10, #0x1c8]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1c0]
	str.w	r8, [r10, #0x1c4]
	bl	divide_s64
	str.w	r0, [r10, #0xdc]
	ldrd	r0, r1, [r10, #0x1d0]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1c8]
	str.w	r8, [r10, #0x1cc]
	bl	divide_s64
	str.w	r0, [r10, #0xe0]
	ldrd	r0, r1, [r10, #0x1d8]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1d0]
	str.w	r8, [r10, #0x1d4]
	bl	divide_s64
	str.w	r0, [r10, #0xe4]
	ldrd	r0, r1, [r10, #0x1e0]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1d8]
	str.w	r8, [r10, #0x1dc]
	bl	divide_s64
	str.w	r0, [r10, #0xe8]
	ldrd	r0, r1, [r10, #0x1e8]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1e0]
	str.w	r8, [r10, #0x1e4]
	bl	divide_s64
	str.w	r0, [r10, #0xec]
	ldrd	r0, r1, [r10, #0x1f0]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1e8]
	str.w	r8, [r10, #0x1ec]
	bl	divide_s64
	str.w	r0, [r10, #0xf0]
	ldrd	r0, r1, [r10, #0x1f8]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1f0]
	str.w	r8, [r10, #0x1f4]
	bl	divide_s64
	str.w	r0, [r10, #0xf4]
	ldrd	r0, r1, [r10, #0x200]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x1f8]
	str.w	r8, [r10, #0x1fc]
	bl	divide_s64
	str.w	r0, [r10, #0xf8]
	ldrd	r0, r1, [r10, #0x208]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x200]
	str.w	r8, [r10, #0x204]
	bl	divide_s64
	str.w	r0, [r10, #0xfc]
	ldrd	r0, r1, [r10, #0x210]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x208]
	str.w	r8, [r10, #0x20c]
	bl	divide_s64
	str.w	r0, [r10, #0x100]
	ldrd	r0, r1, [r10, #0x218]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x210]
	str.w	r8, [r10, #0x214]
	bl	divide_s64
	str.w	r0, [r10, #0x104]
	ldrd	r0, r1, [r10, #0x220]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x218]
	str.w	r8, [r10, #0x21c]
	bl	divide_s64
	str.w	r0, [r10, #0x108]
	ldrd	r0, r1, [r10, #0x228]
	mov	r2, r4
	movs	r3, #0
	str.w	r8, [r10, #0x220]
	str.w	r8, [r10, #0x224]
	bl	divide_s64
	str.w	r0, [r10, #0x10c]
	strd	r8, r8, [r10, #0x228]
	b.n	.L08027628
.L08027618:
	add.w	r0, lr, #0x170
	movs	r1, #0xc0
	mov	r10, lr
	bl	zero_bytes_aligned		@ clear the 0xc0 bytes of sums
	mov.w	r8, #0
.L08027628:
	movs	r0, #0
	str	r0, [sp, #0x34]
	movs	r0, #0
	str	r0, [sp, #0x30]
	movs	r0, #0
	str	r0, [sp, #0x2c]
	movs	r0, #0
	str	r0, [sp, #0x28]
	movs	r0, #0
	str	r0, [sp, #0x24]
	movs	r0, #0
	str	r0, [sp, #0x20]
	movs	r0, #0
	str	r0, [sp, #0x1c]
	movs	r0, #0
	str	r0, [sp, #0x18]
	movs	r0, #0
	str	r0, [sp, #0x14]
	movs	r0, #0
	str	r0, [sp, #0x10]
	movs	r0, #0
	str	r0, [sp, #0xc]
	movs	r0, #0
	str	r0, [sp, #8]
	movs	r0, #0
	mov.w	r12, #0
	mov.w	lr, #0
	mov.w	r9, #0
	movs	r3, #0
	mov.w	r11, #0
	movs	r5, #0
	str	r0, [sp, #4]
.L08027670:
	adds	r4, r7, #1			@ byte 0x20000329 + 1
	strb.w	r4, [r10, #0x231]
	ldr.w	r0, [r10, #0x50]
	ldrd	r4, r1, [r10, #0x170]
	ldr.w	r2, [r10, #0x68]
	adds	r4, r4, r0
	adc.w	r0, r1, r0, asr #31
	strd	r4, r0, [r10, #0x170]
	ldr.w	r0, [r10, #0x54]
	ldrd	r1, r4, [r10, #0x178]
	ldr.w	r6, [r10, #0x6c]
	adds	r1, r1, r0
	adc.w	r0, r4, r0, asr #31
	strd	r1, r0, [r10, #0x178]
	ldr.w	r0, [r10, #0x58]
	ldrd	r1, r4, [r10, #0x180]
	ldr	r7, [sp, #8]
	adds	r1, r1, r0
	adc.w	r0, r4, r0, asr #31
	strd	r1, r0, [r10, #0x180]
	ldr.w	r0, [r10, #0x5c]
	ldrd	r1, r4, [r10, #0x188]
	adds	r1, r1, r0
	str.w	r1, [r10, #0x188]
	ldr.w	r1, [r10, #0x60]
	adc.w	r0, r4, r0, asr #31
	ldr.w	r4, [r10, #0x64]
	adds.w	r11, r11, r1
	adc.w	r1, r5, r1, asr #31
	adds.w	r5, r9, r4
	str.w	r0, [r10, #0x18c]
	adc.w	r4, r3, r4, asr #31
	adds.w	r3, r12, r2
	ldr	r0, [sp, #4]
	adc.w	r2, lr, r2, asr #31
	adds	r7, r7, r6
	adc.w	r6, r0, r6, asr #31
	ldr.w	r0, [r10, #0xb0]
	.include "src/parts/compute_channel_measurements_p2.inc"
