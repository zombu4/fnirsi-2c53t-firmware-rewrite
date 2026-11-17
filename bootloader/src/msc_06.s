@ msc_06.s - SCSI command validation and dispatch for the USB mass-storage class (batch 06 of module msc).
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ validate_usbc_packet_and_dispatch - validate a received command block wrapper
@ and dispatch the SCSI command.
@ r0 = h. S = word at ([h+4]+0x24).
@ Copies S[0x1024] to S[0x1044] and S[0x1028] to S[0x1048].
@ The packet is accepted only if S[0x1020] == 0x43425355 (bytes 55 53 42 43),
@ 0x08004240(h,1) == 0x1F (0x08004240 returns the halfword at
@ h+0x10C+32*(r1&0x7F)+16; the purpose of that field is not determined from the
@ code), byte S[0x102D] <= 1 and 1 <= byte S[0x102E] <= 16.
@ Accepted: calls 0x08000C2C(h); a nonzero result -> 0x08001190(h); a zero result
@ -> if byte S[0] is not 1, 2 or 4: S[0x18] == 0 -> 0x080010F0(h,0), else
@ 0x08001134(h, S+0x1C, S[0x18]).
@ Rejected: 0x08001184(h,5,0x20), S[1] = 2, 0x08001190(h).
@ Called from 0x08000DB6. No return value.
@ ----------------------------------------------------------------------------
	.section .text.validate_usbc_packet_and_dispatch,"ax",%progbits
	.p2align 2
	.global validate_usbc_packet_and_dispatch
	.thumb_func
	.type validate_usbc_packet_and_dispatch, %function
validate_usbc_packet_and_dispatch:
	push {r4, r5, r6, lr}
	mov r5, r0
	mov r6, r5
	ldr r0, [r6, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	movw r0, #0x1024
	ldr r1, [r0, r4]
	movw r0, #0x1044
	str r1, [r0, r4]               @ S[0x1044] = S[0x1024]
	movw r0, #0x1028
	ldr r1, [r0, r4]
	movw r0, #0x1048
	str r1, [r0, r4]               @ S[0x1048] = S[0x1028]
	mov.w r0, #0x1020
	ldr r0, [r0, r4]
	ldr r1, .L08000b0c
	cmp r0, r1
	bne.n .L08000ab4               @ signature mismatch
	movs r1, #1
	mov r0, r6
	bl out_endpoint_length_done
	cmp r0, #0x1f
	bne.n .L08000ab4
	movw r0, #0x102d
	ldrb r0, [r0, r4]
	cmp r0, #1
	bgt.n .L08000ab4
	movw r0, #0x102e
	ldrb r0, [r0, r4]
	cmp r0, #1
	blt.n .L08000ab4
	movw r0, #0x102e
	ldrb r0, [r0, r4]
	cmp r0, #0x10
	ble.n .L08000aca
.L08000ab4:
	movs r2, #0x20                 @ rejected packet
	movs r1, #5
	mov r0, r5
	bl scsi_set_sense
	movs r0, #2
	strb r0, [r4, #1]
	mov r0, r5
	bl fn_08001190
	b.n .L08000b0a
.L08000aca:
	mov r0, r5
	bl scsi_dispatch_by_opcode
	cbz r0, .L08000ada
	mov r0, r5
	bl fn_08001190
	b.n .L08000b0a
.L08000ada:
	ldrb r0, [r4, #0]
	cmp r0, #1
	beq.n .L08000b0a
	ldrb r0, [r4, #0]
	cmp r0, #2
	beq.n .L08000b0a
	ldrb r0, [r4, #0]
	cmp r0, #4
	beq.n .L08000b0a
	ldr r0, [r4, #0x18]
	cbnz r0, .L08000afa
	movs r1, #0
	mov r0, r5
	bl fn_080010f0
	b.n .L08000b0a
.L08000afa:
	ldr r0, [r4, #0x18]
	cbz r0, .L08000b0a
	add.w r1, r4, #0x1c
	mov r0, r5
	ldr r2, [r4, #0x18]
	bl fn_08001134
.L08000b0a:
	pop {r4, r5, r6, pc}
.L08000b0c:
	.word 0x43425355               @ "USBC" signature, bytes 55 53 42 43

@ ----------------------------------------------------------------------------
@ scsi_op_1e_no_data - SCSI opcode 0x1E handler (no data phase).
@ r0 = h, r1 = LUN byte (unused). Sets S[0x18] = 0 (response length).
@ Returns 0. Selected by opcode 0x1E in 0x08000C2C (case 0x08000CBE).
@ ----------------------------------------------------------------------------
	.section .text.scsi_op_1e_no_data,"ax",%progbits
	.global scsi_op_1e_no_data
	.thumb_func
	.type scsi_op_1e_no_data, %function
scsi_op_1e_no_data:
	push {r4, lr}
	mov r2, r0
	mov r4, r1
	mov r3, r2
	ldr r0, [r3, #4]
	ldr r1, [r0, #0x24]            @ r1 = S
	movs r0, #0
	str r0, [r1, #0x18]            @ response length = 0
	pop {r4, pc}

@ ----------------------------------------------------------------------------
@ scsi_op_25_read_capacity - SCSI READ CAPACITY(10), opcode 0x25.
@ r0 = h, r1 = LUN. Calls 0x08002A60(LUN, &S[8+4*LUN], &S[12+4*LUN]) (LUN 0
@ stores 0xFFF and 0x800). S[0x1C..0x1F] = big-endian (S[8+4*LUN]-1),
@ S[0x20..0x23] = big-endian S[12+4*LUN]. S[0x18] = 8. Returns 0.
@ Selected by opcode 0x25 in 0x08000C2C (case 0x08000CDE).
@ ----------------------------------------------------------------------------
	.section .text.scsi_op_25_read_capacity,"ax",%progbits
	.global scsi_op_25_read_capacity
	.thumb_func
	.type scsi_op_25_read_capacity, %function
scsi_op_25_read_capacity:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r7, r0
	mov r4, r1
	mov r8, r7
	ldr.w r0, [r8, #4]
	ldr r5, [r0, #0x24]            @ r5 = S
	add.w r6, r5, #0x1c            @ r6 = response buffer S+0x1C
	add.w r0, r5, #0xc
	add.w r2, r0, r4, lsl #2       @ &S[12+4*LUN]
	.inst.n 0x1f00                 @ subs r0, r0, #4
	add.w r1, r0, r4, lsl #2       @ &S[8+4*LUN]
	mov r0, r4
	bl fn_08002a60
	add.w r0, r5, #8
	ldr.w r0, [r0, r4, lsl #2]
	.inst.n 0x1e40                 @ subs r0, r0, #1
	lsrs r0, r0, #0x18
	strb r0, [r6, #0]
	add.w r0, r5, #8
	ldr.w r0, [r0, r4, lsl #2]
	.inst.n 0x1e40                 @ subs r0, r0, #1
	lsrs r0, r0, #0x10
	strb r0, [r6, #1]
	add.w r0, r5, #8
	ldrh.w r0, [r0, r4, lsl #2]
	.inst.n 0x1e40                 @ subs r0, r0, #1
	lsrs r0, r0, #8
	strb r0, [r6, #2]
	add.w r0, r5, #8
	ldrb.w r0, [r0, r4, lsl #2]
	.inst.n 0x1e40                 @ subs r0, r0, #1
	strb r0, [r6, #3]
	add.w r0, r5, #0xc
	ldr.w r0, [r0, r4, lsl #2]
	lsrs r0, r0, #0x18
	strb r0, [r6, #4]
	add.w r0, r5, #0xc
	ldr.w r0, [r0, r4, lsl #2]
	lsrs r0, r0, #0x10
	strb r0, [r6, #5]
	add.w r0, r5, #0xc
	ldrh.w r0, [r0, r4, lsl #2]
	lsrs r0, r0, #8
	strb r0, [r6, #6]
	add.w r0, r5, #0xc
	ldrb.w r0, [r0, r4, lsl #2]
	strb r0, [r6, #7]
	movs r0, #8
	str r0, [r5, #0x18]            @ response length = 8
	movs r0, #0
	pop.w {r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ check_lba_range_or_set_sense - check that a block range lies inside the medium.
@ r0 = h, r1 = LUN, r2 = first block, r3 = count. Returns 0 when
@ r2+r3 <= S[8+4*r1] (unsigned bls at 0x08000BDA), else calls
@ 0x08001184(h,5,0x21) and returns 1.
@ Callers 0x08000FD8, 0x08001274, 0x080012EA.
@ ----------------------------------------------------------------------------
	.section .text.check_lba_range_or_set_sense,"ax",%progbits
	.p2align 2
	.global check_lba_range_or_set_sense
	.thumb_func
	.type check_lba_range_or_set_sense, %function
check_lba_range_or_set_sense:
	push.w {r4, r5, r6, r7, r8, r9, lr}
	mov r4, r0
	mov r5, r1
	mov r6, r2
	mov r7, r3
	mov r8, r4
	ldr.w r0, [r8, #4]
	ldr.w r9, [r0, #0x24]          @ r9 = S
	adds r1, r6, r7                @ first block + count
	add.w r0, r9, #8
	ldr.w r0, [r0, r5, lsl #2]     @ S[8+4*LUN]
	cmp r1, r0
	bls.n .L08000bec
	movs r2, #0x21
	movs r1, #5
	mov r0, r4
	bl scsi_set_sense
	movs r0, #1
.L08000be8:
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L08000bec:
	movs r0, #0
	b.n .L08000be8

@ ----------------------------------------------------------------------------
@ fn_08000bf0 - r0 = h, r1 = flag byte. If S[1] == 2: 0x08004538(h,0x81),
@ S[1] = 0. Otherwise, if (r1 & 0x80) == 0x80 and S[1] != 1: 0x080010F0(h,1).
@ Caller 0x0800152E. No return value. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08000bf0,"ax",%progbits
	.p2align 2
	.global fn_08000bf0
	.thumb_func
	.type fn_08000bf0, %function
fn_08000bf0:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r4, r0
	mov r6, r1
	mov r7, r4
	ldr r0, [r7, #4]
	ldr r5, [r0, #0x24]            @ r5 = S
	ldrb r0, [r5, #1]
	cmp r0, #2
	bne.n .L08000c12
	movs r1, #0x81
	mov r0, r7
	bl fn_08004538
	movs r0, #0
	strb r0, [r5, #1]
	b.n .L08000c28
.L08000c12:
	and.w r0, r6, #0x80
	cmp r0, #0x80
	bne.n .L08000c28
	ldrb r0, [r5, #1]
	cmp r0, #1
	beq.n .L08000c28
	movs r1, #1
	mov r0, r4
	bl fn_080010f0
.L08000c28:
	pop.w {r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ scsi_dispatch_by_opcode - SCSI command dispatcher.
@ r0 = h; reads the opcode byte S[0x102F] and passes (h, S[0x102D]) to:
@ 0x00 -> 0x080011E6, 0x03 -> 0x08001088, 0x12 -> 0x08000EB4,
@ 0x1A -> 0x08000F44, 0x1B -> 0x080011D4, 0x1E -> 0x08000B10,
@ 0x23 -> 0x08000DD4 (block at 0x08000D32), 0x25 -> 0x08000B22,
@ 0x28 -> 0x08000F74, 0x2A -> 0x08001286, 0x2F -> 0x08001216,
@ 0x5A -> 0x08000F14. The handler's return value goes to r6 and is returned
@ (via the tail at 0x08000D50). Any other opcode: 0x08001184(h,5,0x20) and
@ returns 1 (0x08000D42). Callers 0x08000ACC, 0x08000D78, 0x08000DBE.
@ ----------------------------------------------------------------------------
	.section .text.scsi_dispatch_by_opcode,"ax",%progbits
	.p2align 2
	.global scsi_dispatch_by_opcode
	.thumb_func
	.type scsi_dispatch_by_opcode, %function
scsi_dispatch_by_opcode:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r5, r0
	movs r6, #1                    @ default result = 1
	mov r7, r5
	ldr r0, [r7, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	movw r0, #0x102f
	ldrb r0, [r0, r4]              @ opcode
	cmp r0, #0x23
	beq.n fn_08000d32
	bgt.n .L08000c64
	cmp r0, #0x1a
	beq.n .L08000c9e
	bgt.n .L08000c5a
	cmp r0, #0
	beq.n .L08000cfe
	cmp r0, #3
	beq.n .L08000cee
	cmp r0, #0x12
	bne.n fn_08000d42
	b.n .L08000c7e
.L08000c5a:
	cmp r0, #0x1b
	beq.n .L08000c8e
	cmp r0, #0x1e
	bne.n fn_08000d42
	b.n .L08000cbe
.L08000c64:
	cmp r0, #0x2a
	beq.n .L08000d1e
	bgt.n .L08000c74
	cmp r0, #0x25
	beq.n .L08000cde
	cmp r0, #0x28
	bne.n fn_08000d42
	b.n .L08000cce
.L08000c74:
	cmp r0, #0x2f
	beq.n .L08000d0e
	cmp r0, #0x5a
	bne.n fn_08000d42
	b.n .L08000cae
.L08000c7e:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_op_12_copy_response
	mov r6, r0
	b.n fn_08000d50
.L08000c8e:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_start_stop_unit
	mov r6, r0
	b.n fn_08000d50
.L08000c9e:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_mode_sense_6
	mov r6, r0
	b.n fn_08000d50
.L08000cae:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_mode_sense_10
	mov r6, r0
	b.n fn_08000d50
.L08000cbe:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_op_1e_no_data
	mov r6, r0
	b.n fn_08000d50
.L08000cce:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_read_10
	mov r6, r0
	b.n fn_08000d50
.L08000cde:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_op_25_read_capacity
	mov r6, r0
	b.n fn_08000d50
.L08000cee:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_request_sense
	mov r6, r0
	b.n fn_08000d50
.L08000cfe:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_test_unit_ready
	mov r6, r0
	b.n fn_08000d50
.L08000d0e:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_verify_10
	mov r6, r0
	b.n fn_08000d50
.L08000d1e:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_write_10
	mov r6, r0
	b.n fn_08000d50

@ ----------------------------------------------------------------------------
@ fn_08000d2e - b.n 0x08000D32 (e000, branch to the next instruction).
@ No flow reaches it (unreached island). Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.global fn_08000d2e
	.thumb_func
	.type fn_08000d2e, %function
fn_08000d2e:
	b.n fn_08000d32

@ ----------------------------------------------------------------------------
@ fn_08000d30 - b.n 0x08000D42 (e007). No flow reaches it (unreached island).
@ Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.global fn_08000d30
	.thumb_func
	.type fn_08000d30, %function
fn_08000d30:
	b.n fn_08000d42

@ ----------------------------------------------------------------------------
@ fn_08000d32 - block of 0x08000C2C for opcode 0x23: r0 = h (r5),
@ r1 = S[0x102D]; bl 0x08000DD4; r6 = result; b 0x08000D50. Reached by the beq
@ at 0x08000C42. Not an independent function (uses 0x08000C2C's registers and
@ frame).
@ ----------------------------------------------------------------------------
	.global fn_08000d32
	.thumb_func
	.type fn_08000d32, %function
fn_08000d32:
	movw r0, #0x102d
	ldrb r1, [r0, r4]
	mov r0, r5
	bl scsi_op_23_build_response
	mov r6, r0
	b.n fn_08000d50

@ ----------------------------------------------------------------------------
@ fn_08000d42 - block of 0x08000C2C for every opcode not handled:
@ 0x08001184(r5,5,0x20), r6 = 1, falls into 0x08000D50. Reached by the bne
@ branches at 0x08000C56, 0x08000C60, 0x08000C70, 0x08000C7A. Not an
@ independent function.
@ ----------------------------------------------------------------------------
	.global fn_08000d42
	.thumb_func
	.type fn_08000d42, %function
fn_08000d42:
	movs r2, #0x20
	movs r1, #5
	mov r0, r5
	bl scsi_set_sense
	movs r6, #1
	nop

@ ----------------------------------------------------------------------------
@ fn_08000d50 - tail of 0x08000C2C: nop; mov r0,r6; pop {r4-r8,pc}. Returns
@ r6 of 0x08000C2C's frame. Not an independent function.
@ ----------------------------------------------------------------------------
	.global fn_08000d50
	.thumb_func
	.type fn_08000d50, %function
fn_08000d50:
	nop
	mov r0, r6
	pop.w {r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_08000d58 - r0 = h; byte S[0]: 1 -> 0x08000C2C(h), a nonzero result ->
@ 0x080010F0(h,1); 3 or 4 -> 0x080010F0(h,0); other values do nothing.
@ Caller 0x08001432. No return value. The meaning of the S[0] states is not
@ determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08000d58,"ax",%progbits
	.p2align 2
	.global fn_08000d58
	.thumb_func
	.type fn_08000d58, %function
fn_08000d58:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r4, r0
	mov r7, r1
	mov r6, r4
	ldr r0, [r6, #4]
	ldr r5, [r0, #0x24]            @ r5 = S
	ldrb r0, [r5, #0]
	cmp r0, #1
	beq.n .L08000d76
	cmp r0, #3
	beq.n .L08000d8a
	cmp r0, #4
	bne.n .L08000d94
	b.n .L08000d88
.L08000d76:
	mov r0, r4
	bl scsi_dispatch_by_opcode
	cbz r0, .L08000d86
	movs r1, #1
	mov r0, r4
	bl fn_080010f0
.L08000d86:
	b.n .L08000d96
.L08000d88:
	nop
.L08000d8a:
	movs r1, #0
	mov r0, r4
	bl fn_080010f0
	b.n .L08000d96
.L08000d94:
	nop
.L08000d96:
	nop
	pop.w {r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_08000d9c - r0 = h; byte S[0]: 2 -> 0x08000C2C(h), a nonzero result ->
@ 0x080010F0(h,1); 7 -> 0x08000A5C(h); other values do nothing. Caller
@ 0x08001470. No return value. The meaning of the S[0] states is not
@ determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08000d9c,"ax",%progbits
	.p2align 2
	.global fn_08000d9c
	.thumb_func
	.type fn_08000d9c, %function
fn_08000d9c:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r4, r0
	mov r7, r1
	mov r6, r4
	ldr r0, [r6, #4]
	ldr r5, [r0, #0x24]            @ r5 = S
	ldrb r0, [r5, #0]
	cmp r0, #2
	beq.n .L08000dbc
	cmp r0, #7
	bne.n .L08000dce
	mov r0, r4
	bl validate_usbc_packet_and_dispatch
	b.n .L08000dce
.L08000dbc:
	mov r0, r4
	bl scsi_dispatch_by_opcode
	cbz r0, .L08000dcc
	movs r1, #1
	mov r0, r4
	bl fn_080010f0
.L08000dcc:
	nop
.L08000dce:
	nop
	pop.w {r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ scsi_op_23_build_response - SCSI opcode 0x23 response.
@ r0 = h, r1 = LUN. S[0x1C..0x1F] = 00 00 00 08. Calls
@ 0x08002A60(LUN, &S[8+4*LUN], &S[12+4*LUN]). S[0x20..0x23] = big-endian
@ (S[8+4*LUN]-1), S[0x24] = 2, S[0x25..0x27] = the low 24 bits of S[12+4*LUN]
@ big-endian. S[0x18] = 12. Returns 0. Selected by opcode 0x23 in 0x08000C2C.
@ ----------------------------------------------------------------------------
	.section .text.scsi_op_23_build_response,"ax",%progbits
	.p2align 2
	.global scsi_op_23_build_response
	.thumb_func
	.type scsi_op_23_build_response, %function
scsi_op_23_build_response:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r7, r0
	mov r5, r1
	mov r8, r7
	ldr.w r0, [r8, #4]
	ldr r6, [r0, #0x24]            @ r6 = S
	add.w r4, r6, #0x1c            @ r4 = response buffer S+0x1C
	movs r0, #0
	strb r0, [r4, #0]
	strb r0, [r4, #1]
	strb r0, [r4, #2]
	movs r0, #8
	strb r0, [r4, #3]
	add.w r0, r6, #0xc
	add.w r2, r0, r5, lsl #2       @ &S[12+4*LUN]
	.inst.n 0x1f00                 @ subs r0, r0, #4
	add.w r1, r0, r5, lsl #2       @ &S[8+4*LUN]
	mov r0, r5
	bl fn_08002a60
	add.w r0, r6, #8
	ldr.w r0, [r0, r5, lsl #2]
	.inst.n 0x1e40                 @ subs r0, r0, #1
	lsrs r0, r0, #0x18
	strb r0, [r4, #4]
	add.w r0, r6, #8
	ldr.w r0, [r0, r5, lsl #2]
	.inst.n 0x1e40                 @ subs r0, r0, #1
	lsrs r0, r0, #0x10
	strb r0, [r4, #5]
	add.w r0, r6, #8
	ldrh.w r0, [r0, r5, lsl #2]
	.inst.n 0x1e40                 @ subs r0, r0, #1
	lsrs r0, r0, #8
	strb r0, [r4, #6]
	add.w r0, r6, #8
	ldrb.w r0, [r0, r5, lsl #2]
	.inst.n 0x1e40                 @ subs r0, r0, #1
	strb r0, [r4, #7]
	movs r0, #2
	strb r0, [r4, #8]
	add.w r0, r6, #0xc
	ldr.w r0, [r0, r5, lsl #2]
	lsrs r0, r0, #0x10
	strb r0, [r4, #9]
	add.w r0, r6, #0xc
	ldrh.w r0, [r0, r5, lsl #2]
	lsrs r0, r0, #8
	strb r0, [r4, #0xa]
	add.w r0, r6, #0xc
	ldrb.w r0, [r0, r5, lsl #2]
	strb r0, [r4, #0xb]
	movs r0, #0xc
	str r0, [r6, #0x18]            @ response length = 12
	movs r0, #0
	pop.w {r4, r5, r6, r7, r8, pc}
	.short 0x0000                  @ padding

@ ----------------------------------------------------------------------------
@ start_command_packet_receive - arm the reception of a command block wrapper.
@ r0 = h. S[0] = 7, S[1] = 0, S[4] = 0, S[0x1040] = 0x53425355 then
@ S[0x1048] = 0, S[0x1040] = 0, S[0x1044] = 0 (the word 0x53425355 is
@ overwritten by the later zero stores). Calls 0x08003D88(h, 1, S+0x1020, 31)
@ (stores buffer and length 31 in the record at h+0x10C+32*ep and
@ read-modify-writes the word at 0x40005000+0xC00+4*ep, literal 0x08003DF8).
@ No return value. Caller 0x0800145C.
@ ----------------------------------------------------------------------------
	.section .text.start_command_packet_receive,"ax",%progbits
	.p2align 2
	.global start_command_packet_receive
	.thumb_func
	.type start_command_packet_receive, %function
start_command_packet_receive:
	push {r4, r5, r6, lr}
	mov r5, r0
	mov r6, r5
	ldr r0, [r6, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	movs r0, #7
	strb r0, [r4, #0]
	movs r0, #0
	strb r0, [r4, #1]
	str r0, [r4, #4]
	ldr r1, .L08000eb0
	mov.w r0, #0x1040
	str r1, [r0, r4]
	movs r1, #0
	movw r0, #0x1048
	str r1, [r0, r4]
	mov.w r0, #0x1040
	str r1, [r0, r4]
	.inst.n 0x1d00                 @ adds r0, r0, #4
	str r1, [r0, r4]
	movs r3, #0x1f
	add.w r2, r4, #0x1020
	movs r1, #1
	mov r0, r6
	bl fn_08003d88
	pop {r4, r5, r6, pc}
	.short 0x0000                  @ padding
.L08000eb0:
	.word 0x53425355

@ ----------------------------------------------------------------------------
@ scsi_op_12_copy_response - SCSI INQUIRY response, opcode 0x12.
@ r0 = h, r1 = LUN. If bit 0 of S[0x1030] is set: source = RAM 0x200000CC
@ (5 bytes, initial value 00 00 00 00 00), length 5. Else: source =
@ 0x08002610(LUN) (0x20000500 + 36*LUN for LUN 0, 0 for LUN >= 1), length =
@ min(S[0x1028], 0x24). S[0x18] = length. Copies length bytes from the source
@ to S+0x1C, last byte first. Returns 0. Selected by opcode 0x12 in
@ 0x08000C2C. The pointer 0x08002610 returns for LUN 0 is not checked for 0.
@ ----------------------------------------------------------------------------
	.section .text.scsi_op_12_copy_response,"ax",%progbits
	.p2align 2
	.global scsi_op_12_copy_response
	.thumb_func
	.type scsi_op_12_copy_response, %function
scsi_op_12_copy_response:
	push.w {r4, r5, r6, r7, r8, r9, r10, lr}
	mov r7, r0
	mov r8, r1
	movs r4, #0
	mov r9, r4
	mov r10, r7
	ldr.w r0, [r10, #4]
	ldr r5, [r0, #0x24]            @ r5 = S
	movw r0, #0x1030
	ldrb r0, [r0, r5]
	and.w r0, r0, #1
	cbz r0, .L08000eda
	ldr r6, .L08000f10
	movs r4, #5
	b.n .L08000ef6
.L08000eda:
	mov r0, r8
	bl fn_08002610
	mov r6, r0
	movw r0, #0x1028
	ldr r0, [r0, r5]
	cmp r0, #0x24
	bcs.n .L08000ef4
	movw r0, #0x1028
	ldr r4, [r0, r5]
	b.n .L08000ef6
.L08000ef4:
	movs r4, #0x24
.L08000ef6:
	str r4, [r5, #0x18]
	b.n .L08000f04
.L08000efa:
	.inst.n 0x1e64                 @ subs r4, r4, #1
	ldrb r1, [r6, r4]
	add.w r0, r5, #0x1c
	strb r1, [r0, r4]
.L08000f04:
	cmp r4, #0
	bne.n .L08000efa
	mov r0, r9
	pop.w {r4, r5, r6, r7, r8, r9, r10, pc}
	.short 0x0000                  @ padding
.L08000f10:
	.word 0x200000cc

@ ----------------------------------------------------------------------------
@ scsi_mode_sense_10 - MODE SENSE(10), dispatched for CDB opcode 0x5A
@ (0x08000cae..0x08000cb6). Param r0 = USB device handle; MSC state
@ S = [[r0+4]+0x24]. Sets S+0x18 = 8 (response length), then copies 8 bytes
@ from RAM 0x200000F4..0x200000FB to S+0x1C..S+0x23, index 7 down to 0.
@ Initial table bytes (rwdata_20000000.bin offset 0xF4): 00 06 00 00 00 00 00
@ 00; the only reference to 0x200000F4 is this function's literal at
@ 0x08000F40. No clamp to the CBW length. Returns 0.
@ ----------------------------------------------------------------------------
	.section .text.scsi_mode_sense_10,"ax",%progbits
	.p2align 2
	.global scsi_mode_sense_10
	.thumb_func
	.type scsi_mode_sense_10, %function
scsi_mode_sense_10:
	push {r4, r5, r6, lr}
	mov r2, r0
	mov r5, r1
	movs r1, #8
	mov r4, r2
	ldr r0, [r4, #4]
	ldr r3, [r0, #0x24]            @ r3 = S
	movs r0, #8
	str r0, [r3, #0x18]            @ response length = 8
	b.n .L08000f36
.L08000f28:
	subs r0, r1, #1
	uxtb r1, r0
	ldr r0, .L08000f40
	ldrb r6, [r0, r1]
	add.w r0, r3, #0x1c
	strb r6, [r0, r1]
.L08000f36:
	cmp r1, #0
	bne.n .L08000f28
	movs r0, #0
	pop {r4, r5, r6, pc}
	.short 0x0000                  @ padding
.L08000f40:
	.word 0x200000f4

@ ----------------------------------------------------------------------------
@ scsi_mode_sense_6 - MODE SENSE(6), dispatched for CDB opcode 0x1A
@ (0x08000c9e..0x08000ca6). Same as 0x08000F14 but the source is RAM
@ 0x200000EC..0x200000F3, all zero in rwdata_20000000.bin (offset 0xEC); the
@ only reference to 0x200000EC is this function's literal at 0x08000F70. Sets
@ S+0x18 = 8, copies 8 bytes to S+0x1C.. index 7 down to 0. Returns 0.
@ ----------------------------------------------------------------------------
	.section .text.scsi_mode_sense_6,"ax",%progbits
	.p2align 2
	.global scsi_mode_sense_6
	.thumb_func
	.type scsi_mode_sense_6, %function
scsi_mode_sense_6:
	push {r4, r5, r6, lr}
	mov r2, r0
	mov r5, r1
	movs r1, #8
	mov r4, r2
	ldr r0, [r4, #4]
	ldr r3, [r0, #0x24]            @ r3 = S
	movs r0, #8
	str r0, [r3, #0x18]            @ response length = 8
	b.n .L08000f66
.L08000f58:
	subs r0, r1, #1
	uxtb r1, r0
	ldr r0, .L08000f70
	ldrb r6, [r0, r1]
	add.w r0, r3, #0x1c
	strb r6, [r0, r1]
.L08000f66:
	cmp r1, #0
	bne.n .L08000f58
	movs r0, #0
	pop {r4, r5, r6, pc}
	.short 0x0000                  @ padding
.L08000f70:
	.word 0x200000ec

@ ----------------------------------------------------------------------------
@ scsi_read_10 - SCSI READ(10), CDB opcode 0x28, called from the opcode switch
@ at 0x08000CD6 with r0 = device handle, r1 = LUN byte S+0x102D.
@ S = [[r0+4]+0x24]; S+0 = state byte, S+0x10 = byte address, S+0x14 = bytes
@ left, S+0x18 = response length, S+0x1C = 4096-byte buffer, S+0x1020 = CBW,
@ S+0x1028 = CBW data length, S+0x102C = CBW flags, S+0x1040 = CSW,
@ S+0x1048 = CSW residue.
@ If S+0 == 7 (first call): CBW flags bit 7 must be set, else sense key 5 /
@ code 0x20 via 0x08001184 and return 1; LBA = big-endian S+0x1031..0x1034 ->
@ S+0x10, block count = big-endian halfword S+0x1036..0x1037 -> S+0x14; range
@ check 0x08000BB8(dev,lun,lba,count) nonzero -> return 1; both multiplied by
@ the word at S+0xC+lun*4; if that byte count differs from S+0x1028 -> sense
@ 5 / 0x20, return 1; S+0 = 1.
@ Every call: S+0x18 = 0x1000, n = min(S+0x14, 0x1000), reads n bytes from byte
@ address S+0x10 into S+0x1C with 0x08002A88(lun, addr, buf, n); on 0 sends n
@ bytes on endpoint 0x81 with 0x08003DFC(dev,0x81,S+0x1C,n), S+0x10 += n,
@ S+0x14 -= n, S+0x1048 -= n, S+0 = 4 when S+0x14 reaches 0, returns 0; on
@ nonzero sets sense 4 / 0x3A via 0x08001184 and returns 1.
@ ----------------------------------------------------------------------------
	.section .text.scsi_read_10,"ax",%progbits
	.p2align 2
	.global scsi_read_10
	.thumb_func
	.type scsi_read_10, %function
scsi_read_10:
	push.w {r4, r5, r6, r7, r8, r9, r10, lr}
	mov r8, r0
	mov r7, r1
	mov r9, r8
	ldr.w r0, [r9, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	add.w r0, r4, #0x1020
	add.w r5, r0, #0xf             @ r5 = S+0x102F (CDB opcode byte)
	ldrb r0, [r4, #0]
	cmp r0, #7
	bne.n .L0800101c
	movw r0, #0x102c
	ldrb r0, [r0, r4]
	and.w r0, r0, #0x80
	cmp r0, #0x80
	beq.n .L08000fb0
	movs r2, #0x20
	movs r1, #5
	mov r0, r8
	bl scsi_set_sense
	movs r0, #1
.L08000fac:
	pop.w {r4, r5, r6, r7, r8, r9, r10, pc}
.L08000fb0:
	ldrb r0, [r5, #2]
	lsls r0, r0, #0x18
	ldrb r1, [r5, #3]
	orr.w r0, r0, r1, lsl #0x10
	ldrb r1, [r5, #4]
	orr.w r0, r0, r1, lsl #8
	ldrb r1, [r5, #5]
	orrs r0, r1
	str r0, [r4, #0x10]            @ byte address = LBA (still in blocks)
	ldrb r0, [r5, #8]
	ldrb r1, [r5, #7]
	orr.w r0, r0, r1, lsl #8
	str r0, [r4, #0x14]            @ block count
	mov r1, r7
	mov r0, r8
	ldrd r2, r3, [r4, #0x10]
	bl check_lba_range_or_set_sense
	cbz r0, .L08000fe2
	movs r0, #1
	b.n .L08000fac
.L08000fe2:
	add.w r1, r4, #0xc
	ldr.w r1, [r1, r7, lsl #2]
	ldr r0, [r4, #0x10]
	muls r0, r1, r0
	str r0, [r4, #0x10]
	add.w r1, r4, #0xc
	ldr.w r1, [r1, r7, lsl #2]
	ldr r0, [r4, #0x14]
	muls r0, r1, r0
	str r0, [r4, #0x14]
	movw r0, #0x1028
	ldr r0, [r0, r4]
	ldr r1, [r4, #0x14]
	cmp r0, r1
	beq.n .L08001018
	movs r2, #0x20
	movs r1, #5
	mov r0, r8
	bl scsi_set_sense
	movs r0, #1
	b.n .L08000fac
.L08001018:
	movs r0, #1
	strb r0, [r4, #0]
.L0800101c:
	mov.w r0, #0x1000
	str r0, [r4, #0x18]
	ldr r0, [r4, #0x14]
	cmp.w r0, #0x1000
	bcs.n .L0800102e
	ldr r0, [r4, #0x14]
	b.n .L08001032
.L0800102e:
	mov.w r0, #0x1000
.L08001032:
	uxth r6, r0                    @ n
	mov r3, r6
	add.w r2, r4, #0x1c
	mov r0, r7
	ldr r1, [r4, #0x10]
	bl fn_08002a88
	cbz r0, .L08001052
	movs r2, #0x3a
	movs r1, #4
	mov r0, r8
	bl scsi_set_sense
	movs r0, #1
	b.n .L08000fac
.L08001052:
	uxth r3, r6
	add.w r2, r4, #0x1c
	movs r1, #0x81
	mov r0, r9
	bl fn_08003dfc
	ldr r0, [r4, #0x10]
	add r0, r6
	str r0, [r4, #0x10]
	ldr r0, [r4, #0x14]
	subs r0, r0, r6
	str r0, [r4, #0x14]
	movw r0, #0x1048
	ldr r0, [r0, r4]
	subs r1, r0, r6
	movw r0, #0x1048
	str r1, [r0, r4]
	ldr r0, [r4, #0x14]
	cbnz r0, .L08001082
	movs r0, #4
	strb r0, [r4, #0]
.L08001082:
	movs r0, #0
	b.n .L08000fac
	.short 0x0000                  @ padding

@ ----------------------------------------------------------------------------
@ scsi_request_sense - REQUEST SENSE, dispatched for CDB opcode 0x03
@ (0x08000CF6). r0 = device handle. Copies 18 bytes from RAM
@ 0x200000D4..0x200000E5 into S+0x1C..S+0x2D (S = [[r0+4]+0x24]), source index
@ 17 down to 0; sets S+0x18 = min(S+0x1028, 0x12). Initial source bytes
@ (rwdata_20000000.bin offset 0xD4): 70 00 05 00 00 00 00 00 0A 00 00 00 00 00
@ 00 00 20 00; byte index 2 is 0x200000D6 (written by 0x08001184 arg 2), byte
@ index 16 is 0x200000E4 (written by arg 3). Returns 0.
@ ----------------------------------------------------------------------------
	.section .text.scsi_request_sense,"ax",%progbits
	.p2align 2
	.global scsi_request_sense
	.thumb_func
	.type scsi_request_sense, %function
scsi_request_sense:
	push {r4, r5, r6, r7, lr}
	mov r3, r0
	mov r7, r1
	movs r2, #0x12
	mov r6, r3
	ldr r0, [r6, #4]
	ldr r1, [r0, #0x24]            @ r1 = S
	add.w r4, r1, #0x1c            @ r4 = response buffer
	ldr r5, .L080010c4             @ r5 = RAM 0x200000D4 (sense block)
	b.n .L080010a4
.L0800109e:
	.inst.n 0x1e52                 @ subs r2, r2, #1
	ldrb r0, [r5, r2]
	strb r0, [r4, r2]
.L080010a4:
	cmp r2, #0
	bne.n .L0800109e
	movw r0, #0x1028
	ldr r0, [r0, r1]
	cmp r0, #0x12
	bcs.n .L080010bc
	movw r0, #0x1028
	ldr r0, [r0, r1]
	str r0, [r1, #0x18]
	b.n .L080010c0
.L080010bc:
	movs r0, #0x12
	str r0, [r1, #0x18]
.L080010c0:
	movs r0, #0
	pop {r4, r5, r6, r7, pc}
.L080010c4:
	.word 0x200000d4

@ ----------------------------------------------------------------------------
@ fn_080010c8 - bulk-only reset state setter; called from the class setup
@ handler 0x08001478 (class request 0xFF) at 0x080014B0. r0 = device handle,
@ S = [[r0+4]+0x24]. Sets S+0 = 7, S+1 = 1, word S+4 = 0, then calls
@ 0x08003D88(dev, 1, S+0x1020, 0x1F) (receive 31 bytes on endpoint 1 into the
@ CBW buffer). No return value used.
@ ----------------------------------------------------------------------------
	.section .text.fn_080010c8,"ax",%progbits
	.p2align 2
	.global fn_080010c8
	.thumb_func
	.type fn_080010c8, %function
fn_080010c8:
	push {r4, r5, r6, lr}
	mov r5, r0
	mov r6, r5
	ldr r0, [r6, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	movs r0, #7
	strb r0, [r4, #0]
	movs r0, #1
	strb r0, [r4, #1]
	movs r0, #0
	str r0, [r4, #4]
	movs r3, #0x1f
	add.w r2, r4, #0x1020
	movs r1, #1
	mov r0, r6
	bl fn_08003d88
	pop {r4, r5, r6, pc}
	.short 0x0000                  @ padding

@ ----------------------------------------------------------------------------
@ fn_080010f0 - completes a command. r0 = device handle, r1 = status.
@ S = [[r0+4]+0x24]. Stores r1 at S+0x104C, 0x53425355 at S+0x1040 (the 4 bytes
@ "USBS"), S+0 = 7, sends 13 bytes from S+0x1040 on endpoint 0x81 with
@ 0x08003DFC, then calls 0x08003D88(dev, 1, S+0x1020, 0x1F) (receive 31 bytes
@ on endpoint 1 into the CBW buffer). Callers: 0x08000AF4, 0x08000C24,
@ 0x08000D82, 0x08000D8E, 0x08000DC8 and 0x080013A2 (inside 0x08001286,
@ status 0).
@ ----------------------------------------------------------------------------
	.section .text.fn_080010f0,"ax",%progbits
	.p2align 2
	.global fn_080010f0
	.thumb_func
	.type fn_080010f0, %function
fn_080010f0:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r5, r0
	mov r6, r1
	mov r7, r5
	ldr r0, [r7, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	movw r0, #0x104c
	str r6, [r0, r4]               @ S+0x104C = status
	ldr r1, .L08001130
	mov.w r0, #0x1040
	str r1, [r0, r4]               @ S+0x1040 = "USBS"
	movs r0, #7
	strb r0, [r4, #0]
	movs r3, #0xd
	add.w r2, r4, #0x1040
	movs r1, #0x81
	mov r0, r7
	bl fn_08003dfc
	movs r3, #0x1f
	add.w r2, r4, #0x1020
	movs r1, #1
	mov r0, r7
	bl fn_08003d88
	pop.w {r4, r5, r6, r7, r8, pc}
.L08001130:
	.word 0x53425355

@ ----------------------------------------------------------------------------
@ fn_08001134 - sends a data-in response. r0 = device handle, r1 = buffer,
@ r2 = length. S = [[r0+4]+0x24]. n = min(r2, word S+0x1028);
@ S+0x1048 -= n & 0xFFFF; S+0x104C = 0; S+0 = 3; calls
@ 0x08003DFC(dev, 0x81, buffer, n & 0xFFFF). Caller 0x08000B06. No return
@ value used.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001134,"ax",%progbits
	.p2align 2
	.global fn_08001134
	.thumb_func
	.type fn_08001134, %function
fn_08001134:
	push.w {r4, r5, r6, r7, r8, r9, r10, lr}
	mov r6, r0
	mov r7, r1
	mov r8, r2
	mov r9, r6
	ldr.w r0, [r9, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	movw r0, #0x1028
	ldr r0, [r0, r4]
	cmp r0, r8
	bls.n .L08001154
	mov r0, r8
	b.n .L0800115a
.L08001154:
	movw r0, #0x1028
	ldr r0, [r0, r4]
.L0800115a:
	uxth r5, r0                    @ n
	movw r0, #0x1048
	ldr r0, [r0, r4]
	subs r1, r0, r5
	movw r0, #0x1048
	str r1, [r0, r4]               @ S+0x1048 -= n
	movs r1, #0
	.inst.n 0x1d00                 @ adds r0, r0, #4
	str r1, [r0, r4]               @ S+0x104C = 0
	movs r0, #3
	strb r0, [r4, #0]
	mov r3, r5
	mov r2, r7
	movs r1, #0x81
	mov r0, r9
	bl fn_08003dfc
	pop.w {r4, r5, r6, r7, r8, r9, r10, pc}

@ ----------------------------------------------------------------------------
@ scsi_set_sense - stores r1 (byte) in RAM 0x200000D6 and r2 (byte) in RAM
@ 0x200000E4; r0 is unused. Those two bytes are the source of the 18-byte
@ block that 0x08001088 returns (byte index 2 and index 16). Returns nothing.
@ ----------------------------------------------------------------------------
	.section .text.scsi_set_sense,"ax",%progbits
	.p2align 2
	.global scsi_set_sense
	.thumb_func
	.type scsi_set_sense, %function
scsi_set_sense:
	ldr r3, .L0800118c
	strb r1, [r3, #2]
	strb r2, [r3, #0x10]
	bx lr
.L0800118c:
	.word 0x200000d4

@ ----------------------------------------------------------------------------
@ fn_08001190 - r0 = device handle, S = [[r0+4]+0x24]. If word S+0x1028 != 0
@ and byte S+0x102C == 0 and byte S+1 == 0, calls 0x08004538(dev, 1); always
@ calls 0x08004538(dev, 0x81); then if byte S+1 == 2 calls
@ 0x08003D88(dev, 1, S+0x1020, 0x1F). 0x08004538 writes the endpoint status
@ bits in the 0x40005C00 table (decompile at 0x08004538). Callers 0x08000AC4
@ and 0x08000AD4. No return value used. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001190,"ax",%progbits
	.p2align 2
	.global fn_08001190
	.thumb_func
	.type fn_08001190, %function
fn_08001190:
	push {r4, r5, r6, lr}
	mov r5, r0
	mov r6, r5
	ldr r0, [r6, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	movw r0, #0x1028
	ldr r0, [r0, r4]
	cbz r0, .L080011b6
	movw r0, #0x102c
	ldrb r0, [r0, r4]
	cbnz r0, .L080011b6
	ldrb r0, [r4, #1]
	cbnz r0, .L080011b6
	movs r1, #1
	mov r0, r6
	bl fn_08004538
.L080011b6:
	movs r1, #0x81
	mov r0, r6
	bl fn_08004538
	ldrb r0, [r4, #1]
	cmp r0, #2
	bne.n .L080011d2
	movs r3, #0x1f
	add.w r2, r4, #0x1020
	movs r1, #1
	mov r0, r6
	bl fn_08003d88
.L080011d2:
	pop {r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ scsi_start_stop_unit - START STOP UNIT, dispatched for CDB opcode 0x1B
@ (0x08000C96). Sets word [[r0+4]+0x24]+0x18 = 0 and returns 0 in r0 (movs
@ r0,#0 at 0x080011E0 stays in r0). Nothing else is read or
@ written; the load/eject bits are ignored.
@ ----------------------------------------------------------------------------
	.section .text.scsi_start_stop_unit,"ax",%progbits
	.global scsi_start_stop_unit
	.thumb_func
	.type scsi_start_stop_unit, %function
scsi_start_stop_unit:
	push {r4, lr}
	mov r2, r0
	mov r4, r1
	mov r3, r2
	ldr r0, [r3, #4]
	ldr r1, [r0, #0x24]            @ r1 = S
	movs r0, #0
	str r0, [r1, #0x18]
	pop {r4, pc}

@ ----------------------------------------------------------------------------
@ scsi_test_unit_ready - TEST UNIT READY, dispatched for CDB opcode 0x00
@ (0x08000D06). S = [[r0+4]+0x24]. If word S+0x1028 == 0: S+0x18 = 0 and
@ returns 0; otherwise sets sense 5 / 0x20 via 0x08001184 and returns 1.
@ ----------------------------------------------------------------------------
	.section .text.scsi_test_unit_ready,"ax",%progbits
	.global scsi_test_unit_ready
	.thumb_func
	.type scsi_test_unit_ready, %function
scsi_test_unit_ready:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r4, r0
	mov r8, r1
	movs r6, #0
	mov r7, r4
	ldr r0, [r7, #4]
	ldr r5, [r0, #0x24]            @ r5 = S
	movw r0, #0x1028
	ldr r0, [r0, r5]
	cbz r0, .L0800120e
	movs r2, #0x20
	movs r1, #5
	mov r0, r4
	bl scsi_set_sense
	movs r0, #1
.L0800120a:
	pop.w {r4, r5, r6, r7, r8, pc}
.L0800120e:
	movs r0, #0
	str r0, [r5, #0x18]
	mov r0, r6
	b.n .L0800120a

@ ----------------------------------------------------------------------------
@ scsi_verify_10 - VERIFY(10), dispatched for CDB opcode 0x2F (0x08000D16).
@ r0 = device handle, r1 = LUN. S = [[r0+4]+0x24]. If CDB byte S+0x1030 bit 1
@ is set: sense 5 / 0x24 via 0x08001184 and returns 1. Otherwise LBA =
@ big-endian S+0x1031..0x1034 -> S+0x10, count = big-endian S+0x1036..0x1037
@ -> S+0x14; calls 0x08000BB8(dev,lun,lba,count); on 0 sets S+0x18 = 0 and
@ returns 0, else returns 1. No data is read or compared.
@ ----------------------------------------------------------------------------
	.section .text.scsi_verify_10,"ax",%progbits
	.global scsi_verify_10
	.thumb_func
	.type scsi_verify_10, %function
scsi_verify_10:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r6, r0
	mov r7, r1
	mov r8, r6
	ldr.w r0, [r8, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	add.w r0, r4, #0x1020
	add.w r5, r0, #0xf             @ r5 = S+0x102F
	movw r0, #0x1030
	ldrb r0, [r0, r4]
	and.w r0, r0, #2
	cmp r0, #2
	bne.n .L0800124c
	movs r2, #0x24
	movs r1, #5
	mov r0, r6
	bl scsi_set_sense
	movs r0, #1
.L08001248:
	pop.w {r4, r5, r6, r7, r8, pc}
.L0800124c:
	ldrb r0, [r5, #2]
	lsls r0, r0, #0x18
	ldrb r1, [r5, #3]
	orr.w r0, r0, r1, lsl #0x10
	ldrb r1, [r5, #4]
	orr.w r0, r0, r1, lsl #8
	ldrb r1, [r5, #5]
	orrs r0, r1
	str r0, [r4, #0x10]
	ldrb r0, [r5, #8]
	ldrb r1, [r5, #7]
	orr.w r0, r0, r1, lsl #8
	str r0, [r4, #0x14]
	mov r1, r7
	mov r0, r6
	ldrd r2, r3, [r4, #0x10]
	bl check_lba_range_or_set_sense
	cbz r0, .L0800127e
	movs r0, #1
	b.n .L08001248
.L0800127e:
	movs r0, #0
	str r0, [r4, #0x18]
	nop
	b.n .L08001248

@ ----------------------------------------------------------------------------
@ scsi_write_10 - SCSI WRITE(10), CDB opcode 0x2A, called from the opcode
@ switch at 0x08000D26 with r0 = device handle, r1 = LUN. S = [[r0+4]+0x24]
@ with the same fields as 0x08000F74.
@ If S+0 == 7 (first call): CBW flags bit 7 must be clear, else sense 5 / 0x20
@ and return 1; LBA and block count parsed as in 0x08000F74 (S+0x1031..0x1034,
@ S+0x1036..0x1037), range check 0x08000BB8 nonzero -> return 1, both
@ multiplied by the word at S+0xC+lun*4, mismatch with S+0x1028 -> sense 5 /
@ 0x20 and return 1; S+0 = 2; arms 0x08003D88(dev, 1, S+0x1C,
@ min(S+0x14, 0x1000)); returns 0.
@ Later calls (S+0 != 7, after the data arrived): n = min(S+0x14, 0x1000);
@ writes n bytes from S+0x1C to byte address S+0x10 with
@ 0x08002AB2(lun, addr, buf, n); nonzero -> sense 4 / 0x3A and return 1; else
@ S+0x10 += n, S+0x14 -= n, S+0x1048 -= n; if S+0x14 == 0 calls
@ 0x080010F0(dev, 0), else arms the next receive of min(S+0x14, 0x1000) bytes
@ into S+0x1C; returns 0.
@ ----------------------------------------------------------------------------
	.section .text.scsi_write_10,"ax",%progbits
	.global scsi_write_10
	.thumb_func
	.type scsi_write_10, %function
scsi_write_10:
	push.w {r4, r5, r6, r7, r8, r9, r10, lr}
	mov r8, r0
	mov r7, r1
	mov r9, r8
	ldr.w r0, [r9, #4]
	ldr r4, [r0, #0x24]            @ r4 = S
	add.w r0, r4, #0x1020
	add.w r6, r0, #0xf             @ r6 = S+0x102F (CDB opcode byte)
	ldrb r0, [r4, #0]
	cmp r0, #7
	bne.n .L08001350
	movw r0, #0x102c
	ldrb r0, [r0, r4]
	and.w r0, r0, #0x80
	cmp r0, #0x80
	bne.n .L080012c2
	movs r2, #0x20
	movs r1, #5
	mov r0, r8
	bl scsi_set_sense
	movs r0, #1
.L080012be:
	pop.w {r4, r5, r6, r7, r8, r9, r10, pc}
.L080012c2:
	ldrb r0, [r6, #2]
	lsls r0, r0, #0x18
	ldrb r1, [r6, #3]
	orr.w r0, r0, r1, lsl #0x10
	ldrb r1, [r6, #4]
	orr.w r0, r0, r1, lsl #8
	ldrb r1, [r6, #5]
	orrs r0, r1
	str r0, [r4, #0x10]
	ldrb r0, [r6, #8]
	ldrb r1, [r6, #7]
	orr.w r0, r0, r1, lsl #8
	str r0, [r4, #0x14]
	mov r1, r7
	mov r0, r8
	ldrd r2, r3, [r4, #0x10]
	bl check_lba_range_or_set_sense
	cbz r0, .L080012f4
	movs r0, #1
	b.n .L080012be
.L080012f4:
	add.w r1, r4, #0xc
	ldr.w r1, [r1, r7, lsl #2]
	ldr r0, [r4, #0x10]
	muls r0, r1, r0
	str r0, [r4, #0x10]
	add.w r1, r4, #0xc
	ldr.w r1, [r1, r7, lsl #2]
	ldr r0, [r4, #0x14]
	muls r0, r1, r0
	str r0, [r4, #0x14]
	movw r0, #0x1028
	ldr r0, [r0, r4]
	ldr r1, [r4, #0x14]
	cmp r0, r1
	beq.n .L0800132a
	movs r2, #0x20
	movs r1, #5
	mov r0, r8
	bl scsi_set_sense
	movs r0, #1
	b.n .L080012be
.L0800132a:
	movs r0, #2
	strb r0, [r4, #0]
	ldr r0, [r4, #0x14]
	cmp.w r0, #0x1000
	bcs.n .L0800133a
	ldr r0, [r4, #0x14]
	b.n .L0800133e
.L0800133a:
	mov.w r0, #0x1000
.L0800133e:
	uxth r5, r0                    @ n
	mov r3, r5
	add.w r2, r4, #0x1c
	movs r1, #1
	mov r0, r9
	bl fn_08003d88
	b.n .L080013c8
.L08001350:
	ldr r0, [r4, #0x14]
	cmp.w r0, #0x1000
	bcs.n .L0800135c
	ldr r0, [r4, #0x14]
	b.n .L08001360
.L0800135c:
	mov.w r0, #0x1000
.L08001360:
	uxth r5, r0                    @ n
	mov r3, r5
	add.w r2, r4, #0x1c
	mov r0, r7
	ldr r1, [r4, #0x10]
	bl fn_08002ab2
	cbz r0, .L08001380
	movs r2, #0x3a
	movs r1, #4
	mov r0, r8
	bl scsi_set_sense
	movs r0, #1
	b.n .L080012be
.L08001380:
	ldr r0, [r4, #0x10]
	add r0, r5
	str r0, [r4, #0x10]
	ldr r0, [r4, #0x14]
	subs r0, r0, r5
	str r0, [r4, #0x14]
	movw r0, #0x1048
	ldr r0, [r0, r4]
	subs r1, r0, r5
	movw r0, #0x1048
	str r1, [r0, r4]
	ldr r0, [r4, #0x14]
	cbnz r0, .L080013a8
	movs r1, #0
	mov r0, r8
	bl fn_080010f0
	b.n .L080013c8
.L080013a8:
	ldr r0, [r4, #0x14]
	cmp.w r0, #0x1000
	bcs.n .L080013b4
	ldr r0, [r4, #0x14]
	b.n .L080013b8
.L080013b4:
	mov.w r0, #0x1000
.L080013b8:
	uxth r5, r0                    @ n
	mov r3, r5
	add.w r2, r4, #0x1c
	movs r1, #1
	mov r0, r9
	bl fn_08003d88
.L080013c8:
	movs r0, #0
	b.n .L080012be

@ ----------------------------------------------------------------------------
@ fn_080013cc - calls 0x08003C14(dev, 0x81) then 0x08003C14(dev, 1) and
@ returns 0. Address stored as a word in the initial RAM table at 0x20000100
@ (rwdata_20000000.bin offset 0x100); no direct caller. Purpose not determined
@ from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080013cc,"ax",%progbits
	.p2align 2
	.global fn_080013cc
	.thumb_func
	.type fn_080013cc, %function
fn_080013cc:
	push {r4, r5, r6, lr}
	mov r4, r0
	movs r5, #0
	mov r6, r4
	movs r1, #0x81
	mov r0, r6
	bl fn_08003c14
	movs r1, #1
	mov r0, r6
	bl fn_08003c14
	mov r0, r5
	pop {r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_080013e8 - calls 0x08004240(dev, 0) (result discarded, it reads a
@ halfword at dev+0x11C) and returns 0. Address stored as a word at
@ 0x2000010C (rwdata_20000000.bin offset 0x10C); no direct caller. Purpose not
@ determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080013e8,"ax",%progbits
	.global fn_080013e8
	.thumb_func
	.type fn_080013e8, %function
fn_080013e8:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r4, r0
	movs r5, #0
	mov r6, r4
	movs r1, #0
	mov r0, r6
	bl out_endpoint_length_done
	mov r7, r0
	mov r0, r5
	pop.w {r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_08001402 - does r1 = r0 and returns 0 in r0 (movs r0,#0 at 0x08001404); no
@ memory access. Address stored as a word at
@ 0x20000108 (initial RAM data, offset 0x108); no direct caller. Purpose not
@ determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001402,"ax",%progbits
	.global fn_08001402
	.thumb_func
	.type fn_08001402, %function
fn_08001402:
	mov r1, r0
	movs r0, #0
	bx lr

@ ----------------------------------------------------------------------------
@ fn_08001408 - does r2 = r0, r0 = 0, then compares r1 with 1, 2 and 3
@ (0x0800140C..0x08001416): r1 == 1 branches to 0x0800141A, r1 == 2 to
@ 0x0800141C, r1 == 3 reaches 0x08001418 (b to 0x0800141E), any other r1
@ branches to 0x08001420 (nop); 0x0800141A, 0x0800141C and 0x0800141E each
@ branch to 0x08001422 (nop), and 0x08001420 falls into it; all paths end at
@ the bx lr at 0x08001424 with no effect. Returns 0 in r0. Address stored as a
@ word at 0x2000011C (rwdata_20000000.bin offset 0x11C); no direct caller.
@ Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001408,"ax",%progbits
	.global fn_08001408
	.thumb_func
	.type fn_08001408, %function
fn_08001408:
	mov r2, r0
	movs r0, #0
	cmp r1, #1
	beq.n .L0800141a
	cmp r1, #2
	beq.n .L0800141c
	cmp r1, #3
	bne.n .L08001420
	b.n .L0800141e
.L0800141a:
	b.n .L08001422
.L0800141c:
	b.n .L08001422
.L0800141e:
	b.n .L08001422
.L08001420:
	nop
.L08001422:
	nop
	bx lr

@ ----------------------------------------------------------------------------
@ fn_08001426 - calls 0x08000D58(r0, r1) and returns 0. Address stored as a
@ word at 0x20000110 (rwdata_20000000.bin offset 0x110); no direct caller.
@ Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001426,"ax",%progbits
	.global fn_08001426
	.thumb_func
	.type fn_08001426, %function
fn_08001426:
	push {r4, r5, r6, lr}
	mov r4, r0
	mov r5, r1
	movs r6, #0
	mov r1, r5
	mov r0, r4
	bl fn_08000d58
	mov r0, r6
	pop {r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_0800143a - calls 0x08003D2E(dev, 0x81, 1, 0x40), 0x08003D2E(dev, 1, 1,
@ 0x40) (0x08003D2E sets up an endpoint record: direction by bit 7 of arg 2,
@ type arg 3, size arg 4 + 1 rounded down to even) and 0x08000E70(dev);
@ returns 0. Address stored as a word at 0x200000FC (rwdata_20000000.bin
@ offset 0xFC); no direct caller. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800143a,"ax",%progbits
	.global fn_0800143a
	.thumb_func
	.type fn_0800143a, %function
fn_0800143a:
	push {r4, r5, r6, lr}
	mov r4, r0
	movs r5, #0
	mov r6, r4
	movs r3, #0x40
	movs r2, #1
	movs r1, #0x81
	mov r0, r6
	bl fn_08003d2e
	movs r3, #0x40
	movs r2, #1
	mov r1, r2
	mov r0, r6
	bl fn_08003d2e
	mov r0, r4
	bl start_command_packet_receive
	mov r0, r5
	pop {r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_08001464 - calls 0x08000D9C(r0, r1) and returns 0. Address stored as a
@ word at 0x20000114 (rwdata_20000000.bin offset 0x114); no direct caller.
@ Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001464,"ax",%progbits
	.p2align 2
	.global fn_08001464
	.thumb_func
	.type fn_08001464, %function
fn_08001464:
	push {r4, r5, r6, lr}
	mov r4, r0
	mov r5, r1
	movs r6, #0
	mov r1, r5
	mov r0, r4
	bl fn_08000d9c
	mov r0, r6
	pop {r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_08001478 - setup-request handler. r0 = device handle, r1 = pointer to the
@ 8-byte setup packet P; S = [[r0+4]+0x24]. Switch on P[0] & 0x60.
@ Value 0: P[1] == 1: 0x08003C14(dev, P[4]) then 0x08003D2E(dev, P[4], 1,
@ 0x40) (both branches of the P[4] bit 7 test make this same call) then
@ 0x08000BF0(dev, P[4]); P[1] == 6: 0x080039D6(dev); P[1] == 10:
@ 0x08003996(dev, S+0x101C, 1) (sends 1 byte from S+0x101C); P[1] == 11: word
@ S+0x101C = halfword P[2..3]; any other P[1] with value 0: nothing is called.
@ Value 0x20: P[1] == 0xFE: 0x08003996(dev, S+4, 1) (sends the byte at S+4,
@ initial 0 set by 0x080010C8); P[1] == 0xFF: 0x080010C8(dev) then
@ 0x080039BE(dev); other P[1]: 0x080039D6(dev). Other values of P[0] & 0x60
@ (0x40, 0x60): 0x080039D6(dev) (calls 0x08004538 on endpoints 0 and 0x80).
@ Returns 0. Address stored as a word at 0x20000104 (rwdata_20000000.bin
@ offset 0x104); no direct caller.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001478,"ax",%progbits
	.global fn_08001478
	.thumb_func
	.type fn_08001478, %function
fn_08001478:
	push.w {r4, r5, r6, r7, r8, lr}
	mov r5, r0
	mov r4, r1
	mov.w r8, #0
	mov r7, r5
	ldr r0, [r7, #4]
	ldr r6, [r0, #0x24]            @ r6 = S
	ldrb r0, [r4, #0]
	and.w r0, r0, #0x60
	cbz r0, .L080014c8
	cmp r0, #0x20
	bne.n .L0800153a
	ldrb r0, [r4, #1]
	cmp r0, #0xfe
	beq.n .L080014a2
	cmp r0, #0xff
	bne.n .L080014bc
	b.n .L080014ae
.L080014a2:
	movs r2, #1
	adds r1, r6, #4
	mov r0, r7
	bl fn_08003996
	b.n .L080014c4
.L080014ae:
	mov r0, r5
	bl fn_080010c8
	mov r0, r7
	bl fn_080039be
	b.n .L080014c4
.L080014bc:
	mov r0, r7
	bl fn_080039d6
	nop
.L080014c4:
	nop
	b.n .L08001542
.L080014c8:
	ldrb r0, [r4, #1]
	cmp r0, #1
	beq.n .L080014fe
	cmp r0, #6
	beq.n .L080014dc
	cmp r0, #0xa
	beq.n .L080014e4
	cmp r0, #0xb
	bne.n .L08001534
	b.n .L080014f4
.L080014dc:
	mov r0, r7
	bl fn_080039d6
	b.n .L08001536
.L080014e4:
	movs r2, #1
	movw r0, #0x101c
	adds r1, r6, r0
	mov r0, r7
	bl fn_08003996
	b.n .L08001536
.L080014f4:
	ldrh r1, [r4, #2]
	movw r0, #0x101c
	str r1, [r0, r6]
	b.n .L08001536
.L080014fe:
	ldrb r1, [r4, #4]
	mov r0, r7
	bl fn_08003c14
	ldrb r0, [r4, #4]
	and.w r0, r0, #0x80
	cmp r0, #0x80
	bne.n .L0800151e
	ldrb r1, [r4, #4]
	movs r3, #0x40
	movs r2, #1
	mov r0, r7
	bl fn_08003d2e
	b.n .L0800152a
.L0800151e:
	ldrb r1, [r4, #4]
	movs r3, #0x40
	movs r2, #1
	mov r0, r7
	bl fn_08003d2e
.L0800152a:
	ldrb r1, [r4, #4]
	mov r0, r5
	bl fn_08000bf0
	b.n .L08001536
.L08001534:
	nop
.L08001536:
	nop
	b.n .L08001542
.L0800153a:
	mov r0, r7
	bl fn_080039d6
	nop
.L08001542:
	nop
	mov r0, r8
	pop.w {r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_0800154a - does r1 = r0 and returns 0 in r0; no memory access (same body
@ as 0x08001402). Address stored as a word at 0x20000118
@ (rwdata_20000000.bin offset 0x118); no direct caller. Purpose not determined
@ from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800154a,"ax",%progbits
	.global fn_0800154a
	.thumb_func
	.type fn_0800154a, %function
fn_0800154a:
	mov r1, r0
	movs r0, #0
	bx lr
