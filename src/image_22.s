@ image_22.s - decode_image_file_with_offset and image_rect_callback (image decoding to the display).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ decode_image_file_with_offset - decode an image file and draw it at an offset.
@ Params: r0 = path pointer, r1 (16-bit) = x offset stored to 0x20036b84,
@ r2 (16-bit) = y offset stored to 0x20036b88; no return value.
@ Allocates 0x7c bytes (decoder context) and 0x102c bytes (file object) with
@ alloc_units_of_32_bytes; returns at once if the first fails (frees only the
@ first when the second fails). Opens the file with file_open(file, r0, 1); on
@ success allocates 0x5000 work bytes and calls
@ parse_jpeg_header(ctx, file_read_or_skip_bytes, work, 0x5000, &file); when
@ that returns nonzero it closes the file with file_close and frees the blocks.
@ Otherwise it stores the offsets and calls
@ decode_scan_data_to_rgb565(ctx, image_rect_callback, 0) (decode with row
@ callback image_rect_callback) and then file_close(file).
@ Every exit frees the allocated blocks with inline copies of the logic of
@ 0803acbc (when byte 0x20001080 is 0 it calls the function pointer at
@ 0x20001070 with 0 instead; 0x2000107c is the table of 16-bit unit counts,
@ 32-byte units, block base word 0x20001078) by clearing count*2 bytes of the
@ table entry with zero_bytes. A failed open frees ctx and file object only.
@ ----------------------------------------------------------------------------
	.section .text.decode_image_file_with_offset,"ax",%progbits
	.global decode_image_file_with_offset
	.thumb_func
	.type decode_image_file_with_offset, %function
decode_image_file_with_offset:
	push.w {r4, r5, r6, r7, r8, r9, lr}
	sub sp, #0x14
	mov r4, r0
	movs r0, #0x7c
	mov r6, r2
	mov r7, r1
	bl alloc_units_of_32_bytes
	cmp r0, #0
	beq.w .L0803a150
	mov r5, r0
	movw r0, #0x102c
	bl alloc_units_of_32_bytes
	cbz r0, .L08039fd0
	mov r1, r4
	movs r2, #1
	mov r9, r0
	bl file_open
	cbz r0, .L08039ffe
.L08039f9c:
	movw r4, #0x1070
	movt r4, #0x2000
	ldrb r0, [r4, #0x10]
	cmp r0, #0
	beq.w .L0803a126
	ldr r6, [r4, #8]
	subs r0, r5, r6
	cmp.w r0, #0x2bc00
	bcs.n .L08039fca
.L08039fb6:
	ldr r2, [r4, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L08039fca
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L08039fca:
	sub.w r0, r9, r6
	b.n .L0803a136
.L08039fd0:
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r1, [r0, #0x10]
	cmp r1, #0
	beq.n .L0803a060
	ldr r1, [r0, #8]
	subs r1, r5, r1
	lsrs r2, r1, #0xa
	cmp r2, #0xae
	bhi.w .L0803a150
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	beq.w .L0803a150
	add.w r0, r0, r2, lsl #1
	b.n .L0803a14a
.L08039ffe:
	mov.w r0, #0x5000
	str.w r9, [sp, #8]
	bl alloc_units_of_32_bytes
	cbz r0, .L0803a064
	mov r8, r0
	movw r1, #:lower16:file_read_or_skip_bytes
	add r4, sp, #8
	movt r1, #:upper16:file_read_or_skip_bytes
	mov r0, r5
	mov r2, r8
	mov.w r3, #0x5000
	str r4, [sp, #0]
	bl parse_jpeg_header
	cbz r0, .L0803a06c
	ldr r0, [sp, #8]
	bl file_close
	movw r4, #0x1070
	movt r4, #0x2000
	ldrb r0, [r4, #0x10]
	cmp r0, #0
	beq.n .L0803a0c4
	ldr r6, [r4, #8]
	sub.w r0, r8, r6
	cmp.w r0, #0x2bc00
	bcs.n .L0803a0d2
	ldr r2, [r4, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cmp r1, #0
	beq.n .L0803a0d2
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0803a0d2
.L0803a060:
	ldr r1, [r0, #0]
	b.n .L0803a16a
.L0803a064:
	mov r0, r9
	bl file_close
	b.n .L08039f9c
.L0803a06c:
	movw r0, #0x6b84
	movt r0, #0x2003
	strh r7, [r0, #0]
	movw r0, #0x6b88
	movt r0, #0x2003
	movw r1, #:lower16:image_rect_callback
	strh r6, [r0, #0]
	movt r1, #:upper16:image_rect_callback
	mov r0, r5
	movs r2, #0
	bl decode_scan_data_to_rgb565
	ldr r0, [sp, #8]
	bl file_close
	movw r4, #0x1070
	movt r4, #0x2000
	ldrb r0, [r4, #0x10]
	cbz r0, .L0803a10e
	ldr r6, [r4, #8]
	sub.w r0, r8, r6
	cmp.w r0, #0x2bc00
	bcs.n .L0803a11a
	ldr r2, [r4, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0803a11a
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0803a11a
.L0803a0c4:
	ldr r1, [r4, #0]
	movs r0, #0
	blx r1
	ldrb r0, [r4, #0x10]
	cmp r0, #0
	beq.n .L0803a156
	ldr r6, [r4, #8]
.L0803a0d2:
	subs r0, r5, r6
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0803a0ee
	ldr r2, [r4, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0803a0ee
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
.L0803a0ee:
	sub.w r0, r9, r6
.L0803a0f2:
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0803a150
	ldr r2, [r4, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0803a150
	add.w r0, r2, r0, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L0803a150
.L0803a10e:
	ldr r1, [r4, #0]
	movs r0, #0
	blx r1
	ldrb r0, [r4, #0x10]
	cbz r0, .L0803a126
	ldr r6, [r4, #8]
.L0803a11a:
	subs r0, r5, r6
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.w .L08039fca
	b.n .L08039fb6
.L0803a126:
	ldr r1, [r4, #0]
	movs r0, #0
	blx r1
	ldrb r0, [r4, #0x10]
	cbz r0, .L0803a168
	ldr r0, [r4, #8]
	sub.w r0, r9, r0
.L0803a136:
	lsrs r1, r0, #0xa
	cmp r1, #0xae
	bhi.n .L0803a150
	ldr r2, [r4, #0xc]
	lsrs r0, r0, #5
	ldrh.w r1, [r2, r0, lsl #1]
	cbz r1, .L0803a150
	add.w r0, r2, r0, lsl #1
.L0803a14a:
	lsls r1, r1, #1
	bl zero_bytes
.L0803a150:
	add sp, #0x14
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L0803a156:
	ldr r1, [r4, #0]
	movs r0, #0
	blx r1
	ldrb r0, [r4, #0x10]
	cbz r0, .L0803a168
	ldr r0, [r4, #8]
	sub.w r0, r9, r0
	b.n .L0803a0f2
.L0803a168:
	ldr r1, [r4, #0]
.L0803a16a:
	movs r0, #0
	blx r1
	add sp, #0x14
	pop.w {r4, r5, r6, r7, r8, r9, pc}

@ ----------------------------------------------------------------------------
@ image_rect_callback - row callback of the image decoder.
@ Params: r0 (unused), r1 = pass-through argument, r2 = pointer to four shorts
@ (x0, x1, y0, y1 at indices 0..3); returns 1.
@ Calls the function pointer at 0x20036b80 with (halfword-sum 0x20036b84 + x0,
@ 0x20036b88 + y0, x1 - x0 + 1, y1 - y0 + 1, r1; the fifth argument on the
@ stack). Passed as the row callback by decode_image_file_with_offset to
@ decode_scan_data_to_rgb565 (rectangle of 4 halfwords).
@ ----------------------------------------------------------------------------
	.section .text.image_rect_callback,"ax",%progbits
	.global image_rect_callback
	.thumb_func
	.type image_rect_callback, %function
image_rect_callback:
	push {r4, r5, r7, lr}
	sub sp, #8
	movw r3, #0x6b84
	movt r3, #0x2003
	mov r12, r1
	movw r0, #0x6b80
	ldrh r1, [r2, #0]
	ldrh r3, [r3, #0]
	movt r0, #0x2003
	movw r4, #0x6b88
	ldrh r5, [r2, #2]
	ldr.w lr, [r0, #0]
	adds r0, r3, r1
	ldrh r3, [r2, #4]
	movt r4, #0x2003
	ldrh r2, [r2, #6]
	ldrh r4, [r4, #0]
	subs r1, r5, r1
	adds r5, r1, #1
	subs r1, r2, r3
	add r4, r3
	adds r3, r1, #1
	uxth r0, r0
	uxth r1, r4
	uxth r2, r5
	uxth r3, r3
	str.w r12, [sp, #0]
	blx lr
	movs r0, #1
	add sp, #8
	pop {r4, r5, r7, pc}
	.short 0x0000	@ padding
