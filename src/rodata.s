@ rodata.s - fixed data (V1.2.0 0x08046254..0x080BE67F): format tables, number constants, function
@ pointer tables, the text pointer tables, fonts and glyph bitmaps, pictures and the scatter-load region
@ table (0x080BE314). The initial RAM image it names is src/ram_init.s (typed source, copied at reset).
@ The fonts (assets/fonts/) and pictures (assets/pictures/) are own data with typed descriptors and
@ animation records; the other bytes come from assets/rodata.bin; words that hold code addresses are written as symbols, and so
@ are the data addresses (font key array pointers, scatter-load table). The text pointer tables
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
	.incbin "assets/rodata.bin", 0x0, 1
@ UNREF_08046255: 5 bytes ASCII '12345' (31..35), index 1..5 of the digit text '0123456789ABCDEF' at 0x08046254 | READ: in format_hex_u64, ldr r4,[pc,#132] at 0x0800752a plus add r4,pc at 0x0800752c (word 0x0003ed24 at 0x080075b0 + 0x08007530) gives r4 = 0x08046254, taken when bit 11 of the halfword [r0] is set (lsls #20 / bpl at 0x08007526 / 0x08007528); ldrb r7,[r4,r7] at 0x08007544 with r7 = r2 & 15 (and.w at 0x0800753e), so the index is 0..15
	.global UNREF_08046255
UNREF_08046255:
	.incbin "assets/rodata.bin", 0x1, 5
@ DATA_0804625a: 2 bytes ASCII '67' (36 37), index 6..7 of the digit text at 0x08046254 | the value 0x0804625a is an intermediate: ldr r4,[pc,#124] at 0x08007530 loads the same word 0x0003ed24 from 0x080075b0 and add r4,pc at 0x08007532 gives 0x0003ed24 + 0x08007536 = 0x0804625a, then adds r4,#14 at 0x08007534 makes r4 = 0x08046268 (the text '0123456789abcdef'); no instruction reads at 0x0804625a through this value
	.global DATA_0804625a
DATA_0804625a:
	.global d_0804625a
d_0804625a:
	.incbin "assets/rodata.bin", 0x6, 14
@ d_08046268: lower case digit text '0123456789abcdef@0x'; format_hex_u64 reaches it as d_08046254 + 6 + 14 (second add r4,pc 6 bytes after the first, then adds r4,#14), so these 0x14 bytes stay fixed
	.global d_08046268
d_08046268:
	.incbin "assets/rodata.bin", 0x14, 20
	.if (d_08046268 - d_08046254) != 0x14
	.error "format_hex_u64 (src/format_10.s) needs the lower case digit text 0x14 bytes after d_08046254"
	.endif
@ DATA_0804627c: 20 bytes 04 00 00 08 00 00 00 00 00 00 00 02 00 01 00 00 10 00 00 00: flag table of the format parser 080075b4, indexed by (character - 0x20): ' '=0x04, '#'=0x08, '+'=0x02, '-'=0x01, '0'=0x10 | address built by ldr r11 from the literal 0x0003ECB4 at 0x08007738 and add r11,pc at 0x080075c4 (0x0003ECB4 + 0x080075c8 = 0x0804627c)
	.global DATA_0804627c
DATA_0804627c:
	.global d_0804627c
d_0804627c:
	.incbin "assets/rodata.bin", 0x28, 20
	.global d_08046290
d_08046290:
	.incbin "assets/rodata.bin", 0x3c, 16
	.global d_080462a0
d_080462a0:
	.incbin "assets/rodata.bin", 0x4c, 8
@ UNREF_080462a8: 8 bytes = one 64-bit double 0.5849624872207642 (bytes 00 00 00 40 03 b8 e2 3f) | READ: ldr r0,[pc,#236] at 0x0804410e plus add r0,pc at 0x08044110 gives 0x080462a0; add.w r4,r0,r4,lsl #3 at 0x08044112 and vldr d1,[r4] at 0x0804411a, element size 8; r4 is 0 or 1 (movle r4,#0 at 0x08043e5a, movgt r4,#1 at 0x08043e64, movs r4,#0 at 0x08043e68) and no instruction between 0x08043e72 and 0x08044112 writes r4; this region is r4 = 1
	.global UNREF_080462a8
UNREF_080462a8:
	.incbin "assets/rodata.bin", 0x54, 8
	.global d_080462b0
d_080462b0:
	.incbin "assets/rodata.bin", 0x5c, 8
@ UNREF_080462b8: 8 bytes = one 64-bit double 1.350039202129749e-08 (bytes 06 d0 cf 43 eb fd 4c 3e) | READ: ldr r0,[pc,#284] at 0x080440d8 plus add r0,pc at 0x080440da gives 0x080462b0; add.w r0,r0,r4,lsl #3 at 0x080440dc and vldr d1,[r0] at 0x080440e0, element size 8; r4 is 0 or 1 (set at 0x08043e5a, 0x08043e64, 0x08043e68; not written between 0x08043e72 and 0x080440dc); this region is r4 = 1
	.global UNREF_080462b8
UNREF_080462b8:
	.incbin "assets/rodata.bin", 0x64, 8
@ DATA_080462c0: 48 bytes = 6 64-bit doubles 0.5999999999999946, 0.4285714285785502, 0.33333332981837743, 0.272728123808534, 0.23066074577556175, 0.20697501780033842 | add r0,pc at 0x08043f72 builds this address | double_pow: double-precision x^y routine with special cases for y==0, NaN/inf, 1.0, 2.0, 0.5
	.global DATA_080462c0
DATA_080462c0:
	.global d_080462c0
d_080462c0:
	.incbin "assets/rodata.bin", 0x6c, 48
@ DATA_080462f0: 5 x 64-bit float, 40 bytes, first 0x3fc555555555553e | the array argument of 0x08044c58 (r0 = 0x080462f0 from add r0,pc at 0x0804440c, r1 = 5 from movs r1,#5 at 0x0804440a, call at 0x0804440e), which evaluates the elements from a[4] down to a[0] with 0x0804577c and 0x08044fac.
	.global DATA_080462f0
DATA_080462f0:
	.global d_080462f0
d_080462f0:
	.incbin "assets/rodata.bin", 0x9c, 40
@ DATA_08046318: 4 bytes 00 00 00 00 = float 0.0, the first float of a table of 8-byte pairs of floats spanning 0x08046318..0x08046397 (this region plus DATA_0804631c, 16 pairs) | vldr.32 s6,[r0] at 0x0804467a with r0 = table + 8*r1 (add.w r0,r0,r1,lsl #3 at 0x08044676) | float_pow: single-precision x^y routine with special cases for y==0, x==1.0, NaN, inf
	.global DATA_08046318
DATA_08046318:
	.global d_08046318
d_08046318:
	.incbin "assets/rodata.bin", 0xc4, 4
@ DATA_0804631c: 124 bytes = 31 32-bit floats continuing the pairs table from 0x08046318: second float of pair 0 is 0.0, then pairs (1.3984375, 0.00096796), (2.71875, 5.0023e-05), (3.96875, -0.0019098), (5.1523438, -0.0014942), (6.2773438, -0.00026499), (7.3515625, -0.0006566) ... up to the last pair (15.265625, 0.001516); the first floats of the pairs rise from 0 to 15.265625 and the second floats are below 0.002 in magnitude | vldr.32 s3,[r0,#0x4] at 0x0804467e reads the second float of the pair at table + 8*r1 | float_pow: single-precision x^y routine
	.global DATA_0804631c
DATA_0804631c:
	.incbin "assets/rodata.bin", 0xc8, 124
@ DATA_08046398: 64 bytes = 16 32-bit floats rising 1.0, 1.043945, 1.090332, 1.138672, 1.188965, 1.241699, 1.296387, 1.354004, 1.414062, 1.476562, 1.541992, 1.610352, 1.681641, 1.755859, 1.833984, 1.915039 | vldr.32 s0,[r0] at 0x080447ba with r0 = base + 4*(x & 15) (and.w r0,r0,#15 at 0x0804478a; add.w r0,r1,r0,lsl #2 at 0x080447b4) | float_pow: single-precision x^y routine
	.global DATA_08046398
DATA_08046398:
	.global d_08046398
d_08046398:
	.incbin "assets/rodata.bin", 0x144, 64
@ DATA_080463d8: 64 bytes = 16 32-bit floats of small magnitude 0.0, 0.00032847, 0.00017570, 0.00011676, 0.00024227, 0.00015859, 0.00045284, 0.00025164, 0.00015106, 0.00026365, 0.00021864, 0.00013877, 0.00015221, 0.00039279, 2.3711e-05, 0.00016750 | vldr.32 s2,[r1] at 0x0804479c with r1 = base + 4*(x & 15) (add.w r1,r1,r0,lsl #2 at 0x08044798); s2 then accumulates vmla.f32 s2,s3,s0 at 0x080447ae | float_pow: single-precision x^y routine
	.global DATA_080463d8
DATA_080463d8:
	.global d_080463d8
d_080463d8:
	.incbin "assets/rodata.bin", 0x184, 64
@ DATA_08046418: 63 bytes = 15 whole 32-bit floats 1.0, 1.0442737, 1.0905077, 1.1387886, 1.189207, 1.2418578, 1.2968396, 1.3542556, 1.4142135, 1.4768262, 1.5422108, 1.6104903, 1.6817929, 1.7562522, 1.8340081 plus 3 bytes of a 16th float (whose 4 bytes 0x08046454..0x08046457 read 1.9152066) | vldr.32 s3,[r1] at 0x080447a8 with r1 = base + 4*(x & 15) (add.w r1,r1,r0,lsl #2 at 0x080447a4) | float_pow: single-precision x^y routine
	.global DATA_08046418
DATA_08046418:
	.global d_08046418
d_08046418:
	.incbin "assets/rodata.bin", 0x1c4, 64
@ d_08046458: lower case digit text '0123456789abcdefxp' of format_float_hex; reached as d_0804646b + 6 - 0x19 (src/format_10.s .L08007e98)
	.global d_08046458
d_08046458:
	.incbin "assets/rodata.bin", 0x204, 19
@ d_0804646b: upper case digit text '0123456789ABCDEFXP' of format_float_hex, target of its distance word (src/format_10.s .L08008080); then 2 zero bytes
	.global d_0804646b
d_0804646b:
	.incbin "assets/rodata.bin", 0x217, 21
	.if (d_0804646b - d_08046458) != 0x13
	.error "format_float_hex (src/format_10.s) needs the upper case digit text 0x13 bytes after the lower case one"
	.endif
	.global d_08046480
d_08046480:
	.incbin "assets/rodata.bin", 0x22c, 8
	.global d_08046488
d_08046488:
	.incbin "assets/rodata.bin", 0x234, 8
@ DATA_08046490: 60 bytes = 5 entries of 12 bytes (stride 0xc), each three 32-bit words: (0x00004002, 0xa0000000, 0x0), (0x00004005, 0xc8000000, 0x0), (0x0000400c, 0x9c400000, 0x0), (0x00004019, 0xbebc2000, 0x0), (0x00004034, 0x8e1bc9bf, 0x04000000) | with word0 as exponent (bias 0x3fff) and words 1,2 as the 64-bit mantissa the entries equal 10, 100, 10000, 1e8, 1e16 | add.w r1,r10,r1,lsl #2 at 0x080084ac | fn_08008448: combines 12-byte table entries with 0804356a and divides with 08043540 when n is negative
	.global DATA_08046490
DATA_08046490:
	.global d_08046490
d_08046490:			@ reached by fn_08008448 as d_0804650c - 0x7c (src/format_10.s .L08008496)
	.incbin "assets/rodata.bin", 0x23c, 60
@ DATA_080464cc: 4 bytes b5 40 00 00 = word 0x000040b5, word 0 (exponent word) of the 16-byte entry at 0x080464cc | ldm.w r0,{r1,r2,r3} at 0x080084d4 loads words 0..2 of the entry | entry words (0x000040b5, 0xd0cf4b50, 0xcfe20766, 0x00000001) equal 1e55 with the same reading as the table at 0x08046490 | fn_08008448: combines 12-byte table entries with 0804356a
	.global DATA_080464cc
DATA_080464cc:
	.global d_080464cc
d_080464cc:			@ reached by fn_08008448 as d_0804650c - 0x40 (src/format_10.s .L080084c2)
	.incbin "assets/rodata.bin", 0x278, 4
@ DATA_080464d0: 4 bytes 50 4b cf d0 = word 0xd0cf4b50, word 1 of the 16-byte entry at 0x080464cc (high mantissa word) | loaded by ldm.w r0,{r1,r2,r3} at 0x080084d4 in fn_08008448
	.global DATA_080464d0
DATA_080464d0:
	.incbin "assets/rodata.bin", 0x27c, 4
@ DATA_080464d4: 4 bytes 66 07 e2 cf = word 0xcfe20766, word 2 of the 16-byte entry at 0x080464cc (low mantissa word) | loaded by ldm.w r0,{r1,r2,r3} at 0x080084d4 in fn_08008448
	.global DATA_080464d4
DATA_080464d4:
	.incbin "assets/rodata.bin", 0x280, 4
@ DATA_080464d8: 52 bytes = word 0x00000001 (word 3 of the entry at 0x080464cc, read by ldr r0,[r0,#0xc] at 0x080084dc) followed by three 16-byte entries (0x0000416c, 0xaa51823e, 0x34a7eedf, 0x00000001), (0x000042d9, 0xe2a0b5dc, 0x971f303a, 0xffffffff), (0x000045b4, 0xc8a025fd, 0x4fc1a3e9, 0xffffffff) = 1e110, 1e220, 1e440 with the exponent/mantissa reading used for 0x08046490 | stride 0x10 | fn_08008448: combines 12-byte table entries with 0804356a
	.global DATA_080464d8
DATA_080464d8:
	.incbin "assets/rodata.bin", 0x284, 52
@ d_0804650c: 12-byte extended value 1.0 (words 0x00003fff, 0x80000000, 0), target of fn_08008448's distance word (src/format_10.s .L08008528)
	.global d_0804650c
d_0804650c:
	.incbin "assets/rodata.bin", 0x2b8, 12
@ d_08046518: 12-byte extended value 1.0 again plus a zero word; reached by fn_08008448 as d_0804650c + 0xc (src/format_10.s .L0800845e)
	.global d_08046518
d_08046518:
	.incbin "assets/rodata.bin", 0x2c4, 16
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
	.incbin "assets/rodata.bin", 0x2d4, 7
@ UNREF_0804652f: 8 bytes 08 09 0a 0b 0c 0d 0e 0f (ascending) | READ: the function containing 0x08040382 holds sl = 0x08046528 (movw at 0x08040382, movt at 0x08040392); r6 = 0,3,6,9,12 (movs r6,#0 at 0x0804039e, adds r6,#3 at 0x080403a8, cmp r6,#15 / beq at 0x080403aa); bytes are loaded with ldrb.w r1,[sl,r6] (0x080403e8, 0x08040406), ldrb r5,[r5,#15] after add.w r5,sl,r6 (0x080403d2, 0x080403d6), [r5,#16] (0x08040432, 0x08040436), [r5,#17] (0x08040494, 0x08040498), [r1,#1] (0x08040448, 0x0804044c and 0x08040466, 0x0804046a) and [r1,#2] (0x080404ae, 0x080404b2 and 0x080404d2, 0x080404d6), so the bytes 0x08046528..0x08046545 are addressed; this region (0x0804652f..0x08046536) is inside that range (offsets 7..14 from 0x08046528: [sl,r6] reaches 0x08046531 and 0x08046534, [r1,#1] reaches 0x0804652f, 0x08046532, 0x08046535, [r1,#2] reaches 0x08046530, 0x08046533, 0x08046536)
	.global UNREF_0804652f
UNREF_0804652f:
	.incbin "assets/rodata.bin", 0x2db, 16
@ UNREF_0804653f: 5 bytes 15 16 00 00 00 | READ: the function containing 0x08040382 holds sl = 0x08046528 (movw at 0x08040382, movt at 0x08040392); r6 = 0,3,6,9,12 (movs r6,#0 at 0x0804039e, adds r6,#3 at 0x080403a8, cmp r6,#15 / beq at 0x080403aa); bytes are loaded with ldrb.w r1,[sl,r6] (0x080403e8, 0x08040406), ldrb r5,[r5,#15] after add.w r5,sl,r6 (0x080403d2, 0x080403d6), [r5,#16] (0x08040432, 0x08040436), [r5,#17] (0x08040494, 0x08040498), [r1,#1] (0x08040448, 0x0804044c and 0x08040466, 0x0804046a) and [r1,#2] (0x080404ae, 0x080404b2 and 0x080404d2, 0x080404d6), so the bytes 0x08046528..0x08046545 are addressed; this region (0x0804653f..0x08046543) is offsets 0x17..0x1b from 0x08046528: [r5,#17] with r6 = 6 reaches 0x0804653f, [r5,#15] with r6 = 9 reaches 0x08046540, [r5,#16] with r6 = 9 reaches 0x08046541, [r5,#17] with r6 = 9 reaches 0x08046542, [r5,#15] with r6 = 12 reaches 0x08046543
	.global UNREF_0804653f
UNREF_0804653f:
	.incbin "assets/rodata.bin", 0x2eb, 5
@ DATA_08046544: 4 bytes 00 17 00 00 = word 0x00001700 = element 0 of the word table at 0x08046544 | ldr.w r0,[r0,#-0x4] at 0x08040094 then blx r0 at 0x08040098, with r0 = r8 + 4*byte [sp+7] (add.w at 0x08040090) and r8 = 0x08046548 (movw #0x6548 at 0x08040012, movt at 0x08040028); the words from 0x08046548 on are 0x08009fe1, 0x0800cb51, 0x0800cfcd, 0x0800d121 ... through 0x0800d955 at 0x080465a0 (odd addresses in the code range) | the code at 0x08040012..0x0804009a is inside fn_08040008 (0x08040008..0x0804009b)
	.global DATA_08046544
DATA_08046544:
	.incbin "assets/rodata.bin", 0x2f0, 4
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
	.incbin "assets/rodata.bin", 0x350, 36
	.global d_080465c8
d_080465c8:
	.incbin "assets/rodata.bin", 0x374, 2
@ UNREF_080465ca: 2 bytes 05 00 = halfword 5; the bytes at 0x080465c8..0x080465c9 are 01 02, then halfwords 10 (0x080465cc), 20, 50, 100, 200 (0x080465d4), 500 (0x080465d6), 1000, 2000, 5000, 10000 follow | READ: the byte table at 0x080465c8 (bytes 01 02 05) is indexed by a value modulo 3 computed by multiplying with 0xaaaaaaab (movw/movt at 0x08020f30/0x08020f34, copied to r5 at 0x08020f50) and subtracting 3*quotient: ldrb r2,[r7,r2] at 0x08020fa4 (r7 = 0x080465c8 from movw/movt at 0x08020f9a/0x08020fa0, index r2 + r3 with r3 = r6 - 4*r6 at 0x08020f94, so index 0..2), ldrb r2,[r3,r2] at 0x080210b0, ldrb r0,[r8,r0] at 0x08026040, ldrb r0,[r4,r0] at 0x0802644a, ldrb r0,[r1,r0] at 0x0802e09c, ldrb r3,[r4,r3] at 0x0803b14c, ldrb.w r3,[r9,r3] at 0x0803b36e, ldrb r0,[r7,r0] at 0x0803b4f4 and ldrb.w r0,[r9,r0] at 0x0803b5dc, each with the same modulo-3 index (0..2); the byte 0x080465ca (value 5) is index 2 and is read; the byte 0x080465cb (value 0) is not addressed through this base (index <= 2) and no other base reaches it
	.global UNREF_080465ca
UNREF_080465ca:
	.incbin "assets/rodata.bin", 0x376, 2
	.global d_080465cc
d_080465cc:
	.incbin "assets/rodata.bin", 0x378, 2
@ UNREF_080465ce: 8 bytes = 4 halfwords 0x14, 0x32, 0x64, 0xc8 (20, 50, 100, 200), after the halfwords 5 (0x080465ca) and 10 (0x080465cc) and before 500 at 0x080465d6 | READ: the halfword table at 0x080465cc is read with ldrh.w r2,[r7,r2,lsl #1] at 0x080212c6 (r7 = 0x080465cc from movw/movt at 0x080212bc/0x080212c2, index r2 = ldrb [r2] at 0x080212ba, no compare between the load and the ldrh), ldrh.w r2,[r7,r3,lsl #1] at 0x080212d0, ldrh.w r1,[r0,r1,lsl #1] at 0x0802431a (base from movw/movt at 0x08024312/0x08024316, index ldrb.w [r8,#2] at 0x0802430e) and through lr (movw at 0x080223ca, movt at 0x080223e0), element size 2, so the code allows index 0..255; this region is elements 1..4 (0x080465ce = 0x080465cc + 2)
	.global UNREF_080465ce
UNREF_080465ce:
	.incbin "assets/rodata.bin", 0x37a, 10
@ UNREF_080465d8: 112 bytes: 4 halfwords 0x03e8, 0x07d0, 0x1388, 0x2710 (1000, 2000, 5000, 10000) then 13 64-bit little-endian values 10, 10, 10, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000 (the next value 20000 is at 0x08046648, outside this region) | READ: the halfwords 0x080465d8..0x080465df are elements 6..9 of the halfword table at 0x080465cc (the halfword table at 0x080465cc is read with ldrh.w r2,[r7,r2,lsl #1] at 0x080212c6 (r7 = 0x080465cc from movw/movt at 0x080212bc/0x080212c2, index r2 = ldrb [r2] at 0x080212ba, no compare between the load and the ldrh), ldrh.w r2,[r7,r3,lsl #1] at 0x080212d0, ldrh.w r1,[r0,r1,lsl #1] at 0x0802431a (base from movw/movt at 0x08024312/0x08024316, index ldrb.w [r8,#2] at 0x0802430e) and through lr (movw at 0x080223ca, movt at 0x080223e0), element size 2, so the code allows index 0..255); the 64-bit values from 0x080465e0 are read by ldr.w r4,[ip,r3,lsl #3] at 0x08030b02 and ldr r0,[r0,#4] at 0x08030b1e (add.w r0,ip,r3,lsl #3 at 0x08030b1a) with ip = 0x080465e0 (movw/movt at 0x08030af8/0x08030afc), element size 8, and r3 = ldrb.w [r8,#3520] at 0x08030ae8 (no compare bounds it: cmp r3,#4 at 0x08030aee only selects r2), so the code allows index 0..255
	.global UNREF_080465d8
UNREF_080465d8:
	.incbin "assets/rodata.bin", 0x384, 8
	.global d_080465e0
d_080465e0:
	.incbin "assets/rodata.bin", 0x38c, 112
@ UNREF_08046650: 128 bytes = 16 64-bit little-endian values 50000, 100000, 200000, 500000, 1000000, 2000000, 5000000, 10000000, 20000000, 50000000, 100000000, 200000000, 500000000, 1000000000, 2000000000, then 1 | READ: the 64-bit values are read with ldr.w r4,[ip,r3,lsl #3] at 0x08030b02 and ldr r0,[r0,#4] at 0x08030b1e where ip = 0x080465e0 and r3 = ldrb.w [r8,#3520] (0x08030ae8, no bound), element size 8, so 0x080465e0 + 8*r3 reaches this region (it starts at element 14); the last value (1 at 0x080466c8..0x080466cf) is also read with base 0x080466c8 (movw/movt at 0x08030aaa/0x08030ab0) by ldr.w r0,[r1,r0,lsl #3] at 0x08030ab8 and ldr r1,[r2,#4] at 0x08030abc, r2 = r1 + 8*r0 (add.w at 0x08030ab4), r0 = value modulo 3 (umull by 0xaaaaaaab at 0x08030a9e, lsrs at 0x08030aa2, sub.w at 0x08030aa4, add at 0x08030aa8) = 0..2, element 0 = 1
	.global UNREF_08046650
UNREF_08046650:
	.incbin "assets/rodata.bin", 0x3fc, 120
	.global d_080466c8
d_080466c8:
	.incbin "assets/rodata.bin", 0x474, 16
@ UNREF_080466d8: 15624 bytes = 3906 32-bit little-endian words; word 0 is 5, words 1..8 are 0, word 9 (0x080466fc) is 0x8000, zeros follow until 0x08046720 where signed words begin: -112, 189, -424, 883, -1683, 3105, ... with alternating sign | READ: ldr.w r7,[r2,ip] at 0x0803d6e2, ldrd r7,fp,[r9,#4] at 0x0803d6f2 and further ldr.w from [r9,#12..#48] (0x0803d700, 0x0803d706, 0x0803d720, 0x0803d732, 0x0803d738, 0x0803d74a, 0x0803d750, 0x0803d762, 0x0803d768, 0x0803d77a) with r2 = 0x080466e0 + 64*r0 (movw/movt at 0x0803d630/0x0803d636, add.w r2,r2,r0,lsl #6 at 0x0803d63a), r0 = uxth r7 (0x0803d634) and r7 = sum of constants chosen by compares of r3 (2 if r3 > 2, +4 if > 4, +5 if > 5, +8 if > 8, +10 if > 10, +20 if > 20, +25 if > 25, +40 if > 40, +50 if > 50 at 0x0803d5dc..0x0803d612, +80 if > 80 at 0x0803d61c), so r7 = 0..244 and the rows are 64 bytes (this path is taken when r2 >= 17: cmp r2,#17 / bcc at 0x0803d614 / 0x0803d618); rows 0..243 (0x080466e0..0x0804a3df) are inside this region; the first 8 bytes (0x080466d8..0x080466df) precede row 0 and are not addressed
	.global UNREF_080466d8
UNREF_080466d8:
	.incbin "assets/rodata.bin", 0x484, 8
	.global d_080466e0
d_080466e0:
	.incbin "assets/rodata.bin", 0x48c, 15700
@ UNREF_0804a434: 6202 bytes = signed 32-bit words 141, -313, 32762, 320, -143, 79, -45, 24, -12, 5, -3, -11, ... (first bytes 8d 00 00 00 c7 fe ff ff fa 7f 00 00 40 01 00 00); the region ends at 0x0804bc6e inside the word 0x00000030 at 0x0804bc6c (its bytes 30 00 are the last two bytes of this region, its bytes 00 00 are the first two bytes of DATA_0804bc6e); the words -89, 158, -287, 646, 32746 start at 0x0804bc70 | no reference found
	.global UNREF_0804a434
UNREF_0804a434:
	.incbin "assets/rodata.bin", 0x41e0, 6202
@ DATA_0804bc6e: 114 bytes: 0x0000 (the upper two bytes of the word 0x00000030 at 0x0804bc6c) then 32-bit words (word-aligned from 0x0804bc70) -89, 158, -287, 646, 32746, -619, 280, -155, 87, -47, 23, -11, -3, 5, -12, 24 ... | the reference is an address bias: ldrh r6,[r0,r1] at 0x0803678c in path_resolve uses r0 = 0x0804bd6e + 2*byte (add.w r0,r1,r0,lsl #1 at 0x08036784, movw #0xbd6e/movt #0x804 at 0x0803677c/0x08036780) and r1 = -256 (mvn.w r1,#255 at 0x08036788) for bytes >= 0x80, so the loads read 0x0804bd6e..0x0804be6d, not these bytes | path_resolve: walks a path string against a directory object and converts bytes to halfwords
	.global DATA_0804bc6e
DATA_0804bc6e:
	.incbin "assets/rodata.bin", 0x5a1a, 114
	.global d_0804bce0
d_0804bce0:
	.incbin "assets/rodata.bin", 0x5a8c, 2
@ UNREF_0804bce2: 8 bytes fa 00 f4 01 00 00 00 00 = halfwords 0x00fa, 0x01f4, 0x0000, 0x0000 | elements 1 and 2 of the halfword table at 0x0804bce0 (0x007d, 0x00fa, 0x01f4): ldrh.w r0,[r1,r0,lsl #1] at 0x08026734 and ldrh.w r0,[r2,r0,lsl #1] at 0x080267f6 in compute_channel_measurements with r1/r2 = 0x0804bce0 (movw/movt at 0x0802672a/0x08026730 and 0x080267ec/0x080267f2) and r0 = a value minus 3*(value/3) (smmul by 0x55555556 at 0x0802671c); the other halfwords of this region are 0 | a movw/movt pair of one register ending at 0x080304c2 gives 0x0804bce8 (offset 0x6)
	.global UNREF_0804bce2
UNREF_0804bce2:
	.incbin "assets/rodata.bin", 0x5a8e, 6
	.global d_0804bce8
d_0804bce8:
	.incbin "assets/rodata.bin", 0x5a94, 4
	.incbin "assets/rodata.bin", 0x5a98, 1		@ 0x0804bcec, the byte before the table (the code addresses the table by its own label d_0804bced)
@ DATA_0804bced: 129 bytes: 128 entries 80 9a 45 41 8e 41 8f 80 45 45 45 49 49 49 8e 8f 90 92 92 4f 99 4f 55 55 59 99 9a 9b 9c 9d 9e 9f 41 49 4f 55 a5 a5 a6 a7 a8 a9 aa ab ac ad ae af ... through ff (byte 127 = 0xff), plus a trailing 00 | ldrb r6,[r1,r0] at 0x08036a4a with r1 = 0x0804bced (movw/movt at 0x08036a3e/0x08036a46) and r0 = result & 0x7f (and.w at 0x08036a42), taken when bit 7 of the result of bl 0x08035908 is set (bpl at 0x08036a3c) | path_resolve: walks a path string against a directory object
	.global DATA_0804bced
DATA_0804bced:
	.global d_0804bced
d_0804bced:
	.incbin "assets/rodata.bin", 0x5a99, 129
	.global d_0804bd6e
d_0804bd6e:
	.incbin "assets/rodata.bin", 0x5b1a, 44
@ UNREF_0804bd9a: 214 bytes = 107 halfwords (table elements 22..127 and, after the table, the halfword 0x0000 at 0x0804be6e) 0x00fb, 0x00f9, 0x00ff, 0x00d6, 0x00dc, 0x00a2, 0x00a3, 0x00a5, 0x20a7, 0x0192, 0x00e1, 0x00ed, 0x00f3, 0x00fa, 0x00f1, 0x00d1, 0x00aa, 0x00ba, 0x00bf, 0x2310, 0x00ac, 0x00bd, 0x00bc, 0x00a1 ... | it lies inside the 128-halfword table 0x0804bd6e..0x0804be6d (first halfwords 0x00c7, 0x00fc, 0x00e9, 0x00e2; last 0x25a0, 0x00a0) that path_resolve reads at 0x0804bd6e + 2*(byte-0x80) (ldrh at 0x0803678c); this region starts at table element 22
	.global UNREF_0804bd9a
UNREF_0804bd9a:
	.incbin "assets/rodata.bin", 0x5b46, 214
	.global d_0804be70
d_0804be70:
	.incbin "assets/rodata.bin", 0x5c1c, 4
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
	.incbin "assets/rodata.bin", 0x5d64, 8
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
	.incbin "assets/rodata.bin", 0x5f2c, 6
@ UNREF_0804c186: 2 bytes 00 00 = element 3 of the halfword array at 0x0804c180 (0x8c73, 0xffff, 0x055f, 0x0000); the next bytes 0x0804c188.. are the words 0x080bb8b2, 0x080bb682 ... | no reference found
	.global UNREF_0804c186
UNREF_0804c186:
	.incbin "assets/rodata.bin", 0x5f32, 2
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
	.incbin "assets/rodata.bin", 0x75df, 14
@ UNREF_0804d841: 7 bytes 03 05 09 15 29 52 00 | READ: ldrb r1,[r1,r0] at 0x0803e558 with r1 = 0x0804d833 (movw/movt at 0x0803e550/0x0803e554) and r0 = ldrb.w [r9,#45] at 0x0803e54c (no compare shown between them), and ldrb r1,[r3,r1] at 0x0804067c with r3 = 0x0804d833 (movw/movt at 0x08040670/0x08040678) and r1 = ldrb [r0,#45] at 0x08040668 limited by cmp r1,#19 / bhi at 0x0804066c / 0x0804066e (0..19); this region is index 14..20 (0x0804d841 = 0x0804d833 + 14), index 14..19 reachable at 0x0804067c
	.global UNREF_0804d841
UNREF_0804d841:
	.incbin "assets/rodata.bin", 0x75ed, 7
@ d_0804d848: anchor of the 1600-byte waveform block 0x0804d848..0x0804de87 (8 tables of 100 halfwords, 200-byte
@ stride). fill_output_waveform_table (src/siggen_55.s) reaches every table as d_0804d848 + 200*case minus
@ 0x3d6..0x3e8, so the block is one unit: only d_0804d848 is a label, the inner layout stays (guard after the block).
	.global d_0804d848
d_0804d848:
	.incbin "assets/rodata.bin", 0x75f4, 28
@ UNREF_0804d864: 78 bytes = 39 halfwords 3624, 3703, 3775, 3841, 3899, 3950, 3994, 4030, 4058, 4078, 4090, 4094 (peak at 0x0804d87a), 4090, 4078, ... falling to 1790 (first bytes 28 0e 77 0e bf 0e 01 0f) | element 14 onward of the 100-halfword table at 0x0804d848 (table 0 of the 200-byte-stride tables 0x0804d848 + 200*index, movw #0xd848 at 0x08029e4a); table 0 starts 2047, 2176, 2304, 2431, 2556, 2680 | READ: the loop at 0x0802a1e0..0x0802a29c reads table 0: ldrh r2,[r6,r1] at 0x0802a1e8 with r6 = 0x0804d848 (movw/movt at 0x0802a1e0/0x0802a1e4), then ldrh [r5,#2] .. [r5,#18] with r5 = r6 + r1 (adds at 0x0802a1ea), r1 = 0, 20, .. 180 (adds r1,#20 at 0x0802a258, cmp r1,#200 / bne at 0x0802a28e / 0x0802a29c), so all 100 halfwords 0x0804d848..0x0804d90f are read; this region is elements 14..52
	.global UNREF_0804d864
UNREF_0804d864:
	.incbin "assets/rodata.bin", 0x7610, 79
@ UNREF_0804d8b3: 193 bytes from the odd address 0x0804d8b3; the halfwords from 0x0804d8b2 are table-0 elements 53..99 of 0x0804d848: 1663, 1538, 1414, 1293, 1175, 1061, 950, 844, 742, 646, 555, 470 ... falling to 0 (element 75, 0x0804d8de), rising again 4, 16, 36, 64 ... to 1790, 1918 (element 99, 0x0804d90e), followed by table 1 (0x0804d910 = 0x0804d848 + 200*1) elements 0..49: 2047, 2176, 2304, 2431, 2556, 2680 ... to 2176 and then 2048 2048 2048 (indexing 0x0804d848 + 200*index per smlabb ...,#200 at 0x08029e54) | READ: elements 53..99 (0x0804d8b2..0x0804d90f) are read by the loop at 0x0802a1e0..0x0802a29c (ldrh r2,[r6,r1] at 0x0802a1e8 and [r5,#2..#18], r6 = 0x0804d848, r1 = 0, 20, .. 180, cmp r1,#200 at 0x0802a28e); table 1 (0x0804d910..0x0804d9d7) is read by the code at 0x08029f82 (smlabb r7,r2,r3,r0 with r3 = 200 and r0 = 0x0804d848 from movw/movt at 0x08029f78/0x08029f7c; r2 = 3 or 4 from tbh at 0x08029e2c), which forms ten pointers r7-400..r7-382 (sub.w at 0x08029f86..0x08029fc4) = table (r2-2) and loads ldrh r0,[r0,r6] through them (0x08029fd6..0x0802a03e) with r6 = 0, 20, .. 180 (adds r6,#20 at 0x0802a056, cmp r6,#200 at 0x0802a090), so all 100 halfwords of table 1 are read when r2 = 3
	.global UNREF_0804d8b3
UNREF_0804d8b3:
	.incbin "assets/rodata.bin", 0x765f, 293
@ UNREF_0804d9d8: 1200 bytes = 6 tables of 100 halfwords (200-byte stride) at 0x0804d9d8, 0x0804daa0, 0x0804db68, 0x0804dc30, 0x0804dcf8, 0x0804ddc0, i.e. indexes 2..7 of 0x0804d848 + 200*index (smlabb ...,#200 at 0x08029e54, movw #0xd848 at 0x08029e4a); table starts: 2047, 2111, 2176, 2240, 2304, 2367 (max 4095) | 30, 31, 33, 34, 36, 38 | 4065, 4063, 4061, 4060, 4058, 4056 | 2049, 2532, 2986, 3386, 3709, 3940 | 729, 661, 601, 556, 535, 541 | 1, 52, 105, 160, 217, 276; the region ends at 0x0804de88 | READ: tables 2..7 (0x0804d848 + 200*index) are read through three sites that form a base with smlabb from 0x0804d848 + 200*r2: at 0x08029f82 (r2 = 3 or 4, entries 3 and 4 of the tbh at 0x08029e2c) with ten pointers r7-400..r7-382 (sub.w at 0x08029f86..0x08029fc4) used by ldrh r0,[r0,r6] at 0x08029fd6..0x0802a03e, r6 = 0, 20, .. 180 (adds r6,#20 at 0x0802a056, cmp r6,#200 at 0x0802a090), i.e. table r2-2; at 0x0802a0ae (r2 = 7 or 8) with ten pointers r3-800..r3-782 (0x0802a0b2..0x0802a0f0) used by ldrh r4,[r1,r7] at 0x0802a106..0x0802a16c, r7 = 0, 20, .. 180 (adds r7,#20 at 0x0802a178, cmp r7,#200 at 0x0802a1bc), i.e. table r2-4; at 0x08029e54 (r2 = 10, 11 or 12) with ten pointers r7-1000..r7-982 (0x08029e58..) used by ldrh r4,[r0,r6] at 0x08029eae..0x08029f14, r6 = 0, 20, .. 180 (adds r6,#20 at 0x08029f20, cmp r6,#200 at 0x08029f64), i.e. table r2-5; each of these loops reads all 100 halfwords of its table, so tables 2 (r2 = 4), 3 (r2 = 7), 4 (r2 = 8), 5, 6 and 7 (r2 = 10, 11, 12) of this region are read
	.global UNREF_0804d9d8
UNREF_0804d9d8:
	.incbin "assets/rodata.bin", 0x7784, 1200
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
	.incbin "assets/rodata.bin", 0xbac5, 4
@ UNREF_08051d1d: 115619 bytes, first bytes ff x18 then a5 c3 06 00 00 00 01 20 68 1b 10 00 ...; 89285 of the bytes are 00 | READ: the loop at 0x0802db74..0x0802dc30 loads ldrb.w r3,[r1,r0] at 0x0802db7c, ldrb r7,[r3,#1] at 0x0802dbba (r3 = r0 + r1) and ldrb r3,[r3,#2] at 0x0802dbf4, advances r0 by 3 (adds r0,#3 at 0x0802db74) from 0 (movs at 0x0802db30) until r0 == r2 (cmp at 0x0802db78, beq at 0x0802db7a) with r1 = 0x08051d19 (movw/movt at 0x0802db28/0x0802db32) and r2 = 0x0001c3b6 (movw/movt at 0x0802db2c/0x0802db36), so the bytes 0x08051d19..0x0806e0ce are read, which includes this whole region (0x08051d1d..0x0806e0bf); the two words 0x0805f000 found at 0x080088ac and 0x08008a60 are bytes inside instructions (tbb at 0x080088aa and 0x08008a5e) and not pointers
	.global UNREF_08051d1d
UNREF_08051d1d:
	.incbin "assets/rodata.bin", 0xbac9, 115619
@ DATA_0806e0c0: 16 bytes ff 08 00 00 00 ff ff ff ff ff ff ff ff ff ff 00 (not floats) | the reference is an address bias: movw r0,#0xe0d0 at 0x08025208 and movt r0,#0x806 at 0x08025214 give 0x0806e0d0, subs r0,#16 at 0x08025224 gives 0x0806e0c0, str r0,[sp,#4] at 0x0802522a; the data at 0x0806e0d0 are 8-byte pairs of floats (1.0, 0.0), (0.9987954, 0.0490677), (0.9951847, 0.0980171), (0.9891765, 0.1467305) ... | compute_spectrum_bytes: per channel: allocates 0x400/0x200/0x80 byte buffers and fills 256 floats from a byte ring
	.global DATA_0806e0c0
DATA_0806e0c0:
	.incbin "assets/rodata.bin", 0x27e6c, 16
	.global d_0806e0d0
d_0806e0d0:
	.incbin "assets/rodata.bin", 0x27e7c, 24
@ UNREF_0806e0e8: 8 bytes = 2 32-bit floats 0.9891765, 0.1467305 (x*x + y*y = 1.00000) = pair 3 of the 8-byte float-pair table that starts at 0x0806e0d0 (address built at 0x08025208/0x08025214 in compute_spectrum_bytes) | READ: vldr s1,[r2,#16] at 0x08025480 and vldr s3,[r2,#20] at 0x08025484 (pair 2k) and vldr s0,[r2,#24] at 0x080254d0 and vldr s2,[r2,#28] at 0x080254d4 (pair 2k+1) with r2 = 0x0806e0c0 + 16*k (movw/movt at 0x08025208/0x08025214, subs r0,#16 at 0x08025224, str r0,[sp,#4] at 0x0802522a, ldr r2,[sp,#4] at 0x080253d8, adds r2,#16 at 0x08025518) and k = 0..15 (mvn.w r0,#15 at 0x080253e2, adds r0,#1 at 0x0802551c, bcc at 0x0802551e), so pairs 0..31 (0x0806e0d0..0x0806e1cf) are read; this region is pair 3 (k = 1, second pair of the iteration)
	.global UNREF_0806e0e8
UNREF_0806e0e8:
	.incbin "assets/rodata.bin", 0x27e94, 16
@ UNREF_0806e0f8: 8 bytes = 2 32-bit floats 0.9700313, 0.2429802 (x*x + y*y = 1.00000) = pair 5 of the 8-byte float-pair table that starts at 0x0806e0d0 (address built at 0x08025208/0x08025214 in compute_spectrum_bytes) | READ: vldr s1,[r2,#16] at 0x08025480 and vldr s3,[r2,#20] at 0x08025484 (pair 2k) and vldr s0,[r2,#24] at 0x080254d0 and vldr s2,[r2,#28] at 0x080254d4 (pair 2k+1) with r2 = 0x0806e0c0 + 16*k (movw/movt at 0x08025208/0x08025214, subs r0,#16 at 0x08025224, str r0,[sp,#4] at 0x0802522a, ldr r2,[sp,#4] at 0x080253d8, adds r2,#16 at 0x08025518) and k = 0..15 (mvn.w r0,#15 at 0x080253e2, adds r0,#1 at 0x0802551c, bcc at 0x0802551e), so pairs 0..31 (0x0806e0d0..0x0806e1cf) are read; this region is pair 5 (k = 2, second pair of the iteration)
	.global UNREF_0806e0f8
UNREF_0806e0f8:
	.incbin "assets/rodata.bin", 0x27ea4, 16
@ UNREF_0806e108: 8 bytes = 2 32-bit floats 0.9415441, 0.3368899 (x*x + y*y = 1.00000) = pair 7 of the 8-byte float-pair table that starts at 0x0806e0d0 (address built at 0x08025208/0x08025214 in compute_spectrum_bytes) | READ: vldr s1,[r2,#16] at 0x08025480 and vldr s3,[r2,#20] at 0x08025484 (pair 2k) and vldr s0,[r2,#24] at 0x080254d0 and vldr s2,[r2,#28] at 0x080254d4 (pair 2k+1) with r2 = 0x0806e0c0 + 16*k (movw/movt at 0x08025208/0x08025214, subs r0,#16 at 0x08025224, str r0,[sp,#4] at 0x0802522a, ldr r2,[sp,#4] at 0x080253d8, adds r2,#16 at 0x08025518) and k = 0..15 (mvn.w r0,#15 at 0x080253e2, adds r0,#1 at 0x0802551c, bcc at 0x0802551e), so pairs 0..31 (0x0806e0d0..0x0806e1cf) are read; this region is pair 7 (k = 3, second pair of the iteration)
	.global UNREF_0806e108
UNREF_0806e108:
	.incbin "assets/rodata.bin", 0x27eb4, 16
@ UNREF_0806e118: 8 bytes = 2 32-bit floats 0.9039893, 0.4275551 (x*x + y*y = 1.00000) = pair 9 of the 8-byte float-pair table that starts at 0x0806e0d0 (address built at 0x08025208/0x08025214 in compute_spectrum_bytes) | READ: vldr s1,[r2,#16] at 0x08025480 and vldr s3,[r2,#20] at 0x08025484 (pair 2k) and vldr s0,[r2,#24] at 0x080254d0 and vldr s2,[r2,#28] at 0x080254d4 (pair 2k+1) with r2 = 0x0806e0c0 + 16*k (movw/movt at 0x08025208/0x08025214, subs r0,#16 at 0x08025224, str r0,[sp,#4] at 0x0802522a, ldr r2,[sp,#4] at 0x080253d8, adds r2,#16 at 0x08025518) and k = 0..15 (mvn.w r0,#15 at 0x080253e2, adds r0,#1 at 0x0802551c, bcc at 0x0802551e), so pairs 0..31 (0x0806e0d0..0x0806e1cf) are read; this region is pair 9 (k = 4, second pair of the iteration)
	.global UNREF_0806e118
UNREF_0806e118:
	.incbin "assets/rodata.bin", 0x27ec4, 16
@ UNREF_0806e128: 8 bytes = 2 32-bit floats 0.8577286, 0.5141028 (x*x + y*y = 1.00000) = pair 11 of the 8-byte float-pair table that starts at 0x0806e0d0 (address built at 0x08025208/0x08025214 in compute_spectrum_bytes) | READ: vldr s1,[r2,#16] at 0x08025480 and vldr s3,[r2,#20] at 0x08025484 (pair 2k) and vldr s0,[r2,#24] at 0x080254d0 and vldr s2,[r2,#28] at 0x080254d4 (pair 2k+1) with r2 = 0x0806e0c0 + 16*k (movw/movt at 0x08025208/0x08025214, subs r0,#16 at 0x08025224, str r0,[sp,#4] at 0x0802522a, ldr r2,[sp,#4] at 0x080253d8, adds r2,#16 at 0x08025518) and k = 0..15 (mvn.w r0,#15 at 0x080253e2, adds r0,#1 at 0x0802551c, bcc at 0x0802551e), so pairs 0..31 (0x0806e0d0..0x0806e1cf) are read; this region is pair 11 (k = 5, second pair of the iteration)
	.global UNREF_0806e128
UNREF_0806e128:
	.incbin "assets/rodata.bin", 0x27ed4, 16
@ UNREF_0806e138: 8 bytes = 2 32-bit floats 0.8032075, 0.5956993 (x*x + y*y = 1.00000) = pair 13 of the 8-byte float-pair table that starts at 0x0806e0d0 (address built at 0x08025208/0x08025214 in compute_spectrum_bytes) | READ: vldr s1,[r2,#16] at 0x08025480 and vldr s3,[r2,#20] at 0x08025484 (pair 2k) and vldr s0,[r2,#24] at 0x080254d0 and vldr s2,[r2,#28] at 0x080254d4 (pair 2k+1) with r2 = 0x0806e0c0 + 16*k (movw/movt at 0x08025208/0x08025214, subs r0,#16 at 0x08025224, str r0,[sp,#4] at 0x0802522a, ldr r2,[sp,#4] at 0x080253d8, adds r2,#16 at 0x08025518) and k = 0..15 (mvn.w r0,#15 at 0x080253e2, adds r0,#1 at 0x0802551c, bcc at 0x0802551e), so pairs 0..31 (0x0806e0d0..0x0806e1cf) are read; this region is pair 13 (k = 6, second pair of the iteration)
	.global UNREF_0806e138
UNREF_0806e138:
	.incbin "assets/rodata.bin", 0x27ee4, 16
@ UNREF_0806e148: 8 bytes = 2 32-bit floats 0.7409511, 0.671559 (x*x + y*y = 1.00000) = pair 15 of the 8-byte float-pair table that starts at 0x0806e0d0 (address built at 0x08025208/0x08025214 in compute_spectrum_bytes) | READ: vldr s1,[r2,#16] at 0x08025480 and vldr s3,[r2,#20] at 0x08025484 (pair 2k) and vldr s0,[r2,#24] at 0x080254d0 and vldr s2,[r2,#28] at 0x080254d4 (pair 2k+1) with r2 = 0x0806e0c0 + 16*k (movw/movt at 0x08025208/0x08025214, subs r0,#16 at 0x08025224, str r0,[sp,#4] at 0x0802522a, ldr r2,[sp,#4] at 0x080253d8, adds r2,#16 at 0x08025518) and k = 0..15 (mvn.w r0,#15 at 0x080253e2, adds r0,#1 at 0x0802551c, bcc at 0x0802551e), so pairs 0..31 (0x0806e0d0..0x0806e1cf) are read; this region is pair 15 (k = 7, second pair of the iteration)
	.global UNREF_0806e148
UNREF_0806e148:
	.incbin "assets/rodata.bin", 0x27ef4, 12
@ UNREF_0806e154: 892 bytes = 223 32-bit floats within [-1, 1], first 0.707107, 0.671559, 0.740951, 0.634393, 0.77301, 0.595699, 0.803208, 0.55557: the word at 0x0806e154 completes the pair (0.707107, 0.707107) of the float-pair table at 0x0806e0d0 and the following pairs are (0.671559, 0.740951), (0.634393, 0.77301), (0.595699, 0.803208) | READ: vldr s1,[r2,#16] at 0x08025480 and vldr s3,[r2,#20] at 0x08025484 (pair 2k) and vldr s0,[r2,#24] at 0x080254d0 and vldr s2,[r2,#28] at 0x080254d4 (pair 2k+1) with r2 = 0x0806e0c0 + 16*k (movw/movt at 0x08025208/0x08025214, subs r0,#16 at 0x08025224, str r0,[sp,#4] at 0x0802522a, ldr r2,[sp,#4] at 0x080253d8, adds r2,#16 at 0x08025518) and k = 0..15 (mvn.w r0,#15 at 0x080253e2, adds r0,#1 at 0x0802551c, bcc at 0x0802551e), so pairs 0..31 (0x0806e0d0..0x0806e1cf) are read; this region starts one word into pair 16 and its first 0x7c bytes (0x0806e154..0x0806e1cf) are pairs 16..31 of that loop; the loops of the function at 0x0802fb80 also address the table at 0x0806e0d0 (movw/movt at 0x0802fda2/0x0802fda8, add.w r6,r7,r1,lsl #3 at 0x0802fdac, vldr s0,[r6] at 0x0802fdb0, add.w r5,r7,r1,lsl #4 at 0x0802fdb4, vldr s0,[r5] at 0x0802fdbc, and r7 + 24*r1, 32*r1 at 0x0802fdc4, 0x0802fdd0)
	.global UNREF_0806e154
UNREF_0806e154:
	.incbin "assets/rodata.bin", 0x27f00, 892
	.global d_0806e4d0
d_0806e4d0:
	.incbin "assets/rodata.bin", 0x2827c, 24
@ UNREF_0806e4e8: 392 bytes = 98 32-bit words, as halfword pairs (0x0038, 0x02c0), (0x0040, 0x0100), (0x0048, 0x0300), (0x0050, 0x0140), (0x0058, 0x0340), (0x0060, 0x0180), (0x0068, 0x0380), (0x0070, 0x01c0), (0x0078, 0x03c0), (0x0080, 0x0200), (0x0088, 0x0208), (0x0090, 0x0300); the first halfword of these 12 pairs rises by 8 | READ: the loop at 0x08025538..0x080255f4 reads halfwords with ldrh.w r2,[ip,r0] at 0x0802553c and ldrh r3,[r1,#2], [r1,#4], [r1,#6] .. (r1 = ip + r0 at 0x08025538, ip = 0x0806e4d0 from movw/movt at 0x0802552e/0x08025534), r0 = 0, 16, .. 400 (adds r0,#16 at 0x080255ea, cmp.w r0,#416 / bne at 0x080255ec / 0x080255f4), so all bytes 0x0806e4d0..0x0806e66f are addressed; this region is offset 0x18..0x19f of that range
	.global UNREF_0806e4e8
UNREF_0806e4e8:
	.incbin "assets/rodata.bin", 0x28294, 392
	.global d_0806e670
d_0806e670:
	.incbin "assets/rodata.bin", 0x2841c, 8
@ UNREF_0806e678: 2044 bytes = 511 32-bit floats, first 0.02454123, 0.03680722, 0.04906767, 0.06132074, 0.07356456, 0.08579731 (rising), range [-1, 1], last value -0.0 | READ: add.w r1,r5,r0,lsl #2 at 0x08030954 with r5 = 0x0806e670 (movw at 0x08030940, movt at 0x0803094c) and r0 = the integer part of a float (vcvt at 0x08030932) forced to 0 unless r0 >> 9 equals 0 (cmp.w r4,r0,lsr #9 / movne r0,#0 at 0x08030944 / 0x08030948), so r0 = 0..511; vldr s2,[r1] at 0x0803096a and vldr s4,[r1,#4] at 0x0803096e read words r0 and r0+1 (element size 4), so the words 0x0806e670..0x0806ee77 are addressed and this region (elements 2..512) is read; the same table is used at 0x0801fb7a (r6 = 0x0806e670, movw at 0x0801fb60, movt at 0x0801fb7a)
	.global UNREF_0806e678
UNREF_0806e678:
	.incbin "assets/rodata.bin", 0x28424, 2044
	.global d_0806ee74
d_0806ee74:
	.incbin "assets/rodata.bin", 0x28c20, 20
@ UNREF_0806ee88: 44 bytes 28 30 29 22 1b 14 0d 06 07 0e 15 1c 23 2a 31 38 39 32 2b 24 1d 16 0f 17 1e 25 2c 33 3a 3b 34 2d 26 1f 27 2e 35 3c 3d 36 2f 37 3e 3f = entries 20..63 of a 64-byte table that starts at 0x0806ee74 with 00 01 08 10 09 02 03 0a 11 18 20 19 12 0b 04 05 0c 13 1a 21 (the 64 bytes contain each value 0..63 once) | READ: ldrb.w r7,[r7,r9] at 0x08037a3e with r7 = 0x0806ee74 (movw/movt at 0x08037a34/0x08037a38) and r9 compared against 63 at 0x08037990 (0..63); also ldrb r6,[sl,r2] at 0x08039c1c with sl = 0x0806ee74 (movw 0x08038fa8, movt 0x08038fb2) and r2 = 0, 16, 32, 48 (adds r2,#16 at 0x08039c68, cmp r2,#64 at 0x08039c78, bne at 0x08039d22); this region is index 20..63
	.global UNREF_0806ee88
UNREF_0806ee88:
	.incbin "assets/rodata.bin", 0x28c34, 44
@ DATA_0806eeb4: 2 bytes 00 20 = halfword 0x2000, element 0 of the halfword table of 64 entries at 0x0806eeb4..0x0806ef33 (rows of 8; row 0 = 0x2000, 0x2c62, 0x29cf, 0x25a0, 0x2000, 0x1924, 0x1151, 0x08d4; row 1 = 0x2c62, 0x3d90, 0x39fe, 0x3431, 0x2c62, 0x22df, 0x1805, 0x0c3e) | ldrh.w r4,[r11,r6,lsl #0x1] at 0x08039c24 | parse_jpeg_header: parses the header of an image stream (0xffd8 start, marker segments, component descriptors)
	.global DATA_0806eeb4
DATA_0806eeb4:
	.global d_0806eeb4
d_0806eeb4:
	.incbin "assets/rodata.bin", 0x28c60, 12
@ UNREF_0806eec0: 4 bytes 51 11 d4 08 = halfwords 0x1151, 0x08d4 = elements 6 and 7 of the halfword table of 64 entries at 0x0806eeb4..0x0806ef33 (rows of 8; row 0 = 0x2000, 0x2c62, 0x29cf, 0x25a0, 0x2000, 0x1924, 0x1151, 0x08d4; row 1 = 0x2c62, 0x3d90, 0x39fe, 0x3431, 0x2c62, 0x22df, 0x1805, 0x0c3e) | READ: ldrh.w r4,[fp,r6,lsl #1] at 0x08039c24 (and 0x08039c3a, 0x08039c48 .. 0x08039d16) with fp = 0x0806eeb4 (movw 0x08038fac, movt 0x08038fb6) and r6 = a byte of the 64-byte table at 0x0806ee74 (ldrb.w r6,[sl,r2] at 0x08039c1c; each value 0..63 occurs once in that table), r2 = 0, 16, 32, 48 (adds r2,#16 at 0x08039c68, cmp r2,#64 at 0x08039c78, bne at 0x08039d22; each pass reads 16 consecutive bytes of the 64-byte table), so all 64 halfwords 0x0806eeb4..0x0806ef33 are read; this region is elements 6 and 7
	.global UNREF_0806eec0
UNREF_0806eec0:
	.incbin "assets/rodata.bin", 0x28c6c, 14
@ UNREF_0806eece: 6 bytes df 22 05 18 3e 0c = halfwords 0x22df, 0x1805, 0x0c3e = elements 13..15 of the halfword table of 64 entries at 0x0806eeb4..0x0806ef33 (rows of 8; row 0 = 0x2000, 0x2c62, 0x29cf, 0x25a0, 0x2000, 0x1924, 0x1151, 0x08d4; row 1 = 0x2c62, 0x3d90, 0x39fe, 0x3431, 0x2c62, 0x22df, 0x1805, 0x0c3e) | READ: ldrh.w r4,[fp,r6,lsl #1] at 0x08039c24 (and 0x08039c3a, 0x08039c48 .. 0x08039d16) with fp = 0x0806eeb4 (movw 0x08038fac, movt 0x08038fb6) and r6 = a byte of the 64-byte table at 0x0806ee74 (ldrb.w r6,[sl,r2] at 0x08039c1c; each value 0..63 occurs once in that table), r2 = 0, 16, 32, 48 (adds r2,#16 at 0x08039c68, cmp r2,#64 at 0x08039c78, bne at 0x08039d22; each pass reads 16 consecutive bytes of the 64-byte table), so all 64 halfwords 0x0806eeb4..0x0806ef33 are read; this region is elements 13..15
	.global UNREF_0806eece
UNREF_0806eece:
	.incbin "assets/rodata.bin", 0x28c7a, 14
@ UNREF_0806eedc: 8 bytes cf 29 d9 20 a0 16 89 0b = halfwords 0x29cf, 0x20d9, 0x16a0, 0x0b89 = elements 20..23 of the halfword table of 64 entries at 0x0806eeb4..0x0806ef33 (rows of 8; row 0 = 0x2000, 0x2c62, 0x29cf, 0x25a0, 0x2000, 0x1924, 0x1151, 0x08d4; row 1 = 0x2c62, 0x3d90, 0x39fe, 0x3431, 0x2c62, 0x22df, 0x1805, 0x0c3e) | READ: ldrh.w r4,[fp,r6,lsl #1] at 0x08039c24 (and 0x08039c3a, 0x08039c48 .. 0x08039d16) with fp = 0x0806eeb4 (movw 0x08038fac, movt 0x08038fb6) and r6 = a byte of the 64-byte table at 0x0806ee74 (ldrb.w r6,[sl,r2] at 0x08039c1c; each value 0..63 occurs once in that table), r2 = 0, 16, 32, 48 (adds r2,#16 at 0x08039c68, cmp r2,#64 at 0x08039c78, bne at 0x08039d22; each pass reads 16 consecutive bytes of the 64-byte table), so all 64 halfwords 0x0806eeb4..0x0806ef33 are read; this region is elements 20..23
	.global UNREF_0806eedc
UNREF_0806eedc:
	.incbin "assets/rodata.bin", 0x28c88, 14
@ UNREF_0806eeea: 10 bytes 3e 2c a0 25 90 1d 5d 14 61 0a = halfwords 0x2c3e, 0x25a0, 0x1d90, 0x145d, 0x0a61 = elements 27..31 of the halfword table of 64 entries at 0x0806eeb4..0x0806ef33 (rows of 8; row 0 = 0x2000, 0x2c62, 0x29cf, 0x25a0, 0x2000, 0x1924, 0x1151, 0x08d4; row 1 = 0x2c62, 0x3d90, 0x39fe, 0x3431, 0x2c62, 0x22df, 0x1805, 0x0c3e) | READ: ldrh.w r4,[fp,r6,lsl #1] at 0x08039c24 (and 0x08039c3a, 0x08039c48 .. 0x08039d16) with fp = 0x0806eeb4 (movw 0x08038fac, movt 0x08038fb6) and r6 = a byte of the 64-byte table at 0x0806ee74 (ldrb.w r6,[sl,r2] at 0x08039c1c; each value 0..63 occurs once in that table), r2 = 0, 16, 32, 48 (adds r2,#16 at 0x08039c68, cmp r2,#64 at 0x08039c78, bne at 0x08039d22; each pass reads 16 consecutive bytes of the 64-byte table), so all 64 halfwords 0x0806eeb4..0x0806ef33 are read; this region is elements 27..31
	.global UNREF_0806eeea
UNREF_0806eeea:
	.incbin "assets/rodata.bin", 0x28c96, 12
@ UNREF_0806eef6: 62 bytes = 31 halfwords 0x2c62, 0x29cf, 0x25a0, 0x2000, 0x1924, 0x1151, 0x08d4, 0x1924 ... = elements 33..63 of the halfword table of 64 entries at 0x0806eeb4..0x0806ef33 (rows of 8; row 0 = 0x2000, 0x2c62, 0x29cf, 0x25a0, 0x2000, 0x1924, 0x1151, 0x08d4; row 1 = 0x2c62, 0x3d90, 0x39fe, 0x3431, 0x2c62, 0x22df, 0x1805, 0x0c3e) | READ: ldrh.w r4,[fp,r6,lsl #1] at 0x08039c24 (and 0x08039c3a, 0x08039c48 .. 0x08039d16) with fp = 0x0806eeb4 (movw 0x08038fac, movt 0x08038fb6) and r6 = a byte of the 64-byte table at 0x0806ee74 (ldrb.w r6,[sl,r2] at 0x08039c1c; each value 0..63 occurs once in that table), r2 = 0, 16, 32, 48 (adds r2,#16 at 0x08039c68, cmp r2,#64 at 0x08039c78, bne at 0x08039d22; each pass reads 16 consecutive bytes of the 64-byte table), so all 64 halfwords 0x0806eeb4..0x0806ef33 are read; this region is elements 33..63
	.global UNREF_0806eef6
UNREF_0806eef6:
	.incbin "assets/rodata.bin", 0x28ca2, 62
@ DATA_0806ef34: 71892 bytes; the first 1024 bytes are a lookup table: byte i = i for i 0..255 (0x0806ef34..0x0806f033), 0xff for i 256..511, 0x00 for i 512..1023; from 0x0806f334 the bytes are no ramp (first bytes ac ae ae ae ac 35 ce 33 33 ce ec cc cc 55 55 03) | ldrb r6,[r2,r6] at 0x08037e0a with r2 = 0x0806ef34 (movw #0xef34 at 0x08037de4, movt at 0x08037dea) and the index masked to 10 bits (bfc r6,#10,#22 at 0x08037e02), so only the first 1024 bytes are addressed by it | decode_scan_data_to_rgb565: decodes the scan data of an image stream (Huffman bit reader, dequantise, rows via callback)
	.global DATA_0806ef34
DATA_0806ef34:
	.global d_0806ef34
d_0806ef34:
	.incbin "assets/rodata.bin", 0x28ce0, 1024

@ ============================================================================
@ The 8 fonts (own data, DATA_DESIGN.md step 4). The binary pieces come from tools/make_fonts.py of
@ the project folder: the 7 text fonts are DejaVu Sans Condensed 2.37 (licence
@ assets/fonts/LICENSE-DejaVu.txt) rendered at 4 bits per pixel, 99 glyphs each (0x20..0x7F,
@ U+03A9 Omega, U+2103 degree Celsius, U+2109 degree Fahrenheit); the 63 px font is an own 7-segment
@ drawing at 1 bit per pixel with the 23 keys 0x20 - . 0-9 A C E L O P T U r s.
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
@ 99 glyphs. Font object loaded directly by draw_arc_gauge (src/waveform_84.s).
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
	.hword	0x2109			@ +0x04: high bound, the highest key U+2109
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_0806fcec		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	99			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_0806fcec: key array of the 12 px font (descriptor + 0x14)
	.global d_0806fcec
d_0806fcec:
	.incbin "assets/fonts/f12_keys.bin"
.Lfont12_end:
	.if (d_0806f9d8 - d_0806f334) & 3
	.error "12 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_0806fcd8 - d_0806f9d8) != 8 * 99
	.error "12 px font: the record table must hold 99 records (descriptor glyph count)"
	.endif
	.if (.Lfont12_end - d_0806fcec) != ((2 * 99 + 3) & ~3)
	.error "12 px font: the key array must hold 99 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 15 px font (font object 0x200010B4, context 0x200010C8): DejaVu Sans Condensed size 10, 4 bpp,
@ 99 glyphs. Font object loaded directly by the waveform display (src/parts/draw_waveform_display_p6.inc).
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
	.hword	0x2109			@ +0x04: high bound, the highest key U+2109
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_08077b24		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	99			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_08077b24: key array of the 15 px font (descriptor + 0x14)
	.global d_08077b24
d_08077b24:
	.incbin "assets/fonts/f15_keys.bin"
.Lfont15_end:
	.if (d_08076938 - d_0806fdae) & 3
	.error "15 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_08077b10 - d_08076938) != 8 * 99
	.error "15 px font: the record table must hold 99 records (descriptor glyph count)"
	.endif
	.if (.Lfont15_end - d_08077b24) != ((2 * 99 + 3) & ~3)
	.error "15 px font: the key array must hold 99 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 16 px font (font object 0x200010E4, context 0x200010F8): DejaVu Sans Condensed size 12, 4 bpp,
@ 99 glyphs. Font object loaded directly by the waveform display, fn_080114c4, draw_image_two_texts_and_s_value,
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
	.hword	0x2109			@ +0x04: high bound, the highest key U+2109
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_080819bc		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	99			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_080819bc: key array of the 16 px font (descriptor + 0x14)
	.global d_080819bc
d_080819bc:
	.incbin "assets/fonts/f16_keys.bin"
.Lfont16_end:
	.if (d_080807f0 - d_08077f9c) & 3
	.error "16 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_080819a8 - d_080807f0) != 8 * 99
	.error "16 px font: the record table must hold 99 records (descriptor glyph count)"
	.endif
	.if (.Lfont16_end - d_080819bc) != ((2 * 99 + 3) & ~3)
	.error "16 px font: the key array must hold 99 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 18 px font (font object 0x20001114, context 0x20001128): DejaVu Sans Condensed size 13, 4 bpp,
@ 99 glyphs. The most loaded font object (direct loads): menus, lists, settings pages, the text column highlight.
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
	.hword	0x2109			@ +0x04: high bound, the highest key U+2109
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_0808c3e0		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	99			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_0808c3e0: key array of the 18 px font (descriptor + 0x14)
	.global d_0808c3e0
d_0808c3e0:
	.incbin "assets/fonts/f18_keys.bin"
.Lfont18_end:
	.if (d_0808b214 - d_08081e2c) & 3
	.error "18 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_0808c3cc - d_0808b214) != 8 * 99
	.error "18 px font: the record table must hold 99 records (descriptor glyph count)"
	.endif
	.if (.Lfont18_end - d_0808c3e0) != ((2 * 99 + 3) & ~3)
	.error "18 px font: the key array must hold 99 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 20 px font (font object 0x20001144, context 0x20001158): DejaVu Sans Condensed size 15, 4 bpp,
@ 99 glyphs. Font object loaded directly by menu and list pages, draw_value_panel, message boxes, the waveform display.
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
	.hword	0x2109			@ +0x04: high bound, the highest key U+2109
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_0809a1a8		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	99			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_0809a1a8: key array of the 20 px font (descriptor + 0x14)
	.global d_0809a1a8
d_0809a1a8:
	.incbin "assets/fonts/f20_keys.bin"
.Lfont20_end:
	.if (d_08098fdc - d_0808c850) & 3
	.error "20 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_0809a194 - d_08098fdc) != 8 * 99
	.error "20 px font: the record table must hold 99 records (descriptor glyph count)"
	.endif
	.if (.Lfont20_end - d_0809a1a8) != ((2 * 99 + 3) & ~3)
	.error "20 px font: the key array must hold 99 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 25 px font (font object 0x20001174, context 0x20001188): DejaVu Sans Condensed size 19, 4 bpp
@ (V1.2.0's 25 px font was 1 bpp; context word +0x10 at 0x20001198 is 0x08010000 now, src/ram_init.s),
@ 99 glyphs. Font object loaded directly by the waveform display, fn_08010014, fn_080114c4, fn_08012d2c,
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
	.hword	0x2109			@ +0x04: high bound, the highest key U+2109
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_080a1644		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	99			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_080a1644: key array of the 25 px font (descriptor + 0x14)
	.global d_080a1644
d_080a1644:
	.incbin "assets/fonts/f25_keys.bin"
.Lfont25_end:
	.if (d_080a0468 - d_0809a618) & 3
	.error "25 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_080a1630 - d_080a0468) != 8 * 99
	.error "25 px font: the record table must hold 99 records (descriptor glyph count)"
	.endif
	.if (.Lfont25_end - d_080a1644) != ((2 * 99 + 3) & ~3)
	.error "25 px font: the key array must hold 99 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 28 px font (font object 0x200011A4, context 0x200011B8): DejaVu Sans Condensed size 21, 4 bpp,
@ 99 glyphs. Font object loaded directly by fn_08010a94, draw_header_image_120, draw_arc_gauge.
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
	.hword	0x2109			@ +0x04: high bound, the highest key U+2109
	.hword	0x0000			@ +0x06: 0 (not read by the lookups)
	.word	d_080ba1cc		@ +0x08: key array
	.word	0x00000000		@ +0x0C: 0 (not read by the lookups)
	.hword	99			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_080ba1cc: key array of the 28 px font (descriptor + 0x14)
	.global d_080ba1cc
d_080ba1cc:
	.incbin "assets/fonts/f28_keys.bin"
.Lfont28_end:
	.if (d_080b9000 - d_080a1ab8) & 3
	.error "28 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_080ba1b8 - d_080b9000) != 8 * 99
	.error "28 px font: the record table must hold 99 records (descriptor glyph count)"
	.endif
	.if (.Lfont28_end - d_080ba1cc) != ((2 * 99 + 3) & ~3)
	.error "28 px font: the key array must hold 99 keys (descriptor glyph count)"
	.endif

@ ----------------------------------------------------------------------------
@ 63 px font (font object 0x200011D4, context 0x200011E8): own 7-segment digits, 1 bpp (context
@ word +0x10 0x02010000), 23 glyphs: 0x20 - . 0-9 A C E L O P T U r s (V1.2.0's key set).
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
	.hword	23			@ +0x10: glyph count
	.hword	0x0003			@ +0x12: 3 (not read by the lookups)
@ d_080bb3bc: key array of the 63 px font (descriptor + 0x14)
	.global d_080bb3bc
d_080bb3bc:
	.incbin "assets/fonts/f63_keys.bin"
.Lfont63_end:
	.if (d_080bb2f0 - d_080ba63c) & 3
	.error "63 px font: the bitmaps must be a multiple of 4 bytes (record table word aligned)"
	.endif
	.if (d_080bb3a8 - d_080bb2f0) != 8 * 23
	.error "63 px font: the record table must hold 23 records (descriptor glyph count)"
	.endif
	.if (.Lfont63_end - d_080bb3bc) != ((2 * 23 + 3) & ~3)
	.error "63 px font: the key array must hold 23 keys (descriptor glyph count)"
	.endif

	.global d_080bb3ec
d_080bb3ec:
	.incbin "assets/rodata.bin", 0x75198, 1
@ UNREF_080bb3ed: 15 bytes 00 00 00 00 00 00 00 01 02 03 04 06 07 08 09 = bytes 1..15 of the 16-byte table at 0x080bb3ec (00 00 00 00 00 00 00 00 01 02 03 04 06 07 08 09) | ldrb r3,[r4,r3] at 0x080314c8 with r4 = 0x080bb3ec (movw #0xb3ec at 0x080314bc, movt at 0x080314c4) and r3 = (x>>4)&0xf (ubfx at 0x080314c0) in compute_clock_frequencies, the byte is the shift count of lsrs r2,r3 at 0x080314ce (x = word read from 0x40021004)
	.global UNREF_080bb3ed
UNREF_080bb3ed:
	.incbin "assets/rodata.bin", 0x75199, 15
	.global d_080bb3fc
d_080bb3fc:
	.incbin "assets/rodata.bin", 0x751a8, 1
@ UNREF_080bb3fd: 6 bytes 0c 17 0b 0a 12 11 | READ: ldrb r0,[r2,r0] at 0x0800b2f8 with r2 = 0x080bb3fc (movw at 0x0800b2e6, movt at 0x0800b2f4) and r0 = uxtb r1 at 0x0800b2f2 where r1 = [0x2d] - 1 or 7 (subs at 0x0800b2ea, moveq at 0x0800b2f0) and, in the second function, ldrb r0,[r2,r0] at 0x0800b8d0 with r2 = 0x080bb3fc (movw 0x0800b8c0, movt 0x0800b8cc) and r1 = r0 + 1 when r0 < 7 else 0 (cmp r0,#7 / addcc at 0x0800b8c4 / 0x0800b8c8), so the index is 0..7 at 0x0800b8d0 and this region is index 1..6
	.global UNREF_080bb3fd
UNREF_080bb3fd:
	.incbin "assets/rodata.bin", 0x751a9, 7
@ DATA_080bb404: 8 bytes 00 00 00 00 01 02 03 04 | ldrb r3,[r4,r3] at 0x080314dc with r3 = (x>>8)&7 (ubfx at 0x080314d8) and at 0x080314ea with r3 = (x>>11)&7 (ubfx at 0x080314e6), r4 = 0x080bb404 (movw #0xb404 at 0x080314ca, movt at 0x080314d4); the byte is the shift count of lsr.w r3,r2,r3 at 0x080314de and lsrs r2,r3 at 0x080314ee | compute_clock_frequencies: reads 0x40021004 and derives a base frequency and four shifted/divided values into a 5-dword result
	.global DATA_080bb404
DATA_080bb404:
	.global d_080bb404
d_080bb404:
	.incbin "assets/rodata.bin", 0x751b0, 8
@ DATA_080bb40c: 2 bytes a0 fe = halfword 0xfea0, element 0 of the halfword array 0x080bb40c: 0xfea0, 0x055f, 0x055f, 0xfea0 (the next halfwords are DATA_080bb40e) | ldrh.w with index*4 (lsl #0x2) at 0x08028b6c, 0x0801e7c4, 0x08014984, 0x08014554, 0x08014a34, 0x08014a08 | draw_channel_offset_markers_08028b40: calls fill_triangle (0x08020af8) at 0x08028b80 and 0x08028baa; the colour argument (stack slot [sp+8], str r7,[sp,#8] at 0x08028b7e / 0x08028ba8) is the halfword at 0x080bb40c + byte(0x2000105b)*4 for the first call and at +2 for the second; draw_bottom_strip and draw_panels_by_selector_20001062 also load from it
	.global DATA_080bb40c
DATA_080bb40c:
	.global d_080bb40c
d_080bb40c:
	.incbin "assets/rodata.bin", 0x751b8, 2
@ DATA_080bb40e: 6 bytes 5f 05 5f 05 a0 fe = halfwords 0x055f, 0x055f, 0xfea0 (elements 1..3 of the halfword array at 0x080bb40c) | ldrh r7,[r3,#0x2] at 0x08028b98, ldrh r1,[r1,#0x2] at 0x0801e7fc, ldrh r7,[r0,#0x2] at 0x0801458e and 0x080145bc, 0x080145ea, 0x08014646 | draw_channel_offset_markers_08028b40, draw_bottom_strip, draw_panels_by_selector_20001062
	.global DATA_080bb40e
DATA_080bb40e:
	.incbin "assets/rodata.bin", 0x751ba, 8
@ (the last 2 of these 8 bytes, 20 00 at 0x080bb414, were the text " " of draw_arc_gauge,
@ now t_080bb414 in src/text.s; the bytes are kept here unchanged)
@ (V1.2.0 had its text area, every language, at 0x080bb416..0x080be05b here; the English texts
@ are in src/text.s now.) d_080be05c and the data after it are read as halfwords and words: the
@ next line pads with zero bytes to a multiple of 4 from the section start (the section is
@ 4-aligned, see the .p2align at its start), as the vendor address 0x080be05c was.
	.p2align 2
	.global d_080be05c
d_080be05c:
	.incbin "assets/rodata.bin", 0x77e08, 4
@ UNREF_080be060: 184 bytes = 92 halfwords 0x2c63, 0x1e00, 0x0196, 0x1ea0, 0x015a, 0x1f00, 0x0608, 0x1f10, 0x0606, 0x1f20, 0x0608, 0x1f30, 0x0608, 0x1f40, 0x0606, 0x1f51, 0x0007, 0x1f59, 0x1f52, 0x1f5b, 0x1f54, ... | READ: the group walker in find_directory_entry_by_name starts at r7 = 0x080be05c when the 16-bit key is >= 0x1000 (movw/movt at 0x08031946/0x08031956, cmp.w r2,#4096 / movcc r7,r1 at 0x0803195e / 0x08031962) and at 0x080be118 otherwise (movw 0x0803194e, movt 0x0803195a); each group is a start halfword followed by a halfword with the count in the low byte and flags in the high byte; ldrh r3,[r7,#0] at 0x08031966 and ldrh r1,[r7,#2] at 0x08031976 read the header, groups with flags 0 are followed by count halfwords that the found path reads (sub r1,r2,sl at 0x08031a10 and ldrh.w r1,[r9,r1,lsl #1] at 0x08031a14), r7 advances by 2*count at 0x0803199e, and the walk continues group by group until start-1 >= key (bcs at 0x08031974); the first group at 0x080be05c has start 0x1d7d and count 1, so the halfword 0x2c63 at 0x080be060 is its entry (read when the key is 0x1d7d) and the groups that follow (headers and entries) lie in this region
	.global UNREF_080be060
UNREF_080be060:
	.incbin "assets/rodata.bin", 0x77e0c, 184
	.global d_080be118
d_080be118:
	.incbin "assets/rodata.bin", 0x77ec4, 8
@ DATA_080be120: 46 bytes = 23 halfwords 0x00f8, 0x0307, 0x00ff, 0x0001, 0x0178, 0x0100, 0x0130, 0x0132, 0x0106, 0x0139, 0x0110, 0x014a, 0x012e, 0x0179, 0x0106, 0x0180, 0x004d, 0x0243, 0x0181, 0x0182, 0x0182, 0x0184, 0x0184 | Read through no fixed base: the region lies inside the table that starts at 0x080be118 (used when the character code is below 0x1000, otherwise the table at 0x080be05c is used: cmp #0x1000 and conditional move at 0x0803293c..0x08032946, 0x080329e0..0x080329ea, 0x08032ac0..0x08032aca, 0x08032b64..0x08032b6e, 0x08032c42..0x08032c4c, 0x08032c96..0x08032ca0) and is walked entry by entry: an entry is a start halfword and an info halfword (high byte = type, low byte = count), a type 0 entry is followed by count data halfwords, any other type by none, and the walk ends at a start halfword 0 (0x080be308) | Entries in this region: 0x080be120 {start 0x00f8, type 3, count 7}; 0x080be124 {0x00ff, type 0, count 1} with its data halfword at 0x080be128 = 0x0178; 0x080be12a {0x0100, type 1, count 0x30}; 0x080be12e {0x0132, type 1, count 6}; 0x080be132 {0x0139, type 1, count 0x10}; 0x080be136 {0x014a, type 1, count 0x2e}; 0x080be13a {0x0179, type 1, count 6}; 0x080be13e {0x0180, type 0, count 0x4d} whose data starts at 0x080be142: its first six halfwords 0x080be142..0x080be14c (0x0243, 0x0181, 0x0182, 0x0182, 0x0184, 0x0184) are the last six halfwords of this region, the other 71 follow from 0x080be14e to 0x080be1da | The six ldrh.w are all [base + index*2] and run only when the entry type is 0 (tbb case 0): base = address of the current entry + 4 (its first data halfword), index = character code - entry start halfword, so the address read is entry+4 + 2*(code - start): 0x08032992 base r7 (r3+4 at 0x08032956), index r1 = lr - r5 (0x0803298e; lr = uxth ip, r5 = entry start), result in ip; 0x08032a36 base r7 (0x080329fa), index r1 = r9 - r5 (0x08032a32; r9 loaded at 0x080329d4), result in r9; 0x08032b16 base r7 (0x08032ada), index r1 = lr - r5 (0x08032b12), result in ip; 0x08032b
	.global DATA_080be120
DATA_080be120:
	.incbin "assets/rodata.bin", 0x77ecc, 48
@ UNREF_080be150: 444 bytes = 222 halfwords 0x0187, 0x0187, 0x0189, 0x018a, 0x018b, 0x018b, 0x018d, 0x018e, 0x018f, 0x0190, 0x0191, 0x0191, 0x0193, 0x0194, 0x01f6, 0x0196, ... (not monotonic: first decrease at element 14, 0x01f6 then 0x0196; the last element 221 = 0x8c73 is at 0x080be30a); the region starts at 0x080be150, 2 bytes after the end of DATA_080be120 (0x080be14e) | READ: the group walker in find_directory_entry_by_name starts at r7 = 0x080be05c when the 16-bit key is >= 0x1000 (movw/movt at 0x08031946/0x08031956, cmp.w r2,#4096 / movcc r7,r1 at 0x0803195e / 0x08031962) and at 0x080be118 otherwise (movw 0x0803194e, movt 0x0803195a); each group is a start halfword followed by a halfword with the count in the low byte and flags in the high byte; ldrh r3,[r7,#0] at 0x08031966 and ldrh r1,[r7,#2] at 0x08031976 read the header, groups with flags 0 are followed by count halfwords that the found path reads (sub r1,r2,sl at 0x08031a10 and ldrh.w r1,[r9,r1,lsl #1] at 0x08031a14), r7 advances by 2*count at 0x0803199e, and the walk continues group by group until start-1 >= key (bcs at 0x08031974); the group chain that starts at 0x080be118 runs through this region up to the group at 0x080be304; the last halfword of this region (element 221 = 0x8c73 at 0x080be30a) is also read by ldrh.w r1,[r7,r6,lsl #1] at 0x08015a62 with r7 = 0x080be30a (movw at 0x08015a52, movt at 0x08015a5a) and r6 = 0, 1 or 3 (movs r6,#1 at 0x08015a34, moveq r6,#3 at 0x08015a42, movne r6,r7 at 0x08015a4c with r7 = 0, 1 or 3 from 0x08015a20..0x08015a30)
	.global UNREF_080be150
UNREF_080be150:
	.incbin "assets/rodata.bin", 0x77efc, 442
	.global d_080be30a
d_080be30a:
	.incbin "assets/rodata.bin", 0x780b6, 4
@ UNREF_080be30e: 2 bytes 5f 05 = halfword 0x055f | no reference found
	.global UNREF_080be30e
UNREF_080be30e:
	.incbin "assets/rodata.bin", 0x780ba, 4
@ UNREF_080be312: 2 bytes 00 00 | no reference found
	.global UNREF_080be312
UNREF_080be312:
	.incbin "assets/rodata.bin", 0x780be, 2
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
	.incbin "assets/rodata.bin", 0x780d4, 8              @ destination 0x20001240, length 0x00035d50
.Lsw_080be330:
	.word zero_fill_words_addr                         @ 0x080be330 = 0x0800721c
@ d_080be334: end of the scatter-load region table (the word here, 0x0000001c, is not part of it)
	.global d_080be334
d_080be334:
	.incbin "assets/rodata.bin", 0x780e0, 4
	.global d_080be338
d_080be338:
	.incbin "assets/rodata.bin", 0x780e4, 2
@ UNREF_080be33a: 6 bytes 00 00 f8 ff ff ff = halfword 0 then word 0xfffffff8 (-8) | no reference found
	.global UNREF_080be33a
UNREF_080be33a:
	.incbin "assets/rodata.bin", 0x780e6, 6
@ DATA_080be340: 20 bytes = 5 words 0x0c, 0x0e, 0x0f, 0x2e, 0x110, followed by 0x43 and 0xfffffff8 | add r0,pc at 0x08044ef6 in fn_08044ed8 builds this address | fn_08044ed8: returns the address held in the constant when the string is null, empty or "C"
	.global DATA_080be340
DATA_080be340:
	.global d_080be340
d_080be340:
	.incbin "assets/rodata.bin", 0x780ec, 20
	.global d_080be354
d_080be354:
	.incbin "assets/rodata.bin", 0x78100, 2
@ UNREF_080be356: 6 bytes 00 00 f8 ff ff ff = halfword 0 then word 0xfffffff8 (-8) | no reference found
	.global UNREF_080be356
UNREF_080be356:
	.incbin "assets/rodata.bin", 0x78102, 6
@ DATA_080be35c: 104 bytes: 00 x1, 40 x9, 41 x5, 40 x18, 05 x1, 02 x15, 20 x10, 02 x7, 90 x6, 10 x20, 02 x6, 88 x6 | add r0,pc at 0x08044f22 in fn_08044f04 builds this address | fn_08044f04: returns the address held in the constant when the string is null, empty or "C"
	.global DATA_080be35c
DATA_080be35c:
	.global d_080be35c
d_080be35c:
	.incbin "assets/rodata.bin", 0x78108, 124
@ UNREF_080be3d8: 168 bytes: 02 x4, 40 x1, 00 x163 | READ: fn_08008534 reads a 256-entry byte table whose address is stored as 0x080be35d at [0x20001264]: the routine at 0x080072c8 calls 0x08044f04 (it returns 0x080be35c: ldr r0,[pc,#8] / add r0,pc at 0x08044f20 / 0x08044f22), adds 1 (adds r0,r0,#1 at 0x080072dc) and stores it with str r0,[r4,#4] at 0x080072de (r4 = 0x20001260 returned by 0x08008300); fn_08008534 loads it (bl 0x08008620 at 0x0800853e, ldr r3,[r0,#0] at 0x08008542) and executes ldrb r0,[r3,r4] at 0x08008550 for r4 <= 255 (cmp r4,#255 / bhi at 0x0800854c / 0x0800854e) and ldrb.w r0,[r3,#257] at 0x08008544, so 0x080be35d..0x080be45c and the byte 0x080be45e are read; this region starts at index 123 (0x080be3d8 = 0x080be35d + 123), so its bytes 0x080be3d8..0x080be45c and 0x080be45e are read; the word at [r3,#263] (ldr.w at 0x0800855c) is read only when the byte at [r3,#257] equals 1 and that byte is 0
	.global UNREF_080be3d8
UNREF_080be3d8:
	.incbin "assets/rodata.bin", 0x78184, 168
@ The 512 bytes 0x080be480..0x080be67f of V1.2.0 (the packed initial RAM image, unpacked by
@ unpack_token_stream) are not part of this file: the image is src/ram_init.s, copied by copy_words.
	.global rodata_end
rodata_end:
