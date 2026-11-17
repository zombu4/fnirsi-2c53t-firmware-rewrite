@ draw_waveform_display_p7.inc - part 7 of 7 of draw_waveform_display (0x0801c5ac..0x0801cab0):
@ the tail of the waveform screen drawing: pixel store, scale-value formatting,
@ trigger / status overlays, then the function epilogue and its trailing data.
@ Included by part 1 (same section .text.draw_waveform_display); no header lines here.
	ldrh	r4, [r4, #4]
	subs	r6, r0, r6
	subs	r5, r1, r5
	mla	r6, r5, r4, r6
	strh.w	r2, [r7, r6, lsl #1]	@ store the 16-bit pixel
	movw	r6, #0x8350
	movt	r6, #0x2000
	b.n	.L0801c348
.L0801c5c4:
	ldrd	r0, r1, [r9, #0x20]
	bl	i64_to_double
	vldr	d0, .L0801c338
	vmov	r2, r3, d0
	bl	double_div
	vldr	d0, .L0801c340
	vmov	d8, r0, r1
	vmov	r0, r1, d0
	vldr	d0, .L0801c330
	mov.w	r8, #0
	lsr.w	r9, r1, #0x1f
	vmov	r4, r5, d0
.L0801c5f4:
	vmov	r7, r6, d8
	mov	r1, r6
	bfi	r1, r9, #0x1f, #1
	mov	r0, r7
	mov	r2, r4
	mov	r3, r5
	bl	double_lt
	cbnz	r0, .L0801c620
	mov	r0, r7
	mov	r1, r6
	mov	r2, r4
	mov	r3, r5
	bl	double_div
	vmov	d8, r0, r1
	add.w	r8, r8, #1
	b.n	.L0801c5f4
.L0801c620:
	vstr	d8, [sp, #0x30]
	ldrb.w	r0, [sp, #0x37]
	movw	r1, #:lower16:d_0804bfc0
	eor.w	r0, r0, #0x80
	strb.w	r0, [sp, #0x37]
	uxtb.w	r0, r8
	movt	r1, #:upper16:d_0804bfc0
	movw	r4, #0x8360
	ldrd	r2, r3, [sp, #0x30]
	ldr.w	r7, [r1, r0, lsl #2]
	movt	r4, #0x2000
	movw	r1, #:lower16:d_080bcc10+1
	movt	r1, #:upper16:d_080bcc10+1
	mov	r0, r4
	str	r7, [sp]
	bl	format_to_buffer_080073b4
	movw	r0, #0x1144
	movt	r0, #0x2000
	strd	r4, r0, [sp, #0]
	movw	r0, #0xffff
	movs	r7, #1
	str	r0, [sp, #8]
	movs	r0, #0
	movs	r1, #0xb4
	mov.w	r2, #0x140
	movs	r3, #0x14
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r9, #0xf8
	movt	r9, #0x2000
	ldrb.w	r0, [r9, #0x34]
.L0801c68c:
	cbz	r0, .L0801c6d0
	bl	draw_channel_offset_markers_08028b40
	ldrb.w	r0, [r9, #0x34]
	cbnz	r0, .L0801c6d0
	ldrh.w	r0, [r9, #0x1c]
	movw	r3, #0x13d
	add.w	r1, r0, #0x64
	uxth	r1, r1
	rsb.w	r0, r0, #0x78
	cmp	r1, #0xc8
	it	hi
	movhi	r0, #0x14
	subs	r1, r0, #5
	adds	r2, r0, #5
	sxth	r1, r1
	movw	r7, #0x7e2
	strd	r3, r1, [sp, #0]
	sxth	r1, r0
	sxth	r3, r2
	mov.w	r0, #0x136
	movw	r2, #0x13d
	str	r7, [sp, #8]
	bl	fill_triangle
.L0801c6d0:
	ldrb.w	r0, [r9, #0xe10]
	cmp	r0, #0xff
	beq.n	.L0801c6da
	cbnz	r0, .L0801c712
.L0801c6da:
	ldrb.w	r1, [r9, #0x2f]
	ldrb.w	r2, [r9, #0x30]
	ldrb.w	r3, [r9, #0x33]
	orrs	r1, r2
	orrs	r1, r3
	bne.n	.L0801c712
	ldrb.w	r2, [r9, #0x17]
	ldrb.w	r1, [r9, #0x2e]
	cmp	r2, #2
	bne.n	.L0801c6fa
	cbnz	r1, .L0801c712
.L0801c6fa:
	cmp	r1, #0
	bne.n	.L0801c7b8
	ldr.w	r1, [r9, #0xe08]
	ldr.w	r2, [r9, #0xe0c]
	rsbs.w	r1, r1, #9
	mov.w	r1, #0
	sbcs	r1, r2
	bcc.n	.L0801c7b8
.L0801c712:
	movs	r5, #0x55
	movs	r0, #0xef
	movs	r4, #0
	strd	r0, r5, [sp, #0]
	movs	r0, #0xea
	movs	r1, #0x51
	movs	r2, #0x45
	movs	r3, #0x51
	str	r4, [sp, #8]
	bl	fill_triangle
	movs	r0, #0x59
	movs	r6, #0x3e
	strd	r6, r0, [sp, #0]
	movs	r0, #0x45
	movs	r1, #0x51
	movs	r2, #0xef
	movs	r3, #0x55
	str	r4, [sp, #8]
	bl	fill_triangle
	movw	r7, #0x101
	movs	r0, #0xef
	movs	r1, #0x55
	movs	r2, #0x3e
	movs	r3, #0x59
	strd	r7, r5, [sp, #0]
	str	r4, [sp, #8]
	bl	fill_triangle
	movs	r5, #0xa1
	movs	r0, #0x3e
	movs	r1, #0x59
	movw	r2, #0x101
	movs	r3, #0x55
	strd	r6, r5, [sp, #0]
	str	r4, [sp, #8]
	bl	fill_triangle
	movs	r0, #0x98
	strd	r7, r0, [sp, #0]
	movw	r0, #0x101
	movs	r1, #0x55
	movs	r2, #0x3e
	movs	r3, #0xa1
	str	r4, [sp, #8]
	bl	fill_triangle
	movs	r0, #0xfa
	strd	r0, r5, [sp, #0]
	movs	r0, #0x3e
	movs	r1, #0xa1
	movw	r2, #0x101
	movs	r3, #0x98
	str	r4, [sp, #8]
	bl	fill_triangle
	movw	r0, #:lower16:d_0804fd00
	movt	r0, #:upper16:d_0804fd00
	movw	r7, #0x55f
	str	r0, [sp]
	movs	r0, #0x3d
	movs	r1, #0x50
	movs	r2, #0xc6
	movs	r3, #0x53
	str	r7, [sp, #4]
	bl	draw_4bpp_bitmap
	ldrb.w	r0, [r9, #0xe10]
.L0801c7b8:
	cmp	r0, #3
	beq.n	.L0801c876
	cmp	r0, #2
	beq.n	.L0801c884
	cmp	r0, #1
	bne.n	.L0801c8ba
	movw	r0, #:lower16:d_080bc18a+1
	movt	r0, #:upper16:d_080bc18a+1
	bl	scan_capture_files
	ldrb.w	r1, [r9, #0xf60]
	movw	r2, #:lower16:d_0804bfd0
	movt	r2, #:upper16:d_0804bfd0
	add.w	r1, r2, r1, lsl #2
	ldr.w	r1, [r1, #-4]
	movw	r7, #0x1174
	movt	r7, #0x2000
	strb.w	r0, [r9, #0xe1b]
	movs	r5, #1
	movw	r6, #0x55f
	strd	r1, r7, [sp, #0]
	movs	r0, #0x3f
	movs	r1, #0x60
	movs	r2, #0xc2
	movs	r3, #0x19
	str	r6, [sp, #8]
	str	r5, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r4, #0x8360
	ldrb.w	r2, [r9, #0xe11]
	movt	r4, #0x2000
	movw	r1, #:lower16:d_080bcae4+1
	movt	r1, #:upper16:d_080bcae4+1
	mov	r0, r4
	bl	format_to_buffer_080073b4
	movs	r0, #0x3f
	movs	r1, #0x76
	movs	r2, #0xc2
	movs	r3, #0x19
	strd	r4, r7, [sp, #0]
	str	r6, [sp, #8]
	str	r5, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movs	r0, #0xff
	movw	r5, #0x2d6c
	strb.w	r0, [r9, #0xe10]
	movs	r0, #0xa
	movt	r5, #0x2000
	strb.w	r0, [r9, #0xf68]
	movs	r1, #0x24
	ldr	r0, [r5, #0]
	add.w	r4, sp, #0x3f
	strb.w	r1, [sp, #0x3f]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	movs	r1, #3
	ldr	r0, [r5, #0]
	strb.w	r1, [sp, #0x3f]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_send_timeout
	b.n	.L0801c8ba
.L0801c876:
	ldrb.w	r0, [r9, #0xf60]
	movw	r1, #:lower16:d_0804c010
	movt	r1, #:upper16:d_0804c010
	b.n	.L0801c890
.L0801c884:
	ldrb.w	r0, [r9, #0xf60]
	movw	r1, #:lower16:d_0804bff0
	movt	r1, #:upper16:d_0804bff0
.L0801c890:
	add.w	r0, r1, r0, lsl #2
	ldr.w	r0, [r0, #-4]
	movw	r2, #0x1174
	movw	r1, #0x55f
	movt	r2, #0x2000
	movs	r7, #1
	strd	r0, r2, [sp, #0]
	str	r1, [sp, #8]
	movs	r0, #0x3f
	movs	r1, #0x50
	movs	r2, #0xc2
	movs	r3, #0x53
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L0801c8ba:
	ldrb.w	r0, [r9, #0x17]
	cmp	r0, #2
	bne.n	.L0801c8fe
	ldrb.w	r0, [r9, #0x2e]
	cbz	r0, .L0801c8fe
	ldrb.w	r0, [r9, #0xf60]
	movw	r1, #:lower16:d_0804c030
	movt	r1, #:upper16:d_0804c030
	add.w	r0, r1, r0, lsl #2
	ldr.w	r0, [r0, #-4]
	movw	r2, #0x1174
	movw	r1, #0x55f
	movt	r2, #0x2000
	movs	r7, #1
	strd	r0, r2, [sp, #0]
	str	r1, [sp, #8]
	movs	r0, #0x3f
	movs	r1, #0x50
	movs	r2, #0xc2
	movs	r3, #0x53
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L0801c8fe:
	ldrb.w	r0, [r9, #0x2f]
	cbz	r0, .L0801c93a
	ldrb.w	r0, [r9, #0xf60]
	movw	r1, #:lower16:d_0804c050
	movt	r1, #:upper16:d_0804c050
	add.w	r0, r1, r0, lsl #2
	ldr.w	r0, [r0, #-4]
	movw	r2, #0x1174
	movw	r1, #0x55f
	movt	r2, #0x2000
	movs	r7, #0x81
	strd	r0, r2, [sp, #0]
	str	r1, [sp, #8]
	movs	r0, #0x3f
	movs	r1, #0x58
	movs	r2, #0xc2
	movs	r3, #0x4b
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L0801c93a:
	ldrb.w	r0, [r9, #0x30]
	cbz	r0, .L0801c976
	ldrb.w	r0, [r9, #0xf60]
	movw	r1, #:lower16:d_0804c070
	movt	r1, #:upper16:d_0804c070
	add.w	r0, r1, r0, lsl #2
	ldr.w	r0, [r0, #-4]
	movw	r2, #0x1174
	movw	r1, #0x55f
	movt	r2, #0x2000
	movs	r7, #0x81
	strd	r0, r2, [sp, #0]
	str	r1, [sp, #8]
	movs	r0, #0x3f
	movs	r1, #0x58
	movs	r2, #0xc2
	movs	r3, #0x4b
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L0801c976:
	ldrb.w	r0, [r9, #0x2e]
	cbnz	r0, .L0801c9c6
	ldr.w	r0, [r9, #0xe08]
	ldr.w	r1, [r9, #0xe0c]
	rsbs.w	r0, r0, #9
	mov.w	r0, #0
	sbcs	r0, r1
	bcc.n	.L0801c9c6
	ldrb.w	r0, [r9, #0xf60]
	movw	r1, #:lower16:d_0804c090
	movt	r1, #:upper16:d_0804c090
	add.w	r0, r1, r0, lsl #2
	ldr.w	r0, [r0, #-4]
	movw	r2, #0x1174
	movw	r1, #0x55f
	movt	r2, #0x2000
	movs	r7, #0x81
	strd	r0, r2, [sp, #0]
	str	r1, [sp, #8]
	movs	r0, #0x3f
	movs	r1, #0x58
	movs	r2, #0xc2
	movs	r3, #0x4b
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L0801c9c6:
	ldrb.w	r0, [r9, #0x33]
	cbz	r0, .L0801ca02
	ldrb.w	r0, [r9, #0xf60]
	movw	r1, #:lower16:d_0804c0b0
	movt	r1, #:upper16:d_0804c0b0
	add.w	r0, r1, r0, lsl #2
	ldr.w	r0, [r0, #-4]
	movw	r2, #0x1174
	movw	r1, #0x55f
	movt	r2, #0x2000
	movs	r7, #0x81
	strd	r0, r2, [sp, #0]
	str	r1, [sp, #8]
	movs	r0, #0x3f
	movs	r1, #0x58
	movs	r2, #0xc2
	movs	r3, #0x4b
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L0801ca02:
	ldrb.w	r0, [r9, #0xf70]
	adds	r0, #1
	strb.w	r0, [r9, #0xf70]
	add	sp, #0x40
	vpop	{d8, d9, d10, d11, d12}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0801ca18:
	.byte	0x00
	.byte	0x01, 0x02, 0x02, 0x01, 0x01, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
.L0801ca24:
	.word	0x080bcee6
	.word	0x080bcee1
	.word	0x080bcee5
	.word	0x00000000
	.word	0x080bbcc5
	.word	0x080bbcf2
	.word	0x080bbca4
	.word	0x080bbcf3
	.word	0x080bb5ef
	.word	0x00000000
	.word	0x00000000
	.word	0x00000000
	.word	0x080bbd2d
	.word	0x080bbd2e
	.word	0x00000000
	.word	0x00000000
.L0801ca64:
	.asciz	"%s%.2f%s"
	.byte	0x00, 0x00, 0x00	@ padding
.L0801ca70:
	.asciz	"%s%.1f%s"
	.byte	0x00, 0x00, 0x00	@ padding
.L0801ca7c:
	.word	0x080bba0c
	.word	0x080bba17
	.word	0x080bba14
	.word	0x080bba10
	.word	0x080bba1e
	.word	0x080bba1b
	.word	0x080bbabd
.L0801ca98:
	.byte	0x01, 0x01, 0x01
	.byte	0x02
	.byte	0x02, 0x02, 0x00, 0x00
.L0801caa0:
	.asciz	"%.2fmV"
	.byte	0x00	@ padding
.L0801caa8:
	.asciz	"%.2fV"
	.byte	0x00, 0x00	@ padding
