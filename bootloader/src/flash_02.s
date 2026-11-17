@ flash_02.s - flash:option-byte check, flash status polling, byte program and buffer compare/write routines.
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08001938 - reads the halfword at 0x1FFFF810 (option byte area). If its low
@ byte is not 0xFE it calls flash_unlock_keys (0x080022A4),
@ flash_option_erase_then_write_a5 (0x080022C4),
@ flash_option_program_halfword(0x1FFFF810, 0xFE) (0x0800235C) and then
@ system_reset (0x08002BCC, no return). If it is 0xFE nothing is done.
@ Called from the reset handler 0x08000264 before RAM is set up
@ (BOOTLOADER.md point 2). Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001938,"ax",%progbits
	.p2align 2
	.global fn_08001938
	.thumb_func
	.type fn_08001938, %function
fn_08001938:
	push	{r4, lr}
	ldr	r0, .L0800195c
	ldrh	r0, [r0, #0]
	uxtb	r0, r0
	cmp	r0, #0xfe
	beq.n	.L08001958
	bl	flash_unlock_keys
	bl	flash_option_erase_then_write_a5
	movs	r1, #0xfe
	ldr	r0, .L0800195c
	bl	flash_option_program_halfword
	bl	system_reset
.L08001958:
	pop	{r4, pc}
	.short	0x0000			@ padding
.L0800195c:
	.word	0x1FFFF810

@ ----------------------------------------------------------------------------
@ read_flash_status_bank1 - reads the word at 0x4002200C: returns 0 if bit 0 is
@ set, else 1 if bit 2 is set, else 2 if bit 4 is set, else 3.
@ Callers 0x080019E2 and 0x080019EA (wait_flash_status_bank1).
@ ----------------------------------------------------------------------------
	.section .text.read_flash_status_bank1,"ax",%progbits
	.p2align 2
	.global read_flash_status_bank1
	.thumb_func
	.type read_flash_status_bank1, %function
read_flash_status_bank1:
	movs	r0, #3
	ldr	r1, .L080019d8
	ldr	r1, [r1, #0xc]
	and.w	r1, r1, #1
	cbz	r1, .L080019b8
	movs	r0, #0
	b.n	.L080019d6
.L080019b8:
	ldr	r1, .L080019d8
	ldr	r1, [r1, #0xc]
	ubfx	r1, r1, #2, #1
	cbz	r1, .L080019c6
	movs	r0, #1
	b.n	.L080019d6
.L080019c6:
	ldr	r1, .L080019d8
	ldr	r1, [r1, #0xc]
	ubfx	r1, r1, #4, #1
	cbz	r1, .L080019d4
	movs	r0, #2
	b.n	.L080019d6
.L080019d4:
	movs	r0, #3
.L080019d6:
	bx	lr
.L080019d8:
	.word	0x40022000

@ ----------------------------------------------------------------------------
@ wait_flash_status_bank1 - r0 = poll budget. Calls read_flash_status_bank1
@ (0x080019A8) first; while the result is 0 and the budget is not 0 calls it
@ again and decrements the budget; returns the last status, but returns 4 when
@ the budget is 0 at the end (also when the status became nonzero on the last
@ poll). Callers 0x08001A80 (budget 0x100000), 0x080021A0, 0x080023EC.
@ ----------------------------------------------------------------------------
	.section .text.wait_flash_status_bank1,"ax",%progbits
	.p2align 2
	.global wait_flash_status_bank1
	.thumb_func
	.type wait_flash_status_bank1, %function
wait_flash_status_bank1:
	push	{lr}
	mov	r2, r0
	movs	r3, #3
	bl	read_flash_status_bank1
	mov	r3, r0
	b.n	.L080019f2
.L080019ea:
	bl	read_flash_status_bank1
	mov	r3, r0
	.inst.n	0x1e52			@ subs r2, r2, #1
.L080019f2:
	cbnz	r3, .L080019f8
	cmp	r2, #0
	bne.n	.L080019ea
.L080019f8:
	cbnz	r2, .L080019fc
	movs	r3, #4
.L080019fc:
	mov	r0, r3
	pop	{pc}

@ ----------------------------------------------------------------------------
@ read_flash_status_bank2 - same code as read_flash_status_bank1 for the word at
@ 0x4002204C (0 if bit 0, 1 if bit 2, 2 if bit 4, else 3).
@ Callers 0x08001A3A and 0x08001A42 (wait_flash_status_bank2).
@ ----------------------------------------------------------------------------
	.section .text.read_flash_status_bank2,"ax",%progbits
	.p2align 2
	.global read_flash_status_bank2
	.thumb_func
	.type read_flash_status_bank2, %function
read_flash_status_bank2:
	movs	r0, #3
	ldr	r1, .L08001a30
	ldr	r1, [r1, #0x4c]
	and.w	r1, r1, #1
	cbz	r1, .L08001a10
	movs	r0, #0
	b.n	.L08001a2e
.L08001a10:
	ldr	r1, .L08001a30
	ldr	r1, [r1, #0x4c]
	ubfx	r1, r1, #2, #1
	cbz	r1, .L08001a1e
	movs	r0, #1
	b.n	.L08001a2e
.L08001a1e:
	ldr	r1, .L08001a30
	ldr	r1, [r1, #0x4c]
	ubfx	r1, r1, #4, #1
	cbz	r1, .L08001a2c
	movs	r0, #2
	b.n	.L08001a2e
.L08001a2c:
	movs	r0, #3
.L08001a2e:
	bx	lr
.L08001a30:
	.word	0x40022000

@ ----------------------------------------------------------------------------
@ wait_flash_status_bank2 - same code as wait_flash_status_bank1 with
@ read_flash_status_bank2 (0x08001A00) as the status read.
@ Callers 0x08001AB6 (budget 0x100000), 0x080021E0, 0x08002422.
@ ----------------------------------------------------------------------------
	.section .text.wait_flash_status_bank2,"ax",%progbits
	.p2align 2
	.global wait_flash_status_bank2
	.thumb_func
	.type wait_flash_status_bank2, %function
wait_flash_status_bank2:
	push	{lr}
	mov	r2, r0
	movs	r3, #3
	bl	read_flash_status_bank2
	mov	r3, r0
	b.n	.L08001a4a
.L08001a42:
	bl	read_flash_status_bank2
	mov	r3, r0
	.inst.n	0x1e52			@ subs r2, r2, #1
.L08001a4a:
	cbnz	r3, .L08001a50
	cmp	r2, #0
	bne.n	.L08001a42
.L08001a50:
	cbnz	r2, .L08001a54
	movs	r3, #4
.L08001a54:
	mov	r0, r3
	pop	{pc}

@ ----------------------------------------------------------------------------
@ fn_08001a58 - r0 = address, r1 = byte. Returns 3 by default.
@ If 0x08000000 <= r0 <= 0x0807FFFF: sets bit 0 of 0x40022010, stores the byte
@ at r0 (strb at 0x08001A7A), waits with wait_flash_status_bank1(0x100000)
@ (0x080019DC), clears bit 0 of 0x40022010, returns the wait result.
@ If 0x08080000 <= r0 < 0x08100000: the same with 0x40022050 and
@ wait_flash_status_bank2 (0x08001A34).
@ Any other address: returns 3 with no write. Caller 0x080024F8.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001a58,"ax",%progbits
	.p2align 2
	.global fn_08001a58
	.thumb_func
	.type fn_08001a58, %function
fn_08001a58:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	movs	r6, #3
	cmp.w	r4, #0x8000000
	bcc.n	.L08001a94
	ldr	r0, .L08001acc
	cmp	r4, r0
	bhi.n	.L08001a94
	ldr	r0, .L08001ad0
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #1
	.inst.n	0x1c40			@ adds r0, r0, #1
	ldr	r1, .L08001ad0
	str	r0, [r1, #0x10]
	strb	r5, [r4, #0]
	mov.w	r0, #0x100000
	bl	wait_flash_status_bank1
	mov	r6, r0
	ldr	r0, .L08001ad0
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #1
	ldr	r1, .L08001ad0
	str	r0, [r1, #0x10]
	b.n	.L08001ac8
.L08001a94:
	ldr	r0, .L08001acc
	.inst.n	0x1c40			@ adds r0, r0, #1
	cmp	r4, r0
	bcc.n	.L08001ac8
	cmp.w	r4, #0x8100000
	bcs.n	.L08001ac8
	ldr	r0, .L08001ad0
	ldr	r0, [r0, #0x50]
	bic.w	r0, r0, #1
	.inst.n	0x1c40			@ adds r0, r0, #1
	ldr	r1, .L08001ad0
	str	r0, [r1, #0x50]
	strb	r5, [r4, #0]
	mov.w	r0, #0x100000
	bl	wait_flash_status_bank2
	mov	r6, r0
	ldr	r0, .L08001ad0
	ldr	r0, [r0, #0x50]
	bic.w	r0, r0, #1
	ldr	r1, .L08001ad0
	str	r0, [r1, #0x50]
.L08001ac8:
	mov	r0, r6
	pop	{r4, r5, r6, pc}
.L08001acc:
	.word	0x0807FFFF
.L08001ad0:
	.word	0x40022000

@ ----------------------------------------------------------------------------
@ fn_08001ad4 - r0 = pointer to the stored data, r1 = source buffer,
@ r2 = byte count. Sets bit 6 of 0x40021014 (set_or_clear_bit_40021000_offset
@ (0x140006, 1), 0x080016DC); words = r2 >> 2, plus 1 when r2 & 3, and then
@ writes 0xFF into the (4 - (r2 & 3)) bytes after the count in the source
@ buffer; resets with set_40023008_bit0 (0x08001550), writes every source word
@ to 0x40023000 with write_40023000_read_back (0x08001564, keeps the last
@ read-back); resets again, does the same for the words at r0; clears bit 6 of
@ 0x40021014; returns 1 if the two last read-back values differ, else 0.
@ Caller 0x0800250E.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001ad4,"ax",%progbits
	.p2align 2
	.global fn_08001ad4
	.thumb_func
	.type fn_08001ad4, %function
fn_08001ad4:
	push.w	{r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	mov	r8, r0
	mov	r6, r1
	mov	r5, r2
	mov.w	r11, #0
	movs	r0, #0
	str	r0, [sp, #4]
	movs	r4, #0
	lsrs	r7, r5, #2
	and.w	r9, r5, #3
	str	r6, [sp, #0]
	mov	r10, r8
	movs	r1, #1
	ldr	r0, .L08001b60
	bl	set_or_clear_bit_40021000_offset
	cmp.w	r9, #0
	beq.n	.L08001b16
	.inst.n	0x1c7f			@ adds r7, r7, #1
	nop
	b.n	.L08001b0e
.L08001b06:
	movs	r0, #0xff
	adds	r1, r5, r4
	strb	r0, [r6, r1]
	.inst.n	0x1c64			@ adds r4, r4, #1
.L08001b0e:
	rsb.w	r0, r9, #4
	cmp	r0, r4
	bhi.n	.L08001b06
.L08001b16:
	bl	set_40023008_bit0
	movs	r4, #0
	b.n	.L08001b2c
.L08001b1e:
	ldr	r1, [sp, #0]
	ldr.w	r0, [r1, r4, lsl #2]
	bl	write_40023000_read_back
	str	r0, [sp, #4]
	.inst.n	0x1c64			@ adds r4, r4, #1
.L08001b2c:
	cmp	r4, r7
	bcc.n	.L08001b1e
	bl	set_40023008_bit0
	movs	r4, #0
	b.n	.L08001b44
.L08001b38:
	ldr.w	r0, [r10], #4
	bl	write_40023000_read_back
	mov	r11, r0
	.inst.n	0x1c64			@ adds r4, r4, #1
.L08001b44:
	cmp	r4, r7
	bcc.n	.L08001b38
	movs	r1, #0
	ldr	r0, .L08001b60
	bl	set_or_clear_bit_40021000_offset
	ldr	r0, [sp, #4]
	cmp	r0, r11
	beq.n	.L08001b5c
	movs	r0, #1
.L08001b58:
	pop.w	{r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, pc}
.L08001b5c:
	movs	r0, #0
	b.n	.L08001b58
.L08001b60:
	.word	0x00140006

@ ----------------------------------------------------------------------------
@ read_bit1_4002201c - returns bit 1 of the word at 0x4002201C ((v & 3) >> 1).
@ Caller 0x080022CA.
@ ----------------------------------------------------------------------------
	.section .text.read_bit1_4002201c,"ax",%progbits
	.p2align 2
	.global read_bit1_4002201c
	.thumb_func
	.type read_bit1_4002201c, %function
read_bit1_4002201c:
	ldr	r0, .L08001b70
	ldr	r0, [r0, #0x1c]
	ubfx	r0, r0, #1, #1
	bx	lr
	.short	0x0000			@ padding
.L08001b70:
	.word	0x40022000

@ ----------------------------------------------------------------------------
@ fn_080020f8 - sets bit 7 of the word at 0x40022010 and bit 7 of the word at
@ 0x40022050. Callers 0x08001CCC, 0x080020A2, 0x080024E0, 0x08002504.
@ ----------------------------------------------------------------------------
	.section .text.fn_080020f8,"ax",%progbits
	.p2align 2
	.global fn_080020f8
	.thumb_func
	.type fn_080020f8, %function
fn_080020f8:
	ldr	r0, .L08002114
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #0x80
	adds	r0, #0x80
	ldr	r1, .L08002114
	str	r0, [r1, #0x10]
	mov	r0, r1
	ldr	r0, [r0, #0x50]
	bic.w	r0, r0, #0x80
	adds	r0, #0x80
	str	r0, [r1, #0x50]
	bx	lr
.L08002114:
	.word	0x40022000

@ ----------------------------------------------------------------------------
@ fn_08002118 - same code as read_flash_status_bank1 (0x080019A8): reads the
@ word at 0x4002200C and returns 0 if bit 0 is set, else 1 if bit 2 is set,
@ else 2 if bit 4 is set, else 3. Callers 0x08002152 and 0x0800215A.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002118,"ax",%progbits
	.p2align 2
	.global fn_08002118
	.thumb_func
	.type fn_08002118, %function
fn_08002118:
	movs	r0, #3
	ldr	r1, .L08002148
	ldr	r1, [r1, #0xc]
	and.w	r1, r1, #1
	cbz	r1, .L08002128
	movs	r0, #0
	b.n	.L08002146
.L08002128:
	ldr	r1, .L08002148
	ldr	r1, [r1, #0xc]
	ubfx	r1, r1, #2, #1
	cbz	r1, .L08002136
	movs	r0, #1
	b.n	.L08002146
.L08002136:
	ldr	r1, .L08002148
	ldr	r1, [r1, #0xc]
	ubfx	r1, r1, #4, #1
	cbz	r1, .L08002144
	movs	r0, #2
	b.n	.L08002146
.L08002144:
	movs	r0, #3
.L08002146:
	bx	lr
.L08002148:
	.word	0x40022000

@ ----------------------------------------------------------------------------
@ flash_wait_op_a - polls the flash status word at 0x4002200C through
@ fn_08002118 (0x08002118): r0 = poll budget (kept in r2).
@ Calls fn_08002118 once, then repeats the call while the result is 0 and the
@ budget is not 0, decrementing the budget after each repeat.
@ fn_08002118 returns 0 when bit 0 of 0x4002200C is set, else 1 when bit 2 is
@ set, else 2 when bit 4 is set, else 3.
@ Returns 4 when the budget is 0 at the end (also when the first result was not
@ 0 and r0 was 0), otherwise the last status code (3 = none of bits 0, 2, 4 set).
@ Callers: 0x08002306, 0x08002334, 0x0800239e (option-byte erase and program
@ with budgets 0x40000000 and 0x100000).
@ ----------------------------------------------------------------------------
	.section .text.flash_wait_op_a,"ax",%progbits
	.p2align 2
	.global flash_wait_op_a
	.thumb_func
	.type flash_wait_op_a, %function
flash_wait_op_a:
	push	{lr}
	mov	r2, r0
	movs	r3, #3
	bl	fn_08002118
	mov	r3, r0
	b.n	.L08002162
.L0800215a:
	bl	fn_08002118
	mov	r3, r0
	.inst.n	0x1e52			@ subs r2, r2, #1
.L08002162:
	cbnz	r3, .L08002168
	cmp	r2, #0
	bne.n	.L0800215a
.L08002168:
	cbnz	r2, .L0800216c
	movs	r3, #4
.L0800216c:
	mov	r0, r3
	pop	{pc}

@ ----------------------------------------------------------------------------
@ flash_erase_sector - erases the flash sector whose address is r0, selecting
@ the register set by address range.
@ 0x08000000..0x0807ffff: sets bit 1 of 0x40022010, writes r0 to 0x40022014,
@ sets bit 6 of 0x40022010, waits with wait_flash_status_bank1(0x40000000)
@ (0x080019dc), clears bit 1 of 0x40022010.
@ 0x08080000..0x080fffff: same with 0x40022050 / 0x40022054 and wait
@ wait_flash_status_bank2(0x40000000) (0x08001a34).
@ r0 >= 0x08400000: same with 0x40022090 / 0x40022094 and wait
@ flash_wait_op_c(0xffffffff) (0x08002280).
@ Any other address (including 0x08100000..0x083fffff): nothing is written and
@ the return value stays 3.
@ Returns the wait result (3 = no status flag set, 4 = budget exhausted) or 3
@ for an unmatched address.
@ Callers: 0x08001cc8, 0x080024b8, 0x080024d4, 0x080024dc.
@ ----------------------------------------------------------------------------
	.section .text.flash_erase_sector,"ax",%progbits
	.p2align 2
	.global flash_erase_sector
	.thumb_func
	.type flash_erase_sector, %function
flash_erase_sector:
	push	{r4, r5, lr}
	mov	r4, r0
	movs	r5, #3
	cmp.w	r4, #0x8000000
	bcc.n	.L080021b4
	ldr	r0, .L08002244
	cmp	r4, r0
	bhi.n	.L080021b4
	ldr	r0, .L08002248
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #2
	.inst.n	0x1c80			@ adds r0, r0, #2
	ldr	r1, .L08002248
	str	r0, [r1, #0x10]
	mov	r0, r1
	str	r4, [r0, #0x14]
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #0x40
	adds	r0, #0x40
	str	r0, [r1, #0x10]
	lsls	r0, r1, #17		@ halfword 0x0448 (the budget 0x40000000 is not built here)
	bl	wait_flash_status_bank1
	mov	r5, r0
	ldr	r0, .L08002248
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #2
	ldr	r1, .L08002248
	str	r0, [r1, #0x10]
	b.n	.L0800223e
.L080021b4:
	ldr	r0, .L08002244
	.inst.n	0x1c40			@ adds r0, r0, #1
	cmp	r4, r0
	bcc.n	.L080021f4
	cmp.w	r4, #0x8100000
	bcs.n	.L080021f4
	ldr	r0, .L08002248
	ldr	r0, [r0, #0x50]
	bic.w	r0, r0, #2
	.inst.n	0x1c80			@ adds r0, r0, #2
	ldr	r1, .L08002248
	str	r0, [r1, #0x50]
	mov	r0, r1
	str	r4, [r0, #0x54]
	ldr	r0, [r0, #0x50]
	bic.w	r0, r0, #0x40
	adds	r0, #0x40
	str	r0, [r1, #0x50]
	lsls	r0, r1, #17		@ halfword 0x0448
	bl	wait_flash_status_bank2
	mov	r5, r0
	ldr	r0, .L08002248
	ldr	r0, [r0, #0x50]
	bic.w	r0, r0, #2
	ldr	r1, .L08002248
	str	r0, [r1, #0x50]
	b.n	.L0800223e
.L080021f4:
	cmp.w	r4, #0x8400000
	bcc.n	.L0800223e
	ldr	r0, .L08002248
	adds	r0, #0x90
	ldr	r0, [r0, #0]
	bic.w	r0, r0, #2
	.inst.n	0x1c80			@ adds r0, r0, #2
	ldr	r1, .L08002248
	str.w	r0, [r1, #0x90]
	mov	r0, r1
	str.w	r4, [r0, #0x94]
	ldr	r0, .L08002248
	adds	r0, #0x90
	ldr	r0, [r0, #0]
	bic.w	r0, r0, #0x40
	adds	r0, #0x40
	ldr	r1, .L08002248
	adds	r1, #0x90
	str	r0, [r1, #0]
	mov.w	r0, #0xffffffff
	bl	flash_wait_op_c
	mov	r5, r0
	ldr	r0, .L08002248
	ldr.w	r0, [r0, #0x90]
	bic.w	r0, r0, #2
	ldr	r1, .L08002248
	adds	r1, #0x90
	str	r0, [r1, #0]
.L0800223e:
	mov	r0, r5
	pop	{r4, r5, pc}
	.short	0x0000			@ padding
.L08002244:
	.word	0x0807FFFF
.L08002248:
	.word	0x40022000

@ ----------------------------------------------------------------------------
@ flash_status_code_c - decodes the flash status word at 0x4002208C: returns 0
@ when bit 0 is set, else 1 when bit 2 is set, else 2 when bit 4 is set, else
@ 3. No parameters, no writes. Called only by flash_wait_op_c (0x08002280).
@ Same decode as fn_08002118 (word 0x4002200C) and read_flash_status_bank2
@ (0x08001a00, word 0x4002204C).
@ ----------------------------------------------------------------------------
	.section .text.flash_status_code_c,"ax",%progbits
	.p2align 2
	.global flash_status_code_c
	.thumb_func
	.type flash_status_code_c, %function
flash_status_code_c:
	movs	r0, #3
	ldr	r1, .L0800227c
	ldr	r1, [r1, #0]
	and.w	r1, r1, #1
	cbz	r1, .L0800225c
	movs	r0, #0
	b.n	.L0800227a
.L0800225c:
	ldr	r1, .L0800227c
	ldr	r1, [r1, #0]
	ubfx	r1, r1, #2, #1
	cbz	r1, .L0800226a
	movs	r0, #1
	b.n	.L0800227a
.L0800226a:
	ldr	r1, .L0800227c
	ldr	r1, [r1, #0]
	ubfx	r1, r1, #4, #1
	cbz	r1, .L08002278
	movs	r0, #2
	b.n	.L0800227a
.L08002278:
	movs	r0, #3
.L0800227a:
	bx	lr
.L0800227c:
	.word	0x4002208C

@ ----------------------------------------------------------------------------
@ flash_wait_op_c - polls the flash status word at 0x4002208C through
@ flash_status_code_c (0x0800224c): r0 = poll budget (kept in r2).
@ Calls flash_status_code_c once, then repeats while the result is 0 and the
@ budget is not 0, decrementing the budget after each repeat; returns 4 when
@ the budget is 0 at the end, else the last status code.
@ Same loop as flash_wait_op_a (0x0800214c, word 0x4002200C) and
@ wait_flash_status_bank1 (0x080019dc).
@ Callers: 0x08002228 (erase, budget 0xffffffff) and 0x08002454 (word program,
@ budget 0x100000).
@ ----------------------------------------------------------------------------
	.section .text.flash_wait_op_c,"ax",%progbits
	.p2align 2
	.global flash_wait_op_c
	.thumb_func
	.type flash_wait_op_c, %function
flash_wait_op_c:
	push	{lr}
	mov	r2, r0
	movs	r3, #3
	bl	flash_status_code_c
	mov	r3, r0
	b.n	.L08002296
.L0800228e:
	bl	flash_status_code_c
	mov	r3, r0
	.inst.n	0x1e52			@ subs r2, r2, #1
.L08002296:
	cbnz	r3, .L0800229c
	cmp	r2, #0
	bne.n	.L0800228e
.L0800229c:
	cbnz	r2, .L080022a0
	movs	r3, #4
.L080022a0:
	mov	r0, r3
	pop	{pc}

@ ----------------------------------------------------------------------------
@ flash_unlock_keys - writes the key pair 0x45670123 then 0xcdef89ab to
@ 0x40022004 and again to 0x40022044. No parameters, no return value.
@ Callers: 0x08001944 (start-up option-byte check), 0x08001cba, 0x0800208e,
@ 0x080024a8, 0x080024e6.
@ ----------------------------------------------------------------------------
	.section .text.flash_unlock_keys,"ax",%progbits
	.p2align 2
	.global flash_unlock_keys
	.thumb_func
	.type flash_unlock_keys, %function
flash_unlock_keys:
	ldr	r0, .L080022b8
	ldr	r1, .L080022bc
	str	r0, [r1, #4]
	ldr	r0, .L080022c0
	str	r0, [r1, #4]
	ldr	r0, .L080022b8
	str	r0, [r1, #0x44]
	ldr	r0, .L080022c0
	str	r0, [r1, #0x44]
	bx	lr
.L080022b8:
	.word	0x45670123
.L080022bc:
	.word	0x40022000
.L080022c0:
	.word	0xCDEF89AB

@ ----------------------------------------------------------------------------
@ flash_option_erase_then_write_a5 - erases the option-byte area and writes
@ 0xa5 to the halfword 0x1ffff800.
@ Reads read_bit1_4002201c (0x08001b64, bit 1 of the word 0x4002201C); if that
@ bit is set the value to write is 0, else 0xa5.
@ Writes the keys 0x45670123 / 0xcdef89ab to 0x40022008, waits until bit 9 of
@ 0x40022010 is set, sets bit 5 then bit 6 of 0x40022010 (erase and start),
@ waits with flash_wait_op_a(0x40000000) (0x0800214c), clears bit 5.
@ The erase runs in both cases.
@ Only when the erase result is 3 and the value is 0xa5: sets bit 4 of
@ 0x40022010, stores halfword 0xa5 at 0x1ffff800, waits with
@ flash_wait_op_a(0x100000), clears bit 4.
@ Returns the last wait result. Caller: 0x08001948 (fn_08001938).
@ ----------------------------------------------------------------------------
	.section .text.flash_option_erase_then_write_a5,"ax",%progbits
	.p2align 2
	.global flash_option_erase_then_write_a5
	.thumb_func
	.type flash_option_erase_then_write_a5, %function
flash_option_erase_then_write_a5:
	push	{r4, r5, lr}
	movs	r4, #3
	movs	r5, #0xa5
	bl	read_bit1_4002201c
	cbz	r0, .L080022d2
	movs	r5, #0
.L080022d2:
	ldr	r0, .L0800234c
	ldr	r1, .L08002350
	str	r0, [r1, #8]
	ldr	r0, .L08002354
	str	r0, [r1, #8]
	nop
.L080022de:
	ldr	r0, .L08002350
	ldr	r0, [r0, #0x10]
	ubfx	r0, r0, #9, #1
	cmp	r0, #0
	beq.n	.L080022de
	ldr	r0, .L08002350
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #0x20
	adds	r0, #0x20
	ldr	r1, .L08002350
	str	r0, [r1, #0x10]
	mov	r0, r1
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #0x40
	adds	r0, #0x40
	str	r0, [r1, #0x10]
	lsls	r0, r1, #17		@ halfword 0x0448
	bl	flash_wait_op_a
	mov	r4, r0
	ldr	r0, .L08002350
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #0x20
	ldr	r1, .L08002350
	str	r0, [r1, #0x10]
	cmp	r4, #3
	bne.n	.L08002346
	cmp	r5, #0xa5
	bne.n	.L08002346
	mov	r0, r1
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #0x10
	adds	r0, #0x10
	str	r0, [r1, #0x10]
	ldr	r0, .L08002358
	strh	r5, [r0, #0]
	mov.w	r0, #0x100000
	bl	flash_wait_op_a
	mov	r4, r0
	ldr	r0, .L08002350
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #0x10
	ldr	r1, .L08002350
	str	r0, [r1, #0x10]
.L08002346:
	mov	r0, r4
	pop	{r4, r5, pc}
	.short	0x0000			@ padding
.L0800234c:
	.word	0x45670123
.L08002350:
	.word	0x40022000
.L08002354:
	.word	0xCDEF89AB
.L08002358:
	.word	0x1FFFF800

@ ----------------------------------------------------------------------------
@ flash_option_program_halfword - programs one halfword in the option-byte
@ area: r0 = address, r1 = value.
@ Returns 3 without writing when r0 == 0x1ffff800 and r1 != 0xa5.
@ Otherwise writes the keys 0x45670123 / 0xcdef89ab to 0x40022008, waits until
@ bit 9 of 0x40022010 is set, sets bit 4 of 0x40022010, stores the halfword r1
@ at r0, waits with flash_wait_op_a(0x100000) (0x0800214c), clears bit 4,
@ returns the wait result.
@ Caller: 0x08001950 (start-up: writes 0xfe at 0x1ffff810 per BOOTLOADER.md
@ point 2).
@ ----------------------------------------------------------------------------
	.section .text.flash_option_program_halfword,"ax",%progbits
	.p2align 2
	.global flash_option_program_halfword
	.thumb_func
	.type flash_option_program_halfword, %function
flash_option_program_halfword:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	movs	r6, #3
	ldr	r0, .L080023b4
	cmp	r4, r0
	bne.n	.L08002372
	cmp	r5, #0xa5
	beq.n	.L08002372
	movs	r0, #3
.L08002370:
	pop	{r4, r5, r6, pc}
.L08002372:
	ldr	r0, .L080023b8
	ldr	r1, .L080023bc
	str	r0, [r1, #8]
	ldr	r0, .L080023c0
	str	r0, [r1, #8]
	nop
.L0800237e:
	ldr	r0, .L080023bc
	ldr	r0, [r0, #0x10]
	ubfx	r0, r0, #9, #1
	cmp	r0, #0
	beq.n	.L0800237e
	ldr	r0, .L080023bc
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #0x10
	adds	r0, #0x10
	ldr	r1, .L080023bc
	str	r0, [r1, #0x10]
	strh	r5, [r4, #0]
	mov.w	r0, #0x100000
	bl	flash_wait_op_a
	mov	r6, r0
	ldr	r0, .L080023bc
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #0x10
	ldr	r1, .L080023bc
	str	r0, [r1, #0x10]
	mov	r0, r6
	b.n	.L08002370
.L080023b4:
	.word	0x1FFFF800
.L080023b8:
	.word	0x45670123
.L080023bc:
	.word	0x40022000
.L080023c0:
	.word	0xCDEF89AB

@ ----------------------------------------------------------------------------
@ flash_program_word - programs one 32-bit word: r0 = address, r1 = value.
@ 0x08000000..0x0807ffff: sets bit 0 of 0x40022010, stores r1 at r0, waits with
@ wait_flash_status_bank1(0x100000) (0x080019dc), clears bit 0.
@ 0x08080000..0x080fffff: same with 0x40022050 and wait
@ wait_flash_status_bank2(0x100000) (0x08001a34).
@ r0 >= 0x08400000: same with 0x40022090 and wait flash_wait_op_c(0x100000)
@ (0x08002280).
@ Any other address: nothing written, returns 3. Returns the wait result.
@ Caller: 0x0800209e (value 0x41544b38 from the literal at 0x080020ac; address
@ = word 0x20000418 minus word 0x20000424, 0x08006800 when the sector size is
@ 0x800).
@ ----------------------------------------------------------------------------
	.section .text.flash_program_word,"ax",%progbits
	.p2align 2
	.global flash_program_word
	.thumb_func
	.type flash_program_word, %function
flash_program_word:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	movs	r6, #3
	cmp.w	r4, #0x8000000
	bcc.n	.L08002400
	ldr	r0, .L08002470
	cmp	r4, r0
	bhi.n	.L08002400
	ldr	r0, .L08002474
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #1
	.inst.n	0x1c40			@ adds r0, r0, #1
	ldr	r1, .L08002474
	str	r0, [r1, #0x10]
	str	r5, [r4, #0]
	mov.w	r0, #0x100000
	bl	wait_flash_status_bank1
	mov	r6, r0
	ldr	r0, .L08002474
	ldr	r0, [r0, #0x10]
	bic.w	r0, r0, #1
	ldr	r1, .L08002474
	str	r0, [r1, #0x10]
	b.n	.L0800246a
.L08002400:
	ldr	r0, .L08002470
	.inst.n	0x1c40			@ adds r0, r0, #1
	cmp	r4, r0
	bcc.n	.L08002436
	cmp.w	r4, #0x8100000
	bcs.n	.L08002436
	ldr	r0, .L08002474
	ldr	r0, [r0, #0x50]
	bic.w	r0, r0, #1
	.inst.n	0x1c40			@ adds r0, r0, #1
	ldr	r1, .L08002474
	str	r0, [r1, #0x50]
	str	r5, [r4, #0]
	mov.w	r0, #0x100000
	bl	wait_flash_status_bank2
	mov	r6, r0
	ldr	r0, .L08002474
	ldr	r0, [r0, #0x50]
	bic.w	r0, r0, #1
	ldr	r1, .L08002474
	str	r0, [r1, #0x50]
	b.n	.L0800246a
.L08002436:
	cmp.w	r4, #0x8400000
	bcc.n	.L0800246a
	ldr	r0, .L08002474
	adds	r0, #0x90
	ldr	r0, [r0, #0]
	bic.w	r0, r0, #1
	.inst.n	0x1c40			@ adds r0, r0, #1
	ldr	r1, .L08002474
	adds	r1, #0x90
	str	r0, [r1, #0]
	str	r5, [r4, #0]
	mov.w	r0, #0x100000
	bl	flash_wait_op_c
	mov	r6, r0
	ldr	r0, .L08002474
	ldr.w	r0, [r0, #0x90]
	bic.w	r0, r0, #1
	ldr	r1, .L08002474
	str.w	r0, [r1, #0x90]
.L0800246a:
	mov	r0, r6
	pop	{r4, r5, r6, pc}
	.short	0x0000			@ padding
.L08002470:
	.word	0x0807FFFF
.L08002474:
	.word	0x40022000

@ ----------------------------------------------------------------------------
@ fn_08002478 - flash write of one data block: r0 = target address,
@ r1 = source buffer, r2 = length.
@ RAM words used: 0x20000414 (0x08000000), 0x2000041c (flash size in bytes),
@ 0x20000424 (sector size), 0x20000428 (sector size - 1), all set by
@ 0x08001cd8.
@ Returns 1 at once when 0x20000414 + 0x2000041c < r0 + r2.
@ When (0x20000428 & r0) == 0: unlocks with flash_unlock_keys (0x080022a4),
@ erases with flash_erase_sector (0x08002170) (if the length is larger than the
@ sector size, one call per whole sector while the remaining length >= sector
@ size, then one more call when a remainder is left; otherwise one call at r0),
@ then calls fn_080020f8 (0x080020f8).
@ Always: unlocks (flash_unlock_keys; the second unlock when the first branch
@ ran), calls fn_08001a58 (0x08001a58) (r0 + i, byte i) for i < r2, calls
@ fn_080020f8, returns fn_08001ad4 (0x08001ad4) (r0, r1, r2).
@ Erase and program results are not tested.
@ Caller: 0x08001fca.
@ fn_080020f8 sets bit 7 of 0x40022010 and of 0x40022050.
@ Purpose not determined from the code beyond these mechanics.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002478,"ax",%progbits
	.p2align 2
	.global fn_08002478
	.thumb_func
	.type fn_08002478, %function
fn_08002478:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r6, r0
	mov	r9, r1
	mov	r4, r2
	mov	r5, r6
	mov	r7, r4
	mov.w	r8, #0
	ldr	r0, .L08002514
	ldr	r0, [r0, #0]
	ldr	r1, .L08002514
	ldr	r1, [r1, #8]
	add	r0, r1
	adds	r1, r6, r4
	cmp	r0, r1
	bcs.n	.L080024a0
	movs	r0, #1
.L0800249c:
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
.L080024a0:
	ldr	r0, .L08002514
	ldr	r0, [r0, #0x14]
	ands	r0, r5
	cbnz	r0, .L080024e4
	bl	flash_unlock_keys
	ldr	r0, .L08002514
	ldr	r0, [r0, #0x10]
	cmp	r0, r4
	bcs.n	.L080024da
	b.n	.L080024c8
.L080024b6:
	mov	r0, r5
	bl	flash_erase_sector
	ldr	r0, .L08002514
	ldr	r0, [r0, #0x10]
	add	r5, r0
	ldr	r0, .L08002514
	ldr	r0, [r0, #0x10]
	subs	r7, r7, r0
.L080024c8:
	ldr	r0, .L08002514
	ldr	r0, [r0, #0x10]
	cmp	r0, r7
	bls.n	.L080024b6
	cbz	r7, .L080024e0
	mov	r0, r5
	bl	flash_erase_sector
	b.n	.L080024e0
.L080024da:
	mov	r0, r5
	bl	flash_erase_sector
.L080024e0:
	bl	fn_080020f8
.L080024e4:
	mov	r5, r6
	bl	flash_unlock_keys
	mov.w	r8, #0
	b.n	.L08002500
.L080024f0:
	ldrb.w	r1, [r9, r8]
	add.w	r0, r5, r8
	bl	fn_08001a58
	add.w	r8, r8, #1
.L08002500:
	cmp	r8, r4
	bcc.n	.L080024f0
	bl	fn_080020f8
	mov	r2, r4
	mov	r1, r9
	mov	r0, r6
	bl	fn_08001ad4
	b.n	.L0800249c
.L08002514:
	.word	0x20000414
