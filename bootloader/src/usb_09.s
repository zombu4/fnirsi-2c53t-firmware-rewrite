@ usb_09.s - usb module, batch 09: USB interrupt vector 20, descriptor / string accessors, serial-number text, 0x200000c0 helpers and the endpoint-register helpers of the 0x40005c00 block.
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ irq20_handler - vector word 36 (offset 0x90) = 0x080009F1.
@ Pushes r4/lr, loads r0 = 0x200001C8 (literal at 0x080009FC), calls
@ fn_0800430e (0x0800430E), which reads [[r0]+0x44] and [[r0]+0x40] and tests
@ bits 0x8000, 0x400, 0x200, 0x100, 0x800, 0x1000, then returns.
@ What the peripheral is and the purpose are not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.irq20_handler,"ax",%progbits
	.p2align 2
	.global irq20_handler
	.thumb_func
	.type irq20_handler, %function
irq20_handler:
	push	{r4, lr}
	ldr	r0, .L080009fc
	bl	fn_0800430e
	pop	{r4, pc}
	.short	0x0000			@ padding
.L080009fc:
	.word	0x200001c8

@ ----------------------------------------------------------------------------
@ usb_string_config - builds a string descriptor for the text
@ "Mass Storage Config" with ascii_to_length_prefixed_halfword_string
@ (0x08004626) (text, 0x200014a4); stores the returned halfword at 0x200001c0
@ and 0x200014a4 at 0x200001c4; returns 0x200001c0.
@ Address stored at slot 0x20000148 of the pointer table that starts at
@ 0x20000124 (rwdata_20000000.bin).
@ ----------------------------------------------------------------------------
	.section .text.usb_string_config,"ax",%progbits
	.p2align 2
	.global usb_string_config
	.thumb_func
	.type usb_string_config, %function
usb_string_config:
	push	{r4, lr}
	ldr	r1, .L08002530
	adr	r0, .L08002534
	bl	ascii_to_length_prefixed_halfword_string
	ldr	r1, .L08002548
	strh	r0, [r1, #0]
	ldr	r0, .L08002530
	str	r0, [r1, #4]
	mov	r0, r1
	pop	{r4, pc}
	.short	0x0000			@ padding
.L08002530:
	.word	0x200014a4		@ literal read by the PC-relative load at 0x0800251a
.L08002534:
	.asciz	"Mass Storage Config"
.L08002548:
	.word	0x200001c0

@ ----------------------------------------------------------------------------
@ usb_config_descriptor_ref - returns 0x200001a8.
@ The word pair there initially is {0x20, 0x20000160} (rwdata_20000000.bin
@ 0x1a8), and 0x20000160 holds the bytes 09 02 20 00 01 01 04 c0 32 09 04 00
@ 00 02 08 06 50 05 07 05 81 02 40 00 00 07 05 01 02 40 00 00.
@ Address stored at slot 0x2000012c of the table at 0x20000124.
@ ----------------------------------------------------------------------------
	.section .text.usb_config_descriptor_ref,"ax",%progbits
	.p2align 2
	.global usb_config_descriptor_ref
	.thumb_func
	.type usb_config_descriptor_ref, %function
usb_config_descriptor_ref:
	ldr	r0, .L08002550
	bx	lr
.L08002550:
	.word	0x200001a8

@ ----------------------------------------------------------------------------
@ usb_device_descriptor_ref - returns 0x200001a0.
@ The word pair there initially is {0x12, 0x2000014c}, and 0x2000014c holds
@ 12 01 00 02 00 00 00 40 3c 2e 20 57 00 02 01 02 03 01 (vendor id 0x2e3c,
@ product id 0x5720).
@ Address stored at slot 0x20000124 (first slot) of the table at 0x20000124.
@ ----------------------------------------------------------------------------
	.section .text.usb_device_descriptor_ref,"ax",%progbits
	.p2align 2
	.global usb_device_descriptor_ref
	.thumb_func
	.type usb_device_descriptor_ref, %function
usb_device_descriptor_ref:
	ldr	r0, .L08002558
	bx	lr
.L08002558:
	.word	0x200001a0

@ ----------------------------------------------------------------------------
@ usb_string_interface - builds a string descriptor for the text
@ "Mass Storage Interface" with ascii_to_length_prefixed_halfword_string
@ (0x08004626) (text, 0x200014a4); stores the returned halfword at 0x200001c0
@ and 0x200014a4 at 0x200001c4; returns 0x200001c0.
@ Address stored at slot 0x20000144 of the table at 0x20000124.
@ ----------------------------------------------------------------------------
	.section .text.usb_string_interface,"ax",%progbits
	.p2align 2
	.global usb_string_interface
	.thumb_func
	.type usb_string_interface, %function
usb_string_interface:
	push	{r4, lr}
	ldr	r1, .L08002574
	adr	r0, .L08002578
	bl	ascii_to_length_prefixed_halfword_string
	ldr	r1, .L08002590
	strh	r0, [r1, #0]
	ldr	r0, .L08002574
	str	r0, [r1, #4]
	mov	r0, r1
	pop	{r4, pc}
	.short	0x0000			@ padding
.L08002574:
	.word	0x200014a4		@ literal read by the PC-relative load at 0x0800255e
.L08002578:
	.asciz	"Mass Storage Interface"
	.byte	0x00			@ padding
.L08002590:
	.word	0x200001c0

@ ----------------------------------------------------------------------------
@ usb_langid_descriptor_ref - returns 0x200001b0.
@ The word pair there initially is {4, 0x20000180}, and 0x20000180 holds
@ 04 03 09 04.
@ Address stored at slot 0x20000134 of the table at 0x20000124.
@ ----------------------------------------------------------------------------
	.section .text.usb_langid_descriptor_ref,"ax",%progbits
	.p2align 2
	.global usb_langid_descriptor_ref
	.thumb_func
	.type usb_langid_descriptor_ref, %function
usb_langid_descriptor_ref:
	ldr	r0, .L08002598
	bx	lr
.L08002598:
	.word	0x200001b0

@ ----------------------------------------------------------------------------
@ usb_string_manufacturer - builds a string descriptor for the text "Artery"
@ with ascii_to_length_prefixed_halfword_string (0x08004626)
@ (text, 0x200014a4); stores the returned halfword at 0x200001c0 and
@ 0x200014a4 at 0x200001c4; returns 0x200001c0.
@ Address stored at slot 0x20000138 of the table at 0x20000124 (slot = word
@ 0x20000124 + 0x14; 0x0800414e calls that slot for a type-3 request whose
@ low index byte [R+0x20e] is 1; device descriptor byte 14 = 1).
@ ----------------------------------------------------------------------------
	.section .text.usb_string_manufacturer,"ax",%progbits
	.p2align 2
	.global usb_string_manufacturer
	.thumb_func
	.type usb_string_manufacturer, %function
usb_string_manufacturer:
	push	{r4, lr}
	ldr	r1, .L080025b4
	adr	r0, .L080025b8
	bl	ascii_to_length_prefixed_halfword_string
	ldr	r1, .L080025c0
	strh	r0, [r1, #0]
	ldr	r0, .L080025b4
	str	r0, [r1, #4]
	mov	r0, r1
	pop	{r4, pc}
	.short	0x0000			@ padding
.L080025b4:
	.word	0x200014a4		@ literal read by the PC-relative load at 0x0800259e
.L080025b8:
	.asciz	"Artery"
	.byte	0x00			@ padding
.L080025c0:
	.word	0x200001c0

@ ----------------------------------------------------------------------------
@ return_zero_080025c4 - returns 0, no other effect.
@ Address stored at slot 0x20000130 of the table at 0x20000124.
@ ----------------------------------------------------------------------------
	.section .text.return_zero_080025c4,"ax",%progbits
	.p2align 2
	.global return_zero_080025c4
	.thumb_func
	.type return_zero_080025c4, %function
return_zero_080025c4:
	movs	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ usb_string_product - builds a string descriptor for the text
@ "AT32 Mass Storage" with ascii_to_length_prefixed_halfword_string
@ (0x08004626) (text, 0x200014a4); stores the returned halfword at 0x200001c0
@ and 0x200014a4 at 0x200001c4; returns 0x200001c0.
@ Address stored at slot 0x2000013c of the table at 0x20000124 (device
@ descriptor byte 15 = 2).
@ ----------------------------------------------------------------------------
	.section .text.usb_string_product,"ax",%progbits
	.p2align 2
	.global usb_string_product
	.thumb_func
	.type usb_string_product, %function
usb_string_product:
	push	{r4, lr}
	ldr	r1, .L080025e0
	adr	r0, .L080025e4
	bl	ascii_to_length_prefixed_halfword_string
	ldr	r1, .L080025f8
	strh	r0, [r1, #0]
	ldr	r0, .L080025e0
	str	r0, [r1, #4]
	mov	r0, r1
	pop	{r4, pc}
	.short	0x0000			@ padding
.L080025e0:
	.word	0x200014a4		@ literal read by the PC-relative load at 0x080025ca
.L080025e4:
	.asciz	"AT32 Mass Storage"
	.short	0x0000			@ padding
.L080025f8:
	.word	0x200001c0

@ ----------------------------------------------------------------------------
@ return_zero_080025fc - returns 0, no other effect.
@ Address stored at slot 0x20000128 of the table at 0x20000124.
@ ----------------------------------------------------------------------------
	.section .text.return_zero_080025fc,"ax",%progbits
	.p2align 2
	.global return_zero_080025fc
	.thumb_func
	.type return_zero_080025fc, %function
return_zero_080025fc:
	movs	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ usb_serial_descriptor_ref - calls usb_serial_fill (0x0800262c), then
@ returns 0x200001b8.
@ The word pair at 0x200001b8 initially is {0x1a, 0x20000184}, and
@ 0x20000184 holds 1a 03 followed by zeros (0x0800262c fills the text).
@ Address stored at slot 0x20000140 of the table at 0x20000124 (device
@ descriptor byte 16 = 3).
@ ----------------------------------------------------------------------------
	.section .text.usb_serial_descriptor_ref,"ax",%progbits
	.p2align 2
	.global usb_serial_descriptor_ref
	.thumb_func
	.type usb_serial_descriptor_ref, %function
usb_serial_descriptor_ref:
	push	{r4, lr}
	bl	usb_serial_fill
	ldr	r0, .L0800260c
	pop	{r4, pc}
	.short	0x0000			@ padding
.L0800260c:
	.word	0x200001b8

@ ----------------------------------------------------------------------------
@ fn_08002610 - index to address: r0 signed; when r0 < 1 returns
@ 0x20000005 + r0 * 0x24, otherwise returns 0. No memory access.
@ Caller: 0x08000edc. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002610,"ax",%progbits
	.p2align 2
	.global fn_08002610
	.thumb_func
	.type fn_08002610, %function
fn_08002610:
	mov	r1, r0
	cmp	r1, #1
	bge	.L08002622
	add.w	r0, r1, r1, lsl #3
	ldr	r2, .L08002628
	add.w	r0, r2, r0, lsl #2
.L08002620:
	bx	lr
.L08002622:
	movs	r0, #0
	b.n	.L08002620
	.short	0x0000			@ padding
.L08002628:
	.word	0x20000005

@ ----------------------------------------------------------------------------
@ usb_serial_fill - fills the serial-number string text from three words of
@ the 0x1ffff7e8 area: r4 = word 0x1ffff7e8 + word 0x1ffff7f0,
@ r5 = word 0x1ffff7ec. Does nothing when r4 is 0. Otherwise calls
@ hex_digit_pairs (0x08004298)(r4, 0x20000186, 8) and
@ hex_digit_pairs(r5, 0x20000196, 4); 0x08004298 writes the top n nibbles of
@ its value as upper-case hexadecimal ASCII characters, one per 16-bit unit
@ (character, 0). Result: 12 UTF-16 characters at 0x20000186..0x2000019d
@ inside the descriptor at 0x20000184 (length byte 0x1a).
@ Caller: 0x08002602.
@ ----------------------------------------------------------------------------
	.section .text.usb_serial_fill,"ax",%progbits
	.p2align 2
	.global usb_serial_fill
	.thumb_func
	.type usb_serial_fill, %function
usb_serial_fill:
	push	{r4, r5, r6, lr}
	ldr	r0, .L08002658
	ldr	r4, [r0, #0]
	.inst.n	0x1d00			@ adds r0, r0, #4
	ldr	r5, [r0, #0]
	.inst.n	0x1d00			@ adds r0, r0, #4
	ldr	r6, [r0, #0]
	add	r4, r6
	cbz	r4, .L08002654
	movs	r2, #8
	ldr	r1, .L0800265c
	mov	r0, r4
	bl	hex_digit_pairs
	movs	r2, #4
	ldr	r1, .L0800265c
	adds	r1, #0x10
	mov	r0, r5
	bl	hex_digit_pairs
.L08002654:
	pop	{r4, r5, r6, pc}
	.short	0x0000			@ padding
.L08002658:
	.word	0x1ffff7e8
.L0800265c:
	.word	0x20000186

@ ----------------------------------------------------------------------------
@ halfword_200000c0_reset - stores the halfword 0x40 at 0x200000c0.
@ Caller: 0x080043ae.
@ ----------------------------------------------------------------------------
	.section .text.halfword_200000c0_reset,"ax",%progbits
	.p2align 2
	.global halfword_200000c0_reset
	.thumb_func
	.type halfword_200000c0_reset, %function
halfword_200000c0_reset:
	movs	r0, #0x40
	ldr	r1, .L08002d90
	strh	r0, [r1, #0]
	bx	lr
.L08002d90:
	.word	0x200000c0

@ ----------------------------------------------------------------------------
@ halfword_200000c0_fetch_add - returns the halfword at 0x200000c0 and adds
@ r0 to it (16-bit store).
@ Callers: 0x08003be4, 0x08003bf2, 0x08003c00, 0x08003c0c.
@ ----------------------------------------------------------------------------
	.section .text.halfword_200000c0_fetch_add,"ax",%progbits
	.p2align 2
	.global halfword_200000c0_fetch_add
	.thumb_func
	.type halfword_200000c0_fetch_add, %function
halfword_200000c0_fetch_add:
	mov	r1, r0
	ldr	r2, .L08002da4
	ldrh	r0, [r2, #0]
	ldrh	r2, [r2, #0]
	add	r2, r1
	ldr	r3, .L08002da4
	strh	r2, [r3, #0]
	bx	lr
.L08002da4:
	.word	0x200000c0

@ ----------------------------------------------------------------------------
@ fn_08002e68 - clears bit 1 of [r0 + 0x40] and bit 1 of [r0 + 0x60].
@ Caller: 0x080037c6 (from 0x080037c0, base from the first word of the record
@ at 0x200001c8, 0x40005c00).
@ ----------------------------------------------------------------------------
	.section .text.fn_08002e68,"ax",%progbits
	.global fn_08002e68
	.thumb_func
	.type fn_08002e68, %function
fn_08002e68:
	ldr	r1, [r0, #0x40]
	bic.w	r1, r1, #2
	str	r1, [r0, #0x40]
	ldr	r1, [r0, #0x60]
	bic.w	r1, r1, #2
	str	r1, [r0, #0x60]
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08002e7a - initialises with base r0: clears bit 0 of [r0 + 0x40],
@ [r0 + 0x44] = 0, [r0 + 0x50] = 0, [r0 + 0x4c] = 0x80, then
@ fn_08003638 (0x08003638)(r0, 0x9e00, 1) (sets bits 0x9e00 in [r0 + 0x40]).
@ Caller: 0x080038aa (inside 0x08003886).
@ ----------------------------------------------------------------------------
	.section .text.fn_08002e7a,"ax",%progbits
	.global fn_08002e7a
	.thumb_func
	.type fn_08002e7a, %function
fn_08002e7a:
	push	{r4, lr}
	mov	r4, r0
	ldr	r0, [r4, #0x40]
	bic.w	r0, r0, #1
	str	r0, [r4, #0x40]
	movs	r0, #0
	str	r0, [r4, #0x44]
	str	r0, [r4, #0x50]
	movs	r0, #0x80
	str	r0, [r4, #0x4c]
	movs	r2, #1
	mov.w	r1, #0x9e00
	mov	r0, r4
	bl	fn_08003638
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08002e9e - sets bit 1 of [r0 + 0x40] and bit 1 of [r0 + 0x60].
@ Caller: 0x08003a72 (inside 0x08003a6c). Opposite of fn_08002e68.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002e9e,"ax",%progbits
	.global fn_08002e9e
	.thumb_func
	.type fn_08002e9e, %function
fn_08002e9e:
	ldr	r1, [r0, #0x40]
	bic.w	r1, r1, #2
	.inst.n	0x1c89			@ adds r1, r1, #2
	str	r1, [r0, #0x40]
	ldr	r1, [r0, #0x60]
	bic.w	r1, r1, #2
	.inst.n	0x1c89			@ adds r1, r1, #2
	str	r1, [r0, #0x60]
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08002eb4 - sets bit 3 of [r0 + 0x40], then sets bit 2 of [r0 + 0x40].
@ Caller: 0x08003bca (inside 0x08003bc4). Opposite of fn_08003620.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002eb4,"ax",%progbits
	.p2align 2
	.global fn_08002eb4
	.thumb_func
	.type fn_08002eb4, %function
fn_08002eb4:
	ldr	r1, [r0, #0x40]
	bic.w	r1, r1, #8
	adds	r1, #8
	str	r1, [r0, #0x40]
	ldr	r1, [r0, #0x40]
	bic.w	r1, r1, #4
	.inst.n	0x1d09			@ adds r1, r1, #4
	str	r1, [r0, #0x40]
	bx	lr
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_08002ecc - rewrites the word R = 0x40005c00 + 4 * ep, ep = byte [r1 + 0]
@ of the record r1 (r0 is not used). Every store sets bits 15 and 7.
@ [r1 + 10] == 0 and [r1 + 2] == 1: if bit 6 of R is set
@   R = (R & 0x8f8f) | 0x80c0; then R = (R & 0x8fbf) | 0x8080.
@ [r1 + 10] == 0 and [r1 + 2] != 1: if bit 14 of R is set
@   R = (R & 0x8f8f) | 0xc080; then R = (R & 0xbf8f) | 0x8080.
@ [r1 + 10] != 0: if bit 6 is set R = (R & 0x8f8f) | 0x80c0; if bit 14 is set
@   R = (R & 0x8f8f) | 0xc080; then for [r1 + 2] == 1
@   R = (R & 0x8f8f) | 0x80c0, R = (R & 0x8fbf) | 0x8080,
@   R = (R & 0xbf8f) | 0x8080; for [r1 + 2] != 1
@   R = (R & 0x8f8f) | 0xc080, R = (R & 0x8fbf) | 0x8080,
@   R = (R & 0xbf8f) | 0x8080.
@ Caller: 0x08003c3e. Purpose not determined from the code (the meaning of the
@ bits of R is not shown here).
@ ----------------------------------------------------------------------------
	.section .text.fn_08002ecc,"ax",%progbits
	.p2align 2
	.global fn_08002ecc
	.thumb_func
	.type fn_08002ecc, %function
fn_08002ecc:
	push	{r4, r5, lr}
	mov	r2, r0
	ldrb	r0, [r1, #0xa]
	cmp	r0, #0
	bne.n	.L08002fa0
	ldrb	r0, [r1, #2]
	cmp	r0, #1
	bne.n	.L08002f40
	ldrb	r0, [r1, #0]
	ldr	r3, .L08003104
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #6, #1
	cbz	r0, .L08002f16
	ldrb	r0, [r1, #0]
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r3, #0x8f8f
	ands	r0, r3
	orr.w	r0, r0, #0x40
	orr.w	r0, r0, #0x8000
	orr.w	r0, r0, #0x80
	ldrb	r3, [r1, #0]
	ldr	r4, .L08003104
	add.w	r3, r4, r3, lsl #2
	str.w	r0, [r3, #0xc00]
.L08002f16:
	ldrb	r3, [r1, #0]
	ldr	r4, .L08003104
	add.w	r3, r4, r3, lsl #2
	ldr.w	r3, [r3, #0xc00]
	movw	r4, #0x8fbf
	and.w	r0, r3, r4
	orr.w	r3, r0, #0x8000
	orr.w	r3, r3, #0x80
	ldrb	r4, [r1, #0]
	ldr	r5, .L08003104
	add.w	r4, r5, r4, lsl #2
	str.w	r3, [r4, #0xc00]
	b.n	.L08003102
.L08002f40:
	ldrb	r0, [r1, #0]
	ldr	r3, .L08003104
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #0xe, #1
	cbz	r0, .L08002f76
	ldrb	r0, [r1, #0]
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r3, #0x8f8f
	ands	r0, r3
	orr.w	r0, r0, #0xc000
	orr.w	r0, r0, #0x80
	ldrb	r3, [r1, #0]
	ldr	r4, .L08003104
	add.w	r3, r4, r3, lsl #2
	str.w	r0, [r3, #0xc00]
.L08002f76:
	ldrb	r3, [r1, #0]
	ldr	r4, .L08003104
	add.w	r3, r4, r3, lsl #2
	ldr.w	r3, [r3, #0xc00]
	movw	r4, #0xbf8f
	and.w	r0, r3, r4
	orr.w	r3, r0, #0x8000
	orr.w	r3, r3, #0x80
	ldrb	r4, [r1, #0]
	ldr	r5, .L08003104
	add.w	r4, r5, r4, lsl #2
	str.w	r3, [r4, #0xc00]
	b.n	.L08003102
.L08002fa0:
	ldrb	r0, [r1, #0]
	ldr	r3, .L08003104
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #6, #1
	cbz	r0, .L08002fda
	ldrb	r0, [r1, #0]
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r3, #0x8f8f
	ands	r0, r3
	orr.w	r0, r0, #0x40
	orr.w	r0, r0, #0x8000
	orr.w	r0, r0, #0x80
	ldrb	r3, [r1, #0]
	ldr	r4, .L08003104
	add.w	r3, r4, r3, lsl #2
	str.w	r0, [r3, #0xc00]
.L08002fda:
	ldrb	r0, [r1, #0]
	ldr	r3, .L08003104
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #0xe, #1
	cbz	r0, .L08003010
	ldrb	r0, [r1, #0]
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r3, #0x8f8f
	ands	r0, r3
	orr.w	r0, r0, #0xc000
	orr.w	r0, r0, #0x80
	ldrb	r3, [r1, #0]
	ldr	r4, .L08003104
	add.w	r3, r4, r3, lsl #2
	str.w	r0, [r3, #0xc00]
.L08003010:
	ldrb	r0, [r1, #2]
	cmp	r0, #1
	bne.n	.L0800308e
	ldrb	r0, [r1, #0]
	ldr	r3, .L08003104
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r3, #0x8f8f
	ands	r0, r3
	orr.w	r0, r0, #0x40
	orr.w	r0, r0, #0x8000
	orr.w	r0, r0, #0x80
	ldrb	r3, [r1, #0]
	ldr	r4, .L08003104
	add.w	r3, r4, r3, lsl #2
	str.w	r0, [r3, #0xc00]
	ldrb	r3, [r1, #0]
	add.w	r3, r4, r3, lsl #2
	ldr.w	r3, [r3, #0xc00]
	movw	r4, #0x8fbf
	and.w	r0, r3, r4
	orr.w	r3, r0, #0x8000
	orr.w	r3, r3, #0x80
	ldrb	r4, [r1, #0]
	ldr	r5, .L08003104
	add.w	r4, r5, r4, lsl #2
	str.w	r3, [r4, #0xc00]
	ldrb	r3, [r1, #0]
	mov	r4, r5
	add.w	r3, r4, r3, lsl #2
	ldr.w	r3, [r3, #0xc00]
	movw	r4, #0xbf8f
	and.w	r0, r3, r4
	orr.w	r3, r0, #0x8000
	orr.w	r3, r3, #0x80
	ldrb	r4, [r1, #0]
	add.w	r4, r5, r4, lsl #2
	str.w	r3, [r4, #0xc00]
	b.n	.L08003102
.L0800308e:
	ldrb	r0, [r1, #0]
	ldr	r3, .L08003104
	add.w	r0, r3, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r3, #0x8f8f
	ands	r0, r3
	orr.w	r0, r0, #0xc000
	orr.w	r0, r0, #0x80
	ldrb	r3, [r1, #0]
	ldr	r4, .L08003104
	add.w	r3, r4, r3, lsl #2
	str.w	r0, [r3, #0xc00]
	ldrb	r3, [r1, #0]
	add.w	r3, r4, r3, lsl #2
	ldr.w	r3, [r3, #0xc00]
	movw	r4, #0x8fbf
	and.w	r0, r3, r4
	orr.w	r3, r0, #0x8000
	orr.w	r3, r3, #0x80
	ldrb	r4, [r1, #0]
	ldr	r5, .L08003104
	add.w	r4, r5, r4, lsl #2
	str.w	r3, [r4, #0xc00]
	ldrb	r3, [r1, #0]
	mov	r4, r5
	add.w	r3, r4, r3, lsl #2
	ldr.w	r3, [r3, #0xc00]
	movw	r4, #0xbf8f
	and.w	r0, r3, r4
	orr.w	r3, r0, #0x8000
	orr.w	r3, r3, #0x80
	ldrb	r4, [r1, #0]
	add.w	r4, r5, r4, lsl #2
	str.w	r3, [r4, #0xc00]
	nop
.L08003102:
	pop	{r4, r5, pc}
.L08003104:
	.word	0x40005000

@ ----------------------------------------------------------------------------
@ fn_08003108 - programs the table entries selected by one record:
@ r1 = record {byte [0] = number ep, [1] = value for the low nibble,
@ [2] = direction flag (1 or not), [3] = type code, halfwords [4] and [6] =
@ two values, halfword [8] = size, byte [10] = flag}.
@ R = word at 0x40005c00 + 4 * ep, T = word at 0x40005c50, base B = word at
@ 0x200000bc, entry E(k) = B + (T + ep * 8 + k) * 2 (32-bit stores).
@ Steps: R = (R & 0x8f80) | [1]; type code 0 gives 0x200, 1 gives 0, 2 gives
@ 0x600, 3 gives 0x400 and sets [10] = 1; R = (R & 0x8f8f) with bits 10..9
@ cleared and the type value ORed.
@ Size encoding S(size): size < 0x3f:
@ ((size >> 1) + (size even ? 1 : 0)) & 0x3f) << 10; else
@ (((size >> 5) - (size & 0x1f == 0 ? 1 : 0)) & 0x3f) << 10 | 0x8000.
@ [2] == 1, [10] == 0: stores [4] at E(0); if bit 6 of R set
@   R = (R & 0x8f8f) | 0x80c0; R = ((R & 0x8fbf) ^ 0x20) | 0x8080.
@ [2] == 1, [10] != 0: R = (R & 0x8f8f) | 0x8180; stores [4] at E(0), [6] at
@   E(4); bit 6 set: R = (R & 0x8f8f) | 0x80c0; bit 14 set:
@   R = (R & 0x8f8f) | 0xc080; then R = (R & 0x8f8f) | 0xc080,
@   R = (R & 0xbf8f) | 0x8080, R = ((R & 0x8fbf) ^ 0x20) | 0x8080.
@ [2] != 1, [10] == 0: stores [6] at E(4); bit 14 set:
@   R = (R & 0x8f8f) | 0xc080; stores S([8]) at E(6);
@   R = ((R & 0xbf8f) ^ 0x3000) | 0x8080.
@ [2] != 1, [10] != 0: R = (R & 0x8f8f) | 0x8180; stores [4] at E(0), [6] at
@   E(4), S([8]) at E(2) and E(6); bit 6 set: |0x80c0 form; bit 14 set:
@   |0xc080 form; R = (R & 0x8f8f) | 0x80c0;
@   R = ((R & 0xbf8f) ^ 0x3000) | 0x8080; R = (R & 0x8fbf) | 0x8080.
@ Caller: 0x08003d7e (inside 0x08003d2e). Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003108,"ax",%progbits
	.p2align 2
	.global fn_08003108
	.thumb_func
	.type fn_08003108, %function
fn_08003108:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r3, #0
	ldrb	r0, [r1, #0]
	ldr	r2, .L08003504
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	bic.w	r0, r0, #0xf
	ldrb	r2, [r1, #1]
	orrs	r0, r2
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
	ldrb	r0, [r1, #3]
	cbnz	r0, .L0800313c
	asrs	r3, r5, #0x15		@ halfword 0x156b as in the original
	b.n	.L08003160
.L0800313c:
	ldrb	r0, [r1, #3]
	cmp	r0, #1
	bne.n	.L08003146
	movs	r3, #0
	b.n	.L08003160
.L08003146:
	ldrb	r0, [r1, #3]
	cmp	r0, #2
	bne.n	.L08003152
	mov.w	r3, #0x600
	b.n	.L08003160
.L08003152:
	ldrb	r0, [r1, #3]
	cmp	r0, #3
	bne.n	.L08003160
	mov.w	r3, #0x400
	movs	r0, #1
	strb	r0, [r1, #0xa]
.L08003160:
	ldrb	r0, [r1, #0]
	ldr	r2, .L08003504
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	bic.w	r0, r0, #0x600
	orrs	r0, r3
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
	ldrb	r0, [r1, #2]
	cmp	r0, #1
	bne.n	.L08003286
	ldrb	r0, [r1, #0xa]
	cbnz	r0, .L0800320a
	ldrh	r2, [r1, #4]
	ldr	r0, .L08003508
	ldr	r5, [r0, #0]
	ldrb	r0, [r1, #0]
	add.w	r0, r5, r0, lsl #3
	ldr	r5, .L0800350c
	ldr	r5, [r5, #0]
	str.w	r2, [r5, r0, lsl #1]
	ldrb	r0, [r1, #0]
	ldr	r2, .L08003504
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #6, #1
	cbz	r0, .L080031dc
	ldrb	r0, [r1, #0]
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	orr.w	r0, r0, #0x40
	orr.w	r0, r0, #0x8000
	orr.w	r0, r0, #0x80
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
.L080031dc:
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	ldr.w	r2, [r2, #0xc00]
	movw	r5, #0x8fbf
	and.w	r0, r2, r5
	eor.w	r0, r0, #0x20
	orr.w	r2, r0, #0x8000
	orr.w	r2, r2, #0x80
	ldrb	r5, [r1, #0]
	ldr	r6, .L08003504
	add.w	r5, r6, r5, lsl #2
	str.w	r2, [r5, #0xc00]
	b.n	.L0800361a
.L0800320a:
	b.n	.L0800320c
.L0800320c:
	ldrb	r0, [r1, #0]
	ldr	r2, .L08003504
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	orr.w	r0, r0, #0x100
	movw	r2, #0x8f8f
	ands	r0, r2
	movw	r2, #0x8080
	orrs	r0, r2
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
	ldrh	r2, [r1, #4]
	ldr	r0, .L08003508
	ldr	r5, [r0, #0]
	ldrb	r0, [r1, #0]
	add.w	r0, r5, r0, lsl #3
	ldr	r5, .L0800350c
	ldr	r5, [r5, #0]
	str.w	r2, [r5, r0, lsl #1]
	ldrh	r2, [r1, #6]
	ldr	r0, .L08003508
	ldr	r5, [r0, #0]
	ldrb	r0, [r1, #0]
	add.w	r0, r5, r0, lsl #3
	.inst.n	0x1d00			@ adds r0, r0, #4
	ldr	r5, .L0800350c
	ldr	r5, [r5, #0]
	str.w	r2, [r5, r0, lsl #1]
	ldrb	r0, [r1, #0]
	ldr	r2, .L08003504
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #6, #1
	cbz	r0, .L0800329c
	ldrb	r0, [r1, #0]
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	orr.w	r0, r0, #0x40
	b.n	.L08003288
.L08003286:
	b.n	.L0800334a
.L08003288:
	orr.w	r0, r0, #0x8000
	orr.w	r0, r0, #0x80
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
.L0800329c:
	ldrb	r0, [r1, #0]
	ldr	r2, .L08003504
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #0xe, #1
	cbz	r0, .L080032d2
	ldrb	r0, [r1, #0]
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	orr.w	r0, r0, #0xc000
	orr.w	r0, r0, #0x80
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
.L080032d2:
	ldrb	r0, [r1, #0]
	ldr	r2, .L08003504
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	orr.w	r0, r0, #0xc000
	orr.w	r0, r0, #0x80
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
	ldrb	r2, [r1, #0]
	add.w	r2, r5, r2, lsl #2
	ldr.w	r2, [r2, #0xc00]
	movw	r5, #0xbf8f
	and.w	r0, r2, r5
	orr.w	r2, r0, #0x8000
	orr.w	r2, r2, #0x80
	ldrb	r5, [r1, #0]
	ldr	r6, .L08003504
	add.w	r5, r6, r5, lsl #2
	str.w	r2, [r5, #0xc00]
	ldrb	r2, [r1, #0]
	mov	r5, r6
	add.w	r2, r5, r2, lsl #2
	ldr.w	r2, [r2, #0xc00]
	movw	r5, #0x8fbf
	and.w	r0, r2, r5
	eor.w	r0, r0, #0x20
	orr.w	r2, r0, #0x8000
	orr.w	r2, r2, #0x80
	ldrb	r5, [r1, #0]
	add.w	r5, r6, r5, lsl #2
	str.w	r2, [r5, #0xc00]
	b.n	.L0800361a
.L0800334a:
	ldrb	r0, [r1, #0xa]
	cmp	r0, #0
	bne.n	.L08003422
	ldrh	r2, [r1, #6]
	ldr	r0, .L08003508
	ldr	r5, [r0, #0]
	ldrb	r0, [r1, #0]
	add.w	r0, r5, r0, lsl #3
	.inst.n	0x1d00			@ adds r0, r0, #4
	ldr	r5, .L0800350c
	ldr	r5, [r5, #0]
	str.w	r2, [r5, r0, lsl #1]
	ldrb	r0, [r1, #0]
	ldr	r2, .L08003504
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #0xe, #1
	cbz	r0, .L0800339c
	ldrb	r0, [r1, #0]
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	orr.w	r0, r0, #0xc000
	orr.w	r0, r0, #0x80
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
.L0800339c:
	ldr	r0, .L08003508
	ldr	r5, [r0, #0]
	ldrb	r0, [r1, #0]
	add.w	r0, r5, r0, lsl #3
	.inst.n	0x1d80			@ adds r0, r0, #6
	ldr	r5, .L0800350c
	ldr	r5, [r5, #0]
	add.w	r2, r5, r0, lsl #1
	ldrh	r5, [r1, #8]
	cmp	r5, #0x3e
	ble.n	.L080033d6
	ldrh	r5, [r1, #8]
	asrs	r0, r5, #5
	ldrb	r5, [r1, #8]
	and.w	r5, r5, #0x1f
	cbnz	r5, .L080033c6
	subs	r5, r0, #1
	uxth	r0, r5
.L080033c6:
	movw	r5, #0xffff
	and.w	r5, r5, r0, lsl #10
	orr.w	r5, r5, #0x8000
	str	r5, [r2, #0]
	b.n	.L080033f0
.L080033d6:
	ldrh	r5, [r1, #8]
	asrs	r0, r5, #1
	ldrb	r5, [r1, #8]
	and.w	r5, r5, #1
	cbnz	r5, .L080033e6
	adds	r5, r0, #1
	uxth	r0, r5
.L080033e6:
	movw	r5, #0xffff
	and.w	r5, r5, r0, lsl #10
	str	r5, [r2, #0]
.L080033f0:
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	ldr.w	r2, [r2, #0xc00]
	movw	r5, #0xbf8f
	and.w	r0, r2, r5
	eor.w	r0, r0, #0x1000
	eor.w	r0, r0, #0x2000
	orr.w	r2, r0, #0x8000
	orr.w	r2, r2, #0x80
	ldrb	r5, [r1, #0]
	ldr	r6, .L08003504
	add.w	r5, r6, r5, lsl #2
	str.w	r2, [r5, #0xc00]
	b.n	.L0800361a
.L08003422:
	ldrb	r0, [r1, #0]
	ldr	r2, .L08003504
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	orr.w	r0, r0, #0x100
	movw	r2, #0x8f8f
	ands	r0, r2
	movw	r2, #0x8080
	orrs	r0, r2
	ldrb	r2, [r1, #0]
	ldr	r5, .L08003504
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
	ldrh	r2, [r1, #4]
	ldr	r0, .L08003508
	ldr	r5, [r0, #0]
	ldrb	r0, [r1, #0]
	add.w	r0, r5, r0, lsl #3
	ldr	r5, .L0800350c
	ldr	r5, [r5, #0]
	str.w	r2, [r5, r0, lsl #1]
	ldrh	r2, [r1, #6]
	ldr	r0, .L08003508
	ldr	r5, [r0, #0]
	ldrb	r0, [r1, #0]
	add.w	r0, r5, r0, lsl #3
	.inst.n	0x1d00			@ adds r0, r0, #4
	ldr	r5, .L0800350c
	ldr	r5, [r5, #0]
	str.w	r2, [r5, r0, lsl #1]
	ldr	r0, .L08003508
	ldr	r5, [r0, #0]
	ldrb	r0, [r1, #0]
	add.w	r0, r5, r0, lsl #3
	.inst.n	0x1c80			@ adds r0, r0, #2
	ldr	r5, .L0800350c
	ldr	r5, [r5, #0]
	add.w	r2, r5, r0, lsl #1
	ldrh	r5, [r1, #8]
	cmp	r5, #0x3e
	ble.n	.L080034ae
	ldrh	r5, [r1, #8]
	asrs	r0, r5, #5
	ldrb	r5, [r1, #8]
	and.w	r5, r5, #0x1f
	cbnz	r5, .L0800349e
	subs	r5, r0, #1
	uxth	r0, r5
.L0800349e:
	movw	r5, #0xffff
	and.w	r5, r5, r0, lsl #10
	orr.w	r5, r5, #0x8000
	str	r5, [r2, #0]
	b.n	.L080034c8
.L080034ae:
	ldrh	r5, [r1, #8]
	asrs	r0, r5, #1
	ldrb	r5, [r1, #8]
	and.w	r5, r5, #1
	cbnz	r5, .L080034be
	adds	r5, r0, #1
	uxth	r0, r5
.L080034be:
	movw	r5, #0xffff
	and.w	r5, r5, r0, lsl #10
	str	r5, [r2, #0]
.L080034c8:
	ldr	r0, .L08003508
	ldr	r5, [r0, #0]
	ldrb	r0, [r1, #0]
	add.w	r0, r5, r0, lsl #3
	.inst.n	0x1d80			@ adds r0, r0, #6
	ldr	r5, .L0800350c
	ldr	r5, [r5, #0]
	add.w	r2, r5, r0, lsl #1
	ldrh	r5, [r1, #8]
	cmp	r5, #0x3e
	ble.n	.L08003510
	ldrh	r5, [r1, #8]
	asrs	r0, r5, #5
	ldrb	r5, [r1, #8]
	and.w	r5, r5, #0x1f
	cbnz	r5, .L080034f2
	subs	r5, r0, #1
	uxth	r0, r5
.L080034f2:
	movw	r5, #0xffff
	and.w	r5, r5, r0, lsl #10
	orr.w	r5, r5, #0x8000
	str	r5, [r2, #0]
	b.n	.L0800352a
	.short	0x0000			@ padding
.L08003504:
	.word	0x40005000
.L08003508:
	.word	0x40005c50
.L0800350c:
	.word	0x200000bc
.L08003510:
	ldrh	r5, [r1, #8]
	asrs	r0, r5, #1
	ldrb	r5, [r1, #8]
	and.w	r5, r5, #1
	cbnz	r5, .L08003520
	adds	r5, r0, #1
	uxth	r0, r5
.L08003520:
	movw	r5, #0xffff
	and.w	r5, r5, r0, lsl #10
	str	r5, [r2, #0]
.L0800352a:
	ldrb	r0, [r1, #0]
	ldr	r2, .L0800361c
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #6, #1
	cbz	r0, .L08003564
	ldrb	r0, [r1, #0]
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	orr.w	r0, r0, #0x40
	orr.w	r0, r0, #0x8000
	orr.w	r0, r0, #0x80
	ldrb	r2, [r1, #0]
	ldr	r5, .L0800361c
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
.L08003564:
	ldrb	r0, [r1, #0]
	ldr	r2, .L0800361c
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	ubfx	r0, r0, #0xe, #1
	cbz	r0, .L0800359a
	ldrb	r0, [r1, #0]
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	orr.w	r0, r0, #0xc000
	orr.w	r0, r0, #0x80
	ldrb	r2, [r1, #0]
	ldr	r5, .L0800361c
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
.L0800359a:
	ldrb	r0, [r1, #0]
	ldr	r2, .L0800361c
	add.w	r0, r2, r0, lsl #2
	ldr.w	r0, [r0, #0xc00]
	movw	r2, #0x8f8f
	ands	r0, r2
	orr.w	r0, r0, #0x40
	orr.w	r0, r0, #0x8000
	orr.w	r0, r0, #0x80
	ldrb	r2, [r1, #0]
	ldr	r5, .L0800361c
	add.w	r2, r5, r2, lsl #2
	str.w	r0, [r2, #0xc00]
	ldrb	r2, [r1, #0]
	add.w	r2, r5, r2, lsl #2
	ldr.w	r2, [r2, #0xc00]
	movw	r5, #0xbf8f
	and.w	r0, r2, r5
	eor.w	r0, r0, #0x1000
	eor.w	r0, r0, #0x2000
	orr.w	r2, r0, #0x8000
	orr.w	r2, r2, #0x80
	ldrb	r5, [r1, #0]
	ldr	r6, .L0800361c
	add.w	r5, r6, r5, lsl #2
	str.w	r2, [r5, #0xc00]
	ldrb	r2, [r1, #0]
	mov	r5, r6
	add.w	r2, r5, r2, lsl #2
	ldr.w	r2, [r2, #0xc00]
	movw	r5, #0x8fbf
	and.w	r0, r2, r5
	orr.w	r2, r0, #0x8000
	orr.w	r2, r2, #0x80
	ldrb	r5, [r1, #0]
	add.w	r5, r6, r5, lsl #2
	str.w	r2, [r5, #0xc00]
	nop
.L0800361a:
	pop	{r4, r5, r6, pc}
.L0800361c:
	.word	0x40005000

@ ----------------------------------------------------------------------------
@ fn_08003620 - clears bit 3 of [r0 + 0x40], then clears bit 2 of
@ [r0 + 0x40].
@ Caller: 0x08004668 (inside 0x08004662).
@ ----------------------------------------------------------------------------
	.section .text.fn_08003620,"ax",%progbits
	.global fn_08003620
	.thumb_func
	.type fn_08003620, %function
fn_08003620:
	ldr	r1, [r0, #0x40]
	bic.w	r1, r1, #8
	str	r1, [r0, #0x40]
	ldr	r1, [r0, #0x40]
	bic.w	r1, r1, #4
	str	r1, [r0, #0x40]
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08003632 - stores the complement of r1 at [r0 + 0x44].
@ Callers: 0x08004332, 0x0800434e, 0x0800436a, 0x08004380, 0x080043a2 (inside
@ fn_0800430e, 0x0800430e).
@ ----------------------------------------------------------------------------
	.section .text.fn_08003632,"ax",%progbits
	.global fn_08003632
	.thumb_func
	.type fn_08003632, %function
fn_08003632:
	mvns	r2, r1
	str	r2, [r0, #0x44]
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08003638 - r0 = base, r1 = mask, r2 = flag: r2 == 1 sets the mask bits
@ in [r0 + 0x40], any other r2 clears them.
@ Caller: 0x08002e98 (inside fn_08002e7a).
@ ----------------------------------------------------------------------------
	.section .text.fn_08003638,"ax",%progbits
	.p2align 2
	.global fn_08003638
	.thumb_func
	.type fn_08003638, %function
fn_08003638:
	cmp	r2, #1
	bne.n	.L08003644
	ldr	r3, [r0, #0x40]
	orrs	r3, r1
	str	r3, [r0, #0x40]
	b.n	.L0800364a
.L08003644:
	ldr	r3, [r0, #0x40]
	bics	r3, r1
	str	r3, [r0, #0x40]
.L0800364a:
	bx	lr

@ ----------------------------------------------------------------------------
@ copy_from_200000bc_area - copies (r2 + 1) >> 1 halfwords to the destination
@ r0 from the area at word[0x200000bc] + r1 * 2; the source advances by 4
@ bytes per halfword, the destination by 2.
@ Callers: 0x08003fe2, 0x08004044, 0x0800406c, 0x0800408e.
@ ----------------------------------------------------------------------------
	.section .text.copy_from_200000bc_area,"ax",%progbits
	.p2align 2
	.global copy_from_200000bc_area
	.thumb_func
	.type copy_from_200000bc_area, %function
copy_from_200000bc_area:
	push	{r4, r5, r6, r7, lr}
	mov	r3, r0
	ldr	r7, .L08003674
	ldr	r7, [r7, #0]
	add.w	r0, r7, r1, lsl #1
	adds	r7, r2, #1
	asrs	r6, r7, #1
	mov	r5, r3
	movs	r4, #0
	b.n	.L0800366e
.L08003662:
	ldrh.w	r7, [r0], #2
	strh	r7, [r5, #0]
	.inst.n	0x1c80			@ adds r0, r0, #2
	.inst.n	0x1cad			@ adds r5, r5, #2
	.inst.n	0x1c64			@ adds r4, r4, #1
.L0800366e:
	cmp	r4, r6
	bcc.n	.L08003662
	pop	{r4, r5, r6, r7, pc}
.L08003674:
	.word	0x200000bc

@ ----------------------------------------------------------------------------
@ fn_08003678 - calls systick_delay (0x080018c4)(1000), fn_08003a6c
@ (0x08003a6c)(0x200001c8), systick_delay(1000), fn_080037c0
@ (0x080037c0)(0x200001c8). 0x08003a6c calls fn_08002e9e; 0x080037c0 calls
@ fn_08002e68.
@ Callers: 0x08001d7a, 0x08001da0, 0x08001db6.
@ BOOTLOADER.md point 10 names this as the USB re-enumeration (matches the two
@ calls above); purpose not otherwise determined from this function.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003678,"ax",%progbits
	.p2align 2
	.global fn_08003678
	.thumb_func
	.type fn_08003678, %function
fn_08003678:
	push	{r4, lr}
	mov.w	r0, #0x3e8
	bl	systick_delay
	ldr	r0, .L08003698
	bl	fn_08003a6c
	mov.w	r0, #0x3e8
	bl	systick_delay
	ldr	r0, .L08003698
	bl	fn_080037c0
	pop	{r4, pc}
.L08003698:
	.word	0x200001c8

@ ----------------------------------------------------------------------------
@ fn_0800369c - r0 = base, r1 = value:
@ [r0 + 0x4c] = ([r0 + 0x4c] & 0xffffff80) | (r1 & 0x7f), then sets bit 7 of
@ [r0 + 0x4c] (two stores).
@ Callers: 0x08003fa8, 0x080043d4.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800369c,"ax",%progbits
	.p2align 2
	.global fn_0800369c
	.thumb_func
	.type fn_0800369c, %function
fn_0800369c:
	ldr	r2, [r0, #0x4c]
	bfi	r2, r1, #0, #7
	str	r2, [r0, #0x4c]
	ldr	r2, [r0, #0x4c]
	bic.w	r2, r2, #0x80
	adds	r2, #0x80
	str	r2, [r0, #0x4c]
	bx	lr

@ ----------------------------------------------------------------------------
@ copy_to_200000bc_area - copies (r2 + 1) >> 1 halfwords from the source r0
@ to the area at word[0x200000bc] + r1 * 2; the destination advances by 4
@ bytes per halfword, the source by 2.
@ Callers: 0x08003e4a, 0x08003e90, 0x08003eb2.
@ ----------------------------------------------------------------------------
	.section .text.copy_to_200000bc_area,"ax",%progbits
	.p2align 2
	.global copy_to_200000bc_area
	.thumb_func
	.type copy_to_200000bc_area, %function
copy_to_200000bc_area:
	push	{r4, r5, r6, r7, lr}
	mov	r3, r0
	ldr	r7, .L080036d8
	ldr	r7, [r7, #0]
	add.w	r0, r7, r1, lsl #1
	adds	r7, r2, #1
	asrs	r6, r7, #1
	mov	r5, r3
	movs	r4, #0
	b.n	.L080036d2
.L080036c6:
	ldrh	r7, [r5, #0]
	strh.w	r7, [r0], #2
	.inst.n	0x1c80			@ adds r0, r0, #2
	.inst.n	0x1cad			@ adds r5, r5, #2
	.inst.n	0x1c64			@ adds r4, r4, #1
.L080036d2:
	cmp	r4, r6
	bcc.n	.L080036c6
	pop	{r4, r5, r6, r7, pc}
.L080036d8:
	.word	0x200000bc

@ ----------------------------------------------------------------------------
@ fn_080036dc - r0 = record (0x200001c8 in main).
@ When byte [r0 + 0x224] is 2 or 3: if halfword [r0 + 0x20e] == 1:
@ byte [r0 + 0x227] = 0, clears bit 1 of halfword [r0 + 0x22a], calls the
@ function at [[r0 + 4] + 8] with (r0, r0 + 0x20c), then calls fn_080039be
@ (0x080039be)(r0); with the halfword not 1 nothing more happens.
@ Other states: calls fn_080039d6 (0x080039d6)(r0). Returns 0.
@ Caller: 0x08003a30 (inside 0x080039ec). Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080036dc,"ax",%progbits
	.p2align 2
	.global fn_080036dc
	.thumb_func
	.type fn_080036dc, %function
fn_080036dc:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r5, #0
	add.w	r6, r4, #0x20c
	ldrb.w	r0, [r4, #0x224]
	cmp	r0, #2
	beq.n	.L080036f4
	cmp	r0, #3
	bne.n	.L08003722
	b.n	.L080036f6
.L080036f4:
	nop
.L080036f6:
	ldrh	r0, [r6, #2]
	cmp	r0, #1
	bne.n	.L08003720
	movs	r0, #0
	strb.w	r0, [r4, #0x227]
	ldrh.w	r0, [r4, #0x22a]
	bic.w	r0, r0, #2
	strh.w	r0, [r4, #0x22a]
	ldr	r0, [r4, #4]
	add.w	r1, r4, #0x20c
	ldr	r2, [r0, #8]
	mov	r0, r4
	blx	r2
	mov	r0, r4
	bl	fn_080039be
.L08003720:
	b.n	.L0800372a
.L08003722:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L0800372a:
	nop
	mov	r0, r5
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_08003730 - r0 = record, r1 = code.
@ r1 bit 7 set: entry = r0 + 0xc + (r1 & 0x7f) * 0x20,
@   R = word 0x40005c00 + 4 * byte [entry], R = (((R & 0x8fbf) ^ 0x30) | 0x8080).
@ r1 bit 7 clear: entry = r0 + 0x10c + (r1 & 0x7f) * 0x20,
@   R = (((R & 0xbf8f) ^ 0x3000) | 0x8080).
@ Both: byte [entry + 0xb] = 0.
@ Caller: 0x08003b3e (inside 0x08003a78). Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003730,"ax",%progbits
	.p2align 2
	.global fn_08003730
	.thumb_func
	.type fn_08003730, %function
fn_08003730:
	push	{r4, r5, r6, lr}
	mov	r2, r0
	and.w	r3, r1, #0x80
	cbz	r3, .L08003778
	and.w	r4, r1, #0x7f
	add.w	r3, r2, #0xc
	add.w	r0, r3, r4, lsl #5
	ldrb	r4, [r0, #0]
	ldr	r5, .L080037bc
	add.w	r4, r5, r4, lsl #2
	ldr.w	r4, [r4, #0xc00]
	movw	r5, #0x8fbf
	and.w	r3, r4, r5
	eor.w	r3, r3, #0x10
	eor.w	r3, r3, #0x20
	orr.w	r4, r3, #0x8000
	orr.w	r4, r4, #0x80
	ldrb	r5, [r0, #0]
	ldr	r6, .L080037bc
	add.w	r5, r6, r5, lsl #2
	str.w	r4, [r5, #0xc00]
	b.n	.L080037b6
.L08003778:
	and.w	r4, r1, #0x7f
	add.w	r3, r2, #0x10c
	add.w	r0, r3, r4, lsl #5
	ldrb	r4, [r0, #0]
	ldr	r5, .L080037bc
	add.w	r4, r5, r4, lsl #2
	ldr.w	r4, [r4, #0xc00]
	movw	r5, #0xbf8f
	and.w	r3, r4, r5
	eor.w	r3, r3, #0x1000
	eor.w	r3, r3, #0x2000
	orr.w	r4, r3, #0x8000
	orr.w	r4, r4, #0x80
	ldrb	r5, [r0, #0]
	ldr	r6, .L080037bc
	add.w	r5, r6, r5, lsl #2
	str.w	r4, [r5, #0xc00]
	nop
.L080037b6:
	movs	r3, #0
	strb	r3, [r0, #0xb]
	pop	{r4, r5, r6, pc}
.L080037bc:
	.word	0x40005000

@ ----------------------------------------------------------------------------
@ fn_080037c0 - calls fn_08002e68 (0x08002e68) with the first word of the
@ record r0 (the base, 0x40005c00 for 0x200001c8).
@ Callers: 0x08002a0a, 0x08003692.
@ ----------------------------------------------------------------------------
	.section .text.fn_080037c0,"ax",%progbits
	.p2align 2
	.global fn_080037c0
	.thumb_func
	.type fn_080037c0, %function
fn_080037c0:
	push	{r4, lr}
	mov	r4, r0
	ldr	r0, [r4, #0]
	bl	fn_08002e68
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_080037cc - r0 = record, r1 = code; entry = r0 + 0xc + (r1 & 0x7f) * 0x20
@ (halfwords at entry + 8, 0x18, 0x1a, 0x1c; word at entry + 0x14).
@ r1 == 0 and byte [r0 + 0x220] == 2: if [entry + 0x1a] > [entry + 8]:
@   [entry + 0x1a] -= [entry + 8], calls fn_08003dfc (0x08003dfc)
@   (r0, 0, [entry + 0x14], min([entry + 0x1a], [entry + 8])).
@   Else if [entry + 0x18] == [entry + 8] and [entry + 0x1c] >= [entry + 8]
@   and [entry + 0x1c] < halfword [r0 + 0x222]: [entry + 0x18] = 0, calls
@   fn_08003dfc(r0, 0, 0, 0) then fn_08003d88 (0x08003d88)(r0, 0, 0, 0).
@   Else: when [[r0 + 4] + 0xc] is not 0 and byte [r0 + 0x224] == 3 calls it
@   with r0; then calls fn_0800397e (0x0800397e)(r0).
@ r1 == 0 and byte [r0 + 0x220] != 2: nothing.
@ r1 != 0: when [[r0 + 4] + 0x14] is not 0 and byte [r0 + 0x224] == 3 calls it
@   with (r0, r1).
@ No return value. Caller: 0x08003f80 (inside 0x08003f1c).
@ Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080037cc,"ax",%progbits
	.global fn_080037cc
	.thumb_func
	.type fn_080037cc, %function
fn_080037cc:
	push	{r4, r5, r6, lr}
	mov	r5, r0
	mov	r6, r1
	and.w	r1, r6, #0x7f
	add.w	r0, r5, #0xc
	add.w	r4, r0, r1, lsl #5
	cmp	r6, #0
	bne.n	.L0800386c
	ldrb.w	r0, [r5, #0x220]
	cmp	r0, #2
	bne.n	.L08003884
	ldrh	r0, [r4, #0x1a]
	ldrh	r1, [r4, #8]
	cmp	r0, r1
	ble.n	.L08003816
	ldrh	r0, [r4, #0x1a]
	ldrh	r1, [r4, #8]
	subs	r0, r0, r1
	strh	r0, [r4, #0x1a]
	ldrh	r0, [r4, #0x1a]
	ldrh	r1, [r4, #8]
	cmp	r0, r1
	bge.n	.L08003806
	ldrh	r0, [r4, #0x1a]
	b.n	.L08003808
.L08003806:
	ldrh	r0, [r4, #8]
.L08003808:
	mov	r3, r0
	movs	r1, #0
	mov	r0, r5
	ldr	r2, [r4, #0x14]
	bl	fn_08003dfc
	b.n	.L08003884
.L08003816:
	ldrh	r0, [r4, #0x18]
	ldrh	r1, [r4, #8]
	cmp	r0, r1
	bne.n	.L0800384e
	ldrh	r0, [r4, #0x1c]
	ldrh	r1, [r4, #8]
	cmp	r0, r1
	blt.n	.L0800384e
	ldrh	r0, [r4, #0x1c]
	ldrh.w	r1, [r5, #0x222]
	cmp	r0, r1
	bge.n	.L0800384e
	movs	r0, #0
	strh	r0, [r4, #0x18]
	movs	r3, #0
	mov	r2, r3
	mov	r1, r3
	mov	r0, r5
	bl	fn_08003dfc
	movs	r3, #0
	mov	r2, r3
	mov	r1, r6
	mov	r0, r5
	bl	fn_08003d88
	b.n	.L08003884
.L0800384e:
	ldr	r0, [r5, #4]
	ldr	r0, [r0, #0xc]
	cbz	r0, .L08003864
	ldrb.w	r0, [r5, #0x224]
	cmp	r0, #3
	bne.n	.L08003864
	ldr	r0, [r5, #4]
	ldr	r1, [r0, #0xc]
	mov	r0, r5
	blx	r1
.L08003864:
	mov	r0, r5
	bl	fn_0800397e
	b.n	.L08003884
.L0800386c:
	ldr	r0, [r5, #4]
	ldr	r0, [r0, #0x14]
	cbz	r0, .L08003884
	ldrb.w	r0, [r5, #0x224]
	cmp	r0, #3
	bne.n	.L08003884
	ldr	r0, [r5, #4]
	mov	r1, r6
	ldr	r2, [r0, #0x14]
	mov	r0, r5
	blx	r2
.L08003884:
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_08003886 - initialises the record R (r0) from arguments: [R+4] = r2,
@ [R+8] = r3, [R] = r1 (the register block base), byte [R+0x224] = 1; the
@ stack argument at [sp+24] is loaded into r8 and never used.
@ Then calls init_endpoint_entries (0x08003c44)(R) and fn_08002e7a
@ (0x08002e7a)(r1). No return value.
@ Purpose not determined from the code beyond these stores and calls.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003886,"ax",%progbits
	.global fn_08003886
	.thumb_func
	.type fn_08003886, %function
fn_08003886:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r4, r0
	mov	r5, r1
	mov	r6, r2
	mov	r7, r3
	ldr.w	r8, [sp, #0x18]
	str	r6, [r4, #4]
	str	r7, [r4, #8]
	str	r5, [r4, #0]
	movs	r0, #1
	strb.w	r0, [r4, #0x224]
	mov	r0, r4
	bl	init_endpoint_entries
	ldr	r0, [r4, #0]
	bl	fn_08002e7a
	pop.w	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_080038b2 - called with R (r0) and code r1;
@ E = R + 0x10c + (r1 & 0x7f) * 0x20 (OUT entry, layout set by
@ init_endpoint_entries, 0x08003c44).
@ r1 == 0 and byte [R+0x220] == 3: if halfword [E+8] < halfword [E+0x1a]:
@   [E+0x1a] -= [E+8], then fn_08003d88 (0x08003d88)(R, 0, word [E+0x14],
@   min([E+0x1a], [E+8])). Otherwise: when word [[R+4]+0x10] is not 0 it is
@   called with R, then fn_080039be (0x080039be)(R).
@ r1 == 0 and state not 3: nothing.
@ r1 != 0: when word [[R+4]+0x18] is not 0 and byte [R+0x224] == 3, calls it
@   with (R, r1).
@ No return value. Caller: 0x08003f1c at 0x080040d4. Purpose not determined
@ from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_080038b2,"ax",%progbits
	.global fn_080038b2
	.thumb_func
	.type fn_080038b2, %function
fn_080038b2:
	push	{r4, r5, r6, lr}
	mov	r5, r0
	mov	r6, r1
	and.w	r1, r6, #0x7f
	add.w	r0, r5, #0x10c
	add.w	r4, r0, r1, lsl #5
	cbnz	r6, .L08003910
	ldrb.w	r0, [r5, #0x220]
	cmp	r0, #3
	bne.n	.L08003928
	ldrh	r0, [r4, #0x1a]
	ldrh	r1, [r4, #8]
	cmp	r0, r1
	ble.n	.L080038fa
	ldrh	r0, [r4, #0x1a]
	ldrh	r1, [r4, #8]
	subs	r0, r0, r1
	strh	r0, [r4, #0x1a]
	ldrh	r0, [r4, #0x1a]
	ldrh	r1, [r4, #8]
	cmp	r0, r1
	bge.n	.L080038ea
	ldrh	r0, [r4, #0x1a]
	b.n	.L080038ec
.L080038ea:
	ldrh	r0, [r4, #8]
.L080038ec:
	mov	r3, r0
	mov	r1, r6
	mov	r0, r5
	ldr	r2, [r4, #0x14]
	bl	fn_08003d88
	b.n	.L08003928
.L080038fa:
	ldr	r0, [r5, #4]
	ldr	r0, [r0, #0x10]
	cbz	r0, .L08003908
	ldr	r0, [r5, #4]
	ldr	r1, [r0, #0x10]
	mov	r0, r5
	blx	r1
.L08003908:
	mov	r0, r5
	bl	fn_080039be
	b.n	.L08003928
.L08003910:
	ldr	r0, [r5, #4]
	ldr	r0, [r0, #0x18]
	cbz	r0, .L08003928
	ldrb.w	r0, [r5, #0x224]
	cmp	r0, #3
	bne.n	.L08003928
	ldr	r0, [r5, #4]
	mov	r1, r6
	ldr	r2, [r0, #0x18]
	mov	r0, r5
	blx	r2
.L08003928:
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_0800392a - called with R (r0) and endpoint r1 (r1 is not used); runs
@ after 0x08003f1c has copied 8 bytes to R+0x214.
@ Calls copy_8_bytes (0x080045c0)(R+0x20c, R+0x214) (8-byte copy),
@ byte [R+0x220] = 1, halfword [R+0x222] = halfword [R+0x212].
@ Dispatch on byte [R+0x20c] & 0x1f: 0 calls fn_080039ec (0x080039ec)(R),
@ 1 calls fn_080042d6 (0x080042d6)(R), 2 calls fn_08003a78 (0x08003a78)(R),
@ other values do nothing. No return value.
@ Caller: 0x08003f1c at 0x08003ffc. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800392a,"ax",%progbits
	.global fn_0800392a
	.thumb_func
	.type fn_0800392a, %function
fn_0800392a:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	add.w	r1, r4, #0x214
	add.w	r0, r4, #0x20c
	bl	copy_8_bytes
	movs	r0, #1
	strb.w	r0, [r4, #0x220]
	movw	r0, #0x212
	ldrh	r0, [r0, r4]
	strh.w	r0, [r4, #0x222]
	ldrb.w	r0, [r4, #0x20c]
	and.w	r0, r0, #0x1f
	cbz	r0, .L08003960
	cmp	r0, #1
	beq.n	.L08003968
	cmp	r0, #2
	bne.n	.L08003978
	b.n	.L08003970
.L08003960:
	mov	r0, r4
	bl	fn_080039ec
	b.n	.L0800397a
.L08003968:
	mov	r0, r4
	bl	fn_080042d6
	b.n	.L0800397a
.L08003970:
	mov	r0, r4
	bl	fn_08003a78
	b.n	.L0800397a
.L08003978:
	nop
.L0800397a:
	nop
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_0800397e - sets byte [R+0x220] = 5 (R = r0), then calls fn_08003d88
@ (0x08003d88)(R, 0, 0, 0): arms OUT endpoint 0 for a receive of length 0.
@ No return value. Caller: 0x080037cc.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800397e,"ax",%progbits
	.global fn_0800397e
	.thumb_func
	.type fn_0800397e, %function
fn_0800397e:
	push	{r4, lr}
	mov	r4, r0
	movs	r0, #5
	strb.w	r0, [r4, #0x220]
	movs	r3, #0
	mov	r2, r3
	mov	r1, r3
	mov	r0, r4
	bl	fn_08003d88
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08003996 - control-endpoint send helper: r0 = R, r1 = buffer pointer,
@ r2 = length. Stores the low halfword of r2 at [R+0x28] and [R+0x26],
@ byte [R+0x220] = 2, then fn_08003dfc (0x08003dfc)(R, 0, r1, r2) (queues the
@ data on IN endpoint 0). No return value.
@ Callers: 0x08001478, 0x080040f8, 0x0800414e, 0x08003a78, 0x08004254.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003996,"ax",%progbits
	.global fn_08003996
	.thumb_func
	.type fn_08003996, %function
fn_08003996:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r5, r0
	mov	r6, r1
	mov	r4, r2
	add.w	r7, r5, #0xc
	strh	r4, [r7, #0x1c]
	strh	r4, [r7, #0x1a]
	movs	r0, #2
	strb.w	r0, [r5, #0x220]
	mov	r3, r4
	mov	r2, r6
	movs	r1, #0
	mov	r0, r5
	bl	fn_08003dfc
	pop.w	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_080039be - sets byte [R+0x220] = 4 (R = r0), then calls fn_08003dfc
@ (0x08003dfc)(R, 0, 0, 0): queues a transfer of length 0 on IN endpoint 0.
@ No return value.
@ Callers: 0x080038b2, 0x08003a78, 0x080042d6, 0x080043f0, 0x08004444,
@ 0x0800450c, 0x080036dc, 0x08001478.
@ ----------------------------------------------------------------------------
	.section .text.fn_080039be,"ax",%progbits
	.global fn_080039be
	.thumb_func
	.type fn_080039be, %function
fn_080039be:
	push	{r4, lr}
	mov	r4, r0
	movs	r0, #4
	strb.w	r0, [r4, #0x220]
	movs	r3, #0
	mov	r2, r3
	mov	r1, r3
	mov	r0, r4
	bl	fn_08003dfc
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_080039d6 - calls fn_08004538 (0x08004538)(R, 0) and fn_08004538(R, 0x80)
@ (R = r0): sets the stall bits of OUT endpoint 0 and IN endpoint 0 (see
@ 0x08004538). No return value.
@ Used as the error path of the request handlers 0x080039ec, 0x08003a78,
@ 0x080042d6, 0x080043f0, 0x08004444, 0x0800414e, 0x080040f8, 0x08004254;
@ also called from 0x080036dc and 0x08001478.
@ ----------------------------------------------------------------------------
	.section .text.fn_080039d6,"ax",%progbits
	.global fn_080039d6
	.thumb_func
	.type fn_080039d6, %function
fn_080039d6:
	push	{r4, lr}
	mov	r4, r0
	movs	r1, #0
	mov	r0, r4
	bl	fn_08004538
	movs	r1, #0x80
	mov	r0, r4
	bl	fn_08004538
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_080039ec - request handler for byte [R+0x20c] & 0x1f == 0 (R = r0).
@ If byte [R+0x20c] & 0x60 is 0: switch on byte [R+0x20d]: 0 calls
@ fn_08004254 (0x08004254), 1 calls fn_080036dc (0x080036dc), 3 calls
@ fn_0800450c (0x0800450c), 5 calls fn_080043f0 (0x080043f0), 6 calls
@ fn_0800414e (0x0800414e), 8 calls fn_080040f8 (0x080040f8), 9 calls
@ fn_08004444 (0x08004444), any other value (2, 4, 7, 10 up) calls
@ fn_080039d6 (0x080039d6); each with R (tbb jump table at 0x08003a1c).
@ If the & 0x60 value is not 0: calls the function at [[R+4]+8] with
@ (R, R+0x20c). Returns 0.
@ Caller: 0x0800392a. Purpose of each case: see the handler entries.
@ ----------------------------------------------------------------------------
	.section .text.fn_080039ec,"ax",%progbits
	.p2align 2
	.global fn_080039ec
	.thumb_func
	.type fn_080039ec, %function
fn_080039ec:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r5, #0
	add.w	r6, r4, #0x20c
	ldrb	r0, [r6, #0]
	and.w	r0, r0, #0x60
	cbz	r0, .L08003a0e
	ldr	r0, [r4, #4]
	add.w	r1, r4, #0x20c
	ldr	r2, [r0, #8]
	mov	r0, r4
	blx	r2
	mov	r0, r5
.L08003a0c:
	pop	{r4, r5, r6, pc}
.L08003a0e:
	movw	r0, #0x20d
	ldrb	r0, [r0, r4]
	cmp	r0, #0xa
	bcs.n	.L08003a5e
	tbb	[pc, r0]
.L08003a1c:
	.byte	(.L08003a26 - .L08003a1c)/2	@ case 0
	.byte	(.L08003a2e - .L08003a1c)/2	@ case 1
	.byte	(.L08003a5e - .L08003a1c)/2	@ case 2
	.byte	(.L08003a36 - .L08003a1c)/2	@ case 3
	.byte	(.L08003a5e - .L08003a1c)/2	@ case 4
	.byte	(.L08003a3e - .L08003a1c)/2	@ case 5
	.byte	(.L08003a46 - .L08003a1c)/2	@ case 6
	.byte	(.L08003a5e - .L08003a1c)/2	@ case 7
	.byte	(.L08003a4e - .L08003a1c)/2	@ case 8
	.byte	(.L08003a56 - .L08003a1c)/2	@ case 9
.L08003a26:
	mov	r0, r4
	bl	fn_08004254
	b.n	.L08003a66
.L08003a2e:
	mov	r0, r4
	bl	fn_080036dc
	b.n	.L08003a66
.L08003a36:
	mov	r0, r4
	bl	fn_0800450c
	b.n	.L08003a66
.L08003a3e:
	mov	r0, r4
	bl	fn_080043f0
	b.n	.L08003a66
.L08003a46:
	mov	r0, r4
	bl	fn_0800414e
	b.n	.L08003a66
.L08003a4e:
	mov	r0, r4
	bl	fn_080040f8
	b.n	.L08003a66
.L08003a56:
	mov	r0, r4
	bl	fn_08004444
	b.n	.L08003a66
.L08003a5e:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L08003a66:
	nop
	mov	r0, r5
	b.n	.L08003a0c

@ ----------------------------------------------------------------------------
@ fn_08003a6c - calls fn_08002e9e (0x08002e9e)(word [r0]) (r0 = R, the first
@ word of R is the register block base). No return value.
@ Caller: 0x08003678.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003a6c,"ax",%progbits
	.p2align 2
	.global fn_08003a6c
	.thumb_func
	.type fn_08003a6c, %function
fn_08003a6c:
	push	{r4, lr}
	mov	r4, r0
	ldr	r0, [r4, #0]
	bl	fn_08002e9e
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08003a78 - request handler for byte [R+0x20c] & 0x1f == 2 (R = r0);
@ b = byte [R+0x210], e = b & 0x7f.
@ If byte [R+0x20c] & 0x60 == 0x20: calls [[R+4]+8](R, R+0x20c) first.
@ Request byte [R+0x20d] == 0: state [R+0x224] == 2: when e != 0 calls
@   fn_08004538 (0x08004538)(R, b); state == 3: entry = R+0x10c+e*0x20 when b
@   bit 7 is clear, else R+0xc+e*0x20; halfword [entry+0xc] = 1 when byte
@   [entry+0xb] == 1, else 0; calls fn_08003996 (0x08003996)(R, entry+0xc, 2);
@   other state: fn_080039d6 (0x080039d6).
@ == 1: state 2: when b is neither 0 nor 0x80 calls fn_08004538(R, b);
@   state 3: when halfword [R+0x20e] == 0: when e != 0 calls fn_08003730
@   (0x08003730)(R, b) then [[R+4]+8](R, R+0x20c); then fn_080039be
@   (0x080039be)(R); other state: fn_080039d6.
@ == 3: state 2: when b is neither 0 nor 0x80 calls fn_08004538(R, b);
@   state 3: when halfword [R+0x20e] == 0 and b is neither 0 nor 0x80 calls
@   fn_08004538(R, b); then always [[R+4]+8](R, R+0x20c) and fn_080039be(R);
@   other state: fn_080039d6.
@ Any other request byte: fn_080039d6. Returns 0.
@ Caller: 0x0800392a.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003a78,"ax",%progbits
	.p2align 2
	.global fn_08003a78
	.thumb_func
	.type fn_08003a78, %function
fn_08003a78:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r4, r0
	mov.w	r8, #0
	add.w	r7, r4, #0x20c
	ldrb	r5, [r7, #4]
	ldrb	r0, [r7, #0]
	and.w	r0, r0, #0x60
	cmp	r0, #0x20
	bne.n	.L08003a9e
	ldr	r0, [r4, #4]
	add.w	r1, r4, #0x20c
	ldr	r2, [r0, #8]
	mov	r0, r4
	blx	r2
.L08003a9e:
	ldrb	r0, [r7, #1]
	cbz	r0, .L08003aac
	cmp	r0, #1
	beq.n	.L08003b12
	cmp	r0, #3
	bne.n	.L08003ba6
	b.n	.L08003b62
.L08003aac:
	ldrb.w	r0, [r4, #0x224]
	cmp	r0, #2
	beq.n	.L08003aba
	cmp	r0, #3
	bne.n	.L08003b06
	b.n	.L08003aca
.L08003aba:
	and.w	r0, r5, #0x7f
	cbz	r0, .L08003ac8
	mov	r1, r5
	mov	r0, r4
	bl	fn_08004538
.L08003ac8:
	b.n	.L08003b0e
.L08003aca:
	and.w	r0, r5, #0x80
	cbz	r0, .L08003ade
	and.w	r1, r5, #0x7f
	add.w	r0, r4, #0xc
	add.w	r6, r0, r1, lsl #5
	b.n	.L08003aea
.L08003ade:
	and.w	r1, r5, #0x7f
	add.w	r0, r4, #0x10c
	add.w	r6, r0, r1, lsl #5
.L08003aea:
	ldrb	r0, [r6, #0xb]
	cmp	r0, #1
	bne.n	.L08003af4
	strh	r0, [r6, #0xc]
	b.n	.L08003af8
.L08003af4:
	movs	r0, #0
	strh	r0, [r6, #0xc]
.L08003af8:
	movs	r2, #2
	add.w	r1, r6, #0xc
	mov	r0, r4
	bl	fn_08003996
	b.n	.L08003b0e
.L08003b06:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L08003b0e:
	nop
	b.n	.L08003bbc
.L08003b12:
	ldrb.w	r0, [r4, #0x224]
	cmp	r0, #2
	beq.n	.L08003b20
	cmp	r0, #3
	bne.n	.L08003b56
	b.n	.L08003b30
.L08003b20:
	cbz	r5, .L08003b2e
	cmp	r5, #0x80
	beq.n	.L08003b2e
	mov	r1, r5
	mov	r0, r4
	bl	fn_08004538
.L08003b2e:
	b.n	.L08003b5e
.L08003b30:
	ldrh	r0, [r7, #2]
	cbnz	r0, .L08003b54
	and.w	r0, r5, #0x7f
	cbz	r0, .L08003b4e
	mov	r1, r5
	mov	r0, r4
	bl	fn_08003730
	ldr	r0, [r4, #4]
	add.w	r1, r4, #0x20c
	ldr	r2, [r0, #8]
	mov	r0, r4
	blx	r2
.L08003b4e:
	mov	r0, r4
	bl	fn_080039be
.L08003b54:
	b.n	.L08003b5e
.L08003b56:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L08003b5e:
	nop
	b.n	.L08003bbc
.L08003b62:
	ldrb.w	r0, [r4, #0x224]
	cmp	r0, #2
	beq.n	.L08003b70
	cmp	r0, #3
	bne.n	.L08003ba8
	b.n	.L08003b80
.L08003b70:
	cbz	r5, .L08003b7e
	cmp	r5, #0x80
	beq.n	.L08003b7e
	mov	r1, r5
	mov	r0, r4
	bl	fn_08004538
.L08003b7e:
	b.n	.L08003bb0
.L08003b80:
	ldrh	r0, [r7, #2]
	cbnz	r0, .L08003b92
	cbz	r5, .L08003b92
	cmp	r5, #0x80
	beq.n	.L08003b92
	mov	r1, r5
	mov	r0, r4
	bl	fn_08004538
.L08003b92:
	ldr	r0, [r4, #4]
	add.w	r1, r4, #0x20c
	ldr	r2, [r0, #8]
	mov	r0, r4
	blx	r2
	mov	r0, r4
	bl	fn_080039be
	b.n	.L08003bb0
.L08003ba6:
	b.n	.L08003bb4
.L08003ba8:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L08003bb0:
	nop
	b.n	.L08003bbc
.L08003bb4:
	mov	r0, r4
	bl	fn_080039d6
	nop
.L08003bbc:
	nop
	mov	r0, r8
	pop.w	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_08003bc4 - calls fn_08002eb4 (0x08002eb4)(word [r0]) (r0 = R, first word
@ of R is the register block base). No return value.
@ Caller: 0x080045fc.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003bc4,"ax",%progbits
	.p2align 2
	.global fn_08003bc4
	.thumb_func
	.type fn_08003bc4, %function
fn_08003bc4:
	push	{r4, lr}
	mov	r4, r0
	ldr	r0, [r4, #0]
	bl	fn_08002eb4
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08003bd0 - allocates buffer offsets for the endpoint entry E (r0 = E,
@ layout of init_endpoint_entries, 0x08003c44).
@ Byte [E+10] == 0: when byte [E+2] == 1 and halfword [E+4] == 0,
@   [E+4] = halfword_200000c0_fetch_add (0x08002d94)(halfword [E+8]); when
@   byte [E+2] != 1 and halfword [E+6] == 0, [E+6] =
@   halfword_200000c0_fetch_add(halfword [E+8]).
@ Byte [E+10] != 0: each of [E+4] and [E+6] that is 0 gets
@   halfword_200000c0_fetch_add(halfword [E+8]).
@ 0x08002d94 returns the halfword at 0x200000c0 and adds its argument to it.
@ No return value. Caller: 0x08003d2e.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003bd0,"ax",%progbits
	.p2align 2
	.global fn_08003bd0
	.thumb_func
	.type fn_08003bd0, %function
fn_08003bd0:
	push	{r4, lr}
	mov	r4, r0
	ldrb	r0, [r4, #0xa]
	cbnz	r0, .L08003bfa
	ldrb	r0, [r4, #2]
	cmp	r0, #1
	bne.n	.L08003bec
	ldrh	r0, [r4, #4]
	cbnz	r0, .L08003c12
	ldrh	r0, [r4, #8]
	bl	halfword_200000c0_fetch_add
	strh	r0, [r4, #4]
	b.n	.L08003c12
.L08003bec:
	ldrh	r0, [r4, #6]
	cbnz	r0, .L08003c12
	ldrh	r0, [r4, #8]
	bl	halfword_200000c0_fetch_add
	strh	r0, [r4, #6]
	b.n	.L08003c12
.L08003bfa:
	ldrh	r0, [r4, #4]
	cbnz	r0, .L08003c06
	ldrh	r0, [r4, #8]
	bl	halfword_200000c0_fetch_add
	strh	r0, [r4, #4]
.L08003c06:
	ldrh	r0, [r4, #6]
	cbnz	r0, .L08003c12
	ldrh	r0, [r4, #8]
	bl	halfword_200000c0_fetch_add
	strh	r0, [r4, #6]
.L08003c12:
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08003c14 - r0 = R, r1 = code. E = R + 0xc + (r1 & 0x7f) * 0x20 when r1
@ bit 7 is set, else R + 0x10c + (r1 & 0x7f) * 0x20. Calls fn_08002ecc
@ (0x08002ecc)(word [R], E). No return value.
@ Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08003c14,"ax",%progbits
	.p2align 2
	.global fn_08003c14
	.thumb_func
	.type fn_08003c14, %function
fn_08003c14:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	and.w	r0, r5, #0x80
	cbz	r0, .L08003c2e
	and.w	r1, r5, #0x7f
	add.w	r0, r4, #0xc
	add.w	r6, r0, r1, lsl #5
	b.n	.L08003c3a
.L08003c2e:
	and.w	r1, r5, #0x7f
	add.w	r0, r4, #0x10c
	add.w	r6, r0, r1, lsl #5
.L08003c3a:
	mov	r1, r6
	ldr	r0, [r4, #0]
	bl	fn_08002ecc
	pop	{r4, r5, r6, pc}

