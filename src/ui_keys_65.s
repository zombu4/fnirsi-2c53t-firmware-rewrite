@ ui_keys_65.s - key-event handler on the state byte [0x20001060] (mirror of 0800b1f8).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0800b7cc - no parameters; acts on the state byte [0x20001060] (the mirror of
@ 0800b1f8). Dispatch through a tbh table, states above 9 return.
@ state 0: increments [0x20001061] (3 wraps to 0), sends 0xb, 0xc, 0xf, 0x10, 0x11
@   to queue [0x20002d6c] with queue_send_timeout (08041cf0).
@ state 1: returns when the high nibble of [0x20001055] is 0xb; idx = [0x20001025]+1
@   (7 wraps to 0), sends table byte 0x080bb3fc+idx plus 0x500 to queue [0x20002d74],
@   clears [0x20001055], sets [0x20001025] = idx, sends 0x1d and 0x1b, sets
@   [0x2000102e] (idx if 2 else 1), [0x20001040..48] = 0x7fc00000, clears
@   [0x20001034] / [0x20001035] (sends 0x1a when [0x20001035] was set), tail-calls
@   080098e0.
@ state 2: [0x2000044c] & 0xf = 1 or 2: 0803b2f8(1,0) then 08025fc0; = 3: raises by 1
@   a halfword selected by [0x20000332]: ==1 [0x2000032c] (not above 150), ==2
@   [0x20000330] (not above 100), ==3 [0x2000032c] when bit 7 of [0x2000044c] is set
@   else [0x2000032a] (not above 150), other values return; then calls
@   queue_send_timeout (queue [0x20002d80], 0, 0) and 08025fc0; = 0: when
@   [0x20000125] != 0 decrements it, recomputes 0x40007408 / 0x40007404 and 0x40001c34
@   from the halfword tables, when [0x20000126] != 0 programs registers 0x40000400 /
@   0x40000414 / 0x40000424..0x4000042c and [0x20000eac] (08031430, table 0x080465a4
@   for index >= 0x14), calls 08030a70 and 0803b2f8(0,0), writes 4 to 0x40011410,
@   sends 2 to queue [0x20002d6c] and 1 to queue [0x20002d78], then 08025fc0.
@ state 3: when [0x20001061] == 2 and [0x20001063] >= 0x10 subtracts 0x10, sends 0x19.
@ state 4: when [0x20001061] == 1 and [0x20001062] & 0xf == 1 raises byte [0x2000105a]
@   by 1 when it is at most 9 ([0x20001063] == 0) or otherwise byte [0x20001059] by 5
@   when it is at most 99 (written to 0x40015034), sends 0x21.
@ state 5: raises [0x20000f15] below [0x20000f13]-1, sends 0x27, 0x28.
@ state 6: same with code 0x29.
@ state 9: raises [0x20001063] by 0x40 or 4, sends 0x14.
@ Other states return. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800b7cc,"ax",%progbits
	.p2align 2
	.global fn_0800b7cc
	.thumb_func
	.type fn_0800b7cc, %function
fn_0800b7cc:
	push	{r4, r5, r6, r7, lr}
	sub	sp, #0x14
	movw	r5, #0xf8
	movt	r5, #0x2000
	ldrb.w	r0, [r5, #0xf68]	@ state byte [0x20001060]
	cmp	r0, #0x9
	bhi.w	.L0800bb7c
	tbh	[pc, r0, lsl #1]
.L0800b7e6:
	.short (.L0800b7fa - .L0800b7e6)/2	@ state 0
	.short (.L0800b8ac - .L0800b7e6)/2	@ state 1
	.short (.L0800b97e - .L0800b7e6)/2	@ state 2
	.short (.L0800b9c0 - .L0800b7e6)/2	@ state 3
	.short (.L0800b9f0 - .L0800b7e6)/2	@ state 4
	.short (.L0800b868 - .L0800b7e6)/2	@ state 5
	.short (.L0800ba2c - .L0800b7e6)/2	@ state 6
	.short (.L0800bb7c - .L0800b7e6)/2	@ state 7
	.short (.L0800bb7c - .L0800b7e6)/2	@ state 8
	.short (.L0800ba60 - .L0800b7e6)/2	@ state 9
.L0800b7fa:
	ldrb.w	r0, [r5, #0xf69]
	movs	r1, #0x0
	cmp	r0, #0x3
	it	cc
	addcc	r1, r0, #0x1
	strb.w	r1, [r5, #0xf69]
	movw	r5, #0x2d6c
	movw	r4, #0x2d53
	movt	r5, #0x2000
	movt	r4, #0x2000
	movs	r1, #0xb
	ldr	r0, [r5]
	strb	r1, [r4]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #0xc
	ldr	r0, [r5]
	strb	r1, [r4]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #0xf
	ldr	r0, [r5]
	strb	r1, [r4]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #0x10
	ldr	r0, [r5]
	strb	r1, [r4]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	ldr	r0, [r5]
	movs	r3, #0x11
.L0800b85e:
	mov	r1, r4
	mov.w	r2, #0xffffffff
	strb	r3, [r4]
	b.n	.L0800bb04
.L0800b868:
	ldrb.w	r0, [r5, #0xe1c]
	cmp	r0, #0x0
	bne.w	.L0800bb7c
	ldrb.w	r0, [r5, #0xe1d]
	ldrb.w	r1, [r5, #0xe1b]
	adds	r0, #0x1
	cmp	r0, r1
	bcs.w	.L0800bb7c
	strb.w	r0, [r5, #0xe1d]
	movw	r5, #0x2d6c
	movw	r4, #0x2d53
	movt	r5, #0x2000
	movt	r4, #0x2000
	movs	r1, #0x27
	ldr	r0, [r5]
	strb	r1, [r4]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	ldr	r0, [r5]
	movs	r3, #0x28
	b.n	.L0800b85e
.L0800b8ac:
	ldrb.w	r0, [r5, #0xf5d]
	and.w	r0, r0, #0xf0
	cmp	r0, #0xb0
	beq.w	.L0800bb7c
	ldrb.w	r0, [r5, #0xf2d]
	movs	r1, #0x0
	movw	r2, #:lower16:d_080bb3fc
	cmp	r0, #0x7
	it	cc
	addcc	r1, r0, #0x1
	uxtb	r0, r1
	movt	r2, #:upper16:d_080bb3fc
	ldrb	r0, [r2, r0]
	strb.w	r1, [r5, #0xf2d]
	movw	r1, #0x2d54
	add.w	r0, r0, #0x500
	movt	r1, #0x2000
	strh	r0, [r1]
	movw	r0, #0x2d74
	movt	r0, #0x2000
	ldr	r0, [r0]
	movs	r6, #0x0
	mov.w	r2, #0xffffffff
	strb.w	r6, [r5, #0xf5d]
	bl	queue_send_timeout
	movw	r7, #0x2d6c
	movw	r4, #0x2d53
	movt	r7, #0x2000
	movt	r4, #0x2000
	movs	r1, #0x1d
	ldr	r0, [r7]
	strb	r1, [r4]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #0x1b
	ldr	r0, [r7]
	strb	r1, [r4]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	ldrb.w	r0, [r5, #0xf2d]
	ldrb.w	r1, [r5, #0xf3c]
	cmp	r0, #0x2
	it	ne
	movne	r0, #0x1
	strb.w	r0, [r5, #0xf36]
	movs	r0, #0x0
	movt	r0, #0x7fc0
	str.w	r0, [r5, #0xf48]
	str.w	r0, [r5, #0xf4c]
	cmp	r1, #0x0
	str.w	r0, [r5, #0xf50]
	it	ne
	strbne.w	r6, [r5, #0xf3c]
	ldrb.w	r0, [r5, #0xf3d]
	cbz	r0, .L0800b974
	movs	r0, #0x0
	strb.w	r0, [r5, #0xf3d]
	movs	r1, #0x1a
	ldr	r0, [r7]
	strb	r1, [r4]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
.L0800b974:
	add	sp, #0x14
	pop.w	{r4, r5, r6, r7, lr}
	b.w	fn_080098e0
.L0800b97e:
	ldrb.w	r0, [r5, #0x354]
	and.w	r1, r0, #0xf
	subs	r2, r1, #0x1
	cmp	r2, #0x2
	bcc.n	.L0800ba8a
	cmp	r1, #0x3
	beq.w	.L0800baa8
	cmp	r1, #0x0
	bne.w	.L0800bb7c
	ldrb.w	r0, [r5, #0x2d]
	cmp	r0, #0x0
	beq.w	.L0800bb7c
	subs	r2, r0, #0x1
	uxtb	r1, r2
	ldrb	r0, [r5, #0x2]
	cmp	r1, #0x5
	strb.w	r2, [r5, #0x2d]
	bcc.w	.L0800bb0e
	add.w	r1, r5, r0, lsl #0x1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L0800bb8c
.L0800b9c0:
	ldrb.w	r0, [r5, #0xf69]
	cmp	r0, #0x2
	bne.w	.L0800bb7c
	ldrb.w	r0, [r5, #0xf6b]
	cmp	r0, #0x10
	bcc.w	.L0800bb7c
	subs	r0, #0x10
	strb.w	r0, [r5, #0xf6b]
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movw	r1, #0x2d53
	ldr	r0, [r0]
	movt	r1, #0x2000
	movs	r3, #0x19
	b.n	.L0800bafe
.L0800b9f0:
	ldrb.w	r0, [r5, #0xf69]
	cmp	r0, #0x1
	bne.w	.L0800bb7c
	ldrb.w	r0, [r5, #0xf6a]
	and.w	r0, r0, #0xf
	cmp	r0, #0x1
	bne.w	.L0800bb7c
	ldrb.w	r0, [r5, #0xf6b]
	cmp	r0, #0x0
	beq.n	.L0800badc
	ldrb.w	r0, [r5, #0xf61]
	cmp	r0, #0x63
	bhi.w	.L0800bb7c
	movw	r1, #0x5034
	adds	r0, #0x5
	movt	r1, #0x4001
	strb.w	r0, [r5, #0xf61]
	str	r0, [r1]
	b.n	.L0800baea
.L0800ba2c:
	ldrb.w	r0, [r5, #0xe1c]
	cmp	r0, #0x0
	bne.w	.L0800bb7c
	ldrb.w	r0, [r5, #0xe1d]
	ldrb.w	r1, [r5, #0xe1b]
	adds	r0, #0x1
	cmp	r0, r1
	bcs.w	.L0800bb7c
	strb.w	r0, [r5, #0xe1d]
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movw	r1, #0x2d53
	ldr	r0, [r0]
	movt	r1, #0x2000
	movs	r3, #0x29
	b.n	.L0800bafe
.L0800ba60:
	ldrb.w	r0, [r5, #0xf69]
	cmp	r0, #0x2
	beq.n	.L0800ba94
	cmp	r0, #0x1
	bne.w	.L0800bb7c
	ldrb.w	r0, [r5, #0xf6a]
	and.w	r0, r0, #0xf
	cmp	r0, #0x7
	bne.w	.L0800bb7c
	ldrb.w	r0, [r5, #0xf6b]
	subs	r1, r0, #0x1
	cmp	r1, #0x3
	bhi.n	.L0800bb7c
	adds	r0, #0x4
	b.n	.L0800bac2
.L0800ba8a:
	movs	r0, #0x1
	movs	r1, #0x0
	bl	fn_0803b2f8
	b.n	.L0800bd50
.L0800ba94:
	ldrb.w	r0, [r5, #0xf6b]
	and.w	r1, r0, #0xf0
	cmp	r1, #0xc0
	bne.n	.L0800baba
	movs	r1, #0xd
	bfi	r0, r1, #0x4, #0x1c
	b.n	.L0800bac2
.L0800baa8:
	ldrb.w	r1, [r5, #0x23a]
	cmp	r1, #0x3
	beq.n	.L0800bb40
	cmp	r1, #0x2
	beq.n	.L0800bb26
	cmp	r1, #0x1
	bne.n	.L0800bb7c
	b.n	.L0800bb5e
.L0800baba:
	sxtb	r1, r0
	cmp	r1, #0x0
	bmi.n	.L0800bb7c
	adds	r0, #0x40
.L0800bac2:
	strb.w	r0, [r5, #0xf6b]
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movw	r1, #0x2d53
	ldr	r0, [r0]
	movt	r1, #0x2000
	movs	r3, #0x14
	b.n	.L0800bafe
.L0800badc:
	ldrb.w	r0, [r5, #0xf62]
	cmp	r0, #0x9
	bhi.n	.L0800bb7c
	adds	r0, #0x1
	strb.w	r0, [r5, #0xf62]
.L0800baea:
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movw	r1, #0x2d53
	ldr	r0, [r0]
	movt	r1, #0x2000
	movs	r3, #0x21
.L0800bafe:
	mov.w	r2, #0xffffffff
	strb	r3, [r1]
.L0800bb04:
	add	sp, #0x14
	pop.w	{r4, r5, r6, r7, lr}
	b.w	queue_send_timeout
.L0800bb0e:
	cmp	r1, #0x4
	beq.n	.L0800bb80
	ldrb	r1, [r5, #0x14]
	cmp	r1, #0x3
	beq.n	.L0800bb80
	add.w	r1, r5, r0, lsl #0x1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L0800bb8c
.L0800bb26:
	ldrsh.w	r0, [r5, #0x238]
	cmp	r0, #0x63
	bgt.n	.L0800bb7c
	adds	r1, r0, #0x1
	movw	r0, #0x2d80
	movt	r0, #0x2000
	ldr	r0, [r0]
	strh.w	r1, [r5, #0x238]
	b.n	.L0800bb76
.L0800bb40:
	lsls	r0, r0, #0x18
	bmi.n	.L0800bb5e
	ldrsh.w	r0, [r5, #0x232]
	cmp	r0, #0x95
	bgt.n	.L0800bb7c
	adds	r1, r0, #0x1
	movw	r0, #0x2d80
	movt	r0, #0x2000
	ldr	r0, [r0]
	strh.w	r1, [r5, #0x232]
	b.n	.L0800bb76
.L0800bb5e:
	ldrsh.w	r0, [r5, #0x234]
	cmp	r0, #0x95
	bgt.n	.L0800bb7c
	adds	r1, r0, #0x1
	movw	r0, #0x2d80
	movt	r0, #0x2000
	ldr	r0, [r0]
	strh.w	r1, [r5, #0x234]
.L0800bb76:
	movs	r1, #0x0
	movs	r2, #0x0
	b.n	.L0800bd4c
.L0800bb7c:
	add	sp, #0x14
	pop	{r4, r5, r6, r7, pc}
.L0800bb80:
	add.w	r1, r5, r0, lsl #0x1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L0800bb8c:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	vldr	s0, .L0800bd5c
	subs	r0, r0, r1
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vdiv.f32	s2, s2, s0
	ldrsb.w	r0, [r5, #0x4]
	adds	r0, #0x64
	vmov	s4, r0
	vcvt.f32.s32	s4, s4
	movw	r0, #0x7404
	movt	r0, #0x4000
	vmul.f32	s2, s2, s4
	vmov	s4, r1
	vcvt.f32.u32	s4, s4
	vadd.f32	s2, s2, s4
	ldr	r1, [r0, #0x4]
	vcvt.u32.f32	s2, s2
	vmov	r2, s2
	lsrs	r1, r1, #0xc
	bfi	r2, r1, #0xc, #0x14
	str	r2, [r0, #0x4]
	ldr	r1, [r0]
	orr.w	r1, r1, #0x1
	str	r1, [r0]
	ldrb.w	r1, [r5, #0x2d]
	ldrb	r0, [r5, #0x3]
	cmp	r1, #0x5
	bcc.n	.L0800bbfa
	add.w	r1, r5, r0, lsl #0x1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L0800bc1e
.L0800bbfa:
	cmp	r1, #0x4
	beq.n	.L0800bc12
	ldrb	r1, [r5, #0x14]
	cmp	r1, #0x3
	beq.n	.L0800bc12
	add.w	r1, r5, r0, lsl #0x1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L0800bc1e
.L0800bc12:
	add.w	r1, r5, r0, lsl #0x1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L0800bc1e:
	ldrh	r0, [r0]
	ldrh	r1, [r1]
	subs	r0, r0, r1
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	vdiv.f32	s0, s2, s0
	ldrsb.w	r0, [r5, #0x5]
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
	ldrb.w	r0, [r5, #0x2e]
	cmp	r0, #0x0
	beq.n	.L0800bcfc
	ldrb.w	r0, [r5, #0x2d]
	cmp	r0, #0x14
	bcc.n	.L0800bcd8
	movw	r0, #0x12d
	movw	r4, #0x400
	str.w	r0, [r5, #0xdb4]
	movs	r6, #0x0
	mov	r0, sp
	movt	r4, #0x4000
	str	r6, [sp, #0x10]
	strd	r6, r6, [sp, #0x8]
	strd	r6, r6, [sp]
	bl	compute_clock_frequencies
	ldrb.w	r0, [r5, #0x2d]
	subs	r0, #0x14
	uxtb	r1, r0
	cmp	r1, #0x8
	bhi.n	.L0800bccc
	ldr	r1, [sp, #0x4]
	movw	r2, #0x1759
	movt	r2, #0xd1b7
	umull	r1, r2, r1, r2
	movw	r1, #:lower16:d_080465a4
	sxtb	r0, r0
	movt	r1, #:upper16:d_080465a4
	ldr.w	r0, [r1, r0, lsl #0x2]
	mov.w	r1, #0xffffffff
	add.w	r1, r1, r2, lsr #0xd
	str	r0, [r4, #0x2c]
	str	r1, [r4, #0x28]
	ldr	r0, [r4, #0x14]
	orr.w	r0, r0, #0x1
	str	r0, [r4, #0x14]
.L0800bccc:
	str	r6, [r4, #0x24]
	ldr	r0, [r4]
	orr.w	r0, r0, #0x1
	str	r0, [r4]
	b.n	.L0800bcfc
.L0800bcd8:
	movw	r0, #0x400
	movt	r0, #0x4000
	ldr	r1, [r0]
	bic.w	r1, r1, #0x1
	str	r1, [r0]
	ldrb	r0, [r5, #0x17]
	cmp	r0, #0x1
	itee	ne
	movwne	r0, #0x12d
	moveq	r0, #0x0
	movteq	r0, #0x12d
	str.w	r0, [r5, #0xdb4]
.L0800bcfc:
	bl	fn_08030a70
	movs	r0, #0x0
	movs	r1, #0x0
	bl	fn_0803b2f8
	movw	r0, #0x1410
	movt	r0, #0x4001
	movs	r1, #0x4
	str	r1, [r0]
	movw	r0, #0x2d6c
	movw	r1, #0x2d53
	movt	r0, #0x2000
	movt	r1, #0x2000
	ldr	r0, [r0]
	movs	r2, #0x2
	strb	r2, [r1]
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movw	r0, #0x2d78
	movw	r1, #0x2d52
	movt	r0, #0x2000
	movt	r1, #0x2000
	movs	r2, #0x1
	ldr	r0, [r0]
	strb	r2, [r1]
	mov.w	r2, #0xffffffff
.L0800bd4c:
	bl	queue_send_timeout
.L0800bd50:
	add	sp, #0x14
	pop.w	{r4, r5, r6, r7, lr}
	b.w	fn_08025fc0
	.short 0xbf00	@ padding (never reached; aligns the literal below)
.L0800bd5c:
	.word 0x43480000	@ 200.0f
	.size fn_0800b7cc, . - fn_0800b7cc
