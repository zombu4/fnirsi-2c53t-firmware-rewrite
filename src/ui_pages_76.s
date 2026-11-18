@ ui_pages_76.s - screen drawing routines: header image with text, six-row list, three value rows, bottom value panel.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08015740 - draws an image file and the title "Signal Generator" over it at
@ the top of the screen.
@ No parameters, no return value.
@ Calls decode_image_file_with_offset (08039f6c) with
@ ("3:/System file/88.jpg", 0x34, 0), then draw_wrapped_text_in_box (0800f154)
@ with (0x34, 0, 0xd8, 0x14, "Signal Generator", font block 0x20001144, colour
@ 0xffff, flag 1) (V1.2.0 took the text from a language row).
@ ----------------------------------------------------------------------------
	.section .text.fn_08015740,"ax",%progbits
	.p2align 2
	.global fn_08015740
	.thumb_func
	.type fn_08015740, %function
fn_08015740:
	push	{r7, lr}
	sub	sp, #0x10
	movw	r0, #:lower16:t_080bc612		@ image path string
	movt	r0, #:upper16:t_080bc612
	movs	r1, #0x34
	movs	r2, #0
	bl	decode_image_file_with_offset
	movw	r0, #:lower16:t_080bcbab		@ "Signal Generator"
	movt	r0, #:upper16:t_080bcbab
	movw	r2, #0x1144
	movw	r1, #0xffff				@ colour 0xffff
	movt	r2, #0x2000				@ font block 0x20001144
	mov.w	r12, #1
	strd	r0, r2, [sp]
	str	r1, [sp, #8]
	movs	r0, #0x34
	movs	r1, #0
	movs	r2, #0xd8
	movs	r3, #0x14
	str.w	r12, [sp, #0xc]				@ flag 1
	bl	draw_wrapped_text_in_box
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000					@ padding

@ ----------------------------------------------------------------------------
@ draw_six_row_list_from_first_index - draws a six-row text list in which the
@ row whose index equals byte 0x20000f51 is shown on the 89.jpg image (the
@ highlighted row) and the other rows on a gradient.
@ No parameters, no return value.
@ Unrolled six times for rows at x=0 and y=0x18,0x3c,0x60,0x84,0xa8,0xcc (step
@ 0x24). first = byte 0x20001062 (compared as unsigned with byte 0x20000f51,
@ called last).
@ Row i: if first+i == last it calls decode_image_file_with_offset (08039f6c)
@ ("3:/System file/89.jpg", 0, y), otherwise draw_gradient_bar (08020134)
@ (y, y+0x23) (e.g. 0x18, 0x3b).
@ Then draw_wrapped_text_in_box (0800f154)(0, y, 100, 0x24, word first+i of the
@ English waveform name table d_0804c61c, font block 0x20001114, colour 0xffff,
@ flag 1).
@ ----------------------------------------------------------------------------
	.section .text.draw_six_row_list_from_first_index,"ax",%progbits
	.p2align 2
	.global draw_six_row_list_from_first_index
	.thumb_func
	.type draw_six_row_list_from_first_index, %function
draw_six_row_list_from_first_index:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	sub	sp, #0x10
	movw	r4, #0xf8
	movt	r4, #0x2000				@ r4 = 0x200000f8 (RAM base)
	ldrb.w	r6, [r4, #0xe59]			@ last = byte 0x20000f51
	ldrb.w	r7, [r4, #0xf6a]			@ first = byte 0x20001062
	cmp	r7, r6
	bne.n	.L080157c8
	movw	r0, #:lower16:t_080bc655		@ "3:/System file/89.jpg"
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0x18
	bl	decode_image_file_with_offset
	b.n	.L080157d0
.L080157c8:
	movs	r0, #0x18
	movs	r1, #0x3b
	bl	draw_gradient_bar
.L080157d0:
	movw	r9, #:lower16:d_0804c61c		@ English waveform names
	movt	r9, #:upper16:d_0804c61c
	ldr.w	r0, [r9, r7, lsl #2]			@ name of waveform first
	movw	r10, #0x1114
	movs	r1, #1
	movt	r10, #0x2000				@ font block 0x20001114
	movw	r8, #0xffff				@ colour 0xffff
	strd	r0, r10, [sp]
	str	r1, [sp, #0xc]
	movs	r0, #0
	movs	r1, #0x18
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	adds	r5, r7, #1
	cmp	r5, r6
	bne.n	.L08015826
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0x3c
	bl	decode_image_file_with_offset
	b.n	.L0801582e
.L08015826:
	movs	r0, #0x3c
	movs	r1, #0x5f
	bl	draw_gradient_bar
.L0801582e:
	ldr.w	r0, [r9, r5, lsl #2]			@ name of waveform r5
	movs	r1, #1
	strd	r0, r10, [sp]
	str	r1, [sp, #0xc]
	movs	r0, #0
	movs	r1, #0x3c
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	adds	r5, r7, #2
	cmp	r5, r6
	bne.n	.L08015870
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0x60
	bl	decode_image_file_with_offset
	b.n	.L08015878
.L08015870:
	movs	r0, #0x60
	movs	r1, #0x83
	bl	draw_gradient_bar
.L08015878:
	ldr.w	r0, [r9, r5, lsl #2]			@ name of waveform r5
	movs	r1, #1
	strd	r0, r10, [sp]
	str	r1, [sp, #0xc]
	movs	r0, #0
	movs	r1, #0x60
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	adds	r5, r7, #3
	cmp	r5, r6
	bne.n	.L080158ba
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0x84
	bl	decode_image_file_with_offset
	b.n	.L080158c2
.L080158ba:
	movs	r0, #0x84
	movs	r1, #0xa7
	bl	draw_gradient_bar
.L080158c2:
	ldr.w	r0, [r9, r5, lsl #2]			@ name of waveform r5
	movs	r1, #1
	strd	r0, r10, [sp]
	str	r1, [sp, #0xc]
	movs	r0, #0
	movs	r1, #0x84
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	adds	r5, r7, #4
	cmp	r5, r6
	bne.n	.L08015904
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0xa8
	bl	decode_image_file_with_offset
	b.n	.L0801590c
.L08015904:
	movs	r0, #0xa8
	movs	r1, #0xcb
	bl	draw_gradient_bar
.L0801590c:
	ldr.w	r0, [r9, r5, lsl #2]			@ name of waveform r5
	movs	r1, #1
	strd	r0, r10, [sp]
	str	r1, [sp, #0xc]
	movs	r0, #0
	movs	r1, #0xa8
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	adds	r5, r7, #5
	cmp	r5, r6
	bne.n	.L0801594e
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0xcc
	bl	decode_image_file_with_offset
	b.n	.L08015956
.L0801594e:
	movs	r0, #0xcc
	movs	r1, #0xef
	bl	draw_gradient_bar
.L08015956:
	ldr.w	r0, [r9, r5, lsl #2]			@ name of waveform r5
	movs	r7, #1
	strd	r0, r10, [sp]
	movs	r0, #0
	movs	r1, #0xcc
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add	sp, #0x10
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
	.short	0x0000					@ padding

@ ----------------------------------------------------------------------------
@ draw_three_value_rows - draws three rows each with a label text, a value text
@ and a unit text; for the row selected when byte 0x20001061 == 2 it calls
@ draw_text_column_with_char_highlight (0800e64c) with a digit position
@ (08015b9c..08015ba2). What the rows and values mean is not determined from
@ the code.
@ No parameters, no return value.
@ Loop i=0..2, row y=i*0x20+0x8e (sign-extended), x=0x7a;
@ sel = byte 0x20001063 & 0xf, edit = byte 0x20001061.
@ Draws decode_image_file_with_offset (08039f6c)
@ ("3:/System file/116.jpg", 0x7a, y) when edit != 0 and i == sel, else
@ "117.jpg".
@ Colour index idx: for row 1 with byte 0x20000f51 - 1 >= 2 (unsigned) idx = 0;
@ otherwise idx = 1 when edit == 0, and when edit != 0 idx = 3 for i == sel and
@ 1 for the other rows. Label colour = halfword at 0x080be30a + idx*2 (0x8c73,
@ 0xffff, 0x055f, 0x0000 for idx 0..3); the unit colour uses idx with 3
@ replaced by 1.
@ Label: draw_wrapped_text_in_box (0800f154)(0x7a, y, 0x36, 0x16, word i of
@ the English label table d_0804c5bc, font 0x20001114, label colour,
@ flag 1); unit: 0800f154(0x10e, y, 0x14, 0x16, word at 0x08015be0 + i*4 ("Hz",
@ "%", "V"), font 0x20001114, unit colour, flag 1).
@ Value text into 0x20008360 via format_to_buffer_080073b4: i=0 "%02d %03d" of
@ (0x20000f54/1000, 0x20000f54%1000); i=1 "%03d" of 0x20000f58; i=2 "%d.%d" of
@ (0x20000f59/10, 0x20000f59%10).
@ Normal case: 0800f154(0xb0, y, 0x5e, 0x16, 0x20008360, font 0x20001114, unit
@ colour, 1). When edit == 2 and i == sel it calls 0800e64c(y, pos, unit
@ colour) instead, pos = 0 for i=2 when nibble (0x20001063>>4) == 1 else
@ 2-(0x20001063>>4); i=1: 2-(0x20001063>>4); i=0: 6-((0x20001063>>4)+1) when
@ byte 0x20001063 <= 0x2f, 6-((0x20001063>>4)+2) when above 0x2f.
@ ----------------------------------------------------------------------------
	.section .text.draw_three_value_rows,"ax",%progbits
	.p2align 2
	.global draw_three_value_rows
	.thumb_func
	.type draw_three_value_rows, %function
draw_three_value_rows:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0x14
	movw	r5, #0xf8
	mov.w	r8, #0
	movt	r5, #0x2000				@ r5 = 0x200000f8 (RAM base)
	mov.w	r9, #0
	b.n	.L080159d6
.L080159a0:
	movw	r0, #0x8360
	movt	r0, #0x2000				@ value text buffer 0x20008360
	str	r0, [sp]
	movw	r0, #0x1114
	movt	r0, #0x2000				@ font block 0x20001114
	strd	r0, r6, [sp, #4]
	movs	r0, #0xb0
	mov	r1, r10
	movs	r2, #0x5e
	movs	r3, #0x16
	movs	r7, #1
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L080159c6:
	add.w	r8, r8, #1
	cmp.w	r8, #3
	add.w	r9, r9, #1
	beq.w	.L08015ba8
.L080159d6:
	ldrb.w	r0, [r5, #0xf69]			@ edit = byte 0x20001061
	cbz	r0, .L080159f4
	ldrb.w	r0, [r5, #0xf6b]			@ byte 0x20001063
	and.w	r0, r0, #0xf				@ sel
	cmp	r8, r0
	bne.n	.L080159f4
	movs	r0, #0x8e
	add.w	r4, r0, r8, lsl #5
	uxth	r2, r4
	adr	r0, .L08015bb0				@ "116.jpg" (selected row)
	b.n	.L080159fe
.L080159f4:
	movs	r0, #0x8e
	add.w	r4, r0, r8, lsl #5
	uxth	r2, r4
	adr	r0, .L08015bc8				@ "117.jpg"
.L080159fe:
	movs	r1, #0x7a
	bl	decode_image_file_with_offset
	ldrb.w	r2, [r5, #0xf69]
	ldrb.w	r0, [r5, #0xe59]
	ldrb.w	r3, [r5, #0xf6b]
	cmp	r2, #0
	mov.w	r2, #3
	it	eq
	moveq	r2, #1
	subs	r0, #1
	subs.w	r7, r8, #1
	it	ne
	movne	r7, r2
	cmp	r0, #2
	and.w	r0, r3, #0xf
	it	cc
	movcc	r7, r2
	cmp	r8, r0
	mov.w	r6, #1
	movw	r1, #:lower16:d_0804c5bc		@ English labels Frequency, Duty Cycle, Amplitude
	it	eq
	moveq	r6, #3
	movt	r1, #:upper16:d_0804c5bc
	cmp	r7, #3
	it	ne
	movne	r6, r7
	movw	r7, #:lower16:d_080be30a
	movt	r7, #:upper16:d_080be30a
	ldr.w	r0, [r1, r8, lsl #2]			@ label of row i
	ldrh.w	r1, [r7, r6, lsl #1]
	movw	r11, #0x1114
	movt	r11, #0x2000
	sxth.w	r10, r4
	str	r0, [sp]
	strd	r11, r1, [sp, #4]
	movs	r0, #0x7a
	mov	r1, r10
	movs	r2, #0x36
	movs	r3, #0x16
	movs	r4, #1
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	adr	r0, .L08015be0				@ unit string pointer table
	cmp	r6, #3
	it	eq
	moveq	r6, #1
	ldr.w	r0, [r0, r8, lsl #2]
	ldrh.w	r6, [r7, r6, lsl #1]
	strd	r0, r11, [sp]
	mov.w	r0, #0x10e
	mov	r1, r10
	movs	r2, #0x14
	movs	r3, #0x16
	str	r6, [sp, #8]
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb.w	r11, [r5, #0xf6b]
	and.w	r0, r9, #0x7f
	lsr.w	r7, r11, #4
	cmp	r0, #2
	add.w	r4, r4, r11, lsr #4
	beq.n	.L08015b50
	cmp	r0, #1
	beq.n	.L08015b20
	cmp	r0, #0
	bne.w	.L080159c6
	ldr.w	r0, [r5, #0xe5c]
	movw	r1, #0x4dd3
	movt	r1, #0x1062
	umull	r1, r2, r0, r1
	movw	r1, #0xfc18
	lsrs	r2, r2, #6
	movt	r1, #0xffff
	mla	r3, r2, r1, r0
	movw	r0, #0x8360
	movt	r0, #0x2000
	adr	r1, .L08015bfc				@ "%02d %03d"
	bl	format_to_buffer_080073b4
	ldrb.w	r0, [r5, #0xf69]
	cmp	r0, #2
	bne.w	.L080159a0
	ldrb.w	r0, [r5, #0xf6b]
	and.w	r0, r0, #0xf
	cmp	r8, r0
	bne.w	.L080159a0
	cmp.w	r11, #0x2f
	it	hi
	addhi	r4, r7, #2
	rsb.w	r0, r4, #6
	b.n	.L08015b9c
	.byte	0x00, 0xbf				@ padding
.L08015b20:
	ldrb.w	r2, [r5, #0xe60]
	movw	r0, #0x8360
	movt	r0, #0x2000
	adr	r1, .L08015bf4				@ "%03d"
	bl	format_to_buffer_080073b4
	ldrb.w	r0, [r5, #0xf69]
	cmp	r0, #2
	bne.w	.L080159a0
	ldrb.w	r0, [r5, #0xf6b]
	and.w	r0, r0, #0xf
	cmp	r8, r0
	bne.w	.L080159a0
	rsb.w	r0, r7, #2
	b.n	.L08015b9c
.L08015b50:
	ldrb.w	r0, [r5, #0xe61]
	movw	r2, #0xcccd
	uxtb	r1, r0
	movt	r2, #0xcccc
	umull	r1, r2, r1, r2
	lsrs	r2, r2, #3
	add.w	r1, r2, r2, lsl #2
	sub.w	r0, r0, r1, lsl #1
	uxtb	r3, r0
	movw	r0, #0x8360
	movt	r0, #0x2000
	adr	r1, .L08015bec				@ "%d.%d"
	bl	format_to_buffer_080073b4
	ldrb.w	r0, [r5, #0xf69]
	cmp	r0, #2
	bne.w	.L080159a0
	ldrb.w	r0, [r5, #0xf6b]
	and.w	r0, r0, #0xf
	cmp	r8, r0
	bne.w	.L080159a0
	subs	r0, r4, #2
	it	ne
	rsbne.w	r0, r7, #2
.L08015b9c:
	uxtb	r1, r0
	mov	r0, r10
	mov	r2, r6
	bl	draw_text_column_with_char_highlight
	b.n	.L080159c6
.L08015ba8:
	add	sp, #0x14
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.byte	0x00, 0xbf				@ padding
.L08015bb0:
	.asciz	"3:/System file/116.jpg"
	.byte	0x00					@ padding
.L08015bc8:
	.asciz	"3:/System file/117.jpg"
	.byte	0x00					@ padding
.L08015be0:
	.word	t_080bcee6				@ unit string pointer, row 0: "Hz"
	.word	t_080bb5ef				@ unit string pointer, row 1: "%"
	.word	t_080bbd2e				@ unit string pointer, row 2: "V"
.L08015bec:
	.asciz	"%d.%d"
	.short	0x0000					@ padding
.L08015bf4:
	.asciz	"%03d"
	.byte	0x00, 0x00, 0x00			@ padding
.L08015bfc:
	.asciz	"%02d %03d"
	.short	0x0000					@ padding

@ ----------------------------------------------------------------------------
@ draw_header_image_120 - draws an image file and an indexed text over it at the
@ top of the screen; the screen it belongs to is not determined from the code.
@ No parameters, no return value.
@ Calls decode_image_file_with_offset (08039f6c)
@ ("3:/System file/120.jpg", 0x34, 0), then draw_wrapped_text_in_box (0800f154)
@ (0x34, 0, 0xd8, 0x1d, word byte(0x20001026) of the English function name
@ table d_0804c43c, font block 0x200011a4, colour 0xffff, flag 1).
@ ----------------------------------------------------------------------------
	.section .text.draw_header_image_120,"ax",%progbits
	.p2align 2
	.global draw_header_image_120
	.thumb_func
	.type draw_header_image_120, %function
draw_header_image_120:
	push	{r7, lr}
	sub	sp, #0x10
	movw	r0, #:lower16:t_080bc3fb		@ image path string
	movt	r0, #:upper16:t_080bc3fb
	movs	r1, #0x34
	movs	r2, #0
	bl	decode_image_file_with_offset
	movw	r0, #0xf8
	movt	r0, #0x2000				@ r0 = 0x200000f8 (RAM base)
	movw	r2, #:lower16:d_0804c43c		@ English multimeter function names
	ldrb.w	r0, [r0, #0xf2e]			@ byte 0x20001026
	movt	r2, #:upper16:d_0804c43c
	ldr.w	r0, [r2, r0, lsl #2]			@ name of function [0x20001026]
	movw	r2, #0x11a4
	movw	r1, #0xffff				@ colour 0xffff
	movt	r2, #0x2000				@ font block 0x200011a4
	mov.w	r12, #1
	strd	r0, r2, [sp]
	str	r1, [sp, #8]
	movs	r0, #0x34
	movs	r1, #0
	movs	r2, #0xd8
	movs	r3, #0x1d
	str.w	r12, [sp, #0xc]				@ flag 1
	bl	draw_wrapped_text_in_box
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000					@ padding

@ ----------------------------------------------------------------------------
@ draw_value_panel - draws a three-column bottom panel of label and formatted
@ value with unit.
@ No parameters, no return value.
@ Calls draw_4bpp_bitmap (0801ffcc)(10, 0xb8, 300, 0x34, bitmap 0x0804de88,
@ colour 0xffff), then three columns x=10, 0x6e, 0xd2 (col c=0,1,2).
@ Label: draw_wrapped_text_in_box (0800f154)(x, 0xc0, 100, 0x14, word c of the
@ English label table d_0804c3d8 (MAX, MEAN, MIN), font block 0x20001144,
@ colour 0x6bb0, flag 1).
@ Value: if (float word 0x20001040/44/48 & 0x7fffffff) < 0x7f800001 (not NaN)
@ and byte 0x2000104c/4d/4e < 5 it formats with format_to_buffer_080073b4 into
@ 0x20008360 using the format word at 0x0804c3f0 + idx*4 ("%.0f%s" to
@ "%.4f%s"), the float converted by float_to_double (08045d70) and the unit
@ word at 0x0804c404 + byte(0x20001052/53/54)*4 ("mV", "V", ...), and draws
@ 0800f154(x, 0xd4, 100, 0x14, 0x20008360, font 0x20001144, colour 0xffff,
@ flag 1).
@ ----------------------------------------------------------------------------
	.section .text.draw_value_panel,"ax",%progbits
	.p2align 2
	.global draw_value_panel
	.thumb_func
	.type draw_value_panel, %function
draw_value_panel:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0x14
	movw	r0, #:lower16:d_0804de88		@ bitmap
	movt	r0, #:upper16:d_0804de88
	movs	r5, #1
	movw	r7, #0xffff				@ colour 0xffff
	str	r0, [sp]
	movs	r0, #0xa
	movs	r1, #0xb8
	mov.w	r2, #0x12c
	movs	r3, #0x34
	movt	r5, #0x7f80				@ r5 = 0x7f800001 (NaN limit)
	str	r7, [sp, #4]
	bl	draw_4bpp_bitmap
	movw	r7, #0xf8
	movt	r7, #0x2000				@ r7 = 0x200000f8 (RAM base)
	movw	r8, #:lower16:d_0804c3d8		@ English labels MAX MEAN MIN
	movt	r8, #:upper16:d_0804c3d8
	ldr.w	r0, [r8]				@ label of column 0
	movw	r1, #0x1144
	movt	r1, #0x2000				@ font block 0x20001144
	mov.w	r10, #1
	movw	r11, #0x6bb0				@ label colour 0x6bb0
	stm.w	sp, {r0, r1, r11}
	movs	r0, #0xa
	movs	r1, #0xc0
	movs	r2, #0x64
	movs	r3, #0x14
	str.w	r10, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	addw	r0, r7, #0xf48				@ float word 0x20001040
	vldr	s0, [r0]
	vmov	r0, s0
	bic.w	r1, r0, #0x80000000
	cmp.w	r1, #0x7f800000
	bhi.n	.L0801cba4
	ldrb.w	r1, [r7, #0xf54]			@ byte 0x2000104c
	cmp	r1, #4
	bhi.n	.L0801cba4
	movw	r2, #:lower16:d_0804c3f0
	sxtb	r1, r1
	movt	r2, #:upper16:d_0804c3f0
	mov	r9, r5
	ldr.w	r5, [r2, r1, lsl #2]			@ format word
	bl	float_to_double
	ldrb.w	r3, [r7, #0xf5a]			@ byte 0x20001052
	mov	r2, r0
	movw	r0, #:lower16:d_0804c404
	movt	r0, #:upper16:d_0804c404
	movw	r4, #0x8360
	ldr.w	r6, [r0, r3, lsl #2]			@ unit word
	movt	r4, #0x2000				@ value text buffer 0x20008360
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	mov	r5, r9
	str	r6, [sp]
	bl	format_to_buffer_080073b4
	ldrb.w	r0, [r7, #0xf54]
	cmp	r0, #4
	bhi.n	.L0801cba4
	movw	r1, #0x1144
	movs	r0, #1
	movt	r1, #0x2000
	str	r1, [sp, #4]
	str	r0, [sp, #0xc]
	movs	r0, #0xa
	movs	r1, #0xd4
	movs	r2, #0x64
	movs	r3, #0x14
	movw	r6, #0xffff
	str	r4, [sp]
	str	r6, [sp, #8]
	bl	draw_wrapped_text_in_box
.L0801cba4:
	movs	r1, #0xc0
	ldr.w	r0, [r8, #4]				@ label of column 1
	strd	r11, r10, [sp, #8]
	movw	r10, #0x1144
	str	r0, [sp]
	movs	r0, #0x6e
	movs	r2, #0x64
	movs	r3, #0x14
	movt	r10, #0x2000
	str.w	r10, [sp, #4]
	bl	draw_wrapped_text_in_box
	addw	r0, r7, #0xf4c				@ float word 0x20001044
	vldr	s0, [r0]
	vmov	r0, s0
	bic.w	r1, r0, #0x80000000
	cmp	r1, r5
	bhs.n	.L0801cc50
	ldrb.w	r1, [r7, #0xf55]			@ byte 0x2000104d
	cmp	r1, #4
	bhi.n	.L0801cc50
	movw	r2, #:lower16:d_0804c3f0
	sxtb	r1, r1
	movt	r2, #:upper16:d_0804c3f0
	mov	r4, r5
	ldr.w	r5, [r2, r1, lsl #2]			@ format word
	bl	float_to_double
	ldrb.w	r3, [r7, #0xf5b]			@ byte 0x20001053
	mov	r2, r0
	movw	r0, #:lower16:d_0804c404
	movt	r0, #:upper16:d_0804c404
	movw	r9, #0x8360
	ldr.w	r6, [r0, r3, lsl #2]			@ unit word
	movt	r9, #0x2000				@ value text buffer 0x20008360
	mov	r3, r1
	mov	r0, r9
	mov	r1, r5
	mov	r5, r4
	str	r6, [sp]
	bl	format_to_buffer_080073b4
	ldrb.w	r0, [r7, #0xf55]
	cmp	r0, #4
	bhi.n	.L0801cc50
	movs	r0, #1
	str	r0, [sp, #0xc]
	movs	r0, #0x6e
	movs	r1, #0xd4
	movs	r2, #0x64
	movs	r3, #0x14
	movw	r6, #0xffff
	strd	r9, r10, [sp]
	str	r6, [sp, #8]
	bl	draw_wrapped_text_in_box
.L0801cc50:
	movs	r1, #1
	ldr.w	r0, [r8, #8]				@ label of column 2
	movw	r2, #0x6bb0
	str	r0, [sp]
	strd	r2, r1, [sp, #8]
	movs	r0, #0xd2
	movs	r1, #0xc0
	movs	r2, #0x64
	movs	r3, #0x14
	str.w	r10, [sp, #4]
	bl	draw_wrapped_text_in_box
	add.w	r0, r7, #0xf50				@ float word 0x20001048
	vldr	s0, [r0]
	vmov	r0, s0
	bic.w	r1, r0, #0x80000000
	cmp	r1, r5
	bhs.n	.L0801ccf6
	ldrb.w	r1, [r7, #0xf56]			@ byte 0x2000104e
	cmp	r1, #4
	bhi.n	.L0801ccf6
	movw	r2, #:lower16:d_0804c3f0
	sxtb	r1, r1
	movt	r2, #:upper16:d_0804c3f0
	ldr.w	r5, [r2, r1, lsl #2]			@ format word
	bl	float_to_double
	ldrb.w	r3, [r7, #0xf5c]			@ byte 0x20001054
	mov	r2, r0
	movw	r0, #:lower16:d_0804c404
	movt	r0, #:upper16:d_0804c404
	movw	r4, #0x8360
	ldr.w	r6, [r0, r3, lsl #2]			@ unit word
	movt	r4, #0x2000				@ value text buffer 0x20008360
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	str	r6, [sp]
	bl	format_to_buffer_080073b4
	ldrb.w	r0, [r7, #0xf56]
	cmp	r0, #4
	bhi.n	.L0801ccf6
	movw	r0, #0xffff
	movs	r7, #1
	str	r0, [sp, #8]
	movs	r0, #0xd2
	movs	r1, #0xd4
	movs	r2, #0x64
	movs	r3, #0x14
	strd	r4, r10, [sp]
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L0801ccf6:
	add	sp, #0x14
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}

@ ----------------------------------------------------------------------------
@ fn_0801ccfc - draws an image file and the title "System Settings" at the top
@ of the screen.
@ No parameters, no return value.
@ Calls decode_image_file_with_offset (08039f6c)("3:/System file/71.jpg", 0, 0),
@ then draw_wrapped_text_in_box (0800f154)(0x34, 0, 0xd8, 0x14, "System
@ Settings", font block 0x20001144, colour 0xffff, flag 1) (V1.2.0 took the
@ text from a language row).
@ ----------------------------------------------------------------------------
	.section .text.fn_0801ccfc,"ax",%progbits
	.p2align 2
	.global fn_0801ccfc
	.thumb_func
	.type fn_0801ccfc, %function
fn_0801ccfc:
	push	{r7, lr}
	sub	sp, #0x10
	movw	r0, #:lower16:t_080bc456		@ image path string
	movt	r0, #:upper16:t_080bc456
	movs	r1, #0
	movs	r2, #0
	bl	decode_image_file_with_offset
	movw	r0, #:lower16:t_080bccfe		@ "System Settings"
	movt	r0, #:upper16:t_080bccfe
	movw	r2, #0x1144
	movw	r1, #0xffff				@ colour 0xffff
	movt	r2, #0x2000				@ font block 0x20001144
	mov.w	r12, #1
	strd	r0, r2, [sp]
	str	r1, [sp, #8]
	movs	r0, #0x34
	movs	r1, #0
	movs	r2, #0xd8
	movs	r3, #0x14
	str.w	r12, [sp, #0xc]				@ flag 1
	bl	draw_wrapped_text_in_box
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000					@ padding

@ ----------------------------------------------------------------------------
@ draw_six_row_list - draws the system settings menu (left half of state 4's
@ page): a six-row text list in which the row at index diff
@ is highlighted with 89.jpg and the other rows use a gradient.
@ Menu items (d_0804c258, English): 0 Sound and light, 1 Startup on Boot, 2 Auto
@ Shutdown, 3 USB Sharing, 4 About, 5 Factory Reset. All six are visible, so the
@ key handlers keep hi = 0 (V1.2.0 had a seventh item, Language, in front and
@ scrolled the 6-row window over 7 items).
@ No parameters, no return value.
@ diff = (byte 0x20001062 & 0xf) - (byte 0x20001062 >> 4),
@ hi = byte 0x20001062 >> 4; rows n=0..5 at x=0, y=0x18+0x24*n.
@ Row n: when diff == n it calls decode_image_file_with_offset (08039f6c)
@ ("3:/System file/89.jpg", 0, y), otherwise draw_gradient_bar (08020134)
@ (y, y+0x23) (the arguments are 0x18,0x3b / 0x3c,0x5f / 0x60,0x83 / 0x84,0xa7 /
@ 0xa8,0xcb / 0xcc,0xef).
@ Text: draw_wrapped_text_in_box (0800f154)(0, y, 100, 0x24, word n + hi of
@ d_0804c258, font block 0x20001114, colour 0xffff, flag 1).
@ ----------------------------------------------------------------------------
	.section .text.draw_six_row_list,"ax",%progbits
	.p2align 2
	.global draw_six_row_list
	.thumb_func
	.type draw_six_row_list, %function
draw_six_row_list:
	push.w	{r4, r5, r6, r7, r8, r9, lr}
	sub	sp, #0x14
	movw	r4, #0xf8
	movt	r4, #0x2000				@ r4 = 0x200000f8 (RAM base)
	ldrb.w	r0, [r4, #0xf6a]			@ byte 0x20001062
	and.w	r1, r0, #0xf
	sub.w	r1, r1, r0, lsr #4
	uxtb	r7, r1					@ diff
	lsr.w	r5, r0, #4				@ hi
	cbz	r7, .L0801cd84
	movs	r0, #0x18
	movs	r1, #0x3b
	bl	draw_gradient_bar
	b.n	.L0801cd94
.L0801cd84:
	movw	r0, #:lower16:t_080bc655		@ "3:/System file/89.jpg"
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0x18
	bl	decode_image_file_with_offset
.L0801cd94:
	movw	r6, #:lower16:d_0804c258		@ English menu item names (6 words)
	movt	r6, #:upper16:d_0804c258
	ldr.w	r0, [r6, r5, lsl #2]			@ item hi + 0
	movw	r9, #0x1114
	movs	r1, #1
	movt	r9, #0x2000				@ font block 0x20001114
	movw	r8, #0xffff				@ colour 0xffff
	strd	r0, r9, [sp]
	str	r1, [sp, #0xc]
	movs	r0, #0
	movs	r1, #0x18
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	cmp	r7, #1
	bne.n	.L0801cdea
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0x3c
	bl	decode_image_file_with_offset
	b.n	.L0801cdf2
.L0801cdea:
	movs	r0, #0x3c
	movs	r1, #0x5f
	bl	draw_gradient_bar
.L0801cdf2:
	movs	r1, #1
	add.w	r0, r6, r5, lsl #2
	ldr	r0, [r0, #4]				@ item hi + 1
	str	r1, [sp, #0xc]
	strd	r0, r9, [sp]
	movs	r0, #0
	movs	r1, #0x3c
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	cmp	r7, #2
	bne.n	.L0801ce34
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0x60
	bl	decode_image_file_with_offset
	b.n	.L0801ce3c
.L0801ce34:
	movs	r0, #0x60
	movs	r1, #0x83
	bl	draw_gradient_bar
.L0801ce3c:
	movs	r1, #1
	add.w	r0, r6, r5, lsl #2
	ldr	r0, [r0, #8]				@ item hi + 2
	str	r1, [sp, #0xc]
	strd	r0, r9, [sp]
	movs	r0, #0
	movs	r1, #0x60
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	cmp	r7, #3
	bne.n	.L0801ce7e
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0x84
	bl	decode_image_file_with_offset
	b.n	.L0801ce86
.L0801ce7e:
	movs	r0, #0x84
	movs	r1, #0xa7
	bl	draw_gradient_bar
.L0801ce86:
	movs	r1, #1
	add.w	r0, r6, r5, lsl #2
	ldr	r0, [r0, #0xc]				@ item hi + 3
	str	r1, [sp, #0xc]
	strd	r0, r9, [sp]
	movs	r0, #0
	movs	r1, #0x84
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	cmp	r7, #4
	bne.n	.L0801cec8
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0xa8
	bl	decode_image_file_with_offset
	b.n	.L0801ced0
.L0801cec8:
	movs	r0, #0xa8
	movs	r1, #0xcb
	bl	draw_gradient_bar
.L0801ced0:
	movs	r1, #1
	add.w	r0, r6, r5, lsl #2
	ldr	r0, [r0, #0x10]				@ item hi + 4
	str	r1, [sp, #0xc]
	strd	r0, r9, [sp]
	movs	r0, #0
	movs	r1, #0xa8
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	bl	draw_wrapped_text_in_box
	cmp	r7, #5
	bne.n	.L0801cf12
	movw	r0, #:lower16:t_080bc655
	movt	r0, #:upper16:t_080bc655
	movs	r1, #0
	movs	r2, #0xcc
	bl	decode_image_file_with_offset
	b.n	.L0801cf1a
.L0801cf12:
	movs	r0, #0xcc
	movs	r1, #0xef
	bl	draw_gradient_bar
.L0801cf1a:
	movs	r7, #1
	add.w	r0, r6, r5, lsl #2
	ldr	r0, [r0, #0x14]				@ item hi + 5
	movs	r1, #0xcc
	strd	r0, r9, [sp]
	movs	r0, #0
	movs	r2, #0x64
	movs	r3, #0x24
	str.w	r8, [sp, #8]
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add	sp, #0x14
	pop.w	{r4, r5, r6, r7, r8, r9, pc}
	.word	0x00000000				@ padding

