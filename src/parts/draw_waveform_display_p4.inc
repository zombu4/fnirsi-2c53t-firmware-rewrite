@ draw_waveform_display_p4.inc - part 4 of 7 of draw_waveform_display (0x080195aa..0x0801a5aa).
@ Continues the unrolled marker / dot plotting of the waveform display: each
@ block plots a 5-step pattern (r2 counts 0..4) of halfword writes of the
@ colour in r1 into the frame buffer rows addressed from the structure at
@ 0x20008350 (halfwords at +0,+2,+4,+6 are clip x, y, width, height; word at +8
@ is the buffer base; strh offsets 0xda,0x10c,0x13e,0x170,0x1a2,0x1d4,0x206,0x238
@ select the buffer row set). Each point is clipped against the rectangle first.
@ r0 = running coordinate (stepped by 3, or 4 in the later blocks), r1 = colour
@ (0x3a29), r2 = phase counter.

@ ---- block 0x080195aa: clipped plots, limit 0x6d / 0x6e, buffer offset 0xda ----
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L080196f4
.L080195b4:
	lsls r3, r2, #16
	bne.n .L0801961c
	ldrh r3, [r5]
	cmp r3, #0x6d
	bhi.n .L0801961c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x6e
	bcc.n .L0801961c
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L0801961c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801961c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0xda]
	nop
.L0801961c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L0801968c
	ldrh r3, [r5]
	cmp r3, #0x6d
	bhi.n .L0801968c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x6e
	bcc.n .L0801968c
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L0801968c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801968c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0xda]
.L0801968c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L080195a0
	ldrh r3, [r5]
	cmp r3, #0x6d
	bhi.w .L080195a0
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x6e
	bcc.w .L080195a0
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L080195a0
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L080195a0
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0xda]
	b.n .L080195a0

@ ---- block 0x080196f4: clipped plots, limit 0x86 / 0x87, buffer offset 0x10c ----
.L080196f4:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08019714
	.short 0xbf00 @ padding
.L08019700:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L08019854
.L08019714:
	lsls r3, r2, #16
	bne.n .L0801977c
	ldrh r3, [r5]
	cmp r3, #0x86
	bhi.n .L0801977c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x87
	bcc.n .L0801977c
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L0801977c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801977c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x10c]
	nop
.L0801977c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L080197ec
	ldrh r3, [r5]
	cmp r3, #0x86
	bhi.n .L080197ec
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x87
	bcc.n .L080197ec
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L080197ec
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L080197ec
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x10c]
.L080197ec:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L08019700
	ldrh r3, [r5]
	cmp r3, #0x86
	bhi.w .L08019700
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x87
	bcc.w .L08019700
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L08019700
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L08019700
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x10c]
	b.n .L08019700

@ ---- block 0x08019854: clipped plots, limit 0x9f / 0xa0, buffer offset 0x13e ----
.L08019854:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08019874
	.short 0xbf00 @ padding
.L08019860:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L080199b4
.L08019874:
	lsls r3, r2, #16
	bne.n .L080198dc
	ldrh r3, [r5]
	cmp r3, #0x9f
	bhi.n .L080198dc
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xa0
	bcc.n .L080198dc
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L080198dc
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L080198dc
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13e]
	nop
.L080198dc:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L0801994c
	ldrh r3, [r5]
	cmp r3, #0x9f
	bhi.n .L0801994c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xa0
	bcc.n .L0801994c
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L0801994c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801994c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13e]
.L0801994c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L08019860
	ldrh r3, [r5]
	cmp r3, #0x9f
	bhi.w .L08019860
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xa0
	bcc.w .L08019860
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L08019860
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L08019860
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13e]
	b.n .L08019860

@ ---- block 0x080199b4: clipped plots, limit 0xb8 / 0xb9, buffer offset 0x170 ----
.L080199b4:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L080199d4
	.short 0xbf00 @ padding
.L080199c0:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L08019b14
.L080199d4:
	lsls r3, r2, #16
	bne.n .L08019a3c
	ldrh r3, [r5]
	cmp r3, #0xb8
	bhi.n .L08019a3c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xb9
	bcc.n .L08019a3c
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08019a3c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08019a3c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x170]
	nop
.L08019a3c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L08019aac
	ldrh r3, [r5]
	cmp r3, #0xb8
	bhi.n .L08019aac
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xb9
	bcc.n .L08019aac
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L08019aac
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08019aac
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x170]
.L08019aac:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L080199c0
	ldrh r3, [r5]
	cmp r3, #0xb8
	bhi.w .L080199c0
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xb9
	bcc.w .L080199c0
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L080199c0
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L080199c0
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x170]
	b.n .L080199c0

@ ---- block 0x08019b14: clipped plots, limit 0xd1 / 0xd2, buffer offset 0x1a2 ----
.L08019b14:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08019b34
	.short 0xbf00 @ padding
.L08019b20:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L08019c74
.L08019b34:
	lsls r3, r2, #16
	bne.n .L08019b9c
	ldrh r3, [r5]
	cmp r3, #0xd1
	bhi.n .L08019b9c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xd2
	bcc.n .L08019b9c
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08019b9c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08019b9c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x1a2]
	nop
.L08019b9c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L08019c0c
	ldrh r3, [r5]
	cmp r3, #0xd1
	bhi.n .L08019c0c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xd2
	bcc.n .L08019c0c
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L08019c0c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08019c0c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x1a2]
.L08019c0c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L08019b20
	ldrh r3, [r5]
	cmp r3, #0xd1
	bhi.w .L08019b20
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xd2
	bcc.w .L08019b20
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L08019b20
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L08019b20
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x1a2]
	b.n .L08019b20

@ ---- block 0x08019c74: clipped plots, limit 0xea / 0xeb, buffer offset 0x1d4 ----
.L08019c74:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08019c94
	.short 0xbf00 @ padding
.L08019c80:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L08019dd4
.L08019c94:
	lsls r3, r2, #16
	bne.n .L08019cfc
	ldrh r3, [r5]
	cmp r3, #0xea
	bhi.n .L08019cfc
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xeb
	bcc.n .L08019cfc
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08019cfc
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08019cfc
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x1d4]
	nop
.L08019cfc:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L08019d6c
	ldrh r3, [r5]
	cmp r3, #0xea
	bhi.n .L08019d6c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xeb
	bcc.n .L08019d6c
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L08019d6c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08019d6c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x1d4]
.L08019d6c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L08019c80
	ldrh r3, [r5]
	cmp r3, #0xea
	bhi.w .L08019c80
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xeb
	bcc.w .L08019c80
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L08019c80
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L08019c80
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x1d4]
	b.n .L08019c80

@ ---- block 0x08019dd4: clipped plots, x/4 <= 0x40, x+w >= 0x104, buffer offset 0x206 ----
.L08019dd4:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08019df4
	.short 0xbf00 @ padding
.L08019de0:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L08019f40
.L08019df4:
	lsls r3, r2, #16
	bne.n .L08019e60
	ldrh r3, [r5]
	lsrs r3, r3, #2
	cmp r3, #0x40
	bhi.n .L08019e60
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp.w r3, #0x104
	bcc.n .L08019e60
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08019e60
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08019e60
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x206]
	nop
.L08019e60:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L08019ed4
	ldrh r3, [r5]
	lsrs r3, r3, #2
	cmp r3, #0x40
	bhi.n .L08019ed4
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp.w r3, #0x104
	bcc.n .L08019ed4
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L08019ed4
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08019ed4
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x206]
.L08019ed4:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L08019de0
	ldrh r3, [r5]
	lsrs r3, r3, #2
	cmp r3, #0x40
	bhi.w .L08019de0
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp.w r3, #0x104
	bcc.w .L08019de0
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L08019de0
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L08019de0
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x206]
	b.n .L08019de0

@ ---- block 0x08019f40: clipped plots, x > 0x11c, x+w > 0x11c, buffer offset 0x238 ----
.L08019f40:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08019f60
	.short 0xbf00 @ padding
.L08019f4c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L0801a0ac
.L08019f60:
	lsls r3, r2, #16
	bne.n .L08019fcc
	ldrh r3, [r5]
	cmp.w r3, #0x11c
	bhi.n .L08019fcc
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp.w r3, #0x11c
	bls.n .L08019fcc
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08019fcc
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08019fcc
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x238]
	nop
.L08019fcc:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L0801a040
	ldrh r3, [r5]
	cmp.w r3, #0x11c
	bhi.n .L0801a040
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp.w r3, #0x11c
	bls.n .L0801a040
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L0801a040
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a040
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x238]
.L0801a040:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L08019f4c
	ldrh r3, [r5]
	cmp.w r3, #0x11c
	bhi.w .L08019f4c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp.w r3, #0x11c
	bls.w .L08019f4c
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L08019f4c
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L08019f4c
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x238]
	b.n .L08019f4c

@ ---- block 0x0801a0ac: column plots from r0 = 0xc stepped by 4, limits 0x76 / 0x77 ----
.L0801a0ac:
	movs r2, #0
	movs r0, #0xc
	movw r1, #0x3a29
	b.n .L0801a0c4
	.short 0xbf00 @ padding
.L0801a0b8:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	adds r0, #4
.L0801a0c4:
	lsls r3, r2, #16
	bne.n .L0801a12c
	ldrh r7, [r5]
	subs r3, r0, #3
	cmp r3, r7
	bcc.n .L0801a12c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a12c
	ldrh r3, [r5, #2]
	cmp r3, #0x76
	bhi.n .L0801a12c
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x77
	bcc.n .L0801a12c
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x76
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-6]
.L0801a12c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	cmp.w r0, #0x138
	beq.w .L0801a284
	lsls r3, r2, #16
	bne.n .L0801a1a8
	ldrh r7, [r5]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L0801a1a8
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a1a8
	ldrh r3, [r5, #2]
	cmp r3, #0x76
	bhi.n .L0801a1a8
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x77
	bcc.n .L0801a1a8
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x76
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-4]
	nop
.L0801a1a8:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L0801a21c
	ldrh r7, [r5]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L0801a21c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a21c
	ldrh r3, [r5, #2]
	cmp r3, #0x76
	bhi.n .L0801a21c
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x77
	bcc.n .L0801a21c
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x76
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-2]
	nop
.L0801a21c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L0801a0b8
	ldrh r3, [r5]
	cmp r0, r3
	bcc.w .L0801a0b8
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r0
	bls.w .L0801a0b8
	ldrh r3, [r5, #2]
	cmp r3, #0x76
	bhi.w .L0801a0b8
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x77
	bcc.w .L0801a0b8
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x76
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L0801a0b8

@ ---- block 0x0801a284: column plots from r0 = 0xc stepped by 4, limits 0x77 / 0x78 ----
.L0801a284:
	movs r2, #0
	movs r0, #0xc
	movw r1, #0x3a29
	b.n .L0801a29c
	.short 0xbf00 @ padding
.L0801a290:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	adds r0, #4
.L0801a29c:
	lsls r3, r2, #16
	bne.n .L0801a304
	ldrh r7, [r5]
	subs r3, r0, #3
	cmp r3, r7
	bcc.n .L0801a304
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a304
	ldrh r3, [r5, #2]
	cmp r3, #0x77
	bhi.n .L0801a304
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x78
	bcc.n .L0801a304
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x77
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-6]
.L0801a304:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	cmp.w r0, #0x138
	beq.w .L0801a45c
	lsls r3, r2, #16
	bne.n .L0801a380
	ldrh r7, [r5]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L0801a380
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a380
	ldrh r3, [r5, #2]
	cmp r3, #0x77
	bhi.n .L0801a380
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x78
	bcc.n .L0801a380
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x77
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-4]
	nop
.L0801a380:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L0801a3f4
	ldrh r7, [r5]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L0801a3f4
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a3f4
	ldrh r3, [r5, #2]
	cmp r3, #0x77
	bhi.n .L0801a3f4
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x78
	bcc.n .L0801a3f4
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x77
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-2]
	nop
.L0801a3f4:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.w .L0801a290
	ldrh r3, [r5]
	cmp r0, r3
	bcc.w .L0801a290
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r0
	bls.w .L0801a290
	ldrh r3, [r5, #2]
	cmp r3, #0x77
	bhi.w .L0801a290
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x78
	bcc.w .L0801a290
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x77
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L0801a290

@ ---- block 0x0801a45c: column plots from r0 = 0xc stepped by 4, limits 0x79 / 0x7a ----
.L0801a45c:
	movs r2, #0
	movs r0, #0xc
	movw r1, #0x3a29
	b.n .L0801a474
	.short 0xbf00 @ padding
.L0801a468:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	adds r0, #4
.L0801a474:
	lsls r3, r2, #16
	bne.n .L0801a4dc
	ldrh r7, [r5]
	subs r3, r0, #3
	cmp r3, r7
	bcc.n .L0801a4dc
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a4dc
	ldrh r3, [r5, #2]
	cmp r3, #0x79
	bhi.n .L0801a4dc
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x7a
	bcc.n .L0801a4dc
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x79
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-6]
.L0801a4dc:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	cmp.w r0, #0x138
	beq.w .L0801a634
	lsls r3, r2, #16
	bne.n .L0801a558
	ldrh r7, [r5]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L0801a558
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a558
	ldrh r3, [r5, #2]
	cmp r3, #0x79
	bhi.n .L0801a558
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x7a
	bcc.n .L0801a558
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x79
	muls r6, r5
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #-4]
	nop
.L0801a558:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #16
	bne.n .L0801a5cc
	ldrh r7, [r5]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L0801a5cc
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801a5cc
	ldrh r3, [r5, #2]
	cmp r3, #0x79
	bhi.n .L0801a5cc
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x7a
	bcc.n .L0801a5cc
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
