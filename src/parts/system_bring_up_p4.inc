@ system_bring_up_p4.inc - part 4 of 4 of system_bring_up (0x0802da54..0x0802e71c):
@ the tail of the start-up function: end of the task-name string setup (Timer1, Timer2,
@ display, key, osc, fpga, dvom_TX, dvom_RX), the register waits, queue sends, clock and
@ SysTick set-up, the mode dispatch, the 10.0 double constant and the debug strings.
@ Included by part 1; continues the instructions of part 3 (inside an IT block).

@ ---- continuation of the IT block begun at the end of part 3 ----
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802da62
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802da48
.L0802da62:
	ldr	r0, [r6, #4]
.L0802da64:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802da7e
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802da64
.L0802da7e:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802da84:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802da9e
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802da84
.L0802da9e:
	ldr	r0, [r6, #4]
	movs	r0, #0x40
	str.w	r0, [r4, lr]
	nop
.L0802daa8:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802dac2
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802daa8
.L0802dac2:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802dac8:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802dae2
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802dac8
.L0802dae2:
	ldr	r0, [r6, #4]
	movs	r0, #0x40
	str.w	r0, [r4, r12]
	nop
.L0802daec:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802db06
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802daec
.L0802db06:
	movs	r0, #0x3b
	str	r0, [r6, #4]
	nop
.L0802db0c:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802db26
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802db0c
.L0802db26:
	ldr	r0, [r6, #4]
	movw	r1, #:lower16:d_08051d19	@ own label of the FPGA configuration stream at 0x08051d19 (was d_08051d18+1)
	movw	r2, #0xc3b6
	movs	r0, #0
	movt	r1, #:upper16:d_08051d19	@ own label of the FPGA configuration stream at 0x08051d19 (was d_08051d18+1)
	movt	r2, #1
	b.n	.L0802db7c

@ ---- task-name strings read by code (each padded to 4 bytes) ----
.L0802db3c:
	.asciz	"Timer1"
	.byte	0x00			@ padding
.L0802db44:
	.asciz	"Timer2"
	.byte	0x00			@ padding
.L0802db4c:
	.asciz	"display"
.L0802db54:
	.asciz	"key"
.L0802db58:
	.asciz	"osc"
.L0802db5c:
	.asciz	"fpga"
	.byte	0x00, 0x00, 0x00	@ padding
.L0802db64:
	.asciz	"dvom_TX"
.L0802db6c:
	.asciz	"dvom_RX"

.L0802db74:
	adds	r0, #3
	ldr	r3, [r6, #4]
	cmp	r0, r2
	beq.n	.L0802dc32
.L0802db7c:
	ldrb	r3, [r1, r0]
	nop
.L0802db80:
	ldr	r7, [r6]
	lsls	r7, r7, #0x1e
	itttt	pl
	ldrpl	r7, [r6]
	lslspl.w	r7, r7, #0x1e
	ldrpl	r7, [r6]
	lslspl.w	r7, r7, #0x1e
	bmi.n	.L0802db9a
	ldr	r7, [r6]
	lsls	r7, r7, #0x1e
	bpl.n	.L0802db80
.L0802db9a:
	str	r3, [r6, #4]
.L0802db9c:
	ldr	r3, [r6]
	lsls	r3, r3, #0x1f
	itttt	eq
	ldreq	r3, [r6]
	lslseq.w	r3, r3, #0x1f
	ldreq	r3, [r6]
	lslseq.w	r3, r3, #0x1f
	bne.n	.L0802dbb6
	ldr	r3, [r6]
	lsls	r3, r3, #0x1f
	beq.n	.L0802db9c
.L0802dbb6:
	ldr	r3, [r6, #4]
	adds	r3, r0, r1
	ldrb	r7, [r3, #1]
.L0802dbbc:
	ldr	r5, [r6]
	lsls	r5, r5, #0x1e
	bmi.n	.L0802dbd8
	ldr	r5, [r6]
	lsls	r5, r5, #0x1e
	itt	pl
	ldrpl	r5, [r6]
	lslspl.w	r5, r5, #0x1e
	bmi.n	.L0802dbd8
	ldr	r5, [r6]
	lsls	r5, r5, #0x1e
	bpl.n	.L0802dbbc
	nop
.L0802dbd8:
	str	r7, [r6, #4]
.L0802dbda:
	ldr	r7, [r6]
	lsls	r7, r7, #0x1f
	bne.n	.L0802dbf4
	ldr	r7, [r6]
	lsls	r7, r7, #0x1f
	itt	eq
	ldreq	r7, [r6]
	lslseq.w	r7, r7, #0x1f
	bne.n	.L0802dbf4
	ldr	r7, [r6]
	lsls	r7, r7, #0x1f
	beq.n	.L0802dbda
.L0802dbf4:
	ldrb	r3, [r3, #2]
	ldr	r7, [r6, #4]
.L0802dbf8:
	ldr	r7, [r6]
	lsls	r7, r7, #0x1e
	bmi.n	.L0802dc14
	ldr	r7, [r6]
	lsls	r7, r7, #0x1e
	itt	pl
	ldrpl	r7, [r6]
	lslspl.w	r7, r7, #0x1e
	bmi.n	.L0802dc14
	ldr	r7, [r6]
	lsls	r7, r7, #0x1e
	bpl.n	.L0802dbf8
	nop
.L0802dc14:
	str	r3, [r6, #4]
.L0802dc16:
	ldr	r3, [r6]
	lsls	r3, r3, #0x1f
	bne.n	.L0802db74
	ldr	r3, [r6]
	lsls	r3, r3, #0x1f
	itt	eq
	ldreq	r3, [r6]
	lslseq.w	r3, r3, #0x1f
	bne.n	.L0802db74
	ldr	r3, [r6]
	lsls	r3, r3, #0x1f
	beq.n	.L0802dc16
	b.n	.L0802db74
.L0802dc32:
	movs	r0, #0x40
	str.w	r0, [r4, lr]
.L0802dc38:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802dc52
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802dc38
.L0802dc52:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802dc58:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802dc72
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802dc58
.L0802dc72:
	ldr	r0, [r6, #4]
	movs	r0, #0x40
	str.w	r0, [r4, r12]
	nop
.L0802dc7c:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802dc96
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802dc7c
.L0802dc96:
	movs	r0, #0x3a
	str	r0, [r6, #4]
	nop
.L0802dc9c:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802dcb6
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802dc9c
.L0802dcb6:
	ldr	r0, [r6, #4]
.L0802dcb8:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802dcd2
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802dcb8
.L0802dcd2:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802dcd8:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802dcf2
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802dcd8
.L0802dcf2:
	ldr	r0, [r6, #4]
	movs	r0, #0x40
	str.w	r0, [r4, lr]
	nop
.L0802dcfc:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802dd16
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802dcfc
.L0802dd16:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802dd1c:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802dd36
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802dd1c
.L0802dd36:
	ldr	r0, [r6, #4]
	movs	r0, #0x40
	str.w	r0, [r4, r12]
	nop
.L0802dd40:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802dd5a
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802dd40
.L0802dd5a:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802dd60:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802dd7a
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802dd60
.L0802dd7a:
	ldr	r0, [r6, #4]
	movs	r0, #0x40
	str.w	r0, [r4, lr]
	nop
.L0802dd84:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802dd9e
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802dd84
.L0802dd9e:
	movw	r8, #0x1014
	movs	r0, #0
	movt	r8, #0x4001
	str	r0, [r6, #4]
	nop
.L0802ddac:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802ddc6
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802ddac
.L0802ddc6:
	ldr	r0, [r6, #4]
	ldr.w	r0, [r9]
	add	r4, sp, #0x60
	movs	r5, #1
	mov	r1, r4
	mov.w	r2, #0xffffffff
	strb.w	r5, [sp, #0x60]
	bl	queue_send_timeout
	movs	r1, #2
	ldr.w	r0, [r9]
	strb.w	r1, [sp, #0x60]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #6
	ldr.w	r0, [r9]
	strb.w	r1, [sp, #0x60]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #7
	ldr.w	r0, [r9]
	strb.w	r1, [sp, #0x60]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #8
	ldr.w	r0, [r9]
	strb.w	r1, [sp, #0x60]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	ldr.w	r0, [r11]
	movw	r6, #0x1000
	orr	r0, r0, #0x10
	str.w	r0, [r11]
	ldr.w	r0, [r11]
	add	r4, sp, #0x40
	orr	r0, r0, #0x10
	str.w	r0, [r11]
	movs	r0, #0
	strb.w	r0, [sp, #0x44]
	movs	r0, #4
	movt	r6, #0x4001
	strh.w	r0, [sp, #0x45]
	mov	r0, r6
	mov	r1, r4
	strb.w	r5, [sp, #0x47]
	str	r5, [sp, #0x40]
	bl	set_nibble_fields_from_bit_mask
	movs	r5, #0x10
	mov	r0, r6
	mov	r1, r4
	strb.w	r5, [sp, #0x46]
	str	r5, [sp, #0x40]
	bl	set_nibble_fields_from_bit_mask
	ldrb.w	r0, [r10, #0x17]
	movw	r7, #0x414
	cmp	r0, #2
	ite	ne
	strne.w	r5, [r8]
	streq	r5, [r6, #0x10]
	movw	r6, #0xe409
	movw	r5, #0x400
	movs	r4, #0
	add	r0, sp, #0x40
	movt	r6, #0xe000
	movt	r7, #0x4000
	movt	r5, #0x4000
	str	r4, [sp, #0x50]
	strd	r4, r4, [sp, #0x48]
	strd	r4, r4, [sp, #0x40]
	bl	compute_clock_frequencies
	ldr.w	r0, [r11, #4]
	movw	r1, #0x1759
	orr	r0, r0, #2
	str.w	r0, [r11, #4]
	ldr	r0, [sp, #0x44]
	movt	r1, #0xd1b7
	umull	r0, r1, r0, r1
	mov.w	r0, #0xffffffff
	add.w	r1, r0, r1, lsr #13
	movs	r2, #0x13
	str	r2, [r7, #0x18]
	str	r1, [r7, #0x14]
	ldr	r1, [r7]
	movw	r3, #0xed0c
	orr	r1, r1, #1
	str	r1, [r7]
	ldr	r1, [r5]
	movt	r3, #0xe000
	bic	r1, r1, #0x70
	str	r1, [r5]
	ldr.w	r1, [r7, #-8]
	movw	r2, #0xf8ff
	orr	r1, r1, #1
	str.w	r1, [r7, #-8]
	ldr	r1, [r3]
	mov	r9, r3
	ands	r1, r2
	movw	r2, #0x300
	movt	r2, #0x5fa
	orrs	r1, r2
	str	r1, [r3]
	ldr	r1, [r3]
	ubfx	r1, r1, #8, #3
	eor	r2, r1, #7
	cmp	r2, #4
	it	cs
	movcs	r2, #4
	lsls	r0, r2
	movs	r2, #3
	bic.w	r0, r2, r0
	subs	r1, #3
	it	cc
	movcc	r1, r4
	lsls	r0, r1
	lsls	r0, r0, #4
	movw	r1, #0xe010
	strb	r0, [r6, #0x14]
	mov.w	r0, #0x20000000
	movt	r1, #0xe000
	str.w	r0, [r1, #0xf0]
	ldr	r0, [r5]
	bic	r0, r0, #1
	str	r0, [r5]
	ldrb.w	r0, [r10, #0xf64]
	cbz	r0, .L0802df80
	strb.w	r0, [r10, #0xf68]
	cmp	r0, #1
	beq.n	.L0802df8e
.L0802df5e:
	cmp	r0, #3
	beq.n	.L0802dffc
	cmp	r0, #2
	bne.n	.L0802e00a
	ldrb.w	r0, [r10, #0x354]
	lsls	r0, r0, #0x1c
	movw	r0, #0x2d50
	movt	r0, #0x2000
	ite	eq
	moveq	r1, #0
	movne.w	r1, #0x3c00
	strh	r1, [r0]
	b.n	.L0802e00a
.L0802df80:
	ldrb.w	r0, [r10, #0xf68]
	movs	r1, #1
	strb.w	r1, [r10, #0xf69]
	cmp	r0, #1
	bne.n	.L0802df5e
.L0802df8e:
	movw	r1, #0x440c
	movt	r1, #0x4000
	ldr	r0, [r1]
	orr	r0, r0, #0x2000
	str	r0, [r1]
	movw	r0, #0x2da0
	movt	r0, #0x2000
	ldr	r0, [r0]
	bl	fn_08041610
	movw	r0, #0x2da4
	movt	r0, #0x2000
	ldr	r0, [r0]
	bl	fn_08041610
	movw	r1, #0x1000
	mov.w	r0, #0x800
	movt	r1, #0x4001
	str	r0, [r1, #0x10]
	movs	r0, #0
	movt	r0, #0x7fc0
	movw	r1, #0x101
	str.w	r0, [r10, #0xf48]
	str.w	r0, [r10, #0xf4c]
	str.w	r0, [r10, #0xf50]
	movs	r0, #0
	strh.w	r1, [r10, #0xf35]
	movs	r1, #0xff
	strb.w	r0, [r10, #0xf5d]
	strb.w	r0, [r10, #0xf2d]
	strb.w	r0, [r10, #0xf2f]
	strb.w	r1, [r10, #0xf38]
	strh.w	r0, [r10, #0xf3c]
	b.n	.L0802e05e
.L0802dffc:
	ldrb.w	r0, [r10, #0xe59]
	cmp	r0, #6
	it	hi
	movhi	r0, #7
	strb.w	r0, [r10, #0xf6a]
.L0802e00a:
	movw	r1, #0x440c
	movt	r1, #0x4000
	ldr	r0, [r1]
	bic	r0, r0, #0x2000
	str	r0, [r1]
	movw	r0, #0x2da0
	movt	r0, #0x2000
	ldr	r0, [r0]
	bl	fn_0804178c
	movw	r0, #0x2da4
	movt	r0, #0x2000
	ldr	r0, [r0]
	bl	fn_0804178c
	mov.w	r0, #0x800
	str.w	r0, [r8]
	movw	r0, #0x2d7c
	movt	r0, #0x2000
	ldr	r0, [r0]
	movs	r1, #0
	bl	semaphore_take_timeout
	movw	r0, #0x2d74
	movt	r0, #0x2000
	ldr	r0, [r0]
	movs	r1, #0
	bl	queue_reset
.L0802e05e:
	ldrb.w	r0, [r10, #0x2d]
	movw	r4, #0xaaab
	movt	r4, #0xaaaa
	umull	r0, r1, r0, r4
	lsrs	r0, r1, #1
	bl	u32_to_double
	vmov	d1, r0, r1
	vldr	d0, .L0802e418
	bl	double_pow
	ldrb.w	r0, [r10, #0x2d]
	vmov.f32	s16, s0
	umull	r1, r2, r0, r4
	lsrs	r1, r2, #1
	add.w	r1, r1, r1, lsl #1
	subs	r0, r0, r1
	movw	r1, #:lower16:d_080465c8
	movt	r1, #:upper16:d_080465c8
	ldrb	r0, [r1, r0]
	vmov.f32	s17, s1
	bl	u32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d8
	bl	double_mul
	mov	r4, r0
	ldrsh.w	r0, [r10, #0x1a]
	mov	r6, r1
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r6
	bl	double_mul
	bl	double_to_i64
	strd	r0, r1, [r10, #0x20]
	bl	fn_0803b078
	bl	fn_08030a70
	movs	r0, #0
	movs	r1, #0
	movs	r4, #0
	bl	fn_0803b2f8
	ldrb.w	r0, [r10, #0x2d]
	cmp	r0, #0x14
	bcc.n	.L0802e14e
	movw	r0, #0x12d
	str.w	r0, [r10, #0xdb4]
	add	r0, sp, #0x40
	str	r4, [sp, #0x50]
	strd	r4, r4, [sp, #0x48]
	strd	r4, r4, [sp, #0x40]
	bl	compute_clock_frequencies
	ldrb.w	r0, [r10, #0x2d]
	subs	r0, #0x14
	uxtb	r1, r0
	cmp	r1, #8
	bhi.n	.L0802e140
	ldr	r1, [sp, #0x44]
	movw	r2, #0x1759
	movt	r2, #0xd1b7
	umull	r1, r2, r1, r2
	movw	r1, #:lower16:d_080465a4
	sxtb	r0, r0
	movt	r1, #:upper16:d_080465a4
	ldr.w	r0, [r1, r0, lsl #2]
	mov.w	r1, #0xffffffff
	add.w	r1, r1, r2, lsr #13
	str	r0, [r7, #0x18]
	str	r1, [r7, #0x14]
	ldr	r0, [r7]
	orr	r0, r0, #1
	str	r0, [r7]
.L0802e140:
	movs	r0, #0
	str	r0, [r7, #0x10]
	ldr	r0, [r5]
	orr	r0, r0, #1
	str	r0, [r5]
	b.n	.L0802e16c
.L0802e14e:
	ldr	r0, [r5]
	bic	r0, r0, #1
	str	r0, [r5]
	ldrb.w	r0, [r10, #0x17]
	cmp	r0, #1
	itee	ne
	movwne	r0, #0x12d
	moveq	r0, #0
	movteq	r0, #0x12d
	str.w	r0, [r10, #0xdb4]
.L0802e16c:
	movs	r0, #4
	str.w	r0, [r8, #0x3fc]
	ldrb.w	r4, [r10, #0x14]
	movw	r7, #0xc00
	movt	r7, #0x4000
	cmp	r4, #3
	bhi.n	.L0802e19c
	movs	r0, #0
	tbb	[pc, r4]
.L0802e188:
	.byte	(.L0802e1a4 - .L0802e188)/2
	.byte	(.L0802e18c - .L0802e188)/2
	.byte	(.L0802e1a2 - .L0802e188)/2
	.byte	(.L0802e1de - .L0802e188)/2
.L0802e18c:
	movs	r0, #1
	movw	r4, #0x5034
	strb.w	r0, [r10, #0x15]
	movt	r4, #0x4001
	b.n	.L0802e1c8
.L0802e19c:
	lsls	r0, r4, #0x1f
	beq.n	.L0802e1a8
	b.n	.L0802e1bc
.L0802e1a2:
	movs	r0, #0x12
.L0802e1a4:
	strb.w	r0, [r10, #0x15]
.L0802e1a8:
	ldrb.w	r1, [r10, #4]
	addw	r0, r10, #0x356
	eor	r2, r1, #0x80
	movw	r1, #0x12d
	bl	fill_bytes
.L0802e1bc:
	lsls	r0, r4, #0x1e
	movw	r4, #0x5034
	movt	r4, #0x4001
	bmi.n	.L0802e1ec
.L0802e1c8:
	ldrb.w	r1, [r10, #5]
	addw	r0, r10, #0x483
	eor	r2, r1, #0x80
	movw	r1, #0x12d
	bl	fill_bytes
	b.n	.L0802e1ec
.L0802e1de:
	movs	r0, #2
	movw	r4, #0x5034
	strb.w	r0, [r10, #0x15]
	movt	r4, #0x4001
.L0802e1ec:
	ldrb.w	r0, [r10, #0x23a]
	cmp	r0, #0
	it	ne
	blne	fn_08025fc0
	bl	send_state_message_sequence
	ldrb.w	r0, [r10, #0xf61]
	str	r0, [r4]
	ldrb.w	r0, [r10, #0x14]
	cmp	r0, #3
	beq.n	.L0802e224
	cmp	r0, #2
	beq.n	.L0802e232
	cmp	r0, #1
	bne.n	.L0802e23e
	movw	r1, #0x1000
	movs	r0, #4
	movt	r1, #0x4001
	str	r0, [r1, #0x10]
	movs	r0, #2
	str	r0, [r1, #0x10]
	b.n	.L0802e23e
.L0802e224:
	movw	r1, #0x1000
	movs	r0, #4
	movt	r1, #0x4001
	str	r0, [r1, #0x10]
	b.n	.L0802e238
.L0802e232:
	movs	r0, #4
	str.w	r0, [r8]
.L0802e238:
	movs	r0, #2
	str.w	r0, [r8]
.L0802e23e:
	ldrb.w	r0, [r10, #2]
	bl	fn_080088a4
	ldrb.w	r0, [r10, #3]
	bl	fn_08008a58
	ldrb.w	r0, [r10]
	cmp	r0, #0
	mov.w	r0, #0x1000
	ite	ne
	strne.w	r0, [r8, #0x3fc]
	streq.w	r0, [r8, #0x400]
	ldrb.w	r0, [r10, #1]
	cmp	r0, #0
	mov.w	r0, #0x2000
	ite	ne
	strne.w	r0, [r8, #0x3fc]
	streq.w	r0, [r8, #0x400]
	ldrb.w	r0, [r10, #0xf61]
	movw	r8, #0x1c00
	movt	r8, #0x4000
	str	r0, [r4]
	bl	fill_output_waveform_table
	bl	fn_08029d40
	movw	r0, #:lower16:t_080bc18b
	movt	r0, #:upper16:t_080bc18b
	bl	scan_capture_files
	strb.w	r0, [r10, #0xe1b]
	ldr.w	r0, [r11, #4]
	mov.w	r6, #0xffffffff
	orr	r0, r0, #8
	str.w	r0, [r11, #4]
	ldr	r0, [r7]
	movs	r4, #0
	orr	r0, r0, #0x400
	str	r0, [r7]
	str	r6, [r7, #0x2c]
	str	r4, [r7, #0x28]
	ldr	r0, [r7, #0x14]
	add	r1, sp, #0x40
	orr	r0, r0, #1
	str	r0, [r7, #0x14]
	ldr	r0, [r7]
	bic	r0, r0, #0x70
	str	r0, [r7]
	mov.w	r0, #0x10000
	str	r0, [sp, #0x40]
	mov	r0, r7
	bl	fn_08040734
	ldr	r0, [r7, #8]
	movs	r1, #5
	bfi	r0, r1, #4, #3
	str	r0, [r7, #8]
	ldr	r0, [r7, #8]
	movw	r1, #0xfc14
	orr	r0, r0, #7
	str	r0, [r7, #8]
	ldr	r0, [r7]
	movt	r1, #0xffff
	orr	r0, r0, #1
	str	r0, [r7]
	ldr.w	r0, [r11, #4]
	mov.w	r7, #0x40000000
	orr	r0, r0, #1
	str.w	r0, [r11, #4]
	ldr	r0, [r7]
	orr	r0, r0, #0x400
	str	r0, [r7]
	movw	r0, #0xfc2c
	movt	r0, #0xffff
	str	r6, [r5, r0]
	movw	r0, #0xfc28
	movt	r0, #0xffff
	str	r4, [r5, r0]
	ldr	r0, [r5, r1]
	orr	r0, r0, #1
	str	r0, [r5, r1]
	ldr	r0, [r7]
	add	r1, sp, #0x40
	bic	r0, r0, #0x70
	str	r0, [r7]
	movs	r0, #2
	movt	r0, #1
	str	r0, [sp, #0x40]
	mov.w	r0, #0x40000000
	bl	fn_08040734
	movw	r0, #0xfc08
	movt	r0, #0xffff
	ldr	r1, [r5, r0]
	movs	r2, #6
	bfi	r1, r2, #4, #3
	str	r1, [r5, r0]
	ldr	r1, [r5, r0]
	movw	r6, #0x1000
	orr	r1, r1, #7
	str	r1, [r5, r0]
	ldr	r0, [r7]
	movt	r6, #0x4001
	orr	r0, r0, #1
	str	r0, [r7]
	ldrb.w	r0, [r10, #0xf62]
	movw	r7, #0xe010
	cmp	r0, #0
	ittt	ne
	movwne	r1, #0x5404
	movtne	r1, #0x4001
	strne	r0, [r1, #0x30]
	movw	r0, #0x2b20
	movt	r0, #0x2000
	ldr	r0, [r0]
	movs	r1, #0x32
	muls	r0, r1, r0
	movt	r7, #0xe000
	str	r0, [r7, #4]
	str	r4, [r7, #8]
	ldr	r0, [r7]
	orr	r0, r0, #1
	str	r0, [r7]
	nop
.L0802e3a8:
	ldr	r0, [r7]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802e3d0
	ldr	r0, [r7]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802e3d0
	ldr	r0, [r7]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802e3d0
	ldr	r0, [r7]
	and	r0, r0, #0x10001
	cmp	r0, #1
	beq.n	.L0802e3a8
.L0802e3d0:
	ldr	r0, [r7]
	movw	r1, #0x5404
	bic	r0, r0, #1
	str	r0, [r7]
	movs	r0, #0
	movt	r1, #0x4001
	str	r0, [r7, #8]
	str	r0, [r1, #0x30]
	mov.w	r2, #0x1f4
	movs	r1, #0x32
	b.n	.L0802e3fe
	.byte	0x00, 0xbf		@ padding
.L0802e3f0:
	ldr	r3, [r7]
	bic	r3, r3, #1
	str	r3, [r7]
	lsls	r3, r2, #0x10
	str	r0, [r7, #8]
	beq.n	.L0802e46e
.L0802e3fe:
	uxth	r3, r2
	cmp	r3, #0x33
	bcc.n	.L0802e420
	movw	r3, #0x2b20
	movt	r3, #0x2000
	ldr	r3, [r3]
	subs	r2, #0x32
	muls	r3, r1, r3
	str	r3, [r7, #4]
	b.n	.L0802e430
	.byte	0x00, 0xbf		@ padding
.L0802e418:
	.word	0x00000000		@ double 10.0, low word
	.word	0x40240000		@ double 10.0, high word
.L0802e420:
	movw	r2, #0x2b20
	movt	r2, #0x2000
	ldr	r2, [r2]
	muls	r2, r3, r2
	str	r2, [r7, #4]
	movs	r2, #0
.L0802e430:
	str	r0, [r7, #8]
	ldr	r3, [r7]
	orr	r3, r3, #1
	str	r3, [r7]
	nop
.L0802e43c:
	ldr	r3, [r7]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802e3f0
	ldr	r3, [r7]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802e3f0
	ldr	r3, [r7]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802e3f0
	ldr	r3, [r7]
	and	r3, r3, #0x10001
	cmp	r3, #1
	beq.n	.L0802e43c
	b.n	.L0802e3f0
	.byte	0x00, 0xbf		@ padding
.L0802e468:
	ldr	r0, [r6, #8]
	lsls	r0, r0, #0x17
	bmi.n	.L0802e482
.L0802e46e:
	ldr	r0, [r6, #8]
	lsls	r0, r0, #0x17
	itttt	pl
	ldrpl	r0, [r6, #8]
	lslspl.w	r0, r0, #0x17
	ldrpl	r0, [r6, #8]
	lslspl.w	r0, r0, #0x17
	bpl.n	.L0802e468
.L0802e482:
	movw	r0, #0x2b20
	movt	r0, #0x2000
	ldr	r0, [r0]
	add.w	r0, r0, r0, lsl #2
	lsls	r0, r0, #1
	str	r0, [r7, #4]
	movs	r0, #0
	str	r0, [r7, #8]
	ldr	r0, [r7]
	orr	r0, r0, #1
	str	r0, [r7]
.L0802e4a0:
	ldr	r0, [r7]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802e4c8
	ldr	r0, [r7]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802e4c8
	ldr	r0, [r7]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802e4c8
	ldr	r0, [r7]
	and	r0, r0, #0x10001
	cmp	r0, #1
	beq.n	.L0802e4a0
.L0802e4c8:
	ldr	r0, [r7]
	bic	r0, r0, #1
	str	r0, [r7]
	movs	r0, #0
	str	r0, [r7, #8]
.L0802e4d4:
	ldr	r0, [r6, #8]
	lsls	r0, r0, #0x17
	bmi.n	.L0802e4ee
	ldr	r0, [r6, #8]
	lsls	r0, r0, #0x17
	itt	pl
	ldrpl	r0, [r6, #8]
	lslspl.w	r0, r0, #0x17
	bmi.n	.L0802e4ee
	ldr	r0, [r6, #8]
	lsls	r0, r0, #0x17
	bpl.n	.L0802e4d4
.L0802e4ee:
	bl	fn_08009c78
	ldr.w	r0, [r11]
	add	r1, sp, #0x60
	orr	r0, r0, #0x4000
	str.w	r0, [r11]
	ldr.w	r0, [r11]
	orr	r0, r0, #4
	str.w	r0, [r11]
	movw	r0, #0x400
	movt	r0, #0x108
	str	r0, [sp, #0x64]
	mov.w	r0, #0x200
	str	r0, [sp, #0x60]
	movw	r0, #0x800
	movt	r0, #0x4001
	bl	set_nibble_fields_from_bit_mask
	add	r0, sp, #0x40
	bl	compute_clock_frequencies
	ldr	r0, [sp, #0x48]
	movw	r1, #0xb3c5
	add.w	r0, r0, r0, lsl #2
	lsls	r0, r0, #1
	movt	r1, #0x91a2
	umull	r0, r1, r0, r1
	lsrs	r0, r1, #0x13
	movw	r1, #0xcccd
	movt	r1, #0xcccc
	umull	r1, r2, r0, r1
	lsrs	r1, r2, #3
	add.w	r3, r1, r1, lsl #2
	sub.w	r0, r0, r3, lsl #1
	cmp	r0, #4
	movw	r0, #0x380c
	movt	r0, #0x4001
	ldr.w	r7, [r0, #-4]
	mov.w	r3, #1
	it	hi
	addhi.w	r1, r3, r2, lsr #3
	pkhbt	r1, r1, r7
	str.w	r1, [r0, #-4]
	ldr	r1, [r0]
	movs	r2, #0xef
	bic	r1, r1, #0x1000
	str	r1, [r0]
	ldr	r1, [r0, #4]
	bic	r1, r1, #0x3000
	str	r1, [r0, #4]
	ldr	r1, [r0]
	orr	r1, r1, #8
	str	r1, [r0]
	ldr	r1, [r0]
	orr	r1, r1, #0x2000
	str	r1, [r0]
	adr	r0, .L0802e6d0
	adr	r1, .L0802e700
	bl	fn_0800739c
	movw	r1, #0x3000
	movw	r0, #0x5555
	movt	r1, #0x4000
	str	r0, [r1]
	ldr	r0, [r1, #4]
	movs	r4, #4
	bfi	r0, r4, #0, #3
	str	r0, [r1, #4]
	movw	r0, #0x4e1
	str	r0, [r1, #8]
	movw	r0, #0xaaaa
	str	r0, [r1]
	movw	r0, #0xcccc
	str	r0, [r1]
	ldr.w	r0, [r11, #4]
	movs	r5, #0
	orr	r0, r0, #0x40
	str.w	r0, [r11, #4]
	add	r0, sp, #0x40
	str	r5, [sp, #0x50]
	strd	r5, r5, [sp, #0x48]
	strd	r5, r5, [sp, #0x40]
	bl	compute_clock_frequencies
	ldr	r0, [sp, #0x44]
	movw	r1, #0x1759
	movt	r1, #0xd1b7
	movw	r3, #0xfc2c
	umull	r0, r1, r0, r1
	movw	r2, #0x270f
	movt	r3, #0xffff
	mov.w	r0, #0xffffffff
	str.w	r2, [r8, r3]
	movw	r2, #0xfc28
	add.w	r1, r0, r1, lsr #13
	movt	r2, #0xffff
	movw	r3, #0x1800
	str.w	r1, [r8, r2]
	movt	r3, #0x4000
	ldr	r1, [r3, #0x14]
	orr	r1, r1, #1
	str	r1, [r3, #0x14]
	ldr	r1, [r3]
	bic	r1, r1, #0x70
	str	r1, [r3]
	ldr	r1, [r3]
	bic	r1, r1, #0x300
	str	r1, [r3]
	ldr	r1, [r3, #0xc]
	orr	r1, r1, #1
	str	r1, [r3, #0xc]
	ldr.w	r1, [r9]
	ubfx	r1, r1, #8, #3
	eor	r2, r1, #7
	cmp	r2, #4
	it	cc
	movcc	r4, r2
	lsls	r0, r4
	movs	r2, #3
	subs	r1, #3
	bic.w	r0, r2, r0
	it	cc
	movcc	r1, r5
	lsls	r0, r1
	movw	r1, #0xe409
	lsls	r0, r0, #4
	movt	r1, #0xe000
	strb.w	r0, [r1, #0x22]
	movw	r1, #0xe010
	mov.w	r0, #0x800
	movt	r1, #0xe000
	str.w	r0, [r1, #0xf4]
	ldr	r0, [r3]
	orr	r0, r0, #1
	str	r0, [r3]
	movw	r0, #0x2d88
	movt	r0, #0x2000
	ldr	r4, [r0]
	bl	get_word_200062d4
	mov	r2, r0
	mov	r0, r4
	movs	r1, #1
	bl	fn_08042e38
	movw	r0, #0x2d8c
	movt	r0, #0x2000
	ldr	r4, [r0]
	bl	get_word_200062d4
	mov	r2, r0
	mov	r0, r4
	movs	r1, #1
	bl	fn_08042e38
	add	sp, #0x68
	vpop	{d8}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	b.w	create_idle_and_tmr_svc_tasks
	.byte	0x00, 0xbf		@ padding
	.p2align 2			@ adr targets are word aligned
.L0802e6d0:					@ start-up debug line (own English text; V1.2.0 printed a Chinese word)
	.asciz	"\033[1;32m[DEBUG] file[%s] line[%d] start\r\n\033[0m\n"
	.p2align 2
.L0802e700:					@ source tag printed by that line (own; V1.2.0: the vendor's build path)
	.asciz	"system_bring_up"
	.p2align 2
