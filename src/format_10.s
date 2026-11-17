@ format_10.s - printf-style formatting: buffer / console front ends, padding and string emitters, integer, hex and float conversions
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ format_to_buffer_08007370 - sprintf-like entry.
@ r0 = destination buffer, r1 = format string, r2 and r3 = first variable
@ arguments (r0..r3 are pushed at 0x08007370; the argument list pointer passed
@ to 08008092 in r2 is sp+24 at 0x08007376, the address of the spilled r2; r3
@ passed to 08008092 is the callback 0x080080b9 (store_byte_advance), built at
@ 0x08007374/0x08007378 from a pc-relative distance word).
@ Calls fn_08008092 with the put-byte callback, then store_byte_advance(0,
@ &state) to store a terminating zero byte. Returns the fn_08008092 result.
@ ----------------------------------------------------------------------------
	.section .text.format_to_buffer_08007370,"ax",%progbits
	.p2align 2
	.global format_to_buffer_08007370
	.thumb_func
	.type format_to_buffer_08007370, %function
format_to_buffer_08007370:
	push	{r0, r1, r2, r3}
	push	{r2, r3, r4, lr}
	ldr	r3, .L08007398
	add	r2, sp, #0x18		@ argument list = spilled r2
.L08007378:
	add	r3, pc			@ r3 = store_byte_advance (callback)
	mov	r1, sp
	str	r0, [sp, #0x0]		@ state: destination pointer
	ldr	r0, [sp, #0x14]		@ r0 = format string (spilled r1)
	bl	fn_08008092
	mov	r4, r0
	movs	r0, #0x0
	mov	r1, sp
	bl	store_byte_advance	@ store terminating zero byte
	mov	r0, r4
	pop	{r2, r3, r4}
	ldr.w	pc, [sp], #0x14		@ drop the four spilled words and return
	.short	0x0000			@ padding
.L08007398:
	.word	store_byte_advance - (.L08007378 + 4)

@ ----------------------------------------------------------------------------
@ fn_0800739c - formatted output to the object at 0x20002ac8.
@ r0 = format string, r1..r3 = variable arguments spilled to the stack; calls
@ fn_080080f0(r0, 0x20002ac8, &args), i.e. formatted output to the object at
@ 0x20002ac8.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800739c,"ax",%progbits
	.p2align 2
	.global fn_0800739c
	.thumb_func
	.type fn_0800739c, %function
fn_0800739c:
	push	{r0, r1, r2, r3}
	ldr	r1, .L080073b0		@ r1 = 0x20002ac8
	push	{r4, lr}
	add	r2, sp, #0xc		@ argument list = spilled r1
	ldr	r0, [sp, #0x8]		@ format string (spilled r0)
	bl	fn_080080f0
	pop	{r4}
	ldr.w	pc, [sp], #0x14
.L080073b0:
	.word	0x20002ac8

@ ----------------------------------------------------------------------------
@ format_to_buffer_080073b4 - sprintf-like entry (same code as 08007370).
@ r0 = destination buffer, r1 = format string, r2 and r3 = first variable
@ arguments; calls fn_08008092 with callback 0x080080b9 (store_byte_advance),
@ then store_byte_advance(0, &state) to store a terminating zero byte; returns
@ the fn_08008092 result.
@ ----------------------------------------------------------------------------
	.section .text.format_to_buffer_080073b4,"ax",%progbits
	.p2align 2
	.global format_to_buffer_080073b4
	.thumb_func
	.type format_to_buffer_080073b4, %function
format_to_buffer_080073b4:
	push	{r0, r1, r2, r3}
	push	{r2, r3, r4, lr}
	ldr	r3, .L080073dc
	add	r2, sp, #0x18
.L080073bc:
	add	r3, pc
	mov	r1, sp
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0x14]
	bl	fn_08008092
	mov	r4, r0
	movs	r0, #0x0
	mov	r1, sp
	bl	store_byte_advance
	mov	r0, r4
	pop	{r2, r3, r4}
	ldr.w	pc, [sp], #0x14
	.short	0x0000			@ padding
.L080073dc:
	.word	store_byte_advance - (.L080073bc + 4)

@ ----------------------------------------------------------------------------
@ fn_080073e0 - emit leading fill characters of a format field.
@ r0 = format context; if flag bit0 (left-justify) is set returns at once;
@ otherwise outputs context[6] fill characters through callback
@ context[1](char, context[2]) (fill is 0x30 when flag bit4 is set, else 0x20)
@ and adds each to the counter context[8].
@ ----------------------------------------------------------------------------
	.section .text.fn_080073e0,"ax",%progbits
	.global fn_080073e0
	.thumb_func
	.type fn_080073e0, %function
fn_080073e0:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	ldr	r5, [r0, #0x18]		@ remaining field width
	ldr	r0, [r0, #0x0]		@ flag word
	lsls	r1, r0, #0x1b		@ flag bit4 to N
	bpl.n	.L080073f0
	movs	r6, #0x30
	b.n	.L080073f2
.L080073f0:
	movs	r6, #0x20
.L080073f2:
	lsls	r0, r0, #0x1f		@ flag bit0 to Z
	beq.n	.L08007406
	pop	{r4, r5, r6, pc}
.L080073f8:
	ldrd	r2, r1, [r4, #0x4]	@ r2 = callback, r1 = its argument
	mov	r0, r6
	blx	r2
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1		@ counter++
	str	r0, [r4, #0x20]
.L08007406:
	.inst.n	0x1e6d		@ subs r5, r5, #1
	bpl.n	.L080073f8
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_0800740c - emit trailing spaces of a left-justified format field.
@ r0 = format context; if flag bit0 is set outputs context[6] space
@ characters (0x20) through callback context[1](char, context[2]) and adds each
@ to the counter context[8], otherwise returns.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800740c,"ax",%progbits
	.global fn_0800740c
	.thumb_func
	.type fn_0800740c, %function
fn_0800740c:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	ldr	r5, [r0, #0x18]		@ remaining field width
	ldrb	r0, [r0, #0x0]
	lsls	r0, r0, #0x1f		@ flag bit0 to Z
	bne.n	.L08007428
	pop	{r4, r5, r6, pc}
.L0800741a:
	ldrd	r2, r1, [r4, #0x4]
	movs	r0, #0x20
	blx	r2
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
.L08007428:
	.inst.n	0x1e6d		@ subs r5, r5, #1
	bpl.n	.L0800741a
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_0800742e - emit a string field (%s / %c).
@ r0 = format context, r1 = string, r2 = length (1 = single character, else
@ NUL-terminated scan limited to r2, or to context[7] when flag bit5 is set).
@ Subtracts the length from context[6], adds it to context[8], pads via
@ fn_080073e0, emits each character through callback context[1], then pads via
@ fn_0800740c.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800742e,"ax",%progbits
	.global fn_0800742e
	.thumb_func
	.type fn_0800742e, %function
fn_0800742e:
	push	{r4, r5, r6, lr}
	mov	r4, r1
	mov	r5, r0
	cmp	r2, #0x1
	beq.n	.L08007444
	ldrb	r0, [r5, #0x0]
	lsls	r0, r0, #0x1a		@ flag bit5 (precision given)
	bpl.n	.L08007440
	ldr	r2, [r5, #0x1c]		@ limit = precision
.L08007440:
	movs	r3, #0x0
	b.n	.L0800744a
.L08007444:
	movs	r3, #0x1
	b.n	.L08007454
.L08007448:
	.inst.n	0x1c5b		@ adds r3, r3, #1
.L0800744a:
	cmp	r3, r2
	bcs.n	.L08007454
	ldrb	r0, [r4, r3]
	cmp	r0, #0x0
	bne.n	.L08007448
.L08007454:
	ldr	r0, [r5, #0x18]
	adds	r6, r4, r3		@ r6 = end of string
	subs	r0, r0, r3
	str	r0, [r5, #0x18]		@ width -= length
	ldr	r0, [r5, #0x20]
	add	r0, r3
	str	r0, [r5, #0x20]		@ counter += length
	mov	r0, r5
	bl	fn_080073e0
	b.n	.L08007474
.L0800746a:
	ldrd	r2, r1, [r5, #0x4]
	ldrb.w	r0, [r4], #0x1
	blx	r2
.L08007474:
	cmp	r4, r6
	bcc.n	.L0800746a
	mov	r0, r5
	bl	fn_0800740c
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ format_decimal_32 - format one 32-bit decimal conversion (%d %i %u).
@ r0 = context (flag word at +0x00, digit buffer at +0x24), r1 = conversion
@ character, r2 = pointer to the 4-byte argument slot (word read at
@ 0x08007488); no return value of its own, it ends with a tail jump to
@ emit_formatted_number (080078be), which returns r0 = 1 or 2 to the caller of
@ the conversion handler.
@ r1 == 0x75 ('u') takes the value through fn_080078ac (zero-extends to 8 bits
@ when flag bit10 is set, to 16 bits when bit8 is set); any other r1 (0x69,
@ 0x64) takes it through fn_0800789a (same widths, sign-extended): a negative
@ result is negated and gets the prefix string "-" (0x080074ec), otherwise flag
@ bit1 selects "+" (0x080074f0), otherwise flag bit2 selects " " (0x080074f4),
@ otherwise the empty string at 0x080074e8; prefix length r4 = 1 for '-', '+',
@ ' ', else 0.
@ Digit loop 0x080074c2..0x080074d8: udiv by 10 (r2 = 10) and mls, stores ASCII
@ digit + 0x30 at context+0x24+i, i counts digits, stops when the value is 0
@ (value 0 gives 0 digits).
@ Exit: pops r4-r8,lr then b.w emit_formatted_number with r0 = context, r1 =
@ digit count, r2 = prefix pointer, r3 = prefix length.
@ Entered by beq.w at 0x08007268 (r1 == 0x69), 0x0800726e (r1 == 0x64),
@ 0x08007274 (r1 == 0x75) inside format_one_conversion 08007238; only the forms
@ without the 64-bit marker (flag bit7) arrive. Entry state: lr = return
@ address of the handler's caller (nothing pushed yet); r3 unused.
@ The code at 0x080074f8 (no branch to it inside this unit) loads a pointer from the argument slot and stores the output counter
@ context[8] through it as a byte (flag bit10), halfword (bit8), doubleword
@ sign-extended (bit7) or word, and returns r0 = 1.
@ ----------------------------------------------------------------------------
	.section .text.format_decimal_32,"ax",%progbits
	.global format_decimal_32
	.thumb_func
	.type format_decimal_32, %function
format_decimal_32:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r6, r0
	movs	r4, #0x0		@ prefix length = 0
	ldr	r0, [r2, #0x0]		@ argument value
	cmp	r1, #0x75
	mov	r1, r6
	adr	r5, .L080074e8		@ prefix = empty string
	beq.n	.L080074b4
	bl	fn_0800789a		@ sign-extend per length modifier
	cmp	r0, #0x0
	bge.n	.L080074a0
	rsbs	r0, r0, #0x0		@ negate
	adr	r5, .L080074ec		@ prefix = "-"
	b.n	.L080074b0
.L080074a0:
	ldr	r1, [r6, #0x0]
	lsls	r2, r1, #0x1e		@ flag bit1 ('+')
	bpl.n	.L080074aa
	adr	r5, .L080074f0		@ prefix = "+"
	b.n	.L080074b0
.L080074aa:
	lsls	r1, r1, #0x1d		@ flag bit2 (' ')
	bpl.n	.L080074b8
	adr	r5, .L080074f4		@ prefix = " "
.L080074b0:
	movs	r4, #0x1
	b.n	.L080074b8
.L080074b4:
	bl	fn_080078ac		@ zero-extend per length modifier
.L080074b8:
	movs	r1, #0x0		@ digit count
	movs	r2, #0xa
	add.w	r7, r6, #0x24		@ digit buffer
	b.n	.L080074d6
.L080074c2:
	udiv	r12, r0, r2
	udiv	r3, r0, r2
	mls	r0, r2, r12, r0		@ r0 = value mod 10
	adds	r0, #0x30
	strb	r0, [r7, r1]
	mov	r0, r3			@ value /= 10
	.inst.n	0x1c49		@ adds r1, r1, #1
.L080074d6:
	cmp	r0, #0x0
	bne.n	.L080074c2
	mov	r3, r4
	mov	r2, r5
	mov	r0, r6
	pop.w	{r4, r5, r6, r7, r8, lr}
	b.w	emit_formatted_number
.L080074e8:
	.word	0x00000000		@ empty prefix string (and padding)
.L080074ec:
	.asciz	"-"
	.short	0x0000			@ padding
.L080074f0:
	.asciz	"+"
	.short	0x0000			@ padding
.L080074f4:
	.asciz	" "
	.short	0x0000			@ padding
	.global	L_080074f8		@ entered from format_one_conversion (startup_56)
	.thumb_func
L_080074f8:
.L080074f8:
	ldr	r1, [r2, #0x0]		@ r1 = pointer argument
	ldr	r2, [r0, #0x0]		@ flag word
	ldr	r0, [r0, #0x20]		@ output counter
	lsls	r3, r2, #0x15		@ flag bit10
	bpl.n	.L08007506
	strb	r0, [r1, #0x0]
	b.n	.L0800751c
.L08007506:
	lsls	r3, r2, #0x17		@ flag bit8
	bpl.n	.L0800750e
	strh	r0, [r1, #0x0]
	b.n	.L0800751c
.L0800750e:
	lsls	r3, r2, #0x18		@ flag bit7
	bpl.n	.L0800751a
	asrs	r2, r0, #0x1f
	strd	r0, r2, [r1, #0x0]
	b.n	.L0800751c
.L0800751a:
	str	r0, [r1, #0x0]
.L0800751c:
	movs	r0, #0x1
	bx	lr

@ ----------------------------------------------------------------------------
@ format_hex_u64 - format one hexadecimal conversion of a 64-bit value.
@ r0 = format context, r1 = conversion character (0x70 selects the pointer
@ form), r2 = value low word, r3 = value high word; returns by tail jump to
@ emit_formatted_number (r0 = 1 or 2 from there).
@ Digit string: when flag bit11 of the halfword at context+0 is set it uses the
@ table 0x08046254 ('0123456789ABCDEF@0X'), else 0x08046268
@ ('0123456789abcdef@0x') (ldr r4,[pc] + add r4,pc at 0x0800752a/0x0800752c and
@ 0x08007530/0x08007532 + adds #14).
@ Loop 0x0800753e..0x08007554: takes the low nibble of r3:r2, stores
@ table[nibble] at context+0x24+i, shifts r3:r2 right by 4, until both words
@ are 0.
@ Prefix: only when flag bit3 is set: r1 == 0x70 gives the 1-character prefix
@ '@' (table+16, length 1, 0x08007570), any other r1 with at least one digit
@ gives '0x' / '0X' (table+17, length 2, 0x08007566); otherwise the prefix is
@ the table start with length 0.
@ Exit: pop {r4,r5,r6,r7} then b.w emit_formatted_number with r0 = context,
@ r1 = digit count, r2 = prefix pointer, r3 = prefix length (lr untouched, so
@ it returns to the caller of the conversion).
@ Entered by: b.n at 0x08007590 (from 08007576, r3 = 0), b.n at 0x0800759c
@ (block 0x08007592: reached by beq.w at 0x0800729e for r1 == 0xf8, loads the
@ 8-byte aligned slot with ldrd r2,r3), b.n at 0x080075ae (block 0x0800759e:
@ reached by beq.w at 0x08007240 for r1 == 0x70, ors 0x20 into the flag word,
@ stores 8 at context+0x1c, r3 = 0, r2 = word at [r2]). Entry state: r4-r7 are
@ not yet saved (pushed at 0x08007520); lr is the caller's return address.
@ ----------------------------------------------------------------------------
	.section .text.format_hex_u64,"ax",%progbits
	.global format_hex_u64
	.thumb_func
	.type format_hex_u64, %function
format_hex_u64:
	push	{r4, r5, r6, r7}
	mov	r5, r1
	ldrh	r1, [r0, #0x0]
	lsls	r1, r1, #0x14		@ flag bit11 (upper case)
	bpl.n	.L08007530
	.inst.n	0x4c21			@ ldr r4, [pc, #0x84] = word at 0x080075b0 (literal lies in format_hex_u32's section)
	add	r4, pc			@ r4 = upper case table
	b.n	.L08007536
.L08007530:
	.inst.n	0x4c1f			@ ldr r4, [pc, #0x7c] = word at 0x080075b0 (literal lies in format_hex_u32's section)
.L08007532:
	add	r4, pc
	adds	r4, #0xe		@ r4 = lower case table
.L08007536:
	movs	r1, #0x0		@ digit count
	add.w	r6, r0, #0x24		@ digit buffer
	b.n	.L08007550
.L0800753e:
	and	r7, r2, #0xf
	lsrs	r2, r2, #0x4
	ldrb	r7, [r4, r7]
	orr.w	r2, r2, r3, lsl #0x1c
	lsrs	r3, r3, #0x4
	strb	r7, [r6, r1]
	.inst.n	0x1c49		@ adds r1, r1, #1
.L08007550:
	orrs.w	r7, r2, r3
	bne.n	.L0800753e
	ldrb	r2, [r0, #0x0]
	movs	r3, #0x0		@ prefix length = 0
	lsls	r2, r2, #0x1c		@ flag bit3 ('#')
	bpl.n	.L08007568
	cmp	r5, #0x70
	beq.n	.L08007570
	cbz	r1, .L08007568
	movs	r3, #0x2
	adds	r4, #0x11		@ prefix "0x" / "0X"
.L08007568:
	mov	r2, r4
	pop	{r4, r5, r6, r7}
	b.w	emit_formatted_number
.L08007570:
	movs	r3, #0x1
	adds	r4, #0x10		@ prefix '@'
	b.n	.L08007568

@ ----------------------------------------------------------------------------
@ format_hex_u32 - hexadecimal conversion of a 32-bit argument.
@ r0 = format context, r1 = conversion character, r2 = pointer to the 4-byte
@ argument slot; reads the word [r2], masks it with fn_080078ac (r1 = context
@ as flag-word pointer: 8-bit when flag bit10, 16-bit when bit8, else 32-bit),
@ then continues in format_hex_u64 with r2 = masked value, r3 = 0 (high word).
@ Code: push {r4,r5,r6,lr}; saves r0 and r1 in r4 and r5; bl fn_080078ac;
@ restores r0 = context and r1 = conversion character; pops r4,r5,r6,lr;
@ movs r3,#0; b.n format_hex_u64 (tail jump, return value comes from
@ emit_formatted_number via format_hex_u64).
@ Entered by beq.w at 0x08007280 (r1 == 0x78) in format_one_conversion
@ 08007238. The code at 0x08007592 (r2 aligned up to 8, ldrd r2,r3 of the
@ 64-bit slot) and at 0x0800759e (pointer form: sets flag bit5, precision 8,
@ r2 = word at [r2], r3 = 0) are other entries to format_hex_u64.
@ ----------------------------------------------------------------------------
	.section .text.format_hex_u32,"ax",%progbits
	.global format_hex_u32
	.thumb_func
	.type format_hex_u32, %function
format_hex_u32:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	mov	r1, r4
	ldr	r0, [r2, #0x0]
	bl	fn_080078ac
	mov	r2, r0
	mov	r1, r5
	mov	r0, r4
	pop.w	{r4, r5, r6, lr}
	movs	r3, #0x0
	b.n	format_hex_u64
	.global	L_08007592		@ entered from format_one_conversion (startup_56)
	.thumb_func
L_08007592:
.L08007592:
	.inst.n	0x1dd2		@ adds r2, r2, #7
	bic	r3, r2, #0x7		@ align slot to 8
	ldrd	r2, r3, [r3, #0x0]
	b.n	format_hex_u64
	.global	L_0800759e		@ entered from format_one_conversion (startup_56)
	.thumb_func
L_0800759e:
.L0800759e:
	ldr	r3, [r0, #0x0]
	ldr	r2, [r2, #0x0]
	orr	r3, r3, #0x20
	str	r3, [r0, #0x0]
	movs	r3, #0x8
	str	r3, [r0, #0x1c]
	movs	r3, #0x0
	b.n	format_hex_u64
.L080075b0:
	.word	0x0003ed24		@ distance for add r4,pc at 08007532: 0x0003ED24 + 0x08007532 + 4 = 0x0804625A (the add lies in format_hex_u64's section, so GAS cannot form the symbolic difference)

@ ----------------------------------------------------------------------------
@ fn_080075b4 - format driver (the vfprintf-like loop).
@ r0 = format context (callbacks: [3] get next format char, [1] put char),
@ r1 = argument slot pointer; loops reading format characters until 0; for '%'
@ it parses flags using the byte table at 0x0804627c indexed by (character -
@ 0x20) for characters 0x20..0x30 (' '=0x04, '#'=0x08, '+'=0x02, '-'=0x01,
@ '0'=0x10; a zero entry ends the flag characters), flag 0x02 clears 0x04, '.'
@ sets 0x20, a negative width sets bit0 and is negated, bit0 clears bit4,
@ width and precision (digits via is_ascii_digit 08044e44 or '*' taking an
@ argument), length modifiers 'l'=0x40, 'h'=0x100, 'll' and 'j'=0x80,
@ 'hh'=0x400, 't','z','L' add no flag, upper-case A..Z conversion characters
@ are lower-cased and set flag 0x800, sets flag word at context[0], then calls
@ format_one_conversion 08007238(context, conversion, args) and advances the
@ argument pointer by 4 (result 1) or to the next 8-aligned slot plus 8 (other
@ nonzero result); result 0 puts the conversion character out through callback
@ [1]; other characters are put through callback [1]; returns the total count
@ in context[8].
@ ----------------------------------------------------------------------------
	.section .text.fn_080075b4,"ax",%progbits
	.global fn_080075b4
	.thumb_func
	.type fn_080075b4, %function
fn_080075b4:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	mov	r9, r1			@ argument pointer
	mov	r4, r0			@ context
	mov.w	r10, #0x0
	ldr.w	r11, .L08007738
.L080075c4:
	add	r11, pc			@ r11 = flag table 0x0804627c
	str.w	r10, [r0, #0x20]	@ counter = 0
.L080075ca:
	mov	r0, r4
	ldr	r1, [r4, #0xc]
	blx	r1			@ next format character
	cmp	r0, #0x0
	beq.n	.L080076be
	cmp	r0, #0x25
	beq.n	.L080075e6
.L080075d8:
	ldrd	r2, r1, [r4, #0x4]
	blx	r2			@ put ordinary character
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
	b.n	.L080075ca
.L080075e6:
	movs	r6, #0x0		@ flags = 0
	mov	r7, r11
.L080075ea:
	mov	r0, r4
	ldr	r1, [r4, #0xc]
	blx	r1
	cmp	r0, #0x20
	mov	r5, r0
	blt.n	.L08007606
	cmp	r5, #0x31
	bcs.n	.L08007606
	adds	r0, r7, r5
	ldrb.w	r0, [r0, #-0x20]	@ flag bit for this character
	cbz	r0, .L08007606
	orrs	r6, r0
	b.n	.L080075ea
.L08007606:
	lsls	r0, r6, #0x1e		@ flag bit1 ('+')
	bpl.n	.L0800760e
	bic	r6, r6, #0x4		@ '+' overrides ' '
.L0800760e:
	str.w	r10, [r4, #0x1c]	@ precision = 0
	movs	r7, #0x0
	str.w	r10, [r4, #0x18]	@ width = 0
.L08007618:
	cmp	r5, #0x2a
	beq.n	.L08007630
	mov	r0, r5
	bl	is_ascii_digit
	cbz	r0, .L08007674
	add.w	r8, r4, r7, lsl #0x2
	subs	r5, #0x30
	str.w	r5, [r8, #0x18]
	b.n	.L08007664
.L08007630:
	ldr.w	r1, [r9], #0x4		@ '*': value from the argument list
	mov	r0, r4
	add.w	r2, r4, r7, lsl #0x2
	str	r1, [r2, #0x18]
	ldr	r1, [r4, #0xc]
	blx	r1
	cmp	r7, #0x1
	mov	r5, r0
	bne.n	.L08007678
	ldr	r0, [r4, #0x1c]
	cmp	r0, #0x0
	bge.n	.L0800768e
	bic	r6, r6, #0x20		@ negative precision: none given
	b.n	.L0800768e
.L08007652:
	ldr.w	r0, [r8, #0x18]
	add.w	r0, r0, r0, lsl #0x2
	add.w	r0, r5, r0, lsl #0x1
	subs	r0, #0x30
	str.w	r0, [r8, #0x18]		@ value = value * 10 + digit
.L08007664:
	mov	r0, r4
	ldr	r1, [r4, #0xc]
	blx	r1
	mov	r5, r0
	bl	is_ascii_digit
	cmp	r0, #0x0
	bne.n	.L08007652
.L08007674:
	cmp	r7, #0x1
	beq.n	.L0800768e
.L08007678:
	cmp	r5, #0x2e		@ '.'
	bne.n	.L0800768e
	mov	r0, r4
	ldr	r1, [r4, #0xc]
	blx	r1
	.inst.n	0x1c7f		@ adds r7, r7, #1
	mov	r5, r0
	cmp	r7, #0x2
	orr	r6, r6, #0x20		@ precision given
	blt.n	.L08007618
.L0800768e:
	ldr	r0, [r4, #0x18]
	cmp	r0, #0x0
	bge.n	.L0800769c
	rsbs	r0, r0, #0x0		@ negative width: left-justify
	orr	r6, r6, #0x1
	str	r0, [r4, #0x18]
.L0800769c:
	lsls	r0, r6, #0x1f
	beq.n	.L080076a4
	bic	r6, r6, #0x10		@ left-justify cancels zero fill
.L080076a4:
	cmp	r5, #0x6c		@ 'l'
	beq.n	.L080076c0
	cmp	r5, #0x68		@ 'h'
	beq.n	.L080076c0
	cmp	r5, #0x4c		@ 'L'
	beq.n	.L08007724
	cmp	r5, #0x6a		@ 'j'
	beq.n	.L08007720
	cmp	r5, #0x74		@ 't'
	beq.n	.L08007724
	cmp	r5, #0x7a		@ 'z'
	beq.n	.L08007724
	b.n	.L080076ec
.L080076be:
	b.n	.L08007732
.L080076c0:
	ldr	r1, [r4, #0xc]
	mov	r7, r5
	mov	r0, r4
	blx	r1
	cmp	r0, r7
	mov	r5, r0
	bne.n	.L080076e2
	cmp	r7, #0x6c
	beq.n	.L08007720
	mov.w	r0, #0x400		@ 'hh'
.L080076d6:
	ldr	r1, [r4, #0xc]
	orrs	r6, r0
	mov	r0, r4
	blx	r1
	mov	r5, r0
	b.n	.L080076ec
.L080076e2:
	cmp	r7, #0x6c
	beq.n	.L0800771c
	mov.w	r0, #0x100		@ 'h'
.L080076ea:
	orrs	r6, r0
.L080076ec:
	cbz	r5, .L08007732
	sub.w	r0, r5, #0x41
	cmp	r0, #0x19
	bhi.n	.L080076fc
	adds	r5, #0x20		@ upper case conversion: lower-case it
	orr	r6, r6, #0x800		@ and remember it
.L080076fc:
	mov	r2, r9
	mov	r1, r5
	mov	r0, r4
	str	r6, [r4, #0x0]		@ flag word
	mov	r6, r9
	bl	format_one_conversion
	cbz	r0, .L0800772e
	cmp	r0, #0x1
	beq.n	.L08007728
	.inst.n	0x1df6		@ adds r6, r6, #7
	bic	r0, r6, #0x7
	add.w	r9, r0, #0x8		@ 8-byte argument
	b.n	.L080075ca
.L0800771c:
	movs	r0, #0x40		@ 'l'
	b.n	.L080076ea
.L08007720:
	movs	r0, #0x80		@ 'll' / 'j'
	b.n	.L080076d6
.L08007724:
	movs	r0, #0x0		@ 't' 'z' 'L': no flag
	b.n	.L080076d6
.L08007728:
	add.w	r9, r6, #0x4		@ 4-byte argument
	b.n	.L080075ca
.L0800772e:
	mov	r0, r5
	b.n	.L080075d8		@ unknown conversion: put it out
.L08007732:
	ldr	r0, [r4, #0x20]		@ return count
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, r12, pc}
.L08007738:
	.word	d_0804627c - (.L080075c4 + 4)

@ ----------------------------------------------------------------------------
@ fn_0800789a - sign-extend a value per the length modifier flags.
@ r0 = value, r1 = pointer to the flag word; if flag bit10 is set returns r0
@ sign-extended from 8 bits, else if bit8 is set returns r0 sign-extended from
@ 16 bits, else r0 unchanged.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800789a,"ax",%progbits
	.global fn_0800789a
	.thumb_func
	.type fn_0800789a, %function
fn_0800789a:
	ldr	r1, [r1, #0x0]
	lsls	r2, r1, #0x15		@ flag bit10
	bpl.n	.L080078a4
	sxtb	r0, r0
.L080078a2:
	bx	lr
.L080078a4:
	lsls	r1, r1, #0x17		@ flag bit8
	bpl.n	.L080078a2
	sxth	r0, r0
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_080078ac - zero-extend a value per the length modifier flags.
@ r0 = value, r1 = pointer to the flag word; if flag bit10 is set returns
@ r0 & 0xff, else if bit8 is set returns r0 & 0xffff, else r0 unchanged.
@ ----------------------------------------------------------------------------
	.section .text.fn_080078ac,"ax",%progbits
	.global fn_080078ac
	.thumb_func
	.type fn_080078ac, %function
fn_080078ac:
	ldr	r1, [r1, #0x0]
	lsls	r2, r1, #0x15		@ flag bit10
	bpl.n	.L080078b6
	uxtb	r0, r0
.L080078b4:
	bx	lr
.L080078b6:
	lsls	r1, r1, #0x17		@ flag bit8
	bpl.n	.L080078b4
	uxth	r0, r0
	bx	lr

@ ----------------------------------------------------------------------------
@ emit_formatted_number - write one converted integer field through the output
@ callback of the format context.
@ r0 = context (flag word +0x00, callback +0x04, callback argument +0x08,
@ remaining field width +0x18, precision +0x1c, output counter +0x20, digits
@ stored reversed at +0x24), r1 = digit count n, r2 = prefix string pointer,
@ r3 = prefix length. Returns r0 = 2 when flag bit7 (the 64-bit marker tested
@ at 0x08007960) is set, else 1.
@ Minimum digit count: when flag bit5 is set it is context[7] and flag bit4 is
@ cleared (0x080078d4..0x080078da), else 1; zero padding z = max(0, minimum -
@ n). Remaining width context[6] -= z + n + prefix length.
@ Output order: when flag bit4 is clear, fn_080073e0 pads first (spaces unless
@ flag bit0 left-justify, which makes it return at once); then the prefix
@ characters through blx of context[1](char, context[2]); then, when flag bit4
@ is set, fn_080073e0 pads with '0'; then z characters '0'; then the n digits
@ from context+0x24+n-1 down to context+0x24 (the subs of r5 runs before the
@ ldrb.w, so the first digit read is at +0x24+n-1); then fn_0800740c (trailing
@ spaces when flag bit0 is set). Every character adds 1 to context[8].
@ Exit: pops r4-r9,r10,pc. Entered by b.w at 0x080074e4 (from 08007480),
@ 0x0800756c (from 08007520), 0x08008238 (from 080081d0), 0x0800828c (from
@ 0x0800824c); each caller has popped its registers before the jump, so lr is
@ the conversion handler's caller.
@ ----------------------------------------------------------------------------
	.section .text.emit_formatted_number,"ax",%progbits
	.global emit_formatted_number
	.thumb_func
	.type emit_formatted_number, %function
emit_formatted_number:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r5, r1			@ digit count
	mov	r9, r3			@ prefix length
	mov	r10, r2			@ prefix pointer
	mov	r4, r0
	add.w	r8, r0, #0x24		@ digit buffer
	ldr	r1, [r0, #0x0]
	lsls	r0, r1, #0x1a		@ flag bit5 (precision given)
	bpl.n	.L080078de
	ldr	r0, [r4, #0x1c]		@ minimum digits = precision
	bic	r1, r1, #0x10		@ precision cancels zero fill
	str	r1, [r4, #0x0]
	b.n	.L080078e0
.L080078de:
	movs	r0, #0x1
.L080078e0:
	cmp	r0, r5
	ble.n	.L080078e8
	subs	r7, r0, r5		@ r7 = zero padding z
	b.n	.L080078ea
.L080078e8:
	movs	r7, #0x0
.L080078ea:
	ldr	r1, [r4, #0x18]
	adds	r2, r7, r5
	add.w	r0, r2, r9
	subs	r0, r1, r0
	str	r0, [r4, #0x18]		@ width -= z + n + prefix length
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1b		@ flag bit4
	bmi.n	.L08007902
	mov	r0, r4
	bl	fn_080073e0		@ leading pad
.L08007902:
	movs	r6, #0x0
	b.n	.L08007918
.L08007906:
	ldrd	r2, r1, [r4, #0x4]
	ldrb.w	r0, [r10, r6]		@ prefix character
	blx	r2
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	.inst.n	0x1c76		@ adds r6, r6, #1
	str	r0, [r4, #0x20]
.L08007918:
	cmp	r6, r9
	blt.n	.L08007906
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1b		@ flag bit4
	bpl.n	.L08007938
	mov	r0, r4
	bl	fn_080073e0		@ zero pad
	b.n	.L08007938
.L0800792a:
	ldrd	r2, r1, [r4, #0x4]
	movs	r0, #0x30
	blx	r2
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
.L08007938:
	subs	r0, r7, #0x0
	sub.w	r7, r7, #0x1
	bgt.n	.L0800792a
	b.n	.L08007952
.L08007942:
	ldrd	r2, r1, [r4, #0x4]
	ldrb.w	r0, [r8, r5]		@ digit, most significant first
	blx	r2
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
.L08007952:
	subs	r0, r5, #0x0
	sub.w	r5, r5, #0x1
	bgt.n	.L08007942
	mov	r0, r4
	bl	fn_0800740c		@ trailing pad
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x18		@ flag bit7 (64-bit marker)
	bpl.n	.L0800796c
	movs	r0, #0x2
.L08007968:
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
.L0800796c:
	movs	r0, #0x1
	b.n	.L08007968

@ ----------------------------------------------------------------------------
@ fn_08007970 - decimal digit generator for double conversions.
@ r0 = result record (3 words: exponent, digit count, mode), r1 = digit buffer,
@ r2 = pointer to a double, r3 = digit count, [stack] = mode; scales the value
@ by powers of ten using fn_08008448, fn_08043046, fn_0804356a, fn_08043540,
@ extracts decimal digits with div10_u64 (08008310, divide by 10) into r1 as
@ ASCII '0'+digit, NUL-terminates; a zero input (mantissa words zero, orrs at
@ 080079be) fills r3 bytes with '0' unless mode is 1, then stores the NUL.
@ Multiplier 0x4d10/65536 is applied to the binary exponent (value minus 0x3ff:
@ subw at 080079c8, muls at 080079cc, asrs #16 at 080079ce).
@ The stores of the three result words (strd r2,r0,[r1] at 08007a0a, str r8,
@ [r1,#8] at 08007a06) are followed by add sp,#0x3c at 08007a0e, which falls
@ through into the next unit fn_08007a10 (08007a10: pop.w {r4-r11,pc}, the
@ return); the other exit is b.n 08007a0e at 08007b16. The body is
@ 08007970..08007a0f and 08007a14..08007b1f, with fn_08007a10 between them.
@ ----------------------------------------------------------------------------
	.section .text.fn_08007970,"ax",%progbits
	.global fn_08007970
	.thumb_func
	.type fn_08007970, %function
fn_08007970:
	push.w	{r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, lr}
	mov	r4, r1			@ digit buffer
	mov	r6, r3			@ digit count
	mov.w	r7, #0xffffffff
	sub	sp, #0x2c
	ldrd	r0, r1, [r2, #0x0]	@ double: low, high
	ldr.w	r8, [sp, #0x60]		@ mode (stack argument)
	str	r0, [sp, #0x28]
	mov	r10, r1
	ubfx	r5, r1, #0x14, #0xb	@ biased exponent
	cbnz	r5, .L08007992
	mov	r5, r7
.L08007992:
	movs	r1, #0x0
	mov	r0, r1
	mov.w	r0, #0x0
	cmp.w	r10, #0x0
	and	r0, r0, #0xc00000
	bge.n	.L080079b0
	add.w	r0, r0, r0, lsl #0x2
	mov.w	r1, #0xc00000
	and.w	r0, r1, r0, lsr #0x1
.L080079b0:
	lsr.w	r9, r0, #0x16
	cmp.w	r9, #0x1
	ble.n	.L080079bc
	mov	r9, r7
.L080079bc:
	ldr	r0, [sp, #0x28]
	orrs.w	r0, r0, r10, lsl #0x1	@ zero test (mantissa words, sign dropped)
	beq.n	.L080079e2
	movw	r0, #0x4d10
	subw	r5, r5, #0x3ff
	muls	r5, r0
	asrs	r7, r5, #0x10		@ decimal exponent estimate
.L080079d0:
	cmp.w	r8, #0x0
	beq.n	.L08007a14
	rsbs	r5, r6, #0x0
.L080079d8:
	subs	r1, r5, #0x0
	ble.n	.L08007a1a
	rsb.w	r2, r9, #0x0
	b.n	.L08007a1c
.L080079e2:
	cmp.w	r8, #0x1
	mov.w	r0, #0x0
	beq.n	.L080079f0
	movs	r1, #0x30
	b.n	.L080079f8
.L080079f0:
	mvns	r2, r6
	b.n	.L08007a00
.L080079f4:
	strb	r1, [r4, r0]
	.inst.n	0x1c40		@ adds r0, r0, #1
.L080079f8:
	cmp	r0, r6
	blt.n	.L080079f4
	mov	r0, r6
	movs	r2, #0x0
.L08007a00:
	movs	r1, #0x0
	strb	r1, [r4, r0]		@ NUL terminator
	ldr	r1, [sp, #0x2c]		@ result record pointer (spilled r0)
	str.w	r8, [r1, #0x8]
	strd	r2, r0, [r1, #0x0]
.L08007a0e:
	add	sp, #0x3c

@ ----------------------------------------------------------------------------
@ fn_08007a10 - shared function epilogue, followed by the rest of the body of
@ fn_08007970.
@ pop.w {r4-r11,pc} at 08007a10 restores r4..r11 and returns to the caller of
@ the code that reached it: fn_08007970 (push {r0-r3,r4-r11,lr} at 08007970,
@ sub sp,#0x2c at 0800797c) or format_float_efg (push {r4-r11,lr} at 08007b20,
@ sub sp,#0x44 at 08007b2e). Entered from: fall-through from 08007a0e (add
@ sp,#0x3c; 08007a0e is reached by falling on from strd r2,r0,[r1] at 08007a0a
@ and by b 08007a0e at 08007b16) and by b.n 08007a10 at 08007d8a (after movs
@ r0,#3 at 08007d86 and add sp,#0x44 at 08007d88). Expects on entry: sp at the
@ saved r4 slot, r0 = return value (3 on the path through 08007d86; the
@ epilogue does not touch r0).
@ The bytes after it, 08007a14 (subs r5,r7,r6; adds r5,r5,#1; b 080079d8), are
@ other code of fn_08007970 entered by beq at 080079d4: the scaling, digit
@ extraction (div10_u64), digit reversal for mode 0 and rounding / zero-trim
@ steps of the digit generator, ending with the result record stores
@ (str.w r8,[r0,#8]; strd r2,r11,[r0]) and b 08007a0e.
@ ----------------------------------------------------------------------------
	.section .text.fn_08007a10,"ax",%progbits
	.global fn_08007a10
	.thumb_func
	.type fn_08007a10, %function
fn_08007a10:
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08007a14:
	subs	r5, r7, r6
	.inst.n	0x1c6d		@ adds r5, r5, #1
	b.n	.L080079d8
.L08007a1a:
	mov	r2, r9
.L08007a1c:
	bge.n	.L08007a20
	rsbs	r1, r5, #0x0
.L08007a20:
	add	r0, sp, #0x18
	bl	fn_08008448
	add	r3, sp, #0x18
	ldm.w	r3, {r0, r1, r2}
	add	r3, sp, #0xc
	stm.w	r3, {r0, r1, r2}
	mov	r0, r10
	ldr	r1, [sp, #0x28]
	bl	fn_08043046
	stm.w	sp, {r0, r1, r2}
	sub.w	r0, r0, #0x2000
	subs	r0, #0x1f
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0xc]
	cmp	r5, #0x0
	ble.n	.L08007a62
	movw	r1, #0x201f
	mov	r2, r9
	add	r0, r1
	movs	r3, #0x0
	add	r1, sp, #0xc
	str	r0, [sp, #0xc]
	mov	r0, sp
	bl	fn_08043540
	b.n	.L08007a76
.L08007a62:
	sub.w	r0, r0, #0x2000
	mov	r2, r9
	subs	r0, #0x1f
	movs	r3, #0x0
	add	r1, sp, #0xc
	str	r0, [sp, #0xc]
	mov	r0, sp
	bl	fn_0804356a
.L08007a76:
	stm.w	sp, {r0, r1, r2}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	beq.n	.L08007a88
	mov.w	r0, #0xffffffff
	lsrs	r1, r0, #0x1
	b.n	.L08007a8a
.L08007a88:
	mov	r0, r2
.L08007a8a:
	cmp.w	r8, #0x0
	beq.n	.L08007a98
	movs	r2, #0x0
	str	r2, [sp, #0x0]
	mov	r5, r2
	b.n	.L08007ad6
.L08007a98:
	subs	r5, r6, #0x1
	bmi.n	.L08007aa8
.L08007a9c:
	bl	div10_u64
	adds	r2, #0x30
	strb	r2, [r4, r5]
	.inst.n	0x1e6d		@ subs r5, r5, #1
	bpl.n	.L08007a9c
.L08007aa8:
	mov	r11, r6
	movs	r2, #0x1
	orrs	r0, r1
	beq.n	.L08007ab6
	movs	r2, #0x0
	.inst.n	0x1c7f		@ adds r7, r7, #1
	b.n	.L08007ac0
.L08007ab6:
	ldrb	r0, [r4, #0x0]
	cmp	r0, #0x30
	bne.n	.L08007ac0
	movs	r2, #0x0
	.inst.n	0x1e7f		@ subs r7, r7, #1
.L08007ac0:
	cmp	r2, #0x0
	str	r7, [sp, #0x24]
	beq.n	.L080079d0
	b.n	.L08007b04
.L08007ac8:
	cmp	r5, #0x11
	bge.n	.L08007adc
	bl	div10_u64
	adds	r2, #0x30
	strb	r2, [r4, r5]
	.inst.n	0x1c6d		@ adds r5, r5, #1
.L08007ad6:
	orrs.w	r2, r0, r1
	bne.n	.L08007ac8
.L08007adc:
	orrs	r0, r1
	beq.n	.L08007ae6
	ldr	r0, [sp, #0x0]
	cbz	r0, .L08007b18
	b.n	.L08007b04
.L08007ae6:
	movs	r1, #0x0
	subs	r0, r5, #0x1
	b.n	.L08007af8
.L08007aec:
	ldrb	r3, [r4, r0]
	ldrb	r2, [r4, r1]
	strb	r3, [r4, r1]
	strb	r2, [r4, r0]
	.inst.n	0x1e40		@ subs r0, r0, #1
	.inst.n	0x1c49		@ adds r1, r1, #1
.L08007af8:
	cmp	r1, r0
	blt.n	.L08007aec
	mov	r11, r5
	subs	r0, r5, r6
	.inst.n	0x1e40		@ subs r0, r0, #1
	str	r0, [sp, #0x24]
.L08007b04:
	movs	r0, #0x0
	strb.w	r0, [r4, r11]
	ldr	r0, [sp, #0x2c]
	ldr	r2, [sp, #0x24]
	str.w	r8, [r0, #0x8]
	strd	r2, r11, [r0, #0x0]
	b.n	.L08007a0e
.L08007b18:
	movs	r6, #0x11
	mov.w	r8, #0x0
	b.n	.L080079d0

@ ----------------------------------------------------------------------------
@ format_float_efg - format a double for the conversions e, f, g (r1 = 0x65,
@ 0x66, 0x67).
@ r0 = format context, r1 = conversion character, r2 = pointer to the argument
@ slot (rounded up to 8 bytes: adds #7, bic #7 at 0x08007b28/0x08007b2a; the
@ double is loaded with ldrd r0,r1 = low,high and stored at sp+0x28). Always
@ returns r0 = 3 (movs r0,#3 at 0x08007d86).
@ Class by classify_double (080437d8): class 3 or class >= 7 (inf/nan) calls
@ fn_0800839c (context, conversion character, class, sign character) and jumps
@ to 0x08007d86. Sign character r3: '-' (0x2d) when the high word bit31 is set,
@ '+' (0x2b) when flag bit1, ' ' when flag bit2 ((flags & 4) << 3 = 0x20), else
@ 0 (kept at sp+0x24).
@ Precision p = context[7] when flag bit5 is set, else 6. 'e': calls
@ fn_08007970 (sp+0x30 result record: decimal exponent, digit count, mode;
@ sp+4 digit buffer; r2 = sp+0x28; r3 = min(p+1, 17); mode 0). 'f':
@ fn_08007970 with r3 = p, mode 1; digit count and padding are computed from
@ the record (0x08007bba..0x08007bf2). 'g': p = max(p,1), digits = min(p,17),
@ mode 0, trailing zeros stripped when flag bit3 is clear (0x08007c24..
@ 0x08007c52), switches to the exponent form when exponent >= p or < -4
@ (0x08007c40..0x08007c48).
@ Exponent suffix (0x08007c7e..0x08007cd4): 'e' or 'E' (flag bit11), sign, at
@ least 2 decimal digits by repeated sdiv by 10, built backwards in the buffer
@ ending at sp+0x43.
@ Output: remaining width context[6] is reduced by the field length,
@ fn_080073e0 pads (flag bit4 clear), sign, fn_080073e0 again (flag bit4 set),
@ digits and zeros through blx context[1](char, context[2]) with the
@ decimal-point character taken from [[0x2000126c] + [[0x2000126c]]] after
@ fn_08008300 (returns 0x20001260; word at +0xc at 0x08007d48..0x08007d50) at
@ the digit position, the exponent suffix, then fn_0800740c. Counter
@ context[8] incremented per character.
@ Exit: add sp,#68 and b fn_08007a10 (shared epilogue pop {r4-r11,pc}).
@ Entered by b.w at 0x0804615c (branch island), which is reached by beq.w at
@ 0x08007246 (r1 == 0x66), 0x0800724c (0x65), 0x08007252 (0x67) in
@ format_one_conversion 08007238. Entry state: lr = caller of
@ format_one_conversion, nothing pushed yet.
@ ----------------------------------------------------------------------------
	.section .text.format_float_efg,"ax",%progbits
	.global format_float_efg
	.thumb_func
	.type format_float_efg, %function
format_float_efg:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	mov	r8, r1			@ conversion character
	mov	r4, r0			@ context
	.inst.n	0x1dd2		@ adds r2, r2, #7
	bic	r1, r2, #0x7		@ align slot to 8
	sub	sp, #0x44
	ldrd	r0, r1, [r1, #0x0]
	strd	r0, r1, [sp, #0x28]	@ the double
	bl	classify_double
	mov	r2, r0			@ class
	ldr	r0, [sp, #0x2c]
	lsrs	r0, r0, #0x1f		@ sign bit
	beq.n	.L08007b48
	movs	r0, #0x2d
	b.n	.L08007b58
.L08007b48:
	ldr	r0, [r4, #0x0]
	lsls	r1, r0, #0x1e		@ flag bit1
	bpl.n	.L08007b52
	movs	r0, #0x2b
	b.n	.L08007b58
.L08007b52:
	movs	r1, #0x20
	and.w	r0, r1, r0, lsl #0x3	@ ' ' when flag bit2
.L08007b58:
	cmp	r2, #0x3
	str	r0, [sp, #0x24]		@ sign character
	beq.n	.L08007b62
	cmp	r2, #0x7
	blt.n	.L08007b6e
.L08007b62:
	mov	r3, r0
	mov	r1, r8
	mov	r0, r4
	bl	fn_0800839c		@ inf / nan text
	b.n	.L08007d86
.L08007b6e:
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1a		@ flag bit5 (precision given)
	bpl.n	.L08007b78
	ldr	r0, [r4, #0x1c]
	b.n	.L08007b7a
.L08007b78:
	movs	r0, #0x6		@ default precision
.L08007b7a:
	cmp.w	r8, #0x65
	mov	r9, r0			@ precision p
	beq.n	.L08007b90
	cmp.w	r8, #0x66
	beq.n	.L08007bba
	cmp.w	r8, #0x67
	bne.n	.L08007c70
	b.n	.L08007bf4
.L08007b90:
	movs	r0, #0x0
	cmp.w	r9, #0x11
	str	r0, [sp, #0x0]		@ mode 0
	blt.n	.L08007b9e
	movs	r3, #0x11
	b.n	.L08007ba2
.L08007b9e:
	add.w	r3, r9, #0x1
.L08007ba2:
	add	r2, sp, #0x28
	add	r1, sp, #0x4
	add	r0, sp, #0x30
	bl	fn_08007970
	ldrd	r7, r0, [sp, #0x30]
	movs	r6, #0x0
	add.w	r5, r9, #0x1
	mov	r11, r0
	b.n	.L08007c4a
.L08007bba:
	movs	r0, #0x1
	mov	r3, r9
	str	r0, [sp, #0x0]		@ mode 1
	mov.w	r7, #0x80000000
	add	r2, sp, #0x28
	add	r1, sp, #0x4
	add	r0, sp, #0x30
	bl	fn_08007970
	ldrd	r11, r0, [sp, #0x34]
	ldr	r1, [sp, #0x30]
	mov	r5, r11
	movs	r6, #0x0
	cbnz	r0, .L08007be0
	add.w	r0, r9, #0x1
	adds	r5, r1, r0
.L08007be0:
	subs.w	r0, r9, r5
	bmi.n	.L08007bee
	rsb.w	r6, r0, #0xffffffff
	add.w	r5, r9, #0x1
.L08007bee:
	sub.w	r0, r5, r9
	b.n	.L08007c4c
.L08007bf4:
	cmp.w	r9, #0x1
	bge.n	.L08007bfe
	mov.w	r9, #0x1
.L08007bfe:
	movs	r0, #0x0
	cmp.w	r9, #0x11
	str	r0, [sp, #0x0]		@ mode 0
	mov	r0, r9
	ble.n	.L08007c0e
	movs	r3, #0x11
	b.n	.L08007c10
.L08007c0e:
	mov	r3, r0
.L08007c10:
	add	r2, sp, #0x28
	add	r1, sp, #0x4
	add	r0, sp, #0x30
	bl	fn_08007970
	ldrd	r7, r0, [sp, #0x30]
	mov	r5, r9
	movs	r6, #0x0
	mov	r11, r0
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1c		@ flag bit3 ('#')
	bmi.n	.L08007c40
	cmp	r11, r5
	bge.n	.L08007c30
	mov	r5, r11
.L08007c30:
	add	r0, sp, #0x4
.L08007c32:
	cmp	r5, #0x1
	ble.n	.L08007c40
	adds	r1, r0, r5
	ldrb.w	r1, [r1, #-0x1]
	cmp	r1, #0x30
	beq.n	.L08007c50
.L08007c40:
	cmp	r7, r9
	bge.n	.L08007c4a
	cmn.w	r7, #0x4
	bge.n	.L08007c54
.L08007c4a:
	movs	r0, #0x1
.L08007c4c:
	mov	r10, r0
	b.n	.L08007c70
.L08007c50:
	.inst.n	0x1e6d		@ subs r5, r5, #1
	b.n	.L08007c32
.L08007c54:
	cmp	r7, #0x0
	bgt.n	.L08007c5e
	subs	r5, r5, r7
	add	r6, r7
	b.n	.L08007c66
.L08007c5e:
	adds	r0, r7, #0x1
	cmp	r0, r5
	ble.n	.L08007c66
	adds	r5, r7, #0x1
.L08007c66:
	subs	r0, r7, r6
	add.w	r10, r0, #0x1
	mov.w	r7, #0x80000000
.L08007c70:
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1c		@ flag bit3
	bmi.n	.L08007c7e
	cmp	r10, r5
	blt.n	.L08007c7e
	mov.w	r10, #0xffffffff
.L08007c7e:
	movs	r1, #0x0
	cmp.w	r7, #0x80000000
	add.w	r8, sp, #0x43
	strb.w	r1, [sp, #0x43]		@ exponent text terminator
	beq.n	.L08007cd8
	movs	r0, #0x2
	movs	r3, #0x2b
	cmp	r7, #0x0
	bge.n	.L08007c9a
	rsbs	r7, r7, #0x0
	movs	r3, #0x2d
.L08007c9a:
	movs	r1, #0xa
.L08007c9c:
	subs	r2, r0, #0x0
	sub.w	r0, r0, #0x1
	bgt.n	.L08007ca6
	cbz	r7, .L08007cbe
.L08007ca6:
	sdiv	r12, r7, r1
	sdiv	r2, r7, r1
	mls	r12, r1, r12, r7
	mov	r7, r2
	add.w	r12, r12, #0x30
	strb.w	r12, [r8, #-0x1]!	@ exponent digit, built backwards
	b.n	.L08007c9c
.L08007cbe:
	sub.w	r0, r8, #0x1
	strb	r3, [r0, #0x0]		@ exponent sign
	ldrh	r1, [r4, #0x0]
	lsls	r1, r1, #0x14		@ flag bit11 (upper case)
	bpl.n	.L08007cce
	movs	r1, #0x45
	b.n	.L08007cd0
.L08007cce:
	movs	r1, #0x65
.L08007cd0:
	sub.w	r8, r0, #0x1
	strb.w	r1, [r0, #-0x1]		@ 'E' / 'e'
.L08007cd8:
	ldr	r0, [sp, #0x24]
	add	r1, sp, #0x3c
	sub.w	r7, r1, r8
	.inst.n	0x1dff		@ adds r7, r7, #7		@ exponent suffix length
	cbz	r0, .L08007ce6
	movs	r0, #0x1
.L08007ce6:
	adds	r1, r0, r5
	add.w	r0, r1, r10, asr #0x1f
	ldr	r1, [r4, #0x18]
	add	r0, r7
	subs	r0, r1, r0
	.inst.n	0x1e40		@ subs r0, r0, #1
	str	r0, [r4, #0x18]		@ width -= field length
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1b		@ flag bit4
	bmi.n	.L08007d02
	mov	r0, r4
	bl	fn_080073e0
.L08007d02:
	ldr	r0, [sp, #0x24]
	cbz	r0, .L08007d12
	ldrd	r2, r1, [r4, #0x4]
	blx	r2			@ sign character
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
.L08007d12:
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1b		@ flag bit4
	bpl.n	.L08007d5e
	mov	r0, r4
	bl	fn_080073e0
	b.n	.L08007d5e
.L08007d20:
	cmp	r6, #0x0
	blt.n	.L08007d2e
	cmp	r11, r6
	ble.n	.L08007d2e
	add	r0, sp, #0x4
	ldrb	r0, [r0, r6]		@ digit
	b.n	.L08007d30
.L08007d2e:
	movs	r0, #0x30		@ zero fill
.L08007d30:
	ldrd	r2, r1, [r4, #0x4]
	blx	r2
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
	.inst.n	0x1c76		@ adds r6, r6, #1
	sub.w	r0, r10, #0x1
	movs.w	r10, r0
	bne.n	.L08007d5e
	bl	fn_08008300
	ldr	r0, [r0, #0xc]
	ldr	r1, [r0, #0x0]
	ldrb	r0, [r0, r1]		@ decimal point character
	ldrd	r2, r1, [r4, #0x4]
	blx	r2
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
.L08007d5e:
	subs	r0, r5, #0x0
	sub.w	r5, r5, #0x1
	bgt.n	.L08007d20
	b.n	.L08007d78
.L08007d68:
	ldrd	r2, r1, [r4, #0x4]
	ldrb.w	r0, [r8], #0x1		@ exponent suffix character
	blx	r2
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
.L08007d78:
	subs	r0, r7, #0x0
	sub.w	r7, r7, #0x1
	bgt.n	.L08007d68
	mov	r0, r4
	bl	fn_0800740c
.L08007d86:
	movs	r0, #0x3
	add	sp, #0x44
	b.n	fn_08007a10

@ ----------------------------------------------------------------------------
@ format_float_hex - format a double in hexadecimal floating form for
@ conversion 'a' (r1 = 0x61).
@ r0 = format context, r1 = conversion character, r2 = pointer to the argument
@ slot (8-byte aligned by adds #7 / bic #7 at 0x08007d94/0x08007d96; low word
@ r9, high word r7). Always returns r0 = 3 (0x08008064).
@ Sign character (stored at sp+0x20) as in format_float_efg: '-' when the high
@ word bit31 is set, '+' for flag bit1, ' ' for flag bit2, else none. Class by
@ classify_double (080437d8): class 3 or >= 7 calls fn_0800839c with r0 =
@ context, r1 = conversion character, r2 = class, r3 = sign character (the asm
@ at 0x08007dd8..0x08007ddc passes r2 and r3 unchanged) and jumps to
@ 0x08008062.
@ Precision p = context[7] when flag bit5 is set, else 13 (0x0d). Strings:
@ lower case '0123456789abcdefxp' at 0x08046458, upper case
@ '0123456789ABCDEFXP' at 0x0804646b (flag bit11 selects). Output text is '0x'
@ ('0X'), leading digit '0' (biased exponent 0) or '1', '.' when p > 0 or flag
@ bit3, 5 hex digits from the high word mantissa (loop limit 5), 8 hex digits
@ from the low word (limit 8), trailing zeros stripped when flag bit5 is clear,
@ a '>' marker stored after the 13 digits when p is still above 0
@ (0x08007f66..0x08007f72: strb '>' then subs r5,#1), so p drops once more; at
@ output (0x08008042..0x08008048 and 0x0800806a..0x0800807e) the marker itself
@ is not written, context[8] is increased by the decremented p and p-14 '0'
@ characters are written (p = 14 writes none); the field-width sum at
@ 0x08007ffe counts the marker as one character, then 'p'/'P', sign, and the
@ unbiased exponent in 1..4 decimal digits (divisors 1000, 100, 10,
@ 0x08007fb6..0x08007fea); exponent for a zero exponent field is 0 for zero and
@ -1022 (0xfffffc02 at 0x08008084) for denormals.
@ When p < 13 (cmp r5,#13 / bge at 0x08007df2/0x08007df4) the mantissa is
@ rounded to p hex digits (0x08007e24..0x08007e88) with the rounding mode fixed
@ to nearest (the value tested at 0x08007e1a is the constant 0): r3:r2 is the
@ mask of the lowest kept bit; the remainder r0 is r9 << (4p+12-32) for p >= 5
@ but r7 << (4p+12) for p < 5 (0x08007e4a..0x08007e5a), so for p < 5 the low
@ word r9 is not part of the remainder test; a remainder equal to 0x80000000
@ clears the lowest kept bit again (bics r7,r3 / bic r9,r9,r2 at
@ 0x08007e7c/0x08007e7e), which gives round-half-to-even for p >= 5.
@ Unreachable blocks kept from the original: 0x08007e20 (r1 is always 0 there),
@ 0x08007e66 (r1 is 0 there, ble always taken), 0x08007e68 (entered only by
@ fall-through of the cbnz at 0x08007e66); so the round-up (adds r9,r2 / adcs
@ r7,r3 at 0x08007e70/0x08007e74) runs whenever the remainder r0 >= 0x80000000
@ (cmp r0,r8 / bcc at 0x08007e6c/0x08007e6e).
@ Output: context[6] reduced by field length, fn_080073e0 padding (flag bit4
@ clear), sign/prefix characters (context[8] += count), fn_080073e0 again (flag
@ bit4 set), body characters through blx context[1](char, context[2]),
@ fn_0800740c. Exit: add sp,#36; movs r0,#3; pop {r4-r11,pc} at
@ 0x08008062..0x08008066.
@ Entered by b.w at 0x08046160 (branch island) reached by beq.w at 0x08007258
@ (r1 == 0x61) in format_one_conversion 08007238. Entry state: r0..r2 as above,
@ lr = caller of format_one_conversion.
@ ----------------------------------------------------------------------------
	.section .text.format_float_hex,"ax",%progbits
	.p2align 2
	.global format_float_hex
	.thumb_func
	.type format_float_hex, %function
format_float_hex:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	mov	r4, r0			@ context
	mov	r5, r1			@ conversion character
	.inst.n	0x1dd2		@ adds r2, r2, #7
	bic	r0, r2, #0x7		@ align slot to 8
	sub	sp, #0x24
	ldrd	r9, r7, [r0, #0x0]	@ double: low r9, high r7
	mov	r0, r9
	mov	r1, r7
	bl	classify_double
	mov	r2, r0			@ class
	lsrs	r0, r7, #0x1f		@ sign bit
	beq.n	.L08007db2
	movs	r3, #0x2d
	b.n	.L08007dc2
.L08007db2:
	ldr	r0, [r4, #0x0]
	lsls	r1, r0, #0x1e		@ flag bit1
	bpl.n	.L08007dbc
	movs	r3, #0x2b
	b.n	.L08007dc2
.L08007dbc:
	movs	r1, #0x20
	and.w	r3, r1, r0, lsl #0x3	@ ' ' when flag bit2
.L08007dc2:
	strb.w	r3, [sp, #0x20]		@ sign character
	cbz	r3, .L08007dcc
	movs	r0, #0x1
	b.n	.L08007dce
.L08007dcc:
	movs	r0, #0x0
.L08007dce:
	cmp	r2, #0x3
	mov	r10, r0			@ sign length (0 or 1)
	beq.n	.L08007dd8
	cmp	r2, #0x7
	blt.n	.L08007de2
.L08007dd8:
	mov	r1, r5
	mov	r0, r4
	bl	fn_0800839c		@ inf / nan text
	b.n	.L08008062
.L08007de2:
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1a		@ flag bit5 (precision given)
	bmi.n	.L08007dec
	movs	r5, #0xd		@ default precision 13
	b.n	.L08007dee
.L08007dec:
	ldr	r5, [r4, #0x1c]
.L08007dee:
	ubfx	r6, r7, #0x14, #0xb	@ biased exponent
	cmp	r5, #0xd
	bge.n	.L08007e8a
	movs	r1, #0x0
	lsr.w	r11, r7, #0x14
	mov	r0, r1
	mov.w	r0, #0x0
	cmp	r7, #0x0
	and	r0, r0, #0xc00000
	bge.n	.L08007e1a
	add.w	r0, r0, r0, lsl #0x2
	mov.w	r1, #0xc00000
	add.w	r0, r0, r0, lsr #0x1f
	and.w	r0, r1, r0, asr #0x1
.L08007e1a:
	asrs	r1, r0, #0x16
	cmp	r1, #0x1
	ble.n	.L08007e24
	mov.w	r1, #0xffffffff
.L08007e24:
	movs	r2, #0x0
	lsl.w	r12, r5, #0x2
	cmp.w	r12, #0x18
	bcc.n	.L08007e3e
	mov	r3, r2
	sub.w	r0, r12, #0x18
	mov.w	r2, #0x10000000
	lsrs	r2, r0
	b.n	.L08007e46
.L08007e3e:
	mov.w	r3, #0x100000
	lsr.w	r3, r3, r12
.L08007e46:
	add.w	r12, r12, #0xc
	cmp.w	r12, #0x20
	bcc.n	.L08007e5a
	sub.w	r12, r12, #0x20
	lsl.w	r0, r9, r12
	b.n	.L08007e5e
.L08007e5a:
	lsl.w	r0, r7, r12
.L08007e5e:
	cmp	r1, #0x0
	mov.w	r8, #0x80000000
	ble.n	.L08007e6a
	cbnz	r0, .L08007e70
	b.n	.L08007e8a
.L08007e6a:
	bne.n	.L08007e8a
	cmp	r0, r8
	bcc.n	.L08007e8a
.L08007e70:
	adds.w	r9, r9, r2
	adcs	r7, r3
	cbnz	r1, .L08007e82
	cmp	r0, r8
	bne.n	.L08007e82
	bics	r7, r3
	bic.w	r9, r9, r2
.L08007e82:
	cmp.w	r11, r7, lsr #0x14
	beq.n	.L08007e8a
	.inst.n	0x1c76		@ adds r6, r6, #1
.L08007e8a:
	ldrh	r0, [r4, #0x0]
	lsls	r0, r0, #0x14		@ flag bit11 (upper case)
	bpl.n	.L08007e96
	ldr	r0, .L08008080
	add	r0, pc			@ upper case digit string
	b.n	.L08007e9c
.L08007e96:
	ldr	r0, .L08008080
.L08007e98:
	add	r0, pc
	subs	r0, #0x19		@ lower case digit string
.L08007e9c:
	add	r2, sp, #0x20		@ output text buffer starts with the sign
	movs	r3, #0x30
	strb.w	r3, [r2, r10]		@ '0'
	ldrb	r3, [r0, #0x10]		@ 'x' / 'X'
	add.w	r1, r10, #0x1
	cmp	r6, #0x0
	add.w	r10, r10, #0x2
	strb	r3, [r2, r1]
	mov	r2, sp			@ mantissa text buffer
	bgt.n	.L08007ebc
	mov.w	r1, #0x30
	b.n	.L08007ec0
.L08007ebc:
	mov.w	r1, #0x31
.L08007ec0:
	mov.w	r8, #0x1
	strb.w	r1, [sp, #0x0]		@ leading digit
	beq.n	.L08007ed0
	subw	r6, r6, #0x3ff		@ unbias exponent
	b.n	.L08007ed8
.L08007ed0:
	orrs.w	r1, r9, r7, lsl #0x1
	beq.n	.L08007ed8
	ldr	r6, .L08008084		@ denormal exponent -1022
.L08007ed8:
	cmp	r5, #0x0
	bgt.n	.L08007ee2
	ldrb	r1, [r4, #0x0]
	lsls	r1, r1, #0x1c		@ flag bit3
	bpl.n	.L08007eec
.L08007ee2:
	mov.w	r8, #0x2
	movs	r1, #0x2e		@ '.'
	strb.w	r1, [sp, #0x1]
.L08007eec:
	mov	r12, r8
	movs	r1, #0x0
	b.n	.L08007f0a
.L08007ef2:
	ubfx	r3, r7, #0x10, #0x4	@ next hex digit of the high word mantissa
	lsls	r7, r7, #0x4
	ldrb	r3, [r0, r3]
	.inst.n	0x1c49		@ adds r1, r1, #1
	.inst.n	0x1e6d		@ subs r5, r5, #1
	strb.w	r3, [r2, r8]
	cmp	r1, #0x5
	add.w	r8, r8, #0x1
	bge.n	.L08007f0e
.L08007f0a:
	cmp	r5, #0x0
	bgt.n	.L08007ef2
.L08007f0e:
	movs	r1, #0x0
	b.n	.L08007f2c
.L08007f12:
	add.w	r3, r0, r9, lsr #0x1c	@ next hex digit of the low word
	.inst.n	0x1c49		@ adds r1, r1, #1
	ldrb	r3, [r3, #0x0]
	.inst.n	0x1e6d		@ subs r5, r5, #1
	cmp	r1, #0x8
	strb.w	r3, [r2, r8]
	lsl.w	r9, r9, #0x4
	add.w	r8, r8, #0x1
	bge.n	.L08007f30
.L08007f2c:
	cmp	r5, #0x0
	bgt.n	.L08007f12
.L08007f30:
	ldr	r1, [r4, #0x0]
	lsls	r3, r1, #0x1a		@ flag bit5
	bpl.n	.L08007f3c
	b.n	.L08007f66
.L08007f38:
	sub.w	r8, r8, #0x1
.L08007f3c:
	cmp	r8, r12
	ble.n	.L08007f4c
	add.w	r3, r2, r8
	ldrb.w	r3, [r3, #-0x1]
	cmp	r3, #0x30
	beq.n	.L08007f38		@ strip trailing zero
.L08007f4c:
	cmp.w	r8, #0x0
	ble.n	.L08007f66
	add.w	r3, r2, r8
	ldrb.w	r3, [r3, #-0x1]
	cmp	r3, #0x2e
	bne.n	.L08007f66
	lsls	r1, r1, #0x1c		@ flag bit3
	bmi.n	.L08007f66
	sub.w	r8, r8, #0x1		@ drop a trailing '.'
.L08007f66:
	cmp	r5, #0x0
	ble.n	.L08007f76
	movs	r1, #0x3e		@ '>' marker
	strb.w	r1, [r2, r8]
	.inst.n	0x1e6d		@ subs r5, r5, #1
	add.w	r8, r8, #0x1
.L08007f76:
	ldrb	r0, [r0, #0x11]		@ 'p' / 'P'
	cmp	r6, #0x0
	strb.w	r0, [r2, r8]
	add.w	r8, r8, #0x1
	bge.n	.L08007f8e
	movs	r0, #0x2d
	rsbs	r6, r6, #0x0
	strb.w	r0, [r2, r8]
	b.n	.L08007f94
.L08007f8e:
	movs	r0, #0x2b
	strb.w	r0, [r2, r8]
.L08007f94:
	movs	r1, #0xa
	mov.w	r0, #0x3e8
	cmp	r6, r0
	add.w	r8, r8, #0x1
	blt.n	.L08007fba
	sdiv	r3, r6, r0
	adds	r3, #0x30
	strb.w	r3, [r2, r8]
	sdiv	r3, r6, r0
	add.w	r8, r8, #0x1
	mls	r6, r0, r3, r6
	b.n	.L08007fbe
.L08007fba:
	cmp	r6, #0x64
	blt.n	.L08007fd8
.L08007fbe:
	movs	r0, #0x64
	sdiv	r3, r6, r0
	adds	r3, #0x30
	strb.w	r3, [r2, r8]
	sdiv	r3, r6, r0
	add.w	r8, r8, #0x1
	mls	r6, r0, r3, r6
	b.n	.L08007fdc
.L08007fd8:
	cmp	r6, #0xa
	blt.n	.L08007fea
.L08007fdc:
	sdiv	r0, r6, r1
	adds	r0, #0x30
	strb.w	r0, [r2, r8]
	add.w	r8, r8, #0x1
.L08007fea:
	sdiv	r0, r6, r1
	mls	r0, r1, r0, r6
	adds	r0, #0x30
	strb.w	r0, [r2, r8]
	ldr	r1, [r4, #0x18]
	add.w	r8, r8, #0x1
	add.w	r2, r8, r5
	add.w	r0, r2, r10
	subs	r0, r1, r0
	str	r0, [r4, #0x18]		@ width -= field length
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1b		@ flag bit4
	bmi.n	.L08008016
	mov	r0, r4
	bl	fn_080073e0
.L08008016:
	ldr	r1, [r4, #0x20]
	add	r6, sp, #0x20
	add.w	r0, r1, r10
	str	r0, [r4, #0x20]		@ counter += sign / prefix characters
	b.n	.L0800802c
.L08008022:
	ldrd	r2, r1, [r4, #0x4]
	ldrb.w	r0, [r6], #0x1		@ sign / prefix character
	blx	r2
.L0800802c:
	subs.w	r10, r10, #0x1
	bcs.n	.L08008022
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1b		@ flag bit4
	bpl.n	.L0800803e
	mov	r0, r4
	bl	fn_080073e0
.L0800803e:
	mov	r6, sp
	b.n	.L08008056
.L08008042:
	ldrb.w	r0, [r6], #0x1
	cmp	r0, #0x3e
	beq.n	.L0800806a		@ '>' marker: emit zero fill instead
	ldrd	r2, r1, [r4, #0x4]
	blx	r2
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
.L08008056:
	subs.w	r8, r8, #0x1
	bcs.n	.L08008042
	mov	r0, r4
	bl	fn_0800740c
.L08008062:
	add	sp, #0x24
	movs	r0, #0x3
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0800806a:
	ldr	r0, [r4, #0x20]
	add	r0, r5
	str	r0, [r4, #0x20]
	b.n	.L0800807a
.L08008072:
	ldrd	r2, r1, [r4, #0x4]
	movs	r0, #0x30
	blx	r2
.L0800807a:
	.inst.n	0x1e6d		@ subs r5, r5, #1
	bcc.n	.L08008056
	b.n	.L08008072
.L08008080:
	.word	d_08046470+1 - (.L08007e98 + 4)
.L08008084:
	.word	0xfffffc02		@ -1022

@ ----------------------------------------------------------------------------
@ read_byte_advance - get-next-format-character callback.
@ r0 = context pointer; returns the byte at the pointer stored at [r0+0x10] and
@ stores that pointer plus 1 back to [r0+0x10]. 08008092 stores 0x08008089
@ (this entry, Thumb bit set) into context word 3 and the format string
@ pointer into word 4 (+0x10), and fn_080075b4 calls context[3](context).
@ ----------------------------------------------------------------------------
	.section .text.read_byte_advance,"ax",%progbits
	.global read_byte_advance
	.thumb_func
	.type read_byte_advance, %function
read_byte_advance:
	ldr	r1, [r0, #0x10]
	adds	r2, r1, #0x1
	str	r2, [r0, #0x10]
	ldrb	r0, [r1, #0x0]
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08008092 - format front end that builds a context on the stack.
@ r0 = format string, r1 = output state, r2 = argument list pointer, r3 =
@ put-byte callback; builds a context on the stack: word 1 (+4) = r3 put
@ callback, word 2 (+8) = r1 put argument, word 3 (+0xc) = 0x08008089 (function
@ pointer to read_byte_advance, reads the next format character), word 4
@ (+0x10) = r0 format pointer, word 5 = 0; then calls fn_080075b4(context, r2)
@ and returns its count. Callers: 08007370 and 080073b4 (r3 = 0x080080b9) and
@ 080080f0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08008092,"ax",%progbits
	.global fn_08008092
	.thumb_func
	.type fn_08008092, %function
fn_08008092:
	push	{lr}
	sub	sp, #0x3c
	strd	r3, r1, [sp, #0x4]
	movs	r1, #0x0
	str	r1, [sp, #0x14]
	.inst.n	0x4905			@ ldr r1, [pc, #0x14] = word at .L080080b4 (unit starts at an address = 2 mod 4, GAS cannot place the literal word-aligned from the section start)
.L080080a0:
	add	r1, pc			@ r1 = read_byte_advance
	strd	r1, r0, [sp, #0xc]
	mov	r1, r2
	mov	r0, sp
	bl	fn_080075b4
	add	sp, #0x3c
	pop	{pc}
	.short	0x0000			@ padding
.L080080b4:
	.word	read_byte_advance - (.L080080a0 + 4)

@ ----------------------------------------------------------------------------
@ store_byte_advance - put-byte callback that writes into a buffer.
@ r0 = byte, r1 = pointer to a pointer; stores the byte at the pointed-to
@ address and increments the stored pointer by 1.
@ ----------------------------------------------------------------------------
	.section .text.store_byte_advance,"ax",%progbits
	.global store_byte_advance
	.thumb_func
	.type store_byte_advance, %function
store_byte_advance:
	ldr	r2, [r1, #0x0]
	strb.w	r0, [r2], #0x1
	str	r2, [r1, #0x0]
	bx	lr

@ ----------------------------------------------------------------------------
@ emit_text_conversion - common tail of the 'c' and 's' conversions.
@ r0 = format context, r1 = text pointer, r2 = length (1 for one character, -1
@ for a NUL-terminated string); returns r0 = 1 in every case.
@ Code: push {r4,lr}; r3 = context[5] (0x080080c4); when r3 == 0 it calls
@ fn_0800742e (text emitter: r0 = context, r1 = text, r2 = length) at
@ 0x080080ce, when r3 != 0 the cbz is not taken and the path is nop.w at
@ 0x080080c8 then b.n 0x080080d2, so nothing is emitted; the meaning of the
@ context[5] flag is not determined from the code. Then movs r0,#1 and pop
@ {r4,pc}.
@ Entered by: b.n at 0x080080e4 (block 0x080080d6, 'c': stores the byte [r2] at
@ context+0x24, a 0 at +0x25, r1 = context+0x24, r2 = 1) and b.n at 0x080080ec
@ (block 0x080080e6, 's': r1 = word [r2], r2 = 0xffffffff); both blocks are
@ reached from beq.w at 0x080072ae (r1 == 0x63) and 0x080072b4 (r1 == 0x73) in
@ format_one_conversion 08007238. Entry state: lr = the conversion handler's
@ caller.
@ ----------------------------------------------------------------------------
	.section .text.emit_text_conversion,"ax",%progbits
	.global emit_text_conversion
	.thumb_func
	.type emit_text_conversion, %function
emit_text_conversion:
	push	{r4, lr}
	ldr	r3, [r0, #0x14]
	cbz	r3, .L080080ce
	nop.w
	b.n	.L080080d2
.L080080ce:
	bl	fn_0800742e
.L080080d2:
	movs	r0, #0x1
	pop	{r4, pc}
	.global	L_080080d6		@ entered from format_one_conversion (startup_56)
	.thumb_func
L_080080d6:
.L080080d6:
	ldrb	r2, [r2, #0x0]
	add.w	r1, r0, #0x24
	strb	r2, [r1, #0x0]
	movs	r2, #0x0
	strb	r2, [r1, #0x1]
	movs	r2, #0x1
	b.n	emit_text_conversion
	.global	L_080080e6		@ entered from format_one_conversion (startup_56)
	.thumb_func
L_080080e6:
.L080080e6:
	ldr	r1, [r2, #0x0]
	mov.w	r2, #0xffffffff
	b.n	emit_text_conversion
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_080080f0 - formatted output to a stream object.
@ r0 = format string, r1 = stream object; calls fn_08008092 and then
@ fn_0800852c(r1); returns the fn_08008092 result when fn_0800852c returns 0,
@ else 0xffffffff. r3 = 0x08036BA5 before the call to fn_08008092: ldr r3,[pc]
@ at 0x080080F0 loads 0x0002EAAB from 0x08008110 and add r3,pc at 0x080080F6
@ adds 0x080080FA, i.e. the address of the character output routine 08036ba4.
@ ----------------------------------------------------------------------------
	.section .text.fn_080080f0,"ax",%progbits
	.p2align 2
	.global fn_080080f0
	.thumb_func
	.type fn_080080f0, %function
fn_080080f0:
	ldr	r3, .L08008110
	push	{r4, r5, r6, lr}
	mov	r5, r1
.L080080f6:
	add	r3, pc			@ r3 = fn_08036ba4 (character output)
	bl	fn_08008092
	mov	r4, r0
	mov	r0, r5
	bl	fn_0800852c
	cbz	r0, .L0800810c
	mov.w	r0, #0xffffffff
	pop	{r4, r5, r6, pc}
.L0800810c:
	mov	r0, r4
	pop	{r4, r5, r6, pc}
.L08008110:
	.word	fn_08036ba4 - (.L080080f6 + 4)

@ ----------------------------------------------------------------------------
@ fn_08008114 - emit a 16-bit character array (wide string / character).
@ r0 = format context, r1 = 16-bit character array, r2 = minimum count (signed
@ compare at 08008160): the first r2 halfwords are converted whatever their
@ value, after that conversion continues only while the halfword is nonzero
@ (08008164..0800816a), so r2 = 0xffffffff means up to the first zero halfword;
@ converts each 16-bit character with fn_08008534 into bytes (scratch at
@ stack), counts output bytes against the width limit context[7] when flag bit5
@ is set, then pads via fn_080073e0, emits the bytes through callback
@ context[1], adds the length to context[8] and pads via fn_0800740c.
@ ----------------------------------------------------------------------------
	.section .text.fn_08008114,"ax",%progbits
	.global fn_08008114
	.thumb_func
	.type fn_08008114, %function
fn_08008114:
	push.w	{r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	mov	r5, r2			@ minimum count
	mov	r10, r1			@ halfword array
	mov	r4, r0			@ context
	ldr.w	r8, .L080081cc
.L08008122:
	add	r8, pc			@ r8 = table at 0x08046480
	movs	r7, #0x0		@ output byte count
	ldrd	r1, r0, [r8, #0x0]
	mov	r6, r7			@ index
	strd	r1, r0, [sp, #0x0]
	b.n	.L08008154
.L08008132:
	ldrh.w	r1, [r10, r6, lsl #0x1]
	mov	r2, sp
	add	r0, sp, #0x8
	bl	fn_08008534
	adds	r1, r0, #0x1
	beq.n	.L08008152
	ldrb	r1, [r4, #0x0]
	lsls	r1, r1, #0x1a		@ flag bit5
	bpl.n	.L08008150
	ldr	r2, [r4, #0x1c]
	adds	r1, r7, r0
	cmp	r1, r2
	bhi.n	.L0800816c
.L08008150:
	add	r7, r0
.L08008152:
	.inst.n	0x1c76		@ adds r6, r6, #1
.L08008154:
	ldrb	r0, [r4, #0x0]
	lsls	r0, r0, #0x1a		@ flag bit5
	bpl.n	.L08008160
	ldr	r0, [r4, #0x1c]
	cmp	r0, r7
	ble.n	.L0800816c
.L08008160:
	cmp	r6, r5
	blt.n	.L08008132
	ldrh.w	r0, [r10, r6, lsl #0x1]
	cmp	r0, #0x0
	bne.n	.L08008132
.L0800816c:
	ldr	r0, [r4, #0x18]
	subs	r0, r0, r7
	str	r0, [r4, #0x18]		@ width -= byte count
	mov	r0, r4
	bl	fn_080073e0
	ldrd	r1, r0, [r8, #0x0]
	strd	r1, r0, [sp, #0x0]
	movs	r0, #0x0
	b.n	.L080081b4
.L08008184:
	ldrh.w	r1, [r10, r8, lsl #0x1]
	mov	r2, sp
	add	r0, sp, #0x8
	bl	fn_08008534
	cmp.w	r0, #0xffffffff
	mov	r9, r0
	beq.n	.L080081b0
	movs	r5, #0x0
	add.w	r11, sp, #0x8
	b.n	.L080081ac
.L080081a0:
	ldrd	r2, r1, [r4, #0x4]
	ldrb.w	r0, [r11, r5]
	blx	r2
	.inst.n	0x1c6d		@ adds r5, r5, #1
.L080081ac:
	cmp	r5, r9
	bcc.n	.L080081a0
.L080081b0:
	add.w	r0, r8, #0x1
.L080081b4:
	cmp	r0, r6
	mov	r8, r0
	blt.n	.L08008184
	ldr	r0, [r4, #0x20]
	add	r0, r7
	str	r0, [r4, #0x20]		@ counter += byte count
	mov	r0, r4
	bl	fn_0800740c
	pop.w	{r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, pc}
	.short	0x0000			@ padding
.L080081cc:
	.word	d_08046480 - (.L08008122 + 4)

@ ----------------------------------------------------------------------------
@ format_decimal_64 - format one 64-bit decimal conversion.
@ r0 = format context (kept in r8), r1 = conversion character (0xe9, 0xe4 =
@ 'i','d' with the 64-bit marker; 0xf5 = 'u'), r2 = pointer to the argument
@ slot (aligned up to 8 with adds #7 / bic #7; low word r0, high word r2 via
@ ldrd r0,r2,[r2] at 0x080081de). Ends with a tail jump to
@ emit_formatted_number (returns r0 = 2 there).
@ When r1 != 0xf5: a negative value (subs / sbcs at 0x080081e8..0x080081ea) is
@ negated as 64 bit (rsbs / sbc at 0x080081f2/0x080081f6) and gets the prefix
@ '-' (0x08008240); otherwise flag bit1 gives '+' (0x08008244), flag bit2 gives
@ ' ' (0x08008248); prefix length r5 = 1; for r1 == 0xf5 and for the no-prefix
@ case the empty string at 0x0800823c with length 0.
@ Digit loop 0x0800821c..0x0800822a: div10_u64 (08008310: quotient in r0:r1,
@ remainder digit in r2), stores r2 + 0x30 at context+0x24+i until r0:r1 is 0.
@ Exit: pop {r4-r8,lr} then b.w emit_formatted_number with r0 = context, r1 =
@ digit count, r2 = prefix pointer, r3 = prefix length.
@ Entered by beq.w at 0x08007286 (r1 == 0xe9), 0x0800728c (0xe4), 0x08007292
@ (0xf5) in format_one_conversion 08007238 (r1 carries the 0x80 bit or-ed in at
@ 0x08007262 from flag bit7, which is why these are 0xe9, 0xe4, 0xf5). Entry
@ state: lr = the conversion handler's caller.
@ ----------------------------------------------------------------------------
	.section .text.format_decimal_64,"ax",%progbits
	.global format_decimal_64
	.thumb_func
	.type format_decimal_64, %function
format_decimal_64:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r8, r0			@ context
	.inst.n	0x1dd2		@ adds r2, r2, #7
	bic	r2, r2, #0x7		@ align slot to 8
	movs	r5, #0x0		@ prefix length = 0
	ldrd	r0, r2, [r2, #0x0]	@ value low r0, high r2
	cmp	r1, #0xf5
	adr	r6, .L0800823c		@ prefix = empty string
	beq.n	.L08008212
	subs	r1, r0, #0x0
	sbcs	r1, r2, #0x0		@ sign test of the 64-bit value
	bge.n	.L080081fe
	movs	r3, #0x0
	rsbs.w	r0, r0, r3		@ negate 64-bit value
	sbc.w	r2, r3, r2
	adr	r6, .L08008240		@ prefix = "-"
	b.n	.L08008210
.L080081fe:
	ldr.w	r1, [r8, #0x0]
	lsls	r3, r1, #0x1e		@ flag bit1 ('+')
	bpl.n	.L0800820a
	adr	r6, .L08008244		@ prefix = "+"
	b.n	.L08008210
.L0800820a:
	lsls	r1, r1, #0x1d		@ flag bit2 (' ')
	bpl.n	.L08008212
	adr	r6, .L08008248		@ prefix = " "
.L08008210:
	movs	r5, #0x1
.L08008212:
	mov	r1, r2
	movs	r4, #0x0		@ digit count
	add.w	r7, r8, #0x24		@ digit buffer
	b.n	.L08008226
.L0800821c:
	bl	div10_u64
	adds	r2, #0x30
	strb	r2, [r7, r4]
	.inst.n	0x1c64		@ adds r4, r4, #1
.L08008226:
	orrs.w	r2, r0, r1
	bne.n	.L0800821c
	mov	r3, r5
	mov	r2, r6
	mov	r1, r4
	mov	r0, r8
	pop.w	{r4, r5, r6, r7, r8, lr}
	b.w	emit_formatted_number
.L0800823c:
	.word	0x00000000		@ empty prefix string (and padding)
.L08008240:
	.asciz	"-"
	.short	0x0000			@ padding
.L08008244:
	.asciz	"+"
	.short	0x0000			@ padding
.L08008248:
	.asciz	" "
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ format_octal_64 - octal conversion of a 64-bit value.
@ r0 = format context, r1 = ignored (overwritten by movs r1,#0 at 0x0800824e),
@ r2 = value low word, r3 = value high word; ends with a tail jump to
@ emit_formatted_number (returns r0 = 1 or 2).
@ Loop 0x08008256..0x08008268: digit = (r2 & 7) + 0x30 stored at
@ context+0x24+i, r3:r2 shifted right by 3, until both words are 0.
@ Prefix: when flag bit3 is set and (flag bit5 is set or at least one digit
@ exists) (0x08008274..0x0800827e): prefix '0' (string 0x080082b8, length 1)
@ and context[7] (precision) is decremented by 1 (0x08008286..0x08008288);
@ otherwise the empty string at 0x080082b4 with length 0.
@ Exit: pop {r4,r5} then b.w emit_formatted_number with r0 = context, r1 =
@ digit count, r2 = prefix pointer, r3 = prefix length.
@ Entered by: b.n at 0x080082a6 (from 08008290, r3 = 0, r2 = masked 32-bit
@ value) and b.n at 0x080082b2 (block 0x080082a8, which loads the 8-byte
@ aligned slot with ldrd r2,r3 and is reached by beq.w at 0x08007298 for r1 ==
@ 0xef). Entry state: r4,r5 are pushed here; lr = the conversion handler's
@ caller.
@ ----------------------------------------------------------------------------
	.section .text.format_octal_64,"ax",%progbits
	.global format_octal_64
	.thumb_func
	.type format_octal_64, %function
format_octal_64:
	push	{r4, r5}
	movs	r1, #0x0		@ digit count
	add.w	r4, r0, #0x24		@ digit buffer
	b.n	.L08008268
.L08008256:
	and	r5, r2, #0x7
	lsrs	r2, r2, #0x3
	adds	r5, #0x30
	orr.w	r2, r2, r3, lsl #0x1d
	lsrs	r3, r3, #0x3
	strb	r5, [r4, r1]
	.inst.n	0x1c49		@ adds r1, r1, #1
.L08008268:
	orrs.w	r5, r2, r3
	bne.n	.L08008256
	ldr	r4, [r0, #0x0]
	movs	r3, #0x0		@ prefix length = 0
	.inst.n	0xa210			@ adr r2, 0x080082b4 = empty prefix string (lies in format_octal_32's section)
	lsls	r5, r4, #0x1c		@ flag bit3 ('#')
	bpl.n	.L0800828a
	and	r4, r4, #0x20
	orrs	r4, r1
	beq.n	.L0800828a
	ldr	r4, [r0, #0x1c]
	movs	r3, #0x1
	.inst.n	0xa20c			@ adr r2, 0x080082b8 = prefix string "0" (lies in format_octal_32's section)
	.inst.n	0x1e64		@ subs r4, r4, #1
	str	r4, [r0, #0x1c]		@ precision -= 1
.L0800828a:
	pop	{r4, r5}
	b.w	emit_formatted_number

@ ----------------------------------------------------------------------------
@ format_octal_32 - octal conversion of a 32-bit argument.
@ r0 = format context, r1 = conversion character (unused, overwritten by mov
@ r1,r4 at 0x08008294), r2 = pointer to the 4-byte argument slot; reads [r2],
@ masks it with fn_080078ac (8-bit with flag bit10, 16-bit with flag bit8, else
@ 32-bit), then continues in format_octal_64 with r2 = masked value, r3 = 0.
@ Code: push {r4,lr}; r4 = context; bl fn_080078ac; pop {r4,lr}; movs r3,#0;
@ b.n format_octal_64 (return value from emit_formatted_number).
@ Entered by beq.w at 0x0800727a (r1 == 0x6f) in format_one_conversion
@ 08007238. The block at 0x080082a8 (r2 aligned up to 8, ldrd r2,r3 of the
@ 64-bit slot, b.n format_octal_64) and the data at 0x080082b4 (empty prefix
@ string) and 0x080082b8 (prefix string "0") belong to this unit.
@ ----------------------------------------------------------------------------
	.section .text.format_octal_32,"ax",%progbits
	.global format_octal_32
	.thumb_func
	.type format_octal_32, %function
format_octal_32:
	push	{r4, lr}
	mov	r4, r0
	mov	r1, r4
	ldr	r0, [r2, #0x0]
	bl	fn_080078ac
	mov	r2, r0
	mov	r0, r4
	pop.w	{r4, lr}
	movs	r3, #0x0
	b.n	format_octal_64
	.global	L_080082a8		@ entered from format_one_conversion (startup_56)
	.thumb_func
L_080082a8:
.L080082a8:
	.inst.n	0x1dd2		@ adds r2, r2, #7
	bic	r1, r2, #0x7		@ align slot to 8
	ldrd	r2, r3, [r1, #0x0]
	b.n	format_octal_64
.L080082b4:
	.word	0x00000000		@ empty prefix string (and padding)
.L080082b8:
	.asciz	"0"
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0800839c - emit the text of an infinity or NaN.
@ r0 = format context, r2 = class (below 7 selects text 'inf', else 'nan';
@ upper case when flag bit11 is set), r3 = sign character or 0; clears flag
@ bit4, subtracts 3 (4 with sign) from context[6], pads via fn_080073e0, emits
@ the optional sign and the three characters through callback context[1], adds
@ 3 (and 1) to context[8], pads via fn_0800740c.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800839c,"ax",%progbits
	.global fn_0800839c
	.thumb_func
	.type fn_0800839c, %function
fn_0800839c:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r7, r3			@ sign character
	mov	r4, r0			@ context
	movs	r6, #0x3
	ldr	r1, [r0, #0x0]
	cmp	r2, #0x7
	and	r0, r1, #0x800		@ flag bit11 (upper case)
	blt.n	.L080083ba
	cbz	r0, .L080083b6
	adr	r5, .L0800840c		@ "NAN"
	b.n	.L080083c2
.L080083b6:
	adr	r5, .L08008410		@ "nan"
	b.n	.L080083c2
.L080083ba:
	cbz	r0, .L080083c0
	adr	r5, .L08008414		@ "INF"
	b.n	.L080083c2
.L080083c0:
	adr	r5, .L08008418		@ "inf"
.L080083c2:
	bic	r0, r1, #0x10
	str	r0, [r4, #0x0]		@ clear flag bit4
	ldr	r0, [r4, #0x18]
	.inst.n	0x1ec0		@ subs r0, r0, #3
	str	r0, [r4, #0x18]		@ width -= 3
	cbz	r7, .L080083d4
	.inst.n	0x1e40		@ subs r0, r0, #1
	str	r0, [r4, #0x18]		@ width -= 1 more for the sign
.L080083d4:
	mov	r0, r4
	bl	fn_080073e0
	cbz	r7, .L080083f0
	ldrd	r2, r1, [r4, #0x4]
	mov	r0, r7
	blx	r2			@ sign character
	ldr	r0, [r4, #0x20]
	.inst.n	0x1c40		@ adds r0, r0, #1
	str	r0, [r4, #0x20]
.L080083ea:
	.inst.n	0x1cc0		@ adds r0, r0, #3
	str	r0, [r4, #0x20]		@ counter += 3
	b.n	.L080083fe
.L080083f0:
	ldr	r0, [r4, #0x20]
	b.n	.L080083ea
.L080083f4:
	ldrd	r2, r1, [r4, #0x4]
	ldrb.w	r0, [r5], #0x1
	blx	r2			@ text character
.L080083fe:
	.inst.n	0x1e76		@ subs r6, r6, #1
	bcs.n	.L080083f4
	mov	r0, r4
	bl	fn_0800740c
	pop.w	{r4, r5, r6, r7, r8, pc}
.L0800840c:
	.asciz	"NAN"
.L08008410:
	.asciz	"nan"
.L08008414:
	.asciz	"INF"
.L08008418:
	.asciz	"inf"

@ ----------------------------------------------------------------------------
@ emit_text_conversion_wide - common tail of the wide 'c' and 's' conversions
@ (conversion characters 0xe3 and 0xf3).
@ r0 = format context, r1 = text pointer, r2 = count; returns r0 = 1.
@ Code identical in shape to emit_text_conversion: push {r4,lr}; r3 =
@ context[5]; when r3 == 0 calls fn_08008114 (16-bit character emitter: r0 =
@ context, r1 = halfword array, r2 = minimum count, -1 up to the first zero
@ halfword) at 0x08008428; when r3 != 0 only nop.w at 0x08008422 and b.n
@ 0x0800842c run and nothing is emitted; the meaning of the context[5] flag is
@ not determined from the code.
@ Entered by: b.n at 0x0800843e (block 0x08008430: stores the halfword [r2] at
@ context+0x24 and 0 at +0x26, r1 = context+0x24, r2 = 1; reached by beq.w at
@ 0x080072ba for r1 == 0xe3) and b.n at 0x08008446 (block 0x08008440: r1 = word
@ [r2], r2 = 0xffffffff; reached by beq.w at 0x080072c0 for r1 == 0xf3). Entry
@ state: lr = the conversion handler's caller.
@ ----------------------------------------------------------------------------
	.section .text.emit_text_conversion_wide,"ax",%progbits
	.global emit_text_conversion_wide
	.thumb_func
	.type emit_text_conversion_wide, %function
emit_text_conversion_wide:
	push	{r4, lr}
	ldr	r3, [r0, #0x14]
	cbz	r3, .L08008428
	nop.w
	b.n	.L0800842c
.L08008428:
	bl	fn_08008114
.L0800842c:
	movs	r0, #0x1
	pop	{r4, pc}
	.global	L_08008430		@ entered from format_one_conversion (startup_56)
	.thumb_func
L_08008430:
.L08008430:
	ldrh	r2, [r2, #0x0]
	add.w	r1, r0, #0x24
	strh	r2, [r0, #0x24]
	movs	r2, #0x0
	strh	r2, [r0, #0x26]
	movs	r2, #0x1
	b.n	emit_text_conversion_wide
	.global	L_08008440		@ entered from format_one_conversion (startup_56)
	.thumb_func
L_08008440:
.L08008440:
	ldr	r1, [r2, #0x0]
	mov.w	r2, #0xffffffff
	b.n	emit_text_conversion_wide

@ ----------------------------------------------------------------------------
@ fn_08008448 - scale a 12-byte extended value by a power of ten.
@ r0 = output (12-byte extended value), r1 = signed exponent n, r2 = mode;
@ combines 12-byte table entries (tables at 0x08046490 stride 0xc and
@ 0x080464cc..0x080464d8 stride 0x10) with fn_0804356a, and divides with
@ fn_08043540 when (n+0x1b9b)%0x37 is below 0x1b (not when n itself is
@ negative), otherwise multiplies with fn_0804356a; index split uses
@ (n+0x1b9b)/0x37 and %0x37.
@ ----------------------------------------------------------------------------
	.section .text.fn_08008448,"ax",%progbits
	.p2align 2
	.global fn_08008448
	.thumb_func
	.type fn_08008448, %function
fn_08008448:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r9, r0			@ output
	mov	r6, r2			@ mode
	sub	sp, #0x28
	ldr	r0, .L08008528
	add	r0, pc
	ldmia	r0, {r0, r2, r3}
	stm.w	sp, {r0, r2, r3}
	ldr	r0, .L08008528
	add	r0, pc
	.inst.n	0x1c80		@ adds r0, r0, #2
	add	r4, sp, #0xc
	ldmia	r0, {r0, r2, r3}
	stm.w	r4, {r0, r2, r3}
	movw	r0, #0x1b9b
	add	r0, r1
	movs	r1, #0x37
	sdiv	r2, r0, r1
	sdiv	r5, r0, r1
	sub.w	r5, r5, #0x80
	mls	r4, r1, r2, r0
	subs	r4, #0x1b
	bpl.n	.L0800848c
	rsbs	r4, r4, #0x0
	movs	r0, #0x1
	b.n	.L0800848e
.L0800848c:
	movs	r0, #0x0
.L0800848e:
	ldr.w	r10, .L08008528
	mov	r8, r0
	movs	r7, #0x0
	add	r10, pc
	sub.w	r10, r10, #0xbe
	b.n	.L080084bc
.L0800849e:
	lsls	r0, r4, #0x1f
	beq.n	.L080084b8
	mov	r2, r6
	mov	r0, sp
	add.w	r1, r7, r7, lsl #0x1
	movs	r3, #0x1
	add.w	r1, r10, r1, lsl #0x2
	bl	fn_0804356a
	stm.w	sp, {r0, r1, r2}
.L080084b8:
	asrs	r4, r4, #0x1
	.inst.n	0x1c7f		@ adds r7, r7, #1
.L080084bc:
	cmp	r4, #0x0
	bne.n	.L0800849e
	ldr	r7, .L08008528
.L080084c2:
	add	r7, pc
	subs	r7, #0xae
	b.n	.L080084fc
.L080084c8:
	lsls	r0, r5, #0x1f
	beq.n	.L080084f8
	add.w	r0, r7, r4, lsl #0x4
	add.w	r10, sp, #0x18
	ldm.w	r0, {r1, r2, r3}
	stm.w	r10, {r1, r2, r3}
	ldr	r0, [r0, #0xc]
	cmn	r0, r6
	bne.n	.L080084e6
	adds	r0, r3, r6
	str	r0, [sp, #0x20]
.L080084e6:
	mov	r2, r6
	movs	r3, #0x1
	add	r1, sp, #0x18
	add	r0, sp, #0xc
	bl	fn_0804356a
	add	r3, sp, #0xc
	stm.w	r3, {r0, r1, r2}
.L080084f8:
	asrs	r5, r5, #0x1
	.inst.n	0x1c64		@ adds r4, r4, #1
.L080084fc:
	cmp	r5, #0x0
	bne.n	.L080084c8
	mov.w	r3, #0x1
	mov	r2, r6
	mov	r1, sp
	cmp.w	r8, #0x0
	add	r0, sp, #0xc
	beq.n	.L08008516
	bl	fn_08043540
	b.n	.L0800851a
.L08008516:
	bl	fn_0804356a
.L0800851a:
	strd	r0, r1, [r9, #0x0]
	str.w	r2, [r9, #0x8]
	add	sp, #0x28
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
.L08008528:
	.word	d_0804657a - (.L080084c2 + 4)

@ ----------------------------------------------------------------------------
@ fn_0800852c - test a flag bit of an object.
@ r0 = pointer; returns the byte at [r0+0xc] ANDed with 0x80.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800852c,"ax",%progbits
	.global fn_0800852c
	.thumb_func
	.type fn_0800852c, %function
fn_0800852c:
	ldrb	r0, [r0, #0xc]
	and	r0, r0, #0x80
	bx	lr
