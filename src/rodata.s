@ rodata.s - fixed data (V1.2.0 0x08046254..0x080BE67F): format tables, number constants, function
@ pointer tables, the text pointer tables, fonts and glyph bitmaps, pictures and the scatter-load region
@ table (0x080BE314). The initial RAM image it names is src/ram_init.s (typed source, copied at reset).
@ Number tables, runtime library constants and small tables are typed here with their values;
@ computed tables come from assets/tables/ (tools/make_tables.py of the project folder), the FatFs
@ code page and case tables from assets/tables/fat_*.bin (FatFs R0.15, LICENSE-FatFs.txt), the FPGA
@ stream and the filter bank are the vendor's data kept for now (assets/vendor_kept/). The fonts and
@ pictures still come from assets/rodata.bin. Words that hold code addresses are written as symbols,
@ and so are the data addresses (font key array pointers, scatter-load table). The text pointer tables
@ (0x0804bf28..0x0804c9fb) are typed as .word lists of the English strings of src/text.s; the
@ vendor text area (0x080bb416..0x080be05b, every language) is not part of the image any more.
@ Where code reaches several objects from one label with fixed offsets, a .if/.error guard keeps
@ those offsets.
@ Labels d_<address> are the addresses the code refers to.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb
	.section .rodata.fixed,"a",%progbits
	.p2align 2                                         @ section alignment 4 (emits nothing here): the word and halfword tables keep their alignment
	.global rodata_start
rodata_start:
@ d_08046254: upper case digit text '0123456789ABCDEF@0X', target of the distance word of format_hex_u64 (src/format_10.s .L080075b0)
	.global d_08046254
d_08046254:
	.ascii "0"                                         @ printf digit text, upper case: '0' (index 0)
@ UNREF_08046255: 5 bytes ASCII '12345' (31..35), index 1..5 of the digit text '0123456789ABCDEF' at 0x08046254 | READ: in format_hex_u64, ldr r4,[pc,#132] at 0x0800752a plus add r4,pc at 0x0800752c (word 0x0003ed24 at 0x080075b0 + 0x08007530) gives r4 = 0x08046254, taken when bit 11 of the halfword [r0] is set (lsls #20 / bpl at 0x08007526 / 0x08007528); ldrb r7,[r4,r7] at 0x08007544 with r7 = r2 & 15 (and.w at 0x0800753e), so the index is 0..15
	.global UNREF_08046255
UNREF_08046255:
	.ascii "12345"                                     @ index 1..5
@ DATA_0804625a: 2 bytes ASCII '67' (36 37), index 6..7 of the digit text at 0x08046254 | the value 0x0804625a is an intermediate: ldr r4,[pc,#124] at 0x08007530 loads the same word 0x0003ed24 from 0x080075b0 and add r4,pc at 0x08007532 gives 0x0003ed24 + 0x08007536 = 0x0804625a, then adds r4,#14 at 0x08007534 makes r4 = 0x08046268 (the text '0123456789abcdef'); no instruction reads at 0x0804625a through this value
	.global DATA_0804625a
DATA_0804625a:
	.global d_0804625a
d_0804625a:
	.asciz "6789ABCDEF@0X"                             @ index 6..15, then '@0X' and the NUL
@ d_08046268: lower case digit text '0123456789abcdef@0x'; format_hex_u64 reaches it as d_08046254 + 6 + 14 (second add r4,pc 6 bytes after the first, then adds r4,#14), so these 0x14 bytes stay fixed
	.global d_08046268
d_08046268:
	.asciz "0123456789abcdef@0x"                       @ printf digit text, lower case, 20 bytes with the NUL
	.if (d_08046268 - d_08046254) != 0x14
	.error "format_hex_u64 (src/format_10.s) needs the lower case digit text 0x14 bytes after d_08046254"
	.endif
@ DATA_0804627c: 20 bytes 04 00 00 08 00 00 00 00 00 00 00 02 00 01 00 00 10 00 00 00: flag table of the format parser 080075b4, indexed by (character - 0x20): ' '=0x04, '#'=0x08, '+'=0x02, '-'=0x01, '0'=0x10 | address built by ldr r11 from the literal 0x0003ECB4 at 0x08007738 and add r11,pc at 0x080075c4 (0x0003ECB4 + 0x080075c8 = 0x0804627c)
	.global DATA_0804627c
DATA_0804627c:
	.global d_0804627c
d_0804627c:
	.byte 0x04, 0x00, 0x00, 0x08                       @ ' ' space flag 0x04, '!' '"' none, '#' alternate form 0x08
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00     @ '$' .. '*': no flag
	.byte 0x02, 0x00, 0x01, 0x00, 0x00                 @ '+' sign 0x02, ',' none, '-' left justify 0x01, '.' '/' none
	.byte 0x10, 0x00, 0x00, 0x00                       @ '0' zero padding 0x10, '1' '2' '3' none
@ d_08046290 .. d_08046317: double constants of double_pow (src/math_rt_29.s), runtime library data.
@ The values have the layout and numbers of the constants bp = {1.0, 1.5}, dp_h, dp_l, L1..L6, P1..P5
@ of the e_pow.c algorithm of fdlibm (identified by the numbers; the fdlibm source was not fetched
@ for this file). The code reads bp through d_08046290, dp_h through d_080462a0 + 8*k and dp_l
@ through d_080462b0 + 8*k with k = 0 or 1. Each double is two words, low word first.
	.global d_08046290
d_08046290:
	.word 0x00000000, 0x3ff00000                       @ bp[0] = 1.0
	.word 0x00000000, 0x3ff80000                       @ bp[1] = 1.5
	.global d_080462a0
d_080462a0:
	.word 0x00000000, 0x00000000                       @ dp_h[0] = 0.0
@ UNREF_080462a8: 8 bytes = one 64-bit double 0.5849624872207642 (bytes 00 00 00 40 03 b8 e2 3f) | READ: ldr r0,[pc,#236] at 0x0804410e plus add r0,pc at 0x08044110 gives 0x080462a0; add.w r4,r0,r4,lsl #3 at 0x08044112 and vldr d1,[r4] at 0x0804411a, element size 8; r4 is 0 or 1 (movle r4,#0 at 0x08043e5a, movgt r4,#1 at 0x08043e64, movs r4,#0 at 0x08043e68) and no instruction between 0x08043e72 and 0x08044112 writes r4; this region is r4 = 1
	.global UNREF_080462a8
UNREF_080462a8:
	.word 0x40000000, 0x3fe2b803                       @ dp_h[1] = 0.5849624872207642 (high part of log2(1.5))
	.global d_080462b0
d_080462b0:
	.word 0x00000000, 0x00000000                       @ dp_l[0] = 0.0
@ UNREF_080462b8: 8 bytes = one 64-bit double 1.350039202129749e-08 (bytes 06 d0 cf 43 eb fd 4c 3e) | READ: ldr r0,[pc,#284] at 0x080440d8 plus add r0,pc at 0x080440da gives 0x080462b0; add.w r0,r0,r4,lsl #3 at 0x080440dc and vldr d1,[r0] at 0x080440e0, element size 8; r4 is 0 or 1 (set at 0x08043e5a, 0x08043e64, 0x08043e68; not written between 0x08043e72 and 0x080440dc); this region is r4 = 1
	.global UNREF_080462b8
UNREF_080462b8:
	.word 0x43cfd006, 0x3e4cfdeb                       @ dp_l[1] = 1.350039202129749e-08 (low part: dp_h[1] + dp_l[1] = log2(1.5))
@ DATA_080462c0: 48 bytes = 6 64-bit doubles 0.5999999999999946, 0.4285714285785502, 0.33333332981837743, 0.272728123808534, 0.23066074577556175, 0.20697501780033842 | add r0,pc at 0x08043f72 builds this address | double_pow: double-precision x^y routine with special cases for y==0, NaN/inf, 1.0, 2.0, 0.5
	.global DATA_080462c0
DATA_080462c0:
	.global d_080462c0
d_080462c0:
	.word 0x33333303, 0x3fe33333                       @ L1 = 0.5999999999999946
	.word 0xdb6fabff, 0x3fdb6db6                       @ L2 = 0.4285714285785502
	.word 0x518f264d, 0x3fd55555                       @ L3 = 0.33333332981837743
	.word 0xa91d4101, 0x3fd17460                       @ L4 = 0.272728123808534
	.word 0x93c9db65, 0x3fcd864a                       @ L5 = 0.23066074577556175
	.word 0x4a454eef, 0x3fca7e28                       @ L6 = 0.20697501780033842
@ DATA_080462f0: 5 x 64-bit float, 40 bytes, first 0x3fc555555555553e | the array argument of 0x08044c58 (r0 = 0x080462f0 from add r0,pc at 0x0804440c, r1 = 5 from movs r1,#5 at 0x0804440a, call at 0x0804440e), which evaluates the elements from a[4] down to a[0] with 0x0804577c and 0x08044fac.
	.global DATA_080462f0
DATA_080462f0:
	.global d_080462f0
d_080462f0:
	.word 0x5555553e, 0x3fc55555                       @ P1 = 0.16666666666666602
	.word 0x16bebd93, 0xbf66c16c                       @ P2 = -0.0027777777777015593
	.word 0xaf25de2c, 0x3f11566a                       @ P3 = 6.613756321437934e-05
	.word 0xc5d26bf1, 0xbebbbd41                       @ P4 = -1.6533902205465252e-06
	.word 0x72bea4d0, 0x3e663769                       @ P5 = 4.1381367970572385e-08
@ DATA_08046318: 4 bytes 00 00 00 00 = float 0.0, the first float of a table of 8-byte pairs of floats spanning 0x08046318..0x08046397 (this region plus DATA_0804631c, 16 pairs) | vldr.32 s6,[r0] at 0x0804467a with r0 = table + 8*r1 (add.w r0,r0,r1,lsl #3 at 0x08044676) | float_pow: single-precision x^y routine with special cases for y==0, x==1.0, NaN, inf
	.global DATA_08046318
DATA_08046318:
	.global d_08046318
d_08046318:
@ 16 pairs of float32 (a, b), written as their bit patterns; how the library computed them was not
@ determined (UNPROVEN): a rises 0 .. 15.265625 in steps near 1.1, b is below 0.002 in magnitude.
	.word 0x00000000, 0x00000000                       @ pair 0: 0.0, 0.0
@ (vldr.32 s3,[r0,#0x4] at 0x0804467e of V1.2.0 reads the second float of the pair at table + 8*r1)
	.word 0x3fb30000, 0x3a7dbeb2                       @ pair 1: 1.3984375, 0.00096795999
	.word 0x402e0000, 0x3851cfdf                       @ pair 2: 2.71875, 5.0023078e-05
	.word 0x407e0000, 0xbafa51bf                       @ pair 3: 3.96875, -0.0019097849
	.word 0x40a4e000, 0xbac3da19                       @ pair 4: 5.15234375, -0.0014942318
	.word 0x40c8e000, 0xb98aedc2                       @ pair 5: 6.27734375, -0.00026498555
	.word 0x40eb4000, 0xba2c1fcd                       @ pair 6: 7.3515625, -0.0006566018
	.word 0x41061000, 0xbafaff2a                       @ pair 7: 8.37890625, -0.0019149531
	.word 0x4115c000, 0x37d1cfdf                       @ pair 8: 9.359375, 2.5011539e-05
	.word 0x4124d000, 0x3a70979a                       @ pair 9: 10.30078125, 0.00091778638
	.word 0x41335000, 0x368e4789                       @ pair 10: 11.20703125, 4.2402576e-06
	.word 0x41414000, 0x389d5be7                       @ pair 11: 12.078125, 7.5034615e-05
	.word 0x414eb000, 0xb9980ac0                       @ pair 12: 12.91796875, -0.00028999709
	.word 0x415ba000, 0x3a948f55                       @ pair 13: 13.7265625, 0.001133422
	.word 0x41683000, 0xbac092da                       @ pair 14: 14.51171875, -0.0014692203
	.word 0x41744000, 0x3ac6b362                       @ pair 15: 15.265625, 0.0015159661
@ DATA_08046398: 64 bytes = 16 32-bit floats rising 1.0, 1.043945, 1.090332, 1.138672, 1.188965, 1.241699, 1.296387, 1.354004, 1.414062, 1.476562, 1.541992, 1.610352, 1.681641, 1.755859, 1.833984, 1.915039 | vldr.32 s0,[r0] at 0x080447ba with r0 = base + 4*(x & 15) (and.w r0,r0,#15 at 0x0804478a; add.w r0,r1,r0,lsl #2 at 0x080447b4) | float_pow: single-precision x^y routine
	.global DATA_08046398
DATA_08046398:
	.global d_08046398
d_08046398:
@ 2^(k/16) high parts, k = 0..15 (float32 with at most 12 significant mantissa bits; hi[k] + lo[k]
@ of the next table equals 2^(k/16) within 1.45e-11, DATA_INVENTORY 5)
	.word 0x3f800000, 0x3f85a000, 0x3f8b9000, 0x3f91c000 @ 1.0, 1.0439453125, 1.09033203125, 1.138671875
	.word 0x3f983000, 0x3f9ef000, 0x3fa5f000, 0x3fad5000 @ 1.18896484375, 1.24169921875, 1.29638671875, 1.35400390625
	.word 0x3fb50000, 0x3fbd0000, 0x3fc56000, 0x3fce2000 @ 1.4140625, 1.4765625, 1.5419921875, 1.6103515625
	.word 0x3fd74000, 0x3fe0c000, 0x3feac000, 0x3ff52000 @ 1.681640625, 1.755859375, 1.833984375, 1.9150390625
@ DATA_080463d8: 64 bytes = 16 32-bit floats of small magnitude 0.0, 0.00032847, 0.00017570, 0.00011676, 0.00024227, 0.00015859, 0.00045284, 0.00025164, 0.00015106, 0.00026365, 0.00021864, 0.00013877, 0.00015221, 0.00039279, 2.3711e-05, 0.00016750 | vldr.32 s2,[r1] at 0x0804479c with r1 = base + 4*(x & 15) (add.w r1,r1,r0,lsl #2 at 0x08044798); s2 then accumulates vmla.f32 s2,s3,s0 at 0x080447ae | float_pow: single-precision x^y routine
	.global DATA_080463d8
DATA_080463d8:
	.global d_080463d8
d_080463d8:
@ 2^(k/16) low parts, k = 0..15 (float32)
	.word 0x00000000, 0x39ac367d, 0x39383c7d, 0x38f4dceb @ 0.0, 0.00032846993, 0.00017570141, 0.00011675976
	.word 0x397e0a32, 0x39264c12, 0x39ed6a9b, 0x3983eea4 @ 0.00024227126, 0.00015859332, 0.0004528359, 0.00025164068
	.word 0x391e667f, 0x398a39f6, 0x3965422b, 0x391182a4 @ 0.00015106237, 0.00026364595, 0.00021863791, 0.00013876945
	.word 0x391f995b, 0x39cdeec3, 0x37c6e7dd, 0x392fa2a5 @ 0.00015220551, 0.00039278538, 2.3711409e-05, 0.0001674989
@ DATA_08046418: 63 bytes = 15 whole 32-bit floats 1.0, 1.0442737, 1.0905077, 1.1387886, 1.189207, 1.2418578, 1.2968396, 1.3542556, 1.4142135, 1.4768262, 1.5422108, 1.6104903, 1.6817929, 1.7562522, 1.8340081 plus 3 bytes of a 16th float (whose 4 bytes 0x08046454..0x08046457 read 1.9152066) | vldr.32 s3,[r1] at 0x080447a8 with r1 = base + 4*(x & 15) (add.w r1,r1,r0,lsl #2 at 0x080447a4) | float_pow: single-precision x^y routine
	.global DATA_08046418
DATA_08046418:
	.global d_08046418
d_08046418:
@ 2^(k/16), k = 0..15, each the correctly rounded float32 (16 of 16, DATA_INVENTORY 5)
	.word 0x3f800000, 0x3f85aac3, 0x3f8b95c2, 0x3f91c3d3 @ 1.0, 1.0442737, 1.0905077, 1.1387886
	.word 0x3f9837f0, 0x3f9ef532, 0x3fa5fed7, 0x3fad583f @ 1.1892071, 1.2418578, 1.2968396, 1.3542556
	.word 0x3fb504f3, 0x3fbd08a4, 0x3fc5672a, 0x3fce248c @ 1.4142135, 1.4768262, 1.5422108, 1.6104903
	.word 0x3fd744fd, 0x3fe0ccdf, 0x3feac0c7, 0x3ff5257d @ 1.6817929, 1.7562522, 1.8340081, 1.9152066
@ d_08046458: lower case digit text '0123456789abcdefxp' of format_float_hex; reached as d_0804646b + 6 - 0x19 (src/format_10.s .L08007e98)
	.global d_08046458
d_08046458:
	.asciz "0123456789abcdefxp"                        @ 19 bytes with the NUL
@ d_0804646b: upper case digit text '0123456789ABCDEFXP' of format_float_hex, target of its distance word (src/format_10.s .L08008080); then 2 zero bytes
	.global d_0804646b
d_0804646b:
	.asciz "0123456789ABCDEFXP"                        @ 19 bytes with the NUL
	.byte 0x00, 0x00                                   @ padding to the word at d_08046480
	.if (d_0804646b - d_08046458) != 0x13
	.error "format_float_hex (src/format_10.s) needs the upper case digit text 0x13 bytes after the lower case one"
	.endif
	.global d_08046480
d_08046480:
	.word 0x00000000, 0x00000000                       @ double 0.0 (read by fn_08008114, src/format_10.s .L08008122)
	.global d_08046488
d_08046488:
	.word 0x00000000, 0x00000000                       @ double 0.0 (read by double_pow, src/math_rt_29.s)
@ DATA_08046490: 60 bytes = 5 entries of 12 bytes (stride 0xc), each three 32-bit words: (0x00004002, 0xa0000000, 0x0), (0x00004005, 0xc8000000, 0x0), (0x0000400c, 0x9c400000, 0x0), (0x00004019, 0xbebc2000, 0x0), (0x00004034, 0x8e1bc9bf, 0x04000000) | with word0 as exponent (bias 0x3fff) and words 1,2 as the 64-bit mantissa the entries equal 10, 100, 10000, 1e8, 1e16 | add.w r1,r10,r1,lsl #2 at 0x080084ac | fn_08008448: combines 12-byte table entries with 0804356a and divides with 08043540 when n is negative
	.global DATA_08046490
DATA_08046490:
	.global d_08046490
d_08046490:			@ reached by fn_08008448 as d_0804650c - 0x7c (src/format_10.s .L08008496)
	.word 0x00004002, 0xa0000000, 0x00000000           @ 10    (exponent 0x4002, mantissa 0xa0000000:00000000)
	.word 0x00004005, 0xc8000000, 0x00000000           @ 100
	.word 0x0000400c, 0x9c400000, 0x00000000           @ 1e4
	.word 0x00004019, 0xbebc2000, 0x00000000           @ 1e8
	.word 0x00004034, 0x8e1bc9bf, 0x04000000           @ 1e16
@ DATA_080464cc: 4 bytes b5 40 00 00 = word 0x000040b5, word 0 (exponent word) of the 16-byte entry at 0x080464cc | ldm.w r0,{r1,r2,r3} at 0x080084d4 loads words 0..2 of the entry | entry words (0x000040b5, 0xd0cf4b50, 0xcfe20766, 0x00000001) equal 1e55 with the same reading as the table at 0x08046490 | fn_08008448: combines 12-byte table entries with 0804356a
	.global DATA_080464cc
DATA_080464cc:
	.global d_080464cc
d_080464cc:			@ reached by fn_08008448 as d_0804650c - 0x40 (src/format_10.s .L080084c2)
@ 16-byte entries: exponent word, mantissa high, mantissa low, then word 3 (1 or -1, read by
@ ldr r0,[r0,#0xc] at 0x080084dc). The values are 1e55, 1e110, 1e220, 1e440 to the 64-bit
@ mantissa (relative errors 1.1e-23, 2.1e-20, -1.1e-20, -1.4e-20, computed with fractions);
@ that word 3 is the sign of the rounding error fits these four (+, +, -, -) but is UNPROVEN.
	.word 0x000040b5, 0xd0cf4b50, 0xcfe20766           @ 1e55
@ (V1.2.0 named the words of this entry DATA_080464d0 / DATA_080464d4; nothing refers to them)
@ DATA_080464d8: 52 bytes = word 0x00000001 (word 3 of the entry at 0x080464cc, read by ldr r0,[r0,#0xc] at 0x080084dc) followed by three 16-byte entries (0x0000416c, 0xaa51823e, 0x34a7eedf, 0x00000001), (0x000042d9, 0xe2a0b5dc, 0x971f303a, 0xffffffff), (0x000045b4, 0xc8a025fd, 0x4fc1a3e9, 0xffffffff) = 1e110, 1e220, 1e440 with the exponent/mantissa reading used for 0x08046490 | stride 0x10 | fn_08008448: combines 12-byte table entries with 0804356a
	.global DATA_080464d8
DATA_080464d8:
	.word 0x00000001                                   @ word 3 of the 1e55 entry
	.word 0x0000416c, 0xaa51823e, 0x34a7eedf, 0x00000001 @ 1e110
	.word 0x000042d9, 0xe2a0b5dc, 0x971f303a, 0xffffffff @ 1e220
	.word 0x000045b4, 0xc8a025fd, 0x4fc1a3e9, 0xffffffff @ 1e440
@ d_0804650c: 12-byte extended value 1.0 (words 0x00003fff, 0x80000000, 0), target of fn_08008448's distance word (src/format_10.s .L08008528)
	.global d_0804650c
d_0804650c:
	.word 0x00003fff, 0x80000000, 0x00000000           @ 1.0
@ d_08046518: 12-byte extended value 1.0 again plus a zero word; reached by fn_08008448 as d_0804650c + 0xc (src/format_10.s .L0800845e)
	.global d_08046518
d_08046518:
	.word 0x00003fff, 0x80000000, 0x00000000           @ 1.0
	.word 0x00000000                                   @ zero word
@ fn_08008448 reaches four tables from one distance word, each through its own fixed place in the code:
@ the block 0x08046490..0x08046527 keeps these distances to d_0804650c
	.if (d_08046518 - d_0804650c) != 0xc
	.error "fn_08008448 (src/format_10.s) needs d_08046518 = d_0804650c + 0xc"
	.endif
	.if (d_0804650c - d_08046490) != 0x7c
	.error "fn_08008448 (src/format_10.s) needs d_08046490 = d_0804650c - 0x7c"
	.endif
	.if (d_0804650c - d_080464cc) != 0x40
	.error "fn_08008448 (src/format_10.s) needs d_080464cc = d_0804650c - 0x40"
	.endif
	.global d_08046528
d_08046528:
@ 32 bytes 0x08046528..0x08046547 (V1.2.0 values): byte table of fn_080400b8 (src/keys_26.s, base
@ d_08046528 in r10, read at [base + 3k], [base + 3k + 1..2] and [base + 3k + 15..17], k = 0..4) and
@ the word before the handler table d_08046548. What the numbers stand for is UNPROVEN.
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
@ UNREF_0804652f: 8 bytes 08 09 0a 0b 0c 0d 0e 0f (ascending) | READ: the function containing 0x08040382 holds sl = 0x08046528 (movw at 0x08040382, movt at 0x08040392); r6 = 0,3,6,9,12 (movs r6,#0 at 0x0804039e, adds r6,#3 at 0x080403a8, cmp r6,#15 / beq at 0x080403aa); bytes are loaded with ldrb.w r1,[sl,r6] (0x080403e8, 0x08040406), ldrb r5,[r5,#15] after add.w r5,sl,r6 (0x080403d2, 0x080403d6), [r5,#16] (0x08040432, 0x08040436), [r5,#17] (0x08040494, 0x08040498), [r1,#1] (0x08040448, 0x0804044c and 0x08040466, 0x0804046a) and [r1,#2] (0x080404ae, 0x080404b2 and 0x080404d2, 0x080404d6), so the bytes 0x08046528..0x08046545 are addressed; this region (0x0804652f..0x08046536) is inside that range (offsets 7..14 from 0x08046528: [sl,r6] reaches 0x08046531 and 0x08046534, [r1,#1] reaches 0x0804652f, 0x08046532, 0x08046535, [r1,#2] reaches 0x08046530, 0x08046533, 0x08046536)
	.global UNREF_0804652f
UNREF_0804652f:
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte 0x00, 0x10, 0x00, 0x11, 0x12, 0x13, 0x14, 0x00
@ UNREF_0804653f: 5 bytes 15 16 00 00 00 | READ: the function containing 0x08040382 holds sl = 0x08046528 (movw at 0x08040382, movt at 0x08040392); r6 = 0,3,6,9,12 (movs r6,#0 at 0x0804039e, adds r6,#3 at 0x080403a8, cmp r6,#15 / beq at 0x080403aa); bytes are loaded with ldrb.w r1,[sl,r6] (0x080403e8, 0x08040406), ldrb r5,[r5,#15] after add.w r5,sl,r6 (0x080403d2, 0x080403d6), [r5,#16] (0x08040432, 0x08040436), [r5,#17] (0x08040494, 0x08040498), [r1,#1] (0x08040448, 0x0804044c and 0x08040466, 0x0804046a) and [r1,#2] (0x080404ae, 0x080404b2 and 0x080404d2, 0x080404d6), so the bytes 0x08046528..0x08046545 are addressed; this region (0x0804653f..0x08046543) is offsets 0x17..0x1b from 0x08046528: [r5,#17] with r6 = 6 reaches 0x0804653f, [r5,#15] with r6 = 9 reaches 0x08046540, [r5,#16] with r6 = 9 reaches 0x08046541, [r5,#17] with r6 = 9 reaches 0x08046542, [r5,#15] with r6 = 12 reaches 0x08046543
	.global UNREF_0804653f
UNREF_0804653f:
	.byte 0x15, 0x16, 0x00, 0x00, 0x00
@ DATA_08046544: 4 bytes 00 17 00 00 = word 0x00001700 = element 0 of the word table at 0x08046544 | ldr.w r0,[r0,#-0x4] at 0x08040094 then blx r0 at 0x08040098, with r0 = r8 + 4*byte [sp+7] (add.w at 0x08040090) and r8 = 0x08046548 (movw #0x6548 at 0x08040012, movt at 0x08040028); the words from 0x08046548 on are 0x08009fe1, 0x0800cb51, 0x0800cfcd, 0x0800d121 ... through 0x0800d955 at 0x080465a0 (odd addresses in the code range) | the code at 0x08040012..0x0804009a is inside fn_08040008 (0x08040008..0x0804009b)
	.global DATA_08046544
DATA_08046544:
	.word 0x00001700                                   @ word 0x00001700 (bytes 00 17 00 00)
	.global d_08046548
d_08046548:
.Lsw_08046548:
	.word fn_08009fe0                                  @ 0x08046548 = 0x08009fe1
.Lsw_0804654c:
	.word fn_0800cb50                                  @ 0x0804654c = 0x0800cb51
.Lsw_08046550:
	.word fn_0800cfcc                                  @ 0x08046550 = 0x0800cfcd
.Lsw_08046554:
	.word fn_0800d120                                  @ 0x08046554 = 0x0800d121
.Lsw_08046558:
	.word fn_0800d2f8                                  @ 0x08046558 = 0x0800d2f9
.Lsw_0804655c:
	.word fn_0800d418                                  @ 0x0804655c = 0x0800d419
.Lsw_08046560:
	.word fn_0800d548                                  @ 0x08046560 = 0x0800d549
.Lsw_08046564:
	.word fn_0800d6ac                                  @ 0x08046564 = 0x0800d6ad
.Lsw_08046568:
	.word fn_0800d7e4                                  @ 0x08046568 = 0x0800d7e5
.Lsw_0804656c:
	.word fn_08009fe8                                  @ 0x0804656c = 0x08009fe9
.Lsw_08046570:
	.word fn_0800a148                                  @ 0x08046570 = 0x0800a149
.Lsw_08046574:
	.word fn_0800a900                                  @ 0x08046574 = 0x0800a901
.Lsw_08046578:
	.word fn_0800b1f8                                  @ 0x08046578 = 0x0800b1f9
.Lsw_0804657c:
	.word fn_0800b7cc                                  @ 0x0804657c = 0x0800b7cd
.Lsw_08046580:
	.word fn_0800bd60                                  @ 0x08046580 = 0x0800bd61
.Lsw_08046584:
	.word fn_0800df58                                  @ 0x08046584 = 0x0800df59
.Lsw_08046588:
	.word fn_0800e2f4                                  @ 0x08046588 = 0x0800e2f5
.Lsw_0804658c:
	.word fn_0800e3e4                                  @ 0x0804658c = 0x0800e3e5
.Lsw_08046590:
	.word fn_0800e4f4                                  @ 0x08046590 = 0x0800e4f5
.Lsw_08046594:
	.word fn_0800e60c                                  @ 0x08046594 = 0x0800e60d
.Lsw_08046598:
	.word fn_0800e630                                  @ 0x08046598 = 0x0800e631
.Lsw_0804659c:
	.word fn_0800d834                                  @ 0x0804659c = 0x0800d835
.Lsw_080465a0:
	.word fn_0800d954                                  @ 0x080465a0 = 0x0800d955
@ DATA_080465a4: 36 bytes = 9 32-bit words 0x13, 0x27, 0x4f, 0xc7, 0x18f, 0x31f, 0x7cf, 0xf9f, 0x1f3f (decimal 19, 39, 79, 199, 399, 799, 1999, 3999, 7999) | ldr.w r0,[r1,r0,lsl #0x2] at 0x0802e128 | system_bring_up: bring-up routine (clock enable, pin setup, SysTick delays, external bus, display initialisation sequence)
	.global DATA_080465a4
DATA_080465a4:
	.global d_080465a4
d_080465a4:
	.word 19, 39, 79, 199, 399, 799, 1999, 3999, 7999  @ 2n - 1 for n = 10, 20, 40, 100, 200, 400, 1000, 2000, 4000
@ d_080465c8: 1-2-5 step bytes, indexed by a value modulo 3 (0..2)
	.global d_080465c8
d_080465c8:
	.byte 1, 2
@ UNREF_080465ca: 2 bytes 05 00 = halfword 5; the bytes at 0x080465c8..0x080465c9 are 01 02, then halfwords 10 (0x080465cc), 20, 50, 100, 200 (0x080465d4), 500 (0x080465d6), 1000, 2000, 5000, 10000 follow | READ: the byte table at 0x080465c8 (bytes 01 02 05) is indexed by a value modulo 3 computed by multiplying with 0xaaaaaaab (movw/movt at 0x08020f30/0x08020f34, copied to r5 at 0x08020f50) and subtracting 3*quotient: ldrb r2,[r7,r2] at 0x08020fa4 (r7 = 0x080465c8 from movw/movt at 0x08020f9a/0x08020fa0, index r2 + r3 with r3 = r6 - 4*r6 at 0x08020f94, so index 0..2), ldrb r2,[r3,r2] at 0x080210b0, ldrb r0,[r8,r0] at 0x08026040, ldrb r0,[r4,r0] at 0x0802644a, ldrb r0,[r1,r0] at 0x0802e09c, ldrb r3,[r4,r3] at 0x0803b14c, ldrb.w r3,[r9,r3] at 0x0803b36e, ldrb r0,[r7,r0] at 0x0803b4f4 and ldrb.w r0,[r9,r0] at 0x0803b5dc, each with the same modulo-3 index (0..2); the byte 0x080465ca (value 5) is index 2 and is read; the byte 0x080465cb (value 0) is not addressed through this base (index <= 2) and no other base reaches it
	.global UNREF_080465ca
UNREF_080465ca:
	.hword 5                                           @ byte 5 (index 2 of d_080465c8) and its zero high byte
@ d_080465cc: halfwords 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000 (the halfword 5 before it
@ is the 1-2-5 byte table's last entry)
	.global d_080465cc
d_080465cc:
	.hword 10
@ UNREF_080465ce: 8 bytes = 4 halfwords 0x14, 0x32, 0x64, 0xc8 (20, 50, 100, 200), after the halfwords 5 (0x080465ca) and 10 (0x080465cc) and before 500 at 0x080465d6 | READ: the halfword table at 0x080465cc is read with ldrh.w r2,[r7,r2,lsl #1] at 0x080212c6 (r7 = 0x080465cc from movw/movt at 0x080212bc/0x080212c2, index r2 = ldrb [r2] at 0x080212ba, no compare between the load and the ldrh), ldrh.w r2,[r7,r3,lsl #1] at 0x080212d0, ldrh.w r1,[r0,r1,lsl #1] at 0x0802431a (base from movw/movt at 0x08024312/0x08024316, index ldrb.w [r8,#2] at 0x0802430e) and through lr (movw at 0x080223ca, movt at 0x080223e0), element size 2, so the code allows index 0..255; this region is elements 1..4 (0x080465ce = 0x080465cc + 2)
	.global UNREF_080465ce
UNREF_080465ce:
	.hword 20, 50, 100, 200, 500
@ UNREF_080465d8: 112 bytes: 4 halfwords 0x03e8, 0x07d0, 0x1388, 0x2710 (1000, 2000, 5000, 10000) then 13 64-bit little-endian values 10, 10, 10, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000 (the next value 20000 is at 0x08046648, outside this region) | READ: the halfwords 0x080465d8..0x080465df are elements 6..9 of the halfword table at 0x080465cc (the halfword table at 0x080465cc is read with ldrh.w r2,[r7,r2,lsl #1] at 0x080212c6 (r7 = 0x080465cc from movw/movt at 0x080212bc/0x080212c2, index r2 = ldrb [r2] at 0x080212ba, no compare between the load and the ldrh), ldrh.w r2,[r7,r3,lsl #1] at 0x080212d0, ldrh.w r1,[r0,r1,lsl #1] at 0x0802431a (base from movw/movt at 0x08024312/0x08024316, index ldrb.w [r8,#2] at 0x0802430e) and through lr (movw at 0x080223ca, movt at 0x080223e0), element size 2, so the code allows index 0..255); the 64-bit values from 0x080465e0 are read by ldr.w r4,[ip,r3,lsl #3] at 0x08030b02 and ldr r0,[r0,#4] at 0x08030b1e (add.w r0,ip,r3,lsl #3 at 0x08030b1a) with ip = 0x080465e0 (movw/movt at 0x08030af8/0x08030afc), element size 8, and r3 = ldrb.w [r8,#3520] at 0x08030ae8 (no compare bounds it: cmp r3,#4 at 0x08030aee only selects r2), so the code allows index 0..255
	.global UNREF_080465d8
UNREF_080465d8:
	.hword 1000, 2000, 5000, 10000
@ d_080465e0: u64 table, index = a byte (no bound in fn_08030a70): 10, 10, 10, 10, then 1-2-5 steps
@ 20 .. 2000000000, then 1, 2, 5 = d_080466c8 (same table, indexed by a value modulo 3). Each u64
@ is two words, low word first.
	.global d_080465e0
d_080465e0:
	.word 10, 0, 10, 0, 10, 0, 10, 0
	.word 20, 0, 50, 0, 100, 0, 200, 0
	.word 500, 0, 1000, 0, 2000, 0, 5000, 0
	.word 10000, 0, 20000, 0
@ UNREF_08046650: 128 bytes = 16 64-bit little-endian values 50000, 100000, 200000, 500000, 1000000, 2000000, 5000000, 10000000, 20000000, 50000000, 100000000, 200000000, 500000000, 1000000000, 2000000000, then 1 | READ: the 64-bit values are read with ldr.w r4,[ip,r3,lsl #3] at 0x08030b02 and ldr r0,[r0,#4] at 0x08030b1e where ip = 0x080465e0 and r3 = ldrb.w [r8,#3520] (0x08030ae8, no bound), element size 8, so 0x080465e0 + 8*r3 reaches this region (it starts at element 14); the last value (1 at 0x080466c8..0x080466cf) is also read with base 0x080466c8 (movw/movt at 0x08030aaa/0x08030ab0) by ldr.w r0,[r1,r0,lsl #3] at 0x08030ab8 and ldr r1,[r2,#4] at 0x08030abc, r2 = r1 + 8*r0 (add.w at 0x08030ab4), r0 = value modulo 3 (umull by 0xaaaaaaab at 0x08030a9e, lsrs at 0x08030aa2, sub.w at 0x08030aa4, add at 0x08030aa8) = 0..2, element 0 = 1
	.global UNREF_08046650
UNREF_08046650:
	.word 50000, 0, 100000, 0, 200000, 0, 500000, 0
	.word 1000000, 0, 2000000, 0, 5000000, 0
	.word 10000000, 0, 20000000, 0, 50000000, 0
	.word 100000000, 0, 200000000, 0, 500000000, 0
	.word 1000000000, 0, 2000000000, 0
@ d_080466c8: u64 1, 2, 5 (fn_08030a70, src/measure_37.s:1138, index = value modulo 3)
	.global d_080466c8
d_080466c8:
	.word 1, 0, 2, 0
	.word 5, 0                                         @ u64 5 = d_080466c8 element 2
@ d_080466e0: filter coefficient bank, 344 rows of 16 x s32 (fir_filter_rows, src/measure_38.s;
@ DATA_INVENTORY 5.1), 22016 bytes 0x080466e0..0x0804bcdf of V1.2.0. Vendor data kept for now
@ (owner decision, DATA_DESIGN.md): assets/vendor_kept/filter_bank.bin.
	.global d_080466e0
d_080466e0:
	.incbin "assets/vendor_kept/filter_bank.bin"
	.if (. - d_080466e0) != 22016
	.error "fir_filter_rows (src/measure_38.s) needs the 344 x 64-byte filter bank"
	.endif
@ d_0804bce0: halfwords 125, 250, 500, indexed by a value modulo 3 in compute_channel_measurements
@ (src/measure_33.s:91, 149), then a zero tail; d_0804bce8 (zero word) is also read by
@ scsi_command_dispatch (src/usb_82.s:363).
	.global d_0804bce0
d_0804bce0:
	.hword 125
@ UNREF_0804bce2: 8 bytes fa 00 f4 01 00 00 00 00 = halfwords 0x00fa, 0x01f4, 0x0000, 0x0000 | elements 1 and 2 of the halfword table at 0x0804bce0 (0x007d, 0x00fa, 0x01f4): ldrh.w r0,[r1,r0,lsl #1] at 0x08026734 and ldrh.w r0,[r2,r0,lsl #1] at 0x080267f6 in compute_channel_measurements with r1/r2 = 0x0804bce0 (movw/movt at 0x0802672a/0x08026730 and 0x080267ec/0x080267f2) and r0 = a value minus 3*(value/3) (smmul by 0x55555556 at 0x0802671c); the other halfwords of this region are 0 | a movw/movt pair of one register ending at 0x080304c2 gives 0x0804bce8 (offset 0x6)
	.global UNREF_0804bce2
UNREF_0804bce2:
	.hword 250, 500, 0
	.global d_0804bce8
d_0804bce8:
	.word 0x00000000
	.byte 0x00                                         @ zero byte before the table (the code addresses the table by its own label d_0804bced)
@ DATA_0804bced: 129 bytes: 128 entries 80 9a 45 41 8e 41 8f 80 45 45 45 49 49 49 8e 8f 90 92 92 4f 99 4f 55 55 59 99 9a 9b 9c 9d 9e 9f 41 49 4f 55 a5 a5 a6 a7 a8 a9 aa ab ac ad ae af ... through ff (byte 127 = 0xff), plus a trailing 00 | ldrb r6,[r1,r0] at 0x08036a4a with r1 = 0x0804bced (movw/movt at 0x08036a3e/0x08036a46) and r0 = result & 0x7f (and.w at 0x08036a42), taken when bit 7 of the result of bl 0x08035908 is set (bpl at 0x08036a3c) | path_resolve: walks a path string against a directory object
	.global DATA_0804bced
DATA_0804bced:
	.global d_0804bced
d_0804bced:
@ FatFs data (ChaN, FatFs R0.15 ff.c TBL_CT437, licence assets/tables/LICENSE-FatFs.txt): upper-case
@ CP437 byte for each byte 0x80..0xff of a short file name (ExCvt[], 128 bytes)
	.incbin "assets/tables/fat_oem_upper.bin"
	.if (. - d_0804bced) != 128
	.error "path_resolve (src/filesystem_08.s) needs the 128-byte CP437 upper-case table"
	.endif
	.byte 0x00                                         @ padding: the next table is halfwords
@ d_0804bd6e: FatFs data (R0.15 ffunicode.c uc437[]): Unicode code point of each CP437 byte
@ 0x80..0xff, 128 halfwords (character_code_to_byte, path_resolve, src/filesystem_08.s)
	.global d_0804bd6e
d_0804bd6e:
	.incbin "assets/tables/fat_cp437.bin"
	.if (. - d_0804bd6e) != 256
	.error "path_resolve (src/filesystem_08.s) needs the 128-halfword CP437 to Unicode table"
	.endif
	.hword 0x0000                                      @ padding to the word d_0804be70
@ d_0804be70: the word 4, returned by create_idle_and_tmr_svc_tasks (src/kernel_24.s:690) when task
@ creation returns neither 1 nor -1
	.global d_0804be70
d_0804be70:
	.word 4
	.global d_0804be74
d_0804be74:
.Lsw_0804be74:
	.word fn_0800fd38                                  @ 0x0804be74 = 0x0800fd39
.Lsw_0804be78:
	.word fn_0800fe9c                                  @ 0x0804be78 = 0x0800fe9d
.Lsw_0804be7c:
	.word fn_080104ec                                  @ 0x0804be7c = 0x080104ed
.Lsw_0804be80:
	.word fn_08010d70                                  @ 0x0804be80 = 0x08010d71
.Lsw_0804be84:
	.word fn_08011b74                                  @ 0x0804be84 = 0x08011b75
.Lsw_0804be88:
	.word fn_08012244                                  @ 0x0804be88 = 0x08012245
.Lsw_0804be8c:
	.word fn_08012344                                  @ 0x0804be8c = 0x08012345
.Lsw_0804be90:
	.word fn_08012478                                  @ 0x0804be90 = 0x08012479
.Lsw_0804be94:
	.word fn_08012778                                  @ 0x0804be94 = 0x08012779
.Lsw_0804be98:
	.word fn_08012844                                  @ 0x0804be98 = 0x08012845
.Lsw_0804be9c:
	.word fn_0800fef0                                  @ 0x0804be9c = 0x0800fef1
.Lsw_0804bea0:
	.word fn_0800ffb8                                  @ 0x0804bea0 = 0x0800ffb9
.Lsw_0804bea4:
	.word fn_08010014                                  @ 0x0804bea4 = 0x08010015
.Lsw_0804bea8:
	.word fn_08010158                                  @ 0x0804bea8 = 0x08010159
.Lsw_0804beac:
	.word fn_080101ac                                  @ 0x0804beac = 0x080101ad
.Lsw_0804beb0:
	.word fn_08010200                                  @ 0x0804beb0 = 0x08010201
.Lsw_0804beb4:
	.word fn_0801025c                                  @ 0x0804beb4 = 0x0801025d
.Lsw_0804beb8:
	.word fn_080102b8                                  @ 0x0804beb8 = 0x080102b9
.Lsw_0804bebc:
	.word fn_08010314                                  @ 0x0804bebc = 0x08010315
.Lsw_0804bec0:
	.word fn_080103f4                                  @ 0x0804bec0 = 0x080103f5
.Lsw_0804bec4:
	.word fn_08010584                                  @ 0x0804bec4 = 0x08010585
.Lsw_0804bec8:
	.word fn_0801067c                                  @ 0x0804bec8 = 0x0801067d
.Lsw_0804becc:
	.word fn_080106e8                                  @ 0x0804becc = 0x080106e9
.Lsw_0804bed0:
	.word fn_080107c8                                  @ 0x0804bed0 = 0x080107c9
.Lsw_0804bed4:
	.word fn_080108c0                                  @ 0x0804bed4 = 0x080108c1
.Lsw_0804bed8:
	.word fn_08010924                                  @ 0x0804bed8 = 0x08010925
.Lsw_0804bedc:
	.word fn_08010a1c                                  @ 0x0804bedc = 0x08010a1d
.Lsw_0804bee0:
	.word fn_08010a94                                  @ 0x0804bee0 = 0x08010a95
.Lsw_0804bee4:
	.word fn_08010b80                                  @ 0x0804bee4 = 0x08010b81
.Lsw_0804bee8:
	.word fn_08010c78                                  @ 0x0804bee8 = 0x08010c79
.Lsw_0804beec:
	.word fn_08010e70                                  @ 0x0804beec = 0x08010e71
.Lsw_0804bef0:
	.word fn_08010f68                                  @ 0x0804bef0 = 0x08010f69
.Lsw_0804bef4:
	.word fn_08011048                                  @ 0x0804bef4 = 0x08011049
.Lsw_0804bef8:
	.word fn_08011140                                  @ 0x0804bef8 = 0x08011141
.Lsw_0804befc:
	.word fn_08011238                                  @ 0x0804befc = 0x08011239
.Lsw_0804bf00:
	.word fn_080114c4                                  @ 0x0804bf00 = 0x080114c5
.Lsw_0804bf04:
	.word fn_08011660                                  @ 0x0804bf04 = 0x08011661
.Lsw_0804bf08:
	.word fn_080116ec                                  @ 0x0804bf08 = 0x080116ed
.Lsw_0804bf0c:
	.word fn_080117cc                                  @ 0x0804bf0c = 0x080117cd
.Lsw_0804bf10:
	.word fn_08011828                                  @ 0x0804bf10 = 0x08011829
.Lsw_0804bf14:
	.word fn_08011c10                                  @ 0x0804bf14 = 0x08011c11
.Lsw_0804bf18:
	.word fn_08011d08                                  @ 0x0804bf18 = 0x08011d09
.Lsw_0804bf1c:
	.word fn_08011dfc                                  @ 0x0804bf1c = 0x08011dfd
.Lsw_0804bf20:
	.word fn_08011e84                                  @ 0x0804bf20 = 0x08011e85
.Lsw_0804bf24:
	.word fn_0801215c                                  @ 0x0804bf24 = 0x0801215d
@ ----------------------------------------------------------------------------
@ Text pointer tables. Each word is the address of a string of src/text.s (or 0, or the
@ address of another table). V1.2.0 held one string per language in each row / block; here
@ every language slot names the English string, in the same layout (same word count, order
@ and row / block structure), so the readers are unchanged.
@ ----------------------------------------------------------------------------
@ d_0804bf28: measurement labels, 24 words: English 12 then (V1.2.0: Chinese) 12; the code
@ takes one half or the other by the language byte (draw_waveform_display_p6.inc); both are
@ English now
	.global d_0804bf28
d_0804bf28:
	.word t_080bbaa0, t_080bba4c, t_080bb9f8, t_080bba05   @ Freq: Peri: Duty+: Duty-:
	.word t_080bb9f2, t_080bb9ff, t_080bbab7, t_080bba6b   @ Wid+: Wid-: Vmax: Vmin:
	.word t_080bba95, t_080bba9b, t_080bbaa6, t_080bba47   @ Vp-p: Amp: Vrms: Avg:
	.word t_080bbaa0, t_080bba4c, t_080bb9f8, t_080bba05   @ second half: the same 12
	.word t_080bb9f2, t_080bb9ff, t_080bbab7, t_080bba6b
	.word t_080bba95, t_080bba9b, t_080bbaa6, t_080bba47
@ d_0804bf88: 16-byte row table of unit texts, 3 rows of 4 words (row 0 frequency, row 1
@ time, row 2 voltage), read by ldr.w r7,[r0,r3,lsl #2] at 0x0801bd7e in draw_waveform_display
@ (r0 = 0x0804bf88 + 16*byte, movw/movt at 0x0801bd6a/0x0801bd72, lsl #4 at 0x0801bd76)
	.global d_0804bf88
d_0804bf88:
	.word t_080bcee6, t_080bcee1, t_080bcee5               @ Hz KHz MHz
@ UNREF_0804bf94: the last word of row 0 (0) and row 1 (nS uS mS S)
	.global UNREF_0804bf94
UNREF_0804bf94:
	.word 0x00000000
	.word t_080bbcc5, t_080bbcf2, t_080bbca4, t_080bbcf3   @ nS uS mS S
@ DATA_0804bfa8: row 2 (mV V 0 0)
	.global DATA_0804bfa8
DATA_0804bfa8:
	.word t_080bbd2d, t_080bbd2e, 0x00000000, 0x00000000   @ mV V
@ DATA_0804bfb8: 8 bytes = 4 halfwords 0x0190, 0x0320, 0x07d0, 0x0000 (400, 800, 2000, 0) | ldrh.w with index*2 (lsl #0x1) at 0x08026daa, 0x08026e7c, 0x08026fe4, 0x08026cb2 and 0x0801c1ee after movt #0x804 at 0x08026e76, 0x08026cac and 0x0801c1ea | compute_channel_measurements (compute_channel_measurements): scans per channel the 301 bytes at 0x2000044e + ch*0x12d for min and max, forms the midpoint min + (max-min)/2 and counts the samples of the first high run and low run; draw_waveform_display: draw_waveform_display
	.global DATA_0804bfb8
DATA_0804bfb8:
	.global d_0804bfb8
d_0804bfb8:
	.hword 400, 800, 2000, 0
@ d_0804bfc0: lower-case time units (draw_waveform_display_p7.inc)
	.global d_0804bfc0
d_0804bfc0:
	.word t_080bcd62, t_080bcda8, t_080bcd4a, t_080bcda9   @ ns us ms s
@ Status message rows, 8 words each (one per language byte 1..8, read as
@ [row + 4*byte - 4]); every word names the English text
	.global d_0804bfd0
d_0804bfd0:
	.word t_080bb68e, t_080bb68e, t_080bb68e, t_080bb68e   @ Saving...
	.word t_080bb68e, t_080bb68e, t_080bb68e, t_080bb68e
	.global d_0804bff0
d_0804bff0:
	.word t_080bc05b, t_080bc05b, t_080bc05b, t_080bc05b   @ Saved
	.word t_080bc05b, t_080bc05b, t_080bc05b, t_080bc05b
	.global d_0804c010
d_0804c010:
	.word t_080bc04f, t_080bc04f, t_080bc04f, t_080bc04f   @ Save failed
	.word t_080bc04f, t_080bc04f, t_080bc04f, t_080bc04f
	.global d_0804c030
d_0804c030:
	.word t_080bb712, t_080bb712, t_080bb712, t_080bb712   @ Await Trigger...
	.word t_080bb712, t_080bb712, t_080bb712, t_080bb712
	.global d_0804c050
d_0804c050:
	.word t_080bb779, t_080bb779, t_080bb779, t_080bb779   @ Awaiting Auto Measurement...
	.word t_080bb779, t_080bb779, t_080bb779, t_080bb779
	.global d_0804c070
d_0804c070:
	.word t_080bb6c7, t_080bb6c7, t_080bb6c7, t_080bb6c7   @ Awaiting auto-correction...
	.word t_080bb6c7, t_080bb6c7, t_080bb6c7, t_080bb6c7
@ d_0804c090: read by ldr.w r0,[r0,#-4] at 0x0801c9a0 with r0 = 0x0804c090 + 4*idx
@ (movw/movt at 0x0801c994/0x0801c998, add.w at 0x0801c99c); idx = the byte at 0x20001058
	.global d_0804c090
d_0804c090:
	.word t_080bcde0, t_080bcde0, t_080bcde0, t_080bcde0   @ Exceeded Limit
	.word t_080bcde0, t_080bcde0
@ UNREF_0804c0a8: words 7 and 8 of the row d_0804c090
	.global UNREF_0804c0a8
UNREF_0804c0a8:
	.word t_080bcde0, t_080bcde0
	.global d_0804c0b0
d_0804c0b0:
	.word t_080bc87a, t_080bc87a, t_080bc87a, t_080bc87a   @ Waiting for automatic amplitude calibration
	.word t_080bc87a, t_080bc87a, t_080bc87a, t_080bc87a
	.global d_0804c0d0
d_0804c0d0:
.Lsw_0804c0d0:
	.word return_void_2                                @ 0x0804c0d0 = 0x0801f961
.Lsw_0804c0d4:
	.word fn_08012ff4                                  @ 0x0804c0d4 = 0x08012ff5
.Lsw_0804c0d8:
	.word draw_waveform_display                        @ 0x0804c0d8 = 0x080165a9
.Lsw_0804c0dc:
	.word draw_bottom_strip                            @ 0x0804c0dc = 0x0801e785
.Lsw_0804c0e0:
	.word draw_channel_offset_markers_0801f608         @ 0x0804c0e0 = 0x0801f609
.Lsw_0804c0e4:
	.word fn_0801f60c                                  @ 0x0804c0e4 = 0x0801f60d
.Lsw_0804c0e8:
	.word draw_percent_bar                             @ 0x0804c0e8 = 0x0801f661
.Lsw_0804c0ec:
	.word fn_0801f8e0                                  @ 0x0804c0ec = 0x0801f8e1
.Lsw_0804c0f0:
	.word fn_0801f924                                  @ 0x0804c0f0 = 0x0801f925
.Lsw_0804c0f4:
	.word fn_08012ce8                                  @ 0x0804c0f4 = 0x08012ce9
.Lsw_0804c0f8:
	.word return_void_2                                @ 0x0804c0f8 = 0x0801f961
.Lsw_0804c0fc:
	.word fn_08012d2c                                  @ 0x0804c0fc = 0x08012d2d
.Lsw_0804c100:
	.word return_void_2                                @ 0x0804c100 = 0x0801f961
.Lsw_0804c104:
	.word return_void_2                                @ 0x0804c104 = 0x0801f961
.Lsw_0804c108:
	.word return_void_2                                @ 0x0804c108 = 0x0801f961
.Lsw_0804c10c:
	.word return_void_2                                @ 0x0804c10c = 0x0801f961
.Lsw_0804c110:
	.word return_void_2                                @ 0x0804c110 = 0x0801f961
.Lsw_0804c114:
	.word fn_08012d84                                  @ 0x0804c114 = 0x08012d85
.Lsw_0804c118:
	.word fn_08012de0                                  @ 0x0804c118 = 0x08012de1
.Lsw_0804c11c:
	.word draw_panels_by_selector_20001062             @ 0x0804c11c = 0x08013339
.Lsw_0804c120:
	.word return_void_2                                @ 0x0804c120 = 0x0801f961
@ UNREF_0804c124: 4 bytes 41 57 01 08 = word 0x08015741, the entry 0x08015740 of fn_08015740 with bit 0 set | no reference found
	.global UNREF_0804c124
UNREF_0804c124:
.Lsw_0804c124:
	.word fn_08015740                                  @ 0x0804c124 = 0x08015741
.Lsw_0804c128:
	.word draw_six_row_list_from_first_index           @ 0x0804c128 = 0x0801579d
.Lsw_0804c12c:
	.word return_void_2                                @ 0x0804c12c = 0x0801f961
.Lsw_0804c130:
	.word draw_three_value_rows                        @ 0x0804c130 = 0x08015989
.Lsw_0804c134:
	.word return_void_2                                @ 0x0804c134 = 0x0801f961
.Lsw_0804c138:
	.word draw_header_image_120                        @ 0x0804c138 = 0x08015c09
.Lsw_0804c13c:
	.word draw_arc_gauge                               @ 0x0804c13c = 0x08015c71
.Lsw_0804c140:
	.word draw_seven_icon_row                          @ 0x0804c140 = 0x080163f9
.Lsw_0804c144:
	.word draw_value_panel                             @ 0x0804c144 = 0x0801cab1
.Lsw_0804c148:
	.word fn_0801ccfc                                  @ 0x0804c148 = 0x0801ccfd
.Lsw_0804c14c:
	.word draw_six_row_list                            @ 0x0804c14c = 0x0801cd59
.Lsw_0804c150:
	.word draw_page_by_selector_nibble                 @ 0x0804c150 = 0x0801cf51
.Lsw_0804c154:
	.word return_void_2                                @ 0x0804c154 = 0x0801f961
.Lsw_0804c158:
	.word draw_image_two_texts_and_s_value             @ 0x0804c158 = 0x0801e459
.Lsw_0804c15c:
	.word return_void_2                                @ 0x0804c15c = 0x0801f961
.Lsw_0804c160:
	.word fn_0801e514                                  @ 0x0804c160 = 0x0801e515
.Lsw_0804c164:
	.word return_void_2                                @ 0x0804c164 = 0x0801f961
.Lsw_0804c168:
	.word draw_page_position_bar                       @ 0x0804c168 = 0x0801e571
.Lsw_0804c16c:
	.word draw_thumbnail_grid                          @ 0x0804c16c = 0x0801ede9
.Lsw_0804c170:
	.word return_void_2                                @ 0x0804c170 = 0x0801f961
.Lsw_0804c174:
	.word draw_image_and_three_texts                   @ 0x0804c174 = 0x0801f19d
.Lsw_0804c178:
	.word draw_bitmap_and_text                         @ 0x0804c178 = 0x0801f2c5
.Lsw_0804c17c:
	.word draw_language_list                           @ 0x0804c17c = 0x0801f325
@ DATA_0804c180: 2 bytes 73 8c = halfword 0x8c73, element 0 of the halfword array 0x0804c180: 0x8c73, 0xffff, 0x055f, 0x0000 | ldrh.w r5,[r1,r6,lsl #0x1] at 0x080134f6 with r1 = 0x0804c180 (movw/movt at 0x080134ec/0x080134f0) | draw_panels_by_selector_20001062: menu-panel drawing routine
	.global DATA_0804c180
DATA_0804c180:
	.global d_0804c180
d_0804c180:
	.hword 0x8c73, 0xffff, 0x055f                      @ read as RGB565: grey, white, blue (0x055f is also the colour argument of the message box calls); colour use of this table not traced
	.hword 0x0000                                      @ element 3, no reference found
@ Status message rows 9..12 (8 words each, [row + 4*byte - 4], byte = 0x20001058)
	.global d_0804c188
d_0804c188:
	.word t_080bb682, t_080bb682, t_080bb682, t_080bb682   @ Deleting...
	.word t_080bb682, t_080bb682, t_080bb682, t_080bb682
	.global d_0804c1a8
d_0804c1a8:
	.word t_080bcb6e, t_080bcb6e, t_080bcb6e, t_080bcb6e   @ Image Viewer
	.word t_080bcb6e, t_080bcb6e, t_080bcb6e, t_080bcb6e
@ d_0804c1c8: read by ldr.w r0,[r0,#-4] at 0x08011572 and 0x0801e484 with r0 = 0x0804c1c8 + 4*idx
@ (add.w at 0x0801156e and 0x0801e480), idx = the byte at 0x20001058
	.global d_0804c1c8
d_0804c1c8:
	.word t_080bceb4, t_080bceb4, t_080bceb4, t_080bceb4   @ Battery low, charge now
@ UNREF_0804c1d8: words 5..8 of the row d_0804c1c8
	.global UNREF_0804c1d8
UNREF_0804c1d8:
	.word t_080bceb4, t_080bceb4, t_080bceb4, t_080bceb4
	.global d_0804c1e8
d_0804c1e8:
	.word t_080bc8ae, t_080bc8ae, t_080bc8ae, t_080bc8ae   @ Auto shutdown soon
	.word t_080bc8ae, t_080bc8ae, t_080bc8ae, t_080bc8ae
@ DATA_0804c208: four-element table of row addresses (rows .L0804c338, .L0804c358, .L0804c378,
@ d_0804c398), read by ldr.w r1,[r2,r1,lsl #2] at 0x0801d244 in draw_page_by_selector_nibble
@ (r2 = 0x0804c208 from movw/movt at 0x0801d230/0x0801d23c, r1 = the low 7 bits of r6 after
@ and.w r1,r6,#127 / cmp r1,#3 / bhi at 0x0801d226..0x0801d22c, so 0..3)
	.global DATA_0804c208
DATA_0804c208:
	.global d_0804c208
d_0804c208:
	.word .L0804c338, .L0804c358
@ DATA_0804c210: elements 2 and 3 of the table DATA_0804c208
	.global DATA_0804c210
DATA_0804c210:
	.word .L0804c378, d_0804c398
@ d_0804c218: About page labels, 8 language blocks of 2 words (block = language byte - 1)
	.global d_0804c218
d_0804c218:
	.word t_080bba71, t_080bba52, t_080bba71, t_080bba52   @ "Version:", " Model:"
	.word t_080bba71, t_080bba52, t_080bba71, t_080bba52
	.word t_080bba71, t_080bba52, t_080bba71, t_080bba52
	.word t_080bba71, t_080bba52, t_080bba71, t_080bba52
@ d_0804c258: system settings menu items, 8 language blocks of 7 words, read by
@ ldr.w r0,[r0,#-28] at 0x0801cdac with r0 = 0x0804c258 + 28*idx + 4*r5 (movw/movt at
@ 0x0801cd98/0x0801cda0, rsb r0,r0,r0,lsl #3 at 0x0801cd9c), idx = the byte at 0x20001058
@ (ldrb.w r0,[r4,#3936] at 0x0801cd94). Items: Language, Sound and light, Startup on Boot,
@ Auto Shutdown, USB Sharing, About, Factory Reset. The labels UNREF_* below are pieces of it.
	.global d_0804c258
d_0804c258:
	.word t_080bc168, t_080bcdd0, t_080bce6b, t_080bc8de   @ block 1
	.word t_080bc35e, t_080bce87, t_080bcdab
	.word t_080bc168, t_080bcdd0, t_080bce6b, t_080bc8de   @ block 2 (items 0..3)
	.global UNREF_0804c284
UNREF_0804c284:
	.word t_080bc35e, t_080bce87, t_080bcdab               @ block 2 (items 4..6)
	.word t_080bc168, t_080bcdd0, t_080bce6b, t_080bc8de   @ block 3
	.word t_080bc35e, t_080bce87, t_080bcdab
	.word t_080bc168, t_080bcdd0, t_080bce6b, t_080bc8de   @ block 4
	.word t_080bc35e, t_080bce87, t_080bcdab
	.global UNREF_0804c2c8
UNREF_0804c2c8:
	.word t_080bc168, t_080bcdd0, t_080bce6b, t_080bc8de   @ block 5
	.word t_080bc35e, t_080bce87, t_080bcdab
	.global UNREF_0804c2e4
UNREF_0804c2e4:
	.word t_080bc168, t_080bcdd0, t_080bce6b, t_080bc8de   @ block 6
	.word t_080bc35e, t_080bce87, t_080bcdab
	.word t_080bc168, t_080bcdd0, t_080bce6b, t_080bc8de   @ block 7
	.word t_080bc35e, t_080bce87, t_080bcdab
	.word t_080bc168, t_080bcdd0, t_080bce6b, t_080bc8de   @ block 8
	.word t_080bc35e, t_080bce87, t_080bcdab
@ Page title rows (8 words each, [row + 4*byte - 4]); .L0804c338 .. d_0804c398 are also named
@ by the row table DATA_0804c208, .L0804c358 .. .L0804c378 by d_0804c924
.L0804c338:
	.word t_080bc220, t_080bc220, t_080bc220, t_080bc220   @ None
	.global UNREF_0804c348
UNREF_0804c348:
	.word t_080bc220, t_080bc220, t_080bc220, t_080bc220
.L0804c358:
	.word t_080bcb54, t_080bcb54, t_080bcb54, t_080bcb54   @ Multimeter
	.word t_080bcb54, t_080bcb54, t_080bcb54, t_080bcb54
.L0804c378:
	.word t_080bc225, t_080bc225, t_080bc225, t_080bc225   @ Oscilloscope
	.word t_080bc225, t_080bc225, t_080bc225
@ DATA_0804c394: word 8 of the row .L0804c378; ldr.w r0,[r0,#-0x4] at 0x08010748 in
@ fn_080106e8 and at 0x0801576c in fn_08015740 (base d_0804c398, so language byte 0 would read it)
	.global DATA_0804c394
DATA_0804c394:
	.word t_080bc225
@ d_0804c398: read by ldr.w r0,[r0,#-4] at 0x08010748 and 0x0801576c with r0 = 0x0804c398 + 4*idx
	.global d_0804c398
d_0804c398:
	.word t_080bcbab, t_080bcbab, t_080bcbab, t_080bcbab   @ Signal Generator
	.global UNREF_0804c3a8
UNREF_0804c3a8:
	.word t_080bcbab, t_080bcbab, t_080bcbab
@ DATA_0804c3b4: word 8 of the row d_0804c398; ldr.w r0,[r0,#-0x4] at 0x0801cd28 in fn_0801ccfc
@ and at 0x08010fc8 in fn_08010f68 (base d_0804c3b8)
	.global DATA_0804c3b4
DATA_0804c3b4:
	.word t_080bcbab
	.global d_0804c3b8
d_0804c3b8:
	.word t_080bccfe, t_080bccfe, t_080bccfe, t_080bccfe   @ System Settings
	.word t_080bccfe, t_080bccfe, t_080bccfe, t_080bccfe
@ DATA_0804c3d8: value panel labels, two sets of 3 words (V1.2.0: Chinese, then English), chosen
@ by the language byte in draw_value_panel; ldr.w r0,[r8,r0,lsl #0x2] at 0x0801caf8
	.global DATA_0804c3d8
DATA_0804c3d8:
	.global d_0804c3d8
d_0804c3d8:
	.word t_080bbd30                                       @ MAX
@ DATA_0804c3dc: ldr r0,[r0,#0x4] at 0x0801cbb8
	.global DATA_0804c3dc
DATA_0804c3dc:
	.word t_080bbc4c                                       @ MEAN
@ DATA_0804c3e0: ldr r0,[r0,#0x8] at 0x0801cc64; then the second set
	.global DATA_0804c3e0
DATA_0804c3e0:
	.word t_080bbc51                                       @ MIN
	.word t_080bbd30, t_080bbc4c, t_080bbc51               @ MAX MEAN MIN
@ d_0804c3f0: number formats with 0..4 decimals
	.global d_0804c3f0
d_0804c3f0:
	.word t_080bcc03, t_080bcc0a, t_080bcc11, t_080bcc18, t_080bcc1f
@ DATA_0804c404: unit texts by unit byte; ldr.w r0,[r1,r0,lsl #0x2] at 0x0801636e in
@ draw_arc_gauge (byte 0x20001030) and ldr.w r6,[r0,r3,lsl #0x2] at 0x0801cb64, 0x0801cc18,
@ 0x0801ccc0 in draw_value_panel
	.global DATA_0804c404
DATA_0804c404:
	.global d_0804c404
d_0804c404:
	.word t_080bbd2d, t_080bbd2e, t_080bd8cb, t_080bd8ca   @ mV V Ω kΩ
	.word t_080bd8c6, t_080bbc3e, t_080bbc41, t_080bbc3b   @ MΩ nF uF mF
	.word t_080bbc42, t_080bd03d, t_080bbc02, t_080bbbff   @ F ℃ uA mA
	.word t_080bbc03, t_080bd0d6                           @ A ℉
@ d_0804c43c: multimeter function names, 8 language blocks of 12 words, read by
@ ldr.w r0,[r0,#-48] at 0x08010b00 and 0x08015c40 with r0 = 0x0804c43c + 48*idx + 4*col
@ (idx = the byte at 0x20001058). Items: Automatic, DC Voltage, AC Voltage, Continuity, Diode,
@ Resistance, Capacitance, Temperature, Small DC current, Small AC current, Large DC current,
@ Large AC current.
	.global d_0804c43c
d_0804c43c:
	.word t_080bc02e, t_080bc15d, t_080bc152, t_080bced6   @ block 1
	.word t_080bc111, t_080bc0d6, t_080bc0ca, t_080bc238
	.word t_080bce4b, t_080bce29, t_080bce3a, t_080bce18
	.word t_080bc02e, t_080bc15d, t_080bc152, t_080bced6   @ block 2
	.word t_080bc111, t_080bc0d6, t_080bc0ca, t_080bc238
	.word t_080bce4b, t_080bce29, t_080bce3a, t_080bce18
	.word t_080bc02e, t_080bc15d, t_080bc152, t_080bced6   @ block 3
	.word t_080bc111, t_080bc0d6, t_080bc0ca, t_080bc238
	.word t_080bce4b, t_080bce29, t_080bce3a, t_080bce18
	.word t_080bc02e, t_080bc15d, t_080bc152, t_080bced6   @ block 4 (items 0..9)
	.word t_080bc111, t_080bc0d6, t_080bc0ca, t_080bc238
	.word t_080bce4b, t_080bce29
	.global UNREF_0804c4f4
UNREF_0804c4f4:
	.word t_080bce3a, t_080bce18                           @ block 4 (items 10, 11)
	.word t_080bc02e, t_080bc15d, t_080bc152, t_080bced6   @ block 5
	.word t_080bc111, t_080bc0d6, t_080bc0ca, t_080bc238
	.word t_080bce4b, t_080bce29, t_080bce3a, t_080bce18
	.word t_080bc02e, t_080bc15d, t_080bc152, t_080bced6   @ block 6
	.word t_080bc111, t_080bc0d6, t_080bc0ca, t_080bc238
	.word t_080bce4b, t_080bce29, t_080bce3a, t_080bce18
	.word t_080bc02e, t_080bc15d, t_080bc152, t_080bced6   @ block 7 (items 0..7)
	.word t_080bc111, t_080bc0d6, t_080bc0ca, t_080bc238
	.global UNREF_0804c57c
UNREF_0804c57c:
	.word t_080bce4b, t_080bce29, t_080bce3a, t_080bce18   @ block 7 (items 8..11)
	.word t_080bc02e, t_080bc15d, t_080bc152, t_080bced6   @ block 8
	.word t_080bc111, t_080bc0d6, t_080bc0ca, t_080bc238
	.word t_080bce4b, t_080bce29, t_080bce3a, t_080bce18
@ d_0804c5bc: signal generator value names, 8 language blocks of 3 words, read by
@ ldr.w r0,[r0,#-12] at 0x08015a5e with r0 = 0x0804c5bc + 12*idx + 4*r8
	.global d_0804c5bc
d_0804c5bc:
	.word t_080bcecc, t_080bc179, t_080bc117               @ Frequency, Duty Cycle, Amplitude
	.word t_080bcecc, t_080bc179, t_080bc117
	.word t_080bcecc, t_080bc179, t_080bc117
	.word t_080bcecc, t_080bc179, t_080bc117
	.global UNREF_0804c5ec
UNREF_0804c5ec:
	.word t_080bcecc, t_080bc179, t_080bc117
	.word t_080bcecc, t_080bc179, t_080bc117
	.word t_080bcecc, t_080bc179, t_080bc117
	.word t_080bcecc, t_080bc179, t_080bc117
@ d_0804c61c: waveform names, 8 language blocks of 13 words, read by ldr.w r0,[r0,#-52] at
@ 0x080157e6 with r0 = 0x0804c61c + 52*idx + 4*r7 (smlabb at 0x080157dc). Items: Sine Wave,
@ Square Wave, Sawtooth wave, Half-wave, Full Wave, Step Wave, Reverse Step Wave, Index Up,
@ Index Decrease, Direct current, Multi-audio, Sink Pulse, Lorentz waves.
	.global d_0804c61c
d_0804c61c:
	.word t_080bc2ab, t_080bc2b5, t_080bc2dd, t_080bc2eb   @ block 1
	.word t_080bc2c1, t_080bc2d3, t_080bc2cb, t_080bcac9
	.word t_080bc244, t_080bce5c, t_080bc9b5, t_080bc253
	.word t_080bccc0
	.word t_080bc2ab, t_080bc2b5, t_080bc2dd, t_080bc2eb   @ block 2 (items 0..11)
	.word t_080bc2c1, t_080bc2d3, t_080bc2cb, t_080bcac9
	.word t_080bc244, t_080bce5c, t_080bc9b5, t_080bc253
	.global UNREF_0804c680
UNREF_0804c680:
	.word t_080bccc0                                       @ block 2 (item 12)
	.word t_080bc2ab, t_080bc2b5, t_080bc2dd, t_080bc2eb   @ block 3
	.word t_080bc2c1, t_080bc2d3, t_080bc2cb, t_080bcac9
	.word t_080bc244, t_080bce5c, t_080bc9b5, t_080bc253
	.word t_080bccc0
	.word t_080bc2ab, t_080bc2b5, t_080bc2dd, t_080bc2eb   @ block 4
	.word t_080bc2c1, t_080bc2d3, t_080bc2cb, t_080bcac9
	.word t_080bc244, t_080bce5c, t_080bc9b5, t_080bc253
	.word t_080bccc0
	.global UNREF_0804c6ec
UNREF_0804c6ec:
	.word t_080bc2ab, t_080bc2b5, t_080bc2dd, t_080bc2eb   @ block 5
	.word t_080bc2c1, t_080bc2d3, t_080bc2cb, t_080bcac9
	.word t_080bc244, t_080bce5c, t_080bc9b5, t_080bc253
	.word t_080bccc0
	.word t_080bc2ab, t_080bc2b5, t_080bc2dd, t_080bc2eb   @ block 6 (items 0..10)
	.word t_080bc2c1, t_080bc2d3, t_080bc2cb, t_080bcac9
	.word t_080bc244, t_080bce5c, t_080bc9b5
	.global UNREF_0804c74c
UNREF_0804c74c:
	.word t_080bc253, t_080bccc0                           @ block 6 (items 11, 12)
	.word t_080bc2ab, t_080bc2b5, t_080bc2dd, t_080bc2eb   @ block 7 (items 0..7)
	.word t_080bc2c1, t_080bc2d3, t_080bc2cb, t_080bcac9
	.global UNREF_0804c774
UNREF_0804c774:
	.word t_080bc244, t_080bce5c, t_080bc9b5, t_080bc253   @ block 7 (items 8..12)
	.word t_080bccc0
	.word t_080bc2ab, t_080bc2b5, t_080bc2dd, t_080bc2eb   @ block 8
	.word t_080bc2c1, t_080bc2d3, t_080bc2cb, t_080bcac9
	.word t_080bc244, t_080bce5c, t_080bc9b5, t_080bc253
	.word t_080bccc0
@ DATA_0804c7bc: probe ratio texts; ldr.w r0,[r1,r0,lsl #0x2] at 0x0801e92a and 0x0801ea7a in
@ draw_bottom_strip, and in draw_panels_by_selector_20001062
	.global DATA_0804c7bc
DATA_0804c7bc:
	.global d_0804c7bc
d_0804c7bc:
	.word t_080bb979, t_080bb92f                           @ X1 X10
@ DATA_0804c7c4: coupling texts; ldr.w r5,[r1,r0,lsl #0x2] at 0x0801e8d4 and 0x0801ea24 in
@ draw_bottom_strip, and in draw_panels_by_selector_20001062
	.global DATA_0804c7c4
DATA_0804c7c4:
	.global d_0804c7c4
d_0804c7c4:
	.word t_080bbc28, t_080bbc2b                           @ AC DC
@ DATA_0804c7cc: trigger labels, two sets of 3 words (V1.2.0: Chinese, then English), chosen by
@ the language byte in draw_panels_by_selector_20001062; ldr.w r0,[r10,r6,lsl #0x2] at 0x080136c6
	.global DATA_0804c7cc
DATA_0804c7cc:
	.global d_0804c7cc
d_0804c7cc:
	.word t_080bba31                                       @ Mode:
@ DATA_0804c7d0: ldr r0,[r0,#0x4] at 0x08013786
	.global DATA_0804c7d0
DATA_0804c7d0:
	.word t_080bba37                                       @ Edge:
@ DATA_0804c7d4: ldr r0,[r0,#0x8] at 0x08013994; then the second set
	.global DATA_0804c7d4
DATA_0804c7d4:
	.word t_080bba5a                                       @ Channel:
	.word t_080bba31, t_080bba37, t_080bba5a               @ Mode: Edge: Channel:
@ DATA_0804c7e4: trigger modes, two sets of 3 words (V1.2.0: Chinese, then English); read with
@ r5 = 0x0804c7e4 + 12*r8 (r8 = 0 or 1) by ldr.w r0,[r5,r0,lsl #2] at 0x0801eb06 and
@ ldr.w r5,[r1,r0,lsl #2] at 0x0801eb7e in draw_bottom_strip
	.global DATA_0804c7e4
DATA_0804c7e4:
	.global d_0804c7e4
d_0804c7e4:
	.word t_080bc707                                       @ Normal
	.global DATA_0804c7e8
DATA_0804c7e8:
	.word t_080bca92, t_080bc184                           @ Auto Single
	.word t_080bc707, t_080bca92                           @ Normal Auto
	.global UNREF_0804c7f8
UNREF_0804c7f8:
	.word t_080bc184                                       @ Single
@ DATA_0804c7fc: channel names; ldr.w r5,[r1,r0,lsl #0x2] at 0x0801ebde and
@ ldr.w r0,[r0,r1,lsl #0x2] at 0x0801eda4 in draw_bottom_strip, and in
@ draw_panels_by_selector_20001062
	.global DATA_0804c7fc
DATA_0804c7fc:
	.global d_0804c7fc
d_0804c7fc:
	.word t_080bb975, t_080bb9e0                           @ CH1 CH2
@ d_0804c804: oscilloscope settings items, 8 language blocks of 8 words, read by
@ ldr.w r0,[r0,#-32] at 0x08012e44 with r0 = 0x0804c804 + 32*idx + 4*r7 (idx = the byte at
@ 0x20001058, ldrb.w r0,[r9,#3936] at 0x08012e30). Items: Display Mode, Cursor Measurement,
@ Parameter Measurement, CH1 Settings, CH2 Settings, Trigger Settings, Persistence, Mathematics.
	.global d_0804c804
d_0804c804:
	.word t_080bc104, t_080bce05, t_080bcdef, t_080bccce   @ block 1 (items 0..6)
	.word t_080bccdb, t_080bcd0e, t_080bc0e1
	.global UNREF_0804c820
UNREF_0804c820:
	.word t_080bcc33                                       @ block 1 (item 7)
	.word t_080bc104, t_080bce05, t_080bcdef               @ block 2 (items 0..2)
	.global UNREF_0804c830
UNREF_0804c830:
	.word t_080bccce, t_080bccdb, t_080bcd0e, t_080bc0e1   @ block 2 (items 3..7)
	.word t_080bcc33
	.word t_080bc104, t_080bce05, t_080bcdef, t_080bccce   @ block 3
	.word t_080bccdb, t_080bcd0e, t_080bc0e1, t_080bcc33
	.word t_080bc104, t_080bce05, t_080bcdef, t_080bccce   @ block 4
	.word t_080bccdb, t_080bcd0e, t_080bc0e1, t_080bcc33
	.word t_080bc104, t_080bce05, t_080bcdef, t_080bccce   @ block 5 (items 0..5)
	.word t_080bccdb, t_080bcd0e
	.global UNREF_0804c89c
UNREF_0804c89c:
	.word t_080bc0e1, t_080bcc33                           @ block 5 (items 6, 7)
	.word t_080bc104, t_080bce05, t_080bcdef, t_080bccce   @ block 6 (items 0..5)
	.word t_080bccdb, t_080bcd0e
	.global UNREF_0804c8bc
UNREF_0804c8bc:
	.word t_080bc0e1, t_080bcc33                           @ block 6 (items 6, 7)
	.word t_080bc104, t_080bce05, t_080bcdef, t_080bccce   @ block 7 (items 0..5)
	.word t_080bccdb, t_080bcd0e
	.global UNREF_0804c8dc
UNREF_0804c8dc:
	.word t_080bc0e1, t_080bcc33                           @ block 7 (items 6, 7)
	.word t_080bc104, t_080bce05, t_080bcdef               @ block 8 (items 0..2)
	.global UNREF_0804c8f0
UNREF_0804c8f0:
	.word t_080bccce, t_080bccdb, t_080bcd0e, t_080bc0e1   @ block 8 (items 3..6)
@ DATA_0804c900: block 8 item 7; also read as [d_0804c904 + 4*byte - 4] with byte 0 by
@ ldr.w r0,[r0,#-0x4] at 0x08012db0 in fn_08012d84 and at 0x08010374 in fn_08010314
	.global DATA_0804c900
DATA_0804c900:
	.word t_080bcc33
@ d_0804c904: title row (8 words), read by ldr.w r0,[r0,#-4] at 0x08010374 and 0x08012db0
@ with r0 = 0x0804c904 + 4*idx, idx = the byte at 0x20001058
	.global d_0804c904
d_0804c904:
	.word t_080bcce8, t_080bcce8, t_080bcce8, t_080bcce8   @ Oscilloscope Settings
	.word t_080bcce8, t_080bcce8, t_080bcce8
	.global UNREF_0804c920
UNREF_0804c920:
	.word t_080bcce8
@ d_0804c924: four row addresses, read by ldr.w r0,[r1,r0,lsl #2] at 0x080100c2 with
@ r1 = 0x0804c924 (movw/movt at 0x080100ba/0x080100be) and r0 = ldrsb.w [r5,#3945] at
@ 0x080100b2, cmp r0,#3 / bhi at 0x080100b6 / 0x080100b8 (0..3); then the row word by the
@ language byte. The fifth word starts the row .L0804c934.
	.global d_0804c924
d_0804c924:
	.word .L0804c358, .L0804c378, d_0804c398, .L0804c934
.L0804c934:
	.word t_080bcd16                                       @ Settings
	.global UNREF_0804c938
UNREF_0804c938:
	.word t_080bcd16, t_080bcd16, t_080bcd16, t_080bcd16, t_080bcd16
	.global UNREF_0804c94c
UNREF_0804c94c:
	.word t_080bcd16, t_080bcd16
@ DATA_0804c954: volts per division texts (13 words); draw_bottom_strip, display_task_dispatch
	.global DATA_0804c954
DATA_0804c954:
	.global d_0804c954
d_0804c954:
	.word t_080bbd21, t_080bbd26, t_080bbd2b               @ 10mV 20mV 50mV
	.word t_080bbd0f, t_080bbd15, t_080bbd1b               @ 100mV 200mV 500mV
	.word t_080bbd06, t_080bbd09, t_080bbd0c               @ 1V 2V 5V
	.word t_080bbcfa, t_080bbcfe, t_080bbd02               @ 10V 20V 50V
	.word t_080bbcf5                                       @ 100V
@ d_0804c988: time per division texts (29 words); fn_08012ff4, display_task_dispatch,
@ draw_bottom_strip
	.global d_0804c988
d_0804c988:
	.word t_080bbcb9, t_080bbcbe, t_080bbcc3               @ 10nS 20nS 50nS
	.word t_080bbca7, t_080bbcad, t_080bbcb3               @ 100nS 200nS 500nS
	.word t_080bbce9, t_080bbced, t_080bbcf1               @ 1uS 2uS 5uS
	.word t_080bbcda, t_080bbcdf, t_080bbce4               @ 10uS 20uS 50uS
	.word t_080bbcc8, t_080bbcce                           @ 100uS 200uS
	.global UNREF_0804c9c0
UNREF_0804c9c0:
	.word t_080bbcd4                                       @ 500uS
	.word t_080bbc9b, t_080bbc9f, t_080bbca3               @ 1mS 2mS 5mS
	.word t_080bbc8c, t_080bbc91, t_080bbc96               @ 10mS 20mS 50mS
	.word t_080bbc7a, t_080bbc80, t_080bbc86               @ 100mS 200mS 500mS
	.word t_080bbc6d, t_080bbc70, t_080bbc73               @ 1S 2S 5S
	.word t_080bbc65, t_080bbc69                           @ 10S 20S
	.global d_0804c9fc
d_0804c9fc:
	.incbin "assets/rodata.bin", 0x67a8, 2
@ DATA_0804c9fe: 4 bytes f0 00 d2 00 = halfwords 0x00f0, 0x00d2 = halfwords 1 and 2 of the 8-byte record at 0x0804c9fc (0x0140, 0x00f0, 0x00d2, 0x0000) | no instruction reads record 0 of this array: the loop index ip in system_bring_up runs 0..2 (movs ip,#0 at 0x0802b73a; add ip,#1 at 0x0802b744; cmp ip,#3 at 0x0802b74c) and ldrh r2,[r0,#0x2] at 0x0802b76a uses r0 = r6 + 8*(ip+2) (add.w at 0x0802b764), that is records 2..4; ldrh.w r5,[r6,r2,lsl #3] at 0x0802bd26 and ldrsh.w at 0x0802b7a4 and 0x0802ba6a use records 1..4 and 2..4 | system_bring_up: bring-up routine
	.global DATA_0804c9fe
DATA_0804c9fe:
	.incbin "assets/rodata.bin", 0x67aa, 4
@ DATA_0804ca02: 2 bytes 00 00 = halfword 3 of the 8-byte record at 0x0804c9fc (0x0140, 0x00f0, 0x00d2, 0x0000) | no instruction reads record 0 of this array: ldrh r1,[r0,#0x6] at 0x0802b768 uses r0 = r6 + 8*(ip+2) (add.w at 0x0802b764) with ip = 0..2 (cmp ip,#3 at 0x0802b74c), that is records 2..4 | system_bring_up: bring-up routine
	.global DATA_0804ca02
DATA_0804ca02:
	.incbin "assets/rodata.bin", 0x67ae, 20
@ UNREF_0804ca16: 14 bytes = 7 halfwords 0x0067, 0x000a, 0x0008, 0x0104, 0x0068, 0x0005, 0x0006 = the tail of the 8-byte record at 0x0804ca14 (0x00fa, 0x0067, 0x000a, 0x0008) and the whole record at 0x0804ca1c (0x0104, 0x0068, 0x0005, 0x0006) of the same 8-byte-record array as 0x0804c9fc (records 0x0140,0x00f0,0x00d2,0x0000 / 0x0037,0x0067,0x00c2,0x0023 / 0x00f0,0x0066,0x000a,0x000a / ...) | read through the record base 0x0804c9fc (r6): ldrh r1,[r0,#0x6] at 0x0802b768 and ldrh r2,[r0,#0x2] at 0x0802b76a with r0 = r6 + 8*(ip+2) and ip = 1, 2 (records 3 and 4), ldrh r0,[r0] at 0x0802b7ac after adds r0,#4 at 0x0802b772 (field 2), and ldrh.w r5,[r6,r2,lsl #3] at 0x0802bd26 / ldrh.w r6,[r9,#4] at 0x0802bd38 with r2 = 3, 4 | system_bring_up: bring-up routine
	.global UNREF_0804ca16
UNREF_0804ca16:
	.incbin "assets/rodata.bin", 0x67c2, 14
	.global d_0804ca24
d_0804ca24:
	.incbin "assets/rodata.bin", 0x67d0, 2
@ UNREF_0804ca26: 49 bytes 00 00 00 24 67 78 77 74 00 00 00 00 00 00 00 00 00 00 00 3a b8 10 00 ... = offset 2 of the byte array at 0x0804ca24 read as ldrb r3,[r5,r3] at 0x0802be32 (and 0x0802bf66) with r5 = 0x0804ca24 (movw/movt at 0x0802be14/0x0802be22) and r3 = r7*lr+ip (mla at 0x0802be2c); the high nibble (lsr #4 at 0x0802be36) or low nibble (and #15 at 0x0802bf6a) indexes a 16-entry halfword array on the stack (ldrh.w r3,[r3,fp,lsl #1] at 0x0802be3c) and the halfword is stored with strh.w r3,[r10] (0x0802be9a on the high-nibble path, 0x0802bfce on the low-nibble path) in system_bring_up | no reference found for this address itself
	.global UNREF_0804ca26
UNREF_0804ca26:
	.incbin "assets/rodata.bin", 0x67d2, 66
@ UNREF_0804ca68: 29 bytes 00 00 00 00 00 00 00 00 00 00 00 00 00 00 11 22 23 34 45 66 67 40 00 00 00 00 00 00 00 = offset 0x44 of the byte array at 0x0804ca24 read as ldrb r3,[r5,r3] at 0x0802be32 (and 0x0802bf66) with r5 = 0x0804ca24 (movw/movt at 0x0802be14/0x0802be22) and r3 = r7*lr+ip (mla at 0x0802be2c); the high nibble (lsr #4 at 0x0802be36) or low nibble (and #15 at 0x0802bf6a) indexes a 16-entry halfword array on the stack (ldrh.w r3,[r3,fp,lsl #1] at 0x0802be3c) and the halfword is stored with strh.w r3,[r10] (0x0802be9a on the high-nibble path, 0x0802bfce on the low-nibble path) in system_bring_up | no reference found for this address itself
	.global UNREF_0804ca68
UNREF_0804ca68:
	.incbin "assets/rodata.bin", 0x6814, 29
@ DATA_0804ca85: 1846 bytes, first bytes 00 00 00 28 cf ff ff ff ff ff 70 00 00 ... = offset 0x61 of the byte array at 0x0804ca24 (this region ends at 0x0804d1bb, the next byte range starts at 0x0804d1cc); read by ldrb r3,[r5,r3] at 0x0802be32 and 0x0802bf66 with r5 = 0x0804ca24 (movw/movt at 0x0802be14/0x0802be22) and r3 = r7*lr+ip (mla at 0x0802be2c); the high nibble (lsr #4 at 0x0802be36) or low nibble (and #15 at 0x0802bf6a) indexes a 16-entry halfword array on the stack (ldrh.w r3,[r3,fp,lsl #1] at 0x0802be3c) and the halfword is stored with strh.w r3,[r10] (0x0802be9a on the high-nibble path, 0x0802bfce on the low-nibble path) in system_bring_up
	.global DATA_0804ca85
DATA_0804ca85:
	.incbin "assets/rodata.bin", 0x6831, 1863
@ UNREF_0804d1cc: 660 bytes 0f ff ff f4 00 00 00 00 00 00 1c ff ff ff fd 10 00 00 0f ff ff f3 ... ends at 0x0804d460 where DATA_0804d460 begins; same nibble-pair byte style as the array at 0x0804ca24 read by ldrb r3,[r5,r3] at 0x0802be32 in system_bring_up | READ: part of the 4-bit-per-pixel array that starts at 0x0804ca24: ldrb r3,[r5,r3] at 0x0802be32 and 0x0802bf66 with r5 = 0x0804ca24 (movw/movt at 0x0802be14/0x0802be22) and r3 = r7*lr+ip (mla at 0x0802be2c and 0x0802bf60); the high nibble (lsr #4 at 0x0802be36) or low nibble (and #15 at 0x0802bf6a) of the byte is used as an index into a 16-entry halfword array on the stack (ldrh.w r3,[r3,fp,lsl #1] at 0x0802be3c); the instructions 0x0802be0e..0x0802be32 contain no compare that limits r7*lr+ip, so the code allows offset 0x7a8 (0x0804d1cc - 0x0804ca24)
	.global UNREF_0804d1cc
UNREF_0804d1cc:
	.incbin "assets/rodata.bin", 0x6f78, 660
@ DATA_0804d460: 2 bytes ff ff = halfword 0xffff at 0x0804d460 = 0x0804d848 - 1000 | ldrh r4,[r0,r6] at 0x08029eae reads 0x0804d848 + 200*case - 1000 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d460
DATA_0804d460:
	.incbin "assets/rodata.bin", 0x720c, 4
@ DATA_0804d464: 2 bytes 00 00 = halfword 0x0000 at 0x0804d464 = 0x0804d848 - 996 | ldrh r4,[r0,r6] at 0x08029ecc reads 0x0804d848 + 200*case - 996 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d464
DATA_0804d464:
	.incbin "assets/rodata.bin", 0x7210, 2
@ DATA_0804d466: 2 bytes 00 00 = halfword 0x0000 at 0x0804d466 = 0x0804d848 - 994 | ldrh r4,[r0,r6] at 0x08029ed8 reads 0x0804d848 + 200*case - 994 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d466
DATA_0804d466:
	.incbin "assets/rodata.bin", 0x7212, 2
@ DATA_0804d468: 2 bytes 00 00 = halfword 0x0000 at 0x0804d468 = 0x0804d848 - 992 | ldrh r4,[r0,r6] at 0x08029ee2 reads 0x0804d848 + 200*case - 992 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d468
DATA_0804d468:
	.incbin "assets/rodata.bin", 0x7214, 2
@ DATA_0804d46a: 2 bytes 00 00 = halfword 0x0000 at 0x0804d46a = 0x0804d848 - 990 | ldrh r4,[r0,r6] at 0x08029eec reads 0x0804d848 + 200*case - 990 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d46a
DATA_0804d46a:
	.incbin "assets/rodata.bin", 0x7216, 2
@ DATA_0804d46c: 2 bytes 00 00 = halfword 0x0000 at 0x0804d46c = 0x0804d848 - 988 | ldrh r4,[r0,r6] at 0x08029ef6 reads 0x0804d848 + 200*case - 988 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d46c
DATA_0804d46c:
	.incbin "assets/rodata.bin", 0x7218, 2
@ DATA_0804d46e: 2 bytes 00 00 = halfword 0x0000 at 0x0804d46e = 0x0804d848 - 986 | ldrh r4,[r0,r6] at 0x08029f00 reads 0x0804d848 + 200*case - 986 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d46e
DATA_0804d46e:
	.incbin "assets/rodata.bin", 0x721a, 2
@ DATA_0804d470: 2 bytes 00 00 = halfword 0x0000 at 0x0804d470 = 0x0804d848 - 984 | ldrh r4,[r0,r6] at 0x08029f0a reads 0x0804d848 + 200*case - 984 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d470
DATA_0804d470:
	.incbin "assets/rodata.bin", 0x721c, 2
@ DATA_0804d472: 2 bytes 00 0f = halfword 0x0f00 at 0x0804d472 = 0x0804d848 - 982 | ldrh r4,[r0,r6] at 0x08029f14 reads 0x0804d848 + 200*case - 982 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d472
DATA_0804d472:
	.incbin "assets/rodata.bin", 0x721e, 2
@ DATA_0804d474: 2 bytes ff ff = halfword 0xffff at 0x0804d474 = 0x0804d848 - 980 | ldrh r4,[r0,r6] at 0x08029eae reads 0x0804d848 + 200*case - 1000 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d474
DATA_0804d474:
	.incbin "assets/rodata.bin", 0x7220, 2
@ DATA_0804d476: 2 bytes f4 00 = halfword 0x00f4 at 0x0804d476 = 0x0804d848 - 978 | ldrh r4,[r0,r6] at 0x08029eb8 reads 0x0804d848 + 200*case - 998 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d476
DATA_0804d476:
	.incbin "assets/rodata.bin", 0x7222, 2
@ DATA_0804d478: 176 bytes 00 00 00 00 00 00 00 00 00 08 ff ff ff ff ff ff f3 00 00 af ff ff 70 00 ... = 0x0804d848 - 976 .. 0x0804d848 - 801 | ldrh r4,[r0,r6] at 0x08029ecc reads 0x0804d848 + 200*case - 996 + r6 (r6 = 0, 20, ... in steps of adds r6,#20 at 0x08029f20) with case = byte 0x20000f51 in 10..12, so these addresses would need case 0 and no case reaches them in this loop; no instruction found that reads this region | purpose not determined from the code
	.global DATA_0804d478
DATA_0804d478:
	.incbin "assets/rodata.bin", 0x7224, 176
@ DATA_0804d528: 2 bytes 00 00 = halfword 0x0000 at 0x0804d528 = 0x0804d848 - 800 | ldrh r4,[r1,r7] at 0x0802a106 reads 0x0804d848 + 200*case - 800 + r7 (pointer sp+40 = r3-0x320 (0x0802a0b8), r7 = 0, 20, ... in steps of adds r7,#20 at 0x0802a178) with case = byte 0x20000f51 in 7..8, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d528
DATA_0804d528:
	.incbin "assets/rodata.bin", 0x72d4, 2
@ DATA_0804d52a: 2 bytes 00 00 = halfword 0x0000 at 0x0804d52a = 0x0804d848 - 798 | ldrh r4,[r1,r7] at 0x0802a110 reads 0x0804d848 + 200*case - 798 + r7 (pointer sp+28 = r3-0x31e (0x0802a0ca), r7 = 0, 20, ... in steps of adds r7,#20 at 0x0802a178) with case = byte 0x20000f51 in 7..8, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d52a
DATA_0804d52a:
	.incbin "assets/rodata.bin", 0x72d6, 2
@ DATA_0804d52c: 2 bytes 00 00 = halfword 0x0000 at 0x0804d52c = 0x0804d848 - 796 | ldrh r4,[r1,r7] at 0x0802a124 reads 0x0804d848 + 200*case - 796 + r7 (pointer sp+20 = r3-0x31c (0x0802a0d6), r7 = 0, 20, ... in steps of adds r7,#20 at 0x0802a178) with case = byte 0x20000f51 in 7..8, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d52c
DATA_0804d52c:
	.incbin "assets/rodata.bin", 0x72d8, 2
@ DATA_0804d52e: 2 bytes 00 00 = halfword 0x0000 at 0x0804d52e = 0x0804d848 - 794 | ldrh r4,[r1,r7] at 0x0802a130 reads 0x0804d848 + 200*case - 794 + r7 (pointer sp+12 = r3-0x31a (0x0802a0e6), r7 = 0, 20, ... in steps of adds r7,#20 at 0x0802a178) with case = byte 0x20000f51 in 7..8, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d52e
DATA_0804d52e:
	.incbin "assets/rodata.bin", 0x72da, 2
@ DATA_0804d530: 2 bytes 00 00 = halfword 0x0000 at 0x0804d530 = 0x0804d848 - 792 | ldrh r4,[r1,r7] at 0x0802a13a reads 0x0804d848 + 200*case - 792 + r7 (pointer sp+8 = r3-0x318 (0x0802a0f0), r7 = 0, 20, ... in steps of adds r7,#20 at 0x0802a178) with case = byte 0x20000f51 in 7..8, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d530
DATA_0804d530:
	.incbin "assets/rodata.bin", 0x72dc, 2
@ DATA_0804d532: 2 bytes 00 00 = halfword 0x0000 at 0x0804d532 = 0x0804d848 - 790 | ldrh r4,[r1,r7] at 0x0802a144 reads 0x0804d848 + 200*case - 790 + r7 (pointer sp+16 = r3-0x316 (0x0802a0dc), r7 = 0, 20, ... in steps of adds r7,#20 at 0x0802a178) with case = byte 0x20000f51 in 7..8, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d532
DATA_0804d532:
	.incbin "assets/rodata.bin", 0x72de, 2
@ DATA_0804d534: 2 bytes 00 0f = halfword 0x0f00 at 0x0804d534 = 0x0804d848 - 788 | ldrh r4,[r1,r7] at 0x0802a14e reads 0x0804d848 + 200*case - 788 + r7 (pointer sp+24 = r3-0x314 (0x0802a0d0), r7 = 0, 20, ... in steps of adds r7,#20 at 0x0802a178) with case = byte 0x20000f51 in 7..8, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d534
DATA_0804d534:
	.incbin "assets/rodata.bin", 0x72e0, 2
@ DATA_0804d536: 2 bytes ff ff = halfword 0xffff at 0x0804d536 = 0x0804d848 - 786 | ldrh r4,[r1,r7] at 0x0802a158 reads 0x0804d848 + 200*case - 786 + r7 (pointer sp+32 = r3-0x312 (0x0802a0c4), r7 = 0, 20, ... in steps of adds r7,#20 at 0x0802a178) with case = byte 0x20000f51 in 7..8, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d536
DATA_0804d536:
	.incbin "assets/rodata.bin", 0x72e2, 2
@ DATA_0804d538: 2 bytes f4 00 = halfword 0x00f4 at 0x0804d538 = 0x0804d848 - 784 | ldrh r4,[r1,r7] at 0x0802a162 reads 0x0804d848 + 200*case - 784 + r7 (pointer sp+36 = r3-0x310 (0x0802a0be), r7 = 0, 20, ... in steps of adds r7,#20 at 0x0802a178) with case = byte 0x20000f51 in 7..8, so this address itself would need case 0 and no case reaches it in this loop; no instruction found that reads this address | purpose not determined from the code
	.global DATA_0804d538
DATA_0804d538:
	.incbin "assets/rodata.bin", 0x72e4, 2
@ DATA_0804d53a: 2 bytes 00 00 = halfword 0x0000 at 0x0804d53a = 0x0804d848 - 782 | the ldrh at 0x0802a16c in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 782 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x0802a0a4 is reached only for r2 = 7 or 8 (tbh table at 0x08029e30), so its first accesses are 0x0804dab2 (r2=7) and 0x0804db7a (r2=8); this address equals 0x0804d848 - 782 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d53a
DATA_0804d53a:
	.incbin "assets/rodata.bin", 0x72e6, 2
@ DATA_0804d53c: 2 bytes 00 00 = halfword 0x0000 at 0x0804d53c = 0x0804d848 - 780 | the ldrh at 0x0802a106 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 800 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x0802a0a4 is reached only for r2 = 7 or 8 (tbh table at 0x08029e30), so its first accesses are 0x0804daa0 (r2=7) and 0x0804db68 (r2=8); this address equals 0x0804d848 - 780 only for r2 = 0, k = 1 | no instruction was found that reads this address
	.global DATA_0804d53c
DATA_0804d53c:
	.incbin "assets/rodata.bin", 0x72e8, 2
@ DATA_0804d53e: 2 bytes 00 00 = halfword 0x0000 at 0x0804d53e = 0x0804d848 - 778 | the ldrh at 0x0802a110 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 798 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x0802a0a4 is reached only for r2 = 7 or 8 (tbh table at 0x08029e30), so its first accesses are 0x0804daa2 (r2=7) and 0x0804db6a (r2=8); this address equals 0x0804d848 - 778 only for r2 = 0, k = 1 | no instruction was found that reads this address
	.global DATA_0804d53e
DATA_0804d53e:
	.incbin "assets/rodata.bin", 0x72ea, 2
@ DATA_0804d540: 376 bytes 00 00 00 00 04 ef ff ff ff ff f3 00 00 bf ff ff 70 00 ... | the ldrh at 0x0802a124 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 796 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x0802a0a4 is reached only for r2 = 7 or 8 (tbh table at 0x08029e30), so its first accesses are 0x0804daa4 (r2=7) and 0x0804db6c (r2=8); this address equals 0x0804d848 - 776 only for r2 = 0, k = 1 | no instruction was found that reads this address | fill_output_waveform_table: fills 100 halfwords at 0x20000f5a
	.global DATA_0804d540
DATA_0804d540:
	.incbin "assets/rodata.bin", 0x72ec, 376
@ DATA_0804d6b8: 2 bytes 00 0d = halfword 0x0d00 at 0x0804d6b8 = 0x0804d848 - 400 | the ldrh at 0x08029fd6 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 400 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d910 (r2=3) and 0x0804d9d8 (r2=4); this address equals 0x0804d848 - 400 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6b8
DATA_0804d6b8:
	.incbin "assets/rodata.bin", 0x7464, 2
@ DATA_0804d6ba: 2 bytes ff ff = halfword 0xffff at 0x0804d6ba = 0x0804d848 - 398 | the ldrh at 0x08029fe4 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 398 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d912 (r2=3) and 0x0804d9da (r2=4); this address equals 0x0804d848 - 398 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6ba
DATA_0804d6ba:
	.incbin "assets/rodata.bin", 0x7466, 2
@ DATA_0804d6bc: 2 bytes f1 00 = halfword 0x00f1 at 0x0804d6bc = 0x0804d848 - 396 | the ldrh at 0x08029ff0 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 396 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d914 (r2=3) and 0x0804d9dc (r2=4); this address equals 0x0804d848 - 396 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6bc
DATA_0804d6bc:
	.incbin "assets/rodata.bin", 0x7468, 2
@ DATA_0804d6be: 2 bytes 00 00 = halfword 0x0000 at 0x0804d6be = 0x0804d848 - 394 | the ldrh at 0x08029ffe in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 394 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d916 (r2=3) and 0x0804d9de (r2=4); this address equals 0x0804d848 - 394 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6be
DATA_0804d6be:
	.incbin "assets/rodata.bin", 0x746a, 2
@ DATA_0804d6c0: 2 bytes 00 00 = halfword 0x0000 at 0x0804d6c0 = 0x0804d848 - 392 | the ldrh at 0x0802a00c in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 392 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d918 (r2=3) and 0x0804d9e0 (r2=4); this address equals 0x0804d848 - 392 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6c0
DATA_0804d6c0:
	.incbin "assets/rodata.bin", 0x746c, 2
@ DATA_0804d6c2: 2 bytes 00 00 = halfword 0x0000 at 0x0804d6c2 = 0x0804d848 - 390 | the ldrh at 0x0802a016 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 390 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d91a (r2=3) and 0x0804d9e2 (r2=4); this address equals 0x0804d848 - 390 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6c2
DATA_0804d6c2:
	.incbin "assets/rodata.bin", 0x746e, 2
@ DATA_0804d6c4: 2 bytes 00 00 = halfword 0x0000 at 0x0804d6c4 = 0x0804d848 - 388 | the ldrh at 0x0802a020 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 388 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d91c (r2=3) and 0x0804d9e4 (r2=4); this address equals 0x0804d848 - 388 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6c4
DATA_0804d6c4:
	.incbin "assets/rodata.bin", 0x7470, 2
@ DATA_0804d6c6: 2 bytes 00 00 = halfword 0x0000 at 0x0804d6c6 = 0x0804d848 - 386 | the ldrh at 0x0802a02a in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 386 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d91e (r2=3) and 0x0804d9e6 (r2=4); this address equals 0x0804d848 - 386 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6c6
DATA_0804d6c6:
	.incbin "assets/rodata.bin", 0x7472, 2
@ DATA_0804d6c8: 2 bytes 00 00 = halfword 0x0000 at 0x0804d6c8 = 0x0804d848 - 384 | the ldrh at 0x0802a034 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 384 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d920 (r2=3) and 0x0804d9e8 (r2=4); this address equals 0x0804d848 - 384 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6c8
DATA_0804d6c8:
	.incbin "assets/rodata.bin", 0x7474, 2
@ DATA_0804d6ca: 2 bytes 00 5f = halfword 0x5f00 at 0x0804d6ca = 0x0804d848 - 382 | the ldrh at 0x0802a03e in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 382 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d922 (r2=3) and 0x0804d9ea (r2=4); this address equals 0x0804d848 - 382 only for r2 = 0, k = 0 | no instruction was found that reads this address
	.global DATA_0804d6ca
DATA_0804d6ca:
	.incbin "assets/rodata.bin", 0x7476, 2
@ DATA_0804d6cc: 2 bytes ff ff = halfword 0xffff at 0x0804d6cc = 0x0804d848 - 380 | the ldrh at 0x08029fd6 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 400 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d910 (r2=3) and 0x0804d9d8 (r2=4); this address equals 0x0804d848 - 380 only for r2 = 0, k = 1 | no instruction was found that reads this address
	.global DATA_0804d6cc
DATA_0804d6cc:
	.incbin "assets/rodata.bin", 0x7478, 2
@ DATA_0804d6ce: 2 bytes a0 00 = halfword 0x00a0 at 0x0804d6ce = 0x0804d848 - 378 | the ldrh at 0x08029fe4 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 398 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d912 (r2=3) and 0x0804d9da (r2=4); this address equals 0x0804d848 - 378 only for r2 = 0, k = 1 | no instruction was found that reads this address
	.global DATA_0804d6ce
DATA_0804d6ce:
	.incbin "assets/rodata.bin", 0x747a, 2
@ DATA_0804d6d0: 151 bytes 00 7f ff ff 50 00 00 00 ... 04 bf ff ff ff ff ff ... e9 30 00 | the ldrh at 0x08029ff0 in fill_output_waveform_table does not read this address: its base is (0x0804d848 + 200*r2) - 396 plus 20*k (k = 0..9), r2 = byte at 0x20000f51 (ldrb.w r2,[r6,#3673] at 0x08029e22), and the block entered at 0x08029f78 is reached only for r2 = 3 or 4 (tbh table at 0x08029e30), so its first accesses are 0x0804d914 (r2=3) and 0x0804d9dc (r2=4); this address equals 0x0804d848 - 376 only for r2 = 0, k = 1 | no instruction was found that reads this address | fill_output_waveform_table: fills 100 halfwords at 0x20000f5a
	.global DATA_0804d6d0
DATA_0804d6d0:
	.incbin "assets/rodata.bin", 0x747c, 150
	.incbin "assets/rodata.bin", 0x7512, 1		@ 0x0804d766, the byte before the array (the code addresses it by its own label d_0804d767)
@ DATA_0804d767: 1 byte 00 | ldrb r6,[r4,r6] at 0x0802bd94 with r4 = 0x0804d767 (movw/movt at 0x0802bd8c/0x0802bd90) and r6 = r5*lr+ip (mla at 0x0802bd88); the nibble selected by r3 (and.w r3,r3,#1 at 0x0802bd70; cmp r3,#0 at 0x0802bd9c: low nibble from and.w fp,r6,#15 at 0x0802bd98 when r3 != 0, high nibble from moveq.w fp,r6,lsr #4 at 0x0802bda0 when r3 == 0) indexes the halfword array on the stack (add r4,sp,#0x40; ldrh.w r6,[r4,fp,lsl #1] at 0x0802bda4) | system_bring_up: bring-up routine
	.global DATA_0804d767
DATA_0804d767:
	.global d_0804d767
d_0804d767:
	.incbin "assets/rodata.bin", 0x7513, 2
@ UNREF_0804d769: 43 bytes fe b3 00 09 ff ff ff 60 6f ff ff ff f2 df ff ff ff f9 ff ff ff ff fc ff ff ff ff fb bf ff ff ff f8 3f ff ff ff f1 06 ff ff ff 40 = offsets 2.. of the byte array whose base 0x0804d767 is built at 0x0802bd8c/0x0802bd90 in system_bring_up (nibble selected at 0x0802bd98 / 0x0802bda0 by r3 & 1, see 0x0802bd70 and 0x0802bd9c) | no reference found for this address itself
	.global UNREF_0804d769
UNREF_0804d769:
	.incbin "assets/rodata.bin", 0x7515, 47
	.incbin "assets/rodata.bin", 0x7544, 1		@ 0x0804d798
@ d_0804d799: base address that system_bring_up loads (movw/movt, then add r5,r1); own label instead of d_0804d798+1
	.global d_0804d799
d_0804d799:
	.incbin "assets/rodata.bin", 0x7545, 1
@ UNREF_0804d79a: 39 bytes 3a dc 70 00 04 ff ff fb 00 0e ff ff ff 51 3f ff ff ff 95 2f ff ff ff 84 0d ff ff ff 30 02 ef ff f7 00 00 18 ba 40 00 | lies 1 byte after base 0x0804d799 (movw #0xd799 at 0x0802bf50 + movt at 0x0802bf54, add r5,r1 at 0x0802bf58 in system_bring_up) | no reference found for this address itself
	.global UNREF_0804d79a
UNREF_0804d79a:
	.incbin "assets/rodata.bin", 0x7546, 38
	.incbin "assets/rodata.bin", 0x756c, 1		@ 0x0804d7c0, the byte before the table (the code addresses it by its own label d_0804d7c1)
@ DATA_0804d7c1: 1 byte 2a | ldrbeq.w fp,[r1,r0] at 0x0802bbfc with r1 = 0x0804d7c1 (movw #0xd7c1 at 0x0802bbe4, movt at 0x0802bbee) and r0 = r3>>1 (lsreq at 0x0802bbfa) when [sp+0x3c] == 2 (cmp r0,#2 at 0x0802bbf6) | system_bring_up: bring-up routine
	.global DATA_0804d7c1
DATA_0804d7c1:
	.global d_0804d7c1
d_0804d7c1:
	.incbin "assets/rodata.bin", 0x756d, 2
@ UNREF_0804d7c3: 3 bytes 00 ef ff | lies at offset 2..4 after base 0x0804d7c1 (movw #0xd7c1 at 0x0802bbe4 / 0x0802bea6 in system_bring_up) | no reference found for this address itself
	.global UNREF_0804d7c3
UNREF_0804d7c3:
	.incbin "assets/rodata.bin", 0x756f, 5
@ DATA_0804d7c8: 11 bytes ff f0 ff ff e0 cf ff 70 07 95 00 | ldrb r6,[r4,r6] at 0x0802bd94 in system_bring_up (address = r4 + r6 with r4 = 0x0804d767 and r6 = r5*lr+ip from the mla at 0x0802bd88; nibble selected at 0x0802bd98 / 0x0802bda0 by r3 & 1); 0x0804d7c8 = 0x0804d767 + 0x61 | system_bring_up: bring-up routine
	.global DATA_0804d7c8
DATA_0804d7c8:
	.incbin "assets/rodata.bin", 0x7574, 10
	.incbin "assets/rodata.bin", 0x757e, 1		@ 0x0804d7d2, the byte before the rows (the code addresses them by their own label d_0804d7d3)
@ DATA_0804d7d3: 1 byte 00 = byte 0 of the array at 0x0804d7d3 (base 0x0804d7d3 + 32*index: add.w r5,r2,r1,lsl #5 at 0x0801ec74 after movw #0xd7d3 at 0x0801ec54) | ldrb r6,[r5,r6] at 0x0801ecb6 in draw_bottom_strip with a bit test (rsb r1,r1,#7 at 0x0801ecba, lsr.w at 0x0801ecbe, lsls r1,r1,#31 at 0x0801ecc2: most significant bit first) | 16-pixel-wide 1-bit rows of 2 bytes: bit counter r0 counts 0..7 then r4 advances by 1 (cmp r1,#7 at 0x0801eca6, addhi r4,#1 at 0x0801ecac), the bitmap index byte comes from ldrb r1,[r1,#24] at 0x0801ec4e and is multiplied by 32 (lsl #5 at 0x0801ec74) | ldrb r4,[r2,r4] at 0x08013808 and ldrb r1,[r2,r1] at 0x08013866 in draw_panels_by_selector_20001062 use the same style of bit test (lsr by 7-n at 0x08013810, 0x0801386e) | draw_bottom_strip: draws the bottom status strip at y=0xdd; draw_panels_by_selector_20001062: menu-panel drawing routine
	.global DATA_0804d7d3
DATA_0804d7d3:
	.global d_0804d7d3
d_0804d7d3:
	.incbin "assets/rodata.bin", 0x757f, 1
@ DATA_0804d7d4: 27 bytes 00 01 f8 01 f8 01 80 01 80 01 80 03 c0 03 c0 07 e0 0f f0 0f f0 01 80 01 80 1f 80 = bytes 1..27 of the 1-bit array at 0x0804d7d3 | ldrb r1,[r5,r1] at 0x0801ed40 in draw_bottom_strip and ldrb r1,[r2,r1] at 0x08013866 in draw_panels_by_selector_20001062, bit test most significant bit first | draw_bottom_strip: draws the bottom status strip at y=0xdd; draw_panels_by_selector_20001062: menu-panel drawing routine
	.global DATA_0804d7d4
DATA_0804d7d4:
	.incbin "assets/rodata.bin", 0x7580, 28
@ UNREF_0804d7f0: 10 bytes 80 00 00 00 00 1f 80 1f 80 01 = bytes at offset 0x1d..0x26 of the array at 0x0804d7d3 (base 0x0804d7d3 + 32*index per add.w r5,r2,r1,lsl #5 at 0x0801ec74 in draw_bottom_strip) | no reference found for this address itself
	.global UNREF_0804d7f0
UNREF_0804d7f0:
	.incbin "assets/rodata.bin", 0x759c, 10
@ DATA_0804d7fa: 40 bytes 80 01 80 0f f0 0f f0 07 e0 03 c0 03 c0 01 80 01 80 01 80 01 f8 01 f8 00 00 00 00 0f f0 0f f0 0c 30 0c 30 0c fc 0c 78 0c ... = offset 0x27 of the array at 0x0804d7d3 | ldrb.w r11,[r5,#0x0] at 0x0802beb8 in system_bring_up (r5 = 0x0804d7c1 + r6*lr+ip via add r5,r7 at 0x0802beb4, or 0x0804d799 + index at 0x0802bf58); the listing resolves that load to this address | system_bring_up: bring-up routine
	.global DATA_0804d7fa
DATA_0804d7fa:
	.incbin "assets/rodata.bin", 0x75a6, 40
@ DATA_0804d822: 17 bytes 30 0c 30 1e 30 3f 30 0c 30 0c 30 7c 3e 7c 3e 00 00 | ldrb.w r11,[r5,#0x0] at 0x0802beb8 in system_bring_up (same load as 0x0804d7fa) | the 17 bytes end at 0x0804d832, the byte before DATA_0804d833
	.global DATA_0804d822
DATA_0804d822:
	.incbin "assets/rodata.bin", 0x75ce, 16
	.incbin "assets/rodata.bin", 0x75de, 1		@ 0x0804d832, the byte before the table (the code addresses it by its own label d_0804d833)
@ DATA_0804d833: 13 bytes all 01 | ldrb r1,[r1,r0] at 0x0803e558 with r1 = 0x0804d833 (movw #0xd833 at 0x0803e550, movt at 0x0803e554) and r0 = byte [r9+0x2d] (ldrb.w at 0x0803e54c); r1+0x32 is compared with the halfword [r9+0xdb8] (cmp r1,r2 at 0x0803e560) | the code at 0x0803e54c..0x0803e562 lies inside fn_0803e454 (0x0803e454..0x08040007)
	.global DATA_0804d833
DATA_0804d833:
	.global d_0804d833
d_0804d833:
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1     @ index 0..13
@ UNREF_0804d841: 7 bytes 03 05 09 15 29 52 00 | READ: ldrb r1,[r1,r0] at 0x0803e558 with r1 = 0x0804d833 (movw/movt at 0x0803e550/0x0803e554) and r0 = ldrb.w [r9,#45] at 0x0803e54c (no compare shown between them), and ldrb r1,[r3,r1] at 0x0804067c with r3 = 0x0804d833 (movw/movt at 0x08040670/0x08040678) and r1 = ldrb [r0,#45] at 0x08040668 limited by cmp r1,#19 / bhi at 0x0804066c / 0x0804066e (0..19); this region is index 14..20 (0x0804d841 = 0x0804d833 + 14), index 14..19 reachable at 0x0804067c
	.global UNREF_0804d841
UNREF_0804d841:
	.byte 3, 5, 9, 21, 41, 82                          @ index 14..19
	.byte 0                                            @ index 20 (the reader at 0x0804067c bounds the index to 0..19)
@ d_0804d848: anchor of the 1600-byte waveform block 0x0804d848..0x0804de87 (8 tables of 100 halfwords, 200-byte
@ stride). fill_output_waveform_table (src/siggen_55.s) reaches every table as d_0804d848 + 200*case minus
@ 0x3d6..0x3e8, so the block is one unit: only d_0804d848 is a label, the inner layout stays (guard after the block).
	.global d_0804d848
d_0804d848:
@ Our own tables, from tools/make_tables.py (project folder) waves(): 8 x 100 u16, values 0..4095,
@ in the order the cases reach them: T0 sine (case 0), T1 half wave (3), T2 full wave (4),
@ T3 exponential rise "Index Up" (7), T4 1 - exponential "Index Decrease" (8), T5 sum of
@ harmonics 1..5 "Multi-audio" (10), T6 sin(x)/x "Sink Pulse" (11), T7 1/(1+x^2) "Lorentz waves" (12).
	.incbin "assets/tables/waves.bin"
@ DATA_0804de88: 7800 bytes = 300*0x34/2 (the width 300 and height 0x34 passed to 0x0801ffcc), first bytes 00 00 00 38 88 88 88 88 ... | the address is passed as the fifth argument: str r0,[sp,#0x0] at 0x0801cac4 for the call 0801ffcc(10,0xb8,300,0x34,bitmap,0xffff) | draw_value_panel: draws the lower value panel
	.global DATA_0804de88
DATA_0804de88:
	.global d_0804de88
d_0804de88:
	.if (d_0804de88 - d_0804d848) != 1600
	.error "fill_output_waveform_table (src/siggen_55.s) needs the 8 waveform tables as one 1600-byte block at d_0804d848"
	.endif
	.incbin "assets/rodata.bin", 0x7c34, 7800
@ DATA_0804fd00: 8217 bytes = 0xc6*0x53/2 (width 0xc6, height 0x53 passed to 0x0801ffcc), first bytes all 00 ... | the address is passed as the fifth argument: str r0,[sp,#0x0] at 0x0801c7a4, 0x08011f1e and 0x0801f2d4 for calls 0801ffcc(0x3d,0x50,0xc6,0x53,bitmap,0x55f) | fn_08011e84: draws a region 0x3d,0x50,0xc6,0x53 with 0801ffcc; draw_bitmap_and_text: draws a message box; draw_waveform_display: scope-view drawing routine
	.global DATA_0804fd00
DATA_0804fd00:
	.global d_0804fd00
d_0804fd00:
	.incbin "assets/rodata.bin", 0x9aac, 8216
	.incbin "assets/rodata.bin", 0xbac4, 1		@ 0x08051d18, the last byte before the FPGA stream
@ d_08051d19: start of the FPGA configuration stream (115638 bytes to 0x0806e0ce, read as triples by system_bring_up); own label instead of d_08051d18+1
	.global d_08051d19
d_08051d19:
@ Vendor data kept for now (owner decision, DATA_DESIGN.md): assets/vendor_kept/fpga.bin, the bytes
@ 0x08051d19..0x0806e0ce of V1.2.0 (115638 = 3 * 38546). system_bring_up reads it as byte triples from
@ d_08051d19 for 0x1c3b6 bytes (movw/movt at 0x0802db2c/0x0802db36 of V1.2.0).
	.incbin "assets/vendor_kept/fpga.bin"
	.if (. - d_08051d19) != 0x1c3b6
	.error "system_bring_up (src/parts/system_bring_up_p4.inc) sends 0x1c3b6 bytes from d_08051d19"
	.endif
	.byte 0x00                                         @ filler before the word-aligned twiddle table
@ d_0806e0d0: FFT twiddles, 128 float32 pairs (cos(2 pi k/128), sin(2 pi k/128)), correctly rounded,
@ from tools/make_tables.py twiddle() (compute_spectrum_bytes, src/measure_32.s, takes d_0806e0d0 - 16
@ as its base and reads from base + 16 on; fft64_radix8_in_place, src/measure_37.s)
	.global d_0806e0d0
d_0806e0d0:
	.incbin "assets/tables/twiddle.bin"
	.if (. - d_0806e0d0) != 1024
	.error "fft64_radix8_in_place (src/measure_37.s) needs 128 float pairs at d_0806e0d0"
	.endif
@ d_0806e4d0: FFT output swap table, 104 pairs of u16 byte offsets (8 i, 8 j) of the 8-byte entries
@ that compute_spectrum_bytes (src/measure_32.s) exchanges after the transform, from
@ tools/make_tables.py fftswap() (permutation 64 (i & 1) + 8 ((i >> 1) & 7) + (i >> 4))
	.global d_0806e4d0
d_0806e4d0:
	.incbin "assets/tables/fftswap.bin"
	.if (. - d_0806e4d0) != 416
	.error "compute_spectrum_bytes (src/measure_32.s) reads 416 bytes of swap offsets"
	.endif
@ d_0806e670: sine table, 513 float32 sin(2 pi k / 512), k = 0..512, correctly rounded, from
@ tools/make_tables.py sine() (draw_arc_degrees, src/gfx_12.s; polar_degrees_to_xy_center_160_225,
@ src/gfx_14.s; the reader takes words k and k + 1 for k = 0..511)
	.global d_0806e670
d_0806e670:
	.incbin "assets/tables/sine.bin"
	.if (. - d_0806e670) != 2052
	.error "the sine readers (src/gfx_12.s, src/gfx_14.s) need 513 floats at d_0806e670"
	.endif
@ d_0806ee74: the standard JPEG zigzag order (ITU-T T.81): position in the 8x8 block of the k-th
@ coefficient of a scan (decode_scan_data_to_rgb565, src/image_18.s; parse_jpeg_header, src/image_20.s)
	.global d_0806ee74
d_0806ee74:
	.byte  0,  1,  8, 16,  9,  2,  3, 10
	.byte 17, 24, 32, 25, 18, 11,  4,  5
	.byte 12, 19, 26, 33, 40, 48, 41, 34
	.byte 27, 20, 13,  6,  7, 14, 21, 28
	.byte 35, 42, 49, 56, 57, 50, 43, 36
	.byte 29, 22, 15, 23, 30, 37, 44, 51
	.byte 58, 59, 52, 45, 38, 31, 39, 46
	.byte 53, 60, 61, 54, 47, 55, 62, 63
@ d_0806eeb4: JPEG IDCT scale factors, 64 u16 round(8192 s_i s_j), s_0 = 1, s_k = sqrt(2) cos(k pi/16)
@ (AAN), from tools/make_tables.py idct(); parse_jpeg_header (src/image_20.s) reads element
@ d_0806ee74[k] for k = 0..63 (V1.2.0 ldrh at 0x08039c24 with the index a byte of the zigzag table)
	.global d_0806eeb4
d_0806eeb4:
	.incbin "assets/tables/idct.bin"
	.if (. - d_0806eeb4) != 128
	.error "parse_jpeg_header (src/image_20.s) needs 64 halfwords at d_0806eeb4"
	.endif
@ d_0806ef34: clamp table, 1024 bytes: i for 0..255, 255 for 256..511, 0 for 512..1023, from
@ tools/make_tables.py clamp(); decode_scan_data_to_rgb565 (src/image_18.s) indexes it with
@ (value & 0x3ff)
	.global d_0806ef34
d_0806ef34:
	.incbin "assets/tables/clamp.bin"
	.if (. - d_0806ef34) != 1024
	.error "decode_scan_data_to_rgb565 (src/image_18.s) needs the 1024-byte clamp table"
	.endif
@ d_0806f334: 12 px font glyph data base (context word +0 at 0x20001098 in src/ram_init.s)
	.global d_0806f334
d_0806f334:
	.incbin "assets/rodata.bin", 0x290e0, 1700
@ d_0806f9d8: 12 px font record table, 8 bytes per glyph (context word +4 at 0x2000109C)
	.global d_0806f9d8
d_0806f9d8:
	.incbin "assets/rodata.bin", 0x29784, 768
@ d_0806fcd8: 12 px font range descriptor (context word +8 at 0x200010A0)
	.global d_0806fcd8
d_0806fcd8:
	.incbin "assets/rodata.bin", 0x29a84, 8
@ 0x0806fce0: word +8 of the 12 px font range descriptor (0x0806fcd8): pointer to its sorted u16 key array, written as a symbol so it follows the array
	.word d_0806fcec                                   @ 0x0806fce0 = 0x0806fcec
	.incbin "assets/rodata.bin", 0x29a90, 8
@ d_0806fcec: key array of the 12 px font (descriptor + 0x14)
	.global d_0806fcec
d_0806fcec:
	.incbin "assets/rodata.bin", 0x29a98, 194
@ d_0806fdae: 15 px font glyph data base (context word +0 at 0x200010C8 in src/ram_init.s)
	.global d_0806fdae
d_0806fdae:
	.incbin "assets/rodata.bin", 0x29b5a, 27530
@ d_08076938: 15 px font record table (context word +4 at 0x200010CC)
	.global d_08076938
d_08076938:
	.incbin "assets/rodata.bin", 0x306e4, 4568
@ d_08077b10: 15 px font range descriptor (context word +8 at 0x200010D0)
	.global d_08077b10
d_08077b10:
	.incbin "assets/rodata.bin", 0x318bc, 8
@ 0x08077b18: word +8 of the 15 px font range descriptor (0x08077b10): pointer to its key array
	.word d_08077b24                                   @ 0x08077b18 = 0x08077b24
	.incbin "assets/rodata.bin", 0x318c8, 8
@ d_08077b24: key array of the 15 px font (descriptor + 0x14)
	.global d_08077b24
d_08077b24:
	.incbin "assets/rodata.bin", 0x318d0, 1144
@ d_08077f9c: 16 px font glyph data base (context word +0 at 0x200010F8 in src/ram_init.s)
	.global d_08077f9c
d_08077f9c:
	.incbin "assets/rodata.bin", 0x31d48, 34900
@ d_080807f0: 16 px font record table (context word +4 at 0x200010FC); continues in UNREF_0808080a
	.global d_080807f0
d_080807f0:
	.incbin "assets/rodata.bin", 0x3a59c, 26
@ UNREF_0808080a: 107066 bytes; the first 92 8-byte records are (u16, u8, u8, u8, u8, u16) = (0x0080, 8, 9, 0, 3, 0x0044), (0x0070, 8, 13, 0, 1, 0x0078), (0x00a0, 10, 10, 0, 2, 0x00aa), (0x0090, 10, 11, 0, 2, 0x00e1), (0x0030, 4, 4, 0, 9, 0x00e9), (0x0050, 6, 12, 0, 1, 0x010d) ... with the last halfword non-decreasing 68, 120, 170, 225, 233, 269, ... 3110 | READ: the record table of the glyph descriptor at 0x200010f8 (words 0x08077f9c data base, 0x080807f0 record table, 0x080819a8 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x200010e4 with callback words 0x0802f809 and 0x0802f429) continues here: the callback 0x0802f428 loads the 8-byte records with ldr.w r0,[r0,r4,lsl #3] (word 0 holds a 12-bit field in bits 20..31 and the glyph offset in bits 0..19; bytes 4..7 = columns, rows, two signed offsets, copied to the caller by the fields callback 0x0802f808); the range table of that descriptor (0x080819a8..0x08081e2b), the glyph data, record tables (0x0808b214, 0x08098fdc) and range tables (0x0808c3cc, 0x0809a194) of the descriptors at 0x20001128 (words 0x08081e2c, 0x0808b214, 0x0808c3cc) and 0x20001158 (words 0x0808c850, 0x08098fdc, 0x0809a194) and the first glyph bitmaps of the descriptor at 0x20001188 (data base 0x0809a618) lie inside this region; blend_glyph_into_region_buffer (0x0800fb90) reads bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48 after the pointer callback (blx r2 at 0x0800fba4); 1182 record offsets give bitmap start addresses inside this region (first 0x08081e2c, last 0x0809aa3f); the words 0x08080878 at 0x08008e20 and 0x0808f04f at 0x08040188 are bytes inside instructions and not pointers
	.global UNREF_0808080a
UNREF_0808080a:
	.incbin "assets/rodata.bin", 0x3a5b6, 4510
@ d_080819a8: 16 px font range descriptor (context word +8 at 0x20001100 in src/ram_init.s)
	.global d_080819a8
d_080819a8:
	.incbin "assets/rodata.bin", 0x3b754, 8
@ 0x080819b0: word +8 of the 16 px font range descriptor (0x080819a8): pointer to its key array
	.word d_080819bc                                   @ 0x080819b0 = 0x080819bc
	.incbin "assets/rodata.bin", 0x3b760, 8
@ d_080819bc: key array of the 16 px font (descriptor + 0x14)
	.global d_080819bc
d_080819bc:
	.incbin "assets/rodata.bin", 0x3b768, 1136
@ d_08081e2c: 18 px font glyph data base (context word +0 at 0x20001128 in src/ram_init.s)
	.global d_08081e2c
d_08081e2c:
	.incbin "assets/rodata.bin", 0x3bbd8, 37864
@ d_0808b214: 18 px font record table (context word +4 at 0x2000112C)
	.global d_0808b214
d_0808b214:
	.incbin "assets/rodata.bin", 0x44fc0, 4536
@ d_0808c3cc: 18 px font range descriptor (context word +8 at 0x20001130)
	.global d_0808c3cc
d_0808c3cc:
	.incbin "assets/rodata.bin", 0x46178, 8
@ 0x0808c3d4: word +8 of the 18 px font range descriptor (0x0808c3cc): pointer to its key array
	.word d_0808c3e0                                   @ 0x0808c3d4 = 0x0808c3e0
	.incbin "assets/rodata.bin", 0x46184, 8
@ d_0808c3e0: key array of the 18 px font (descriptor + 0x14)
	.global d_0808c3e0
d_0808c3e0:
	.incbin "assets/rodata.bin", 0x4618c, 1136
@ d_0808c850: 20 px font glyph data base (context word +0 at 0x20001158 in src/ram_init.s)
	.global d_0808c850
d_0808c850:
	.incbin "assets/rodata.bin", 0x465fc, 51084
@ d_08098fdc: 20 px font record table (context word +4 at 0x2000115C)
	.global d_08098fdc
d_08098fdc:
	.incbin "assets/rodata.bin", 0x52d88, 4536
@ d_0809a194: 20 px font range descriptor (context word +8 at 0x20001160)
	.global d_0809a194
d_0809a194:
	.incbin "assets/rodata.bin", 0x53f40, 8
@ 0x0809a19c: word +8 of the 20 px font range descriptor (0x0809a194): pointer to its key array
	.word d_0809a1a8                                   @ 0x0809a19c = 0x0809a1a8
	.incbin "assets/rodata.bin", 0x53f4c, 8
@ d_0809a1a8: key array of the 20 px font (descriptor + 0x14)
	.global d_0809a1a8
d_0809a1a8:
	.incbin "assets/rodata.bin", 0x53f54, 1136
@ d_0809a618: 25 px font glyph data base (context word +0 at 0x20001188 in src/ram_init.s)
	.global d_0809a618
d_0809a618:
	.incbin "assets/rodata.bin", 0x543c4, 1080
@ UNREF_0809aa50: 44 bytes 1c 60 18 30 18 38 30 1f f0 0f c0 3f 00 3f c0 30 e0 30 60 30 60 30 60 30 e0 3f c0 3f 00 30 00 30 00 30 00 30 00 30 00 0f c0 1f f0 38 (even byte count) | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 2 record offsets give bitmap start addresses inside this region (first 0x0809aa5b, last 0x0809aa77)
	.global UNREF_0809aa50
UNREF_0809aa50:
	.incbin "assets/rodata.bin", 0x547fc, 56
@ UNREF_0809aa88: 540 bytes 1c 60 18 30 18 38 30 1f f0 0f e0 00 70 00 38 00 1e 3f 00 3f c0 30 e0 30 60 30 60 30 60 31 c0 3f c0 3f 80 31 80 30 c0 30 e0 30 60 30 30 1f 00 3f ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 24 record offsets give bitmap start addresses inside this region (first 0x0809aa99, last 0x0809aca2)
	.global UNREF_0809aa88
UNREF_0809aa88:
	.incbin "assets/rodata.bin", 0x54834, 576
@ UNREF_0809acc8: 20 bytes 00 60 00 61 c0 63 80 63 00 66 00 6e 00 7e 00 73 00 63 80 61 | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); no record offset starts inside this region; the record 75 (0x080a0468 + 8*75, word 0x00a006ab, width 16, height 14, 1 bit per pixel from the descriptor halfword at 0x2000119a) gives the start 0x0809acc3 and the next glyph starts at 0x0809acdf, so its 28 bytes 0x0809acc3..0x0809acde include this region
	.global UNREF_0809acc8
UNREF_0809acc8:
	.incbin "assets/rodata.bin", 0x54a74, 36
@ UNREF_0809acec: 24 bytes 60 6f 3c 7f fe 71 c6 61 86 61 86 61 86 61 86 61 86 61 86 61 86 6f 00 7f | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 2 record offsets give bitmap start addresses inside this region (first 0x0809aced, last 0x0809ad01)
	.global UNREF_0809acec
UNREF_0809acec:
	.incbin "assets/rodata.bin", 0x54a98, 40
@ UNREF_0809ad14: 264 bytes c0 1f 00 3f 80 70 c0 60 c0 60 c0 60 c0 60 c0 70 c0 3f 80 1f 00 6f 80 7f c0 70 c0 70 60 60 60 60 60 70 60 70 c0 7f c0 6f 80 60 00 60 00 60 00 60 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 13 record offsets give bitmap start addresses inside this region (first 0x0809ad15, last 0x0809ae0e)
	.global UNREF_0809ad14
UNREF_0809ad14:
	.incbin "assets/rodata.bin", 0x54ac0, 284
@ UNREF_0809ae30: 344 bytes f0 30 38 18 18 18 18 1e 0e 18 18 18 18 18 30 f0 e0 18 c0 3c c0 67 c0 63 80 08 80 1d c0 08 80 00 00 06 00 07 00 07 00 0d 80 0d 80 19 80 18 c0 18 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 15 record offsets give bitmap start addresses inside this region (first 0x0809ae30, last 0x0809af87)
	.global UNREF_0809ae30
UNREF_0809ae30:
	.incbin "assets/rodata.bin", 0x54bdc, 356
@ UNREF_0809af94: 12 bytes 60 1d 80 37 80 03 00 00 00 6f 00 7f | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 1 record offsets give bitmap start addresses inside this region (first 0x0809af95, last 0x0809af95)
	.global UNREF_0809af94
UNREF_0809af94:
	.incbin "assets/rodata.bin", 0x54d40, 28
@ UNREF_0809afb0: 92 bytes c0 03 00 06 00 06 00 00 00 1f 00 3f 80 70 c0 60 c0 60 c0 60 c0 60 c0 70 c0 3f 80 1f 00 1d 80 37 80 03 00 00 00 1f 00 3f 80 70 c0 60 c0 60 c0 60 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 4 record offsets give bitmap start addresses inside this region (first 0x0809afb1, last 0x0809b005)
	.global UNREF_0809afb0
UNREF_0809afb0:
	.incbin "assets/rodata.bin", 0x54d5c, 104
@ UNREF_0809b018: 372 bytes c0 60 c0 71 c0 3f c0 1e c0 0f c0 1f f0 38 30 30 18 60 18 60 1c 60 1c 60 1c 60 18 30 18 30 30 1c 70 7c fc 7c fc 06 00 07 00 07 00 0d 80 0d 80 19 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 13 record offsets give bitmap start addresses inside this region (first 0x0809b021, last 0x0809b185)
	.global UNREF_0809b018
UNREF_0809b018:
	.incbin "assets/rodata.bin", 0x54dc4, 384
@ UNREF_0809b198: 152 bytes 18 30 18 38 30 1f f0 0f c0 3f f8 3f f8 30 18 30 18 30 18 30 18 30 18 30 18 30 18 30 18 30 18 30 18 30 18 3f 00 3f c0 30 e0 30 60 30 60 30 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 5 record offsets give bitmap start addresses inside this region (first 0x0809b1a1, last 0x0809b211)
	.global UNREF_0809b198
UNREF_0809b198:
	.incbin "assets/rodata.bin", 0x54f44, 164
@ UNREF_0809b23c: 316 bytes 60 60 60 70 e0 3f e0 1f 60 00 60 00 60 00 60 00 60 00 60 0f e0 1f e0 30 60 70 60 70 60 30 60 38 60 1f e0 0f e0 1c 60 18 60 30 60 70 60 e0 60 1f ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 14 record offsets give bitmap start addresses inside this region (first 0x0809b24f, last 0x0809b369)
	.global UNREF_0809b23c
UNREF_0809b23c:
	.incbin "assets/rodata.bin", 0x54fe8, 328
@ UNREF_0809b384: 36 bytes c0 7f c0 7f c0 60 c0 60 c0 60 c0 60 c0 1f 00 3f 80 70 c0 60 c0 60 c0 60 c0 60 c0 70 c0 3f 80 1f 00 7f c0 7f | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 2 record offsets give bitmap start addresses inside this region (first 0x0809b391, last 0x0809b3a5)
	.global UNREF_0809b384
UNREF_0809b384:
	.incbin "assets/rodata.bin", 0x55130, 52
@ UNREF_0809b3b8: 152 bytes c0 6f 80 7f c0 70 c0 70 60 60 60 60 60 70 60 70 c0 7f c0 6f 80 60 00 60 00 60 00 60 00 1f 00 3f 80 71 00 60 00 60 00 60 00 60 00 71 00 3f 80 1f ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 6 record offsets give bitmap start addresses inside this region (first 0x0809b3b9, last 0x0809b43d)
	.global UNREF_0809b3b8
UNREF_0809b3b8:
	.incbin "assets/rodata.bin", 0x55164, 168
@ UNREF_0809b460: 84897 bytes (odd count), first bytes c0 7f e0 7f e0 00 20 00 20 00 20 61 80 61 80 61 80 61 80 61 80 7f 80 3f 80 01 80 01 80 01 80 61 8c 61 8c 61 8c ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (src/ram_init.s, copied to 0x20000000 at reset); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); glyph data of that descriptor and of the descriptor at 0x200011b8 (words 0x080a1ab8, 0x080b9000, 0x080ba1b8, font object 0x200011a4 with callback words 0x0802fa59 and 0x0802f5f9) continue through this region: 801 record offsets give bitmap start addresses inside it (first 0x0809b46b, last 0x080affe2); its record table 0x080a0468..0x080a162f and range table 0x080a1630.. are read by the same callback (ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 for the records, ldr r2,[r0,#0], ldrh r2,[r0,#4], ldr.w lr,[r0,#8] at 0x0802f58e..0x0802f5cc for the range table)
	.global UNREF_0809b460
UNREF_0809b460:
	.incbin "assets/rodata.bin", 0x5520c, 20488
@ d_080a0468: 25 px font record table (context word +4 at 0x2000118C in src/ram_init.s)
	.global d_080a0468
d_080a0468:
	.incbin "assets/rodata.bin", 0x5a214, 4552
@ d_080a1630: 25 px font range descriptor (context word +8 at 0x20001190)
	.global d_080a1630
d_080a1630:
	.incbin "assets/rodata.bin", 0x5b3dc, 8
@ 0x080a1638: word +8 of the 25 px font range descriptor (0x080a1630): pointer to its key array
	.word d_080a1644                                   @ 0x080a1638 = 0x080a1644
	.incbin "assets/rodata.bin", 0x5b3e8, 8
@ d_080a1644: key array of the 25 px font (descriptor + 0x14)
	.global d_080a1644
d_080a1644:
	.incbin "assets/rodata.bin", 0x5b3f0, 1140
@ d_080a1ab8: 28 px font glyph data base (context word +0 at 0x200011B8 in src/ram_init.s)
	.global d_080a1ab8
d_080a1ab8:
	.incbin "assets/rodata.bin", 0x5b864, 58697
@ DATA_080b0001: 36425 bytes from the odd address 0x080b0001, first bytes fe 80 00 0a fe 8e c3 0c fa 3e ec 30 00 00 5e e5 | the reference movt.eq r0,#0x80b at 0x0801dfee in draw_page_by_selector_nibble follows movweq r0,#0xc4f2 at 0x0801dfea, so the value built is 0x080bc4f2 (text '3:/System file/74.jpg'; the ne path builds 0x080bc5cf, '3:/System file/77.jpg'), then bl 0x08039f6c; the address 0x080b0001 comes from r0 = 1 and is not loaded by any instruction | draw_page_by_selector_nibble: draws one of seven option pages with radio-style rows
	.global DATA_080b0001
DATA_080b0001:
	.incbin "assets/rodata.bin", 0x69dad, 36435
@ UNREF_080b8e54: 9624 bytes, first bytes 08 aa aa aa aa aa aa aa cf e5 00 00 00 00 00 00 00 00 00 8e e5 00 00 00 00 00 00 00 00 00 8e e5 (the pattern 8e e5 followed by 9 zero bytes repeats at 11-byte distance at the start) | READ: glyph data of the descriptors at 0x200011b8 (words 0x080a1ab8 data base, 0x080b9000 record table, 0x080ba1b8 range table, font object 0x200011a4 with callback words 0x0802fa59 and 0x0802f5f9) and 0x200011e8 (words 0x080ba63c, 0x080bb2f0, 0x080bb3a8, font object 0x200011d4 with callback words 0x0802faed and 0x0802f66d): the pointer callbacks (0x0802f5f8 and 0x0802f66c) load the 8-byte records with ldr.w r0,[r0,r4,lsl #3] and return the data base plus the low 20 bits of the record word, blend_glyph_into_region_buffer (0x0800fb90) reads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; 27 record offsets give bitmap start addresses inside this region (first 0x080b8e8a, last 0x080bb249), and the record tables 0x080b9000..0x080ba1b7 and 0x080bb2f0..0x080bb3a7 lie inside it
	.global UNREF_080b8e54
UNREF_080b8e54:
	.incbin "assets/rodata.bin", 0x72c00, 428
@ d_080b9000: 28 px font record table (context word +4 at 0x200011BC in src/ram_init.s)
	.global d_080b9000
d_080b9000:
	.incbin "assets/rodata.bin", 0x72dac, 4536
@ d_080ba1b8: 28 px font range descriptor (context word +8 at 0x200011C0)
	.global d_080ba1b8
d_080ba1b8:
	.incbin "assets/rodata.bin", 0x73f64, 8
@ 0x080ba1c0: word +8 of the 28 px font range descriptor (0x080ba1b8): pointer to its key array
	.word d_080ba1cc                                   @ 0x080ba1c0 = 0x080ba1cc
	.incbin "assets/rodata.bin", 0x73f70, 8
@ d_080ba1cc: key array of the 28 px font (descriptor + 0x14)
	.global d_080ba1cc
d_080ba1cc:
	.incbin "assets/rodata.bin", 0x73f78, 1136
@ d_080ba63c: 63 px font glyph data base (context word +0 at 0x200011E8 in src/ram_init.s)
	.global d_080ba63c
d_080ba63c:
	.incbin "assets/rodata.bin", 0x743e8, 3252
@ d_080bb2f0: 63 px font record table (context word +4 at 0x200011EC)
	.global d_080bb2f0
d_080bb2f0:
	.incbin "assets/rodata.bin", 0x7509c, 184
@ d_080bb3a8: 63 px font range descriptor (context word +8 at 0x200011F0)
	.global d_080bb3a8
d_080bb3a8:
	.incbin "assets/rodata.bin", 0x75154, 8
@ 0x080bb3b0: word +8 of the 63 px font range descriptor (0x080bb3a8): pointer to its key array
	.word d_080bb3bc                                   @ 0x080bb3b0 = 0x080bb3bc
	.incbin "assets/rodata.bin", 0x75160, 8
@ d_080bb3bc: key array of the 63 px font (descriptor + 0x14)
	.global d_080bb3bc
d_080bb3bc:
	.incbin "assets/rodata.bin", 0x75168, 48
	.global d_080bb3ec
d_080bb3ec:
@ d_080bb3ec: 16 right-shift counts indexed by bits 7..4 of the word at 0x40021004, read by
@ compute_clock_frequencies and init_system_clock (src/system_62.s): 0 for 0..7, then 1, 2, 3, 4,
@ 6, 7, 8, 9. d_080bb404: 8 right-shift counts indexed by bits 10..8 and 13..11 of that word.
	.byte 0
@ UNREF_080bb3ed: 15 bytes 00 00 00 00 00 00 00 01 02 03 04 06 07 08 09 = bytes 1..15 of the 16-byte table at 0x080bb3ec (00 00 00 00 00 00 00 00 01 02 03 04 06 07 08 09) | ldrb r3,[r4,r3] at 0x080314c8 with r4 = 0x080bb3ec (movw #0xb3ec at 0x080314bc, movt at 0x080314c4) and r3 = (x>>4)&0xf (ubfx at 0x080314c0) in compute_clock_frequencies, the byte is the shift count of lsrs r2,r3 at 0x080314ce (x = word read from 0x40021004)
	.global UNREF_080bb3ed
UNREF_080bb3ed:
	.byte 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 6, 7, 8, 9
	.global d_080bb3fc
d_080bb3fc:
@ d_080bb3fc: 8 bytes read by fn_0800b1f8 (src/ui_keys_64.s:1002) and fn_0800b7cc
@ (src/ui_keys_65.s:135) with an index 0..7; what the values stand for is UNPROVEN
	.byte 0x14
@ UNREF_080bb3fd: 6 bytes 0c 17 0b 0a 12 11 | READ: ldrb r0,[r2,r0] at 0x0800b2f8 with r2 = 0x080bb3fc (movw at 0x0800b2e6, movt at 0x0800b2f4) and r0 = uxtb r1 at 0x0800b2f2 where r1 = [0x2d] - 1 or 7 (subs at 0x0800b2ea, moveq at 0x0800b2f0) and, in the second function, ldrb r0,[r2,r0] at 0x0800b8d0 with r2 = 0x080bb3fc (movw 0x0800b8c0, movt 0x0800b8cc) and r1 = r0 + 1 when r0 < 7 else 0 (cmp r0,#7 / addcc at 0x0800b8c4 / 0x0800b8c8), so the index is 0..7 at 0x0800b8d0 and this region is index 1..6
	.global UNREF_080bb3fd
UNREF_080bb3fd:
	.byte 0x0c, 0x17, 0x0b, 0x0a, 0x12, 0x11, 0x10
@ DATA_080bb404: 8 bytes 00 00 00 00 01 02 03 04 | ldrb r3,[r4,r3] at 0x080314dc with r3 = (x>>8)&7 (ubfx at 0x080314d8) and at 0x080314ea with r3 = (x>>11)&7 (ubfx at 0x080314e6), r4 = 0x080bb404 (movw #0xb404 at 0x080314ca, movt at 0x080314d4); the byte is the shift count of lsr.w r3,r2,r3 at 0x080314de and lsrs r2,r3 at 0x080314ee | compute_clock_frequencies: reads 0x40021004 and derives a base frequency and four shifted/divided values into a 5-dword result
	.global DATA_080bb404
DATA_080bb404:
	.global d_080bb404
d_080bb404:
	.byte 0, 0, 0, 0, 1, 2, 3, 4
@ DATA_080bb40c: 2 bytes a0 fe = halfword 0xfea0, element 0 of the halfword array 0x080bb40c: 0xfea0, 0x055f, 0x055f, 0xfea0 (the next halfwords are DATA_080bb40e) | ldrh.w with index*4 (lsl #0x2) at 0x08028b6c, 0x0801e7c4, 0x08014984, 0x08014554, 0x08014a34, 0x08014a08 | draw_channel_offset_markers_08028b40: calls fill_triangle (0x08020af8) at 0x08028b80 and 0x08028baa; the colour argument (stack slot [sp+8], str r7,[sp,#8] at 0x08028b7e / 0x08028ba8) is the halfword at 0x080bb40c + byte(0x2000105b)*4 for the first call and at +2 for the second; draw_bottom_strip and draw_panels_by_selector_20001062 also load from it
	.global DATA_080bb40c
DATA_080bb40c:
	.global d_080bb40c
d_080bb40c:
	.hword 0xfea0                                      @ element 0; the readers index by byte * 4 and read +0 and +2
@ DATA_080bb40e: 6 bytes 5f 05 5f 05 a0 fe = halfwords 0x055f, 0x055f, 0xfea0 (elements 1..3 of the halfword array at 0x080bb40c) | ldrh r7,[r3,#0x2] at 0x08028b98, ldrh r1,[r1,#0x2] at 0x0801e7fc, ldrh r7,[r0,#0x2] at 0x0801458e and 0x080145bc, 0x080145ea, 0x08014646 | draw_channel_offset_markers_08028b40, draw_bottom_strip, draw_panels_by_selector_20001062
	.global DATA_080bb40e
DATA_080bb40e:
	.hword 0x055f, 0x055f, 0xfea0                      @ elements 1..3 (read as RGB565: 0xfea0 yellow-orange, 0x055f blue)
	.byte 0x20, 0x00                                   @ the bytes of the V1.2.0 text " " (now t_080bb414 in src/text.s)
@ (the last 2 of these 8 bytes, 20 00 at 0x080bb414, were the text " " of draw_arc_gauge,
@ now t_080bb414 in src/text.s; the bytes are kept here unchanged)
@ (V1.2.0 had its text area, every language, at 0x080bb416..0x080be05b here; the English texts
@ are in src/text.s now.) d_080be05c and the data after it are read as halfwords and words: the
@ next line pads with zero bytes to a multiple of 4 from the section start (the section is
@ 4-aligned, see the .p2align at its start), as the vendor address 0x080be05c was.
	.p2align 2
@ d_080be05c / d_080be118: FatFs data (ChaN, FatFs R0.15 ffunicode.c, ff_wtoupper tables cvt2 for
@ code points U+1000..U+FFFF and cvt1 for U+0000..U+0FFF, licence assets/tables/LICENSE-FatFs.txt),
@ u16 groups {start, type << 8 | count, type 0: count halfwords}, each table ending with start 0.
@ The code of src/filesystem_03.s (find_directory_entry_by_name and its neighbours) walks them; it
@ takes d_080be05c for a key >= 0x1000 and d_080be118 otherwise.
	.global d_080be05c
d_080be05c:
	.incbin "assets/tables/fat_cvt2.bin"
	.global d_080be118
d_080be118:
	.incbin "assets/tables/fat_cvt1.bin"
@ d_080be30a: 4 halfwords read by draw_three_value_rows (src/ui_pages_76.s:367, ldrh at 0x08015a62 of
@ V1.2.0) as [d_080be30a + 2*i], i = 0, 1 or 3: 0x8c73, 0xffff, 0x055f, 0x0000 (read as RGB565:
@ grey, white, blue, black; element 2 is not read there)
	.global d_080be30a
d_080be30a:
	.hword 0x8c73, 0xffff, 0x055f, 0x0000
	.hword 0x0000                                      @ padding to the word-aligned region table
@ d_080be314: scatter-load region table, 2 entries {source, destination, length, handler}, read by
@ scatter_load_regions (src/startup_56.s) from d_080be314 up to d_080be334 (distance words at .L080071b8)
	.global d_080be314
d_080be314:
	.word ram_init                                     @ region 1 source: the initial RAM image, src/ram_init.s (V1.2.0: 0x080be480, a packed stream)
	.word 0x20000000                                   @ region 1 destination
	.word 0x00001240                                   @ region 1 length in bytes (src/ram_init.s checks its own size against it)
.Lsw_080be320:
	.word copy_words_addr                              @ region 1 handler: plain word copy, even entry label (V1.2.0: 0x080071c0, unpack_token_stream)
@ UNREF_080be324: 12 bytes = 3 words: region 2 source, destination 0x20001240, length 0x00035d50; its handler word zero_fill_words_addr follows | ldm.w r10!,{r0,r1,r2,r3} in scatter_load_regions loads them, and zero_fill_words does not read r0 (the source)
	.global UNREF_080be324
UNREF_080be324:
	.word rodata_end                                   @ region 2 source = the end of this file's data (V1.2.0: 0x080be680); zero_fill_words does not read it
	.word 0x20001240                                   @ region 2 destination (zero-filled RAM after the initial image)
	.word 0x00035d50                                   @ region 2 length in bytes
.Lsw_080be330:
	.word zero_fill_words_addr                         @ 0x080be330 = 0x0800721c
@ d_080be334: end of the scatter-load region table (the word here, 0x0000001c, is not part of it)
	.global d_080be334
d_080be334:
	.word 0x0000001c                                   @ value 0x1c (V1.2.0 word, no reader found)
@ C runtime library locale data ("C" locale), V1.2.0 values. fn_08044ed8 (src/runtime_lib_41.s)
@ compares its argument with the name d_080be338 and returns d_080be340; fn_08044f04 compares with
@ d_080be354 and returns d_080be35c. The word -8 before each block equals the distance from the
@ block back to its name; no reader of it was found.
	.global d_080be338
d_080be338:
	.asciz "C"
	.byte 0x00, 0x00                                   @ padding
	.word 0xfffffff8                                   @ -8
@ d_080be340: 5 words 0x0c, 0x0e, 0x0f, 0x2e, 0x110 (how the library reads them was not traced: UNPROVEN)
	.global d_080be340
d_080be340:
	.word 0x0000000c, 0x0000000e, 0x0000000f, 0x0000002e, 0x00000110
	.global d_080be354
d_080be354:
	.asciz "C"
	.byte 0x00, 0x00                                   @ padding
	.word 0xfffffff8                                   @ -8
@ d_080be35c: character class table: byte [d_080be35c] is the entry of EOF (-1), d_080be35c + 1 + c
@ the entry of the character c = 0..255 (fn_08008534 reads [base + c] for c <= 255 and the byte at
@ base + 257, base = d_080be35c + 1 stored at 0x20001264 by fn_080072c8). Flag values seen:
@ 0x40 control, 0x01 with control for 9..13, 0x05 for space, 0x02 punctuation, 0x20 digits,
@ 0x10 upper case, 0x08 lower case, 0x80 with the letters a..f / A..F.
	.global d_080be35c
d_080be35c:
	.byte 0x00                                         @ EOF
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 @ 0x00..0x08
	.byte 0x41, 0x41, 0x41, 0x41, 0x41                 @ 0x09..0x0d tab, line feed, vertical tab, form feed, return
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 @ 0x0e..0x16
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 @ 0x17..0x1f
	.byte 0x05                                         @ 0x20 space
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02 @ 0x21..0x28 ! " # $ % & ' (
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02     @ 0x29..0x2f ) * + , - . /
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20 @ 0x30..0x39 digits
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02     @ 0x3a..0x40 : ; < = > ? @
	.byte 0x90, 0x90, 0x90, 0x90, 0x90, 0x90           @ 0x41..0x46 A..F
	.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10 @ 0x47..0x50 G..P
	.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10 @ 0x51..0x5a Q..Z
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02           @ 0x5b..0x60 [ \ ] ^ _ `
	.byte 0x88, 0x88, 0x88, 0x88, 0x88, 0x88           @ 0x61..0x66 a..f
	.byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08 @ 0x67..0x70 g..p
	.byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08 @ 0x71..0x7a q..z
	.byte 0x02, 0x02, 0x02, 0x02                       @ 0x7b..0x7e { | } ~
	.byte 0x40                                         @ 0x7f delete
	.space 128, 0x00                                   @ 0x80..0xff: no class
	.space 35, 0x00                                    @ zero bytes to the end of the block (base + 257 is one of them)
	.if (. - d_080be35c) != 292
	.error "the character class block keeps its 292 bytes (fn_08008534 reads base + 257 and the word at base + 263)"
	.endif
@ The 512 bytes 0x080be480..0x080be67f of V1.2.0 (the packed initial RAM image, unpacked by
@ unpack_token_stream) are not part of this file: the image is src/ram_init.s, copied by copy_words.
	.global rodata_end
rodata_end:
