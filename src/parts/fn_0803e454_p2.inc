@ fn_0803e454_p2.inc - part 2 of 2 of fn_0803e454 (scope_acq): continuation of the
@ acquisition task body, 0x0803f454..0x08040008, included inline by part 1.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
@ Fragment only: no .section / .type lines; the instructions continue part 1.
@ What the code does, from the instructions: r9 holds 0x200000f8 (movw/movt) and is
@ used as base of two byte tables (+0x5b0 and +0x9b0, 0x400 apart per 0x400 samples,
@ and a second pair at +0x400 offsets from base+0x5b0); the bytes at base+0x350 and
@ base+0x351 are subtracted from table reads when lr / r10 is not 1 and the index is
@ odd or even; each sample index is wrapped by 0x7ff / 0x3ff limits before the read.
@ The differences of neighbouring samples are made absolute with qsub16 / sxth and
@ compared against the thresholds 7 and 0xb. Byte [base+0xdb0] is incremented on
@ some paths, [base+0xdb8] is cleared and [base+0xdb4] is set to 0x12d on the last
@ path. The tail loops poll the word at [r7] (bit 1 then bit 0) and write 0x12 or
@ r0+1 to [r7+4]. Exits branch back to .L0803e49a / .L0803e498 in part 1.

	sub.w r9, r9, r2
	uxth.w r2, r11
	uxth r1, r1
	cmp.w r3, r2, lsr #10
	str.w r11, [sp, #0x30]
	it ne
	movne r11, lr
	uxth.w r6, r10
	ldrb.w r10, [r0, r1]
	uxth r1, r4
	uxth.w r3, r8
	uxth.w r5, r12
	ldrb r4, [r0, r1]
	uxth.w r1, r11
	ldrb r6, [r0, r6]
	ldrb r3, [r0, r3]
	ldrb r5, [r0, r5]
	ldrb r1, [r0, r1]
	subs r2, r6, r4
	subs r4, r5, r4
	subs r0, r3, r1
	cmp r2, #0
	bgt.n .L0803f49c
.L0803f494:
	movs r3, #0
	qsub16 r2, r3, r2
	sxth r2, r2
.L0803f49c:
	mov r6, r9
	cmp.w r9, #0
	movw r9, #0xf8
	ldr.w lr, [sp, #0x28]
	movt r9, #0x2000
	bgt.n .L0803f4b8
	movs r3, #0
	qsub16 r3, r3, r6
	sxth r6, r3
.L0803f4b8:
	ldr.w r8, [sp, #0x2c]
	cmp r0, #0
	ble.n .L0803f53c
	cmp r4, #0
	ble.n .L0803f548
.L0803f4c4:
	uxtb r1, r1
	sub.w r1, r10, r1
	cmp r1, #0
	bgt.n .L0803f4d6
	movs r3, #0
	qsub16 r1, r3, r1
	sxth r1, r1
.L0803f4d6:
	cmp r2, #7
	bgt.w .L0803f39c
	cmp r6, #0xb
	blt.w .L0803f39c
	cmp r0, #0xb
	blt.w .L0803f39c
	cmp r4, #7
	bgt.w .L0803f39c
	cmp r1, #7
	bgt.w .L0803f39c
	ldr r0, [sp, #0x24]
	cmp r0, #0
	bne.w .L0803f34c
	and.w r1, r8, #1
	cmp.w lr, #1
	ubfx r0, r8, #1, #15
	bne.n .L0803f562
	cmp r1, #0
	bne.w .L0803f874
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803f888
.L0803f518:
	cmp.w r0, r4, lsr #11
	mov r0, r5
	it ne
	addne.w r0, r0, #0xf800
	and.w r1, r0, #1
	cmp.w lr, #1
	ubfx r0, r0, #1, #15
	bne.n .L0803f554
	cbnz r1, .L0803f574
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803f588
.L0803f53c:
	movs r3, #0
	qsub16 r0, r3, r0
	sxth r0, r0
	cmp r4, #0
	bgt.n .L0803f4c4
.L0803f548:
	movs r3, #0
	qsub16 r3, r3, r4
	sxth r4, r3
	b.n .L0803f4c4
	.byte 0x00, 0xbf @ padding
.L0803f554:
	cbnz r1, .L0803f582
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldrb.w r1, [r9, #0x351]
	b.n .L0803f57e
.L0803f562:
	cmp r1, #0
	bne.w .L0803f882
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldrb.w r1, [r9, #0x351]
	b.n .L0803f87e
.L0803f574:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldrb.w r1, [r9, #0x350]
.L0803f57e:
	subs r0, r0, r1
	b.n .L0803f588
.L0803f582:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803f588:
	str r0, [sp, #0xc]
	adds r6, r5, #1
	movw r0, #0x7fe
	cmp r4, r0
	mov r0, r6
	it hi
	subwhi r0, r5, #0x7ff
	uxth r2, r0
	and.w r1, r0, #1
	cmp.w lr, #1
	lsr.w r0, r2, #1
	bne.n .L0803f5b4
	cbnz r1, .L0803f5c2
	add r0, r9
	ldrb.w r11, [r0, #0x5b0]
	b.n .L0803f5d8
.L0803f5b4:
	cbnz r1, .L0803f5d2
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldrb.w r1, [r9, #0x351]
	b.n .L0803f5cc
.L0803f5c2:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldrb.w r1, [r9, #0x350]
.L0803f5cc:
	sub.w r11, r0, r1
	b.n .L0803f5d8
.L0803f5d2:
	add r0, r9
	ldrb.w r11, [r0, #0x9b0]
.L0803f5d8:
	adds r3, r5, #2
	movw r0, #0x7fd
	cmp r4, r0
	mov r0, r3
	it hi
	subwhi r0, r5, #0x7fe
	uxth r2, r0
	and.w r1, r0, #1
	cmp.w lr, #1
	lsr.w r0, r2, #1
	bne.n .L0803f604
	cbnz r1, .L0803f612
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803f626
	.byte 0x00, 0xbf @ padding
.L0803f604:
	cbnz r1, .L0803f620
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldrb.w r1, [r9, #0x351]
	b.n .L0803f61c
.L0803f612:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldrb.w r1, [r9, #0x350]
.L0803f61c:
	subs r0, r0, r1
	b.n .L0803f626
.L0803f620:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803f626:
	str r0, [sp, #0x8]
	adds r1, r5, #3
	movw r0, #0x7fc
	cmp r4, r0
	mov r0, r1
	subw r8, r5, #0x7fd
	str r1, [sp, #0x30]
	it hi
	movhi r0, r8
	uxth r2, r0
	and.w r1, r0, #1
	cmp.w lr, #1
	lsr.w r0, r2, #1
	bne.n .L0803f658
	cbnz r1, .L0803f666
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803f67a
	.byte 0x00, 0xbf @ padding
.L0803f658:
	cbnz r1, .L0803f674
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldrb.w r1, [r9, #0x351]
	b.n .L0803f670
.L0803f666:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldrb.w r1, [r9, #0x350]
.L0803f670:
	subs r0, r0, r1
	b.n .L0803f67a
.L0803f674:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803f67a:
	str r0, [sp, #0x4]
	adds r0, r5, #4
	movw r1, #0x7fb
	cmp r4, r1
	it hi
	subwhi r0, r5, #0x7fc
	uxth r2, r0
	and.w r1, r0, #1
	cmp.w lr, #1
	lsr.w r0, r2, #1
	bne.n .L0803f6a4
	cbnz r1, .L0803f6b2
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803f6c6
.L0803f6a4:
	cbnz r1, .L0803f6c0
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldrb.w r1, [r9, #0x351]
	b.n .L0803f6bc
.L0803f6b2:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldrb.w r1, [r9, #0x350]
.L0803f6bc:
	subs r0, r0, r1
	b.n .L0803f6c6
.L0803f6c0:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803f6c6:
	and.w r2, r6, #1
	cmp.w lr, #1
	ubfx r10, r6, #1, #15
	str r0, [sp, #0x0]
	bne.n .L0803f6e4
	cbnz r2, .L0803f6f4
	add.w r0, r9, r10
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803f70c
	.byte 0x00, 0xbf @ padding
.L0803f6e4:
	cbnz r2, .L0803f704
	add.w r0, r9, r10
	ldrb.w r0, [r0, #0x5b0]
	ldrb.w r1, [r9, #0x351]
	b.n .L0803f700
.L0803f6f4:
	add.w r0, r10, r9
	ldrb.w r0, [r0, #0x9b0]
	ldrb.w r1, [r9, #0x350]
.L0803f700:
	subs r0, r0, r1
	b.n .L0803f70c
.L0803f704:
	add.w r0, r10, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803f70c:
	str r0, [sp, #0x18]
	and.w r1, r5, #1
	cmp.w lr, #1
	ubfx r0, r3, #1, #15
	str r6, [sp, #0x2c]
	str r3, [sp, #0x20]
	bne.n .L0803f72c
	cbnz r1, .L0803f73a
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803f74e
	.byte 0x00, 0xbf @ padding
.L0803f72c:
	cbnz r1, .L0803f748
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldrb.w r1, [r9, #0x351]
	b.n .L0803f744
.L0803f73a:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldrb.w r1, [r9, #0x350]
.L0803f744:
	subs r0, r0, r1
	b.n .L0803f74e
.L0803f748:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803f74e:
	ldr r1, [sp, #0x30]
	str r0, [sp, #0x14]
	uxth.w r12, r1
	movs r0, #0
	cmp.w r0, r12, lsr #11
	it ne
	movne r1, r8
	uxth r4, r1
	and.w r5, r1, #1
	cmp.w lr, #1
	lsr.w r1, r4, #1
	bne.n .L0803f77c
	cbnz r5, .L0803f78a
	add r1, r9
	ldrb.w r0, [r1, #0x5b0]
	b.n .L0803f79e
	.byte 0x00, 0xbf @ padding
.L0803f77c:
	cbnz r5, .L0803f798
	add r1, r9
	ldrb.w r1, [r1, #0x5b0]
	ldrb.w r4, [r9, #0x351]
	b.n .L0803f794
.L0803f78a:
	add r1, r9
	ldrb.w r1, [r1, #0x9b0]
	ldrb.w r4, [r9, #0x350]
.L0803f794:
	subs r0, r1, r4
	b.n .L0803f79e
.L0803f798:
	add r1, r9
	ldrb.w r0, [r1, #0x9b0]
.L0803f79e:
	cmp.w lr, #1
	str r0, [sp, #0x10]
	bne.n .L0803f7b4
	cbnz r2, .L0803f7c4
	add.w r1, r9, r10
	ldrb.w r3, [r1, #0x5b0]
	b.n .L0803f7dc
	.byte 0x00, 0xbf @ padding
.L0803f7b4:
	cbnz r2, .L0803f7d4
	add.w r1, r9, r10
	ldrb.w r1, [r1, #0x5b0]
	ldrb.w r2, [r9, #0x351]
	b.n .L0803f7d0
.L0803f7c4:
	add.w r1, r10, r9
	ldrb.w r1, [r1, #0x9b0]
	ldrb.w r2, [r9, #0x350]
.L0803f7d0:
	subs r3, r1, r2
	b.n .L0803f7dc
.L0803f7d4:
	add.w r1, r10, r9
	ldrb.w r3, [r1, #0x9b0]
.L0803f7dc:
	ldrd r6, r0, [sp]
	ldrd r2, r1, [sp, #8]
	uxtb.w r9, r0
	ldr r0, [sp, #0x18]
	uxtb r4, r2
	uxtb r2, r0
	ldr r0, [sp, #0x14]
	uxtb r1, r1
	subs r2, r1, r2
	uxtb r1, r0
	ldr r0, [sp, #0x10]
	uxtb.w r5, r11
	uxtb.w r10, r6
	subs r6, r5, r1
	uxtb r0, r0
	uxtb r1, r3
	subs r0, r4, r0
	sub.w r4, r9, r1
	movs r1, #0
	cmp.w r1, r12, lsr #11
	ldr r1, [sp, #0x30]
	it eq
	moveq r8, r1
	uxth.w r1, r8
	movw r3, #0xf8
	and.w r5, r8, #1
	cmp.w lr, #1
	lsr.w r1, r1, #1
	mov r9, r6
	movt r3, #0x2000
	bne.n .L0803f844
	cbnz r5, .L0803f852
	add r1, r3
	ldrb.w r1, [r1, #0x5b0]
	cmp r2, #0
	bgt.w .L0803f49c
	b.n .L0803f494
.L0803f844:
	cbnz r5, .L0803f866
	add r1, r3
	ldrb.w r1, [r1, #0x5b0]
	ldrb.w r3, [r3, #0x351]
	b.n .L0803f85c
.L0803f852:
	add r1, r3
	ldrb.w r1, [r1, #0x9b0]
	ldrb.w r3, [r3, #0x350]
.L0803f85c:
	subs r1, r1, r3
	cmp r2, #0
	bgt.w .L0803f49c
	b.n .L0803f494
.L0803f866:
	add r1, r3
	ldrb.w r1, [r1, #0x9b0]
	cmp r2, #0
	bgt.w .L0803f49c
	b.n .L0803f494
.L0803f874:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldrb.w r1, [r9, #0x350]
.L0803f87e:
	subs r0, r0, r1
	b.n .L0803f888
.L0803f882:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803f888:
	ldr r6, [sp, #0x30]
	ldr r5, [sp, #0x1c]
	uxth r3, r6
	movs r1, #0
	cmp.w r1, r3, lsr #11
	mov r1, r6
	subw r2, r5, #0x7fd
	it ne
	movne r1, r2
	uxth r6, r1
	and.w r4, r1, #1
	cmp.w lr, #1
	lsr.w r1, r6, #1
	bne.n .L0803f8b8
	cbnz r4, .L0803f8c8
	add r1, r9
	ldrb.w r1, [r1, #0x5b0]
	b.n .L0803f8dc
.L0803f8b8:
	cbnz r4, .L0803f8d6
	add r1, r9
	ldrb.w r1, [r1, #0x5b0]
	ldrb.w r6, [r9, #0x351]
	subs r1, r1, r6
	b.n .L0803f8dc
.L0803f8c8:
	add r1, r9
	ldrb.w r1, [r1, #0x9b0]
	ldrb.w r6, [r9, #0x350]
	subs r1, r1, r6
	b.n .L0803f8dc
.L0803f8d6:
	add r1, r9
	ldrb.w r1, [r1, #0x9b0]
.L0803f8dc:
	uxtb r0, r0
	uxtb r1, r1
	subs r0, r0, r1
	uxth r1, r0
	add.w r0, r0, r1, lsr #15
	movs r1, #0
	cmp.w r1, r3, lsr #11
	ldr r3, [sp, #0x30]
	ldr r6, [sp, #0x20]
	it ne
	movne r3, r2
	uxth r1, r3
	asrs r0, r0, #1
	and.w r2, r3, #1
	cmp.w lr, #1
	lsr.w r1, r1, #1
	bne.n .L0803f912
	cbnz r2, .L0803f920
	add r1, r9
	ldrb.w r2, [r1, #0x5b0]
	b.n .L0803f386
.L0803f912:
	cbnz r2, .L0803f92e
	add r1, r9
	ldrb.w r1, [r1, #0x5b0]
	ldrb.w r2, [r9, #0x351]
	b.n .L0803f92a
.L0803f920:
	add r1, r9
	ldrb.w r1, [r1, #0x9b0]
	ldrb.w r2, [r9, #0x350]
.L0803f92a:
	subs r2, r1, r2
	b.n .L0803f386
.L0803f92e:
	add r1, r9
	ldrb.w r2, [r1, #0x9b0]
	b.n .L0803f386
.L0803f936:
	ldrb.w r0, [r9, #0xdb0]
	ldrb.w r2, [r9, #0x17]
	adds r0, #1
	cmp r2, #2
	strb.w r0, [r9, #0xdb0]
	bne.w .L0803e49a
	sub.w r0, r10, #3
	clz r0, r0
	lsrs r0, r0, #5
	cmp r1, #3
	mov.w r1, #0
	it hi
	movhi r1, #1
	orrs r0, r1
	str r0, [sp, #0x24]
	ldrb.w r0, [r9, #0x350]
	mov.w lr, #0
	str r0, [sp, #0x20]
	ldrb.w r0, [r9, #0x351]
	str.w r10, [sp, #0x18]
	str r0, [sp, #0x1c]
	b.n .L0803f9e4
.L0803f978:
	movw r0, #0x3fe
	movw r5, #0xf8
	cmp r8, r0
	mov r0, lr
	movw r1, #0xfc01
	movt r5, #0x2000
	it hi
	addhi.w r0, r8, r1
	add.w r1, r5, #0x5b0
	uxtah r0, r1, r0
	uxth r2, r4
	movs r3, #0
	ldrb.w r0, [r0, #0x400]
	cmp.w r3, r2, lsr #10
	it ne
	subwne r4, r8, #0x3fd
	uxtah r1, r1, r4
	ldrb.w r1, [r1, #0x400]
	subs r0, r0, r1
	uxth r2, r0
	add.w r0, r0, r2, lsr #15
	asrs r0, r0, #1
.L0803f9be:
	add r0, r1
	movw r1, #0x3fd
	cmp r8, r1
	ldr r1, [sp, #0x28]
	it ls
	addwls r1, r8, #0x402
	add r1, r5
	strb.w r0, [r1, #0x5b0]
.L0803f9d4:
	movw r9, #0xf8
	cmp.w lr, #0x400
	movt r9, #0x2000
	beq.w .L0803e49a
.L0803f9e4:
	ldr r0, [sp, #0x24]
	mov r8, lr
	cmp r0, #0
	uxth.w r4, lr
	mov.w r0, #0
	beq.n .L0803fad4
	add.w r5, r8, #1
	cmp.w r0, r4, lsr #10
	mov r12, r8
	movw r1, #0x3fe
	mov r2, r5
	it ne
	addne.w r12, r12, #0xfc00
	add.w r0, r9, #0x5b0
	cmp r4, r1
	it hi
	subwhi r2, r8, #0x3ff
	uxtah r2, r0, r2
	ldrb.w r9, [r2, #0x400]
	add.w r2, r8, #2
	movw r3, #0x3fd
	cmp r4, r3
	mov lr, r2
	add.w r3, r8, #3
	it hi
	subwhi lr, r8, #0x3fe
	cmp.w r4, #0x3fc
	mov r11, r3
	lsr.w r4, r4, #2
	subw r10, r8, #0x3fd
	it hi
	movhi r11, r10
	add.w r6, r8, #4
	cmp r4, #0xfe
	it hi
	subhi.w r6, r8, #0x3fc
	cmp r8, r1
	mov r4, r5
	movw r1, #0xfc01
	str r5, [sp, #0x2c]
	it hi
	addhi.w r4, r8, r1
	movw r1, #0x3fd
	cmp r8, r1
	str r2, [sp, #0x28]
	movw r5, #0xfc02
	it hi
	addhi.w r2, r8, r5
	uxtah r1, r0, r2
	ldrb.w r1, [r1, #0x400]
	movs r2, #0
	sub.w r9, r9, r1
	uxth r1, r3
	cmp.w r2, r1, lsr #10
	mov r1, r3
	str r3, [sp, #0x30]
	it ne
	movne r1, r10
	uxtah r5, r0, r12
	uxtah r3, r0, r11
	uxtah r4, r0, r4
	uxtah r2, r0, lr
	uxtah r6, r0, r6
	uxtah r1, r0, r1
	ldrb.w r0, [r5, #0x400]
	ldrb.w r4, [r4, #0x400]
	ldrb.w r3, [r3, #0x400]
	ldrb.w r2, [r2, #0x400]
	ldrb.w r5, [r1, #0x400]
	sub.w r12, r0, r4
	subs r0, r3, r4
	ldrb.w r3, [r6, #0x400]
	subs r1, r2, r5
	cmp.w r12, #0
	bgt.w .L0803fdfc
	b.n .L0803fdf2
	.byte 0x00, 0xbf @ padding
.L0803fad4:
	cmp.w r0, r4, lsr #11
	mov r0, r8
	it ne
	addne.w r0, r0, #0xf800
	and.w r1, r0, #1
	cmp.w r10, #1
	ubfx r0, r0, #1, #15
	bne.n .L0803faf8
	cbnz r1, .L0803fb04
	add r0, r9
	ldrb.w lr, [r0, #0x5b0]
	b.n .L0803fb18
.L0803faf8:
	cbnz r1, .L0803fb12
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldr r1, [sp, #0x1c]
	b.n .L0803fb0c
.L0803fb04:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldr r1, [sp, #0x20]
.L0803fb0c:
	sub.w lr, r0, r1
	b.n .L0803fb18
.L0803fb12:
	add r0, r9
	ldrb.w lr, [r0, #0x9b0]
.L0803fb18:
	add.w r12, r8, #1
	movw r0, #0x7fe
	cmp r4, r0
	mov r0, r12
	it hi
	subwhi r0, r8, #0x7ff
	uxth r2, r0
	and.w r1, r0, #1
	cmp.w r10, #1
	lsr.w r0, r2, #1
	bne.n .L0803fb44
	cbnz r1, .L0803fb50
	add r0, r9
	ldrb.w r6, [r0, #0x5b0]
	b.n .L0803fb62
.L0803fb44:
	cbnz r1, .L0803fb5c
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldr r1, [sp, #0x1c]
	b.n .L0803fb58
.L0803fb50:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldr r1, [sp, #0x20]
.L0803fb58:
	subs r6, r0, r1
	b.n .L0803fb62
.L0803fb5c:
	add r0, r9
	ldrb.w r6, [r0, #0x9b0]
.L0803fb62:
	add.w r1, r8, #2
	movw r0, #0x7fd
	cmp r4, r0
	mov r0, r1
	str r1, [sp, #0x28]
	it hi
	subwhi r0, r8, #0x7fe
	uxth r2, r0
	and.w r1, r0, #1
	cmp.w r10, #1
	lsr.w r0, r2, #1
	bne.n .L0803fb90
	cbnz r1, .L0803fb9c
	add r0, r9
	ldrb.w r1, [r0, #0x5b0]
	b.n .L0803fbae
.L0803fb90:
	cbnz r1, .L0803fba8
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldr r1, [sp, #0x1c]
	b.n .L0803fba4
.L0803fb9c:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldr r1, [sp, #0x20]
.L0803fba4:
	subs r1, r0, r1
	b.n .L0803fbae
.L0803fba8:
	add r0, r9
	ldrb.w r1, [r0, #0x9b0]
.L0803fbae:
	add.w r5, r8, #3
	movw r0, #0x7fc
	cmp r4, r0
	mov r0, r5
	subw r11, r8, #0x7fd
	it hi
	movhi r0, r11
	uxth r3, r0
	and.w r2, r0, #1
	cmp.w r10, #1
	lsr.w r0, r3, #1
	bne.n .L0803fbdc
	cbnz r2, .L0803fbe8
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803fbfa
.L0803fbdc:
	cbnz r2, .L0803fbf4
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldr r2, [sp, #0x1c]
	b.n .L0803fbf0
.L0803fbe8:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldr r2, [sp, #0x20]
.L0803fbf0:
	subs r0, r0, r2
	b.n .L0803fbfa
.L0803fbf4:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803fbfa:
	str r0, [sp, #0xc]
	add.w r0, r8, #4
	movw r2, #0x7fb
	cmp r4, r2
	it hi
	subwhi r0, r8, #0x7fc
	uxth r3, r0
	and.w r2, r0, #1
	cmp.w r10, #1
	lsr.w r0, r3, #1
	bne.n .L0803fc28
	cbnz r2, .L0803fc36
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803fc40
	.byte 0x00, 0xbf @ padding
.L0803fc28:
	cbnz r2, .L0803fc54
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldr r2, [sp, #0x1c]
	subs r0, r0, r2
	b.n .L0803fc5a
.L0803fc36:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldr r2, [sp, #0x20]
	subs r0, r0, r2
.L0803fc40:
	uxtb r3, r0
	lsls.w r0, r12, #31
	ubfx r0, r12, #1, #15
	bne.n .L0803fc70
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803fc82
.L0803fc54:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803fc5a:
	uxtb r3, r0
	lsls.w r0, r12, #31
	ubfx r0, r12, #1, #15
	bne.n .L0803fc7c
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldr r2, [sp, #0x1c]
	b.n .L0803fc78
.L0803fc70:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldr r2, [sp, #0x20]
.L0803fc78:
	subs r0, r0, r2
	b.n .L0803fc82
.L0803fc7c:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
.L0803fc82:
	str r0, [sp, #0x8]
	ldr r0, [sp, #0x28]
	and.w r2, r8, #1
	cmp.w r10, #1
	ubfx r0, r0, #1, #15
	str r3, [sp, #0x14]
	bne.n .L0803fca0
	cbnz r2, .L0803fcac
	add r0, r9
	ldrb.w r2, [r0, #0x5b0]
	b.n .L0803fcbe
.L0803fca0:
	cbnz r2, .L0803fcb8
	add r0, r9
	ldrb.w r0, [r0, #0x5b0]
	ldr r2, [sp, #0x1c]
	b.n .L0803fcb4
.L0803fcac:
	add r0, r9
	ldrb.w r0, [r0, #0x9b0]
	ldr r2, [sp, #0x20]
.L0803fcb4:
	subs r2, r0, r2
	b.n .L0803fcbe
.L0803fcb8:
	add r0, r9
	ldrb.w r2, [r0, #0x9b0]
.L0803fcbe:
	uxtb.w r0, lr
	str r0, [sp, #0x10]
	uxth.w lr, r5
	movs r0, #0
	cmp.w r0, lr, lsr #11
	mov r0, r5
	str r5, [sp, #0x30]
	it ne
	movne r0, r11
	uxth.w r9, r0
	uxtb r1, r1
	and.w r3, r0, #1
	cmp.w r10, #1
	lsr.w r0, r9, #1
	str.w r12, [sp, #0x2c]
	bne.n .L0803fd00
	cbnz r3, .L0803fd1a
	movw r3, #0xf8
	movt r3, #0x2000
	add r0, r3
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803fd30
.L0803fd00:
	cbnz r3, .L0803fd48
	movw r3, #0xf8
	movt r3, #0x2000
	add r0, r3
	ldrb.w r0, [r0, #0x5b0]
	mov r4, r6
	ldr r6, [sp, #0x1c]
	subs r0, r0, r6
	mov r6, r4
	b.n .L0803fd56
.L0803fd1a:
	movw r3, #0xf8
	movt r3, #0x2000
	add r0, r3
	ldrb.w r0, [r0, #0x9b0]
	mov r4, r6
	ldr r6, [sp, #0x20]
	subs r0, r0, r6
	mov r6, r4
.L0803fd30:
	uxtb r0, r0
	subs r1, r1, r0
	lsls.w r0, r12, #31
	mov r9, r2
	ubfx r0, r12, #1, #15
	bne.n .L0803fd70
	add r0, r3
	ldrb.w r0, [r0, #0x5b0]
	b.n .L0803fd82
.L0803fd48:
	movw r3, #0xf8
	movt r3, #0x2000
	add r0, r3
	ldrb.w r0, [r0, #0x9b0]
.L0803fd56:
	uxtb r0, r0
	subs r1, r1, r0
	lsls.w r0, r12, #31
	mov r9, r2
	ubfx r0, r12, #1, #15
	bne.n .L0803fd7c
	add r0, r3
	ldrb.w r0, [r0, #0x5b0]
	ldr r3, [sp, #0x1c]
	b.n .L0803fd78
.L0803fd70:
	add r0, r3
	ldrb.w r0, [r0, #0x9b0]
	ldr r3, [sp, #0x20]
.L0803fd78:
	subs r0, r0, r3
	b.n .L0803fd82
.L0803fd7c:
	add r0, r3
	ldrb.w r0, [r0, #0x9b0]
.L0803fd82:
	add r5, sp, #8
	ldmia r5, {r2, r4, r5}
	uxtb r3, r6
	uxtb r6, r4
	uxtb r4, r2
	uxtb.w r2, r9
	sub.w r9, r3, r2
	movs r2, #0
	cmp.w r2, lr, lsr #11
	ldr r2, [sp, #0x30]
	it eq
	moveq r11, r2
	uxth.w r2, r11
	uxtb r0, r0
	lsrs r3, r2, #1
	movw r2, #0xf8
	sub.w r12, r5, r4
	subs r0, r6, r0
	and.w r5, r11, #1
	cmp.w r10, #1
	movt r2, #0x2000
	bne.n .L0803fdcc
	cbnz r5, .L0803fdd8
	add r2, r3
	ldrb.w r5, [r2, #0x5b0]
	b.n .L0803fdea
	.byte 0x00, 0xbf @ padding
.L0803fdcc:
	cbnz r5, .L0803fde4
	add r2, r3
	ldrb.w r2, [r2, #0x5b0]
	ldr r3, [sp, #0x1c]
	b.n .L0803fde0
.L0803fdd8:
	add r2, r3
	ldrb.w r2, [r2, #0x9b0]
	ldr r3, [sp, #0x20]
.L0803fde0:
	subs r5, r2, r3
	b.n .L0803fdea
.L0803fde4:
	add r2, r3
	ldrb.w r5, [r2, #0x9b0]
.L0803fdea:
	ldr r3, [sp, #0x14]
	cmp.w r12, #0
	bgt.n .L0803fdfc
.L0803fdf2:
	movs r2, #0
	qsub16 r2, r2, r12
	sxth.w r12, r2
.L0803fdfc:
	ldr.w r10, [sp, #0x18]
	ldr r4, [sp, #0x30]
	cmp.w r9, #0
	ble.n .L0803fe70
	cmp r1, #0
	ble.n .L0803fe7e
.L0803fe0c:
	cmp r0, #0
	ble.n .L0803fe8a
.L0803fe10:
	uxtb r2, r5
	subs r3, r3, r2
	cmp r3, #0
	bgt.n .L0803fe20
	movs r2, #0
	qsub16 r2, r2, r3
	sxth r3, r2
.L0803fe20:
	ldr.w lr, [sp, #0x2c]
	cmp.w r12, #7
	bgt.w .L0803f9d4
	cmp.w r9, #0xb
	blt.w .L0803f9d4
	cmp r1, #0xb
	blt.w .L0803f9d4
	cmp r0, #7
	bgt.w .L0803f9d4
	cmp r3, #7
	bgt.w .L0803f9d4
	ldr r0, [sp, #0x24]
	cmp r0, #0
	bne.w .L0803f978
	movw r5, #0xf8
	and.w r1, lr, #1
	cmp.w r10, #1
	ubfx r0, lr, #1, #15
	movt r5, #0x2000
	bne.n .L0803fe94
	cbnz r1, .L0803fea0
	add r0, r5
	ldrb.w r12, [r0, #0x5b0]
	b.n .L0803feb4
	.byte 0x00, 0xbf @ padding
.L0803fe70:
	movs r2, #0
	qsub16 r2, r2, r9
	sxth.w r9, r2
	cmp r1, #0
	bgt.n .L0803fe0c
.L0803fe7e:
	movs r2, #0
	qsub16 r1, r2, r1
	sxth r1, r1
	cmp r0, #0
	bgt.n .L0803fe10
.L0803fe8a:
	movs r2, #0
	qsub16 r0, r2, r0
	sxth r0, r0
	b.n .L0803fe10
.L0803fe94:
	cbnz r1, .L0803feae
	add r0, r5
	ldrb.w r0, [r0, #0x5b0]
	ldr r1, [sp, #0x1c]
	b.n .L0803fea8
.L0803fea0:
	add r0, r5
	ldrb.w r0, [r0, #0x9b0]
	ldr r1, [sp, #0x20]
.L0803fea8:
	sub.w r12, r0, r1
	b.n .L0803feb4
.L0803feae:
	add r0, r5
	ldrb.w r12, [r0, #0x9b0]
.L0803feb4:
	uxth r2, r4
	movs r3, #0
	cmp.w r3, r2, lsr #11
	mov r3, r4
	subw r1, r8, #0x7fd
	it ne
	movne r3, r1
	uxth r6, r3
	and.w r0, r3, #1
	cmp.w r10, #1
	lsr.w r3, r6, #1
	bne.n .L0803fee0
	cbnz r0, .L0803feee
	add r3, r5
	ldrb.w r3, [r3, #0x5b0]
	b.n .L0803ff00
.L0803fee0:
	cbnz r0, .L0803fefa
	add r3, r5
	ldrb.w r3, [r3, #0x5b0]
	ldr r6, [sp, #0x1c]
	subs r3, r3, r6
	b.n .L0803ff00
.L0803feee:
	add r3, r5
	ldrb.w r3, [r3, #0x9b0]
	ldr r6, [sp, #0x20]
	subs r3, r3, r6
	b.n .L0803ff00
.L0803fefa:
	add r3, r5
	ldrb.w r3, [r3, #0x9b0]
.L0803ff00:
	uxtb.w r0, r12
	uxtb r3, r3
	subs r0, r0, r3
	uxth r3, r0
	add.w r0, r0, r3, lsr #15
	movs r3, #0
	cmp.w r3, r2, lsr #11
	it ne
	movne r4, r1
	uxth r1, r4
	asrs r0, r0, #1
	and.w r2, r4, #1
	cmp.w r10, #1
	lsr.w r1, r1, #1
	bne.n .L0803ff34
	cbnz r2, .L0803ff40
	add r1, r5
	ldrb.w r1, [r1, #0x5b0]
	b.n .L0803f9be
.L0803ff34:
	cbnz r2, .L0803ff4c
	add r1, r5
	ldrb.w r1, [r1, #0x5b0]
	ldr r2, [sp, #0x1c]
	b.n .L0803ff48
.L0803ff40:
	add r1, r5
	ldrb.w r1, [r1, #0x9b0]
	ldr r2, [sp, #0x20]
.L0803ff48:
	subs r1, r1, r2
	b.n .L0803f9be
.L0803ff4c:
	add r1, r5
	ldrb.w r1, [r1, #0x9b0]
	b.n .L0803f9be
.L0803ff54:
	cmp.w lr, #1
	bne.w .L0803e49a
	cmp r1, #5
	bcc.w .L0803e49a
	ldrb.w r0, [r9, #0xdb0]
	adds r0, #1
.L0803ff68:
	strb.w r0, [r9, #0xdb0]
	b.w .L0803e49a
.L0803ff70:
	cmp r0, #0x12
	mov.w r1, #0
	strh.w r1, [r9, #0xdb8]
	bls.n .L0803ffbc
.L0803ff7c:
	ldr r0, [r7]
	lsls r0, r0, #30
	itttt pl
	ldrpl r0, [r7]
	lslspl.w r0, r0, #30
	ldrpl r0, [r7]
	lslspl.w r0, r0, #30
	bmi.n .L0803ff96
	ldr r0, [r7]
	lsls r0, r0, #30
	bpl.n .L0803ff7c
.L0803ff96:
	movs r0, #0x12
	str r0, [r7, #4]
	nop
.L0803ff9c:
	ldr r0, [r7]
	lsls r0, r0, #31
	itttt eq
	ldreq r0, [r7]
	lslseq.w r0, r0, #31
	ldreq r0, [r7]
	lslseq.w r0, r0, #31
	bne.w .L0803e498
	ldr r0, [r7]
	lsls r0, r0, #31
	beq.n .L0803ff9c
	b.w .L0803e498
.L0803ffbc:
	ldr r1, [r7]
	lsls r1, r1, #30
	itttt pl
	ldrpl r1, [r7]
	lslspl.w r1, r1, #30
	ldrpl r1, [r7]
	lslspl.w r1, r1, #30
	bmi.n .L0803ffd6
	ldr r1, [r7]
	lsls r1, r1, #30
	bpl.n .L0803ffbc
.L0803ffd6:
	adds r0, #1
	str r0, [r7, #4]
	nop
.L0803ffdc:
	ldr r0, [r7]
	lsls r0, r0, #31
	itttt eq
	ldreq r0, [r7]
	lslseq.w r0, r0, #31
	ldreq r0, [r7]
	lslseq.w r0, r0, #31
	bne.w .L0803e498
	ldr r0, [r7]
	lsls r0, r0, #31
	beq.n .L0803ffdc
	b.w .L0803e498
.L0803fffc:
	movw r0, #0x12d
	str.w r0, [r9, #0xdb4]
	b.w .L0803e49a
