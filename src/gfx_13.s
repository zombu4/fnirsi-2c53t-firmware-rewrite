@ gfx_13.s - RGB565 pixel blend, line, vertical run, 4bpp bitmap, gradient bar, rectangle halving, circle octants and triangle fill drawing routines.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ blend_pixel_rgb565 - blends one RGB565 pixel into the frame buffer.
@ Parameters: weight param_1 (float, s0), pixel x param_2 (r0), y param_3 (r1),
@ new colour param_4 (r2) and old colour param_5 (r3), both RGB565. No return value.
@ Clip rectangle: word 0x20008350/52/54/56 (x, y, width, height halfwords), buffer
@ pointer word 0x20008358.
@ When x and y are inside the clip rectangle it writes to
@ word 0x20008358 + ((y-clipY)*clipW + (x-clipX))*2 the halfword whose red (bits 15..11),
@ green (bits 10..5) and blue (bits 4..0) fields are each
@ int(new*weight + old*(1-weight)) (float math, truncated; red not masked, green
@ masked 0x3f, blue masked 0x1f). Does nothing outside the rectangle.
@ ----------------------------------------------------------------------------
	.section .text.blend_pixel_rgb565,"ax",%progbits
	.global blend_pixel_rgb565
	.thumb_func
	.type blend_pixel_rgb565, %function
blend_pixel_rgb565:
	push {r4, r5, r7, lr}
	movw r12, #0x8350
	movt r12, #0x2000
	ldrh.w lr, [r12, #0x0]
	cmp r0, lr
	blt.n .L0801fd9c
	ldrh.w lr, [r12, #0x0]
	ldrh.w r4, [r12, #0x4]
	add r4, lr
	cmp r4, r0
	ble.n .L0801fd9c
	ldrh.w r4, [r12, #0x2]
	cmp r1, r4
	blt.n .L0801fd9c
	ldrh.w lr, [r12, #0x2]
	ldrh.w r4, [r12, #0x6]
	add r4, lr
	cmp r4, r1
	it le
	pople {r4, r5, r7, pc}
	lsrs r4, r3, #0xb
	vmov s2, r4
	lsrs r4, r2, #0xb
	vmov.f32 s4, #1.0
	vmov s6, r4
	vcvt.f32.s32 s2, s2
	vsub.f32 s4, s4, s0
	vcvt.f32.s32 s6, s6
	vmul.f32 s2, s4, s2
	vmul.f32 s6, s6, s0
	vadd.f32 s2, s6, s2
	vcvt.s32.f32 s2, s2
	ubfx r4, r3, #0x5, #0x6
	vmov lr, s2
	vmov s2, r4
	ubfx r4, r2, #0x5, #0x6
	vmov s6, r4
	vcvt.f32.s32 s2, s2
	vcvt.f32.s32 s6, s6
	vmul.f32 s2, s4, s2
	vmul.f32 s6, s6, s0
	vadd.f32 s2, s6, s2
	vcvt.s32.f32 s2, s2
	and r3, r3, #0x1f
	vmov r5, s2
	vmov s2, r3
	vcvt.f32.s32 s2, s2
	and r2, r2, #0x1f
	vmul.f32 s2, s4, s2
	vmov s4, r2
	vcvt.f32.s32 s4, s4
	vmul.f32 s0, s4, s0
	vadd.f32 s0, s0, s2
	vcvt.s32.f32 s0, s0
	ldr.w r3, [r12, #0x8]
	ldrh.w r4, [r12, #0x0]
	vmov r2, s0
	and r2, r2, #0x1f
	subs r0, r0, r4
	ldrh.w r4, [r12, #0x2]
	orr.w lr, r2, lr, lsl #0xb
	ldrh.w r2, [r12, #0x4]
	subs r1, r1, r4
	and r5, r5, #0x3f
	mla r0, r1, r2, r0
	orr.w r1, lr, r5, lsl #0x5
	strh.w r1, [r3, r0, lsl #0x1]
.L0801fd9c:
	pop {r4, r5, r7, pc}
	.short 0x0000 @ padding

@ ----------------------------------------------------------------------------
@ draw_line - draws a line from (x1,y1) to (x2,y2) by error accumulation.
@ Parameters: x1 (r0), y1 (r1), x2 (r2), y2 (r3) (16-bit values) and 16-bit colour
@ param_5 (stack, [sp,#0x30] after the push). No return value.
@ dx = x2-x1, dy = y2-y1 (16-bit), sx/sy = sign of dx/dy (-1,0,1), ax/ay = |dx|,|dy|,
@ n = max(ax,ay). Do-while loop of n+2 iterations: writes the colour at (x,y) when
@ inside the clip rectangle word 0x20008350/52/54/56 (buffer word 0x20008358), then
@ accx += ax and accy += ay; when acc > n (strictly) x += sx (resp. y += sy) and
@ acc -= n.
@ ----------------------------------------------------------------------------
	.section .text.draw_line,"ax",%progbits
	.global draw_line
	.thumb_func
	.type draw_line, %function
draw_line:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0xc
	subs r2, r2, r0
	sxth r7, r2
	uxth.w r12, r2
	subs r6, r3, r1
	sxth r5, r6
	cmp.w r12, #0x0
	add.w r2, r2, r7, asr #0xf
	uxth.w r11, r6
	it ne
	movne.w r12, #0xffffffff
	eor.w r3, r2, r7, asr #0xf
	cmp r7, #0x0
	add.w r7, r6, r5, asr #0xf
	it gt
	movgt.w r12, #0x1
	cmp.w r11, #0x0
	eor.w r4, r7, r5, asr #0xf
	sxth r2, r3
	it ne
	movne.w r11, #0xffffffff
	sxth r7, r4
	cmp r5, #0x0
	it gt
	movgt.w r11, #0x1
	cmp r2, r7
	mov r2, r4
	it gt
	movgt r2, r3
	sxth.w r9, r2
	cmp.w r9, #0xffffffff
	bge.n .L0801fe06
.L0801fe00:
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0801fe06:
	uxth r2, r3
	movw r8, #0x8350
	str r2, [sp, #0x8]
	uxth r2, r4
	add.w r10, r9, #0x1
	movs r6, #0x0
	movt r8, #0x2000
	movs r5, #0x0
	movs r4, #0x0
	str r2, [sp, #0x4]
	b.n .L0801fe50
	.byte 0x00, 0xbf @ padding
.L0801fe24:
	ldr r2, [sp, #0x8]
	ldr r3, [sp, #0x4]
	sxtah r2, r2, r5
	sxth r7, r2
	sxtah r3, r3, r6
	subs.w r5, r7, r9
	ite le
	movle r5, r2
	addgt r0, r12
	sxth r2, r3
	adds r4, #0x1
	subs.w r6, r2, r9
	sxth r2, r4
	ite le
	movle r6, r3
	addgt r1, r11
	cmp r10, r2
	blt.n .L0801fe00
.L0801fe50:
	ldrh.w r7, [r8, #0x0]
	sxth r3, r0
	cmp r3, r7
	blt.n .L0801fe24
	ldrh.w r7, [r8, #0x0]
	ldrh.w r2, [r8, #0x4]
	add r2, r7
	cmp r2, r3
	ble.n .L0801fe24
	ldrh.w r2, [r8, #0x2]
	sxth.w lr, r1
	cmp lr, r2
	blt.n .L0801fe24
	ldrh.w r2, [r8, #0x2]
	ldrh.w r7, [r8, #0x6]
	add r2, r7
	cmp r2, lr
	ble.n .L0801fe24
	ldr.w r2, [r8, #0x8]
	str r2, [sp, #0x0]
	ldrh.w r7, [r8, #0x0]
	subs r3, r3, r7
	ldrh.w r7, [r8, #0x2]
	ldrh.w r2, [r8, #0x4]
	sub.w r7, lr, r7
	mla r2, r7, r2, r3
	ldr r3, [sp, #0x30]
	ldr r7, [sp, #0x0]
	strh.w r3, [r7, r2, lsl #0x1]
	b.n .L0801fe24

@ ----------------------------------------------------------------------------
@ fn_0801fea8 - draws the trace segment (x1,y1)-(x2,y2), anti-aliased (this rewrite, owner
@ 2026-11-18; V1.2.0 drew a hard vertical run in column x1 and one pixel at (x2,y2)).
@ Parameters: x1 (r0), y1 (r1), x2 (r2), y2 (r3) (16-bit, signed) and the 16-bit colour (stack,
@ first stack word). No return value. Callers: the live and persistence traces and the bar strip
@ of draw_waveform_display.
@ Xiaolin Wu's method along the longer axis in 16.16 fixed point: n = the longer difference, n + 1
@ steps from (x1,y1) to (x2,y2) (both end points included); at each step the position on the
@ other axis has the integer part i and the fraction f (8 bits): pixel i gets the coverage
@ 256 - f, pixel i + 1 the coverage f (not drawn when f is 0). aa_plot blends each one into the
@ region buffer. Equal end points give one full pixel; a vertical or horizontal segment gives
@ full pixels only.
@ ----------------------------------------------------------------------------
	.section .text.fn_0801fea8,"ax",%progbits
	.global fn_0801fea8
	.thumb_func
	.type fn_0801fea8, %function
fn_0801fea8:
	push	{r4, r5, r6, r7, r8, r9, r10, lr}
	ldr	r10, [sp, #32]			@ r10 = colour (8 registers pushed)
	uxth	r10, r10
	sxth	r0, r0
	sxth	r1, r1
	sxth	r2, r2
	sxth	r3, r3
	subs	r4, r2, r0			@ r4 = dx
	subs	r5, r3, r1			@ r5 = dy
	eor	r6, r4, r4, asr #31
	sub	r6, r6, r4, asr #31		@ r6 = |dx|
	eor	r7, r5, r5, asr #31
	sub	r7, r7, r5, asr #31		@ r7 = |dy|
	cmp	r7, r6
	blo	5f
	@ steep (|dy| >= |dx|): y steps by sign(dy), x is the 16.16 position
	mov	r9, r7				@ r9 = steps left after this one
	movs	r8, #0
	cmp	r5, #0
	it	gt
	movgt	r8, #1
	it	lt
	movlt	r8, #-1			@ r8 = y step
	movs	r6, #0				@ r6 = x step (0 when dy is 0)
	cbz	r7, 1f
	lsls	r6, r4, #16
	sdiv	r6, r6, r7
1:	lsls	r4, r0, #16			@ r4 = x (16.16)
	mov	r5, r1				@ r5 = y
2:	asrs	r0, r4, #16
	mov	r1, r5
	ubfx	r7, r4, #8, #8			@ r7 = f
	rsb	r2, r7, #256
	mov	r3, r10
	bl	aa_plot
	cbz	r7, 3f
	asrs	r0, r4, #16
	adds	r0, #1
	mov	r1, r5
	mov	r2, r7
	mov	r3, r10
	bl	aa_plot
3:	add	r4, r4, r6
	add	r5, r5, r8
	subs	r9, r9, #1
	bpl	2b
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}
	@ shallow (|dx| > |dy|): x steps by sign(dx), y is the 16.16 position
5:	mov	r9, r6
	movs	r8, #1
	cmp	r4, #0
	it	lt
	movlt	r8, #-1			@ r8 = x step
	lsls	r7, r5, #16
	sdiv	r7, r7, r6			@ r7 = y step (|dx| > 0 here)
	mov	r6, r7				@ r6 = y step
	lsls	r5, r1, #16			@ r5 = y (16.16)
	mov	r4, r0				@ r4 = x
6:	mov	r0, r4
	asrs	r1, r5, #16
	ubfx	r7, r5, #8, #8
	rsb	r2, r7, #256
	mov	r3, r10
	bl	aa_plot
	cbz	r7, 7f
	mov	r0, r4
	asrs	r1, r5, #16
	adds	r1, #1
	mov	r2, r7
	mov	r3, r10
	bl	aa_plot
7:	add	r5, r5, r6
	add	r4, r4, r8
	subs	r9, r9, #1
	bpl	6b
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}

@ aa_plot - r0 = x, r1 = y (signed), r2 = coverage 0..256, r3 = colour: the pixel of the region
@ buffer (record halfwords 0x20008350 x, 0x52 y, 0x54 width, 0x56 height, buffer word 0x20008358)
@ at (x, y), when inside: coverage above 240 writes the colour, below 16 leaves the pixel, else
@ the RGB565 blend of blend_glyph_into_region_buffer (src/gfx_12.s) with coverage c:
@ ((bg & 0xf81f) + (((fg & 0xf81f) - (bg & 0xf81f)) * (c >> 2) >> 6) & 0xf81f)
@ + ((bg & 0x7e0) + (((fg & 0x7e0) - (bg & 0x7e0)) * c >> 8) & 0x7e0). Changes r0..r3, r12.
	.global	aa_plot
	.thumb_func
	.type	aa_plot, %function
aa_plot:
	cmp	r2, #16
	blo	9f
	push	{r4, r5}
	movw	r12, #0x8350
	movt	r12, #0x2000
	ldrh	r4, [r12, #0]			@ region x
	subs	r0, r0, r4			@ r0 = x - region x
	bmi	8f
	ldrh	r4, [r12, #4]			@ width
	cmp	r0, r4
	bhs	8f
	ldrh	r5, [r12, #2]			@ region y
	subs	r1, r1, r5
	bmi	8f
	ldrh	r5, [r12, #6]			@ height
	cmp	r1, r5
	bhs	8f
	mla	r0, r1, r4, r0			@ index
	ldr	r1, [r12, #8]
	add	r1, r1, r0, lsl #1		@ r1 = pixel address
	cmp	r2, #240
	bls	1f
	strh	r3, [r1]
	b	8f
1:	ldrh	r0, [r1]			@ r0 = bg
	movw	r12, #0xf81f
	and	r4, r0, r12			@ bg red / blue
	and	r5, r3, r12			@ fg red / blue
	subs	r5, r5, r4
	lsrs	r12, r2, #2
	mul	r5, r5, r12
	add	r4, r4, r5, asr #6
	movw	r12, #0xf81f
	and	r4, r4, r12
	and	r0, r0, #0x7e0			@ bg green
	and	r5, r3, #0x7e0			@ fg green
	subs	r5, r5, r0
	mul	r5, r5, r2
	add	r0, r0, r5, asr #8
	and	r0, r0, #0x7e0
	orr	r0, r0, r4
	strh	r0, [r1]
8:	pop	{r4, r5}
9:	bx	lr
	.short	0x0000				@ padding: this section is 0x14c + 2 bytes, a multiple of 4 longer
						@ than V1.2.0's, so every following function keeps its address
						@ modulo 4 (their vldr / literal loads need that; a 2-byte shift
						@ made draw_gradient_bar draw white bars)

@ ----------------------------------------------------------------------------
@ draw_4bpp_bitmap - draws a 4-bit-per-pixel bitmap in one colour, each pixel
@ blended with the existing pixel by its nibble value.
@ Parameters: x (r0), y (r1) (16-bit), width param_3 (r2), height param_4 (r3),
@ pointer param_5 to the bitmap (stack, [sp,#0x3c] after the push and sub) and
@ RGB565 colour param_6 (stack, [sp,#0x40]). No return value.
@ Pixels are taken with a running index idx that is not reset per row:
@ byte = bitmap[idx>>1]; idx even takes the high nibble (shift 4 & ~(idx<<2),
@ instructions at 0x0802008e..0x08020096), idx odd the low nibble; when the row
@ width is odd idx is rounded up to even after the row (0x08020010..0x08020018).
@ a = nibble/15.0*255 (vdiv by 15.0 at 0x080200a2, vmul by 255.0, vcvt.s32):
@ a < 0x10 keeps the existing pixel (0 outside the clip rectangle), a > 0xf0 writes
@ param_6, otherwise the result is
@ (bg&0xf81f) + (((fg&0xf81f)-(bg&0xf81f))*(a>>2)>>6) masked 0xf81f plus
@ (bg&0x7e0) + (((fg&0x7e0)-(bg&0x7e0))*a>>8) masked 0x7e0.
@ Writes go to word 0x20008358 inside the clip rectangle word 0x20008350/52/54/56.
@ ----------------------------------------------------------------------------
	.section .text.draw_4bpp_bitmap,"ax",%progbits
	.global draw_4bpp_bitmap
	.thumb_func
	.type draw_4bpp_bitmap, %function
draw_4bpp_bitmap:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x18
	ldrd r6, r11, [sp, #0x3c]
	uxtah r3, r3, r1
	str r3, [sp, #0x4]
	mov r3, r6
	uxth r6, r0
	str r0, [sp, #0x8]
	uxtah lr, r2, r0
	bic r0, r11, #0x7e0
	str r0, [sp, #0x14]
	and r0, r11, #0x7e0
	movw r4, #0x8350
	vldr s2, .L08020130
	uxth r7, r1
	str r0, [sp, #0x10]
	movs r0, #0x0
	mov.w r12, #0x4
	movt r4, #0x2000
	vmov.f32 s0, #15.0
	str r6, [sp, #0x0]
	b.n .L0802002a
	.byte 0x00, 0xbf @ padding
.L08020010:
	add.w r1, r8, #0x3
	lsls r2, r0, #0x1f
	it ne
	bicne r0, r1, #0x1
	ldr r1, [sp, #0xc]
	ldr r2, [sp, #0x4]
	adds r1, #0x1
	sxth r7, r1
	cmp r2, r7
	ble.w .L08020128
.L0802002a:
	ldr.w r9, [sp, #0x0]
	ldr r5, [sp, #0x8]
	str r1, [sp, #0xc]
	b.n .L08020042
.L08020034:
	adds r5, #0x1
	sxth.w r9, r5
	cmp lr, r9
	add.w r0, r8, #0x1
	ble.n .L08020010
.L08020042:
	mov r8, r0
	uxth r0, r0
	lsrs r0, r0, #0x1
	ldrb.w r10, [r3, r0]
	ldrh r0, [r4, #0x0]
	cmp r9, r0
	blt.n .L0802008c
	ldrh r0, [r4, #0x0]
	ldrh r1, [r4, #0x4]
	add r0, r1
	cmp r0, r9
	ble.n .L0802008c
	ldrh r0, [r4, #0x2]
	cmp r7, r0
	blt.n .L0802008c
	ldrh r0, [r4, #0x2]
	ldrh r1, [r4, #0x6]
	add r0, r1
	cmp r0, r7
	ble.n .L0802008c
	ldr r0, [r4, #0x8]
	ldrh r1, [r4, #0x0]
	ldrh r6, [r4, #0x2]
	mov r2, r11
	ldrh.w r11, [r4, #0x4]
	sub.w r1, r9, r1
	subs r6, r7, r6
	mla r1, r6, r11, r1
	mov r11, r2
	ldrh.w r0, [r0, r1, lsl #0x1]
	b.n .L0802008e
	.byte 0x00, 0xbf @ padding
.L0802008c:
	movs r0, #0x0
.L0802008e:
	bic.w r1, r12, r8, lsl #0x2
	lsr.w r1, r10, r1
	and r1, r1, #0xf
	vmov s4, r1
	vcvt.f32.u32 s4, s4
	vdiv.f32 s4, s4, s0
	vmul.f32 s4, s4, s2
	vcvt.s32.f32 s4, s4
	vmov r1, s4
	cmp r1, #0x10
	bcs.n .L080200bc
	mov r6, r0
	b.n .L080200ee
	.byte 0x00, 0xbf @ padding
.L080200bc:
	cmp r1, #0xf0
	mov r6, r11
	bhi.n .L080200ee
	ldr r2, [sp, #0x14]
	bic r6, r0, #0x7e0
	subs r3, r2, r6
	lsrs r2, r1, #0x2
	muls r2, r3
	ldr r3, [sp, #0x10]
	and r0, r0, #0x7e0
	subs r3, r3, r0
	muls r1, r3
	add.w r2, r6, r2, lsr #0x6
	add.w r0, r0, r1, lsr #0x8
	movw r1, #0xf81f
	ldr r3, [sp, #0x3c]
	ands r1, r2
	and r0, r0, #0x7e0
	adds r6, r1, r0
.L080200ee:
	ldrh r0, [r4, #0x0]
	cmp r9, r0
	blt.n .L08020034
	ldrh r0, [r4, #0x0]
	ldrh r1, [r4, #0x4]
	add r0, r1
	cmp r0, r9
	ble.n .L08020034
	ldrh r0, [r4, #0x2]
	cmp r7, r0
	blt.n .L08020034
	ldrh r0, [r4, #0x2]
	ldrh r1, [r4, #0x6]
	add r0, r1
	cmp r0, r7
	ble.n .L08020034
	ldr r0, [r4, #0x8]
	ldrh r1, [r4, #0x0]
	ldrh r2, [r4, #0x2]
	ldrh r3, [r4, #0x4]
	sub.w r1, r9, r1
	subs r2, r7, r2
	mla r1, r2, r3, r1
	ldr r3, [sp, #0x3c]
	strh.w r6, [r0, r1, lsl #0x1]
	b.n .L08020034
.L08020128:
	add sp, #0x18
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.byte 0x00, 0xbf @ padding
.L08020130:
	.word 0x437f0000 @ 255.0f

@ ----------------------------------------------------------------------------
@ draw_gradient_bar - draws a 100-pixel wide bar whose colour follows (i/n)^3.333
@ per row.
@ Parameters: row range param_1 (r0) .. param_2 (r1) (16-bit, inclusive). No return
@ value. n = param_2-param_1+1; nothing when n <= 0.
@ For i = 0..n-1: t = float_pow(i/n, 0x40555555 = 3.3333333f) (single-precision x^y
@ routine), colour = int(t*5) << 11 | (int(t*11) & 0x3f) << 5 | (int(t*6) & 0x1f).
@ Row y = param_1 + i, filled for x = 0..99 (20 inner steps of five pixels,
@ x = uVar3-4..uVar3 with uVar3 = 4,9,..,99) with writes clipped against
@ word 0x20008350/52/54/56 into word 0x20008358.
@ ----------------------------------------------------------------------------
	.section .text.draw_gradient_bar,"ax",%progbits
	.global draw_gradient_bar
	.thumb_func
	.type draw_gradient_bar, %function
draw_gradient_bar:
	push.w {r4, r5, r6, r7, r8, r9, r10, lr}
	vpush {d8, d9, d10, d11, d12}
	mov r8, r0
	subs r0, r1, r0
	adds r0, #0x1
	sxth.w r9, r0
	cmp.w r9, #0x1
	blt.w .L08020322
	vmov s0, r9
	vldr s16, .L0802032c
	movw r7, #0x8350
	vcvt.f32.s32 s18, s0
	mov.w r10, #0x0
	vmov.f32 s20, #5.0
	vmov.f32 s22, #11.0
	vmov.f32 s24, #6.0
	movt r7, #0x2000
	b.n .L08020182
.L08020174:
	add.w r0, r10, #0x1
	sxth.w r10, r0
	cmp r10, r9
	bge.w .L08020322
.L08020182:
	sxth.w r0, r10
	vmov s0, r0
	vcvt.f32.s32 s0, s0
	vdiv.f32 s0, s0, s18
	vmov.f32 s1, s16
	bl float_pow
	vmul.f32 s2, s0, s20
	vcvt.s32.f32 s2, s2
	vmov r0, s2
	vmul.f32 s2, s0, s22
	vmul.f32 s0, s0, s24
	vcvt.s32.f32 s0, s0
	vcvt.s32.f32 s2, s2
	vmov r2, s0
	vmov r1, s2
	and r2, r2, #0x1f
	and r1, r1, #0x3f
	orr.w r0, r2, r0, lsl #0xb
	orr.w r0, r0, r1, lsl #0x5
	add.w r1, r10, r8
	sxth.w r12, r1
	mov lr, r12
	b.n .L080201e8
	.byte 0x00, 0xbf @ padding
.L080201dc:
	add.w r2, lr, #0x1
	sxth.w lr, r2
	cmp lr, r12
	bgt.n .L08020174
.L080201e8:
	sxth.w r3, lr
	movs r4, #0x4
	b.n .L080201f6
.L080201f0:
	adds r4, #0x5
	cmp r4, #0x68
	beq.n .L080201dc
.L080201f6:
	ldrh r6, [r7, #0x0]
	subs r5, r4, #0x4
	cmp r5, r6
	bcc.n .L08020230
	ldrh r6, [r7, #0x0]
	ldrh r1, [r7, #0x4]
	add r1, r6
	cmp r1, r5
	bls.n .L08020230
	ldrh r1, [r7, #0x2]
	cmp r3, r1
	blt.n .L08020230
	ldrh r1, [r7, #0x2]
	ldrh r6, [r7, #0x6]
	add r1, r6
	cmp r1, r3
	ble.n .L08020230
	ldr r1, [r7, #0x8]
	ldrh r6, [r7, #0x0]
	ldrh r5, [r7, #0x2]
	ldrh r2, [r7, #0x4]
	subs r5, r3, r5
	muls r2, r5
	subs r2, r2, r6
	add r2, r4
	add.w r1, r1, r2, lsl #0x1
	strh.w r0, [r1, #-0x8]
.L08020230:
	ldrh r1, [r7, #0x0]
	subs r5, r4, #0x3
	cmp r5, r1
	bcc.n .L0802026c
	ldrh r1, [r7, #0x0]
	ldrh r2, [r7, #0x4]
	add r1, r2
	cmp r1, r5
	bls.n .L0802026c
	ldrh r1, [r7, #0x2]
	cmp r3, r1
	blt.n .L0802026c
	ldrh r1, [r7, #0x2]
	ldrh r2, [r7, #0x6]
	add r1, r2
	cmp r1, r3
	ble.n .L0802026c
	ldr r1, [r7, #0x8]
	ldrh r2, [r7, #0x0]
	ldrh r5, [r7, #0x2]
	ldrh r6, [r7, #0x4]
	subs r5, r3, r5
	muls r5, r6
	subs r2, r5, r2
	add r2, r4
	add.w r1, r1, r2, lsl #0x1
	strh.w r0, [r1, #-0x6]
	nop
.L0802026c:
	ldrh r1, [r7, #0x0]
	subs r5, r4, #0x2
	cmp r5, r1
	bcc.n .L080202a8
	ldrh r1, [r7, #0x0]
	ldrh r2, [r7, #0x4]
	add r1, r2
	cmp r1, r5
	bls.n .L080202a8
	ldrh r1, [r7, #0x2]
	cmp r3, r1
	blt.n .L080202a8
	ldrh r1, [r7, #0x2]
	ldrh r2, [r7, #0x6]
	add r1, r2
	cmp r1, r3
	ble.n .L080202a8
	ldr r1, [r7, #0x8]
	ldrh r2, [r7, #0x0]
	ldrh r5, [r7, #0x2]
	ldrh r6, [r7, #0x4]
	subs r5, r3, r5
	muls r5, r6
	subs r2, r5, r2
	add r2, r4
	add.w r1, r1, r2, lsl #0x1
	strh.w r0, [r1, #-0x4]
	nop
.L080202a8:
	ldrh r1, [r7, #0x0]
	subs r5, r4, #0x1
	cmp r5, r1
	bcc.n .L080202e4
	ldrh r1, [r7, #0x0]
	ldrh r2, [r7, #0x4]
	add r1, r2
	cmp r1, r5
	bls.n .L080202e4
	ldrh r1, [r7, #0x2]
	cmp r3, r1
	blt.n .L080202e4
	ldrh r1, [r7, #0x2]
	ldrh r2, [r7, #0x6]
	add r1, r2
	cmp r1, r3
	ble.n .L080202e4
	ldr r1, [r7, #0x8]
	ldrh r2, [r7, #0x0]
	ldrh r5, [r7, #0x2]
	ldrh r6, [r7, #0x4]
	subs r5, r3, r5
	muls r5, r6
	subs r2, r5, r2
	add r2, r4
	add.w r1, r1, r2, lsl #0x1
	strh.w r0, [r1, #-0x2]
	nop
.L080202e4:
	ldrh r1, [r7, #0x0]
	cmp r4, r1
	bcc.w .L080201f0
	ldrh r1, [r7, #0x0]
	ldrh r2, [r7, #0x4]
	add r1, r2
	cmp r1, r4
	bls.w .L080201f0
	ldrh r1, [r7, #0x2]
	cmp r3, r1
	blt.w .L080201f0
	ldrh r1, [r7, #0x2]
	ldrh r2, [r7, #0x6]
	add r1, r2
	cmp r1, r3
	ble.w .L080201f0
	ldr r1, [r7, #0x8]
	ldrh r2, [r7, #0x0]
	ldrh r5, [r7, #0x2]
	ldrh r6, [r7, #0x4]
	subs r5, r3, r5
	muls r5, r6
	subs r2, r5, r2
	add r2, r4
	strh.w r0, [r1, r2, lsl #0x1]
	b.n .L080201f0
.L08020322:
	vpop {d8, d9, d10, d11, d12}
	pop.w {r4, r5, r6, r7, r8, r9, r10, pc}
	.byte 0x00, 0xbf @ padding
.L0802032c:
	.word 0x40555555 @ 3.3333333f

@ ----------------------------------------------------------------------------
@ halve_rect_rgb565 - darkens a rectangle to half brightness.
@ Parameters: x1 (r0), y1 (r1), x2 (r2), y2 (r3) (16-bit loop counters). No return
@ value. Returns at once when y1 > y2 (cmp at 0x08020336). When x2 < x1
@ (0x08020346) it only steps y in a loop without touching memory.
@ Otherwise for every (x,y) with x1<=x<=x2, y1<=y<=y2 it reads the pixel from
@ word 0x20008358 (0 outside the clip rectangle word 0x20008350/52/54/56) and, inside the
@ clip rectangle, writes back each field halved: the 5-bit red, 6-bit green and
@ 5-bit blue fields are computed as field*128 times 0x80808081 >> 32 (1/255 scaling,
@ umull at 0x0802041c/0x08020428/0x08020434) and shifted into place, which for all
@ 65536 input pixels equals field>>1 per field (checked by exhaustive computation
@ of those instructions).
@ ----------------------------------------------------------------------------
	.section .text.halve_rect_rgb565,"ax",%progbits
	.global halve_rect_rgb565
	.thumb_func
	.type halve_rect_rgb565, %function
halve_rect_rgb565:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x4
	cmp r1, r3
	str r0, [sp, #0x0]
	ble.n .L08020342
.L0802033c:
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08020342:
	ldr r0, [sp, #0x0]
	cmp r0, r2
	ble.n .L0802036a
.L08020348:
	adds r0, r1, #0x1
	sxth r0, r0
	cmp r0, r3
	bgt.n .L0802033c
	adds r0, r1, #0x2
	sxth r0, r0
	cmp r0, r3
	bgt.n .L0802033c
	adds r0, r1, #0x3
	sxth r0, r0
	cmp r0, r3
	bgt.n .L0802033c
	adds r0, r1, #0x4
	sxth r1, r0
	cmp r1, r3
	ble.n .L08020348
	b.n .L0802033c
.L0802036a:
	movw r12, #0x8350
	movt r12, #0x2000
	b.n .L0802037c
.L08020374:
	adds r1, #0x1
	sxth r1, r1
	cmp r1, r3
	bgt.n .L0802033c
.L0802037c:
	ldr r7, [sp, #0x0]
	sxth.w r9, r1
	b.n .L0802038c
.L08020384:
	adds r0, r7, #0x1
	sxth r7, r0
	cmp r7, r2
	bgt.n .L08020374
.L0802038c:
	ldrh.w r4, [r12, #0x0]
	sxth r5, r7
	cmp r5, r4
	blt.n .L080203dc
	ldrh.w r4, [r12, #0x0]
	ldrh.w r6, [r12, #0x4]
	add r6, r4
	cmp r6, r5
	ble.n .L080203dc
	ldrh.w r6, [r12, #0x2]
	cmp r9, r6
	blt.n .L080203dc
	ldrh.w r6, [r12, #0x2]
	ldrh.w r4, [r12, #0x6]
	add r6, r4
	cmp r6, r9
	ble.n .L080203dc
	ldr.w lr, [r12, #0x8]
	ldrh.w r4, [r12, #0x0]
	ldrh.w r6, [r12, #0x2]
	ldrh.w r10, [r12, #0x4]
	subs r4, r5, r4
	sub.w r6, r9, r6
	mla r4, r6, r10, r4
	ldrh.w lr, [lr, r4, lsl #0x1]
	b.n .L080203e0
	.byte 0x00, 0xbf @ padding
.L080203dc:
	mov.w lr, #0x0
.L080203e0:
	ldrh.w r4, [r12, #0x0]
	cmp r5, r4
	blt.n .L08020384
	ldrh.w r4, [r12, #0x0]
	ldrh.w r6, [r12, #0x4]
	add r4, r6
	cmp r4, r5
	ble.n .L08020384
	ldrh.w r4, [r12, #0x2]
	cmp r9, r4
	blt.n .L08020384
	ldrh.w r4, [r12, #0x2]
	ldrh.w r6, [r12, #0x6]
	add r4, r6
	cmp r4, r9
	ble.n .L08020384
	mvn r0, #0x7f
	and.w r4, r0, lr, lsr #0x4
	movw r0, #0x8081
	movt r0, #0x8080
	umull r4, r6, r4, r0
	mov.w r4, #0x1f80
	and.w r4, r4, lr, lsl #0x2
	umull r4, r10, r4, r0
	mov.w r4, #0xf80
	and.w r4, r4, lr, lsl #0x7
	umull r4, lr, r4, r0
	ldr.w r4, [r12, #0x8]
	ldrh.w r11, [r12, #0x0]
	lsls r0, r6, #0x4
	sub.w r11, r5, r11
	ldrh.w r5, [r12, #0x2]
	ldrh.w r8, [r12, #0x4]
	movw r6, #0x7ff
	sub.w r5, r9, r5
	bics r0, r6
	mvn r6, #0x1f
	mla r5, r5, r8, r11
	and.w r6, r6, r10, lsr #0x2
	orr.w r0, r0, lr, lsr #0x7
	orrs r0, r6
	strh.w r0, [r4, r5, lsl #0x1]
	b.n .L08020384

@ ----------------------------------------------------------------------------
@ draw_circle_octants - draws circle arcs by octant in colour 0xfb43.
@ Parameters: centre x = param_1 (r0), y = param_2 (r1) (16-bit), radius param_3
@ (r2) and octant mask param_4 (r3, bits 0..7). No return value.
@ Integer midpoint iteration: d = 3 - 2r, i = 0; per step with a = i+1:
@ if (short)d < 0 then b = r and d += 4*i + 6, else b = r-1,
@ d += 4*(i-r) + 10 and r = r-1.
@ Writes colour 0xfb43 into word 0x20008358 (clipped against word 0x20008350/52/54/56) at
@ the point selected by each set mask bit: bit0 (cx+b, cy-a), bit1 (cx+a, cy-b),
@ bit2 (cx-a, cy-b), bit3 (cx-b, cy-a), bit4 (cx-b, cy+a), bit5 (cx-a, cy+b),
@ bit6 (cx+a, cy+b), bit7 (cx+b, cy+a). Loop continues while i+1 < r. The point at
@ offset a=0 is not drawn.
@ The mask bits are kept on the stack: bit0 [sp,#0x18], bit1 [sp,#0x14], bit2
@ [sp,#0x10], bit3 [sp,#0xc], bit4 [sp,#0x8], bit5 [sp,#0x4], bit6 [sp,#0x0],
@ bit7 in r10; the centre y is at [sp,#0x1c].
@ ----------------------------------------------------------------------------
	.section .text.draw_circle_octants,"ax",%progbits
	.global draw_circle_octants
	.thumb_func
	.type draw_circle_octants, %function
draw_circle_octants:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x20
	mov r8, r2
	sub.w r2, r2, r2, lsl #0x1
	movs r7, #0x3
	add.w r6, r7, r2, lsl #0x1
	and r2, r3, #0x1
	str r2, [sp, #0x18]
	and r2, r3, #0x2
	str r2, [sp, #0x14]
	and r2, r3, #0x4
	str r2, [sp, #0x10]
	and r2, r3, #0x8
	str r1, [sp, #0x1c]
	movw r1, #0xfffe
	str r2, [sp, #0xc]
	and r2, r3, #0x10
	str r2, [sp, #0x8]
	and r2, r3, #0x20
	adds r1, #0x1
	movw r12, #0x8350
	str r2, [sp, #0x4]
	and r2, r3, #0x40
	and r10, r3, #0x80
	mov.w r9, #0x0
	sxth.w r11, r1
	movt r12, #0x2000
	movs r1, #0x0
	str r2, [sp, #0x0]
	b.n .L080204de
.L080204cc:
	mov r2, r8
.L080204ce:
	sxth.w r9, lr
	sxth r1, r2
	cmp r9, r1
	mov r8, r2
	mov r1, lr
	bge.w .L08020af2
.L080204de:
	sxth r2, r6
	cmp r2, r11
	ble.w .L080207e8
	ldr r2, [sp, #0x18]
	add.w lr, r9, #0x1
	cmp r2, #0x0
	sub.w r2, r8, #0x1
	beq.n .L0802054c
	adds r4, r2, r0
	ldrh.w r5, [r12, #0x0]
	sxth r4, r4
	cmp r4, r5
	blt.n .L0802054c
	ldrh.w r5, [r12, #0x0]
	ldrh.w r3, [r12, #0x4]
	add r3, r5
	cmp r3, r4
	ble.n .L0802054c
	ldr r3, [sp, #0x1c]
	ldrh.w r7, [r12, #0x2]
	sub.w r3, r3, lr
	sxth r5, r3
	cmp r5, r7
	blt.n .L0802054c
	ldrh.w r3, [r12, #0x2]
	ldrh.w r7, [r12, #0x6]
	add r3, r7
	cmp r3, r5
	ble.n .L0802054c
	ldr.w r9, [r12, #0x8]
	ldrh.w r7, [r12, #0x0]
	subs r4, r4, r7
	ldrh.w r7, [r12, #0x2]
	ldrh.w r3, [r12, #0x4]
	subs r5, r5, r7
	mla r3, r5, r3, r4
	movw r4, #0xfb43
	strh.w r4, [r9, r3, lsl #0x1]
.L0802054c:
	ldr r3, [sp, #0x14]
	cbz r3, .L080205a8
	add.w r3, lr, r0
	ldrh.w r5, [r12, #0x0]
	sxth r4, r3
	cmp r4, r5
	blt.n .L080205a8
	ldrh.w r3, [r12, #0x0]
	ldrh.w r5, [r12, #0x4]
	add r3, r5
	cmp r3, r4
	ble.n .L080205a8
	ldr r3, [sp, #0x1c]
	ldrh.w r7, [r12, #0x2]
	subs r3, r3, r2
	sxth r5, r3
	cmp r5, r7
	blt.n .L080205a8
	ldrh.w r3, [r12, #0x2]
	ldrh.w r7, [r12, #0x6]
	add r3, r7
	cmp r3, r5
	ble.n .L080205a8
	ldr.w r9, [r12, #0x8]
	ldrh.w r7, [r12, #0x0]
	subs r4, r4, r7
	ldrh.w r7, [r12, #0x2]
	ldrh.w r3, [r12, #0x4]
	subs r5, r5, r7
	mla r3, r5, r3, r4
	movw r4, #0xfb43
	strh.w r4, [r9, r3, lsl #0x1]
.L080205a8:
	ldr r3, [sp, #0x10]
	cbz r3, .L08020604
	sub.w r3, r0, lr
	ldrh.w r5, [r12, #0x0]
	sxth r4, r3
	cmp r4, r5
	blt.n .L08020604
	ldrh.w r3, [r12, #0x0]
	ldrh.w r5, [r12, #0x4]
	add r3, r5
	cmp r3, r4
	ble.n .L08020604
	ldr r3, [sp, #0x1c]
	ldrh.w r7, [r12, #0x2]
	subs r3, r3, r2
	sxth r5, r3
	cmp r5, r7
	blt.n .L08020604
	ldrh.w r3, [r12, #0x2]
	ldrh.w r7, [r12, #0x6]
	add r3, r7
	cmp r3, r5
	ble.n .L08020604
	ldr.w r9, [r12, #0x8]
	ldrh.w r7, [r12, #0x0]
	subs r4, r4, r7
	ldrh.w r7, [r12, #0x2]
	ldrh.w r3, [r12, #0x4]
	subs r5, r5, r7
	mla r3, r5, r3, r4
	movw r4, #0xfb43
	strh.w r4, [r9, r3, lsl #0x1]
.L08020604:
	ldr r3, [sp, #0xc]
	cbz r3, .L08020660
	subs r3, r0, r2
	ldrh.w r5, [r12, #0x0]
	sxth r4, r3
	cmp r4, r5
	blt.n .L08020660
	ldrh.w r3, [r12, #0x0]
	ldrh.w r5, [r12, #0x4]
	add r3, r5
	cmp r3, r4
	ble.n .L08020660
	ldr r3, [sp, #0x1c]
	ldrh.w r7, [r12, #0x2]
	sub.w r3, r3, lr
	sxth r5, r3
	cmp r5, r7
	blt.n .L08020660
	ldrh.w r3, [r12, #0x2]
	ldrh.w r7, [r12, #0x6]
	add r3, r7
	cmp r3, r5
	ble.n .L08020660
	ldr.w r9, [r12, #0x8]
	ldrh.w r7, [r12, #0x0]
	subs r4, r4, r7
	ldrh.w r7, [r12, #0x2]
	ldrh.w r3, [r12, #0x4]
	subs r5, r5, r7
	mla r3, r5, r3, r4
	movw r4, #0xfb43
	strh.w r4, [r9, r3, lsl #0x1]
.L08020660:
	ldr r3, [sp, #0x8]
	cbz r3, .L080206bc
	subs r3, r0, r2
	ldrh.w r5, [r12, #0x0]
	sxth r4, r3
	cmp r4, r5
	blt.n .L080206bc
	ldrh.w r3, [r12, #0x0]
	ldrh.w r5, [r12, #0x4]
	add r3, r5
	cmp r3, r4
	ble.n .L080206bc
	ldr r3, [sp, #0x1c]
	ldrh.w r7, [r12, #0x2]
	add r3, lr
	sxth r5, r3
	cmp r5, r7
	blt.n .L080206bc
	ldrh.w r3, [r12, #0x2]
	ldrh.w r7, [r12, #0x6]
	add r3, r7
	cmp r3, r5
	ble.n .L080206bc
	ldr.w r9, [r12, #0x8]
	ldrh.w r7, [r12, #0x0]
	subs r4, r4, r7
	ldrh.w r7, [r12, #0x2]
	ldrh.w r3, [r12, #0x4]
	subs r5, r5, r7
	mla r3, r5, r3, r4
	movw r4, #0xfb43
	strh.w r4, [r9, r3, lsl #0x1]
	nop
.L080206bc:
	ldr r3, [sp, #0x4]
	cbz r3, .L08020718
	sub.w r3, r0, lr
	ldrh.w r5, [r12, #0x0]
	sxth r4, r3
	cmp r4, r5
	blt.n .L08020718
	ldrh.w r3, [r12, #0x0]
	ldrh.w r5, [r12, #0x4]
	add r3, r5
	cmp r3, r4
	ble.n .L08020718
	ldr r3, [sp, #0x1c]
	ldrh.w r7, [r12, #0x2]
	add r3, r2
	sxth r5, r3
	cmp r5, r7
	blt.n .L08020718
	ldrh.w r3, [r12, #0x2]
	ldrh.w r7, [r12, #0x6]
	add r3, r7
	cmp r3, r5
	ble.n .L08020718
	ldr.w r9, [r12, #0x8]
	ldrh.w r7, [r12, #0x0]
	subs r4, r4, r7
	ldrh.w r7, [r12, #0x2]
	ldrh.w r3, [r12, #0x4]
	subs r5, r5, r7
	mla r3, r5, r3, r4
	movw r4, #0xfb43
	strh.w r4, [r9, r3, lsl #0x1]
.L08020718:
	ldr r3, [sp, #0x0]
	cbz r3, .L08020774
	add.w r3, lr, r0
	ldrh.w r5, [r12, #0x0]
	sxth r4, r3
	cmp r4, r5
	blt.n .L08020774
	ldrh.w r3, [r12, #0x0]
	ldrh.w r5, [r12, #0x4]
	add r3, r5
	cmp r3, r4
	ble.n .L08020774
	ldr r3, [sp, #0x1c]
	ldrh.w r7, [r12, #0x2]
	add r3, r2
	sxth r5, r3
	cmp r5, r7
	blt.n .L08020774
	ldrh.w r3, [r12, #0x2]
	ldrh.w r7, [r12, #0x6]
	add r3, r7
	cmp r3, r5
	ble.n .L08020774
	ldr.w r9, [r12, #0x8]
	ldrh.w r7, [r12, #0x0]
	subs r4, r4, r7
	ldrh.w r7, [r12, #0x2]
	ldrh.w r3, [r12, #0x4]
	subs r5, r5, r7
	mla r3, r5, r3, r4
	movw r4, #0xfb43
	strh.w r4, [r9, r3, lsl #0x1]
.L08020774:
	sub.w r1, r1, r8
	add.w r1, r6, r1, lsl #0x2
	cmp.w r10, #0x0
	add.w r6, r1, #0xa
	beq.w .L080204ce
	adds r1, r2, r0
	ldrh.w r3, [r12, #0x0]
	sxth r1, r1
	cmp r1, r3
	blt.w .L080204ce
	ldrh.w r3, [r12, #0x0]
	ldrh.w r4, [r12, #0x4]
	add r3, r4
	cmp r3, r1
	ble.w .L080204ce
	ldr r3, [sp, #0x1c]
	ldrh.w r5, [r12, #0x2]
	add r3, lr
	sxth r4, r3
	cmp r4, r5
	blt.w .L080204ce
	ldrh.w r3, [r12, #0x2]
	ldrh.w r5, [r12, #0x6]
	add r3, r5
	cmp r3, r4
	ble.w .L080204ce
	ldr.w r3, [r12, #0x8]
	ldrh.w r5, [r12, #0x0]
	subs r1, r1, r5
	ldrh.w r5, [r12, #0x2]
	ldrh.w r7, [r12, #0x4]
	subs r4, r4, r5
	mla r1, r4, r7, r1
	movw r4, #0xfb43
	strh.w r4, [r3, r1, lsl #0x1]
	b.n .L080204ce
.L080207e8:
	ldr r2, [sp, #0x18]
	add.w lr, r9, #0x1
	cbz r2, .L0802084c
	add.w r2, r8, r0
	ldrh.w r3, [r12, #0x0]
	sxth r2, r2
	cmp r2, r3
	blt.n .L0802084c
	ldrh.w r3, [r12, #0x0]
	ldrh.w r4, [r12, #0x4]
	add r3, r4
	cmp r3, r2
	ble.n .L0802084c
	ldr r3, [sp, #0x1c]
	ldrh.w r5, [r12, #0x2]
	sub.w r3, r3, lr
	sxth r4, r3
	cmp r4, r5
	blt.n .L0802084c
	ldrh.w r3, [r12, #0x2]
	ldrh.w r5, [r12, #0x6]
	add r3, r5
	cmp r3, r4
	ble.n .L0802084c
	ldr.w r3, [r12, #0x8]
	ldrh.w r5, [r12, #0x0]
	subs r2, r2, r5
	ldrh.w r5, [r12, #0x2]
	ldrh.w r7, [r12, #0x4]
	subs r4, r4, r5
	mla r2, r4, r7, r2
	movw r4, #0xfb43
	strh.w r4, [r3, r2, lsl #0x1]
	nop
.L0802084c:
	ldr r2, [sp, #0x14]
	cbz r2, .L080208ac
	add.w r2, lr, r0
	ldrh.w r3, [r12, #0x0]
	sxth r2, r2
	cmp r2, r3
	blt.n .L080208ac
	ldrh.w r3, [r12, #0x0]
	ldrh.w r4, [r12, #0x4]
	add r3, r4
	cmp r3, r2
	ble.n .L080208ac
	ldr r3, [sp, #0x1c]
	ldrh.w r5, [r12, #0x2]
	sub.w r3, r3, r8
	sxth r4, r3
	cmp r4, r5
	blt.n .L080208ac
	ldrh.w r3, [r12, #0x2]
	ldrh.w r5, [r12, #0x6]
	add r3, r5
	cmp r3, r4
	ble.n .L080208ac
	ldr.w r3, [r12, #0x8]
	ldrh.w r5, [r12, #0x0]
	subs r2, r2, r5
	ldrh.w r5, [r12, #0x2]
	ldrh.w r7, [r12, #0x4]
	subs r4, r4, r5
	mla r2, r4, r7, r2
	movw r4, #0xfb43
	strh.w r4, [r3, r2, lsl #0x1]
	nop
.L080208ac:
	ldr r2, [sp, #0x10]
	cbz r2, .L0802090c
	sub.w r2, r0, lr
	ldrh.w r3, [r12, #0x0]
	sxth r2, r2
	cmp r2, r3
	blt.n .L0802090c
	ldrh.w r3, [r12, #0x0]
	ldrh.w r4, [r12, #0x4]
	add r3, r4
	cmp r3, r2
	ble.n .L0802090c
	ldr r3, [sp, #0x1c]
	ldrh.w r5, [r12, #0x2]
	sub.w r3, r3, r8
	sxth r4, r3
	cmp r4, r5
	blt.n .L0802090c
	ldrh.w r3, [r12, #0x2]
	ldrh.w r5, [r12, #0x6]
	add r3, r5
	cmp r3, r4
	ble.n .L0802090c
	ldr.w r3, [r12, #0x8]
	ldrh.w r5, [r12, #0x0]
	subs r2, r2, r5
	ldrh.w r5, [r12, #0x2]
	ldrh.w r7, [r12, #0x4]
	subs r4, r4, r5
	mla r2, r4, r7, r2
	movw r4, #0xfb43
	strh.w r4, [r3, r2, lsl #0x1]
	nop
.L0802090c:
	ldr r2, [sp, #0xc]
	cbz r2, .L0802096c
	sub.w r2, r0, r8
	ldrh.w r3, [r12, #0x0]
	sxth r2, r2
	cmp r2, r3
	blt.n .L0802096c
	ldrh.w r3, [r12, #0x0]
	ldrh.w r4, [r12, #0x4]
	add r3, r4
	cmp r3, r2
	ble.n .L0802096c
	ldr r3, [sp, #0x1c]
	ldrh.w r5, [r12, #0x2]
	sub.w r3, r3, lr
	sxth r4, r3
	cmp r4, r5
	blt.n .L0802096c
	ldrh.w r3, [r12, #0x2]
	ldrh.w r5, [r12, #0x6]
	add r3, r5
	cmp r3, r4
	ble.n .L0802096c
	ldr.w r3, [r12, #0x8]
	ldrh.w r5, [r12, #0x0]
	subs r2, r2, r5
	ldrh.w r5, [r12, #0x2]
	ldrh.w r7, [r12, #0x4]
	subs r4, r4, r5
	mla r2, r4, r7, r2
	movw r4, #0xfb43
	strh.w r4, [r3, r2, lsl #0x1]
	nop
.L0802096c:
	ldr r2, [sp, #0x8]
	cbz r2, .L080209c8
	sub.w r2, r0, r8
	ldrh.w r3, [r12, #0x0]
	sxth r2, r2
	cmp r2, r3
	blt.n .L080209c8
	ldrh.w r3, [r12, #0x0]
	ldrh.w r4, [r12, #0x4]
	add r3, r4
	cmp r3, r2
	ble.n .L080209c8
	ldr r3, [sp, #0x1c]
	ldrh.w r5, [r12, #0x2]
	add r3, lr
	sxth r4, r3
	cmp r4, r5
	blt.n .L080209c8
	ldrh.w r3, [r12, #0x2]
	ldrh.w r5, [r12, #0x6]
	add r3, r5
	cmp r3, r4
	ble.n .L080209c8
	ldr.w r3, [r12, #0x8]
	ldrh.w r5, [r12, #0x0]
	subs r2, r2, r5
	ldrh.w r5, [r12, #0x2]
	ldrh.w r7, [r12, #0x4]
	subs r4, r4, r5
	mla r2, r4, r7, r2
	movw r4, #0xfb43
	strh.w r4, [r3, r2, lsl #0x1]
.L080209c8:
	ldr r2, [sp, #0x4]
	cbz r2, .L08020a24
	sub.w r2, r0, lr
	ldrh.w r3, [r12, #0x0]
	sxth r2, r2
	cmp r2, r3
	blt.n .L08020a24
	ldrh.w r3, [r12, #0x0]
	ldrh.w r4, [r12, #0x4]
	add r3, r4
	cmp r3, r2
	ble.n .L08020a24
	ldr r3, [sp, #0x1c]
	ldrh.w r5, [r12, #0x2]
	add r3, r8
	sxth r4, r3
	cmp r4, r5
	blt.n .L08020a24
	ldrh.w r3, [r12, #0x2]
	ldrh.w r5, [r12, #0x6]
	add r3, r5
	cmp r3, r4
	ble.n .L08020a24
	ldr.w r3, [r12, #0x8]
	ldrh.w r5, [r12, #0x0]
	subs r2, r2, r5
	ldrh.w r5, [r12, #0x2]
	ldrh.w r7, [r12, #0x4]
	subs r4, r4, r5
	mla r2, r4, r7, r2
	movw r4, #0xfb43
	strh.w r4, [r3, r2, lsl #0x1]
.L08020a24:
	ldr r2, [sp, #0x0]
	cbz r2, .L08020a80
	add.w r2, lr, r0
	ldrh.w r3, [r12, #0x0]
	sxth r2, r2
	cmp r2, r3
	blt.n .L08020a80
	ldrh.w r3, [r12, #0x0]
	ldrh.w r4, [r12, #0x4]
	add r3, r4
	cmp r3, r2
	ble.n .L08020a80
	ldr r3, [sp, #0x1c]
	ldrh.w r5, [r12, #0x2]
	add r3, r8
	sxth r4, r3
	cmp r4, r5
	blt.n .L08020a80
	ldrh.w r3, [r12, #0x2]
	ldrh.w r5, [r12, #0x6]
	add r3, r5
	cmp r3, r4
	ble.n .L08020a80
	ldr.w r3, [r12, #0x8]
	ldrh.w r5, [r12, #0x0]
	subs r2, r2, r5
	ldrh.w r5, [r12, #0x2]
	ldrh.w r7, [r12, #0x4]
	subs r4, r4, r5
	mla r2, r4, r7, r2
	movw r4, #0xfb43
	strh.w r4, [r3, r2, lsl #0x1]
.L08020a80:
	add.w r1, r6, r1, lsl #0x2
	cmp.w r10, #0x0
	add.w r6, r1, #0x6
	beq.w .L080204cc
	add.w r1, r8, r0
	ldrh.w r2, [r12, #0x0]
	sxth r1, r1
	cmp r1, r2
	blt.w .L080204cc
	ldrh.w r2, [r12, #0x0]
	ldrh.w r3, [r12, #0x4]
	add r2, r3
	cmp r2, r1
	ble.w .L080204cc
	ldr r2, [sp, #0x1c]
	ldrh.w r3, [r12, #0x2]
	add r2, lr
	sxth r2, r2
	cmp r2, r3
	blt.w .L080204cc
	ldrh.w r3, [r12, #0x2]
	ldrh.w r4, [r12, #0x6]
	add r3, r4
	cmp r3, r2
	ble.w .L080204cc
	ldr.w r3, [r12, #0x8]
	ldrh.w r4, [r12, #0x0]
	subs r1, r1, r4
	ldrh.w r4, [r12, #0x2]
	ldrh.w r5, [r12, #0x4]
	subs r2, r2, r4
	mla r1, r2, r5, r1
	movw r2, #0xfb43
	strh.w r2, [r3, r1, lsl #0x1]
	b.n .L080204cc
.L08020af2:
	add sp, #0x20
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}

@ ----------------------------------------------------------------------------
@ fill_triangle - fills a triangle (edge pixels included).
@ Parameters: vertices (x1,y1) = (r0,r1), (x2,y2) = (r2,r3) and (x3,y3) = ([sp,#0x50],
@ [sp,#0x54] after the push and sub) and 16-bit colour param_7 ([sp,#0x58]).
@ No return value. Bounding box = min/max of the three x and of the three y; for
@ every (px,py) in the box (y outer, x inner) the three 16-bit edge values
@ e1 = (x1-px)*(y2-y1) + (x2-x1)*(py-y1),
@ e2 = (x2-px)*(y3-y2) + (py-y2)*(x3-x2),
@ e3 = (x3-px)*(y1-y3) + (py-y3)*(x1-x3) are evaluated. The colour is written to
@ word 0x20008358 (inside the clip rectangle word 0x20008350/52/54/56) when all three are
@ <= 0 or all three are >= 0 (signed 16-bit).
@ ----------------------------------------------------------------------------
	.section .text.fill_triangle,"ax",%progbits
	.global fill_triangle
	.thumb_func
	.type fill_triangle, %function
fill_triangle:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0x2c
	ldrd r12, lr, [sp, #0x50]
	mov r8, r0
	cmp r0, r12
	mov r0, r12
	it lt
	movlt r0, r8
	cmp r0, r2
	it ge
	movge r0, r2
	cmp r8, r12
	mov r5, r12
	str r0, [sp, #0x10]
	it gt
	movgt r5, r8
	cmp r5, r2
	it le
	movle r5, r2
	cmp r1, lr
	mov r4, lr
	it lt
	movlt r4, r1
	cmp r4, r3
	mov r6, lr
	it ge
	movge r4, r3
	cmp r1, lr
	it gt
	movgt r6, r1
	sub.w r0, r2, r8
	cmp r6, r3
	it le
	movle r6, r3
	str r0, [sp, #0xc]
	subs r0, r3, r1
	strd r0, r2, [sp, #0x24]
	sub.w r0, r12, r2
	str r0, [sp, #0x8]
	str r3, [sp, #0x18]
	sub.w r7, lr, r3
	sxth r0, r6
	movw r3, #0x8350
	sxth r5, r5
	str r0, [sp, #0x4]
	mov r0, r8
	sub.w r2, r8, r12
	sub.w r9, r1, lr
	movt r3, #0x2000
	str r2, [sp, #0x0]
	str r1, [sp, #0x14]
	b.n .L08020b80
.L08020b74:
	ldr r1, [sp, #0x1c]
	adds r1, #0x1
	sxth r4, r1
	ldr r1, [sp, #0x4]
	cmp r4, r1
	bgt.n .L08020c40
.L08020b80:
	ldr r1, [sp, #0x14]
	ldr r2, [sp, #0xc]
	subs r1, r4, r1
	muls r1, r2
	ldr r2, [sp, #0x18]
	ldr.w r12, [sp, #0x10]
	subs r6, r4, r2
	ldr r2, [sp, #0x8]
	str r4, [sp, #0x1c]
	mul r10, r6, r2
	ldr r2, [sp, #0x54]
	subs r6, r4, r2
	ldr r2, [sp, #0x0]
	mul r11, r6, r2
	sxth r2, r4
	str r2, [sp, #0x20]
	b.n .L08020bb4
.L08020ba8:
	add.w r2, r12, #0x1
	sxth.w r12, r2
	cmp r12, r5
	bgt.n .L08020b74
.L08020bb4:
	ldr r2, [sp, #0x24]
	sub.w r6, r0, r12
	mla r6, r6, r2, r1
	ldr r2, [sp, #0x28]
	sxth r6, r6
	sub.w r4, r2, r12
	ldr r2, [sp, #0x50]
	mla r4, r4, r7, r10
	sub.w r2, r2, r12
	mla r2, r2, r9, r11
	sxth.w r8, r4
	sxth.w lr, r2
	cmp.w lr, #0x0
	it le
	cmple r6, #0x0
	ble.n .L08020bf4
.L08020be6:
	orr.w r2, r6, r8
	orrs.w r2, r2, lr
	bpl.n .L08020bfa
	b.n .L08020ba8
	.byte 0x00, 0xbf @ padding
.L08020bf4:
	cmp.w r8, #0x1
	bge.n .L08020be6
.L08020bfa:
	ldrh r2, [r3, #0x0]
	sxth.w r6, r12
	cmp r6, r2
	blt.n .L08020ba8
	ldrh r2, [r3, #0x0]
	ldrh r4, [r3, #0x4]
	add r2, r4
	cmp r2, r6
	ble.n .L08020ba8
	ldrh r2, [r3, #0x2]
	ldr r4, [sp, #0x20]
	cmp r4, r2
	blt.n .L08020ba8
	ldrh r2, [r3, #0x2]
	ldrh r4, [r3, #0x6]
	add r2, r4
	ldr r4, [sp, #0x20]
	cmp r2, r4
	ble.n .L08020ba8
	ldr.w lr, [r3, #0x8]
	ldrh r4, [r3, #0x0]
	sub.w r8, r6, r4
	ldrh r4, [r3, #0x2]
	ldrh r2, [r3, #0x4]
	ldr r6, [sp, #0x20]
	subs r4, r6, r4
	mla r2, r4, r2, r8
	ldr r4, [sp, #0x58]
	strh.w r4, [lr, r2, lsl #0x1]
	b.n .L08020ba8
.L08020c40:
	add sp, #0x2c
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short 0x0000 @ padding
