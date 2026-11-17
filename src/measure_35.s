@ measure_35.s - compute_math_trace, part 1 of 2 (the second part is included at the end of this file)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ compute_math_trace - builds a 301-sample math trace from the two channel buffers.
@ No parameters, no return value.
@ If byte 0x2000012d is 0, or byte 0x2000010c is 0, or byte 0x2000012c is non-zero:
@ releases the buffer pointer at word 0x20000130 when it is non-zero (same release
@ test as 0x080251e4: function pointer 0x20001070 when byte 0x20001080 is 0, else
@ table 0x2000107c/0x20001078 with zero_bytes 0x080082bc) and stores 0 there.
@ Otherwise allocates 0x12d bytes with alloc_units_of_32_bytes (0x0803acfc) into word
@ 0x20000130 when it is 0 (returns when that fails) and fills 301 signed bytes
@ k = 0..300 by a switch on byte 0x2000012d (values above 8 leave the buffer
@ unfilled), each result clamped to -100.0 .. 100.0 and truncated to a signed byte.
@ With a = float(byte 0x2000044e[k]) - 128 - s8 0x200000fc and
@ b = float(byte 0x2000057b[k]) - 128 - s8 0x200000fd:
@   case 1: a + b
@   case 2: a + (s8 0x200000fd - (B - 128)) with B = byte 0x2000057b[k]
@   case 3: a * b
@   case 4: a / b (no zero test)
@ Cases 1-4 are unrolled by 4 and end after index 300.
@ Cases 5-8 use one channel only and are unrolled by 7 (43 passes = 301 bytes):
@   case 5: 2*s8 0x200000fc + 128 - byte 0x2000044e[k]
@   case 6: 2*s8 0x200000fd + 128 - byte 0x2000057b[k]
@   case 7: |s8 0x200000fc + 128 - byte 0x2000044e[k]| + s8 0x200000fc
@   case 8: |s8 0x200000fd + 128 - byte 0x2000057b[k]| + s8 0x200000fd
@ Purpose: builds a 301-sample math trace (sum, difference, product, quotient,
@ inverted, absolute value) from the two channel buffers 0x2000044e / 0x2000057b
@ selected by byte 0x2000012d.
@ ----------------------------------------------------------------------------
	.section .text.compute_math_trace,"ax",%progbits
	.global compute_math_trace
	.thumb_func
	.type compute_math_trace, %function
compute_math_trace:
	push {r4, lr}
	movw r4, #0xf8
	movt r4, #0x2000
	ldrb.w r1, [r4, #0x35]
	ldr r0, [r4, #0x38]
	cmp r1, #0
	beq.w .L08027b72
	ldrb r2, [r4, #0x14]
	cmp r2, #0
	beq.w .L08027b72
	ldrb.w r2, [r4, #0x34]
	cmp r2, #0
	bne.w .L08027b72
	cbnz r0, .L0802796e
	movw r0, #0x12d
	bl alloc_units_of_32_bytes
	cmp r0, #0
	str r0, [r4, #0x38]
	beq.w .L08027bae
	ldrb.w r1, [r4, #0x35]
.L0802796e:
	subs r0, r1, #1
	cmp r0, #7
	bhi.w .L08027bae
	tbh [pc, r0, lsl #1]
.Ltbl_0802797a:
	.short (.L0802798a - .Ltbl_0802797a)/2
	.short (.L08027bb0 - .Ltbl_0802797a)/2
	.short (.L08027da0 - .Ltbl_0802797a)/2
	.short (.L08027f86 - .Ltbl_0802797a)/2
	.short (.L0802816e - .Ltbl_0802797a)/2
	.short (.L080283ce - .Ltbl_0802797a)/2
	.short (.L0802863a - .Ltbl_0802797a)/2
	.short (.L080288b6 - .Ltbl_0802797a)/2
.L0802798a:
	vldr s0, .L08027bc0
	vldr s2, .L08027bc4
	vldr s4, .L08027bc8
	movs r0, #0
	b.n .L080279ac
	.short 0xbf00	@ padding
.L0802799c:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r2, s6
	add r1, r0
	strb r2, [r1, #3]
	adds r0, #4
.L080279ac:
	adds r1, r4, r0
	ldrb.w r2, [r1, #0x356]
	ldrb.w r3, [r1, #0x483]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08027a12
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08027a12:
	vcvt.s32.f32 s6, s8
	ldr r3, [r4, #0x38]
	vmov r2, s6
	cmp.w r0, #0x12c
	strb r2, [r3, r0]
	beq.w .L08027bae
	ldrb.w r2, [r1, #0x357]
	ldrb.w r3, [r1, #0x484]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08027a8a
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08027a8a:
	ldr r2, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r2, r0
	strb r3, [r2, #1]
	ldrb.w r2, [r1, #0x358]
	ldrb.w r3, [r1, #0x485]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08027afc
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08027afc:
	ldr r2, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r2, r0
	strb r3, [r2, #2]
	ldrb.w r2, [r1, #0x359]
	ldrb.w r1, [r1, #0x486]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	vsub.f32 s6, s6, s8
	vmov s8, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s8, s8
	vmov s10, r1
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.w .L0802799c
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
	b.n .L0802799c
.L08027b72:
	cmp r0, #0
	it eq
	popeq {r4, pc}
	movw r1, #0x1070
	movt r1, #0x2000
	ldrb r2, [r1, #0x10]
	cbz r2, .L08027ba4
	ldr r2, [r1, #8]
	subs r0, r0, r2
	lsrs r2, r0, #0xa
	cmp r2, #0xae
	bhi.n .L08027baa
	ldr r2, [r1, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L08027baa
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L08027baa
.L08027ba4:
	ldr r1, [r1]
	movs r0, #0
	blx r1
.L08027baa:
	movs r0, #0
	str r0, [r4, #0x38]
.L08027bae:
	pop {r4, pc}
.L08027bb0:
	vldr s0, .L08027bc0
	vldr s2, .L08027bc4
	vldr s4, .L08027bc8
	movs r0, #0
	b.n .L08027bdc
.L08027bc0:
	.word 0xc3000000	@ -128.0
.L08027bc4:
	.word 0x42c80000	@ 100.0
.L08027bc8:
	.word 0xc2c80000	@ -100.0
.L08027bcc:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r2, s6
	add r1, r0
	strb r2, [r1, #3]
	adds r0, #4
.L08027bdc:
	adds r1, r4, r0
	ldrb.w r2, [r1, #0x356]
	ldrb.w r3, [r1, #0x483]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s10, s8
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08027c42
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08027c42:
	vcvt.s32.f32 s6, s8
	ldr r3, [r4, #0x38]
	vmov r2, s6
	cmp.w r0, #0x12c
	strb r2, [r3, r0]
	beq.n .L08027bae
	ldrb.w r2, [r1, #0x357]
	ldrb.w r3, [r1, #0x484]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s10, s8
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08027cb8
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08027cb8:
	ldr r2, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r2, r0
	strb r3, [r2, #1]
	ldrb.w r2, [r1, #0x358]
	ldrb.w r3, [r1, #0x485]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s10, s8
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08027d2a
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08027d2a:
	ldr r2, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r2, r0
	strb r3, [r2, #2]
	ldrb.w r2, [r1, #0x359]
	ldrb.w r1, [r1, #0x486]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	vsub.f32 s6, s6, s8
	vmov s8, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s8, s8
	vmov s10, r1
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s10, s8
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.w .L08027bcc
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
	b.n .L08027bcc
.L08027da0:
	vldr s0, .L08027bc0
	vldr s2, .L08027bc4
	vldr s4, .L08027bc8
	movs r0, #0
	b.n .L08027dc0
.L08027db0:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r2, s6
	add r1, r0
	strb r2, [r1, #3]
	adds r0, #4
.L08027dc0:
	adds r1, r4, r0
	ldrb.w r2, [r1, #0x356]
	ldrb.w r3, [r1, #0x483]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vmul.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08027e26
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08027e26:
	vcvt.s32.f32 s6, s8
	ldr r3, [r4, #0x38]
	vmov r2, s6
	cmp.w r0, #0x12c
	strb r2, [r3, r0]
	beq.w .L08027bae
	ldrb.w r2, [r1, #0x357]
	ldrb.w r3, [r1, #0x484]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vmul.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08027e9e
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08027e9e:
	ldr r2, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r2, r0
	strb r3, [r2, #1]
	ldrb.w r2, [r1, #0x358]
	ldrb.w r3, [r1, #0x485]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vmul.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08027f10
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08027f10:
	ldr r2, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r2, r0
	strb r3, [r2, #2]
	ldrb.w r2, [r1, #0x359]
	ldrb.w r1, [r1, #0x486]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	vsub.f32 s6, s6, s8
	vmov s8, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s8, s8
	vmov s10, r1
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vmul.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.w .L08027db0
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
	b.n .L08027db0
.L08027f86:
	vldr s0, .L08027bc0
	vldr s2, .L08027bc4
	vldr s4, .L08027bc8
	movs r0, #0
	b.n .L08027fa8
	.short 0xbf00	@ padding
.L08027f98:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r2, s6
	add r1, r0
	strb r2, [r1, #3]
	adds r0, #4
.L08027fa8:
	adds r1, r4, r0
	ldrb.w r2, [r1, #0x356]
	ldrb.w r3, [r1, #0x483]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vdiv.f32 s6, s6, s8
	vmov.f32 s8, s2
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	bgt.n .L0802800e
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L0802800e:
	vcvt.s32.f32 s6, s8
	ldr r3, [r4, #0x38]
	vmov r2, s6
	cmp.w r0, #0x12c
	strb r2, [r3, r0]
	beq.w .L08027bae
	ldrb.w r2, [r1, #0x357]
	ldrb.w r3, [r1, #0x484]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vdiv.f32 s6, s6, s8
	vmov.f32 s8, s2
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	bgt.n .L08028086
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08028086:
	ldr r2, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r2, r0
	strb r3, [r2, #1]
	ldrb.w r2, [r1, #0x358]
	ldrb.w r3, [r1, #0x485]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	ldrsb.w r2, [r4, #5]
	vsub.f32 s6, s6, s8
	vmov s8, r3
	vcvt.f32.u32 s8, s8
	vmov s10, r2
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vdiv.f32 s6, s6, s8
	vmov.f32 s8, s2
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	bgt.n .L080280f8
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L080280f8:
	ldr r2, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r2, r0
	strb r3, [r2, #2]
	ldrb.w r2, [r1, #0x359]
	ldrb.w r1, [r1, #0x486]
	vmov s6, r2
	ldrsb.w r2, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r2
	vadd.f32 s6, s6, s0
	vcvt.f32.s32 s8, s8
	vsub.f32 s6, s6, s8
	vmov s8, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s8, s8
	vmov s10, r1
	vadd.f32 s8, s8, s0
	vcvt.f32.s32 s10, s10
	vsub.f32 s8, s8, s10
	vdiv.f32 s6, s6, s8
	vmov.f32 s8, s2
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	bgt.w .L08027f98
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
	b.n .L08027f98
.L0802816e:
	vldr s0, .L080283e4
	vldr s2, .L080283e8
	vldr s4, .L080283ec
	movs r0, #0
	movw r12, #0x12d
	b.n .L0802819a
	.short 0xbf00	@ padding
.L08028184:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	add r1, r0
	adds r0, #7
	vmov r2, s6
	cmp r0, r12
	strb r2, [r1, #6]
	beq.w .L08027bae
.L0802819a:
	adds r2, r4, r0
	ldrb.w r3, [r2, #0x356]
	vmov s6, r3
	ldrsb.w r3, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r3
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L080281e0
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L080281e0:
	vcvt.s32.f32 s6, s8
	ldr r3, [r4, #0x38]
	vmov r1, s6
	strb r1, [r3, r0]
	ldrb.w r1, [r2, #0x357]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08028230
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08028230:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #1]
	ldrb.w r1, [r2, #0x358]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08028282
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08028282:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #2]
	ldrb.w r1, [r2, #0x359]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L080282d4
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L080282d4:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #3]
	ldrb.w r1, [r2, #0x35a]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08028326
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08028326:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #4]
	ldrb.w r1, [r2, #0x35b]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08028378
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08028378:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #5]
	ldrb.w r1, [r2, #0x35c]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.w .L08028184
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
	b.n .L08028184
.L080283ce:
	vldr s0, .L080283e4
	vldr s2, .L080283e8
	vldr s4, .L080283ec
	movs r0, #0
	movw r12, #0x12d
	b.n .L08028406
	.short 0xbf00	@ padding
.L080283e4:
	.word 0x43000000	@ 128.0
.L080283e8:
	.word 0x42c80000	@ 100.0
.L080283ec:
	.word 0xc2c80000	@ -100.0
.L080283f0:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	add r1, r0
	adds r0, #7
	vmov r2, s6
	cmp r0, r12
	strb r2, [r1, #6]
	beq.w .L08027bae
.L08028406:
	adds r2, r4, r0
	ldrb.w r3, [r2, #0x483]
	vmov s6, r3
	ldrsb.w r3, [r4, #5]
	vcvt.f32.u32 s6, s6
	vmov s8, r3
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L0802844c
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L0802844c:
	vcvt.s32.f32 s6, s8
	ldr r3, [r4, #0x38]
	vmov r1, s6
	strb r1, [r3, r0]
	ldrb.w r1, [r2, #0x484]
	vmov s6, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L0802849c
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L0802849c:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #1]
	ldrb.w r1, [r2, #0x485]
	vmov s6, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L080284ee
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L080284ee:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #2]
	ldrb.w r1, [r2, #0x486]
	vmov s6, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08028540
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08028540:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #3]
	ldrb.w r1, [r2, #0x487]
	vmov s6, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08028592
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08028592:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #4]
	ldrb.w r1, [r2, #0x488]
	vmov s6, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L080285e4
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L080285e4:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #5]
	ldrb.w r1, [r2, #0x489]
	vmov s6, r1
	ldrsb.w r1, [r4, #5]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.w .L080283f0
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
	b.n .L080283f0
.L0802863a:
	vldr s0, .L080283e4
	vldr s2, .L080283e8
	vldr s4, .L080283ec
	movs r0, #0
	movw r12, #0x12d
	b.n .L08028666
	.short 0xbf00	@ padding
.L08028650:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	add r1, r0
	adds r0, #7
	vmov r2, s6
	cmp r0, r12
	strb r2, [r1, #6]
	beq.w .L08027bae
.L08028666:
	adds r2, r4, r0
	ldrb.w r3, [r2, #0x356]
	vmov s6, r3
	ldrsb.w r3, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r3
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vabs.f32 s6, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L080286b0
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L080286b0:
	vcvt.s32.f32 s6, s8
	ldr r3, [r4, #0x38]
	vmov r1, s6
	strb r1, [r3, r0]
	ldrb.w r1, [r2, #0x357]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vabs.f32 s6, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08028704
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08028704:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #1]
	ldrb.w r1, [r2, #0x358]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vabs.f32 s6, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L0802875a
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L0802875a:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #2]
	ldrb.w r1, [r2, #0x359]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vabs.f32 s6, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L080287b0
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L080287b0:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #3]
	ldrb.w r1, [r2, #0x35a]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vabs.f32 s6, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L08028806
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L08028806:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #4]
	ldrb.w r1, [r2, #0x35b]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vabs.f32 s6, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L0802885c
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L0802885c:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	vmov r3, s6
	add r1, r0
	strb r3, [r1, #5]
	ldrb.w r1, [r2, #0x35c]
	vmov s6, r1
	ldrsb.w r1, [r4, #4]
	vcvt.f32.u32 s6, s6
	vmov s8, r1
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vabs.f32 s6, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.w .L08028650
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
	b.n .L08028650
.L080288b6:
	vldr s0, .L08028b34
	vldr s2, .L08028b38
	vldr s4, .L08028b3c
	movs r0, #0
	movw r12, #0x12d
	b.n .L080288e2
	.short 0xbf00	@ padding
.L080288cc:
	ldr r1, [r4, #0x38]
	vcvt.s32.f32 s6, s8
	add r1, r0
	adds r0, #7
	vmov r2, s6
	cmp r0, r12
	strb r2, [r1, #6]
	beq.w .L08027bae
.L080288e2:
	adds r2, r4, r0
	ldrb.w r3, [r2, #0x483]
	vmov s6, r3
	ldrsb.w r3, [r4, #5]
	vcvt.f32.u32 s6, s6
	vmov s8, r3
	vsub.f32 s6, s0, s6
	vcvt.f32.s32 s8, s8
	vadd.f32 s6, s8, s6
	vabs.f32 s6, s6
	vadd.f32 s6, s6, s8
	vcmp.f32 s6, s2
	vmrs APSR_nzcv, fpscr
	vmov.f32 s8, s2
	bgt.n .L0802892c
	vcmp.f32 s6, s4
	vmov.f32 s8, s6
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s8, s4
.L0802892c:
	vcvt.s32.f32 s6, s8
	.include "src/parts/compute_math_trace_p2.inc"
