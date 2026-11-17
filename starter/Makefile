# Build the starter (first stage of the two-part bootloader, flash page 0).
#   make        -> build/STARTER.bin (at most 2048 bytes, for 0x08000000)
#   make clean
CROSS   ?= arm-none-eabi-
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy

all: build/STARTER.bin

build/starter.o: src/starter.s src/layout.inc | build
	$(AS) -I . -o $@ $<

build/starter.elf: build/starter.o link.ld
	$(LD) --no-warn-rwx-segments -T link.ld -Map build/starter.map -o $@ build/starter.o

build/STARTER.bin: build/starter.elf
	$(OBJCOPY) -O binary $< $@
	@echo "starter: $$(wc -c < $@ | tr -d ' ') bytes of 2048"

build:
	mkdir -p $@

clean:
	rm -rf build

.PHONY: all clean
