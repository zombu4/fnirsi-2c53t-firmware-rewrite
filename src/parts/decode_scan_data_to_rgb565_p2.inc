@ decode_scan_data_to_rgb565_p2.inc - part 2 of 2 of decode_scan_data_to_rgb565 (0x08038524..0x08038f20).
@ Included by part 1 (decode_scan_data_to_rgb565); the instructions continue that function.
@ Convert-and-store loops: per pixel the tail of the 12-byte (4 pixel) block conversion,
@ the 8-pixel block variant with the table at d_0806ef34, the box-averaging loops and the
@ epilogue (pop {r4-r11, pc}).
	ldrb.w	r3, [lr, #0x2]
	subs	r0, #0x80
	mul	r4, r0, r6
	add.w	r4, r4, r4, lsr #22
	add.w	r4, r3, r4, lsr #10
	bfc	r4, #0xa, #0x16
	ldrb.w	r4, [r9, r4]
	ldrb.w	r5, [r12, #0x2]
	strb	r4, [r1, #0x6]
	sub.w	r4, r5, #0x80
	muls	r0, r2
	smlabb	r0, r4, r10, r0
	mul	r4, r4, r11
	add.w	r0, r0, r0, lsr #22
	add.w	r4, r4, r4, lsr #22
	sub.w	r0, r3, r0, lsr #10
	add.w	r3, r3, r4, lsr #10
	bfc	r0, #0xa, #0x16
	bfc	r3, #0xa, #0x16
	ldrb.w	r0, [r9, r0]
	ldrb.w	r3, [r9, r3]
	strb	r0, [r1, #0x7]
	strb	r3, [r1, #0x8]
	ldrb.w	r0, [r12, #0x43]
	ldrb.w	r3, [lr, #0x3]
	subs	r0, #0x80
	movw	lr, #0x59b
	mul	r5, r0, lr
	add.w	r5, r5, r5, lsr #22
	add.w	r5, r3, r5, lsr #10
	bfc	r5, #0xa, #0x16
	ldrb.w	r5, [r9, r5]
	ldrb.w	r4, [r12, #0x3]
	strb	r5, [r1, #0x9]
	sub.w	r5, r4, #0x80
	muls	r0, r2
	smlabb	r0, r5, r10, r0
	add.w	r0, r0, r0, lsr #22
	mul	r5, r5, r11
	sub.w	r0, r3, r0, lsr #10
	add.w	r5, r5, r5, lsr #22
	add.w	r3, r3, r5, lsr #10
	bfc	r0, #0xa, #0x16
	ldrb.w	r0, [r9, r0]
	bfc	r3, #0xa, #0x16
	ldr	r2, [sp, #0x64]
	ldr	r6, [sp, #0x68]
	ldrb.w	r3, [r9, r3]
	adds	r7, #0x4
	strb	r0, [r1, #0xa]
	mov	r0, r8
	cmp	r2, r7
	add.w	r8, r1, #0xc
	strb	r3, [r1, #0xb]
	bne.w	.L08038452
	adds	r0, #0xc
	str	r0, [sp, #0x68]
	ldr	r0, [sp, #0x58]
	ldr.w	r11, [sp, #0x5c]
	adds	r6, r0, r7
	ldr	r0, [sp, #0x60]
	ldrd	r10, r3, [sp, #0x4c]
	ldr.w	r9, [sp, #0x54]
	ldr	r2, [sp, #0x40]
	ldrd	r12, r4, [sp, #0x38]
	adds	r5, r0, r7
.L08038600:
	ldr	r0, [sp, #0x44]
	cmp	r0, #0
	beq.w	.L080383f4
	ldrb.w	r0, [r6, #0x40]
	ldrb	r1, [r6]
	subs	r0, #0x80
	b.n	.L08038390
.L08038612:
	ldr.w	r12, [sp, #0x68]
	movw	lr, #:lower16:d_0806ef34
	mov.w	r8, #0
	movt	lr, #:upper16:d_0806ef34
	strd	r4, r2, [sp, #0x3c]
	str.w	r9, [sp, #0x54]
	str.w	r12, [sp, #0x68]
.L0803862e:
	ldrb.w	r0, [r6, #0x40]
	cmp.w	r8, #8
	sub.w	r0, r0, #0x80
	it	eq
	addeq	r5, #0x38
	movw	r10, #0x59b
	ldrb.w	r3, [r5], #4
	mul	r4, r0, r10
	add.w	r4, r4, r4, lsr #22
	add.w	r4, r3, r4, lsr #10
	bfc	r4, #0xa, #0x16
	ldrb.w	r4, [lr, r4]
	ldr	r7, [sp, #0x68]
	add.w	r1, r8, r8, lsl #1
	ldrb	r2, [r6]
	strb	r4, [r7, r1]
	add	r1, r7
	movw	r7, #0x2db
	subs	r2, #0x80
	muls	r0, r7
	mov.w	r11, #0x160
	movw	r9, #0x716
	smlabb	r0, r2, r11, r0
	mul	r2, r2, r9
	add.w	r0, r0, r0, lsr #22
	add.w	r2, r2, r2, lsr #22
	sub.w	r0, r3, r0, lsr #10
	add.w	r2, r3, r2, lsr #10
	bfc	r0, #0xa, #0x16
	bfc	r2, #0xa, #0x16
	ldrb.w	r0, [lr, r0]
	ldrb.w	r2, [lr, r2]
	strb	r0, [r1, #0x1]
	strb	r2, [r1, #0x2]
	ldrb.w	r0, [r6], #2
	ldrb.w	r3, [r5, #-3]
	ldrb.w	r2, [r6, #0x3e]
	subs	r0, #0x80
	subs	r2, #0x80
	mul	r4, r2, r10
	muls	r2, r7
	smlabb	r2, r0, r11, r2
	mul	r0, r0, r9
	add.w	r4, r4, r4, lsr #22
	add.w	r2, r2, r2, lsr #22
	add.w	r0, r0, r0, lsr #22
	add.w	r4, r3, r4, lsr #10
	sub.w	r2, r3, r2, lsr #10
	add.w	r0, r3, r0, lsr #10
	bfc	r4, #0xa, #0x16
	bfc	r2, #0xa, #0x16
	bfc	r0, #0xa, #0x16
	ldrb.w	r4, [lr, r4]
	ldrb.w	r2, [lr, r2]
	ldrb.w	r0, [lr, r0]
	strb	r4, [r1, #0x3]
	strb	r2, [r1, #0x4]
	strb	r0, [r1, #0x5]
	ldrb.w	r0, [r6, #0x3f]
	ldrb.w	r2, [r6, #-1]
	subs	r0, #0x80
	mul	r4, r0, r10
	subs	r2, #0x80
	muls	r0, r7
	ldrb.w	r3, [r5, #-2]
	smlabb	r0, r2, r11, r0
	mul	r2, r2, r9
	add.w	r4, r4, r4, lsr #22
	add.w	r0, r0, r0, lsr #22
	add.w	r2, r2, r2, lsr #22
	add.w	r4, r3, r4, lsr #10
	sub.w	r0, r3, r0, lsr #10
	add.w	r2, r3, r2, lsr #10
	bfc	r4, #0xa, #0x16
	bfc	r0, #0xa, #0x16
	bfc	r2, #0xa, #0x16
	ldrb.w	r4, [lr, r4]
	ldrb.w	r0, [lr, r0]
	ldrb.w	r2, [lr, r2]
	strb	r4, [r1, #0x6]
	strb	r0, [r1, #0x7]
	strb	r2, [r1, #0x8]
	ldrb.w	r0, [r6, #0x3f]
	ldrb.w	r2, [r5, #-1]
	subs	r0, #0x80
	mul	r3, r0, r10
	add.w	r3, r3, r3, lsr #22
	add.w	r3, r2, r3, lsr #10
	bfc	r3, #0xa, #0x16
	ldrb.w	r3, [lr, r3]
	ldrb.w	r4, [r6, #-1]
	strb	r3, [r1, #0x9]
	sub.w	r3, r4, #0x80
	muls	r0, r7
	smlabb	r0, r3, r11, r0
	mul	r3, r3, r9
	add.w	r0, r0, r0, lsr #22
	add.w	r3, r3, r3, lsr #22
	sub.w	r0, r2, r0, lsr #10
	add.w	r2, r2, r3, lsr #10
	bfc	r2, #0xa, #0x16
	ldrb.w	r2, [lr, r2]
	bfc	r0, #0xa, #0x16
	ldrb.w	r0, [lr, r0]
	strb	r2, [r1, #0xb]
	ldr	r2, [sp, #0x64]
	add.w	r8, r8, #4
	strb	r0, [r1, #0xa]
	mov	r0, r12
	cmp	r2, r8
	add.w	r12, r1, #0xc
	bne.w	.L0803862e
	adds	r0, #0xc
	ldr.w	r11, [sp, #0x5c]
	ldrd	r10, r3, [sp, #0x4c]
	ldr.w	r9, [sp, #0x54]
	ldr	r2, [sp, #0x40]
	ldrd	r12, r4, [sp, #0x38]
	str	r0, [sp, #0x68]
	movw	lr, #0x59b
.L080387cc:
	ldr	r0, [sp, #0x44]
	cmp	r0, #0
	beq.w	.L080383f4
	ldrb.w	r0, [r6, #0x40]
	ldrb	r1, [r6]
	subs	r0, #0x80
	cmp.w	r8, #8
	it	eq
	addeq	r5, #0x38
	b.n	.L08038390
.L080387e6:
	ldrb.w	r0, [r11, #0xd]
	mov.w	r8, #1
	cmp	r0, #0
	beq.w	.L08038afe
	cmp	r3, #0
	lsl.w	r9, r8, r0
	beq.w	.L08038acc
	lsls	r0, r0, #1
	str	r0, [sp, #0x44]
	sub.w	r0, r10, r9
	add.w	r12, r0, r0, lsl #1
	movs	r0, #1
	ldr.w	r3, [r11, #0x64]
	cmp.w	r9, #1
	it	hi
	movhi	r0, r9
	add.w	r1, r0, r0, lsl #1
	str	r1, [sp, #0x60]
	subs	r1, r0, #1
	str	r1, [sp, #0x68]
	and	r1, r0, #1
	str	r1, [sp, #0x40]
	bic	r1, r0, #1
	and	lr, r0, #3
	bic	r0, r0, #3
	str	r1, [sp, #0x3c]
	subs	r1, r0, #4
	lsrs	r1, r1, #2
	add.w	r1, r1, r1, lsl #1
	lsls	r1, r1, #2
	str	r1, [sp, #0x34]
	rsbs	r0, r0, #0
	movs	r1, #0
	str	r0, [sp, #0x64]
	str.w	r9, [sp, #0x48]
	b	.L0803885e
.L0803884e:
	ldr	r1, [sp, #0x28]
	ldr	r0, [sp, #0x30]
	add	r1, r9
	cmp	r1, r0
	mov.w	r8, #1
	bhs.w	.L08038afe
.L0803885e:
	mul	r0, r1, r10
	movs	r2, #0
	str	r1, [sp, #0x28]
	str	r0, [sp, #0x50]
	b	.L08038894
	.byte	0x00, 0xbf	@ padding
.L0803886c:
	ldr	r1, [sp, #0x44]
	ldr	r2, [sp, #0x54]
	lsrs	r0, r1
	ldr.w	r10, [sp, #0x4c]
	strb.w	r0, [r3], #3
	lsr.w	r0, r11, r1
	add	r2, r9
	ldr.w	r11, [sp, #0x5c]
	strb.w	r0, [r3, #-2]
	lsr.w	r0, r8, r1
	cmp	r2, r10
	strb.w	r0, [r3, #-1]
	bhs	.L0803884e
.L08038894:
	ldr	r1, [sp, #0x50]
	ldr.w	r0, [r11, #0x64]
	str	r2, [sp, #0x54]
	add	r1, r2
	ldr	r2, [sp, #0x68]
	add.w	r1, r1, r1, lsl #1
	cmp	r2, #0
	add.w	r10, r0, r1
	mov.w	r8, #0
	mov.w	r11, #0
	mov.w	r0, #0
	str	r3, [sp, #0x58]
	beq.w	.L08038a18
	ldr.w	r9, [sp, #0x3c]
	b	.L080388d4
	.byte	0x00, 0xbf	@ padding
.L080388c4:
	ldr	r1, [sp, #0x60]
	subs.w	r9, r9, #2
	add	r1, r2
	add.w	r10, r1, r12
	beq.w	.L08038a18
.L080388d4:
	ldr	r2, [sp, #0x68]
	ldr	r5, [sp, #0x64]
	mov	r1, r12
	cmp	r2, #3
	mov	r2, r10
	bcc	.L08038936
.L080388e0:
	ldrb.w	r4, [r2], #0xc
	adds	r5, #4
	ldrb.w	r6, [r2, #-0xb]
	ldrb.w	r7, [r2, #-0xa]
	add	r0, r4
	add.w	r4, r11, r6
	add.w	r6, r8, r7
	ldrb.w	r7, [r2, #-8]
	ldrb.w	r12, [r2, #-9]
	add	r7, r4
	ldrb.w	r4, [r2, #-7]
	ldrb.w	r3, [r2, #-6]
	add	r0, r12
	add	r6, r4
	add	r0, r3
	ldrb.w	r3, [r2, #-5]
	ldrb.w	r4, [r2, #-4]
	add	r3, r7
	add.w	r7, r6, r4
	ldrb.w	r4, [r2, #-2]
	ldrb.w	r6, [r2, #-3]
	add.w	r11, r3, r4
	ldrb.w	r3, [r2, #-1]
	add	r0, r6
	add.w	r8, r7, r3
	bne	.L080388e0
.L08038936:
	cmp.w	lr, #0
	mov	r12, r1
	beq	.L08038970
	ldrb	r4, [r2]
	ldrb	r5, [r2, #1]
	ldrb	r6, [r2, #2]
	add	r0, r4
	add	r11, r5
	cmp.w	lr, #1
	add	r8, r6
	beq	.L08038970
	ldrb	r3, [r2, #3]
	ldrb	r7, [r2, #4]
	ldrb	r6, [r2, #5]
	add	r0, r3
	add	r11, r7
	cmp.w	lr, #2
	add	r8, r6
	beq	.L08038970
	ldrb	r3, [r2, #6]
	ldrb	r7, [r2, #7]
	ldrb	r2, [r2, #8]
	add	r0, r3
	add	r11, r7
	add	r8, r2
	nop
.L08038970:
	ldr	r1, [sp, #0x60]
	ldr	r6, [sp, #0x64]
	add.w	r2, r10, r1
	ldr	r1, [sp, #0x68]
	add	r2, r12
	cmp	r1, #3
	mov	r5, r2
	bcc	.L080389da
	nop
.L08038984:
	ldrb.w	r3, [r5], #0xc
	adds	r6, #4
	ldrb.w	r7, [r5, #-0xb]
	ldrb.w	r4, [r5, #-0xa]
	ldrb.w	r1, [r5, #-9]
	add	r0, r3
	add.w	r3, r11, r7
	add.w	r7, r8, r4
	ldrb.w	r4, [r5, #-8]
	add	r0, r1
	add.w	r1, r3, r4
	ldrb.w	r4, [r5, #-6]
	ldrb.w	r3, [r5, #-7]
	add	r0, r4
	ldrb.w	r4, [r5, #-4]
	add	r3, r7
	ldrb.w	r7, [r5, #-5]
	add	r3, r4
	ldrb.w	r4, [r5, #-2]
	add	r1, r7
	ldrb.w	r7, [r5, #-3]
	add.w	r11, r1, r4
	ldrb.w	r1, [r5, #-1]
	add	r0, r7
	add.w	r8, r3, r1
	bne	.L08038984
.L080389da:
	cmp.w	lr, #0
	beq.w	.L080388c4
	ldrb	r1, [r5]
	ldrb	r3, [r5, #1]
	ldrb	r7, [r5, #2]
	add	r0, r1
	add	r11, r3
	cmp.w	lr, #1
	add	r8, r7
	beq.w	.L080388c4
	ldrb	r1, [r5, #3]
	ldrb	r3, [r5, #4]
	ldrb	r7, [r5, #5]
	add	r0, r1
	add	r11, r3
	cmp.w	lr, #2
	add	r8, r7
	beq.w	.L080388c4
	ldrb	r1, [r5, #6]
	ldrb	r3, [r5, #7]
	ldrb	r7, [r5, #8]
	add	r0, r1
	add	r11, r3
	add	r8, r7
	b	.L080388c4
.L08038a18:
	ldr	r1, [sp, #0x40]
	ldr.w	r9, [sp, #0x48]
	ldr	r3, [sp, #0x58]
	cmp	r1, #0
	beq.w	.L0803886c
	ldr	r1, [sp, #0x68]
	cmp	r1, #3
	bcc	.L08038a7c
	ldr	r5, [sp, #0x64]
	add.w	r1, r10, #0xc
	sub.w	r2, r10, #0xc
	str	r1, [sp, #0x38]
.L08038a38:
	ldrb.w	r6, [r2, #0xc]!
	adds	r5, #4
	add	r0, r6
	ldrb	r6, [r2, #1]
	ldrb	r4, [r2, #3]
	ldrb	r7, [r2, #4]
	add	r6, r11
	ldrb	r1, [r2, #2]
	add	r0, r4
	add.w	r4, r6, r7
	ldrb	r7, [r2, #6]
	ldrb	r6, [r2, #5]
	add	r1, r8
	add	r0, r7
	ldrb	r7, [r2, #8]
	add	r1, r6
	ldrb	r6, [r2, #7]
	add	r1, r7
	ldrb	r7, [r2, #0xa]
	add	r4, r6
	ldrb	r6, [r2, #9]
	add.w	r11, r4, r7
	ldrb	r4, [r2, #0xb]
	add	r0, r6
	add.w	r8, r1, r4
	bne	.L08038a38
	ldrd	r1, r2, [sp, #0x34]
	add.w	r10, r2, r1
.L08038a7c:
	cmp.w	lr, #0
	beq.w	.L0803886c
	ldrb.w	r1, [r10]
	ldrb.w	r2, [r10, #1]
	ldrb.w	r4, [r10, #2]
	add	r0, r1
	add	r11, r2
	cmp.w	lr, #1
	add	r8, r4
	beq.w	.L0803886c
	ldrb.w	r1, [r10, #3]
	ldrb.w	r2, [r10, #4]
	ldrb.w	r4, [r10, #5]
	add	r0, r1
	add	r11, r2
	cmp.w	lr, #2
	add	r8, r4
	beq.w	.L0803886c
	ldrb.w	r1, [r10, #6]
	ldrb.w	r2, [r10, #7]
	ldrb.w	r4, [r10, #8]
	add	r0, r1
	add	r11, r2
	add	r8, r4
	b	.L0803886c
.L08038acc:
	ldr	r5, [sp, #0x30]
	lsl.w	r0, r9, #2
	add.w	r1, r9, r9, lsl #1
	lsl.w	r2, r9, #1
	movs	r4, #0
.L08038adc:
	add.w	r7, r4, r9
	cmp	r7, r5
	bhs	.L08038afe
	adds	r6, r2, r4
	cmp	r6, r5
	bhs	.L08038afe
	adds	r6, r1, r4
	cmp	r6, r5
	bhs	.L08038afe
	add	r7, r9
	add	r7, r9
	adds	r6, r0, r4
	add	r7, r9
	cmp	r6, r5
	mov	r4, r7
	blo	.L08038adc
.L08038afe:
	ldrb.w	r0, [r11, #0xd]
	ldr.w	r9, [sp, #0x20]
	lsr.w	r1, r10, r0
	cmp	r9, r1
	bhs	.L08038be0
	mov.w	lr, #1
	ldr.w	r0, [r11, #0x64]
	cmp.w	r9, #1
	it	hi
	movhi	lr, r9
	ldr	r2, [sp, #0x24]
	mov.w	r12, #1
	cmp	r2, #1
	it	hi
	movhi	r12, r2
	cmp	r2, #2
	sub.w	r2, lr, #1
	bhs.w	.L08038c54
	mov	r5, r0
.L08038b36:
	ands	r1, r12, #1
	mov.w	r8, #1
	beq	.L08038be0
	cmp	r2, #3
	bcc	.L08038bae
	bic	r1, lr, #3
	rsbs	r1, r1, #0
.L08038b4a:
	ldrb.w	r2, [r5], #0xc
	adds	r1, #4
	strb.w	r2, [r0], #0xc
	ldrb.w	r2, [r5, #-0xb]
	strb.w	r2, [r0, #-0xb]
	ldrb.w	r2, [r5, #-0xa]
	strb.w	r2, [r0, #-0xa]
	ldrb.w	r2, [r5, #-9]
	strb.w	r2, [r0, #-9]
	ldrb.w	r2, [r5, #-8]
	strb.w	r2, [r0, #-8]
	ldrb.w	r2, [r5, #-7]
	strb.w	r2, [r0, #-7]
	ldrb.w	r2, [r5, #-6]
	strb.w	r2, [r0, #-6]
	ldrb.w	r2, [r5, #-5]
	strb.w	r2, [r0, #-5]
	ldrb.w	r2, [r5, #-4]
	strb.w	r2, [r0, #-4]
	ldrb.w	r2, [r5, #-3]
	strb.w	r2, [r0, #-3]
	ldrb.w	r2, [r5, #-2]
	strb.w	r2, [r0, #-2]
	ldrb.w	r2, [r5, #-1]
	strb.w	r2, [r0, #-1]
	bne	.L08038b4a
.L08038bae:
	ands.w	r1, lr, #3
	beq	.L08038be0
	ldrb	r2, [r5]
	cmp	r1, #1
	strb	r2, [r0]
	ldrb	r2, [r5, #1]
	strb	r2, [r0, #1]
	ldrb	r2, [r5, #2]
	strb	r2, [r0, #2]
	beq	.L08038be0
	ldrb	r2, [r5, #3]
	cmp	r1, #2
	strb	r2, [r0, #3]
	ldrb	r2, [r5, #4]
	strb	r2, [r0, #4]
	ldrb	r2, [r5, #5]
	strb	r2, [r0, #5]
	beq	.L08038be0
	ldrb	r1, [r5, #6]
	strb	r1, [r0, #6]
	ldrb	r1, [r5, #7]
	strb	r1, [r0, #7]
	ldrb	r1, [r5, #8]
	strb	r1, [r0, #8]
.L08038be0:
	ldr	r0, [sp, #0x24]
	ldr.w	r1, [r11, #0x64]
	mul	r0, r0, r9
	ands.w	r6, r0, #3
	sub.w	r2, r0, #1
	beq	.L08038c1c
	ldrb	r3, [r1]
	ldrb	r7, [r1, #1]
	and	r5, r3, #0xf8
	and	r3, r7, #0xfc
	lsls	r7, r3, #3
	mov	r3, r1
	ldrb.w	r4, [r3, #2]!
	orr.w	r7, r7, r5, lsl #8
	orr.w	r7, r7, r4, lsr #3
	cmp	r6, #1
	strh	r7, [r1]
	bne	.L08038c22
	adds	r7, r1, #3
	mov	r0, r2
	b	.L08038df6
.L08038c1c:
	mov	r7, r1
	mov	r3, r1
	b	.L08038df6
.L08038c22:
	mov	r3, r1
	ldrb.w	r7, [r3, #4]!
	cmp	r6, #2
	ldrb.w	r5, [r3, #-1]
	and	r7, r7, #0xfc
	ldrb	r4, [r3, #1]
	and	r5, r5, #0xf8
	lsl.w	r7, r7, #3
	orr.w	r5, r7, r5, lsl #8
	add.w	r7, r3, #2
	orr.w	r5, r5, r4, lsr #3
	strh.w	r5, [r3, #-2]
	bne.w	.L08038dd4
	subs	r0, #2
	b	.L08038df6
.L08038c54:
	sub.w	r1, r1, r9
	add.w	r7, r1, r1, lsl #1
	bic	r1, lr, #3
	bic	r6, r12, #1
	and	r4, lr, #3
	rsb.w	r8, r1, #0
	mov	r5, r0
	b	.L08038c7c
.L08038c70:
	adds	r5, #3
	adds	r0, #3
.L08038c74:
	subs	r6, #2
	add	r5, r7
	beq.w	.L08038b36
.L08038c7c:
	cmp	r2, #3
	bcc	.L08038ce8
	mov	r3, r8
	nop
.L08038c84:
	ldrb.w	r1, [r5], #0xc
	adds	r3, #4
	strb.w	r1, [r0], #0xc
	ldrb.w	r1, [r5, #-0xb]
	strb.w	r1, [r0, #-0xb]
	ldrb.w	r1, [r5, #-0xa]
	strb.w	r1, [r0, #-0xa]
	ldrb.w	r1, [r5, #-9]
	strb.w	r1, [r0, #-9]
	ldrb.w	r1, [r5, #-8]
	strb.w	r1, [r0, #-8]
	ldrb.w	r1, [r5, #-7]
	strb.w	r1, [r0, #-7]
	ldrb.w	r1, [r5, #-6]
	strb.w	r1, [r0, #-6]
	ldrb.w	r1, [r5, #-5]
	strb.w	r1, [r0, #-5]
	ldrb.w	r1, [r5, #-4]
	strb.w	r1, [r0, #-4]
	ldrb.w	r1, [r5, #-3]
	strb.w	r1, [r0, #-3]
	ldrb.w	r1, [r5, #-2]
	strb.w	r1, [r0, #-2]
	ldrb.w	r1, [r5, #-1]
	strb.w	r1, [r0, #-1]
	bne	.L08038c84
.L08038ce8:
	cbz	r4, .L08038d26
	ldrb	r1, [r5]
	cmp	r4, #1
	strb	r1, [r0]
	ldrb	r1, [r5, #1]
	strb	r1, [r0, #1]
	ldrb	r1, [r5, #2]
	strb	r1, [r0, #2]
	bne	.L08038d00
	adds	r5, #3
	adds	r0, #3
	b	.L08038d26
.L08038d00:
	ldrb	r1, [r5, #3]
	cmp	r4, #2
	strb	r1, [r0, #3]
	ldrb	r1, [r5, #4]
	strb	r1, [r0, #4]
	ldrb	r1, [r5, #5]
	strb	r1, [r0, #5]
	bne	.L08038d16
	adds	r5, #6
	adds	r0, #6
	b	.L08038d26
.L08038d16:
	ldrb	r1, [r5, #6]
	strb	r1, [r0, #6]
	ldrb	r1, [r5, #7]
	strb	r1, [r0, #7]
	ldrb	r1, [r5, #8]
	adds	r5, #9
	strb	r1, [r0, #8]
	adds	r0, #9
.L08038d26:
	add	r5, r7
	cmp	r2, #3
	mov	r3, r8
	bcc	.L08038d94
	nop
.L08038d30:
	ldrb.w	r1, [r5], #0xc
	adds	r3, #4
	strb.w	r1, [r0], #0xc
	ldrb.w	r1, [r5, #-0xb]
	strb.w	r1, [r0, #-0xb]
	ldrb.w	r1, [r5, #-0xa]
	strb.w	r1, [r0, #-0xa]
	ldrb.w	r1, [r5, #-9]
	strb.w	r1, [r0, #-9]
	ldrb.w	r1, [r5, #-8]
	strb.w	r1, [r0, #-8]
	ldrb.w	r1, [r5, #-7]
	strb.w	r1, [r0, #-7]
	ldrb.w	r1, [r5, #-6]
	strb.w	r1, [r0, #-6]
	ldrb.w	r1, [r5, #-5]
	strb.w	r1, [r0, #-5]
	ldrb.w	r1, [r5, #-4]
	strb.w	r1, [r0, #-4]
	ldrb.w	r1, [r5, #-3]
	strb.w	r1, [r0, #-3]
	ldrb.w	r1, [r5, #-2]
	strb.w	r1, [r0, #-2]
	ldrb.w	r1, [r5, #-1]
	strb.w	r1, [r0, #-1]
	bne	.L08038d30
.L08038d94:
	cmp	r4, #0
	beq.w	.L08038c74
	ldrb	r1, [r5]
	cmp	r4, #1
	strb	r1, [r0]
	ldrb	r1, [r5, #1]
	strb	r1, [r0, #1]
	ldrb	r1, [r5, #2]
	strb	r1, [r0, #2]
	beq.w	.L08038c70
	ldrb	r1, [r5, #3]
	cmp	r4, #2
	strb	r1, [r0, #3]
	ldrb	r1, [r5, #4]
	strb	r1, [r0, #4]
	ldrb	r1, [r5, #5]
	strb	r1, [r0, #5]
	bne	.L08038dc2
	adds	r5, #6
	adds	r0, #6
	b	.L08038c74
.L08038dc2:
	ldrb	r1, [r5, #6]
	strb	r1, [r0, #6]
	ldrb	r1, [r5, #7]
	strb	r1, [r0, #7]
	ldrb	r1, [r5, #8]
	adds	r5, #9
	strb	r1, [r0, #8]
	adds	r0, #9
	b	.L08038c74
.L08038dd4:
	ldrb	r6, [r1, #7]
	ldrb	r3, [r1, #6]
	and	r6, r6, #0xfc
	ldrb	r5, [r1, #8]
	and	r3, r3, #0xf8
	lsls	r6, r6, #3
	orr.w	r6, r6, r3, lsl #8
	orr.w	r6, r6, r5, lsr #3
	mov	r3, r7
	add.w	r7, r1, #9
	strh	r6, [r1, #4]
	subs	r0, #3
.L08038df6:
	cmp	r2, #3
	bcc	.L08038e78
	sub.w	r2, r7, #0xc
	subs	r3, #8
.L08038e00:
	ldrb.w	r7, [r2, #0xc]!
	subs	r0, #4
	ldrb	r6, [r2, #1]
	and	r7, r7, #0xf8
	and	r6, r6, #0xfc
	ldrb	r5, [r2, #2]
	lsl.w	r6, r6, #3
	orr.w	r7, r6, r7, lsl #8
	orr.w	r7, r7, r5, lsr #3
	strh.w	r7, [r3, #8]!
	ldrb	r6, [r2, #4]
	ldrb	r7, [r2, #3]
	and	r6, r6, #0xfc
	ldrb	r5, [r2, #5]
	and	r7, r7, #0xf8
	lsl.w	r6, r6, #3
	orr.w	r7, r6, r7, lsl #8
	orr.w	r7, r7, r5, lsr #3
	strh	r7, [r3, #2]
	ldrb	r6, [r2, #7]
	ldrb	r7, [r2, #6]
	and	r6, r6, #0xfc
	ldrb	r5, [r2, #8]
	and	r7, r7, #0xf8
	lsl.w	r6, r6, #3
	orr.w	r7, r6, r7, lsl #8
	orr.w	r7, r7, r5, lsr #3
	strh	r7, [r3, #4]
	ldrb	r6, [r2, #0xa]
	ldrb	r7, [r2, #9]
	and	r6, r6, #0xfc
	ldrb	r5, [r2, #0xb]
	and	r7, r7, #0xf8
	lsl.w	r6, r6, #3
	orr.w	r7, r6, r7, lsl #8
	orr.w	r7, r7, r5, lsr #3
	strh	r7, [r3, #6]
	bne	.L08038e00
.L08038e78:
	ldr	r5, [sp, #0xc]
	mov	r0, r11
	add	r2, sp, #0x6c
	blx	r5
	cmp	r0, #0
	beq	.L08038f14
	ldr.w	r0, [r11, #0x1c]
	ldrd	r3, r10, [sp, #4]
	ldr	r6, [sp, #0x18]
.L08038e8e:
	ldr	r2, [sp, #0x2c]
	ldr	r7, [sp, #0x10]
	add	r2, r10
	ldr	r4, [sp, #0x14]
	cmp	r2, r0
	mov	r1, r2
	str	r2, [sp, #0x2c]
	bcc.w	.L0803757e
	ldr.w	r1, [r11, #0x20]
	b	.L08038ea8
.L08038ea6:
	movs	r0, #0
.L08038ea8:
	add	r6, r3
	cmp	r6, r1
	mov.w	r2, #0
	bcc.w	.L08037568
	b	.L08038f16
.L08038eb6:
	movs	r2, #0
	b	.L08038f16
.L08038eba:
	mvn	r8, #5
	rsb.w	r2, r8, #0
	b	.L08038f16
.L08038ec4:
	movs	r2, #6
	b	.L08038f16
.L08038ec8:
	mvn	r8, #1
	rsb.w	r2, r8, #0
	b	.L08038f16
.L08038ed2:
	mvn	r8, #5
	rsb.w	r2, r8, #0
	b	.L08038f16
.L08038edc:
	movs	r2, #6
	b	.L08038f16
.L08038ee0:
	mvn	r8, #1
	rsb.w	r2, r8, #0
	b	.L08038f16
.L08038eea:
	movs	r2, #6
	b	.L08038f16
.L08038eee:
	movs	r2, #6
	b	.L08038f16
.L08038ef2:
	movs	r2, #2
	b	.L08038f16
.L08038ef6:
	movs	r2, #6
	b	.L08038f16
.L08038efa:
	movs	r2, #2
	b	.L08038f16
.L08038efe:
	movs	r2, #6
	b	.L08038f16
.L08038f02:
	movs	r2, #6
	b	.L08038f16
.L08038f06:
	movs	r2, #2
	b	.L08038f16
.L08038f0a:
	movs	r2, #2
	b	.L08038f16
.L08038f0e:
	rsb.w	r2, r8, #0
	b	.L08038f16
.L08038f14:
	movs	r2, #1
.L08038f16:
	uxtb	r0, r2
	add	sp, #0x74
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short	0x0000	@ padding
