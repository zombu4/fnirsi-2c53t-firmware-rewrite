@ math_rt_29.s - double_pow: the C library pow(x, y) for IEEE-754 doubles (soft double helpers).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ double_pow - computes x raised to the power y (double precision).
@ No C params in registers as such: x (d0) and y (d1) are saved by vpush {d0-d1}
@ (0x080438e4) and read from the stack: [sp+0x88] x low (r10), [sp+0x8c] x high
@ (r5), [sp+0x90] y low (r0), [sp+0x94] y high (r4); r6 = |x high|, r8 = |y high|.
@ The double result is returned in d0 (epilogue 0x08043a18).
@
@ Special cases in order:
@ (1) NaN test: if 2*high+(low!=0)+0x1fffff < 0xfffff (high-word bit 19 clear,
@     exponent field all ones, mantissa non-zero) for x (0x0804390e..0x08043916)
@     or for y (0x08043920..0x0804392a), or if 2*high+(low!=0) > 0xffe00000 for x
@     or y after the tests of (2) (cmn #0x200000 at 0x08043956 / 0x08043968), the
@     function tail-branches (b.w at 0x08043982) to the separate function
@     double_add_vfp_regs (0x08044d80..0x08044d93: vmov r2,r3,d1 / vmov r0,r1,d0,
@     bl 08044fac, vmov d0,r0,r1, pop {r4,pc}) with d0 = x, d1 = y; it returns
@     d0 + d1 to the caller of this function.
@ (2) y == +-0 returns 1.0 (d10 loaded from 0x08043d08, return at 0x08043a58);
@     x == +1.0 (high 0x3ff00000, low 0) returns 1.0.
@ (3) for x < 0 and finite y, r7 = class of y: 2 if |y high| >= 0x43400000,
@     otherwise 0 for |y high| < 0x3ff00000 or non-integer, 1 for odd integer,
@     2 for even integer (shift tests 0x080439a6..0x080439d2, r7 = 2 - (bit 0 of
@     the integer part)); r7 stays 0 for x >= 0.
@ (4) x == +-0 and y < 0: 0800788e(2) then +inf (0x08044d50 = 1.0/0.0 through
@     08045124); x == -0 with odd integer y (r7 = 1) gives -inf (0x08044d50
@     result negated by 08044f30 at 0x08043a10).
@ (5) y low == 0 and |y high| == 0x7ff00000 (y = +-inf): x == -1.0 returns 1.0;
@     |x high| < 0x3ff00000 returns 0.0 for y = +inf and +inf (08044f30 of y)
@     for y = -inf; otherwise returns y for y = +inf and 0.0 for y = -inf.
@ (6) y == +1.0 returns x; y == -1.0 (y high 0xbff00000, low 0): x == +-inf
@     returns a zero with the sign of x, x == +-0 returns an infinity with the
@     sign of x (bfi of the sign at 0x08043ab6 / 0x08043ad6), with 0800788e(2)
@     and 08044db8 first when x high == 0 and low != 0, any other x returns 1.0/x
@     (08045124 at 0x08043b10).
@ (7) y == +2.0 (y high 0x40000000, low 0) and |x high| < 0x7ff00000 returns x*x
@     (b.w 0x080444e8, 0804577c); y == +0.5 (y high 0x3fe00000, low 0) with
@     finite x >= +0 (x high sign clear) returns 08044e6a(x) (0x08043b3e).
@ (8) any other y with x == +-inf or +-0 or x == -1.0 (x low == 0): x == +-inf
@     gives, for x > 0, +inf (y >= 0) or 0.0 (y < 0), for x < 0, y >= 0 -inf if y
@     is an odd integer else +inf, y < 0 -0.0 if odd integer else +0.0
@     (0x08043b9a..0x08043bea); x == +-0 (y > 0) gives -0.0 if x == -0 and y odd
@     integer else +0.0 (0x08043bc8..0x08043bea); x == -1.0 gives +1.0 for r7 = 2
@     and -1.0 for r7 = 1 through 0804550a(+-1) (0x08043b8a..0x08043b94).
@ (9) x < 0 with r7 == 0 (non-integer y, also x == -1.0): 0800788e(1) then
@     tail-branch to 0x08044d98 (0.0/0.0 through 08045124)
@     (0x08043bf6..0x08043c40, 0x08043c2e).
@
@ Otherwise d8 = sign factor: 1.0 (copy of d10), or -1.0 (literal 0x08043d48,
@ vldreq at 0x08043c10) when x < 0 and y is an odd integer; r5 = 0 is used from
@ here on as the zero low word of constructed doubles.
@
@ Range cut on |y high| (r8): <= 0x41e00000 (0x08043c1a) goes to the general
@ path 0x08043e1a; larger |y| compares |x high| (r6): if r8 > 0x43f00000,
@ r6 > 0x3fefffff gives overflow for y > 0 and underflow for y <= 0,
@ r6 <= 0x3fefffff gives underflow for y >= 0 and overflow for y < 0; if
@ r8 <= 0x43f00000, r6 < 0x3fefffff gives underflow for y >= 0 and overflow for
@ y < 0, r6 > 0x3ff00000 gives overflow for y > 0 and underflow for y <= 0,
@ 0x3fefffff <= r6 <= 0x3ff00000 takes the near-1 path 0x08043cb4.
@
@ Overflow (0x08043c60): 0800788e(2), 08044db8 (+inf), sign taken from
@ d8 * +inf (0804577c) by bfi; underflow (0x08043c8e): 0800788e(2), 08044dd8 (0),
@ sign taken from d8.
@
@ Near-1 path (0x08043cb4..0x08043e16): t = |x| - 1.0 (08045b94 with d10);
@ w = t*t*(0.5 - t*(1/3 - 0.25*t)) as call order 0804577c(t,0.25 at 0x08043d60),
@ 080459e4 with 0x3fd5555555555555 (0x08043d68), 0804577c(.,t), 080459e4 with
@ 0.5 (0x08043d70), 0804577c(t,t), 0804577c(.,.); u = t*0x3ff7154760000000
@ (0x080441a0); v = t*0x3e54ae0bf85ddf44 (0x080441b0) - w*0x3ff71547652b82fe
@ (0x080441a8, 1.4426950408889634 = log2(e)) with 08045b94; t1 = u + v
@ (08044fac) with its low word set to 0 (strd r5 at 0x08043df6); t2 = v - (t1 - u)
@ (08045b94, 080459e4); continues at 0x0804416c with d0 = t2.
@
@ General path (0x08043e1a): if |x high| < 0x100000 then |x| is multiplied by
@ 2^53 (0x4340000000000000 at 0x080441b8, 0804577c) and the exponent is lowered
@ by 53; n = exponent field - 1023 (r7); j = high 20 bits of the mantissa;
@ ix = j | 0x3ff00000; k = 0 if j <= 0x3988e (0x08043e4c), k = 1 if j < 0xbb67a
@ (0x08043e5e), otherwise k = 0, ix -= 0x100000 and n += 1; bp[k] from the table
@ 0x08046290 = {1.0, 1.5} (0x08043e70); ax = |x| with high word ix.
@ Log steps: u = ax - bp[k] (08045b94); v = 1.0/(ax + bp[k]) (08044fac, 08045124);
@ ss = u*v (0804577c); s_h = ss with low word 0 (str r5 at 0x08043ed2); t_h =
@ double with low word 0 and high word ((ix>>1)|0x20000000) + 0x80000 + (k<<18)
@ (0x08043ed8..0x08043eec, zero from 0x08046488); t_l = ax - (t_h - bp[k])
@ (08045b94, 080459e4); s_l = v*((u - s_h*t_h) - s_h*t_l) (0804577c, 080459e4,
@ 08045b94); s2 = ss*ss; r = s2*s2*poly(s2) with 08044c58(d0 = s2, r0 = table
@ 0x080462c0 = {0.5999999999999946, 0.4285714285785502, 0.33333332981837743,
@ 0.272728123808534, 0.23066074577556175, 0.20697501780033842}, r1 = 6 elements,
@ a[0] + x*(a[1] + ...) Horner form from a[n-1] down to a[0]) then
@ r = r + s_l*(s_h + ss); t_h = 3.0 (0x080441d8) + s_h*s_h + r with low word 0
@ (0x08043ff0); t_l = r - ((t_h - 3.0) - s_h*s_h); u2 = s_h*t_h;
@ v2 = s_l*t_h + t_l*ss; p_h = u2 + v2 with low word 0 (0x08044022..0x0804406c),
@ p_l = v2 - (p_h - u2).
@ Then z_h = 0x3feec709e0000000 (0x080441e0) * p_h, z_l = 0xbe3e2fe0145b01f5
@ (0x080441f0) * p_h + p_l * 0x3feec709dc3a03fd (0x080441e8) + dp_l[k] with dp_l
@ at 0x080462b0 = {0.0, 1.350039202129749e-08} (0x080440d8); t = double(n)
@ (0804550a at 0x080440f6); t1 = ((z_h + z_l) + dp_h[k]) + t with dp_h at
@ 0x080462a0 = {0.0, 0.5849624872207642} (0x0804410e) and its low word set to 0
@ (0x08044132); t2 = z_l - (((t1 - t) - dp_h[k]) - z_h); continues at 0x0804416c
@ with d0 = t2 and t1 in [sp+0x10].
@
@ Exp steps (0x0804416c): y1 = y with low word 0 (str r5 at 0x08044178); y*t2
@ (0804577c); (y - y1)*t1 (08045b94, 0804577c) added to y*t2 gives p_l
@ (08044fac); y1*t1 gives p_h; z = p_l + p_h (0x08044240, high word in r4 as j).
@
@ Thresholds on z: j >= 0x40900000 (signed compare at 0x08044248, literal
@ 0x080444f0): if j != 0x40900000 or z low != 0 then overflow (0x08044284:
@ 0800788e(2), 08044db8, sign of d8 by bfi, return); if z == 1024.0 the overflow
@ is taken unless 08045978(p_l + 0x3c971547652b82fe (literal 0x080444f8, 08044fac),
@ z - p_h (08045b94)) leaves carry set (bcs at 0x08044282); j < 0x40900000 and
@ |j| >= 0x4090cc00 (unsigned compare at 0x080442b2, literal 0x08044500): if
@ j + 0x3f6f3400 (literal 0x08044504) or z low is non-zero then underflow
@ (bne.w 0x08043c8e), if z == -1075.0 the underflow is taken when
@ 08045978(z - p_h, p_l) leaves carry clear or Z set (bls.w at 0x080442dc).
@
@ Then if |j| > 0x3fe00000 (cmp at 0x080442ee): n = j + (0x100000 >> (exponent+1)),
@ t = double with low word 0 and high word n & ~(0xfffff >> k) with k from n,
@ n = ((n & 0xfffff) | 0x100000) >> (20 - k) (negated for j < 0) in r6,
@ p_h = p_h - t (08045b94); t = p_l + p_h with low word 0 (08044fac, 0x08044360);
@ u = t*0x3fe62e4300000000 (0x08044518); w1 = t*0xbe205c610ca86c39 (0x08044520);
@ v = (p_l - (t - p_h))*0x3fe62e42fefa39ef (0x08044528, 0.6931471805599453) + w1;
@ z = u + v; w = v - (z - u); t = z*z; c = 08044c58(d0 = t, r0 = table 0x080462f0 =
@ {0.16666666666666602, -0.0027777777777015593, 6.613756321437934e-05,
@ -1.6533902205465252e-06, 4.1381367970572385e-08}, r1 = 5 elements);
@ t1 = z - c*t; r = z*t1/(t1 - 2.0 (literal 0x4000000000000000 at 0x08044538))
@ - (w + z*w); z = 1.0 - (r - z) (d10).
@
@ Result: j2 = high word of z + (n << 20); if (j2 >> 20) > 0 it replaces the high
@ word of z (0x080444ac), otherwise z = 080461c8(z, n) (scale by 2^n), 080437d8
@ classifies it and if the class is 4 (non-zero mantissa, exponent field 0)
@ 08044dd8 is called and its result discarded (0x080444c2..0x080444c6), then
@ z = 080461c8(z, n) again; the result is d8 * z (0804577c at 0x080444e8)
@ returned in d0. The main code ends with its literal pool at
@ 0x08044530..0x0804453f (0x08044540 starts another function); the code at
@ 0x08044d98..0x08044daf (vldr d0, then push {r4,lr}, 0.0/0.0 through 08045124,
@ pop {r4,pc}), reached by the b.w at 0x08043c40, also belongs to this
@ function's body, while 0x08044d80..0x08044d93 is the separate function
@ double_add_vfp_regs.
@ Calls helpers 0800788e, 080437d8, 08044d50, 08044d80, 08044d98, 08044db8,
@ 08044dd8, 08044e6a, 08044f30, 08044fac, 08045124, 0804550a, 0804577c,
@ 08045978, 080459e4, 08045b94, 08044c58, 080461c8.
@ ----------------------------------------------------------------------------
	.section .text.double_pow,"ax",%progbits
	.global double_pow
	.thumb_func
	.type double_pow, %function
double_pow:
	push.w {r4, r5, r6, r7, r8, r10, r11, lr}
	vpush {d0, d1}
	vpush {d8, d9, d10, d11, d12, d13, d14}
	sub sp, #0x50
	ldrd r5, r0, [sp, #0x8c]
	ldr r4, [sp, #0x94]
	ldr.w r10, [sp, #0x88]
	bic.w r6, r5, #0x80000000
	bic.w r8, r4, #0x80000000
	cmp.w r10, #0
	ite ne
	movne r1, #1
	moveq r1, #0
	add.w r2, r1, r5, lsl #1
	ldr r1, .L08043d00
	adds r3, r2, r1
	asrs r2, r1, #1
	cmp r3, r2
	bcc.n .L0804396e
	cmp r0, #0
	ite ne
	movne r3, #1
	moveq r3, #0
	add.w r3, r3, r4, lsl #1
	add r3, r1
	ldr r1, .L08043d04
	cmp r3, r1
	bcc.n .L0804396e
	orrs.w r1, r8, r0
	vldr d10, .L08043d08
	beq.n .L08043a24
	ldr.w r11, .L08043d10
	cmp r5, r11
	bne.n .L08043946
	cmp.w r10, #0
	bne.n .L08043950
	b.n .L08043a58
.L08043946:
	cmp.w r10, #0
	it eq
	moveq r1, #0
	beq.n .L08043952
.L08043950:
	movs r1, #1
.L08043952:
	add.w r1, r1, r5, lsl #1
	cmn.w r1, #0x200000
	bhi.n .L0804396e
	cmp r0, #0
	ite ne
	movne r1, #1
	moveq r1, #0
	add.w r1, r1, r4, lsl #1
	cmn.w r1, #0x200000
	bls.n .L08043986
.L0804396e:
	vldr d1, [sp, #0x90]
	vldr d0, [sp, #0x88]
	add sp, #0x50
	vpop {d8, d9, d10, d11, d12, d13, d14}
	add sp, #0x10
	pop.w {r4, r5, r6, r7, r8, r10, r11, lr}
	b.w double_add_vfp_regs
.L08043986:
	movs r7, #0
	cmp r5, #0
	itt lt
	ldrlt r1, .L08043d14
	cmplt r8, r1
	bge.n .L080439d6
	ldr r1, .L08043d18
	cmp r8, r1
	it ge
	movge r7, #2
	bge.n .L080439d6
	cmp r11, r8
	bgt.n .L080439d6
	ldr r1, .L08043d1c
	add.w r1, r1, r8, asr #20
	cmp r1, #0x14
	ble.n .L080439bc
	rsb.w r2, r1, #0x34
	lsr.w r1, r0, r2
	lsl.w r2, r1, r2
	cmp r2, r0
	bne.n .L080439d6
	b.n .L080439ce
.L080439bc:
	cbnz r0, .L080439d6
	rsb.w r2, r1, #0x14
	lsr.w r1, r8, r2
	lsl.w r2, r1, r2
	cmp r2, r8
	bne.n .L080439d6
.L080439ce:
	and.w r1, r1, #1
	rsb.w r7, r1, #2
.L080439d6:
	orrs.w r1, r6, r10
	bne.n .L08043a26
	cmp r4, #0
	bge.n .L08043a26
	cmp r5, #0
	it ne
	cmpne r7, #2
	beq.n .L080439ec
	cmp r7, #1
	beq.n .L08043a02
.L080439ec:
	movs r0, #2
	bl fn_0800788e
	add sp, #0x50
	vpop {d8, d9, d10, d11, d12, d13, d14}
	add sp, #0x10
	pop.w {r4, r5, r6, r7, r8, r10, r11, lr}
	b.w fn_08044d50
.L08043a02:
	movs r0, #2
	bl fn_0800788e
	bl fn_08044d50
	vmov r0, r1, d0
	bl negate_f64
	vmov d0, r0, r1
.L08043a18:
	add sp, #0x50
	vpop {d8, d9, d10, d11, d12, d13, d14}
	add sp, #0x10
	pop.w {r4, r5, r6, r7, r8, r10, r11, pc}
.L08043a24:
	b.n .L08043a58
.L08043a26:
	vldr d9, .L08043d20
	vldr d8, .L08043d28
	cmp r0, #0
	bne.n .L08043b16
	ldr r0, .L08043d14
	cmp r8, r0
	bne.n .L08043a7e
	add.w r0, r5, #0x40000000
	adds.w r0, r0, #0x100000
	it eq
	cmpeq.w r10, #0
	beq.n .L08043a58
	cmp r11, r6
	bgt.n .L08043a62
	cmp r4, #0
	it ge
	vldrge d0, [sp, #0x90]
	bge.n .L08043a18
	b.n .L08043a74
.L08043a58:
	vmov.f32 s0, s20
	vmov.f32 s1, s21
	b.n .L08043a18
.L08043a62:
	cmp r4, #0
	bge.n .L08043a74
	vldr d0, [sp, #0x90]
	vmov r0, r1, d0
	bl negate_f64
	b.n .L08043b54
.L08043a74:
	ldr r0, .L08043d30
.L08043a76:
	add r0, pc
	vldr d0, [r0]
	b.n .L08043a18
.L08043a7e:
	cmp r8, r11
	bne.n .L08043b1e
	cmp r4, #0
	bge.n .L08043b18
	cbz r6, .L08043a94
	cmp r6, r0
	bne.n .L08043b02
	cmp.w r10, #0
	bne.n .L08043b18
	b.n .L08043ae2
.L08043a94:
	cmp.w r10, #0
	beq.n .L08043ac2
	movs r0, #2
	bl fn_0800788e
	bl fn_08044db8
	vstr d0, [sp, #8]
	vldr d0, [sp, #0x88]
	vstr d0, [sp]
	vmov r0, s1
	ldr r1, [sp, #0xc]
	bfi r0, r1, #0, #0x1f
	str r0, [sp, #0xc]
	vldr d0, [sp, #8]
	b.n .L08043a18
.L08043ac2:
	vstr d9, [sp, #8]
	vldr d0, [sp, #0x88]
	vmov r1, s19
	vmov r0, s1
	vstr d0, [sp]
	bfi r0, r1, #0, #0x1f
	str r0, [sp, #0xc]
	vldr d0, [sp, #8]
	b.n .L08043a18
.L08043ae2:
	vstr d8, [sp, #8]
	vldr d0, [sp, #0x88]
	vmov r1, s17
	vmov r0, s1
	vstr d0, [sp]
	bfi r0, r1, #0, #0x1f
	str r0, [sp, #0xc]
	vldr d0, [sp, #8]
	b.n .L08043a18
.L08043b02:
	bge.n .L08043b18
	vldr d0, [sp, #0x88]
	vmov r0, r1, d10
	vmov r2, r3, d0
	bl double_div
	b.n .L08043b54
.L08043b16:
	b.n .L08043b5a
.L08043b18:
	vldr d0, [sp, #0x88]
	b.n .L08043a18
.L08043b1e:
	cmp r6, r0
	bge.n .L08043b5a
	cmp.w r4, #0x40000000
	beq.n .L08043b44
	sub.w r0, r4, #0x20000000
	subs.w r0, r0, #0x1fe00000
	bne.n .L08043b5a
	cmp r5, #0
	blt.n .L08043b5a
	vldr d0, [sp, #0x88]
	vmov r0, r1, d0
	bl double_sqrt_checked_08044e6a
	b.n .L08043b54
.L08043b44:
	vldr d0, [sp, #0x88]
	vmov r2, r3, d0
	vmov r0, r1, d0
	b.w .L080444e8
.L08043b54:
	vmov d0, r0, r1
	b.n .L08043a18
.L08043b5a:
	vldr d0, [sp, #0x88]
	vmov r0, r1, d0
	bl abs_f64_08044e52
	cmp.w r10, #0
	strd r0, r1, [sp, #0x28]
	bne.n .L08043bf6
	vldr d0, .L08043d38
	cbz r6, .L08043bc8
	sub.w r0, r6, #0x70000000
	subs.w r0, r0, #0xff00000
	beq.n .L08043b9a
	cmp r6, r11
	bne.n .L08043bf6
	cmp r5, #0
	bge.n .L08043b8a
	cbz r7, .L08043bf4
.L08043b8a:
	cmp r7, #2
	ite eq
	moveq r0, #1
	movne.w r0, #0xffffffff
	bl i32_to_double
	b.n .L08043b54
.L08043b9a:
	cmp r5, #0
	ble.n .L08043ba2
	cmp r4, #0
	bge.n .L08043bbe
.L08043ba2:
	cmp r5, #0
	ble.n .L08043baa
	cmp r4, #0
	blt.n .L08043bea
.L08043baa:
	cmp r5, #0
	bge.n .L08043bdc
	cmp r4, #0
	blt.n .L08043bdc
	cmp r7, #1
	it eq
	vldreq d0, .L08043d40
	beq.w .L08043a18
.L08043bbe:
	vmov.f32 s0, s18
	vmov.f32 s1, s19
	b.n .L08043a18
.L08043bc8:
	cmp r7, #2
	it ne
	cmpne r5, #0
	beq.n .L08043bea
	cmp r7, #1
	bne.n .L08043bea
	cmp r5, #0
	blt.w .L08043a18
	b.n .L08043bea
.L08043bdc:
	cmp r5, #0
	it lt
	cmplt r4, #0
	bge.n .L08043bf6
	cmp r7, #1
	beq.w .L08043a18
.L08043bea:
	vmov.f32 s0, s16
	vmov.f32 s1, s17
	b.n .L08043a18
.L08043bf4:
	b.n .L08043c2e
.L08043bf6:
	movs r0, #1
	add.w r0, r0, r5, asr #31
	orrs.w r1, r0, r7
	beq.n .L08043c2e
	subs r1, r7, #1
	vmov.f32 s16, s20
	vmov.f32 s17, s21
	orrs r0, r1
	it eq
	vldreq d8, .L08043d48
	ldr r0, .L08043d50
	movs r5, #0
	cmp r8, r0
	ble.n .L08043cfe
	ldr r1, .L08043d54
	ldr r0, .L08043d58
	cmp r8, r1
	ble.n .L08043c4e
	cmp r0, r6
	blt.n .L08043c44
	cmp r4, #0
	blt.n .L08043c60
	b.n .L08043c8e
.L08043c2e:
	movs r0, #1
	bl fn_0800788e
	add sp, #0x50
	vpop {d8, d9, d10, d11, d12, d13, d14}
	add sp, #0x10
	pop.w {r4, r5, r6, r7, r8, r10, r11, lr}
	b.w	L_08044d98		@ tail jump into double_add_vfp_regs (global label there)
.L08043c44:
	cmp r11, r6
	bgt.n .L08043c4e
	cmp r4, #0
	bgt.n .L08043c60
	b.n .L08043c8e
.L08043c4e:
	cmp r6, r0
	bge.n .L08043c58
	cmp r4, #0
	bge.n .L08043c8e
	b.n .L08043c60
.L08043c58:
	cmp r6, r11
	ble.n .L08043cb4
	cmp r4, #0
	ble.n .L08043c8e
.L08043c60:
	movs r0, #2
	bl fn_0800788e
	bl fn_08044db8
	vstr d0, [sp, #8]
	vmov r2, r3, d9
	vmov r0, r1, d8
	bl double_mul
	strd r0, r1, [sp]
	ldr r1, [sp, #0xc]
	ldr r0, [sp, #4]
	bfi r0, r1, #0, #0x1f
	str r0, [sp, #0xc]
	vldr d0, [sp, #8]
	b.n .L08043a18
.L08043c8e:
	movs r0, #2
	bl fn_0800788e
	bl fn_08044dd8
	vmov r1, s1
	vmov r0, s17
	vstr d0, [sp, #8]
	vstr d8, [sp]
	bfi r0, r1, #0, #0x1f
	str r0, [sp, #0xc]
	vldr d0, [sp, #8]
	b.n .L08043a18
.L08043cb4:
	vldr d0, [sp, #0x28]
	vmov r2, r3, d10
	vmov r0, r1, d0
	bl double_sub
	vldr d0, .L08043d60
	strd r0, r1, [sp, #0x28]
	vmov r2, r3, d0
	vldr d0, [sp, #0x28]
	vmov r0, r1, d0
	bl double_mul
	vldr d1, .L08043d68
	vmov r2, r3, d1
	bl double_rsub
	vldr d1, [sp, #0x28]
	vmov r2, r3, d1
	bl double_mul
	vldr d1, .L08043d70
	vmov r2, r3, d1
	b.n .L08043d78
.L08043cfe:
	b.n .L08043e1a
.L08043d00:
	.word 0x001fffff
.L08043d04:
	.word 0x000fffff
.L08043d08:
	.word 0x00000000, 0x3ff00000	@ 1.0
.L08043d10:
	.word 0x3ff00000
.L08043d14:
	.word 0x7ff00000
.L08043d18:
	.word 0x43400000
.L08043d1c:
	.word 0xfffffc01
.L08043d20:
	.word 0x00000000, 0x7ff00000	@ +inf
.L08043d28:
	.word 0x00000000, 0x00000000	@ 0.0
.L08043d30:
	.word d_08046488 - (.L08043a76 + 4)
	.word 0x00000000	@ padding
.L08043d38:
	.word 0x00000000, 0x80000000	@ -0.0
.L08043d40:
	.word 0x00000000, 0xfff00000	@ -inf
.L08043d48:
	.word 0x00000000, 0xbff00000	@ -1.0
.L08043d50:
	.word 0x41e00000
.L08043d54:
	.word 0x43f00000
.L08043d58:
	.word 0x3fefffff
	.word 0x00000000	@ padding
.L08043d60:
	.word 0x00000000, 0x3fd00000	@ 0.25
.L08043d68:
	.word 0x55555555, 0x3fd55555	@ 0x3fd5555555555555
.L08043d70:
	.word 0x00000000, 0x3fe00000	@ 0.5
.L08043d78:
	bl double_rsub
	vldr d0, [sp, #0x28]
	vmov d9, r0, r1
	vmov r2, r3, d0
	vmov r0, r1, d0
	bl double_mul
	vmov r2, r3, d9
	bl double_mul
	vldr d0, [sp, #0x28]
	vmov d11, r0, r1
	vmov r2, r3, d0
	vldr d0, .L080441a0
	vmov r0, r1, d0
	bl double_mul
	vmov d9, r0, r1
	vldr d0, .L080441a8
	vmov r0, r1, d11
	vmov r2, r3, d0
	bl double_mul
	vmov d11, r0, r1
	vldr d0, .L080441b0
	vmov r2, r3, d0
	vldr d0, [sp, #0x28]
	vmov r0, r1, d0
	bl double_mul
	vmov r2, r3, d11
	bl double_sub
	vmov d11, r0, r1
	vmov r0, r1, d9
	vmov r2, r3, d11
	bl double_add
	str r0, [sp, #0x10]
	strd r5, r1, [sp, #0x10]
	vldr d0, [sp, #0x10]
	vmov r2, r3, d9
	vmov r0, r1, d0
	bl double_sub
	vmov r2, r3, d11
	bl double_rsub
	vmov d0, r0, r1
	b.w .L0804416c
.L08043e1a:
	movs r0, #0
	cmp.w r6, #0x100000
	bge.n .L08043e40
	vldr d0, .L080441b8
	vmov r2, r3, d0
	vldr d0, [sp, #0x28]
	vmov r0, r1, d0
	bl double_mul
	strd r0, r1, [sp, #0x28]
	mvn.w r0, #0x34
	mov r6, r1
.L08043e40:
	add.w r0, r0, r6, asr #20
	subw r7, r0, #0x3ff
	ubfx r0, r6, #0, #0x14
	ldr r1, .L080441c0
	orr.w r6, r0, #0xff00000
	orr.w r6, r6, #0x30000000
	cmp r0, r1
	it le
	movle r4, #0
	ble.n .L08043e70
	ldr r1, .L080441c4
	cmp r1, r0
	it gt
	movgt r4, #1
	bgt.n .L08043e70
	movs r4, #0
	sub.w r6, r6, #0x100000
	.inst.n 0x1c7f	@ adds r7, r7, #1
.L08043e70:
	ldr r0, .L080441c8
.L08043e72:
	add r0, pc
	add.w r8, r0, r4, lsl #3
	str r6, [sp, #0x2c]
	vldr d0, [r8]
	vmov r2, r3, d0
	vldr d0, [sp, #0x28]
	vmov r0, r1, d0
	bl double_sub
	vldr d0, [r8]
	vmov d11, r0, r1
	vmov r2, r3, d0
	vldr d0, [sp, #0x28]
	vmov r0, r1, d0
	bl double_add
	vmov d0, r0, r1
	vmov r0, r1, d10
	vmov r2, r3, d0
	bl double_div
	vmov d12, r0, r1
	vmov r0, r1, d11
	vmov r2, r3, d12
	bl double_mul
	vmov d9, r0, r1
	ldr r0, .L080441cc
	vstr d9, [sp, #0x38]
.L08043ed0:
	add r0, pc
	str r5, [sp, #0x38]
	vldr d0, [r0]
	mov.w r0, #0x20000000
	orr.w r0, r0, r6, asr #1
	add.w r0, r0, r4, lsl #18
	vstr d0, [sp, #0x48]
	add.w r0, r0, #0x80000
	str r0, [sp, #0x4c]
	vldr d0, [r8]
	vmov r2, r3, d0
	vldr d0, [sp, #0x48]
	vmov r0, r1, d0
	bl double_sub
	vldr d1, [sp, #0x28]
	vmov r2, r3, d1
	bl double_rsub
	vmov d0, r0, r1
	vmov r2, r3, d0
	vldr d0, [sp, #0x38]
	vmov r0, r1, d0
	bl double_mul
	vldr d0, [sp, #0x48]
	vmov d13, r0, r1
	vmov r2, r3, d0
	vldr d0, [sp, #0x38]
	vmov r0, r1, d0
	bl double_mul
	vmov r2, r3, d11
	bl double_rsub
	vmov r2, r3, d13
	bl double_sub
	vmov r2, r3, d12
	bl double_mul
	vmov d12, r0, r1
	vmov r2, r3, d9
	vmov r0, r1, d9
	bl double_mul
	vmov d11, r0, r1
	ldr r0, .L080441d0
	movs r1, #6
	vmov.f32 s0, s22
	vmov.f32 s1, s23
.L08043f72:
	add r0, pc
	bl double_poly_eval
	vmov.f32 s2, s0
	vmov.f32 s3, s1
	vmov.f32 s26, s2
	vmov.f32 s27, s3
	vmov r2, r3, d11
	vmov r0, r1, d11
	bl double_mul
	vmov r2, r3, d13
	bl double_mul
	vldr d0, [sp, #0x38]
	vmov d11, r0, r1
	vmov r2, r3, d9
	vmov r0, r1, d0
	bl double_add
	vmov r2, r3, d12
	bl double_mul
	vmov r2, r3, d11
	bl double_add
	vldr d0, [sp, #0x38]
	vmov d11, r0, r1
	vmov r2, r3, d0
	vmov r0, r1, d0
	bl double_mul
	vmov d13, r0, r1
	vmov r2, r3, d13
	vldr d14, .L080441d8
	vmov r0, r1, d14
	bl double_add
	vmov r2, r3, d11
	bl double_add
	str r0, [sp, #0x48]
	strd r5, r1, [sp, #0x48]
	vldr d0, [sp, #0x48]
	vmov r2, r3, d14
	vmov r0, r1, d0
	bl double_sub
	vmov r2, r3, d13
	bl double_sub
	vmov r2, r3, d11
	bl double_rsub
	vldr d0, [sp, #0x48]
	vmov d13, r0, r1
	vmov r2, r3, d0
	vldr d0, [sp, #0x38]
	vmov r0, r1, d0
	bl double_mul
	vmov d11, r0, r1
	vmov r2, r3, d9
	vmov r0, r1, d13
	bl double_mul
	vldr d0, [sp, #0x48]
	vmov d9, r0, r1
	vmov r2, r3, d0
	vmov r0, r1, d12
	bl double_mul
	vmov r2, r3, d9
	bl double_add
	vmov d9, r0, r1
	vmov r0, r1, d11
	vmov r2, r3, d9
	bl double_add
	str r0, [sp, #0x10]
	strd r5, r1, [sp, #0x10]
	vldr d0, [sp, #0x10]
	vmov r2, r3, d11
	vmov r0, r1, d0
	bl double_sub
	vmov r2, r3, d9
	bl double_rsub
	vldr d0, [sp, #0x10]
	vmov d9, r0, r1
	vmov r2, r3, d0
	vldr d0, .L080441e0
	vmov r0, r1, d0
	bl double_mul
	vmov d11, r0, r1
	vldr d0, .L080441e8
	vmov r0, r1, d9
	vmov r2, r3, d0
	bl double_mul
	vldr d0, [sp, #0x10]
	vmov d9, r0, r1
	vmov r2, r3, d0
	vldr d0, .L080441f0
	vmov r0, r1, d0
	bl double_mul
	vmov r2, r3, d9
	bl double_add
	vmov d0, r0, r1
	ldr r0, .L080441f8
.L080440da:
	add r0, pc
	add.w r0, r0, r4, lsl #3
	vldr d1, [r0]
	vmov r0, r1, d0
	vmov r2, r3, d1
	bl double_add
	vmov d9, r0, r1
	mov r0, r7
	bl i32_to_double
	strd r0, r1, [sp, #0x28]
	vmov r2, r3, d9
	vmov r0, r1, d11
	bl double_add
	vmov d0, r0, r1
	ldr r0, .L080441fc
.L08044110:
	add r0, pc
	add.w r4, r0, r4, lsl #3
	vmov r0, r1, d0
	vldr d1, [r4]
	vmov r2, r3, d1
	bl double_add
	vldr d1, [sp, #0x28]
	vmov r2, r3, d1
	bl double_add
	str r0, [sp, #0x10]
	strd r5, r1, [sp, #0x10]
	vldr d0, [sp, #0x28]
	vmov r2, r3, d0
	vldr d0, [sp, #0x10]
	vmov r0, r1, d0
	bl double_sub
	vldr d1, [r4]
	vmov r2, r3, d1
	bl double_sub
	vmov r2, r3, d11
	bl double_sub
	vmov r2, r3, d9
	bl double_rsub
	vmov d0, r0, r1
.L0804416c:
	vldr d1, [sp, #0x90]
	vmov r2, r3, d0
	vstr d1, [sp]
	str r5, [sp]
	vldr d0, [sp, #0x90]
	vmov r0, r1, d0
	bl double_mul
	vldr d0, [sp]
	vmov d9, r0, r1
	vmov r2, r3, d0
	vldr d0, [sp, #0x90]
	vmov r0, r1, d0
	bl double_sub
	b.n .L08044200
.L080441a0:
	.word 0x60000000, 0x3ff71547	@ 0x3ff7154760000000
.L080441a8:
	.word 0x652b82fe, 0x3ff71547	@ 0x3ff71547652b82fe (log2(e))
.L080441b0:
	.word 0xf85ddf44, 0x3e54ae0b	@ 0x3e54ae0bf85ddf44
.L080441b8:
	.word 0x00000000, 0x43400000	@ 2^53
.L080441c0:
	.word 0x0003988e
.L080441c4:
	.word 0x000bb67a
.L080441c8:
	.word d_08046290 - (.L08043e72 + 4)
.L080441cc:
	.word d_08046488 - (.L08043ed0 + 4)
.L080441d0:
	.word d_080462c0 - (.L08043f72 + 4)
	.word 0x00000000	@ padding
.L080441d8:
	.word 0x00000000, 0x40080000	@ 3.0
.L080441e0:
	.word 0xe0000000, 0x3feec709	@ 0x3feec709e0000000
.L080441e8:
	.word 0xdc3a03fd, 0x3feec709	@ 0x3feec709dc3a03fd
.L080441f0:
	.word 0x145b01f5, 0xbe3e2fe0	@ 0xbe3e2fe0145b01f5
.L080441f8:
	.word d_080462b0 - (.L080440da + 4)
.L080441fc:
	.word d_080462a0 - (.L08044110 + 4)
.L08044200:
	vldr d1, [sp, #0x10]
	vmov r2, r3, d1
	bl double_mul
	vmov r2, r3, d9
	bl double_add
	vldr d0, [sp, #0x10]
	vmov d9, r0, r1
	vmov r2, r3, d0
	vldr d0, [sp]
	vmov r0, r1, d0
	bl double_mul
	strd r0, r1, [sp, #0x10]
	vldr d0, [sp, #0x10]
	vmov r0, r1, d9
	vmov r2, r3, d0
	bl double_add
	strd r0, r1, [sp, #8]
	mov r4, r1
	ldr r1, .L080444f0
	cmp r4, r1
	blt.n .L080442ac
	subs r1, r4, r1
	orrs r0, r1
	bne.n .L08044284
	vldr d0, [sp, #0x10]
	vmov r2, r3, d0
	vldr d0, [sp, #8]
	vmov r0, r1, d0
	bl double_sub
	vmov d11, r0, r1
	vldr d0, .L080444f8
	vmov r0, r1, d9
	vmov r2, r3, d0
	bl double_add
	vmov r2, r3, d11
	bl fn_08045978
	bcs.n .L080442e0
.L08044284:
	movs r0, #2
	bl fn_0800788e
	bl fn_08044db8
	vmov r1, s1
	vmov r0, s17
	vstr d0, [sp, #8]
	vstr d8, [sp]
	bfi r0, r1, #0, #0x1f
	str r0, [sp, #0xc]
	vldr d0, [sp, #8]
	b.w .L08043a18
.L080442ac:
	ldr r2, .L08044500
	bic.w r1, r4, #0x80000000
	cmp r1, r2
	bcc.n .L080442e0
	ldr r1, .L08044504
	add r1, r4
	orrs r0, r1
	bne.w .L08043c8e
	vldr d0, [sp, #0x10]
	vmov r2, r3, d0
	vldr d0, [sp, #8]
	vmov r0, r1, d0
	bl double_sub
	vmov r2, r3, d9
	bl fn_08045978
	bls.w .L08043c8e
.L080442e0:
	bic.w r0, r4, #0x80000000
	ldr r1, .L08044508
	ldr r2, .L0804450c
	movs r6, #0
	add.w r1, r1, r0, asr #20
	cmp r2, r0
	bge.n .L0804434a
	adds r0, r1, #1
	mov.w r1, #0x100000
	lsr.w r0, r1, r0
	add r0, r4
	ldr r2, .L08044510
	ubfx r1, r0, #0x14, #0xb
.L08044304:
	add r2, pc
	subw r1, r1, #0x3ff
	vldr d0, [r2]
	ldr r2, .L08044514
	vstr d0, [sp, #0x28]
	lsrs r2, r1
	bic.w r2, r0, r2
	ubfx r0, r0, #0, #0x14
	orr.w r0, r0, #0x100000
	rsb.w r1, r1, #0x14
	lsr.w r6, r0, r1
	str r2, [sp, #0x2c]
	cmp r4, #0
	it lt
	rsblt r6, r6, #0
	vldr d0, [sp, #0x28]
	vmov r2, r3, d0
	vldr d0, [sp, #0x10]
	vmov r0, r1, d0
	bl double_sub
	strd r0, r1, [sp, #0x10]
.L0804434a:
	vldr d0, [sp, #0x10]
	vmov r0, r1, d9
	vmov r2, r3, d0
	bl double_add
	vldr d0, .L08044518
	str r0, [sp, #0x28]
	strd r5, r1, [sp, #0x28]
	vmov r2, r3, d0
	vldr d0, [sp, #0x28]
	vmov r0, r1, d0
	bl double_mul
	vmov d11, r0, r1
	vldr d0, .L08044520
	vmov r2, r3, d0
	vldr d0, [sp, #0x28]
	vmov r0, r1, d0
	bl double_mul
	vldr d0, [sp, #0x10]
	vmov d12, r0, r1
	vmov r2, r3, d0
	vldr d0, [sp, #0x28]
	vmov r0, r1, d0
	bl double_sub
	vmov r2, r3, d9
	bl double_rsub
	vldr d1, .L08044528
	vmov r2, r3, d1
	bl double_mul
	vmov r2, r3, d12
	bl double_add
	vmov d9, r0, r1
	vmov r0, r1, d11
	vmov r2, r3, d9
	bl double_add
	strd r0, r1, [sp, #8]
	vldr d0, [sp, #8]
	vmov r2, r3, d11
	vmov r0, r1, d0
	bl double_sub
	vmov r2, r3, d9
	bl double_rsub
	vldr d0, [sp, #8]
	vmov d9, r0, r1
	vmov r2, r3, d0
	vmov r0, r1, d0
	bl double_mul
	strd r0, r1, [sp, #0x28]
	ldr r0, .L08044530
	vldr d0, [sp, #0x28]
	movs r1, #5
.L0804440c:
	add r0, pc
	bl double_poly_eval
	vldr d1, [sp, #0x28]
	vmov r0, r1, d0
	vmov r2, r3, d1
	bl double_mul
	vldr d1, [sp, #8]
	vmov r2, r3, d1
	bl double_rsub
	strd r0, r1, [sp, #0x10]
	vldr d0, [sp, #8]
	vmov r2, r3, d9
	vmov r0, r1, d0
	bl double_mul
	vmov r2, r3, d9
	bl double_add
	vldr d0, .L08044538
	vmov d9, r0, r1
	vmov r2, r3, d0
	vldr d0, [sp, #0x10]
	vmov r0, r1, d0
	bl double_sub
	vldr d0, [sp, #0x10]
	vmov d11, r0, r1
	vmov r2, r3, d0
	vldr d0, [sp, #8]
	vmov r0, r1, d0
	bl double_mul
	vmov r2, r3, d11
	bl double_div
	vmov r2, r3, d9
	bl double_sub
	vldr d1, [sp, #8]
	vmov r2, r3, d1
	bl double_sub
	vmov r2, r3, d10
	bl double_rsub
	strd r0, r1, [sp, #8]
	add.w r0, r1, r6, lsl #20
	asrs r1, r0, #0x14
	cmp r1, #0
	it gt
	strgt r0, [sp, #0xc]
	bgt.n .L080444dc
	vldr d0, [sp, #8]
	mov r2, r6
	vmov r0, r1, d0
	bl double_scale_by_pow2
	bl classify_double
	cmp r0, #4
	it eq
	bleq fn_08044dd8
	mov r2, r6
	vldr d0, [sp, #8]
	vmov r0, r1, d0
	bl double_scale_by_pow2
	strd r0, r1, [sp, #8]
.L080444dc:
	vldr d0, [sp, #8]
	vmov r0, r1, d8
	vmov r2, r3, d0
.L080444e8:
	bl double_mul
	b.w .L08043b54
.L080444f0:
	.word 0x40900000
	.word 0x00000000	@ padding
.L080444f8:
	.word 0x652b82fe, 0x3c971547	@ 0x3c971547652b82fe
.L08044500:
	.word 0x4090cc00
.L08044504:
	.word 0x3f6f3400
.L08044508:
	.word 0xfffffc01
.L0804450c:
	.word 0x3fe00000
.L08044510:
	.word d_08046488 - (.L08044304 + 4)
.L08044514:
	.word 0x000fffff
.L08044518:
	.word 0x00000000, 0x3fe62e43	@ 0x3fe62e4300000000
.L08044520:
	.word 0x0ca86c39, 0xbe205c61	@ 0xbe205c610ca86c39
.L08044528:
	.word 0xfefa39ef, 0x3fe62e42	@ 0x3fe62e42fefa39ef (0.6931471805599453)
.L08044530:
	.word d_080462f0 - (.L0804440c + 4)
	.word 0x00000000	@ padding
.L08044538:
	.word 0x00000000, 0x40000000	@ 2.0
