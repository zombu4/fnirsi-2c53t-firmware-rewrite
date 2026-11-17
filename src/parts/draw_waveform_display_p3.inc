@ draw_waveform_display_p3.inc - part 3 of 7 of draw_waveform_display (0x080185a8..0x080195a9).
@ Fragment included by part 1; continues the instruction stream of draw_waveform_display.
@
@ This part draws bounds-checked pixel groups into the frame buffer. Registers used by
@ every group: r5 = clip record at 0x20008350 (halfwords: [0] x0, [2] y0, [4] width,
@ [6] height, word [8] = frame buffer base), r0 = x position, r1 = colour (0x3a29 in the
@ marker groups), r2 = 0..4 phase counter that wraps to 0 after 4, r7/r6/r3 = scratch.
@ Every store writes one halfword at base + 2 * (x - x0 + (limit - y) * width) with a
@ small byte offset; a store is skipped when the point is outside the clip rectangle.
@ Part 3 starts with the tail of one group (colour in r4), then six groups limited to
@ y <= 0x46, 0x5f, 0x78, 0x91, 0xaa, 0xc3 (x runs 0xc..0x138 in steps of 4), then groups
@ using a stride of 3 in x (0x16..0xdf) with fixed offsets 0x44, 0x76, 0xa8.

.L080185a8:
	adds	r1, #1
	uxth	r2, r1
	cmp	r2, #4
	it	hi
	movhi	r1, #0
	lsls	r2, r1, #16
	bne.n	.L08018604
	ldrh	r3, [r5, #0]
	subs	r2, r0, #1
	cmp	r2, r3
	bcc.n	.L08018604
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r2
	bls.n	.L08018604
	ldrh	r2, [r5, #2]
	cmp	r2, #0x2d
	bhi.n	.L08018604
	ldrh	r2, [r5, #2]
	ldrh	r3, [r5, #6]
	add	r2, r3
	cmp	r2, #0x2e
	bcc.n	.L08018604
	movw	r6, #0x8350
	ldr	r2, [r5, #8]
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #2]
	movt	r6, #0x2000
	ldrh	r6, [r6, #4]
	rsb.w	r7, r7, #0x2d
	muls	r7, r6, r7
	subs	r3, r7, r3
	movw	r5, #0x8350
	add	r3, r0
	movt	r5, #0x2000
	add.w	r2, r2, r3, lsl #1
	strh	r4, [r2, #-2]
	nop
.L08018604:
	adds	r1, #1
	uxth	r2, r1
	cmp	r2, #4
	it	hi
	movhi	r1, #0
	lsls	r2, r1, #16
	bne.w	.L080184e8
	ldrh	r2, [r5, #0]
	cmp	r0, r2
	bcc.w	.L080184e8
	ldrh	r2, [r5, #0]
	ldrh	r3, [r5, #4]
	add	r2, r3
	cmp	r2, r0
	bls.w	.L080184e8
	ldrh	r2, [r5, #2]
	cmp	r2, #0x2d
	bhi.w	.L080184e8
	ldrh	r2, [r5, #2]
	ldrh	r3, [r5, #6]
	add	r2, r3
	cmp	r2, #0x2e
	bcc.w	.L080184e8
	movw	r6, #0x8350
	ldr	r2, [r5, #8]
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #2]
	movt	r6, #0x2000
	ldrh	r6, [r6, #4]
	rsb.w	r7, r7, #0x2d
	muls	r7, r6, r7
	movw	r5, #0x8350
	subs	r3, r7, r3
	movt	r5, #0x2000
	add	r3, r0
	strh.w	r4, [r2, r3, lsl #1]
	b.n	.L080184e8

@ Group limited to y <= 0x46: x from 0xc up to 0x138 in steps of 4, colour 0x3a29.
.L08018664:
	movs	r2, #0
	movs	r0, #0xc
	movw	r1, #0x3a29
	b.n	.L0801867c
	.byte	0x00, 0xbf	@ padding
.L08018670:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	adds	r0, #4
.L0801867c:
	lsls	r3, r2, #16
	bne.n	.L080186e4
	ldrh	r7, [r5, #0]
	subs	r3, r0, #3
	cmp	r3, r7
	bcc.n	.L080186e4
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080186e4
	ldrh	r3, [r5, #2]
	cmp	r3, #0x46
	bhi.n	.L080186e4
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x47
	bcc.n	.L080186e4
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x46
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-6]
.L080186e4:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x138
	beq.w	.L0801883c
	lsls	r3, r2, #16
	bne.n	.L08018760
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08018760
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018760
	ldrh	r3, [r5, #2]
	cmp	r3, #0x46
	bhi.n	.L08018760
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x47
	bcc.n	.L08018760
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x46
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L08018760:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.n	.L080187d4
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L080187d4
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080187d4
	ldrh	r3, [r5, #2]
	cmp	r3, #0x46
	bhi.n	.L080187d4
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x47
	bcc.n	.L080187d4
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x46
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L080187d4:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.w	.L08018670
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L08018670
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08018670
	ldrh	r3, [r5, #2]
	cmp	r3, #0x46
	bhi.w	.L08018670
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x47
	bcc.w	.L08018670
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x46
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L08018670

@ Group limited to y <= 0x5f (same shape as the group above).
.L0801883c:
	movs	r2, #0
	movs	r0, #0xc
	movw	r1, #0x3a29
	b.n	.L08018854
	.byte	0x00, 0xbf	@ padding
.L08018848:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	adds	r0, #4
.L08018854:
	lsls	r3, r2, #16
	bne.n	.L080188bc
	ldrh	r7, [r5, #0]
	subs	r3, r0, #3
	cmp	r3, r7
	bcc.n	.L080188bc
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080188bc
	ldrh	r3, [r5, #2]
	cmp	r3, #0x5f
	bhi.n	.L080188bc
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x60
	bcc.n	.L080188bc
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x5f
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-6]
.L080188bc:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x138
	beq.w	.L08018a14
	lsls	r3, r2, #16
	bne.n	.L08018938
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08018938
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018938
	ldrh	r3, [r5, #2]
	cmp	r3, #0x5f
	bhi.n	.L08018938
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x60
	bcc.n	.L08018938
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x5f
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L08018938:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.n	.L080189ac
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L080189ac
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080189ac
	ldrh	r3, [r5, #2]
	cmp	r3, #0x5f
	bhi.n	.L080189ac
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x60
	bcc.n	.L080189ac
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x5f
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L080189ac:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.w	.L08018848
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L08018848
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08018848
	ldrh	r3, [r5, #2]
	cmp	r3, #0x5f
	bhi.w	.L08018848
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x60
	bcc.w	.L08018848
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x5f
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L08018848

@ Group limited to y <= 0x78.
.L08018a14:
	movs	r2, #0
	movs	r0, #0xc
	movw	r1, #0x3a29
	b.n	.L08018a2c
	.byte	0x00, 0xbf	@ padding
.L08018a20:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	adds	r0, #4
.L08018a2c:
	lsls	r3, r2, #16
	bne.n	.L08018a94
	ldrh	r7, [r5, #0]
	subs	r3, r0, #3
	cmp	r3, r7
	bcc.n	.L08018a94
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018a94
	ldrh	r3, [r5, #2]
	cmp	r3, #0x78
	bhi.n	.L08018a94
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x79
	bcc.n	.L08018a94
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x78
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-6]
.L08018a94:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x138
	beq.w	.L08018bec
	lsls	r3, r2, #16
	bne.n	.L08018b10
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08018b10
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018b10
	ldrh	r3, [r5, #2]
	cmp	r3, #0x78
	bhi.n	.L08018b10
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x79
	bcc.n	.L08018b10
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x78
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L08018b10:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.n	.L08018b84
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L08018b84
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018b84
	ldrh	r3, [r5, #2]
	cmp	r3, #0x78
	bhi.n	.L08018b84
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x79
	bcc.n	.L08018b84
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x78
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L08018b84:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.w	.L08018a20
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L08018a20
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08018a20
	ldrh	r3, [r5, #2]
	cmp	r3, #0x78
	bhi.w	.L08018a20
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x79
	bcc.w	.L08018a20
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x78
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L08018a20

@ Group limited to y <= 0x91.
.L08018bec:
	movs	r2, #0
	movs	r0, #0xc
	movw	r1, #0x3a29
	b.n	.L08018c04
	.byte	0x00, 0xbf	@ padding
.L08018bf8:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	adds	r0, #4
.L08018c04:
	lsls	r3, r2, #16
	bne.n	.L08018c6c
	ldrh	r7, [r5, #0]
	subs	r3, r0, #3
	cmp	r3, r7
	bcc.n	.L08018c6c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018c6c
	ldrh	r3, [r5, #2]
	cmp	r3, #0x91
	bhi.n	.L08018c6c
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x92
	bcc.n	.L08018c6c
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x91
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-6]
.L08018c6c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x138
	beq.w	.L08018dc4
	lsls	r3, r2, #16
	bne.n	.L08018ce8
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08018ce8
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018ce8
	ldrh	r3, [r5, #2]
	cmp	r3, #0x91
	bhi.n	.L08018ce8
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x92
	bcc.n	.L08018ce8
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x91
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L08018ce8:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.n	.L08018d5c
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L08018d5c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018d5c
	ldrh	r3, [r5, #2]
	cmp	r3, #0x91
	bhi.n	.L08018d5c
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x92
	bcc.n	.L08018d5c
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x91
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L08018d5c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.w	.L08018bf8
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L08018bf8
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08018bf8
	ldrh	r3, [r5, #2]
	cmp	r3, #0x91
	bhi.w	.L08018bf8
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0x92
	bcc.w	.L08018bf8
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0x91
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L08018bf8

@ Group limited to y <= 0xaa.
.L08018dc4:
	movs	r2, #0
	movs	r0, #0xc
	movw	r1, #0x3a29
	b.n	.L08018ddc
	.byte	0x00, 0xbf	@ padding
.L08018dd0:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	adds	r0, #4
.L08018ddc:
	lsls	r3, r2, #16
	bne.n	.L08018e44
	ldrh	r7, [r5, #0]
	subs	r3, r0, #3
	cmp	r3, r7
	bcc.n	.L08018e44
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018e44
	ldrh	r3, [r5, #2]
	cmp	r3, #0xaa
	bhi.n	.L08018e44
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0xab
	bcc.n	.L08018e44
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0xaa
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-6]
.L08018e44:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x138
	beq.w	.L08018f9c
	lsls	r3, r2, #16
	bne.n	.L08018ec0
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08018ec0
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018ec0
	ldrh	r3, [r5, #2]
	cmp	r3, #0xaa
	bhi.n	.L08018ec0
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0xab
	bcc.n	.L08018ec0
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0xaa
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L08018ec0:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.n	.L08018f34
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L08018f34
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08018f34
	ldrh	r3, [r5, #2]
	cmp	r3, #0xaa
	bhi.n	.L08018f34
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0xab
	bcc.n	.L08018f34
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0xaa
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L08018f34:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.w	.L08018dd0
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L08018dd0
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08018dd0
	ldrh	r3, [r5, #2]
	cmp	r3, #0xaa
	bhi.w	.L08018dd0
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0xab
	bcc.w	.L08018dd0
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0xaa
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L08018dd0

@ Group limited to y <= 0xc3.
.L08018f9c:
	movs	r2, #0
	movs	r0, #0xc
	movw	r1, #0x3a29
	b.n	.L08018fb4
	.byte	0x00, 0xbf	@ padding
.L08018fa8:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	adds	r0, #4
.L08018fb4:
	lsls	r3, r2, #16
	bne.n	.L0801901c
	ldrh	r7, [r5, #0]
	subs	r3, r0, #3
	cmp	r3, r7
	bcc.n	.L0801901c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801901c
	ldrh	r3, [r5, #2]
	cmp	r3, #0xc3
	bhi.n	.L0801901c
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0xc4
	bcc.n	.L0801901c
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0xc3
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-6]
.L0801901c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	cmp.w	r0, #0x138
	beq.w	.L08019174
	lsls	r3, r2, #16
	bne.n	.L08019098
	ldrh	r7, [r5, #0]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L08019098
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L08019098
	ldrh	r3, [r5, #2]
	cmp	r3, #0xc3
	bhi.n	.L08019098
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0xc4
	bcc.n	.L08019098
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0xc3
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-4]
	nop
.L08019098:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.n	.L0801910c
	ldrh	r7, [r5, #0]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L0801910c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #0]
	ldrh	r6, [r6, #4]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801910c
	ldrh	r3, [r5, #2]
	cmp	r3, #0xc3
	bhi.n	.L0801910c
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0xc4
	bcc.n	.L0801910c
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0xc3
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	add	r7, r0
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #-2]
	nop
.L0801910c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.w	.L08018fa8
	ldrh	r3, [r5, #0]
	cmp	r0, r3
	bcc.w	.L08018fa8
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08018fa8
	ldrh	r3, [r5, #2]
	cmp	r3, #0xc3
	bhi.w	.L08018fa8
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, #0xc4
	bcc.w	.L08018fa8
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	rsb.w	r6, r6, #0xc3
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add	r7, r0
	strh.w	r1, [r3, r7, lsl #1]
	b.n	.L08018fa8

@ Stride-3 group, rows limited to y <= 0x22, byte offset 0x44, x from 0x16 up to 0xdf.
.L08019174:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L08019194
	.byte	0x00, 0xbf	@ padding
.L08019180:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp	r0, #0xdf
	beq.w	.L080192d4
.L08019194:
	lsls	r3, r2, #16
	bne.n	.L080191fc
	ldrh	r3, [r5, #0]
	cmp	r3, #0x22
	bhi.n	.L080191fc
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x23
	bcc.n	.L080191fc
	ldrh	r7, [r5, #2]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L080191fc
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080191fc
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
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x44]
	nop
.L080191fc:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.n	.L0801926c
	ldrh	r3, [r5, #0]
	cmp	r3, #0x22
	bhi.n	.L0801926c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x23
	bcc.n	.L0801926c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L0801926c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801926c
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
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x44]
.L0801926c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.w	.L08019180
	ldrh	r3, [r5, #0]
	cmp	r3, #0x22
	bhi.w	.L08019180
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x23
	bcc.w	.L08019180
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L08019180
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08019180
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x44]
	b.n	.L08019180

@ Stride-3 group, rows limited to y <= 0x3b, byte offset 0x76.
.L080192d4:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L080192f4
	.byte	0x00, 0xbf	@ padding
.L080192e0:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp	r0, #0xdf
	beq.w	.L08019434
.L080192f4:
	lsls	r3, r2, #16
	bne.n	.L0801935c
	ldrh	r3, [r5, #0]
	cmp	r3, #0x3b
	bhi.n	.L0801935c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x3c
	bcc.n	.L0801935c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L0801935c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801935c
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
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x76]
	nop
.L0801935c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.n	.L080193cc
	ldrh	r3, [r5, #0]
	cmp	r3, #0x3b
	bhi.n	.L080193cc
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x3c
	bcc.n	.L080193cc
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L080193cc
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080193cc
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
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x76]
.L080193cc:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.w	.L080192e0
	ldrh	r3, [r5, #0]
	cmp	r3, #0x3b
	bhi.w	.L080192e0
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x3c
	bcc.w	.L080192e0
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L080192e0
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L080192e0
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0x76]
	b.n	.L080192e0

@ Stride-3 group, rows limited to y <= 0x54, byte offset 0xa8.
.L08019434:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L08019454
	.byte	0x00, 0xbf	@ padding
.L08019440:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
	it	hi
	movhi	r2, #0
	cmp	r0, #0xdf
	beq.w	.L08019594
.L08019454:
	lsls	r3, r2, #16
	bne.n	.L080194bc
	ldrh	r3, [r5, #0]
	cmp	r3, #0x54
	bhi.n	.L080194bc
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x55
	bcc.n	.L080194bc
	ldrh	r7, [r5, #2]
	subs	r3, r0, #2
	cmp	r3, r7
	bcc.n	.L080194bc
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L080194bc
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
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0xa8]
	nop
.L080194bc:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.n	.L0801952c
	ldrh	r3, [r5, #0]
	cmp	r3, #0x54
	bhi.n	.L0801952c
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x55
	bcc.n	.L0801952c
	ldrh	r7, [r5, #2]
	subs	r3, r0, #1
	cmp	r3, r7
	bcc.n	.L0801952c
	movw	r6, #0x8350
	movt	r6, #0x2000
	ldrh	r7, [r5, #2]
	ldrh	r6, [r6, #6]
	movw	r5, #0x8350
	add	r7, r6
	movt	r5, #0x2000
	cmp	r7, r3
	bls.n	.L0801952c
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
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0xa8]
.L0801952c:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	it	hi
	movhi	r2, #0
	lsls	r3, r2, #16
	bne.w	.L08019440
	ldrh	r3, [r5, #0]
	cmp	r3, #0x54
	bhi.w	.L08019440
	ldrh	r3, [r5, #0]
	ldrh	r7, [r5, #4]
	add	r3, r7
	cmp	r3, #0x55
	bcc.w	.L08019440
	ldrh	r3, [r5, #2]
	cmp	r0, r3
	bcc.w	.L08019440
	ldrh	r3, [r5, #2]
	ldrh	r7, [r5, #6]
	add	r3, r7
	cmp	r3, r0
	bls.w	.L08019440
	movw	r6, #0x8350
	ldr	r3, [r5, #8]
	ldrh	r7, [r5, #0]
	movt	r6, #0x2000
	movw	r5, #0x8350
	ldrh	r6, [r6, #2]
	movt	r5, #0x2000
	ldrh	r5, [r5, #4]
	subs	r6, r0, r6
	muls	r6, r5, r6
	subs	r7, r6, r7
	movw	r5, #0x8350
	movt	r5, #0x2000
	add.w	r3, r3, r7, lsl #1
	strh.w	r1, [r3, #0xa8]
	b.n	.L08019440

@ Start of the next stride-3 group: set up x = 0x16, colour 0x3a29, jump into the loop
@ body in the following part (.L080195b4); the loop head below continues in that part.
.L08019594:
	movs	r2, #0
	movs	r0, #0x16
	movw	r1, #0x3a29
	b.n	.L080195b4
	.byte	0x00, 0xbf	@ padding
.L080195a0:
	adds	r2, #1
	uxth	r3, r2
	cmp	r3, #4
	add.w	r0, r0, #3
