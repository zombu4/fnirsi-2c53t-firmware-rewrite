@ usb_82.s - bulk-only mass-storage SCSI command dispatcher, status block sender, command receive handlers, control request handler and descriptor builders.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ scsi_command_dispatch - command dispatcher of a bulk-only mass-storage device.
@ param_1 (r0) = device structure; returns 0 = command accepted, 1 = error.
@ cb = *(word at *(param_1+4) + 0x24) (command buffer). CBW fields inside cb:
@ dword +0x1028 = host transfer length, byte +0x102c = flags (bit7 direction),
@ byte +0x102d = LUN, byte +0x102f = opcode, byte +0x1030 = first CDB byte.
@ Response buffer cb+0x1c, its length dword at cb+0x18; state byte cb[0].
@ Opcode >= 0x5b or not in the switch returns 1 with byte 0x2000001a = 5 and
@ byte 0x20000028 = 0x20.
@ Opcode set: 0x00 0x03 0x12 0x1a 0x1b 0x1e 0x23 0x25 0x28 0x2a 0x2f 0x5a.
@  0x00: dword +0x1028 == 0 gives length 0 and return 0, else error (5 / 0x20).
@  0x03: copies the 18 bytes 0x20000018..0x20000029 to cb+0x1c, length =
@        min(+0x1028, 0x12).
@  0x12: if bit0 of +0x1030 is set copies 5 bytes from 0x0804bce8 (length
@        forced to 5), else copies min(+0x1028, 0x24) bytes from the 36-byte
@        record 0x08030838 when LUN == 0 (source pointer 0 when LUN != 0) to
@        cb+0x1c (byte copy, 4-way unrolled downward loop: a plain forward
@        copy, not a reversal).
@  0x1a: length 8, response bytes 0.
@  0x1b and 0x1e: length 0.
@  0x23: length 12, response header 0,0,0,8, big-endian (count-1) at +0x20,
@        byte 2 at +0x24, 24-bit big-endian block size at +0x25.
@  0x25: length 8, big-endian (count-1) then big-endian block size.
@  For 0x23/0x25 and LUN 0 the count dword at cb+8 is set to 0xe00 (byte
@  0x20001066 == 0) or 0x200, and the block-size dword at cb+0xc to 0x1000;
@  for a nonzero LUN byte the dwords at cb+LUN*4+8/+0xc are used as stored.
@  0x28: when cb[0] == 7 (new command) requires flags bit7 set else error
@        (5 / 0x20), byte-swaps the dword at +0x1031 (block address) and the
@        ushort at +0x1036 (block count), range check against the count dword
@        (error 5 / 0x21), multiplies by the block size dword, requires the
@        product to equal dword +0x1028 else error (5 / 0x20), sets cb[0] = 1;
@        then each call sends min(remaining, 0x1000) bytes: LUN 0 reads them
@        with 08036048(cb+0x1c, address (+0x200000 when byte 0x20001066 == 0),
@        n), sends with 08040eb4(param_1,0x81,cb+0x1c,n), advances +0x10,
@        reduces +0x14 and the residue dword +0x1048, sets cb[0] = 4 when
@        nothing remains.
@  0x2a: first call (cb[0] == 7) requires flags bit7 clear else error, same
@        decoding and checks, sets cb[0] = 2 and arms reception of the next
@        chunk (see below); later calls write the received chunk with
@        0803616c(cb+0x1c, address, n) (LUN 0), and when all data is written
@        build the 13-byte status block at cb+0x1040 (signature 0x53425355,
@        residue +0x1048, status dword +0x104c = 0), cb[0] = 7, send it with
@        08040eb4(param_1,0x81,..,0xd) and re-arm CBW reception with
@        [param_1+0x140] = cb+0x1020 and n = 0x1f; a 0x2a call that is not
@        finished arms the next chunk (n = min(remaining, 0x1000)) the same
@        way. The arming = [param_1+0x140] = buffer (cb+0x1c for chunks),
@        [param_1+0x13c] = 0, [param_1+0x13a] = max(ushort [param_1+0x134], n)
@        - ushort [param_1+0x134], word 0x40005c04 = (x & 0x3f0f) ^ 0xb080.
@  0x2f: error (5 / 0x24) when bit1 of +0x1030 is set, else range check as
@        above (error 5 / 0x21), length 0.
@  0x5a: length 8, response bytes 0 except byte +0x1d = 6.
@ This function writes the status signature 0x53425355 and does not reference
@ 0x43425355. Data at address +0x200000 (when byte 0x20001066 == 0) moves
@ through 08036048 (called with buffer, address, count; it sends byte 3, then
@ the 3 address bytes, then clocks in count bytes) and 0803616c (called with
@ the received chunk).
@ The tbh table at 0803022e has 91 halfword entries (opcodes 0..0x5a); the
@ 36-byte inquiry record sits at 08030838 after a 2-byte padding.
@ ----------------------------------------------------------------------------
	.section .text.scsi_command_dispatch,"ax",%progbits
	.p2align 2
	.global scsi_command_dispatch
	.thumb_func
	.type scsi_command_dispatch, %function
scsi_command_dispatch:
	push.w {r4, r5, r6, r7, r8, r9, lr}
	sub sp, #4
	mov r4, r0
	ldr r0, [r0, #4]
	ldr r7, [r0, #0x24]
	movw r0, #0x102f
	ldrb r0, [r7, r0]
	cmp r0, #0x5a
	bhi.w .L08030300
	movw r1, #0x1028
	adds r5, r7, r1
	tbh [pc, r0, lsl #1]
.L0803022e:
	.short (.L080302e4 - .L0803022e)/2	@ opcode 0x00
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x01
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x02
	.short (.L08030314 - .L0803022e)/2	@ opcode 0x03
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x04
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x05
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x06
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x07
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x08
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x09
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x0a
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x0b
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x0c
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x0d
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x0e
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x0f
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x10
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x11
	.short (.L08030354 - .L0803022e)/2	@ opcode 0x12
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x13
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x14
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x15
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x16
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x17
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x18
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x19
	.short (.L08030384 - .L0803022e)/2	@ opcode 0x1a
	.short (.L08030390 - .L0803022e)/2	@ opcode 0x1b
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x1c
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x1d
	.short (.L08030396 - .L0803022e)/2	@ opcode 0x1e
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x1f
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x20
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x21
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x22
	.short (.L0803039c - .L0803022e)/2	@ opcode 0x23
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x24
	.short (.L080303d2 - .L0803022e)/2	@ opcode 0x25
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x26
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x27
	.short (.L08030402 - .L0803022e)/2	@ opcode 0x28
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x29
	.short (.L08030428 - .L0803022e)/2	@ opcode 0x2a
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x2b
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x2c
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x2d
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x2e
	.short (.L0803046e - .L0803022e)/2	@ opcode 0x2f
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x30
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x31
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x32
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x33
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x34
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x35
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x36
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x37
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x38
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x39
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x3a
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x3b
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x3c
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x3d
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x3e
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x3f
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x40
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x41
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x42
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x43
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x44
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x45
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x46
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x47
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x48
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x49
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x4a
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x4b
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x4c
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x4d
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x4e
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x4f
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x50
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x51
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x52
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x53
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x54
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x55
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x56
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x57
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x58
	.short (.L08030300 - .L0803022e)/2	@ opcode 0x59
	.short (.L080304aa - .L0803022e)/2	@ opcode 0x5a
.L080302e4:				@ opcode 0x00 TEST UNIT READY
	ldr r0, [r5]
	cmp r0, #0
	beq.w .L080305c8
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x20
	strb r1, [r0, #0x10]
	movs r5, #1
	b.n .L080307ee
.L08030300:				@ unknown opcode: error 5 / 0x20
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x20
	movs r5, #1
	strb r1, [r0, #0x10]
	b.n .L080307ee
.L08030314:				@ opcode 0x03 REQUEST SENSE: copy 0x20000018..0x20000029
	movw r0, #0x18
	movt r0, #0x2000
	ldrb r1, [r0, #0x11]
	ldr.w r2, [r0, #9]
	strb.w r1, [r7, #0x2d]
	ldr.w r1, [r0, #0xd]
	str.w r2, [r7, #0x25]
	str.w r1, [r7, #0x29]
	ldr.w r1, [r0, #5]
	ldr.w r2, [r0, #1]
	str.w r1, [r7, #0x21]
	ldrb r0, [r0]
	ldr r1, [r5]
	str.w r2, [r7, #0x1d]
	strb r0, [r7, #0x1c]
	cmp r1, #0x12
	it cs
	movcs r1, #0x12
	str r1, [r7, #0x18]
	movs r5, #0
	b.n .L080307ee
.L08030354:				@ opcode 0x12 INQUIRY
	ldrb r0, [r5, #8]
	lsls r0, r0, #0x1f
	bne.w .L080304be
	ldrb r1, [r5, #5]
	ldr r2, [r5]
	movs r0, #0
	cmp r1, #0
	add.w r3, r1, r1, lsl #3
	adr.w r6, .L08030838
	it eq
	addeq.w r0, r6, r3, lsl #2
	cmp r2, #0x24
	bcs.w .L080305ce
	cmp r2, #0
	str r2, [r7, #0x18]
	bne.w .L080305d2
	movs r5, #0
	b.n .L080307ee
.L08030384:				@ opcode 0x1a: length 8, response bytes 0
	movs r0, #8
	movs r5, #0
	str r0, [r7, #0x18]
	str r5, [r7, #0x20]
	str r5, [r7, #0x1c]
	b.n .L080307ee
.L08030390:				@ opcode 0x1b: length 0
	movs r5, #0
	str r5, [r7, #0x18]
	b.n .L080307ee
.L08030396:				@ opcode 0x1e: length 0
	movs r5, #0
	str r5, [r7, #0x18]
	b.n .L080307ee
.L0803039c:				@ opcode 0x23 READ FORMAT CAPACITIES
	ldrb r0, [r5, #5]
	mov.w r1, #0x8000000
	str r1, [r7, #0x1c]
	add.w r1, r7, r0, lsl #2
	add.w r5, r1, #8
	cmp r0, #0
	add.w r4, r1, #0xc
	bne.w .L08030750
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf6e]
	cmp r0, #0
	beq.w .L08030738
	nop.w
	mov.w r6, #0x200
	b.n .L08030740
.L080303d2:				@ opcode 0x25 READ CAPACITY
	ldrb r0, [r5, #5]
	add.w r1, r7, r0, lsl #2
	add.w r5, r1, #8
	cmp r0, #0
	add.w r4, r1, #0xc
	bne.w .L080307b0
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf6e]
	cmp r0, #0
	beq.w .L08030798
	nop.w
	mov.w r6, #0x200
	b.n .L080307a0
.L08030402:				@ opcode 0x28 READ(10)
	ldrb r1, [r7]
	ldrb r0, [r5, #5]
	cmp r1, #7
	bne.n .L080304ca
	ldrsb.w r1, [r5, #4]
	cmp r1, #0
	bmi.w .L080306aa
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x20
	strb r1, [r0, #0x10]
	movs r5, #1
	b.n .L080307ee
.L08030428:				@ opcode 0x2a WRITE(10)
	ldrb r1, [r7]
	ldrb r0, [r5, #5]
	cmp r1, #7
	bne.n .L08030528
	ldrsb.w r1, [r5, #4]
	cmp.w r1, #-1
	ble.w .L0803063a
	ldr.w r1, [r5, #9]
	ldrh r3, [r5, #0xe]
	rev r2, r1
	lsls r1, r3, #0x10
	rev r1, r1
	strd r2, r1, [r7, #0x10]
	add.w r0, r7, r0, lsl #2
	ldr r3, [r0, #8]
	adds r6, r1, r2
	cmp r6, r3
	bls.w .L080306de
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x21
	strb r1, [r0, #0x10]
	movs r5, #1
	b.n .L080307ee
.L0803046e:				@ opcode 0x2f VERIFY(10)
	ldrb r0, [r5, #8]
	lsls r0, r0, #0x1e
	bmi.w .L080305b4
	ldrh r2, [r5, #0xe]
	ldr.w r1, [r5, #9]
	ldrb r0, [r5, #5]
	lsls r2, r2, #0x10
	rev r1, r1
	rev r2, r2
	strd r1, r2, [r7, #0x10]
	add.w r0, r7, r0, lsl #2
	ldr r0, [r0, #8]
	add r1, r2
	cmp r1, r0
	bls.w .L08030634
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x21
	strb r1, [r0, #0x10]
	movs r5, #1
	b.n .L080307ee
.L080304aa:				@ opcode 0x5a: length 8, byte +0x1d = 6
	movs r0, #8
	str r0, [r7, #0x18]
	movs r5, #0
	mov.w r0, #0x600
	str.w r5, [r7, #0x1e]
	strh r5, [r7, #0x22]
	strh r0, [r7, #0x1c]
	b.n .L080307ee
.L080304be:				@ inquiry with bit0 set: 5 bytes from 0x0804bce8
	movw r0, #:lower16:d_0804bce8
	movt r0, #:upper16:d_0804bce8
	movs r2, #5
	b.n .L080305d0
.L080304ca:				@ read: next chunk of min(remaining, 0x1000)
	ldrd r1, r2, [r7, #0x10]
.L080304ce:
	mov.w r6, #0x1000
	cmp.w r2, #0x1000
	str r6, [r7, #0x18]
	it cc
	movcc r6, r2
	add.w r8, r7, #0x1c
	cbnz r0, .L080304fe
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf6e]
	uxth r2, r6
	cmp r0, #0
	mov r0, r8
	it eq
	addeq.w r1, r1, #0x200000
	bl serial_device_read
.L080304fe:
	uxth r3, r6
	mov r0, r4
	movs r1, #0x81
	mov r2, r8
	bl fn_08040eb4
	ldrd r0, r1, [r7, #0x10]
	add r0, r6
	str r0, [r7, #0x10]
	ldr r0, [r5, #0x20]
	subs r1, r1, r6
	sub.w r0, r0, r6
	str r1, [r7, #0x14]
	str r0, [r5, #0x20]
	itt eq
	moveq r0, #4
	strbeq r0, [r7]
	movs r5, #0
	b.n .L080307ee
.L08030528:				@ write: arm reception of the next chunk
	ldrd r1, r2, [r7, #0x10]
	mov.w r6, #0x1000
	cmp.w r2, #0x1000
	it cc
	uxthcc r6, r2
	add.w r8, r7, #0x1c
	cbnz r0, .L0803055e
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf6e]
	mov r2, r6
	cmp r0, #0
	mov r0, r8
	it eq
	addeq.w r1, r1, #0x200000
	bl serial_device_write_merge
	ldrd r1, r2, [r7, #0x10]
.L0803055e:
	add r1, r6
	str r1, [r7, #0x10]
	ldr r1, [r5, #0x20]
	movw r9, #0x5c04
	movt r9, #0x4000
	subs r0, r2, r6
	sub.w r1, r1, r6
	str r0, [r7, #0x14]
	str r1, [r5, #0x20]
	beq.n .L0803064e
	cmp.w r0, #0x1000
	it cs
	movcs.w r0, #0x1000
	ldrh.w r1, [r4, #0x134]
	uxth r0, r0
	movs r5, #0
	str.w r8, [r4, #0x140]
	strh.w r5, [r4, #0x13c]
	cmp r0, r1
	it ls
	movls r0, r1
	subs r0, r0, r1
	strh.w r0, [r4, #0x13a]
	ldr.w r0, [r9]
	movw r1, #0x3f0f
	ands r0, r1
	movw r1, #0xb080
	eors r0, r1
	str.w r0, [r9]
	b.n .L080307ee
.L080305b4:				@ verify with bit1 set: error 5 / 0x24
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x24
	strb r1, [r0, #0x10]
	movs r5, #1
	b.n .L080307ee
.L080305c8:
	movs r5, #0
	str r5, [r7, #0x18]
	b.n .L080307ee
.L080305ce:
	movs r2, #0x24
.L080305d0:
	str r2, [r7, #0x18]
.L080305d2:				@ byte copy of r2 bytes from r0 to cb+0x1c
	ands.w r6, r2, #3
	sub.w r3, r2, #1
	beq.n .L080305fe
	ldrb r1, [r0, r3]
	adds r5, r7, r3
	strb r1, [r5, #0x1c]
	cmp r6, #1
	mov r1, r3
	beq.n .L08030600
	subs r1, r2, #2
	ldrb r5, [r0, r1]
	adds r4, r7, r1
	cmp r6, #2
	strb r5, [r4, #0x1c]
	beq.n .L08030600
	subs r1, r2, #3
	ldrb r2, [r0, r1]
	adds r6, r7, r1
	strb r2, [r6, #0x1c]
	b.n .L08030600
.L080305fe:
	mov r1, r2
.L08030600:
	cmp r3, #3
	bcs.n .L08030608
	movs r5, #0
	b.n .L080307ee
.L08030608:
	subs r0, #2
	movs r2, #0
.L0803060c:
	adds r3, r0, r1
	ldrb r6, [r3, #1]
	adds r5, r7, r1
	strb r6, [r5, #0x1b]
	ldrb r6, [r0, r1]
	adds r2, #4
	strb r6, [r5, #0x1a]
	ldrb.w r6, [r3, #-1]
	subs r7, #4
	strb r6, [r5, #0x19]
	ldrb.w r3, [r3, #-2]
	cmp r1, r2
	sub.w r0, r0, #4
	strb r3, [r5, #0x18]
	bne.n .L0803060c
	movs r5, #0
	b.n .L080307ee
.L08030634:
	movs r5, #0
	str r5, [r7, #0x18]
	b.n .L080307ee
.L0803063a:				@ write with direction bit7 set: error 5 / 0x20
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x20
	strb r1, [r0, #0x10]
	movs r5, #1
	b.n .L080307ee
.L0803064e:				@ all data written: send the 13-byte status block
	ldr r0, [r4, #4]
	movw r1, #0x5355
	ldr r6, [r0, #0x24]
	mov.w r0, #0x1040
	movt r1, #0x5342
	str r1, [r6, r0]
	movs r0, #7
	add.w r2, r6, #0x1040
	movs r5, #0
	strb r0, [r6]
	mov r0, r4
	movs r1, #0x81
	movs r3, #0xd
	str r5, [r2, #0xc]
	bl fn_08040eb4
	add.w r0, r6, #0x1020
	str.w r0, [r4, #0x140]
	ldrh.w r0, [r4, #0x134]
	strh.w r5, [r4, #0x13c]
	mov r1, r0
	cmp r0, #0x1f
	it ls
	movls r1, #0x1f
	subs r0, r1, r0
	strh.w r0, [r4, #0x13a]
	ldr.w r0, [r9]
	movw r1, #0x3f0f
	ands r0, r1
	movw r1, #0xb080
	eors r0, r1
	str.w r0, [r9]
	b.n .L080307ee
.L080306aa:				@ first read call: decode block address and count
	ldrh r2, [r5, #0xe]
	ldr.w r1, [r5, #9]
	lsls r2, r2, #0x10
	rev r1, r1
	rev r2, r2
	strd r1, r2, [r7, #0x10]
	add.w r3, r7, r0, lsl #2
	ldr.w r12, [r3, #8]
	adds r6, r2, r1
	cmp r6, r12
	bls.w .L080307f6
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x21
	strb r1, [r0, #0x10]
	movs r5, #1
	b.n .L080307ee
.L080306de:				@ first write call: multiply by block size, arm reception
	ldr r3, [r0, #0xc]
	muls r2, r3, r2
	str r2, [r7, #0x10]
	ldr r0, [r0, #0xc]
	ldr r2, [r5]
	muls r0, r1, r0
	cmp r2, r0
	str r0, [r7, #0x14]
	bne.w .L0803080e
	movs r1, #2
	strb.w r1, [r7], #0x1c
	cmp.w r0, #0x1000
	it cs
	movcs.w r0, #0x1000
	ldrh.w r1, [r4, #0x134]
	uxth r0, r0
	movs r5, #0
	str.w r7, [r4, #0x140]
	strh.w r5, [r4, #0x13c]
	cmp r0, r1
	it ls
	movls r0, r1
	subs r0, r0, r1
	strh.w r0, [r4, #0x13a]
	movw r0, #0x5c04
	movt r0, #0x4000
	ldr r1, [r0]
	movw r2, #0x3f0f
	ands r1, r2
	movw r2, #0xb080
	eors r1, r2
	str r1, [r0]
	b.n .L080307ee
.L08030738:
	nop.w
	mov.w r6, #0xe00
.L08030740:
	nop.w
	str r6, [r5]
	nop.w
	mov.w r0, #0x1000
	str r0, [r4]
.L08030750:				@ read format capacities response
	ldr r0, [r5]
	subs r0, #1
	lsrs r0, r0, #0x18
	strb.w r0, [r7, #0x20]
	ldr r0, [r5]
	ldrb r1, [r5]
	subs r0, #1
	lsrs r0, r0, #0x10
	strb.w r0, [r7, #0x21]
	ldr r0, [r5]
	movs r5, #0
	subs r0, #1
	lsrs r0, r0, #8
	strb.w r0, [r7, #0x22]
	subs r0, r1, #1
	strb.w r0, [r7, #0x23]
	movs r0, #2
	strb.w r0, [r7, #0x24]
	ldrh r0, [r4, #2]
	strb.w r0, [r7, #0x25]
	ldr r0, [r4]
	lsrs r0, r0, #8
	strb.w r0, [r7, #0x26]
	ldr r0, [r4]
	strb.w r0, [r7, #0x27]
	movs r0, #0xc
	str r0, [r7, #0x18]
	b.n .L080307ee
.L08030798:
	nop.w
	mov.w r6, #0xe00
.L080307a0:
	nop.w
	str r6, [r5]
	nop.w
	mov.w r0, #0x1000
	str r0, [r4]
.L080307b0:				@ read capacity response
	ldr r0, [r5]
	subs r0, #1
	lsrs r0, r0, #0x18
	strb r0, [r7, #0x1c]
	ldr r0, [r5]
	ldrb r1, [r5]
	subs r0, #1
	lsrs r0, r0, #0x10
	strb r0, [r7, #0x1d]
	ldr r0, [r5]
	movs r5, #0
	subs r0, #1
	lsrs r0, r0, #8
	strb r0, [r7, #0x1e]
	subs r0, r1, #1
	strb r0, [r7, #0x1f]
	ldrb r0, [r4, #3]
	strb.w r0, [r7, #0x20]
	ldrh r0, [r4, #2]
	strb.w r0, [r7, #0x21]
	ldr r0, [r4]
	lsrs r0, r0, #8
	strb.w r0, [r7, #0x22]
	ldr r0, [r4]
	strb.w r0, [r7, #0x23]
	movs r0, #8
	str r0, [r7, #0x18]
.L080307ee:				@ common exit: r0 = r5 (0 accepted, 1 error)
	mov r0, r5
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L080307f6:				@ first read call: multiply, check against CBW length
	ldr r6, [r3, #0xc]
	muls r1, r6, r1
	str r1, [r7, #0x10]
	ldr r3, [r3, #0xc]
	ldr r6, [r5]
	muls r2, r3, r2
	cmp r6, r2
	str r2, [r7, #0x14]
	bne.n .L08030822
	movs r3, #1
	strb r3, [r7]
	b.n .L080304ce
.L0803080e:
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x20
	strb r1, [r0, #0x10]
	movs r5, #1
	b.n .L080307ee
.L08030822:
	movw r0, #0x18
	movt r0, #0x2000
	movs r1, #5
	strb r1, [r0, #2]
	movs r1, #0x20
	strb r1, [r0, #0x10]
	movs r5, #1
	b.n .L080307ee
	.byte 0x00, 0xbf	@ padding
.L08030838:				@ 36-byte inquiry record
	.byte 0x00, 0x80, 0x00, 0x01, 0x1f, 0x00, 0x00, 0x00
	.byte 0x41, 0x54, 0x33, 0x32, 0x20, 0x20, 0x20, 0x20
	.byte 0x44, 0x69, 0x73, 0x6b, 0x30, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x32
	.byte 0x2e, 0x30, 0x30

@ ----------------------------------------------------------------------------
@ fn_08030ca0 - param_1 (r0) = device structure; returns 0.
@ Calls 08040874(param_1, 0x81) then 08040874(param_1, 1) (the endpoint indices
@ 0x81 and 1; 0x81 is also the index passed to 08040eb4 by 0803020c and
@ 08030cc4). No other effect. Purpose not determined from the code.
@ A 2-byte zero padding follows the final pop (never reached, no reference).
@ ----------------------------------------------------------------------------
	.section .text.fn_08030ca0,"ax",%progbits
	.p2align 2
	.global fn_08030ca0
	.thumb_func
	.type fn_08030ca0, %function
fn_08030ca0:
	push {r4, lr}
	movs r1, #0x81
	mov r4, r0
	bl fn_08040874
	mov r0, r4
	movs r1, #1
	bl fn_08040874
	movs r0, #0
	pop {r4, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ return_zero_08030cb8 - returns 0; no parameters, no memory access.
@ ----------------------------------------------------------------------------
	.section .text.return_zero_08030cb8,"ax",%progbits
	.p2align 2
	.global return_zero_08030cb8
	.thumb_func
	.type return_zero_08030cb8, %function
return_zero_08030cb8:
	movs r0, #0
	bx lr

@ ----------------------------------------------------------------------------
@ return_zero_08030cbc - returns 0; no parameters, no memory access.
@ ----------------------------------------------------------------------------
	.section .text.return_zero_08030cbc,"ax",%progbits
	.p2align 2
	.global return_zero_08030cbc
	.thumb_func
	.type return_zero_08030cbc, %function
return_zero_08030cbc:
	movs r0, #0
	bx lr

@ ----------------------------------------------------------------------------
@ return_zero_08030cc0 - returns 0; no parameters, no memory access.
@ ----------------------------------------------------------------------------
	.section .text.return_zero_08030cc0,"ax",%progbits
	.p2align 2
	.global return_zero_08030cc0
	.thumb_func
	.type return_zero_08030cc0, %function
return_zero_08030cc0:
	movs r0, #0
	bx lr

@ ----------------------------------------------------------------------------
@ send_status_block_after_data - param_1 (r0) = device structure; returns 0
@ always. cb = *(word at *(param_1+4) + 0x24).
@ If cb[0] is 3 or 4 (response or read data sent): writes bytes
@ 0x55,0x53,0x42,0x53 at cb+0x1040, cb[0] = 7, zeroes the dword at cb+0x104c
@ (status 0), sends the 13 bytes with 08040eb4(param_1,0x81,cb+0x1040,0xd),
@ then arms reception: [param_1+0x140] = cb+0x1020, [param_1+0x13c] = 0,
@ [param_1+0x13a] = max(ushort [param_1+0x134], 0x1f) - ushort [param_1+0x134],
@ word 0x40005c04 = (x & 0x3f0f) ^ 0xb080 (a store of the masked and xored
@ value, not an xor of the register).
@ Else if cb[0] == 1 (read in progress) and 0803020c(param_1) != 0 (error):
@ dword cb+0x104c = 1, dword cb+0x1040 = 0x53425355, cb[0] = 7, same send and
@ re-arm.
@ Else (cb[0] == 1 and 0803020c returned 0, or any other state) nothing more;
@ the next read chunk is sent inside 0803020c.
@ ----------------------------------------------------------------------------
	.section .text.send_status_block_after_data,"ax",%progbits
	.p2align 2
	.global send_status_block_after_data
	.thumb_func
	.type send_status_block_after_data, %function
send_status_block_after_data:
	push {r4, r5, r6, lr}
	mov r4, r0
	ldr r0, [r0, #4]
	ldr r5, [r0, #0x24]
	ldrb r0, [r5]
	subs r1, r0, #3
	cmp r1, #2
	bcs.n .L08030d2e
	movw r0, #0x5355
	add.w r2, r5, #0x1040
	movt r0, #0x5342
	str r0, [r2]
	movs r0, #7
	movs r6, #0
	strb r0, [r5]
	mov r0, r4
	movs r1, #0x81
	movs r3, #0xd
	str r6, [r2, #0xc]
	bl fn_08040eb4
	add.w r0, r5, #0x1020
	str.w r0, [r4, #0x140]
	ldrh.w r0, [r4, #0x134]
	strh.w r6, [r4, #0x13c]
	mov r1, r0
	cmp r0, #0x1f
	it ls
	movls r1, #0x1f
	subs r0, r1, r0
	strh.w r0, [r4, #0x13a]
	movw r0, #0x5c04
	movt r0, #0x4000
	ldr r1, [r0]
	movw r2, #0x3f0f
	ands r1, r2
	movw r2, #0xb080
	eors r1, r2
	str r1, [r0]
.L08030d2a:
	movs r0, #0
	pop {r4, r5, r6, pc}
.L08030d2e:
	cmp r0, #1
	bne.n .L08030d2a
	mov r0, r4
	bl scsi_command_dispatch
	cmp r0, #0
	beq.n .L08030d2a
	ldr r0, [r4, #4]
	movw r1, #0x5355
	ldr r5, [r0, #0x24]
	movs r0, #1
	add.w r2, r5, #0x1040
	str r0, [r2, #0xc]
	mov.w r0, #0x1040
	movt r1, #0x5342
	str r1, [r5, r0]
	movs r0, #7
	strb r0, [r5]
	mov r0, r4
	movs r1, #0x81
	movs r3, #0xd
	bl fn_08040eb4
	add.w r0, r5, #0x1020
	ldrh.w r1, [r4, #0x134]
	str.w r0, [r4, #0x140]
	movs r0, #0
	strh.w r0, [r4, #0x13c]
	mov r0, r1
	cmp r1, #0x1f
	it ls
	movls r0, #0x1f
	subs r0, r0, r1
	strh.w r0, [r4, #0x13a]
	movw r0, #0x5c04
	movt r0, #0x4000
	ldr r1, [r0]
	movw r2, #0x3f0f
	ands r1, r2
	movw r2, #0xb080
	eors r1, r2
	str r1, [r0]
	movs r0, #0
	pop {r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ init_state_arm_command_receive - param_1 (r0) = device structure; returns 0.
@ Calls 08040b24(param_1,0x81,1) and 08040b24(param_1,1,1);
@ p = *(word at *(param_1+4) + 0x24); stores ushort p[0] = 7 (state 7 = waiting
@ for a command block, stall byte p[1] = 0), zeroes dword p+4 and dwords
@ p+0x1040, p+0x1044, p+0x1048; arms reception at p+0x1020:
@ [param_1+0x140] = p+0x1020, [param_1+0x13c] = 0, [param_1+0x13a] =
@ max(ushort [param_1+0x134], 0x1f) - ushort [param_1+0x134];
@ word 0x40005c04 = (x & 0x3f0f) ^ 0xb080.
@ A 2-byte zero padding follows the final pop (never reached, no reference).
@ ----------------------------------------------------------------------------
	.section .text.init_state_arm_command_receive,"ax",%progbits
	.p2align 2
	.global init_state_arm_command_receive
	.thumb_func
	.type init_state_arm_command_receive, %function
init_state_arm_command_receive:
	push {r4, lr}
	movs r1, #0x81
	movs r2, #1
	mov r4, r0
	bl fn_08040b24
	mov r0, r4
	movs r1, #1
	movs r2, #1
	bl fn_08040b24
	ldr r0, [r4, #4]
	movs r2, #7
	ldr r0, [r0, #0x24]
	mov.w r3, #0x1040
	strh r2, [r0]
	movs r2, #0
	add.w r1, r0, #0x1040
	str r2, [r0, #4]
	str r2, [r0, r3]
	add.w r0, r0, #0x1020
	str.w r0, [r4, #0x140]
	ldrh.w r0, [r4, #0x134]
	strd r2, r2, [r1, #4]
	mov r1, r0
	strh.w r2, [r4, #0x13c]
	cmp r0, #0x1f
	it ls
	movls r1, #0x1f
	subs r0, r1, r0
	movw r1, #0x5c04
	strh.w r0, [r4, #0x13a]
	movt r1, #0x4000
	ldr r0, [r1]
	movw r2, #0x3f0f
	ands r0, r2
	movw r2, #0xb080
	eors r2, r0
	movs r0, #0
	str r2, [r1]
	pop {r4, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ handle_command_block_or_write_data - param_1 (r0) = device structure; returns
@ 0 always. cb = *(word at *(param_1+4) + 0x24).
@ cb[0] == 2 (write data received): calls 0803020c; if it returns nonzero
@ writes the 13-byte status (dword +0x104c = 1, dword +0x1040 = 0x53425355,
@ cb[0] = 7), sends it with 08040eb4(param_1,0x81,..,0xd) and re-arms
@ reception (as 08030cc4).
@ cb[0] == 7 (command block received): copies dword cb+0x1024 to cb+0x1044
@ (tag) and dword cb+0x1028 to cb+0x1048 (residue); if dword cb+0x1020 ==
@ 0x43425355, ushort [param_1+0x13c] == 0x1f, cb[0x102d] < 2 and
@ cb[0x102e]-1 < 0x10: calls 0803020c: result 0: when cb[0] is not 1, 2 or 4
@ (mask 0x16) either sends the 13-byte status with status dword 0 if the
@ response length dword cb+0x18 == 0 (cb[0] = 7, re-arm) or reduces residue
@ +0x1048 by min(dword +0x1028, cb+0x18) (low 16 bits), status dword +0x104c =
@ 0, cb[0] = 3 and sends the response with 08040eb4(param_1,0x81,cb+0x1c,count);
@ result nonzero: when dword +0x1028 != 0, flags byte +0x102c == 0 and cb[1] ==
@ 0 stalls the OUT endpoint (word 0x40005c00+4*byte [param_1+0x12c] = (x &
@ 0x3f0f) ^ 0x9080, byte [param_1+0x137] = 1), then stalls the IN endpoint
@ (word 0x40005c00+4*byte [param_1+0x2c] = (x & 0xf3f) ^ 0x8090, byte
@ [param_1+0x37] = 1), and if cb[1] == 2 re-arms reception at cb+0x1020.
@ Invalid header: byte 0x2000001a = 5, byte 0x20000028 = 0x20, cb[1] = 2,
@ stalls the IN endpoint as above, byte [param_1+0x37] = 1, re-arms reception
@ at cb+0x1020 (word 0x40005c04 = (x & 0x3f0f) ^ 0xb080).
@ Purpose: acts on state cb[0] == 2 (write data received) or cb[0] == 7
@ (command block received); the event that calls this function is not
@ determined from this function.
@ ----------------------------------------------------------------------------
	.section .text.handle_command_block_or_write_data,"ax",%progbits
	.p2align 2
	.global handle_command_block_or_write_data
	.thumb_func
	.type handle_command_block_or_write_data, %function
handle_command_block_or_write_data:
	push {r4, r5, r6, r7, lr}
	sub sp, #4
	mov r4, r0
	ldr r0, [r0, #4]
	ldr r5, [r0, #0x24]
	ldrb r0, [r5]
	cmp r0, #2
	beq.n .L08030ec6
	cmp r0, #7
	bne.w .L08030f2e
	add.w r0, r5, #0x1020
	movw r6, #0x5355
	movt r6, #0x5342
	ldm.w r0, {r1, r2, r3}
	str r2, [r0, #0x24]
	add.w r2, r6, #0xf0000000
	cmp r1, r2
	str r3, [r0, #0x28]
	bne.n .L08030e54
	ldrh.w r1, [r4, #0x13c]
	cmp r1, #0x1f
	bne.n .L08030e54
	ldrb r1, [r0, #0xd]
	cmp r1, #1
	bhi.n .L08030e54
	ldrb r1, [r0, #0xe]
	subs r1, #1
	cmp r1, #0x10
	bcc.n .L08030f34
.L08030e54:				@ invalid header
	movw r2, #0x18
	movt r2, #0x2000
	movs r3, #5
	strb r3, [r2, #2]
	movs r3, #0x20
	movw r1, #0x5c04
	strb r3, [r2, #0x10]
	ldrb.w r3, [r4, #0x2c]
	movt r1, #0x4000
	movs r2, #2
	strb r2, [r5, #1]
	add.w r2, r1, r3, lsl #2
	ldr.w r3, [r2, #-4]
	movw r6, #0xf3f
	ands r3, r6
	movw r6, #0x8090
	eors r3, r6
	str.w r3, [r2, #-4]
	ldrb r2, [r5, #1]
	movs r3, #1
	cmp r2, #2
	strb.w r3, [r4, #0x37]
	bne.n .L08030f2e
	ldrh.w r2, [r4, #0x134]
	str.w r0, [r4, #0x140]
	movs r0, #0
	strh.w r0, [r4, #0x13c]
	mov r0, r2
	cmp r2, #0x1f
	it ls
	movls r0, #0x1f
	subs r0, r0, r2
	strh.w r0, [r4, #0x13a]
	ldr r0, [r1]
	movw r2, #0x3f0f
	ands r0, r2
	movw r2, #0xb080
	eors r0, r2
	str r0, [r1]
	b.n .L08030f2e
.L08030ec6:				@ cb[0] == 2: write data received
	mov r0, r4
	bl scsi_command_dispatch
	cbz r0, .L08030f2e
	ldr r0, [r4, #4]
	movw r1, #0x5355
	ldr r5, [r0, #0x24]
	movs r0, #1
	add.w r2, r5, #0x1040
	str r0, [r2, #0xc]
	mov.w r0, #0x1040
	movt r1, #0x5342
	str r1, [r5, r0]
	movs r0, #7
	strb r0, [r5]
	mov r0, r4
	movs r1, #0x81
	movs r3, #0xd
	bl fn_08040eb4
	add.w r0, r5, #0x1020
	ldrh.w r1, [r4, #0x134]
	str.w r0, [r4, #0x140]
	movs r0, #0
	strh.w r0, [r4, #0x13c]
	mov r0, r1
	cmp r1, #0x1f
	it ls
	movls r0, #0x1f
	subs r0, r0, r1
	strh.w r0, [r4, #0x13a]
	movw r0, #0x5c04
	movt r0, #0x4000
	ldr r1, [r0]
	movw r2, #0x3f0f
	ands r1, r2
	movw r2, #0xb080
	eors r1, r2
	str r1, [r0]
.L08030f2e:
	movs r0, #0
	add sp, #4
	pop {r4, r5, r6, r7, pc}
.L08030f34:				@ valid command block
	mov r0, r4
	bl scsi_command_dispatch
	cmp r0, #0
	beq.n .L08030fda
	ldr r0, [r4, #4]
	movw r2, #0x1028
	ldr r1, [r0, #0x24]
	ldr r0, [r1, r2]
	cmp r0, #0
	movw r0, #0x5c04
	movt r0, #0x4000
	beq.n .L08030f80
	add r2, r1
	ldrb r2, [r2, #4]
	cbnz r2, .L08030f80
	ldrb r2, [r1, #1]
	cbnz r2, .L08030f80
	ldrb.w r2, [r4, #0x12c]
	movw r6, #0x3f0f
	add.w r2, r0, r2, lsl #2
	ldr.w r3, [r2, #-4]
	ands r3, r6
	movw r6, #0x9080
	eors r3, r6
	str.w r3, [r2, #-4]
	movs r2, #1
	strb.w r2, [r4, #0x137]
.L08030f80:
	ldrb.w r2, [r4, #0x2c]
	movw r6, #0xf3f
	add.w r2, r0, r2, lsl #2
	ldr.w r3, [r2, #-4]
	ands r3, r6
	movw r6, #0x8090
	eors r3, r6
	str.w r3, [r2, #-4]
	ldrb r2, [r1, #1]
	movs r3, #1
	cmp r2, #2
	strb.w r3, [r4, #0x37]
	bne.n .L08030f2e
	add.w r1, r1, #0x1020
	ldrh.w r2, [r4, #0x134]
	str.w r1, [r4, #0x140]
	movs r1, #0
	strh.w r1, [r4, #0x13c]
	mov r1, r2
	cmp r2, #0x1f
	it ls
	movls r1, #0x1f
	subs r1, r1, r2
	strh.w r1, [r4, #0x13a]
	ldr r1, [r0]
	movw r2, #0x3f0f
	ands r1, r2
	movw r2, #0xb080
	eors r1, r2
	str r1, [r0]
	b.n .L08030f2e
.L08030fda:				@ dispatch accepted the command
	ldrb r0, [r5]
	cmp r0, #4
	bhi.n .L08030fec
	movs r1, #1
	lsl.w r0, r1, r0
	tst.w r0, #0x16
	bne.n .L08030f2e
.L08030fec:
	ldr r0, [r5, #0x18]
	cbz r0, .L08031020
	ldr r1, [r4, #4]
	movw r3, #0x1028
	ldr r1, [r1, #0x24]
	add.w r2, r5, #0x1c
	ldr r7, [r1, r3]
	adds r6, r1, r3
	cmp r7, r0
	it hi
	movhi r7, r0
	ldr r0, [r6, #0x20]
	uxth r3, r7
	subs r0, r0, r3
	movs r7, #0
	strd r0, r7, [r6, #0x20]
	movs r0, #3
	strb r0, [r1]
	mov r0, r4
	movs r1, #0x81
	bl fn_08040eb4
	b.n .L08030f2e
.L08031020:				@ response length 0: send the status block directly
	ldr r0, [r4, #4]
	movs r7, #0
	ldr r5, [r0, #0x24]
	mov.w r0, #0x1040
	str r6, [r5, r0]
	movs r0, #7
	add.w r2, r5, #0x1040
	strb r0, [r5]
	mov r0, r4
	movs r1, #0x81
	movs r3, #0xd
	str r7, [r2, #0xc]
	bl fn_08040eb4
	add.w r0, r5, #0x1020
	str.w r0, [r4, #0x140]
	ldrh.w r0, [r4, #0x134]
	strh.w r7, [r4, #0x13c]
	mov r1, r0
	cmp r0, #0x1f
	it ls
	movls r1, #0x1f
	subs r0, r1, r0
	strh.w r0, [r4, #0x13a]
	movw r0, #0x5c04
	movt r0, #0x4000
	ldr r1, [r0]
	movw r2, #0x3f0f
	ands r1, r2
	movw r2, #0xb080
	eors r1, r2
	str r1, [r0]
	b.n .L08030f2e

@ ----------------------------------------------------------------------------
@ msc_control_request_handler - control-request handler of the bulk-only
@ mass-storage function (class requests 0xfe and 0xff, base requests 1, 6, 10,
@ 11). param_1 (r0) = device structure, param_2 (r1) = pointer to the 8-byte
@ setup request (byte 0 type, byte 1 request, ushort at +2 wValue, byte 4
@ wIndex low); returns 0 always; p = *(word at *(param_1+4) + 0x24).
@ Type & 0x60 == 0 (base requests):
@  request 1: calls 08040874(param_1, wIndex low) and 08040b24(param_1, wIndex
@   low, 1); if p[1] == 2 clears the IN stall (word 0x40005c00+4*byte
@   [param_1+0x2c] = (x & 0xf3f) ^ 0x8090, byte [param_1+0x37] = 1, p[1] = 0),
@   else if bit7 of wIndex low is set and p[1] != 1 writes a failed status
@   (dword p+0x104c = 1, dword p+0x1040 = 0x53425355, p[0] = 7), sends 13 bytes
@   with 08040eb4(param_1,0x81,..,0xd) and re-arms reception at p+0x1020 (word
@   0x40005c04 = (x & 0x3f0f) ^ 0xb080).
@  request 6: stalls endpoint 0 in both directions (word 0x40005c00+4*byte
@   [param_1+0x10c] = (x & 0x3f0f) ^ 0x9080 with byte [param_1+0x117] = 1, word
@   0x40005c00+4*byte [param_1+0xc] = (x & 0xf3f) ^ 0x8090 with byte
@   [param_1+0x17] = 1).
@  request 10: sets dword [param_1+0x26] = 0x10001, byte [param_1+0x220] = 2
@   and sends 1 byte from p+0x101c with 08040eb4(param_1,0,p+0x101c,1).
@  request 11: stores wValue (ushort at +2) as dword at p+0x101c.
@  other requests: nothing.
@ Type & 0x60 == 0x20 (class):
@  request 0xff: sets ushort p[0] = 0x107, dword p+4 = 0, re-arms reception at
@   p+0x1020 as above, byte [param_1+0x220] = 4, calls
@   08040eb4(param_1,0,0,0).
@  request 0xfe: sets dword [param_1+0x26] = 0x10001, byte [param_1+0x220] = 2
@   and sends 1 byte from p+4 (value 0 after 08030da0) with
@   08040eb4(param_1,0,p+4,1).
@  any other class request stalls endpoint 0 as in request 6.
@ Any other type stalls endpoint 0 as in request 6.
@ The tbh table at 080310c6 has 11 entries (request - 1, requests 1..11).
@ ----------------------------------------------------------------------------
	.section .text.msc_control_request_handler,"ax",%progbits
	.p2align 2
	.global msc_control_request_handler
	.thumb_func
	.type msc_control_request_handler, %function
msc_control_request_handler:
	push {r4, r5, r6, r7, lr}
	sub sp, #4
	mov r4, r0
	ldr r0, [r0, #4]
	mov r5, r1
	ldrb r1, [r1]
	ldr r0, [r0, #0x24]
	ands.w r1, r1, #0x60
	beq.n .L080310b8
	cmp r1, #0x20
	bne.n .L08031126
	ldrb r1, [r5, #1]
	cmp r1, #0xff
	beq.n .L08031166
	cmp r1, #0xfe
	bne.w .L080311ba
	adds r2, r0, #4
	mov.w r0, #0x10001
	str.w r0, [r4, #0x26]
	movs r0, #2
	strb.w r0, [r4, #0x220]
	mov r0, r4
	movs r1, #0
	movs r3, #1
	bl fn_08040eb4
	b.n .L080312ca
.L080310b8:				@ base requests
	ldrb r1, [r5, #1]
	subs r1, #1
	cmp r1, #0xa
	bhi.w .L080312ca
	tbh [pc, r1, lsl #1]
.L080310c6:
	.short (.L080310dc - .L080310c6)/2	@ request 1
	.short (.L080312ca - .L080310c6)/2	@ request 2
	.short (.L080312ca - .L080310c6)/2	@ request 3
	.short (.L080312ca - .L080310c6)/2	@ request 4
	.short (.L080312ca - .L080310c6)/2	@ request 5
	.short (.L080311fa - .L080310c6)/2	@ request 6
	.short (.L080312ca - .L080310c6)/2	@ request 7
	.short (.L080312ca - .L080310c6)/2	@ request 8
	.short (.L080312ca - .L080310c6)/2	@ request 9
	.short (.L0803123a - .L080310c6)/2	@ request 10
	.short (.L0803125a - .L080310c6)/2	@ request 11
.L080310dc:				@ request 1
	ldrb r1, [r5, #4]
	mov r0, r4
	bl fn_08040874
	ldrb r1, [r5, #4]
	mov r0, r4
	movs r2, #1
	movs r7, #1
	bl fn_08040b24
	ldr r0, [r4, #4]
	ldr r6, [r0, #0x24]
	ldrb r0, [r6, #1]
	cmp r0, #2
	bne.w .L08031264
	ldrb.w r0, [r4, #0x2c]
	movw r1, #0x5c00
	movt r1, #0x4000
	ldr.w r2, [r1, r0, lsl #2]
	movw r3, #0xf3f
	ands r2, r3
	movw r3, #0x8090
	eors r2, r3
	str.w r2, [r1, r0, lsl #2]
	movs r0, #0
	strb.w r7, [r4, #0x37]
	strb r0, [r6, #1]
	b.n .L080312ca
.L08031126:				@ any other type: stall endpoint 0
	ldrb.w r0, [r4, #0x10c]
	movw r1, #0x5c00
	movt r1, #0x4000
	ldr.w r2, [r1, r0, lsl #2]
	movw r3, #0x3f0f
	ands r2, r3
	movw r3, #0x9080
	eors r2, r3
	str.w r2, [r1, r0, lsl #2]
	movs r0, #1
	ldrb r2, [r4, #0xc]
	strb.w r0, [r4, #0x117]
	ldr.w r3, [r1, r2, lsl #2]
	movw r7, #0xf3f
	ands r3, r7
	movw r7, #0x8090
	eors r3, r7
	str.w r3, [r1, r2, lsl #2]
	strb r0, [r4, #0x17]
	b.n .L080312ca
.L08031166:				@ class request 0xff
	movw r1, #0x107
	strh r1, [r0]
	movs r1, #0
	str r1, [r0, #4]
	add.w r0, r0, #0x1020
	str.w r0, [r4, #0x140]
	ldrh.w r0, [r4, #0x134]
	strh.w r1, [r4, #0x13c]
	mov r1, r0
	cmp r0, #0x1f
	it ls
	movls r1, #0x1f
	subs r0, r1, r0
	strh.w r0, [r4, #0x13a]
	movw r0, #0x5c00
	movt r0, #0x4000
	ldr r1, [r0, #4]
	movw r2, #0x3f0f
	ands r1, r2
	movw r2, #0xb080
	eors r1, r2
	str r1, [r0, #4]
	movs r0, #4
	strb.w r0, [r4, #0x220]
	mov r0, r4
	movs r1, #0
	movs r2, #0
	movs r3, #0
	bl fn_08040eb4
	b.n .L080312ca
.L080311ba:				@ any other class request: stall endpoint 0
	ldrb.w r0, [r4, #0x10c]
	movw r1, #0x5c00
	movt r1, #0x4000
	ldr.w r2, [r1, r0, lsl #2]
	movw r3, #0x3f0f
	ands r2, r3
	movw r3, #0x9080
	eors r2, r3
	str.w r2, [r1, r0, lsl #2]
	movs r0, #1
	ldrb r2, [r4, #0xc]
	strb.w r0, [r4, #0x117]
	ldr.w r3, [r1, r2, lsl #2]
	movw r7, #0xf3f
	ands r3, r7
	movw r7, #0x8090
	eors r3, r7
	str.w r3, [r1, r2, lsl #2]
	strb r0, [r4, #0x17]
	b.n .L080312ca
.L080311fa:				@ base request 6: stall endpoint 0
	ldrb.w r0, [r4, #0x10c]
	movw r1, #0x5c00
	movt r1, #0x4000
	ldr.w r2, [r1, r0, lsl #2]
	movw r3, #0x3f0f
	ands r2, r3
	movw r3, #0x9080
	eors r2, r3
	str.w r2, [r1, r0, lsl #2]
	movs r0, #1
	ldrb r2, [r4, #0xc]
	strb.w r0, [r4, #0x117]
	ldr.w r3, [r1, r2, lsl #2]
	movw r7, #0xf3f
	ands r3, r7
	movw r7, #0x8090
	eors r3, r7
	str.w r3, [r1, r2, lsl #2]
	strb r0, [r4, #0x17]
	b.n .L080312ca
.L0803123a:				@ base request 10
	movw r1, #0x101c
	adds r2, r0, r1
	mov.w r0, #0x10001
	str.w r0, [r4, #0x26]
	movs r0, #2
	strb.w r0, [r4, #0x220]
	mov r0, r4
	movs r1, #0
	movs r3, #1
	bl fn_08040eb4
	b.n .L080312ca
.L0803125a:				@ base request 11: store wValue at p+0x101c
	ldrh r1, [r5, #2]
	movw r2, #0x101c
	str r1, [r0, r2]
	b.n .L080312ca
.L08031264:
	ldrsb.w r1, [r5, #4]
	cmp.w r1, #-1
	bgt.n .L080312ca
	cmp r0, #1
	beq.n .L080312ca
	add.w r2, r6, #0x1040
	movs r0, #1
	str r0, [r2, #0xc]
	movw r0, #0x5355
	movt r0, #0x5342
	str r0, [r2]
	movs r0, #7
	strb r0, [r6]
	mov r0, r4
	movs r1, #0x81
	movs r3, #0xd
	bl fn_08040eb4
	add.w r0, r6, #0x1020
	ldrh.w r1, [r4, #0x134]
	str.w r0, [r4, #0x140]
	movs r0, #0
	strh.w r0, [r4, #0x13c]
	mov r0, r1
	cmp r1, #0x1f
	it ls
	movls r0, #0x1f
	subs r0, r0, r1
	strh.w r0, [r4, #0x13a]
	movw r0, #0x5c00
	movt r0, #0x4000
	ldr r1, [r0, #4]
	movw r2, #0x3f0f
	ands r1, r2
	movw r2, #0xb080
	eors r1, r2
	str r1, [r0, #4]
.L080312ca:
	movs r0, #0
	add sp, #4
	pop {r4, r5, r6, r7, pc}

@ ----------------------------------------------------------------------------
@ return_zero_080312d0 - returns 0; no parameters, no memory access.
@ ----------------------------------------------------------------------------
	.section .text.return_zero_080312d0,"ax",%progbits
	.p2align 2
	.global return_zero_080312d0
	.thumb_func
	.type return_zero_080312d0, %function
return_zero_080312d0:
	movs r0, #0
	bx lr

@ ----------------------------------------------------------------------------
@ set_string_descriptor_mass_storage_config - fills the descriptor buffer at
@ 0x20005ec4 with a string descriptor: halfword 0x328 (length 0x28, type 3)
@ followed by the UTF-16 characters "Mass Storage Config" at 0x20005ec6..; sets
@ 0x20005fc4 = 0x28 and 0x20005fc8 = 0x20005ec4.
@ A 2-byte zero padding follows the final bx lr (never reached).
@ ----------------------------------------------------------------------------
	.section .text.set_string_descriptor_mass_storage_config,"ax",%progbits
	.p2align 2
	.global set_string_descriptor_mass_storage_config
	.thumb_func
	.type set_string_descriptor_mass_storage_config, %function
set_string_descriptor_mass_storage_config:
	movw r1, #0x5ec4
	movs r0, #0x4d
	movt r1, #0x2000
	movt r0, #0x61
	str.w r0, [r1, #2]
	mov.w r0, #0x730073
	str.w r0, [r1, #6]
	movs r0, #0x20
	movt r0, #0x53
	str.w r0, [r1, #0xa]
	movs r0, #0x74
	movt r0, #0x6f
	str.w r0, [r1, #0xe]
	movs r0, #0x72
	movt r0, #0x61
	str.w r0, [r1, #0x12]
	movs r0, #0x67
	movt r0, #0x65
	str.w r0, [r1, #0x16]
	movs r0, #0x20
	movt r0, #0x43
	str.w r0, [r1, #0x1a]
	movs r0, #0x6f
	movt r0, #0x6e
	str.w r0, [r1, #0x1e]
	movs r0, #0x66
	movt r0, #0x69
	str.w r0, [r1, #0x22]
	movs r0, #0x67
	strh r0, [r1, #0x26]
	mov.w r0, #0x328
	strh r0, [r1]
	movw r0, #0x5fc4
	movt r0, #0x2000
	movs r2, #0x28
	strh r2, [r0]
	str r1, [r0, #4]
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ get_configuration_descriptor_record - returns the constant address
@ 0x200000b0. The 8 bytes there (initial RAM image, unpacked from 0x080BE480 at reset) are the word
@ 0x00000020 and the pointer 0x200000b8, whose bytes begin 09 02 20 00 01 01 04
@ c0 32 (length 9, type 2, total length 0x20), followed at 0x200000c1 by 09 04
@ 00 00 02 08 06 50. Purpose: returns a record {length 0x20, pointer to the
@ configuration descriptor}.
@ A 2-byte zero padding follows the final bx lr (never reached).
@ ----------------------------------------------------------------------------
	.section .text.get_configuration_descriptor_record,"ax",%progbits
	.p2align 2
	.global get_configuration_descriptor_record
	.thumb_func
	.type get_configuration_descriptor_record, %function
get_configuration_descriptor_record:
	movw r0, #0xb0
	movt r0, #0x2000
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ get_device_descriptor_record - returns the constant address 0x200000d8. The 8
@ bytes there (initial RAM image, unpacked from 0x080BE480 at reset) are the word 0x00000012 and the
@ pointer 0x200000e0, whose bytes begin 12 01 00 02 00 00 00 40 (length 0x12,
@ type 1, version 0x0200, max packet 0x40). Purpose: returns a record {length
@ 0x12, pointer to the device descriptor}.
@ A 2-byte zero padding follows the final bx lr (never reached).
@ ----------------------------------------------------------------------------
	.section .text.get_device_descriptor_record,"ax",%progbits
	.p2align 2
	.global get_device_descriptor_record
	.thumb_func
	.type get_device_descriptor_record, %function
get_device_descriptor_record:
	movw r0, #0xd8
	movt r0, #0x2000
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ set_string_descriptor_mass_storage_interface - fills the descriptor buffer at
@ 0x20005ec4 with a string descriptor: halfword 0x32e (length 0x2e, type 3)
@ followed by the UTF-16 characters "Mass Storage Interface" at 0x20005ec6..;
@ sets 0x20005fc4 = 0x2e and 0x20005fc8 = 0x20005ec4.
@ A 2-byte zero padding follows the final bx lr (never reached).
@ ----------------------------------------------------------------------------
	.section .text.set_string_descriptor_mass_storage_interface,"ax",%progbits
	.p2align 2
	.global set_string_descriptor_mass_storage_interface
	.thumb_func
	.type set_string_descriptor_mass_storage_interface, %function
set_string_descriptor_mass_storage_interface:
	movw r1, #0x5ec4
	movs r0, #0x4d
	movt r1, #0x2000
	movt r0, #0x61
	str.w r0, [r1, #2]
	mov.w r0, #0x730073
	str.w r0, [r1, #6]
	movs r0, #0x20
	movt r0, #0x53
	str.w r0, [r1, #0xa]
	movs r0, #0x74
	movt r0, #0x6f
	str.w r0, [r1, #0xe]
	movs r0, #0x72
	movt r0, #0x61
	str.w r0, [r1, #0x12]
	movs r0, #0x67
	movt r0, #0x65
	str.w r0, [r1, #0x16]
	movs r0, #0x20
	movt r0, #0x49
	str.w r0, [r1, #0x1a]
	movs r0, #0x6e
	movt r0, #0x74
	str.w r0, [r1, #0x1e]
	movs r0, #0x65
	movt r0, #0x72
	str.w r0, [r1, #0x22]
	movs r0, #0x66
	movt r0, #0x61
	str.w r0, [r1, #0x26]
	movs r0, #0x63
	movt r0, #0x65
	str.w r0, [r1, #0x2a]
	movw r0, #0x32e
	strh r0, [r1]
	movw r0, #0x5fc4
	movt r0, #0x2000
	movs r2, #0x2e
	strh r2, [r0]
	str r1, [r0, #4]
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ get_language_id_descriptor_record - returns the constant address 0x200000a4.
@ The 8 bytes there (initial RAM image, unpacked from 0x080BE480 at reset) are the word 0x00000004 and
@ the pointer 0x200000ac, whose bytes are 04 03 09 04 (length 4, type 3,
@ language 0x0409). Purpose: returns a record {length 4, pointer to the
@ language id string descriptor}.
@ A 2-byte zero padding follows the final bx lr (never reached).
@ ----------------------------------------------------------------------------
	.section .text.get_language_id_descriptor_record,"ax",%progbits
	.p2align 2
	.global get_language_id_descriptor_record
	.thumb_func
	.type get_language_id_descriptor_record, %function
get_language_id_descriptor_record:
	movw r0, #0xa4
	movt r0, #0x2000
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08036cfc - fills the descriptor buffer at 0x20005ec4 with a string
@ descriptor: halfword 0x30e (length 0x0e, type 3) followed by the UTF-16
@ characters "Artery" at 0x20005ec6..; sets 0x20005fc4 = 0x0e and 0x20005fc8 =
@ 0x20005ec4. Purpose: fills a string descriptor buffer with the text "Artery"
@ (what the string names is not determined from this function).
@ ----------------------------------------------------------------------------
	.section .text.fn_08036cfc,"ax",%progbits
	.p2align 2
	.global fn_08036cfc
	.thumb_func
	.type fn_08036cfc, %function
fn_08036cfc:
	movw r1, #0x5ec4
	movs r0, #0x41
	movt r1, #0x2000
	movt r0, #0x72
	str.w r0, [r1, #2]
	movs r0, #0x74
	movt r0, #0x65
	str.w r0, [r1, #6]
	movs r0, #0x72
	movt r0, #0x79
	str.w r0, [r1, #0xa]
	movw r0, #0x30e
	strh r0, [r1]
	movw r0, #0x5fc4
	movt r0, #0x2000
	movs r2, #0xe
	strh r2, [r0]
	str r1, [r0, #4]
	bx lr

@ ----------------------------------------------------------------------------
@ fn_08036d38 - returns 0 (no arguments used). Purpose not determined from the
@ code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08036d38,"ax",%progbits
	.p2align 2
	.global fn_08036d38
	.thumb_func
	.type fn_08036d38, %function
fn_08036d38:
	movs r0, #0
	bx lr

@ ----------------------------------------------------------------------------
@ fn_08036d3c - fills the descriptor buffer at 0x20005ec4 with a string
@ descriptor: halfword 0x324 (length 0x24, type 3) followed by the UTF-16
@ characters "AT32 Mass Storage" at 0x20005ec6..; sets 0x20005fc4 = 0x24 and
@ 0x20005fc8 = 0x20005ec4.
@ A 2-byte zero padding follows the final bx lr (never reached).
@ ----------------------------------------------------------------------------
	.section .text.fn_08036d3c,"ax",%progbits
	.p2align 2
	.global fn_08036d3c
	.thumb_func
	.type fn_08036d3c, %function
fn_08036d3c:
	movw r1, #0x5ec4
	movs r0, #0x41
	movt r1, #0x2000
	movt r0, #0x54
	str.w r0, [r1, #2]
	movs r0, #0x33
	movt r0, #0x32
	str.w r0, [r1, #6]
	movs r0, #0x20
	movt r0, #0x4d
	str.w r0, [r1, #0xa]
	movs r0, #0x61
	movt r0, #0x73
	str.w r0, [r1, #0xe]
	movs r0, #0x73
	movt r0, #0x20
	str.w r0, [r1, #0x12]
	movs r0, #0x53
	movt r0, #0x74
	str.w r0, [r1, #0x16]
	movs r0, #0x6f
	movt r0, #0x72
	str.w r0, [r1, #0x1a]
	movs r0, #0x61
	movt r0, #0x67
	str.w r0, [r1, #0x1e]
	movs r0, #0x65
	strh r0, [r1, #0x22]
	mov.w r0, #0x324
	strh r0, [r1]
	movw r0, #0x5fc4
	movt r0, #0x2000
	movs r2, #0x24
	strh r2, [r0]
	str r1, [r0, #4]
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08036db0 - returns 0 (no arguments used). Purpose not determined from the
@ code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08036db0,"ax",%progbits
	.p2align 2
	.global fn_08036db0
	.thumb_func
	.type fn_08036db0, %function
fn_08036db0:
	movs r0, #0
	bx lr

@ ----------------------------------------------------------------------------
@ build_hex_id_string_descriptor_record - reads words at 0x1ffff7e8,
@ 0x1ffff7f0 and 0x1ffff7ec; when sum(0x1ffff7e8 + 0x1ffff7f0) != 0 it writes
@ the sum as 8 upper-case hex digits to bytes 0x20000082,84,86,88,8a,8c,8e,90
@ (high nibble first; nibble+0x30 below 10, nibble+0x37 otherwise) and the top
@ 16 bits of the word at 0x1ffff7ec as 4 hex digits to 0x20000092,94,96,98,
@ with zero bytes between and after the digits (0x20000083.. and 0x20000099).
@ Returns 0x2000009c. The record at 0x2000009c (initial RAM image, unpacked from 0x080BE480 at reset) is
@ the word 0x0000001a followed by the pointer 0x20000080, whose halfword is
@ 0x031a (length 0x1a, type 3): the 12 characters written at
@ 0x20000082..0x20000098 fill that string descriptor.
@ Purpose: builds a 12-character hex string descriptor from the words at
@ 0x1ffff7e8, 0x1ffff7f0 and 0x1ffff7ec and returns the record {length,
@ pointer}; its role as the device's serial number string is not determined
@ from this function (it is slot 7 of the pointer table at 0x20000058 and the
@ device descriptor at 0x200000e0 has the byte 3 at offset 16).
@ ----------------------------------------------------------------------------
	.section .text.build_hex_id_string_descriptor_record,"ax",%progbits
	.p2align 2
	.global build_hex_id_string_descriptor_record
	.thumb_func
	.type build_hex_id_string_descriptor_record, %function
build_hex_id_string_descriptor_record:
	push {r4, r5, r7, lr}
	movw r0, #0xf7e8
	movt r0, #0x1fff
	ldr r1, [r0]
	ldr r2, [r0, #8]
	adds r3, r2, r1
	beq.w .L08036f0e
	mov.w r12, #0x37
	lsrs r1, r3, #0x1c
	add.w r2, r12, r3, lsr #0x1c
	ldr r0, [r0, #4]
	cmp.w r3, #0xa0000000
	it cc
	addcc.w r2, r1, #0x30
	movw r1, #0x80
	movt r1, #0x2000
	ubfx r4, r3, #0x18, #4
	strb r2, [r1, #2]
	lsls r2, r3, #4
	mov.w lr, #0
	add.w r5, r4, #0x37
	strb.w lr, [r1, #3]
	cmp.w r2, #0xa0000000
	it cc
	addcc.w r5, r4, #0x30
	ubfx r4, r3, #0x14, #4
	strb r5, [r1, #4]
	lsls r2, r3, #8
	add.w r5, r4, #0x37
	strb.w lr, [r1, #5]
	cmp.w r2, #0xa0000000
	it cc
	addcc.w r5, r4, #0x30
	ubfx r4, r3, #0x10, #4
	strb r5, [r1, #6]
	lsls r2, r3, #0xc
	add.w r5, r4, #0x37
	strb.w lr, [r1, #7]
	cmp.w r2, #0xa0000000
	it cc
	addcc.w r5, r4, #0x30
	ubfx r4, r3, #0xc, #4
	strb r5, [r1, #8]
	lsls r2, r3, #0x10
	add.w r5, r4, #0x37
	strb.w lr, [r1, #9]
	cmp.w r2, #0xa0000000
	it cc
	addcc.w r5, r4, #0x30
	ubfx r4, r3, #8, #4
	strb r5, [r1, #0xa]
	lsls r2, r3, #0x14
	add.w r5, r4, #0x37
	strb.w lr, [r1, #0xb]
	cmp.w r2, #0xa0000000
	it cc
	addcc.w r5, r4, #0x30
	lsls r2, r3, #0x18
	ubfx r4, r3, #4, #4
	strb r5, [r1, #0xc]
	add.w r5, r4, #0x37
	cmp.w r2, #0xa0000000
	lsl.w r2, r3, #0x1c
	and.w r3, r3, #0xf
	strb.w lr, [r1, #0xd]
	it cc
	addcc.w r5, r4, #0x30
	add.w r4, r3, #0x37
	strb r5, [r1, #0xe]
	strb.w lr, [r1, #0xf]
	cmp.w r2, #0xa0000000
	it cc
	addcc.w r4, r3, #0x30
	add.w r3, r12, r0, lsr #0x1c
	strb r4, [r1, #0x10]
	strb.w lr, [r1, #0x11]
	lsrs r2, r0, #0x1c
	cmp.w r0, #0xa0000000
	it cc
	addcc.w r3, r2, #0x30
	strb r3, [r1, #0x12]
	ubfx r3, r0, #0x18, #4
	lsls r2, r0, #4
	add.w r5, r3, #0x37
	strb.w lr, [r1, #0x13]
	cmp.w r2, #0xa0000000
	it cc
	addcc.w r5, r3, #0x30
	lsls r2, r0, #8
	ubfx r3, r0, #0x14, #4
	strb r5, [r1, #0x14]
	add.w r5, r3, #0x37
	cmp.w r2, #0xa0000000
	lsl.w r2, r0, #0xc
	ubfx r0, r0, #0x10, #4
	strb.w lr, [r1, #0x15]
	it cc
	addcc.w r5, r3, #0x30
	add.w r3, r0, #0x37
	strb r5, [r1, #0x16]
	strb.w lr, [r1, #0x17]
	cmp.w r2, #0xa0000000
	it cc
	addcc.w r3, r0, #0x30
	strb r3, [r1, #0x18]
	strb.w lr, [r1, #0x19]
.L08036f0e:
	movw r0, #0x9c
	movt r0, #0x2000
	pop {r4, r5, r7, pc}
