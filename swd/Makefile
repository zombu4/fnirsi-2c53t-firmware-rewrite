# Build the SWD loader (FLASHING_BOOTLOADER.md).
#   make        -> build/swd_loader.bin (RAM program for 0x20000000)
#   make clean
CROSS   ?= arm-none-eabi-
build/swd_loader.bin: swd_loader.s | build
	$(CROSS)as -o build/swd_loader.o $<
	$(CROSS)ld -Ttext=0x20000000 -e loader_start -o build/swd_loader.elf build/swd_loader.o
	$(CROSS)objcopy -O binary build/swd_loader.elf $@
build:
	mkdir -p $@
clean:
	rm -rf build
.PHONY: clean
