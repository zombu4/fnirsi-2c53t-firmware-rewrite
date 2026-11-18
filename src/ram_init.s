@ ram_init.s - initial RAM image 0x20000000..0x2000123F (0x1240 bytes), copied to RAM at reset.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
@ scatter_load_regions (src/startup_56.s) takes region 1 of the table d_080be314 (src/rodata.s):
@ source ram_init, destination 0x20000000, length 0x1240, handler copy_words. Every byte below lands
@ at 0x20000000 + its offset; the comment of each item names its RAM address.
@ Values: those of the V1.2.0 image after unpacking (ghidra/rwdata_20000000.bin of the project; its
@ packed stream was 0x080BE480..0x080BE67F), except (calibration rule, DATA_DESIGN.md "Invariant"):
@ - code addresses are function symbols (37 words; .word of a Thumb function gives the address with
@   bit 0 set, as in V1.2.0),
@ - the 24 font context words that point into the font data are the labels in src/rodata.s,
@ - the glyph cache pair of each font context (+0x14 key, +0x18 index) is key 0 / index 0xFFFFFFFF
@   (V1.2.0 held the last looked-up key and its index; key 0 is below every font's low bound 0x20,
@   so the cache never hits before the first lookup, lookup_sorted_table_* in src/filesystem_02.s),
@ - the bits-per-pixel word of the 25 px font context (0x20001198) is 0x08010000 (4 bpp): its glyphs
@   are the own 4 bpp DejaVu glyphs now (V1.2.0: 0x02010000, 1 bpp).
@ RAM addresses stored in the image are plain numbers: no RAM address changes meaning.
@ Offset guards (.if/.error) keep every item at its RAM address.
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb
	.section .rodata.ram_init,"a",%progbits
	.p2align 2			@ copy_words reads words
	.global ram_init
ram_init:

@ 0x20000000..0x2000000F
	.word	0xaaaaaaaa		@ 0x20000000
	.byte	0x64			@ 0x20000004: 100; fn_08009c78 limits [0x2000105f] to it and sets it to 100 (src/keys_26.s)
	.byte	0xaa, 0x55, 0x05	@ 0x20000005..0x20000007
	.space	7			@ 0x20000008..0x2000000E
	.byte	0x0a			@ 0x2000000F

@ 0x20000010..0x2000002F: USB mass-storage state
	.hword	0x0040			@ 0x20000010: 0x40, also written on a USB bus reset (src/usb_81.s)
	.hword	0x0000			@ 0x20000012
	.word	0x007a1200		@ 0x20000014: 8000000, the clock frequency word (stored by src/system_62.s, divided for SysTick)
@ 0x20000018..0x20000029: the 18 bytes the SCSI REQUEST SENSE command (opcode 0x03) copies (src/usb_82.s)
	.byte	0x70, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00	@ 0x20000018 (0x2000001A: 5, also written for an invalid command)
	.byte	0x0a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	@ 0x20000020
	.byte	0x20, 0x00		@ 0x20000028 (0x20, also written for an invalid command, src/usb_82.s)
	.space	6			@ 0x2000002A..0x2000002F

	.if (. - ram_init) != 0x30
	.error "ram_init: USB callback table not at 0x20000030"
	.endif
@ 0x20000030..0x20000053: callback table of the USB driver (passed as r0 with the table at 0x20000058
@ and the peripheral 0x40005C00 to the driver set-up 0x08040990, src/system_58.s)
	.word	init_state_arm_command_receive		@ 0x20000030
	.word	fn_08030ca0				@ 0x20000034
	.word	msc_control_request_handler		@ 0x20000038
	.word	return_zero_08030cbc			@ 0x2000003C
	.word	return_zero_08030cb8			@ 0x20000040
	.word	send_status_block_after_data		@ 0x20000044
	.word	handle_command_block_or_write_data	@ 0x20000048
	.word	return_zero_080312d0			@ 0x2000004C
	.word	return_zero_08030cc0			@ 0x20000050
	.word	0x20004e74				@ 0x20000054: RAM address 0x20004E74 (its use not traced)
@ 0x20000058..0x2000007F: descriptor-getter table of the USB driver (src/system_58.s, src/usb_82.s)
	.word	get_device_descriptor_record			@ 0x20000058
	.word	fn_08036db0					@ 0x2000005C
	.word	get_configuration_descriptor_record		@ 0x20000060
	.word	fn_08036d38					@ 0x20000064
	.word	get_language_id_descriptor_record		@ 0x20000068
	.word	fn_08036cfc					@ 0x2000006C
	.word	fn_08036d3c					@ 0x20000070
	.word	build_hex_id_string_descriptor_record		@ 0x20000074
	.word	set_string_descriptor_mass_storage_interface	@ 0x20000078
	.word	set_string_descriptor_mass_storage_config	@ 0x2000007C

	.if (. - ram_init) != 0x80
	.error "ram_init: USB descriptors not at 0x20000080"
	.endif
@ 0x20000080..0x2000009B: string descriptor, length 0x1a, type 3; its 12 UTF-16 hex digits (from
@ the words at 0x1FFFF7E8..0x1FFFF7F3) are written by build_hex_id_string_descriptor_record (src/usb_82.s)
	.byte	0x1a, 0x03		@ 0x20000080
	.space	26			@ 0x20000082..0x2000009B
	.word	0x0000001a		@ 0x2000009C: record {length 0x1a,
	.word	0x20000080		@ 0x200000A0:  pointer 0x20000080}
	.word	0x00000004		@ 0x200000A4: record {length 4,
	.word	0x200000ac		@ 0x200000A8:  pointer 0x200000AC}
	.byte	0x04, 0x03, 0x09, 0x04	@ 0x200000AC: language id string descriptor: length 4, type 3, language 0x0409
	.word	0x00000020		@ 0x200000B0: record {length 0x20,
	.word	0x200000b8		@ 0x200000B4:  pointer 0x200000B8}
@ 0x200000B8..0x200000D7: configuration descriptor (32 bytes)
	.byte	0x09, 0x02, 0x20, 0x00, 0x01, 0x01, 0x04, 0xc0, 0x32	@ 0x200000B8: configuration: total 0x20, 1 interface, value 1, string 4, attributes 0xc0, 0x32 * 2 mA
	.byte	0x09, 0x04, 0x00, 0x00, 0x02, 0x08, 0x06, 0x50, 0x05	@ 0x200000C1: interface 0, 2 endpoints, class 8 subclass 6 protocol 0x50 (mass storage, SCSI, bulk only), string 5
	.byte	0x07, 0x05, 0x81, 0x02, 0x40, 0x00, 0x00		@ 0x200000CA: endpoint 0x81, bulk, 0x40 bytes
	.byte	0x07, 0x05, 0x01, 0x02, 0x40, 0x00, 0x00		@ 0x200000D1: endpoint 0x01, bulk, 0x40 bytes
	.word	0x00000012		@ 0x200000D8: record {length 0x12,
	.word	0x200000e0		@ 0x200000DC:  pointer 0x200000E0}
@ 0x200000E0..0x200000F1: device descriptor (18 bytes)
	.byte	0x12, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x40	@ 0x200000E0: length 0x12, type 1, USB 0x0200, class 0, max packet 0x40
	.byte	0x3c, 0x2e, 0x20, 0x57, 0x00, 0x02		@ 0x200000E8: vendor 0x2e3c, product 0x5720, release 0x0200
	.byte	0x01, 0x02, 0x03, 0x01				@ 0x200000EE: strings 1, 2, 3, 1 configuration

	.if (. - ram_init) != 0xf2
	.error "ram_init: settings state not at 0x200000F2"
	.endif
@ 0x200000F2..0x20000147: state read and written by the measurement, scope and settings code (users
@ not traced one by one). system_bring_up (src/system_58.s) overwrites 0x200000F8..0x200000FF,
@ 0x2000010C..0x20000115, 0x20000125, 0x2000012C, 0x2000012D, 0x20000134, 0x20000140, 0x20000144..
@ 0x20000147 and more from the settings page 0x08006000 when its marker byte is 0x55 or 0xAA, so
@ the values below are the defaults for a meter without saved settings.
	.byte	0x02			@ 0x200000F2
	.space	7			@ 0x200000F3..0x200000F9
	.byte	0x05, 0x05, 0x32, 0xce	@ 0x200000FA..0x200000FD
	.space	14			@ 0x200000FE..0x2000010B
	.byte	0x03, 0x00, 0x00, 0x01	@ 0x2000010C..0x2000010F
	.space	4			@ 0x20000110..0x20000113
	.byte	0x32			@ 0x20000114
	.space	16			@ 0x20000115..0x20000124
	.byte	0x0d, 0x01		@ 0x20000125..0x20000126
	.space	29			@ 0x20000127..0x20000143
	.byte	0x05, 0x01, 0x05, 0x01	@ 0x20000144..0x20000147
	.space	482			@ 0x20000148..0x20000329

	.if (. - ram_init) != 0x32a
	.error "ram_init: halfwords not at 0x2000032A"
	.endif
@ 0x2000032A..0x20000331: words 0x0800601C and 0x08006020 of the settings page replace them when the
@ page is valid (system_bring_up)
	.hword	0xffb5			@ 0x2000032A: -75
	.hword	0x004b			@ 0x2000032C: 75
	.hword	0x0032			@ 0x2000032E: 50
	.hword	0xffce			@ 0x20000330: -50
	.space	2934			@ 0x20000332..0x20000EA7

	.if (. - ram_init) != 0xea8
	.error "ram_init: word not at 0x20000EA8"
	.endif
	.word	0x00000002		@ 0x20000EA8: 2
	.space	164			@ 0x20000EAC..0x20000F4F

@ 0x20000F50..0x20000F59: defaults; system_bring_up replaces them from the settings page words
@ 0x08006024 (bytes to 0x20000F50, F51, F58, F59) and 0x08006028 (word to 0x20000F54) when it is valid
	.byte	0x01			@ 0x20000F50: 1
	.byte	0x00			@ 0x20000F51: 0
	.space	2			@ 0x20000F52..0x20000F53
	.word	1000			@ 0x20000F54: 1000
	.byte	0x32			@ 0x20000F58: 0x32
	.byte	0x1e			@ 0x20000F59: 0x1e
	.space	254			@ 0x20000F5A..0x20001057

	.if (. - ram_init) != 0x1058
	.error "ram_init: language byte not at 0x20001058"
	.endif
@ 0x20001058..0x2000105B: word 0x0800602C of the settings page when it is valid; otherwise
@ system_bring_up sets the low byte (the language byte, no longer read for texts) to 2
	.byte	0x00			@ 0x20001058: language byte
	.byte	0x64			@ 0x20001059: 100
	.byte	0x01			@ 0x2000105A: 1
	.byte	0x00			@ 0x2000105B
	.byte	0x00, 0x01		@ 0x2000105C: halfword 0x0100 (low half of settings word 0x08006030 when valid)
	.byte	0x05			@ 0x2000105E: 5 (fn_08009c78 sets 4, src/keys_26.s)
	.byte	0x64			@ 0x2000105F: 100 (fn_08009c78 stores 100..5 and limits it to [0x20000004])
	.space	16			@ 0x20001060..0x2000106F

	.if (. - ram_init) != 0x1070
	.error "ram_init: allocator state not at 0x20001070"
	.endif
@ 0x20001070..0x20001083: allocator state (src/heap_15.s, base r5 = 0x20001070)
	.word	init_alloc_table	@ 0x20001070: called when the flag byte 0x20001080 is 0
	.word	alloc_table_used_permille	@ 0x20001074
	.word	0x200083c0		@ 0x20001078: RAM address 0x200083C0 (the offset base of the allocator)
	.word	0x20033fc0		@ 0x2000107C: RAM address 0x20033FC0, table pointer of index 0
	.word	0x00000000		@ 0x20001080: flag bytes 0x20001080 + index, 0 = table not cleared yet

	.if (. - ram_init) != 0x1084
	.error "ram_init: font objects not at 0x20001084"
	.endif
@ 0x20001084..0x20001203: 8 fonts, each a font object (20 bytes) followed by its context (28 bytes)
@ (DATA_INVENTORY.md 2.1). Object: +0 glyph-fields callback, +4 bitmap-pointer callback, +8 halfword
@ pixel size, +0x10 pointer to the context. Context: +0 glyph data base, +4 record table, +8 range
@ descriptor, +0x10 word whose halfword +0x12 gives the bits per pixel ((h & 0x1fff) >> 9: 0x0801 = 4,
@ 0x0201 = 1), +0x14 cached key, +0x18 cached index.

@ 12 px font: object 0x20001084, context 0x20001098
	.word	lookup_sorted_table_fields_0802f6e0	@ 0x20001084
	.word	lookup_sorted_table_ptr_0802f340	@ 0x20001088
	.hword	12, 0					@ 0x2000108C: size 12
	.word	0					@ 0x20001090
	.word	0x20001098				@ 0x20001094: context
	.word	d_0806f334				@ 0x20001098: data base
	.word	d_0806f9d8				@ 0x2000109C: record table
	.word	d_0806fcd8				@ 0x200010A0: range descriptor
	.word	0					@ 0x200010A4
	.word	0x08010000				@ 0x200010A8: 4 bits per pixel
	.word	0x00000000				@ 0x200010AC: cached key (V1.2.0: 0x7f)
	.word	0xffffffff				@ 0x200010B0: cached index (V1.2.0: 0x5f)

@ 15 px font: object 0x200010B4, context 0x200010C8
	.word	lookup_sorted_table_fields_0802f774	@ 0x200010B4
	.word	lookup_sorted_table_ptr_0802f3b4	@ 0x200010B8
	.hword	15, 0					@ 0x200010BC: size 15
	.word	0					@ 0x200010C0
	.word	0x200010c8				@ 0x200010C4: context
	.word	d_0806fdae				@ 0x200010C8: data base
	.word	d_08076938				@ 0x200010CC: record table
	.word	d_08077b10				@ 0x200010D0: range descriptor
	.word	0					@ 0x200010D4
	.word	0x08010000				@ 0x200010D8: 4 bits per pixel
	.word	0x00000000				@ 0x200010DC: cached key (V1.2.0: 0xff1a)
	.word	0xffffffff				@ 0x200010E0: cached index (V1.2.0: 0x23a)

@ 16 px font: object 0x200010E4, context 0x200010F8
	.word	lookup_sorted_table_fields_0802f808	@ 0x200010E4
	.word	lookup_sorted_table_ptr_0802f428	@ 0x200010E8
	.hword	16, 0					@ 0x200010EC: size 16
	.word	0					@ 0x200010F0
	.word	0x200010f8				@ 0x200010F4: context
	.word	d_08077f9c				@ 0x200010F8: data base
	.word	d_080807f0				@ 0x200010FC: record table
	.word	d_080819a8				@ 0x20001100: range descriptor
	.word	0					@ 0x20001104
	.word	0x08010000				@ 0x20001108: 4 bits per pixel
	.word	0x00000000				@ 0x2000110C: cached key (V1.2.0: 0xff1a)
	.word	0xffffffff				@ 0x20001110: cached index (V1.2.0: 0x236)

@ 18 px font: object 0x20001114, context 0x20001128
	.word	lookup_sorted_table_fields_0802f89c	@ 0x20001114
	.word	lookup_sorted_table_ptr_0802f49c	@ 0x20001118
	.hword	18, 0					@ 0x2000111C: size 18
	.word	0					@ 0x20001120
	.word	0x20001128				@ 0x20001124: context
	.word	d_08081e2c				@ 0x20001128: data base
	.word	d_0808b214				@ 0x2000112C: record table
	.word	d_0808c3cc				@ 0x20001130: range descriptor
	.word	0					@ 0x20001134
	.word	0x08010000				@ 0x20001138: 4 bits per pixel
	.word	0x00000000				@ 0x2000113C: cached key (V1.2.0: 0xff1a)
	.word	0xffffffff				@ 0x20001140: cached index (V1.2.0: 0x236)

@ 20 px font: object 0x20001144, context 0x20001158
	.word	lookup_sorted_table_fields_0802f930	@ 0x20001144
	.word	lookup_sorted_table_ptr_0802f510	@ 0x20001148
	.hword	20, 0					@ 0x2000114C: size 20
	.word	0					@ 0x20001150
	.word	0x20001158				@ 0x20001154: context
	.word	d_0808c850				@ 0x20001158: data base
	.word	d_08098fdc				@ 0x2000115C: record table
	.word	d_0809a194				@ 0x20001160: range descriptor
	.word	0					@ 0x20001164
	.word	0x08010000				@ 0x20001168: 4 bits per pixel
	.word	0x00000000				@ 0x2000116C: cached key (V1.2.0: 0xff1a)
	.word	0xffffffff				@ 0x20001170: cached index (V1.2.0: 0x236)

@ 25 px font: object 0x20001174, context 0x20001188
	.word	lookup_sorted_table_fields_0802f9c4	@ 0x20001174
	.word	lookup_sorted_table_ptr_0802f584	@ 0x20001178
	.hword	25, 0					@ 0x2000117C: size 25
	.word	0					@ 0x20001180
	.word	0x20001188				@ 0x20001184: context
	.word	d_0809a618				@ 0x20001188: data base
	.word	d_080a0468				@ 0x2000118C: record table
	.word	d_080a1630				@ 0x20001190: range descriptor
	.word	0					@ 0x20001194
	.word	0x08010000				@ 0x20001198: 4 bits per pixel (V1.2.0: 0x02010000, 1 bpp)
	.word	0x00000000				@ 0x2000119C: cached key (V1.2.0: 0xff1a)
	.word	0xffffffff				@ 0x200011A0: cached index (V1.2.0: 0x238)

@ 28 px font: object 0x200011A4, context 0x200011B8
	.word	lookup_sorted_table_fields_0802fa58	@ 0x200011A4
	.word	lookup_sorted_table_ptr_0802f5f8	@ 0x200011A8
	.hword	28, 0					@ 0x200011AC: size 28
	.word	0					@ 0x200011B0
	.word	0x200011b8				@ 0x200011B4: context
	.word	d_080a1ab8				@ 0x200011B8: data base
	.word	d_080b9000				@ 0x200011BC: record table
	.word	d_080ba1b8				@ 0x200011C0: range descriptor
	.word	0					@ 0x200011C4
	.word	0x08010000				@ 0x200011C8: 4 bits per pixel
	.word	0x00000000				@ 0x200011CC: cached key (V1.2.0: 0xff1a)
	.word	0xffffffff				@ 0x200011D0: cached index (V1.2.0: 0x236)

@ 63 px font: object 0x200011D4, context 0x200011E8
	.word	lookup_sorted_table_fields_0802faec	@ 0x200011D4
	.word	lookup_sorted_table_ptr_0802f66c	@ 0x200011D8
	.hword	63, 0					@ 0x200011DC: size 63
	.word	0					@ 0x200011E0
	.word	0x200011e8				@ 0x200011E4: context
	.word	d_080ba63c				@ 0x200011E8: data base
	.word	d_080bb2f0				@ 0x200011EC: record table
	.word	d_080bb3a8				@ 0x200011F0: range descriptor
	.word	0					@ 0x200011F4
	.word	0x02010000				@ 0x200011F8: 1 bit per pixel
	.word	0x00000000				@ 0x200011FC: cached key (V1.2.0: 0x73)
	.word	0xffffffff				@ 0x20001200: cached index (V1.2.0: 0x16)

	.if (. - ram_init) != 0x1204
	.error "ram_init: fonts do not end at 0x20001204"
	.endif
	.space	60			@ 0x20001204..0x2000123F
	.global ram_init_end
ram_init_end:
	.if (ram_init_end - ram_init) != 0x1240
	.error "ram_init: the image must be 0x1240 bytes (region 1 length in src/rodata.s)"
	.endif
