@ usb_83.s - four routines working on the 0x20-byte record tables at 0x20002b24 and the
@ register / buffer arrays at 0x40005c00 and 0x40006000 (fn_08040874, fn_08040990, fn_08040b24, fn_08040eb4).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08040874 - read-modify-write sequence on one word of the register array at 0x40005c00.
@ Params: r0 = base of the 0x20-byte entry table, r1 = index.
@ Entry E = base + (r1 & 0x7f) * 0x20 + 0xc when bit7 of r1 is set,
@           base + (r1 & 0x7f) * 0x20 + 0x10c when bit7 is clear.
@ W = word 0x40005c00[E[0]] (word array, address 0x40005c00 + E[0] * 4).
@ If E[10] == 0:
@   if E[2] == 1: if bit6 of W is set W = (W & 0xf0f) | 0x80c0;
@                 then W = (W & 0xf3f) | 0x8080
@   else:         if bit14 of W is set W = (W & 0xf0f) | 0xc080;
@                 then W = (W & 0x3f0f) | 0x8080
@ If E[10] != 0:
@   if bit6 set W = (W & 0xf0f) | 0x80c0; if bit14 set W = (W & 0xf0f) | 0xc080;
@   W = (W & 0xf0f) | (E[2] == 1 ? 0x80c0 : 0xc080);
@   W = (W & 0xf3f) | 0x8080; W = (W & 0x3f0f) | 0x8080.
@ No return value. The meaning of the fields is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08040874,"ax",%progbits
	.p2align 2
	.global fn_08040874
	.thumb_func
	.type fn_08040874, %function
fn_08040874:
	push	{r7, lr}
	and	r2, r1, #0x7f
	add.w	r0, r0, r2, lsl #5
	add.w	r2, r0, #0xc
	lsls	r1, r1, #0x18
	it	pl
	addpl.w	r2, r0, #0x10c
	ldrb	r0, [r2, #0xa]
	movw	lr, #0x5c00
	cmp	r0, #0
	movt	lr, #0x4000
	beq.n	.L0804092c
	ldrb	r1, [r2, #0]
	ldr.w	r3, [lr, r1, lsl #2]
	lsls	r3, r3, #0x19
	bpl.n	.L080408bc
	ldr.w	r12, [lr, r1, lsl #2]
	movw	r3, #0xf0f
	and.w	r12, r12, r3
	movw	r3, #0x80c0
	orr.w	r3, r3, r12
	str.w	r3, [lr, r1, lsl #2]
	ldrb	r1, [r2, #0]
.L080408bc:
	ldr.w	r3, [lr, r1, lsl #2]
	lsls	r3, r3, #0x11
	bpl.n	.L080408de
	ldr.w	r12, [lr, r1, lsl #2]
	movw	r3, #0xf0f
	and.w	r12, r12, r3
	movw	r3, #0xc080
	orr.w	r3, r3, r12
	str.w	r3, [lr, r1, lsl #2]
	ldrb	r1, [r2, #0]
.L080408de:
	ldrb	r3, [r2, #2]
	ldr.w	r0, [lr, r1, lsl #2]
	movw	r12, #0xf0f
	cmp	r3, #1
	and.w	r3, r0, r12
	ite	ne
	movwne	r0, #0xc080
	movweq	r0, #0x80c0
	orrs	r0, r3
	str.w	r0, [lr, r1, lsl #2]
	ldrb	r0, [r2, #0]
	movw	r3, #0xf3f
	ldr.w	r1, [lr, r0, lsl #2]
	ands	r1, r3
	movw	r3, #0x8080
	orrs	r1, r3
	str.w	r1, [lr, r0, lsl #2]
	ldrb	r1, [r2, #0]
	movw	r2, #0x3f0f
.L0804091a:
	ldr.w	r0, [lr, r1, lsl #2]
	ands	r0, r2
	movw	r2, #0x8080
	orrs	r0, r2
	str.w	r0, [lr, r1, lsl #2]
	pop	{r7, pc}
.L0804092c:
	ldrb	r1, [r2, #0]
	ldrb	r3, [r2, #2]
	ldr.w	r12, [lr, r1, lsl #2]
	cmp	r3, #1
	bne.n	.L08040944
	lsls.w	r3, r12, #0x19
	bmi.n	.L08040950
	movw	r2, #0xf3f
	b.n	.L0804091a
.L08040944:
	lsls.w	r3, r12, #0x11
	bmi.n	.L08040970
	movw	r2, #0x3f0f
	b.n	.L0804091a
.L08040950:
	ldr.w	r12, [lr, r1, lsl #2]
	movw	r3, #0xf0f
	and.w	r12, r12, r3
	movw	r3, #0x80c0
	orr.w	r3, r3, r12
	str.w	r3, [lr, r1, lsl #2]
	ldrb	r1, [r2, #0]
	movw	r2, #0xf3f
	b.n	.L0804091a
.L08040970:
	ldr.w	r12, [lr, r1, lsl #2]
	movw	r3, #0xf0f
	and.w	r12, r12, r3
	movw	r3, #0xc080
	orr.w	r3, r3, r12
	str.w	r3, [lr, r1, lsl #2]
	ldrb	r1, [r2, #0]
	movw	r2, #0x3f0f
	b.n	.L0804091a

@ ----------------------------------------------------------------------------
@ fn_08040990 - resets two tables of eight 0x20-byte records in RAM.
@ No params, no return value. First array 0x20002b30, 0x20002b50, ... 0x20002c10
@ (8 records) and second array 0x20002c30 ... 0x20002d10 (8 records); these
@ addresses equal base+0xc and base+0x10c with base 0x20002b24, the entry
@ addresses used by fn_08040874, fn_08040b24 and fn_08040eb4.
@ For record i (0..7): stores the halfword i*0x101 at +0 (bytes 0 and 1 both i),
@ 1 at +2 in the first array and 0 at +2 in the second array, zero at +0xe
@ (halfword) and +0x14 (word); the word at +4 and the halfword at +8 are zeroed
@ in every record of the first array and in records 0, 3, 6 of the second
@ array; in records 1, 2, 4, 5, 7 of the second array the halfword at +4 and
@ the word at +6 are zeroed. The meaning of the fields is not determined from
@ the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08040990,"ax",%progbits
	.p2align 2
	.global fn_08040990
	.thumb_func
	.type fn_08040990, %function
fn_08040990:
	push	{r4, r5, r6, r7, lr}
	movw	r0, #0x2b24
	movt	r0, #0x2000
	movs	r1, #0
	movs	r5, #1
	movw	r12, #0x101
	movw	lr, #0x202
	movw	r2, #0x303
	movw	r3, #0x404
	movw	r4, #0x505
	movw	r6, #0x606
	movw	r7, #0x707
	strh	r1, [r0, #0xc]
	strb	r5, [r0, #0xe]
	strh	r1, [r0, #0x14]
	str	r1, [r0, #0x20]
	strh	r1, [r0, #0x1a]
	str	r1, [r0, #0x10]
	strh.w	r12, [r0, #0x2c]
	strb.w	r5, [r0, #0x2e]
	strh	r1, [r0, #0x34]
	str	r1, [r0, #0x40]
	strh	r1, [r0, #0x3a]
	str	r1, [r0, #0x30]
	strh.w	lr, [r0, #0x4c]
	strb.w	r5, [r0, #0x4e]
	strh.w	r1, [r0, #0x54]
	str	r1, [r0, #0x60]
	strh.w	r1, [r0, #0x5a]
	str	r1, [r0, #0x50]
	strh.w	r2, [r0, #0x6c]
	strb.w	r5, [r0, #0x6e]
	strh.w	r1, [r0, #0x74]
	str.w	r1, [r0, #0x80]
	strh.w	r1, [r0, #0x7a]
	str	r1, [r0, #0x70]
	strh.w	r3, [r0, #0x8c]
	strb.w	r5, [r0, #0x8e]
	strh.w	r1, [r0, #0x94]
	str.w	r1, [r0, #0xa0]
	strh.w	r1, [r0, #0x9a]
	str.w	r1, [r0, #0x90]
	strh.w	r4, [r0, #0xac]
	strb.w	r5, [r0, #0xae]
	strh.w	r1, [r0, #0xb4]
	str.w	r1, [r0, #0xc0]
	strh.w	r1, [r0, #0xba]
	str.w	r1, [r0, #0xb0]
	strh.w	r6, [r0, #0xcc]
	strb.w	r5, [r0, #0xce]
	strh.w	r1, [r0, #0xd4]
	str.w	r1, [r0, #0xe0]
	strh.w	r1, [r0, #0xda]
	str.w	r1, [r0, #0xd0]
	strh.w	r7, [r0, #0xec]
	strb.w	r5, [r0, #0xee]
	strh.w	r1, [r0, #0xf4]
	str.w	r1, [r0, #0x100]
	strh.w	r1, [r0, #0xfa]
	str.w	r1, [r0, #0xf0]
	strh.w	r1, [r0, #0x10c]
	strb.w	r1, [r0, #0x10e]
	strh.w	r1, [r0, #0x114]
	str.w	r1, [r0, #0x120]
	strh.w	r1, [r0, #0x11a]
	str.w	r1, [r0, #0x110]
	strh.w	r12, [r0, #0x12c]
	strb.w	r1, [r0, #0x12e]
	str.w	r1, [r0, #0x140]
	strh.w	r1, [r0, #0x13a]
	str.w	r1, [r0, #0x132]
	strh.w	r1, [r0, #0x130]
	strh.w	lr, [r0, #0x14c]
	strb.w	r1, [r0, #0x14e]
	str.w	r1, [r0, #0x160]
	strh.w	r1, [r0, #0x15a]
	str.w	r1, [r0, #0x152]
	strh.w	r1, [r0, #0x150]
	strh.w	r2, [r0, #0x16c]
	strb.w	r1, [r0, #0x16e]
	strh.w	r1, [r0, #0x174]
	str.w	r1, [r0, #0x180]
	strh.w	r1, [r0, #0x17a]
	str.w	r1, [r0, #0x170]
	strh.w	r3, [r0, #0x18c]
	strb.w	r1, [r0, #0x18e]
	str.w	r1, [r0, #0x1a0]
	strh.w	r1, [r0, #0x19a]
	str.w	r1, [r0, #0x192]
	strh.w	r1, [r0, #0x190]
	strh.w	r4, [r0, #0x1ac]
	strb.w	r1, [r0, #0x1ae]
	str.w	r1, [r0, #0x1c0]
	strh.w	r1, [r0, #0x1ba]
	str.w	r1, [r0, #0x1b2]
	strh.w	r1, [r0, #0x1b0]
	strh.w	r6, [r0, #0x1cc]
	strb.w	r1, [r0, #0x1ce]
	strh.w	r1, [r0, #0x1d4]
	str.w	r1, [r0, #0x1e0]
	strh.w	r1, [r0, #0x1da]
	str.w	r1, [r0, #0x1d0]
	strh.w	r7, [r0, #0x1ec]
	strb.w	r1, [r0, #0x1ee]
	str.w	r1, [r0, #0x200]
	strh.w	r1, [r0, #0x1fa]
	str.w	r1, [r0, #0x1f2]
	strh.w	r1, [r0, #0x1f0]
	pop	{r4, r5, r6, r7, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08040b24 - configures one record of the tables set up by fn_08040990, in the
@ register array at 0x40005c00 and the buffer area at 0x40006000.
@ Params: r0 = base, r1 = index, r2 (byte) = mode.
@ E = base + (r1 & 0x7f) * 0x20 + 0xc with E[2] = 1 when bit7 of r1 is set,
@ else E = base + (r1 & 0x7f) * 0x20 + 0x10c with E[2] = 0.
@ Sets E[8] = 0x40, E[9] = 0, E[3] = mode.
@ Buffer offsets: if E[10] == 0 then E[2] == 1 allocates only halfword E+4,
@ E[2] != 1 only E+6; if E[10] != 0 both; a halfword that is 0 receives the
@ running counter halfword 0x20000010, which then grows by 0x40.
@ W = word 0x40005c00[E[0]]: W = (W & 0x8f80) | E[1]; then by mode E[3]:
@ 0 -> 0x200, 2 -> 0x600, 3 -> 0x400 and E[10] = 1, other -> 0;
@ W = (W & 0x898f) | that.
@ Then with P = 0x40006000 + (word 0x40005c50 + E[0] * 8) * 2:
@ E[2] == 1 && E[10] != 0: W = (W & 0xe0f) | 0x8180; halfword E+4 stored to P+0,
@   E+6 to P+8; bit6 of W set -> W = (W & 0xf0f) | 0x80c0; bit14 set ->
@   W = (W & 0xf0f) | 0xc080; W = (W & 0xf0f) | 0xc080; W = (W & 0x3f0f) | 0x8080;
@   W = (W & 0xf3f) ^ 0x80a0.
@ E[2] == 1 && E[10] == 0: E+4 stored to P+0; bit6 set -> W = (W & 0xf0f) | 0x80c0;
@   W = (W & 0xf3f) ^ 0x80a0.
@ E[2] != 1 && E[10] != 0: W = (W & 0xe0f) | 0x8180; E+4 to P+0, E+6 to P+8,
@   c(E+8) to P+4 and P+0xc; bit6 and bit14 fixes as above;
@   W = (W & 0xf0f) | 0x80c0; W = (W & 0x3f0f) ^ 0xb080; W = (W & 0xf3f) | 0x8080.
@ E[2] != 1 && E[10] == 0: E+6 to P+8; bit14 set -> W = (W & 0xf0f) | 0xc080;
@   c(E+8) to P+0xc; W = (W & 0x3f0f) ^ 0xb080.
@ c(v) for halfword v: v < 0x3f -> ((~v & 1) + (v >> 1)) * 0x400;
@   else (((v >> 5) - (v & 0x1f == 0 ? 1 : 0)) << 10) | 0x8000.
@ No return value. The meaning of the fields is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08040b24,"ax",%progbits
	.p2align 2
	.global fn_08040b24
	.thumb_func
	.type fn_08040b24, %function
fn_08040b24:
	push.w	{r4, r5, r6, r7, r8, lr}
	lsls	r3, r1, #0x18
	and	r1, r1, #0x7f
	add.w	r1, r0, r1, lsl #5
	bmi.n	.L08040b40
	movs	r3, #0
	add.w	r0, r1, #0x10c
	strb.w	r3, [r1, #0x10e]
	b.n	.L08040b48
.L08040b40:
	add.w	r0, r1, #0xc
	movs	r3, #1
	strb	r3, [r1, #0xe]
.L08040b48:
	ldrb	r3, [r0, #0xa]
	movs	r1, #0x40
	strh	r1, [r0, #8]
	strb	r2, [r0, #3]
	cbz	r3, .L08040b6a
	ldrh	r1, [r0, #4]
	cbnz	r1, .L08040b88
	movw	r1, #0x10
	movt	r1, #0x2000
	ldrh	r2, [r1, #0]
	add.w	r3, r2, #0x40
	strh	r3, [r1, #0]
	strh	r2, [r0, #4]
	b.n	.L08040b88
.L08040b6a:
	ldrb	r1, [r0, #2]
	cmp	r1, #1
	bne.n	.L08040b88
	ldrh	r1, [r0, #4]
	cbnz	r1, .L08040b9e
	movw	r1, #0x10
	movt	r1, #0x2000
	ldrh	r2, [r1, #0]
	add.w	r3, r2, #0x40
	strh	r3, [r1, #0]
	strh	r2, [r0, #4]
	b.n	.L08040b9e
.L08040b88:
	ldrh	r1, [r0, #6]
	cbnz	r1, .L08040b9e
	movw	r1, #0x10
	movt	r1, #0x2000
	ldrh	r2, [r1, #0]
	add.w	r3, r2, #0x40
	strh	r3, [r1, #0]
	strh	r2, [r0, #6]
.L08040b9e:
	ldrb	r2, [r0, #0]
	movw	r1, #0x5c00
	movt	r1, #0x4000
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r6, #0x8f80
	ldrb	r5, [r0, #1]
	ands	r3, r6
	orrs	r3, r5
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r3, [r0, #3]
	cmp	r3, #3
	bhi.n	.L08040bcc
	mov.w	r2, #0x200
	tbb	[pc, r3]
.L08040bc8:
	.byte	(.L08040bde - .L08040bc8)/2
	.byte	(.L08040bcc - .L08040bc8)/2
	.byte	(.L08040bd0 - .L08040bc8)/2
	.byte	(.L08040bd6 - .L08040bc8)/2
.L08040bcc:
	movs	r2, #0
	b.n	.L08040bde
.L08040bd0:
	mov.w	r2, #0x600
	b.n	.L08040bde
.L08040bd6:
	movs	r2, #1
	strb	r2, [r0, #0xa]
	mov.w	r2, #0x400
.L08040bde:
	ldrb	r3, [r0, #0]
	movw	r5, #0x898f
	ldr.w	r6, [r1, r3, lsl #2]
	ands	r6, r5
	orrs	r2, r6
	str.w	r2, [r1, r3, lsl #2]
	ldrb	r3, [r0, #2]
	ldrb	r2, [r0, #0xa]
	cmp	r3, #1
	bne.n	.L08040cba
	cmp	r2, #0
	beq.w	.L08040d2c
	ldrb	r2, [r0, #0]
	movw	r6, #0xe0f
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r5, #0x6008
	ands	r3, r6
	movw	r6, #0x8180
	orrs	r3, r6
	str.w	r3, [r1, r2, lsl #2]
	ldrh	r3, [r0, #4]
	ldr	r6, [r1, #0x50]
	ldrb	r2, [r0, #0]
	movt	r5, #0x4000
	add.w	r6, r6, r2, lsl #3
	add.w	r6, r1, r6, lsl #1
	str.w	r3, [r6, #0x400]
	ldrh	r3, [r0, #6]
	ldr	r6, [r1, #0x50]
	add.w	r6, r6, r2, lsl #3
	str.w	r3, [r5, r6, lsl #1]
	ldr.w	r3, [r1, r2, lsl #2]
	lsls	r3, r3, #0x19
	bpl.n	.L08040c58
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r6, #0xf0f
	ands	r3, r6
	movw	r6, #0x80c0
	orrs	r3, r6
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r2, [r0, #0]
.L08040c58:
	ldr.w	r3, [r1, r2, lsl #2]
	lsls	r3, r3, #0x11
	bpl.n	.L08040c76
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r6, #0xf0f
	ands	r3, r6
	movw	r6, #0xc080
	orrs	r3, r6
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r2, [r0, #0]
.L08040c76:
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r6, #0xf0f
	ands	r3, r6
	movw	r6, #0xc080
	orrs	r3, r6
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r2, [r0, #0]
	movw	r6, #0x3f0f
	ldr.w	r3, [r1, r2, lsl #2]
	ands	r3, r6
	movw	r6, #0x8080
	orrs	r3, r6
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r0, [r0, #0]
	movw	r3, #0xf3f
	ldr.w	r2, [r1, r0, lsl #2]
	ands	r2, r3
	movw	r3, #0x80a0
	eors	r2, r3
	str.w	r2, [r1, r0, lsl #2]
	pop.w	{r4, r5, r6, r7, r8, pc}
.L08040cba:
	movw	r12, #0x6008
	cmp	r2, #0
	movt	r12, #0x4000
	beq.n	.L08040d6c
	ldrb	r2, [r0, #0]
	movw	r6, #0xe0f
	ldr.w	r3, [r1, r2, lsl #2]
	sub.w	r5, r12, #4
	ands	r3, r6
	movw	r6, #0x8180
	orrs	r3, r6
	str.w	r3, [r1, r2, lsl #2]
	ldrh	r3, [r0, #4]
	ldr	r6, [r1, #0x50]
	ldrb	r2, [r0, #0]
	add.w	r6, r6, r2, lsl #3
	add.w	r6, r1, r6, lsl #1
	str.w	r3, [r6, #0x400]
	ldrh	r3, [r0, #6]
	ldr	r4, [r1, #0x50]
	lsl.w	lr, r2, #3
	add.w	r4, r4, r2, lsl #3
	str.w	r3, [r12, r4, lsl #1]
	ldr	r4, [r1, #0x50]
	ldrh	r3, [r0, #8]
	add.w	r4, r4, r2, lsl #3
	cmp	r3, #0x3f
	bcc.n	.L08040dc4
	lsls	r7, r3, #0x1b
	lsr.w	r6, r3, #5
	movw	r7, #0x8000
	mov.w	r8, #0xffffffff
	it	eq
	addeq.w	r6, r8, r3, lsr #5
	movt	r7, #0xffff
	orr.w	r6, r7, r6, lsl #0xa
	b.n	.L08040dce
.L08040d2c:
	ldrh	r3, [r0, #4]
	ldr	r6, [r1, #0x50]
	ldrb	r2, [r0, #0]
	add.w	r6, r6, r2, lsl #3
	add.w	r6, r1, r6, lsl #1
	str.w	r3, [r6, #0x400]
	ldr.w	r3, [r1, r2, lsl #2]
	lsls	r3, r3, #0x19
	bpl.n	.L08040d5c
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r6, #0xf0f
	ands	r3, r6
	movw	r6, #0x80c0
	orrs	r3, r6
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r2, [r0, #0]
.L08040d5c:
	ldr.w	r0, [r1, r2, lsl #2]
	movw	r3, #0xf3f
	ands	r0, r3
	movw	r3, #0x80a0
	b.n	.L08040eaa
.L08040d6c:
	ldrh	r3, [r0, #6]
	ldr	r6, [r1, #0x50]
	ldrb	r2, [r0, #0]
	add.w	r6, r6, r2, lsl #3
	str.w	r3, [r12, r6, lsl #1]
	ldr.w	r3, [r1, r2, lsl #2]
	lsls	r3, r3, #0x11
	bpl.n	.L08040d98
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r6, #0xf0f
	ands	r3, r6
	movw	r6, #0xc080
	orrs	r3, r6
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r2, [r0, #0]
.L08040d98:
	ldr	r6, [r1, #0x50]
	ldrh	r5, [r0, #8]
	lsls	r3, r2, #3
	adds	r0, r3, r6
	cmp	r5, #0x3f
	add.w	r3, r12, #4
	bcc.n	.L08040e8c
	lsrs	r6, r5, #5
	mov.w	r12, #0xffffffff
	lsls	r4, r5, #0x1b
	it	eq
	addeq.w	r6, r12, r5, lsr #5
	movw	r5, #0x8000
	movt	r5, #0xffff
	orr.w	r6, r5, r6, lsl #0xa
	b.n	.L08040e96
.L08040dc4:
	movs	r6, #1
	bics	r6, r3
	add.w	r6, r6, r3, lsr #1
	lsls	r6, r6, #0xa
.L08040dce:
	uxth	r6, r6
	str.w	r6, [r5, r4, lsl #1]
	ldr	r4, [r1, #0x50]
	cmp	r3, #0x3f
	add	lr, r4
	add.w	r5, r12, #4
	bcc.n	.L08040dfc
	lsrs	r7, r3, #5
	mov.w	r6, #0xffffffff
	lsls	r4, r3, #0x1b
	it	eq
	addeq.w	r7, r6, r3, lsr #5
	movw	r3, #0x8000
	movt	r3, #0xffff
	orr.w	r3, r3, r7, lsl #0xa
	b.n	.L08040e06
.L08040dfc:
	movs	r7, #1
	bics	r7, r3
	add.w	r3, r7, r3, lsr #1
	lsls	r3, r3, #0xa
.L08040e06:
	uxth	r3, r3
	str.w	r3, [r5, lr, lsl #1]
	ldr.w	r3, [r1, r2, lsl #2]
	lsls	r3, r3, #0x19
	bpl.n	.L08040e2a
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r7, #0xf0f
	ands	r3, r7
	movw	r7, #0x80c0
	orrs	r3, r7
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r2, [r0, #0]
.L08040e2a:
	ldr.w	r3, [r1, r2, lsl #2]
	lsls	r3, r3, #0x11
	bpl.n	.L08040e48
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r7, #0xf0f
	ands	r3, r7
	movw	r7, #0xc080
	orrs	r3, r7
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r2, [r0, #0]
.L08040e48:
	ldr.w	r3, [r1, r2, lsl #2]
	movw	r7, #0xf0f
	ands	r3, r7
	movw	r7, #0x80c0
	orrs	r3, r7
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r2, [r0, #0]
	movw	r7, #0x3f0f
	ldr.w	r3, [r1, r2, lsl #2]
	ands	r3, r7
	movw	r7, #0xb080
	eors	r3, r7
	str.w	r3, [r1, r2, lsl #2]
	ldrb	r0, [r0, #0]
	movw	r3, #0xf3f
	ldr.w	r2, [r1, r0, lsl #2]
	ands	r2, r3
	movw	r3, #0x8080
	orrs	r2, r3
	str.w	r2, [r1, r0, lsl #2]
	pop.w	{r4, r5, r6, r7, r8, pc}
.L08040e8c:
	movs	r6, #1
	bics	r6, r5
	add.w	r6, r6, r5, lsr #1
	lsls	r6, r6, #0xa
.L08040e96:
	uxth	r6, r6
	str.w	r6, [r3, r0, lsl #1]
	ldr.w	r0, [r1, r2, lsl #2]
	movw	r3, #0x3f0f
	ands	r0, r3
	movw	r3, #0xb080
.L08040eaa:
	eors	r0, r3
	str.w	r0, [r1, r2, lsl #2]
	pop.w	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_08040eb4 - loads a buffer of halfwords into the area at 0x40006000 for record
@ index idx and updates its register word.
@ Params: r0 = base (word *r0 is the register-array pointer), r1 = index (& 0x7f),
@ r2 = source halfword pointer, r3 = count. Let L = base + idx * 0x20.
@ Stores r2 in the word at L+0x20, clears the halfword at L+0x1c, takes
@ limit = halfword L+0x14, writes max(limit, count) - limit to the halfword
@ L+0x1a and min(limit, count) to the halfword L+0x24 (count is clamped to the
@ limit).
@ If byte L+0x16 == 0: copies (n+1)>>1 halfwords (n = clamped count) from the
@ source to 0x40006000 + halfword[L+0x10] * 2 with a destination stride of 4
@ bytes (source stride 2), and stores n in the word
@ 0x40006004 + (word 0x40005c50 + idx * 8) * 2.
@ Else with Q = word 0x40005c50 + idx * 8: if bit6 of word (*r0)[idx] is set it
@ stores n at 0x4000600c + Q*2 and copies to the area at halfword[L+0x12] * 2,
@ else it stores n at 0x40006004 + Q*2 and copies to halfword[L+0x10] * 2
@ ((n+1)>>1 halfwords, same stride); then W = (W & 0xf0f) | 0xc080 for
@ W = word 0x40005c00[idx].
@ Finally W = (W & 0xf3f) ^ 0x80b0. No return value. The meaning of the fields
@ is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08040eb4,"ax",%progbits
	.p2align 2
	.global fn_08040eb4
	.thumb_func
	.type fn_08040eb4, %function
fn_08040eb4:
	push	{r4, r5, r6, lr}
	and	r1, r1, #0x7f
	ldr	r4, [r0, #0]
	add.w	r0, r0, r1, lsl #5
	ldrh	r5, [r0, #0x14]
	mov.w	lr, #0
	mov	r6, r5
	str	r2, [r0, #0x20]
	strh.w	lr, [r0, #0x1c]
	cmp	r3, r5
	it	hi
	movhi	r6, r3
	subs	r6, r6, r5
	cmp	r5, r3
	it	cc
	movcc	r3, r5
	ldrb	r5, [r0, #0x16]
	movw	r12, #0x5c00
	movt	r12, #0x4000
	strh	r6, [r0, #0x1a]
	strh	r3, [r0, #0x24]
	cbz	r5, .L08040f0c
	ldr.w	r4, [r4, r1, lsl #2]
	ldr.w	r5, [r12, #0x50]
	movw	lr, #0x6004
	lsls	r4, r4, #0x19
	movt	lr, #0x4000
	add.w	r4, r5, r1, lsl #3
	bmi.n	.L08040f8c
	adds	r0, #0x10
	str.w	r3, [lr, r4, lsl #1]
	b.n	.L08040f94
.L08040f0c:
	adds	r4, r3, #1
	cmp.w	lr, r4, lsr #1
	beq.n	.L08040f76
	ldrh	r0, [r0, #0x10]
	lsrs	r6, r4, #1
	add.w	r0, r12, r0, lsl #1
	subs	r5, r6, #1
	add.w	r0, r0, #0x400
	cmp	r5, #3
	and	lr, r6, #3
	bcc.n	.L08040f58
	mvn	r5, #3
	and.w	r4, r5, r4, lsr #1
	rsbs	r4, r4, #0
.L08040f34:
	ldrh.w	r5, [r2], #8
	adds	r4, #4
	strh.w	r5, [r0], #0x10
	ldrh.w	r5, [r2, #-6]
	strh.w	r5, [r0, #-12]
	ldrh.w	r5, [r2, #-4]
	strh.w	r5, [r0, #-8]
	ldrh.w	r5, [r2, #-2]
	strh.w	r5, [r0, #-4]
	bne.n	.L08040f34
.L08040f58:
	cmp.w	lr, #0
	beq.n	.L08040f76
	ldrh	r4, [r2, #0]
	cmp.w	lr, #1
	strh	r4, [r0, #0]
	beq.n	.L08040f76
	ldrh	r4, [r2, #2]
	cmp.w	lr, #2
	strh	r4, [r0, #4]
	itt	ne
	ldrhne	r2, [r2, #4]
	strhne	r2, [r0, #8]
.L08040f76:
	ldr.w	r0, [r12, #0x50]
	movw	r2, #0x6004
	add.w	r0, r0, r1, lsl #3
	movt	r2, #0x4000
	str.w	r3, [r2, r0, lsl #1]
	b.n	.L0804100e
.L08040f8c:
	add.w	r6, lr, r4, lsl #1
	str	r3, [r6, #8]
	adds	r0, #0x12
.L08040f94:
	adds	r4, r3, #1
	movs	r3, #0
	cmp.w	r3, r4, lsr #1
	beq.n	.L08040ffa
	ldrh	r0, [r0, #0]
	lsrs	r3, r4, #1
	add.w	r0, r12, r0, lsl #1
	subs	r6, r3, #1
	add.w	r0, r0, #0x400
	cmp	r6, #3
	and	r3, r3, #3
	bcc.n	.L08040fe4
	mvn	r6, #3
	and.w	r6, r6, r4, lsr #1
	rsbs	r4, r6, #0
	nop
.L08040fc0:
	ldrh.w	r6, [r2], #8
	adds	r4, #4
	strh.w	r6, [r0], #0x10
	ldrh.w	r6, [r2, #-6]
	strh.w	r6, [r0, #-12]
	ldrh.w	r6, [r2, #-4]
	strh.w	r6, [r0, #-8]
	ldrh.w	r6, [r2, #-2]
	strh.w	r6, [r0, #-4]
	bne.n	.L08040fc0
.L08040fe4:
	cbz	r3, .L08040ffa
	ldrh	r6, [r2, #0]
	cmp	r3, #1
	strh	r6, [r0, #0]
	beq.n	.L08040ffa
	ldrh	r6, [r2, #2]
	cmp	r3, #2
	strh	r6, [r0, #4]
	itt	ne
	ldrhne	r2, [r2, #4]
	strhne	r2, [r0, #8]
.L08040ffa:
	ldr.w	r0, [r12, r1, lsl #2]
	movw	r2, #0xf0f
	ands	r0, r2
	movw	r2, #0xc080
	orrs	r0, r2
	str.w	r0, [r12, r1, lsl #2]
.L0804100e:
	ldr.w	r0, [r12, r1, lsl #2]
	movw	r2, #0xf3f
	ands	r0, r2
	movw	r2, #0x80b0
	eors	r0, r2
	str.w	r0, [r12, r1, lsl #2]
	pop	{r4, r5, r6, pc}
