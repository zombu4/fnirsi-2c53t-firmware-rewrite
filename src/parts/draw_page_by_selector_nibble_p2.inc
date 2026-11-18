@ draw_page_by_selector_nibble part 2 of 2 (0x0801df50..0x0801e458 original): the
@ remaining pixel-plot loops (rectangle clip test against the descriptor at r2 and a
@ store of colour r12 into the frame buffer), the image / label drawing for the
@ 15min / 30min / 1hour choices, the version string "V%s" / "1.2.0", the
@ "3:/System file/142.jpg" path, the image address tables and the label strings.
@ Fragment included by part 1: continues its instructions, no section line.
.L0801df50:
	adds	r4, #2
	cmp	r4, r3
	beq.n	.L0801dec0
.L0801df56:
	ldrh	r1, [r2, #0]
	subs	r6, r4, #1
	cmp	r6, r1
	blo.n	.L0801df94
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r6
	bls.n	.L0801df94
	ldrh	r1, [r2, #2]
	cmp	r5, r1
	blo.n	.L0801df94
	ldrh	r1, [r2, #2]
	ldrh	r6, [r2, #6]
	add	r1, r6
	cmp	r1, r5
	bls.n	.L0801df94
	ldr.w	r10, [r2, #8]
	ldrh	r6, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r6
	add	r1, r4
	add.w	r1, r10, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L0801df94:
	ldrh	r1, [r2, #0]
	cmp	r4, r1
	blo.n	.L0801df50
	ldrh	r1, [r2, #0]
	ldrh	r6, [r2, #4]
	add	r1, r6
	cmp	r1, r4
	bls.n	.L0801df50
	ldrh	r1, [r2, #2]
	cmp	r5, r1
	blo.n	.L0801df50
	ldrh	r1, [r2, #2]
	ldrh	r6, [r2, #6]
	add	r1, r6
	cmp	r1, r5
	bls.n	.L0801df50
	ldr.w	r10, [r2, #8]
	ldrh	r6, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r6
	add	r1, r4
	strh.w	r12, [r10, r1, lsl #1]
	b.n	.L0801df50
.L0801dfce:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf65]
	movs	r1, #0xa6
	movs	r2, #0x6b
	cmp	r0, #1
	ittee	ne
	movwne	r0, #:lower16:t_080bc5cf
	movtne	r0, #:upper16:t_080bc5cf
	movweq	r0, #:lower16:t_080bc4f2
	movteq	r0, #:upper16:t_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.n	.L0801e00c
.L0801dffa:
	movw	r0, #:lower16:t_080bc5fc
	movt	r0, #:upper16:t_080bc5fc
	movs	r1, #0xa5
.L0801e004:
	movs	r2, #0x69
	bl	decode_image_file_with_offset
	movs	r0, #2
.L0801e00c:
	ldrh.w	r0, [r9, r0, lsl #1]
	movs	r1, #1
	adr.w	r2, .L0801e440
	str	r2, [sp, #0]
	strd	r0, r1, [sp, #8]
	movs	r0, #0xb6
	movs	r1, #0x61
	movs	r2, #0x5c
	movs	r3, #0x22
	str.w	r8, [sp, #4]
	bl	draw_wrapped_text_in_box
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldrb.w	r0, [r1, #0xf69]
	cbz	r0, .L0801e070
	ldrb.w	r0, [r1, #0xf6b]
	cmp	r0, #2
	bne.n	.L0801e070
	movw	r0, #:lower16:t_080bc499
	movt	r0, #:upper16:t_080bc499
	movs	r1, #0x79
	movs	r2, #0x85
	bl	decode_image_file_with_offset
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf65]
	cmp	r0, #2
	bne.w	.L0801e22a
	movw	r0, #:lower16:t_080bc54a
	movt	r0, #:upper16:t_080bc54a
	movs	r1, #0xa6
	b.n	.L0801e234
.L0801e070:
	movw	r2, #0x8350
	movs	r0, #0x86
	mov.w	lr, #0x87
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L0801e094
.L0801e088:
	adds	r0, #2
	cmp	r0, #0xa6
	add.w	lr, lr, #2
	beq.w	.L0801e1fe
.L0801e094:
	movs	r5, #0x7b
	b.n	.L0801e09e
.L0801e098:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L0801e110
.L0801e09e:
	ldrh	r4, [r2, #0]
	subs	r6, r5, #1
	cmp	r6, r4
	blo.n	.L0801e0d8
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r4
	cmp	r7, r6
	bls.n	.L0801e0d8
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	blo.n	.L0801e0d8
	ldrh	r7, [r2, #2]
	ldrh	r6, [r2, #6]
	add	r7, r6
	cmp	r7, r0
	bls.n	.L0801e0d8
	ldr	r7, [r2, #8]
	ldrh	r6, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r6
	add	r1, r5
	add.w	r1, r7, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L0801e0d8:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	blo.n	.L0801e098
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L0801e098
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	blo.n	.L0801e098
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L0801e098
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r6, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r6, r0, r6
	muls	r6, r7, r6
	subs	r4, r6, r4
	add	r4, r5
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L0801e098
	.byte	0x00, 0xbf	@ padding
.L0801e110:
	orr.w	r5, r0, #1
	movs	r4, #0x7b
	b.n	.L0801e184
.L0801e118:
	.asciz	"V%s"
.L0801e11c:
	.global	firmware_version_text	@ also reported by the USB control channel (usb_ctl.s INFO)
firmware_version_text:
	.asciz	"1.4.8"		@ version shown in About as "V%s": this rewrite
	.short	0x0000	@ padding
.L0801e124:
	.asciz	"3:/System file/142.jpg"
	.byte	0x00	@ string terminator padding (24 bytes in total)
.L0801e17c:
	adds	r4, #2
	cmp	r4, r3
	beq.w	.L0801e088
.L0801e184:
	ldrh	r1, [r2, #0]
	subs	r6, r4, #1
	cmp	r6, r1
	blo.n	.L0801e1c4
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r6
	bls.n	.L0801e1c4
	ldrh	r1, [r2, #2]
	cmp	r5, r1
	blo.n	.L0801e1c4
	ldrh	r1, [r2, #2]
	ldrh	r6, [r2, #6]
	add	r1, r6
	cmp	r1, r5
	bls.n	.L0801e1c4
	ldr.w	r10, [r2, #8]
	ldrh	r6, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r6
	add	r1, r4
	add.w	r1, r10, r1, lsl #1
	strh.w	r12, [r1, #-2]
	nop
.L0801e1c4:
	ldrh	r1, [r2, #0]
	cmp	r4, r1
	blo.n	.L0801e17c
	ldrh	r1, [r2, #0]
	ldrh	r6, [r2, #4]
	add	r1, r6
	cmp	r1, r4
	bls.n	.L0801e17c
	ldrh	r1, [r2, #2]
	cmp	r5, r1
	blo.n	.L0801e17c
	ldrh	r1, [r2, #2]
	ldrh	r6, [r2, #6]
	add	r1, r6
	cmp	r1, r5
	bls.n	.L0801e17c
	ldr.w	r10, [r2, #8]
	ldrh	r6, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r6
	add	r1, r4
	strh.w	r12, [r10, r1, lsl #1]
	b.n	.L0801e17c
.L0801e1fe:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf65]
	movs	r1, #0xa6
	movs	r2, #0x8f
	cmp	r0, #2
	ittee	ne
	movwne	r0, #:lower16:t_080bc5cf
	movtne	r0, #:upper16:t_080bc5cf
	movweq	r0, #:lower16:t_080bc4f2
	movteq	r0, #:upper16:t_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.n	.L0801e23c
.L0801e22a:
	movw	r0, #:lower16:t_080bc5fc
	movt	r0, #:upper16:t_080bc5fc
	movs	r1, #0xa5
.L0801e234:
	movs	r2, #0x8d
	bl	decode_image_file_with_offset
	movs	r0, #2
.L0801e23c:
	ldrh.w	r0, [r9, r0, lsl #1]
	movs	r1, #1
	adr	r2, .L0801e448
	str	r2, [sp, #0]
	strd	r0, r1, [sp, #8]
	movs	r0, #0xb6
	movs	r1, #0x85
	movs	r2, #0x5c
	movs	r3, #0x22
	str.w	r8, [sp, #4]
	bl	draw_wrapped_text_in_box
	movw	r3, #0xf8
	movt	r3, #0x2000
	ldrb.w	r0, [r3, #0xf69]
	cbz	r0, .L0801e298
	ldrb.w	r0, [r3, #0xf6b]
	cmp	r0, #3
	bne.n	.L0801e298
	movw	r0, #:lower16:t_080bc499
	movt	r0, #:upper16:t_080bc499
	movs	r1, #0x79
	movs	r2, #0xa9
	mov	r4, r3
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r4, #0xf65]
	cmp	r0, #3
	bne.w	.L0801e3ea
	movw	r0, #:lower16:t_080bc54a
	movt	r0, #:upper16:t_080bc54a
	movs	r1, #0xa6
	b.n	.L0801e3f4
.L0801e298:
	movw	r2, #0x8350
	movs	r0, #0xaa
	mov.w	lr, #0xab
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L0801e2bc
.L0801e2b0:
	adds	r0, #2
	cmp	r0, #0xca
	add.w	lr, lr, #2
	beq.w	.L0801e3be
.L0801e2bc:
	movs	r5, #0x7b
	b.n	.L0801e2c6
.L0801e2c0:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L0801e338
.L0801e2c6:
	ldrh	r4, [r2, #0]
	subs	r6, r5, #1
	cmp	r6, r4
	blo.n	.L0801e300
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r4
	cmp	r7, r6
	bls.n	.L0801e300
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	blo.n	.L0801e300
	ldrh	r7, [r2, #2]
	ldrh	r6, [r2, #6]
	add	r7, r6
	cmp	r7, r0
	bls.n	.L0801e300
	ldr	r7, [r2, #8]
	ldrh	r6, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r6
	add	r1, r5
	add.w	r1, r7, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L0801e300:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	blo.n	.L0801e2c0
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L0801e2c0
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	blo.n	.L0801e2c0
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L0801e2c0
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r6, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r6, r0, r6
	muls	r6, r7, r6
	subs	r4, r6, r4
	add	r4, r5
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L0801e2c0
	.byte	0x00, 0xbf	@ padding
.L0801e338:
	orr.w	r5, r0, #1
	movs	r4, #0x7b
	b.n	.L0801e346
.L0801e340:
	adds	r4, #2
	cmp	r4, r3
	beq.n	.L0801e2b0
.L0801e346:
	ldrh	r1, [r2, #0]
	subs	r6, r4, #1
	cmp	r6, r1
	blo.n	.L0801e384
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r6
	bls.n	.L0801e384
	ldrh	r1, [r2, #2]
	cmp	r5, r1
	blo.n	.L0801e384
	ldrh	r1, [r2, #2]
	ldrh	r6, [r2, #6]
	add	r1, r6
	cmp	r1, r5
	bls.n	.L0801e384
	ldr.w	r10, [r2, #8]
	ldrh	r6, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r6
	add	r1, r4
	add.w	r1, r10, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L0801e384:
	ldrh	r1, [r2, #0]
	cmp	r4, r1
	blo.n	.L0801e340
	ldrh	r1, [r2, #0]
	ldrh	r6, [r2, #4]
	add	r1, r6
	cmp	r1, r4
	bls.n	.L0801e340
	ldrh	r1, [r2, #2]
	cmp	r5, r1
	blo.n	.L0801e340
	ldrh	r1, [r2, #2]
	ldrh	r6, [r2, #6]
	add	r1, r6
	cmp	r1, r5
	bls.n	.L0801e340
	ldr.w	r10, [r2, #8]
	ldrh	r6, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r6
	add	r1, r4
	strh.w	r12, [r10, r1, lsl #1]
	b.n	.L0801e340
.L0801e3be:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf65]
	movs	r1, #0xa6
	movs	r2, #0xb3
	cmp	r0, #3
	ittee	ne
	movwne	r0, #:lower16:t_080bc5cf
	movtne	r0, #:upper16:t_080bc5cf
	movweq	r0, #:lower16:t_080bc4f2
	movteq	r0, #:upper16:t_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.n	.L0801e3fc
.L0801e3ea:
	movw	r0, #:lower16:t_080bc5fc
	movt	r0, #:upper16:t_080bc5fc
	movs	r1, #0xa5
.L0801e3f4:
	movs	r2, #0xb1
	bl	decode_image_file_with_offset
	movs	r0, #2
.L0801e3fc:
	ldrh.w	r0, [r9, r0, lsl #1]
	adr	r1, .L0801e450
	movs	r7, #1
	strd	r1, r8, [sp, #0]
	str	r0, [sp, #8]
.L0801e40a:
	movs	r0, #0xb6
	movs	r1, #0xa9
.L0801e40e:
	movs	r2, #0x5c
.L0801e410:
	movs	r3, #0x22
	str	r7, [sp, #0xc]
.L0801e414:
	bl	draw_wrapped_text_in_box
	add	sp, #44
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.byte	0x00, 0xbf	@ padding
.L0801e440:
	.asciz	"15min"
	.short	0x0000	@ padding
.L0801e448:
	.asciz	"30min"
	.short	0x0000	@ padding
.L0801e450:
	.asciz	"1hour"
	.short	0x0000	@ padding
