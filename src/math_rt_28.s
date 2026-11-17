@ math_rt_28.s - 64-bit divide helpers (div10_u64, divide_u64, divide_s64 and their divide-by-zero exits) and the double-to-internal-format / mantissa-divide helpers fn_08043046 and fn_0804312c
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ div10_u64 - unsigned 64-bit divide by 10.
@ In:  r0:r1 = unsigned 64-bit value (low:high).
@ Out: r0:r1 = quotient of the division by 10, computed with shift-and-add
@      reciprocal arithmetic and a final +1 correction; callers read the
@      remainder digit from r2.
@ Saves r4, r5 and lr on the stack; no memory or I/O access, no callees.
@ ----------------------------------------------------------------------------
	.section .text.div10_u64,"ax",%progbits
	.global div10_u64
	.thumb_func
	.type div10_u64, %function
div10_u64:
	push	{r4, r5, lr}
	subs.w	r2, r0, #0xa
	sbcs.w	r3, r1, #0
	lsr.w	lr, r0, #2
	orr.w	lr, lr, r1, lsl #30
	subs.w	r0, r0, lr
	sbc.w	r1, r1, r1, lsr #2
	lsr.w	lr, r0, #4
	orr.w	lr, lr, r1, lsl #28
	adds.w	r0, r0, lr
	adc.w	r1, r1, r1, lsr #4
	lsr.w	lr, r0, #8
	orr.w	lr, lr, r1, lsl #24
	adds.w	r0, r0, lr
	adc.w	r1, r1, r1, lsr #8
	lsr.w	lr, r0, #0x10
	orr.w	lr, lr, r1, lsl #16
	adds.w	r0, r0, lr
	adc.w	r1, r1, r1, lsr #16
	adds	r0, r0, r1
	adc.w	r1, r1, #0
	lsr.w	r0, r0, #3
	orr.w	r0, r0, r1, lsl #29
	lsr.w	r1, r1, #3
	lsl.w	r4, r1, #2
	orr.w	r4, r4, r0, lsr #30
	adds.w	r5, r0, r0, lsl #2
	adc.w	r4, r4, r1
	adds	r5, r5, r5
	adc.w	r4, r4, r4
	subs	r2, r2, r5
	sbcs	r3, r4
	mov.w	r3, #0
	it	mi
	addmi	r2, #0xa
	bpl.n	.L08008392
	pop	{r4, r5, pc}
.L08008392:
	.inst.n 0x1c40	@ adds r0, r0, #1
	adc.w	r1, r1, #0
	pop	{r4, r5, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ divide_u64 - unsigned 64-bit division.
@ In:  r0:r1 = dividend (low:high), r2:r3 = divisor (low:high).
@ Out: r0:r1 = quotient; r2:r3 = remainder.
@ Divisor zero (orrs at 08008642): branches (beq.w at 08008646) to the split-off
@ function divide_u64_by_zero_result, which returns 0 when the dividend is zero
@ and 0xffffffff:0xffffffff otherwise and leaves the dividend in r2:r3.
@ Divisor non-zero (the rest of the body, 0800864a..0800871b, ends with a
@ pop of pc at 08008718): normalises with leading-zero counts and iterates
@ 32-bit division estimates, subtracting estimate times divisor each round.
@ Saves r4-r9, r11 and lr; no memory or I/O access.
@ ----------------------------------------------------------------------------
	.section .text.divide_u64,"ax",%progbits
	.global divide_u64
	.thumb_func
	.type divide_u64, %function
divide_u64:
	orrs.w	r12, r3, r2
	beq.w	divide_u64_by_zero_result
	push.w	{r4, r5, r6, r7, r8, r9, r11, lr}
	mov.w	r6, #0
	cmp	r3, #0
	itttt	ne
	clzne	r5, r3
	lslne.w	r4, r3, r5
	lsrne.w	r6, r4, r5
	eorne	r6, r3
	itee	ne
	orrne	r6, r2
	clzeq	r5, r2
	lsleq.w	r4, r2, r5
	rsb.w	r5, r5, #0x20
	ittt	ne
	lsrne.w	r12, r2, r5
	orrne.w	r4, r4, r12
	addne	r5, #0x20
	orrs.w	r12, r6, r4, lsl #16
	lsr.w	r4, r4, #0x10
	it	ne
	.inst.n 0x1c64	@ addne r4, r4, #1
	mov.w	r8, #0
	mov.w	r9, #0
.L08008694:
	cmp	r0, r2
	sbcs.w	r12, r1, r3
	bcc.n	.L08008710
	cmp	r1, #0
	ittee	ne
	clzne	r7, r1
	lslne.w	r6, r1, r7
	clzeq	r7, r0
	lsleq.w	r6, r0, r7
	rsb.w	r7, r7, #0x20
	ittt	ne
	lsrne.w	r12, r0, r7
	orrne.w	r6, r6, r12
	addne	r7, #0x20
	udiv	r12, r6, r4
	sub.w	r7, r7, r5
	subs	r7, #0x10
	and	r11, r7, #0x1f
	rsb.w	r6, r11, #0x20
	lsr.w	r6, r12, r6
	lsl.w	r11, r12, r11
	itt	mi
	movmi	r11, r6
	movmi	r6, #0
	cmp	r7, #0x20
	itt	ge
	movge	r6, r11
	movge.w	r11, #0
	orrs.w	r12, r11, r6
	it	eq
	moveq.w	r11, #1
	adds.w	r9, r9, r11
	adc.w	r8, r8, r6
	umull	r7, r12, r11, r2
	mla	r12, r6, r2, r12
	mla	r12, r11, r3, r12
	subs	r0, r0, r7
	sbcs.w	r1, r1, r12
	b.n	.L08008694
.L08008710:
	mov	r3, r1
	mov	r2, r0
	mov	r1, r8
	mov	r0, r9
	pop.w	{r4, r5, r6, r7, r8, r9, r11, pc}

@ ----------------------------------------------------------------------------
@ divide_u64_by_zero_result - divide-by-zero exit of the 64-bit unsigned
@ division divide_u64 (08008642).
@ In:  r0:r1 = dividend (low:high), r2:r3 = divisor 0 (entered by beq.w at
@      08008646 after orrs.w ip,r3,r2 set Z for divisor 0).
@ Out: r0:r1 = 0xffffffff:0xffffffff when the dividend is nonzero, 0:0 when it
@      is zero; r2:r3 = the dividend.
@ Code: push {r0,r1,r4,lr}; orrs r0,r0,r1; movne r0,#-1; r1 = r0; nop.w (no
@ call is made); pop {r2,r3,r4,lr} restores the dividend into r2:r3 and lr;
@ bx lr to the caller of divide_u64. The decompiler shows an empty function
@ because it drops the register flow. No fall-in from the preceding pop.
@ ----------------------------------------------------------------------------
	.section .text.divide_u64_by_zero_result,"ax",%progbits
	.global divide_u64_by_zero_result
	.thumb_func
	.type divide_u64_by_zero_result, %function
divide_u64_by_zero_result:
	push	{r0, r1, r4, lr}
	orrs	r0, r1
	it	ne
	movne.w	r0, #0xffffffff
	mov	r1, r0
	nop.w
	pop.w	{r2, r3, r4, lr}
	bx	lr

@ ----------------------------------------------------------------------------
@ divide_s64 - signed 64-bit division.
@ In:  r0:r1 = signed dividend, r2:r3 = signed divisor.
@ Out: r0:r1 = quotient; r2:r3 = remainder with the sign of the dividend.
@ Takes absolute values, calls divide_u64 (08008642, bl at 0800875a), negates
@ the quotient when the signs differ (r4 bit 30, tst at 0800875e) and the
@ remainder when the dividend is negative (r4 bit 31, tst at 0800876e).
@ Divisor zero (orrs at 08008732): branches (beq.n at 08008736) to the
@ split-off function divide_s64_by_zero_result (08008780..080087a5), which
@ returns 0x7fffffff:0xffffffff for a positive dividend, 0:0 for a zero
@ dividend and 0x80000000:0x00000000 for a negative dividend, with the
@ dividend in r2:r3 (pushes r0,r1 at 08008780, pops r2,r3,r4,pc at 080087a4).
@ ----------------------------------------------------------------------------
	.section .text.divide_s64,"ax",%progbits
	.global divide_s64
	.thumb_func
	.type divide_s64, %function
divide_s64:
	orrs.w	r12, r3, r2
	beq.n	divide_s64_by_zero_result
	push	{r4, lr}
	asrs	r4, r1, #1
	eor.w	r4, r4, r3, lsr #1
	bpl.n	.L0800874c
	rsbs	r0, r0, #0
	rsb.w	r1, r1, #0
	it	cc
	.inst.n 0x1e49	@ subcc r1, r1, #1
.L0800874c:
	tst	r3, r3
	bpl.n	.L0800875a
	rsbs	r2, r2, #0
	rsb.w	r3, r3, #0
	it	cc
	.inst.n 0x1e5b	@ subcc r3, r3, #1
.L0800875a:
	bl	divide_u64
	tst.w	r4, #0x40000000
	beq.n	.L0800876e
	rsbs	r0, r0, #0
	rsb.w	r1, r1, #0
	it	cc
	.inst.n 0x1e49	@ subcc r1, r1, #1
.L0800876e:
	tst.w	r4, #0x80000000
	beq.n	.L0800877e
	rsbs	r2, r2, #0
	rsb.w	r3, r3, #0
	it	cc
	.inst.n 0x1e5b	@ subcc r3, r3, #1
.L0800877e:
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ divide_s64_by_zero_result - divide-by-zero exit of the 64-bit signed
@ division divide_s64 (08008732).
@ In:  r0:r1 = dividend (low:high), r2:r3 = divisor 0 (entered by beq.n at
@      08008736 after orrs.w ip,r3,r2 at 08008732).
@ Out: r0 = 0xffffffff and r1 = 0x7fffffff for a positive dividend; r0 = 0 and
@      r1 = 0 for a zero dividend; r0 = 0 and r1 = 0x80000000 for a negative
@      dividend; r2:r3 = the dividend.
@ Code: push {r0,r1,r4,lr}; rsbs r0,r0,#0 and sbcs r4,r0,r1 (08008782..08008788)
@ set the flags of 0 - dividend; movlt r0,#1 gives r0 = 1 when the dividend is
@ positive; r1 = r1 & 0x80000000; when r0 != 0 it sets r1 = 0x7fffffff and
@ r0 = 0xffffffff (08008794..0800879c); nop.w (no call); pop {r2,r3,r4,pc}
@ restores the dividend into r2:r3 and returns to the caller of divide_s64.
@ No fall-in from the pop {r4,pc} of divide_s64.
@ ----------------------------------------------------------------------------
	.global divide_s64_by_zero_result
	.thumb_func
	.type divide_s64_by_zero_result, %function
divide_s64_by_zero_result:
	push	{r0, r1, r4, lr}
	rsbs	r0, r0, #0
	mov.w	r0, #0
	sbcs.w	r4, r0, r1
	it	lt
	movlt	r0, #1
	and	r1, r1, #0x80000000
	cmp	r0, #0
	itt	ne
	mvnne	r1, #0x80000000
	movne.w	r0, #0xffffffff
	nop.w
	pop	{r2, r3, r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08043046 - unpack a 64-bit double into the internal extended format.
@ In:  r0 = high word, r1 = low word of a 64-bit double (sign bit 31, 11-bit
@      exponent in bits 30..20 of r0).
@ Out: r0 = sign bit 31 | (exponent + 0x3c00) (0x08043062 adds 0x7800 to
@      exponent*2 + top mantissa bit, 0x08043066 rotates right through the
@      carry that holds the sign); r1:r2 = the 52-bit mantissa shifted left by
@      11 (r1 high, r2 = r1<<11 at 0x08043054) with bit 31 of r1 set as
@      explicit leading one when the input is nonzero (0x0804306c).
@ Exponent field 0 with a nonzero input is renormalised at 0x080430ca..
@ 0x08043128 (and, when the high mantissa part is zero, at 0x08043084..
@ 0x080430c8) by counting leading zeros in steps 16, 8, 4, 2, 1 and lowering
@ the exponent in r0 by the shift. Exponent field all ones ORs 0x40000000 into
@ r0 (0x0804307e). A zero input returns at 0x080430d0.
@ Pure register arithmetic, no memory access, no calls.
@ ----------------------------------------------------------------------------
	.section .text.fn_08043046,"ax",%progbits
	.global fn_08043046
	.thumb_func
	.type fn_08043046, %function
fn_08043046:
	lsls.w	r12, r0, #1
	it	eq
	teqeq	r1, #0
	lsl.w	r3, r12, #0xa
	lsl.w	r2, r1, #0xb
	orr.w	r1, r3, r1, lsr #21
	lsr.w	r0, r12, #0x14
	it	ne
	addne.w	r0, r0, #0x7800
	rrx	r0, r0
	it	ne
	orrne	r1, r1, #0x80000000
	asrs.w	r12, r12, #0x15
	beq.w	.L080430ca
	cmp.w	r12, #0xffffffff
	it	eq
	orreq	r0, r0, #0x40000000
	bx	lr
.L08043084:
	lsrs	r3, r2, #0x10
	itte	eq
	lsleq	r2, r2, #0x10
	moveq.w	r12, #0x10
	movne.w	r12, #0
	lsrs	r3, r2, #0x18
	itt	eq
	lsleq	r2, r2, #8
	addeq.w	r12, r12, #8
	lsrs	r3, r2, #0x1c
	itt	eq
	lsleq	r2, r2, #4
	addeq.w	r12, r12, #4
	lsrs	r3, r2, #0x1e
	itt	eq
	lsleq	r2, r2, #2
	addeq.w	r12, r12, #2
	lsrs	r3, r2, #0x1f
	itt	eq
	lsleq	r2, r2, #1
	addeq.w	r12, r12, #1
	mov	r1, r2
	mov.w	r2, #0
	sub.w	r0, r0, #0x1f
	sub.w	r0, r0, r12
	bx	lr
.L080430ca:
	tst.w	r1, #0x80000000
	it	eq
	bxeq	lr
	bics	r1, r1, #0x80000000
	beq.w	.L08043084
	lsrs	r3, r1, #0x10
	itte	eq
	lsleq	r1, r1, #0x10
	moveq.w	r12, #0x10
	movne.w	r12, #0
	lsrs	r3, r1, #0x18
	itt	eq
	lsleq	r1, r1, #8
	addeq.w	r12, r12, #8
	lsrs	r3, r1, #0x1c
	itt	eq
	lsleq	r1, r1, #4
	addeq.w	r12, r12, #4
	lsrs	r3, r1, #0x1e
	itt	eq
	lsleq	r1, r1, #2
	addeq.w	r12, r12, #2
	lsrs	r3, r1, #0x1f
	itt	eq
	lsleq	r1, r1, #1
	addeq.w	r12, r12, #1
	rsb.w	r3, r12, #0x20
	lsr.w	r3, r2, r3
	orr.w	r1, r1, r3
	lsl.w	r2, r2, r12
	sub.w	r0, r0, r12
	add.w	r0, r0, #1
	bx	lr
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0804312c - mantissa divide for the internal format used by fn_08043046 and
@ fn_08043464.
@ In:  r0, r3 = sign/exponent words of dividend and divisor; r1:r2 = dividend
@      mantissa (r1 high); r4:r5 = divisor mantissa (r4 high).
@ Sign = (r0^r3)&0x80000000 and exponent = (r0&0xffffff) - (r3&0xffffff) +
@ 0x3fff (0x0804312c..0x08043144); both are pushed at 0x0804314c.
@ The reciprocal estimate starts from the byte table at 0x08043364 + (r4>>24)
@ (0x0804315e..0x08043166; for r4>>24 = 0x80..0xff the bytes are at
@ 0x080433e4..0x08043463), refined by two multiply-and-subtract steps
@ (0x08043168..0x08043198), then five multiply-and-subtract quotient rounds
@ (0x080431ae, 0x080431ea, 0x0804324c, 0x0804328c, 0x080432f0) and three
@ conditional-subtract compare steps (0x08043354, 0x08043374, 0x08043398).
@ Out: r0 = sign, r1:r2 = quotient mantissa (r1 high), r3 = exponent
@      (decremented by 1 when the quotient is shifted left one bit at
@      0x080433d6..0x080433de), r6 = guard/sticky word.
@ Writes only to the stack (push at 0x08043148 and 0x0804314c), one byte-table
@ read at 0x08043166, no calls. The 128-byte reciprocal table sits at the end
@ of the function (0x080433e4).
@ ----------------------------------------------------------------------------
	.section .text.fn_0804312c,"ax",%progbits
	.global fn_0804312c
	.thumb_func
	.type fn_0804312c, %function
fn_0804312c:
	bic	r7, r3, #0xff000000
	bic	r12, r0, #0xff000000
	eor.w	r0, r0, r3
	and	r0, r0, #0x80000000
	sub.w	r3, r12, r7
	add.w	r3, r3, #0x3f00
	add.w	r3, r3, #0xff
	push.w	{r7, r8, r11, lr}
	push	{r0, r3}
	lsr.w	r3, r4, #0x10
	bic.w	r8, r4, r3, lsl #16
	lsr.w	r11, r5, #0x10
	bic.w	lr, r5, r11, lsl #16
	adr.w	r6, .L08043364	@ virtual table base: real bytes start at 0x080433e4 (index 0x80..0xff)
	add.w	r7, r6, r3, lsr #8
	ldrb	r6, [r7, #0]
	mla	r7, r3, r6, r6
	rsb.w	r7, r7, #0x800000
	mul	r6, r7, r6
	lsr.w	r6, r6, #0x13
	add.w	r6, r6, #2
	lsr.w	r7, r4, #0xd
	mla	r12, r7, r6, r6
	rsb.w	r12, r12, #0x20000000
	lsr.w	r7, r12, #0x10
	bic.w	r12, r12, r7, lsl #16
	mul	r5, r12, r6
	mul	r4, r7, r6
	add.w	r6, r4, r5, lsr #16
	lsr.w	r6, r6, #6
	lsrs	r1, r1, #1
	rrxs	r2, r2
	ite	cc
	movcc	r0, #0
	movcs.w	r0, #0x80000000
	lsr.w	r7, r1, #0xf
	mul	r12, r6, r7
	lsr.w	r12, r12, #0x10
	mul	r7, r12, r11
	subs	r2, r2, r7
	mul	r7, r3, r12
	sbc.w	r1, r1, r7
	mul	r7, r12, lr
	subs.w	r0, r0, r7, lsl #16
	sbcs.w	r2, r2, r7, lsr #16
	mul	r7, r12, r8
	ite	cc
	subcc.w	r2, r2, r7, lsl #16
	subscs.w	r2, r2, r7, lsl #16
	sbc.w	r1, r1, r7, lsr #16
	lsl.w	r4, r12, #0x10
	lsr.w	r7, r1, #2
	mul	r12, r6, r7
	lsr.w	r12, r12, #0x10
	mul	r7, r12, r11
	subs.w	r0, r0, r7, lsl #19
	sbcs.w	r2, r2, r7, lsr #13
	mul	r7, r3, r12
	ite	cc
	subcc.w	r2, r2, r7, lsl #19
	subscs.w	r2, r2, r7, lsl #19
	sbc.w	r1, r1, r7, lsr #13
	mul	r7, r12, lr
	subs.w	r0, r0, r7, lsl #3
	sbcs.w	r2, r2, r7, lsr #29
	mul	r7, r12, r8
	ite	cc
	subcc.w	r2, r2, r7, lsl #3
	subscs.w	r2, r2, r7, lsl #3
	sbc.w	r1, r1, r7, lsr #29
	lsl.w	r1, r1, #0x1a
	orr.w	r1, r1, r2, lsr #6
	lsl.w	r2, r2, #0x1a
	orr.w	r2, r2, r0, lsr #6
	lsl.w	r0, r0, #0x1a
	add.w	r4, r4, r12, lsl #3
	ldr	r7, [sp, #0xc]
	lsr.w	r7, r1, #0xf
	mul	r12, r6, r7
	lsr.w	r12, r12, #0x10
	mul	r7, r12, r11
	subs	r2, r2, r7
	mul	r7, r3, r12
	sbc.w	r1, r1, r7
	mul	r7, r12, lr
	subs.w	r0, r0, r7, lsl #16
	sbcs.w	r2, r2, r7, lsr #16
	mul	r7, r12, r8
	ite	cc
	subcc.w	r2, r2, r7, lsl #16
	subscs.w	r2, r2, r7, lsl #16
	sbc.w	r1, r1, r7, lsr #16
	lsl.w	r5, r12, #0x16
	add.w	r4, r4, r12, lsr #10
	lsr.w	r7, r1, #2
	mul	r12, r6, r7
	lsr.w	r12, r12, #0x10
	mul	r7, r12, r11
	subs.w	r0, r0, r7, lsl #19
	sbcs.w	r2, r2, r7, lsr #13
	mul	r7, r3, r12
	ite	cc
	subcc.w	r2, r2, r7, lsl #19
	subscs.w	r2, r2, r7, lsl #19
	sbc.w	r1, r1, r7, lsr #13
	mul	r7, r12, lr
	subs.w	r0, r0, r7, lsl #3
	sbcs.w	r2, r2, r7, lsr #29
	mul	r7, r12, r8
	ite	cc
	subcc.w	r2, r2, r7, lsl #3
	subscs.w	r2, r2, r7, lsl #3
	sbc.w	r1, r1, r7, lsr #29
	lsl.w	r1, r1, #0x1a
	orr.w	r1, r1, r2, lsr #6
	lsl.w	r2, r2, #0x1a
	orr.w	r2, r2, r0, lsr #6
	lsl.w	r0, r0, #0x1a
	adds.w	r5, r5, r12, lsl #9
	adc.w	r4, r4, #0
	lsr.w	r7, r1, #0xf
	mul	r12, r6, r7
	lsr.w	r12, r12, #0x10
	mul	r7, r12, r11
	subs	r2, r2, r7
	mul	r7, r3, r12
	sbc.w	r1, r1, r7
	mul	r7, r12, lr
	subs.w	r0, r0, r7, lsl #16
	sbcs.w	r2, r2, r7, lsr #16
	mul	r7, r12, r8
	ite	cc
	subcc.w	r2, r2, r7, lsl #16
	subscs.w	r2, r2, r7, lsl #16
	sbc.w	r1, r1, r7, lsr #16
	lsl.w	r1, r1, #0xe
	orr.w	r1, r1, r2, lsr #18
	lsl.w	r2, r2, #0xe
	orr.w	r2, r2, r0, lsr #18
	lsl.w	r0, r0, #0xe
	lsl.w	r6, r12, #0x1c
	adds.w	r5, r5, r12, lsr #4
	adc.w	r4, r4, #0
	orr.w	r3, r8, r3, lsl #16
	orr.w	r8, lr, r11, lsl #16
	mov.w	lr, #0
	subs.w	r12, r2, r8
	sbcs.w	r7, r1, r3
	itt	cs
	movcs	r2, r12
	movcs	r1, r7
	adc.w	lr, lr, lr
	mov.w	r11, #0
	adds	r0, r0, r0
	adcs	r2, r2
	adcs	r1, r1
	adc.w	r11, r11, r11
	subs.w	r12, r2, r8
	sbcs.w	r7, r1, r3
	sbcs.w	r11, r11, #0
	itt	cs
	movcs	r2, r12
	movcs	r1, r7
	adc.w	lr, lr, lr
	mov.w	r11, #0
	adds	r0, r0, r0
	adcs	r2, r2
	adcs	r1, r1
	adc.w	r11, r11, r11
	subs.w	r12, r2, r8
	sbcs.w	r7, r1, r3
	sbcs.w	r11, r11, #0
	itt	cs
	movcs	r2, r12
	movcs	r1, r7
	adc.w	lr, lr, lr
	orrs.w	r7, r1, r2
	it	ne
	orrne.w	r6, r6, #1
	adds.w	r6, r6, lr, lsl #28
	adcs.w	r2, r5, #0
	adcs.w	r1, r4, #0
	bpl.n	.L080433ce
	pop.w	{r0, r3, r7, r8}
	pop.w	{r11, pc}
.L080433ce:
	pop.w	{r0, r3, r7, r8}
	pop.w	{r11, lr}
	adds	r6, r6, r6
	adcs	r2, r2
	adc.w	r1, r1, r1
	sub.w	r3, r3, #1
	bx	lr
.L080433e4:
	.incbin "assets/blobs/080433e4.bin"
	.set	.L08043364, .L080433e4 - 0x80

@ ----------------------------------------------------------------------------
@ fn_08043464 - rounding and denormalising step of the internal format.
@ In:  r0 = word whose bit 31 is the sign; r1:r2 = 64-bit mantissa (r1 high);
@      r3 = signed exponent; r6 = sticky word; r11 = rounding selector; r10 and
@      r12 only feed a block whose results are discarded by pop {r0-r3} at
@      0x08043496.
@ If r3 is negative the mantissa is shifted right by -r3: when r3 <= -32 first
@ by one 32-bit step (r6 |= r2, r2 = r1, r1 = 0, r3 += 32 at 0x080434da..
@ 0x080434e6), bits shifted out go into r6 (0x080434ec..0x08043514) and r3
@ becomes 0; when r3 <= -64 the mantissa is cleared and r6 |= r1 | r2
@ (0x0804351a..0x0804353e).
@ Rounding at 0x0804346a..0x080434b4: nothing is added when r6 == 0; r11 == -1
@ never adds; r11 == 0 adds one when bit 31 of r6 is set, and when
@ r6 == 0x80000000 exactly only when bit 0 of r2 is set; any other r11 adds one
@ whenever r6 != 0. The add increments r2, carries into r1, sets
@ r1 = 0x80000000 if r1 wraps to zero (0x080434b4) and the carry is added to r3
@ (0x080434b8); r11 is incremented by 1 (0x0804349c) only when r6 != 0 (r6 == 0
@ branches from 0x0804346c over it).
@ Out: r0 = r3 | (r0 & 0x80000000) and r1:r2 = mantissa.
@ Uses the stack only for push/pop, no other memory access, no calls.
@ ----------------------------------------------------------------------------
	.section .text.fn_08043464,"ax",%progbits
	.global fn_08043464
	.thumb_func
	.type fn_08043464, %function
fn_08043464:
	mov	r12, r3
	cmp	r3, #0
	bmi.n	.L080434cc
.L0804346a:
	lsls	r7, r6, #1
	beq.n	.L080434c6
.L0804346e:
	rrx	r7, r7
	push	{r2, r3, r4, lr}
	push	{r0, r1}
	mov.w	r0, #0x10
	mov.w	r1, #0x10
	cmp.w	r10, #0
	beq.n	.L08043492
	cmp.w	r12, #0
	itt	le
	orrle.w	r0, r0, #8
	orrle.w	r1, r0, #8
.L08043492:
	mov.w	r0, #0
	pop	{r0, r1, r2, r3}
	pop.w	{r4, lr}
	add.w	r11, r11, #1
	cmp.w	r11, #1
	it	eq
	lsrseq.w	r7, r7, #32
	ittt	cs
	addscs.w	r2, r2, #1
	addscs.w	r1, r1, #1
	movcs.w	r1, #0x80000000
	adc.w	r3, r3, #0
.L080434bc:
	and	r0, r0, #0x80000000
	orr.w	r0, r3, r0
	bx	lr
.L080434c6:
	bcc.n	.L080434bc
	lsrs	r7, r2, #1
	b.n	.L0804346e
.L080434cc:
	orr.w	r6, r6, r6, lsl #16
	lsr.w	r6, r6, #0x10
	cmn.w	r3, #0x40
	ble.n	.L0804351a
	cmn.w	r3, #0x20
	itttt	le
	orrle	r6, r2
	movle	r2, r1
	movle	r1, #0
	addle	r3, #0x20
	rsbs	r3, r3, #0
	beq.n	.L0804346a
	rsb.w	r7, r3, #0x20
	orr.w	r6, r6, r6, lsl #16
	lsr.w	r6, r6, #0x10
	lsl.w	r7, r2, r7
	orr.w	r6, r6, r7
	lsr.w	r2, r2, r3
	rsb.w	r7, r3, #0x20
	lsl.w	r7, r1, r7
	orr.w	r2, r2, r7
	lsr.w	r1, r1, r3
	mov.w	r3, #0
	b.n	.L0804346a
.L0804351a:
	orr.w	r6, r6, r2
	orr.w	r6, r6, r6, lsl #16
	lsr.w	r6, r6, #0x10
	orr.w	r6, r6, r1
	itt	lt
	orrlt.w	r6, r6, r6, lsl #16
	lsrlt	r6, r6, #0x10
	mov.w	r3, #0
	mov.w	r2, #0
	mov.w	r1, #0
	b.n	.L0804346a

@ ----------------------------------------------------------------------------
@ fn_08043540 - internal-format step: call mantissa divide then rounding.
@ In:  r0 = pointer to first operand (3 words), r1 = pointer to second operand,
@      r2 and r3 are copied to r11 and r10 (0x08043548, 0x08043546) for
@      fn_08043464.
@ r0:r1:r2 are loaded from the first operand and r3:r4:r5 from the second
@ operand before the call. If (op[1] & ~(op[0]<<1)) < 0 for both operands, it
@ calls fn_0804312c(op1[0], op1[1], op1[2]) and then fn_08043464().
@ ----------------------------------------------------------------------------
	.section .text.fn_08043540,"ax",%progbits
	.global fn_08043540
	.thumb_func
	.type fn_08043540, %function
fn_08043540:
	push.w	{r7, r10, r11, lr}
	push	{r4, r5, r6}
	mov	r10, r3
	mov	r11, r2
	ldm.w	r1, {r3, r4, r5}
	ldmia	r0, {r0, r1, r2}
	bics.w	r12, r1, r0, lsl #1
	it	mi
	bicsmi.w	r12, r4, r3, lsl #1
	bpl.n	.L08043564
	bl	fn_0804312c
	bl	fn_08043464
.L08043564:
	pop	{r4, r5, r6, r7}
	pop.w	{r10, r11, pc}

@ ----------------------------------------------------------------------------
@ fn_0804356a - internal-format step: call mantissa multiply then rounding.
@ In:  r0 = pointer to first operand (3 words), r1 = pointer to second operand,
@      r2 and r3 are copied to r11 and r10 (0x08043572, 0x08043570) for
@      fn_08043464.
@ r0:r1:r2 are loaded from the first operand and r3:r4:r5 from the second
@ operand before the call. If bit 30 of word 0 of both operands is clear, it
@ calls fn_08043594(op1[0], op1[1], op1[2]) and then fn_08043464().
@ ----------------------------------------------------------------------------
	.section .text.fn_0804356a,"ax",%progbits
	.global fn_0804356a
	.thumb_func
	.type fn_0804356a, %function
fn_0804356a:
	push.w	{r7, r10, r11, lr}
	push	{r4, r5, r6}
	mov	r10, r3
	mov	r11, r2
	ldm.w	r1, {r3, r4, r5}
	ldmia	r0, {r0, r1, r2}
	tst.w	r0, #0x40000000
	it	eq
	tsteq.w	r3, #0x40000000
	bne.n	.L0804358e
	bl	fn_08043594
	bl	fn_08043464
.L0804358e:
	pop	{r4, r5, r6, r7}
	pop.w	{r10, r11, pc}

@ ----------------------------------------------------------------------------
@ fn_08043594 - mantissa multiply for the internal format used by fn_08043046
@ and fn_08043464.
@ In:  r0, r3 = sign/exponent words of the two operands; r1:r2 = first mantissa
@      (r1 high); r4:r5 = second mantissa (r4 high).
@ Sign = (r0^r3)&0x80000000 into r0 and exponent r3 = (r0&0xffffff) +
@ (r3&0xffffff) - 0x3ffe (0x08043594..0x080435ac).
@ Selects one of four cases by r2 == 0 (0x080435b0) and r5 == 0 (0x080435b8 and
@ 0x0804371e): with both nonzero it forms the product from three 64-bit
@ products built from 16x16-bit multiplies with carry propagation (r1*r4 at
@ 0x080435c4..0x080435f0, r2*r5 at 0x080435f4..0x08043620 and a product of the
@ differences (r1-r2) and (r5-r4) at 0x08043638..0x08043686); the other three
@ cases omit the terms of the zero low words (0x080436ae, 0x08043724,
@ 0x08043794).
@ Out: r0 = sign, r1:r2 = upper 64 bits of the product, shifted left one bit
@      with r3 decremented by 1 when bit 31 of r1 is clear; r6 = low/sticky
@      word.
@ The full case pushes and pops r0, r8, r11, lr at 0x080435c0 and
@ 0x0804369a/0x080436aa (stack only), no other memory access, no calls.
@ ----------------------------------------------------------------------------
	.section .text.fn_08043594,"ax",%progbits
	.global fn_08043594
	.thumb_func
	.type fn_08043594, %function
fn_08043594:
	bic	r7, r0, #0xff000000
	bic	r12, r3, #0xff000000
	eor.w	r0, r0, r3
	and	r0, r0, #0x80000000
	add.w	r3, r7, r12
	sub.w	r3, r3, #0x3f00
	sub.w	r3, r3, #0xfe
	teq	r2, #0
	beq.w	.L0804371e
	teq	r5, #0
	beq.w	.L080436ae
	push.w	{r0, r8, r11, lr}
	lsr.w	r0, r1, #0x10
	bic.w	r8, r1, r0, lsl #16
	lsr.w	r6, r4, #0x10
	bic.w	r7, r4, r6, lsl #16
	mul	r12, r0, r6
	mul	r6, r8, r6
	mul	r8, r7, r8
	adds.w	r8, r8, r6, lsl #16
	adc.w	r12, r12, r6, lsr #16
	mul	r7, r0, r7
	adds.w	r8, r8, r7, lsl #16
	adc.w	r0, r12, r7, lsr #16
	lsr.w	r11, r2, #0x10
	bic.w	lr, r2, r11, lsl #16
	lsr.w	r6, r5, #0x10
	bic.w	r7, r5, r6, lsl #16
	mul	r12, r11, r6
	mul	r6, lr, r6
	mul	lr, r7, lr
	adds.w	lr, lr, r6, lsl #16
	adc.w	r12, r12, r6, lsr #16
	mul	r7, r11, r7
	adds.w	lr, lr, r7, lsl #16
	adc.w	r11, r12, r7, lsr #16
	adds.w	r8, r8, r11
	adc.w	r0, r0, #0
	adds.w	r11, r8, lr
	adcs.w	r8, r8, r0
	adc.w	r0, r0, #0
	subs	r7, r1, r2
	mov.w	r1, #0
	mov.w	r6, #0
	itt	cc
	mvncc	r1, r1
	subcc	r6, r4, r5
	ite	ne
	subsne.w	r12, r5, r4
	moveq	r1, #0
	itt	cc
	mvncc	r1, r1
	subcc	r6, r6, r7
	lsr.w	r4, r7, #0x10
	bic.w	r5, r7, r4, lsl #16
	lsr.w	r7, r12, #0x10
	bic.w	r12, r12, r7, lsl #16
	mla	r2, r4, r7, r6
	mul	r7, r5, r7
	mul	r6, r12, r5
	adds.w	r6, r6, r7, lsl #16
	adc.w	r2, r2, r7, lsr #16
	mul	r12, r4, r12
	adds.w	r6, r6, r12, lsl #16
	adc.w	r2, r2, r12, lsr #16
	adds.w	r6, r11, r6
	adcs.w	r2, r8, r2
	adcs	r1, r0
	orr.w	lr, lr, lr, lsl #2
	orr.w	r6, r6, lr, lsr #2
	bpl.n	.L0804369e
	pop.w	{r0, r8, r11, pc}
.L0804369e:
	adds	r6, r6, r6
	adcs	r2, r2
	adc.w	r1, r1, r1
	sub.w	r3, r3, #1
	pop.w	{r0, r8, r11, pc}
.L080436ae:
	lsr.w	r5, r4, #0x10
	bic.w	r6, r4, r5, lsl #16
	lsr.w	r7, r1, #0x10
	bic.w	r12, r1, r7, lsl #16
	mul	r4, r5, r7
	mul	r7, r6, r7
	mul	r1, r12, r6
	adds.w	r1, r1, r7, lsl #16
	adc.w	r4, r4, r7, lsr #16
	mul	r12, r5, r12
	adds.w	r1, r1, r12, lsl #16
	adc.w	r4, r4, r12, lsr #16
	lsr.w	r7, r2, #0x10
	bic.w	r12, r2, r7, lsl #16
	mul	r2, r5, r7
	mul	r7, r6, r7
	mul	r6, r12, r6
	adds.w	r6, r6, r7, lsl #16
	adc.w	r2, r2, r7, lsr #16
	mul	r12, r5, r12
	adds.w	r6, r6, r12, lsl #16
	adc.w	r5, r2, r12, lsr #16
	adds	r2, r5, r1
	adcs.w	r1, r4, #0
	it	mi
	bxmi	lr
	adds	r6, r6, r6
	adcs	r2, r2
	adc.w	r1, r1, r1
	sub.w	r3, r3, #1
	bx	lr
.L0804371e:
	teq	r5, #0
	beq.n	.L08043794
	lsr.w	r2, r1, #0x10
	bic.w	r6, r1, r2, lsl #16
	lsr.w	r7, r4, #0x10
	bic.w	r12, r4, r7, lsl #16
	mul	r1, r2, r7
	mul	r7, r6, r7
	mul	r4, r12, r6
	adds.w	r4, r4, r7, lsl #16
	adc.w	r1, r1, r7, lsr #16
	mul	r12, r2, r12
	adds.w	r4, r4, r12, lsl #16
	adc.w	r1, r1, r12, lsr #16
	lsr.w	r7, r5, #0x10
	bic.w	r12, r5, r7, lsl #16
	mul	r5, r2, r7
	mul	r7, r6, r7
	mul	r6, r12, r6
	adds.w	r6, r6, r7, lsl #16
	adc.w	r5, r5, r7, lsr #16
	mul	r12, r2, r12
	adds.w	r6, r6, r12, lsl #16
	adc.w	r2, r5, r12, lsr #16
	adds	r2, r2, r4
	adcs.w	r1, r1, #0
	it	mi
	bxmi	lr
	adds	r6, r6, r6
	adcs	r2, r2
	adc.w	r1, r1, r1
	sub.w	r3, r3, #1
	bx	lr
.L08043794:
	lsr.w	r5, r4, #0x10
	bic.w	r6, r4, r5, lsl #16
	lsr.w	r7, r1, #0x10
	bic.w	r12, r1, r7, lsl #16
	mul	r1, r5, r7
	mul	r7, r6, r7
	mul	r2, r12, r6
	adds.w	r2, r2, r7, lsl #16
	adc.w	r1, r1, r7, lsr #16
	mul	r12, r5, r12
	adds.w	r2, r2, r12, lsl #16
	adcs.w	r1, r1, r12, lsr #16
	mov.w	r6, #0
	it	mi
	bxmi	lr
	adds	r2, r2, r2
	adc.w	r1, r1, r1
	sub.w	r3, r3, #1
	bx	lr

@ ----------------------------------------------------------------------------
@ classify_double - classify a 64-bit floating value.
@ In:  r0 = low word, r1 = high word of the value.
@ Out: r0 = class code: 4 if (low != 0 or high&0xfffff != 0), OR 1 if the
@      exponent bits (high&0x7fffffff)>>20 are non-zero, OR 2 if that field is
@      0x7ff; a result of exactly 1 is returned as 5.
@ Spills r0:r1 to the stack and reads them back; no other memory access.
@ ----------------------------------------------------------------------------
	.section .text.classify_double,"ax",%progbits
	.global classify_double
	.thumb_func
	.type classify_double, %function
classify_double:
	push	{r0, r1}
	ldr	r0, [sp, #4]
	lsls	r1, r0, #1
	ldr	r0, [sp, #0]
	orrs.w	r0, r0, r1, lsl #11
	it	ne
	movne	r0, #4
	lsrs	r2, r1, #0x15
	it	ne
	orrne.w	r0, r0, #1
	movw	r2, #0x7ff
	cmp.w	r2, r1, lsr #21
	it	eq
	orreq.w	r0, r0, #2
	cmp	r0, #1
	it	eq
	moveq	r0, #5
	add	sp, #8
	bx	lr

@ ----------------------------------------------------------------------------
@ classify_float - classify a 32-bit floating value.
@ In:  r0 = 32-bit floating value.
@ Out: r0 = class code: 4 if the mantissa bits (r0&0x7fffff) are non-zero, OR 1
@      if the exponent field (r0&0x7fffffff)>>23 is non-zero, OR 2 if the
@      exponent field is 0xff; a result of exactly 1 is returned as 5.
@ Register arithmetic only.
@ ----------------------------------------------------------------------------
	.section .text.classify_float,"ax",%progbits
	.global classify_float
	.thumb_func
	.type classify_float, %function
classify_float:
	lsls	r1, r0, #1
	lsls	r0, r1, #8
	it	ne
	movne	r0, #4
	lsrs	r2, r1, #0x18
	it	ne
	orrne.w	r0, r0, #1
	mov.w	r2, #0xff000000
	bics.w	r1, r2, r1
	it	eq
	orreq.w	r0, r0, #2
	cmp	r0, #1
	it	eq
	moveq	r0, #5
	bx	lr

@ ----------------------------------------------------------------------------
@ float_remainder_sign_fixup - remainder of x divided by y with the sign of x
@ (truncating remainder), built on the IEEE remainder float_ieee_remainder
@ (08045f20).
@ In:  s0, s1 as passed; r0, r1 = the two 32-bit floats x, y (moved to s17 /
@      s16; d8 is saved with vpush).
@ Domain check: when neither |x| nor |y| exceeds 0x7f800000 (no NaN;
@ 0x08043844/0x08043854) and (x*2 == 0xff000000, i.e. x is +-infinity, or
@ y*2 == 0, i.e. y is +-zero) it calls fn_0800788e(1) (0800788e) and
@ tail-branches to float_return_nan (08044e14), which returns NaN as 0/0 in s0.
@ Otherwise it calls float_ieee_remainder (08045f20) with r0 = x, r1 = y and
@ takes the result r in s0: if the exponent field of r is all ones (NaN or
@ infinity) or the sign bit of r equals the sign bit of x it returns r; else it
@ returns r - ((r & 0x80000000) | (y & 0x7fffffff)) with vsub.f32 at
@ 0x080438ae (adds |y| when r is negative, subtracts |y| when r is positive).
@ Out: result in s0.
@ ----------------------------------------------------------------------------
	.section .text.float_remainder_sign_fixup,"ax",%progbits
	.global float_remainder_sign_fixup
	.thumb_func
	.type float_remainder_sign_fixup, %function
float_remainder_sign_fixup:
	push	{r4, lr}
	vpush	{d8}
	vmov.f32	s17, s0
	vmov	r0, s17
	vmov.f32	s16, s1
	bic	r0, r0, #0x80000000
	rsb.w	r0, r0, #0x7f800000
	lsrs	r0, r0, #0x1f
	bne.n	.L0804385c
	vmov	r0, s16
	bic	r0, r0, #0x80000000
	rsb.w	r0, r0, #0x7f800000
	lsrs	r0, r0, #0x1f
	beq.n	.L080438b4
.L0804385c:
	vmov	r1, s16
	vmov	r0, s17
	bl	float_ieee_remainder
	vmov	s0, r0
	vmov	r0, s0
	mvn.w	r0, r0, lsr #23
	tst.w	r0, #0xff
	itt	eq
	vpopeq	{d8}
	popeq	{r4, pc}
	vmov	r0, s17
	and	r1, r0, #0x80000000
	vmov	r0, s0
	and	r0, r0, #0x80000000
	cmp	r1, r0
	itt	eq
	vpopeq	{d8}
	popeq	{r4, pc}
	vmov	r1, s16
	vmov	r0, s0
	vpop	{d8}
	bfi	r0, r1, #0, #0x1f
	vmov	s1, r0
	vsub.f32	s0, s0, s1
	pop	{r4, pc}
.L080438b4:
	vmov	r0, s17
	mov.w	r1, #0xff000000
	cmp.w	r1, r0, lsl #1
	itt	ne
	vmovne	r0, s16
	lslsne.w	r0, r0, #1
	bne.n	.L0804385c
	movs	r0, #1
	bl	fn_0800788e
	vpop	{d8}
	pop.w	{r4, lr}
	b.w	float_return_nan
	.short	0x0000	@ padding
