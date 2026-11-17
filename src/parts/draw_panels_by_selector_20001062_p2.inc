@ draw_panels_by_selector_20001062, part 2 of 3 (0x0801433a..0x08015344).
@ Fragment included by part 1; continues the function without a header.
	movs r0, #0xb6
	movs r1, #0x3d
	movs r2, #0x5c
	movs r3, #0x22
	str.w r8, [sp, #4]
	bl draw_wrapped_text_in_box
	movw r3, #0xf8
	movt r3, #0x2000
	ldrb.w r0, [r3, #0xf69]
	cbz r0, .L08014388
	ldrb.w r0, [r3, #0xf6b]
	cmp r0, #1
	bne.n .L08014388
	movw r0, #:lower16:d_080bc498+1
	movt r0, #:upper16:d_080bc498+1
	movs r1, #0x79
	movs r2, #0x85
	mov r4, r3
	bl decode_image_file_with_offset
	ldrb.w r0, [r4, #0x23a]
	lsls r0, r0, #0x1e
	bmi.w .L080144dc
	movw r0, #:lower16:d_080bc5fc
	movt r0, #:upper16:d_080bc5fc
	movs r1, #0xa5
	b.n .L080144e6
.L08014388:
	movw r2, #0x8350
	movs r0, #0x86
	mov.w lr, #0x87
	movt r2, #0x2000
	movw r3, #0x131
	movw r12, #0x18c3
	b.n .L080143ac
.L080143a0:
	adds r0, #2
	cmp r0, #0xa6
	add.w lr, lr, #2
	beq.w .L080144ae
.L080143ac:
	movs r6, #0x7b
	b.n .L080143b6
.L080143b0:
	adds r6, #2
	cmp r6, r3
	beq.n .L08014428
.L080143b6:
	ldrh r5, [r2]
	subs r4, r6, #1
	cmp r4, r5
	bcc.n .L080143f0
	ldrh r5, [r2]
	ldrh r7, [r2, #4]
	add r7, r5
	cmp r7, r4
	bls.n .L080143f0
	ldrh r7, [r2, #2]
	cmp r0, r7
	bcc.n .L080143f0
	ldrh r7, [r2, #2]
	ldrh r5, [r2, #6]
	add r7, r5
	cmp r7, r0
	bls.n .L080143f0
	ldr r7, [r2, #8]
	ldrh r5, [r2]
	ldrh r4, [r2, #2]
	ldrh r1, [r2, #4]
	subs r4, r0, r4
	muls r1, r4, r1
	subs r1, r1, r5
	add r1, r6
	add.w r1, r7, r1, lsl #1
	strh.w r12, [r1, #-2]
.L080143f0:
	ldrh r1, [r2]
	cmp r6, r1
	bcc.n .L080143b0
	ldrh r1, [r2]
	ldrh r4, [r2, #4]
	add r1, r4
	cmp r1, r6
	bls.n .L080143b0
	ldrh r1, [r2, #2]
	cmp r0, r1
	bcc.n .L080143b0
	ldrh r1, [r2, #2]
	ldrh r4, [r2, #6]
	add r1, r4
	cmp r1, r0
	bls.n .L080143b0
	ldr r1, [r2, #8]
	ldrh r4, [r2]
	ldrh r5, [r2, #2]
	ldrh r7, [r2, #4]
	subs r5, r0, r5
	muls r5, r7, r5
	subs r4, r5, r4
	add r4, r6
	strh.w r12, [r1, r4, lsl #1]
	b.n .L080143b0
	.byte 0x00, 0xbf @ padding
.L08014428:
	orr.w r6, r0, #1
	movs r4, #0x7b
	b.n .L08014436
.L08014430:
	adds r4, #2
	cmp r4, r3
	beq.n .L080143a0
.L08014436:
	ldrh r1, [r2]
	subs r5, r4, #1
	cmp r5, r1
	bcc.n .L08014474
	ldrh r1, [r2]
	ldrh r7, [r2, #4]
	add r1, r7
	cmp r1, r5
	bls.n .L08014474
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08014474
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08014474
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	add.w r1, r10, r1, lsl #1
	strh.w r12, [r1, #-2]
.L08014474:
	ldrh r1, [r2]
	cmp r4, r1
	bcc.n .L08014430
	ldrh r1, [r2]
	ldrh r5, [r2, #4]
	add r1, r5
	cmp r1, r4
	bls.n .L08014430
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08014430
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08014430
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	strh.w r12, [r10, r1, lsl #1]
	b.n .L08014430
.L080144ae:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x23a]
	movs r1, #0xa6
	lsls r0, r0, #0x1e
	mov.w r2, #0x8f
	ittee mi
	movwmi r0, #:lower16:d_080bc4f2
	movtmi r0, #:upper16:d_080bc4f2
	movwpl r0, #:lower16:d_080bc5ce+1
	movtpl r0, #:upper16:d_080bc5ce+1
	bl decode_image_file_with_offset
	movs r0, #1
	b.n .L080144ee
.L080144dc:
	movw r0, #:lower16:d_080bc54a
	movt r0, #:upper16:d_080bc54a
	movs r1, #0xa6
.L080144e6:
	movs r2, #0x8d
	bl decode_image_file_with_offset
	movs r0, #2
.L080144ee:
	ldrh.w r0, [r9, r0, lsl #1]
	movs r7, #1
	adr.w r1, .L08015338
	b.n .L08014c4a
.L080144fa:
	movw r0, #:lower16:d_080bc46c
	movt r0, #:upper16:d_080bc46c
	b.n .L0801450c
.L08014504:
	movw r0, #:lower16:d_080bc4ae+1
	movt r0, #:upper16:d_080bc4ae+1
.L0801450c:
	mov r4, r12
.L0801450e:
	movs r1, #0x72
	movs r2, #0x1b
	bl decode_image_file_with_offset
	ldrb.w r1, [r4, #0xf6b]
	ldr r0, [r4, #0x4c]
	lsls r1, r1, #0x1c
	mov r3, r4
	beq.w .L08014874
	movw r4, #:lower16:d_080bb40c
	lsls r1, r0, #0x1d
	movt r4, #:upper16:d_080bb40c
	bmi.w .L0801497e
	lsls r1, r0, #0x19
	bmi.w .L080149aa
.L08014538:
	lsls r1, r0, #0x15
	bmi.w .L080149d6
.L0801453e:
	lsls r1, r0, #0x1c
	bmi.w .L08014a02
.L08014544:
	lsls r1, r0, #0x18
	bmi.w .L08014a2e
.L0801454a:
	lsls r1, r0, #0x14
	bpl.n .L08014574
.L0801454e:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x3a
	ldrh.w r7, [r4, r0, lsl #2]
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
.L08014574:
	movs r5, #0
	movt r5, #0xfff
	and.w r1, r0, r5
	cmp r1, r5
	bne.w .L080147d2
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x68
	add.w r0, r4, r0, lsl #2
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
	tst r0, r5
	bne.w .L080147d8
.L080145b2:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x68
	add.w r0, r4, r0, lsl #2
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
	bpl.w .L080147de
.L080145e0:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x82
	add.w r0, r4, r0, lsl #2
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
	lsls r1, r0, #0xe
	bpl.w .L080147e4
.L0801460e:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x9c
	add.w r0, r4, r0, lsl #2
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
	lsls r1, r0, #0xd
	bpl.w .L080147ea
.L0801463c:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xb6
	add.w r0, r4, r0, lsl #2
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
	lsls r1, r0, #0xc
	bpl.w .L080147f0
.L0801466a:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xd0
	add.w r0, r4, r0, lsl #2
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
	bpl.w .L080147f6
.L08014698:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x82
	add.w r0, r4, r0, lsl #2
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
	lsls r1, r0, #0xa
	bpl.w .L080147fc
.L080146c6:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x9c
	add.w r0, r4, r0, lsl #2
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
	lsls r1, r0, #9
	bpl.w .L08014802
.L080146f4:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xb6
	add.w r0, r4, r0, lsl #2
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
	lsls r1, r0, #8
	bpl.n .L08014806
.L08014720:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xd0
	add.w r0, r4, r0, lsl #2
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
	lsls r1, r0, #7
	bpl.n .L0801480a
.L0801474c:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x82
	add.w r0, r4, r0, lsl #2
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
	lsls r1, r0, #6
	bpl.n .L0801480e
.L08014778:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x9c
	add.w r0, r4, r0, lsl #2
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
	lsls r1, r0, #5
	bpl.n .L08014812
.L080147a4:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xb6
	add.w r0, r4, r0, lsl #2
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
	lsls r0, r0, #4
	bmi.n .L08014816
	b.n .L0801483c
.L080147d2:
	tst r0, r5
	beq.w .L080145b2
.L080147d8:
	lsls r1, r0, #0xf
	bmi.w .L080145e0
.L080147de:
	lsls r1, r0, #0xe
	bmi.w .L0801460e
.L080147e4:
	lsls r1, r0, #0xd
	bmi.w .L0801463c
.L080147ea:
	lsls r1, r0, #0xc
	bmi.w .L0801466a
.L080147f0:
	lsls r1, r0, #0xb
	bmi.w .L08014698
.L080147f6:
	lsls r1, r0, #0xa
	bmi.w .L080146c6
.L080147fc:
	lsls r1, r0, #9
	bmi.w .L080146f4
.L08014802:
	lsls r1, r0, #8
	bmi.n .L08014720
.L08014806:
	lsls r1, r0, #7
	bmi.n .L0801474c
.L0801480a:
	lsls r1, r0, #6
	bmi.n .L08014778
.L0801480e:
	lsls r1, r0, #5
	bmi.n .L080147a4
.L08014812:
	lsls r0, r0, #4
	bpl.n .L0801483c
.L08014816:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0xd0
	add.w r0, r4, r0, lsl #2
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
.L0801483c:
	ldrb.w r0, [r3, #0xf69]
	cmp r0, #2
	bne.w .L080156de
	ldrb.w r1, [r3, #0xf6b]
	cmp r1, #0xbf
	lsr.w r0, r1, #4
	bhi.w .L08015538
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
	b.w .L08015542
.L08014874:
	mov r1, r0
	bfc r1, #0xc, #0x14
	movw r2, #0xfff
	cmp r1, r2
	bne.n .L080148b0
	ldrb.w r0, [r3, #0xf63]
	movw r1, #:lower16:d_080bb40c
	movt r1, #:upper16:d_080bb40c
	ldrh.w r7, [r1, r0, lsl #2]
	movw r0, #0x2965
	str r0, [sp]
	movs r0, #0xbb
	movs r1, #0x26
	movs r2, #0x36
	movs r3, #0x12
	str r7, [sp, #4]
	bl recolor_rect_above_threshold
	movw r3, #0xf8
	movt r3, #0x2000
	ldr r0, [r3, #0x4c]
.L080148b0:
	lsls r0, r0, #0x14
	bne.n .L080148e0
	ldrb.w r0, [r3, #0xf63]
	movw r1, #:lower16:d_080bb40c
	movt r1, #:upper16:d_080bb40c
	ldrh.w r7, [r1, r0, lsl #2]
	movw r0, #0x2965
	str r0, [sp]
	movs r0, #0xf9
	movs r1, #0x26
	movs r2, #0x36
	movs r3, #0x12
	str r7, [sp, #4]
	bl recolor_rect_above_threshold
	movw r3, #0xf8
	movt r3, #0x2000
.L080148e0:
	movw r8, #:lower16:d_080bb40c
	movs r5, #0
	movs r6, #1
	mov.w r9, #0x7d
	mov.w r10, #0x40
	mov.w r11, #0x1a
	movt r8, #:upper16:d_080bb40c
	movw r4, #0x2965
	b.n .L08014906
	.byte 0x00, 0xbf @ padding
.L08014900:
	adds r5, #1
	cmp r5, #0xc
	beq.n .L08014946
.L08014906:
	ldr r0, [r3, #0x4c]
	lsl.w r1, r6, r5
	ands r0, r1
	lsls r0, r0, #0x14
	beq.n .L08014900
	lsrs r0, r5, #2
	lsls r0, r0, #5
	ldrb.w r1, [r3, #0xf63]
	sub.w r0, r0, r5, lsr #2
	add.w r0, r9, r0, lsl #1
	and.w r2, r5, #3
	ldrh.w r7, [r8, r1, lsl #2]
	smlabb r1, r2, r11, r10
	sxth r0, r0
	movs r2, #0x36
	movs r3, #0x12
	str r4, [sp]
	str r7, [sp, #4]
	bl recolor_rect_above_threshold
	movw r3, #0xf8
	movt r3, #0x2000
	b.n .L08014900
.L08014946:
	ldrb.w r0, [r3, #0xf69]
	cmp r0, #2
	bne.w .L080155ea
	ldrb.w r1, [r3, #0xf6b]
	cmp r1, #0xbf
	lsr.w r0, r1, #4
	bhi.w .L08015590
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
	b.w .L0801559a
.L0801497e:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x20
	ldrh.w r7, [r4, r0, lsl #2]
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
	lsls r1, r0, #0x19
	bpl.w .L08014538
.L080149aa:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x20
	ldrh.w r7, [r4, r0, lsl #2]
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
	lsls r1, r0, #0x15
	bpl.w .L0801453e
.L080149d6:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x20
	ldrh.w r7, [r4, r0, lsl #2]
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
	lsls r1, r0, #0x1c
	bpl.w .L08014544
.L08014a02:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x3a
	ldrh.w r7, [r4, r0, lsl #2]
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
	lsls r1, r0, #0x18
	bpl.w .L0801454a
.L08014a2e:
	ldrb.w r0, [r3, #0xf63]
	movs r1, #0x3a
	ldrh.w r7, [r4, r0, lsl #2]
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
	lsls r1, r0, #0x14
	bmi.w .L0801454e
	b.n .L08014574
.L08014a5c:
	movw r0, #:lower16:d_080bc54a
	movt r0, #:upper16:d_080bc54a
	movs r1, #0xa6
.L08014a66:
	movs r2, #0x45
	bl decode_image_file_with_offset
	movs r0, #2
.L08014a6e:
	movw r9, #:lower16:d_0804c180
	movt r9, #:upper16:d_0804c180
	ldrh.w r0, [r9, r0, lsl #1]
	movs r1, #1
	movw r8, #0x1114
	adr.w r2, .L08015738
	movt r8, #0x2000
	str r2, [sp]
	strd r0, r1, [sp, #8]
	movs r0, #0xb6
	movs r1, #0x3d
	movs r2, #0x5c
	movs r3, #0x22
	str.w r8, [sp, #4]
	bl draw_wrapped_text_in_box
	movw r3, #0xf8
	movt r3, #0x2000
	ldrb.w r0, [r3, #0xf69]
	cbz r0, .L08014adc
	ldrb.w r0, [r3, #0xf6b]
	cmp r0, #1
	bne.n .L08014adc
	movw r0, #:lower16:d_080bc498+1
	movt r0, #:upper16:d_080bc498+1
	movs r1, #0x79
	movs r2, #0x85
	mov r4, r3
	bl decode_image_file_with_offset
	ldrb.w r0, [r4, #0x34]
	cmp r0, #1
	bne.w .L08014c2e
	movw r0, #:lower16:d_080bc54a
	movt r0, #:upper16:d_080bc54a
	movs r1, #0xa6
	b.n .L08014c38
.L08014adc:
	movw r2, #0x8350
	movs r0, #0x86
	mov.w lr, #0x87
	movt r2, #0x2000
	movw r3, #0x131
	movw r12, #0x18c3
	b.n .L08014b00
.L08014af4:
	adds r0, #2
	cmp r0, #0xa6
	add.w lr, lr, #2
	beq.w .L08014c02
.L08014b00:
	movs r6, #0x7b
	b.n .L08014b0a
.L08014b04:
	adds r6, #2
	cmp r6, r3
	beq.n .L08014b7c
.L08014b0a:
	ldrh r5, [r2]
	subs r4, r6, #1
	cmp r4, r5
	bcc.n .L08014b44
	ldrh r5, [r2]
	ldrh r7, [r2, #4]
	add r7, r5
	cmp r7, r4
	bls.n .L08014b44
	ldrh r7, [r2, #2]
	cmp r0, r7
	bcc.n .L08014b44
	ldrh r7, [r2, #2]
	ldrh r5, [r2, #6]
	add r7, r5
	cmp r7, r0
	bls.n .L08014b44
	ldr r7, [r2, #8]
	ldrh r5, [r2]
	ldrh r4, [r2, #2]
	ldrh r1, [r2, #4]
	subs r4, r0, r4
	muls r1, r4, r1
	subs r1, r1, r5
	add r1, r6
	add.w r1, r7, r1, lsl #1
	strh.w r12, [r1, #-2]
.L08014b44:
	ldrh r1, [r2]
	cmp r6, r1
	bcc.n .L08014b04
	ldrh r1, [r2]
	ldrh r4, [r2, #4]
	add r1, r4
	cmp r1, r6
	bls.n .L08014b04
	ldrh r1, [r2, #2]
	cmp r0, r1
	bcc.n .L08014b04
	ldrh r1, [r2, #2]
	ldrh r4, [r2, #6]
	add r1, r4
	cmp r1, r0
	bls.n .L08014b04
	ldr r1, [r2, #8]
	ldrh r4, [r2]
	ldrh r5, [r2, #2]
	ldrh r7, [r2, #4]
	subs r5, r0, r5
	muls r5, r7, r5
	subs r4, r5, r4
	add r4, r6
	strh.w r12, [r1, r4, lsl #1]
	b.n .L08014b04
	.byte 0x00, 0xbf @ padding
.L08014b7c:
	orr.w r6, r0, #1
	movs r4, #0x7b
	b.n .L08014b8a
.L08014b84:
	adds r4, #2
	cmp r4, r3
	beq.n .L08014af4
.L08014b8a:
	ldrh r1, [r2]
	subs r5, r4, #1
	cmp r5, r1
	bcc.n .L08014bc8
	ldrh r1, [r2]
	ldrh r7, [r2, #4]
	add r1, r7
	cmp r1, r5
	bls.n .L08014bc8
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08014bc8
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08014bc8
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	add.w r1, r10, r1, lsl #1
	strh.w r12, [r1, #-2]
.L08014bc8:
	ldrh r1, [r2]
	cmp r4, r1
	bcc.n .L08014b84
	ldrh r1, [r2]
	ldrh r5, [r2, #4]
	add r1, r5
	cmp r1, r4
	bls.n .L08014b84
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08014b84
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08014b84
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	strh.w r12, [r10, r1, lsl #1]
	b.n .L08014b84
.L08014c02:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x34]
	movs r1, #0xa6
	movs r2, #0x8f
	cmp r0, #1
	ittee ne
	movwne r0, #:lower16:d_080bc5ce+1
	movtne r0, #:upper16:d_080bc5ce+1
	movweq r0, #:lower16:d_080bc4f2
	movteq r0, #:upper16:d_080bc4f2
	bl decode_image_file_with_offset
	movs r0, #1
	b.n .L08014c40
.L08014c2e:
	movw r0, #:lower16:d_080bc5fc
	movt r0, #:upper16:d_080bc5fc
	movs r1, #0xa5
.L08014c38:
	movs r2, #0x8d
	bl decode_image_file_with_offset
	movs r0, #2
.L08014c40:
	ldrh.w r0, [r9, r0, lsl #1]
	movs r7, #1
	adr.w r1, .L0801573c
.L08014c4a:
	strd r1, r8, [sp]
	str r0, [sp, #8]
	movs r0, #0xb6
	movs r1, #0x85
	b.n .L080151f4
.L08014c56:
	movw r0, #:lower16:d_080bc54a
	movt r0, #:upper16:d_080bc54a
	movs r1, #0xa6
.L08014c60:
	movs r2, #0x45
	bl decode_image_file_with_offset
	movs r0, #2
.L08014c68:
	movw r9, #:lower16:d_0804c180
	movt r9, #:upper16:d_0804c180
	ldrh.w r0, [r9, r0, lsl #1]
	movw r2, #:lower16:d_080bbc36+1
	movs r1, #1
	movw r8, #0x1114
	movt r2, #:upper16:d_080bbc36+1
	movt r8, #0x2000
	str r2, [sp]
	strd r0, r1, [sp, #8]
	movs r0, #0xb6
	movs r1, #0x3d
	movs r2, #0x5c
	movs r3, #0x22
	str.w r8, [sp, #4]
	bl draw_wrapped_text_in_box
	movw r1, #0xf8
	movt r1, #0x2000
	ldrb.w r0, [r1, #0xf69]
	cbz r0, .L08014ce0
	ldrb.w r0, [r1, #0xf6b]
	cmp r0, #1
	bne.n .L08014ce0
	movw r0, #:lower16:d_080bc498+1
	movt r0, #:upper16:d_080bc498+1
	movs r1, #0x79
	movs r2, #0x61
	bl decode_image_file_with_offset
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x3c]
	cmp r0, #1
	bne.w .L08014e32
	movw r0, #:lower16:d_080bc54a
	movt r0, #:upper16:d_080bc54a
	movs r1, #0xa6
	b.n .L08014e3c
.L08014ce0:
	movw r2, #0x8350
	movs r0, #0x62
	mov.w lr, #0x63
	movt r2, #0x2000
	movw r3, #0x131
	movw r12, #0x18c3
	b.n .L08014d04
.L08014cf8:
	adds r0, #2
	cmp r0, #0x82
	add.w lr, lr, #2
	beq.w .L08014e06
.L08014d04:
	movs r6, #0x7b
	b.n .L08014d0e
.L08014d08:
	adds r6, #2
	cmp r6, r3
	beq.n .L08014d80
.L08014d0e:
	ldrh r5, [r2]
	subs r4, r6, #1
	cmp r4, r5
	bcc.n .L08014d48
	ldrh r5, [r2]
	ldrh r7, [r2, #4]
	add r7, r5
	cmp r7, r4
	bls.n .L08014d48
	ldrh r7, [r2, #2]
	cmp r0, r7
	bcc.n .L08014d48
	ldrh r7, [r2, #2]
	ldrh r5, [r2, #6]
	add r7, r5
	cmp r7, r0
	bls.n .L08014d48
	ldr r7, [r2, #8]
	ldrh r5, [r2]
	ldrh r4, [r2, #2]
	ldrh r1, [r2, #4]
	subs r4, r0, r4
	muls r1, r4, r1
	subs r1, r1, r5
	add r1, r6
	add.w r1, r7, r1, lsl #1
	strh.w r12, [r1, #-2]
.L08014d48:
	ldrh r1, [r2]
	cmp r6, r1
	bcc.n .L08014d08
	ldrh r1, [r2]
	ldrh r4, [r2, #4]
	add r1, r4
	cmp r1, r6
	bls.n .L08014d08
	ldrh r1, [r2, #2]
	cmp r0, r1
	bcc.n .L08014d08
	ldrh r1, [r2, #2]
	ldrh r4, [r2, #6]
	add r1, r4
	cmp r1, r0
	bls.n .L08014d08
	ldr r1, [r2, #8]
	ldrh r4, [r2]
	ldrh r5, [r2, #2]
	ldrh r7, [r2, #4]
	subs r5, r0, r5
	muls r5, r7, r5
	subs r4, r5, r4
	add r4, r6
	strh.w r12, [r1, r4, lsl #1]
	b.n .L08014d08
	.byte 0x00, 0xbf @ padding
.L08014d80:
	orr.w r6, r0, #1
	movs r4, #0x7b
	b.n .L08014d8e
.L08014d88:
	adds r4, #2
	cmp r4, r3
	beq.n .L08014cf8
.L08014d8e:
	ldrh r1, [r2]
	subs r5, r4, #1
	cmp r5, r1
	bcc.n .L08014dcc
	ldrh r1, [r2]
	ldrh r7, [r2, #4]
	add r1, r7
	cmp r1, r5
	bls.n .L08014dcc
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08014dcc
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08014dcc
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	add.w r1, r10, r1, lsl #1
	strh.w r12, [r1, #-2]
.L08014dcc:
	ldrh r1, [r2]
	cmp r4, r1
	bcc.n .L08014d88
	ldrh r1, [r2]
	ldrh r5, [r2, #4]
	add r1, r5
	cmp r1, r4
	bls.n .L08014d88
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08014d88
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08014d88
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	strh.w r12, [r10, r1, lsl #1]
	b.n .L08014d88
.L08014e06:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x3c]
	movs r1, #0xa6
	movs r2, #0x6b
	cmp r0, #1
	ittee ne
	movwne r0, #:lower16:d_080bc5ce+1
	movtne r0, #:upper16:d_080bc5ce+1
	movweq r0, #:lower16:d_080bc4f2
	movteq r0, #:upper16:d_080bc4f2
	bl decode_image_file_with_offset
	movs r0, #1
	b.n .L08014e44
.L08014e32:
	movw r0, #:lower16:d_080bc5fc
	movt r0, #:upper16:d_080bc5fc
	movs r1, #0xa5
.L08014e3c:
	movs r2, #0x69
	bl decode_image_file_with_offset
	movs r0, #2
.L08014e44:
	ldrh.w r0, [r9, r0, lsl #1]
	movw r2, #:lower16:d_080bbc86
	movs r1, #1
	movt r2, #:upper16:d_080bbc86
	str r2, [sp]
	strd r0, r1, [sp, #8]
	movs r0, #0xb6
	movs r1, #0x61
	movs r2, #0x5c
	movs r3, #0x22
	str.w r8, [sp, #4]
	bl draw_wrapped_text_in_box
	movw r1, #0xf8
	movt r1, #0x2000
	ldrb.w r0, [r1, #0xf69]
	cbz r0, .L08014eac
	ldrb.w r0, [r1, #0xf6b]
	cmp r0, #2
	bne.n .L08014eac
	movw r0, #:lower16:d_080bc498+1
	movt r0, #:upper16:d_080bc498+1
	movs r1, #0x79
	movs r2, #0x85
	bl decode_image_file_with_offset
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x3c]
	cmp r0, #2
	bne.w .L08014ffe
	movw r0, #:lower16:d_080bc54a
	movt r0, #:upper16:d_080bc54a
	movs r1, #0xa6
	b.n .L08015008
.L08014eac:
	movw r2, #0x8350
	movs r0, #0x86
	mov.w lr, #0x87
	movt r2, #0x2000
	movw r3, #0x131
	movw r12, #0x18c3
	b.n .L08014ed0
.L08014ec4:
	adds r0, #2
	cmp r0, #0xa6
	add.w lr, lr, #2
	beq.w .L08014fd2
.L08014ed0:
	movs r6, #0x7b
	b.n .L08014eda
.L08014ed4:
	adds r6, #2
	cmp r6, r3
	beq.n .L08014f4c
.L08014eda:
	ldrh r4, [r2]
	subs r5, r6, #1
	cmp r5, r4
	bcc.n .L08014f14
	ldrh r4, [r2]
	ldrh r7, [r2, #4]
	add r7, r4
	cmp r7, r5
	bls.n .L08014f14
	ldrh r7, [r2, #2]
	cmp r0, r7
	bcc.n .L08014f14
	ldrh r7, [r2, #2]
	ldrh r5, [r2, #6]
	add r7, r5
	cmp r7, r0
	bls.n .L08014f14
	ldr r7, [r2, #8]
	ldrh r5, [r2]
	ldrh r4, [r2, #2]
	ldrh r1, [r2, #4]
	subs r4, r0, r4
	muls r1, r4, r1
	subs r1, r1, r5
	add r1, r6
	add.w r1, r7, r1, lsl #1
	strh.w r12, [r1, #-2]
.L08014f14:
	ldrh r1, [r2]
	cmp r6, r1
	bcc.n .L08014ed4
	ldrh r1, [r2]
	ldrh r4, [r2, #4]
	add r1, r4
	cmp r1, r6
	bls.n .L08014ed4
	ldrh r1, [r2, #2]
	cmp r0, r1
	bcc.n .L08014ed4
	ldrh r1, [r2, #2]
	ldrh r4, [r2, #6]
	add r1, r4
	cmp r1, r0
	bls.n .L08014ed4
	ldr r1, [r2, #8]
	ldrh r4, [r2]
	ldrh r5, [r2, #2]
	ldrh r7, [r2, #4]
	subs r5, r0, r5
	muls r5, r7, r5
	subs r4, r5, r4
	add r4, r6
	strh.w r12, [r1, r4, lsl #1]
	b.n .L08014ed4
	.byte 0x00, 0xbf @ padding
.L08014f4c:
	orr.w r6, r0, #1
	movs r4, #0x7b
	b.n .L08014f5a
.L08014f54:
	adds r4, #2
	cmp r4, r3
	beq.n .L08014ec4
.L08014f5a:
	ldrh r1, [r2]
	subs r5, r4, #1
	cmp r5, r1
	bcc.n .L08014f98
	ldrh r1, [r2]
	ldrh r7, [r2, #4]
	add r1, r7
	cmp r1, r5
	bls.n .L08014f98
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08014f98
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08014f98
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	add.w r1, r10, r1, lsl #1
	strh.w r12, [r1, #-2]
.L08014f98:
	ldrh r1, [r2]
	cmp r4, r1
	bcc.n .L08014f54
	ldrh r1, [r2]
	ldrh r5, [r2, #4]
	add r1, r5
	cmp r1, r4
	bls.n .L08014f54
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08014f54
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08014f54
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	strh.w r12, [r10, r1, lsl #1]
	b.n .L08014f54
.L08014fd2:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x3c]
	movs r1, #0xa6
	movs r2, #0x8f
	cmp r0, #2
	ittee ne
	movwne r0, #:lower16:d_080bc5ce+1
	movtne r0, #:upper16:d_080bc5ce+1
	movweq r0, #:lower16:d_080bc4f2
	movteq r0, #:upper16:d_080bc4f2
	bl decode_image_file_with_offset
	movs r0, #1
	b.n .L08015010
.L08014ffe:
	movw r0, #:lower16:d_080bc5fc
	movt r0, #:upper16:d_080bc5fc
	movs r1, #0xa5
.L08015008:
	movs r2, #0x8d
	bl decode_image_file_with_offset
	movs r0, #2
.L08015010:
	ldrh.w r0, [r9, r0, lsl #1]
	movw r2, #:lower16:d_080bbc6c+1
	movs r1, #1
	movt r2, #:upper16:d_080bbc6c+1
	str r2, [sp]
	strd r0, r1, [sp, #8]
	movs r0, #0xb6
	movs r1, #0x85
	movs r2, #0x5c
	movs r3, #0x22
	str.w r8, [sp, #4]
	bl draw_wrapped_text_in_box
	movw r3, #0xf8
	movt r3, #0x2000
	ldrb.w r0, [r3, #0xf69]
	cbz r0, .L08015072
	ldrb.w r0, [r3, #0xf6b]
	cmp r0, #3
	bne.n .L08015072
	movw r0, #:lower16:d_080bc498+1
	movt r0, #:upper16:d_080bc498+1
	movs r1, #0x79
	movs r2, #0xa9
	mov r4, r3
	bl decode_image_file_with_offset
	ldrb.w r0, [r4, #0x3c]
	cmp r0, #3
	bne.w .L080151ce
	movw r0, #:lower16:d_080bc54a
	movt r0, #:upper16:d_080bc54a
	movs r1, #0xa6
	b.n .L080151d8
.L08015072:
	movw r2, #0x8350
	movs r0, #0xaa
	mov.w lr, #0xab
	movt r2, #0x2000
	movw r3, #0x131
	movw r12, #0x18c3
	b.n .L08015098
	.byte 0x00, 0xbf @ padding
.L0801508c:
	adds r0, #2
	cmp r0, #0xca
	add.w lr, lr, #2
	beq.w .L080151a2
.L08015098:
	movs r6, #0x7b
	b.n .L080150aa
.L0801509c:
	.asciz "X1-X2"
	.short 0x0000 @ padding
.L080150a4:
	adds r6, #2
	cmp r6, r3
	beq.n .L0801511c
.L080150aa:
	ldrh r4, [r2]
	subs r5, r6, #1
	cmp r5, r4
	bcc.n .L080150e4
	ldrh r4, [r2]
	ldrh r7, [r2, #4]
	add r7, r4
	cmp r7, r5
	bls.n .L080150e4
	ldrh r7, [r2, #2]
	cmp r0, r7
	bcc.n .L080150e4
	ldrh r7, [r2, #2]
	ldrh r5, [r2, #6]
	add r7, r5
	cmp r7, r0
	bls.n .L080150e4
	ldr r7, [r2, #8]
	ldrh r5, [r2]
	ldrh r4, [r2, #2]
	ldrh r1, [r2, #4]
	subs r4, r0, r4
	muls r1, r4, r1
	subs r1, r1, r5
	add r1, r6
	add.w r1, r7, r1, lsl #1
	strh.w r12, [r1, #-2]
.L080150e4:
	ldrh r1, [r2]
	cmp r6, r1
	bcc.n .L080150a4
	ldrh r1, [r2]
	ldrh r4, [r2, #4]
	add r1, r4
	cmp r1, r6
	bls.n .L080150a4
	ldrh r1, [r2, #2]
	cmp r0, r1
	bcc.n .L080150a4
	ldrh r1, [r2, #2]
	ldrh r4, [r2, #6]
	add r1, r4
	cmp r1, r0
	bls.n .L080150a4
	ldr r1, [r2, #8]
	ldrh r4, [r2]
	ldrh r5, [r2, #2]
	ldrh r7, [r2, #4]
	subs r5, r0, r5
	muls r5, r7, r5
	subs r4, r5, r4
	add r4, r6
	strh.w r12, [r1, r4, lsl #1]
	b.n .L080150a4
	.byte 0x00, 0xbf @ padding
.L0801511c:
	orr.w r6, r0, #1
	movs r4, #0x7b
	b.n .L0801512a
.L08015124:
	adds r4, #2
	cmp r4, r3
	beq.n .L0801508c
.L0801512a:
	ldrh r1, [r2]
	subs r5, r4, #1
	cmp r5, r1
	bcc.n .L08015168
	ldrh r1, [r2]
	ldrh r7, [r2, #4]
	add r1, r7
	cmp r1, r5
	bls.n .L08015168
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08015168
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08015168
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	add.w r1, r10, r1, lsl #1
	strh.w r12, [r1, #-2]
.L08015168:
	ldrh r1, [r2]
	cmp r4, r1
	bcc.n .L08015124
	ldrh r1, [r2]
	ldrh r5, [r2, #4]
	add r1, r5
	cmp r1, r4
	bls.n .L08015124
	ldrh r1, [r2, #2]
	cmp r6, r1
	bcc.n .L08015124
	ldrh r1, [r2, #2]
	ldrh r5, [r2, #6]
	add r1, r5
	cmp r1, r6
	bls.n .L08015124
	ldr.w r10, [r2, #8]
	ldrh r5, [r2]
	ldrh r7, [r2, #2]
	ldrh r1, [r2, #4]
	sub.w r7, lr, r7
	muls r1, r7, r1
	subs r1, r1, r5
	add r1, r4
	strh.w r12, [r10, r1, lsl #1]
	b.n .L08015124
.L080151a2:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x3c]
	movs r1, #0xa6
	movs r2, #0xb3
	cmp r0, #3
	ittee ne
	movwne r0, #:lower16:d_080bc5ce+1
	movtne r0, #:upper16:d_080bc5ce+1
	movweq r0, #:lower16:d_080bc4f2
	movteq r0, #:upper16:d_080bc4f2
	bl decode_image_file_with_offset
	movs r0, #1
	b.n .L080151e0
.L080151ce:
	movw r0, #:lower16:d_080bc5fc
	movt r0, #:upper16:d_080bc5fc
	movs r1, #0xa5
.L080151d8:
	movs r2, #0xb1
	bl decode_image_file_with_offset
	movs r0, #2
.L080151e0:
	ldrh.w r0, [r9, r0, lsl #1]
	adr.w r1, .L08015734
	movs r7, #1
	strd r1, r8, [sp]
	str r0, [sp, #8]
	movs r0, #0xb6
	movs r1, #0xa9
.L080151f4:
	movs r2, #0x5c
	movs r3, #0x22
.L080151f8:
	str r7, [sp, #0xc]
	bl draw_wrapped_text_in_box
	add sp, #0x1c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08015204:
	movw r0, #:lower16:d_080bc54a
	movt r0, #:upper16:d_080bc54a
	movs r1, #0xb3
.L0801520e:
	movs r2, #0x37
	bl decode_image_file_with_offset
	movs r0, #2
.L08015216:
	movw r1, #:lower16:d_0804c180
	movt r1, #:upper16:d_0804c180
	ldrh.w r0, [r1, r0, lsl #1]
	movw r2, #0x1114
	movw r1, #:lower16:d_080bbc36+1
	movt r2, #0x2000
	movt r1, #:upper16:d_080bbc36+1
	movs r6, #1
	strd r1, r2, [sp]
	str r0, [sp, #8]
	movs r0, #0xb6
	movs r1, #0x2f
	movs r2, #0x5c
	movs r3, #0x22
	str r6, [sp, #0xc]
	bl draw_wrapped_text_in_box
	movw r2, #0xf8
	movw r9, #0x18c3
	mov.w r10, #1
	movt r2, #0x2000
	b.n .L0801530e
	.byte 0x00, 0xbf @ padding
.L0801525c:
	movw r1, #0xcccd
	uxtb.w r0, r10
	movt r1, #0xcccc
	umull r0, r1, r0, r1
	movw r0, #0xf8
	movt r0, #0x2000
	lsrs r4, r1, #2
	ldrb.w r2, [r0, #0x35]
	movs r0, #0x6b
	add.w r1, r4, r4, lsl #3
	mul r8, r4, r0
	sub.w r3, r11, r1, lsl #4
	add.w r0, r8, #0x7f
	rsbs r1, r1, #0
	cmp r10, r2
	add.w r2, r3, #0x39
	lsl.w r5, r1, #4
	uxth r1, r0
	uxth r2, r2
	ittee ne
	movwne r0, #:lower16:d_080bc5ce+1
	movtne r0, #:upper16:d_080bc5ce+1
	movweq r0, #:lower16:d_080bc4f2
	movteq r0, #:upper16:d_080bc4f2
	bl decode_image_file_with_offset
	movs r0, #1
.L080152b4:
	adr.w r2, .L08015714
	add.w r2, r2, r10, lsl #2
	ldr.w r2, [r2, #-4]
	movw r6, #:lower16:d_0804c180
	movt r6, #:upper16:d_0804c180
	add.w r1, r11, r5
	ldrh.w r0, [r6, r0, lsl #1]
	movs r6, #0x4a
	str r2, [sp]
	movw r2, #0x1114
	add.w r3, r8, #0x8e
	adds r1, #0x30
	sub.w r6, r6, r4, lsl #4
	movt r2, #0x2000
	strd r2, r0, [sp, #4]
	uxth r2, r6
	sxth r1, r1
	sxth r0, r3
	movs r3, #0x20
	movs r6, #1
	str r6, [sp, #0xc]
	bl draw_wrapped_text_in_box
	add.w r10, r10, #1
	movw r2, #0xf8
	cmp.w r10, #9
	movt r2, #0x2000
	beq.w .L080156de
.L0801530e:
	ldrb.w r0, [r2, #0xf69]
	add.w r1, r10, r10, lsl #3
	lsl.w r11, r1, #2
	cbz r0, .L08015340
	ldrb.w r0, [r2, #0xf6b]
	cmp r10, r0
	bne.n .L08015340
	cmp.w r10, #5
	bcc.n .L0801541c
	sub.w r0, r11, #0x61
	uxth r2, r0
	adr.w r0, .L080156fc
	movs r1, #0xe1
	b.n .L08015426
.L08015338:
	.asciz "Y1-Y2"
	.short 0x0000 @ padding
.L08015340:
	cmp.w r10, #5
