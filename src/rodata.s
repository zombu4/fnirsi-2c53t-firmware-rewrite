@ rodata.s - fixed data (V1.2.0 0x08046254..0x080BE67F): format tables, number constants, function
@ pointer tables, the text pointer tables, fonts and glyph bitmaps, pictures and the scatter-load region
@ table (0x080BE314). The initial RAM image it names is src/ram_init.s (typed source, copied at reset).
@ The fonts (assets/fonts/) and pictures (assets/pictures/) are own data with typed descriptors and
@ animation records. Number tables, runtime library constants and small tables are typed here with
@ their values; computed tables come from assets/tables/ (tools/make_tables.py of the project folder),
@ the FatFs code page and case tables from assets/tables/fat_*.bin (FatFs R0.15, LICENSE-FatFs.txt),
@ the FPGA stream and the filter bank are the vendor's data kept for now (assets/vendor_kept/). Words
@ that hold code addresses are written as symbols, and so are the data addresses (font key array
@ pointers, scatter-load table). The text pointer tables
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
	.word return_void_2                                @ display code 0x2c: nothing (V1.2.0: fn_0801215c, the language page; no code sends 0x2c any more)
@ ----------------------------------------------------------------------------
@ Text pointer tables, English only: one word per item (the address of a string of
@ src/text.s, or 0). V1.2.0 held one string per language in each row / block and the code
@ picked the slot by the language byte 0x20001058; the code now indexes these tables by item
@ only, and texts that had a whole language row to themselves (status messages, page titles)
@ are named directly by the code, so those rows are gone.
@ ----------------------------------------------------------------------------
@ d_0804bf28: measurement labels, word i = label of measurement i (draw_waveform_display_p6.inc)
	.global d_0804bf28
d_0804bf28:
	.word t_080bbaa0, t_080bba4c, t_080bb9f8, t_080bba05   @ Freq: Peri: Duty+: Duty-:
	.word t_080bb9f2, t_080bb9ff, t_080bbab7, t_080bba6b   @ Wid+: Wid-: Vmax: Vmin:
	.word t_080bba95, t_080bba9b, t_080bbaa6, t_080bba47   @ Vp-p: Amp: Vrms: Avg:
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
@ (V1.2.0's status message rows 0x0804bfd0..0x0804c0cf are gone: draw_waveform_display
@ names its English pop-up texts directly)
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
	.word return_void_2                                @ 0x0804c17c: unused entry (V1.2.0: draw_language_list, removed)
@ DATA_0804c180: 2 bytes 73 8c = halfword 0x8c73, element 0 of the halfword array 0x0804c180: 0x8c73, 0xffff, 0x055f, 0x0000 | ldrh.w r5,[r1,r6,lsl #0x1] at 0x080134f6 with r1 = 0x0804c180 (movw/movt at 0x080134ec/0x080134f0) | draw_panels_by_selector_20001062: menu-panel drawing routine
	.global DATA_0804c180
DATA_0804c180:
	.global d_0804c180
d_0804c180:
	.hword 0x8c73, 0xffff, 0x055f                      @ read as RGB565: grey, white, blue (0x055f is also the colour argument of the message box calls); colour use of this table not traced
	.hword 0x0000                                      @ element 3, no reference found
@ (V1.2.0's status message rows 0x0804c188..0x0804c207 are gone: the page routines name
@ their English texts directly)
@ d_0804c208: Startup on Boot choices, word i = text of choice i ([0x2000105c] = 0..3), read by
@ draw_page_by_selector_nibble (case 1). V1.2.0: four addresses of 8-word language rows.
	.global d_0804c208
d_0804c208:
	.word t_080bc220, t_080bcb54, t_080bc225, t_080bcbab   @ None, Multimeter, Oscilloscope, Signal Generator
@ d_0804c218: About page labels (draw_page_by_selector_nibble case 4). V1.2.0: 8 language
@ blocks of 2 words.
	.global d_0804c218
d_0804c218:
	.word t_080bba71, t_080bba52                           @ "Version:", " Model:"
@ d_0804c258: system settings menu, word n = name of item n (draw_six_row_list). Items:
@ 0 Sound and light, 1 Startup on Boot, 2 Auto Shutdown, 3 USB Sharing, 4 About, 5 Factory
@ Reset. V1.2.0: 8 language blocks of 7 words with the item Language in front (removed).
	.global d_0804c258
d_0804c258:
	.word t_080bcdd0, t_080bce6b, t_080bc8de               @ Sound and light, Startup on Boot, Auto Shutdown
	.word t_080bc35e, t_080bce87, t_080bcdab               @ USB Sharing, About, Factory Reset
@ (V1.2.0's page title rows 0x0804c338..0x0804c3d7 are gone: the titles are named directly)
@ d_0804c3d8: value panel labels, word c = label of column c (draw_value_panel). V1.2.0: a
@ Chinese set of 3, then the English set, chosen by the language byte.
	.global d_0804c3d8
d_0804c3d8:
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
@ d_0804c43c: multimeter function names, word f = name of function f (byte 0x20001026), read by
@ fn_08010a94 and draw_header_image_120. V1.2.0: 8 language blocks of 12 words.
	.global d_0804c43c
d_0804c43c:
	.word t_080bc02e, t_080bc15d, t_080bc152, t_080bced6   @ Automatic, DC Voltage, AC Voltage, Continuity
	.word t_080bc111, t_080bc0d6, t_080bc0ca, t_080bc238   @ Diode, Resistance, Capacitance, Temperature
	.word t_080bce4b, t_080bce29, t_080bce3a, t_080bce18   @ Small DC / AC current, Large DC / AC current
@ d_0804c5bc: signal generator value names, word i = label of row i (draw_three_value_rows).
@ V1.2.0: 8 language blocks of 3 words.
	.global d_0804c5bc
d_0804c5bc:
	.word t_080bcecc, t_080bc179, t_080bc117               @ Frequency, Duty Cycle, Amplitude
@ d_0804c61c: waveform names, word w = name of waveform w (draw_six_row_list_from_first_index).
@ V1.2.0: 8 language blocks of 13 words.
	.global d_0804c61c
d_0804c61c:
	.word t_080bc2ab, t_080bc2b5, t_080bc2dd, t_080bc2eb   @ Sine, Square, Ramp, Half Wave
	.word t_080bc2c1, t_080bc2d3, t_080bc2cb, t_080bcac9   @ Full Wave, Step Up, Step Down, Exp Rise
	.word t_080bc244, t_080bce5c, t_080bc9b5, t_080bc253   @ Exp Fall, DC, Harmonics, Sinc Pulse
	.word t_080bccc0                                       @ Lorentz
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
@ d_0804c7cc: trigger panel labels, words 0..2 (draw_panels_by_selector_20001062 case 5).
@ V1.2.0: a Chinese set of 3, then the English set, chosen by the language byte.
	.global d_0804c7cc
d_0804c7cc:
	.word t_080bba31, t_080bba37, t_080bba5a               @ Mode: Edge: Channel:
@ d_0804c7e4: trigger modes, word m = name of mode m (byte 0x2000010f), read by
@ draw_panels_by_selector_20001062 and draw_bottom_strip. V1.2.0: a Chinese set of 3, then
@ the English set, chosen by the language byte.
	.global d_0804c7e4
d_0804c7e4:
	.word t_080bc707, t_080bca92, t_080bc184               @ Normal Auto Single
@ DATA_0804c7fc: channel names; ldr.w r5,[r1,r0,lsl #0x2] at 0x0801ebde and
@ ldr.w r0,[r0,r1,lsl #0x2] at 0x0801eda4 in draw_bottom_strip, and in
@ draw_panels_by_selector_20001062
	.global DATA_0804c7fc
DATA_0804c7fc:
	.global d_0804c7fc
d_0804c7fc:
	.word t_080bb975, t_080bb9e0                           @ CH1 CH2
@ d_0804c804: oscilloscope settings items, word k = name of item k (fn_08012de0). Items:
@ Display, Cursors, Measure, Channel 1, Channel 2, Trigger, Persistence, Math (V1.2.0: Display Mode,
@ Cursor Measurement, ..., Mathematics; 8 language blocks of 8 words).
	.global d_0804c804
d_0804c804:
	.word t_080bc104, t_080bce05, t_080bcdef, t_080bccce   @ Display, Cursors, Measure, Channel 1
	.word t_080bccdb, t_080bcd0e, t_080bc0e1, t_080bcc33   @ Channel 2, Trigger, Persistence, Math
@ (V1.2.0's title row 0x0804c904, "Oscilloscope Settings", is gone: the code names the text)
@ d_0804c924: help box texts, word i = text for [0x20001061] = i (0..3), read by fn_08010014
@ and fn_08012d2c. V1.2.0: four addresses of 8-word language rows.
	.global d_0804c924
d_0804c924:
	.word t_080bcb54, t_080bc225, t_080bcbab, t_080bcd16   @ Multimeter, Oscilloscope, Signal Generator, Settings
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

@ ============================================================================
@ Boot animation and pictures (own data, DATA_DESIGN.md step 5). The bitmaps come from
@ tools/make_pictures.py of the project folder; sizes and formats are the ones the drawing code
@ reads. 4 bpp pictures: high nibble first, pixels one after the other, after each row an odd
@ running nibble index is rounded up to even (system_bring_up .L0802b84a `bicne r4,r0,#1`, the wipe
@ loop's byte index row * ((w & 1) + (w >> 1)) + column / 2, draw_4bpp_bitmap); a nibble is a
@ palette index in system_bring_up and a coverage value in draw_4bpp_bitmap.
@ ============================================================================

@ d_0804c9fc: boot animation records, 5 records of 4 halfwords (x, y, width, height), read by
@ system_bring_up (src/system_58.s `ldrh.w r5,[r6,r2,lsl #3]` and `ldrh [rec,#2/#4/#6]`,
@ src/parts/system_bring_up_p2.inc). Width and height of records 1..4 are the sizes of the logo and
@ the 3 sprites below; x / y of record 1 are the logo's top left corner (the logo loop also uses the
@ immediates 0x37 / 0x67); records 2..4 give where the sprites land at the end of their fall. No
@ instruction reads record 0 (the loops index records 1..4). Values of V1.2.0.
	.global d_0804c9fc
d_0804c9fc:
	.hword	0x0140, 0x00f0, 0x00d2, 0x0000	@ record 0: 320, 240, 210, 0 (not read)
	.hword	0x0037, 0x0067, 0x00c2, 0x0023	@ record 1: logo at x 55, y 103, 194 x 35
	.hword	0x00f0, 0x0066, 0x000a, 0x000a	@ record 2: sprite 0 to x 240, y 102, 10 x 10
	.hword	0x00fa, 0x0067, 0x000a, 0x0008	@ record 3: sprite 1 to x 250, y 103, 10 x 8
	.hword	0x0104, 0x0068, 0x0005, 0x0006	@ record 4: sprite 2 to x 260, y 104, 5 x 6
@ d_0804ca24: boot logo (own picture), 194 x 35 4 bpp, 3395 bytes: "F***NIRS" and a dotless i
@ whose dot is sprite 0 (it lands at x 240..249, y 102..111, over logo columns 185..193, rows 0..8,
@ which stay 0). Drawn by
@ system_bring_up when 2:/LOGO/LOGO2C53T.jpg is missing: nibble = index into the fade palette.
	.global d_0804ca24
d_0804ca24:
	.incbin "assets/pictures/logo.bin"
.Llogo_end:
	.if (.Llogo_end - d_0804ca24) != 194 * 35 / 2
	.error "boot logo: record 1 gives 194 x 35 pixels at 4 bpp, 3395 bytes"
	.endif
@ The 3 sprites of the boot animation (own pictures, assets/pictures/sprites.bin, 108 bytes): round
@ dots, 4 bpp palette indices, nibble 0 is drawn black. Each has its own label (system_bring_up
@ loads all three).
@ d_0804d767: sprite 0, 10 x 10 (record 2), 50 bytes
	.global d_0804d767
d_0804d767:
	.incbin "assets/pictures/sprites.bin", 0, 50
@ d_0804d799: sprite 1, 10 x 8 (record 3), 40 bytes
	.global d_0804d799
d_0804d799:
	.incbin "assets/pictures/sprites.bin", 50, 40
@ d_0804d7c1: sprite 2, 5 x 6 (record 4), rows of 3 bytes (odd width), 18 bytes
	.global d_0804d7c1
d_0804d7c1:
	.incbin "assets/pictures/sprites.bin", 90, 18
.Lsprites_end:
	.if (d_0804d799 - d_0804d767) != 50 || (d_0804d7c1 - d_0804d799) != 40 || (.Lsprites_end - d_0804d7c1) != 18
	.error "sprites: 10 x 10, 10 x 8 and 5 x 6 at 4 bpp are 50, 40 and 18 bytes"
	.endif
@ d_0804d7d3: the 3 trigger-edge icons (own pictures, assets/pictures/icons.bin): 16 x 16, 1 bpp,
@ 2 bytes per row, most significant bit = left pixel, 32 bytes each: rising, falling, both edges.
@ Icon i is at d_0804d7d3 + 32 * i (`add.w r5,r2,r1,lsl #5`), drawn by
@ draw_panels_by_selector_20001062 (src/ui_pages_73.s) and draw_bottom_strip (src/ui_pages_79.s).
	.global d_0804d7d3
d_0804d7d3:
	.incbin "assets/pictures/icons.bin"
.Licons_end:
	.if (.Licons_end - d_0804d7d3) != 3 * 32
	.error "trigger icons: 3 icons of 32 bytes"
	.endif
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
@ T3 exponential rise "Exp Rise" (7), T4 1 - exponential "Exp Fall" (8), T5 sum of
@ harmonics 1..5 "Harmonics" (10), T6 sin(x)/x "Sinc Pulse" (11), T7 1/(1+x^2) "Lorentz" (12).
	.incbin "assets/tables/waves.bin"
@ d_0804de88: lower value panel frame (own picture, tools/make_pictures.py): 300 x 52 4 bpp coverage
@ mask, rows packed without padding (300 is even), 7800 bytes, a frame with rounded corners and
@ dividers at x 100 and 199. Drawn by draw_value_panel (src/ui_pages_76.s) as
@ draw_4bpp_bitmap(10, 0xb8, 300, 0x34, d_0804de88, 0xffff).
	.global d_0804de88
d_0804de88:
	.if (d_0804de88 - d_0804d848) != 1600
	.error "fill_output_waveform_table (src/siggen_55.s) needs the 8 waveform tables as one 1600-byte block at d_0804d848"
	.endif
	.incbin "assets/pictures/panel.bin"
.Lpanel_end:
	.if (.Lpanel_end - d_0804de88) != 7800
	.error "value panel: draw_value_panel draws 300 x 52 pixels at 4 bpp, 7800 bytes"
	.endif
@ d_0804fd00: message box frame (own picture, tools/make_pictures.py): 198 x 83 4 bpp coverage mask,
@ rows packed without padding (198 is even), 8217 bytes, a frame with rounded corners. Drawn by
@ draw_4bpp_bitmap(0x3d, 0x50, 0xc6, 0x53, d_0804fd00, 0x055f) from fn_08011e84 (src/ui_pages_71.s),
@ draw_bitmap_and_text (src/ui_pages_79.s) and draw_waveform_display
@ (src/parts/draw_waveform_display_p7.inc).
	.global d_0804fd00
d_0804fd00:
	.incbin "assets/pictures/msgbox.bin"
.Lmsgbox_end:
	.if (.Lmsgbox_end - d_0804fd00) != 8217
	.error "message box: the callers draw 198 x 83 pixels at 4 bpp, 8217 bytes"
	.endif
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

@ ============================================================================
@ The 8 fonts (own data, DATA_DESIGN.md step 4). The binary pieces come from tools/make_fonts.py of
@ the project folder: the 7 text fonts are DejaVu Sans Condensed 2.37 (licence
@ assets/fonts/LICENSE-DejaVu.txt) rendered at 4 bits per pixel, 100 glyphs each (0x20..0x7F,
@ U+03A9 Omega, U+2103 degree Celsius, U+2109 degree Fahrenheit, U+221E infinity); the 63 px font is an own 7-segment
@ drawing at 1 bit per pixel with the 24 keys 0x20 - . 0-9 A C E L O P S T U r s.
@ Each font is described by its context in the initial RAM image (src/ram_init.s): +0 data base,
@ +4 record table, +8 range descriptor, +0x12 bits per pixel. The labels keep the names of the
@ V1.2.0 addresses (d_<address>) that src/ram_init.s and tests/test_ram_init.py name.
@ Per font, in this order:
@ - fNN_bits.bin: the glyph bitmaps. Row-major, top row first, bpp bits per pixel, most significant
@   bits first, every row ends on a byte boundary (blend_glyph_into_region_buffer, src/gfx_12.s:
@   .L0800fc34 steps bpp bits and takes a new byte after 8, .L0800fc1c moves to the next byte at a
@   row end when bits of the byte were used, so odd column counts are allowed). Padded with 0 to a
@   multiple of 4 bytes, so the record table after it stays word aligned.
@ - fNN_recs.bin: one 8-byte record per glyph, in key order (record i belongs to key i of the key
@   array). Word 0: bits 31..20 advance in pixels (lookup_sorted_table_fields_*: `lsrs r2,r2,#0x14`),
@   bits 19..0 offset of the bitmap from the data base (lookup_sorted_table_ptr_*: `bfc r0,#0x14,#0xc`,
@   `add r0,r1`); byte 4 columns, byte 5 rows, signed byte 6 x offset, signed byte 7 baseline offset.
@   The renderer starts the columns at x + x offset / 2 + (x offset & 1), so the x offset is 0 in
@   every record and the left bearing is part of the bitmap; the rows start at
@   y + line height (font object +8) - baseline offset - rows, so the baseline offset is the number
@   of cell rows below the bitmap (0..line height). Glyphs without pixels (0x20, 0x7F) have 0 rows.
@ - range descriptor, 20 bytes, typed below in V1.2.0's layout. lookup_sorted_table_ptr_* and
@   lookup_sorted_table_fields_* (src/filesystem_02.s) read +0 (word, low bound), +4 (halfword, high
@   bound; a key outside [low, high] is not found), +8 (word, address of the key array) and +0x10
@   (halfword, glyph count); +6, +0xC and +0x12 are not read by them and keep V1.2.0's values
@   (0, 0, 3, the same in all 8 V1.2.0 descriptors).
@ - fNN_keys.bin: the glyph keys (Unicode code points) as ascending u16 values, read by the binary
@   search with `ldrh.w r5,[lr,r5]` at byte offset (lo + hi) & ~1; padded with 0 to a multiple of 4.
@ Every piece is word aligned: the .p2align before each font emits nothing (all sizes are multiples
@ of 4) and the guards check the sizes against the counts typed in the descriptor.
@ ============================================================================

@ ----------------------------------------------------------------------------
@ 12 px font (font object 0x20001084, context 0x20001098): DejaVu Sans Condensed size 9, 4 bpp,
@ 100 glyphs. Font object loaded directly by draw_arc_gauge (src/waveform_84.s).
@ ----------------------------------------------------------------------------
	.p2align 2
@ d_0806f334: data base of the 12 px font (context word +0, 0x20001098)
	.global d_0806f334
d_0806f334:
	.incbin "assets/fonts/f12_bits.bin"
@ d_0806f9d8: record table of the 12 px font (context word +4, 0x2000109C)
	.global d_0806f9d8
d_0806f9d8:
	.incbin "assets/fonts/f12_recs.bin"
@ d_0806fcd8: range descriptor of the 12 px font (context word +8, 0x200010A0)
	.global d_0806fcd8
d_0806fcd8:
	.word	0x00000020		@ +0x00: low bound, key 0x20 (space)
	.hword	0x221e			@ +0x04: high bound, the highest key U+221E (infinity)
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_0806fcec		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	100			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_0806fcec: key array of the 12 px font (descriptor + 0x14)
	.global d_0806fcec
d_0806fcec:
	.incbin "assets/fonts/f12_keys.bin"
.Lfont12_end:
	.if (d_0806f9d8 - d_0806f334) & 3
	.error "12 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_0806fcd8 - d_0806f9d8) != 8 * 100
	.error "12 px font: the record table must hold 100 records (descriptor glyph count)"
	.endif
	.if (.Lfont12_end - d_0806fcec) != ((2 * 100 + 3) & ~3)
	.error "12 px font: the key array must hold 100 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 15 px font (font object 0x200010B4, context 0x200010C8): DejaVu Sans Condensed size 10, 4 bpp,
@ 100 glyphs. Font object loaded directly by the waveform display (src/parts/draw_waveform_display_p6.inc).
@ ----------------------------------------------------------------------------
	.p2align 2
@ d_0806fdae: data base of the 15 px font (context word +0, 0x200010C8)
	.global d_0806fdae
d_0806fdae:
	.incbin "assets/fonts/f15_bits.bin"
@ d_08076938: record table of the 15 px font (context word +4, 0x200010CC)
	.global d_08076938
d_08076938:
	.incbin "assets/fonts/f15_recs.bin"
@ d_08077b10: range descriptor of the 15 px font (context word +8, 0x200010D0)
	.global d_08077b10
d_08077b10:
	.word	0x00000020		@ +0x00: low bound, key 0x20 (space)
	.hword	0x221e			@ +0x04: high bound, the highest key U+221E (infinity)
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_08077b24		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	100			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_08077b24: key array of the 15 px font (descriptor + 0x14)
	.global d_08077b24
d_08077b24:
	.incbin "assets/fonts/f15_keys.bin"
.Lfont15_end:
	.if (d_08076938 - d_0806fdae) & 3
	.error "15 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_08077b10 - d_08076938) != 8 * 100
	.error "15 px font: the record table must hold 100 records (descriptor glyph count)"
	.endif
	.if (.Lfont15_end - d_08077b24) != ((2 * 100 + 3) & ~3)
	.error "15 px font: the key array must hold 100 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 16 px font (font object 0x200010E4, context 0x200010F8): DejaVu Sans Condensed size 12, 4 bpp,
@ 100 glyphs. Font object loaded directly by the waveform display, fn_080114c4, draw_image_two_texts_and_s_value,
@ draw_arc_gauge.
@ ----------------------------------------------------------------------------
	.p2align 2
@ d_08077f9c: data base of the 16 px font (context word +0, 0x200010F8)
	.global d_08077f9c
d_08077f9c:
	.incbin "assets/fonts/f16_bits.bin"
@ d_080807f0: record table of the 16 px font (context word +4, 0x200010FC)
	.global d_080807f0
d_080807f0:
	.incbin "assets/fonts/f16_recs.bin"
@ d_080819a8: range descriptor of the 16 px font (context word +8, 0x20001100)
	.global d_080819a8
d_080819a8:
	.word	0x00000020		@ +0x00: low bound, key 0x20 (space)
	.hword	0x221e			@ +0x04: high bound, the highest key U+221E (infinity)
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_080819bc		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	100			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_080819bc: key array of the 16 px font (descriptor + 0x14)
	.global d_080819bc
d_080819bc:
	.incbin "assets/fonts/f16_keys.bin"
.Lfont16_end:
	.if (d_080807f0 - d_08077f9c) & 3
	.error "16 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_080819a8 - d_080807f0) != 8 * 100
	.error "16 px font: the record table must hold 100 records (descriptor glyph count)"
	.endif
	.if (.Lfont16_end - d_080819bc) != ((2 * 100 + 3) & ~3)
	.error "16 px font: the key array must hold 100 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 18 px font (font object 0x20001114, context 0x20001128): DejaVu Sans Condensed size 13, 4 bpp,
@ 100 glyphs. The most loaded font object (direct loads): menus, lists, settings pages, the text column highlight.
@ ----------------------------------------------------------------------------
	.p2align 2
@ d_08081e2c: data base of the 18 px font (context word +0, 0x20001128)
	.global d_08081e2c
d_08081e2c:
	.incbin "assets/fonts/f18_bits.bin"
@ d_0808b214: record table of the 18 px font (context word +4, 0x2000112C)
	.global d_0808b214
d_0808b214:
	.incbin "assets/fonts/f18_recs.bin"
@ d_0808c3cc: range descriptor of the 18 px font (context word +8, 0x20001130)
	.global d_0808c3cc
d_0808c3cc:
	.word	0x00000020		@ +0x00: low bound, key 0x20 (space)
	.hword	0x221e			@ +0x04: high bound, the highest key U+221E (infinity)
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_0808c3e0		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	100			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_0808c3e0: key array of the 18 px font (descriptor + 0x14)
	.global d_0808c3e0
d_0808c3e0:
	.incbin "assets/fonts/f18_keys.bin"
.Lfont18_end:
	.if (d_0808b214 - d_08081e2c) & 3
	.error "18 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_0808c3cc - d_0808b214) != 8 * 100
	.error "18 px font: the record table must hold 100 records (descriptor glyph count)"
	.endif
	.if (.Lfont18_end - d_0808c3e0) != ((2 * 100 + 3) & ~3)
	.error "18 px font: the key array must hold 100 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 20 px font (font object 0x20001144, context 0x20001158): DejaVu Sans Condensed Bold size 14, 4 bpp,
@ 100 glyphs. Font object loaded directly by menu and list pages, draw_value_panel, message boxes, the waveform display.
@ ----------------------------------------------------------------------------
	.p2align 2
@ d_0808c850: data base of the 20 px font (context word +0, 0x20001158)
	.global d_0808c850
d_0808c850:
	.incbin "assets/fonts/f20_bits.bin"
@ d_08098fdc: record table of the 20 px font (context word +4, 0x2000115C)
	.global d_08098fdc
d_08098fdc:
	.incbin "assets/fonts/f20_recs.bin"
@ d_0809a194: range descriptor of the 20 px font (context word +8, 0x20001160)
	.global d_0809a194
d_0809a194:
	.word	0x00000020		@ +0x00: low bound, key 0x20 (space)
	.hword	0x221e			@ +0x04: high bound, the highest key U+221E (infinity)
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_0809a1a8		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	100			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_0809a1a8: key array of the 20 px font (descriptor + 0x14)
	.global d_0809a1a8
d_0809a1a8:
	.incbin "assets/fonts/f20_keys.bin"
.Lfont20_end:
	.if (d_08098fdc - d_0808c850) & 3
	.error "20 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_0809a194 - d_08098fdc) != 8 * 100
	.error "20 px font: the record table must hold 100 records (descriptor glyph count)"
	.endif
	.if (.Lfont20_end - d_0809a1a8) != ((2 * 100 + 3) & ~3)
	.error "20 px font: the key array must hold 100 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 25 px font (font object 0x20001174, context 0x20001188): DejaVu Sans Condensed size 19, 4 bpp
@ (V1.2.0's 25 px font was 1 bpp; context word +0x10 at 0x20001198 is 0x08010000 now, src/ram_init.s),
@ 100 glyphs. Font object loaded directly by the waveform display, fn_08010014, fn_080114c4, fn_08012d2c,
@ draw_image_two_texts_and_s_value, draw_arc_gauge.
@ ----------------------------------------------------------------------------
	.p2align 2
@ d_0809a618: data base of the 25 px font (context word +0, 0x20001188)
	.global d_0809a618
d_0809a618:
	.incbin "assets/fonts/f25_bits.bin"
@ d_080a0468: record table of the 25 px font (context word +4, 0x2000118C)
	.global d_080a0468
d_080a0468:
	.incbin "assets/fonts/f25_recs.bin"
@ d_080a1630: range descriptor of the 25 px font (context word +8, 0x20001190)
	.global d_080a1630
d_080a1630:
	.word	0x00000020		@ +0x00: low bound, key 0x20 (space)
	.hword	0x221e			@ +0x04: high bound, the highest key U+221E (infinity)
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_080a1644		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	100			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_080a1644: key array of the 25 px font (descriptor + 0x14)
	.global d_080a1644
d_080a1644:
	.incbin "assets/fonts/f25_keys.bin"
.Lfont25_end:
	.if (d_080a0468 - d_0809a618) & 3
	.error "25 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_080a1630 - d_080a0468) != 8 * 100
	.error "25 px font: the record table must hold 100 records (descriptor glyph count)"
	.endif
	.if (.Lfont25_end - d_080a1644) != ((2 * 100 + 3) & ~3)
	.error "25 px font: the key array must hold 100 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 28 px font (font object 0x200011A4, context 0x200011B8): DejaVu Sans Condensed size 21, 4 bpp,
@ 100 glyphs. Font object loaded directly by fn_08010a94, draw_header_image_120, draw_arc_gauge.
@ ----------------------------------------------------------------------------
	.p2align 2
@ d_080a1ab8: data base of the 28 px font (context word +0, 0x200011B8)
	.global d_080a1ab8
d_080a1ab8:
	.incbin "assets/fonts/f28_bits.bin"
@ d_080b9000: record table of the 28 px font (context word +4, 0x200011BC)
	.global d_080b9000
d_080b9000:
	.incbin "assets/fonts/f28_recs.bin"
@ d_080ba1b8: range descriptor of the 28 px font (context word +8, 0x200011C0)
	.global d_080ba1b8
d_080ba1b8:
	.word	0x00000020		@ +0x00: low bound, key 0x20 (space)
	.hword	0x221e			@ +0x04: high bound, the highest key U+221E (infinity)
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_080ba1cc		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	100			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_080ba1cc: key array of the 28 px font (descriptor + 0x14)
	.global d_080ba1cc
d_080ba1cc:
	.incbin "assets/fonts/f28_keys.bin"
.Lfont28_end:
	.if (d_080b9000 - d_080a1ab8) & 3
	.error "28 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_080ba1b8 - d_080b9000) != 8 * 100
	.error "28 px font: the record table must hold 100 records (descriptor glyph count)"
	.endif
	.if (.Lfont28_end - d_080ba1cc) != ((2 * 100 + 3) & ~3)
	.error "28 px font: the key array must hold 100 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 63 px font (font object 0x200011D4, context 0x200011E8): own 7-segment digits, 1 bpp (context
@ word +0x10 0x02010000), 24 glyphs: 0x20 - . 0-9 A C E L O P S T U r s (V1.2.0's key set and S, for "PAS").
@ Full characters are 28 x 41 pixels (advance 31), 11 rows above the cell bottom. Font object loaded
@ directly by draw_arc_gauge (src/waveform_84.s).
@ ----------------------------------------------------------------------------
	.p2align 2
@ d_080ba63c: data base of the 63 px font (context word +0, 0x200011E8)
	.global d_080ba63c
d_080ba63c:
	.incbin "assets/fonts/f63_bits.bin"
@ d_080bb2f0: record table of the 63 px font (context word +4, 0x200011EC)
	.global d_080bb2f0
d_080bb2f0:
	.incbin "assets/fonts/f63_recs.bin"
@ d_080bb3a8: range descriptor of the 63 px font (context word +8, 0x200011F0)
	.global d_080bb3a8
d_080bb3a8:
	.word	0x00000020		@ +0x00: low bound, key 0x20 (space)
	.hword	0x0073			@ +0x04: high bound, the highest key 0x73 (s)
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_080bb3bc		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	24			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_080bb3bc: key array of the 63 px font (descriptor + 0x14)
	.global d_080bb3bc
d_080bb3bc:
	.incbin "assets/fonts/f63_keys.bin"
.Lfont63_end:
	.if (d_080bb2f0 - d_080ba63c) & 3
	.error "63 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_080bb3a8 - d_080bb2f0) != 8 * 24
	.error "63 px font: the record table must hold 24 records (descriptor glyph count)"
	.endif
	.if (.Lfont63_end - d_080bb3bc) != ((2 * 24 + 3) & ~3)
	.error "63 px font: the key array must hold 24 keys (descriptor glyph count)"
	.endif

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
