@ ui_keys_66.s - key-driven menu state machine on the state byte [0x20001060] (fn_0800bd60) and the unit that follows it in group 75.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0800bd60 - No parameters; function on the state byte [0x20001060].
@ Layout used by the callers: [0x20001060]=state, [0x20001061]=sub,
@ [0x20001062]=item, [0x20001063]=value. r5 holds 0x200000f8 throughout (so
@ [r5,#0xf68] is [0x20001060]).
@ state 0: sets state=[0x20001061]+1, clears [0x20001063] and halfword
@   [0x20001061]; old sub 2 loads [0x20001062]=min([0x20000f51],7);
@   old sub 1 sets [0x20002d50]=0x3c00 when [0x2000044c]&0xf!=0;
@   old sub 0 sets bit13 of 0x4000440c, calls 08041610 on [0x20002da0] and
@   [0x20002da4], writes 0x800 to 0x40011010, sets [0x20001040..48]=0x7fc00000,
@   [0x2000102d]=0x101, clears [0x20001055], [0x20001027], [0x20001034..35],
@   sets [0x20001030]=0xff and [0x20001024..25]=0xff; then 08012908.
@ state 1: returns when high nibble of [0x20001055] is 0xb; clears it, toggles
@   [0x20001034], sends 0x1c.
@ state 2: toggles [0x20000126]; setting it releases the buffers [0x20000ef4]
@   and [0x20000ef8] (call [0x20001070](0) when [0x20001080]==0, else when
@   (p-[0x20001078])>>10 is below 0xaf and the halfword entry
@   [0x2000107c]+((p-[0x20001078])>>5)*2 is nonzero, zeroes entry*2 bytes
@   starting at that entry with zero_bytes 080082bc) and selects [0x20000eac]
@   by [0x2000010f]/[0x20000125]; clearing it calls 0803b078; may program
@   0x40000400, 0x40000414, 0x40000424..0x4000042c (08031430, table 0x080465a4)
@   and copies 0x2000044e.. to 0x200006a8.. and 0x2000057b.. to 0x20000aa8..;
@   sends 2.
@ state 3: advances [0x20001061] (wraps to 1 with [0x20001063]&=0xf), sends 0x19.
@ state 4: sub-state advance on [0x20001062]&0xf; at sub 2 applies the item:
@   0 sets byte [0x20001058]=[0x20001063]+1 (sends 0x1f,0x20), 2/3 store
@   [0x20001063] into [0x2000105c]/[0x2000105d], 4 sets state 7 and calls
@   08012908, 6 with value 0 calls 080293bc(0) (never returns); sends 0x21.
@ state 5: [0x20000f14]==2 clears it and sends 0x26,0x28; ==1 sends 0,0x2b,
@   sets state 5, calls 08012908 and stores state 0xb; ==0 toggles bit
@   ([0x20000f15]%6) in the byte table 0x20000f0a.. (or enters state 6 when
@   [0x20000f12]==0 and [0x20000f13]!=0) and sends 0x28.
@ state 6: [0x20000f14]==2 clears it and sets state 5; ==1 sends 0x2b, runs
@   08012908 with state 5 then stores state 0xc.
@ state 7: sets state 4, sets bit1 of 0x40005c40 and 0x40005c60, calls 08012908.
@ state 8: sets state 0 and calls 08012908.
@ state 9: sub>=2 edits bit masks of the word [0x20000144] (item high nibble
@   [0x20001063]>>4: 0xd clears halves, 0xc sets 0xfff, else toggles bit) and
@   sends 0x14; sub<2 advances sub and at 2 applies item [0x20001062]&0xf:
@   0 toggles [0x2000012c] and releases the list at [0x20000138], 1 toggles
@   bits of [0x20000332] (calls 08025fc0), 2 none, 3/4 change the channel
@   enable [0x2000010c] and the sample copies at 0x200000c8.., then 08030a70
@   and writes to 0x40011410/0x40011010/0x40011014, 5 changes
@   [0x2000010f]/[0x20000110]/[0x2000010e] and the registers 0x40000400/
@   0x40000414/0x40000424..0x4000042c (sends 1,6,7 or 8 to queue [0x20002d78]),
@   6 manages the list [0x20000134], 7 toggles [0x2000012d].
@ other states return. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800bd60,"ax",%progbits
	.p2align 2
	.global fn_0800bd60
	.thumb_func
	.type fn_0800bd60, %function
fn_0800bd60:
	push.w {r4, r5, r6, r7, r8, lr}
	sub sp, #0x18
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #0x9
	bhi.w .L0800c5a8
	tbh [pc, r0, lsl #1]
.L0800bd7c:
	.short (.L0800bd90 - .L0800bd7c)/2
	.short (.L0800be24 - .L0800bd7c)/2
	.short (.L0800be5e - .L0800bd7c)/2
	.short (.L0800be74 - .L0800bd7c)/2
	.short (.L0800be86 - .L0800bd7c)/2
	.short (.L0800c11c - .L0800bd7c)/2
	.short (.L0800c1a4 - .L0800bd7c)/2
	.short (.L0800bf08 - .L0800bd7c)/2
	.short (.L0800c1e6 - .L0800bd7c)/2
	.short (.L0800bf28 - .L0800bd7c)/2
.L0800bd90:
	ldrb.w r0, [r5, #0xf69]
	adds r1, r0, #1
	strb.w r1, [r5, #0xf68]
	movs r1, #0
	cmp r0, #2
	strb.w r1, [r5, #0xf6b]
	strh.w r1, [r5, #0xf69]
	beq.w .L0800c2a6
	cmp r0, #1
	beq.w .L0800c2b6
	cmp r0, #0
	bne.w .L0800c392
	movw r0, #0x440c
	movt r0, #0x4000
	ldr r1, [r0]
	orr.w r1, r1, #0x2000
	str r1, [r0]
	movw r0, #0x2da0
	movt r0, #0x2000
	ldr r0, [r0]
	bl fn_08041610
	movw r0, #0x2da4
	movt r0, #0x2000
	ldr r0, [r0]
	bl fn_08041610
	movw r0, #0x1010
	movt r0, #0x4001
	mov.w r1, #0x800
	str r1, [r0]
	movs r0, #0
	movt r0, #0x7fc0
	movw r1, #0x101
	str.w r0, [r5, #0xf48]
	str.w r0, [r5, #0xf4c]
	str.w r0, [r5, #0xf50]
	movs r0, #0
	strh.w r1, [r5, #0xf35]
	movs r1, #0xff
	strb.w r0, [r5, #0xf5d]
	strb.w r0, [r5, #0xf2f]
	strb.w r1, [r5, #0xf38]
	strh.w r0, [r5, #0xf3c]
	strh.w r1, [r5, #0xf2c]
	b.n .L0800c392
.L0800be24:
	ldrb.w r0, [r5, #0xf5d]
	and.w r0, r0, #0xf0
	cmp r0, #0xb0
	beq.w .L0800c5a8
	ldrb.w r1, [r5, #0xf3c]
	movs r0, #0
	strb.w r0, [r5, #0xf5d]
	clz r0, r1
	lsrs r0, r0, #5
	strb.w r0, [r5, #0xf3c]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x1c
	b.w .L0800cb38
.L0800be5e:
	ldrb.w r0, [r5, #0x2e]
	cmp r0, #0
	beq.w .L0800c252
	movs r0, #0
	strb.w r0, [r5, #0x2e]
	bl fn_0803b078
	b.n .L0800c3f4
.L0800be74:
	ldrb.w r0, [r5, #0xf69]
	cmp r0, #1
	bhi.w .L0800c1ee
	adds r0, #1
	strb.w r0, [r5, #0xf69]
	b.n .L0800c200
.L0800be86:
	ldrb.w r2, [r5, #0xf69]
	cmp r2, #1
	bhi.w .L0800c5a8
	ldrb.w r0, [r5, #0xf6a]
	and.w r0, r0, #0xf
	subs r1, r0, #5
	it ne
	addne r1, r2, #1
	cmp r0, #6
	strb.w r1, [r5, #0xf69]
	it eq
	cmpeq r1, #1
	beq.w .L0800c346
	cmp r1, #2
	bne.w .L0800c58a
	cmp r0, #6
	bhi.w .L0800c58a
	tbh [pc, r0, lsl #1]
.L0800bebc:
	.short (.L0800beca - .L0800bebc)/2
	.short (.L0800bf04 - .L0800bebc)/2
	.short (.L0800c554 - .L0800bebc)/2
	.short (.L0800c560 - .L0800bebc)/2
	.short (.L0800c56c - .L0800bebc)/2
	.short (.L0800c58a - .L0800bebc)/2
	.short (.L0800c57a - .L0800bebc)/2
.L0800beca:
	ldrb.w r0, [r5, #0xf6b]
	movw r6, #0x2d6c
	adds r0, #1
	movw r4, #0x2d53
	movt r6, #0x2000
	strb.w r0, [r5, #0xf60]
	movt r4, #0x2000
	movs r1, #0x1f
	ldr r0, [r6]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x20
	ldr r0, [r6]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L0800bf04:
	movs r0, #1
	b.n .L0800c586
.L0800bf08:
	movs r0, #4
	strb.w r0, [r5, #0xf68]
	movw r0, #0x5c40
	movt r0, #0x4000
	ldr r1, [r0]
	orr.w r1, r1, #2
	str r1, [r0]
	ldr r1, [r0, #0x20]
	orr.w r1, r1, #2
	str r1, [r0, #0x20]
	b.n .L0800c392
.L0800bf28:
	ldrb.w r0, [r5, #0xf69]
	cmp r0, #1
	bhi.w .L0800c218
	adds r0, #1
	cmp r0, #2
	strb.w r0, [r5, #0xf69]
	bne.w .L0800cb24
	ldrb.w r3, [r5, #0xf6a]
	and.w r0, r3, #0xf
	cmp r0, #2
	beq.w .L0800cb24
	cmp r0, #7
	bhi.w .L0800cb1e
	tbh [pc, r0, lsl #1]
.L0800bf56:
	.short (.L0800c5ae - .L0800bf56)/2
	.short (.L0800c5c0 - .L0800bf56)/2
	.short (.L0800cb1e - .L0800bf56)/2
	.short (.L0800bf66 - .L0800bf56)/2
	.short (.L0800bf66 - .L0800bf56)/2
	.short (.L0800c5d8 - .L0800bf56)/2
	.short (.L0800c64c - .L0800bf56)/2
	.short 0x03d6
.L0800bf66:
	ldrb.w r1, [r5, #0xf6b]
	cmp r1, #4
	bhi.w .L0800cb1e
	tbh [pc, r1, lsl #1]
.L0800bf74:
	.short (.L0800bf7e - .L0800bf74)/2
	.short (.L0800c82e - .L0800bf74)/2
	.short (.L0800c836 - .L0800bf74)/2
	.short (.L0800c85e - .L0800bf74)/2
	.short (.L0800c826 - .L0800bf74)/2
.L0800bf7e:
	ldrb r1, [r5, #0x14]
	subs r2, r0, #2
	tst r2, r1
	beq.w .L0800c8ec
	rsb.w r2, r0, #1
	ands r1, r2
	strb r1, [r5, #0x14]
	subs r1, r0, #3
	adds r0, r5, r1
	ldrb r0, [r0, #4]
	eor.w r2, r0, #0x80
	movw r0, #0x12d
	smlabb r1, r1, r0, r5
	strb.w r2, [r1, #0x356]
	movs r1, #0
	adds r2, r5, #4
.L0800bfaa:
	and.w r3, r3, #0xf
	adds r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x30]
	ldrb.w r3, [r5, #0xf6a]
	cmp.w r1, #0x120
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x2f]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x2e]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x2d]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x2c]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x2b]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x2a]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x29]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x28]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x27]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x26]
	ldrb.w r3, [r5, #0xf6a]
	and.w r3, r3, #0xf
	add.w r7, r3, r2
	ldrb.w r7, [r7, #-3]
	smlabb r3, r3, r0, r1
	eor.w r7, r7, #0x80
	add r3, r5
	strb.w r7, [r3, #-0x25]
	beq.w .L0800c8f2
	ldrb.w r3, [r5, #0xf6a]
	adds r1, #0xc
	b.n .L0800bfaa
.L0800c11c:
	ldrb.w r0, [r5, #0xe1c]
	cmp r0, #2
	beq.w .L0800c2ce
	cmp r0, #1
	beq.w .L0800c304
	cmp r0, #0
	bne.w .L0800c5a8
	ldrb.w r0, [r5, #0xe1a]
	cmp r0, #0
	beq.w .L0800c382
	ldrb.w r1, [r5, #0xe1d]
	movw r2, #0xaaab
	uxtb r0, r1
	movt r2, #0xaaaa
	umull r0, r2, r0, r2
	lsrs r3, r2, #2
	add.w r7, r5, r2, lsr #2
	sub.w r2, r3, r3, lsl #2
	add.w r1, r1, r2, lsl #1
	ldrb.w r0, [r7, #0xe12]
	uxtb r1, r1
	movs r2, #1
	lsls r2, r1
	tst r2, r0
	addw r1, r7, #0xe12
	beq.w .L0800c53a
	bics r0, r2
	strb r0, [r1]
	ldrb.w r0, [r5, #0xe1a]
	cmp r0, #2
	bne.w .L0800c53e
	movs r0, #1
	strb.w r0, [r5, #0xe1a]
	movw r0, #0x2d6c
	movw r1, #0x2d53
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #0x26
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	b.n .L0800c53e
.L0800c1a4:
	ldrb.w r0, [r5, #0xe1c]
	cmp r0, #2
	beq.n .L0800c298
	cmp r0, #1
	bne.w .L0800c5a8
	movw r0, #0x2d6c
	movw r1, #0x2d53
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #0x2b
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #5
	strb.w r0, [r5, #0xf68]
	bl send_state_message_sequence
	movs r0, #0xc
	strb.w r0, [r5, #0xf68]
	add sp, #0x18
	pop.w {r4, r5, r6, r7, r8, pc}
.L0800c1e6:
	movs r0, #0
	strb.w r0, [r5, #0xf68]
	b.n .L0800c392
.L0800c1ee:
	ldrb.w r1, [r5, #0xf6b]
	movs r0, #1
	strb.w r0, [r5, #0xf69]
	and.w r0, r1, #0xf
	strb.w r0, [r5, #0xf6b]
.L0800c200:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x19
	b.w .L0800cb38
.L0800c218:
	ldrb.w r1, [r5, #0xf6b]
	movs r0, #0xd
	cmp.w r0, r1, lsr #4
	beq.w .L0800c34e
	lsrs r2, r1, #4
	cmp r2, #0xc
	bne.w .L0800c364
	ldr r0, [r5, #0x4c]
	lsls r1, r1, #0x1c
	beq.w .L0800c50a
	movw r1, #0xfff
	cmp.w r1, r0, lsr #16
	beq.w .L0800c5a8
	uxth r0, r0
	orr.w r0, r0, #0xf000000
	orr.w r0, r0, #0xff0000
	str r0, [r5, #0x4c]
	b.w .L0800cb24
.L0800c252:
	ldr.w r1, [r5, #0xdfc]
	movs r0, #1
	cmp r1, #0
	strb.w r0, [r5, #0x2e]
	beq.w .L0800c3a8
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cmp r2, #0
	beq.w .L0800c39c
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.w .L0800c3a2
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	beq.w .L0800c3a2
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800c3a2
.L0800c298:
	movs r0, #0
	strb.w r0, [r5, #0xe1c]
	movs r0, #5
	strb.w r0, [r5, #0xf68]
	b.n .L0800c392
.L0800c2a6:
	ldrb.w r0, [r5, #0xe59]
	cmp r0, #6
	it hi
	movhi r0, #7
	strb.w r0, [r5, #0xf6a]
	b.n .L0800c392
.L0800c2b6:
	ldrb.w r0, [r5, #0x354]
	lsls r0, r0, #0x1c
	beq.n .L0800c392
	movw r0, #0x2d50
	movt r0, #0x2000
	mov.w r1, #0x3c00
	strh r1, [r0]
	b.n .L0800c392
.L0800c2ce:
	movs r0, #0
	strb.w r0, [r5, #0xe1c]
	movw r5, #0x2d6c
	movw r4, #0x2d53
	movt r5, #0x2000
	movt r4, #0x2000
	movs r1, #0x26
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x28
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	b.w .L0800cb3e
.L0800c304:
	movw r6, #0x2d6c
	movw r4, #0x2d53
	movt r6, #0x2000
	movt r4, #0x2000
	movs r1, #0
	ldr r0, [r6]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x2b
	ldr r0, [r6]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #5
	strb.w r0, [r5, #0xf68]
	bl send_state_message_sequence
	movs r0, #0xb
	strb.w r0, [r5, #0xf68]
	b.n .L0800c5a8
.L0800c346:
	movs r0, #1
	strb.w r0, [r5, #0xf6b]
	b.n .L0800c58a
.L0800c34e:
	ldr r0, [r5, #0x4c]
	lsls r1, r1, #0x1c
	beq.w .L0800c51c
	cmp.w r0, #0x10000
	bcc.w .L0800c5a8
	uxth r0, r0
	str r0, [r5, #0x4c]
	b.n .L0800cb24
.L0800c364:
	ldr r0, [r5, #0x4c]
	lsls r1, r1, #0x1c
	beq.w .L0800c526
	lsrs r1, r0, #0x10
	lsrs r1, r2
	add.w r3, r2, #0x10
	movs r7, #1
	lsls r1, r1, #0x1f
	lsl.w r1, r7, r3
	bne.w .L0800c52e
	b.n .L0800c534
.L0800c382:
	ldrb.w r0, [r5, #0xe1b]
	cmp r0, #0
	beq.w .L0800c5a8
	movs r0, #6
	strb.w r0, [r5, #0xf68]
.L0800c392:
	add sp, #0x18
	pop.w {r4, r5, r6, r7, r8, lr}
	b.w send_state_message_sequence
.L0800c39c:
	ldr r1, [r0]
	movs r0, #0
	blx r1
.L0800c3a2:
	movs r0, #0
	str.w r0, [r5, #0xdfc]
.L0800c3a8:
	ldr.w r1, [r5, #0xe00]
	cbz r1, .L0800c3e6
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L0800c3da
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L0800c3e0
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L0800c3e0
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800c3e0
.L0800c3da:
	ldr r1, [r0]
	movs r0, #0
	blx r1
.L0800c3e0:
	movs r0, #0
	str.w r0, [r5, #0xe00]
.L0800c3e6:
	ldrb r0, [r5, #0x17]
	cmp r0, #2
	bne.n .L0800c4a6
	movw r0, #0x12d
	str.w r0, [r5, #0xdb4]
.L0800c3f4:
	ldrb.w r0, [r5, #0x2d]
	cmp r0, #0x14
	bcc.n .L0800c46e
.L0800c3fc:
	ldrb.w r0, [r5, #0x2e]
	movw r4, #0x400
	cmp r0, #0
	movt r4, #0x4000
	beq.n .L0800c4ba
	movw r0, #0x12d
	str.w r0, [r5, #0xdb4]
	movs r6, #0
	add r0, sp, #4
	str r6, [sp, #0x14]
	strd r6, r6, [sp, #0xc]
	strd r6, r6, [sp, #4]
	bl compute_clock_frequencies
	ldrb.w r0, [r5, #0x2d]
	subs r0, #0x14
	uxtb r1, r0
	cmp r1, #8
	bhi.n .L0800c462
	ldr r1, [sp, #8]
	movw r2, #0x1759
	movt r2, #0xd1b7
	umull r1, r2, r1, r2
	movw r1, #0x65a4
	sxtb r0, r0
	movt r1, #0x804
	ldr.w r0, [r1, r0, lsl #2]
	mov.w r1, #0xffffffff
	add.w r1, r1, r2, lsr #13
	str r0, [r4, #0x2c]
	str r1, [r4, #0x28]
	ldr r0, [r4, #0x14]
	orr.w r0, r0, #1
	str r0, [r4, #0x14]
.L0800c462:
	str r6, [r4, #0x24]
	ldr r0, [r4]
	orr.w r0, r0, #1
	str r0, [r4]
	b.n .L0800c4f4
.L0800c46e:
	ldrb r0, [r5, #0x17]
	cmp r0, #2
	bne.n .L0800c4f4
	movs r0, #3
	strb.w r0, [r5, #0xdb0]
	movw r0, #0x1010
	movt r0, #0x4001
	movs r1, #0x10
	str r1, [r0]
	movw r0, #0x2d78
	movw r1, #0x2d52
	movt r0, #0x2000
	movt r1, #0x2000
	ldr r0, [r0]
	movs r2, #8
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	b.n .L0800c4f4
.L0800c4a6:
	ldrb.w r0, [r5, #0x2d]
	cmp r0, #0x13
	bhi.n .L0800c3fc
	movs r0, #0
	movt r0, #0x12d
	str.w r0, [r5, #0xdb4]
	b.n .L0800c4f4
.L0800c4ba:
	ldr r0, [r4]
	bic.w r0, r0, #1
	str r0, [r4]
	ldrh.w r0, [r5, #0xdb6]
	cbz r0, .L0800c4f4
	ldrh.w r1, [r5, #0xdb4]
	mov r0, r1
	nop
.L0800c4d0:
	add r1, r5
	ldrb.w r2, [r1, #0x356]
	ldrb.w r3, [r1, #0x483]
	strb.w r2, [r1, #0x5b0]
	strb.w r3, [r1, #0x9b0]
	ldrh.w r2, [r5, #0xdb4]
	ldrh.w r3, [r5, #0xdb6]
	adds r0, #1
	uxth r1, r0
	add r2, r3
	cmp r2, r1
	bhi.n .L0800c4d0
.L0800c4f4:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #2
	b.n .L0800cb38
.L0800c50a:
	uxth r2, r0
	movw r1, #0xfff
	cmp r2, r1
	beq.n .L0800c5a8
	bfi r0, r1, #0, #16
	str r0, [r5, #0x4c]
	b.n .L0800cb24
.L0800c51c:
	lsls r1, r0, #0x10
	beq.n .L0800c5a8
	movw r1, #0xffff
	b.n .L0800c52e
.L0800c526:
	movs r1, #1
	lsls r1, r2
	tst r0, r1
	beq.n .L0800c534
.L0800c52e:
	bics r0, r1
	str r0, [r5, #0x4c]
	b.n .L0800cb24
.L0800c534:
	orrs r0, r1
	str r0, [r5, #0x4c]
	b.n .L0800cb24
.L0800c53a:
	orrs r0, r2
	strb r0, [r1]
.L0800c53e:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x28
	b.n .L0800cb38
.L0800c554:
	ldrb.w r0, [r5, #0xf6b]
	strb.w r0, [r5, #0xf64]
	movs r0, #1
	b.n .L0800c586
.L0800c560:
	ldrb.w r0, [r5, #0xf6b]
	strb.w r0, [r5, #0xf65]
	movs r0, #1
	b.n .L0800c586
.L0800c56c:
	movs r0, #7
	strb.w r0, [r5, #0xf68]
	bl send_state_message_sequence
	movs r0, #1
	b.n .L0800c586
.L0800c57a:
	ldrb.w r0, [r5, #0xf6b]
	cmp r0, #0
	beq.w .L0800cb48
	movs r0, #0
.L0800c586:
	strb.w r0, [r5, #0xf69]
.L0800c58a:
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #4
	bne.n .L0800c5a8
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x21
	b.n .L0800cb38
.L0800c5a8:
	add sp, #0x18
	pop.w {r4, r5, r6, r7, r8, pc}
.L0800c5ae:
	ldrb.w r0, [r5, #0x34]
	cmp r0, #0
	beq.w .L0800c732
	movs r0, #0
	strb.w r0, [r5, #0x34]
	b.n .L0800c758
.L0800c5c0:
	ldrb.w r1, [r5, #0xf6b]
	ldrb.w r0, [r5, #0x23a]
	cmp r1, #0
	beq.w .L0800c818
	lsls r1, r0, #0x1e
	bmi.w .L0800c870
	movs r1, #2
	b.n .L0800c81e
.L0800c5d8:
	ldrb.w r0, [r5, #0xf6b]
	cmp r0, #2
	beq.w .L0800c874
	cmp r0, #1
	beq.w .L0800c894
	cmp r0, #0
	bne.w .L0800cb1e
	ldrb r0, [r5, #0x17]
	ldrb.w r1, [r5, #0x2e]
	adds r0, #1
	uxtb r2, r0
	cmp r2, #2
	it hi
	movhi r0, #0
	cmp r1, #0
	strb r0, [r5, #0x17]
	bne.w .L0800ca22
	ldr.w r1, [r5, #0xdfc]
	movs r0, #1
	cmp r1, #0
	strb.w r0, [r5, #0x2e]
	beq.w .L0800c9e4
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cmp r2, #0
	beq.w .L0800c9d8
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.w .L0800c9de
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	beq.w .L0800c9de
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800c9de
.L0800c64c:
	ldrb.w r0, [r5, #0x3c]
	cmp r0, #0
	beq.n .L0800c71e
	ldr r7, [r5, #0x40]
	cmp r7, #0
	beq.n .L0800c71e
	movw r6, #0x1070
	movt r6, #0x2000
	mov.w r8, #0
	b.n .L0800c672
.L0800c668:
	ldr r1, [r6]
	movs r0, #0
	blx r1
.L0800c66e:
	cmp r7, #0
	beq.n .L0800c716
.L0800c672:
	ldr r0, [r7, #4]
	mov r4, r7
	ldr r7, [r7, #0x10]
	cbz r0, .L0800c6a8
	ldrb r1, [r6, #0x10]
	cbz r1, .L0800c69e
	ldr r1, [r6, #8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800c6a4
	ldr r2, [r6, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800c6a4
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800c6a4
.L0800c69e:
	ldr r1, [r6]
	movs r0, #0
	blx r1
.L0800c6a4:
	str.w r8, [r4, #4]
.L0800c6a8:
	ldr r0, [r4, #8]
	cbz r0, .L0800c6da
	ldrb r1, [r6, #0x10]
	cbz r1, .L0800c6d0
	ldr r1, [r6, #8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800c6d6
	ldr r2, [r6, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800c6d6
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800c6d6
.L0800c6d0:
	ldr r1, [r6]
	movs r0, #0
	blx r1
.L0800c6d6:
	str.w r8, [r4, #8]
.L0800c6da:
	ldrb r0, [r6, #0x10]
	cmp r0, #0
	beq.n .L0800c668
	ldr r0, [r6, #8]
	subs r0, r4, r0
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800c66e
	ldr r2, [r6, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cmp r1, #0
	beq.n .L0800c66e
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800c66e
	ldrb.w r1, [r5, #0x35]
	ldrb.w r0, [r5, #0xf6b]
	cmp r1, r0
	it eq
	moveq r0, #0
	strb.w r0, [r5, #0x35]
	b.n .L0800cb1e
.L0800c716:
	ldrb.w r0, [r5, #0x3c]
	movs r1, #0
	str r1, [r5, #0x40]
.L0800c71e:
	ldrb.w r1, [r5, #0xf6b]
	cmp r0, r1
	itee ne
	strbne.w r1, [r5, #0x3c]
	moveq r0, #0
	strbeq.w r0, [r5, #0x3c]
	b.n .L0800cb1e
.L0800c732:
	ldrb.w r0, [r5, #0x354]
	movs r1, #1
	and.w r2, r0, #0xf
	cmp r2, #3
	strb.w r1, [r5, #0x34]
	bne.n .L0800c758
	and.w r0, r0, #0xf0
	strb.w r0, [r5, #0x354]
	movw r0, #0x2d50
	movt r0, #0x2000
	movs r1, #0
	strh r1, [r0]
.L0800c758:
	ldrb.w r0, [r5, #0x3c]
	cmp r0, #0
	beq.w .L0800cb1e
	ldr r7, [r5, #0x40]
	cmp r7, #0
	beq.w .L0800cb1e
	movw r6, #0x1070
	movt r6, #0x2000
	mov.w r8, #0
	b.n .L0800c782
.L0800c778:
	ldr r1, [r6]
	movs r0, #0
	blx r1
.L0800c77e:
	cmp r7, #0
	beq.n .L0800c812
.L0800c782:
	ldr r0, [r7, #4]
	mov r4, r7
	ldr r7, [r7, #0x10]
	cbz r0, .L0800c7b8
	ldrb r1, [r6, #0x10]
	cbz r1, .L0800c7ae
	ldr r1, [r6, #8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800c7b4
	ldr r2, [r6, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800c7b4
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800c7b4
.L0800c7ae:
	ldr r1, [r6]
	movs r0, #0
	blx r1
.L0800c7b4:
	str.w r8, [r4, #4]
.L0800c7b8:
	ldr r0, [r4, #8]
	cbz r0, .L0800c7ea
	ldrb r1, [r6, #0x10]
	cbz r1, .L0800c7e0
	ldr r1, [r6, #8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800c7e6
	ldr r2, [r6, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800c7e6
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800c7e6
.L0800c7e0:
	ldr r1, [r6]
	movs r0, #0
	blx r1
.L0800c7e6:
	str.w r8, [r4, #8]
.L0800c7ea:
	ldrb r0, [r6, #0x10]
	cmp r0, #0
	beq.n .L0800c778
	ldr r0, [r6, #8]
	subs r0, r4, r0
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800c77e
	ldr r2, [r6, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cmp r1, #0
	beq.n .L0800c77e
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800c77e
.L0800c812:
	movs r0, #0
	str r0, [r5, #0x40]
	b.n .L0800cb1e
.L0800c818:
	lsls r1, r0, #0x1f
	bne.n .L0800c8b8
	movs r1, #1
.L0800c81e:
	orrs r0, r1
	strb.w r0, [r5, #0x23a]
	b.n .L0800c8c2
.L0800c826:
	add r0, r5
	ldrb.w r1, [r0, #5]!
	b.n .L0800c864
.L0800c82e:
	add r0, r5
	ldrb.w r1, [r0, #3]!
	b.n .L0800c864
.L0800c836:
	add r0, r5
	ldrb.w r1, [r0, #-3]
	clz r1, r1
	lsrs r1, r1, #5
	strb.w r1, [r0, #-3]
	ldrb r0, [r5]
	cmp r0, #0
	movw r0, #0x1010
	movt r0, #0x4001
	beq.n .L0800c916
	mov.w r1, #0x1000
	str.w r1, [r0, #0x400]
	b.n .L0800c924
.L0800c85e:
	add r0, r5
	ldrb.w r1, [r0, #7]!
.L0800c864:
	cmp r1, #0
	ite eq
	moveq r1, #1
	movne r1, #0
	strb r1, [r0]
	b.n .L0800cb1e
.L0800c870:
	movs r1, #0xfd
	b.n .L0800c8ba
.L0800c874:
	ldrb r0, [r5, #0x16]
	movw r1, #0x2d52
	clz r0, r0
	lsrs r0, r0, #5
	strb r0, [r5, #0x16]
	movw r0, #0x2d78
	movt r0, #0x2000
	ldr r0, [r0]
	movt r1, #0x2000
	movs r2, #6
	b.n .L0800cb14
.L0800c894:
	ldrb r0, [r5, #0x18]
	movs r2, #7
	adds r0, #1
	uxtb r1, r0
	cmp r1, #1
	it hi
	movhi r0, #0
	strb r0, [r5, #0x18]
	movw r0, #0x2d78
	movt r0, #0x2000
	movw r1, #0x2d52
	ldr r0, [r0]
	movt r1, #0x2000
	b.n .L0800cb14
.L0800c8b8:
	movs r1, #0xfe
.L0800c8ba:
	ands r0, r1
	strb.w r0, [r5, #0x23a]
	beq.n .L0800c8c8
.L0800c8c2:
	bl fn_08025fc0
	b.n .L0800cb1e
.L0800c8c8:
	ldrb.w r0, [r5, #0x354]
	and.w r1, r0, #0xf
	cmp r1, #3
	bcc.w .L0800cb1e
	and.w r0, r0, #0xf0
	strb.w r0, [r5, #0x354]
	movw r0, #0x2d50
	movt r0, #0x2000
	movs r1, #0
	strh r1, [r0]
	b.n .L0800cb1e
.L0800c8ec:
	orr.w r0, r1, r2
	strb r0, [r5, #0x14]
.L0800c8f2:
	bl fn_08030a70
	ldrb.w r0, [r5, #0x2d]
	cmp r0, #3
	itt ls
	movls r0, #0xa
	strbls.w r0, [r5, #0xdba]
	ldrb r0, [r5, #0x14]
	cmp r0, #3
	bhi.n .L0800c980
	tbb [pc, r0]
.L0800c90e:
	.byte (.L0800c912 - .L0800c90e)/2
	.byte (.L0800c942 - .L0800c90e)/2
	.byte (.L0800c950 - .L0800c90e)/2
	.byte (.L0800c97c - .L0800c90e)/2
.L0800c912:
	movs r0, #0
	b.n .L0800c97e
.L0800c916:
	movw r1, #0x1414
	movt r1, #0x4001
	mov.w r2, #0x1000
	str r2, [r1]
.L0800c924:
	ldrb r1, [r5, #1]
	cbz r1, .L0800c932
	mov.w r1, #0x2000
	str.w r1, [r0, #0x400]
	b.n .L0800cb1e
.L0800c932:
	movw r0, #0x1414
	movt r0, #0x4001
	mov.w r1, #0x2000
	str r1, [r0]
	b.n .L0800cb1e
.L0800c942:
	ldrb r0, [r5, #0x16]
	movs r1, #1
	cmp r0, #1
	strb r1, [r5, #0x15]
	bne.n .L0800c980
	movs r0, #0
	b.n .L0800c95a
.L0800c950:
	ldrb r0, [r5, #0x16]
	movs r1, #0x12
	strb r1, [r5, #0x15]
	cbnz r0, .L0800c980
	movs r0, #1
.L0800c95a:
	strb r0, [r5, #0x16]
	movw r0, #0x2d78
	movw r1, #0x2d52
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #6
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	b.n .L0800c980
.L0800c97c:
	movs r0, #2
.L0800c97e:
	strb r0, [r5, #0x15]
.L0800c980:
	movw r0, #0x1010
	movt r0, #0x4001
	movs r2, #4
	str.w r2, [r0, #0x400]
	ldrb r1, [r5, #0x14]
	cmp r1, #3
	beq.n .L0800c9a6
	cmp r1, #2
	beq.n .L0800c9aa
	cmp r1, #1
	bne.n .L0800c9b4
	movs r1, #4
	str r1, [r0]
	movs r1, #2
	str r1, [r0]
	b.n .L0800c9b2
.L0800c9a6:
	str r2, [r0]
	b.n .L0800c9ae
.L0800c9aa:
	movs r1, #4
	str r1, [r0, #4]
.L0800c9ae:
	movs r1, #2
	str r1, [r0, #4]
.L0800c9b2:
	ldrb r1, [r5, #0x14]
.L0800c9b4:
	cmp r1, #3
	beq.n .L0800c9cc
	ldrb.w r0, [r5, #0x354]
	cmp r1, #1
	ite ne
	ornne r0, r0, #0x7f
	andeq.w r0, r0, #0x7f
	strb.w r0, [r5, #0x354]
.L0800c9cc:
	movw r1, #0x2d52
	movt r1, #0x2000
	movs r2, #2
	b.n .L0800cb0a
.L0800c9d8:
	ldr r1, [r0]
	movs r0, #0
	blx r1
.L0800c9de:
	movs r0, #0
	str.w r0, [r5, #0xdfc]
.L0800c9e4:
	ldr.w r1, [r5, #0xe00]
	cbz r1, .L0800ca22
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L0800ca16
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L0800ca1c
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L0800ca1c
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800ca1c
.L0800ca16:
	ldr r1, [r0]
	movs r0, #0
	blx r1
.L0800ca1c:
	movs r0, #0
	str.w r0, [r5, #0xe00]
.L0800ca22:
	ldrb.w r0, [r5, #0x2d]
	cmp r0, #0x14
	bcc.n .L0800caaa
	ldrb.w r0, [r5, #0x2e]
	cbz r0, .L0800ca9a
	movw r0, #0x12d
	movw r4, #0x400
	str.w r0, [r5, #0xdb4]
	movs r6, #0
	add r0, sp, #4
	movt r4, #0x4000
	str r6, [sp, #0x14]
	strd r6, r6, [sp, #0xc]
	strd r6, r6, [sp, #4]
	bl compute_clock_frequencies
	ldrb.w r0, [r5, #0x2d]
	subs r0, #0x14
	uxtb r1, r0
	cmp r1, #8
	bhi.n .L0800ca8e
	ldr r1, [sp, #8]
	movw r2, #0x1759
	movt r2, #0xd1b7
	umull r1, r2, r1, r2
	movw r1, #:lower16:d_080465a4
	sxtb r0, r0
	movt r1, #:upper16:d_080465a4
	ldr.w r0, [r1, r0, lsl #2]
	mov.w r1, #0xffffffff
	add.w r1, r1, r2, lsr #13
	str r0, [r4, #0x2c]
	str r1, [r4, #0x28]
	ldr r0, [r4, #0x14]
	orr.w r0, r0, #1
	str r0, [r4, #0x14]
.L0800ca8e:
	str r6, [r4, #0x24]
	ldr r0, [r4]
	orr.w r0, r0, #1
	str r0, [r4]
	b.n .L0800caaa
.L0800ca9a:
	movw r0, #0x400
	movt r0, #0x4000
	ldr r1, [r0]
	bic.w r1, r1, #1
	str r1, [r0]
.L0800caaa:
	movw r0, #0x1010
	movt r0, #0x4001
	movs r1, #0x10
	str r1, [r0, #4]
	ldrb r1, [r5, #0x17]
	cmp r1, #2
	bne.n .L0800cadc
	ldrb.w r1, [r5, #0x2d]
	movw r2, #0x12d
	cmp r1, #0x13
	str.w r2, [r5, #0xdb4]
	bhi.n .L0800cb1e
	movs r1, #0x10
	str r1, [r0]
	movw r1, #0x2d52
	movt r1, #0x2000
	movs r2, #8
	b.n .L0800cb0a
.L0800cadc:
	ldrb.w r0, [r5, #0x2d]
	movw r1, #0x2d52
	cmp r0, #0x13
	itee hi
	movwhi r0, #0x12d
	movls r0, #0
	movtls r0, #0x12d
	str.w r0, [r5, #0xdb4]
	ldrb.w r0, [r5, #0xdb0]
	movt r1, #0x2000
	cmp r0, #3
	itt cs
	movcs r0, #2
	strbcs.w r0, [r5, #0xdb0]
	movs r2, #1
.L0800cb0a:
	movw r0, #0x2d78
	movt r0, #0x2000
	ldr r0, [r0]
.L0800cb14:
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L0800cb1e:
	movs r0, #1
	strb.w r0, [r5, #0xf69]
.L0800cb24:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x14
.L0800cb38:
	mov.w r2, #0xffffffff
	strb r3, [r1]
.L0800cb3e:
	add sp, #0x18
	pop.w {r4, r5, r6, r7, r8, lr}
	b.w queue_send_timeout
.L0800cb48:
	movs r0, #0
	bl save_settings_to_flash
	.short 0x0000 @ padding, never reached (after the call to a proven no-return function)

@ ----------------------------------------------------------------------------
@ fn_0800cb50 - No parameters. r5 = 0x200000f8 throughout.
@ State 2 ([0x20001060]==2) with [0x2000010c]!=0: sets [0x20000127]=1;
@   for channel bit0 of [0x2000010c]: saves [0x200000f8] into [0x20000129],
@   clears [0x200000f8], [0x200000fa], [0x200000fc], writes 0x1000 to
@   0x40011414 and 0x40011010, 0x10 and 0x40 to 0x40011810, 0x20 to
@   0x40011814 and recomputes 0x40007408/0x40007404 from the halfword tables
@   at index 0 with weight [0x200000fc]+100 (read before [0x200000fc] is
@   cleared, ldrsb at 0800ccb8, strb at 0800cd00) and again with weight 100.0
@   afterwards;
@   for bit1: ORs [0x200000f9]<<4 into [0x20000129], clears [0x200000f9],
@   [0x200000fb], [0x200000fd], writes 0x2000 to 0x40011414, 0x8000/0x800/
@   0x400 to 0x40010810/0x40010c10/0x40010c14 and recomputes 0x40001c34
@   likewise (first with the old [0x200000fd], then with weight 100.0);
@   sets [0x2000010f]=1 (0x10 to 0x40011014 when it was not 1), caps
@   [0x20000ea8] at 2, clears [0x2000012a], sends 4 and 5 to queue
@   [0x20002d6c] and 1 to queue [0x20002d78], sets [0x20000125]=4, writes 4
@   to 0x40011410, clears bit0 of 0x40000400, sets [0x20000eac]=0x12d0000,
@   when [0x20000126]==0 sets it to 1 and releases the buffers [0x20000ef4],
@   [0x20000ef8] (as in 0800bd60), sends 2.
@ State 1 with high nibble of [0x20001055] != 0xb: sends halfword 0x514 to
@   queue [0x20002d74], clears [0x20001055], sends 0x1d and 0x1b, sets
@   [0x2000102e]=1, [0x20001040..48]=0x7fc00000, clears [0x20001034] /
@   [0x20001035] (0x1a when it was set), [0x20001025]=0 and tail-calls
@   080098e0.
@ Other states return. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.global fn_0800cb50
	.thumb_func
	.type fn_0800cb50, %function
fn_0800cb50:
	push.w {r4, r5, r6, r7, r8, r9, lr}
	sub sp, #4
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #2
	beq.n .L0800cc20
	cmp r0, #1
	bne.w .L0800cc82
	ldrb.w r0, [r5, #0xf5d]
	and.w r0, r0, #0xf0
	cmp r0, #0xb0
	beq.w .L0800cc82
	movw r0, #0x2d74
	movw r1, #0x2d54
	movt r0, #0x2000
	movt r1, #0x2000
	movw r2, #0x514
	ldr r0, [r0]
	movs r6, #0
	strh r2, [r1]
	mov.w r2, #0xffffffff
	strb.w r6, [r5, #0xf5d]
	bl queue_send_timeout
	movw r7, #0x2d6c
	movw r4, #0x2d53
	movt r7, #0x2000
	movt r4, #0x2000
	movs r1, #0x1d
	ldr r0, [r7]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x1b
	ldr r0, [r7]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #1
	ldrb.w r1, [r5, #0xf3c]
	strb.w r0, [r5, #0xf36]
	movs r0, #0
	movt r0, #0x7fc0
	cmp r1, #0
	str.w r0, [r5, #0xf48]
	str.w r0, [r5, #0xf4c]
	str.w r0, [r5, #0xf50]
	it ne
	strbne.w r6, [r5, #0xf3c]
	ldrb.w r0, [r5, #0xf3d]
	cbz r0, .L0800cc10
	movs r0, #0
	strb.w r0, [r5, #0xf3d]
	movs r1, #0x1a
	ldr r0, [r7]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L0800cc10:
	movs r0, #0
	strb.w r0, [r5, #0xf2d]
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, lr}
	b.w fn_080098e0
.L0800cc20:
	ldrb r1, [r5, #0x14]
	cbz r1, .L0800cc82
	movw r8, #0x1414
	movw r0, #0xc14
	movt r8, #0x4001
	movt r0, #0x4001
	movs r2, #1
	lsls r3, r1, #0x1f
	strb.w r2, [r5, #0x2f]
	beq.w .L0800cd78
	ldrb r1, [r5]
	mov.w r2, #0x1000
	strb.w r1, [r5, #0x31]
	movs r1, #0
	strb r1, [r5]
	str.w r2, [r8]
	strb r1, [r5, #2]
	str.w r2, [r0, #0x3fc]
	movs r2, #0x10
	str.w r2, [r8, #0x3fc]
	movw r2, #0x1814
	movt r2, #0x4001
	movs r3, #0x20
	str r3, [r2]
	movs r2, #0x40
	str.w r2, [r8, #0x3fc]
	ldrb.w r3, [r5, #0x2d]
	cmp r3, #4
	bls.n .L0800cc88
	add.w r2, r5, #0x29c
	add.w r3, r5, #0x260
	b.n .L0800cca2
.L0800cc82:
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L0800cc88:
	add.w r2, r5, #0x2b0
	cmp r3, #4
	add.w r3, r5, #0x274
	beq.n .L0800cca2
	ldrb r7, [r5, #0x14]
	cmp r7, #3
	itt ne
	addne.w r2, r5, #0x2c4
	addne.w r3, r5, #0x288
.L0800cca2:
	ldrh r2, [r2]
	ldrh r3, [r3]
	vldr s0, .L0800cfc4
	subs r2, r2, r3
	vmov s2, r2
	vcvt.f32.s32 s2, s2
	vdiv.f32 s2, s2, s0
	ldrsb.w r7, [r5, #4]
	movw r2, #0x7404
	adds r7, #0x64
	vmov s4, r7
	vcvt.f32.s32 s4, s4
	movt r2, #0x4000
	vmul.f32 s2, s2, s4
	vmov s4, r3
	vcvt.f32.u32 s4, s4
	vadd.f32 s2, s2, s4
	ldr r3, [r2, #4]
	vcvt.u32.f32 s2, s2
	vmov r7, s2
	lsrs r3, r3, #0xc
	bfi r7, r3, #0xc, #0x14
	str r7, [r2, #4]
	ldr r3, [r2]
	orr.w r3, r3, #1
	str r3, [r2]
	ldrb.w r7, [r5, #0x2d]
	ldrb r3, [r5, #2]
	cmp r7, #5
	strb r1, [r5, #4]
	bcc.n .L0800cd12
	add.w r3, r5, r3, lsl #1
	add.w r1, r3, #0x29c
	add.w r3, r3, #0x260
	b.n .L0800cd36
.L0800cd12:
	cmp r7, #4
	beq.n .L0800cd2a
	ldrb r1, [r5, #0x14]
	cmp r1, #3
	beq.n .L0800cd2a
	add.w r3, r5, r3, lsl #1
	add.w r1, r3, #0x2c4
	add.w r3, r3, #0x288
	b.n .L0800cd36
.L0800cd2a:
	add.w r3, r5, r3, lsl #1
	add.w r1, r3, #0x2b0
	add.w r3, r3, #0x274
.L0800cd36:
	ldrh r1, [r1]
	ldrh r3, [r3]
	subs r1, r1, r3
	vmov s2, r1
	vcvt.f32.s32 s2, s2
	vdiv.f32 s0, s2, s0
	vldr s2, .L0800cfc8
	ldr r1, [r2, #4]
	lsrs r1, r1, #0xc
	vmul.f32 s0, s0, s2
	vmov s2, r3
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vmov r3, s0
	bfi r3, r1, #0xc, #0x14
	str r3, [r2, #4]
	ldr r1, [r2]
	orr.w r1, r1, #1
	str r1, [r2]
	ldrb r1, [r5, #0x14]
.L0800cd78:
	lsls r1, r1, #0x1e
	bpl.w .L0800ce94
	ldrb r1, [r5, #1]
	ldrb.w r2, [r5, #0x31]
	mov.w r3, #0x8000
	orr.w r1, r2, r1, lsl #4
	strb.w r1, [r5, #0x31]
	movs r1, #0
	mov.w r2, #0x2000
	strb r1, [r5, #1]
	str.w r2, [r8]
	movw r2, #0x810
	movt r2, #0x4001
	strb r1, [r5, #3]
	str r3, [r2]
	mov.w r3, #0x800
	str.w r3, [r2, #0x400]
	mov.w r3, #0x400
	str r3, [r0]
	str r3, [r2]
	ldrb.w r3, [r5, #0x2d]
	cmp r3, #4
	bls.n .L0800cdca
	add.w r2, r5, #0x314
	add.w r3, r5, #0x2d8
	b.n .L0800cde4
.L0800cdca:
	add.w r2, r5, #0x328
	cmp r3, #4
	add.w r3, r5, #0x2ec
	beq.n .L0800cde4
	ldrb r7, [r5, #0x14]
	cmp r7, #3
	itt ne
	addne.w r2, r5, #0x33c
	addne.w r3, r5, #0x300
.L0800cde4:
	ldrh r2, [r2]
	ldrh r3, [r3]
	vldr s0, .L0800cfc4
	subs r2, r2, r3
	vmov s2, r2
	vcvt.f32.s32 s2, s2
	vdiv.f32 s2, s2, s0
	ldrsb.w r7, [r5, #5]
	movw r2, #0x1c34
	adds r7, #0x64
	vmov s4, r7
	vcvt.f32.s32 s4, s4
	movt r2, #0x4000
	vmul.f32 s2, s2, s4
	vmov s4, r3
	vcvt.f32.u32 s4, s4
	vadd.f32 s2, s2, s4
	vcvt.u32.f32 s2, s2
	vstr s2, [r2]
	ldrb.w r7, [r5, #0x2d]
	ldrb r3, [r5, #3]
	cmp r7, #5
	strb r1, [r5, #5]
	bcc.n .L0800ce42
	add.w r3, r5, r3, lsl #1
	add.w r1, r3, #0x314
	add.w r3, r3, #0x2d8
	b.n .L0800ce66
.L0800ce42:
	cmp r7, #4
	beq.n .L0800ce5a
	ldrb r1, [r5, #0x14]
	cmp r1, #3
	beq.n .L0800ce5a
	add.w r3, r5, r3, lsl #1
	add.w r1, r3, #0x33c
	add.w r3, r3, #0x300
	b.n .L0800ce66
.L0800ce5a:
	add.w r3, r5, r3, lsl #1
	add.w r1, r3, #0x328
	add.w r3, r3, #0x2ec
.L0800ce66:
	ldrh r1, [r1]
	ldrh r3, [r3]
	subs r1, r1, r3
	vmov s2, r1
	vcvt.f32.s32 s2, s2
	vdiv.f32 s0, s2, s0
	vldr s2, .L0800cfc8
	vmul.f32 s0, s0, s2
	vmov s2, r3
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vstr s0, [r2]
.L0800ce94:
	ldrb r1, [r5, #0x17]
	cmp r1, #1
	beq.n .L0800cea4
	movs r1, #1
	strb r1, [r5, #0x17]
	movs r1, #0x10
	str.w r1, [r0, #0x400]
.L0800cea4:
	ldrb.w r0, [r5, #0xdb0]
	movw r9, #0x2d6c
	cmp r0, #3
	itt cs
	movcs r0, #2
	strbcs.w r0, [r5, #0xdb0]
	movs r0, #0
	movw r4, #0x2d53
	movt r9, #0x2000
	strb.w r0, [r5, #0x32]
	movt r4, #0x2000
	ldr.w r0, [r9]
	movs r6, #4
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r6, [r4]
	bl queue_send_timeout
	movs r1, #5
	ldr.w r0, [r9]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movw r0, #0x2d78
	movt r0, #0x2000
	movw r1, #0x2d52
	ldr r0, [r0]
	movt r1, #0x2000
	movs r7, #1
	mov.w r2, #0xffffffff
	strb.w r6, [r5, #0x2d]
	strb r7, [r1]
	bl queue_send_timeout
	movw r0, #0x400
	str.w r6, [r8, #-4]
	movt r0, #0x4000
	ldr r1, [r0]
	bic.w r1, r1, #1
	str r1, [r0]
	ldrb.w r0, [r5, #0x2e]
	movs r1, #0
	movt r1, #0x12d
	str.w r1, [r5, #0xdb4]
	cbnz r0, .L0800cfaa
	ldr.w r0, [r5, #0xdfc]
	movw r6, #0x1070
	movt r6, #0x2000
	strb.w r7, [r5, #0x2e]
	cbz r0, .L0800cf74
	ldrb r1, [r6, #0x10]
	cbz r1, .L0800cf68
	ldr r1, [r6, #8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800cf6e
	ldr r2, [r6, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800cf6e
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800cf6e
.L0800cf68:
	ldr r1, [r6]
	movs r0, #0
	blx r1
.L0800cf6e:
	movs r0, #0
	str.w r0, [r5, #0xdfc]
.L0800cf74:
	ldr.w r0, [r5, #0xe00]
	cbz r0, .L0800cfaa
	ldrb r1, [r6, #0x10]
	cbz r1, .L0800cf9e
	ldr r1, [r6, #8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800cfa4
	ldr r2, [r6, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800cfa4
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800cfa4
.L0800cf9e:
	ldr r1, [r6]
	movs r0, #0
	blx r1
.L0800cfa4:
	movs r0, #0
	str.w r0, [r5, #0xe00]
.L0800cfaa:
	ldr.w r0, [r9]
	movs r3, #2
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, lr}
	b.w queue_send_timeout
	.short 0xbf00 @ padding, never reached (after the final tail call)
.L0800cfc4:
	.word 0x43480000 @ float 200.0
.L0800cfc8:
	.word 0x42c80000 @ float 100.0
