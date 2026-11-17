@ filesystem_05.s - directory iterator: read the next directory entry together with its long name.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ dir_read_next_entry_with_long_name - reads the next directory entry with its long name.
@ param_1 (r0) = pointer to the directory iterator structure (same layout as the one
@   used by 08031664): [0] = volume context, [4] = byte offset in the directory,
@   [5] = cluster, [6] = sector number, [7] = pointer to the current 32-byte entry,
@   [0xb] = offset of the first long-name entry or -1. Returns 4 when param_1[6] == 0.
@ Walks the 32-byte entries in the 0x1000-byte window at ctx+0x34 (window sector at
@   ctx+0x30). A dirty window (byte ctx+3 != 0) is written back with 0803616c
@   (serial_device_write_merge) and the flag is cleared; when byte ctx+2 == 2 and
@   window sector - word ctx+0x24 < word ctx+0x1c it is also written to
@   sector + word ctx+0x1c. The new window is loaded with 08036048 (serial_device_read)
@   and word ctx+0x30 is set to the sector. Address = sector<<12 when byte ctx+1 == 3,
@   sector*0x1000 + 0x200000 when byte ctx+1 == 2; other values return 1 (on a load also
@   ctx+0x30 = -1).
@ First byte 0 returns 4 (end). First byte 0x2e or 0xe5 or (attribute & 0x1f) == 8 is
@   skipped and the long-name state reset. The attribute byte (entry+0xb) & 0x3f is
@   stored in the byte at offset 6 of param_1.
@ Attribute 0x0f entries: a first byte with bit 6 set starts a sequence (saves the
@   checksum byte +0xd and param_1[0xb] = param_1[4]); other entries must continue the
@   count and carry the same checksum and a zero halfword at +0x1a. The thirteen UTF-16
@   characters (+1,+3,+5,+7,+9,+0xe,+0x10,+0x12,+0x14,+0x16,+0x18,+0x1c,+0x1e) go to the
@   buffer whose pointer is the word at ctx+0xc at index (first byte & 0xbf)*13 - 13
@   (limit 0x100 characters); a 0x0000 character must be followed by 0xffff padding and a
@   terminating 0 is written after the last character (+0x1e) only when that character is
@   nonzero and bit 6 of the first byte is set (index must be <= 0xfe).
@ Short entries: when the sequence is complete and the rotate-add checksum over the 11
@   name bytes equals the saved one it returns 0 with the entry at param_1[7], otherwise
@   it sets param_1[0xb] = -1 and returns 0.
@ Advances 0x20 per entry (a new offset above 0x1fffff gives 4); at a 0x1000 boundary
@   the sector is incremented; when param_1[5] == 0 it ends when offset>>5 >= ushort
@   ctx+8 (4), else when (offset>>12) & (ushort ctx+10 - 1) == 0 the next cluster comes
@   from 08036f18 (allocation_table_read)(ctx) (below 2 gives 2, 0xffffffff gives 1,
@   >= word ctx+0x18 gives 4).
@ Stores 0 in param_1[6] before returning 4, 1 or 2. Returns 0, 1, 2 or 4.
@ Purpose: reads the next directory entry with its long name (FAT-style layout proven
@   by 0xe5, attribute 0x0f, 13 characters per long entry and the rotate-add checksum).
@ ----------------------------------------------------------------------------
	.section .text.dir_read_next_entry_with_long_name,"ax",%progbits
	.global dir_read_next_entry_with_long_name
	.thumb_func
	.type dir_read_next_entry_with_long_name, %function
dir_read_next_entry_with_long_name:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x4
	ldr.w r10, [r0, #0x18]
	mov r4, r0
	cmp.w r10, #0x0
	beq.w .L0803318e
	ldr r7, [r4, #0x0]
	movs r5, #0xff
	add.w r0, r7, #0x34
	mov.w r11, #0xff
	str r0, [sp, #0x0]
	b.n .L08032e28
.L08032e08:
	ldrh r0, [r6, #0x8]
	cmp.w r0, r8, lsr #0x5
	bls.w .L0803323c
	nop
.L08032e14:
	add.w r0, r6, r9
	adds r0, #0x34
	cmp.w r10, #0x0
	str.w r8, [r4, #0x10]
	str r0, [r4, #0x1c]
	beq.w .L08033234
.L08032e28:
	ldr r6, [r7, #0x30]
	cmp r6, r10
	beq.n .L08032ee4
	ldrb r0, [r7, #0x3]
	cbz r0, .L08032eac
	ldrb r0, [r7, #0x1]
	cmp r0, #0x3
	beq.n .L08032e4c
	cmp r0, #0x2
	bne.w .L080331a4
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r6, lsl #0xc
	b.n .L08032e52
.L08032e4c:
	nop.w
	lsls r6, r6, #0xc
.L08032e52:
	nop.w
	ldr r0, [sp, #0x0]
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r0, [r7, #0x24]
	ldr r1, [r7, #0x30]
	ldr r2, [r7, #0x1c]
	subs r0, r1, r0
	cmp r0, r2
	mov.w r0, #0x0
	strb r0, [r7, #0x3]
	bcs.n .L08032eac
	ldrb r0, [r7, #0x2]
	cmp r0, #0x2
	bne.n .L08032eac
	ldrb r0, [r7, #0x1]
	adds r6, r2, r1
	cmp r0, #0x3
	beq.n .L08032e94
	cmp r0, #0x2
	bne.n .L08032eae
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r6, lsl #0xc
	b.n .L08032e9a
.L08032e94:
	nop.w
	lsls r6, r6, #0xc
.L08032e9a:
	nop.w
	ldr r0, [sp, #0x0]
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	nop
.L08032eac:
	ldrb r0, [r7, #0x1]
.L08032eae:
	cmp r0, #0x3
	beq.n .L08032ec8
	cmp r0, #0x2
	bne.w .L0803319e
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r10, lsl #0xc
	b.n .L08032ed0
	.byte 0x00, 0xbf	@ padding
.L08032ec8:
	nop.w
	lsl.w r6, r10, #0xc
.L08032ed0:
	nop.w
	ldr r0, [sp, #0x0]
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_read
	str.w r10, [r7, #0x30]
.L08032ee4:
	ldr r0, [r4, #0x1c]
	ldrb r1, [r0, #0x0]
	cmp r1, #0x0
	beq.w .L08033192
	ldrb r3, [r0, #0xb]
	cmp r1, #0x2e
	and.w r2, r3, #0x3f
	strb r2, [r4, #0x6]
	beq.w .L080330f4
	cmp r1, #0xe5
	beq.w .L080330f4
	and.w r3, r3, #0x1f
	cmp r3, #0x8
	beq.w .L080330f4
	cmp r2, #0xf
	bne.w .L080331a8
	lsls r2, r1, #0x19
	bmi.n .L08032f20
	uxtb.w r2, r11
	cmp r1, r2
	beq.n .L08032f2a
	b.n .L080330f4
.L08032f20:
	ldrb r5, [r0, #0xd]
	ldr r2, [r4, #0x10]
	and.w r11, r1, #0xbf
	str r2, [r4, #0x2c]
.L08032f2a:
	ldrb r1, [r0, #0xd]
	uxtb r2, r5
	cmp r2, r1
	bne.w .L080330f4
	ldrh r1, [r0, #0x1a]
	cmp r1, #0x0
	bne.w .L080330f4
	ldrb r1, [r0, #0x0]
	movs r2, #0xd
	and.w r1, r1, #0xbf
	mul r3, r1, r2
	sub.w r2, r3, #0xd
	cmp r2, #0xff
	bhi.w .L080330f4
	ldr.w r12, [r7, #0xc]
	ldrh.w r1, [r0, #0x1]
	strh.w r1, [r12, r2, lsl #0x1]
	ldrh.w r6, [r0, #0x3]
	sub.w r2, r3, #0xc
	cbz r1, .L08032f78
	cmp r2, #0xff
	bhi.w .L080330f4
	strh.w r6, [r12, r2, lsl #0x1]
	sub.w r2, r3, #0xb
	b.n .L08032f84
.L08032f78:
	movw r1, #0xffff
	cmp r6, r1
	bne.w .L080330f4
	movs r6, #0x0
.L08032f84:
	ldrh.w r3, [r0, #0x5]
	cbz r6, .L08032f98
	cmp r2, #0xff
	bhi.w .L080330f4
	strh.w r3, [r12, r2, lsl #0x1]
	adds r2, #0x1
	b.n .L08032fa4
.L08032f98:
	movw r1, #0xffff
	cmp r3, r1
	bne.w .L080330f4
	movs r3, #0x0
.L08032fa4:
	ldrh.w r6, [r0, #0x7]
	cbz r3, .L08032fb8
	cmp r2, #0xff
	bhi.w .L080330f4
	strh.w r6, [r12, r2, lsl #0x1]
	adds r2, #0x1
	b.n .L08032fc4
.L08032fb8:
	movw r1, #0xffff
	cmp r6, r1
	bne.w .L080330f4
	movs r6, #0x0
.L08032fc4:
	ldrh.w r3, [r0, #0x9]
	cbz r6, .L08032fd8
	cmp r2, #0xff
	bhi.w .L080330f4
	strh.w r3, [r12, r2, lsl #0x1]
	adds r2, #0x1
	b.n .L08032fe4
.L08032fd8:
	movw r1, #0xffff
	cmp r3, r1
	bne.w .L080330f4
	movs r3, #0x0
.L08032fe4:
	ldrh r6, [r0, #0xe]
	cbz r3, .L08032ffc
	cmp r2, #0xff
	bhi.w .L080330f4
	clz r1, r6
	strh.w r6, [r12, r2, lsl #0x1]
	adds r2, #0x1
	lsrs r6, r1, #0x5
	b.n .L08033006
.L08032ffc:
	movw r1, #0xffff
	cmp r6, r1
	bne.n .L080330f4
	movs r6, #0x1
.L08033006:
	ldrh r3, [r0, #0x10]
	cbz r6, .L08033016
	movw r1, #0xffff
	cmp r3, r1
	bne.n .L080330f4
	movs r6, #0x1
	b.n .L08033026
.L08033016:
	cmp r2, #0xff
	bhi.n .L080330f4
	clz r1, r3
	strh.w r3, [r12, r2, lsl #0x1]
	adds r2, #0x1
	lsrs r6, r1, #0x5
.L08033026:
	ldrh r3, [r0, #0x12]
	cbz r6, .L08033036
	movw r1, #0xffff
	cmp r3, r1
	bne.n .L080330f4
	movs r6, #0x1
	b.n .L08033046
.L08033036:
	cmp r2, #0xff
	bhi.n .L080330f4
	clz r1, r3
	strh.w r3, [r12, r2, lsl #0x1]
	adds r2, #0x1
	lsrs r6, r1, #0x5
.L08033046:
	ldrh r3, [r0, #0x14]
	cbz r6, .L08033056
	movw r1, #0xffff
	cmp r3, r1
	bne.n .L080330f4
	movs r6, #0x1
	b.n .L08033066
.L08033056:
	cmp r2, #0xff
	bhi.n .L080330f4
	clz r1, r3
	strh.w r3, [r12, r2, lsl #0x1]
	adds r2, #0x1
	lsrs r6, r1, #0x5
.L08033066:
	ldrh r3, [r0, #0x16]
	cbz r6, .L08033076
	movw r1, #0xffff
	cmp r3, r1
	bne.n .L080330f4
	movs r6, #0x1
	b.n .L08033086
.L08033076:
	cmp r2, #0xff
	bhi.n .L080330f4
	clz r1, r3
	strh.w r3, [r12, r2, lsl #0x1]
	adds r2, #0x1
	lsrs r6, r1, #0x5
.L08033086:
	ldrh r3, [r0, #0x18]
	cbz r6, .L08033096
	movw r1, #0xffff
	cmp r3, r1
	bne.n .L080330f4
	movs r6, #0x1
	b.n .L080330a6
.L08033096:
	cmp r2, #0xff
	bhi.n .L080330f4
	clz r1, r3
	strh.w r3, [r12, r2, lsl #0x1]
	adds r2, #0x1
	lsrs r6, r1, #0x5
.L080330a6:
	ldrh r3, [r0, #0x1c]
	cbz r6, .L080330b6
	movw r1, #0xffff
	cmp r3, r1
	bne.n .L080330f4
	movs r3, #0x1
	b.n .L080330c6
.L080330b6:
	cmp r2, #0xff
	bhi.n .L080330f4
	clz r1, r3
	strh.w r3, [r12, r2, lsl #0x1]
	adds r2, #0x1
	lsrs r3, r1, #0x5
.L080330c6:
	ldrh r6, [r0, #0x1e]
	cbz r3, .L080330d8
	movw r0, #0xffff
	cmp r6, r0
	bne.n .L080330f4
	sub.w r11, r11, #0x1
	b.n .L080330f8
.L080330d8:
	cmp r2, #0xff
	bhi.n .L080330f4
	cmp r6, #0x0
	strh.w r6, [r12, r2, lsl #0x1]
	mov r1, r5
	itt ne
	ldrbne r0, [r0, #0x0]
	andsne.w r0, r0, #0x40
	beq.n .L08033186
	cmp r2, #0xfe
	mov r5, r1
	bls.n .L0803317e
.L080330f4:
	mov.w r11, #0xff
.L080330f8:
	ldr r0, [r4, #0x10]
	add.w r8, r0, #0x20
	movw r0, #0xffff
	movt r0, #0xf
	add.w r0, r0, #0x100000
	cmp r8, r0
	bhi.n .L08033196
	ldr.w r10, [r4, #0x18]
	cmp.w r10, #0x0
	beq.n .L0803319a
	mov r9, r8
	ldr r6, [r4, #0x0]
	bfc r9, #0xc, #0x14
	cmp.w r9, #0x0
	bne.w .L08032e14
	ldr r1, [r4, #0x14]
	add.w r10, r10, #0x1
	cmp r1, #0x0
	str.w r10, [r4, #0x18]
	beq.w .L08032e08
	ldrh r0, [r6, #0xa]
	movw r2, #0xffff
	movt r2, #0xf
	add r0, r2
	tst.w r0, r8, lsr #0xc
	bne.w .L08032e14
	mov r0, r6
	bl allocation_table_read
	cmp r0, #0x2
	bcc.n .L08033240
	adds r1, r0, #0x1
	beq.n .L080331a4
	ldr r2, [r6, #0x18]
	cmp r0, r2
	bcs.n .L08033244
	subs r1, r0, #0x2
	subs r2, #0x2
	cmp r1, r2
	str r0, [r4, #0x14]
	bcs.n .L08033174
	ldr r0, [r6, #0x2c]
	ldrh r2, [r6, #0xa]
	mla r10, r1, r2, r0
	b.n .L08033178
.L08033174:
	mov.w r10, #0x0
.L08033178:
	str.w r10, [r4, #0x18]
	b.n .L08032e14
.L0803317e:
	adds r0, r2, #0x1
	movs r2, #0x0
	strh.w r2, [r12, r0, lsl #0x1]
.L08033186:
	sub.w r11, r11, #0x1
	mov r5, r1
	b.n .L080330f8
.L0803318e:
	movs r0, #0x4
	b.n .L08033246
.L08033192:
	movs r0, #0x4
	b.n .L08033246
.L08033196:
	movs r0, #0x4
	b.n .L08033246
.L0803319a:
	movs r0, #0x4
	b.n .L08033246
.L0803319e:
	mov.w r0, #0xffffffff
	str r0, [r7, #0x30]
.L080331a4:
	movs r0, #0x1
	b.n .L08033246
.L080331a8:
	lsls.w r1, r11, #0x18
	bne.n .L0803322e
	ldrb r1, [r0, #0x0]
	ldrb r2, [r0, #0x1]
	lsrs r6, r1, #0x1
	orr.w r1, r6, r1, lsl #0x7
	ldrb r3, [r0, #0x2]
	add r1, r2
	uxtb r1, r1
	add.w r2, r3, r1, lsl #0x7
	ldrb r7, [r0, #0x3]
	add.w r1, r2, r1, lsr #0x1
	uxtb r1, r1
	add.w r2, r7, r1, lsl #0x7
	add.w r1, r2, r1, lsr #0x1
	ldrb r2, [r0, #0x4]
	uxtb r1, r1
	add.w r2, r2, r1, lsl #0x7
	add.w r1, r2, r1, lsr #0x1
	ldrb r2, [r0, #0x5]
	uxtb r1, r1
	add.w r2, r2, r1, lsl #0x7
	add.w r1, r2, r1, lsr #0x1
	ldrb r2, [r0, #0x6]
	uxtb r1, r1
	add.w r2, r2, r1, lsl #0x7
	add.w r1, r2, r1, lsr #0x1
	ldrb r2, [r0, #0x7]
	uxtb r1, r1
	add.w r2, r2, r1, lsl #0x7
	add.w r1, r2, r1, lsr #0x1
	ldrb r2, [r0, #0x8]
	uxtb r1, r1
	add.w r2, r2, r1, lsl #0x7
	add.w r1, r2, r1, lsr #0x1
	ldrb r2, [r0, #0x9]
	uxtb r1, r1
	add.w r2, r2, r1, lsl #0x7
	add.w r1, r2, r1, lsr #0x1
	uxtb r1, r1
	lsrs r2, r1, #0x1
	ldrb r0, [r0, #0xa]
	orr.w r1, r2, r1, lsl #0x7
	add r0, r1
	uxtb r0, r0
	uxtb r1, r5
	cmp r1, r0
	beq.n .L08033234
.L0803322e:
	mov.w r0, #0xffffffff
	str r0, [r4, #0x2c]
.L08033234:
	movs r0, #0x0
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803323c:
	movs r0, #0x4
	b.n .L08033246
.L08033240:
	movs r0, #0x2
	b.n .L08033246
.L08033244:
	movs r0, #0x4
.L08033246:
	movs r1, #0x0
	str r1, [r4, #0x18]
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
