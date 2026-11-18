@ ui_keys_68.s - key handlers fn_0800df58..fn_0800e630, send_state_message_sequence and fn_0803da50
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0800df58 - No parameters, no return value; returns at once unless
@ [0x20001060]==2.
@ Sets [0x20000128]=1.
@ If byte [0x2000010c]!=3: halfword [0x2000010c]=0x203, writes 0x40011410=4,
@ 0x40011010=4, 0x40011014=2 and sends byte 2 to queue [0x20002d78] with
@ queue_send_timeout(queue,&byte,0xffffffff).
@ Then [0x200000f8]=[0x200000fa]=0 and writes 0x40011414=0x1000,
@ 0x40011010=0x1000, 0x40011810=0x10, 0x40011814=0x20, 0x40011810=0x40.
@ Table select by [0x20000125]: >=5 lo=0x20000358 hi=0x20000394; ==4 or
@ [0x2000010c]==3 lo=0x2000036c hi=0x200003a8; else lo=0x20000380
@ hi=0x200003bc. Sets bits 0..11 of 0x40007408 to
@ (uint)((hi-lo)/200.0*([0x200000fc]+100)+lo) (VFP, halfword table values),
@ sets bit0 of 0x40007404, [0x200000fc]=0x9c, then sets bits 0..11 of
@ 0x40007408 to the lo value and bit0 of 0x40007404 again.
@ Then [0x200000f9]=[0x200000fb]=0, 0x40011414=0x2000, 0x40010810=0x8000,
@ 0x40010c10=0x800, 0x40010c14=0x400, 0x40010810=0x400.
@ Same scheme for 0x40001c34 with lo tables 0x200003d0/0x200003e4/0x200003f8,
@ hi tables 0x2000040c/0x20000420/0x20000434 and [0x200000fd]+100: writes the
@ computed value, [0x200000fd]=0x9c, then writes the lo value.
@ Sends bytes 4,5 to queue [0x20002d6c]; limits [0x20000ea8] to at most 2;
@ [0x20000125]=5; sends byte 1 to [0x20002d78]; clears bit0 of 0x40000400;
@ word [0x20000eac]=0x012d0000.
@ If [0x20000126]==0: sets it to 1 and for [0x20000ef4] and [0x20000ef8], when
@ nonzero, releases the buffer (callback (*[0x20001070])(0) if [0x20001080]==0,
@ else zero_bytes on the entry range in table [0x2000107c]) and clears the
@ pointer. Sends byte 2 to [0x20002d6c]; if [0x2000010f]!=1 sets it to 1 and
@ writes 0x40011014=0x10; halfword at 0x20000114=0xff9c; sends byte 6 to
@ [0x20002d6c] and byte 8 to [0x20002d78].
@ Purpose not determined from the code (the peripheral registers are not
@ identified).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800df58,"ax",%progbits
	.p2align 2
	.global fn_0800df58
	.thumb_func
	.type fn_0800df58, %function
fn_0800df58:
	push.w {r4, r5, r6, r7, r8, r9, r10, lr}
	movw r6, #0xf8
	movt r6, #0x2000
	ldrb.w r0, [r6, #0xf68]
	cmp r0, #2
	it ne
	popne.w {r4, r5, r6, r7, r8, r9, r10, pc}
	ldrb r1, [r6, #0x14]
	movw r5, #0x1414
	movw r9, #0x1010
	movw r10, #0x2d52
	movw r8, #0x2d78
	movt r5, #0x4001
	movt r9, #0x4001
	movs r0, #1
	cmp r1, #3
	movt r10, #0x2000
	movt r8, #0x2000
	strb.w r0, [r6, #0x30]
	beq.n .L0800dfea
	movw r0, #0x203
	movs r1, #4
	strh r0, [r6, #0x14]
	str.w r1, [r5, #-0x4]
	ldrb r0, [r6, #0x14]
	cmp r0, #3
	beq.n .L0800dfc4
	cmp r0, #2
	beq.n .L0800dfca
	cmp r0, #1
	bne.n .L0800dfd6
	movs r0, #4
	str.w r0, [r9, #0x0]
	movs r0, #2
	str.w r0, [r9, #0x0]
	b.n .L0800dfd6
.L0800dfc4:
	str.w r1, [r9, #0x0]
	b.n .L0800dfd0
.L0800dfca:
	movs r0, #4
	str.w r0, [r9, #0x4]
.L0800dfd0:
	movs r0, #2
	str.w r0, [r9, #0x4]
.L0800dfd6:
	movs r1, #2
	ldr.w r0, [r8, #0x0]
	strb.w r1, [r10, #0x0]
	mov r1, r10
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L0800dfea:
	movs r0, #0
	mov.w r1, #0x1000
	strb r0, [r6, #0x0]
	str r1, [r5, #0x0]
	strb r0, [r6, #0x2]
	movs r0, #0x10
	str.w r1, [r9, #0x0]
	str.w r0, [r5, #0x3fc]
	movw r0, #0x1814
	movt r0, #0x4001
	movs r1, #0x20
	str r1, [r0, #0x0]
	movs r0, #0x40
	str.w r0, [r5, #0x3fc]
	ldrb.w r1, [r6, #0x2d]
	cmp r1, #4
	bls.n .L0800e024
	add.w r0, r6, #0x29c
	add.w r1, r6, #0x260
	b.n .L0800e03e
.L0800e024:
	add.w r0, r6, #0x2b0
	cmp r1, #4
	add.w r1, r6, #0x274
	beq.n .L0800e03e
	ldrb r2, [r6, #0x14]
	cmp r2, #3
	itt ne
	addne.w r0, r6, #0x2c4
	addne.w r1, r6, #0x288
.L0800e03e:
	ldrh r0, [r0, #0x0]
	ldrh r1, [r1, #0x0]
	vldr s0, .L0800e2f0
	subs r0, r0, r1
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s2, s2, s0
	ldrsb.w r2, [r6, #0x4]
	movw r0, #0x7404
	adds r2, #0x64
	vmov s4, r2
	vcvt.f32.s32 s4, s4
	movt r0, #0x4000
	movs r3, #0x9c
	vmul.f32 s2, s2, s4
	vmov s4, r1
	vcvt.f32.u32 s4, s4
	vadd.f32 s2, s2, s4
	ldr r1, [r0, #0x4]
	vcvt.u32.f32 s2, s2
	vmov r2, s2
	lsrs r1, r1, #0xc
	bfi r2, r1, #0xc, #0x14
	str r2, [r0, #0x4]
	ldr r1, [r0, #0x0]
	orr r1, r1, #1
	str r1, [r0, #0x0]
	ldrb.w r2, [r6, #0x2d]
	ldrb r1, [r6, #0x2]
	cmp r2, #5
	strb r3, [r6, #0x4]
	bcc.n .L0800e0ac
	add.w r1, r6, r1, lsl #1
	add.w r1, r1, #0x260
	b.n .L0800e0c8
.L0800e0ac:
	cmp r2, #4
	beq.n .L0800e0c0
	ldrb r2, [r6, #0x14]
	cmp r2, #3
	beq.n .L0800e0c0
	add.w r1, r6, r1, lsl #1
	add.w r1, r1, #0x288
	b.n .L0800e0c8
.L0800e0c0:
	add.w r1, r6, r1, lsl #1
	add.w r1, r1, #0x274
.L0800e0c8:
	ldrh r1, [r1, #0x0]
	ldr r2, [r0, #0x4]
	bfi r2, r1, #0, #0xc
	str r2, [r0, #0x4]
	ldr r1, [r0, #0x0]
	mov.w r2, #0x400
	orr r1, r1, #1
	str r1, [r0, #0x0]
	movs r0, #0
	mov.w r1, #0x2000
	strb r0, [r6, #0x1]
	str r1, [r5, #0x0]
	strb r0, [r6, #0x3]
	movw r0, #0x810
	movt r0, #0x4001
	mov.w r1, #0x8000
	str r1, [r0, #0x0]
	mov.w r1, #0x800
	str.w r1, [r0, #0x400]
	movw r1, #0xfc04
	movt r1, #0xffff
	str.w r2, [r9, r1]
	str r2, [r0, #0x0]
	ldrb.w r1, [r6, #0x2d]
	cmp r1, #4
	bls.n .L0800e120
	add.w r0, r6, #0x314
	add.w r1, r6, #0x2d8
	b.n .L0800e13a
.L0800e120:
	add.w r0, r6, #0x328
	cmp r1, #4
	add.w r1, r6, #0x2ec
	beq.n .L0800e13a
	ldrb r2, [r6, #0x14]
	cmp r2, #3
	itt ne
	addne.w r0, r6, #0x33c
	addne.w r1, r6, #0x300
.L0800e13a:
	ldrh r0, [r0, #0x0]
	ldrh r1, [r1, #0x0]
	ldrsb.w r2, [r6, #0x5]
	subs r0, r0, r1
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s0, s2, s0
	adds r2, #0x64
	vmov s2, r2
	vcvt.f32.s32 s2, s2
	movw r0, #0x1c34
	movt r0, #0x4000
	movs r3, #0x9c
	vmul.f32 s0, s0, s2
	vmov s2, r1
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vstr s0, [r0]
	ldrb.w r2, [r6, #0x2d]
	ldrb r1, [r6, #0x3]
	cmp r2, #5
	strb r3, [r6, #0x5]
	bcc.n .L0800e192
	add.w r1, r6, r1, lsl #1
	add.w r1, r1, #0x2d8
	b.n .L0800e1ae
.L0800e192:
	cmp r2, #4
	beq.n .L0800e1a6
	ldrb r2, [r6, #0x14]
	cmp r2, #3
	beq.n .L0800e1a6
	add.w r1, r6, r1, lsl #1
	add.w r1, r1, #0x300
	b.n .L0800e1ae
.L0800e1a6:
	add.w r1, r6, r1, lsl #1
	add.w r1, r1, #0x2ec
.L0800e1ae:
	ldrh r1, [r1, #0x0]
	movw r7, #0x2d6c
	str r1, [r0, #0x0]
	movw r5, #0x2d53
	movt r7, #0x2000
	movt r5, #0x2000
	movs r1, #4
	ldr r0, [r7, #0x0]
	strb r1, [r5, #0x0]
	mov r1, r5
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r7, #0x0]
	movs r4, #5
	mov r1, r5
	mov.w r2, #0xffffffff
	strb r4, [r5, #0x0]
	bl queue_send_timeout
	ldrb.w r0, [r6, #0xdb0]
	mov r1, r10
	cmp r0, #3
	itt cs
	movcs r0, #2
	strbcs.w r0, [r6, #0xdb0]
	ldr.w r0, [r8, #0x0]
	strb.w r4, [r6, #0x2d]
	movs r4, #1
	mov.w r2, #0xffffffff
	strb.w r4, [r10, #0x0]
	bl queue_send_timeout
	movw r0, #0x400
	movt r0, #0x4000
	ldr r1, [r0, #0x0]
	bic r1, r1, #1
	str r1, [r0, #0x0]
	ldrb.w r0, [r6, #0x2e]
	movs r1, #0
	movt r1, #0x12d
	str.w r1, [r6, #0xdb4]
	cbnz r0, .L0800e2a0
	ldr.w r0, [r6, #0xdfc]
	strb.w r4, [r6, #0x2e]
	movw r4, #0x1070
	movt r4, #0x2000
	cbz r0, .L0800e26a
	ldrb r1, [r4, #0x10]
	cbz r1, .L0800e25e
	ldr r1, [r4, #0x8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800e264
	ldr r2, [r4, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800e264
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800e264
.L0800e25e:
	ldr r1, [r4, #0x0]
	movs r0, #0
	blx r1
.L0800e264:
	movs r0, #0
	str.w r0, [r6, #0xdfc]
.L0800e26a:
	ldr.w r0, [r6, #0xe00]
	cbz r0, .L0800e2a0
	ldrb r1, [r4, #0x10]
	cbz r1, .L0800e294
	ldr r1, [r4, #0x8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800e29a
	ldr r2, [r4, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800e29a
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800e29a
.L0800e294:
	ldr r1, [r4, #0x0]
	movs r0, #0
	blx r1
.L0800e29a:
	movs r0, #0
	str.w r0, [r6, #0xe00]
.L0800e2a0:
	movs r1, #2
	ldr r0, [r7, #0x0]
	strb r1, [r5, #0x0]
	mov r1, r5
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldrb r0, [r6, #0x17]
	cmp r0, #1
	beq.n .L0800e2c0
	movs r0, #1
	strb r0, [r6, #0x17]
	movs r0, #0x10
	str.w r0, [r9, #0x4]
.L0800e2c0:
	movw r0, #0xff9c
	strh r0, [r6, #0x1c]
	movs r1, #6
	ldr r0, [r7, #0x0]
	strb r1, [r5, #0x0]
	mov r1, r5
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr.w r0, [r8, #0x0]
	movs r3, #8
	mov r1, r10
	mov.w r2, #0xffffffff
	strb.w r3, [r10, #0x0]
	pop.w {r4, r5, r6, r7, r8, r9, r10, lr}
	b.w queue_send_timeout
	.byte 0x00, 0xbf	@ padding (never reached; aligns the literal below)
.L0800e2f0:
	.word 0x43480000	@ 200.0f

@ ----------------------------------------------------------------------------
@ fn_0800e2f4 - No parameters, no return value; sets the state byte
@ [0x20001060] to 1.
@ Per old state: 2 clears halfword [0x20002d50]; 5 or 6 clear halfword
@ [0x20000f14], [0x20000f0a] word, [0x20000f0e] halfword and byte
@ [0x20000f12]; 7 sets bit1 of 0x40005c40 and 0x40005c60 and then (like
@ 0,3,4,8 and others) continues; 9 clears [0x2000044d]; old state 1 returns
@ without change.
@ Then sets bit13 of 0x4000440c, calls fn_08041610([0x20002da0]) and
@ fn_08041610([0x20002da4]), writes 0x800 to 0x40011010,
@ [0x20001040]=[0x20001044]=[0x20001048]=0x7fc00000, halfword
@ [0x2000102d]=0x0101, [0x20001055]=0, [0x20001027]=0, [0x20001030]=0xff,
@ halfword [0x20001034]=0, halfword [0x20001024]=0xff, halfword
@ [0x20001061]=0, [0x20001063]=0, then tail-calls send_state_message_sequence.
@ Purpose: sets the state byte [0x20001060] to 1 (state byte written at
@ 0x0800e362; the meaning of the states is not determined from the code).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800e2f4,"ax",%progbits
	.p2align 2
	.global fn_0800e2f4
	.thumb_func
	.type fn_0800e2f4, %function
fn_0800e2f4:
	push {r4, lr}
	movw r4, #0xf8
	movt r4, #0x2000
	ldrb.w r0, [r4, #0xf68]
	subs r1, r0, #2
	cmp r1, #7
	bhi.n .L0800e352
	tbb [pc, r1]
.L0800e30c:
	.byte (.L0800e328 - .L0800e30c)/2
	.byte (.L0800e352 - .L0800e30c)/2
	.byte (.L0800e352 - .L0800e30c)/2
	.byte (.L0800e314 - .L0800e30c)/2
	.byte (.L0800e314 - .L0800e30c)/2
	.byte (.L0800e336 - .L0800e30c)/2
	.byte (.L0800e352 - .L0800e30c)/2
	.byte (.L0800e35a - .L0800e30c)/2
.L0800e314:
	movs r0, #0
	strh.w r0, [r4, #0xe1c]
	str.w r0, [r4, #0xe12]
	str.w r0, [r4, #0xe16]
	strb.w r0, [r4, #0xe1a]
	b.n .L0800e360
.L0800e328:
	movw r0, #0x2d50
	movt r0, #0x2000
	movs r1, #0
	strh r1, [r0, #0x0]
	b.n .L0800e360
.L0800e336:
	movw r0, #0x5c40
	movt r0, #0x4000
	ldr r1, [r0, #0x0]
	nop.w				@ USB stays powered (usb_ctl.s re-enumerates instead)
	str r1, [r0, #0x0]
	ldr r1, [r0, #0x20]
	nop.w				@ USB stays powered (usb_ctl.s re-enumerates instead)
	str r1, [r0, #0x20]
	ldrb.w r0, [r4, #0xf68]
.L0800e352:
	cmp r0, #1
	it eq
	popeq {r4, pc}
	b.n .L0800e360
.L0800e35a:
	movs r0, #0
	strb.w r0, [r4, #0x355]
.L0800e360:
	movs r0, #1
	strb.w r0, [r4, #0xf68]
	movw r0, #0x440c
	movt r0, #0x4000
	ldr r1, [r0, #0x0]
	orr r1, r1, #0x2000
	str r1, [r0, #0x0]
	movw r0, #0x2da0
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	bl fn_08041610
	movw r0, #0x2da4
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	bl fn_08041610
	movw r0, #0x1010
	movt r0, #0x4001
	mov.w r1, #0x800
	str r1, [r0, #0x0]
	movs r0, #0
	movt r0, #0x7fc0
	movw r1, #0x101
	str.w r0, [r4, #0xf48]
	str.w r0, [r4, #0xf4c]
	str.w r0, [r4, #0xf50]
	movs r0, #0
	strh.w r1, [r4, #0xf35]
	movs r1, #0xff
	strb.w r0, [r4, #0xf5d]
	strb.w r0, [r4, #0xf2f]
	strb.w r1, [r4, #0xf38]
	strh.w r0, [r4, #0xf3c]
	strh.w r1, [r4, #0xf2c]
	strh.w r0, [r4, #0xf69]
	strb.w r0, [r4, #0xf6b]
	pop.w {r4, lr}
	b.w send_state_message_sequence
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0800e3e4 - No parameters, no return value; sets the state byte
@ [0x20001060] to 2.
@ Old state 1: clears bit13 of 0x4000440c, calls fn_0804178c([0x20002da0]) and
@ fn_0804178c([0x20002da4]), writes 0x800 to 0x40011014, calls
@ semaphore_take_timeout([0x20002d7c],0) and queue_reset([0x20002d74],0),
@ [0x2000102e]=1, [0x20001040..48]=0x7fc00000, halfword [0x20001034]=0,
@ halfword [0x20001025]=0, [0x20001028]=0.
@ Old state 5 or 6: clears [0x20000f14] halfword, [0x20000f0a] word,
@ [0x20000f0e] halfword, [0x20000f12].
@ Old state 7: sets bit1 of 0x40005c40 and 0x40005c60.
@ Old state 9: clears [0x2000044d] and skips the same-state test.
@ Old state 2 returns without change.
@ Then halfword [0x20001061]=0, [0x20001063]=0, when [0x2000044c]&0xf is
@ nonzero halfword [0x20002d50]=0x3c00, tail-calls
@ send_state_message_sequence.
@ Purpose: sets the state byte [0x20001060] to 2 (the meaning of the states is
@ not determined from the code).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800e3e4,"ax",%progbits
	.p2align 2
	.global fn_0800e3e4
	.thumb_func
	.type fn_0800e3e4, %function
fn_0800e3e4:
	push {r4, r5, r7, lr}
	movw r4, #0xf8
	movt r4, #0x2000
	ldrb.w r0, [r4, #0xf68]
	subs r1, r0, #1
	cmp r1, #8
	bhi.n .L0800e4b8
	tbb [pc, r1]
.L0800e3fc:
	.byte (.L0800e41a - .L0800e3fc)/2
	.byte (.L0800e4b8 - .L0800e3fc)/2
	.byte (.L0800e4b8 - .L0800e3fc)/2
	.byte (.L0800e4b8 - .L0800e3fc)/2
	.byte (.L0800e406 - .L0800e3fc)/2
	.byte (.L0800e406 - .L0800e3fc)/2
	.byte (.L0800e49c - .L0800e3fc)/2
	.byte (.L0800e4b8 - .L0800e3fc)/2
	.byte (.L0800e4ec - .L0800e3fc)/2
	.byte 0x00	@ padding
.L0800e406:
	movs r0, #0
	strh.w r0, [r4, #0xe1c]
	str.w r0, [r4, #0xe12]
	str.w r0, [r4, #0xe16]
	strb.w r0, [r4, #0xe1a]
	b.n .L0800e4b4
.L0800e41a:
	movw r0, #0x440c
	movt r0, #0x4000
	ldr r1, [r0, #0x0]
	bic r1, r1, #0x2000
	str r1, [r0, #0x0]
	movw r0, #0x2da0
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	bl fn_0804178c
	movw r0, #0x2da4
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	bl fn_0804178c
	movw r0, #0x1014
	movt r0, #0x4001
	mov.w r1, #0x800
	str r1, [r0, #0x0]
	movw r0, #0x2d7c
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	movs r1, #0
	movs r5, #0
	bl semaphore_take_timeout
	movw r0, #0x2d74
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	movs r1, #0
	bl queue_reset
	movs r0, #1
	strb.w r0, [r4, #0xf36]
	movs r0, #0
	movt r0, #0x7fc0
	str.w r0, [r4, #0xf48]
	str.w r0, [r4, #0xf4c]
	str.w r0, [r4, #0xf50]
	strh.w r5, [r4, #0xf3c]
	strh.w r5, [r4, #0xf2d]
	str.w r5, [r4, #0xf30]
	b.n .L0800e4b4
.L0800e49c:
	movw r0, #0x5c40
	movt r0, #0x4000
	ldr r1, [r0, #0x0]
	nop.w				@ USB stays powered (usb_ctl.s re-enumerates instead)
	str r1, [r0, #0x0]
	ldr r1, [r0, #0x20]
	nop.w				@ USB stays powered (usb_ctl.s re-enumerates instead)
	str r1, [r0, #0x20]
.L0800e4b4:
	ldrb.w r0, [r4, #0xf68]
.L0800e4b8:
	cmp r0, #2
	it eq
	popeq {r4, r5, r7, pc}
.L0800e4be:
	ldrb.w r1, [r4, #0x354]
	movs r0, #2
	strb.w r0, [r4, #0xf68]
	movs r0, #0
	lsls r1, r1, #0x1c
	strh.w r0, [r4, #0xf69]
	strb.w r0, [r4, #0xf6b]
	beq.n .L0800e4e4
	movw r0, #0x2d50
	movt r0, #0x2000
	mov.w r1, #0x3c00
	strh r1, [r0, #0x0]
.L0800e4e4:
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800e4ec:
	movs r0, #0
	strb.w r0, [r4, #0x355]
	b.n .L0800e4be

@ ----------------------------------------------------------------------------
@ fn_0800e4f4 - No parameters, no return value; sets the state byte
@ [0x20001060] to 3.
@ Old state 1: same cleanup as fn_0800e3e4 (0x4000440c bit13, fn_0804178c on
@ [0x20002da0]/[0x20002da4], 0x40011014=0x800,
@ semaphore_take_timeout([0x20002d7c],0), queue_reset([0x20002d74],0),
@ [0x2000102e]=1, [0x20001040..48]=0x7fc00000, [0x20001034] halfword=0,
@ [0x20001025] halfword=0, [0x20001028]=0).
@ Old state 2: clears halfword [0x20002d50] and skips the same-state test.
@ Old state 5 or 6: clears [0x20000f14],[0x20000f0a],[0x20000f0e],
@ [0x20000f12].
@ Old state 7: sets bit1 of 0x40005c40 and 0x40005c60.
@ Old state 9: clears [0x2000044d] and skips the same-state test.
@ Old state 3 returns without change.
@ Then [0x20001063]=0 and writes the halfword at 0x20001061 as
@ min([0x20000f51],7)<<8 (byte 0x20001061=0, byte 0x20001062=
@ min([0x20000f51],7)), tail-calls send_state_message_sequence.
@ Purpose: sets the state byte [0x20001060] to 3 (the meaning of the states is
@ not determined from the code).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800e4f4,"ax",%progbits
	.p2align 2
	.global fn_0800e4f4
	.thumb_func
	.type fn_0800e4f4, %function
fn_0800e4f4:
	push {r4, r5, r7, lr}
	movw r4, #0xf8
	movt r4, #0x2000
	ldrb.w r0, [r4, #0xf68]
	subs r1, r0, #1
	cmp r1, #8
	bhi.n .L0800e5d6
	tbb [pc, r1]
.L0800e50c:
	.byte (.L0800e52a - .L0800e50c)/2
	.byte (.L0800e5ac - .L0800e50c)/2
	.byte (.L0800e5d6 - .L0800e50c)/2
	.byte (.L0800e5d6 - .L0800e50c)/2
	.byte (.L0800e516 - .L0800e50c)/2
	.byte (.L0800e516 - .L0800e50c)/2
	.byte (.L0800e5ba - .L0800e50c)/2
	.byte (.L0800e5d6 - .L0800e50c)/2
	.byte (.L0800e5de - .L0800e50c)/2
	.byte 0x00	@ padding
.L0800e516:
	movs r0, #0
	strh.w r0, [r4, #0xe1c]
	str.w r0, [r4, #0xe12]
	str.w r0, [r4, #0xe16]
	strb.w r0, [r4, #0xe1a]
	b.n .L0800e5d2
.L0800e52a:
	movw r0, #0x440c
	movt r0, #0x4000
	ldr r1, [r0, #0x0]
	bic r1, r1, #0x2000
	str r1, [r0, #0x0]
	movw r0, #0x2da0
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	bl fn_0804178c
	movw r0, #0x2da4
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	bl fn_0804178c
	movw r0, #0x1014
	movt r0, #0x4001
	mov.w r1, #0x800
	str r1, [r0, #0x0]
	movw r0, #0x2d7c
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	movs r1, #0
	movs r5, #0
	bl semaphore_take_timeout
	movw r0, #0x2d74
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	movs r1, #0
	bl queue_reset
	movs r0, #1
	strb.w r0, [r4, #0xf36]
	movs r0, #0
	movt r0, #0x7fc0
	str.w r0, [r4, #0xf48]
	str.w r0, [r4, #0xf4c]
	str.w r0, [r4, #0xf50]
	strh.w r5, [r4, #0xf3c]
	strh.w r5, [r4, #0xf2d]
	str.w r5, [r4, #0xf30]
	b.n .L0800e5d2
.L0800e5ac:
	movw r0, #0x2d50
	movt r0, #0x2000
	movs r1, #0
	strh r1, [r0, #0x0]
	b.n .L0800e5e4
.L0800e5ba:
	movw r0, #0x5c40
	movt r0, #0x4000
	ldr r1, [r0, #0x0]
	nop.w				@ USB stays powered (usb_ctl.s re-enumerates instead)
	str r1, [r0, #0x0]
	ldr r1, [r0, #0x20]
	nop.w				@ USB stays powered (usb_ctl.s re-enumerates instead)
	str r1, [r0, #0x20]
.L0800e5d2:
	ldrb.w r0, [r4, #0xf68]
.L0800e5d6:
	cmp r0, #3
	it eq
	popeq {r4, r5, r7, pc}
	b.n .L0800e5e4
.L0800e5de:
	movs r0, #0
	strb.w r0, [r4, #0x355]
.L0800e5e4:
	movs r0, #3
	ldrb.w r1, [r4, #0xe59]
	strb.w r0, [r4, #0xf68]
	movs r0, #0
	strh.w r0, [r4, #0xf69]
	strb.w r0, [r4, #0xf6b]
	cmp r1, #7
	it cs
	movcs r1, #7
	strb.w r1, [r4, #0xf6a]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0800e60c - No parameters, no return value; if [0x20001060]==2 toggles
@ byte [0x20000140] (0 becomes 1, otherwise 0), otherwise does nothing.
@ Purpose: flag toggle in state 2 (meaning of [0x20000140] not determined from
@ the code).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800e60c,"ax",%progbits
	.p2align 2
	.global fn_0800e60c
	.thumb_func
	.type fn_0800e60c, %function
fn_0800e60c:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #2
	it ne
	bxne lr
	ldrb.w r1, [r0, #0x48]
	clz r1, r1
	lsrs r1, r1, #5
	strb.w r1, [r0, #0x48]
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0800e630 - No parameters, no return value; if [0x20001060]==2 writes
@ [0x20001060]=5 and tail-calls send_state_message_sequence, otherwise does
@ nothing.
@ Purpose: sets the state byte [0x20001060] from 2 to 5 (the meaning of the
@ states is not determined from the code).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800e630,"ax",%progbits
	.p2align 2
	.global fn_0800e630
	.thumb_func
	.type fn_0800e630, %function
fn_0800e630:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #2
	it ne
	bxne lr
	movs r1, #5
	strb.w r1, [r0, #0xf68]
	b.w send_state_message_sequence

@ ----------------------------------------------------------------------------
@ send_state_message_sequence - No parameters, no return value.
@ Switch on [0x20001060]; each message is one byte sent with
@ queue_send_timeout(queue [0x20002d6c],&byte,0xffffffff).
@ case 0: 0,1,0xb,0xc,0xd,0xe,0xf,0x10,0x11
@ case 1: 0,9,X,0x1a,0x1b,0x1c,0x1d,0x1e
@ case 2: 2,3,4,5,6,8,9,X
@ case 3: 0,8,9,X,0x16,0x17,0x18,0x19
@ case 4: 0,0x1f,9,0x20,0x21 (word at 0x40011008 is read, unused)
@ case 5: 0,0x25,9,0x26,0x27,0x28 (0x40011008 read, unused)
@ case 6: 0x29
@ case 7: 0x15
@ case 8: 0,0x2c
@ case 9: 0,0x12,0x13,0x14,9,X
@ X is 7 when bit7 of the word at 0x40011008 is set, otherwise 10 (cases
@ 1,2,3,9). Other values send nothing.
@ Purpose: sends the message-code list belonging to the current state; the
@ receiver of queue [0x20002d6c] is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.send_state_message_sequence,"ax",%progbits
	.p2align 2
	.global send_state_message_sequence
	.thumb_func
	.type send_state_message_sequence, %function
send_state_message_sequence:
	push {r4, r5, r7, lr}
	sub sp, #8
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #9
	bhi.w .L08012cce
	movw r5, #0x2d6c
	movt r5, #0x2000
	tbh [pc, r0, lsl #1]
.L0801292a:
	.short (.L0801293e - .L0801292a)/2
	.short (.L080129d6 - .L0801292a)/2
	.short (.L08012a6c - .L0801292a)/2
	.short (.L08012ace - .L0801292a)/2
	.short (.L08012b64 - .L0801292a)/2
	.short (.L08012bbe - .L0801292a)/2
	.short (.L08012c2a - .L0801292a)/2
	.short (.L08012c2e - .L0801292a)/2
	.short (.L08012ca6 - .L0801292a)/2
	.short (.L08012c32 - .L0801292a)/2
.L0801293e:
	movs r1, #0
	ldr r0, [r5, #0x0]
	add.w r4, sp, #7
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #1
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0xb
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0xc
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0xd
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0xe
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0xf
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x10
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #0x11
	b.n .L08012cbc
.L080129d6:
	movs r1, #0
	ldr r0, [r5, #0x0]
	add.w r4, sp, #7
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #9
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movw r0, #0x1008
	movt r0, #0x4001
	ldr r0, [r0, #0x0]
	movs r1, #7
	lsls r0, r0, #0x18
	it pl
	movpl r1, #0xa
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x1a
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x1b
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x1c
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x1d
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #0x1e
	b.n .L08012cbc
.L08012a6c:
	movs r1, #2
	ldr r0, [r5, #0x0]
	add.w r4, sp, #7
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #3
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #4
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #5
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #6
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #8
	b.n .L08012c6e
.L08012ace:
	movs r1, #0
	ldr r0, [r5, #0x0]
	add.w r4, sp, #7
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #8
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #9
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movw r0, #0x1008
	movt r0, #0x4001
	ldr r0, [r0, #0x0]
	movs r1, #7
	lsls r0, r0, #0x18
	it pl
	movpl r1, #0xa
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x16
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x17
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x18
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #0x19
	b.n .L08012cbc
.L08012b64:
	movs r1, #0
	ldr r0, [r5, #0x0]
	add.w r4, sp, #7
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x1f
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #9
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movw r0, #0x1008
	movt r0, #0x4001
	ldr r0, [r0, #0x0]
	movs r1, #0x20
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #0x21
	b.n .L08012cbc
.L08012bbe:
	movs r1, #0
	ldr r0, [r5, #0x0]
	add.w r4, sp, #7
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x25
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #9
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movw r0, #0x1008
	movt r0, #0x4001
	ldr r0, [r0, #0x0]
	movs r1, #0x26
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x27
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #0x28
	b.n .L08012cbc
.L08012c2a:
	movs r0, #0x29
	b.n .L08012cbc
.L08012c2e:
	movs r0, #0x15
	b.n .L08012cbc
.L08012c32:
	movs r1, #0
	ldr r0, [r5, #0x0]
	add.w r4, sp, #7
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x12
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x13
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x14
.L08012c6e:
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #9
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movw r0, #0x1008
	movt r0, #0x4001
	ldr r0, [r0, #0x0]
	lsls r0, r0, #0x18
	mov.w r0, #7
	it pl
	movpl r0, #0xa
	b.n .L08012cbc
.L08012ca6:
	movs r1, #0
	ldr r0, [r5, #0x0]
	strb.w r1, [sp, #7]
	add.w r1, sp, #7
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #0x2c
.L08012cbc:
	strb.w r0, [sp, #7]
	ldr r0, [r5, #0x0]
	add.w r1, sp, #7
	mov.w r2, #0xffffffff
.L08012cca:
	bl queue_send_timeout
.L08012cce:
	add sp, #8
	pop {r4, r5, r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0803da50 - No parameters; never returns.
@ Loop: receives one byte into a local with queue_receive_timeout(*0x20002d6c,
@ &local,0) (timeout 0); when it returns 1 it calls the code pointer at
@ 0x0804be74+4*local (table of 45 pointers 0x0804be74..0x0804bf27, no bounds
@ check); otherwise calls fn_0804206c(*0x20002d80) and, when that returns 0 and
@ the byte 0x20001060 is 2, calls queue_send_timeout(*0x20002d80,0,0); then
@ receives again with queue_receive_timeout(*0x20002d6c,&local,0xffffffff)
@ (wait forever) and dispatches the byte when it returns 1, repeating
@ otherwise.
@ Purpose: task body that runs the handler selected by each queued byte.
@ This firmware: the table call is display_task_dispatch (usb_remote.s), which runs USB remote jobs
@ for code 0x80 and calls the same table entry for every other code (same size: bl, nop).
@ ----------------------------------------------------------------------------
	.section .text.fn_0803da50,"ax",%progbits
	.p2align 2
	.global fn_0803da50
	.thumb_func
	.type fn_0803da50, %function
fn_0803da50:
	sub sp, #8
	movw r5, #0x2d6c
	movw r6, #:lower16:d_0804be74
	movw r7, #0x2d80
	movw r8, #0xf8
	movt r5, #0x2000
	add.w r4, sp, #7
	movt r6, #:upper16:d_0804be74
	movt r7, #0x2000
	movt r8, #0x2000
	b.n .L0803da82
.L0803da78:
	ldrb.w r0, [sp, #0x7]
	bl	display_task_dispatch	@ usb_remote.s: USB remote jobs, then the same table entry
	nop
.L0803da82:
	ldr r0, [r5, #0x0]
	mov r1, r4
	movs r2, #0
	bl queue_receive_timeout
	cmp r0, #1
	beq.n .L0803da78
	ldr r0, [r7, #0x0]
	bl fn_0804206c
	cbnz r0, .L0803daaa
	ldrb.w r0, [r8, #0xf68]
	cmp r0, #2
	bne.n .L0803daaa
	ldr r0, [r7, #0x0]
	movs r1, #0
	movs r2, #0
	bl queue_send_timeout
.L0803daaa:
	ldr r0, [r5, #0x0]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_receive_timeout
	cmp r0, #1
	bne.n .L0803da82
	b.n .L0803da78
	.word 0x00000000	@ padding
