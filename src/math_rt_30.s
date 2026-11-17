@ math_rt_30.s - single-precision powf (float_pow) with its special-case paths, and the small double / float math helpers 08044ba4..08044f36.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ float_pow - single-precision x raised to the power y.
@ Params: x = s0, y = s1 (vmov r0,s0 at 0x08044542 and vmov r1,s1 at 0x0804454e copy
@ their raw bits to r0 and r1). Returns a float in s0. The function body is
@ 0x08044540..0x08044ba3 (literal words 0x08044958..0x080449a7 and 0x08044b88..0x08044ba3);
@ the bytes 0x08044ba4..0x08044e1d hold other functions (08044ba4, 08044c1e, 08044c58,
@ 08044d50, ...), so the size 1530 / end 08044e11 in functions.csv does not delimit it.
@ Registers: s16 = sign factor (1.0, set to -1.0 for negative x with odd integer y),
@ r2 = exponent count (0, or -27 after denormal scaling), s19 = 0.0 (literal 0x08044958,
@ also the returned +0.0), s17/s19 = high/low part of 16*y*log2(x), r4 = 0xff000000.
@ 'call 0800788e(n)' stores n in the word 0x20001240.
@ Entry tests: if x_bits - 0x800000 >= 0x7f000000 unsigned (x is not a positive normal
@ float) go to 0x080448dc, else 0x08044574; both test t = 0x2000000 + (y_bits<<1) <
@ 0x40000000 unsigned (exponent field of y < 0x3e or >= 0xfe) and then go to 0x080449bc,
@ otherwise x positive normal goes to the general path 0x0804457c and any other x to
@ 0x080448e4.
@ 0x080449bc: exponent field of y = 0xff (inf or NaN) goes to 0x080449fe; exponent field
@ 0xfe sets s1 = y_bits - 0x800000 (y with its exponent lowered by 1; r1 keeps the
@ original y) and goes to 0x080448e4; exponent field < 0x3e with y != 0 sets
@ s1 = (sign of y) | 0x1f800000 (+-2^-64) and goes to 0x080448e4; y == 0 returns 1.0
@ (0x08044b2a) when x*2 != 0 and x*2 < 0xff000000 (x finite nonzero), otherwise goes
@ to 0x080448e4.
@ 0x080448e4: x_bits + 0x7f800000 < 0x7f000000 unsigned (x negative normal) goes to
@ 0x080448f0; otherwise 0x08044938: when x*2 == 0 or x*2 >= 0x1000000 it goes to
@ 0x0804457c if x_bits - 0x800000 < 0x7f000000 (x positive normal) and to 0x080449fe if
@ not; when x*2 is 1..0xffffff (denormal) it sets s0 = x * 134217728.0 (2^27, literal
@ 0x080449a4), r2 = -27 and goes to 0x0804457c when the scaled value has sign bit clear,
@ else to 0x080448f0.
@ 0x080448f0 (negative x): s0 = |x|; e = exponent field of y (original y in r1): e < 0x7f
@ is a non-integer, e >= 0x97 is an even integer (s16 stays 1.0), otherwise
@ m = 1 << (0x96 - e): (y_bits & (m-1)) != 0 is a non-integer, else y_bits & m != 0 sets
@ s16 = -1.0 (odd integer); then 0x0804457c. A non-integer calls 0800788e(1), restores
@ the registers (vpop {d8-d10} at 08044922, pop.w {r4,lr} at 08044926) and branches with
@ b.w 08044e14 at 0804492a to float_return_nan, which returns 0.0/0.0 = NaN in s0.
@ 0x080449fe (y inf/NaN, or x zero/infinity/NaN): if |x| or |y| lies in
@ 0x7f800001..0x7fbfffff (|v| + 0x807fffff < 0x003fffff, literal 0x08044b88) or later
@ exceeds 0x7f800000, it returns x+y (vadd at 0x08044e0c); x == 1.0 or y*2 == 0 returns
@ 1.0 (0x08044b2a); x == +inf returns +0.0 when y has its sign bit set, else +inf. Then
@ iVar4 from y: e < 0x7f gives 0 (non-integer), e >= 0x97 gives 2 (even), else
@ m = 1 << (0x96 - e): y_bits & (m-1) != 0 gives 0, y_bits & m != 0 gives 1 (odd), else
@ 2. x == -inf: y negative returns -0.0 for odd else +0.0; y non-negative returns -inf
@ for odd else +inf. x == +0: y negative calls 0800788e(2) and returns the result of
@ 08044df8 (+inf, 1.0/0.0), y non-negative returns +0.0. x == -0: y == +inf returns
@ +0.0; y == -inf calls 0800788e(2) and returns +inf (08044df8); y positive returns -0.0
@ for odd else +0.0; y negative calls 0800788e(2) and returns -inf (negated 08044df8)
@ for odd, else +inf. x == -1.0 returns 1.0. Any other x (finite nonzero, y = +-inf):
@ a = (x*2 >= 0x7f000000), b = (y sign clear); a == b returns +inf, else +0.0.
@ General path 0x0804457c (x positive normal, s1 = y): R(v) below means bits(v) + 0x800
@ with bits 0..11 cleared (add, bfc). If x_bits - 0x3f7ff000 <= 0x2000 (x_bits in
@ 0x3f7ff000..0x3f801000): t = x - 1.0; hi = t*23.0859375 (0x41b8b000, 0x08044b98);
@ lo = t*(-0.0028168457) (0x08044b9c) - (t*t*(0.5 - t*(0.33333334 - t*0.25)))*23.08312
@ (0x41b8aa3b, 0x08044ba0; 23.08312 = 16/ln2); s18 = R(hi+lo), s20 = (hi - s18) + lo.
@ Otherwise: u = (x_bits + 0x40000) >> 19, i = u & 15, k = ((u>>4) & 0xff) - 127,
@ x' = x_bits - (k<<23) (x with exponent lowered by k), r2 += k, c = 1.0 + i*0.0625
@ (0x3d800000, 0x08044964); a = R(x'+c); rc = 1.0/(x'+c) (vdiv at 0x080445de);
@ qh = R((x'-c)*rc); ql = (((x'-c) - qh*a) - qh*((c-a)+x'))*rc; q = qh+ql; z = q*q;
@ S = ql + ((0.33333334 + z*0.20008275)*z)*q (0x3e4ce27e, 0x08044968); vh = R(qh+S);
@ vl = (qh - vh) + S; Lh0 = vh*46.171875 (0x4238b000, 0x0804496c); Ll0 = vh*(-0.0056336913)
@ (0xbbb89ad4, 0x08044970) + vl*46.16624 (0x4238aa3b, 0x08044974; 46.16624 = 32/ln2);
@ Lh = R(Lh0+Ll0); Ll = (Lh0 - Lh) + Ll0; the table at 0x08046318 holds two floats per i
@ (T1 at +8*i, T2 at +8*i+4; T1+T2 equals 16*log2(1+i/16) for all 16 entries);
@ s5 = float(r2*16); s18 = R(Ll + T2 + Lh + T1 + s5);
@ s20 = Ll - ((((s18 - s5) - T1) - Lh) - T2). In both branches s18 + s20 = 16*log2(x).
@ Product (0x080446c0): yh = R(s1) (s17), yl = s1 - yh (s21), p = s18*yh; if bits(|p|) >
@ 0x45800000 (|p| > 4096.0) and 2*bits(|p|) <= 0xff000000 then s17 = (sign of p) |
@ 0x45800000 (+-4096.0) and s19 stays 0.0; otherwise w = s18*yl + s20*(yh+yl),
@ s17 = R(p+w), s19 = (p - s17) + w.
@ Exponentiation (0x08044736): S = s17 + s19; n = trunc(S + (S < 0 ? -0.5 : 0.5))
@ (vcvt.s32.f32); m = float(n asr 4); f = (s17 - float(n)) + s19; j = n & 15;
@ P = f*(0.0433217 + f*(0.0009384123 + f*1.35512055e-05)) (0x3d317218 at 0x08044984,
@ 0x3a75ffc9 at 0x08044980, 0x376359fc at 0x0804497c; 0.0433217 = ln2/16);
@ g = T_d8[j] + T_18[j]*P + T_98[j] with the float tables at 0x080463d8, 0x08046418,
@ 0x08046398 (T_18[j] equals 2^(j/16) in single precision for all 16 entries).
@ Result by m: if bits(|m|) < 0x42fc0000 (|m| < 126.0) the result is
@ uint32((m + 127.0)*8388608.0) used as a float bit pattern (2^m) times (s16*g); else if
@ bits(|m|) < 0x43400000 (|m| < 192.0): n2 = int(m), h = (n2 + (n2 lsr 31)) asr 1,
@ A = float with bits (h<<23) + 0x3f800000, B = float with bits ((n2-h)<<23) +
@ 0x3f800000, r = A*(s16*g)*B; if 2*bits(r) == 0xff000000 (r infinite) it calls
@ 0800788e(2), 08044e24 (+inf from 0x70000000*0x70000000 in single) and returns that
@ magnitude with the sign of s16; else if 2*bits(r) == 0 it calls 0800788e(2), 08044e34
@ (0x10000000*0x10000000 in single = 0) and returns that magnitude with the sign of s16;
@ else it calls 08044e34 (result discarded) when 08043808(bits(r)) == 4 (denormal) and
@ returns r; else (|m| >= 192.0 or NaN): m >= 0.0 calls 0800788e(2) and returns +-inf
@ (08044e24 magnitude, sign of s16), otherwise calls 0800788e(2) and returns +-0
@ (08044e34 magnitude, sign of s16).
@ For x positive normal (or made so by |x| / the 2^27 scaling) and y not special the
@ function returns s16 * 2^(y*log2(x)) in single precision (x raised to the power y);
@ special operands follow the cases above.
@ ----------------------------------------------------------------------------
	.section .text.float_pow,"ax",%progbits
	.p2align 2
	.global float_pow
	.thumb_func
	.type float_pow, %function
float_pow:
	push	{r4, lr}
	vmov	r0, s0
	vpush	{d8, d9, d10}
	vmov.f32	s2, #1.0
	vmov	r1, s1
	vmov.f32	s16, s2
	movs	r2, #0
	sub.w	r12, r0, #0x800000
	vldr	s19, .L08044958
	mov.w	r3, #0x2000000
	cmp.w	r12, #0x7f000000
	mov.w	r4, #0xff000000
	add.w	r12, r3, r1, lsl #1
	bcs.w	.L080448dc
	cmp.w	r12, #0x40000000
	bcc.w	.L080449bc
.L0804457c:
	ldr	r1, .L0804495c
	add	r1, r0
	vldr	s6, .L08044960
	cmp.w	r1, #0x2000
	bls.w	.L08044b34
	add.w	r1, r0, #0x40000
	lsrs	r3, r1, #0x13
	and	r1, r3, #0xf
	vmov	s3, r1
	ubfx	r3, r3, #4, #8
	subs	r3, #0x7f
	sub.w	r0, r0, r3, lsl #23
	vcvt.f32.s32	s4, s3
	vmov	s0, r0
	add	r2, r3
	vldr	s5, .L08044964
	vmov.f32	s3, s2
	vmla.f32	s3, s4, s5
	vmov.f32	s7, s3
	vadd.f32	s5, s0, s7
	vsub.f32	s4, s0, s7
	vmov	r0, s5
	add.w	r0, r0, #0x800
	bfc	r0, #0, #12
	vmov	s3, r0
	vsub.f32	s7, s7, s3
	vadd.f32	s8, s7, s0
	vdiv.f32	s7, s2, s5
	vmul.f32	s0, s4, s7
	vmov	r0, s0
	add.w	r0, r0, #0x800
	bfc	r0, #0, #12
	vmov	s0, r0
	vmls.f32	s4, s0, s3
	vmls.f32	s4, s0, s8
	vmul.f32	s5, s4, s7
	vadd.f32	s3, s0, s5
	vmul.f32	s4, s3, s3
	vldr	s7, .L08044968
	vmla.f32	s6, s4, s7
	vmul.f32	s6, s6, s4
	vmul.f32	s4, s0, s2
	vmul.f32	s2, s5, s2
	vmla.f32	s2, s6, s3
	vadd.f32	s0, s4, s2
	vmov	r0, s0
	add.w	r0, r0, #0x800
	bfc	r0, #0, #12
	vmov	s0, r0
	vsub.f32	s3, s4, s0
	vadd.f32	s4, s3, s2
	vldr	s2, .L0804496c
	vmul.f32	s3, s0, s2
	vldr	s2, .L08044970
	vmul.f32	s2, s0, s2
	vldr	s0, .L08044974
	vmla.f32	s2, s4, s0
	vadd.f32	s0, s3, s2
	vmov	r0, s0
	add.w	r0, r0, #0x800
	bfc	r0, #0, #12
	vmov	s0, r0
	ldr	r0, .L08044978
	vsub.f32	s3, s3, s0
	vadd.f32	s4, s3, s2
.L08044674:
	add	r0, pc
	add.w	r0, r0, r1, lsl #3
	vldr	s6, [r0]
	vldr	s3, [r0, #4]
	lsls	r0, r2, #4
	vmov	s2, r0
	vcvt.f32.s32	s5, s2
	vadd.f32	s2, s4, s3
	vadd.f32	s2, s2, s0
	vadd.f32	s2, s2, s6
	vadd.f32	s2, s2, s5
	vmov	r0, s2
	add.w	r0, r0, #0x800
	bfc	r0, #0, #12
	vmov	s18, r0
	vsub.f32	s2, s18, s5
	vsub.f32	s2, s2, s6
	vsub.f32	s0, s2, s0
	vsub.f32	s0, s0, s3
	vsub.f32	s20, s4, s0
.L080446c0:
	vmov	r0, s1
	movs	r1, #0
	add.w	r0, r0, #0x800
	bfc	r0, #0, #12
	vmov	s17, r0
	mov	r0, r1
	vsub.f32	s21, s1, s17
	mov.w	r0, #0
	vmul.f32	s0, s18, s17
	and	r1, r0, #0xc
	vabs.f32	s1, s0
	vmov	r0, s1
	cmp.w	r0, #0x45800000
	ble.n	.L0804470e
	vmov	r0, s1
	cmp.w	r4, r0, lsl #1
	bcc.n	.L0804470e
	vmov	r0, s0
	mov.w	r2, #0x45800000
	bfi	r0, r2, #0, #31
	vmov	s17, r0
	b.n	.L08044736
.L0804470e:
	vmul.f32	s1, s18, s21
	vadd.f32	s2, s17, s21
	vmla.f32	s1, s20, s2
	vadd.f32	s2, s0, s1
	vmov	r0, s2
	add.w	r0, r0, #0x800
	bfc	r0, #0, #12
	vmov	s17, r0
	vsub.f32	s0, s0, s17
	vadd.f32	s19, s0, s1
.L08044736:
	movs	r0, #0xc
	mov.w	r0, #0
	vadd.f32	s0, s17, s19
	vcmpe.f32	s0, #0
	vmrs	APSR_nzcv, fpscr
	ite	cc
	vmovcc.f32	s1, #-0.5
	vmovcs.f32	s1, #0.5
	vadd.f32	s0, s1, s0
	vcvt.s32.f32	s0, s0
	vmov	r0, s0
	asrs	r1, r0, #4
	vmov	s0, r1
	vcvt.f32.s32	s1, s0
	vmov	s0, r0
	vcvt.f32.s32	s0, s0
	vsub.f32	s0, s17, s0
	vadd.f32	s0, s0, s19
	vldr	s3, .L0804497c
	vldr	s2, .L08044980
	vmla.f32	s2, s0, s3
	vldr	s3, .L08044984
	ldr	r1, .L08044988
	and	r0, r0, #0xf
	vmla.f32	s3, s0, s2
	vmul.f32	s0, s3, s0
.L08044796:
	add	r1, pc
	add.w	r1, r1, r0, lsl #2
	vldr	s2, [r1]
	ldr	r1, .L0804498c
.L080447a2:
	add	r1, pc
	add.w	r1, r1, r0, lsl #2
	vldr	s3, [r1]
	ldr	r1, .L08044990
	vmla.f32	s2, s3, s0
.L080447b2:
	add	r1, pc
	add.w	r0, r1, r0, lsl #2
	ldr	r1, .L08044994
	vldr	s0, [r0]
	vadd.f32	s2, s2, s0
	vabs.f32	s0, s1
	vmov	r0, s0
	cmp	r0, r1
	bge.n	.L080447fa
	vmov	r0, s0
	cmp.w	r4, r0, lsl #1
	bcc.n	.L080447fa
	vldr	s0, .L08044998
	vadd.f32	s0, s1, s0
	vldr	s1, .L0804499c
	vmul.f32	s0, s0, s1
	vmul.f32	s1, s16, s2
	vpop	{d8, d9, d10}
	vcvt.u32.f32	s0, s0
	vmul.f32	s0, s0, s1
	pop	{r4, pc}
.L080447fa:
	vmov	r0, s0
	ldr	r1, .L080449a0
	cmp	r0, r1
	bge.n	.L0804488c
	vmov	r0, s0
	cmp.w	r4, r0, lsl #1
	bcc.n	.L0804488c
	vcvt.s32.f32	s0, s1
	vmul.f32	s1, s16, s2
	vmov	r0, s0
	add.w	r2, r0, r0, lsr #31
	asrs	r1, r2, #1
	lsls	r1, r1, #0x17
	add.w	r1, r1, #0x3f800000
	vmov	s0, r1
	sub.w	r0, r0, r2, asr #1
	lsls	r0, r0, #0x17
	vmul.f32	s1, s0, s1
	add.w	r0, r0, #0x3f800000
	vmov	s0, r0
	vmul.f32	s17, s1, s0
	vmov	r0, s17
	cmp.w	r4, r0, lsl #1
	bne.n	.L0804486a
	movs	r0, #2
	bl	fn_0800788e
	bl	fn_08044e24
	vmov	r1, s0
	vmov	r0, s16
	vpop	{d8, d9, d10}
	bfi	r0, r1, #0, #31
	vmov	s0, r0
	pop	{r4, pc}
.L0804486a:
	vmov	r0, s17
	lsls	r0, r0, #1
	beq.n	.L08044896
	vmov	r0, s17
	bl	classify_float
	cmp	r0, #4
	it	eq
	bleq	fn_08044e34
	vmov.f32	s0, s17
	vpop	{d8, d9, d10}
	pop	{r4, pc}
.L0804488c:
	vcmpe.f32	s1, #0
	vmrs	APSR_nzcv, fpscr
	bcs.n	.L080448b6
.L08044896:
	movs	r0, #2
	bl	fn_0800788e
	bl	fn_08044e34
	vmov	r1, s0
	vmov	r0, s16
	vpop	{d8, d9, d10}
	bfi	r0, r1, #0, #31
	vmov	s0, r0
	pop	{r4, pc}
.L080448b6:
	movs	r0, #2
	bl	fn_0800788e
	bl	fn_08044e24
	vmov	r1, s0
	vmov.f32	s0, s16
	vmov	r0, s0
	vpop	{d8, d9, d10}
	bfi	r0, r1, #0, #31
	vmov	s0, r0
	pop	{r4, pc}
	.byte	0x00, 0xbf	@ padding (never reached)
.L080448dc:
	cmp.w	r12, #0x40000000
	bcc.n	.L080449bc
	nop
.L080448e4:
	add.w	r3, r0, #0x7f800000
	cmp.w	r3, #0x7f000000
	bcs.n	.L08044938
	nop
.L080448f0:
	vabs.f32	s0, s0
	vmov	r0, s0
	ubfx	r3, r1, #0x17, #8
	cmp	r3, #0x7f
	blt.n	.L0804491c
	cmp	r3, #0x97
	bge.w	.L0804457c
	rsb.w	r3, r3, #0x96
	mov.w	r12, #1
	lsl.w	r3, r12, r3
	sub.w	r12, r3, #1
	tst.w	r12, r1
	beq.n	.L0804492e
.L0804491c:
	movs	r0, #1
	bl	fn_0800788e
	vpop	{d8, d9, d10}
	pop.w	{r4, lr}
	b.w	float_return_nan
.L0804492e:
	tst	r3, r1
	it	ne
	vmovne.f32	s16, #-1.0
	b.n	.L0804457c
.L08044938:
	lsls	r3, r0, #1
	itt	ne
	movne.w	r3, #0x1000000
	cmpne.w	r3, r0, lsl #1
	bls.n	.L080449b0
	mvn	r2, #0x1a
	vldr	s3, .L080449a4
	vmul.f32	s0, s0, s3
	vmov	r0, s0
	b.n	.L080449a8
.L08044958:
	.word	0x00000000
.L0804495c:
	.word	0xc0801000
.L08044960:
	.word	0x3eaaaaab
.L08044964:
	.word	0x3d800000
.L08044968:
	.word	0x3e4ce27e
.L0804496c:
	.word	0x4238b000
.L08044970:
	.word	0xbbb89ad4
.L08044974:
	.word	0x4238aa3b
.L08044978:
	.word	d_08046318 - (.L08044674 + 4)
.L0804497c:
	.word	0x376359fc
.L08044980:
	.word	0x3a75ffc9
.L08044984:
	.word	0x3d317218
.L08044988:
	.word	d_080463d8 - (.L08044796 + 4)
.L0804498c:
	.word	d_08046418 - (.L080447a2 + 4)
.L08044990:
	.word	d_08046398 - (.L080447b2 + 4)
.L08044994:
	.word	0x42fc0000
.L08044998:
	.word	0x42fe0000
.L0804499c:
	.word	0x4b000000
.L080449a0:
	.word	0x43400000
.L080449a4:
	.word	0x4d000000
.L080449a8:
	tst.w	r0, #0x80000000
	bne.n	.L080448f0
	b.n	.L0804457c
.L080449b0:
	sub.w	r3, r0, #0x800000
	cmp.w	r3, #0x7f000000
	bcs.n	.L080449fe
	b.n	.L0804457c
.L080449bc:
	add.w	r3, r3, r1, lsl #1
	cmp.w	r3, #0x2000000
	bcc.n	.L080449ea
	vcmpe.f32	s1, #0
	vmrs	APSR_nzcv, fpscr
	bne.n	.L080449dc
	lsls	r3, r0, #1
	it	ne
	cmpne.w	r4, r0, lsl #1
	bhi.n	.L08044ac8
	b.n	.L080448e4
.L080449dc:
	and	r1, r1, #0x80000000
	orr	r1, r1, #0x1f800000
	vmov	s1, r1
	b.n	.L080448e4
.L080449ea:
	cmp.w	r3, #0x1000000
	bcs.n	.L080449fe
	vmov	r3, s1
	sub.w	r3, r3, #0x800000
	vmov	s1, r3
	b.n	.L080448e4
.L080449fe:
	bic	r2, r0, #0x80000000
	mvn	r12, #0x7f800000
	ldr	r4, .L08044b88
	add.w	r3, r2, r12
	cmp	r3, r4
	bcc.n	.L08044a32
	bic	r3, r1, #0x80000000
	add	r12, r3
	cmp	r12, r4
	bcc.n	.L08044a32
	cmp.w	r0, #0x3f800000
	it	ne
	lslsne.w	r12, r1, #1
	beq.n	.L08044ac8
	cmp.w	r2, #0x7f800000
	it	ls
	cmpls.w	r3, #0x7f800000
	bls.n	.L08044a3e
.L08044a32:
	vpop	{d8, d9, d10}
	pop.w	{r4, lr}
	b.w	L_08044e0c
.L08044a3e:
	cmp.w	r0, #0x7f800000
	beq.n	.L08044a64
	ubfx	r2, r1, #0x17, #8
	cmp	r2, #0x7f
	blt.n	.L08044a60
	cmp	r2, #0x97
	bge.n	.L08044a74
	rsb.w	r2, r2, #0x96
	movs	r3, #1
	lsl.w	r2, r3, r2
	subs	r3, r2, #1
	tst	r3, r1
	beq.n	.L08044a6c
.L08044a60:
	movs	r2, #0
	b.n	.L08044a76
.L08044a64:
	tst.w	r1, #0x80000000
	bne.n	.L08044b16
	b.n	.L08044abe
.L08044a6c:
	tst	r2, r1
	it	ne
	movne	r2, #1
	bne.n	.L08044a76
.L08044a74:
	movs	r2, #2
.L08044a76:
	cmn.w	r0, #0x800000
	beq.n	.L08044aa4
	cbz	r0, .L08044aca
	cmp.w	r0, #0x80000000
	beq.n	.L08044ad2
	cmn.w	r0, #0x40800000
	beq.n	.L08044b2a
	mov.w	r2, #0x7f000000
	cmp.w	r2, r0, lsl #1
	ite	ls
	movls	r0, #1
	movhi	r0, #0
	movs	r2, #1
	add.w	r1, r2, r1, asr #31
	cmp	r0, r1
	bne.n	.L08044b16
	b.n	.L08044abe
.L08044aa4:
	tst.w	r1, #0x80000000
	beq.n	.L08044ab0
	cmp	r2, #1
	beq.n	.L08044b20
	b.n	.L08044b16
.L08044ab0:
	cmp	r2, #1
	ittt	eq
	vldreq	s0, .L08044b8c
	vpopeq	{d8, d9, d10}
	popeq	{r4, pc}
.L08044abe:
	vldr	s0, .L08044b90
	vpop	{d8, d9, d10}
	pop	{r4, pc}
.L08044ac8:
	b.n	.L08044b2a
.L08044aca:
	tst.w	r1, #0x80000000
	bne.n	.L08044aea
	b.n	.L08044b16
.L08044ad2:
	cmp.w	r1, #0x7f800000
	beq.n	.L08044b16
	cmn.w	r1, #0x800000
	beq.n	.L08044aea
	tst.w	r1, #0x80000000
	beq.n	.L08044b10
	cbz	r2, .L08044aea
	cmp	r2, #1
	beq.n	.L08044afc
.L08044aea:
	movs	r0, #2
	bl	fn_0800788e
	vpop	{d8, d9, d10}
	pop.w	{r4, lr}
	b.w	fn_08044df8
.L08044afc:
	movs	r0, #2
	bl	fn_0800788e
	bl	fn_08044df8
	vpop	{d8, d9, d10}
	vneg.f32	s0, s0
	pop	{r4, pc}
.L08044b10:
	cbz	r2, .L08044b16
	cmp	r2, #1
	beq.n	.L08044b20
.L08044b16:
	vmov.f32	s0, s19
	vpop	{d8, d9, d10}
	pop	{r4, pc}
.L08044b20:
	vpop	{d8, d9, d10}
	vldr	s0, .L08044b94
	pop	{r4, pc}
.L08044b2a:
	vpop	{d8, d9, d10}
	vmov.f32	s0, #1.0
	pop	{r4, pc}
.L08044b34:
	vsub.f32	s0, s0, s2
	vmov.f32	s2, #0.25
	vldr	s4, .L08044b9c
	vmls.f32	s6, s0, s2
	vmov.f32	s2, #0.5
	vmul.f32	s3, s0, s0
	vmls.f32	s2, s0, s6
	vnmul.f32	s3, s3, s2
	vldr	s2, .L08044b98
	vmul.f32	s2, s0, s2
	vmul.f32	s0, s0, s4
	vldr	s4, .L08044ba0
	vmla.f32	s0, s3, s4
	vadd.f32	s3, s2, s0
	vmov	r0, s3
	add.w	r0, r0, #0x800
	bfc	r0, #0, #12
	vmov	s18, r0
	vsub.f32	s2, s2, s18
	vadd.f32	s20, s2, s0
	b.n	.L080446c0
	.short	0x0000	@ padding
.L08044b88:
	.word	0x003fffff
.L08044b8c:
	.word	0xff800000
.L08044b90:
	.word	0x7f800000
.L08044b94:
	.word	0x80000000
.L08044b98:
	.word	0x41b8b000
.L08044b9c:
	.word	0xbb389ad4
.L08044ba0:
	.word	0x41b8aa3b

@ ----------------------------------------------------------------------------
@ double_sqrt_checked - square root of a 64-bit float with the NaN error report.
@ Takes a 64-bit float in VFP register d0 (s0/s1), moves it to r0/r1 (vmov at
@ 0x08044bb4), calls 080459fc (double_sqrt) and returns the 64-bit result in d0
@ (s0/s1). After the call: if the result is a NaN (0x7ff00000 - ((low != 0) |
@ (high & 0x7fffffff)) is negative) and the input is not a NaN (same test on the input
@ is not negative) it calls 0800788e(1). The result is returned unchanged. Same body as
@ 08044e6a, which uses r0/r1 for input and output instead of d0.
@ ----------------------------------------------------------------------------
	.section .text.double_sqrt_checked,"ax",%progbits
	.global double_sqrt_checked
	.thumb_func
	.type double_sqrt_checked, %function
double_sqrt_checked:
	push	{lr}
	vpush	{d8, d9}
	vmov.f32	s18, s0
	vmov.f32	s19, s1
	sub	sp, #0xc
	vmov	r0, r1, d9
	bl	double_sqrt
	vmov	d8, r0, r1
	vmov	r0, s16
	vmov	r1, s17
	vstr	d8, [sp]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	orrs	r0, r1
	bic	r0, r0, #0x80000000
	rsb.w	r0, r0, #0xff00000
	add.w	r0, r0, #0x70000000
	lsrs	r0, r0, #0x1f
	beq.n	.L08044c0e
	vmov	r1, s18
	vmov	r0, s19
	vstr	d9, [sp]
	cmp	r1, #0
	it	ne
	movne	r1, #1
	orrs	r0, r1
	bic	r0, r0, #0x80000000
	rsb.w	r0, r0, #0xff00000
	add.w	r0, r0, #0x70000000
	lsrs	r0, r0, #0x1f
	itt	eq
	moveq	r0, #1
	bleq	fn_0800788e
.L08044c0e:
	vmov.f32	s0, s16
	add	sp, #0xc
	vmov.f32	s1, s17
	vpop	{d8, d9}
	pop	{pc}

@ ----------------------------------------------------------------------------
@ sqrt_f32_checked - square root of a 32-bit float with the NaN error report.
@ Takes a 32-bit float (s0); computes the VFP square root of it and returns it
@ (s0). If 0x7f800000 - |result bits| is negative (result is a NaN) and 0x7f800000 -
@ |input bits| is not negative (input is not a NaN) it calls 0800788e with r0 = 1.
@ ----------------------------------------------------------------------------
	.section .text.sqrt_f32_checked,"ax",%progbits
	.global sqrt_f32_checked
	.thumb_func
	.type sqrt_f32_checked, %function
sqrt_f32_checked:
	push	{r4, lr}
	vpush	{d8}
	vsqrt.f32	s16, s0
	vmov	r0, s16
	bic	r0, r0, #0x80000000
	rsb.w	r0, r0, #0x7f800000
	lsrs	r0, r0, #0x1f
	beq.n	.L08044c4e
	vmov	r0, s0
	bic	r0, r0, #0x80000000
	rsb.w	r0, r0, #0x7f800000
	lsrs	r0, r0, #0x1f
	itt	eq
	moveq	r0, #1
	bleq	fn_0800788e
.L08044c4e:
	vmov.f32	s0, s16
	vpop	{d8}
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ double_poly_eval - Horner evaluation of a polynomial of 64-bit floats.
@ Takes r0 = pointer to an array of 64-bit floats a[0..n-1], r1 = element count n,
@ d0 = a 64-bit float x (copied to d8 at 0x08044c66 and moved to r2:r3 as the
@ multiplier before every 0804577c call). Starts with the running value a[n-1]
@ (index = n-1); while (index & 0xfffffff9) != 0 each step multiplies the running
@ value by x with 0804577c (double_mul), decrements the index and adds a[index] with
@ 08044fac (double_add). The loop ends when the index is 0, 2, 4 or 6: index 6, 4 and
@ 2 enter an unrolled tail of the same multiply-by-x (0804577c) and add (08044fac)
@ pairs over a[5], a[4], a[3], a[2], a[1], a[0] (6 runs all six pairs, 4 the last
@ four, 2 the last two); index 0 returns directly. Returns the running 64-bit float
@ in d0 (vmov d0,r0,r1 at 0x08044d4a, the loop value for index 0).
@ ----------------------------------------------------------------------------
	.section .text.double_poly_eval,"ax",%progbits
	.global double_poly_eval
	.thumb_func
	.type double_poly_eval, %function
double_poly_eval:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	vpush	{d8}
	subs	r5, r1, #1
	add.w	r0, r0, r5, lsl #3
	vmov.f32	s16, s0
	vmov.f32	s17, s1
	vldr	d0, [r0]
	bics	r0, r5, #6
	beq.n	.L08044ca8
.L08044c78:
	vmov	r2, r3, d8
	vmov	r0, r1, d0
	bl	double_mul
	vmov	d0, r0, r1
	.inst.n	0x1e6d	@ subs r5, r5, #1
	add.w	r0, r4, r5, lsl #3
	vldr	d1, [r0]
	vmov	r0, r1, d0
	vmov	r2, r3, d1
	bl	double_add
	vmov	d0, r0, r1
	bics	r0, r5, #6
	bne.n	.L08044c78
.L08044ca8:
	cmp	r5, #2
	beq.n	.L08044d1a
	cmp	r5, #4
	beq.n	.L08044cea
	cmp	r5, #6
	itt	ne
	vpopne	{d8}
	popne	{r4, r5, r6, pc}
	vmov	r2, r3, d8
	vmov	r0, r1, d0
	bl	double_mul
	vldr	d1, [r4, #0x28]
	vmov	r2, r3, d1
	bl	double_add
	vmov	r2, r3, d8
	bl	double_mul
	vldr	d1, [r4, #0x20]
	vmov	r2, r3, d1
	bl	double_add
	vmov	d0, r0, r1
.L08044cea:
	vmov	r2, r3, d8
	vmov	r0, r1, d0
	bl	double_mul
	vldr	d1, [r4, #0x18]
	vmov	r2, r3, d1
	bl	double_add
	vmov	r2, r3, d8
	bl	double_mul
	vldr	d0, [r4, #0x10]
	vmov	r2, r3, d0
	bl	double_add
	vmov	d0, r0, r1
.L08044d1a:
	vmov	r2, r3, d8
	vmov	r0, r1, d0
	bl	double_mul
	vldr	d1, [r4, #8]
	vmov	r2, r3, d1
	bl	double_add
	vmov	r2, r3, d8
	bl	double_mul
	vldr	d1, [r4]
	vmov	r2, r3, d1
	bl	double_add
	vpop	{d8}
	vmov	d0, r0, r1
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_08044d50 - returns the 64-bit +infinity value of the error paths.
@ No parameters; calls 08045124 (double_div) with first operand r0:r1 = 0:0x3ff00000
@ (1.0) and second operand r2:r3 = 0:0 (zero) and returns its result in r0/r1 (and d0):
@ 08045124 returns +infinity 0x7ff00000:0 for a finite nonzero dividend and a zero
@ divisor (sign from r1 XOR r3). Used as the +infinity value of the error paths in
@ 080438e0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08044d50,"ax",%progbits
	.global fn_08044d50
	.thumb_func
	.type fn_08044d50, %function
fn_08044d50:
	vldr	d0, .L08044d70
	push	{r4, lr}
	vmov	r2, r3, d0
	vldr	d0, .L08044d78
	vmov	r0, r1, d0
	bl	double_div
	vmov	d0, r0, r1
	pop	{r4, pc}
	.word	0x00000000	@ padding
.L08044d70:
	.word	0x00000000, 0x00000000	@ 0.0
.L08044d78:
	.word	0x00000000, 0x3ff00000	@ 1.0

@ ----------------------------------------------------------------------------
@ double_add_vfp_regs - adds the doubles in d0 and d1, sum returned in d0.
@ vmov r2,r3,d1 and vmov r0,r1,d0 (0x08044d82/0x08044d86) move them to the integer
@ registers (r0:r1 first operand, r2:r3 second), bl 08044fac (double_add), vmov
@ d0,r0,r1 (0x08044d8e), pop {r4,pc}. Entered by: b.w at 0x08043982 in double_pow
@ 080438e0, after that code reloaded d1 from [sp+0x90] and d0 from [sp+0x88]
@ (0x0804396e/0x08043972) and popped its frame (pop {r4-r8,sl,fp,lr} at 0x0804397e),
@ so lr is double_pow's caller and the result d0 is returned to it. Previous bytes
@ 0x08044d7c..0x08044d7f are data (0x3ff00000 half of a constant), no fall-in.
@ The code at 08044d98 (after 4 padding bytes) loads the double at 08044db0 (0.0)
@ into d0, copies it to r2:r3 and r0:r1, calls 08045124 (double_div) and returns the
@ quotient in d0.
@ ----------------------------------------------------------------------------
	.section .text.double_add_vfp_regs,"ax",%progbits
	.global double_add_vfp_regs
	.thumb_func
	.type double_add_vfp_regs, %function
double_add_vfp_regs:
	push	{r4, lr}
	vmov	r2, r3, d1
	vmov	r0, r1, d0
	bl	double_add
	vmov	d0, r0, r1
	pop	{r4, pc}
	.word	0x00000000	@ padding
	.global	L_08044d98
	.thumb_func
L_08044d98:				@ reached by b.w from double_pow (math_rt_29)
	vldr	d0, .L08044db0
	push	{r4, lr}
	vmov	r2, r3, d0
	vmov	r0, r1, d0
	bl	double_div
	vmov	d0, r0, r1
	pop	{r4, pc}
.L08044db0:
	.word	0x00000000, 0x00000000	@ 0.0

@ ----------------------------------------------------------------------------
@ fn_08044db8 - returns the 64-bit +infinity from an overflowing multiply.
@ No parameters; calls 0804577c (double_mul) with both operands equal to
@ 0x70000000:00000000 (r0=0, r1=0x70000000, r2=0, r3=0x70000000, about 2^769) and
@ returns the product in r0/r1 (and d0): the product overflows and 0804577c returns
@ +infinity 0x7ff00000:0. Used by the overflow paths of 080438e0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08044db8,"ax",%progbits
	.global fn_08044db8
	.thumb_func
	.type fn_08044db8, %function
fn_08044db8:
	vldr	d0, .L08044dd0
	push	{r4, lr}
	vmov	r2, r3, d0
	vmov	r0, r1, d0
	bl	double_mul
	vmov	d0, r0, r1
	pop	{r4, pc}
.L08044dd0:
	.word	0x00000000, 0x70000000	@ 2^769

@ ----------------------------------------------------------------------------
@ fn_08044dd8 - returns 64-bit zero from an underflowing multiply.
@ No parameters; calls 0804577c (double_mul) with both operands equal to
@ 0x10000000:00000000 (r0=0, r1=0x10000000, about 2^-767) and returns the product in
@ r0/r1 (and d0): the product underflows and 0804577c returns signed zero (0). Used by
@ the underflow path of 080438e0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08044dd8,"ax",%progbits
	.global fn_08044dd8
	.thumb_func
	.type fn_08044dd8, %function
fn_08044dd8:
	vldr	d0, .L08044df0
	push	{r4, lr}
	vmov	r2, r3, d0
	vmov	r0, r1, d0
	bl	double_mul
	vmov	d0, r0, r1
	pop	{r4, pc}
.L08044df0:
	.word	0x00000000, 0x10000000	@ 2^-767

@ ----------------------------------------------------------------------------
@ fn_08044df8 - returns single-precision +infinity from 1.0 / 0.0.
@ No parameters. Loads s1 = 0 from the literal at 0x08044e08, s2 = 1.0 (vmov.f32 #1.0
@ at 0x08044dfc), computes s0 = s2 / s1 with vdiv.f32 (0x08044e00), which gives
@ +infinity 0x7f800000 and sets the divide-by-zero flag, and returns it in s0 (bx lr at
@ 0x08044e04). The two instructions at 0x08044e0c (vadd.f32 s0,s0,s1; bx lr) return
@ s0 + s1; float_pow reaches them with b.w for its NaN operands.
@ ----------------------------------------------------------------------------
	.section .text.fn_08044df8,"ax",%progbits
	.global fn_08044df8
	.thumb_func
	.type fn_08044df8, %function
fn_08044df8:
	vldr	s1, .L08044e08
	vmov.f32	s2, #1.0
	vdiv.f32	s0, s2, s1
	bx	lr
	.short	0x0000	@ padding
.L08044e08:
	.word	0x00000000
	.global L_08044e0c
	.thumb_func
L_08044e0c:
	vadd.f32	s0, s0, s1
	bx	lr
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ float_return_nan - returns the default quiet NaN in s0.
@ s1 = word at 08044e20 (0x00000000 = 0.0f, vldr at 08044e14), s0 = s1/s1 (vdiv.f32
@ at 08044e18) = 0.0/0.0 = default quiet NaN 0x7fc00000, bx lr; returns the NaN in s0,
@ clobbers s1 and sets the FPSCR invalid-operation flag through the 0/0. Entered from:
@ float_remainder_sign_fixup by b.w at 080438da and float_pow by b.w at 0804492a (both
@ are tail branches, so lr is the caller's return address; before each branch the
@ caller does movs r0,#1 and bl 0800788e (080438cc/080438ce, 0804491c/0804491e), then
@ vpop and pop.w {r4,lr} (080438d2..080438d6, 08044922..08044926)). Expects on entry:
@ nothing (inputs ignored), lr = return address.
@ ----------------------------------------------------------------------------
	.section .text.float_return_nan,"ax",%progbits
	.global float_return_nan
	.thumb_func
	.type float_return_nan, %function
float_return_nan:
	vldr	s1, .L08044e20
	vdiv.f32	s0, s1, s1
	bx	lr
	.short	0x0000	@ padding
.L08044e20:
	.word	0x00000000

@ ----------------------------------------------------------------------------
@ fn_08044e24 - returns single-precision +infinity from an overflowing multiply.
@ No parameters. Loads s0 = 0x70000000 (literal at 0x08044e30), computes s0 = s0 * s0
@ with vmul.f32 (0x08044e28), which overflows to +infinity 0x7f800000 and sets the
@ overflow flag, returns it in s0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08044e24,"ax",%progbits
	.global fn_08044e24
	.thumb_func
	.type fn_08044e24, %function
fn_08044e24:
	vldr	s0, .L08044e30
	vmul.f32	s0, s0, s0
	bx	lr
	.short	0x0000	@ padding
.L08044e30:
	.word	0x70000000

@ ----------------------------------------------------------------------------
@ fn_08044e34 - returns single-precision 0 from an underflowing multiply.
@ No parameters. Loads s0 = 0x10000000 (literal at 0x08044e40), computes s0 = s0 * s0
@ with vmul.f32 (0x08044e38), which underflows to 0 and sets the underflow flag,
@ returns it in s0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08044e34,"ax",%progbits
	.global fn_08044e34
	.thumb_func
	.type fn_08044e34, %function
fn_08044e34:
	vldr	s0, .L08044e40
	vmul.f32	s0, s0, s0
	bx	lr
	.short	0x0000	@ padding
.L08044e40:
	.word	0x10000000

@ ----------------------------------------------------------------------------
@ abs_f64_08044e52 - absolute value of a 64-bit float in r0:r1.
@ Takes the 64-bit float in r0 (low) / r1 (high), stores r1 & 0x7fffffff over the
@ high word on the stack (0x08044e58), reloads it into d0 and returns it in r0/r1
@ (vmov r0,r1,d0 at 0x08044e64): the value with bit 63 cleared (absolute value).
@ ----------------------------------------------------------------------------
	.section .text.abs_f64_08044e52,"ax",%progbits
	.global abs_f64_08044e52
	.thumb_func
	.type abs_f64_08044e52, %function
abs_f64_08044e52:
	sub	sp, #8
	strd	r0, r1, [sp]
	bic	r0, r1, #0x80000000
	str	r0, [sp, #4]
	vldr	d0, [sp]
	add	sp, #8
	vmov	r0, r1, d0
	bx	lr

@ ----------------------------------------------------------------------------
@ double_sqrt_checked_08044e6a - square root of a 64-bit float in r0:r1 with the
@ NaN error report.
@ Takes a 64-bit float in r0 (low) / r1 (high), calls 080459fc (double_sqrt) on it and
@ returns the 64-bit result in r0/r1 (via d8, vmov at 0x08044e7a and 0x08044ecc). If
@ the result is a NaN (0x7ff00000 - ((low != 0) | (high & 0x7fffffff)) is negative) and
@ the input is not a NaN (same test on the input is not negative) it calls
@ 0800788e(1). Same checks as 08044ba4, which takes and returns the value in d0.
@ ----------------------------------------------------------------------------
	.section .text.double_sqrt_checked_08044e6a,"ax",%progbits
	.global double_sqrt_checked_08044e6a
	.thumb_func
	.type double_sqrt_checked_08044e6a, %function
double_sqrt_checked_08044e6a:
	push	{lr}
	vpush	{d8, d9}
	sub	sp, #0xc
	vmov	d9, r0, r1
	bl	double_sqrt
	vmov	d8, r0, r1
	vmov	r0, s16
	vmov	r1, s17
	vstr	d8, [sp]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	orrs	r0, r1
	bic	r0, r0, #0x80000000
	rsb.w	r0, r0, #0xff00000
	add.w	r0, r0, #0x70000000
	lsrs	r0, r0, #0x1f
	beq.n	.L08044ecc
	vmov	r1, s18
	vmov	r0, s19
	vstr	d9, [sp]
	cmp	r1, #0
	it	ne
	movne	r1, #1
	orrs	r0, r1
	bic	r0, r0, #0x80000000
	rsb.w	r0, r0, #0xff00000
	add.w	r0, r0, #0x70000000
	lsrs	r0, r0, #0x1f
	itt	eq
	moveq	r0, #1
	bleq	fn_0800788e
.L08044ecc:
	vmov	r0, r1, d8
	add	sp, #0xc
	vpop	{d8, d9}
	pop	{pc}

@ ----------------------------------------------------------------------------
@ negate_f64 - flips the sign of a 64-bit float in r0:r1.
@ Inverts bit 31 of r1 (eor.w r1,r1,#0x80000000 at 0x08044f30) and returns (bx lr at
@ 0x08044f34); with a 64-bit float in r0 (low) / r1 (high) this flips its sign bit;
@ r0 is unchanged.
@ ----------------------------------------------------------------------------
	.section .text.negate_f64,"ax",%progbits
	.global negate_f64
	.thumb_func
	.type negate_f64, %function
negate_f64:
	eor	r1, r1, #0x80000000
	bx	lr

@ ----------------------------------------------------------------------------
@ negate_f32 - flips the sign of a 32-bit float in r0.
@ Returns r0 XOR 0x80000000 (flips the sign bit of a 32-bit float). Marked unreached:
@ no flow or pointer to this address was found.
@ ----------------------------------------------------------------------------
	.section .text.negate_f32,"ax",%progbits
	.global negate_f32
	.thumb_func
	.type negate_f32, %function
negate_f32:
	eor	r0, r0, #0x80000000
	bx	lr

@ ----------------------------------------------------------------------------
@ abs_f64_08044f3c - clears the sign of a 64-bit float in r0:r1.
@ Clears bit 31 of r1 (bic.w r1,r1,#0x80000000 at 0x08044f3c) and returns (bx lr at
@ 0x08044f40); with a 64-bit float in r0 (low) / r1 (high) this clears its sign bit;
@ r0 is unchanged.
@ ----------------------------------------------------------------------------
	.section .text.abs_f64_08044f3c,"ax",%progbits
	.global abs_f64_08044f3c
	.thumb_func
	.type abs_f64_08044f3c, %function
abs_f64_08044f3c:
	bic	r1, r1, #0x80000000
	bx	lr

@ ----------------------------------------------------------------------------
@ abs_f32 - clears the sign of a 32-bit float in r0.
@ Returns r0 AND 0x7fffffff (clears the sign bit of a 32-bit float). Marked unreached:
@ no flow or pointer to this address was found.
@ ----------------------------------------------------------------------------
	.section .text.abs_f32,"ax",%progbits
	.global abs_f32
	.thumb_func
	.type abs_f32, %function
abs_f32:
	bic	r0, r0, #0x80000000
	bx	lr

@ ----------------------------------------------------------------------------
@ double_to_float - converts a 64-bit float (r0 = low word, r1 = high word) to a
@ 32-bit float returned in r0.
@ r2 = (r1 & 0x7fffffff) - 0x38000000 (exponent rebias by 0x380 in the high word,
@ 08044f50), r3 = r1 & 0x80000000; if r2 >= 0x100000 and 0x0ff00000 - r2 does not
@ borrow or equal zero (cmp at 08044f54, rsbs ip,r2,#0x0ff00000 at 08044f5a, bls.n
@ 08044f78 at 08044f5e), i.e. r2 is in 0x100000..0x0feffffff, it builds sign (r3) |
@ r2*8 plus (r0 >> 29) plus a rounding bit taken from r0 bit 28 (adc at 08044f68),
@ returns at once when the low 28 bits of r0 are not all zero (bxne at 08044f6e), and
@ on an exact tie (low 28 bits zero with the round bit set) clears the lowest result
@ bit (08044f72). Otherwise at 08044f78: if r2 < 0x100000 (signed, cmp at 08044f78)
@ it returns only the sign bit (movlt r0,r3 / bxlt lr, zero); else if r1 << 1 >=
@ 0xffe00000 (cmn at 08044f86; all-ones exponent field) bcs.n 08044f92 at 08044f8a
@ branches to double_to_float_special_case (push {r4,r5,r6,lr}; bl 080458d0 at
@ 08044f94 with the inline word 0x89000000 at 08044f98, a dispatcher that never
@ returns to 08044f98 but enters one of the slots below); otherwise (finite value too
@ large) mov r0,r1 (08044f8c) and b.w 08046014 (08044f8e), which returns
@ ((r0>>23) | 0xff) << 23, a signed infinity.
@ ----------------------------------------------------------------------------
	.section .text.double_to_float,"ax",%progbits
	.global double_to_float
	.thumb_func
	.type double_to_float, %function
double_to_float:
	bic	r2, r1, #0x80000000
	and	r3, r1, #0x80000000
	sub.w	r2, r2, #0x38000000
	cmp.w	r2, #0x100000
	it	cs
	rsbscs.w	r12, r2, #0xff00000
	bls.n	.L08044f78
	lsls.w	r12, r0, #4
	orr.w	r2, r3, r2, lsl #3
	adc.w	r0, r2, r0, lsr #29
	it	ne
	bxne	lr
	it	cs
	biccs	r0, r0, #1
	bx	lr
.L08044f78:
	cmp.w	r2, #0x100000
	itt	lt
	movlt	r0, r3
	bxlt	lr
	lsl.w	r12, r1, #1
	cmn.w	r12, #0x200000
	bcs.n	double_to_float_special_case
.L08044f8c:
	mov	r0, r1
	b.w	L_08046014

@ ----------------------------------------------------------------------------
@ double_to_float_special_case - infinity / NaN exit of double_to_float 08044f48.
@ Stub with push {r4,r5,r6,lr}; bl 080458d0 (double_special_dispatch) and the inline
@ word 0x89000000 at 0x08044f98; never returns to the call. Word bit31 is set (the
@ second operand is not tested), fields 0 for classes 0..7 and 1 for class 8 (first
@ operand r0:r1 is a NaN). Slot 0 (0x08044f9c, any infinity): b.w 08044f8c = mov r0,r1;
@ b.w 08046014, which returns r0 = ((r1 >> 23) | 0xff) << 23, a 32-bit infinity with
@ the sign of r1. Slot 1 (0x08044fa0, NaN): r0 = 0x7fc00000, bx lr. Entered by: bcs.n
@ at 0x08044f8a (after lsl.w ip,r1,#1 and cmn.w ip,#0x200000 at 0x08044f82/0x08044f86:
@ carry when the exponent field of r1 is 0x7ff). Entry state: r0 = low word, r1 = high
@ word of the double; the dispatcher does not test r2:r3 (bit31 set); lr = caller of
@ double_to_float; the dispatcher pops r4,r5,r6,lr itself.
@ ----------------------------------------------------------------------------
	.global double_to_float_special_case
	.thumb_func
	.type double_to_float_special_case, %function
double_to_float_special_case:
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.word	0x89000000	@ inline word for 080458d0: fields 0=0 1=0 2=0 3=0 4=0 5=0 6=0 7=0 8=1, bit31=1
	b.w	.L08044f8c	@ slot 0
	mov.w	r0, #0x80000000	@ slot 1
	sub.w	r0, r0, #0x400000
	bx	lr
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ double_add - adds two 64-bit floats (first r0 low / r1 high, second r2 low / r3
@ high) and returns the 64-bit float sum in r0/r1.
@ Its own body is only 16 bytes: push {r4,lr} (08044fac), teq r1,r3 (08044fae), and
@ when the signs differ (N set) eor r3,r3,#0x80000000 (08044fb4) and bmi.w 08045ba4
@ (08044fb8). The signs-differ path therefore leaves this function for
@ double_sub_same_sign 08045ba4 (the magnitude-subtract body, shared with double_sub
@ 08045b94, which orders the operands by magnitude, shifts the smaller mantissa right
@ by the exponent difference, subtracts, renormalises with clz and rounds to
@ nearest-even, and pops r4,lr itself). When the signs are equal bmi.w is not taken
@ and execution falls through from 08044fbb to double_add_same_sign at 08044fbc (the
@ magnitude-add body, which adds the aligned mantissas, rounds to nearest-even, returns
@ signed infinity through 0804596c on exponent overflow, handles exponent field 0x7ff
@ or a zero second operand by returning the operand or calling dispatcher 080458d0, and
@ pops r4,lr itself). The 0x20 / 0x1e / 0x1f shift-count tests, mask 0xffe00000,
@ carry-out shift and rounding are in those two functions, not in this body.
@ ----------------------------------------------------------------------------
	.section .text.double_add,"ax",%progbits
	.p2align 2
	.global double_add
	.thumb_func
	.type double_add, %function
double_add:
	push	{r4, lr}
	teq.w	r1, r3
	it	mi
	eormi	r3, r3, #0x80000000
	bmi.w	double_sub_same_sign

@ ----------------------------------------------------------------------------
@ double_add_same_sign - magnitude-add body of the 64-bit float addition.
@ a=r0(lo):r1(hi), b=r2(lo):r3(hi) with equal sign bits; returns the rounded sum in
@ r0:r1. Swap so a is the larger encoded value: subs r4,r0,r2 / sbcs r12,r1,r3
@ (08044fbc..08044fcc, swap when borrow); r4=r1>>20, r12=r4-(r3>>20) = exponent
@ difference (08044fd0/08044fd4), lr=mask 0xffe00000 from 080450f8. If b exponent
@ field is 0 or a exponent is 0x7ff (tst/teq at 08044fdc..08044fe2, beq.w 080450d2):
@ a exponent 0x7ff pops r4/lr, push {r4,r5,r6,lr}, bl 080458d0 with inline word
@ 0x3EBEFB64 at 080450f4 and never continues here; otherwise returns a (r0:r1=0 with
@ the sign kept when a exponent is also 0, 080450e2/080450e6). Else mantissa of b =
@ (r3 & 0x1fffff)|0x100000 (08044fee/08044ff2); exponent difference <= 0x20 (rsbs
@ lr,r12,#0x20, bcc 08045062 otherwise): r0+=r2>>r12, r1+=r3>>r12 with carry,
@ r0+=r3<<(32-r12), then carry into r1 (08044ffc..0804501c); r1>=0x100000 goes to the
@ carry-out shift-right-by-one at 0804508c (rrxs r0), else r1+=r4<<20 and round bit =
@ r2<<(32-r12) sign (0804502a, bx.pl lr after pop.w {r4,lr}); round-up adds 1 to r0
@ (08045036); difference > 0x20 (08045062): sticky r2 = (r3*2)+(r2!=0), r12-=0x20,
@ r3>>r12 added when r12<=31. The rounding tie case is fn_08045042 (08045042..0804504d,
@ tie-to-even finish, which then falls into fn_0804504e, the exponent-overflow test
@ and return): this body reaches it by falling through after bxne lr at 08045040 (not
@ taken when Z is set) and by b.n 08045042 at 080450ac (after pop.w {r4,lr} at
@ 080450a8); the b.w 0804596c at 0804505e (signed infinity on overflow) is in
@ fn_0804504e, not in this body; the 12-byte function at 080450ae lies inside the same
@ address range and is not entered from this body. Exits of this body: bx lr at
@ 08045034, 08045040 and 080450c8 after pop.w {r4,lr}, b.n 08045042 at 080450ac,
@ b.w 0804596c at 080450ce (exponent field overflow after r1-=0x60000000, returns
@ signed infinity). Entered from: double_add by fall-through of the not-taken bmi.w at
@ 08044fb8 (signs equal), double_rsub by bmi.w at 080459ee, double_sub by bmi.w at
@ 08045ba0. Expects on entry: r0:r1 = a, r2:r3 = b with equal sign bits (callers flip
@ r1 or r3 with eor 0x80000000 first), stack top = r4 and lr pushed by the caller
@ entry (push {r4,lr} at 08044fac, 080459e4, 08045b94) and popped here by pop.w
@ {r4,lr}; flags from the caller are not used.
@ ----------------------------------------------------------------------------
	.global double_add_same_sign
	.thumb_func
	.type double_add_same_sign, %function
double_add_same_sign:
	subs	r4, r0, r2
	sbcs.w	r12, r1, r3
	bcs.n	.L08044fd0
	adds	r2, r2, r4
	adc.w	r3, r3, r12
	subs	r0, r0, r4
	sbc.w	r1, r1, r12
.L08044fd0:
	lsr.w	r4, r1, #0x14
	sub.w	r12, r4, r3, lsr #20
	ldr.w	lr, .L080450f8
	tst.w	lr, r3, lsl #1
	it	ne
	teqne.w	lr, r4, lsl #21
	beq.w	.L080450d2
	bic.w	r1, r1, r4, lsl #20
	bic.w	r3, r3, lr
	orr	r3, r3, #0x100000
	rsbs.w	lr, r12, #0x20
	bcc.n	.L08045062
	lsr.w	lr, r2, r12
	adds.w	r0, r0, lr
	lsr.w	lr, r3, r12
	adc.w	r1, r1, lr
	rsb.w	lr, r12, #0x20
	lsl.w	lr, r3, lr
	adds.w	r0, r0, lr
	rsb.w	lr, r12, #0x20
	adcs	r1, r1, #0
	cmp.w	r1, #0x100000
	bcs.n	.L0804508c
	add.w	r1, r1, r4, lsl #20
.L0804502a:
	lsls.w	r2, r2, lr
	pop.w	{r4, lr}
	it	pl
	bxpl	lr
	.inst.n	0x1c40	@ adds r0, r0, #1
	it	cc
	lslscc.w	r2, r2, #1
	it	ne
	bxne	lr

@ ----------------------------------------------------------------------------
@ fn_08045042 - tie-to-even finish of the 64-bit float rounding code.
@ cmp r0,#0; r0!=0: bic r0,r0,#1 (clear low bit); r0==0: adc.eq r1,r1,#0 (carry is
@ set by cmp, so r1+=1) (08045042..0804504a); the body ends at 0804504d without a
@ branch, so execution continues in fn_0804504e at 0804504e (r3=r1<<1; cmn
@ r3,#0x200000; bxcc lr returns r0:r1; otherwise r1-=0x60000000 and b.w 0804596c,
@ signed infinity). Entered from: fall-through from 08044fbc at 08045040 (bx.ne lr
@ not taken because Z is set: adds r0,r0,#1 at 08045036 wrapped r0 to 0, or, when it
@ did not wrap, movs.cc r2,r2,lsl #1 at 0804503a made r2 zero), b 08045042 at 080450ac
@ (in 08044fbc, after pop.w {r4,lr}) and b 08045042 at 080450b8 (code at 080450ae:
@ adds r0,r0,#1; movs.cc r2,r2,lsl #1 when no carry; bne 0804504e at 080450b6).
@ Expects on entry: r0 = low word and r1 = high word of the rounded-up result
@ (round-up already added), r4 and lr already popped, lr = return address; no flag
@ requirement. Returns r0:r1 via 0804504e.
@ ----------------------------------------------------------------------------
	.global fn_08045042
	.thumb_func
	.type fn_08045042, %function
fn_08045042:
	cmp	r0, #0
	ite	ne
	bicne	r0, r0, #1
	adceq	r1, r1, #0

@ ----------------------------------------------------------------------------
@ fn_0804504e - overflow test and return of the 64-bit float rounding code.
@ r3 = r1<<1; cmn r3,#0x200000 (carry when r3>=0xffe00000, exponent field 0x7ff);
@ carry clear: bx lr returning r0:r1 unchanged; carry set: r1-=0x60000000 (0804505a)
@ and b.w 0804596c, which returns signed infinity (only bit 31 of r1 is used there).
@ Entered from: fall-through from 08045042 and bne 0804504e at 080450b6 (code at
@ 080450ae). Expects on entry: r0 = low word, r1 = high word of the rounded result, r4
@ and lr already popped, lr = return address; no flag requirement. Purpose:
@ exponent-overflow check, proven by the 0xffe00000 test and the tail branch to
@ 0804596c. The code from 08045062 is the mantissa-shift path of the addition
@ (exponent difference above 0x20), reached by bcc.n from double_add_same_sign.
@ ----------------------------------------------------------------------------
	.global fn_0804504e
	.thumb_func
	.type fn_0804504e, %function
fn_0804504e:
	lsl.w	r3, r1, #1
	cmn.w	r3, #0x200000
	it	cc
	bxcc	lr
	sub.w	r1, r1, #0x60000000
	b.w	double_return_infinity
.L08045062:
	cmp	r2, #1
	adc.w	r2, r3, r3
	sub.w	r12, r12, #0x20
	rsbs.w	lr, r12, #0x1f
	itee	cc
	movcc.w	lr, #0
	lsrcs.w	r3, r3, r12
	addscs.w	r0, r0, r3
	adc.w	r1, r1, r4, lsl #20
	cmp.w	r4, r1, lsr #20
	beq.n	.L0804502a
	sub.w	r1, r1, r4, lsl #20
.L0804508c:
	add.w	r1, r1, #0x100000
	lsrs	r1, r1, #1
	add.w	r1, r1, r4, lsl #20
	rrxs	r0, r0
	bcc.n	.L080450ba
	adcs	r0, r0, #0
	it	cc
	lslscc.w	lr, r2, lr
	bne.n	.L080450ba
	pop.w	{r4, lr}
	b.n	fn_08045042

@ ----------------------------------------------------------------------------
@ fn_080450ae - tail fragment of the 64-bit float rounding code.
@ Takes r0 = low word, r1 = high word, r2 = rounding word; low = r0 + 1; if the add
@ carried out (low wrapped to 0) or (r2 & 0x7fffffff) == 0 it continues at 0x08045042:
@ if low == 0 the high word is incremented, else low is ANDed with 0xfffffffe (tie to
@ even); otherwise it continues at 0x0804504e. If (high << 1) < 0xffe00000 returns
@ high:low; otherwise returns signed infinity (0x7ff00000 with sign from the high
@ word). Marked unreached: no flow or pointer to this address was found. The code
@ from 080450ba is the exit of the carry-out path (pop.w {r4,lr}, the same
@ exponent-overflow test and return), the exponent-0 / exponent-0x7ff handling of
@ double_add_same_sign at 080450d2 (a exponent 0x7ff goes to 080450ea: pop.w {r4,lr},
@ push {r4,r5,r6,lr}, bl 080458d0 with the inline word 0x3EBEFB64, fields 0=4 1=4 2=5
@ 3=5 4=7 5=5 6=7 7=5 8=6, bit31=0; otherwise a is returned, as zero with its sign when
@ its exponent field is 0), the mask word 0xffe00000 read by ldr.w at 08044fd8, and
@ the slot code at 080450fc (r1 = 0x7ff80000, r0 = 0, b.w 08046164).
@ ----------------------------------------------------------------------------
	.global fn_080450ae
	.thumb_func
	.type fn_080450ae, %function
fn_080450ae:
	.inst.n	0x1c40	@ adds r0, r0, #1
	it	cc
	lslscc.w	r2, r2, #1
	bne.n	fn_0804504e
	b.n	fn_08045042
.L080450ba:
	pop.w	{r4, lr}
	lsl.w	r3, r1, #1
	cmn.w	r3, #0x200000
	it	cc
	bxcc	lr
	sub.w	r1, r1, #0x60000000
	b.w	double_return_infinity
.L080450d2:
	teq.w	lr, r4, lsl #21
	beq.n	.L080450ea
	tst.w	r1, lr, lsr #1
	pop.w	{r4, lr}
	itt	eq
	andeq	r1, r1, #0x80000000
	moveq	r0, #0
	bx	lr
.L080450ea:
	pop.w	{r4, lr}
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.word	0x3ebefb64	@ inline word for 080458d0: fields 0=4 1=4 2=5 3=5 4=7 5=5 6=7 7=5 8=6, bit31=0
.L080450f8:
	.word	0xffe00000
	.global	L_080450fc
	.thumb_func
L_080450fc:				@ inline-word slot: reached from double_compare_special_case (math_rt_31)
	ldr	r1, .L08045108
	mov.w	r0, #0
	b.w	L_08046164
	.byte	0x00, 0xbf	@ padding
.L08045108:
	.word	0x7ff80000

@ ----------------------------------------------------------------------------
@ fn_0804510c - flag-returning tail of the 64-bit float compares.
@ r1 = r1 asr 1, when the result is non-negative r1 = 0xc0000000 - r1
@ (0804510c..08045110); same for r3 (08045114..08045118); cmp r3,r1 (0804511c); mrs
@ r0,CPSR (0804511e); bx lr (08045122); returns r0 = the APSR value (N,Z,C,V in bits
@ 31..28, Q bit 27 unchanged) and leaves the flags of cmp r3,r1 set for the caller.
@ Entered from: 0804543a (stub of fn_080453d8, b.w at 0804544c), 080456ee (stub of
@ fn_0804568c, b.w at 08045700) and fn_08045766 (b.w at 08045778); the stubs reach
@ it with the original r1/r3 for non-NaN operands, or after setting r1/r3 to the fixed
@ NaN values 0x20000000/0x10000000 or 0x10000000/0x20000000. Expects on entry: r1 and
@ r3 = high words of the two operands, lr = return address of the compare function
@ (callers pop their pushed r4..r6 through 080458d0 before the slot code runs).
@ Purpose: turns the high words into order-comparable values and returns the compare
@ flags, proven by the instructions.
@ ----------------------------------------------------------------------------
	.section .text.fn_0804510c,"ax",%progbits
	.global fn_0804510c
	.thumb_func
	.type fn_0804510c, %function
fn_0804510c:
	asrs	r1, r1, #1
	it	pl
	rsbpl.w	r1, r1, #0xc0000000
	asrs	r3, r3, #1
	it	pl
	rsbpl.w	r3, r3, #0xc0000000
	cmp	r3, r1
	mrs	r0, apsr
	bx	lr

@ ----------------------------------------------------------------------------
@ double_div - divides the 64-bit float in r0 low / r1 high by the 64-bit float in r2
@ low / r3 high and returns the 64-bit float quotient in r0:r1.
@ If either operand has an all-ones exponent field ((~(high >> 4) & 0x7ff0000) == 0)
@ it calls dispatcher 080458d0 (inline word at 08045324, never returns here). If either
@ exponent field is 0: both zero gives 0x7ff80000:00000000; otherwise returns signed
@ zero (sign = r1 XOR r3 bit 31), or signed infinity when only the divisor is zero.
@ Otherwise it takes the divisor mantissa (<<11 with bit 31 forced), looks up the byte
@ table at 0x08045350 (128 bytes, adr base 0x080452d0) indexed by the top 8 bits of
@ the divisor mantissa, refines the reciprocal with several 32x32 to 64-bit multiplies
@ (Newton steps), multiplies by the dividend mantissa, normalises (shifts by one when
@ the product high word + 0x70000000 does not overflow), corrects the last bit with a
@ remainder check, rounds and rebuilds the exponent (difference + 0x3fe0000 or
@ 0x3fd0000, scaled by 16 in the high word). Overflow returns signed infinity
@ 0x7ff00000; underflow returns signed zero. Equal mantissas short-circuit to mantissa
@ 0x100000. The literal words are 0x07ff0000 (exponent mask, 080453d0) and 0x7ff80000
@ (NaN high word, 080453d4).
@ ----------------------------------------------------------------------------
	.section .text.double_div,"ax",%progbits
	.p2align 2
	.global double_div
	.thumb_func
	.type double_div, %function
double_div:
	push.w	{r6, r7, r8, lr}
	push	{r4, r5}
	ldr.w	r12, .L080453d0
	bics.w	r4, r12, r1, lsr #4
	it	ne
	bicsne.w	r4, r12, r3, lsr #4
	beq.w	.L08045316
	ands.w	r4, r12, r1, lsr #4
	eor.w	r5, r1, r3
	orr.w	r4, r4, r5, lsr #31
	it	ne
	andsne.w	r5, r12, r3, lsr #4
	beq.w	.L080452e2
	sub.w	r4, r4, r5
	add.w	r4, r4, #0x3fc0000
	add.w	r4, r4, #0x20000
	mov.w	r5, #0x80000000
	orr.w	r1, r5, r1, lsl #11
	orr.w	r3, r5, r3, lsl #11
	orr.w	r1, r1, r0, lsr #21
	orr.w	r3, r3, r2, lsr #21
	lsl.w	r0, r0, #0xb
	lsl.w	r2, r2, #0xb
	cmp	r1, r3
	it	eq
	cmpeq	r0, r2
	beq.w	.L080452be
	lsr.w	r5, r3, #0x18
	adr.w	r6, .L080452d0
	ldrb	r6, [r6, r5]
	lsr.w	r5, r3, #0x10
	mul	r7, r6, r5
	rsb.w	r7, r7, #0x1000000
	mul.w	r7, r6, r7
	lsr.w	r7, r7, #0xf
	umull	r6, r8, r7, r3
	rsbs	r6, r6, #0
	umull	r12, lr, r7, r6
	rsb.w	r8, r8, #0x10000
	it	cc
	subcc.w	r8, r8, #1
	mla	r6, r7, r8, lr
	umull	r8, r12, r6, r2
	mov.w	lr, #0
	umlal	r12, lr, r6, r3
	rsbs.w	r12, r12, #0
	rsb.w	lr, lr, #0x80000000
	it	cc
	subcc.w	lr, lr, #1
	umull	r5, r8, r6, r12
	mov.w	r7, #0
	umlal	r8, r7, r6, lr
	umull	r12, r6, r1, r8
	umull	r12, lr, r0, r7
	adds.w	r6, r6, lr
	mov.w	r5, #0
	adc	r5, r5, #0
	umlal	r6, r5, r1, r7
	adds.w	lr, r5, #0x70000000
	ittt	vc
	subvc.w	r4, r4, #0x10000
	lslsvc.w	r6, r6, #1
	adcvc	r5, r5
	adds.w	r7, r6, #0x80
	adc	r5, r5, #0
	lsr.w	r7, r7, #8
	orr.w	r7, r7, r5, lsl #24
	lsr.w	r5, r5, #8
	lsl.w	r6, r6, #0x18
	sub.w	r6, r6, #0x6f000000
	cmp.w	r6, #0x10000000
	bls.n	.L0804526c
.L0804522a:
	mov	r0, r7
	add.w	r1, r5, r4, lsl #31
	bic	r12, r4, #1
	add.w	r1, r1, r12, lsl #4
	cmp.w	r12, #0x7f00000
	bhi.n	.L08045244
	pop	{r4, r5, r6, r7}
	pop.w	{r8, pc}
.L08045244:
	tst	r4, r4
	itt	pl
	addpl.w	lr, r1, #0x100000
	teqpl.w	lr, r4, lsl #31
	bmi.n	.L08045258
	pop	{r4, r5, r6, r7}
	pop.w	{r8, pc}
.L08045258:
	tst	r4, r4
	bmi.w	.L080452d0
	sub.w	r1, r1, #0x60000000
	pop	{r4, r5, r6, r7}
	pop.w	{r8, lr}
	b.w	double_return_infinity
.L0804526c:
	lsr.w	r0, r0, #0xb
	orr.w	r0, r0, r1, lsl #21
	lsr.w	r1, r1, #0xb
	lsr.w	r2, r2, #0xb
	orr.w	r2, r2, r3, lsl #21
	lsr.w	r3, r3, #0xb
	umull	r8, r6, r7, r2
	mla	r6, r7, r3, r6
	mla	r6, r5, r2, r6
	tst.w	lr, lr
	it	pl
	subpl.w	r6, r6, r0, lsl #20
	subs.w	r6, r6, r0, lsl #20
	lsr.w	lr, r2, #1
	orr.w	lr, lr, r3, lsl #31
	adds.w	lr, r8, lr
	adcs.w	lr, r6, r3, lsr #1
	bpl.n	.L0804522a
	adds.w	r8, r8, r2
	adcs	r6, r3
	.inst.n	0x1c7f	@ adds r7, r7, #1
	adcs	r5, r5, #0
	b.n	.L0804522a
.L080452be:
	mov.w	r5, #0x100000
	mov.w	r7, #0
	mov.w	r6, #0
	mov.w	r8, #0
	b.n	.L0804522a
.L080452d0:
	add.w	r1, r1, #0x60000000
	and	r1, r1, #0x80000000
	mov.w	r0, #0
	pop	{r4, r5, r6, r7}
	pop.w	{r8, pc}
.L080452e2:
	and.w	r5, r12, r3, lsr #4
	tst.w	r1, r12, lsl #4
	beq.n	.L080452ee
	b.n	.L08045308
.L080452ee:
	tst.w	r3, r12, lsl #4
	beq.w	.L08045342
	mov.w	r0, #0
	eor.w	r1, r1, r3
	and	r1, r1, #0x80000000
	pop	{r4, r5, r6, r7}
	pop.w	{r8, pc}
.L08045308:
	pop	{r4, r5, r6, r7}
	pop.w	{r8, lr}
	eor.w	r1, r1, r3
	b.w	double_return_infinity
.L08045316:
	pop	{r4, r5, r6, r7}
	pop.w	{r8, lr}
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.byte	0x00, 0xbf	@ padding
	.word	0x3efc7e09	@ inline word for 080458d0: fields 0=1 1=1 2=0 3=7 4=7 5=0 6=7 7=7 8=6, bit31=0
	b.w	.L0804533a	@ slot 0
	mov.w	r0, #0	@ slot 1
	eor.w	r1, r1, r3
	and	r1, r1, #0x80000000
	bx	lr
.L0804533a:
	eor.w	r1, r1, r3
	b.w	double_return_infinity
.L08045342:
	pop	{r4, r5, r6, r7}
	pop.w	{r8, lr}
	ldr	r1, .L080453d4
	mov.w	r0, #0
	bx	lr
	.incbin	"assets/blobs/08045350.bin"
.L080453d0:
	.word	0x07ff0000
.L080453d4:
	.word	0x7ff80000

@ ----------------------------------------------------------------------------
@ fn_080453d8 - compares the 64-bit floats a = r0:r1 and b = r2:r3 and returns the
@ result in the CPU flags (no value register).
@ ip = r1 | r3. ip >= 0 (both non-negative): ip < 0x100000 (both exponent fields 0)
@ gives cmp r1,r1 (equal flags, 0x0804540a); ip in [0x100000, 0x7ff00000) gives cmp
@ r1,r3 and, when equal, cmp r0,r2 (0x080453ec..0x080453f4); ip >= 0x7ff00000 gives
@ cmp r1,r3 when neither r1 nor r3 alone is >= 0x7ff00000 (cmn tests at
@ 0x080453fa/0x08045400), else the branch to 0x0804543a. ip < 0 (an operand
@ negative): ip in 0x80000000..0x800fffff gives cmp r1,r1 (0x0804540a); ip >=
@ 0xfff00000 gives the branch to 0x0804543a when r1<<1 or r3<<1 is >= 0xffe00000
@ (0x0804542a..0x08045434), else cmp r3,r1 (0x08045436); other negative cases compare
@ swapped: cmp r3,r1 and, when equal, cmp r2,r0 (0x0804541a..0x08045422). 0x0804543a
@ is the unordered stub (dispatcher 080458d0). Called only from 08045dc6 (bl at
@ 0x08045dc8) and 08045dd4 (bl at 0x08045dd6); no reference or code-address value
@ leading to 08045dc6 or 08045dd4 was found.
@ ----------------------------------------------------------------------------
	.section .text.fn_080453d8,"ax",%progbits
	.global fn_080453d8
	.thumb_func
	.type fn_080453d8, %function
fn_080453d8:
	orrs.w	r12, r1, r3
	bmi.n	.L0804540e
	cmn.w	r12, #0x100000
	it	pl
	cmppl.w	r12, #0x100000
	bmi.w	.L080453f8
	cmp	r1, r3
	it	ne
	bxne	lr
	it	eq
	cmpeq	r0, r2
	bx	lr
.L080453f8:
	bvc.n	.L0804540a
	cmn.w	r1, #0x100000
	it	pl
	cmnpl.w	r3, #0x100000
	bmi.n	fn_0804543a
	cmp	r1, r3
	bx	lr
.L0804540a:
	cmp	r1, r1
	bx	lr
.L0804540e:
	cmn.w	r12, #0x100000
	bpl.n	.L08045426
	cmp.w	r12, #0x100000
	bpl.n	.L0804540a
	cmp	r3, r1
	it	ne
	bxne	lr
	it	eq
	cmpeq	r2, r0
	bx	lr
.L08045426:
	mov.w	r12, #0x200000
	cmn.w	r12, r1, lsl #1
	it	cc
	cmncc.w	r12, r3, lsl #1
	bcs.n	fn_0804543a
	cmp	r3, r1
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_0804543a - unordered tail of the double compare 080453d8.
@ Entered by bmi 0804543a at 08045404 and bcs 0804543a at 08045434: push
@ {r4,r5,r6,lr} (0804543a); bl 080458d0 (double_special_dispatch) at 0804543c with the
@ inline word 0x00492492 at 08045440 (field 2 for classes 0..7, field 0 for class 8);
@ slot 0 (08045444) sets r1 = 0x20000000, slot 1 (08045448) sets r3 = 0x10000000 and
@ slot 2 (0804544c) is b.w 0804510c. So for class 8 (a NaN operand) r1 = 0x20000000 and
@ r3 = 0x10000000 are loaded and then the b.w at 0804544c runs; for all other classes
@ the b.w at 0804544c runs with the original r1/r3. The target of that b.w is
@ fn_0804510c (0804510c..08045123), which does r1 = r1 asr 1 and, when the result is
@ non-negative, r1 = 0xc0000000 - r1, the same for r3, then cmp r3,r1; mrs r0,CPSR; bx
@ lr, so the flags of the compare come back in r0 and in the flags; for a NaN it turns
@ r1 = 0x20000000 into 0xb0000000 and r3 = 0x10000000 into 0xb8000000, so cmp r3,r1
@ finds r3 above r1. This body itself ends at the b.w (0804544c..0804544f) and has no
@ return of its own.
@ ----------------------------------------------------------------------------
	.global fn_0804543a
	.thumb_func
	.type fn_0804543a, %function
fn_0804543a:
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.word	0x00492492	@ inline word for 080458d0: fields 0..7 = 2, 8 = 0, bit31=0
	mov.w	r1, #0x20000000	@ slot 0
	mov.w	r3, #0x10000000	@ slot 1
	b.w	fn_0804510c	@ slot 2

@ ----------------------------------------------------------------------------
@ double_to_i32 - converts a 64-bit float (r0 low / r1 high) to a signed 32-bit
@ integer by truncation.
@ Takes exponent e = ((r1 & 0x7fffffff) >> 20) - 0x400 and shift = 0x1e - e
@ (08045450..0804545c); in range (shift >= 1 and shift <= 0x20: rsbsgt ip,r3,#0x21 at
@ 08045462, ble.n 08045482) it forms the mantissa (r1 << 11 | 0x80000000 | r0 >> 21),
@ shifts it right by that amount and applies the sign (r1 >> 31) by XOR and subtract
@ (08045468..0804547c, returns at 08045480). Otherwise (08045482): a shift above 0x10
@ (cmp r3,#0x10 / gt, i.e. 0x21 or more) returns 0; when shift + 0x3e0 equals -1
@ (exponent field 0x7ff, cmp at 0804548e) beq.n 0804549e at 08045492 branches to
@ double_to_i32_special_case (push {r4,r5,r6,lr}; bl 080458d0 at 080454a0, with the
@ inline word 0x80249249 at 080454a4; the dispatcher never returns to 080454a4);
@ otherwise returns 0x7fffffff (positive) or 0x80000000 (negative, (r1 >> 31) XOR
@ 0x7fffffff, 08045494..0804549c). The two slots after the inline word belong to this
@ function: 080454a8 (r0 = 0, bx lr), selected for a NaN (class 8, field 0), and
@ 080454ac (b.n 08045494, the saturated return), selected for an infinity (field 1).
@ ----------------------------------------------------------------------------
	.section .text.double_to_i32,"ax",%progbits
	.global double_to_i32
	.thumb_func
	.type double_to_i32, %function
double_to_i32:
	lsl.w	r3, r1, #1
	lsr.w	r3, r3, #0x15
	sub.w	r3, r3, #0x400
	rsbs.w	r3, r3, #0x1e
	it	gt
	rsbsgt.w	r12, r3, #0x21
	ble.n	.L08045482
	mov.w	r2, #0x80000000
	orr.w	r2, r2, r1, lsl #11
	orr.w	r2, r2, r0, lsr #21
	lsrs.w	r12, r2, r3
	eor.w	r12, r12, r1, asr #31
	sub.w	r0, r12, r1, asr #31
	bx	lr
.L08045482:
	cmp	r3, #0x10
	itt	gt
	movgt	r0, #0
	bxgt	lr
	add.w	r12, r3, #0x3e0
	cmp.w	r12, #0xffffffff
	beq.n	double_to_i32_special_case
.L08045494:
	mvn	r2, #0x80000000
	eor.w	r0, r2, r1, asr #32
	bx	lr

@ ----------------------------------------------------------------------------
@ double_to_i32_special_case - infinity / NaN exit of double_to_i32 08045450.
@ Stub with push {r4,r5,r6,lr}; bl 080458d0 (double_special_dispatch) and the inline
@ word 0x80249249 at 0x080454a4; never returns to the call. Bit31 set, field 1 for
@ classes 0..7, field 0 for class 8 (r0:r1 NaN). Slot 0 (0x080454a8, NaN): movs r0,#0;
@ bx lr, returns 0. Slot 1 (0x080454ac, infinity): b.n 0x08045494 = mvn r2,#0x80000000;
@ eor r0,r2,r1,asr #32; bx lr, returns 0x7fffffff for a positive and 0x80000000 for a
@ negative infinity. Entered by: beq.n at 0x08045492 (ip = r3 + 0x3e0 equals -1 at
@ 0x0804548a..0x0804548e, i.e. the exponent field is 0x7ff, reached after the shift
@ test cmp r3,#16 at 0x08045482). The previous instruction 0x0804549c is bx lr, no
@ fall-in. Entry state: r0 = low word, r1 = high word of the double; lr = caller of
@ double_to_i32.
@ ----------------------------------------------------------------------------
	.global double_to_i32_special_case
	.thumb_func
	.type double_to_i32_special_case, %function
double_to_i32_special_case:
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.word	0x80249249	@ inline word for 080458d0: fields 0..7 = 1, 8 = 0, bit31=1
	movs	r0, #0	@ slot 0
	bx	lr
	b.n	.L08045494	@ slot 1
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ double_to_u32 - converts a 64-bit float (r0 low / r1 high) to an unsigned 32-bit
@ integer by truncation.
@ Takes e = (r1 >> 20) - 0x400 and shift = 0x1e - e (080454b0..080454b8); in range
@ (shift 0..0x20, rsbsge ip,r3,#0x20 at 080454be, blt.n 080454d6) returns (r1 << 11 |
@ 0x80000000 | r0 >> 21) >> shift (080454c4..080454d4). Otherwise (080454d6): if r1 is
@ negative it returns 0 (bmi.n 080454f2); if shift is above 0x10 (cmp r3,#0x10 / gt,
@ i.e. 0x21 or more) it returns 0; when shift + 0x3e0 equals -1 (exponent field 0x7ff)
@ beq.n 080454f8 at 080454ea branches to double_to_u32_special_case (push
@ {r4,r5,r6,lr}; bl 080458d0 at 080454fa, with the inline word 0x80249249 at 08045500;
@ the dispatcher never returns to 08045500); otherwise returns 0xffffffff (080454ec).
@ The two slots after the inline word belong to this function: 08045504 (r0 = 0, bx
@ lr), selected for a NaN (class 8, field 0), and 08045508 (b.n 080454ec, returns
@ 0xffffffff), selected for a positive infinity (field 1).
@ ----------------------------------------------------------------------------
	.section .text.double_to_u32,"ax",%progbits
	.global double_to_u32
	.thumb_func
	.type double_to_u32, %function
double_to_u32:
	lsr.w	r3, r1, #0x14
	sub.w	r3, r3, #0x400
	rsbs.w	r3, r3, #0x1e
	it	ge
	rsbsge.w	r12, r3, #0x20
	blt.n	.L080454d6
	mov.w	r2, #0x80000000
	orr.w	r2, r2, r1, lsl #11
	orrs.w	r2, r2, r0, lsr #21
	lsrs.w	r0, r2, r3
	bx	lr
.L080454d6:
	tst	r1, r1
	bmi.n	.L080454f2
	cmp	r3, #0x10
	itt	gt
	movgt	r0, #0
	bxgt	lr
	add.w	r12, r3, #0x3e0
	cmp.w	r12, #0xffffffff
	beq.n	double_to_u32_special_case
.L080454ec:
	mov.w	r0, #0xffffffff
	bx	lr
.L080454f2:
	mov.w	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ double_to_u32_special_case - infinity / NaN exit of double_to_u32 080454b0.
@ Stub with push {r4,r5,r6,lr}; bl 080458d0 (double_special_dispatch) and the inline
@ word 0x80249249 at 0x08045500 (the halfword at 0x080454fe is a nop); never returns to
@ the call. Bit31 set, field 1 for classes 0..7, field 0 for class 8 (r0:r1 NaN). Slot
@ 0 (0x08045504, NaN): movs r0,#0; bx lr. Slot 1 (0x08045508, positive infinity only:
@ the stub is entered only for an exponent field of 0x7ff; finite values that are too
@ large fall through the beq at 0x080454ea to 0x080454ec directly): b.n 0x080454ec =
@ mov.w r0,#0xffffffff; bx lr. Entered by: beq.n at 0x080454ea (ip = r3 + 0x3e0 equals
@ -1 at 0x080454e2..0x080454e6: exponent field 0x7ff; negative values were already sent
@ to 0x080454f2, which returns 0, by the bmi at 0x080454d8). The previous instruction
@ 0x080454f6 is bx lr, no fall-in. Entry state: r0 = low word, r1 = high word of the
@ double; lr = caller of double_to_u32.
@ ----------------------------------------------------------------------------
	.global double_to_u32_special_case
	.thumb_func
	.type double_to_u32_special_case, %function
double_to_u32_special_case:
	push	{r4, r5, r6, lr}
	bl	double_special_dispatch
	.byte	0x00, 0xbf	@ padding (nop halfword)
	.word	0x80249249	@ inline word for 080458d0: fields 0..7 = 1, 8 = 0, bit31=1
	movs	r0, #0	@ slot 0
	bx	lr
	b.n	.L080454ec	@ slot 1

@ ----------------------------------------------------------------------------
@ i32_to_double - converts a signed 32-bit integer in r0 to a 64-bit float returned in
@ r0 (low) / r1 (high).
@ Saves the sign bit (r0 & 0x80000000) and negates r0 if set; returns 0 if r0 is zero;
@ otherwise shifts r0 left by LZCOUNT(r0) to normalise, high word = sign + (0x41d -
@ LZCOUNT) * 0x100000 + (normalised >> 11), low word = normalised << 21. Exact (no
@ rounding needed).
@ ----------------------------------------------------------------------------
	.section .text.i32_to_double,"ax",%progbits
	.global i32_to_double
	.thumb_func
	.type i32_to_double, %function
i32_to_double:
	ands	r2, r0, #0x80000000
	it	mi
	rsbmi	r0, r0, #0
	clz	r3, r0
	lsls.w	r1, r0, r3
	beq.n	.L08045532
	rsb.w	r3, r3, #0x1d
	add.w	r3, r3, #0x400
	add.w	r2, r2, r3, lsl #20
	lsl.w	r0, r1, #0x15
	add.w	r1, r2, r1, lsr #11
	bx	lr
.L08045532:
	mov.w	r0, #0
	bx	lr
