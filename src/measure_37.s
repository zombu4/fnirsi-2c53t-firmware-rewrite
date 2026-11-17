@ measure_37.s - find_level_crossing: scans the sample buffers for a threshold edge.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ find_level_crossing - scans the sample buffers for a threshold edge and records
@ the edge position and a found flag in 0x20000eb4.
@ No parameters, no return value.
@ step = 1 when byte 0x2000010c is 3 or byte 0x20000125 > 3, else 2.
@ extra = s16 0x2000013e * step when byte 0x2000010f is 2, else 0.
@ first = u16(s16 0x20000112 + extra + 0x9e),
@ end = u16(s16 0x20000112 + step*0x400 + extra - 0xa7).
@ The search runs only when first + 10 < end, positions p = first + 10 .. end - 1.
@ The default result is s16 0x20000112 + 0xa8.
@ Level L = s16 at 0x20000114 (s16 at 0x20000ebe when byte 0x20000126 is 0) + 0x80.
@ The sample at position q is:
@   step 1: byte 0x200006a8 + byte(0x2000010e)*0x400 + (q as a 16-bit value,
@           minus 0x400 when q >= 0x400; no & 0x7fff mask).
@   step 2: index (q as a 16-bit value, minus 0x800 when q >= 0x800; no & 0x7fff
@           mask) >> 1 into 0x200006a8 for even q and 0x20000aa8 for odd q, with
@           byte 0x20000449 subtracted for even q when byte 0x2000010c != 1 and
@           byte 0x20000448 subtracted for odd q when byte 0x2000010c == 1.
@ Direction byte 0x20000110: values 0 and 2 test rising (s[p-1] <= L, s[p] > L and,
@ when byte 0x2000010f != 2, also s[p+1] > L); values 1 and 2 test falling
@ (s[p-1] >= L, s[p] < L and, when byte 0x2000010f != 2, also s[p+1] < L).
@ The first hit sets bit 15 of u16 0x20000eb4 and stops with position p-1.
@ Final store: u16 0x20000eb4 = (u16 0x20000eb4 & 0x8000) | position (bit 15 is
@ not cleared on a miss).
@ ----------------------------------------------------------------------------
	.section .text.find_level_crossing,"ax",%progbits
	.global find_level_crossing
	.thumb_func
	.type find_level_crossing, %function
find_level_crossing:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x1c
	movw r10, #0xf8
	movt r10, #0x2000
	ldrb.w r9, [r10, #0x14]
	ldrb.w r1, [r10, #0x2d]
	sub.w r3, r9, #0x3
	clz r3, r3
	cmp r1, #0x3
	mov.w r1, #0x0
	ldrb.w r11, [r10, #0x17]
	lsr.w r3, r3, #0x5
	it hi
	movhi r1, #0x1
	orrs.w r12, r3, r1
	mov.w r1, #0x2
	it ne
	movne r1, #0x1
	ldrh.w r6, [r10, #0x1a]
	movs r5, #0x0
	ldrh.w r7, [r10, #0x46]
	cmp.w r11, #0x2
	it eq
	muleq r5, r7, r1
	add.w r1, r6, r1, lsl #0xa
	adds r7, r6, r5
	add r1, r5
	sub.w r5, r1, #0xa7
	add.w r1, r7, #0x9e
	movs r7, #0xa
	uxtah r4, r7, r1
	uxth r7, r5
	movs r2, #0x0
	cmp r4, r7
	add.w r5, r6, #0xa8
	bcs.w .L0802937c
	ldrb.w r6, [r10, #0x2e]
	add.w r4, r10, #0x1c
	str r5, [sp, #0x0]
	ldrb.w r5, [r10, #0x16]
	cmp r6, #0x0
	it eq
	addweq r4, r10, #0xdc6
	ldrb.w r3, [r10, #0x351]
	ldrh r6, [r4, #0x0]
	ldrb.w r4, [r10, #0x18]
	str r3, [sp, #0x14]
	ldrb.w r3, [r10, #0x350]
	rsbs r7, r7, #0
	uxth r1, r1
	adds r6, #0x80
	str r7, [sp, #0x18]
	movw r7, #0xf80a
	str r3, [sp, #0x10]
	sxth r6, r6
	lsls r3, r5, #0xa
	subs r0, r4, #0x1
	add r7, r1
	orr lr, r4, #0x2
	str r3, [sp, #0xc]
	strd r9, r0, [sp, #0x4]
	b.n .L08028ec2
.L08028ea0:
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r4, [sp, #0x14]
.L08028eaa:
	subs r4, r1, r4
.L08028eac:
	uxtb r1, r4
	cmp r6, r1
	bgt.w .L0802939e
.L08028eb4:
	ldr r1, [sp, #0x18]
	adds r7, #0x1
	add r1, r7
	cmp.w r1, #0xf800
	beq.w .L0802937a
.L08028ec2:
	cmp.w lr, #0x2
	sub.w r8, r7, #0xf800
	bne.w .L08029128
	sub.w r5, r8, #0x1
	cmp.w r11, #0x2
	uxth r1, r5
	bne.n .L08028f18
	cmp.w r12, #0x0
	beq.n .L08028f76
	cmp.w r2, r1, lsr #0xa
	mov r1, r5
	it ne
	subwne r1, r8, #0x401
	uxtah r1, r3, r1
	add r1, r10
	ldrb.w r1, [r1, #0x5b0]
	cmp r1, r6
	bgt.w .L08029128
	uxth.w r1, r8
	cmp.w r2, r1, lsr #0xa
	mov r1, r8
	it ne
	addne.w r1, r7, #0x400
	uxtah r1, r3, r1
	add r1, r10
	ldrb.w r9, [r1, #0x5b0]
	b.n .L080290ae
.L08028f18:
	cmp.w r12, #0x0
	beq.n .L08028f9e
	cmp.w r2, r1, lsr #0xa
	mov r1, r5
	it ne
	subwne r1, r8, #0x401
	uxtah r1, r3, r1
	add r1, r10
	ldrb.w r1, [r1, #0x5b0]
	cmp r1, r6
	bgt.w .L08029128
	uxth.w r1, r8
	cmp.w r2, r1, lsr #0xa
	mov r1, r8
	it ne
	addne.w r1, r7, #0x400
	uxtah r1, r3, r1
	add r1, r10
	ldrb.w r1, [r1, #0x5b0]
	cmp r6, r1
	bge.w .L08029128
	add.w r1, r8, #0x1
	uxth r4, r1
	cmp.w r2, r4, lsr #0xa
	it ne
	subwne r1, r8, #0x3ff
	uxtah r1, r3, r1
	add r1, r10
	ldrb.w r4, [r1, #0x5b0]
	b.n .L08029120
.L08028f76:
	cmp.w r2, r1, lsr #0xb
	mov r1, r5
	it ne
	subwne r1, r8, #0x801
	uxth r4, r1
	and r1, r1, #0x1
	cmp.w r9, #0x1
	lsr.w r4, r4, #0x1
	bne.n .L08028fc6
	cbnz r1, .L08028fe2
	add.w r1, r10, r4
	ldrb.w r4, [r1, #0x5b0]
	b.n .L08029006
.L08028f9e:
	cmp.w r2, r1, lsr #0xb
	mov r1, r5
	it ne
	subwne r1, r8, #0x801
	uxth r4, r1
	and r1, r1, #0x1
	cmp.w r9, #0x1
	lsr.w r4, r4, #0x1
	bne.n .L08028fd4
	cbnz r1, .L08028ff0
	add.w r1, r10, r4
	ldrb.w r4, [r1, #0x5b0]
	b.n .L0802903e
.L08028fc6:
	cbnz r1, .L08028ffe
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r4, [sp, #0x14]
	b.n .L08028fec
.L08028fd4:
	cbnz r1, .L08029036
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r4, [sp, #0x14]
	b.n .L08028ffa
.L08028fe2:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r4, [sp, #0x10]
.L08028fec:
	subs r4, r1, r4
	b.n .L08029006
.L08028ff0:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r4, [sp, #0x10]
.L08028ffa:
	subs r4, r1, r4
	b.n .L0802903e
.L08028ffe:
	add.w r1, r4, r10
	ldrb.w r4, [r1, #0x9b0]
.L08029006:
	uxtb r1, r4
	cmp r1, r6
	bgt.w .L08029128
	uxth.w r1, r8
	mov r4, r8
	cmp.w r2, r1, lsr #0xb
	it ne
	movne r4, r7
	and r1, r4, #0x1
	cmp.w r9, #0x1
	ubfx r4, r4, #0x1, #0xf
	bne.n .L0802906c
	cbnz r1, .L08029088
	add.w r1, r10, r4
	ldrb.w r9, [r1, #0x5b0]
	b.n .L080290ae
.L08029036:
	add.w r1, r4, r10
	ldrb.w r4, [r1, #0x9b0]
.L0802903e:
	uxtb r1, r4
	cmp r1, r6
	bgt.n .L08029128
	uxth.w r1, r8
	mov r4, r8
	cmp.w r2, r1, lsr #0xb
	it ne
	movne r4, r7
	and r1, r4, #0x1
	cmp.w r9, #0x1
	ubfx r4, r4, #0x1, #0xf
	bne.n .L0802907a
	cbnz r1, .L08029098
	add.w r1, r10, r4
	ldrb.w r4, [r1, #0x5b0]
	b.n .L080290ca
.L0802906c:
	cbnz r1, .L080290a6
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r2, [sp, #0x14]
	b.n .L08029092
.L0802907a:
	cbnz r1, .L080290c2
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r4, [sp, #0x14]
	b.n .L080290a2
.L08029088:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r2, [sp, #0x10]
.L08029092:
	sub.w r9, r1, r2
	b.n .L080290ae
.L08029098:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r4, [sp, #0x10]
.L080290a2:
	subs r4, r1, r4
	b.n .L080290ca
.L080290a6:
	add.w r1, r4, r10
	ldrb.w r9, [r1, #0x9b0]
.L080290ae:
	uxtb.w r1, r9
	ldr r3, [sp, #0xc]
	ldrd r9, r0, [sp, #0x4]
	cmp r6, r1
	mov.w r2, #0x0
	bge.n .L08029128
	b.n .L08029390
.L080290c2:
	add.w r1, r4, r10
	ldrb.w r4, [r1, #0x9b0]
.L080290ca:
	uxtb r1, r4
	cmp r1, r6
	ble.n .L08029128
	add.w r1, r8, #0x1
	uxth r4, r1
	cmp.w r2, r4, lsr #0xb
	it ne
	subwne r1, r8, #0x7ff
	uxth r4, r1
	and r1, r1, #0x1
	cmp.w r9, #0x1
	lsr.w r4, r4, #0x1
	bne.n .L080290fc
	cbnz r1, .L0802910a
	add.w r1, r10, r4
	ldrb.w r4, [r1, #0x5b0]
	b.n .L08029120
.L080290fc:
	cbnz r1, .L08029118
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r4, [sp, #0x14]
	b.n .L08029114
.L0802910a:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r4, [sp, #0x10]
.L08029114:
	subs r4, r1, r4
	b.n .L08029120
.L08029118:
	add.w r1, r4, r10
	ldrb.w r4, [r1, #0x9b0]
.L08029120:
	uxtb r1, r4
	cmp r6, r1
	blt.w .L080293ac
.L08029128:
	cmp r0, #0x1
	bhi.w .L08028eb4
	sub.w r5, r8, #0x1
	cmp.w r11, #0x2
	uxth r1, r5
	bne.n .L08029178
	cmp.w r12, #0x0
	beq.n .L080291d6
	cmp.w r2, r1, lsr #0xa
	mov r1, r5
	it ne
	subwne r1, r8, #0x401
	uxtah r1, r3, r1
	add r1, r10
	ldrb.w r1, [r1, #0x5b0]
	cmp r1, r6
	blt.w .L08028eb4
	uxth.w r1, r8
	cmp.w r2, r1, lsr #0xa
	it ne
	addne.w r8, r7, #0x400
	uxtah r1, r3, r8
	add r1, r10
	ldrb.w r4, [r1, #0x5b0]
	b.n .L08028eac
	.byte 0x00, 0xbf	@ padding
.L08029178:
	cmp.w r12, #0x0
	beq.n .L080291fe
	cmp.w r2, r1, lsr #0xa
	mov r1, r5
	it ne
	subwne r1, r8, #0x401
	uxtah r1, r3, r1
	add r1, r10
	ldrb.w r1, [r1, #0x5b0]
	cmp r1, r6
	blt.w .L08028eb4
	uxth.w r1, r8
	cmp.w r2, r1, lsr #0xa
	mov r1, r8
	it ne
	addne.w r1, r7, #0x400
	uxtah r1, r3, r1
	add r1, r10
	ldrb.w r1, [r1, #0x5b0]
	cmp r6, r1
	ble.w .L08028eb4
	add.w r1, r8, #0x1
	uxth r4, r1
	cmp.w r2, r4, lsr #0xa
	it ne
	subwne r1, r8, #0x3ff
	uxtah r1, r3, r1
	add r1, r10
	ldrb.w r4, [r1, #0x5b0]
	b.n .L08029364
.L080291d6:
	cmp.w r2, r1, lsr #0xb
	mov r1, r5
	it ne
	subwne r1, r8, #0x801
	uxth r4, r1
	and r1, r1, #0x1
	cmp.w r9, #0x1
	lsr.w r4, r4, #0x1
	bne.n .L08029226
	cbnz r1, .L08029242
	add.w r1, r10, r4
	ldrb.w r4, [r1, #0x5b0]
	b.n .L08029266
.L080291fe:
	cmp.w r2, r1, lsr #0xb
	mov r1, r5
	it ne
	subwne r1, r8, #0x801
	uxth r4, r1
	and r1, r1, #0x1
	cmp.w r9, #0x1
	lsr.w r4, r4, #0x1
	bne.n .L08029234
	cbnz r1, .L08029250
	add.w r1, r10, r4
	ldrb.w r4, [r1, #0x5b0]
	b.n .L0802929c
.L08029226:
	cbnz r1, .L0802925e
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r4, [sp, #0x14]
	b.n .L0802924c
.L08029234:
	cbnz r1, .L08029294
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r4, [sp, #0x14]
	b.n .L0802925a
.L08029242:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r4, [sp, #0x10]
.L0802924c:
	subs r4, r1, r4
	b.n .L08029266
.L08029250:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r4, [sp, #0x10]
.L0802925a:
	subs r4, r1, r4
	b.n .L0802929c
.L0802925e:
	add.w r1, r4, r10
	ldrb.w r4, [r1, #0x9b0]
.L08029266:
	uxtb r1, r4
	cmp r1, r6
	blt.w .L08028eb4
	uxth.w r1, r8
	cmp.w r2, r1, lsr #0xb
	it ne
	movne r8, r7
	and r1, r8, #0x1
	cmp.w r9, #0x1
	ubfx r4, r8, #0x1, #0xf
	bne.n .L080292cc
	cbnz r1, .L080292ea
	add.w r1, r10, r4
	ldrb.w r4, [r1, #0x5b0]
	b.n .L08028eac
.L08029294:
	add.w r1, r4, r10
	ldrb.w r4, [r1, #0x9b0]
.L0802929c:
	uxtb r1, r4
	cmp r1, r6
	blt.w .L08028eb4
	uxth.w r1, r8
	mov r4, r8
	cmp.w r2, r1, lsr #0xb
	it ne
	movne r4, r7
	and r1, r4, #0x1
	cmp.w r9, #0x1
	ubfx r4, r4, #0x1, #0xf
	bne.n .L080292dc
	cbnz r1, .L080292f6
	add.w r1, r10, r4
	ldrb.w r4, [r1, #0x5b0]
	b.n .L0802930c
.L080292cc:
	cmp r1, #0x0
	beq.w .L08028ea0
	add.w r1, r4, r10
	ldrb.w r4, [r1, #0x9b0]
	b.n .L08028eac
.L080292dc:
	cbnz r1, .L08029304
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r4, [sp, #0x14]
	b.n .L08029300
.L080292ea:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r4, [sp, #0x10]
	b.n .L08028eaa
.L080292f6:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r4, [sp, #0x10]
.L08029300:
	subs r4, r1, r4
	b.n .L0802930c
.L08029304:
	add.w r1, r4, r10
	ldrb.w r4, [r1, #0x9b0]
.L0802930c:
	uxtb r1, r4
	cmp r1, r6
	bge.w .L08028eb4
	add.w r1, r8, #0x1
	uxth r4, r1
	cmp.w r2, r4, lsr #0xb
	it ne
	subwne r1, r8, #0x7ff
	uxth r4, r1
	and r1, r1, #0x1
	cmp.w r9, #0x1
	lsr.w r4, r4, #0x1
	bne.n .L08029340
	cbnz r1, .L0802934e
	add.w r1, r10, r4
	ldrb.w r4, [r1, #0x5b0]
	b.n .L08029364
.L08029340:
	cbnz r1, .L0802935c
	add.w r1, r10, r4
	ldrb.w r1, [r1, #0x5b0]
	ldr r4, [sp, #0x14]
	b.n .L08029358
.L0802934e:
	add.w r1, r4, r10
	ldrb.w r1, [r1, #0x9b0]
	ldr r4, [sp, #0x10]
.L08029358:
	subs r4, r1, r4
	b.n .L08029364
.L0802935c:
	add.w r1, r4, r10
	ldrb.w r4, [r1, #0x9b0]
.L08029364:
	uxtb r1, r4
	cmp r6, r1
	ble.w .L08028eb4
	ldrh.w r1, [r10, #0xdbc]
	orr r1, r1, #0x8000
	strh.w r1, [r10, #0xdbc]
	b.n .L0802937c
.L0802937a:
	ldr r5, [sp]
.L0802937c:
	ldrh.w r1, [r10, #0xdbc]
	and r1, r1, #0x8000
	orrs r1, r5
	strh.w r1, [r10, #0xdbc]
	add sp, #0x1c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08029390:
	ldrh.w r1, [r10, #0xdbc]
	orr r1, r1, #0x8000
	strh.w r1, [r10, #0xdbc]
	b.n .L0802937c
.L0802939e:
	ldrh.w r1, [r10, #0xdbc]
	orr r1, r1, #0x8000
	strh.w r1, [r10, #0xdbc]
	b.n .L0802937c
.L080293ac:
	ldrh.w r1, [r10, #0xdbc]
	orr r1, r1, #0x8000
	strh.w r1, [r10, #0xdbc]
	b.n .L0802937c
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fft64_radix8_in_place - 64-point forward complex transform built from two
@ radix-8 stages, done in place.
@ param_1 (r0) = pointer to 64 complex single-precision values stored as
@ interleaved (re, im) float pairs (the code reads pfVar4[-1] and pfVar4[0] with
@ pfVar4 = param_1+4); no return value; transforms in place.
@ Stage 1 has uVar5 = 0x40, uVar3 = 8: a first loop (offset 0) runs the radix-8
@ butterfly (adds/subtracts of 8 points spaced 8 complex points apart, the
@ 45-degree rotation by constant 0.70710677 on the odd terms), then a second loop
@ for offsets k = 1..7 runs the same butterfly and multiplies outputs j = 1..7 by
@ the complex pair read from the float table at 0x0806e0d0 (pair index 2*k*j;
@ real part at 0x0806e0d0+8*idx, imaginary at 0x0806e0d4+8*idx; the table is
@ cos/sin pairs (1,0), (0.9987954,0.0490677), (0.9951847,0.0980171)... i.e. step
@ 2*pi/128; product form re*c + im*s, im*c - re*s = multiplication by the
@ conjugate).
@ Stage 2 (uVar5 = 8, uVar3 = 1): 8 groups of 8 consecutive points, radix-8
@ butterflies with no twiddle multiplication, then the loop exits because
@ uVar5 < 0x40.
@ Purpose: 64-point forward complex transform built from two radix-8 stages with
@ twiddle table 0x0806e0d0 (output order is not reordered by this function).
@ ----------------------------------------------------------------------------
	.section .text.fft64_radix8_in_place,"ax",%progbits
	.global fft64_radix8_in_place
	.thumb_func
	.type fft64_radix8_in_place, %function
fft64_radix8_in_place:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x4
	vpush {d8, d9, d10, d11, d12, d13, d14, d15}
	sub sp, #0x80
	adds r1, r0, #0x4
	adds r0, #0xc
	vldr s25, .L0802fba0
	str r0, [sp, #0x4]
	movs r0, #0x2
	movs r4, #0x40
	str r1, [sp, #0x8]
	str r0, [sp, #0x10]
	b.n .L0802fba4
.L0802fba0:
	.word 0x3f3504f3	@ 0.70710677 (single precision)
.L0802fba4:
	lsrs r3, r4, #0x3
	lsls r1, r3, #0x3
	sub.w r0, r1, r4, lsr #0x3
	lsls r0, r0, #0x3
	str r0, [sp, #0x6c]
	add.w r0, r3, r3, lsl #0x1
	lsls r6, r0, #0x4
	lsls r7, r0, #0x3
	add.w r0, r3, r3, lsl #0x2
	lsls r5, r3, #0x4
	lsl.w r12, r0, #0x3
	str r3, [sp, #0xc]
	lsls r0, r3, #0x5
	ldr r3, [sp, #0x8]
	lsls r2, r4, #0x3
	mov.w lr, #0x0
	strd r2, r4, [sp, #0x78]
	strd r5, r1, [sp, #0x70]
	strd r7, r6, [sp, #0x34]
	strd r0, r12, [sp, #0x2c]
	nop
.L0802fbe0:
	adds r4, r3, r0
	ldr r0, [sp, #0x70]
	add.w r9, r3, r1
	adds r5, r3, r0
	ldr r0, [sp, #0x38]
	add.w r8, r3, r12
	adds r6, r3, r0
	ldr r0, [sp, #0x34]
	vldr s2, [r3, #-0x4]
	add.w r10, r3, r0
	ldr r0, [sp, #0x6c]
	vldr s4, [r4, #-0x4]
	add.w r11, r3, r0
	vldr s6, [r9, #-0x4]
	vldr s8, [r8, #-0x4]
	vldr s14, [r5, #-0x4]
	vldr s1, [r6, #-0x4]
	vldr s3, [r10, #-0x4]
	vldr s5, [r11, #-0x4]
	vadd.f32 s10, s2, s4
	vadd.f32 s12, s6, s8
	vadd.f32 s7, s14, s1
	vadd.f32 s9, s3, s5
	vadd.f32 s11, s10, s7
	vadd.f32 s13, s12, s9
	vadd.f32 s15, s11, s13
	vstr s15, [r3, #-0x4]
	vsub.f32 s11, s11, s13
	vldr s15, [r9]
	vldr s16, [r8]
	vldr s22, [r10]
	vldr s24, [r11]
	vldr s13, [r3]
	vstr s11, [r4, #-0x4]
	vldr s11, [r4]
	vldr s18, [r5]
	vldr s20, [r6]
	vadd.f32 s28, s15, s16
	vadd.f32 s17, s22, s24
	vadd.f32 s26, s13, s11
	vadd.f32 s30, s18, s20
	vsub.f32 s10, s10, s7
	vsub.f32 s12, s12, s9
	vsub.f32 s9, s28, s17
	vadd.f32 s19, s26, s30
	vsub.f32 s7, s26, s30
	vadd.f32 s26, s10, s9
	vsub.f32 s10, s10, s9
	vadd.f32 s21, s28, s17
	vstr s26, [r5, #-0x4]
	vsub.f32 s26, s7, s12
	vstr s10, [r6, #-0x4]
	vadd.f32 s10, s12, s7
	vsub.f32 s2, s2, s4
	vsub.f32 s4, s6, s8
	vsub.f32 s6, s14, s1
	vsub.f32 s8, s3, s5
	vsub.f32 s12, s15, s16
	vsub.f32 s1, s22, s24
	vadd.f32 s23, s19, s21
	vsub.f32 s19, s19, s21
	vsub.f32 s3, s4, s8
	vadd.f32 s4, s4, s8
	vsub.f32 s8, s12, s1
	vadd.f32 s12, s12, s1
	vstr s23, [r3]
	vstr s19, [r4]
	ldr r4, [sp, #0x7c]
	vstr s26, [r5]
	vstr s10, [r6]
	vsub.f32 s10, s13, s11
	vsub.f32 s14, s18, s20
	vmul.f32 s3, s3, s25
	vmul.f32 s4, s4, s25
	vmul.f32 s8, s8, s25
	vmul.f32 s12, s12, s25
	ldrd r1, r2, [sp, #0x74]
	vadd.f32 s1, s2, s3
	vadd.f32 s5, s6, s4
	vadd.f32 s7, s10, s8
	vadd.f32 s9, s14, s12
	vsub.f32 s2, s2, s3
	vsub.f32 s4, s6, s4
	vsub.f32 s6, s10, s8
	vsub.f32 s8, s14, s12
	ldr.w r12, [sp, #0x30]
	vadd.f32 s11, s1, s9
	vsub.f32 s1, s1, s9
	vadd.f32 s10, s2, s8
	ldr r0, [sp, #0x2c]
	vsub.f32 s2, s2, s8
	add lr, r4
	vstr s11, [r9, #-0x4]
	vsub.f32 s11, s7, s5
	vstr s1, [r11, #-0x4]
	vadd.f32 s1, s5, s7
	vstr s10, [r8, #-0x4]
	vsub.f32 s10, s6, s4
	vstr s2, [r10, #-0x4]
	vadd.f32 s2, s4, s6
	cmp.w lr, #0x40
	add r3, r2
	vstr s11, [r9]
	vstr s1, [r11]
	vstr s10, [r8]
	vstr s2, [r10]
	bcc.w .L0802fbe0
	cmp r4, #0x40
	bcc.w .L0803011e
	ldr r3, [sp, #0x10]
	ldr r1, [sp, #0xc]
	uxth r0, r3
	str r0, [sp, #0x1c]
	movs r0, #0x2
	cmp r1, #0x2
	it hi
	movhi r0, r1
	rsb r3, r1, r1, lsl #0x3
	ldr.w r11, [sp, #0x4]
	str r0, [sp, #0x18]
	lsls r0, r3, #0x3
	movs r1, #0x0
	movs r2, #0x1
	str r0, [sp, #0x14]
	nop
.L0802fda0:
	ldr r0, [sp, #0x1c]
	movw r7, #:lower16:d_0806e0d0
	add r1, r0
	movt r7, #:upper16:d_0806e0d0
	add.w r6, r7, r1, lsl #0x3
	vldr s0, [r6]
	add.w r5, r7, r1, lsl #0x4
	vstr s0, [sp, #0x6c]
	vldr s0, [r5]
	add.w r5, r1, r1, lsl #0x1
	add.w r3, r7, r5, lsl #0x3
	vstr s0, [sp, #0x68]
	vldr s0, [r3]
	add.w r6, r7, r1, lsl #0x5
	vstr s0, [sp, #0x64]
	vldr s0, [r6]
	add.w r6, r1, r1, lsl #0x2
	lsls r3, r6, #0x3
	add.w r6, r7, r6, lsl #0x3
	vstr s0, [sp, #0x60]
	vldr s0, [r6]
	lsl.w r10, r5, #0x3
	lsls r6, r5, #0x4
	add.w r5, r7, r5, lsl #0x4
	vstr s0, [sp, #0x5c]
	vldr s0, [r5]
	rsb r5, r1, r1, lsl #0x3
	lsl.w r12, r1, #0x3
	lsls r4, r5, #0x3
	add.w r5, r7, r5, lsl #0x3
	vstr s0, [sp, #0x58]
	vldr s0, [r5]
	add.w r5, r12, #0x4
	lsl.w r8, r1, #0x4
	add r5, r7
	vstr s0, [sp, #0x54]
	vldr s0, [r5]
	add.w r5, r8, #0x4
	add r5, r7
	vstr s0, [sp, #0x50]
	vldr s0, [r5]
	add.w r5, r10, #0x4
	lsl.w r9, r1, #0x5
	add r5, r7
	vstr s0, [sp, #0x4c]
	vldr s0, [r5]
	add.w r5, r9, #0x4
	add r5, r7
	vstr s0, [sp, #0x48]
	vldr s0, [r5]
	adds r3, #0x4
	add r3, r7
	vstr s0, [sp, #0x44]
	vldr s0, [r3]
	adds r3, r6, #0x4
	add r3, r7
	vstr s0, [sp, #0x40]
	vldr s0, [r3]
	adds r3, r4, #0x4
	add r3, r7
	add.w lr, sp, #0x2c
	str r1, [sp, #0x28]
	vldr s13, [r3]
	strd r11, r2, [sp, #0x20]
	mov r9, r2
	ldm.w lr, {r1, r2, r7, lr}
	ldr r0, [sp, #0x14]
	vstr s0, [sp, #0x3c]
.L0802fe8c:
	ldr r3, [sp, #0x74]
	ldr r5, [sp, #0x70]
	add.w r4, r11, r1
	add r3, r11
	add.w r12, r11, r2
	add.w r6, r11, r5
	add.w r5, r11, lr
	add.w r10, r11, r7
	add.w r8, r11, r0
	vldr s15, [r11, #-0x4]
	vldr s16, [r4, #-0x4]
	vldr s18, [r3, #-0x4]
	vldr s20, [r12, #-0x4]
	vldr s26, [r6, #-0x4]
	vldr s28, [r5, #-0x4]
	vldr s30, [r10, #-0x4]
	vldr s17, [r8, #-0x4]
	vadd.f32 s22, s15, s16
	vadd.f32 s24, s18, s20
	vadd.f32 s19, s26, s28
	vadd.f32 s21, s30, s17
	vadd.f32 s23, s22, s19
	vmov.f32 s7, s25
	vadd.f32 s25, s24, s21
	vadd.f32 s27, s23, s25
	vstr s27, [r11, #-0x4]
	vsub.f32 s23, s23, s25
	vldr s25, [r11]
	vldr s27, [r4]
	vldr s29, [r3]
	vldr s31, [r12]
	vldr s0, [r6]
	vldr s2, [r5]
	vldr s4, [r10]
	vldr s6, [r8]
	vadd.f32 s8, s25, s27
	vadd.f32 s10, s29, s31
	vadd.f32 s12, s0, s2
	vadd.f32 s14, s4, s6
	vadd.f32 s1, s8, s12
	vadd.f32 s3, s10, s14
	vldr s9, [sp, #0x60]
	vldr s11, [sp, #0x44]
	vadd.f32 s5, s1, s3
	vsub.f32 s1, s1, s3
	vstr s5, [r11]
	vmul.f32 s3, s9, s23
	vmul.f32 s5, s11, s1
	vadd.f32 s3, s3, s5
	vmul.f32 s1, s9, s1
	vmul.f32 s5, s11, s23
	vsub.f32 s1, s1, s5
	vstr s3, [r4, #-0x4]
	vstr s1, [r4]
	vsub.f32 s1, s22, s19
	vsub.f32 s3, s24, s21
	vsub.f32 s8, s8, s12
	vsub.f32 s10, s10, s14
	vldr s24, [sp, #0x68]
	vldr s9, [sp, #0x4c]
	vadd.f32 s12, s1, s10
	vsub.f32 s14, s8, s3
	vmul.f32 s5, s24, s12
	vmul.f32 s22, s9, s14
	vmul.f32 s14, s24, s14
	vmul.f32 s12, s9, s12
	vsub.f32 s10, s1, s10
	vadd.f32 s8, s3, s8
	vldr s1, [sp, #0x58]
	vldr s3, [sp, #0x3c]
	vsub.f32 s12, s14, s12
	vstr s12, [r6]
	vmul.f32 s12, s1, s10
	vmul.f32 s14, s3, s8
	vmul.f32 s8, s1, s8
	vmul.f32 s10, s3, s10
	vadd.f32 s12, s14, s12
	vsub.f32 s8, s8, s10
	vsub.f32 s10, s18, s20
	vsub.f32 s14, s30, s17
	vsub.f32 s3, s29, s31
	vsub.f32 s0, s0, s2
	vsub.f32 s2, s4, s6
	vadd.f32 s5, s22, s5
	vsub.f32 s4, s10, s14
	vadd.f32 s6, s10, s14
	vsub.f32 s10, s3, s2
	vadd.f32 s2, s3, s2
	vstr s5, [r6, #-0x4]
	vstr s12, [r5, #-0x4]
	vstr s8, [r5]
	vsub.f32 s8, s15, s16
	vsub.f32 s12, s26, s28
	vsub.f32 s1, s25, s27
	vmul.f32 s4, s4, s7
	vmul.f32 s6, s6, s7
	vmul.f32 s10, s10, s7
	vmul.f32 s2, s2, s7
	vmov.f32 s25, s7
	vadd.f32 s14, s8, s4
	vadd.f32 s3, s12, s6
	vadd.f32 s5, s1, s10
	vadd.f32 s15, s0, s2
	vldr s7, [sp, #0x6c]
	vldr s9, [sp, #0x50]
	vadd.f32 s16, s14, s15
	vsub.f32 s18, s5, s3
	vmul.f32 s20, s7, s16
	vmul.f32 s22, s9, s18
	vmul.f32 s18, s7, s18
	vldr s7, [sp, #0x54]
	vsub.f32 s14, s14, s15
	vadd.f32 s3, s3, s5
	vmul.f32 s5, s7, s14
	vmul.f32 s15, s13, s3
	vmul.f32 s3, s7, s3
	vmul.f32 s14, s13, s14
	vmul.f32 s16, s9, s16
	vsub.f32 s14, s3, s14
	vsub.f32 s4, s8, s4
	vsub.f32 s6, s12, s6
	vsub.f32 s8, s1, s10
	vsub.f32 s0, s0, s2
	vldr s1, [sp, #0x5c]
	vldr s3, [sp, #0x40]
	vsub.f32 s16, s18, s16
	vadd.f32 s2, s4, s0
	vsub.f32 s10, s8, s6
	vadd.f32 s20, s20, s22
	vstr s16, [r3]
	vstr s14, [r8]
	vmul.f32 s12, s1, s2
	vmul.f32 s14, s3, s10
	vmul.f32 s10, s1, s10
	vmul.f32 s2, s3, s2
	vstr s20, [r3, #-0x4]
	vsub.f32 s2, s10, s2
	ldr r3, [sp, #0x7c]
	vstr s2, [r12]
	vadd.f32 s2, s6, s8
	vldr s8, [sp, #0x64]
	vldr s10, [sp, #0x48]
	vsub.f32 s0, s4, s0
	add r9, r3
	ldr r3, [sp, #0x78]
	vmul.f32 s4, s8, s0
	vmul.f32 s6, s10, s2
	vmul.f32 s2, s8, s2
	vmul.f32 s0, s10, s0
	vadd.f32 s5, s5, s15
	vadd.f32 s12, s12, s14
	vadd.f32 s4, s4, s6
	vsub.f32 s0, s2, s0
	cmp.w r9, #0x40
	add r11, r3
	vstr s5, [r8, #-0x4]
	vstr s12, [r12, #-0x4]
	vstr s4, [r10, #-0x4]
	vstr s0, [r10]
	bcc.w .L0802fe8c
	ldr r2, [sp, #0x24]
	ldr r0, [sp, #0x18]
	ldr.w r11, [sp, #0x20]
	adds r2, #0x1
	ldr r1, [sp, #0x28]
	cmp r2, r0
	add.w r11, r11, #0x8
	bne.w .L0802fda0
	ldr r0, [sp, #0x10]
	ldr r4, [sp, #0xc]
	lsls r0, r0, #0x3
	str r0, [sp, #0x10]
	b.n .L0802fba4
.L0803011e:
	add sp, #0x80
	vpop {d8, d9, d10, d11, d12, d13, d14, d15}
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ sort_bytes_ascending - bubble sort of the unsigned bytes at 0x20000f1d.
@ param_1 (r0) = element count; returns nothing.
@ If r0 < 2 returns at once. Otherwise bubble-sorts the r0 unsigned bytes at
@ 0x20000f1d into ascending order: r0-1 passes, pass i compares bytes [j] and
@ [j+1] for j < r0-1-i and swaps them when [j+1] < [j].
@ Both loop counters are byte variables (uxtb), so counts above 255 are not
@ handled.
@ ----------------------------------------------------------------------------
	.section .text.sort_bytes_ascending,"ax",%progbits
	.global sort_bytes_ascending
	.thumb_func
	.type sort_bytes_ascending, %function
sort_bytes_ascending:
	push {r4, r5, r6, r7, lr}
	cmp r0, #0x2
	it lo
	poplo {r4, r5, r6, r7, pc}
	movw r2, #0xf8
	sub.w r12, r0, #0x1
	movs r1, #0x0
	movt r2, #0x2000
	mov.w lr, #0x0
	b.n .L08030884
.L08030878:
	add.w lr, lr, #0x1
	uxtb.w r1, lr
	cmp r12, r1
	ble.n .L080308b8
.L08030884:
	mvns r1, r1
	add r1, r0
	cmp r1, #0x1
	blt.n .L08030878
	movs r4, #0x0
	movs r3, #0x0
	b.n .L0803089c
	.byte 0x00, 0xbf	@ padding
.L08030894:
	adds r3, #0x1
	uxtb r4, r3
	cmp r1, r4
	ble.n .L08030878
.L0803089c:
	adds r6, r2, r4
	ldrb.w r4, [r6, #0xe25]
	ldrb.w r5, [r6, #0xe26]
	cmp r4, r5
	bls.n .L08030894
	addw r7, r6, #0xe25
	addw r6, r6, #0xe26
	strb r5, [r7, #0x0]
	strb r4, [r6, #0x0]
	b.n .L08030894
.L080308b8:
	pop {r4, r5, r6, r7, pc}
	.short 0x0000	@ padding
	.short 0x0000	@ padding
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08030a70 - computes a value from byte 0x20000125 (idx) and the tables at
@ 0x080466c8 and 0x080465e0 and stores it to 0x20000f00/0x20000f04.
@ No parameters (r0/r1 are overwritten at 0x08030a7c before use; the decompiler
@ parameters are artefacts); no return value.
@ idx = byte 0x20000125, flag = byte 0x20000126; when flag == 1 copies idx to
@ byte 0x20000eb8 and byte 0x2000010c to byte 0x20000eb6.
@ A = unsigned 64-bit entry (idx % 3) of the table at 0x080466c8 (values 1, 2, 5)
@ converted with u64_to_double (08045600); B = 10.0 (0x4024000000000000, literal
@ at 0x08030b78) raised by double_pow (080438e0) to the power (idx / 3 + 3)
@ (exponent from u32_to_double, 080455da); P = B * A with double_mul (0804577c)
@ (the 1-2-5 sequence times a power of ten).
@ k = byte 0x20000eb8, m = 2 when k < 4 and byte 0x20000eb6 == 3, else 1;
@ D = m * unsigned 64-bit entry k of the table at 0x080465e0 (entries 0..13 are
@ 10, 10, 10, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000; the
@ largest index k reached is not bounded by this function) converted with
@ u64_to_double; result = P / D (double_div, 08045124) converted to unsigned
@ 64-bit by double_to_u64 (080460e4) and stored to 0x20000f00 (low dword) and
@ 0x20000f04 (high dword).
@ When flag == 1: if (result >> 3) > 0x7c the function returns without further
@ write, otherwise stores byte 1000 / (result & 0xffff) to 0x20000efc.
@ Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08030a70,"ax",%progbits
	.global fn_08030a70
	.thumb_func
	.type fn_08030a70, %function
fn_08030a70:
	push.w {r4, r5, r6, r7, r8, lr}
	movw r8, #0xf8
	movt r8, #0x2000
	ldrb.w r1, [r8, #0x2e]
	ldrb.w r0, [r8, #0x2d]
	cmp r1, #0x1
	bne.n .L08030a94
	ldrb.w r1, [r8, #0x14]
	strb.w r0, [r8, #0xdc0]
	strb.w r1, [r8, #0xdbe]
.L08030a94:
	movw r2, #0xaaab
	uxtb r1, r0
	movt r2, #0xaaaa
	umull r1, r7, r1, r2
	lsrs r1, r7, #0x1
	sub.w r1, r1, r1, lsl #0x2
	add r0, r1
	movw r1, #:lower16:d_080466c8
	uxtb r0, r0
	movt r1, #:upper16:d_080466c8
	add.w r2, r1, r0, lsl #0x3
	ldr.w r0, [r1, r0, lsl #0x3]
	ldr r1, [r2, #0x4]
	bl u64_to_double
	mov r4, r0
	movs r0, #0x3
	add.w r0, r0, r7, lsr #0x1
	mov r5, r1
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L08030b78
	bl double_pow
	vmov r0, r1, d0
	mov r2, r4
	mov r3, r5
	bl double_mul
	ldrb.w r3, [r8, #0xdc0]
	movs r2, #0x0
	cmp r3, #0x4
	it lo
	movlo r2, #0x1
	ldrb.w r5, [r8, #0xdbe]
	movw r12, #:lower16:d_080465e0
	movt r12, #:upper16:d_080465e0
	subs r5, #0x3
	ldr.w r4, [r12, r3, lsl #0x3]
	clz r5, r5
	lsrs r5, r5, #0x5
	movs r6, #0x1
	tst r2, r5
	it ne
	movne r6, #0x2
	umull r2, r7, r6, r4
	mov r4, r0
	add.w r0, r12, r3, lsl #0x3
	ldr r0, [r0, #0x4]
	mov r5, r1
	mla r1, r6, r0, r7
	mov r0, r2
	movs r7, #0x0
	bl u64_to_double
	mov r2, r0
	mov r3, r1
	mov r0, r4
	mov r1, r5
	bl double_div
	bl double_to_u64
	ldrb.w r2, [r8, #0x2e]
	str.w r0, [r8, #0xe08]
	cmp r2, #0x1
	str.w r1, [r8, #0xe0c]
	bne.n .L08030b70
	lsrs r2, r0, #0x3
	orr.w r2, r2, r1, lsl #0x1d
	rsbs.w r2, r2, #0x7c
	sbcs.w r1, r7, r1, lsr #0x3
	it lo
	poplo.w {r4, r5, r6, r7, r8, pc}
	uxth r0, r0
	mov.w r1, #0x3e8
	udiv r0, r1, r0
	strb.w r0, [r8, #0xe04]
.L08030b70:
	pop.w {r4, r5, r6, r7, r8, pc}
	.byte 0x00, 0xbf, 0x00, 0xbf	@ padding
.L08030b78:
	.word 0x00000000, 0x40240000	@ 10.0 (double, low word first)
