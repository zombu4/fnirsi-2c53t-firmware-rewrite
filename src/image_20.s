@ image_20.s - parse_jpeg_header: baseline JPEG header parser (part 1 of 2, part 2 is included at the end).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ parse_jpeg_header - parses the header of a baseline JPEG stream (markers 0xffd8
@ start, 0xc0 frame, 0xc4 Huffman table, 0xdb quantisation table, 0xdd restart
@ interval, 0xda scan) into the decoder context r0.
@ Arguments: r0 = decoder context, r1 = input callback (called as r1(ctx,buf,count),
@ stored at r0[0x1d]), r2 = work memory (null returns 5), r3 = work size, fifth
@ argument (the first stack word at entry, read by ldr r0,[sp,#144] at 0x08038f2a
@ after the 9-register push and sub sp,#108) = user word stored at r0[0x1e];
@ r4 is not an argument.
@ Stores r0[0x1b] = r2 + 0x200 and r0[0x1c] = r3 - 0x200 (work size below 0x200
@ returns 3; the first 0x200 bytes become the segment buffer r0[2]), clears halfword
@ r0+0x1a and 0x40 bytes at r0[9] with zero_bytes_aligned (0800857c).
@ Reads 2 bytes (callback result must be 2 else return 2; the byte-swapped halfword
@ must equal 0xffd8 else 6), then 4 bytes per segment (must start with 0xff and have
@ length >= 3 else 6; callback must return 4 else 2). Per marker:
@  - 0xc0 (payload <= 0x200 else 4): stores width r0[7] (bytes +3,+4 big-endian) and
@    height r0[8] (bytes +1,+2); requires 3 components (byte +5, else 8); component 1
@    sampling byte +7 only 0x11/0x21/0x22 (mask 0x30001 over byte-0x11) stored as high
@    nibble r0+0xe and low nibble r0+0xf; components 2 and 3 sampling bytes (+10,+13)
@    must be 0x11; quantiser selectors (bytes +8,+11,+14) must be < 4 and are stored at
@    r0+0x10, +0x11, +0x12; any violation returns 8.
@  - markers 0xc1-0xc3, 0xc5-0xc7, 0xc9-0xcb, 0xcd-0xcf and 0xd9 return 8.
@  - 0xc4 (payload <= 0x200 else 4): per table the class/id byte & 0xee must be 0 (else
@    6); allocates 0x10 work bytes for the 16 count bytes at r0[id*2+class+9]; builds
@    the ascending code table (ushort entries, sum*2 rounded to 4 bytes) at
@    r0[id*2+class+0xd]; copies the symbol bytes (sum rounded to 4) to
@    r0[id*2+class+0x11] (class 0 symbols must be <= 0xb else 6); repeats while payload
@    remains; work memory exhausted returns 3.
@  - 0xdb: each table needs 0x41 payload bytes with high nibble 0 (else 6); allocates
@    0x100 bytes into r0[(id&3)+0x15] and stores scale halfword (table 0x0806eeb4) *
@    payload byte at word index zz[i], zz being the byte table 0x0806ee74.
@  - 0xdd stores the big-endian ushort at r0+0x1a.
@  - any other marker is skipped through callback(ctx,0,length).
@  - 0xda (payload <= 0x200 else 4): needs width and height nonzero (6), component
@    count byte 3 and table-selector bytes +2,+4,+6 equal to 0 or 0x11 (8), Huffman
@    tables r0[9..0xc] and the three quantiser tables present (6), r0[0xe]*r0[0xf]
@    nonzero (6); allocates n*0x80+0x40 (minimum 0x100) bytes into r0[0x19] and
@    n*0x40+0x80 bytes into r0[0x1a] (n = r0[0xe]*r0[0xf], 3 when work memory is
@    short), sets r0[0]=0, r0[1]=segment buffer, byte r0+0xc=0, and when (bytes
@    consumed & 0x1ff) is nonzero reads the rest of the 0x200 buffer through the
@    callback (result to r0[0], r0[1]=buffer+offset-1); returns 0.
@ Return codes: 0 ok, 2 short read, 3 out of work memory, 4 segment longer than
@ 0x200, 5 no work memory, 6 inconsistent data, 8 unsupported.
@ ----------------------------------------------------------------------------
	.section .text.parse_jpeg_header,"ax",%progbits
	.global parse_jpeg_header
	.thumb_func
	.type parse_jpeg_header, %function
parse_jpeg_header:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x6c
	cbz r2, .L08038f5c
	mov r8, r0
	ldr r0, [sp, #0x90]
	add.w r4, r8, #0x24
	mov r6, r1
	strd r1, r0, [r8, #0x74]
	movs r5, #0
	mov r0, r4
	movs r1, #0x40
	mov r7, r3
	mov r9, r2
	strd r2, r3, [r8, #0x6c]
	strh.w r5, [r8, #0x1a]
	str.w r5, [r8, #0x1c]		@ width and height 0 until a SOF segment sets them (this rewrite):
	str.w r5, [r8, #0x20]		@ SOS refuses 0, so a file without SOF never reaches the table
					@ selectors ctx+0x10..0x12, which only SOF checks (<= 3)
	bl zero_bytes_aligned
	cmp.w r5, r7, lsr #9
	bne.n .L08038f62
	str.w r5, [r8, #8]
	movs r7, #3
	b.w .L08039d78
.L08038f5c:
	movs r7, #5
	b.w .L08039d78
.L08038f62:
	sub.w r0, r7, #0x200
	add.w r1, r9, #0x200
	strd r1, r0, [r8, #0x6c]
	mov r0, r8
	mov r1, r9
	movs r2, #2
	str r4, [sp, #0x68]
	str.w r9, [r8, #8]
	movs r7, #2
	blx r6
	cmp r0, #2
	bne.w .L08039d78
	ldrh.w r0, [r9]
	movw r1, #0xffd8
	lsls r0, r0, #0x10
	rev r0, r0
	cmp r0, r1
	bne.w .L08039d72
	ldr.w r3, [r8, #0x74]
	mov r0, r8
	mov r1, r9
	movs r2, #4
	blx r3
	cmp r0, #4
	bne.w .L08039d76
	movw r10, #:lower16:d_0806ee74
	movw r11, #:lower16:d_0806eeb4
	movs r3, #2
	movt r10, #:upper16:d_0806ee74
	movt r11, #:upper16:d_0806eeb4
.L08038fba:
	ldrh.w r0, [r9, #2]
	lsls r0, r0, #0x10
	rev r0, r0
	cmp r0, #3
	bcc.w .L08039d90
	ldrb.w r1, [r9]
	cmp r1, #0xff
	bne.w .L08039d94
	ldrb.w r1, [r9, #1]
	subs r2, r0, #2
	add r3, r0
	sub.w r0, r1, #0xc0
	cmp r0, #0x1d
	add.w r4, r3, #2
	bhi.w .L08039b98
	movs r7, #8
	tbh [pc, r0, lsl #1]
@ jump table for marker 0xc0 + index, halfword offsets from the first table byte
.L08038fee:
	.short (.L0803902a - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L080390da - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039d78 - .L08038fee)/2
	.short (.L08039dc4 - .L08038fee)/2
	.short (.L08039bae - .L08038fee)/2
	.short (.L08039b98 - .L08038fee)/2
	.short (.L08039d34 - .L08038fee)/2
@ marker 0xc0: frame header
.L0803902a:
	cmp.w r2, #0x200
	bhi.w .L08039dce
	ldr.w r3, [r8, #0x74]
	mov r0, r8
	mov r1, r9
	str r4, [sp, #0x5c]
	mov r4, r2
	blx r3
	cmp r0, r4
	bne.w .L08039de2
	ldrh.w r0, [r9, #3]
	lsls r0, r0, #0x10
	rev r0, r0
	str.w r0, [r8, #0x1c]
	ldrh.w r0, [r9, #1]
	lsls r0, r0, #0x10
	rev r0, r0
	str.w r0, [r8, #0x20]
	ldrb.w r0, [r9, #5]
	cmp r0, #3
	bne.w .L08039df2
	ldrb.w r0, [r9, #7]
	movs r7, #8
	sub.w r1, r0, #0x11
	cmp r1, #0x11
	bhi.w .L08039d78
	movs r2, #1
	lsl.w r1, r2, r1
	movs r2, #1
	movt r2, #3
	tst r1, r2
	beq.w .L08039d78
	lsrs r1, r0, #4
	and.w r0, r0, #0xf
	strb.w r1, [r8, #0xe]
	strb.w r0, [r8, #0xf]
	ldrb.w r0, [r9, #8]
	cmp r0, #3
	bhi.w .L08039df6
	strb.w r0, [r8, #0x10]
	ldrb.w r0, [r9, #0xa]
	cmp r0, #0x11
	bne.w .L08039dfa
	ldrb.w r0, [r9, #0xb]
	cmp r0, #3
	bhi.w .L08039dfe
	strb.w r0, [r8, #0x11]
	ldrb.w r0, [r9, #0xd]
	cmp r0, #0x11
	bne.w .L08039e02
	ldrb.w r0, [r9, #0xe]
	cmp r0, #3
	bhi.w .L08039e06
	strb.w r0, [r8, #0x12]
	b.w .L08039d58
@ marker 0xc4: Huffman table
.L080390da:
	cmp.w r2, #0x200
	bhi.w .L08039dd2
	ldr.w r3, [r8, #0x74]
	mov r0, r8
	mov r1, r9
	str r4, [sp, #0x5c]
	mov r4, r2
	blx r3
	cmp r0, r4
	mov r2, r9
	bne.w .L08039de6
.L080390f8:
	cmp r4, #0x11
	bcc.w .L08039d98
	ldrb r0, [r2]
	tst.w r0, #0xee
	bne.w .L08039d9c
	ldr.w r1, [r8, #0x70]
	cmp r1, #0x10
	bcc.w .L08039da0
	ldr.w r5, [r8, #0x6c]
	subs r1, #0x10
	str.w r1, [r8, #0x70]
	add.w r1, r5, #0x10
	cmp r5, #0
	mov.w r7, #3
	str.w r1, [r8, #0x6c]
	beq.w .L08039d78
	lsr.w r12, r0, #4
	and.w r0, r0, #0xf
	add.w r0, r8, r0, lsl #3
	add.w r10, r0, r12, lsl #2
	str.w r5, [r10, #0x24]
	ldrb.w lr, [r2, #1]
	str r4, [sp, #0x54]
	strb.w lr, [r5]
	ldrb r3, [r2, #2]
	str r5, [sp, #0x60]
	strb r3, [r5, #1]
	ldrb r1, [r2, #3]
	add.w r0, r3, lr
	strb r1, [r5, #2]
	ldrb r6, [r2, #4]
	str r1, [sp, #0x40]
	strb r6, [r5, #3]
	add r0, r1
	ldrb r1, [r2, #5]
	str r6, [sp, #0x3c]
	strb r1, [r5, #4]
	add r0, r6
	ldrb r6, [r2, #6]
	str r1, [sp, #0x38]
	strb r6, [r5, #5]
	add r0, r1
	ldrb r1, [r2, #7]
	str r6, [sp, #0x34]
	strb r1, [r5, #6]
	add r0, r6
	ldrb r6, [r2, #8]
	str r1, [sp, #0x30]
	strb r6, [r5, #7]
	add r0, r1
	ldrb r1, [r2, #9]
	str r6, [sp, #0x2c]
	strb r1, [r5, #8]
	add r0, r6
	ldrb r6, [r2, #0xa]
	str r1, [sp, #0x28]
	strb r6, [r5, #9]
	add r0, r1
	ldrb r1, [r2, #0xb]
	str r6, [sp, #0x24]
	strb r1, [r5, #0xa]
	add r0, r6
	ldrb r6, [r2, #0xc]
	str r1, [sp, #0x20]
	strb r6, [r5, #0xb]
	add r0, r1
	ldrb r1, [r2, #0xd]
	str r6, [sp, #0x1c]
	strb r1, [r5, #0xc]
	add r0, r6
	ldrb r6, [r2, #0xe]
	str r1, [sp, #0x18]
	strb r6, [r5, #0xd]
	add r0, r1
	ldrb r1, [r2, #0xf]
	str r6, [sp, #0x14]
	strb r1, [r5, #0xe]
	add r0, r6
	ldrb r6, [r2, #0x10]
	add r0, r1
	strb r6, [r5, #0xf]
	adds r4, r0, r6
	str r1, [sp, #0x10]
	add.w r0, r7, r4, lsl #1
	ldr.w r1, [r8, #0x70]
	bic.w r0, r0, #3
	cmp r1, r0
	str r6, [sp, #0xc]
	bcc.w .L08039d78
	ldr.w r5, [r8, #0x6c]
	subs r1, r1, r0
	add r0, r5
	cmp r5, #0
	str.w r1, [r8, #0x70]
	str.w r0, [r8, #0x6c]
	beq.w .L08039da4
	ldr r0, [sp, #0x60]
	str.w r5, [r10, #0x34]
	str r1, [sp, #0x4c]
	ldrb r1, [r0]
	str r5, [sp, #0x64]
	str r2, [sp, #0x58]
	strd lr, r3, [sp, #4]
	strd r12, r10, [sp, #0x44]
	cbz r1, .L08039212
	subs r0, r1, #1
	cmp r0, #3
	bcs.n .L08039224
	movs r0, #0
	movs r2, #0
	b.n .L08039252
.L08039212:
	movw r10, #:lower16:d_0806ee74
	ldr r5, [sp, #0x60]
	mov.w r12, #0
	movs r7, #0
	movt r10, #:upper16:d_0806ee74
	b.n .L08039296
.L08039224:
	ldr r0, [sp, #0x64]
	and.w r3, r1, #0xfc
	sub.w r7, r0, #8
	movs r0, #0
	movs r2, #0
	nop
.L08039234:
	orr.w r6, r0, #1
	strh.w r0, [r7, #8]!
	adds r2, #4
	orr.w r5, r0, #2
	strh r6, [r7, #2]
	orr.w r6, r0, #3
	adds r0, #4
	cmp r3, r2
	strh r5, [r7, #4]
	strh r6, [r7, #6]
	bne.n .L08039234
.L08039252:
	movw r10, #:lower16:d_0806ee74
	ldr r5, [sp, #0x60]
	ands.w r1, r1, #3
	mov r12, r2
	mov r7, r0
	movt r10, #:upper16:d_0806ee74
	beq.n .L08039296
	ldr r3, [sp, #0x64]
	adds r7, r0, #1
	add.w r12, r2, #1
	cmp r1, #1
	strh.w r0, [r3, r2, lsl #1]
	beq.n .L08039296
	adds r6, r0, #2
	adds r5, r2, #2
	cmp r1, #2
	strh.w r7, [r3, r12, lsl #1]
	bne.n .L0803928a
	mov r12, r5
	ldr r5, [sp, #0x60]
	mov r7, r6
	b.n .L08039296
.L0803928a:
	strh.w r6, [r3, r5, lsl #1]
	ldr r5, [sp, #0x60]
	adds r7, r0, #3
	add.w r12, r2, #3
.L08039296:
	ldrb r1, [r5, #1]
	lsls r7, r7, #1
	str r4, [sp, #0x50]
	cbz r1, .L080392c4
	ands.w r0, r1, #3
	sub.w r3, r1, #1
	beq.n .L080392c8
	ldr r4, [sp, #0x64]
	orr.w r6, r7, #1
	add.w r2, r12, #1
	cmp r0, #1
	strh.w r7, [r4, r12, lsl #1]
	bne.n .L080392cc
	mov r7, r6
	mov lr, r2
	mov r1, r3
	mov r12, r2
	b.n .L080392ee
.L080392c4:
	mov lr, r12
	b.n .L0803931e
.L080392c8:
	ldr r4, [sp, #0x64]
	b.n .L080392ee
.L080392cc:
	adds r7, r6, #1
	add.w lr, r12, #2
	cmp r0, #2
	strh.w r6, [r4, r2, lsl #1]
	bne.n .L080392e0
	subs r1, #2
	mov r12, lr
	b.n .L080392ee
.L080392e0:
	add.w r12, r12, #3
	subs r1, #3
	strh.w r7, [r4, lr, lsl #1]
	adds r7, r6, #2
	mov lr, r12
.L080392ee:
	cmp r3, #3
	bcc.n .L08039320
	add.w r0, r4, r12, lsl #1
	subs r2, r0, #2
	movs r6, #0
	nop
.L080392fc:
	adds r5, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r2, #2]
	adds r3, r7, #2
	strh r5, [r4, #2]
	adds r5, r7, #3
	adds r6, #4
	strh r3, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r5, [r2, #8]!
	bne.n .L080392fc
	ldr r5, [sp, #0x60]
	add.w lr, r12, r6
.L0803931e:
	ldr r4, [sp, #0x64]
.L08039320:
	ldrb r1, [r5, #2]
	lsls r3, r7, #1
	cbz r1, .L0803934a
	ands.w r7, r1, #3
	sub.w r0, r1, #1
	beq.n .L0803934e
	orr.w r6, r3, #1
	add.w r2, lr, #1
	cmp r7, #1
	strh.w r3, [r4, lr, lsl #1]
	bne.n .L08039350
	mov r3, r6
	mov r12, r2
	mov r1, r0
	mov lr, r2
	b.n .L08039372
.L0803934a:
	mov r12, lr
	b.n .L080393a4
.L0803934e:
	b.n .L08039372
.L08039350:
	adds r3, r6, #1
	add.w r12, lr, #2
	cmp r7, #2
	strh.w r6, [r4, r2, lsl #1]
	bne.n .L08039364
	subs r1, #2
	mov lr, r12
	b.n .L08039372
.L08039364:
	add.w lr, lr, #3
	subs r1, #3
	strh.w r3, [r4, r12, lsl #1]
	adds r3, r6, #2
	mov r12, lr
.L08039372:
	cmp r0, #3
	bcc.n .L080393a4
	add.w r0, r4, lr, lsl #1
	subs r7, r0, #2
	movs r6, #0
	nop
.L08039380:
	adds r2, r3, #1
	add.w r5, r0, r6, lsl #1
	strh r3, [r7, #2]
	adds r4, r3, #2
	strh r2, [r5, #2]
	adds r2, r3, #3
	adds r6, #4
	strh r4, [r5, #4]
	adds r3, #4
	cmp r1, r6
	strh.w r2, [r7, #8]!
	bne.n .L08039380
	ldrd r5, r4, [sp, #0x60]
	add.w r12, lr, r6
.L080393a4:
	ldrb r1, [r5, #3]
	lsls r3, r3, #1
	cbz r1, .L080393ce
	ands.w r7, r1, #3
	sub.w r0, r1, #1
	beq.n .L080393d2
	orr.w r6, r3, #1
	add.w r2, r12, #1
	cmp r7, #1
	strh.w r3, [r4, r12, lsl #1]
	bne.n .L080393d4
	mov r3, r6
	mov lr, r2
	mov r1, r0
	mov r12, r2
	b.n .L080393f6
.L080393ce:
	mov lr, r12
	b.n .L08039428
.L080393d2:
	b.n .L080393f6
.L080393d4:
	adds r3, r6, #1
	add.w lr, r12, #2
	cmp r7, #2
	strh.w r6, [r4, r2, lsl #1]
	bne.n .L080393e8
	subs r1, #2
	mov r12, lr
	b.n .L080393f6
.L080393e8:
	add.w r12, r12, #3
	subs r1, #3
	strh.w r3, [r4, lr, lsl #1]
	adds r3, r6, #2
	mov lr, r12
.L080393f6:
	cmp r0, #3
	bcc.n .L08039428
	add.w r0, r4, r12, lsl #1
	subs r2, r0, #2
	movs r6, #0
	nop
.L08039404:
	adds r7, r3, #1
	add.w r4, r0, r6, lsl #1
	strh r3, [r2, #2]
	adds r5, r3, #2
	strh r7, [r4, #2]
	adds r7, r3, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r3, #4
	cmp r1, r6
	strh.w r7, [r2, #8]!
	bne.n .L08039404
	ldrd r5, r4, [sp, #0x60]
	add.w lr, r12, r6
.L08039428:
	ldrb r1, [r5, #4]
	lsls r7, r3, #1
	cbz r1, .L08039452
	ands.w r0, r1, #3
	sub.w r3, r1, #1
	beq.n .L08039456
	orr.w r6, r7, #1
	add.w r2, lr, #1
	cmp r0, #1
	strh.w r7, [r4, lr, lsl #1]
	bne.n .L08039458
	mov r7, r6
	mov r12, r2
	mov r1, r3
	mov lr, r2
	b.n .L0803947a
.L08039452:
	mov r12, lr
	b.n .L080394ac
.L08039456:
	b.n .L0803947a
.L08039458:
	adds r7, r6, #1
	add.w r12, lr, #2
	cmp r0, #2
	strh.w r6, [r4, r2, lsl #1]
	bne.n .L0803946c
	subs r1, #2
	mov lr, r12
	b.n .L0803947a
.L0803946c:
	add.w lr, lr, #3
	subs r1, #3
	strh.w r7, [r4, r12, lsl #1]
	adds r7, r6, #2
	mov r12, lr
.L0803947a:
	cmp r3, #3
	bcc.n .L080394ac
	add.w r0, r4, lr, lsl #1
	subs r3, r0, #2
	movs r6, #0
	nop
.L08039488:
	adds r2, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r3, #2]
	adds r5, r7, #2
	strh r2, [r4, #2]
	adds r2, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r2, [r3, #8]!
	bne.n .L08039488
	ldrd r5, r4, [sp, #0x60]
	add.w r12, lr, r6
.L080394ac:
	ldrb r1, [r5, #5]
	lsls r7, r7, #1
	cbz r1, .L080394d6
	ands.w r0, r1, #3
	sub.w r2, r1, #1
	beq.n .L080394da
	orr.w r6, r7, #1
	add.w r3, r12, #1
	cmp r0, #1
	strh.w r7, [r4, r12, lsl #1]
	bne.n .L080394dc
	mov r7, r6
	mov lr, r3
	mov r1, r2
	mov r12, r3
	b.n .L080394fe
.L080394d6:
	mov lr, r12
	b.n .L08039530
.L080394da:
	b.n .L080394fe
.L080394dc:
	adds r7, r6, #1
	add.w lr, r12, #2
	cmp r0, #2
	strh.w r6, [r4, r3, lsl #1]
	bne.n .L080394f0
	subs r1, #2
	mov r12, lr
	b.n .L080394fe
.L080394f0:
	add.w r12, r12, #3
	subs r1, #3
	strh.w r7, [r4, lr, lsl #1]
	adds r7, r6, #2
	mov lr, r12
.L080394fe:
	cmp r2, #3
	bcc.n .L08039530
	add.w r0, r4, r12, lsl #1
	subs r2, r0, #2
	movs r6, #0
	nop
.L0803950c:
	adds r3, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r2, #2]
	adds r5, r7, #2
	strh r3, [r4, #2]
	adds r3, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r3, [r2, #8]!
	bne.n .L0803950c
	ldrd r5, r4, [sp, #0x60]
	add.w lr, r12, r6
.L08039530:
	ldrb r1, [r5, #6]
	lsls r7, r7, #1
	cbz r1, .L0803955a
	ands.w r0, r1, #3
	sub.w r3, r1, #1
	beq.n .L0803955e
	orr.w r6, r7, #1
	add.w r2, lr, #1
	cmp r0, #1
	strh.w r7, [r4, lr, lsl #1]
	bne.n .L08039560
	mov r7, r6
	mov r12, r2
	mov r1, r3
	mov lr, r2
	b.n .L08039582
.L0803955a:
	mov r12, lr
	b.n .L080395b4
.L0803955e:
	b.n .L08039582
.L08039560:
	adds r7, r6, #1
	add.w r12, lr, #2
	cmp r0, #2
	strh.w r6, [r4, r2, lsl #1]
	bne.n .L08039574
	subs r1, #2
	mov lr, r12
	b.n .L08039582
.L08039574:
	add.w lr, lr, #3
	subs r1, #3
	strh.w r7, [r4, r12, lsl #1]
	adds r7, r6, #2
	mov r12, lr
.L08039582:
	cmp r3, #3
	bcc.n .L080395b4
	add.w r0, r4, lr, lsl #1
	subs r3, r0, #2
	movs r6, #0
	nop
.L08039590:
	adds r2, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r3, #2]
	adds r5, r7, #2
	strh r2, [r4, #2]
	adds r2, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r2, [r3, #8]!
	bne.n .L08039590
	ldrd r5, r4, [sp, #0x60]
	add.w r12, lr, r6
.L080395b4:
	ldrb r1, [r5, #7]
	lsls r7, r7, #1
	cbz r1, .L080395de
	ands.w r0, r1, #3
	sub.w r2, r1, #1
	beq.n .L080395e2
	orr.w r6, r7, #1
	add.w r3, r12, #1
	cmp r0, #1
	strh.w r7, [r4, r12, lsl #1]
	bne.n .L080395e4
	mov r7, r6
	mov lr, r3
	mov r1, r2
	mov r12, r3
	b.n .L08039606
.L080395de:
	mov lr, r12
	b.n .L08039638
.L080395e2:
	b.n .L08039606
.L080395e4:
	adds r7, r6, #1
	add.w lr, r12, #2
	cmp r0, #2
	strh.w r6, [r4, r3, lsl #1]
	bne.n .L080395f8
	subs r1, #2
	mov r12, lr
	b.n .L08039606
.L080395f8:
	add.w r12, r12, #3
	subs r1, #3
	strh.w r7, [r4, lr, lsl #1]
	adds r7, r6, #2
	mov lr, r12
.L08039606:
	cmp r2, #3
	bcc.n .L08039638
	add.w r0, r4, r12, lsl #1
	subs r2, r0, #2
	movs r6, #0
	nop
.L08039614:
	adds r3, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r2, #2]
	adds r5, r7, #2
	strh r3, [r4, #2]
	adds r3, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r3, [r2, #8]!
	bne.n .L08039614
	ldrd r5, r4, [sp, #0x60]
	add.w lr, r12, r6
.L08039638:
	ldrb r1, [r5, #8]
	lsls r7, r7, #1
	cbz r1, .L08039662
	ands.w r0, r1, #3
	sub.w r3, r1, #1
	beq.n .L08039666
	orr.w r6, r7, #1
	add.w r2, lr, #1
	cmp r0, #1
	strh.w r7, [r4, lr, lsl #1]
	bne.n .L08039668
	mov r7, r6
	mov r12, r2
	mov r1, r3
	mov lr, r2
	b.n .L0803968a
.L08039662:
	mov r12, lr
	b.n .L080396bc
.L08039666:
	b.n .L0803968a
.L08039668:
	adds r7, r6, #1
	add.w r12, lr, #2
	cmp r0, #2
	strh.w r6, [r4, r2, lsl #1]
	bne.n .L0803967c
	subs r1, #2
	mov lr, r12
	b.n .L0803968a
.L0803967c:
	add.w lr, lr, #3
	subs r1, #3
	strh.w r7, [r4, r12, lsl #1]
	adds r7, r6, #2
	mov r12, lr
.L0803968a:
	cmp r3, #3
	bcc.n .L080396bc
	add.w r0, r4, lr, lsl #1
	subs r3, r0, #2
	movs r6, #0
	nop
.L08039698:
	adds r2, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r3, #2]
	adds r5, r7, #2
	strh r2, [r4, #2]
	adds r2, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r2, [r3, #8]!
	bne.n .L08039698
	ldrd r5, r4, [sp, #0x60]
	add.w r12, lr, r6
.L080396bc:
	ldrb r1, [r5, #9]
	lsls r7, r7, #1
	cbz r1, .L080396e6
	ands.w r0, r1, #3
	sub.w r2, r1, #1
	beq.n .L080396ea
	orr.w r6, r7, #1
	add.w r3, r12, #1
	cmp r0, #1
	strh.w r7, [r4, r12, lsl #1]
	bne.n .L080396ec
	mov r7, r6
	mov lr, r3
	mov r1, r2
	mov r12, r3
	b.n .L0803970e
.L080396e6:
	mov lr, r12
	b.n .L08039740
.L080396ea:
	b.n .L0803970e
.L080396ec:
	adds r7, r6, #1
	add.w lr, r12, #2
	cmp r0, #2
	strh.w r6, [r4, r3, lsl #1]
	bne.n .L08039700
	subs r1, #2
	mov r12, lr
	b.n .L0803970e
.L08039700:
	add.w r12, r12, #3
	subs r1, #3
	strh.w r7, [r4, lr, lsl #1]
	adds r7, r6, #2
	mov lr, r12
.L0803970e:
	cmp r2, #3
	bcc.n .L08039740
	add.w r0, r4, r12, lsl #1
	subs r2, r0, #2
	movs r6, #0
	nop
.L0803971c:
	adds r3, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r2, #2]
	adds r5, r7, #2
	strh r3, [r4, #2]
	adds r3, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r3, [r2, #8]!
	bne.n .L0803971c
	ldrd r5, r4, [sp, #0x60]
	add.w lr, r12, r6
.L08039740:
	ldrb r1, [r5, #0xa]
	lsls r7, r7, #1
	cbz r1, .L0803976a
	ands.w r0, r1, #3
	sub.w r3, r1, #1
	beq.n .L0803976e
	orr.w r6, r7, #1
	add.w r2, lr, #1
	cmp r0, #1
	strh.w r7, [r4, lr, lsl #1]
	bne.n .L08039770
	mov r7, r6
	mov r12, r2
	mov r1, r3
	mov lr, r2
	b.n .L08039792
.L0803976a:
	mov r12, lr
	b.n .L080397c4
.L0803976e:
	b.n .L08039792
.L08039770:
	adds r7, r6, #1
	add.w r12, lr, #2
	cmp r0, #2
	strh.w r6, [r4, r2, lsl #1]
	bne.n .L08039784
	subs r1, #2
	mov lr, r12
	b.n .L08039792
.L08039784:
	add.w lr, lr, #3
	subs r1, #3
	strh.w r7, [r4, r12, lsl #1]
	adds r7, r6, #2
	mov r12, lr
.L08039792:
	cmp r3, #3
	bcc.n .L080397c4
	add.w r0, r4, lr, lsl #1
	subs r3, r0, #2
	movs r6, #0
	nop
.L080397a0:
	adds r2, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r3, #2]
	adds r5, r7, #2
	strh r2, [r4, #2]
	adds r2, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r2, [r3, #8]!
	bne.n .L080397a0
	ldrd r5, r4, [sp, #0x60]
	add.w r12, lr, r6
.L080397c4:
	ldrb r1, [r5, #0xb]
	lsls r7, r7, #1
	cbz r1, .L080397ee
	ands.w r0, r1, #3
	sub.w r2, r1, #1
	beq.n .L080397f2
	orr.w r6, r7, #1
	add.w r3, r12, #1
	cmp r0, #1
	strh.w r7, [r4, r12, lsl #1]
	bne.n .L080397f4
	mov r7, r6
	mov lr, r3
	mov r1, r2
	mov r12, r3
	b.n .L08039816
.L080397ee:
	mov lr, r12
	b.n .L08039848
.L080397f2:
	b.n .L08039816
.L080397f4:
	adds r7, r6, #1
	add.w lr, r12, #2
	cmp r0, #2
	strh.w r6, [r4, r3, lsl #1]
	bne.n .L08039808
	subs r1, #2
	mov r12, lr
	b.n .L08039816
.L08039808:
	add.w r12, r12, #3
	subs r1, #3
	strh.w r7, [r4, lr, lsl #1]
	adds r7, r6, #2
	mov lr, r12
.L08039816:
	cmp r2, #3
	bcc.n .L08039848
	add.w r0, r4, r12, lsl #1
	subs r2, r0, #2
	movs r6, #0
	nop
.L08039824:
	adds r3, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r2, #2]
	adds r5, r7, #2
	strh r3, [r4, #2]
	adds r3, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r3, [r2, #8]!
	bne.n .L08039824
	ldrd r5, r4, [sp, #0x60]
	add.w lr, r12, r6
.L08039848:
	ldrb r1, [r5, #0xc]
	lsls r7, r7, #1
	cbz r1, .L08039872
	ands.w r0, r1, #3
	sub.w r3, r1, #1
	beq.n .L08039876
	orr.w r6, r7, #1
	add.w r2, lr, #1
	cmp r0, #1
	strh.w r7, [r4, lr, lsl #1]
	bne.n .L08039878
	mov r7, r6
	mov r12, r2
	mov r1, r3
	mov lr, r2
	b.n .L0803989a
.L08039872:
	mov r12, lr
	b.n .L080398cc
.L08039876:
	b.n .L0803989a
.L08039878:
	adds r7, r6, #1
	add.w r12, lr, #2
	cmp r0, #2
	strh.w r6, [r4, r2, lsl #1]
	bne.n .L0803988c
	subs r1, #2
	mov lr, r12
	b.n .L0803989a
.L0803988c:
	add.w lr, lr, #3
	subs r1, #3
	strh.w r7, [r4, r12, lsl #1]
	adds r7, r6, #2
	mov r12, lr
.L0803989a:
	cmp r3, #3
	bcc.n .L080398cc
	add.w r0, r4, lr, lsl #1
	subs r3, r0, #2
	movs r6, #0
	nop
.L080398a8:
	adds r2, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r3, #2]
	adds r5, r7, #2
	strh r2, [r4, #2]
	adds r2, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r1, r6
	strh.w r2, [r3, #8]!
	bne.n .L080398a8
	ldrd r5, r4, [sp, #0x60]
	add.w r12, lr, r6
.L080398cc:
	ldrb r2, [r5, #0xd]
	lsls r7, r7, #1
	cbz r2, .L080398f6
	ands.w r0, r2, #3
	sub.w r1, r2, #1
	beq.n .L080398fa
	orr.w r6, r7, #1
	add.w r3, r12, #1
	cmp r0, #1
	strh.w r7, [r4, r12, lsl #1]
	bne.n .L080398fc
	mov r7, r6
	mov lr, r3
	mov r2, r1
	mov r12, r3
	b.n .L0803991e
.L080398f6:
	mov lr, r12
	b.n .L08039950
.L080398fa:
	b.n .L0803991e
.L080398fc:
	adds r7, r6, #1
	add.w lr, r12, #2
	cmp r0, #2
	strh.w r6, [r4, r3, lsl #1]
	bne.n .L08039910
	subs r2, #2
	mov r12, lr
	b.n .L0803991e
.L08039910:
	add.w r12, r12, #3
	subs r2, #3
	strh.w r7, [r4, lr, lsl #1]
	adds r7, r6, #2
	mov lr, r12
.L0803991e:
	cmp r1, #3
	bcc.n .L08039950
	add.w r0, r4, r12, lsl #1
	subs r1, r0, #2
	movs r6, #0
	nop
.L0803992c:
	adds r3, r7, #1
	add.w r4, r0, r6, lsl #1
	strh r7, [r1, #2]
	adds r5, r7, #2
	strh r3, [r4, #2]
	adds r3, r7, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r7, #4
	cmp r2, r6
	strh.w r3, [r1, #8]!
	bne.n .L0803992c
	ldrd r5, r4, [sp, #0x60]
	add.w lr, r12, r6
.L08039950:
	ldrb r0, [r5, #0xe]
	lsls r3, r7, #1
	cbz r0, .L0803997a
	ands.w r7, r0, #3
	sub.w r12, r0, #1
	beq.n .L0803997e
	orr.w r6, r3, #1
	add.w r1, lr, #1
	cmp r7, #1
	strh.w r3, [r4, lr, lsl #1]
	bne.n .L08039980
	mov r3, r6
	mov r2, r1
	mov r0, r12
	mov lr, r1
	b.n .L080399a2
.L0803997a:
	mov r2, lr
	b.n .L080399d6
.L0803997e:
	b.n .L080399a2
.L08039980:
	adds r3, r6, #1
	add.w r2, lr, #2
	cmp r7, #2
	strh.w r6, [r4, r1, lsl #1]
	bne.n .L08039994
	subs r0, #2
	mov lr, r2
	b.n .L080399a2
.L08039994:
	add.w lr, lr, #3
	subs r0, #3
	strh.w r3, [r4, r2, lsl #1]
	adds r3, r6, #2
	mov r2, lr
.L080399a2:
	cmp.w r12, #3
	bcc.n .L080399d6
	ldr r1, [sp, #0x64]
	movs r6, #0
	add.w r2, r1, lr, lsl #1
	subs r7, r2, #2
	nop
.L080399b4:
	adds r1, r3, #1
	add.w r4, r2, r6, lsl #1
	strh r3, [r7, #2]
	adds r5, r3, #2
	strh r1, [r4, #2]
	adds r1, r3, #3
	adds r6, #4
	strh r5, [r4, #4]
	adds r3, #4
	cmp r0, r6
	strh.w r1, [r7, #8]!
	bne.n .L080399b4
	ldr r5, [sp, #0x60]
	add.w r2, lr, r6
.L080399d6:
	ldrb r0, [r5, #0xf]
	ldrd r4, r5, [sp, #0x50]
	cbz r0, .L08039a54
	lsls r1, r3, #1
	ands.w r6, r0, #3
	sub.w r3, r0, #1
	beq.n .L08039a30
	ldr.w r12, [sp, #0x64]
	orr.w r7, r1, #1
	add.w lr, r2, #1
	cmp r6, #1
	strh.w r1, [r12, r2, lsl #1]
	bne.n .L08039a06
	mov r1, r7
	mov r0, r3
	mov r2, lr
	b.n .L08039a30
.L08039a06:
	adds r1, r7, #1
	mov r5, lr
	add.w lr, r2, #2
	cmp r6, #2
	str.w lr, [sp, #0x60]
	strh.w r7, [r12, r5, lsl #1]
	bne.n .L08039a22
	ldr r2, [sp, #0x60]
	ldr r5, [sp, #0x54]
	subs r0, #2
	b.n .L08039a30
.L08039a22:
	ldr r5, [sp, #0x60]
	subs r0, #3
	strh.w r1, [r12, r5, lsl #1]
	ldr r5, [sp, #0x54]
	adds r1, r7, #2
	adds r2, #3
.L08039a30:
	cmp r3, #3
	bcc.n .L08039a54
	ldr r3, [sp, #0x64]
	add.w r2, r3, r2, lsl #1
	subs r2, #8
.L08039a3c:
	adds r3, r1, #1
	strh.w r1, [r2, #8]!
	adds r7, r1, #2
	strh r3, [r2, #2]
	adds r3, r1, #3
	subs r0, #4
	add.w r1, r1, #4
	strh r7, [r2, #4]
	strh r3, [r2, #6]
	bne.n .L08039a3c
.L08039a54:
	sub.w r12, r5, #0x11
	cmp r12, r4
	bcc.w .L08039da8
	adds r0, r4, #3
	ldr r1, [sp, #0x4c]
	bic.w r0, r0, #3
	cmp r1, r0
	bcc.w .L08039dac
	ldr.w r7, [r8, #0x6c]
	subs r1, r1, r0
	add r0, r7
	cmp r7, #0
	str.w r1, [r8, #0x70]
	str.w r0, [r8, #0x6c]
	beq.w .L08039db4
	ldr r2, [sp, #0x58]
	ldr r1, [sp, #0x48]
	add.w r0, r2, #0x11
	str r7, [r1, #0x44]
	cbz r4, .L08039a9a
	ldr r1, [sp, #0x44]
	cbz r1, .L08039a9e
	subs r1, r4, #1
	cmp r1, #3
	bcs.n .L08039b2e
	b.n .L08039b5a
.L08039a9a:
	mov r2, r0
	b.n .L08039b8e
.L08039a9e:
	ldr r0, [sp, #4]
	ldr r1, [sp, #0x40]
	add r0, r1
	ldr r1, [sp, #0x3c]
	add r0, r1
	ldr r1, [sp, #0x38]
	add r0, r1
	ldr r1, [sp, #0x34]
	add r0, r1
	ldr r1, [sp, #0x30]
	add r0, r1
	ldr r1, [sp, #0x2c]
	add r0, r1
	ldr r1, [sp, #0x28]
	add r0, r1
	ldr r1, [sp, #0x24]
	add r0, r1
	ldr r1, [sp, #0x20]
	add r0, r1
	ldr r1, [sp, #0x1c]
	add r0, r1
	ldr r1, [sp, #0x18]
	add r0, r1
	ldr r1, [sp, #0x14]
	add r0, r1
	ldr r1, [sp, #0x10]
	add r0, r1
	ldr r1, [sp, #0xc]
	add r0, r1
	ldr r1, [sp, #8]
	add.w lr, r0, r1
	rsb.w r4, lr, #0
	movs r1, #0
.L08039ae4:
	add r2, r1
	ldrb r5, [r2, #0x11]
	cmp r5, #0xb
	bhi.w .L08039db0
	adds r0, r4, r1
	adds r3, r7, r1
	adds r6, r0, #1
	strb r5, [r3]
	beq.n .L08039b82
	ldrb r5, [r2, #0x12]
	cmp r5, #0xb
	bhi.w .L08039db8
	adds r6, r0, #2
	strb r5, [r3, #1]
	beq.n .L08039b86
	ldrb r5, [r2, #0x13]
	cmp r5, #0xb
	bhi.w .L08039dbc
	adds r0, #3
	strb r5, [r3, #2]
	beq.n .L08039b8a
	ldrb r0, [r2, #0x14]
	cmp r0, #0xb
	bhi.w .L08039dc0
	adds r1, #4
	ldr r2, [sp, #0x58]
	cmp lr, r1
	strb r0, [r3, #3]
	bne.n .L08039ae4
	adds r0, r2, r1
	add.w r2, r0, #0x11
	b.n .L08039b8c
.L08039b2e:
	bic.w r1, r4, #3
	rsbs r1, r1, #0
.L08039b34:
	ldrb.w r2, [r0], #4
	adds r1, #4
	strb.w r2, [r7], #4
	ldrb.w r2, [r0, #-3]
	strb.w r2, [r7, #-3]
	ldrb.w r2, [r0, #-2]
	strb.w r2, [r7, #-2]
	ldrb.w r2, [r0, #-1]
	strb.w r2, [r7, #-1]
	bne.n .L08039b34
	mov r2, r0
.L08039b5a:
	ands.w r1, r4, #3
	beq.n .L08039b8e
	mov r3, r0
	ldrb.w r2, [r3], #1
	cmp r1, #1
	strb r2, [r7]
	mov r2, r3
	beq.n .L08039b8e
	ldrb r2, [r0, #1]
	cmp r1, #2
	strb r2, [r7, #1]
	bne.n .L08039b7a
	adds r2, r0, #2
	b.n .L08039b8e
.L08039b7a:
	ldrb r1, [r0, #2]
	adds r2, r0, #3
	strb r1, [r7, #2]
	b.n .L08039b8e
.L08039b82:
	adds r2, #0x12
	b.n .L08039b8c
.L08039b86:
	adds r2, #0x13
	b.n .L08039b8c
.L08039b8a:
	adds r2, #0x14
.L08039b8c:
	ldr r4, [sp, #0x50]
.L08039b8e:
	subs.w r4, r12, r4
	bne.w .L080390f8
	b.n .L08039d58
.L08039b98:
	ldr.w r3, [r8, #0x74]
	mov r0, r8
	movs r1, #0
	str r4, [sp, #0x5c]
	mov r4, r2
	blx r3
	cmp r0, r4
	beq.w .L08039d58
	b.n .L08039dd6
@ marker 0xdb: quantisation table
.L08039bae:
	cmp.w r2, #0x200
	bhi.w .L08039dda
	ldr.w r3, [r8, #0x74]
	mov r0, r8
	mov r1, r9
	str r4, [sp, #0x5c]
	mov r4, r2
	blx r3
	mov lr, r4
	cmp r0, r4
	mov r1, r9
	bne.w .L08039dea
.L08039bce:
	cmp.w lr, #0x41
	bcc.w .L08039d80
	ldrb r2, [r1]
	tst.w r2, #0xf0
	bne.w .L08039d84
	ldr.w r0, [r8, #0x70]
	cmp.w r0, #0x100
	bcc.w .L08039d88
	sub.w r3, r0, #0x100
	ldr.w r0, [r8, #0x6c]
	str.w r3, [r8, #0x70]
	add.w r3, r0, #0x100
	cmp r0, #0
	str.w r3, [r8, #0x6c]
	beq.w .L08039d8c
	and.w r2, r2, #3
	add.w r2, r8, r2, lsl #2
	sub.w lr, lr, #0x41
	str r0, [r2, #0x54]
	add.w r12, r1, #1
	movs r2, #0
	nop
.L08039c1c:
	ldrb.w r6, [r10, r2]
	ldrb.w r5, [r12, r2]
	ldrh.w r4, [r11, r6, lsl #1]
	add.w r7, r10, r2
	muls r5, r4, r5
	str.w r5, [r0, r6, lsl #2]
	ldrb r6, [r7, #1]
	add.w r3, r12, r2
	ldrb r5, [r3, #1]
	ldrh.w r4, [r11, r6, lsl #1]
	ldrb r1, [r7, #2]
	muls r5, r4, r5
	str.w r5, [r0, r6, lsl #2]
	ldrb r6, [r3, #2]
	ldrh.w r5, [r11, r1, lsl #1]
	ldrb r4, [r7, #3]
	muls r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r3, #3]
	ldrh.w r6, [r11, r4, lsl #1]
	ldrb r5, [r7, #4]
	muls r1, r6, r1
	str.w r1, [r0, r4, lsl #2]
	ldrb r1, [r3, #4]
	ldrh.w r6, [r11, r5, lsl #1]
	adds r2, #0x10
	muls r1, r6, r1
	str.w r1, [r0, r5, lsl #2]
	ldrb r1, [r7, #5]
	ldrb r6, [r3, #5]
	ldrh.w r5, [r11, r1, lsl #1]
	cmp r2, #0x40
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #6]
	ldrb r6, [r3, #6]
	ldrh.w r5, [r11, r1, lsl #1]
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #7]
	ldrb r6, [r3, #7]
	ldrh.w r5, [r11, r1, lsl #1]
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #8]
	ldrb r6, [r3, #8]
	ldrh.w r5, [r11, r1, lsl #1]
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #9]
	ldrb r6, [r3, #9]
	ldrh.w r5, [r11, r1, lsl #1]
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #0xa]
	ldrb r6, [r3, #0xa]
	ldrh.w r5, [r11, r1, lsl #1]
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #0xb]
	ldrb r6, [r3, #0xb]
	ldrh.w r5, [r11, r1, lsl #1]
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #0xc]
	ldrb r6, [r3, #0xc]
	ldrh.w r5, [r11, r1, lsl #1]
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #0xd]
	ldrb r6, [r3, #0xd]
	ldrh.w r5, [r11, r1, lsl #1]
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #0xe]
	ldrb r6, [r3, #0xe]
	ldrh.w r5, [r11, r1, lsl #1]
	mul r6, r5, r6
	str.w r6, [r0, r1, lsl #2]
	ldrb r1, [r7, #0xf]
	ldrb r3, [r3, #0xf]
	ldrh.w r7, [r11, r1, lsl #1]
	mul r3, r7, r3
	str.w r3, [r0, r1, lsl #2]
	bne.w .L08039c1c
	cmp.w lr, #0
	add.w r1, r12, r2
	bne.w .L08039bce
	b.n .L08039d58
@ marker 0xdd: restart interval
.L08039d34:
	cmp.w r2, #0x200
	bhi.n .L08039dde
	ldr.w r3, [r8, #0x74]
	mov r0, r8
	mov r1, r9
	str r4, [sp, #0x5c]
	mov r4, r2
	blx r3
	cmp r0, r4
	bne.n .L08039dee
	ldrh.w r0, [r9]
	rev r0, r0
	lsrs r0, r0, #0x10
	strh.w r0, [r8, #0x1a]
@ read the next segment header (4 bytes), loop back while the callback returns 4
.L08039d58:
	ldr.w r3, [r8, #0x74]
	mov r0, r8
	mov r1, r9
	movs r2, #4
	blx r3
	ldr r3, [sp, #0x5c]
	cmp r0, #4
	mov.w r7, #2
	beq.w .L08038fba
	b.n .L08039d78
.L08039d72:
	movs r7, #6
	b.n .L08039d78
.L08039d76:
	movs r7, #2
@ common return: r7 = return code
.L08039d78:
	mov r0, r7
	add sp, #0x6c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08039d80:
	movs r7, #6
	b.n .L08039d78
.L08039d84:
	movs r7, #6
	b.n .L08039d78
.L08039d88:
	movs r7, #3
	b.n .L08039d78
.L08039d8c:
	movs r7, #3
	b.n .L08039d78
.L08039d90:
	movs r7, #6
	b.n .L08039d78
.L08039d94:
	movs r7, #6
	b.n .L08039d78
.L08039d98:
	movs r7, #6
	b.n .L08039d78
.L08039d9c:
	movs r7, #6
	b.n .L08039d78
.L08039da0:
	movs r7, #3
	b.n .L08039d78
.L08039da4:
	movs r7, #3
	b.n .L08039d78
.L08039da8:
	movs r7, #6
	b.n .L08039d78
.L08039dac:
	movs r7, #3
	b.n .L08039d78
.L08039db0:
	movs r7, #6
	b.n .L08039d78
.L08039db4:
	movs r7, #3
	b.n .L08039d78
.L08039db8:
	movs r7, #6
	b.n .L08039d78
.L08039dbc:
	movs r7, #6
	b.n .L08039d78
.L08039dc0:
	movs r7, #6
	b.n .L08039d78
@ marker 0xda: scan header
.L08039dc4:
	cmp.w r2, #0x200
	bls.n .L08039e0a
	movs r7, #4
	b.n .L08039d78
.L08039dce:
	movs r7, #4
	b.n .L08039d78
.L08039dd2:
	movs r7, #4
	b.n .L08039d78
.L08039dd6:
	movs r7, #2
	b.n .L08039d78
.L08039dda:
	movs r7, #4
	b.n .L08039d78
.L08039dde:
	movs r7, #4
	b.n .L08039d78
.L08039de2:
	movs r7, #2
	b.n .L08039d78
.L08039de6:
	movs r7, #2
	b.n .L08039d78
.L08039dea:
	movs r7, #2
	b.n .L08039d78
.L08039dee:
	movs r7, #2
	b.n .L08039d78
.L08039df2:
	movs r7, #8
	b.n .L08039d78
.L08039df6:
	movs r7, #8
	b.n .L08039d78
.L08039dfa:
	movs r7, #8
	b.n .L08039d78
.L08039dfe:
	movs r7, #8
	b.n .L08039d78
.L08039e02:
	movs r7, #8
	b.n .L08039d78
.L08039e06:
	movs r7, #8
	b.n .L08039d78
.L08039e0a:
	ldr.w r3, [r8, #0x74]
	mov r0, r8
	mov r1, r9
	mov r5, r2
	blx r3
	cmp r0, r5
	bne.n .L08039ec0
	ldr.w r0, [r8, #0x1c]
	cmp r0, #0
	beq.n .L08039ec4
	ldr.w r0, [r8, #0x20]
	cmp r0, #0
	beq.n .L08039ec8
	ldrb.w r0, [r9]
	cmp r0, #3
	bne.n .L08039ecc
	ldrb.w r0, [r9, #2]
	cbz r0, .L08039e3c
	cmp r0, #0x11
	bne.n .L08039ed0
.L08039e3c:
	ldr r0, [sp, #0x68]
	ldr r0, [r0]
	cmp r0, #0
	beq.n .L08039ed4
	ldr.w r0, [r8, #0x28]
	cmp r0, #0
	beq.n .L08039ed8
	ldrb.w r0, [r8, #0x10]
	add.w r0, r8, r0, lsl #2
	ldr r0, [r0, #0x54]
	cmp r0, #0
	beq.n .L08039edc
	ldrb.w r0, [r9, #4]
	cbz r0, .L08039e64
	cmp r0, #0x11
	bne.n .L08039ee0
.L08039e64:
	ldr.w r0, [r8, #0x2c]
	cbz r0, .L08039ee4
	ldr.w r0, [r8, #0x30]
	cbz r0, .L08039ee8
	ldrb.w r0, [r8, #0x11]
	add.w r0, r8, r0, lsl #2
	ldr r0, [r0, #0x54]
	cbz r0, .L08039eec
	ldrb.w r0, [r9, #6]
	cmp r0, #0x11
	beq.n .L08039e86
	cbnz r0, .L08039ef0
.L08039e86:
	ldrb.w r0, [r8, #0x12]
	add.w r0, r8, r0, lsl #2
	ldr r0, [r0, #0x54]
	cbz r0, .L08039ef4
	ldrb.w r0, [r8, #0xe]
	ldrb.w r1, [r8, #0xf]
	muls r0, r1, r0
	cbz r0, .L08039ef8
	lsls r1, r0, #7
	add.w r2, r1, #0x40
	ldr.w r1, [r8, #0x70]
	cmp.w r2, #0x100
	it ls
	movls.w r2, #0x100
	cmp r1, r2
	bcs.n .L08039efc
	movs r0, #0
	str.w r0, [r8, #0x64]
	movs r7, #3
	b.n .L08039d78
.L08039ec0:
	movs r7, #2
	b.n .L08039d78
.L08039ec4:
	movs r7, #6
	b.n .L08039d78
.L08039ec8:
	movs r7, #6
	b.n .L08039d78
.L08039ecc:
	movs r7, #8
	b.n .L08039d78
.L08039ed0:
	movs r7, #8
	b.n .L08039d78
.L08039ed4:
	movs r7, #6
	b.n .L08039d78
.L08039ed8:
	movs r7, #6
	b.n .L08039d78
.L08039edc:
	movs r7, #6
	b.n .L08039d78
.L08039ee0:
	movs r7, #8
	b.n .L08039d78
.L08039ee4:
	movs r7, #6
	b.n .L08039d78
.L08039ee8:
	movs r7, #6
	b.n .L08039d78
.L08039eec:
	movs r7, #6
	b.n .L08039d78
.L08039ef0:
	movs r7, #8
	b.n .L08039d78
.L08039ef4:
	movs r7, #6
	b.n .L08039d78
.L08039ef8:
	movs r7, #6
	b.n .L08039d78
.L08039efc:
	ldr.w r3, [r8, #0x6c]
	subs r1, r1, r2
	add r2, r3
	str.w r1, [r8, #0x70]
	str.w r2, [r8, #0x6c]
	str.w r3, [r8, #0x64]
	cbz r3, .L08039f2a
	movs r3, #0x83
	add.w r0, r3, r0, lsl #6
	bic.w r0, r0, #3
	cmp r1, r0
	bcs.n .L08039f2e
	.include "src/parts/parse_jpeg_header_p2.inc"
