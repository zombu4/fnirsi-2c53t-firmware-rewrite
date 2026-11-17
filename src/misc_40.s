@ misc_40.s - fn_080098e0: scales a float/byte pair, derives a display class and a position pair, and sends three codes to a queue.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_080098e0 - if byte [0x20001035] != 0: value computation and class selection;
@ then a case switch on [0x20001025]; then always sends codes to a queue.
@ Part 1 (only when [0x20001035] != 0):
@   converts the float [0x20001038] with float_to_double (08045d70) and the byte
@   [0x2000103c] with u32_to_double (080455da), and the float [0x20001028] and the
@   byte [0x2000102f] the same way; calls double_pow (080438e0) with the double
@   1000.0 (loaded from 0x08009bf0) and the byte as a double, multiplies with
@   double_mul (0804577c), and combines both products with double_sub (08045b94).
@   Clears [0x2000102f], then up to four times tests |value| against 10000.0
@   (high word 0x40c38800, at 0x08009c00) with double_lt (08045e0c); while that
@   returns 0 it divides by 1000.0 (0x408f4000) with double_div (08045124) and
@   counts in [0x2000102f]. Stores the result as float (double_to_float, 08044f48)
@   in [0x20001028] and sets the class [0x2000102c] to 1 when |v| >= 1000 and
@   class >= 2, to 2 when |v| >= 100 and class >= 3, to 3 when |v| >= 10 and
@   class >= 4.
@ Part 2: switch on [0x20001025] (values above 7 skip it):
@   case 0 with [0x20001027]: 0 sets [0x20001026] = 0 and [0x20001030] = 0xff;
@     1 sets [0x20001026] = [0x2000102e] and [0x20001030] = [0x2000102f] when
@     [0x2000102e] is 1 or 2; 2 sets [0x20001026] = 3 when [0x2000102e] == 2 and
@     [0x20001030] = [0x2000102f] + 2; 3 sets [0x20001026] = 5 and
@     [0x20001030] = [0x2000102f] + 2; values above 3 change nothing; then sends
@     code 0x1b.
@   case 1: [0x20001026] = [0x2000102e] when it is 1 or 2, [0x20001030] = [0x2000102f]
@   case 2: [0x2000102e] == 1 gives 4 and +0, == 2 gives 3 and +2
@   case 3: 5 and +2
@   case 4: 6 and +5
@   case 5: 7 and +9
@   case 6: [0x20001026] = 9 when [0x2000102e] == 2, 8 when == 1,
@     [0x20001030] = [0x2000102f] + 10
@   case 7: 0xb when == 2, 10 when == 1, +10
@ Then always sends 0x1c and 0x1e with queue_send_timeout (08041cf0, timeout -1) to
@ the queue whose handle is at [0x20002d6c]. Purpose beyond this mechanics not
@ determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080098e0,"ax",%progbits
	.global fn_080098e0
	.thumb_func
	.type fn_080098e0, %function
fn_080098e0:
	push.w {r4, r5, r6, r7, r8, r9, r10, lr}
	vpush {d8, d9, d10}
	sub sp, #8
	movw r8, #0xf8
	movt r8, #0x2000                @ r8 = 0x200000f8 (base of the block at 0x20001035..)
	ldrb.w r0, [r8, #0xf3d]
	cmp r0, #0
	beq.w .L08009a9a
	ldr.w r0, [r8, #0xf40]
	bl float_to_double
	mov r4, r0
	ldrb.w r0, [r8, #0xf44]
	mov r5, r1
	bl u32_to_double
	vldr d8, .L08009bf0             @ 1000.0
	vmov d1, r0, r1
	vmov.f32 s0, s16
	vmov.f32 s1, s17
	bl double_pow
	vmov r0, r1, d0
	mov r2, r4
	mov r3, r5
	bl double_mul
	mov r4, r0
	ldr.w r0, [r8, #0xf30]
	mov r5, r1
	bl float_to_double
	mov r6, r0
	ldrb.w r0, [r8, #0xf37]
	mov r7, r1
	bl u32_to_double
	vmov d1, r0, r1
	vmov.f32 s0, s16
	vmov.f32 s1, s17
	bl double_pow
	vmov r0, r1, d0
	mov r2, r6
	mov r3, r7
	bl double_mul
	mov r2, r4
	mov r3, r5
	bl double_sub
	vldr d0, .L08009bf8
	mov r7, r0
	mov r6, r1
	vmov d9, r0, r1
	vmov r0, r1, d0
	vldr d0, .L08009c00             @ 10000.0
	lsr.w r10, r1, #0x1f
	mov r1, r6
	vmov r5, r9, d0
	movs r4, #0
	bfi r1, r10, #0x1f, #0x1
	mov r0, r7
	mov r2, r5
	mov r3, r9
	vmov d10, r7, r1
	strb.w r4, [r8, #0xf37]
	bl double_lt
	cbnz r0, .L080099c2
	movs r4, #1
	vmov r2, r3, d8
	mov r0, r7
	mov r1, r6
	strb.w r4, [r8, #0xf37]
	bl double_div
	vmov d9, r0, r1
	bfi r1, r10, #0x1f, #0x1
	vmov d10, r0, r1
.L080099c2:
	vmov r0, r1, d10
	mov r2, r5
	mov r3, r9
	bl double_lt
	cbnz r0, .L080099ee
	adds r4, #1
	vmov r0, r1, d9
	vmov r2, r3, d8
	strb.w r4, [r8, #0xf37]
	bl double_div
	vmov d9, r0, r1
	bfi r1, r10, #0x1f, #0x1
	vmov d10, r0, r1
.L080099ee:
	vmov r0, r1, d10
	mov r2, r5
	mov r3, r9
	bl double_lt
	cbnz r0, .L08009a1a
	adds r4, #1
	vmov r0, r1, d9
	vmov r2, r3, d8
	strb.w r4, [r8, #0xf37]
	bl double_div
	vmov d9, r0, r1
	bfi r1, r10, #0x1f, #0x1
	vmov d10, r0, r1
.L08009a1a:
	vmov r0, r1, d10
	mov r2, r5
	mov r3, r9
	bl double_lt
	cbnz r0, .L08009a3e
	adds	r0, r4, #1
	strb.w r0, [r8, #0xf37]
	vmov r0, r1, d9
	vmov r2, r3, d8
	bl double_div
	vmov d9, r0, r1
.L08009a3e:
	vmov r0, r1, d9
	bl double_to_float
	bic.w r1, r0, #0x80000000       @ |value|
	vldr s2, .L08009c08             @ 1000.0f
	vmov s0, r1
	ldrb.w r1, [r8, #0xf34]
	vcmp.f32 s0, s2
	vmrs APSR_nzcv, fpscr
	str.w r0, [r8, #0xf30]
	blt.n .L08009a6c
	cmp r1, #1
	bls.n .L08009a6c
	movs r0, #1
	b.n .L08009a96
.L08009a6c:
	vldr s2, .L08009c0c             @ 100.0f
	vcmp.f32 s0, s2
	vmrs APSR_nzcv, fpscr
	blt.n .L08009a82
	cmp r1, #2
	bls.n .L08009a82
	movs r0, #2
	b.n .L08009a96
.L08009a82:
	vmov.f32 s2, #10.0
	vcmp.f32 s0, s2
	vmrs APSR_nzcv, fpscr
	blt.n .L08009a9a
	cmp r1, #4
	blo.n .L08009a9a
	movs r0, #3
.L08009a96:
	strb.w r0, [r8, #0xf34]
.L08009a9a:
	ldrb.w r0, [r8, #0xf2d]
	movw r5, #0x2d6c
	cmp r0, #7
	movt r5, #0x2000
	bhi.w .L08009bba
	tbb [pc, r0]
.Ltbl1:
	.byte (.L08009ab8 - .Ltbl1)/2
	.byte (.L08009ae6 - .Ltbl1)/2
	.byte (.L08009afe - .Ltbl1)/2
	.byte (.L08009b0e - .Ltbl1)/2
	.byte (.L08009ad4 - .Ltbl1)/2
	.byte (.L08009b20 - .Ltbl1)/2
	.byte (.L08009b34 - .Ltbl1)/2
	.byte (.L08009b44 - .Ltbl1)/2
.L08009ab8:
	ldrb.w r0, [r8, #0xf2f]
	cmp r0, #3
	bhi.n .L08009ba6
	movs r1, #5
	tbb [pc, r0]
.Ltbl2:
	.byte (.L08009aca - .Ltbl2)/2
	.byte (.L08009b7a - .Ltbl2)/2
	.byte (.L08009b8e - .Ltbl2)/2
	.byte (.L08009b98 - .Ltbl2)/2
.L08009aca:
	movs r0, #0
	strb.w r0, [r8, #0xf2e]
	movs r0, #0xff
	b.n .L08009ba2
.L08009ad4:
	ldrb.w r1, [r8, #0xf37]
	movs r0, #6
	strb.w r0, [r8, #0xf2e]
	adds	r0, r1, #5
	strb.w r0, [r8, #0xf38]
	b.n .L08009bba
.L08009ae6:
	ldrb.w r0, [r8, #0xf36]
	subs	r1, r0, #1
	cmp r1, #2
	it cc
	strbcc.w r0, [r8, #0xf2e]
	ldrb.w r0, [r8, #0xf37]
	strb.w r0, [r8, #0xf38]
	b.n .L08009bba
.L08009afe:
	ldrb.w r0, [r8, #0xf36]
	cmp r0, #1
	beq.n .L08009b54
	cmp r0, #2
	bne.n .L08009bba
	movs r0, #3
	b.n .L08009b10
.L08009b0e:
	movs r0, #5
.L08009b10:
	ldrb.w r1, [r8, #0xf37]
	strb.w r0, [r8, #0xf2e]
	adds	r0, r1, #2
	strb.w r0, [r8, #0xf38]
	b.n .L08009bba
.L08009b20:
	ldrb.w r1, [r8, #0xf37]
	movs r0, #7
	strb.w r0, [r8, #0xf2e]
	add.w r0, r1, #9
	strb.w r0, [r8, #0xf38]
	b.n .L08009bba
.L08009b34:
	ldrb.w r0, [r8, #0xf36]
	cmp r0, #2
	beq.n .L08009b64
	cmp r0, #1
	bne.n .L08009b6e
	movs r0, #8
	b.n .L08009b6a
.L08009b44:
	ldrb.w r0, [r8, #0xf36]
	cmp r0, #2
	beq.n .L08009b68
	cmp r0, #1
	bne.n .L08009b6e
	movs r0, #0xa
	b.n .L08009b6a
.L08009b54:
	ldrb.w r1, [r8, #0xf37]
	movs r0, #4
	strb.w r0, [r8, #0xf2e]
	strb.w r1, [r8, #0xf38]
	b.n .L08009bba
.L08009b64:
	movs r0, #9
	b.n .L08009b6a
.L08009b68:
	movs r0, #0xb
.L08009b6a:
	strb.w r0, [r8, #0xf2e]
.L08009b6e:
	ldrb.w r0, [r8, #0xf37]
	adds r0, #0xa
	strb.w r0, [r8, #0xf38]
	b.n .L08009bba
.L08009b7a:
	ldrb.w r0, [r8, #0xf36]
	subs	r1, r0, #1
	cmp r1, #2
	it cc
	strbcc.w r0, [r8, #0xf2e]
	ldrb.w r0, [r8, #0xf37]
	b.n .L08009ba2
.L08009b8e:
	ldrb.w r0, [r8, #0xf36]
	cmp r0, #2
	bne.n .L08009b9c
	movs r1, #3
.L08009b98:
	strb.w r1, [r8, #0xf2e]
.L08009b9c:
	ldrb.w r0, [r8, #0xf37]
	adds r0, #2
.L08009ba2:
	strb.w r0, [r8, #0xf38]
.L08009ba6:
	movs r1, #0x1b
	ldr r0, [r5, #0]
	strb.w r1, [sp, #7]
	add.w r1, sp, #7
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L08009bba:
	movs r1, #0x1c
	ldr r0, [r5, #0]
	add.w r4, sp, #7
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x1e
	ldr r0, [r5, #0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	add sp, #8
	vpop {d8, d9, d10}
	pop.w {r4, r5, r6, r7, r8, r9, r10, pc}
	.short 0xbf00                   @ padding
	.short 0xbf00                   @ padding
.L08009bf0:
	.word 0x00000000                @ 1000.0 (double), low word
	.word 0x408f4000                @ high word
.L08009bf8:
	.word 0x00000000                @ 0.0 (double), low word
	.word 0x00000000                @ high word
.L08009c00:
	.word 0x00000000                @ 10000.0 (double), low word
	.word 0x40c38800                @ high word
.L08009c08:
	.word 0x447a0000                @ 1000.0f
.L08009c0c:
	.word 0x42c80000                @ 100.0f
