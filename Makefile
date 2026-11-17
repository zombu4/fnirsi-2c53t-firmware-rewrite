# Build the FNIRSI 2C53T application image (GNU Arm Embedded toolchain: arm-none-eabi-as / ld / objcopy).
#   make        -> build/APP_2C53T.bin, this rewrite (About shows V1.2.1)
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

.PHONY: all clean check
