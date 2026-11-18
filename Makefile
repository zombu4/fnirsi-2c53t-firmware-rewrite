# Build the FNIRSI 2C53T application image (GNU Arm Embedded toolchain: arm-none-eabi-as / ld / objcopy).
#   make        -> build/APP_2C53T.bin, this rewrite (About shows the version in
#                  src/parts/draw_page_by_selector_nibble_p2.inc); builds the starter and the bootloader
#                  images it embeds first (src/boot_install.s)
#   make check  -> builds the same source with the vendor version text into build/vendor/ and
#                  verifies it against the SHA-256 of the vendor V1.2.0 application image
#   make clean
CROSS   ?= arm-none-eabi-
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
ASFLAGS := -I .
SRC     := $(wildcard src/*.s)
INC     := $(wildcard src/parts/*.inc)
OBJ     := $(patsubst src/%.s,build/%.o,$(SRC))
VOBJ    := $(patsubst src/%.s,build/vendor/%.o,$(SRC))

all: build/APP_2C53T.bin

build/%.o: src/%.s $(INC) | build
	$(AS) $(ASFLAGS) -o $@ $<

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

build/vendor/%.o: src/%.s $(INC) | build/vendor
	$(AS) $(ASFLAGS) --defsym VENDOR_V120=1 -o $@ $<

build/vendor/app.elf: $(VOBJ) link.ld
	$(LD) --no-warn-rwx-segments -T link.ld -o $@ $(VOBJ)

build/vendor/APP_2C53T_V1.2.0.bin: build/vendor/app.elf
	$(OBJCOPY) -O binary $< $@

build build/vendor:
	mkdir -p $@

# SHA-256 of the vendor application image V1.2.0 (APP_2C53T_V1.2.0_251015.bin)
VENDOR_SHA256 := a17c5c35c97bb898f15672a1747bc1041d8ed507c16999ddba0d1e4e2ec0c760
check: build/vendor/APP_2C53T_V1.2.0.bin
	@echo "$(VENDOR_SHA256)  $<" | shasum -a 256 -c -

clean:
	rm -rf build
	$(MAKE) -C starter clean
	$(MAKE) -C bootloader clean

.PHONY: all clean check FORCE
