@ image_18.s - part 1 of decode_scan_data_to_rgb565 (image stream scan data decoder, 0x08037524..0x08038524).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ decode_scan_data_to_rgb565 - decodes the scan data of an image stream described
@ by context r0 (set up by 08038f20) and delivers rows through the callback
@ r1(ctx, buffer ctx[0x19], &rect) with rect = four halfwords {left, right, top,
@ bottom} in output pixels. r2 (0..3, else returns 5) is stored at ctx byte +0xd
@ as the reduction shift.
@ Loops over MCU rows (step ctx byte +0xf *8 up to ctx[8]) and columns (step ctx
@ byte +0xe *8 up to ctx[7]); resets the three DC predictors (halfwords at
@ ctx+0x14, +0x16, +0x18) at the start and at each restart.
@ Per MCU it loops over blocks (count = ctx bytes +0xe * +0xf, then two further
@ blocks), reads bits MSB first from the input (ctx[0] remaining count, ctx[1]
@ pointer, byte ctx+0xc bit mask) with Huffman tables selected by block kind from
@ ctx[9..0x14] (code counts, codes, values for DC and AC), refills the 0x200-byte
@ input through ctx[0x1d](ctx, ctx[2], 0x200) (0 gives return 2), handles 0xff byte
@ stuffing (0xff followed by 0 is data, otherwise return 6); a code longer than
@ 16 bits gives 6.
@ Restart: every ushort ctx+0x1a MCUs it reads a byte pair, requires
@ (second & 0xd8) | (first << 8) == 0xffd0 and low 3 bits equal to the restart
@ counter & 7, else returns 6.
@ AC run/size symbols: high nibble = zero run (position above 0x3f gives 6), low
@ nibble = size, symbol 0 ends the block; coefficients are multiplied by the table
@ ctx[0x15 + kind byte at ctx+0x10..] and placed in zig-zag order from table
@ 0x0806ee74; when r2 == 3 only the DC value ((x + bias) >> 8) ^ 0x80 is stored per
@ block and the transform is skipped.
@ Otherwise a fixed-point 8x8 inverse transform (constants 0x16a0, 0x1d90, 0x29cf,
@ 0x1151, rounding 0x8000), outputs clamped through the 1024-byte table 0x0806ef34.
@ Converts the two chroma planes to 3 bytes per pixel:
@ R = Y + (Cr-128)*0x59b >> 10, G = Y - ((Cb-128)*0x160 + (Cr-128)*0x2db) >> 10,
@ B = Y + (Cb-128)*0x716 >> 10 (each product p is taken as (p + (p >> 22 unsigned))
@ >> 10, a division by 1024 rounding toward zero; the sum with Y is clamped by
@ 0x0806ef34 with index & 0x3ff); r2 > 0 averages 2^r2 x 2^r2 pixels (sum >> 2*r2);
@ the block is cut to the image edge, rows compacted, and every pixel packed to 16
@ bits as (R & 0xf8) << 8 | (G & 0xfc) << 3 | B >> 3 at ctx[0x19] before the
@ callback.
@ Returns 0 when all MCU rows are done, 1 when the callback returns 0, 2 on input
@ exhausted, 5 for bad r2, 6 on a data error, and the low byte of the negated value
@ when the accumulated coefficient bits read negative as a signed 32-bit value and
@ its low byte is nonzero (08037d00); when that low byte is zero the remaining block
@ decoding of the MCU is skipped and the output stage (08037d08) runs.
@ Purpose: decodes baseline-style entropy-coded image data (restart markers 0xffd0,
@ byte stuffing, zig-zag order, 8x8 inverse transform) to RGB565 rows.
@ ----------------------------------------------------------------------------
	.section .text.decode_scan_data_to_rgb565,"ax",%progbits
	.global decode_scan_data_to_rgb565
	.thumb_func
	.type decode_scan_data_to_rgb565, %function
decode_scan_data_to_rgb565:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x74
	cmp r2, #0x3
	bls.n .L08037534
	movs r2, #0x5
	b.w .L08038f16
.L08037534:
	mov r11, r0
	mov r5, r1
	ldr.w r1, [r11, #0x20]
	strb r2, [r0, #0xd]
	ldrb r0, [r0, #0xe]
	ldrb.w r2, [r11, #0xf]
	movs r3, #0x0
	cmp r1, #0x0
	str.w r3, [r11, #0x14]
	strh.w r3, [r11, #0x18]
	beq.w .L08038eb6
	lsl.w r10, r0, #0x3
	ldr.w r0, [r11, #0x1c]
	lsls r3, r2, #0x3
	mov.w r8, #0x1
	movs r4, #0x0
	movs r7, #0x0
	movs r6, #0x0
.L08037568:
	cmp r0, #0x0
	beq.w .L08038ea6
	movs r0, #0x0
	str r0, [sp, #0x2c]
	str r6, [sp, #0x18]
	str r5, [sp, #0xc]
	str.w r11, [sp, #0x5c]
	strd r3, r10, [sp, #0x4]
.L0803757e:
	ldrh.w r0, [r11, #0x1a]
	cbz r0, .L08037598
	uxth r1, r7
	cmp r1, r0
	bne.n .L0803759e
	ldr.w r0, [r11, #0x0]
	cbz r0, .L080375a6
	ldr.w r1, [r11, #0x4]
	adds r6, r1, #0x1
	b.n .L080375be
.L08037598:
	strd r7, r4, [sp, #0x10]
	b.n .L08037624
.L0803759e:
	adds r7, #0x1
	str r4, [sp, #0x14]
	str r7, [sp, #0x10]
	b.n .L08037624
.L080375a6:
	ldr.w r6, [r11, #0x8]
	ldr.w r3, [r11, #0x74]
	mov r0, r11
	mov r1, r6
	mov.w r2, #0x200
	blx r3
	cmp r0, #0x0
	beq.w .L08038f06
.L080375be:
	ldrb.w r9, [r6, #0x0]
	subs r0, #0x1
	beq.n .L080375ca
	adds r6, #0x1
	b.n .L080375e2
.L080375ca:
	ldr.w r6, [r11, #0x8]
	ldr.w r3, [r11, #0x74]
	mov r0, r11
	mov r1, r6
	mov.w r2, #0x200
	blx r3
	cmp r0, #0x0
	beq.w .L08038f0a
.L080375e2:
	subs r1, r0, #0x1
	ldrb r0, [r6, #0x0]
	strd r1, r6, [r11, #0x0]
	and.w r1, r0, #0xd8
	orr.w r1, r1, r9, lsl #0x8
	movw r2, #0xffd0
	cmp r1, r2
	mov.w r1, #0x0
	strb.w r1, [r11, #0xc]
	bne.w .L08038efe
	and.w r0, r0, #0x7
	and.w r1, r4, #0x7
	cmp r0, r1
	bne.w .L08038f02
	movs r0, #0x0
	str.w r0, [r11, #0x14]
	strh.w r0, [r11, #0x18]
	adds r4, #0x1
	movs r0, #0x1
	str r4, [sp, #0x14]
	str r0, [sp, #0x10]
.L08037624:
	ldrb.w r0, [r11, #0xe]
	ldrb.w r1, [r11, #0xf]
	ldr.w r2, [r11, #0x64]
	mul r7, r1, r0
	smlabb r0, r1, r0, r8
	ldr.w r3, [r11, #0x68]
	str r0, [sp, #0x20]
	sub.w r0, r2, #0x20
	rsb.w r6, r7, #0x1
	adds r5, r2, #0x4
	str r0, [sp, #0x1c]
	movs r0, #0x0
	str r5, [sp, #0x38]
	str r2, [sp, #0x3c]
	strd r6, r7, [sp, #0x24]
.L08037654:
	adds r1, r6, r0
	str r3, [sp, #0x40]
	str r0, [sp, #0x30]
	cmp r0, r7
	it cc
	movcc r1, #0x0
	mov r0, r1
	cmp r1, #0x0
	str r1, [sp, #0x50]
	it ne
	movne r0, #0x1
	add.w r0, r11, r0, lsl #0x3
	ldr.w r9, [r0, #0x24]
	ldr r7, [r0, #0x34]
	str r0, [sp, #0x44]
	ldr.w r8, [r0, #0x44]
	ldrd r0, r6, [r11, #0x0]
	ldrb.w r1, [r11, #0xc]
	ldrb r2, [r6, #0x0]
	movs r5, #0x10
	movs r4, #0x0
	movs r3, #0x0
	str r3, [sp, #0x68]
	b.n .L080376a6
	.byte 0x00, 0xbf	@ padding
.L08037690:
	ldr.w r9, [sp, #0x64]
	ldrd r11, r5, [sp, #0x5c]
	ldrd r8, r2, [sp, #0x54]
	mov r7, r12
.L0803769e:
	subs r5, #0x1
	cmp r5, #0x0
	beq.w .L08038edc
.L080376a6:
	cbnz r1, .L080376f6
	cbz r0, .L080376ae
	adds r6, #0x1
	b.n .L080376c6
.L080376ae:
	ldr.w r6, [r11, #0x8]
	ldr.w r3, [r11, #0x74]
	mov r0, r11
	mov r1, r6
	mov.w r2, #0x200
	blx r3
	cmp r0, #0x0
	beq.w .L08038efa
.L080376c6:
	ldr r1, [sp, #0x68]
	ldrb r2, [r6, #0x0]
	sub.w r0, r0, #0x1
	cbz r1, .L080376dc
	cmp r2, #0x0
	bne.w .L08038ef6
	movs r2, #0xff
	strb r2, [r6, #0x0]
	b.n .L080376f0
.L080376dc:
	cmp r2, #0xff
	bne.n .L080376f0
	movs r3, #0x1
	movs r2, #0xff
	movs r1, #0x0
	str r3, [sp, #0x68]
	cmp r5, #0x0
	bne.n .L080376a6
	b.w .L08038edc
.L080376f0:
	movs r1, #0x0
	str r1, [sp, #0x68]
	movs r1, #0x80
.L080376f6:
	ldrb.w r3, [r9], #0x1
	lsls r4, r4, #0x1
	tst r2, r1
	it ne
	addne r4, #0x1
	cmp r3, #0x0
	lsr.w r1, r1, #0x1
	beq.n .L0803769e
	str r2, [sp, #0x58]
	add.w r2, r8, r3
	strd r5, r9, [sp, #0x60]
	add.w r12, r7, r3, lsl #0x1
	mov lr, r8
	str r2, [sp, #0x54]
	sub.w r9, r3, #0x3
	sub.w r8, r3, #0x2
	sub.w r11, r3, #0x1
	movs r2, #0x0
.L0803772a:
	ldrh.w r5, [r7, r2, lsl #0x1]
	cmp r4, r5
	beq.n .L08037762
	cmp r11, r2
	beq.n .L08037690
	add.w r10, r7, r2, lsl #0x1
	ldrh.w r5, [r10, #0x2]
	cmp r4, r5
	beq.n .L08037766
	cmp r8, r2
	beq.n .L08037690
	ldrh.w r5, [r10, #0x4]
	cmp r4, r5
	beq.n .L0803776c
	cmp r9, r2
	beq.n .L08037690
	ldrh.w r5, [r10, #0x6]
	cmp r4, r5
	beq.n .L08037772
	adds r2, #0x4
	cmp r3, r2
	bne.n .L0803772a
	b.n .L08037690
.L08037762:
	add r2, lr
	b.n .L08037776
.L08037766:
	add r2, lr
	adds r2, #0x1
	b.n .L08037776
.L0803776c:
	add r2, lr
	adds r2, #0x2
	b.n .L08037776
.L08037772:
	add r2, lr
	adds r2, #0x3
.L08037776:
	ldr r3, [sp, #0x5c]
	strb r1, [r3, #0xc]
	strd r0, r6, [r3, #0x0]
	ldrb.w r9, [r2, #0x0]
	ldr r2, [sp, #0x50]
	cmp.w r9, #0x0
	add.w r11, r3, r2, lsl #1
	ldrsh.w r4, [r11, #0x14]!
	beq.n .L08037830
	ldrb r2, [r6, #0x0]
	mov.w r8, #0x0
	mov r7, r9
	movs r5, #0x0
	b.n .L080377b8
	.byte 0x00, 0xbf	@ padding
.L080377a0:
	mov r3, r1
	mov r1, r5
.L080377a4:
	mov r5, r1
	lsl.w r8, r8, #0x1
	lsrs r1, r3, #0x1
	subs r7, #0x1
	tst r2, r3
	it ne
	addne.w r8, r8, #0x1
	cbz r7, .L08037804
.L080377b8:
	cmp r1, #0x0
	bne.n .L080377a0
	cbz r0, .L080377c2
	adds r6, #0x1
	b.n .L080377d6
.L080377c2:
	ldr r0, [sp, #0x5c]
	mov.w r2, #0x200
	ldr r6, [r0, #0x8]
	ldr r3, [r0, #0x74]
	mov r1, r6
	blx r3
	cmp r0, #0x0
	beq.w .L08038ee0
.L080377d6:
	ldrb r2, [r6, #0x0]
	sub.w r0, r0, #0x1
	cbz r5, .L080377ec
	cmp r2, #0x0
	bne.w .L08038ed2
	movs r2, #0xff
	movs r1, #0x0
	strb r2, [r6, #0x0]
	b.n .L08037800
.L080377ec:
	cmp r2, #0xff
	mov.w r1, #0x0
	bne.n .L08037800
	movs r5, #0x1
	movs r2, #0xff
	cmp r7, #0x0
	bne.n .L080377b8
	b.n .L08037804
	.byte 0x00, 0xbf	@ padding
.L08037800:
	movs r3, #0x80
	b.n .L080377a4
.L08037804:
	ldr r2, [sp, #0x5c]
	cmp.w r8, #0x0
	strb r1, [r2, #0xc]
	str r0, [r2, #0x0]
	str r6, [r2, #0x4]
	bmi.w .L08037cfc
	sub.w r0, r9, #0x1
	mvn r1, #0x1
	lsls r1, r0
	add r4, r8
	lsr.w r0, r8, r0
	add r1, r4
	lsls r0, r0, #0x1f
	it eq
	addeq r4, r1, #0x1
	strh.w r4, [r11, #0x0]
.L08037830:
	ldr.w r11, [sp, #0x5c]
	ldr r0, [sp, #0x50]
	add r0, r11
	ldrb r0, [r0, #0x10]
	add.w r0, r11, r0, lsl #0x2
	ldr r1, [r0, #0x54]
	ldr r0, [r1, #0x0]
	str r1, [sp, #0x34]
	muls r0, r4, r0
	ldr r1, [sp, #0x3c]
	asrs r0, r0, #0x8
	str r0, [r1, #0x0]
	ldr r0, [sp, #0x38]
	movs r1, #0xfc
	bl zero_bytes_aligned
	ldr r1, [sp, #0x44]
	mov.w r9, #0x1
	ldr r0, [r1, #0x28]
	str r0, [sp, #0x4c]
	ldr r0, [r1, #0x38]
	str r0, [sp, #0x48]
	ldr r0, [r1, #0x48]
	ldrb.w r1, [r11, #0xc]
	str r0, [sp, #0x44]
	ldrd r0, r6, [r11, #0x0]
.L0803786e:
	str.w r9, [sp, #0x50]
	ldrb r2, [r6, #0x0]
	ldr.w r8, [sp, #0x4c]
	ldrd r9, r7, [sp, #0x44]
	movs r4, #0x10
	movs r5, #0x0
	movs r3, #0x0
	str r3, [sp, #0x68]
	b.n .L0803789c
	.byte 0x00, 0xbf	@ padding
.L08037888:
	ldr r4, [sp, #0x64]
	ldrd r11, r8, [sp, #0x5c]
	ldrd r9, r2, [sp, #0x54]
	mov r7, r12
.L08037894:
	subs r4, #0x1
	cmp r4, #0x0
	beq.w .L08038ec4
.L0803789c:
	cbnz r1, .L080378ee
	cbz r0, .L080378a4
	adds r6, #0x1
	b.n .L080378bc
.L080378a4:
	ldr.w r6, [r11, #0x8]
	ldr.w r3, [r11, #0x74]
	mov r0, r11
	mov r1, r6
	mov.w r2, #0x200
	blx r3
	cmp r0, #0x0
	beq.w .L08038ef2
.L080378bc:
	ldr r1, [sp, #0x68]
	ldrb r2, [r6, #0x0]
	sub.w r0, r0, #0x1
	cbz r1, .L080378d2
	cmp r2, #0x0
	bne.w .L08038eea
	movs r2, #0xff
	strb r2, [r6, #0x0]
	b.n .L080378e8
.L080378d2:
	cmp r2, #0xff
	bne.n .L080378e8
	movs r3, #0x1
	movs r2, #0xff
	movs r1, #0x0
	str r3, [sp, #0x68]
	cmp r4, #0x0
	bne.n .L0803789c
	b.w .L08038ec4
	.byte 0x00, 0xbf	@ padding
.L080378e8:
	movs r1, #0x0
	str r1, [sp, #0x68]
	movs r1, #0x80
.L080378ee:
	ldrb.w r3, [r8], #0x1
	lsls r5, r5, #0x1
	tst r2, r1
	it ne
	addne r5, #0x1
	cmp r3, #0x0
	lsr.w r1, r1, #0x1
	beq.n .L08037894
	str r2, [sp, #0x58]
	add.w r2, r9, r3
	strd r8, r4, [sp, #0x60]
	add.w r12, r7, r3, lsl #0x1
	mov lr, r9
	str r2, [sp, #0x54]
	sub.w r11, r3, #0x3
	sub.w r9, r3, #0x2
	sub.w r8, r3, #0x1
	movs r2, #0x0
.L08037922:
	ldrh.w r4, [r7, r2, lsl #0x1]
	cmp r5, r4
	beq.n .L0803795a
	cmp r8, r2
	beq.n .L08037888
	add.w r10, r7, r2, lsl #0x1
	ldrh.w r4, [r10, #0x2]
	cmp r5, r4
	beq.n .L0803795e
	cmp r9, r2
	beq.n .L08037888
	ldrh.w r4, [r10, #0x4]
	cmp r5, r4
	beq.n .L08037964
	cmp r11, r2
	beq.n .L08037888
	ldrh.w r4, [r10, #0x6]
	cmp r5, r4
	beq.n .L0803796a
	adds r2, #0x4
	cmp r3, r2
	bne.n .L08037922
	b.n .L08037888
.L0803795a:
	add r2, lr
	b.n .L0803796e
.L0803795e:
	add r2, lr
	adds r2, #0x1
	b.n .L0803796e
.L08037964:
	add r2, lr
	adds r2, #0x2
	b.n .L0803796e
.L0803796a:
	add r2, lr
	adds r2, #0x3
.L0803796e:
	ldr.w r11, [sp, #0x5c]
	ldr.w r9, [sp, #0x50]
	strb.w r1, [r11, #0xc]
	strd r0, r6, [r11, #0x0]
	ldrb r2, [r2, #0x0]
	cmp r2, #0x0
	beq.n .L08037a68
	movs r3, #0x0
	cmp.w r3, r2, lsr #0x4
	beq.n .L08037998
	lsrs r3, r2, #0x4
	add r9, r3
	cmp.w r9, #0x3f
	bhi.w .L08038eee
.L08037998:
	ands.w r4, r2, #0xf
	beq.n .L08037a5c
	ldrb r2, [r6, #0x0]
	mov.w r8, #0x0
	mov r5, r4
	movs r7, #0x0
	b.n .L080379c4
	.byte 0x00, 0xbf	@ padding
.L080379ac:
	mov r3, r1
	mov r1, r7
.L080379b0:
	mov r7, r1
	lsl.w r8, r8, #0x1
	lsrs r1, r3, #0x1
	subs r5, #0x1
	tst r2, r3
	it ne
	addne.w r8, r8, #0x1
	cbz r5, .L08037a14
.L080379c4:
	cmp r1, #0x0
	bne.n .L080379ac
	cbz r0, .L080379ce
	adds r6, #0x1
	b.n .L080379e6
.L080379ce:
	ldr.w r6, [r11, #0x8]
	ldr.w r3, [r11, #0x74]
	mov r0, r11
	mov r1, r6
	mov.w r2, #0x200
	blx r3
	cmp r0, #0x0
	beq.w .L08038ec8
.L080379e6:
	ldrb r2, [r6, #0x0]
	sub.w r0, r0, #0x1
	cbz r7, .L080379fc
	cmp r2, #0x0
	bne.w .L08038eba
	movs r2, #0xff
	movs r1, #0x0
	strb r2, [r6, #0x0]
	b.n .L08037a10
.L080379fc:
	cmp r2, #0xff
	mov.w r1, #0x0
	bne.n .L08037a10
	movs r7, #0x1
	movs r2, #0xff
	cmp r5, #0x0
	bne.n .L080379c4
	b.n .L08037a14
	.byte 0x00, 0xbf	@ padding
.L08037a10:
	movs r3, #0x80
	b.n .L080379b0
.L08037a14:
	cmp.w r8, #0x0
	strb.w r1, [r11, #0xc]
	str.w r0, [r11, #0x0]
	str.w r6, [r11, #0x4]
	bmi.w .L08037d00
	subs r2, r4, #0x1
	mvn r3, #0x1
	lsls r3, r2
	lsr.w r2, r8, r2
	movw r7, #:lower16:d_0806ee74
	movt r7, #:upper16:d_0806ee74
	lsls r2, r2, #0x1f
	ldrb.w r7, [r7, r9]
	ldr r2, [sp, #0x34]
	add r3, r8
	ldr.w r2, [r2, r7, lsl #0x2]
	it eq
	addeq.w r8, r3, #0x1
	mul r2, r2, r8
	ldr r3, [sp, #0x3c]
	asrs r2, r2, #0x8
	str.w r2, [r3, r7, lsl #0x2]
.L08037a5c:
	add.w r9, r9, #0x1
	cmp.w r9, #0x40
	bcc.w .L0803786e
.L08037a68:
	ldrb.w r0, [r11, #0xd]
	cmp r0, #0x3
	bne.n .L08037a86
	ldr r0, [sp, #0x3c]
	ldr r0, [r0, #0x0]
	asrs r1, r0, #0x1f
	add.w r0, r0, r1, lsr #0x18
	movs r1, #0x80
	eor.w r0, r1, r0, lsr #0x8
	ldr r1, [sp, #0x40]
	strb r0, [r1, #0x0]
	b.n .L08037ce0
.L08037a86:
	ldr r0, [sp, #0x1c]
	mov.w r10, #0x8
.L08037a8c:
	ldr r2, [r0, #0x60]
	ldr.w r3, [r0, #0xa0]
	ldr.w r7, [r0, #0xe0]
	ldr r6, [r0, #0x20]
	mov.w r9, #0x16a0
	adds r4, r3, r6
	subs r3, r6, r3
	subs r6, r2, r7
	mul r6, r6, r9
	add r2, r7
	rsb r7, r2, r6, asr #0xc
	ldr r5, [r0, #0x40]
	adds r6, r2, r4
	sub.w lr, r4, r2
	adds r4, r7, r3
	sub.w r8, r3, r7
	ldr.w r7, [r0, #0x100]
	ldr.w r1, [r0, #0xc0]
	ldr.w r2, [r0, #0x80]
	subs r3, r5, r7
	add r5, r7
	subs r7, r1, r2
	add r1, r2
	sub.w r12, r5, r1
	add r1, r5
	adds r5, r7, r3
	movw r11, #0x1d90
	movw r2, #0x1151
	mul r5, r5, r11
	muls r3, r2, r3
	movw r2, #0x29cf
	asrs r5, r5, #0xc
	muls r7, r2, r7
	sub.w r3, r5, r3, asr #0xc
	sub.w r5, r5, r7, asr #0xc
	adds r7, r1, r6
	subs r5, r5, r1
	subs r1, r6, r1
	mul r2, r12, r9
	str.w r1, [r0, #0x100]
	adds r1, r5, r4
	rsb r2, r5, r2, asr #0xc
	str r1, [r0, #0x40]
	subs r1, r4, r5
	str.w r1, [r0, #0xe0]
	add.w r1, r2, r8
	subs r3, r3, r2
	str r1, [r0, #0x60]
	sub.w r1, r8, r2
	str.w r1, [r0, #0xc0]
	add.w r1, r3, lr
	str.w r1, [r0, #0x80]
	sub.w r1, lr, r3
	str r7, [r0, #0x20]
	ldr r7, [r0, #0x24]
	str.w r1, [r0, #0xa0]
	ldr r1, [r0, #0x64]
	ldr.w r2, [r0, #0xa4]
	ldr.w r3, [r0, #0xe4]
	adds r5, r2, r7
	subs r7, r7, r2
	subs r2, r1, r3
	mul r2, r2, r9
	add r1, r3
	rsb r3, r1, r2, asr #0xc
	ldr r6, [r0, #0x44]
	adds r4, r1, r5
	sub.w lr, r5, r1
	adds r1, r3, r7
	sub.w r8, r7, r3
	ldr.w r7, [r0, #0x104]
	ldr.w r5, [r0, #0xc4]
	ldr.w r2, [r0, #0x84]
	subs r3, r6, r7
	add r6, r7
	subs r7, r5, r2
	add r2, r5
	sub.w r12, r6, r2
	add r2, r6
	adds r6, r7, r3
	movw r5, #0x1151
	mul r6, r6, r11
	muls r3, r5, r3
	movw r5, #0x29cf
	asrs r6, r6, #0xc
	muls r7, r5, r7
	sub.w r3, r6, r3, asr #0xc
	sub.w r6, r6, r7, asr #0xc
	adds r7, r2, r4
	subs r6, r6, r2
	subs r2, r4, r2
	str.w r2, [r0, #0x104]
	adds r2, r6, r1
	str r2, [r0, #0x44]
	mul r2, r12, r9
	rsb r2, r6, r2, asr #0xc
	subs r1, r1, r6
	str.w r1, [r0, #0xe4]
	add.w r1, r2, r8
	str r1, [r0, #0x64]
	subs r1, r3, r2
	sub.w r2, r8, r2
	str.w r2, [r0, #0xc4]
	add.w r2, r1, lr
	sub.w r1, lr, r1
	str r7, [r0, #0x24]
	str.w r2, [r0, #0x84]
	str.w r1, [r0, #0xa4]
	subs.w r10, r10, #0x2
	add.w r0, r0, #0x8
	bne.w .L08037a8c
	movs r1, #0x0
	nop
.L08037be0:
	ldr.w r2, [r0, r1, lsl #0x2]
	add.w r3, r0, r1, lsl #0x2
	ldrd lr, r6, [r3, #0x4]
	ldrd r9, r4, [r3, #0xc]
	ldrd r8, r7, [r3, #0x14]
	add.w r2, r2, #0x8000
	ldr.w r12, [r3, #0x1c]
	adds r5, r4, r2
	subs r4, r2, r4
	subs r2, r6, r7
	mov.w r3, #0x16a0
	muls r2, r3, r2
	add r6, r7
	rsb r7, r6, r2, asr #0xc
	subs r3, r5, r6
	adds r2, r6, r5
	str r3, [sp, #0x68]
	add.w r11, r7, r4
	sub.w r10, r4, r7
	sub.w r7, lr, r12
	add.w r3, lr, r12
	sub.w r5, r8, r9
	add.w r4, r9, r8
	sub.w r12, r3, r4
	add r3, r4
	adds r4, r5, r7
	movw r6, #0x1d90
	muls r4, r6, r4
	movw r6, #0x1151
	asrs r4, r4, #0xc
	muls r7, r6, r7
	sub.w lr, r4, r7, asr #0xc
	movw r7, #0x29cf
	muls r5, r7, r5
	sub.w r4, r4, r5, asr #0xc
	adds r7, r3, r2
	movw r8, #:lower16:d_0806ef34
	subs r4, r4, r3
	ubfx r7, r7, #0x8, #0xa
	movt r8, #:upper16:d_0806ef34
	subs r2, r2, r3
	add.w r3, r4, r11
	ldrb.w r7, [r8, r7]
	ldr r5, [sp, #0x40]
	ubfx r3, r3, #0x8, #0xa
	ubfx r2, r2, #0x8, #0xa
	ldrb.w r3, [r8, r3]
	strb r7, [r5, r1]
	adds r7, r5, r1
	ldrb.w r2, [r8, r2]
	strb r3, [r7, #0x1]
	sub.w r3, r11, r4
	strb r2, [r7, #0x7]
	mov.w r2, #0x16a0
	ubfx r3, r3, #0x8, #0xa
	mul r2, r12, r2
	ldrb.w r3, [r8, r3]
	rsb r2, r4, r2, asr #0xc
	add.w r6, r2, r10
	strb r3, [r7, #0x6]
	sub.w r3, lr, r2
	sub.w r2, r10, r2
	ubfx r6, r6, #0x8, #0xa
	ubfx r2, r2, #0x8, #0xa
	ldrb.w r6, [r8, r6]
	ldrb.w r2, [r8, r2]
	ldr r5, [sp, #0x68]
	strb r6, [r7, #0x2]
	adds r6, r3, r5
	strb r2, [r7, #0x5]
	subs r2, r5, r3
	ubfx r6, r6, #0x8, #0xa
	ubfx r2, r2, #0x8, #0xa
	ldrb.w r6, [r8, r6]
	ldrb.w r2, [r8, r2]
	adds r1, #0x8
	cmp r1, #0x40
	strb r6, [r7, #0x3]
	strb r2, [r7, #0x4]
	bne.w .L08037be0
.L08037ce0:
	ldr r3, [sp, #0x40]
	ldr r0, [sp, #0x20]
	ldr r1, [sp, #0x30]
	ldr.w r11, [sp, #0x5c]
	ldrd r6, r7, [sp, #0x24]
	adds r3, #0x40
	cmp r1, r0
	add.w r0, r1, #0x1
	bne.w .L08037654
	b.n .L08037d08
.L08037cfc:
	ldr.w r11, [sp, #0x5c]
.L08037d00:
	lsls.w r0, r8, #0x18
	bne.w .L08038f0e
.L08037d08:
	ldrb.w r0, [r11, #0xe]
	ldr r6, [sp, #0x2c]
	lsl.w r10, r0, #0x3
	str r0, [sp, #0x50]
	add.w r3, r6, r0, lsl #0x3
	ldrd r0, r7, [r11, #0x1c]
	mov r5, r10
	ldrb.w r2, [r11, #0xd]
	ldrb.w r1, [r11, #0xf]
	cmp r3, r0
	it hi
	subhi r5, r0, r6
	ldr r6, [sp, #0x18]
	lsls r4, r1, #0x3
	add.w r3, r6, r1, lsl #0x3
	cmp r3, r7
	mov r3, r4
	it hi
	subhi r3, r7, r6
	lsrs.w r7, r5, r2
	it ne
	lsrsne.w r5, r3, r2
	bne.n .L08037d56
	ldr r5, [sp, #0xc]
	ldrd r3, r10, [sp, #0x4]
	mov.w r8, #0x1
	b.w .L08038e8e
.L08037d56:
	ldr r0, [sp, #0x2c]
	lsr.w r3, r6, r2
	lsrs r0, r2
	strh.w r0, [sp, #0x6c]
	add r0, r7
	subs r0, #0x1
	strh.w r0, [sp, #0x6e]
	adds r0, r5, r3
	subs r0, #0x1
	cmp r2, #0x3
	str r4, [sp, #0x30]
	str r7, [sp, #0x20]
	strh.w r3, [sp, #0x70]
	strh.w r0, [sp, #0x72]
	str r5, [sp, #0x24]
	bne.n .L08037e3c
	ldr r2, [sp, #0x30]
	cmp r1, #0x0
	mov.w r8, #0x1
	ldr r0, [sp, #0x50]
	it ne
	cmpne r0, #0x0
	beq.w .L08038afe
	ldr.w r0, [r11, #0x68]
	mul r1, r2, r10
	smlabb r2, r2, r10, r0
	ldrb r1, [r0, r1]
	ldrb.w r2, [r2, #0x40]
	sub.w r3, r1, #0x80
	subs r2, #0x80
	movw r1, #0x59b
	muls r1, r2, r1
	add.w r1, r1, r1, lsr #0x16
	asr.w lr, r1, #0xa
	movw r1, #0x2db
	muls r2, r1, r2
	mov.w r1, #0x160
	smlabb r2, r3, r1, r2
	add.w r2, r2, r2, lsr #0x16
	movs r1, #0x0
	sub.w r9, r1, r2, asr #0xa
	movw r1, #0x716
	muls r3, r1, r3
	add.w r3, r3, r3, lsr #0x16
	ldr.w r7, [r11, #0x64]
	asrs r3, r3, #0xa
	mov.w r12, #0x0
.L08037de4:
	movw r2, #:lower16:d_0806ef34
	movs r5, #0x0
	movt r2, #:upper16:d_0806ef34
	cmp.w r12, #0x8
	it eq
	addeq r0, #0x80
	nop
.L08037df8:
	ldrb.w r4, [r0, r5, lsl #0x3]
	adds r5, #0x8
	add.w r6, lr, r4
	bfc r6, #0xa, #0x16
	add.w r1, r9, r4
	ldrb r6, [r2, r6]
	bfc r1, #0xa, #0x16
	ldrb r1, [r2, r1]
	strb.w r6, [r7], #0x3
	strb.w r1, [r7, #-0x2]
	adds r1, r3, r4
	bfc r1, #0xa, #0x16
	ldrb r1, [r2, r1]
	cmp r5, r10
	strb.w r1, [r7, #-0x1]
	bcc.n .L08037df8
	ldr r0, [sp, #0x30]
	add.w r12, r12, #0x8
	cmp r12, r0
	bcs.w .L08038afe
	ldr.w r0, [r11, #0x68]
	b.n .L08037de4
.L08037e3c:
	ldr r3, [sp, #0x50]
	cmp r1, #0x0
	mov.w r8, #0x1
	beq.w .L08038afe
	ldr.w r0, [r11, #0x64]
	cmp r3, #0x0
	str r0, [sp, #0x68]
	mov r0, r10
	it eq
	moveq r0, #0x1
	subs r2, r0, #0x1
	str r2, [sp, #0x48]
	and.w r2, r0, #0x1
	str r2, [sp, #0x44]
	cmp r1, #0x2
	bic r2, r0, #0x7
	str.w r10, [sp, #0x4c]
	str r2, [sp, #0x64]
	bne.w .L0803837a
	movw r7, #:lower16:d_0806ef34
	movs r6, #0x0
	mov.w r4, #0x100
	movt r7, #:upper16:d_0806ef34
	movw r12, #0x59b
	movw r8, #0x2db
	b.n .L08037eb4
.L08037e88:
	add.w r1, r1, r1, lsr #0x16
	add.w r1, r2, r1, lsr #0xa
	bfc r1, #0xa, #0x16
	ldrb r1, [r7, r1]
	strb.w r0, [r5, #-0x2]
	mov r0, r5
	str r5, [sp, #0x68]
	strb.w r1, [r5, #-0x1]
.L08037ea2:
	ldr r6, [sp, #0x58]
	ldr r0, [sp, #0x30]
	ldr r4, [sp, #0x54]
	adds r6, #0x1
	cmp r6, r0
	add.w r4, r4, #0x4
	beq.w .L080387e6
.L08037eb4:
	ldr.w r0, [r11, #0x68]
	cmp r6, #0x7
	add.w r9, r0, r6, lsl #0x3
	it hi
	addhi.w r9, r9, #0x40
	cmp r3, #0x0
	strd r4, r6, [sp, #0x54]
	beq.n .L08037ea2
	mov.w r1, #0x100
	add.w r1, r1, r6, lsl #0x2
	bic r1, r1, #0x4
	cmp r3, #0x2
	add.w r5, r0, r1
	bne.w .L08038120
	ldr r0, [sp, #0x48]
	movs r6, #0x0
	cmp r0, #0x3
	blo.w .L080380c4
	ldr.w lr, [sp, #0x68]
	str.w lr, [sp, #0x68]
.L08037ef4:
	ldrb.w r0, [r5, #0x40]
	cmp r6, #0x8
	sub.w r0, r0, #0x80
	it eq
	addeq.w r9, r9, #0x38
	movw r10, #0x59b
	ldrb.w r3, [r9], #0x4
	mul r2, r0, r10
	add.w r2, r2, r2, lsr #0x16
	add.w r2, r3, r2, lsr #0xa
	bfc r2, #0xa, #0x16
	ldrb r2, [r7, r2]
	ldrb r7, [r5, #0x0]
	ldr r4, [sp, #0x68]
	add.w r1, r6, r6, lsl #0x1
	strb r2, [r4, r1]
	adds r2, r4, r1
	sub.w r1, r7, #0x80
	mul r0, r0, r8
	mov.w r11, #0x160
	movw r12, #0x716
	smlabb r0, r1, r11, r0
	mul r1, r1, r12
	add.w r0, r0, r0, lsr #0x16
	add.w r1, r1, r1, lsr #0x16
	sub.w r0, r3, r0, lsr #0xa
	movw r7, #:lower16:d_0806ef34
	add.w r1, r3, r1, lsr #0xa
	movw r3, #:lower16:d_0806ef34
	bfc r0, #0xa, #0x16
	movt r7, #:upper16:d_0806ef34
	bfc r1, #0xa, #0x16
	movt r3, #:upper16:d_0806ef34
	ldrb r0, [r7, r0]
	ldrb r1, [r3, r1]
	strb r0, [r2, #0x1]
	strb r1, [r2, #0x2]
	ldrb.w r0, [r5], #0x2
	ldrb.w r3, [r9, #-0x3]
	ldrb.w r1, [r5, #0x3e]
	movw r4, #:lower16:d_0806ef34
	subs r1, #0x80
	mul r7, r1, r10
	add.w r7, r7, r7, lsr #0x16
	add.w r7, r3, r7, lsr #0xa
	bfc r7, #0xa, #0x16
	movt r4, #:upper16:d_0806ef34
	subs r0, #0x80
	mul r1, r1, r8
	ldrb r7, [r4, r7]
	smlabb r1, r0, r11, r1
	mul r0, r0, r12
	add.w r1, r1, r1, lsr #0x16
	add.w r0, r0, r0, lsr #0x16
	strb r7, [r2, #0x3]
	sub.w r1, r3, r1, lsr #0xa
	movw r7, #:lower16:d_0806ef34
	add.w r0, r3, r0, lsr #0xa
	movw r3, #:lower16:d_0806ef34
	bfc r1, #0xa, #0x16
	movt r7, #:upper16:d_0806ef34
	bfc r0, #0xa, #0x16
	movt r3, #:upper16:d_0806ef34
	ldrb r1, [r7, r1]
	ldrb r0, [r3, r0]
	strb r1, [r2, #0x4]
	strb r0, [r2, #0x5]
	ldrb.w r0, [r5, #0x3f]
	ldrb.w r3, [r9, #-0x2]
	subs r0, #0x80
	mul r7, r0, r10
	ldrb.w r1, [r5, #-0x1]
	add.w r7, r7, r7, lsr #0x16
	add.w r7, r3, r7, lsr #0xa
	movw r4, #:lower16:d_0806ef34
	bfc r7, #0xa, #0x16
	movt r4, #:upper16:d_0806ef34
	subs r1, #0x80
	mul r0, r0, r8
	ldrb r7, [r4, r7]
	smlabb r0, r1, r11, r0
	mul r1, r1, r12
	add.w r0, r0, r0, lsr #0x16
	add.w r1, r1, r1, lsr #0x16
	strb r7, [r2, #0x6]
	sub.w r0, r3, r0, lsr #0xa
	movw r7, #:lower16:d_0806ef34
	add.w r1, r3, r1, lsr #0xa
	movw r3, #:lower16:d_0806ef34
	bfc r0, #0xa, #0x16
	movt r7, #:upper16:d_0806ef34
	bfc r1, #0xa, #0x16
	movt r3, #:upper16:d_0806ef34
	ldrb r0, [r7, r0]
	ldrb r1, [r3, r1]
	strb r0, [r2, #0x7]
	strb r1, [r2, #0x8]
	ldrb.w r0, [r5, #0x3f]
	ldrb.w r1, [r9, #-0x1]
	subs r0, #0x80
	mul r3, r0, r10
	add.w r3, r3, r3, lsr #0x16
	add.w r3, r1, r3, lsr #0xa
	movw r7, #:lower16:d_0806ef34
	bfc r3, #0xa, #0x16
	movt r7, #:upper16:d_0806ef34
	ldrb r3, [r7, r3]
	ldrb.w r7, [r5, #-0x1]
	strb r3, [r2, #0x9]
	sub.w r3, r7, #0x80
	mul r0, r0, r8
	smlabb r0, r3, r11, r0
	mul r3, r3, r12
	add.w r0, r0, r0, lsr #0x16
	add.w r3, r3, r3, lsr #0x16
	movw r7, #:lower16:d_0806ef34
	sub.w r0, r1, r0, lsr #0xa
	add.w r1, r1, r3, lsr #0xa
	movt r7, #:upper16:d_0806ef34
	bfc r1, #0xa, #0x16
	ldrb r1, [r7, r1]
	bfc r0, #0xa, #0x16
	ldrb r0, [r7, r0]
	strb r1, [r2, #0xb]
	ldr r1, [sp, #0x64]
	adds r6, #0x4
	strb r0, [r2, #0xa]
	mov r0, lr
	cmp r1, r6
	add.w lr, r2, #0xc
	bne.w .L08037ef4
	adds r0, #0xc
	ldr.w r11, [sp, #0x5c]
	ldrd r10, r3, [sp, #0x4c]
	str r0, [sp, #0x68]
	movw r12, #0x59b
.L080380c4:
	mov.w r4, #0x160
	movw lr, #0x716
	ldr r0, [sp, #0x44]
	cmp r0, #0x0
	beq.w .L08037ea2
	ldrb.w r0, [r5, #0x40]
	ldrb r1, [r5, #0x0]
	subs r0, #0x80
	cmp r6, #0x8
	it eq
	addeq.w r9, r9, #0x38
	ldrb.w r2, [r9, #0x0]
	mul r3, r0, r12
	add.w r3, r3, r3, lsr #0x16
	subs r1, #0x80
	mul r0, r0, r8
	add.w r3, r2, r3, lsr #0xa
	smlabb r0, r1, r4, r0
	bfc r3, #0xa, #0x16
	add.w r0, r0, r0, lsr #0x16
	ldrb r3, [r7, r3]
	ldr r5, [sp, #0x68]
	sub.w r0, r2, r0, lsr #0xa
	bfc r0, #0xa, #0x16
	strb.w r3, [r5], #0x3
	ldr r3, [sp, #0x50]
	ldrb r0, [r7, r0]
	mul r1, r1, lr
	b.n .L08037e88
.L08038120:
	ldr r1, [sp, #0x48]
	cmp r1, #0x3
	blo.w .L08038328
	bic r1, r4, #0x7
	ldr.w r11, [sp, #0x68]
	add r0, r1
	mov.w lr, #0x0
	str r0, [sp, #0x60]
	str.w r11, [sp, #0x68]
.L0803813c:
	ldr r0, [sp, #0x60]
	movw r8, #0x59b
	add.w r1, r0, lr
	ldrb.w r3, [r1, #0x40]
	ldrb.w r5, [r9, lr]
	subs r3, #0x80
	mul r7, r3, r8
	add.w r7, r7, r7, lsr #0x16
	add.w r7, r5, r7, lsr #0xa
	movw r4, #:lower16:d_0806ef34
	bfc r7, #0xa, #0x16
	movt r4, #:upper16:d_0806ef34
	ldr r6, [sp, #0x68]
	ldrb r7, [r4, r7]
	ldrb.w r12, [r0, lr]
	add.w r10, lr, lr, lsl #0x1
	movw r0, #0x2db
	add.w r2, r6, r10
	strb.w r7, [r6, r10]
	sub.w r7, r12, #0x80
	muls r3, r0, r3
	mov.w r6, #0x160
	smlabb r3, r7, r6, r3
	add.w r3, r3, r3, lsr #0x16
	movw r12, #0x716
	sub.w r3, r5, r3, lsr #0xa
	movw r0, #:lower16:d_0806ef34
	mul r7, r7, r12
	bfc r3, #0xa, #0x16
	movt r0, #:upper16:d_0806ef34
	add.w r7, r7, r7, lsr #0x16
	ldrb r3, [r0, r3]
	add.w r7, r5, r7, lsr #0xa
	movw r0, #:lower16:d_0806ef34
	bfc r7, #0xa, #0x16
	movt r0, #:upper16:d_0806ef34
	ldrb r7, [r0, r7]
	strb r3, [r2, #0x1]
	strb r7, [r2, #0x2]
	ldrb.w r3, [r1, #0x41]
	add.w r10, r9, lr
	subs r3, #0x80
	ldrb.w r5, [r10, #0x1]
	mul r0, r3, r8
	add.w r0, r0, r0, lsr #0x16
	add.w r0, r5, r0, lsr #0xa
	movw r4, #:lower16:d_0806ef34
	bfc r0, #0xa, #0x16
	movt r4, #:upper16:d_0806ef34
	ldrb r7, [r1, #0x1]
	ldrb r0, [r4, r0]
	movw r4, #0x2db
	subs r7, #0x80
	strb r0, [r2, #0x3]
	mul r0, r3, r4
	smlabb r0, r7, r6, r0
	add.w r0, r0, r0, lsr #0x16
	sub.w r0, r5, r0, lsr #0xa
	movw r3, #:lower16:d_0806ef34
	bfc r0, #0xa, #0x16
	movt r3, #:upper16:d_0806ef34
	ldrb r0, [r3, r0]
	mul r3, r7, r12
	add.w r3, r3, r3, lsr #0x16
	add.w r3, r5, r3, lsr #0xa
	movw r7, #:lower16:d_0806ef34
	bfc r3, #0xa, #0x16
	movt r7, #:upper16:d_0806ef34
	ldrb r3, [r7, r3]
	strb r0, [r2, #0x4]
	strb r3, [r2, #0x5]
	ldrb.w r0, [r1, #0x42]
	ldrb.w r3, [r10, #0x2]
	subs r0, #0x80
	mul r7, r0, r8
	add.w r7, r7, r7, lsr #0x16
	add.w r7, r3, r7, lsr #0xa
	movw r5, #:lower16:d_0806ef34
	bfc r7, #0xa, #0x16
	movt r5, #:upper16:d_0806ef34
	ldrb r7, [r5, r7]
	ldrb r5, [r1, #0x2]
	strb r7, [r2, #0x6]
	sub.w r7, r5, #0x80
	muls r0, r4, r0
	smlabb r0, r7, r6, r0
	mul r7, r7, r12
	add.w r0, r0, r0, lsr #0x16
	add.w r7, r7, r7, lsr #0x16
	sub.w r0, r3, r0, lsr #0xa
	add.w r3, r3, r7, lsr #0xa
	movw r7, #:lower16:d_0806ef34
	bfc r0, #0xa, #0x16
	movt r7, #:upper16:d_0806ef34
	ldrb r0, [r7, r0]
	movw r7, #:lower16:d_0806ef34
	bfc r3, #0xa, #0x16
	movt r7, #:upper16:d_0806ef34
	ldrb r3, [r7, r3]
	strb r0, [r2, #0x7]
	strb r3, [r2, #0x8]
	ldrb.w r0, [r1, #0x43]
	ldrb.w r3, [r10, #0x3]
	subs r0, #0x80
	mul r7, r0, r8
	add.w r7, r7, r7, lsr #0x16
	ldrb r1, [r1, #0x3]
	movw r4, #0x2db
	add.w r7, r3, r7, lsr #0xa
	movw r5, #:lower16:d_0806ef34
	bfc r7, #0xa, #0x16
	movt r5, #:upper16:d_0806ef34
	subs r1, #0x80
	muls r0, r4, r0
	ldrb r7, [r5, r7]
	smlabb r0, r1, r6, r0
	mul r1, r1, r12
	add.w r1, r1, r1, lsr #0x16
	strb r7, [r2, #0x9]
	movw r7, #:lower16:d_0806ef34
	add.w r1, r3, r1, lsr #0xa
	movt r7, #:upper16:d_0806ef34
	add.w r0, r0, r0, lsr #0x16
	bfc r1, #0xa, #0x16
	sub.w r0, r3, r0, lsr #0xa
	ldrb r1, [r7, r1]
	bfc r0, #0xa, #0x16
	ldrb r0, [r7, r0]
	strb r1, [r2, #0xb]
	ldr r1, [sp, #0x64]
	add.w lr, lr, #0x4
	strb r0, [r2, #0xa]
	mov r0, r11
	cmp r1, lr
	add.w r11, r2, #0xc
	bne.w .L0803813c
	adds r0, #0xc
	str r0, [sp, #0x68]
	ldr r0, [sp, #0x60]
	ldr.w r11, [sp, #0x5c]
	ldrd r10, r3, [sp, #0x4c]
	add.w r5, r0, lr
	add r9, lr
	movw r12, #0x59b
	movw r8, #0x2db
.L08038328:
	mov.w r6, #0x160
	movw r4, #0x716
	ldr r0, [sp, #0x44]
	cmp r0, #0x0
	beq.w .L08037ea2
	ldrb.w r0, [r5, #0x40]
	ldrb r1, [r5, #0x0]
	subs r0, #0x80
	ldrb.w r2, [r9, #0x0]
	mul r3, r0, r12
	add.w r3, r3, r3, lsr #0x16
	subs r1, #0x80
	mul r0, r0, r8
	add.w r3, r2, r3, lsr #0xa
	smlabb r0, r1, r6, r0
	bfc r3, #0xa, #0x16
	add.w r0, r0, r0, lsr #0x16
	ldrb r3, [r7, r3]
	ldr r5, [sp, #0x68]
	sub.w r0, r2, r0, lsr #0xa
	bfc r0, #0xa, #0x16
	strb.w r3, [r5], #0x3
	ldr r3, [sp, #0x50]
	ldrb r0, [r7, r0]
	muls r1, r4, r1
	b.n .L08037e88
.L0803837a:
	lsl.w r12, r3, #0x6
	mov.w r9, #0x0
	mov r2, r12
	movs r4, #0x0
	movw lr, #0x59b
	str.w r12, [sp, #0x38]
	b.n .L08038404
.L08038390:
	ldrb r5, [r5, #0x0]
	mul r3, r0, lr
	add.w r3, r3, r3, lsr #0x16
	add.w r3, r5, r3, lsr #0xa
	movw r7, #:lower16:d_0806ef34
	bfc r3, #0xa, #0x16
	movt r7, #:upper16:d_0806ef34
	ldrb r3, [r7, r3]
	ldr r6, [sp, #0x68]
	movw r8, #0x2db
	subs r1, #0x80
	strb.w r3, [r6], #0x3
	mul r0, r0, r8
	mov.w r3, #0x160
	smlabb r0, r1, r3, r0
	movw r3, #0x716
	muls r1, r3, r1
	add.w r0, r0, r0, lsr #0x16
	add.w r1, r1, r1, lsr #0x16
	sub.w r0, r5, r0, lsr #0xa
	add.w r1, r5, r1, lsr #0xa
	bfc r0, #0xa, #0x16
	bfc r1, #0xa, #0x16
	ldrb r0, [r7, r0]
	ldr r3, [sp, #0x50]
	ldrb r1, [r7, r1]
	strb.w r0, [r6, #-0x2]
	mov r0, r6
	str r6, [sp, #0x68]
	strb.w r1, [r6, #-0x1]
.L080383f4:
	ldr r0, [sp, #0x30]
	adds r4, #0x1
	adds r2, #0x8
	cmp r4, r0
	add.w r9, r9, #0x8
	beq.w .L080387e6
.L08038404:
	cmp r3, #0x0
	beq.n .L080383f4
	ldr.w r0, [r11, #0x68]
	add.w r1, r12, r4, lsl #0x3
	add.w r5, r0, r4, lsl #0x3
	cmp r3, #0x2
	add.w r6, r0, r1
	bne.n .L0803842a
	ldr r0, [sp, #0x48]
	cmp r0, #0x3
	bcs.w .L08038612
	mov.w r8, #0x0
	b.n .L080387cc
.L0803842a:
	ldr r1, [sp, #0x48]
	cmp r1, #0x3
	blo.w .L08038600
	ldr r6, [sp, #0x68]
	str.w r9, [sp, #0x54]
	add.w r1, r0, r9
	movw r9, #:lower16:d_0806ef34
	add r0, r2
	movs r7, #0x0
	mov r8, r6
	movt r9, #:upper16:d_0806ef34
	str r4, [sp, #0x3c]
	str r1, [sp, #0x60]
	str r2, [sp, #0x40]
	str r0, [sp, #0x58]
.L08038452:
	ldr r2, [sp, #0x58]
	ldr.w r11, [sp, #0x60]
	add.w r12, r2, r7
	ldrb.w r3, [r12, #0x40]
	ldrb.w r4, [r11, r7]
	subs r3, #0x80
	mul r5, r3, lr
	add.w r5, r5, r5, lsr #0x16
	add.w r5, r4, r5, lsr #0xa
	bfc r5, #0xa, #0x16
	ldrb.w r5, [r9, r5]
	ldrb.w r10, [r2, r7]
	add.w r0, r7, r7, lsl #0x1
	movw r2, #0x2db
	adds r1, r6, r0
	strb r5, [r6, r0]
	add.w lr, r11, r7
	sub.w r0, r10, #0x80
	muls r3, r2, r3
	mov.w r10, #0x160
	movw r11, #0x716
	smlabb r3, r0, r10, r3
	mul r0, r0, r11
	add.w r3, r3, r3, lsr #0x16
	add.w r0, r0, r0, lsr #0x16
	sub.w r3, r4, r3, lsr #0xa
	add.w r0, r4, r0, lsr #0xa
	bfc r3, #0xa, #0x16
	bfc r0, #0xa, #0x16
	ldrb.w r3, [r9, r3]
	ldrb.w r0, [r9, r0]
	strb r3, [r1, #0x1]
	strb r0, [r1, #0x2]
	ldrb.w r0, [r12, #0x41]
	ldrb.w r3, [r12, #0x1]
	movw r6, #0x59b
	subs r0, #0x80
	mul r5, r0, r6
	subs r3, #0x80
	muls r0, r2, r0
	ldrb.w r4, [lr, #0x1]
	smlabb r0, r3, r10, r0
	mul r3, r3, r11
	add.w r5, r5, r5, lsr #0x16
	add.w r0, r0, r0, lsr #0x16
	add.w r3, r3, r3, lsr #0x16
	add.w r5, r4, r5, lsr #0xa
	sub.w r0, r4, r0, lsr #0xa
	add.w r3, r4, r3, lsr #0xa
	bfc r5, #0xa, #0x16
	bfc r0, #0xa, #0x16
	bfc r3, #0xa, #0x16
	ldrb.w r5, [r9, r5]
	ldrb.w r0, [r9, r0]
	ldrb.w r3, [r9, r3]
	strb r5, [r1, #0x3]
	strb r0, [r1, #0x4]
	strb r3, [r1, #0x5]
	ldrb.w r0, [r12, #0x42]
	.include "src/parts/decode_scan_data_to_rgb565_p2.inc"
