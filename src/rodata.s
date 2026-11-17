@ rodata.s - fixed data 0x08046254..0x080BE67F: format tables, number constants, function pointer
@ tables, text in every language, fonts and glyph bitmaps, pictures, the scatter-load region table
@ (0x080BE314) and the packed initial RAM image (0x080BE480, unpacked to 0x20000000 at reset).
@ The bytes come from assets/rodata.bin; words that hold code addresses are written as symbols.
@ Labels d_<address> are the addresses the code refers to.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb
	.section .rodata.fixed,"a",%progbits
	.global rodata_start
rodata_start:
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
	.incbin "assets/rodata.bin", 0x6, 34
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
	.incbin "assets/rodata.bin", 0x1c4, 88
	.global d_08046470
d_08046470:
	.incbin "assets/rodata.bin", 0x21c, 16
	.global d_08046480
d_08046480:
	.incbin "assets/rodata.bin", 0x22c, 8
	.global d_08046488
d_08046488:
	.incbin "assets/rodata.bin", 0x234, 8
@ DATA_08046490: 60 bytes = 5 entries of 12 bytes (stride 0xc), each three 32-bit words: (0x00004002, 0xa0000000, 0x0), (0x00004005, 0xc8000000, 0x0), (0x0000400c, 0x9c400000, 0x0), (0x00004019, 0xbebc2000, 0x0), (0x00004034, 0x8e1bc9bf, 0x04000000) | with word0 as exponent (bias 0x3fff) and words 1,2 as the 64-bit mantissa the entries equal 10, 100, 10000, 1e8, 1e16 | add.w r1,r10,r1,lsl #2 at 0x080084ac | fn_08008448: combines 12-byte table entries with 0804356a and divides with 08043540 when n is negative
	.global DATA_08046490
DATA_08046490:
	.incbin "assets/rodata.bin", 0x23c, 60
@ DATA_080464cc: 4 bytes b5 40 00 00 = word 0x000040b5, word 0 (exponent word) of the 16-byte entry at 0x080464cc | ldm.w r0,{r1,r2,r3} at 0x080084d4 loads words 0..2 of the entry | entry words (0x000040b5, 0xd0cf4b50, 0xcfe20766, 0x00000001) equal 1e55 with the same reading as the table at 0x08046490 | fn_08008448: combines 12-byte table entries with 0804356a
	.global DATA_080464cc
DATA_080464cc:
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
	.incbin "assets/rodata.bin", 0x284, 80
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
	.global d_0804657a
	.set d_0804657a, .Lsw_08046578 + 2
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
	.global d_0804bcec
d_0804bcec:
	.incbin "assets/rodata.bin", 0x5a98, 1
@ DATA_0804bced: 129 bytes: 128 entries 80 9a 45 41 8e 41 8f 80 45 45 45 49 49 49 8e 8f 90 92 92 4f 99 4f 55 55 59 99 9a 9b 9c 9d 9e 9f 41 49 4f 55 a5 a5 a6 a7 a8 a9 aa ab ac ad ae af ... through ff (byte 127 = 0xff), plus a trailing 00 | ldrb r6,[r1,r0] at 0x08036a4a with r1 = 0x0804bced (movw/movt at 0x08036a3e/0x08036a46) and r0 = result & 0x7f (and.w at 0x08036a42), taken when bit 7 of the result of bl 0x08035908 is set (bpl at 0x08036a3c) | path_resolve: walks a path string against a directory object
	.global DATA_0804bced
DATA_0804bced:
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
	.global d_0804bf28
d_0804bf28:
	.incbin "assets/rodata.bin", 0x5cd4, 96
	.global d_0804bf88
d_0804bf88:
	.incbin "assets/rodata.bin", 0x5d34, 12
@ UNREF_0804bf94: 20 bytes = 5 words 0x00000000, 0x080bbcc5, 0x080bbcf2, 0x080bbca4, 0x080bbcf3 (text 'nS', 'uS', 'mS', 'S'): the last word of row 0 and the whole row 1 of the 16-byte row table at 0x0804bf88 (row 0 words 0x080bcee6 'Hz', 0x080bcee1 'KHz', 0x080bcee5 'MHz', 0) | the table is read by ldr.w r7,[r0,r3,lsl #2] at 0x0801bd7e in draw_waveform_display
	.global UNREF_0804bf94
UNREF_0804bf94:
	.incbin "assets/rodata.bin", 0x5d40, 20
@ DATA_0804bfa8: 16 bytes = 4 words 0x080bbd2d, 0x080bbd2e, 0, 0 (text 'mV', 'V') = row 2 of the 16-byte row table at 0x0804bf88 | ldr.w r7,[r0,r3,lsl #0x2] at 0x0801bd7e in draw_waveform_display (r0 = 0x0804bf88 + 16*byte, movw/movt at 0x0801bd6a/0x0801bd72, lsl #4 at 0x0801bd76) | draw_waveform_display: draw_waveform_display
	.global DATA_0804bfa8
DATA_0804bfa8:
	.incbin "assets/rodata.bin", 0x5d54, 16
@ DATA_0804bfb8: 8 bytes = 4 halfwords 0x0190, 0x0320, 0x07d0, 0x0000 (400, 800, 2000, 0) | ldrh.w with index*2 (lsl #0x1) at 0x08026daa, 0x08026e7c, 0x08026fe4, 0x08026cb2 and 0x0801c1ee after movt #0x804 at 0x08026e76, 0x08026cac and 0x0801c1ea | compute_channel_measurements (compute_channel_measurements): scans per channel the 301 bytes at 0x2000044e + ch*0x12d for min and max, forms the midpoint min + (max-min)/2 and counts the samples of the first high run and low run; draw_waveform_display: draw_waveform_display
	.global DATA_0804bfb8
DATA_0804bfb8:
	.global d_0804bfb8
d_0804bfb8:
	.incbin "assets/rodata.bin", 0x5d64, 8
	.global d_0804bfc0
d_0804bfc0:
	.incbin "assets/rodata.bin", 0x5d6c, 16
	.global d_0804bfd0
d_0804bfd0:
	.incbin "assets/rodata.bin", 0x5d7c, 32
	.global d_0804bff0
d_0804bff0:
	.incbin "assets/rodata.bin", 0x5d9c, 32
	.global d_0804c010
d_0804c010:
	.incbin "assets/rodata.bin", 0x5dbc, 32
	.global d_0804c030
d_0804c030:
	.incbin "assets/rodata.bin", 0x5ddc, 32
	.global d_0804c050
d_0804c050:
	.incbin "assets/rodata.bin", 0x5dfc, 32
	.global d_0804c070
d_0804c070:
	.incbin "assets/rodata.bin", 0x5e1c, 32
	.global d_0804c090
d_0804c090:
	.incbin "assets/rodata.bin", 0x5e3c, 24
@ UNREF_0804c0a8: 4 bytes cd c3 0b 08 = word 0x080bc3cd, an address whose text is 'Grenzüberschreitung' | READ: ldr.w r0,[r0,#-4] at 0x0801c9a0 with r0 = 0x0804c090 + 4*idx (movw/movt at 0x0801c994/0x0801c998, add.w at 0x0801c99c); idx = the byte at 0x20001058 (ldrb with offset 3936 from 0x200000f8); no compare limits idx between its load and the ldr, so the code allows 0..255; draw_language_list (0x0801f324) tests the byte for 1 and 2; this word is idx = 7 of the 8-word row 0x0804c090..0x0804c0af
	.global UNREF_0804c0a8
UNREF_0804c0a8:
	.incbin "assets/rodata.bin", 0x5e54, 8
	.global d_0804c0b0
d_0804c0b0:
	.incbin "assets/rodata.bin", 0x5e5c, 32
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
	.global d_0804c188
d_0804c188:
	.incbin "assets/rodata.bin", 0x5f34, 32
	.global d_0804c1a8
d_0804c1a8:
	.incbin "assets/rodata.bin", 0x5f54, 32
	.global d_0804c1c8
d_0804c1c8:
	.incbin "assets/rodata.bin", 0x5f74, 16
@ UNREF_0804c1d8: 12 bytes = 3 words: 0x080bbe0b->'Batería baja, carga', 0x080bbdf4->'Bateria baixa, carrega', 0x080bc76f->'Batterie niedrig, laden' | READ: ldr.w r0,[r0,#-4] at 0x08011572 and 0x0801e484 with r0 = 0x0804c1c8 + 4*idx (add.w at 0x0801156e and 0x0801e480, base from movw/movt ending at 0x0801156a and 0x0801e47c); idx = the byte at 0x20001058 (ldrb with offset 3936 from 0x200000f8); no compare limits idx between its load and the ldr, so the code allows 0..255; draw_language_list (0x0801f324) tests the byte for 1 and 2; these words are idx = 5, 6, 7 of the 8-word row 0x0804c1c8..0x0804c1e7
	.global UNREF_0804c1d8
UNREF_0804c1d8:
	.incbin "assets/rodata.bin", 0x5f84, 16
	.global d_0804c1e8
d_0804c1e8:
	.incbin "assets/rodata.bin", 0x5f94, 32
@ DATA_0804c208: 8 bytes = 2 words 0x0804c338, 0x0804c358, addresses of two blocks 32 bytes apart that hold 0x080b.... words (elements 0 and 1 of the four-element table at 0x0804c208) | ldr.w r1,[r2,r1,lsl #0x2] at 0x0801d244 | draw_page_by_selector_nibble: draws one of seven pages (switch on byte 0x20001062 & 0xf, values 7..15 return at once)
	.global DATA_0804c208
DATA_0804c208:
	.global d_0804c208
d_0804c208:
	.incbin "assets/rodata.bin", 0x5fb4, 8
@ DATA_0804c210: 4 bytes 78 c3 04 08 = word 0x0804c378, the address of a block that holds 0x080b.... words, element 2 of the four-element table at 0x0804c208 | ldr.w r1,[r2,r1,lsl #0x2] at 0x0801d244 with r2 = 0x0804c208 (movw/movt at 0x0801d230/0x0801d23c) and r1 = signed 7-bit value from sbfx at 0x0801d238 reaches it with r1 = 2; ldr.w r0,[r0,#-0x8] at 0x0801d322 reaches it with byte [0x20001058] = 0 (r0 = 0x0804c218 + 8*byte) | draw_page_by_selector_nibble: draws one of seven pages (switch on byte 0x20001062 & 0xf, values 7..15 return at once)
	.global DATA_0804c210
DATA_0804c210:
	.incbin "assets/rodata.bin", 0x5fbc, 8
	.global d_0804c218
d_0804c218:
	.incbin "assets/rodata.bin", 0x5fc4, 64
	.global d_0804c258
d_0804c258:
	.incbin "assets/rodata.bin", 0x6004, 44
@ UNREF_0804c284: 4 bytes = 1 word: 0x080bc35e->'USB Sharing' | READ: ldr.w r0,[r0,#-28] at 0x0801cdac with r0 = 0x0804c258 + 28*idx + 4*r5 (movw/movt at 0x0801cd98/0x0801cda0, rsb r0,r0,r0,lsl #3 at 0x0801cd9c, add.w at 0x0801cda4 and 0x0801cda8), i.e. address = 0x0804c258 + 28*(idx-1) + 4*r5 with idx = the byte at 0x20001058 (ldrb.w r0,[r4,#3936] at 0x0801cd94) and r5 not bounded by a compare in 0x0801cd7c..0x0801cdac; the table has 7 words per idx value; this word is idx = 2, r5 = 4 (44 = 28 + 16)
	.global UNREF_0804c284
UNREF_0804c284:
	.incbin "assets/rodata.bin", 0x6030, 68
@ UNREF_0804c2c8: 4 bytes = 1 word: 0x080bbeca->'Idioma' | READ: ldr.w r0,[r0,#-28] at 0x0801cdac with r0 = 0x0804c258 + 28*idx + 4*r5 (movw/movt at 0x0801cd98/0x0801cda0, rsb r0,r0,r0,lsl #3 at 0x0801cd9c, add.w at 0x0801cda4 and 0x0801cda8), i.e. address = 0x0804c258 + 28*(idx-1) + 4*r5 with idx = the byte at 0x20001058 (ldrb.w r0,[r4,#3936] at 0x0801cd94) and r5 not bounded by a compare in 0x0801cd7c..0x0801cdac; the table has 7 words per idx value; this word is idx = 5, r5 = 0 (112 = 28*4)
	.global UNREF_0804c2c8
UNREF_0804c2c8:
	.incbin "assets/rodata.bin", 0x6074, 28
@ UNREF_0804c2e4: 12 bytes = 3 words: 0x080bbf5b->'Língua', 0x080bcf03->'Som e luz', 0x080bbd4f->'Inicialização Automática' | READ: ldr.w r0,[r0,#-28] at 0x0801cdac with r0 = 0x0804c258 + 28*idx + 4*r5 (movw/movt at 0x0801cd98/0x0801cda0, rsb r0,r0,r0,lsl #3 at 0x0801cd9c, add.w at 0x0801cda4 and 0x0801cda8), i.e. address = 0x0804c258 + 28*(idx-1) + 4*r5 with idx = the byte at 0x20001058 (ldrb.w r0,[r4,#3936] at 0x0801cd94) and r5 not bounded by a compare in 0x0801cd7c..0x0801cdac; the table has 7 words per idx value; these words are idx = 6, r5 = 0, 1, 2 (140 = 28*5)
	.global UNREF_0804c2e4
UNREF_0804c2e4:
	.incbin "assets/rodata.bin", 0x6090, 100
@ UNREF_0804c348: 8 bytes = 2 words: 0x080bbd6b->'Nada', 0x080bbd6b->'Nada' | READ: ldr.w r1,[r2,r1,lsl #2] at 0x0801d244 with r2 = 0x0804c208 (movw at 0x0801d230, movt at 0x0801d23c) and r1 = the low 7 bits of r6 after and.w r1,r6,#127 / cmp r1,#3 / bhi at 0x0801d226..0x0801d22c, so r1 = 0..3 selects one of the four row addresses 0x0804c338, 0x0804c358, 0x0804c378, 0x0804c398 stored at 0x0804c208..0x0804c214; then ldr.w r3,[r1,#-4] at 0x0801d252 with r1 = row + 4*idx (add.w at 0x0801d24e, idx = ldrb.w r3,[r3,#3936] at 0x0801d248); for r1 = 0 (row 0x0804c338) this region is idx = 5 and 6 (offset 0x10)
	.global UNREF_0804c348
UNREF_0804c348:
	.incbin "assets/rodata.bin", 0x60f4, 76
@ DATA_0804c394: 4 bytes 48 d0 0b 08 = word 0x080bd048, an address whose text is '오실로스코프' | ldr.w r0,[r0,#-0x4] at 0x08010748 in fn_080106e8; ldr.w r0,[r0,#-0x4] at 0x0801576c in fn_08015740 (string table indexed by [0x20001058]) | fn_080106e8: draws 88.jpg at (0x34,0) and a string from the table indexed by [0x20001058] at the top of the screen; fn_08015740: draws 88.jpg and the string pointer at the table plus 0x20001058*4 | purpose not determined from the code
	.global DATA_0804c394
DATA_0804c394:
	.incbin "assets/rodata.bin", 0x6140, 4
	.global d_0804c398
d_0804c398:
	.incbin "assets/rodata.bin", 0x6144, 16
@ UNREF_0804c3a8: 12 bytes = 3 words: 0x080bcc43->'Generador de señales', 0x080bcd1f->'Gerador de sinais', 0x080bcbbc->'Signalgenerator' | READ: ldr.w r0,[r0,#-4] at 0x08010748 and 0x0801576c with r0 = 0x0804c398 + 4*idx (add.w at 0x08010744 and 0x08015768, base from movw/movt ending at 0x08010740 and 0x08015764); idx = the byte at 0x20001058 (ldrb with offset 3936 from 0x200000f8); no compare limits idx between its load and the ldr, so the code allows 0..255; draw_language_list (0x0801f324) tests the byte for 1 and 2; these words are idx = 5, 6, 7 of the 8-word row 0x0804c398..0x0804c3b7
	.global UNREF_0804c3a8
UNREF_0804c3a8:
	.incbin "assets/rodata.bin", 0x6154, 12
@ DATA_0804c3b4: 36 bytes = 9 words 0x080bd9d8->'신호 발생기', 0x080bd982->'系统设置', 0x080bccfe->'System Settings', 0x080bd171->'Настройки системы', 0x080bd650->'システム設定', 0x080bbea1->'Configuración del sistema', 0x080bbe86->'Configurações do Sistema', 0x080bc7e7->'Systemeinstellungen', 0x080bd506->'시스템 설정' | ldr.w r0,[r0,#-0x4] at 0x0801cd28 in fn_0801ccfc; ldr.w r0,[r0,#-0x4] at 0x08010fc8 in fn_08010f68 | fn_08010f68: draws 71.jpg at (0,0) and a string from the table indexed by [0x20001058]; fn_0801ccfc: draws 71.jpg and a string from the table indexed by 0x20001058 | purpose not determined from the code
	.global DATA_0804c3b4
DATA_0804c3b4:
	.incbin "assets/rodata.bin", 0x6160, 4
	.global d_0804c3b8
d_0804c3b8:
	.incbin "assets/rodata.bin", 0x6164, 32
@ DATA_0804c3d8: 4 bytes: word 0x080bdfb2, an address whose text is '最大值' | ldr.w r0,[r8,r0,lsl #0x2] at 0x0801caf8 | draw_value_panel: draws the lower value panel (labels from tables 0804c3d8/0804c3dc/0804c3e0)
	.global DATA_0804c3d8
DATA_0804c3d8:
	.global d_0804c3d8
d_0804c3d8:
	.incbin "assets/rodata.bin", 0x6184, 4
@ DATA_0804c3dc: 4 bytes: word 0x080bdf9e, an address whose text is '平均值' | ldr r0,[r0,#0x4] at 0x0801cbb8 | draw_value_panel: draws the lower value panel (labels from tables 0804c3d8/0804c3dc/0804c3e0)
	.global DATA_0804c3dc
DATA_0804c3dc:
	.incbin "assets/rodata.bin", 0x6188, 4
@ DATA_0804c3e0: 4 bytes: word 0x080bdfa8, an address whose text is '最小值' | ldr r0,[r0,#0x8] at 0x0801cc64 | draw_value_panel: draws the lower value panel (labels from tables 0804c3d8/0804c3dc/0804c3e0)
	.global DATA_0804c3e0
DATA_0804c3e0:
	.incbin "assets/rodata.bin", 0x618c, 16
	.global d_0804c3f0
d_0804c3f0:
	.incbin "assets/rodata.bin", 0x619c, 20
@ DATA_0804c404: 8 bytes = 2 words 0x080bbd2d, 0x080bbd2e, text 'mV', 'V' | ldr.w r0,[r1,r0,lsl #0x2] at 0x0801636e in draw_arc_gauge and ldr.w r6,[r0,r3,lsl #0x2] at 0x0801cb64, 0x0801cc18, 0x0801ccc0 in draw_value_panel | draw_arc_gauge: when byte 0x20001030 ([r5+0xf38], r5 = 0x200000f8) is not 0xff, draws the word at 0x0804c404 + 4*that byte as text at (0x102,0x70,0x34,0x1c) with font block 0x200011a4 and colour 0x055f (0x0801635e..0x0801638a); draw_value_panel: draws the lower value panel
	.global DATA_0804c404
DATA_0804c404:
	.global d_0804c404
d_0804c404:
	.incbin "assets/rodata.bin", 0x61b0, 56
	.global d_0804c43c
d_0804c43c:
	.incbin "assets/rodata.bin", 0x61e8, 184
@ UNREF_0804c4f4: 116 bytes = 29 words 0x080bcfb9->'大きい直流電流', 0x080bcf8d->'大きい交流電流', 0x080bc912->'Automático', 0x080bbf63->'Voltaje de Corriente Con..', 0x080bbed1->'Voltaje de Corriente Alt..', 0x080bc043->'Continuidad', 0x080bc982->'Diodo', 0x080bbe2d->'Resistencia', 0x080bbe20->'Capacitancia', 0x080bbf34->'Temperatura', ... (29 words in total) | READ: ldr.w r0,[r0,#-48] at 0x08010b00 and 0x08015c40 with r0 = 0x0804c43c + 48*idx + 4*col (movw/movt at 0x08010ae8/0x08010af4 and 0x08015c28/0x08015c34, add.w r0,r0,r0,lsl #1 at 0x08010af0 / add.w r0,r2,r0,lsl #4 at 0x08010af8, add.w r0,r0,r1,lsl #2 at 0x08010afc, and the same shape at 0x08015c30..0x08015c3c), i.e. address = 0x0804c43c + 48*(idx-1) + 4*col with idx = the byte at 0x20001058 (ldrb.w at 0x08010ae4 / 0x08015c24) and col = ldrb.w [r5,#3886] at 0x08010aec (0x08015c2c), neither compared against a limit; the table has 12 words per idx value; the 29 words are idx = 4 col 10, 11 (0x0804c4f4, 0x0804c4f8), idx = 5 col 0..11 (0x0804c4fc..0x0804c528), idx = 6 col 0..11 (0x0804c52c..0x0804c558) and idx = 7 col 0..2 (0x0804c55c..0x0804c564)
	.global UNREF_0804c4f4
UNREF_0804c4f4:
	.incbin "assets/rodata.bin", 0x62a0, 136
@ UNREF_0804c57c: 4 bytes = 1 word: 0x080bc715->'Kleiner Gleichstrom' | READ: ldr.w r0,[r0,#-48] at 0x08010b00 and 0x08015c40 with r0 = 0x0804c43c + 48*idx + 4*col (movw/movt at 0x08010ae8/0x08010af4 and 0x08015c28/0x08015c34, add.w r0,r0,r0,lsl #1 at 0x08010af0 / add.w r0,r2,r0,lsl #4 at 0x08010af8, add.w r0,r0,r1,lsl #2 at 0x08010afc, and the same shape at 0x08015c30..0x08015c3c), i.e. address = 0x0804c43c + 48*(idx-1) + 4*col with idx = the byte at 0x20001058 (ldrb.w at 0x08010ae4 / 0x08015c24) and col = ldrb.w [r5,#3886] at 0x08010aec (0x08015c2c), neither compared against a limit; the table has 12 words per idx value; this word is idx = 7, col = 8 (0x0804c55c + 32)
	.global UNREF_0804c57c
UNREF_0804c57c:
	.incbin "assets/rodata.bin", 0x6328, 64
	.global d_0804c5bc
d_0804c5bc:
	.incbin "assets/rodata.bin", 0x6368, 48
@ UNREF_0804c5ec: 16 bytes = 4 words: 0x080bbe46->'Frecuencia', 0x080bca28->'Ciclo de trabajo', 0x080bc085->'Amplitud', 0x080bbe7a->'Frequência' | READ: ldr.w r0,[r0,#-12] at 0x08015a5e with r0 = 0x0804c5bc + 12*idx + 4*r8 (movw at 0x08015a3c, movt at 0x08015a44, add.w r0,r1,r1,lsl #1 at 0x08015a38 with r1 = ldrb.w [r5,#3936] at 0x08015a16 (idx), add.w r0,r1,r0,lsl #2 at 0x08015a4e, add.w r0,r0,r8,lsl #2 at 0x08015a56), i.e. address = 0x0804c5bc + 12*(idx-1) + 4*r8; r8 is compared only for equality (cmp r8,r0 at 0x08015a32), so no compare limits it; the table has 3 words per idx value; these words are idx = 5, r8 = 0, 1, 2 (0x0804c5ec..0x0804c5f4) and idx = 6, r8 = 0 (0x0804c5f8)
	.global UNREF_0804c5ec
UNREF_0804c5ec:
	.incbin "assets/rodata.bin", 0x6398, 48
	.global d_0804c61c
d_0804c61c:
	.incbin "assets/rodata.bin", 0x63c8, 100
@ UNREF_0804c680: 4 bytes = 1 word: 0x080bccc0->'Lorentz waves' | READ: ldr.w r0,[r0,#-52] at 0x080157e6 with r0 = 0x0804c61c + 52*idx + 4*r7 (ldrb.w r0,[r4,#3936] at 0x080157d0 = idx, movw/movt r9 at 0x080157d4/0x080157d8, smlabb r0,r0,r1,r9 with r1 = 52 at 0x080157dc/0x080157de, add.w r0,r0,r7,lsl #2 at 0x080157e2), i.e. address = 0x0804c61c + 52*(idx-1) + 4*r7, r7 not bounded by a compare in 0x080157b4..0x080157e6; the table has 13 words per idx value; this word is idx = 2, r7 = 12 (100 = 52 + 48)
	.global UNREF_0804c680
UNREF_0804c680:
	.incbin "assets/rodata.bin", 0x642c, 108
@ UNREF_0804c6ec: 84 bytes = 21 words 0x080bc6e2->'Onda sinusoidal', 0x080bbdc3->'Onda cuadrada', 0x080bc29f->'Onda diente', 0x080bbddf->'Media onda', 0x080bbf4d->'Onda completa', 0x080bca5f->'Onda de Paso', 0x080bca6c->'Onda de Retroceso', 0x080bbd34->'Índice arriba', 0x080bc6f2->'descenso exponencial', 0x080bbfb5->'Corriente continua', ... (21 words in total) | READ: ldr.w r0,[r0,#-52] at 0x080157e6 with r0 = 0x0804c61c + 52*idx + 4*r7 (ldrb.w r0,[r4,#3936] at 0x080157d0 = idx, movw/movt r9 at 0x080157d4/0x080157d8, smlabb r0,r0,r1,r9 with r1 = 52 at 0x080157dc/0x080157de, add.w r0,r0,r7,lsl #2 at 0x080157e2), i.e. address = 0x0804c61c + 52*(idx-1) + 4*r7, r7 not bounded by a compare in 0x080157b4..0x080157e6; the table has 13 words per idx value; the 21 words are idx = 5 r7 = 0..12 (0x0804c6ec..0x0804c71c) and idx = 6 r7 = 0..7 (0x0804c720..0x0804c73c)
	.global UNREF_0804c6ec
UNREF_0804c6ec:
	.incbin "assets/rodata.bin", 0x6498, 96
@ UNREF_0804c74c: 4 bytes = 1 word: 0x080bc6c9->'Pulso Sink' | READ: ldr.w r0,[r0,#-52] at 0x080157e6 with r0 = 0x0804c61c + 52*idx + 4*r7 (ldrb.w r0,[r4,#3936] at 0x080157d0 = idx, movw/movt r9 at 0x080157d4/0x080157d8, smlabb r0,r0,r1,r9 with r1 = 52 at 0x080157dc/0x080157de, add.w r0,r0,r7,lsl #2 at 0x080157e2), i.e. address = 0x0804c61c + 52*(idx-1) + 4*r7, r7 not bounded by a compare in 0x080157b4..0x080157e6; the table has 13 words per idx value; this word is idx = 6, r7 = 11 (304 = 52*5 + 44)
	.global UNREF_0804c74c
UNREF_0804c74c:
	.incbin "assets/rodata.bin", 0x64f8, 40
@ UNREF_0804c774: 12 bytes = 3 words: 0x080bc345->'Indexrückgang', 0x080bc731->'Gleichstrom', 0x080bc354->'Mehrklang' | READ: ldr.w r0,[r0,#-52] at 0x080157e6 with r0 = 0x0804c61c + 52*idx + 4*r7 (ldrb.w r0,[r4,#3936] at 0x080157d0 = idx, movw/movt r9 at 0x080157d4/0x080157d8, smlabb r0,r0,r1,r9 with r1 = 52 at 0x080157dc/0x080157de, add.w r0,r0,r7,lsl #2 at 0x080157e2), i.e. address = 0x0804c61c + 52*(idx-1) + 4*r7, r7 not bounded by a compare in 0x080157b4..0x080157e6; the table has 13 words per idx value; these words are idx = 7, r7 = 8, 9, 10 (344 = 52*6 + 32)
	.global UNREF_0804c774
UNREF_0804c774:
	.incbin "assets/rodata.bin", 0x6520, 72
@ DATA_0804c7bc: 8 bytes = 2 words 0x080bb979->'X1', 0x080bb92f->'X10' | ldr.w r0,[r1,r0,lsl #0x2] at 0x0801e92a in draw_bottom_strip; ldr.w r0,[r1,r0,lsl #0x2] at 0x0801ea7a in draw_bottom_strip; 1 further references listed | draw_panels_by_selector_20001062: menu-panel drawing routine (switch on 0x20001062 & 0xf); draw_bottom_strip: draws the bottom status strip at y=0xdd (JPEG 3.jpg, strings, 1-bit bitmap)
	.global DATA_0804c7bc
DATA_0804c7bc:
	.global d_0804c7bc
d_0804c7bc:
	.incbin "assets/rodata.bin", 0x6568, 8
@ DATA_0804c7c4: 8 bytes = 2 words 0x080bbc28->'AC', 0x080bbc2b->'DC' | ldr.w r5,[r1,r0,lsl #0x2] at 0x0801e8d4 in draw_bottom_strip; ldr.w r5,[r1,r0,lsl #0x2] at 0x0801ea24 in draw_bottom_strip; 3 further references listed | draw_panels_by_selector_20001062: menu-panel drawing routine (switch on 0x20001062 & 0xf); draw_bottom_strip: draws the bottom status strip at y=0xdd (JPEG 3.jpg, strings, 1-bit bitmap)
	.global DATA_0804c7c4
DATA_0804c7c4:
	.global d_0804c7c4
d_0804c7c4:
	.incbin "assets/rodata.bin", 0x6570, 8
@ DATA_0804c7cc: 4 bytes = word 0x080bbb04->'触发模式:' | ldr.w r0,[r10,r6,lsl #0x2] at 0x080136c6 in draw_panels_by_selector_20001062 | draw_panels_by_selector_20001062: menu-panel drawing routine (switch on 0x20001062 & 0xf)
	.global DATA_0804c7cc
DATA_0804c7cc:
	.global d_0804c7cc
d_0804c7cc:
	.incbin "assets/rodata.bin", 0x6578, 4
@ DATA_0804c7d0: 4 bytes = word 0x080bbbec->'触发沿:' | ldr r0,[r0,#0x4] at 0x08013786 in draw_panels_by_selector_20001062 | draw_panels_by_selector_20001062: menu-panel drawing routine (switch on 0x20001062 & 0xf)
	.global DATA_0804c7d0
DATA_0804c7d0:
	.incbin "assets/rodata.bin", 0x657c, 4
@ DATA_0804c7d4: 4 bytes = word 0x080bbb20->'触发通道:' | ldr r0,[r0,#0x8] at 0x08013994 in draw_panels_by_selector_20001062 | draw_panels_by_selector_20001062: menu-panel drawing routine (switch on 0x20001062 & 0xf)
	.global DATA_0804c7d4
DATA_0804c7d4:
	.incbin "assets/rodata.bin", 0x6580, 16
@ DATA_0804c7e4: 4 bytes = word 0x080bdd54->'正常' | movt r2,#0x804 at 0x0801eb76 in draw_bottom_strip | draw_bottom_strip: draws the bottom status strip at y=0xdd (JPEG 3.jpg, strings, 1-bit bitmap)
	.global DATA_0804c7e4
DATA_0804c7e4:
	.global d_0804c7e4
d_0804c7e4:
	.incbin "assets/rodata.bin", 0x6590, 4
@ DATA_0804c7e8: 12 bytes = 3 words 0x080bd86b->'自动', 0x080bd72f->'单次', 0x080bc707->'Normal' | ldr.w r0,[r5,r0,lsl #0x2] at 0x0801eb06 in draw_bottom_strip | draw_bottom_strip: draws the bottom status strip at y=0xdd (JPEG 3.jpg, strings, 1-bit bitmap)
	.global DATA_0804c7e8
DATA_0804c7e8:
	.incbin "assets/rodata.bin", 0x6594, 16
@ UNREF_0804c7f8: 4 bytes = 1 word: 0x080bc184->'Single' | READ: ldr.w r0,[r5,r0,lsl #2] at 0x0801eb06 with r5 = 0x0804c7e4 + 12*r8 (movt at 0x0801eafe, orr.w r1,r8,r8,lsl #1 at 0x0801eafa, add.w r5,r2,r1,lsl #2 at 0x0801eb02, r8 = 0 or 1 from subs/movne at 0x0801eaee..0x0801eaf4) and r0 = ldrb [r7,#23] at 0x0801eaf8 (no compare); ldr.w r5,[r1,r0,lsl #2] at 0x0801eb7e with r1 = 0x0804c7e4 + 12*r8 (0x0801eb72..0x0801eb7a); ldr.w r0,[r1,r0,lsl #2] at 0x0801371c with r1 = 0x0804c7e4 + 4*r6 (add.w at 0x08013718) and r0 = ldrb [r4,#23] at 0x08013712; this word is offset 0x14 from 0x0804c7e4 (r8 = 1 and byte value 2)
	.global UNREF_0804c7f8
UNREF_0804c7f8:
	.incbin "assets/rodata.bin", 0x65a4, 4
@ DATA_0804c7fc: 8 bytes = 2 words 0x080bb975->'CH1', 0x080bb9e0->'CH2' | ldr.w r5,[r1,r0,lsl #0x2] at 0x0801ebde in draw_bottom_strip; ldr.w r0,[r0,r1,lsl #0x2] at 0x0801eda4 in draw_bottom_strip; 1 further references listed | draw_panels_by_selector_20001062: menu-panel drawing routine (switch on 0x20001062 & 0xf); draw_bottom_strip: draws the bottom status strip at y=0xdd (JPEG 3.jpg, strings, 1-bit bitmap)
	.global DATA_0804c7fc
DATA_0804c7fc:
	.global d_0804c7fc
d_0804c7fc:
	.incbin "assets/rodata.bin", 0x65a8, 8
	.global d_0804c804
d_0804c804:
	.incbin "assets/rodata.bin", 0x65b0, 28
@ UNREF_0804c820: 4 bytes = 1 word: 0x080bd57a->'运 算' | READ: ldr.w r0,[r0,#-32] at 0x08012e44 with r0 = 0x0804c804 + 32*idx + 4*r7 (ldrb.w r0,[r9,#3936] at 0x08012e30 = idx, add.w r0,fp,r0,lsl #5 at 0x08012e3c with fp = 0x0804c804, add.w r0,r0,r7,lsl #2 at 0x08012e40), i.e. address = 0x0804c804 + 32*(idx-1) + 4*r7, r7 not bounded by a compare near it; the table has 8 words per idx value; this word is idx = 1, r7 = 7 (offset 0x1c)
	.global UNREF_0804c820
UNREF_0804c820:
	.incbin "assets/rodata.bin", 0x65cc, 16
@ UNREF_0804c830: 12 bytes = 3 words: 0x080bccce->'CH1 Settings', 0x080bccdb->'CH2 Settings', 0x080bcd0e->'Trigger Settings' | READ: ldr.w r0,[r0,#-32] at 0x08012e44 with r0 = 0x0804c804 + 32*idx + 4*r7 (ldrb.w r0,[r9,#3936] at 0x08012e30 = idx, add.w r0,fp,r0,lsl #5 at 0x08012e3c with fp = 0x0804c804, add.w r0,r0,r7,lsl #2 at 0x08012e40), i.e. address = 0x0804c804 + 32*(idx-1) + 4*r7, r7 not bounded by a compare near it; the table has 8 words per idx value; these words are idx = 2, r7 = 3, 4, 5 (offset 0x2c = 32 + 12)
	.global UNREF_0804c830
UNREF_0804c830:
	.incbin "assets/rodata.bin", 0x65dc, 108
@ UNREF_0804c89c: 4 bytes = 1 word: 0x080bbe39->'Persistencia' | READ: ldr.w r0,[r0,#-32] at 0x08012e44 with r0 = 0x0804c804 + 32*idx + 4*r7 (ldrb.w r0,[r9,#3936] at 0x08012e30 = idx, add.w r0,fp,r0,lsl #5 at 0x08012e3c with fp = 0x0804c804, add.w r0,r0,r7,lsl #2 at 0x08012e40), i.e. address = 0x0804c804 + 32*(idx-1) + 4*r7, r7 not bounded by a compare near it; the table has 8 words per idx value; this word is idx = 5, r7 = 6 (offset 0x98 = 32*4 + 24)
	.global UNREF_0804c89c
UNREF_0804c89c:
	.incbin "assets/rodata.bin", 0x6648, 32
@ UNREF_0804c8bc: 20 bytes = 5 words: 0x080bbe6c->'Persistência', 0x080bbd43->'Matemática', 0x080bcd9e->'Anzeigemodus', 0x080bc39f->'Cursor-Messung', 0x080bc3ae->'Parametermessung' | READ: ldr.w r0,[r0,#-32] at 0x08012e44 with r0 = 0x0804c804 + 32*idx + 4*r7 (ldrb.w r0,[r9,#3936] at 0x08012e30 = idx, add.w r0,fp,r0,lsl #5 at 0x08012e3c with fp = 0x0804c804, add.w r0,r0,r7,lsl #2 at 0x08012e40), i.e. address = 0x0804c804 + 32*(idx-1) + 4*r7, r7 not bounded by a compare near it; the table has 8 words per idx value; these words are idx = 6 r7 = 6, 7 (0x0804c8bc, 0x0804c8c0) and idx = 7 r7 = 0, 1, 2 (0x0804c8c4..0x0804c8cc)
	.global UNREF_0804c8bc
UNREF_0804c8bc:
	.incbin "assets/rodata.bin", 0x6668, 32
@ UNREF_0804c8dc: 8 bytes = 2 words: 0x080bc3bf->'Nachleuchtung', 0x080bc6be->'Mathematik' | READ: ldr.w r0,[r0,#-32] at 0x08012e44 with r0 = 0x0804c804 + 32*idx + 4*r7 (ldrb.w r0,[r9,#3936] at 0x08012e30 = idx, add.w r0,fp,r0,lsl #5 at 0x08012e3c with fp = 0x0804c804, add.w r0,r0,r7,lsl #2 at 0x08012e40), i.e. address = 0x0804c804 + 32*(idx-1) + 4*r7, r7 not bounded by a compare near it; the table has 8 words per idx value; these words are idx = 7, r7 = 6, 7 (offset 0xd8 = 32*6 + 24)
	.global UNREF_0804c8dc
UNREF_0804c8dc:
	.incbin "assets/rodata.bin", 0x6688, 20
@ UNREF_0804c8f0: 16 bytes = 4 words: 0x080bd4d6->'CH1 설정', 0x080bd4e1->'CH2 설정', 0x080bd517->'트리거 설정', 0x080bdfdd->'잔상 효과' | READ: ldr.w r0,[r0,#-32] at 0x08012e44 with r0 = 0x0804c804 + 32*idx + 4*r7 (ldrb.w r0,[r9,#3936] at 0x08012e30 = idx, add.w r0,fp,r0,lsl #5 at 0x08012e3c with fp = 0x0804c804, add.w r0,r0,r7,lsl #2 at 0x08012e40), i.e. address = 0x0804c804 + 32*(idx-1) + 4*r7, r7 not bounded by a compare near it; the table has 8 words per idx value; these words are idx = 8, r7 = 3, 4, 5, 6 (offset 0xec = 32*7 + 12)
	.global UNREF_0804c8f0
UNREF_0804c8f0:
	.incbin "assets/rodata.bin", 0x669c, 16
@ DATA_0804c900: 12 bytes = 3 words 0x080bd99f->'수학 연산', 0x080bd98f->'示波器设置', 0x080bcce8->'Oscilloscope Settings' | ldr.w r0,[r0,#-0x4] at 0x08012db0 in fn_08012d84; ldr.w r0,[r0,#-0x4] at 0x08010374 in fn_08010314 | fn_08010314: draws 71.jpg at (0,0) and a string from the table indexed by [0x20001058]; fn_08012d84: draws 71.jpg and a string from the table indexed by 0x20001058 | purpose not determined from the code
	.global DATA_0804c900
DATA_0804c900:
	.incbin "assets/rodata.bin", 0x66ac, 4
	.global d_0804c904
d_0804c904:
	.incbin "assets/rodata.bin", 0x66b0, 28
@ UNREF_0804c920: 4 bytes = 1 word: 0x080bd4ec->'오실로스코프 설정' | READ: ldr.w r0,[r0,#-4] at 0x08010374 and 0x08012db0 with r0 = 0x0804c904 + 4*idx (add.w at 0x08010370 and 0x08012dac, base from movw/movt ending at 0x0801036c and 0x08012da8); idx = the byte at 0x20001058 (ldrb with offset 3936 from 0x200000f8); no compare limits idx between its load and the ldr, so the code allows 0..255; draw_language_list (0x0801f324) tests the byte for 1 and 2; this word is idx = 8 of the 8-word row 0x0804c904..0x0804c923
	.global UNREF_0804c920
UNREF_0804c920:
	.incbin "assets/rodata.bin", 0x66cc, 4
	.global d_0804c924
d_0804c924:
	.incbin "assets/rodata.bin", 0x66d0, 20
@ UNREF_0804c938: 4 bytes = 1 word: 0x080bcd16->'Settings' | READ: ldrsb.w r0,[r5,#3945] at 0x080100b2 with cmp r0,#3 / bhi at 0x080100b6 / 0x080100b8 (0..3), ldr.w r0,[r1,r0,lsl #2] at 0x080100c2 with r1 = 0x0804c924 (movw/movt at 0x080100ba/0x080100be) selecting one of the row addresses 0x0804c358, 0x0804c378, 0x0804c398, 0x0804c934 stored at 0x0804c924..0x0804c930, then ldrb.w r1,[r5,#3936] at 0x080100c6 (idx), add.w r0,r0,r1,lsl #2 at 0x080100ce and ldr.w r0,[r0,#-4] at 0x080100d2 (the same sequence at 0x08012d3c..0x08012d58); idx is not compared against a limit; for the value 3 the row is 0x0804c934 and this word is idx = 2
	.global UNREF_0804c938
UNREF_0804c938:
	.incbin "assets/rodata.bin", 0x66e4, 20
@ UNREF_0804c94c: 8 bytes = 2 words: 0x080bc36a->'Einstellung', 0x080bd521->'설정' | READ: ldrsb.w r0,[r5,#3945] at 0x080100b2 with cmp r0,#3 / bhi at 0x080100b6 / 0x080100b8 (0..3), ldr.w r0,[r1,r0,lsl #2] at 0x080100c2 with r1 = 0x0804c924 (movw/movt at 0x080100ba/0x080100be) selecting one of the row addresses 0x0804c358, 0x0804c378, 0x0804c398, 0x0804c934 stored at 0x0804c924..0x0804c930, then ldrb.w r1,[r5,#3936] at 0x080100c6 (idx), add.w r0,r0,r1,lsl #2 at 0x080100ce and ldr.w r0,[r0,#-4] at 0x080100d2 (the same sequence at 0x08012d3c..0x08012d58); idx is not compared against a limit; for the value 3 the row is 0x0804c934 and these words are idx = 7 and 8
	.global UNREF_0804c94c
UNREF_0804c94c:
	.incbin "assets/rodata.bin", 0x66f8, 8
@ DATA_0804c954: 104 bytes = 26 words, each an address of a text: 0x080bbd21->'10mV', 0x080bbd26->'20mV', 0x080bbd2b->'50mV', 0x080bbd0f->'100mV', 0x080bbd15->'200mV', 0x080bbd1b->'500mV', 0x080bbd06->'1V', 0x080bbd09->'2V', 0x080bbd0c->'5V', 0x080bbcfa->'10V', 0x080bbcfe->'20V', 0x080bbd02->'50V', 0x080bbcf5->'100V', 0x080bbcb9->'10nS', 0x080bbcbe->'20nS', 0x080bbcc3->'50nS', 0x080bbca7->'100nS', 0x080bbcad->'200nS', 0x080bbcb3->'500nS', 0x080bbce9->'1uS', 0x080bbced->'2uS', 0x080bbcf1->'5uS', 0x080bbcda->'10uS', 0x080bbcdf->'20uS', 0x080bbce4->'50uS', 0x080bbcc8->'100uS' | ldr.w r0,[r7,r0,lsl #0x2] at 0x0801e7c0 in draw_bottom_strip; ldr.w r0,[r7,r0,lsl #0x2] at 0x0801e7f4 in draw_bottom_strip; 4 further references listed (index = byte 0x200000fe*3 + byte 0x200000fa: ldrb at 0x0801e7a2/0x0801e7a4, add.w at 0x0801e7a6/0x0801e7aa) | draw_bottom_strip: draws the bottom status strip at y=0xdd (JPEG 3.jpg, strings, 1-bit bitmap)
	.global DATA_0804c954
DATA_0804c954:
	.global d_0804c954
d_0804c954:
	.incbin "assets/rodata.bin", 0x6700, 52
	.global d_0804c988
d_0804c988:
	.incbin "assets/rodata.bin", 0x6734, 56
@ UNREF_0804c9c0: 62 bytes = 15 words 0x080bbcd4->'500uS', 0x080bbc9b->'1mS', 0x080bbc9f->'2mS', 0x080bbca3->'5mS', 0x080bbc8c->'10mS', 0x080bbc91->'20mS', 0x080bbc96->'50mS', 0x080bbc7a->'100mS', 0x080bbc80->'200mS', 0x080bbc86->'500mS', 0x080bbc6d->'1S', 0x080bbc70->'2S', 0x080bbc73->'5S', 0x080bbc65->'10S', 0x080bbc69->'20S' followed by the 2 bytes 40 01 that start the halfword record array at 0x0804c9fc | READ: ldr.w r2,[r1,r0,lsl #2] at 0x0801302a with r1 = 0x0804c988 (movw/movt at 0x0801301e/0x08013022) and r0 = ldrb.w [r6,#45] at 0x0801301a (r6 = 0x200000f8 from 0x08012ff8/0x08012ffc), no compare bounds r0, so 0x0804c988 + 4*r0 reaches this region (it starts at index 14); also ldr.w r0,[r7,r0,lsl #2] at 0x0801e7c0 with r7 = 0x0804c954 (movw 0x0801e7ac, movt 0x0801e7b8) and r0 = 3*[r4+6] + [r4+2] (add.w r0,r0,r0,lsl #1 at 0x0801e7a6, add r0,r1 at 0x0801e7aa), where this region starts at index 27
	.global UNREF_0804c9c0
UNREF_0804c9c0:
	.incbin "assets/rodata.bin", 0x676c, 60
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
	.global d_0804d766
d_0804d766:
	.incbin "assets/rodata.bin", 0x7512, 1
@ DATA_0804d767: 1 byte 00 | ldrb r6,[r4,r6] at 0x0802bd94 with r4 = 0x0804d767 (movw/movt at 0x0802bd8c/0x0802bd90) and r6 = r5*lr+ip (mla at 0x0802bd88); the nibble selected by r3 (and.w r3,r3,#1 at 0x0802bd70; cmp r3,#0 at 0x0802bd9c: low nibble from and.w fp,r6,#15 at 0x0802bd98 when r3 != 0, high nibble from moveq.w fp,r6,lsr #4 at 0x0802bda0 when r3 == 0) indexes the halfword array on the stack (add r4,sp,#0x40; ldrh.w r6,[r4,fp,lsl #1] at 0x0802bda4) | system_bring_up: bring-up routine
	.global DATA_0804d767
DATA_0804d767:
	.incbin "assets/rodata.bin", 0x7513, 2
@ UNREF_0804d769: 43 bytes fe b3 00 09 ff ff ff 60 6f ff ff ff f2 df ff ff ff f9 ff ff ff ff fc ff ff ff ff fb bf ff ff ff f8 3f ff ff ff f1 06 ff ff ff 40 = offsets 2.. of the byte array whose base 0x0804d767 is built at 0x0802bd8c/0x0802bd90 in system_bring_up (nibble selected at 0x0802bd98 / 0x0802bda0 by r3 & 1, see 0x0802bd70 and 0x0802bd9c) | no reference found for this address itself
	.global UNREF_0804d769
UNREF_0804d769:
	.incbin "assets/rodata.bin", 0x7515, 47
	.global d_0804d798
d_0804d798:
	.incbin "assets/rodata.bin", 0x7544, 2
@ UNREF_0804d79a: 39 bytes 3a dc 70 00 04 ff ff fb 00 0e ff ff ff 51 3f ff ff ff 95 2f ff ff ff 84 0d ff ff ff 30 02 ef ff f7 00 00 18 ba 40 00 | lies 1 byte after base 0x0804d799 (movw #0xd799 at 0x0802bf50 + movt at 0x0802bf54, add r5,r1 at 0x0802bf58 in system_bring_up) | no reference found for this address itself
	.global UNREF_0804d79a
UNREF_0804d79a:
	.incbin "assets/rodata.bin", 0x7546, 38
	.global d_0804d7c0
d_0804d7c0:
	.incbin "assets/rodata.bin", 0x756c, 1
@ DATA_0804d7c1: 1 byte 2a | ldrbeq.w fp,[r1,r0] at 0x0802bbfc with r1 = 0x0804d7c1 (movw #0xd7c1 at 0x0802bbe4, movt at 0x0802bbee) and r0 = r3>>1 (lsreq at 0x0802bbfa) when [sp+0x3c] == 2 (cmp r0,#2 at 0x0802bbf6) | system_bring_up: bring-up routine
	.global DATA_0804d7c1
DATA_0804d7c1:
	.incbin "assets/rodata.bin", 0x756d, 2
@ UNREF_0804d7c3: 3 bytes 00 ef ff | lies at offset 2..4 after base 0x0804d7c1 (movw #0xd7c1 at 0x0802bbe4 / 0x0802bea6 in system_bring_up) | no reference found for this address itself
	.global UNREF_0804d7c3
UNREF_0804d7c3:
	.incbin "assets/rodata.bin", 0x756f, 5
@ DATA_0804d7c8: 11 bytes ff f0 ff ff e0 cf ff 70 07 95 00 | ldrb r6,[r4,r6] at 0x0802bd94 in system_bring_up (address = r4 + r6 with r4 = 0x0804d767 and r6 = r5*lr+ip from the mla at 0x0802bd88; nibble selected at 0x0802bd98 / 0x0802bda0 by r3 & 1); 0x0804d7c8 = 0x0804d767 + 0x61 | system_bring_up: bring-up routine
	.global DATA_0804d7c8
DATA_0804d7c8:
	.incbin "assets/rodata.bin", 0x7574, 10
	.global d_0804d7d2
d_0804d7d2:
	.incbin "assets/rodata.bin", 0x757e, 1
@ DATA_0804d7d3: 1 byte 00 = byte 0 of the array at 0x0804d7d3 (base 0x0804d7d3 + 32*index: add.w r5,r2,r1,lsl #5 at 0x0801ec74 after movw #0xd7d3 at 0x0801ec54) | ldrb r6,[r5,r6] at 0x0801ecb6 in draw_bottom_strip with a bit test (rsb r1,r1,#7 at 0x0801ecba, lsr.w at 0x0801ecbe, lsls r1,r1,#31 at 0x0801ecc2: most significant bit first) | 16-pixel-wide 1-bit rows of 2 bytes: bit counter r0 counts 0..7 then r4 advances by 1 (cmp r1,#7 at 0x0801eca6, addhi r4,#1 at 0x0801ecac), the bitmap index byte comes from ldrb r1,[r1,#24] at 0x0801ec4e and is multiplied by 32 (lsl #5 at 0x0801ec74) | ldrb r4,[r2,r4] at 0x08013808 and ldrb r1,[r2,r1] at 0x08013866 in draw_panels_by_selector_20001062 use the same style of bit test (lsr by 7-n at 0x08013810, 0x0801386e) | draw_bottom_strip: draws the bottom status strip at y=0xdd; draw_panels_by_selector_20001062: menu-panel drawing routine
	.global DATA_0804d7d3
DATA_0804d7d3:
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
	.global d_0804d832
d_0804d832:
	.incbin "assets/rodata.bin", 0x75de, 1
@ DATA_0804d833: 13 bytes all 01 | ldrb r1,[r1,r0] at 0x0803e558 with r1 = 0x0804d833 (movw #0xd833 at 0x0803e550, movt at 0x0803e554) and r0 = byte [r9+0x2d] (ldrb.w at 0x0803e54c); r1+0x32 is compared with the halfword [r9+0xdb8] (cmp r1,r2 at 0x0803e560) | the code at 0x0803e54c..0x0803e562 lies inside fn_0803e454 (0x0803e454..0x08040007)
	.global DATA_0804d833
DATA_0804d833:
	.incbin "assets/rodata.bin", 0x75df, 14
@ UNREF_0804d841: 7 bytes 03 05 09 15 29 52 00 | READ: ldrb r1,[r1,r0] at 0x0803e558 with r1 = 0x0804d833 (movw/movt at 0x0803e550/0x0803e554) and r0 = ldrb.w [r9,#45] at 0x0803e54c (no compare shown between them), and ldrb r1,[r3,r1] at 0x0804067c with r3 = 0x0804d833 (movw/movt at 0x08040670/0x08040678) and r1 = ldrb [r0,#45] at 0x08040668 limited by cmp r1,#19 / bhi at 0x0804066c / 0x0804066e (0..19); this region is index 14..20 (0x0804d841 = 0x0804d833 + 14), index 14..19 reachable at 0x0804067c
	.global UNREF_0804d841
UNREF_0804d841:
	.incbin "assets/rodata.bin", 0x75ed, 7
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
@ DATA_0804de88: 7800 bytes = 300*0x34/2 (the width 300 and height 0x34 passed to 0x0801ffcc), first bytes 00 00 00 38 88 88 88 88 ... | the address is passed as the fifth argument: str r0,[sp,#0x0] at 0x0801cac4 for the call 0801ffcc(10,0xb8,300,0x34,bitmap,0xffff) | draw_value_panel: draws the lower value panel
	.global DATA_0804de88
DATA_0804de88:
	.global d_0804de88
d_0804de88:
	.incbin "assets/rodata.bin", 0x7c34, 7800
@ DATA_0804fd00: 8217 bytes = 0xc6*0x53/2 (width 0xc6, height 0x53 passed to 0x0801ffcc), first bytes all 00 ... | the address is passed as the fifth argument: str r0,[sp,#0x0] at 0x0801c7a4, 0x08011f1e and 0x0801f2d4 for calls 0801ffcc(0x3d,0x50,0xc6,0x53,bitmap,0x55f) | fn_08011e84: draws a region 0x3d,0x50,0xc6,0x53 with 0801ffcc; draw_bitmap_and_text: draws a message box; draw_waveform_display: scope-view drawing routine
	.global DATA_0804fd00
DATA_0804fd00:
	.global d_0804fd00
d_0804fd00:
	.incbin "assets/rodata.bin", 0x9aac, 8216
	.global d_08051d18
d_08051d18:
	.incbin "assets/rodata.bin", 0xbac4, 5
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
	.incbin "assets/rodata.bin", 0x28ce0, 71894
@ UNREF_0808080a: 107066 bytes; the first 92 8-byte records are (u16, u8, u8, u8, u8, u16) = (0x0080, 8, 9, 0, 3, 0x0044), (0x0070, 8, 13, 0, 1, 0x0078), (0x00a0, 10, 10, 0, 2, 0x00aa), (0x0090, 10, 11, 0, 2, 0x00e1), (0x0030, 4, 4, 0, 9, 0x00e9), (0x0050, 6, 12, 0, 1, 0x010d) ... with the last halfword non-decreasing 68, 120, 170, 225, 233, 269, ... 3110 | READ: the record table of the glyph descriptor at 0x200010f8 (words 0x08077f9c data base, 0x080807f0 record table, 0x080819a8 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x200010e4 with callback words 0x0802f809 and 0x0802f429) continues here: the callback 0x0802f428 loads the 8-byte records with ldr.w r0,[r0,r4,lsl #3] (word 0 holds a 12-bit field in bits 20..31 and the glyph offset in bits 0..19; bytes 4..7 = columns, rows, two signed offsets, copied to the caller by the fields callback 0x0802f808); the range table of that descriptor (0x080819a8..0x08081e2b), the glyph data, record tables (0x0808b214, 0x08098fdc) and range tables (0x0808c3cc, 0x0809a194) of the descriptors at 0x20001128 (words 0x08081e2c, 0x0808b214, 0x0808c3cc) and 0x20001158 (words 0x0808c850, 0x08098fdc, 0x0809a194) and the first glyph bitmaps of the descriptor at 0x20001188 (data base 0x0809a618) lie inside this region; blend_glyph_into_region_buffer (0x0800fb90) reads bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48 after the pointer callback (blx r2 at 0x0800fba4); 1182 record offsets give bitmap start addresses inside this region (first 0x08081e2c, last 0x0809aa3f); the words 0x08080878 at 0x08008e20 and 0x0808f04f at 0x08040188 are bytes inside instructions and not pointers
	.global UNREF_0808080a
UNREF_0808080a:
	.incbin "assets/rodata.bin", 0x3a5b6, 107078
@ UNREF_0809aa50: 44 bytes 1c 60 18 30 18 38 30 1f f0 0f c0 3f 00 3f c0 30 e0 30 60 30 60 30 60 30 e0 3f c0 3f 00 30 00 30 00 30 00 30 00 30 00 0f c0 1f f0 38 (even byte count) | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 2 record offsets give bitmap start addresses inside this region (first 0x0809aa5b, last 0x0809aa77)
	.global UNREF_0809aa50
UNREF_0809aa50:
	.incbin "assets/rodata.bin", 0x547fc, 56
@ UNREF_0809aa88: 540 bytes 1c 60 18 30 18 38 30 1f f0 0f e0 00 70 00 38 00 1e 3f 00 3f c0 30 e0 30 60 30 60 30 60 31 c0 3f c0 3f 80 31 80 30 c0 30 e0 30 60 30 30 1f 00 3f ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 24 record offsets give bitmap start addresses inside this region (first 0x0809aa99, last 0x0809aca2)
	.global UNREF_0809aa88
UNREF_0809aa88:
	.incbin "assets/rodata.bin", 0x54834, 576
@ UNREF_0809acc8: 20 bytes 00 60 00 61 c0 63 80 63 00 66 00 6e 00 7e 00 73 00 63 80 61 | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); no record offset starts inside this region; the record 75 (0x080a0468 + 8*75, word 0x00a006ab, width 16, height 14, 1 bit per pixel from the descriptor halfword at 0x2000119a) gives the start 0x0809acc3 and the next glyph starts at 0x0809acdf, so its 28 bytes 0x0809acc3..0x0809acde include this region
	.global UNREF_0809acc8
UNREF_0809acc8:
	.incbin "assets/rodata.bin", 0x54a74, 36
@ UNREF_0809acec: 24 bytes 60 6f 3c 7f fe 71 c6 61 86 61 86 61 86 61 86 61 86 61 86 61 86 6f 00 7f | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 2 record offsets give bitmap start addresses inside this region (first 0x0809aced, last 0x0809ad01)
	.global UNREF_0809acec
UNREF_0809acec:
	.incbin "assets/rodata.bin", 0x54a98, 40
@ UNREF_0809ad14: 264 bytes c0 1f 00 3f 80 70 c0 60 c0 60 c0 60 c0 60 c0 70 c0 3f 80 1f 00 6f 80 7f c0 70 c0 70 60 60 60 60 60 70 60 70 c0 7f c0 6f 80 60 00 60 00 60 00 60 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 13 record offsets give bitmap start addresses inside this region (first 0x0809ad15, last 0x0809ae0e)
	.global UNREF_0809ad14
UNREF_0809ad14:
	.incbin "assets/rodata.bin", 0x54ac0, 284
@ UNREF_0809ae30: 344 bytes f0 30 38 18 18 18 18 1e 0e 18 18 18 18 18 30 f0 e0 18 c0 3c c0 67 c0 63 80 08 80 1d c0 08 80 00 00 06 00 07 00 07 00 0d 80 0d 80 19 80 18 c0 18 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 15 record offsets give bitmap start addresses inside this region (first 0x0809ae30, last 0x0809af87)
	.global UNREF_0809ae30
UNREF_0809ae30:
	.incbin "assets/rodata.bin", 0x54bdc, 356
@ UNREF_0809af94: 12 bytes 60 1d 80 37 80 03 00 00 00 6f 00 7f | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 1 record offsets give bitmap start addresses inside this region (first 0x0809af95, last 0x0809af95)
	.global UNREF_0809af94
UNREF_0809af94:
	.incbin "assets/rodata.bin", 0x54d40, 28
@ UNREF_0809afb0: 92 bytes c0 03 00 06 00 06 00 00 00 1f 00 3f 80 70 c0 60 c0 60 c0 60 c0 60 c0 70 c0 3f 80 1f 00 1d 80 37 80 03 00 00 00 1f 00 3f 80 70 c0 60 c0 60 c0 60 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 4 record offsets give bitmap start addresses inside this region (first 0x0809afb1, last 0x0809b005)
	.global UNREF_0809afb0
UNREF_0809afb0:
	.incbin "assets/rodata.bin", 0x54d5c, 104
@ UNREF_0809b018: 372 bytes c0 60 c0 71 c0 3f c0 1e c0 0f c0 1f f0 38 30 30 18 60 18 60 1c 60 1c 60 1c 60 18 30 18 30 30 1c 70 7c fc 7c fc 06 00 07 00 07 00 0d 80 0d 80 19 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 13 record offsets give bitmap start addresses inside this region (first 0x0809b021, last 0x0809b185)
	.global UNREF_0809b018
UNREF_0809b018:
	.incbin "assets/rodata.bin", 0x54dc4, 384
@ UNREF_0809b198: 152 bytes 18 30 18 38 30 1f f0 0f c0 3f f8 3f f8 30 18 30 18 30 18 30 18 30 18 30 18 30 18 30 18 30 18 30 18 30 18 3f 00 3f c0 30 e0 30 60 30 60 30 ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 5 record offsets give bitmap start addresses inside this region (first 0x0809b1a1, last 0x0809b211)
	.global UNREF_0809b198
UNREF_0809b198:
	.incbin "assets/rodata.bin", 0x54f44, 164
@ UNREF_0809b23c: 316 bytes 60 60 60 70 e0 3f e0 1f 60 00 60 00 60 00 60 00 60 00 60 0f e0 1f e0 30 60 70 60 70 60 30 60 38 60 1f e0 0f e0 1c 60 18 60 30 60 70 60 e0 60 1f ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 14 record offsets give bitmap start addresses inside this region (first 0x0809b24f, last 0x0809b369)
	.global UNREF_0809b23c
UNREF_0809b23c:
	.incbin "assets/rodata.bin", 0x54fe8, 328
@ UNREF_0809b384: 36 bytes c0 7f c0 7f c0 60 c0 60 c0 60 c0 60 c0 1f 00 3f 80 70 c0 60 c0 60 c0 60 c0 60 c0 70 c0 3f 80 1f 00 7f c0 7f | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 2 record offsets give bitmap start addresses inside this region (first 0x0809b391, last 0x0809b3a5)
	.global UNREF_0809b384
UNREF_0809b384:
	.incbin "assets/rodata.bin", 0x55130, 52
@ UNREF_0809b3b8: 152 bytes c0 6f 80 7f c0 70 c0 70 60 60 60 60 60 70 60 70 c0 7f c0 6f 80 60 00 60 00 60 00 60 00 1f 00 3f 80 71 00 60 00 60 00 60 00 60 00 71 00 3f 80 1f ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); 6 record offsets give bitmap start addresses inside this region (first 0x0809b3b9, last 0x0809b43d)
	.global UNREF_0809b3b8
UNREF_0809b3b8:
	.incbin "assets/rodata.bin", 0x55164, 168
@ UNREF_0809b460: 84897 bytes (odd count), first bytes c0 7f e0 7f e0 00 20 00 20 00 20 61 80 61 80 61 80 61 80 61 80 7f 80 3f 80 01 80 01 80 01 80 61 8c 61 8c 61 8c ... | READ: glyph bitmap data: blend_glyph_into_region_buffer (0x0800fb90) calls the pointer callback with blx r2 at 0x0800fba4 and loads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; the callback for the glyph descriptor at 0x20001188 (words 0x0809a618 data base, 0x080a0468 record table, 0x080a1630 range table, from the initial RAM image (unpacked from 0x080BE480); font object 0x20001174 with callback word 0x0802f585) is the function at 0x0802f584, which loads the 8-byte record with ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 and returns the data base plus the low 20 bits of the record word (bfc r0,#20,#12 at 0x0802f5be, add r0,r0,r1 at 0x0802f5c2); glyph data of that descriptor and of the descriptor at 0x200011b8 (words 0x080a1ab8, 0x080b9000, 0x080ba1b8, font object 0x200011a4 with callback words 0x0802fa59 and 0x0802f5f9) continue through this region: 801 record offsets give bitmap start addresses inside it (first 0x0809b46b, last 0x080affe2); its record table 0x080a0468..0x080a162f and range table 0x080a1630.. are read by the same callback (ldr.w r0,[r0,r4,lsl #3] at 0x0802f5b6 for the records, ldr r2,[r0,#0], ldrh r2,[r0,#4], ldr.w lr,[r0,#8] at 0x0802f58e..0x0802f5cc for the range table)
	.global UNREF_0809b460
UNREF_0809b460:
	.incbin "assets/rodata.bin", 0x5520c, 84897
@ DATA_080b0001: 36425 bytes from the odd address 0x080b0001, first bytes fe 80 00 0a fe 8e c3 0c fa 3e ec 30 00 00 5e e5 | the reference movt.eq r0,#0x80b at 0x0801dfee in draw_page_by_selector_nibble follows movweq r0,#0xc4f2 at 0x0801dfea, so the value built is 0x080bc4f2 (text '3:/System file/74.jpg'; the ne path builds 0x080bc5cf, '3:/System file/77.jpg'), then bl 0x08039f6c; the address 0x080b0001 comes from r0 = 1 and is not loaded by any instruction | draw_page_by_selector_nibble: draws one of seven option pages with radio-style rows
	.global DATA_080b0001
DATA_080b0001:
	.incbin "assets/rodata.bin", 0x69dad, 36435
@ UNREF_080b8e54: 9624 bytes, first bytes 08 aa aa aa aa aa aa aa cf e5 00 00 00 00 00 00 00 00 00 8e e5 00 00 00 00 00 00 00 00 00 8e e5 (the pattern 8e e5 followed by 9 zero bytes repeats at 11-byte distance at the start) | READ: glyph data of the descriptors at 0x200011b8 (words 0x080a1ab8 data base, 0x080b9000 record table, 0x080ba1b8 range table, font object 0x200011a4 with callback words 0x0802fa59 and 0x0802f5f9) and 0x200011e8 (words 0x080ba63c, 0x080bb2f0, 0x080bb3a8, font object 0x200011d4 with callback words 0x0802faed and 0x0802f66d): the pointer callbacks (0x0802f5f8 and 0x0802f66c) load the 8-byte records with ldr.w r0,[r0,r4,lsl #3] and return the data base plus the low 20 bits of the record word, blend_glyph_into_region_buffer (0x0800fb90) reads the bitmap bytes with ldrb.w ip,[r0] at 0x0800fc48; 27 record offsets give bitmap start addresses inside this region (first 0x080b8e8a, last 0x080bb249), and the record tables 0x080b9000..0x080ba1b7 and 0x080bb2f0..0x080bb3a7 lie inside it
	.global UNREF_080b8e54
UNREF_080b8e54:
	.incbin "assets/rodata.bin", 0x72c00, 9624
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
@ DATA_080bb416: 86 bytes of UTF-8 text 'Ein Zurücksetzen auf die Werkseinstellungen wird alle vorherigen Änderungen rückgä' | the 32-bit word at 0x0801e174 holds 0x080bb416
	.global DATA_080bb416
DATA_080bb416:
	.incbin "assets/rodata.bin", 0x751c2, 145
@ DATA_080bb4a7: 76 bytes of UTF-8 text 'A restauração às configurações de fábrica desfará todas as alteraçõ' | the 32-bit word at 0x0801e170 holds 0x080bb4a7
	.global DATA_080bb4a7
DATA_080bb4a7:
	.incbin "assets/rodata.bin", 0x75253, 330
@ DATA_080bb5f1: 27 bytes of UTF-8 text 'Esperando Medición Automá' | the 32-bit word at 0x0804c060 holds 0x080bb5f1
	.global DATA_080bb5f1
DATA_080bb5f1:
	.incbin "assets/rodata.bin", 0x7539d, 35
@ DATA_080bb614: 28 bytes of UTF-8 text 'Aguardando Medição Automá' | the 32-bit word at 0x0804c064 holds 0x080bb614
	.global DATA_080bb614
DATA_080bb614:
	.incbin "assets/rodata.bin", 0x753c0, 36
@ DATA_080bb638: 29 bytes of UTF-8 text 'Esperando corrección automá' | the 32-bit word at 0x0804c080 holds 0x080bb638
	.global DATA_080bb638
DATA_080bb638:
	.incbin "assets/rodata.bin", 0x753e4, 37
@ DATA_080bb65d: 29 bytes of UTF-8 text 'Aguardando correção automá' | the 32-bit word at 0x0804c084 holds 0x080bb65d
	.global DATA_080bb65d
DATA_080bb65d:
	.incbin "assets/rodata.bin", 0x75409, 94
@ DATA_080bb6bb: 3 bytes of UTF-8 text 'Lö' | the 32-bit word at 0x0804c1a0 holds 0x080bb6bb
	.global DATA_080bb6bb
DATA_080bb6bb:
	.incbin "assets/rodata.bin", 0x75467, 104
@ DATA_080bb723: 17 bytes of UTF-8 text 'Warten auf Auslö' | the 32-bit word at 0x0804c048 holds 0x080bb723
	.global DATA_080bb723
DATA_080bb723:
	.incbin "assets/rodata.bin", 0x754cf, 515
	.global d_080bb926
d_080bb926:
	.incbin "assets/rodata.bin", 0x756d2, 4
	.global d_080bb92a
d_080bb92a:
	.incbin "assets/rodata.bin", 0x756d6, 28
@ DATA_080bb946: 13 bytes of UTF-8 text 'Configuraçõ' | the 32-bit word at 0x0804c8b0 holds 0x080bb946
	.global DATA_080bb946
DATA_080bb946:
	.incbin "assets/rodata.bin", 0x756f2, 50
	.global d_080bb978
d_080bb978:
	.incbin "assets/rodata.bin", 0x75724, 4
	.global d_080bb97c
d_080bb97c:
	.incbin "assets/rodata.bin", 0x75728, 26
@ DATA_080bb996: 13 bytes of UTF-8 text 'Configuraçõ' | the 32-bit word at 0x0804c8b4 holds 0x080bb996
	.global DATA_080bb996
DATA_080bb996:
	.incbin "assets/rodata.bin", 0x75742, 78
	.global d_080bb9e4
d_080bb9e4:
	.incbin "assets/rodata.bin", 0x75790, 2
	.global d_080bb9e6
d_080bb9e6:
	.incbin "assets/rodata.bin", 0x75792, 56
	.global d_080bba1e
d_080bba1e:
	.incbin "assets/rodata.bin", 0x757ca, 4
	.global d_080bba22
d_080bba22:
	.incbin "assets/rodata.bin", 0x757ce, 518
@ UNREF_080bbc28: 6 bytes of UTF-8 text, NUL-separated: 'AC|DC|' | a 32-bit word at 0x0804c7c4 holds 0x080bbc28 (offset 0x0); a 32-bit word at 0x0804c7c8 holds 0x080bbc2b (offset 0x3) | read: the text bytes are read from the pointer words by the text routines (decode_utf8_char via 0x0803a40c) until the NUL; the pointer words are loaded by ldr.w r5,[r1,r0,lsl #2] at 0x0801e8d4 and 0x0801ea24 (base 0x0804c7c4, movt at 0x0801e8d0 and 0x0801ea20)
	.global UNREF_080bbc28
UNREF_080bbc28:
	.incbin "assets/rodata.bin", 0x759d4, 10
	.global d_080bbc32
d_080bbc32:
	.incbin "assets/rodata.bin", 0x759de, 4
	.global d_080bbc36
d_080bbc36:
	.incbin "assets/rodata.bin", 0x759e2, 30
	.global d_080bbc54
d_080bbc54:
	.incbin "assets/rodata.bin", 0x75a00, 4
	.global d_080bbc58
d_080bbc58:
	.incbin "assets/rodata.bin", 0x75a04, 20
	.global d_080bbc6c
d_080bbc6c:
	.incbin "assets/rodata.bin", 0x75a18, 4
@ UNREF_080bbc70: 6 bytes of UTF-8 text, NUL-separated: '2S|5S|' | a 32-bit word at 0x0804c9ec holds 0x080bbc70 (offset 0x0); a 32-bit word at 0x0804c9f0 holds 0x080bbc73 (offset 0x3) | read: the text bytes are read from the pointer words by the text routines (decode_utf8_char via 0x0803a40c) until the NUL; the pointer words are loaded by ldr.w r2,[r1,r0,lsl #2] at 0x0801302a (base 0x0804c988, index 25 and 26 for the words at 0x0804c9ec and 0x0804c9f0) and ldr.w r0,[r7,r0,lsl #2] at 0x0801e7c0 (base 0x0804c954, index 38 and 39), neither index compared against a limit
	.global UNREF_080bbc70
UNREF_080bbc70:
	.incbin "assets/rodata.bin", 0x75a1c, 22
	.global d_080bbc86
d_080bbc86:
	.incbin "assets/rodata.bin", 0x75a32, 78
@ UNREF_080bbcd4: 90 bytes of UTF-8 text, NUL-separated: '500uS|10uS|20uS|50uS|1uS|2uS|5uS|100V|10V|20V|50V|1V|...' | a 32-bit word at 0x0804c404 holds 0x080bbd2d (offset 0x59); a 32-bit word at 0x0804c954 holds 0x080bbd21 (offset 0x4d); a 32-bit word at 0x0804c958 holds 0x080bbd26 (offset 0x52); 27 such 32-bit words in total (4-byte aligned scan of the image): 0x0801ca38, 0x0801ca40, 0x0801ca54, 0x0804bf9c, 0x0804bfa4, 0x0804bfa8, 0x0804c404 and 0x0804c954..0x0804c9c0 (20 more) | read: the text bytes are read from the pointer words by the text routines (decode_utf8_char via 0x0803a40c) until the NUL; the pointer words are loaded by ldr.w r0,[r1,r0,lsl #2] at 0x0801636e (base 0x0804c404) and ldr.w r6,[r0,r3,lsl #2] at 0x0801cb64, 0x0801cc18, 0x0801ccc0, ldr.w r0,[r7,r0,lsl #2] at 0x0801e7c0 (base 0x0804c954), ldr.w r2,[r1,r0,lsl #2] at 0x0801302a (base 0x0804c988), ldr.w r0,[r0,r4,lsl #2] at 0x0801bbbc (rows of the table at 0x0801ca24) and ldr.w r7,[r0,r3,lsl #2] at 0x0801bd7e (rows of the table at 0x0804bf88)
	.global UNREF_080bbcd4
UNREF_080bbcd4:
	.incbin "assets/rodata.bin", 0x75a80, 90
	.global d_080bbd2e
d_080bbd2e:
	.incbin "assets/rodata.bin", 0x75ada, 6
@ UNREF_080bbd34: 620 bytes of UTF-8 text, NUL-separated: 'Índice arriba|Matemática|Inicialização Automática|Nada|Tensão de Corrente Alternada|Grande Corrente Alternada|Pequeno Corrente Alternada|Onda cuadrada|Onda quad...' | a 32-bit word at 0x0804c1d8 holds 0x080bbe0b (offset 0xd7); a 32-bit word at 0x0804c1dc holds 0x080bbdf4 (offset 0xc0); a 32-bit word at 0x0804c2c8 holds 0x080bbeca (offset 0x196); 39 such addresses in total | read: the text bytes are read from the pointer words by the text routines (decode_utf8_char via 0x0803a40c) until the NUL; the pointer words are loaded by the language tables 0x0804c1c8 (ldr.w r0,[r0,#-4] at 0x08011572, 0x0801e484), 0x0804c258 (ldr.w r0,[r0,#-28] at 0x0801cdac), 0x0804c3b8 (ldr.w r0,[r0,#-4] at 0x08010fc8, 0x0801cd28), 0x0804c43c (ldr.w r0,[r0,#-48] at 0x08010b00, 0x08015c40), 0x0804c5bc (ldr.w r0,[r0,#-12] at 0x08015a5e), 0x0804c61c (ldr.w r0,[r0,#-52] at 0x080157e6), 0x0804c7e4 (ldr.w r0,[r1,r0,lsl #2] at 0x0801371c, 0x0801eb06), 0x0804c804 (ldr.w r0,[r0,#-32] at 0x08012e44) and the row table 0x0804c208 (ldr.w r1,[r2,r1,lsl #2] at 0x0801d244 then ldr.w r3,[r1,#-4] at 0x0801d252), each indexed by the byte at 0x20001058 without a limit compare
	.global UNREF_080bbd34
UNREF_080bbd34:
	.incbin "assets/rodata.bin", 0x75ae0, 772
	.global d_080bc038
d_080bc038:
	.incbin "assets/rodata.bin", 0x75de4, 8
	.global d_080bc040
d_080bc040:
	.incbin "assets/rodata.bin", 0x75dec, 78
@ DATA_080bc08e: 30 bytes of UTF-8 text 'Esperando calibración automá' | the 32-bit word at 0x0804c0c0 holds 0x080bc08e
	.global DATA_080bc08e
DATA_080bc08e:
	.incbin "assets/rodata.bin", 0x75e3a, 147
@ DATA_080bc121: 31 bytes of UTF-8 text 'Aguardando calibração automá' | the 32-bit word at 0x0804c0c4 holds 0x080bc121
	.global DATA_080bc121
DATA_080bc121:
	.incbin "assets/rodata.bin", 0x75ecd, 105
	.global d_080bc18a
d_080bc18a:
	.incbin "assets/rodata.bin", 0x75f36, 26
	.global d_080bc1a4
d_080bc1a4:
	.incbin "assets/rodata.bin", 0x75f50, 16
	.global d_080bc1b4
d_080bc1b4:
	.incbin "assets/rodata.bin", 0x75f60, 82
@ DATA_080bc206: 3 bytes of UTF-8 text 'Sä' | the 32-bit word at 0x0804c75c holds 0x080bc206
	.global DATA_080bc206
DATA_080bc206:
	.incbin "assets/rodata.bin", 0x75fb2, 133
@ DATA_080bc28b: 2 bytes of UTF-8 text 'Í' | the 32-bit word at 0x0804c740 holds 0x080bc28b
	.global DATA_080bc28b
DATA_080bc28b:
	.incbin "assets/rodata.bin", 0x76037, 181
	.global d_080bc340
d_080bc340:
	.incbin "assets/rodata.bin", 0x760ec, 5
@ UNREF_080bc345: 143 bytes of UTF-8 text, NUL-separated: 'Indexrückgang|Mehrklang|USB Sharing|Einstellung|Gleichstromspannung|Wechselstromspannung|Cursor-Messung|Parametermessung|Nachleuchtung|Grenzü' | a 32-bit word at 0x0804c284 holds 0x080bc35e (offset 0x19); a 32-bit word at 0x0804c560 holds 0x080bc376 (offset 0x31); a 32-bit word at 0x0804c564 holds 0x080bc38a (offset 0x45); 10 such 32-bit words in total (4-byte aligned scan of the image); the additional one at 0x0804c0a8 holds 0x080bc3cd (offset 0x88) | read: the text bytes are read from the pointer words by the text routines (decode_utf8_char via 0x0803a40c) until the NUL; the pointer words are loaded by ldr.w r0,[r0,#-4] at 0x08010748 (row 0x0804c398), ldr.w r0,[r0,#-28] at 0x0801cdac (0x0804c258 block, word 0x0804c284), ldr.w r0,[r0,#-4] at 0x080100d2 and 0x08012d58 (row 0x0804c934, word 0x0804c94c), ldr.w r0,[r0,#-48] at 0x08010b00 (words 0x0804c560, 0x0804c564), ldr.w r0,[r0,#-52] at 0x080157e6 (words 0x0804c774, 0x0804c77c), ldr.w r0,[r0,#-32] at 0x08012e44 (words 0x0804c8c8, 0x0804c8cc, 0x0804c8dc) and ldr.w r0,[r0,#-4] at 0x0801c9a0 (word 0x0804c0a8)
	.global UNREF_080bc345
UNREF_080bc345:
	.incbin "assets/rodata.bin", 0x760f1, 181
	.global d_080bc3fa
d_080bc3fa:
	.incbin "assets/rodata.bin", 0x761a6, 24
	.global d_080bc412
d_080bc412:
	.incbin "assets/rodata.bin", 0x761be, 22
	.global d_080bc428
d_080bc428:
	.incbin "assets/rodata.bin", 0x761d4, 22
	.global d_080bc43e
d_080bc43e:
	.incbin "assets/rodata.bin", 0x761ea, 24
	.global d_080bc456
d_080bc456:
	.incbin "assets/rodata.bin", 0x76202, 22
	.global d_080bc46c
d_080bc46c:
	.incbin "assets/rodata.bin", 0x76218, 22
	.global d_080bc482
d_080bc482:
	.incbin "assets/rodata.bin", 0x7622e, 22
	.global d_080bc498
d_080bc498:
	.incbin "assets/rodata.bin", 0x76244, 22
	.global d_080bc4ae
d_080bc4ae:
	.incbin "assets/rodata.bin", 0x7625a, 22
	.global d_080bc4c4
d_080bc4c4:
	.incbin "assets/rodata.bin", 0x76270, 24
	.global d_080bc4dc
d_080bc4dc:
	.incbin "assets/rodata.bin", 0x76288, 22
	.global d_080bc4f2
d_080bc4f2:
	.incbin "assets/rodata.bin", 0x7629e, 22
	.global d_080bc508
d_080bc508:
	.incbin "assets/rodata.bin", 0x762b4, 22
	.global d_080bc51e
d_080bc51e:
	.incbin "assets/rodata.bin", 0x762ca, 20
	.global d_080bc532
d_080bc532:
	.incbin "assets/rodata.bin", 0x762de, 24
	.global d_080bc54a
d_080bc54a:
	.incbin "assets/rodata.bin", 0x762f6, 22
	.global d_080bc560
d_080bc560:
	.incbin "assets/rodata.bin", 0x7630c, 22
	.global d_080bc576
d_080bc576:
	.incbin "assets/rodata.bin", 0x76322, 20
	.global d_080bc58a
d_080bc58a:
	.incbin "assets/rodata.bin", 0x76336, 24
	.global d_080bc5a2
d_080bc5a2:
	.incbin "assets/rodata.bin", 0x7634e, 22
	.global d_080bc5b8
d_080bc5b8:
	.incbin "assets/rodata.bin", 0x76364, 22
	.global d_080bc5ce
d_080bc5ce:
	.incbin "assets/rodata.bin", 0x7637a, 22
	.global d_080bc5e4
d_080bc5e4:
	.incbin "assets/rodata.bin", 0x76390, 24
	.global d_080bc5fc
d_080bc5fc:
	.incbin "assets/rodata.bin", 0x763a8, 22
	.global d_080bc612
d_080bc612:
	.incbin "assets/rodata.bin", 0x763be, 22
	.global d_080bc628
d_080bc628:
	.incbin "assets/rodata.bin", 0x763d4, 22
	.global d_080bc63e
d_080bc63e:
	.incbin "assets/rodata.bin", 0x763ea, 22
	.global d_080bc654
d_080bc654:
	.incbin "assets/rodata.bin", 0x76400, 22
	.global d_080bc66a
d_080bc66a:
	.incbin "assets/rodata.bin", 0x76416, 22
	.global d_080bc680
d_080bc680:
	.incbin "assets/rodata.bin", 0x7642c, 46
	.global d_080bc6ae
d_080bc6ae:
	.incbin "assets/rodata.bin", 0x7645a, 16
@ UNREF_080bc6be: 107 bytes of UTF-8 text, NUL-separated: 'Mathematik|Pulso Sink|Onda senoidal|Onda sinusoidal|descenso exponencial|Normal|Cancel|Kleiner Gleichstrom|' | a 32-bit word at 0x0804c57c holds 0x080bc715 (offset 0x57); a 32-bit word at 0x0804c6ec holds 0x080bc6e2 (offset 0x24); a 32-bit word at 0x0804c70c holds 0x080bc6f2 (offset 0x34); 9 such 32-bit words in total (4-byte aligned scan of the image); the additional one at 0x0801f2a8 holds 0x080bc70e (offset 0x50) | read: the text bytes are read from the pointer words by the text routines (decode_utf8_char via 0x0803a40c) until the NUL; the pointer words are loaded by ldr.w r0,[r0,#-32] at 0x08012e44 (word 0x0804c8e0), ldr.w r0,[r0,#-52] at 0x080157e6 (words 0x0804c6ec, 0x0804c70c, 0x0804c718, 0x0804c720, 0x0804c74c), ldr.w r0,[r1,r0,lsl #2] at 0x0801371c and 0x0801eb06 (word 0x0804c7f0), ldr.w r5,[r0,#-4] at 0x0801f23a (word 0x0801f2a8) and ldr.w r0,[r0,#-48] at 0x08010b00 (words 0x0804c57c, 0x0804c584)
	.global UNREF_080bc6be
UNREF_080bc6be:
	.incbin "assets/rodata.bin", 0x7646a, 107
@ DATA_080bc729: 5 bytes of UTF-8 text 'Groß' | the 32-bit word at 0x0804c584 holds 0x080bc729
	.global DATA_080bc729
DATA_080bc729:
	.incbin "assets/rodata.bin", 0x764d5, 41
@ DATA_080bc752: 5 bytes of UTF-8 text 'Groß' | the 32-bit word at 0x0804c588 holds 0x080bc752
	.global DATA_080bc752
DATA_080bc752:
	.incbin "assets/rodata.bin", 0x764fe, 53
@ DATA_080bc787: 6 bytes of UTF-8 text 'Bestä' | the 32-bit word at 0x0801f29c holds 0x080bc787
	.global DATA_080bc787
DATA_080bc787:
	.incbin "assets/rodata.bin", 0x76533, 126
@ DATA_080bc805: 3 bytes of UTF-8 text 'Lö' | the 32-bit word at 0x0801f27c holds 0x080bc805
	.global DATA_080bc805
DATA_080bc805:
	.incbin "assets/rodata.bin", 0x765b1, 59
	.global d_080bc840
d_080bc840:
	.incbin "assets/rodata.bin", 0x765ec, 24
	.global d_080bc858
d_080bc858:
	.incbin "assets/rodata.bin", 0x76604, 322
@ DATA_080bc99a: 13 bytes of UTF-8 text 'Configuraçõ' | the 32-bit word at 0x0804c8b8 holds 0x080bc99a
	.global DATA_080bc99a
DATA_080bc99a:
	.incbin "assets/rodata.bin", 0x76746, 63
@ DATA_080bc9d9: 13 bytes of UTF-8 text 'Configuració' | the 32-bit word at 0x0804c914 holds 0x080bc9d9
	.global DATA_080bc9d9
DATA_080bc9d9:
	.incbin "assets/rodata.bin", 0x76785, 96
@ DATA_080bca39: 13 bytes of UTF-8 text 'Configuració' | the 32-bit word at 0x0804c898 holds 0x080bca39
	.global DATA_080bca39
DATA_080bca39:
	.incbin "assets/rodata.bin", 0x767e5, 26
@ DATA_080bca53: 6 bytes of UTF-8 text 'Multí' | the 32-bit words at 0x0804c368 and 0x0804c36c both hold 0x080bca53
	.global DATA_080bca53
DATA_080bca53:
	.incbin "assets/rodata.bin", 0x767ff, 127
	.global d_080bcad2
d_080bcad2:
	.incbin "assets/rodata.bin", 0x7687e, 18
	.global d_080bcae4
d_080bcae4:
	.incbin "assets/rodata.bin", 0x76890, 159
@ DATA_080bcb83: 8 bytes of UTF-8 text 'Medició' | the 32-bit word at 0x0804c888 holds 0x080bcb83
	.global DATA_080bcb83
DATA_080bcb83:
	.incbin "assets/rodata.bin", 0x7692f, 20
@ DATA_080bcb97: 8 bytes of UTF-8 text 'Mediçã' | the 32-bit word at 0x0804c8a8 holds 0x080bcb97
	.global DATA_080bcb97
DATA_080bcb97:
	.incbin "assets/rodata.bin", 0x76943, 121
	.global d_080bcc10
d_080bcc10:
	.incbin "assets/rodata.bin", 0x769bc, 22
@ DATA_080bcc26: 7 bytes of UTF-8 text 'Matemá' | the 32-bit word at 0x0804c8a0 holds 0x080bcc26
	.global DATA_080bcc26
DATA_080bcc26:
	.incbin "assets/rodata.bin", 0x769d2, 24
	.global d_080bcc3e
d_080bcc3e:
	.incbin "assets/rodata.bin", 0x769ea, 295
@ DATA_080bcd65: 18 bytes of UTF-8 text 'Medición de pará' | the 32-bit word at 0x0804c88c holds 0x080bcd65
	.global DATA_080bcd65
DATA_080bcd65:
	.incbin "assets/rodata.bin", 0x76b11, 25
@ DATA_080bcd7e: 18 bytes of UTF-8 text 'Medição de parâ' | the 32-bit word at 0x0804c8ac holds 0x080bcd7e
	.global DATA_080bcd7e
DATA_080bcd7e:
	.incbin "assets/rodata.bin", 0x76b2a, 511
@ DATA_080bcf7d: 4 bytes e7 9b b4 e6 = UTF-8 for U+76F4 followed by the lead byte 0xe6; the bytes 0x080bcf81 (b5) and 0x080bcf82 (81) complete U+6D41, then e5 a4 a7 (U+5927) at 0x080bcf83..0x080bcf85 and the bytes of UNREF_080bcf86 follow, so the NUL-terminated text at 0x080bcf7d reads '直流大电流' | the 32-bit word at 0x0804c464 holds 0x080bcf7d
	.global DATA_080bcf7d
DATA_080bcf7d:
	.incbin "assets/rodata.bin", 0x76d29, 5
@ UNREF_080bcf82: 3 bytes 81 e5 a4 = the last byte of the UTF-8 sequence e6 b5 81 (U+6D41) that starts at 0x080bcf80, followed by the first two bytes of the sequence e5 a4 a7 (U+5927) that is completed by the byte 0x080bcf85 | READ: part of the NUL-terminated text that starts at 0x080bcf7d (pointer word 0x080bcf7d at 0x0804c464, read as idx = 1 col 10 of the 12-word-per-idx table 0x0804c43c by ldr.w r0,[r0,#-48] at 0x08010b00 / 0x08015c40: address = 0x0804c43c + 48*(idx-1) + 4*col = 0x0804c464 for idx = 1, col = 10); the text bytes are read from the pointer by the text routines (decode_utf8_char via 0x0803a40c) until the NUL, so these bytes are read
	.global UNREF_080bcf82
UNREF_080bcf82:
	.incbin "assets/rodata.bin", 0x76d2e, 4
@ UNREF_080bcf86: 29 bytes of UTF-8 text, NUL-separated: '电流|大きい交流電流|' | a 32-bit word at 0x0804c4f8 holds 0x080bcf8d (offset 0x7) | READ: part of NUL-terminated texts reached through the words 0x080bcf8d at 0x0804c4f8 (idx = 4, col 11 of the table 0x0804c43c read by ldr.w r0,[r0,#-48] at 0x08010b00 / 0x08015c40) and 0x080bcf7d at 0x0804c464 (idx = 1, col 10; the text from 0x080bcf7d runs through this region); the text bytes are read from the pointer by the text routines (decode_utf8_char via 0x0803a40c) until the NUL, so these bytes are read
	.global UNREF_080bcf86
UNREF_080bcf86:
	.incbin "assets/rodata.bin", 0x76d32, 29
@ DATA_080bcfa3: 21 bytes of UTF-8 text '小さい交流電流' | the 32-bit word at 0x0804c4f0 holds 0x080bcfa3
	.global DATA_080bcfa3
DATA_080bcfa3:
	.incbin "assets/rodata.bin", 0x76d4f, 25
@ UNREF_080bcfbc: 19 bytes of UTF-8 text, NUL-separated: 'きい直流電流|' | READ: part of the NUL-terminated text that starts at 0x080bcfb9 (word 0x080bcfb9 at 0x0804c4f4 = idx = 4 col 10 of the table 0x0804c43c read by ldr.w r0,[r0,#-48] at 0x08010b00 / 0x08015c40: address = 0x0804c43c + 48*(idx-1) + 4*col); the text bytes are read from the pointer by the text routines (decode_utf8_char via 0x0803a40c) until the NUL, so these bytes are read
	.global UNREF_080bcfbc
UNREF_080bcfbc:
	.incbin "assets/rodata.bin", 0x76d68, 19
@ DATA_080bcfcf: 9 bytes of UTF-8 text '小さい' | the 32-bit word at 0x0804c4ec holds 0x080bcfcf
	.global DATA_080bcfcf
DATA_080bcfcf:
	.incbin "assets/rodata.bin", 0x76d7b, 13
@ UNREF_080bcfdc: 9 bytes of UTF-8 text, NUL-separated: '\xb5\x81電流|' | READ: part of the NUL-terminated text that starts at 0x080bcfcf (word 0x080bcfcf at 0x0804c4ec = idx = 4 col 8 of the table 0x0804c43c read by ldr.w r0,[r0,#-48] at 0x08010b00 / 0x08015c40); the text bytes are read from the pointer by the text routines (decode_utf8_char via 0x0803a40c) until the NUL, so these bytes are read
	.global UNREF_080bcfdc
UNREF_080bcfdc:
	.incbin "assets/rodata.bin", 0x76d88, 9
@ DATA_080bcfe5: 3 bytes of UTF-8 text 'バ' | the 32-bit word at 0x0804c1d4 holds 0x080bcfe5
	.global DATA_080bcfe5
DATA_080bcfe5:
	.incbin "assets/rodata.bin", 0x76d91, 7
@ UNREF_080bcfec: 18 bytes of UTF-8 text, NUL-separated: '\xae\x8b低、充電！|' | READ: part of the NUL-terminated text that starts at 0x080bcfe5 (word 0x080bcfe5 at 0x0804c1d4 = idx = 4 of the 8-word row 0x0804c1c8..0x0804c1e7 read by ldr.w r0,[r0,#-4] at 0x08011572 / 0x0801e484 with r0 = 0x0804c1c8 + 4*idx); the text bytes are read from the pointer by the text routines (decode_utf8_char via 0x0803a40c) until the NUL, so these bytes are read
	.global UNREF_080bcfec
UNREF_080bcfec:
	.incbin "assets/rodata.bin", 0x76d98, 174
	.global d_080bd09a
d_080bd09a:
	.incbin "assets/rodata.bin", 0x76e46, 1350
@ DATA_080bd5e0: 4 bytes ed 81 b0 20 = UTF-8 for U+D070 followed by a space (0x20) | the 32-bit word at 0x0804c5b8 holds 0x080bd5e0
	.global DATA_080bd5e0
DATA_080bd5e0:
	.incbin "assets/rodata.bin", 0x7738c, 8
@ UNREF_080bd5e8: 10 bytes of UTF-8 text, NUL-separated: '\xa5\x98 전류|' | READ: part of the NUL-terminated text that starts at 0x080bd5e0 (word 0x080bd5e0 at 0x0804c5b8, read by ldr.w r0,[r0,#-12] at 0x08015a5e with r0 = 0x0804c5bc + 12*idx + 4*r8 (add.w at 0x08015a4e and 0x08015a56): 0x0804c5bc + 12*0 + 4*2 - 12 = 0x0804c5b8 for idx = 0 (the initial value of the byte at 0x20001058 in the initial RAM image (unpacked from 0x080BE480) is 0) and r8 = 2); the text bytes are read from the pointer by the text routines (decode_utf8_char via 0x0803a40c) until the NUL, so these bytes are read
	.global UNREF_080bd5e8
UNREF_080bd5e8:
	.incbin "assets/rodata.bin", 0x77394, 922
@ UNREF_080bd982: 22 bytes of UTF-8 text, NUL-separated: '系统设置|示波器' | a 32-bit word at 0x0804c3b8 holds 0x080bd982 (offset 0x0); a 32-bit word at 0x0804c904 holds 0x080bd98f (offset 0xd) | read: the text bytes are read from the pointer words by the text routines (decode_utf8_char via 0x0803a40c) until the NUL; the pointer words are loaded by ldr.w r0,[r0,#-4] at 0x08010fc8 and 0x0801cd28 (word 0x0804c3b8, base 0x0804c3b8 + 4*idx - 4) and ldr.w r0,[r0,#-4] at 0x08010374 and 0x08012db0 (word 0x0804c904, row 0x0804c904)
	.global UNREF_080bd982
UNREF_080bd982:
	.incbin "assets/rodata.bin", 0x7772e, 1754
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
	.incbin "assets/rodata.bin", 0x780be, 14
.Lsw_080be320:
	.word unpack_token_stream_addr                     @ 0x080be320 = 0x080071c0
@ UNREF_080be324: 20 bytes = 5 words 0x080be680, 0x20001240, 0x00035d50, 0x0800721c, 0x0000001c; the words before it at 0x080be314 are 0x080be480, 0x20000000, 0x00001240, 0x080071c0, i.e. the same source/destination/length as the table entry read by the routine at 0x0800718c (ldm.w at 0x080071a6), and 0x080be680 is the byte after DATA_080be480 | no reference found
	.global UNREF_080be324
UNREF_080be324:
	.incbin "assets/rodata.bin", 0x780d0, 12
.Lsw_080be330:
	.word zero_fill_words_addr                         @ 0x080be330 = 0x0800721c
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
@ DATA_080be480: 512 bytes, first bytes 1a aa 01 75 64 aa 55 05 43 0a 40 13 12 7a 12 70 49 13 72 0a 72 20 18 0e | the source of the first block of the scatter-load table: words 0x080be480 (source), 0x20000000 (destination), 0x1240 (length), 0x080071c0 at 0x080be314..0x080be323 and the next block starts at 0x080be680 = 0x080be480 + 512 | ldm.w r10!,{r0,r1,r2,r3} at 0x080071a6 in the routine at 0x0800718c | routine at 0x0800718c: reads r0..r3 from the table (ldm.w at 0x080071a6) and branches with bx r3 (0x080071b6, lr set by subw lr,pc,#9 at 0x080071a2) to the routine at 0x080071c0 with source 0x080be480, destination 0x20000000, length 0x1240
	.global DATA_080be480
DATA_080be480:
	.incbin "assets/rodata.bin", 0x7822c, 512
	.global rodata_end
rodata_end:
