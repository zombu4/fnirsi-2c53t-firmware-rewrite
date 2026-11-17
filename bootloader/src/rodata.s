@ rodata.s - the fixed data of the stock bootloader, flash 0x080049A4..0x08005873 (0xED0 bytes)
@ Contents in address order: the first bytes of the virtual-disk boot-sector block, the font of the
@ bootloader text, the clock shift table, the scatter-load region table and the packed RAM image.
@ Long items without an address word are taken from assets/rodata.bin (the dump bytes of this region,
@ offset = address - 0x080049A4).  The labels d_<address> are the ones the code references (some of
@ them as label+1, the address of the item that follows).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

	.section .rodata.fixed,"a",%progbits

@ ----------------------------------------------------------------------------
@ 0x080049A4..0x080049D2 (47 bytes): the block fn_08001e24 copies into the virtual disk's boot
@ sector at sector offset 0x0B..0x39 (base 0x080049A4, 0x2F bytes).  It holds the bytes 20 00, then
@ the directory entry "IAP" + 8 spaces + attribute 08 (volume label) at 0x080049B9..0x080049C4.
@ ----------------------------------------------------------------------------
	.global d_080049a4
d_080049a4:
	.byte	0x20, 0x00
@ 0x080049A6..0x080049B8: 19 bytes before "IAP"
	.byte	0x4b, 0x9c, 0x42, 0x92, 0x38, 0x92, 0x38, 0x00, 0x00, 0x9d, 0x42, 0x92, 0x38
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ 0x080049B9: "IAP", 8 spaces, volume-label attribute 08
	.ascii	"IAP"
	.ascii	"        "
	.byte	0x08
@ 0x080049C5..0x080049CE: 10 zero bytes
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ 0x080049CF..0x080049D1, then the last byte of the block at 0x080049D2 (label for d_080049d2+1)
	.byte	0x9d, 0x42, 0x92
	.global d_080049d2
d_080049d2:
	.byte	0x38

@ ----------------------------------------------------------------------------
@ 0x080049D3..0x080049D6 (4 bytes): first FAT entries of the virtual disk, f8 ff ff ff
@ (0xFFF8, 0xFFFF), copied by fn_08001e24 to the start of sector offsets 0x3000 and 0x3800.
@ The label d_080049d6 is the last byte; the code references it as d_080049d6+1.
@ ----------------------------------------------------------------------------
	.byte	0xf8, 0xff, 0xff
	.global d_080049d6
d_080049d6:
	.byte	0xff

@ ----------------------------------------------------------------------------
@ 0x080049D7..0x08005732 (3420 bytes): packed bitmap font of the bootloader text, 95 rows of 36
@ bytes for the character codes 0x20..0x7E (24-pixel glyphs, 3 bytes per column, MSB first), read
@ by draw_glyph at row address 0x080049D7 + (code - 0x20) * 0x24.  The first 3419 bytes come from
@ assets/rodata.bin offset 0x33; the last byte 0x08005732 carries the label d_08005732 (the code
@ references d_08005732+1, the table that follows).
@ ----------------------------------------------------------------------------
	.incbin	"assets/rodata.bin", 0x33, 3419
	.global d_08005732
d_08005732:
	.byte	0x00

@ ----------------------------------------------------------------------------
@ 0x08005733..0x08005743 (17 bytes): clock shift table, indexed by bits 7..4 of [0x40021004]
@ (index 0..15) in fn_08002c68: shift 0 for index 0..7, then 1,2,3,4,6,7,8,9 for index 8..15;
@ the final 00 at 0x08005743 is not indexed.
@ ----------------------------------------------------------------------------
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x01, 0x02, 0x03, 0x04, 0x06, 0x07, 0x08, 0x09
	.byte	0x00

@ ----------------------------------------------------------------------------
@ 0x08005744..0x08005763 (two 16-byte entries): scatter-load region table read by
@ scatter_load_regions as {source, destination, length, handler}.  Entry 0 unpacks the packed RAM
@ image (0x1C8 bytes into 0x20000000) with unpack_literal_run_stream; entry 1 zero-fills 0x1840
@ bytes at 0x200001C8..0x20001A07 with zero_fill_region (source word 0x08005874 is ignored by the
@ handler).  The handler words are the even addresses 0x080001C0 and 0x0800021C.
@ ----------------------------------------------------------------------------
	.p2align 2
	.global region_table
region_table:
	.word	packed_ram_image		@ entry 0 source 0x08005764
	.word	0x20000000			@ entry 0 destination
	.word	0x000001c8			@ entry 0 length
	.word	unpack_literal_run_stream_addr	@ entry 0 handler 0x080001C0
	.word	0x08005874			@ entry 1 source (unused by the handler)
	.word	0x200001c8			@ entry 1 destination
	.word	0x00001840			@ entry 1 length
	.word	zero_fill_region_addr		@ entry 1 handler 0x0800021C

@ ----------------------------------------------------------------------------
@ 0x08005764..0x08005873 (272 bytes): the packed RAM image, a literal-run stream that
@ unpack_literal_run_stream expands into the 0x1C8 bytes at RAM 0x20000000 (it holds the strings
@ "AT32 ", "MSDOS5.0", "FAT16", "Ready", "TXT" and the data fn_08001e24 copies from RAM 0x2000002C
@ and 0x2000006A).
@ ----------------------------------------------------------------------------
	.global packed_ram_image
packed_ram_image:
	.incbin	"assets/rodata.bin", 0xdc0, 272
