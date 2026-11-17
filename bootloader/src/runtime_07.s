@ runtime_07.s - byte compare / copy / fill helpers, hex digit writer and 8-byte copy of the bootloader runtime.
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ compare_bytes - compares two byte buffers.
@ r0 = a, r1 = b, r2 = n. Returns 0 if the first n bytes of a and b are equal,
@ else 1 at the first difference.
@ Callers 0x08001F0A, 0x08001F18, 0x0800201E.
@ ----------------------------------------------------------------------------
	.section .text.compare_bytes,"ax",%progbits
	.p2align 2
	.global compare_bytes
	.thumb_func
	.type compare_bytes, %function
compare_bytes:
	push	{r4, r5, lr}
	mov	r3, r0
	mov	r4, r1
	movs	r1, #0
	b.n	.L08001978
.L0800196a:
	ldrb	r0, [r3, r1]
	ldrb	r5, [r4, r1]
	cmp	r0, r5
	beq.n	.L08001976
	movs	r0, #1
.L08001974:
	pop	{r4, r5, pc}
.L08001976:
	.inst.n 0x1c49	@ adds r1, r1, #1
.L08001978:
	cmp	r1, r2
	bcc.n	.L0800196a
	movs	r0, #0
	b.n	.L08001974

@ ----------------------------------------------------------------------------
@ copy_bytes - forward byte copy.
@ r0 = destination, r1 = source, r2 = n. Copies n bytes forward one at a time;
@ returns n in r0 (Ghidra shows void; callers 0x08001E4A, 0x08001E74,
@ 0x08001E8E and 0x08001E9A use the value: each is followed by add r4, r0).
@ Other caller 0x08001C5A does not use it.
@ ----------------------------------------------------------------------------
	.section .text.copy_bytes,"ax",%progbits
	.p2align 2
	.global copy_bytes
	.thumb_func
	.type copy_bytes, %function
copy_bytes:
	push	{r4, lr}
	mov	r3, r0
	movs	r0, #0
	b.n	.L0800198e
.L08001988:
	ldrb	r4, [r1, r0]
	strb	r4, [r3, r0]
	.inst.n 0x1c40	@ adds r0, r0, #1
.L0800198e:
	cmp	r0, r2
	bcc.n	.L08001988
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fill_bytes - stores one byte value n times.
@ r0 = destination, r1 = byte value, r2 = n. Returns n in r0 (Ghidra shows
@ void); no caller uses the value (callers 0x08001CA2, 0x08001E5A, 0x08001E82,
@ 0x08001EA8, 0x08001EB8).
@ ----------------------------------------------------------------------------
	.section .text.fill_bytes,"ax",%progbits
	.p2align 2
	.global fill_bytes
	.thumb_func
	.type fill_bytes, %function
fill_bytes:
	push	{r4, lr}
	mov	r3, r0
	movs	r0, #0
	b.n	.L080019a0
.L0800199c:
	strb	r1, [r3, r0]
	.inst.n 0x1c40	@ adds r0, r0, #1
.L080019a0:
	cmp	r0, r2
	bcc.n	.L0800199c
	pop	{r4, pc}
	.short	0x0000	@ padding: never reached, aligns the next function to 2 bytes

@ ----------------------------------------------------------------------------
@ hex_digit_pairs - writes hex digits, each followed by a zero byte.
@ r0 = value, r1 = destination, r2 = digit count (signed compare, byte
@ counter). For i in 0..r2-1: nibble n = top nibble of the value; byte
@ [r1 + 2*i] = n + 0x30 when n < 10, else n + 0x37; byte [r1 + 2*i + 1] = 0;
@ value <<= 4. No return value.
@ ----------------------------------------------------------------------------
	.section .text.hex_digit_pairs,"ax",%progbits
	.global hex_digit_pairs
	.thumb_func
	.type hex_digit_pairs, %function
hex_digit_pairs:
	push	{r4, r5, lr}
	mov	r3, r1
	movs	r1, #0
	nop
	b.n	.L080042d0
.L080042a2:
	movs	r4, #0xa
	cmp.w	r4, r0, lsr #28
	bls.n	.L080042b6
	movs	r4, #0x30
	add.w	r4, r4, r0, lsr #28
	strb.w	r4, [r3, r1, lsl #1]
	b.n	.L080042c2
.L080042b6:
	movs	r4, #0x41
	add.w	r4, r4, r0, lsr #28
	subs	r4, #0xa
	strb.w	r4, [r3, r1, lsl #1]
.L080042c2:
	lsls	r0, r0, #4
	movs	r5, #0
	lsls	r4, r1, #1
	.inst.n 0x1c64	@ adds r4, r4, #1
	strb	r5, [r3, r4]
	adds	r4, r1, #1
	uxtb	r1, r4
.L080042d0:
	cmp	r1, r2
	blt.n	.L080042a2
	pop	{r4, r5, pc}

@ ----------------------------------------------------------------------------
@ copy_8_bytes - copies 8 bytes from r1 to r0.
@ Copies byte [0], byte [1], then halfwords [2], [4], [6] (each halfword built
@ from two source bytes, low byte first). No return value.
@ Caller: 0x0800392a (destination R+0x20c, source R+0x214).
@ ----------------------------------------------------------------------------
	.section .text.copy_8_bytes,"ax",%progbits
	.p2align 2
	.global copy_8_bytes
	.thumb_func
	.type copy_8_bytes, %function
copy_8_bytes:
	ldrb	r2, [r1, #0]
	strb	r2, [r0, #0]
	ldrb	r2, [r1, #1]
	strb	r2, [r0, #1]
	ldrb	r3, [r1, #2]
	ldrb	r2, [r1, #3]
	add.w	r2, r3, r2, lsl #8
	strh	r2, [r0, #2]
	ldrb	r3, [r1, #4]
	ldrb	r2, [r1, #5]
	add.w	r2, r3, r2, lsl #8
	strh	r2, [r0, #4]
	ldrb	r3, [r1, #6]
	ldrb	r2, [r1, #7]
	add.w	r2, r3, r2, lsl #8
	strh	r2, [r0, #6]
	bx	lr
