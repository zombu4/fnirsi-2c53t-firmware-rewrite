@ system_62.s - interrupt handlers for 0x40000410 / 0x40001810 events, system reset, clock frequency computation, system clock init, a measurement-setup routine and FPU enable
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0802e71c - event handler for bit0 of the I/O word 0x40000410.
@ No parameters, no return value. Reads word 0x40000410 once; if bit0 is clear
@ it returns without any write. If bit0 is set and byte 0x20000124 == 0: sets
@ a local item byte = 3 and a local wake flag = 0, calls queue_send_from_isr
@ (08041f08) with queue = word at 0x20002d78, &item, &wake (this enqueues the
@ byte 3), then writes 0xfffffffe to 0x40000410, and if the wake flag is
@ nonzero writes 0x10000000 to 0xE000ED04 (ICSR, PENDSVSET) followed by DSB
@ and ISB. If bit0 is set and byte 0x20000124 != 0: only writes 0xfffffffe to
@ 0x40000410, no enqueue.
@ Purpose: posts the event value 3 to the queue at 0x20002d78 on each
@ flag-bit0 event and requests a PendSV when the queue call asks for a wake;
@ what the I/O word 0x40000410 is, is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0802e71c,"ax",%progbits
	.p2align 2
	.global fn_0802e71c
	.thumb_func
	.type fn_0802e71c, %function
fn_0802e71c:
	push {r4, lr}
	sub sp, #8
	movw r4, #0x410
	movt r4, #0x4000
	ldr r0, [r4]
	lsls r0, r0, #0x1f
	beq.n .L0802e742
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0x2c]		@ byte 0x20000124
	cbz r0, .L0802e746
	mvn r0, #1
	str r0, [r4]
.L0802e742:
	add sp, #8
	pop {r4, pc}
.L0802e746:
	movs r0, #0
	str r0, [sp, #4]		@ wake flag = 0
	movw r0, #0x2d78
	movt r0, #0x2000
	movs r1, #3
	ldr r0, [r0]			@ queue handle
	strb.w r1, [sp, #3]		@ item byte = 3
	add.w r1, sp, #3
	add r2, sp, #4
	bl queue_send_from_isr
	mvn r0, #1
	str r0, [r4]
	ldr r0, [sp, #4]
	cmp r0, #0
	beq.n .L0802e742
	movw r0, #0xed04
	movt r0, #0xe000
	mov.w r1, #0x10000000
	str r1, [r0]			@ ICSR: PENDSVSET
	dsb sy
	isb sy
	add sp, #8
	pop {r4, pc}
	.short 0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0802e78c - event handler for bit0 of the I/O word 0x40001810.
@ No parameters, no return value. Reads word 0x40001810 once; if bit0 is
@ clear returns without writes. If bit0 is set writes 0xaaaa to 0x40003000
@ and then 0xfffffffe to 0x40001810.
@ Purpose: on a bit0 event of 0x40001810 it writes the constant 0xaaaa to
@ 0x40003000 and acknowledges the event with 0xfffffffe; what the two I/O
@ blocks are is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0802e78c,"ax",%progbits
	.p2align 2
	.global fn_0802e78c
	.thumb_func
	.type fn_0802e78c, %function
fn_0802e78c:
	movw r0, #0x1810
	movt r0, #0x4000
	ldr r1, [r0]
	lsls r1, r1, #0x1f
	it eq
	bxeq lr
	movw r1, #0x3000
	movt r1, #0x4000
	movw r2, #0xaaaa
	str r2, [r1]
	mvn r1, #1
	str r1, [r0]
	bx lr
	.short 0x0000			@ padding

@ ----------------------------------------------------------------------------
@ system_reset - request a system reset through AIRCR.
@ No parameters, never returns. Executes DSB, reads word 0xE000ED0C (AIRCR),
@ writes (value & 0x700) | 0x05FA0004 (vector key 0x05FA, bit2 SYSRESETREQ,
@ bits 10..8 kept), executes DSB, then loops forever over four nops at
@ 0x0802f334..0x0802f33a and the b.n at 0x0802f33c that branches back to
@ 0x0802f334.
@ ----------------------------------------------------------------------------
	.section .text.system_reset,"ax",%progbits
	.p2align 2
	.global system_reset
	.thumb_func
	.type system_reset, %function
system_reset:
	movw r0, #0xed0c
	dsb sy
	movt r0, #0xe000
	ldr r1, [r0]
	movs r2, #4
	and r1, r1, #0x700
	movt r2, #0x5fa
	orrs r1, r2
	str r1, [r0]
	dsb sy
.L0802f334:
	nop
	nop
	nop
	nop
	b.n .L0802f334
	.short 0x0000			@ padding

@ ----------------------------------------------------------------------------
@ compute_clock_frequencies - derive a base frequency and four divided
@ frequencies from the configuration words at 0x40021004 / 0x40021054 /
@ 0x40021030 (the I/O block is not identified).
@ Parameter: r0 = pointer to result array of 5 dwords; no return value.
@ x = word 0x40021004 (re-read for each field); source = (x & 0xf) >> 2:
@ source 2 computes mult = field (x & 0x3fffff) >> 18 plus (adjust:
@ ((x & 0x7fffffff) >> 29) * 0x10 + 1, with 2 used instead when that 2-bit
@ field (bits 29..30) is 0 and the 4-bit field is not 0xf), then
@ freq = mult * 4000000 when bit16 of x is clear, mult * 8000000 when bit16
@ is set and bit17 clear, mult * (8000000 / (((word 0x40021054 & 0x3fff) >>
@ 12) + 2)) when bits 16 and 17 are set; source 0 gives 48000000 when bit9
@ of word 0x40021054 and bit25 of word 0x40021030 are both set; every other
@ case 8000000.
@ Stores [0] = freq, [1] = freq >> byte 0x080bb3ec[(x & 0xff) >> 4],
@ [3] = [1] >> byte 0x080bb404[(x & 0x7ff) >> 8],
@ [2] = [1] >> byte 0x080bb404[(x & 0x3fff) >> 11],
@ [4] = [2] / byte 0x0803150c[((x & 0xffff) >> 14) + ((x >> 26) & 4)].
@ ----------------------------------------------------------------------------
	.section .text.compute_clock_frequencies,"ax",%progbits
	.p2align 2
	.global compute_clock_frequencies
	.thumb_func
	.type compute_clock_frequencies, %function
compute_clock_frequencies:
	push {r4, lr}
	movw r1, #0x1004
	movt r1, #0x4002
	ldr r2, [r1]
	ubfx r3, r2, #2, #2
	movw r2, #0x1200
	cmp r3, #2
	movt r2, #0x7a			@ r2 = 8000000
	beq.n .L08031464
	cbnz r3, .L080314b8
	ldr r3, [r1, #0x50]
	lsls r3, r3, #0x16
	bpl.n .L080314b8
	ldr r3, [r1, #0x2c]
	lsls r3, r3, #6
	itt mi
	movwmi r2, #0x6c00
	movtmi r2, #0x2dc		@ 48000000
	b.n .L080314b8
.L08031464:
	ldr.w r12, [r1]
	ldr.w lr, [r1]
	ldr r4, [r1]
	ubfx lr, lr, #0x12, #4
	ubfx r4, r4, #0x1d, #2
	lsls r3, r4, #4
	adds r3, #1
	cmp r4, #0
	mov r4, r3
	it eq
	moveq r4, #2
	cmp.w lr, #0xf
	it eq
	moveq r4, r3
	lsls.w r3, r12, #0xf
	add.w r3, r4, lr
	bmi.n .L080314a0
	movw r2, #0x900
	movt r2, #0x3d			@ 4000000
	muls r2, r3
	b.n .L080314b8
.L080314a0:
	ldr r4, [r1]
	lsls r4, r4, #0xe
	bmi.n .L080314aa
	muls r2, r3
	b.n .L080314b8
.L080314aa:
	ldr r4, [r1, #0x50]
	ubfx r4, r4, #0xc, #2
	adds r4, #2
	udiv r2, r2, r4
	muls r2, r3
.L080314b8:
	str r2, [r0]
	ldr r3, [r1]
	movw r4, #:lower16:d_080bb3ec
	ubfx r3, r3, #4, #4
	movt r4, #:upper16:d_080bb3ec
	ldrb r3, [r4, r3]
	movw r4, #:lower16:d_080bb404
	lsrs r2, r3
	str r2, [r0, #4]
	ldr r3, [r1]
	movt r4, #:upper16:d_080bb404
	ubfx r3, r3, #8, #3
	ldrb r3, [r4, r3]
	lsr.w r3, r2, r3
	str r3, [r0, #0xc]
	ldr r3, [r1]
	ubfx r3, r3, #0xb, #3
	ldrb r3, [r4, r3]
	movs r4, #4
	lsrs r2, r3
	str r2, [r0, #8]
	ldr r3, [r1]
	ldr r1, [r1]
	and.w r3, r4, r3, lsr #0x1a
	ubfx r1, r1, #0xe, #2
	add r1, r3
	adr r3, .L0803150c
	ldrb r1, [r3, r1]
	udiv r1, r2, r1
	str r1, [r0, #0x10]
	pop {r4, pc}
.L0803150c:
	.byte 0x02, 0x04, 0x06, 0x08, 0x02, 0x0c, 0x08, 0x10

@ ----------------------------------------------------------------------------
@ init_system_clock - set up the vector table, the clock block at 0x40021000
@ and the derived clock variables.
@ No parameters; returns 0. Writes 0x08007000 to 0xE000ED08 (VTOR), enables
@ interrupts, then configures the block at 0x40021000 with unbounded polling
@ loops (no timeout exit): sets bit0 of 0x40021000 and waits for bit1; clears
@ the low 2 bits of 0x40021004 and waits for (x&0xc)==0; clears bits 16, 18,
@ 19, 24 of 0x40021000 (mask 0xfef2ffff); writes 0 to 0x40021004 and
@ 0x40021030 and 0x9f0000 to 0x40021008; sets bit16 of 0x40021000 and waits
@ for bit17; sets bits 16 and 17 of 0x40021004, sets the 4-bit field at bits
@ 18..21 to 0xb, sets bits 29, 30 and 31; clears bits 12 and 13 of
@ 0x40021054; sets bit24 of 0x40021000 and waits for bit25; clears bits 4..7
@ of 0x40021004, sets the field at bits 11..13 to 4 and the field at bits
@ 8..10 to 4; sets bits 4, 5 of 0x40021054; selects value 2 in the low 2 bits
@ of 0x40021004 and waits for (x&0xc)==8; clears bits 4, 5 of 0x40021054.
@ Computes a frequency: start 8000000; when (0x40021004&0xc)>>2 is 2 the
@ multiplier is bits 18..21 plus (bits 29..30 * 16 + 1, or 2 when bits
@ 29..30 are 0 and bits 18..21 are not 0xf) and the frequency is
@ multiplier * 4000000 when bit16 of 0x40021004 is clear, multiplier *
@ 8000000 when bit16 is set and bit17 is clear, multiplier * (8000000 /
@ (((0x40021054&0x3fff)>>12)+2)) when both are set; when the select value is
@ 0 and bit9 of 0x40021054 and bit25 of 0x40021030 are set the frequency is
@ 48000000. Shifts it right by the table byte at
@ 0x080bb3ec[(0x40021004&0xff)>>4] and stores it to 0x20000014; writes
@ (AIRCR & 0xf8ff) | 0x05fa0300 to 0xE000ED0C; sets bit2 of 0xE000E010
@ (SysTick control); stores 0x20000014/1000000 to 0x20002b1c and that*1000 to
@ 0x20002b20; calls system_bring_up (0802aa50).
@ ----------------------------------------------------------------------------
	.section .text.init_system_clock,"ax",%progbits
	.p2align 2
	.global init_system_clock
	.thumb_func
	.type init_system_clock, %function
init_system_clock:
	push {r4, r5, r7, lr}
	movw r12, #0xed0c
	movw r1, #0x1004
	movw r0, #:lower16:vectors	@ the vector table (src/vectors.s, 0x08007000): symbolic like every code address
	movt r12, #0xe000
	movt r1, #0x4002
	movt r0, #:upper16:vectors
	str.w r0, [r12, #-4]		@ VTOR = vectors (0x08007000)
	cpsie i
	ldr.w r0, [r1, #-4]
	orr r0, r0, #1
	str.w r0, [r1, #-4]
.L0803a518:
	ldr.w r0, [r1, #-4]
	lsls r0, r0, #0x1e
	itttt pl
	ldrpl.w r0, [r1, #-4]
	lslspl.w r0, r0, #0x1e
	ldrpl.w r0, [r1, #-4]
	lslspl.w r0, r0, #0x1e
	bmi.n .L0803a53a
	ldr.w r0, [r1, #-4]
	lsls r0, r0, #0x1e
	bpl.n .L0803a518
.L0803a53a:
	ldr r0, [r1]
	bic r0, r0, #3
	str r0, [r1]
	nop
.L0803a544:
	ldr r0, [r1]
	tst r0, #0xc
	beq.n .L0803a564
	ldr r0, [r1]
	tst r0, #0xc
	beq.n .L0803a564
	ldr r0, [r1]
	tst r0, #0xc
	beq.n .L0803a564
	ldr r0, [r1]
	tst r0, #0xc
	bne.n .L0803a544
.L0803a564:
	ldr.w r0, [r1, #-4]
	movw r2, #0xffff
	movt r2, #0xfef2
	ands r0, r2
	str.w r0, [r1, #-4]
	movs r0, #0
	str r0, [r1]
	str r0, [r1, #0x2c]
	mov.w r0, #0x9f0000
	str r0, [r1, #4]
	ldr.w r0, [r1, #-4]
	movw r2, #0x2ffe
	orr r0, r0, #0x10000
	movw r3, #0x2ffd
	movw lr, #0x2ffc
	str.w r0, [r1, #-4]
	b.n .L0803a5a4
.L0803a59c:
	ldr.w r0, [r1, #-4]
	lsls r0, r0, #0xe
	bmi.n .L0803a5e8
.L0803a5a4:
	movs r0, #0
	nop
.L0803a5a8:
	ldr.w r4, [r1, #-4]
	lsrs r5, r0, #0xc
	cmp r5, #2
	bhi.n .L0803a59c
	ands r4, r4, #0x20000
	bne.n .L0803a59c
	ldr.w r4, [r1, #-4]
	cmp r0, r2
	bhi.n .L0803a59c
	ands r4, r4, #0x20000
	bne.n .L0803a59c
	ldr.w r4, [r1, #-4]
	cmp r0, r3
	bhi.n .L0803a59c
	ands r4, r4, #0x20000
	bne.n .L0803a59c
	ldr.w r4, [r1, #-4]
	cmp r0, lr
	bhi.n .L0803a59c
	ands r4, r4, #0x20000
	add.w r0, r0, #4
	beq.n .L0803a5a8
	b.n .L0803a59c
.L0803a5e8:
	ldr r0, [r1]
	movs r2, #0xb
	orr r0, r0, #0x10000
	str r0, [r1]
	ldr r0, [r1]
	orr r0, r0, #0x20000
	str r0, [r1]
	ldr r0, [r1]
	bfi r0, r2, #0x12, #4
	str r0, [r1]
	ldr r0, [r1]
	orr r0, r0, #0x60000000
	str r0, [r1]
	ldr r0, [r1]
	orr r0, r0, #0x80000000
	str r0, [r1]
	ldr r0, [r1, #0x50]
	bic r0, r0, #0x3000
	str r0, [r1, #0x50]
	ldr.w r0, [r1, #-4]
	orr r0, r0, #0x1000000
	str.w r0, [r1, #-4]
	nop
.L0803a628:
	ldr.w r0, [r1, #-4]
	lsls r0, r0, #6
	itttt pl
	ldrpl.w r0, [r1, #-4]
	lslspl.w r0, r0, #6
	ldrpl.w r0, [r1, #-4]
	lslspl.w r0, r0, #6
	bmi.n .L0803a64a
	ldr.w r0, [r1, #-4]
	lsls r0, r0, #6
	bpl.n .L0803a628
.L0803a64a:
	ldr r0, [r1]
	movs r2, #4
	bic r0, r0, #0xf0
	str r0, [r1]
	ldr r0, [r1]
	bfi r0, r2, #0xb, #3
	str r0, [r1]
	ldr r0, [r1]
	bfi r0, r2, #8, #3
	str r0, [r1]
	ldr r0, [r1, #0x50]
	movs r2, #2
	orr r0, r0, #0x30
	str r0, [r1, #0x50]
	ldr r0, [r1]
	bfi r0, r2, #0, #2
	str r0, [r1]
	nop
.L0803a678:
	ldr r0, [r1]
	and r0, r0, #0xc
	cmp r0, #8
	beq.n .L0803a6a0
	ldr r0, [r1]
	and r0, r0, #0xc
	cmp r0, #8
	beq.n .L0803a6a0
	ldr r0, [r1]
	and r0, r0, #0xc
	cmp r0, #8
	beq.n .L0803a6a0
	ldr r0, [r1]
	and r0, r0, #0xc
	cmp r0, #8
	bne.n .L0803a678
.L0803a6a0:
	ldr r0, [r1, #0x50]
	movw r2, #0x1200
	bic r0, r0, #0x30
	str r0, [r1, #0x50]
	ldr r0, [r1]
	movt r2, #0x7a			@ r2 = 8000000
	ubfx r0, r0, #2, #2
	cmp r0, #2
	beq.n .L0803a6d2
	cbnz r0, .L0803a722
	ldr r0, [r1, #0x50]
	lsls r0, r0, #0x16
	bpl.n .L0803a722
	ldr r0, [r1, #0x2c]
	lsls r0, r0, #6
	itt mi
	movwmi r2, #0x6c00
	movtmi r2, #0x2dc		@ 48000000
	b.n .L0803a722
.L0803a6d2:
	ldr.w lr, [r1]
	ldr r3, [r1]
	ldr r5, [r1]
	ubfx r3, r3, #0x12, #4
	ubfx r5, r5, #0x1d, #2
	lsls r4, r5, #4
	adds r0, r4, #1
	cmp r5, #0
	mov r4, r0
	it eq
	moveq r4, #2
	cmp r3, #0xf
	it eq
	moveq r4, r0
	lsls.w r0, lr, #0xf
	add.w r0, r4, r3
	bmi.n .L0803a70a
	movw r2, #0x900
	movt r2, #0x3d			@ 4000000
	muls r2, r0
	b.n .L0803a722
.L0803a70a:
	ldr r3, [r1]
	lsls r3, r3, #0xe
	bmi.n .L0803a714
	muls r2, r0
	b.n .L0803a722
.L0803a714:
	ldr r3, [r1, #0x50]
	ubfx r3, r3, #0xc, #2
	adds r3, #2
	udiv r2, r2, r3
	muls r2, r0
.L0803a722:
	movw r0, #0x14
	movt r0, #0x2000
	str r2, [r0]			@ 0x20000014 = frequency
	ldr r1, [r1]
	movw r3, #:lower16:d_080bb3ec
	ubfx r1, r1, #4, #4
	movt r3, #:upper16:d_080bb3ec
	ldrb r1, [r3, r1]
	lsr.w r1, r2, r1
	str r1, [r0]
	ldr.w r1, [r12]
	movw r2, #0xf8ff
	ands r1, r2
	movw r2, #0x300
	movt r2, #0x5fa
	orrs r1, r2
	str.w r1, [r12]			@ AIRCR
	movw r1, #0xe010
	movt r1, #0xe000
	ldr r2, [r1]
	orr r2, r2, #4
	str r2, [r1]			@ SysTick control bit2
	ldr r0, [r0]
	movw r1, #0xde83
	movt r1, #0x431b
	umull r0, r1, r0, r1
	lsrs r0, r1, #0x12
	movw r1, #0x2b1c
	movt r1, #0x2000
	str r0, [r1]
	ldr r0, [r1]
	mov.w r1, #0x3e8
	muls r0, r1
	movw r1, #0x2b20
	movt r1, #0x2000
	str r0, [r1]
	bl system_bring_up
	movs r0, #0
	pop {r4, r5, r7, pc}
	.short 0x0000			@ padding

@ ----------------------------------------------------------------------------
@ reset_system - reset the system.
@ No parameters. The instruction at 0x0803b070 is bl system_reset (0802f314:
@ DSB, AIRCR write with 0x05FA0004, endless loop), which never returns, so
@ this function never returns.
@ ----------------------------------------------------------------------------
	.section .text.reset_system,"ax",%progbits
	.p2align 2
	.global reset_system
	.thumb_func
	.type reset_system, %function
reset_system:
	bl system_reset
	.word 0x00000000		@ padding

@ ----------------------------------------------------------------------------
@ fn_0803b078 - copy and rescale measurement settings into a work block.
@ No parameters; no return value. Copies bytes 0x20000125 to 0x20000eb8,
@ 0x200000fa to 0x20000eb9 and 0x200000fd to 0x20000ebc, the halfword
@ 0x2000010c (ldrh [r5,#20]) to 0x20000eb6 (strh [r5,#3518]) and the
@ halfword 0x200000fb to 0x20000eba; writes the word 0x20000112 with its
@ halves swapped to 0x20000ebe; copies the halfword 0x20000eac to 0x20000ed8.
@ Derives sign-extended 64-bit values 0x20000ec8 = ushort 0x20000eac - 0x96
@ and 0x20000ed0 = ushort 0x20000eae + ushort 0x20000eac - 0x96, each
@ converted to a double (i64_to_double 08045538), multiplied (double_mul
@ 0804577c) by 10^(idx/3) (double_pow 080438e0 with base 10.0 = high word
@ 0x40240000, exponent u32_to_double 080455da(idx/3), idx = byte
@ 0x20000125), converted back to int64 (double_to_i64 08046020) and
@ multiplied by the table byte 0x080465c8[idx%3].
@ Calls fn_08030a70 (08030a70) and clears 0x20000ef0; when 0x20000eb8<4 and
@ (0x20000eb8!=3 or byte 0x20000eb6==3): copies 0x20000ec8..0x20000ed4 to
@ 0x20000ee0..0x20000eec, recomputes 0x20000ed0 and 0x20000ec8 from the same
@ two 16-bit values with factor 10.0 and the table byte 0x080465c8
@ (0x080465c9 when byte 0x20000eb6==3), divides 0x20000118:0x2000011c by
@ 10*table byte with divide_s64 (08008732), takes (0x20000118-remainder) as a
@ double divided by 10.0 (double_div 08045124), converted to int64, divided
@ by the table byte, clamped to -0x96..0x96 and stores it as halfword
@ 0x20000ec0 (high half of 0x20000ebe); writes 0x20000ef0 = low halfword of
@ 0x20000112 - clamped * divide_u64(1000,0,0x20000f00,0x20000f04) (08008642).
@ Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0803b078,"ax",%progbits
	.p2align 2
	.global fn_0803b078
	.thumb_func
	.type fn_0803b078, %function
fn_0803b078:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #4
	vpush {d8, d9}
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0x2d]
	movw r7, #0xaaab
	movt r7, #0xaaaa
	umull r1, r2, r0, r7
	ldrb r1, [r5, #2]
	strb.w r0, [r5, #0xdc0]
	strb.w r1, [r5, #0xdc1]
	ldr.w r1, [r5, #0x1a]
	ldrh.w r0, [r5, #0xdb4]
	ror.w r1, r1, #0x10
	str.w r1, [r5, #0xdc6]
	ldrh r1, [r5, #0x14]
	ldrb r3, [r5, #5]
	strh.w r1, [r5, #0xdbe]
	ldrh.w r1, [r5, #0xdb6]
	strh.w r0, [r5, #0xde0]
	add r1, r0
	subs r0, #0x96
	mov.w r8, #0
	strb.w r3, [r5, #0xdc4]
	sbc r3, r8, #0
	subs r1, #0x96
	ldrh.w r6, [r5, #3]
	str.w r0, [r5, #0xdd0]
	sbc r0, r8, #0
	str.w r0, [r5, #0xddc]
	lsrs r0, r2, #1
	strh.w r6, [r5, #0xdc2]
	str.w r3, [r5, #0xdd4]
	str.w r1, [r5, #0xdd8]
	bl u32_to_double
	vldr d8, .L0803b2f0
	vmov d1, r0, r1
	vmov.f32 s0, s16
	vmov.f32 s1, s17
	bl double_pow
	ldr.w r0, [r5, #0xdd8]
	ldr.w r1, [r5, #0xddc]
	vmov.f32 s18, s0
	vmov.f32 s19, s1
	bl i64_to_double
	mov r2, r0
	mov r3, r1
	vmov r0, r1, d9
	bl double_mul
	bl double_to_i64
	ldrb.w r3, [r5, #0x2d]
	uxtb r2, r3
	umull r2, r4, r2, r7
	lsrs r2, r4, #1
	sub.w r4, r2, r2, lsl #2
	add r3, r4
	movw r4, #:lower16:d_080465c8
	uxtb r3, r3
	movt r4, #:upper16:d_080465c8
	ldrb r3, [r4, r3]
	umull r0, r6, r3, r0
	mla r1, r3, r1, r6
	str.w r0, [r5, #0xdd8]
	mov r0, r2
	str.w r1, [r5, #0xddc]
	bl u32_to_double
	vmov d1, r0, r1
	vmov.f32 s0, s16
	vmov.f32 s1, s17
	bl double_pow
	ldr.w r0, [r5, #0xdd0]
	ldr.w r1, [r5, #0xdd4]
	vmov.f32 s18, s0
	vmov.f32 s19, s1
	bl i64_to_double
	mov r2, r0
	mov r3, r1
	vmov r0, r1, d9
	bl double_mul
	bl double_to_i64
	ldrb.w r2, [r5, #0x2d]
	umull r3, r7, r2, r7
	lsrs r3, r7, #1
	add.w r3, r3, r3, lsl #1
	subs r2, r2, r3
	ldrb r2, [r4, r2]
	umull r0, r3, r2, r0
	mla r1, r2, r1, r3
	str.w r0, [r5, #0xdd0]
	str.w r1, [r5, #0xdd4]
	bl fn_08030a70
	ldrb.w r0, [r5, #0xdc0]
	strh.w r8, [r5, #0xdf8]
	cmp r0, #3
	bhi.w .L0803b2e0
	ldrb.w r6, [r5, #0xdbe]
	bne.n .L0803b1d8
	cmp r6, #3
	bne.w .L0803b2e0
.L0803b1d8:
	add.w r3, r5, #0xdd0
	ldm r3, {r0, r1, r2, r3}
	str.w r1, [r5, #0xdec]
	str.w r0, [r5, #0xde8]
	ldrh.w r0, [r5, #0xdb4]
	ldrh.w r1, [r5, #0xdb6]
	subs.w r8, r0, #0x96
	add r1, r0
	mov.w r11, #0
	sbc r7, r11, #0
	subs.w r0, r1, #0x96
	sbc r1, r11, #0
	str.w r2, [r5, #0xdf0]
	str.w r3, [r5, #0xdf4]
	bl i64_to_double
	vmov r10, r9, d8
	mov r2, r10
	mov r3, r9
	bl double_mul
	bl double_to_i64
	cmp r6, #3
	it eq
	addeq r4, #1
	ldrb r6, [r4]
	umull r0, r2, r0, r6
	mla r1, r1, r6, r2
	str.w r0, [r5, #0xdd8]
	str.w r1, [r5, #0xddc]
	mov r0, r8
	mov r1, r7
	bl i64_to_double
	mov r2, r10
	mov r3, r9
	bl double_mul
	bl double_to_i64
	umull r0, r2, r6, r0
	mla r1, r6, r1, r2
	ldrd r7, r4, [r5, #0x20]
	str.w r0, [r5, #0xdd0]
	movs r0, #0xa
	str.w r1, [r5, #0xdd4]
	umull r2, r3, r6, r0
	mov r0, r7
	mov r1, r4
	bl divide_s64
	subs r0, r7, r2
	sbc.w r1, r4, r3
	bl i64_to_double
	mov r2, r10
	mov r3, r9
	bl double_div
	bl double_to_i64
	mov r2, r6
	movs r3, #0
	bl divide_s64
	mvn r4, #0x95
	subs r2, r4, r0
	mov.w r2, #0xffffffff
	sbcs.w r3, r2, r1
	mov.w r3, #0
	it lt
	movlt r3, #1
	cmp r3, #0
	itt ne
	movne r2, r1
	movne r4, r0
	subs.w r0, r4, #0x96
	sbcs r0, r2, #0
	it lt
	movlt.w r11, #1
	cmp.w r11, #0
	it eq
	moveq r4, #0x96
	ldr.w r2, [r5, #0xe08]
	ldr.w r3, [r5, #0xe0c]
	ldrh r6, [r5, #0x1a]
	mov.w r0, #0x3e8
	movs r1, #0
	strh.w r4, [r5, #0xdc8]
	bl divide_u64
	mls r0, r4, r0, r6
	strh.w r0, [r5, #0xdf8]
.L0803b2e0:
	vpop {d8, d9}
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short 0xbf00			@ padding
	.short 0xbf00			@ padding
	.short 0xbf00			@ padding
.L0803b2f0:
	.word 0x00000000		@ double 10.0, low word
	.word 0x40240000		@ double 10.0, high word

@ ----------------------------------------------------------------------------
@ enable_fpu_access - enable access to the floating-point coprocessors.
@ No params. ORs 0x00f00000 into the word at 0xE000ED88 (SCB coprocessor
@ access word, bits 23..20 set for the two floating-point coprocessors).
@ No return value.
@ ----------------------------------------------------------------------------
	.section .text.enable_fpu_access,"ax",%progbits
	.p2align 2
	.global enable_fpu_access
	.thumb_func
	.type enable_fpu_access, %function
enable_fpu_access:
	ldr.w r0, .L08041164
	ldr r1, [r0]
	orr r1, r1, #0xf00000
	str r1, [r0]
	bx lr
	.short 0xbf00			@ padding
.L08041164:
	.word 0xe000ed88		@ SCB coprocessor access word address
