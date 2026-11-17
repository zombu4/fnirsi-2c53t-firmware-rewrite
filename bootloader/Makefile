# Build the stock FNIRSI 2C53T bootloader from source (GNU Arm Embedded toolchain: arm-none-eabi-as / ld / objcopy).
#   make         -> build/BOOT.bin, the bootloader part only: 0x08000000..0x08005873 (0x5874 bytes)
#   make padded  -> build/BOOT_padded.bin, the same bytes padded with 0xFF to 0x08005FFF (0x6000 bytes)
#   make check   -> compares both with the stock bootloader dump (SHA-256 below)
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

all: build/BOOT.bin

build/%.o: src/%.s $(INC) | build
	$(AS) $(ASFLAGS) -o $@ $<

build/boot.elf: $(OBJ) link.ld
	$(LD) --no-warn-rwx-segments -T link.ld -Map build/boot.map -o $@ $(OBJ)

build/BOOT.bin: build/boot.elf
	$(OBJCOPY) -O binary $< $@

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

.PHONY: all padded clean check
