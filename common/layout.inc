@ layout.inc - flash layout and record format shared by the starter, the slot bootloaders and the
@ installer of the two-part bootloader.  Part of the FNIRSI 2C53T firmware rewrite.
@
@ Flash (1024 KB, 2 KB pages; bank 1 0x08000000..0x0807FFFF, bank 2 0x08080000..0x080FFFFF):
@   0x08000000..0x080007FF  starter (this program), written once
@   0x08006000..0x080067FF  the meter's settings / calibration page: never written by any of these
@   0x08006800..0x08006FFF  "8KTA" page (update success mark, as the stock bootloader)
@   0x08007000..0x080E6FFF  application area (896 KB)
@   0x080E7000, 0x080E7800  record pages (append-only records, two pages used in turn)
@   0x080E8000..0x080EFFFF  slot F (factory bootloader, written once, never erased)
@   0x080F0000..0x080F7FFF  slot A
@   0x080F8000..0x080FFFFF  slot B
@ Slots are 32 KB: the slot build of the bootloader is 23476 bytes (make -C bootloader slot).
@ A slot holds a header in its first 0x200 bytes and the bootloader image (vector table first) from
@ slot + 0x200 (VTOR needs a 512-byte boundary for the 97-entry table).  The header is written last
@ and is the slot's valid mark.

	.equ	SLOT_F_BASE,	0x080E8000
	.equ	SLOT_A_BASE,	0x080F0000
	.equ	SLOT_B_BASE,	0x080F8000
	.equ	SLOT_SIZE,	0x00008000	@ every slot, header included
	.equ	SLOT_IMAGE_OFS,	0x200

@ slot header (at the slot base)
	.equ	HDR_MAGIC,	0x00		@ word 0x544F4C53 ("SLOT")
	.equ	HDR_FORMAT,	0x04		@ word 1
	.equ	HDR_LINK,	0x08		@ word: the slot base the image is linked for
	.equ	HDR_LENGTH,	0x0C		@ word: image length in bytes from slot + 0x200
	.equ	HDR_IMAGE_CRC,	0x10		@ word: CRC-32 of the image
	.equ	HDR_VERSION,	0x14		@ word: bootloader version
	.equ	HDR_CRC,	0x18		@ word: CRC-32 of bytes 0x00..0x17
	.equ	SLOT_MAGIC,	0x544F4C53
	.equ	SLOT_FORMAT,	1
	.equ	SLOT_IMAGE_VERSION, 2		@ HDR_VERSION the installer writes for this source (2: staged updates)

@ record pages and records (16 bytes; an erased cell reads all 0xFF)
	.equ	REC_PAGE0,	0x080E7000
	.equ	REC_PAGE1,	0x080E7800
	.equ	REC_PAGE_SIZE,	0x800
	.equ	REC_CELLS,	128
	.equ	REC_MAGIC_OFS,	0x00		@ halfword 0xB007
	.equ	REC_STATE_OFS,	0x02		@ byte: 1 INSTALL, 2 TRIAL, 3 OK
	.equ	REC_SLOT_OFS,	0x03		@ byte: 0 F, 1 A, 2 B
	.equ	REC_SEQ_OFS,	0x04		@ word: sequence number, +1 per record
	.equ	REC_VERSION_OFS, 0x08		@ word: version of the slot's bootloader
	.equ	REC_CRC_OFS,	0x0C		@ word: CRC-32 of bytes 0x00..0x0B
	.equ	REC_MAGIC,	0xB007
	.equ	ST_INSTALL,	1
	.equ	ST_TRIAL,	2
	.equ	ST_OK,		3
	.equ	SLOT_ID_F,	0
	.equ	SLOT_ID_A,	1
	.equ	SLOT_ID_B,	2

@ flash controller, bank 2 (register use as the stock bootloader: 0x08002170, 0x080023C4, 0x080022A4)
	.equ	FLASH_KEYR2,	0x40022044
	.equ	FLASH_STS2,	0x4002204C	@ bit 0 busy, bit 2 program error, bit 4 write-protect error
	.equ	FLASH_CTRL2,	0x40022050	@ bit 0 PG, bit 1 PER, bit 6 STRT, bit 7 LOCK
	.equ	FLASH_ADDR2,	0x40022054
	.equ	FLASH_KEY1,	0x45670123
	.equ	FLASH_KEY2,	0xCDEF89AB

@ starter signature: two words right after the starter's vector table (the installer's test for a
@ starter in page 0, independent of the starter's version)
	.equ	STARTER_SIG_ADDR, 0x08000184
	.equ	STARTER_SIG,	0x54525453	@ "STRT"
	.equ	STARTER_SIG_FORMAT, 1

@ fault flag: a RAM word the starter's fault handler sets before it resets the core; on the next
@ start the starter clears it and starts slot F without reading the records
	.equ	FAULT_FLAG_ADDR, 0x20000000
	.equ	FAULT_FLAG,	0x5AFEF417

@ key test (the update key of the stock bootloader: PE2 and PE3, main 0x08002938, 0x080004B0)
	.equ	RCC_APB2EN,	0x40021018	@ bit 6: port E clock (set by the stock code at 0x0800033C)
	.equ	GPIOE_CFGLR,	0x40011800	@ 4 bits per pin 0..7
	.equ	GPIOE_IDR,	0x40011808
	.equ	GPIOE_ODR,	0x4001180C

@ valid application / bootloader stack pointer range (vendor application SP 0x20036F90)
	.equ	RAM_LO,		0x20000000
	.equ	RAM_HI,		0x20038000

@ application area and the slot bootloader's flash gate (stock layout: "8KTA" page 0x08006800, the
@ application from 0x08007000; the record pages start at APP_END)
	.equ	APP_BASE,	0x08007000
	.equ	APP_END,	0x080E7000
	.equ	APP_AREA_SIZE,	0x000E7000	@ APP_END - 0x08000000 (the geometry word 0x2000041C)
	.equ	KTA_ADDR,	0x08006800	@ "8KTA" success mark (stock 0x0800208C / 0x080020AC)
	.equ	KTA_WORD,	0x41544B38
	.equ	GATE_LO,	0x08006800
	.equ	GATE_HI,	0x080E7000

@ application <-> slot bootloader (version 2) words in RAM 0x20037FE0..0x20037FFF: the only RAM that no
@ start-up initialises (the application's RAM image and zeroed area end at 0x20036F8F, its stack top is
@ 0x20036F90; the bootloader's RAM ends at 0x20001A08, the starter's stack is below that); inside the
@ 224 KB the application needs (EOPB0 = FE); they survive a system reset (CONTROL_DESIGN.md revision 2,
@ items 3 and 4)
	.equ	FAULT_ADDR,	0x20037FB0	@ fault record (48 bytes, src/fault.s): the top of the USB control
						@ area (src/parts/usb_ctl.inc), above the job stack
	.equ	FAULT_MAGIC,	0xFA017EC0
	.equ	REQ_ADDR,	0x20037FE0	@ update request, written by the application before its reset:
	.equ	REQ_MAGIC,	0xB0075AFE	@   +0 magic, +4 image CRC-32, +8 image length, +12 ~magic
	.equ	HANDOVER_ADDR,	0x20037FF0	@ hand-over, written by the bootloader before it starts the
	.equ	HANDOVER_MAGIC,	0xB007C0DE	@   application: +0 magic, +4 slot id, +8 bootloader version,
						@   +12 result of the last staged update (UPD_*)
	.equ	UPD_NONE,	0
	.equ	UPD_OK,		1
	.equ	UPD_NO_FILE,	2		@ 2:/UPDATE/APP.BIN missing or the volume not readable
	.equ	UPD_BAD_IMAGE,	3		@ length / CRC-32 / vector table do not match the request
	.equ	UPD_FLASH_FAIL,	4		@ programmed application does not compare
	.equ	BOOT_VERSION_STAGED, 2		@ first slot bootloader version with staged updates

@ serial flash (research 2026-11-17, src/serial_flash_52.s): SPI 0x40003800, chip select PB12 low;
@ drive "2:" is a FAT volume from serial flash byte 0x200000, 4096-byte sectors
	.equ	SPI2_BASE,	0x40003800
	.equ	VOL2_BASE,	0x00200000
	.equ	IWDG_KEY,	0x40003000	@ independent watchdog key register: 0xAAAA reloads it
