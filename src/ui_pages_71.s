@ ui_pages_71.s - UI page routines: region-record set-up, buffer allocation, draw, release hand-off.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08011dfc - No parameters, no return value.
@ Sets the region record [0x20008350..56] = (0x3d, 0x32, 0xc6, 0x76) (x, y, w, h
@ halfwords) and allocates 0xb688 bytes (= w*h*2) with 0803acfc into [0x20008358].
@ When that succeeds it calls 0801f19c (no zero fill), then 08042ee0 and
@ 080423a8([0x20002d84], 0xffffffff). When that returns 1 and [0x20008358] != 0
@ the buffer is released: callback (*[0x20001070])(0) if [0x20001080] == 0, else
@ when (buf - [0x20001078]) >> 10 < 0xaf, 080082bc zeroes its entry range in the
@ halfword table [0x2000107c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08011dfc,"ax",%progbits
	.p2align 2
	.global fn_08011dfc
	.thumb_func
	.type fn_08011dfc, %function
fn_08011dfc:
	push {r4, lr}
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0x3d
	strh r0, [r4, #0x0]
	movs r0, #0x32
	strh r0, [r4, #0x2]
	movs r0, #0xc6
	strh r0, [r4, #0x4]
	movs r0, #0x76
	strh r0, [r4, #0x6]
	ldrh r0, [r4, #0x4]
	ldrh r1, [r4, #0x6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #0x8]
	ldr r0, [r4, #0x8]
	cbz r0, .L08011e78
	bl draw_image_and_three_texts
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #0x1
	bne.n .L08011e78
	ldr r1, [r4, #0x8]
	cbz r1, .L08011e78
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L08011e7a
	ldr r2, [r0, #0x8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08011e78
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0x0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08011e78:
	pop {r4, pc}
.L08011e7a:
	ldr r1, [r0, #0x0]
	movs r0, #0x0
	pop.w {r4, lr}
	bx r1

@ ----------------------------------------------------------------------------
@ fn_08011e84 - No parameters, no return value.
@ Sets the region record [0x20008350..56] = (0x3d, 0x50, 0xc6, 0x53) (x, y, w, h
@ halfwords), allocates 0x8064 bytes (= w*h*2) with 0803acfc into [0x20008358].
@ When that succeeds it zero-fills w*h halfwords, draws with
@ 0801ffcc(0x3d, 0x50, 0xc6, 0x53, 0x0804fd00, 0x55f) (4-bit bitmap draw) and the
@ text "Deleting..." with
@ 0800f154(0x3f, 0x6d, 0xc2, 0x14, text, 0x20001144, 0x55f, 1). Then the hand-off:
@ 08042ee0 and 080423a8([0x20002d84], 0xffffffff); when that returns 1 and
@ [0x20008358] != 0 the buffer is released (callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf 080082bc zeroes
@ its entry range in the halfword table [0x2000107c]).
@ Then: if [0x20001060] == 0x0b it loops over the 8 bytes 0x20000f0a..0x20000f11
@ and for each set bit k (0..5) of a byte j formats "2:/Screenshot file/%d.bmp" and
@ "2:/Screenshot simple file/%d.bin" with the byte at 0x20000f1d + 6*j + k into
@ 0x20008360 (080073b4) and calls 0803512c after each of the two names; otherwise
@ it does the same two names and calls for the single byte at
@ 0x20000f1d + [0x20000f15].
@ Finally byte [0x20000f13] = 0803b878("2:/Screenshot simple file"),
@ [0x20000f12] = 0, halfword [0x20000f14] = 0, [0x20001060] = 5.
@ The allocation-failure case skips only the drawing part. Purpose of 0803512c and
@ 0803b878 not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08011e84,"ax",%progbits
	.p2align 2
	.global fn_08011e84
	.thumb_func
	.type fn_08011e84, %function
fn_08011e84:
	push.w {r4, r5, r6, r7, r8, r9, r10, lr}
	sub sp, #0x10
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0x3d
	strh r0, [r4, #0x0]
	movs r0, #0x50
	strh r0, [r4, #0x2]
	movs r0, #0xc6
	strh r0, [r4, #0x4]
	movs r0, #0x53
	strh r0, [r4, #0x6]
	ldrh r0, [r4, #0x4]
	ldrh r1, [r4, #0x6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #0x8]
	ldr r0, [r4, #0x8]
	movw r8, #0xf8
	cmp r0, #0x0
	movt r8, #0x2000
	beq.n .L08011fae
	ldr r0, [r4, #0x8]
	ldrh r1, [r4, #0x4]
	ldrh r2, [r4, #0x6]
	mul.w r7, r2, r1
	cbz r7, .L08011f12
	subs r2, r7, #1
	and r1, r7, #3
	movs r3, #0x0
	cmp r2, #3
	mov.w r2, #0x0
	bcc.n .L08011ef8
	movw r2, #0xfffc
	movt r2, #0x7fff
	ands r7, r2
	sub.w r6, r0, #8
	movs r2, #0x0
	nop
.L08011eec:
	adds r2, #4
	str.w r3, [r6, #8]!
	cmp r7, r2
	str r3, [r6, #4]
	bne.n .L08011eec
.L08011ef8:
	cbz r1, .L08011f12
	movs r3, #0x0
	cmp r1, #1
	strh.w r3, [r0, r2, lsl #1]
	beq.n .L08011f12
	add.w r0, r0, r2, lsl #1
	cmp r1, #2
	strh r3, [r0, #2]
	itt ne
	movne r1, #0x0
	strhne r1, [r0, #4]
.L08011f12:
	movw r0, #:lower16:d_0804fd00
	movt r0, #:upper16:d_0804fd00
	movw r5, #0x55f
	str r0, [sp]
	movs r0, #0x3d
	movs r1, #0x50
	movs r2, #0xc6
	movs r3, #0x53
	str r5, [sp, #0x4]
	bl draw_4bpp_bitmap
	movw r0, #:lower16:t_080bb682	@ "Deleting..."
	movt r0, #:upper16:t_080bb682
	movw r1, #0x1144
	movt r1, #0x2000
	movs r7, #0x1
	stm.w sp, {r0, r1, r5}
	movs r0, #0x3f
	movs r1, #0x6d
	movs r2, #0xc2
	movs r3, #0x14
	str r7, [sp, #0xc]
	bl draw_wrapped_text_in_box
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #0x1
	bne.n .L08011fae
	ldr r1, [r4, #0x8]
	cbz r1, .L08011fae
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L08011fa8
	ldr r2, [r0, #0x8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08011fae
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L08011fae
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L08011fae
.L08011fa8:
	ldr r1, [r0, #0x0]
	movs r0, #0x0
	blx r1
.L08011fae:
	ldrb.w r0, [r8, #0xf68]
	cmp r0, #0xb
	bne.w .L080120f8
	movw r4, #0x8360
	movw r9, #:lower16:t_080bcad2
	movw r10, #:lower16:t_080bc859
	addw r7, r8, #0xe2a
	mvn r5, #0x7
	movt r4, #0x2000
	movt r9, #:upper16:t_080bcad2
	movt r10, #:upper16:t_080bc859
	b.n .L08011fe6
	.byte 0x00, 0xbf	@ padding
.L08011fdc:
	adds r5, #1
	add.w r7, r7, #6
	bcs.w .L08012134
.L08011fe6:
	add.w r1, r8, r5
	ldrb.w r0, [r1, #0xe1a]
	cmp r0, #0x0
	beq.n .L08011fdc
	lsls r2, r0, #0x1f
	addw r6, r1, #0xe2a
	bne.n .L08012010
.L08011ffa:
	lsls r1, r0, #0x1e
	bmi.n .L08012038
.L08011ffe:
	lsls r1, r0, #0x1d
	bmi.n .L08012060
.L08012002:
	lsls r1, r0, #0x1c
	bmi.n .L08012088
.L08012006:
	lsls r1, r0, #0x1b
	bmi.n .L080120b0
.L0801200a:
	lsls r0, r0, #0x1a
	bpl.n .L08011fdc
	b.n .L080120da
.L08012010:
	ldrb r2, [r7, #-0x5]
	mov r0, r4
	mov r1, r9
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r2, [r7, #-0x5]
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r0, [r6, #-0x10]
	lsls r1, r0, #0x1e
	bpl.n .L08011ffe
.L08012038:
	ldrb r2, [r7, #-0x4]
	mov r0, r4
	mov r1, r9
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r2, [r7, #-0x4]
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r0, [r6, #-0x10]
	lsls r1, r0, #0x1d
	bpl.n .L08012002
.L08012060:
	ldrb r2, [r7, #-0x3]
	mov r0, r4
	mov r1, r9
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r2, [r7, #-0x3]
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r0, [r6, #-0x10]
	lsls r1, r0, #0x1c
	bpl.n .L08012006
.L08012088:
	ldrb r2, [r7, #-0x2]
	mov r0, r4
	mov r1, r9
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r2, [r7, #-0x2]
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r0, [r6, #-0x10]
	lsls r1, r0, #0x1b
	bpl.n .L0801200a
.L080120b0:
	ldrb r2, [r7, #-0x1]
	mov r0, r4
	mov r1, r9
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r2, [r7, #-0x1]
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r0, [r6, #-0x10]
	lsls r0, r0, #0x1a
	bpl.w .L08011fdc
.L080120da:
	ldrb r2, [r7]
	mov r0, r4
	mov r1, r9
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb r2, [r7]
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	bl path_delete
	b.n .L08011fdc
.L080120f8:
	ldrb.w r0, [r8, #0xe1d]
	addw r5, r8, #0xe25
	movw r4, #0x8360
	ldrb r2, [r5, r0]
	movt r4, #0x2000
	movw r1, #:lower16:t_080bcad2
	movt r1, #:upper16:t_080bcad2
	mov r0, r4
	bl format_to_buffer_080073b4
	bl path_delete
	ldrb.w r0, [r8, #0xe1d]
	movw r1, #:lower16:t_080bc859
	ldrb r2, [r5, r0]
	movt r1, #:upper16:t_080bc859
	mov r0, r4
	bl format_to_buffer_080073b4
	bl path_delete
.L08012134:
	movw r0, #:lower16:t_080bc18b
	movt r0, #:upper16:t_080bc18b
	bl scan_capture_files
	strb.w r0, [r8, #0xe1b]
	movs r0, #0x0
	strb.w r0, [r8, #0xe1a]
	strh.w r0, [r8, #0xe1c]
	movs r0, #0x5
	strb.w r0, [r8, #0xf68]
	add sp, #0x10
	pop.w {r4, r5, r6, r7, r8, r9, r10, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08012244 - Returns at once unless [0x20001060] == 2.
@ Sets the region record [0x20008350..56] = (0, 0x14, 9, 0xc9) (x, y, w, h
@ halfwords) and allocates 0xe22 bytes (= w*h*2) with 0803acfc into
@ [0x20008358]. When that succeeds it zero-fills w*h halfwords and calls
@ 08028b40 when [0x2000012c] == 0. Then 08042ee0 and
@ 080423a8([0x20002d84], 0xffffffff); when that returns 1 and [0x20008358] != 0
@ the buffer is released (callback (*[0x20001070])(0) if [0x20001080] == 0, else
@ when (buf - [0x20001078]) >> 10 < 0xaf 080082bc zeroes its entry range in the
@ halfword table [0x2000107c]).
@ ----------------------------------------------------------------------------
	.section .text.fn_08012244,"ax",%progbits
	.p2align 2
	.global fn_08012244
	.thumb_func
	.type fn_08012244, %function
fn_08012244:
	push {r4, r5, r7, lr}
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #0x2
	bne.n .L08012336
	movw r4, #0x8350
	movt r4, #0x2000
	movs r0, #0x0
	strh r0, [r4, #0x0]
	movs r0, #0x14
	strh r0, [r4, #0x2]
	movs r0, #0x9
	strh r0, [r4, #0x4]
	movs r0, #0xc9
	strh r0, [r4, #0x6]
	ldrh r0, [r4, #0x4]
	ldrh r1, [r4, #0x6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #0x8]
	ldr r0, [r4, #0x8]
	cmp r0, #0x0
	beq.n .L08012336
	ldr.w r12, [r4, #0x8]
	ldrh r0, [r4, #0x4]
	ldrh r1, [r4, #0x6]
	muls r0, r1, r0
	cbz r0, .L080122de
	subs r1, r0, #1
	and lr, r0, #3
	movs r3, #0x0
	cmp r1, #3
	mov.w r2, #0x0
	bcc.n .L080122bc
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1
	sub.w r1, r12, #8
	movs r2, #0x0
	nop
.L080122b0:
	adds r2, #4
	str.w r3, [r1, #8]!
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L080122b0
.L080122bc:
	cmp.w lr, #0x0
	beq.n .L080122de
	movs r0, #0x0
	cmp.w lr, #1
	strh.w r0, [r12, r2, lsl #1]
	beq.n .L080122de
	add.w r1, r12, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0x0
	strhne r0, [r1, #4]
.L080122de:
	ldrb.w r0, [r5, #0x34]
	cmp r0, #0x0
	it eq
	bleq draw_channel_offset_markers_08028b40
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #0x1
	bne.n .L08012336
	ldr r1, [r4, #0x8]
	cbz r1, .L08012336
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L08012338
	ldr r2, [r0, #0x8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08012336
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0x0
	it eq
	popeq {r4, r5, r7, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08012336:
	pop {r4, r5, r7, pc}
.L08012338:
	ldr r1, [r0, #0x0]
	movs r0, #0x0
	pop.w {r4, r5, r7, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08012344 - Returns at once unless [0x20001060] == 2.
@ Sets the region record [0x20008350..56] = (0x136, 0x14, 10, 0xc9) (x, y, w, h
@ halfwords) and allocates 0xfb4 bytes (= w*h*2) with 0803acfc into
@ [0x20008358]. When that succeeds it zero-fills w*h halfwords; when
@ [0x2000012c] == 0: y = 0x78 - (short)halfword[0x20000114], replaced by 0x14
@ when (ushort)(halfword[0x20000114] + 100) > 200, then fill_triangle
@ 08020af8(0x136, y, 0x13d, y+5, 0x13d, y-5, 0x7e2). Then 08042ee0 and
@ 080423a8([0x20002d84], 0xffffffff); when that returns 1 and [0x20008358] != 0
@ the buffer is released (callback (*[0x20001070])(0) if [0x20001080] == 0, else
@ when (buf - [0x20001078]) >> 10 < 0xaf 080082bc zeroes its entry range in the
@ halfword table [0x2000107c]).
@ ----------------------------------------------------------------------------
	.section .text.fn_08012344,"ax",%progbits
	.p2align 2
	.global fn_08012344
	.thumb_func
	.type fn_08012344, %function
fn_08012344:
	push {r4, r5, r7, lr}
	sub sp, #0x10
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #0x2
	bne.w .L08012466
	movw r4, #0x8350
	movt r4, #0x2000
	mov.w r0, #0x136
	strh r0, [r4, #0x0]
	movs r0, #0x14
	strh r0, [r4, #0x2]
	movs r0, #0xa
	strh r0, [r4, #0x4]
	movs r0, #0xc9
	strh r0, [r4, #0x6]
	ldrh r0, [r4, #0x4]
	ldrh r1, [r4, #0x6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #0x8]
	ldr r0, [r4, #0x8]
	cmp r0, #0x0
	beq.n .L08012466
	ldr.w r12, [r4, #0x8]
	ldrh r0, [r4, #0x4]
	ldrh r1, [r4, #0x6]
	muls r0, r1, r0
	cbz r0, .L080123e2
	subs r1, r0, #1
	and lr, r0, #3
	movs r3, #0x0
	cmp r1, #3
	mov.w r2, #0x0
	bcc.n .L080123c0
	movw r1, #0xfffc
	movt r1, #0x7fff
	ands r0, r1
	sub.w r1, r12, #8
	movs r2, #0x0
.L080123b4:
	adds r2, #4
	str.w r3, [r1, #8]!
	cmp r0, r2
	str r3, [r1, #4]
	bne.n .L080123b4
.L080123c0:
	cmp.w lr, #0x0
	beq.n .L080123e2
	movs r0, #0x0
	cmp.w lr, #1
	strh.w r0, [r12, r2, lsl #1]
	beq.n .L080123e2
	add.w r1, r12, r2, lsl #1
	cmp.w lr, #2
	strh r0, [r1, #2]
	itt ne
	movne r0, #0x0
	strhne r0, [r1, #4]
.L080123e2:
	ldrb.w r0, [r5, #0x34]
	cbnz r0, .L0801241e
	ldrh r0, [r5, #0x1c]
	movw r3, #0x13d
	add.w r1, r0, #0x64
	uxth r1, r1
	rsb.w r0, r0, #0x78
	cmp r1, #0xc8
	it hi
	movhi r0, #0x14
	subs r1, r0, #5
	adds r2, r0, #5
	sxth r1, r1
	movw r5, #0x7e2
	strd r3, r1, [sp]
	sxth r1, r0
	sxth r3, r2
	mov.w r0, #0x136
	movw r2, #0x13d
	str r5, [sp, #0x8]
	bl fill_triangle
.L0801241e:
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #0x1
	bne.n .L08012466
	ldr r1, [r4, #0x8]
	cbz r1, .L08012466
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L0801246a
	ldr r2, [r0, #0x8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08012466
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L08012466
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08012466:
	add sp, #0x10
	pop {r4, r5, r7, pc}
.L0801246a:
	ldr r1, [r0, #0x0]
	movs r0, #0x0
	add sp, #0x10
	pop.w {r4, r5, r7, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08012478 - No parameters, no return value.
@ Sets the region record [0x20008350..56] = (0x122, 7, 0xe, 6) (x, y, w, h
@ halfwords) and allocates 0xa8 bytes (= w*h*2) with 0803acfc into [0x20008358].
@ When that succeeds: writes 0x422 at columns x and x+1 for x = 0x122, 0x124, ..
@ 0x12e on each of the rows 7..12 (rows 7, 9, 11 first, then 8, 10, 12), i.e.
@ every pixel of the 14x6 region, with bounds tests against the region record.
@ When [0x2000105f] > 10: x_end = (int)([0x2000105f] / 100.0 * 14.0 + 290.0 - 1.0)
@ (VFP) and, when x_end > 0x121, fills rows 7..12 from x = 0x122 to x_end with
@ 0xffff, or with 0xfb80 when [0x2000105f] < 0x3d.
@ Then 08042ee0 and 080423a8([0x20002d84], 0xffffffff); when that returns 1 and
@ [0x20008358] != 0 the buffer is released (callback (*[0x20001070])(0) if
@ [0x20001080] == 0, else when (buf - [0x20001078]) >> 10 < 0xaf 080082bc zeroes
@ its entry range in the halfword table [0x2000107c]).
@ Purpose not determined from the code (pixel output: the 14x6 region is filled
@ with 0x422, then columns 0x122..x_end are overwritten on rows 7..12; meaning of
@ [0x2000105f] not determined).
@ Literals: 0x42c80000 (100.0) and 0x43910000 (290.0).
@ ----------------------------------------------------------------------------
	.section .text.fn_08012478,"ax",%progbits
	.p2align 2
	.global fn_08012478
	.thumb_func
	.type fn_08012478, %function
fn_08012478:
	push {r4, r5, r6, r7, lr}
	sub sp, #4
	movw r4, #0x8350
	movt r4, #0x2000
	mov.w r0, #0x122
	strh r0, [r4, #0x0]
	movs r0, #0x7
	strh r0, [r4, #0x2]
	movs r0, #0xe
	strh r0, [r4, #0x4]
	movs r0, #0x6
	strh r0, [r4, #0x6]
	ldrh r0, [r4, #0x4]
	ldrh r1, [r4, #0x6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #0x8]
	ldr r0, [r4, #0x8]
	cmp r0, #0x0
	beq.w .L0801266c
	movs r0, #0x7
	mov.w lr, #0x8
	movw r12, #0x422
	b.n .L080124c4
.L080124b8:
	adds r0, #2
	cmp r0, #0xd
	add.w lr, lr, #2
	beq.w .L080125ca
.L080124c4:
	mov.w r3, #0x122
	b.n .L080124d4
	.byte 0x00, 0xbf	@ padding
.L080124cc:
	adds r3, #2
	cmp.w r3, #0x130
	beq.n .L08012544
.L080124d4:
	ldrh r1, [r4, #0x0]
	cmp r3, r1
	bcc.n .L08012508
	ldrh r1, [r4, #0x0]
	ldrh r2, [r4, #0x4]
	add r1, r2
	cmp r1, r3
	bls.n .L08012508
	ldrh r1, [r4, #0x2]
	cmp r0, r1
	bcc.n .L08012508
	ldrh r1, [r4, #0x2]
	ldrh r2, [r4, #0x6]
	add r1, r2
	cmp r1, r0
	bls.n .L08012508
	ldr r1, [r4, #0x8]
	ldrh r2, [r4, #0x0]
	ldrh r5, [r4, #0x2]
	ldrh r6, [r4, #0x4]
	subs r5, r0, r5
	muls r5, r6, r5
	subs r2, r5, r2
	add r2, r3
	strh.w r12, [r1, r2, lsl #1]
.L08012508:
	ldrh r1, [r4, #0x0]
	adds r2, r3, #1
	cmp r2, r1
	bcc.n .L080124cc
	ldrh r1, [r4, #0x0]
	ldrh r5, [r4, #0x4]
	add r1, r5
	cmp r1, r2
	bls.n .L080124cc
	ldrh r1, [r4, #0x2]
	cmp r0, r1
	bcc.n .L080124cc
	ldrh r1, [r4, #0x2]
	ldrh r2, [r4, #0x6]
	add r1, r2
	cmp r1, r0
	bls.n .L080124cc
	ldr r1, [r4, #0x8]
	ldrh r2, [r4, #0x0]
	ldrh r5, [r4, #0x2]
	ldrh r6, [r4, #0x4]
	subs r5, r0, r5
	muls r5, r6, r5
	subs r2, r5, r2
	add r2, r3
	add.w r1, r1, r2, lsl #1
	strh.w r12, [r1, #2]
	b.n .L080124cc
.L08012544:
	adds r3, r0, #1
	mov.w r2, #0x122
	b.n .L08012554
.L0801254c:
	adds r2, #2
	cmp.w r2, #0x130
	beq.n .L080124b8
.L08012554:
	ldrh r1, [r4, #0x0]
	cmp r2, r1
	bcc.n .L0801258c
	ldrh r1, [r4, #0x0]
	ldrh r5, [r4, #0x4]
	add r1, r5
	cmp r1, r2
	bls.n .L0801258c
	ldrh r1, [r4, #0x2]
	cmp r3, r1
	bcc.n .L0801258c
	ldrh r1, [r4, #0x2]
	ldrh r5, [r4, #0x6]
	add r1, r5
	cmp r1, r3
	bls.n .L0801258c
	ldr r1, [r4, #0x8]
	ldrh r5, [r4, #0x0]
	ldrh r6, [r4, #0x2]
	ldrh r7, [r4, #0x4]
	sub.w r6, lr, r6
	muls r6, r7, r6
	subs r5, r6, r5
	add r5, r2
	strh.w r12, [r1, r5, lsl #1]
	nop
.L0801258c:
	ldrh r5, [r4, #0x0]
	adds r1, r2, #1
	cmp r1, r5
	bcc.n .L0801254c
	ldrh r5, [r4, #0x0]
	ldrh r6, [r4, #0x4]
	add r5, r6
	cmp r5, r1
	bls.n .L0801254c
	ldrh r1, [r4, #0x2]
	cmp r3, r1
	bcc.n .L0801254c
	ldrh r1, [r4, #0x2]
	ldrh r5, [r4, #0x6]
	add r1, r5
	cmp r1, r3
	bls.n .L0801254c
	ldr r1, [r4, #0x8]
	ldrh r5, [r4, #0x0]
	ldrh r6, [r4, #0x2]
	ldrh r7, [r4, #0x4]
	sub.w r6, lr, r6
	muls r6, r7, r6
	subs r5, r6, r5
	add r5, r2
	add.w r1, r1, r5, lsl #1
	strh.w r12, [r1, #2]
	b.n .L0801254c
.L080125ca:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r1, [r0, #0xf67]
	cmp r1, #0xb
	bcc.n .L08012620
	vmov s0, r1
	vldr s2, .L08012770
	vcvt.f32.u32 s0, s0
	vdiv.f32 s0, s0, s2
	vmov.f32 s2, #14.0
	vldr s4, .L08012774
	mov.w r12, #0xffffffff
	cmp r1, #0x3d
	itt cc
	movwcc r12, #0xfb80
	movtcc r12, #0xffff
	vmul.f32 s0, s0, s2
	vadd.f32 s0, s0, s4
	vmov.f32 s2, #-1.0
	vadd.f32 s0, s0, s2
	vcvt.s32.f32 s0, s0
	vmov r0, s0
	cmp.w r0, #0x122
	bge.n .L08012670
.L08012620:
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #0x1
	bne.n .L0801266c
	ldr r1, [r4, #0x8]
	cbz r1, .L0801266c
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cmp r2, #0x0
	beq.w .L08012764
	ldr r2, [r0, #0x8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L0801266c
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cbz r1, .L0801266c
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L0801266c:
	add sp, #4
	pop {r4, r5, r6, r7, pc}
.L08012670:
	mov.w lr, #0x7
	b.n .L08012682
	.byte 0x00, 0xbf	@ padding
.L08012678:
	add.w lr, lr, #3
	cmp.w lr, #0xd
	beq.n .L08012620
.L08012682:
	mov.w r3, #0x122
	b.n .L08012690
.L08012688:
	adds r1, r3, #1
	sxth r3, r1
	cmp r3, r0
	bgt.n .L080126cc
.L08012690:
	ldrh r2, [r4, #0x0]
	sxth r1, r3
	cmp r1, r2
	blt.n .L08012688
	ldrh r2, [r4, #0x0]
	ldrh r5, [r4, #0x4]
	add r2, r5
	cmp r2, r1
	ble.n .L08012688
	ldrh r2, [r4, #0x2]
	cmp lr, r2
	bcc.n .L08012688
	ldrh r2, [r4, #0x2]
	ldrh r5, [r4, #0x6]
	add r2, r5
	cmp r2, lr
	bls.n .L08012688
	ldr r2, [r4, #0x8]
	ldrh r5, [r4, #0x0]
	subs r1, r1, r5
	ldrh r5, [r4, #0x2]
	ldrh r6, [r4, #0x4]
	sub.w r5, lr, r5
	mla r1, r5, r6, r1
	strh.w r12, [r2, r1, lsl #1]
	b.n .L08012688
	.byte 0x00, 0xbf	@ padding
.L080126cc:
	add.w r3, lr, #1
	mov.w r1, #0x122
	b.n .L080126e0
	.byte 0x00, 0xbf	@ padding
.L080126d8:
	adds r1, #1
	sxth r1, r1
	cmp r1, r0
	bgt.n .L08012718
.L080126e0:
	ldrh r5, [r4, #0x0]
	sxth r2, r1
	cmp r2, r5
	blt.n .L080126d8
	ldrh r5, [r4, #0x0]
	ldrh r6, [r4, #0x4]
	add r5, r6
	cmp r5, r2
	ble.n .L080126d8
	ldrh r5, [r4, #0x2]
	cmp r3, r5
	bcc.n .L080126d8
	ldrh r5, [r4, #0x2]
	ldrh r6, [r4, #0x6]
	add r5, r6
	cmp r5, r3
	bls.n .L080126d8
	ldr r5, [r4, #0x8]
	ldrh r6, [r4, #0x0]
	subs r2, r2, r6
	ldrh r6, [r4, #0x2]
	ldrh r7, [r4, #0x4]
	subs r6, r3, r6
	mla r2, r6, r7, r2
	strh.w r12, [r5, r2, lsl #1]
	b.n .L080126d8
.L08012718:
	add.w r3, lr, #2
	mov.w r1, #0x122
	b.n .L0801272c
	.byte 0x00, 0xbf	@ padding
.L08012724:
	adds r1, #1
	sxth r1, r1
	cmp r1, r0
	bgt.n .L08012678
.L0801272c:
	ldrh r5, [r4, #0x0]
	sxth r2, r1
	cmp r2, r5
	blt.n .L08012724
	ldrh r5, [r4, #0x0]
	ldrh r6, [r4, #0x4]
	add r5, r6
	cmp r5, r2
	ble.n .L08012724
	ldrh r5, [r4, #0x2]
	cmp r3, r5
	bcc.n .L08012724
	ldrh r5, [r4, #0x2]
	ldrh r6, [r4, #0x6]
	add r5, r6
	cmp r5, r3
	bls.n .L08012724
	ldr r5, [r4, #0x8]
	ldrh r6, [r4, #0x0]
	subs r2, r2, r6
	ldrh r6, [r4, #0x2]
	ldrh r7, [r4, #0x4]
	subs r6, r3, r6
	mla r2, r6, r7, r2
	strh.w r12, [r5, r2, lsl #1]
	b.n .L08012724
.L08012764:
	ldr r1, [r0, #0x0]
	movs r0, #0x0
	add sp, #4
	pop.w {r4, r5, r6, r7, lr}
	bx r1
.L08012770:
	.word 0x42c80000	@ 100.0
.L08012774:
	.word 0x43910000	@ 290.0

@ ----------------------------------------------------------------------------
@ fn_08012778 - No parameters, no return value; does nothing unless
@ ([0x20001060] & 0xfe) == 2.
@ Sets the region record [0x20008350..56] = (0, 0, 0x34, 0x14) (x, y, w, h
@ halfwords) and allocates 0x820 bytes (= w*h*2) with 0803acfc into
@ [0x20008358]. When that succeeds it formats "3:/System file/%d.jpg" with
@ (short)[0x20000f50] * -13 + [0x20000f51] + 0x17 into 0x20008360 (080073b4) and
@ draws it with 08039f6c(name, 0, 0). Then 08042ee0 and
@ 080423a8([0x20002d84], 0xffffffff); when that returns 1 and [0x20008358] != 0
@ the buffer is released (callback (*[0x20001070])(0) if [0x20001080] == 0, else
@ when (buf - [0x20001078]) >> 10 < 0xaf 080082bc zeroes its entry range in the
@ halfword table [0x2000107c]).
@ ----------------------------------------------------------------------------
	.section .text.fn_08012778,"ax",%progbits
	.p2align 2
	.global fn_08012778
	.thumb_func
	.type fn_08012778, %function
fn_08012778:
	push {r4, r5, r7, lr}
	movw r4, #0xf8
	movt r4, #0x2000
	ldrb.w r0, [r4, #0xf68]
	and r0, r0, #0xfe
	cmp r0, #0x2
	bne.n .L08012838
	movw r5, #0x8350
	movt r5, #0x2000
	movs r0, #0x0
	strh r0, [r5, #0x0]
	strh r0, [r5, #0x2]
	movs r0, #0x34
	strh r0, [r5, #0x4]
	movs r0, #0x14
	strh r0, [r5, #0x6]
	ldrh r0, [r5, #0x4]
	ldrh r1, [r5, #0x6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r5, #0x8]
	ldr r0, [r5, #0x8]
	cmp r0, #0x0
	beq.n .L08012838
	ldrb.w r0, [r4, #0xe58]
	ldrb.w r1, [r4, #0xe59]
	mvn r2, #0xc
	movw r4, #0x8360
	smlabb r0, r0, r2, r1
	movt r4, #0x2000
	movw r1, #:lower16:t_080bc681
	add.w r2, r0, #0x17
	movt r1, #:upper16:t_080bc681
	mov r0, r4
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x0
	movs r2, #0x0
	bl decode_image_file_with_offset
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #0x1
	bne.n .L08012838
	ldr r1, [r5, #0x8]
	cbz r1, .L08012838
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L0801283a
	ldr r2, [r0, #0x8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L08012838
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0x0
	it eq
	popeq {r4, r5, r7, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08012838:
	pop {r4, r5, r7, pc}
.L0801283a:
	ldr r1, [r0, #0x0]
	movs r0, #0x0
	pop.w {r4, r5, r7, lr}
	bx r1

@ ----------------------------------------------------------------------------
@ fn_08012844 - No parameters, no return value.
@ Sets the region record [0x20008350..56] = (0x10c, 0, 0x34, 0x14) (x, y, w, h
@ halfwords) and allocates 0x820 bytes (= w*h*2) with 0803acfc into
@ [0x20008358]. When that succeeds it draws "3:/System file/6.jpg" when
@ [0x2000105f] < 0xb and bit 7 of the word at 0x40011008 is set, otherwise
@ "3:/System file/5.jpg", at (0x10c, 0) with 08039f6c. Then 08042ee0 and
@ 080423a8([0x20002d84], 0xffffffff); when that returns 1 and [0x20008358] != 0
@ the buffer is released (callback (*[0x20001070])(0) if [0x20001080] == 0, else
@ when (buf - [0x20001078]) >> 10 < 0xaf 080082bc zeroes its entry range in the
@ halfword table [0x2000107c]).
@ ----------------------------------------------------------------------------
	.section .text.fn_08012844,"ax",%progbits
	.p2align 2
	.global fn_08012844
	.thumb_func
	.type fn_08012844, %function
fn_08012844:
	push {r4, lr}
	movw r4, #0x8350
	movt r4, #0x2000
	mov.w r0, #0x10c
	strh r0, [r4, #0x0]
	movs r0, #0x0
	strh r0, [r4, #0x2]
	movs r0, #0x34
	strh r0, [r4, #0x4]
	movs r0, #0x14
	strh r0, [r4, #0x6]
	ldrh r0, [r4, #0x4]
	ldrh r1, [r4, #0x6]
	muls r0, r1, r0
	lsls r0, r0, #1
	bl alloc_units_of_32_bytes
	str r0, [r4, #0x8]
	ldr r0, [r4, #0x8]
	cmp r0, #0x0
	beq.n .L080128fa
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xf67]
	cmp r0, #0xa
	movw r0, #:lower16:t_080bc51e
	movt r0, #:upper16:t_080bc51e
	bhi.n .L080128a4
	movw r1, #0x1008
	movt r1, #0x4001
	ldr r1, [r1, #0x0]
	lsls r1, r1, #0x18
	movw r1, #:lower16:t_080bc576
	movt r1, #:upper16:t_080bc576
	it mi
	movmi r0, r1
.L080128a4:
	mov.w r1, #0x10c
	movs r2, #0x0
	bl decode_image_file_with_offset
	bl fn_08042ee0
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0, #0x0]
	mov.w r1, #0xffffffff
	bl semaphore_take_timeout
	cmp r0, #0x1
	bne.n .L080128fa
	ldr r1, [r4, #0x8]
	cbz r1, .L080128fa
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r2, [r0, #0x10]
	cbz r2, .L080128fc
	ldr r2, [r0, #0x8]
	subs r1, r1, r2
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.n .L080128fa
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0x0
	it eq
	popeq {r4, pc}
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L080128fa:
	pop {r4, pc}
.L080128fc:
	ldr r1, [r0, #0x0]
	movs r0, #0x0
	pop.w {r4, lr}
	bx r1
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ jump_indirect_through_table - One parameter r0 = index.
@ Loads the word at 0x0804c0cc + index*4 (r1 = 0x0804c0d0 from movw/movt, then
@ add.w r0, r1, r0, lsl #2 and ldr r0, [r0, #-4]) and branches to it with bx r0.
@ No link register write, so lr still holds the return address of the caller of
@ this function (a return by the target goes to that caller). r0 holds the
@ target address and r1 = 0x0804c0d0 on entry to the target.
@ ----------------------------------------------------------------------------
	.section .text.jump_indirect_through_table,"ax",%progbits
	.p2align 2
	.global jump_indirect_through_table
	.thumb_func
	.type jump_indirect_through_table, %function
jump_indirect_through_table:
	movw r1, #:lower16:d_0804c0d0
	movt r1, #:upper16:d_0804c0d0
	add.w r0, r1, r0, lsl #2
	ldr.w r0, [r0, #-0x4]
	bx r0
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08012ce8 - No parameters.
@ Increments byte [0x2000835e], writing 0 when the new value is above 2 (value
@ cycles 0, 1, 2), formats "3:/System file/%d.jpg" with [0x2000835e] + 7 (images
@ 7..9) into 0x20008360 with 080073b4 and tail-calls 08039f6c(name, 0x121, 6)
@ with b.w (draws the image at x = 0x121, y = 6; the same image step as in
@ 0800fef0 without region record, buffer and hand-off).
@ ----------------------------------------------------------------------------
	.section .text.fn_08012ce8,"ax",%progbits
	.p2align 2
	.global fn_08012ce8
	.thumb_func
	.type fn_08012ce8, %function
fn_08012ce8:
	push {r4, lr}
	movw r0, #0x835e
	movt r0, #0x2000
	ldrb r1, [r0, #0x0]
	movw r4, #0x8360
	adds r1, #1
	uxtb r2, r1
	cmp r2, #0x2
	it hi
	movhi r1, #0x0
	strb r1, [r0, #0x0]
	movs r0, #0x7
	uxtab r2, r0, r1
	movt r4, #0x2000
	movw r1, #:lower16:t_080bc681
	movt r1, #:upper16:t_080bc681
	mov r0, r4
	bl format_to_buffer_080073b4
	mov r0, r4
	movw r1, #0x121
	movs r2, #0x6
	pop.w {r4, lr}
	b.w decode_image_file_with_offset

@ ----------------------------------------------------------------------------
@ fn_08012d2c - No parameters, no return value.
@ When byte [0x20001061] < 4 draws with
@ 0800f154(0x4b, 0xbe, 0xaa, 0x19, text, 0x20001174, 0x55f, 1) the text
@ = word [0x20001061] of d_0804c924 (Multimeter, Oscilloscope, Signal Generator, Settings) (same
@ drawing step as in 08010014 without region record and buffer).
@ ----------------------------------------------------------------------------
	.section .text.fn_08012d2c,"ax",%progbits
	.p2align 2
	.global fn_08012d2c
	.thumb_func
	.type fn_08012d2c, %function
fn_08012d2c:
	push {r7, lr}
	sub sp, #0x10
	movw r0, #0xf8
	movt r0, #0x2000
	ldrsb.w r1, [r0, #0xf69]
	cmp r1, #0x3
	bhi.n .L08012d7e
	movw r2, #:lower16:d_0804c924
	movt r2, #:upper16:d_0804c924
	ldr.w r0, [r2, r1, lsl #2]	@ English text of entry [0x20001061]
	movw r2, #0x1174
	movw r1, #0x55f
	movt r2, #0x2000
	mov.w r12, #0x1
	strd r0, r2, [sp]
	str r1, [sp, #0x8]
	movs r0, #0x4b
	movs r1, #0xbe
	movs r2, #0xaa
	movs r3, #0x19
	str.w r12, [sp, #0xc]
	bl draw_wrapped_text_in_box
.L08012d7e:
	add sp, #0x10
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08012d84 - No parameters, no return value.
@ Draws "3:/System file/71.jpg" at (0, 0) with 08039f6c, then "Oscilloscope Settings" with
@ 0800f154(0x34, 0, 0xd8, 0x14, text, 0x20001144, 0xffff, 1) (the drawing step of
@ 08010314 without region record and buffer).
@ ----------------------------------------------------------------------------
	.section .text.fn_08012d84,"ax",%progbits
	.p2align 2
	.global fn_08012d84
	.thumb_func
	.type fn_08012d84, %function
fn_08012d84:
	push {r7, lr}
	sub sp, #0x10
	movw r0, #:lower16:t_080bc456
	movt r0, #:upper16:t_080bc456
	movs r1, #0x0
	movs r2, #0x0
	bl decode_image_file_with_offset
	movw r0, #:lower16:t_080bcce8	@ "Oscilloscope Settings"
	movt r0, #:upper16:t_080bcce8
	movw r2, #0x1144
	movw r1, #0xffff
	movt r2, #0x2000
	mov.w r12, #0x1
	strd r0, r2, [sp]
	str r1, [sp, #0x8]
	movs r0, #0x34
	movs r1, #0x0
	movs r2, #0xd8
	movs r3, #0x14
	str.w r12, [sp, #0xc]
	bl draw_wrapped_text_in_box
	add sp, #0x10
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08012de0 - No parameters, no return value.
@ Reads byte [0x20001062]: L = low nibble, H = high nibble, D = L - H (byte).
@ Draws six rows at x = 0 and y = 0x18, 0x3c, 0x60, 0x84, 0xa8, 0xcc: image
@ "3:/System file/%d.jpg" (name in 0x20008360 via 080073b4, drawn with 08039f6c)
@ number H+0x3f (H+0x37 when D == 0), H+0x40 (H+0x38 when D == 1), H+0x41 (H+0x39
@ when D == 2), H+0x42 (H+0x3a when D == 3), H+0x43 (H+0x3b when D == 4), H+0x44
@ (H+0x3c when D == 5). After each image the text is drawn with
@ 0800f154(0x18, y, 0x4c, 0x24, text, 0x20001114, 0xffff, 0) with the text
@ = word H + row - 1 of the English item table d_0804c804 (rows 1..6).
@ ----------------------------------------------------------------------------
	.section .text.fn_08012de0,"ax",%progbits
	.p2align 2
	.global fn_08012de0
	.thumb_func
	.type fn_08012de0, %function
fn_08012de0:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x14
	movw r9, #0xf8
	movt r9, #0x2000
	ldrb.w r0, [r9, #0xf6a]
	movw r4, #0x8360
	and r1, r0, #0xf
	sub.w r1, r1, r0, lsr #4
	uxtb r5, r1
	movs r1, #0x3f
	movw r6, #:lower16:t_080bc681
	cmp r5, #0x0
	it eq
	moveq r1, #0x37
	movt r4, #0x2000
	movt r6, #:upper16:t_080bc681
	lsrs r7, r0, #4
	add.w r2, r1, r0, lsr #4
	mov r0, r4
	mov r1, r6
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x0
	movs r2, #0x18
	mov.w r10, #0x0
	bl decode_image_file_with_offset
	movw r11, #:lower16:d_0804c804	@ English item names, one word each
	movt r11, #:upper16:d_0804c804
	ldr.w r0, [r11, r7, lsl #2]	@ item H
	movw r8, #0x1114
	movw r1, #0xffff
	movt r8, #0x2000
	strd r0, r8, [sp]
	str r1, [sp, #0x8]
	movs r0, #0x18
	movs r1, #0x18
	movs r2, #0x4c
	movs r3, #0x24
	str.w r10, [sp, #0xc]
	bl draw_wrapped_text_in_box
	ldrb.w r0, [r9, #0xf6a]
	movs r3, #0x38
	lsrs r1, r0, #4
	add.w r2, r1, #0x40
	cmp r5, #0x1
	it eq
	addeq.w r2, r3, r0, lsr #4
	mov r0, r4
	mov r1, r6
	mov r10, r6
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x0
	movs r2, #0x3c
	bl decode_image_file_with_offset
	movs r1, #0x3c
	add.w r0, r11, r7, lsl #2
	ldr r0, [r0, #0x4]	@ item H+1
	movs r2, #0x4c
	strd r0, r8, [sp]
	movw r0, #0xffff
	str r0, [sp, #0x8]
	movs r0, #0x18
	movs r3, #0x24
	movs r6, #0x0
	str r6, [sp, #0xc]
	bl draw_wrapped_text_in_box
	ldrb.w r0, [r9, #0xf6a]
	movs r1, #0x41
	cmp r5, #0x2
	it eq
	moveq r1, #0x39
	add.w r2, r1, r0, lsr #4
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x0
	movs r2, #0x60
	bl decode_image_file_with_offset
	movs r1, #0x60
	add.w r0, r11, r7, lsl #2
	ldr r0, [r0, #0x8]	@ item H+2
	movs r2, #0x4c
	strd r0, r8, [sp]
	movw r0, #0xffff
	str r0, [sp, #0x8]
	movs r0, #0x18
	movs r3, #0x24
	movs r6, #0x0
	str r6, [sp, #0xc]
	bl draw_wrapped_text_in_box
	ldrb.w r0, [r9, #0xf6a]
	movs r1, #0x42
	cmp r5, #0x3
	it eq
	moveq r1, #0x3a
	add.w r2, r1, r0, lsr #4
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x0
	movs r2, #0x84
	bl decode_image_file_with_offset
	movs r1, #0x84
	add.w r0, r11, r7, lsl #2
	ldr r0, [r0, #0xc]	@ item H+3
	movs r2, #0x4c
	strd r0, r8, [sp]
	movw r0, #0xffff
	str r0, [sp, #0x8]
	movs r0, #0x18
	movs r3, #0x24
	movs r6, #0x0
	str r6, [sp, #0xc]
	bl draw_wrapped_text_in_box
	ldrb.w r0, [r9, #0xf6a]
	movs r1, #0x43
	cmp r5, #0x4
	it eq
	moveq r1, #0x3b
	add.w r2, r1, r0, lsr #4
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x0
	movs r2, #0xa8
	bl decode_image_file_with_offset
	movs r1, #0xa8
	add.w r0, r11, r7, lsl #2
	ldr r0, [r0, #0x10]	@ item H+4
	movs r2, #0x4c
	strd r0, r8, [sp]
	movw r0, #0xffff
	str r0, [sp, #0x8]
	movs r0, #0x18
	movs r3, #0x24
	movs r6, #0x0
	str r6, [sp, #0xc]
	movs r6, #0x0
	bl draw_wrapped_text_in_box
	ldrb.w r0, [r9, #0xf6a]
	movs r1, #0x44
	cmp r5, #0x5
	it eq
	moveq r1, #0x3c
	add.w r2, r1, r0, lsr #4
	mov r0, r4
	mov r1, r10
	bl format_to_buffer_080073b4
	mov r0, r4
	movs r1, #0x0
	movs r2, #0xcc
	bl decode_image_file_with_offset
	movs r1, #0xcc
	add.w r0, r11, r7, lsl #2
	ldr r0, [r0, #0x14]	@ item H+5
	movs r2, #0x4c
	strd r0, r8, [sp]
	movw r0, #0xffff
	str r0, [sp, #0x8]
	movs r0, #0x18
	movs r3, #0x24
	str r6, [sp, #0xc]
	bl draw_wrapped_text_in_box
	add sp, #0x14
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short 0x0000	@ padding
