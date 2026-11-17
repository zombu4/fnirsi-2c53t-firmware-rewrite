@ fn_08020e98_p4.inc - part 4 of 4 of fn_08020e98 (0x08023e9a..0x080242ec):
@ tail of the acquisition-state update: the last timer-register write, the
@ table-entry selection and register writes for the two channels, the queue
@ messages sent through queue_send_timeout, the two 25-step byte-sum loops
@ (offsets 0x6aa.. and 0xaaa.. of the row at r10) and the final state checks.
@ Included by part 1; no header or section lines. Contents, in address order:
@  - finishes the register write at 0x40007404 (bits 31..12 of the old word at
@    offset 4 are kept, the low 12 bits come from the float result) and sets
@    bit 0 of the register at offset 0;
@  - selects a pair of u16 table entries (offsets 0x274.. / 0x2b0.. / 0x2d8.. /
@    0x2ec.. / 0x300.. / 0x314.. / 0x328.. / 0x33c.. from r9), scales their
@    difference by a float and writes the result to 0x40001c34;
@  - sends queue messages 8, 5, 6 (to the queues at 0x20002d78 / 0x20002d6c);
@  - calls fn_080088a4 and fn_08008a58 with the low nibble of byte 0x30;
@  - when byte 0x32 is 0xff and byte 0x33 is non-zero: sums 20 bytes per step
@    over 25 steps (step 0x19) from offset 0x6aa and again from offset 0xaaa,
@    scales each sum by 0x10624dd3 >> 5 and stores the bytes at 0x352 / 0x353;
@  - final checks of bytes 0x2e, 0xdb0, 0x14, 0x2d, 0x2c, the register at
@    0x40010008 bit 0, queue messages 4 and 5, and the call to fn_080242ec.
	vcvt.f32.u32	s4, s4
	vadd.f32	s2, s2, s4
	ldr	r1, [r0, #4]
	vcvt.u32.f32	s2, s2
	vmov	r2, s2
	lsrs	r1, r1, #12
	bfi	r2, r1, #12, #20
	str	r2, [r0, #4]
	ldr	r1, [r0]
	orr.w	r1, r1, #1
	str	r1, [r0]
	ldrb.w	r1, [r9, #0x2d]
	ldrb.w	r0, [r9, #3]
	cmp	r1, #5
	bcc.n	.L08023ed6
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L08023f96
.L08023ed6:
	cmp	r1, #4
	beq.n	.L08023f8a
	ldrb.w	r1, [r9, #0x14]
	cmp	r1, #3
	beq.n	.L08023f8a
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L08023f96
.L08023ef0:
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L08023efc:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	vldr	s0, .L08023d38
	subs	r0, r0, r1
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vdiv.f32	s2, s2, s0
	ldrsb.w	r0, [r9, #4]
	adds	r0, #0x64
	vmov	s4, r0
	vcvt.f32.s32	s4, s4
	movw	r0, #0x7404
	movt	r0, #0x4000
	vmul.f32	s2, s2, s4
	vmov	s4, r1
	vcvt.f32.u32	s4, s4
	vadd.f32	s2, s2, s4
	ldr	r1, [r0, #4]
	vcvt.u32.f32	s2, s2
	vmov	r2, s2
	lsrs	r1, r1, #12
	bfi	r2, r1, #12, #20
	str	r2, [r0, #4]
	ldr	r1, [r0]
	orr.w	r1, r1, #1
	str	r1, [r0]
	ldrb.w	r1, [r9, #0x2d]
	ldrb.w	r0, [r9, #0x30]
	cmp	r1, #5
	and.w	r0, r0, #0xf
	bcc.n	.L08023f70
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L0802404a
.L08023f70:
	cmp	r1, #4
	beq.n	.L0802403e
	ldrb.w	r1, [r9, #0x14]
	cmp	r1, #3
	beq.n	.L0802403e
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L0802404a
.L08023f8a:
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L08023f96:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	movw	r8, #0x2d78
	subs	r0, r0, r1
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vdiv.f32	s0, s2, s0
	ldrsb.w	r0, [r9, #5]
	movt	r8, #0x2000
	adds	r0, #0x64
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	movw	r0, #0x1c34
	movt	r0, #0x4000
	add.w	r4, sp, #0x5e
	mov.w	r2, #0xffffffff
	vmul.f32	s0, s0, s2
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vcvt.u32.f32	s0, s0
	vstr	s0, [r0]
	movs	r1, #8
	ldr.w	r0, [r8]
	strb.w	r1, [sp, #0x5e]
	mov	r1, r4
	bl	queue_send_timeout
	bl	fn_08025fc0
	movw	r7, #0x2d6c
	movt	r7, #0x2000
	movs	r1, #5
	ldr	r0, [r7]
	add.w	r5, sp, #0x5f
	strb.w	r1, [sp, #0x5f]
	mov	r1, r5
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	ldr	r0, [r7]
	movs	r6, #6
	mov	r1, r5
	mov.w	r2, #0xffffffff
	strb.w	r6, [sp, #0x5f]
	bl	queue_send_timeout
	ldr.w	r0, [r8]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	strb.w	r6, [sp, #0x5e]
	bl	queue_send_timeout
	b.n	.L0802408a
.L0802403e:
	add.w	r1, r9, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L0802404a:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	subs	r0, r0, r1
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vdiv.f32	s0, s2, s0
	ldrsb.w	r0, [r9, #5]
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
.L0802408a:
	mov	r6, r9
.L0802408c:
	ldrb.w	r0, [r6, #0x30]
	and.w	r0, r0, #0xf
	bl	fn_080088a4
	ldrb.w	r0, [r6, #0x30]
	and.w	r0, r0, #0xf
	bl	fn_08008a58
.L080240a4:
	ldrb.w	r0, [r6, #0x32]
	mov	r10, r6
	cmp	r0, #0xff
	bne.w	.L0802422e
	ldrb.w	r0, [r10, #0x33]
	cmp	r0, #0
	beq.w	.L0802422e
	movs	r0, #0
	movs	r2, #0
	strb.w	r0, [r10, #0x32]
	nop
.L080240c4:
	add.w	r1, r10, r0
	ldrb.w	r3, [r1, #0x6aa]
	ldrb.w	r7, [r1, #0x6ab]
	ldrb.w	r6, [r1, #0x6ac]
	add	r2, r3
	ldrb.w	r5, [r1, #0x6ad]
	add	r2, r7
	add	r2, r6
	ldrb.w	r3, [r1, #0x6ae]
	add	r2, r5
	ldrb.w	r7, [r1, #0x6af]
	add	r2, r3
	ldrb.w	r3, [r1, #0x6b0]
	add	r2, r7
	ldrb.w	r7, [r1, #0x6b1]
	add	r2, r3
	ldrb.w	r3, [r1, #0x6b2]
	add	r2, r7
	ldrb.w	r7, [r1, #0x6b3]
	add	r2, r3
	ldrb.w	r3, [r1, #0x6b4]
	add	r2, r7
	ldrb.w	r7, [r1, #0x6b5]
	add	r2, r3
	ldrb.w	r3, [r1, #0x6b6]
	add	r2, r7
	ldrb.w	r7, [r1, #0x6b7]
	add	r2, r3
	ldrb.w	r3, [r1, #0x6b8]
	add	r2, r7
	ldrb.w	r7, [r1, #0x6b9]
	add	r2, r3
	ldrb.w	r3, [r1, #0x6ba]
	add	r2, r7
	ldrb.w	r7, [r1, #0x6bb]
	add	r2, r3
	ldrb.w	r3, [r1, #0x6bc]
	add	r2, r7
	ldrb.w	r7, [r1, #0x6bd]
	add	r2, r3
	ldrb.w	r3, [r1, #0x6be]
	add	r2, r7
	ldrb.w	r7, [r1, #0x6bf]
	add	r2, r3
	ldrb.w	r3, [r1, #0x6c0]
	add	r2, r7
	ldrb.w	r7, [r1, #0x6c1]
	add	r2, r3
	ldrb.w	r1, [r1, #0x6c2]
	add	r2, r7
	adds	r0, #0x19
	cmp.w	r0, #0x1f4
	add	r2, r1
	bne.n	.L080240c4
	movw	r0, #0x4dd3
	movt	r0, #0x1062
	umull	r1, r2, r2, r0
	lsrs	r1, r2, #5
	strb.w	r1, [r10, #0x352]
	movs	r1, #0
	movs	r3, #0
.L0802417c:
	add.w	r2, r10, r1
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
	bne.n	.L0802417c
	umull	r0, r1, r3, r0
	lsrs	r0, r1, #5
	strb.w	r0, [r10, #0x353]
	movs	r0, #0
	strb.w	r0, [r10, #0x33]
.L0802422e:
	ldrb.w	r0, [r10, #0x2e]
	cbz	r0, .L08024254
	ldrh.w	r0, [r10, #0xdbc]
	ldrb.w	r1, [r10, #0xdb2]
	bfc	r0, #15, #17
	strh.w	r0, [r10, #0xdbc]
	movs	r0, #2
	strb.w	r0, [r10, #0xdb0]
	adds	r0, r1, #1
	strb.w	r0, [r10, #0xdb2]
	movs	r0, #1
	b.n	.L08024260
.L08024254:
	ldrb.w	r1, [r10, #0xdb0]
	movs	r0, #0
.L0802425a:
	cmp	r1, #2
	bne.w	.L080224b2
.L08024260:
	movw	r1, #0x1014
	movt	r1, #0x4001
	ldr.w	r1, [r1, #-0xc]
	lsls	r1, r1, #31
	bne.n	.L08024286
	ldrb.w	r1, [r10, #0x2c]
	cmp	r1, #0
	it	ne
	cmpne	r0, #0
	beq.w	.L080224b2
	bl	fn_080242ec
	b.w	.L080224b2
.L08024286:
	ldrb.w	r0, [r10, #0x14]
	movw	r4, #0x2d78
	lsls	r1, r0, #31
	movt	r4, #0x2000
	bne.n	.L0802429e
	ldrb.w	r1, [r10, #0x2d]
	cmp	r1, #4
	bhi.n	.L080242c0
.L0802429e:
	movs	r0, #0
	strb.w	r0, [r10, #0xdb0]
	movs	r1, #4
	ldr	r0, [r4]
	strb.w	r1, [sp, #0x5b]
	add.w	r1, sp, #0x5b
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	ldrb.w	r0, [r10, #0x14]
	ldrb.w	r1, [r10, #0x2d]
.L080242c0:
	cmp	r1, #5
	bcc.n	.L080242cc
	ands.w	r0, r0, #2
	beq.w	.L080224b2
.L080242cc:
	movs	r0, #0
	strb.w	r0, [r10, #0xdb0]
	movs	r1, #5
	ldr	r0, [r4]
	strb.w	r1, [sp, #0x5b]
	add.w	r1, sp, #0x5b
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	b.w	.L080224b2
	.short	0x0000	@ padding
