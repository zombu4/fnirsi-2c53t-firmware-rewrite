# FNIRSI 2C53T firmware rewrite

Hand-written Thumb-2 assembly source for the application firmware of the FNIRSI 2C53T
(oscilloscope / multimeter / signal generator). The source is a port of the vendor application
V1.2.0: every function was typed by hand from the disassembly, with symbolic addresses and comments,
and the build is checked against the original image.

## Status

- Base port: the assembled image is identical to the vendor V1.2.0 application image, byte for
  byte (`make check`). Functions are in sections of their own, except small groups of functions
  that branch into each other with short (16-bit) instructions, which share one section.
- Code addresses are symbols. Some pointers into the fixed data (texts, tables) and the pointers
  stored inside `assets/rodata.bin` are still plain numbers; this is correct while the data stays
  at its original address (0x08046254) and is the next thing to change before data is moved.
- Next steps: smaller and faster replacements for the compiler-generated code, debug output and
  device control over USB, self-update over USB, a bootloader dump menu entry, and later a
  new bootloader.

## Hardware facts used by the source

- Core: ARMv7E-M Thumb-2 with a single-precision FPU (`.arch armv7e-m`, `.fpu fpv4-sp-d16`).
- The USB descriptors in the firmware name "Artery" / "AT32 Mass Storage"; the exact
  microcontroller part is not proven by the firmware itself.
- Flash layout:
  - below `0x08007000`: the meter's bootloader and its settings / calibration data. This project
    does not contain or write that area; the image starts at 0x08007000.
  - the application's settings code (`src/settings_53.s`) reads and programs the flash page at
    `0x08006000` (it copies 0x800 bytes from there) exactly as V1.2.0 does. Where the bootloader
    ends is not known from the application.
  - `0x08007000..` this application (vector table at 0x08007000; the start-up code sets VTOR to
    0x08000000 first and to 0x08007000 later, as V1.2.0 does)
- RAM `0x20000000..0x20036F8F`, stack top `0x20036F90`.

## Layout

| Path | Contents |
|---|---|
| `src/vectors.s` | exception vector table |
| `src/<module>_NN.s` | functions, grouped by subsystem (file system, graphics, USB, measurement, ...) |
| `src/parts/*.inc` | continuation parts of very large functions, included by their first part |
| `src/rodata.s` | fixed data: tables, text in every language, fonts, pictures, initial RAM image |
| `assets/` | binary data included by the sources (`.incbin`) |
| `link.ld` | memory layout |
| `Makefile` | build |

## Build

Requires the GNU Arm Embedded toolchain (`arm-none-eabi-as`, `arm-none-eabi-ld`,
`arm-none-eabi-objcopy`), binutils 2.39 or newer (for `--no-warn-rwx-segments`).

    make          # build/APP_2C53T.bin
    make check    # compares the SHA-256 of the image with the vendor V1.2.0 image

## Flashing

The meter's own bootloader installs application images. This is the procedure from the FNIRSI
manual and what was observed on a meter; the bootloader itself is not part of this project, so
its checks (file name, size) are not known from here:

1. Switch the meter off and connect it to a computer by USB.
2. Hold MENU and press Power: the bootloader starts its update mode and a USB drive appears.
3. Copy the `.bin` file onto that drive. The meter installs it and restarts.

Restoring the original FNIRSI V1.2.0 file this way has been done on a meter. The image built
here starts at 0x08007000 and contains nothing for the area below it.

## Legal

This is an independent project, not affiliated with or endorsed by FNIRSI. FNIRSI and the product
names are trademarks of their owners. Both the assembly source (written from the disassembly of
the vendor application) and the binary data in `assets/` (fonts, pictures, text) are derived from
the vendor's firmware; no licence for that vendor-derived content is granted here.
