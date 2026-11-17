@ scope_acq_48.s - fn_08025aac: builds / frees the singly linked list of bit-row or sample-copy nodes.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08025aac - maintains a singly linked list of allocated nodes.
@ No parameters, no return value.
@ The head pointer of the list is the word at 0x20000138. A node is 0x14 bytes:
@   +0x00 byte tag (0x80 or 0xff)
@   +0x04 buffer pointer, channel 0
@   +0x08 buffer pointer, channel 1
@   +0x0c u16 start and +0x0e u16 count (both copied from word 0x20000eac)
@   +0x10 next pointer
@ Buffers are released with the same test as in 0x080251e4: the function
@ pointer at 0x20001070 is called (r0 = 0 as argument) when byte 0x20001080 is
@ 0, otherwise the table 0x2000107c / 0x20001078 is used together with
@ 0x080082bc zero_bytes.
@ Dispatch on byte 0x20000134:
@  == 0: for every node releases the +4 and +8 buffers (when non-zero) and the
@        node itself, then sets the head to 0.
@  == 3: if the head is 0 allocates a node with 0x0803acfc (0x14 bytes; a
@        failure stores 0 in the head and returns), sets tag 0x80, +0xc from
@        word 0x20000eac, +4 / +8 / +0x10 = 0.
@        If byte 0x2000012c is 0: for each channel ch from the high to below
@        the low nibble of byte 0x2000010d, when the node buffer +4+ch*4 is 0
@        allocates 0x1e92 bytes (301 rows of 0x1a bytes) and clears them with
@        0x080082bc (the clear call at 0x08025e24 also runs when the
@        allocation returned 0; the channel is skipped after it when the
@        pointer is 0). An existing buffer is not cleared, so bits accumulate.
@        When count >= 2 then for i = start .. start+count-2, with
@        y(i) = byte 0x2000044e + ch*0x12d + i minus 0x1c, sets in row i (0x1a
@        bytes per row, bit y&7 of byte y>>3) the bits from y(i) up to but
@        excluding y(i+1) and sets the bit y(i+1) in row i+1.
@        If byte 0x2000012c is non-zero: uses only the +4 buffer (allocated
@        with 0x146a bytes = 201 rows of 0x1a bytes and cleared when 0; the
@        clear call at 0x08025b3a also runs when the allocation returned 0;
@        returns when the allocation fails) and for i = start .. start+count-2
@        sets the bit (byte 0x2000057b[i] - 0x1c) in row
@        byte 0x2000044e[i] - 0x1c.
@  any other value: if byte 0x2000013c is 0 appends at the list tail a new node
@        (0x14 bytes, tag 0xff, start/count from word 0x20000eac); for each
@        channel allocates a buffer of count bytes (u16 0x20000eae) and copies
@        the bytes 0x2000044e + ch*0x12d + start .. + count-1. If byte
@        0x2000013c is non-zero and the head exists releases the head's +4 and
@        +8 buffers and the head node and makes its next pointer the head.
@ Purpose: builds a linked list of allocated nodes holding either per-channel
@ bit rows (byte 0x20000134 == 3) or copies of sample byte ranges (other values
@ except 0); the use of the data is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08025aac,"ax",%progbits
	.global fn_08025aac
	.thumb_func
	.type fn_08025aac, %function
fn_08025aac:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0xc
	movw r3, #0xf8
	movt r3, #0x2000
	ldrb.w r0, [r3, #0x3c]
	cmp r0, #0x0
	beq.n .L08025bb2
	cmp r0, #0x3
	bne.w .L08025c78
	ldr.w r8, [r3, #0x40]
	cmp.w r8, #0x0
	bne.n .L08025b02
	movs r0, #0x14
	bl alloc_units_of_32_bytes
	movw r3, #0xf8
	movt r3, #0x2000
	cmp r0, #0x0
	str r0, [r3, #0x40]
	beq.w .L08025f30
	movs r1, #0x80
	strb r1, [r0, #0x0]
	ldr.w r1, [r3, #0xdb4]
	str r1, [r0, #0xc]
	movs r1, #0x0
	str r1, [r0, #0x4]
	ldr r0, [r3, #0x40]
	str r1, [r0, #0x8]
	ldr.w r8, [r3, #0x40]
	str.w r1, [r8, #0x10]
.L08025b02:
	ldrb.w r0, [r3, #0x34]
	cmp r0, #0x0
	beq.w .L08025dc4
	ldr.w r0, [r8, #0x4]
	cbnz r0, .L08025b50
	movw r0, #0x146a
	bl alloc_units_of_32_bytes
	movw r1, #0xf8
	movt r1, #0x2000
	ldr r1, [r1, #0x40]
	str r0, [r1, #0x4]
	movw r0, #0xf8
	movt r0, #0x2000
	ldr.w r8, [r0, #0x40]
	movw r1, #0x146a
	ldr.w r0, [r8, #0x4]
	bl zero_bytes
	ldr.w r0, [r8, #0x4]
	movw r3, #0xf8
	movt r3, #0x2000
	cmp r0, #0x0
	beq.w .L08025f30
.L08025b50:
	ldrh.w r1, [r8, #0xe]
	cmp r1, #0x2
	bcc.w .L08025f30
	ldrh.w r6, [r8, #0xc]
	movw r2, #0xfd28
	mov.w r12, #0x1
	mov.w lr, #0x1a
	movt r2, #0xffff
	mov r7, r6
.L08025b70:
	add r6, r3
	ldrb.w r5, [r6, #0x483]
	ldrb.w r6, [r6, #0x356]
	subs r5, #0x1c
	uxth r4, r5
	and.w r1, r5, #0x7
	mul r6, r6, lr
	add.w r5, r5, r4, lsr #0xd
	add.w r6, r6, r5, asr #0x3
	add r0, r6
	ldrb r6, [r0, r2]
	lsl.w r1, r12, r1
	orrs r1, r6
	strb r1, [r0, r2]
	ldr r0, [r3, #0x40]
	adds r7, #0x1
	ldrh r1, [r0, #0xc]
	ldrh r5, [r0, #0xe]
	uxth r6, r7
	add r1, r5
	subs r1, #0x1
	cmp r1, r6
	ble.w .L08025f30
	ldr r0, [r0, #0x4]
	b.n .L08025b70
.L08025bb2:
	ldr r4, [r3, #0x40]
	cmp r4, #0x0
	beq.w .L08025f30
	movw r5, #0x1070
	movt r5, #0x2000
	movs r6, #0x0
	b.n .L08025bda
	.short 0xbf00	@ padding
.L08025bc8:
	ldr r1, [r5, #0x0]
	movs r0, #0x0
	blx r1
.L08025bce:
	movw r3, #0xf8
	movt r3, #0x2000
.L08025bd6:
	cmp r4, #0x0
	beq.n .L08025cc6
.L08025bda:
	ldr r0, [r4, #0x4]
	mov r7, r4
	ldr r4, [r4, #0x10]
	cbz r0, .L08025c18
	ldrb r1, [r5, #0x10]
	cbz r1, .L08025c08
	ldr r1, [r5, #0x8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L08025c16
	ldr r2, [r5, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r2, r0, lsl #0x1]
	cbz r1, .L08025c16
	add.w r0, r2, r0, lsl #0x1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L08025c0e
	.short 0xbf00	@ padding
.L08025c08:
	ldr r1, [r5, #0x0]
	movs r0, #0x0
	blx r1
.L08025c0e:
	movw r3, #0xf8
	movt r3, #0x2000
.L08025c16:
	str r6, [r7, #0x4]
.L08025c18:
	ldr r0, [r7, #0x8]
	cbz r0, .L08025c50
	ldrb r1, [r5, #0x10]
	cbz r1, .L08025c40
	ldr r1, [r5, #0x8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L08025c4e
	ldr r2, [r5, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r2, r0, lsl #0x1]
	cbz r1, .L08025c4e
	add.w r0, r2, r0, lsl #0x1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L08025c46
.L08025c40:
	ldr r1, [r5, #0x0]
	movs r0, #0x0
	blx r1
.L08025c46:
	movw r3, #0xf8
	movt r3, #0x2000
.L08025c4e:
	str r6, [r7, #0x8]
.L08025c50:
	ldrb r0, [r5, #0x10]
	cmp r0, #0x0
	beq.n .L08025bc8
	ldr r0, [r5, #0x8]
	subs r0, r7, r0
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L08025bd6
	ldr r2, [r5, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r2, r0, lsl #0x1]
	cmp r1, #0x0
	beq.n .L08025bd6
	add.w r0, r2, r0, lsl #0x1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L08025bce
.L08025c78:
	ldrb.w r0, [r3, #0x44]
	cbz r0, .L08025ccc
	ldr r6, [r3, #0x40]
	cmp r6, #0x0
	beq.w .L08025f30
	ldr r0, [r6, #0x4]
	ldr r4, [r6, #0x10]
	movw r5, #0x1070
	cmp r0, #0x0
	movt r5, #0x2000
	beq.w .L08025f48
	ldrb r1, [r5, #0x10]
	cmp r1, #0x0
	beq.w .L08025f36
	ldr r1, [r5, #0x8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.w .L08025f44
	ldr r2, [r5, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r2, r0, lsl #0x1]
	cmp r1, #0x0
	beq.w .L08025f44
	add.w r0, r2, r0, lsl #0x1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L08025f3c
.L08025cc6:
	movs r0, #0x0
	str r0, [r3, #0x40]
	b.n .L08025f30
.L08025ccc:
	add.w r0, r3, #0x40
.L08025cd0:
	ldr r1, [r0, #0x0]
	mov r4, r0
	cbz r1, .L08025cf4
	add.w r4, r1, #0x10
	ldr r0, [r4, #0x0]
	cbz r0, .L08025cf4
	add.w r4, r0, #0x10
	ldr r0, [r4, #0x0]
	cbz r0, .L08025cf4
	add.w r4, r0, #0x10
	ldr r0, [r4, #0x0]
	cmp r0, #0x0
	add.w r0, r0, #0x10
	bne.n .L08025cd0
.L08025cf4:
	movs r0, #0x14
	bl alloc_units_of_32_bytes
	movw r6, #0xf8
	cmp r0, #0x0
	movt r6, #0x2000
	str r0, [r4, #0x0]
	beq.w .L08025f30
	movs r1, #0xff
	strb r1, [r0, #0x0]
	ldr.w r1, [r6, #0xdb4]
	str r1, [r0, #0xc]
	movs r1, #0x0
	str r1, [r0, #0x4]
	ldr r0, [r4, #0x0]
	str r1, [r0, #0x8]
	ldrb r0, [r6, #0x15]
	ldr r2, [r4, #0x0]
	and.w r3, r0, #0xf
	cmp.w r3, r0, lsr #0x4
	str r1, [r2, #0x10]
	bls.w .L08025f30
	lsrs r5, r0, #0x4
	movw r8, #0x12d
	smlabb r0, r5, r8, r6
	addw r7, r0, #0x356
	b.n .L08025d52
	.short 0xbf00	@ padding
.L08025d40:
	ldrb r0, [r6, #0x15]
	adds r5, #0x1
	and.w r0, r0, #0xf
	cmp r5, r0
	addw r7, r7, #0x12d
	bcs.w .L08025f30
.L08025d52:
	ldr r1, [r4, #0x0]
	add.w r0, r1, r5, lsl #0x2
	ldr r0, [r0, #0x4]
	cbnz r0, .L08025d7a
	ldrh r0, [r1, #0xe]
	bl alloc_units_of_32_bytes
	ldr r1, [r4, #0x0]
	movw r6, #0xf8
	add.w r1, r1, r5, lsl #0x2
	str r0, [r1, #0x4]
	ldr r0, [r4, #0x0]
	movt r6, #0x2000
	add.w r0, r0, r5, lsl #0x2
	ldr r0, [r0, #0x4]
.L08025d7a:
	cmp r0, #0x0
	beq.n .L08025d40
	ldrh.w r1, [r6, #0xdb6]
	cmp r1, #0x0
	beq.n .L08025d40
	ldrh.w r1, [r6, #0xdb4]
	mla r2, r5, r8, r6
	add r1, r2
	ldrb.w r1, [r1, #0x356]
	strb r1, [r0, #0x0]
	ldrh.w r0, [r6, #0xdb6]
	cmp r0, #0x2
	bcc.n .L08025d40
	movs r0, #0x1
	mov r1, r7
	nop
.L08025da4:
	ldr r2, [r4, #0x0]
	ldrh.w r3, [r6, #0xdb4]
	add.w r2, r2, r5, lsl #0x2
	add r3, r1
	ldr r2, [r2, #0x4]
	ldrb r3, [r3, #0x1]
	adds r1, #0x1
	strb r3, [r2, r0]
	ldrh.w r2, [r6, #0xdb6]
	adds r0, #0x1
	cmp r0, r2
	bcc.n .L08025da4
	b.n .L08025d40
.L08025dc4:
	ldrb r0, [r3, #0x15]
	and.w r1, r0, #0xf
	cmp.w r1, r0, lsr #0x4
	bls.w .L08025f30
	lsrs r7, r0, #0x4
	movw r9, #0xffff
	mov.w r10, #0x1
	movs r5, #0x1a
	b.n .L08025dee
.L08025de0:
	ldrb r0, [r3, #0x15]
	adds r7, #0x1
	and.w r0, r0, #0xf
	cmp r7, r0
	bcs.w .L08025f30
.L08025dee:
	add.w r0, r8, r7, lsl #0x2
	ldr r0, [r0, #0x4]
	cbnz r0, .L08025e38
	movw r0, #0x1e92
	bl alloc_units_of_32_bytes
	movw r1, #0xf8
	movt r1, #0x2000
	ldr r1, [r1, #0x40]
	add.w r1, r1, r7, lsl #0x2
	str r0, [r1, #0x4]
	movw r0, #0xf8
	movt r0, #0x2000
	ldr.w r8, [r0, #0x40]
	movw r1, #0x1e92
	add.w r5, r8, r7, lsl #0x2
	ldr r0, [r5, #0x4]
	bl zero_bytes
	ldr r0, [r5, #0x4]
	movw r3, #0xf8
	movt r3, #0x2000
	movs r5, #0x1a
	cmp r0, #0x0
	beq.n .L08025de0
.L08025e38:
	ldrh.w r0, [r8, #0xe]
	cmp r0, #0x2
	bcc.n .L08025de0
	ldrh.w r0, [r8, #0xc]
	ldrh.w r2, [r8, #0xe]
	ldrh.w r1, [r8, #0xc]
	add r0, r2
	subs r0, #0x1
	cmp r0, r1
	ble.n .L08025de0
	mov r11, r1
	str r7, [sp, #0x4]
	b.n .L08025ea0
	.short 0xbf00	@ padding
.L08025e5c:
	ldr r2, [sp, #0x8]
	movs r5, #0x1a
	and.w r0, r3, #0x7
	smulbb r2, r5, r2
	add.w r3, r3, r12, lsr #0xd
	add.w r2, r2, r3, asr #0x3
	ldrb r3, [r1, r2]
	lsl.w r0, r10, r0
	orrs r0, r3
	movw r3, #0xf8
	strb r0, [r1, r2]
	movt r3, #0x2000
	ldr.w r8, [r3, #0x40]
	add.w r11, r11, #0x1
	ldrh.w r0, [r8, #0xc]
	ldrh.w r2, [r8, #0xe]
	uxth.w r1, r11
	add r0, r2
	subs r0, #0x1
	ldr r7, [sp, #0x4]
	cmp r0, r1
	ble.n .L08025de0
.L08025ea0:
	movw r0, #0x12d
	mla r2, r7, r0, r3
	adds r0, r1, #0x1
	addw r2, r2, #0x356
	ldrb r4, [r2, r1]
	ldrb r2, [r2, r0]
	sub.w r6, r4, #0x1c
	uxth.w lr, r6
	add.w r1, r8, r7, lsl #0x2
	sub.w r3, r2, #0x1c
	ldr r1, [r1, #0x4]
	cmp r4, r2
	smulbb r4, r5, r11
	add.w r2, r6, lr, lsr #0xd
	add.w r7, r4, r2, asr #0x3
	and.w r8, r6, #0x7
	ldrb r2, [r1, r7]
	str r0, [sp, #0x8]
	lsl.w r0, r10, r8
	orr.w r0, r0, r2
	mov.w r2, #0x0
	it cc
	movcc r2, #0x1
	it hi
	movhi r2, r9
	add r2, r6
	uxth.w r12, r3
	uxth r6, r2
	cmp r6, r12
	strb r0, [r1, r7]
	beq.n .L08025e5c
.L08025efc:
	sxth r0, r2
	ubfx r6, r0, #0x1c, #0x3
	add r6, r2
	sxth r6, r6
	add.w r6, r4, r6, asr #0x3
	cmp r0, r3
	mov.w r0, #0x0
	ldrb r5, [r1, r6]
	it lt
	movlt r0, #0x1
	and.w r7, r2, #0x7
	it gt
	movgt r0, r9
	add r2, r0
	lsl.w r7, r10, r7
	uxth r0, r2
	orrs r7, r5
	cmp r0, r12
	strb r7, [r1, r6]
	bne.n .L08025efc
	b.n .L08025e5c
.L08025f30:
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08025f36:
	ldr r1, [r5, #0x0]
	movs r0, #0x0
	blx r1
.L08025f3c:
	movw r3, #0xf8
	movt r3, #0x2000
.L08025f44:
	movs r0, #0x0
	str r0, [r6, #0x4]
.L08025f48:
	ldr r0, [r6, #0x8]
	cbz r0, .L08025f82
	ldrb r1, [r5, #0x10]
	cbz r1, .L08025f70
	ldr r1, [r5, #0x8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L08025f7e
	ldr r2, [r5, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r2, r0, lsl #0x1]
	cbz r1, .L08025f7e
	add.w r0, r2, r0, lsl #0x1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L08025f76
.L08025f70:
	ldr r1, [r5, #0x0]
	movs r0, #0x0
	blx r1
.L08025f76:
	movw r3, #0xf8
	movt r3, #0x2000
.L08025f7e:
	movs r0, #0x0
	str r0, [r6, #0x8]
.L08025f82:
	ldrb r0, [r5, #0x10]
	cbz r0, .L08025fa6
	ldr r0, [r5, #0x8]
	subs r0, r6, r0
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L08025fb4
	ldr r2, [r5, #0xc]
	lsrs r0, r0, #0x5
	ldrh.w r1, [r2, r0, lsl #0x1]
	cbz r1, .L08025fb4
	add.w r0, r2, r0, lsl #0x1
	lsls r1, r1, #0x1
	bl zero_bytes
	b.n .L08025fac
.L08025fa6:
	ldr r1, [r5, #0x0]
	movs r0, #0x0
	blx r1
.L08025fac:
	movw r3, #0xf8
	movt r3, #0x2000
.L08025fb4:
	str r4, [r3, #0x40]
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.word 0x00000000	@ padding
