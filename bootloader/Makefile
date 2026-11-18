# Build the FNIRSI 2C53T bootloader from source (GNU Arm Embedded toolchain: arm-none-eabi-as / ld / objcopy).
#   make         -> build/slot/BOOT_F.bin, BOOT_A.bin, BOOT_B.bin (same as make slot)
#   make slot    -> build/slot/BOOT_F.bin, BOOT_A.bin, BOOT_B.bin: the slot build (assembled with
#                   --defsym SLOT=1: slot_11.s and every .ifdef SLOT change), one image per slot, each
#                   linked for slot base + 0x200 (link_slot.ld); the slot header is written by the
#                   installer, not here
#   make vendor-data DUMP=<BOOTDUMP.BIN>
#                -> assets/vendor/rodata.bin: the fixed-data bytes 0x080049A4..0x08005873 of a meter's
#                   own bootloader dump (font, packed RAM image); not part of this repository
#   make stock   -> build/BOOT.bin, the stock bootloader rebuilt from source with that vendor data
#                   (assembled with --defsym VENDOR_DATA=1): 0x08000000..0x08005873 (0x5874 bytes)
#   make check   -> make stock, then BOOT.bin and BOOT_padded.bin compared with the stock bootloader
#                   dump (SHA-256 below): the byte proof of the port
#   make clean
# The settings / calibration page 0x08006000.. is NOT part of this source and is never built or linked
# (link.ld ends FLASH at 0x08006000).  Padding rule: the dump bytes 0x5874..0x5FFF are all 0xFF (checked
# 2026-11-17), so the padded image fills them with 0xFF.
CROSS   ?= arm-none-eabi-
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
ASFLAGS := -I .
SRC     := $(wildcard src/*.s)
INC     := $(wildcard src/parts/*.inc)
OBJ     := $(patsubst src/%.s,build/%.o,$(SRC))

all: slot

stock: build/BOOT.bin

VENDOR_DATA_FILE := assets/vendor/rodata.bin
$(VENDOR_DATA_FILE):
	@echo "missing $@: run make vendor-data DUMP=<BOOTDUMP.BIN of a meter> first"; exit 1

vendor-data:
	@test -n "$(DUMP)" || { echo "usage: make vendor-data DUMP=<BOOTDUMP.BIN>"; exit 1; }
	@test `wc -c < "$(DUMP)"` -eq 28672 || { echo "$(DUMP) is not a 0x7000-byte BOOTDUMP.BIN"; exit 1; }
	mkdir -p assets/vendor
	dd if="$(DUMP)" of=$(VENDOR_DATA_FILE) bs=1 skip=$$((0x49A4)) count=$$((0xED0)) 2>/dev/null
	@echo "assets/vendor/rodata.bin: 3792 bytes from $(DUMP)"

build/%.o: src/%.s $(INC) $(VENDOR_DATA_FILE) | build
	$(AS) $(ASFLAGS) --defsym VENDOR_DATA=1 -o $@ $<

build/boot.elf: $(OBJ) link.ld
	$(LD) --no-warn-rwx-segments -T link.ld -Map build/boot.map -o $@ $(OBJ)

build/BOOT.bin: build/boot.elf
	$(OBJCOPY) -O binary $< $@

slot: build/slot/BOOT_F.bin build/slot/BOOT_A.bin build/slot/BOOT_B.bin

SLOT_OBJ := $(patsubst src/%.s,build/slot/%.o,$(SRC))

build/slot/%.o: src/%.s $(INC) assets/font_12x24.bin ../common/layout.inc ../common/records.inc | build/slot
	$(AS) $(ASFLAGS) -I .. --defsym SLOT=1 -o $@ $<

build/slot/boot_%.elf: $(SLOT_OBJ) link_slot.ld
	$(LD) --no-warn-rwx-segments -T link_slot.ld --defsym SLOT_BASE=$(SLOT_BASE_$*) \
		--defsym SLOT_SIZE=$(SLOT_SIZE_$*) -Map build/slot/boot_$*.map -o $@ $(SLOT_OBJ)

build/slot/BOOT_%.bin: build/slot/boot_%.elf
	$(OBJCOPY) -O binary $< $@
	@echo "$@: $$(wc -c < $@ | tr -d ' ') bytes"

SLOT_BASE_F := 0x080E8000
SLOT_SIZE_F := 0x8000
SLOT_BASE_A := 0x080F0000
SLOT_SIZE_A := 0x8000
SLOT_BASE_B := 0x080F8000
SLOT_SIZE_B := 0x8000

build/slot:
	mkdir -p $@

padded: build/BOOT_padded.bin

build/BOOT_padded.bin: build/boot.elf
	$(OBJCOPY) -O binary --pad-to 0x08006000 --gap-fill 0xFF $< $@

build:
	mkdir -p $@

# SHA-256 of bytes 0x0000..0x5873 (0x5874 bytes) and of bytes 0x0000..0x5FFF (0x6000 bytes) of
# dumps/BOOTDUMP_2026-11-17.bin (the stock bootloader flash dump, 0x7000 bytes from 0x08000000)
BOOT_SHA256   := d1622ae5c5af1adfc618908cc33be2fa7ef901f1bda587345f5d1de6b76887b5
PADDED_SHA256 := 7a6201ee16ce155675f1d235e468edfdce7a736318f2591d54a221d4ad06566b
check: build/BOOT.bin build/BOOT_padded.bin
	@test `wc -c < build/BOOT.bin` -eq 22644 || { echo "BOOT.bin is not 0x5874 bytes"; exit 1; }
	@test `wc -c < build/BOOT_padded.bin` -eq 24576 || { echo "BOOT_padded.bin is not 0x6000 bytes"; exit 1; }
	@echo "$(BOOT_SHA256)  build/BOOT.bin" | shasum -a 256 -c -
	@echo "$(PADDED_SHA256)  build/BOOT_padded.bin" | shasum -a 256 -c -

clean:
	rm -rf build

.PHONY: all stock padded slot clean check vendor-data

.PRECIOUS: build/slot/boot_%.elf build/slot/%.o
