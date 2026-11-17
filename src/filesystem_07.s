@ filesystem_07.s - FAT file layer: file_seek, dir_create, drive_unmount, drive_mount, file_open, dir_open, file_read, dir_read_entry.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ file_seek - sets the position of file object r0 to r1 (seek).
@ Returns 9 for an invalid object (null, base (obj[0]) null, base byte 0, mismatching
@   ushort obj+4 versus base+6, base[1]-1 > 2); returns obj byte 0x11 when it is nonzero.
@ When obj[10] (word at +0x28) == 0: r1 is clamped to the size obj[3] unless the write
@   flag (bit 1 of obj byte 0x10) is set, in which case clusters are added with
@   next_or_allocate_cluster (080312d4) up to r1; clusters are followed with
@   allocation_table_read (08036f18); a value < 2 or >= base[0x18] gives 2, 0xffffffff
@   gives 1. Sets obj[5] (position), obj[6] (cluster), raises obj[3] and sets flag bit
@   0x40 of obj byte 0x10 when the position passes the size. When the position is not
@   on a 0x1000 boundary the window at obj+0x2c is flushed (dirty bit 0x80) with
@   serial_device_write_merge (0803616c) and the new sector loaded with
@   serial_device_read (08036048).
@ When obj[10] != 0 and r1 == 0xffffffff it fills the table at obj[10] (word 0 =
@   capacity in words) with (count, start cluster) pairs by following 08036f18, stores
@   the needed size in word 0, writes a 0 terminator and returns 0x11 when the
@   capacity is too small.
@ When obj[10] != 0 and r1 != 0xffffffff it looks the cluster up in that table.
@ Returns 0 on success, 1 on read/write failure, 2 on bad chain, 0x11 when the table is
@   too small; failures 1 and 2 are stored in obj byte 0x11.
@ ----------------------------------------------------------------------------
	.section .text.file_seek,"ax",%progbits
	.global file_seek
	.thumb_func
	.type file_seek, %function
file_seek:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x4
	cbz r0, .L08034216
	ldr r7, [r0, #0x0]
	mov r4, r0
	cbz r7, .L08034216
	ldrb r0, [r7, #0x0]
	cbz r0, .L08034216
	mov r5, r1
	ldrh r0, [r4, #0x4]
	ldrh r1, [r7, #0x6]
	cmp r0, r1
	bne.n .L08034216
	ldrb r1, [r7, #0x1]
	subs r0, r1, #0x1
	cmp r0, #0x2
	bhi.n .L08034216
	ldrb r0, [r4, #0x11]
	cbz r0, .L0803421e
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08034216:
	movs r0, #0x9
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803421e:
	ldr r3, [r4, #0x28]
	cbz r3, .L08034288
	adds r0, r5, #0x1
	beq.n .L080342a2
	ldr r0, [r4, #0xc]
	cmp r0, r5
	it cc
	movcc r5, r0
	cmp r5, #0x0
	str r5, [r4, #0x14]
	beq.w .L0803452a
	ldr r6, [r3, #0x4]
	sub.w r12, r5, #0x1
	cbz r6, .L08034284
	ldrh r0, [r7, #0xa]
	lsr.w r2, r12, #0xc
	udiv r2, r2, r0
	adds r3, #0x24
.L0803424a:
	cmp r2, r6
	bcc.w .L08034408
	ldr.w r0, [r3, #-0x18]
	cbz r0, .L08034284
	subs r2, r2, r6
	cmp r2, r0
	bcc.w .L0803440c
	ldr.w r6, [r3, #-0x10]
	cbz r6, .L08034284
	subs r2, r2, r0
	cmp r2, r6
	bcc.w .L08034410
	ldr.w r0, [r3, #-0x8]
	cbz r0, .L08034284
	subs r2, r2, r6
	cmp r2, r0
	bcc.w .L08034414
	ldr.w r6, [r3], #0x20
	subs r2, r2, r0
	cmp r6, #0x0
	bne.n .L0803424a
.L08034284:
	movs r2, #0x0
	b.n .L0803441a
.L08034288:
	ldr r1, [r4, #0xc]
	cmp r1, r5
	bcs.n .L080342fe
	ldrb r0, [r4, #0x10]
	lsls r0, r0, #0x1e
	bpl.n .L08034300
	mov r9, r4
	ldr.w r0, [r9, #0x14]!
	movs r1, #0x0
	str.w r1, [r9, #0x0]
	b.n .L08034314
.L080342a2:
	mov r9, r3
	ldr r0, [r4, #0x8]
	ldr.w r8, [r9], #0x4
	mov.w r11, #0x2
	cbz r0, .L080342e8
.L080342b0:
	mov r10, r0
	add.w r11, r11, #0x2
	movs r6, #0x0
	mov r5, r0
.L080342ba:
	ldr r0, [r4, #0x0]
	mov r1, r5
	bl allocation_table_read
	cmp r0, #0x1
	bls.w .L08034462
	adds r1, r0, #0x1
	beq.w .L08034504
	adds r1, r5, #0x1
	adds r6, #0x1
	cmp r0, r1
	mov r5, r0
	beq.n .L080342ba
	cmp r11, r8
	it ls
	strdls r6, r10, [r9], #0x8
	ldr r1, [r7, #0x18]
	cmp r0, r1
	bcc.n .L080342b0
	ldr r3, [r4, #0x28]
.L080342e8:
	cmp r11, r8
	str.w r11, [r3, #0x0]
	itee hi
	movhi r0, #0x11
	movls r0, #0x0
	strls.w r0, [r9, #0x0]
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080342fe:
	mov r1, r5
.L08034300:
	mov r9, r4
	ldr.w r0, [r9, #0x14]!
	mov.w r8, #0x0
	cmp r1, #0x0
	mov r5, r1
	str.w r8, [r9, #0x0]
	beq.n .L080343ac
.L08034314:
	ldrh r1, [r7, #0xa]
	lsl.w r6, r1, #0xc
	cbz r0, .L0803432c
	subs r1, r5, #0x1
	subs r0, #0x1
	udiv r1, r1, r6
	udiv r2, r0, r6
	cmp r1, r2
	bcs.n .L08034336
.L0803432c:
	ldr r1, [r4, #0x8]
	cmp r1, #0x0
	beq.n .L080343f0
.L08034332:
	str r1, [r4, #0x18]
	b.n .L08034340
.L08034336:
	rsbs r1, r6, #0
	ands r0, r1
	ldr r1, [r4, #0x18]
	str r0, [r4, #0x14]
	subs r5, r5, r0
.L08034340:
	cbz r1, .L080343a8
	cmp r5, r6
	bls.n .L0803437e
.L08034346:
	ldr r0, [r4, #0x14]
	ldrb r2, [r4, #0x10]
	add r0, r6
	lsls r2, r2, #0x1e
	str r0, [r4, #0x14]
	bmi.n .L0803435c
	ldr r0, [r4, #0x0]
	bl allocation_table_read
	mov r1, r0
	b.n .L08034366
.L0803435c:
	mov r0, r4
	bl next_or_allocate_cluster
	mov r1, r0
	cbz r0, .L080343a8
.L08034366:
	adds r0, r1, #0x1
	beq.w .L08034504
	cmp r1, #0x2
	bcc.n .L08034462
	ldr r0, [r7, #0x18]
	cmp r1, r0
	bcs.n .L08034462
	subs r5, r5, r6
	cmp r5, r6
	str r1, [r4, #0x18]
	bhi.n .L08034346
.L0803437e:
	ldr.w r0, [r9, #0x0]
	lsls r2, r5, #0x14
	add r0, r5
	str.w r0, [r9, #0x0]
	beq.n .L080343a8
	ldr r2, [r7, #0x18]
	subs r0, r1, #0x2
	subs r1, r2, #0x2
	cmp r0, r1
	bcs.n .L08034462
	ldr r1, [r7, #0x2c]
	ldrh r2, [r7, #0xa]
	mla r0, r0, r2, r1
	cmp r0, #0x0
	beq.n .L08034462
	add.w r8, r0, r5, lsr #0xc
	b.n .L080343ac
.L080343a8:
	mov.w r8, #0x0
.L080343ac:
	ldr r1, [r4, #0xc]
	ldr r0, [r4, #0x14]
	cmp r0, r1
	bls.n .L080343be
	ldrb r1, [r4, #0x10]
	str r0, [r4, #0xc]
	orr r1, r1, #0x40
	strb r1, [r4, #0x10]
.L080343be:
	lsls r0, r0, #0x14
	beq.w .L0803452a
	ldr r5, [r4, #0x1c]
	cmp r8, r5
	beq.w .L0803452a
	ldrsb.w r0, [r4, #0x10]
	cmp.w r0, #0xffffffff
	bgt.n .L08034488
	ldrb r0, [r7, #0x1]
	cmp r0, #0x3
	beq.n .L08034466
	cmp r0, #0x2
	bne.w .L08034504
	nop.w
	mov.w r0, #0x200000
	add.w r5, r0, r5, lsl #0xc
	b.n .L0803446c
.L080343f0:
	mov r0, r4
	movs r1, #0x0
	bl next_or_allocate_cluster
	mov r1, r0
	adds r0, #0x1
	beq.w .L08034504
	cmp r1, #0x1
	beq.n .L08034462
	str r1, [r4, #0x8]
	b.n .L08034332
.L08034408:
	subs r3, #0x1c
	b.n .L08034416
.L0803440c:
	subs r3, #0x14
	b.n .L08034416
.L08034410:
	subs r3, #0xc
	b.n .L08034416
.L08034414:
	subs r3, #0x4
.L08034416:
	ldr r0, [r3, #0x0]
	add r2, r0
.L0803441a:
	ldr r3, [r7, #0x18]
	subs r0, r2, #0x2
	subs r3, #0x2
	cmp r0, r3
	str r2, [r4, #0x18]
	bcs.n .L08034462
	ldr r3, [r7, #0x2c]
	ldrh r2, [r7, #0xa]
	mla r0, r0, r2, r3
	cbz r0, .L08034462
	lsls r3, r5, #0x14
	beq.n .L0803452a
	subs r2, #0x1
	and.w r2, r2, r12, lsr #0xc
	ldr r6, [r4, #0x1c]
	adds r5, r2, r0
	cmp r5, r6
	beq.n .L0803452a
	ldrsb.w r0, [r4, #0x10]
	cmp.w r0, #0xffffffff
	bgt.n .L080344ee
	cmp r1, #0x3
	beq.n .L080344c8
	cmp r1, #0x2
	bne.n .L08034504
	nop.w
	mov.w r0, #0x200000
	add.w r8, r0, r6, lsl #0xc
	b.n .L080344d0
.L08034462:
	movs r0, #0x2
	b.n .L08034506
.L08034466:
	nop.w
	lsls r5, r5, #0xc
.L0803446c:
	add.w r6, r4, #0x2c
	nop.w
	mov r0, r6
	mov r1, r5
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldrb r0, [r4, #0x10]
	and r0, r0, #0x7f
	strb r0, [r4, #0x10]
.L08034488:
	ldrb r0, [r7, #0x1]
	cmp r0, #0x3
	beq.n .L080344a0
	cmp r0, #0x2
	bne.n .L08034504
	nop.w
	mov.w r0, #0x200000
	add.w r5, r0, r8, lsl #0xc
	b.n .L080344a8
.L080344a0:
	nop.w
	lsl.w r5, r8, #0xc
.L080344a8:
	add.w r6, r4, #0x2c
	nop.w
	mov r0, r6
	mov r1, r5
	mov.w r2, #0x1000
	bl serial_device_read
	movs r0, #0x0
	str.w r8, [r4, #0x1c]
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080344c8:
	nop.w
	lsl.w r8, r6, #0xc
.L080344d0:
	add.w r6, r4, #0x2c
	nop.w
	mov r0, r6
	mov r1, r8
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldrb r0, [r4, #0x10]
	ldrb r1, [r7, #0x1]
	and r0, r0, #0x7f
	strb r0, [r4, #0x10]
.L080344ee:
	cmp r1, #0x3
	beq.n .L0803450e
	cmp r1, #0x2
	bne.n .L08034504
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r5, lsl #0xc
	b.n .L08034514
.L08034504:
	movs r0, #0x1
.L08034506:
	strb r0, [r4, #0x11]
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803450e:
	nop.w
	lsls r7, r5, #0xc
.L08034514:
	add.w r6, r4, #0x2c
	nop.w
	mov r0, r6
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_read
	str r5, [r4, #0x1c]
.L0803452a:
	movs r0, #0x0
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short 0x0000	@ padding (2 bytes), never reached

@ ----------------------------------------------------------------------------
@ dir_create - creates a directory at path r0 (no return value).
@ Resolves the path with mount_fat_volume (0803a7a0, args &r0, &base, 2) and path_resolve
@   (080366d8); requires the result 4 (not found). Allocates a cluster with
@   next_or_allocate_cluster (080312d4), flushes a dirty window (serial_device_write_merge,
@   0803616c), zeroes the window base+0x34 with zero_bytes_aligned (0800857c, 0x1000
@   bytes) and writes zeros to every sector of the cluster via 0803616c.
@ Builds the entry "." (name byte 0x2e then spaces, attribute 0x10, stamp 0x50210000 at
@   +0x16, cluster number bytes at +0x1a/+0x14) and the entry ".." (a copy of 0x20 bytes
@   via copy_bytes_forward (080087a6), byte 0x55 = '.', cluster = first cluster of the
@   parent from the iterator).
@ Links the entry with dir_add_entry (08033250), sets its stamp 0x50210000, cluster and
@   attribute 0x10 and calls fat_sync_volume (0803d934). On failure it frees the chain
@   with allocation_table_read (08036f18) / fat_set_entry (0803c86c) and updates the
@   counters base+0x14 and the flag base[4] |= 1.
@ ----------------------------------------------------------------------------
	.section .text.dir_create,"ax",%progbits
	.global dir_create
	.thumb_func
	.type dir_create, %function
dir_create:
	push.w {r4, r5, r6, r7, r8, r9, r10, lr}
	sub sp, #0x48
	str r0, [sp, #0x44]
	add r0, sp, #0x44
	mov r1, sp
	movs r2, #0x2
	bl mount_fat_volume
	cmp r0, #0x0
	bne.w .L080346f8
	ldr r4, [sp, #0x0]
	ldr r1, [sp, #0x44]
	add r0, sp, #0x14
	str r4, [sp, #0x14]
	bl path_resolve
	cmp r0, #0x4
	bne.w .L080346f8
	add r0, sp, #0x4
	movs r1, #0x0
	str r4, [sp, #0x4]
	bl next_or_allocate_cluster
	subs r5, r0, #0x2
	mov r9, r0
	cmn.w r5, #0x4
	bhi.w .L080346ec
	ldrb r0, [r4, #0x3]
	cbz r0, .L080345f4
	ldrb r0, [r4, #0x1]
	ldr r6, [r4, #0x30]
	cmp r0, #0x3
	beq.n .L08034594
	cmp r0, #0x2
	bne.w .L080346f2
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r6, lsl #0xc
	b.n .L0803459a
.L08034594:
	nop.w
	lsls r7, r6, #0xc
.L0803459a:
	add.w r8, r4, #0x34
	nop.w
	mov r0, r8
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [r4, #0x24]
	ldr r0, [r4, #0x30]
	ldr r1, [r4, #0x1c]
	subs r3, r0, r3
	movs r2, #0x0
	cmp r3, r1
	strb r2, [r4, #0x3]
	bcs.n .L080345f4
	ldrb r2, [r4, #0x2]
	cmp r2, #0x2
	bne.n .L080345f4
	ldrb r2, [r4, #0x1]
	adds r6, r1, r0
	cmp r2, #0x3
	beq.n .L080345de
	cmp r2, #0x2
	bne.n .L080345f4
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r6, lsl #0xc
	b.n .L080345e4
.L080345de:
	nop.w
	lsls r7, r6, #0xc
.L080345e4:
	nop.w
	mov r0, r8
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L080345f4:
	ldr r0, [r4, #0x18]
	subs r0, #0x2
	cmp r5, r0
	bcs.n .L08034606
	ldr r0, [r4, #0x2c]
	ldrh r6, [r4, #0xa]
	mla r8, r5, r6, r0
	b.n .L0803460c
.L08034606:
	ldrh r6, [r4, #0xa]
	mov.w r8, #0x0
.L0803460c:
	add.w r10, r4, #0x34
	mov r0, r10
	mov.w r1, #0x1000
	str.w r8, [r4, #0x30]
	bl zero_bytes_aligned
	cbz r6, .L08034664
	mov.w r0, #0x200000
	add.w r7, r0, r8, lsl #0xc
	movs r5, #0x0
	b.n .L08034652
.L0803462c:
	add.w r6, r5, r8
	nop.w
	lsls r6, r6, #0xc
.L08034636:
	nop.w
	mov r0, r10
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldrh r6, [r4, #0xa]
	adds r5, #0x1
	cmp r5, r6
	add.w r7, r7, #0x1000
	bcs.n .L08034668
.L08034652:
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803462c
	cmp r0, #0x2
	bne.n .L08034668
	nop.w
	mov r6, r7
	b.n .L08034636
.L08034664:
	movs r6, #0x0
	movs r5, #0x0
.L08034668:
	cmp r5, r6
	bne.n .L080346ec
	movw r0, #0x2020
	ldrb r5, [r4, #0x0]
	strh.w r0, [r4, #0x3d]
	mov.w r0, #0x20202020
	movw r8, #0x0
	str.w r0, [r4, #0x39]
	str.w r0, [r4, #0x35]
	movs r7, #0x2e
	movs r0, #0x10
	movt r8, #0x5021
	lsr.w r6, r9, #0x8
	cmp r5, #0x3
	strb.w r7, [r4, #0x34]
	strb.w r0, [r4, #0x3f]
	str.w r8, [r4, #0x4a]
	strb.w r9, [r4, #0x4e]
	strb.w r6, [r4, #0x4f]
	bne.n .L080346ba
	lsr.w r0, r9, #0x10
	strb.w r0, [r4, #0x48]
	lsr.w r0, r9, #0x18
	strb.w r0, [r4, #0x49]
.L080346ba:
	add.w r0, r4, #0x54
	mov r1, r10
	movs r2, #0x20
	bl copy_bytes_forward
	ldr r0, [sp, #0x1c]
	cmp r5, #0x3
	strb.w r7, [r4, #0x55]
	strh.w r0, [r4, #0x6e]
	bne.n .L080346e0
	lsrs r1, r0, #0x10
	lsrs r0, r0, #0x18
	strb.w r1, [r4, #0x68]
	strb.w r0, [r4, #0x69]
.L080346e0:
	movs r0, #0x1
	strb r0, [r4, #0x3]
	add r0, sp, #0x14
	bl dir_add_entry
	cbz r0, .L0803473c
.L080346ec:
	cmp.w r9, #0x2
	bcc.n .L080346f8
.L080346f2:
	ldr r0, [r4, #0x18]
	cmp r0, r9
	bhi.n .L08034706
.L080346f8:
	add sp, #0x48
	pop.w {r4, r5, r6, r7, r8, r9, r10, pc}
	.byte 0x00, 0xbf	@ padding (2 bytes), never reached
.L08034700:
	cmp r6, r0
	mov r9, r6
	bcs.n .L080346f8
.L08034706:
	mov r0, r4
	mov r1, r9
	bl allocation_table_read
	mov r6, r0
	adds r0, #0x1
	cmp r0, #0x3
	bcc.n .L080346f8
	mov r0, r4
	mov r1, r9
	movs r2, #0x0
	bl fat_set_entry
	cmp r0, #0x0
	bne.n .L080346f8
	ldrd r1, r0, [r4, #0x14]
	subs r2, r0, #0x2
	cmp r1, r2
	bcs.n .L08034700
	ldrb r2, [r4, #0x4]
	adds r1, #0x1
	str r1, [r4, #0x14]
	orr r1, r2, #0x1
	strb r1, [r4, #0x4]
	b.n .L08034700
.L0803473c:
	ldr r0, [sp, #0x30]
	str.w r8, [r0, #0x16]
	ldr r0, [sp, #0x30]
	strb.w r9, [r0, #0x1a]
	strb r6, [r0, #0x1b]
	ldrb r1, [r4, #0x0]
	cmp r1, #0x3
	bne.n .L0803475c
	lsr.w r1, r9, #0x10
	strb r1, [r0, #0x14]
	lsr.w r1, r9, #0x18
	strb r1, [r0, #0x15]
.L0803475c:
	ldr r0, [sp, #0x30]
	movs r1, #0x10
	strb r1, [r0, #0xb]
	movs r0, #0x1
	strb r0, [r4, #0x3]
	mov r0, r4
	bl fat_sync_volume
	add sp, #0x48
	pop.w {r4, r5, r6, r7, r8, r9, r10, pc}
	.short 0x0000	@ padding (2 bytes), never reached

@ ----------------------------------------------------------------------------
@ drive_unmount - unmounts the drive named by a "d:" prefix of path r0 (clears the first
@ byte of its registered volume object).
@ Parses path string r0 for a drive prefix: returns 0xb for null; scans bytes (stops at
@   < 0x20 or ':' 0x3a); when the scan ends on ':' the prefix is valid only when the text
@   up to and including the ':' is 2 bytes and the first char is '0'..'3', else 0xb;
@   when the scan ends on a byte below 0x20 the drive is 0.
@ Clears the byte pointed to by the word at 0x20005fcc + 4 * drive when that word is
@   non-null. Returns 0x11 for drive 2 or 3 and 3 otherwise.
@ ----------------------------------------------------------------------------
	.section .text.drive_unmount,"ax",%progbits
	.global drive_unmount
	.thumb_func
	.type drive_unmount, %function
drive_unmount:
	push {r7, lr}
	cbz r0, .L080347aa
	movs r1, #0x0
	nop
.L0803477c:
	ldrb r2, [r0, r1]
	cmp r2, #0x20
	bcc.n .L080347ae
	cmp r2, #0x3a
	beq.n .L080347ae
	adds r3, r0, r1
	ldrb r2, [r3, #0x1]
	cmp r2, #0x20
	bcc.n .L080347b6
	cmp r2, #0x3a
	beq.n .L080347b6
	ldrb r2, [r3, #0x2]
	cmp r2, #0x20
	bcc.n .L080347d4
	cmp r2, #0x3a
	beq.n .L080347d4
	ldrb r2, [r3, #0x3]
	adds r1, #0x4
	cmp r2, #0x20
	bcc.n .L080347b8
	cmp r2, #0x3a
	bne.n .L0803477c
	b.n .L080347b8
.L080347aa:
	movs r0, #0xb
	pop {r7, pc}
.L080347ae:
	adds r1, #0x1
	cmp r2, #0x3a
	beq.n .L080347bc
	b.n .L080347da
.L080347b6:
	adds r1, #0x2
.L080347b8:
	cmp r2, #0x3a
	bne.n .L080347da
.L080347bc:
	ldrb r2, [r0, #0x0]
	movs r0, #0xb
	cmp r2, #0x33
	bhi.n .L080347d2
	cmp r1, #0x2
	it ne
	popne {r7, pc}
	sub.w r1, r2, #0x30
	cmp r1, #0x9
	bls.n .L080347dc
.L080347d2:
	pop {r7, pc}
.L080347d4:
	adds r1, #0x3
	cmp r2, #0x3a
	beq.n .L080347bc
.L080347da:
	movs r1, #0x0
.L080347dc:
	movw r0, #0x5fcc
	movt r0, #0x2000
	ldr.w r0, [r0, r1, lsl #0x2]
	cmp r0, #0x0
	itt ne
	movne r2, #0x0
	strbne r2, [r0, #0x0]
	uxtb r0, r1
	cmp r0, #0x3
	beq.n .L080347fe
	cmp r0, #0x2
	bne.n .L08034806
	nop.w
.L080347fe:
	nop.w
	movs r0, #0x11
	pop {r7, pc}
.L08034806:
	movs r0, #0x3
	pop {r7, pc}
	.short 0x0000	@ padding (2 bytes), never reached

@ ----------------------------------------------------------------------------
@ drive_mount - registers buffer r0 as the volume object of the drive named by path r1.
@ Returns 0xb for a null path; parses an optional "d:" prefix as in drive_unmount
@   (digit 0..3 only, otherwise 0xb), drive 0 without prefix.
@ Clears the byte of the previous pointer in the table 0x20005fcc[drive], clears *r0,
@   stores r0 in the table and returns mount_fat_volume (0803a7a0) called with
@   (&path, &buf, 0).
@ ----------------------------------------------------------------------------
	.section .text.drive_mount,"ax",%progbits
	.global drive_mount
	.thumb_func
	.type drive_mount, %function
drive_mount:
	push {r7, lr}
	sub sp, #0x8
	str r0, [sp, #0x4]
	str r1, [sp, #0x0]
	cbz r1, .L08034850
	mov.w r12, #0x0
	nop
.L0803481c:
	ldrb.w r3, [r1, r12]
	cmp r3, #0x20
	bcc.n .L08034854
	cmp r3, #0x3a
	beq.n .L08034854
	add.w r2, r1, r12
	ldrb r3, [r2, #0x1]
	cmp r3, #0x20
	bcc.n .L0803485e
	cmp r3, #0x3a
	beq.n .L0803485e
	ldrb r3, [r2, #0x2]
	cmp r3, #0x20
	bcc.n .L0803487c
	cmp r3, #0x3a
	beq.n .L0803487c
	ldrb r3, [r2, #0x3]
	add.w r12, r12, #0x4
	cmp r3, #0x20
	bcc.n .L08034862
	cmp r3, #0x3a
	bne.n .L0803481c
	b.n .L08034862
.L08034850:
	movs r1, #0xb
	b.n .L080348b2
.L08034854:
	add.w r12, r12, #0x1
	cmp r3, #0x3a
	beq.n .L08034866
	b.n .L08034884
.L0803485e:
	add.w r12, r12, #0x2
.L08034862:
	cmp r3, #0x3a
	bne.n .L08034884
.L08034866:
	ldrb r2, [r1, #0x0]
	movs r1, #0xb
	cmp r2, #0x33
	bhi.n .L080348b2
	cmp.w r12, #0x2
	bne.n .L080348b2
	subs r2, #0x30
	cmp r2, #0x9
	bls.n .L08034886
	b.n .L080348b2
.L0803487c:
	add.w r12, r12, #0x3
	cmp r3, #0x3a
	beq.n .L08034866
.L08034884:
	movs r2, #0x0
.L08034886:
	movw r12, #0x5fcc
	movt r12, #0x2000
	ldr.w r3, [r12, r2, lsl #0x2]
	cmp r3, #0x0
	itt ne
	movne r1, #0x0
	strbne r1, [r3, #0x0]
	cmp r0, #0x0
	itt ne
	movne r1, #0x0
	strbne r1, [r0, #0x0]
	str.w r0, [r12, r2, lsl #0x2]
	mov r0, sp
	add r1, sp, #0x4
	movs r2, #0x0
	bl mount_fat_volume
	mov r1, r0
.L080348b2:
	mov r0, r1
	add sp, #0x8
	pop {r7, pc}

@ ----------------------------------------------------------------------------
@ file_open - opens or creates a file. r0 = file object, r1 = path, r2 = mode flags
@ (mask 0x3f: bit 0 read, bit 1 write, bit 3 truncate/create, bits 0x1c select create
@ modes, 0x20 append).
@ Returns 9 for a null object; resolves with mount_fat_volume (0803a7a0) and path_resolve
@   (080366d8); a lookup result of 0 is replaced by 6 when byte iterator+0x2b has bit 7
@   set.
@ For flags with bits 0x1c clear it requires an existing file (returns 4 if the entry
@   attribute has bit 0x10, 7 if write is requested and the entry attribute has bit 0).
@ With create flags a missing entry (result 4) is created with dir_add_entry (08033250);
@   an existing entry with attribute bits 0x11 returns 7 and, when r2 bit 2 is set, any
@   other existing entry returns 8. Truncation only happens when bit 3 is set (bit 3 is
@   forced on when the lookup result was not 0); an entry to truncate gets 0x50210000
@   stamps at +0xe/+0x16, attribute 0x20, first cluster 0 and size 0 and its old chain is
@   freed with allocation_table_read (08036f18) / fat_set_entry (0803c86c) (counters
@   base+0x14, base[4] |= 1).
@ Fills obj[8] = window sector, obj[9] = entry, obj[2] = first cluster (high bytes
@   +0x14/+0x15 when type 3), obj[3] = size, obj[10] = 0, obj[0] = base, ushort obj+4 =
@   ushort base+6, flags byte obj+0x10 = mode | (bit 3 << 3), obj+0x11 = 0,
@   obj[5] = obj[7] = 0, clears the window obj+0x2c with zero_bytes_aligned (0800857c).
@   For flag 0x20 it positions at the end of the file (follows the chain, loads the
@   window with serial_device_read 08036048 / writes with 0803616c).
@ Returns 0 on success; on any error clears obj[0] and returns the error.
@ ----------------------------------------------------------------------------
	.section .text.file_open,"ax",%progbits
	.global file_open
	.thumb_func
	.type file_open, %function
file_open:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x3c
	str r1, [sp, #0x38]
	cbz r0, .L080348e0
	and r11, r2, #0x3f
	mov r7, r2
	mov r10, r0
	add r0, sp, #0x38
	add r1, sp, #0x4
	mov r2, r11
	bl mount_fat_volume
	mov r6, r0
	cbz r0, .L080348ea
.L080348d8:
	movs r0, #0x0
	str.w r0, [r10, #0x0]
	b.n .L080348e2
.L080348e0:
	movs r6, #0x9
.L080348e2:
	mov r0, r6
	add sp, #0x3c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080348ea:
	ldr.w r9, [sp, #0x4]
	ldr r1, [sp, #0x38]
	add r0, sp, #0x8
	str.w r9, [sp, #0x8]
	bl path_resolve
	mov r6, r0
	cmp r6, #0x0
	ldrsb.w r0, [sp, #0x33]
	mov.w r1, #0x6
	it eq
	andeq.w r6, r1, r0, lsr #0x7
	tst.w r11, #0x1c
	beq.n .L080349e8
	cmp r6, #0x0
	beq.n .L08034a06
	cmp r6, #0x4
	bne.n .L08034922
	add r0, sp, #0x8
	bl dir_add_entry
	mov r6, r0
.L08034922:
	orr r11, r11, #0x8
.L08034926:
	cmp r6, #0x0
	bne.w .L08034b10
.L0803492c:
	ands.w r0, r11, #0x8
	beq.w .L08034b10
	ldr r0, [sp, #0x24]
	movs r1, #0x0
	movt r1, #0x5021
	str.w r1, [r0, #0xe]
	ldr r0, [sp, #0x24]
	str.w r1, [r0, #0x16]
	ldr r0, [sp, #0x24]
	ldrb.w r1, [r9, #0x0]
	ldrh r4, [r0, #0x1a]
	cmp r1, #0x3
	bne.n .L0803495e
	ldrb r1, [r0, #0x14]
	ldrb r2, [r0, #0x15]
	orr.w r1, r4, r1, lsl #0x10
	orr.w r4, r1, r2, lsl #0x18
.L0803495e:
	movs r1, #0x20
	strb r1, [r0, #0xb]
	ldr r1, [sp, #0x24]
	movs r0, #0x0
	strh r0, [r1, #0x1a]
	ldrb.w r2, [r9, #0x0]
	cmp r2, #0x3
	it eq
	strheq r0, [r1, #0x14]
	ldr r1, [sp, #0x24]
	cmp r4, #0x0
	str r0, [r1, #0x1c]
	mov.w r0, #0x1
	strb.w r0, [r9, #0x3]
	beq.w .L08034b16
	cmp r4, #0x1
	beq.w .L08034c18
	ldr.w r8, [sp, #0x8]
	ldr.w r0, [r8, #0x18]
	cmp r0, r4
	bls.w .L08034c18
	ldr.w r5, [r9, #0x30]
	mov r0, r8
	mov r6, r4
.L080349a0:
	mov r1, r6
	bl allocation_table_read
	mov r7, r0
	adds r0, #0x1
	beq.w .L08034c1c
	cbz r7, .L08034a26
	cmp r7, #0x1
	beq.w .L08034c18
	mov r0, r8
	mov r1, r6
	movs r2, #0x0
	bl fat_set_entry
	cbnz r0, .L08034a32
	ldrd r1, r0, [r8, #0x14]
	subs r2, r0, #0x2
	cmp r1, r2
	bcs.n .L080349de
	ldrb.w r2, [r8, #0x4]
	adds r1, #0x1
	str.w r1, [r8, #0x14]
	orr r1, r2, #0x1
	strb.w r1, [r8, #0x4]
.L080349de:
	cmp r7, r0
	bcs.n .L08034a26
	ldr r0, [sp, #0x8]
	mov r6, r7
	b.n .L080349a0
.L080349e8:
	cmp r6, #0x0
	bne.w .L080348d8
	ldrb.w r0, [sp, #0xe]
	lsls r1, r0, #0x1b
	bmi.n .L08034a22
	lsls.w r1, r11, #0x1e
	bpl.w .L08034b16
	ands.w r0, r0, #0x1
	bne.n .L08034a10
	b.n .L08034b16
.L08034a06:
	ldrb.w r0, [sp, #0xe]
	tst.w r0, #0x11
	beq.n .L08034a14
.L08034a10:
	movs r6, #0x7
	b.n .L080348d8
.L08034a14:
	movs r0, #0x8
	and.w r6, r0, r7, lsl #0x1
	cmp r6, #0x0
	beq.w .L0803492c
	b.n .L08034b10
.L08034a22:
	movs r6, #0x4
	b.n .L080348d8
.L08034a26:
	ldr.w r6, [r9, #0x30]
	cmp r6, r5
	bne.n .L08034a36
	movs r6, #0x0
	b.n .L08034b0a
.L08034a32:
	mov r6, r0
	b.n .L080348d8
.L08034a36:
	ldrb.w r0, [r9, #0x3]
	cmp r0, #0x0
	beq.n .L08034ac8
	ldrb.w r0, [r9, #0x1]
	cmp r0, #0x3
	beq.n .L08034a58
	cmp r0, #0x2
	bne.n .L08034aae
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r6, lsl #0xc
	b.n .L08034a5e
.L08034a58:
	nop.w
	lsls r7, r6, #0xc
.L08034a5e:
	add.w r6, r9, #0x34
	nop.w
	mov r0, r6
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr.w r3, [r9, #0x24]
	ldr.w r0, [r9, #0x30]
	ldr.w r1, [r9, #0x1c]
	subs r3, r0, r3
	movs r2, #0x0
	cmp r3, r1
	strb.w r2, [r9, #0x3]
	bcs.n .L08034ac8
	ldrb.w r2, [r9, #0x2]
	cmp r2, #0x2
	bne.n .L08034ac8
	ldrb.w r2, [r9, #0x1]
	adds r7, r1, r0
	cmp r2, #0x3
	beq.n .L08034ab2
	cmp r2, #0x2
	bne.n .L08034ac8
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L08034ab8
.L08034aae:
	movs r6, #0x1
	b.n .L08034b0a
.L08034ab2:
	nop.w
	lsls r7, r7, #0xc
.L08034ab8:
	nop.w
	mov r0, r6
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L08034ac8:
	ldrb.w r0, [r9, #0x1]
	cmp r0, #0x3
	beq.n .L08034ae2
	cmp r0, #0x2
	bne.n .L08034b00
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r5, lsl #0xc
	b.n .L08034ae8
.L08034ae2:
	nop.w
	lsls r6, r5, #0xc
.L08034ae8:
	add.w r7, r9, #0x34
	nop.w
	mov r0, r7
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_read
	movs r6, #0x0
	b.n .L08034b06
.L08034b00:
	mov.w r5, #0xffffffff
	movs r6, #0x1
.L08034b06:
	str.w r5, [r9, #0x30]
.L08034b0a:
	subs r0, r4, #0x1
	str.w r0, [r9, #0x10]
.L08034b10:
	cmp r6, #0x0
	bne.w .L080348d8
.L08034b16:
	ldr.w r2, [r9, #0x30]
	ldr r1, [sp, #0x24]
	and r0, r11, #0x8
	strd r2, r1, [r10, #0x20]
	ldrb.w r2, [r9, #0x0]
	ldrh r7, [r1, #0x1a]
	cmp r2, #0x3
	orr.w r0, r11, r0, lsl #0x3
	bne.n .L08034b3e
	ldrb r2, [r1, #0x14]
	ldrb r3, [r1, #0x15]
	orr.w r2, r7, r2, lsl #0x10
	orr.w r7, r2, r3, lsl #0x18
.L08034b3e:
	str.w r7, [r10, #0x8]
	ldr r5, [r1, #0x1c]
	movs r6, #0x0
	str.w r5, [r10, #0xc]
	str.w r6, [r10, #0x28]
	str.w r9, [r10, #0x0]
	ldrh.w r1, [r9, #0x6]
	add.w r8, r10, #0x2c
	strh.w r1, [r10, #0x4]
	strb.w r0, [r10, #0x10]
	mov r0, r8
	mov.w r1, #0x1000
	strb.w r6, [r10, #0x11]
	str.w r6, [r10, #0x1c]
	str.w r6, [r10, #0x14]
	bl zero_bytes_aligned
	lsls.w r0, r11, #0x1a
	bpl.w .L080348e2
	cmp r5, #0x0
	beq.w .L080348e2
	str.w r5, [r10, #0x14]
	ldrh.w r0, [r9, #0xa]
	movs r6, #0x0
	cmp.w r5, r0, lsl #0xc
	bls.n .L08034bcc
	lsls r4, r0, #0xc
	subs r5, r5, r4
	mov r0, r9
.L08034b9c:
	mov r1, r7
	bl allocation_table_read
	mov r7, r0
	cmp r0, #0x2
	mov.w r0, #0x0
	it cc
	movcc r0, #0x1
	lsls r6, r0, #0x1
	adds r0, r7, #0x1
	it eq
	moveq r6, #0x1
	clz r0, r6
	lsr.w r0, r0, #0x5
	cbnz r6, .L08034bce
	cmp r5, r4
	bls.n .L08034bce
	ldr.w r0, [r10, #0x0]
	subs r5, r5, r4
	b.n .L08034b9c
.L08034bcc:
	movs r0, #0x1
.L08034bce:
	str.w r7, [r10, #0x18]
	cbz r0, .L08034c36
	mov r0, r5
	bfc r0, #0xc, #0x14
	cbz r0, .L08034c36
	ldr.w r1, [r9, #0x18]
	subs r0, r7, #0x2
	subs r1, #0x2
	cmp r0, r1
	bcs.n .L08034c18
	ldr.w r1, [r9, #0x2c]
	ldrh.w r2, [r9, #0xa]
	mla r0, r0, r2, r1
	cbz r0, .L08034c18
	add.w r4, r0, r5, lsr #0xc
	str.w r4, [r10, #0x1c]
	ldrb.w r0, [r9, #0x1]
	cmp r0, #0x3
	beq.n .L08034c20
	cmp r0, #0x2
	bne.n .L08034c1c
	nop.w
	mov.w r0, #0x200000
	add.w r5, r0, r4, lsl #0xc
	b.n .L08034c26
.L08034c18:
	movs r6, #0x2
	b.n .L080348d8
.L08034c1c:
	movs r6, #0x1
	b.n .L080348d8
.L08034c20:
	nop.w
	lsls r5, r4, #0xc
.L08034c26:
	nop.w
	mov r0, r8
	mov r1, r5
	mov.w r2, #0x1000
	bl serial_device_read
.L08034c36:
	cmp r6, #0x0
	bne.w .L080348d8
	movs r6, #0x0
	b.n .L080348e2

@ ----------------------------------------------------------------------------
@ dir_open - opens directory object r0 for path r1 (for reading its entries).
@ Returns 9 for a null object; resolves with mount_fat_volume (0803a7a0, args &path,
@   &base, 0), stores base in obj[0] and calls path_resolve (080366d8).
@ When bit 7 of byte obj+0x2b is clear it requires attribute byte obj+6 bit 0x10 (else
@   returns 5) and sets obj[2] to the first cluster (ushort entry+0x1a, plus
@   entry+0x14/+0x15 when base byte 0 == 3). Stores ushort base+6 at obj+4 and calls
@   dir_set_offset (08033e94) with (obj, 0).
@ Returns 0 on success, error 4 mapped to 5; clears obj[0] on failure.
@ ----------------------------------------------------------------------------
	.section .text.dir_open,"ax",%progbits
	.global dir_open
	.thumb_func
	.type dir_open, %function
dir_open:
	push {r4, r5, r6, lr}
	sub sp, #0x8
	str r1, [sp, #0x4]
	cbz r0, .L08034c74
	mov r4, r0
	add r0, sp, #0x4
	mov r1, sp
	movs r2, #0x0
	movs r5, #0x0
	bl mount_fat_volume
	cbnz r0, .L08034c6e
	ldrd r6, r1, [sp, #0x0]
	mov r0, r4
	str r6, [r4, #0x0]
	bl path_resolve
	cbz r0, .L08034c7a
	cbz r0, .L08034cb4
.L08034c68:
	cmp r0, #0x4
	it eq
	moveq r0, #0x5
.L08034c6e:
	str r5, [r4, #0x0]
	add sp, #0x8
	pop {r4, r5, r6, pc}
.L08034c74:
	movs r0, #0x9
	add sp, #0x8
	pop {r4, r5, r6, pc}
.L08034c7a:
	ldrsb.w r0, [r4, #0x2b]
	cmp r0, #0x0
	bmi.n .L08034ca4
	ldrb r0, [r4, #0x6]
	lsls r0, r0, #0x1b
	bmi.n .L08034c8c
	movs r0, #0x5
	b.n .L08034c6e
.L08034c8c:
	ldr r1, [r4, #0x1c]
	ldrb r2, [r6, #0x0]
	ldrh r0, [r1, #0x1a]
	cmp r2, #0x3
	bne.n .L08034ca2
	ldrb r2, [r1, #0x14]
	ldrb r1, [r1, #0x15]
	orr.w r0, r0, r2, lsl #0x10
	orr.w r0, r0, r1, lsl #0x18
.L08034ca2:
	str r0, [r4, #0x8]
.L08034ca4:
	ldrh r0, [r6, #0x6]
	movs r1, #0x0
	strh r0, [r4, #0x4]
	mov r0, r4
	bl dir_set_offset
	cmp r0, #0x0
	bne.n .L08034c68
.L08034cb4:
	movs r0, #0x0
	add sp, #0x8
	pop {r4, r5, r6, pc}
	.short 0x0000	@ padding (2 bytes), never reached

@ ----------------------------------------------------------------------------
@ file_read - reads up to r2 bytes of file object r0 into buffer r1 and stores the
@ count read in *r3.
@ Returns 9 for an invalid object, obj byte 0x11 when nonzero, 7 when obj byte 0x10 bit 0
@   is clear. Limits r2 to the size obj[3] minus the position obj[5].
@ Per loop step it locates the cluster (allocation_table_read 08036f18 or the table at
@   obj[10]), reads whole 0x1000-byte units directly with serial_device_read (08036048),
@   or copies partial data from the window obj+0x2c with copy_bytes_forward (080087a6);
@   updates *r3 and obj[5]. A dirty window is written back with serial_device_write_merge
@   (0803616c) first.
@ Returns 0 on success, 1 on read failure, 2 on bad chain (error stored at obj+0x11).
@ ----------------------------------------------------------------------------
	.section .text.file_read,"ax",%progbits
	.global file_read
	.thumb_func
	.type file_read, %function
file_read:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0xc
	mov r4, r0
	movs r0, #0x0
	str r0, [r3, #0x0]
	cbz r4, .L08034cee
	ldr r6, [r4, #0x0]
	cbz r6, .L08034cee
	ldrb r0, [r6, #0x0]
	cbz r0, .L08034cee
	mov r9, r1
	ldrh r0, [r4, #0x4]
	ldrh r1, [r6, #0x6]
	cmp r0, r1
	bne.n .L08034cee
	ldrb r0, [r6, #0x1]
	subs r0, #0x1
	cmp r0, #0x2
	bhi.n .L08034cee
	ldrb r0, [r4, #0x11]
	cbz r0, .L08034cf6
.L08034ce8:
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08034cee:
	movs r0, #0x9
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08034cf6:
	ldrb r0, [r4, #0x10]
	lsls r0, r0, #0x1f
	bne.n .L08034d04
	movs r0, #0x7
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08034d04:
	ldr r0, [r4, #0xc]
	ldr r1, [r4, #0x14]
	mov r11, r2
	subs r0, r0, r1
	cmp r0, r2
	it cc
	movcc r11, r0
	cmp.w r11, #0x0
	mov.w r8, #0x0
	beq.n .L08034d26
	mov r5, r3
	add.w r0, r4, #0x2c
	str r0, [sp, #0x4]
	b.n .L08034d82
.L08034d26:
	movs r0, #0x0
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08034d2e:
	nop.w
	lsl.w r7, r10, #0xc
.L08034d36:
	nop.w
	ldr r0, [sp, #0x4]
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_read
.L08034d46:
	ldr r0, [r4, #0x14]
	str.w r10, [r4, #0x1c]
	bfc r0, #0xc, #0x14
.L08034d50:
	rsb.w r7, r0, #0x1000
	add r0, r4
	cmp r7, r11
	it hi
	movhi r7, r11
	add.w r1, r0, #0x2c
	mov r0, r9
	mov r2, r7
	bl copy_bytes_forward
.L08034d68:
	ldr r0, [r5, #0x0]
	subs.w r11, r11, r7
	add r0, r7
	str r0, [r5, #0x0]
	ldr r0, [r4, #0x14]
	add r9, r7
	add.w r1, r0, r7
	mov.w r0, #0x0
	str r1, [r4, #0x14]
	beq.n .L08034ce8
.L08034d82:
	mov r0, r1
	bfc r0, #0xc, #0x14
	cmp r0, #0x0
	bne.n .L08034d50
	ldrh r0, [r6, #0xa]
	subs r0, #0x1
	and.w r7, r0, r1, lsr #0xc
	cbz r7, .L08034d9a
	ldr r0, [r4, #0x18]
	b.n .L08034e20
.L08034d9a:
	cbz r1, .L08034df6
	ldr r3, [r4, #0x28]
	cbz r3, .L08034dfa
	ldr r2, [r3, #0x4]
	cmp r2, #0x0
	beq.w .L08034f10
	ldr r0, [r4, #0x0]
	lsrs r1, r1, #0xc
	ldrh r0, [r0, #0xa]
	udiv r0, r1, r0
	add.w r1, r3, #0x24
.L08034db6:
	cmp r0, r2
	bcc.n .L08034e04
	ldr.w r3, [r1, #-0x18]
	cmp r3, #0x0
	beq.w .L08034f10
	subs r0, r0, r2
	cmp r0, r3
	bcc.n .L08034e08
	ldr.w r2, [r1, #-0x10]
	cmp r2, #0x0
	beq.w .L08034f10
	subs r0, r0, r3
	cmp r0, r2
	bcc.n .L08034e0c
	ldr.w r3, [r1, #-0x8]
	cmp r3, #0x0
	beq.w .L08034f10
	subs r0, r0, r2
	cmp r0, r3
	bcc.n .L08034e10
	ldr.w r2, [r1], #0x20
	subs r0, r0, r3
	cmp r2, #0x0
	bne.n .L08034db6
	b.n .L08034f10
.L08034df6:
	ldr r0, [r4, #0x8]
	b.n .L08034e16
.L08034dfa:
	ldr r0, [r4, #0x0]
	ldr r1, [r4, #0x18]
	bl allocation_table_read
	b.n .L08034e16
.L08034e04:
	subs r1, #0x1c
	b.n .L08034e12
.L08034e08:
	subs r1, #0x14
	b.n .L08034e12
.L08034e0c:
	subs r1, #0xc
	b.n .L08034e12
.L08034e10:
	subs r1, #0x4
.L08034e12:
	ldr r1, [r1, #0x0]
	add r0, r1
.L08034e16:
	cmp r0, #0x1
	bls.n .L08034f10
	adds r1, r0, #0x1
	beq.n .L08034f1a
	str r0, [r4, #0x18]
.L08034e20:
	ldr r2, [r6, #0x18]
	subs r1, r0, #0x2
	subs r0, r2, #0x2
	cmp r1, r0
	bcs.n .L08034f10
	ldr r2, [r6, #0x2c]
	ldrh r0, [r6, #0xa]
	mla r1, r1, r0, r2
	cmp r1, #0x0
	beq.n .L08034f10
	cmp.w r8, r11, lsr #0xc
	add.w r10, r1, r7
	beq.n .L08034e6c
	lsr.w r8, r11, #0xc
	add.w r1, r7, r8
	cmp r1, r0
	ldrb r1, [r6, #0x1]
	it hi
	subhi.w r8, r0, r7
	cmp r1, #0x3
	str.w r10, [sp, #0x8]
	beq.n .L08034e96
	cmp r1, #0x2
	bne.n .L08034f1a
	nop.w
	mov.w r0, #0x200000
	add.w r10, r0, r10, lsl #0xc
	b.n .L08034e9e
.L08034e6c:
	ldr r7, [r4, #0x1c]
	cmp r7, r10
	beq.w .L08034d46
	ldrsb.w r0, [r4, #0x10]
	cmp.w r0, #0xffffffff
	bgt.n .L08034ef6
	ldrb r0, [r6, #0x1]
	cmp r0, #0x3
	beq.n .L08034ed8
	cmp r0, #0x2
	bne.n .L08034f1a
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L08034ede
.L08034e96:
	nop.w
	lsl.w r10, r10, #0xc
.L08034e9e:
	nop.w
	lsl.w r7, r8, #0xc
	uxth r2, r7
	mov r0, r9
	mov r1, r10
	bl serial_device_read
	ldrsb.w r0, [r4, #0x10]
	cmp.w r0, #0xffffffff
	bgt.n .L08034ed2
	ldr r0, [r4, #0x1c]
	ldr r1, [sp, #0x8]
	subs r0, r0, r1
	cmp r0, r8
	bcs.n .L08034ed2
	ldr r1, [sp, #0x4]
	add.w r0, r9, r0, lsl #0xc
	mov.w r2, #0x1000
	bl copy_bytes_forward
.L08034ed2:
	mov.w r8, #0x0
	b.n .L08034d68
.L08034ed8:
	nop.w
	lsls r7, r7, #0xc
.L08034ede:
	nop.w
	ldr r0, [sp, #0x4]
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldrb r0, [r4, #0x10]
	and r0, r0, #0x7f
	strb r0, [r4, #0x10]
.L08034ef6:
	ldrb r0, [r6, #0x1]
	cmp r0, #0x3
	beq.w .L08034d2e
	cmp r0, #0x2
	bne.n .L08034f1a
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r10, lsl #0xc
	b.n .L08034d36
.L08034f10:
	movs r0, #0x2
.L08034f12:
	strb r0, [r4, #0x11]
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08034f1a:
	movs r0, #0x1
	b.n .L08034f12
	.short 0x0000	@ padding (2 bytes), never reached

@ ----------------------------------------------------------------------------
@ dir_read_entry - reads the next directory entry of directory object r0 into record r1
@ (a null r1 rewinds with dir_set_offset 08033e94 (r0, 0)).
@ Returns 9 for an invalid object. Calls dir_read_next_entry_with_long_name (08032de4); a
@   result of 4 counts as success with an empty name at r1+0x16 (end of directory), other
@   nonzero results are returned.
@ When a long name exists (r0[0xb] != -1) the UTF-16 characters at base[3] are converted
@   with character_code_to_byte (08035908) into bytes at r1+0x16 (a surrogate pair is
@   passed as one value, first unit in the high half; the name is emptied when a 256th
@   byte would be written, when 08035908 returns 0, or when a surrogate's second unit is
@   0).
@ The short entry is always converted into r1+9 (spaces dropped, '.' inserted before the
@   first extension character when the byte at index 8 is not a space, byte 5 maps to
@   0xe5, terminating 0). When r1+0x16 is still empty it is filled from that string with
@   'A'..'Z' turned to lowercase by the case flag byte entry+0xc (bit 3 mask 8 for the
@   base, bit 4 mask 0x10 after the '.'); an empty string becomes "?" at r1+0x16. In both
@   of those cases r1+9 is then cleared when the whole byte entry+0xc is 0.
@ Copies attribute & 0x3f to r1+8, size entry+0x1c to r1[0], entry+0x16 to r1+6 and
@   entry+0x18 to r1+4. Then advances obj[4] by 0x20 (limit 0x1fffff, past it sets
@   obj[6] = 0), following allocation_table_read (08036f18) at cluster boundaries (< 2
@   gives 2, 0xffffffff gives 1).
@ Returns 0, 1 or 2.
@ ----------------------------------------------------------------------------
	.section .text.dir_read_entry,"ax",%progbits
	.global dir_read_entry
	.thumb_func
	.type dir_read_entry, %function
dir_read_entry:
	push.w {r4, r5, r6, r7, r8, r9, lr}
	sub sp, #0x4
	cbz r0, .L08034f5c
	mov r4, r0
	ldr r0, [r0, #0x0]
	cbz r0, .L08034f5c
	mov r5, r1
	ldrb r1, [r0, #0x0]
	cbz r1, .L08034f5c
	ldrh r1, [r4, #0x4]
	ldrh r2, [r0, #0x6]
	cmp r1, r2
	bne.n .L08034f5c
	ldrb r0, [r0, #0x1]
	subs r0, #0x1
	cmp r0, #0x2
	bhi.n .L08034f5c
	cbz r5, .L08034f64
	mov r0, r4
	bl dir_read_next_entry_with_long_name
	mov r1, r0
	subs r0, #0x4
	it ne
	movne r0, r1
	cbz r0, .L08034f72
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L08034f5c:
	movs r0, #0x9
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L08034f64:
	mov r0, r4
	movs r1, #0x0
	bl dir_set_offset
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L08034f72:
	movs r0, #0x0
	ldr.w r9, [r4, #0x0]
	strb r0, [r5, #0x16]
	ldr r0, [r4, #0x18]
	cmp r0, #0x0
	beq.w .L08035084
	ldr r0, [r4, #0x2c]
	adds r0, #0x1
	beq.n .L08034fe4
	add.w r8, r5, #0x16
	movs r7, #0x0
	movs r1, #0x0
	b.n .L08034f9a
.L08034f92:
	strb.w r0, [r8, r7]
	adds r7, #0x1
	mov r1, r6
.L08034f9a:
	ldr.w r2, [r9, #0xc]
	ldrh.w r0, [r2, r1, lsl #0x1]
	cmp r0, #0x0
	beq.w .L080350f8
	and r3, r0, #0xf800
	cmp.w r3, #0xd800
	add.w r6, r1, #0x1
	bne.n .L08034fc8
	ldrh.w r2, [r2, r6, lsl #0x1]
	cmp r2, #0x0
	beq.w .L0803511a
	adds r6, r1, #0x2
	mov r1, r0
	mov r0, r2
	b.n .L08034fca
.L08034fc8:
	movs r1, #0x0
.L08034fca:
	orr.w r0, r0, r1, lsl #0x10
	bl character_code_to_byte
	cmp r7, #0xff
	mov.w r1, #0x0
	it ne
	cmpne r0, #0x0
	bne.n .L08034f92
.L08034fde:
	adds r0, r5, r1
	movs r1, #0x0
	strb r1, [r0, #0x16]
.L08034fe4:
	movs r0, #0x0
	movs r1, #0x2e
	movs r7, #0x0
.L08034fea:
	mov r6, r7
	mov r2, r7
	cmp r7, #0xb
	it ls
	movls r6, #0xb
.L08034ff4:
	cmp r6, r2
	beq.n .L08035020
	ldr r3, [r4, #0x1c]
	adds r7, r2, #0x1
	ldrb r3, [r3, r2]
	mov r2, r7
	cmp r3, #0x20
	beq.n .L08034ff4
	cmp r3, #0x5
	it eq
	moveq r3, #0xe5
	cmp r0, #0xb
	it ls
	cmpls r7, #0x9
	ittt eq
	addeq r2, r5, r0
	addeq r0, #0x1
	strbeq r1, [r2, #0x9]
	adds r2, r5, r0
	adds r0, #0x1
	strb r3, [r2, #0x9]
	b.n .L08034fea
.L08035020:
	adds r1, r5, r0
	movs r2, #0x0
	strb r2, [r1, #0x9]
	ldrb r1, [r5, #0x16]
	cbnz r1, .L0803506e
	cbz r0, .L08035058
	movs r0, #0x0
	movs r1, #0x8
	b.n .L0803503a
.L08035032:
	movs r3, #0x2e
	movs r1, #0x10
.L08035036:
	strb r3, [r2, #0x16]
	adds r0, #0x1
.L0803503a:
	adds r2, r5, r0
	ldrb r3, [r2, #0x9]
	cmp r3, #0x2e
	beq.n .L08035032
	cbz r3, .L0803505e
	sub.w r7, r3, #0x41
	cmp r7, #0x19
	bhi.n .L08035036
	ldr r7, [r4, #0x1c]
	ldrb r7, [r7, #0xc]
	tst r7, r1
	it ne
	addne r3, #0x20
	b.n .L08035036
.L08035058:
	movs r0, #0x3f
	strb r0, [r5, #0x16]
	movs r0, #0x1
.L0803505e:
	adds r1, r5, r0
	movs r0, #0x0
	strb r0, [r1, #0x16]
	ldr r1, [r4, #0x1c]
	ldrb r1, [r1, #0xc]
	cmp r1, #0x0
	it eq
	strbeq r0, [r5, #0x9]
.L0803506e:
	ldr r0, [r4, #0x1c]
	ldrb r1, [r0, #0xb]
	and r1, r1, #0x3f
	strb r1, [r5, #0x8]
	ldr r1, [r0, #0x1c]
	str r1, [r5, #0x0]
	ldrh r1, [r0, #0x16]
	strh r1, [r5, #0x6]
	ldrh r0, [r0, #0x18]
	strh r0, [r5, #0x4]
.L08035084:
	ldr r1, [r4, #0x10]
	movw r0, #0xffff
	movt r0, #0xf
	add.w r6, r1, #0x20
	add.w r1, r0, #0x100000
	cmp r6, r1
	bls.n .L080350a4
.L0803509a:
	movs r0, #0x0
	str r0, [r4, #0x18]
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L080350a4:
	ldr r2, [r4, #0x18]
	cbz r2, .L080350c2
	mov r7, r6
	ldr r5, [r4, #0x0]
	bfc r7, #0xc, #0x14
	cbz r7, .L080350ca
.L080350b2:
	adds r0, r5, r7
	adds r0, #0x34
	str r0, [r4, #0x1c]
	movs r0, #0x0
	str r6, [r4, #0x10]
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L080350c2:
	movs r0, #0x0
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L080350ca:
	ldr r1, [r4, #0x14]
	adds r2, #0x1
	str r2, [r4, #0x18]
	cbz r1, .L080350ee
	ldrh r2, [r5, #0xa]
	add r0, r2
	tst.w r0, r6, lsr #0xc
	bne.n .L080350b2
	mov r0, r5
	bl allocation_table_read
	cmp r0, #0x2
	bcs.n .L080350fc
	movs r0, #0x2
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L080350ee:
	ldrh r0, [r5, #0x8]
	cmp.w r0, r6, lsr #0x5
	bhi.n .L080350b2
	b.n .L0803509a
.L080350f8:
	mov r1, r7
	b.n .L08034fde
.L080350fc:
	adds r1, r0, #0x1
	beq.n .L0803511e
	ldr r1, [r5, #0x18]
	cmp r0, r1
	bcs.n .L0803509a
	subs r2, r0, #0x2
	subs r1, #0x2
	cmp r2, r1
	str r0, [r4, #0x14]
	bcs.n .L08035126
	ldr r0, [r5, #0x2c]
	ldrh r1, [r5, #0xa]
	mla r0, r2, r1, r0
	b.n .L08035128
.L0803511a:
	movs r1, #0x0
	b.n .L08034fde
.L0803511e:
	movs r0, #0x1
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L08035126:
	movs r0, #0x0
.L08035128:
	str r0, [r4, #0x18]
	b.n .L080350b2
