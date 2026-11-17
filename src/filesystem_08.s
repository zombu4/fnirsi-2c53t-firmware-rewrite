@ filesystem_08.s - path_delete (delete a file or empty directory) and file_write (write bytes to an open file)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ path_delete - deletes the directory entry of the path at 0x20008360 (text at
@ that address), i.e. deletes a file or an empty directory. No return value.
@ Resolves the path with mount_fat_volume(&path, &base, 2) (0803a7a0) and
@ path_resolve (080366d8); requires result 0, flag byte iterator+0x2b bit 7 clear
@ and entry attribute bit 0 clear. Reads the first cluster from the entry (+0x1a,
@ plus +0x14/+0x15 as the high half when base byte 0 == 3).
@ When the entry attribute has bit 0x10 (directory) it first walks the entries of
@ that directory with dir_read_next_entry_with_long_name (08032de4) and returns
@ without deleting unless the result is 4 (empty).
@ Marks the short entry and, when iterator[0xb] != -1, the preceding long-name
@ entries from offset iterator[0xb] up to the short entry with 0xe5 as first byte
@ (windows loaded with serial_device_read 08036048, written back with
@ serial_device_write_merge 0803616c, dirty flag base[3] = 1).
@ The cluster chain loop (entered by the jump at 0x0803544e) follows the chain with
@ allocation_table_read (08036f18) and frees each cluster with fat_set_entry
@ (0803c86c), updating base+0x14 (free count, below base[0x18]-2) and base[4] |= 1.
@ First cluster 1 or >= word base+0x18 stops without freeing; with first cluster 0
@ only the flush follows. Per step the next value is read first: 0xffffffff returns
@ without fat_sync_volume, 0 jumps to fat_sync_volume without freeing the current
@ cluster, 1 returns, a value >= word base+0x18 frees the current cluster and then
@ jumps to fat_sync_volume. Finishes with fat_sync_volume(base) (0803d934).
@ ----------------------------------------------------------------------------
	.section .text.path_delete,"ax",%progbits
	.global path_delete
	.thumb_func
	.type path_delete, %function
path_delete:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x7c
	movw r0, #0x8360
	movt r0, #0x2000
	str r0, [sp, #0x78]
	add r0, sp, #0x78
	add r1, sp, #0x14
	movs r2, #0x2
	bl mount_fat_volume
	cbnz r0, .L08035156
	ldr r4, [sp, #0x14]
	ldr r1, [sp, #0x78]
	add r0, sp, #0x48
	str r4, [sp, #0x48]
	bl path_resolve
	cbz r0, .L0803515c
.L08035156:
	add sp, #0x7c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803515c:
	ldrsb.w r0, [sp, #0x73]
	cmp r0, #0x0
	bmi.n .L08035156
	ldrb.w r1, [sp, #0x4e]
	ands.w r0, r1, #0x1
	bne.n .L08035156
	ldr.w r9, [sp, #0x64]
	ldrb r0, [r4, #0x0]
	ldrh.w r7, [r9, #0x1a]
	cmp r0, #0x3
	bne.n .L0803518c
	ldrb.w r2, [r9, #0x14]
	ldrb.w r3, [r9, #0x15]
	orr.w r2, r7, r2, lsl #0x10
	orr.w r7, r2, r3, lsl #0x18
.L0803518c:
	lsls r1, r1, #0x1b
	str r7, [sp, #0x8]
	bmi.n .L080351e2
.L08035192:
	ldr.w r11, [sp, #0x74]
	ldr r6, [sp, #0x48]
	ldr r2, [sp, #0x58]
	adds.w r0, r11, #0x1
	str r2, [sp, #0xc]
	beq.n .L08035214
	movs r0, #0x1f
	movt r0, #0xffe0
	tst.w r11, r0
	bne.n .L08035156
	ldr.w r10, [sp, #0x50]
	str.w r11, [sp, #0x58]
	cmp.w r10, #0x0
	beq.w .L08035490
.L080351be:
	ldrh r0, [r6, #0xa]
	cmp.w r11, r0, lsl #0xc
	bcs.w .L080354d0
	ldr r0, [r6, #0x18]
	mov r5, r11
.L080351cc:
	sub.w r1, r10, #0x2
	subs r0, #0x2
	cmp r1, r0
	bcs.w .L080354fa
	ldr r0, [r6, #0x2c]
	ldrh r2, [r6, #0xa]
	mla r0, r1, r2, r0
	b.n .L080354b4
.L080351e2:
	ldr r2, [sp, #0x8]
	movs r1, #0x0
	str r1, [sp, #0x28]
	cmp r2, #0x0
	mov r1, r2
	str r4, [sp, #0x18]
	str r2, [sp, #0x20]
	beq.w .L080353a4
.L080351f4:
	ldrh r0, [r4, #0xa]
	cmp r0, #0x0
	beq.w .L080353e4
	ldr r0, [r4, #0x18]
	movs r5, #0x0
.L08035200:
	subs r2, r1, #0x2
	subs r0, #0x2
	cmp r2, r0
	bcs.w .L08035408
	ldr r0, [r4, #0x2c]
	ldrh r3, [r4, #0xa]
	mla r0, r2, r3, r0
	b.n .L080353be
.L08035214:
	ldrd r10, r8, [sp, #0x5c]
	mov r11, r2
.L0803521a:
	add.w r0, r6, #0x34
	str r0, [sp, #0x10]
	add.w r0, r11, #0x20
	lsrs r3, r0, #0x5
	b.n .L08035238
.L08035228:
	mov r0, r10
.L0803522a:
	add.w r1, r6, r9
	add.w r9, r1, #0x34
	adds r3, #0x1
	mov r10, r0
	mov r11, r5
.L08035238:
	ldr r5, [r6, #0x30]
	cmp r5, r8
	beq.n .L08035306
	ldrb r0, [r6, #0x3]
	cmp r0, #0x0
	beq.n .L080352c8
	ldrb r0, [r6, #0x1]
	cmp r0, #0x3
	beq.n .L08035260
	cmp r0, #0x2
	bne.w .L0803551a
	mov r7, r3
	nop.w
	mov.w r0, #0x200000
	add.w r5, r0, r5, lsl #0xc
	b.n .L08035268
.L08035260:
	mov r7, r3
	nop.w
	lsls r5, r5, #0xc
.L08035268:
	nop.w
	ldr r0, [sp, #0x10]
	mov r1, r5
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r0, [r6, #0x24]
	ldr r1, [r6, #0x30]
	ldr r2, [r6, #0x1c]
	subs r0, r1, r0
	cmp r0, r2
	mov.w r0, #0x0
	mov r3, r7
	strb r0, [r6, #0x3]
	bcs.n .L080352c8
	ldrb r0, [r6, #0x2]
	cmp r0, #0x2
	bne.n .L080352c8
	ldrb r0, [r6, #0x1]
	adds r5, r2, r1
	cmp r0, #0x3
	beq.n .L080352ae
	cmp r0, #0x2
	bne.n .L080352ca
	mov r7, r3
	nop.w
	mov.w r0, #0x200000
	add.w r5, r0, r5, lsl #0xc
	b.n .L080352b6
.L080352ae:
	mov r7, r3
	nop.w
	lsls r5, r5, #0xc
.L080352b6:
	nop.w
	ldr r0, [sp, #0x10]
	mov r1, r5
	mov.w r2, #0x1000
	bl serial_device_write_merge
	mov r3, r7
.L080352c8:
	ldrb r0, [r6, #0x1]
.L080352ca:
	cmp r0, #0x3
	beq.n .L080352e4
	cmp r0, #0x2
	bne.w .L08035510
	mov r7, r3
	nop.w
	mov.w r0, #0x200000
	add.w r5, r0, r8, lsl #0xc
	b.n .L080352ee
.L080352e4:
	mov r7, r3
	nop.w
	lsl.w r5, r8, #0xc
.L080352ee:
	nop.w
	ldr r0, [sp, #0x10]
	mov r1, r5
	mov.w r2, #0x1000
	bl serial_device_read
	ldr r2, [sp, #0xc]
	mov r3, r7
	str.w r8, [r6, #0x30]
.L08035306:
	movs r0, #0xe5
	strb.w r0, [r9, #0x0]
	cmp r11, r2
	mov.w r0, #0x1
	strb r0, [r6, #0x3]
	bcs.n .L08035410
	movw r0, #0xffff
	movt r0, #0xf
	add.w r5, r11, #0x20
	add.w r0, r0, #0x100000
	cmp r5, r0
	bhi.w .L08035434
	cmp.w r8, #0x0
	beq.w .L08035442
	mov r7, r9
	mov r9, r5
	bfc r9, #0xc, #0x14
	cmp.w r9, #0x0
	bne.w .L08035228
	cmp.w r10, #0x0
	add.w r8, r8, #0x1
	beq.n .L0803538e
	ldrh r0, [r6, #0xa]
	movw r1, #0xffff
	movt r1, #0xf
	add r0, r1
	tst.w r0, r5, lsr #0xc
	bne.w .L08035228
	mov r0, r6
	mov r1, r10
	str r3, [sp, #0x4]
	bl allocation_table_read
	adds r1, r0, #0x1
	cmp r1, #0x3
	bcc.w .L08035518
	ldr r1, [r6, #0x18]
	cmp r0, r1
	bcs.w .L08035528
	subs r2, r0, #0x2
	subs r1, #0x2
	cmp r2, r1
	bcs.n .L0803539a
	ldr r1, [r6, #0x2c]
	ldrh r3, [r6, #0xa]
	mla r8, r2, r3, r1
	b.n .L0803539e
.L0803538e:
	ldrh r0, [r6, #0x8]
	cmp r3, r0
	bcs.w .L08035528
	movs r0, #0x0
	b.n .L0803522a
.L0803539a:
	mov.w r8, #0x0
.L0803539e:
	ldr r2, [sp, #0xc]
	ldr r3, [sp, #0x4]
	b.n .L0803522a
.L080353a4:
	cmp r0, #0x3
	bcc.n .L080353b0
	ldr r1, [r4, #0x28]
	cmp r1, #0x0
	bne.w .L080351f4
.L080353b0:
	ldrh r0, [r4, #0x8]
	cmp r0, #0x0
	beq.w .L08035156
	ldr r0, [r4, #0x28]
	movs r5, #0x0
	movs r1, #0x0
.L080353be:
	cmp r0, #0x0
	str r1, [sp, #0x2c]
	beq.w .L08035156
	add.w r0, r0, r5, lsr #0xc
	bfc r5, #0xc, #0x14
	str r0, [sp, #0x30]
	adds r0, r4, r5
	adds r0, #0x34
	str r0, [sp, #0x34]
	add r0, sp, #0x18
	bl dir_read_next_entry_with_long_name
	cmp r0, #0x4
	beq.w .L08035192
	b.n .L08035156
.L080353e4:
	lsls r6, r0, #0xc
	movs r5, #0x0
.L080353e8:
	mov r0, r4
	bl allocation_table_read
	mov r1, r0
	adds r0, #0x1
	cmp r0, #0x3
	bcc.w .L08035156
	ldr r0, [r4, #0x18]
	cmp r1, r0
	bcs.w .L08035156
	subs r5, r5, r6
	cmp r5, r6
	bcs.n .L080353e8
	b.n .L08035200
.L08035408:
	str r1, [sp, #0x2c]
	add sp, #0x7c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08035410:
	ldr r0, [sp, #0x8]
	str.w r8, [sp, #0x60]
	cmp r0, #0x0
	str.w r9, [sp, #0x64]
	beq.n .L08035504
	cmp r0, #0x1
	beq.w .L08035156
	ldr r5, [sp, #0x48]
	ldr r1, [sp, #0x8]
	ldr r0, [r5, #0x18]
	cmp r0, r1
	bls.w .L08035156
	ldr r1, [sp, #0x8]
	b.n .L0803544e
.L08035434:
	strd r8, r9, [sp, #0x60]
.L08035438:
	str.w r11, [sp, #0x58]
	add sp, #0x7c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08035442:
	mov.w r8, #0x0
	b.n .L0803551a
.L08035448:
	cmp r6, r0
	mov r1, r6
	bcs.n .L08035504
.L0803544e:
	mov r0, r5
	mov r7, r1
	bl allocation_table_read
	mov r6, r0
	adds r0, #0x1
	beq.w .L08035156
	cmp r6, #0x0
	beq.n .L08035504
	cmp r6, #0x1
	beq.w .L08035156
	mov r0, r5
	mov r1, r7
	movs r2, #0x0
	bl fat_set_entry
	cmp r0, #0x0
	bne.w .L08035156
	ldrd r1, r0, [r5, #0x14]
	subs r2, r0, #0x2
	cmp r1, r2
	bcs.n .L08035448
	ldrb r2, [r5, #0x4]
	adds r1, #0x1
	str r1, [r5, #0x14]
	orr.w r1, r2, #0x1
	strb r1, [r5, #0x4]
	b.n .L08035448
.L08035490:
	ldrb r0, [r6, #0x0]
	cmp r0, #0x3
	bcc.n .L080354a2
	ldr.w r10, [r6, #0x28]
	cmp.w r10, #0x0
	bne.w .L080351be
.L080354a2:
	ldrh r0, [r6, #0x8]
	cmp.w r0, r11, lsr #0x5
	bls.w .L08035156
	ldr r0, [r6, #0x28]
	mov.w r10, #0x0
	mov r5, r11
.L080354b4:
	cmp r0, #0x0
	str.w r10, [sp, #0x5c]
	beq.w .L08035156
	add.w r8, r0, r5, lsr #0xc
	bfc r5, #0xc, #0x14
	adds r0, r6, r5
	ldr r2, [sp, #0xc]
	add.w r9, r0, #0x34
	b.n .L0803521a
.L080354d0:
	lsl.w r8, r0, #0xc
	mov r5, r11
.L080354d6:
	mov r0, r6
	mov r1, r10
	bl allocation_table_read
	mov r10, r0
	adds r0, #0x1
	cmp r0, #0x3
	bcc.w .L08035156
	ldr r0, [r6, #0x18]
	cmp r10, r0
	bcs.w .L08035156
	sub.w r5, r5, r8
	cmp r5, r8
	bcs.n .L080354d6
	b.n .L080351cc
.L080354fa:
	str.w r10, [sp, #0x5c]
	add sp, #0x7c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08035504:
	mov r0, r4
	bl fat_sync_volume
	add sp, #0x7c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08035510:
	mov.w r0, #0xffffffff
	str r0, [r6, #0x30]
	b.n .L0803551a
.L08035518:
	mov r9, r7
.L0803551a:
	strd r8, r9, [sp, #0x60]
	strd r11, r10, [sp, #0x58]
	add sp, #0x7c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08035528:
	strd r8, r7, [sp, #0x60]
	b.n .L08035438
	.short 0x0000	@ padding (2 bytes of 0x00): never reached, aligns file_write to 4 bytes

@ ----------------------------------------------------------------------------
@ file_write - writes up to r2 bytes from buffer r1 into file object r0 and stores
@ the count written in *r3. Returns 0 on success, 1 on failure, 2 on bad chain
@ (errors 1 and 2 are also stored at obj+0x11); 9 for an invalid object; obj byte
@ 0x11 when nonzero; 7 when obj byte 0x10 bit 1 is clear.
@ r2 is limited to 0xffffffff minus the position obj[5]. Allocates a cluster with
@ next_or_allocate_cluster (080312d4) when the chain ends (result 0xffffffff gives
@ 1, 0 stops, 1 gives 2), looks clusters up in the table at obj[10] when present,
@ flushes a dirty window (flag bit 0x80) with serial_device_write_merge (0803616c),
@ loads a partly overwritten sector with serial_device_read (08036048), writes
@ whole 0x1000-byte units with write_sector_run (08033f38, up to the cluster end)
@ and partial data into window obj+0x2c with copy_bytes_forward (080087a6; flag
@ obj byte 0x10 |= 0x80). Updates obj[5], size obj[3] (raised to the position) and
@ sets flag bit 0x40. Purpose: writes bytes to an open file.
@ ----------------------------------------------------------------------------
	.section .text.file_write,"ax",%progbits
	.global file_write
	.thumb_func
	.type file_write, %function
file_write:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x4
	mov r4, r0
	movs r0, #0x0
	str r0, [r3, #0x0]
	cbz r4, .L0803556e
	ldr.w r8, [r4, #0x0]
	cmp.w r8, #0x0
	beq.n .L0803556e
	ldrb.w r0, [r8, #0x0]
	cbz r0, .L0803556e
	mov r11, r1
	ldrh r0, [r4, #0x4]
	ldrh.w r1, [r8, #0x6]
	cmp r0, r1
	bne.n .L0803556e
	ldrb.w r0, [r8, #0x1]
	subs r0, #0x1
	cmp r0, #0x2
	bhi.n .L0803556e
	ldrb r0, [r4, #0x11]
	cbz r0, .L08035576
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803556e:
	movs r0, #0x9
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08035576:
	ldrb r0, [r4, #0x10]
	lsls r0, r0, #0x1e
	bmi.n .L08035584
	movs r0, #0x7
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08035584:
	ldr r0, [r4, #0x14]
	mov r6, r2
	mvns r1, r0
	cmp r1, r2
	it cc
	movcc r6, r1
	cmp r6, #0x0
	beq.w .L0803579e
	mov r5, r3
	add.w r1, r4, #0x2c
	mov.w r10, #0x0
	str r1, [sp, #0x0]
	b.n .L08035604
.L080355a4:
	nop.w
	lsl.w r7, r9, #0xc
.L080355ac:
	nop.w
	ldr r0, [sp, #0x0]
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_read
.L080355bc:
	ldr r1, [r4, #0x14]
	str.w r9, [r4, #0x1c]
	bfc r1, #0xc, #0x14
.L080355c6:
	rsb.w r7, r1, #0x1000
	adds r0, r4, r1
	cmp r7, r6
	it hi
	movhi r7, r6
	adds r0, #0x2c
	mov r1, r11
	mov r2, r7
	bl copy_bytes_forward
	ldrb r0, [r4, #0x10]
	orr.w r0, r0, #0x80
	strb r0, [r4, #0x10]
.L080355e4:
	ldr r0, [r5, #0x0]
	subs r6, r6, r7
	add r0, r7
	str r0, [r5, #0x0]
	ldr r0, [r4, #0x14]
	ldr r1, [r4, #0xc]
	add r0, r7
	cmp r0, r1
	add r11, r7
	str r0, [r4, #0x14]
	it hi
	movhi r1, r0
	cmp r6, #0x0
	str r1, [r4, #0xc]
	beq.w .L0803579e
.L08035604:
	mov r1, r0
	bfc r1, #0xc, #0x14
	cmp r1, #0x0
	bne.n .L080355c6
	ldrh.w r1, [r8, #0xa]
	subs r1, #0x1
	and.w r7, r1, r0, lsr #0xc
	cmp r7, #0x0
	bne.n .L080356b6
	cbz r0, .L08035676
	ldr r1, [r4, #0x28]
	cbz r1, .L08035680
	ldr r2, [r1, #0x4]
	cmp r2, #0x0
	beq.w .L0803579e
	ldr r3, [r4, #0x0]
	lsrs r0, r0, #0xc
	ldrh r3, [r3, #0xa]
	adds r1, #0x24
	udiv r0, r0, r3
.L08035636:
	cmp r0, r2
	bcc.n .L0803568a
	ldr.w r3, [r1, #-0x18]
	cmp r3, #0x0
	beq.w .L0803579e
	subs r0, r0, r2
	cmp r0, r3
	bcc.n .L0803568e
	ldr.w r2, [r1, #-0x10]
	cmp r2, #0x0
	beq.w .L0803579e
	subs r0, r0, r3
	cmp r0, r2
	bcc.n .L08035692
	ldr.w r3, [r1, #-0x8]
	cmp r3, #0x0
	beq.w .L0803579e
	subs r0, r0, r2
	cmp r0, r3
	bcc.n .L08035696
	ldr.w r2, [r1], #0x20
	subs r0, r0, r3
	cmp r2, #0x0
	bne.n .L08035636
	b.n .L0803579e
.L08035676:
	ldr r0, [r4, #0x8]
	cbnz r0, .L0803569c
	mov r0, r4
	movs r1, #0x0
	b.n .L08035684
.L08035680:
	ldr r1, [r4, #0x18]
	mov r0, r4
.L08035684:
	bl next_or_allocate_cluster
	b.n .L0803569c
.L0803568a:
	subs r1, #0x1c
	b.n .L08035698
.L0803568e:
	subs r1, #0x14
	b.n .L08035698
.L08035692:
	subs r1, #0xc
	b.n .L08035698
.L08035696:
	subs r1, #0x4
.L08035698:
	ldr r1, [r1, #0x0]
	add r0, r1
.L0803569c:
	adds r1, r0, #0x1
	beq.w .L080357b2
	cmp r0, #0x0
	beq.n .L0803579e
	cmp r0, #0x1
	beq.w .L080357ae
	ldr r1, [r4, #0x8]
	str r0, [r4, #0x18]
	cmp r1, #0x0
	it eq
	streq r0, [r4, #0x8]
.L080356b6:
	ldrsb.w r0, [r4, #0x10]
	cmp.w r0, #0xffffffff
	bgt.n .L080356fe
	ldrb.w r0, [r8, #0x1]
	mov r9, r7
	ldr r7, [r4, #0x1c]
	cmp r0, #0x3
	beq.n .L080356de
	cmp r0, #0x2
	bne.n .L080357b2
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L080356e4
.L080356de:
	nop.w
	lsls r7, r7, #0xc
.L080356e4:
	nop.w
	ldr r0, [sp, #0x0]
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldrb r0, [r4, #0x10]
	mov r7, r9
	and.w r0, r0, #0x7f
	strb r0, [r4, #0x10]
.L080356fe:
	ldr r0, [r4, #0x18]
	ldr.w r1, [r8, #0x18]
	subs r0, #0x2
	subs r1, #0x2
	cmp r0, r1
	bcs.n .L080357ae
	ldr.w r2, [r8, #0x2c]
	ldrh.w r1, [r8, #0xa]
	mla r0, r0, r1, r2
	cmp r0, #0x0
	beq.n .L080357ae
	cmp.w r10, r6, lsr #0xc
	add.w r9, r0, r7
	beq.n .L08035770
	lsr.w r10, r6, #0xc
	add.w r0, r7, r10
	cmp r0, r1
	ldrb.w r0, [r8, #0x1]
	it hi
	subhi.w r10, r1, r7
	mov r1, r11
	mov r2, r9
	mov r3, r10
	bl write_sector_run
	cbnz r0, .L080357b2
	ldr r0, [r4, #0x1c]
	sub.w r0, r0, r9
	cmp r0, r10
	bcs.n .L08035766
	add.w r1, r11, r0, lsl #0xc
	ldr r0, [sp, #0x0]
	mov.w r2, #0x1000
	bl copy_bytes_forward
	ldrb r0, [r4, #0x10]
	and.w r0, r0, #0x7f
	strb r0, [r4, #0x10]
.L08035766:
	lsl.w r7, r10, #0xc
	mov.w r10, #0x0
	b.n .L080355e4
.L08035770:
	ldr r0, [r4, #0x1c]
	cmp r0, r9
	beq.w .L080355bc
	ldr r0, [r4, #0xc]
	ldr r1, [r4, #0x14]
	cmp r1, r0
	bcs.w .L080355bc
	ldrb.w r0, [r8, #0x1]
	cmp r0, #0x3
	beq.w .L080355a4
	cmp r0, #0x2
	bne.n .L080357b2
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r9, lsl #0xc
	b.n .L080355ac
.L0803579e:
	ldrb r0, [r4, #0x10]
	orr.w r0, r0, #0x40
	strb r0, [r4, #0x10]
	movs r0, #0x0
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080357ae:
	movs r0, #0x2
	b.n .L080357b4
.L080357b2:
	movs r0, #0x1
.L080357b4:
	strb r0, [r4, #0x11]
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}

@ ----------------------------------------------------------------------------
@ filesystem_startup_setup - start-up file system setup, no parameters, no return
@ value. Allocates four buffers with alloc_units_of_32_bytes (0803acfc) of sizes
@ 0x1000, 1, 0x30 and 0x102c (kept at [sp,#0xc], [sp,#0x8], [sp,#0x4], [sp,#0x0]).
@ Registers drive "2:" with drive_mount (0803480c)(0x20002da8, "2:") and, if the
@ result is 0x0d, retries with drive_unmount (08034774)("2:"). When
@ dir_open (08034c40)(dir, "2:/") returns 0 it calls dir_create (08034534) for
@ "2:/LOGO", "2:/Screenshot file" and "2:/Screenshot simple file" and then
@ fn_08033fbc (08033fbc). Registers "3:" the same way with buffer 0x20003ddc (with
@ the same 0x0d retry), and when dir_open(dir, "3:/") returns 0 calls dir_create
@ for "3:/System file" only. Then in every case it opens "3:/System file/9999.bin"
@ with file_open (080348b8)(..., 0): on success writes 0 to 0x20001066 and closes
@ with file_close (08034014), otherwise writes 1 to 0x20001066. Frees the four
@ buffers with free_units_of_32_bytes (0803acbc).
@ ----------------------------------------------------------------------------
	.section .text.filesystem_startup_setup,"ax",%progbits
	.global filesystem_startup_setup
	.thumb_func
	.type filesystem_startup_setup, %function
filesystem_startup_setup:
	push {r7, lr}
	sub sp, #0x10
	mov.w r0, #0x1000
	bl alloc_units_of_32_bytes
	str r0, [sp, #0xc]
	movs r0, #0x1
	bl alloc_units_of_32_bytes
	str r0, [sp, #0x8]
	movs r0, #0x30
	bl alloc_units_of_32_bytes
	str r0, [sp, #0x4]
	movw r0, #0x102c
	bl alloc_units_of_32_bytes
	str r0, [sp, #0x0]
	movw r0, #0x2da8
	movt r0, #0x2000
	movw r1, #:lower16:d_080bba1e+1
	movt r1, #:upper16:d_080bba1e+1
	bl drive_mount
	ldr r1, [sp, #0x8]
	strb r0, [r1, #0x0]
	ldr r0, [sp, #0x8]
	ldrb r0, [r0, #0x0]
	cmp r0, #0xd
	bne.n .L08035818
	b.n .L08035806
.L08035806:
	movw r0, #:lower16:d_080bba1e+1
	movt r0, #:upper16:d_080bba1e+1
	bl drive_unmount
	ldr r1, [sp, #0x8]
	strb r0, [r1, #0x0]
	b.n .L08035818
.L08035818:
	ldr r0, [sp, #0x4]
	movw r1, #:lower16:d_080bb926+1
	movt r1, #:upper16:d_080bb926+1
	bl dir_open
	cbnz r0, .L08035854
	b.n .L0803582a
.L0803582a:
	movw r0, #:lower16:d_080bbc58
	movt r0, #:upper16:d_080bbc58
	bl dir_create
	movw r0, #:lower16:d_080bc1b4
	movt r0, #:upper16:d_080bc1b4
	bl dir_create
	movw r0, #:lower16:d_080bc18a+1
	movt r0, #:upper16:d_080bc18a+1
	bl dir_create
	bl fn_08033fbc
	b.n .L08035854
.L08035854:
	movw r0, #0x3ddc
	movt r0, #0x2000
	movw r1, #:lower16:d_080bba22
	movt r1, #:upper16:d_080bba22
	bl drive_mount
	ldr r1, [sp, #0x8]
	strb r0, [r1, #0x0]
	ldr r0, [sp, #0x8]
	ldrb r0, [r0, #0x0]
	cmp r0, #0xd
	bne.n .L08035888
	b.n .L08035876
.L08035876:
	movw r0, #:lower16:d_080bba22
	movt r0, #:upper16:d_080bba22
	bl drive_unmount
	ldr r1, [sp, #0x8]
	strb r0, [r1, #0x0]
	b.n .L08035888
.L08035888:
	ldr r0, [sp, #0x4]
	movw r1, #:lower16:d_080bb92a+1
	movt r1, #:upper16:d_080bb92a+1
	bl dir_open
	cbnz r0, .L080358a8
	b.n .L0803589a
.L0803589a:
	movw r0, #:lower16:d_080bc1a4+1
	movt r0, #:upper16:d_080bc1a4+1
	bl dir_create
	b.n .L080358a8
.L080358a8:
	ldr r0, [sp, #0x0]
	movw r1, #:lower16:d_080bc840+1
	movt r1, #:upper16:d_080bc840+1
	movs r2, #0x0
	bl file_open
	ldr r1, [sp, #0x8]
	strb r0, [r1, #0x0]
	ldr r0, [sp, #0x8]
	ldrb r0, [r0, #0x0]
	cbnz r0, .L080358da
	b.n .L080358c4
.L080358c4:
	movw r0, #0xf8
	movt r0, #0x2000
	movs r1, #0x0
	strb.w r1, [r0, #0xf6e]
	ldr r0, [sp, #0x0]
	bl file_close
	b.n .L080358ea
.L080358da:
	movw r0, #0xf8
	movt r0, #0x2000
	movs r1, #0x1
	strb.w r1, [r0, #0xf6e]
	b.n .L080358ea
.L080358ea:
	ldr r0, [sp, #0xc]
	bl free_units_of_32_bytes
	ldr r0, [sp, #0x8]
	bl free_units_of_32_bytes
	ldr r0, [sp, #0x4]
	bl free_units_of_32_bytes
	ldr r0, [sp, #0x0]
	bl free_units_of_32_bytes
	add sp, #0x10
	pop {r7, pc}
	.short 0x0000	@ padding (2 bytes of 0x00): never reached, after pop {r7,pc}

@ ----------------------------------------------------------------------------
@ character_code_to_byte - maps code point r0 to a byte. Values < 0x80 are returned
@ unchanged; for r0 below 0x10000 it searches the table of 128 halfwords at
@ 0x0804bd6e (16 entries per loop pass) and returns index + 0x80 on a match.
@ Returns 0 when not found or when r0 >> 16 != 0. Purpose: converts a character
@ code to a byte of the 128-entry table at 0x0804bd6e, the reverse direction of the
@ byte-to-halfword mapping path_resolve (080366d8) reads from the same table.
@ ----------------------------------------------------------------------------
	.section .text.character_code_to_byte,"ax",%progbits
	.global character_code_to_byte
	.thumb_func
	.type character_code_to_byte, %function
character_code_to_byte:
	push {r7, lr}
	cmp r0, #0x7f
	itt ls
	uxthls r0, r0
	popls {r7, pc}
	movs r2, #0x0
	cmp.w r2, r0, lsr #0x10
	bne.n .L080359a0
	movw r12, #:lower16:d_0804bd6e
	movt r12, #:upper16:d_0804bd6e
	add.w r3, r12, #0x1e
	mov.w lr, #0x0
.L0803592a:
	ldrh.w r2, [r3, #-0x1e]
	cmp r2, r0
	beq.n .L080359fc
	add.w r2, r12, lr, lsl #0x1
	ldrh r1, [r2, #0x2]
	cmp r1, r0
	beq.n .L080359a4
	ldrh r1, [r2, #0x4]
	cmp r1, r0
	beq.n .L080359aa
	ldrh r1, [r2, #0x6]
	cmp r1, r0
	beq.n .L080359b0
	ldrh r1, [r2, #0x8]
	cmp r1, r0
	beq.n .L080359b6
	ldrh r1, [r2, #0xa]
	cmp r1, r0
	beq.n .L080359bc
	ldrh r1, [r2, #0xc]
	cmp r1, r0
	beq.n .L080359c2
	ldrh r1, [r2, #0xe]
	cmp r1, r0
	beq.n .L080359c8
	ldrh r1, [r2, #0x10]
	cmp r1, r0
	beq.n .L080359ce
	ldrh r1, [r2, #0x12]
	cmp r1, r0
	beq.n .L080359d4
	ldrh r1, [r2, #0x14]
	cmp r1, r0
	beq.n .L080359da
	ldrh r1, [r2, #0x16]
	cmp r1, r0
	beq.n .L080359e0
	ldrh r1, [r2, #0x18]
	cmp r1, r0
	beq.n .L080359e6
	ldrh r1, [r2, #0x1a]
	cmp r1, r0
	beq.n .L080359ec
	ldrh r1, [r2, #0x1c]
	cmp r1, r0
	beq.n .L080359f2
	ldrh r1, [r3, #0x0]
	cmp r1, r0
	beq.n .L080359f8
	add.w lr, lr, #0x10
	adds r3, #0x20
	cmp.w lr, #0x80
	mov.w r2, #0x0
	bne.n .L0803592a
.L080359a0:
	uxth r0, r2
	pop {r7, pc}
.L080359a4:
	add.w lr, lr, #0x1
	b.n .L080359fc
.L080359aa:
	add.w lr, lr, #0x2
	b.n .L080359fc
.L080359b0:
	add.w lr, lr, #0x3
	b.n .L080359fc
.L080359b6:
	add.w lr, lr, #0x4
	b.n .L080359fc
.L080359bc:
	add.w lr, lr, #0x5
	b.n .L080359fc
.L080359c2:
	add.w lr, lr, #0x6
	b.n .L080359fc
.L080359c8:
	add.w lr, lr, #0x7
	b.n .L080359fc
.L080359ce:
	add.w lr, lr, #0x8
	b.n .L080359fc
.L080359d4:
	add.w lr, lr, #0x9
	b.n .L080359fc
.L080359da:
	add.w lr, lr, #0xa
	b.n .L080359fc
.L080359e0:
	add.w lr, lr, #0xb
	b.n .L080359fc
.L080359e6:
	add.w lr, lr, #0xc
	b.n .L080359fc
.L080359ec:
	add.w lr, lr, #0xd
	b.n .L080359fc
.L080359f2:
	add.w lr, lr, #0xe
	b.n .L080359fc
.L080359f8:
	add.w lr, lr, #0xf
.L080359fc:
	add.w r0, lr, #0x80
	uxtb r2, r0
	uxth r0, r2
	pop {r7, pc}
	.short 0x0000	@ padding (2 bytes of 0x00): never reached, after pop {r7,pc}

@ ----------------------------------------------------------------------------
@ path_resolve - resolves a path to a directory entry. Walks path string r1
@ against directory object r0 (r0[0] = base, r0[2] = start cluster, set to 0
@ first). Skips leading '/' or '\' characters; an empty remainder (byte < 0x20)
@ sets byte r0+0x2b = 0x80 and tail-calls dir_set_offset (08033e94)(r0, 0).
@ Per path component it copies characters as halfwords into the buffer whose
@ pointer is the word at base+0xc: bytes >= 0x80 are mapped through the
@ 128-halfword table at 0x0804bd6e, a byte < 0x20 ends the component and the path
@ (marks the last component), '/' or '\' ends the component; characters < 0x80
@ that find_byte (08007794) finds in the first 9 bytes of the table at 0x08036b90
@ give return 6, names longer than 255 characters give 6.
@ Strips trailing '.' and ' ' (an empty result gives 6). Builds an 11-byte short
@ name in r0+0x20 (blanks 0x20; characters >= 0x80 through
@ character_code_to_byte (08035908) and the table 0x0804bced, characters
@ find_byte finds in "+,;=[]" and unmapped ones become '_', lowercase letters
@ become uppercase, first byte 0xe5 becomes 5). Flags (lossy conversion, mixed
@ case, case bits 0x08/0x10, last-component bit 0x04) go to byte r0+0x2b, then
@ it calls find_directory_entry_by_name (08031664)(r0) for the lookup.
@ Returns 0 when found at the last component, 4/5 when not found at the last /
@ an inner component, 6 on a bad name, otherwise the lookup error. An inner
@ component that is found must have attribute bit 0x10 (else 5); r0[2] is set to
@ its first cluster (+0x1a, +0x14/+0x15 when base byte 0 == 3) and the loop
@ continues with the rest of the path.
@ ----------------------------------------------------------------------------
	.section .text.path_resolve,"ax",%progbits
	.global path_resolve
	.thumb_func
	.type path_resolve, %function
path_resolve:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x24
	ldr.w r10, [r0, #0x0]
	mov r9, r0
	mov r5, r1
	b.n .L080366ea
.L080366e8:
	adds r5, #0x4
.L080366ea:
	ldrb r0, [r5, #0x0]
	cmp r0, #0x5c
	beq.n .L080366f4
	cmp r0, #0x2f
	bne.n .L0803671c
.L080366f4:
	ldrb r0, [r5, #0x1]
	cmp r0, #0x2f
	beq.n .L080366fe
	cmp r0, #0x5c
	bne.n .L08036716
.L080366fe:
	ldrb r0, [r5, #0x2]
	cmp r0, #0x5c
	beq.n .L08036708
	cmp r0, #0x2f
	bne.n .L0803671a
.L08036708:
	ldrb r0, [r5, #0x3]
	cmp r0, #0x5c
	beq.n .L080366e8
	cmp r0, #0x2f
	beq.n .L080366e8
	adds r5, #0x3
	b.n .L0803671c
.L08036716:
	adds r5, #0x1
	b.n .L0803671c
.L0803671a:
	adds r5, #0x2
.L0803671c:
	movs r0, #0x0
	str.w r0, [r9, #0x8]
	ldrb r0, [r5, #0x0]
	cmp r0, #0x20
	bcs.n .L0803673c
	movs r2, #0x80
	mov r0, r9
	movs r1, #0x0
	strb.w r2, [r9, #0x2b]
	add sp, #0x24
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	b.w dir_set_offset
.L0803673c:
	ldr.w r8, [r10, #0xc]
	add.w r1, r9, #0x20
	adr.w r11, .L08036b90
	str r1, [sp, #0x20]
.L0803674a:
	adds r4, r5, #0x1
	adds r5, #0x4
	movs r7, #0x0
	b.n .L0803676a
	.short 0xbf00	@ padding (bytes 00 bf): never reached, after b.n .L0803676a
.L08036754:
	cmp r7, #0xfe
	bhi.w .L08036b62
.L0803675a:
	strh.w r6, [r8, r7, lsl #0x1]
	ldrb r0, [r4, r7]
	adds r1, r7, #0x1
	adds r5, #0x1
	cmp r0, #0x0
	mov r7, r1
	beq.n .L080367f6
.L0803676a:
	sxtb r1, r0
	cmp.w r1, #0xffffffff
	ble.n .L0803677c
	uxtb r6, r0
	cmp r6, #0x20
	bcs.n .L08036792
	b.n .L080367ee
	.short 0xbf00	@ padding (bytes 00 bf): never reached, after b.n .L080367ee
.L0803677c:
	movw r1, #:lower16:d_0804bd6e
	movt r1, #:upper16:d_0804bd6e
	add.w r0, r1, r0, lsl #0x1
	mvn r1, #0xff
	ldrh r6, [r0, r1]
	cmp r6, #0x20
	bcc.n .L080367ee
.L08036792:
	cmp r6, #0x5c
	beq.n .L080367be
	cmp r6, #0x2f
	beq.n .L080367be
	cmp r6, #0x7f
	bhi.n .L08036754
	mov r0, r11
	mov r1, r6
	movs r2, #0x9
	bl find_byte
	mov r1, r0
	cmp r7, #0xfe
	mov.w r0, #0x6
	bhi.w .L08036b5c
	cmp r1, #0x0
	beq.n .L0803675a
	b.n .L08036b5c
	.short 0xbf00	@ padding (bytes 00 bf): never reached, after b.n .L08036b5c
.L080367bc:
	adds r5, #0x4
.L080367be:
	ldrb.w r0, [r5, #-0x3]
	cmp r0, #0x5c
	beq.n .L080367ca
	cmp r0, #0x2f
	bne.n .L08036800
.L080367ca:
	ldrb.w r0, [r5, #-0x2]
	cmp r0, #0x2f
	beq.n .L080367d6
	cmp r0, #0x5c
	bne.n .L08036804
.L080367d6:
	ldrb.w r0, [r5, #-0x1]
	cmp r0, #0x5c
	beq.n .L080367e2
	cmp r0, #0x2f
	bne.n .L08036808
.L080367e2:
	ldrb r0, [r5, #0x0]
	cmp r0, #0x5c
	beq.n .L080367bc
	cmp r0, #0x2f
	beq.n .L080367bc
	b.n .L0803680a
.L080367ee:
	adds r5, r4, r7
	mov.w r11, #0x4
	b.n .L08036818
.L080367f6:
	adds r5, r4, r1
	mov.w r11, #0x4
	mov r7, r1
	b.n .L0803681e
.L08036800:
	subs r5, #0x3
	b.n .L0803680a
.L08036804:
	subs r5, #0x2
	b.n .L0803680a
.L08036808:
	subs r5, #0x1
.L0803680a:
	cmp r0, #0x20
	mov.w r0, #0x0
	it cc
	movcc r0, #0x1
	lsl.w r11, r0, #0x2
.L08036818:
	cmp r7, #0x0
	beq.w .L08036b54
.L0803681e:
	add.w r0, r8, r7, lsl #0x1
	subs r0, #0x4
	b.n .L08036832
	.short 0xbf00	@ padding (bytes 00 bf): never reached, after b.n .L08036832
.L08036828:
	subs r7, #0x4
	sub.w r0, r0, #0x8
	beq.w .L08036b54
.L08036832:
	ldrh r1, [r0, #0x2]
	cmp r1, #0x2e
	beq.n .L0803683c
	cmp r1, #0x20
	bne.n .L08036872
.L0803683c:
	cmp r7, #0x1
	beq.w .L08036b54
	ldrh r1, [r0, #0x0]
	cmp r1, #0x2e
	beq.n .L0803684c
	cmp r1, #0x20
	bne.n .L08036878
.L0803684c:
	cmp r7, #0x2
	beq.w .L08036b54
	ldrh.w r1, [r0, #-0x2]
	cmp r1, #0x2e
	beq.n .L0803685e
	cmp r1, #0x20
	bne.n .L08036880
.L0803685e:
	cmp r7, #0x3
	beq.w .L08036b54
	ldrh.w r1, [r0, #-0x4]
	cmp r1, #0x2e
	beq.n .L08036828
	cmp r1, #0x20
	beq.n .L08036828
	subs r7, #0x3
.L08036872:
	str.w r10, [sp, #0xc]
	b.n .L08036886
.L08036878:
	str.w r10, [sp, #0xc]
	subs r7, #0x1
	b.n .L08036886
.L08036880:
	str.w r10, [sp, #0xc]
	subs r7, #0x2
.L08036886:
	mov.w r10, #0x0
	add.w r1, r8, #0x6
	strh.w r10, [r8, r7, lsl #0x1]
	str.w r9, [sp, #0x18]
	nop
.L08036898:
	ldrh.w r0, [r1, #-0x6]
	cmp r0, #0x20
	bne.n .L080368cc
	add.w r2, r8, r10, lsl #0x1
	ldrh r0, [r2, #0x2]
	cmp r0, #0x20
	bne.n .L080368c2
	ldrh r0, [r2, #0x4]
	cmp r0, #0x20
	bne.n .L080368c8
	ldrh.w r0, [r1], #0x8
	add.w r10, r10, #0x4
	cmp r0, #0x20
	beq.n .L08036898
	sub.w r10, r10, #0x1
	b.n .L080368cc
.L080368c2:
	add.w r10, r10, #0x1
	b.n .L080368cc
.L080368c8:
	add.w r10, r10, #0x2
.L080368cc:
	cmp r0, #0x2e
	add.w r0, r8, r7, lsl #0x1
	orr.w r1, r11, #0x3
	it eq
	moveq r11, r1
	sub.w r9, r7, #0x1
	subs r0, #0x4
	cmp.w r10, #0x0
	it ne
	movne r11, r1
.L080368e8:
	adds.w r1, r9, #0x1
	beq.n .L0803692a
	ldrh r2, [r0, #0x2]
	cmp r2, #0x2e
	beq.n .L08036930
	cmp.w r9, #0x0
	beq.n .L0803692a
	ldrh r1, [r0, #0x0]
	cmp r1, #0x2e
	beq.n .L08036938
	cmp.w r9, #0x1
	beq.n .L0803692a
	ldrh.w r1, [r0, #-0x2]
	cmp r1, #0x2e
	beq.n .L08036934
	cmp.w r9, #0x2
	beq.n .L0803692a
	ldrh.w r1, [r0, #-0x4]
	sub.w r9, r9, #0x4
	cmp r1, #0x2e
	sub.w r0, r0, #0x8
	bne.n .L080368e8
	add.w r9, r9, #0x2
	b.n .L08036938
.L0803692a:
	mov.w r9, #0x0
	b.n .L08036938
.L08036930:
	mov r9, r1
	b.n .L08036938
.L08036934:
	sub.w r9, r9, #0x1
.L08036938:
	ldr r0, [sp, #0x20]
	mov.w r1, #0x20202020
	str.w r1, [r0, #0x7]
	strd r1, r1, [r0, #0x0]
	movs r0, #0x8
	str r0, [sp, #0x10]
	movs r0, #0x0
	rsb.w r7, r9, #0x0
	add.w lr, r8, #0x4
	sub.w r4, r9, #0x1
	mov.w r12, #0x1
	movs r3, #0x0
	str r0, [sp, #0x1c]
	movs r0, #0x0
	str r0, [sp, #0x14]
.L08036964:
	add.w r0, lr, r10, lsl #0x1
	b.n .L0803696e
	.short 0xbf00	@ padding (bytes 00 bf): never reached, after b.n .L0803696e
.L0803696c:
	adds r0, #0x8
.L0803696e:
	ldrh.w r6, [r8, r10, lsl #0x1]
	cmp r6, #0x20
	beq.n .L0803697e
	cmp r6, #0x2e
	bne.n .L080369e6
	cmp r4, r10
	beq.n .L080369b8
.L0803697e:
	add.w r1, r8, r10, lsl #0x1
	ldrh r6, [r1, #0x2]
	orr.w r11, r11, #0x3
	cmp r6, #0x20
	add.w r1, r7, r10
	beq.n .L08036998
	cmp r6, #0x2e
	bne.n .L080369f0
	adds r2, r1, #0x2
	beq.n .L080369b8
.L08036998:
	ldrh r6, [r0, #0x0]
	cmp r6, #0x20
	beq.n .L080369a6
	cmp r6, #0x2e
	bne.n .L080369fa
	adds r2, r1, #0x3
	beq.n .L080369b8
.L080369a6:
	ldrh r6, [r0, #0x2]
	add.w r10, r10, #0x4
	cmp r6, #0x20
	beq.n .L0803696c
	cmp r6, #0x2e
	bne.n .L08036a04
	adds r1, #0x4
	bne.n .L0803696c
.L080369b8:
	movs r0, #0x1
	mov r10, r9
.L080369bc:
	ldr r1, [sp, #0x14]
	lsls r1, r1, #0x1f
	orr.w r1, r11, #0x3
	bne.n .L08036aa8
	cmp r0, #0x0
	it eq
	moveq r11, r1
	cmp r10, r9
	bhi.n .L08036aaa
	movs r0, #0xb
	str r0, [sp, #0x10]
	movs r0, #0x1
	str r0, [sp, #0x14]
	movs r0, #0x8
	lsls r3, r3, #0x2
	mov.w r12, #0x0
	str r0, [sp, #0x1c]
	mov r10, r9
	b.n .L08036964
.L080369e6:
	cmp r6, #0x0
	beq.n .L08036aaa
	add.w r10, r10, #0x1
	b.n .L08036a08
.L080369f0:
	cmp r6, #0x0
	beq.n .L08036aaa
	add.w r10, r10, #0x2
	b.n .L08036a08
.L080369fa:
	cmp r6, #0x0
	beq.n .L08036aaa
	add.w r10, r10, #0x3
	b.n .L08036a08
.L08036a04:
	cmp r6, #0x0
	beq.n .L08036aaa
.L08036a08:
	sub.w r0, r10, r9
	ldr r1, [sp, #0x10]
	ldr r2, [sp, #0x1c]
	clz r0, r0
	cmp r2, r1
	lsr.w r0, r0, #0x5
	bcs.n .L080369bc
	cmp r10, r9
	beq.n .L080369bc
	cmp r6, #0x80
	strd r4, lr, [sp, #0x4]
	bcc.n .L08036a56
	mov r0, r6
	str.w r12, [sp, #0x0]
	mov r4, r3
	bl character_code_to_byte
	mov r6, r0
	lsls r0, r0, #0x18
	orr.w r11, r11, #0x2
	bpl.n .L08036a4c
	movw r1, #:lower16:d_0804bcec+1
	and.w r0, r6, #0x7f
	movt r1, #:upper16:d_0804bcec+1
	ldrb r6, [r1, r0]
.L08036a4c:
	mov r3, r4
	ldr.w lr, [sp, #0x8]
	ldrd r12, r4, [sp, #0x0]
.L08036a56:
	cbz r6, .L08036a72
	adr r0, .L08036b9c
	mov r1, r6
	movs r2, #0x7
	str r3, [sp, #0x0]
	mov r4, r12
	bl find_byte
	ldr.w lr, [sp, #0x8]
	mov r12, r4
	ldrd r3, r4, [sp, #0x0]
	cbz r0, .L08036a7a
.L08036a72:
	orr.w r11, r11, #0x3
	movs r6, #0x5f
	b.n .L08036a98
.L08036a7a:
	sub.w r0, r6, #0x41
	uxth r0, r0
	cmp r0, #0x1a
	sub.w r0, r6, #0x61
	it cc
	orrcc.w r3, r3, #0x2
	uxth r0, r0
	cmp r0, #0x19
	itt ls
	orrls.w r3, r3, #0x1
	subls r6, #0x20
.L08036a98:
	ldrd r0, r1, [sp, #0x18]
	add r0, r1
	adds r1, #0x1
	strb.w r6, [r0, #0x20]
	str r1, [sp, #0x1c]
	b.n .L08036964
.L08036aa8:
	mov r11, r1
.L08036aaa:
	ldr r0, [sp, #0x20]
	ldr.w r9, [sp, #0x18]
	ldrb r0, [r0, #0x0]
	ldr.w r10, [sp, #0xc]
	cmp r0, #0xe5
	bne.n .L08036ac0
	ldr r0, [sp, #0x20]
	movs r1, #0x5
	strb r1, [r0, #0x0]
.L08036ac0:
	lsls.w r0, r12, #0x1f
	it ne
	lslne r3, r3, #0x2
	and.w r1, r3, #0x3
	and.w r0, r3, #0xc
	cmp r1, #0x3
	orr.w r2, r11, #0x2
	it eq
	moveq r11, r2
	cmp r0, #0xc
	mov.w r0, #0x10
	and.w r0, r0, r3, lsl #0x4
	and.w r1, r3, #0x4
	it eq
	moveq r11, r2
	orr.w r0, r0, r1, lsl #0x1
	lsls.w r1, r11, #0x1e
	it pl
	orrpl.w r11, r11, r0
	mov r0, r9
	strb.w r11, [r9, #0x2b]
	bl find_directory_entry_by_name
	ldrb.w r1, [r9, #0x2b]
	cbnz r0, .L08036b6a
	lsls r0, r1, #0x1d
	bmi.n .L08036b7e
	ldrb.w r0, [r9, #0x6]
	lsls r0, r0, #0x1b
	bpl.n .L08036b86
	ldr.w r0, [r9, #0x10]
	ldrb.w r2, [r10, #0x0]
	bfc r0, #0xc, #0x14
	add.w r1, r10, r0
	ldrh.w r0, [r1, #0x4e]
	cmp r2, #0x3
	bne.n .L08036b3c
	adds r1, #0x34
	ldrb r2, [r1, #0x14]
	ldrb r1, [r1, #0x15]
	orr.w r0, r0, r2, lsl #0x10
	orr.w r0, r0, r1, lsl #0x18
.L08036b3c:
	str.w r0, [r9, #0x8]
	ldr.w r1, [r9, #0x0]
	ldrb r0, [r5, #0x0]
	ldr.w r8, [r1, #0xc]
	cmp r0, #0x0
	adr.w r11, .L08036b90
	bne.w .L0803674a
.L08036b54:
	movs r0, #0x0
	strh.w r0, [r8, #0x0]
	movs r0, #0x6
.L08036b5c:
	add sp, #0x24
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08036b62:
	movs r0, #0x6
	add sp, #0x24
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08036b6a:
	cmp r0, #0x4
	bne.n .L08036b5c
	lsls r0, r1, #0x1d
	mov.w r0, #0x4
	it pl
	movpl r0, #0x5
	add sp, #0x24
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08036b7e:
	movs r0, #0x0
	add sp, #0x24
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08036b86:
	movs r0, #0x5
	add sp, #0x24
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short 0xbf00	@ padding (bytes 00 bf)
.L08036b90:
	@ 12 bytes: the characters * : < > | " ? 0x7f followed by four NUL bytes;
	@ the first 9 bytes are the forbidden-character set searched with find_byte
	.byte 0x2a, 0x3a, 0x3c, 0x3e, 0x7c, 0x22, 0x3f, 0x7f, 0x00, 0x00, 0x00, 0x00
.L08036b9c:
	.asciz "+,;=[]"	@ characters replaced by '_' in the short name
	.byte 0x00	@ padding (1 byte of 0x00): aligns the end of path_resolve to 2 bytes

