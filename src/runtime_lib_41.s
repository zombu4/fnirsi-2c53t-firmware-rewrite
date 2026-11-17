@ runtime_lib_41.s - runtime library: byte/string compare, search, copy and fill helpers, locale-state accessors, digit parsing
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ compare_bytes - memcmp-style compare.
@ r0 = pointer A, r1 = pointer B, r2 = count.
@ When both pointers are word aligned and at least 4 bytes remain, compares
@ 4 bytes at a time; on a difference the two words are byte-swapped (rev) and
@ compared unsigned, returning 1 (A greater) or -1 (A smaller). Remaining
@ bytes (and unaligned input) are compared one byte at a time (two per loop
@ pass); returns the first byte difference (A minus B), or 0 when equal.
@ ----------------------------------------------------------------------------
	.section .text.compare_bytes,"ax",%progbits
	.global compare_bytes
	.thumb_func
	.type compare_bytes, %function
compare_bytes:
	orr.w	r3, r0, r1
	push	{r4, lr}
	lsls	r3, r3, #0x1e
	bne.n	.L08007766
.L08007746:
	cmp	r2, #0x4
	bcc.n	.L08007766
	ldmia	r0!, {r4}
	ldmia	r1!, {r3}
	.inst.n 0x1f12	@ subs r2, r2, #4
	cmp	r4, r3
	beq.n	.L08007746
	rev	r0, r4
	rev	r1, r3
	cmp	r0, r1
	bls.n	.L08007760
	movs	r0, #0x1
	pop	{r4, pc}
.L08007760:
	mov.w	r0, #0xffffffff
	pop	{r4, pc}
.L08007766:
	cbz	r2, .L08007770
	lsls	r3, r2, #0x1f
	beq.n	.L08007774
	.inst.n 0x1c52	@ adds r2, r2, #1
	b.n	.L08007780
.L08007770:
	movs	r0, #0x0
	pop	{r4, pc}
.L08007774:
	ldrb.w	r3, [r0], #0x1
	ldrb.w	r4, [r1], #0x1
	subs	r3, r3, r4
	bne.n	.L08007790
.L08007780:
	ldrb.w	r3, [r0], #0x1
	ldrb.w	r4, [r1], #0x1
	subs	r3, r3, r4
	bne.n	.L08007790
	.inst.n 0x1e92	@ subs r2, r2, #2
	bne.n	.L08007774
.L08007790:
	mov	r0, r3
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ find_byte - memchr-style search.
@ r0 = pointer, r1 = byte value, r2 = count.
@ Returns the pointer to the first byte equal to r1 within r2 bytes, or 0 if
@ none.
@ ----------------------------------------------------------------------------
	.section .text.find_byte,"ax",%progbits
	.global find_byte
	.thumb_func
	.type find_byte, %function
find_byte:
	uxtb	r3, r1
	cbz	r2, .L080077a4
.L08007798:
	ldrb	r1, [r0, #0x0]
	cmp	r3, r1
	beq.n	.L080077a6
	.inst.n 0x1c40	@ adds r0, r0, #1
	.inst.n 0x1e52	@ subs r2, r2, #1
	bne.n	.L08007798
.L080077a4:
	movs	r0, #0x0
.L080077a6:
	bx	lr

@ ----------------------------------------------------------------------------
@ copy_string_padded - strncpy-style copy.
@ r0 = destination, r1 = source, r2 = max count.
@ Copies bytes up to and including the NUL terminator (word-wise when both
@ pointers are aligned and the word holds no zero byte; the zero-byte test is
@ (w - 0x01010101) & ~w & (0x01010101 << 7)), then zero-fills the rest of the
@ r2 bytes by calling zero_bytes (080082bc). Returns r0 = destination.
@ ----------------------------------------------------------------------------
	.section .text.copy_string_padded,"ax",%progbits
	.global copy_string_padded
	.thumb_func
	.type copy_string_padded, %function
copy_string_padded:
	push	{r4, lr}
	mov	r4, r0
	tst.w	r0, #0x3
	it	eq
	tsteq.w	r1, #0x3
	bne.w	.L080077e4
	mov.w	lr, #0x1010101
.L080077be:
	.inst.n 0x1f12	@ subs r2, r2, #4
	blt.w	.L080077e0
	ldr.w	r3, [r1], #0x4
	sub.w	r12, r3, lr
	bic.w	r12, r12, r3
	ands.w	r12, r12, lr, lsl #0x7
	it	eq
	streq.w	r3, [r0], #0x4
	beq.n	.L080077be
	sub.w	r1, r1, #0x4
.L080077e0:
	add.w	r2, r2, #0x4
.L080077e4:
	.inst.n 0x1e52	@ subs r2, r2, #1
	blt.n	.L080077fa
	ldrb.w	r3, [r1], #0x1
	strb.w	r3, [r0], #0x1
	cmp	r3, #0x0
	bne.n	.L080077e4
	mov	r1, r2
	bl	zero_bytes
.L080077fa:
	mov	r0, r4
	pop	{r4, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ compare_strings - strcmp-style compare.
@ r0 = pointer A, r1 = pointer B (both word aligned, read 4 bytes per step).
@ Each step loads a word of each string; uqsub8 of 0x01010101 minus the word
@ of A (at 0800780e, 08007820, 08007832 and 08007844) is nonzero when a byte
@ of the first string is zero. The loop runs until a difference or a zero
@ byte. Returns the difference of the first differing byte, or 0 when the
@ strings are equal up to the NUL.
@ ----------------------------------------------------------------------------
	.section .text.compare_strings,"ax",%progbits
	.global compare_strings
	.thumb_func
	.type compare_strings, %function
compare_strings:
	push	{r4, r5}
	mov.w	r12, #0x1010101
.L08007806:
	ldr.w	r2, [r0], #0x4
	ldr.w	r3, [r1], #0x4
	uqsub8	r4, r12, r2
	subs	r5, r2, r3
	bne.n	.L08007858
	cbnz	r4, .L08007858
	ldr.w	r2, [r0], #0x4
	ldr.w	r3, [r1], #0x4
	uqsub8	r4, r12, r2
	subs	r5, r2, r3
	bne.n	.L08007858
	cbnz	r4, .L08007858
	ldr.w	r2, [r0], #0x4
	ldr.w	r3, [r1], #0x4
	uqsub8	r4, r12, r2
	subs	r5, r2, r3
	bne.n	.L08007858
	cbnz	r4, .L08007858
	ldr.w	r2, [r0], #0x4
	ldr.w	r3, [r1], #0x4
	uqsub8	r4, r12, r2
	subs	r5, r2, r3
	bne.n	.L08007858
	cmp	r4, #0x0
	beq.n	.L08007806
.L08007850:
	pop	{r4, r5}
	mov.w	r0, #0x0
	bx	lr
.L08007858:
	rev	r1, r5
	clz	r1, r1
	ands.w	r1, r1, #0x18
	rsbs.w	r0, r1, #0x20
	lsls	r4, r0
	bne.n	.L08007850
	lsrs	r2, r1
	lsrs	r3, r1
	ands.w	r2, r2, #0xff
	ands.w	r3, r3, #0xff
	pop	{r4, r5}
	subs	r0, r2, r3
	bx	lr

@ ----------------------------------------------------------------------------
@ nop_return_0800787c - returns immediately (bx lr); the analysis found no
@ flow or pointer to this address.
@ ----------------------------------------------------------------------------
	.section .text.nop_return_0800787c,"ax",%progbits
	.global nop_return_0800787c
	.thumb_func
	.type nop_return_0800787c, %function
nop_return_0800787c:
	bx	lr

@ ----------------------------------------------------------------------------
@ nop_return_0800787e - returns immediately (bx lr); the analysis found no
@ flow or pointer to this address.
@ ----------------------------------------------------------------------------
	.section .text.nop_return_0800787e,"ax",%progbits
	.global nop_return_0800787e
	.thumb_func
	.type nop_return_0800787e, %function
nop_return_0800787e:
	bx	lr

@ ----------------------------------------------------------------------------
@ nop_return_08007880 - returns immediately (bx lr); the analysis found no
@ flow or pointer to this address.
@ ----------------------------------------------------------------------------
	.section .text.nop_return_08007880,"ax",%progbits
	.global nop_return_08007880
	.thumb_func
	.type nop_return_08007880, %function
nop_return_08007880:
	bx	lr

@ ----------------------------------------------------------------------------
@ nop_return_08007882 - returns immediately (bx lr); the analysis found no
@ flow or pointer to this address.
@ ----------------------------------------------------------------------------
	.section .text.nop_return_08007882,"ax",%progbits
	.global nop_return_08007882
	.thumb_func
	.type nop_return_08007882, %function
nop_return_08007882:
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08007884 - returns the word stored at [0x20001240]. The address comes
@ from fn_08008308; the analysis found no flow or pointer to this address.
@ ----------------------------------------------------------------------------
	.section .text.fn_08007884,"ax",%progbits
	.global fn_08007884
	.thumb_func
	.type fn_08007884, %function
fn_08007884:
	push	{r4, lr}
	bl	fn_08008308
	ldr	r0, [r0, #0x0]
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_0800788e - stores r0 into the word at [0x20001240]. The address comes
@ from fn_08008308.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800788e,"ax",%progbits
	.global fn_0800788e
	.thumb_func
	.type fn_0800788e, %function
fn_0800788e:
	push	{r4, lr}
	mov	r4, r0
	bl	fn_08008308
	str	r4, [r0, #0x0]
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ zero_bytes - r0 = destination, r1 = count. Its own body is only
@ mov.w r2,#0 (the fill value); with no branch, execution falls through into
@ fill_bytes_body (080082c0..080082ff). Together they zero r1 bytes at r0:
@ r1 < 4 stores 0..3 bytes and returns; otherwise a word-aligned r0 branches
@ to fill_bytes_aligned_body (08008580), a misaligned one first stores 1 byte
@ (ip != 2) and/or 2 bytes (ip >= 2) to reach alignment, subtracts them from
@ r1 and branches there. fill_bytes_aligned_body does the 32-byte blocks (two
@ stmia of four words), 16/8/4 byte word stores and 2/1 byte tails. Returns
@ the pointer after the last byte written in r0.
@ ----------------------------------------------------------------------------
	.section .text.zero_bytes,"ax",%progbits
	.global zero_bytes
	.thumb_func
	.type zero_bytes, %function
zero_bytes:
	mov.w	r2, #0x0

@ ----------------------------------------------------------------------------
@ fill_bytes_body - r0 = destination (any alignment), r1 = byte count,
@ r2 = 32-bit pattern (the byte replicated into all four bytes). Stores r2
@ into r1 bytes at r0 and returns r0 = pointer after the last byte.
@ r1 < 4 (cmp at 080082c0, bcc.w 080082ea): movs.w ip,r1,lsl #31 puts count
@ bit 1 in C and bit 0 in N; strb twice if C, strb once if N, bx lr.
@ r1 >= 4: ands.w ip,r0,#3; misaligned: ip = 4-(r0&3), strb if ip != 2,
@ strh if ip >= 2 (strhge, it ge), r1 -= ip, b.w fill_bytes_aligned_body;
@ aligned: beq.w fill_bytes_aligned_body.
@ Entered from zero_bytes (falls in after mov.w r2,#0) and from fill_bytes
@ (b.w at 0800883c after replicating the byte into r2). Expects r0, r1, r2
@ as above, lr = return address; clobbers r1, r3, ip, flags. Purpose: byte /
@ halfword head and tail around the word-store core at 08008580.
@ ----------------------------------------------------------------------------
	.global fill_bytes_body
	.thumb_func
	.type fill_bytes_body, %function
fill_bytes_body:
	cmp	r1, #0x4
	bcc.w	.L080082ea
	ands.w	r12, r0, #0x3
	beq.w	fill_bytes_aligned_body
	rsb.w	r12, r12, #0x4
	cmp.w	r12, #0x2
	it	ne
	strbne.w	r2, [r0], #0x1
	it	ge
	strhge.w	r2, [r0], #0x2
	sub.w	r1, r1, r12
	b.w	fill_bytes_aligned_body
.L080082ea:
	lsls.w	r12, r1, #0x1f
	itt	cs
	strbcs.w	r2, [r0], #0x1
	strbcs.w	r2, [r0], #0x1
	it	mi
	strbmi.w	r2, [r0], #0x1
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08008300 - returns the constant address 0x20001260.
@ ----------------------------------------------------------------------------
	.section .text.fn_08008300,"ax",%progbits
	.global fn_08008300
	.thumb_func
	.type fn_08008300, %function
fn_08008300:
	ldr	r0, .L08008304
	bx	lr
.L08008304:
	.word 0x20001260

@ ----------------------------------------------------------------------------
@ fn_08008308 - returns the constant address 0x20001240.
@ ----------------------------------------------------------------------------
	.section .text.fn_08008308,"ax",%progbits
	.global fn_08008308
	.thumb_func
	.type fn_08008308, %function
fn_08008308:
	ldr	r0, .L0800830c
	bx	lr
.L0800830c:
	.word 0x20001240

@ ----------------------------------------------------------------------------
@ fn_08008534 - r0 = output byte pointer, r1 = character code, r2 = state.
@ Gets p = *[0x20001264] (via fn_08008620). If byte [p+0x101] == 1 it calls
@ the function at address p+0x107+word at [p+0x107] with (r0, r1, r2, 0) and
@ returns its result (tail call through bx r12; the decompiler treated the
@ indirect jump as a call). Otherwise, if r1 < 0x100 and byte [p+r1] != 0, it
@ stores r1 as a byte at r0 and returns 1; else returns 0xffffffff.
@ ----------------------------------------------------------------------------
	.section .text.fn_08008534,"ax",%progbits
	.global fn_08008534
	.thumb_func
	.type fn_08008534, %function
fn_08008534:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r6, r2
	mov	r4, r1
	mov	r5, r0
	bl	fn_08008620
	ldr	r3, [r0, #0x0]
	ldrb.w	r0, [r3, #0x101]
	cmp	r0, #0x1
	beq.n	.L0800855c
	cmp	r4, #0xff
	bhi.n	.L08008576
	ldrb	r0, [r3, r4]
	cbz	r0, .L08008576
	movs	r0, #0x1
	strb	r4, [r5, #0x0]
.L08008558:
	pop.w	{r4, r5, r6, r7, r8, pc}
.L0800855c:
	ldr.w	r0, [r3, #0x107]
	mov	r2, r6
	mov	r1, r4
	addw	r3, r3, #0x107
	adds	r7, r0, r3
	mov	r0, r5
	mov	r12, r7
	pop.w	{r4, r5, r6, r7, r8, lr}
	movs	r3, #0x0
	bx	r12
.L08008576:
	mov.w	r0, #0xffffffff
	b.n	.L08008558

@ ----------------------------------------------------------------------------
@ zero_bytes_aligned - r0 = destination (word aligned), r1 = count. Its own
@ body is only mov.w r2,#0 (the fill value); with no branch, execution falls
@ through into fill_bytes_aligned_body (08008580..080085c9), which holds all
@ the stores. fill_bytes_aligned_body copies r2 into r3, r12 and lr and zeroes
@ r1 bytes with 32-byte blocks (subs r1,#32 loop, two stmia of four words),
@ then a 16 byte store (bit 4 of r1), an 8 byte store (bit 3), a 4 byte word
@ store (bit 2), a 2 byte store (bit 1) and a 1 byte store (bit 0); it returns
@ early when bits 2..0 of r1 are zero (bxeq lr). Returns the pointer after the
@ last byte in r0.
@ ----------------------------------------------------------------------------
	.section .text.zero_bytes_aligned,"ax",%progbits
	.global zero_bytes_aligned
	.thumb_func
	.type zero_bytes_aligned, %function
zero_bytes_aligned:
	mov.w	r2, #0x0

@ ----------------------------------------------------------------------------
@ fill_bytes_aligned_body - r0 = destination (must be word aligned, no
@ check), r1 = byte count, r2 = 32-bit pattern. Stores the pattern over r1
@ bytes and returns r0 = pointer after the last byte.
@ push {lr}; r3 = ip = lr = r2. Loop: subs r1,#32; while carry is set, two
@ stmia r0!,{r2,r3,ip,lr} (32 bytes) and subs r1,#32, bcs.w back. Remainder
@ bits of r1 (r1 mod 32 is kept by the wrap-around subtraction): lsls r1,#28:
@ C (bit 4) stores 16 bytes with stmia {r2,r3,ip,lr}, N (bit 3) stores 8
@ bytes with stmia {r2,r3}; pop lr; lsls r1,#2: C (bit 2) str r2, Z set
@ returns (bxeq lr), N (bit 1) strh r2, tst r1,#0x40000000 (bit 0) strb r2;
@ bx lr.
@ Entered from fill_bytes_body (beq.w when aligned, b.w after the head
@ stores) and from zero_bytes_aligned (falls in after mov.w r2,#0). Expects
@ r0 word aligned, r1 any count, r2 pattern, lr = return address; clobbers
@ r1, r3, ip, flags. Purpose: word-store fill core.
@ ----------------------------------------------------------------------------
	.global fill_bytes_aligned_body
	.thumb_func
	.type fill_bytes_aligned_body, %function
fill_bytes_aligned_body:
	push	{lr}
	mov	r3, r2
	mov	r12, r2
	mov	lr, r2
	subs	r1, #0x20
.L0800858a:
	ittt	cs
	stmiacs.w	r0!, {r2, r3, r12, lr}
	stmiacs.w	r0!, {r2, r3, r12, lr}
	subscs.w	r1, r1, #0x20
	bcs.w	.L0800858a
	lsls	r1, r1, #0x1c
	it	cs
	stmiacs.w	r0!, {r2, r3, r12, lr}
	it	mi
	stmiami	r0!, {r2, r3}
	pop.w	{lr}
	lsls	r1, r1, #0x2
	it	cs
	strcs.w	r2, [r0], #0x4
	it	eq
	bxeq	lr
	it	mi
	strhmi.w	r2, [r0], #0x2
	tst.w	r1, #0x40000000
	it	ne
	strbne.w	r2, [r0], #0x1
	bx	lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080085cc - returns the constant address 0x20001240.
@ ----------------------------------------------------------------------------
	.section .text.fn_080085cc,"ax",%progbits
	.global fn_080085cc
	.thumb_func
	.type fn_080085cc, %function
fn_080085cc:
	ldr	r0, .L080085d0
	bx	lr
.L080085d0:
	.word 0x20001240

@ ----------------------------------------------------------------------------
@ fn_080085d4 - gets p = 0x20001240 from fn_080085cc, stores the incoming
@ link register at [(p&~7)+0x5c] and p at [(p&~7)+0x58] (via the push {r5,lr}
@ below the new stack pointer), calls fn_08007348, then zeroes the 16 words
@ starting at the address held in [(p&~7)+0x58]. r5 carries p, r1 the old sp;
@ sp is moved to (p&~7)+0x60 for the call and restored (8-byte aligned) at
@ the end.
@ ----------------------------------------------------------------------------
	.section .text.fn_080085d4,"ax",%progbits
	.global fn_080085d4
	.thumb_func
	.type fn_080085d4, %function
fn_080085d4:
	mov	r5, lr
	bl	fn_080085cc
	mov	lr, r5
	movs	r5, r0
	mov	r1, sp
	mov	r3, r10
	bic.w	r0, r0, #0x7
	mov	sp, r0
	add	sp, #0x60
	push	{r5, lr}
	bl	fn_08007348
	pop.w	{r5, lr}
	mov.w	r6, #0x0
	mov.w	r7, #0x0
	mov.w	r8, #0x0
	mov.w	r11, #0x0
	mov	r12, r5
	stm.w	r12!, {r6, r7, r8, r11}
	stm.w	r12!, {r6, r7, r8, r11}
	stm.w	r12!, {r6, r7, r8, r11}
	stm.w	r12!, {r6, r7, r8, r11}
	bic.w	r1, r1, #0x7
	mov	sp, r1
	bx	lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08008620 - returns 0x20001264 (the result of fn_08008300 plus 4).
@ ----------------------------------------------------------------------------
	.section .text.fn_08008620,"ax",%progbits
	.global fn_08008620
	.thumb_func
	.type fn_08008620, %function
fn_08008620:
	push	{r4, lr}
	bl	fn_08008300
	.inst.n 0x1d00	@ adds r0, r0, #4
	pop	{r4, pc}
	.byte 0x00, 0xbf, 0xd9, 0xc8, 0x03, 0x00	@ data bytes after the return (6 bytes)

@ ----------------------------------------------------------------------------
@ fn_08008630 - saves r4 and lr (push {r4,lr}), keeps r0 (mov r4,r0 ... mov
@ r0,r4 around a nop.w), restores r4 and lr and branches with b.w to
@ fn_08007302 (08007302), the instruction after the bl to fn_08008630 at
@ 080072fe. The calls the decompiler lists (080072ec, 08033f7d, 0802a9c5,
@ 08007185) are the code at 08007302 and 08007310 reached by that branch.
@ ----------------------------------------------------------------------------
	.section .text.fn_08008630,"ax",%progbits
	.global fn_08008630
	.thumb_func
	.type fn_08008630, %function
fn_08008630:
	push	{r4, lr}
	mov	r4, r0
	nop.w
	mov	r0, r4
	pop.w	{r4, lr}
	b.w	fn_08007302

@ ----------------------------------------------------------------------------
@ copy_bytes_forward - memcpy-style ascending copy.
@ r0 = destination, r1 = source, r2 = count; returns the end pointers in r0
@ (destination) and r1 (source).
@ Count < 4 (cmp, bls.w 0800880c) goes straight to the 1..3 byte tail at
@ 0800880c..0800882e (bx lr at 0800882e). Otherwise the destination is
@ aligned to 4 (ands at 080087ac; up to 3 byte copies at 080087b4..080087da;
@ beq.w 080087de when already aligned). Then, when the source is word aligned
@ (ands r3,r1,#3 at 080087de), beq.w branches to copy_bytes_aligned_body,
@ which copies 32-byte blocks, a 16 and an 8 byte step, then a word,
@ halfword and byte tail and returns. When the source is not word aligned
@ the loop at 080087e8..080087fa copies 8 bytes per pass (two word loads,
@ stmia), then a 4 byte word step at 080087fc and the 1..3 byte tail at
@ 0800880c.
@ ----------------------------------------------------------------------------
	.section .text.copy_bytes_forward,"ax",%progbits
	.global copy_bytes_forward
	.thumb_func
	.type copy_bytes_forward, %function
copy_bytes_forward:
	cmp	r2, #0x3
	bls.w	.L0800880c
	ands.w	r12, r0, #0x3
	beq.w	.L080087de
	ldrb.w	r3, [r1], #0x1
	cmp.w	r12, #0x2
	add	r2, r12
	it	ls
	ldrbls.w	r12, [r1], #0x1
	strb.w	r3, [r0], #0x1
	it	cc
	ldrbcc.w	r3, [r1], #0x1
	sub.w	r2, r2, #0x4
	it	ls
	strbls.w	r12, [r0], #0x1
	it	cc
	strbcc.w	r3, [r0], #0x1
.L080087de:
	ands.w	r3, r1, #0x3
	beq.w	copy_bytes_aligned_body
	subs	r2, #0x8
.L080087e8:
	bcc.w	.L080087fc
	ldr.w	r3, [r1], #0x4
	subs	r2, #0x8
	ldr.w	r12, [r1], #0x4
	stm.w	r0!, {r3, r12}
	b.n	.L080087e8
.L080087fc:
	.inst.n 0x1d12	@ adds r2, r2, #4
	itt	pl
	ldrpl.w	r3, [r1], #0x4
	strpl.w	r3, [r0], #0x4
	nop.w
.L0800880c:
	lsls	r2, r2, #0x1f
	itt	cs
	ldrbcs.w	r3, [r1], #0x1
	ldrbcs.w	r12, [r1], #0x1
	it	mi
	ldrbmi.w	r2, [r1], #0x1
	itt	cs
	strbcs.w	r3, [r0], #0x1
	strbcs.w	r12, [r0], #0x1
	it	mi
	strbmi.w	r2, [r0], #0x1
	bx	lr

@ ----------------------------------------------------------------------------
@ fill_bytes - memset-style fill.
@ r0 = destination, r1 = count, r2 = byte value. Replicates the byte into a
@ word, then continues in fill_bytes_body (aligns with byte / halfword
@ stores, 32-byte blocks of word stores, then smaller tails). Returns the
@ pointer after the last byte written.
@ ----------------------------------------------------------------------------
	.section .text.fill_bytes,"ax",%progbits
	.global fill_bytes
	.thumb_func
	.type fill_bytes, %function
fill_bytes:
	and.w	r3, r2, #0xff
	orr.w	r2, r3, r3, lsl #0x8
	orr.w	r2, r2, r2, lsl #0x10
	b.w	fill_bytes_body

@ ----------------------------------------------------------------------------
@ copy_bytes_aligned_body - copy body of copy_bytes_forward for a
@ word-aligned destination and source: r0 = destination (4-aligned), r1 =
@ source (4-aligned), r2 = byte count already reduced by the head bytes.
@ Returns r0 = end destination pointer, r1 = end source pointer.
@ Code: push {r4,lr}; subs r2,#32 and a loop copying 32 bytes per pass with
@ two ldmia/stmia of {r3,r4,ip,lr} while the count stays >= 32; then count
@ bit 4 selects a 16-byte copy, bit 3 an 8-byte copy ({r3,r4}), pops r4,lr,
@ bit 2 a 4-byte copy, return when bits 1:0 are 0 (bxeq lr), else bit 1
@ copies a halfword and bit 0 a byte, then bx lr.
@ Entered by: beq.w in copy_bytes_forward when (r1 & 3) == 0, after the
@ destination head alignment. No fall-in from the preceding code (fill_bytes
@ ends in b.w). Entry state: lr = caller of copy_bytes_forward, r3 is
@ overwritten before use.
@ ----------------------------------------------------------------------------
	.section .text.copy_bytes_aligned_body,"ax",%progbits
	.global copy_bytes_aligned_body
	.thumb_func
	.type copy_bytes_aligned_body, %function
copy_bytes_aligned_body:
	push	{r4, lr}
	subs	r2, #0x20
	bcc.w	.L0800885e
.L08008848:
	ldmia.w	r1!, {r3, r4, r12, lr}
	stmia.w	r0!, {r3, r4, r12, lr}
	ldmia.w	r1!, {r3, r4, r12, lr}
	stmia.w	r0!, {r3, r4, r12, lr}
	subs	r2, #0x20
	bcs.w	.L08008848
.L0800885e:
	lsls.w	r12, r2, #0x1c
	itt	cs
	ldmiacs.w	r1!, {r3, r4, r12, lr}
	stmiacs.w	r0!, {r3, r4, r12, lr}
	itt	mi
	ldmiami	r1!, {r3, r4}
	stmiami	r0!, {r3, r4}
	pop.w	{r4, lr}
	lsls.w	r12, r2, #0x1e
	itt	cs
	ldrcs.w	r3, [r1], #0x4
	strcs.w	r3, [r0], #0x4
	it	eq
	bxeq	lr
	lsls	r2, r2, #0x1f
	it	cs
	ldrhcs.w	r3, [r1], #0x2
	it	mi
	ldrbmi.w	r2, [r1], #0x1
	it	cs
	strhcs.w	r3, [r0], #0x2
	it	mi
	strbmi.w	r2, [r0], #0x1
	bx	lr

@ ----------------------------------------------------------------------------
@ parse_signed_decimal - atoi-style parser.
@ r0 = pointer to text bytes; returns the int in r0.
@ Skips bytes equal to 0x20 (four-way unrolled loop), then accepts one
@ optional sign byte (0x2d gives -1, 0x2b gives +1; any other byte leaves
@ +1), then accumulates decimal digits (bytes 0x30..0x39) as
@ acc = acc*10 + digit (four digits per loop iteration) until a non-digit
@ byte, and returns acc * sign (sign kept in r12).
@ Overflow test: after each digit the sum acc*10 + byte is compared with
@ 0x30 (signed); a sum below 0x30 (wrapped negative) returns
@ sign * 0x7fffffff (exits at 080301f8..080301fc and 08030202..08030206). An
@ overflow that wraps to a nonnegative sum >= 0x30 is not detected by this
@ test. No digits gives 0. No memory is written.
@ ----------------------------------------------------------------------------
	.section .text.parse_signed_decimal,"ax",%progbits
	.global parse_signed_decimal
	.thumb_func
	.type parse_signed_decimal, %function
parse_signed_decimal:
	ldrb	r2, [r0, #0x0]
	cmp	r2, #0x20
	bne.n	.L08030148
	ldrb	r2, [r0, #0x1]
	cmp	r2, #0x20
	bne.n	.L08030152
	ldrb	r2, [r0, #0x2]
	cmp	r2, #0x20
	bne.n	.L0803015e
	ldrb	r2, [r0, #0x3]
	cmp	r2, #0x20
	bne.n	.L0803016a
	adds	r0, #0x4
	b.n	parse_signed_decimal
.L08030148:
	cmp	r2, #0x2b
	beq.n	.L08030174
	cmp	r2, #0x2d
	beq.n	.L08030174
	b.n	.L0803018e
.L08030152:
	cmp	r2, #0x2d
	beq.n	.L0803015a
	cmp	r2, #0x2b
	bne.n	.L08030184
.L0803015a:
	adds	r0, #0x1
	b.n	.L08030174
.L0803015e:
	cmp	r2, #0x2b
	beq.n	.L08030166
	cmp	r2, #0x2d
	bne.n	.L08030188
.L08030166:
	adds	r0, #0x2
	b.n	.L08030174
.L0803016a:
	cmp	r2, #0x2b
	beq.n	.L08030172
	cmp	r2, #0x2d
	bne.n	.L0803018c
.L08030172:
	adds	r0, #0x3
.L08030174:
	mov.w	r12, #0x1
	cmp	r2, #0x2d
	it	eq
	moveq.w	r12, #0xffffffff
	adds	r0, #0x1
	b.n	.L08030192
.L08030184:
	adds	r0, #0x1
	b.n	.L0803018e
.L08030188:
	adds	r0, #0x2
	b.n	.L0803018e
.L0803018c:
	adds	r0, #0x3
.L0803018e:
	mov.w	r12, #0x1
.L08030192:
	movs	r2, #0x0
.L08030194:
	ldrb	r3, [r0, #0x0]
	sub.w	r1, r3, #0x30
	cmp	r1, #0x9
	bhi.n	.L08030206
	add.w	r1, r2, r2, lsl #0x2
	add.w	r2, r3, r1, lsl #0x1
	cmp	r2, #0x2f
	ble.n	.L08030202
	ldrb	r3, [r0, #0x1]
	subs	r2, #0x30
	sub.w	r1, r3, #0x30
	cmp	r1, #0x9
	bhi.n	.L08030206
	add.w	r1, r2, r2, lsl #0x2
	add.w	r2, r3, r1, lsl #0x1
	cmp	r2, #0x30
	blt.n	.L080301f8
	ldrb	r3, [r0, #0x2]
	subs	r2, #0x30
	sub.w	r1, r3, #0x30
	cmp	r1, #0x9
	bhi.n	.L08030206
	add.w	r1, r2, r2, lsl #0x2
	add.w	r2, r3, r1, lsl #0x1
	cmp	r2, #0x30
	blt.n	.L080301f8
	ldrb	r3, [r0, #0x3]
	subs	r2, #0x30
	sub.w	r1, r3, #0x30
	cmp	r1, #0x9
	bhi.n	.L08030206
	add.w	r1, r2, r2, lsl #0x2
	add.w	r1, r3, r1, lsl #0x1
	subs.w	r2, r1, #0x30
	add.w	r0, r0, #0x4
	bge.n	.L08030194
.L080301f8:
	mvn	r2, #0x80000000
	mul	r0, r2, r12
	bx	lr
.L08030202:
	mvn	r2, #0x80000000
.L08030206:
	mul	r0, r2, r12
	bx	lr

@ ----------------------------------------------------------------------------
@ fill_halfwords - r0 = halfword buffer pointer, r1 (16-bit) = value,
@ r2 = count. Stores the 16-bit value into count consecutive halfwords at r0
@ (loop unrolled by 4, then 0..3 remainder stores; nothing when count is 0).
@ No return value.
@ ----------------------------------------------------------------------------
	.section .text.fill_halfwords,"ax",%progbits
	.global fill_halfwords
	.thumb_func
	.type fill_halfwords, %function
fill_halfwords:
	push	{r7, lr}
	cbz	r2, .L0803acba
	subs	r3, r2, #1
	cmp	r3, #0x3
	and.w	r12, r2, #0x3
	bcs.n	.L0803ac7e
	movs	r2, #0x0
	b.n	.L0803ac98
.L0803ac7e:
	bic.w	lr, r2, #0x3
	sub.w	r3, r0, #0x8
	movs	r2, #0x0
.L0803ac88:
	adds	r2, #0x4
	strh.w	r1, [r3, #0x8]!
	cmp	lr, r2
	strh	r1, [r3, #0x2]
	strh	r1, [r3, #0x4]
	strh	r1, [r3, #0x6]
	bne.n	.L0803ac88
.L0803ac98:
	cmp.w	r12, #0x0
	it	eq
	popeq	{r7, pc}
	cmp.w	r12, #0x1
	strh.w	r1, [r0, r2, lsl #0x1]
	beq.n	.L0803acba
	add.w	r0, r0, r2, lsl #0x1
	cmp.w	r12, #0x2
	strh	r1, [r0, #0x2]
	itt	ne
	strhne	r1, [r0, #0x4]
	popne	{r7, pc}
.L0803acba:
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ is_ascii_digit - returns 1 if (r0 - 0x30) as unsigned is below 10 (r0 is
@ 0x30..0x39), else 0.
@ ----------------------------------------------------------------------------
	.section .text.is_ascii_digit,"ax",%progbits
	.global is_ascii_digit
	.thumb_func
	.type is_ascii_digit, %function
is_ascii_digit:
	subs	r0, #0x30
	cmp	r0, #0xa
	bcs.n	.L08044e4e
	movs	r0, #0x1
	bx	lr
.L08044e4e:
	movs	r0, #0x0
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08044ed8 - takes r1 = pointer to a string (r0 unused). If r1 is null,
@ or r1[0] == 0, or compare_strings (08007800) called with r0 = the string
@ "C" (at 0x080be338) and r1 returns 0 (equal), it returns the constant
@ 0x080be340 (pc-relative literal 0x00079446 at 0x08044f00 plus pc
@ 0x08044efa); otherwise it returns 0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08044ed8,"ax",%progbits
	.global fn_08044ed8
	.thumb_func
	.type fn_08044ed8, %function
fn_08044ed8:
	push	{r4, lr}
	cmp	r1, #0x0
	beq.n	.L08044ef4
	ldrb	r0, [r1, #0x0]
	cmp	r0, #0x0
	beq.n	.L08044ef4
	ldr	r0, .L08044efc
.L08044ee6:
	add	r0, pc
	bl	compare_strings
	cmp	r0, #0x0
	beq.n	.L08044ef4
	movs	r0, #0x0
	pop	{r4, pc}
.L08044ef4:
	ldr	r0, .L08044f00
.L08044ef6:
	add	r0, pc
	pop	{r4, pc}
	.short 0x0000	@ padding
.L08044efc:
	.word d_080be338 - (.L08044ee6 + 4)	@ distance for add r0,pc at 08044ee6: 0x080BE338
.L08044f00:
	.word d_080be340 - (.L08044ef6 + 4)	@ distance for add r0,pc at 08044ef6: 0x080BE340

@ ----------------------------------------------------------------------------
@ fn_08044f04 - takes r1 = pointer to a string (r0 unused). If r1 is null,
@ or r1[0] == 0, or compare_strings (08007800) called with r0 = the string
@ "C" and r1 returns 0 (equal), it returns the constant 0x080be35c
@ (pc-relative literal at 0x08044f2c plus pc); otherwise it returns 0. Twin
@ of fn_08044ed8 with a different returned address.
@ ----------------------------------------------------------------------------
	.section .text.fn_08044f04,"ax",%progbits
	.global fn_08044f04
	.thumb_func
	.type fn_08044f04, %function
fn_08044f04:
	push	{r4, lr}
	cmp	r1, #0x0
	beq.n	.L08044f20
	ldrb	r0, [r1, #0x0]
	cmp	r0, #0x0
	beq.n	.L08044f20
	ldr	r0, .L08044f28
.L08044f12:
	add	r0, pc
	bl	compare_strings
	cmp	r0, #0x0
	beq.n	.L08044f20
	movs	r0, #0x0
	pop	{r4, pc}
.L08044f20:
	ldr	r0, .L08044f2c
.L08044f22:
	add	r0, pc
	pop	{r4, pc}
	.short 0x0000	@ padding
.L08044f28:
	.word d_080be354 - (.L08044f12 + 4)	@ distance for add r0,pc at 08044f12: 0x080BE354
.L08044f2c:
	.word d_080be35c - (.L08044f22 + 4)	@ distance for add r0,pc at 08044f22: 0x080BE35C
