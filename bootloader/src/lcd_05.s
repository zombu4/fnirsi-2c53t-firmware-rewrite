@ lcd_05.s - LCD:window fill, orientation / window setup, pixel write, panel init sequence, window-to-dimensions write, the 0x60020000 / 0x6001FFFE halfword writers and the glyph drawer.
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fill_window_with_halfword - fills the current window with one halfword value.
@ r0 = value (kept in r6). r5 = u16[0x20000444] * u16[0x20000446] (pixel count).
@ Calls write_window_xy_to_dims(0, 0) (0x080008A0), then
@ write_ram_44c_to_6001fffe (0x0800091C, writes u16[0x2000044C] to 0x6001FFFE),
@ then calls write_halfword_60020000_b(value) (0x08000910, halfword to
@ 0x60020000) r5 times. Called from 0x08000894 with 0xFFFF. No return value.
@ The 0x2000044C command is 0x2C after set_orientation_and_window (0x080005DC) ran.
@ ----------------------------------------------------------------------------
	.section .text.fill_window_with_halfword,"ax",%progbits
	.p2align 2
	.global fill_window_with_halfword
	.thumb_func
	.type fill_window_with_halfword, %function
fill_window_with_halfword:
	push	{r4, r5, r6, lr}
	mov	r6, r0
	movs	r4, #0
	ldr	r0, .L080005d8
	ldrh	r5, [r0]
	ldrh	r0, [r0, #2]
	muls	r5, r0, r5
	movs	r1, #0
	mov	r0, r1
	bl	write_window_xy_to_dims
	bl	write_ram_44c_to_6001fffe
	nop
	b.n	.L080005d2
.L080005ca:
	mov	r0, r6
	bl	write_halfword_60020000_b
	.inst.n 0x1c64	@ adds r4, r4, #1
.L080005d2:
	cmp	r4, r5
	bcc.n	.L080005ca
	pop	{r4, r5, r6, pc}
.L080005d8:
	.word	0x20000444

@ ----------------------------------------------------------------------------
@ set_orientation_and_window - sets the display orientation and the window size.
@ r0 = mode.
@ Modes 0 and 1: byte 0x2000044A = 0, u16 0x20000444 = 0xF0, u16 0x20000446 = 0x140.
@ Modes 2 and 3: byte 0x2000044A = 1, u16 0x20000444 = 0x140, u16 0x20000446 = 0xF0.
@ Any other value changes none of them.
@ In both groups u16 0x2000044C = 0x2C, 0x2000044E = 0x2A, 0x20000450 = 0x2B.
@ Then write_halfword_6001fffe(0x36) (0x08000904) followed by
@ write_halfword_60020000 (0x080008F8) of 0x48 (mode 0), 0x88 (mode 1),
@ 0xE8 (mode 2), 0xA0 (mode 3); nothing for other values.
@ Then write_halfword_6001fffe(u16[0x2000044E]) with data 0, 0,
@ ((u16[0x20000444]-1)>>8), (byte[0x20000444]-1) via 0x080008F8, and
@ write_halfword_6001fffe(u16[0x20000450]) with data 0, 0,
@ ((u16[0x20000446]-1)>>8), (byte[0x20000446]-1).
@ Called from 0x0800088C with 3 (movs r0,#3 at 0x0800088A). No return value.
@ ----------------------------------------------------------------------------
	.section .text.set_orientation_and_window,"ax",%progbits
	.p2align 2
	.global set_orientation_and_window
	.thumb_func
	.type set_orientation_and_window, %function
set_orientation_and_window:
	push	{lr}
	mov	r2, r0
	cbz	r2, .L080005e6
	cmp	r2, #1
	bne.n	.L08000620
.L080005e6:
	movs	r0, #0
	ldr	r1, .L080006c0
	strb	r0, [r1, #6]
	movs	r0, #0xf0
	strh	r0, [r1]
	mov.w	r0, #0x140
	strh	r0, [r1, #2]
	movs	r0, #0x2c
	strh	r0, [r1, #8]
	movs	r0, #0x2a
	strh	r0, [r1, #0xa]
	movs	r0, #0x2b
	strh	r0, [r1, #0xc]
	cbnz	r2, .L08000612
	movs	r0, #0x36
	bl	write_halfword_6001fffe
	movs	r0, #0x48
	bl	write_halfword_60020000
	b.n	.L08000662
.L08000612:
	movs	r0, #0x36
	bl	write_halfword_6001fffe
	movs	r0, #0x88
	bl	write_halfword_60020000
	b.n	.L08000662
.L08000620:
	cmp	r2, #2
	beq.n	.L08000628
	cmp	r2, #3
	bne.n	.L08000662
.L08000628:
	movs	r0, #1
	ldr	r1, .L080006c0
	strb	r0, [r1, #6]
	mov.w	r0, #0x140
	strh	r0, [r1]
	movs	r0, #0xf0
	strh	r0, [r1, #2]
	movs	r0, #0x2c
	strh	r0, [r1, #8]
	movs	r0, #0x2a
	strh	r0, [r1, #0xa]
	movs	r0, #0x2b
	strh	r0, [r1, #0xc]
	cmp	r2, #2
	bne.n	.L08000656
	movs	r0, #0x36
	bl	write_halfword_6001fffe
	movs	r0, #0xe8
	bl	write_halfword_60020000
	b.n	.L08000662
.L08000656:
	movs	r0, #0x36
	bl	write_halfword_6001fffe
	movs	r0, #0xa0
	bl	write_halfword_60020000
.L08000662:
	ldr	r1, .L080006c0
	ldrh	r0, [r1, #0xa]
	bl	write_halfword_6001fffe
	movs	r0, #0
	bl	write_halfword_60020000
	movs	r0, #0
	bl	write_halfword_60020000
	ldr	r1, .L080006c0
	ldrh	r1, [r1]
	.inst.n 0x1e49	@ subs r1, r1, #1
	ubfx	r0, r1, #8, #16
	bl	write_halfword_60020000
	ldr	r1, .L080006c0
	ldrb	r1, [r1]
	.inst.n 0x1e49	@ subs r1, r1, #1
	uxtb	r0, r1
	bl	write_halfword_60020000
	ldr	r1, .L080006c0
	ldrh	r0, [r1, #0xc]
	bl	write_halfword_6001fffe
	movs	r0, #0
	bl	write_halfword_60020000
	movs	r0, #0
	bl	write_halfword_60020000
	ldr	r1, .L080006c0
	ldrh	r1, [r1, #2]
	.inst.n 0x1e49	@ subs r1, r1, #1
	ubfx	r0, r1, #8, #16
	bl	write_halfword_60020000
	ldr	r1, .L080006c0
	ldrb	r1, [r1, #2]
	.inst.n 0x1e49	@ subs r1, r1, #1
	uxtb	r0, r1
	bl	write_halfword_60020000
	pop	{pc}
.L080006c0:
	.word	0x20000444

@ ----------------------------------------------------------------------------
@ write_halfword_at_xy - writes one data halfword at the window position (x, y).
@ r0 = x, r1 = y, r2 = value (copied to r4, r5, r6).
@ Calls write_window_xy_to_dims(u16 x, u16 y) (0x080008A0), then
@ write_ram_44c_to_6001fffe (0x0800091C), then
@ write_halfword_60020000_b(value) (0x08000910): sets the window start to (x,y),
@ selects the u16[0x2000044C] command and writes one data halfword.
@ Called from 0x08002858 and 0x0800286C. No return value.
@ ----------------------------------------------------------------------------
	.section .text.write_halfword_at_xy,"ax",%progbits
	.p2align 2
	.global write_halfword_at_xy
	.thumb_func
	.type write_halfword_at_xy, %function
write_halfword_at_xy:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	mov	r6, r2
	uxth	r1, r5
	uxth	r0, r4
	bl	write_window_xy_to_dims
	bl	write_ram_44c_to_6001fffe
	mov	r0, r6
	bl	write_halfword_60020000_b
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ send_init_sequence_6001fffe - sends the panel initialisation sequence.
@ No parameters. Calls fn_080046b0 first.
@ [0x40011400+0x10] = 0x40 (write_reg_0x10, 0x08002664), delay
@ systick_delay(10) (0x080018C4), [0x40011400+0x14] = 0x40 (write_reg_0x14,
@ 0x08002660), delay 20, [0x40011400+0x10] = 0x40, delay 20.
@ Then command bytes through write_halfword_6001fffe (0x08000904, halfword to
@ 0x6001FFFE) and data bytes through write_halfword_60020000 (0x080008F8,
@ halfword to 0x60020000): 0x11, delay 0x78, 0x36:00, 0x3A:55,
@ 0xB2:0C 0C 00 33 33, 0xB7:46, 0xBB:1B, 0xC0:2C, 0xC2:01, 0xC3:0F, 0xC4:20,
@ 0xC6:0F, 0xD0:A4 A1, 0xD6:A1,
@ 0xE0:F0 00 06 04 05 05 31 44 48 36 12 12 2B 34,
@ 0xE1:F0 0B 0F 0F 0D 26 31 43 47 38 14 14 2C 32, 0x21, 0x29.
@ Then set_orientation_and_window(3) (0x080005DC) and
@ fill_window_with_halfword(0xFFFF) (0x080005AC).
@ Called once from main at 0x08002990. The meaning of the command bytes and of
@ the pin is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.send_init_sequence_6001fffe,"ax",%progbits
	.p2align 2
	.global send_init_sequence_6001fffe
	.thumb_func
	.type send_init_sequence_6001fffe, %function
send_init_sequence_6001fffe:
	push	{r4, lr}
	bl	fn_080046b0
	movs	r1, #0x40
	ldr	r0, .L0800089c
	bl	write_reg_0x10
	movs	r0, #0xa
	bl	systick_delay
	movs	r1, #0x40
	ldr	r0, .L0800089c
	bl	write_reg_0x14
	movs	r0, #0x14
	bl	systick_delay
	movs	r1, #0x40
	ldr	r0, .L0800089c
	bl	write_reg_0x10
	movs	r0, #0x14
	bl	systick_delay
	movs	r0, #0x11
	bl	write_halfword_6001fffe
	movs	r0, #0x78
	bl	systick_delay
	movs	r0, #0x36
	bl	write_halfword_6001fffe
	movs	r0, #0
	bl	write_halfword_60020000
	movs	r0, #0x3a
	bl	write_halfword_6001fffe
	movs	r0, #0x55
	bl	write_halfword_60020000
	movs	r0, #0xb2
	bl	write_halfword_6001fffe
	movs	r0, #0xc
	bl	write_halfword_60020000
	movs	r0, #0xc
	bl	write_halfword_60020000
	movs	r0, #0
	bl	write_halfword_60020000
	movs	r0, #0x33
	bl	write_halfword_60020000
	movs	r0, #0x33
	bl	write_halfword_60020000
	movs	r0, #0xb7
	bl	write_halfword_6001fffe
	movs	r0, #0x46
	bl	write_halfword_60020000
	movs	r0, #0xbb
	bl	write_halfword_6001fffe
	movs	r0, #0x1b
	bl	write_halfword_60020000
	movs	r0, #0xc0
	bl	write_halfword_6001fffe
	movs	r0, #0x2c
	bl	write_halfword_60020000
	movs	r0, #0xc2
	bl	write_halfword_6001fffe
	movs	r0, #1
	bl	write_halfword_60020000
	movs	r0, #0xc3
	bl	write_halfword_6001fffe
	movs	r0, #0xf
	bl	write_halfword_60020000
	movs	r0, #0xc4
	bl	write_halfword_6001fffe
	movs	r0, #0x20
	bl	write_halfword_60020000
	movs	r0, #0xc6
	bl	write_halfword_6001fffe
	movs	r0, #0xf
	bl	write_halfword_60020000
	movs	r0, #0xd0
	bl	write_halfword_6001fffe
	movs	r0, #0xa4
	bl	write_halfword_60020000
	movs	r0, #0xa1
	bl	write_halfword_60020000
	movs	r0, #0xd6
	bl	write_halfword_6001fffe
	movs	r0, #0xa1
	bl	write_halfword_60020000
	movs	r0, #0xe0
	bl	write_halfword_6001fffe
	movs	r0, #0xf0
	bl	write_halfword_60020000
	movs	r0, #0
	bl	write_halfword_60020000
	movs	r0, #6
	bl	write_halfword_60020000
	movs	r0, #4
	bl	write_halfword_60020000
	movs	r0, #5
	bl	write_halfword_60020000
	movs	r0, #5
	bl	write_halfword_60020000
	movs	r0, #0x31
	bl	write_halfword_60020000
	movs	r0, #0x44
	bl	write_halfword_60020000
	movs	r0, #0x48
	bl	write_halfword_60020000
	movs	r0, #0x36
	bl	write_halfword_60020000
	movs	r0, #0x12
	bl	write_halfword_60020000
	movs	r0, #0x12
	bl	write_halfword_60020000
	movs	r0, #0x2b
	bl	write_halfword_60020000
	movs	r0, #0x34
	bl	write_halfword_60020000
	movs	r0, #0xe1
	bl	write_halfword_6001fffe
	movs	r0, #0xf0
	bl	write_halfword_60020000
	movs	r0, #0xb
	bl	write_halfword_60020000
	movs	r0, #0xf
	bl	write_halfword_60020000
	movs	r0, #0xf
	bl	write_halfword_60020000
	movs	r0, #0xd
	bl	write_halfword_60020000
	movs	r0, #0x26
	bl	write_halfword_60020000
	movs	r0, #0x31
	bl	write_halfword_60020000
	movs	r0, #0x43
	bl	write_halfword_60020000
	movs	r0, #0x47
	bl	write_halfword_60020000
	movs	r0, #0x38
	bl	write_halfword_60020000
	movs	r0, #0x14
	bl	write_halfword_60020000
	movs	r0, #0x14
	bl	write_halfword_60020000
	movs	r0, #0x2c
	bl	write_halfword_60020000
	movs	r0, #0x32
	bl	write_halfword_60020000
	movs	r0, #0x21
	bl	write_halfword_6001fffe
	movs	r0, #0x29
	bl	write_halfword_6001fffe
	movs	r0, #3
	bl	set_orientation_and_window
	movw	r0, #0xffff
	bl	fill_window_with_halfword
	pop	{r4, pc}
	.short	0x0000	@ padding
.L0800089c:
	.word	0x40011400

@ ----------------------------------------------------------------------------
@ write_window_xy_to_dims - writes the window start and end coordinates.
@ r0 = x, r1 = y (copied to r2, r3).
@ write_halfword_6001fffe(u16[0x2000044E]) (0x08000904), then
@ write_halfword_60020000 (0x080008F8) of x>>8, x&0xFF, u16[0x20000444]>>8,
@ byte[0x20000444]; write_halfword_6001fffe(u16[0x20000450]) then
@ 0x080008F8 of y>>8, y&0xFF, u16[0x20000446]>>8, byte[0x20000446].
@ The end values are the width and height words themselves, not minus 1.
@ Called from 0x080005BE, 0x080006D0. No return value.
@ ----------------------------------------------------------------------------
	.section .text.write_window_xy_to_dims,"ax",%progbits
	.p2align 2
	.global write_window_xy_to_dims
	.thumb_func
	.type write_window_xy_to_dims, %function
write_window_xy_to_dims:
	push	{lr}
	mov	r2, r0
	mov	r3, r1
	ldr	r1, .L080008f4
	ldrh	r0, [r1, #0xa]
	bl	write_halfword_6001fffe
	asrs	r0, r2, #8
	bl	write_halfword_60020000
	uxtb	r0, r2
	bl	write_halfword_60020000
	ldr	r1, .L080008f4
	ldrh	r1, [r1]
	asrs	r0, r1, #8
	bl	write_halfword_60020000
	ldr	r1, .L080008f4
	ldrb	r0, [r1]
	bl	write_halfword_60020000
	ldr	r1, .L080008f4
	ldrh	r0, [r1, #0xc]
	bl	write_halfword_6001fffe
	asrs	r0, r3, #8
	bl	write_halfword_60020000
	uxtb	r0, r3
	bl	write_halfword_60020000
	ldr	r1, .L080008f4
	ldrh	r1, [r1, #2]
	asrs	r0, r1, #8
	bl	write_halfword_60020000
	ldr	r1, .L080008f4
	ldrb	r0, [r1, #2]
	bl	write_halfword_60020000
	pop	{pc}
.L080008f4:
	.word	0x20000444

@ ----------------------------------------------------------------------------
@ write_halfword_60020000 - r0 = value: strh r0,[0x60020000] (literal at
@ 0x08000900); bx lr.
@ Callers 0x08000910, 0x080005DC, 0x080006E0, 0x080008A0.
@ ----------------------------------------------------------------------------
	.section .text.write_halfword_60020000,"ax",%progbits
	.p2align 2
	.global write_halfword_60020000
	.thumb_func
	.type write_halfword_60020000, %function
write_halfword_60020000:
	ldr	r1, .L08000900
	strh	r0, [r1]
	bx	lr
	.short	0x0000	@ padding
.L08000900:
	.word	0x60020000

@ ----------------------------------------------------------------------------
@ write_halfword_6001fffe - r0 = value: strh r0,[0x6001FFFE] (literal 0x0800090C);
@ bx lr.
@ Callers 0x080005DC, 0x080006E0, 0x080008A0, 0x0800091C.
@ ----------------------------------------------------------------------------
	.section .text.write_halfword_6001fffe,"ax",%progbits
	.p2align 2
	.global write_halfword_6001fffe
	.thumb_func
	.type write_halfword_6001fffe, %function
write_halfword_6001fffe:
	ldr	r1, .L0800090c
	strh	r0, [r1]
	bx	lr
	.short	0x0000	@ padding
.L0800090c:
	.word	0x6001fffe

@ ----------------------------------------------------------------------------
@ write_halfword_60020000_b - r0 = value, passed on to write_halfword_60020000
@ (0x080008F8, strh to 0x60020000).
@ Callers 0x080005AC, 0x080006C4.
@ ----------------------------------------------------------------------------
	.section .text.write_halfword_60020000_b,"ax",%progbits
	.p2align 2
	.global write_halfword_60020000_b
	.thumb_func
	.type write_halfword_60020000_b, %function
write_halfword_60020000_b:
	push	{lr}
	mov	r2, r0
	mov	r0, r2
	bl	write_halfword_60020000
	pop	{pc}

@ ----------------------------------------------------------------------------
@ write_ram_44c_to_6001fffe - loads u16[0x2000044C] (ldrh [0x20000444+8]) and
@ passes it to write_halfword_6001fffe (0x08000904, strh to 0x6001FFFE).
@ Callers 0x080005AC, 0x080006C4. No parameters, no return value.
@ ----------------------------------------------------------------------------
	.section .text.write_ram_44c_to_6001fffe,"ax",%progbits
	.p2align 2
	.global write_ram_44c_to_6001fffe
	.thumb_func
	.type write_ram_44c_to_6001fffe, %function
write_ram_44c_to_6001fffe:
	push	{lr}
	ldr	r1, .L08000928
	ldrh	r0, [r1, #8]
	bl	write_halfword_6001fffe
	pop	{pc}
.L08000928:
	.word	0x20000444

@ ----------------------------------------------------------------------------
@ draw_glyph - draws one character of the packed bitmap font table at 0x080049d7.
@ r0 = first coordinate (halfword), r1 = second coordinate, r2 = character code,
@ r3 = glyph size s, stack0 = flag (0 draws unset bits), stack1 = colour.
@ Bytes per glyph n = (s/8 rounded up) * (s/2), low byte; table row =
@ 0x080049d7 + ((code - 0x20) & 0xff) * 0x24, used only when s == 0x18 (other
@ sizes keep pointer 0).
@ For each byte (MSB first) and each of its bits: a set bit calls
@ write_halfword_at_xy (0x080006c4) with (first, second, colour); a clear bit
@ calls it with the halfword at 0x200000b8 when the flag is 0; then the second
@ coordinate +1; returns when the halfword at 0x20000446 <= second; when
@ second - start == s, resets second to start, first += 1, returns when the
@ halfword at 0x20000444 <= first, and moves on to the next byte.
@ write_halfword_at_xy calls write_window_xy_to_dims(x, y) (0x080008a0),
@ write_ram_44c_to_6001fffe (0x0800091c) and
@ write_halfword_60020000_b(colour) (0x08000910).
@ Caller: 0x08002912.
@ ----------------------------------------------------------------------------
	.section .text.draw_glyph,"ax",%progbits
	.p2align 2
	.global draw_glyph
	.thumb_func
	.type draw_glyph, %function
draw_glyph:
	push.w	{r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, lr}
	mov	r6, r0
	mov	r5, r1
	mov	r8, r2
	mov	r4, r3
	mov	r11, r5
	movs	r0, #0
	str	r0, [sp, #4]
	str	r0, [sp]
	mov	r0, r4
	asrs	r3, r4, #0x1f
	add.w	r3, r4, r3, lsr #29
	asrs	r3, r3, #3
	mov	r1, r4
	asr.w	r12, r4, #31
	add.w	r12, r4, r12, lsr #29
	asr.w	r12, r12, #3
	sub.w	r12, r4, r12, lsl #3
	cmp.w	r12, #0
	beq.n	.L08002808
	mov.w	r12, #1
	b.n	.L0800280c
.L08002808:
	mov.w	r12, #0
.L0800280c:
	add	r3, r12
	mov	r2, r4
	add.w	r12, r4, r2, lsr #31
	asr.w	r12, r12, #1
	mul	r3, r3, r12
	uxtb	r3, r3
	str	r3, [sp, #4]
	sub.w	r0, r8, #0x20
	and.w	r8, r0, #0xff
	cmp	r4, #0x18
	bne.n	.L0800283a
	add.w	r0, r8, r8, lsl #3
	ldr	r1, .L080028c0
	add.w	r0, r1, r0, lsl #2
	str	r0, [sp]
	nop
.L0800283a:
	nop
	movs	r7, #0
	b.n	.L080028b6
.L08002840:
	ldr	r0, [sp]
	ldrb.w	r9, [r0, r7]
	mov.w	r10, #0
	b.n	.L080028aa
.L0800284c:
	and.w	r0, r9, #0x80
	cbz	r0, .L0800285e
	sxth	r1, r5
	sxth	r0, r6
	ldr	r2, [sp, #0x30]
	bl	write_halfword_at_xy
	b.n	.L08002870
.L0800285e:
	ldr	r0, [sp, #0x2c]
	cbnz	r0, .L08002870
	ldr	r0, .L080028c4
	ldrh	r0, [r0]
	uxth	r2, r0
	sxth	r1, r5
	sxth	r0, r6
	bl	write_halfword_at_xy
.L08002870:
	lsl.w	r0, r9, #25
	lsr.w	r9, r0, #24
	adds	r0, r5, #1
	uxth	r5, r0
	ldr	r0, .L080028c8
	ldrh	r0, [r0, #2]
	cmp	r0, r5
	bgt.n	.L08002888
.L08002884:
	pop.w	{r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08002888:
	sub.w	r0, r5, r11
	cmp	r0, r4
	bne.n	.L080028a2
	mov	r5, r11
	adds	r0, r6, #1
	uxth	r6, r0
	ldr	r0, .L080028c8
	ldrh	r0, [r0]
	cmp	r0, r6
	bgt.n	.L080028a0
	b.n	.L08002884
.L080028a0:
	b.n	.L080028b0
.L080028a2:
	add.w	r0, r10, #1
	and.w	r10, r0, #0xff
.L080028aa:
	cmp.w	r10, #8
	blt.n	.L0800284c
.L080028b0:
	nop
	adds	r0, r7, #1
	uxtb	r7, r0
.L080028b6:
	ldr	r0, [sp, #4]
	cmp	r7, r0
	blt.n	.L08002840
	nop
	b.n	.L08002884
.L080028c0:
	.word	d_080049d6+1
.L080028c4:
	.word	0x200000b8
.L080028c8:
	.word	0x20000444

@ ----------------------------------------------------------------------------
@ draw_string - draws a text.
@ r0 = first coordinate, r1 = second coordinate, r2 = width, r3 = height,
@ stack0 = line step and glyph size, stack1 = pointer to the string,
@ stack2 = colour.
@ Right limit = r0 + r2, bottom limit = r1 + r3 (16-bit); start column kept as
@ r0 & 0xff.
@ Loop: stops at a character below 0x20 or above 0x7e; when first >= right
@ limit, first = start column and second += line step; returns when second >=
@ bottom limit; calls draw_glyph (0x080027cc) with (first, second, char, line
@ step, 0, colour); first += line step / 2 (signed halving); next character.
@ Caller: 0x080029a8 (0x40, 0x6c, 0xc0, 0x18, 0x18, "Firmware upgrade", 0).
@ ----------------------------------------------------------------------------
	.section .text.draw_string,"ax",%progbits
	.p2align 2
	.global draw_string
	.thumb_func
	.type draw_string, %function
draw_string:
	push.w	{r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, lr}
	mov	r4, r0
	mov	r5, r1
	mov	r8, r2
	mov	r9, r3
	ldrd	r7, r10, [sp, #0x30]
	ldr	r6, [sp, #0x2c]
	and.w	r11, r4, #0xff
	add.w	r0, r8, r4
	uxth.w	r8, r0
	add.w	r0, r9, r5
	uxth.w	r9, r0
	b.n	.L08002924
.L080028f4:
	cmp	r4, r8
	blt.n	.L080028fe
	mov	r4, r11
	adds	r0, r5, r6
	uxth	r5, r0
.L080028fe:
	cmp	r5, r9
	blt.n	.L08002904
	b.n	.L08002930
.L08002904:
	movs	r0, #0
	strd	r0, r10, [sp]
	ldrb	r2, [r7]
	mov	r3, r6
	mov	r1, r5
	mov	r0, r4
	bl	draw_glyph
	mov	r0, r6
	add.w	r1, r6, r0, lsr #31
	add.w	r1, r4, r1, asr #1
	uxth	r4, r1
	.inst.n 0x1c7f	@ adds r7, r7, #1
.L08002924:
	ldrb	r0, [r7]
	cmp	r0, #0x7e
	bgt.n	.L08002930
	ldrb	r0, [r7]
	cmp	r0, #0x20
	bge.n	.L080028f4
.L08002930:
	nop
	pop.w	{r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080046b0 - port and peripheral setup sequence. No parameters, no return value.
@ Calls set_or_clear_bit_40021000_offset (0x080016dc) with (0x180005, 1),
@ (0x180006, 1), (0x180000, 1), (0x140008, 1); fn_08002738 (0x08002738) with
@ (0x301b0101, 1).
@ Then config_record_apply_nibbles (0x0800267e) with records on the port blocks:
@ 0x40011400 mask 0xc703 [4..7] = 00 04 08 01; 0x40011800 mask 0xff80 same
@ bytes; 0x40011400 mask 0x40 [4..7] = 00 04 10 01; 0x40011400 mask 0x8b0
@ [4..7] = 00 04 08 01.
@ Then builds a record at sp+0x44 (init_record_08004862 (0x08004938) init, then
@ bytes [0..3] = 0 0 0 0x10, halfwords 0 except [0xe] = 0x1000, [0x12] = 0x4000)
@ and calls fn_08004862 (0x08004862) on it: word 0xa0000000 = 0x5010.
@ Builds two 32-byte records with init_records_080048bc (0x08004962), sets in
@ both byte [0] = 0, halfword [2] = 0x4000, words [4] = 2, [8] = 0, [0xc] = 2,
@ others 0, calls fn_080048bc (0x080048bc): words 0xa0000004 = 0x202 and
@ 0xa0000104 = 0x202.
@ Then set_byte0_clear_byte1_a0000220(0, 8, 8) (0x08004688) (word 0xa0000220 low
@ byte = 8, bits 15..8 = 0) and set_bit0_a0000000(0, 1) (0x0800484c) (sets bit 0
@ of word 0xa0000000).
@ Purpose not determined from the code (what the blocks at 0x40011400,
@ 0x40011800 and 0xa0000000 are is not shown by this function).
@ ----------------------------------------------------------------------------
	.section .text.fn_080046b0,"ax",%progbits
	.p2align 2
	.global fn_080046b0
	.thumb_func
	.type fn_080046b0, %function
fn_080046b0:
	push	{lr}
	sub	sp, #0x64
	movs	r0, #0
	str	r0, [sp, #0x5c]
	str	r0, [sp, #0x60]
	movs	r1, #1
	ldr	r0, .L08004838
	bl	set_or_clear_bit_40021000_offset
	movs	r1, #1
	ldr	r0, .L08004838
	.inst.n 0x1c40	@ adds r0, r0, #1
	bl	set_or_clear_bit_40021000_offset
	movs	r1, #1
	mov.w	r0, #0x180000
	bl	set_or_clear_bit_40021000_offset
	movs	r1, #1
	ldr	r0, .L0800483c
	bl	set_or_clear_bit_40021000_offset
	movs	r1, #1
	ldr	r0, .L08004840
	bl	fn_08002738
	movw	r0, #0xc703
	str	r0, [sp, #0x5c]
	movs	r0, #8
	strb.w	r0, [sp, #0x62]
	movs	r0, #0
	strb.w	r0, [sp, #0x60]
	movs	r0, #4
	strb.w	r0, [sp, #0x61]
	movs	r0, #1
	strb.w	r0, [sp, #0x63]
	add	r1, sp, #0x5c
	ldr	r0, .L08004844
	bl	config_record_apply_nibbles
	movw	r0, #0xff80
	str	r0, [sp, #0x5c]
	movs	r0, #8
	strb.w	r0, [sp, #0x62]
	movs	r0, #0
	strb.w	r0, [sp, #0x60]
	movs	r0, #4
	strb.w	r0, [sp, #0x61]
	movs	r0, #1
	strb.w	r0, [sp, #0x63]
	add	r1, sp, #0x5c
	ldr	r0, .L08004848
	bl	config_record_apply_nibbles
	movs	r0, #0x40
	str	r0, [sp, #0x5c]
	movs	r0, #0x10
	strb.w	r0, [sp, #0x62]
	movs	r0, #0
	strb.w	r0, [sp, #0x60]
	movs	r0, #4
	strb.w	r0, [sp, #0x61]
	movs	r0, #1
	strb.w	r0, [sp, #0x63]
	add	r1, sp, #0x5c
	ldr	r0, .L08004844
	bl	config_record_apply_nibbles
	mov.w	r0, #0x8b0
	str	r0, [sp, #0x5c]
	movs	r0, #8
	strb.w	r0, [sp, #0x62]
	movs	r0, #0
	strb.w	r0, [sp, #0x60]
	movs	r0, #4
	strb.w	r0, [sp, #0x61]
	movs	r0, #1
	strb.w	r0, [sp, #0x63]
	add	r1, sp, #0x5c
	ldr	r0, .L08004844
	bl	config_record_apply_nibbles
	add	r0, sp, #0x44
	bl	init_record_08004862
	movs	r0, #0
	strb.w	r0, [sp, #0x44]
	strb.w	r0, [sp, #0x45]
	strb.w	r0, [sp, #0x46]
	movs	r0, #0x10
	strb.w	r0, [sp, #0x47]
	movs	r0, #0
	strh.w	r0, [sp, #0x48]
	strh.w	r0, [sp, #0x4a]
	strh.w	r0, [sp, #0x4c]
	strh.w	r0, [sp, #0x4e]
	strh.w	r0, [sp, #0x50]
	mov.w	r0, #0x1000
	strh.w	r0, [sp, #0x52]
	movs	r0, #0
	strh.w	r0, [sp, #0x54]
	mov.w	r0, #0x4000
	strh.w	r0, [sp, #0x56]
	movs	r0, #0
	str	r0, [sp, #0x58]
	add	r0, sp, #0x44
	bl	fn_08004862
	add	r1, sp, #4
	add	r0, sp, #0x24
	bl	init_records_080048bc
	movs	r0, #0
	strb.w	r0, [sp, #0x24]
	mov.w	r0, #0x4000
	strh.w	r0, [sp, #0x26]
	movs	r0, #2
	str	r0, [sp, #0x28]
	movs	r0, #0
	str	r0, [sp, #0x2c]
	movs	r0, #2
	str	r0, [sp, #0x30]
	movs	r0, #0
	str	r0, [sp, #0x34]
	str	r0, [sp, #0x38]
	str	r0, [sp, #0x3c]
	str	r0, [sp, #0x40]
	strb.w	r0, [sp, #4]
	mov.w	r0, #0x4000
	strh.w	r0, [sp, #6]
	movs	r0, #2
	str	r0, [sp, #8]
	movs	r0, #0
	str	r0, [sp, #0xc]
	movs	r0, #2
	str	r0, [sp, #0x10]
	movs	r0, #0
	str	r0, [sp, #0x14]
	str	r0, [sp, #0x18]
	str	r0, [sp, #0x1c]
	str	r0, [sp, #0x20]
	add	r1, sp, #4
	add	r0, sp, #0x24
	bl	fn_080048bc
	movs	r2, #8
	mov	r1, r2
	movs	r0, #0
	bl	set_byte0_clear_byte1_a0000220
	movs	r1, #1
	movs	r0, #0
	bl	set_bit0_a0000000
	add	sp, #0x64
	pop	{pc}
.L08004838:
	.word	0x00180005
.L0800483c:
	.word	0x00140008
.L08004840:
	.word	0x301b0101
.L08004844:
	.word	0x40011400
.L08004848:
	.word	0x40011800

@ ----------------------------------------------------------------------------
@ set_bit0_a0000000 - r0 = index, r1 = value: the word at
@ 0xa0000000 + index * 8 has bit 0 replaced by r1 & 1.
@ No return value.
@ Caller: 0x08004830 (inside 0x080046b0) with (0, 1).
@ ----------------------------------------------------------------------------
	.section .text.set_bit0_a0000000,"ax",%progbits
	.global set_bit0_a0000000
	.thumb_func
	.type set_bit0_a0000000, %function
set_bit0_a0000000:
	lsls	r2, r0, #3
	sub.w	r2, r2, #0x60000000
	ldr	r2, [r2]
	bfi	r2, r1, #0, #1
	lsls	r3, r0, #3
	sub.w	r3, r3, #0x60000000
	str	r2, [r3]
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08004862 - r0 = record. The word at 0xa0000000 + byte [r0] * 8 = OR of
@ bytes [1], [2], [3] (OR-ed as one byte), halfwords [4], [6], [8], [0xa],
@ [0xc], [0xe], [0x10], [0x12] and word [0x14]. When byte [r0+2] == 8, the
@ stored word then has bit 6 cleared and 0x40 added.
@ No return value.
@ Caller: 0x080047c8 (inside 0x080046b0).
@ ----------------------------------------------------------------------------
	.section .text.fn_08004862,"ax",%progbits
	.global fn_08004862
	.thumb_func
	.type fn_08004862, %function
fn_08004862:
	ldrb	r1, [r0, #1]
	ldrb	r2, [r0, #2]
	orrs	r1, r2
	ldrb	r2, [r0, #3]
	orrs	r1, r2
	ldrh	r2, [r0, #4]
	orrs	r1, r2
	ldrh	r2, [r0, #6]
	orrs	r1, r2
	ldrh	r2, [r0, #8]
	orrs	r1, r2
	ldrh	r2, [r0, #0xa]
	orrs	r1, r2
	ldrh	r2, [r0, #0xc]
	orrs	r1, r2
	ldrh	r2, [r0, #0xe]
	orrs	r1, r2
	ldrh	r2, [r0, #0x10]
	orrs	r1, r2
	ldrh	r2, [r0, #0x12]
	orrs	r1, r2
	ldr	r2, [r0, #0x14]
	orrs	r1, r2
	ldrb	r2, [r0]
	lsls	r2, r2, #3
	sub.w	r2, r2, #0x60000000
	str	r1, [r2]
	ldrb	r1, [r0, #2]
	cmp	r1, #8
	bne.n	.L080048ba
	ldrb	r1, [r0]
	lsls	r1, r1, #3
	sub.w	r1, r1, #0x60000000
	ldr	r1, [r1]
	bic.w	r1, r1, #0x40
	adds	r1, #0x40
	ldrb	r2, [r0]
	lsls	r2, r2, #3
	sub.w	r2, r2, #0x60000000
	str	r1, [r2]
.L080048ba:
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_080048bc - r0 = record A, r1 = record B (32-byte records).
@ The word at 0xa0000004 + byte [A] * 8 = word [A+4] | word [A+8] << 4 |
@ word [A+0xc] << 8 | halfword [A+0x10] << 16 | halfword [A+0x14] << 20 |
@ byte [A+0x18] << 24 | word [A+0x1c].
@ When halfword [A+2] == 0x4000: the word at 0xa0000104 + byte [B] * 8 = the
@ same expression over B; otherwise that word = 0x0fffffff.
@ No return value.
@ Caller: 0x0800481e (inside 0x080046b0).
@ ----------------------------------------------------------------------------
	.section .text.fn_080048bc,"ax",%progbits
	.p2align 2
	.global fn_080048bc
	.thumb_func
	.type fn_080048bc, %function
fn_080048bc:
	push	{r4, lr}
	ldrd	r2, r3, [r0, #4]
	orr.w	r2, r2, r3, lsl #4
	ldr	r3, [r0, #0xc]
	orr.w	r2, r2, r3, lsl #8
	ldrh	r3, [r0, #0x10]
	orr.w	r2, r2, r3, lsl #16
	ldrh	r3, [r0, #0x14]
	orr.w	r2, r2, r3, lsl #20
	ldrb	r3, [r0, #0x18]
	orr.w	r2, r2, r3, lsl #24
	ldr	r3, [r0, #0x1c]
	orrs	r2, r3
	ldrb	r3, [r0]
	mov.w	r4, #0xa0000000
	add.w	r3, r4, r3, lsl #3
	str	r2, [r3, #4]
	ldrh	r2, [r0, #2]
	cmp.w	r2, #0x4000
	bne.n	.L08004924
	ldrd	r2, r3, [r1, #4]
	orr.w	r2, r2, r3, lsl #4
	ldr	r3, [r1, #0xc]
	orr.w	r2, r2, r3, lsl #8
	ldrh	r3, [r1, #0x10]
	orr.w	r2, r2, r3, lsl #16
	ldrh	r3, [r1, #0x14]
	orr.w	r2, r2, r3, lsl #20
	ldrb	r3, [r1, #0x18]
	orr.w	r2, r2, r3, lsl #24
	ldr	r3, [r1, #0x1c]
	orrs	r2, r3
	ldr	r3, .L08004934
	ldrb	r4, [r1]
	str.w	r2, [r3, r4, lsl #3]
	b.n	.L08004930
.L08004924:
	mvn.w	r3, #0xf0000000
	ldr	r2, .L08004934
	ldrb	r4, [r1]
	str.w	r3, [r2, r4, lsl #3]
.L08004930:
	pop	{r4, pc}
	.short	0x0000	@ padding
.L08004934:
	.word	0xa0000104

@ ----------------------------------------------------------------------------
@ init_record_08004862 - r0 = record (24 bytes): byte [0] = 0, [1] = 2,
@ [2] = 0, [3] = 0, halfwords [4], [6], [8], [0xa], [0xc] = 0, [0xe] = 0x1000,
@ [0x10] = 0x2000, [0x12] = 0, word [0x14] = 0.
@ No return value.
@ Caller: 0x0800477e (inside 0x080046b0); layout read by fn_08004862 (0x08004862).
@ ----------------------------------------------------------------------------
	.section .text.init_record_08004862,"ax",%progbits
	.global init_record_08004862
	.thumb_func
	.type init_record_08004862, %function
init_record_08004862:
	movs	r1, #0
	strb	r1, [r0]
	movs	r1, #2
	strb	r1, [r0, #1]
	movs	r1, #0
	strb	r1, [r0, #2]
	strb	r1, [r0, #3]
	strh	r1, [r0, #4]
	strh	r1, [r0, #6]
	strh	r1, [r0, #8]
	strh	r1, [r0, #0xa]
	strh	r1, [r0, #0xc]
	mov.w	r1, #0x1000
	strh	r1, [r0, #0xe]
	lsls	r1, r1, #1
	strh	r1, [r0, #0x10]
	movs	r1, #0
	strh	r1, [r0, #0x12]
	str	r1, [r0, #0x14]
	bx	lr

@ ----------------------------------------------------------------------------
@ init_records_080048bc - r0 = record A, r1 = record B; each gets: byte [0] = 0,
@ halfword [2] = 0, words [4] = 0xf, [8] = 0xf, [0xc] = 0xff, [0x10] = 0xf,
@ [0x14] = 0xf, [0x18] = 0xf, [0x1c] = 0.
@ No return value.
@ Caller: 0x080047d0 (inside 0x080046b0); layout read by fn_080048bc (0x080048bc).
@ ----------------------------------------------------------------------------
	.section .text.init_records_080048bc,"ax",%progbits
	.global init_records_080048bc
	.thumb_func
	.type init_records_080048bc, %function
init_records_080048bc:
	movs	r2, #0
	strb	r2, [r0]
	strh	r2, [r0, #2]
	movs	r2, #0xf
	str	r2, [r0, #4]
	str	r2, [r0, #8]
	movs	r2, #0xff
	str	r2, [r0, #0xc]
	movs	r2, #0xf
	str	r2, [r0, #0x10]
	str	r2, [r0, #0x14]
	str	r2, [r0, #0x18]
	movs	r2, #0
	str	r2, [r0, #0x1c]
	strb	r2, [r1]
	strh	r2, [r1, #2]
	movs	r2, #0xf
	str	r2, [r1, #4]
	str	r2, [r1, #8]
	movs	r2, #0xff
	str	r2, [r1, #0xc]
	movs	r2, #0xf
	str	r2, [r1, #0x10]
	str	r2, [r1, #0x14]
	str	r2, [r1, #0x18]
	movs	r2, #0
	str	r2, [r1, #0x1c]
	bx	lr

