@ ui_pages_69.s - UI page drawing routines (system image drawing and page redraw helpers)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0800fe9c - draws the system image "3:/System file/36.jpg" at x=0x59, y=0x27.
@ Returns at once unless byte [0x20001060] (read at 0x200000f8+0xf68) is 0.
@ Sets the pixel-writer pointer [0x20036b80] = write_pixel_window_to_port
@ (0x0803a23d) around the call and restores copy_rect_into_clip_buffer
@ (0x0803a175) afterwards. Calls decode_image_file_with_offset
@ (08039f6c) with (name, 0x59, 0x27).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800fe9c,"ax",%progbits
	.p2align 2
	.global fn_0800fe9c
	.thumb_func
	.type fn_0800fe9c, %function
fn_0800fe9c:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #0
	it ne
	popne {r4, pc}
	movw r4, #0x6b80
	movw r0, #:lower16:write_pixel_window_to_port
	movt r4, #0x2003
	movt r0, #:upper16:write_pixel_window_to_port
	str r0, [r4, #0]
	adr r0, .L0800fed8
	movs r1, #0x59
	movs r2, #0x27
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r4, #0]
	pop {r4, pc}
.L0800fed8:
	.asciz "3:/System file/36.jpg"
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0800fef0 - redraws the rotating banner image; no parameters, no return value.
@ Sets the region record [0x20008350..56] = (0x121, 6, 0x10, 8) (x, y, w, h
@ halfwords) and allocates 0x100 bytes (w*h*2) with alloc_units_of_32_bytes
@ (0803acfc) into [0x20008358]; nothing else happens when that fails.
@ Increments byte [0x2000835e] and writes 0 when the new value is above 2 (value
@ cycles 0,1,2), formats "3:/System file/%d.jpg" with [0x2000835e]+7 (images
@ 7..9) into 0x20008360 with format_to_buffer_080073b4, draws it with
@ decode_image_file_with_offset (08039f6c)(name, 0x121, 6). Then calls
@ fn_08042ee0 and semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff);
@ when that returns 1 and [0x20008358] != 0 the buffer is released: callback
@ (*[0x20001070])(0) if [0x20001080] == 0, else when
@ (buf - [0x20001078]) >> 10 < 0xaf, zero_bytes (080082bc) zeroes its entry
@ range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_0800fef0,"ax",%progbits
	.p2align 2
	.global fn_0800fef0
	.thumb_func
	.type fn_0800fef0, %function
fn_0800fef0:
	push {r4, r5, r7, lr}
	movw r5, #0x8350
	movt r5, #0x2000
	movw r0, #0x121
	strh r0, [r5, #0]
	movs r0, #6
	strh r0, [r5, #2]
	movs r0, #0x10
	strh r0, [r5, #4]
	movs r0, #8
	strh r0, [r5, #6]
	ldrh r0, [r5, #4]
	ldrh r1, [r5, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r5, #8]
	ldr r0, [r5, #8]
	cmp r0, #0
	beq.n .L0800ffaa
	movw r0, #0x835e
	movt r0, #0x2000
	ldrb r1, [r0, #0]
	movw r4, #0x8360
	adds r1, #1
	uxtb r2, r1
	cmp r2, #2
	it hi
	movhi r1, #0
	strb r1, [r0, #0]
	movs r0, #7
	uxtab r2, r0, r1
	movt r4, #0x2000
	movw r1, #:lower16:d_080bc680+1
	movt r1, #:upper16:d_080bc680+1
	mov r0, r4
	bl format_to_buffer_080073b4
	mov r0, r4
	movw r1, #0x121
	movs r2, #6
	bl decode_image_file_with_offset
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L0800ffaa
	ldr r1, [r5, #8]
	cbz r1, .L0800ffaa
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L0800ffac
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L0800ffaa
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, r5, r7, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L0800ffaa:
	pop {r4, r5, r7, pc}
.L0800ffac:
	ldr r1, [r0, #0]
	movs r0, #0
	pop.w {r4, r5, r7, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0800ffb8 - draws the system image selected by byte [0x20001061].
@ Returns at once unless byte [0x20001060] is 0. Sets [0x20036b80] =
@ write_pixel_window_to_port (0x0803a23d) around the call and restores
@ copy_rect_into_clip_buffer (0x0803a175) afterwards. Formats
@ "3:/System file/%d.jpg" with [0x20001061]+0x27 into 0x20008360
@ (format_to_buffer_080073b4) and draws it with decode_image_file_with_offset
@ (08039f6c)(name, 0x69, 0xd).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800ffb8,"ax",%progbits
	.p2align 2
	.global fn_0800ffb8
	.thumb_func
	.type fn_0800ffb8, %function
fn_0800ffb8:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #0
	it ne
	popne {r4, r5, r7, pc}
	movw r5, #0x6b80
	movw r1, #:lower16:write_pixel_window_to_port
	movt r5, #0x2003
	movt r1, #:upper16:write_pixel_window_to_port
	ldrb.w r0, [r0, #0xf69]
	movw r4, #0x8360
	str r1, [r5, #0]
	movt r4, #0x2000
	movw r1, #:lower16:d_080bc680+1
	add.w r2, r0, #0x27
	movt r1, #:upper16:d_080bc680+1
	mov r0, r4
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x69
	movs r2, #0xd
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r5, #0]
	pop {r4, r5, r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08010014 - draws the wrapped help text box; no parameters, no return value.
@ Returns at once unless byte [0x20001060] is 0. Sets the region record
@ [0x20008350..56] = (0x4b, 0xbe, 0xaa, 0x19) (x, y, w, h halfwords), allocates
@ 0x2134 bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it zero-fills w*h halfwords; when byte
@ [0x20001061] < 4 it draws with draw_wrapped_text_in_box (0800f154)(0x4b, 0xbe,
@ 0xaa, 0x19, text, 0x20001174, 0x55f, 1), the text pointer read from address
@ [0x0804c924 + 4*[0x20001061]] + 4*[0x20001058] - 4. Then calls fn_08042ee0 and
@ semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff); when that returns
@ 1 and [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf zero_bytes
@ (080082bc) zeroes its entry range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08010014,"ax",%progbits
	.p2align 2
	.global fn_08010014
	.thumb_func
	.type fn_08010014, %function
fn_08010014:
	push {r4, r5, r7, lr}
	sub sp, #0x10
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cbz r0, .L0801002a
.L08010026:
	add sp, #0x10
	pop {r4, r5, r7, pc}
.L0801002a:
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0x4b
	strh r0, [r4, #0]
	movs r0, #0xbe
	strh r0, [r4, #2]
	movs r0, #0xaa
	strh r0, [r4, #4]
	movs r0, #0x19
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L08010026
	ldr.w ip, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	cbz r0, .L080100b2
	subs r1, r0, #1
	and.w lr, r0, #3
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	blo.n .L08010090
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1
	sub.w r1, ip, #8
	movs r2, #0
	nop
.L08010084:
	adds r2, #4
	str r3, [r1, #8]!
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L08010084
.L08010090:
	cmp.w lr, #0
	beq.n .L080100b2
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [ip, r2, lsl #1]
	beq.n .L080100b2
	add.w r1, ip, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L080100b2:
	ldrsb.w r0, [r5, #0xf69]
	cmp r0, #3
	bhi.n .L080100f4
	movw r1, #:lower16:d_0804c924
	movt r1, #:upper16:d_0804c924
	ldr.w r0, [r1, r0, lsl #2]
	ldrb.w r1, [r5, #0xf60]
	movw r2, #0x1174
	add.w r0, r0, r1, lsl #2
	ldr r0, [r0, #-4]
	movw r1, #0x55f
	movt r2, #0x2000
	movs r5, #1
	strd r0, r2, [sp]
	str r1, [sp, #8]
	movs r0, #0x4b
	movs r1, #0xbe
	movs r2, #0xaa
	movs r3, #0x19
	str r5, [sp, #0xc]
	bl draw_wrapped_text_in_box
.L080100f4:
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08010026
	ldr r1, [r4, #8]
	cmp r1, #0
	beq.w .L08010026
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L0801014a
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.w .L08010026
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	beq.w .L08010026
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	add sp, #0x10
	pop {r4, r5, r7, pc}
.L0801014a:
	ldr r1, [r0, #0]
	movs r0, #0
	add sp, #0x10
	pop.w {r4, r5, r7, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08010158 - draws the system image "3:/System file/37.jpg" (index 0x25) at 0,0x3c.
@ Returns at once unless byte [0x20001060] is 0. Sets [0x20036b80] =
@ write_pixel_window_to_port (0x0803a23d) around the call and restores
@ copy_rect_into_clip_buffer (0x0803a175) afterwards. Formats
@ "3:/System file/%d.jpg" with 0x25 into 0x20008360 (format_to_buffer_080073b4)
@ and draws it with decode_image_file_with_offset (08039f6c)(name, 0, 0x3c).
@ ----------------------------------------------------------------------------
	.section .text.fn_08010158,"ax",%progbits
	.p2align 2
	.global fn_08010158
	.thumb_func
	.type fn_08010158, %function
fn_08010158:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #0
	it ne
	popne {r4, r5, r7, pc}
	movw r5, #0x6b80
	movw r0, #:lower16:write_pixel_window_to_port
	movw r4, #0x8360
	movt r5, #0x2003
	movt r0, #:upper16:write_pixel_window_to_port
	movt r4, #0x2000
	movw r1, #:lower16:d_080bc680+1
	str r0, [r5, #0]
	movt r1, #:upper16:d_080bc680+1
	mov r0, r4
	movs r2, #0x25
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0
	movs r2, #0x3c
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r5, #0]
	pop {r4, r5, r7, pc}

@ ----------------------------------------------------------------------------
@ fn_080101ac - draws the system image number 0x26 at x=0xfa, y=0x3c.
@ Returns at once unless byte [0x20001060] is 0. Sets [0x20036b80] =
@ write_pixel_window_to_port (0x0803a23d) around the call and restores
@ copy_rect_into_clip_buffer (0x0803a175) afterwards. Formats
@ "3:/System file/%d.jpg" with 0x26 into 0x20008360 (format_to_buffer_080073b4)
@ and draws it with decode_image_file_with_offset (08039f6c)(name, 0xfa, 0x3c).
@ ----------------------------------------------------------------------------
	.section .text.fn_080101ac,"ax",%progbits
	.p2align 2
	.global fn_080101ac
	.thumb_func
	.type fn_080101ac, %function
fn_080101ac:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #0
	it ne
	popne {r4, r5, r7, pc}
	movw r5, #0x6b80
	movw r0, #:lower16:write_pixel_window_to_port
	movw r4, #0x8360
	movt r5, #0x2003
	movt r0, #:upper16:write_pixel_window_to_port
	movt r4, #0x2000
	movw r1, #:lower16:d_080bc680+1
	str r0, [r5, #0]
	movt r1, #:upper16:d_080bc680+1
	mov r0, r4
	movs r2, #0x26
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0xfa
	movs r2, #0x3c
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r5, #0]
	pop {r4, r5, r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08010200 - draws the system image selected by byte [0x20001061] (+0x33).
@ Returns at once unless byte [0x20001060] is 0. Sets [0x20036b80] =
@ write_pixel_window_to_port (0x0803a23d) around the call and restores
@ copy_rect_into_clip_buffer (0x0803a175) afterwards. Formats
@ "3:/System file/%d.jpg" with [0x20001061]+0x33 into 0x20008360
@ (format_to_buffer_080073b4) and draws it with decode_image_file_with_offset
@ (08039f6c)(name, 0x6a, 0x4b).
@ ----------------------------------------------------------------------------
	.section .text.fn_08010200,"ax",%progbits
	.p2align 2
	.global fn_08010200
	.thumb_func
	.type fn_08010200, %function
fn_08010200:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #0
	it ne
	popne {r4, r5, r7, pc}
	movw r5, #0x6b80
	movw r1, #:lower16:write_pixel_window_to_port
	movt r5, #0x2003
	movt r1, #:upper16:write_pixel_window_to_port
	ldrb.w r0, [r0, #0xf69]
	movw r4, #0x8360
	str r1, [r5, #0]
	movt r4, #0x2000
	movw r1, #:lower16:d_080bc680+1
	add.w r2, r0, #0x33
	movt r1, #:upper16:d_080bc680+1
	mov r0, r4
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x6a
	movs r2, #0x4b
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r5, #0]
	pop {r4, r5, r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0801025c - draws the system image selected by byte [0x20001061] (+0x2b).
@ Returns at once unless byte [0x20001060] is 0. Sets [0x20036b80] =
@ write_pixel_window_to_port (0x0803a23d) around the call and restores
@ copy_rect_into_clip_buffer (0x0803a175) afterwards. Formats
@ "3:/System file/%d.jpg" with [0x20001061]+0x2b into 0x20008360
@ (format_to_buffer_080073b4) and draws it with decode_image_file_with_offset
@ (08039f6c)(name, 0, 0x5f).
@ ----------------------------------------------------------------------------
	.section .text.fn_0801025c,"ax",%progbits
	.p2align 2
	.global fn_0801025c
	.thumb_func
	.type fn_0801025c, %function
fn_0801025c:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #0
	it ne
	popne {r4, r5, r7, pc}
	movw r5, #0x6b80
	movw r1, #:lower16:write_pixel_window_to_port
	movt r5, #0x2003
	movt r1, #:upper16:write_pixel_window_to_port
	ldrb.w r0, [r0, #0xf69]
	movw r4, #0x8360
	str r1, [r5, #0]
	movt r4, #0x2000
	movw r1, #:lower16:d_080bc680+1
	add.w r2, r0, #0x2b
	movt r1, #:upper16:d_080bc680+1
	mov r0, r4
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0
	movs r2, #0x5f
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r5, #0]
	pop {r4, r5, r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080102b8 - draws the system image selected by byte [0x20001061] (+0x2f).
@ Returns at once unless byte [0x20001060] is 0. Sets [0x20036b80] =
@ write_pixel_window_to_port (0x0803a23d) around the call and restores
@ copy_rect_into_clip_buffer (0x0803a175) afterwards. Formats
@ "3:/System file/%d.jpg" with [0x20001061]+0x2f into 0x20008360
@ (format_to_buffer_080073b4) and draws it with decode_image_file_with_offset
@ (08039f6c)(name, 0x10a, 0x5f).
@ ----------------------------------------------------------------------------
	.section .text.fn_080102b8,"ax",%progbits
	.p2align 2
	.global fn_080102b8
	.thumb_func
	.type fn_080102b8, %function
fn_080102b8:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #0
	it ne
	popne {r4, r5, r7, pc}
	movw r5, #0x6b80
	movw r1, #:lower16:write_pixel_window_to_port
	movt r5, #0x2003
	movt r1, #:upper16:write_pixel_window_to_port
	ldrb.w r0, [r0, #0xf69]
	movw r4, #0x8360
	str r1, [r5, #0]
	movt r4, #0x2000
	movw r1, #:lower16:d_080bc680+1
	add.w r2, r0, #0x2f
	movt r1, #:upper16:d_080bc680+1
	mov r0, r4
	bl format_to_buffer_080073b4
	mov r0, r4
	mov.w r1, #0x10a
	movs r2, #0x5f
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r5, #0]
	pop {r4, r5, r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08010314 - draws the title bar of page 9; no parameters, no return value.
@ Returns at once unless byte [0x20001060] is 9. Sets the region record
@ [0x20008350..56] = (0, 0, 0x10c, 0x14) (x, y, w, h halfwords), allocates 0x29e0
@ bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into [0x20008358].
@ When that succeeds it draws "3:/System file/71.jpg" at (0, 0) with
@ decode_image_file_with_offset (08039f6c), and the text pointer at
@ 0x0804c900 + 4*[0x20001058] with draw_wrapped_text_in_box (0800f154)(0x34, 0,
@ 0xd8, 0x14, text, 0x20001144, 0xffff, 1). Then calls fn_08042ee0 and
@ semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff); when that returns
@ 1 and [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf zero_bytes
@ (080082bc) zeroes its entry range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08010314,"ax",%progbits
	.p2align 2
	.global fn_08010314
	.thumb_func
	.type fn_08010314, %function
fn_08010314:
	push {r4, r5, r7, lr}
	sub sp, #0x10
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #9
	bne.n .L080103e2
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0
	strh r0, [r4, #0]
	strh r0, [r4, #2]
	mov.w r0, #0x10c
	strh r0, [r4, #4]
	movs r0, #0x14
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L080103e2
	movw r0, #:lower16:d_080bc456
	movt r0, #:upper16:d_080bc456
	movs r1, #0
	movs r2, #0
	bl decode_image_file_with_offset
	ldrb.w r0, [r5, #0xf60]
	movw r1, #:lower16:d_0804c904
	movt r1, #:upper16:d_0804c904
	add.w r0, r1, r0, lsl #2
	ldr r0, [r0, #-4]
	movw r2, #0x1144
	movw r1, #0xffff
	movt r2, #0x2000
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
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L080103e2
	ldr r1, [r4, #8]
	cbz r1, .L080103e2
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L080103e6
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L080103e2
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L080103e2
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L080103e2:
	add sp, #0x10
	pop {r4, r5, r7, pc}
.L080103e6:
	ldr r1, [r0, #0]
	movs r0, #0
	add sp, #0x10
	pop.w {r4, r5, r7, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080103f4 - clears and redraws the page-9 side panel; no parameters.
@ Returns at once unless byte [0x20001060] is 9. Sets the region record
@ [0x20008350..56] = (0, 0x18, 0x6c, 0xd8) (x, y, w, h halfwords), allocates
@ 0xb640 bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it zero-fills w*h halfwords and calls
@ fn_08012de0. Then calls fn_08042ee0 and semaphore_take_timeout (080423a8)
@ ([0x20002d84], 0xffffffff); when that returns 1 and [0x20008358] != 0 the buffer
@ is released: callback (*[0x20001070])(0) if [0x20001080] == 0, else when
@ (buf - [0x20001078]) >> 10 < 0xaf zero_bytes (080082bc) zeroes its entry range
@ in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_080103f4,"ax",%progbits
	.p2align 2
	.global fn_080103f4
	.thumb_func
	.type fn_080103f4, %function
fn_080103f4:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #9
	bne.n .L080104de
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0
	strh r0, [r4, #0]
	movs r0, #0x18
	strh r0, [r4, #2]
	movs r0, #0x6c
	strh r0, [r4, #4]
	movs r0, #0xd8
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L080104de
	ldr.w ip, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	cbz r0, .L0801048e
	subs r1, r0, #1
	and.w lr, r0, #3
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	blo.n .L0801046c
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1
	sub.w r1, ip, #8
	movs r2, #0
	nop
.L08010460:
	adds r2, #4
	str r3, [r1, #8]!
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L08010460
.L0801046c:
	cmp.w lr, #0
	beq.n .L0801048e
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [ip, r2, lsl #1]
	beq.n .L0801048e
	add.w r1, ip, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L0801048e:
	bl fn_08012de0
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L080104de
	ldr r1, [r4, #8]
	cbz r1, .L080104de
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L080104e0
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L080104de
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L080104de:
	pop {r4, pc}
.L080104e0:
	ldr r1, [r0, #0]
	movs r0, #0
	pop.w {r4, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080104ec - redraws the page-2 title strip; no parameters, no return value.
@ Returns at once unless byte [0x20001060] is 2. Sets the region record
@ [0x20008350..56] = (0x34, 0, 0xd8, 0x14) (x, y, w, h halfwords), allocates
@ 0x21c0 bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it calls fn_08012ff4 (no zero fill). Then
@ calls fn_08042ee0 and semaphore_take_timeout (080423a8)([0x20002d84],
@ 0xffffffff); when that returns 1 and [0x20008358] != 0 the buffer is released:
@ callback (*[0x20001070])(0) if [0x20001080] == 0, else when
@ (buf - [0x20001078]) >> 10 < 0xaf zero_bytes (080082bc) zeroes its entry range
@ in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_080104ec,"ax",%progbits
	.p2align 2
	.global fn_080104ec
	.thumb_func
	.type fn_080104ec, %function
fn_080104ec:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #2
	bne.n .L08010578
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0x34
	strh r0, [r4, #0]
	movs r0, #0
	strh r0, [r4, #2]
	movs r0, #0xd8
	strh r0, [r4, #4]
	movs r0, #0x14
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cbz r0, .L08010578
	bl fn_08012ff4
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08010578
	ldr r1, [r4, #8]
	cbz r1, .L08010578
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L0801057a
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08010578
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08010578:
	pop {r4, pc}
.L0801057a:
	ldr r1, [r0, #0]
	movs r0, #0
	pop.w {r4, lr}
	bx r1

@ ----------------------------------------------------------------------------
@ fn_08010584 - clears and redraws the page-9 main panel; no parameters.
@ Returns at once unless byte [0x20001060] is 9. Sets the region record
@ [0x20008350..56] = (0x72, 0x1b, 0xce, 0xd5) (x, y, w, h halfwords), allocates
@ 0x156cc bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it zero-fills w*h halfwords and calls
@ draw_panels_by_selector_20001062 (08013338). Then calls fn_08042ee0 and
@ semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff); when that returns
@ 1 and [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf zero_bytes
@ (080082bc) zeroes its entry range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08010584,"ax",%progbits
	.p2align 2
	.global fn_08010584
	.thumb_func
	.type fn_08010584, %function
fn_08010584:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #9
	bne.n .L0801066e
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0x72
	strh r0, [r4, #0]
	movs r0, #0x1b
	strh r0, [r4, #2]
	movs r0, #0xce
	strh r0, [r4, #4]
	movs r0, #0xd5
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L0801066e
	ldr.w ip, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	cbz r0, .L0801061e
	subs r1, r0, #1
	and.w lr, r0, #3
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	blo.n .L080105fc
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1
	sub.w r1, ip, #8
	movs r2, #0
	nop
.L080105f0:
	adds r2, #4
	str r3, [r1, #8]!
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L080105f0
.L080105fc:
	cmp.w lr, #0
	beq.n .L0801061e
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [ip, r2, lsl #1]
	beq.n .L0801061e
	add.w r1, ip, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L0801061e:
	bl draw_panels_by_selector_20001062
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L0801066e
	ldr r1, [r4, #8]
	cbz r1, .L0801066e
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L08010670
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L0801066e
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L0801066e:
	pop {r4, pc}
.L08010670:
	ldr r1, [r0, #0]
	movs r0, #0
	pop.w {r4, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0801067c - draws the system image "3:/System file/87.jpg" at (0, 0).
@ Returns at once unless byte [0x20001060] is 7. Sets [0x20036b80] =
@ write_pixel_window_to_port (0x0803a23d) around the call and restores
@ copy_rect_into_clip_buffer (0x0803a175) afterwards. Calls
@ decode_image_file_with_offset (08039f6c)(name, 0, 0). Afterwards clears bit 1
@ of the words at 0x40005c40 and 0x40005c60.
@ ----------------------------------------------------------------------------
	.section .text.fn_0801067c,"ax",%progbits
	.p2align 2
	.global fn_0801067c
	.thumb_func
	.type fn_0801067c, %function
fn_0801067c:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #7
	it ne
	popne {r4, pc}
	movw r4, #0x6b80
	movw r0, #:lower16:write_pixel_window_to_port
	movt r4, #0x2003
	movt r0, #:upper16:write_pixel_window_to_port
	str r0, [r4, #0]
	adr r0, .L080106d0
	movs r1, #0
	movs r2, #0
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r4, #0]
	movw r0, #0x5c40
	movt r0, #0x4000
	ldr r1, [r0, #0]
	bic.w r1, r1, #2
	str r1, [r0, #0]
	ldr r1, [r0, #0x20]
	bic.w r1, r1, #2
	str r1, [r0, #0x20]
	pop {r4, pc}
.L080106d0:
	.asciz "3:/System file/87.jpg"
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080106e8 - draws the page-3 title strip; no parameters, no return value.
@ Returns at once unless byte [0x20001060] is 3. Sets the region record
@ [0x20008350..56] = (0x34, 0, 0xd8, 0x14) (x, y, w, h halfwords), allocates
@ 0x21c0 bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it draws "3:/System file/88.jpg" at (0x34, 0)
@ with decode_image_file_with_offset (08039f6c), and the text pointer at
@ 0x0804c394 + 4*[0x20001058] with draw_wrapped_text_in_box (0800f154)(0x34, 0,
@ 0xd8, 0x14, text, 0x20001144, 0xffff, 1). Then calls fn_08042ee0 and
@ semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff); when that returns
@ 1 and [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf zero_bytes
@ (080082bc) zeroes its entry range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_080106e8,"ax",%progbits
	.p2align 2
	.global fn_080106e8
	.thumb_func
	.type fn_080106e8, %function
fn_080106e8:
	push {r4, r5, r7, lr}
	sub sp, #0x10
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #3
	bne.n .L080107b6
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0x34
	strh r0, [r4, #0]
	movs r0, #0
	strh r0, [r4, #2]
	movs r0, #0xd8
	strh r0, [r4, #4]
	movs r0, #0x14
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L080107b6
	movw r0, #:lower16:d_080bc612
	movt r0, #:upper16:d_080bc612
	movs r1, #0x34
	movs r2, #0
	bl decode_image_file_with_offset
	ldrb.w r0, [r5, #0xf60]
	movw r1, #:lower16:d_0804c398
	movt r1, #:upper16:d_0804c398
	add.w r0, r1, r0, lsl #2
	ldr r0, [r0, #-4]
	movw r2, #0x1144
	movw r1, #0xffff
	movt r2, #0x2000
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
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L080107b6
	ldr r1, [r4, #8]
	cbz r1, .L080107b6
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L080107ba
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L080107b6
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L080107b6
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L080107b6:
	add sp, #0x10
	pop {r4, r5, r7, pc}
.L080107ba:
	ldr r1, [r0, #0]
	movs r0, #0
	add sp, #0x10
	pop.w {r4, r5, r7, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080107c8 - clears and redraws the page-3 side panel; no parameters.
@ Returns at once unless byte [0x20001060] is 3. Sets the region record
@ [0x20008350..56] = (0, 0x18, 0x6c, 0xd8) (x, y, w, h halfwords), allocates
@ 0xb640 bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it zero-fills w*h halfwords and calls
@ draw_six_row_list_from_first_index (0801579c). Then calls fn_08042ee0 and
@ semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff); when that returns
@ 1 and [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf zero_bytes
@ (080082bc) zeroes its entry range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_080107c8,"ax",%progbits
	.p2align 2
	.global fn_080107c8
	.thumb_func
	.type fn_080107c8, %function
fn_080107c8:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #3
	bne.n .L080108b2
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0
	strh r0, [r4, #0]
	movs r0, #0x18
	strh r0, [r4, #2]
	movs r0, #0x6c
	strh r0, [r4, #4]
	movs r0, #0xd8
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L080108b2
	ldr.w ip, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	cbz r0, .L08010862
	subs r1, r0, #1
	and.w lr, r0, #3
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	blo.n .L08010840
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1
	sub.w r1, ip, #8
	movs r2, #0
	nop
.L08010834:
	adds r2, #4
	str r3, [r1, #8]!
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L08010834
.L08010840:
	cmp.w lr, #0
	beq.n .L08010862
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [ip, r2, lsl #1]
	beq.n .L08010862
	add.w r1, ip, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L08010862:
	bl draw_six_row_list_from_first_index
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L080108b2
	ldr r1, [r4, #8]
	cbz r1, .L080108b2
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L080108b4
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L080108b2
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L080108b2:
	pop {r4, pc}
.L080108b4:
	ldr r1, [r0, #0]
	movs r0, #0
	pop.w {r4, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080108c0 - draws the page-3 selector image at x=0x79, y=0x1d.
@ Returns at once unless byte [0x20001060] is 3. Sets [0x20036b80] =
@ write_pixel_window_to_port (0x0803a23d) around the call and restores
@ copy_rect_into_clip_buffer (0x0803a175) afterwards. Formats
@ "3:/System file/%d.jpg" with (([0x20000f50] == 0) ? 0x67 : 0x5a) + [0x20000f51]
@ into 0x20008360 (format_to_buffer_080073b4) and draws it with
@ decode_image_file_with_offset (08039f6c)(name, 0x79, 0x1d).
@ ----------------------------------------------------------------------------
	.section .text.fn_080108c0,"ax",%progbits
	.p2align 2
	.global fn_080108c0
	.thumb_func
	.type fn_080108c0, %function
fn_080108c0:
	push {r4, r5, r7, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #3
	it ne
	popne {r4, r5, r7, pc}
	movw r5, #0x6b80
	movw r1, #:lower16:write_pixel_window_to_port
	movt r5, #0x2003
	movt r1, #:upper16:write_pixel_window_to_port
	str r1, [r5, #0]
	ldrb.w r1, [r0, #0xe58]
	ldrb.w r0, [r0, #0xe59]
	movs r2, #0x5a
	movw r4, #0x8360
	cmp r1, #0
	it eq
	moveq r2, #0x67
	movt r4, #0x2000
	movw r1, #:lower16:d_080bc680+1
	add r2, r0
	movt r1, #:upper16:d_080bc680+1
	mov r0, r4
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x79
	movs r2, #0x1d
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r5, #0]
	pop {r4, r5, r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08010924 - clears and redraws the page-3 value rows; no parameters.
@ Returns at once unless byte [0x20001060] is 3. Sets the region record
@ [0x20008350..56] = (0x7a, 0x8e, 0xb0, 0x56) (x, y, w, h halfwords), allocates
@ 0x7640 bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it zero-fills w*h halfwords and calls
@ draw_three_value_rows (08015988). Then calls fn_08042ee0 and
@ semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff); when that returns
@ 1 and [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf zero_bytes
@ (080082bc) zeroes its entry range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08010924,"ax",%progbits
	.p2align 2
	.global fn_08010924
	.thumb_func
	.type fn_08010924, %function
fn_08010924:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #3
	bne.n .L08010a0e
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0x7a
	strh r0, [r4, #0]
	movs r0, #0x8e
	strh r0, [r4, #2]
	movs r0, #0xb0
	strh r0, [r4, #4]
	movs r0, #0x56
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L08010a0e
	ldr.w ip, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	cbz r0, .L080109be
	subs r1, r0, #1
	and.w lr, r0, #3
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	blo.n .L0801099c
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1
	sub.w r1, ip, #8
	movs r2, #0
	nop
.L08010990:
	adds r2, #4
	str r3, [r1, #8]!
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L08010990
.L0801099c:
	cmp.w lr, #0
	beq.n .L080109be
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [ip, r2, lsl #1]
	beq.n .L080109be
	add.w r1, ip, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L080109be:
	bl draw_three_value_rows
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08010a0e
	ldr r1, [r4, #8]
	cbz r1, .L08010a0e
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L08010a10
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08010a0e
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08010a0e:
	pop {r4, pc}
.L08010a10:
	ldr r1, [r0, #0]
	movs r0, #0
	pop.w {r4, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08010a1c - draws the page-1 background image at (0, 0).
@ Returns at once unless byte [0x20001060] is 1. Sets [0x20036b80] =
@ write_pixel_window_to_port (0x0803a23d) around the call and restores
@ copy_rect_into_clip_buffer (0x0803a175) afterwards. Draws with
@ decode_image_file_with_offset (08039f6c) at (0, 0) "3:/System file/118.jpg"
@ when byte [0x20001035] != 0, otherwise "3:/System file/119.jpg".
@ ----------------------------------------------------------------------------
	.section .text.fn_08010a1c,"ax",%progbits
	.p2align 2
	.global fn_08010a1c
	.thumb_func
	.type fn_08010a1c, %function
fn_08010a1c:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf68]
	cmp r1, #1
	it ne
	popne {r4, pc}
	movw r4, #0x6b80
	movw r1, #:lower16:write_pixel_window_to_port
	movt r4, #0x2003
	movt r1, #:upper16:write_pixel_window_to_port
	str r1, [r4, #0]
	ldrb.w r1, [r0, #0xf3d]
	adr r2, .L08010a64
	adr r0, .L08010a7c
	cmp r1, #0
	it eq
	moveq r0, r2
	movs r1, #0
	movs r2, #0
	bl decode_image_file_with_offset
	movw r0, #:lower16:copy_rect_into_clip_buffer
	movt r0, #:upper16:copy_rect_into_clip_buffer
	str r0, [r4, #0]
	pop {r4, pc}
.L08010a64:
	.asciz "3:/System file/119.jpg"
	.byte 0x00	@ padding
.L08010a7c:
	.asciz "3:/System file/118.jpg"
	.byte 0x00	@ padding

@ ----------------------------------------------------------------------------
@ fn_08010a94 - draws the page-1 title strip; no parameters, no return value.
@ Returns at once unless byte [0x20001060] is 1. Sets the region record
@ [0x20008350..56] = (0x34, 0, 0xd8, 0x1d) (x, y, w, h halfwords), allocates
@ 0x30f0 bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it draws "3:/System file/120.jpg" at (0x34, 0)
@ with decode_image_file_with_offset (08039f6c), and the text pointer at
@ 0x0804c40c + 4*([0x20001026] + 12*[0x20001058]) with draw_wrapped_text_in_box
@ (0800f154)(0x34, 0, 0xd8, 0x1d, text, 0x200011a4, 0xffff, 1). Then calls
@ fn_08042ee0 and semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff);
@ when that returns 1 and [0x20008358] != 0 the buffer is released: callback
@ (*[0x20001070])(0) if [0x20001080] == 0, else when
@ (buf - [0x20001078]) >> 10 < 0xaf zero_bytes (080082bc) zeroes its entry range
@ in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08010a94,"ax",%progbits
	.p2align 2
	.global fn_08010a94
	.thumb_func
	.type fn_08010a94, %function
fn_08010a94:
	push {r4, r5, r7, lr}
	sub sp, #0x10
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #1
	bne.n .L08010b6e
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0x34
	strh r0, [r4, #0]
	movs r0, #0
	strh r0, [r4, #2]
	movs r0, #0xd8
	strh r0, [r4, #4]
	movs r0, #0x1d
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L08010b6e
	movw r0, #:lower16:d_080bc3fa+1
	movt r0, #:upper16:d_080bc3fa+1
	movs r1, #0x34
	movs r2, #0
	bl decode_image_file_with_offset
	ldrb.w r0, [r5, #0xf60]
	movw r2, #:lower16:d_0804c43c
	ldrb.w r1, [r5, #0xf2e]
	add.w r0, r0, r0, lsl #1
	movt r2, #:upper16:d_0804c43c
	add.w r0, r2, r0, lsl #4
	add.w r0, r0, r1, lsl #2
	ldr r0, [r0, #-0x30]
	movw r2, #0x11a4
	movw r1, #0xffff
	movt r2, #0x2000
	movs r5, #1
	strd r0, r2, [sp]
	str r1, [sp, #8]
	movs r0, #0x34
	movs r1, #0
	movs r2, #0xd8
	movs r3, #0x1d
	str r5, [sp, #0xc]
	bl draw_wrapped_text_in_box
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08010b6e
	ldr r1, [r4, #8]
	cbz r1, .L08010b6e
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L08010b72
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08010b6e
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L08010b6e
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08010b6e:
	add sp, #0x10
	pop {r4, r5, r7, pc}
.L08010b72:
	ldr r1, [r0, #0]
	movs r0, #0
	add sp, #0x10
	pop.w {r4, r5, r7, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08010b80 - clears and redraws the page-1 gauge area; no parameters.
@ Returns at once unless byte [0x20001060] is 1. Sets the region record
@ [0x20008350..56] = (10, 0x20, 300, 0x67) (x, y, w, h halfwords), allocates
@ 0xf168 bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it zero-fills w*h halfwords and calls
@ draw_arc_gauge (08015c70). Then calls fn_08042ee0 and semaphore_take_timeout
@ (080423a8)([0x20002d84], 0xffffffff); when that returns 1 and [0x20008358] != 0
@ the buffer is released: callback (*[0x20001070])(0) if [0x20001080] == 0, else
@ when (buf - [0x20001078]) >> 10 < 0xaf zero_bytes (080082bc) zeroes its entry
@ range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08010b80,"ax",%progbits
	.p2align 2
	.global fn_08010b80
	.thumb_func
	.type fn_08010b80, %function
fn_08010b80:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #1
	bne.n .L08010c6a
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0xa
	strh r0, [r4, #0]
	movs r0, #0x20
	strh r0, [r4, #2]
	mov.w r0, #0x12c
	strh r0, [r4, #4]
	movs r0, #0x67
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L08010c6a
	ldr.w ip, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	cbz r0, .L08010c1a
	subs r1, r0, #1
	and.w lr, r0, #3
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	blo.n .L08010bf8
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1
	sub.w r1, ip, #8
	movs r2, #0
.L08010bec:
	adds r2, #4
	str r3, [r1, #8]!
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L08010bec
.L08010bf8:
	cmp.w lr, #0
	beq.n .L08010c1a
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [ip, r2, lsl #1]
	beq.n .L08010c1a
	add.w r1, ip, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L08010c1a:
	bl draw_arc_gauge
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08010c6a
	ldr r1, [r4, #8]
	cbz r1, .L08010c6a
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L08010c6c
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08010c6a
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08010c6a:
	pop {r4, pc}
.L08010c6c:
	ldr r1, [r0, #0]
	movs r0, #0
	pop.w {r4, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08010c78 - clears and redraws the page-1 icon row; no parameters.
@ Returns at once unless byte [0x20001060] is 1. Sets the region record
@ [0x20008350..56] = (10, 0x96, 300, 0x1c) (x, y, w, h halfwords), allocates
@ 0x41a0 bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]. When that succeeds it zero-fills w*h halfwords and calls
@ draw_seven_icon_row (080163f8). Then calls fn_08042ee0 and
@ semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff); when that returns
@ 1 and [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf zero_bytes
@ (080082bc) zeroes its entry range in the halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08010c78,"ax",%progbits
	.p2align 2
	.global fn_08010c78
	.thumb_func
	.type fn_08010c78, %function
fn_08010c78:
	push {r4, lr}
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf68]
	cmp r0, #1
	bne.n .L08010d62
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0xa
	strh r0, [r4, #0]
	movs r0, #0x96
	strh r0, [r4, #2]
	mov.w r0, #0x12c
	strh r0, [r4, #4]
	movs r0, #0x1c
	strh r0, [r4, #6]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #8]
	ldr r0, [r4, #8]
	cmp r0, #0
	beq.n .L08010d62
	ldr.w ip, [r4, #8]
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #6]
	muls r0, r1, r0
	cbz r0, .L08010d12
	subs r1, r0, #1
	and.w lr, r0, #3
	movs r3, #0
	cmp r1, #3
	mov.w r2, #0
	blo.n .L08010cf0
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1
	sub.w r1, ip, #8
	movs r2, #0
.L08010ce4:
	adds r2, #4
	str r3, [r1, #8]!
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L08010ce4
.L08010cf0:
	cmp.w lr, #0
	beq.n .L08010d12
	movs r0, #0
	cmp.w lr, #1
	strh.w r0, [ip, r2, lsl #1]
	beq.n .L08010d12
	add.w r1, ip, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0
	strhne r0, [r1, #4]
.L08010d12:
	bl draw_seven_icon_row
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08010d62
	ldr r1, [r4, #8]
	cbz r1, .L08010d62
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L08010d64
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08010d62
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08010d62:
	pop {r4, pc}
.L08010d64:
	ldr r1, [r0, #0]
	movs r0, #0
	pop.w {r4, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08010d70 - redraws the page-2 waveform area; no parameters, no return value.
@ Returns at once when byte [0x20000f08] == 0xff or [0x20001060] != 2. Sets the
@ region record [0x20008350..56] = (9, 0x14, 0x12d, 0xc9) (x, y, w, h halfwords),
@ allocates 0x1d8aa bytes (= w*h*2) with alloc_units_of_32_bytes (0803acfc) into
@ [0x20008358]; when that fails sets byte [0x2000013c] = 1. Otherwise zero-fills
@ w*h halfwords, calls draw_waveform_display (080165a8), then fn_08042ee0 and
@ semaphore_take_timeout (080423a8)([0x20002d84], 0xffffffff); when that returns
@ 1 and [0x20008358] != 0 the buffer is released: callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf zero_bytes
@ (080082bc) zeroes its entry range in the halfword table [0x2000107c]; then
@ sets byte [0x2000013c] = 0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08010d70,"ax",%progbits
	.p2align 2
	.global fn_08010d70
	.thumb_func
	.type fn_08010d70, %function
fn_08010d70:
	push {r4, r5, r6, lr}
	movw r6, #0xf8
	movt r6, #0x2000
	ldrb.w r0, [r6, #0xe10]
	cmp r0, #0xff
	beq.n .L08010e64
	ldrb.w r0, [r6, #0xf68]
	cmp r0, #2
	it ne
	popne {r4, r5, r6, pc}
	movw r5, #0x8350
	movt r5, #0x2000
	movs r0, #9
	strh r0, [r5, #0]
	movs r0, #0x14
	strh r0, [r5, #2]
	movw r0, #0x12d
	strh r0, [r5, #4]
	movs r0, #0xc9
	strh r0, [r5, #6]
	ldrh r0, [r5, #4]
	ldrh r1, [r5, #6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r5, #8]
	ldr r0, [r5, #8]
	cmp r0, #0
	beq.n .L08010e5e
	ldr.w ip, [r5, #8]
	ldrh r0, [r5, #4]
	ldrh r1, [r5, #6]
	muls r0, r1, r0
	cbz r0, .L08010e0e
	subs r2, r0, #1
	and.w r1, r0, #3
	movs r3, #0
	cmp r2, #3
	mov.w r2, #0
	blo.n .L08010df4
	movw r2, #0xfffc
	movt r2, #0x7fff
	ands r0, r2
	sub.w r4, ip, #8
	movs r2, #0
	nop
.L08010de8:
	adds r2, #4
	str r3, [r4, #8]!
	cmp r0, r2
	str r3, [r4, #4]
	bne.n .L08010de8
.L08010df4:
	cbz r1, .L08010e0e
	movs r0, #0
	cmp r1, #1
	strh.w r0, [ip, r2, lsl #1]
	beq.n .L08010e0e
	add.w r2, ip, r2, lsl #1
	cmp r1, #2
	strh r0, [r2, #2]
	itt ne
	movne r0, #0
	strhne r0, [r2, #4]
.L08010e0e:
	bl draw_waveform_display
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #-1
	bl semaphore_take_timeout
	cmp r0, #1
	bne.n .L08010e5a
	ldr r1, [r5, #8]
	cbz r1, .L08010e5a
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L08010e66
	ldr r2, [r0, #8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08010e5a
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L08010e5a
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08010e5a:
	movs r5, #0
	b.n .L08010e60
.L08010e5e:
	movs r5, #1
.L08010e60:
	strb.w r5, [r6, #0x44]
.L08010e64:
	pop {r4, r5, r6, pc}
.L08010e66:
	ldr r1, [r0, #0]
	movs r0, #0
	movs r5, #0
	blx r1
	b.n .L08010e60
