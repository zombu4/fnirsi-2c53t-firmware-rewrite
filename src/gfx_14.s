@ gfx_14.s - graphics helpers: rounded rectangle outline, rectangle recolour, polar to XY, copy into clip buffer, UTF-8 decode.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ draw_rounded_rect_outline - takes x=param_1 (r0), y=param_2 (r1) and corner
@ radius r=param_3 (r2); no return value.
@ Draws the outline of a rectangle x..x+0x35, y..y+0x11 in colour 0xfb43:
@ draw_circle_octants (08020470) four times at (x+0x35-r, y+r) mask 3,
@ (x+r, y+r) mask 0xc, (x+r, y+0x11-r) mask 0x30, (x+0x35-r, y+0x11-r) mask 0xc0,
@ and draw_line (0801fda0) four times: top (x+r,y)-(x+0x35-r,y), bottom at y+0x11,
@ left x from y+r to y+0x11-r, right at x+0x35.
@ ----------------------------------------------------------------------------
	.section .text.draw_rounded_rect_outline,"ax",%progbits
	.global draw_rounded_rect_outline
	.thumb_func
	.type draw_rounded_rect_outline, %function
draw_rounded_rect_outline:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0xc
	mov r9, r0			@ r9 = x
	adds r0, #0x35			@ x + 0x35 (right edge)
	mov r4, r1			@ r4 = y
	str r0, [sp, #0x8]		@ keep right edge x+0x35
	subs r0, r0, r2			@ x + 0x35 - r
	add r1, r2			@ y + r
	sxth.w r8, r1			@ r8 = y + r
	sxth.w r10, r0			@ r10 = x + 0x35 - r
	mov r0, r10
	mov r1, r8
	movs r3, #0x3			@ octant mask 3
	mov r6, r2			@ r6 = r
	bl draw_circle_octants
	add.w r0, r6, r9		@ x + r
	sxth r5, r0			@ r5 = x + r
	mov r0, r5
	mov r1, r8
	mov r2, r6
	movs r3, #0xc			@ octant mask 0xc
	bl draw_circle_octants
	add.w r11, r4, #0x11		@ y + 0x11 (bottom edge)
	sub.w r0, r11, r6		@ y + 0x11 - r
	sxth r7, r0			@ r7 = y + 0x11 - r
	mov r0, r5
	mov r1, r7
	mov r2, r6
	movs r3, #0x30			@ octant mask 0x30
	bl draw_circle_octants
	mov r0, r10
	mov r1, r7
	mov r2, r6
	movs r3, #0xc0			@ octant mask 0xc0
	bl draw_circle_octants
	movw r6, #0xfb43		@ outline colour
	mov r0, r5
	mov r1, r4
	mov r2, r10
	mov r3, r4
	str r6, [sp, #0x0]
	bl draw_line			@ top edge
	sxth.w r1, r11
	mov r0, r5
	mov r2, r10
	mov r3, r1
	str r6, [sp, #0x0]
	bl draw_line			@ bottom edge
	mov r0, r9
	mov r1, r8
	mov r2, r9
	mov r3, r7
	str r6, [sp, #0x0]
	bl draw_line			@ left edge
	ldr r0, [sp, #0x8]
	mov r1, r8
	sxth r0, r0
	mov r2, r0
	mov r3, r7
	str r6, [sp, #0x0]
	bl draw_line			@ right edge
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}

@ ----------------------------------------------------------------------------
@ recolor_rect_above_threshold - takes x,y (16-bit, r0/r1), width r2, height r3,
@ threshold colour param_5 (stack [sp,#0x30] after the push) and replacement
@ colour param_6 (stack [sp,#0x34]) (16-bit); no return value.
@ When width == 0 it only loops over the rows (4 per step) without writing.
@ Otherwise do-while over rows then columns (so at least one pixel is visited
@ when width/height are nonzero or non-positive): for each (x+dx, y+dy) inside
@ the clip rectangle word 0x20008350/52/54/56 the pixel is read from the buffer
@ pointer at 0x20008358 and replaced by param_6 when its red (>>11), green
@ ((&0x7ff)>>5) and blue (&0x1f) fields are each strictly greater than those of
@ param_5. Recolours pixels that are brighter than a threshold in all three fields.
@ ----------------------------------------------------------------------------
	.section .text.recolor_rect_above_threshold,"ax",%progbits
	.global recolor_rect_above_threshold
	.thumb_func
	.type recolor_rect_above_threshold, %function
recolor_rect_above_threshold:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #0xc
	cmp r2, #0x0			@ width == 0 ?
	str r1, [sp, #0x4]		@ save y
	beq.n .L08020dd2
	ldr r4, [sp, #0x30]		@ threshold colour
	movw r7, #0x8350
	lsr.w lr, r4, #0xb		@ threshold red
	ubfx r9, r4, #0x5, #0x6		@ threshold green
	and.w r10, r4, #0x1f		@ threshold blue
	movs r6, #0x0
	movt r7, #0x2000		@ r7 = 0x20008350 (clip rectangle)
	str r3, [sp, #0x0]		@ save height
	b.n .L08020d1c
.L08020d10:
	ldr r6, [sp, #0x8]
	ldr r3, [sp, #0x0]
	adds r6, #0x1
	sxth r1, r6
	cmp r1, r3
	bge.n .L08020dfa
.L08020d1c:
	ldr r1, [sp, #0x4]
	str r6, [sp, #0x8]
	adds r4, r6, r1
	sxth.w r11, r4			@ r11 = y + dy
	movs r4, #0x0
	b.n .L08020d34
	.byte 0x00, 0xbf		@ padding
.L08020d2c:
	adds r4, #0x1
	sxth r1, r4
	cmp r1, r2
	bge.n .L08020d10
.L08020d34:
	adds r5, r4, r0
	ldrh r6, [r7, #0x0]
	sxth r5, r5			@ r5 = x + dx
	cmp r5, r6
	blt.n .L08020d80
	ldrh r6, [r7, #0x0]
	ldrh.w r12, [r7, #0x4]
	add r6, r12
	cmp r6, r5
	ble.n .L08020d80
	ldrh r6, [r7, #0x2]
	cmp r11, r6
	blt.n .L08020d80
	ldrh.w r12, [r7, #0x2]
	ldrh r6, [r7, #0x6]
	add r6, r12
	cmp r6, r11
	ble.n .L08020d80
	ldr.w r12, [r7, #0x8]
	ldrh r6, [r7, #0x0]
	ldrh.w r8, [r7, #0x2]
	ldrh r1, [r7, #0x4]
	subs r6, r5, r6
	sub.w r3, r11, r8
	mla r1, r3, r1, r6
	ldrh.w r6, [r12, r1, lsl #0x1]	@ pixel read
	cmp.w lr, r6, lsr #0xb
	bcs.n .L08020d2c
	b.n .L08020d88
	.byte 0x00, 0xbf		@ padding
.L08020d80:
	movs r6, #0x0
	cmp.w lr, r6, lsr #0xb
	bcs.n .L08020d2c
.L08020d88:
	and.w r1, r6, #0x1f
	cmp r1, r10
	bls.n .L08020d2c
	ubfx r1, r6, #0x5, #0x6
	cmp r1, r9
	bls.n .L08020d2c
	ldrh r1, [r7, #0x0]
	cmp r5, r1
	blt.n .L08020d2c
	ldrh r1, [r7, #0x0]
	ldrh r3, [r7, #0x4]
	add r1, r3
	cmp r1, r5
	ble.n .L08020d2c
	ldrh r1, [r7, #0x2]
	cmp r11, r1
	blt.n .L08020d2c
	ldrh r1, [r7, #0x2]
	ldrh r3, [r7, #0x6]
	add r1, r3
	cmp r1, r11
	ble.n .L08020d2c
	ldr r1, [r7, #0x8]
	ldrh r3, [r7, #0x0]
	ldrh r6, [r7, #0x2]
	subs r3, r5, r3
	ldrh r5, [r7, #0x4]
	sub.w r6, r11, r6
	mla r3, r6, r5, r3
	ldr r6, [sp, #0x34]		@ replacement colour
	strh.w r6, [r1, r3, lsl #0x1]	@ pixel write
	b.n .L08020d2c
.L08020dd2:
	movs r0, #0x0
.L08020dd4:
	orr.w r1, r0, #0x1
	sxth r1, r1
	cmp r1, r3
	bge.n .L08020dfa
	orr.w r1, r0, #0x2
	sxth r1, r1
	cmp r1, r3
	bge.n .L08020dfa
	orr.w r1, r0, #0x3
	sxth r1, r1
	cmp r1, r3
	bge.n .L08020dfa
	adds r0, #0x4
	sxth r1, r0
	cmp r1, r3
	blt.n .L08020dd4
.L08020dfa:
	add sp, #0xc
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}

@ ----------------------------------------------------------------------------
@ polar_degrees_to_xy_center_160_225 - arguments by register: r0 = pointer to
@ double out_a, r1 = pointer to double out_b, d0 = radius (double, kept in d8),
@ d1 = angle in degrees (double); no return value (the decompiler parameter list
@ is wrong: set up at 0x080308ca vmov s16,s0 and 0x080308da vmov r0,r1,d1).
@ Angle: 0804577c(angle, 3.14159... = 0x400921fb60000000) then
@ 08045124(.., 180.0 = 0x4066800000000000) gives radians, 08044f48 converts to
@ float, times 0.15915494 (1/(2*pi)) gives turns t.
@ out_a: table phase t + 0.25, f = phase - floor (floor by truncation minus 1
@ when negative), index i = (int)(f*512), if (i >> 9) != 0 then i = 0 and f*512
@ reduced by 512, fraction a = f*512 - i, value (1-a)*T[i] + a*T[i+1] with T =
@ float table at 0x0806e670 (T[i] = sin(2*pi*i/512), 512 entries plus closing 0),
@ converted by 08045d70 to double, multiplied by the radius with 0804577c, plus
@ 160.0 (0x4064000000000000) with 08044fac, stored to *r0.
@ out_b: same interpolation with phase t (no 0.25), multiplied by the radius,
@ plus 225.0 (0x406c200000000000), stored to *r1.
@ So out_a = radius*cos(angle)+160 and out_b = radius*sin(angle)+225 (cos as
@ sine of phase + quarter turn).
@ ----------------------------------------------------------------------------
	.section .text.polar_degrees_to_xy_center_160_225,"ax",%progbits
	.global polar_degrees_to_xy_center_160_225
	.thumb_func
	.type polar_degrees_to_xy_center_160_225, %function
polar_degrees_to_xy_center_160_225:
	push.w {r4, r5, r6, r7, r8, r9, lr}
	sub sp, #0x4
	vpush {d8, d9, d10, d11, d12}
	vmov.f32 s16, s0		@ radius low word kept in d8
	vmov.f32 s17, s1		@ radius high word
	vldr d0, .L08030a40		@ pi (0x400921fb60000000)
	mov r8, r1			@ r8 = out_b
	mov r9, r0			@ r9 = out_a
	vmov r0, r1, d1			@ angle in degrees
	vmov r2, r3, d0
	bl double_mul
	vldr d0, .L08030a48		@ 180.0
	vmov r2, r3, d0
	bl double_div
	bl double_to_float
	vldr s0, .L08030a60		@ 1/(2*pi)
	vmov s2, r0
	vmul.f32 s18, s2, s0		@ s18 = turns t
	vmov.f32 s0, #0.25
	vadd.f32 s0, s18, s0		@ phase t + 0.25
	vcvt.s32.f32 s2, s0
	vmov r0, s2
	vcmp.f32 s0, #0
	vmrs APSR_nzcv, fpscr
	it lt
	sublt r0, #0x1			@ floor correction for negative phase
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vldr s20, .L08030a64		@ 512.0
	vsub.f32 s0, s0, s2
	vmul.f32 s0, s0, s20
	vcvt.s32.f32 s2, s0
	vmov r0, s2
	vldr s22, .L08030a68		@ -512.0
	movs r4, #0x0
	movw r5, #:lower16:d_0806e670
	cmp.w r4, r0, lsr #0x9
	it ne
	movne r0, #0x0
	movt r5, #:upper16:d_0806e670
	vmov s2, r0
	add.w r1, r5, r0, lsl #0x2
	vadd.f32 s4, s0, s22
	it ne
	vmovne.f32 s0, s4
	vcvt.f32.u32 s2, s2
	vsub.f32 s0, s0, s2
	vldr s2, [r1]
	vldr s4, [r1, #0x4]
	vmov.f32 s24, #1.0
	vsub.f32 s6, s24, s0
	vmul.f32 s2, s6, s2
	vmul.f32 s0, s0, s4
	vadd.f32 s0, s2, s0
	vmov r0, s0
	bl float_to_double
	vmov r7, r6, d8
	mov r2, r7
	mov r3, r6
	bl double_mul
	vldr d0, .L08030a50		@ 160.0
	vmov r2, r3, d0
	bl double_add
	vmov d0, r0, r1
	vcmp.f32 s18, #0
	vstr d0, [r9]			@ *out_a
	vcvt.s32.f32 s0, s18
	vmov r0, s0
	vmrs APSR_nzcv, fpscr
	it lt
	sublt r0, #0x1
	vmov s0, r0
	vcvt.f32.s32 s0, s0
	vsub.f32 s0, s18, s0
	vmul.f32 s0, s0, s20
	vcvt.s32.f32 s2, s0
	vmov r0, s2
	vadd.f32 s2, s0, s22
	cmp.w r4, r0, lsr #0x9
	itt ne
	movne r0, #0x0
	vmovne.f32 s0, s2
	vmov s2, r0
	add.w r1, r5, r0, lsl #0x2
	vcvt.f32.u32 s2, s2
	vsub.f32 s0, s0, s2
	vldr s2, [r1]
	vldr s4, [r1, #0x4]
	vsub.f32 s6, s24, s0
	vmul.f32 s2, s6, s2
	vmul.f32 s0, s0, s4
	vadd.f32 s0, s2, s0
	vmov r0, s0
	bl float_to_double
	mov r2, r7
	mov r3, r6
	bl double_mul
	vldr d0, .L08030a58		@ 225.0
	vmov r2, r3, d0
	bl double_add
	vmov d0, r0, r1
	vstr d0, [r8]			@ *out_b
	vpop {d8, d9, d10, d11, d12}
	add sp, #0x4
	pop.w {r4, r5, r6, r7, r8, r9, pc}
.L08030a40:
	.word 0x60000000, 0x400921fb	@ double 3.14159... (0x400921FB60000000)
.L08030a48:
	.word 0x00000000, 0x40668000	@ double 180.0
.L08030a50:
	.word 0x00000000, 0x40640000	@ double 160.0
.L08030a58:
	.word 0x00000000, 0x406c2000	@ double 225.0
.L08030a60:
	.word 0x3e22f983		@ float 0.15915494 (1/(2*pi))
.L08030a64:
	.word 0x44000000		@ float 512.0
.L08030a68:
	.word 0xc4000000		@ float -512.0
	.word 0x00000000		@ padding

@ ----------------------------------------------------------------------------
@ copy_rect_into_clip_buffer - params r0=x0, r1=y0, r2=width, r3=height, stack
@ param_5 = pointer to 16-bit source pixels (at [sp,#0x24] after the push);
@ no return value.
@ Computes x1=(x0+width-1)&0xffff and y1=(y0+height-1)&0xffff; if y1<y0
@ (unsigned) nothing is done; for each y from y0..y1 and x from x0..x1 (x and y
@ taken as signed 16-bit) it stores the next source halfword (source index
@ advances for every pixel, clipped or not, row stride = width) at buffer
@ pointer word 0x20008358 + ((y-clipY)*clipW+(x-clipX))*2 when x is in
@ [clipX,clipX+clipW) and y in [clipY,clipY+clipH), where clipX=ushort
@ 0x20008350, clipY=ushort 0x20008352, clipW=ushort 0x20008354, clipH=ushort
@ 0x20008356; if x1<x0 only a bounds loop without stores runs.
@ ----------------------------------------------------------------------------
	.section .text.copy_rect_into_clip_buffer,"ax",%progbits
	.global copy_rect_into_clip_buffer
	.thumb_func
	.type copy_rect_into_clip_buffer, %function
copy_rect_into_clip_buffer:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	add r3, r1
	subs r3, #0x1
	uxth.w r12, r3			@ y1
	cmp r12, r1
	bcs.n .L0803a188
.L0803a184:
	pop.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0803a188:
	add r2, r0
	subs r2, #0x1
	uxth.w r9, r2			@ x1
	cmp r9, r0
	bcc.n .L0803a1b8
	ldr.w lr, [sp, #0x24]		@ source pixel pointer
	movw r10, #0x8350
	movs r3, #0x0			@ source index
	movt r10, #0x2000		@ r10 = 0x20008350 (clip rectangle)
	b.n .L0803a1d4
.L0803a1a4:
	adds r0, r1, #0x3
	uxth r0, r0
	cmp r0, r12
	it hi
	pophi.w {r4, r5, r6, r7, r8, r9, r10, r11, pc}
	adds r1, #0x4
	uxth r0, r1
	cmp r0, r12
	bhi.n .L0803a184
.L0803a1b8:
	adds r0, r1, #0x1
	uxth r0, r0
	cmp r0, r12
	bhi.n .L0803a184
	adds r0, r1, #0x2
	uxth r0, r0
	cmp r0, r12
	bls.n .L0803a1a4
	b.n .L0803a184
	.byte 0x00, 0xbf		@ padding
.L0803a1cc:
	adds r1, #0x1
	uxth r5, r1
	cmp r5, r12
	bhi.n .L0803a184
.L0803a1d4:
	sxth.w r8, r1			@ y as signed 16-bit
	mov r6, r0
	b.n .L0803a1e8
.L0803a1dc:
	adds r6, #0x1
	uxth r2, r6
	cmp r2, r9
	add.w r3, r3, #0x1
	bhi.n .L0803a1cc
.L0803a1e8:
	ldrh.w r7, [lr, r3, lsl #0x1]	@ next source halfword
	ldrh.w r2, [r10, #0x0]
	sxth r5, r6			@ x as signed 16-bit
	cmp r5, r2
	blt.n .L0803a1dc
	ldrh.w r2, [r10, #0x0]
	ldrh.w r4, [r10, #0x4]
	add r2, r4
	cmp r2, r5
	ble.n .L0803a1dc
	ldrh.w r2, [r10, #0x2]
	cmp r8, r2
	blt.n .L0803a1dc
	ldrh.w r2, [r10, #0x2]
	ldrh.w r4, [r10, #0x6]
	add r2, r4
	cmp r2, r8
	ble.n .L0803a1dc
	ldr.w r11, [r10, #0x8]
	ldrh.w r4, [r10, #0x0]
	subs r4, r5, r4
	ldrh.w r5, [r10, #0x2]
	ldrh.w r2, [r10, #0x4]
	sub.w r5, r8, r5
	mla r2, r5, r2, r4
	strh.w r7, [r11, r2, lsl #0x1]	@ store pixel into clip buffer
	b.n .L0803a1dc
	.byte 0x00, 0x00		@ padding

@ ----------------------------------------------------------------------------
@ decode_utf8_char - params r0=byte string pointer, r1=pointer to index (or 0
@ to use a local index starting at 0).
@ Decodes one UTF-8 sequence at string[index]: 1 byte if <0x80 (a 0 byte also
@ returns 0 with the index advanced by 1), 2 bytes (0xC0 lead, mask 0xe0), 3
@ bytes (0xE0 lead, mask 0xf0), 4 bytes (0xF0 lead, mask 0xf8) with
@ continuation bytes checked as (b&0xc0)==0x80. Stores the advanced index to *r1
@ (or the local) and returns the code point; returns 0 on an invalid sequence
@ (the stored index then equals the offset of the first byte that is not a valid
@ continuation, or lead offset + 1 for a lead byte that is none of
@ 0xxxxxxx/110xxxxx/1110xxxx/11110xxx; the bad byte is not consumed). The code
@ checks only the bit patterns, no overlong, surrogate or range check.
@ ----------------------------------------------------------------------------
	.section .text.decode_utf8_char,"ax",%progbits
	.global decode_utf8_char
	.thumb_func
	.type decode_utf8_char, %function
decode_utf8_char:
	push {r4, lr}
	sub sp, #0x4
	movs r2, #0x0
	str r2, [sp, #0x0]		@ local index = 0
	mov r2, sp
	cmp r1, #0x0
	it ne
	movne r2, r1			@ use caller's index pointer
	ldr r4, [r2, #0x0]		@ r4 = index
	mov r1, r0
	ldrb r0, [r0, r4]		@ lead byte
	lsls r3, r0, #0x18
	bmi.n .L0803a42a
	adds r1, r4, #0x1
	b.n .L0803a4de
.L0803a42a:
	and.w r3, r0, #0xe0
	cmp r3, #0xc0
	bne.n .L0803a450
	adds r3, r4, #0x1
	str r3, [r2, #0x0]
	ldrb r1, [r1, r3]
	and.w r3, r1, #0xc0
	cmp r3, #0x80
	bne.n .L0803a4e4
	and.w r0, r0, #0x1f
	and.w r1, r1, #0x3f
	orr.w r0, r1, r0, lsl #0x6
	adds r1, r4, #0x2
	b.n .L0803a4de
.L0803a450:
	and.w r3, r0, #0xf0
	cmp r3, #0xe0
	bne.n .L0803a488
	adds r3, r4, #0x1
	str r3, [r2, #0x0]
	ldrb.w r12, [r1, r3]
	and.w r3, r12, #0xc0
	cmp r3, #0x80
	bne.n .L0803a4e4
	adds r3, r4, #0x2
	str r3, [r2, #0x0]
	ldrb r1, [r1, r3]
	and.w r3, r1, #0xc0
	cmp r3, #0x80
	bne.n .L0803a4e4
	lsls r0, r0, #0xc
	uxth r0, r0
	bfi r0, r12, #0x6, #0x6
	and.w r1, r1, #0x3f
	add r0, r1
	adds r1, r4, #0x3
	b.n .L0803a4de
.L0803a488:
	and.w r3, r0, #0xf8
	add.w r12, r4, #0x1
	cmp r3, #0xf0
	str.w r12, [r2, #0x0]
	bne.n .L0803a4e4
	ldrb.w r12, [r1, r12]
	and.w r3, r12, #0xc0
	cmp r3, #0x80
	bne.n .L0803a4e4
	adds r3, r4, #0x2
	str r3, [r2, #0x0]
	ldrb.w lr, [r1, r3]
	and.w r3, lr, #0xc0
	cmp r3, #0x80
	bne.n .L0803a4e4
	adds r3, r4, #0x3
	str r3, [r2, #0x0]
	ldrb r1, [r1, r3]
	and.w r3, r1, #0xc0
	cmp r3, #0x80
	bne.n .L0803a4e4
	mov.w r3, #0x1c0000
	and.w r0, r3, r0, lsl #0x12
	bfi r0, r12, #0xc, #0x6
	and.w r3, lr, #0x3f
	orr.w r0, r0, r3, lsl #0x6
	and.w r1, r1, #0x3f
	add r0, r1
	adds r1, r4, #0x4
.L0803a4de:
	str r1, [r2, #0x0]		@ store advanced index
	add sp, #0x4
	pop {r4, pc}
.L0803a4e4:
	movs r0, #0x0			@ invalid sequence: return 0
	add sp, #0x4
	pop {r4, pc}
	.byte 0x00, 0x00		@ padding
