@ system_bring_up_p2.inc - part 2 of 4 of system_bring_up (0x0802ba52..0x0802ca54):
@ pixel-pair output loops (display data port at [r10], command port at [r8]),
@ SysTick setup / wait and the table-driven row output; included by part 1.
	ldr r0, [sp, #0x14]
	movs r1, #0x0
	ldrh r7, [r0, #0x0]
	and r0, r7, #0x1
	add.w r0, r0, r7, lsr #0x1
	mul r3, r4, r0
	ldr r0, [sp, #0x18]
	sub.w r3, r1, r3, lsl #0x1
	ldrsh.w r0, [r6, r0, lsl #0x3]
	uxth r2, r0
	uxtah lr, r7, r0
	strd r2, r0, [sp, #0x30]
	str.w r9, [sp, #0x2c]
	b.n .L0802ba9e
	.byte 0x00, 0xbf	@ padding
.L0802ba80:
	ldr.w r9, [sp, #0x2c]
.L0802ba84:
	adds r0, r3, #0x2
	lsls r2, r3, #0x1f
	it ne
	bicne r3, r0, #0x1
	ldr r1, [sp, #0x38]
	ldr.w r12, [sp, #0x3c]
	adds r1, #0x1
	sxth r0, r1
	cmp r9, r0
	ble.w .L0802bc80
.L0802ba9e:
	ldr r0, [sp, #0x34]
	str r1, [sp, #0x38]
	cmp lr, r0
	ble.n .L0802ba84
	uxtb.w r7, r12
	cmp r7, #0x0
	beq.n .L0802bb4a
	cmp r7, #0x1
	bne.w .L0802bbde
	uxth r7, r1
	lsrs r6, r7, #0x8
	uxtb r5, r1
	ldr r7, [sp, #0x30]
	movw r1, #:lower16:d_0804d799	@ own label of the data at 0x0804d799 (was d_0804d798+1)
	lsls r4, r3, #0x2
	add.w r12, sp, #0x40
	movt r1, #:upper16:d_0804d799	@ own label of the data at 0x0804d799 (was d_0804d798+1)
	mov.w r9, #0x4
	nop
.L0802bad0:
	lsrs r0, r3, #0x1
	ldrb r0, [r1, r0]
	bic.w r2, r9, r4
	lsrs r0, r2
	and r11, r0, #0xf
	ldrh.w r0, [r12, r11, lsl #0x1]
	ldrh.w r2, [r8, #0xa]
	adds r3, #0x1
	strh r2, [r10, #-0x2]
	uxth r2, r7
	lsrs r2, r2, #0x8
	strh.w r2, [r10]
	uxtb r2, r7
	strh.w r2, [r10]
	ldrh.w r2, [r8]
	adds r7, #0x1
	lsrs r2, r2, #0x8
	strh.w r2, [r10]
	ldrh.w r2, [r8]
	adds r4, #0x4
	uxtb r2, r2
	strh.w r2, [r10]
	ldrh.w r2, [r8, #0xc]
	strh r2, [r10, #-0x2]
	strh.w r6, [r10]
	strh.w r5, [r10]
	ldrh.w r2, [r8, #0x2]
	lsrs r2, r2, #0x8
	strh.w r2, [r10]
	ldrh.w r2, [r8, #0x2]
	uxtb r2, r2
	strh.w r2, [r10]
	ldrh.w r2, [r8, #0x8]
	strh r2, [r10, #-0x2]
	strh.w r0, [r10]
	sxth r0, r7
	cmp lr, r0
	bgt.n .L0802bad0
	b.n .L0802ba80
.L0802bb4a:
	uxth r7, r1
	lsrs r6, r7, #0x8
	uxtb r5, r1
	ldr r7, [sp, #0x30]
	movw r1, #:lower16:d_0804d767	@ own label of the nibble array at 0x0804d767 (was d_0804d766+1)
	lsls r4, r3, #0x2
	add.w r12, sp, #0x40
	movt r1, #:upper16:d_0804d767	@ own label of the nibble array at 0x0804d767 (was d_0804d766+1)
	mov.w r9, #0x4
.L0802bb64:
	lsrs r0, r3, #0x1
	ldrb r0, [r1, r0]
	bic.w r2, r9, r4
	lsrs r0, r2
	and r11, r0, #0xf
	ldrh.w r0, [r12, r11, lsl #0x1]
	ldrh.w r2, [r8, #0xa]
	adds r3, #0x1
	strh r2, [r10, #-0x2]
	uxth r2, r7
	lsrs r2, r2, #0x8
	strh.w r2, [r10]
	uxtb r2, r7
	strh.w r2, [r10]
	ldrh.w r2, [r8]
	adds r7, #0x1
	lsrs r2, r2, #0x8
	strh.w r2, [r10]
	ldrh.w r2, [r8]
	adds r4, #0x4
	uxtb r2, r2
	strh.w r2, [r10]
	ldrh.w r2, [r8, #0xc]
	strh r2, [r10, #-0x2]
	strh.w r6, [r10]
	strh.w r5, [r10]
	ldrh.w r2, [r8, #0x2]
	lsrs r2, r2, #0x8
	strh.w r2, [r10]
	ldrh.w r2, [r8, #0x2]
	uxtb r2, r2
	strh.w r2, [r10]
	ldrh.w r2, [r8, #0x8]
	strh r2, [r10, #-0x2]
	strh.w r0, [r10]
	sxth r0, r7
	cmp lr, r0
	bgt.n .L0802bb64
	b.n .L0802ba80
.L0802bbde:
	uxth r7, r1
	uxtb r6, r1
	ldr r5, [sp, #0x30]
	movw r1, #:lower16:d_0804d7c1	@ own label of the byte table at 0x0804d7c1 (was d_0804d7c0+1)
	lsr.w r12, r7, #0x8
	lsls r4, r3, #0x2
	movt r1, #:upper16:d_0804d7c1	@ own label of the byte table at 0x0804d7c1 (was d_0804d7c0+1)
	movs r7, #0x4
.L0802bbf4:
	ldr r0, [sp, #0x3c]
	cmp r0, #0x2
	itt eq
	lsreq r0, r3, #0x1
	ldrbeq.w r11, [r1, r0]
	bic.w r0, r7, r4
	uxtb.w r2, r11
	lsr.w r0, r2, r0
	and r11, r0, #0xf
	add r0, sp, #0x40
	ldrh.w r0, [r0, r11, lsl #0x1]
	ldrh.w r2, [r8, #0xa]
	adds r3, #0x1
	strh r2, [r10, #-0x2]
	uxth r2, r5
	lsrs r2, r2, #0x8
	strh.w r2, [r10]
	uxtb r2, r5
	strh.w r2, [r10]
	ldrh.w r2, [r8]
	adds r5, #0x1
	lsrs r2, r2, #0x8
	strh.w r2, [r10]
	ldrh.w r2, [r8]
	adds r4, #0x4
	uxtb r2, r2
	strh.w r2, [r10]
	ldrh.w r2, [r8, #0xc]
	strh r2, [r10, #-0x2]
	strh.w r12, [r10]
	strh.w r6, [r10]
	ldrh.w r2, [r8, #0x2]
	lsrs r2, r2, #0x8
	strh.w r2, [r10]
	ldrh.w r2, [r8, #0x2]
	uxtb r2, r2
	strh.w r2, [r10]
	ldrh.w r2, [r8, #0x8]
	strh r2, [r10, #-0x2]
	strh.w r0, [r10]
	sxth r0, r5
	cmp lr, r0
	bgt.n .L0802bbf4
	b.n .L0802ba84
	.byte 0x00, 0xbf	@ padding
.L0802bc80:
	ldr r0, [sp, #0x20]
	ldr r1, [sp, #0x28]
	cmp r1, r0
	beq.w .L0802b744
	movw r0, #0x2b20
	movt r0, #0x2000
	ldr r0, [r0]
	movw r1, #0xe010
	lsls r0, r0, #0x1
	movt r1, #0xe000
	movs r5, #0x0
	str r0, [r1, #0x4]
	str r5, [r1, #0x8]
	ldr r0, [r1]
	orr r0, r0, #0x1
	str r0, [r1]
.L0802bcac:
	ldr r0, [r1]
	and r0, r0, #0x10001
	cmp r0, #0x1
	bne.w .L0802b780
	ldr r0, [r1]
	and r0, r0, #0x10001
	cmp r0, #0x1
	bne.w .L0802b780
	ldr r0, [r1]
	and r0, r0, #0x10001
	cmp r0, #0x1
	bne.w .L0802b780
	ldr r0, [r1]
	and r0, r0, #0x10001
	cmp r0, #0x1
	beq.n .L0802bcac
	b.n .L0802b780
.L0802bcdc:
	movs r3, #0x0
	b.n .L0802bcf2
.L0802bce0:
	ldr r0, [r2]
	adds r3, #0x1
	bic r0, r0, #0x1
	cmp r3, #0xd2
	str r0, [r2]
	str r7, [r2, #0x8]
	beq.w .L0802c024
.L0802bcf2:
	add.w r0, r3, #0x37
	uxth r2, r0
	lsrs r2, r2, #0x8
	uxtb r0, r0
	movs r4, #0x0
	str r2, [sp, #0x3c]
	str r0, [sp, #0x38]
	str r3, [sp, #0x30]
	b.n .L0802bd24
	.byte 0x00, 0xbf	@ padding
.L0802bd08:
	ldr r4, [sp, #0x34]
	movw r2, #0xe010
	movw r6, #:lower16:d_0804c9fc
	ldr r3, [sp, #0x30]
	cmp r4, #0x4
	movt r2, #0xe000
	add r1, sp, #0x40
	movt r6, #:upper16:d_0804c9fc
	beq.w .L0802bfd8
.L0802bd24:
	adds r2, r4, #0x1
	ldrh.w r5, [r6, r2, lsl #0x3]
	str r2, [sp, #0x34]
	sub.w r7, r5, #0x37
	cmp r3, r7
	blt.n .L0802bd08
	add.w r9, r6, r2, lsl #0x3
	ldrh.w r6, [r9, #0x4]
	adds r0, r7, r6
	cmp r0, r3
	ble.n .L0802bd08
	adr r0, .L0802c0ac	@ halfword table (GAS forms the adr: the section is word aligned)
	ldrh.w r0, [r0, r4, lsl #0x1]
	bl fn_080092dc
	ldr r3, [sp, #0x30]
	and r1, r6, #0x1
	add.w lr, r1, r6, lsr #0x1
	subs r1, r3, r7
	mvns r2, r5
	add.w r1, r1, r1, lsr #0x1f
	add r3, r2
	ldrh.w r2, [r9, #0x2]
	uxtb r4, r4
	add.w r0, r9, #0x6
	asr.w r12, r1, #0x1
	cmp r4, #0x0
	and r3, r3, #0x1
	beq.n .L0802be0e
	cmp r4, #0x1
	bne.w .L0802bea2
	ldrh r0, [r0]
	ldrd r1, r9, [sp, #0x38]
	movs r5, #0x0
	movs r7, #0x0
	nop
.L0802bd88:
	mla r6, r5, lr, r12
	movw r4, #:lower16:d_0804d767	@ own label of the nibble array at 0x0804d767 (was d_0804d766+1)
	movt r4, #:upper16:d_0804d767	@ own label of the nibble array at 0x0804d767 (was d_0804d766+1)
	ldrb r6, [r4, r6]
	add r4, sp, #0x40
	and r11, r6, #0xf
	cmp r3, #0x0
	it eq
	lsreq.w r11, r6, #0x4
	ldrh.w r6, [r4, r11, lsl #0x1]
	ldrh.w r5, [r8, #0xa]
	adds r4, r2, r7
	strh r5, [r10, #-0x2]
	strh.w r9, [r10]
	strh.w r1, [r10]
	ldrh.w r5, [r8]
	adds r7, #0x1
	lsrs r5, r5, #0x8
	strh.w r5, [r10]
	ldrh.w r5, [r8]
	uxtb r5, r5
	strh.w r5, [r10]
	ldrh.w r5, [r8, #0xc]
	strh r5, [r10, #-0x2]
	uxth r5, r4
	lsrs r5, r5, #0x8
	strh.w r5, [r10]
	uxtb r5, r4
	strh.w r5, [r10]
	ldrh.w r5, [r8, #0x2]
	lsrs r5, r5, #0x8
	strh.w r5, [r10]
	ldrh.w r5, [r8, #0x2]
	uxtb r5, r5
	strh.w r5, [r10]
	ldrh.w r5, [r8, #0x8]
	strh r5, [r10, #-0x2]
	sxth r5, r7
	cmp r5, r0
	strh.w r6, [r10]
	blt.n .L0802bd88
	b.n .L0802bd08
.L0802be0e:
	ldrh.w r9, [r0]
	ldr r4, [sp, #0x3c]
	movw r5, #:lower16:d_0804ca24
	cmp r3, #0x0
	mov.w r7, #0x0
	mov.w r0, #0x0
	movt r5, #:upper16:d_0804ca24
	bne.w .L0802bf5c
	ldr r1, [sp, #0x38]
.L0802be2c:
	mla r3, r7, lr, r12
	adds r6, r2, r0
	ldrb r3, [r5, r3]
	adds r0, #0x1
	lsr.w r11, r3, #0x4
	add r3, sp, #0x40
	ldrh.w r3, [r3, r11, lsl #0x1]
	ldrh.w r7, [r8, #0xa]
	strh r7, [r10, #-0x2]
	strh.w r4, [r10]
	strh.w r1, [r10]
	ldrh.w r7, [r8]
	lsrs r7, r7, #0x8
	strh.w r7, [r10]
	ldrh.w r7, [r8]
	uxtb r7, r7
	strh.w r7, [r10]
	ldrh.w r7, [r8, #0xc]
	strh r7, [r10, #-0x2]
	uxth r7, r6
	lsrs r7, r7, #0x8
	strh.w r7, [r10]
	uxtb r7, r6
	strh.w r7, [r10]
	ldrh.w r7, [r8, #0x2]
	lsrs r7, r7, #0x8
	strh.w r7, [r10]
	ldrh.w r7, [r8, #0x2]
	uxtb r7, r7
	strh.w r7, [r10]
	ldrh.w r7, [r8, #0x8]
	strh r7, [r10, #-0x2]
	sxth r7, r0
	cmp r7, r9
	strh.w r3, [r10]
	blt.n .L0802be2c
	b.n .L0802bd08
.L0802bea2:
	ldrh.w r9, [r0]
	movw r7, #:lower16:d_0804d7c1	@ own label of the byte table at 0x0804d7c1 (was d_0804d7c0+1)
	movs r6, #0x0
	movs r0, #0x0
	movt r7, #:upper16:d_0804d7c1	@ own label of the byte table at 0x0804d7c1 (was d_0804d7c0+1)
	b.n .L0802bf42
.L0802beb4:
	add r5, r7
	ldr r7, [sp, #0x38]
.L0802beb8:
	ldrb.w r11, [r5]
.L0802bebc:
	uxtb.w r5, r11
	and r11, r11, #0xf
	add r1, sp, #0x40
	cmp r3, #0x0
	it eq
	lsreq.w r11, r5, #0x4
	ldrh.w r5, [r1, r11, lsl #0x1]
	ldrh.w r6, [r8, #0xa]
	strh r6, [r10, #-0x2]
	ldr r1, [sp, #0x3c]
	strh.w r1, [r10]
	strh.w r7, [r10]
	ldrh.w r6, [r8]
	adds r7, r2, r0
	lsrs r6, r6, #0x8
	strh.w r6, [r10]
	ldrh.w r6, [r8]
	uxth r1, r7
	uxtb r6, r6
	strh.w r6, [r10]
	ldrh.w r6, [r8, #0xc]
	lsrs r1, r1, #0x8
	strh r6, [r10, #-0x2]
	strh.w r1, [r10]
	uxtb r1, r7
	strh.w r1, [r10]
	ldrh.w r1, [r8, #0x2]
	adds r0, #0x1
	lsrs r1, r1, #0x8
	strh.w r1, [r10]
	ldrh.w r1, [r8, #0x2]
	movw r7, #:lower16:d_0804d7c1	@ own label of the byte table at 0x0804d7c1 (was d_0804d7c0+1)
	uxtb r1, r1
	strh.w r1, [r10]
	ldrh.w r1, [r8, #0x8]
	sxth r6, r0
	movt r7, #:upper16:d_0804d7c1	@ own label of the byte table at 0x0804d7c1 (was d_0804d7c0+1)
	cmp r6, r9
	strh r1, [r10, #-0x2]
	strh.w r5, [r10]
	bge.w .L0802bd08
.L0802bf42:
	mla r5, r6, lr, r12
	cmp r4, #0x3
	beq.n .L0802beb4
	ldr r7, [sp, #0x38]
	cmp r4, #0x2
	bne.n .L0802bebc
	movw r1, #:lower16:d_0804d799	@ own label of the data at 0x0804d799 (was d_0804d798+1)
	movt r1, #:upper16:d_0804d799	@ own label of the data at 0x0804d799 (was d_0804d798+1)
	add r5, r1
	b.n .L0802beb8
.L0802bf5c:
	ldr r1, [sp, #0x38]
	nop
.L0802bf60:
	mla r3, r7, lr, r12
	adds r6, r2, r0
	ldrb r3, [r5, r3]
	adds r0, #0x1
	and r11, r3, #0xf
	add r3, sp, #0x40
	ldrh.w r3, [r3, r11, lsl #0x1]
	ldrh.w r7, [r8, #0xa]
	strh r7, [r10, #-0x2]
	strh.w r4, [r10]
	strh.w r1, [r10]
	ldrh.w r7, [r8]
	lsrs r7, r7, #0x8
	strh.w r7, [r10]
	ldrh.w r7, [r8]
	uxtb r7, r7
	strh.w r7, [r10]
	ldrh.w r7, [r8, #0xc]
	strh r7, [r10, #-0x2]
	uxth r7, r6
	lsrs r7, r7, #0x8
	strh.w r7, [r10]
	uxtb r7, r6
	strh.w r7, [r10]
	ldrh.w r7, [r8, #0x2]
	lsrs r7, r7, #0x8
	strh.w r7, [r10]
	ldrh.w r7, [r8, #0x2]
	uxtb r7, r7
	strh.w r7, [r10]
	ldrh.w r7, [r8, #0x8]
	strh r7, [r10, #-0x2]
	sxth r7, r0
	cmp r7, r9
	strh.w r3, [r10]
	blt.n .L0802bf60
	b.n .L0802bd08
	.byte 0x00, 0xbf	@ padding
.L0802bfd8:
	movw r0, #0x2b20
	movt r0, #0x2000
	ldr r0, [r0]
	movs r7, #0x0
	add.w r0, r0, r0, lsl #0x1
	str r0, [r2, #0x4]
	str r7, [r2, #0x8]
	ldr r0, [r2]
	orr r0, r0, #0x1
	str r0, [r2]
.L0802bff4:
	ldr r0, [r2]
	and r0, r0, #0x10001
	cmp r0, #0x1
	bne.w .L0802bce0
	ldr r0, [r2]
	and r0, r0, #0x10001
	cmp r0, #0x1
	bne.w .L0802bce0
	ldr r0, [r2]
	and r0, r0, #0x10001
	cmp r0, #0x1
	bne.w .L0802bce0
	ldr r0, [r2]
	and r0, r0, #0x10001
	cmp r0, #0x1
	beq.n .L0802bff4
	b.n .L0802bce0
.L0802c024:
	movw r5, #0x1018
	movw r6, #0xf8
	movw r8, #0x1c34
	movw r7, #0x1070
	ldrd r11, r9, [sp, #0x4]
	movt r5, #0x4002
	movt r6, #0x2000
	movt r8, #0x4000
	movt r7, #0x2000
	b.n .L0802c134
.L0802c04a:
	movw r5, #0x5034
	movw r0, #:lower16:t_080bc66b
	movt r5, #0x4001
	movt r0, #:upper16:t_080bc66b
	movs r1, #0x0
	movs r2, #0x0
	str r4, [r5]
	bl decode_image_file_with_offset
	ldrb.w r0, [r6, #0xf61]
	movw r3, #0xe010
	str r0, [r5]
	movw r5, #0x1018
	movw r8, #0x1c34
	movw r7, #0x1070
	mov.w r1, #0x1f4
	movs r0, #0x32
	movt r3, #0xe000
	movt r5, #0x4002
	movt r8, #0x4000
	movt r7, #0x2000
	b.n .L0802c0c6
	.byte 0x00, 0xbf	@ padding
.L0802c094:
	.asciz "3:/System file/162.jpg"
	.byte 0x00	@ padding
.L0802c0ac:
	.short 0x4d3f
	.short 0xfd88
	.byte 0xf7, 0x56, 0x3f, 0x4d
.L0802c0b4:
	.word 0x43480000
.L0802c0b8:
	ldr r2, [r3]
	bic r2, r2, #0x1
	str r2, [r3]
	lsls r2, r1, #0x10
	str r4, [r3, #0x8]
	beq.n .L0802c126
.L0802c0c6:
	uxth r2, r1
	cmp r2, #0x33
	bcc.n .L0802c0e0
	movw r2, #0x2b20
	movt r2, #0x2000
	ldr r2, [r2]
	subs r1, #0x32
	muls r2, r0, r2
	str r2, [r3, #0x4]
	b.n .L0802c0f0
	.byte 0x00, 0xbf	@ padding
.L0802c0e0:
	movw r1, #0x2b20
	movt r1, #0x2000
	ldr r1, [r1]
	muls r1, r2, r1
	str r1, [r3, #0x4]
	movs r1, #0x0
.L0802c0f0:
	str r4, [r3, #0x8]
	ldr r2, [r3]
	orr r2, r2, #0x1
	str r2, [r3]
	nop
.L0802c0fc:
	ldr r2, [r3]
	and r2, r2, #0x10001
	cmp r2, #0x1
	bne.n .L0802c0b8
	ldr r2, [r3]
	and r2, r2, #0x10001
	cmp r2, #0x1
	bne.n .L0802c0b8
	ldr r2, [r3]
	and r2, r2, #0x10001
	cmp r2, #0x1
	bne.n .L0802c0b8
	ldr r2, [r3]
	and r2, r2, #0x10001
	cmp r2, #0x1
	beq.n .L0802c0fc
	b.n .L0802c0b8
.L0802c126:
	mov r0, r9
	bl file_close
	movw r2, #0xe010
	movt r2, #0xe000
.L0802c134:
	ldrb r0, [r7, #0x10]
	cbz r0, .L0802c15a
	ldr r0, [r7, #0x8]
	sub.w r0, r11, r0
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0802c168
	ldr r3, [r7, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r3, r0, lsl #0x1]
	cbz r1, .L0802c168
	add.w r0, r3, r0, lsl #0x1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L0802c160
.L0802c15a:
	ldr r1, [r7]
	movs r0, #0x0
	blx r1
.L0802c160:
	movw r2, #0xe010
	movt r2, #0xe000
.L0802c168:
	cmp.w r9, #0x0
	beq.n .L0802c1a2
	ldrb r0, [r7, #0x10]
	cbz r0, .L0802c194
	ldr r0, [r7, #0x8]
	sub.w r0, r9, r0
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0802c1a2
	ldr r3, [r7, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r3, r0, lsl #0x1]
	cbz r1, .L0802c1a2
	add.w r0, r3, r0, lsl #0x1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L0802c19a
.L0802c194:
	ldr r1, [r7]
	movs r0, #0x0
	blx r1
.L0802c19a:
	movw r2, #0xe010
	movt r2, #0xe000
.L0802c1a2:
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movw r1, #0x6b80
	movt r0, #:upper16:copy_rect_into_clip_buffer
	movt r1, #0x2003
	str r0, [r1]
	movw r0, #0x2b20
	movt r0, #0x2000
	ldr r0, [r0]
	rsb r0, r0, r0, lsl #0x4
	lsls r0, r0, #0x1
	str r0, [r2, #0x4]
	movs r0, #0x0
	str r0, [r2, #0x8]
	ldr r0, [r2]
	orr r0, r0, #0x1
	str r0, [r2]
	nop
.L0802c1d4:
	ldr r0, [r2]
	and r0, r0, #0x10001
	cmp r0, #0x1
	bne.n .L0802c1fc
	ldr r0, [r2]
	and r0, r0, #0x10001
	cmp r0, #0x1
	bne.n .L0802c1fc
	ldr r0, [r2]
	and r0, r0, #0x10001
	cmp r0, #0x1
	bne.n .L0802c1fc
	ldr r0, [r2]
	and r0, r0, #0x10001
	cmp r0, #0x1
	beq.n .L0802c1d4
.L0802c1fc:
	ldr r0, [r2]
	movw r7, #0x400
	bic r0, r0, #0x1
	str r0, [r2]
	movs r0, #0x0
	str r0, [r2, #0x8]
	ldr r0, [r5, #0x4]
	movw r4, #0x7400
	orr r0, r0, #0x20000000
	str r0, [r5, #0x4]
	ldr r0, [r5]
	movt r7, #0x103
	orr r0, r0, #0x4
	str r0, [r5]
	movs r0, #0x10
	str r0, [sp, #0x40]
	movw r0, #0x800
	add r1, sp, #0x40
	movt r0, #0x4001
	movt r4, #0x4000
	str r7, [sp, #0x44]
	bl set_nibble_fields_from_bit_mask
	ldr r0, [r4]
	orr r0, r0, #0x38
	str r0, [r4]
	ldr r0, [r4]
	orr r0, r0, #0x4
	str r0, [r4]
	ldr r0, [r4]
	bic r0, r0, #0xc0
	str r0, [r4]
	ldr r0, [r4]
	bic r0, r0, #0x2
	str r0, [r4]
	ldr r0, [r4]
	bic r0, r0, #0x1000
	str r0, [r4]
	ldr r0, [r4]
	orr r0, r0, #0x1
	str r0, [r4]
	ldrb.w r1, [r6, #0x2d]
	ldrb r0, [r6, #0x2]
	cmp r1, #0x5
	bcc.n .L0802c284
	add.w r1, r6, r0, lsl #0x1
	add.w r0, r1, #0x29c
	add.w r1, r1, #0x260
	b.n .L0802c2a8
.L0802c284:
	cmp r1, #0x4
	beq.n .L0802c29c
	ldrb r1, [r6, #0x14]
	cmp r1, #0x3
	beq.n .L0802c29c
	add.w r1, r6, r0, lsl #0x1
	add.w r0, r1, #0x2c4
	add.w r1, r1, #0x288
	b.n .L0802c2a8
.L0802c29c:
	add.w r1, r6, r0, lsl #0x1
	add.w r0, r1, #0x2b0
	add.w r1, r1, #0x274
.L0802c2a8:
	ldrh r0, [r0]
	ldrh r1, [r1]
	vldr s0, .L0802c0b4
	subs r0, r0, r1
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s2, s2, s0
	ldrsb.w r0, [r6, #0x4]
	adds r0, #0x64
	vmov s4, r0
	vcvt.f32.s32 s4, s4
	ldr r0, [r4, #0x8]
	lsrs r0, r0, #0xc
	vmul.f32 s2, s2, s4
	vmov s4, r1
	vcvt.f32.u32 s4, s4
	vadd.f32 s2, s2, s4
	vcvt.u32.f32 s2, s2
	vmov r1, s2
	bfi r1, r0, #0xc, #0x14
	str r1, [r4, #0x8]
	ldr r0, [r4, #0x4]
	orr r0, r0, #0x1
	str r0, [r4, #0x4]
	ldrb.w r1, [r6, #0x2d]
	ldrb r0, [r6, #0x3]
	cmp r1, #0x5
	bcc.n .L0802c30e
	add.w r1, r6, r0, lsl #0x1
	add.w r0, r1, #0x314
	add.w r1, r1, #0x2d8
	b.n .L0802c332
.L0802c30e:
	cmp r1, #0x4
	beq.n .L0802c326
	ldrb r1, [r6, #0x14]
	cmp r1, #0x3
	beq.n .L0802c326
	add.w r1, r6, r0, lsl #0x1
	add.w r0, r1, #0x33c
	add.w r1, r1, #0x300
	b.n .L0802c332
.L0802c326:
	add.w r1, r6, r0, lsl #0x1
	add.w r0, r1, #0x328
	add.w r1, r1, #0x2ec
.L0802c332:
	ldrh r0, [r0]
	ldrh r1, [r1]
	movw r4, #0x2408
	subs r0, r0, r1
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s0, s2, s0
	ldrsb.w r0, [r6, #0x5]
	movs r6, #0x2
	adds r0, #0x64
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	movt r4, #0x4001
	vmul.f32 s0, s0, s2
	vmov s2, r1
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vstr s0, [r8]
	ldr r0, [r5]
	add r1, sp, #0x40
	orr r0, r0, #0x8
	str r0, [r5]
	ldr r0, [sp, #0x10]
	str r7, [sp, #0x44]
	str r6, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	ldr r0, [r5]
	movw r1, #0x444
	orr r0, r0, #0x200
	str r0, [r5]
	movt r1, #0x4002
	ldr.w r0, [r1, #0xbc0]
	bfi r0, r6, #0xe, #2
	str.w r0, [r1, #0xbc0]
	ldr.w r0, [r1, #0xbc0]
	bic r0, r0, #0x10000000
	str.w r0, [r1, #0xbc0]
	ldr.w r0, [r4, #-0x4]
	movs r1, #0x9
	bic r0, r0, #0xf0000
	str.w r0, [r4, #-0x4]
	ldr.w r0, [r4, #-0x4]
	orr r0, r0, #0x100
	str.w r0, [r4, #-0x4]
	ldr r0, [r4]
	orr r0, r0, #0x2
	str r0, [r4]
	ldr r0, [r4]
	bic r0, r0, #0x800
	str r0, [r4]
	ldr r0, [r4, #0x24]
	bic r0, r0, #0xf00000
	str r0, [r4, #0x24]
	ldr r0, [r4, #0x8]
	orr r0, r0, #0x38000000
	str r0, [r4, #0x8]
	ldr r0, [r4, #0x2c]
	bfi r0, r1, #0x0, #0x5
	str r0, [r4, #0x2c]
	ldr r0, [r4]
	bic r0, r0, #0x2000000
	str r0, [r4]
	ldr r0, [r4]
	orr r0, r0, #0xe0000
	str r0, [r4]
	ldr r0, [r4]
	orr r0, r0, #0x100000
	str r0, [r4]
	ldr r0, [r4]
	orr r0, r0, #0x100
	str r0, [r4]
	ldr r0, [r4]
	orr r0, r0, #0x1
	str r0, [r4]
	ldr r0, [r4]
	orr r0, r0, #0x8
	str r0, [r4]
	nop
.L0802c424:
	ldr r0, [r4]
	lsls r0, r0, #0x1c
	itttt mi
	ldrmi r0, [r4]
	lslsmi.w r0, r0, #0x1c
	ldrmi r0, [r4]
	lslsmi.w r0, r0, #0x1c
	bpl.n .L0802c43e
	ldr r0, [r4]
	lsls r0, r0, #0x1c
	bmi.n .L0802c424
.L0802c43e:
	ldr r0, [r4]
	movw r1, #0x1000
	orr r0, r0, #0x4
	movt r1, #0x4001
	str r0, [r4]
	nop
.L0802c450:
	ldr r0, [r4]
	lsls r0, r0, #0x1d
	itttt mi
	ldrmi r0, [r4]
	lslsmi.w r0, r0, #0x1d
	ldrmi r0, [r4]
	lslsmi.w r0, r0, #0x1d
	bpl.n .L0802c46a
	ldr r0, [r4]
	lsls r0, r0, #0x1d
	bmi.n .L0802c450
.L0802c46a:
	ldr r0, [r5]
	add r4, sp, #0x40
	orr r0, r0, #0x10
	str r0, [r5]
	ldr r0, [r5]
	mov.w r9, #0x1
	orr r0, r0, #0x40
	str r0, [r5]
	ldr r0, [r5]
	movw r10, #0x1018
	orr r0, r0, #0x40
	str r0, [r5]
	ldr r0, [r5]
	mov.w r11, #0x1000
	orr r0, r0, #0x40
	str r0, [r5]
	ldr r0, [r5]
	orr r0, r0, #0x4
	str r0, [r5]
	ldr r0, [r5]
	orr r0, r0, #0x8
	str r0, [r5]
	ldr r0, [r5]
	orr r0, r0, #0x8
	str r0, [r5]
	ldr r0, [r5]
	orr r0, r0, #0x4
	str r0, [r5]
	movs r0, #0x0
	strb.w r0, [sp, #0x44]
	mov r0, r1
	mov r1, r4
	strb.w r9, [sp, #0x47]
	strh.w r10, [sp, #0x45]
	str.w r11, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	movw r6, #0x1800
	movs r0, #0x10
	movt r6, #0x4001
	str r0, [sp, #0x40]
	mov r0, r6
	mov r1, r4
	bl set_nibble_fields_from_bit_mask
	movs r0, #0x20
	str r0, [sp, #0x40]
	mov r0, r6
	mov r1, r4
	bl set_nibble_fields_from_bit_mask
	movs r0, #0x40
	str r0, [sp, #0x40]
	mov r0, r6
	mov r1, r4
	bl set_nibble_fields_from_bit_mask
	movw r8, #0x800
	mov.w r0, #0x8000
	movt r8, #0x4001
	str r0, [sp, #0x40]
	mov r0, r8
	mov r1, r4
	bl set_nibble_fields_from_bit_mask
	ldr r6, [sp, #0x10]
	mov.w r0, #0x800
	str r0, [sp, #0x40]
	mov r0, r6
	mov r1, r4
	bl set_nibble_fields_from_bit_mask
	mov.w r7, #0x400
	mov r0, r6
	mov r1, r4
	str r7, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	mov r0, r8
	mov r1, r4
	str r7, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	movw r4, #0xf8
	movt r4, #0x2000
	ldrb r0, [r4, #0x2]
	bl fn_080088a4
	ldrb r0, [r4, #0x3]
	bl fn_08008a58
	ldr r0, [r5]
	orr r0, r0, #0x20
	str r0, [r5]
	ldr r0, [r5]
	orr r0, r0, #0x20
	str r0, [r5]
	ldr r6, [sp, #0xc]
	movs r0, #0x0
	strb.w r9, [sp, #0x47]
	mov r9, r4
	add r4, sp, #0x40
	strb.w r0, [sp, #0x44]
	mov r0, r6
	mov r1, r4
	strh.w r10, [sp, #0x45]
	str.w r11, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	mov.w r0, #0x2000
	str r0, [sp, #0x40]
	mov r0, r6
	mov r1, r4
	bl set_nibble_fields_from_bit_mask
	ldrb.w r0, [r9]
	movw r1, #0x1014
	movt r1, #0x4001
	cmp r0, #0x0
	ite ne
	strne.w r11, [r1, #0x3fc]
	streq.w r11, [r1, #0x400]
	ldrb.w r0, [r9, #0x1]
	movw r6, #0x1000
	cmp r0, #0x0
	mov.w r0, #0x2000
	ite ne
	strne.w r0, [r1, #0x3fc]
	streq.w r0, [r1, #0x400]
	ldr r0, [r5]
	movt r6, #0x4001
	orr r0, r0, #0x10
	str r0, [r5]
	ldr r0, [r5]
	add r4, sp, #0x40
	orr r0, r0, #0x10
	str r0, [r5]
	movs r0, #0x0
	strb.w r0, [sp, #0x44]
	movs r0, #0x1
	strb.w r0, [sp, #0x47]
	movw r0, #0x1018
	strh.w r0, [sp, #0x45]
	mov.w r8, #0x4
	mov r0, r6
	mov r1, r4
	str.w r8, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	movs r7, #0x2
	mov r0, r6
	mov r1, r4
	str r7, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	ldrb.w r0, [r9, #0x14]
	cmp r0, #0x3
	beq.n .L0802c632
	cmp r0, #0x2
	beq.n .L0802c64a
	movw r10, #0x1000
	movw r6, #0x1014
	cmp r0, #0x1
	movt r10, #0x4001
	movt r6, #0x4001
	bne.n .L0802c662
	movs r0, #0x4
	str.w r0, [r10, #0x10]
	movs r0, #0x2
	str.w r0, [r10, #0x10]
	b.n .L0802c662
.L0802c632:
	movw r10, #0x1000
	movw r6, #0x1014
	movt r10, #0x4001
	movt r6, #0x4001
	str.w r8, [r10, #0x10]
	str r7, [r6]
	b.n .L0802c662
.L0802c64a:
	movw r6, #0x1014
	movs r0, #0x4
	movt r6, #0x4001
	str r0, [r6]
	movs r0, #0x2
	movw r10, #0x1000
	str r0, [r6]
	movt r10, #0x4001
.L0802c662:
	ldr r0, [r5]
	add r4, sp, #0x40
	orr r0, r0, #0x20
	str r0, [r5]
	ldr r0, [r5]
	movw r11, #0x440c
	orr r0, r0, #0x20
	str r0, [r5]
	movs r0, #0x0
	strb.w r0, [sp, #0x44]
	movs r0, #0x1
	strb.w r0, [sp, #0x47]
	movw r0, #0x1018
	ldr r7, [sp, #0xc]
	strh.w r0, [sp, #0x45]
	movs r0, #0x8
	str r0, [sp, #0x40]
	mov r0, r7
	mov r1, r4
	movt r11, #0x4000
	mov.w r8, #0x8
	bl set_nibble_fields_from_bit_mask
	mov.w r9, #0x4
	mov r0, r7
	mov r1, r4
	str.w r9, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	str.w r8, [r6, #0x3fc]
	ldr r0, [r5]
	movw r8, #0x800
	orr r0, r0, #0x4
	str r0, [r5]
	ldr r0, [r5]
	add r4, sp, #0x40
	orr r0, r0, #0x4
	str r0, [r5]
	movw r0, #0x400
	movt r0, #0x100
	str r0, [sp, #0x44]
	movs r0, #0x2
	movt r8, #0x4001
	str r0, [sp, #0x40]
	mov r0, r8
	mov r1, r4
	bl set_nibble_fields_from_bit_mask
	movs r7, #0x1
	mov r0, r8
	mov r1, r4
	str r7, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	ldr r0, [r5]
	mov.w r8, #0x0
	orr r0, r0, #0x10
	str r0, [r5]
	movw r0, #0x1018
	strh.w r0, [sp, #0x45]
	mov.w r4, #0x800
	add r1, sp, #0x40
	mov r0, r10
	strb.w r8, [sp, #0x44]
	strb.w r7, [sp, #0x47]
	movs r7, #0x1
	str r4, [sp, #0x40]
	bl set_nibble_fields_from_bit_mask
	str r4, [r6]
	ldr r0, [r5]
	add r1, sp, #0x40
	orr r0, r0, #0x10
	str r0, [r5]
	movs r0, #0x18
	strh.w r0, [sp, #0x45]
	movs r0, #0x8
	strb.w r7, [sp, #0x47]
	str r0, [sp, #0x40]
	mov r0, r10
	movw r7, #0xed0c
	strb.w r8, [sp, #0x44]
	movs r6, #0x0
	movs r4, #0x1
	movt r7, #0xe000
	bl set_nibble_fields_from_bit_mask
	ldr r0, [r5]
	movs r2, #0x8
	orr r0, r0, #0x1
	str r0, [r5]
	ldr r0, [r5]
	movt r2, #0x4001
	orr r0, r0, #0x10
	str r0, [r5]
	ldr r0, [r2]
	movw r8, #0x800
	bic r0, r0, #0xf000
	str r0, [r2]
	ldr r0, [r2]
	movt r8, #0x4001
	orr r0, r0, #0x2000
	str r0, [r2]
	ldr.w r0, [r2, #0x3f8]
	mov r3, r8
	bic r0, r0, #0x8
	str.w r0, [r2, #0x3f8]
	ldr.w r0, [r2, #0x3fc]
	mov r10, r3
	bic r0, r0, #0x8
	str.w r0, [r2, #0x3fc]
	ldr.w r0, [r2, #0x3f8]
	orr r0, r0, #0x8
	str.w r0, [r2, #0x3f8]
	ldr.w r0, [r2, #0x400]
	bic r0, r0, #0x8
	str.w r0, [r2, #0x400]
	movw r0, #0xfc0c
	movt r0, #0xffff
	ldr.w r1, [r8, r0]
	bic r1, r1, #0x8
	str.w r1, [r8, r0]
	ldr.w r0, [r2, #0x400]
	movw r8, #0xe409
	orr r0, r0, #0x8
	str.w r0, [r2, #0x400]
	ldr r0, [r7]
	mov.w r7, #0xffffffff
	ubfx r0, r0, #0x8, #0x3
	eor r1, r0, #0x7
	cmp r1, #0x4
	it cs
	movcs r1, r9
	lsl.w r1, r7, r1
	subs r0, #0x3
	bic.w r1, r4, r1
	it cc
	movcc r0, r6
	lsl.w r0, r1, r0
	lsls r0, r0, #0x4
	movt r8, #0xe000
	movw r6, #0xe010
	strb.w r0, [r8]
	mov.w r0, #0x200
	movt r6, #0xe000
	str.w r0, [r6, #0xf0]
	ldr r0, [r5, #0x4]
	add r4, sp, #0x60
	orr r0, r0, #0x20000
	str r0, [r5, #0x4]
	ldr r0, [r5]
	mov r1, r4
	orr r0, r0, #0x4
	str r0, [r5]
	ldr r0, [r5]
	orr r0, r0, #0x4
	str r0, [r5]
	movw r0, #0x400
	movt r0, #0x108
	strd r9, r0, [sp, #0x60]
	mov r0, r3
	bl set_nibble_fields_from_bit_mask
	movw r0, #0x1800
	movt r0, #0x100
	str r0, [sp, #0x64]
	movs r0, #0x8
	str r0, [sp, #0x60]
	mov r0, r10
	mov r1, r4
	bl set_nibble_fields_from_bit_mask
	movw r0, #0xed0c
	movt r0, #0xe000
	ldr r0, [r0]
	movs r4, #0x1
	ubfx r0, r0, #0x8, #0x3
	eor r1, r0, #0x7
	cmp r1, #0x4
	it cc
	movcc r9, r1
	lsl.w r1, r7, r9
	subs r0, #0x3
	bic.w r1, r4, r1
	mov.w r2, #0x0
	it cc
	movcc r0, r2
	lsl.w r0, r1, r0
	lsls r0, r0, #0x4
	strb.w r0, [r8, #0x1d]
	movs r0, #0x40
	str.w r0, [r6, #0xf4]
	movw r7, #0xc00
	add r0, sp, #0x40
	mov r9, r8
	movt r7, #0x4000
	bl compute_clock_frequencies
	ldr r0, [sp, #0x4c]
	movw r1, #0x81b5
	add.w r0, r0, r0, lsl #0x2
	lsls r0, r0, #0x1
	movt r1, #0x1b4e
	umull r0, r1, r0, r1
	lsrs r0, r1, #0xa
	movw r1, #0xcccd
	movt r1, #0xcccc
	umull r1, r2, r0, r1
	lsrs r1, r2, #0x3
	add.w r3, r1, r1, lsl #0x2
	sub.w r0, r0, r3, lsl #0x1
	cmp r0, #0x4
	ldr.w r0, [r11, #-0x4]
	it hi
	addhi.w r1, r4, r2, lsr #0x3
	pkhbt r0, r1, r0
	str.w r0, [r11, #-0x4]
	ldr.w r0, [r11]
	movw r4, #0x444
	bic r0, r0, #0x1000
	str.w r0, [r11]
	ldr.w r0, [r11, #0x4]
	movt r4, #0x4002
	bic r0, r0, #0x3000
	str.w r0, [r11, #0x4]
	ldr.w r0, [r11]
	add r1, sp, #0x60
	orr r0, r0, #0x8
	str.w r0, [r11]
	ldr.w r0, [r11]
	mov.w r8, #0x0
	orr r0, r0, #0x4
	str.w r0, [r11]
	ldr.w r0, [r11]
	orr r0, r0, #0x20
	str.w r0, [r11]
	ldr.w r0, [r11]
	bic r0, r0, #0x2000
	str.w r0, [r11]
	ldr r0, [r5, #0x4]
	orr r0, r0, #0x20
	str r0, [r5, #0x4]
	ldr.w r0, [r4, #0xbd0]
	orr r0, r0, #0x2
	str.w r0, [r4, #0xbd0]
	ldr r0, [r5, #0x4]
	orr r0, r0, #0x20000000
	str r0, [r5, #0x4]
	ldr r0, [r5]
	orr r0, r0, #0x4
	str r0, [r5]
	movw r0, #0x400
	movt r0, #0x103
	str r0, [sp, #0x64]
	movs r0, #0x20
	str r0, [sp, #0x60]
	movs r0, #0x0
	str r0, [sp, #0x50]
	strd r0, r0, [sp, #0x48]
	strd r0, r0, [sp, #0x40]
	mov r0, r10
	bl set_nibble_fields_from_bit_mask
	add r0, sp, #0x40
	bl compute_clock_frequencies
	movw lr, #0xf8
	movt lr, #0x2000
	ldr.w r0, [lr, #0xe5c]
	movs r1, #0xc8
	muls r0, r1, r0
	vmov s0, r0
	vldr s2, [sp, #0x40]
	vcvt.f32.u32 s0, s0
	vmov.f32 s4, #10.0
	cmp.w r0, #0xfa0
	vcvt.f32.u32 s2, s2
	vmul.f32 s4, s0, s4
	it cc
	vmovcc.f32 s0, s4
	vdiv.f32 s0, s2, s0
	mov.w r0, #0x1
	vmov.f32 s2, #-1.0
	movw r2, #0xfc2c
	movw r3, #0x1800
	it cc
	movcc r0, #0x13
	movt r2, #0xffff
	movt r3, #0x4000
	str r0, [r3, r2]
	movw r0, #0xfc28
	movt r0, #0xffff
	movs r2, #0x2
	movw r6, #0x7400
	movt r6, #0x4000
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vmov r1, s0
	str r1, [r3, r0]
	movw r1, #0xfc14
	movt r1, #0xffff
	ldr r0, [r3, r1]
	mov.w r12, #0x1
	orr r0, r0, #0x1
	str r0, [r3, r1]
	ldr.w r0, [r7, #0x800]
	bic r0, r0, #0x70
	str.w r0, [r7, #0x800]
	movw r0, #0xfc04
	movt r0, #0xffff
	ldr r1, [r3, r0]
	bfi r1, r2, #0x4, #0x3
	str r1, [r3, r0]
	ldr r0, [r6]
	movs r3, #0x2
	bfi r0, r2, #0x13, #0x3
	str r0, [r6]
	ldr r0, [r6]
	movw r2, #0xbfef
	orr r0, r0, #0x40000
	str r0, [r6]
	ldr r0, [r6]
	bic r0, r0, #0xc00000
	str r0, [r6]
	ldr r0, [r6]
	bic r0, r0, #0x20000
	str r0, [r6]
	ldr r0, [r6]
	orr r1, r0, #0x10000000
