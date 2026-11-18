@ ui_keys_63.s - fn_0800a148: key handler that raises values, dispatched on the state byte [0x20001060].
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0800a148 - No parameters. Function on the state byte [0x20001060] that
@ raises values (the mirror of 0800a900, which lowers them). Queue sends use
@ 08041cf0 (queue_send_timeout) as (queue, &item, 0xffffffff).
@ State 1: when [0x20001025]==5 and the high nibble of [0x20001055]==0xb, sends
@   halfword 0x508 to queue [0x20002d74]; otherwise clears [0x20001055] unless
@   its high nibble is 0xb.
@ State 2: switch on [0x2000044c]&0xf with ch=[0x2000044c]>>7:
@  0: increments counter [0x200000fa+ch] (stops at 9; reaching 5 sets
@     [0x20000eb3]=10), re-applies with 08008a58([0x200000fb]) (ch 1) or
@     080088a4([0x200000fa]), sends 4 and calls 08025fc0, then only when
@     [0x2000010e]==ch (otherwise returns) rescales halfword [0x20000114] with
@     the float table at 0x0800a8f4 indexed by counter%3 (clamped +-100) and
@     sends 8 to queue [0x20002d78] when [0x2000010f]==2 and [0x20000126]!=0,
@     sends 6 when [0x2000012c]==0.
@  1: increments offset byte [0x200000fc+ch] (max 100), recomputes 0x40001c34
@     or 0x40007408/0x40007404 from the halfword tables (0x200003a8/0x2000036c,
@     0x200003bc/0x20000380, 0x20000394/0x20000358 and 0x20000420/0x200003e4,
@     0x20000434/0x200003f8, 0x2000040c/0x200003d0), sets [0x20000124]=100 (and
@     [0x20000eac]=0x12d when [0x20000125]>0x13) when [0x20000126]!=0, calls
@     08041cf0(queue [0x20002d80],0,0), sends 5 when [0x2000012c]==0, then when
@     [0x2000010e]==ch and [0x20000114]<100 increments [0x20000114], sends 8 to
@     queue [0x20002d78] when [0x2000010f]==2 and [0x20000126]!=0 and 6 when
@     [0x2000012c]==0.
@  2: increments halfword [0x20000114] to at most 100, sets [0x20000122]=300,
@     calls 08041cf0(queue [0x20002d80],0,0), then sends 8 to queue
@     [0x20002d78] when [0x2000010f]==2 and [0x20000126]!=0 and 6 when
@     [0x2000012c]==0.
@  3: increments by 1 a halfword selected by [0x20000332]: ==1 [0x2000032a] (not
@     above 150), ==2 [0x2000032e] (not above 100), ==3 [0x20000330] when bit7
@     of [0x2000044c] is set else [0x2000032e] (not above 100), other values
@     return; then 08025fc0.
@ State 3: sub-state [0x20001061]:
@  2: adds a term from [0x20001063]>>4 (0804550a, 080438e0, 08044fac) to
@     [0x20000f59] (low nibble 2, limit 0x1e), [0x20000f58] (nibble 1, limit
@     100) or word [0x20000f54] (nibble 0, limit 50000) chosen by
@     [0x20001063]&0xf, then calls 08029e14 for nibbles 1 and 2 or 08029d40
@     for nibble 0 (other nibbles call neither).
@  1: returns when [0x20001063]==0, else [0x20001063] becomes [0x20001063]-1
@     when [0x20000f51]-1<2 and 0 otherwise.
@  0: returns when [0x20000f51]==0, else decrements it, lowers [0x20001062] to
@     it when above, sends 8,0x17,0x18,0x19 and tail-calls 08029e14.
@  Sub-states 1 and 2 then send 0x19.
@ State 4 (system settings menu, items 0..5): sub 0 moves the item
@   [0x20001062] up to 0, sub 1 lowers the value [0x20001063] to 0; codes
@   0x20,0x21.
@ State 5: [0x20000f14]==0 lowers [0x20000f15] by 3 (min 0), sends 0x27,0x28;
@   ==2 sets [0x20000f14]=1, sends 0x2a.
@ State 6: [0x20000f14]==2 sets 1, sends 0x2a.
@ State 8: returns (V1.2.0: the language page, decremented byte [0x20001058]
@   (min 1) and sent 0x2c; there is no language page any more).
@ State 9: edits [0x20001061..63] downward with codes 0x13,0x14.
@ Other states return. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800a148,"ax",%progbits
	.p2align 2
	.global fn_0800a148
	.thumb_func
	.type fn_0800a148, %function
fn_0800a148:
	push	{r4, r5, r6, r7, lr}
	sub	sp, #4
	vpush	{d8}
	movw	r5, #0xf8
	movt	r5, #0x2000
	ldrb.w	r0, [r5, #0xf68]		@ state byte [0x20001060]
	subs	r0, #1
	cmp	r0, #8
	bhi.w	.L0800a8ca
	tbh	[pc, r0, lsl #1]
.L0800a168:
	.short	(.L0800a17a - .L0800a168)/2	@ state 1
	.short	(.L0800a19c - .L0800a168)/2	@ state 2
	.short	(.L0800a1ee - .L0800a168)/2	@ state 3
	.short	(.L0800a280 - .L0800a168)/2	@ state 4
	.short	(.L0800a2d6 - .L0800a168)/2	@ state 5
	.short	(.L0800a31a - .L0800a168)/2	@ state 6
	.short	(.L0800a8ca - .L0800a168)/2	@ state 7: return
	.short	(.L0800a8ca - .L0800a168)/2	@ state 8: return (no such page; V1.2.0: language page)
	.short	(.L0800a366 - .L0800a168)/2	@ state 9
.L0800a17a:
	ldrb.w	r0, [r5, #0xf2d]
	ldrb.w	r1, [r5, #0xf5d]
	cmp	r0, #5
	and.w	r0, r1, #0xf0
	it	eq
	cmpeq	r0, #0xb0
	beq.w	.L0800a3ca
	cmp	r0, #0xb0
	itt	ne
	movne	r0, #0
	strbne.w	r0, [r5, #0xf5d]
	b.n	.L0800a8ca
.L0800a19c:
	ldrb.w	r0, [r5, #0x354]
	and.w	r1, r0, #0xf
	cmp	r1, #3
	bhi.w	.L0800a8ca
	tbh	[pc, r1, lsl #1]
.L0800a1ae:
	.short	(.L0800a1b6 - .L0800a1ae)/2
	.short	(.L0800a4d4 - .L0800a1ae)/2
	.short	(.L0800a50c - .L0800a1ae)/2
	.short	(.L0800a53c - .L0800a1ae)/2
.L0800a1b6:
	add.w	r0, r5, r0, lsr #7
	ldrb.w	r1, [r0, #2]!
	cmp	r1, #8
	bhi.w	.L0800a8ca
	adds	r1, #1
	strb	r1, [r0, #0]
	ldrb.w	r0, [r5, #0x354]
	add.w	r1, r5, r0, lsr #7
	ldrb	r1, [r1, #2]
	sxtb	r0, r0
	cmp	r1, #5
	itt	eq
	moveq	r1, #0xa
	strbeq.w	r1, [r5, #0xdbb]
	cmp.w	r0, #0xffffffff
	ble.w	.L0800a642
	ldrb	r0, [r5, #2]
	bl	fn_080088a4
	b.n	.L0800a648
.L0800a1ee:
	ldrb.w	r0, [r5, #0xf69]
	cmp	r0, #2
	beq.w	.L0800a40e
	cmp	r0, #1
	beq.w	.L0800a46e
	cmp	r0, #0
	bne.w	.L0800a8ca
	ldrb.w	r0, [r5, #0xe59]
	cmp	r0, #0
	beq.w	.L0800a8ca
	subs	r0, #1
	ldrb.w	r1, [r5, #0xf6a]
	uxtb	r2, r0
	cmp	r1, r2
	strb.w	r0, [r5, #0xe59]
	it	hi
	strbhi.w	r0, [r5, #0xf6a]
	movw	r5, #0x2d6c
	movw	r4, #0x2d53
	movt	r5, #0x2000
	movt	r4, #0x2000
	movs	r1, #8
	ldr	r0, [r5, #0]
	strb	r1, [r4, #0]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #0x17
	ldr	r0, [r5, #0]
	strb	r1, [r4, #0]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #0x18
	ldr	r0, [r5, #0]
	strb	r1, [r4, #0]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #0x19
	ldr	r0, [r5, #0]
	strb	r1, [r4, #0]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	vpop	{d8}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, lr}
	b.w	fill_output_waveform_table
.L0800a280:
	ldrb.w	r0, [r5, #0xf69]
	cmp	r0, #1
	beq.w	.L0800a3e8
	cmp	r0, #0
	bne.w	.L0800a8ca
	ldrb.w	r0, [r5, #0xf6a]
	lsls	r1, r0, #0x1c
	beq.w	.L0800a8ca
	subs	r1, r0, #1
	uxtb	r2, r1
	and.w	r3, r1, #0xf
	cmp.w	r3, r2, lsr #4
	it	cc
	subcc.w	r1, r0, #0x11
	strb.w	r1, [r5, #0xf6a]
	movw	r5, #0x2d6c
	movw	r4, #0x2d53
	movt	r5, #0x2000
	movt	r4, #0x2000
	movs	r1, #0x20
	ldr	r0, [r5, #0]
	strb	r1, [r4, #0]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	ldr	r0, [r5, #0]
	movs	r3, #0x21
	b.n	.L0800a3c0
.L0800a2d6:
	ldrb.w	r0, [r5, #0xe1c]
	cmp	r0, #2
	beq.n	.L0800a324
	cmp	r0, #0
	bne.w	.L0800a8ca
	ldrb.w	r0, [r5, #0xe1d]
	cmp	r0, #3
	bcc.w	.L0800a8ca
	subs	r0, #3
	strb.w	r0, [r5, #0xe1d]
	movw	r5, #0x2d6c
	movw	r4, #0x2d53
	movt	r5, #0x2000
	movt	r4, #0x2000
	movs	r1, #0x27
	ldr	r0, [r5, #0]
	strb	r1, [r4, #0]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	ldr	r0, [r5, #0]
	movs	r3, #0x28
	b.n	.L0800a3c0
.L0800a31a:
	ldrb.w	r0, [r5, #0xe1c]
	cmp	r0, #2
	bne.w	.L0800a8ca
.L0800a324:
	movs	r0, #1
	strb.w	r0, [r5, #0xe1c]
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movw	r1, #0x2d53
	ldr	r0, [r0, #0]
	movt	r1, #0x2000
	movs	r3, #0x2a
	b.n	.L0800a616
.L0800a366:
	ldrb.w	r0, [r5, #0xf69]
	cmp	r0, #2
	beq.w	.L0800a48c
	cmp	r0, #1
	beq.w	.L0800a4ac
	cmp	r0, #0
	bne.w	.L0800a8ca
	ldrb.w	r0, [r5, #0xf6a]
	lsls	r1, r0, #0x1c
	beq.w	.L0800a8ca
	subs	r1, r0, #1
	uxtb	r2, r1
	and.w	r3, r1, #0xf
	cmp.w	r3, r2, lsr #4
	it	cc
	subcc.w	r1, r0, #0x11
	strb.w	r1, [r5, #0xf6a]
	movw	r5, #0x2d6c
	movw	r4, #0x2d53
	movt	r5, #0x2000
	movt	r4, #0x2000
	movs	r1, #0x13
	ldr	r0, [r5, #0]
	strb	r1, [r4, #0]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	ldr	r0, [r5, #0]
	movs	r3, #0x14
.L0800a3c0:
	mov	r1, r4
	mov.w	r2, #0xffffffff
	strb	r3, [r4, #0]
	b.n	.L0800a61c
.L0800a3ca:
	movw	r0, #0x2d74
	movw	r1, #0x2d54
	movt	r0, #0x2000
	movt	r1, #0x2000
	ldr	r0, [r0, #0]
	mov.w	r3, #0x508
	mov.w	r2, #0xffffffff
	strh	r3, [r1, #0]
	b.n	.L0800a61c
.L0800a3e8:
	ldrb.w	r0, [r5, #0xf6b]
	cmp	r0, #0
	beq.w	.L0800a8ca
	subs	r0, #1
	strb.w	r0, [r5, #0xf6b]
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movw	r1, #0x2d53
	ldr	r0, [r0, #0]
	movt	r1, #0x2000
	movs	r3, #0x21
	b.n	.L0800a616
.L0800a40e:
	ldrb.w	r0, [r5, #0xf6b]
	and.w	r1, r0, #0xf
	cmp	r1, #2
	beq.w	.L0800a560
	cmp	r1, #1
	beq.w	.L0800a59e
	cmp	r1, #0
	bne.w	.L0800a5de
	lsrs	r0, r0, #4
	bl	i32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L0800a7d8
	bl	double_pow
	ldr.w	r0, [r5, #0xe5c]
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	bl	u32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_add
	bl	double_to_u32
	movw	r1, #0xc350
	cmp	r0, r1
	it	cc
	movcc	r1, r0
	str.w	r1, [r5, #0xe5c]
	bl	fn_08029d40
	b.n	.L0800a5de
.L0800a46e:
	ldrb.w	r0, [r5, #0xf6b]
	cmp	r0, #0
	beq.w	.L0800a8ca
	ldrb.w	r1, [r5, #0xe59]
	movs	r2, #0
	subs	r1, #1
	cmp	r1, #2
	it	cc
	subcc	r2, r0, #1
	strb.w	r2, [r5, #0xf6b]
	b.n	.L0800a5de
.L0800a48c:
	ldrb.w	r0, [r5, #0xf6b]
	movs	r1, #0
	cmp.w	r1, r0, lsr #4
	beq.w	.L0800a8ca
	lsrs	r1, r0, #4
	cmp	r1, #8
	beq.w	.L0800a5f4
	cmp	r1, #4
	bne.w	.L0800a5fc
	movs	r1, #0xc
	b.n	.L0800a5f6
.L0800a4ac:
	ldrb.w	r0, [r5, #0xf6b]
	cmp	r0, #0
	beq.w	.L0800a8ca
	ldrb.w	r1, [r5, #0xf6a]
	subs	r0, #1
	and.w	r1, r1, #0xf
	subs	r1, #7
	uxtb	r2, r0
	it	ne
	movne	r1, r0
	cmp	r2, #4
	it	ne
	movne	r1, r0
	strb.w	r1, [r5, #0xf6b]
	b.n	.L0800a602
.L0800a4d4:
	add.w	r0, r5, r0, lsr #7
	ldrsb.w	r1, [r0, #4]!
	cmp	r1, #0x63
	bgt.w	.L0800a8ca
	adds	r1, #1
	strb	r1, [r0, #0]
	ldrsb.w	r0, [r5, #0x354]
	cmp.w	r0, #0xffffffff
	ble.w	.L0800a70c
	ldrb.w	r1, [r5, #0x2d]
	ldrb	r0, [r5, #2]
	cmp	r1, #5
	bcc.w	.L0800a724
	add.w	r1, r5, r0, lsl #1
	add.w	r0, r1, #0x29c
	add.w	r1, r1, #0x260
	b.n	.L0800a77e
.L0800a50c:
	ldrsh.w	r0, [r5, #0x1c]
	cmp	r0, #0x63
	bgt.w	.L0800a8ca
	adds	r0, #1
	strh	r0, [r5, #0x1c]
	movw	r0, #0x2d80
	movt	r0, #0x2000
	mov.w	r1, #0x12c
	ldr	r0, [r0, #0]
	strh	r1, [r5, #0x2a]
	movs	r1, #0
	movs	r2, #0
	bl	queue_send_timeout
	ldrb	r0, [r5, #0x17]
	cmp	r0, #2
	beq.w	.L0800a8a0
	b.n	.L0800a8c4
.L0800a53c:
	ldrb.w	r1, [r5, #0x23a]
	cmp	r1, #3
	beq.n	.L0800a62a
	cmp	r1, #2
	beq.n	.L0800a630
	cmp	r1, #1
	bne.w	.L0800a8ca
	ldrsh.w	r0, [r5, #0x232]
	cmp	r0, #0x95
	bgt.w	.L0800a8ca
	adds	r0, #1
	strh.w	r0, [r5, #0x232]
	b.n	.L0800a74c
.L0800a560:
	lsrs	r0, r0, #4
	bl	i32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L0800a8e8
	bl	double_pow
	ldrb.w	r0, [r5, #0xe61]
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	bl	u32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_add
	bl	double_to_i32
	cmp	r0, #0x1e
	it	cs
	movcs	r0, #0x1e
	strb.w	r0, [r5, #0xe61]
	b.n	.L0800a5da
.L0800a59e:
	lsrs	r0, r0, #4
	bl	i32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L0800a8e8
	bl	double_pow
	ldrb.w	r0, [r5, #0xe60]
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	bl	u32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_add
	bl	double_to_i32
	cmp	r0, #0x64
	it	cs
	movcs	r0, #0x64
	strb.w	r0, [r5, #0xe60]
.L0800a5da:
	bl	fill_output_waveform_table
.L0800a5de:
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movw	r1, #0x2d53
	ldr	r0, [r0, #0]
	movt	r1, #0x2000
	movs	r3, #0x19
	b.n	.L0800a616
.L0800a5f4:
	movs	r1, #0xd
.L0800a5f6:
	bfi	r0, r1, #4, #0x1c
	b.n	.L0800a5fe
.L0800a5fc:
	subs	r0, #0x10
.L0800a5fe:
	strb.w	r0, [r5, #0xf6b]
.L0800a602:
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movw	r1, #0x2d53
	ldr	r0, [r0, #0]
	movt	r1, #0x2000
	movs	r3, #0x14
.L0800a616:
	mov.w	r2, #0xffffffff
	strb	r3, [r1, #0]
.L0800a61c:
	vpop	{d8}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, lr}
	b.w	queue_send_timeout
.L0800a62a:
	lsls	r0, r0, #0x18
	bmi.w	.L0800a73c
.L0800a630:
	ldrsh.w	r0, [r5, #0x236]
	cmp	r0, #0x63
	bgt.w	.L0800a8ca
	adds	r0, #1
	strh.w	r0, [r5, #0x236]
	b.n	.L0800a74c
.L0800a642:
	ldrb	r0, [r5, #3]
	bl	fn_08008a58
.L0800a648:
	movw	r7, #0x2d6c
	movw	r4, #0x2d53
	movt	r7, #0x2000
	movt	r4, #0x2000
	movs	r1, #4
	ldr	r0, [r7, #0]
	strb	r1, [r4, #0]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	bl	fn_08025fc0
	ldrb	r0, [r5, #0x16]
	ldrb.w	r1, [r5, #0x354]
	cmp.w	r0, r1, lsr #7
	bne.w	.L0800a8ca
	add	r0, r5
	ldrsb.w	r2, [r0, #4]
	ldrb	r0, [r0, #2]
	movw	r3, #0xaaab
	movt	r3, #0xaaaa
	umull	r3, r6, r0, r3
	ldrh	r1, [r5, #0x1c]
	lsrs	r3, r6, #1
	add.w	r3, r3, r3, lsl #1
	subs	r1, r1, r2
	subs	r0, r0, r3
	adr	r3, .L0800a8f4
	sxth	r1, r1
	add.w	r0, r3, r0, lsl #2
	vldr	s0, [r0]
	vmov	s2, r1
	vcvt.f32.s32	s2, s2
	vdiv.f32	s0, s2, s0
	vcvt.s32.f32	s0, s0
	vmov	r0, s0
	add	r0, r2
	sxth	r1, r0
	cmp	r1, #0x64
	it	ge
	movge	r0, #0x64
	sxth	r1, r0
	cmn.w	r1, #0x64
	ldrb	r1, [r5, #0x17]
	it	le
	mvnle	r0, #0x63
	cmp	r1, #2
	strh	r0, [r5, #0x1c]
	bne.n	.L0800a6fc
	ldrb.w	r0, [r5, #0x2e]
	cbz	r0, .L0800a6fc
	movw	r0, #0x2d78
	movw	r1, #0x2d52
	movt	r0, #0x2000
	movt	r1, #0x2000
	movs	r2, #8
	ldr	r0, [r0, #0]
	strb	r2, [r1, #0]
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
.L0800a6fc:
	ldrb.w	r0, [r5, #0x34]
	cmp	r0, #0
	bne.w	.L0800a8ca
	ldr	r0, [r7, #0]
	movs	r3, #6
	b.n	.L0800a3c0
.L0800a70c:
	ldrb.w	r1, [r5, #0x2d]
	ldrb	r0, [r5, #3]
	cmp	r1, #5
	bcc.n	.L0800a75a
	add.w	r1, r5, r0, lsl #1
	add.w	r0, r1, #0x314
	add.w	r1, r1, #0x2d8
	b.n	.L0800a7ec
.L0800a724:
	cmp	r1, #4
	beq.n	.L0800a772
	ldrb	r1, [r5, #0x14]
	cmp	r1, #3
	beq.n	.L0800a772
	add.w	r1, r5, r0, lsl #1
	add.w	r0, r1, #0x2c4
	add.w	r1, r1, #0x288
	b.n	.L0800a77e
.L0800a73c:
	ldrsh.w	r0, [r5, #0x238]
	cmp	r0, #0x63
	bgt.w	.L0800a8ca
	adds	r0, #1
	strh.w	r0, [r5, #0x238]
.L0800a74c:
	vpop	{d8}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, lr}
	b.w	fn_08025fc0
.L0800a75a:
	cmp	r1, #4
	beq.n	.L0800a7e0
	ldrb	r1, [r5, #0x14]
	cmp	r1, #3
	beq.n	.L0800a7e0
	add.w	r1, r5, r0, lsl #1
	add.w	r0, r1, #0x33c
	add.w	r1, r1, #0x300
	b.n	.L0800a7ec
.L0800a772:
	add.w	r1, r5, r0, lsl #1
	add.w	r0, r1, #0x2b0
	add.w	r1, r1, #0x274
.L0800a77e:
	ldrh	r0, [r0, #0]
	ldrh	r1, [r1, #0]
	vldr	s2, .L0800a8f0
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s2
	ldrsb.w	r0, [r5, #4]
	adds	r0, #0x64
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	movw	r0, #0x7404
	movt	r0, #0x4000
	vmul.f32	s0, s0, s2
	vmov	s2, r1
	vcvt.f32.u32	s2, s2
	vadd.f32	s0, s0, s2
	ldr	r1, [r0, #4]
	vcvt.u32.f32	s0, s0
	vmov	r2, s0
	lsrs	r1, r1, #0xc
	bfi	r2, r1, #0xc, #0x14
	str	r2, [r0, #4]
	ldr	r1, [r0, #0]
	orr.w	r1, r1, #1
	str	r1, [r0, #0]
	b.n	.L0800a830
	.byte	0x00, 0xbf			@ padding
.L0800a7d8:
	.word	0x00000000			@ double 10.0, low word
	.word	0x40240000			@ double 10.0, high word
.L0800a7e0:
	add.w	r1, r5, r0, lsl #1
	add.w	r0, r1, #0x328
	add.w	r1, r1, #0x2ec
.L0800a7ec:
	ldrh	r0, [r0, #0]
	ldrh	r1, [r1, #0]
	vldr	s2, .L0800a8f0
	subs	r0, r0, r1
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vdiv.f32	s0, s0, s2
	ldrsb.w	r0, [r5, #5]
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
.L0800a830:
	ldrb.w	r0, [r5, #0x2e]
	cbz	r0, .L0800a84c
	ldrb.w	r0, [r5, #0x2d]
	movs	r1, #0x64
	cmp	r0, #0x14
	strb.w	r1, [r5, #0x2c]
	itt	cs
	movwcs	r0, #0x12d
	strcs.w	r0, [r5, #0xdb4]
.L0800a84c:
	movw	r0, #0x2d80
	movt	r0, #0x2000
	ldr	r0, [r0, #0]
	movs	r1, #0
	movs	r2, #0
	bl	queue_send_timeout
	ldrb.w	r0, [r5, #0x34]
	cbnz	r0, .L0800a882
	movw	r0, #0x2d6c
	movw	r1, #0x2d53
	movt	r0, #0x2000
	movt	r1, #0x2000
	movs	r2, #5
	ldr	r0, [r0, #0]
	strb	r2, [r1, #0]
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
.L0800a882:
	ldrb.w	r0, [r5, #0x354]
	ldrb	r1, [r5, #0x16]
	cmp.w	r1, r0, lsr #7
	bne.n	.L0800a8ca
	ldrsh.w	r0, [r5, #0x1c]
	cmp	r0, #0x63
	bgt.n	.L0800a8ca
	ldrb	r1, [r5, #0x17]
	adds	r0, #1
	cmp	r1, #2
	strh	r0, [r5, #0x1c]
	bne.n	.L0800a8c4
.L0800a8a0:
	ldrb.w	r0, [r5, #0x2e]
	cbz	r0, .L0800a8c4
	movw	r0, #0x2d78
	movw	r1, #0x2d52
	movt	r0, #0x2000
	movt	r1, #0x2000
	movs	r2, #8
	ldr	r0, [r0, #0]
	strb	r2, [r1, #0]
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
.L0800a8c4:
	ldrb.w	r0, [r5, #0x34]
	cbz	r0, .L0800a8d2
.L0800a8ca:
	vpop	{d8}
	add	sp, #4
	pop	{r4, r5, r6, r7, pc}
.L0800a8d2:
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	movw	r1, #0x2d53
	ldr	r0, [r0, #0]
	movt	r1, #0x2000
	movs	r3, #6
	b.n	.L0800a616
.L0800a8e8:
	.word	0x00000000			@ double 10.0, low word
	.word	0x40240000			@ double 10.0, high word
.L0800a8f0:
	.word	0x43480000			@ float 200.0
.L0800a8f4:
	.word	0x40000000			@ float 2.0
	.word	0x40000000			@ float 2.0
	.word	0x40200000			@ float 2.5
