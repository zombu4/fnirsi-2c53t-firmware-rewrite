@ clock_01.s - clock module, batch 01: small register read-modify-write helpers for 0x40015804.. and the 0x40021000 / 0x40023000 blocks.
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ write_40015804_bits - r0 = flag, r1 = value.
@ Word 0x40015804: bit 1 is cleared, then set again when r0 != 0 (bic/adds path
@ 0x08000A18..0x08000A22); then bit 0 = r1 & 1 (bfi r2, r1, #0, #1).
@ Called from 0x08002DD8. No return value. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.write_40015804_bits,"ax",%progbits
	.p2align 2
	.global write_40015804_bits
	.thumb_func
	.type write_40015804_bits, %function
write_40015804_bits:
	cbnz	r0, .L08000a18
	ldr	r2, .L08000a34
	ldr	r2, [r2]
	bic.w	r2, r2, #2
	ldr	r3, .L08000a34
	str	r2, [r3]
	b.n	.L08000a26
.L08000a18:
	ldr	r2, .L08000a34
	ldr	r2, [r2]
	bic.w	r2, r2, #2
	.inst.n 0x1c92	@ adds r2, r2, #2
	ldr	r3, .L08000a34
	str	r2, [r3]
.L08000a26:
	ldr	r2, .L08000a34
	ldr	r2, [r2]
	bfi	r2, r1, #0, #1
	ldr	r3, .L08000a34
	str	r2, [r3]
	bx	lr
.L08000a34:
	.word	0x40015804

@ ----------------------------------------------------------------------------
@ write_4001580c - str r0, [0x4001580C] (literal 0x08000A40); bx lr.
@ Called from 0x08002DC0.
@ ----------------------------------------------------------------------------
	.section .text.write_4001580c,"ax",%progbits
	.p2align 2
	.global write_4001580c
	.thumb_func
	.type write_4001580c, %function
write_4001580c:
	ldr	r1, .L08000a40
	str	r0, [r1]
	bx	lr
	.short	0x0000	@ padding
.L08000a40:
	.word	0x4001580c

@ ----------------------------------------------------------------------------
@ write_40015810 - str r0, [0x40015810] (literal 0x08000A4C); bx lr.
@ Called from 0x08002DC8.
@ ----------------------------------------------------------------------------
	.section .text.write_40015810,"ax",%progbits
	.p2align 2
	.global write_40015810
	.thumb_func
	.type write_40015810, %function
write_40015810:
	ldr	r1, .L08000a4c
	str	r0, [r1]
	bx	lr
	.short	0x0000	@ padding
.L08000a4c:
	.word	0x40015810

@ ----------------------------------------------------------------------------
@ write_40015814 - str r0, [0x40015814] (literal 0x08000A58); bx lr.
@ Called from 0x08002DD0.
@ ----------------------------------------------------------------------------
	.section .text.write_40015814,"ax",%progbits
	.p2align 2
	.global write_40015814
	.thumb_func
	.type write_40015814, %function
write_40015814:
	ldr	r1, .L08000a58
	str	r0, [r1]
	bx	lr
	.short	0x0000	@ padding
.L08000a58:
	.word	0x40015814

@ ----------------------------------------------------------------------------
@ set_40023008_bit0 - sets bit 0 of the word at 0x40023008 (read, clear bit 0,
@ add 1). Called from 0x08001ad4 (at 0x08001B16 and 0x08001B30) before each of
@ its two sums.
@ ----------------------------------------------------------------------------
	.section .text.set_40023008_bit0,"ax",%progbits
	.p2align 2
	.global set_40023008_bit0
	.thumb_func
	.type set_40023008_bit0, %function
set_40023008_bit0:
	ldr	r0, .L08001560
	ldr	r0, [r0, #8]
	bic.w	r0, r0, #1
	.inst.n 0x1c40	@ adds r0, r0, #1
	ldr	r1, .L08001560
	str	r0, [r1, #8]
	bx	lr
.L08001560:
	.word	0x40023000

@ ----------------------------------------------------------------------------
@ write_40023000_read_back - writes r0 to the word at 0x40023000 and returns
@ the word read back from 0x40023000. Called from 0x08001ad4 once per data word.
@ ----------------------------------------------------------------------------
	.section .text.write_40023000_read_back,"ax",%progbits
	.p2align 2
	.global write_40023000_read_back
	.thumb_func
	.type write_40023000_read_back, %function
write_40023000_read_back:
	mov	r1, r0
	ldr	r0, .L08001570
	str	r1, [r0]
	ldr	r0, [r0]
	bx	lr
	.short	0x0000	@ padding
.L08001570:
	.word	0x40023000

@ ----------------------------------------------------------------------------
@ set_40021004_bits7_4 - replaces bits 7..4 of the word at 0x40021004 with
@ r0 & 0xF. Caller 0x08002C36.
@ ----------------------------------------------------------------------------
	.section .text.set_40021004_bits7_4,"ax",%progbits
	.p2align 2
	.global set_40021004_bits7_4
	.thumb_func
	.type set_40021004_bits7_4, %function
set_40021004_bits7_4:
	ldr	r1, .L08001584
	ldr	r1, [r1, #4]
	bfi	r1, r0, #4, #4
	ldr	r2, .L08001584
	str	r1, [r2, #4]
	bx	lr
	.short	0x0000	@ padding
.L08001584:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ set_40021004_bits10_8 - replaces bits 10..8 of the word at 0x40021004 with
@ r0 & 7. Caller 0x08002C42.
@ ----------------------------------------------------------------------------
	.section .text.set_40021004_bits10_8,"ax",%progbits
	.p2align 2
	.global set_40021004_bits10_8
	.thumb_func
	.type set_40021004_bits10_8, %function
set_40021004_bits10_8:
	ldr	r1, .L08001598
	ldr	r1, [r1, #4]
	bfi	r1, r0, #8, #3
	ldr	r2, .L08001598
	str	r1, [r2, #4]
	bx	lr
	.short	0x0000	@ padding
.L08001598:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ set_40021004_bits13_11 - replaces bits 13..11 of the word at 0x40021004 with
@ r0 & 7. Caller 0x08002C3C.
@ ----------------------------------------------------------------------------
	.section .text.set_40021004_bits13_11,"ax",%progbits
	.p2align 2
	.global set_40021004_bits13_11
	.thumb_func
	.type set_40021004_bits13_11, %function
set_40021004_bits13_11:
	ldr	r1, .L080015ac
	ldr	r1, [r1, #4]
	bfi	r1, r0, #11, #3
	ldr	r2, .L080015ac
	str	r1, [r2, #4]
	bx	lr
	.short	0x0000	@ padding
.L080015ac:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ fn_080015b0 - if r0 == 1 sets bits 5..4 of the word at 0x40021054 (both to
@ 1), otherwise clears bits 5..4. Callers 0x08002C48 and 0x08002C5E. Purpose
@ not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080015b0,"ax",%progbits
	.p2align 2
	.global fn_080015b0
	.thumb_func
	.type fn_080015b0, %function
fn_080015b0:
	cmp	r0, #1
	bne.n	.L080015c4
	ldr	r1, .L080015d4
	ldr	r1, [r1, #0x54]
	bic.w	r1, r1, #0x30
	adds	r1, #0x30
	ldr	r2, .L080015d4
	str	r1, [r2, #0x54]
	b.n	.L080015d0
.L080015c4:
	ldr	r1, .L080015d4
	ldr	r1, [r1, #0x54]
	bic.w	r1, r1, #0x30
	ldr	r2, .L080015d4
	str	r1, [r2, #0x54]
.L080015d0:
	bx	lr
	.short	0x0000	@ padding
.L080015d4:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ fn_080015d8 - switch on r0, r1 = value (only bit 0 used): 0 -> bit 0 of
@ 0x40021000 = r1 & 1; 1 -> bit 16 of 0x40021000; 2 -> bit 24 of 0x40021000;
@ 3 -> bit 0 of 0x40021020; 4 -> bit 0 of 0x40021024; any other r0 does
@ nothing. Callers 0x08002C02 and 0x08002C24. Purpose not determined from the
@ code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080015d8,"ax",%progbits
	.p2align 2
	.global fn_080015d8
	.thumb_func
	.type fn_080015d8, %function
fn_080015d8:
	cmp	r0, #5
	bcs.n	.L0800162c
	tbb	[pc, r0]
.L080015e0:
	.byte	(.L080015e6 - .L080015e0)/2
	.byte	(.L080015f4 - .L080015e0)/2
	.byte	(.L08001602 - .L080015e0)/2
	.byte	(.L08001610 - .L080015e0)/2
	.byte	(.L0800161e - .L080015e0)/2
	.byte	0x00	@ padding
.L080015e6:
	ldr	r2, .L08001634
	ldr	r2, [r2]
	bfi	r2, r1, #0, #1
	ldr	r3, .L08001634
	str	r2, [r3]
	b.n	.L0800162e
.L080015f4:
	ldr	r2, .L08001634
	ldr	r2, [r2]
	bfi	r2, r1, #0x10, #1
	ldr	r3, .L08001634
	str	r2, [r3]
	b.n	.L0800162e
.L08001602:
	ldr	r2, .L08001634
	ldr	r2, [r2]
	bfi	r2, r1, #0x18, #1
	ldr	r3, .L08001634
	str	r2, [r3]
	b.n	.L0800162e
.L08001610:
	ldr	r2, .L08001634
	ldr	r2, [r2, #0x20]
	bfi	r2, r1, #0, #1
	ldr	r3, .L08001634
	str	r2, [r3, #0x20]
	b.n	.L0800162e
.L0800161e:
	ldr	r2, .L08001634
	ldr	r2, [r2, #0x24]
	bfi	r2, r1, #0, #1
	ldr	r3, .L08001634
	str	r2, [r3, #0x24]
	b.n	.L0800162e
.L0800162c:
	nop
.L0800162e:
	nop
	bx	lr
	.short	0x0000	@ padding
.L08001634:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ read_bit_40021000_offset - returns 1 if bit (r0 & 0x1F) of the word at
@ 0x40021000 + (r0 >> 16) is set, else 0. Callers 0x08001688, 0x08001698 (with
@ 0x11) and 0x08002C2C.
@ ----------------------------------------------------------------------------
	.section .text.read_bit_40021000_offset,"ax",%progbits
	.p2align 2
	.global read_bit_40021000_offset
	.thumb_func
	.type read_bit_40021000_offset, %function
read_bit_40021000_offset:
	push	{r4, lr}
	mov	r1, r0
	movs	r0, #0
	ldr	r3, .L08001664
	add.w	r2, r3, r1, lsr #16
	ldr	r2, [r2]
	and.w	r4, r1, #0x1f
	movs	r3, #1
	lsls	r3, r4
	ands	r2, r3
	and.w	r4, r1, #0x1f
	movs	r3, #1
	lsls	r3, r4
	cmp	r2, r3
	beq.n	.L0800165e
	b.n	.L08001660
.L0800165e:
	movs	r0, #1
.L08001660:
	pop	{r4, pc}
	.short	0x0000	@ padding
.L08001664:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ set_40021054_bits13_12 - replaces bits 13..12 of the word at 0x40021054 with
@ r0 & 3. Caller 0x08002C1C.
@ ----------------------------------------------------------------------------
	.section .text.set_40021054_bits13_12,"ax",%progbits
	.p2align 2
	.global set_40021054_bits13_12
	.thumb_func
	.type set_40021054_bits13_12, %function
set_40021054_bits13_12:
	ldr	r1, .L08001678
	ldr	r1, [r1, #0x54]
	bfi	r1, r0, #0xc, #2
	ldr	r2, .L08001678
	str	r1, [r2, #0x54]
	bx	lr
	.short	0x0000	@ padding
.L08001678:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ fn_0800167c - polls read_bit_40021000_offset(0x11) (bit 17 of 0x40021000) up
@ to 0x3001 times (counter 0..0x3000, loop ends when the bit is 1 or the
@ counter reaches 0x3000); returns 1 if the bit is set on a final read, else 0.
@ Caller 0x08002C08. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800167c,"ax",%progbits
	.p2align 2
	.global fn_0800167c
	.thumb_func
	.type fn_0800167c, %function
fn_0800167c:
	push	{r4, r5, lr}
	movs	r4, #0
	movs	r5, #0
	b.n	.L08001686
.L08001684:
	.inst.n 0x1c64	@ adds r4, r4, #1
.L08001686:
	movs	r0, #0x11
	bl	read_bit_40021000_offset
	cmp	r0, #1
	beq.n	.L08001696
	cmp.w	r4, #0x3000
	bcc.n	.L08001684
.L08001696:
	movs	r0, #0x11
	bl	read_bit_40021000_offset
	cmp	r0, #1
	beq.n	.L080016a4
	movs	r5, #0
	b.n	.L080016a6
.L080016a4:
	movs	r5, #1
.L080016a6:
	mov	r0, r5
	pop	{r4, r5, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ set_40021030_bit25 - replaces bit 25 of the word at 0x40021030 with r0 & 1.
@ Caller 0x080016C6.
@ ----------------------------------------------------------------------------
	.section .text.set_40021030_bit25,"ax",%progbits
	.p2align 2
	.global set_40021030_bit25
	.thumb_func
	.type set_40021030_bit25, %function
set_40021030_bit25:
	ldr	r1, .L080016bc
	ldr	r1, [r1, #0x30]
	bfi	r1, r0, #0x19, #1
	ldr	r2, .L080016bc
	str	r1, [r2, #0x30]
	bx	lr
	.short	0x0000	@ padding
.L080016bc:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ fn_080016c0 - r0 = value. Calls set_40021030_bit25(1) (bit 25 of 0x40021030
@ = 1), then replaces bit 9 of the word at 0x40021054 with r0 & 1 (r0 saved in
@ r3 at 0x080016C2). Caller 0x08001874. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080016c0,"ax",%progbits
	.p2align 2
	.global fn_080016c0
	.thumb_func
	.type fn_080016c0, %function
fn_080016c0:
	push	{lr}
	mov	r3, r0
	movs	r0, #1
	bl	set_40021030_bit25
	ldr	r0, .L080016d8
	ldr	r0, [r0, #0x54]
	bfi	r0, r3, #9, #1
	ldr	r1, .L080016d8
	str	r0, [r1, #0x54]
	pop	{pc}
.L080016d8:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ set_or_clear_bit_40021000_offset - r0 = bit descriptor (offset from
@ 0x40021000 in bits 31..16, bit number in bits 4..0), r1 = mode: if r1 == 1
@ sets the bit in the word at 0x40021000 + (r0 >> 16), otherwise clears it.
@ Called with 0x140006 from 0x08001AD4 (set at 0x08001AF6, clear at
@ 0x08001B4C), 0x08000342, 0x0800034C, 0x08000356, 0x08000360, 0x0800056A,
@ 0x0800093A, 0x08002790, 0x08002798, 0x080029EA, 0x08002DB8, 0x080046BE,
@ 0x080046C8, 0x080046D2, 0x080046DA.
@ ----------------------------------------------------------------------------
	.section .text.set_or_clear_bit_40021000_offset,"ax",%progbits
	.p2align 2
	.global set_or_clear_bit_40021000_offset
	.thumb_func
	.type set_or_clear_bit_40021000_offset, %function
set_or_clear_bit_40021000_offset:
	push	{r4, lr}
	cmp	r1, #1
	bne.n	.L080016fe
	ldr	r3, .L0800171c
	add.w	r2, r3, r0, lsr #16
	ldr	r2, [r2]
	and.w	r4, r0, #0x1f
	movs	r3, #1
	lsls	r3, r4
	orrs	r2, r3
	ldr	r4, .L0800171c
	add.w	r3, r4, r0, lsr #16
	str	r2, [r3]
	b.n	.L08001718
.L080016fe:
	ldr	r3, .L0800171c
	add.w	r2, r3, r0, lsr #16
	ldr	r2, [r2]
	and.w	r4, r0, #0x1f
	movs	r3, #1
	lsls	r3, r4
	bics	r2, r3
	ldr	r4, .L0800171c
	add.w	r3, r4, r0, lsr #16
	str	r2, [r3]
.L08001718:
	pop	{r4, pc}
	.short	0x0000	@ padding
.L0800171c:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ set_or_clear_bit_40021000_offset_b - same code as
@ set_or_clear_bit_40021000_offset (r0 = descriptor, r1 == 1 sets the bit in
@ the word at 0x40021000 + (r0 >> 16), otherwise clears it). Callers
@ 0x080027A0 and 0x080027A8 only.
@ ----------------------------------------------------------------------------
	.section .text.set_or_clear_bit_40021000_offset_b,"ax",%progbits
	.p2align 2
	.global set_or_clear_bit_40021000_offset_b
	.thumb_func
	.type set_or_clear_bit_40021000_offset_b, %function
set_or_clear_bit_40021000_offset_b:
	push	{r4, lr}
	cmp	r1, #1
	bne.n	.L08001742
	ldr	r3, .L08001760
	add.w	r2, r3, r0, lsr #16
	ldr	r2, [r2]
	and.w	r4, r0, #0x1f
	movs	r3, #1
	lsls	r3, r4
	orrs	r2, r3
	ldr	r4, .L08001760
	add.w	r3, r4, r0, lsr #16
	str	r2, [r3]
	b.n	.L0800175c
.L08001742:
	ldr	r3, .L08001760
	add.w	r2, r3, r0, lsr #16
	ldr	r2, [r2]
	and.w	r4, r0, #0x1f
	movs	r3, #1
	lsls	r3, r4
	bics	r2, r3
	ldr	r4, .L08001760
	add.w	r3, r4, r0, lsr #16
	str	r2, [r3]
.L0800175c:
	pop	{r4, pc}
	.short	0x0000	@ padding
.L08001760:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ fn_08001764 - r0, r1, r2 = parameters. r0 == 0: clears bit 16 of 0x40021004;
@ otherwise sets bit 16 and sets bit 17 unless r0 == 1 (then clears it). Then
@ bits 21..18 = r1 & 0xF, bits 30..29 = (r1 >> 4) & 3, bit 31 = r2 & 1, all in
@ 0x40021004. Caller 0x08002C16. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001764,"ax",%progbits
	.p2align 2
	.global fn_08001764
	.thumb_func
	.type fn_08001764, %function
fn_08001764:
	push	{r4, lr}
	cbnz	r0, .L08001776
	ldr	r3, .L080017cc
	ldr	r3, [r3, #4]
	bic.w	r3, r3, #0x10000
	ldr	r4, .L080017cc
	str	r3, [r4, #4]
	b.n	.L080017a6
.L08001776:
	ldr	r3, .L080017cc
	ldr	r3, [r3, #4]
	bic.w	r3, r3, #0x10000
	add.w	r3, r3, #0x10000
	ldr	r4, .L080017cc
	str	r3, [r4, #4]
	cmp	r0, #1
	bne.n	.L08001796
	mov	r3, r4
	ldr	r3, [r3, #4]
	bic.w	r3, r3, #0x20000
	str	r3, [r4, #4]
	b.n	.L080017a6
.L08001796:
	ldr	r3, .L080017cc
	ldr	r3, [r3, #4]
	bic.w	r3, r3, #0x20000
	add.w	r3, r3, #0x20000
	ldr	r4, .L080017cc
	str	r3, [r4, #4]
.L080017a6:
	ldr	r3, .L080017cc
	ldr	r3, [r3, #4]
	bfi	r3, r1, #0x12, #4
	ldr	r4, .L080017cc
	str	r3, [r4, #4]
	lsrs	r4, r1, #4
	ldr	r3, .L080017cc
	ldr	r3, [r3, #4]
	bfi	r3, r4, #0x1d, #2
	ldr	r4, .L080017cc
	str	r3, [r4, #4]
	mov	r3, r4
	ldr	r3, [r3, #4]
	bfi	r3, r2, #0x1f, #1
	str	r3, [r4, #4]
	pop	{r4, pc}
.L080017cc:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ fn_080017d0 - sets bit 0 of 0x40021000 and waits (no timeout) for bit 1 of
@ 0x40021000 to be 1; clears bits 1..0 of 0x40021004 and waits (no timeout)
@ until bits 3..2 of 0x40021004 are 0; clears bits 16, 18, 19, 24 of
@ 0x40021000 (AND 0xFEF2FFFF); writes 0 to 0x40021004, 0 to 0x40021030 and
@ 0x9F0000 to 0x40021008. Caller 0x08002BFA. Purpose not determined from the
@ code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080017d0,"ax",%progbits
	.p2align 2
	.global fn_080017d0
	.thumb_func
	.type fn_080017d0, %function
fn_080017d0:
	ldr	r0, .L08001820
	ldr	r0, [r0]
	bic.w	r0, r0, #1
	.inst.n 0x1c40	@ adds r0, r0, #1
	ldr	r1, .L08001820
	str	r0, [r1]
	nop
.L080017e0:
	ldr	r0, .L08001820
	ldr	r0, [r0]
	ubfx	r0, r0, #1, #1
	cmp	r0, #0
	beq.n	.L080017e0
	ldr	r0, .L08001820
	ldr	r0, [r0, #4]
	bic.w	r0, r0, #3
	ldr	r1, .L08001820
	str	r0, [r1, #4]
	nop
.L080017fa:
	ldr	r0, .L08001820
	ldr	r0, [r0, #4]
	ubfx	r0, r0, #2, #2
	cmp	r0, #0
	bne.n	.L080017fa
	ldr	r0, .L08001820
	ldr	r0, [r0]
	ldr	r1, .L08001824
	ands	r0, r1
	ldr	r1, .L08001820
	str	r0, [r1]
	movs	r0, #0
	str	r0, [r1, #4]
	str	r0, [r1, #0x30]
	mov.w	r0, #0x9f0000
	str	r0, [r1, #8]
	bx	lr
.L08001820:
	.word	0x40021000
.L08001824:
	.word	0xfef2ffff

@ ----------------------------------------------------------------------------
@ set_40021004_bits1_0 - replaces bits 1..0 of the word at 0x40021004 with
@ r0 & 3. Caller 0x08002C4E.
@ ----------------------------------------------------------------------------
	.section .text.set_40021004_bits1_0,"ax",%progbits
	.p2align 2
	.global set_40021004_bits1_0
	.thumb_func
	.type set_40021004_bits1_0, %function
set_40021004_bits1_0:
	ldr	r1, .L08001838
	ldr	r1, [r1, #4]
	bfi	r1, r0, #0, #2
	ldr	r2, .L08001838
	str	r1, [r2, #4]
	bx	lr
	.short	0x0000	@ padding
.L08001838:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ get_40021004_bits3_2 - returns bits 3..2 of the word at 0x40021004
@ ((v & 0xF) >> 2). Callers 0x08002C54 and 0x08002C78.
@ ----------------------------------------------------------------------------
	.section .text.get_40021004_bits3_2,"ax",%progbits
	.p2align 2
	.global get_40021004_bits3_2
	.thumb_func
	.type get_40021004_bits3_2, %function
get_40021004_bits3_2:
	ldr	r0, .L08001848
	ldr	r0, [r0, #4]
	ubfx	r0, r0, #2, #2
	bx	lr
	.short	0x0000	@ padding
.L08001848:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ fn_0800184c - replaces bits 23..22 of 0x40021004 with r0 & 3, then bit 27
@ with (r0 >> 2) & 1. Callers 0x08002E16..0x08002E46 (seven calls). Purpose
@ not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800184c,"ax",%progbits
	.p2align 2
	.global fn_0800184c
	.thumb_func
	.type fn_0800184c, %function
fn_0800184c:
	ldr	r1, .L08001868
	ldr	r1, [r1, #4]
	bfi	r1, r0, #0x16, #2
	ldr	r2, .L08001868
	str	r1, [r2, #4]
	lsrs	r2, r0, #2
	ldr	r1, .L08001868
	ldr	r1, [r1, #4]
	bfi	r1, r2, #0x1b, #1
	ldr	r2, .L08001868
	str	r1, [r2, #4]
	bx	lr
.L08001868:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ fn_0800186c - r0 = value. If r0 == 1 calls fn_080016c0(1); then replaces
@ bit 8 of the word at 0x40021054 with r0 & 1. Caller 0x08002DB0. Purpose not
@ determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800186c,"ax",%progbits
	.p2align 2
	.global fn_0800186c
	.thumb_func
	.type fn_0800186c, %function
fn_0800186c:
	push	{r4, lr}
	mov	r4, r0
	cmp	r4, #1
	bne.n	.L08001878
	bl	fn_080016c0
.L08001878:
	ldr	r0, .L08001888
	ldr	r0, [r0, #0x54]
	bfi	r0, r4, #8, #1
	ldr	r1, .L08001888
	str	r0, [r1, #0x54]
	pop	{r4, pc}
	.short	0x0000	@ padding
.L08001888:
	.word	0x40021000

@ ----------------------------------------------------------------------------
@ fn_0800188c - calls systick_clock_source(4), then stores RAM 0x200000C4 /
@ 1000000 into 0x200000A8 and that quotient * 1000 into 0x200000AC (0x200000C4
@ holds 0x007A1200 in rwdata_20000000.bin). 0x200000AC is the reload
@ multiplier used by systick_delay. Caller 0x0800294A. Purpose not determined
@ from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800188c,"ax",%progbits
	.p2align 2
	.global fn_0800188c
	.thumb_func
	.type fn_0800188c, %function
fn_0800188c:
	push	{r4, lr}
	movs	r0, #4
	bl	systick_clock_source
	ldr	r0, .L080018b4
	ldr	r0, [r0]
	ldr	r1, .L080018b8
	udiv	r0, r0, r1
	ldr	r1, .L080018bc
	str	r0, [r1]
	mov	r0, r1
	ldr	r0, [r0]
	mov.w	r1, #0x3e8
	muls	r0, r1, r0
	ldr	r1, .L080018c0
	str	r0, [r1]
	pop	{r4, pc}
	.short	0x0000	@ padding
.L080018b4:
	.word	0x200000c4
.L080018b8:
	.word	0x000f4240
.L080018bc:
	.word	0x200000a8
.L080018c0:
	.word	0x200000ac

@ ----------------------------------------------------------------------------
@ systick_delay - r0 = count. Repeats until the count is 0: n = count if count
@ < 0x33 (signed), else 0x32 (count -= 0x32, masked to 16 bits); writes
@ n * [0x200000AC] to 0xE000E014, 0 to 0xE000E018, sets bit 0 of 0xE000E010
@ and waits until bit 16 of 0xE000E010 is set or bit 0 is clear; then clears
@ bit 0 of 0xE000E010 and writes 0 to 0xE000E018. Callers 0x080006F0,
@ 0x080006FE, 0x0800070C, 0x08000718, 0x08001D82, 0x08001DD4, 0x080029CC,
@ 0x0800367E, 0x0800368C (0x08001D2C passes 1000). No return value.
@ ----------------------------------------------------------------------------
	.section .text.systick_delay,"ax",%progbits
	.p2align 2
	.global systick_delay
	.thumb_func
	.type systick_delay, %function
systick_delay:
	movs	r1, #0
	b.n	.L0800192c
.L080018c8:
	cmp	r0, #0x32
	ble.n	.L080018e2
	ldr	r2, .L08001934
	ldr	r2, [r2]
	movs	r3, #0x32
	muls	r2, r3, r2
	mov.w	r3, #0xe000e000
	str	r2, [r3, #0x14]
	sub.w	r2, r0, #0x32
	uxth	r0, r2
	b.n	.L080018f0
.L080018e2:
	ldr	r2, .L08001934
	ldr	r2, [r2]
	muls	r2, r0, r2
	mov.w	r3, #0xe000e000
	str	r2, [r3, #0x14]
	movs	r0, #0
.L080018f0:
	movs	r2, #0
	mov.w	r3, #0xe000e000
	str	r2, [r3, #0x18]
	mov	r2, r3
	ldr	r2, [r2, #0x10]
	orr.w	r2, r2, #1
	str	r2, [r3, #0x10]
	nop
.L08001904:
	mov.w	r2, #0xe000e000
	ldr	r1, [r2, #0x10]
	and.w	r2, r1, #1
	cbz	r2, .L08001918
	and.w	r2, r1, #0x10000
	cmp	r2, #0
	beq.n	.L08001904
.L08001918:
	mov.w	r2, #0xe000e000
	ldr	r2, [r2, #0x10]
	bic.w	r2, r2, #1
	mov.w	r3, #0xe000e000
	str	r2, [r3, #0x10]
	movs	r2, #0
	str	r2, [r3, #0x18]
.L0800192c:
	cmp	r0, #0
	bne.n	.L080018c8
	bx	lr
	.short	0x0000	@ padding
.L08001934:
	.word	0x200000ac

@ ----------------------------------------------------------------------------
@ fn_08002bf8 - programs the register block at 0x40021000 in the order below,
@ then calls fn_08002c68.
@ Order: fn_080017d0 (sets bit 0 of word 0x40021000, waits for bit 1, clears
@ bits 1..0 of [0x40021004], waits for bits 3..2 = 0, masks [0x40021000] with
@ 0xfef2ffff, [0x40021004] = 0, [0x40021030] = 0, [0x40021008] = 0x9f0000);
@ fn_080015d8(1, 1) (bit 16 of [0x40021000]); polls fn_0800167c (bit 17: up to
@ 0x3001 reads in its loop plus one read afterwards, r4 0..0x3000 with bcc)
@ until it returns 1; fn_08001764(2, 0x2f, 1) (bits of [0x40021004]: 16 and 17
@ set, bits 21..18 = 0xf, bits 30..29 = 2, bit 31 = 1); set_40021054_bits13_12(0);
@ fn_080015d8(2, 1) (bit 24 of [0x40021000]); polls
@ read_bit_40021000_offset(0x19) (bit 25 of [0x40021000]) until it returns 1;
@ set_40021004_bits7_4(0), set_40021004_bits13_11(4), set_40021004_bits10_8(4),
@ fn_080015b0(1); set_40021004_bits1_0(2) (bits 1..0 of [0x40021004] = 2);
@ polls get_40021004_bits3_2 (bits 3..2 of [0x40021004]) until 2;
@ fn_080015b0(0); fn_08002c68.
@ Waits have no time limit except the 0x3000 count in fn_0800167c, whose result
@ is looped on. Caller: 0x08002942. Purpose of each field is stated only by the
@ register bits; no register names are proven by the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002bf8,"ax",%progbits
	.p2align 2
	.global fn_08002bf8
	.thumb_func
	.type fn_08002bf8, %function
fn_08002bf8:
	push	{r4, lr}
	bl	fn_080017d0
	movs	r1, #1
	mov	r0, r1
	bl	fn_080015d8
	nop
.L08002c08:
	bl	fn_0800167c
	cmp	r0, #0
	beq.n	.L08002c08
	movs	r2, #1
	movs	r1, #0x2f
	movs	r0, #2
	bl	fn_08001764
	movs	r0, #0
	bl	set_40021054_bits13_12
	movs	r1, #1
	movs	r0, #2
	bl	fn_080015d8
	nop
.L08002c2a:
	movs	r0, #0x19
	bl	read_bit_40021000_offset
	cmp	r0, #1
	bne.n	.L08002c2a
	movs	r0, #0
	bl	set_40021004_bits7_4
	movs	r0, #4
	bl	set_40021004_bits13_11
	movs	r0, #4
	bl	set_40021004_bits10_8
	movs	r0, #1
	bl	fn_080015b0
	movs	r0, #2
	bl	set_40021004_bits1_0
	nop
.L08002c54:
	bl	get_40021004_bits3_2
	cmp	r0, #2
	bne.n	.L08002c54
	movs	r0, #0
	bl	fn_080015b0
	bl	fn_08002c68
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08002c68 - computes a value into the word 0x200000c4 from the fields of
@ 0x40021004: source = bits 3..2 (get_40021004_bits3_2).
@ 0: 48000000 when bit 9 of [0x40021054] and bit 25 of [0x40021030] are both
@ set, else 8000000.
@ 1 and any other value except 2: 8000000.
@ 2: m = bits 21..18, k = bits 30..29, factor = m + 2 when k == 0 and m != 15,
@ else m + 16 * k + 1; bit 16 of [0x40021004] clear: 4000000 * factor; set with
@ bit 17 set: (8000000 / (bits 13..12 of [0x40021054] + 2)) * factor; set with
@ bit 17 clear: 8000000 * factor.
@ Finally shifts the value right by the byte at 0x08005733 + bits 7..4 of
@ [0x40021004] (bytes 0 0 0 0 0 0 0 0 1 2 3 4 6 7 8 9).
@ Caller: 0x08002c62. Purpose not determined from the code; the register
@ meanings are not shown in the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002c68,"ax",%progbits
	.p2align 2
	.global fn_08002c68
	.thumb_func
	.type fn_08002c68, %function
fn_08002c68:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	movs	r6, #0
	movs	r4, #0
	movs	r5, #0
	movs	r7, #0
	mov	r8, r4
	mov	r9, r4
	bl	get_40021004_bits3_2
	mov	r10, r0
	cmp.w	r10, #0
	beq.n	.L08002c92
	cmp.w	r10, #1
	beq.n	.L08002cb6
	cmp.w	r10, #2
	bne.n	.L08002d1e
	b.n	.L08002cbe
.L08002c92:
	ldr	r0, .L08002d48
	ldr	r0, [r0, #0x54]
	ubfx	r0, r0, #9, #1
	cbz	r0, .L08002cae
	ldr	r0, .L08002d48
	ldr	r0, [r0, #0x30]
	ubfx	r0, r0, #0x19, #1
	cbz	r0, .L08002cae
	ldr	r0, .L08002d4c
	ldr	r1, .L08002d50
	str	r0, [r1]
	b.n	.L08002cb4
.L08002cae:
	ldr	r0, .L08002d54
	ldr	r1, .L08002d50
	str	r0, [r1]
.L08002cb4:
	b.n	.L08002d26
.L08002cb6:
	ldr	r0, .L08002d54
	ldr	r1, .L08002d50
	str	r0, [r1]
	b.n	.L08002d26
.L08002cbe:
	ldr	r0, .L08002d48
	ldr	r0, [r0, #4]
	ubfx	r7, r0, #0x10, #1
	ldr	r0, .L08002d48
	ldr	r0, [r0, #4]
	ubfx	r4, r0, #0x12, #4
	ldr	r0, .L08002d48
	ldr	r0, [r0, #4]
	ubfx	r5, r0, #0x1d, #2
	cbnz	r5, .L08002cdc
	cmp	r4, #0xf
	bne.n	.L08002ce4
.L08002cdc:
	lsls	r0, r5, #4
	.inst.n 0x1c40	@ adds r0, r0, #1
	add	r4, r0
	b.n	.L08002ce6
.L08002ce4:
	.inst.n 0x1ca4	@ adds r4, r4, #2
.L08002ce6:
	cbnz	r7, .L08002cf2
	ldr	r0, .L08002d58
	muls	r0, r4, r0
	ldr	r1, .L08002d50
	str	r0, [r1]
	b.n	.L08002d1c
.L08002cf2:
	ldr	r0, .L08002d48
	ldr	r0, [r0, #4]
	ubfx	r0, r0, #0x11, #1
	cbz	r0, .L08002d14
	ldr	r0, .L08002d48
	ldr	r0, [r0, #0x54]
	ubfx	r6, r0, #0xc, #2
	adds	r0, r6, #2
	ldr	r1, .L08002d54
	udiv	r0, r1, r0
	muls	r0, r4, r0
	ldr	r1, .L08002d50
	str	r0, [r1]
	b.n	.L08002d1c
.L08002d14:
	ldr	r0, .L08002d54
	muls	r0, r4, r0
	ldr	r1, .L08002d50
	str	r0, [r1]
.L08002d1c:
	b.n	.L08002d26
.L08002d1e:
	ldr	r0, .L08002d54
	ldr	r1, .L08002d50
	str	r0, [r1]
	nop
.L08002d26:
	nop
	ldr	r0, .L08002d48
	ldr	r0, [r0, #4]
	ubfx	r8, r0, #4, #4
	ldr	r0, .L08002d5c
	ldrb.w	r9, [r0, r8]
	ldr	r0, .L08002d50
	ldr	r0, [r0]
	lsr.w	r0, r0, r9
	ldr	r1, .L08002d50
	str	r0, [r1]
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
	.short	0x0000	@ padding
.L08002d48:
	.word	0x40021000
.L08002d4c:
	.word	0x02dc6c00
.L08002d50:
	.word	0x200000c4
.L08002d54:
	.word	0x007a1200
.L08002d58:
	.word	0x003d0900
.L08002d5c:
	.word	d_08005732+1

@ ----------------------------------------------------------------------------
@ systick_clock_source - r0 == 4: sets bit 2 of 0xe000e010; any other r0:
@ clears bit 2. Caller: 0x08001890.
@ ----------------------------------------------------------------------------
	.section .text.systick_clock_source,"ax",%progbits
	.p2align 2
	.global systick_clock_source
	.thumb_func
	.type systick_clock_source, %function
systick_clock_source:
	cmp	r0, #4
	bne.n	.L08002d76
	mov.w	r1, #0xe000e000
	ldr	r1, [r1, #0x10]
	orr.w	r1, r1, #4
	mov.w	r2, #0xe000e000
	str	r1, [r2, #0x10]
	b.n	.L08002d86
.L08002d76:
	mov.w	r1, #0xe000e000
	ldr	r1, [r1, #0x10]
	bic.w	r1, r1, #4
	mov.w	r2, #0xe000e000
	str	r1, [r2, #0x10]
.L08002d86:
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08002da8 - r0 = mode.
@ r0 == 0: fn_0800186c(1), set_or_clear_bit_40021000_offset(0x00180016, 1),
@ write_4001580c(0x1f2c), write_40015810(8000), write_40015814(0x1f54),
@ write_40015804_bits(2, 1); the only call site (0x080029e2) passes 1, so this
@ block is not reached from there.
@ r0 != 0: reads the word 0x200000c4 and calls fn_0800184c(code) with code 2
@ for 120000000, 1 for 48000000, 0 for 72000000, 3 for 96000000, 5 for
@ 144000000, 4 for 168000000, 6 for 192000000; other values: no call.
@ fn_0800184c sets bits 23..22 of [0x40021004] to code & 3 and bit 27 to
@ code >> 2. Caller: 0x080029e2 (r0 = 1).
@ ----------------------------------------------------------------------------
	.section .text.fn_08002da8,"ax",%progbits
	.p2align 2
	.global fn_08002da8
	.thumb_func
	.type fn_08002da8, %function
fn_08002da8:
	push	{r4, lr}
	mov	r4, r0
	cbnz	r4, .L08002dde
	movs	r0, #1
	bl	fn_0800186c
	movs	r1, #1
	ldr	r0, .L08002e54
	bl	set_or_clear_bit_40021000_offset
	movw	r0, #0x1f2c
	bl	write_4001580c
	mov.w	r0, #0x1f40
	bl	write_40015810
	movw	r0, #0x1f54
	bl	write_40015814
	movs	r1, #1
	movs	r0, #2
	bl	write_40015804_bits
	b.n	.L08002e50
.L08002dde:
	ldr	r0, .L08002e58
	ldr	r0, [r0]
	ldr	r2, .L08002e5c
	subs	r1, r0, r2
	cmp	r0, r2
	beq.n	.L08002e2c
	bgt.n	.L08002e00
	ldr	r1, .L08002e60
	add	r0, r1
	cbz	r0, .L08002e12
	asr.w	r1, r1, #1
	add	r0, r1
	cbz	r0, .L08002e1c
	add	r0, r1
	cbnz	r0, .L08002e4c
	b.n	.L08002e24
.L08002e00:
	ldr	r0, .L08002e64
	add	r0, r1
	cbz	r0, .L08002e34
	ldr	r1, .L08002e64
	add	r0, r1
	cbz	r0, .L08002e3c
	add	r0, r1
	cbnz	r0, .L08002e4c
	b.n	.L08002e44
.L08002e12:
	mov.w	r0, #1
	bl	fn_0800184c
	b.n	.L08002e4e
.L08002e1c:
	movs	r0, #0
	bl	fn_0800184c
	b.n	.L08002e4e
.L08002e24:
	movs	r0, #3
	bl	fn_0800184c
	b.n	.L08002e4e
.L08002e2c:
	movs	r0, #2
	bl	fn_0800184c
	b.n	.L08002e4e
.L08002e34:
	movs	r0, #5
	bl	fn_0800184c
	b.n	.L08002e4e
.L08002e3c:
	movs	r0, #4
	bl	fn_0800184c
	b.n	.L08002e4e
.L08002e44:
	movs	r0, #6
	bl	fn_0800184c
	b.n	.L08002e4e
.L08002e4c:
	nop
.L08002e4e:
	nop
.L08002e50:
	pop	{r4, pc}
	.short	0x0000	@ padding
.L08002e54:
	.word	0x00180016
.L08002e58:
	.word	0x200000c4
.L08002e5c:
	.word	0x07270e00
.L08002e60:
	.word	0xfd239400
.L08002e64:
	.word	0xfe91ca00

