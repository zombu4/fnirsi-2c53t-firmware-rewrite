@ filesystem_06.s - FAT directory: dir_add_entry (creates a directory entry with a long name).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ dir_add_entry - creates a directory entry (with long name) in the directory.
@ param_1 (r0) = pointer to the directory iterator structure (same layout as the one
@   used by 08031664). Returns 6 when byte (param_1+0x2b) & 0xa0 is nonzero.
@ Counts the length n of the UTF-16 name in the buffer at the pointer in the word at
@   ctx+0xc (stops at a 0x0000 halfword).
@ If bit0 of the flag byte (param_1+0x2b) is set, the short name needs a numeric tail:
@   the flag byte is set to 0x40 and up to 99 tries (counter from 1) build a tail with
@   '~' and hex digits (the value is the try counter; for counters above 5 it is first
@   run bitwise over each UTF-16 name character, low bit first, 16 steps per character,
@   shifting left and xoring 0x11021 when bit 15 is set, without truncation; up to 7
@   uppercase hex digits) into the 8 name characters at param_1+0x20, each tested with
@   08031664: result 4 (not found) restores the flag byte and continues at the creation
@   step, another nonzero result is returned, 99 failures return 7.
@ Creation step (flag bit0 clear): needs (n+12)/13+1 entry slots (1 when flag bit1
@   clear), calls 08033e94(param_1,0) (dir_set_offset) and scans entries for a run of
@   free slots (first byte 0xe5 or 0). At the end of the directory it extends it with
@   080312d4, zeroes the window with 0800857c(ctx+0x34,0x1000) and clears the new cluster
@   sectors via 0803616c (failure codes 1, 2, 7 from the table 0x20701); 08036f18 steps
@   clusters.
@ With the run found it returns to its first slot with 08033e94, computes the rotate-add
@   checksum over the 11-byte short name at param_1+0x20 and writes the long-name entries
@   from the highest sequence number down (halfword 0x000f at +0xb so attribute 0x0f and
@   +0xc=0, +0x1a=0, +0xd=checksum, 13 UTF-16 characters, the terminating 0 followed by
@   0xffff padding, bit 6 of the sequence byte on the entry that holds the end of the
@   name).
@ Last the short entry: 32 bytes zeroed, 11 name bytes copied from param_1+0x20,
@   byte entry+0xc = (byte at param_1+0x2b) & 0x18, byte ctx+3 = 1 as dirty flag.
@ Returns 0 on success or error codes 1, 2, 4, 6, 7.
@ ----------------------------------------------------------------------------
	.section .text.dir_add_entry,"ax",%progbits
	.global dir_add_entry
	.thumb_func
	.type dir_add_entry, %function
dir_add_entry:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x3c
	ldrb.w r7, [r0, #0x2b]
	tst.w r7, #0xa0
	beq.n .L08033268
	movs r0, #0x6
	add sp, #0x3c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08033268:
	ldr r1, [r0, #0x0]
	mov r9, r0
	mov r0, r1
	ldr r0, [r1, #0xc]
	str r1, [sp, #0x24]
	adds r1, r0, #0x6
	mov.w r8, #0x0
.L08033278:
	ldrh.w r2, [r1, #-0x6]
	cbz r2, .L080332a6
	add.w r2, r0, r8, lsl #0x1
	ldrh r3, [r2, #0x2]
	cbz r3, .L0803329c
	ldrh r2, [r2, #0x4]
	cbz r2, .L080332a2
	ldrh.w r2, [r1], #0x8
	add.w r8, r8, #0x4
	cmp r2, #0x0
	bne.n .L08033278
	sub.w r8, r8, #0x1
	b.n .L080332a6
.L0803329c:
	add.w r8, r8, #0x1
	b.n .L080332a6
.L080332a2:
	add.w r8, r8, #0x2
.L080332a6:
	mov r11, r9
	ldr.w r0, [r11, #0x20]!
	str r0, [sp, #0x28]
	ldr.w r0, [r11, #0x7]
	ldr.w r1, [r11, #0x4]
	str.w r0, [sp, #0x2f]
	str r1, [sp, #0x2c]
	ldr r1, [sp, #0x24]
	lsls r0, r7, #0x1f
	str r1, [sp, #0x1c]
	bne.n .L080332fa
.L080332c4:
	movw r1, #0xec4f
	add.w r0, r8, #0xc
	movt r1, #0x4ec4
	umull r0, r1, r0, r1
	movs r0, #0x1
	add.w r1, r0, r1, lsr #0x2
	lsls r0, r7, #0x1e
	it pl
	movpl r1, #0x1
	str r1, [sp, #0x20]
	mov r0, r9
	movs r1, #0x0
	bl dir_set_offset
	ldr r7, [sp, #0x1c]
	cmp r0, #0x0
	beq.w .L080336ca
.L080332f2:
	cmp r0, #0x4
	beq.w .L080339b4
	b.n .L080339d2
.L080332fa:
	str r7, [sp, #0x20]
	movw r7, #0x1021
	movt r7, #0x1
	movs r0, #0x40
	movs r5, #0x1
	add.w r10, sp, #0x34
	mov.w lr, #0x7e
	strb.w r0, [r9, #0x2b]
.L08033314:
	ldr.w r2, [sp, #0x2f]
	ldr r3, [sp, #0x2c]
	ldr r1, [r1, #0xc]
	ldr r0, [sp, #0x28]
	str.w r2, [r11, #0x7]
	str.w r3, [r11, #0x4]
	cmp r5, #0x6
	mov r3, r5
	str.w r0, [r11, #0x0]
	bcc.n .L08033424
	ldrh r0, [r1, #0x0]
	mov r3, r5
	cmp r0, #0x0
	beq.n .L08033424
	subs r1, #0x2
	mov r3, r5
.L0803333c:
	and r2, r0, #0x1
	orr.w r2, r2, r3, lsl #0x1
	lsls r3, r3, #0x10
	it mi
	eormi r2, r7
	ubfx r3, r0, #0x1, #0x1
	orr.w r3, r3, r2, lsl #0x1
	lsls r2, r2, #0x10
	it mi
	eormi r3, r7
	ubfx r2, r0, #0x2, #0x1
	orr.w r2, r2, r3, lsl #0x1
	lsls r3, r3, #0x10
	it mi
	eormi r2, r7
	ubfx r3, r0, #0x3, #0x1
	orr.w r3, r3, r2, lsl #0x1
	lsls r2, r2, #0x10
	it mi
	eormi r3, r7
	ubfx r2, r0, #0x4, #0x1
	orr.w r2, r2, r3, lsl #0x1
	lsls r3, r3, #0x10
	it mi
	eormi r2, r7
	ubfx r3, r0, #0x5, #0x1
	orr.w r3, r3, r2, lsl #0x1
	lsls r2, r2, #0x10
	it mi
	eormi r3, r7
	ubfx r2, r0, #0x6, #0x1
	orr.w r2, r2, r3, lsl #0x1
	lsls r3, r3, #0x10
	it mi
	eormi r2, r7
	ubfx r3, r0, #0x7, #0x1
	orr.w r3, r3, r2, lsl #0x1
	lsls r2, r2, #0x10
	it mi
	eormi r3, r7
	ubfx r2, r0, #0x8, #0x1
	orr.w r2, r2, r3, lsl #0x1
	lsls r3, r3, #0x10
	it mi
	eormi r2, r7
	ubfx r3, r0, #0x9, #0x1
	orr.w r3, r3, r2, lsl #0x1
	lsls r2, r2, #0x10
	it mi
	eormi r3, r7
	ubfx r2, r0, #0xa, #0x1
	orr.w r2, r2, r3, lsl #0x1
	lsls r3, r3, #0x10
	it mi
	eormi r2, r7
	ubfx r3, r0, #0xb, #0x1
	orr.w r3, r3, r2, lsl #0x1
	lsls r2, r2, #0x10
	it mi
	eormi r3, r7
	ubfx r2, r0, #0xc, #0x1
	orr.w r2, r2, r3, lsl #0x1
	lsls r3, r3, #0x10
	it mi
	eormi r2, r7
	ubfx r3, r0, #0xd, #0x1
	orr.w r3, r3, r2, lsl #0x1
	lsls r2, r2, #0x10
	it mi
	eormi r3, r7
	ubfx r2, r0, #0xe, #0x1
	orr.w r2, r2, r3, lsl #0x1
	lsls r3, r3, #0x10
	it mi
	eormi r2, r7
	lsls r3, r2, #0x1
	orr.w r3, r3, r0, lsr #0xf
	lsls r0, r2, #0x10
	ldrh r0, [r1, #0x4]
	it mi
	eormi r3, r7
	cmp r0, #0x0
	add.w r1, r1, #0x2
	bne.n .L0803333c
.L08033424:
	and r0, r3, #0xf
	add.w r1, r0, #0x30
	cmp r1, #0x39
	mov.w r2, #0x0
	it hi
	addhi.w r1, r0, #0x37
	cmp.w r2, r3, lsr #0x4
	strb.w r1, [sp, #0x3b]
	beq.n .L080334fc
	lsrs r0, r3, #0x4
	and r0, r0, #0xf
	add.w r1, r0, #0x30
	cmp r1, #0x39
	it hi
	addhi.w r1, r0, #0x37
	cmp.w r2, r3, lsr #0x8
	strb.w r1, [sp, #0x3a]
	beq.n .L08033504
	lsrs r0, r3, #0x8
	and r0, r0, #0xf
	add.w r1, r0, #0x30
	cmp r1, #0x39
	mov.w r2, #0x0
	it hi
	addhi.w r1, r0, #0x37
	cmp.w r2, r3, lsr #0xc
	strb.w r1, [sp, #0x39]
	beq.n .L08033510
	lsrs r0, r3, #0xc
	and r0, r0, #0xf
	add.w r1, r0, #0x30
	cmp r1, #0x39
	it hi
	addhi.w r1, r0, #0x37
	cmp.w r2, r3, lsr #0x10
	strb.w r1, [sp, #0x38]
	beq.w .L080335a4
	lsrs r0, r3, #0x10
	and r0, r0, #0xf
	add.w r1, r0, #0x30
	cmp r1, #0x39
	mov.w r4, #0x0
	it hi
	addhi.w r1, r0, #0x37
	cmp.w r4, r3, lsr #0x14
	strb.w r1, [sp, #0x37]
	beq.n .L080335aa
	lsrs r0, r3, #0x14
	and r0, r0, #0xf
	add.w r1, r0, #0x30
	cmp r1, #0x39
	it hi
	addhi.w r1, r0, #0x37
	movs r0, #0x0
	cmp.w r0, r3, lsr #0x18
	strb.w r1, [sp, #0x36]
	beq.n .L080335b0
	lsrs r0, r3, #0x18
	and r0, r0, #0xf
	add.w r1, r0, #0x30
	cmp r1, #0x39
	it hi
	addhi.w r1, r0, #0x37
	strb.w r1, [sp, #0x35]
	strb.w lr, [sp, #0x34]
	movs r1, #0x0
	movs r0, #0x0
	b.n .L080335c0
	.byte 0x00, 0xbf	@ padding (never reached, after the b above)
.L080334fc:
	movs r1, #0x6
	movs r4, #0x0
.L08033500:
	movs r3, #0x0
	b.n .L08033516
.L08033504:
	movs r1, #0x5
	mov.w r12, #0x1
	movs r4, #0x0
	movs r3, #0x0
	b.n .L0803351a
.L08033510:
	movs r1, #0x4
	movs r3, #0x1
	movs r4, #0x0
.L08033516:
	mov.w r12, #0x0
.L0803351a:
	ldrb.w r6, [r11, #0x0]
	subs.w r0, r6, #0x20
	it ne
	movne r0, r1
	cmp r6, #0x20
	strb.w lr, [r10, r1]
	beq.n .L080335c0
	ldrb.w r0, [r9, #0x21]
	subs r0, #0x20
	clz r0, r0
	lsr.w r0, r0, #0x5
	orr.w r2, r2, r0
	mov r0, r1
	it eq
	moveq r0, #0x1
	cbnz r2, .L080335c0
	ldrb.w r0, [r9, #0x22]
	subs r0, #0x20
	clz r0, r0
	lsr.w r0, r0, #0x5
	orr.w r2, r0, r4
	mov r0, r1
	it eq
	moveq r0, #0x2
	cbnz r2, .L080335c0
	ldrb.w r0, [r9, #0x23]
	subs r0, #0x20
	clz r0, r0
	lsr.w r0, r0, #0x5
	orr.w r2, r0, r3
	mov r0, r1
	it eq
	moveq r0, #0x3
	cbnz r2, .L080335c0
	ldrb.w r0, [r9, #0x24]
	subs r0, #0x20
	clz r0, r0
	lsr.w r0, r0, #0x5
	orr.w r2, r0, r12
	mov r0, r1
	it eq
	moveq r0, #0x4
	cbnz r2, .L080335c0
	ldrb.w r0, [r9, #0x25]
	cmp r0, #0x20
	mov r0, r1
	it eq
	moveq r0, #0x5
	b.n .L080335c0
.L080335a4:
	movs r1, #0x3
	movs r4, #0x1
	b.n .L08033500
.L080335aa:
	movs r1, #0x2
	movs r2, #0x1
	b.n .L08033500
.L080335b0:
	ldrb.w r0, [r11, #0x0]
	movs r1, #0x1
	subs r0, #0x20
	strb.w lr, [sp, #0x35]
	it ne
	movne r0, #0x1
.L080335c0:
	add.w r2, r1, r10
	ldrb r2, [r2, #0x1]
	adds r3, r0, #0x2
	add.w r6, r9, r0
	cmp r3, #0x8
	strb.w lr, [r6, #0x20]
	strb.w r2, [r6, #0x21]
	beq.n .L08033698
	cmp r1, #0x5
	bhi.n .L080335fc
	adds r2, r1, #0x2
	ldrb.w r6, [r10, r2]
	adds r2, r0, #0x3
	add r3, r9
	cmp r2, #0x8
	strb.w r6, [r3, #0x20]
	beq.n .L08033698
	cmp r1, #0x4
	bhi.n .L0803360e
	adds r3, r1, #0x3
	ldrb.w r4, [r10, r3]
	adds r3, r1, #0x4
	b.n .L08033612
.L080335fc:
	adds r2, r0, #0x3
	add.w r1, r9, r3
	movs r4, #0x20
	cmp r2, #0x8
	strb.w r4, [r1, #0x20]
	bne.n .L08033610
	b.n .L08033698
.L0803360e:
	movs r4, #0x20
.L08033610:
	movs r3, #0x8
.L08033612:
	adds r1, r0, #0x4
	add r2, r9
	cmp r1, #0x8
	strb.w r4, [r2, #0x20]
	beq.n .L08033698
	cmp r3, #0x7
	bhi.n .L08033640
	ldrb.w r6, [r10, r3]
	adds r2, r0, #0x5
	add r1, r9
	cmp r2, #0x8
	strb.w r6, [r1, #0x20]
	beq.n .L08033698
	cmp r3, #0x6
	bhi.n .L08033650
	adds r1, r3, #0x1
	ldrb.w r4, [r10, r1]
	adds r3, #0x2
	b.n .L08033654
.L08033640:
	adds r2, r0, #0x5
	add r1, r9
	movs r4, #0x20
	cmp r2, #0x8
	strb.w r4, [r1, #0x20]
	bne.n .L08033652
	b.n .L08033698
.L08033650:
	movs r4, #0x20
.L08033652:
	movs r3, #0x8
.L08033654:
	adds r1, r0, #0x6
	add r2, r9
	cmp r1, #0x8
	strb.w r4, [r2, #0x20]
	beq.n .L08033698
	cmp r3, #0x7
	bhi.n .L08033680
	ldrb.w r2, [r10, r3]
	adds r0, #0x7
	add r1, r9
	cmp r0, #0x8
	strb.w r2, [r1, #0x20]
	beq.n .L08033698
	ldrb.w r1, [sp, #0x3b]
	cmp r3, #0x7
	it cs
	movcs r1, #0x20
	b.n .L08033690
.L08033680:
	adds r0, #0x7
	add.w r2, r9, r1
	movs r1, #0x20
	cmp r0, #0x8
	strb.w r1, [r2, #0x20]
	beq.n .L08033698
.L08033690:
	add r0, r9
	strb.w r1, [r0, #0x20]
	nop
.L08033698:
	mov r0, r9
	bl find_directory_entry_by_name
	cbnz r0, .L080336b0
	adds r5, #0x1
	ldr r1, [sp, #0x24]
	cmp r5, #0x64
	mov.w lr, #0x7e
	bne.w .L08033314
	b.n .L080339b4
.L080336b0:
	cmp r5, #0x64
	beq.w .L080339b4
	cmp r0, #0x4
	bne.w .L080339d2
	ldr.w r0, [r9, #0x0]
	ldr r7, [sp, #0x20]
	str r0, [sp, #0x1c]
	strb.w r7, [r9, #0x2b]
	b.n .L080332c4
.L080336ca:
	add.w r0, r7, #0x34
	mov.w r8, #0x0
	str r0, [sp, #0x18]
	b.n .L080336f6
.L080336d6:
	ldrh r0, [r3, #0x8]
	cmp.w r0, r5, lsr #0x5
	bls.w .L080339ae
.L080336e0:
	add.w r0, r3, r10
	adds r0, #0x34
	str.w r5, [r9, #0x10]
	str.w r0, [r9, #0x1c]
	movs r0, #0x0
	cmp r0, #0x0
	bne.w .L080332f2
.L080336f6:
	ldr.w r6, [r9, #0x18]
	ldr r4, [r7, #0x30]
	cmp r4, r6
	beq.n .L080337ae
	ldrb r0, [r7, #0x3]
	cbz r0, .L0803377c
	ldrb r0, [r7, #0x1]
	cmp r0, #0x3
	beq.n .L0803371e
	cmp r0, #0x2
	bne.w .L080339de
	nop.w
	mov.w r0, #0x200000
	add.w r5, r0, r4, lsl #0xc
	b.n .L08033724
.L0803371e:
	nop.w
	lsls r5, r4, #0xc
.L08033724:
	nop.w
	ldr r0, [sp, #0x18]
	mov r1, r5
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r0, [r7, #0x24]
	ldr r1, [r7, #0x30]
	ldr r2, [r7, #0x1c]
	subs r0, r1, r0
	cmp r0, r2
	mov.w r0, #0x0
	strb r0, [r7, #0x3]
	bcs.n .L0803377c
	ldrb r0, [r7, #0x2]
	cmp r0, #0x2
	bne.n .L0803377c
	ldrb r0, [r7, #0x1]
	adds r4, r2, r1
	cmp r0, #0x3
	beq.n .L08033766
	cmp r0, #0x2
	bne.n .L0803377e
	nop.w
	mov.w r0, #0x200000
	add.w r5, r0, r4, lsl #0xc
	b.n .L0803376c
.L08033766:
	nop.w
	lsls r5, r4, #0xc
.L0803376c:
	nop.w
	ldr r0, [sp, #0x18]
	mov r1, r5
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L0803377c:
	ldrb r0, [r7, #0x1]
.L0803377e:
	cmp r0, #0x3
	beq.n .L08033796
	cmp r0, #0x2
	bne.w .L080339d8
	nop.w
	mov.w r0, #0x200000
	add.w r5, r0, r6, lsl #0xc
	b.n .L0803379c
.L08033796:
	nop.w
	lsls r5, r6, #0xc
.L0803379c:
	nop.w
	ldr r0, [sp, #0x18]
	mov r1, r5
	mov.w r2, #0x1000
	bl serial_device_read
	str r6, [r7, #0x30]
.L080337ae:
	ldr.w r1, [r9, #0x1c]
	ldrb r0, [r1, #0x0]
	cmp r0, #0xe5
	beq.n .L080337ba
	cbnz r0, .L080337c6
.L080337ba:
	ldr r0, [sp, #0x20]
	add.w r8, r8, #0x1
	cmp r8, r0
	bne.n .L080337ca
	b.n .L080339bc
.L080337c6:
	mov.w r8, #0x0
.L080337ca:
	ldr.w r0, [r9, #0x10]
	add.w r5, r0, #0x20
	movw r0, #0xffff
	movt r0, #0xf
	add.w r0, r0, #0x100000
	cmp r5, r0
	bhi.w .L080339ae
	ldr.w r0, [r9, #0x18]
	cmp r0, #0x0
	beq.w .L080339b4
	mov r10, r5
	ldr.w r3, [r9, #0x0]
	bfc r10, #0xc, #0x14
	cmp.w r10, #0x0
	bne.w .L080336e0
	ldr.w r1, [r9, #0x14]
	adds r0, #0x1
	cmp r1, #0x0
	str.w r0, [r9, #0x18]
	beq.w .L080336d6
	ldrh r0, [r3, #0xa]
	movw r2, #0xffff
	movt r2, #0xf
	add r0, r2
	tst.w r0, r5, lsr #0xc
	bne.w .L080336e0
	mov r0, r3
	str r3, [sp, #0x14]
	bl allocation_table_read
	cmp r0, #0x2
	bcc.w .L08033d78
	adds r1, r0, #0x1
	beq.w .L080339de
	ldr r3, [sp, #0x14]
	ldr r1, [r3, #0x18]
	cmp r0, r1
	bcs.n .L08033844
	subs r2, r0, #0x2
	b.n .L08033992
.L08033844:
	ldr.w r1, [r9, #0x14]
	mov r0, r9
	bl next_or_allocate_cluster
	mov r6, r0
	adds r0, #0x1
	cmp r0, #0x3
	bcs.n .L08033878
	movw r1, #0xfff8
	movt r1, #0xff
	and.w r0, r1, r0, lsl #0x3
	movw r1, #0x701
	movt r1, #0x2
	lsr.w r0, r1, r0
	uxtb r0, r0
	cmp r0, #0x0
	beq.w .L080336f6
	b.n .L080332f2
.L08033878:
	ldr r3, [sp, #0x14]
	ldrb r0, [r3, #0x3]
	cmp r0, #0x0
	beq.n .L08033908
	ldrb r0, [r3, #0x1]
	ldr r4, [r3, #0x30]
	cmp r0, #0x3
	beq.n .L0803389c
	cmp r0, #0x2
	bne.w .L080339de
	nop.w
	mov.w r0, #0x200000
	add.w r0, r0, r4, lsl #0xc
	b.n .L080338a2
.L0803389c:
	nop.w
	lsls r0, r4, #0xc
.L080338a2:
	ldr r4, [sp, #0x14]
	str r0, [sp, #0x10]
	add.w r7, r4, #0x34
	nop.w
	ldr r1, [sp, #0x10]
	mov r0, r7
	mov.w r2, #0x1000
	str r7, [sp, #0xc]
	bl serial_device_write_merge
	ldr r2, [r4, #0x24]
	ldr r0, [r4, #0x30]
	ldr r1, [r4, #0x1c]
	subs r2, r0, r2
	mov r3, r4
	cmp r2, r1
	mov.w r2, #0x0
	strb r2, [r4, #0x3]
	bcs.n .L08033908
	ldrb r2, [r3, #0x2]
	cmp r2, #0x2
	bne.n .L08033908
	ldrb r2, [r3, #0x1]
	adds r4, r1, r0
	cmp r2, #0x3
	beq.n .L080338f0
	cmp r2, #0x2
	bne.n .L08033908
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r4, lsl #0xc
	b.n .L080338f6
.L080338f0:
	nop.w
	lsls r7, r4, #0xc
.L080338f6:
	nop.w
	ldr r0, [sp, #0xc]
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [sp, #0x14]
.L08033908:
	ldr r0, [r3, #0x18]
	subs r1, r6, #0x2
	subs r0, #0x2
	cmp r1, r0
	str r6, [sp, #0x8]
	bcs.n .L0803391e
	ldr r0, [r3, #0x2c]
	ldrh r6, [r3, #0xa]
	mla r4, r1, r6, r0
	b.n .L08033922
.L0803391e:
	ldrh r6, [r3, #0xa]
	movs r4, #0x0
.L08033922:
	str r1, [sp, #0x4]
	add.w r0, r3, #0x34
	mov.w r1, #0x1000
	str r4, [r3, #0x30]
	str r0, [sp, #0x10]
	bl zero_bytes_aligned
	cbz r6, .L08033980
	mov.w r0, #0x200000
	ldr r3, [sp, #0x14]
	str r4, [sp, #0xc]
	add.w r7, r0, r4, lsl #0xc
	movs r4, #0x0
	b.n .L0803396e
.L08033946:
	ldr r0, [sp, #0xc]
	adds r6, r4, r0
	nop.w
	lsls r6, r6, #0xc
.L08033950:
	nop.w
	ldr r0, [sp, #0x10]
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [sp, #0x14]
	adds r4, #0x1
	ldrh r6, [r3, #0xa]
	add.w r7, r7, #0x1000
	cmp r4, r6
	bcs.n .L08033986
.L0803396e:
	ldrb r0, [r3, #0x1]
	cmp r0, #0x3
	beq.n .L08033946
	cmp r0, #0x2
	bne.n .L08033986
	nop.w
	mov r6, r7
	b.n .L08033950
.L08033980:
	ldr r3, [sp, #0x14]
	movs r6, #0x0
	movs r4, #0x0
.L08033986:
	cmp r4, r6
	bne.n .L080339de
	ldr r1, [r3, #0x18]
	ldr r7, [sp, #0x1c]
	ldrd r2, r0, [sp, #0x4]
.L08033992:
	subs r1, #0x2
	cmp r2, r1
	str.w r0, [r9, #0x14]
	bcs.n .L080339a6
	ldr r0, [r3, #0x2c]
	ldrh r1, [r3, #0xa]
	mla r0, r2, r1, r0
	b.n .L080339a8
.L080339a6:
	movs r0, #0x0
.L080339a8:
	str.w r0, [r9, #0x18]
	b.n .L080336e0
.L080339ae:
	movs r0, #0x0
	str.w r0, [r9, #0x18]
.L080339b4:
	movs r0, #0x7
	add sp, #0x3c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080339bc:
	ldr r0, [sp, #0x20]
	subs r7, r0, #0x1
	beq.n .L080339e6
	ldr.w r0, [r9, #0x10]
	sub.w r1, r0, r7, lsl #0x5
	mov r0, r9
	bl dir_set_offset
	cbz r0, .L08033a16
.L080339d2:
	add sp, #0x3c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080339d8:
	mov.w r0, #0xffffffff
	str r0, [r7, #0x30]
.L080339de:
	movs r0, #0x1
	add sp, #0x3c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080339e6:
	ldr.w r10, [r9, #0x18]
.L080339ea:
	ldr r5, [sp, #0x24]
	ldr r4, [r5, #0x30]
	cmp r4, r10
	beq.w .L08033e4a
	ldrb r0, [r5, #0x3]
	cmp r0, #0x0
	beq.w .L08033e0c
	ldrb r0, [r5, #0x1]
	cmp r0, #0x3
	beq.w .L08033d8e
	cmp r0, #0x2
	bne.n .L080339de
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r4, lsl #0xc
	b.n .L08033d94
.L08033a16:
	ldrb.w r0, [r9, #0x20]
	ldrb.w r2, [r9, #0x21]
	lsrs r1, r0, #0x1
	orr.w r0, r1, r0, lsl #0x7
	add r0, r2
	ldrb.w r1, [r9, #0x22]
	uxtb r0, r0
	add.w r1, r1, r0, lsl #0x7
	add.w r0, r1, r0, lsr #0x1
	ldrb.w r1, [r9, #0x23]
	uxtb r0, r0
	add.w r1, r1, r0, lsl #0x7
	add.w r0, r1, r0, lsr #0x1
	ldrb.w r1, [r9, #0x24]
	uxtb r0, r0
	add.w r1, r1, r0, lsl #0x7
	add.w r0, r1, r0, lsr #0x1
	ldrb.w r1, [r9, #0x25]
	uxtb r0, r0
	add.w r1, r1, r0, lsl #0x7
	add.w r0, r1, r0, lsr #0x1
	ldrb.w r1, [r9, #0x26]
	uxtb r0, r0
	add.w r1, r1, r0, lsl #0x7
	add.w r0, r1, r0, lsr #0x1
	ldrb.w r1, [r9, #0x27]
	uxtb r0, r0
	add.w r1, r1, r0, lsl #0x7
	add.w r0, r1, r0, lsr #0x1
	ldrb.w r1, [r9, #0x28]
	uxtb r0, r0
	add.w r1, r1, r0, lsl #0x7
	add.w r0, r1, r0, lsr #0x1
	ldrb.w r1, [r9, #0x29]
	uxtb r0, r0
	add.w r1, r1, r0, lsl #0x7
	add.w r0, r1, r0, lsr #0x1
	uxtb r0, r0
	lsrs r1, r0, #0x1
	ldrb.w r2, [r9, #0x2a]
	orr.w r0, r1, r0, lsl #0x7
	adds r5, r2, r0
	ldr r0, [sp, #0x24]
	ldr.w r10, [r9, #0x18]
	adds r0, #0x34
	str r0, [sp, #0x20]
	b.n .L08033ace
.L08033ab0:
	ldrh r0, [r6, #0x8]
	cmp.w r0, r4, lsr #0x5
	bls.w .L08033d80
.L08033aba:
	add.w r0, r6, r8
	add.w r1, r0, #0x34
	subs r7, #0x1
	str.w r4, [r9, #0x10]
	str.w r1, [r9, #0x1c]
	beq.n .L080339ea
.L08033ace:
	ldr r6, [sp, #0x24]
	ldr r4, [r6, #0x30]
	cmp r4, r10
	beq.n .L08033ba2
	ldrb r0, [r6, #0x3]
	cmp r0, #0x0
	beq.n .L08033b6a
	ldrb r0, [r6, #0x1]
	cmp r0, #0x3
	beq.n .L08033af6
	cmp r0, #0x2
	bne.w .L080339de
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r4, lsl #0xc
	b.n .L08033afc
.L08033af6:
	nop.w
	lsls r6, r4, #0xc
.L08033afc:
	nop.w
	ldr r0, [sp, #0x20]
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r6, [sp, #0x24]
	ldr r0, [r6, #0x24]
	ldr r1, [r6, #0x30]
	ldr r2, [r6, #0x1c]
	subs r0, r1, r0
	cmp r0, r2
	mov.w r0, #0x0
	strb r0, [r6, #0x3]
	bcs.n .L08033b6a
	ldrb r0, [r6, #0x2]
	cmp r0, #0x2
	bne.n .L08033b6a
	ldrb r0, [r6, #0x1]
	adds r4, r2, r1
	cmp r0, #0x3
	beq.n .L08033b52
	ldr r6, [sp, #0x24]
	cmp r0, #0x2
	bne.n .L08033b6c
	nop.w
	mov.w r0, #0x200000
	add.w r4, r0, r4, lsl #0xc
	nop.w
	ldr r0, [sp, #0x20]
	mov r1, r4
	mov.w r2, #0x1000
	bl serial_device_write_merge
	b.n .L08033b6a
.L08033b52:
	nop.w
	lsls r6, r4, #0xc
	nop.w
	ldr r0, [sp, #0x20]
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r6, [sp, #0x24]
.L08033b6a:
	ldrb r0, [r6, #0x1]
.L08033b6c:
	cmp r0, #0x3
	beq.n .L08033b84
	cmp r0, #0x2
	bne.w .L08033dec
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r10, lsl #0xc
	b.n .L08033b8c
.L08033b84:
	nop.w
	lsl.w r6, r10, #0xc
.L08033b8c:
	nop.w
	ldr r0, [sp, #0x20]
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_read
	ldr r6, [sp, #0x24]
	str.w r10, [r6, #0x30]
.L08033ba2:
	ldr.w r0, [r9, #0x1c]
	movs r2, #0xf
	ldr r1, [r6, #0xc]
	strh.w r2, [r0, #0xb]
	movs r2, #0x0
	strh r2, [r0, #0x1a]
	uxtb r2, r7
	movs r3, #0xd
	muls r3, r2, r3
	strb r5, [r0, #0xd]
	add.w r2, r1, r3, lsl #0x1
	ldrh.w r6, [r2, #-0x1a]
	adds r2, r6, #0x1
	uxth r2, r2
	cmp r2, #0x2
	sub.w r2, r3, #0xc
	strh.w r6, [r0, #0x1]
	itte cs
	ldrhcs.w r6, [r1, r2, lsl #0x1]
	subcs.w r2, r3, #0xb
	movwcc r6, #0xffff
	adds r3, r6, #0x1
	uxth r3, r3
	strh.w r6, [r0, #0x3]
	cmp r3, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh.w r3, [r0, #0x5]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh.w r3, [r0, #0x7]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh.w r3, [r0, #0x9]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh r3, [r0, #0xe]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh r3, [r0, #0x10]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh r3, [r0, #0x12]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh r3, [r0, #0x14]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh r3, [r0, #0x16]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh r3, [r0, #0x18]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	strh r3, [r0, #0x1c]
	cmp r6, #0x2
	itte cs
	ldrhcs.w r3, [r1, r2, lsl #0x1]
	addcs r2, #0x1
	movwcc r3, #0xffff
	adds r6, r3, #0x1
	uxth r6, r6
	cmp r6, #0x2
	strh r3, [r0, #0x1e]
	bcs.n .L08033cd2
	orr.w r1, r7, #0x40
	b.n .L08033ce0
.L08033cd2:
	ldrh.w r1, [r1, r2, lsl #0x1]
	cmp r1, #0x0
	mov r1, r7
	it eq
	orreq.w r1, r7, #0x40
.L08033ce0:
	strb r1, [r0, #0x0]
	ldr r0, [sp, #0x24]
	movs r1, #0x1
	strb r1, [r0, #0x3]
	ldr.w r0, [r9, #0x10]
	add.w r4, r0, #0x20
	movw r0, #0xffff
	movt r0, #0xf
	add.w r0, r0, #0x100000
	cmp r4, r0
	bhi.n .L08033d80
	ldr.w r10, [r9, #0x18]
	cmp.w r10, #0x0
	beq.n .L08033d86
	mov r8, r4
	ldr.w r6, [r9, #0x0]
	bfc r8, #0xc, #0x14
	cmp.w r8, #0x0
	bne.w .L08033aba
	ldr.w r1, [r9, #0x14]
	add.w r10, r10, #0x1
	cmp r1, #0x0
	str.w r10, [r9, #0x18]
	beq.w .L08033ab0
	ldrh r0, [r6, #0xa]
	movw r2, #0xffff
	movt r2, #0xf
	add r0, r2
	tst.w r0, r4, lsr #0xc
	bne.w .L08033aba
	mov r0, r6
	bl allocation_table_read
	cmp r0, #0x2
	bcc.n .L08033d78
	adds r1, r0, #0x1
	beq.w .L080339de
	ldr r1, [r6, #0x18]
	cmp r0, r1
	bcs.n .L08033d80
	subs r2, r0, #0x2
	subs r1, #0x2
	cmp r2, r1
	str.w r0, [r9, #0x14]
	bcs.n .L08033d6e
	ldr r0, [r6, #0x2c]
	ldrh r1, [r6, #0xa]
	mla r10, r2, r1, r0
	b.n .L08033d72
.L08033d6e:
	mov.w r10, #0x0
.L08033d72:
	str.w r10, [r9, #0x18]
	b.n .L08033aba
.L08033d78:
	movs r0, #0x2
	add sp, #0x3c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08033d80:
	movs r0, #0x0
	str.w r0, [r9, #0x18]
.L08033d86:
	movs r0, #0x4
	add sp, #0x3c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08033d8e:
	nop.w
	lsls r6, r4, #0xc
.L08033d94:
	ldr r5, [sp, #0x24]
	add.w r7, r5, #0x34
	nop.w
	mov r0, r7
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [r5, #0x24]
	ldr r0, [r5, #0x30]
	ldr r1, [r5, #0x1c]
	subs r3, r0, r3
	movs r2, #0x0
	cmp r3, r1
	strb r2, [r5, #0x3]
	bcs.n .L08033e0c
	ldrb r2, [r5, #0x2]
	cmp r2, #0x2
	bne.n .L08033e0c
	ldrb r2, [r5, #0x1]
	adds r4, r1, r0
	cmp r2, #0x3
	beq.n .L08033df4
	ldr r5, [sp, #0x24]
	cmp r2, #0x2
	bne.n .L08033e0c
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r4, lsl #0xc
	nop.w
	mov r0, r7
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	b.n .L08033e0c
.L08033dec:
	mov.w r0, #0xffffffff
	str r0, [r6, #0x30]
	b.n .L080339de
.L08033df4:
	nop.w
	lsls r6, r4, #0xc
	nop.w
	mov r0, r7
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r5, [sp, #0x24]
.L08033e0c:
	ldrb r0, [r5, #0x1]
	cmp r0, #0x3
	beq.n .L08033e24
	cmp r0, #0x2
	bne.n .L08033e8c
	nop.w
	mov.w r0, #0x200000
	add.w r4, r0, r10, lsl #0xc
	b.n .L08033e2c
.L08033e24:
	nop.w
	lsl.w r4, r10, #0xc
.L08033e2c:
	ldr r5, [sp, #0x24]
	add.w r6, r5, #0x34
	nop.w
	mov r0, r6
	mov r1, r4
	mov.w r2, #0x1000
	bl serial_device_read
	str.w r10, [r5, #0x30]
	ldr.w r1, [r9, #0x1c]
.L08033e4a:
	movs r0, #0x0
	str r0, [r1, #0x1c]
	str r0, [r1, #0x18]
	str r0, [r1, #0x14]
	str r0, [r1, #0x10]
	str r0, [r1, #0xc]
	str r0, [r1, #0x8]
	str r0, [r1, #0x4]
	str r0, [r1, #0x0]
	ldr.w r1, [r9, #0x1c]
	ldr.w r2, [r11, #0x0]
	ldr.w r3, [r11, #0x7]
	ldr.w r7, [r11, #0x4]
	str.w r3, [r1, #0x7]
	str r7, [r1, #0x4]
	str r2, [r1, #0x0]
	ldrb.w r1, [r9, #0x2b]
	ldr.w r2, [r9, #0x1c]
	and r1, r1, #0x18
	strb r1, [r2, #0xc]
	movs r1, #0x1
	strb r1, [r5, #0x3]
	add sp, #0x3c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08033e8c:
	mov.w r0, #0xffffffff
	str r0, [r5, #0x30]
	b.n .L080339de

@ ----------------------------------------------------------------------------
@ dir_set_offset - positions a directory iterator at a 32-byte entry offset.
@ r0 = directory iterator, r1 = byte offset. Returns 2 if (r1 & 0xffe0001f) != 0;
@   stores r1 at obj[4].
@ With obj[2]==0 and (byte *base<3 or word base+0x28==0) the fixed root area is used:
@   it returns 2 when r1>>5 >= ushort(base+8) and takes the start sector from word
@   base+0x28.
@ Otherwise it follows 08036f18 (allocation_table_read) once per ushort(base+10)*0x1000
@   bytes skipped from the start cluster obj[2] (or word base+0x28 for type 3 with
@   obj[2]==0); 0xffffffff gives return 1, a value <2 or >= word base+0x18 gives
@   return 2. A start cluster with (cluster-2) >= (word base+0x18)-2 unsigned stores
@   obj[5]=cluster, obj[6]=0 and returns 2; otherwise sector =
@   (cluster-2)*ushort(base+10)+word base+0x2c.
@ Writes obj[5] (cluster), obj[6] (sector + (remaining offset>>12), remaining offset =
@   r1 minus the whole clusters skipped) and obj[7]=base+(r1&0xfff)+0x34; returns 2
@   when the sector is 0. Returns 0 on success.
@ ----------------------------------------------------------------------------
	.section .text.dir_set_offset,"ax",%progbits
	.global dir_set_offset
	.thumb_func
	.type dir_set_offset, %function
dir_set_offset:
	push {r4, r5, r6, r7, lr}
	sub sp, #0x4
	mov r5, r1
	movs r1, #0x1f
	movt r1, #0xffe0
	tst r5, r1
	beq.n .L08033eaa
.L08033ea4:
	movs r0, #0x2
	add sp, #0x4
	pop {r4, r5, r6, r7, pc}
.L08033eaa:
	ldr r1, [r0, #0x8]
	ldr r6, [r0, #0x0]
	mov r4, r0
	str r5, [r0, #0x10]
	cbz r1, .L08033ed0
.L08033eb4:
	ldrh r0, [r6, #0xa]
	cmp.w r5, r0, lsl #0xc
	bcs.n .L08033f06
	ldr r0, [r6, #0x18]
.L08033ebe:
	subs r2, r1, #0x2
	subs r0, #0x2
	cmp r2, r0
	bcs.n .L08033f2a
	ldr r0, [r6, #0x2c]
	ldrh r3, [r6, #0xa]
	mla r0, r2, r3, r0
	b.n .L08033ee8
.L08033ed0:
	ldrb r0, [r6, #0x0]
	cmp r0, #0x3
	bcc.n .L08033edc
	ldr r1, [r6, #0x28]
	cmp r1, #0x0
	bne.n .L08033eb4
.L08033edc:
	ldrh r0, [r6, #0x8]
	cmp.w r0, r5, lsr #0x5
	bls.n .L08033ea4
	ldr r0, [r6, #0x28]
	movs r1, #0x0
.L08033ee8:
	cmp r0, #0x0
	str r1, [r4, #0x14]
	str r0, [r4, #0x18]
	beq.n .L08033ea4
	add.w r0, r0, r5, lsr #0xc
	bfc r5, #0xc, #0x14
	adds r1, r6, r5
	adds r1, #0x34
	strd r0, r1, [r4, #0x18]
	movs r0, #0x0
	add sp, #0x4
	pop {r4, r5, r6, r7, pc}
.L08033f06:
	lsls r7, r0, #0xc
	subs r5, r5, r7
	mov r0, r6
.L08033f0c:
	bl allocation_table_read
	mov r1, r0
	adds r0, #0x1
	beq.n .L08033f32
	cmp r1, #0x2
	bcc.n .L08033ea4
	ldr r0, [r6, #0x18]
	cmp r1, r0
	bcs.n .L08033ea4
	cmp r5, r7
	bcc.n .L08033ebe
	ldr r0, [r4, #0x0]
	subs r5, r5, r7
	b.n .L08033f0c
.L08033f2a:
	movs r0, #0x0
	strd r1, r0, [r4, #0x14]
	b.n .L08033ea4
.L08033f32:
	movs r0, #0x1
	add sp, #0x4
	pop {r4, r5, r6, r7, pc}

@ ----------------------------------------------------------------------------
@ file_close - flushes and closes a file object (writes buffered data, updates its
@ directory entry, releases it).
@ Takes a pointer p (r0); returns at once if p or word *p is 0, if byte [*p] is 0, if
@   halfword p+4 differs from halfword *p+6, or if byte *p+1 is not 1..3.
@ If bit 6 of byte p+0x10 is clear only the last step runs. If bits 6 and 7 are set it
@   calls 0x0803616c(p+0x2c, a, 0x1000) with a = p[7]<<12 when byte *p+1 is 3 or
@   p[7]*0x1000+0x200000 when it is 2, then clears bit 7.
@ If word *p+0x30 differs from p[8]: when byte *p+3 is set it calls
@   0x0803616c(*p+0x34, a(word *p+0x30), 0x1000), clears *p+3 and, when byte *p+2 is 2
@   and (word *p+0x30 - word *p+0x24) < word *p+0x1c, calls 0x0803616c again at
@   a(word *p+0x1c + word *p+0x30). Then it calls 0x08036048(*p+0x34, a(p[8]), 0x1000)
@   and stores p[8] into word *p+0x30; when byte *p+1 is neither 2 nor 3 it stores
@   0xffffffff there and returns.
@ Then it updates the record at p[9]: byte +0xb |= 0x20, halfword +0x1a = low half of
@   p[2], bytes +0x14/+0x15 = high half of p[2] when byte [*p] is 3, word +0x1c = p[3],
@   word +0x16 = 0x50210000, halfword +0x12 = 0; sets byte *p+3 = 1, calls 0x0803d934
@   (fat_sync_volume)(*p), clears bit 6 of byte p+0x10 and returns if that call returned
@   nonzero.
@ Last step: if the checks on *p pass again it stores 0 into word p[0].
@ ----------------------------------------------------------------------------
	.section .text.file_close,"ax",%progbits
	.global file_close
	.thumb_func
	.type file_close, %function
file_close:
	push.w {r4, r5, r6, r7, r8, lr}
	cmp r0, #0x0
	beq.w .L080341aa
	ldr r5, [r0, #0x0]
	mov r4, r0
	cmp r5, #0x0
	beq.w .L080341aa
	ldrb r0, [r5, #0x0]
	cmp r0, #0x0
	beq.w .L080341aa
	ldrh r0, [r4, #0x4]
	ldrh r1, [r5, #0x6]
	cmp r0, r1
	bne.w .L080341aa
	ldrb r0, [r5, #0x1]
	subs r1, r0, #0x1
	cmp r1, #0x2
	bhi.w .L080341aa
	ldrb r1, [r4, #0x10]
	lsls r2, r1, #0x19
	bmi.n .L0803406c
.L0803404a:
	ldrb r0, [r5, #0x0]
	cmp r0, #0x0
	it eq
	popeq.w {r4, r5, r6, r7, r8, pc}
	ldrh r0, [r4, #0x4]
	ldrh r1, [r5, #0x6]
	cmp r0, r1
	bne.w .L080341aa
	ldrb r0, [r5, #0x1]
	subs r0, #0x1
	cmp r0, #0x2
	itt ls
	movls r0, #0x0
	strls r0, [r4, #0x0]
	b.n .L080341aa
.L0803406c:
	lsls r1, r1, #0x18
	bpl.n .L080340ac
	ldr r6, [r4, #0x1c]
	cmp r0, #0x3
	beq.n .L0803408a
	cmp r0, #0x2
	bne.w .L080341aa
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r6, lsl #0xc
	b.n .L08034090
.L0803408a:
	nop.w
	lsls r6, r6, #0xc
.L08034090:
	add.w r7, r4, #0x2c
	nop.w
	mov r0, r7
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldrb r0, [r4, #0x10]
	and.w r0, r0, #0x7f
	strb r0, [r4, #0x10]
.L080340ac:
	ldr r6, [r4, #0x20]
	ldr r7, [r5, #0x30]
	cmp r7, r6
	beq.n .L08034166
	ldrb r0, [r5, #0x3]
	cbz r0, .L08034130
	ldrb r0, [r5, #0x1]
	cmp r0, #0x3
	beq.n .L080340d0
	cmp r0, #0x2
	bne.n .L080341aa
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L080340d6
.L080340d0:
	nop.w
	lsls r7, r7, #0xc
.L080340d6:
	add.w r8, r5, #0x34
	nop.w
	mov r0, r8
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [r5, #0x24]
	ldr r1, [r5, #0x30]
	ldr r2, [r5, #0x1c]
	subs r3, r1, r3
	movs r0, #0x0
	cmp r3, r2
	strb r0, [r5, #0x3]
	bcs.n .L08034130
	ldrb r0, [r5, #0x2]
	cmp r0, #0x2
	bne.n .L08034130
	ldrb r0, [r5, #0x1]
	adds r7, r2, r1
	cmp r0, #0x3
	beq.n .L0803411a
	cmp r0, #0x2
	bne.n .L08034132
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L08034120
.L0803411a:
	nop.w
	lsls r7, r7, #0xc
.L08034120:
	nop.w
	mov r0, r8
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L08034130:
	ldrb r0, [r5, #0x1]
.L08034132:
	cmp r0, #0x3
	beq.n .L08034148
	cmp r0, #0x2
	bne.n .L080341b8
	nop.w
	mov.w r0, #0x200000
	add.w r8, r0, r6, lsl #0xc
	b.n .L08034150
.L08034148:
	nop.w
	lsl.w r8, r6, #0xc
.L08034150:
	add.w r7, r5, #0x34
	nop.w
	mov r0, r7
	mov r1, r8
	mov.w r2, #0x1000
	bl serial_device_read
	str r6, [r5, #0x30]
.L08034166:
	ldr r0, [r4, #0x24]
	ldrb r1, [r0, #0xb]
	orr.w r1, r1, #0x20
	strb r1, [r0, #0xb]
	ldr r1, [r4, #0x8]
	ldr r2, [r4, #0x0]
	strh r1, [r0, #0x1a]
	ldrb r2, [r2, #0x0]
	cmp r2, #0x3
	bne.n .L08034184
	lsrs r2, r1, #0x10
	lsrs r1, r1, #0x18
	strb r2, [r0, #0x14]
	strb r1, [r0, #0x15]
.L08034184:
	ldr r1, [r4, #0xc]
	str r1, [r0, #0x1c]
	movs r1, #0x0
	movt r1, #0x5021
	str.w r1, [r0, #0x16]
	movs r1, #0x0
	strh r1, [r0, #0x12]
	movs r0, #0x1
	strb r0, [r5, #0x3]
	mov r0, r5
	bl fat_sync_volume
	ldrb r1, [r4, #0x10]
	and.w r1, r1, #0xbf
	strb r1, [r4, #0x10]
	cbz r0, .L080341ae
.L080341aa:
	pop.w {r4, r5, r6, r7, r8, pc}
.L080341ae:
	ldr r5, [r4, #0x0]
	cmp r5, #0x0
	bne.w .L0803404a
	b.n .L080341aa
.L080341b8:
	mov.w r0, #0xffffffff
	str r0, [r5, #0x30]
	pop.w {r4, r5, r6, r7, r8, pc}
	.short 0x0000	@ padding (never reached, after the pop above)

@ ----------------------------------------------------------------------------
@ object_release - releases a file or directory object without writing anything.
@ Sets *r0 to 0 when r0 is non-null, *r0 is non-null, its byte 0 is nonzero, ushort at
@   r0+4 equals ushort at base+6 and base[1]-1 < 3; otherwise does nothing.
@ ----------------------------------------------------------------------------
	.section .text.object_release,"ax",%progbits
	.global object_release
	.thumb_func
	.type object_release, %function
object_release:
	cbz r0, .L080341e6
	ldr r1, [r0, #0x0]
	cbz r1, .L080341e6
	ldrb r2, [r1, #0x0]
	cmp r2, #0x0
	it eq
	bxeq lr
	ldrh r2, [r0, #0x4]
	ldrh r3, [r1, #0x6]
	cmp r2, r3
	bne.n .L080341e6
	ldrb r1, [r1, #0x1]
	subs r1, #0x1
	cmp r1, #0x2
	itt ls
	movls r1, #0x0
	strls r1, [r0, #0x0]
.L080341e6:
	bx lr
