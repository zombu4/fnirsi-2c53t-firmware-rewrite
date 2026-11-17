@ system_57.s - interrupt-status handler fn_08009c10 and system register set-up fn_0802a9c4 (clock block bring-up, VTOR).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08009c10 - no parameters, no return value.
@ Reads 0x40010414 and acts only when bit3 is set: reads 0x40010410, writes 8 to
@ 0x40010414 (a second time when bit3 of the 0x40010410 value is set). Returns when
@ [0x20001060] != 1; otherwise writes 10 to 0x40015434 if [0x20001025] == 0 or
@ ([0x2000102e] == 2 and [0x20001025] == 2), then clears [0x20002d67].
@ The 4 padding bytes after the final bx lr are never reached.
@ ----------------------------------------------------------------------------
	.section .text.fn_08009c10,"ax",%progbits
	.global fn_08009c10
	.thumb_func
	.type fn_08009c10, %function
fn_08009c10:
	movw	r0, #0x414
	movt	r0, #0x4001
	ldr	r1, [r0, #0]
	lsls	r1, r1, #0x1c
	bpl.n	.L08009c72
	ldr.w	r2, [r0, #-0x4]
	movs	r1, #8
	lsls	r2, r2, #0x1c
	str	r1, [r0, #0]
	it	mi
	strmi	r1, [r0, #0]
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r1, [r0, #0xf68]
	cmp	r1, #1
	it	ne
	bxne	lr
	ldrb.w	r1, [r0, #0xf2d]
	cbz	r1, .L08009c5a
	ldrb.w	r0, [r0, #0xf36]
	eor.w	r1, r1, #2
	eor.w	r0, r0, #2
	orrs	r0, r1
	clz	r0, r0
	lsrs	r0, r0, #5
	beq.n	.L08009c66
.L08009c5a:
	movw	r0, #0x5434
	movt	r0, #0x4001
	movs	r1, #0xa
	str	r1, [r0, #0]
.L08009c66:
	movw	r0, #0x2d67
	movt	r0, #0x2000
	movs	r1, #0
	strb	r1, [r0, #0]
.L08009c72:
	bx	lr
	.word	0x00000000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0802a9c4 - no parameters, no return value.
@ Sets bits 20..23 (0xf00000) in 0xE000ED88; sets bit 0 in 0x40021000 and loops
@ until bit 1 of 0x40021000 reads set; clears bits 0..1 of 0x40021004 and loops
@ until bits 2..3 of 0x40021004 read 0; 0x40021000 &= 0xfef2ffff; writes 0 to
@ 0x40021004 and 0x40021030, 0x9f0000 to 0x40021008 and 0x08000000 to 0xE000ED08
@ (VTOR, i.e. 0x08000000 and not the image base 0x08007000).
@ Purpose: not determined from the code (register writes only; the clock block is
@ not identified). The 4 padding bytes after the final bx lr are never reached.
@ ----------------------------------------------------------------------------
	.section .text.fn_0802a9c4,"ax",%progbits
	.global fn_0802a9c4
	.thumb_func
	.type fn_0802a9c4, %function
fn_0802a9c4:
	movw	r0, #0xed88
	movt	r0, #0xe000
	ldr	r2, [r0, #0]
	movw	r1, #0x1000
	orr.w	r2, r2, #0xf00000
	movt	r1, #0x4002
	str	r2, [r0, #0]
	ldr	r2, [r1, #0]
	orr.w	r2, r2, #1
	str	r2, [r1, #0]
.L0802a9e4:
	ldr	r2, [r1, #0]
	lsls	r2, r2, #0x1e
	itttt	pl
	ldrpl	r2, [r1, #0]
	lslspl.w	r2, r2, #0x1e
	ldrpl	r2, [r1, #0]
	lslspl.w	r2, r2, #0x1e
	bmi.n	.L0802a9fe
	ldr	r2, [r1, #0]
	lsls	r2, r2, #0x1e
	bpl.n	.L0802a9e4
.L0802a9fe:
	ldr	r2, [r1, #4]
	bic.w	r2, r2, #3
	str	r2, [r1, #4]
	nop
.L0802aa08:
	ldr	r2, [r1, #4]
	tst.w	r2, #0xc
	beq.n	.L0802aa28
	ldr	r2, [r1, #4]
	tst.w	r2, #0xc
	beq.n	.L0802aa28
	ldr	r2, [r1, #4]
	tst.w	r2, #0xc
	beq.n	.L0802aa28
	ldr	r2, [r1, #4]
	tst.w	r2, #0xc
	bne.n	.L0802aa08
.L0802aa28:
	ldr	r2, [r1, #0]
	movw	r3, #0xffff
	movt	r3, #0xfef2
	ands	r2, r3
	str	r2, [r1, #0]
	movs	r2, #0
	str	r2, [r1, #4]
	str	r2, [r1, #0x30]
	mov.w	r2, #0x9f0000
	str	r2, [r1, #8]
	mov.w	r1, #0x8000000
	str.w	r1, [r0, #-0x80]
	bx	lr
	.word	0x00000000	@ padding
