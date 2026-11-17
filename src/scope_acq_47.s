@ scope_acq_47.s - fn_080242ec: oscilloscope acquisition post-processing (sample copy, resample, trigger search, clamp, rescale)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_080242ec - no parameters, no return value.
@
@ PATH A, taken when byte 0x20000124 == 0 or byte 0x20000126 == 0 (tests at
@ 0x080242fa / 0x08024304, both branch to 0x08024576): calls find_level_crossing
@ (08028de4), then acts only when halfword 0x20000eb4 is negative or byte
@ 0x2000010f != 0, otherwise goes straight to the return at 0x08025060 (when
@ 0x2000010f == 0 it first stores word 0x20000eac = 0x012d0000).
@
@ COPY: for each channel ch from the high nibble up to below the low nibble of
@ byte 0x2000010d (no copy when high >= low), copies 301 samples i = 0..300 into
@ 0x2000044e + ch*0x12d from index
@   idx = (0x20000eb4 & 0x7fff) + i - halfword 0x20000112 (h, zero-extended) - 0x96:
@ - when byte 0x20000125 < 4 and byte 0x2000010c != 3: from the interleaved rings
@   0x200006a8 / 0x20000aa8 (idx wrapped by one conditional subtraction of 0x800
@   when the 16-bit value of idx is >= 0x800; element index = wrapped idx >> 1,
@   bit 0 of the wrapped idx selects the ring, the same source for every channel;
@   mode byte 0x2000010c == 1: even idx raw from 0x200006a8, odd idx from
@   0x20000aa8 minus byte 0x20000448; any other mode: even idx from 0x200006a8
@   minus byte 0x20000449, odd idx raw from 0x20000aa8);
@ - else from 0x200006a8 + ch*0x400 + idx wrapped by one conditional subtraction
@   of 0x400 when the 16-bit value of idx is >= 0x400.
@
@ RESAMPLE, only when the 64-bit value 0x20000f00/0x20000f04 is below 1000
@ (subs/sbcs at 0x08024b24) and alloc_units_of_32_bytes (0803acfc) called with
@ 0x5e1 succeeds (buffer B1; on failure it skips to the final clamp):
@ when the low nibble of 0x2000010d is above the high nibble,
@   decim = byte of (1000 / halfword 0x20000f00) (unsigned divide, low 8 bits),
@   h = halfword 0x20000112,
@   start = (h+0x96) - ((h+0x96) as signed 16-bit * 5) / decim (signed divide),
@   as signed 16-bit and clamped at 0;
@   level = signed 16-bit (halfword 0x20000114, or halfword 0x20000ebe when byte
@   0x20000126 == 0) + 0x80;
@   search limit 0x2f0, or 0x1c3 when decim < 3;
@ per channel ch (counter from the high nibble while counter < low nibble of
@ 0x2000010d, re-read each pass):
@   source channel srcch = byte 0x2000010e (no range check), toggled to
@   (srcch == 0) when mode byte 0x2000010c == 3 and ch == 1;
@   when start <= 300 copies 0x12d-start bytes from
@   0x2000044e + srcch*0x12d + start into B1;
@   allocates a second 0x5e1 buffer B2 and when that succeeds calls
@   fir_filter_rows (0803d5d4) with (B2, B1, 0x5e1/decim, decim), copies all
@   0x5e1 bytes of B2 back into B1 and frees B2 at once;
@   then, unless ch == 1 and mode == 3, searches i from h+0x96 while
@   i < h+limit (signed compare, i 16-bit) for the first adjacent byte pair
@   B1[i], B1[i+1] (unsigned bytes compared with the signed level) with form
@   byte 0x20000110:
@     0: B1[i] <= level < B1[i+1];
@     1: level <= B1[i] and B1[i+1] < level;
@     2: either of both;
@     any other value never matches;
@   pos = i if found; if not found (or the range is empty) pos keeps the value of
@   the previous channel (initially 0); when a search ran and pos is 0 it becomes
@   0x12d; when the search is skipped (ch == 1 and mode 3) the previous pos is
@   used unchanged with no 0 -> 0x12d replacement;
@   then copies 301 bytes from B1[pos - h - 0x96 + k] (k = 0..300, seven per loop
@   pass) into 0x2000044e + srcch*0x12d + k;
@ after the channel loop (or at once when low nibble <= high nibble) frees B1.
@ free = when byte 0x20001080 == 0 call the function pointer at word 0x20001070
@ with r0 = 0, else when ((ptr - word 0x20001078) >> 10) <= 0xae and the halfword
@ at (word 0x2000107c + 2*((ptr - word 0x20001078) >> 5)) is nonzero call
@ zero_bytes (080082bc) on that address with twice that count.
@
@ FINAL CLAMP (reached on every path that did not return early): clamps all 301
@ bytes of every channel from the high nibble up to below the low nibble of
@ 0x2000010d (unsigned bytes above 0xe4 become 0xe4, below 0x1c become 0x1c) and
@ returns.
@
@ PATH B (both bytes 0x20000124 and 0x20000126 nonzero; find_level_crossing is
@ not called): rescales the array 0x2000044e..0x2000057a (ch 0, 301 bytes) with
@   y = (T[byte 0x20000eb9]/T[byte 0x200000fa]) * ((s-128) - o) + 128 + g
@ where o = signed byte 0x20000ebb and g = signed byte 0x200000fc
@ (single-precision floats, evaluated as
@ ((ratio*((s-128)-o) + 128 + o + g) - o), s = unsigned byte), then the array
@ 0x2000057b..0x200006a7 (ch 1) the same with T[byte 0x20000eba]/T[byte
@ 0x200000fb], o = signed byte 0x20000ebc, g = signed byte 0x200000fd; each
@ result is limited to the float range 28.0..228.0, converted by truncation
@ toward zero (vcvt.s32.f32), stored as a byte and limited again to 0x1c..0xe4
@ (T = halfword table at 0x080465cc {10,20,50,100,200,500,1000,2000,5000,10000},
@ indices not range-checked); ch 0 is processed first, then ch 1, then it
@ restores the stack and tail-branches (b.w at 0x08024b18) to fn_0803b078.
@
@ Purpose of the arrays and flags not determined from the code beyond this
@ mechanics.
@ ----------------------------------------------------------------------------
	.section .text.fn_080242ec,"ax",%progbits
	.global fn_080242ec
	.thumb_func
	.type fn_080242ec, %function
fn_080242ec:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x1c
	movw r8, #0xf8
	movt r8, #0x2000                @ r8 = 0x200000f8 (base of the flag / setting bytes)
	ldrb.w r0, [r8, #0x2c]          @ byte 0x20000124
	cmp r0, #0
	beq.w .L08024576
	ldrb.w r0, [r8, #0x2e]          @ byte 0x20000126
	cmp r0, #0
	beq.w .L08024576
	@ PATH B: rescale ch 0 (0x2000044e..) with the ratio of two table entries
	ldrb.w r1, [r8, #0x2]           @ byte 0x200000fa
	movw r0, #:lower16:d_080465cc
	movt r0, #:upper16:d_080465cc   @ r0 = table T
	ldrh.w r1, [r0, r1, lsl #1]
	ldrsb.w r2, [r8, #0x4]          @ g = signed byte 0x200000fc
	vmov s0, r1
	vcvt.f32.u32 s4, s0             @ s4 = (float) T[0x200000fa]
	vmov s0, r2
	vcvt.f32.s32 s6, s0             @ s6 = (float) g
	vldr s0, .L080245f0             @ s0 = -128.0
	vldr s2, .L080245f4             @ s2 = 128.0
	vldr s8, .L080245f8             @ s8 = 228.0 (upper float limit)
	movs r1, #0                     @ r1 = sample index (step 4, 0..0x12c)
	vmov.f32 s10, #2.800000e+01     @ s10 = 28.0 (lower float limit)
	b.n .L08024350
	.short 0xbf00                   @ padding
.L08024348:
	movs r3, #0xe4
.L0802434a:
	strb.w r3, [r2, #0x359]
.L0802434e:
	adds r1, #4
.L08024350:
	ldrb.w r2, [r8, #0xdc1]         @ byte 0x20000eb9
	ldrh.w r2, [r0, r2, lsl #1]
	vmov s12, r2
	vcvt.f32.u32 s12, s12
	vdiv.f32 s12, s12, s4           @ ratio = T[0x20000eb9] / T[0x200000fa]
	add.w r2, r8, r1
	ldrb.w r3, [r2, #0x356]         @ s = byte 0x2000044e + index
	vmov s14, r3
	ldrsb.w r3, [r8, #0xdc3]        @ o = signed byte 0x20000ebb
	vcvt.f32.u32 s14, s14
	vmov s1, r3
	vadd.f32 s14, s14, s0
	vcvt.f32.s32 s1, s1
	vsub.f32 s14, s14, s1
	vmul.f32 s12, s12, s14
	vadd.f32 s12, s12, s2
	vadd.f32 s12, s12, s1
	vadd.f32 s12, s12, s6
	vsub.f32 s14, s12, s1
	vcmp.f32 s14, s8
	vmrs APSR_nzcv, fpscr
	vmov.f32 s12, s8
	bgt.n .L080243bc
	vcmp.f32 s14, s10
	vmov.f32 s12, s14
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s12, s10
.L080243bc:
	vcvt.s32.f32 s12, s12
	vmov r3, s12
	cmp r3, #0xe4
	strb.w r3, [r2, #0x356]
	bls.n .L080243d0
	movs r3, #0xe4
	b.n .L080243d6
.L080243d0:
	cmp r3, #0x1b
	bhi.n .L080243da
	movs r3, #0x1c
.L080243d6:
	strb.w r3, [r2, #0x356]
.L080243da:
	cmp.w r1, #0x12c
	beq.w .L080248b8
	ldrb.w r3, [r8, #0xdc1]
	ldrh.w r3, [r0, r3, lsl #1]
	vmov s12, r3
	vcvt.f32.u32 s12, s12
	vdiv.f32 s12, s12, s4
	ldrb.w r3, [r2, #0x357]
	vmov s14, r3
	ldrsb.w r3, [r8, #0xdc3]
	vcvt.f32.u32 s14, s14
	vmov s1, r3
	vadd.f32 s14, s14, s0
	vcvt.f32.s32 s1, s1
	vsub.f32 s14, s14, s1
	vmul.f32 s12, s12, s14
	vadd.f32 s12, s12, s2
	vadd.f32 s12, s12, s1
	vadd.f32 s12, s12, s6
	vsub.f32 s14, s12, s1
	vcmp.f32 s14, s8
	vmrs APSR_nzcv, fpscr
	vmov.f32 s12, s8
	bgt.n .L0802444a
	vcmp.f32 s14, s10
	vmov.f32 s12, s14
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s12, s10
.L0802444a:
	vcvt.s32.f32 s12, s12
	vmov r3, s12
	cmp r3, #0xe4
	strb.w r3, [r2, #0x357]
	bls.n .L08024460
	movs r3, #0xe4
	b.n .L08024466
	.short 0xbf00                   @ padding
.L08024460:
	cmp r3, #0x1b
	bhi.n .L0802446a
	movs r3, #0x1c
.L08024466:
	strb.w r3, [r2, #0x357]
.L0802446a:
	ldrb.w r3, [r8, #0xdc1]
	ldrh.w r3, [r0, r3, lsl #1]
	vmov s12, r3
	vcvt.f32.u32 s12, s12
	vdiv.f32 s12, s12, s4
	ldrb.w r3, [r2, #0x358]
	vmov s14, r3
	ldrsb.w r3, [r8, #0xdc3]
	vcvt.f32.u32 s14, s14
	vmov s1, r3
	vadd.f32 s14, s14, s0
	vcvt.f32.s32 s1, s1
	vsub.f32 s14, s14, s1
	vmul.f32 s12, s12, s14
	vadd.f32 s12, s12, s2
	vadd.f32 s12, s12, s1
	vadd.f32 s12, s12, s6
	vsub.f32 s14, s12, s1
	vcmp.f32 s14, s8
	vmrs APSR_nzcv, fpscr
	vmov.f32 s12, s8
	bgt.n .L080244d2
	vcmp.f32 s14, s10
	vmov.f32 s12, s14
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s12, s10
.L080244d2:
	vcvt.s32.f32 s12, s12
	vmov r3, s12
	cmp r3, #0xe4
	strb.w r3, [r2, #0x358]
	bls.n .L080244e8
	movs r3, #0xe4
	b.n .L080244ee
	.short 0xbf00                   @ padding
.L080244e8:
	cmp r3, #0x1b
	bhi.n .L080244f2
	movs r3, #0x1c
.L080244ee:
	strb.w r3, [r2, #0x358]
.L080244f2:
	ldrb.w r3, [r8, #0xdc1]
	ldrh.w r3, [r0, r3, lsl #1]
	vmov s12, r3
	vcvt.f32.u32 s12, s12
	vdiv.f32 s12, s12, s4
	ldrb.w r3, [r2, #0x359]
	vmov s14, r3
	ldrsb.w r3, [r8, #0xdc3]
	vcvt.f32.u32 s14, s14
	vmov s1, r3
	vadd.f32 s14, s14, s0
	vcvt.f32.s32 s1, s1
	vsub.f32 s14, s14, s1
	vmul.f32 s12, s12, s14
	vadd.f32 s12, s12, s2
	vadd.f32 s12, s12, s1
	vadd.f32 s12, s12, s6
	vsub.f32 s14, s12, s1
	vcmp.f32 s14, s8
	vmrs APSR_nzcv, fpscr
	vmov.f32 s12, s8
	bgt.n .L0802455a
	vcmp.f32 s14, s10
	vmov.f32 s12, s14
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s12, s10
.L0802455a:
	vcvt.s32.f32 s12, s12
	vmov r3, s12
	cmp r3, #0xe4
	strb.w r3, [r2, #0x359]
	bhi.w .L08024348
	cmp r3, #0x1b
	bhi.w .L0802434e
	movs r3, #0x1c
	b.n .L0802434a
	@ PATH A: find the trigger crossing, then copy / resample / clamp
.L08024576:
	bl find_level_crossing
	ldrsh.w r1, [r8, #0xdbc]        @ halfword 0x20000eb4
	ldrb.w r0, [r8, #0x17]          @ byte 0x2000010f
	cmp r1, #0
	bmi.n .L0802458c
	cmp r0, #0
	beq.w .L08025060
.L0802458c:
	cbnz r0, .L08024598
	movs r0, #0
	movt r0, #0x12d
	str.w r0, [r8, #0xdb4]          @ word 0x20000eac = 0x012d0000
.L08024598:
	ldrb.w r0, [r8, #0x15]          @ byte 0x2000010d (channel nibbles)
	and.w r1, r0, #0xf
	cmp.w r1, r0, lsr #4
	str r1, [sp, #0xc]
	bls.w .L08024b1c
	ldrb.w r10, [r8, #0x14]         @ byte 0x2000010c (mode)
	lsrs r2, r0, #4
	ldrb.w r0, [r8, #0x2d]          @ byte 0x20000125
	sub.w r1, r10, #3
	clz r1, r1
	cmp r0, #3
	mov.w r0, #0
	ldrh.w r9, [r8, #0x1a]          @ h = halfword 0x20000112
	lsr.w r1, r1, #5                @ r1 = (mode == 3)
	it hi
	movhi r0, #1
	orrs r0, r1
	str r0, [sp, #8]                @ nonzero: use the per-channel rings (0x20000125 >= 4 or mode == 3)
	ldrb.w r0, [r8, #0x351]         @ byte 0x20000449
	mov.w r11, #0
	str r0, [sp, #0x18]
	ldrb.w r0, [r8, #0x350]         @ byte 0x20000448
	str r0, [sp, #0x14]
	movw r0, #0x12d
	smlabb lr, r2, r0, r8           @ lr = r8 + ch*0x12d
	add.w r0, r8, #0x5b0            @ r0 = 0x200006a8 (ring 0)
	b.n .L0802460c
.L080245f0:
	.word 0xc3000000                @ float -128.0
.L080245f4:
	.word 0x43000000                @ float 128.0
.L080245f8:
	.word 0x43640000                @ float 228.0
.L080245fc:
	ldr r2, [sp, #0x10]
	ldr r1, [sp, #0xc]
	adds r2, #1
	cmp r2, r1
	addw lr, lr, #0x12d
	beq.w .L08024b1c
.L0802460c:
	ldr r1, [sp, #8]
	str r2, [sp, #0x10]
	cmp r1, #0
	beq.w .L08024730
	lsls r5, r2, #0xa               @ r5 = ch*0x400
	movs r4, #0
	nop
.L0802461c:
	ldrh.w r7, [r8, #0xdbc]
	sub.w r1, r4, r9
	bfc r7, #0xf, #0x11
	add r7, r1
	sub.w r2, r7, #0x96
	uxth r3, r2
	cmp.w r11, r3, lsr #10
	it ne
	subwne r2, r7, #0x496
	uxtah r2, r5, r2
	ldrb r2, [r0, r2]
	add.w r7, lr, r4
	strb.w r2, [r7, #0x356]
	ldrh.w r2, [r8, #0xdbc]
	adds r4, #7
	bfc r2, #0xf, #0x11
	add r2, r1
	sub.w r3, r2, #0x95
	uxth r6, r3
	cmp.w r11, r6, lsr #10
	it ne
	subwne r3, r2, #0x495
	uxtah r2, r5, r3
	ldrb r2, [r0, r2]
	strb.w r2, [r7, #0x357]
	ldrh.w r2, [r8, #0xdbc]
	bfc r2, #0xf, #0x11
	add r2, r1
	sub.w r3, r2, #0x94
	uxth r6, r3
	cmp.w r11, r6, lsr #10
	it ne
	subwne r3, r2, #0x494
	uxtah r2, r5, r3
	ldrb r2, [r0, r2]
	strb.w r2, [r7, #0x358]
	ldrh.w r2, [r8, #0xdbc]
	bfc r2, #0xf, #0x11
	add r2, r1
	sub.w r3, r2, #0x93
	uxth r6, r3
	cmp.w r11, r6, lsr #10
	it ne
	subwne r3, r2, #0x493
	uxtah r2, r5, r3
	ldrb r2, [r0, r2]
	strb.w r2, [r7, #0x359]
	ldrh.w r2, [r8, #0xdbc]
	bfc r2, #0xf, #0x11
	add r2, r1
	sub.w r3, r2, #0x92
	uxth r6, r3
	cmp.w r11, r6, lsr #10
	it ne
	subwne r3, r2, #0x492
	uxtah r2, r5, r3
	ldrb r2, [r0, r2]
	strb.w r2, [r7, #0x35a]
	ldrh.w r2, [r8, #0xdbc]
	bfc r2, #0xf, #0x11
	add r2, r1
	sub.w r3, r2, #0x91
	uxth r6, r3
	cmp.w r11, r6, lsr #10
	it ne
	subwne r3, r2, #0x491
	uxtah r2, r5, r3
	ldrb r2, [r0, r2]
	strb.w r2, [r7, #0x35b]
	ldrh.w r2, [r8, #0xdbc]
	bfc r2, #0xf, #0x11
	add r1, r2
	sub.w r2, r1, #0x90
	uxth r3, r2
	cmp.w r11, r3, lsr #10
	it ne
	subne.w r2, r1, #0x490
	uxtah r1, r5, r2
	ldrb r1, [r0, r1]
	movw r2, #0x12d
	cmp r4, r2
	strb.w r1, [r7, #0x35c]
	bne.w .L0802461c
	b.n .L080245fc
	.short 0xbf00                   @ padding
	@ interleaved-ring copy (byte 0x20000125 < 4 and mode != 3)
.L08024730:
	movs r4, #0
	b.n .L08024740
.L08024734:
	add r1, r8
	ldrb.w r1, [r1, #0x5b0]
.L0802473a:
	strb.w r1, [r12, #0x359]
	adds r4, #4
.L08024740:
	ldrh.w r1, [r8, #0xdbc]
	sub.w r5, r4, r9
	bfc r1, #0xf, #0x11
	add r1, r5
	sub.w r2, r1, #0x96
	uxth r3, r2
	cmp.w r11, r3, lsr #11
	it ne
	subwne r2, r1, #0x896
	uxth r1, r2
	and.w r7, r2, #1
	cmp.w r10, #1
	lsr.w r1, r1, #1
	bne.n .L08024778
	cbnz r7, .L08024784
	add r1, r8
	ldrb.w r1, [r1, #0x5b0]
	b.n .L08024796
.L08024778:
	cbnz r7, .L08024790
	add r1, r8
	ldrb.w r1, [r1, #0x5b0]
	ldr r2, [sp, #0x18]
	b.n .L0802478c
.L08024784:
	add r1, r8
	ldrb.w r1, [r1, #0x9b0]
	ldr r2, [sp, #0x14]
.L0802478c:
	subs r1, r1, r2
	b.n .L08024796
.L08024790:
	add r1, r8
	ldrb.w r1, [r1, #0x9b0]
.L08024796:
	add.w r12, lr, r4
	cmp.w r4, #0x12c
	strb.w r1, [r12, #0x356]
	beq.w .L080245fc
	ldrh.w r1, [r8, #0xdbc]
	adds r2, r4, #1
	bfc r1, #0xf, #0x11
	sub.w r2, r2, r9
	add r1, r2
	sub.w r2, r1, #0x96
	uxth r3, r2
	cmp.w r11, r3, lsr #11
	it ne
	subwne r2, r1, #0x896
	uxth r1, r2
	and.w r7, r2, #1
	cmp.w r10, #1
	lsr.w r1, r1, #1
	bne.n .L080247e0
	cbnz r7, .L080247f0
	add r1, r8
	ldrb.w r1, [r1, #0x5b0]
	b.n .L08024802
.L080247e0:
	cbnz r7, .L080247fc
	add r1, r8
	ldrb.w r1, [r1, #0x5b0]
	ldr r2, [sp, #0x18]
	subs r1, r1, r2
	b.n .L08024802
	.short 0xbf00                   @ padding
.L080247f0:
	add r1, r8
	ldrb.w r1, [r1, #0x9b0]
	ldr r2, [sp, #0x14]
	subs r1, r1, r2
	b.n .L08024802
.L080247fc:
	add r1, r8
	ldrb.w r1, [r1, #0x9b0]
.L08024802:
	strb.w r1, [r12, #0x357]
	ldrh.w r1, [r8, #0xdbc]
	bfc r1, #0xf, #0x11
	add r1, r5
	sub.w r2, r1, #0x94
	uxth r3, r2
	cmp.w r11, r3, lsr #11
	it ne
	subwne r2, r1, #0x894
	uxth r1, r2
	and.w r7, r2, #1
	cmp.w r10, #1
	lsr.w r1, r1, #1
	bne.n .L0802483c
	cbnz r7, .L0802484c
	add r1, r8
	ldrb.w r1, [r1, #0x5b0]
	b.n .L0802485e
	.short 0xbf00                   @ padding
.L0802483c:
	cbnz r7, .L08024858
	add r1, r8
	ldrb.w r1, [r1, #0x5b0]
	ldr r2, [sp, #0x18]
	subs r1, r1, r2
	b.n .L0802485e
	.short 0xbf00                   @ padding
.L0802484c:
	add r1, r8
	ldrb.w r1, [r1, #0x9b0]
	ldr r2, [sp, #0x14]
	subs r1, r1, r2
	b.n .L0802485e
.L08024858:
	add r1, r8
	ldrb.w r1, [r1, #0x9b0]
.L0802485e:
	strb.w r1, [r12, #0x358]
	ldrh.w r1, [r8, #0xdbc]
	bfc r1, #0xf, #0x11
	add r1, r5
	sub.w r2, r1, #0x93
	uxth r3, r2
	cmp.w r11, r3, lsr #11
	it ne
	subwne r2, r1, #0x893
	uxth r1, r2
	and.w r5, r2, #1
	cmp.w r10, #1
	lsr.w r1, r1, #1
	bne.n .L080248a0
	cmp r5, #0
	beq.w .L08024734
	add r1, r8
	ldrb.w r1, [r1, #0x9b0]
	ldr r2, [sp, #0x14]
	subs r1, r1, r2
	b.n .L0802473a
	.short 0xbf00                   @ padding
.L080248a0:
	cbnz r5, .L080248b0
	add r1, r8
	ldrb.w r1, [r1, #0x5b0]
	ldr r2, [sp, #0x18]
	subs r1, r1, r2
	b.n .L0802473a
	.short 0xbf00                   @ padding
.L080248b0:
	add r1, r8
	ldrb.w r1, [r1, #0x9b0]
	b.n .L0802473a
	@ PATH B: rescale ch 1 (0x2000057b..) with T[0x20000eba] / T[0x200000fb]
.L080248b8:
	ldrb.w r1, [r8, #0x3]           @ byte 0x200000fb
	ldrsb.w r2, [r8, #0x5]          @ g = signed byte 0x200000fd
	ldrh.w r1, [r0, r1, lsl #1]
	vmov s6, r2
	vmov s4, r1
	movw r1, #0xfed4
	vldr s8, .L080245f8             @ s8 = 228.0
	vcvt.f32.u32 s4, s4
	vcvt.f32.s32 s6, s6
	movt r1, #0xffff                @ r1 = -300 (index counts up to 0 in steps of 4)
	vmov.f32 s10, #2.800000e+01     @ s10 = 28.0
	b.n .L080248f0
	.short 0xbf00                   @ padding
.L080248e8:
	movs r3, #0xe4
.L080248ea:
	strb.w r3, [r2, #0x5b2]
.L080248ee:
	adds r1, #4
.L080248f0:
	ldrb.w r2, [r8, #0xdc2]         @ byte 0x20000eba
	ldrh.w r2, [r0, r2, lsl #1]
	vmov s12, r2
	vcvt.f32.u32 s12, s12
	vdiv.f32 s12, s12, s4
	add.w r2, r8, r1
	ldrb.w r3, [r2, #0x5af]
	vmov s14, r3
	ldrsb.w r3, [r8, #0xdc4]        @ o = signed byte 0x20000ebc
	vcvt.f32.u32 s14, s14
	vmov s1, r3
	vadd.f32 s14, s14, s0
	vcvt.f32.s32 s1, s1
	vsub.f32 s14, s14, s1
	vmul.f32 s12, s12, s14
	vadd.f32 s12, s12, s2
	vadd.f32 s12, s12, s1
	vadd.f32 s12, s12, s6
	vsub.f32 s14, s12, s1
	vcmp.f32 s14, s8
	vmrs APSR_nzcv, fpscr
	vmov.f32 s12, s8
	bgt.n .L0802495c
	vcmp.f32 s14, s10
	vmov.f32 s12, s14
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s12, s10
.L0802495c:
	vcvt.s32.f32 s12, s12
	vmov r3, s12
	cmp r3, #0xe4
	strb.w r3, [r2, #0x5af]
	bls.n .L08024970
	movs r3, #0xe4
	b.n .L08024976
.L08024970:
	cmp r3, #0x1b
	bhi.n .L0802497a
	movs r3, #0x1c
.L08024976:
	strb.w r3, [r2, #0x5af]
.L0802497a:
	cmp r1, #0
	beq.w .L08024b12
	ldrb.w r3, [r8, #0xdc2]
	ldrh.w r3, [r0, r3, lsl #1]
	vmov s12, r3
	vcvt.f32.u32 s12, s12
	vdiv.f32 s12, s12, s4
	ldrb.w r3, [r2, #0x5b0]
	vmov s14, r3
	ldrsb.w r3, [r8, #0xdc4]
	vcvt.f32.u32 s14, s14
	vmov s1, r3
	vadd.f32 s14, s14, s0
	vcvt.f32.s32 s1, s1
	vsub.f32 s14, s14, s1
	vmul.f32 s12, s12, s14
	vadd.f32 s12, s12, s2
	vadd.f32 s12, s12, s1
	vadd.f32 s12, s12, s6
	vsub.f32 s14, s12, s1
	vcmp.f32 s14, s8
	vmrs APSR_nzcv, fpscr
	vmov.f32 s12, s8
	bgt.n .L080249e8
	vcmp.f32 s14, s10
	vmov.f32 s12, s14
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s12, s10
.L080249e8:
	vcvt.s32.f32 s12, s12
	vmov r3, s12
	cmp r3, #0xe4
	strb.w r3, [r2, #0x5b0]
	bls.n .L080249fc
	movs r3, #0xe4
	b.n .L08024a02
.L080249fc:
	cmp r3, #0x1b
	bhi.n .L08024a06
	movs r3, #0x1c
.L08024a02:
	strb.w r3, [r2, #0x5b0]
.L08024a06:
	ldrb.w r3, [r8, #0xdc2]
	ldrh.w r3, [r0, r3, lsl #1]
	vmov s12, r3
	vcvt.f32.u32 s12, s12
	vdiv.f32 s12, s12, s4
	ldrb.w r3, [r2, #0x5b1]
	vmov s14, r3
	ldrsb.w r3, [r8, #0xdc4]
	vcvt.f32.u32 s14, s14
	vmov s1, r3
	vadd.f32 s14, s14, s0
	vcvt.f32.s32 s1, s1
	vsub.f32 s14, s14, s1
	vmul.f32 s12, s12, s14
	vadd.f32 s12, s12, s2
	vadd.f32 s12, s12, s1
	vadd.f32 s12, s12, s6
	vsub.f32 s14, s12, s1
	vcmp.f32 s14, s8
	vmrs APSR_nzcv, fpscr
	vmov.f32 s12, s8
	bgt.n .L08024a6e
	vcmp.f32 s14, s10
	vmov.f32 s12, s14
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s12, s10
.L08024a6e:
	vcvt.s32.f32 s12, s12
	vmov r3, s12
	cmp r3, #0xe4
	strb.w r3, [r2, #0x5b1]
	bls.n .L08024a84
	movs r3, #0xe4
	b.n .L08024a8a
	.short 0xbf00                   @ padding
.L08024a84:
	cmp r3, #0x1b
	bhi.n .L08024a8e
	movs r3, #0x1c
.L08024a8a:
	strb.w r3, [r2, #0x5b1]
.L08024a8e:
	ldrb.w r3, [r8, #0xdc2]
	ldrh.w r3, [r0, r3, lsl #1]
	vmov s12, r3
	vcvt.f32.u32 s12, s12
	vdiv.f32 s12, s12, s4
	ldrb.w r3, [r2, #0x5b2]
	vmov s14, r3
	ldrsb.w r3, [r8, #0xdc4]
	vcvt.f32.u32 s14, s14
	vmov s1, r3
	vadd.f32 s14, s14, s0
	vcvt.f32.s32 s1, s1
	vsub.f32 s14, s14, s1
	vmul.f32 s12, s12, s14
	vadd.f32 s12, s12, s2
	vadd.f32 s12, s12, s1
	vadd.f32 s12, s12, s6
	vsub.f32 s14, s12, s1
	vcmp.f32 s14, s8
	vmrs APSR_nzcv, fpscr
	vmov.f32 s12, s8
	bgt.n .L08024af6
	vcmp.f32 s14, s10
	vmov.f32 s12, s14
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s12, s10
.L08024af6:
	vcvt.s32.f32 s12, s12
	vmov r3, s12
	cmp r3, #0xe4
	strb.w r3, [r2, #0x5b2]
	bhi.w .L080248e8
	cmp r3, #0x1b
	bhi.w .L080248ee
	movs r3, #0x1c
	b.n .L080248ea
	@ PATH B exit: restore the stack and tail-branch to fn_0803b078
.L08024b12:
	add sp, #0x1c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	b.w fn_0803b078
	@ RESAMPLE entry (also reached from PATH A COPY when all channels are done)
.L08024b1c:
	ldr.w r5, [r8, #0xe08]          @ word 0x20000f00
	ldr.w r0, [r8, #0xe0c]          @ word 0x20000f04
	subs.w r1, r5, #0x3e8
	sbcs r0, r0, #0                 @ carry set: 64-bit value >= 1000, skip the resample
	bcs.w .L08024f88
	movw r0, #0x5e1
	bl alloc_units_of_32_bytes      @ buffer B1 (0x5e1 bytes)
	cmp r0, #0
	beq.w .L08024f88
	mov r4, r0                      @ r4 = B1
	ldrb.w r0, [r8, #0x15]
	and.w r1, r0, #0xf
	cmp.w r1, r0, lsr #4
	bls.w .L08024f56
	ldrh.w r3, [r8, #0x1a]          @ h = halfword 0x20000112
	uxth r1, r5
	mov.w r2, #0x3e8
	udiv r1, r2, r1                 @ 1000 / halfword 0x20000f00
	add.w r2, r3, #0x96
	sxth r3, r2
	add.w r3, r3, r3, lsl #2        @ (h+0x96) * 5
	uxtb r6, r1                     @ decim
	sdiv r1, r3, r6
	lsrs r3, r0, #4                 @ ch counter = high nibble
	ldrb.w r0, [r8, #0x2e]
	subs r1, r2, r1                 @ start
	add.w r2, r8, #0x1c             @ r2 = 0x20000114
	ldrb.w r12, [r8, #0x14]
	cmp r0, #0
	it eq
	addweq r2, r8, #0xdc6           @ byte 0x20000126 == 0: halfword 0x20000ebe
	ldrh r0, [r2]
	sxth r1, r1
	ldrb.w r2, [r8, #0x16]          @ byte 0x2000010e
	adds r0, #0x80                  @ level
	bic.w r1, r1, r1, asr #31       @ clamp start at 0
	uxth.w r10, r1
	movw r7, #0x12d
	mov.w r1, #0x2f0
	sxth r0, r0
	str r2, [sp, #0x14]
	sub.w r9, r7, r10               @ bytes to copy = 0x12d - start
	str r6, [sp, #8]
	cmp r6, #3
	it cc
	movwcc r1, #0x1c3
	str r1, [sp, #0]
	str r0, [sp, #0x18]
	movs r0, #0
	movw r11, #0x5e1
	str r0, [sp, #0xc]
	nop
.L08024bc0:
	str r3, [sp, #0x10]
	eor.w r1, r3, #1
	ldr r3, [sp, #0x14]
	eor.w r0, r12, #3
	uxtb r2, r3
	orrs r0, r1
	clz r2, r2
	it eq
	lsreq r3, r2, #5
	cmp.w r10, #0x12c
	str r3, [sp, #0x14]
	bhi.n .L08024c44
	ldr r0, [sp, #0x14]
	movs r3, #0
	uxtb r0, r0
	movs r1, #0
.L08024be8:
	add.w r6, r3, r10
	smlabb r2, r0, r7, r8
	add r6, r2
	ldrb.w r5, [r6, #0x356]
	orr.w r6, r1, #1
	uxth r6, r6
	cmp r9, r6
	strb r5, [r4, r3]
	ble.n .L08024c44
	add.w r3, r6, r10
	add r3, r2
	ldrb.w r5, [r3, #0x356]
	orr.w r3, r1, #2
	uxth r3, r3
	cmp r9, r3
	strb r5, [r4, r6]
	ble.n .L08024c44
	add.w r6, r3, r10
	add r6, r2
	ldrb.w r5, [r6, #0x356]
	orr.w r6, r1, #3
	uxth r6, r6
	cmp r9, r6
	strb r5, [r4, r3]
	ble.n .L08024c44
	add.w r3, r6, r10
	add r2, r3
	adds r1, #4
	ldrb.w r2, [r2, #0x356]
	uxth r3, r1
	cmp r9, r3
	strb r2, [r4, r6]
	bgt.n .L08024be8
	nop
.L08024c44:
	movw r0, #0x5e1
	bl alloc_units_of_32_bytes      @ buffer B2 (0x5e1 bytes)
	cmp r0, #0
	beq.w .L08024d82
	ldr r3, [sp, #8]
	mov r1, r4
	udiv r2, r11, r3                @ 0x5e1 / decim
	mov r6, r0                      @ r6 = B2
	bl fir_filter_rows
	movs r0, #0
	nop
.L08024c64:
	ldrb r1, [r6, r0]
	adds r2, r6, r0
	strb r1, [r4, r0]
	ldrb r3, [r2, #1]
	adds r1, r4, r0
	strb r3, [r1, #1]
	ldrb r3, [r2, #2]
	adds r0, #0x2b
	strb r3, [r1, #2]
	ldrb r3, [r2, #3]
	cmp r0, r11
	strb r3, [r1, #3]
	ldrb r3, [r2, #4]
	strb r3, [r1, #4]
	ldrb r3, [r2, #5]
	strb r3, [r1, #5]
	ldrb r3, [r2, #6]
	strb r3, [r1, #6]
	ldrb r3, [r2, #7]
	strb r3, [r1, #7]
	ldrb r3, [r2, #8]
	strb r3, [r1, #8]
	ldrb r3, [r2, #9]
	strb r3, [r1, #9]
	ldrb r3, [r2, #0xa]
	strb r3, [r1, #0xa]
	ldrb r3, [r2, #0xb]
	strb r3, [r1, #0xb]
	ldrb r3, [r2, #0xc]
	strb r3, [r1, #0xc]
	ldrb r3, [r2, #0xd]
	strb r3, [r1, #0xd]
	ldrb r3, [r2, #0xe]
	strb r3, [r1, #0xe]
	ldrb r3, [r2, #0xf]
	strb r3, [r1, #0xf]
	ldrb r3, [r2, #0x10]
	strb r3, [r1, #0x10]
	ldrb r3, [r2, #0x11]
	strb r3, [r1, #0x11]
	ldrb r3, [r2, #0x12]
	strb r3, [r1, #0x12]
	ldrb r3, [r2, #0x13]
	strb r3, [r1, #0x13]
	ldrb r3, [r2, #0x14]
	strb r3, [r1, #0x14]
	ldrb r3, [r2, #0x15]
	strb r3, [r1, #0x15]
	ldrb r3, [r2, #0x16]
	strb r3, [r1, #0x16]
	ldrb r3, [r2, #0x17]
	strb r3, [r1, #0x17]
	ldrb r3, [r2, #0x18]
	strb r3, [r1, #0x18]
	ldrb r3, [r2, #0x19]
	strb r3, [r1, #0x19]
	ldrb r3, [r2, #0x1a]
	strb r3, [r1, #0x1a]
	ldrb r3, [r2, #0x1b]
	strb r3, [r1, #0x1b]
	ldrb r3, [r2, #0x1c]
	strb r3, [r1, #0x1c]
	ldrb r3, [r2, #0x1d]
	strb r3, [r1, #0x1d]
	ldrb r3, [r2, #0x1e]
	strb r3, [r1, #0x1e]
	ldrb r3, [r2, #0x1f]
	strb r3, [r1, #0x1f]
	ldrb.w r3, [r2, #0x20]
	strb.w r3, [r1, #0x20]
	ldrb.w r3, [r2, #0x21]
	strb.w r3, [r1, #0x21]
	ldrb.w r3, [r2, #0x22]
	strb.w r3, [r1, #0x22]
	ldrb.w r3, [r2, #0x23]
	strb.w r3, [r1, #0x23]
	ldrb.w r3, [r2, #0x24]
	strb.w r3, [r1, #0x24]
	ldrb.w r3, [r2, #0x25]
	strb.w r3, [r1, #0x25]
	ldrb.w r3, [r2, #0x26]
	strb.w r3, [r1, #0x26]
	ldrb.w r3, [r2, #0x27]
	strb.w r3, [r1, #0x27]
	ldrb.w r3, [r2, #0x28]
	strb.w r3, [r1, #0x28]
	ldrb.w r3, [r2, #0x29]
	strb.w r3, [r1, #0x29]
	ldrb.w r2, [r2, #0x2a]
	strb.w r2, [r1, #0x2a]
	bne.n .L08024c64
	@ free B2
	movw r1, #0x1070
	movt r1, #0x2000                @ r1 = 0x20001070
	ldrb r0, [r1, #0x10]            @ byte 0x20001080
	cbz r0, .L08024d7c
	ldr r0, [r1, #8]                @ word 0x20001078
	subs r0, r6, r0
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L08024d82
	movw r1, #0x1070
	movt r1, #0x2000
	ldr r2, [r1, #0xc]              @ word 0x2000107c
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L08024d82
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L08024d82
	.short 0xbf00                   @ padding
.L08024d7c:
	ldr r1, [r1]                    @ function pointer at word 0x20001070
	movs r0, #0
	blx r1
.L08024d82:
	ldr r0, [sp, #0x10]
	ldrb.w r12, [r8, #0x14]
	ldrsh.w lr, [r8, #0x1a]
	cmp r0, #1
	it eq
	cmpeq.w r12, #3
	beq.w .L08024eac
	uxth.w r0, lr
	add.w r2, r0, #0x96
	ldr r0, [sp, #0]
	uxth r6, r2
	add.w r3, r0, lr
	cmp r3, r6
	ble.w .L08024ed8
	ldrb.w r0, [r8, #0x18]          @ form byte 0x20000110
	ldr r5, [sp, #0x18]
	cmp r0, #0
	beq.n .L08024e4c
	str.w r12, [sp, #4]
	cmp r0, #2
	sub.w r12, r0, #1
	beq.n .L08024dda
	cmp.w r12, #2
	bcs.n .L08024eb0
	ldr.w r12, [sp, #4]
	b.n .L08024e0c
.L08024dd0:
	adds r2, #1
	uxth r6, r2
	cmp r3, r6
	ble.w .L08024f4e
.L08024dda:
	ldrb r0, [r4, r6]
	cmp r0, r5
	bgt.n .L08024dee
	adds r5, r6, r4
	ldrb r5, [r5, #1]
	ldr r1, [sp, #0x18]
	cmp r5, r1
	ldr r5, [sp, #0x18]
	bgt.w .L08024f50
.L08024dee:
	cmp.w r12, #1
	bhi.n .L08024dd0
	cmp r0, r5
	blt.n .L08024dd0
	adds r0, r6, r4
	ldrb r0, [r0, #1]
	cmp r0, r5
	bge.n .L08024dd0
	b.n .L08024f50
	.short 0xbf00                   @ padding
.L08024e04:
	adds r2, #1
	uxth r6, r2
	cmp r3, r6
	ble.n .L08024ed8
.L08024e0c:
	orr.w r1, r0, #2
	cmp r1, #2
	bne.n .L08024e34
	ldrb r1, [r4, r6]
	cmp r1, r5
	bgt.n .L08024e2c
	adds r5, r6, r4
	ldrb r5, [r5, #1]
	ldr.w r12, [sp, #0x18]
	cmp r5, r12
	ldr.w r12, [sp, #4]
	ldr r5, [sp, #0x18]
	bgt.n .L08024eda
.L08024e2c:
	cmp r1, r5
	blt.n .L08024e04
	b.n .L08024e3a
	.short 0xbf00                   @ padding
.L08024e34:
	ldrb r1, [r4, r6]
	cmp r1, r5
	blt.n .L08024e04
.L08024e3a:
	adds r1, r6, r4
	ldrb r1, [r1, #1]
	cmp r1, r5
	bge.n .L08024e04
	b.n .L08024eda
.L08024e44:
	adds r2, #4
	uxth r6, r2
	cmp r3, r6
	ble.n .L08024ed8
.L08024e4c:
	ldrb r0, [r4, r6]
	cmp r0, r5
	bgt.n .L08024e5a
	adds r0, r6, r4
	ldrb r0, [r0, #1]
	cmp r0, r5
	bgt.n .L08024eda
.L08024e5a:
	adds r0, r2, #1
	uxth r1, r0
	cmp r3, r1
	ble.n .L08024ed8
	ldrb r5, [r4, r1]
	ldr r6, [sp, #0x18]
	cmp r5, r6
	bgt.n .L08024e74
	add r1, r4
	ldrb r1, [r1, #1]
	mov r5, r6
	cmp r1, r6
	bgt.n .L08024ea8
.L08024e74:
	adds r0, r2, #2
	uxth r1, r0
	cmp r3, r1
	ble.n .L08024ed8
	ldrb r5, [r4, r1]
	ldr r6, [sp, #0x18]
	cmp r5, r6
	ldr r5, [sp, #0x18]
	bgt.n .L08024e8e
	add r1, r4
	ldrb r1, [r1, #1]
	cmp r1, r5
	bgt.n .L08024ea8
.L08024e8e:
	adds r0, r2, #3
	uxth r1, r0
	cmp r3, r1
	ble.n .L08024ed8
	ldrb r5, [r4, r1]
	ldr r6, [sp, #0x18]
	cmp r5, r6
	ldr r5, [sp, #0x18]
	bgt.n .L08024e44
	add r1, r4
	ldrb r1, [r1, #1]
	cmp r1, r5
	ble.n .L08024e44
.L08024ea8:
	mov r2, r0
	b.n .L08024eda
.L08024eac:
	ldr r2, [sp, #0xc]
	b.n .L08024ee2
.L08024eb0:
	ldr.w r12, [sp, #4]
	b.n .L08024ec0
	.short 0xbf00                   @ padding
.L08024eb8:
	adds r2, #1
	uxth r6, r2
	cmp r3, r6
	ble.n .L08024ed8
.L08024ec0:
	orr.w r1, r0, #2
	cmp r1, #2
	bne.n .L08024eb8
	ldrb r1, [r4, r6]
	cmp r1, r5
	bgt.n .L08024eb8
	adds r1, r6, r4
	ldrb r1, [r1, #1]
	cmp r1, r5
	ble.n .L08024eb8
	b.n .L08024eda
.L08024ed8:
	ldr r2, [sp, #0xc]
.L08024eda:
	lsls r0, r2, #0x10
	it eq
	movweq r2, #0x12d
.L08024ee2:
	str r2, [sp, #0xc]
	ldr r0, [sp, #0x14]
	uxth r1, r2
	uxtb r0, r0
	sub.w r1, r1, lr
	smlabb r0, r0, r7, r8
	add r1, r4
	movs r2, #0
	nop
.L08024ef8:
	adds r3, r1, r2
	ldrb.w r6, [r3, #-0x96]
	adds r5, r0, r2
	strb.w r6, [r5, #0x356]
	ldrb.w r6, [r3, #-0x95]
	adds r2, #7
	strb.w r6, [r5, #0x357]
	ldrb.w r6, [r3, #-0x94]
	cmp r2, r7
	strb.w r6, [r5, #0x358]
	ldrb.w r6, [r3, #-0x93]
	strb.w r6, [r5, #0x359]
	ldrb.w r6, [r3, #-0x92]
	strb.w r6, [r5, #0x35a]
	ldrb.w r6, [r3, #-0x91]
	strb.w r6, [r5, #0x35b]
	ldrb.w r3, [r3, #-0x90]
	strb.w r3, [r5, #0x35c]
	bne.n .L08024ef8
	ldrb.w r0, [r8, #0x15]
	ldr r3, [sp, #0x10]
	and.w r0, r0, #0xf
	adds r3, #1
	cmp r3, r0
	blo.w .L08024bc0
	b.n .L08024f56
.L08024f4e:
	ldr r2, [sp, #0xc]
.L08024f50:
	ldr.w r12, [sp, #4]
	b.n .L08024eda
	@ free B1
.L08024f56:
	movw r2, #0x1070
	movt r2, #0x2000
	ldrb r0, [r2, #0x10]
	cbz r0, .L08024f82
	ldr r0, [r2, #8]
	subs r0, r4, r0
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L08024f88
	ldr r2, [r2, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L08024f88
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L08024f88
.L08024f82:
	ldr r1, [r2]
	movs r0, #0
	blx r1
	@ FINAL CLAMP: all 301 bytes of every channel limited to 0x1c..0xe4
.L08024f88:
	ldrb.w r1, [r8, #0x15]
	and.w r0, r1, #0xf
	cmp.w r0, r1, lsr #4
	bls.n .L08025060
	lsrs r1, r1, #4
	subs r2, r0, r1
	lsls r2, r2, #0x1f
	mvn.w r2, r1
	beq.n .L0802505c
	movw r3, #0x12d
	smlabb r3, r1, r3, r8
	mvn r6, #0x12c
	b.n .L08024fba
.L08024fb0:
	movs r7, #0xe4
.L08024fb2:
	strb.w r7, [r5, #0x489]
.L08024fb6:
	adds r6, #7
	beq.n .L0802505a
.L08024fba:
	adds r5, r3, r6
	ldrb.w r7, [r5, #0x483]
	cmp r7, #0xe4
	bls.n .L08024fc8
	movs r7, #0xe4
	b.n .L08024fce
.L08024fc8:
	cmp r7, #0x1b
	bhi.n .L08024fd2
	movs r7, #0x1c
.L08024fce:
	strb.w r7, [r5, #0x483]
.L08024fd2:
	ldrb.w r7, [r5, #0x484]
	cmp r7, #0xe4
	bls.n .L08024fe0
	movs r7, #0xe4
	b.n .L08024fe6
	.short 0xbf00                   @ padding
.L08024fe0:
	cmp r7, #0x1b
	bhi.n .L08024fea
	movs r7, #0x1c
.L08024fe6:
	strb.w r7, [r5, #0x484]
.L08024fea:
	ldrb.w r7, [r5, #0x485]
	cmp r7, #0xe4
	bls.n .L08024ff8
	movs r7, #0xe4
	b.n .L08024ffe
	.short 0xbf00                   @ padding
.L08024ff8:
	cmp r7, #0x1b
	bhi.n .L08025002
	movs r7, #0x1c
.L08024ffe:
	strb.w r7, [r5, #0x485]
.L08025002:
	ldrb.w r7, [r5, #0x486]
	cmp r7, #0xe4
	bls.n .L08025010
	movs r7, #0xe4
	b.n .L08025016
	.short 0xbf00                   @ padding
.L08025010:
	cmp r7, #0x1b
	bhi.n .L0802501a
	movs r7, #0x1c
.L08025016:
	strb.w r7, [r5, #0x486]
.L0802501a:
	ldrb.w r7, [r5, #0x487]
	cmp r7, #0xe4
	bls.n .L08025028
	movs r7, #0xe4
	b.n .L0802502e
	.short 0xbf00                   @ padding
.L08025028:
	cmp r7, #0x1b
	bhi.n .L08025032
	movs r7, #0x1c
.L0802502e:
	strb.w r7, [r5, #0x487]
.L08025032:
	ldrb.w r7, [r5, #0x488]
	cmp r7, #0xe4
	bls.n .L08025040
	movs r7, #0xe4
	b.n .L08025046
	.short 0xbf00                   @ padding
.L08025040:
	cmp r7, #0x1b
	bhi.n .L0802504a
	movs r7, #0x1c
.L08025046:
	strb.w r7, [r5, #0x488]
.L0802504a:
	ldrb.w r7, [r5, #0x489]
	cmp r7, #0xe4
	bhi.n .L08024fb0
	cmp r7, #0x1b
	bhi.n .L08024fb6
	movs r7, #0x1c
	b.n .L08024fb2
.L0802505a:
	adds r1, #1
.L0802505c:
	cmn r2, r0
	bne.n .L08025066
.L08025060:
	add sp, #0x1c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08025066:
	movw r2, #0x12d
	smlabb r2, r1, r2, r8
	b.n .L0802507a
.L08025070:
	adds r1, #2
	cmp r1, r0
	addw r2, r2, #0x25a
	beq.n .L08025060
.L0802507a:
	mvn r3, #0x12c
	b.n .L0802508a
.L08025080:
	movs r6, #0xe4
.L08025082:
	strb.w r6, [r7, #0x489]
.L08025086:
	adds r3, #7
	beq.n .L0802512c
.L0802508a:
	adds r7, r2, r3
	ldrb.w r6, [r7, #0x483]
	cmp r6, #0xe4
	bls.n .L08025098
	movs r6, #0xe4
	b.n .L0802509e
.L08025098:
	cmp r6, #0x1b
	bhi.n .L080250a2
	movs r6, #0x1c
.L0802509e:
	strb.w r6, [r7, #0x483]
.L080250a2:
	ldrb.w r6, [r7, #0x484]
	cmp r6, #0xe4
	bls.n .L080250b0
	movs r6, #0xe4
	b.n .L080250b6
	.short 0xbf00                   @ padding
.L080250b0:
	cmp r6, #0x1b
	bhi.n .L080250ba
	movs r6, #0x1c
.L080250b6:
	strb.w r6, [r7, #0x484]
.L080250ba:
	ldrb.w r6, [r7, #0x485]
	cmp r6, #0xe4
	bls.n .L080250c8
	movs r6, #0xe4
	b.n .L080250ce
	.short 0xbf00                   @ padding
.L080250c8:
	cmp r6, #0x1b
	bhi.n .L080250d2
	movs r6, #0x1c
.L080250ce:
	strb.w r6, [r7, #0x485]
.L080250d2:
	ldrb.w r6, [r7, #0x486]
	cmp r6, #0xe4
	bls.n .L080250e0
	movs r6, #0xe4
	b.n .L080250e6
	.short 0xbf00                   @ padding
.L080250e0:
	cmp r6, #0x1b
	bhi.n .L080250ea
	movs r6, #0x1c
.L080250e6:
	strb.w r6, [r7, #0x486]
.L080250ea:
	ldrb.w r6, [r7, #0x487]
	cmp r6, #0xe4
	bls.n .L080250f8
	movs r6, #0xe4
	b.n .L080250fe
	.short 0xbf00                   @ padding
.L080250f8:
	cmp r6, #0x1b
	bhi.n .L08025102
	movs r6, #0x1c
.L080250fe:
	strb.w r6, [r7, #0x487]
.L08025102:
	ldrb.w r6, [r7, #0x488]
	cmp r6, #0xe4
	bls.n .L08025110
	movs r6, #0xe4
	b.n .L08025116
	.short 0xbf00                   @ padding
.L08025110:
	cmp r6, #0x1b
	bhi.n .L0802511a
	movs r6, #0x1c
.L08025116:
	strb.w r6, [r7, #0x488]
.L0802511a:
	ldrb.w r6, [r7, #0x489]
	cmp r6, #0xe4
	bhi.n .L08025080
	cmp r6, #0x1b
	bhi.n .L08025086
	movs r6, #0x1c
	b.n .L08025082
	.short 0xbf00                   @ padding
.L0802512c:
	mvn r3, #0x12c
	b.n .L08025140
	.short 0xbf00                   @ padding
.L08025134:
	movs r6, #0xe4
.L08025136:
	strb.w r6, [r7, #0x5b6]
.L0802513a:
	adds r3, #7
	beq.w .L08025070
.L08025140:
	adds r7, r2, r3
	ldrb.w r6, [r7, #0x5b0]
	cmp r6, #0xe4
	bls.n .L08025150
	movs r6, #0xe4
	b.n .L08025156
	.short 0xbf00                   @ padding
.L08025150:
	cmp r6, #0x1b
	bhi.n .L0802515a
	movs r6, #0x1c
.L08025156:
	strb.w r6, [r7, #0x5b0]
.L0802515a:
	ldrb.w r6, [r7, #0x5b1]
	cmp r6, #0xe4
	bls.n .L08025168
	movs r6, #0xe4
	b.n .L0802516e
	.short 0xbf00                   @ padding
.L08025168:
	cmp r6, #0x1b
	bhi.n .L08025172
	movs r6, #0x1c
.L0802516e:
	strb.w r6, [r7, #0x5b1]
.L08025172:
	ldrb.w r6, [r7, #0x5b2]
	cmp r6, #0xe4
	bls.n .L08025180
	movs r6, #0xe4
	b.n .L08025186
	.short 0xbf00                   @ padding
.L08025180:
	cmp r6, #0x1b
	bhi.n .L0802518a
	movs r6, #0x1c
.L08025186:
	strb.w r6, [r7, #0x5b2]
.L0802518a:
	ldrb.w r6, [r7, #0x5b3]
	cmp r6, #0xe4
	bls.n .L08025198
	movs r6, #0xe4
	b.n .L0802519e
	.short 0xbf00                   @ padding
.L08025198:
	cmp r6, #0x1b
	bhi.n .L080251a2
	movs r6, #0x1c
.L0802519e:
	strb.w r6, [r7, #0x5b3]
.L080251a2:
	ldrb.w r6, [r7, #0x5b4]
	cmp r6, #0xe4
	bls.n .L080251b0
	movs r6, #0xe4
	b.n .L080251b6
	.short 0xbf00                   @ padding
.L080251b0:
	cmp r6, #0x1b
	bhi.n .L080251ba
	movs r6, #0x1c
.L080251b6:
	strb.w r6, [r7, #0x5b4]
.L080251ba:
	ldrb.w r6, [r7, #0x5b5]
	cmp r6, #0xe4
	bls.n .L080251c8
	movs r6, #0xe4
	b.n .L080251ce
	.short 0xbf00                   @ padding
.L080251c8:
	cmp r6, #0x1b
	bhi.n .L080251d2
	movs r6, #0x1c
.L080251ce:
	strb.w r6, [r7, #0x5b5]
.L080251d2:
	ldrb.w r6, [r7, #0x5b6]
	cmp r6, #0xe4
	bhi.n .L08025134
	cmp r6, #0x1b
	bhi.n .L0802513a
	movs r6, #0x1c
	b.n .L08025136
	.short 0x0000                   @ padding
