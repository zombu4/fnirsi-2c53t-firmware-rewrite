	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	rsb.w r6, r6, #0x79
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-0x2]
	nop
.L0801a5cc:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.w .L0801a468
	ldrh r3, [r5, #0x0]
	cmp r0, r3
	bcc.w .L0801a468
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, r0
	bls.w .L0801a468
	ldrh r3, [r5, #0x2]
	cmp r3, #0x79
	bhi.w .L0801a468
	ldrh r3, [r5, #0x2]
	ldrh r7, [r5, #0x6]
	add r3, r7
	cmp r3, #0x7a
	bcc.w .L0801a468
	movw r6, #0x8350
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #0x2]
	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	rsb.w r6, r6, #0x79
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L0801a468
.L0801a634:
	movs r2, #0x0
	movs r0, #0xc
	movw r1, #0x3a29
	b.n .L0801a64c
	.byte 0x00, 0xbf	@ padding
.L0801a640:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	adds r0, #0x4
.L0801a64c:
	lsls r3, r2, #0x10
	bne.n .L0801a6b4
	ldrh r7, [r5, #0x0]
	subs r3, r0, #0x3
	cmp r3, r7
	bcc.n .L0801a6b4
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a6b4
	ldrh r3, [r5, #0x2]
	cmp r3, #0x7a
	bhi.n .L0801a6b4
	ldrh r3, [r5, #0x2]
	ldrh r7, [r5, #0x6]
	add r3, r7
	cmp r3, #0x7b
	bcc.n .L0801a6b4
	movw r6, #0x8350
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #0x2]
	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	rsb.w r6, r6, #0x7a
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-0x6]
.L0801a6b4:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	cmp.w r0, #0x138
	beq.w .L0801a80c
	lsls r3, r2, #0x10
	bne.n .L0801a730
	ldrh r7, [r5, #0x0]
	subs r3, r0, #0x2
	cmp r3, r7
	bcc.n .L0801a730
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a730
	ldrh r3, [r5, #0x2]
	cmp r3, #0x7a
	bhi.n .L0801a730
	ldrh r3, [r5, #0x2]
	ldrh r7, [r5, #0x6]
	add r3, r7
	cmp r3, #0x7b
	bcc.n .L0801a730
	movw r6, #0x8350
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #0x2]
	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	rsb.w r6, r6, #0x7a
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-0x4]
	nop
.L0801a730:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.n .L0801a7a4
	ldrh r7, [r5, #0x0]
	subs r3, r0, #0x1
	cmp r3, r7
	bcc.n .L0801a7a4
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a7a4
	ldrh r3, [r5, #0x2]
	cmp r3, #0x7a
	bhi.n .L0801a7a4
	ldrh r3, [r5, #0x2]
	ldrh r7, [r5, #0x6]
	add r3, r7
	cmp r3, #0x7b
	bcc.n .L0801a7a4
	movw r6, #0x8350
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #0x2]
	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	rsb.w r6, r6, #0x7a
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-0x2]
	nop
.L0801a7a4:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.w .L0801a640
	ldrh r3, [r5, #0x0]
	cmp r0, r3
	bcc.w .L0801a640
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, r0
	bls.w .L0801a640
	ldrh r3, [r5, #0x2]
	cmp r3, #0x7a
	bhi.w .L0801a640
	ldrh r3, [r5, #0x2]
	ldrh r7, [r5, #0x6]
	add r3, r7
	cmp r3, #0x7b
	bcc.w .L0801a640
	movw r6, #0x8350
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #0x2]
	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	rsb.w r6, r6, #0x7a
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L0801a640
.L0801a80c:
	movs r2, #0x0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L0801a82c
	.byte 0x00, 0xbf	@ padding
.L0801a818:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	add.w r0, r0, #0x3
	it hi
	movhi r2, #0x0
	cmp r0, #0xdf
	beq.w .L0801a96c
.L0801a82c:
	lsls r3, r2, #0x10
	bne.n .L0801a894
	ldrh r3, [r5, #0x0]
	cmp r3, #0x9d
	bhi.n .L0801a894
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0x9e
	bcc.n .L0801a894
	ldrh r7, [r5, #0x2]
	subs r3, r0, #0x2
	cmp r3, r7
	bcc.n .L0801a894
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x2]
	ldrh r6, [r6, #0x6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a894
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #0x4]
	subs r6, #0x2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13a]
	nop
.L0801a894:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.n .L0801a904
	ldrh r3, [r5, #0x0]
	cmp r3, #0x9d
	bhi.n .L0801a904
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0x9e
	bcc.n .L0801a904
	ldrh r7, [r5, #0x2]
	subs r3, r0, #0x1
	cmp r3, r7
	bcc.n .L0801a904
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x2]
	ldrh r6, [r6, #0x6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a904
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #0x4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13a]
.L0801a904:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.w .L0801a818
	ldrh r3, [r5, #0x0]
	cmp r3, #0x9d
	bhi.w .L0801a818
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0x9e
	bcc.w .L0801a818
	ldrh r3, [r5, #0x2]
	cmp r0, r3
	bcc.w .L0801a818
	ldrh r3, [r5, #0x2]
	ldrh r7, [r5, #0x6]
	add r3, r7
	cmp r3, r0
	bls.w .L0801a818
	movw r6, #0x8350
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #0x2]
	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13a]
	b.n .L0801a818
.L0801a96c:
	movs r2, #0x0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L0801a98c
	.byte 0x00, 0xbf	@ padding
.L0801a978:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	add.w r0, r0, #0x3
	it hi
	movhi r2, #0x0
	cmp r0, #0xdf
	beq.w .L0801aacc
.L0801a98c:
	lsls r3, r2, #0x10
	bne.n .L0801a9f4
	ldrh r3, [r5, #0x0]
	cmp r3, #0x9e
	bhi.n .L0801a9f4
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0x9f
	bcc.n .L0801a9f4
	ldrh r7, [r5, #0x2]
	subs r3, r0, #0x2
	cmp r3, r7
	bcc.n .L0801a9f4
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x2]
	ldrh r6, [r6, #0x6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a9f4
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #0x4]
	subs r6, #0x2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13c]
	nop
.L0801a9f4:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.n .L0801aa64
	ldrh r3, [r5, #0x0]
	cmp r3, #0x9e
	bhi.n .L0801aa64
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0x9f
	bcc.n .L0801aa64
	ldrh r7, [r5, #0x2]
	subs r3, r0, #0x1
	cmp r3, r7
	bcc.n .L0801aa64
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x2]
	ldrh r6, [r6, #0x6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801aa64
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #0x4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13c]
.L0801aa64:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.w .L0801a978
	ldrh r3, [r5, #0x0]
	cmp r3, #0x9e
	bhi.w .L0801a978
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0x9f
	bcc.w .L0801a978
	ldrh r3, [r5, #0x2]
	cmp r0, r3
	bcc.w .L0801a978
	ldrh r3, [r5, #0x2]
	ldrh r7, [r5, #0x6]
	add r3, r7
	cmp r3, r0
	bls.w .L0801a978
	movw r6, #0x8350
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #0x2]
	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13c]
	b.n .L0801a978
.L0801aacc:
	movs r2, #0x0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L0801aaec
	.byte 0x00, 0xbf	@ padding
.L0801aad8:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	add.w r0, r0, #0x3
	it hi
	movhi r2, #0x0
	cmp r0, #0xdf
	beq.w .L0801ac2c
.L0801aaec:
	lsls r3, r2, #0x10
	bne.n .L0801ab54
	ldrh r3, [r5, #0x0]
	cmp r3, #0xa0
	bhi.n .L0801ab54
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0xa1
	bcc.n .L0801ab54
	ldrh r7, [r5, #0x2]
	subs r3, r0, #0x2
	cmp r3, r7
	bcc.n .L0801ab54
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x2]
	ldrh r6, [r6, #0x6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801ab54
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #0x4]
	subs r6, #0x2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x140]
	nop
.L0801ab54:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.n .L0801abc4
	ldrh r3, [r5, #0x0]
	cmp r3, #0xa0
	bhi.n .L0801abc4
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0xa1
	bcc.n .L0801abc4
	ldrh r7, [r5, #0x2]
	subs r3, r0, #0x1
	cmp r3, r7
	bcc.n .L0801abc4
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x2]
	ldrh r6, [r6, #0x6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801abc4
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #0x4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x140]
.L0801abc4:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.w .L0801aad8
	ldrh r3, [r5, #0x0]
	cmp r3, #0xa0
	bhi.w .L0801aad8
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0xa1
	bcc.w .L0801aad8
	ldrh r3, [r5, #0x2]
	cmp r0, r3
	bcc.w .L0801aad8
	ldrh r3, [r5, #0x2]
	ldrh r7, [r5, #0x6]
	add r3, r7
	cmp r3, r0
	bls.w .L0801aad8
	movw r6, #0x8350
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #0x2]
	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x140]
	b.n .L0801aad8
.L0801ac2c:
	movs r2, #0x0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L0801ac4c
	.byte 0x00, 0xbf	@ padding
.L0801ac38:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	add.w r0, r0, #0x3
	it hi
	movhi r2, #0x0
	cmp r0, #0xdf
	beq.w .L0801ad8c
.L0801ac4c:
	lsls r3, r2, #0x10
	bne.n .L0801acb4
	ldrh r3, [r5, #0x0]
	cmp r3, #0xa1
	bhi.n .L0801acb4
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0xa2
	bcc.n .L0801acb4
	ldrh r7, [r5, #0x2]
	subs r3, r0, #0x2
	cmp r3, r7
	bcc.n .L0801acb4
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x2]
	ldrh r6, [r6, #0x6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801acb4
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #0x4]
	subs r6, #0x2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x142]
	nop
.L0801acb4:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.n .L0801ad24
	ldrh r3, [r5, #0x0]
	cmp r3, #0xa1
	bhi.n .L0801ad24
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0xa2
	bcc.n .L0801ad24
	ldrh r7, [r5, #0x2]
	subs r3, r0, #0x1
	cmp r3, r7
	bcc.n .L0801ad24
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #0x2]
	ldrh r6, [r6, #0x6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801ad24
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	ldrh r6, [r6, #0x2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #0x4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x142]
.L0801ad24:
	adds r2, #0x1
	uxth r3, r2
	cmp r3, #0x4
	it hi
	movhi r2, #0x0
	lsls r3, r2, #0x10
	bne.w .L0801ac38
	ldrh r3, [r5, #0x0]
	cmp r3, #0xa1
	bhi.w .L0801ac38
	ldrh r3, [r5, #0x0]
	ldrh r7, [r5, #0x4]
	add r3, r7
	cmp r3, #0xa2
	bcc.w .L0801ac38
	ldrh r3, [r5, #0x2]
	cmp r0, r3
	bcc.w .L0801ac38
	ldrh r3, [r5, #0x2]
	ldrh r7, [r5, #0x6]
	add r3, r7
	cmp r3, r0
	bls.w .L0801ac38
	movw r6, #0x8350
	ldr r3, [r5, #0x8]
	ldrh r7, [r5, #0x0]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #0x2]
	movt r5, #0x2000
	ldrh r5, [r5, #0x4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x142]
	b.n .L0801ac38
.L0801ad8c:
	ldrb.w r9, [r8, #0x3c]
	cmp.w r9, #0x0
	beq.w .L0801b4ca
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x2e]
	cmp r0, #0x0
	beq.w .L0801b4ca
	cmp.w r9, #0x3
	bne.w .L0801afa6
	movw r0, #0xf8
	movt r0, #0x2000
	ldr.w r10, [r0, #0x40]
	cmp.w r10, #0x0
	beq.w .L0801b4ca
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0x34]
	cmp r1, #0x0
	beq.w .L0801b2a2
	ldr.w r1, [r10, #0x4]
	cmp r1, #0x0
	beq.w .L0801b4ca
	ldrb.w r0, [r10, #0x0]
	movw r2, #0x8081
	rsb r0, r0, r0, lsl #5
	movt r2, #0x8080
	umull r0, r2, r0, r2
	lsrs r0, r2, #0x7
	orr.w r8, r0, r0, lsl #11
	mov.w r9, #0x0
	mov.w r12, #0x1a
	mov.w lr, #0x3b0000
	b.n .L0801ae18
	.byte 0x00, 0xbf	@ padding
.L0801ae0c:
	add.w r9, r9, #0x1
	cmp.w r9, #0xc9
	beq.w .L0801b4ca
.L0801ae18:
	add.w r3, lr, r9, lsl #16
	mul r5, r9, r12
	asrs r4, r3, #0x10
	movs r3, #0xc9
	movs r6, #0x2
	b.n .L0801ae30
.L0801ae28:
	subs r3, #0x3
	add.w r6, r6, #0x3
	beq.n .L0801ae0c
.L0801ae30:
	subs r7, r6, #0x2
	ubfx r0, r7, #3, #5
	add r0, r5
	ldrb r0, [r1, r0]
	and r7, r7, #0x7
	lsrs r0, r7
	lsls r0, r0, #0x1f
	beq.n .L0801aea8
	movw r0, #0x8350
	movt r0, #0x2000
	ldrh r0, [r0, #0x0]
	cmp r4, r0
	bcc.n .L0801aea8
	movw r2, #0x8350
	movt r2, #0x2000
	ldrh r0, [r2, #0x0]
	ldrh r7, [r2, #0x4]
	add r0, r7
	cmp r0, r4
	bls.n .L0801aea8
	movw r0, #0x8350
	movt r0, #0x2000
	ldrh r0, [r0, #0x2]
	add.w r7, r3, #0x13
	cmp r7, r0
	bcc.n .L0801aea8
	movw r2, #0x8350
	movt r2, #0x2000
	ldrh r0, [r2, #0x2]
	ldrh r2, [r2, #0x6]
	add r0, r2
	cmp r0, r7
	bls.n .L0801aea8
	movw r0, #0x8350
	movt r0, #0x2000
	ldr.w r10, [r0, #0x8]
	ldrh r2, [r0, #0x0]
	ldrh r7, [r0, #0x2]
	ldrh r0, [r0, #0x4]
	subs r7, r3, r7
	subs r2, r4, r2
	adds r7, #0x13
	mla r0, r7, r0, r2
	strh.w r8, [r10, r0, lsl #1]
.L0801aea8:
	subs r0, r6, #0x1
	ubfx r2, r0, #3, #5
	add r2, r5
	ldrb r2, [r1, r2]
	and r0, r0, #0x7
	lsr.w r0, r2, r0
	lsls r0, r0, #0x1f
	beq.n .L0801af24
	movw r0, #0x8350
	movt r0, #0x2000
	ldrh r0, [r0, #0x0]
	cmp r4, r0
	bcc.n .L0801af24
	movw r2, #0x8350
	movt r2, #0x2000
	ldrh r0, [r2, #0x0]
	ldrh r2, [r2, #0x4]
	add r0, r2
	cmp r0, r4
	bls.n .L0801af24
	movw r0, #0x8350
	movt r0, #0x2000
	ldrh r0, [r0, #0x2]
	add.w r7, r3, #0x12
	cmp r7, r0
	bcc.n .L0801af24
	movw r2, #0x8350
	movt r2, #0x2000
	ldrh r0, [r2, #0x2]
	ldrh r2, [r2, #0x6]
	add r0, r2
	cmp r0, r7
	bls.n .L0801af24
	movw r0, #0x8350
	movt r0, #0x2000
	ldr.w r10, [r0, #0x8]
	ldrh r2, [r0, #0x0]
	ldrh r7, [r0, #0x2]
	ldrh r0, [r0, #0x4]
	subs r7, r3, r7
	subs r2, r4, r2
	adds r7, #0x12
	mla r0, r7, r0, r2
	strh.w r8, [r10, r0, lsl #1]
	nop
.L0801af24:
	ubfx r0, r6, #3, #5
	add r0, r5
	ldrb r0, [r1, r0]
	and r2, r6, #0x7
	lsrs r0, r2
	lsls r0, r0, #0x1f
	beq.w .L0801ae28
	movw r0, #0x8350
	movt r0, #0x2000
	ldrh r0, [r0, #0x0]
	cmp r4, r0
	bcc.w .L0801ae28
	movw r2, #0x8350
	movt r2, #0x2000
	ldrh r0, [r2, #0x0]
	ldrh r2, [r2, #0x4]
	add r0, r2
	cmp r0, r4
	bls.w .L0801ae28
	movw r0, #0x8350
	movt r0, #0x2000
	ldrh r0, [r0, #0x2]
	add.w r7, r3, #0x11
	cmp r7, r0
	bcc.w .L0801ae28
	movw r2, #0x8350
	movt r2, #0x2000
	ldrh r0, [r2, #0x2]
	ldrh r2, [r2, #0x6]
	add r0, r2
	cmp r0, r7
	bls.w .L0801ae28
	movw r0, #0x8350
	movt r0, #0x2000
	ldr.w r10, [r0, #0x8]
	ldrh r2, [r0, #0x0]
	ldrh r7, [r0, #0x2]
	ldrh r0, [r0, #0x4]
	subs r7, r3, r7
	subs r2, r4, r2
	adds r7, #0x11
	mla r0, r7, r0, r2
	strh.w r8, [r10, r0, lsl #1]
	b.n .L0801ae28
.L0801afa6:
	movw r2, #0xf8
	movt r2, #0x2000
	ldrb.w r0, [r2, #0x3d]
	ldrb.w r1, [r2, #0x3e]
	strb.w r0, [r2, #0x3e]
	cmp r0, r1
	it ls
	addls r0, #0x64
	ldr.w r10, [r2, #0x40]
	subs r4, r0, r1
	cmp.w r10, #0x0
	strb.w r4, [r2, #0x3f]
	beq.w .L0801b4ca
	vldr d0, .L0801b350
	movw r0, #0xf8
	movt r0, #0x2000
	add.w r8, r0, #0x40
	vmov r0, r1, d0
	strd r1, r0, [sp, #0x28]
	b.n .L0801b010
.L0801afec:
	ldr r1, [r5, #0x0]
	movs r0, #0x0
	blx r1
.L0801aff2:
	mov r8, r4
	str.w r10, [r8, #0x40]!
	cmp.w r10, #0x0
	beq.w .L0801b4ca
.L0801b000:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r9, [r0, #0x3c]
	ldrb.w r4, [r0, #0x3f]
.L0801b010:
	ldrb.w r0, [r10, #0x0]
	bl u32_to_double
	mov r6, r0
	uxtb r0, r4
	mov r11, r1
	bl u32_to_double
	ldrd r3, r2, [sp, #0x28]
	bl double_mul
	mov r4, r0
	rsb.w r0, r9, #0x3
	mov r5, r1
	bl i32_to_double
	mov r2, r0
	mov r3, r1
	mov r0, r4
	mov r1, r5
	bl double_mul
	mov r2, r6
	mov r3, r11
	mov r4, r0
	mov r5, r1
	bl double_ge
	cmp r0, #0x0
	bne.n .L0801b0f8
	mov r0, r6
	mov r1, r11
	mov r2, r4
	mov r3, r5
	bl double_sub
	bl double_to_i32
	movw r2, #0xf8
	movt r2, #0x2000
	ldrb.w r1, [r2, #0x34]
	strb.w r0, [r10, #0x0]
	cmp r1, #0x0
	beq.n .L0801b138
	ldr r1, [r2, #0x40]
	ldr r2, [r1, #0x4]
	cmp r2, #0x0
	beq.w .L0801b214
	ldr r1, [r1, #0x8]
	cmp r1, #0x0
	beq.w .L0801b214
	ldrh.w r1, [r10, #0xe]
	cmp r1, #0x2
	bcc.w .L0801b214
	ldrh.w r2, [r10, #0xc]
	add r1, r2
	subs r1, #0x1
	cmp r1, r2
	ble.w .L0801b214
	movw r1, #0x8081
	rsb r0, r0, r0, lsl #5
	movt r1, #0x8080
	umull r0, r1, r0, r1
	lsrs r0, r1, #0x7
	orr.w r4, r0, r0, lsl #11
	mov r5, r2
.L0801b0b8:
	ldrd r3, r7, [r10, #0x4]
	ldrb r0, [r3, r2]
	ldrb r1, [r7, r2]
	adds r2, #0x1
	ldrb r3, [r3, r2]
	ldrb r7, [r7, r2]
	adds r0, #0x1f
	rsb.w r1, r1, #0xf8
	add.w r2, r3, #0x1f
	rsb.w r3, r7, #0xf8
	uxth r7, r4
	str r7, [sp, #0x0]
	bl draw_line
	ldr.w r10, [r8, #0x0]
	adds r5, #0x1
	ldrh.w r0, [r10, #0xc]
	ldrh.w r1, [r10, #0xe]
	uxth r2, r5
	add r0, r1
	subs r0, #0x1
	cmp r0, r2
	bgt.n .L0801b0b8
	b.n .L0801b214
	.byte 0x00, 0xbf	@ padding
.L0801b0f8:
	ldr.w r0, [r10, #0x4]
	movw r5, #0x1070
	cmp r0, #0x0
	movt r5, #0x2000
	beq.w .L0801b22a
	ldrb r1, [r5, #0x10]
	cmp r1, #0x0
	beq.w .L0801b224
	ldr r1, [r5, #0x8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.w .L0801b22a
	ldr r2, [r5, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r2, r0, lsl #1]
	cmp r1, #0x0
	beq.w .L0801b22a
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L0801b22a
.L0801b138:
	ldrb r0, [r2, #0x15]
	and r1, r0, #0xf
	cmp.w r1, r0, lsr #4
	bls.n .L0801b214
	lsrs r4, r0, #0x4
	b.n .L0801b152
.L0801b148:
	adds r4, #0x1
	and r1, r0, #0xf
	cmp r4, r1
	bcs.n .L0801b214
.L0801b152:
	ldr r1, [r2, #0x40]
	add.w r1, r1, r4, lsl #2
	ldr r1, [r1, #0x4]
	cmp r1, #0x0
	beq.n .L0801b148
	ldrh.w r1, [r10, #0xe]
	cmp r1, #0x2
	bcc.n .L0801b148
	ldrh.w r1, [r10, #0xe]
	cmp r1, #0x2
	bcc.n .L0801b148
	ldrb.w r0, [r2, #0xf63]
	movw r1, #:lower16:d_080bb40c
	movt r1, #:upper16:d_080bb40c
	add.w r0, r1, r0, lsl #2
	ldrh.w r0, [r0, r4, lsl #1]
	ldrb.w r1, [r10, #0x0]
	lsrs r2, r0, #0xb
	movw r6, #0x8081
	muls r2, r1
	movt r6, #0x8080
	umull r2, r3, r2, r6
	ubfx r2, r0, #5, #6
	and r0, r0, #0x1f
	muls r2, r1
	muls r0, r1
	umull r2, r7, r2, r6
	umull r0, r1, r0, r6
	lsls r0, r3, #0x4
	movw r2, #0x7ff
	bics r0, r2
	mvn r2, #0x1f
	and.w r2, r2, r7, lsr #2
	orr.w r1, r2, r1, lsr #7
	orr.w r9, r1, r0
	movs r0, #0x0
	movs r6, #0x0
	nop
.L0801b1c8:
	ldrh.w r1, [r10, #0xc]
	uxth.w r5, r9
	adds r2, r1, r6
	add.w r1, r10, r4, lsl #2
	ldr r1, [r1, #0x4]
	add.w r7, r2, #0x9
	ldrb r3, [r1, r0]
	add r0, r1
	ldrb r0, [r0, #0x1]
	adds r2, #0xa
	rsb.w r1, r3, #0xf8
	rsb.w r3, r0, #0xf8
	sxth r0, r7
	sxth r2, r2
	str r5, [sp, #0x0]
	bl fn_0801fea8
	ldr.w r10, [r8, #0x0]
	adds r6, #0x1
	ldrh.w r1, [r10, #0xe]
	uxth r0, r6
	subs r1, #0x1
	cmp r1, r0
	bgt.n .L0801b1c8
	movw r2, #0xf8
	movt r2, #0x2000
	ldrb r0, [r2, #0x15]
	b.n .L0801b148
.L0801b214:
	mov r8, r10
	ldr.w r10, [r8, #0x10]!
	cmp.w r10, #0x0
	bne.w .L0801b000
	b.n .L0801b4ca
.L0801b224:
	ldr r1, [r5, #0x0]
	movs r0, #0x0
	blx r1
.L0801b22a:
	ldr.w r0, [r8, #0x0]
	movw r4, #0xf8
	ldr r0, [r0, #0x8]
	movt r4, #0x2000
	cbz r0, .L0801b264
	ldrb r1, [r5, #0x10]
	cbz r1, .L0801b25e
	ldr r1, [r5, #0x8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0801b264
	ldr r2, [r5, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0801b264
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L0801b264
.L0801b25e:
	ldr r1, [r5, #0x0]
	movs r0, #0x0
	blx r1
.L0801b264:
	ldr.w r1, [r8, #0x0]
	ldr r0, [r4, #0x40]
	ldr.w r10, [r1, #0x10]
	cmp r0, #0x0
	beq.w .L0801aff2
	ldrb r1, [r5, #0x10]
	cmp r1, #0x0
	beq.w .L0801afec
	ldr r1, [r5, #0x8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.w .L0801aff2
	ldr r2, [r5, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r2, r0, lsl #1]
	cmp r1, #0x0
	beq.w .L0801aff2
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L0801aff2
.L0801b2a2:
	ldrb r1, [r0, #0x15]
	and r0, r1, #0xf
	cmp.w r0, r1, lsr #4
	str r0, [sp, #0x2c]
	bls.w .L0801b4ca
	movw r0, #0xf8
	movt r0, #0x2000
	lsr.w r9, r1, #4
	ldrb.w r1, [r0, #0xf63]
	movw r3, #:lower16:d_080bb40c
	movt r3, #:upper16:d_080bb40c
	add.w r0, r3, r1, lsl #2
	str r0, [sp, #0x28]
	b.n .L0801b2e0
	.byte 0x00, 0xbf	@ padding
.L0801b2d4:
	ldr r0, [sp, #0x2c]
	add.w r9, r9, #0x1
	cmp r9, r0
	beq.w .L0801b4ca
.L0801b2e0:
	add.w r1, r10, r9, lsl #2
	ldr r3, [r1, #0x4]
	cmp r3, #0x0
	beq.n .L0801b2d4
	ldrh.w r3, [r10, #0xe]
	cmp r3, #0x0
	beq.n .L0801b2d4
	ldr r0, [sp, #0x28]
	ldrb.w r7, [r10, #0x0]
	ldrh.w r3, [r0, r9, lsl #1]
	movw r0, #0x8081
	lsrs r6, r3, #0xb
	muls r6, r7
	movt r0, #0x8080
	umull r6, r5, r6, r0
	ubfx r6, r3, #5, #6
	and r3, r3, #0x1f
	muls r3, r7
	muls r6, r7
	umull r3, r7, r3, r0
	umull r6, r4, r6, r0
	lsls r3, r5, #0x4
	movw r0, #0x7ff
	bic.w r6, r3, r0
	mvn r0, #0x1f
	and.w r3, r0, r4, lsr #2
	orr.w r7, r3, r7, lsr #7
	ldrh.w r4, [r10, #0xc]
	ldr r3, [r1, #0x4]
	orr.w r11, r7, r6
	movw r6, #0x8350
	movt r6, #0x2000
	b.n .L0801b36a
	.byte 0x00, 0xbf, 0x00, 0xbf, 0x00, 0xbf	@ padding
.L0801b350:
	.word 0x66666666, 0x40046666	@ double 2.55 (0x4004666666666666), read by vldr d0 at 0x0801afd2
.L0801b358:
	ldrh.w r1, [r10, #0xc]
	ldrh.w r7, [r10, #0xe]
	adds r4, #0x1
	uxth r5, r4
	add r1, r7
	cmp r1, r5
	bls.n .L0801b2d4
.L0801b36a:
	movs r0, #0x1a
	add.w r7, r4, #0x9
	smulbb r1, r0, r4
	sxth r5, r7
	mov.w r12, #0xc6
	mov.w lr, #0x2
	nop
.L0801b380:
	sub.w r7, lr, #0x2
	ubfx r8, r7, #3, #13
	add.w r2, r1, r8
	ldrb r2, [r3, r2]
	and r7, r7, #0x7
	lsrs r2, r7
	lsls r2, r2, #0x1f
	beq.n .L0801b3e4
	ldrh r2, [r6, #0x0]
	cmp r5, r2
	blt.n .L0801b3e4
	ldrh r2, [r6, #0x0]
	ldrh r7, [r6, #0x4]
	add r2, r7
	cmp r2, r5
	ble.n .L0801b3e4
	ldrh r2, [r6, #0x2]
	add.w r7, r12, #0x16
	cmp r7, r2
	bcc.n .L0801b3e4
	ldrh r2, [r6, #0x2]
	ldrh r0, [r6, #0x6]
	add r0, r2
	cmp r0, r7
	bls.n .L0801b3e4
	ldr r0, [r6, #0x8]
	ldrh r2, [r6, #0x0]
	ldrh r7, [r6, #0x2]
	movw r6, #0x8350
	movt r6, #0x2000
	sub.w r7, r12, r7
	ldrh r6, [r6, #0x4]
	subs r2, r5, r2
	adds r7, #0x16
	mla r2, r7, r6, r2
	movw r6, #0x8350
	movt r6, #0x2000
	strh.w r11, [r0, r2, lsl #1]
.L0801b3e4:
	sub.w r0, lr, #0x1
	ubfx r2, r0, #3, #13
	add r2, r1
	ldrb r2, [r3, r2]
	and r0, r0, #0x7
	lsr.w r0, r2, r0
	lsls r0, r0, #0x1f
	beq.n .L0801b450
	ldrh r0, [r6, #0x0]
	cmp r5, r0
	blt.n .L0801b450
	ldrh r0, [r6, #0x0]
	ldrh r2, [r6, #0x4]
	add r0, r2
	cmp r0, r5
	ble.n .L0801b450
	ldrh r0, [r6, #0x2]
	add.w r7, r12, #0x15
	cmp r7, r0
	bcc.n .L0801b450
	ldrh r0, [r6, #0x2]
	ldrh r2, [r6, #0x6]
	add r0, r2
	cmp r0, r7
	bls.n .L0801b450
	ldr r0, [r6, #0x8]
	ldrh r2, [r6, #0x0]
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r6, [r6, #0x2]
	movw r7, #0x8350
	movt r7, #0x2000
	sub.w r6, r12, r6
	ldrh r7, [r7, #0x4]
	subs r2, r5, r2
	adds r6, #0x15
	mla r2, r6, r7, r2
	movw r6, #0x8350
	movt r6, #0x2000
	strh.w r11, [r0, r2, lsl #1]
.L0801b450:
	ubfx r0, lr, #3, #13
	add r0, r1
	ldrb r0, [r3, r0]
	and r2, lr, #0x7
	lsrs r0, r2
	lsls r0, r0, #0x1f
	beq.n .L0801b4b8
	ldrh r0, [r6, #0x0]
	cmp r5, r0
	blt.n .L0801b4b8
	ldrh r0, [r6, #0x0]
	ldrh r2, [r6, #0x4]
	add r0, r2
	cmp r0, r5
	ble.n .L0801b4b8
	ldrh r0, [r6, #0x2]
	add.w r7, r12, #0x14
	cmp r7, r0
	bcc.n .L0801b4b8
	ldrh r0, [r6, #0x2]
	ldrh r2, [r6, #0x6]
	add r0, r2
	cmp r0, r7
	bls.n .L0801b4b8
	ldr r0, [r6, #0x8]
	ldrh r2, [r6, #0x0]
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r6, [r6, #0x2]
	movw r7, #0x8350
	movt r7, #0x2000
	sub.w r6, r12, r6
	ldrh r7, [r7, #0x4]
	subs r2, r5, r2
	adds r6, #0x14
	mla r2, r6, r7, r2
	movw r6, #0x8350
	movt r6, #0x2000
	strh.w r11, [r0, r2, lsl #1]
	nop
.L0801b4b8:
	cmp.w r12, #0x0
	beq.w .L0801b358
	sub.w r12, r12, #0x3
	add.w lr, lr, #0x3
	b.n .L0801b380
.L0801b4ca:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrh.w r3, [r0, #0xdb6]
	movw r10, #0xf81f
	cmp r3, #0x0
	beq.w .L0801b800
	movw r9, #0xf8
	movt r9, #0x2000
	ldrb.w r0, [r9, #0x34]
	cmp r0, #0x0
	beq.n .L0801b5aa
	cmp r3, #0x2
	bcc.w .L0801b8ec
	ldrb.w r0, [r9, #0x2e]
	cmp r0, #0x0
	bne.w .L0801b7a6
	ldr.w r0, [r9, #0xe08]
	ldr.w r1, [r9, #0xe0c]
	subs.w r2, r0, #0x3e8
	sbcs r2, r1, #0x0
	bcc.w .L0801b7a6
	mov r5, r9
	mov.w r9, #0x0
	movw r8, #0x12d
	addw r6, r5, #0x356
	mov.w r11, #0x1
	movs r4, #0x0
.L0801b528:
	uxth r2, r3
	umull r0, r3, r0, r2
	mla r1, r1, r2, r3
	mov.w r2, #0x3e8
	movs r3, #0x0
	uxth r7, r4
	bl divide_u64
	ldrh.w r2, [r5, #0xde0]
	sub.w r2, r8, r2
	subs r3, r0, r2
	sbcs.w r3, r1, r2, asr #31
	mov.w r3, #0x0
	it cc
	movcc r3, #0x1
	cmp r3, #0x0
	ite eq
	asreq r1, r2, #0x1f
	movne r2, r0
	subs r0, r2, #0x1
	sbc r1, r1, #0x0
	subs r0, r7, r0
	sbcs.w r0, r9, r1
	bcs.w .L0801b800
	movw r5, #0xf8
	movt r5, #0x2000
	addw r2, r5, #0x483
	uxtah r3, r11, r4
	ldrb r0, [r6, r7]
	ldrb r1, [r2, r7]
	ldrb r7, [r6, r3]
	ldrb r3, [r2, r3]
	adds r0, #0x1f
	rsb.w r1, r1, #0xf8
	add.w r2, r7, #0x1f
	rsb.w r3, r3, #0xf8
	str.w r10, [sp, #0x0]
	bl draw_line
	ldrh.w r3, [r5, #0xdb6]
	ldr.w r0, [r5, #0xe08]
	ldr.w r1, [r5, #0xe0c]
	adds r4, #0x1
	b.n .L0801b528
