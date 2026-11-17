@ waveform_84.s - draw_arc_gauge (100-degree arc gauge with ticks, scale labels and value text) and draw_seven_icon_row (row of seven icons).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ draw_arc_gauge - draws a 100-degree arc gauge with 21 ticks, 11 numeric scale
@ labels, the text of the float at 0x20001028 and a unit text.
@ No parameters (r0 and r1 are overwritten at 08015c84/08015c96 before being
@ read), no return value.
@ Formats the float at 0x20001028 with "%.4f" (08045d70 float to double,
@ 080073b4) into 0x20008360 and runs a character scan of that text
@ (08015cb6..08015ce6) whose result is not used afterwards.
@ v=|float 0x20001028| is divided by 10.0 repeatedly (unrolled 4x,
@ 08015d08..08015d3e) while v > 20.0, then multiplied by 10.0 once when v < 2.0.
@ Calls 0801faf0(5*v+220.0, 320.0, 0x6bb0) and 0801faf0(220.0, 5*v+220.0, 0x55f):
@ two arcs from 220 to 320 degrees (0801faf0 draws an arc of radius 190 around
@ (160,225)).
@ n=(uint)v+1 (vcvt.u32.f32). 080308c0(r0=pointer A, r1=pointer B, s0/s1=radius
@ double, s2/s3=angle in degrees double) stores to A the double
@ 160.0 + radius*s(angle+0.25 turn) and to B the double 225.0 + radius*s(angle),
@ where s interpolates linearly in the 512-float table at 0x0806e670 (entry 0 =
@ 0.0, 128 = 1.0, 256 = 0.0, 384 = -1.0) and the angle in turns is angle*pi/180
@ (08030a40, 08030a48) converted to float and multiplied by the float 0x3e22f983
@ at 08030a60 (the quarter-turn shift is at 08030902..08030906; stores vstr at
@ 080309ae to [r9] and 08030a32 to [r8]), so A receives x and B receives y.
@ Tick k=0..20 (angle 220+5*k): 080308c0 is called twice, first with radius
@ 189.0 and A=sp+0x30, B=sp+0x28 (x1, y1), then with radius 184.0 and A=sp+0x20,
@ B=sp+0x18 (x2, y2) (08015df4, 08015e0c); all four doubles are converted to
@ float with 08044f48; dx=x2-x1, dy=y2-y1, so the tick is a short line from the
@ radius-189 point to the radius-184 point, drawn by an error accumulator that
@ starts at (x1,y1), adds sign(dx) to x and sign(dy) to y when the accumulators
@ exceed m=max(|dx|,|dy|), and plots floor(m+1)+1 points with
@ 0801f964(x,y,colour) (s0=x, s1=y; loop 08015ecc..08015f30, count test at
@ 08015f28 s29=m+1 >= r6 after the increment): ticks k < n use colour 0x55f,
@ ticks n..20 use 0x6bb0 (loops at 08015da6 and 08015f34).
@ Labels: for idx=0..10 formats "%d" of 2*idx into 0x20008360 and draws it with
@ 0800f154(x,y,12,12, 0x20008360, font 0x20001084, colour, flag 1) at
@ (x-(idx-5)-6, y) truncated to int, with x the double at sp+0x30 (pointer A)
@ and y the double at sp+0x28 (pointer B) of 080308c0(radius 184.0, angle
@ 220+10*idx) (A=sp+0x30 and B=sp+0x28 passed at 08016146/08016148 and
@ 080161fe/08016200; 0800f154 gets r0=x, r1=y) (08045b94 subtract, 08044fac add
@ -6.0, 08045450 to int); first loop idx=((uint)v>>1)+1..10 uses colour 0x6bb0
@ (skipped when ((uint)v>>1)+1 > 10, loop at 08016106), second loop
@ idx=0..((uint)v>>1) uses colour 0x55f (080161c6).
@ Then 0800f154(0x82,0x30,0x3c,0x19, text "HOLD" (literal at 0x080163b0), font
@ 0x20001174, colour 0x55f when byte 0x20001034 != 0 else 0x18c3, flag 1).
@ When byte 0x20001036 == 2 and (byte 0x2000102f == 1 or byte 0x2000102d == 1):
@ 0800f154(0x82,0x44,0x3c,0x10, "%d Hz" of halfword 0x2000103a into 0x20008360,
@ font 0x200010e4, colour 0xffff, flag 1).
@ Then 0800f154(0x28,0x50,0xf0,0x3f, text, font 0x200011d4, colour 0x55f, flag
@ 1): text = word at 0x080163c0 + (byte 0x2000102d - 1)*4 ("AUTO", ".OL", " ",
@ "CAL", "PAS", "Er1", "Er2", "Er3", "ErC") when byte 0x2000102d != 0; otherwise
@ when signed byte 0x2000102c <= 4 (unsigned compare) the float 0x20001028
@ formatted into 0x20008360 with the format word at 0x080163e4 + idx*4
@ ("%.0f".. "%.4f"); otherwise 0x20008360 is drawn unchanged.
@ When byte 0x20001030 != 0xff: 0800f154(0x102,0x70,0x34,0x1c, word at
@ 0x0804c404 + byte(0x20001030)*4 ("mV", "V", ...), font 0x200011a4, colour
@ 0x55f, flag 1).
@ ----------------------------------------------------------------------------
	.section .text.draw_arc_gauge,"ax",%progbits
	.p2align 2
	.global draw_arc_gauge
	.thumb_func
	.type draw_arc_gauge, %function
draw_arc_gauge:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #4
	vpush	{d8, d9, d10, d11, d12, d13, d14, d15}
	sub	sp, #0x38
	movw	r5, #0xf8
	movt	r5, #0x2000
	ldr.w	r0, [r5, #0xf30]
	bl	float_to_double
	movw	r8, #0x8360
	mov	r3, r1
	movt	r8, #0x2000
	movw	r1, #:lower16:d_080bc340
	mov	r2, r0
	movt	r1, #:upper16:d_080bc340
	mov	r0, r8
	bl	format_to_buffer_080073b4
	ldrb.w	r0, [r8, #0]
	movs	r1, #0
	b.n	.L08015cba
	.short	0xbf00			@ padding
.L08015cb0:
	subs	r3, #1
.L08015cb2:
	cmp	r3, r2
	add.w	r1, r1, #1
	ble.n	.L08015ce8
.L08015cba:
	cbz	r0, .L08015ce8
	uxtb	r2, r1
	movs	r3, #2
.L08015cc0:
	add.w	r7, r8, r3
	ldrb.w	r6, [r7, #-1]
	cmp	r6, #0
	beq.n	.L08015cb0
	ldrb.w	r6, [r8, r3]
	cmp	r6, #0
	beq.n	.L08015cb2
	ldrb	r6, [r7, #1]
	cbz	r6, .L08015ce4
	ldrb	r7, [r7, #2]
	adds	r3, #4
	cmp	r7, #0
	bne.n	.L08015cc0
	subs	r3, #2
	b.n	.L08015cb2
.L08015ce4:
	adds	r3, #1
	b.n	.L08015cb2
.L08015ce8:
	add.w	r0, r5, #0xf30
	vldr	s0, [r0]
	vabs.f32	s20, s0
	vmov.f32	s0, #20.0
	vcmp.f32	s20, s0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08015d40
	vmov.f32	s2, #10.0
	nop
.L08015d08:
	vdiv.f32	s20, s20, s2
	vcmp.f32	s20, s0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08015d40
	vdiv.f32	s20, s20, s2
	vcmp.f32	s20, s0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08015d40
	vdiv.f32	s20, s20, s2
	vcmp.f32	s20, s0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08015d40
	vdiv.f32	s20, s20, s2
	vcmp.f32	s20, s0
	vmrs	APSR_nzcv, fpscr
	bgt.n	.L08015d08
.L08015d40:
	vmov.f32	s0, #10.0
	vmov.f32	s4, #2.0
	vmul.f32	s2, s20, s0
	vcmp.f32	s20, s4
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s20, s2
	vmul.f32	s0, s20, s0
	vmov.f32	s2, #0.5
	vldr	s16, .L08015f60
	vmul.f32	s0, s0, s2
	vadd.f32	s18, s0, s16
	vldr	s1, .L08015f64
	vmov.f32	s0, s18
	movw	r0, #0x6bb0
	bl	draw_arc_degrees
	vmov.f32	s0, s16
	vmov.f32	s1, s18
	movw	r0, #0x55f
	bl	draw_arc_degrees
	vcvt.u32.f32	s0, s20
	vmov	r0, s0
	adds	r7, r0, #1
	uxtb.w	r10, r7
	cmp.w	r10, #0x14
	str	r0, [sp, #0x14]
	bhi.w	.L08015f34
	vldr	d8, .L08015f68
	vldr	d9, .L08015f70
	vldr	s28, .L08015f78
	add	r4, sp, #0x30
	add.w	r9, sp, #0x28
	add.w	r11, sp, #0x20
	add	r5, sp, #0x18
	vmov.f32	s24, #1.0
	b.n	.L08015dd2
.L08015dc4:
	add.w	r10, r10, #1
	uxtb.w	r0, r10
	cmp	r0, #0x15
	beq.w	.L08015f34
.L08015dd2:
	add.w	r0, r10, r10, lsl #2
	adds	r0, #0xdc
	bl	i32_to_double
	vmov	d10, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s2, s20
	vmov.f32	s1, s17
	vmov.f32	s3, s21
	mov	r0, r4
	mov	r1, r9
	bl	polar_degrees_to_xy_center_160_225
	vmov.f32	s0, s18
	vmov.f32	s2, s20
	vmov.f32	s1, s19
	vmov.f32	s3, s21
	mov	r0, r11
	mov	r1, r5
	bl	polar_degrees_to_xy_center_160_225
	ldrd	r0, r1, [sp, #0x30]
	bl	double_to_float
	ldrd	r2, r1, [sp, #0x28]
	vmov	s20, r0
	mov	r0, r2
	bl	double_to_float
	ldrd	r2, r1, [sp, #0x20]
	mov	r6, r0
	mov	r0, r2
	bl	double_to_float
	ldrd	r2, r1, [sp, #0x18]
	vmov	s22, r0
	mov	r0, r2
	bl	double_to_float
	vsub.f32	s30, s22, s20
	vcmp.f32	s30, #0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08015e54
	vmov.f32	s21, s24
	b.n	.L08015e6a
.L08015e54:
	vcmp.f32	s30, #0
	vmrs	APSR_nzcv, fpscr
	itte	ne
	vnegne.f32	s30, s30
	vmovne.f32	s21, #-1.0
	vmoveq.f32	s21, s28
.L08015e6a:
	vmov	s22, r6
	vmov	s0, r0
	vsub.f32	s23, s0, s22
	vcmp.f32	s23, #0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08015e88
	vmov.f32	s25, s24
	b.n	.L08015e9e
	.short	0xbf00			@ padding
.L08015e88:
	vcmp.f32	s23, #0
	vmrs	APSR_nzcv, fpscr
	itte	ne
	vnegne.f32	s23, s23
	vmovne.f32	s25, #-1.0
	vmoveq.f32	s25, s28
.L08015e9e:
	vcmp.f32	s30, s23
	vmov.f32	s27, s23
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s27, s30
	vadd.f32	s29, s27, s24
	vcmp.f32	s29, #0
	vmrs	APSR_nzcv, fpscr
	blt.w	.L08015dc4
	movs	r6, #0
	vmov.f32	s31, s28
	vmov.f32	s26, s28
	nop
.L08015ecc:
	vmov.f32	s0, s20
	vmov.f32	s1, s22
	movw	r0, #0x6bb0
	bl	blend_subpixel_point
	vadd.f32	s26, s30, s26
	vcmp.f32	s26, s27
	vsub.f32	s0, s26, s27
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s26, s0
	vadd.f32	s0, s21, s20
	vadd.f32	s31, s23, s31
	it	gt
	vmovgt.f32	s20, s0
	vcmp.f32	s31, s27
	vsub.f32	s0, s31, s27
	adds	r6, #1
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s31, s0
	vadd.f32	s0, s25, s22
	uxth	r0, r6
	it	gt
	vmovgt.f32	s22, s0
	vmov	s0, r0
	vcvt.f32.u32	s0, s0
	vcmp.f32	s29, s0
	vmrs	APSR_nzcv, fpscr
	bge.n	.L08015ecc
	b.n	.L08015dc4
.L08015f34:
	cmp	r7, #0
	beq.w	.L080160fe
	vldr	d8, .L08015f68
	vldr	d9, .L08015f70
	vldr	s28, .L08015f78
	movs	r0, #0
	add	r4, sp, #0x30
	add.w	r9, sp, #0x28
	add.w	r11, sp, #0x20
	add.w	r10, sp, #0x18
	vmov.f32	s24, #1.0
	movs	r5, #0
	b.n	.L08015f86
	.short	0xbf00			@ padding
.L08015f60:
	.word	0x435c0000		@ 220.0
.L08015f64:
	.word	0x43a00000		@ 320.0
.L08015f68:
	.word	0x00000000		@ double 189.0 (low word)
	.word	0x4067a000		@ double 189.0 (high word)
.L08015f70:
	.word	0x00000000		@ double 184.0 (low word)
	.word	0x40670000		@ double 184.0 (high word)
.L08015f78:
	.word	0x00000000		@ float 0.0
.L08015f7c:
	adds	r5, #1
	uxtb	r0, r5
	cmp	r7, r0
	bls.w	.L080160e8
.L08015f86:
	add.w	r0, r0, r0, lsl #2
	adds	r0, #0xdc
	bl	i32_to_double
	vmov	d10, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s2, s20
	vmov.f32	s1, s17
	vmov.f32	s3, s21
	mov	r0, r4
	mov	r1, r9
	bl	polar_degrees_to_xy_center_160_225
	vmov.f32	s0, s18
	vmov.f32	s2, s20
	vmov.f32	s1, s19
	vmov.f32	s3, s21
	mov	r0, r11
	mov	r1, r10
	bl	polar_degrees_to_xy_center_160_225
	ldrd	r0, r1, [sp, #0x30]
	bl	double_to_float
	ldrd	r2, r1, [sp, #0x28]
	vmov	s20, r0
	mov	r0, r2
	bl	double_to_float
	ldrd	r2, r1, [sp, #0x20]
	mov	r6, r0
	mov	r0, r2
	bl	double_to_float
	ldrd	r2, r1, [sp, #0x18]
	vmov	s22, r0
	mov	r0, r2
	bl	double_to_float
	vsub.f32	s30, s22, s20
	vcmp.f32	s30, #0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L08016008
	vmov.f32	s21, s24
	b.n	.L0801601e
.L08016008:
	vcmp.f32	s30, #0
	vmrs	APSR_nzcv, fpscr
	itte	ne
	vnegne.f32	s30, s30
	vmovne.f32	s21, #-1.0
	vmoveq.f32	s21, s28
.L0801601e:
	vmov	s22, r6
	vmov	s0, r0
	vsub.f32	s23, s0, s22
	vcmp.f32	s23, #0
	vmrs	APSR_nzcv, fpscr
	ble.n	.L0801603c
	vmov.f32	s25, s24
	b.n	.L08016052
	.short	0xbf00			@ padding
.L0801603c:
	vcmp.f32	s23, #0
	vmrs	APSR_nzcv, fpscr
	itte	ne
	vnegne.f32	s23, s23
	vmovne.f32	s25, #-1.0
	vmoveq.f32	s25, s28
.L08016052:
	vcmp.f32	s30, s23
	vmov.f32	s27, s23
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s27, s30
	vadd.f32	s29, s27, s24
	vcmp.f32	s29, #0
	vmrs	APSR_nzcv, fpscr
	blt.w	.L08015f7c
	movs	r6, #0
	vmov.f32	s31, s28
	vmov.f32	s26, s28
	nop
.L08016080:
	vmov.f32	s0, s20
	vmov.f32	s1, s22
	movw	r0, #0x55f
	bl	blend_subpixel_point
	vadd.f32	s26, s30, s26
	vcmp.f32	s26, s27
	vsub.f32	s0, s26, s27
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s26, s0
	vadd.f32	s0, s21, s20
	vadd.f32	s31, s23, s31
	it	gt
	vmovgt.f32	s20, s0
	vcmp.f32	s31, s27
	vsub.f32	s0, s31, s27
	adds	r6, #1
	vmrs	APSR_nzcv, fpscr
	it	gt
	vmovgt.f32	s31, s0
	vadd.f32	s0, s25, s22
	uxth	r0, r6
	it	gt
	vmovgt.f32	s22, s0
	vmov	s0, r0
	vcvt.f32.u32	s0, s0
	vcmp.f32	s29, s0
	vmrs	APSR_nzcv, fpscr
	bge.n	.L08016080
	b.n	.L08015f7c
.L080160e8:
	ldr	r1, [sp, #0x14]
	movs	r0, #1
	add.w	r10, r0, r1, lsr #1
	uxtb.w	r0, r10
	cmp	r0, #0xa
	lsr.w	r11, r1, #1
	bls.n	.L08016106
	b.n	.L080161c6
.L080160fe:
	mvn	r11, #0x80000000
	mov.w	r10, #0
.L08016106:
	uxtb.w	r0, r10
	mvn	r1, #4
	lsls	r6, r0, #1
	lsls	r0, r0, #2
	vldr	d0, .L080163a8
	uxtab	r5, r1, r10
	uxtab	r0, r0, r10
	movs	r1, #0xdc
	vldr	d8, .L080163a0
	str.w	r11, [sp, #0x10]
	add.w	r7, r1, r0, lsl #1
	vmov	r11, r0, d0
	movs	r4, #1
	str	r0, [sp, #0x14]
.L08016134:
	mov	r0, r7
	bl	i32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	add	r0, sp, #0x30
	add	r1, sp, #0x28
	bl	polar_degrees_to_xy_center_160_225
	movw	r1, #:lower16:d_080bc040
	mov	r0, r8
	movt	r1, #:upper16:d_080bc040
	mov	r2, r6
	bl	format_to_buffer_080073b4
	vldr	d9, [sp, #0x30]
	mov	r0, r5
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_sub
	ldr	r3, [sp, #0x14]
	mov	r2, r11
	bl	double_add
	bl	double_to_i32
	vldr	d0, [sp, #0x28]
	mov	r9, r0
	vmov	r0, r1, d0
	bl	double_to_i32
	mov	r1, r0
	movw	r0, #0x1084
	movt	r0, #0x2000
	str	r0, [sp, #4]
	movw	r0, #0x6bb0
	str	r0, [sp, #8]
	mov	r0, r9
	movs	r2, #0xc
	movs	r3, #0xc
	str.w	r8, [sp]
	str	r4, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	uxtb.w	r0, r10
	add.w	r10, r10, #1
	adds	r5, #1
	adds	r6, #2
	adds	r7, #0xa
	cmp	r0, #0xa
	bcc.n	.L08016134
	ldr.w	r11, [sp, #0x10]
.L080161c6:
	vldr	d0, .L080163a8
	vldr	d8, .L080163a0
	movw	r10, #0x1084
	movs	r7, #0
	vmov	r5, r6, d0
	movw	r4, #0x55f
	mov.w	r9, #0
	movt	r10, #0x2000
.L080161e4:
	add.w	r0, r7, r7, lsl #2
	movs	r1, #0xdc
	add.w	r0, r1, r0, lsl #1
	bl	i32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	add	r0, sp, #0x30
	add	r1, sp, #0x28
	bl	polar_degrees_to_xy_center_160_225
	movw	r1, #:lower16:d_080bc040
	lsls	r2, r7, #1
	mov	r0, r8
	movt	r1, #:upper16:d_080bc040
	bl	format_to_buffer_080073b4
	vldr	d9, [sp, #0x30]
	subs	r0, r7, #5
	bl	i32_to_double
	mov	r2, r0
	mov	r3, r1
	vmov	r0, r1, d9
	bl	double_sub
	mov	r2, r5
	mov	r3, r6
	bl	double_add
	bl	double_to_i32
	vldr	d0, [sp, #0x28]
	mov	r7, r0
	vmov	r0, r1, d0
	bl	double_to_i32
	mov	r1, r0
	mov	r0, r7
	movs	r2, #0xc
	movs	r3, #0xc
	movs	r7, #1
	strd	r8, r10, [sp]
	str	r4, [sp, #8]
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	add.w	r9, r9, #1
	uxtb.w	r7, r9
	cmp	r11, r7
	bcs.n	.L080161e4
	movw	r5, #0xf8
	movt	r5, #0x2000
	ldrb.w	r0, [r5, #0xf3c]
	movw	r1, #0x55f
	cmp	r0, #0
	movw	r0, #0x1174
	it	eq
	movweq	r1, #0x18c3
	movt	r0, #0x2000
	adr	r2, .L080163b0
	movs	r7, #1
	strd	r2, r0, [sp]
	str	r1, [sp, #8]
	movs	r0, #0x82
	movs	r1, #0x30
	movs	r2, #0x3c
	movs	r3, #0x19
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb.w	r0, [r5, #0xf36]
	cmp	r0, #2
	bne.n	.L080162f6
	ldrb.w	r0, [r5, #0xf2f]
	ldrb.w	r1, [r5, #0xf2d]
	eor.w	r0, r0, #1
	orrs	r0, r1
	subs	r1, #1
	clz	r0, r0
	clz	r1, r1
	lsrs	r0, r0, #5
	lsrs	r1, r1, #5
	orrs	r0, r1
	beq.n	.L080162f6
	ldrh.w	r2, [r5, #0xf3a]
	adr	r1, .L080163b8
	mov	r0, r8
	bl	format_to_buffer_080073b4
	movw	r1, #0x10e4
	movw	r0, #0xffff
	movt	r1, #0x2000
	movs	r7, #1
	strd	r8, r1, [sp]
	str	r0, [sp, #8]
	movs	r0, #0x82
	movs	r1, #0x44
	movs	r2, #0x3c
	movs	r3, #0x10
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L080162f6:
	ldrb.w	r0, [r5, #0xf35]
	cbz	r0, .L08016308
	adr	r1, .L080163c0
	add.w	r0, r1, r0, lsl #2
	ldr.w	r4, [r0, #-4]
	b.n	.L0801633c
.L08016308:
	ldrsb.w	r0, [r5, #0xf34]
	cmp	r0, #4
	bhi.n	.L08016334
	adr	r1, .L080163e4
	ldr.w	r6, [r1, r0, lsl #2]
	ldr.w	r0, [r5, #0xf30]
	bl	float_to_double
	movw	r4, #0x8360
	movt	r4, #0x2000
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r6
	bl	format_to_buffer_080073b4
	b.n	.L0801633c
.L08016334:
	movw	r4, #0x8360
	movt	r4, #0x2000
.L0801633c:
	movw	r0, #0x11d4
	movt	r0, #0x2000
	movs	r7, #1
	movw	r6, #0x55f
	strd	r4, r0, [sp]
	movs	r0, #0x28
	movs	r1, #0x50
	movs	r2, #0xf0
	movs	r3, #0x3f
	str	r6, [sp, #8]
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	ldrb.w	r0, [r5, #0xf38]
	cmp	r0, #0xff
	beq.n	.L0801638e
	movw	r1, #:lower16:d_0804c404
	movt	r1, #:upper16:d_0804c404
	ldr.w	r0, [r1, r0, lsl #2]
	movw	r1, #0x11a4
	movt	r1, #0x2000
	stm.w	sp, {r0, r1, r6}
	mov.w	r0, #0x102
	movs	r1, #0x70
	movs	r2, #0x34
	movs	r3, #0x1c
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
.L0801638e:
	add	sp, #0x38
	vpop	{d8, d9, d10, d11, d12, d13, d14, d15}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short	0xbf00			@ padding
	.short	0xbf00			@ padding
	.short	0xbf00			@ padding
.L080163a0:
	.word	0x00000000		@ double 184.0 (low word)
	.word	0x40670000		@ double 184.0 (high word)
.L080163a8:
	.word	0x00000000		@ double -6.0 (low word)
	.word	0xc0180000		@ double -6.0 (high word)
.L080163b0:
	.asciz	"HOLD"
	.byte	0x00, 0x00, 0x00	@ padding
.L080163b8:
	.asciz	"%d Hz"
	.short	0x0000			@ padding
.L080163c0:
	.word	0x080bbc60		@ "AUTO" text address
	.word	0x080bbc48
	.word	0x080bb414
	.word	0x080bbc44
	.word	0x080bbc76
	.word	0x080bb97f
	.word	0x080bb9ea
	.word	0x080bb9ee
	.word	0x080bbc2e
.L080163e4:
	.word	0x080bc32c		@ "%.0f" format
	.word	0x080bc331
	.word	0x080bc336
	.word	0x080bc33b
	.word	0x080bc340		@ "%.4f" format

@ ----------------------------------------------------------------------------
@ draw_seven_icon_row - draws a row of seven icons in which the icon whose
@ index equals byte 0x20001025 uses the 0x81..0x87 image set and is raised by
@ 2 pixels, the others use 0x7a..0x80.
@ No parameters, no return value.
@ For k=1..7 formats "3:/System file/%d.jpg" with 080073b4 into 0x20008360 and
@ draws it with 08039f6c: if byte 0x20001025==k image 0x80+k at (x,0x96) with
@ x=10,0x35,0x60,0x8b,0xb6,0xe1,0x10c, otherwise image 0x79+k at (x,0x98) with
@ x=0xc,0x37,0x62,0x8d,0xb8,0xe3,0x10e.
@ ----------------------------------------------------------------------------
	.section .text.draw_seven_icon_row,"ax",%progbits
	.p2align 2
	.global draw_seven_icon_row
	.thumb_func
	.type draw_seven_icon_row, %function
draw_seven_icon_row:
	push	{r4, r5, r7, lr}
	movw	r5, #0xf8
	movt	r5, #0x2000
	ldrb.w	r0, [r5, #0xf2d]
	movw	r4, #0x8360
	movw	r1, #:lower16:d_080bc680+1
	movt	r4, #0x2000
	movt	r1, #:upper16:d_080bc680+1
	cmp	r0, #1
	bne.n	.L0801642a
	mov	r0, r4
	movs	r2, #0x81
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0xa
	movs	r2, #0x96
	b.n	.L08016438
.L0801642a:
	mov	r0, r4
	movs	r2, #0x7a
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0xc
	movs	r2, #0x98
.L08016438:
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r5, #0xf2d]
	movw	r4, #0x8360
	movw	r1, #:lower16:d_080bc680+1
	movt	r4, #0x2000
	movt	r1, #:upper16:d_080bc680+1
	cmp	r0, #2
	bne.n	.L08016464
	mov	r0, r4
	movs	r2, #0x82
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0x35
	movs	r2, #0x96
	b.n	.L08016472
.L08016464:
	mov	r0, r4
	movs	r2, #0x7b
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0x37
	movs	r2, #0x98
.L08016472:
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r5, #0xf2d]
	movw	r4, #0x8360
	movw	r1, #:lower16:d_080bc680+1
	movt	r4, #0x2000
	movt	r1, #:upper16:d_080bc680+1
	cmp	r0, #3
	bne.n	.L0801649e
	mov	r0, r4
	movs	r2, #0x83
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0x60
	movs	r2, #0x96
	b.n	.L080164ac
.L0801649e:
	mov	r0, r4
	movs	r2, #0x7c
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0x62
	movs	r2, #0x98
.L080164ac:
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r5, #0xf2d]
	movw	r4, #0x8360
	movw	r1, #:lower16:d_080bc680+1
	movt	r4, #0x2000
	movt	r1, #:upper16:d_080bc680+1
	cmp	r0, #4
	bne.n	.L080164d8
	mov	r0, r4
	movs	r2, #0x84
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0x8b
	movs	r2, #0x96
	b.n	.L080164e6
.L080164d8:
	mov	r0, r4
	movs	r2, #0x7d
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0x8d
	movs	r2, #0x98
.L080164e6:
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r5, #0xf2d]
	movw	r4, #0x8360
	movw	r1, #:lower16:d_080bc680+1
	movt	r4, #0x2000
	movt	r1, #:upper16:d_080bc680+1
	cmp	r0, #5
	bne.n	.L08016512
	mov	r0, r4
	movs	r2, #0x85
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0xb6
	movs	r2, #0x96
	b.n	.L08016520
.L08016512:
	mov	r0, r4
	movs	r2, #0x7e
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0xb8
	movs	r2, #0x98
.L08016520:
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r5, #0xf2d]
	movw	r4, #0x8360
	movw	r1, #:lower16:d_080bc680+1
	movt	r4, #0x2000
	movt	r1, #:upper16:d_080bc680+1
	cmp	r0, #6
	bne.n	.L0801654c
	mov	r0, r4
	movs	r2, #0x86
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0xe1
	movs	r2, #0x96
	b.n	.L0801655a
.L0801654c:
	mov	r0, r4
	movs	r2, #0x7f
	bl	format_to_buffer_080073b4
	mov	r0, r4
	movs	r1, #0xe3
	movs	r2, #0x98
.L0801655a:
	bl	decode_image_file_with_offset
	ldrb.w	r0, [r5, #0xf2d]
	movw	r4, #0x8360
	movw	r1, #:lower16:d_080bc680+1
	movt	r4, #0x2000
	movt	r1, #:upper16:d_080bc680+1
	cmp	r0, #7
	bne.n	.L0801658e
	mov	r0, r4
	movs	r2, #0x87
	bl	format_to_buffer_080073b4
	mov	r0, r4
	mov.w	r1, #0x10c
	movs	r2, #0x96
	pop.w	{r4, r5, r7, lr}
	b.w	decode_image_file_with_offset
.L0801658e:
	mov	r0, r4
	movs	r2, #0x80
	bl	format_to_buffer_080073b4
	mov	r0, r4
	mov.w	r1, #0x10e
	movs	r2, #0x98
	pop.w	{r4, r5, r7, lr}
	b.w	decode_image_file_with_offset
	.short	0x0000			@ padding
