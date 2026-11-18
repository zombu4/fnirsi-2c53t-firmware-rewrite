@ siggen_55.s - fill_output_waveform_table: builds the 100-point output waveform table at 0x20000f5a from the shape, amplitude and width bytes.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fill_output_waveform_table - no parameters, no return value.
@ Does nothing when byte 0x20000f51 (shape) >= 13; otherwise fills 100 halfwords
@ at 0x20000f5a..0x20001021 (the table whose address 0x0802aa50 stores in
@ 0x40020450 with count 100) by a switch on byte 0x20000f51, using amplitude
@ a = byte 0x20000f59, width w = byte 0x20000f58 and A = a*0xfff/0x21.
@ Case 0: table[i] = (a * u16 0x0804d848[i]) / 0x21 + 0x14. Cases 3, 4, 7, 8, 10,
@ 11, 12 (default) do the same with the u16 table at base + case*200 + 2*i, with
@ bases 0x0804d6b8 (cases 3, 4), 0x0804d528 (cases 7, 8) and 0x0804d460 (cases
@ 10-12), all inside the 200-byte tables starting at 0x0804d848 + 200*k.
@ The tables are reached only from the anchor d_0804d848 (+ 200*case - 0x3d6..
@ 0x3e8), so src/rodata.s keeps the 1600-byte block 0x0804d848..0x0804de87 as
@ one unit with this inner layout (guard there).
@ Case 1: A + 0x14 for i < w, 0x14 for i >= w.
@ Case 2: triangle, (i*A)/w + 0x14 for i < w, then A*(100-i)/(100-w) + 0x14.
@ Case 5: staircase table[i] = A7 * ((8*i)/100) + 0x14 with A7 = a*0xfff/231
@ (computed as a*0xfff * 0x11bb4a405 >> 40, which equals division by 231).
@ Case 6: table[i] = (A - A7 * ((8*i)/100)) + 0x14.
@ Case 9: A + 0x14 for all 100 entries.
@ Purpose: builds the 100-point output waveform table (shape byte 0x20000f51,
@ amplitude byte 0x20000f59, width byte 0x20000f58) whose address 0x20000f5a is
@ stored by 0x0802aa50 into 0x40020450 together with 0x40020448 = 100 and
@ 0x4002044c = 0x40007414; what reads the table is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fill_output_waveform_table,"ax",%progbits
	.global fill_output_waveform_table
	.thumb_func
	.type fill_output_waveform_table, %function
fill_output_waveform_table:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x38
	movw r6, #0xf8
	movt r6, #0x2000
	ldrb.w r2, [r6, #0xe59]
	cmp r2, #0xc
	bhi.w .L0802a98c
	tbh [pc, r2, lsl #1]
.L08029e30:
	.short (.L0802a1ce - .L08029e30)/2
	.short (.L0802a2a0 - .L08029e30)/2
	.short (.L0802a424 - .L08029e30)/2
	.short (.L08029f78 - .L08029e30)/2
	.short (.L08029f78 - .L08029e30)/2
	.short (.L0802a600 - .L08029e30)/2
	.short (.L0802a7d4 - .L08029e30)/2
	.short (.L0802a0a4 - .L08029e30)/2
	.short (.L0802a0a4 - .L08029e30)/2
	.short 0x0569
	.short 0x000d
	.short 0x000d
	.short 0x000d

@ cases 10, 11, 12 and default of the table: u16 table at 0x0804d460 + 2*i
.L08029e4a:
	movw r0, #:lower16:d_0804d848
	movt r0, #:upper16:d_0804d848
	movs r3, #0xc8
	smlabb r7, r2, r3, r0
	subw r0, r7, #0x3d6
	str r0, [sp, #0x2c]
	sub.w r0, r7, #0x3e8
	str r0, [sp, #0x28]
	sub.w r0, r7, #0x3d8
	str r0, [sp, #0x24]
	subw r0, r7, #0x3da
	str r0, [sp, #0x20]
	subw r0, r7, #0x3e6
	str r0, [sp, #0x1c]
	sub.w r0, r7, #0x3dc
	str r0, [sp, #0x18]
	sub.w r0, r7, #0x3e4
	str r0, [sp, #0x14]
	subw r0, r7, #0x3de
	ldrb.w r1, [r6, #0xe61]
	str r0, [sp, #0x10]
	subw r0, r7, #0x3e2
	movw r5, #0x83e1
	str r0, [sp, #0xc]
	sub.w r0, r7, #0x3e0
	movs r6, #0x0
	movt r5, #0x3e0f
	mov.w r12, #0x14
	str r0, [sp, #0x8]
	nop
.L08029ea8:
	ldr r0, [sp, #0x28]
	movw r2, #0xf8
	ldrh r4, [r0, r6]
	ldr r0, [sp, #0x1c]
	muls r4, r1, r4
	umull r4, r8, r4, r5
	ldrh r4, [r0, r6]
	movt r2, #0x2000
	muls r4, r1, r4
	umull r4, r0, r4, r5
	str r0, [sp, #0x34]
	ldr r0, [sp, #0x14]
	add.w r8, r12, r8, lsr #3
	ldrh r4, [r0, r6]
	muls r4, r1, r4
	umull r4, r0, r4, r5
	str r0, [sp, #0x30]
	ldr r0, [sp, #0xc]
	ldrh r4, [r0, r6]
	ldr r0, [sp, #0x8]
	muls r4, r1, r4
	umull r4, r10, r4, r5
	ldrh r4, [r0, r6]
	ldr r0, [sp, #0x10]
	muls r4, r1, r4
	umull r4, r11, r4, r5
	ldrh r4, [r0, r6]
	ldr r0, [sp, #0x18]
	muls r4, r1, r4
	umull r4, r9, r4, r5
	ldrh r4, [r0, r6]
	ldr r0, [sp, #0x20]
	muls r4, r1, r4
	umull r4, lr, r4, r5
	ldrh r4, [r0, r6]
	ldr r0, [sp, #0x24]
	muls r4, r1, r4
	umull r4, r3, r4, r5
	ldrh r4, [r0, r6]
	ldr r0, [sp, #0x2c]
	muls r4, r1, r4
	umull r4, r7, r4, r5
	ldrh r4, [r0, r6]
	muls r4, r1, r4
	umull r4, r0, r4, r5
	adds r4, r2, r6
	ldr r2, [sp, #0x34]
	adds r6, #0x14
	add.w r2, r12, r2, lsr #3
	strh.w r2, [r4, #0xe64]
	ldr r2, [sp, #0x30]
	add.w r0, r12, r0, lsr #3
	add.w r2, r12, r2, lsr #3
	strh.w r2, [r4, #0xe66]
	add.w r2, r12, r10, lsr #3
	strh.w r2, [r4, #0xe68]
	add.w r2, r12, r11, lsr #3
	strh.w r2, [r4, #0xe6a]
	add.w r2, r12, r9, lsr #3
	strh.w r2, [r4, #0xe6c]
	add.w r2, r12, lr, lsr #3
	strh.w r2, [r4, #0xe6e]
	add.w r2, r12, r3, lsr #3
	strh.w r2, [r4, #0xe70]
	add.w r2, r12, r7, lsr #3
	cmp r6, #0xc8
	strh.w r8, [r4, #0xe62]
	strh.w r2, [r4, #0xe72]
	strh.w r0, [r4, #0xe74]
	bne.n .L08029ea8
	b.w .L0802a98c

@ cases 3 and 4: u16 table at 0x0804d6b8 + 2*i
.L08029f78:
	movw r0, #:lower16:d_0804d848
	movt r0, #:upper16:d_0804d848
	movs r3, #0xc8
	smlabb r7, r2, r3, r0
	sub.w r0, r7, #0x17e
	str r0, [sp, #0x2c]
	sub.w r0, r7, #0x190
	str r0, [sp, #0x28]
	sub.w r0, r7, #0x180
	str r0, [sp, #0x24]
	sub.w r0, r7, #0x182
	str r0, [sp, #0x20]
	sub.w r0, r7, #0x18e
	str r0, [sp, #0x1c]
	sub.w r0, r7, #0x184
	str r0, [sp, #0x18]
	sub.w r0, r7, #0x18c
	str r0, [sp, #0x14]
	sub.w r0, r7, #0x186
	ldrb.w r1, [r6, #0xe61]
	str r0, [sp, #0x10]
	sub.w r0, r7, #0x18a
	movw r5, #0x83e1
	str r0, [sp, #0xc]
	sub.w r0, r7, #0x188
	movs r6, #0x0
	movt r5, #0x3e0f
	movs r4, #0x14
	str r0, [sp, #0x8]
	nop
.L08029fd4:
	ldr r0, [sp, #0x28]
	ldrh r0, [r0, r6]
	muls r0, r1, r0
	umull r0, r3, r0, r5
	ldr r0, [sp, #0x1c]
	add.w r8, r4, r3, lsr #3
	ldrh r0, [r0, r6]
	muls r0, r1, r0
	umull r0, r2, r0, r5
	ldr r0, [sp, #0x14]
	str r2, [sp, #0x34]
	ldrh r0, [r0, r6]
	ldr r3, [sp, #0x34]
	muls r0, r1, r0
	umull r0, r2, r0, r5
	ldr r0, [sp, #0xc]
	str r2, [sp, #0x30]
	ldrh r0, [r0, r6]
	add.w r3, r4, r3, lsr #3
	muls r0, r1, r0
	umull r0, r10, r0, r5
	ldr r0, [sp, #0x8]
	ldrh r0, [r0, r6]
	muls r0, r1, r0
	umull r0, r11, r0, r5
	ldr r0, [sp, #0x10]
	ldrh r0, [r0, r6]
	muls r0, r1, r0
	umull r0, r9, r0, r5
	ldr r0, [sp, #0x18]
	ldrh r0, [r0, r6]
	muls r0, r1, r0
	umull r0, lr, r0, r5
	ldr r0, [sp, #0x20]
	ldrh r0, [r0, r6]
	muls r0, r1, r0
	umull r0, r12, r0, r5
	ldr r0, [sp, #0x24]
	ldrh r0, [r0, r6]
	muls r0, r1, r0
	umull r0, r7, r0, r5
	ldr r0, [sp, #0x2c]
	ldrh r0, [r0, r6]
	muls r0, r1, r0
	umull r0, r2, r0, r5
	movw r0, #0xf8
	movt r0, #0x2000
	add r0, r6
	strh.w r3, [r0, #0xe64]
	ldr r3, [sp, #0x30]
	adds r6, #0x14
	add.w r3, r4, r3, lsr #3
	strh.w r3, [r0, #0xe66]
	add.w r3, r4, r10, lsr #3
	strh.w r3, [r0, #0xe68]
	add.w r3, r4, r11, lsr #3
	strh.w r3, [r0, #0xe6a]
	add.w r3, r4, r9, lsr #3
	strh.w r3, [r0, #0xe6c]
	add.w r3, r4, lr, lsr #3
	strh.w r3, [r0, #0xe6e]
	add.w r3, r4, r12, lsr #3
	strh.w r3, [r0, #0xe70]
	add.w r3, r4, r7, lsr #3
	add.w r2, r4, r2, lsr #3
	cmp r6, #0xc8
	strh.w r8, [r0, #0xe62]
	strh.w r3, [r0, #0xe72]
	strh.w r2, [r0, #0xe74]
	bne.n .L08029fd4
	b.w .L0802a98c

@ cases 7 and 8: u16 table at 0x0804d528 + 2*i
.L0802a0a4:
	movw r1, #:lower16:d_0804d848
	movt r1, #:upper16:d_0804d848
	movs r3, #0xc8
	smlabb r3, r2, r3, r1
	subw r1, r3, #0x30e
	str r1, [sp, #0x2c]
	sub.w r1, r3, #0x320
	str r1, [sp, #0x28]
	sub.w r1, r3, #0x310
	str r1, [sp, #0x24]
	subw r1, r3, #0x312
	str r1, [sp, #0x20]
	subw r1, r3, #0x31e
	str r1, [sp, #0x1c]
	sub.w r1, r3, #0x314
	str r1, [sp, #0x18]
	sub.w r1, r3, #0x31c
	str r1, [sp, #0x14]
	subw r1, r3, #0x316
	ldrb.w r0, [r6, #0xe61]
	str r1, [sp, #0x10]
	subw r1, r3, #0x31a
	movw r6, #0x83e1
	str r1, [sp, #0xc]
	sub.w r1, r3, #0x318
	movs r7, #0x0
	movt r6, #0x3e0f
	movs r5, #0x14
	str r1, [sp, #0x8]
	nop
.L0802a100:
	ldr r1, [sp, #0x28]
	movw r2, #0xf8
	ldrh r4, [r1, r7]
	ldr r1, [sp, #0x1c]
	muls r4, r0, r4
	umull r4, lr, r4, r6
	ldrh r4, [r1, r7]
	movt r2, #0x2000
	muls r4, r0, r4
	umull r4, r1, r4, r6
	str r1, [sp, #0x34]
	ldr r1, [sp, #0x14]
	add.w lr, r5, lr, lsr #3
	ldrh r4, [r1, r7]
	muls r4, r0, r4
	umull r4, r1, r4, r6
	str r1, [sp, #0x30]
	ldr r1, [sp, #0xc]
	ldrh r4, [r1, r7]
	ldr r1, [sp, #0x8]
	muls r4, r0, r4
	umull r4, r9, r4, r6
	ldrh r4, [r1, r7]
	ldr r1, [sp, #0x10]
	muls r4, r0, r4
	umull r4, r10, r4, r6
	ldrh r4, [r1, r7]
	ldr r1, [sp, #0x18]
	muls r4, r0, r4
	umull r4, r11, r4, r6
	ldrh r4, [r1, r7]
	ldr r1, [sp, #0x20]
	muls r4, r0, r4
	umull r4, r8, r4, r6
	ldrh r4, [r1, r7]
	ldr r1, [sp, #0x24]
	muls r4, r0, r4
	umull r4, r12, r4, r6
	ldrh r4, [r1, r7]
	ldr r1, [sp, #0x2c]
	muls r4, r0, r4
	umull r4, r3, r4, r6
	ldrh r4, [r1, r7]
	muls r4, r0, r4
	umull r4, r1, r4, r6
	adds r4, r2, r7
	ldr r2, [sp, #0x34]
	adds r7, #0x14
	add.w r2, r5, r2, lsr #3
	strh.w r2, [r4, #0xe64]
	ldr r2, [sp, #0x30]
	add.w r1, r5, r1, lsr #3
	add.w r2, r5, r2, lsr #3
	strh.w r2, [r4, #0xe66]
	add.w r2, r5, r9, lsr #3
	strh.w r2, [r4, #0xe68]
	add.w r2, r5, r10, lsr #3
	strh.w r2, [r4, #0xe6a]
	add.w r2, r5, r11, lsr #3
	strh.w r2, [r4, #0xe6c]
	add.w r2, r5, r8, lsr #3
	strh.w r2, [r4, #0xe6e]
	add.w r2, r5, r12, lsr #3
	strh.w r2, [r4, #0xe70]
	add.w r2, r5, r3, lsr #3
	cmp r7, #0xc8
	strh.w lr, [r4, #0xe62]
	strh.w r2, [r4, #0xe72]
	strh.w r1, [r4, #0xe74]
	bne.n .L0802a100
	b.n .L0802a98c

@ case 0: u16 table at 0x0804d848 + 2*i
.L0802a1ce:
	ldrb.w r0, [r6, #0xe61]
	movw r3, #0x83e1
	movs r1, #0x0
	movt r3, #0x3e0f
	movs r7, #0x14
	nop
.L0802a1e0:
	movw r6, #:lower16:d_0804d848
	movt r6, #:upper16:d_0804d848
	ldrh r2, [r6, r1]
	adds r5, r6, r1
	muls r2, r0, r2
	umull r2, r8, r2, r3
	ldrh r2, [r5, #0x2]
	add.w r8, r7, r8, lsr #3
	muls r2, r0, r2
	umull r2, r6, r2, r3
	ldrh r2, [r5, #0x4]
	add.w r6, r7, r6, lsr #3
	muls r2, r0, r2
	umull r4, r2, r2, r3
	ldrh r4, [r5, #0x6]
	str r2, [sp, #0x34]
	muls r4, r0, r4
	umull r4, r10, r4, r3
	ldrh r4, [r5, #0x8]
	muls r4, r0, r4
	umull r2, r11, r4, r3
	ldrh r2, [r5, #0xa]
	muls r2, r0, r2
	umull r2, r9, r2, r3
	ldrh r2, [r5, #0xc]
	muls r2, r0, r2
	umull r2, r4, r2, r3
	ldrh r2, [r5, #0xe]
	add.w r4, r7, r4, lsr #3
	muls r2, r0, r2
	umull r2, lr, r2, r3
	ldrh r2, [r5, #0x10]
	muls r2, r0, r2
	umull r2, r12, r2, r3
	ldrh r2, [r5, #0x12]
	muls r2, r0, r2
	umull r2, r5, r2, r3
	movw r2, #0xf8
	movt r2, #0x2000
	add r2, r1
	strh.w r6, [r2, #0xe64]
	ldr r6, [sp, #0x34]
	adds r1, #0x14
	add.w r6, r7, r6, lsr #3
	strh.w r6, [r2, #0xe66]
	add.w r6, r7, r10, lsr #3
	strh.w r6, [r2, #0xe68]
	add.w r6, r7, r11, lsr #3
	strh.w r6, [r2, #0xe6a]
	add.w r6, r7, r9, lsr #3
	strh.w r6, [r2, #0xe6c]
	add.w r6, r7, lr, lsr #3
	strh.w r6, [r2, #0xe70]
	add.w r6, r7, r12, lsr #3
	strh.w r6, [r2, #0xe72]
	add.w r6, r7, r5, lsr #3
	cmp r1, #0xc8
	strh.w r8, [r2, #0xe62]
	strh.w r4, [r2, #0xe6e]
	strh.w r6, [r2, #0xe74]
	bne.n .L0802a1e0
	b.n .L0802a98c

@ case 1: A + 0x14 for i < w, 0x14 for i >= w
.L0802a2a0:
	ldrb.w r0, [r6, #0xe61]
	movw r1, #0x83e1
	rsb r0, r0, r0, lsl #12
	movt r1, #0x3e0f
	umull r0, r2, r0, r1
	ldrb.w r1, [r6, #0xe60]
	movs r0, #0x14
	add.w r2, r0, r2, lsr #3
	addw r0, r6, #0xe88
	movs r3, #0x0
.L0802a2c4:
	movs r7, #0x14
	cmp r3, r1
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x26]
	adds r7, r3, #0x1
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x24]
	adds r7, r3, #0x2
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x22]
	adds r7, r3, #0x3
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x20]
	adds r7, r3, #0x4
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x1e]
	adds r7, r3, #0x5
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x1c]
	adds r7, r3, #0x6
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x1a]
	adds r7, r3, #0x7
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x18]
	add.w r7, r3, #0x8
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x16]
	add.w r7, r3, #0x9
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x14]
	add.w r7, r3, #0xa
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x12]
	add.w r7, r3, #0xb
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x10]
	add.w r7, r3, #0xc
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0xe]
	add.w r7, r3, #0xd
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0xc]
	add.w r7, r3, #0xe
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0xa]
	add.w r7, r3, #0xf
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x8]
	add.w r7, r3, #0x10
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x6]
	add.w r7, r3, #0x11
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x4]
	add.w r7, r3, #0x12
	cmp r7, r1
	mov.w r7, #0x14
	it cc
	movcc r7, r2
	strh.w r7, [r0, #-0x2]
	add.w r7, r3, #0x13
	cmp r7, r1
	mov.w r7, #0x14
	add.w r3, r3, #0x14
	it cc
	movcc r7, r2
	cmp r3, #0x64
	strh.w r7, [r0], #0x28
	bne.w .L0802a2c4
	b.n .L0802a98c

@ case 2: triangle
.L0802a424:
	ldrb.w r0, [r6, #0xe61]
	movw r1, #0x83e1
	rsb r0, r0, r0, lsl #12
	movt r1, #0x3e0f
	umull r0, r7, r0, r1
	lsrs r2, r7, #0x3
	movs r0, #0x64
	muls r0, r2, r0
	str r0, [sp, #0x34]
	movs r0, #0x5b
	muls r0, r2, r0
	str r0, [sp, #0x30]
	movs r0, #0x5c
	muls r0, r2, r0
	str r0, [sp, #0x2c]
	movs r0, #0x5d
	lsls r5, r2, #0x3
	muls r0, r2, r0
	strd r0, r5, [sp, #0x24]
	sub.w r0, r5, r7, lsr #3
	str r0, [sp, #0x20]
	movs r0, #0x5e
	muls r0, r2, r0
	str r0, [sp, #0x1c]
	movs r0, #0x5f
	muls r0, r2, r0
	str r0, [sp, #0x18]
	movs r0, #0x63
	muls r0, r2, r0
	str r0, [sp, #0x14]
	movs r0, #0x61
	muls r0, r2, r0
	ldrb.w r1, [r6, #0xe60]
	str r0, [sp, #0x10]
	movs r0, #0x62
	add.w r7, r2, r2, lsl #3
	add.w r10, r2, r2, lsl #1
	muls r0, r2, r0
	add.w lr, r2, r2, lsl #2
	str r7, [sp, #0x8]
	lsl.w r7, r10, #1
	rsb.w r3, r1, #0x64
	str r0, [sp, #0xc]
	addw r0, r6, #0xe74
	lsl.w r8, lr, #1
	str r7, [sp, #0x4]
	lsl.w r7, r10, #5
	lsl.w r11, r2, #2
	lsls r5, r2, #1
	movs r4, #0x0
	mov.w r12, #0x0
	mov.w r9, #0x0
	str r7, [sp, #0x0]
	b.n .L0802a4d8
	.short 0xbf00 @ padding
.L0802a4b8:
	ldr r7, [sp, #0x8]
	add r7, r4
	udiv r7, r7, r1
.L0802a4c0:
	adds r7, #0x14
	add.w r9, r6, #0x1
	strh.w r7, [r0], #0x14
	sub.w r12, r12, r8
	cmp.w r9, #0x64
	add r4, r8
	beq.w .L0802a98c
.L0802a4d8:
	cmp r9, r1
	bcs.n .L0802a4e4
	udiv r6, r4, r1
	b.n .L0802a4ec
	.short 0xbf00 @ padding
.L0802a4e4:
	ldr r6, [sp, #0x34]
	add r6, r12
	sdiv r6, r6, r3
.L0802a4ec:
	add.w r7, r6, #0x14
	add.w r6, r9, #0x1
	cmp r6, r1
	strh.w r7, [r0, #-0x12]
	bcs.n .L0802a504
	adds r7, r2, r4
	udiv r7, r7, r1
	b.n .L0802a50c
.L0802a504:
	ldr r7, [sp, #0x14]
	add r7, r12
	sdiv r7, r7, r3
.L0802a50c:
	adds r6, #0x1
	adds r7, #0x14
	cmp r6, r1
	strh.w r7, [r0, #-0x10]
	bcs.n .L0802a520
	adds r7, r5, r4
	udiv r7, r7, r1
	b.n .L0802a528
.L0802a520:
	ldr r7, [sp, #0xc]
	add r7, r12
	sdiv r7, r7, r3
.L0802a528:
	adds r6, #0x1
	adds r7, #0x14
	cmp r6, r1
	strh.w r7, [r0, #-0xe]
	bcs.n .L0802a540
	add.w r7, r10, r4
	udiv r7, r7, r1
	b.n .L0802a548
	.short 0xbf00 @ padding
.L0802a540:
	ldr r7, [sp, #0x10]
	add r7, r12
	sdiv r7, r7, r3
.L0802a548:
	adds r6, #0x1
	adds r7, #0x14
	cmp r6, r1
	strh.w r7, [r0, #-0xc]
	bcs.n .L0802a560
	add.w r7, r11, r4
	udiv r7, r7, r1
	b.n .L0802a568
	.short 0xbf00 @ padding
.L0802a560:
	ldr r7, [sp, #0x0]
	add r7, r12
	sdiv r7, r7, r3
.L0802a568:
	adds r6, #0x1
	adds r7, #0x14
	cmp r6, r1
	strh.w r7, [r0, #-0xa]
	bcs.n .L0802a580
	add.w r7, lr, r4
	udiv r7, r7, r1
	b.n .L0802a588
	.short 0xbf00 @ padding
.L0802a580:
	ldr r7, [sp, #0x18]
	add r7, r12
	sdiv r7, r7, r3
.L0802a588:
	adds r6, #0x1
	adds r7, #0x14
	cmp r6, r1
	strh.w r7, [r0, #-0x8]
	bcs.n .L0802a5a0
	ldr r7, [sp, #0x4]
	add r7, r4
	udiv r7, r7, r1
	b.n .L0802a5a8
	.short 0xbf00 @ padding
.L0802a5a0:
	ldr r7, [sp, #0x1c]
	add r7, r12
	sdiv r7, r7, r3
.L0802a5a8:
	adds r6, #0x1
	adds r7, #0x14
	cmp r6, r1
	strh.w r7, [r0, #-0x6]
	bcs.n .L0802a5c0
	ldr r7, [sp, #0x20]
	add r7, r4
	udiv r7, r7, r1
	b.n .L0802a5c8
	.short 0xbf00 @ padding
.L0802a5c0:
	ldr r7, [sp, #0x24]
	add r7, r12
	sdiv r7, r7, r3
.L0802a5c8:
	adds r6, #0x1
	adds r7, #0x14
	cmp r6, r1
	strh.w r7, [r0, #-0x4]
	bcs.n .L0802a5e0
	ldr r7, [sp, #0x28]
	add r7, r4
	udiv r7, r7, r1
	b.n .L0802a5e8
	.short 0xbf00 @ padding
.L0802a5e0:
	ldr r7, [sp, #0x2c]
	add r7, r12
	sdiv r7, r7, r3
.L0802a5e8:
	adds r6, #0x1
	adds r7, #0x14
	cmp r6, r1
	strh.w r7, [r0, #-0x2]
	bcc.w .L0802a4b8
	ldr r7, [sp, #0x30]
	add r7, r12
	sdiv r7, r7, r3
	b.n .L0802a4c0

@ case 5: staircase, A7 * ((8*i)/100) + 0x14
.L0802a600:
	ldrb.w r0, [r6, #0xe61]
	movw r1, #0xa405
	rsb r0, r0, r0, lsl #12
	movt r1, #0x1bb4
	umull r1, r2, r0, r1
	subs r0, r0, r2
	add.w r0, r2, r0, lsr #1
	movw r3, #0x851f
	lsrs r1, r0, #0x7
	addw r0, r6, #0xe88
	movs r2, #0x98
	movt r3, #0x51eb
	nop
.L0802a62c:
	sub.w r7, r2, #0x98
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x90
	str r6, [sp, #0x34]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x88
	str r6, [sp, #0x30]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x80
	str r6, [sp, #0x2c]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x78
	str r6, [sp, #0x28]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x70
	str r6, [sp, #0x24]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x68
	str r6, [sp, #0x20]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x60
	str r6, [sp, #0x1c]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x58
	str r6, [sp, #0x18]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x50
	str r6, [sp, #0x14]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x48
	str r6, [sp, #0x10]
	umull r7, r6, r7, r3
	sub.w r7, r2, #0x40
	umull r7, r11, r7, r3
	sub.w r7, r2, #0x38
	umull r7, r10, r7, r3
	sub.w r7, r2, #0x30
	umull r7, r9, r7, r3
	sub.w r7, r2, #0x28
	str r6, [sp, #0xc]
	umull r6, r8, r7, r3
	sub.w r6, r2, #0x20
	umull r5, r6, r6, r3
	sub.w r5, r2, #0x18
	umull r4, r5, r5, r3
	sub.w r4, r2, #0x10
	umull r7, r4, r4, r3
	sub.w r7, r2, #0x8
	umull r7, lr, r7, r3
	umull r7, r12, r2, r3
	ldr r7, [sp, #0x34]
	lsrs r6, r6, #0x5
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x26]
	ldr r7, [sp, #0x30]
	lsrs r5, r5, #0x5
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x24]
	ldr r7, [sp, #0x2c]
	lsrs r4, r4, #0x5
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x22]
	ldr r7, [sp, #0x28]
	muls r6, r1, r6
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x20]
	ldr r7, [sp, #0x24]
	muls r5, r1, r5
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x1e]
	ldr r7, [sp, #0x20]
	muls r4, r1, r4
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x1c]
	ldr r7, [sp, #0x1c]
	adds r6, #0x14
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x1a]
	ldr r7, [sp, #0x18]
	adds r5, #0x14
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x18]
	ldr r7, [sp, #0x14]
	adds r4, #0x14
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x16]
	ldr r7, [sp, #0x10]
	adds r2, #0xa0
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x14]
	ldr r7, [sp, #0xc]
	strh.w r6, [r0, #-0x8]
	lsrs r7, r7, #0x5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x12]
	lsr.w r7, r11, #5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x10]
	lsr.w r7, r10, #5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0xe]
	lsr.w r7, r9, #5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0xc]
	lsr.w r7, r8, #5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0xa]
	lsr.w r7, lr, #5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r7, [r0, #-0x2]
	lsr.w r7, r12, #5
	muls r7, r1, r7
	adds r7, #0x14
	strh.w r5, [r0, #-0x6]
	strh.w r4, [r0, #-0x4]
	cmp.w r2, #0x3b8
	strh.w r7, [r0], #0x28
	bne.w .L0802a62c
	b.n .L0802a98c

@ case 6: (A - A7 * ((8*i)/100)) + 0x14
.L0802a7d4:
	ldrb.w r0, [r6, #0xe61]
	movw r1, #0xa405
	rsb r0, r0, r0, lsl #12
	movt r1, #0x1bb4
	umull r1, r2, r0, r1
	movw r1, #0x83e1
	movt r1, #0x3e0f
	umull r1, r3, r0, r1
	subs r0, r0, r2
	add.w r0, r2, r0, lsr #1
	movw r7, #0x851f
	lsrs r0, r0, #0x7
	lsrs r1, r3, #0x3
	addw r2, r6, #0xe74
	movs r3, #0x48
	movt r7, #0x51eb
.L0802a80c:
	sub.w r6, r3, #0x48
	umull r6, r11, r6, r7
	sub.w r6, r3, #0x40
	umull r6, r5, r6, r7
	sub.w r6, r3, #0x38
	str r5, [sp, #0x34]
	umull r6, r5, r6, r7
	sub.w r6, r3, #0x30
	umull r6, r8, r6, r7
	sub.w r6, r3, #0x28
	umull r6, r9, r6, r7
	sub.w r6, r3, #0x20
	umull r6, r10, r6, r7
	sub.w r6, r3, #0x18
	umull r6, lr, r6, r7
	sub.w r6, r3, #0x10
	str r5, [sp, #0x30]
	umull r6, r5, r6, r7
	lsr.w r6, r11, #5
	mls r6, r0, r6, r1
	sub.w r4, r3, #0x8
	umull r4, r11, r4, r7
	umull r4, r12, r3, r7
	add.w r4, r6, #0x14
	ldr r6, [sp, #0x34]
	strh.w r4, [r2, #-0x12]
	lsrs r6, r6, #0x5
	mls r6, r0, r6, r1
	lsrs r5, r5, #0x5
	add.w r4, r6, #0x14
	ldr r6, [sp, #0x30]
	strh.w r4, [r2, #-0x10]
	lsrs r6, r6, #0x5
	mls r6, r0, r6, r1
	mls r5, r0, r5, r1
	add.w r4, r6, #0x14
	lsr.w r6, r8, #5
	mls r6, r0, r6, r1
	strh.w r4, [r2, #-0xe]
	add.w r4, r6, #0x14
	lsr.w r6, r9, #5
	mls r6, r0, r6, r1
	strh.w r4, [r2, #-0xc]
	add.w r4, r6, #0x14
	lsr.w r6, r10, #5
	mls r6, r0, r6, r1
	strh.w r4, [r2, #-0xa]
	add.w r4, r6, #0x14
	lsr.w r6, lr, #5
	mls r6, r0, r6, r1
	adds r3, #0x50
	adds r6, #0x14
	strh.w r6, [r2, #-0x6]
	add.w r6, r5, #0x14
	lsr.w r5, r11, #5
	mls r5, r0, r5, r1
	strh.w r6, [r2, #-0x4]
	add.w r6, r5, #0x14
	lsr.w r5, r12, #5
	mls r5, r0, r5, r1
	strh.w r6, [r2, #-0x2]
	add.w r6, r5, #0x14
	strh.w r4, [r2, #-0x8]
	cmp.w r3, #0x368
	strh.w r6, [r2], #0x14
	bne.n .L0802a80c
	b.n .L0802a98c

@ case 9: A + 0x14 for all 100 entries
.L0802a902:
	ldrb.w r0, [r6, #0xe61]
	movw r1, #0x83e1
	rsb r0, r0, r0, lsl #12
	movt r1, #0x3e0f
	umull r0, r1, r0, r1
	movs r0, #0x14
	mov r3, r6
	add.w r0, r0, r1, lsr #3
	movs r1, #0x0
.L0802a920:
	adds r2, r3, r1
	adds r1, #0x32
	cmp r1, #0xc8
	strh.w r0, [r2, #0xe62]
	strh.w r0, [r2, #0xe64]
	strh.w r0, [r2, #0xe66]
	strh.w r0, [r2, #0xe68]
	strh.w r0, [r2, #0xe6a]
	strh.w r0, [r2, #0xe6c]
	strh.w r0, [r2, #0xe6e]
	strh.w r0, [r2, #0xe70]
	strh.w r0, [r2, #0xe72]
	strh.w r0, [r2, #0xe74]
	strh.w r0, [r2, #0xe76]
	strh.w r0, [r2, #0xe78]
	strh.w r0, [r2, #0xe7a]
	strh.w r0, [r2, #0xe7c]
	strh.w r0, [r2, #0xe7e]
	strh.w r0, [r2, #0xe80]
	strh.w r0, [r2, #0xe82]
	strh.w r0, [r2, #0xe84]
	strh.w r0, [r2, #0xe86]
	strh.w r0, [r2, #0xe88]
	strh.w r0, [r2, #0xe8a]
	strh.w r0, [r2, #0xe8c]
	strh.w r0, [r2, #0xe8e]
	strh.w r0, [r2, #0xe90]
	strh.w r0, [r2, #0xe92]
	bne.n .L0802a920
.L0802a98c:
	add sp, #0x38
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short 0x0000 @ padding
