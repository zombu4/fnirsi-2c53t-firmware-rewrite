# Build the FNIRSI 2C53T application image (GNU Arm Embedded toolchain: arm-none-eabi-as / ld / objcopy).
#   make        -> build/APP_2C53T.bin, this rewrite (About shows the version in
#                  src/parts/draw_page_by_selector_nibble_p2.inc); builds the starter and the bootloader
#                  images it embeds first (src/boot_install.s)
#   make clean
CROSS   ?= arm-none-eabi-
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
ASFLAGS := -I .
SRC     := $(wildcard src/*.s)
INC     := $(wildcard src/parts/*.inc)
OBJ     := $(patsubst src/%.s,build/%.o,$(SRC))

all: build/APP_2C53T.bin

build/%.o: src/%.s $(INC) | build
	$(AS) $(ASFLAGS) -o $@ $<

# binary assets included by src/rodata.s (.incbin)
build/rodata.o: $(wildcard assets/*.bin assets/fonts/*.bin assets/pictures/*.bin)

# images embedded by src/boot_install.s (its object is rebuilt whenever a sub-make ran)
IMAGES := starter/build/STARTER.bin \
	bootloader/build/slot/BOOT_F.bin bootloader/build/slot/BOOT_A.bin bootloader/build/slot/BOOT_B.bin
build/boot_install.o: $(IMAGES) common/layout.inc common/records.inc
starter/build/STARTER.bin: FORCE
	$(MAKE) -C starter
bootloader/build/slot/BOOT_F.bin bootloader/build/slot/BOOT_A.bin bootloader/build/slot/BOOT_B.bin: FORCE
	$(MAKE) -C bootloader slot
FORCE:

build/app.elf: $(OBJ) link.ld
	$(LD) --no-warn-rwx-segments -T link.ld -Map build/app.map -o $@ $(OBJ)

build/APP_2C53T.bin: build/app.elf
	$(OBJCOPY) -O binary $< $@

build:
	mkdir -p $@

clean:
	rm -rf build
	$(MAKE) -C starter clean
	$(MAKE) -C bootloader clean

.PHONY: all clean FORCE
