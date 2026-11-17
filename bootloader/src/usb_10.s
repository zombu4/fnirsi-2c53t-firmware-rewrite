@ usb_10.s - USB module, batch 10: endpoint-entry table initialisation, endpoint configuration, receive arming, IN queueing and the endpoint transfer-complete handler.
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ init_endpoint_entries - initialises the table of endpoint entries.
@ Parameter: r0 = R (base of the USB state block). No return value.
@ Callers: 0x08003886, 0x080043aa.
@ For i = 0..7: IN entry at R+0xc+i*0x20: bytes [+0] = i, [+1] = i, [+2] = 1,
@ halfword [+8] = 0, word [+0x14] = 0, halfwords [+0xe], [+4], [+6] = 0.
@ Second loop for the entries at R+0x10c+i*0x20: bytes [+0] = i, [+1] = i,
@ [+2] = 0, same zeroing.
@ Entry layout used by the other functions: +0 and +1 endpoint number,
@ +2 direction flag (1 IN, 0 OUT), +3 type code, +4 and +6 buffer offsets,
@ +8 maximum packet size, +0xa double-buffer flag, +0xb stall flag,
@ +0xe length left, +0x10 length done, +0x14 buffer pointer.
@ ----------------------------------------------------------------------------
	.section .text.init_endpoint_entries,"ax",%progbits
	.p2align 2
	.global init_endpoint_entries
	.thumb_func
	.type init_endpoint_entries, %function
init_endpoint_entries:
	mov	r1, r0
	movs	r0, #0
	nop
	b.n	.L08003ca4
.L08003c4c:
	add.w	r2, r1, #0xc
	add.w	r2, r2, r0, lsl #5
	strb	r0, [r2, #0]
	add.w	r2, r1, #0xc
	add.w	r2, r2, r0, lsl #5
	strb	r0, [r2, #1]
	movs	r3, #1
	add.w	r2, r1, #0xc
	add.w	r2, r2, r0, lsl #5
	strb	r3, [r2, #2]
	movs	r3, #0
	add.w	r2, r1, #0xc
	add.w	r2, r2, r0, lsl #5
	strh	r3, [r2, #8]
	add.w	r2, r1, #0xc
	add.w	r2, r2, r0, lsl #5
	str	r3, [r2, #0x14]
	add.w	r2, r1, #0xc
	add.w	r2, r2, r0, lsl #5
	strh	r3, [r2, #0xe]
	add.w	r2, r1, #0xc
	add.w	r2, r2, r0, lsl #5
	strh	r3, [r2, #4]
	add.w	r2, r1, #0xc
	add.w	r2, r2, r0, lsl #5
	strh	r3, [r2, #6]
	adds	r2, r0, #1
	uxtb	r0, r2
.L08003ca4:
	cmp	r0, #8
	blt.n	.L08003c4c
	movs	r0, #0
	b.n	.L08003d02
.L08003cac:
	add.w	r2, r1, #0x10c
	add.w	r2, r2, r0, lsl #5
	strb	r0, [r2, #0]
	add.w	r2, r1, #0x10c
	add.w	r2, r2, r0, lsl #5
	strb	r0, [r2, #1]
	movs	r3, #0
	add.w	r2, r1, #0x10c
	add.w	r2, r2, r0, lsl #5
	strb	r3, [r2, #2]
	add.w	r2, r1, #0x10c
	add.w	r2, r2, r0, lsl #5
	strh	r3, [r2, #8]
	add.w	r2, r1, #0x10c
	add.w	r2, r2, r0, lsl #5
	str	r3, [r2, #0x14]
	add.w	r2, r1, #0x10c
	add.w	r2, r2, r0, lsl #5
	strh	r3, [r2, #0xe]
	add.w	r2, r1, #0x10c
	add.w	r2, r2, r0, lsl #5
	strh	r3, [r2, #6]
	add.w	r2, r1, #0x10c
	add.w	r2, r2, r0, lsl #5
	strh	r3, [r2, #4]
	adds	r2, r0, #1
	uxtb	r0, r2
.L08003d02:
	cmp	r0, #8
	blt.n	.L08003cac
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08003d08 - polls the interrupt-status word until bit 15 clears.
@ Parameter: r0 = R; base = word [R]. Loop while bit 15 (0x8000) of word
@ [base+0x44] is set: calls fn_08003f1c(R, word [base+0x44] & 0xf).
@ No return value. Caller: 0x0800430e.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003d08,"ax",%progbits
	.global fn_08003d08
	.thumb_func
	.type fn_08003d08, %function
fn_08003d08:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r4, r0
	ldr	r6, [r4, #0]
	movs	r7, #0
	b.n	.L08003d20
.L08003d14:
	and	r7, r5, #0xf
	mov	r1, r7
	mov	r0, r4
	bl	fn_08003f1c
.L08003d20:
	ldr	r5, [r6, #0x44]
	and	r0, r5, #0x8000
	cmp	r0, #0
	bne.n	.L08003d14
	pop.w	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_08003d2e - configures one endpoint entry.
@ Parameters: r0 = R, r1 = code, r2 = type code, r3 = size. No return value.
@ E = R+0x10c+(r1&0x7f)*0x20 with byte [E+2] = 0 when r1 bit 7 is clear, else
@ R+0xc+(r1&0x7f)*0x20 with byte [E+2] = 1. Halfword [E+8] = (r3 + 1) & 0xfffe,
@ byte [E+3] = r2. Then fn_08003bd0(E) and fn_08003108(word [R], E).
@ Callers: 0x080043aa (called with codes 0 and 0x80, type 0, size 0x40),
@ 0x0800143a, 0x08001478.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003d2e,"ax",%progbits
	.global fn_08003d2e
	.thumb_func
	.type fn_08003d2e, %function
fn_08003d2e:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r5, r0
	mov	r6, r1
	mov	r7, r2
	mov	r8, r3
	ldr.w	r9, [r5, #0]
	and	r0, r6, #0x80
	cbnz	r0, .L08003d56
	and	r1, r6, #0x7f
	add.w	r0, r5, #0x10c
	add.w	r4, r0, r1, lsl #5
	movs	r0, #0
	strb	r0, [r4, #2]
	b.n	.L08003d66
.L08003d56:
	and	r1, r6, #0x7f
	add.w	r0, r5, #0xc
	add.w	r4, r0, r1, lsl #5
	movs	r0, #1
	strb	r0, [r4, #2]
.L08003d66:
	add.w	r0, r8, #1
	movw	r1, #0xfffe
	ands	r0, r1
	strh	r0, [r4, #8]
	strb	r7, [r4, #3]
	mov	r0, r4
	bl	fn_08003bd0
	mov	r1, r4
	mov	r0, r9
	bl	fn_08003108
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
	.short	0x0000			@ padding (never reached; aligns fn_08003d88)

@ ----------------------------------------------------------------------------
@ fn_08003d88 - arms an OUT endpoint for receive.
@ Parameters: r0 = R, r1 = code, r2 = buffer pointer, r3 = length.
@ E = R+0x10c+(r1&0x7f)*0x20: word [E+0x14] = r2, halfword [E+0xe] = r3,
@ halfword [E+0x10] = 0; when halfword [E+0xe] > halfword [E+8] (signed
@ compare) [E+0xe] -= [E+8], else [E+0xe] = 0.
@ Then the word at 0x40005000 + 0xc00 + (r1&0x7f)*4 =
@ ((V & 0xbf8f) ^ 0x1000 ^ 0x2000) | 0x8000 | 0x80 with V its previous value.
@ No return value.
@ Callers: 0x080038b2, 0x0800397e, 0x08003f1c at 0x080040e2, 0x080037cc,
@ 0x08000e70, 0x080010c8, 0x080010f0, 0x08001190, 0x08001286.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003d88,"ax",%progbits
	.p2align 2
	.global fn_08003d88
	.thumb_func
	.type fn_08003d88, %function
fn_08003d88:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r5, r0
	mov	r4, r2
	and	r7, r1, #0x7f
	add.w	r2, r5, #0x10c
	add.w	r0, r2, r7, lsl #5
	movs	r6, #0
	str	r4, [r0, #0x14]
	strh	r3, [r0, #0xe]
	movs	r2, #0
	strh	r2, [r0, #0x10]
	ldrh	r2, [r0, #0xe]
	ldrh	r7, [r0, #8]
	cmp	r2, r7
	ble.n	.L08003db8
	ldrh	r6, [r0, #8]
	ldrh	r2, [r0, #0xe]
	subs	r2, r2, r6
	strh	r2, [r0, #0xe]
	b.n	.L08003dbe
.L08003db8:
	mov	r6, r3
	movs	r2, #0
	strh	r2, [r0, #0xe]
.L08003dbe:
	lsls	r7, r1, #0x19
	ldr.w	r12, .L08003df8
	add.w	r7, r12, r7, lsr #0x17
	ldr.w	r7, [r7, #0xc00]
	movw	r12, #0xbf8f
	and.w	r2, r7, r12
	eor	r2, r2, #0x1000
	eor	r2, r2, #0x2000
	orr	r7, r2, #0x8000
	orr	r7, r7, #0x80
	lsl.w	r12, r1, #0x19
	ldr.w	r8, .L08003df8
	add.w	r12, r8, r12, lsr #0x17
	str.w	r7, [r12, #0xc00]
	pop.w	{r4, r5, r6, r7, r8, pc}
.L08003df8:
	.word	0x40005000

@ ----------------------------------------------------------------------------
@ fn_08003dfc - queues data on an IN endpoint.
@ Parameters: r0 = R, r1 = code (only r1 & 0x7f is used, the entry is always
@ the IN entry), r2 = buffer pointer, r3 = length. No return value.
@ E = R+0xc+(r1&0x7f)*0x20; word [E+0x14] = r2, halfword [E+0xe] = r3,
@ halfword [E+0x10] = 0; n = min(r3, [E+8]) with [E+0xe] = r3 - [E+8] when
@ r3 > [E+8] else 0; halfword [E+0x18] = n.
@ Byte [E+10] == 0: copy_to_200000bc_area(r2, [E+4], n) and word store of n
@ at word [0x200000bc] + 2 * (word [0x40005c50] + ep*8 + 2).
@ Byte [E+10] != 0: with W = word [word [R] + ep*4]: bit 6 of W set: store n
@ at the +6 slot, copy_to_200000bc_area(r2, [E+6], n); clear: store n at the
@ +2 slot, copy_to_200000bc_area(r2, [E+4], n); then register word
@ 0x40005c00 + ep*4 = (V & 0x8f8f) | 0xc080.
@ Finally on every path register 0x40005c00 + ep*4 =
@ ((V & 0x8fbf) ^ 0x30) | 0x8080.
@ Callers: 0x080039be, 0x08003996, 0x08003f1c at 0x08003f8e, 0x080037cc,
@ 0x08000f74, 0x080010f0, 0x08001134.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003dfc,"ax",%progbits
	.p2align 2
	.global fn_08003dfc
	.thumb_func
	.type fn_08003dfc, %function
fn_08003dfc:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r7, r0
	mov	r5, r1
	mov	r9, r2
	mov	r8, r3
	and	r1, r5, #0x7f
	add.w	r0, r7, #0xc
	add.w	r4, r0, r1, lsl #5
	movs	r6, #0
	ldr.w	r10, [r7, #0]
	str.w	r9, [r4, #0x14]
	strh.w	r8, [r4, #0xe]
	movs	r0, #0
	strh	r0, [r4, #0x10]
	ldrh	r0, [r4, #0xe]
	ldrh	r1, [r4, #8]
	cmp	r0, r1
	ble.n	.L08003e38
	ldrh	r6, [r4, #8]
	ldrh	r0, [r4, #0xe]
	subs	r0, r0, r6
	strh	r0, [r4, #0xe]
	b.n	.L08003e3e
.L08003e38:
	mov	r6, r8
	movs	r0, #0
	strh	r0, [r4, #0xe]
.L08003e3e:
	strh	r6, [r4, #0x18]
	ldrb	r0, [r4, #0xa]
	cbnz	r0, .L08003e66
	ldrh	r1, [r4, #4]
	mov	r2, r6
	ldr	r0, [r4, #0x14]
	bl	copy_to_200000bc_area
	ldr	r0, .L08003f10
	ldr	r1, [r0, #0]
	and	r0, r5, #0x7f
	add.w	r0, r1, r0, lsl #3
	.inst.n	0x1c80			@ adds r0, r0, #2
	ldr	r1, .L08003f14
	ldr	r1, [r1, #0]
	str.w	r6, [r1, r0, lsl #1]
	b.n	.L08003edc
.L08003e66:
	and	r0, r5, #0x7f
	ldr.w	r0, [r10, r0, lsl #2]
	ubfx	r0, r0, #6, #1
	cbz	r0, .L08003e96
	ldr	r0, .L08003f10
	ldr	r1, [r0, #0]
	and	r0, r5, #0x7f
	add.w	r0, r1, r0, lsl #3
	.inst.n	0x1d80			@ adds r0, r0, #6
	ldr	r1, .L08003f14
	ldr	r1, [r1, #0]
	str.w	r6, [r1, r0, lsl #1]
	ldrh	r1, [r4, #6]
	mov	r2, r6
	ldr	r0, [r4, #0x14]
	bl	copy_to_200000bc_area
	b.n	.L08003eb6
.L08003e96:
	ldr	r0, .L08003f10
	ldr	r1, [r0, #0]
	and	r0, r5, #0x7f
	add.w	r0, r1, r0, lsl #3
	.inst.n	0x1c80			@ adds r0, r0, #2
	ldr	r1, .L08003f14
	ldr	r1, [r1, #0]
	str.w	r6, [r1, r0, lsl #1]
	ldrh	r1, [r4, #4]
	mov	r2, r6
	ldr	r0, [r4, #0x14]
	bl	copy_to_200000bc_area
.L08003eb6:
	lsls	r0, r5, #0x19
	ldr	r1, .L08003f18
	add.w	r0, r1, r0, lsr #0x17
	ldr.w	r0, [r0, #0xc00]
	movw	r1, #0x8f8f
	ands	r0, r1
	orr	r0, r0, #0xc000
	orr	r0, r0, #0x80
	lsls	r1, r5, #0x19
	ldr	r2, .L08003f18
	add.w	r1, r2, r1, lsr #0x17
	str.w	r0, [r1, #0xc00]
.L08003edc:
	lsls	r1, r5, #0x19
	ldr	r2, .L08003f18
	add.w	r1, r2, r1, lsr #0x17
	ldr.w	r1, [r1, #0xc00]
	movw	r2, #0x8fbf
	and.w	r0, r1, r2
	eor	r0, r0, #0x10
	eor	r0, r0, #0x20
	orr	r1, r0, #0x8000
	orr	r1, r1, #0x80
	lsls	r2, r5, #0x19
	ldr	r3, .L08003f18
	add.w	r2, r3, r2, lsr #0x17
	str.w	r1, [r2, #0xc00]
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
.L08003f10:
	.word	0x40005c50
.L08003f14:
	.word	0x200000bc
.L08003f18:
	.word	0x40005000

@ ----------------------------------------------------------------------------
@ fn_08003f1c - endpoint transfer-complete handler.
@ Parameters: r0 = R, r1 = ep (0..15). base = word [R]; W = word [base + ep*4].
@ No return value. Caller: fn_08003d08 (0x08003d1c).
@ Case W bit 7 (0x80) set: IN entry E = R+0xc+ep*0x20; register
@ 0x40005c00+ep*4 &= 0x8f0f; halfword [E+0x10] = halfword at word
@ [0x200000bc] + 2*(word [0x40005c50] + ep*8 + 2) & 0x3ff; word [E+0x14] +=
@ [E+0x10]; when halfword [E+0xe] == 0 or ep == 0 calls fn_080037cc(R, ep),
@ else fn_08003dfc(R, ep, [E+0x14], [E+0xe]); then when byte [R+0x224] == 2
@ and byte [R+0x226] != 0 calls fn_0800369c(base, [R+0x226]) and clears
@ byte [R+0x226].
@ Case bit 7 clear: OUT entry E = R+0x10c+ep*0x20. Bit 11 (0x800) set:
@ halfword [E+0x10] = slot +6 & 0x3ff; copy_from_200000bc_area(R+0x214,
@ [E+6], [E+0x10]); word 0x40005c00 &= 0xf8f; fn_0800392a(R, ep).
@ Else bit 15 (0x8000) set: register ep &= 0xf8f; byte [E+10] == 0:
@ n = slot +6 & 0x3ff, copy_from_200000bc_area(word [E+0x14], [E+6], n);
@ byte [E+10] != 0: W bit 14 set: n = slot +2, copy from [E+4]; else
@ n = slot +6, copy from [E+6]; register = (V & 0x8f8f) | 0x80c0; then
@ [E+0x10] += n, [E+0x14] += n; when [E+0xe] == 0 or maximum size [E+8] > n
@ or ep == 0 calls fn_080038b2(R, ep), else
@ fn_08003d88(R, ep, [E+0x14], [E+0xe]). Neither bit: nothing.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003f1c,"ax",%progbits
	.p2align 2
	.global fn_08003f1c
	.thumb_func
	.type fn_08003f1c, %function
fn_08003f1c:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r6, r0
	mov	r5, r1
	ldr.w	r9, [r6, #0]
	ldr.w	r8, [r9, r5, lsl #2]
	and	r0, r8, #0x80
	cmp	r0, #0
	beq.n	.L08003fb4
	add.w	r0, r6, #0xc
	add.w	r4, r0, r5, lsl #5
	ldr	r1, .L080040ec
	add.w	r0, r1, r5, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r1, #0x8f0f
	ands	r0, r1
	ldr	r2, .L080040ec
	add.w	r1, r2, r5, lsl #2
	str.w	r0, [r1, #0xc00]
	ldr	r0, .L080040f0
	ldr	r0, [r0, #0]
	add.w	r0, r0, r5, lsl #3
	.inst.n	0x1c80			@ adds r0, r0, #2
	ldr	r1, .L080040f4
	ldr	r1, [r1, #0]
	ldrh.w	r0, [r1, r0, lsl #1]
	ubfx	r0, r0, #0, #0xa
	strh	r0, [r4, #0x10]
	ldrh	r1, [r4, #0x10]
	ldr	r0, [r4, #0x14]
	add	r0, r1
	str	r0, [r4, #0x14]
	ldrh	r0, [r4, #0xe]
	cbz	r0, .L08003f7c
	cbnz	r5, .L08003f86
.L08003f7c:
	mov	r1, r5
	mov	r0, r6
	bl	fn_080037cc
	b.n	.L08003f92
.L08003f86:
	ldrh	r3, [r4, #0xe]
	mov	r1, r5
	mov	r0, r6
	ldr	r2, [r4, #0x14]
	bl	fn_08003dfc
.L08003f92:
	ldrb.w	r0, [r6, #0x224]
	cmp	r0, #2
	bne.n	.L08003fb2
	ldrb.w	r0, [r6, #0x226]
	cmp	r0, #0
	ble.n	.L08003fb2
	ldrb.w	r1, [r6, #0x226]
	ldr	r0, [r6, #0]
	bl	fn_0800369c
	movs	r0, #0
	strb.w	r0, [r6, #0x226]
.L08003fb2:
	b.n	.L080040e6
.L08003fb4:
	add.w	r0, r6, #0x10c
	add.w	r4, r0, r5, lsl #5
	and	r0, r8, #0x800
	cbz	r0, .L08004002
	ldr	r0, .L080040f0
	ldr	r0, [r0, #0]
	add.w	r0, r0, r5, lsl #3
	.inst.n	0x1d80			@ adds r0, r0, #6
	ldr	r1, .L080040f4
	ldr	r1, [r1, #0]
	ldrh.w	r0, [r1, r0, lsl #1]
	ubfx	r0, r0, #0, #0xa
	strh	r0, [r4, #0x10]
	ldrh	r2, [r4, #0x10]
	ldrh	r1, [r4, #6]
	add.w	r0, r6, #0x214
	bl	copy_from_200000bc_area
	ldr	r0, .L080040f0
	subs	r0, #0x50
	ldr	r0, [r0, #0]
	movw	r1, #0xf8f
	ands	r0, r1
	ldr	r1, .L080040f0
	subs	r1, #0x50
	str	r0, [r1, #0]
	mov	r1, r5
	mov	r0, r6
	bl	fn_0800392a
	b.n	.L080040e6
.L08004002:
	and	r0, r8, #0x8000
	cmp	r0, #0
	beq.n	.L080040e6
	ldr	r1, .L080040ec
	add.w	r0, r1, r5, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r1, #0xf8f
	ands	r0, r1
	ldr	r2, .L080040ec
	add.w	r1, r2, r5, lsl #2
	str.w	r0, [r1, #0xc00]
	ldrb	r0, [r4, #0xa]
	cbnz	r0, .L0800404a
	ldr	r0, .L080040f0
	ldr	r0, [r0, #0]
	add.w	r0, r0, r5, lsl #3
	.inst.n	0x1d80			@ adds r0, r0, #6
	ldr	r1, .L080040f4
	ldr	r1, [r1, #0]
	ldrh.w	r0, [r1, r0, lsl #1]
	ubfx	r7, r0, #0, #0xa
	ldrh	r1, [r4, #6]
	mov	r2, r7
	ldr	r0, [r4, #0x14]
	bl	copy_from_200000bc_area
	b.n	.L080040b8
.L0800404a:
	and	r0, r8, #0x4000
	cbz	r0, .L08004072
	ldr	r0, .L080040f0
	ldr	r0, [r0, #0]
	add.w	r0, r0, r5, lsl #3
	.inst.n	0x1c80			@ adds r0, r0, #2
	ldr	r1, .L080040f4
	ldr	r1, [r1, #0]
	ldrh.w	r0, [r1, r0, lsl #1]
	ubfx	r7, r0, #0, #0xa
	ldrh	r1, [r4, #4]
	mov	r2, r7
	ldr	r0, [r4, #0x14]
	bl	copy_from_200000bc_area
	b.n	.L08004092
.L08004072:
	ldr	r0, .L080040f0
	ldr	r0, [r0, #0]
	add.w	r0, r0, r5, lsl #3
	.inst.n	0x1d80			@ adds r0, r0, #6
	ldr	r1, .L080040f4
	ldr	r1, [r1, #0]
	ldrh.w	r0, [r1, r0, lsl #1]
	ubfx	r7, r0, #0, #0xa
	ldrh	r1, [r4, #6]
	mov	r2, r7
	ldr	r0, [r4, #0x14]
	bl	copy_from_200000bc_area
.L08004092:
	ldr	r1, .L080040ec
	add.w	r0, r1, r5, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r1, #0x8f8f
	ands	r0, r1
	orr	r0, r0, #0x40
	orr	r0, r0, #0x8000
	orr	r0, r0, #0x80
	ldr	r2, .L080040ec
	add.w	r1, r2, r5, lsl #2
	str.w	r0, [r1, #0xc00]
.L080040b8:
	ldrh	r0, [r4, #0x10]
	add	r0, r7
	strh	r0, [r4, #0x10]
	ldr	r0, [r4, #0x14]
	add	r0, r7
	str	r0, [r4, #0x14]
	ldrh	r0, [r4, #0xe]
	cbz	r0, .L080040d0
	ldrh	r0, [r4, #8]
	cmp	r0, r7
	bgt.n	.L080040d0
	cbnz	r5, .L080040da
.L080040d0:
	mov	r1, r5
	mov	r0, r6
	bl	fn_080038b2
	b.n	.L080040e6
.L080040da:
	ldrh	r3, [r4, #0xe]
	mov	r1, r5
	mov	r0, r6
	ldr	r2, [r4, #0x14]
	bl	fn_08003d88
.L080040e6:
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
	.short	0x0000			@ padding (never reached; aligns the literals)
.L080040ec:
	.word	0x40005000
.L080040f0:
	.word	0x40005c50
.L080040f4:
	.word	0x200000bc

@ ----------------------------------------------------------------------------
@ fn_080040f8 - request handler for request byte 8 (R = r0).
@ When halfword [R+0x212] == 1: state byte [R+0x224] == 2: byte [R+0x228] = 0,
@ fn_08003996(R, R+0x228, 1); state 3: fn_08003996(R, R+0x229, 1); other
@ state: fn_080039d6. When halfword [R+0x212] != 1: fn_080039d6.
@ Returns 0. Caller: fn_080039ec (0x080039ec, case 8).
@ ----------------------------------------------------------------------------
	.section .text.fn_080040f8,"ax",%progbits
	.global fn_080040f8
	.thumb_func
	.type fn_080040f8, %function
fn_080040f8:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r5, #0
	add.w	r6, r4, #0x20c
	ldrh	r0, [r6, #6]
	cmp	r0, #1
	beq.n	.L08004110
	mov	r0, r4
	bl	fn_080039d6
	b.n	.L0800414a
.L08004110:
	ldrb.w	r0, [r4, #0x224]
	cmp	r0, #2
	beq.n	.L0800411e
	cmp	r0, #3
	bne.n	.L08004140
	b.n	.L08004132
.L0800411e:
	movs	r0, #0
	strb.w	r0, [r4, #0x228]
	movs	r2, #1
	add.w	r1, r4, #0x228
	mov	r0, r4
	bl	fn_08003996
	b.n	.L08004148
.L08004132:
	movs	r2, #1
	addw	r1, r4, #0x229
	mov	r0, r4
	bl	fn_08003996
	b.n	.L08004148
.L08004140:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L08004148:
	nop
.L0800414a:
	mov	r0, r5
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_0800414e - request handler for request byte 6 (R = r0).
@ v = halfword [R+0x20e], high byte h = v >> 8. Descriptor getters are fetched
@ from the table at [R+8] and called with no argument set up; each returns a
@ pointer P.
@ h == 1: [[R+8]+0]; h == 2: [[R+8]+8]; h == 3: by low byte of v: 0 -> +0x10,
@ 1 -> +0x14, 2 -> +0x18, 3 -> +0x1c, 4 -> +0x24, 5 -> +0x20, others call
@ [[R+4]+8](R, R+0x20c) and return 0; h == 6: fn_080039d6; h == 7 or any
@ other h: fn_080039d6 and return 0.
@ Afterwards when P != 0, halfword [P] != 0 and halfword [R+0x212] != 0:
@ fn_08003996(R, word [P+4], min(halfword [P], halfword [R+0x212])).
@ Returns 0. Caller: fn_080039ec (0x080039ec, case 6).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800414e,"ax",%progbits
	.global fn_0800414e
	.thumb_func
	.type fn_0800414e, %function
fn_0800414e:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r4, r0
	mov.w	r8, #0
	mov	r9, r8
	movs	r5, #0
	movw	r0, #0x20e
	ldrh	r0, [r0, r4]
	asrs	r6, r0, #8
	cmp	r6, #8
	bcs.n	.L08004200
	tbb	[pc, r6]
.L0800416c:
	.byte	(.L08004200 - .L0800416c)/2
	.byte	(.L08004174 - .L0800416c)/2
	.byte	(.L0800417e - .L0800416c)/2
	.byte	(.L08004188 - .L0800416c)/2
	.byte	(.L08004200 - .L0800416c)/2
	.byte	(.L08004200 - .L0800416c)/2
	.byte	(.L080041ee - .L0800416c)/2
	.byte	(.L080041f6 - .L0800416c)/2
.L08004174:
	ldr	r1, [r4, #8]
	ldr	r0, [r1, #0]
	blx	r0
	mov	r5, r0
	b.n	.L0800420a
.L0800417e:
	ldr	r1, [r4, #8]
	ldr	r0, [r1, #8]
	blx	r0
	mov	r5, r0
	b.n	.L0800420a
.L08004188:
	movw	r0, #0x20e
	ldrb	r7, [r0, r4]
	cmp	r7, #6
	bcs.n	.L080041d8
	tbb	[pc, r7]
.L08004196:
	.byte	(.L0800419c - .L08004196)/2
	.byte	(.L080041a6 - .L08004196)/2
	.byte	(.L080041b0 - .L08004196)/2
	.byte	(.L080041ba - .L08004196)/2
	.byte	(.L080041c4 - .L08004196)/2
	.byte	(.L080041ce - .L08004196)/2
.L0800419c:
	ldr	r1, [r4, #8]
	ldr	r0, [r1, #0x10]
	blx	r0
	mov	r5, r0
	b.n	.L080041ea
.L080041a6:
	ldr	r1, [r4, #8]
	ldr	r0, [r1, #0x14]
	blx	r0
	mov	r5, r0
	b.n	.L080041ea
.L080041b0:
	ldr	r1, [r4, #8]
	ldr	r0, [r1, #0x18]
	blx	r0
	mov	r5, r0
	b.n	.L080041ea
.L080041ba:
	ldr	r1, [r4, #8]
	ldr	r0, [r1, #0x1c]
	blx	r0
	mov	r5, r0
	b.n	.L080041ea
.L080041c4:
	ldr	r1, [r4, #8]
	ldr	r0, [r1, #0x24]
	blx	r0
	mov	r5, r0
	b.n	.L080041ea
.L080041ce:
	ldr	r1, [r4, #8]
	ldr	r0, [r1, #0x20]
	blx	r0
	mov	r5, r0
	b.n	.L080041ea
.L080041d8:
	ldr	r0, [r4, #4]
	add.w	r1, r4, #0x20c
	ldr	r2, [r0, #8]
	mov	r0, r4
	blx	r2
	mov	r0, r8
.L080041e6:
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
.L080041ea:
	nop
	b.n	.L0800420a
.L080041ee:
	mov	r0, r4
	bl	fn_080039d6
	b.n	.L0800420a
.L080041f6:
	mov	r0, r4
	bl	fn_080039d6
	mov	r0, r8
	b.n	.L080041e6
.L08004200:
	mov	r0, r4
	bl	fn_080039d6
	mov	r0, r8
	b.n	.L080041e6
.L0800420a:
	nop
	cbz	r5, .L0800423c
	ldrh	r0, [r5, #0]
	cbz	r0, .L0800423c
	movw	r0, #0x212
	ldrh	r0, [r0, r4]
	cbz	r0, .L0800423c
	ldrh	r1, [r5, #0]
	movw	r0, #0x212
	ldrh	r0, [r0, r4]
	cmp	r1, r0
	bge.n	.L0800422a
	ldrh	r0, [r5, #0]
	b.n	.L08004230
.L0800422a:
	movw	r0, #0x212
	ldrh	r0, [r0, r4]
.L08004230:
	mov	r9, r0
	mov	r2, r9
	mov	r0, r4
	ldr	r1, [r5, #4]
	bl	fn_08003996
.L0800423c:
	mov	r0, r8
	b.n	.L080041e6

@ ----------------------------------------------------------------------------
@ out_endpoint_length_done - returns the length-done field of an OUT entry.
@ Parameters: r0 = R, r1 = code. Returns halfword
@ [R + 0x10c + (r1 & 0x7f) * 0x20 + 0x10].
@ Name follows the field set by fn_08003f1c.
@ ----------------------------------------------------------------------------
	.section .text.out_endpoint_length_done,"ax",%progbits
	.p2align 2
	.global out_endpoint_length_done
	.thumb_func
	.type out_endpoint_length_done, %function
out_endpoint_length_done:
	push	{r4, lr}
	mov	r2, r0
	and	r4, r1, #0x7f
	add.w	r0, r2, #0x10c
	add.w	r3, r0, r4, lsl #5
	ldrh	r0, [r3, #0x10]
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08004254 - request handler for request byte 0 (R = r0).
@ State byte [R+0x224] == 2 or 3: when byte [R+0x227] != 0 halfword
@ [R+0x22a] |= 2; fn_08003996(R, R+0x22a, 2). Other state: fn_080039d6.
@ Returns 0. Caller: fn_080039ec (0x080039ec, case 0).
@ ----------------------------------------------------------------------------
	.section .text.fn_08004254,"ax",%progbits
	.p2align 2
	.global fn_08004254
	.thumb_func
	.type fn_08004254, %function
fn_08004254:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r5, #0
	ldrb.w	r0, [r4, #0x224]
	cmp	r0, #2
	beq.n	.L08004268
	cmp	r0, #3
	bne.n	.L0800428a
	b.n	.L0800426a
.L08004268:
	nop
.L0800426a:
	ldrb.w	r0, [r4, #0x227]
	cbz	r0, .L0800427c
	ldrh.w	r0, [r4, #0x22a]
	orr	r0, r0, #2
	strh.w	r0, [r4, #0x22a]
.L0800427c:
	movs	r2, #2
	addw	r1, r4, #0x22a
	mov	r0, r4
	bl	fn_08003996
	b.n	.L08004292
.L0800428a:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L08004292:
	nop
	mov	r0, r5
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_080042d6 - request handler for byte [R+0x20c] & 0x1f == 1 (R = r0).
@ State byte [R+0x224] == 3: calls [[R+4]+8](R, R+0x20c); when halfword
@ [R+0x212] == 0 calls fn_080039be(R). Other state: fn_080039d6.
@ Returns 0. Caller: fn_0800392a (0x0800392a).
@ ----------------------------------------------------------------------------
	.section .text.fn_080042d6,"ax",%progbits
	.global fn_080042d6
	.thumb_func
	.type fn_080042d6, %function
fn_080042d6:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r5, #0
	add.w	r6, r4, #0x20c
	ldrb.w	r0, [r4, #0x224]
	cmp	r0, #3
	bne.n	.L08004300
	ldr	r0, [r4, #4]
	add.w	r1, r4, #0x20c
	ldr	r2, [r0, #8]
	mov	r0, r4
	blx	r2
	ldrh	r0, [r6, #6]
	cbnz	r0, .L080042fe
	mov	r0, r4
	bl	fn_080039be
.L080042fe:
	b.n	.L08004308
.L08004300:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L08004308:
	nop
	mov	r0, r5
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_0800430e - USB event dispatcher.
@ Parameter: r0 = R, base = word [R]; F = word [base+0x44] (flags),
@ M = word [base+0x40] (mask). No return value.
@ F bit 15: fn_08003d08(R). F bit 10 (0x400): fn_08003632(base, 0x400) then
@ fn_080043aa(R). F bit 9 and M bit 9: fn_08003632(base, 0x200) then
@ fn_080045e8(R). F bit 8 and M bit 8: fn_08003632(base, 0x100) only.
@ F bit 11 and M bit 11: fn_08003632(base, 0x800) then fn_080045fc(R).
@ F bit 12 and M bit 12: fn_08004662(R) then fn_08003632(base, 0x1000).
@ Purpose not determined from the code beyond the bit tests.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800430e,"ax",%progbits
	.global fn_0800430e
	.thumb_func
	.type fn_0800430e, %function
fn_0800430e:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r7, r0
	ldr	r6, [r7, #0]
	ldr	r4, [r6, #0x44]
	ldr	r5, [r6, #0x40]
	and	r0, r4, #0x8000
	cbz	r0, .L08004326
	mov	r0, r7
	bl	fn_08003d08
.L08004326:
	and	r0, r4, #0x400
	cbz	r0, .L0800433c
	mov.w	r1, #0x400
	mov	r0, r6
	bl	fn_08003632
	mov	r0, r7
	bl	fn_080043aa
.L0800433c:
	and	r0, r4, #0x200
	cbz	r0, .L08004358
	and	r0, r5, #0x200
	cbz	r0, .L08004358
	mov.w	r1, #0x200
	mov	r0, r6
	bl	fn_08003632
	mov	r0, r7
	bl	fn_080045e8
.L08004358:
	and	r0, r4, #0x100
	cbz	r0, .L0800436e
	and	r0, r5, #0x100
	cbz	r0, .L0800436e
	mov.w	r1, #0x100
	mov	r0, r6
	bl	fn_08003632
.L0800436e:
	and	r0, r4, #0x800
	cbz	r0, .L0800438a
	and	r0, r5, #0x800
	cbz	r0, .L0800438a
	mov.w	r1, #0x800
	mov	r0, r6
	bl	fn_08003632
	mov	r0, r7
	bl	fn_080045fc
.L0800438a:
	and	r0, r4, #0x1000
	cbz	r0, .L080043a6
	and	r0, r5, #0x1000
	cbz	r0, .L080043a6
	mov	r0, r7
	bl	fn_08004662
	mov.w	r1, #0x1000
	mov	r0, r6
	bl	fn_08003632
.L080043a6:
	pop.w	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_080043aa - bus-reset handling.
@ Parameter: r0 = R. No return value. Caller: fn_0800430e (flag 0x400).
@ Calls halfword_200000c0_reset(), init_endpoint_entries(R),
@ fn_08003d2e(R, 0, 0, 0x40), fn_08003d2e(R, 0x80, 0, 0x40),
@ fn_0800369c(word [R], 0); byte [R+0x224] = 1; when word [[R+4]+0x20] != 0
@ calls it with (R, 1).
@ ----------------------------------------------------------------------------
	.section .text.fn_080043aa,"ax",%progbits
	.global fn_080043aa
	.thumb_func
	.type fn_080043aa, %function
fn_080043aa:
	push	{r4, lr}
	mov	r4, r0
	bl	halfword_200000c0_reset
	mov	r0, r4
	bl	init_endpoint_entries
	movs	r3, #0x40
	movs	r2, #0
	mov	r1, r2
	mov	r0, r4
	bl	fn_08003d2e
	movs	r3, #0x40
	movs	r2, #0
	movs	r1, #0x80
	mov	r0, r4
	bl	fn_08003d2e
	movs	r1, #0
	ldr	r0, [r4, #0]
	bl	fn_0800369c
	movs	r0, #1
	strb.w	r0, [r4, #0x224]
	ldr	r0, [r4, #4]
	ldr	r0, [r0, #0x20]
	cbz	r0, .L080043ee
	ldr	r0, [r4, #4]
	movs	r1, #1
	ldr	r2, [r0, #0x20]
	mov	r0, r4
	blx	r2
.L080043ee:
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_080043f0 - request handler for request byte 5 (R = r0).
@ When halfword [R+0x210] == 0 and halfword [R+0x212] == 0: state byte
@ [R+0x224] == 3: fn_080039d6; else byte [R+0x226] = byte [R+0x20e] & 0x7f,
@ byte [R+0x224] = 1 when that value is 0 else 2, then fn_080039be(R).
@ Otherwise fn_080039d6. Returns 0.
@ The stored value is later passed to fn_0800369c(base, [R+0x226]) by
@ fn_08003f1c (IN completion with byte [R+0x224] == 2).
@ Caller: fn_080039ec (0x080039ec, case 5).
@ ----------------------------------------------------------------------------
	.section .text.fn_080043f0,"ax",%progbits
	.p2align 2
	.global fn_080043f0
	.thumb_func
	.type fn_080043f0, %function
fn_080043f0:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r4, r0
	movs	r7, #0
	add.w	r5, r4, #0x20c
	ldrh	r0, [r5, #4]
	cbnz	r0, .L08004436
	ldrh	r0, [r5, #6]
	cbnz	r0, .L08004436
	ldrb	r0, [r5, #2]
	and	r6, r0, #0x7f
	ldrb.w	r0, [r4, #0x224]
	cmp	r0, #3
	bne.n	.L0800441a
	mov	r0, r4
	bl	fn_080039d6
	b.n	.L0800443c
.L0800441a:
	strb.w	r6, [r4, #0x226]
	cbz	r6, .L08004428
	movs	r0, #2
	strb.w	r0, [r4, #0x224]
	b.n	.L0800442e
.L08004428:
	movs	r0, #1
	strb.w	r0, [r4, #0x224]
.L0800442e:
	mov	r0, r4
	bl	fn_080039be
	b.n	.L0800443c
.L08004436:
	mov	r0, r4
	bl	fn_080039d6
.L0800443c:
	mov	r0, r7
	pop.w	{r4, r5, r6, r7, r8, pc}
	.short	0x0000			@ padding (never reached; aligns fn_08004444)

@ ----------------------------------------------------------------------------
@ fn_08004444 - request handler for request byte 9 (R = r0).
@ Byte 0x200000c8 = byte [R+0x20e]. When halfword [R+0x210] == 0 and halfword
@ [R+0x212] == 0: state [R+0x224] == 2: value 0 gives fn_080039be(R); else
@ byte [R+0x229] = value, byte [R+0x224] = 3, [[R+4]+0](R), fn_080039be(R).
@ State 3: value 0: byte [R+0x224] = 2, byte [R+0x229] = 0, [[R+4]+4](R),
@ fn_080039be(R); value == byte [R+0x229]: [[R+4]+4](R), byte [R+0x229] =
@ value, [[R+4]+0](R), fn_080039be(R); other value: fn_080039be(R).
@ Other state: fn_080039d6. Other lengths: fn_080039d6. Returns 0.
@ Caller: fn_080039ec (0x080039ec, case 9).
@ ----------------------------------------------------------------------------
	.section .text.fn_08004444,"ax",%progbits
	.p2align 2
	.global fn_08004444
	.thumb_func
	.type fn_08004444, %function
fn_08004444:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r6, #0
	add.w	r5, r4, #0x20c
	ldrb	r0, [r5, #2]
	ldr	r1, .L08004508
	strb	r0, [r1, #0]
	ldrh	r0, [r5, #4]
	cmp	r0, #0
	bne.n	.L080044fc
	ldrh	r0, [r5, #6]
	cmp	r0, #0
	bne.n	.L080044fc
	ldrb.w	r0, [r4, #0x224]
	cmp	r0, #2
	beq.n	.L0800446e
	cmp	r0, #3
	bne.n	.L080044f2
	b.n	.L0800449a
.L0800446e:
	ldr	r0, .L08004508
	ldrb	r0, [r0, #0]
	cbz	r0, .L08004492
	ldr	r0, .L08004508
	ldrb	r0, [r0, #0]
	strb.w	r0, [r4, #0x229]
	movs	r0, #3
	strb.w	r0, [r4, #0x224]
	ldr	r0, [r4, #4]
	ldr	r1, [r0, #0]
	mov	r0, r4
	blx	r1
	mov	r0, r4
	bl	fn_080039be
	b.n	.L08004498
.L08004492:
	mov	r0, r4
	bl	fn_080039be
.L08004498:
	b.n	.L080044fa
.L0800449a:
	ldr	r0, .L08004508
	ldrb	r0, [r0, #0]
	cbnz	r0, .L080044be
	movs	r0, #2
	strb.w	r0, [r4, #0x224]
	ldr	r0, .L08004508
	ldrb	r0, [r0, #0]
	strb.w	r0, [r4, #0x229]
	ldr	r0, [r4, #4]
	ldr	r1, [r0, #4]
	mov	r0, r4
	blx	r1
	mov	r0, r4
	bl	fn_080039be
	b.n	.L080044f0
.L080044be:
	ldrb.w	r0, [r4, #0x229]
	ldr	r1, .L08004508
	ldrb	r1, [r1, #0]
	cmp	r0, r1
	bne.n	.L080044ea
	ldr	r0, [r4, #4]
	ldr	r1, [r0, #4]
	mov	r0, r4
	blx	r1
	ldr	r0, .L08004508
	ldrb	r0, [r0, #0]
	strb.w	r0, [r4, #0x229]
	ldr	r0, [r4, #4]
	ldr	r1, [r0, #0]
	mov	r0, r4
	blx	r1
	mov	r0, r4
	bl	fn_080039be
	b.n	.L080044f0
.L080044ea:
	mov	r0, r4
	bl	fn_080039be
.L080044f0:
	b.n	.L080044fa
.L080044f2:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L080044fa:
	b.n	.L08004502
.L080044fc:
	mov	r0, r4
	bl	fn_080039d6
.L08004502:
	mov	r0, r6
	pop	{r4, r5, r6, pc}
	.short	0x0000			@ padding (never reached; aligns the literal)
.L08004508:
	.word	0x200000c8

@ ----------------------------------------------------------------------------
@ fn_0800450c - request handler for request byte 3 (R = r0).
@ When halfword [R+0x20e] == 1: byte [R+0x227] = 1, [[R+4]+8](R, R+0x20c),
@ fn_080039be(R). Otherwise does nothing. Returns 0.
@ Caller: fn_080039ec (0x080039ec, case 3).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800450c,"ax",%progbits
	.p2align 2
	.global fn_0800450c
	.thumb_func
	.type fn_0800450c, %function
fn_0800450c:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r5, #0
	add.w	r6, r4, #0x20c
	ldrh	r0, [r6, #2]
	cmp	r0, #1
	bne.n	.L08004532
	strb.w	r0, [r4, #0x227]
	ldr	r0, [r4, #4]
	add.w	r1, r4, #0x20c
	ldr	r2, [r0, #8]
	mov	r0, r4
	blx	r2
	mov	r0, r4
	bl	fn_080039be
.L08004532:
	mov	r0, r5
	pop	{r4, r5, r6, pc}
	.short	0x0000			@ padding (never reached; aligns fn_08004538)

@ ----------------------------------------------------------------------------
@ fn_08004538 - sets a stall state on an endpoint.
@ Parameters: r0 = R, r1 = code. No return value.
@ Bit 7 set: E = R+0xc+(r1&0x7f)*0x20, register word 0x40005000 + 0xc00 +
@ byte [E] * 4 = ((V & 0x8fbf) ^ 0x10) | 0x8080; bit 7 clear:
@ E = R+0x10c+(r1&0x7f)*0x20, register = ((V & 0xbf8f) ^ 0x1000) | 0x8080.
@ Both: byte [E+0xb] = 1.
@ Callers: 0x080039d6, 0x08003a78, 0x08000bf0, 0x08001190.
@ ----------------------------------------------------------------------------
	.section .text.fn_08004538,"ax",%progbits
	.p2align 2
	.global fn_08004538
	.thumb_func
	.type fn_08004538, %function
fn_08004538:
	push	{r4, r5, r6, lr}
	mov	r2, r0
	and	r3, r1, #0x80
	cbz	r3, .L0800457c
	and	r4, r1, #0x7f
	add.w	r3, r2, #0xc
	add.w	r0, r3, r4, lsl #5
	ldrb	r4, [r0, #0]
	ldr	r5, .L080045bc
	add.w	r4, r5, r4, lsl #2
	ldr.w	r4, [r4, #0xc00]
	movw	r5, #0x8fbf
	and.w	r3, r4, r5
	eor	r3, r3, #0x10
	orr	r4, r3, #0x8000
	orr	r4, r4, #0x80
	ldrb	r5, [r0, #0]
	ldr	r6, .L080045bc
	add.w	r5, r6, r5, lsl #2
	str.w	r4, [r5, #0xc00]
	b.n	.L080045b6
.L0800457c:
	and	r4, r1, #0x7f
	add.w	r3, r2, #0x10c
	add.w	r0, r3, r4, lsl #5
	ldrb	r4, [r0, #0]
	ldr	r5, .L080045bc
	add.w	r4, r5, r4, lsl #2
	ldr.w	r4, [r4, #0xc00]
	movw	r5, #0xbf8f
	and.w	r3, r4, r5
	eor	r3, r3, #0x1000
	orr	r4, r3, #0x8000
	orr	r4, r4, #0x80
	ldrb	r5, [r0, #0]
	ldr	r6, .L080045bc
	add.w	r5, r6, r5, lsl #2
	str.w	r4, [r5, #0xc00]
	nop
.L080045b6:
	movs	r3, #1
	strb	r3, [r0, #0xb]
	pop	{r4, r5, r6, pc}
.L080045bc:
	.word	0x40005000

@ ----------------------------------------------------------------------------
@ fn_080045e8 - calls the class callback at [[R+4]+0x1c] when present.
@ Parameter: r0 = R. When word [[R+4]+0x1c] is not 0 calls it with R.
@ No return value. Caller: fn_0800430e (flag 0x200).
@ ----------------------------------------------------------------------------
	.section .text.fn_080045e8,"ax",%progbits
	.p2align 2
	.global fn_080045e8
	.thumb_func
	.type fn_080045e8, %function
fn_080045e8:
	push	{r4, lr}
	mov	r4, r0
	ldr	r0, [r4, #4]
	ldr	r0, [r0, #0x1c]
	cbz	r0, .L080045fa
	ldr	r0, [r4, #4]
	ldr	r1, [r0, #0x1c]
	mov	r0, r4
	blx	r1
.L080045fa:
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_080045fc - enters state 4 (suspend handling).
@ Parameter: r0 = R. Byte [R+0x225] = byte [R+0x224], byte [R+0x224] = 4,
@ calls fn_08003bc4(R); when word [[R+4]+0x20] is not 0 calls it with (R, 2).
@ No return value. Caller: fn_0800430e (flag 0x800).
@ ----------------------------------------------------------------------------
	.section .text.fn_080045fc,"ax",%progbits
	.global fn_080045fc
	.thumb_func
	.type fn_080045fc, %function
fn_080045fc:
	push	{r4, lr}
	mov	r4, r0
	ldrb.w	r0, [r4, #0x224]
	strb.w	r0, [r4, #0x225]
	movs	r0, #4
	strb.w	r0, [r4, #0x224]
	mov	r0, r4
	bl	fn_08003bc4
	ldr	r0, [r4, #4]
	ldr	r0, [r0, #0x20]
	cbz	r0, .L08004624
	ldr	r0, [r4, #4]
	movs	r1, #2
	ldr	r2, [r0, #0x20]
	mov	r0, r4
	blx	r2
.L08004624:
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ ascii_to_length_prefixed_halfword_string - builds a length-prefixed string.
@ Parameters: r0 = zero-terminated byte string, r1 = destination.
@ For each source byte c at index i: [r1 + 2 + 2*i] = c, [r1 + 3 + 2*i] = 0
@ (16-bit counters). Then byte [r1] = the low 8 bits of 2 * count + 2 (count
@ is the 16-bit number of source bytes, uxth at 0x08004658, stored with strb
@ at 0x0800465a) and byte [r1+1] = 3. No return value.
@ ----------------------------------------------------------------------------
	.section .text.ascii_to_length_prefixed_halfword_string,"ax",%progbits
	.global ascii_to_length_prefixed_halfword_string
	.thumb_func
	.type ascii_to_length_prefixed_halfword_string, %function
ascii_to_length_prefixed_halfword_string:
	push	{r4, r5, r6, r7, lr}
	mov	r3, r0
	movs	r0, #0
	movs	r4, #2
	mov	r2, r3
	b.n	.L0800464c
.L08004632:
	adds	r5, r0, #1
	uxth	r0, r5
	ldrb.w	r7, [r2], #1
	mov	r5, r4
	adds	r6, r4, #1
	uxth	r4, r6
	strb	r7, [r1, r5]
	movs	r7, #0
	mov	r5, r4
	adds	r6, r4, #1
	uxth	r4, r6
	strb	r7, [r1, r5]
.L0800464c:
	ldrb	r5, [r2, #0]
	cmp	r5, #0
	bne.n	.L08004632
	movs	r5, #2
	add.w	r5, r5, r0, lsl #1
	uxth	r0, r5
	strb	r0, [r1, #0]
	movs	r5, #3
	strb	r5, [r1, #1]
	pop	{r4, r5, r6, r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08004662 - leaves state 4 (resume handling).
@ Parameter: r0 = R. Calls fn_08003620(word [R]); byte [R+0x224] =
@ byte [R+0x225]; when word [[R+4]+0x20] is not 0 calls it with (R, 3).
@ No return value. Caller: fn_0800430e (flag 0x1000).
@ ----------------------------------------------------------------------------
	.section .text.fn_08004662,"ax",%progbits
	.global fn_08004662
	.thumb_func
	.type fn_08004662, %function
fn_08004662:
	push	{r4, lr}
	mov	r4, r0
	ldr	r0, [r4, #0]
	bl	fn_08003620
	ldrb.w	r0, [r4, #0x225]
	strb.w	r0, [r4, #0x224]
	ldr	r0, [r4, #4]
	ldr	r0, [r0, #0x20]
	cbz	r0, .L08004684
	ldr	r0, [r4, #4]
	movs	r1, #3
	ldr	r2, [r0, #0x20]
	mov	r0, r4
	blx	r2
.L08004684:
	pop	{r4, pc}
	.short	0x0000			@ padding (never reached; aligns set_byte0_clear_byte1_a0000220)

@ ----------------------------------------------------------------------------
@ set_byte0_clear_byte1_a0000220 - writes bits 7..0 of a table word, clears bits 15..8.
@ Parameters: r0 = index, r1 = value, r2 unused in the result.
@ Word at 0xa0000220 + index * 4 has bits 15..8 cleared (the bit-field insert
@ of r2 << 8 inserts 0), then bits 7..0 = r1 & 0xff. No return value.
@ Caller: 0x08004828 with (0, 8, 8).
@ ----------------------------------------------------------------------------
	.section .text.set_byte0_clear_byte1_a0000220,"ax",%progbits
	.p2align 2
	.global set_byte0_clear_byte1_a0000220
	.thumb_func
	.type set_byte0_clear_byte1_a0000220, %function
set_byte0_clear_byte1_a0000220:
	push	{r4, lr}
	lsls	r4, r2, #8
	ldr	r3, .L080046ac
	ldr.w	r3, [r3, r0, lsl #2]
	bfi	r3, r4, #8, #8
	ldr	r4, .L080046ac
	str.w	r3, [r4, r0, lsl #2]
	mov	r3, r4
	ldr.w	r4, [r3, r0, lsl #2]
	bfi	r4, r1, #0, #8
	str.w	r4, [r3, r0, lsl #2]
	pop	{r4, pc}
.L080046ac:
	.word	0xa0000220
