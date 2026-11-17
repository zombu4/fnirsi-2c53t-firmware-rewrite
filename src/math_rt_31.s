@ math_rt_31.s - 64-bit float runtime: integer to double conversions, double compare, multiply, special-case dispatcher, sqrt, subtract, float conversion, remainder, double to integer, scale by power of two
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ i64_to_double - converts a signed 64-bit integer (r0 low / r1 high) to a
@ 64-bit float in r0 (low) / r1 (high).
@ If r1 is negative it negates the 64-bit value (low = -low, high = -high -
@ borrow) and keeps the sign in the exponent word (0x800 << 20 added).
@ Normalises with LZCOUNT of the high word (or of the low word when the high
@ word is zero, base 0xc1d), exponent base 0xc32 minus the shift, shifts the
@ mantissa so bit 52 is the implicit bit, rounds to nearest-even from the bits
@ shifted out of the low word (tie clears bit 0, carry increments the high
@ word); returns the low word as-is when the value is 0.
@ ----------------------------------------------------------------------------
	.section .text.i64_to_double,"ax",%progbits
	.global i64_to_double
	.thumb_func
	.type i64_to_double, %function
i64_to_double:
	mvns.w	r2, r1, asr #31
	bne.n	.L08045544
	subs	r0, r2, r0
	sbc.w	r1, r2, r1
.L08045544:
	clz	r3, r1
	subs	r3, #0xb
	bcc.n	.L08045596
	lsls	r1, r3
	bne.n	.L08045576
	clz	r3, r0
	lsls.w	r1, r0, r3
	it	eq
	bxeq	lr
	rsb.w	r3, r3, #0x1d
	add.w	r3, r3, #0xc00
	add.w	r3, r3, r2, lsl #11
	lsr.w	r2, r1, #11
	lsl.w	r0, r1, #21
	add.w	r1, r2, r3, lsl #20
	bx	lr
.L08045576:
	rsb.w	r12, r3, #0x20
	lsr.w	r12, r0, r12
	orr.w	r1, r1, r12
	lsls	r0, r3
	rsb.w	r3, r3, #0x32
	add.w	r3, r3, #0xc00
	add.w	r3, r3, r2, lsl #11
	add.w	r1, r1, r3, lsl #20
	bx	lr
.L08045596:
	rsb.w	r12, r3, #0x32
	add.w	r12, r12, #0xc00
	add.w	r2, r12, r2, lsl #11
	push	{r4, lr}
	rsb.w	r4, r3, #0
	rsb.w	lr, r4, #0x20
	lsl.w	r12, r1, lr
	lsr.w	r1, r1, r4
	lsl.w	r3, r0, lr
	lsrs	r0, r4
	orr.w	r0, r0, r12
	pop.w	{r4, lr}
	add.w	r1, r1, r2, lsl #20
	it	cc
	bxcc	lr
	.inst.n 0x1c40	@ adds r0, r0, #1
	adc	r1, r1, #0
	lsls	r3, r3, #1
	it	eq
	biceq	r0, r0, #1
	bx	lr

@ ----------------------------------------------------------------------------
@ u32_to_double - converts an unsigned 32-bit integer in r0 to a 64-bit float
@ in r0 (low) / r1 (high).
@ Returns 0 if r0 is zero; otherwise shifts r0 left by LZCOUNT(r0), high word =
@ (0x41d - LZCOUNT) * 0x100000 + (normalised >> 11), low word = normalised
@ << 21.
@ ----------------------------------------------------------------------------
	.section .text.u32_to_double,"ax",%progbits
	.global u32_to_double
	.thumb_func
	.type u32_to_double, %function
u32_to_double:
	clz	r3, r0
	lsls.w	r1, r0, r3
	beq.n	.L080455fa
	rsb.w	r3, r3, #0x1d
	add.w	r3, r3, #0x400
	lsl.w	r2, r3, #20
	lsl.w	r0, r1, #21
	add.w	r1, r2, r1, lsr #11
	bx	lr
.L080455fa:
	mov.w	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ u64_to_double - converts an unsigned 64-bit integer (r0 low / r1 high) to a
@ 64-bit float in r0/r1.
@ Normalises with LZCOUNT of the high word (or of the low word when the high
@ word is zero, exponent base 0x41d), exponent base 0x432 minus the shift,
@ shifts the mantissa so bit 52 is the implicit bit, and rounds to
@ nearest-even from the bits shifted out of the low word (tie clears bit 0,
@ carry increments the high word); returns r0 as-is when the value is 0.
@ The two trailing bytes are padding (never reached; after the bx lr, aligns
@ the next function to 2 bytes).
@ ----------------------------------------------------------------------------
	.section .text.u64_to_double,"ax",%progbits
	.global u64_to_double
	.thumb_func
	.type u64_to_double, %function
u64_to_double:
	clz	r3, r1
	subs	r3, #0xb
	bcc.n	.L0804564a
	lsls	r1, r3
	bne.n	.L0804562e
	clz	r3, r0
	lsls.w	r1, r0, r3
	it	eq
	bxeq	lr
	rsb.w	r3, r3, #0x1d
	add.w	r3, r3, #0x400
	lsr.w	r2, r1, #11
	lsl.w	r0, r1, #21
	add.w	r1, r2, r3, lsl #20
	bx	lr
.L0804562e:
	rsb.w	r12, r3, #0x20
	lsr.w	r12, r0, r12
	orr.w	r1, r1, r12
	lsls	r0, r3
	rsb.w	r3, r3, #0x32
	add.w	r3, r3, #0x400
	add.w	r1, r1, r3, lsl #20
	bx	lr
.L0804564a:
	rsb.w	r12, r3, #0x32
	add.w	r2, r12, #0x400
	push	{r4, lr}
	rsb.w	r4, r3, #0
	rsb.w	lr, r4, #0x20
	lsl.w	r12, r1, lr
	lsr.w	r1, r1, r4
	lsl.w	r3, r0, lr
	lsrs	r0, r4
	orr.w	r0, r0, r12
	pop.w	{r4, lr}
	add.w	r1, r1, r2, lsl #20
	it	cc
	bxcc	lr
	.inst.n 0x1c40	@ adds r0, r0, #1
	adc	r1, r1, #0
	lsls	r3, r3, #1
	it	eq
	biceq	r0, r0, #1
	bx	lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0804568c - compares the 64-bit floats a = r0:r1 and b = r2:r3 and returns
@ the result in the CPU flags (not visible in the decompiled C); same compare
@ body as 080453d8 (ip = r1 | r3 range tests at 0x08045692, cmp r1,r3 / cmp
@ r0,r2 at 0x080456a0.., swapped cmp r3,r1 / cmp r2,r0 for negative operands,
@ cmp r1,r1 for both exponent fields 0).
@ A NaN operand reaches the split-off function double_compare_special_case
@ (080456ee) by bmi.n at 080456b8 and bcs.n at 080456e8; that function
@ (080456ee..080456f3) is only push {r4,r5,r6,lr}; bl 080458d0 (080456f0). The
@ inline word 0x00492492 at 080456f4 and the slots after it belong to it: class
@ 8 loads r1 = 0x10000000 (slot 0, 080456f8) and r3 = 0x20000000 (slot 1,
@ 080456fc) and continues at b.w 0x0804510c (08045700); the other classes
@ (field 2) go straight to the b.w at 08045700.
@ The target 0804510c is the split-off function fn_0804510c, which turns r1 =
@ 0x10000000 into 0xb8000000 and r3 = 0x20000000 into 0xb0000000 (asr 1, then
@ 0xc0000000 minus the value) and returns the flags of cmp r3,r1 (r3 below r1)
@ in r0 (mrs r0,CPSR) and in the flags.
@ Differs from 080453d8 and 08045704 only in the operand values of the NaN case
@ (r1 above r3 after the transform here).
@ ----------------------------------------------------------------------------
	.section .text.fn_0804568c,"ax",%progbits
	.global fn_0804568c
	.thumb_func
	.type fn_0804568c, %function
fn_0804568c:
	orrs.w	r12, r1, r3
	bmi.n	.L080456c2
	cmn.w	r12, #0x100000
	it	pl
	cmppl.w	r12, #0x100000
	bmi.w	.L080456ac
	cmp	r1, r3
	it	ne
	bxne	lr
	it	eq
	cmpeq	r0, r2
	bx	lr
.L080456ac:
	bvc.n	.L080456be
	cmn.w	r1, #0x100000
	it	pl
	cmnpl.w	r3, #0x100000
	bmi.n	double_compare_special_case
	cmp	r1, r3
	bx	lr
.L080456be:
	cmp	r1, r1
	bx	lr
.L080456c2:
	cmn.w	r12, #0x100000
	bpl.n	.L080456da
	cmp.w	r12, #0x100000
	bpl.n	.L080456be
	cmp	r3, r1
	it	ne
	bxne	lr
	it	eq
	cmpeq	r2, r0
	bx	lr
.L080456da:
	mov.w	r12, #0x200000
	cmn.w	r12, r1, lsl #1
	it	cc
	cmncc.w	r12, r3, lsl #1
	bcs.n	double_compare_special_case
	cmp	r3, r1
	bx	lr

@ ----------------------------------------------------------------------------
@ double_compare_special_case - NaN exit of the 64-bit float compare 0804568c
@ (an operand with an all-ones exponent that is an infinity arrives too and
@ goes to slot 2; class 8 only when an operand is a NaN): stub with push
@ {r4,r5,r6,lr}; bl 080458d0 (double_special_dispatch) and the inline word
@ 0x00492492 at 0x080456f4; never returns to the call. Bit31 clear (the second
@ operand r2:r3 is tested for NaN too), field 2 for classes 0..7, field 0 for
@ class 8 (either operand a NaN).
@ Slot 0 (0x080456f8): mov.w r1,#0x10000000 and, falling into slot 1
@ (0x080456fc), mov.w r3,#0x20000000, then slot 2 (0x08045700) b.w 0x0804510c;
@ so class 8 reaches 0x0804510c with r1 = 0x10000000 and r3 = 0x20000000, all
@ other classes go straight to slot 2; the flags result is produced at
@ 0x0804510c.
@ Entered by: bmi.n at 0x080456b8 (after cmn.w r1,#0x100000 / cmnpl.w
@ r3,#0x100000, i.e. an operand with an all-ones exponent) and bcs.n at
@ 0x080456e8 (after the cmn.w tests of the shifted operands at
@ 0x080456de/0x080456e4). The previous instruction 0x080456ec is bx lr, no
@ fall-in.
@ Entry state: r0:r1 = first double, r2:r3 = second double; lr = caller of
@ 0804568c.
@ ----------------------------------------------------------------------------
	.global double_compare_special_case
	.thumb_func
	.type double_compare_special_case, %function
double_compare_special_case:
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.word 0x00492492	@ inline word for 080458d0: fields 0..7 = 2, field 8 = 0, bit31 = 0
	mov.w	r1, #0x10000000	@ slot 0
	mov.w	r3, #0x20000000	@ slot 1
	b.w	fn_0804510c	@ slot 2

@ ----------------------------------------------------------------------------
@ fn_08045704 - compares the 64-bit floats a = r0:r1 and b = r2:r3 and returns
@ the result in the CPU flags (not visible in the decompiled C); same compare
@ body as 080453d8 (range tests of ip = r1 | r3 at 0x0804570a, cmp r1,r3 / cmp
@ r0,r2 at 0x08045718.., swapped cmp r3,r1 / cmp r2,r0 for negative operands
@ at 0x08045746..0x0804574e, cmp r1,r1 for both exponent fields 0).
@ A NaN operand reaches the split-off function fn_08045766 by bmi.n 08045766 at
@ 08045730 and bcs.n 08045766 at 08045760; fn_08045766 (08045766..0804576b) is
@ only push {r4,r5,r6,lr}; bl 080458d0 (08045768). The inline word 0x00492492
@ at 0804576c and the slots after it belong to this function: class 8 loads r1
@ = 0x20000000 (slot 0, 08045770) and r3 = 0x10000000 (slot 1, 08045774) and
@ continues at b.w 0x0804510c (08045778); the other classes (field 2) go
@ straight to that b.w.
@ The target 0804510c is the split-off function fn_0804510c, which turns r1 =
@ 0x20000000 into 0xb0000000 and r3 = 0x10000000 into 0xb8000000 and returns
@ the flags of cmp r3,r1 (r3 above r1) in r0 and in the flags.
@ ----------------------------------------------------------------------------
	.section .text.fn_08045704,"ax",%progbits
	.global fn_08045704
	.thumb_func
	.type fn_08045704, %function
fn_08045704:
	orrs.w	r12, r1, r3
	bmi.n	.L0804573a
	cmn.w	r12, #0x100000
	it	pl
	cmppl.w	r12, #0x100000
	bmi.w	.L08045724
	cmp	r1, r3
	it	ne
	bxne	lr
	it	eq
	cmpeq	r0, r2
	bx	lr
.L08045724:
	bvc.n	.L08045736
	cmn.w	r1, #0x100000
	it	pl
	cmnpl.w	r3, #0x100000
	bmi.n	fn_08045766
	cmp	r1, r3
	bx	lr
.L08045736:
	cmp	r1, r1
	bx	lr
.L0804573a:
	cmn.w	r12, #0x100000
	bpl.n	.L08045752
	cmp.w	r12, #0x100000
	bpl.n	.L08045736
	cmp	r3, r1
	it	ne
	bxne	lr
	it	eq
	cmpeq	r2, r0
	bx	lr
.L08045752:
	mov.w	r12, #0x200000
	cmn.w	r12, r1, lsl #1
	it	cc
	cmncc.w	r12, r3, lsl #1
	bcs.n	fn_08045766
	cmp	r3, r1
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08045766 - NaN stub of the 64-bit float compares: push {r4,r5,r6,lr}
@ (08045766), bl 080458d0 (double_special_dispatch) with inline word
@ 0x00492492 at 0804576c (fields 0..7 = 2, field 8 = 0); never continues
@ here; decompiler-selectable slots [0,2]: class 8 (a NaN operand) selects
@ slot 0 (08045770: r1=0x20000000, 08045774: r3=0x10000000) and then slot 2
@ (08045778: b.w 0804510c), every other class selects slot 2 directly.
@ Entered from: fn_08045704 by bmi at 08045730 and bcs at 08045760, and
@ fn_08045978 by b.w at 080459e0 (after push {r0-r3}; pop {r2,r3}; pop {r0,r1}
@ at 080459da swapped the operands).
@ Expects on entry: r0:r1 and r2:r3 = the two operands, lr = return address of
@ the compare function (saved by the push here); flags unused.
@ Purpose: sends operands with an all-ones exponent through the dispatcher,
@ then to the flag computation 0804510c.
@ ----------------------------------------------------------------------------
	.global fn_08045766
	.thumb_func
	.type fn_08045766, %function
fn_08045766:
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.word 0x00492492	@ inline word for 080458d0: fields 0..7 = 2, field 8 = 0, bit31 = 0
	mov.w	r1, #0x20000000	@ slot 0
	mov.w	r3, #0x10000000	@ slot 1
	b.w	fn_0804510c	@ slot 2

@ ----------------------------------------------------------------------------
@ double_mul - multiplies two 64-bit floats (r0 low / r1 high and r2 low / r3
@ high) and returns the 64-bit float product in r0/r1.
@ If either exponent field is 0 or 0x7ff: when either is 0x7ff it calls
@ dispatcher 080458d0 (never returns here), otherwise returns signed zero
@ (sign = r1 XOR r3 bit 31).
@ Otherwise it forms 53-bit mantissas (mask 0x1fffff, OR 0x100000), computes
@ the 106-bit product from 32x32 to 64-bit multiplies, shifts it left by 11 or
@ 12 depending on bit 9 of the top word, adds exponent sum - 0x3fc0000 (>>16)
@ and sets the sign by XOR; rounds to nearest-even using the shifted-out bits
@ (bit 31 round, remaining bits sticky).
@ Exponent field >= 0x7fe (cmp lr,#0x4000000 / ge at 08045856): r1 -=
@ 0x60000000 (0804585c), pop r4,r5,r6,lr (08045860) and bge.w 0804596c at
@ 08045864, a jump to the split-off function double_return_infinity (lsrs
@ r0,r1,#32; sub r1,r0,#0x200000; mov r1,r1,rrx; bx lr, so r0 = 0 and r1 =
@ sign bit of r1 | 0x7ff00000, a signed infinity); for a negative biased sum
@ (lt at 08045864) r1 += 0x60000000, r1 &= 0x80000000, r0 = 0 and bx lr at
@ 08045874 return signed zero.
@ The call at 0x08045894 passes the inline word 0x3E010089 at 0x08045898
@ (fields 0=1 1=1 2=2 3=0 4=0 5=2 6=0 7=0 8=6), slots: 0 at 0x0804589c (b.w
@ 0x080458ae), 1 at 0x080458a0 (b.w 0x080458b6), 2 at 0x080458a4 (if
@ (r3<<1)>>21 is 0 branch to 0x080458c0, else fall into 0x080458ae).
@ 0x080458ae: r1 = r1 XOR r3, then b.w 0x0804596c at 080458b2 (the same
@ split-off double_return_infinity, signed infinity). 0x080458b6: if
@ (r1<<1)>>21 is nonzero branch to 0x080458ae, else 0x080458c0: r1 =
@ 0x7ff80000 (literal at 0x080458cc), r0 = 0, bx lr.
@ Literal 0x080458c8 = 0x07ff0000 (exponent mask used with lsr #4), literal
@ 0x080458cc = 0x7ff80000 (quiet NaN high word).
@ ----------------------------------------------------------------------------
	.section .text.double_mul,"ax",%progbits
	.global double_mul
	.thumb_func
	.type double_mul, %function
double_mul:
	push	{r4, r5, r6, lr}
	ldr.w	r12, .L080458c8
	ands.w	lr, r12, r1, lsr #4
	ittt	ne
	andsne.w	r5, r12, r3, lsr #4
	teqne.w	lr, r12
	teqne.w	r5, r12
	beq.w	.L08045876
	eor.w	r4, r1, r3
	orr.w	lr, lr, r4, lsr #31
	add	lr, r5
	bic.w	r1, r1, r12, lsl #5
	bic.w	r3, r3, r12, lsl #5
	orr	r1, r1, #0x100000
	orr	r3, r3, #0x100000
	sub.w	lr, lr, #0x3fc0000
	umull	r4, r12, r1, r2
	umull	r6, r5, r0, r3
	adds	r6, r6, r4
	adcs.w	r5, r5, r12
	umull	r4, r12, r1, r3
	adc	r3, r12, #0
	umull	r1, r12, r0, r2
	adds.w	r6, r6, r12
	adcs	r5, r4
	adcs	r3, r3, #0
	tst	r1, r1
	it	ne
	orrne	r6, r6, #1
	tst.w	r3, #0x200
	bne.n	.L08045800
	lsl.w	r1, r3, #12
	lsl.w	r0, r5, #12
	orr.w	r1, r1, r5, lsr #20
	orr.w	r0, r0, r6, lsr #20
	lsls	r4, r6, #12
	mvn	r2, #3
	b.n	.L08045816
.L08045800:
	lsl.w	r1, r3, #11
	lsl.w	r0, r5, #11
	orr.w	r1, r1, r5, lsr #21
	orr.w	r0, r0, r6, lsr #21
	lsls	r4, r6, #11
	mvn	r2, #2
.L08045816:
	add.w	r2, r2, lr, asr #16
	add.w	r5, r1, r2, lsl #20
	eor.w	r1, r5, lr, lsl #31
	beq.n	.L0804583a
	lsls.w	r12, r4, #1
	it	ne
	bicne	r4, r4, #0x80000000
	adcs	r0, r0, #0
	adc	r1, r1, #0
	bic.w	r0, r0, r4, lsr #31
.L0804583a:
	movw	r12, #0x7fe
	cmp	r2, r12
	bcs.n	.L08045844
	pop	{r4, r5, r6, pc}
.L08045844:
	cmp	r0, r5
	ite	ne
	movne.w	r4, #0x40000000
	moveq.w	r4, #0xc0000000
	cmp	r6, #0
	it	eq
	moveq	r4, #0
	cmp.w	lr, #0x4000000
	it	ge
	subge.w	r1, r1, #0x60000000
	pop.w	{r4, r5, r6, lr}
	bge.w	double_return_infinity
	add.w	r1, r1, #0x60000000
	and	r1, r1, #0x80000000
	mov.w	r0, #0
	bx	lr
.L08045876:
	and.w	r5, r12, r3, lsr #4
	teq.w	lr, r12
	it	ne
	teqne.w	r5, r12
	beq.n	.L08045894
	eor.w	lr, r1, r3
	mov.w	r0, #0
	and	r1, lr, #0x80000000
	pop	{r4, r5, r6, pc}
.L08045894:
	bl	double_special_dispatch
	.word 0x3e010089	@ inline word for 080458d0: 0=1 1=1 2=2 3=0 4=0 5=2 6=0 7=0 8=6, bit31 = 0
	b.w	.L080458ae	@ slot 0
	b.w	.L080458b6	@ slot 1
	lsl.w	r12, r3, #1	@ slot 2
	lsrs.w	r12, r12, #21
	beq.n	.L080458c0
.L080458ae:
	eor.w	r1, r1, r3
	b.w	double_return_infinity
.L080458b6:
	lsl.w	r12, r1, #1
	lsrs.w	r12, r12, #21
	bne.n	.L080458ae
.L080458c0:
	.inst.n 0x4902	@ ldr r1, .L080458cc
	mov.w	r0, #0
	bx	lr
.L080458c8:
	.word 0x07ff0000	@ exponent mask (used shifted right by 4)
.L080458cc:
	.word 0x7ff80000	@ quiet NaN high word

@ ----------------------------------------------------------------------------
@ double_special_dispatch - inline-word dispatcher for 64-bit float operands a
@ = r0:r1 and b = r2:r3 (called with bl from the operation's special-case
@ stub; saved r4-r6 and lr of the stub are on its stack).
@ lr = (lr + 2) & ~3 is the address of the 32-bit word W after the call,
@ loaded into r6 (lr then points at the slots, W address + 4).
@ Class: if W bit 31 is clear and b is a NaN (2*r3 + (r2 != 0) > 0xffe00000)
@ class 8; if a is a NaN class 8; if a is +-infinity class = 2 + 3*sign(a),
@ plus (1 + sign(b)) when b is also infinity; otherwise class = sign bit of b
@ (0 or 1).
@ Field = (W >> (class*3)) & 7. Fields 0..3: pops r4,r5,r6,lr (restoring the
@ stub's caller state) and jumps (bx, Thumb bit set) to the slot at W address +
@ 4 + field*4 with r0..r3 unchanged. Fields 4..7 use tbb at 0x0804593c (table
@ 0x08045940): field 4 returns b (0x08045952), field 5 returns a (0x08045956)
@ (tbb bytes 09 0b 02 02 at 0x08045940), fields 6 and 7 return the quiet NaN
@ 0x7ff80000:00000000 (0x08045944); the returned value (field 4/5) has r0:r1
@ flushed to 0 with its sign kept when 2*r1 + (r0 != 0) is below 0x200000
@ (denormal or zero; rsbs r4,r4,#0x200000 at 0x0804595e, movhi at 0x08045964).
@ The return of the fields 4..7 pops r4,r5,r6,pc and goes to the stub's
@ caller; the dispatcher never returns to the instruction after its call.
@ ----------------------------------------------------------------------------
	.section .text.double_special_dispatch,"ax",%progbits
	.global double_special_dispatch
	.thumb_func
	.type double_special_dispatch, %function
double_special_dispatch:
	add.w	lr, lr, #2
	bic	lr, lr, #3
	ldr.w	r6, [lr], #4
	tst	r6, r6
	bmi.n	.L080458ec
	cmp	r2, #1
	adc.w	r5, r3, r3
	cmn.w	r5, #0x200000
	bhi.n	.L08045912
.L080458ec:
	cmp	r0, #1
	adc.w	r12, r1, r1
	cmn.w	r12, #0x200000
	bhi.n	.L08045912
	bne.n	.L08045918
	lsr.w	r12, r1, #31
	add.w	r12, r12, r12, lsl #1
	add.w	r12, r12, #2
	cmn.w	r5, #0x200000
	it	eq
	adceq.w	r12, r12, r3, lsr #31
	b.n	.L0804591c
.L08045912:
	mov.w	r12, #8
	b.n	.L0804591c
.L08045918:
	lsr.w	r12, r3, #31
.L0804591c:
	add.w	r5, r12, r12, lsl #1
	lsr.w	r6, r6, r5
	and	r6, r6, #7
	subs.w	r12, r6, #4
	bcs.n	.L0804593c
	add.w	r12, lr, r6, lsl #2
	pop.w	{r4, r5, r6, lr}
	orr	r12, r12, #1
	bx	r12
.L0804593c:
	tbb	[pc, r12]
.L08045940:
	.byte (.L08045952 - .L08045940)/2
	.byte (.L08045956 - .L08045940)/2
	.byte (.L08045944 - .L08045940)/2
	.byte (.L08045944 - .L08045940)/2
.L08045944:
	mov.w	r1, #0x80000000
	sub.w	r1, r1, #0x80000
	mov.w	r0, #0
	pop	{r4, r5, r6, pc}
.L08045952:
	mov	r1, r3
	mov	r0, r2
.L08045956:
	cmp	r0, #1
	adcs.w	r4, r1, r1
	it	ne
	rsbsne.w	r4, r4, #0x200000
	itt	hi
	movhi	r0, #0
	andhi	r1, r1, #0x80000000
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ double_return_infinity - lsrs r0,r1,#32 (r0 = 0, C = bit 31 of r1), sub.w
@ r1,r0,#0x200000 (r1 = 0xffe00000), rrx r1,r1 (r1 = C<<31 | 0x7ff00000), bx
@ lr: returns r0:r1 = signed 64-bit float infinity with the sign taken from
@ bit 31 of the incoming r1; only that bit is used, r0 is ignored.
@ Entered by b.w from: fn_0804504e at 0804505e, 08044fbc at 080450ce,
@ double_div at 08045268, 08045312 and 0804533e, double_mul at 08045864
@ (bge.w) and 080458b2, and float_to_double at 08045db4 (after mov.w r1,r0).
@ Expects on entry: r1 bit 31 = sign, lr = return address of the function that
@ branched; flags not used, flags are changed (lsrs); clobbers r0, r1.
@ Purpose: overflow result, proven by the constants.
@ ----------------------------------------------------------------------------
	.section .text.double_return_infinity,"ax",%progbits
	.global double_return_infinity
	.thumb_func
	.type double_return_infinity, %function
double_return_infinity:
	lsrs	r0, r1, #32
	sub.w	r1, r0, #0x200000
	rrx	r1, r1
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08045978 - compare of two 64-bit floats like 08045704 with the operand
@ roles swapped: ip = r3 | r1 (0x08045978), compares r3 with r1 (cmp r3,r1 /
@ cmp r2,r0 at 0x0804598c..0x08045994 for non-negative operands, cmp r1,r3 /
@ cmp r0,r2 at 0x080459ba..0x080459c2 for negative ones, cmp r3,r3 for both
@ exponent fields 0); result in the CPU flags (not visible in the decompiled
@ C). An all-ones exponent operand ends at 0x080459da: push {r0-r3}; pop
@ {r2,r3}; pop {r0,r1} (swaps the two operands) and b 0x08045766
@ (fn_08045766), the NaN stub of 08045704 (dispatcher 080458d0 never returns
@ here).
@ ----------------------------------------------------------------------------
	.section .text.fn_08045978,"ax",%progbits
	.global fn_08045978
	.thumb_func
	.type fn_08045978, %function
fn_08045978:
	orrs.w	r12, r3, r1
	bmi.n	.L080459ae
	cmn.w	r12, #0x100000
	it	pl
	cmppl.w	r12, #0x100000
	bmi.w	.L08045998
	cmp	r3, r1
	it	ne
	bxne	lr
	it	eq
	cmpeq	r2, r0
	bx	lr
.L08045998:
	bvc.n	.L080459aa
	cmn.w	r3, #0x100000
	it	pl
	cmnpl.w	r1, #0x100000
	bmi.n	.L080459da
	cmp	r3, r1
	bx	lr
.L080459aa:
	cmp	r3, r3
	bx	lr
.L080459ae:
	cmn.w	r12, #0x100000
	bpl.n	.L080459c6
	cmp.w	r12, #0x100000
	bpl.n	.L080459aa
	cmp	r1, r3
	it	ne
	bxne	lr
	it	eq
	cmpeq	r0, r2
	bx	lr
.L080459c6:
	mov.w	r12, #0x200000
	cmn.w	r12, r3, lsl #1
	it	cc
	cmncc.w	r12, r1, lsl #1
	bcs.n	.L080459da
	cmp	r1, r3
	bx	lr
.L080459da:
	push	{r0, r1, r2, r3}
	pop	{r2, r3}	@ swap the operands
	pop	{r0, r1}
	b.w	fn_08045766

@ ----------------------------------------------------------------------------
@ double_rsub - reverse subtract for 64-bit floats: returns b - a for a =
@ r0:r1 and b = r2:r3 (result in r0/r1).
@ Entry: teq r1,r3; r1 ^= 0x80000000 (0x080459ea, i.e. -a); when the original
@ signs differed (mi) it branches to 0x08044fbc (double_add_same_sign, the
@ magnitude-add body of 08044fac), otherwise it flips r3 and branches to
@ 0x08045ba4 (double_sub_same_sign, the magnitude-subtract body of 08045b94
@ double_sub). The decompiled C contains the 08044fac code with the flip
@ applied to r1. Same alignment shift tests (0x20, then 0x1f in the 08044fac
@ body, 0x1e in the 08045b94 body), LZCOUNT renormalisation and
@ round-to-nearest-even as 08044fac; exponent 0x7ff in the larger operand
@ calls dispatcher 080458d0 (never returns here); overflow returns signed
@ 0x7ff00000, underflow signed zero.
@ The two trailing bytes are padding (never reached, aligns the next function
@ to 2 bytes).
@ ----------------------------------------------------------------------------
	.section .text.double_rsub,"ax",%progbits
	.global double_rsub
	.thumb_func
	.type double_rsub, %function
double_rsub:
	push	{r4, lr}
	teq.w	r1, r3
	eor	r1, r1, #0x80000000
	bmi.w	double_add_same_sign
	eor	r3, r3, #0x80000000
	b.w	double_sub_same_sign
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ double_sqrt - square root of the 64-bit float in r0 (low) / r1 (high);
@ returns a 64-bit float in r0/r1.
@ If r1 + 0x100000 is not below 0x200000 (normal, positive exponent range) the
@ exponent is halved with bias ((r1 >> 20) + 0xfd) >> 1 + 0x180 in the high
@ word, an odd exponent shifts the mantissa left by 1, a seed byte is read from
@ the table at 0x08045aec indexed by (mantissa & 0x3fffff) >> 16 (the 64-byte
@ table overlaps the code bytes 08045aec..08045af9 and the data bytes at
@ 08045afa), and Newton iterations with 32x32 to 64-bit multiplies refine the
@ result, followed by a last-bit correction (square the result, compare with
@ the input, adjust by 1).
@ Otherwise: if (r1 + 0x100000) & 0x7fffffff >> 21 is nonzero returns
@ 0x7ff80000:00000000; if bit 20 of that value is 0 it calls dispatcher
@ 080458d0 (inline word at 08045b80, never returns here); else returns signed
@ zero (r1 & 0x80000000).
@ Inline word 0xBEFFDB6D at 08045b80: fields 0=5 1=5 2=5 3=5 4=5 5=7 6=7 7=7
@ 8=6, bit31=1. Literal at 08045b90 = 0x7ff80000 (quiet NaN high word).
@ ----------------------------------------------------------------------------
	.section .text.double_sqrt,"ax",%progbits
	.global double_sqrt
	.thumb_func
	.type double_sqrt, %function
double_sqrt:
	push.w	{r4, r5, r6, r7, r8, lr}
	add.w	r12, r1, #0x100000
	cmp.w	r12, #0x200000
	blt.w	.L08045b5e
	lsr.w	r12, r1, #20
	bic.w	r1, r1, r12, lsl #20
	orr	r1, r1, #0x100000
	add.w	r12, r12, #0xfd
	lsrs.w	r12, r12, #1
	add.w	r12, r12, #0x180
	bcc.n	.L08045a2a
	lsls	r0, r0, #1
	adcs	r1, r1
.L08045a2a:
	lsls	r1, r1, #10
	orr.w	r1, r1, r0, lsr #22
	lsls	r7, r0, #10
	adr	r4, .L08045aec
	lsrs	r6, r1, #26
	ldrb	r4, [r4, r6]
	lsrs	r2, r1, #16
	mul.w	r6, r4, r4
	mul.w	r6, r2, r6
	rsb.w	r6, r6, #0xc0000000
	umull	r6, r2, r4, r6
	lsrs	r6, r6, #23
	orr.w	r6, r6, r2, lsl #9
	mul.w	r4, r6, r6
	umull	r2, r3, r4, r1
	rsbs	r2, r2, #0
	rsb.w	r3, r3, #0xc0000000
	.inst.n 0xbf38	@ it cc
	.inst.n 0x1e5b	@ subcc r3, r3, #1
	umull	r4, r2, r6, r2
	movs	r4, #0
	umlal	r2, r4, r6, r3
	lsrs	r2, r2, #15
	orr.w	r6, r2, r4, lsl #17
	umull	r2, r3, r6, r6
	umull	lr, r2, r1, r2
	umull	lr, r4, r3, r7
	umaal	r4, r2, r3, r1
	rsbs	r4, r4, #0
	rsb.w	lr, r2, #0xc0000000
	it	cc
	subcc.w	lr, lr, #1
	umull	r2, r3, r6, r4
	mov.w	r2, #0
	umlal	r3, r2, r6, lr
	umull	r4, r6, r2, r3
	movs	r4, r6
	umaal	r6, r4, r2, r2
	umull	lr, r6, r1, r6
	umull	lr, r8, r4, r7
	umaal	r6, r8, r4, r1
	rsbs	r6, r6, #0
	rsb.w	r8, r8, #0x30000000
	it	cc
	subcc.w	r8, r8, #1
	umull	lr, r4, r2, r6
	umull	lr, r5, r3, r8
	umaal	r5, r4, r2, r8
	umull	lr, r6, r1, r5
	umull	lr, r8, r7, r4
	umaal	r8, r6, r1, r4
	adds.w	r5, r8, #0x20
	adcs	r6, r6, #0
	lsrs	r0, r5, #6
	orr.w	r0, r0, r6, lsl #26
	lsrs	r1, r6, #6
	sub.w	r8, r8, #0x1b
	and	r8, r8, #0x3f
.L08045aec:
	cmp.w	r8, #0xa
	bls.n	.L08045b2c
.L08045af2:
	add.w	r1, r1, r12, lsl #20
	pop.w	{r4, r5, r6, r7, r8, pc}
	@ 50 data bytes: the rest of the 64-byte seed table that starts at 08045aec
	.byte 0x00, 0xbf, 0xfc, 0xf5, 0xee, 0xe8, 0xe2, 0xdd, 0xd8, 0xd3
	.byte 0xcf, 0xcb, 0xc7, 0xc3, 0xc0, 0xbd, 0xb9, 0xb6, 0xb4, 0xb1
	.byte 0xae, 0xac, 0xa9, 0xa7, 0xa5, 0xa3, 0xa1, 0x9f, 0x9d, 0x9b
	.byte 0x9a, 0x98, 0x96, 0x95, 0x93, 0x92, 0x90, 0x8f, 0x8d, 0x8c
	.byte 0x8b, 0x89, 0x88, 0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81
.L08045b2c:
	umull	r6, r8, r0, r0
	mul.w	r2, r0, r1
	add.w	r8, r8, r2, lsl #1
	subs.w	r8, r8, r7, lsl #10
	bpl.n	.L08045b4e
	adds	r4, r6, r0
	adcs.w	r4, r8, r1
	bpl.n	.L08045af2
	.inst.n 0x1c40	@ adds r0, r0, #1
	adcs	r1, r1, #0
	b.n	.L08045af2
.L08045b4e:
	subs	r4, r6, r0
	sbcs.w	r4, r8, r1
	bmi.n	.L08045af2
	.inst.n 0x1e40	@ subs r0, r0, #1
	sbcs	r1, r1, #0
	b.n	.L08045af2
.L08045b5e:
	lsls.w	r12, r12, #1
	lsrs.w	r12, r12, #22
	bne.n	.L08045b84
	bcc.n	.L08045b76
	and	r1, r1, #0x80000000
	mov.w	r0, #0
	pop.w	{r4, r5, r6, r7, r8, pc}
.L08045b76:
	pop.w	{r4, r5, r6, r7, r8, lr}
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.word 0xbeffdb6d	@ inline word for 080458d0
.L08045b84:
	pop.w	{r4, r5, r6, r7, r8, lr}
	.inst.n 0x4901	@ ldr r1, .L08045b90
	mov.w	r0, #0
	bx	lr
.L08045b90:
	.word 0x7ff80000	@ quiet NaN high word

@ ----------------------------------------------------------------------------
@ double_sub - subtracts two 64-bit floats: r0 low / r1 high (a) minus r2 low /
@ r3 high (b), result in r0/r1 (push {r4,lr} at entry, pops at each return).
@ Own body 08045b94..08045ba3: teq r1,r3 (08045b96); when the signs differ (mi)
@ it XORs r3 with 0x80000000 (08045b9c) and bmi.w 08044fbc at 08045ba0
@ branches to double_add_same_sign (the magnitude-add body shared with
@ double_add 08044fac, so a - b becomes |a|+|b| with a's sign); when the signs
@ are equal bmi.w is not taken and execution falls through (no branch) from
@ 08045ba3 into double_sub_same_sign (08045ba4..08045d5d, the
@ magnitude-subtract body).
@ 08045ba4 (double_sub_same_sign): subs/sbcs of r0:r1 - r2:r3 and, when a < b
@ (carry clear at 08045baa), swaps the operands with the result sign inverted;
@ takes exponents r1>>20 and r3>>20 (mask 0xffe00000 from the word at
@ 08045d6c); shifts the smaller mantissa right by the exponent difference
@ (sticky path 08045c3a for a difference above 32); renormalises with clz,
@ rounds to nearest-even and returns signed zero on underflow. When b's
@ exponent field is 0 or a's is 0x7ff it goes to 08045d3e, and for a's
@ exponent 0x7ff (08045d54: pop {r4,lr}, push {r4,r5,r6,lr}) calls dispatcher
@ 080458d0 with bl at 08045d5a; the inline word 0x3ef6df40 at 08045d60 and
@ the slots after it belong to this function's own body (08045d5e..08045d6b):
@ NaN in r0:r1 or r2:r3 is class 8, field 6, and returns 0x7ff80000:00000000
@ (08045944); r0:r1 infinite with r2:r3 finite is class 2 (positive) or 5
@ (negative), field 5, and returns r0:r1 unchanged (08045956); both infinite
@ is class 3 or 7 (the sign bits of r1 and r3 are equal at 08045ba4, so
@ classes 4 and 6 do not occur), field 7, and returns 0x7ff80000:00000000;
@ the slot at 08045d64 (mov r0,r2; eor r1,r3,#0x80000000; bx lr at 08045d6a)
@ belongs to field 0 (class 0 or 1), which needs r0:r1 finite, so it cannot be
@ selected from this call.
@ 0804596c (double_return_infinity, signed infinity: r0 = 0, r1 = sign of r1 |
@ 0x7ff00000) is the shared overflow exit of 08044fac and is reached from the
@ add body (08044fbc), not from the subtract body.
@ ----------------------------------------------------------------------------
	.section .text.double_sub,"ax",%progbits
	.global double_sub
	.thumb_func
	.type double_sub, %function
double_sub:
	push	{r4, lr}
	teq.w	r1, r3
	it	mi
	eormi	r3, r3, #0x80000000
	bmi.w	double_add_same_sign

@ ----------------------------------------------------------------------------
@ double_sub_same_sign - magnitude-subtract body of the 64-bit float
@ subtraction: a = r0:r1, b = r2:r3 with equal sign bits; returns a-b rounded
@ in r0:r1.
@ subs r4,r0,r2 / sbcs r12,r1,r3 (08045ba4/08045ba6): when borrow, eor
@ r12,#0x80000000 and swap a/b (08045bac..08045bb8) so the result sign flips;
@ r4 = r1>>20, r12 = exponent difference (08045bbc/08045bc0), mask 0xffe00000
@ from 08045d6c. b exponent field 0 or a exponent 0x7ff goes to 08045d3e: a
@ exponent 0x7ff pops r4/lr, push {r4,r5,r6,lr} and bl 080458d0 with inline
@ word 0x3EF6DF40 at 08045d60, never continues here (decompiler lists slot 0
@ at 08045d64: r0=r2, r1=r3 xor 0x80000000, bx lr as selectable); otherwise a
@ is returned, r0:r1=0 when a exponent is also 0.
@ Exponent difference <= 0x20: negated b mantissa shifted and added
@ (decompiler 0x21 test); larger differences: 0x1d test on difference-0x20
@ returns a unchanged when above 0x1d; result renormalised with clz (08045cac,
@ 08045cb2, 08045cea), rounded to nearest even (ties clear bit 0 at
@ 08045c24..08045c38 and 08045c96..08045ca0), exponent underflow (08045cd2)
@ returns signed zero, carry-out cases at 08045d0e..08045d3c.
@ Entered from: double_add by bmi.w at 08044fb8 (signs differ, r3 flipped by
@ eor.mi at 08044fb4), double_sub by fall-through at 08045ba0 (bmi.w 08044fbc
@ not taken), double_rsub by b.w at 080459f6 (after eor r3 at 080459f2).
@ Expects on entry: r0:r1 = a, r2:r3 = b with equal sign bits, stack top = r4
@ and lr pushed by the caller entry (push {r4,lr}) and popped here (pop.w
@ {r4,lr} at 08045d48/08045d54 and in the exits); flags from the caller are
@ not used.
@ ----------------------------------------------------------------------------
	.global double_sub_same_sign
	.thumb_func
	.type double_sub_same_sign, %function
double_sub_same_sign:
	subs	r4, r0, r2
	sbcs.w	r12, r1, r3
	bcs.n	.L08045bbc
	eor	r12, r12, #0x80000000
	adds	r2, r2, r4
	adc.w	r3, r3, r12
	subs	r0, r0, r4
	sbc.w	r1, r1, r12
.L08045bbc:
	lsr.w	r4, r1, #20
	sub.w	r12, r4, r3, lsr #20
	ldr.w	lr, .L08045d6c
	tst.w	lr, r3, lsl #1
	it	ne
	teqne.w	lr, r4, lsl #21
	beq.w	.L08045d3e
	bic.w	r1, r1, r4, lsl #20
	bic.w	r3, r3, lr, asr #1
	rsbs	r2, r2, #0
	rsb	r3, r3, lr, asr #1
	.inst.n 0xbf38	@ it cc
	.inst.n 0x1e5b	@ subcc r3, r3, #1
	rsbs.w	lr, r12, #0x20
	bcc.n	.L08045c3a
	lsr.w	lr, r2, r12
	adds.w	r0, r0, lr
	asr.w	lr, r3, r12
	adc.w	r1, r1, lr
	rsb.w	lr, r12, #0x20
	lsl.w	lr, r3, lr
	adds.w	r0, r0, lr
	rsb.w	lr, r12, #0x20
	adcs	r1, r1, #0
	bmi.n	.L08045c68
.L08045c14:
	add.w	r1, r1, r4, lsl #20
	lsls.w	r2, r2, lr
	pop.w	{r4, lr}
	it	pl
	bxpl	lr
	.inst.n 0x1c40	@ adds r0, r0, #1
	itt	ne
	cmpne.w	r2, #0x80000000
	bxne	lr
	cmp	r0, #0
	.inst.n 0xbf0c	@ ite eq
	.inst.n 0x1c49	@ addeq r1, r1, #1
	.inst.w 0xf0200001	@ bicne r0, r0, #1
	bx	lr
.L08045c3a:
	adds.w	lr, r2, r2
	adc.w	r2, r3, r3
	it	ne
	movne.w	lr, #1
	orr.w	r2, lr, r2, lsl #1
	sub.w	r12, r12, #0x20
	rsbs.w	lr, r12, #0x1e
	bls.n	.L08045d04
	asr.w	lr, r3, r12
	adds.w	r0, r0, lr
	rsb.w	lr, r12, #0x1e
	adcs	r1, r1, #0xffffffff
	bpl.n	.L08045c14
.L08045c68:
	add.w	lr, lr, #1
	lsls.w	lr, r2, lr
	adcs	r0, r0
	adc.w	r1, r1, r1
	add.w	r12, r1, r4, lsl #21
	lsrs.w	r12, r12, #21
	bls.n	.L08045ca2
	add.w	r1, r1, r4, lsl #20
	adds.w	r0, r0, lr, lsr #31
	it	cc
	cmpcc.w	lr, #0x80000000
	pop.w	{r4, lr}
	it	ne
	bxne	lr
	cmp	r0, #0
	.inst.n 0xbf0c	@ ite eq
	.inst.n 0x1c49	@ addeq r1, r1, #1
	.inst.w 0xf0200001	@ bicne r0, r0, #1
	bx	lr
.L08045ca2:
	bcs.n	.L08045d0e
	lsr.w	r12, r4, #11
	bic	r4, r4, #0x800
	adds.w	r1, r1, #0x200000
	beq.n	.L08045cea
	clz	r2, r1
	subs	r2, #0xb
	subs	r4, r4, r2
	.inst.n 0x1ea4	@ subs r4, r4, #2
	rsbs.w	r3, r2, #0x20
	lsls	r1, r2
	lsrs.w	r3, r0, r3
	orrs	r1, r3
	lsls	r0, r2
.L08045cca:
	add.w	r1, r1, r12, lsl #31
	add.w	r1, r1, r4, lsl #20
	cmp	r4, #0
	pop.w	{r4, lr}
	it	ge
	bxge	lr
	add.w	r1, r1, #0x60000000
	and	r1, r1, #0x80000000
	mov.w	r0, #0
	bx	lr
.L08045cea:
	clz	r3, r0
	lsls.w	r1, r0, r3
	bne.n	.L08045cfa
	pop.w	{r4, lr}
	bx	lr
.L08045cfa:
	subs	r4, r4, r3
	subs	r4, #0x17
	lsls	r0, r1, #21
	lsrs	r1, r1, #11
	b.n	.L08045cca
.L08045d04:
	add.w	r1, r1, r4, lsl #20
	pop.w	{r4, lr}
	bx	lr
.L08045d0e:
	asrs	r1, r1, #1
	rrx	r0, r0
	add.w	r1, r1, r4, lsl #20
	pop.w	{r4, lr}
	b.n	.L08045d24
.L08045d1e:
	mov.w	r1, #0
	bx	lr
.L08045d24:
	lsls	r2, r1, #1
	it	eq
	tsteq	r0, r0
	beq.n	.L08045d1e
	cmp.w	r2, #0x200000
	it	cs
	bxcs	lr
	and	r1, r1, #0x80000000
	mov.w	r0, #0
	bx	lr
.L08045d3e:
	teq.w	lr, r4, lsl #21
	beq.n	.L08045d54
	tst.w	r1, lr, lsr #1
	pop.w	{r4, lr}
	itt	eq
	moveq	r1, #0
	moveq	r0, #0
	bx	lr
.L08045d54:
	pop.w	{r4, lr}
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.short 0xbf00	@ padding (bytes 00 bf), never reached
	.word 0x3ef6df40	@ inline word for 080458d0: 0=0 1=0 2=5 3=7 4=5 5=5 6=5 7=7 8=6, bit31 = 0
	mov	r0, r2	@ slot 0
	eor	r1, r3, #0x80000000
	bx	lr
.L08045d6c:
	.word 0xffe00000	@ exponent mask

@ ----------------------------------------------------------------------------
@ float_to_double - converts the 32-bit float in r0 to a 64-bit float, low word
@ in r0, high word in r1.
@ Code: r3 = r0<<1; r12 = (r3>>3) rotated right through carry with the sign bit
@ of r0 (ip = sign | (r0 & 0x7fffffff)>>3); r3 = (r0<<1) XOR r0 (Z set only
@ when r0 == 0).
@ When r0 != 0: r0 = r0<<29 (low word) and r1 = ip + 0x38000000 (exponent
@ rebias 1023-127 = 896 << 20); returns when (r3 & 0x7f000000) is nonzero,
@ i.e. the exponent bits 23..30 of r0 are not all equal (finite normal
@ number).
@ Otherwise: if ip bit 27 (r0 bit 30) is clear the exponent field is 0 (zero or
@ denormal): returns r1 = sign (ip & 0x80000000), r0 = 0 (denormals flush to
@ signed zero).
@ If ip bit 27 is set (exponent 0xff): rebuilds the original float in r0 (sign
@ | r0>>29 | ip<<3), push {r4,lr} and calls dispatcher 08045e7a with inline
@ word 0x92000000 at 08045dac: a NaN (class 8, field 2) selects slot 08045db8
@ (r1 = 0x7ff80000, r0 = 0: quiet NaN), an infinity (fields 0) selects slot
@ 08045db0 (r1 = r0, branch to 0804596c which returns signed double infinity
@ r1 = sign | 0x7ff00000, r0 = 0); the dispatcher never returns to 08045dac.
@ ----------------------------------------------------------------------------
	.section .text.float_to_double,"ax",%progbits
	.global float_to_double
	.thumb_func
	.type float_to_double, %function
float_to_double:
	lsls	r3, r0, #1
	lsr.w	r12, r3, #3
	rrx	r12, r12
	eors	r3, r0
	itttt	ne
	lslne	r0, r0, #29
	addne.w	r1, r12, #0x38000000
	tstne.w	r3, #0x7f000000
	bxne	lr
	tst.w	r12, #0x8000000
	bne.n	.L08045d98
	and	r1, r12, #0x80000000
	movs	r0, #0
	bx	lr
.L08045d98:
	and	r3, r12, #0x80000000
	orr.w	r0, r3, r0, lsr #29
	orr.w	r0, r0, r12, lsl #3
	push	{r4, lr}
	bl	float_special_dispatch
	.short 0xbf00	@ padding (bytes 00 bf), never reached
	.word 0x92000000	@ inline word for 08045e7a: fields 0..7 = 0, field 8 = 2, bit31 = 1
	mov.w	r1, r0	@ slot 0
	b.w	double_return_infinity
	mov.w	r1, #0x80000000	@ slot 2
	sub.w	r1, r1, #0x80000
	mov.w	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ double_eq - calls compare helper 080453d8 (fn_080453d8) on r0:r1 and r2:r3
@ (doubles) and returns r0 = 1 when the zero flag it leaves is set, else 0
@ (ite eq: moveq r0,#1 / movne r0,#0 at 08045dcc..08045dd0); push {r4,lr},
@ returns via pop {r4,pc}.
@ 080453d8 sets Z for equal values (cmp r1,r3 then cmpeq r0,r2 at
@ 080453ec..080453f4, swapped for negative operands at 0804541a..08045422)
@ and, when both operands have exponent field 0, runs cmp r1,r1 at 0804540a
@ so zeros and denormals of either sign compare equal; an operand with an
@ all-ones exponent field (NaN or infinity) goes to stub 0804543a and
@ dispatcher 080458d0 (inline word 0x00492492 at 08045440): for a NaN (class
@ 8, field 0) slot 08045444 loads r1 = 0x20000000 and r3 = 0x10000000 and
@ 0804510c leaves Z clear, so a NaN gives 0; the other classes (field 2) run
@ 0804510c with r1 and r3 unchanged.
@ Unreached: no branch, call or pointer to 08045dc6 is known
@ (scan of every instruction and stored word of the image).
@ ----------------------------------------------------------------------------
	.section .text.double_eq,"ax",%progbits
	.global double_eq
	.thumb_func
	.type double_eq, %function
double_eq:
	push	{r4, lr}
	bl	fn_080453d8
	ite	eq
	moveq	r0, #1
	movne	r0, #0
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ double_ne - calls compare helper 080453d8 (fn_080453d8) on r0:r1 and r2:r3
@ (doubles) and returns r0 = 1 when the zero flag it leaves is clear, else 0
@ (ite ne: movne r0,#1 / moveq r0,#0 at 08045dda..08045dde); push {r4,lr},
@ returns via pop {r4,pc}.
@ A NaN operand leaves Z clear in 080453d8 (dispatcher 080458d0, inline word
@ 0x00492492 at 08045440, slot 08045444), so a NaN gives 1.
@ Unreached: no branch, call or pointer to 08045dd4 is known
@ (scan of every instruction and stored word of the image).
@ ----------------------------------------------------------------------------
	.section .text.double_ne,"ax",%progbits
	.global double_ne
	.thumb_func
	.type double_ne, %function
double_ne:
	push	{r4, lr}
	bl	fn_080453d8
	ite	ne
	movne	r0, #1
	moveq	r0, #0
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ double_gt - compares the doubles r0:r1 (a) and r2:r3 (b) through helper
@ 0804568c (fn_0804568c) and returns r0 = 1 when the flags it leaves are
@ unsigned higher (carry set and zero clear: ite hi at 08045de8), else 0;
@ push {r4,lr}, returns via pop {r4,pc}.
@ 0804568c compares r1 with r3 then r0 with r2 when neither is negative and
@ with reversed operands (r3,r1 then r2,r0) when either is negative, so hi
@ means a > b; two operands whose exponent fields are both 0 (zeros and
@ denormals of either sign) give Z=1 (cmp r1,r1 at 080456be); a NaN operand
@ goes through dispatcher 080458d0 (inline word 0x00492492 at 080456f4) and
@ slot 080456f8 loads r1 = 0x10000000, r3 = 0x20000000 before 0804510c, which
@ leaves carry clear, so a NaN gives 0.
@ Called from 08009d6e, 08009d98, 08009dbc, 08009dd2, 08009de8, 08009dfe,
@ 08009e14, 08009e2a, 08009e40, 0800ac42, 0800ad92, 0800adc6, 0803b592 (13
@ call sites).
@ ----------------------------------------------------------------------------
	.section .text.double_gt,"ax",%progbits
	.global double_gt
	.thumb_func
	.type double_gt, %function
double_gt:
	push	{r4, lr}
	bl	fn_0804568c
	ite	hi
	movhi	r0, #1
	movls	r0, #0
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ double_ge - compares the doubles r0:r1 (a) and r2:r3 (b) through helper
@ 0804568c (fn_0804568c) and returns r0 = 1 when the carry flag it leaves is
@ set, else 0 (ite cs at 08045df6); push {r4,lr}, returns via pop {r4,pc}.
@ Carry set after 0804568c means a >= b (same compare sequence as 08045de2:
@ cmp r1,r3 / cmp r0,r2 for non-negative operands, reversed for negative
@ ones, operands whose exponent fields are both 0 give C=1); a NaN operand
@ leaves carry clear (dispatcher slot 080456f8 then 0804510c), so a NaN gives
@ 0.
@ Called from 0801b04a, 08022ca8, 08022cba, 08022d1a, 08022d2c, 0802302c,
@ 0802303a, 08023088, 08023096, 08023386, 08023a30, 080262d4, 0803dee6 (13
@ call sites).
@ ----------------------------------------------------------------------------
	.section .text.double_ge,"ax",%progbits
	.global double_ge
	.thumb_func
	.type double_ge, %function
double_ge:
	push	{r4, lr}
	bl	fn_0804568c
	ite	cs
	movcs	r0, #1
	movcc	r0, #0
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ double_le - compares the doubles r0:r1 (a) and r2:r3 (b) through helper
@ 08045704 (fn_08045704) and returns r0 = 1 when the flags it leaves are
@ unsigned lower-or-same (carry clear or zero set: ite ls at 08045e04), else
@ 0; push {r4,lr}, returns via pop {r4,pc}.
@ 08045704 runs the same compare sequence as 0804568c (cmp r1,r3 / cmp r0,r2,
@ reversed operands when either is negative), so ls means a <= b; a NaN
@ operand goes through dispatcher 080458d0 and slot 08045770 loads r1 =
@ 0x20000000, r3 = 0x10000000 before 0804510c, which leaves carry set and
@ zero clear (hi), so a NaN gives 0.
@ Called from 0803de3e.
@ ----------------------------------------------------------------------------
	.section .text.double_le,"ax",%progbits
	.global double_le
	.thumb_func
	.type double_le, %function
double_le:
	push	{r4, lr}
	bl	fn_08045704
	ite	ls
	movls	r0, #1
	movhi	r0, #0
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ double_lt - compares the doubles r0:r1 (a) and r2:r3 (b) through helper
@ 08045704 (fn_08045704) and returns r0 = 1 when the carry flag it leaves is
@ clear, else 0 (ite cc at 08045e12); push {r4,lr}, returns via pop {r4,pc}.
@ Carry clear after 08045704 means a < b (same compare sequence as
@ 08045dfe); a NaN operand leaves carry set (slot 08045770 then 0804510c), so
@ a NaN gives 0.
@ Called from 0800999e, 080099ca, 080099f6, 08009a22, 0801c604, 08023398,
@ 08023a4e, 08026288, 0802631c, 08026364, 080263a0, 0803b4ac, 0803df82,
@ 0803dfb4, 0803dfe2, 0803e010, 0803e04c, 0803e062, 0803e070 (19 call
@ sites); the calls at 0800999e, 080099ca, 080099f6 and 08009a22 compare with
@ r5:r9 = 10000.0 (high word 0x40c38800, loaded by vldr d0 at 0800997c from
@ 08009c00 and vmov r5,r9,d0 at 08009986).
@ ----------------------------------------------------------------------------
	.section .text.double_lt,"ax",%progbits
	.global double_lt
	.thumb_func
	.type double_lt, %function
double_lt:
	push	{r4, lr}
	bl	fn_08045704
	ite	cc
	movcc	r0, #1
	movcs	r0, #0
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ u64_to_float - converts the unsigned 64-bit integer r0 (low) / r1 (high) to a
@ 32-bit float returned in r0.
@ Entry 08045e1a: r2 = 0x3f800000, branches into the body of 08045e20 at
@ 08045e34 (r2 += 0x0f000000 gives base 0x4e800000, exponent field 0x9d).
@ Body: if r1 != 0, r3 = 32 and the leading-zero count is taken of r1, else r3
@ = 0 and it is taken of r0 (movs r1,r0 at 08045e3e); when both words are zero
@ it returns r0 unchanged (0).
@ Then r3 = r3 - clz, r1 = (r1 << clz) | (r0 >> r3) (top-aligned mantissa), r2
@ += r3 << 23, round bit = bit 7 of r1 (carry out of orrs ip,ip,r1,lsl #25 at
@ 08045e64), sticky = bits 6..0 of r1 and the bits of r0 shifted out (lsls.w
@ at 08045e60); result r0 = r2 + (r1>>8) + round bit (adc at 08045e68), and on
@ an exact tie (sticky zero, round bit set) bit 0 is cleared (biccs at
@ 08045e74): round to nearest-even.
@ Called from 0801b6a4 and 0801bf0e.
@ ----------------------------------------------------------------------------
	.section .text.u64_to_float,"ax",%progbits
	.global u64_to_float
	.thumb_func
	.type u64_to_float, %function
u64_to_float:
	mov.w	r2, #0x3f800000
	b.n	uint64_to_float_core

@ ----------------------------------------------------------------------------
@ i64_to_float - converts the signed 64-bit integer r0 (low) / r1 (high) to a
@ 32-bit float returned in r0.
@ r2 = r1 & 0x80000000 (sign); when negative the 64-bit value is negated (negs
@ r0; rsb r1,r1,#0; subcc r1,r1,#1 at 08045e26..08045e2e); r2 |= 0x3f800000
@ (orr at 08045e30).
@ The 20-byte body ends at 08045e33 without a branch and falls through into
@ uint64_to_float_core (shared with 08045e1a), which does r2 += 0x0f000000 at
@ 08045e34 and the rest: returns r0 unchanged (0) when both words are zero,
@ otherwise leading-zero count of r1 (r3 = 32) or r0 (r3 = 0), r3 = r3 - clz,
@ mantissa r1 = (r1<<clz)|(r0>>r3), r2 += r3<<23, result = r2 + (r1>>8) +
@ round bit (bit 7 of r1), with the bit-0 clear on an exact tie (round to
@ nearest-even).
@ Called from 0802168e.
@ ----------------------------------------------------------------------------
	.global i64_to_float
	.thumb_func
	.type i64_to_float, %function
i64_to_float:
	ands	r2, r1, #0x80000000
	bpl.n	.L08045e30
	rsbs	r0, r0, #0
	rsb.w	r1, r1, #0
	.inst.n 0xbf38	@ it cc
	.inst.n 0x1e49	@ subcc r1, r1, #1
.L08045e30:
	orr	r2, r2, #0x3f800000

@ ----------------------------------------------------------------------------
@ uint64_to_float_core - shared body of u64_to_float and i64_to_float:
@ converts a non-negative 64-bit magnitude r0 (low) : r1 (high) to a 32-bit
@ float returned in r0; the decompiler's param_3 is r2 = sign bit | 0x3f800000
@ | add.w r2,r2,#0xf000000 (08045e34); movs r3,r1: r1!=0 gives r3=32 and the
@ leading-zero count is taken of r1, else r3=0 and r1=r0 (movs.eq at 08045e3e)
@ and when both words are zero bx.eq lr returns r0 (0).
@ clz r12,r1; r1<<=r12; r3-=r12; r1|=r0>>r3 (08045e44..08045e54); r2+=r3<<23
@ (08045e58); r3=32-r3, lsls r12,r0,r3 and orrs r12,r12,r1,lsl #25 give the
@ carry (round bit = bit 7 of r1) and Z (sticky bits clear) (08045e60/
@ 08045e64); r0 = r2 + (r1>>8) + carry (adc at 08045e68); movs.ne
@ r12,#0x4000000 clears carry when sticky is set, bic.cs r0,r0,#1 clears bit 0
@ on an exact tie (08045e6e..08045e74); bx lr.
@ Entered from: u64_to_float by b at 08045e1e (r2 = 0x3f800000 loaded at
@ 08045e1a) and i64_to_float by fall-through from 08045e30 (orr
@ r2,r2,#0x3f800000 after negating a negative value).
@ Expects on entry: r0 = low word, r1 = high word of the magnitude, r2 = sign
@ bit (bit 31) | 0x3f800000, lr = return address; clobbers r1, r2, r3, r12,
@ flags.
@ ----------------------------------------------------------------------------
	.global uint64_to_float_core
	.thumb_func
	.type uint64_to_float_core, %function
uint64_to_float_core:
	add.w	r2, r2, #0xf000000
	movs	r3, r1
	itee	ne
	movne	r3, #0x20
	movseq.w	r1, r0
	bxeq	lr
	clz	r12, r1
	lsl.w	r1, r1, r12
	sub.w	r3, r3, r12
	lsr.w	r12, r0, r3
	orr.w	r1, r1, r12
	add.w	r2, r2, r3, lsl #23
	rsb.w	r3, r3, #0x20
	lsls.w	r12, r0, r3
	orrs.w	r12, r12, r1, lsl #25
	adc.w	r0, r2, r1, lsr #8
	it	ne
	movsne.w	r12, #0x4000000
	it	cs
	biccs	r0, r0, #1
	bx	lr

@ ----------------------------------------------------------------------------
@ float_special_dispatch - inline-word dispatcher for 32-bit float special
@ cases with operands r0 and r1; the caller does push {r4,lr}; bl 08045e7a and
@ a 32-bit word follows the bl; never returns to the call site.
@ Code: lr = (lr + 2) & ~3 and r4 = word at that address (lr advances by 4
@ past it, so the slot table starts at word address + 4).
@ Class (r12): r2 = r1<<1 is tested against 0xff000000 only when bit 31 of the
@ word is clear (a NaN in r1 gives class 8); r3 = r0<<1 > 0xff000000 (NaN in
@ r0) always gives class 8; r0 equal to infinity (r3 == 0xff000000) gives
@ class 3*sign(r0) + 2, plus (sign(r1) + 1) when r2 == 0xff000000 (r1 also
@ infinite); r0 finite gives class = sign bit of r1 (0 or 1).
@ field = (word >> (3 * class)) & 7. Fields 0..3: pops r4/lr and branches to
@ slot address word + 4 + 4*field (bit 0 set), so the slot's bx lr returns to
@ the original caller. Field 4: returns r1 (r0 = r1) and field 5: returns r0,
@ each after flushing a nonzero operand whose (value<<1) < 0x01000000
@ (denormal) to its sign bit only (08045ef6..08045f00). Fields 6 and 7:
@ return 0x7fc00000 (quiet NaN). The tbb at 08045ee2 uses the table bytes
@ 07 08 02 02 at 08045ee6.
@ Callers in this file: 08045d70 (word 0x92000000 at 08045dac) and 08045f20
@ (word 0x3effffed at 08045ffc).
@ ----------------------------------------------------------------------------
	.section .text.float_special_dispatch,"ax",%progbits
	.global float_special_dispatch
	.thumb_func
	.type float_special_dispatch, %function
float_special_dispatch:
	add.w	lr, lr, #2
	bic	lr, lr, #3
	ldr.w	r4, [lr], #4
	tst	r4, r4
	bmi.n	.L08045e94
	lsl.w	r2, r1, #1
	cmp.w	r2, #0xff000000
	bhi.n	.L08045eb8
.L08045e94:
	lsl.w	r3, r0, #1
	cmp.w	r3, #0xff000000
	bhi.n	.L08045eb8
	bne.n	.L08045ebe
	lsr.w	r12, r0, #31
	add.w	r12, r12, r12, lsl #1
	add.w	r12, r12, #2
	cmp.w	r2, #0xff000000
	it	eq
	adceq.w	r12, r12, r1, lsr #31
	b.n	.L08045ec2
.L08045eb8:
	mov.w	r12, #8
	b.n	.L08045ec2
.L08045ebe:
	lsr.w	r12, r1, #31
.L08045ec2:
	add.w	r3, r12, r12, lsl #1
	lsr.w	r4, r4, r3
	and	r4, r4, #7
	subs.w	r12, r4, #4
	bcs.n	.L08045ee2
	add.w	r12, lr, r4, lsl #2
	pop.w	{r4, lr}
	orr	r12, r12, #1
	bx	r12
.L08045ee2:
	tbb	[pc, r12]
.L08045ee6:
	.byte (.L08045ef4 - .L08045ee6)/2
	.byte (.L08045ef6 - .L08045ee6)/2
	.byte (.L08045eea - .L08045ee6)/2
	.byte (.L08045eea - .L08045ee6)/2
.L08045eea:
	mov.w	r0, #0x80000000
	sub.w	r0, r0, #0x400000
	pop	{r4, pc}
.L08045ef4:
	mov	r0, r1
.L08045ef6:
	lsls	r2, r0, #1
	it	ne
	rsbsne.w	r2, r2, #0x1000000
	it	hi
	andhi	r0, r0, #0x80000000
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fpscr_set_fz_dn_round_nearest - no parameters. Reads FPSCR (vmrs r0,fpscr),
@ clears bits 0..15 and 22..25 (mask 0x03c0ffff from movw #0xffff / movt
@ #0x3c0), sets bits 24 and 25 (orr #0x03000000: FZ and DN), writes the value
@ back (vmsr fpscr,r0 at 08045f1a) and returns the new FPSCR value in r0.
@ Effect on FPSCR: rounding mode bits 22..23 = 0 (round to nearest),
@ flush-to-zero and default-NaN on, exception flags and trap enable bits
@ 0..15 cleared.
@ Called from 080072ca.
@ ----------------------------------------------------------------------------
	.section .text.fpscr_set_fz_dn_round_nearest,"ax",%progbits
	.global fpscr_set_fz_dn_round_nearest
	.thumb_func
	.type fpscr_set_fz_dn_round_nearest, %function
fpscr_set_fz_dn_round_nearest:
	vmrs	r0, fpscr
	movw	r1, #0xffff
	movt	r1, #0x3c0
	bic.w	r0, r0, r1
	orr	r0, r0, #0x3000000
	vmsr	fpscr, r0
	bx	lr

@ ----------------------------------------------------------------------------
@ float_ieee_remainder - remainder of two 32-bit floats: r0 = x (dividend), r1
@ = y (divisor), result in r0.
@ If the exponent of either operand is 0xff (bics tests against 0xff000000 at
@ 08045f24 / 08045f2a) beq.w 08045ff6 at 08045f2e branches to the split-off
@ function float_remainder_special_case (push {r4,lr} at 08045ff6; bl
@ 08045e7a at 08045ff8, a dispatcher that never returns to 08045ffc); the
@ inline word 0x3effffed at 08045ffc, which the dispatcher reads, belongs to
@ this function: y infinite with x finite returns x, every case with x
@ infinite or a NaN returns 0x7fc00000.
@ Exponents are taken as (r>>7)&0xff0000 in r2 (x) and r3 (y), with r3 |= 5
@ when x is negative (bit 0 = sign, bit 2 = saved sign); if either exponent
@ field is 0 (08046000, L_08046000): y's exponent 0 returns 0x7fc00000 (ldr at
@ 0804600c, word 0x7fc00000 at 08046010), otherwise returns x & 0x80000000.
@ Otherwise mantissas r0 = x<<8 | 0x80000000, r1 = y<<8 | 0x80000000 and a
@ shift-subtract loop (08045f62..08045f86) runs while x's exponent field
@ exceeds y's minus 0x10000: bit 1 of r3 records whether the step subtracted
@ (bit 31 of r0 set), a negative difference is negated and flips bit 0 of r3,
@ r0 is doubled and x's exponent decreases by 0x10000.
@ After the loop, when (r2 asr 16) >= (r3 asr 16) (x's exponent field >= y's
@ minus 1, because r3 was reduced by 0x10000 at 08045f5e; otherwise 08045fa4
@ is entered directly) and r0 >= r1 with (r0 != r1 or bit 1 of r3 set) (the
@ tie goes by the last quotient bit) it replaces r0 by -(r0 - 2*r1) and flips
@ bit 0 of r3 (08045f98..08045fa0): the result is the IEEE remainder x - n*y
@ with n the nearest integer to x/y, ties to even.
@ Renormalisation: r0 = 0 after doubling returns bit 2 of r3 shifted to bit 31
@ (signed zero, 08045fc8); otherwise, when r0 doubled at 08045fa4 has no carry
@ out and a clear top bit, clz of r0 renormalises and reduces the exponent
@ (carry out goes to 08045fe4, which returns via 08045fe8 when the exponent is
@ > 0; a set top bit goes to 08045fda, which doubles r0 again and reduces the
@ exponent by 0x10000 first); an exponent <= 0 returns only bit 0 of r3
@ shifted to bit 31 (08045fc2: signed zero); else returns exponent<<7 | r0>>9
@ | r3<<31 (08045fe8).
@ Called from 08043864.
@ ----------------------------------------------------------------------------
	.section .text.float_ieee_remainder,"ax",%progbits
	.global float_ieee_remainder
	.thumb_func
	.type float_ieee_remainder, %function
float_ieee_remainder:
	mov.w	r12, #0xff000000
	bics.w	r3, r12, r1, lsl #1
	it	ne
	bicsne.w	r2, r12, r0, lsl #1
	beq.w	float_remainder_special_case
	mov.w	r12, #0xff0000
	and.w	r3, r12, r1, lsr #7
	tst.w	r0, #0x80000000
	it	ne
	orrne	r3, r3, #5
	ands.w	r2, r12, r0, lsr #7
	it	ne
	tstne.w	r3, r12
	beq.w	L_08046000
	mov.w	r12, #0x80000000
	orr.w	r0, r12, r0, lsl #8
	orr.w	r1, r12, r1, lsl #8
	sub.w	r3, r3, #0x10000
.L08045f62:
	cmp	r2, r3
	ble.n	.L08045f88
	bic	r3, r3, #2
	cmp.w	r0, #0x80000000
	bcc.n	.L08045f7e
	orr	r3, r3, #2
	subs	r0, r0, r1
	itt	lt
	rsblt	r0, r0, #0
	eorlt	r3, r3, #1
.L08045f7e:
	lsl.w	r0, r0, #1
	sub.w	r2, r2, #0x10000
	b.n	.L08045f62
.L08045f88:
	asr.w	r12, r2, #16
	cmp.w	r12, r3, asr #16
	blt.n	.L08045fa4
	cmp	r0, r1
	bcc.n	.L08045fa4
	beq.n	.L08045fd2
.L08045f98:
	sub.w	r0, r0, r1, lsl #1
	rsb.w	r0, r0, #0
	eor	r3, r3, #1
.L08045fa4:
	lsls	r0, r0, #1
	bcs.n	.L08045fe4
	bmi.n	.L08045fda
	beq.n	.L08045fc8
	clz	r12, r0
	add.w	r12, r12, #1
	lsl.w	r0, r0, r12
	sub.w	r2, r2, r12, lsl #16
.L08045fbc:
	rsbs.w	r12, r2, #0
	blt.n	.L08045fe8
	lsl.w	r0, r3, #31
	bx	lr
.L08045fc8:
	lsl.w	r0, r3, #29
	and	r0, r0, #0x80000000
	bx	lr
.L08045fd2:
	tst.w	r3, #2
	beq.n	.L08045fa4
	b.n	.L08045f98
.L08045fda:
	lsl.w	r0, r0, #1
	subs.w	r2, r2, #0x10000
	ble.n	.L08045fbc
.L08045fe4:
	cmp	r2, #0
	ble.n	.L08045fbc
.L08045fe8:
	lsl.w	r2, r2, #7
	orr.w	r0, r2, r0, lsr #9
	orr.w	r0, r0, r3, lsl #31
	bx	lr

@ ----------------------------------------------------------------------------
@ float_remainder_special_case - special-value exit of float_ieee_remainder
@ 08045f20: stub with push {r4,lr}; bl 08045e7a (float_special_dispatch) and
@ the inline word 0x3effffed at 0x08045ffc; never returns to the call. Bit31
@ clear (operand r1 is tested for NaN too). Fields: class 0 and 1 (r0 finite,
@ r1 infinite) = 5, classes 2..7 (r0 infinite) = 7, class 8 (a NaN) = 6; all
@ fields are above 3, so no slot is entered; the dispatcher returns r0 itself:
@ field 5 (tbb at 0x08045ee2, table bytes 07 08 02 02 at 0x08045ee6, entry for
@ field 5 = 0x08) goes to 0x08045ef6 and returns r0 (the dividend) unchanged
@ unless r0 is a nonzero denormal (lsls/rsbsne/it hi at 0x08045ef6..0x08045efe),
@ in which case andhi.w at 0x08045f00 returns r0 & 0x80000000 (signed zero);
@ fields 6 and 7 go to 0x08045eea and return 0x7fc00000.
@ Entered by: beq.w at 0x08045f2e in 08045f20 (the bics tests at
@ 0x08045f24/0x08045f2a find an exponent field 0xff in r1 or r0). The previous
@ instruction 0x08045ff4 is bx lr, no fall-in.
@ Entry state: r0 = dividend, r1 = divisor as 32-bit floats; lr = caller of
@ 08045f20; the dispatcher pops r4 and lr itself.
@ Global label L_08046000 (08046000) is the zero-exponent exit of
@ float_ieee_remainder (code in another unit branches to it; r12 = 0xff0000
@ mask on entry). Global label L_08046014 (08046014) is a further entry used
@ from other code: r0 = 0xff | (r0 >> 23), then r0 <<= 23. The last two bytes
@ are padding (never reached, aligns the next function to 2 bytes).
@ ----------------------------------------------------------------------------
	.section .text.float_remainder_special_case,"ax",%progbits
	.global float_remainder_special_case
	.thumb_func
	.type float_remainder_special_case, %function
float_remainder_special_case:
	push	{r4, lr}
	bl	float_special_dispatch
	.word 0x3effffed	@ inline word for 08045e7a: 0=5 1=5 2=7 3=7 4=7 5=7 6=7 7=7 8=6, bit31 = 0
	.global L_08046000
	.thumb_func
L_08046000:
	tst.w	r12, r1, lsr #7
	beq.n	.L0804600c
	and	r0, r0, #0x80000000
	bx	lr
.L0804600c:
	.inst.n 0x4800	@ ldr r0, .L08046010
	bx	lr
.L08046010:
	.word 0x7fc00000
	.global L_08046014
	.thumb_func
L_08046014:
	movs	r1, #0xff
	orr.w	r0, r1, r0, lsr #23
	lsls	r0, r0, #23
	bx	lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ double_to_i64 - converts the 64-bit float r0 (low) / r1 (high) to a signed
@ 64-bit integer in r0 (low) / r1 (high), truncating toward zero.
@ Code: e = r1 asr 20 (12-bit signed: sign bit with weight -2048 plus the
@ 11-bit exponent), mantissa r3:ip = (r1<<11 | r0>>21) : r0<<11 with the
@ implicit bit (bit 31 of r3) forced when e != 0 (08046030).
@ Positive branch (e >= 0): shift = 1008 - (e - 78) = 1086 - exponent; shift
@ <= 0 (value >= 2^63, infinity, NaN) goes to the dispatcher call at 080460c6;
@ otherwise the shift is capped at 80 (cmp #80 / movge at 08046042..08046046)
@ and the 64-bit mantissa is shifted right by it (lsr by r2 on both words,
@ plus the cross-word terms r3<<(32-r2) for r2 < 32 and r3>>(r2-32) for r2 >=
@ 32) and returned.
@ Negative branch (e < 0): e == -2048 (exponent 0) clears the implicit bit
@ (08046078); shift = 46 - (e + 1008) = 1086 - exponent; shift < 0 goes to the
@ dispatcher; shift == 0 is accepted only when the mantissa equals
@ 0x80000000:00000000 (value -2^63, 080460ba); otherwise the same capped
@ shift, then the 64-bit result is negated (negs r0; rsb r1; subcc r1,#1 at
@ 080460ae..080460b6).
@ Dispatcher (push {r4,r5,r6,lr}; bl 080458d0, inline word 0x80492492 at
@ 080460cc): NaN in r0:r1 is class 8 (field 0) and runs slot 080460d0 (r0 = 0,
@ r1 = 0, returns 0); every other class has field 2 and runs slot 080460d8
@ (r0 = NOT (r1 asr 31), r1 = r0 XOR 0x80000000): +0x7fffffff:ffffffff for a
@ non-negative r1, 0x80000000:00000000 for a negative r1 (saturation); the
@ dispatcher never returns to 080460cc. The last two bytes are padding (never
@ reached, aligns the next function to 2 bytes).
@ Called from 08020f82, 08020fe6, 08021094, 0802e0ca, 0803b12c, 0803b194,
@ 0803b21c, 0803b248, 0803b280, 0803b34e, 0803b422, 0803b508, 0803b5f2,
@ 0803b64c, 0803b740, 0803b796 (16 call sites).
@ ----------------------------------------------------------------------------
	.section .text.double_to_i64,"ax",%progbits
	.global double_to_i64
	.thumb_func
	.type double_to_i64, %function
double_to_i64:
	asrs	r2, r1, #20
	lsl.w	r3, r1, #11
	orr.w	r3, r3, r0, lsr #21
	lsl.w	r12, r0, #11
	it	ne
	orrne	r3, r3, #0x80000000
	bmi.n	.L0804606e
	subw	r2, r2, #0x4e
	rsbs.w	r2, r2, #0x3f0
	ble.w	.L080460c6
	cmp	r2, #0x50
	it	ge
	movge	r2, #0x50
	lsr.w	r1, r3, r2
	lsr.w	r0, r12, r2
	rsbs.w	r2, r2, #0x20
	push	{r5, r6}
	lsl.w	r5, r3, r2
	it	hi
	orrhi	r0, r5
	rsb.w	r2, r2, #0
	lsr.w	r5, r3, r2
	it	ls
	orrls	r0, r5
	pop	{r5, r6}
	bx	lr
.L0804606e:
	add.w	r2, r2, #0x3f0
	cmn.w	r2, #0x410
	it	eq
	biceq	r3, r3, #0x80000000
	rsbs.w	r2, r2, #0x2e
	blt.n	.L080460c6
	beq.n	.L080460ba
.L08046084:
	cmp	r2, #0x50
	it	ge
	movge	r2, #0x50
	lsr.w	r1, r3, r2
	lsr.w	r0, r12, r2
	rsbs.w	r2, r2, #0x20
	push	{r5, r6}
	lsl.w	r5, r3, r2
	it	hi
	orrhi	r0, r5
	rsb.w	r2, r2, #0
	lsr.w	r5, r3, r2
	it	ls
	orrls	r0, r5
	pop	{r5, r6}
	rsbs	r0, r0, #0
	rsb.w	r1, r1, #0
	.inst.n 0xbf38	@ it cc
	.inst.n 0x1e49	@ subcc r1, r1, #1
	bx	lr
.L080460ba:
	teq.w	r12, #0
	it	eq
	teqeq.w	r3, #0x80000000
	beq.n	.L08046084
.L080460c6:
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.word 0x80492492	@ inline word for 080458d0: fields 0..7 = 2, field 8 = 0, bit31 = 1
	mov.w	r0, #0	@ slot 0
	movs	r1, #0
	bx	lr
	mvn.w	r0, r1, asr #31	@ slot 2
	eor	r1, r0, #0x80000000
	bx	lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ double_to_u64 - converts the 64-bit float r0 (low) / r1 (high) to an unsigned
@ 64-bit integer in r0 (low) / r1 (high), truncating toward zero.
@ Code: e = r1 asr 20 (12-bit signed), mantissa high r3 = r1<<11 | r0>>21 with
@ bit 31 forced when e != 0, low ip = r0<<11.
@ Positive branch (e >= 0): shift = 1008 - (e - 78) = 1086 - exponent; shift <
@ 0 (value >= 2^64, infinity, NaN) goes by blt.w 08046146 at 08046102 to the
@ split-off function double_to_u64_special_case; otherwise (shift 0 is
@ accepted) the shift is capped at 80 and the mantissa is shifted right (same
@ two-word shift as 08046020) and returned.
@ Negative branch (r1 sign set, 08046132): r1 + 0x40000000 compared signed
@ with -0x100000: smaller (r1 < 0xbff00000, |x| < 1.0 including -0.0) returns
@ r0 = r1 = 0, otherwise bge.n 08046146 at 0804613a goes to
@ double_to_u64_special_case.
@ double_to_u64_special_case (08046146..0804614b) is only push {r4,r5,r6,lr};
@ bl 080458d0 (08046148), a dispatcher; the inline word 0x80249249 at 0804614c
@ and the two slots after it belong to this function: NaN in r0:r1 is class 8
@ (field 0) and runs slot 08046150 (r0 = 0, r1 = r0, returns 0:0); every other
@ class has field 1 and runs slot 08046154 (r0 = NOT (r1 asr 31), r1 = r0):
@ 0xffffffff:ffffffff for a non-negative r1 (saturation), 0:0 for a negative
@ r1; never returns to 0804614c.
@ Called from 08030b3a.
@ ----------------------------------------------------------------------------
	.section .text.double_to_u64,"ax",%progbits
	.global double_to_u64
	.thumb_func
	.type double_to_u64, %function
double_to_u64:
	asrs	r2, r1, #20
	lsl.w	r3, r1, #11
	orr.w	r3, r3, r0, lsr #21
	lsl.w	r12, r0, #11
	it	ne
	orrne	r3, r3, #0x80000000
	bmi.n	.L08046132
	subw	r2, r2, #0x4e
	rsbs.w	r2, r2, #0x3f0
	blt.w	double_to_u64_special_case
	cmp	r2, #0x50
	it	ge
	movge	r2, #0x50
	lsr.w	r1, r3, r2
	lsr.w	r0, r12, r2
	rsbs.w	r2, r2, #0x20
	push	{r5, r6}
	itt	hi
	lslhi.w	r5, r3, r2
	orrhi	r0, r5
	rsb.w	r2, r2, #0
	itt	ls
	lsrls.w	r5, r3, r2
	orrls	r0, r5
	pop	{r5, r6}
	bx	lr
.L08046132:
	add.w	r2, r1, #0x40000000
	cmn.w	r2, #0x100000
	bge.n	double_to_u64_special_case
	mov.w	r0, #0
	mov.w	r1, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ double_to_u64_special_case - exit of double_to_u64 080460e4 for positive
@ values of 2^64 or more (finite, infinity or NaN) and for negative values
@ whose exponent field is 0x3ff or more (absolute value 1 or more, finite,
@ infinity or NaN): stub with push {r4,r5,r6,lr}; bl 080458d0
@ (double_special_dispatch) and the inline word 0x80249249 at 0x0804614c;
@ never returns to the call. Bit31 set, field 1 for classes 0..7, field 0 for
@ class 8 (r0:r1 NaN). Slot 0 (0x08046150): movs r0,#0; b.n 0x08046158 (mov
@ r1,r0; bx lr) returns 0:0. Slot 1 (0x08046154): mvn r0,r1,asr #31 gives
@ 0xffffffff for a positive value, 0 for a negative one, then 0x08046158
@ copies it to r1 and returns r0:r1 = 0xffffffff:0xffffffff or 0:0.
@ Entered by: blt.w at 0x08046102 (shift count 0x3f0 - (e - 78) < 0 for a
@ positive value, i.e. 2^64 or larger, infinity or NaN) and bge.n at
@ 0x0804613a (negative value whose r1 + 0x40000000 is not below -0x100000 as a
@ signed number, i.e. r1 in 0xbff00000..0xffffffff, exponent field >= 0x3ff; a
@ finite one gets class 0 or 1 from the stale r3 sign at 0x08045918, so field
@ 1, slot 1, result 0:0). The previous instruction 0x08046144 is bx lr, no
@ fall-in.
@ Entry state: r0 = low word, r1 = high word of the double; lr = caller of
@ double_to_u64.
@ After the dispatcher stub follow three code blocks that other code branches
@ into (global labels L_0804615c, L_08046160, L_08046164):
@ L_0804615c is b.w format_float_efg (08007b20); L_08046160 is b.w
@ format_float_hex (08007d8c); L_08046164 is a shared tail reached from
@ 080450fc via b.w: r3 = r12 & 15; 9 sets r0 = 8 and jumps to 08046224
@ (L_08046224); 10 returns 0x80000000 in r0 when r12 bit 6 is set; 8 with r12
@ bit 6 set returns r0 = r1 = 0, with bit 6 clear and bit 4 set converts a
@ float in r0 to a double bit layout (r1 = r0 & 0xff000000 | (r0 &
@ 0x0fffffff)>>3, r0 = (r0 & 0x0fffffff)<<29) and with bit 4 clear the
@ reverse (08046164..080461c6).
@ ----------------------------------------------------------------------------
	.global double_to_u64_special_case
	.thumb_func
	.type double_to_u64_special_case, %function
double_to_u64_special_case:
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.word 0x80249249	@ inline word for 080458d0: fields 0..7 = 1, field 8 = 0, bit31 = 1
	movs	r0, #0	@ slot 0
	b.n	.L08046158
	mvn.w	r0, r1, asr #31	@ slot 1
.L08046158:
	mov	r1, r0
	bx	lr
	.global L_0804615c
	.thumb_func
L_0804615c:
	b.w	format_float_efg
	.global L_08046160
	.thumb_func
L_08046160:
	b.w	format_float_hex
	.global L_08046164
	.thumb_func
L_08046164:
	and	r3, r12, #0xf
	cmp	r3, #9
	it	eq
	moveq	r0, #8
	beq.w	L_08046224
	cmp	r3, #0xa
	beq.n	.L0804618e
	cmp	r3, #8
	it	ne
	bxne	lr
	it	eq
	tsteq.w	r12, #0x40
	beq.n	.L0804619a
	mov.w	r0, #0
	mov.w	r1, #0
	bx	lr
.L0804618e:
	tst.w	r12, #0x40
	it	ne
	movne.w	r0, #0x80000000
	bx	lr
.L0804619a:
	tst.w	r12, #0x10
	beq.n	.L080461b2
	and	r2, r0, #0xff000000
	bic	r3, r0, #0xf0000000
	orr.w	r1, r2, r3, lsr #3
	lsl.w	r0, r3, #29
	bx	lr
.L080461b2:
	and	r0, r0, #0xe0000000
	bic	r2, r1, #0xff000000
	orr.w	r2, r2, r0
	and	r0, r1, #0xff000000
	orr.w	r0, r0, r2, ror #29
	bx	lr

@ ----------------------------------------------------------------------------
@ double_scale_by_pow2 - scales the 64-bit float r0 (low) / r1 (high) by 2^n
@ with n = r2 (signed integer), result in r0/r1.
@ E = (r1>>20) & 0x7ff (r3); when E != 0 and 0x7ff - E > n and E + n > 0
@ (signed compares through the IT block at 080461d4..080461e4; there is no
@ separate test for E == 0x7ff, so E == 0x7ff with n < 0 and n > -0x7ff also
@ takes this exit) it returns r1 + (n << 20) with r0 unchanged.
@ E == 0 (08046206): returns r1 & 0x80000000, r0 = 0 (signed zero, denormals
@ flush).
@ E == 0x7ff (08046210): infinity (r0 == 0 and mantissa bits r1 & 0xfffff ==
@ 0) returns the operand unchanged; a NaN sets r12 = 0x0400009b and branches
@ to 080450fc (L_080450fc), which loads r1 = 0x7ff80000 (word at 08045108),
@ r0 = 0 and branches to 08046164; with r12 & 15 = 11 that code returns (bx lr
@ at 0804617a) with r0:r1 = 0x7ff80000:00000000 (quiet NaN).
@ Other E (exponent out of range, 080461f0..08046204): r1 &= 0x80000000, r0 =
@ 0, and r1 |= 0x7ff00000 when n >= 0: signed infinity for overflow, signed
@ zero for underflow.
@ Kept unreachable blocks 08046164..08046252 (shared tail reached from 080450fc
@ via b.w 08046164 and not from the main path above): r3 = r12 & 15; 9 sets r0
@ = 8 and jumps to 08046224; 10 returns 0x80000000 in r0 when r12 bit 6 is
@ set; 8 with r12 bit 6 set returns r0 = r1 = 0, with bit 6 clear and bit 4
@ set converts a float in r0 to a double bit layout (r1 = r0 & 0xff000000 |
@ (r0 & 0x0fffffff)>>3, r0 = (r0 & 0x0fffffff)<<29) and with bit 4 clear the
@ reverse (08046164..080461c6); 08046224 (global L_08046224): r12 bit 20
@ clear returns r0 = 0, set with r12 & 0x70000 nonzero returns r1 = (NOT
@ (r12<<15))<<1, set with r12 & 0x70000 zero writes the APSR flags N=0 Z=0 C=1
@ V=1 (r0 = 0x30000000 merged into CPSR bits 31..28, msr CPSR_f at 08046248)
@ and returns.
@ Called from 080444ba and 080444d4.
@ ----------------------------------------------------------------------------
	.section .text.double_scale_by_pow2,"ax",%progbits
	.global double_scale_by_pow2
	.thumb_func
	.type double_scale_by_pow2, %function
double_scale_by_pow2:
	mov.w	r12, #0xff
	orr	r12, r12, #0x700
	ands.w	r3, r12, r1, lsr #20
	itt	ne
	eorsne.w	r12, r12, r3
	cmpne	r12, r2
	ittt	gt
	cmngt	r2, r3
	addgt.w	r1, r1, r2, lsl #20
	bxgt	lr
	cmp	r3, #0
	beq.n	.L08046206
	cmp.w	r12, #0
	beq.n	.L08046210
	and	r1, r1, #0x80000000
	cmp	r2, #0
	itt	ge
	orrge	r1, r1, #0x70000000
	orrge	r1, r1, #0xff00000
	mov.w	r0, #0
	bx	lr
.L08046206:
	and	r1, r1, #0x80000000
	mov.w	r0, #0
	bx	lr
.L08046210:
	orrs.w	r3, r0, r1, lsl #12
	mov.w	r12, #0x9b
	it	ne
	orrne	r12, r12, #0x4000000
	bne.w	L_080450fc
	bx	lr
	.global L_08046224
	.thumb_func
L_08046224:
	tst.w	r12, #0x100000
	beq.n	.L0804624e
	tst.w	r12, #0x70000
	beq.n	.L08046238
	mvn.w	r1, r12, lsl #15
	lsls	r1, r1, #1
	bx	lr
.L08046238:
	mov.w	r0, #0x30000000
	mrs	r2, apsr
	bic	r2, r2, #0xf0000000
	orr.w	r2, r2, r0
	msr	apsr_nzcvq, r2
	bx	lr
.L0804624e:
	mov.w	r0, #0
	bx	lr
