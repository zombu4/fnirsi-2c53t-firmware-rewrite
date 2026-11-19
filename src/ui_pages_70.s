@ ui_pages_70.s - page draw routines fn_08010e70 .. fn_08011d08 (13 units, 0x08010e70..0x08011dfc)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08010e70 - draw one page region: returns at once unless [0x20001060]==1.
@ Sets the region record at 0x20008350..56 = (x=10, y=0xb8, w=300, h=0x34)
@ (four halfwords), allocates w*h*2 = 0x79e0 bytes with alloc_units_of_32_bytes
@ (0803acfc) into [0x20008358]. When that succeeds, zero-fills w*h halfwords
@ (unrolled by 4, remainder 0..3 halfwords) and calls draw_value_panel
@ (0801cab0). Then calls fn_08042ee0 and
@ semaphore_take_timeout([0x20002d84], 0xffffffff). When that returns 1 and
@ [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080]==0, otherwise, when (buf - [0x20001078]) >> 10 < 0xaf,
@ zero_bytes (080082bc) clears its entry range in the halfword table
@ [0x2000107c] (index (buf-base)>>5, length = entry*2 bytes).
@ ----------------------------------------------------------------------------
	.section .text.fn_08010e70,"ax",%progbits
	.p2align 2
	.global fn_08010e70
	.thumb_func
	.type fn_08010e70, %function
fn_08010e70:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]	@ [0x20001060]
	cmp r0, #1
	bne.n .L08010f5a
	movw r4, #0x8350
	movt r4, #0x2000	@ r4 = region record 0x20008350
	movs r0, #0xa
	strh r0, [r4, #0]	@ x = 10
	movs r0, #0xb8
	strh r0, [r4, #2]	@ y = 0xb8
	mov.w r0, #0x12c
	strh r0, [r4, #4]	@ w = 300
	movs r0, #0x34
	strh r0, [r4, #6]	@ h = 0x34
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L08010f5a
	ldr.w r12, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0	@ halfword count
	cbz r0, .L08010f0a
	subs r1, r0, #1
	and.w lr, r0, #3	@ remainder
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	bcc.n .L08010ee8
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1	@ count rounded down to a multiple of 4
	sub.w r1, r12, #8
	movs r2, #0
.L08010edc:
	adds r2, #4
	str.w r3, [r1, #8]!	@ four halfwords per pass
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L08010edc
.L08010ee8:
	cmp.w lr, #0
	beq.n .L08010f0a
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [r12, r2, lsl #1]
	beq.n .L08010f0a
	add.w r1, r12, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L08010f0a:
	bl draw_value_panel
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08010f5a
	ldr r1, [r4, #8]
	cbz r1, .L08010f5a
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L08010f5c
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08010f5a
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08010f5a:
	pop {r4, pc}
.L08010f5c:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	pop.w {r4, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08010f68 - draw one page region: returns at once unless [0x20001060]==4.
@ Sets the region record 0x20008350..56 = (x=0, y=0, w=0x10c, h=0x14),
@ allocates w*h*2 = 0x29e0 bytes with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds draws the image "3:/System file/71.jpg" at
@ (0,0) with decode_image_file_with_offset (08039f6c) and "System Settings" with
@ draw_wrapped_text_in_box (0800f154)(0x34, 0, 0xd8, 0x14, text, 0x20001144,
@ 0xffff, 1). Then fn_08042ee0 and
@ semaphore_take_timeout([0x20002d84], 0xffffffff); when that returns 1 and
@ [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080]==0, otherwise, when (buf - [0x20001078]) >> 10 < 0xaf,
@ zero_bytes (080082bc) clears its entry range in the halfword table
@ [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08010f68,"ax",%progbits
	.p2align 2
	.global fn_08010f68
	.thumb_func
	.type fn_08010f68, %function
fn_08010f68:
	push {r4, r5, r7, lr}
	sub sp, #0x10
	movw r5, #0xf8
	movt r5, #0x2000	@ r5 = 0x200000f8
	ldrb.w r0, [r5, #0xf68]	@ [0x20001060]
	cmp r0, #4
	bne.n .L08011036
	movw r4, #0x8350
	movt r4, #0x2000	@ r4 = region record 0x20008350
	movs r0, #0
	strh r0, [r4, #0]	@ x = 0
	strh r0, [r4, #2]	@ y = 0
	mov.w r0, #0x10c
	strh r0, [r4, #4]	@ w = 0x10c
	movs r0, #0x14
	strh r0, [r4, #6]	@ h = 0x14
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L08011036
	movw r0, #:lower16:t_080bc456	@ "3:/System file/71.jpg"
	movt r0, #:upper16:t_080bc456
	movs r1, #0
	movs r2, #0
	bl decode_image_file_with_offset
	movw r0, #:lower16:t_080bccfe	@ "System Settings"
	movt r0, #:upper16:t_080bccfe
	movw r2, #0x1144
	movw r1, #0xffff
	movt r2, #0x2000	@ r2 = 0x20001144
	movs r5, #1
	strd r0, r2, [sp]
	str r1, [sp, #8]
	movs r0, #0x34
	movs r1, #0
	movs r2, #0xd8
	movs r3, #0x14
	str r5, [sp, #0xc]
	bl draw_wrapped_text_in_box
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08011036
	ldr r1, [r4, #8]
	cbz r1, .L08011036
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L0801103a
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08011036
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L08011036
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08011036:
	add sp, #0x10
	pop {r4, r5, r7, pc}
.L0801103a:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	add sp, #0x10
	pop.w {r4, r5, r7, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08011048 - draw one page region: returns at once unless [0x20001060]==4.
@ Sets the region record 0x20008350..56 = (x=0, y=0x18, w=0x6c, h=0xd8),
@ allocates w*h*2 = 0xb640 bytes with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds zero-fills w*h halfwords (unrolled by 4,
@ remainder 0..3) and calls draw_six_row_list (0801cd58). Then fn_08042ee0 and
@ semaphore_take_timeout([0x20002d84], 0xffffffff); when that returns 1 and
@ [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080]==0, otherwise, when (buf - [0x20001078]) >> 10 < 0xaf,
@ zero_bytes (080082bc) clears its entry range in the halfword table
@ [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08011048,"ax",%progbits
	.p2align 2
	.global fn_08011048
	.thumb_func
	.type fn_08011048, %function
fn_08011048:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]	@ [0x20001060]
	cmp r0, #4
	bne.n .L08011132
	movw r4, #0x8350
	movt r4, #0x2000	@ r4 = region record 0x20008350
	movs r0, #0
	strh r0, [r4, #0]	@ x = 0
	movs r0, #0x18
	strh r0, [r4, #2]	@ y = 0x18
	movs r0, #0x6c
	strh r0, [r4, #4]	@ w = 0x6c
	movs r0, #0xd8
	strh r0, [r4, #6]	@ h = 0xd8
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L08011132
	ldr.w r12, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0	@ halfword count
	cbz r0, .L080110e2
	subs r1, r0, #1
	and.w lr, r0, #3	@ remainder
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	bcc.n .L080110c0
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1	@ count rounded down to a multiple of 4
	sub.w r1, r12, #8
	movs r2, #0
	nop
.L080110b4:
	adds r2, #4
	str.w r3, [r1, #8]!	@ four halfwords per pass
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L080110b4
.L080110c0:
	cmp.w lr, #0
	beq.n .L080110e2
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [r12, r2, lsl #1]
	beq.n .L080110e2
	add.w r1, r12, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L080110e2:
	bl draw_six_row_list
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08011132
	ldr r1, [r4, #8]
	cbz r1, .L08011132
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L08011134
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08011132
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08011132:
	pop {r4, pc}
.L08011134:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	pop.w {r4, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08011140 - draw one page region: returns at once unless [0x20001060]==4.
@ Sets the region record 0x20008350..56 = (x=0x72, y=0x18, w=0xce, h=0xd8),
@ allocates w*h*2 = 0x15ba0 bytes with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds zero-fills w*h halfwords (unrolled by 4,
@ remainder 0..3) and calls draw_page_by_selector_nibble (0801cf50). Then
@ fn_08042ee0 and semaphore_take_timeout([0x20002d84], 0xffffffff); when that
@ returns 1 and [0x20008358] != 0 the buffer is released: callback
@ (*[0x20001070])(0) if [0x20001080]==0, otherwise, when
@ (buf - [0x20001078]) >> 10 < 0xaf, zero_bytes (080082bc) clears its entry
@ range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08011140,"ax",%progbits
	.p2align 2
	.global fn_08011140
	.thumb_func
	.type fn_08011140, %function
fn_08011140:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]	@ [0x20001060]
	cmp r0, #4
	bne.n .L0801122a
	movw r4, #0x8350
	movt r4, #0x2000	@ r4 = region record 0x20008350
	movs r0, #0x72
	strh r0, [r4, #0]	@ x = 0x72
	movs r0, #0x18
	strh r0, [r4, #2]	@ y = 0x18
	movs r0, #0xce
	strh r0, [r4, #4]	@ w = 0xce
	movs r0, #0xd8
	strh r0, [r4, #6]	@ h = 0xd8
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L0801122a
	ldr.w r12, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0	@ halfword count
	cbz r0, .L080111da
	subs r1, r0, #1
	and.w lr, r0, #3	@ remainder
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	bcc.n .L080111b8
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1	@ count rounded down to a multiple of 4
	sub.w r1, r12, #8
	movs r2, #0
	nop
.L080111ac:
	adds r2, #4
	str.w r3, [r1, #8]!	@ four halfwords per pass
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L080111ac
.L080111b8:
	cmp.w lr, #0
	beq.n .L080111da
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [r12, r2, lsl #1]
	beq.n .L080111da
	add.w r1, r12, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L080111da:
	bl draw_page_by_selector_nibble
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L0801122a
	ldr r1, [r4, #8]
	cbz r1, .L0801122a
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L0801122c
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L0801122a
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L0801122a:
	pop {r4, pc}
.L0801122c:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	pop.w {r4, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08011238 - read the screen back, process it and write it out again.
@ No parameters, no return value. Runs the same block twice, for the region
@ records (x=0, y=0, w=0x140, h=0x78) and (x=0, y=0x78, w=0x140, h=0x78)
@ (record at 0x20008350..56): allocates w*h*2 = 0x12c00 bytes with
@ alloc_units_of_32_bytes (0803acfc) into [0x20008358]; when that succeeds it
@ calls fn_080097e8, which writes the region record's x/y start and end values
@ to 0x60020000 after [0x2000834a]/[0x2000834c] at 0x6001fffe, writes 0x2e to
@ 0x6001fffe (0800984a), reads 0x60020000 once through 08020e00 (0800984e) and
@ discards it, then for index 0,2,4.. below w*h reads 0x60020000 three times
@ (08009868, 0800986e, 08009874) and stores two halfwords built from the three
@ reads with masks at buffer index and index+1. Then it calls
@ halve_rect_rgb565 (08020330)(x, y, x+w-1, y+h-1) (purpose not determined
@ here) and writes the port values: [0x6001fffe]=[0x2000834a] then x>>8,
@ x&0xff, (x+w-1)>>8&0xff, (x+w-1)&0xff to 0x60020000;
@ [0x6001fffe]=[0x2000834c] then y>>8, y&0xff, (y+h-1)>>8&0xff,
@ (y+h-1)&0xff; [0x6001fffe]=[0x20008348]; it streams all w*h halfwords of the
@ buffer (unrolled by 4) to 0x60020000 and releases the buffer (callback
@ (*[0x20001070])(0) if [0x20001080]==0, else zero_bytes (080082bc) on the
@ entry range of the table [0x2000107c]).
@ Purpose: fills the region buffer from three reads of 0x60020000 per two
@ pixels via fn_080097e8, calls halve_rect_rgb565 on the rectangle, then
@ writes the buffer to 0x60020000.
@ Registers: r4 = region record 0x20008350, r5 = 0x60020000 (data port),
@ r9 = 0x20008340, r10 = 0 (x and y of block 1), r8 = 0x140 (w), r11 = 0x78.
@ ----------------------------------------------------------------------------
	.section .text.fn_08011238,"ax",%progbits
	.p2align 2
	.global fn_08011238
	.thumb_func
	.type fn_08011238, %function
fn_08011238:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #4
	movw r4, #0x8350
	movt r4, #0x2000	@ r4 = region record 0x20008350
	mov.w r10, #0
	mov.w r8, #0x140
	mov.w r11, #0x78
	strh.w r10, [r4, #0]	@ x = 0
	strh.w r10, [r4, #2]	@ y = 0
	strh.w r8, [r4, #4]	@ w = 0x140
	strh.w r11, [r4, #6]	@ h = 0x78
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	movs r5, #0
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	movt r5, #0x6002	@ r5 = 0x60020000
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	movw r9, #0x8340
	cmp r0, #0
	movt r9, #0x2000	@ r9 = 0x20008340
	beq.w .L0801138c
	bl fn_080097e8
	ldrsh.w r0, [r4, #0]
	ldrsh.w r1, [r4, #2]
	ldrh r2, [r4, #0]
	ldrh r3, [r4, #4]
	add r2, r3
	ldrh r3, [r4, #2]
	ldrh r7, [r4, #6]
	subs r2, #1	@ x + w - 1
	add r3, r7
	subs r3, #1	@ y + h - 1
	sxth r2, r2
	sxth r3, r3
	bl halve_rect_rgb565
	ldrh r0, [r4, #0]
	ldrh r1, [r4, #2]
	ldrh r2, [r4, #4]
	ldrh r3, [r4, #6]
	add r2, r0
	ldrh.w r6, [r9, #0xa]	@ [0x2000834a]
	subs r2, #1
	uxth r7, r2
	strh.w r6, [r5, #-2]	@ [0x6001fffe] = [0x2000834a]
	lsrs r6, r0, #8
	uxtb r0, r0
	strh r6, [r5, #0]	@ x >> 8
	strh r0, [r5, #0]	@ x & 0xff
	lsrs r0, r7, #8
	strh r0, [r5, #0]	@ (x+w-1) >> 8
	uxtb r0, r2
	strh r0, [r5, #0]	@ (x+w-1) & 0xff
	ldrh.w r0, [r9, #0xc]	@ [0x2000834c]
	add r3, r1
	subs r3, #1
	strh.w r0, [r5, #-2]	@ [0x6001fffe] = [0x2000834c]
	lsrs r0, r1, #8
	uxth r2, r3
	strh r0, [r5, #0]	@ y >> 8
	uxtb r0, r1
	strh r0, [r5, #0]	@ y & 0xff
	lsrs r0, r2, #8
	strh r0, [r5, #0]	@ (y+h-1) >> 8
	uxtb r0, r3
	strh r0, [r5, #0]	@ (y+h-1) & 0xff
	ldrh.w r0, [r9, #8]	@ [0x20008348]
	strh.w r0, [r5, #-2]	@ [0x6001fffe] = [0x20008348]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	cbz r0, .L08011356
	movs r0, #0
.L08011300:
	ldr r1, [r4, #8]
	adds r3, r0, #1
	ldrh.w r1, [r1, r0, lsl #1]
	strh r1, [r5, #0]	@ halfword 0 of 4
	ldrh r1, [r4, #4]
	ldrh r2, [r4, #6]
	muls r1, r2, r1
	cmp r3, r1
	bcs.n .L08011356
	ldr r1, [r4, #8]
	adds r3, r0, #2
	add.w r1, r1, r0, lsl #1
	ldrh r1, [r1, #2]
	strh r1, [r5, #0]	@ halfword 1 of 4
	ldrh r1, [r4, #4]
	ldrh r2, [r4, #6]
	muls r1, r2, r1
	cmp r3, r1
	bcs.n .L08011356
	ldr r1, [r4, #8]
	adds r3, r0, #3
	add.w r1, r1, r0, lsl #1
	ldrh r1, [r1, #4]
	strh r1, [r5, #0]	@ halfword 2 of 4
	ldrh r1, [r4, #4]
	ldrh r2, [r4, #6]
	muls r1, r2, r1
	cmp r3, r1
	bcs.n .L08011356
	ldr r1, [r4, #8]
	add.w r1, r1, r0, lsl #1
	ldrh r1, [r1, #6]
	adds r0, #4
	strh r1, [r5, #0]	@ halfword 3 of 4
	ldrh r1, [r4, #4]
	ldrh r2, [r4, #6]
	muls r1, r2, r1
	cmp r0, r1
	bcc.n .L08011300
.L08011356:
	ldr r1, [r4, #8]
	cbz r1, .L0801138c
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L08011386
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L0801138c
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L0801138c
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0801138c
.L08011386:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	blx r1	@ (*[0x20001070])(0)
.L0801138c:
	strh.w r10, [r4, #0]	@ x = 0
	strh.w r11, [r4, #2]	@ y = 0x78
	strh.w r8, [r4, #4]	@ w = 0x140
	strh.w r11, [r4, #6]	@ h = 0x78
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.w .L080114b0
	bl fn_080097e8
	ldrsh.w r0, [r4, #0]
	ldrsh.w r1, [r4, #2]
	ldrh r2, [r4, #0]
	ldrh r3, [r4, #4]
	add r2, r3
	ldrh r3, [r4, #2]
	ldrh r7, [r4, #6]
	subs r2, #1	@ x + w - 1
	add r3, r7
	subs r3, #1	@ y + h - 1
	sxth r2, r2
	sxth r3, r3
	bl halve_rect_rgb565
	ldrh r0, [r4, #0]
	ldrh r1, [r4, #2]
	ldrh r2, [r4, #4]
	ldrh r3, [r4, #6]
	add r2, r0
	ldrh.w r6, [r9, #0xa]	@ [0x2000834a]
	subs r2, #1
	uxth r7, r2
	strh.w r6, [r5, #-2]	@ [0x6001fffe] = [0x2000834a]
	lsrs r6, r0, #8
	uxtb r0, r0
	strh r6, [r5, #0]	@ x >> 8
	strh r0, [r5, #0]	@ x & 0xff
	lsrs r0, r7, #8
	strh r0, [r5, #0]	@ (x+w-1) >> 8
	uxtb r0, r2
	strh r0, [r5, #0]	@ (x+w-1) & 0xff
	ldrh.w r0, [r9, #0xc]	@ [0x2000834c]
	add r3, r1
	subs r3, #1
	strh.w r0, [r5, #-2]	@ [0x6001fffe] = [0x2000834c]
	lsrs r0, r1, #8
	uxth r2, r3
	strh r0, [r5, #0]	@ y >> 8
	uxtb r0, r1
	strh r0, [r5, #0]	@ y & 0xff
	lsrs r0, r2, #8
	strh r0, [r5, #0]	@ (y+h-1) >> 8
	uxtb r0, r3
	strh r0, [r5, #0]	@ (y+h-1) & 0xff
	ldrh.w r0, [r9, #8]	@ [0x20008348]
	strh.w r0, [r5, #-2]	@ [0x6001fffe] = [0x20008348]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	cbz r0, .L08011482
	movs r0, #0
.L0801142c:
	ldr r1, [r4, #8]
	adds r3, r0, #1
	ldrh.w r1, [r1, r0, lsl #1]
	strh r1, [r5, #0]	@ halfword 0 of 4
	ldrh r1, [r4, #4]
	ldrh r2, [r4, #6]
	muls r1, r2, r1
	cmp r3, r1
	bcs.n .L08011482
	ldr r1, [r4, #8]
	adds r3, r0, #2
	add.w r1, r1, r0, lsl #1
	ldrh r1, [r1, #2]
	strh r1, [r5, #0]	@ halfword 1 of 4
	ldrh r1, [r4, #4]
	ldrh r2, [r4, #6]
	muls r1, r2, r1
	cmp r3, r1
	bcs.n .L08011482
	ldr r1, [r4, #8]
	adds r3, r0, #3
	add.w r1, r1, r0, lsl #1
	ldrh r1, [r1, #4]
	strh r1, [r5, #0]	@ halfword 2 of 4
	ldrh r1, [r4, #4]
	ldrh r2, [r4, #6]
	muls r1, r2, r1
	cmp r3, r1
	bcs.n .L08011482
	ldr r1, [r4, #8]
	add.w r1, r1, r0, lsl #1
	ldrh r1, [r1, #6]
	adds r0, #4
	strh r1, [r5, #0]	@ halfword 3 of 4
	ldrh r1, [r4, #4]
	ldrh r2, [r4, #6]
	muls r1, r2, r1
	cmp r0, r1
	bcc.n .L0801142c
.L08011482:
	ldr r1, [r4, #8]
	cbz r1, .L080114b0
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L080114b6
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L080114b0
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L080114b0
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L080114b0:
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L080114b6:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080114c4 - draw a message box with an image, two texts and a countdown.
@ No parameters, no return value. Sets the region record 0x20008350..56 =
@ (x=0x46, y=0x43, w=0xb4, h=0x6a), allocates w*h*2 = 0x9510 bytes with
@ alloc_units_of_32_bytes (0803acfc) into [0x20008358]. When that succeeds it
@ zero-fills w*h halfwords, draws the image "3:/System file/145.jpg" at
@ (0x46,0x43) with decode_image_file_with_offset (08039f6c), draws "Battery low,
@ charge now" with
@ draw_wrapped_text_in_box (0800f154)(0x48,0x48,0xb0,0x14,text,0x200010e4,0,1),
@ draws "Auto shutdown soon" with
@ 0800f154(0x48,0x7a,0xb0,0x28,text,0x200010e4,0xf800,0x81), formats "%ds" with
@ 0xe - [0x2000105e] into 0x20008360 (format_to_buffer_080073b4) and draws it
@ with 0800f154(0x48,0x61,0xb0,0x19,0x20008360,0x20001174,0xf800,0x81). Then
@ fn_08042ee0 and semaphore_take_timeout([0x20002d84], 0xffffffff); when that
@ returns 1 and [0x20008358] != 0 the buffer is released: callback
@ (*[0x20001070])(0) if [0x20001080]==0, otherwise, when
@ (buf - [0x20001078]) >> 10 < 0xaf, zero_bytes (080082bc) clears its entry
@ range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_080114c4,"ax",%progbits
	.p2align 2
	.global fn_080114c4
	.thumb_func
	.type fn_080114c4, %function
fn_080114c4:
	push.w {r4, r5, r6, r7, r8, lr}
	sub sp, #0x10
	movw r5, #0x8350
	movt r5, #0x2000	@ r5 = region record 0x20008350
	movs r0, #0x46
	strh r0, [r5, #0]	@ x = 0x46
	movs r0, #0x43
	strh r0, [r5, #2]	@ y = 0x43
	movs r0, #0xb4
	strh r0, [r5, #4]	@ w = 0xb4
	movs r0, #0x6a
	strh r0, [r5, #6]	@ h = 0x6a
	ldrh r0, [r5, #4]
	ldrh r1, [r5, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r5, #8]
	ldr r0, [r5, #8]
	cmp r0, #0
	beq.w .L0801164c
	ldr r0, [r5, #8]	@ r0 = buffer
	ldrh r1, [r5, #4]
	ldrh r2, [r5, #6]
	mul r6, r2, r1	@ halfword count
	cbz r6, .L0801154a
	subs r2, r6, #1
	and.w r1, r6, #3	@ remainder
	movs r3, #0
	cmp r2, #3
	mov.w r2, #0
	bcc.n .L08011530
	movw r2, #0xfffc
	movt r2, #0x7fff
	ands r6, r2	@ count rounded down to a multiple of 4
	sub.w r4, r0, #8
	movs r2, #0
.L08011524:
	adds r2, #4
	str.w r3, [r4, #8]!	@ four halfwords per pass
	cmp r6, r2
	str r3, [r4, #4]
	bne.n .L08011524
.L08011530:
	cbz r1, .L0801154a
	movs r3, #0
	cmp r1, #1
	strh.w r3, [r0, r2, lsl #1]
	beq.n .L0801154a
	add.w r0, r0, r2, lsl #1
	cmp r1, #2
	strh r3, [r0, #2]
	itt ne
	movne r1, #0
	strhne r1, [r0, #4]
.L0801154a:
	movw r0, #:lower16:t_080bc533	@ "3:/System file/145.jpg"
	movt r0, #:upper16:t_080bc533
	movs r1, #0x46
	movs r2, #0x43
	bl decode_image_file_with_offset
	movw r4, #0xf8
	movt r4, #0x2000	@ r4 = 0x200000f8
	movw r0, #:lower16:t_080bceb4	@ "Battery low, charge now"
	movt r0, #:upper16:t_080bceb4
	movs r1, #1
	movs r2, #0
	movw r7, #0x10e4
	movt r7, #0x2000	@ r7 = 0x200010e4
	str r0, [sp, #0]
	strd r2, r1, [sp, #8]
	movs r0, #0x48
	movs r1, #0x48
	movs r2, #0xb0
	movs r3, #0x14
	str r7, [sp, #4]
	bl draw_wrapped_text_in_box
	movw r0, #:lower16:t_080bc8ae	@ "Auto shutdown soon"
	movt r0, #:upper16:t_080bc8ae
	mov.w r8, #0x81
	mov.w r6, #0xf800
	strd r0, r7, [sp]
	movs r0, #0x48
	movs r1, #0x7a
	movs r2, #0xb0
	movs r3, #0x28
	str r6, [sp, #8]
	str.w r8, [sp, #0xc]
	bl draw_wrapped_text_in_box
	ldrb.w r0, [r4, #0xf66]	@ [0x2000105e]
	movw r4, #0x8360
	movt r4, #0x2000	@ r4 = text buffer 0x20008360
	movw r1, #:lower16:t_080bcc3f	@ "%ds"
	rsb.w r2, r0, #0xe	@ 0xe - [0x2000105e]
	movt r1, #:upper16:t_080bcc3f
	mov r0, r4
	bl format_to_buffer_080073b4
	movw r0, #0x1174
	movt r0, #0x2000	@ r0 = 0x20001174
	strd r4, r0, [sp]
	movs r0, #0x48
	movs r1, #0x61
	movs r2, #0xb0
	movs r3, #0x19
	str r6, [sp, #8]
	str.w r8, [sp, #0xc]
	bl draw_wrapped_text_in_box
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L0801164c
	ldr r1, [r5, #8]
	cbz r1, .L0801164c
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L08011652
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L0801164c
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L0801164c
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L0801164c:
	add sp, #0x10
	pop.w {r4, r5, r6, r7, r8, pc}
.L08011652:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	add sp, #0x10
	pop.w {r4, r5, r6, r7, r8, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08011660 - screenshot save state machine.
@ No parameters, no return value. If byte [0x20000f09]==0xff, sets byte
@ [0x20000f08]=3. Otherwise formats "2:/Screenshot file/%d.bmp" with
@ [0x20000f09] into 0x20008360 (format_to_buffer_080073b4) and calls
@ save_screen_bmp (0803d084). Result 0: calls write_numbered_bin_file
@ (0803ced4); result 0 sets [0x20000f08]=2 and stores [0x20000f09] into the
@ byte array at 0x20000f1d at index [0x20000f13], then increments
@ [0x20000f13]; nonzero sets [0x20000f08]=3, re-formats the path with
@ [0x20000f09] and calls path_delete (0803512c). A nonzero result of
@ save_screen_bmp sets [0x20000f08]=3 and calls path_delete (0803512c). Always
@ ends with [0x20001060]=2. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08011660,"ax",%progbits
	.p2align 2
	.global fn_08011660
	.thumb_func
	.type fn_08011660, %function
fn_08011660:
	push {r4, lr}
	movw r4, #0xf8
	movt r4, #0x2000	@ r4 = 0x200000f8
	ldrb.w r2, [r4, #0xe11]	@ [0x20000f09]
	cmp r2, #0xff
	beq.n .L08011698
	movw r0, #0x8360
	movw r1, #:lower16:t_080bcad2	@ "2:/Screenshot file/%d.bmp"
	movt r0, #0x2000
	movt r1, #:upper16:t_080bcad2
	bl format_to_buffer_080073b4
	bl save_screen_bmp
	cbz r0, .L080116a0
	movs r0, #3
	strb.w r0, [r4, #0xe10]	@ [0x20000f08] = 3
	bl path_delete
	b.n .L080116e4
.L08011698:
	movs r0, #3
	strb.w r0, [r4, #0xe10]	@ [0x20000f08] = 3
	b.n .L080116e4
.L080116a0:
	bl write_numbered_bin_file
	cbz r0, .L080116ca
	movs r0, #3
	ldrb.w r2, [r4, #0xe11]	@ [0x20000f09]
	strb.w r0, [r4, #0xe10]	@ [0x20000f08] = 3
	movw r0, #0x8360
	movw r1, #:lower16:t_080bcad2
	movt r0, #0x2000
	movt r1, #:upper16:t_080bcad2
	bl format_to_buffer_080073b4
	bl path_delete
	b.n .L080116e4
.L080116ca:
	movs r0, #2
	strb.w r0, [r4, #0xe10]	@ [0x20000f08] = 2
	ldrb.w r0, [r4, #0xe1b]	@ [0x20000f13]
	ldrb.w r1, [r4, #0xe11]	@ [0x20000f09]
	adds r2, r4, r0
	adds r0, #1
	strb.w r1, [r2, #0xe25]	@ byte array 0x20000f1d, index [0x20000f13]
	strb.w r0, [r4, #0xe1b]	@ [0x20000f13] += 1
.L080116e4:
	movs r0, #2
	strb.w r0, [r4, #0xf68]	@ [0x20001060] = 2
	pop {r4, pc}

@ ----------------------------------------------------------------------------
@ fn_080116ec - draw one page region: returns at once unless [0x20001060]==5.
@ Sets the region record 0x20008350..56 = (x=0, y=0, w=0x10c, h=0x14),
@ allocates w*h*2 = 0x29e0 bytes with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds draws the image "3:/System file/71.jpg" at
@ (0,0) with decode_image_file_with_offset (08039f6c) and "Image Viewer" with
@ draw_wrapped_text_in_box (0800f154)(0x34, 0, 0xd8, 0x14, text, 0x20001144,
@ 0xffff, 1). Then fn_08042ee0 and
@ semaphore_take_timeout([0x20002d84], 0xffffffff); when that returns 1 and
@ [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080]==0, otherwise, when (buf - [0x20001078]) >> 10 < 0xaf,
@ zero_bytes (080082bc) clears its entry range in the halfword table
@ [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_080116ec,"ax",%progbits
	.p2align 2
	.global fn_080116ec
	.thumb_func
	.type fn_080116ec, %function
fn_080116ec:
	push {r4, r5, r7, lr}
	sub sp, #0x10
	movw r5, #0xf8
	movt r5, #0x2000	@ r5 = 0x200000f8
	ldrb.w r0, [r5, #0xf68]	@ [0x20001060]
	cmp r0, #5
	bne.n .L080117ba
	movw r4, #0x8350
	movt r4, #0x2000	@ r4 = region record 0x20008350
	movs r0, #0
	strh r0, [r4, #0]	@ x = 0
	strh r0, [r4, #2]	@ y = 0
	mov.w r0, #0x10c
	strh r0, [r4, #4]	@ w = 0x10c
	movs r0, #0x14
	strh r0, [r4, #6]	@ h = 0x14
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L080117ba
	movw r0, #:lower16:t_080bc456	@ "3:/System file/71.jpg"
	movt r0, #:upper16:t_080bc456
	movs r1, #0
	movs r2, #0
	bl decode_image_file_with_offset
	movw r0, #:lower16:t_080bcb6e	@ "Image Viewer"
	movt r0, #:upper16:t_080bcb6e
	movw r2, #0x1144
	movw r1, #0xffff
	movt r2, #0x2000	@ r2 = 0x20001144
	movs r5, #1
	strd r0, r2, [sp]
	str r1, [sp, #8]
	movs r0, #0x34
	movs r1, #0
	movs r2, #0xd8
	movs r3, #0x14
	str r5, [sp, #0xc]
	bl draw_wrapped_text_in_box
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L080117ba
	ldr r1, [r4, #8]
	cbz r1, .L080117ba
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L080117be
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L080117ba
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L080117ba
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L080117ba:
	add sp, #0x10
	pop {r4, r5, r7, pc}
.L080117be:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	add sp, #0x10
	pop.w {r4, r5, r7, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080117cc - draw the numbered system image on the page: returns at once
@ unless [0x20001060]==5. Stores 0x0803a23d (write_pixel_window_to_port) into
@ [0x20036b80] around the call and restores 0x0803a175
@ (copy_rect_into_clip_buffer) afterwards. Formats "3:/System file/%d.jpg"
@ with [0x20000f12] + 0x92 into 0x20008360 (format_to_buffer_080073b4) and
@ draws it with decode_image_file_with_offset (08039f6c)(name, 0, 0xd3).
@ ----------------------------------------------------------------------------
	.section .text.fn_080117cc,"ax",%progbits
	.p2align 2
	.global fn_080117cc
	.thumb_func
	.type fn_080117cc, %function
fn_080117cc:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000	@ r0 = 0x200000f8
	ldrb.w r1, [r0, #0xf68]	@ [0x20001060]
	cmp r1, #5
	it ne
	popne {r4, r5, r7, pc}
	movw r5, #0x6b80
	movw r1, #:lower16:write_pixel_window_to_port
	movt r5, #0x2003	@ r5 = 0x20036b80
	movt r1, #:upper16:write_pixel_window_to_port
	ldrb.w r0, [r0, #0xe1a]	@ [0x20000f12]
	movw r4, #0x8360
	str r1, [r5, #0]	@ [0x20036b80] = write_pixel_window_to_port
	movt r4, #0x2000	@ r4 = text buffer 0x20008360
	movw r1, #:lower16:t_080bc681	@ "3:/System file/%d.jpg"
	add.w r2, r0, #0x92
	movt r1, #:upper16:t_080bc681
	mov r0, r4
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0
	movs r2, #0xd3
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r5, #0]	@ [0x20036b80] = copy_rect_into_clip_buffer
	pop {r4, r5, r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08011828 - draw the two-column scroll indicator: returns at once unless
@ [0x20001060]==5. Sets the region record 0x20008350..56 = (x=0x13a, y=0x1d,
@ w=2, h=0xad), allocates w*h*2 = 0x2b4 bytes with alloc_units_of_32_bytes
@ (0803acfc) into [0x20008358]. When that succeeds: if byte [0x20000f13]==0
@ all w*h halfwords are set to 0x8c73; otherwise they are zeroed and, with
@ n = ceil([0x20000f13]/6) (the byte quotient plus 1 when the remainder is
@ nonzero) and s = 0xad/n, the rows from s*([0x20000f15]/6)+0x1d to
@ s*([0x20000f15]/6+1)+0x1c are set to 0x8c73 in both columns (every store is
@ bounds-tested against the region record). Then fn_08042ee0 and
@ semaphore_take_timeout([0x20002d84], 0xffffffff); when that returns 1 and
@ [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080]==0, otherwise, when (buf - [0x20001078]) >> 10 < 0xaf,
@ zero_bytes (080082bc) clears its entry range in the halfword table
@ [0x2000107c]. Purpose not determined from the code (pixel output only: the
@ two columns x 0x13a..0x13b get 0x8c73 on every row when [0x20000f13]==0,
@ otherwise on the rows given by the arithmetic above over a zeroed
@ background; the meaning of [0x20000f13] and [0x20000f15] is not determined).
@ Division by 6 is done as a multiply by 0xaaaaaaab and a shift (umull).
@ ----------------------------------------------------------------------------
	.section .text.fn_08011828,"ax",%progbits
	.p2align 2
	.global fn_08011828
	.thumb_func
	.type fn_08011828, %function
fn_08011828:
	push {r4, r5, r6, lr}
	movw r5, #0xf8
	movt r5, #0x2000	@ r5 = 0x200000f8
	ldrb.w r0, [r5, #0xf68]	@ [0x20001060]
	cmp r0, #5
	bne.w .L08011b66
	movw r4, #0x8350
	movt r4, #0x2000	@ r4 = region record 0x20008350
	mov.w r0, #0x13a
	strh r0, [r4, #0]	@ x = 0x13a
	movs r0, #0x1d
	strh r0, [r4, #2]	@ y = 0x1d
	movs r0, #2
	strh r0, [r4, #4]	@ w = 2
	movs r0, #0xad
	strh r0, [r4, #6]	@ h = 0xad
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.w .L08011b66
	ldrb.w r1, [r5, #0xe1b]	@ [0x20000f13]
	ldr.w r12, [r4, #8]	@ r12 = buffer
	ldrh r0, [r4, #4]
	ldrh r2, [r4, #6]
	cmp r1, #0
	mul r0, r2, r0	@ halfword count
	beq.w .L08011ad0
	cbz r0, .L080118d2
	subs r3, r0, #1
	and.w lr, r0, #3	@ remainder
	movs r2, #0
	cmp r3, #3
	mov.w r3, #0
	bcc.n .L080118b0
	movw r3, #0xfffc
	movt r3, #0x7fff
	ands r0, r3	@ count rounded down to a multiple of 4
	sub.w r6, r12, #8
	movs r3, #0
.L080118a4:
	adds r3, #4
	str.w r2, [r6, #8]!	@ four zero halfwords per pass
	cmp r0, r3
	str r2, [r6, #4]
	bne.n .L080118a4
.L080118b0:
	cmp.w lr, #0
	beq.n .L080118d2
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [r12, r3, lsl #1]
	beq.n .L080118d2
	add.w r2, r12, r3, lsl #1
	cmp.w lr, #2
	strh r0, [r2, #2]
	itt ne
	movne r0, #0
	strhne r0, [r2, #4]
.L080118d2:
	movw r2, #0xaaab
	uxtb r0, r1
	movt r2, #0xaaaa	@ r2 = 0xaaaaaaab (reciprocal of 6 for umull)
	umull r0, r3, r0, r2	@ r3 = [0x20000f13] / 6 * 4 (before the shift)
	ldrb.w r0, [r5, #0xe1d]	@ [0x20000f15]
	rsbs r1, r1, #0
	umull r0, r2, r0, r2	@ r2 = [0x20000f15] / 6 * 4 (before the shift)
	lsrs r0, r3, #2	@ [0x20000f13] / 6
	sub.w r6, r0, r0, lsl #2
	lsls r6, r6, #1
	uxtb r6, r6
	uxtb r1, r1
	cmp r6, r1	@ remainder of [0x20000f13] / 6 versus 0
	mov.w r1, #0xad
	mov.w r5, #1
	it ne
	addne.w r0, r5, r3, lsr #2	@ n = quotient + 1 when the remainder is nonzero
	udiv r3, r1, r0	@ s = 0xad / n
	lsrs r0, r2, #2	@ [0x20000f15] / 6
	add.w r2, r5, r2, lsr #2	@ [0x20000f15] / 6 + 1
	mul r1, r3, r0
	muls r2, r3, r2
	add.w r0, r1, #0x1d	@ first row = s*([0x20000f15]/6) + 0x1d
	add.w r6, r2, #0x1c	@ last row = s*([0x20000f15]/6 + 1) + 0x1c
	cmp r0, r6
	bhi.w .L08011b1a
	lsls r3, r3, #0x1f
	add.w r3, r1, #1
	beq.n .L080119c0
	ldrh r6, [r4, #0]
	cmp.w r6, #0x13a
	bhi.n .L08011974
	ldrh r6, [r4, #0]
	ldrh r5, [r4, #4]
	add r6, r5
	cmp.w r6, #0x13a
	bls.n .L08011974
	ldrh r6, [r4, #2]
	cmp r0, r6
	bcc.n .L08011974
	ldrh r6, [r4, #2]
	ldrh r5, [r4, #6]
	add r6, r5
	cmp r6, r0
	bls.n .L08011974
	ldr.w r12, [r4, #8]
	ldrh.w lr, [r4, #0]
	ldrh r6, [r4, #2]
	ldrh r5, [r4, #4]
	subs r6, r0, r6
	muls r5, r6, r5
	sub.w r6, r5, lr
	movw r5, #0x8c73
	add.w r6, r12, r6, lsl #1
	movt r5, #0xffff
	strh.w r5, [r6, #0x274]
.L08011974:
	ldrh r6, [r4, #0]
	lsrs r6, r6, #2
	cmp r6, #0x4e
	bhi.n .L080119bc
	ldrh r6, [r4, #0]
	ldrh r5, [r4, #4]
	add r6, r5
	cmp.w r6, #0x13c
	bcc.n .L080119bc
	ldrh r6, [r4, #2]
	cmp r0, r6
	bcc.n .L080119bc
	ldrh r6, [r4, #2]
	ldrh r5, [r4, #6]
	add r6, r5
	cmp r6, r0
	bls.n .L080119bc
	ldr.w r12, [r4, #8]
	ldrh.w lr, [r4, #0]
	ldrh r6, [r4, #2]
	ldrh r5, [r4, #4]
	subs r0, r0, r6
	muls r0, r5, r0
	sub.w r0, r0, lr
	movw r6, #0x8c73
	add.w r0, r12, r0, lsl #1
	movt r6, #0xffff
	strh.w r6, [r0, #0x276]
.L080119bc:
	add.w r0, r1, #0x1e
.L080119c0:
	cmp r2, r3
	beq.w .L08011b1a
	movw r12, #0x8c73
	adds r2, #0x1b
	b.n .L080119da
	.byte 0x00, 0xbf	@ padding
.L080119d0:
	cmp r0, r2
	add.w r0, r0, #2
	beq.w .L08011b1a
.L080119da:
	ldrh r3, [r4, #0]
	cmp.w r3, #0x13a
	bhi.n .L08011a14
	ldrh r3, [r4, #0]
	ldrh r6, [r4, #4]
	add r3, r6
	cmp.w r3, #0x13a
	bls.n .L08011a14
	ldrh r3, [r4, #2]
	cmp r0, r3
	bcc.n .L08011a14
	ldrh r3, [r4, #2]
	ldrh r6, [r4, #6]
	add r3, r6
	cmp r3, r0
	bls.n .L08011a14
	ldr r3, [r4, #8]
	ldrh r6, [r4, #0]
	ldrh r5, [r4, #2]
	ldrh r1, [r4, #4]
	subs r5, r0, r5
	muls r1, r5, r1
	subs r1, r1, r6
	add.w r1, r3, r1, lsl #1
	strh.w r12, [r1, #0x274]
.L08011a14:
	ldrh r1, [r4, #0]
	lsrs r1, r1, #2
	cmp r1, #0x4e
	bhi.n .L08011a50
	ldrh r1, [r4, #0]
	ldrh r3, [r4, #4]
	add r1, r3
	cmp.w r1, #0x13c
	bcc.n .L08011a50
	ldrh r1, [r4, #2]
	cmp r0, r1
	bcc.n .L08011a50
	ldrh r1, [r4, #2]
	ldrh r3, [r4, #6]
	add r1, r3
	cmp r1, r0
	bls.n .L08011a50
	ldr r1, [r4, #8]
	ldrh r3, [r4, #0]
	ldrh r6, [r4, #2]
	ldrh r5, [r4, #4]
	subs r6, r0, r6
	muls r6, r5, r6
	subs r3, r6, r3
	add.w r1, r1, r3, lsl #1
	strh.w r12, [r1, #0x276]
	nop
.L08011a50:
	ldrh r1, [r4, #0]
	adds r3, r0, #1
	cmp.w r1, #0x13a
	bhi.n .L08011a90
	ldrh r1, [r4, #0]
	ldrh r6, [r4, #4]
	add r1, r6
	cmp.w r1, #0x13a
	bls.n .L08011a90
	ldrh r1, [r4, #2]
	cmp r3, r1
	bcc.n .L08011a90
	ldrh r1, [r4, #2]
	ldrh r6, [r4, #6]
	add r1, r6
	cmp r1, r3
	bls.n .L08011a90
	ldr.w lr, [r4, #8]
	ldrh r6, [r4, #0]
	ldrh r5, [r4, #2]
	ldrh r1, [r4, #4]
	subs r5, r0, r5
	adds r5, #1
	muls r1, r5, r1
	subs r1, r1, r6
	add.w r1, lr, r1, lsl #1
	strh.w r12, [r1, #0x274]
.L08011a90:
	ldrh r1, [r4, #0]
	lsrs r1, r1, #2
	cmp r1, #0x4e
	bhi.n .L080119d0
	ldrh r1, [r4, #0]
	ldrh r6, [r4, #4]
	add r1, r6
	cmp.w r1, #0x13c
	bcc.n .L080119d0
	ldrh r1, [r4, #2]
	cmp r3, r1
	bcc.n .L080119d0
	ldrh r1, [r4, #2]
	ldrh r6, [r4, #6]
	add r1, r6
	cmp r1, r3
	bls.w .L080119d0
	ldr r1, [r4, #8]
	ldrh r3, [r4, #0]
	ldrh r6, [r4, #2]
	ldrh r5, [r4, #4]
	subs r6, r0, r6
	adds r6, #1
	muls r6, r5, r6
	subs r3, r6, r3
	add.w r1, r1, r3, lsl #1
	strh.w r12, [r1, #0x276]
	b.n .L080119d0
.L08011ad0:
	cbz r0, .L08011b1a
	subs r2, r0, #1
	movw r1, #0x8c73
	cmp r2, #3
	and.w r2, r0, #3	@ remainder
	bcs.n .L08011ae4
	movs r3, #0
	b.n .L08011b04
.L08011ae4:
	movw r3, #0xfffc
	movt r3, #0x7fff
	ands r0, r3	@ count rounded down to a multiple of 4
	sub.w r5, r12, #8
	movs r3, #0
.L08011af4:
	adds r3, #4
	strh.w r1, [r5, #8]!	@ four halfwords of 0x8c73 per pass
	cmp r0, r3
	strh r1, [r5, #2]
	strh r1, [r5, #4]
	strh r1, [r5, #6]
	bne.n .L08011af4
.L08011b04:
	cbz r2, .L08011b1a
	cmp r2, #1
	strh.w r1, [r12, r3, lsl #1]
	beq.n .L08011b1a
	add.w r0, r12, r3, lsl #1
	cmp r2, #2
	strh r1, [r0, #2]
	it ne
	strhne r1, [r0, #4]
.L08011b1a:
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08011b66
	ldr r1, [r4, #8]
	cbz r1, .L08011b66
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L08011b68
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08011b66
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, r5, r6, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08011b66:
	pop {r4, r5, r6, pc}
.L08011b68:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	pop.w {r4, r5, r6, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08011b74 - draw the bottom strip: returns at once unless
@ [0x20001060]==2. Sets the region record 0x20008350..56 = (x=0, y=0xdd,
@ w=0x140, h=0x13), allocates w*h*2 = 0x2f80 bytes with
@ alloc_units_of_32_bytes (0803acfc) into [0x20008358]. When that succeeds
@ calls draw_bottom_strip (0801e784) (no zero fill). Then fn_08042ee0 and
@ semaphore_take_timeout([0x20002d84], 0xffffffff); when that returns 1 and
@ [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080]==0, otherwise, when (buf - [0x20001078]) >> 10 < 0xaf,
@ zero_bytes (080082bc) clears its entry range in the halfword table
@ [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08011b74,"ax",%progbits
	.p2align 2
	.global fn_08011b74
	.thumb_func
	.type fn_08011b74, %function
fn_08011b74:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]	@ [0x20001060]
	cmp r0, #2
	bne.n .L08011c02
	movw r4, #0x8350
	movt r4, #0x2000	@ r4 = region record 0x20008350
	movs r0, #0
	strh r0, [r4, #0]	@ x = 0
	movs r0, #0xdd
	strh r0, [r4, #2]	@ y = 0xdd
	mov.w r0, #0x140
	strh r0, [r4, #4]	@ w = 0x140
	movs r0, #0x13
	strh r0, [r4, #6]	@ h = 0x13
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cbz r0, .L08011c02
	bl draw_bottom_strip
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08011c02
	ldr r1, [r4, #8]
	cbz r1, .L08011c02
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L08011c04
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08011c02
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08011c02:
	pop {r4, pc}
.L08011c04:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	pop.w {r4, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08011c10 - draw the thumbnail page: returns at once unless
@ [0x20001060]==5. Sets the region record 0x20008350..56 = (x=0, y=0x1d,
@ w=0x137, h=0xad), allocates w*h*2 = 0x1a456 bytes with
@ alloc_units_of_32_bytes (0803acfc) into [0x20008358]. When that succeeds
@ zero-fills w*h halfwords (unrolled by 4, remainder 0..3) and calls
@ draw_thumbnail_grid (0801ede8). Then fn_08042ee0 and
@ semaphore_take_timeout([0x20002d84], 0xffffffff); when that returns 1 and
@ [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080]==0, otherwise, when (buf - [0x20001078]) >> 10 < 0xaf,
@ zero_bytes (080082bc) clears its entry range in the halfword table
@ [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08011c10,"ax",%progbits
	.p2align 2
	.global fn_08011c10
	.thumb_func
	.type fn_08011c10, %function
fn_08011c10:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]	@ [0x20001060]
	cmp r0, #5
	bne.n .L08011cfa
	movw r4, #0x8350
	movt r4, #0x2000	@ r4 = region record 0x20008350
	movs r0, #0
	strh r0, [r4, #0]	@ x = 0
	movs r0, #0x1d
	strh r0, [r4, #2]	@ y = 0x1d
	movw r0, #0x137
	strh r0, [r4, #4]	@ w = 0x137
	movs r0, #0xad
	strh r0, [r4, #6]	@ h = 0xad
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L08011cfa
	ldr.w r12, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0	@ halfword count
	cbz r0, .L08011caa
	subs r1, r0, #1
	and.w lr, r0, #3	@ remainder
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	bcc.n .L08011c88
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1	@ count rounded down to a multiple of 4
	sub.w r1, r12, #8
	movs r2, #0
.L08011c7c:
	adds r2, #4
	str.w r3, [r1, #8]!	@ four halfwords per pass
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L08011c7c
.L08011c88:
	cmp.w lr, #0
	beq.n .L08011caa
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [r12, r2, lsl #1]
	beq.n .L08011caa
	add.w r1, r12, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L08011caa:
	bl draw_thumbnail_grid
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08011cfa
	ldr r1, [r4, #8]
	cbz r1, .L08011cfa
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L08011cfc
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08011cfa
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08011cfa:
	pop {r4, pc}
.L08011cfc:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	pop.w {r4, lr}
	bx r1	@ tail call (*[0x20001070])(0)
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08011d08 - show the selected screenshot and draw its number.
@ No parameters, no return value. Formats "2:/Screenshot file/%d.bmp" with the
@ byte at 0x20000f1d + [0x20000f15] into 0x20008360
@ (format_to_buffer_080073b4) and calls show_bmp_file_fullscreen (08031534)
@ (its purpose is not determined from the code). Sets the region record
@ 0x20008350..56 = (x=0x11e, y=0x14, w=0x18, h=0x14), allocates w*h*2 = 0x3c0
@ bytes with alloc_units_of_32_bytes (0803acfc) into [0x20008358]. When that
@ succeeds calls fn_080097e8 (reads 0x60020000 into the region buffer, see
@ fn_08011238), formats "%d" with the same byte into 0x20008360 and draws it
@ with draw_wrapped_text_in_box (0800f154)(0x11e, 0x14, 0x18, 0x14,
@ 0x20008360, 0x20001144, 0xffff, 1). Then fn_08042ee0 and
@ semaphore_take_timeout([0x20002d84], 0xffffffff); when that returns 1 and
@ [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080]==0, otherwise, when (buf - [0x20001078]) >> 10 < 0xaf,
@ zero_bytes (080082bc) clears its entry range in the halfword table
@ [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08011d08,"ax",%progbits
	.p2align 2
	.global fn_08011d08
	.thumb_func
	.type fn_08011d08, %function
fn_08011d08:
	push {r4, r5, r6, lr}
	sub sp, #0x10
	movw r6, #0xf8
	movt r6, #0x2000	@ r6 = 0x200000f8
	ldrb.w r0, [r6, #0xe1d]	@ [0x20000f15]
	movw r4, #0x8360
	add r0, r6
	ldrb.w r2, [r0, #0xe25]	@ byte at 0x20000f1d + [0x20000f15]
	movt r4, #0x2000	@ r4 = text buffer 0x20008360
	movw r1, #:lower16:t_080bcad2	@ "2:/Screenshot file/%d.bmp"
	movt r1, #:upper16:t_080bcad2
	mov r0, r4
	bl format_to_buffer_080073b4
	bl show_bmp_file_fullscreen
	movw r5, #0x8350
	movt r5, #0x2000	@ r5 = region record 0x20008350
	mov.w r0, #0x11e
	strh r0, [r5, #0]	@ x = 0x11e
	movs r0, #0x14
	movs r1, #0x18
	strh r0, [r5, #2]	@ y = 0x14
	strh r1, [r5, #4]	@ w = 0x18
	strh r0, [r5, #6]	@ h = 0x14
	ldrh r0, [r5, #4]
	ldrh r1, [r5, #6]
	muls r0, r1, r0
	lsls r0, r0, #1	@ w*h*2 bytes
	bl alloc_units_of_32_bytes
	str r0, [r5, #8]
	ldr r0, [r5, #8]
	cmp r0, #0
	beq.n .L08011dec
	bl fn_080097e8
	ldrb.w r0, [r6, #0xe1d]	@ [0x20000f15]
	movw r1, #:lower16:t_080bc040	@ "%d"
	add r0, r6
	ldrb.w r2, [r0, #0xe25]	@ byte at 0x20000f1d + [0x20000f15]
	movt r1, #:upper16:t_080bc040
	mov r0, r4
	bl format_to_buffer_080073b4
	movw r1, #0x1144
	movw r0, #0xffff
	movt r1, #0x2000	@ r1 = 0x20001144
	movs r6, #1
	strd r4, r1, [sp]
	str r0, [sp, #8]
	movw r0, #0x119	@ box 0x119..0x13a centred on the old one (0x11e, 0x18 wide): three digits are
	movs r1, #0x14	@ 29 px in the 20 px font (this rewrite)
	movs r2, #0x22
	movs r3, #0x14
	str r6, [sp, #0xc]
	bl draw_wrapped_text_in_box
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]	@ [0x20002d84]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08011dec
	ldr r1, [r5, #8]
	cbz r1, .L08011dec
	movw r0, #0x1070
	movt r0, #0x2000	@ r0 = 0x20001070
	ldrb r2, [r0, #0x10]	@ [0x20001080]
	cbz r2, .L08011df0
	ldr r2, [r0, #8]	@ [0x20001078]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08011dec
	ldr r0, [r0, #0xc]	@ [0x2000107c] halfword table
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L08011dec
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08011dec:
	add sp, #0x10
	pop {r4, r5, r6, pc}
.L08011df0:
	ldr r1, [r0, #0]	@ callback [0x20001070]
	movs r0, #0
	add sp, #0x10
	pop.w {r4, r5, r6, lr}
	bx r1	@ tail call (*[0x20001070])(0)
