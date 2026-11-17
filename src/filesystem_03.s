@ filesystem_03.s - FAT directory search: find_directory_entry_by_name (part 1 of 2, first 4096 bytes; part 2 follows from the include at the end of this file).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ find_directory_entry_by_name - searches a directory for an entry matching a
@ short or a long name.
@ Parameter param_1 (r0) = pointer to the search state:
@   param_1[0]   = volume context ctx
@   param_1[4]   = byte position in the directory
@   param_1[5]   = cluster (0 = fixed root area)
@   param_1[6]   = sector (0x1000-byte block) number
@   param_1[7]   = pointer to the current 32-byte entry
@   11 bytes at byte offset 0x20 = short name searched
@   byte +0x2b = flags (bit0 set: skip the short-name compare, bit6 set: skip
@                long-name entries)
@   byte +6 receives attribute & 0x3f
@   ctx+0xc = pointer to the UTF-16 long name searched
@ Returns (r0): 0 = found, 4 = end of directory / not found, 1 = read error or
@ bad medium byte, 2 = chain entry < 2, or the nonzero result of 08033e94.
@ Starts with 08033e94(param_1, 0) (position 0), sets param_1[0xb] = -1.
@ Block cache = ctx+0x34 with block number ctx[0x30], dirty byte ctx[3]: when
@ another block is needed a dirty cache is written back with 0803616c (address
@ block << 12 for medium byte ctx[1] == 3, block * 0x1000 + 0x200000 for 2,
@ else returns 1; also a second copy at block + ctx[0x1c] when ctx[2] == 2 and
@ the block lies in the table area), then 08036048 loads the block at address
@ block << 12 / + 0x200000.
@ Per entry: first byte 0 returns 4; first byte 0xe5, or attribute bit3 set with
@ attribute & 0x3f != 0xf, resets the long-name state (param_1[0xb] = -1,
@ expected sequence 0xff).
@ attribute & 0x3f == 0xf (long-name entry): the entry with sequence bit 0x40
@ sets the checksum (byte +0xd), expected sequence = byte & 0xbf and
@ param_1[0xb] = param_1[4]; every long-name entry needs the expected sequence,
@ the same checksum, halfword +0x1a == 0 and (sequence & 0x3f)*13 - 13 < 0x100,
@ then compares its 13 UTF-16 characters (offsets 1,3,5,7,9,0xe,0x10,0x12,0x14,
@ 0x16,0x18,0x1c,0x1e) one by one with the search name characters at
@ ctx[3] + 2*((sequence*13)-13+i), both case-folded through the range tables
@ 0x080be118 (code < 0x1000) / 0x080be05c (others) with operations table
@ lookup, alternate step, -0x10, -0x20, -0x30, -0x1a, +8, -0x50, -0x1c60/+0xe3a0;
@ every character's name index must be < 0x100; after a 0 character only 0xffff
@ may follow; a mismatch or a failed condition sets the expected sequence to
@ 0xff and leaves param_1[0xb] unchanged (0x080317c0, 0x08032daa); when the last
@ character (offset 0x1e) matches, is nonzero, the entry's first byte has bit
@ 0x40 set and the next search-name character is nonzero, the entry counts as a
@ mismatch (0x08032d8c..0x08032d98, 0x08032d9e..0x08032da8); otherwise a full
@ match decrements the expected sequence (0x08032d9a subs r6,#1).
@ Short entry: returns 0 when the expected sequence reached 0 and the
@ rotate-right-by-one-and-add checksum over bytes 0..10 equals the stored
@ checksum, or when flags bit0 is clear and 0800773c(entry, param_1+0x20, 0xb)
@ == 0; otherwise resets the long-name state.
@ Advance: position + 0x20 (above 0x1fffff, or sector 0, returns 4); at a 0x1000
@ boundary sector + 1; in the root area (cluster 0) position >> 5 >= ushort
@ ctx[8] ends with 4; at a cluster boundary
@ ((ushort ctx+10 + 0xfffff) & (position >> 12) == 0) the next cluster comes
@ from 08036f18 (< 2 returns 2, -1 returns 1, >= ctx[0x18] returns 4),
@ sector = (cluster-2) * ushort ctx[10] + ctx[0x2c]; param_1[7] =
@ ctx + 0x34 + (position & 0xfff).
@ ----------------------------------------------------------------------------
	.section .text.find_directory_entry_by_name,"ax",%progbits
	.global find_directory_entry_by_name
	.thumb_func
	.type find_directory_entry_by_name, %function
find_directory_entry_by_name:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0x1c
	ldr.w	r8, [r0, #0x0]
	movs	r1, #0x0
	mov	r4, r0
	bl	dir_set_offset
	cbz	r0, .L0803167e
	add	sp, #0x1c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803167e:
	mov.w	r0, #0xffffffff
	str	r0, [r4, #0x2c]
	add.w	r0, r8, #0x34
	movw	r5, #0xffff
	str	r0, [sp, #0x18]
	add.w	r0, r4, #0x20
	ldr.w	r9, [r4, #0x18]
	movt	r5, #0xf
	str	r0, [sp, #0x10]
	movs	r6, #0xff
	movs	r0, #0xff
	str	r0, [sp, #0x14]
	b.n	.L080316bc
.L080316a4:
	ldrh	r0, [r7, #0x8]
	cmp.w	r0, r11, lsr #0x5
	bls.w	.L08032db8
	nop
.L080316b0:
	add.w	r0, r7, r10
	adds	r0, #0x34
	str.w	r11, [r4, #0x10]
	str	r0, [r4, #0x1c]
.L080316bc:
	ldr.w	r7, [r8, #0x30]
	cmp	r7, r9
	beq.n	.L0803179c
	ldrb.w	r0, [r8, #0x3]
	cmp	r0, #0x0
	beq.n	.L08031754
	ldrb.w	r0, [r8, #0x1]
	cmp	r0, #0x3
	beq.n	.L080316e8
	cmp	r0, #0x2
	bne.w	.L08032dcc
	nop.w
	mov.w	r0, #0x200000
	add.w	r7, r0, r7, lsl #0xc
	b.n	.L080316ee
.L080316e8:
	nop.w
	lsls	r7, r7, #0xc
.L080316ee:
	nop.w
	ldr	r0, [sp, #0x18]
	mov	r1, r7
	mov.w	r2, #0x1000
	bl	serial_device_write_merge
	ldr.w	r0, [r8, #0x24]
	ldr.w	r1, [r8, #0x30]
	ldr.w	r2, [r8, #0x1c]
	subs	r0, r1, r0
	cmp	r0, r2
	mov.w	r0, #0x0
	strb.w	r0, [r8, #0x3]
	bcs.n	.L08031754
	ldrb.w	r0, [r8, #0x2]
	cmp	r0, #0x2
	bne.n	.L08031754
	ldrb.w	r0, [r8, #0x1]
	adds	r5, r2, r1
	cmp	r0, #0x3
	beq.n	.L0803173c
	cmp	r0, #0x2
	bne.n	.L08031758
	nop.w
	mov.w	r0, #0x200000
	add.w	r7, r0, r5, lsl #0xc
	b.n	.L08031742
.L0803173c:
	nop.w
	lsls	r7, r5, #0xc
.L08031742:
	nop.w
	ldr	r0, [sp, #0x18]
	mov	r1, r7
	mov.w	r2, #0x1000
	bl	serial_device_write_merge
	nop
.L08031754:
	ldrb.w	r0, [r8, #0x1]
.L08031758:
	cmp	r0, #0x3
	beq.n	.L08031778
	movw	r5, #0xffff
	cmp	r0, #0x2
	movt	r5, #0xf
	bne.w	.L08032dc4
	nop.w
	mov.w	r0, #0x200000
	add.w	r7, r0, r9, lsl #0xc
	b.n	.L08031788
.L08031778:
	nop.w
	movw	r5, #0xffff
	lsl.w	r7, r9, #0xc
	movt	r5, #0xf
.L08031788:
	nop.w
	ldr	r0, [sp, #0x18]
	mov	r1, r7
	mov.w	r2, #0x1000
	bl	serial_device_read
	str.w	r9, [r8, #0x30]
.L0803179c:
	ldr	r0, [r4, #0x1c]
	ldrb	r1, [r0, #0x0]
	cmp	r1, #0x0
	beq.w	.L08032dbc
	ldrb	r3, [r0, #0xb]
	cmp	r1, #0xe5
	and	r2, r3, #0x3f
	strb	r2, [r4, #0x6]
	beq.n	.L080317ba
	lsls	r3, r3, #0x1c
	bpl.n	.L08031838
	cmp	r2, #0xf
	beq.n	.L08031838
.L080317ba:
	mov.w	r0, #0xffffffff
	str	r0, [r4, #0x2c]
.L080317c0:
	movs	r6, #0xff
.L080317c2:
	ldr	r0, [r4, #0x10]
	add.w	r11, r0, #0x20
	add.w	r0, r5, #0x100000
	cmp	r11, r0
	bhi.w	.L08032db8
	ldr.w	r9, [r4, #0x18]
	cmp.w	r9, #0x0
	beq.w	.L08032dbc
	mov	r10, r11
	ldr	r7, [r4, #0x0]
	bfc	r10, #0xc, #0x14
	cmp.w	r10, #0x0
	bne.w	.L080316b0
	ldr	r1, [r4, #0x14]
	add.w	r9, r9, #0x1
	cmp	r1, #0x0
	str.w	r9, [r4, #0x18]
	beq.w	.L080316a4
	ldrh	r0, [r7, #0xa]
	add	r0, r5
	tst.w	r0, r11, lsr #0xc
	bne.w	.L080316b0
	mov	r0, r7
	bl	allocation_table_read
	cmp	r0, #0x2
	bcc.w	.L08032ddc
	adds	r1, r0, #0x1
	beq.w	.L08032dcc
	ldr	r1, [r7, #0x18]
	cmp	r0, r1
	bcs.w	.L08032db8
	subs	r2, r0, #0x2
	subs	r1, #0x2
	cmp	r2, r1
	str	r0, [r4, #0x14]
	bcs.n	.L080318fe
	ldr	r0, [r7, #0x2c]
	ldrh	r1, [r7, #0xa]
	mla	r9, r2, r1, r0
	b.n	.L08031902
.L08031838:
	cmp	r2, #0xf
	bne.n	.L08031852
	ldrb.w	r2, [r4, #0x2b]
	lsls	r2, r2, #0x19
	bmi.n	.L080317c2
	lsls	r2, r1, #0x19
	bmi.n	.L08031908
	uxtb	r2, r6
	cmp	r1, r2
	bne.n	.L080317c0
	ldr	r3, [sp, #0x14]
	b.n	.L08031912
@ short entry: checksum over the 11 name bytes (rotate right by one and add)
.L08031852:
	lsls	r1, r6, #0x18
	ldr	r6, [sp, #0x14]
	bne.n	.L080318e2
	ldrb	r1, [r0, #0x0]
	ldrb	r2, [r0, #0x1]
	lsrs	r5, r1, #0x1
	orr.w	r1, r5, r1, lsl #0x7
	ldrb	r3, [r0, #0x2]
	add	r1, r2
	uxtb	r1, r1
	add.w	r2, r3, r1, lsl #0x7
	ldrb	r7, [r0, #0x3]
	add.w	r1, r2, r1, lsr #0x1
	uxtb	r1, r1
	add.w	r2, r7, r1, lsl #0x7
	add.w	r1, r2, r1, lsr #0x1
	ldrb	r2, [r0, #0x4]
	uxtb	r1, r1
	add.w	r2, r2, r1, lsl #0x7
	add.w	r1, r2, r1, lsr #0x1
	ldrb	r2, [r0, #0x5]
	uxtb	r1, r1
	add.w	r2, r2, r1, lsl #0x7
	add.w	r1, r2, r1, lsr #0x1
	ldrb	r2, [r0, #0x6]
	uxtb	r1, r1
	add.w	r2, r2, r1, lsl #0x7
	add.w	r1, r2, r1, lsr #0x1
	ldrb	r2, [r0, #0x7]
	uxtb	r1, r1
	add.w	r2, r2, r1, lsl #0x7
	add.w	r1, r2, r1, lsr #0x1
	ldrb	r2, [r0, #0x8]
	uxtb	r1, r1
	add.w	r2, r2, r1, lsl #0x7
	add.w	r1, r2, r1, lsr #0x1
	ldrb	r2, [r0, #0x9]
	uxtb	r1, r1
	add.w	r2, r2, r1, lsl #0x7
	add.w	r1, r2, r1, lsr #0x1
	uxtb	r1, r1
	lsrs	r2, r1, #0x1
	ldrb	r3, [r0, #0xa]
	orr.w	r1, r2, r1, lsl #0x7
	add	r1, r3
	movw	r5, #0xffff
	uxtb	r1, r1
	uxtb	r2, r6
	movt	r5, #0xf
	cmp	r2, r1
	beq.w	.L08032dd4
.L080318e2:
	ldrb.w	r1, [r4, #0x2b]
	lsls	r1, r1, #0x1f
	bne.w	.L080317ba
	ldr	r1, [sp, #0x10]
	movs	r2, #0xb
	bl	compare_bytes
	cmp	r0, #0x0
	bne.w	.L080317ba
	b.w	.L08032dd4
.L080318fe:
	mov.w	r9, #0x0
.L08031902:
	str.w	r9, [r4, #0x18]
	b.n	.L080316b0
@ long-name entry with sequence bit 0x40: record checksum, expected sequence
.L08031908:
	ldr	r2, [r4, #0x10]
	ldrb	r3, [r0, #0xd]
	and	r6, r1, #0xbf
	str	r2, [r4, #0x2c]
.L08031912:
	ldrb	r1, [r0, #0xd]
	uxtb	r2, r3
	cmp	r2, r1
	str	r3, [sp, #0x14]
	bne.w	.L080317c0
	ldrh	r1, [r0, #0x1a]
	cmp	r1, #0x0
	bne.w	.L080317c0
	ldrb	r3, [r0, #0x0]
	movs	r2, #0xd
	and	r1, r3, #0x3f
	muls	r1, r2, r1
	sub.w	r12, r1, #0xd
	cmp.w	r12, #0xff
	bhi.w	.L080317c0
	strd	r3, r1, [sp, #0x4]
	ldrb.w	lr, [r0, #0x1]
	ldrb	r1, [r0, #0x2]
	movw	r7, #:lower16:d_080be05c
	orr.w	r11, lr, r1, lsl #0x8
	movw	r1, #:lower16:d_080be118
	uxth.w	r2, r11
	movt	r7, #:upper16:d_080be05c
	movt	r1, #:upper16:d_080be118
	cmp.w	r2, #0x1000
	it	cc
	movcc	r7, r1
	ldrh	r3, [r7, #0x0]
	ldr.w	r1, [r8, #0xc]
	str	r1, [sp, #0xc]
.L0803196e:
	subs	r1, r3, #0x1
	uxth	r1, r1
	cmp	r1, r2
	bcs.n	.L080319a4
	ldrh	r1, [r7, #0x2]
	uxth.w	r10, r3
	uxtab	r5, r10, r1
	add.w	r9, r7, #0x4
	cmp	r5, r2
	lsr.w	r5, r1, #0x8
	bhi.n	.L080319fc
	movs	r3, #0x0
	uxtb	r1, r1
	cmp	r5, #0x0
	it	eq
	moveq	r3, r1
	mov	r7, r9
	ldrh.w	r3, [r9, r3, lsl #0x1]
	it	eq
	addeq.w	r7, r7, r1, lsl #0x1
	b.n	.L0803196e
.L080319a4:
	mov	r1, r11
.L080319a6:
	mov	lr, r1
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	r12, [r1, r12, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r12, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L080319c8:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r12
	bcs.w	.L08031aa4
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, r12
	lsr.w	r3, r1, #0x8
	bhi.n	.L08031a1a
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L080319c8
.L080319fc:
	cmp	r5, #0x8
	mov	r1, r11
	bhi.n	.L080319a6
	tbb	[pc, r5]
.L08031a06:
	.byte	(.L08031a10 - .L08031a06)/2
	.byte	(.L08031a36 - .L08031a06)/2
	.byte	(.L08031a44 - .L08031a06)/2
	.byte	(.L08031a4a - .L08031a06)/2
	.byte	(.L08031a50 - .L08031a06)/2
	.byte	(.L08031a56 - .L08031a06)/2
	.byte	(.L08031a5c - .L08031a06)/2
	.byte	(.L08031a62 - .L08031a06)/2
	.byte	(.L08031a68 - .L08031a06)/2
	.byte	0x00	@ padding
.L08031a10:
	sub.w	r1, r2, r10
	ldrh.w	r1, [r9, r1, lsl #0x1]
	b.n	.L080319a6
.L08031a1a:
	cmp	r3, #0x8
	bhi.n	.L08031aa4
	tbb	[pc, r3]
.L08031a22:
	.byte	(.L08031a2c - .L08031a22)/2
	.byte	(.L08031a6e - .L08031a22)/2
	.byte	(.L08031a7c - .L08031a22)/2
	.byte	(.L08031a82 - .L08031a22)/2
	.byte	(.L08031a88 - .L08031a22)/2
	.byte	(.L08031a8e - .L08031a22)/2
	.byte	(.L08031a94 - .L08031a22)/2
	.byte	(.L08031a9a - .L08031a22)/2
	.byte	(.L08031aa0 - .L08031a22)/2
	.byte	0x00	@ padding
.L08031a2c:
	sub.w	r1, r12, r5
	ldrh.w	r12, [r7, r1, lsl #0x1]
	b.n	.L08031aa4
.L08031a36:
	sub.w	r1, lr, r3
	and	r1, r1, #0x1
	sub.w	r1, r11, r1
	b.n	.L080319a6
.L08031a44:
	sub.w	r1, r11, #0x10
	b.n	.L080319a6
.L08031a4a:
	sub.w	r1, r11, #0x20
	b.n	.L080319a6
.L08031a50:
	sub.w	r1, r11, #0x30
	b.n	.L080319a6
.L08031a56:
	sub.w	r1, r11, #0x1a
	b.n	.L080319a6
.L08031a5c:
	add.w	r1, r11, #0x8
	b.n	.L080319a6
.L08031a62:
	sub.w	r1, r11, #0x50
	b.n	.L080319a6
.L08031a68:
	sub.w	r1, r11, #0x1c60
	b.n	.L080319a6
.L08031a6e:
	sub.w	r1, r12, r2
	and	r1, r1, #0x1
	sub.w	r12, r12, r1
	b.n	.L08031aa4
.L08031a7c:
	sub.w	r12, r12, #0x10
	b.n	.L08031aa4
.L08031a82:
	sub.w	r12, r12, #0x20
	b.n	.L08031aa4
.L08031a88:
	sub.w	r12, r12, #0x30
	b.n	.L08031aa4
.L08031a8e:
	sub.w	r12, r12, #0x1a
	b.n	.L08031aa4
.L08031a94:
	add.w	r12, r12, #0x8
	b.n	.L08031aa4
.L08031a9a:
	sub.w	r12, r12, #0x50
	b.n	.L08031aa4
.L08031aa0:
	sub.w	r12, r12, #0x1c60
.L08031aa4:
	uxth.w	r1, r12
	uxth.w	r2, lr
	cmp	r2, r1
	bne.w	.L08032daa
	ldr	r1, [sp, #0x8]
	ldrb.w	r9, [r0, #0x3]
	sub.w	r7, r1, #0xc
	ldrb	r1, [r0, #0x4]
	movw	r5, #0xffff
	lsls.w	r2, r11, #0x10
	orr.w	lr, r9, r1, lsl #0x8
	movt	r5, #0xf
	beq.n	.L08031b90
	cmp	r7, #0xff
	bhi.w	.L080317c0
	movw	r12, #:lower16:d_080be05c
	uxth.w	r10, lr
	movt	r12, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r10, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r12, r1
	ldrh.w	r2, [r12, #0x0]
	mov	r11, lr
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r10
	bcs.n	.L08031b3e
	str	r7, [sp, #0x0]
.L08031b02:
	ldrh.w	r7, [r12, #0x2]
	uxth	r5, r2
	uxtab	r1, r5, r7
	add.w	r3, r12, #0x4
	cmp	r1, r10
	lsr.w	r1, r7, #0x8
	bhi.n	.L08031bc0
	cmp	r1, #0x0
	mov.w	r1, #0x0
	uxtb	r5, r7
	it	eq
	moveq	r1, r5
	ldrh.w	r2, [r3, r1, lsl #0x1]
	mov	r12, r3
	sub.w	r1, r2, #0x1
	uxth	r1, r1
	it	eq
	addeq.w	r12, r12, r5, lsl #0x1
	cmp	r1, r10
	bcc.n	.L08031b02
	mov	r11, lr
.L08031b3c:
	ldr	r7, [sp, #0x0]
.L08031b3e:
	ldr	r1, [sp, #0xc]
	ldrh.w	r12, [r1, r7, lsl #0x1]
	movw	r7, #:lower16:d_080be05c
	movt	r7, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r12, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r7, r1
	ldrh	r2, [r7, #0x0]
.L08031b5e:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r12
	bcs.n	.L08031c1e
	ldrh	r1, [r7, #0x2]
	uxth	r5, r2
	adds	r3, r7, #0x4
	uxtab	r7, r5, r1
	cmp	r7, r12
	lsr.w	r7, r1, #0x8
	bhi.n	.L08031ba4
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r7, #0x0
	it	eq
	moveq	r2, r1
	mov	r7, r3
	ldrh.w	r2, [r3, r2, lsl #0x1]
	it	eq
	addeq.w	r7, r7, r1, lsl #0x1
	b.n	.L08031b5e
.L08031b90:
	uxth.w	r1, lr
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L080317c0
	mov.w	lr, #0x0
	b.n	.L08031c3a
.L08031ba4:
	cmp	r7, #0x8
	bhi.n	.L08031c1e
	tbb	[pc, r7]
.L08031bac:
	.byte	(.L08031bb6 - .L08031bac)/2
	.byte	(.L08031be8 - .L08031bac)/2
	.byte	(.L08031bf6 - .L08031bac)/2
	.byte	(.L08031bfc - .L08031bac)/2
	.byte	(.L08031c02 - .L08031bac)/2
	.byte	(.L08031c08 - .L08031bac)/2
	.byte	(.L08031c0e - .L08031bac)/2
	.byte	(.L08031c14 - .L08031bac)/2
	.byte	(.L08031c1a - .L08031bac)/2
	.byte	0x00	@ padding
.L08031bb6:
	sub.w	r1, r12, r5
	ldrh.w	r12, [r3, r1, lsl #0x1]
	b.n	.L08031c1e
.L08031bc0:
	ldr	r7, [sp, #0x0]
	cmp	r1, #0x8
	mov	r11, lr
	bhi.n	.L08031b3e
	tbh	[pc, r1, lsl #1]
.L08031bcc:
	.short	(.L08031bde - .L08031bcc)/2
	.short	(.L08031d56 - .L08031bcc)/2
	.short	(.L08031d64 - .L08031bcc)/2
	.short	(.L08031d6a - .L08031bcc)/2
	.short	(.L08031d70 - .L08031bcc)/2
	.short	(.L08031d76 - .L08031bcc)/2
	.short	(.L08031d7c - .L08031bcc)/2
	.short	(.L08031d82 - .L08031bcc)/2
	.short	(.L08031d88 - .L08031bcc)/2
.L08031bde:
	sub.w	r1, r10, r5
	ldrh.w	r11, [r3, r1, lsl #0x1]
	b.n	.L08031b3c
.L08031be8:
	sub.w	r1, r12, r2
	and	r1, r1, #0x1
	sub.w	r12, r12, r1
	b.n	.L08031c1e
.L08031bf6:
	sub.w	r12, r12, #0x10
	b.n	.L08031c1e
.L08031bfc:
	sub.w	r12, r12, #0x20
	b.n	.L08031c1e
.L08031c02:
	sub.w	r12, r12, #0x30
	b.n	.L08031c1e
.L08031c08:
	sub.w	r12, r12, #0x1a
	b.n	.L08031c1e
.L08031c0e:
	add.w	r12, r12, #0x8
	b.n	.L08031c1e
.L08031c14:
	sub.w	r12, r12, #0x50
	b.n	.L08031c1e
.L08031c1a:
	sub.w	r12, r12, #0x1c60
.L08031c1e:
	uxth.w	r1, r12
	uxth.w	r2, r11
	cmp	r2, r1
	bne.w	.L08032daa
	ldr	r1, [sp, #0x8]
	movw	r5, #0xffff
	sub.w	r7, r1, #0xb
	movt	r5, #0xf
.L08031c3a:
	ldrb.w	r9, [r0, #0x5]
	ldrb	r1, [r0, #0x6]
	lsls.w	r2, lr, #0x10
	orr.w	r12, r9, r1, lsl #0x8
	beq.n	.L08031d06
	cmp	r7, #0xff
	bhi.w	.L080317c0
	movw	r3, #:lower16:d_080be05c
	uxth.w	lr, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
	mov	r10, r12
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.n	.L08031cb0
	mov	r11, r7
.L08031c7a:
	ldrh	r7, [r3, #0x2]
	uxth	r5, r2
	adds	r1, r3, #0x4
	uxtab	r3, r5, r7
	cmp	r3, lr
	lsr.w	r3, r7, #0x8
	bhi.n	.L08031d1a
	movs	r2, #0x0
	uxtb	r5, r7
	cmp	r3, #0x0
	it	eq
	moveq	r2, r5
	ldrh.w	r2, [r1, r2, lsl #0x1]
	mov	r3, r1
	sub.w	r1, r2, #0x1
	uxth	r1, r1
	it	eq
	addeq.w	r3, r3, r5, lsl #0x1
	cmp	r1, lr
	bcc.n	.L08031c7a
	mov	r10, r12
.L08031cae:
	mov	r7, r11
.L08031cb0:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	lr, [r1, r7, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
	mov	r9, r7
.L08031cd2:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.w	.L08031dfc
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L08031d3a
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L08031cd2
.L08031d06:
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L080317c0
	mov.w	r12, #0x0
	b.n	.L08031e18
.L08031d1a:
	cmp	r3, #0x8
	mov	r10, r12
	mov	r7, r11
	bhi.n	.L08031cb0
	tbb	[pc, r3]
.L08031d26:
	.byte	(.L08031d30 - .L08031d26)/2
	.byte	(.L08031d8e - .L08031d26)/2
	.byte	(.L08031d9c - .L08031d26)/2
	.byte	(.L08031da2 - .L08031d26)/2
	.byte	(.L08031da8 - .L08031d26)/2
	.byte	(.L08031dae - .L08031d26)/2
	.byte	(.L08031db4 - .L08031d26)/2
	.byte	(.L08031dba - .L08031d26)/2
	.byte	(.L08031dc0 - .L08031d26)/2
	.byte	0x00	@ padding
.L08031d30:
	sub.w	r2, lr, r5
	ldrh.w	r10, [r1, r2, lsl #0x1]
	b.n	.L08031cae
.L08031d3a:
	cmp	r3, #0x8
	bhi.n	.L08031dfc
	tbb	[pc, r3]
.L08031d42:
	.byte	(.L08031d4c - .L08031d42)/2
	.byte	(.L08031dc6 - .L08031d42)/2
	.byte	(.L08031dd4 - .L08031d42)/2
	.byte	(.L08031dda - .L08031d42)/2
	.byte	(.L08031de0 - .L08031d42)/2
	.byte	(.L08031de6 - .L08031d42)/2
	.byte	(.L08031dec - .L08031d42)/2
	.byte	(.L08031df2 - .L08031d42)/2
	.byte	(.L08031df8 - .L08031d42)/2
	.byte	0x00	@ padding
.L08031d4c:
	sub.w	r1, lr, r5
	ldrh.w	lr, [r7, r1, lsl #0x1]
	b.n	.L08031dfc
.L08031d56:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r11, lr, r1
	b.n	.L08031b3c
.L08031d64:
	sub.w	r11, lr, #0x10
	b.n	.L08031b3c
.L08031d6a:
	sub.w	r11, lr, #0x20
	b.n	.L08031b3c
.L08031d70:
	sub.w	r11, lr, #0x30
	b.n	.L08031b3c
.L08031d76:
	sub.w	r11, lr, #0x1a
	b.n	.L08031b3c
.L08031d7c:
	add.w	r11, lr, #0x8
	b.n	.L08031b3c
.L08031d82:
	sub.w	r11, lr, #0x50
	b.n	.L08031b3c
.L08031d88:
	sub.w	r11, lr, #0x1c60
	b.n	.L08031b3c
.L08031d8e:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r10, r12, r1
	b.n	.L08031cae
.L08031d9c:
	sub.w	r10, r12, #0x10
	b.n	.L08031cae
.L08031da2:
	sub.w	r10, r12, #0x20
	b.n	.L08031cae
.L08031da8:
	sub.w	r10, r12, #0x30
	b.n	.L08031cae
.L08031dae:
	sub.w	r10, r12, #0x1a
	b.n	.L08031cae
.L08031db4:
	add.w	r10, r12, #0x8
	b.n	.L08031cae
.L08031dba:
	sub.w	r10, r12, #0x50
	b.n	.L08031cae
.L08031dc0:
	sub.w	r10, r12, #0x1c60
	b.n	.L08031cae
.L08031dc6:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	lr, lr, r1
	b.n	.L08031dfc
.L08031dd4:
	sub.w	lr, lr, #0x10
	b.n	.L08031dfc
.L08031dda:
	sub.w	lr, lr, #0x20
	b.n	.L08031dfc
.L08031de0:
	sub.w	lr, lr, #0x30
	b.n	.L08031dfc
.L08031de6:
	sub.w	lr, lr, #0x1a
	b.n	.L08031dfc
.L08031dec:
	add.w	lr, lr, #0x8
	b.n	.L08031dfc
.L08031df2:
	sub.w	lr, lr, #0x50
	b.n	.L08031dfc
.L08031df8:
	sub.w	lr, lr, #0x1c60
.L08031dfc:
	uxth.w	r1, lr
	uxth.w	r2, r10
	cmp	r2, r1
	bne.w	.L08032daa
	mov	r7, r9
	movw	r5, #0xffff
	add.w	r7, r9, #0x1
	movt	r5, #0xf
.L08031e18:
	ldrb.w	lr, [r0, #0x7]
	ldrb	r1, [r0, #0x8]
	lsls.w	r2, r12, #0x10
	orr.w	r12, lr, r1, lsl #0x8
	beq.n	.L08031ee2
	cmp	r7, #0xff
	bhi.w	.L080317c0
	movw	r3, #:lower16:d_080be05c
	uxth.w	r9, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
	mov	r11, r7
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r9
	mov	r10, r12
	bcs.n	.L08031e8c
.L08031e58:
	ldrh	r7, [r3, #0x2]
	uxth	r5, r2
	adds	r1, r3, #0x4
	uxtab	r3, r5, r7
	cmp	r3, r9
	lsr.w	r3, r7, #0x8
	bhi.n	.L08031ef6
	movs	r2, #0x0
	uxtb	r5, r7
	cmp	r3, #0x0
	it	eq
	moveq	r2, r5
	ldrh.w	r2, [r1, r2, lsl #0x1]
	mov	r3, r1
	sub.w	r1, r2, #0x1
	uxth	r1, r1
	it	eq
	addeq.w	r3, r3, r5, lsl #0x1
	cmp	r1, r9
	bcc.n	.L08031e58
	mov	r10, r12
.L08031e8c:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	lr, [r1, r11, lsl #0x1]
	mov	r2, r11
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L08031eae:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.w	.L08031f9e
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L08031f14
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L08031eae
.L08031ee2:
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L080317c0
	mov.w	r12, #0x0
	b.n	.L08031fb2
.L08031ef6:
	cmp	r3, #0x8
	mov	r10, r12
	bhi.n	.L08031e8c
	tbb	[pc, r3]
.L08031f00:
	.byte	(.L08031f0a - .L08031f00)/2
	.byte	(.L08031f30 - .L08031f00)/2
	.byte	(.L08031f3e - .L08031f00)/2
	.byte	(.L08031f44 - .L08031f00)/2
	.byte	(.L08031f4a - .L08031f00)/2
	.byte	(.L08031f50 - .L08031f00)/2
	.byte	(.L08031f56 - .L08031f00)/2
	.byte	(.L08031f5c - .L08031f00)/2
	.byte	(.L08031f62 - .L08031f00)/2
	.byte	0x00	@ padding
.L08031f0a:
	sub.w	r2, r9, r5
	ldrh.w	r10, [r1, r2, lsl #0x1]
	b.n	.L08031e8c
.L08031f14:
	cmp	r3, #0x8
	bhi.n	.L08031f9e
	tbb	[pc, r3]
.L08031f1c:
	.byte	(.L08031f26 - .L08031f1c)/2
	.byte	(.L08031f68 - .L08031f1c)/2
	.byte	(.L08031f76 - .L08031f1c)/2
	.byte	(.L08031f7c - .L08031f1c)/2
	.byte	(.L08031f82 - .L08031f1c)/2
	.byte	(.L08031f88 - .L08031f1c)/2
	.byte	(.L08031f8e - .L08031f1c)/2
	.byte	(.L08031f94 - .L08031f1c)/2
	.byte	(.L08031f9a - .L08031f1c)/2
	.byte	0x00	@ padding
.L08031f26:
	sub.w	r1, lr, r5
	ldrh.w	lr, [r7, r1, lsl #0x1]
	b.n	.L08031f9e
.L08031f30:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	r10, r12, r1
	b.n	.L08031e8c
.L08031f3e:
	sub.w	r10, r12, #0x10
	b.n	.L08031e8c
.L08031f44:
	sub.w	r10, r12, #0x20
	b.n	.L08031e8c
.L08031f4a:
	sub.w	r10, r12, #0x30
	b.n	.L08031e8c
.L08031f50:
	sub.w	r10, r12, #0x1a
	b.n	.L08031e8c
.L08031f56:
	add.w	r10, r12, #0x8
	b.n	.L08031e8c
.L08031f5c:
	sub.w	r10, r12, #0x50
	b.n	.L08031e8c
.L08031f62:
	sub.w	r10, r12, #0x1c60
	b.n	.L08031e8c
.L08031f68:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	lr, lr, r1
	b.n	.L08031f9e
.L08031f76:
	sub.w	lr, lr, #0x10
	b.n	.L08031f9e
.L08031f7c:
	sub.w	lr, lr, #0x20
	b.n	.L08031f9e
.L08031f82:
	sub.w	lr, lr, #0x30
	b.n	.L08031f9e
.L08031f88:
	sub.w	lr, lr, #0x1a
	b.n	.L08031f9e
.L08031f8e:
	add.w	lr, lr, #0x8
	b.n	.L08031f9e
.L08031f94:
	sub.w	lr, lr, #0x50
	b.n	.L08031f9e
.L08031f9a:
	sub.w	lr, lr, #0x1c60
.L08031f9e:
	uxth.w	r1, lr
	uxth.w	r2, r10
	cmp	r2, r1
	bne.w	.L08032daa
	mov	r7, r11
	add.w	r7, r11, #0x1
.L08031fb2:
	ldrb.w	lr, [r0, #0x9]
	ldrb	r1, [r0, #0xa]
	lsls.w	r2, r12, #0x10
	orr.w	r12, lr, r1, lsl #0x8
	beq.n	.L0803207a
	cmp	r7, #0xff
	bhi.w	.L08032daa
	movw	r3, #:lower16:d_080be05c
	uxth.w	r9, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
	mov	r11, r7
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r9
	mov	r10, r12
	bcs.n	.L08032026
.L08031ff2:
	ldrh	r7, [r3, #0x2]
	uxth	r5, r2
	adds	r1, r3, #0x4
	uxtab	r3, r5, r7
	cmp	r3, r9
	lsr.w	r3, r7, #0x8
	bhi.n	.L08032090
	movs	r2, #0x0
	uxtb	r5, r7
	cmp	r3, #0x0
	it	eq
	moveq	r2, r5
	ldrh.w	r2, [r1, r2, lsl #0x1]
	mov	r3, r1
	sub.w	r1, r2, #0x1
	uxth	r1, r1
	it	eq
	addeq.w	r3, r3, r5, lsl #0x1
	cmp	r1, r9
	bcc.n	.L08031ff2
	mov	r10, r12
.L08032026:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	lr, [r1, r11, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L08032046:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.w	.L08032138
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L080320ae
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L08032046
.L0803207a:
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L08032daa
	mov	r11, r7
	mov.w	r12, #0x0
	b.n	.L0803214a
.L08032090:
	cmp	r3, #0x8
	mov	r10, r12
	bhi.n	.L08032026
	tbb	[pc, r3]
.L0803209a:
	.byte	(.L080320a4 - .L0803209a)/2
	.byte	(.L080320ca - .L0803209a)/2
	.byte	(.L080320d8 - .L0803209a)/2
	.byte	(.L080320de - .L0803209a)/2
	.byte	(.L080320e4 - .L0803209a)/2
	.byte	(.L080320ea - .L0803209a)/2
	.byte	(.L080320f0 - .L0803209a)/2
	.byte	(.L080320f6 - .L0803209a)/2
	.byte	(.L080320fc - .L0803209a)/2
	.byte	0x00	@ padding
.L080320a4:
	sub.w	r2, r9, r5
	ldrh.w	r10, [r1, r2, lsl #0x1]
	b.n	.L08032026
.L080320ae:
	cmp	r3, #0x8
	bhi.n	.L08032138
	tbb	[pc, r3]
.L080320b6:
	.byte	(.L080320c0 - .L080320b6)/2
	.byte	(.L08032102 - .L080320b6)/2
	.byte	(.L08032110 - .L080320b6)/2
	.byte	(.L08032116 - .L080320b6)/2
	.byte	(.L0803211c - .L080320b6)/2
	.byte	(.L08032122 - .L080320b6)/2
	.byte	(.L08032128 - .L080320b6)/2
	.byte	(.L0803212e - .L080320b6)/2
	.byte	(.L08032134 - .L080320b6)/2
	.byte	0x00	@ padding
.L080320c0:
	sub.w	r1, lr, r5
	ldrh.w	lr, [r7, r1, lsl #0x1]
	b.n	.L08032138
.L080320ca:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	r10, r12, r1
	b.n	.L08032026
.L080320d8:
	sub.w	r10, r12, #0x10
	b.n	.L08032026
.L080320de:
	sub.w	r10, r12, #0x20
	b.n	.L08032026
.L080320e4:
	sub.w	r10, r12, #0x30
	b.n	.L08032026
.L080320ea:
	sub.w	r10, r12, #0x1a
	b.n	.L08032026
.L080320f0:
	add.w	r10, r12, #0x8
	b.n	.L08032026
.L080320f6:
	sub.w	r10, r12, #0x50
	b.n	.L08032026
.L080320fc:
	sub.w	r10, r12, #0x1c60
	b.n	.L08032026
.L08032102:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	lr, lr, r1
	b.n	.L08032138
.L08032110:
	sub.w	lr, lr, #0x10
	b.n	.L08032138
.L08032116:
	sub.w	lr, lr, #0x20
	b.n	.L08032138
.L0803211c:
	sub.w	lr, lr, #0x30
	b.n	.L08032138
.L08032122:
	sub.w	lr, lr, #0x1a
	b.n	.L08032138
.L08032128:
	add.w	lr, lr, #0x8
	b.n	.L08032138
.L0803212e:
	sub.w	lr, lr, #0x50
	b.n	.L08032138
.L08032134:
	sub.w	lr, lr, #0x1c60
.L08032138:
	uxth.w	r1, lr
	uxth.w	r2, r10
	cmp	r2, r1
	bne.w	.L08032daa
	add.w	r11, r11, #0x1
.L0803214a:
	ldrb.w	lr, [r0, #0xe]
	ldrb	r1, [r0, #0xf]
	lsls.w	r2, r12, #0x10
	orr.w	r12, lr, r1, lsl #0x8
	beq.n	.L08032212
	cmp.w	r11, #0xff
	bhi.w	.L08032daa
	movw	r3, #:lower16:d_080be05c
	uxth.w	r9, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
	mov	r10, r12
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r9
	bcs.n	.L080321be
.L0803218a:
	ldrh	r7, [r3, #0x2]
	uxth	r5, r2
	adds	r1, r3, #0x4
	uxtab	r3, r5, r7
	cmp	r3, r9
	lsr.w	r3, r7, #0x8
	bhi.n	.L08032226
	movs	r2, #0x0
	uxtb	r5, r7
	cmp	r3, #0x0
	it	eq
	moveq	r2, r5
	ldrh.w	r2, [r1, r2, lsl #0x1]
	mov	r3, r1
	sub.w	r1, r2, #0x1
	uxth	r1, r1
	it	eq
	addeq.w	r3, r3, r5, lsl #0x1
	cmp	r1, r9
	bcc.n	.L0803218a
	mov	r10, r12
.L080321be:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	lr, [r1, r11, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L080321de:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.w	.L080322ce
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L08032244
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L080321de
.L08032212:
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L08032daa
	mov.w	r12, #0x0
	b.n	.L080322e0
.L08032226:
	cmp	r3, #0x8
	mov	r10, r12
	bhi.n	.L080321be
	tbb	[pc, r3]
.L08032230:
	.byte	(.L0803223a - .L08032230)/2
	.byte	(.L08032260 - .L08032230)/2
	.byte	(.L0803226e - .L08032230)/2
	.byte	(.L08032274 - .L08032230)/2
	.byte	(.L0803227a - .L08032230)/2
	.byte	(.L08032280 - .L08032230)/2
	.byte	(.L08032286 - .L08032230)/2
	.byte	(.L0803228c - .L08032230)/2
	.byte	(.L08032292 - .L08032230)/2
	.byte	0x00	@ padding
.L0803223a:
	sub.w	r2, r9, r5
	ldrh.w	r10, [r1, r2, lsl #0x1]
	b.n	.L080321be
.L08032244:
	cmp	r3, #0x8
	bhi.n	.L080322ce
	tbb	[pc, r3]
.L0803224c:
	.byte	(.L08032256 - .L0803224c)/2
	.byte	(.L08032298 - .L0803224c)/2
	.byte	(.L080322a6 - .L0803224c)/2
	.byte	(.L080322ac - .L0803224c)/2
	.byte	(.L080322b2 - .L0803224c)/2
	.byte	(.L080322b8 - .L0803224c)/2
	.byte	(.L080322be - .L0803224c)/2
	.byte	(.L080322c4 - .L0803224c)/2
	.byte	(.L080322ca - .L0803224c)/2
	.byte	0x00	@ padding
.L08032256:
	sub.w	r1, lr, r5
	ldrh.w	lr, [r7, r1, lsl #0x1]
	b.n	.L080322ce
.L08032260:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	r10, r12, r1
	b.n	.L080321be
.L0803226e:
	sub.w	r10, r12, #0x10
	b.n	.L080321be
.L08032274:
	sub.w	r10, r12, #0x20
	b.n	.L080321be
.L0803227a:
	sub.w	r10, r12, #0x30
	b.n	.L080321be
.L08032280:
	sub.w	r10, r12, #0x1a
	b.n	.L080321be
.L08032286:
	add.w	r10, r12, #0x8
	b.n	.L080321be
.L0803228c:
	sub.w	r10, r12, #0x50
	b.n	.L080321be
.L08032292:
	sub.w	r10, r12, #0x1c60
	b.n	.L080321be
.L08032298:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	lr, lr, r1
	b.n	.L080322ce
.L080322a6:
	sub.w	lr, lr, #0x10
	b.n	.L080322ce
.L080322ac:
	sub.w	lr, lr, #0x20
	b.n	.L080322ce
.L080322b2:
	sub.w	lr, lr, #0x30
	b.n	.L080322ce
.L080322b8:
	sub.w	lr, lr, #0x1a
	b.n	.L080322ce
.L080322be:
	add.w	lr, lr, #0x8
	b.n	.L080322ce
.L080322c4:
	sub.w	lr, lr, #0x50
	b.n	.L080322ce
.L080322ca:
	sub.w	lr, lr, #0x1c60
.L080322ce:
	uxth.w	r1, lr
	uxth.w	r2, r10
	cmp	r2, r1
	bne.w	.L08032daa
	add.w	r11, r11, #0x1
.L080322e0:
	ldrb.w	lr, [r0, #0x10]
	ldrb	r1, [r0, #0x11]
	lsls.w	r2, r12, #0x10
	orr.w	r12, lr, r1, lsl #0x8
	beq.n	.L080323a8
	cmp.w	r11, #0xff
	bhi.w	.L08032daa
	movw	r3, #:lower16:d_080be05c
	uxth.w	r9, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
	mov	r10, r12
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r9
	bcs.n	.L08032354
.L08032320:
	ldrh	r7, [r3, #0x2]
	uxth	r5, r2
	adds	r1, r3, #0x4
	uxtab	r3, r5, r7
	cmp	r3, r9
	lsr.w	r3, r7, #0x8
	bhi.n	.L080323bc
	movs	r2, #0x0
	uxtb	r5, r7
	cmp	r3, #0x0
	it	eq
	moveq	r2, r5
	ldrh.w	r2, [r1, r2, lsl #0x1]
	mov	r3, r1
	sub.w	r1, r2, #0x1
	uxth	r1, r1
	it	eq
	addeq.w	r3, r3, r5, lsl #0x1
	cmp	r1, r9
	bcc.n	.L08032320
	mov	r10, r12
.L08032354:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	lr, [r1, r11, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L08032374:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.w	.L08032464
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L080323da
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L08032374
.L080323a8:
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L08032daa
	mov.w	r12, #0x0
	b.n	.L08032476
.L080323bc:
	cmp	r3, #0x8
	mov	r10, r12
	bhi.n	.L08032354
	tbb	[pc, r3]
.L080323c6:
	.byte	(.L080323d0 - .L080323c6)/2
	.byte	(.L080323f6 - .L080323c6)/2
	.byte	(.L08032404 - .L080323c6)/2
	.byte	(.L0803240a - .L080323c6)/2
	.byte	(.L08032410 - .L080323c6)/2
	.byte	(.L08032416 - .L080323c6)/2
	.byte	(.L0803241c - .L080323c6)/2
	.byte	(.L08032422 - .L080323c6)/2
	.byte	(.L08032428 - .L080323c6)/2
	.byte	0x00	@ padding
.L080323d0:
	sub.w	r2, r9, r5
	ldrh.w	r10, [r1, r2, lsl #0x1]
	b.n	.L08032354
.L080323da:
	cmp	r3, #0x8
	bhi.n	.L08032464
	tbb	[pc, r3]
.L080323e2:
	.byte	(.L080323ec - .L080323e2)/2
	.byte	(.L0803242e - .L080323e2)/2
	.byte	(.L0803243c - .L080323e2)/2
	.byte	(.L08032442 - .L080323e2)/2
	.byte	(.L08032448 - .L080323e2)/2
	.byte	(.L0803244e - .L080323e2)/2
	.byte	(.L08032454 - .L080323e2)/2
	.byte	(.L0803245a - .L080323e2)/2
	.byte	(.L08032460 - .L080323e2)/2
	.byte	0x00	@ padding
.L080323ec:
	sub.w	r1, lr, r5
	ldrh.w	lr, [r7, r1, lsl #0x1]
	b.n	.L08032464
.L080323f6:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	r10, r12, r1
	b.n	.L08032354
.L08032404:
	sub.w	r10, r12, #0x10
	b.n	.L08032354
.L0803240a:
	sub.w	r10, r12, #0x20
	b.n	.L08032354
.L08032410:
	sub.w	r10, r12, #0x30
	b.n	.L08032354
.L08032416:
	sub.w	r10, r12, #0x1a
	b.n	.L08032354
.L0803241c:
	add.w	r10, r12, #0x8
	b.n	.L08032354
.L08032422:
	sub.w	r10, r12, #0x50
	b.n	.L08032354
.L08032428:
	sub.w	r10, r12, #0x1c60
	b.n	.L08032354
.L0803242e:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	lr, lr, r1
	b.n	.L08032464
.L0803243c:
	sub.w	lr, lr, #0x10
	b.n	.L08032464
.L08032442:
	sub.w	lr, lr, #0x20
	b.n	.L08032464
.L08032448:
	sub.w	lr, lr, #0x30
	b.n	.L08032464
.L0803244e:
	sub.w	lr, lr, #0x1a
	b.n	.L08032464
.L08032454:
	add.w	lr, lr, #0x8
	b.n	.L08032464
.L0803245a:
	sub.w	lr, lr, #0x50
	b.n	.L08032464
.L08032460:
	sub.w	lr, lr, #0x1c60
.L08032464:
	uxth.w	r1, lr
	uxth.w	r2, r10
	cmp	r2, r1
	bne.w	.L08032daa
	add.w	r11, r11, #0x1
.L08032476:
	ldrb.w	lr, [r0, #0x12]
	ldrb	r1, [r0, #0x13]
	lsls.w	r2, r12, #0x10
	orr.w	r12, lr, r1, lsl #0x8
	beq.n	.L080324de
	cmp.w	r11, #0xff
	bhi.w	.L08032daa
	movw	r3, #:lower16:d_080be05c
	uxth.w	r9, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L080324ac:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r9
	bcs.n	.L08032542
	ldrh	r7, [r3, #0x2]
	uxth	r5, r2
	adds	r1, r3, #0x4
	uxtab	r3, r5, r7
	cmp	r3, r9
	lsr.w	r3, r7, #0x8
	bhi.n	.L080324f0
	movs	r2, #0x0
	uxtb	r5, r7
	cmp	r3, #0x0
	it	eq
	moveq	r2, r5
	mov	r3, r1
	ldrh.w	r2, [r1, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r5, lsl #0x1
	b.n	.L080324ac
.L080324de:
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L08032daa
	movs	r2, #0x1
	b.n	.L080325fe
.L080324f0:
	cmp	r3, #0x8
	bhi.n	.L08032542
	tbb	[pc, r3]
.L080324f8:
	.byte	(.L08032502 - .L080324f8)/2
	.byte	(.L0803250c - .L080324f8)/2
	.byte	(.L0803251a - .L080324f8)/2
	.byte	(.L08032520 - .L080324f8)/2
	.byte	(.L08032526 - .L080324f8)/2
	.byte	(.L0803252c - .L080324f8)/2
	.byte	(.L08032532 - .L080324f8)/2
	.byte	(.L08032538 - .L080324f8)/2
	.byte	(.L0803253e - .L080324f8)/2
	.byte	0x00	@ padding
.L08032502:
	sub.w	r2, r9, r5
	ldrh.w	r12, [r1, r2, lsl #0x1]
	b.n	.L08032542
.L0803250c:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	r12, r12, r1
	b.n	.L08032542
.L0803251a:
	sub.w	r12, r12, #0x10
	b.n	.L08032542
.L08032520:
	sub.w	r12, r12, #0x20
	b.n	.L08032542
.L08032526:
	sub.w	r12, r12, #0x30
	b.n	.L08032542
.L0803252c:
	sub.w	r12, r12, #0x1a
	b.n	.L08032542
.L08032532:
	add.w	r12, r12, #0x8
	b.n	.L08032542
.L08032538:
	sub.w	r12, r12, #0x50
	b.n	.L08032542
.L0803253e:
	sub.w	r12, r12, #0x1c60
.L08032542:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	lr, [r1, r11, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L08032562:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.n	.L080325e6
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L08032594
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L08032562
.L08032594:
	cmp	r3, #0x8
	bhi.n	.L080325e6
	tbb	[pc, r3]
.L0803259c:
	.byte	(.L080325a6 - .L0803259c)/2
	.byte	(.L080325b0 - .L0803259c)/2
	.byte	(.L080325be - .L0803259c)/2
	.byte	(.L080325c4 - .L0803259c)/2
	.byte	(.L080325ca - .L0803259c)/2
	.byte	(.L080325d0 - .L0803259c)/2
	.byte	(.L080325d6 - .L0803259c)/2
	.byte	(.L080325dc - .L0803259c)/2
	.byte	(.L080325e2 - .L0803259c)/2
	.byte	0x00	@ padding
.L080325a6:
	sub.w	r1, lr, r5
	ldrh.w	lr, [r7, r1, lsl #0x1]
	b.n	.L080325e6
.L080325b0:
	sub.w	r1, lr, r2
	and	r1, r1, #0x1
	sub.w	lr, lr, r1
	b.n	.L080325e6
.L080325be:
	sub.w	lr, lr, #0x10
	b.n	.L080325e6
.L080325c4:
	sub.w	lr, lr, #0x20
	b.n	.L080325e6
.L080325ca:
	sub.w	lr, lr, #0x30
	b.n	.L080325e6
.L080325d0:
	sub.w	lr, lr, #0x1a
	b.n	.L080325e6
.L080325d6:
	add.w	lr, lr, #0x8
	b.n	.L080325e6
.L080325dc:
	sub.w	lr, lr, #0x50
	b.n	.L080325e6
.L080325e2:
	sub.w	lr, lr, #0x1c60
.L080325e6:
	uxth.w	r1, lr
	uxth.w	r2, r12
	cmp	r2, r1
	bne.w	.L08032daa
	clz	r1, r9
	add.w	r11, r11, #0x1
	lsrs	r2, r1, #0x5
.L080325fe:
	ldrb.w	r9, [r0, #0x14]
	ldrb	r1, [r0, #0x15]
	orr.w	r12, r9, r1, lsl #0x8
	cbz	r2, .L0803261c
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L08032daa
	movs	r2, #0x1
	b.n	.L08032782
.L0803261c:
	cmp.w	r11, #0xff
	bhi.w	.L08032daa
	movw	r3, #:lower16:d_080be05c
	uxth.w	lr, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L08032642:				@ loop back from part 2 (next table range)
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.n	.L080326c6
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L08032674
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	.include "src/parts/find_directory_entry_by_name_p2.inc"
