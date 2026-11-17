@ system_58.s - system_bring_up, part 1 of 4: clock/port set-up, LCD controller init, splash picture loop start
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ system_bring_up - one-shot system bring-up routine (no parameters). Original
@ range 0x0802aa50..0x0802e6cd, ending with b.w 0x080416d8 at 0x0802e6ca (after
@ ldmia.w sp!,{r4-r11,lr} at 0x0802e6c6); that b.w is a tail jump into the
@ split-off function fn_080416d8 (0x080416d8..0x08041789), which is not part of
@ this function's body. r0..r3 are written (0x0802aa5c..0x0802ac20) before any
@ read. Straight-line code without an outer loop. The value returned to the
@ caller is produced in fn_080416d8: at its 0x0804177c r0 is the word at
@ 0x0804be70 (bytes 04 00 00 00, value 4).
@
@ Port-bit setups are calls to set_nibble_fields_from_bit_mask (0x080372fc)
@ with (block, record): record = u16 mask at +0 and bytes +4..+7 (the routine
@ edits 4-bit fields in the words at block offsets 0 and 4 for the mask bits
@ and, when byte +6 is 0 and byte +5 is 0x18 / 0x28, writes the mask to block
@ offset 16 / 20). All 47 calls in code order as call address, block / mask /
@ bytes +4..+7:
@  0x0802aab2 40011000/0x200/00181001   0x0802ab04 40010c00/0x80/00280001
@  0x0802ab18 40011000/0x2100/00180001  0x0802ab2e 40010800/0x180/00181002
@  0x0802ab3c 40010c00/0x1/00181002     0x0802ab4a 40011000/0x420/00181002
@  0x0802ab5e 40011800/0xc/00181002     0x0802abc2 40011400/0xc703/00040801
@  0x0802abd2 40011800/0xff80/00040801  0x0802abec 40011400/0x40/00041001
@  0x0802abfe 40011400/0x8b0/00040801   0x0802b118 40011000/0x80/00180001
@  0x0802b12c 40011000/0x4000/00180001  0x0802b1d0 40010c00/0x100/00040801
@  0x0802b1de 40010c00/0x200/00040801   0x0802b1f0 40010800/0x40/00040801
@  0x0802c238 40010800/0x10/00040301    0x0802c384 40010c00/0x2/00040301
@  0x0802c4ce 40011000/0x1000/00181001  0x0802c4e2 40011800/0x10/00181001
@  0x0802c4ee 40011800/0x20/00181001    0x0802c4fa 40011800/0x40/00181001
@  0x0802c510 40010800/0x8000/00181001  0x0802c520 40010c00/0x800/00181001
@  0x0802c52e 40010c00/0x400/00181001   0x0802c538 40010800/0x400/00181001
@  0x0802c57c 40011400/0x1000/00181001  0x0802c58a 40011400/0x2000/00181001
@  0x0802c5f4 40011000/0x4/00181001     0x0802c600 40011000/0x2/00181001
@  0x0802c69e 40011400/0x8/00181001     0x0802c6ae 40011400/0x4/00181001
@  0x0802c6e2 40010800/0x2/00040001     0x0802c6ee 40010800/0x1/00040001
@  0x0802c71a 40011000/0x800/00181001   0x0802c74a 40011000/0x8/00180001
@  0x0802c83e 40010800/0x4/00040801     0x0802c854 40010800/0x8/00180001
@  0x0802c97a 40010800/0x20/00040301    0x0802d580 40010c00/0x40/00181001
@  0x0802d594 40010c00/0x8/00180801     0x0802d5a6 40010c00/0x10/00180001
@  0x0802d5b6 40010c00/0x20/00180801    0x0802d634 40011000/0x40/00181001
@  0x0802de66 40011000/0x1/00040001     0x0802de76 40011000/0x10/00041001
@  0x0802e524 40010800/0x200/00040801
@
@ Writes before the port-pair init: 0x40021018 |= 0x10; setup 0x0802aab2;
@ 0x40011014 = 0x200; 0x40021018 |= 4, |= 8, |= 0x10, |= 0x40; setups
@ 0x0802ab04..0x0802ab5e; 0x40021018 |= 0x20, |= 0x40, |= 1; 0x40021014
@ |= 0x100; 0x40010030 |= 0x8000000; setups 0x0802abc2..0x0802abfe;
@ 0xa0000000 = 0x5010, 0xa0000004 = 0x2020424, 0xa0000104 = 0x202,
@ 0xa0000220 = (old & ~0xff00) then low byte = 8, 0xa0000000 |= 1;
@ 0x40011410 = 0x40, delay 10 units, 0x40011414 = 0x40, delay 20 units,
@ 0x40011410 = 0x40, delay 20 units.
@
@ Delay (inline copies; unit = word 0x20002b20): write 0xE000E014 = unit*N,
@ 0xE000E018 = 0, 0xE000E010 |= 1, spin while (0xE000E010 & 0x10001) == 1,
@ then 0xE000E010 &= ~1 and 0xE000E018 = 0; an N above 50 runs chunks of 50
@ and then the remainder (N = 100: 50, 50; N = 120: 50, 50, 20; N = 500: ten
@ chunks of 50); N used: 1, 2, 3, 5, 10, 20, 30, 50, 100, 120, 500; the delay
@ at 0x0802d638 uses word 0x20002b1c * 10.
@
@ Port pair (index 0x6001fffe, data 0x60020000, halfword stores): index 0x11,
@ delay 120; then index:data bytes 0x36:00, 0x3a:55, 0xb2:0c 0c 00 33 33,
@ 0xb7:46, 0xbb:1b, 0xc0:2c, 0xc2:01, 0xc3:0f, 0xc4:20, 0xc6:0f, 0xd0:a4 a1,
@ 0xd6:a1, 0xe0:f0 00 06 04 05 05 31 44 48 36 12 12 2b 34, 0xe1:f0 0b 0f 0f
@ 0d 26 31 43 47 38 14 14 2c 32, index 0x29; RAM byte 0x20008346 = 1,
@ halfwords 0x20008340 = 0x140, 0x20008342 = 0xf0, 0x20008348 = 0x2c,
@ 0x2000834a = 0x2a, 0x2000834c = 0x2b; index 0x36:a0; index 0x2a:00 00 01 3f;
@ index 0x2b:00 00 00 ef; index 0x2a:00 00 01 40; index 0x2b:00 00 00 f0 (the
@ last two take the end values from the RAM halfwords 0x20008340 /
@ 0x20008342); index 0x2c; then 0x4b00 passes of 4 data writes of 0 (76800 =
@ 0x140 * 0xf0); delay 100.
@
@ Memory and calls: 0x40021018 |= 0x10 twice; setups 0x0802b118, 0x0802b12c;
@ zero_bytes(word 0x2000107c, 0x2bc0); byte 0x20001080 = 1;
@ serial_device_interface_init() and filesystem_startup_setup() (what they do
@ is not determined from this function); word 0x20036b80 = 0x0803a23d
@ (write_pixel_window_to_port); compute_clock_frequencies(buffer sp+0x40)
@ fills 5 words clk[0..4]; 0x40021018 |= 8, |= 0x100000, |= 8, |= 0x200000,
@ |= 4; 0x4002101c |= 0x80; setups 0x0802b1d0, 0x0802b1de, 0x0802b1f0;
@ 0x4001502c = 99; 0x40015028 = (clk[1]*0x431bde83 >> 50) - 1; 0x40015014
@ |= 1; 0x40015000 &= ~0x70; 0x40015004 &= ~0x100 then |= 0x100; 0x40015018
@ |= 0x70; 0x40015020 |= 3; 0x40015034 = 100; 0x40015044 |= 0x8000;
@ 0x40015000 |= 1; 0x4001542c = 0x18; 0x40015428 =
@ (((clk[1]>>4)*0x0a7c5ac5) >> 39) - 1; 0x40015414 |= 1; 0x40015400 &= ~0x70;
@ 0x40015404 &= ~0x100 then |= 0x100; 0x40015418 |= 0x70; 0x40015420 |= 3;
@ 0x40015434 = 0; 0x40015444 |= 0x8000; 0x40015400 |= 1; 0x40001c2c = 0xffe;
@ 0x40001c28 = 0; 0x40001c14 |= 1; 0x40001c00 &= ~0x70; 0x40001c04 &= ~0x100
@ then |= 0x100; 0x40001c18 |= 0x70; 0x40001c20 |= 3; 0x40001c34 = 0;
@ 0x40001c44 |= 0x8000; 0x40001c00 |= 1.
@
@ Picture loop: b starts at 0, is incremented before use and set to 0 when it
@ then exceeds 0x18; each pass formats "3:/System file/%d.jpg" (0x080bc681)
@ with (b/5 + 0xa3) & 0xff via format_to_buffer_080073b4 into buffer
@ 0x20008360; when bit 7 of 0x40011008 is clear it calls
@ decode_image_file_with_offset(buffer, 0x50, 0x52); when bit 7 is set it
@ calls it with "3:/System file/162.jpg" (0x0802c094), 0x50, 0x52 only if bit
@ 14 of 0x40011008 is clear; the pass repeats while bit 8 of 0x40011008 is
@ set; once it reads clear a delay of 5 units follows and the loop restarts
@ if bit 8 is set again; then 0x40011010 = 0x200, word 0x20036b80 =
@ 0x0803a23d, alloc_units_of_32_bytes(1) and alloc_units_of_32_bytes(0x102c),
@ file_open(second buffer, "2:/LOGO/LOGO2C53T.jpg" (0x080bc66b), 0) and the
@ result byte is stored in the first buffer.
@
@ When that result is 0: 0x40015034 = 0, decode_image_file_with_offset(
@ "2:/LOGO/LOGO2C53T.jpg", 0, 0), 0x40015034 = byte 0x20001059, delay 500,
@ 0x08034014(second buffer); otherwise: window index 0x2a 0..0x140 and 0x2b
@ 0..0xf0 (end values from the RAM halfwords), index 0x2c and 76800 data
@ writes of 0, then level v = 0, 8, .., 0xf8, 0xff (next v = v + 8 while v <
@ 247, else 0xff; loop ends after 0xff): fn_080092dc(value ((v*31/255)<<11) |
@ ((v*63/255)<<5) | (v*31/255), buffer sp+0x40) fills the 16-halfword lookup
@ table, then a rectangle x = 0x37..0xf8 (97 pixel pairs per row, first of a
@ pair at x, second at x+1), y = 0x67..0x89 is written pixel by pixel from the
@ 4-bit-per-pixel table 0x0804ca24 (high nibble for even index, low nibble
@ for odd index, one lookup-table entry per nibble; window indexes 0x2a / 0x2b
@ with the pixel position, then index 0x2c and one halfword), with a delay of
@ 3 units after every level except 0xff; then the lookup table is replaced
@ by the 8 words 0x08610000, 0x296518e3, 0x4a6939e7, 0x6b6d5aeb, 0x8c717bef,
@ 0xad759cf3, 0xce79bdf7, 0xef7ddefb; for i = 0, 1, 2 the 4-bit picture
@ (tables 0x0804d767, 0x0804d799, 0x0804d7c1 for i = 0, 1, 2) described by the
@ 4 halfwords at 0x0804ca0c + 8*i (+0 x origin, +2 y target, +4 width, +6
@ height; bytes per row = (width+1)/2) moves down one row per step: counter c
@ runs from 1 - height to the y target, rows y = 0 .. c+height-1 (c <= 0,
@ starting at picture row -c) or y = c .. c+height-1 (c > 0, after writing
@ colour 0 across the width at y = c-1) are redrawn, with a delay of 2 units
@ between steps (none after the last); then for column c = 0..209 (x = 0x37 +
@ c) and k = 0..3 (picture k at 0x0804ca04 + 8*k, tables 0x0804ca24,
@ 0x0804d767, 0x0804d799, 0x0804d7c1) every picture row of column x is written
@ when x0 - 0x37 <= c < x0 - 0x37 + width, after fn_080092dc(halfword k of the
@ table 0x0802c0ac = 0x4d3f, 0xfd88, 0x56f7, 0x4d3f, buffer sp+0x40); a delay
@ of 3 units follows every column.
@
@ Cleanup at 0x0802c134: for the first buffer (always) and the second buffer
@ (when non-zero): if byte 0x20001080 is 0 the word 0x20001070 is called as a
@ function with argument 0, else when ((buffer - word 0x20001078) >> 10) <
@ 0xaf and the halfword h at word 0x2000107c + ((buffer - word 0x20001078) >>
@ 5) * 2 is non-zero, zero_bytes(that address, h * 2) is called; then word
@ 0x20036b80 = 0x0803a175, delay 30 units.
@
@ Block 0x40007400 setup: 0x4002101c |= 0x20000000; 0x40021018 |= 4; setup
@ 0x0802c238; 0x40007400 |= 0x38, |= 4, &= ~0xc0, &= ~2, &= ~0x1000, |= 1;
@ with b = byte 0x20000125, i1 = byte 0x200000fa, i2 = byte 0x200000fb, m =
@ byte 0x2000010c, pair A (hi, lo) = (0x20000394, 0x20000358) when b >= 5,
@ (0x200003a8, 0x2000036c) when b < 5 and (b == 4 or m == 3), (0x200003bc,
@ 0x20000380) for other b < 5, and pair B = (0x2000040c, 0x200003d0) /
@ (0x20000420, 0x200003e4) / (0x20000434, 0x200003f8) under the same three
@ conditions: 0x40007408 = (old & 0xfffff000) | (trunc(float(u16 hi[i1] - u16
@ lo[i1]) / 200.0 * float(s8 0x200000fc + 100) + float(u16 lo[i1])) & 0xfff)
@ (200.0 literal at 0x0802c0b4); 0x40007404 |= 1; 0x40001c34 =
@ trunc(float(u16 hiB[i2] - u16 loB[i2]) / 200.0 * float(s8 0x200000fd + 100)
@ + float(u16 loB[i2])) (u16 table[i] is the halfword at table + 2*i; the same
@ RAM halfword tables are read by 0x080293bc).
@
@ Next writes: 0x40021018 |= 8; setup 0x0802c384; 0x40021018 |= 0x200;
@ 0x40021004 bits 15:14 = 2 and &= ~0x10000000; 0x40012404 &= ~0xf0000 then
@ |= 0x100; 0x40012408 |= 2 then &= ~0x800; 0x4001242c &= ~0xf00000;
@ 0x40012410 |= 0x38000000; 0x40012434 bits 4:0 = 9; 0x40012408 &=
@ ~0x2000000, |= 0xe0000, |= 0x100000, |= 0x100, |= 1, |= 8, wait until bit 3
@ reads clear, |= 4, wait until bit 2 reads clear; 0x40021018 |= 0x10, 0x40,
@ 0x40, 0x40, 4, 8, 8, 4; setups 0x0802c4ce..0x0802c538; 0x080088a4(byte
@ 0x200000fa); 0x08008a58(byte 0x200000fb); 0x40021018 |= 0x20 twice; setups
@ 0x0802c57c, 0x0802c58a; 0x40011410 = 0x1000 when byte 0x200000f8 is
@ non-zero else 0x40011414 = 0x1000; 0x40011410 = 0x2000 when byte 0x200000f9
@ is non-zero else 0x40011414 = 0x2000; 0x40021018 |= 0x10 twice; setups
@ 0x0802c5f4, 0x0802c600; by byte 0x2000010c: 3 gives 0x40011010 = 4 then
@ 0x40011014 = 2, 2 gives 0x40011014 = 4 then 2, 1 gives 0x40011010 = 4 then
@ 2, other values none; 0x40021018 |= 0x20 twice; setups 0x0802c69e,
@ 0x0802c6ae; 0x40011410 = 8; 0x40021018 |= 4 twice; setups 0x0802c6e2,
@ 0x0802c6ee; 0x40021018 |= 0x10; setup 0x0802c71a; 0x40011014 = 0x800;
@ 0x40021018 |= 0x10; setup 0x0802c74a; 0x40021018 |= 1 and |= 0x10;
@ 0x40010008 &= ~0xf000 then |= 0x2000; 0x40010400 &= ~8; 0x40010404 &= ~8;
@ 0x40010400 |= 8; 0x40010408 &= ~8; 0x4001040c &= ~8; 0x40010408 |= 8.
@
@ NVIC and further blocks: g = bits 10:8 of 0xE000ED0C (read each time) and
@ enc(m) = ((m & ~(-1 << min(4, g^7))) << (g < 3 ? 0 : g-3)) << 4; byte
@ 0xE000E409 = enc(1), 0xE000E100 = 0x200; 0x4002101c |= 0x20000; 0x40021018
@ |= 4 twice; setups 0x0802c83e, 0x0802c854; byte 0xE000E426 = enc(1),
@ 0xE000E104 = 0x40; 0x40004408 low halfword = x/10, plus 1 when x mod 10 >
@ 4, with x = (clk[3]*10*0x1b4e81b5) >> 42 (upper half kept); 0x4000440c &=
@ ~0x1000; 0x40004410 &= ~0x3000; 0x4000440c |= 8, |= 4, |= 0x20, &= ~0x2000;
@ 0x4002101c |= 0x20; 0x40021014 |= 2; 0x4002101c |= 0x20000000; 0x40021018
@ |= 4; setup 0x0802c97a; compute_clock_frequencies(buffer) again; r = word
@ 0x20000f54 * 200: when r < 4000 the divisor is float(r) * 10.0 and
@ 0x4000142c = 19, else the divisor is float(r) and 0x4000142c = 1;
@ 0x40001428 = trunc(float(clk[0]) / divisor - 1.0); 0x40001414 |= 1;
@ 0x40001400 &= ~0x70; 0x40001404 bits 6:4 = 2; 0x40007400 bits 21:19 = 2,
@ |= 0x40000, &= ~0xc00000, &= ~0x20000, |= 0x10000000; 0x40020444 &= ~1;
@ 0x40020444 = 0; 0x40020448 = 0; 0x4002044c = 0; 0x40020450 = 0;
@ 0x40020404 |= 0xf000; 0x40020444 &= 0xbfef, |= 0x10, &= ~0x3000, bits 11:10
@ = 1, bits 9:8 = 2, |= 0x80, &= ~0x40, |= 0x20; 0x40020448 = 100;
@ 0x4002044c = 0x40007414; 0x40020450 = 0x20000f5a; when bit 24 of 0x400204a4
@ is clear it is set; 0x400204a0 bits 31:24 = 6; 0x40020444 |= 1; 0x40007400
@ |= 0x10000; 0x40001400 |= 1; 0x40021030 |= 0x2000000; 0x40021054 |= 0x200
@ then |= 0x100; 0x40021018 |= 0x400000; 0x4001580c = 0x1f2c; 0x40015810 =
@ 8000; 0x40015814 = 0x1f54; 0x40015804 |= 2 then |= 1; 0x4002101c |=
@ 0x800000; byte 0xE000E414 = 0; 0xE000E100 = 0x100000.
@
@ Objects: 0x20002b24 = 0x40005c00, 0x20002b28 = 0x20000030, 0x20002b2c =
@ 0x20000058, byte 0x20002d48 = 1; 0x08040990(r0 = 0x20000030, r1 =
@ 0x20000058, r2 = 0x40005c00); with the word at 0x20002b24 as base: [0x40]
@ &= ~1, [0x44] = 0, [0x50] = 0, [0x4c] = 0x80, [0x40] |= 0x9e00, [0x40] &=
@ ~2, [0x60] &= ~2; then 0x40005c40 |= 2 and 0x40005c60 |= 2;
@ 0x08041b74(a, b, c) results into 0x20002d6c (0x14, 1, 0), 0x20002d70 (0xf,
@ 1, 0), 0x20002d74 (10, 2, 0), 0x20002d78 (0xf, 1, 0), 0x20002d7c,
@ 0x20002d80, 0x20002d84 (each 1, 0, 3); 0x08042d88(name, 10, 0x080400b9)
@ "Timer1" into 0x20002d88 and 0x08042d88(name, 1000, 0x080406c9) "Timer2"
@ into 0x20002d8c; 0x080426a0(entry, name, 3rd, 4th, stack argument = address
@ where the result is stored) for "display" (0x0803da51, 0x180, 1,
@ 0x20002d90), "key" (0x08040009, 0x80, 4, 0x20002d94), "osc" (0x0804009d,
@ 0x100, 2, 0x20002d98), "fpga" (0x0803e455, 0x80, 3, 0x20002d9c), "dvom_TX"
@ (0x0803e3f5, 0x40, 2, 0x20002da0), "dvom_RX" (0x0803dac1, 0x80, 3,
@ 0x20002da4); 0x08041cf0(word 0x20002d80, 0, 0); 0x080423a8(word
@ 0x20002d7c, 0); 0x080423a8(word 0x20002d84, 0).
@
@ Load from 0x08006000: when the low byte of word 0x08006000 is 0x55 or 0xaa
@ (0xaa first sets byte 0x20001060 = 8) copies word 0x08006000: byte 1 to
@ 0x200000f8, byte 2 to 0x200000f9, byte 3 to 0x200000fa; word 0x08006004 to
@ word 0x200000fb; word 0x08006008: byte 0 to 0x200000ff, byte 1 to
@ 0x2000010c, byte 2 to 0x2000010e, byte 3 to 0x2000010f; word 0x0800600c:
@ byte 0 to 0x20000110, byte 1 to 0x20000125, byte 2 to 0x2000012c, byte 3 to
@ 0x2000012d; word 0x08006010 to word 0x20000112; word 0x08006014: byte 0 to
@ 0x20000134, byte 1 to 0x20000332, byte 2 to 0x2000044c, byte 3 to
@ 0x20001031; word 0x08006018 to word 0x20000144; word 0x0800601c to word
@ 0x2000032a; word 0x08006020 to word 0x2000032e; word 0x08006024: byte 0 to
@ 0x20000f50, byte 1 to 0x20000f51, byte 2 to 0x20000f58, byte 3 to
@ 0x20000f59; word 0x08006028 to word 0x20000f54; word 0x0800602c to word
@ 0x20001058; word 0x08006030: low half to u16 0x2000105c, byte 2 to
@ 0x20000100, byte 3 to 0x20000101; word 0x08006034: low half to u16
@ 0x20000102, byte 2 to 0x20000140; word 0x08006038 + 4k (k = 0..59): low
@ half to u16 0x20000358 + 2k, high half to u16 0x200003d0 + 2k (so
@ 0x20000446 comes from the high half of word 0x08006124); word 0x08006128
@ low half to u16 0x20000448; word 0x0800612c low half to u16 0x2000044a; for
@ any other marker: byte 0x20001060 = 8, low byte of word 0x20001058 = 1, and
@ the RAM halfword 0x20000446 is tested.
@
@ Default values: when the halfword just loaded into 0x20000446 (or the RAM
@ halfword 0x20000446 for another marker) is 0 or 0xffff, the halfword at
@ 0x20000358 + 2*i, i = 0..119, is set to (hex) 667 665 65e 65b 65a 669 65f
@ 65a 657 655 662 663 659 659 657 667 65d 658 655 655 665 65d 658 65a 656 666
@ 65c 658 655 654 cce cc4 cbc cba cb9 cc5 cbb cb6 cb4 cb3 cc4 cc2 cbb cbb cb9
@ cc5 cbb cb6 cb2 cb2 ccb cc1 cb9 cb7 cb7 cc2 cb8 cb3 cb0 caf 65d 64b 63f 63c
@ 63a 658 648 63f 63a 639 64b 64a 63a 639 637 656 646 63f 639 637 654 64a 63e
@ 63a 63b 659 648 640 63b 639 cc7 cb4 ca7 ca5 ca3 cc2 cb2 caa ca4 ca4 cf6 cb1
@ ca6 ca3 ca2 cc1 cb1 ca8 ca3 ca0 cc0 cb4 ca9 ca6 ca4 cc2 cb4 cab ca6 ca4 and
@ u16 0x20000448 = 0x05fa (121 halfword stores, none to 0x2000044a);
@ otherwise these locations keep their values.
@
@ Transfers through block 0x40003c00: 0x4002101c |= 0x8000; 0x40021018 |= 8
@ four times; 0x40010030 bits 18:16 = 2; setups 0x0802d580..0x0802d5b6;
@ 0x40010c10 = 0x40; 0x0803d848(0x40003c00, record: word 0x100, word
@ 0x01010100); 0x40003c04 |= 2 then |= 1; 0x40003c00 |= 0x40; 0x40021018 |=
@ 0x10; setup 0x0802d634; 0x40011010 = 0x40; delays: word 0x20002b1c * 10,
@ word 0x20002b20 * 1, 100 units; a byte is sent by waiting until bit 1 of
@ 0x40003c08 is set, writing it to 0x40003c0c, waiting until bit 0 is set and
@ reading 0x40003c0c; the line used is bit 0x40 of 0x40010c00 (0x40010c10 =
@ 0x40 is high, 0x40010c14 = 0x40 is low); sequence: high, 0x00; low, 0x05,
@ 0x00; high, 0x00; delay 100; low, 0x12, 0x00; high, 0x00; delay 100; low,
@ 0x15, 0x00; high, 0x00; low, 0x3b followed by 0x1c3b6 (115638) bytes read
@ from 0x08051d19..0x0806e0ce, three per pass (38546 passes, each byte with
@ the same two waits and a read); high, 0x00; low, 0x3a, 0x00; high, 0x00;
@ low, 0x00; high, 0x00.
@
@ Then 0x08041cf0(word 0x20002d78, &item, 0xffffffff) with item byte 1, 2, 6,
@ 7, 8 in this order; 0x40021018 |= 0x10 twice; setups 0x0802de66, 0x0802de76;
@ 0x40011014 = 0x10 when byte 0x2000010f != 2, else 0x40011010 = 0x10;
@ compute_clock_frequencies(buffer); 0x4002101c |= 2; 0x4000042c = 0x13;
@ 0x40000428 = (clk[1]*0xd1b71759 >> 45) - 1; 0x40000414 |= 1; 0x40000400 &=
@ ~0x70; 0x4000040c |= 1; 0xE000ED0C = (old & 0xf8ff) | 0x05fa0300; byte
@ 0xE000E41d = 0x30 (value 3 encoded with the grouping bits 10:8 = 3 just
@ written); 0xE000E100 = 0x20000000; 0x40000400 &= ~1.
@
@ Mode: when byte 0x2000105c is non-zero it is stored in byte 0x20001060
@ (mode value = that byte), else byte 0x20001061 = 1 (mode value = byte
@ 0x20001060 as loaded); mode 1: 0x4000440c |= 0x2000, 0x08041610(word
@ 0x20002da0), 0x08041610(word 0x20002da4), 0x40011010 = 0x800, words
@ 0x20001040 / 0x20001044 / 0x20001048 = 0x7fc00000, halfword 0x2000102d =
@ 0x101, byte 0x20001055 = 0, byte 0x20001025 = 0, byte 0x20001027 = 0, byte
@ 0x20001030 = 0xff, halfword 0x20001034 = 0, then continues at the Derived
@ values; other modes: 0x4000440c &= ~0x2000, 0x0804178c(word 0x20002da0),
@ 0x0804178c(word 0x20002da4), 0x40011014 = 0x800, 0x080423a8(word
@ 0x20002d7c, 0), 0x08041c38(word 0x20002d74, 0); before those, mode 3
@ stores min(byte 0x20000f51, 7) in byte 0x20001062 and mode 2 stores
@ halfword 0x20002d50 = 0 when (byte 0x2000044c & 0xf) is 0, else 0x3c00.
@
@ Derived values: b = byte 0x20000125; 0x080455da(b/3) (u32_to_double) and
@ 10.0 (double at 0x0802e418) go to 0x080438e0 (double_pow); 0x080455da(byte
@ at 0x080465c8 + (b mod 3)); 0x0804577c (double_mul) of the two; 0x0804550a(
@ s16 0x20000112) (i32_to_double); 0x0804577c of that product and the result;
@ 0x08046020 (double_to_i64) of the product; r0 / r1 stored as words
@ 0x20000118 / 0x2000011c; calls 0x0803b078(), 0x08030a70(), 0x0803b2f8(0,
@ 0); when b < 20: 0x40000400 &= ~1 and word 0x20000eac = 0x12d0000 when byte
@ 0x2000010f == 1 else 0x12d; when b >= 20: word 0x20000eac = 0x12d,
@ compute_clock_frequencies(buffer), and when ((b - 20) & 0xff) <= 8:
@ 0x4000042c = word at 0x080465a4 + 4*(b - 20), 0x40000428 = (clk[1]*
@ 0xd1b71759 >> 45) - 1, 0x40000414 |= 1; then 0x40000424 = 0 and 0x40000400
@ |= 1; for both: 0x40011410 = 4.
@
@ Buffers by m = byte 0x2000010c: 0 sets byte 0x2000010d = 0, fills
@ 0x2000044e and (bit 1 of m clear) 0x2000057b; 1 sets 0x2000010d = 1 and
@ fills only 0x2000057b; 2 sets 0x2000010d = 0x12 and fills only 0x2000044e; 3
@ sets 0x2000010d = 2 and fills neither; values >= 4 leave 0x2000010d
@ unchanged, fill 0x2000044e when bit 0 of m is clear and 0x2000057b when bit
@ 1 of m is clear; a fill is 0x08008830(buffer, 0x12d, value) (fill_bytes)
@ with value = byte 0x200000fc ^ 0x80 for 0x2000044e and byte 0x200000fd ^
@ 0x80 for 0x2000057b; then 0x08025fc0() when byte 0x20000332 is non-zero;
@ 0x08012908(); 0x40015034 = byte 0x20001059; the byte-0x2000010c pin writes
@ (3: 0x40011010 = 4 then 0x40011014 = 2; 2: 0x40011014 = 4 then 2; 1:
@ 0x40011010 = 4 then 2); 0x080088a4(byte 0x200000fa); 0x08008a58(byte
@ 0x200000fb); 0x40011410 / 0x40011414 = 0x1000 by byte 0x200000f8 and =
@ 0x2000 by byte 0x200000f9 (non-zero selects 0x40011410); 0x40015034 = byte
@ 0x20001059 again; 0x08029e14(); 0x08029d40(); byte 0x20000f13 = low byte of
@ 0x0803b878("2:/Screenshot simple file" at 0x080bc18b).
@
@ Blocks 0x40000c00 / 0x40000000: 0x4002101c |= 8; 0x40000c00 |= 0x400;
@ 0x40000c2c = 0xffffffff; 0x40000c28 = 0; 0x40000c14 |= 1; 0x40000c00 &=
@ ~0x70; 0x08040734(0x40000c00, &{0x10000}); 0x40000c08 bits 6:4 = 5 then
@ |= 7; 0x40000c00 |= 1; 0x4002101c |= 1; 0x40000000 |= 0x400; 0x4000002c =
@ 0xffffffff; 0x40000028 = 0; 0x40000014 |= 1; 0x40000000 &= ~0x70;
@ 0x08040734(0x40000000, &{0x10002}); 0x40000008 bits 6:4 = 6 then |= 7;
@ 0x40000000 |= 1; when byte 0x2000105a is non-zero it is stored in
@ 0x40015434; delay 50 units; 0x40015434 = 0; delay 500; wait until bit 8 of
@ 0x40011008 is set; delay 10; wait until bit 8 is set; 0x08009c78();
@ 0x40021018 |= 0x4000 and |= 4; setup 0x0802e524; 0x40013808 low halfword =
@ x/10 plus 1 when x mod 10 > 4, with x = (clk[2]*10*0x91a2b3c5) >> 51 (upper
@ half kept); 0x4001380c &= ~0x1000; 0x40013810 &= ~0x3000; 0x4001380c |= 8
@ then |= 0x2000; 0x4002101c |= 0x40.
@
@ Final writes: 0x0800739c(string at 0x0802e6d0 = ESC[1;32m[DEBUG] file[%s]
@ line[%d] ..., "../../../project/bsp_sys.c", 0xef); 0x40003000 = 0x5555;
@ 0x40003004 bits 2:0 = 4; 0x40003008 = 0x4e1; 0x40003000 = 0xaaaa then
@ 0xcccc; compute_clock_frequencies(buffer); 0x4000182c = 9999; 0x40001828 =
@ (clk[1]*0xd1b71759 >> 45) - 1; 0x40001814 |= 1; 0x40001800 &= ~0x70, &=
@ ~0x300; 0x4000180c |= 1; byte 0xE000E42b = enc(3) (= 0x30 for the grouping
@ 3); 0xE000E104 = 0x800; 0x40001800 |= 1; 0x08042e38(word 0x20002d88, 1,
@ result of 0x08042768) and 0x08042e38(word 0x20002d8c, 1, result of
@ 0x08042768) (0x08042768 returns the word 0x200062d4); epilogue and b.w
@ 0x080416d8 (0x0802e6ca).
@
@ Split-off function fn_080416d8 (entered only by that b.w, after the
@ epilogue, so its pop {r7,pc} returns to the caller of this function):
@ 0x080426a0(0x0803becd, "IDLE" (0x080bbc32), 0x80, 0, stack argument
@ 0x200062e0) = r; when r == 1: r = 0x08042dd4(); when r == 1: BASEPRI = 0x10
@ (msr), isb, dsb, 0x200062d0 = 0xffffffff, 0x20006258 = 1, 0x200062d4 = 0,
@ then 0x080419d4() (whether it returns is not determined from this
@ function); when r == -1 (0xffffffff): BASEPRI = 0x10, isb, dsb and an
@ endless loop; all other paths continue at 0x0804177c: r0 = word
@ 0x0804be70 (4), return.
@
@ Blocks that cannot be reached (kept so the code is complete):
@ 0x0802b042..0x0802b059 (remainder stores to 0x60020000 of the first
@ 76800-write loop; unreachable because 76800 is a multiple of 4) and
@ 0x0802b670..0x0802b687 (odd-index adjustment in the rectangle loop, never
@ taken because the index advances by 2).
@ Purpose of the whole sequence and the roles of 0x08035f48, 0x080357bc,
@ 0x080426a0, 0x08042dd4, 0x080419d4 are not determined from the code.
@ This file holds part 1 (0x0802aa50..0x0802ba52); parts 2..4 are included at
@ the end.
@ ----------------------------------------------------------------------------
	.section .text.system_bring_up,"ax",%progbits
	.global system_bring_up
	.thumb_func
	.type system_bring_up, %function
system_bring_up:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #4
	vpush	{d8}
	sub	sp, #0x68
	movw	r9, #0x1018
	movt	r9, #0x4002		@ r9 = 0x40021018 (clock enable register)
	ldr.w	r0, [r9]
	movw	r5, #0x1000
	orr	r0, r0, #0x10
	str.w	r0, [r9]
	movs	r0, #0
	movt	r5, #0x4001		@ r5 = 0x40011000 (port block)
	strb.w	r0, [sp, #0x44]
	movw	r0, #0x1018
	movw	r7, #0x1014
	movw	r11, #0x800
	movw	r8, #8
	movs	r6, #1
	strh.w	r0, [sp, #0x45]
	mov.w	r4, #0x200
	add	r1, sp, #0x40
	mov	r0, r5
	movt	r7, #0x4001
	movt	r11, #0x4001
	movt	r8, #0x4001
	mov.w	r10, #0
	strb.w	r6, [sp, #0x47]
	str	r4, [sp, #0x40]
	bl	set_nibble_fields_from_bit_mask
	str	r4, [r7]
	ldr.w	r0, [r9]
	add	r4, sp, #0x40
	orr	r0, r0, #4
	str.w	r0, [r9]
	ldr.w	r0, [r9]
	mov	r1, r4
	orr	r0, r0, #8
	str.w	r0, [r9]
	ldr.w	r0, [r9]
	orr	r0, r0, #0x10
	str.w	r0, [r9]
	ldr.w	r0, [r9]
	orr	r0, r0, #0x40
	str.w	r0, [r9]
	movs	r0, #0x28
	strb.w	r10, [sp, #0x44]
	strh.w	r0, [sp, #0x45]
	movs	r0, #0x80
	sub.w	r10, r5, #0x400
	str	r0, [sp, #0x40]
	mov	r0, r10
	strb.w	r6, [sp, #0x47]
	bl	set_nibble_fields_from_bit_mask
	movs	r0, #0x18
	strb.w	r0, [sp, #0x45]
	mov.w	r0, #0x2100
	str	r0, [sp, #0x40]
	mov	r0, r5
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	mov.w	r0, #0x210
	strh.w	r0, [sp, #0x46]
	mov.w	r0, #0x180
	str	r0, [sp, #0x40]
	mov	r0, r11
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	mov	r0, r10
	mov	r1, r4
	str	r6, [sp, #0x40]
	str.w	r10, [sp, #0x10]
	bl	set_nibble_fields_from_bit_mask
	mov.w	r0, #0x420
	str	r0, [sp, #0x40]
	mov	r0, r5
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	movw	r10, #0x1800
	movs	r0, #0xc
	movt	r10, #0x4001
	str	r0, [sp, #0x40]
	mov	r0, r10
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	movw	r5, #0x400
	movw	r0, #0xc703
	movt	r5, #0x108
	str	r0, [sp, #0x40]
	str	r5, [sp, #0x44]
	ldr.w	r0, [r9]
	movw	r1, #0x444
	orr	r0, r0, #0x20
	str.w	r0, [r9]
	ldr.w	r0, [r9]
	movt	r1, #0x4002
	orr	r0, r0, #0x40
	str.w	r0, [r9]
	ldr.w	r0, [r9]
	mov	r6, r7
	orr	r0, r0, #1
	str.w	r0, [r9]
	ldr.w	r0, [r1, #0xbd0]
	add.w	r7, r7, #0x3ec
	orr	r0, r0, #0x100
	str.w	r0, [r1, #0xbd0]
	ldr.w	r0, [r8, #0x28]
	add	r4, sp, #0x40
	orr	r0, r0, #0x8000000
	str.w	r0, [r8, #0x28]
	mov	r0, r7
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	movw	r0, #0xff80
	strd	r0, r5, [sp, #0x40]
	mov	r0, r10
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	movw	r0, #0x400
	movt	r0, #0x110
	mov.w	r8, #0x40
	str	r0, [sp, #0x44]
	mov	r0, r7
	mov	r1, r4
	str.w	r8, [sp, #0x40]
	bl	set_nibble_fields_from_bit_mask
	mov.w	r0, #0x8b0
	strd	r0, r5, [sp, #0x40]
	mov	r0, r7
	mov	r1, r4
	str	r7, [sp, #0xc]
	bl	set_nibble_fields_from_bit_mask
	mov.w	r0, #0xa0000000
	movw	r1, #0x5010
	str	r1, [r0]
	movw	r1, #0xfde4
	movw	r2, #0x220
	movw	r3, #0x424
	movt	r1, #0xffff
	movt	r2, #0xa000
	movt	r3, #0x202
	str	r3, [r2, r1]
	movw	r1, #0xfee4
	movt	r1, #0xffff
	movw	r3, #0x202
	str	r3, [r2, r1]
	ldr	r1, [r2]
	movs	r3, #8
	bic	r1, r1, #0xff00
	str	r1, [r2]
	ldr	r1, [r2]
	movw	r4, #0xe010
	bfi	r1, r3, #0, #8
	str	r1, [r2]
	ldr	r1, [r0]
	movt	r4, #0xe000		@ r4 = 0xE000E010 (SysTick control)
	orr	r1, r1, #1
	str	r1, [r0]
	movw	r0, #0x2b20
	str.w	r8, [r6, #0x3fc]
	movt	r0, #0x2000
	ldr	r0, [r0]
	mov	r7, r6
	add.w	r0, r0, r0, lsl #2
	lsls	r0, r0, #1		@ delay unit * 10
	str	r0, [r4, #4]
	movs	r0, #0
	str	r0, [r4, #8]
	ldr	r0, [r4]
	orr	r0, r0, #1
	str	r0, [r4]
	nop
.L0802ac7c:
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802aca4
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802aca4
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802aca4
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	beq.n	.L0802ac7c
.L0802aca4:
	ldr	r0, [r4]
	movs	r1, #0x40
	bic	r0, r0, #1
	str	r0, [r4]
	movs	r0, #0
	str	r0, [r4, #8]
	str.w	r1, [r7, #0x400]
	movw	r1, #0x2b20
	movt	r1, #0x2000
	ldr	r1, [r1]
	add.w	r1, r1, r1, lsl #2
	lsls	r1, r1, #2		@ delay unit * 20
	str	r1, [r4, #4]
	str	r0, [r4, #8]
	ldr	r0, [r4]
	orr	r0, r0, #1
	str	r0, [r4]
	nop
.L0802acd4:
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802acfc
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802acfc
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802acfc
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	beq.n	.L0802acd4
.L0802acfc:
	ldr	r0, [r4]
	movs	r1, #0x40
	bic	r0, r0, #1
	str	r0, [r4]
	movs	r0, #0
	str	r0, [r4, #8]
	str.w	r1, [r7, #0x3fc]
	movw	r1, #0x2b20
	movt	r1, #0x2000
	ldr	r1, [r1]
	add.w	r1, r1, r1, lsl #2
	lsls	r1, r1, #2		@ delay unit * 20
	str	r1, [r4, #4]
	str	r0, [r4, #8]
	ldr	r0, [r4]
	orr	r0, r0, #1
	str	r0, [r4]
	nop
.L0802ad2c:
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802ad54
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802ad54
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802ad54
	ldr	r0, [r4]
	and	r0, r0, #0x10001
	cmp	r0, #1
	beq.n	.L0802ad2c
.L0802ad54:
	ldr	r0, [r4]
	movw	r10, #0
	bic	r0, r0, #1
	movt	r10, #0x6002		@ r10 = 0x60020000 (LCD data port)
	str	r0, [r4]
	movs	r0, #0
	movs	r1, #0x11
	str	r0, [r4, #8]
	strh.w	r1, [r10, #-2]		@ index 0x11
	movs	r2, #0x78		@ delay 120 units, in chunks of 50
	movs	r1, #0x32
	b.n	.L0802ad82
.L0802ad74:
	ldr	r3, [r4]
	bic	r3, r3, #1
	str	r3, [r4]
	lsls	r3, r2, #0x10
	str	r0, [r4, #8]
	beq.n	.L0802ade2
.L0802ad82:
	uxth	r3, r2
	cmp	r3, #0x33
	blo.n	.L0802ad9c
	movw	r3, #0x2b20
	movt	r3, #0x2000
	ldr	r3, [r3]
	subs	r2, #0x32
	muls	r3, r1, r3
	str	r3, [r4, #4]
	b.n	.L0802adac
	.byte	0x00, 0xbf		@ padding
.L0802ad9c:
	movw	r2, #0x2b20
	movt	r2, #0x2000
	ldr	r2, [r2]
	muls	r2, r3, r2
	str	r2, [r4, #4]
	movs	r2, #0
.L0802adac:
	str	r0, [r4, #8]
	ldr	r3, [r4]
	orr	r3, r3, #1
	str	r3, [r4]
	nop
.L0802adb8:
	ldr	r3, [r4]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802ad74
	ldr	r3, [r4]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802ad74
	ldr	r3, [r4]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802ad74
	ldr	r3, [r4]
	and	r3, r3, #0x10001
	cmp	r3, #1
	beq.n	.L0802adb8
	b.n	.L0802ad74
.L0802ade2:
	mov.w	r12, #0x36
	mov.w	r11, #0
	movs	r1, #0x3a
	strh.w	r12, [r10, #-2]		@ index 0x36
	strh.w	r11, [r10]		@ data 0x00
	strh.w	r1, [r10, #-2]		@ index 0x3a
	movs	r1, #0x55
	strh.w	r1, [r10]
	movs	r1, #0xb2
	strh.w	r1, [r10, #-2]		@ index 0xb2
	movs	r1, #0xc
	strh.w	r1, [r10]
	strh.w	r1, [r10]
	movs	r1, #0x33
	strh.w	r11, [r10]
	strh.w	r1, [r10]
	strh.w	r1, [r10]
	movs	r1, #0xb7
	strh.w	r1, [r10, #-2]		@ index 0xb7
	movs	r1, #0x46
	strh.w	r1, [r10]
	movs	r1, #0xbb
	strh.w	r1, [r10, #-2]		@ index 0xbb
	movs	r1, #0x1b
	strh.w	r1, [r10]
	movs	r1, #0xc0
	strh.w	r1, [r10, #-2]		@ index 0xc0
	movs	r3, #0x2c
	movs	r1, #0xc2
	strh.w	r3, [r10]
	strh.w	r1, [r10, #-2]		@ index 0xc2
	mov.w	lr, #1
	movs	r1, #0xc3
	strh.w	lr, [r10]
	strh.w	r1, [r10, #-2]		@ index 0xc3
	movs	r1, #0xf
	movs	r6, #0xc4
	strh.w	r1, [r10]
	strh.w	r6, [r10, #-2]		@ index 0xc4
	movs	r6, #0x20
	strh.w	r6, [r10]
	movs	r6, #0xc6
	strh.w	r6, [r10, #-2]		@ index 0xc6
	movs	r6, #0xd0
	strh.w	r1, [r10]
	strh.w	r6, [r10, #-2]		@ index 0xd0
	movs	r6, #0xa4
	strh.w	r6, [r10]
	movs	r6, #0xa1
	movs	r5, #0xd6
	strh.w	r6, [r10]
	strh.w	r5, [r10, #-2]		@ index 0xd6
	strh.w	r6, [r10]
	movs	r6, #0xe0
	strh.w	r6, [r10, #-2]		@ index 0xe0
	movs	r6, #0xf0
	movs	r5, #6
	strh.w	r6, [r10]
	strh.w	r11, [r10]
	strh.w	r5, [r10]
	movs	r5, #4
	strh.w	r5, [r10]
	movs	r5, #5
	strh.w	r5, [r10]
	strh.w	r5, [r10]
	movs	r7, #0x31
	movs	r5, #0x44
	strh.w	r7, [r10]
	strh.w	r5, [r10]
	movs	r5, #0x48
	strh.w	r5, [r10]
	movs	r5, #0x12
	strh.w	r12, [r10]
	strh.w	r5, [r10]
	strh.w	r5, [r10]
	movs	r5, #0x2b
	movs	r2, #0x34
	strh.w	r5, [r10]
	strh.w	r2, [r10]
	movs	r2, #0xe1
	strh.w	r2, [r10, #-2]		@ index 0xe1
	movs	r2, #0xb
	strh.w	r6, [r10]
	strh.w	r2, [r10]
	strh.w	r1, [r10]
	strh.w	r1, [r10]
	movs	r1, #0xd
	strh.w	r1, [r10]
	movs	r1, #0x26
	strh.w	r1, [r10]
	movs	r1, #0x43
	strh.w	r7, [r10]
	strh.w	r1, [r10]
	movs	r1, #0x47
	strh.w	r1, [r10]
	movs	r1, #0x38
	strh.w	r1, [r10]
	movs	r1, #0x14
	strh.w	r1, [r10]
	strh.w	r1, [r10]
	movs	r1, #0x32
	movs	r2, #0x29
	movw	r8, #0x8340
	strh.w	r3, [r10]
	strh.w	r1, [r10]
	strh.w	r2, [r10, #-2]		@ index 0x29
	movt	r8, #0x2000		@ r8 = 0x20008340 (LCD window parameters)
	mov.w	r2, #0x140
	strb.w	lr, [r8, #6]
	strh.w	r2, [r8]
	movs	r2, #0x2a
	strh.w	r6, [r8, #2]
	strh.w	r3, [r8, #8]
	strh.w	r2, [r8, #0xa]
	movs	r2, #0xa0
	strh.w	r5, [r8, #0xc]
	strh.w	r12, [r10, #-2]		@ index 0x36
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #0xa]
	movw	r0, #0x1000
	strh.w	r2, [r10, #-2]		@ index 0x2a
	strh.w	r11, [r10]
	strh.w	r11, [r10]
	ldrh.w	r2, [r8]
	movt	r0, #0x4001
	subs	r2, #1
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8]
	subs	r2, #1
	uxtb	r2, r2
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #0xc]
	strh.w	r2, [r10, #-2]		@ index 0x2b
	strh.w	r11, [r10]
	strh.w	r11, [r10]
	ldrh.w	r2, [r8, #2]
	subs	r2, #1
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #2]
	subs	r2, #1
	uxtb	r2, r2
	strh.w	r2, [r10]
	ldrh.w	r2, [r8]
	ldrh.w	r3, [r8, #2]
	ldrh.w	r7, [r8, #0xa]
	muls	r3, r2, r3		@ width * height = 76800
	strh.w	r7, [r10, #-2]		@ index 0x2a
	strh.w	r11, [r10]
	strh.w	r11, [r10]
	ldrh.w	r7, [r8]
	lsr.w	r7, r7, #8
	strh.w	r7, [r10]
	ldrh.w	r7, [r8]
	uxtb	r7, r7
	strh.w	r7, [r10]
	ldrh.w	r7, [r8, #0xc]
	strh.w	r7, [r10, #-2]		@ index 0x2b
	strh.w	r11, [r10]
	strh.w	r11, [r10]
	ldrh.w	r7, [r8, #2]
	lsr.w	r7, r7, #8
	strh.w	r7, [r10]
	ldrh.w	r7, [r8, #2]
	uxtb	r2, r7
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #8]
	strh.w	r2, [r10, #-2]		@ index 0x2c
	cbz	r3, .L0802b05a
	subs	r2, r3, #1
	cmp	r2, #3
	and	r2, r3, #3
	blo.n	.L0802b040
	bic	r3, r3, #3
	rsbs	r3, r3, #0
	movs	r7, #0
.L0802b02c:
	adds	r3, #4
	strh.w	r7, [r10]
	strh.w	r7, [r10]
	strh.w	r7, [r10]
	strh.w	r7, [r10]
	bne.n	.L0802b02c
.L0802b040:
	cbz	r2, .L0802b05a
	movs	r3, #0
	cmp	r2, #1
	strh.w	r3, [r10]
	beq.n	.L0802b05a
	cmp	r2, #2
	strh.w	r3, [r10]
	itt	ne
	movne	r2, #0
	strhne.w	r2, [r10]
.L0802b05a:
	movs	r2, #0x64		@ delay 100 units, in chunks of 50
	b.n	.L0802b070
	.byte	0x00, 0xbf		@ padding
.L0802b060:
	ldr	r3, [r4]
	bic	r3, r3, #1
	str	r3, [r4]
	lsls	r3, r2, #0x10
	str.w	r11, [r4, #8]
	beq.n	.L0802b0ce
.L0802b070:
	uxth	r3, r2
	cmp	r3, #0x33
	blo.n	.L0802b088
	movw	r3, #0x2b20
	movt	r3, #0x2000
	ldr	r3, [r3]
	subs	r2, #0x32
	muls	r3, r1, r3
	str	r3, [r4, #4]
	b.n	.L0802b098
.L0802b088:
	movw	r2, #0x2b20
	movt	r2, #0x2000
	ldr	r2, [r2]
	muls	r2, r3, r2
	str	r2, [r4, #4]
	movs	r2, #0
.L0802b098:
	str.w	r11, [r4, #8]
	ldr	r3, [r4]
	orr	r3, r3, #1
	str	r3, [r4]
.L0802b0a4:
	ldr	r3, [r4]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802b060
	ldr	r3, [r4]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802b060
	ldr	r3, [r4]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802b060
	ldr	r3, [r4]
	and	r3, r3, #0x10001
	cmp	r3, #1
	beq.n	.L0802b0a4
	b.n	.L0802b060
.L0802b0ce:
	ldr.w	r1, [r9]
	add	r4, sp, #0x40
	orr	r1, r1, #0x10
	str.w	r1, [r9]
	ldr.w	r1, [r9]
	movw	r6, #0x5404
	orr	r1, r1, #0x10
	str.w	r1, [r9]
	movs	r1, #0
	strb.w	r1, [sp, #0x44]
	movs	r1, #0x18
	strh.w	r1, [sp, #0x45]
	movs	r1, #0x80
	movw	r11, #0x5034
	movw	r7, #0x1c00
	movs	r5, #1
	str	r1, [sp, #0x40]
	mov	r1, r4
	movt	r6, #0x4001
	movt	r11, #0x4001
	movt	r7, #0x4000
	strb.w	r5, [sp, #0x47]
	bl	set_nibble_fields_from_bit_mask
	mov.w	r0, #0x4000
	str	r0, [sp, #0x40]
	movw	r0, #0x1000
	movt	r0, #0x4001
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	movw	r4, #0x1070
	movt	r4, #0x2000
	ldr	r0, [r4, #0xc]
	mov.w	r1, #0x2bc0
	bl	zero_bytes
	strb	r5, [r4, #0x10]
	bl	serial_device_interface_init
	bl	filesystem_startup_setup
	movw	r0, #0x6b80
	movw	r1, #:lower16:write_pixel_window_to_port
	movt	r0, #0x2003
	movt	r1, #:upper16:write_pixel_window_to_port
	str	r1, [r0]
	movw	r0, #0x400
	movt	r0, #0x108
	str	r0, [sp, #0x64]
	mov.w	r0, #0x100
	str	r0, [sp, #0x60]
	movs	r0, #0
	str	r0, [sp, #0x50]
	strd	r0, r0, [sp, #0x48]
	strd	r0, r0, [sp, #0x40]
	add	r0, sp, #0x40
	bl	compute_clock_frequencies
	ldr.w	r0, [r9]
	add	r4, sp, #0x60
	orr	r0, r0, #8
	str.w	r0, [r9]
	ldr.w	r0, [r9]
	mov	r1, r4
	orr	r0, r0, #0x100000
	str.w	r0, [r9]
	ldr.w	r0, [r9]
	orr	r0, r0, #8
	str.w	r0, [r9]
	ldr.w	r0, [r9]
	orr	r0, r0, #0x200000
	str.w	r0, [r9]
	ldr.w	r0, [r9]
	orr	r0, r0, #4
	str.w	r0, [r9]
	ldr.w	r0, [r9, #4]
	orr	r0, r0, #0x80
	str.w	r0, [r9, #4]
	ldr	r5, [sp, #0x10]
	mov	r0, r5
	bl	set_nibble_fields_from_bit_mask
	mov.w	r0, #0x200
	str	r0, [sp, #0x60]
	mov	r0, r5
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	movs	r0, #0x40
	str	r0, [sp, #0x60]
	movw	r0, #0x800
	movt	r0, #0x4001
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	ldr	r0, [sp, #0x44]
	movw	r1, #0xde83
	movt	r1, #0x431b
	umull	r1, r2, r0, r1
	mov.w	r1, #0xffffffff
	add.w	r2, r1, r2, lsr #18
	movs	r3, #0x63
	str.w	r3, [r11, #-8]
	str.w	r2, [r11, #-0xc]
	ldr.w	r2, [r11, #-0x20]
	movw	r3, #0x5ac5
	orr	r2, r2, #1
	str.w	r2, [r11, #-0x20]
	ldr.w	r2, [r11, #-0x34]
	lsrs	r0, r0, #4
	bic	r2, r2, #0x70
	str.w	r2, [r11, #-0x34]
	ldr.w	r2, [r11, #-0x30]
	movt	r3, #0xa7c
	bic	r2, r2, #0x100
	str.w	r2, [r11, #-0x30]
	ldr.w	r2, [r11, #-0x30]
	umull	r0, r3, r0, r3
	orr	r2, r2, #0x100
	str.w	r2, [r11, #-0x30]
	ldr.w	r2, [r11, #-0x1c]
	movw	r4, #0x8360
	orr	r2, r2, #0x70
	str.w	r2, [r11, #-0x1c]
	ldr.w	r2, [r11, #-0x14]
	mvn	r5, #0x5c
	orr	r2, r2, #3
	str.w	r2, [r11, #-0x14]
	movs	r2, #0x64
	str.w	r2, [r11]
	ldr.w	r2, [r11, #0x10]
	movt	r4, #0x2000		@ r4 = 0x20008360 (file name buffer)
	orr	r2, r2, #0x8000
	str.w	r2, [r11, #0x10]
	ldr.w	r2, [r11, #-0x34]
	adr.w	r9, .L0802c094		@ "3:/System file/162.jpg"
	orr	r0, r2, #1
	str.w	r0, [r11, #-0x34]
	add.w	r0, r1, r3, lsr #7
	movs	r1, #0x18
	str	r1, [r6, #0x28]
	str	r0, [r6, #0x24]
	ldr	r0, [r6, #0x10]
	movs	r2, #0
	orr	r0, r0, #1
	str	r0, [r6, #0x10]
	ldr.w	r0, [r11, #0x3cc]
	bic	r0, r0, #0x70
	str.w	r0, [r11, #0x3cc]
	ldr	r0, [r6]
	ldr	r1, [r6, #0x1c]
	bic	r0, r0, #0x100
	str	r0, [r6]
	ldr	r0, [r6]
	orr	r0, r0, #0x100
	str	r0, [r6]
	ldr	r0, [r6, #0x14]
	orr	r0, r0, #0x70
	str	r0, [r6, #0x14]
	orr	r0, r1, #3
	str	r0, [r6, #0x1c]
	str	r2, [r6, #0x30]
	ldr	r0, [r6, #0x40]
	movw	r1, #0x1c34
	orr	r0, r0, #0x8000
	str	r0, [r6, #0x40]
	ldr.w	r0, [r11, #0x3cc]
	movt	r1, #0x4000
	orr	r0, r0, #1
	str.w	r0, [r11, #0x3cc]
	movw	r0, #0xffe
	str.w	r0, [r1, #-8]
	str	r2, [r7, #0x28]
	ldr	r0, [r7, #0x14]
	movs	r2, #0
	orr	r0, r0, #1
	str	r0, [r7, #0x14]
	ldr	r0, [r7]
	movw	r6, #:lower16:d_080bc680+1
	bic	r0, r0, #0x70
	str	r0, [r7]
	ldr	r0, [r7, #4]
	movt	r6, #:upper16:d_080bc680+1
	bic	r0, r0, #0x100
	str	r0, [r7, #4]
	ldr	r0, [r7, #4]
	mov.w	r11, #0
	orr	r0, r0, #0x100
	str	r0, [r7, #4]
	ldr	r0, [r7, #0x18]
	orr	r0, r0, #0x70
	str	r0, [r7, #0x18]
	ldr	r0, [r7, #0x20]
	orr	r0, r0, #3
	str	r0, [r7, #0x20]
	str	r2, [r1]
	ldr	r0, [r1, #0x10]
	orr	r0, r0, #0x8000
	str	r0, [r1, #0x10]
	ldr	r0, [r7]
	orr	r0, r0, #1
	str	r0, [r7]
	movs	r7, #0
	b.n	.L0802b364
.L0802b354:
	ldr	r0, [r1]
	bic	r0, r0, #1
	str	r0, [r1]
	str	r7, [r1, #8]
	ldr	r0, [r2, #8]
	lsls	r0, r0, #0x17
	bpl.n	.L0802b40e
.L0802b364:
	add.w	r11, r11, #1
	uxtb.w	r0, r11
	movw	r1, #0xcccd
	cmp	r0, #0x18
	it	hi
	movhi.w	r11, #0
	uxtb.w	r0, r11
	movt	r1, #0xcccc
	umull	r0, r1, r0, r1
	add.w	r0, r5, r1, lsr #2	@ name index (b/5 + 0xa3) & 0xff
	uxtb	r2, r0
	mov	r0, r4
	mov	r1, r6
	bl	format_to_buffer_080073b4
	movw	r2, #0x1000
	movt	r2, #0x4001
	ldr	r0, [r2, #8]
	lsls	r0, r0, #0x18
	mov	r0, r4
	bpl.n	.L0802b3aa
	ldr	r0, [r2, #8]
	lsls	r0, r0, #0x11
	mov	r0, r9
	bmi.n	.L0802b3ba
.L0802b3aa:
	movs	r1, #0x50
	movs	r2, #0x52
	bl	decode_image_file_with_offset
	movw	r2, #0x1000
	movt	r2, #0x4001
.L0802b3ba:
	ldr	r0, [r2, #8]
	lsls	r0, r0, #0x17
	bmi.n	.L0802b364
	movw	r0, #0x2b20
	movt	r0, #0x2000
	ldr	r0, [r0]
	movw	r1, #0xe010
	add.w	r0, r0, r0, lsl #2
	movt	r1, #0xe000
	str	r0, [r1, #4]		@ delay 5 units
	str	r7, [r1, #8]
	ldr	r0, [r1]
	orr	r0, r0, #1
	str	r0, [r1]
	nop
.L0802b3e4:
	ldr	r0, [r1]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802b354
	ldr	r0, [r1]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802b354
	ldr	r0, [r1]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802b354
	ldr	r0, [r1]
	and	r0, r0, #0x10001
	cmp	r0, #1
	beq.n	.L0802b3e4
	b.n	.L0802b354
.L0802b40e:
	mov.w	r0, #0x200
	str	r0, [r2, #0x10]
	movw	r0, #0x6b80
	movw	r1, #:lower16:write_pixel_window_to_port
	movt	r0, #0x2003
	movt	r1, #:upper16:write_pixel_window_to_port
	str	r1, [r0]
	movs	r0, #1
	bl	alloc_units_of_32_bytes
	mov	r11, r0
	movw	r0, #0x102c
	bl	alloc_units_of_32_bytes
	movw	r1, #:lower16:d_080bc66a+1
	movt	r1, #:upper16:d_080bc66a+1
	movs	r2, #0
	mov	r9, r0
	movs	r4, #0
	bl	file_open
	movw	r6, #0xf8
	cmp	r0, #0
	movt	r6, #0x2000
	strb.w	r0, [r11]
	beq.w	.L0802c04a
	ldrh.w	r0, [r8]
	ldrh.w	r1, [r8, #2]
	ldrh.w	r2, [r8, #0xa]
	muls	r1, r0, r1
	strh.w	r2, [r10, #-2]		@ index 0x2a
	strh.w	r4, [r10]
	strh.w	r4, [r10]
	ldrh.w	r2, [r8]
	lsr.w	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8]
	add.w	r12, sp, #0x40
	uxtb	r2, r2
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #0xc]
	strh.w	r2, [r10, #-2]		@ index 0x2b
	strh.w	r4, [r10]
	strh.w	r4, [r10]
	ldrh.w	r2, [r8, #2]
	lsr.w	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #2]
	uxtb	r0, r2
	strh.w	r0, [r10]
	ldrh.w	r0, [r8, #8]
	strh.w	r0, [r10, #-2]		@ index 0x2c
	cbz	r1, .L0802b4fe
	subs	r0, r1, #1
	cmp	r0, #3
	and	r0, r1, #3
	blo.n	.L0802b4e4
	bic	r1, r1, #3
	rsbs	r1, r1, #0
	movs	r2, #0
.L0802b4d0:
	adds	r1, #4
	strh.w	r2, [r10]
	strh.w	r2, [r10]
	strh.w	r2, [r10]
	strh.w	r2, [r10]
	bne.n	.L0802b4d0
.L0802b4e4:
	cbz	r0, .L0802b4fe
	movs	r1, #0
	cmp	r0, #1
	strh.w	r1, [r10]
	beq.n	.L0802b4fe
	cmp	r0, #2
	strh.w	r1, [r10]
	itt	ne
	movne	r0, #0
	strhne.w	r0, [r10]
.L0802b4fe:
	strd	r11, r9, [sp, #4]
	mov.w	r9, #4
	movs	r0, #0
	b.n	.L0802b526
	.byte	0x00, 0xbf		@ padding
.L0802b50c:
	ldr	r0, [r1]
	bic	r0, r0, #1
	str	r0, [r1]
	movs	r0, #0
	str	r0, [r1, #8]
	sxth	r0, r2
	cmp	r0, #0xf7
	mov.w	r0, #0xff
	it	lt
	addlt.w	r0, r2, #8
.L0802b526:
	str	r0, [sp, #0x3c]
	uxtb	r0, r0
	movw	r3, #0x8081
	rsb	r1, r0, r0, lsl #5
	movt	r3, #0x8080
	umull	r1, r2, r1, r3
	rsb	r0, r0, r0, lsl #6
	umull	r0, r1, r0, r3
	mvn	r3, #0x1f
	and.w	r1, r3, r1, lsr #2
	lsrs	r0, r2, #7
	orr.w	r1, r1, r2, lsr #7
	orr.w	r0, r1, r0, lsl #11
	uxth	r0, r0
	mov	r1, r12
	bl	fn_080092dc
	movw	lr, #:lower16:d_0804ca24
	add.w	r12, sp, #0x40
	movs	r0, #0
	movs	r1, #0x67
	movt	lr, #:upper16:d_0804ca24
.L0802b56c:
	lsrs	r2, r1, #8
	lsls	r3, r0, #2
	movs	r4, #0x37
	nop
.L0802b574:
	lsrs	r7, r0, #1
	ldrb.w	r7, [lr, r7]
	bic.w	r5, r9, r3
	lsrs	r7, r5
	and	r7, r7, #0xf
	ldrh.w	r7, [r12, r7, lsl #1]
	ldrh.w	r5, [r8, #0xa]
	adds	r6, r4, #1
	strh.w	r5, [r10, #-2]		@ index 0x2a
	lsrs	r5, r4, #8
	strh.w	r5, [r10]
	strh.w	r4, [r10]
	ldrh.w	r5, [r8]
	cmp	r4, #0xf7
	lsr.w	r5, r5, #8
	strh.w	r5, [r10]
	ldrh.w	r5, [r8]
	add.w	r4, r4, #2
	uxtb	r5, r5
	strh.w	r5, [r10]
	ldrh.w	r5, [r8, #0xc]
	strh.w	r5, [r10, #-2]		@ index 0x2b
	strh.w	r2, [r10]
	strh.w	r1, [r10]
	ldrh.w	r5, [r8, #2]
	lsr.w	r5, r5, #8
	strh.w	r5, [r10]
	ldrh.w	r5, [r8, #2]
	uxtb	r5, r5
	strh.w	r5, [r10]
	ldrh.w	r5, [r8, #8]
	strh.w	r5, [r10, #-2]		@ index 0x2c
	strh.w	r7, [r10]
	add.w	r7, r0, #1
	lsr.w	r7, r7, #1
	ldrb.w	r7, [lr, r7]
	add.w	r5, r3, #4
	bic.w	r5, r9, r5
	lsr.w	r7, r7, r5
	and	r11, r7, #0xf
	ldrh.w	r7, [r12, r11, lsl #1]
	ldrh.w	r5, [r8, #0xa]
	add.w	r0, r0, #2
	strh.w	r5, [r10, #-2]		@ index 0x2a
	lsr.w	r5, r6, #8
	strh.w	r5, [r10]
	strh.w	r6, [r10]
	ldrh.w	r6, [r8]
	add.w	r3, r3, #8
	lsr.w	r6, r6, #8
	strh.w	r6, [r10]
	ldrh.w	r6, [r8]
	uxtb	r6, r6
	strh.w	r6, [r10]
	ldrh.w	r6, [r8, #0xc]
	strh.w	r6, [r10, #-2]		@ index 0x2b
	strh.w	r2, [r10]
	strh.w	r1, [r10]
	ldrh.w	r6, [r8, #2]
	lsr.w	r6, r6, #8
	strh.w	r6, [r10]
	ldrh.w	r6, [r8, #2]
	uxtb	r6, r6
	strh.w	r6, [r10]
	ldrh.w	r6, [r8, #8]
	strh.w	r6, [r10, #-2]		@ index 0x2c
	strh.w	r7, [r10]
	blo.n	.L0802b574
	subs	r2, r0, #2		@ kept unreachable block 0x0802b670..0x0802b687
	lsls	r2, r2, #0x1f
	add.w	r3, r0, #2
	it	ne
	bicne	r0, r3, #1
	cmp	r1, #0x89
	add.w	r1, r1, #1
	bcc.w	.L0802b56c
	ldr	r2, [sp, #0x3c]
	movw	r1, #0xe010
	uxth	r0, r2
	cmp	r0, #0xff
	movt	r1, #0xe000
	beq.n	.L0802b6e4
	movw	r0, #0x2b20
	movt	r0, #0x2000
	ldr	r0, [r0]
	add.w	r0, r0, r0, lsl #1	@ delay 3 units
	str	r0, [r1, #4]
	movs	r0, #0
	str	r0, [r1, #8]
	ldr	r0, [r1]
	orr	r0, r0, #1
	str	r0, [r1]
.L0802b6b4:
	ldr	r0, [r1]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.w	.L0802b50c
	ldr	r0, [r1]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.w	.L0802b50c
	ldr	r0, [r1]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.w	.L0802b50c
	ldr	r0, [r1]
	and	r0, r0, #0x10001
	cmp	r0, #1
	beq.n	.L0802b6b4
	b.n	.L0802b50c
.L0802b6e4:
	movs	r0, #0
	movt	r0, #0x861
	str	r0, [sp, #0x40]		@ replacement lookup table, 8 words
	movw	r0, #0x18e3
	movt	r0, #0x2965
	str	r0, [sp, #0x44]
	movw	r0, #0x39e7
	movt	r0, #0x4a69
	str	r0, [sp, #0x48]
	movw	r0, #0x5aeb
	movt	r0, #0x6b6d
	str	r0, [sp, #0x4c]
	movw	r0, #0x7bef
	movt	r0, #0x8c71
	str	r0, [sp, #0x50]
	movw	r0, #0x9cf3
	movt	r0, #0xad75
	str	r0, [sp, #0x54]
	movw	r0, #0xbdf7
	movt	r0, #0xce79
	str	r0, [sp, #0x58]
	movw	r0, #0xdefb
	movw	r6, #:lower16:d_0804c9fc
	movt	r0, #0xef7d
	movs	r5, #0
	movt	r6, #:upper16:d_0804c9fc
	mov.w	r12, #0
	str	r0, [sp, #0x5c]
	b.n	.L0802b75e
	.byte	0x00, 0xbf		@ padding
.L0802b744:
	add.w	r12, r12, #1
	movw	r6, #:lower16:d_0804c9fc
	cmp.w	r12, #3
	add	r1, sp, #0x40
	movt	r6, #:upper16:d_0804c9fc
	mov.w	r5, #0
	beq.w	.L0802bcdc
.L0802b75e:
	add.w	r0, r12, #2
	str	r0, [sp, #0x18]
	add.w	r0, r6, r0, lsl #3
	ldrh	r1, [r0, #6]
	ldrh	r2, [r0, #2]
	str	r1, [sp, #0x1c]
	rsb.w	r1, r1, #1
	adds	r0, #4
	str	r2, [sp, #0x20]
	str	r0, [sp, #0x14]
	str.w	r12, [sp, #0x3c]
	b.n	.L0802b796
	.byte	0x00, 0xbf		@ padding
.L0802b780:
	ldr	r0, [r1]
	movw	r6, #:lower16:d_0804c9fc
	bic	r0, r0, #1
	str	r0, [r1]
	str	r5, [r1, #8]
	ldr	r1, [sp, #0x24]
	movt	r6, #:upper16:d_0804c9fc
	adds	r1, #1
.L0802b796:
	sxth	r4, r1
	cmp	r4, #0
	strd	r1, r4, [sp, #0x24]
	ble.w	.L0802ba44
	ldr	r0, [sp, #0x18]
	ldrsh.w	r2, [r6, r0, lsl #3]
	ldr	r0, [sp, #0x14]
	str	r2, [sp, #0x34]
	ldrh	r0, [r0]
	uxtah	r3, r0, r2
	cmp	r3, r2
	uxth	r0, r2
	str	r0, [sp, #0x2c]
	ble.n	.L0802b826
	subs	r2, r1, #1
	uxth	r0, r2
	ldr	r6, [sp, #0x2c]
	lsrs	r0, r0, #8
	uxtb	r7, r2
.L0802b7c4:
	ldrh.w	r2, [r8, #0xa]
	strh.w	r2, [r10, #-2]		@ index 0x2a
	uxth	r2, r6
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	uxtb	r2, r6
	strh.w	r2, [r10]
	ldrh.w	r2, [r8]
	adds	r6, #1
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8]
	uxtb	r2, r2
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #0xc]
	strh.w	r2, [r10, #-2]		@ index 0x2b
	strh.w	r0, [r10]
	strh.w	r7, [r10]
	ldrh.w	r2, [r8, #2]
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #2]
	uxtb	r2, r2
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #8]
	strh.w	r2, [r10, #-2]		@ index 0x2c
	sxth	r2, r6
	cmp	r3, r2
	strh.w	r5, [r10]
	bgt.n	.L0802b7c4
.L0802b826:
	ldr	r0, [sp, #0x1c]
	movw	r2, #:lower16:d_0804d7c0+1
	add	r0, r4
	movs	r4, #0
	mov	r5, r1
	movt	r2, #:upper16:d_0804d7c0+1
	movs	r7, #4
	str	r0, [sp, #0x30]
	b.n	.L0802b862
.L0802b83c:
	movw	r2, #:lower16:d_0804d7c0+1
	ldr.w	r12, [sp, #0x3c]
	movt	r2, #:upper16:d_0804d7c0+1
	movs	r7, #4
.L0802b84a:
	adds	r0, r4, #2
	lsls	r1, r4, #0x1f
	it	ne
	bicne	r4, r0, #1
	ldr	r5, [sp, #0x38]
	ldr	r1, [sp, #0x30]
	adds	r5, #1
	sxth	r0, r5
	cmp	r1, r0
	ble.w	.L0802bc80
.L0802b862:
	ldr	r0, [sp, #0x34]
	str	r5, [sp, #0x38]
	cmp	r3, r0
	ble.n	.L0802b84a
	uxtb.w	r0, r12
	movw	r9, #:lower16:d_0804d766+1
	cmp	r0, #0
	movt	r9, #:upper16:d_0804d766+1
	beq.n	.L0802b918
	cmp	r0, #1
	bne.w	.L0802b9aa
	uxth	r0, r5
	ldr	r7, [sp, #0x2c]
	movw	r9, #:lower16:d_0804d798+1
	lsrs	r6, r0, #8
	uxtb	r5, r5
	lsls	r0, r4, #2
	mov.w	r12, #4
	add.w	lr, sp, #0x40
	movt	r9, #:upper16:d_0804d798+1
	nop
.L0802b89c:
	lsrs	r1, r4, #1
	ldrb.w	r1, [r9, r1]
	bic.w	r2, r12, r0
	lsrs	r1, r2
	and	r11, r1, #0xf
	ldrh.w	r1, [lr, r11, lsl #1]
	ldrh.w	r2, [r8, #0xa]
	adds	r4, #1
	strh.w	r2, [r10, #-2]		@ index 0x2a
	uxth	r2, r7
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	uxtb	r2, r7
	strh.w	r2, [r10]
	ldrh.w	r2, [r8]
	adds	r7, #1
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8]
	adds	r0, #4
	uxtb	r2, r2
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #0xc]
	strh.w	r2, [r10, #-2]		@ index 0x2b
	strh.w	r6, [r10]
	strh.w	r5, [r10]
	ldrh.w	r2, [r8, #2]
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #2]
	uxtb	r2, r2
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #8]
	strh.w	r2, [r10, #-2]		@ index 0x2c
	strh.w	r1, [r10]
	sxth	r1, r7
	cmp	r3, r1
	bgt.n	.L0802b89c
	b.n	.L0802b83c
.L0802b918:
	uxth	r0, r5
	ldr	r7, [sp, #0x2c]
	lsrs	r6, r0, #8
	uxtb	r5, r5
	lsls	r0, r4, #2
	mov.w	r12, #4
	add.w	lr, sp, #0x40
	nop
.L0802b92c:
	lsrs	r2, r4, #1
	ldrb.w	r2, [r9, r2]
	bic.w	r1, r12, r0
	lsr.w	r1, r2, r1
	and	r11, r1, #0xf
	ldrh.w	r1, [lr, r11, lsl #1]
	ldrh.w	r2, [r8, #0xa]
	adds	r4, #1
	strh.w	r2, [r10, #-2]		@ index 0x2a
	uxth	r2, r7
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	uxtb	r2, r7
	strh.w	r2, [r10]
	ldrh.w	r2, [r8]
	adds	r7, #1
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8]
	adds	r0, #4
	uxtb	r2, r2
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #0xc]
	strh.w	r2, [r10, #-2]		@ index 0x2b
	strh.w	r6, [r10]
	strh.w	r5, [r10]
	ldrh.w	r2, [r8, #2]
	lsrs	r2, r2, #8
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #2]
	uxtb	r2, r2
	strh.w	r2, [r10]
	ldrh.w	r2, [r8, #8]
	strh.w	r2, [r10, #-2]		@ index 0x2c
	strh.w	r1, [r10]
	sxth	r1, r7
	cmp	r3, r1
	bgt.n	.L0802b92c
	b.n	.L0802b83c
.L0802b9aa:
	uxth	r0, r5
	uxtb.w	lr, r5
	ldr	r5, [sp, #0x2c]
	lsrs	r6, r0, #8
	lsl.w	r9, r4, #2
.L0802b9b8:
	cmp.w	r12, #2
	itt	eq
	lsreq	r0, r4, #1
	ldrbeq.w	r11, [r2, r0]
	bic.w	r0, r7, r9
	uxtb.w	r1, r11
	lsr.w	r0, r1, r0
	and	r11, r0, #0xf
	add	r0, sp, #0x40
	ldrh.w	r0, [r0, r11, lsl #1]
	ldrh.w	r1, [r8, #0xa]
	adds	r4, #1
	strh.w	r1, [r10, #-2]		@ index 0x2a
	uxth	r1, r5
	lsrs	r1, r1, #8
	strh.w	r1, [r10]
	uxtb	r1, r5
	strh.w	r1, [r10]
	ldrh.w	r1, [r8]
	adds	r5, #1
	lsrs	r1, r1, #8
	strh.w	r1, [r10]
	ldrh.w	r1, [r8]
	add.w	r9, r9, #4
	uxtb	r1, r1
	strh.w	r1, [r10]
	ldrh.w	r1, [r8, #0xc]
	strh.w	r1, [r10, #-2]		@ index 0x2b
	strh.w	r6, [r10]
	strh.w	lr, [r10]
	ldrh.w	r1, [r8, #2]
	lsrs	r1, r1, #8
	strh.w	r1, [r10]
	ldrh.w	r1, [r8, #2]
	uxtb	r1, r1
	strh.w	r1, [r10]
	ldrh.w	r1, [r8, #8]
	strh.w	r1, [r10, #-2]		@ index 0x2c
	strh.w	r0, [r10]
	sxth	r0, r5
	cmp	r3, r0
	bgt.n	.L0802b9b8
	b.n	.L0802b84a
.L0802ba44:
	ldr	r0, [sp, #0x1c]
	add.w	r9, r4, r0
	cmp.w	r9, #1
	blt.w	.L0802bc80
	.include "src/parts/system_bring_up_p2.inc"
	.include "src/parts/system_bring_up_p3.inc"
	.include "src/parts/system_bring_up_p4.inc"
