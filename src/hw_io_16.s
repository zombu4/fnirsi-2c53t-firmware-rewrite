@ hw_io_16.s - hardware I/O helpers: two index-driven output/DAC-style setters, register bit helpers, character output on 0x40013800, nibble-field setter and small flag helpers
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_080088a4 - r0 = index 0..9 (anything above 9 skips the switch).
@ A tbb switch on the index writes bit patterns to the registers 0x40011010,
@ 0x40011014, 0x40011810 and 0x40011814 (values such as 0x1000, 0x10, 0x20,
@ 0x40, chosen per index; the 0x40011810 writes go through a negative offset
@ 0xfffff800 / 0xfffff804 added to the base).
@ Then it picks two halfword tables by [0x20000125] and [0x2000010c], each
@ indexed by r0: 0x200003a8 / 0x2000036c, 0x200003bc / 0x20000380, or
@ 0x20000394 / 0x20000358 (offsets 0x29c/0x260, 0x2c4/0x288, 0x2b0/0x274 from
@ the base 0x200000f8 plus 2*index).
@ It computes ((hi - lo) / 200.0) * ([0x200000fc] + 100) + lo as a float,
@ converts it to unsigned, stores its low 12 bits into [0x40007408] (bits
@ 31..12 of that word are kept) and sets bit 0 of [0x40007404].
@ No return value. Callees: none.
@ ----------------------------------------------------------------------------
	.section .text.fn_080088a4,"ax",%progbits
	.global fn_080088a4
	.thumb_func
	.type fn_080088a4, %function
fn_080088a4:
	cmp r0, #9
	bhi.w .L080089ba
	tbb [pc, r0]
.L080088ae:
	.byte (.L080088b8 - .L080088ae)/2
	.byte (.L080088be - .L080088ae)/2
	.byte (.L080088c4 - .L080088ae)/2
	.byte (.L080088ec - .L080088ae)/2
	.byte (.L080088f2 - .L080088ae)/2
	.byte (.L080088f8 - .L080088ae)/2
	.byte (.L08008920 - .L080088ae)/2
	.byte (.L0800893c - .L080088ae)/2
	.byte (.L08008990 - .L080088ae)/2
	.byte (.L08008968 - .L080088ae)/2
.L080088b8:
	movw r1, #0xf800
	b.n .L080088fc
.L080088be:
	movw r1, #0xf800
	b.n .L08008924
.L080088c4:
	movw r1, #0xf800
	movw r2, #0x1810
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x1000
	str r3, [r2, r1]
	movw r1, #0x1814
	movt r1, #0x4001
	movs r3, #0x10
	str r3, [r1, #0x0]
	movs r3, #0x20
	str r3, [r2, #0x0]
	b.n .L080089b6
.L080088ec:
	movw r1, #0xf800
	b.n .L08008994
.L080088f2:
	movw r1, #0xf800
	b.n .L0800896c
.L080088f8:
	movw r1, #0xf804
.L080088fc:
	movw r2, #0x1810
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x1000
	str r3, [r2, r1]
	movs r1, #0x10
	str r1, [r2, #0x0]
	movw r1, #0x1814
	movt r1, #0x4001
	movs r3, #0x20
	str r3, [r1, #0x0]
	b.n .L08008962
.L08008920:
	movw r1, #0xf804
.L08008924:
	movw r2, #0x1810
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x1000
	str r3, [r2, r1]
	movs r1, #0x10
	str r1, [r2, #0x0]
	b.n .L0800895e
.L0800893c:
	movw r1, #0xf804
	movw r2, #0x1810
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x1000
	str r3, [r2, r1]
	movw r1, #0x1814
	movt r1, #0x4001
	movs r3, #0x10
	str r3, [r1, #0x0]
.L0800895e:
	movs r1, #0x20
	str r1, [r2, #0x0]
.L08008962:
	movs r1, #0x40
	str r1, [r2, #0x0]
	b.n .L080089ba
.L08008968:
	movw r1, #0xf804
.L0800896c:
	movw r2, #0x1810
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x1000
	str r3, [r2, r1]
	movs r1, #0x10
	str r1, [r2, #0x0]
	movs r1, #0x20
	str r1, [r2, #0x0]
	movw r1, #0x1814
	movt r1, #0x4001
	b.n .L080089b6
.L08008990:
	movw r1, #0xf804
.L08008994:
	movw r2, #0x1810
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x1000
	str r3, [r2, r1]
	movs r1, #0x10
	str r1, [r2, #0x0]
	movw r1, #0x1814
	movt r1, #0x4001
	movs r2, #0x20
	str r2, [r1, #0x0]
.L080089b6:
	movs r2, #0x40
	str r2, [r1, #0x0]
.L080089ba:
	movw r1, #0xf8
	movt r1, #0x2000
	ldrb.w r2, [r1, #0x2d]
	cmp r2, #5
	bcc.n .L080089d8
	add.w r2, r1, r0, lsl #1
	add.w r0, r2, #0x29c
	add.w r2, r2, #0x260
	b.n .L080089fc
.L080089d8:
	cmp r2, #4
	beq.n .L080089f0
	ldrb r2, [r1, #0x14]
	cmp r2, #3
	beq.n .L080089f0
	add.w r2, r1, r0, lsl #1
	add.w r0, r2, #0x2c4
	add.w r2, r2, #0x288
	b.n .L080089fc
.L080089f0:
	add.w r2, r1, r0, lsl #1
	add.w r0, r2, #0x2b0
	add.w r2, r2, #0x274
.L080089fc:
	ldrh r0, [r0, #0x0]
	ldrh r2, [r2, #0x0]
	vldr s2, .L08008a54
	subs r0, r0, r2
	vmov s0, r0
	vcvt.f32.s32 s0, s0
	vdiv.f32 s0, s0, s2
	ldrsb.w r0, [r1, #0x4]
	adds r0, #0x64
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	movw r0, #0x7404
	movt r0, #0x4000
	ldr r1, [r0, #0x4]
	lsrs r1, r1, #0xc
	vmul.f32 s0, s0, s2
	vmov s2, r2
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vmov r2, s0
	bfi r2, r1, #0xc, #0x14
	str r2, [r0, #0x4]
	ldr r1, [r0, #0x0]
	orr r1, r1, #0x1
	str r1, [r0, #0x0]
	bx lr
.L08008a54:
	.word 0x43480000	@ float 200.0

@ ----------------------------------------------------------------------------
@ fn_08008a58 - r0 = index 0..9 (anything above 9 skips the switch).
@ A tbb switch on the index writes bit patterns to the registers 0x40010810,
@ 0x40010814, 0x40010c10 and 0x40010c14 (values 0x8000, 0x800, 0x400 chosen
@ per index; the 0x40010c10 writes go through a negative offset 0xfffffc00 /
@ 0xfffffc04 added to the base).
@ Then it picks two halfword tables by [0x20000125] and [0x2000010c], each
@ indexed by r0: 0x20000420 / 0x200003e4, 0x20000434 / 0x200003f8 or
@ 0x2000040c / 0x200003d0 (offsets 0x314/0x2d8, 0x33c/0x300, 0x328/0x2ec from
@ the base 0x200000f8 plus 2*index).
@ It computes ((hi - lo) / 200.0) * ([0x200000fd] + 100) + lo as a float,
@ converts it to unsigned and stores it to [0x40001c34].
@ No return value. Callees: none.
@ ----------------------------------------------------------------------------
	.section .text.fn_08008a58,"ax",%progbits
	.global fn_08008a58
	.thumb_func
	.type fn_08008a58, %function
fn_08008a58:
	cmp r0, #9
	bhi.w .L08008bd4
	tbb [pc, r0]
.L08008a62:
	.byte (.L08008a6c - .L08008a62)/2
	.byte (.L08008a72 - .L08008a62)/2
	.byte (.L08008a78 - .L08008a62)/2
	.byte (.L08008a9e - .L08008a62)/2
	.byte (.L08008ad2 - .L08008a62)/2
	.byte (.L08008afa - .L08008a62)/2
	.byte (.L08008b2e - .L08008a62)/2
	.byte (.L08008b4c - .L08008a62)/2
	.byte (.L08008ba6 - .L08008a62)/2
	.byte (.L08008b82 - .L08008a62)/2
.L08008a6c:
	movw r1, #0xfc00
	b.n .L08008baa
.L08008a72:
	movw r1, #0xfc00
	b.n .L08008b86
.L08008a78:
	movw r1, #0xfc00
	movw r2, #0xc10
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x8000
	str r3, [r2, r1]
	movw r1, #0xc14
	movt r1, #0x4001
	mov.w r3, #0x800
	str r3, [r1, #0x0]
	b.n .L08008aee
.L08008a9e:
	movw r1, #0xfc00
	movw r2, #0xc10
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x8000
	str r3, [r2, r1]
	mov.w r1, #0x800
	str r1, [r2, #0x0]
	movw r1, #0xc14
	movt r1, #0x4001
	mov.w r3, #0x400
	str r3, [r1, #0x0]
	movw r1, #0xfc04
	movt r1, #0xffff
	b.n .L08008bd2
.L08008ad2:
	movw r1, #0xfc00
	movw r2, #0xc10
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x8000
	str r3, [r2, r1]
	mov.w r1, #0x800
	str r1, [r2, #0x0]
.L08008aee:
	mov.w r1, #0x400
	movw r3, #0xfc04
	str r1, [r2, #0x0]
	b.n .L08008b7a
.L08008afa:
	movw r1, #0xfc04
	movw r2, #0xc10
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x8000
	str r3, [r2, r1]
	mov.w r1, #0x800
	str r1, [r2, #0x0]
	movw r1, #0xc14
	movt r1, #0x4001
	mov.w r3, #0x400
	str r3, [r1, #0x0]
	movw r1, #0xfc00
	movt r1, #0xffff
	b.n .L08008bd2
.L08008b2e:
	movw r1, #0xfc04
	movw r2, #0xc10
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x8000
	str r3, [r2, r1]
	mov.w r1, #0x800
	str r1, [r2, #0x0]
	b.n .L08008b70
.L08008b4c:
	movw r1, #0xfc04
	movw r2, #0xc10
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x8000
	str r3, [r2, r1]
	movw r1, #0xc14
	movt r1, #0x4001
	mov.w r3, #0x800
	str r3, [r1, #0x0]
.L08008b70:
	mov.w r1, #0x400
	str r1, [r2, #0x0]
	movw r3, #0xfc00
.L08008b7a:
	movt r3, #0xffff
	str r1, [r2, r3]
	b.n .L08008bd4
.L08008b82:
	movw r1, #0xfc04
.L08008b86:
	movw r2, #0xc10
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x8000
	str r3, [r2, r1]
	mov.w r3, #0x800
	str r3, [r2, #0x0]
	mov.w r3, #0x400
	str r3, [r2, #0x0]
	b.n .L08008bd2
.L08008ba6:
	movw r1, #0xfc04
.L08008baa:
	movw r2, #0xc10
	movt r1, #0xffff
	movt r2, #0x4001
	mov.w r3, #0x8000
	str r3, [r2, r1]
	mov.w r3, #0x800
	movw r12, #0xc14
	str r3, [r2, #0x0]
	movt r12, #0x4001
	mov.w r3, #0x400
	str.w r3, [r12, #0x0]
.L08008bd2:
	str r3, [r2, r1]
.L08008bd4:
	movw r1, #0xf8
	movt r1, #0x2000
	ldrb.w r2, [r1, #0x2d]
	cmp r2, #5
	bcc.n .L08008bf2
	add.w r2, r1, r0, lsl #1
	add.w r0, r2, #0x314
	add.w r2, r2, #0x2d8
	b.n .L08008c16
.L08008bf2:
	cmp r2, #4
	beq.n .L08008c0a
	ldrb r2, [r1, #0x14]
	cmp r2, #3
	beq.n .L08008c0a
	add.w r2, r1, r0, lsl #1
	add.w r0, r2, #0x33c
	add.w r2, r2, #0x300
	b.n .L08008c16
.L08008c0a:
	add.w r2, r1, r0, lsl #1
	add.w r0, r2, #0x328
	add.w r2, r2, #0x2ec
.L08008c16:
	ldrh r0, [r0, #0x0]
	ldrh r2, [r2, #0x0]
	vldr s2, .L08008c5c
	subs r0, r0, r2
	vmov s0, r0
	vcvt.f32.s32 s0, s0
	vdiv.f32 s0, s0, s2
	ldrsb.w r0, [r1, #0x5]
	adds r0, #0x64
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	movw r0, #0x1c34
	movt r0, #0x4000
	vmul.f32 s0, s0, s2
	vmov s2, r2
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vstr s0, [r0]
	bx lr
.L08008c5c:
	.word 0x43480000	@ float 200.0

@ ----------------------------------------------------------------------------
@ set_bit_in_register - param_1 (r0): bits 31..16 = byte offset from
@ 0x40021000, bits 4..0 = bit number. Sets bit (param_1 & 0x1f) in the word at
@ 0x40021000 + (param_1 >> 16) by read-modify-write. No return value.
@ ----------------------------------------------------------------------------
	.section .text.set_bit_in_register,"ax",%progbits
	.global set_bit_in_register
	.thumb_func
	.type set_bit_in_register, %function
set_bit_in_register:
	movw r3, #0x1000
	and r1, r0, #0x1f
	lsrs r0, r0, #0x10
	movt r3, #0x4002
	mov.w r12, #0x1
	ldr r2, [r0, r3]
	lsl.w r1, r12, r1
	orrs r1, r2
	str r1, [r0, r3]
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08036ba4 - Outputs one character on the I/O block 0x40013800: polls the
@ word 0x40013800 while bit 7 is clear (re-read up to four times per pass),
@ leaves the loop when bit 7 is set, then writes r0 & 0x1ff to 0x40013804.
@ No return value. Its Thumb address 0x08036BA5 is built at 0x080080F6 in
@ 080080f0 (ldr r3,[pc,#0x1c] = literal 0x0002EAAB at 0x08008110, add r3,pc:
@ 0x0002EAAB + 0x080080FA) and passed in r3 to 08008092. Reached at boot
@ through 0802e5a0 -> 0800739c -> 080080f0, which prints the text at
@ 0x0802E6D0 ('[DEBUG] file[%s] line[%d]' with 0x0802E700
@ '../../../project/bsp_sys.c', r2 = 239).
@ ----------------------------------------------------------------------------
	.section .text.fn_08036ba4,"ax",%progbits
	.global fn_08036ba4
	.thumb_func
	.type fn_08036ba4, %function
fn_08036ba4:
	movw r1, #0x3800
	movt r1, #0x4001
.L08036bac:
	ldr r2, [r1, #0x0]
	lsls r2, r2, #0x18
	bmi.n .L08036bc6
	ldr r2, [r1, #0x0]
	lsls r2, r2, #0x18
	itt pl
	ldrpl r2, [r1, #0x0]
	lslspl.w r2, r2, #0x18
	bmi.n .L08036bc6
	ldr r2, [r1, #0x0]
	lsls r2, r2, #0x18
	bpl.n .L08036bac
.L08036bc6:
	mov r2, r0
	bfc r2, #0x9, #0x17
	str r2, [r1, #0x4]
	bx lr

@ ----------------------------------------------------------------------------
@ set_nibble_fields_from_bit_mask - Replaces 4-bit fields in words 0 and 1 of
@ the block r0 (words 4 and 5 are also written in two cases) from the record
@ r1 (ushort pin mask at +0, bytes at +4, +5, +6, +7).
@ A nibble value is computed from byte +6: 3 gives 0; 0 uses byte +5 (0x28
@ also stores the mask at r0[5] and gives 8, 0x18 stores the mask at r0[4] and
@ gives 8, otherwise byte+5 & 0xf); any other value gives
@ (byte+7 & 3) + (byte+4 & 4) + (byte+6 & 8).
@ For each set bit n of the low 8 mask bits it writes nibble n of r0[0]; for
@ the high 8 bits it writes nibble n-8 of r0[1] (r0 is advanced by 4).
@ No return value.
@ ----------------------------------------------------------------------------
	.section .text.set_nibble_fields_from_bit_mask,"ax",%progbits
	.global set_nibble_fields_from_bit_mask
	.thumb_func
	.type set_nibble_fields_from_bit_mask, %function
set_nibble_fields_from_bit_mask:
	push {r7, lr}
	ldrb r3, [r1, #0x6]
	ldrh r2, [r1, #0x0]
	cmp r3, #0x3
	beq.n .L08037318
	cbnz r3, .L0803731c
	ldrb r1, [r1, #0x5]
	cmp r1, #0x28
	beq.n .L08037332
	cmp r1, #0x18
	bne.n .L08037338
	str r2, [r0, #0x10]
	movs r1, #0x8
	b.n .L0803733c
.L08037318:
	movs r1, #0x0
	b.n .L0803733c
.L0803731c:
	and r12, r3, #0x8
	ldrb r3, [r1, #0x4]
	ldrb r1, [r1, #0x7]
	and r3, r3, #0x4
	add r3, r12
	and r1, r1, #0x3
	add r1, r3
	b.n .L0803733c
.L08037332:
	str r2, [r0, #0x14]
	movs r1, #0x8
	b.n .L0803733c
.L08037338:
	and r1, r1, #0xf
.L0803733c:
	lsls.w r12, r2, #0x18
	bic lr, r2, #0xff
	beq.n .L08037378
	lsls r3, r2, #0x1f
	bne.n .L080373cc
.L0803734a:
	lsls r3, r2, #0x1e
	bmi.n .L080373de
.L0803734e:
	lsls r3, r2, #0x1d
	bmi.n .L080373f2
.L08037352:
	lsls r3, r2, #0x1c
	bmi.n .L08037406
.L08037356:
	lsls r3, r2, #0x1b
	bmi.n .L0803741a
.L0803735a:
	lsls r3, r2, #0x1a
	bmi.n .L0803742e
.L0803735e:
	lsls r3, r2, #0x19
	bmi.n .L08037442
.L08037362:
	cmp.w r12, #0x0
	bpl.n .L08037378
.L08037368:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf0000000
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x1c
	str r3, [r0, #0x0]
.L08037378:
	cmp.w lr, #0x0
	beq.n .L080373ca
	lsls r3, r2, #0x17
	add.w r0, r0, #0x4
	bmi.n .L0803745c
.L08037386:
	lsls r3, r2, #0x16
	bmi.n .L0803746e
.L0803738a:
	lsls r3, r2, #0x15
	bmi.n .L08037484
.L0803738e:
	lsls r3, r2, #0x14
	bmi.w .L0803749a
.L08037394:
	lsls r3, r2, #0x13
	bmi.w .L080374b0
.L0803739a:
	lsls r3, r2, #0x12
	bmi.w .L080374c6
.L080373a0:
	lsls r3, r2, #0x11
	bpl.n .L080373b4
.L080373a4:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf000000
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x18
	str r3, [r0, #0x0]
.L080373b4:
	lsls r2, r2, #0x10
	it pl
	poppl {r7, pc}
	ldr r2, [r0, #0x0]
	bic r2, r2, #0xf0000000
	str r2, [r0, #0x0]
	ldr r2, [r0, #0x0]
	orr.w r1, r2, r1, lsl #0x1c
	str r1, [r0, #0x0]
.L080373ca:
	pop {r7, pc}
.L080373cc:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orrs r3, r1
	str r3, [r0, #0x0]
	lsls r3, r2, #0x1e
	bpl.n .L0803734e
.L080373de:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf0
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x4
	str r3, [r0, #0x0]
	lsls r3, r2, #0x1d
	bpl.n .L08037352
.L080373f2:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf00
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x8
	str r3, [r0, #0x0]
	lsls r3, r2, #0x1c
	bpl.n .L08037356
.L08037406:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf000
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0xc
	str r3, [r0, #0x0]
	lsls r3, r2, #0x1b
	bpl.n .L0803735a
.L0803741a:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf0000
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x10
	str r3, [r0, #0x0]
	lsls r3, r2, #0x1a
	bpl.n .L0803735e
.L0803742e:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf00000
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x14
	str r3, [r0, #0x0]
	lsls r3, r2, #0x19
	bpl.n .L08037362
.L08037442:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf000000
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x18
	str r3, [r0, #0x0]
	cmp.w r12, #0x0
	bmi.w .L08037368
	b.n .L08037378
.L0803745c:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orrs r3, r1
	str r3, [r0, #0x0]
	lsls r3, r2, #0x16
	bpl.n .L0803738a
.L0803746e:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf0
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x4
	str r3, [r0, #0x0]
	lsls r3, r2, #0x15
	bpl.w .L0803738e
.L08037484:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf00
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x8
	str r3, [r0, #0x0]
	lsls r3, r2, #0x14
	bpl.w .L08037394
.L0803749a:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf000
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0xc
	str r3, [r0, #0x0]
	lsls r3, r2, #0x13
	bpl.w .L0803739a
.L080374b0:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf0000
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x10
	str r3, [r0, #0x0]
	lsls r3, r2, #0x12
	bpl.w .L080373a0
.L080374c6:
	ldr r3, [r0, #0x0]
	bic r3, r3, #0xf00000
	str r3, [r0, #0x0]
	ldr r3, [r0, #0x0]
	orr.w r3, r3, r1, lsl #0x14
	str r3, [r0, #0x0]
	lsls r3, r2, #0x11
	bpl.w .L080373b4
	b.n .L080373a4
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ all_bits_set - Returns true (1) when (word at r0+8 & r1) == r1, else 0
@ (computed as clz((word & r1) - r1) >> 5). Purpose not determined from the
@ code (the word at r0+8 is not identified).
@ ----------------------------------------------------------------------------
	.section .text.all_bits_set,"ax",%progbits
	.global all_bits_set
	.thumb_func
	.type all_bits_set, %function
all_bits_set:
	ldr r0, [r0, #0x8]
	ands r0, r1
	subs r0, r0, r1
	clz r0, r0
	lsrs r0, r0, #0x5
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0803d820 - Param r0 = pointer; no return value. Writes 0 to the word at
@ r0+3, 0 to the word at r0 (so bytes 0..6 are 0) and 1 to the byte at r0+7.
@ Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0803d820,"ax",%progbits
	.global fn_0803d820
	.thumb_func
	.type fn_0803d820, %function
fn_0803d820:
	movs r1, #0x0
	str.w r1, [r0, #0x3]
	str r1, [r0, #0x0]
	movs r1, #0x1
	strb r1, [r0, #0x7]
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ set_bit6 - Param r0 = pointer to a word; no return value. Sets bit 6 (0x40)
@ of *r0 by read-modify-write.
@ ----------------------------------------------------------------------------
	.section .text.set_bit6,"ax",%progbits
	.global set_bit6
	.thumb_func
	.type set_bit6, %function
set_bit6:
	ldr r1, [r0, #0x0]
	orr r1, r1, #0x40
	str r1, [r0, #0x0]
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ word8_any_bit_set - Params r0 = base, r1 = mask; returns bool in r0:
@ ((word at r0+8) & r1) != 0 (1 if any masked bit is set, else 0).
@ ----------------------------------------------------------------------------
	.section .text.word8_any_bit_set,"ax",%progbits
	.global word8_any_bit_set
	.thumb_func
	.type word8_any_bit_set, %function
word8_any_bit_set:
	ldr r0, [r0, #0x8]
	ands r0, r1
	it ne
	movne r0, #0x1
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0803d848 - Params r0 = pointer to a register block (words), r1 = pointer
@ to a settings byte array; no return value.
@ Clears bit 11 of r0[7]; switch on r1[0]: 0 clears bits 15, 14 and 10 of
@ r0[0]; 1 clears bits 15 and 14 and sets bit 10; 2 sets bit 15 and clears
@ bits 14 and 10; 3 sets bits 15 and 14 and clears bit 10; other values change
@ none of these bits.
@ Then sets bit 9 of r0[0] from r1[7]&1; bit 8 of r0[0] set when r1[1]==1 and
@ r1[7]==1, else cleared; bit 2 from r1[1]&1; bit 8 of r0[1] set when
@ r1[2]>7, else cleared; bits 5..3 of r0[0] from r1[2]&7; bit 7 from r1[3]&1;
@ bit 11 from r1[4]&1; bit 1 from r1[5]&1; bit 0 from r1[6]&1.
@ Purpose not determined from the code (the register block base is not named
@ here).
@ ----------------------------------------------------------------------------
	.section .text.fn_0803d848,"ax",%progbits
	.global fn_0803d848
	.thumb_func
	.type fn_0803d848, %function
fn_0803d848:
	ldr r2, [r0, #0x1c]
	bic r2, r2, #0x800
	str r2, [r0, #0x1c]
	ldrb r2, [r1, #0x0]
	cmp r2, #0x3
	bhi.n .L0803d8a6
	tbb [pc, r2]
.L0803d85a:
	.byte (.L0803d85e - .L0803d85a)/2
	.byte (.L0803d866 - .L0803d85a)/2
	.byte (.L0803d87e - .L0803d85a)/2
	.byte (.L0803d88e - .L0803d85a)/2
.L0803d85e:
	ldr r2, [r0, #0x0]
	bic r2, r2, #0x8000
	b.n .L0803d884
.L0803d866:
	ldr r2, [r0, #0x0]
	bic r2, r2, #0x8000
	str r2, [r0, #0x0]
	ldr r2, [r0, #0x0]
	bic r2, r2, #0x4000
	str r2, [r0, #0x0]
	ldr r2, [r0, #0x0]
	orr r2, r2, #0x400
	b.n .L0803d8a4
.L0803d87e:
	ldr r2, [r0, #0x0]
	orr r2, r2, #0x8000
.L0803d884:
	str r2, [r0, #0x0]
	ldr r2, [r0, #0x0]
	bic r2, r2, #0x4000
	b.n .L0803d89c
.L0803d88e:
	ldr r2, [r0, #0x0]
	orr r2, r2, #0x8000
	str r2, [r0, #0x0]
	ldr r2, [r0, #0x0]
	orr r2, r2, #0x4000
.L0803d89c:
	str r2, [r0, #0x0]
	ldr r2, [r0, #0x0]
	bic r2, r2, #0x400
.L0803d8a4:
	str r2, [r0, #0x0]
.L0803d8a6:
	ldrb r2, [r1, #0x7]
	ldr r3, [r0, #0x0]
	and r2, r2, #0x1
	bic r3, r3, #0x200
	orr.w r2, r3, r2, lsl #0x9
	str r2, [r0, #0x0]
	ldrb r2, [r1, #0x1]
	cmp r2, #0x1
	bne.n .L0803d8cc
	ldrb r2, [r1, #0x7]
	cmp r2, #0x1
	bne.n .L0803d8cc
	ldr r2, [r0, #0x0]
	orr r2, r2, #0x100
	b.n .L0803d8d2
.L0803d8cc:
	ldr r2, [r0, #0x0]
	bic r2, r2, #0x100
.L0803d8d2:
	str r2, [r0, #0x0]
	ldrb r2, [r1, #0x1]
	ldr r3, [r0, #0x0]
	bfi r3, r2, #0x2, #0x1
	str r3, [r0, #0x0]
	ldrb r2, [r1, #0x2]
	ldr r3, [r0, #0x4]
	cmp r2, #0x7
	bic r3, r3, #0x100
	it hi
	addhi.w r3, r3, #0x100
	str r3, [r0, #0x4]
	ldrb r2, [r1, #0x2]
	ldr r3, [r0, #0x0]
	bfi r3, r2, #0x3, #0x3
	str r3, [r0, #0x0]
	ldrb r2, [r1, #0x3]
	ldr r3, [r0, #0x0]
	and r2, r2, #0x1
	bic r3, r3, #0x80
	orr.w r2, r3, r2, lsl #0x7
	str r2, [r0, #0x0]
	ldrb r2, [r1, #0x4]
	ldr r3, [r0, #0x0]
	and r2, r2, #0x1
	bic r3, r3, #0x800
	orr.w r2, r3, r2, lsl #0xb
	str r2, [r0, #0x0]
	ldrb r2, [r1, #0x5]
	ldr r3, [r0, #0x0]
	bfi r3, r2, #0x1, #0x1
	str r3, [r0, #0x0]
	ldrb r1, [r1, #0x6]
	ldr r2, [r0, #0x0]
	bfi r2, r1, #0x0, #0x1
	str r2, [r0, #0x0]
	bx lr
