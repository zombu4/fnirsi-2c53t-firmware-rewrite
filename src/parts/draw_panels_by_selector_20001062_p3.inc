@ draw_panels_by_selector_20001062, part 3 of 3 (0x08015344..0x08015740).
@ Fragment included by part 1: continues the instructions of the function.
@ Contents: the tail of the pixel-plot loops (clipped writes of a 16-bit
@ colour into the frame buffer described by the structure at r7), the
@ image draws (73.jpg, 76.jpg), the rounded-rect outlines, the four
@ recolor_rect_above_threshold calls selected by the flags in the word at
@ 0x20000144, the function epilogue, the strings and the literal pool.
	bcc.w .L08015478
	sub.w r1, r11, #0x41
	sub.w r0, r11, #0x60
	sxth.w r12, r1
	b.n .L08015362
	.byte 0x00, 0xbf                @ padding
.L08015358:
	adds r0, #1
	sxth r0, r0
	cmp r0, r12
	bgt.w .L0801525c
.L08015362:
	sxth r2, r0
	movs r3, #0xe2
	b.n .L08015370
.L08015368:
	adds r3, #3
	cmp.w r3, #0x130
	beq.n .L08015358
.L08015370:
	ldrh r5, [r7]
	cmp r3, r5
	bcc.n .L080153a4
	ldrh r5, [r7]
	ldrh r4, [r7, #4]
	add r5, r4
	cmp r5, r3
	bls.n .L080153a4
	ldrh r5, [r7, #2]
	cmp r2, r5
	blt.n .L080153a4
	ldrh r5, [r7, #2]
	ldrh r4, [r7, #6]
	add r5, r4
	cmp r5, r2
	ble.n .L080153a4
	ldr r5, [r7, #8]
	ldrh r4, [r7]
	ldrh r6, [r7, #2]
	ldrh r1, [r7, #4]
	subs r6, r2, r6
	muls r1, r6, r1
	subs r1, r1, r4
	add r1, r3
	strh.w r9, [r5, r1, lsl #1]
.L080153a4:
	ldrh r1, [r7]
	adds r5, r3, #1
	cmp r5, r1
	bcc.n .L080153e0
	ldrh r1, [r7]
	ldrh r6, [r7, #4]
	add r1, r6
	cmp r1, r5
	bls.n .L080153e0
	ldrh r1, [r7, #2]
	cmp r2, r1
	blt.n .L080153e0
	ldrh r1, [r7, #2]
	ldrh r6, [r7, #6]
	add r1, r6
	cmp r1, r2
	ble.n .L080153e0
	ldr r1, [r7, #8]
	ldrh r6, [r7]
	ldrh r5, [r7, #2]
	ldrh r4, [r7, #4]
	subs r5, r2, r5
	muls r5, r4, r5
	subs r6, r5, r6
	add r6, r3
	add.w r1, r1, r6, lsl #1
	strh.w r9, [r1, #2]
	nop
.L080153e0:
	ldrh r1, [r7]
	adds r5, r3, #2
	cmp r5, r1
	bcc.n .L08015368
	ldrh r1, [r7]
	ldrh r6, [r7, #4]
	add r1, r6
	cmp r1, r5
	bls.n .L08015368
	ldrh r1, [r7, #2]
	cmp r2, r1
	blt.n .L08015368
	ldrh r1, [r7, #2]
	ldrh r6, [r7, #6]
	add r1, r6
	cmp r1, r2
	ble.n .L08015368
	ldr r1, [r7, #8]
	ldrh r6, [r7]
	ldrh r5, [r7, #2]
	ldrh r4, [r7, #4]
	subs r5, r2, r5
	muls r5, r4, r5
	subs r6, r5, r6
	add r6, r3
	add.w r1, r1, r6, lsl #1
	strh.w r9, [r1, #4]
	b.n .L08015368
.L0801541c:
	add.w r0, r11, #0x2f
	uxth r2, r0
	adr r0, .L080156e4              @ "3:/System file/73.jpg"
	movs r1, #0x79
.L08015426:
	bl decode_image_file_with_offset
	movw r1, #0xcccd
	uxtb.w r0, r10
	movt r1, #0xcccc
	umull r0, r1, r0, r1
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x35]
	lsrs r4, r1, #2
	cmp r10, r0
	mov.w r0, #0x6b
	mul r8, r4, r0
	bne.n .L08015510
	add.w r1, r4, r4, lsl #3
	sub.w r2, r11, r1, lsl #4
	rsbs r1, r1, #0
	add.w r0, r8, #0x7f
	lsls r5, r1, #4
	add.w r1, r2, #0x37
	uxth r2, r1
	uxth r1, r0
	movw r0, #:lower16:t_080bc54a
	movt r0, #:upper16:t_080bc54a
	b.n .L08015530
	.byte 0x00, 0xbf                @ padding
.L08015478:
	add.w r1, r11, #0x4f
	add.w r0, r11, #0x30
	sxth.w r12, r1
	b.n .L08015492
	.byte 0x00, 0xbf                @ padding
.L08015488:
	adds r0, #1
	sxth r0, r0
	cmp r0, r12
	bgt.w .L0801525c
.L08015492:
	sxth r2, r0
	movs r3, #0x7b
	b.n .L0801549e
.L08015498:
	adds r3, #2
	cmp r3, #0xd9
	beq.n .L08015488
.L0801549e:
	ldrh r6, [r7]
	subs r5, r3, #1
	cmp r5, r6
	bcc.n .L080154d8
	ldrh r6, [r7]
	ldrh r4, [r7, #4]
	add r6, r4
	cmp r6, r5
	bls.n .L080154d8
	ldrh r6, [r7, #2]
	cmp r2, r6
	blt.n .L080154d8
	ldrh r6, [r7, #2]
	ldrh r5, [r7, #6]
	add r6, r5
	cmp r6, r2
	ble.n .L080154d8
	ldr r6, [r7, #8]
	ldrh r5, [r7]
	ldrh r4, [r7, #2]
	ldrh r1, [r7, #4]
	subs r4, r2, r4
	muls r1, r4, r1
	subs r1, r1, r5
	add r1, r3
	add.w r1, r6, r1, lsl #1
	strh r9, [r1, #-2]
.L080154d8:
	ldrh r1, [r7]
	cmp r3, r1
	bcc.n .L08015498
	ldrh r1, [r7]
	ldrh r6, [r7, #4]
	add r1, r6
	cmp r1, r3
	bls.n .L08015498
	ldrh r1, [r7, #2]
	cmp r2, r1
	blt.n .L08015498
	ldrh r1, [r7, #2]
	ldrh r6, [r7, #6]
	add r1, r6
	cmp r1, r2
	ble.n .L08015498
	ldr r1, [r7, #8]
	ldrh r6, [r7]
	ldrh r5, [r7, #2]
	ldrh r4, [r7, #4]
	subs r5, r2, r5
	muls r5, r4, r5
	subs r6, r5, r6
	add r6, r3
	strh.w r9, [r1, r6, lsl #1]
	b.n .L08015498
	.byte 0x00, 0xbf                @ padding
.L08015510:
	add.w r1, r4, r4, lsl #3
	sub.w r2, r11, r1, lsl #4
	rsbs r1, r1, #0
	add.w r0, r8, #0x7e
	lsls r5, r1, #4
	add.w r1, r2, #0x37
	uxth r2, r1
	uxth r1, r0
	movw r0, #:lower16:t_080bc5fc
	movt r0, #:upper16:t_080bc5fc
.L08015530:
	bl decode_image_file_with_offset
	movs r0, #2
	b.n .L080152b4
.L08015538:
	movs r1, #0x68
	cmp r0, #0xc
	ite ne
	movne r0, #0xf9
	moveq r0, #0xbb
.L08015542:
	movs r2, #4
	bl draw_rounded_rect_outline
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf6b]
	cmp r1, #0xbf
	lsr.w r0, r1, #4
	bhi.n .L0801557a
	lsrs r2, r1, #6
	lsls r2, r2, #5
	sub.w r1, r2, r1, lsr #6
	movs r2, #0x7d
	add.w r2, r2, r1, lsl #1
	and.w r0, r0, #3
	movs r1, #0x82
	movs r3, #0x1a
	smlabb r1, r0, r3, r1
	uxtb r0, r2
	b.n .L08015584
.L0801557a:
	movs r1, #0x68
	cmp r0, #0xc
	ite eq
	moveq r0, #0xbb
	movne r0, #0xf9
.L08015584:
	movs r2, #3
	add sp, #0x1c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	b.w draw_rounded_rect_outline
.L08015590:
	movs r1, #0x26
	cmp r0, #0xc
	ite ne
	movne r0, #0xf9
	moveq r0, #0xbb
.L0801559a:
	movs r2, #4
	bl draw_rounded_rect_outline
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf6b]
	cmp r1, #0xbf
	lsr.w r0, r1, #4
	bhi.n .L080155d2
	lsrs r2, r1, #6
	lsls r2, r2, #5
	sub.w r1, r2, r1, lsr #6
	movs r2, #0x7d
	add.w r2, r2, r1, lsl #1
	and.w r0, r0, #3
	movs r1, #0x40
	movs r3, #0x1a
	smlabb r1, r0, r3, r1
	uxtb r0, r2
	b.n .L080155dc
.L080155d2:
	movs r1, #0x26
	cmp r0, #0xc
	ite ne
	movne r0, #0xf9
	moveq r0, #0xbb
.L080155dc:
	movs r2, #3
	bl draw_rounded_rect_outline
	movw r3, #0xf8
	movt r3, #0x2000
.L080155ea:
	ldr r0, [r3, #0x4c]
	movs r4, #0
	movt r4, #0xfff
	and.w r1, r0, r4
	cmp r1, r4
	bne.n .L080156ce
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xbc
	add.w r0, r8, r0, lsl #2
	ldrh r7, [r0, #2]
	movw r0, #0x2965
	str r0, [sp]
	movs r0, #0xbb
	movs r2, #0x36
	movs r3, #0x12
	str r7, [sp, #4]
	bl recolor_rect_above_threshold
	movw r3, #0xf8
	movt r3, #0x2000
	ldr r0, [r3, #0x4c]
	tst r0, r4
	bne.n .L080156d2
.L08015626:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xbc
	add.w r0, r8, r0, lsl #2
	ldrh r7, [r0, #2]
	movw r0, #0x2965
	str r0, [sp]
	movs r0, #0xf9
	movs r2, #0x36
	movs r3, #0x12
	str r7, [sp, #4]
	bl recolor_rect_above_threshold
	movw r3, #0xf8
	movt r3, #0x2000
	ldr r0, [r3, #0x4c]
	lsls r1, r0, #0xf
	bpl.n .L080156d6
.L08015652:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xd6
	add.w r0, r8, r0, lsl #2
	ldrh r7, [r0, #2]
	movw r0, #0x2965
	str r0, [sp]
	movs r0, #0x7d
	movs r2, #0x36
	movs r3, #0x12
	str r7, [sp, #4]
	bl recolor_rect_above_threshold
	movw r3, #0xf8
	movt r3, #0x2000
	ldr r0, [r3, #0x4c]
	lsls r1, r0, #0xb
	bpl.n .L080156da
.L0801567e:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xd6
	add.w r0, r8, r0, lsl #2
	ldrh r7, [r0, #2]
	movw r0, #0x2965
	str r0, [sp]
	movs r0, #0xbb
	movs r2, #0x36
	movs r3, #0x12
	str r7, [sp, #4]
	bl recolor_rect_above_threshold
	movw r3, #0xf8
	movt r3, #0x2000
	ldr r0, [r3, #0x4c]
	lsls r0, r0, #7
	bpl.n .L080156de
.L080156aa:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xd6
	add.w r0, r8, r0, lsl #2
	ldrh r7, [r0, #2]
	movw r0, #0x2965
	str r0, [sp]
	movs r0, #0xf9
	movs r2, #0x36
	movs r3, #0x12
	str r7, [sp, #4]
	bl recolor_rect_above_threshold
	add sp, #0x1c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080156ce:
	tst r0, r4
	beq.n .L08015626
.L080156d2:
	lsls r1, r0, #0xf
	bmi.n .L08015652
.L080156d6:
	lsls r1, r0, #0xb
	bmi.n .L0801567e
.L080156da:
	lsls r0, r0, #7
	bmi.n .L080156aa
.L080156de:
	add sp, #0x1c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080156e4:
	.asciz "3:/System file/73.jpg"
	.short 0x0000                   @ padding
.L080156fc:
	.asciz "3:/System file/76.jpg"
	.short 0x0000                   @ padding
.L08015714:
	.word t_080bb9cc                @ "CH1+CH2"
	.word t_080bb9d4                @ "CH1-CH2"
	.word t_080bb9c4                @ "CH1*CH2"
	.word t_080bb9dc                @ "CH1/CH2"
	.word t_080bb974                @ "-CH1"
	.word t_080bb9d7                @ "-CH2"
	.word t_080bcf1a                @ "|CH1|"
	.word t_080bcf20                @ "|CH2|"
.L08015734:
	.byte 0xe2, 0x88, 0x9e, 0x00    @ UTF-8 infinity sign, NUL
.L08015738:
	.asciz "Y-T"
.L0801573c:
	.word 0x00592d58                @ read as data by 08014c4a
