@ keys_26.s - battery / key state handlers fn_08009c78, fn_08009fe0, fn_08009fe8, the key event task and the key scanner
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08009c78 - periodic handler built on bit7 of 0x40011008 and the counters at
@ 0x2000105e..0x20001060. No parameters.
@ Increments [0x2000105e]. Only when it is above 4:
@   if [0x20002d68]==0 and bit7 of 0x40011008 is set: sets bit22 of 0x40012408,
@   waits until bit1 of 0x40012400 is set, reads the low 16 bits of 0x4001244c,
@   converts them to double (u32_to_double), multiplies by 0.00087890625
@   (0x3f4ccccc:cccccccd, double_mul), applies double_add(x,x), double_to_float
@   and float_to_double, then tests the double with double_gt against 4.06,
@   3.98, 3.92, 3.87, 3.82, 3.79, 3.77, 3.74, 3.68 in that order: the first
@   nonzero result stores 100, 90, 80, 70, 60, 50, 40, 30 or 15 into
@   [0x2000105f]; no hit stores 5.
@   Then sends code 7 to queue [0x20002d6c] (queue_send_timeout) when
@   [0x20001060]-1<5 or [0x20001060]==9; limits [0x2000105f] to [0x20000004] and
@   stores it there; below 6: sets bit7 of [0x20001060] and sends 0x22 if it was
@   clear, sends 0x23, calls save_settings_to_flash(0x55) (never returns) when
@   [0x2000105e]>14, else continues at the common tail; at 6 or more sets
@   [0x2000105e]=4.
@ Common tail (also reached when [0x20002d68]!=0 or bit7 clear): when bit7 of
@   0x40011008 is clear sets [0x2000105e]=4, [0x20000004]=100, [0x20002d68]=1;
@   when set clears [0x20002d68]; when clear and ([0x20001060]&0x7f) is 1..5 or
@   9: clears bit7 and calls send_state_message_sequence if bit7 was set, else
@   sends 10; when the low 7 bits are 0 and bit7 set: sets [0x20001060]=0 and
@   calls send_state_message_sequence.
@ Last part: edge detector on bit7 of 0x40011008 with flag [0x20002d69] (set when
@   [0x2000105f]<=10 and bit7 set, cleared otherwise) that sends code 9 on a
@   change when [0x20001060]-1<5 or ==9.
@ Purpose beyond this mechanics not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08009c78,"ax",%progbits
	.global fn_08009c78
	.thumb_func
	.type fn_08009c78, %function
fn_08009c78:
	push.w {r4, r5, r6, r7, r8, lr}
	sub sp, #8
	movw r6, #0xf8
	movt r6, #0x2000
	ldrb.w r0, [r6, #0xf66]
	movw r7, #0x1008
	adds r0, #1
	uxtb r1, r0
	movt r7, #0x4001
	cmp r1, #5
	strb.w r0, [r6, #0xf66]
	bcc.w .L08009ef4
	movw r8, #0x2d68
	movt r8, #0x2000
	ldrb.w r0, [r8]
	cbnz r0, .L08009cb4
	ldr r0, [r7]
	lsls r0, r0, #0x18
	bmi.n .L08009d14
.L08009cb4:
	ldr r0, [r7]
	lsls r0, r0, #0x18
	bmi.n .L08009cd2
	movs r0, #4
	strb.w r0, [r6, #0xf66]
	movw r0, #4
	movt r0, #0x2000
	movs r1, #0x64
	strb r1, [r0]
	movs r0, #1
	strb.w r0, [r8]
.L08009cd2:
	ldr r0, [r7]
	lsls r0, r0, #0x18
	bmi.n .L08009d0c
	ldrb.w r0, [r6, #0xf68]
	and.w r1, r0, #0x7f
	subs r2, r1, #1
	cmp r2, #5
	bcs.n .L08009d78
.L08009ce6:
	sxtb r0, r0
	cmp.w r0, #-1
	ble.n .L08009da2
	movw r0, #0x2d6c
	movt r0, #0x2000
	movs r1, #0xa
	ldr r0, [r0]
	strb.w r1, [sp, #7]
	add.w r1, sp, #7
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	b.n .L08009ef4
.L08009d0c:
	movs r0, #0
	strb.w r0, [r8]
	b.n .L08009ef4
.L08009d14:
	movw r0, #0x2400
	movt r0, #0x4001
	ldr r1, [r0, #8]
	orr.w r1, r1, #0x400000
	str r1, [r0, #8]
.L08009d24:
	ldr r1, [r0]
	lsls r1, r1, #0x1e
	itttt pl
	ldrpl r1, [r0]
	lslspl.w r1, r1, #0x1e
	ldrpl r1, [r0]
	lslspl.w r1, r1, #0x1e
	bmi.n .L08009d3e
	ldr r1, [r0]
	lsls r1, r1, #0x1e
	bpl.n .L08009d24
.L08009d3e:
	ldr r0, [r0, #0x4c]
	uxth r0, r0
	bl u32_to_double
	vldr d0, .L08009f90
	vmov r2, r3, d0
	bl double_mul
	mov r2, r0
	mov r3, r1
	bl double_add
	bl double_to_float
	bl float_to_double
	vldr d0, .L08009f98
	mov r4, r0
	vmov r2, r3, d0
	mov r5, r1
	bl double_gt
	cbz r0, .L08009d8c
	movs r1, #0x64
	b.n .L08009e4c
.L08009d78:
	cmp r1, #9
	beq.n .L08009ce6
	cmp r1, #0
	bne.w .L08009ef4
	lsls r0, r0, #0x18
	bpl.w .L08009ef4
	movs r0, #0
	b.n .L08009da6
.L08009d8c:
	vldr d0, .L08009fa0
	mov r0, r4
	vmov r2, r3, d0
	mov r1, r5
	bl double_gt
	cbz r0, .L08009db0
	movs r1, #0x5a
	b.n .L08009e4c
.L08009da2:
	and.w r0, r0, #0x7f
.L08009da6:
	strb.w r0, [r6, #0xf68]
	bl send_state_message_sequence
	b.n .L08009ef4
.L08009db0:
	vldr d0, .L08009fa8
	mov r0, r4
	vmov r2, r3, d0
	mov r1, r5
	bl double_gt
	cbz r0, .L08009dc6
	movs r1, #0x50
	b.n .L08009e4c
.L08009dc6:
	vldr d0, .L08009fb0
	mov r0, r4
	vmov r2, r3, d0
	mov r1, r5
	bl double_gt
	cbz r0, .L08009ddc
	movs r1, #0x46
	b.n .L08009e4c
.L08009ddc:
	vldr d0, .L08009fb8
	mov r0, r4
	vmov r2, r3, d0
	mov r1, r5
	bl double_gt
	cbz r0, .L08009df2
	movs r1, #0x3c
	b.n .L08009e4c
.L08009df2:
	vldr d0, .L08009fc0
	mov r0, r4
	vmov r2, r3, d0
	mov r1, r5
	bl double_gt
	cbz r0, .L08009e08
	movs r1, #0x32
	b.n .L08009e4c
.L08009e08:
	vldr d0, .L08009fc8
	mov r0, r4
	vmov r2, r3, d0
	mov r1, r5
	bl double_gt
	cbz r0, .L08009e1e
	movs r1, #0x28
	b.n .L08009e4c
.L08009e1e:
	vldr d0, .L08009fd0
	mov r0, r4
	vmov r2, r3, d0
	mov r1, r5
	bl double_gt
	cbz r0, .L08009e34
	movs r1, #0x1e
	b.n .L08009e4c
.L08009e34:
	vldr d0, .L08009fd8
	mov r0, r4
	vmov r2, r3, d0
	mov r1, r5
	bl double_gt
	movs r1, #5
	cmp r0, #0
	it ne
	movne r1, #0xf
.L08009e4c:
	ldrb.w r0, [r6, #0xf68]
	strb.w r1, [r6, #0xf67]
	subs r2, r0, #1
	cmp r2, #5
	bcs.w .L08009f7c
.L08009e5c:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movs r1, #7
	ldr r0, [r0]
	strb.w r1, [sp, #7]
	add.w r1, sp, #7
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldrb.w r1, [r6, #0xf67]
.L08009e7c:
	movw r2, #4
	movt r2, #0x2000
	ldrb r0, [r2]
	cmp r0, r1
	itte ls
	strbls.w r0, [r6, #0xf67]
	movls r1, r0
	strbhi r1, [r2]
	cmp r1, #6
	bcc.n .L08009e9e
	movs r0, #4
	strb.w r0, [r6, #0xf66]
	b.n .L08009ef4
.L08009e9e:
	ldrsb.w r0, [r6, #0xf68]
	cmp r0, #0
	bmi.n .L08009eca
	orr.w r0, r0, #0x80
	strb.w r0, [r6, #0xf68]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movs r1, #0x22
	ldr r0, [r0]
	strb.w r1, [sp, #7]
	add.w r1, sp, #7
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L08009eca:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movs r1, #0x23
	ldr r0, [r0]
	strb.w r1, [sp, #7]
	add.w r1, sp, #7
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldrb.w r0, [r6, #0xf66]
	cmp r0, #0xf
	bcs.n .L08009f8a
	cmp r0, #5
	bcs.w .L08009cb4
.L08009ef4:
	ldr r0, [r7]
	lsls r0, r0, #0x18
	bmi.n .L08009f1c
	movw r0, #0x2d69
	movt r0, #0x2000
	ldrb r1, [r0]
	cmp r1, #1
	bne.n .L08009f46
	ldrb.w r1, [r6, #0xf68]
	movs r2, #0
	subs r3, r1, #1
	cmp r3, #5
	strb r2, [r0]
	bcc.n .L08009f5a
	cmp r1, #9
	beq.n .L08009f5a
	b.n .L08009f46
.L08009f1c:
	movw r0, #0x2d69
	ldrb.w r2, [r6, #0xf67]
	movt r0, #0x2000
	ldrb r1, [r0]
	cmp r2, #0xb
	bcc.n .L08009f44
	cbz r1, .L08009f46
	ldrb.w r1, [r6, #0xf68]
	movs r2, #0
	subs r3, r1, #1
	cmp r3, #5
	strb r2, [r0]
	bcc.n .L08009f5a
	cmp r1, #9
	bne.n .L08009f46
	b.n .L08009f5a
.L08009f44:
	cbz r1, .L08009f4c
.L08009f46:
	add sp, #8
	pop.w {r4, r5, r6, r7, r8, pc}
.L08009f4c:
	ldrb.w r1, [r6, #0xf68]
	movs r2, #1
	subs r3, r1, #1
	cmp r3, #5
	strb r2, [r0]
	bcs.n .L08009f84
.L08009f5a:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movs r1, #9
	ldr r0, [r0]
	strb.w r1, [sp, #7]
	add.w r1, sp, #7
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	add sp, #8
	pop.w {r4, r5, r6, r7, r8, pc}
.L08009f7c:
	cmp r0, #9
	beq.w .L08009e5c
	b.n .L08009e7c
.L08009f84:
	cmp r1, #9
	bne.n .L08009f46
	b.n .L08009f5a
.L08009f8a:
	movs r0, #0x55
	bl save_settings_to_flash
.L08009f90:
	.word 0xcccccccd, 0x3f4ccccc	@ 0.00087890625 (double)
.L08009f98:
	.word 0xa3d70a3d, 0x40103d70	@ 4.06 (double)
.L08009fa0:
	.word 0x3d70a3d7, 0x400fd70a	@ 3.98 (double)
.L08009fa8:
	.word 0xf5c28f5c, 0x400f5c28	@ 3.92 (double)
.L08009fb0:
	.word 0x8f5c28f6, 0x400ef5c2	@ 3.87 (double)
.L08009fb8:
	.word 0x28f5c28f, 0x400e8f5c	@ 3.82 (double)
.L08009fc0:
	.word 0x851eb852, 0x400e51eb	@ 3.79 (double)
.L08009fc8:
	.word 0xc28f5c29, 0x400e28f5	@ 3.77 (double)
.L08009fd0:
	.word 0x1eb851ec, 0x400deb85	@ 3.74 (double)
.L08009fd8:
	.word 0xd70a3d71, 0x400d70a3	@ 3.68 (double)

@ ----------------------------------------------------------------------------
@ fn_08009fe0 - calls save_settings_to_flash(0x55); the call never returns.
@ ----------------------------------------------------------------------------
	.global fn_08009fe0
	.thumb_func
	.type fn_08009fe0, %function
fn_08009fe0:
	movs r0, #0x55
	bl save_settings_to_flash
	.short 0x0000	@ padding, never reached

@ ----------------------------------------------------------------------------
@ fn_08009fe8 - state switch on [0x20001060]. No parameters.
@   1: clears [0x20001055] unless its high nibble is 0xb.
@   2: sets [0x20001060]=9, clears halfword [0x20001061], byte [0x20001063] and
@      calls send_state_message_sequence (08012908).
@   3: when [0x20001061]==2 stores [0x20001062]<<8|1 into the halfword at
@      0x20001061 and masks [0x20001063]&=0xf; when ==1 clears [0x20001063] and
@      stores [0x20001062]<<8; any other value returns; then sends code 0x19
@      (byte [0x20002d53]) to queue [0x20002d6c] with queue_send_timeout.
@   4: only when [0x20001061]==1: stores [0x20001062]<<8 into the halfword at
@      0x20001061, clears [0x20001063], sends 0x20 and 0x21.
@   9: when [0x20001061]!=0 and [0x2000044d]!=1: if [0x20001061]==2 stores
@      [0x20001062]<<8|1, masks [0x20001063]&=0xf and sends 0x14; if ==1 stores
@      [0x20001062]<<8, clears [0x20001063] and sends 0x13 then 0x14; other
@      values return; otherwise ([0x20001061]==0 or [0x2000044d]==1) clears
@      [0x2000044d], sets [0x20001060]=2, clears halfword [0x20001061] and
@      [0x20001063] and calls send_state_message_sequence.
@   other states return. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.global fn_08009fe8
	.thumb_func
	.type fn_08009fe8, %function
fn_08009fe8:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	subs r1, #1
	cmp r1, #8
	bhi.n .L0800a074
	tbb [pc, r1]
.L0800a000:
	.byte (.L0800a00a - .L0800a000)/2
	.byte (.L0800a01e - .L0800a000)/2
	.byte (.L0800a028 - .L0800a000)/2
	.byte (.L0800a03c - .L0800a000)/2
	.byte (.L0800a074 - .L0800a000)/2
	.byte (.L0800a074 - .L0800a000)/2
	.byte (.L0800a074 - .L0800a000)/2
	.byte (.L0800a074 - .L0800a000)/2
	.byte (.L0800a076 - .L0800a000)/2
	.byte 0x00	@ padding
.L0800a00a:
	ldrb.w r1, [r0, #0xf5d]
	and.w r1, r1, #0xf0
	cmp r1, #0xb0
	itt ne
	movne r1, #0
	strbne.w r1, [r0, #0xf5d]
	b.n .L0800a074
.L0800a01e:
	movs r1, #9
	strb.w r1, [r0, #0xf68]
	movs r1, #0
	b.n .L0800a0d8
.L0800a028:
	ldrb.w r1, [r0, #0xf69]
	cmp r1, #2
	beq.n .L0800a0e8
	cmp r1, #1
	bne.n .L0800a074
	movs r1, #0
	strb.w r1, [r0, #0xf69]
	b.n .L0800a0f6
.L0800a03c:
	ldrb.w r1, [r0, #0xf69]
	cmp r1, #1
	bne.n .L0800a074
	movw r5, #0x2d6c
	movs r1, #0
	movw r4, #0x2d53
	movt r5, #0x2000
	strb.w r1, [r0, #0xf69]
	strb.w r1, [r0, #0xf6b]
	movt r4, #0x2000
	movs r1, #0x20
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x21
	b.n .L0800a0bc
.L0800a074:
	pop {r4, r5, r7, pc}
.L0800a076:
	ldrb.w r1, [r0, #0xf69]
	cbz r1, .L0800a0cc
	ldrb.w r2, [r0, #0x355]
	cmp r2, #1
	beq.n .L0800a0cc
	cmp r1, #2
	beq.n .L0800a110
	cmp r1, #1
	it ne
	popne {r4, r5, r7, pc}
	movw r5, #0x2d6c
	movs r1, #0
	movw r4, #0x2d53
	movt r5, #0x2000
	strb.w r1, [r0, #0xf69]
	strb.w r1, [r0, #0xf6b]
	movt r4, #0x2000
	movs r1, #0x13
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x14
.L0800a0bc:
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
.L0800a0cc:
	movs r1, #0
	movs r2, #2
	strb.w r1, [r0, #0x355]
	strb.w r2, [r0, #0xf68]
.L0800a0d8:
	strh.w r1, [r0, #0xf69]
	strb.w r1, [r0, #0xf6b]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800a0e8:
	ldrb.w r2, [r0, #0xf6b]
	movs r1, #1
	strb.w r1, [r0, #0xf69]
	and.w r1, r2, #0xf
.L0800a0f6:
	strb.w r1, [r0, #0xf6b]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x19
	b.n .L0800a136
.L0800a110:
	ldrb.w r2, [r0, #0xf6b]
	movs r1, #1
	strb.w r1, [r0, #0xf69]
	and.w r1, r2, #0xf
	strb.w r1, [r0, #0xf6b]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x14
.L0800a136:
	mov.w r2, #0xffffffff
	strb r3, [r1]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
	.short 0x0000	@ padding, never reached
	.short 0x0000	@ padding, never reached

@ ----------------------------------------------------------------------------
@ fn_08040008 - task body that dispatches code bytes to handlers through the
@ word table at 0x08046544. No parameters; never returns (infinite outer loop).
@ Loop: queue_receive_timeout(*0x20002d70, &byte, 0xffffffff) blocks without time
@ limit until it returns 1, leaving one received byte (code byte) in a stack
@ variable (the producer is fn_080400b8, which posts its code byte to the same
@ queue handle *0x20002d70 with queue_send_timeout). Then: if
@ (byte 0x20000f08 & 0xfe)==2 it clears 0x20000f08 and takes the dispatch
@ branch; else if 0x20000f08 is neither 1 nor 0xff it takes the dispatch branch;
@ 0x20000f08 equal to 1 or 0xff skips dispatch.
@ Dispatch: only when bytes 0x20000127, 0x20000128, 0x2000012b and 0x20001024 are
@ all 0 it calls the function whose address is the word at 0x08046544 + code*4
@ (word table: element 0 at 0x08046544 is 0x00001700, handlers from 0x08046548
@ are odd Thumb addresses 0x08009fe1, 0x0800cb51, ...; indirect call ldr.w/blx).
@ After every received code: if byte 0x2000105a != 0 it is written to 0x40015434;
@ then 0 is stored to 0x20001064.
@ ----------------------------------------------------------------------------
	.section .text.fn_08040008,"ax",%progbits
	.global fn_08040008
	.thumb_func
	.type fn_08040008, %function
fn_08040008:
	sub sp, #8
	movw r6, #0x2d70
	movw r7, #0xf8
	movw r8, #:lower16:d_08046548
	movw r9, #0x5434
	movs r5, #0
	movt r6, #0x2000
	add.w r4, sp, #7
	movt r7, #0x2000
	movt r8, #:upper16:d_08046548
	movt r9, #0x4001
	strb.w r5, [sp, #7]
	b.n .L08040048
	.byte 0x00, 0xbf	@ padding, never reached
.L08040038:
	ldrb.w r0, [r7, #0xf62]
	cmp r0, #0
	it ne
	strne.w r0, [r9]
	strh.w r5, [r7, #0xf6c]
.L08040048:
	ldr r0, [r6]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_receive_timeout
	cmp r0, #1
	bne.n .L08040048
	ldrb.w r0, [r7, #0xe10]
	and.w r1, r0, #0xfe
	cmp r1, #2
	bne.n .L0804006c
	strb.w r5, [r7, #0xe10]
	b.n .L08040074
	.byte 0x00, 0xbf	@ padding, never reached
.L0804006c:
	cmp r0, #1
	beq.n .L08040038
	cmp r0, #0xff
	beq.n .L08040038
.L08040074:
	ldrb.w r0, [r7, #0x2f]
	ldrb.w r1, [r7, #0x30]
	ldrb.w r2, [r7, #0x33]
	orrs r0, r1
	ldrb.w r1, [r7, #0xf2c]
	orrs r0, r2
	orrs r0, r1
	bne.n .L08040038
	ldrb.w r0, [sp, #7]
	add.w r0, r8, r0, lsl #2
	ldr.w r0, [r0, #-4]
	blx r0
	b.n .L08040038

@ ----------------------------------------------------------------------------
@ fn_080400b8 - key scanner. No parameters.
@ Scans input pins into a 15-bit mask, debounces five groups of three bits and
@ posts code bytes to a queue; also runs several software down-counters.
@ Mechanics: 0x20002d56 (halfword mask) = bit0 if bit8 of 0x40011008 is clear,
@ | 0x40 if bit7 of 0x40010c08 is set, | 0x400 if bit13 of 0x40011008 is clear.
@ Pin setup through set_nibble_fields_from_bit_mask(port, &cfg) on 0x40010800
@ (mask 0x80), 0x40010c00 (1), 0x40011000 (0x20), 0x40011800 (4), then
@ 0x40010800 (0x100), 0x40011000 (0x400), 0x40011800 (8) with cfg byte1 0x28 /
@ byte2 0x10; then 0x40011814=8, 0x40010814=0x100, 0x40011014=0x400 (writes to
@ offset 0x14 of those ports). Then a 4-bit code c = (!bit3 of 0x40011808)<<3 |
@ (!bit2 of 0x40010c08)<<2 | (!bit5 of 0x40011008)<<1 | !bit7 of 0x40010808; if
@ c is 1, 2, 4 or 8 the pins are reconfigured the other way (masks 0x100, 0x400,
@ 8 then 0x80, 1, 0x20, 4), 0x40010814=0x80, 0x40011014=0x20, 0x40010c14=1,
@ 0x40011814=4 are written, and bits are ORed into 0x20002d56 by switch(c): if
@ bit3 of 0x40011808 is clear: c=1:0x80, 2:0x800, 4:0x100, 8:0x200; if bit8 of
@ 0x40010808 is clear: c=1:0x20, 2:0x10, 4:8, 8:0x2000; if bit10 of 0x40011008
@ is clear: c=1:0x1000, 2:4, 4:0x4000, 8:2.
@ Debounce: for group start g = 0,3,6,9,12 each of bits g, g+1, g+2 has a byte
@ counter at 0x20002d58+bit: held bit counts up to 0xff; count 0x46 yields the
@ code from table 0x08046537[bit]; if its bit is set in byte 0x20002d50 and the
@ count is 0x48 it yields the code 0x08046528[bit] and the count drops by 1;
@ released bit with count 2..0x45 yields 0x08046528[bit]; released counter is
@ cleared. If fewer than 2 codes were produced and a code is nonzero it calls
@ queue_send_timeout(*0x20002d70, &code, 0).
@ Then: if word 0x40015434 != 0 byte 0x20002d67 is incremented and when it
@ reaches 0xb both are cleared (0x20002d67=0 also when the word is 0);
@ 0x20000135 counts 0..99; 0x20000f1c counts up while byte 0x20000f08 is 2..0xfe
@ and when it exceeds 100 0x20000f08 is cleared (0x20000f1c cleared when
@ 0x20000f08 < 2 or 0xff); 0x2000012a is incremented unless 0xff; 0x20000122,
@ 0x20000120 (halfwords), 0x20000124, 0x20000eb3, 0x20000eb2 (bytes) are
@ decremented while nonzero; byte 0x2000013d counts 0..0x32: at 0 the words
@ 0x40000024 and 0x40000c24 are cleared, at 0x33 (when byte 0x20000126 != 0) both
@ words are converted from unsigned to float, doubled and converted to int into
@ 0x20000148 and 0x20000178, 0x2000014c = 1000000000/0x20000148 and 0x2000017c =
@ 1000000000/0x20000178 (0 when the divisor is 0), 0x20000329 is copied to
@ 0x20000328 and cleared, then 0x2000013d=0.
@ Finally if bit0 of 0x40011008 is set 0x20000eb0 is cleared and it returns; else
@ if byte 0x2000010f != 2 and byte 0x20000125 < 0x14, 0x20000eb0 is incremented
@ and when it equals table byte 0x0804d833[0x20000125] + 0x32 the byte 1 is
@ posted twice to the queue handle *0x20002d78 with queue_send_timeout (timeout
@ 0xffffffff).
@ ----------------------------------------------------------------------------
	.section .text.fn_080400b8,"ax",%progbits
	.global fn_080400b8
	.thumb_func
	.type fn_080400b8, %function
fn_080400b8:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x14
	movw r11, #0x2d56
	movw r5, #0x1008
	movs r0, #0
	movt r11, #0x2000
	movt r5, #0x4001
	strb.w r0, [sp, #0xa]
	strh.w r0, [r11]
	ldr r0, [r5]
	lsls r0, r0, #0x17
	bmi.n .L080400ea
	ldrh.w r0, [r11]
	orr.w r0, r0, #1
	strh.w r0, [r11]
.L080400ea:
	movw r9, #0x800
	movt r9, #0x4001
	ldr.w r0, [r9, #0x408]
	lsls r0, r0, #0x18
	bpl.n .L08040106
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x40
	strh.w r0, [r11]
.L08040106:
	ldr r0, [r5]
	lsls r0, r0, #0x12
	bmi.n .L08040118
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x400
	strh.w r0, [r11]
.L08040118:
	movw r0, #0x1800
	movt r0, #0x100
	str r0, [sp, #0x10]
	movs r0, #0x80
	add r6, sp, #0xc
	movw r10, #0x1800
	str r0, [sp, #0xc]
	mov r0, r9
	mov r1, r6
	movt r10, #0x4001
	bl set_nibble_fields_from_bit_mask
	movs r0, #1
	str r0, [sp, #0xc]
	add.w r0, r9, #0x400
	mov r1, r6
	str r0, [sp, #4]
	bl set_nibble_fields_from_bit_mask
	movs r0, #0x20
	sub.w r7, r5, #8
	str r0, [sp, #0xc]
	mov r0, r7
	mov r1, r6
	bl set_nibble_fields_from_bit_mask
	movs r0, #4
	str r0, [sp, #0xc]
	mov r0, r10
	mov r1, r6
	bl set_nibble_fields_from_bit_mask
	movw r0, #0x1028
	strh.w r0, [sp, #0x11]
	mov.w r0, #0x100
	str r0, [sp, #0xc]
	mov r0, r9
	mov r1, r6
	bl set_nibble_fields_from_bit_mask
	mov.w r4, #0x400
	mov r0, r7
	mov r1, r6
	str r4, [sp, #0xc]
	bl set_nibble_fields_from_bit_mask
	mov.w r8, #8
	mov r0, r10
	mov r1, r6
	str.w r8, [sp, #0xc]
	bl set_nibble_fields_from_bit_mask
	mov.w r3, #0x100
	movs r0, #0
	str.w r8, [r10, #0x14]
	str.w r3, [r9, #0x14]
	str r4, [r5, #0xc]
	strb.w r0, [sp, #0xb]
	ldr.w r0, [r9, #8]
	ldrb.w r1, [sp, #0xb]
	mvns r0, r0
	uxtb r0, r0
	orr.w r0, r1, r0, lsr #7
	strb.w r0, [sp, #0xb]
	ldr r0, [r5]
	movs r1, #2
	ldrb.w r2, [sp, #0xb]
	bic.w r0, r1, r0, lsr #4
	orrs r0, r2
	strb.w r0, [sp, #0xb]
	ldr.w r0, [r9, #0x408]
	ldrb.w r1, [sp, #0xb]
	movs r2, #4
	bic.w r0, r2, r0, lsl #2
	orrs r0, r1
	strb.w r0, [sp, #0xb]
	ldr.w r0, [r10, #8]
	ldrb.w r1, [sp, #0xb]
	bic.w r0, r8, r0, lsl #1
	orrs r0, r1
	strb.w r0, [sp, #0xb]
	ldrb.w r0, [sp, #0xb]
	cmp r0, #1
	beq.n .L0804021a
	ldrb.w r0, [sp, #0xb]
	cmp r0, #2
	beq.n .L0804021a
	ldrb.w r0, [sp, #0xb]
	cmp r0, #4
	beq.n .L0804021a
	ldrb.w r0, [sp, #0xb]
	cmp r0, #8
	bne.w .L08040374
.L0804021a:
	movw r0, #0x1800
	movt r0, #0x100
	add r6, sp, #0xc
	strd r3, r0, [sp, #0xc]
	mov r0, r9
	mov r1, r6
	bl set_nibble_fields_from_bit_mask
	mov r0, r7
	mov r1, r6
	str r4, [sp, #0xc]
	bl set_nibble_fields_from_bit_mask
	mov r0, r10
	mov r1, r6
	str.w r8, [sp, #0xc]
	bl set_nibble_fields_from_bit_mask
	movw r0, #0x1028
	strh.w r0, [sp, #0x11]
	mov.w r8, #0x80
	mov r0, r9
	mov r1, r6
	str.w r8, [sp, #0xc]
	bl set_nibble_fields_from_bit_mask
	ldr r0, [sp, #4]
	movs r4, #1
	mov r1, r6
	str r4, [sp, #0xc]
	bl set_nibble_fields_from_bit_mask
	movs r5, #0x20
	mov r0, r7
	mov r1, r6
	str r5, [sp, #0xc]
	bl set_nibble_fields_from_bit_mask
	movs r7, #4
	mov r0, r10
	mov r1, r6
	str r7, [sp, #0xc]
	bl set_nibble_fields_from_bit_mask
	movw r2, #0x1008
	movw r0, #0xfc0c
	movt r2, #0x4001
	movt r0, #0xffff
	str.w r8, [r9, #0x14]
	str r5, [r2, #0xc]
	str r4, [r2, r0]
	str.w r7, [r10, #0x14]
	ldr.w r0, [r10, #8]
	lsls r0, r0, #0x1c
	bmi.n .L080402e6
	ldrb.w r0, [sp, #0xb]
	subs r0, #1
	cmp r0, #7
	bhi.n .L080402e6
	tbb [pc, r0]
.L080402b4:
	.byte (.L080402bc - .L080402b4)/2
	.byte (.L080402c6 - .L080402b4)/2
	.byte (.L080402e6 - .L080402b4)/2
	.byte (.L080402d0 - .L080402b4)/2
	.byte (.L080402e6 - .L080402b4)/2
	.byte (.L080402e6 - .L080402b4)/2
	.byte (.L080402e6 - .L080402b4)/2
	.byte (.L080402da - .L080402b4)/2
.L080402bc:
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x80
	b.n .L080402e2
.L080402c6:
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x800
	b.n .L080402e2
.L080402d0:
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x100
	b.n .L080402e2
.L080402da:
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x200
.L080402e2:
	strh.w r0, [r11]
.L080402e6:
	ldr.w r0, [r9, #8]
	lsls r0, r0, #0x17
	bmi.n .L0804032e
	ldrb.w r0, [sp, #0xb]
	subs r0, #1
	cmp r0, #7
	bhi.n .L0804032e
	tbb [pc, r0]
.L080402fc:
	.byte (.L08040304 - .L080402fc)/2
	.byte (.L0804030e - .L080402fc)/2
	.byte (.L0804032e - .L080402fc)/2
	.byte (.L08040318 - .L080402fc)/2
	.byte (.L0804032e - .L080402fc)/2
	.byte (.L0804032e - .L080402fc)/2
	.byte (.L0804032e - .L080402fc)/2
	.byte (.L08040322 - .L080402fc)/2
.L08040304:
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x20
	b.n .L0804032a
.L0804030e:
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x10
	b.n .L0804032a
.L08040318:
	ldrh.w r0, [r11]
	orr.w r0, r0, #8
	b.n .L0804032a
.L08040322:
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x2000
.L0804032a:
	strh.w r0, [r11]
.L0804032e:
	ldr r0, [r2]
	lsls r0, r0, #0x15
	bmi.n .L08040374
	ldrb.w r0, [sp, #0xb]
	subs r0, #1
	cmp r0, #7
	bhi.n .L08040374
	tbb [pc, r0]
.L08040342:
	.byte (.L0804034a - .L08040342)/2
	.byte (.L08040354 - .L08040342)/2
	.byte (.L08040374 - .L08040342)/2
	.byte (.L0804035e - .L08040342)/2
	.byte (.L08040374 - .L08040342)/2
	.byte (.L08040374 - .L08040342)/2
	.byte (.L08040374 - .L08040342)/2
	.byte (.L08040368 - .L08040342)/2
.L0804034a:
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x1000
	b.n .L08040370
.L08040354:
	ldrh.w r0, [r11]
	orr.w r0, r0, #4
	b.n .L08040370
.L0804035e:
	ldrh.w r0, [r11]
	orr.w r0, r0, #0x4000
	b.n .L08040370
.L08040368:
	ldrh.w r0, [r11]
	orr.w r0, r0, #2
.L08040370:
	strh.w r0, [r11]
.L08040374:
	movw r0, #0x2d50
	movt r0, #0x2000
	ldrh r0, [r0]
	movw r3, #0x2d58
	movw r10, #:lower16:d_08046528
	mov.w r9, #0
	mov.w r12, #1
	movt r3, #0x2000
	movt r10, #:upper16:d_08046528
	mov.w lr, #2
	mov.w r8, #4
	movs r6, #0
	movs r2, #0
	b.n .L080403b0
.L080403a4:
	strb.w r9, [r4, #2]
.L080403a8:
	adds r6, #3
	cmp r6, #0xf
	beq.w .L080404e0
.L080403b0:
	ldrh.w r4, [r11]
	lsl.w r1, r12, r6
	ldrb r5, [r3, r6]
	tst r1, r4
	add.w r4, r3, r6
	beq.n .L080403fc
	cmp r5, #0xff
	beq.n .L080403cc
	ldrb r5, [r4]
	adds r5, #1
	strb r5, [r4]
.L080403cc:
	ldrb r5, [r4]
	cmp r5, #0x46
	bne.n .L080403de
	add.w r5, r10, r6
	ldrb r5, [r5, #0xf]
	adds r2, #1
	strb.w r5, [sp, #0xa]
.L080403de:
	tst r1, r0
	beq.n .L08040414
	ldrb r1, [r4]
	cmp r1, #0x48
	bne.n .L08040414
	ldrb.w r1, [r10, r6]
	adds r2, #1
	strb.w r1, [sp, #0xa]
	ldrb r1, [r4]
	subs r1, #1
	strb r1, [r4]
	b.n .L08040414
	.byte 0x00, 0xbf	@ padding, never reached
.L080403fc:
	cmp r5, #2
	bcc.n .L08040410
	ldrb r1, [r4]
	cmp r1, #0x45
	bhi.n .L08040410
	ldrb.w r1, [r10, r6]
	adds r2, #1
	strb.w r1, [sp, #0xa]
.L08040410:
	strb.w r9, [r4]
.L08040414:
	ldrh.w r7, [r11]
	lsl.w r1, lr, r6
	ldrb r5, [r4, #1]
	tst r1, r7
	beq.n .L0804045c
	cmp r5, #0xff
	beq.n .L0804042c
	ldrb r5, [r4, #1]
	adds r5, #1
	strb r5, [r4, #1]
.L0804042c:
	ldrb r5, [r4, #1]
	cmp r5, #0x46
	bne.n .L0804043e
	add.w r5, r10, r6
	ldrb r5, [r5, #0x10]
	adds r2, #1
	strb.w r5, [sp, #0xa]
.L0804043e:
	tst r1, r0
	beq.n .L08040476
	ldrb r1, [r4, #1]
	cmp r1, #0x48
	bne.n .L08040476
	add.w r1, r10, r6
	ldrb r1, [r1, #1]
	adds r2, #1
	strb.w r1, [sp, #0xa]
	ldrb r1, [r4, #1]
	subs r1, #1
	strb r1, [r4, #1]
	b.n .L08040476
.L0804045c:
	cmp r5, #2
	bcc.n .L08040472
	ldrb r1, [r4, #1]
	cmp r1, #0x45
	bhi.n .L08040472
	add.w r1, r10, r6
	ldrb r1, [r1, #1]
	adds r2, #1
	strb.w r1, [sp, #0xa]
.L08040472:
	strb.w r9, [r4, #1]
.L08040476:
	ldrh.w r7, [r11]
	lsl.w r1, r8, r6
	ldrb r5, [r4, #2]
	tst r1, r7
	beq.n .L080404c4
	cmp r5, #0xff
	beq.n .L0804048e
	ldrb r5, [r4, #2]
	adds r5, #1
	strb r5, [r4, #2]
.L0804048e:
	ldrb r5, [r4, #2]
	cmp r5, #0x46
	bne.n .L080404a0
	add.w r5, r10, r6
	ldrb r5, [r5, #0x11]
	adds r2, #1
	strb.w r5, [sp, #0xa]
.L080404a0:
	tst r1, r0
	beq.w .L080403a8
	ldrb r1, [r4, #2]
	cmp r1, #0x48
	bne.w .L080403a8
	add.w r1, r10, r6
	ldrb r1, [r1, #2]
	adds r2, #1
	strb.w r1, [sp, #0xa]
	ldrb r1, [r4, #2]
	subs r1, #1
	strb r1, [r4, #2]
	b.n .L080403a8
	.byte 0x00, 0xbf	@ padding, never reached
.L080404c4:
	cmp r5, #2
	bcc.w .L080403a4
	ldrb r1, [r4, #2]
	cmp r1, #0x45
	bhi.w .L080403a4
	add.w r1, r10, r6
	ldrb r1, [r1, #2]
	adds r2, #1
	strb.w r1, [sp, #0xa]
	b.n .L080403a4
.L080404e0:
	uxtb r0, r2
	movw r4, #0x1008
	cmp r0, #1
	movt r4, #0x4001
	bhi.n .L08040508
	ldrb.w r0, [sp, #0xa]
	cbz r0, .L08040508
	movw r0, #0x2d70
	movt r0, #0x2000
	ldr r0, [r0]
	add.w r1, sp, #0xa
	movs r2, #0
	bl queue_send_timeout
.L08040508:
	movw r0, #0x5434
	movt r0, #0x4001
	ldr r1, [r0]
	cmp r1, #0
	movw r1, #0x2d67
	movt r1, #0x2000
	beq.n .L0804052e
	ldrb r2, [r1]
	adds r2, #1
	strb r2, [r1]
	ldrb r2, [r1]
	cmp r2, #0xb
	bcc.n .L08040532
	movs r2, #0
	str r2, [r0]
.L0804052e:
	movs r0, #0
	strb r0, [r1]
.L08040532:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0x3d]
	adds r2, r1, #1
	uxtb r1, r2
	cmp r1, #0x63
	ldrb.w r1, [r0, #0xe10]
	it hi
	movhi r2, #0
	cmp r1, #2
	strb.w r2, [r0, #0x3d]
	bcc.n .L08040558
	cmp r1, #0xff
	bne.n .L08040560
.L08040558:
	movs r1, #0
	strb.w r1, [r0, #0xe24]
	b.n .L08040576
.L08040560:
	ldrb.w r1, [r0, #0xe24]
	adds r1, #1
	uxtb r2, r1
	cmp r2, #0x65
	strb.w r1, [r0, #0xe24]
	itt cs
	movcs r1, #0
	strbcs.w r1, [r0, #0xe10]
.L08040576:
	ldrb.w r1, [r0, #0x32]
	cmp r1, #0xff
	itt ne
	addne r1, #1
	strbne.w r1, [r0, #0x32]
	ldrh r1, [r0, #0x2a]
	cmp r1, #0
	itt ne
	subne r1, #1
	strhne r1, [r0, #0x2a]
	ldrh r1, [r0, #0x28]
	cmp r1, #0
	itt ne
	subne r1, #1
	strhne r1, [r0, #0x28]
	ldrb.w r1, [r0, #0x2c]
	cmp r1, #0
	itt ne
	subne r1, #1
	strbne.w r1, [r0, #0x2c]
	ldrb.w r1, [r0, #0xdbb]
	cmp r1, #0
	itt ne
	subne r1, #1
	strbne.w r1, [r0, #0xdbb]
	ldrb.w r1, [r0, #0xdba]
	cmp r1, #0
	itt ne
	subne r1, #1
	strbne.w r1, [r0, #0xdba]
	ldrb.w r2, [r0, #0x45]
	adds r1, r2, #1
	strb.w r1, [r0, #0x45]
	cbnz r2, .L080405e0
	movs r1, #0x24
	movt r1, #0x4000
	movs r2, #0
	str r2, [r1]
	str.w r2, [r1, #0xc00]
	ldrb.w r1, [r0, #0x45]
.L080405e0:
	uxtb r1, r1
	cmp r1, #0x33
	bne.n .L0804065c
	ldrb.w r1, [r0, #0x2e]
	cbz r1, .L08040656
	movs r2, #0x24
	movt r2, #0x4000
	vldr s0, [r2]
	add.w r2, r2, #0xc00
	vcvt.f32.u32 s0, s0
	vldr s2, [r2]
	vadd.f32 s0, s0, s0
	vcvt.s32.f32 s0, s0
	vstr s0, [r0, #0x50]
	vmov r2, s0
	vcvt.f32.u32 s0, s2
	vadd.f32 s0, s0, s0
	movw r1, #0xca00
	vcvt.s32.f32 s0, s0
	movt r1, #0x3b9a
	cmp r2, #0
	vmov r3, s0
	ite ne
	sdivne r2, r1, r2
	moveq r2, #0
	str r2, [r0, #0x54]
	vstr s0, [r0, #0x80]
	cmp r3, #0
	ite ne
	sdivne r1, r1, r3
	moveq r1, #0
	ldrb.w r3, [r0, #0x231]
	movs r2, #0
	str.w r1, [r0, #0x84]
	strb.w r3, [r0, #0x230]
	strb.w r2, [r0, #0x231]
.L08040656:
	movs r1, #0
	strb.w r1, [r0, #0x45]
.L0804065c:
	ldr r1, [r4]
	lsls r1, r1, #0x1f
	bne.n .L080406ba
	ldrb r1, [r0, #0x17]
	cmp r1, #2
	beq.n .L080406b4
	ldrb.w r1, [r0, #0x2d]
	cmp r1, #0x13
	bhi.n .L080406b4
	movw r3, #:lower16:d_0804d832+1
	ldrh.w r2, [r0, #0xdb8]
	movt r3, #:upper16:d_0804d832+1
	ldrb r1, [r3, r1]
	adds r2, #1
	uxth r3, r2
	adds r1, #0x32
	cmp r1, r3
	strh.w r2, [r0, #0xdb8]
	bne.n .L080406b4
	movw r5, #0x2d78
	movt r5, #0x2000
	movs r1, #1
	ldr r0, [r5]
	add r4, sp, #0xc
	strb.w r1, [sp, #0xc]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L080406b4:
	add sp, #0x14
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080406ba:
	movs r1, #0
	strh.w r1, [r0, #0xdb8]
	add sp, #0x14
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short 0x0000	@ padding, never reached

@ ----------------------------------------------------------------------------
@ fn_080406c8 - periodic call counter. No parameters.
@ Calls fn_08009c78(); copies byte 0x20001068 to 0x20001067 and 0x20000eaa to
@ 0x20000ea9, reads the halfword 0x20001064 (s) and clears 0x20001068 and
@ 0x20000eaa. If byte 0x2000105d == 0 it returns. Otherwise it stores s+1 to
@ 0x20001064 and by byte 0x2000105d: 3 -> if (ushort)(s+1) < 0xe11 it clears
@ 0x20000eaa and 0x20001068 again and returns; 2 -> if (ushort)(s+1) < 0x709 it
@ returns; 1 -> if (ushort)(s+1) < 0x385 it clears both again and returns; any
@ other value clears both and returns. When the threshold of the selected mode
@ is reached it calls the no-return function save_settings_to_flash(0x55).
@ Purpose: counts calls in 0x20001064 against the limits 0x385, 0x709, 0xe11 and
@ ends in save_settings_to_flash(0x55) when the limit selected by 0x2000105d is
@ reached; what the call means is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080406c8,"ax",%progbits
	.global fn_080406c8
	.thumb_func
	.type fn_080406c8, %function
fn_080406c8:
	push {r7, lr}
	bl fn_08009c78
	movw r1, #0xf8
	movt r1, #0x2000
	ldrb.w r3, [r1, #0xf70]
	ldrb.w r0, [r1, #0xf65]
	ldrb.w r2, [r1, #0xdb2]
	strb.w r3, [r1, #0xf6f]
	movs r3, #0
	strb.w r3, [r1, #0xf70]
	strb.w r2, [r1, #0xdb1]
	strb.w r3, [r1, #0xdb2]
	cbz r0, .L08040720
	ldrh.w r2, [r1, #0xf6c]
	cmp r0, #3
	add.w r2, r2, #1
	strh.w r2, [r1, #0xf6c]
	beq.n .L08040718
	cmp r0, #2
	beq.n .L08040722
	cmp r0, #1
	bne.n .L08040720
	uxth r0, r2
	cmp.w r0, #0x384
	bls.n .L08040720
	b.n .L0804072c
.L08040718:
	uxth r0, r2
	cmp.w r0, #0xe10
	bhi.n .L0804072c
.L08040720:
	pop {r7, pc}
.L08040722:
	uxth r0, r2
	cmp.w r0, #0x708
	it ls
	popls {r7, pc}
.L0804072c:
	movs r0, #0x55
	bl save_settings_to_flash
	.short 0x0000	@ padding, never reached

@ ----------------------------------------------------------------------------
@ fn_08040734 - programs one of four field groups in a register block.
@ Params: r0 = base address, r1 = pointer to settings bytes s[0..3]. Switch on
@ s[0]: 0, 2, 4, 6 are handled; 1, 3, 5 and every other value return without a
@ write. No return value.
@   Case 0: r0[0x20] bit1 = s[1] bit0, bit3 = s[1] bit1; r0[0x18] low 2 bits =
@     s[2]&3, bits 7..4 = low nibble of s[3], bits 3..2 cleared; then
@     r0[0x20] |= 1.
@   Case 2: r0[0x20] bit5 = s[1] bit0, bit7 = s[1] bit1; r0[0x18] bits 9..8 =
@     s[2]&3, bits 15..12 = s[3]&0xf, bits 11..10 cleared; r0[0x20] |= 0x10.
@   Case 4: r0[0x20] bit9 = s[1] bit0, bit11 = s[1] bit1; r0[0x1c] low 2 bits =
@     s[2]&3, bits 7..4 = low nibble of s[3], bits 3..2 cleared;
@     r0[0x20] |= 0x100.
@   Case 6: r0[0x20] bit13 = s[1] bit0; r0[0x1c] bits 9..8 = s[2]&3, bits
@     15..12 = s[3]&0xf, bits 11..10 cleared; r0[0x20] |= 0x1000.
@ Purpose: programs one of four field groups in the register block at r0 (words
@ 0x18, 0x1c, 0x20); the peripheral is not named from the code.
@ ----------------------------------------------------------------------------
	.global fn_08040734
	.thumb_func
	.type fn_08040734, %function
fn_08040734:
	push {r4, lr}
	ldrb r2, [r1]
	cmp r2, #6
	it hi
	pophi {r4, pc}
	tbb [pc, r2]
.L08040742:
	.byte (.L0804074a - .L08040742)/2
	.byte (.L08040872 - .L08040742)/2
	.byte (.L0804077a - .L08040742)/2
	.byte (.L08040872 - .L08040742)/2
	.byte (.L080407c8 - .L08040742)/2
	.byte (.L08040872 - .L08040742)/2
	.byte (.L0804081a - .L08040742)/2
	.byte 0x00	@ padding
.L0804074a:
	mov r2, r0
	ldrb.w r12, [r1, #1]
	ldr.w r3, [r2, #0x20]!
	movs r4, #1
	bfi r3, r12, #1, #1
	str r3, [r2]
	ldrb.w r12, [r1, #1]
	ldr.w lr, [r2]
	ubfx r3, r12, #1, #0x1d
	bfi lr, r3, #3, #1
	str.w lr, [r2]
	ldrb.w r12, [r1, #2]
	ldr.w r3, [r0, #0x18]!
	b.n .L08040800
.L0804077a:
	mov r2, r0
	ldrb.w r12, [r1, #1]
	ldr.w r3, [r2, #0x20]!
	movs r4, #0x10
	bfi r3, r12, #5, #1
	str r3, [r2]
	ldrb.w r12, [r1, #1]
	ldr.w lr, [r2]
	ubfx r3, r12, #1, #0x19
	bfi lr, r3, #7, #1
	str.w lr, [r2]
	ldrb.w r12, [r1, #2]
	ldr.w r3, [r0, #0x18]!
	and.w r12, r12, #3
	bic.w r3, r3, #0x300
	orr.w r3, r3, r12, lsl #8
	str r3, [r0]
	ldrb r1, [r1, #3]
	ldr r3, [r0]
	and.w r1, r1, #0xf
	lsl.w lr, r1, #0xc
	bic.w r12, r3, #0xf000
	b.n .L0804085c
.L080407c8:
	mov r2, r0
	ldrb.w r12, [r1, #1]
	ldr.w r3, [r2, #0x20]!
	and.w r12, r12, #1
	bic.w r3, r3, #0x200
	orr.w r3, r3, r12, lsl #9
	str r3, [r2]
	ldrb.w r12, [r1, #1]
	ldr.w lr, [r2]
	ubfx r3, r12, #1, #0x15
	bfi lr, r3, #0xb, #1
	str.w lr, [r2]
	ldrb.w r12, [r1, #2]
	ldr.w r3, [r0, #0x1c]!
	mov.w r4, #0x100
.L08040800:
	bfi r3, r12, #0, #2
	str r3, [r0]
	ldrb r1, [r1, #3]
	ldr r3, [r0]
	lsls r1, r1, #4
	uxtb.w r12, r1
	bic.w lr, r3, #0xf0
	mvn.w r3, #0xc
	b.n .L08040860
.L0804081a:
	mov r2, r0
	ldrb.w r12, [r1, #1]
	ldr.w r3, [r2, #0x20]!
	and.w r12, r12, #1
	bic.w r3, r3, #0x2000
	orr.w r3, r3, r12, lsl #0xd
	str r3, [r2]
	ldrb.w r12, [r1, #2]
	ldr.w r3, [r0, #0x1c]!
	and.w r12, r12, #3
	bic.w r3, r3, #0x300
	orr.w r3, r3, r12, lsl #8
	str r3, [r0]
	ldrb r1, [r1, #3]
	ldr r3, [r0]
	and.w r1, r1, #0xf
	lsl.w lr, r1, #0xc
	bic.w r12, r3, #0xf000
	mov.w r4, #0x1000
.L0804085c:
	mvn.w r3, #0xc00
.L08040860:
	orr.w r1, lr, r12
	str r1, [r0]
	ldr r1, [r0]
	ands r1, r3
	str r1, [r0]
	ldr r0, [r2]
	orrs r0, r4
	str r0, [r2]
.L08040872:
	pop {r4, pc}
