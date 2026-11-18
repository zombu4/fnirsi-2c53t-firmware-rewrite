@ filesystem_09.s - FAT volume code: allocation table entry read, volume mount, FAT entry write, volume sync.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ allocation_table_read - reads entry r1 of the allocation table of volume
@ object r0 (purpose: reads one allocation table entry, the next cluster of a
@ chain).
@ Returns 1 when r1 < 2 or r1 >= the word at r0+0x18. The volume type byte
@ r0[0] selects the layout: 3 = 4-byte entries (28 bits kept, 0x400 entries per
@ block), 2 = 2-byte entries (0x800 per block), 1 = 12-bit entries at byte
@ offset r1+r1/2 (may span two blocks, odd entries shifted right by 4); any
@ other type returns 1.
@ Uses the 0x1000-byte window at r0+0x34 with its sector number at r0+0x30 and
@ the table start sector at r0+0x24. Flushes a dirty window (r0[3] != 0) with
@ 0803616c (serial_device_write_merge), also to the mirror copy at
@ sector + word r0+0x1c when r0[2]==2 and the sector is inside the table, then
@ loads the new sector with 08036048 (serial_device_read). The device address
@ is sector<<12 when r0[1]==3, sector*0x1000+0x200000 when r0[1]==2.
@ Returns 0xffffffff when r0[1] is neither 2 nor 3 at a flush or load (a failed
@ load also sets r0+0x30 to -1).
@ ----------------------------------------------------------------------------
	.section .text.allocation_table_read,"ax",%progbits
	.global allocation_table_read
	.thumb_func
	.type allocation_table_read, %function
allocation_table_read:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x4
	cmp r1, #0x2
	bcc.n .L08036f6e
	mov r4, r0
	ldr r0, [r0, #0x18]
	mov r5, r1
	cmp r0, r1
	bls.n .L08036f6e
	ldrb r0, [r4, #0x0]
	cmp r0, #0x3
	beq.n .L08036f76
	cmp r0, #0x2
	beq.n .L08036fa6
	cmp r0, #0x1
	bne.n .L08036f6e
	ldr r0, [r4, #0x24]
	add.w r7, r5, r5, lsr #0x1
	ldr r6, [r4, #0x30]
	add.w r10, r0, r7, lsr #0xc
	cmp r6, r10
	beq.w .L0803711a
	ldrb r0, [r4, #0x3]
	cmp r0, #0x0
	beq.w .L080370de
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L08036fd6
	cmp r0, #0x2
	bne.w .L08037150
	nop.w
	mov.w r0, #0x200000
	add.w r9, r0, r6, lsl #0xc
	b.n .L08036fde
.L08036f6e:
	movs r0, #0x1
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08036f76:
	ldr r0, [r4, #0x24]
	ldr r7, [r4, #0x30]
	add.w r6, r0, r5, lsr #0xa
	cmp r7, r6
	beq.w .L080371f6
	ldrb r0, [r4, #0x3]
	cmp r0, #0x0
	beq.w .L080371c0
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L08037022
	cmp r0, #0x2
	bne.w .L08037150
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L08037028
.L08036fa6:
	ldr r0, [r4, #0x24]
	ldr r7, [r4, #0x30]
	add.w r6, r0, r5, lsr #0xb
	cmp r7, r6
	beq.w .L0803726e
	ldrb r0, [r4, #0x3]
	cmp r0, #0x0
	beq.w .L08037238
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L08037074
	cmp r0, #0x2
	bne.w .L08037150
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L0803707a
.L08036fd6:
	nop.w
	lsl.w r9, r6, #0xc
.L08036fde:
	add.w r8, r4, #0x34
	nop.w
	mov r0, r8
	mov r1, r9
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [r4, #0x24]
	ldr r0, [r4, #0x30]
	ldr r1, [r4, #0x1c]
	subs r3, r0, r3
	movs r2, #0x0
	cmp r3, r1
	strb r2, [r4, #0x3]
	bcs.n .L080370de
	ldrb r2, [r4, #0x2]
	cmp r2, #0x2
	bne.n .L080370de
	ldrb r2, [r4, #0x1]
	adds r6, r1, r0
	cmp r2, #0x3
	beq.n .L080370c6
	cmp r2, #0x2
	bne.n .L080370de
	nop.w
	mov.w r0, #0x200000
	add.w r9, r0, r6, lsl #0xc
	b.n .L080370ce
.L08037022:
	nop.w
	lsls r7, r7, #0xc
.L08037028:
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
	bcs.w .L080371c0
	ldrb r2, [r4, #0x2]
	cmp r2, #0x2
	bne.w .L080371c0
	ldrb r2, [r4, #0x1]
	adds r7, r1, r0
	cmp r2, #0x3
	beq.w .L080371aa
	cmp r2, #0x2
	bne.w .L080371c0
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L080371b0
.L08037074:
	nop.w
	lsls r7, r7, #0xc
.L0803707a:
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
	bcs.w .L08037238
	ldrb r2, [r4, #0x2]
	cmp r2, #0x2
	bne.w .L08037238
	ldrb r2, [r4, #0x1]
	adds r7, r1, r0
	cmp r2, #0x3
	beq.w .L08037222
	cmp r2, #0x2
	bne.w .L08037238
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L08037228
.L080370c6:
	nop.w
	lsl.w r9, r6, #0xc
.L080370ce:
	nop.w
	mov r0, r8
	mov r1, r9
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L080370de:
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L080370f8
	cmp r0, #0x2
	bne.w .L080372ae
	nop.w
	mov.w r0, #0x200000
	add.w r8, r0, r10, lsl #0xc
	b.n .L08037100
.L080370f8:
	nop.w
	lsl.w r8, r10, #0xc
.L08037100:
	add.w r9, r4, #0x34
	nop.w
	mov r0, r9
	mov r1, r8
	mov.w r2, #0x1000
	bl serial_device_read
	ldr r0, [r4, #0x24]
	str.w r10, [r4, #0x30]
.L0803711a:
	adds r6, r7, #0x1
	bfc r7, #0xc, #0x14
	adds r1, r4, r7
	ldrb.w r9, [r1, #0x34]
	add.w r11, r0, r6, lsr #0xc
	cmp r10, r11
	beq.w .L080372da
	ldrb r0, [r4, #0x3]
	cmp r0, #0x0
	beq.w .L08037296
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803715a
	cmp r0, #0x2
	bne.n .L08037150
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r10, lsl #0xc
	b.n .L08037162
.L08037150:
	mov.w r0, #0xffffffff
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803715a:
	nop.w
	lsl.w r7, r10, #0xc
.L08037162:
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
	bcs.w .L08037296
	ldrb r2, [r4, #0x2]
	cmp r2, #0x2
	bne.w .L08037296
	ldrb r2, [r4, #0x1]
	adds r7, r1, r0
	cmp r2, #0x3
	beq.n .L08037280
	cmp r2, #0x2
	bne.n .L08037296
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L08037286
.L080371aa:
	nop.w
	lsls r7, r7, #0xc
.L080371b0:
	nop.w
	mov r0, r8
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L080371c0:
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L080371d8
	cmp r0, #0x2
	bne.n .L080372ae
	nop.w
	mov.w r0, #0x200000
	add.w r8, r0, r6, lsl #0xc
	b.n .L080371e0
.L080371d8:
	nop.w
	lsl.w r8, r6, #0xc
.L080371e0:
	add.w r7, r4, #0x34
	nop.w
	mov r0, r7
	mov r1, r8
	mov.w r2, #0x1000
	bl serial_device_read
	str r6, [r4, #0x30]
.L080371f6:
	movw r0, #0xffc
	and.w r0, r0, r5, lsl #0x2
	adds r1, r4, r0
	ldrb.w r3, [r1, #0x36]
	ldrb.w r0, [r1, #0x34]
	ldrb.w r2, [r1, #0x35]
	ldrb.w r1, [r1, #0x37]
	lsls r3, r3, #0x8
	orr.w r1, r3, r1, lsl #0x10
	add r1, r2
	bfi r0, r1, #0x8, #0x14
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08037222:
	nop.w
	lsls r7, r7, #0xc
.L08037228:
	nop.w
	mov r0, r8
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L08037238:
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L08037250
	cmp r0, #0x2
	bne.n .L080372ae
	nop.w
	mov.w r0, #0x200000
	add.w r8, r0, r6, lsl #0xc
	b.n .L08037258
.L08037250:
	nop.w
	lsl.w r8, r6, #0xc
.L08037258:
	add.w r7, r4, #0x34
	nop.w
	mov r0, r7
	mov r1, r8
	mov.w r2, #0x1000
	bl serial_device_read
	str r6, [r4, #0x30]
.L0803726e:
	movw r0, #0xffe
	and.w r0, r0, r5, lsl #0x1
	add r0, r4
	ldrh r0, [r0, #0x34]
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08037280:
	nop.w
	lsls r7, r7, #0xc
.L08037286:
	nop.w
	mov r0, r8
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L08037296:
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L080372ba
	cmp r0, #0x2
	bne.n .L080372ae
	nop.w
	mov.w r0, #0x200000
	add.w r8, r0, r11, lsl #0xc
	b.n .L080372c2
.L080372ae:
	mov.w r0, #0xffffffff
	str r0, [r4, #0x30]
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080372ba:
	nop.w
	lsl.w r8, r11, #0xc
.L080372c2:
	add.w r7, r4, #0x34
	nop.w
	mov r0, r7
	mov r1, r8
	mov.w r2, #0x1000
	bl serial_device_read
	str.w r11, [r4, #0x30]
.L080372da:
	bfc r6, #0xc, #0x14
	adds r0, r4, r6
	ldrb.w r0, [r0, #0x34]
	lsls r2, r5, #0x1f
	orr.w r1, r9, r0, lsl #0x8
	mov r0, r1
	bfc r0, #0xc, #0x14
	it ne
	lsrne r0, r1, #0x4
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short 0x0000 @ padding

@ ----------------------------------------------------------------------------
@ mount_fat_volume - mounts a FAT volume. Params: r0 = pointer to a path
@ pointer, r1 = pointer to the output volume pointer. Returns an error code.
@ Sets *r1 = 0; returns 0xb if the path pointer is null. Scans the path for ':'
@ within the first characters (stops at bytes < 0x20); when ':' is found it
@ requires exactly 2 characters with a digit byte <= 0x33 (drive '0'..'3',
@ else 0xb) and advances the path pointer by 2, otherwise drive 0.
@ Looks up the volume structure in the pointer table 0x20005fcc[drive] (returns
@ 0xc if null) and stores it to *r1; returns 0 when its type byte [0] is
@ nonzero and medium byte [1]-1 < 3 (already mounted). Otherwise clears [0],
@ sets [1] = drive and returns 3 unless the drive is 2 or 3; calls
@ 08030b80 (validate_boot_sector) with (vol, 0) (reads the first 0x1000-byte
@ block and tests for a boot sector); when it returns 2 (signature present, not
@ a boot sector) it reads the four partition start sectors at +0x1fa, +0x20a,
@ +0x21a, +0x22a and retries 08030b80 with each nonzero one (when none is valid
@ the value 3 remains and 0xd is returned); a result of 4 returns 1, any other
@ result above 1 returns 0xd.
@ Boot sector checks (window at +0x34): halfword +0x3f (bytes per sector) must
@ be 0x1000, sectors per FAT from halfword +0x4a (else word +0x58) to +0x1c,
@ FAT count byte +0x44 to [2] must be 1 or 2, sectors per cluster byte +0x41
@ (to halfword [10]) a nonzero power of two, root entries halfword +0x45 (to
@ halfword [8]) with (x & 0x7f) == 0, total sectors halfword +0x47 (else word
@ +0x54), reserved sectors halfword +0x42 nonzero, data area must hold at
@ least one cluster; cluster count < 0xff6 gives type 1, < 0xfff6 type 2,
@ < 0xffffff6 type 3, else 0xd.
@ Fills +0x18 (clusters+2), +0x20 (start sector from +0x30), +0x24 (FAT
@ start), +0x28 (root directory start; type 3 requires halfword +0x45, +0x5e
@ and +0x5f zero and takes word +0x60), +0x2c (data start); FAT size must cover
@ the entries (else 0xd); sets +0x10..+0x17 to 0xff and [4] = 0x80; for type 3
@ with halfword +0x64 == 1 it writes back a dirty window with 0803616c
@ (serial_device_write_merge), loads sector start+1 with 08036048
@ (serial_device_read), and when 0xaa55 at +0x232, 0x41615252 at +0x34 and
@ 0x61417272 at +0x218 match copies word +0x220 to +0x10 and word +0x21c to
@ +0x14. Finally writes [0] = type, increments 0x20005fdc and stores it as
@ halfword [6], sets word [0xc] = 0x20005fde, returns 0.
@ ----------------------------------------------------------------------------
	.section .text.mount_fat_volume,"ax",%progbits
	.global mount_fat_volume
	.thumb_func
	.type mount_fat_volume, %function
mount_fat_volume:
	push.w {r4, r5, r6, r7, r8, r9, lr}
	sub sp, #0x14
	movs r2, #0x0
	str r2, [r1, #0x0]
	ldr r3, [r0, #0x0]
	cbz r3, .L0803a7de
	movs r7, #0x0
.L0803a7b0:
	ldrb r2, [r3, r7]
	cmp r2, #0x20
	bcc.n .L0803a7e2
	cmp r2, #0x3a
	beq.n .L0803a7e2
	adds r6, r3, r7
	ldrb r2, [r6, #0x1]
	cmp r2, #0x20
	bcc.n .L0803a7ea
	cmp r2, #0x3a
	beq.n .L0803a7ea
	ldrb r2, [r6, #0x2]
	cmp r2, #0x20
	bcc.n .L0803a80e
	cmp r2, #0x3a
	beq.n .L0803a80e
	ldrb r2, [r6, #0x3]
	adds r7, #0x4
	cmp r2, #0x20
	bcc.n .L0803a7ec
	cmp r2, #0x3a
	bne.n .L0803a7b0
	b.n .L0803a7ec
.L0803a7de:
	movs r2, #0xb
	b.n .L0803a90a
.L0803a7e2:
	adds r7, #0x1
	cmp r2, #0x3a
	beq.n .L0803a7f0
	b.n .L0803a814
.L0803a7ea:
	adds r7, #0x2
.L0803a7ec:
	cmp r2, #0x3a
	bne.n .L0803a814
.L0803a7f0:
	ldrb r6, [r3, #0x0]
	movs r2, #0xb
	cmp r6, #0x33
	bhi.w .L0803a90a
	cmp r7, #0x2
	bne.w .L0803a90a
	subs r6, #0x30
	cmp r6, #0x9
	bhi.w .L0803a90a
	adds r2, r3, r7
	str r2, [r0, #0x0]
	b.n .L0803a816
.L0803a80e:
	adds r7, #0x3
	cmp r2, #0x3a
	beq.n .L0803a7f0
.L0803a814:
	movs r6, #0x0
.L0803a816:
	movw r0, #0x5fcc
	movt r0, #0x2000
	ldr.w r4, [r0, r6, lsl #0x2]
	cbz r4, .L0803a892
	str r4, [r1, #0x0]
	ldrb r0, [r4, #0x0]
	cbz r0, .L0803a832
	ldrb r0, [r4, #0x1]
	subs r0, #0x1
	cmp r0, #0x2
	bls.n .L0803a8a2
.L0803a832:
	movs r0, #0x0
	strb r0, [r4, #0x0]
	and r0, r6, #0xfe
	cmp r0, #0x2
	strb r6, [r4, #0x1]
	bne.n .L0803a896
	mov r0, r4
	movs r1, #0x0
	bl validate_boot_sector
	cmp r0, #0x2
	bne.n .L0803a89a
	ldr.w r1, [r4, #0x1fa]
	ldr.w r0, [r4, #0x20a]
	add r7, sp, #0x4
	adds r5, r7, #0x4
	add.w r12, sp, #0x8
	movs r6, #0x0
	ldr.w r2, [r4, #0x21a]
	ldr.w r3, [r4, #0x22a]
	str r1, [sp, #0x4]
	stm.w r12, {r0, r2, r3}
	cbz r1, .L0803a87c
	nop
.L0803a870:
	mov r0, r4
	bl validate_boot_sector
	cmp r6, #0x2
	bls.n .L0803a882
	b.n .L0803a89a
.L0803a87c:
	movs r0, #0x3
	cmp r6, #0x2
	bhi.n .L0803a89a
.L0803a882:
	cmp r0, #0x2
	bcc.n .L0803a89a
	ldr.w r1, [r5, r6, lsl #0x2]
	adds r6, #0x1
	cmp r1, #0x0
	bne.n .L0803a870
	b.n .L0803a87c
.L0803a892:
	movs r2, #0xc
	b.n .L0803a90a
.L0803a896:
	movs r2, #0x3
	b.n .L0803a90a
.L0803a89a:
	cmp r0, #0x4
	bne.n .L0803a8a6
	movs r2, #0x1
	b.n .L0803a90a
.L0803a8a2:
	movs r2, #0x0
	b.n .L0803a90a
.L0803a8a6:
	cmp r0, #0x1
	bls.n .L0803a8ae
	movs r2, #0xd
	b.n .L0803a90a
.L0803a8ae:
	ldrh.w r0, [r4, #0x3f]
	cmp.w r0, #0x1000
	bne.n .L0803a900
	ldrh.w r0, [r4, #0x4a]
	cmp r0, #0x0
	it eq
	ldreq r0, [r4, #0x58]
	ldrb.w r3, [r4, #0x44]
	ldr r5, [r4, #0x30]
	subs r1, r3, #0x1
	cmp r1, #0x1
	str r0, [r4, #0x1c]
	strb r3, [r4, #0x2]
	bhi.n .L0803a904
	ldrb.w r2, [r4, #0x41]
	subs r1, r2, #0x1
	ands r1, r2
	clz r7, r2
	it ne
	movne r1, #0x1
	lsrs r7, r7, #0x5
	orrs r1, r7
	strh r2, [r4, #0xa]
	bne.n .L0803a908
	ldrb.w r7, [r4, #0x45]
	ldrb.w r1, [r4, #0x46]
	orr.w r1, r7, r1, lsl #0x8
	lsls r7, r7, #0x19
	strh r1, [r4, #0x8]
	beq.n .L0803a912
	movs r2, #0xd
	b.n .L0803a90a
.L0803a900:
	movs r2, #0xd
	b.n .L0803a90a
.L0803a904:
	movs r2, #0xd
	b.n .L0803a90a
.L0803a908:
	movs r2, #0xd
.L0803a90a:
	mov r0, r2
	add sp, #0x14
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L0803a912:
	ldrh.w r7, [r4, #0x47]
	cmp r7, #0x0
	it eq
	ldreq r7, [r4, #0x54]
	ldrh.w r6, [r4, #0x42]
	cbz r6, .L0803a934
	mul lr, r0, r3
	add.w r3, lr, r1, lsr #0x7
	add r3, r6
	cmp r7, r3
	bcs.n .L0803a938
	movs r2, #0xd
	b.n .L0803a90a
.L0803a934:
	movs r2, #0xd
	b.n .L0803a90a
.L0803a938:
	subs r7, r7, r3
	cmp r7, r2
	bcs.n .L0803a942
	movs r2, #0xd
	b.n .L0803a90a
.L0803a942:
	udiv r2, r7, r2
	movw r7, #0xfff6
	movt r7, #0xfff
	mov.w r9, #0x0
	cmp r2, r7
	movw r7, #0xfff6
	it cc
	movcc.w r9, #0x3
	cmp r2, r7
	movw r7, #0xff6
	it cc
	movcc.w r9, #0x2
	cmp r2, r7
	it cc
	movcc.w r9, #0x1
	cmp.w r9, #0x0
	beq.n .L0803a9a4
	add.w r12, r2, #0x2
	add r6, r5
	add r3, r5
	cmp.w r9, #0x3
	str.w r12, [r4, #0x18]
	strd r5, r6, [r4, #0x20]
	str r3, [r4, #0x2c]
	bne.n .L0803a9a8
	ldrb.w r2, [r4, #0x5e]
	ldrb.w r3, [r4, #0x5f]
	orrs r1, r2
	orr.w r1, r1, r3, lsl #0x8
	cbz r1, .L0803a9c8
	movs r2, #0xd
	b.n .L0803a90a
.L0803a9a4:
	movs r2, #0xd
	b.n .L0803a90a
.L0803a9a8:
	cbz r1, .L0803aa18
	add.w r1, r6, lr
	cmp.w r9, #0x2
	str r1, [r4, #0x28]
	iteee eq
	lsleq.w r1, r12, #0x1
	addne.w r1, r12, r12, lsl #0x1
	andne r2, r2, #0x1
	addne.w r1, r2, r1, lsr #0x1
	b.n .L0803a9d0
.L0803a9c8:
	ldr r1, [r4, #0x60]
	str r1, [r4, #0x28]
	lsl.w r1, r12, #0x2
.L0803a9d0:
	addw r1, r1, #0xfff
	cmp.w r0, r1, lsr #0xc
	bcs.n .L0803a9de
	movs r2, #0xd
	b.n .L0803a90a
.L0803a9de:
	mov.w r0, #0xffffffff
	strd r0, r0, [r4, #0x10]
	movs r0, #0x80
	cmp.w r9, #0x3
	strb r0, [r4, #0x4]
	bne.n .L0803aaee
	ldrh.w r0, [r4, #0x64]
	cmp r0, #0x1
	bne.n .L0803aaee
	ldrb r0, [r4, #0x3]
	add.w r8, r4, #0x34
	cbz r0, .L0803aa78
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803aa1c
	cmp r0, #0x2
	bne.n .L0803aaee
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r5, lsl #0xc
	b.n .L0803aa22
.L0803aa18:
	movs r2, #0xd
	b.n .L0803a90a
.L0803aa1c:
	nop.w
	lsls r6, r5, #0xc
.L0803aa22:
	nop.w
	mov r0, r8
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [r4, #0x24]
	ldr r1, [r4, #0x30]
	ldr r2, [r4, #0x1c]
	subs r3, r1, r3
	movs r0, #0x0
	cmp r3, r2
	strb r0, [r4, #0x3]
	bcs.n .L0803aa78
	ldrb r0, [r4, #0x2]
	cmp r0, #0x2
	bne.n .L0803aa78
	ldrb r0, [r4, #0x1]
	adds r6, r2, r1
	cmp r0, #0x3
	beq.n .L0803aa62
	cmp r0, #0x2
	bne.n .L0803aa7a
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r6, lsl #0xc
	b.n .L0803aa68
.L0803aa62:
	nop.w
	lsls r6, r6, #0xc
.L0803aa68:
	nop.w
	mov r0, r8
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L0803aa78:
	ldrb r0, [r4, #0x1]
.L0803aa7a:
	cmp r0, #0x3
	add.w r5, r5, #0x1
	beq.n .L0803aa94
	cmp r0, #0x2
	bne.n .L0803aae8
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r5, lsl #0xc
	b.n .L0803aa9a
.L0803aa94:
	nop.w
	lsls r6, r5, #0xc
.L0803aa9a:
	nop.w
	mov r0, r8
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_read
	ldrh.w r1, [r4, #0x232]
	movw r2, #0xaa55
	movs r0, #0x0
	cmp r1, r2
	str r5, [r4, #0x30]
	strb r0, [r4, #0x4]
	bne.n .L0803aaee
	ldr r0, [r4, #0x34]
	movw r1, #0x5252
	movt r1, #0x4161
	cmp r0, r1
	bne.n .L0803aaee
	ldr.w r0, [r4, #0x218]
	movw r1, #0x7272
	movt r1, #0x6141
	cmp r0, r1
	bne.n .L0803aaee
	ldr.w r0, [r4, #0x220]
	ldr.w r1, [r4, #0x21c]
	strd r0, r1, [r4, #0x10]
	b.n .L0803aaee
.L0803aae8:
	mov.w r0, #0xffffffff
	str r0, [r4, #0x30]
.L0803aaee:
	movw r0, #0x5fdc
	strb.w r9, [r4, #0x0]
	movt r0, #0x2000
	ldrh r1, [r0, #0x0]
	movs r2, #0x0
	adds r1, #0x1
	strh r1, [r0, #0x0]
	movw r0, #0x5fde
	movt r0, #0x2000
	strh r1, [r4, #0x6]
	str r0, [r4, #0xc]
	b.n .L0803a90a

@ ----------------------------------------------------------------------------
@ fat_set_entry - writes an entry into the allocation table of a volume.
@ Params: r0 = pointer to a volume structure, r1 = cluster index, r2 = value.
@ Returns 0 ok, 1 medium error, 2 invalid index/type. Returns 2 if r1 < 2 or
@ r1 >= word [0x18], or if the type byte [0] is not 1, 2 or 3.
@ Writes an entry into the table held in a 0x1000-byte sector window at r0+0x34
@ (window sector word [0x30], FAT start sector [0x24], dirty byte [3], medium
@ byte [1], copy count byte [2], FAT size word [0x1c]):
@  - type 3 uses sector [0x24]+(r1>>10) and stores bytes 0..2 of the value and
@    the low nibble of byte 3 (high nibble kept) at entry r1&0x3ff;
@  - type 2 uses sector [0x24]+(r1>>11) and stores 16 bits at entry r1&0x7ff;
@  - type 1 uses byte offset r1+r1/2 (sector [0x24]+(offset>>12)): even r1
@    stores value bits 0..7 in that byte and bits 8..11 in the low nibble of the
@    next byte, odd r1 stores bits 0..3 in the high nibble of that byte and
@    bits 4..11 in the next byte, loading the following sector when the two
@    bytes lie in different sectors.
@ When the needed sector differs from [0x30] a dirty window is written back
@ with 0803616c (serial_device_write_merge; sector<<12 for medium 3,
@ sector*0x1000+0x200000 for medium 2, other media return 1) and, when
@ (sector-[0x24]) < [0x1c] and [2]==2, a second copy at sector+[0x1c]; the new
@ sector is read with 08036048 (serial_device_read) and stored at [0x30]; a
@ medium byte other than 2/3 sets [0x30]=0xffffffff and returns 1.
@ Sets the dirty byte [3]=1 and returns 0.
@ ----------------------------------------------------------------------------
	.section .text.fat_set_entry,"ax",%progbits
	.global fat_set_entry
	.thumb_func
	.type fat_set_entry, %function
fat_set_entry:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x4
	cmp r1, #0x2
	bcc.n .L0803c8c4
	mov r4, r0
	ldr r0, [r0, #0x18]
	mov r6, r1
	cmp r0, r1
	bls.n .L0803c8c4
	ldrb r0, [r4, #0x0]
	mov r5, r2
	cmp r0, #0x3
	beq.n .L0803c8cc
	cmp r0, #0x2
	beq.n .L0803c8fc
	cmp r0, #0x1
	bne.n .L0803c8c4
	ldr r0, [r4, #0x24]
	add.w r8, r6, r6, lsr #0x1
	ldr r7, [r4, #0x30]
	add.w r9, r0, r8, lsr #0xc
	cmp r7, r9
	beq.w .L0803cac6
	ldrb r0, [r4, #0x3]
	cmp r0, #0x0
	beq.w .L0803ca8c
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803c976
	cmp r0, #0x2
	bne.w .L0803cc00
	nop.w
	mov.w r0, #0x200000
	add.w r10, r0, r7, lsl #0xc
	b.n .L0803c97e
.L0803c8c4:
	movs r0, #0x2
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803c8cc:
	ldr r0, [r4, #0x24]
	ldr r7, [r4, #0x30]
	add.w r9, r0, r6, lsr #0xa
	cmp r7, r9
	beq.w .L0803cc28
	ldrb r0, [r4, #0x3]
	cmp r0, #0x0
	beq.w .L0803cbe2
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803c9c4
	cmp r0, #0x2
	bne.w .L0803cc00
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L0803c9ca
.L0803c8fc:
	ldr r0, [r4, #0x24]
	ldr r7, [r4, #0x30]
	add.w r9, r0, r6, lsr #0xb
	cmp r7, r9
	beq.w .L0803ca66
	ldrb r0, [r4, #0x3]
	cmp r0, #0x0
	beq.w .L0803ca2c
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803c92c
	cmp r0, #0x2
	bne.w .L0803cc00
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L0803c932
.L0803c92c:
	nop.w
	lsls r7, r7, #0xc
.L0803c932:
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
	bcs.n .L0803ca2c
	ldrb r2, [r4, #0x2]
	cmp r2, #0x2
	bne.n .L0803ca2c
	ldrb r2, [r4, #0x1]
	adds r7, r1, r0
	cmp r2, #0x3
	beq.n .L0803ca16
	cmp r2, #0x2
	bne.n .L0803ca2c
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L0803ca1c
.L0803c976:
	nop.w
	lsl.w r10, r7, #0xc
.L0803c97e:
	add.w r7, r4, #0x34
	nop.w
	mov r0, r7
	mov r1, r10
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [r4, #0x24]
	ldr r0, [r4, #0x30]
	ldr r1, [r4, #0x1c]
	subs r3, r0, r3
	movs r2, #0x0
	cmp r3, r1
	strb r2, [r4, #0x3]
	bcs.n .L0803ca8c
	ldrb r2, [r4, #0x2]
	cmp r2, #0x2
	bne.n .L0803ca8c
	ldrb r2, [r4, #0x1]
	add.w r10, r1, r0
	cmp r2, #0x3
	beq.n .L0803ca74
	cmp r2, #0x2
	bne.n .L0803ca8c
	nop.w
	mov.w r0, #0x200000
	add.w r10, r0, r10, lsl #0xc
	b.n .L0803ca7c
.L0803c9c4:
	nop.w
	lsls r7, r7, #0xc
.L0803c9ca:
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
	bcs.w .L0803cbe2
	ldrb r2, [r4, #0x2]
	cmp r2, #0x2
	bne.w .L0803cbe2
	ldrb r2, [r4, #0x1]
	adds r7, r1, r0
	cmp r2, #0x3
	beq.w .L0803cbcc
	cmp r2, #0x2
	bne.w .L0803cbe2
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r7, lsl #0xc
	b.n .L0803cbd2
.L0803ca16:
	nop.w
	lsls r7, r7, #0xc
.L0803ca1c:
	nop.w
	mov r0, r8
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L0803ca2c:
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803ca46
	cmp r0, #0x2
	bne.w .L0803cbfa
	nop.w
	mov.w r0, #0x200000
	add.w r8, r0, r9, lsl #0xc
	b.n .L0803ca4e
.L0803ca46:
	nop.w
	lsl.w r8, r9, #0xc
.L0803ca4e:
	add.w r7, r4, #0x34
	nop.w
	mov r0, r7
	mov r1, r8
	mov.w r2, #0x1000
	bl serial_device_read
	str.w r9, [r4, #0x30]
.L0803ca66:
	movw r0, #0xffe
	and.w r0, r0, r6, lsl #0x1
	add r0, r4
	strh r5, [r0, #0x34]
	b.n .L0803cc58
.L0803ca74:
	nop.w
	lsl.w r10, r10, #0xc
.L0803ca7c:
	nop.w
	mov r0, r7
	mov r1, r10
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L0803ca8c:
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803caa6
	cmp r0, #0x2
	bne.w .L0803cbfa
	nop.w
	mov.w r0, #0x200000
	add.w r7, r0, r9, lsl #0xc
	b.n .L0803caae
.L0803caa6:
	nop.w
	lsl.w r7, r9, #0xc
.L0803caae:
	add.w r10, r4, #0x34
	nop.w
	mov r0, r10
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_read
	str.w r9, [r4, #0x30]
.L0803cac6:
	add.w r11, r8, #0x1
	bfc r8, #0xc, #0x14
	add.w r0, r4, r8
	ands r10, r6, #0x1
	add.w r0, r0, #0x34
	bne.n .L0803cae0
	uxtb r1, r5
	b.n .L0803caea
.L0803cae0:
	ldrb r1, [r0, #0x0]
	and r1, r1, #0xf
	bfi r1, r5, #0x4, #0x8
.L0803caea:
	strb r1, [r0, #0x0]
	ldr r0, [r4, #0x24]
	movs r1, #0x1
	add.w r7, r0, r11, lsr #0xc
	cmp r9, r7
	strb r1, [r4, #0x3]
	beq.n .L0803cba4
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803cb12
	cmp r0, #0x2
	bne.n .L0803cc00
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r9, lsl #0xc
	b.n .L0803cb1a
.L0803cb12:
	nop.w
	lsl.w r6, r9, #0xc
.L0803cb1a:
	add.w r8, r4, #0x34
	nop.w
	mov r0, r8
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [r4, #0x24]
	ldr r1, [r4, #0x30]
	ldr r2, [r4, #0x1c]
	subs r3, r1, r3
	movs r0, #0x0
	cmp r3, r2
	strb r0, [r4, #0x3]
	bcs.n .L0803cb74
	ldrb r0, [r4, #0x2]
	cmp r0, #0x2
	bne.n .L0803cb74
	ldrb r0, [r4, #0x1]
	adds r6, r2, r1
	cmp r0, #0x3
	beq.n .L0803cb5e
	cmp r0, #0x2
	bne.n .L0803cb76
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r6, lsl #0xc
	b.n .L0803cb64
.L0803cb5e:
	nop.w
	lsls r6, r6, #0xc
.L0803cb64:
	nop.w
	mov r0, r8
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L0803cb74:
	ldrb r0, [r4, #0x1]
.L0803cb76:
	cmp r0, #0x3
	beq.n .L0803cb8c
	cmp r0, #0x2
	bne.n .L0803cbfa
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r7, lsl #0xc
	b.n .L0803cb92
.L0803cb8c:
	nop.w
	lsls r6, r7, #0xc
.L0803cb92:
	nop.w
	mov r0, r8
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_read
	str r7, [r4, #0x30]
.L0803cba4:
	bfc r11, #0xc, #0x14
	add.w r0, r4, r11
	cmp.w r10, #0x0
	add.w r0, r0, #0x34
	bne.n .L0803cbc4
	ldrb r1, [r0, #0x0]
	ubfx r2, r5, #0x8, #0x4
	and r1, r1, #0xf0
	add r1, r2
	b.n .L0803cbc8
.L0803cbc4:
	ubfx r1, r5, #0x4, #0x8
.L0803cbc8:
	strb r1, [r0, #0x0]
	b.n .L0803cc58
.L0803cbcc:
	nop.w
	lsls r7, r7, #0xc
.L0803cbd2:
	nop.w
	mov r0, r8
	mov r1, r7
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L0803cbe2:
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803cc08
	cmp r0, #0x2
	bne.n .L0803cbfa
	nop.w
	mov.w r0, #0x200000
	add.w r8, r0, r9, lsl #0xc
	b.n .L0803cc10
.L0803cbfa:
	mov.w r0, #0xffffffff
	str r0, [r4, #0x30]
.L0803cc00:
	movs r0, #0x1
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803cc08:
	nop.w
	lsl.w r8, r9, #0xc
.L0803cc10:
	add.w r7, r4, #0x34
	nop.w
	mov r0, r7
	mov r1, r8
	mov.w r2, #0x1000
	bl serial_device_read
	str.w r9, [r4, #0x30]
.L0803cc28:
	movw r0, #0xffc
	and.w r0, r0, r6, lsl #0x2
	add r0, r4
	ldrb.w r1, [r0, #0x37]
	and r2, r5, #0xf000000
	and r1, r1, #0xf0
	orr.w r1, r2, r1, lsl #0x18
	lsrs r2, r5, #0x8
	strb.w r2, [r0, #0x35]
	lsrs r2, r5, #0x10
	lsrs r1, r1, #0x18
	strb.w r5, [r0, #0x34]
	strb.w r2, [r0, #0x36]
	strb.w r1, [r0, #0x37]
.L0803cc58:
	movs r0, #0x1
	strb r0, [r4, #0x3]
	movs r0, #0x0
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}

@ ----------------------------------------------------------------------------
@ fat_sync_volume - writes back the dirty state of a volume.
@ Param r0 = pointer to a volume structure; returns 0 when the medium byte [1]
@ is 2 or 3, else 1.
@ If the dirty byte [3] is set: writes the 0x1000-byte window at +0x34 back with
@ 0803616c (serial_device_write_merge; sector word [0x30]; sector<<12 for medium
@ 3, sector*0x1000+0x200000 for medium 2; any other medium returns 1 at once),
@ clears [3], and when (sector-[0x24]) < [0x1c] and [2]==2 writes a second copy
@ at sector+[0x1c].
@ If type [0]==3 and byte [4]==1: clears 0xffc bytes at +0x38 with 0800857c
@ (zero_bytes_aligned), writes 'RRaA' (0x41615252) at +0x34, 'rrAa'
@ (0x61417272) at +0x218, 0x55 0xaa (halfword 0xaa55) at +0x232, copies word
@ [0x14] to +0x21c and word [0x10] to +0x220, sets [0x30]=[0x20]+1, writes the
@ window with 0803616c and clears byte [4].
@ ----------------------------------------------------------------------------
	.section .text.fat_sync_volume,"ax",%progbits
	.global fat_sync_volume_unlocked
	.thumb_func
	.type fat_sync_volume_unlocked, %function
fat_sync_volume_unlocked:
	push {r4, r5, r6, lr}
	mov r4, r0
	ldrb r0, [r0, #0x3]
	cbz r0, .L0803d9b8
	ldrb r0, [r4, #0x1]
	ldr r5, [r4, #0x30]
	cmp r0, #0x3
	beq.n .L0803d958
	cmp r0, #0x2
	bne.w .L0803da4a
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r5, lsl #0xc
	b.n .L0803d95e
.L0803d958:
	nop.w
	lsls r6, r5, #0xc
.L0803d95e:
	add.w r5, r4, #0x34
	nop.w
	mov r0, r5
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
	ldr r3, [r4, #0x24]
	ldr r0, [r4, #0x30]
	ldr r1, [r4, #0x1c]
	subs r3, r0, r3
	movs r2, #0x0
	cmp r3, r1
	strb r2, [r4, #0x3]
	bcs.n .L0803d9b8
	ldrb r2, [r4, #0x2]
	cmp r2, #0x2
	bne.n .L0803d9b8
	ldrb r2, [r4, #0x1]
	adds r6, r1, r0
	cmp r2, #0x3
	beq.n .L0803d9a2
	cmp r2, #0x2
	bne.n .L0803d9b8
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r6, lsl #0xc
	b.n .L0803d9a8
.L0803d9a2:
	nop.w
	lsls r6, r6, #0xc
.L0803d9a8:
	nop.w
	mov r0, r5
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L0803d9b8:
	ldrb r0, [r4, #0x0]
	cmp r0, #0x3
	bne.n .L0803da3c
	ldrb r0, [r4, #0x4]
	cmp r0, #0x1
	bne.n .L0803da3c
	add.w r0, r4, #0x38
	movw r1, #0xffc
	bl zero_bytes_aligned
	movw r0, #0x5252
	movt r0, #0x4161
	mov r5, r4
	str.w r0, [r5, #0x34]!
	movw r0, #0xaa55
	strh.w r0, [r5, #0x1fe]
	movw r0, #0x7272
	movt r0, #0x6141
	str.w r0, [r5, #0x1e4]
	ldrd r1, r0, [r5, #-0x24]
	str.w r0, [r5, #0x1e8]
	str.w r1, [r5, #0x1ec]
	ldr.w r1, [r5, #-0x14]
	ldrb.w r0, [r5, #-0x33]
	adds r6, r1, #0x1
	cmp r0, #0x3
	str.w r6, [r5, #-0x4]
	beq.n .L0803da22
	cmp r0, #0x2
	bne.n .L0803da38
	nop.w
	mov.w r0, #0x200000
	add.w r6, r0, r6, lsl #0xc
	b.n .L0803da28
.L0803da22:
	nop.w
	lsls r6, r6, #0xc
.L0803da28:
	nop.w
	mov r0, r5
	mov r1, r6
	mov.w r2, #0x1000
	bl serial_device_write_merge
.L0803da38:
	movs r0, #0x0
	strb r0, [r4, #0x4]
.L0803da3c:
	ldrb r0, [r4, #0x1]
	cmp r0, #0x3
	beq.n .L0803da46
	cmp r0, #0x2
	bne.n .L0803da4a
.L0803da46:
	movs r0, #0x0
	pop {r4, r5, r6, pc}
.L0803da4a:
	movs r0, #0x1
	pop {r4, r5, r6, pc}
	.short 0x0000 @ padding
