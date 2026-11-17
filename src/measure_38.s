@ measure_38.s - measure module: fn_0803b2f8 (64-bit scaled accumulator update) and fir_filter_rows (16-tap FIR over byte rows)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0803b2f8 - scaled 64-bit accumulator update.
@ Param r0:r1 = signed 64-bit integer (low:high); r2 and r3 are not parameters
@ (r2 is reloaded at 0x0803b30c and r3 at 0x0803b318 before any use).
@ idx = byte 0x20000125 (0x200000f8 + 0x2d).
@ Scaling: i64_to_double (08045538) converts r0:r1 to a double, double_pow
@ (080438e0) is called with d0 = 10.0 (constant at 0x0803b6d0) and
@ d1 = u32_to_double (080455da) of (idx/3); double_mul (0804577c) multiplies that
@ double_pow result by the converted value, double_to_i64 (08046020) converts
@ the product to a signed 64-bit integer, which is multiplied by the byte
@ 0x080465c8[idx%3].
@ The 64-bit result is added to 0x20000118/0x2000011c and, if byte 0x20000126
@ == 0, also to 0x20000ec8, 0x20000ed0, 0x20000ee0 and 0x20000ee8 (64-bit adds
@ with carry).
@ Then divide_s64 (08008732) divides 0x20000118 by
@ int64(double_pow(10.0, double(idx/3)) * double(0x080465c8[idx%3])) and the
@ remainder returned in r2:r3 is subtracted from 0x20000118.
@ When byte 0x20000126 != 0: the value is compared as a double with the limit
@ 150.0 (0x4062c000 high word, constant at 0x0803b818) times 10^(idx/3) times
@ the table byte using double_lt (08045e0c), and with -150.0 (0xc062c000 high
@ word, constant at 0x0803b820) times the same factor using double_gt
@ (08045de2); it is replaced by the limit converted to int64 when the compare
@ reports it outside; the result is stored to 0x20000118.
@ Then 0x20000118 is divided by double_pow(10.0, double(idx/3)) with
@ double_div (08045124) and by the table byte with divide_s64, clamped to
@ -0x96..0x96 (0xffffff6a bound at 0x0803b620, 0x96 at 0x0803b69e), stored as
@ halfword to 0x20000112; 300 is stored as halfword to 0x20000120 and the
@ function returns 300 if 0x20000126 != 0.
@ Otherwise, if the 64-bit value at 0x20000f00/0x20000f04 is >= 10: takes
@ 0x20000ec8/ed0, or 0x20000ee0/ee8 when 0x20000eb8 < 4 and not (== 3 with
@ 0x20000eb6 != 3); divides each by 10^(idx/3) (double_div) and by the table
@ byte (divide_s64) giving Y1 (first) and Y2 (second); if Y1 > 151 or Y2 < -150
@ both 0x20000eac and 0x20000eae are cleared to 0, otherwise
@ 0x20000eac = max(Y1,-150)+0x96 and 0x20000eae = min(Y2,151) - max(Y1,-150);
@ if the 64-bit value at 0x20000f00/0x20000f04 is below 10 both are cleared to
@ 0. The function returns 300 only on that path; on the other exits
@ (0x0803b6c6, 0x0803b800) r0 is not loaded with a result before the return at
@ 0x0803b80c. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0803b2f8,"ax",%progbits
	.global fn_0803b2f8
	.thumb_func
	.type fn_0803b2f8, %function
fn_0803b2f8:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #4
	vpush {d8, d9}
	sub sp, #0x10
	movw r10, #0xf8
	movt r10, #0x2000
	ldrb.w r2, [r10, #0x2d]
	movw r8, #0xaaab
	movt r8, #0xaaaa
	umull r2, r3, r2, r8
	mov r5, r0
	lsrs r0, r3, #1
	mov r4, r1
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0803b6d0
	bl double_pow
	vmov.f32 s16, s0
	mov r0, r5
	mov r1, r4
	vmov.f32 s17, s1
	bl i64_to_double
	mov r2, r0
	mov r3, r1
	vmov r0, r1, d8
	bl double_mul
	bl double_to_i64
	ldrb.w r3, [r10, #0x2d]
	movw r9, #:lower16:d_080465c8
	uxtb r2, r3
	umull r2, r7, r2, r8
	lsrs r2, r7, #1
	sub.w r7, r2, r2, lsl #2
	add r3, r7
	uxtb r3, r3
	movt r9, #:upper16:d_080465c8
	ldrb.w r3, [r9, r3]
	ldrd r6, r5, [r10, #0x20]
	umull r0, r7, r3, r0
	mla r1, r3, r1, r7
	ldrb.w r7, [r10, #0x2e]
	adds r3, r0, r6
	adc.w r6, r1, r5
	strd r3, r6, [r10, #0x20]
	cbnz r7, .L0803b3de
	ldr.w r3, [r10, #0xdd0]
	ldr.w r7, [r10, #0xdd4]
	ldr.w r6, [r10, #0xdd8]
	adds r3, r3, r0
	ldr.w r5, [r10, #0xddc]
	adcs r7, r1
	str.w r3, [r10, #0xdd0]
	ldr.w r3, [r10, #0xde8]
	adds r6, r6, r0
	str.w r7, [r10, #0xdd4]
	ldr.w r7, [r10, #0xdec]
	adcs r5, r1
	adds r3, r3, r0
	adcs r7, r1
	str.w r3, [r10, #0xde8]
	ldr.w r3, [r10, #0xdf0]
	str.w r7, [r10, #0xdec]
	ldr.w r7, [r10, #0xdf4]
	adds r0, r0, r3
	adcs r1, r7
	str.w r6, [r10, #0xdd8]
	str.w r5, [r10, #0xddc]
	str.w r0, [r10, #0xdf0]
	str.w r1, [r10, #0xdf4]
.L0803b3de:
	uxtb r0, r2
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0803b6d0
	bl double_pow
	ldrb.w r11, [r10, #0x2d]
	vmov.f32 s16, s0
	uxtb.w r0, r11
	umull r0, r1, r0, r8
	lsrs r6, r1, #1
	sub.w r0, r6, r6, lsl #2
	add r0, r11
	uxtb r0, r0
	ldrb.w r0, [r9, r0]
	vmov.f32 s17, s1
	bl u32_to_double
	mov r2, r0
	mov r3, r1
	vmov r0, r1, d8
	bl double_mul
	bl double_to_i64
	ldrd r4, r5, [r10, #0x20]
	mov r2, r0
	mov r3, r1
	mov r0, r4
	mov r1, r5
	bl divide_s64
	ldrb.w r0, [r10, #0x2e]
	subs r4, r4, r2
	sbcs r5, r3
	cmp r0, #0
	strd r4, r5, [r10, #0x20]
	beq.w .L0803b614
	mov r0, r4
	mov r1, r5
	bl i64_to_double
	str r0, [sp, #0xc]
	uxtb r0, r6
	mov r7, r9
	mov r9, r1
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0803b810
	bl double_pow
	vmov r0, r1, d0
	vldr d0, .L0803b818
	vmov r5, r11, d0
	mov r2, r5
	mov r3, r11
	bl double_mul
	ldrb.w r4, [r10, #0x2d]
	mov r6, r0
	uxtb r2, r4
	umull r2, r3, r2, r8
	lsr.w r8, r3, #1
	sub.w r0, r8, r8, lsl #2
	add r0, r4
	uxtb r0, r0
	ldrb r0, [r7, r0]
	mov r7, r1
	bl u32_to_double
	mov r2, r0
	mov r3, r1
	mov r0, r6
	mov r1, r7
	bl double_mul
	ldr r2, [sp, #0xc]
	mov r3, r9
	bl double_lt
	cbz r0, .L0803b516
	uxtb.w r0, r8
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0803b810
	bl double_pow
	vmov r0, r1, d0
	mov r2, r5
	mov r3, r11
	bl double_mul
	ldrb.w r4, [r10, #0x2d]
	movw r8, #0xaaab
	movt r8, #0xaaaa
	umull r2, r3, r4, r8
	mov r6, r0
	lsrs r0, r3, #1
	add.w r0, r0, r0, lsl #1
	movw r7, #:lower16:d_080465c8
	subs r0, r4, r0
	movt r7, #:upper16:d_080465c8
	ldrb r0, [r7, r0]
	mov r5, r1
	bl u32_to_double
	mov r2, r0
	mov r3, r1
	mov r0, r6
	mov r1, r5
	bl double_mul
	bl double_to_i64
	mov r5, r8
	mov r6, r7
	strd r0, r1, [r10, #0x20]
	b.n .L0803b52a
.L0803b516:
	ldrd r0, r1, [r10, #0x20]
	movw r5, #0xaaab
	movw r6, #:lower16:d_080465c8
	movt r5, #0xaaaa
	movt r6, #:upper16:d_080465c8
.L0803b52a:
	bl i64_to_double
	umull r2, r3, r4, r5
	mov r9, r0
	lsrs r0, r3, #1
	str r1, [sp, #0xc]
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0803b810
	bl double_pow
	ldrb.w r11, [r10, #0x2d]
	vmov.f32 s16, s0
	uxtb.w r0, r11
	umull r0, r1, r0, r5
	lsr.w r8, r1, #1
	sub.w r0, r8, r8, lsl #2
	add r0, r11
	uxtb r0, r0
	ldrb r0, [r6, r0]
	vmov.f32 s17, s1
	bl u32_to_double
	vldr d0, .L0803b820
	mov r4, r0
	vmov r7, r6, d0
	mov r5, r1
	vmov r0, r1, d8
	mov r2, r7
	mov r3, r6
	bl double_mul
	mov r2, r4
	mov r3, r5
	bl double_mul
	ldr r3, [sp, #0xc]
	mov r2, r9
	bl double_gt
	cbz r0, .L0803b600
	uxtb.w r0, r8
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0803b810
	bl double_pow
	vmov r0, r1, d0
	mov r2, r7
	mov r3, r6
	bl double_mul
	ldrb.w r11, [r10, #0x2d]
	movw r8, #0xaaab
	movt r8, #0xaaaa
	umull r2, r3, r11, r8
	mov r4, r0
	lsrs r0, r3, #1
	add.w r0, r0, r0, lsl #1
	movw r9, #:lower16:d_080465c8
	sub.w r0, r11, r0
	movt r9, #:upper16:d_080465c8
	ldrb.w r0, [r9, r0]
	mov r5, r1
	bl u32_to_double
	mov r2, r0
	mov r3, r1
	mov r0, r4
	mov r1, r5
	bl double_mul
	bl double_to_i64
	mov r4, r0
	mov r5, r1
	strd r4, r5, [r10, #0x20]
	b.n .L0803b614
.L0803b600:
	ldrd r4, r5, [r10, #0x20]
	movw r8, #0xaaab
	movw r9, #:lower16:d_080465c8
	movt r8, #0xaaaa
	movt r9, #:upper16:d_080465c8
.L0803b614:
	umull r0, r1, r11, r8
	lsrs r0, r1, #1
	mov r11, r8
	mov.w r8, #0xffffffff
	mvn r7, #0x95
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0803b810
	bl double_pow
	vmov.f32 s16, s0
	mov r0, r4
	mov r1, r5
	vmov.f32 s17, s1
	bl i64_to_double
	vmov r2, r3, d8
	bl double_div
	bl double_to_i64
	ldrb.w r2, [r10, #0x2d]
	ldrb.w r4, [r10, #0x2e]
	uxtb r3, r2
	umull r3, r6, r3, r11
	lsrs r5, r6, #1
	sub.w r3, r5, r5, lsl #2
	add r2, r3
	uxtb r2, r2
	ldrb.w r2, [r9, r2]
	movs r3, #0
	movs r6, #0
	bl divide_s64
	subs r2, r7, r0
	sbcs.w r2, r8, r1
	mov.w r2, #0
	it lt
	movlt r2, #1
	cmp r2, #0
	itt eq
	moveq r1, r8
	moveq r0, r7
	subs.w r2, r0, #0x96
	sbcs r1, r1, #0
	mov.w r1, #0
	it lt
	movlt r1, #1
	cmp r1, #0
	it eq
	moveq r0, #0x96
	strh.w r0, [r10, #0x1a]
	mov.w r0, #0x12c
	cmp r4, #0
	strh.w r0, [r10, #0x28]
	bne.w .L0803b804
	ldr.w r0, [r10, #0xe08]
	ldr.w r1, [r10, #0xe0c]
	rsbs.w r0, r0, #9
	sbcs.w r0, r6, r1
	bcc.n .L0803b6d8
	movs r5, #0
.L0803b6c6:
	strh.w r5, [r10, #0xdb4]
	b.n .L0803b800
	.short 0xbf00	@ padding
	.short 0xbf00	@ padding
.L0803b6d0:
	.word 0x00000000	@ double 10.0 (0x4024000000000000), low word
	.word 0x40240000	@ high word
.L0803b6d8:
	ldrb.w r0, [r10, #0xdc0]
	ldr.w r6, [r10, #0xdd0]
	ldr.w r4, [r10, #0xdd4]
	ldr.w r1, [r10, #0xdd8]
	ldr.w r2, [r10, #0xddc]
	cmp r0, #3
	bhi.n .L0803b70a
	bne.n .L0803b6fa
	ldrb.w r0, [r10, #0xdbe]
	cmp r0, #3
	bne.n .L0803b70a
.L0803b6fa:
	ldr.w r6, [r10, #0xde8]
	ldr.w r4, [r10, #0xdec]
	ldr.w r1, [r10, #0xdf0]
	ldr.w r2, [r10, #0xdf4]
.L0803b70a:
	uxtb r0, r5
	strd r1, r2, [sp, #8]
	bl u32_to_double
	vldr d8, .L0803b810
	vmov d1, r0, r1
	vmov.f32 s0, s16
	vmov.f32 s1, s17
	bl double_pow
	vmov.f32 s18, s0
	mov r0, r6
	mov r1, r4
	vmov.f32 s19, s1
	bl i64_to_double
	vmov r2, r3, d9
	bl double_div
	bl double_to_i64
	ldrb.w r2, [r10, #0x2d]
	movs r5, #0
	uxtb r3, r2
	umull r3, r6, r3, r11
	lsrs r4, r6, #1
	sub.w r3, r4, r4, lsl #2
	add r2, r3
	uxtb r2, r2
	ldrb.w r2, [r9, r2]
	movs r3, #0
	bl divide_s64
	mov r6, r0
	mov r0, r4
	str r1, [sp, #4]
	bl u32_to_double
	vmov d1, r0, r1
	vmov.f32 s0, s16
	vmov.f32 s1, s17
	bl double_pow
	ldrd r0, r1, [sp, #8]
	vmov.f32 s16, s0
	vmov.f32 s17, s1
	bl i64_to_double
	vmov r2, r3, d8
	bl double_div
	bl double_to_i64
	ldrb.w r2, [r10, #0x2d]
	umull r3, r4, r2, r11
	lsrs r3, r4, #1
	add.w r3, r3, r3, lsl #1
	subs r2, r2, r3
	ldrb.w r2, [r9, r2]
	movs r3, #0
	bl divide_s64
	ldr r3, [sp, #4]
	rsbs.w r2, r6, #0x97
	sbcs.w r2, r5, r3
	blt.w .L0803b6c6
	subs r2, r0, r7
	sbcs.w r2, r1, r8
	blt.w .L0803b6c6
	subs r2, r7, r6
	sbcs.w r2, r8, r3
	mov.w r3, #0
	it lt
	movlt r3, #1
	cmp r3, #0
	it ne
	movne r7, r6
	add.w r3, r7, #0x96
	strh.w r3, [r10, #0xdb4]
	subs.w r3, r0, #0x97
	mov.w r2, #0
	sbcs r1, r1, #0
	it lt
	movlt r2, #1
	cmp r2, #0
	it eq
	moveq r0, #0x97
	subs r5, r0, r7
.L0803b800:
	strh.w r5, [r10, #0xdb6]
.L0803b804:
	add sp, #0x10
	vpop {d8, d9}
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803b810:
	.word 0x00000000	@ double 10.0 (0x4024000000000000), low word
	.word 0x40240000	@ high word
.L0803b818:
	.word 0x00000000	@ double 150.0 (0x4062c00000000000), low word
	.word 0x4062c000	@ high word
.L0803b820:
	.word 0x00000000	@ double -150.0 (0xc062c00000000000), low word
	.word 0xc062c000	@ high word

@ ----------------------------------------------------------------------------
@ fir_filter_rows - 16-tap FIR over a byte buffer using fixed coefficient rows.
@ Params: r0 = output byte buffer, r1 = input byte buffer, r2 = input length,
@ r3 = row count; no return value.
@ Computes a row offset from r3 as the sum of the values 2, 4, 5, 8, 10, 0x14,
@ 0x19, 0x28, 0x32, 0x50 for each of those numbers that r3 exceeds (0x50 only
@ when r2 > 0x10) and uses 64-byte coefficient rows (16 signed words each) at
@ 0x080466e0 + offset*0x40.
@ If r2 > 0x10: for each position i from 0 to r2-0x11 and each of the r3 rows it
@ sums the 16 products coef[k]*in[i+k] in 64 bits and stores one byte at
@ out[i*r3+row]: 0 if the sum is negative, 0xff if it exceeds 0x7fffff, else
@ (sum>>15)&0xff.
@ If r3 == 0 only a counting loop with no stores runs; if r2 <= 0x10 nothing
@ happens.
@ ----------------------------------------------------------------------------
	.section .text.fir_filter_rows,"ax",%progbits
	.global fir_filter_rows
	.thumb_func
	.type fir_filter_rows, %function
fir_filter_rows:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x50
	movs r7, #0
	cmp r3, #2
	it hi
	movhi r7, #1
	lsls r7, r7, #1
	cmp r3, #4
	it hi
	addhi r7, #4
	cmp r3, #5
	it hi
	addhi r7, #5
	cmp r3, #8
	it hi
	addhi r7, #8
	cmp r3, #0xa
	it hi
	addhi r7, #0xa
	cmp r3, #0x14
	it hi
	addhi r7, #0x14
	cmp r3, #0x19
	it hi
	addhi r7, #0x19
	cmp r3, #0x28
	it hi
	addhi r7, #0x28
	cmp r3, #0x32
	it hi
	addhi r7, #0x32
	cmp r2, #0x11
	str r0, [sp, #8]
	bcc.w .L0803d7f0
	cmp r3, #0x50
	it hi
	addhi r7, #0x50
	cmp r3, #0
	sub.w r5, r2, #0x10
	beq.w .L0803d7f6
	lsls r2, r3, #6
	str r2, [sp, #0]
	movw r2, #:lower16:d_080466e0
	uxth r0, r7
	movt r2, #:upper16:d_080466e0
	add.w r2, r2, r0, lsl #6
	movs r0, #0
	movs r6, #0
	str r5, [sp, #4]
.L0803d644:
	uxth r3, r0
	str r3, [sp, #0x48]
	adds r3, r0, #3
	adds r5, r0, #2
	str r3, [sp, #0x4c]
	uxth.w r10, r5
	ldr r5, [sp, #0x4c]
	adds r3, r0, #4
	str r3, [sp, #0x3c]
	uxth r5, r5
	str r5, [sp, #0x40]
	ldr r5, [sp, #0x3c]
	adds r3, r0, #5
	str r3, [sp, #0x38]
	uxth r5, r5
	str r5, [sp, #0x3c]
	ldr r5, [sp, #0x38]
	adds r3, r0, #6
	str r3, [sp, #0x34]
	uxth r5, r5
	str r5, [sp, #0x38]
	ldr r5, [sp, #0x34]
	adds r3, r0, #7
	str r3, [sp, #0x30]
	uxth r5, r5
	str r5, [sp, #0x34]
	ldr r5, [sp, #0x30]
	add.w r11, r0, #8
	uxth r5, r5
	add.w r9, r0, #9
	add.w r4, r0, #0xc
	add.w r3, r0, #0xe
	str r5, [sp, #0x30]
	uxth.w r5, r11
	add.w r8, r0, #0xa
	add.w r12, r0, #0xf
	str r5, [sp, #0x2c]
	uxth.w r5, r9
	uxth r4, r4
	uxth r3, r3
	add.w r7, r0, #0xb
	add.w lr, r0, #0xd
	adds r0, #1
	str.w r10, [sp, #0x44]
	str r5, [sp, #0x28]
	uxth.w r5, r8
	str r4, [sp, #0x1c]
	str r3, [sp, #0x14]
	uxth.w r3, r12
	ldr.w r10, [sp, #8]
	ldr r4, [sp, #0]
	str r5, [sp, #0x24]
	uxth r5, r7
	uxth.w r7, lr
	strd r0, r3, [sp, #0xc]
	uxth r0, r0
	mov.w r12, #0
	str r5, [sp, #0x20]
	str r7, [sp, #0x18]
	str r0, [sp, #0x4c]
.L0803d6e0:
	ldr r0, [sp, #0x48]
	ldr.w r7, [r2, r12]
	ldrb r0, [r1, r0]
	add.w r9, r2, r12
	smull r8, lr, r7, r0
	ldr r0, [sp, #0x4c]
	ldrd r7, r11, [r9, #4]
	ldrb r0, [r1, r0]
	ldr r5, [sp, #0x38]
	smlal r8, lr, r7, r0
	ldr r0, [sp, #0x44]
	ldr.w r7, [r9, #0xc]
	ldrb r0, [r1, r0]
	ldr.w r3, [r9, #0x10]
	smlal r8, lr, r11, r0
	ldr r0, [sp, #0x40]
	add.w r12, r12, #0x40
	ldrb r0, [r1, r0]
	smlal r8, lr, r7, r0
	ldr r0, [sp, #0x3c]
	ldrb r7, [r1, r5]
	ldrb r0, [r1, r0]
	ldr.w r5, [r9, #0x14]
	smlal r8, lr, r3, r0
	ldr r0, [sp, #0x34]
	smlal r8, lr, r5, r7
	ldr r5, [sp, #0x30]
	ldrb r0, [r1, r0]
	ldr.w r3, [r9, #0x18]
	ldrb r5, [r1, r5]
	ldr.w r7, [r9, #0x1c]
	smlal r8, lr, r3, r0
	ldr r0, [sp, #0x2c]
	smlal r8, lr, r7, r5
	ldr r5, [sp, #0x28]
	ldrb r0, [r1, r0]
	ldr.w r3, [r9, #0x20]
	ldrb r5, [r1, r5]
	ldr.w r7, [r9, #0x24]
	smlal r8, lr, r3, r0
	ldr r0, [sp, #0x24]
	smlal r8, lr, r7, r5
	ldr r5, [sp, #0x20]
	ldrb r0, [r1, r0]
	ldr.w r3, [r9, #0x28]
	ldrb r5, [r1, r5]
	ldr.w r7, [r9, #0x2c]
	smlal r8, lr, r3, r0
	ldr r0, [sp, #0x1c]
	smlal r8, lr, r7, r5
	ldr r5, [sp, #0x18]
	ldrb r0, [r1, r0]
	ldr.w r3, [r9, #0x30]
	ldrb r5, [r1, r5]
	ldr.w r7, [r9, #0x34]
	smlal r8, lr, r3, r0
	ldr r0, [sp, #0x14]
	smlal r8, lr, r7, r5
	ldr r5, [sp, #0x10]
	ldrb r0, [r1, r0]
	ldr.w r3, [r9, #0x38]
	ldrb r5, [r1, r5]
	ldr.w r7, [r9, #0x3c]
	smlal r8, lr, r3, r0
	movw r0, #0xffff
	smlal r8, lr, r7, r5
	movt r0, #0x7f
	subs.w r0, r0, r8
	mov.w r0, #0
	sbcs.w r0, r0, lr
	mov.w r0, #0
	it lt
	movlt r0, #1
	cmp.w lr, #0
	lsr.w r3, r8, #0xf
	it mi
	movmi r3, #0
	cmp r0, #0
	it ne
	movne.w r3, #0xffffffff
	uxth r0, r6
	cmp r4, r12
	add.w r6, r6, #1
	strb.w r3, [r10, r0]
	bne.w .L0803d6e0
	ldr r5, [sp, #4]
	ldr r0, [sp, #0x4c]
	cmp r5, r0
	ldr r0, [sp, #0xc]
	bgt.w .L0803d644
.L0803d7f0:
	add sp, #0x50
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803d7f6:
	movs r0, #0
.L0803d7f8:
	orr r1, r0, #1
	uxth r1, r1
	cmp r5, r1
	ble.n .L0803d7f0
	orr r1, r0, #2
	uxth r1, r1
	cmp r5, r1
	ble.n .L0803d7f0
	orr r1, r0, #3
	uxth r1, r1
	cmp r5, r1
	ble.n .L0803d7f0
	adds r0, #4
	uxth r1, r0
	cmp r5, r1
	bgt.n .L0803d7f8
	b.n .L0803d7f0
