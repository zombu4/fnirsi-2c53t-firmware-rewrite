@ scope_acq_42.s - scope acquisition: per-channel offset calibration from the extremes of the sample buffers (fn_08008c60).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08008c60 - no parameters. Channel loop: ch runs from the high nibble of byte
@ [0x2000010d] up to (excluding) its low nibble (nothing happens when high >= low).
@ Per channel it computes the minimum and maximum over the 301 bytes at
@ 0x2000044e + ch*0x12d (seed byte 0, then bytes 1..300 in 20 passes of 15), then
@ switches on nibble ch of [0x20000127] (cases 0 and 6..0xe do nothing):
@ case 1: if max > 0x80+0x2d*k or min < 0x80-0x2d*k (k=2, k=1 when the low byte of
@   [0x2000010c] is 3) it increments the counter [0x200000fa+ch] when below 9,
@   re-applies with 080088a4([0x200000fa]) (ch 0) or 08008a58([0x200000fb]) (ch 1)
@   and sends code 4 to queue [0x20002d6c] with 08041cf0(queue, &code, 0xffffffff);
@   otherwise adds 1<<(4*ch) to [0x20000127].
@ case 2: if nibble ch of [0x20000129] is 0 sets [0x20000127]=0xff (or only returns
@   to the next channel when the low byte of [0x2000010c] is 3 and adds 1<<(4*ch));
@   else sets [0x200000f8+ch]=1, writes 0x1000 (ch 0) or 0x2000 to 0x40011410,
@   sends 4, adds 1<<(4*ch).
@ case 3 (off = signed byte [0x200000fc+ch]; k as above): if max==0xe4:
@   off' = off+0xe4-0x5a*k-min (16 bit); when off' < -100 adds 1<<(4*ch) to
@   [0x20000127] and stores 0x9c (-100), else stores the low byte of off'.
@   Else if min==0x1c: off' = off+0x1c+0x5a*k-max, when off' > 100 adds 1<<(4*ch)
@   to [0x20000127] and stores 100, else stores the low byte of off'.
@   Else: c = 0x80 (or 0xad-0x5a*ch when the low byte of [0x2000010c] is 3),
@   off' = off+(c-min)-((max-min)/2 rounded toward zero) (16 bit), above 100 stored
@   as 100, at or below -100 stored as -100, then [0x20000127]=0xff (or ORs
@   0xf<<(4*ch) when the low byte of [0x2000010c] is 3).
@   All three paths then recompute (ch 0: formula of 080088a4 with [0x200000fa],
@   ch 1: formula of 08008a58 with [0x200000fb]) and send 5 to queue [0x20002d6c].
@ case 4: if max==0xe4 or min==0x1c it takes the case 1 path, else adds 1<<(4*ch).
@ case 5: offset [0x200000fc+ch] gains ((0xe4-max)/2) for ch 0 when max != 0,
@   clamped to +-100, re-applies the register, sends 5, sets [0x20000127]=0xff (or
@   ORs 0xf<<(4*ch) when the low byte of [0x2000010c] is 3).
@ case 0xf: only when [0x20000127]==0xff and ch==[0x2000010e]: sets
@   [0x20000127]=0, stores (max-min)/2+min-0x80 into the halfword [0x20000114],
@   sends 6 to queue [0x20002d6c] and 8 to queue [0x20002d78].
@ Purpose not determined from the code beyond this mechanics (it adjusts the
@ per-channel offset bytes from the extremes of the sample buffers).
@ ----------------------------------------------------------------------------
	.section .text.fn_08008c60,"ax",%progbits
	.global fn_08008c60
	.thumb_func
	.type fn_08008c60, %function
fn_08008c60:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #4
	vpush	{d8}
	sub	sp, #0x18
	movw	r11, #0xf8
	movt	r11, #0x2000
	ldrb.w	r2, [r11, #0x14]
	ldrb.w	r1, [r11, #0x15]
	movs	r0, #2
	cmp	r2, #3
	and.w	r2, r1, #0xf
	it	eq
	moveq	r0, #1
	cmp.w	r2, r1, lsr #4
	bls.w	.L080092ca
	lsr.w	r10, r1, #4
	movs	r1, #0x1c
	movt	r1, #0xffff
	movs	r2, #0x5a
	smlabb	r1, r0, r2, r1
	str	r1, [sp, #4]
	movs	r1, #0xe4
	movt	r1, #0xffff
	mvn.w	r2, #0x59
	smlabb	r1, r0, r2, r1
	str	r1, [sp, #8]
	movs	r1, #0x2d
	movs	r3, #0x80
	mul.w	r2, r0, r1
	smlabb	r0, r0, r1, r3
	str	r0, [sp, #0x10]
	rsb.w	r0, r2, #0x80
	movw	r9, #0x12d
	str	r0, [sp, #0xc]
	smlabb	r0, r10, r9, r11
	vldr	s16, .L08008cd8
	addw	r8, r0, #0x356
	b.n	.L08008cfc
.L08008cd8:
	.word	0x43480000	@ float 200.0
.L08008cdc:
	movs	r0, #1
	lsls	r0, r5
	add	r0, r2
.L08008ce2:
	strb.w	r0, [r11, #0x2f]
.L08008ce6:
	ldrb.w	r0, [r11, #0x15]
	add.w	r10, r10, #1
	and.w	r0, r0, #0xf
	cmp	r10, r0
	addw	r8, r8, #0x12d
	bcs.w	.L080092ca
.L08008cfc:
	mla	r0, r10, r9, r11
	mov.w	r2, #0x12c
	ldrb.w	r0, [r0, #0x356]
	mov	r3, r8
	mov	r1, r0
.L08008d0c:
	ldrb.w	r12, [r3, #0xf]!
	ldrb.w	r4, [r3, #-0xe]
	ldrb.w	r6, [r3, #-0xd]
	cmp	r1, r4
	ldrb.w	r7, [r3, #-0xc]
	ldrb.w	r5, [r3, #-0xb]
	it	cc
	movcc	r1, r4
	cmp	r0, r4
	it	hi
	movhi	r0, r4
	cmp	r1, r6
	it	cc
	movcc	r1, r6
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r1, r7
	it	cc
	movcc	r1, r7
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r1, r5
	it	cc
	movcc	r1, r5
	ldrb.w	r7, [r3, #-0xa]
	cmp	r0, r5
	it	hi
	movhi	r0, r5
	cmp	r1, r7
	it	cc
	movcc	r1, r7
	ldrb.w	r6, [r3, #-0x9]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r1, r6
	it	cc
	movcc	r1, r6
	ldrb.w	r7, [r3, #-0x8]
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r1, r7
	it	cc
	movcc	r1, r7
	ldrb.w	r6, [r3, #-0x7]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r1, r6
	it	cc
	movcc	r1, r6
	ldrb.w	r7, [r3, #-0x6]
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r1, r7
	it	cc
	movcc	r1, r7
	ldrb.w	r6, [r3, #-0x5]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r1, r6
	it	cc
	movcc	r1, r6
	ldrb.w	r7, [r3, #-0x4]
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r1, r7
	it	cc
	movcc	r1, r7
	ldrb.w	r6, [r3, #-0x3]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r1, r6
	it	cc
	movcc	r1, r6
	ldrb.w	r7, [r3, #-0x2]
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r1, r7
	it	cc
	movcc	r1, r7
	ldrb.w	r6, [r3, #-0x1]
	cmp	r0, r7
	it	hi
	movhi	r0, r7
	cmp	r1, r6
	it	cc
	movcc	r1, r6
	cmp	r0, r6
	it	hi
	movhi	r0, r6
	cmp	r1, r12
	it	cc
	movcc	r1, r12
	cmp	r0, r12
	it	hi
	movhi	r0, r12
	subs	r2, #0xf
	bne.n	.L08008d0c
	ldrb.w	r2, [r11, #0x2f]
	lsl.w	r5, r10, #2
	lsr.w	r3, r2, r5
	and.w	r3, r3, #0xf
	subs	r3, #1
	cmp	r3, #0xe
	bhi.w	.L08008ce6
	tbb	[pc, r3]
.L08008e1c:
	.byte	(.L08008e2e - .L08008e1c)/2
	.byte	(.L08008e3e - .L08008e1c)/2
	.byte	(.L08008e90 - .L08008e1c)/2
	.byte	(.L08008ede - .L08008e1c)/2
	.byte	(.L08008f0c - .L08008e1c)/2
	.byte	(.L08008e2c - .L08008e1c)/2
	.byte	(.L08008e2c - .L08008e1c)/2
	.byte	(.L08008e2c - .L08008e1c)/2
	.byte	(.L08008e2c - .L08008e1c)/2
	.byte	(.L08008e2c - .L08008e1c)/2
	.byte	(.L08008e2c - .L08008e1c)/2
	.byte	(.L08008e2c - .L08008e1c)/2
	.byte	(.L08008e2c - .L08008e1c)/2
	.byte	(.L08008e2c - .L08008e1c)/2
	.byte	(.L08008f64 - .L08008e1c)/2
	.byte	0x00	@ padding
.L08008e2c:
	b.n	.L08008ce6
.L08008e2e:
	ldr	r3, [sp, #0x10]
	cmp	r3, r1
	bcc.n	.L08008ee8
	ldr	r1, [sp, #0xc]
	cmp	r1, r0
	ble.w	.L08008cdc
	b.n	.L08008ee8
.L08008e3e:
	ldrb.w	r0, [r11, #0x31]
	lsrs	r0, r5
	lsls	r0, r0, #0x1c
	beq.w	.L08008ff6
	movs	r4, #1
	mov.w	r0, #0x2000
	movw	r1, #0x1410
	strb.w	r4, [r11, r10]
	cmp.w	r10, #0
	it	eq
	moveq.w	r0, #0x1000
	movt	r1, #0x4001
	str	r0, [r1, #0]
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	ldr	r0, [r0, #0]
	movs	r1, #4
	strb.w	r1, [sp, #0x17]
	add.w	r1, sp, #0x17
	mov.w	r2, #-1
	bl	queue_send_timeout
	ldrb.w	r0, [r11, #0x2f]
	lsl.w	r1, r4, r5
	add	r0, r1
	b.n	.L08008ce2
.L08008e90:
	cmp	r1, #0xe4
	bne.w	.L08008fc4
	add.w	r1, r11, r10
	ldrsb.w	r3, [r1, #4]!
	ldr	r7, [sp, #8]
	add	r3, r7
	subs	r0, r3, r0
	lsls	r3, r0, #0x10
	cmn.w	r3, #0x640000
	bge.n	.L08008eb8
	movs	r0, #1
	lsls	r0, r5
	add	r0, r2
	strb.w	r0, [r11, #0x2f]
	movs	r0, #0x9c
.L08008eb8:
	strb	r0, [r1, #0]
	cmp.w	r10, #0
	beq.w	.L08009188
.L08008ec2:
	ldrb.w	r1, [r11, #0x2d]
	ldrb.w	r0, [r11, #3]
	cmp	r1, #5
	bcc.w	.L0800901c
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L080090ea
.L08008ede:
	cmp	r1, #0xe4
	it	ne
	cmpne	r0, #0x1c
	bne.w	.L08008cdc
.L08008ee8:
	add.w	r0, r11, r10
	ldrb.w	r1, [r0, #2]!
	cmp	r1, #8
	bhi.w	.L08008cdc
	adds	r1, #1
	cmp.w	r10, #0
	strb	r1, [r0, #0]
	beq.w	.L080090ae
	ldrb.w	r0, [r11, #3]
	bl	fn_08008a58
	b.n	.L080090b6
.L08008f0c:
	add.w	r0, r11, r10
	ldrsb.w	r2, [r0, #4]
	uxtb	r3, r1
	rsb.w	r3, r3, #0xe4
	uxth	r7, r3
	cmp	r1, #0
	mov	r1, r2
	add.w	r3, r3, r7, lsr #15
	it	ne
	addne.w	r1, r1, r3, asr #1
	cmp.w	r10, #0
	it	ne
	movne	r1, r2
	cmp	r1, #0x64
	mvn.w	r2, #0x63
	it	ge
	movge	r1, #0x64
	cmp	r1, r2
	it	le
	movle	r1, r2
	cmp.w	r10, #0
	strb	r1, [r0, #4]
	beq.n	.L08009002
	ldrb.w	r1, [r11, #0x2d]
	ldrb.w	r0, [r11, #3]
	cmp	r1, #5
	bcc.n	.L08009036
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L08009138
.L08008f64:
	cmp	r2, #0xff
	bne.w	.L08008ce6
	ldrb.w	r2, [r11, #0x16]
	cmp	r10, r2
	bne.w	.L08008ce6
	movs	r2, #0
	strb.w	r2, [r11, #0x2f]
	uxtb	r1, r1
	uxtb	r2, r0
	subs	r1, r1, r2
	uxth	r2, r1
	add.w	r1, r1, r2, lsr #15
	lsrs	r1, r1, #1
	uxtab	r0, r1, r0
	subs	r0, #0x80
	strh.w	r0, [r11, #0x1c]
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	ldr	r0, [r0, #0]
	movs	r1, #6
	strb.w	r1, [sp, #0x17]
	add.w	r1, sp, #0x17
	mov.w	r2, #-1
	bl	queue_send_timeout
	movw	r0, #0x2d78
	movt	r0, #0x2000
	ldr	r0, [r0, #0]
	movs	r1, #8
	strb.w	r1, [sp, #0x16]
	add.w	r1, sp, #0x16
	b.n	.L080092c0
.L08008fc4:
	add.w	r3, r11, r10
	ldrsb.w	r4, [r3, #4]!
	cmp	r0, #0x1c
	bne.n	.L08009050
	ldr	r0, [sp, #4]
	subs	r0, r0, r1
	add	r0, r4
	lsls	r1, r0, #0x10
	cmp.w	r1, #0x640000
	ble.n	.L08008fea
	movs	r0, #1
	lsls	r0, r5
	add	r0, r2
	strb.w	r0, [r11, #0x2f]
	movs	r0, #0x64
.L08008fea:
	strb	r0, [r3, #0]
	cmp.w	r10, #0
	bne.w	.L08008ec2
	b.n	.L08009188
.L08008ff6:
	ldrb.w	r0, [r11, #0x14]
	cmp	r0, #3
	beq.w	.L08008cdc
	b.n	.L0800924a
.L08009002:
	ldrb.w	r1, [r11, #0x2d]
	ldrb.w	r0, [r11, #2]
	cmp	r1, #5
	bcc.n	.L080090c4
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L080091c8
.L0800901c:
	cmp	r1, #4
	beq.n	.L080090de
	ldrb.w	r1, [r11, #0x14]
	cmp	r1, #3
	beq.n	.L080090de
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L080090ea
.L08009036:
	cmp	r1, #4
	beq.n	.L0800912c
	ldrb.w	r1, [r11, #0x14]
	cmp	r1, #3
	beq.n	.L0800912c
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L08009138
.L08009050:
	ldrb.w	r2, [r11, #0x14]
	mvn.w	r7, #0x59
	mul.w	r7, r10, r7
	cmp	r2, #3
	mov.w	r2, #0x80
	sub.w	r1, r1, r0
	it	eq
	addeq.w	r2, r7, #0xad
	uxth	r7, r1
	add.w	r1, r1, r7, lsr #15
	sxth	r1, r1
	movs	r7, #0
	sub.w	r1, r7, r1, lsr #1
	subs	r0, r2, r0
	uxtah	r0, r0, r1
	add	r0, r4
	lsls	r1, r0, #0x10
	cmp.w	r1, #0x640000
	it	gt
	movgt	r0, #0x64
	sxth	r1, r0
	mvn.w	r2, #0x63
	cmp	r1, r2
	it	le
	movle	r0, r2
	strb	r0, [r3, #0]
	ldrb.w	r0, [r11, #0x14]
	cmp	r0, #3
	bne.n	.L0800917a
	ldrb.w	r0, [r11, #0x2f]
	movs	r1, #0xf
	lsls	r1, r5
	orrs	r0, r1
	b.n	.L0800917c
.L080090ae:
	ldrb.w	r0, [r11, #2]
	bl	fn_080088a4
.L080090b6:
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	ldr	r0, [r0, #0]
	movs	r1, #4
	b.n	.L080092b8
.L080090c4:
	cmp	r1, #4
	beq.n	.L080091bc
	ldrb.w	r1, [r11, #0x14]
	cmp	r1, #3
	beq.n	.L080091bc
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L080091c8
.L080090de:
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L080090ea:
	ldrh	r0, [r0, #0]
	ldrh	r1, [r1, #0]
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s16
	ldrsb.w	r0, [r11, #5]
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
	b.n	.L080092ac
.L0800912c:
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L08009138:
	ldrh	r0, [r0, #0]
	ldrh	r1, [r1, #0]
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s16
	ldrsb.w	r0, [r11, #5]
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
	b.n	.L0800921a
.L0800917a:
	movs	r0, #0xff
.L0800917c:
	strb.w	r0, [r11, #0x2f]
	cmp.w	r10, #0
	bne.w	.L08008ec2
.L08009188:
	ldrb.w	r1, [r11, #0x2d]
	ldrb.w	r0, [r11, #2]
	cmp	r1, #5
	bcc.n	.L080091a2
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L0800925a
.L080091a2:
	cmp	r1, #4
	beq.n	.L0800924e
	ldrb.w	r1, [r11, #0x14]
	cmp	r1, #3
	beq.n	.L0800924e
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L0800925a
.L080091bc:
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L080091c8:
	ldrh	r0, [r0, #0]
	ldrh	r1, [r1, #0]
	movw	r2, #0x7404
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s16
	ldrsb.w	r0, [r11, #4]
	movt	r2, #0x4000
	adds	r0, #0x64
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	ldr	r0, [r2, #4]
	lsrs	r0, r0, #0xc
	vmul.f32	s0, s0, s2
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vcvt.u32.f32	s0, s0
	vmov	r1, s0
	bfi	r1, r0, #0xc, #0x14
	str	r1, [r2, #4]
	ldr	r0, [r2, #0]
	orr.w	r0, r0, #1
	str	r0, [r2, #0]
.L0800921a:
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	ldr	r0, [r0, #0]
	movs	r1, #5
	strb.w	r1, [sp, #0x17]
	add.w	r1, sp, #0x17
	mov.w	r2, #-1
	bl	queue_send_timeout
	ldrb.w	r0, [r11, #0x14]
	cmp	r0, #3
	bne.n	.L0800924a
	ldrb.w	r0, [r11, #0x2f]
	movs	r1, #0xf
	lsls	r1, r5
	orrs	r0, r1
	b.n	.L08008ce2
.L0800924a:
	movs	r0, #0xff
	b.n	.L08008ce2
.L0800924e:
	add.w	r1, r11, r0, lsl #1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L0800925a:
	ldrh	r0, [r0, #0]
	ldrh	r1, [r1, #0]
	movw	r2, #0x7404
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s16
	ldrsb.w	r0, [r11, #4]
	movt	r2, #0x4000
	adds	r0, #0x64
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	ldr	r0, [r2, #4]
	lsrs	r0, r0, #0xc
	vmul.f32	s0, s0, s2
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	vcvt.u32.f32	s0, s0
	vmov	r1, s0
	bfi	r1, r0, #0xc, #0x14
	str	r1, [r2, #4]
	ldr	r0, [r2, #0]
	orr.w	r0, r0, #1
	str	r0, [r2, #0]
.L080092ac:
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	ldr	r0, [r0, #0]
	movs	r1, #5
.L080092b8:
	strb.w	r1, [sp, #0x17]
	add.w	r1, sp, #0x17
.L080092c0:
	mov.w	r2, #-1
	bl	queue_send_timeout
	b.n	.L08008ce6
.L080092ca:
	add	sp, #0x18
	vpop	{d8}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short	0x0000	@ padding
