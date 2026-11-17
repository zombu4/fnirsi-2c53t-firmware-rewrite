@ draw_waveform_display_p2.inc - part 2 of 7 of draw_waveform_display (bytes 0x080175a8..0x080185a8).
@ Fragment included by part 1; continues the instructions of draw_waveform_display.
@ Unrolled loops (r2 = phase counter 0..4, r0 = running coordinate, r1 = 0x3a29)
@ that test a point against the record at 0x20008350 (halfwords at +0, +2, +4,
@ +6, word at +8) and, when it lies inside, store a halfword (r1, or r4 in the
@ later loops) into the buffer whose pointer is the word at 0x20008350 + 8.
@ Then six draw_line calls (colour r4 on the stack) and a further dotted-point
@ loop starting at .L080184e8; the loop exit continues in the next part.
	movw	r5, #0x8350
	movt	r5, #0x2000
	subs	r6, r0, r6
	ldrh	r5, [r5, #4]
	subs	r6, #2
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x170]
	nop
.L080175cc:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L0801763c
	ldrh	r3, [r5, #0]
	cmp	r3, #0xb8
	bhi.n	.L0801763c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xb9
	bcc.n	.L0801763c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L0801763c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801763c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	mvns	r6, r6
	ldrh	r5, [r5, #4]
	add	r6, r0
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x170]
.L0801763c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L08017550
	ldrh	r3, [r5, #0]
	cmp	r3, #0xb8
	bhi.w	.L08017550
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xb9
	bcc.w	.L08017550
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L08017550
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08017550
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x170]
	b.n	.L08017550
.L080176a4:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L080176c4
	.byte	0x00, 0xbf	@ padding
.L080176b0:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp	r0, #0xdf
	beq.w	.L08017804
.L080176c4:
	lsls	r3, r2, #0x10
	bne.n	.L0801772c
	ldrh	r3, [r5, #0]
	cmp	r3, #0xd1
	bhi.n	.L0801772c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xd2
	bcc.n	.L0801772c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L0801772c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801772c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	subs	r6, r0, r6
	ldrh	r5, [r5, #4]
	subs	r6, #2
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x1a2]
	nop
.L0801772c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L0801779c
	ldrh	r3, [r5, #0]
	cmp	r3, #0xd1
	bhi.n	.L0801779c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xd2
	bcc.n	.L0801779c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L0801779c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801779c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	mvns	r6, r6
	ldrh	r5, [r5, #4]
	add	r6, r0
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x1a2]
.L0801779c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L080176b0
	ldrh	r3, [r5, #0]
	cmp	r3, #0xd1
	bhi.w	.L080176b0
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xd2
	bcc.w	.L080176b0
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L080176b0
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L080176b0
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x1a2]
	b.n	.L080176b0
.L08017804:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L08017824
	.byte	0x00, 0xbf	@ padding
.L08017810:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp	r0, #0xdf
	beq.w	.L08017964
.L08017824:
	lsls	r3, r2, #0x10
	bne.n	.L0801788c
	ldrh	r3, [r5, #0]
	cmp	r3, #0xea
	bhi.n	.L0801788c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xeb
	bcc.n	.L0801788c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L0801788c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801788c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	subs	r6, r0, r6
	ldrh	r5, [r5, #4]
	subs	r6, #2
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x1d4]
	nop
.L0801788c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L080178fc
	ldrh	r3, [r5, #0]
	cmp	r3, #0xea
	bhi.n	.L080178fc
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xeb
	bcc.n	.L080178fc
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L080178fc
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080178fc
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	mvns	r6, r6
	ldrh	r5, [r5, #4]
	add	r6, r0
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x1d4]
.L080178fc:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L08017810
	ldrh	r3, [r5, #0]
	cmp	r3, #0xea
	bhi.w	.L08017810
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xeb
	bcc.w	.L08017810
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L08017810
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08017810
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x1d4]
	b.n	.L08017810
.L08017964:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L08017984
	.byte	0x00, 0xbf	@ padding
.L08017970:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp	r0, #0xdf
	beq.w	.L08017ac4
.L08017984:
	lsls	r3, r2, #0x10
	bne.n	.L080179ec
	ldrh	r3, [r5, #0]
	cmp	r3, #0x9d
	bhi.n	.L080179ec
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x9e
	bcc.n	.L080179ec
	ldrh	r7, [r5, #2]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L080179ec
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080179ec
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	subs	r6, r0, r6
	ldrh	r5, [r5, #4]
	subs	r6, #2
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x13a]
	nop
.L080179ec:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L08017a5c
	ldrh	r3, [r5, #0]
	cmp	r3, #0x9d
	bhi.n	.L08017a5c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x9e
	bcc.n	.L08017a5c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L08017a5c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08017a5c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	mvns	r6, r6
	ldrh	r5, [r5, #4]
	add	r6, r0
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x13a]
.L08017a5c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L08017970
	ldrh	r3, [r5, #0]
	cmp	r3, #0x9d
	bhi.w	.L08017970
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x9e
	bcc.w	.L08017970
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L08017970
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08017970
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x13a]
	b.n	.L08017970
.L08017ac4:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L08017ae4
	.byte	0x00, 0xbf	@ padding
.L08017ad0:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp	r0, #0xdf
	beq.w	.L08017c24
.L08017ae4:
	lsls	r3, r2, #0x10
	bne.n	.L08017b4c
	ldrh	r3, [r5, #0]
	cmp	r3, #0x9e
	bhi.n	.L08017b4c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x9f
	bcc.n	.L08017b4c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08017b4c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08017b4c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	subs	r6, r0, r6
	ldrh	r5, [r5, #4]
	subs	r6, #2
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x13c]
	nop
.L08017b4c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L08017bbc
	ldrh	r3, [r5, #0]
	cmp	r3, #0x9e
	bhi.n	.L08017bbc
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x9f
	bcc.n	.L08017bbc
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L08017bbc
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08017bbc
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	mvns	r6, r6
	ldrh	r5, [r5, #4]
	add	r6, r0
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x13c]
.L08017bbc:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L08017ad0
	ldrh	r3, [r5, #0]
	cmp	r3, #0x9e
	bhi.w	.L08017ad0
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x9f
	bcc.w	.L08017ad0
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L08017ad0
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08017ad0
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x13c]
	b.n	.L08017ad0
.L08017c24:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L08017c44
	.byte	0x00, 0xbf	@ padding
.L08017c30:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp	r0, #0xdf
	beq.w	.L08017d84
.L08017c44:
	lsls	r3, r2, #0x10
	bne.n	.L08017cac
	ldrh	r3, [r5, #0]
	cmp	r3, #0xa0
	bhi.n	.L08017cac
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xa1
	bcc.n	.L08017cac
	ldrh	r7, [r5, #2]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08017cac
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08017cac
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	subs	r6, r0, r6
	ldrh	r5, [r5, #4]
	subs	r6, #2
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x140]
	nop
.L08017cac:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L08017d1c
	ldrh	r3, [r5, #0]
	cmp	r3, #0xa0
	bhi.n	.L08017d1c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xa1
	bcc.n	.L08017d1c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L08017d1c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08017d1c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	mvns	r6, r6
	ldrh	r5, [r5, #4]
	add	r6, r0
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x140]
.L08017d1c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L08017c30
	ldrh	r3, [r5, #0]
	cmp	r3, #0xa0
	bhi.w	.L08017c30
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xa1
	bcc.w	.L08017c30
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L08017c30
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08017c30
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x140]
	b.n	.L08017c30
.L08017d84:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L08017da4
	.byte	0x00, 0xbf	@ padding
.L08017d90:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp	r0, #0xdf
	beq.w	.L08017ee4
.L08017da4:
	lsls	r3, r2, #0x10
	bne.n	.L08017e0c
	ldrh	r3, [r5, #0]
	cmp	r3, #0xa1
	bhi.n	.L08017e0c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xa2
	bcc.n	.L08017e0c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08017e0c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08017e0c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	subs	r6, r0, r6
	ldrh	r5, [r5, #4]
	subs	r6, #2
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x142]
	nop
.L08017e0c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L08017e7c
	ldrh	r3, [r5, #0]
	cmp	r3, #0xa1
	bhi.n	.L08017e7c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xa2
	bcc.n	.L08017e7c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L08017e7c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08017e7c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #2]
	movw	r5, #0x8350
	movt	r5, #0x2000
	mvns	r6, r6
	ldrh	r5, [r5, #4]
	add	r6, r0
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x142]
.L08017e7c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L08017d90
	ldrh	r3, [r5, #0]
	cmp	r3, #0xa1
	bhi.w	.L08017d90
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0xa2
	bcc.w	.L08017d90
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L08017d90
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08017d90
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x142]
	b.n	.L08017d90
.L08017ee4:
	movs	r2, #0
	movs	r0, #0x3d
	movw	r1, #0x3a29
	b.n	.L08017f06
	.byte	0x00, 0xbf	@ padding
.L08017ef0:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x106
	beq.w	.L0801804c
.L08017f06:
	lsls	r3, r2, #0x10
	bne.n	.L08017f70
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08017f70
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08017f70
	ldrh	r3, [r5, #2]
	cmp	r3, #0x76
	bhi.n	.L08017f70
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x77
	bcc.n	.L08017f70
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x76
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L08017f70:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L08017fe4
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L08017fe4
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08017fe4
	ldrh	r3, [r5, #2]
	cmp	r3, #0x76
	bhi.n	.L08017fe4
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x77
	bcc.n	.L08017fe4
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x76
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L08017fe4:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L08017ef0
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L08017ef0
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08017ef0
	ldrh	r3, [r5, #2]
	cmp	r3, #0x76
	bhi.w	.L08017ef0
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x77
	bcc.w	.L08017ef0
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x76
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L08017ef0
.L0801804c:
	movs	r2, #0
	movs	r0, #0x3d
	movw	r1, #0x3a29
	b.n	.L0801806e
	.byte	0x00, 0xbf	@ padding
.L08018058:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x106
	beq.w	.L080181b4
.L0801806e:
	lsls	r3, r2, #0x10
	bne.n	.L080180d8
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L080180d8
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080180d8
	ldrh	r3, [r5, #2]
	cmp	r3, #0x77
	bhi.n	.L080180d8
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x78
	bcc.n	.L080180d8
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x77
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L080180d8:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L0801814c
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L0801814c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801814c
	ldrh	r3, [r5, #2]
	cmp	r3, #0x77
	bhi.n	.L0801814c
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x78
	bcc.n	.L0801814c
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x77
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L0801814c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L08018058
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L08018058
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08018058
	ldrh	r3, [r5, #2]
	cmp	r3, #0x77
	bhi.w	.L08018058
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x78
	bcc.w	.L08018058
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x77
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L08018058
.L080181b4:
	movs	r2, #0
	movs	r0, #0x3d
	movw	r1, #0x3a29
	b.n	.L080181d6
	.byte	0x00, 0xbf	@ padding
.L080181c0:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x106
	beq.w	.L0801831c
.L080181d6:
	lsls	r3, r2, #0x10
	bne.n	.L08018240
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08018240
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018240
	ldrh	r3, [r5, #2]
	cmp	r3, #0x79
	bhi.n	.L08018240
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x7a
	bcc.n	.L08018240
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x79
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L08018240:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L080182b4
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L080182b4
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080182b4
	ldrh	r3, [r5, #2]
	cmp	r3, #0x79
	bhi.n	.L080182b4
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x7a
	bcc.n	.L080182b4
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x79
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L080182b4:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L080181c0
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L080181c0
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L080181c0
	ldrh	r3, [r5, #2]
	cmp	r3, #0x79
	bhi.w	.L080181c0
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x7a
	bcc.w	.L080181c0
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x79
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L080181c0
.L0801831c:
	movs	r2, #0
	movs	r0, #0x3d
	movw	r1, #0x3a29
	b.n	.L0801833e
	.byte	0x00, 0xbf	@ padding
.L08018328:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x106
	beq.w	.L0801ad8c
.L0801833e:
	lsls	r3, r2, #0x10
	bne.n	.L080183a8
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L080183a8
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080183a8
	ldrh	r3, [r5, #2]
	cmp	r3, #0x7a
	bhi.n	.L080183a8
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x7b
	bcc.n	.L080183a8
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x7a
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L080183a8:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.n	.L0801841c
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L0801841c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801841c
	ldrh	r3, [r5, #2]
	cmp	r3, #0x7a
	bhi.n	.L0801841c
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x7b
	bcc.n	.L0801841c
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x7a
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L0801841c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #0x10
	bne.w	.L08018328
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L08018328
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08018328
	ldrh	r3, [r5, #2]
	cmp	r3, #0x7a
	bhi.w	.L08018328
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x7b
	bcc.w	.L08018328
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x7a
	muls	r6, r5
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L08018328
.L08018484:
	movs	r0, #9
	movs	r1, #0x14
	movw	r2, #0x135
	movs	r3, #0x14
	str	r4, [sp, #0]
	bl	draw_line
	movs	r0, #9
	movs	r1, #0xdc
	movw	r2, #0x135
	movs	r3, #0xdc
	str	r4, [sp, #0]
	bl	draw_line
	movs	r0, #9
	movs	r1, #0x14
	movs	r2, #9
	movs	r3, #0xdc
	str	r4, [sp, #0]
	bl	draw_line
	movw	r0, #0x135
	movs	r1, #0x14
	movw	r2, #0x135
	movs	r3, #0xdc
	str	r4, [sp, #0]
	bl	draw_line
	movs	r0, #9
	movs	r1, #0x78
	movw	r2, #0x135
	movs	r3, #0x78
	str	r4, [sp, #0]
	bl	draw_line
	movs	r0, #0x9f
	movs	r1, #0x14
	movs	r2, #0x9f
	movs	r3, #0xdc
	str	r4, [sp, #0]
	bl	draw_line
	movs	r1, #0
	movs	r0, #0xc
	b.n	.L080184f4
.L080184e8:
	adds	r1, #1
	uxth	r2, r1
	cmp	r2, #4
	it	hi
	movhi	r1, #0
	adds	r0, #4
.L080184f4:
	lsls	r2, r1, #0x10
	bne.n	.L08018544
	ldrh	r3, [r5, #0]
	subs	r2, r0, #3
	cmp	r2, r3
	bcc.n	.L08018544
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r2
	bls.n	.L08018544
	ldrh	r2, [r5, #2]
	cmp	r2, #0x2d
	bhi.n	.L08018544
	ldrh	r2, [r5, #2]
	ldrh	r3, [r5, #6]
	add	r2, r3
	cmp	r2, #0x2e
	bcc.n	.L08018544
	movw	r6, #0x8350
	ldr	r2, [r5, #8]
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #2]
	movt	r6, #0x2000
	ldrh	r6, [r6, #4]
	rsb.w	r7, r7, #0x2d
	muls	r7, r6
	subs	r3, r7, r3
	movw	r5, #0x8350
	add	r3, r0
	movt	r5, #0x2000
	add.w	r2, r2, r3, lsl #1
	strh.w	r4, [r2, #-6]
.L08018544:
	adds	r1, #1
	uxth	r2, r1
	cmp	r2, #4
	it	hi
	movhi	r1, #0
	cmp.w	r0, #0x138
	beq.w	.L08018664
	lsls	r2, r1, #0x10
	bne.n	.L080185a8
	ldrh	r3, [r5, #0]
	subs	r2, r0, #2
	cmp	r2, r3
	bcc.n	.L080185a8
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r2
	bls.n	.L080185a8
	ldrh	r2, [r5, #2]
	cmp	r2, #0x2d
	bhi.n	.L080185a8
	ldrh	r2, [r5, #2]
	ldrh	r3, [r5, #6]
	add	r2, r3
	cmp	r2, #0x2e
	bcc.n	.L080185a8
	movw	r6, #0x8350
	ldr	r2, [r5, #8]
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #2]
	movt	r6, #0x2000
	ldrh	r6, [r6, #4]
	rsb.w	r7, r7, #0x2d
	muls	r7, r6
	subs	r3, r7, r3
	movw	r5, #0x8350
	add	r3, r0
	movt	r5, #0x2000
	add.w	r2, r2, r3, lsl #1
	strh.w	r4, [r2, #-4]
	nop
