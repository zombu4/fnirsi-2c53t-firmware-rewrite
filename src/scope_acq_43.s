@ scope_acq_43.s - part 1 of 4 of fn_08020e98 (0x08020e98..0x08021e98): the scope acquisition state machine
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08020e98 - scope acquisition state machine (4096 bytes, written in 4 parts;
@ parts 2..4 are included at the end of this file).
@
@ No parameters, no return value (the decompiler shows two; the second is only
@ forwarded to 080438e0).
@
@ RAM tables used, by name:
@   - signed bytes 0x200000fc/0x200000fd: per-channel gain step (ch = 0/1)
@   - bytes 0x200000fa/0x200000fb: per-channel index 0..9
@   - offset bytes 0x20000448/0x20000449 and averages 0x2000044a/0x2000044b
@   - per-channel sample arrays of 301 bytes at 0x2000044e + ch*0x12d
@   - ring buffers 0x200006a8 / 0x20000aa8
@   - halfword tables of 10 entries: low 0x20000358 (T>=5) / 0x2000036c
@     (T==4 or mode 3) / 0x20000380 (else), high 0x20000394 / 0x200003a8 /
@     0x200003bc, channel 1 tables 0x78 higher
@   - the halfword table at 0x080465cc {10,20,50,100,200,500,1000,2000,5000,10000}
@
@ Names: T = byte 0x20000125, S = byte 0x20000ea8, A = byte 0x20000126,
@ M = byte 0x2000010f, mode = byte 0x2000010c (1, 2, 3). Channel nibbles:
@ segment 1 uses byte 0x2000010d, segment 3 uses byte 0x20000eb7; in both the
@ channels run from the high nibble up to below the low nibble and nothing
@ happens when high >= low.
@
@ Exits: returns at once (to 0x080224d4, no post) when byte 0x20001060 != 2; all
@ other paths end at 0x080224b2 which posts byte 3 to queue [0x20002d6c] with
@ 08041cf0 only while byte 0x20001060 is still 2 (re-read there), then returns;
@ every post uses timeout -1, targets are the queue records read from the words
@ at 0x20002d6c (bytes 2, 3, 4, 5, 6) and 0x20002d78 (bytes 1, 4, 5, 6, 8, 9).
@
@ SEGMENT 1 (A != 0, M != 2):
@ T > 0x13 -> when byte 0x20000124 == 0 calls 080251e4, 08027930, 08025aac,
@ 080266f8, then ends; ends also when byte 0x20000eb2 or 0x20000eb3 is nonzero;
@ when S == 1 it calls 080242ec, the same four calls when byte 0x20000124 == 0,
@ then switches on byte 0x20000127:
@   case 0: nothing.
@   case 1 (tick byte 0x2000012a > 0x27): per channel scans the 301 bytes of
@     0x2000044e+ch*0x12d for max/min and when max > 0xd9 or min < 0x27 and byte
@     0x200000fa+ch <= 8 increments it, calls 080088a4(byte 0x200000fa) (ch 0)
@     or 08008a58(byte 0x200000fb) (ch 1), posts byte 4 to queue [0x20002d6c],
@     clears 0x2000012a and leaves 0x20000127 unchanged; when no channel needed
@     a step (or the nibble range is empty) sets 0x20000127 = 2.
@   case 2 (0x2000012a > 99): maps the signed word at 0x20000148 + 0x30*byte
@     0x2000010e (stride 0x30 bytes) through the ladder (>=30000000 -> 0,
@     >=10000000 -> 1, >=5000000 -> 2, >=3000000 -> 3, >=1000000 -> 4,
@     >=500000 -> 5, >=300000 -> 6, >=100000 -> 7, >=50000 -> 8, >=30000 -> 9,
@     >=10000 -> 10, >=5000 -> 11, >=3000 -> 12, >=1000 -> 13, >=500 -> 14,
@     >=300 -> 15, >=100 -> 16, >=50 -> 17, >=30 -> 18, else 19) into T, posts
@     byte 2 to queue [0x20002d6c] and byte 1 to [0x20002d78], sets
@     0x20000127 = 3, writes 0x40011410 = 4, calls 08030a70, then writes
@     register 0x40007408 (low 12 bits, upper 20 bits kept) = lo + (hi-lo)/200 *
@     (signed byte 0x200000fc + 100) with lo/hi = tables [byte 0x200000fa], sets
@     bit 0 of 0x40007404, and writes word 0x40001c34 = same formula with byte
@     0x200000fd and index byte 0x200000fb.
@   case 3 (0x2000012a > 99): sets 0x2000012a = 0, 0x20000127 = 0x11.
@   other values: after 0x2000012a > 0x27 (> 199 when 0x20000127 == 0xff)
@     clears it and calls 08008c60.
@ After the switch: when 0x2000012a > 0x27 and step byte 0x20000128 != 0 it
@ clears 0x2000012a and
@  (a) for 0x20000128 in 0x30..0x39 (n = low nibble): sums the 500 bytes at
@   0x200007a2 (mode 1) or 0x20000ba2 (other) (25 groups of 20), m = sum/500 -
@   28.0 when signed byte 0x200000fc+c (c = 0 if mode == 1 else 1) == 0x9c
@   (-100) else sum/500 - 228.0, converts m with 08045d70 to double and
@   compares with 0.3 / -0.1 via 08045df0 (a>=b, used twice for the decision:
@   m >= 0.3 changes h, else m >= -0.1 is settled, else h is changed) and
@   08045e0c (a<b, used only in the later test): when m >= 0.3 or m < -0.1 the
@   halfword h at 0x200000f8 + 2*n + 0x78*c + 0x288 (low table 0x20000380 /
@   0x200003f8) when the gain byte is -100, else + 0x2c4 (high table
@   0x200003bc / 0x20000434), is changed: 0 < m < 1 -> h-1; -1 < m < 0 -> h+1;
@   |m| >= 1 -> h - m (|m| <= 1.5) or h - 8*m (|m| > 1.5), stored as
@   (short)(int); then (also when -0.1 <= m < 0.3, h unchanged) register
@   0x40007408/0x40007404 (mode 1) or word 0x40001c34 (other modes) is
@   rewritten with the same lo/hi formula for index n; then m is tested again,
@   m >= 0.3 (08045df0) or m < -0.1 (08045e0c) ends the step; when -0.1 <= m <
@   0.3 byte 0x20000128 is incremented and when its low nibble reaches 10: if
@   the gain byte was -100 it is set to 100 ('d'), 0x20000128 &= 0xf0 and the
@   outputs rewritten with index 0, otherwise byte 0x20000448+c = sum/500 +
@   0x1c (sum of the 500 bytes at 0x20000ba2 when mode is 1, else at
@   0x200007a2, 20 groups of 25) and the state moves on (mode 2: 0x20000128 =
@   0, halfword 0x2000010c = 0x0203, 0x40011410 = 4, 0x40011010 = 4,
@   0x40011014 = 2, halfword 0x200000fc = 0xce32 (fc = 0x32, fd = 0xce),
@   halfword 0x20000112 = 0, halfword 0x20000114 = signed byte at 0x200000fc +
@   byte[0x2000010e] (sign-extended), outputs rewritten with gains 150 and 50,
@   byte 8 posted to [0x20002d78], 08025fc0 called, bytes 5 and 6 posted to
@   [0x20002d6c], byte 6 to [0x20002d78]; other mode: halfword 0x2000010c =
@   0x1202, byte 6 posted to [0x20002d78], 0x20000128 = 0x30, then by byte
@   0x2000010c re-read after the post (3 -> 0x40011010 = 4 then 0x40011014 = 2,
@   2 -> 0x40011014 = 4 then 2, 1 -> 0x40011010 = 4 then 2, else nothing),
@   outputs of both channels rewritten with index 0) and in all settled cases
@   080088a4 and 08008a58 are called with 0x20000128 & 0xf;
@  (b) 0x20000128 == 1 sets it to 0x10;
@  (c) other values run a per-channel pass (ch runs from bit 7 of 0x20000128 up
@   to below 1 when bit 6 is set or below 2 when bit 6 is clear, nothing when
@   that bound <= start): same 500-byte mean m for channel ch at 0x200007a2 +
@   ch*0x400, same adjustment of a halfword at 0x200000f8 + 0x260 + 2*n +
@   0x78*ch + (gain -100: 0 or 0x14; else 0x3c or 0x50, chosen by bit 5),
@   outputs of channel ch rewritten (ch 0: 0x40007408/0x40007404, ch 1: word
@   0x40001c34, index n, tables as above), then m is tested again, m >= 0.3
@   (08045df0) or m < -0.1 (08045e0c) ends this channel; when settled (-0.1 <=
@   m < 0.3) with step < 0x40 it does 0x20000128 |= ch<<6 (no change for ch 0)
@   and ends this channel, otherwise it sets 0x20000128 = (0x20000128 & 0x3f)
@   + 1 and: low nibble != 10 -> 080088a4/08008a58 are called with the low
@   nibble; low nibble 10 and gain byte 0x200000fc+ch == 0x9c -> bytes
@   0x200000fc/fd = 0x6464 (halfword), 0x20000128 &= 0x70, outputs of both
@   channels rewritten with index 0 at gain 200 (no post), then
@   080088a4/08008a58 with 0x20000128 & 0xf; low nibble 10 and gain byte !=
@   0x9c -> bytes 0x200000fc/fd = 0x9c9c (halfword), 0x20000128 &= 0x70,
@   outputs rewritten with index 0, then when bit 5 of 0x20000128 is set:
@   0x20000128 = 0x30, T = 3, halfword 0x2000010c = 0x0101, byte 6 to
@   [0x20002d78], 0x40011410 = 4, outputs rewritten, then by byte 0x2000010c
@   re-read (3 -> 0x40011010 = 4 then 0x40011014 = 2, 2 -> 0x40011014 = 4 then
@   2, 1 -> 0x40011010 = 4 then 2); when bit 5 is clear: 0x20000128 = 0x20,
@   T = 4; both then post byte 1 to [0x20002d78] and byte 2 to [0x20002d6c]
@   and call 080088a4/08008a58 with 0x20000128 & 0xf.
@ When 0x2000012a == 0xff and byte 0x2000012b != 0: 0x2000044a = mean of 500
@ bytes at 0x200007a2, 0x2000044b = mean of 500 bytes at 0x20000ba2,
@ 0x2000012b = 0, 0x2000012a = 0.
@ Then (A != 0): 0x20000eb4 &= 0x7fff, S = 2, byte 0x20000eaa += 1; common tail
@ for S == 2 (also reached with A == 0 and S == 2, and from segment 1 with
@ S == 2 at entry): when bit 0 of word 0x40011008 is clear it calls 080242ec
@ only when byte 0x20000124 != 0 and A != 0, then ends; when bit 0 is set: when
@ halfword 0x2000010c & 1 or T < 5 sets S = 0 and posts byte 4 to [0x20002d78],
@ when T < 5 or (byte 0x2000010c & 2) sets S = 0 and posts byte 5 to
@ [0x20002d78]; if S is neither 1 nor 2 the function ends.
@
@ SEGMENT 2 (A != 0, M == 2):
@ T < 0x14: S in {1,2} -> S = 3; S == 3: reads 0x40011008: bit 0 clear ->
@ 080266f8; set -> S = 4, posts bytes 4 (halfword 0x2000010c & 1 or T < 5),
@ 5 (T < 5 or mode & 2) and 9 to [0x20002d78]; S == 6: writes 0x40011014 =
@ 0x10, word 0x20000eac = 0x012d0000, calls 080242ec, clears A, posts byte 2
@ to [0x20002d6c], calls 0803b078; then 080266f8 and end; T >= 0x14 calls
@ 080266f8 and ends (it does not enter segment 3), as does S not in
@ {1,2,3,6}.
@
@ SEGMENT 3 (A == 0 only):
@ when M != 2 and S == 1 sets S = 2 and calls 08028de4, 080266f8; ends unless
@ S == 2 (or M == 2); ends when the unsigned 64-bit value 0x20000f00/0x20000f04
@ (f00) < 10 or halfword 0x20000eae == 0.
@ Window bounds: P = 10^(T/3) as double (080455da of T/3, then 080438e0 with
@ base 10.0); S1 = (64-bit value at 0x20000ec8/0x20000ecc converted with
@ 08045538, divided by P with 08045124, truncated with 08046020) divided with
@ divide_s64 (08008732) by byte table 0x080465c8[T%3] = 1,2,5, plus 0x96;
@ E = the same chain on the 64-bit value at 0x20000ed0/0x20000ed4 without the
@ plus 0x96; start' = S1 when S1 > 0 else 0, E' = E when E < 0x97 else 0x97
@ (signed 64-bit compares), count = E' - start' + 0x96 (only the low 16 bits
@ are used below).
@ Sample decode SD(idx, ch) with a 16-bit idx: when byte 0x2000010c == 3 or
@ T > 3, 0x400 is subtracted when idx >= 0x400 and the sample is byte
@ 0x200006a8 + ch*0x400 + idx; otherwise 0x800 is subtracted when idx >= 0x800
@ and with j = idx >> 1: byte 0x2000010c == 1: even idx -> byte 0x200006a8[j],
@ odd idx -> byte 0x20000aa8[j] minus byte 0x20000448; byte 0x2000010c != 1:
@ even idx -> 0x200006a8[j] minus byte 0x20000449, odd idx -> byte
@ 0x20000aa8[j].
@ Rescale RS(s, ch) = T[byte 0x20000eb9+ch]/T[byte 0x200000fa+ch] * ((s-128) -
@ signed byte 0x20000ebb+ch) + 128 + signed byte 0x200000fc+ch in float
@ arithmetic (T = the table 0x080465cc), clamped to 28..228 and truncated
@ toward zero.
@ When f00 < 1000 (resample path): F = 5 and R = 2 when f00 == 400, else
@ F = 1000/f00 (unsigned 16-bit divide) and R = 1; D = (16-bit start') - S1
@ (signed 64-bit), rem = remainder of divide_s64(D, F), G = float(F)/float(R),
@ sx = float(D)/G;
@  case byte 0x20000eb8 < 0x14: when halfword 0x20000eb4 is negative a
@  crossing search runs first: allocate (alloc_units_of_32_bytes 0803acfc) 0x19
@  bytes and 0x19*F bytes (a failed allocation ends at 0x080224b2), copy 25
@  samples SD((0x20000eb4 & 0x7fff) + i - 7, byte 0x2000010e) for i = 0..24,
@  call 0803d5d4(out, in, 0x19, F) (documented as fir_filter_rows), and when
@  F != 0 find the first j < F where the out bytes cross the level L = byte
@  0x20000ebe ^ 0x80 according to byte 0x20000110 (0: out[j] <= L and
@  out[j+1] > L; 2: that or out[j] >= L and out[j+1] < L; any other value:
@  out[j] >= L and out[j+1] < L); the found j (0 when none) is added to O =
@  rem - halfword 0x20000ef0, then both buffers are released; when eb4 is not
@  negative O = rem - halfword 0x20000ef0; then for every channel ch of byte
@  0x20000eb7: allocate n = trunc(count/G + 23) bytes and n*F bytes (a failed
@  allocation ends at 0x080224b2), copy SD(i0 + j, ch) for j = 0..n-1 with
@  i0 = (0x20000eb4 & 0x7fff) + uxth(trunc(sx - 7)) - 0x96 - halfword
@  0x20000ec0, call 0803d5d4(out, in, n, F), and when count != 0 store
@  out[sxth(O) + j*R] for j < count to byte 0x2000044e + ch*0x12d +
@  uxth(start') + j;
@  case byte 0x20000eb8 >= 0x14: per channel allocate n = trunc(count/G + 23)
@  bytes and trunc(G*n) bytes, the n inputs are the ring bytes 0x200006a8 +
@  ch*0x400 + k + j with k = trunc(float(halfword 0x20000ed8) + sx - 7) (0x12d
@  added to the index when it is negative), call 0803d5d4(out, in, n, F), and
@  store out[rem + j*R] for j < count to the same sample array positions;
@ after the channel loop both buffers are released (inline release: the unit
@ table of the structure at 0x20001070 is cleared with zero_bytes 080082bc, or
@ the function pointer at 0x20001070 is called with 0 when byte 0x20001080 is
@ 0); then for byte 0x20000eb8 < 4 (and != 3 unless byte 0x20000eb6 == 3) every
@ channel of byte 0x20000eb7 whose pointer at 0x20000ef4+4*ch is 0 gets a new
@ 0x12d-byte buffer (0803acfc, a failed allocation is skipped) holding a copy
@ of its 301-byte array; then when count != 0 every channel array byte
@ 0x2000044e + ch*0x12d + i for i from start' while uxth(i) < uxth(start') +
@ uxth(count) is replaced by RS.
@ When f00 >= 1000 (direct path): when byte 0x20000eb8 < 4 (and != 3 unless
@ byte 0x20000eb6 == 3) S1 is recomputed with the same chain from the 64-bit
@ value at 0x20000ee0/0x20000ee4 (plus 0x96), start' becomes halfword
@ 0x20000eac and count becomes halfword 0x20000eae; for every channel ch of
@ byte 0x20000eb7 and i = 0.. below min(0x12d - halfword 0x20000ed8, mult *
@ (f00 * count / 1000)) (signed 64-bit compare, mult = byte 0x20000efc, or 1
@ when the pointer 0x20000ef4+4*ch is 0), with q = (f00 * ((16-bit start') -
@ S1)) / 1000 (unsigned 64-bit divide 08008642, low 32 bits used) the sample
@ is: byte 0x20000eb8 >= 0x14: ring byte 0x200006a8 + ch*0x400 + halfword
@ 0x20000ed8 + i + q (no wrap); else when the pointer 0x20000ef4+4*ch is
@ nonzero: byte pointer[2*q + i]; else SD((0x20000eb4 & 0x7fff) + i + q -
@ halfword 0x20000ec0 - 0x96, ch); it is stored to 0x2000044e + ch*0x12d + i
@ and then replaced by RS; both paths end with 08027930 and then the post at
@ 0x080224b2.
@
@ Six blocks the decompiler judges unreachable are kept: 0x08023c46..0x08023c4b,
@ 0x08023c4c..0x08023c51, 0x08023c52..0x08023c5f, 0x08023dbc..0x08023dbf (arms
@ of the 0x40011010/0x40011014 write sequence, stores of 4 and 2),
@ 0x08023dfe..0x08023e0b (table offsets +0x2c4/+0x288) and
@ 0x08023ee2..0x08023eef (+0x33c/+0x300); dead only because the mode byte just
@ stored is a constant at those points.
@
@ Described by mechanics; the purpose of the state values 0x20000127 /
@ 0x20000128 / 0x20000ea8 is not determined from the code, the code adjusts the
@ RAM tables 0x20000358..0x20000447 and bytes 0x200000fc/fd/0x20000448/49.
@
@ Register use in this part: r10 = 0x200000f8 (base of the RAM block).
@ ----------------------------------------------------------------------------
	.section .text.fn_08020e98,"ax",%progbits
	.global fn_08020e98
	.thumb_func
	.type fn_08020e98, %function
fn_08020e98:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #4
	vpush {d8, d9, d10, d11, d12, d13, d14, d15}
	sub sp, #0x60
	movw r10, #0xf8
	movt r10, #0x2000
	ldrb.w r0, [r10, #0xf68]	@ byte 0x20001060
	cmp r0, #2
	bne.w .L080224d4	@ not 2: return at once, no post
	ldrb.w r0, [r10, #0x2e]	@ A (0x20000126)
	ldrb.w r1, [r10, #0x17]	@ M (0x2000010f)
	cbz r0, .L08020eec
	cmp r1, #2
	bne.w .L0802134a
	ldrb.w r0, [r10, #0x2d]	@ T (0x20000125)
	cmp r0, #0x13
	bhi.w .L08021642
	ldrb.w r1, [r10, #0xdb0]	@ S (0x20000ea8)
	movw r4, #0x1014
	subs r2, r1, #1
	cmp r2, #1
	movt r4, #0x4001
	bhi.w .L08021580
	movs r1, #3
	strb.w r1, [r10, #0xdb0]
	b.n .L08021584
.L08020eec:
	cmp r1, #2
	beq.n .L08020f10
	ldrb.w r0, [r10, #0xdb0]
	cmp r0, #1
	bne.n .L08020f0a
	movs r0, #2
	strb.w r0, [r10, #0xdb0]
	bl find_level_crossing
	bl compute_channel_measurements
	ldrb.w r0, [r10, #0xdb0]
.L08020f0a:
	cmp r0, #2
	bne.w .L080224b2
.L08020f10:
	ldr.w r0, [r10, #0xe08]	@ f00 low
	ldr.w r1, [r10, #0xe0c]	@ f00 high
	subs r0, #0xa
	sbcs r0, r1, #0
	bcc.w .L080224b2	@ f00 < 10
	ldrh.w r0, [r10, #0xdb6]
	cmp r0, #0
	beq.w .L080224b2
	ldrb.w r0, [r10, #0x2d]
	movw r2, #0xaaab
	movt r2, #0xaaaa
	umull r0, r1, r0, r2
	ldr.w r0, [r10, #0xddc]
	ldr.w r6, [r10, #0xdd0]
	ldr.w r4, [r10, #0xdd4]
	ldr.w r9, [r10, #0xdd8]
	str r0, [sp, #0x54]
	lsrs r0, r1, #1	@ T/3
	mov r5, r2
	bl u32_to_double
	vldr d8, .L08021210	@ 10.0
	vmov d1, r0, r1
	vmov.f32 s0, s16
	vmov.f32 s1, s17
	bl double_pow
	vmov.f32 s18, s0
	mov r0, r6
	mov r1, r4
	vmov.f32 s19, s1
	bl i64_to_double
	vmov r2, r3, d9
	bl double_div
	bl double_to_i64
	ldrb.w r2, [r10, #0x2d]
	movs r4, #0
	uxtb r3, r2
	umull r3, r7, r3, r5
	lsrs r6, r7, #1
	sub.w r3, r6, r6, lsl #2
	add r2, r3
	movw r7, #:lower16:d_080465c8
	uxtb r2, r2
	movt r7, #:upper16:d_080465c8
	ldrb r2, [r7, r2]
	movs r3, #0
	bl divide_s64
	adds.w r8, r0, #0x96
	mov r0, r6
	mov r11, r10
	adc.w r10, r1, #0
	bl u32_to_double
	vmov d1, r0, r1
	vmov.f32 s0, s16
	vmov.f32 s1, s17
	bl double_pow
	ldr r1, [sp, #0x54]
	vmov.f32 s16, s0
	mov r0, r9
	vmov.f32 s17, s1
	mov r9, r5
	bl i64_to_double
	vmov r2, r3, d8
	bl double_div
	bl double_to_i64
	ldrb.w r6, [r11, #0x2d]
	uxtb r2, r6
	umull r2, r3, r2, r5
	lsrs r5, r3, #1
	sub.w r2, r5, r5, lsl #2
	add r2, r6
	uxtb r2, r2
	ldrb r2, [r7, r2]
	movs r3, #0
	bl divide_s64
	rsbs.w r2, r8, #0
	sbcs.w r2, r4, r10
	mov.w r7, #0
	it lt
	movlt r7, #1
	cmp r7, #0
	it ne
	movne r7, r8
	subs.w r2, r0, #0x97
	sbcs.w r1, r1, #0
	it lt
	movlt r4, #1
	cmp r4, #0
	it eq
	moveq r0, #0x97
	subs r2, r0, r7
	ldr.w r0, [r11, #0xe08]
	ldr.w r1, [r11, #0xe0c]
	subs.w r3, r0, #0x3e8
	sbcs.w r3, r1, #0
	add.w r3, r2, #0x96
	bcc.w .L0802164a
	ldrb.w r0, [r11, #0xdc0]
	movw r11, #0xf8
	movt r11, #0x2000
	cmp r0, #3
	bhi.n .L080210c8
	bne.n .L08021062
	ldrb.w r0, [r11, #0xdbe]
	cmp r0, #3
	bne.n .L080210c8
.L08021062:
	ldr.w r6, [r11, #0xde8]
	ldr.w r4, [r11, #0xdec]
	uxtb r0, r5
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L08021210
	bl double_pow
	vmov.f32 s16, s0
	mov r0, r6
	mov r1, r4
	vmov.f32 s17, s1
	bl i64_to_double
	vmov r2, r3, d8
	bl double_div
	bl double_to_i64
	ldrb.w r6, [r11, #0x2d]
	umull r2, r3, r6, r9
	lsrs r2, r3, #1
	add.w r2, r2, r2, lsl #1
	movw r3, #:lower16:d_080465c8
	subs r2, r6, r2
	movt r3, #:upper16:d_080465c8
	ldrb r2, [r3, r2]
	movs r3, #0
	bl divide_s64
	adds.w r8, r0, #0x96
	ldrh.w r7, [r11, #0xdb4]
	ldrh.w r3, [r11, #0xdb6]
	adc.w r10, r1, #0
.L080210c8:
	ldrb.w r0, [r11, #0xdbf]
	and r1, r0, #0xf
	cmp.w r1, r0, lsr #4
	bls.w .L080224ac
	lsrs r2, r0, #4
	uxth r0, r7
	subs.w r0, r0, r8
	str r0, [sp, #0x3c]
	mov.w r0, #0
	ldrb.w r1, [r11, #0x14]
	sbc.w r0, r0, r10
	str r0, [sp, #0x38]
	subs r0, r1, #3
	clz r0, r0
	str r1, [sp, #0x2c]
	lsrs r0, r0, #5
	movs r1, #0
	cmp r6, #3
	it hi
	movhi r1, #1
	orrs r0, r1
	str r0, [sp, #0x30]
	ldrb.w r0, [r11, #0x351]
	vldr s16, .L08021218
	str r0, [sp, #0x28]
	ldrb.w r0, [r11, #0x350]
	vldr s18, .L0802121c
	vldr s20, .L08021220
	uxth r5, r3
	vmov.f32 s22, #28.0
	str r0, [sp, #0x24]
	b.n .L0802113a
	.byte 0x00, 0xbf	@ padding
.L08021128:
	ldrb.w r0, [r11, #0xdbf]
	ldr r2, [sp, #0x54]
	and r0, r0, #0xf
	adds r2, #1
	cmp r2, r0
	bcs.w .L080224ac
.L0802113a:
	add.w r0, r11, r2, lsl #2
	addw r0, r0, #0xdfc
	str r0, [sp, #0x50]
	lsls r0, r2, #10
	str r0, [sp, #0x34]
	add.w r0, r11, r2
	addw r1, r0, #0xdc1
	str r1, [sp, #0x4c]
	adds r1, r0, #2
	str r1, [sp, #0x48]
	addw r1, r0, #0xdc3
	adds r0, #4
	movs r6, #0
	str r2, [sp, #0x54]
	str r1, [sp, #0x44]
	str r0, [sp, #0x40]
	b.n .L08021178
	.byte 0x00, 0xbf	@ padding
.L08021168:
	vcvt.s32.f32 s0, s0
	addw r0, r0, #0x356
	vmov r1, s0
	strb r1, [r0, #0]
	adds r6, #1
.L08021178:
	ldr.w r10, [r11, #0xe08]
	ldr.w r9, [r11, #0xe0c]
	umull r0, r1, r10, r5
	mla r1, r9, r5, r1
	mov.w r2, #0x3e8
	movs r3, #0
	uxth r4, r6
	bl divide_u64
	ldr r2, [sp, #0x50]
	ldr r7, [r2, #0]
	ldrb.w r2, [r11, #0xe04]
	cmp r7, #0
	it eq
	moveq r2, #1
	umull r0, r3, r2, r0
	ldrh.w r8, [r11, #0xde0]
	mla r1, r2, r1, r3
	movw r2, #0x12d
	sub.w r2, r2, r8
	subs r3, r0, r2
	sbcs.w r3, r1, r2, asr #0x1f
	mov.w r3, #0
	it cc
	movcc r3, #1
	cmp r3, #0
	ite eq
	asreq r1, r2, #0x1f
	movne r2, r0
	subs r0, r4, r2
	mov.w r0, #0
	sbcs r0, r1
	bcs.n .L08021128
	ldr r2, [sp, #0x3c]
	ldr r3, [sp, #0x38]
	umull r0, r1, r10, r2
	mla r1, r10, r3, r1
	ldrb.w r4, [r11, #0xdc0]
	mla r1, r9, r2, r1
	mov.w r2, #0x3e8
	movs r3, #0
	bl divide_u64
	cmp r4, #0x14
	bcc.n .L08021224
	uxtah r0, r0, r6
	ldr r1, [sp, #0x34]
	add r0, r8
	add r0, r1
	add r0, r11
	ldrb.w r1, [r0, #0x5b0]
	ldr r3, [sp, #0x54]
	b.n .L080212a8
	.byte 0x00, 0xbf, 0x00, 0xbf	@ padding
.L08021210:
	.word 0x00000000, 0x40240000	@ double 10.0
.L08021218:
	.word 0xc3000000	@ float -128.0
.L0802121c:
	.word 0x43000000	@ float 128.0
.L08021220:
	.word 0x43640000	@ float 228.0
.L08021224:
	ldr r3, [sp, #0x54]
	cbz r7, .L08021232
	lsls r0, r0, #1
	uxtah r0, r0, r6
	ldrb r1, [r7, r0]
	b.n .L080212a8
.L08021232:
	ldrh.w r1, [r11, #0xdbc]
	uxtah r0, r0, r6
	bfc r1, #15, #17
	ldrh.w r2, [r11, #0xdc8]
	add r0, r1
	subs r0, r0, r2
	ldr r1, [sp, #0x30]
	subs r0, #0x96
	cmp r1, #0
	uxth r1, r0
	mov.w r2, #0
	beq.n .L08021266
	cmp.w r2, r1, lsr #10
	it ne
	subne.w r0, r0, #0x400
	ldr r1, [sp, #0x34]
	uxtah r0, r1, r0
	b.n .L08021282
.L08021266:
	cmp.w r2, r1, lsr #11
	it ne
	subne.w r0, r0, #0x800
	uxth r2, r0
	and r1, r0, #1
	ldr r0, [sp, #0x2c]
	cmp r0, #1
	lsr.w r0, r2, #1
	bne.n .L0802128a
	cbnz r1, .L08021296
.L08021282:
	add r0, r11
	ldrb.w r1, [r0, #0x5b0]
	b.n .L080212a8
.L0802128a:
	cbnz r1, .L080212a2
	add r0, r11
	ldrb.w r0, [r0, #0x5b0]
	ldr r1, [sp, #0x28]
	b.n .L0802129e
.L08021296:
	add r0, r11
	ldrb.w r0, [r0, #0x9b0]
	ldr r1, [sp, #0x24]
.L0802129e:
	subs r1, r0, r1
	b.n .L080212a8
.L080212a2:
	add r0, r11
	ldrb.w r1, [r0, #0x9b0]
.L080212a8:
	movw r0, #0x12d
	mla r0, r3, r0, r11
	ldr r2, [sp, #0x4c]
	uxtah r0, r0, r6
	strb.w r1, [r0, #0x356]
	ldrb r2, [r2, #0]
	movw r7, #:lower16:d_080465cc
	ldr r3, [sp, #0x48]
	movt r7, #:upper16:d_080465cc
	ldrh.w r2, [r7, r2, lsl #1]
	ldrb r3, [r3, #0]
	vmov s0, r2
	ldrh.w r2, [r7, r3, lsl #1]
	vcvt.f32.u32 s0, s0
	vmov s2, r2
	vcvt.f32.u32 s2, s2
	vdiv.f32 s0, s0, s2
	uxtb r1, r1
	vmov s2, r1
	ldr r1, [sp, #0x44]
	vcvt.f32.u32 s2, s2
	ldrsb.w r1, [r1, #0]
	vadd.f32 s2, s2, s16
	vmov s4, r1
	ldr r1, [sp, #0x40]
	vcvt.f32.s32 s4, s4
	vsub.f32 s2, s2, s4
	ldrsb.w r1, [r1, #0]
	vmul.f32 s0, s0, s2
	vadd.f32 s0, s0, s18
	vmov s2, r1
	vadd.f32 s0, s0, s4
	vcvt.f32.s32 s2, s2
	vadd.f32 s0, s0, s2
	vsub.f32 s2, s0, s4
	vcmp.f32 s2, s20
	vmrs APSR_nzcv, fpscr
	vmov.f32 s0, s20
	bgt.w .L08021168
	vcmp.f32 s2, s22
	vmov.f32 s0, s2
	vmrs APSR_nzcv, fpscr
	it lt
	vmovlt.f32 s0, s22
	b.n .L08021168
.L0802134a:
	ldrb.w r1, [r10, #0x2d]	@ T
	cmp r1, #0x14
	bcc.n .L08021370
	ldrb.w r0, [r10, #0x2c]	@ byte 0x20000124
	cmp r0, #0
	bne.w .L080224b2
	bl compute_spectrum_bytes
	bl compute_math_trace
	bl fn_08025aac
	bl compute_channel_measurements
	b.w .L080224b2
.L08021370:
	ldrb.w r1, [r10, #0xdba]	@ byte 0x20000eb2
	ldrb.w r2, [r10, #0xdbb]	@ byte 0x20000eb3
	orrs r1, r2
	bne.w .L080224b2
	ldrb.w r1, [r10, #0xdb0]	@ S
	cmp r1, #1
	bne.w .L0802425a
	bl fn_080242ec
	ldrb.w r0, [r10, #0x2c]
	cbnz r0, .L080213a2
	bl compute_spectrum_bytes
	bl compute_math_trace
	bl fn_08025aac
	bl compute_channel_measurements
.L080213a2:
	ldrb.w r0, [r10, #0x2f]	@ byte 0x20000127: switch 0..3
	cmp r0, #3
	bhi.w .L08021ee0
	tbh [pc, r0, lsl #1]
.L080213b0:
	.short (.L08022ae4 - .L080213b0)/2	@ case 0
	.short (.L080213b8 - .L080213b0)/2	@ case 1
	.short (.L08021ef0 + 0x5c - .L080213b0)/2	@ case 2 (0x08021f4c, lies in part 2)
	.short (.L08021ef0 + 0xa0 - .L080213b0)/2	@ case 3 (0x08021f90, lies in part 2)
.L080213b8:
	ldrb.w r0, [r10, #0x32]	@ tick byte 0x2000012a
	cmp r0, #0x28
	bcc.w .L08022ae4
	ldrb.w r0, [r10, #0x15]	@ channel nibbles (0x2000010d)
	and r1, r0, #0xf
	cmp.w r1, r0, lsr #4
	bls.w .L08022624
	lsr.w r11, r0, #4
	mov.w r12, #1
	movw r5, #0x12d
.L080213de:
	mla r2, r11, r5, r10
	and lr, r0, #0xf
	addw r4, r2, #0x356
	b.n .L0802140c
.L080213ec:
	add.w r0, r10, r11
	ldrb.w r2, [r0, #2]!
	cmp r2, #8
	bls.w .L08021526
.L080213fa:
	add.w r11, r11, #1
	cmp r11, lr
	addw r4, r4, #0x12d
	movw r5, #0x12d
	bcs.w .L0802261c
.L0802140c:
	mla r0, r11, r5, r10
	mov.w r7, #0x12c
	ldrb.w r0, [r0, #0x356]
	mov r2, r4
	mov r3, r0
.L0802141c:
	ldrb.w r6, [r2, #0xf]!
	ldrb.w r1, [r2, #-0xe]
	ldrb.w r8, [r2, #-0xd]
	cmp r3, r1
	ldrb.w r9, [r2, #-0xc]
	ldrb.w r10, [r2, #-0xb]
	it cc
	movcc r3, r1
	cmp r0, r1
	it hi
	movhi r0, r1
	cmp r3, r8
	it cc
	movcc r3, r8
	cmp r0, r8
	it hi
	movhi r0, r8
	cmp r3, r9
	it cc
	movcc r3, r9
	cmp r0, r9
	it hi
	movhi r0, r9
	cmp r3, r10
	it cc
	movcc r3, r10
	ldrb.w r1, [r2, #-0xa]
	cmp r0, r10
	it hi
	movhi r0, r10
	cmp r3, r1
	it cc
	movcc r3, r1
	ldrb.w r5, [r2, #-9]
	cmp r0, r1
	it hi
	movhi r0, r1
	cmp r3, r5
	it cc
	movcc r3, r5
	ldrb.w r1, [r2, #-8]
	cmp r0, r5
	it hi
	movhi r0, r5
	cmp r3, r1
	it cc
	movcc r3, r1
	ldrb.w r5, [r2, #-7]
	cmp r0, r1
	it hi
	movhi r0, r1
	cmp r3, r5
	it cc
	movcc r3, r5
	ldrb.w r1, [r2, #-6]
	cmp r0, r5
	it hi
	movhi r0, r5
	cmp r3, r1
	it cc
	movcc r3, r1
	ldrb.w r5, [r2, #-5]
	cmp r0, r1
	it hi
	movhi r0, r1
	cmp r3, r5
	it cc
	movcc r3, r5
	ldrb.w r1, [r2, #-4]
	cmp r0, r5
	it hi
	movhi r0, r5
	cmp r3, r1
	it cc
	movcc r3, r1
	ldrb.w r5, [r2, #-3]
	cmp r0, r1
	it hi
	movhi r0, r1
	cmp r3, r5
	it cc
	movcc r3, r5
	ldrb.w r1, [r2, #-2]
	cmp r0, r5
	it hi
	movhi r0, r5
	cmp r3, r1
	it cc
	movcc r3, r1
	ldrb.w r5, [r2, #-1]
	cmp r0, r1
	it hi
	movhi r0, r1
	cmp r3, r5
	it cc
	movcc r3, r5
	cmp r0, r5
	it hi
	movhi r0, r5
	cmp r3, r6
	it cc
	movcc r3, r6
	cmp r0, r6
	it hi
	movhi r0, r6
	subs r7, #0xf
	bne.n .L0802141c
	movw r10, #0xf8
	cmp r3, #0xd9	@ max > 0xd9
	movt r10, #0x2000
	bhi.w .L080213ec
	cmp r0, #0x27	@ min < 0x27
	bcs.w .L080213fa
	b.n .L080213ec
.L08021526:
	adds r1, r2, #1
	cmp.w r11, #0
	strb r1, [r0, #0]
	beq.n .L0802153a
	ldrb.w r0, [r10, #3]
	bl fn_08008a58
	b.n .L08021542
.L0802153a:
	ldrb.w r0, [r10, #2]
	bl fn_080088a4
.L08021542:
	movw r0, #0x2d6c
	movt r0, #0x2000
	ldr r0, [r0, #0]
	movs r1, #4
	strb.w r1, [sp, #0x5d]
	add.w r1, sp, #0x5d
	mov.w r2, #0xffffffff
	movw r5, #0x12d
	bl queue_send_timeout
	ldrb.w r0, [r10, #0x15]
	add.w r11, r11, #1
	and r1, r0, #0xf
	mov.w r12, #0
	cmp r11, r1
	strb.w r12, [r10, #0x32]
	bcc.w .L080213de
	b.w .L08022ae4
.L08021580:
	cmp r1, #3
	bne.n .L08021606
.L08021584:
	ldr.w r1, [r4, #-0xc]	@ word 0x40011008
	lsls r1, r1, #0x1f
	beq.n .L08021642
	ldrb.w r1, [r10, #0x14]
	movs r2, #4
	lsls r3, r1, #0x1f
	strb.w r2, [r10, #0xdb0]
	bne.n .L0802159e
	cmp r0, #4
	bhi.n .L080215c0
.L0802159e:
	movw r0, #0x2d78
	movt r0, #0x2000
	ldr r0, [r0, #0]
	strb.w r2, [sp, #0x5a]
	add.w r1, sp, #0x5a
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldrb.w r1, [r10, #0x14]
	ldrb.w r0, [r10, #0x2d]
.L080215c0:
	cmp r0, #5
	bcc.n .L080215ca
	ands.w r0, r1, #2
	beq.n .L080215e6
.L080215ca:
	movw r0, #0x2d78
	movt r0, #0x2000
	movs r1, #5
	ldr r0, [r0, #0]
	strb.w r1, [sp, #0x5a]
	add.w r1, sp, #0x5a
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L080215e6:
	movw r0, #0x2d78
	movt r0, #0x2000
	movs r1, #9
	ldr r0, [r0, #0]
	strb.w r1, [sp, #0x5a]
	add.w r1, sp, #0x5a
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldrb.w r1, [r10, #0xdb0]
.L08021606:
	cmp r1, #6
	bne.n .L08021642
	movs r0, #0x10
	str r0, [r4, #0]	@ 0x40011014 = 0x10
	movs r0, #0
	movt r0, #0x12d
	str.w r0, [r10, #0xdb4]	@ word 0x20000eac = 0x012d0000
	bl fn_080242ec
	movs r0, #0
	strb.w r0, [r10, #0x2e]	@ clear A
	movw r0, #0x2d6c
	movt r0, #0x2000
	movs r1, #2
	ldr r0, [r0, #0]
	strb.w r1, [sp, #0x59]
	add.w r1, sp, #0x59
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	bl fn_0803b078
.L08021642:
	bl compute_channel_measurements
	b.w .L080224b2
.L0802164a:
	eor.w r2, r0, #0x190	@ f00 == 400 ?
	orrs r1, r2
	str r7, [sp, #0x24]
	str r3, [sp, #0x2c]
	bne.n .L0802165e
	mov.w r11, #2	@ R = 2
	movs r7, #5	@ F = 5
	b.n .L0802166c
.L0802165e:
	uxth r0, r0
	mov.w r1, #0x3e8
	udiv r7, r1, r0	@ F = 1000 / f00
	mov.w r11, #1	@ R = 1
.L0802166c:
	ldr r0, [sp, #0x24]
	movw r9, #0xf8
	uxth r0, r0
	str r0, [sp, #0x3c]
	subs.w r4, r0, r8
	mov.w r0, #0
	movt r9, #0x2000
	sbc.w r5, r0, r10
	ldrb.w r6, [r9, #0xdc0]
	mov r0, r4
	mov r1, r5
	bl i64_to_float
	uxtb r2, r7
	vmov s0, r2
	vmov s2, r11
	vcvt.f32.u32 s0, s0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s18, s0, s2
	vmov s0, r0
	cmp r6, #0x14
	str r2, [sp, #0x30]
	vdiv.f32 s16, s0, s18
	bcc.w .L08021990
	ldrh.w r6, [r9, #0xde0]
	mov r0, r4
	mov r1, r5
	movs r3, #0
	bl divide_s64
	ldr r0, [sp, #0x2c]
	vmov.f32 s2, #7.0
	uxth r4, r0
	vmov s0, r4
	vcvt.f32.u32 s0, s0
	vdiv.f32 s0, s0, s18
	str r2, [sp, #0x50]
	vadd.f32 s0, s0, s2
	vmov.f32 s2, #16.0
	vadd.f32 s0, s0, s2
	vcvt.s32.f32 s20, s0
	vmov r5, s20
	mov r0, r5
	bl alloc_units_of_32_bytes
	ldr.w r8, [sp, #0x24]
	cmp r0, #0
	mov r10, r9
	beq.w .L080224b2
	vcvt.f32.u32 s0, s20
	vmul.f32 s0, s18, s0
	vcvt.u32.f32 s0, s0
	str r0, [sp, #0x38]
	vmov r0, s0
	bl alloc_units_of_32_bytes
	cmp r0, #0
	beq.w .L08021d72
	mov r12, r0
	ldrb.w r0, [r10, #0xdbf]
	and r1, r0, #0xf
	cmp.w r1, r0, lsr #4
	bls.w .L08021eda
	ldr.w lr, [sp, #0x38]
	cmp r5, #0
	lsr.w r9, r0, #4
	str.w r12, [sp, #0x34]
	str r5, [sp, #0x4c]
	beq.w .L08021fc4
	vmov s0, r6
	vcvt.f32.u32 s0, s0
	vadd.f32 s0, s16, s0
	vmov.f32 s2, #-7.0
	vadd.f32 s0, s0, s2
	vcvt.s32.f32 s0, s0
	vmov r0, s0
	cmp r4, #0
	sub.w r1, r5, #1
	str r1, [sp, #0x48]
	str r0, [sp, #0x40]
	beq.w .L080224e0
	subs r1, r4, #1
	str r1, [sp, #0x28]
	and r1, r4, #3
	str r1, [sp, #0x1c]
	bic r1, r4, #3
	mov r6, r9
	add.w r9, r0, r9, lsl #10
	ldr r0, [sp, #0x3c]
	str r1, [sp, #0x18]
	movw r1, #0x12d
	smlabb r0, r6, r1, r0
	movw r1, #0xf8
	movt r1, #0x2000
	add.w r8, r1, r0
	ldr r0, [sp, #0x50]
	and r7, r5, #3
	add r0, r12
	and r2, r5, #0xfc
	addw r4, r9, #0x12d
	addw r5, r9, #0x12f
	add.w r10, lr, #1
	str r0, [sp, #0x14]
	lsl.w r0, r11, #2
	str r0, [sp, #0x10]
	str r7, [sp, #0x44]
	str r2, [sp, #0x20]
	b.n .L080217ee
.L080217c0:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xdbf]
	adds r6, #1
	and r0, r0, #0xf
	ldr r2, [sp, #0x20]
	ldr.w lr, [sp, #0x38]
	add.w r9, r9, #0x400
	add.w r4, r4, #0x400
	add.w r5, r5, #0x400
	cmp r6, r0
	addw r8, r8, #0x12d
	bcs.w .L080221be
.L080217ee:
	ldr r0, [sp, #0x48]
	mov lr, r6
	cmp r0, #3
	bcs.n .L080217fa
	movs r0, #0
	b.n .L0802185a
.L080217fa:
	movw r7, #0xf8
	movs r0, #0
	movt r7, #0x2000
	mov r12, r2
	nop
.L08021808:
	add.w r1, r9, r0
	mov r2, r1
	cmp.w r1, #0xffffffff
	it le
	addle r2, r4, r0
	add.w r3, r7, #0x5b0
	ldrb r2, [r3, r2]
	add.w r6, r10, r0
	strb.w r2, [r6, #-1]
	adds r2, r1, #1
	cmp.w r2, #0xffffffff
	it le
	addle.w r2, r1, #0x12e
	ldrb r2, [r3, r2]
	strb.w r2, [r10, r0]
	adds r2, r1, #2
	cmp.w r2, #0xffffffff
	it le
	addle r2, r5, r0
	ldrb r2, [r3, r2]
	adds r0, #4
	strb r2, [r6, #1]
	adds r2, r1, #3
	cmp.w r2, #0xffffffff
	it le
	addle.w r2, r1, #0x130
	ldrb r1, [r3, r2]
	cmp r12, r0
	strb r1, [r6, #2]
	bne.n .L08021808
.L0802185a:
	ldr r6, [sp, #0x44]
	ldr r1, [sp, #0x38]
	cbz r6, .L080218ce
	ldr r2, [sp, #0x40]
	movw r3, #0xf8
	add.w r12, r2, lr, lsl #10
	add.w r2, r0, r12
	cmp.w r2, #0xffffffff
	it le
	addwle r2, r2, #0x12d
	movt r3, #0x2000
	add r2, r3
	ldrb.w r2, [r2, #0x5b0]
	cmp r6, #1
	strb r2, [r1, r0]
	beq.n .L080218ce
	adds r2, r0, #1
	add.w r3, r2, r12
	movw r7, #0xf8
	cmp.w r3, #0xffffffff
	it le
	addwle r3, r3, #0x12d
	movt r7, #0x2000
	add r3, r7
	ldr r6, [sp, #0x44]
	ldrb.w r3, [r3, #0x5b0]
	cmp r6, #2
	strb r3, [r1, r2]
	beq.n .L080218ce
	adds r0, #2
	movw r2, #0xf8
	add.w r3, r0, r12
	movt r2, #0x2000
	cmp.w r3, #0xffffffff
	it le
	addwle r3, r3, #0x12d
	add r2, r3
	ldrb.w r2, [r2, #0x5b0]
	strb r2, [r1, r0]
.L080218ce:
	ldr r2, [sp, #0x4c]
	ldrd r3, r0, [sp, #0x30]
	str.w lr, [sp, #0x54]
	bl fir_filter_rows
	ldr r0, [sp, #0x28]
	cmp r0, #3
	bcs.n .L080218ea
	ldr.w lr, [sp, #0x1c]
	movs r0, #0
	b.n .L08021920
.L080218ea:
	ldrd r7, lr, [sp, #0x18]
	ldrd r6, r1, [sp, #0x10]
	movs r0, #0
.L080218f4:
	ldrb r2, [r1, #0]
	add.w r3, r8, r0
	strb.w r2, [r3, #0x356]
	ldrb.w r2, [r1, r11]
	adds r0, #4
	strb.w r2, [r3, #0x357]
	ldrb.w r2, [r1, r11, lsl #1]
	cmp r7, r0
	strb.w r2, [r3, #0x358]
	add.w r2, r11, r11, lsl #1
	ldrb r2, [r1, r2]
	add r1, r6
	strb.w r2, [r3, #0x359]
	bne.n .L080218f4
.L08021920:
	ldr.w r12, [sp, #0x34]
	ldr r6, [sp, #0x54]
	cmp.w lr, #0
	beq.w .L080217c0
	ldr r1, [sp, #0x50]
	movw r3, #0x12d
	mla r1, r0, r11, r1
	cmp.w lr, #1
	ldrb.w r2, [r12, r1]
	movw r1, #0xf8
	movt r1, #0x2000
	mla r1, r6, r3, r1
	ldr r3, [sp, #0x3c]
	add r3, r0
	add r3, r1
	strb.w r2, [r3, #0x356]
	beq.w .L080217c0
	ldr r3, [sp, #0x50]
	adds r2, r0, #1
	mla r3, r2, r11, r3
	ldr r7, [sp, #0x3c]
	ldrb.w r3, [r12, r3]
	add r2, r7
	add r2, r1
	cmp.w lr, #2
	strb.w r3, [r2, #0x356]
	beq.w .L080217c0
	ldr r2, [sp, #0x50]
	adds r0, #2
	mla r2, r0, r11, r2
	ldr r3, [sp, #0x3c]
	ldrb.w r2, [r12, r2]
	add r0, r3
	add r0, r1
	strb.w r2, [r0, #0x356]
	b.n .L080217c0
.L08021990:
	mov r0, r4
	mov r1, r5
	movs r3, #0
	bl divide_s64
	ldrsh.w r0, [r9, #0xdbc]
	ldrh.w r1, [r9, #0xdf8]
	ldr.w r8, [sp, #0x24]
	cmp.w r0, #0xffffffff
	sub.w r6, r2, r1
	mov r10, r9
	ble.w .L08021daa
.L080219b4:
	ldr r0, [sp, #0x2c]
	vmov.f32 s2, #7.0
	uxth r4, r0
	vmov s0, r4
	vcvt.f32.u32 s0, s0
	vdiv.f32 s0, s0, s18
	vadd.f32 s0, s0, s2
	vmov.f32 s2, #16.0
	vadd.f32 s0, s0, s2
	vcvt.s32.f32 s0, s0
	vmov r7, s0
	mov r0, r7
	bl alloc_units_of_32_bytes
	cmp r0, #0
	beq.w .L080224b2
	ldr r5, [sp, #0x30]
	str r0, [sp, #0x38]
	mul.w r0, r7, r5
	str r7, [sp, #0x20]
	bl alloc_units_of_32_bytes
	cmp r0, #0
	beq.w .L08021d72
	mov r12, r0
	ldrb.w r0, [r10, #0xdbf]
	and r1, r0, #0xf
	cmp.w r1, r0, lsr #4
	bls.w .L08021eda
	ldr r3, [sp, #0x20]
	ldr.w lr, [sp, #0x38]
	lsr.w r9, r0, #4
	cmp r3, #0
	sxth r6, r6
	str.w r12, [sp, #0x34]
	beq.w .L080220c8
	vmov.f32 s0, #-7.0
	vadd.f32 s0, s16, s0
	vcvt.s32.f32 s0, s0
	vmov r0, s0
	mvn.w r2, #0x95
	uxth r1, r0
	uxtah r0, r2, r0
	str r0, [sp, #0xc]
	subs r0, r4, #1
	str r0, [sp, #0x10]
	and r0, r3, #1
	str r0, [sp, #0x14]
	and r0, r3, #0xfe
	str r0, [sp, #0x54]
	and r0, r4, #3
	str r0, [sp, #0x1c]
	bic r0, r4, #3
	str r0, [sp, #8]
	sub.w r0, r1, #0x95
	str r0, [sp, #0x50]
	movw r0, #0xfb6b
	add r0, r1
	str r0, [sp, #0x4c]
	movw r0, #0xf76b
	add r0, r1
	str r0, [sp, #0x48]
	movw r0, #0xfb6a
	add r0, r1
	str r0, [sp, #0x44]
	movw r0, #0xf76a
	add r0, r1
	str r0, [sp, #0x40]
	ldr r0, [sp, #0x3c]
	sub.w r8, r1, #0x96
	movw r1, #0x12d
	smlabb r0, r9, r1, r0
	mov r2, r9
	add.w r9, r10, r0
	add.w r0, r12, r6
	add.w r4, lr, #1
	str r6, [sp, #0x18]
	str r0, [sp, #4]
	lsl.w r0, r11, #2
	mov.w r10, #0
	mov r6, r3
	str r0, [sp, #0]
	b.n .L08021ad2
.L08021ab0:
	movw r0, #0xf8
	movt r0, #0x2000
	ldrb.w r0, [r0, #0xdbf]
	ldr r2, [sp, #0x28]
	and r0, r0, #0xf
	adds r2, #1
	ldr.w lr, [sp, #0x38]
	cmp r2, r0
	addw r9, r9, #0x12d
	bcs.w .L080221be
.L08021ad2:
	cmp r6, #1
	lsl.w r12, r2, #10
	mov.w r0, #0
	str r2, [sp, #0x28]
	bne.n .L08021b58
.L08021ae0:
	ldr r1, [sp, #0x14]
	cmp r1, #0
	beq.w .L08021c86
	movw r5, #0xf8
	movt r5, #0x2000
	ldrh.w r2, [r5, #0xdbc]
	ldr r1, [sp, #0xc]
	bfc r2, #15, #17
	ldrh.w r7, [r5, #0xdc8]
	adds r3, r1, r0
	add r2, r3
	ldrb r3, [r5, #0x14]
	subs r2, r2, r7
	cmp r3, #3
	uxth r6, r2
	beq.w .L08021c6e
	ldrb.w r7, [r5, #0x2d]
	cmp r7, #3
	bhi.w .L08021c6e
	cmp.w r10, r6, lsr #11
	it ne
	addne.w r2, r2, #0xf800
	and r6, r2, #1
	ubfx r1, r2, #1, #15
	movw r2, #0xf8
	cmp r3, #1
	movt r2, #0x2000
	bne.w .L08021d4c
	cmp r6, #0
	bne.w .L08021d5c
	add r1, r2
	b.n .L08021c7e
.L08021b42:
	add r2, r1
	ldrb.w r2, [r2, #0x9b0]
	ldrb.w r3, [r1, #0x350]
.L08021b4c:
	subs r2, r2, r3
.L08021b4e:
	ldr r1, [sp, #0x54]
	strb r2, [r4, r0]
	adds r0, #2
	cmp r1, r0
	beq.n .L08021ae0
.L08021b58:
	movw r1, #0xf8
	movt r1, #0x2000
	ldrh.w r2, [r1, #0xdbc]
	ldrh.w r3, [r1, #0xdc8]
	bfc r2, #15, #17
	subs r2, r2, r3
	add.w r3, r8, r0
	ldrb r5, [r1, #0x14]
	add r3, r2
	cmp r5, #3
	uxth r6, r3
	beq.n .L08021bb8
	ldrb.w r7, [r1, #0x2d]
	cmp r7, #3
	bhi.n .L08021bb8
	ldr r1, [sp, #0x40]
	cmp.w r10, r6, lsr #11
	add.w r7, r1, r0
	movw r1, #0xf8
	it ne
	addne r3, r7, r2
	and r6, r3, #1
	cmp r5, #1
	ubfx r2, r3, #1, #15
	movt r1, #0x2000
	bne.n .L08021c40
	cbz r6, .L08021bca
	add r2, r1
	ldrb.w r2, [r2, #0x9b0]
	ldrb.w r3, [r1, #0x350]
	subs r2, r2, r3
	b.n .L08021bd0
	.byte 0x00, 0xbf	@ padding
.L08021bb8:
	ldr r5, [sp, #0x44]
	cmp.w r10, r6, lsr #10
	add.w r7, r5, r0
	it ne
	addne r3, r7, r2
	uxtah r2, r12, r3
.L08021bca:
	add r2, r1
	ldrb.w r2, [r2, #0x5b0]
.L08021bd0:
	adds r3, r4, r0
	strb.w r2, [r3, #-1]
	ldrh.w r2, [r1, #0xdbc]
	ldrh.w r3, [r1, #0xdc8]
	bfc r2, #15, #17
	subs r2, r2, r3
	ldr r3, [sp, #0x50]
	ldrb r5, [r1, #0x14]
	add r3, r0
	add r3, r2
	cmp r5, #3
	uxth r6, r3
	beq.n .L08021c24
	ldrb.w r7, [r1, #0x2d]
	cmp r7, #3
	bhi.n .L08021c24
	ldr r1, [sp, #0x48]
	cmp.w r10, r6, lsr #11
	add.w r7, r1, r0
	movw r1, #0xf8
	it ne
	addne r3, r7, r2
	and r6, r3, #1
	cmp r5, #1
	ubfx r2, r3, #1, #15
	movt r1, #0x2000
	bne.n .L08021c50
	cmp r6, #0
	bne.n .L08021b42
	b.n .L08021c36
	.byte 0x00, 0xbf	@ padding
.L08021c24:
	ldr r5, [sp, #0x4c]
	cmp.w r10, r6, lsr #10
	add.w r7, r5, r0
	it ne
	addne r3, r7, r2
	uxtah r2, r12, r3
.L08021c36:
	add r2, r1
	ldrb.w r2, [r2, #0x5b0]
	b.n .L08021b4e
	.byte 0x00, 0xbf	@ padding
.L08021c40:
	cbnz r6, .L08021c5e
	add r2, r1
	ldrb.w r2, [r2, #0x5b0]
	ldrb.w r3, [r1, #0x351]
	subs r2, r2, r3
	b.n .L08021bd0
.L08021c50:
	cbnz r6, .L08021c66
	add r2, r1
	ldrb.w r2, [r2, #0x5b0]
	ldrb.w r3, [r1, #0x351]
	b.n .L08021b4c
.L08021c5e:
	add r2, r1
	ldrb.w r2, [r2, #0x9b0]
	b.n .L08021bd0
.L08021c66:
	add r2, r1
	ldrb.w r2, [r2, #0x9b0]
	b.n .L08021b4e
.L08021c6e:
	cmp.w r10, r6, lsr #10
	it ne
	addne.w r2, r2, #0xfc00
	uxtah r1, r12, r2
	add r1, r5
.L08021c7e:
	ldrb.w r1, [r1, #0x5b0]
.L08021c82:
	strb.w r1, [lr, r0]
.L08021c86:
	ldr r5, [sp, #0x34]
	ldr r6, [sp, #0x20]
	ldr r3, [sp, #0x30]
	mov r0, r5
	mov r1, lr
	mov r2, r6
	bl fir_filter_rows
	ldr r0, [sp, #0x2c]
	mov r12, r5
	lsls r0, r0, #16
	beq.w .L08021ab0
	ldr r0, [sp, #0x10]
	cmp r0, #3
	bcs.n .L08021caa
	movs r0, #0
	b.n .L08021ce0
.L08021caa:
	ldr r7, [sp, #8]
	ldrd r5, r1, [sp, #0]
	movs r0, #0
	nop
.L08021cb4:
	ldrb r2, [r1, #0]
	add.w r3, r9, r0
	strb.w r2, [r3, #0x356]
	ldrb.w r2, [r1, r11]
	adds r0, #4
	strb.w r2, [r3, #0x357]
	ldrb.w r2, [r1, r11, lsl #1]
	cmp r7, r0
	strb.w r2, [r3, #0x358]
	add.w r2, r11, r11, lsl #1
	ldrb r2, [r1, r2]
	add r1, r5
	strb.w r2, [r3, #0x359]
	bne.n .L08021cb4
.L08021ce0:
	ldr r1, [sp, #0x1c]
	cmp r1, #0
	beq.w .L08021ab0
	ldr r1, [sp, #0x18]
	ldr r3, [sp, #0x28]
	mla r1, r0, r11, r1
	movw r7, #0x12d
	ldrb.w r2, [r12, r1]
	movw r1, #0xf8
	movt r1, #0x2000
	mla r1, r3, r7, r1
	ldr r3, [sp, #0x3c]
	ldr r7, [sp, #0x1c]
	add r3, r0
	add r3, r1
	cmp r7, #1
	strb.w r2, [r3, #0x356]
	beq.w .L08021ab0
	ldr r3, [sp, #0x18]
	adds r2, r0, #1
	ldr r7, [sp, #0x3c]
	mla r3, r2, r11, r3
	add r2, r7
	ldr r7, [sp, #0x1c]
	ldrb.w r3, [r12, r3]
	add r2, r1
	cmp r7, #2
	strb.w r3, [r2, #0x356]
	beq.w .L08021ab0
	ldr r2, [sp, #0x18]
	adds r0, #2
	mla r2, r0, r11, r2
	ldr r3, [sp, #0x3c]
	ldrb.w r2, [r12, r2]
	add r0, r3
	add r0, r1
	strb.w r2, [r0, #0x356]
	b.n .L08021ab0
.L08021d4c:
	cbnz r6, .L08021d6a
	add r1, r2
	ldrb.w r1, [r1, #0x5b0]
	ldrb.w r2, [r2, #0x351]
	subs r1, r1, r2
	b.n .L08021c82
.L08021d5c:
	add r1, r2
	ldrb.w r1, [r1, #0x9b0]
	ldrb.w r2, [r2, #0x350]
	subs r1, r1, r2
	b.n .L08021c82
.L08021d6a:
	add r1, r2
	ldrb.w r1, [r1, #0x9b0]
	b.n .L08021c82
.L08021d72:
	movw r0, #0x1070
	movt r0, #0x2000
	ldrb r1, [r0, #0x10]	@ byte 0x20001080
	cmp r1, #0
	beq.w .L08021fbc
	ldr r1, [r0, #8]
	ldr r2, [sp, #0x38]
	subs r1, r2, r1
.L08021d88:
	lsrs r2, r1, #10
	cmp r2, #0xae
	bhi.w .L080224b2
	ldr r0, [r0, #0xc]
	lsrs r2, r1, #5
	ldrh.w r1, [r0, r2, lsl #1]
	cmp r1, #0
	beq.w .L080224b2
	add.w r0, r0, r2, lsl #1
	lsls r1, r1, #1
	bl zero_bytes
	b.n .L080224b2
.L08021daa:
	movs r0, #0x19
	movs r4, #0x19
	bl alloc_units_of_32_bytes
	cmp r0, #0
	beq.w .L080224b2
	str r6, [sp, #0x54]
	ldr r6, [sp, #0x30]
	mov r5, r0
	mul.w r0, r6, r4
	bl alloc_units_of_32_bytes
	cmp r0, #0
	beq.w .L08021faa
	mov r9, r0
	movs r0, #0
	movs r1, #0
	b.n .L08021de6
.L08021dd4:
	add r2, r10
	ldrb.w r2, [r2, #0x9b0]
	ldrb.w r3, [r10, #0x350]
.L08021dde:
	subs r2, r2, r3
.L08021de0:
	adds r3, r5, r1
	strb r2, [r3, #1]
	adds r1, #2
.L08021de6:
	ldrh.w r2, [r10, #0xdbc]
	ldrb.w r7, [r10, #0x14]
	bfc r2, #15, #17
	adds r3, r2, r1
	cmp r7, #3
	sub.w r2, r3, #7
	beq.n .L08021e2c
	ldrb.w r4, [r10, #0x2d]
	cmp r4, #4
	bcs.n .L08021e2c
	uxth r4, r2
	cmp.w r0, r4, lsr #11
	it ne
	subwne r2, r3, #0x807
	uxth r4, r2
	and r3, r2, #1
	cmp r7, #1
	lsr.w r2, r4, #1
	bne.n .L08021e4a
	cbz r3, .L08021e42
	add r2, r10
	ldrb.w r2, [r2, #0x9b0]
	ldrb.w r3, [r10, #0x350]
	b.n .L08021e56
.L08021e2c:
	ldrb.w r7, [r10, #0x16]
	uxth r4, r2
	cmp.w r0, r4, lsr #10
	it ne
	subwne r2, r3, #0x407
	lsls r3, r7, #10
	uxtah r2, r3, r2
.L08021e42:
	add r2, r10
	ldrb.w r2, [r2, #0x5b0]
	b.n .L08021e60
.L08021e4a:
	cbnz r3, .L08021e5a
	add r2, r10
	ldrb.w r2, [r2, #0x5b0]
	ldrb.w r3, [r10, #0x351]
.L08021e56:
	subs r2, r2, r3
	b.n .L08021e60
.L08021e5a:
	add r2, r10
	ldrb.w r2, [r2, #0x9b0]
.L08021e60:
	cmp r1, #0x18
	strb r2, [r5, r1]
	beq.n .L08021ef0
	ldrh.w r2, [r10, #0xdbc]
	adds r3, r1, #1
	bfc r2, #15, #17
	ldrb.w r7, [r10, #0x14]
	add r3, r2
	cmp r7, #3
	sub.w r2, r3, #7
	beq.n .L08021ea6
	ldrb.w r4, [r10, #0x2d]
	cmp r4, #3
	bhi.n .L08021ea6
	uxth r4, r2
	cmp.w r0, r4, lsr #11
	it ne
	subwne r2, r3, #0x807
	uxth r4, r2
	and r3, r2, #1
	.include "src/parts/fn_08020e98_p2.inc"
	.include "src/parts/fn_08020e98_p3.inc"
	.include "src/parts/fn_08020e98_p4.inc"
