# Build the FNIRSI 2C53T application image (GNU Arm Embedded toolchain: arm-none-eabi-as / ld / objcopy).
#   make        -> build/app.elf, build/APP_2C53T.bin (copy the .bin to the meter's update drive)
#   make clean
CROSS   ?= arm-none-eabi-
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
ASFLAGS := -I .
SRC     := $(wildcard src/*.s)
OBJ     := $(patsubst src/%.s,build/%.o,$(SRC))
INC     := $(wildcard src/parts/*.inc)

all: build/APP_2C53T.bin

build/%.o: src/%.s $(INC) | build
	$(AS) $(ASFLAGS) -o $@ $<

build/app.elf: $(OBJ) link.ld
	$(LD) --no-warn-rwx-segments -T link.ld -Map build/app.map -o $@ $(OBJ)

build/APP_2C53T.bin: build/app.elf
	$(OBJCOPY) -O binary $< $@

build:
	mkdir -p build

# SHA-256 of the vendor application image V1.2.0 (APP_2C53T_V1.2.0_251015.bin)
VENDOR_SHA256 := a17c5c35c97bb898f15672a1747bc1041d8ed507c16999ddba0d1e4e2ec0c760
check: build/APP_2C53T.bin
	@echo "$(VENDOR_SHA256)  build/APP_2C53T.bin" | shasum -a 256 -c -

clean:
	rm -rf build

.PHONY: all clean check
