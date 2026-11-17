# FNIRSI 2C53T firmware rewrite

Hand-written Thumb-2 assembly source for the application firmware of the FNIRSI 2C53T
(oscilloscope / multimeter / signal generator). The source is a port of the vendor application
V1.2.0: every function was typed by hand from the disassembly, with symbolic addresses and comments,
and the build is checked against the original image.

## Status

- Base port: the assembled image is identical to the vendor V1.2.0 application image, byte for
  byte. Every function has its own section and every code and data address is a symbol, so code
  can be changed and moved from here on.
- Next steps: smaller and faster replacements for the compiler-generated code, debug output and
  device control over USB, self-update over USB, a bootloader dump menu entry, and later a
  new bootloader.

## Hardware facts used by the source

- Core: ARMv7E-M Thumb-2 with a single-precision FPU (`.arch armv7e-m`, `.fpu fpv4-sp-d16`).
- The USB descriptors in the firmware name "Artery" / "AT32 Mass Storage"; the exact
  microcontroller part is not proven by the firmware itself.
- Flash layout:
  - `0x08000000..0x08005FFF` bootloader (not part of this project, never written by it)
  - `0x08006000..0x08006FFF` the meter's own calibration and settings page (never written when
    flashing; the firmware's settings code reads and writes it exactly as V1.2.0 does)
  - `0x08007000..` this application (vector table at 0x08007000)
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
`arm-none-eabi-objcopy`).

    make

The result is `build/APP_2C53T.bin`.

## Flashing

The meter's own bootloader installs application images:

1. Switch the meter off and connect it to a computer by USB.
2. Hold MENU and press Power: the bootloader starts its update mode and a USB drive appears.
3. Copy the `.bin` file onto that drive. The meter installs it and restarts.

To go back to the vendor firmware, repeat the same steps with the original FNIRSI V1.2.0 file.

The bootloader and the calibration page are not touched by this procedure.

## Legal

This is an independent project, not affiliated with or endorsed by FNIRSI. FNIRSI and the product
names are trademarks of their owners. The source was produced by reverse engineering the vendor
application for interoperability; the binary data in `assets/` (fonts, pictures, text) comes from
the vendor image.
