@ ui_keys_67.s - key handlers working on the state byte at 0x20001060 (fn_0800cfcc..fn_0800d954)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0800cfcc - key handler, dispatch on the low byte of the word at 0x20001060.
@ No parameters. Purpose not determined from the code.
@ state 9: returns when [0x2000044d]==0; when [0x20001062]==3 clears [0x2000044d],
@   sets [0x20001060]=2 and calls send_state_message_sequence (08012908); else
@   stores the word keeping the state byte with [0x20001061]=1,[0x20001062]=3 and
@   sends 0x13, 0x14 to queue [0x20002d6c].
@ state 2: stores the word 0x00030109 ([0x20001060]=9,[0x20001061]=1,
@   [0x20001062]=3), sets [0x2000044d]=1 and calls 08012908.
@ state 1: when [0x20001025]==3 and the high nibble of [0x20001055] is not 0xb:
@   [0x20001055]==0x11 becomes 0x22, any other value is left unchanged and the
@   function returns; when [0x20001025]!=3 and the high nibble is not 0xb: clears
@   [0x20001055] and returns; when the high nibble is 0xb: increments [0x20001055]
@   and for its low nibble 1..5 (other nibbles change nothing) sets
@   [0x20001025]=1,3,5,6,7 and [0x20001026]=1,5,7,8,10, sends halfword 0x501 to
@   queue [0x20002d74] and 0x1d, 0x1b to queue [0x20002d6c].
@ other states return.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800cfcc,"ax",%progbits
	.p2align 2
	.global fn_0800cfcc
	.thumb_func
	.type fn_0800cfcc, %function
fn_0800cfcc:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000		@ r0 = 0x200000f8 (base of the field block)
	ldrb.w r1, [r0, #0xf68]		@ state byte [0x20001060]
	cmp r1, #9
	beq.n .L0800d006
	cmp r1, #2
	beq.n .L0800d034
	cmp r1, #1
	bne.n .L0800d0b0
	ldrb.w r2, [r0, #0xf2d]		@ [0x20001025]
	ldrb.w r1, [r0, #0xf5d]		@ [0x20001055]
	cmp r2, #3
	and.w r2, r1, #0xf0
	bne.n .L0800d04e
	cmp r2, #0xb0
	beq.n .L0800d04e
	cmp r1, #0x11
	bne.n .L0800d0b0
	movs r1, #0x22
	strb.w r1, [r0, #0xf5d]
	pop {r4, r5, r7, pc}
.L0800d006:
	ldrb.w r1, [r0, #0x355]		@ [0x2000044d]
	cmp r1, #0
	it eq
	popeq {r4, r5, r7, pc}
	ldrb.w r1, [r0, #0xf6a]		@ [0x20001062]
	cmp r1, #3
	bne.n .L0800d076
	movs r1, #0
	movs r2, #2
	strb.w r1, [r0, #0x355]
	strb.w r2, [r0, #0xf68]
	strh.w r1, [r0, #0xf69]
	strb.w r1, [r0, #0xf6b]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d034:
	movw r1, #0x109
	movt r1, #0x3			@ word 0x00030109
	str.w r1, [r0, #0xf68]
	movs r1, #1
	strb.w r1, [r0, #0x355]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d04e:
	cmp r2, #0xb0
	bne.n .L0800d0aa
	adds r1, #1
	and.w r2, r1, #0xf
	subs r3, r2, #1
	cmp r3, #4
	strb.w r1, [r0, #0xf5d]
	bhi.n .L0800d0ca
	movs r2, #1
	movs r1, #1
	tbb [pc, r3]
.L0800d06a:
	.byte (.L0800d0c2 - .L0800d06a)/2
	.byte (.L0800d070 - .L0800d06a)/2
	.byte (.L0800d0b2 - .L0800d06a)/2
	.byte (.L0800d0b8 - .L0800d06a)/2
	.byte (.L0800d0be - .L0800d06a)/2
	.byte 0x00			@ padding
.L0800d070:
	movs r1, #5
	movs r2, #3
	b.n .L0800d0c2
.L0800d076:
	movw r1, #0x301
	movw r5, #0x2d6c
	strh.w r1, [r0, #0xf69]
	movs r1, #0
	movw r4, #0x2d53
	movt r5, #0x2000
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
	b.n .L0800d10e
.L0800d0aa:
	movs r1, #0
	strb.w r1, [r0, #0xf5d]
.L0800d0b0:
	pop {r4, r5, r7, pc}
.L0800d0b2:
	movs r1, #7
	movs r2, #5
	b.n .L0800d0c2
.L0800d0b8:
	movs r1, #8
	movs r2, #6
	b.n .L0800d0c2
.L0800d0be:
	movs r1, #0xa
	movs r2, #7
.L0800d0c2:
	strb.w r2, [r0, #0xf2d]
	strb.w r1, [r0, #0xf2e]
.L0800d0ca:
	movw r0, #0x2d74
	movw r1, #0x2d54
	movt r0, #0x2000
	movt r1, #0x2000
	movw r2, #0x501
	ldr r0, [r0]
	strh r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movw r5, #0x2d6c
	movw r4, #0x2d53
	movt r5, #0x2000
	movt r4, #0x2000
	movs r1, #0x1d
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x1b
.L0800d10e:
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
	.short 0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0800d120 - key handler, dispatch on the state byte at 0x20001060.
@ No parameters. Purpose not determined from the code.
@ state 5: when [0x20000f14]==0 and [0x20000f13]!=0: if [0x20000f12]==0 sets it to
@   1, clears the words [0x20000f0a] and [0x20000f0e] and sets bit
@   ([0x20000f15]%6) of byte [0x20000f0a+[0x20000f15]/6], else clears
@   [0x20000f12]; sends 0x28 and 0x26 to queue [0x20002d6c].
@ state 2: when the low byte of [0x2000010c]==3 or [0x2000044c]&0xf>2 toggles bit7
@   of [0x2000044c] and sends 2.
@ state 1: returns when the high nibble of [0x20001055] is 0xb; clears
@   [0x20001055]; when [0x20001025]<8 and its bit is in mask 0xc6 (indices 1,2,6,7):
@   toggles [0x2000102e] between 1 and 2, sets [0x20002d54] to 0xc/0xd (index 1),
@   0xe/0x17 (2), 0x11/0x16 (6), 0x10/0x15 (7), sets [0x20001040..48]=0x7fc00000,
@   calls fn_080098e0, sends [0x20002d54]|0x500 to queue [0x20002d74] and 0x1b to
@   queue [0x20002d6c]; when [0x20001025]==5 toggles [0x20001031] and sets
@   [0x20001040..48]=0x7fc00000.
@ other states return.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800d120,"ax",%progbits
	.p2align 2
	.global fn_0800d120
	.thumb_func
	.type fn_0800d120, %function
fn_0800d120:
	push {r4, r5, r6, lr}
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #5
	beq.n .L0800d19e
	cmp r0, #2
	beq.n .L0800d1bc
	cmp r0, #1
	bne.n .L0800d1ce
	ldrb.w r0, [r5, #0xf5d]
	and.w r0, r0, #0xf0
	cmp r0, #0xb0
	beq.n .L0800d1ce
	ldrb.w r0, [r5, #0xf2d]
	movs r6, #0
	movs r1, #0
	cmp r0, #7
	movt r6, #0x7fc0		@ r6 = 0x7fc00000
	strb.w r1, [r5, #0xf5d]
	bhi.w .L0800d2d6
	movs r2, #1
	lsl.w r1, r2, r0
	tst.w r1, #0xc6
	beq.w .L0800d2d6
	ldrb.w r1, [r5, #0xf36]
	subs r0, #1
	cmp r1, #1
	movw r4, #0x2d54
	it eq
	moveq r2, #2
	cmp r0, #6
	movt r4, #0x2000
	strb.w r2, [r5, #0xf36]
	bhi.w .L0800d288
	tbb [pc, r0]
.L0800d18c:
	.byte (.L0800d194 - .L0800d18c)/2
	.byte (.L0800d26a - .L0800d18c)/2
	.byte (.L0800d288 - .L0800d18c)/2
	.byte (.L0800d288 - .L0800d18c)/2
	.byte (.L0800d288 - .L0800d18c)/2
	.byte (.L0800d274 - .L0800d18c)/2
	.byte (.L0800d27e - .L0800d18c)/2
	.byte 0x00			@ padding
.L0800d194:
	movs r0, #0xc
	cmp r1, #1
	it eq
	moveq r0, #0xd
	b.n .L0800d286
.L0800d19e:
	ldrb.w r0, [r5, #0xe1c]
	cbnz r0, .L0800d1ce
	ldrb.w r0, [r5, #0xe1b]
	cmp r0, #0
	it eq
	popeq {r4, r5, r6, pc}
	ldrb.w r0, [r5, #0xe1a]
	cbz r0, .L0800d1fa
	movs r0, #0
	strb.w r0, [r5, #0xe1a]
	b.n .L0800d236
.L0800d1bc:
	ldrb r1, [r5, #0x14]
	ldrb.w r0, [r5, #0x354]
	cmp r1, #3
	beq.n .L0800d1d0
	and.w r1, r0, #0xf
	cmp r1, #3
	bcs.n .L0800d1d0
.L0800d1ce:
	pop {r4, r5, r6, pc}
.L0800d1d0:
	eor.w r0, r0, #0x80
	strb.w r0, [r5, #0x354]
	movw r0, #0x2d6c
	movw r1, #0x2d53
	movt r0, #0x2000
	movt r1, #0x2000
	ldr r0, [r0]
	movs r3, #2
	mov.w r2, #0xffffffff
	strb r3, [r1]
	pop.w {r4, r5, r6, lr}
	b.w queue_send_timeout
.L0800d1fa:
	ldrb.w r0, [r5, #0xe1d]
	movw r2, #0xaaab
	uxtb r1, r0
	movt r2, #0xaaaa
	umull r1, r2, r1, r2
	lsrs r2, r2, #2			@ r2 = [0x20000f15] / 6
	movs r1, #1
	movs r3, #0
	sub.w r6, r2, r2, lsl #2
	strb.w r1, [r5, #0xe1a]
	str.w r3, [r5, #0xe16]
	str.w r3, [r5, #0xe12]
	addw r3, r5, #0xe12
	add.w r0, r0, r6, lsl #1	@ r0 = [0x20000f15] % 6
	uxtb r0, r0
	ldrb r6, [r3, r2]
	lsl.w r0, r1, r0
	orrs r0, r6
	strb r0, [r3, r2]
.L0800d236:
	movw r5, #0x2d6c
	movw r4, #0x2d53
	movt r5, #0x2000
	movt r4, #0x2000
	movs r1, #0x28
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x26
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	pop.w {r4, r5, r6, lr}
	b.w queue_send_timeout
.L0800d26a:
	movs r0, #0xe
	cmp r1, #1
	it eq
	moveq r0, #0x17
	b.n .L0800d286
.L0800d274:
	movs r0, #0x11
	cmp r1, #1
	it eq
	moveq r0, #0x16
	b.n .L0800d286
.L0800d27e:
	movs r0, #0x10
	cmp r1, #1
	it eq
	moveq r0, #0x15
.L0800d286:
	strh r0, [r4]
.L0800d288:
	str.w r6, [r5, #0xf48]
	str.w r6, [r5, #0xf4c]
	str.w r6, [r5, #0xf50]
	bl fn_080098e0
	ldrh r0, [r4]
	mov.w r2, #0xffffffff
	orr.w r1, r0, #0x500
	movw r0, #0x2d74
	movt r0, #0x2000
	ldr r0, [r0]
	strh r1, [r4]
	mov r1, r4
	bl queue_send_timeout
	movw r0, #0x2d6c
	movw r1, #0x2d53
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #0x1b
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldrb.w r0, [r5, #0xf2d]
.L0800d2d6:
	cmp r0, #5
	bne.w .L0800d1ce
	ldrb.w r0, [r5, #0xf39]
	str.w r6, [r5, #0xf48]
	clz r0, r0
	lsrs r0, r0, #5
	strb.w r0, [r5, #0xf39]
	str.w r6, [r5, #0xf4c]
	str.w r6, [r5, #0xf50]
	pop {r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_0800d2f8 - key handler, dispatch on the state byte at 0x20001060.
@ No parameters. Purpose not determined from the code.
@ state 5: when [0x20000f14]==0 and [0x20000f13]!=0: sets [0x20000f12] to 1 when it
@   was 2 else 2, sets the words [0x20000f0a] and [0x20000f0e] to 0 (when it was 2)
@   or 0x3f3f3f3f, sends 0x26 and 0x28 to queue [0x20002d6c].
@ state 2: increments [0x2000044c]; wraps the low nibble to 0 when it is 3 and
@   ([0x20000332]==0 or [0x2000012c]==1), and when bits 2..3 are set; sets
@   [0x20002d50]=0x3c00 when the low nibble is nonzero else 0; for low nibble <3 and
@   low byte of [0x2000010c]!=3 sets bit7 of [0x2000044c] when the low byte of
@   [0x2000010c] !=1 and clears it when it ==1; sends 2.
@ state 1: clears [0x20001055] unless its high nibble is 0xb.
@ other states return.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800d2f8,"ax",%progbits
	.p2align 2
	.global fn_0800d2f8
	.thumb_func
	.type fn_0800d2f8, %function
fn_0800d2f8:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #5
	beq.n .L0800d326
	cmp r1, #2
	beq.n .L0800d38c
	cmp r1, #1
	bne.n .L0800d38a
	ldrb.w r1, [r0, #0xf5d]
	and.w r1, r1, #0xf0
	cmp r1, #0xb0
	beq.n .L0800d38a
	movs r1, #0
	strb.w r1, [r0, #0xf5d]
	pop {r4, r5, r7, pc}
.L0800d326:
	ldrb.w r1, [r0, #0xe1c]
	cmp r1, #0
	it ne
	popne {r4, r5, r7, pc}
	ldrb.w r1, [r0, #0xe1b]
	cbz r1, .L0800d38a
	ldrb.w r1, [r0, #0xe1a]
	movs r2, #2
	cmp r1, #2
	it eq
	moveq r2, #1
	subs r1, #2
	movw r5, #0x2d6c
	it ne
	movne.w r1, #0x3f3f3f3f
	movw r4, #0x2d53
	movt r5, #0x2000
	strb.w r2, [r0, #0xe1a]
	str.w r1, [r0, #0xe16]
	str.w r1, [r0, #0xe12]
	movt r4, #0x2000
	movs r1, #0x26
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x28
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
.L0800d38a:
	pop {r4, r5, r7, pc}
.L0800d38c:
	ldrb.w r1, [r0, #0x354]
	adds r1, #1
	and.w r2, r1, #0xf
	cmp r2, #3
	strb.w r1, [r0, #0x354]
	bne.n .L0800d3b4
	ldrb.w r2, [r0, #0x23a]
	cbz r2, .L0800d3ac
	ldrb.w r2, [r0, #0x34]
	cmp r2, #1
	bne.n .L0800d3b4
.L0800d3ac:
	and.w r1, r1, #0xf0
	strb.w r1, [r0, #0x354]
.L0800d3b4:
	tst.w r1, #0xc
	itt ne
	andne.w r1, r1, #0xf0
	strbne.w r1, [r0, #0x354]
	ands.w r2, r1, #0xf
	mov r3, r2
	movw r4, #0x2d50
	it ne
	movne.w r3, #0x3c00
	movt r4, #0x2000
	cmp r2, #2
	strh r3, [r4]
	bhi.n .L0800d3f4
	ldrb r2, [r0, #0x14]
	cmp r2, #3
	beq.n .L0800d3f4
	subs r2, #1
	and.w r1, r1, #0x7f
	it ne
	movne r2, #1
	orr.w r1, r1, r2, lsl #7
	strb.w r1, [r0, #0x354]
.L0800d3f4:
	movw r0, #0x2d6c
	movw r1, #0x2d53
	movt r0, #0x2000
	movt r1, #0x2000
	ldr r0, [r0]
	movs r3, #2
	mov.w r2, #0xffffffff
	strb r3, [r1]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
	.short 0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0800d418 - key handler, dispatch on the state byte at 0x20001060.
@ No parameters. Purpose not determined from the code.
@ state 1: clears [0x20001055] unless its high nibble is 0xb.
@ state 2: stores the word 0x00050109 ([0x20001060]=9,[0x20001061]=1,
@   [0x20001062]=5), sets [0x2000044d]=1, calls send_state_message_sequence (08012908).
@ state 5: when [0x20000f14]==0 and [0x20000f12]!=0 and any of the bytes
@   [0x20000f0a..0x20000f11] is nonzero sets [0x20000f14]=2 and sends 0x2a to
@   queue [0x20002d6c].
@ state 6: when [0x20000f14]==0 does the same.
@ state 9: returns when [0x2000044d]==0; when [0x20001062]==5 clears [0x2000044d],
@   sets [0x20001060]=2, calls 08012908; else stores [0x20001061]=1,
@   [0x20001062]=5 keeping the state byte and sends 0x13, 0x14.
@ other states return.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800d418,"ax",%progbits
	.p2align 2
	.global fn_0800d418
	.thumb_func
	.type fn_0800d418, %function
fn_0800d418:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	subs r1, #1
	cmp r1, #8
	bhi.n .L0800d4d4
	tbb [pc, r1]
.L0800d430:
	.byte (.L0800d43a - .L0800d430)/2
	.byte (.L0800d44e - .L0800d430)/2
	.byte (.L0800d4d4 - .L0800d430)/2
	.byte (.L0800d4d4 - .L0800d430)/2
	.byte (.L0800d468 - .L0800d430)/2
	.byte (.L0800d4cc - .L0800d430)/2
	.byte (.L0800d4d4 - .L0800d430)/2
	.byte (.L0800d4d4 - .L0800d430)/2
	.byte (.L0800d4d6 - .L0800d430)/2
	.byte 0x00			@ padding
.L0800d43a:
	ldrb.w r1, [r0, #0xf5d]
	and.w r1, r1, #0xf0
	cmp r1, #0xb0
	beq.n .L0800d4d4
	movs r1, #0
	strb.w r1, [r0, #0xf5d]
	pop {r4, r5, r7, pc}
.L0800d44e:
	movw r1, #0x109
	movt r1, #0x5			@ word 0x00050109
	str.w r1, [r0, #0xf68]
	movs r1, #1
	strb.w r1, [r0, #0x355]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d468:
	ldrb.w r1, [r0, #0xe1c]
	cbnz r1, .L0800d4d4
	ldrb.w r1, [r0, #0xe1a]
	cbz r1, .L0800d4d4
	ldrb.w r1, [r0, #0xe12]
	ldrb.w r2, [r0, #0xe13]
	ldrb.w r3, [r0, #0xe14]
	ldrb.w r4, [r0, #0xe15]
	orrs r1, r2
	orrs r1, r3
	ldrb.w r2, [r0, #0xe16]
	orrs r1, r4
	ldrb.w r3, [r0, #0xe17]
	orrs r1, r2
	ldrb.w r2, [r0, #0xe18]
	orrs r1, r3
	ldrb.w r3, [r0, #0xe19]
	orrs r1, r2
	orrs r1, r3
	beq.n .L0800d4d4
.L0800d4a4:
	movs r1, #2
	strb.w r1, [r0, #0xe1c]
	movw r0, #0x2d6c
	movw r1, #0x2d53
	movt r0, #0x2000
	movt r1, #0x2000
	ldr r0, [r0]
	movs r3, #0x2a
	mov.w r2, #0xffffffff
	strb r3, [r1]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
.L0800d4cc:
	ldrb.w r1, [r0, #0xe1c]
	cmp r1, #0
	beq.n .L0800d4a4
.L0800d4d4:
	pop {r4, r5, r7, pc}
.L0800d4d6:
	ldrb.w r1, [r0, #0x355]
	cmp r1, #0
	it eq
	popeq {r4, r5, r7, pc}
	ldrb.w r1, [r0, #0xf6a]
	cmp r1, #5
	bne.n .L0800d504
	movs r1, #0
	movs r2, #2
	strb.w r1, [r0, #0x355]
	strb.w r2, [r0, #0xf68]
	strh.w r1, [r0, #0xf69]
	strb.w r1, [r0, #0xf6b]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d504:
	movw r1, #0x501
	movw r5, #0x2d6c
	strh.w r1, [r0, #0xf69]
	movs r1, #0
	movw r4, #0x2d53
	movt r5, #0x2000
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
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
	.short 0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0800d548 - key handler, dispatch on the low byte of the word at 0x20001060.
@ No parameters. Purpose not determined from the code.
@ state 2: stores the word 0x00020109 ([0x20001060]=9,[0x20001061]=1,
@   [0x20001062]=2), sets [0x2000044d]=1, calls send_state_message_sequence.
@ state 5: sets [0x20001060]=2 keeping bytes 1..3, clears the halfword
@   [0x20000f14], the words [0x20000f0a],[0x20000f0e] and the byte [0x20000f12],
@   calls 08012908.
@ state 6: sets [0x20001060]=5 keeping bytes 1..3, calls 08012908.
@ state 9: returns when [0x2000044d]==0; when [0x20001062]==2 clears it, sets
@   [0x20001060]=2, calls 08012908; else stores [0x20001061]=1,[0x20001062]=2
@   keeping the state byte and sends 0x13, 0x14 to queue [0x20002d6c].
@ state 1: returns when the high nibble of [0x20001055] is 0xb; clears
@   [0x20001055]; when [0x20001025]<8 and its bit is in mask 0xda (indices
@   1,3,4,6,7): when [0x20001035]!=0 clears it; when it is 0 and [0x2000102d]==0
@   sets it to 1 and copies [0x20001028] to [0x20001038] and [0x2000102f] to
@   [0x2000103c] and sets [0x20001040..48]=0x7fc00000; when it is 0 and
@   [0x2000102d]!=0 leaves it; in all three cases then sends 0x1a to queue
@   [0x20002d6c] and tail-calls fn_080098e0.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800d548,"ax",%progbits
	.p2align 2
	.global fn_0800d548
	.thumb_func
	.type fn_0800d548, %function
fn_0800d548:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	subs r1, #1
	cmp r1, #8
	bhi.n .L0800d576
	tbb [pc, r1]
.L0800d560:
	.byte (.L0800d56a - .L0800d560)/2
	.byte (.L0800d578 - .L0800d560)/2
	.byte (.L0800d576 - .L0800d560)/2
	.byte (.L0800d576 - .L0800d560)/2
	.byte (.L0800d592 - .L0800d560)/2
	.byte (.L0800d5b2 - .L0800d560)/2
	.byte (.L0800d576 - .L0800d560)/2
	.byte (.L0800d576 - .L0800d560)/2
	.byte (.L0800d5c0 - .L0800d560)/2
	.byte 0x00			@ padding
.L0800d56a:
	ldrb.w r1, [r0, #0xf5d]
	and.w r1, r1, #0xf0
	cmp r1, #0xb0
	bne.n .L0800d5ee
.L0800d576:
	pop {r4, r5, r7, pc}
.L0800d578:
	movw r1, #0x109
	movt r1, #0x2			@ word 0x00020109
	str.w r1, [r0, #0xf68]
	movs r1, #1
	strb.w r1, [r0, #0x355]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d592:
	movs r1, #2
	strb.w r1, [r0, #0xf68]
	movs r1, #0
	strh.w r1, [r0, #0xe1c]
	str.w r1, [r0, #0xe12]
	str.w r1, [r0, #0xe16]
	strb.w r1, [r0, #0xe1a]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d5b2:
	movs r1, #5
	strb.w r1, [r0, #0xf68]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d5c0:
	ldrb.w r1, [r0, #0x355]
	cmp r1, #0
	it eq
	popeq {r4, r5, r7, pc}
	ldrb.w r1, [r0, #0xf6a]
	cmp r1, #2
	bne.n .L0800d616
	movs r1, #0
	movs r2, #2
	strb.w r1, [r0, #0x355]
	strb.w r2, [r0, #0xf68]
	strh.w r1, [r0, #0xf69]
	strb.w r1, [r0, #0xf6b]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d5ee:
	ldrb.w r1, [r0, #0xf2d]
	movs r2, #0
	cmp r1, #7
	strb.w r2, [r0, #0xf5d]
	bhi.n .L0800d576
	movs r2, #1
	lsl.w r1, r2, r1
	tst.w r1, #0xda
	beq.n .L0800d576
	ldrb.w r1, [r0, #0xf3d]
	cbz r1, .L0800d658
	movs r1, #0
	strb.w r1, [r0, #0xf3d]
	b.n .L0800d686
.L0800d616:
	movw r1, #0x201
	movw r5, #0x2d6c
	strh.w r1, [r0, #0xf69]
	movs r1, #0
	movw r4, #0x2d53
	movt r5, #0x2000
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
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
.L0800d658:
	ldrb.w r1, [r0, #0xf35]
	cbnz r1, .L0800d686
	movs r1, #1
	strb.w r1, [r0, #0xf3d]
	ldr.w r1, [r0, #0xf30]
	ldrb.w r2, [r0, #0xf37]
	str.w r1, [r0, #0xf40]
	movs r1, #0
	movt r1, #0x7fc0
	strb.w r2, [r0, #0xf44]
	str.w r1, [r0, #0xf48]
	str.w r1, [r0, #0xf4c]
	str.w r1, [r0, #0xf50]
.L0800d686:
	movw r0, #0x2d6c
	movw r1, #0x2d53
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #0x1a
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	pop.w {r4, r5, r7, lr}
	b.w fn_080098e0

@ ----------------------------------------------------------------------------
@ fn_0800d6ac - key handler, dispatch on the low byte of the word at 0x20001060.
@ No parameters. Purpose not determined from the code.
@ state 9: returns when [0x2000044d]==0; when [0x20001062]==4 clears it, sets
@   [0x20001060]=2, calls send_state_message_sequence (08012908); else stores
@   [0x20001061]=1,[0x20001062]=4 keeping the state byte and sends 0x13, 0x14 to
@   queue [0x20002d6c].
@ state 2: stores the word 0x00040109, sets [0x2000044d]=1, calls 08012908.
@ state 1: when [0x20001025]==3 and the high nibble of [0x20001055]!=0xb:
@   [0x20001055] becomes 0x11 when [0x20001034]==0 and it is 0, becomes 0xb0 (with
@   halfword 0x2a0 sent to queue [0x20002d74] and [0x20001025]=8) when it is 0x53,
@   becomes 0x53 when it is 0x22, otherwise becomes 0; then when the high nibble of
@   [0x20001055] is 0xb sends halfword 0x503 to queue [0x20002d74].
@ other states return.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800d6ac,"ax",%progbits
	.p2align 2
	.global fn_0800d6ac
	.thumb_func
	.type fn_0800d6ac, %function
fn_0800d6ac:
	push {r4, r5, r7, lr}
	movw r4, #0xf8
	movt r4, #0x2000
	ldrb.w r0, [r4, #0xf68]
	cmp r0, #9
	beq.n .L0800d6f2
	cmp r0, #2
	beq.n .L0800d720
	cmp r0, #1
	bne.w .L0800d7e0
	ldrb.w r0, [r4, #0xf2d]
	cmp r0, #3
	bne.n .L0800d7b0
	ldrb.w r0, [r4, #0xf5d]
	and.w r1, r0, #0xf0
	cmp r1, #0xb0
	beq.n .L0800d7b0
	ldrb.w r1, [r4, #0xf3c]
	orrs r1, r0
	beq.n .L0800d77c
	cmp r0, #0x53
	beq.n .L0800d784
	cmp r0, #0x22
	ite ne
	movne r0, #0
	moveq r0, #0x53
	b.n .L0800d77e
.L0800d6f2:
	ldrb.w r0, [r4, #0x355]
	cmp r0, #0
	it eq
	popeq {r4, r5, r7, pc}
	ldrb.w r0, [r4, #0xf6a]
	cmp r0, #4
	bne.n .L0800d73a
	movs r0, #0
	movs r1, #2
	strb.w r0, [r4, #0x355]
	strb.w r1, [r4, #0xf68]
	strh.w r0, [r4, #0xf69]
	strb.w r0, [r4, #0xf6b]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d720:
	movw r0, #0x109
	movt r0, #0x4			@ word 0x00040109
	str.w r0, [r4, #0xf68]
	movs r0, #1
	strb.w r0, [r4, #0x355]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d73a:
	movw r0, #0x401
	strh.w r0, [r4, #0xf69]
	movs r0, #0
	movw r5, #0x2d6c
	strb.w r0, [r4, #0xf6b]
	movw r4, #0x2d53
	movt r5, #0x2000
	movt r4, #0x2000
	movs r1, #0x13
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x14
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
.L0800d77c:
	movs r0, #0x11
.L0800d77e:
	strb.w r0, [r4, #0xf5d]
	b.n .L0800d7b0
.L0800d784:
	movs r0, #0xb0
	strb.w r0, [r4, #0xf5d]
	movw r0, #0x2d74
	movw r1, #0x2d54
	movt r0, #0x2000
	movt r1, #0x2000
	mov.w r2, #0x2a0
	ldr r0, [r0]
	strh r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r0, #8
	strb.w r0, [r4, #0xf2d]
.L0800d7b0:
	ldrb.w r0, [r4, #0xf5d]
	and.w r0, r0, #0xf0
	cmp r0, #0xb0
	bne.n .L0800d7e0
	movw r0, #0x2d74
	movw r1, #0x2d54
	movt r0, #0x2000
	movt r1, #0x2000
	ldr r0, [r0]
	movw r3, #0x503
	mov.w r2, #0xffffffff
	strh r3, [r1]
	pop.w {r4, r5, r7, lr}
	b.w queue_send_timeout
.L0800d7e0:
	pop {r4, r5, r7, pc}
	.short 0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0800d7e4 - key handler, dispatch on the state byte at 0x20001060.
@ No parameters. Purpose not determined from the code.
@ state 2: sets [0x20000f08]=1 and sends code 3 to queue [0x20002d6c] with
@   queue_send_timeout(queue, &[0x20002d53], 0xffffffff).
@ state 1: clears [0x20001055] unless its high nibble is 0xb.
@ other states return.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800d7e4,"ax",%progbits
	.p2align 2
	.global fn_0800d7e4
	.thumb_func
	.type fn_0800d7e4, %function
fn_0800d7e4:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #2
	beq.n .L0800d80e
	cmp r1, #1
	it ne
	bxne lr
	ldrb.w r1, [r0, #0xf5d]
	and.w r1, r1, #0xf0
	cmp r1, #0xb0
	itt ne
	movne r1, #0
	strbne.w r1, [r0, #0xf5d]
	bx lr
.L0800d80e:
	movs r1, #1
	strb.w r1, [r0, #0xe10]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #3
	mov.w r2, #0xffffffff
	strb r3, [r1]
	b.w queue_send_timeout
	.short 0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0800d834 - key handler, dispatch on the byte at 0x20001060 (cases 1..9,
@ others return).
@ No parameters. Purpose not determined from the code. Every handled case ends by
@ clearing the halfword [0x20002d50] and calling send_state_message_sequence
@ (08012908); cases 7 and 8 return before this.
@ state 1: clears bit13 of 0x4000440c, calls 0804178c on [0x20002da0] and
@   [0x20002da4], writes 0x800 to 0x40011014, calls semaphore_take_timeout
@   (080423a8)([0x20002d7c],0) and queue_reset (08041c38)([0x20002d74],0), sets
@   [0x2000102e]=1, [0x20001040..48]=0x7fc00000, clears the halfwords [0x20001034]
@   and [0x20001025], clears the word [0x20001028], stores [0x20001060]=0 and
@   [0x20001061]=0.
@ state 2: stores the halfword 0x0100 at 0x20001060 ([0x20001060]=0,[0x20001061]=1).
@ state 3: stores [0x20001062]=min([0x20000f51],7) and the halfword 0x0200
@   ([0x20001060]=0,[0x20001061]=2).
@ state 4: stores the halfword 0x0300 ([0x20001060]=0,[0x20001061]=3).
@ states 5 and 6: clear the halfword [0x20000f14], the words [0x20000f0a] and
@   [0x20000f0e], the byte [0x20000f12] and store 0x0100.
@ state 9: clears [0x2000044d] and stores the word 0x00000100.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800d834,"ax",%progbits
	.p2align 2
	.global fn_0800d834
	.thumb_func
	.type fn_0800d834, %function
fn_0800d834:
	push {r4, r5, r7, lr}
	movw r4, #0xf8
	movt r4, #0x2000
	ldrb.w r0, [r4, #0xf68]
	subs r0, #1
	cmp r0, #8
	it hi
	pophi {r4, r5, r7, pc}
	tbb [pc, r0]
.L0800d84e:
	.byte (.L0800d874 - .L0800d84e)/2
	.byte (.L0800d904 - .L0800d84e)/2
	.byte (.L0800d90e - .L0800d84e)/2
	.byte (.L0800d926 - .L0800d84e)/2
	.byte (.L0800d858 - .L0800d84e)/2
	.byte (.L0800d858 - .L0800d84e)/2
	.byte (.L0800d952 - .L0800d84e)/2
	.byte (.L0800d952 - .L0800d84e)/2
	.byte (.L0800d930 - .L0800d84e)/2
	.byte 0x00			@ padding
.L0800d858:
	movs r0, #0
	mov.w r1, #0x100
	strh.w r0, [r4, #0xe1c]
	strh.w r1, [r4, #0xf68]
	str.w r0, [r4, #0xe12]
	str.w r0, [r4, #0xe16]
	strb.w r0, [r4, #0xe1a]
	b.n .L0800d93e
.L0800d874:
	movw r0, #0x440c
	movt r0, #0x4000
	ldr r1, [r0]
	bic.w r1, r1, #0x2000
	str r1, [r0]
	movw r0, #0x2da0
	movt r0, #0x2000
	ldr r0, [r0]
	bl fn_0804178c
	movw r0, #0x2da4
	movt r0, #0x2000
	ldr r0, [r0]
	bl fn_0804178c
	movw r0, #0x1014
	movt r0, #0x4001
	mov.w r1, #0x800
	str r1, [r0]
	movw r0, #0x2d7c
	movt r0, #0x2000
	ldr r0, [r0]
	movs r1, #0
	movs r5, #0
	bl semaphore_take_timeout
	movw r0, #0x2d74
	movt r0, #0x2000
	ldr r0, [r0]
	movs r1, #0
	bl queue_reset
	movs r0, #1
	strb.w r0, [r4, #0xf36]
	movs r0, #0
	movt r0, #0x7fc0
	str.w r0, [r4, #0xf48]
	str.w r0, [r4, #0xf4c]
	str.w r0, [r4, #0xf50]
	ldrb.w r0, [r4, #0xf68]
	strh.w r5, [r4, #0xf3c]
	subs r0, #1
	strh.w r5, [r4, #0xf2d]
	str.w r5, [r4, #0xf30]
	strb.w r0, [r4, #0xf69]
	strb.w r5, [r4, #0xf68]
	b.n .L0800d93e
.L0800d904:
	mov.w r0, #0x100
	strh.w r0, [r4, #0xf68]
	b.n .L0800d93e
.L0800d90e:
	ldrb.w r0, [r4, #0xe59]
	cmp r0, #7
	it cs
	movcs r0, #7
	strb.w r0, [r4, #0xf6a]
	mov.w r0, #0x200
	strh.w r0, [r4, #0xf68]
	b.n .L0800d93e
.L0800d926:
	mov.w r0, #0x300
	strh.w r0, [r4, #0xf68]
	b.n .L0800d93e
.L0800d930:
	movs r0, #0
	strb.w r0, [r4, #0x355]
	mov.w r0, #0x100
	str.w r0, [r4, #0xf68]
.L0800d93e:
	movw r0, #0x2d50
	movt r0, #0x2000
	movs r1, #0
	strh r1, [r0]
	pop.w {r4, r5, r7, lr}
	b.w send_state_message_sequence
.L0800d952:
	pop {r4, r5, r7, pc}

@ ----------------------------------------------------------------------------
@ fn_0800d954 - key handler acting on the state byte [0x20001060].
@ No parameters. Purpose not determined from the code.
@ state 3: toggles [0x20000f50], sends 8, 0x18, 0x19 to queue [0x20002d6c] and
@   tail-calls fn_08029d40; states other than 2 and 3 return.
@ state 2, branch A (taken only when the bytes [0x2000044a] and [0x2000044b] are
@   both neither 0 nor 0xff): sets [0x200000fd]=0 and [0x200000fc]=0, or (when
@   [0x2000012c]==0 and the low byte of [0x2000010c]==3) [0x200000fc]=0x32 and
@   [0x200000fd]=-0x32; clears the halfword [0x20000112], [0x20000118],
@   [0x2000011c], loads [0x20000114] with [0x200000fc+[0x2000010e]]; recomputes
@   0x40007408/0x40007404 and 0x40001c34 from the halfword tables
@   (0x200003a8/0x2000036c, 0x200003bc/0x20000380, 0x20000394/0x20000358 and
@   0x20000420/0x200003e4, 0x20000434/0x200003f8, 0x2000040c/0x200003d0) using
@   [0x200000fa], [0x200000fb] and the offsets (float constant 200.0 at
@   0800de90 / 0800df54); sets [0x20000124]=100 when [0x20000126]!=0; calls
@   queue_send_timeout(queue [0x20002d80],0,0), sends 8 to queue [0x20002d78],
@   calls fn_08025fc0, and when [0x2000012c]==0 sends 5 then 6 to queue
@   [0x20002d6c].
@ branch B (a byte is 0 or 0xff): sets the halfword [0x2000012a]=0x100; when the
@   low byte of [0x2000010c]!=3 stores the halfword 0x0203 at 0x2000010c, writes
@   4 to 0x40011410, 4 to 0x40011010, 2 to 0x40011014 and sends 2 to queue
@   [0x20002d78]; sets [0x200000f8]=1, [0x200000fa]=7, [0x200000f9]=1,
@   [0x200000fb]=7, writes 0x1000 and 0x2000 to 0x40011410, 0x1000 to 0x40011014,
@   0x10/0x20/0x40 to 0x40011810/0x40011814, 0x8000/0x800/0x400 to
@   0x40010814/0x40010c14/0x40010c10/0x40010810, sets 0x40007408 from the halfword
@   at 0x2000037a/0x2000038e/0x20000366 and 0x40001c34 from
@   0x200003f2/0x20000406/0x200003de, sets [0x200000fc]=0x9c, [0x200000fd]=-100,
@   [0x20000125]=4, [0x2000010f]=1 (0x10 to 0x40011014 when it was not 1),
@   [0x20000114]=-100, caps [0x20000ea8] at 2, clears bit0 of 0x40000400, sets
@   [0x20000eac]=0x12d0000, when [0x20000126]==0 sets it to 1 and releases the
@   buffers [0x20000ef4], [0x20000ef8] (as in 0800bd60), sends 4,5,2,6 to queue
@   [0x20002d6c] and 1,8 to queue [0x20002d78].
@ ----------------------------------------------------------------------------
	.section .text.fn_0800d954,"ax",%progbits
	.p2align 2
	.global fn_0800d954
	.thumb_func
	.type fn_0800d954, %function
fn_0800d954:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #4
	movw r9, #0xf8
	movt r9, #0x2000		@ r9 = 0x200000f8
	ldrb.w r0, [r9, #0xf68]		@ state byte [0x20001060]
	cmp r0, #3
	beq.n .L0800d9e2
	cmp r0, #2
	bne.w .L0800df20
	ldrb.w r0, [r9, #0x352]		@ [0x2000044a]
	movw r5, #0x7404
	movw r8, #0x1c34
	movt r5, #0x4000
	movt r8, #0x4000
	cbz r0, .L0800d996
	cmp r0, #0xff
	beq.n .L0800d996
	ldrb.w r0, [r9, #0x353]		@ [0x2000044b]
	cmp r0, #0xff
	beq.n .L0800d996
	cmp r0, #0
	bne.n .L0800da3a
.L0800d996:
	ldrb.w r0, [r9, #0x14]
	movw r4, #0x1410
	movw r6, #0x1014
	movt r4, #0x4001
	movt r6, #0x4001
	mov.w r1, #0x100
	cmp r0, #3
	strh.w r1, [r9, #0x32]
	beq.w .L0800dabc
	movw r0, #0x203
	movs r1, #4
	strh.w r0, [r9, #0x14]
	str r1, [r4]
	ldrb.w r0, [r9, #0x14]
	cmp r0, #3
	beq.n .L0800da90
	cmp r0, #2
	beq.n .L0800da96
	cmp r0, #1
	bne.n .L0800da9e
	movs r0, #4
	str.w r0, [r6, #-4]
	movs r0, #2
	str.w r0, [r6, #-4]
	b.n .L0800da9e
.L0800d9e2:
	ldrb.w r0, [r9, #0xe58]
	movw r5, #0x2d6c
	clz r0, r0
	lsrs r0, r0, #5
	movw r4, #0x2d53
	movt r5, #0x2000
	strb.w r0, [r9, #0xe58]
	movt r4, #0x2000
	movs r1, #8
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x18
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x19
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	b.w fn_08029d40
.L0800da3a:
	ldrb.w r1, [r9, #0x14]
	ldrb.w r0, [r9, #0x34]
	eor.w r2, r1, #3
	orrs r0, r2
	uxtb r0, r0
	cmp r0, #0
	mov.w r0, #0
	mov.w r3, #0
	mov r6, r9
	it eq
	moveq r0, #0x32
	it eq
	mvneq r3, #0x31
	strb.w r0, [r6, #4]!
	movs r2, #0
	ldrb r7, [r6, #0x12]
	strb r3, [r6, #1]
	strh r2, [r6, #0x16]
	strd r2, r2, [r6, #0x1c]
	ldrb.w r3, [r6, #0x29]
	ldrb.w r2, [r6, #-2]
	ldrsb r7, [r6, r7]
	cmp r3, #5
	strh r7, [r6, #0x18]
	bcc.w .L0800ddf6
	add.w r2, r9, r2, lsl #1
	add.w r1, r2, #0x29c
	add.w r2, r2, #0x260
	b.n .L0800de12
.L0800da90:
	str.w r1, [r6, #-4]
	b.n .L0800da9a
.L0800da96:
	movs r0, #4
	str r0, [r6]
.L0800da9a:
	movs r0, #2
	str r0, [r6]
.L0800da9e:
	movw r0, #0x2d78
	movw r1, #0x2d52
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #2
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L0800dabc:
	movs r0, #1
	strb.w r0, [r9]
	mov.w r0, #0x1000
	movs r1, #7
	str r0, [r4]
	strb.w r1, [r9, #2]
	str r0, [r6]
	movw r0, #0x1814
	movt r0, #0x4001
	movs r1, #0x10
	str r1, [r0]
	movs r0, #0x20
	str.w r0, [r4, #0x400]
	movs r0, #0x40
	str.w r0, [r4, #0x400]
	ldrb.w r1, [r9, #0x2d]
	cmp r1, #4
	bls.n .L0800dafa
	addw r0, r9, #0x2aa
	addw r1, r9, #0x26e
	b.n .L0800db16
.L0800dafa:
	addw r0, r9, #0x2be
	cmp r1, #4
	addw r1, r9, #0x282
	beq.n .L0800db16
	ldrb.w r2, [r9, #0x14]
	cmp r2, #3
	itt ne
	addwne r0, r9, #0x2d2
	addwne r1, r9, #0x296
.L0800db16:
	ldrh r0, [r0]
	ldrh r1, [r1]
	vldr s0, .L0800de90
	subs r0, r0, r1
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s2, s2, s0
	ldrsb.w r0, [r9, #4]
	movs r2, #0x9c
	adds r0, #0x64
	vmov s4, r0
	vcvt.f32.s32 s4, s4
	ldr r0, [r5, #4]
	lsrs r0, r0, #0xc
	vmul.f32 s2, s2, s4
	vmov s4, r1
	vcvt.f32.u32 s4, s4
	vadd.f32 s2, s2, s4
	vcvt.u32.f32 s2, s2
	vmov r1, s2
	bfi r1, r0, #0xc, #0x14
	str r1, [r5, #4]
	ldr r0, [r5]
	orr.w r0, r0, #1
	str r0, [r5]
	ldrb.w r1, [r9, #0x2d]
	ldrb.w r0, [r9, #2]
	cmp r1, #5
	strb.w r2, [r9, #4]
	bcc.n .L0800db80
	add.w r0, r9, r0, lsl #1
	add.w r0, r0, #0x260
	b.n .L0800db9e
.L0800db80:
	cmp r1, #4
	beq.n .L0800db96
	ldrb.w r1, [r9, #0x14]
	cmp r1, #3
	beq.n .L0800db96
	add.w r0, r9, r0, lsl #1
	add.w r0, r0, #0x288
	b.n .L0800db9e
.L0800db96:
	add.w r0, r9, r0, lsl #1
	add.w r0, r0, #0x274
.L0800db9e:
	ldrh r0, [r0]
	ldr r1, [r5, #4]
	mov.w r2, #0x800
	bfi r1, r0, #0, #0xc
	str r1, [r5, #4]
	ldr r0, [r5]
	mov.w r1, #0x8000
	orr.w r0, r0, #1
	str r0, [r5]
	movs r0, #1
	strb.w r0, [r9, #1]
	mov.w r0, #0x2000
	str r0, [r4]
	movs r0, #7
	strb.w r0, [r9, #3]
	movw r0, #0x810
	movt r0, #0x4001
	str r1, [r0, #4]
	movw r1, #0xfc00
	movt r1, #0xffff
	str r2, [r6, r1]
	mov.w r1, #0x400
	str.w r1, [r0, #0x400]
	str r1, [r0]
	ldrb.w r1, [r9, #0x2d]
	cmp r1, #4
	bls.n .L0800dbfa
	addw r0, r9, #0x322
	addw r1, r9, #0x2e6
	b.n .L0800dc16
.L0800dbfa:
	addw r0, r9, #0x336
	cmp r1, #4
	addw r1, r9, #0x2fa
	beq.n .L0800dc16
	ldrb.w r2, [r9, #0x14]
	cmp r2, #3
	itt ne
	addwne r0, r9, #0x34a
	addwne r1, r9, #0x30e
.L0800dc16:
	ldrh r0, [r0]
	ldrh r1, [r1]
	movs r2, #0x9c
	subs r0, r0, r1
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s0, s2, s0
	ldrsb.w r0, [r9, #5]
	adds r0, #0x64
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vmul.f32 s0, s0, s2
	vmov s2, r1
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vstr s0, [r8]
	ldrb.w r1, [r9, #0x2d]
	ldrb.w r0, [r9, #3]
	cmp r1, #5
	strb.w r2, [r9, #5]
	bcc.n .L0800dc6a
	add.w r0, r9, r0, lsl #1
	add.w r0, r0, #0x2d8
	b.n .L0800dc88
.L0800dc6a:
	cmp r1, #4
	beq.n .L0800dc80
	ldrb.w r1, [r9, #0x14]
	cmp r1, #3
	beq.n .L0800dc80
	add.w r0, r9, r0, lsl #1
	add.w r0, r0, #0x300
	b.n .L0800dc88
.L0800dc80:
	add.w r0, r9, r0, lsl #1
	add.w r0, r0, #0x2ec
.L0800dc88:
	ldrh r0, [r0]
	movw r11, #0x2d6c
	str.w r0, [r8]
	movw r4, #0x2d53
	movt r11, #0x2000
	movt r4, #0x2000
	ldr.w r0, [r11]
	movs r5, #4
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r5, [r4]
	bl queue_send_timeout
	movs r1, #5
	ldr.w r0, [r11]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldrb.w r0, [r9, #0xdb0]
	movw r8, #0x2d78
	cmp r0, #3
	itt cs
	movcs r0, #2
	strbcs.w r0, [r9, #0xdb0]
	strb.w r5, [r9, #0x2d]
	movw r5, #0x2d52
	movt r8, #0x2000
	movt r5, #0x2000
	ldr.w r0, [r8]
	movs r7, #1
	mov r1, r5
	mov.w r2, #0xffffffff
	strb r7, [r5]
	bl queue_send_timeout
	movw r0, #0x400
	movt r0, #0x4000
	ldr r1, [r0]
	bic.w r1, r1, #1
	str r1, [r0]
	ldrb.w r0, [r9, #0x2e]
	movs r1, #0
	movt r1, #0x12d
	cmp r0, #0
	str.w r1, [r9, #0xdb4]
	bne.n .L0800dda0
	ldr.w r0, [r9, #0xdfc]
	movw r10, #0x1070
	movt r10, #0x2000
	strb.w r7, [r9, #0x2e]
	cbz r0, .L0800dd62
	ldrb.w r1, [r10, #0x10]
	cbz r1, .L0800dd54
	ldr.w r1, [r10, #8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800dd5c
	ldr.w r2, [r10, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800dd5c
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800dd5c
.L0800dd54:
	ldr.w r1, [r10]
	movs r0, #0
	blx r1
.L0800dd5c:
	movs r0, #0
	str.w r0, [r9, #0xdfc]
.L0800dd62:
	ldr.w r0, [r9, #0xe00]
	cbz r0, .L0800dda0
	ldrb.w r1, [r10, #0x10]
	cbz r1, .L0800dd92
	ldr.w r1, [r10, #8]
	subs r0, r0, r1
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0800dd9a
	ldr.w r2, [r10, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0800dd9a
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0800dd9a
.L0800dd92:
	ldr.w r1, [r10]
	movs r0, #0
	blx r1
.L0800dd9a:
	movs r0, #0
	str.w r0, [r9, #0xe00]
.L0800dda0:
	movs r1, #2
	ldr.w r0, [r11]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldrb.w r0, [r9, #0x17]
	cmp r0, #1
	beq.n .L0800ddc4
	movs r0, #1
	strb.w r0, [r9, #0x17]
	movs r0, #0x10
	str r0, [r6]
.L0800ddc4:
	movw r0, #0xff9c
	strh.w r0, [r9, #0x1c]
	movs r1, #6
	ldr.w r0, [r11]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr.w r0, [r8]
	movs r3, #8
	mov r1, r5
	mov.w r2, #0xffffffff
	strb r3, [r5]
.L0800ddec:
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	b.w queue_send_timeout
.L0800ddf6:
	cmp r3, #4
	add.w r2, r9, r2, lsl #1
	it ne
	cmpne r1, #3
	ittee ne
	addne.w r1, r2, #0x2c4
	addne.w r2, r2, #0x288
	addeq.w r1, r2, #0x2b0
	addeq.w r2, r2, #0x274
.L0800de12:
	ldrh r1, [r1]
	ldrh r2, [r2]
	vldr s0, .L0800df54
	subs r1, r1, r2
	vmov s2, r1
	vcvt.f32.s32 s2, s2
	vdiv.f32 s2, s2, s0
	adds r0, #0x64
	vmov s4, r0
	vcvt.f32.u32 s4, s4
	ldr r0, [r5, #4]
	lsrs r0, r0, #0xc
	vmul.f32 s2, s2, s4
	vmov s4, r2
	vcvt.f32.u32 s4, s4
	vadd.f32 s2, s2, s4
	vcvt.u32.f32 s2, s2
	vmov r1, s2
	bfi r1, r0, #0xc, #0x14
	str r1, [r5, #4]
	ldr r0, [r5]
	orr.w r0, r0, #1
	str r0, [r5]
	ldrb.w r1, [r9, #0x2d]
	ldrb.w r0, [r9, #3]
	cmp r1, #5
	bcc.n .L0800de76
	add.w r1, r9, r0, lsl #1
	add.w r0, r1, #0x314
	add.w r1, r1, #0x2d8
	b.n .L0800dea0
.L0800de76:
	cmp r1, #4
	beq.n .L0800de94
	ldrb.w r1, [r9, #0x14]
	cmp r1, #3
	beq.n .L0800de94
	add.w r1, r9, r0, lsl #1
	add.w r0, r1, #0x33c
	add.w r1, r1, #0x300
	b.n .L0800dea0
.L0800de90:
	.word 0x43480000		@ 200.0f
.L0800de94:
	add.w r1, r9, r0, lsl #1
	add.w r0, r1, #0x328
	add.w r1, r1, #0x2ec
.L0800dea0:
	ldrh r0, [r0]
	ldrh r1, [r1]
	movs r2, #0
	subs r0, r0, r1
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s0, s2, s0
	ldrsb.w r0, [r9, #5]
	adds r0, #0x64
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vmul.f32 s0, s0, s2
	vmov s2, r1
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vstr s0, [r8]
	ldrb.w r0, [r9, #0x2e]
	movs r1, #0
	cmp r0, #0
	itt ne
	movne r0, #0x64
	strbne.w r0, [r9, #0x2c]
	movw r0, #0x2d80
	movt r0, #0x2000
	ldr r0, [r0]
	bl queue_send_timeout
	movw r0, #0x2d78
	movw r1, #0x2d52
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #8
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	bl fn_08025fc0
	ldrb.w r0, [r9, #0x34]
	cbz r0, .L0800df26
.L0800df20:
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0800df26:
	movw r5, #0x2d6c
	movw r4, #0x2d53
	movt r5, #0x2000
	movt r4, #0x2000
	movs r1, #5
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #6
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	b.n .L0800ddec
.L0800df54:
	.word 0x43480000		@ 200.0f
