# FNIRSI 2C53T firmware rewrite

Firmware for the **FNIRSI 2C53T** (oscilloscope / multimeter / signal generator), written in native
**Thumb-2 assembly** for its ARM Cortex-M4F microcontroller.

The project contains:

- the **application firmware**,
- a port of the meter's **stock bootloader**,
- a new **two-part bootloader** that keeps the meter recoverable whatever happens to its flash.

[![build](https://github.com/zombu4/fnirsi-2c53t-firmware-rewrite/actions/workflows/build.yml/badge.svg)](https://github.com/zombu4/fnirsi-2c53t-firmware-rewrite/actions/workflows/build.yml)

---

## Screenshots

<p align="center"><img src="docs/screenshots/boot_animation.gif" alt="Boot animation"></p>

The boot animation, rendered by running the firmware's own start-up code in an emulator and
recording what it writes to the display (timing from its delay calls; drawing time not included).

Taken from the meter over USB (SCREENSHOT command), application V1.4.12 with our own pictures,
fonts and texts; shown at twice the size.

| | |
|---|---|
| ![Main menu](docs/screenshots/1_menu.png) | ![Multimeter](docs/screenshots/2_meter.png) |
| ![Oscilloscope](docs/screenshots/3_scope.png) | ![Oscilloscope settings](docs/screenshots/4_scope_settings.png) |
| ![Signal generator](docs/screenshots/5_generator.png) | ![System settings](docs/screenshots/6_settings.png) |

All 151 user-interface pictures: [docs/screenshots/ui_pictures.png](docs/screenshots/ui_pictures.png).

---

## Status

### Application

- Runs on the meter as assembly firmware (About shows **V1.4.15**). It started as a byte-identical
  port of the vendor application V1.2.0 and is now developed on its own.
- **USB control channel** (`src/usb_ctl.s`, `src/usb_remote.s`): a serial port next to the drive,
  no menu setting needed: every function of the meter (multimeter, oscilloscope, generator,
  settings), screenshots, files, events and firmware updates without touching the meter.
  Protocol: **[PROTOCOL.md](PROTOCOL.md)**.
- **Storage fix** (`src/storage.s`): one lock for the external flash and the file system, the USB
  drive handled outside the interrupt, the drive flushed before it is shared and re-read after, and
  the flash idle before every power-off and reset (the vendor firmware could corrupt the drive when
  the host wrote to it, e.g. a Mac, or when the meter was switched off or restarted on USB).
- No charging screen after a software restart; the power hold stays on until the meter is switched
  off.
- **Own data**: English-only texts typed in `src/text.s`, own fonts (DejaVu Sans Condensed, the 20 px one Bold, rendered
  at 4 bits per pixel; own 7-segment digits; white text drawn in a warm white that reads better on
  the meter's LCD), own boot logo "FU**NIRSi" with the falling-dot animation,
  own pictures and computed tables; the language page and the language menu item are gone. Every
  address between code and data is a symbol, so both can move freely. Only the FPGA configuration and
  the filter coefficients are still the vendor's (`assets/vendor_kept/`).
- Start-up hooks for the bootloader installer and the flash dump (`src/boot_install.s`,
  `src/boot_dump.s`).

### Bootloaders

| Part | Build | State |
|---|---|---|
| Stock bootloader port | `make -C bootloader vendor-data DUMP=…` then `make -C bootloader check` | byte-identical to a dump of the meter's bootloader (needs that meter's dump) |
| Two-part bootloader | `make -C bootloader slot`, `starter/` | installed and running on a meter |

How to install the two-part bootloader: **[FLASHING_BOOTLOADER.md](FLASHING_BOOTLOADER.md)**.

### Next steps

- Smaller and faster code
- Own FPGA configuration and filter coefficients

---

## Hardware

| Item | Value |
|---|---|
| MCU | Artery AT32F403A, Cortex-M4F, chip ID 0x70050344 ("AT32F403AVGT7" in Artery's ID tables) |
| Flash | 1024 KB, 2 KB pages, two banks (0x08000000, 0x08080000) |
| RAM | 224 KB (option byte 0x1FFFF810 = FE), application stack top 0x20036F90 |
| Board | marking "2C53T-V1.4_20250507" |
| SWD header | from the square pad: 3V3, SWDIO, GND, SWCLK |
| Power | the meter stays on only while the firmware drives the power-hold line (port C pin 9); without firmware only while the power button is held |

The vendor firmware leaves the flash access protection on; installing the two-part bootloader turns
it off.

### Flash layout (two-part bootloader, `common/layout.inc`)

| Address | Contents |
|---|---|
| `0x08000000` – `0x080007FF` | starter (page 0) |
| `0x08006000` – `0x080067FF` | settings / calibration page (individual to each meter) |
| `0x08006800` | "8KTA" mark: application update complete |
| `0x08007000` – `0x080E6FFF` | application |
| `0x080E7000`, `0x080E7800` | record pages (INSTALL / TRIAL / OK, CRC-32) |
| `0x080E8000` | slot F: factory bootloader, written once |
| `0x080F0000`, `0x080F8000` | slots A, B: bootloader updates |

---

## Two-part bootloader

### Starter

Page 0, about 1.4 KB, written once. At every reset:

1. Update key (MENU) held, or a fault flag set → **slot F**.
2. Otherwise the newest record decides:
   - none → slot A
   - OK → that slot
   - INSTALL → that slot, once, recorded as TRIAL
   - TRIAL (started once, never confirmed) → back to the last confirmed slot
3. A slot starts only when its header checks out (magic, link address, length, CRC-32, stack
   pointer, reset vector); otherwise slot F.

### Slot bootloader

The stock bootloader's code, relinked for the slots, with these changes:

- starts the application only when the "8KTA" mark, its stack pointer and its reset vector check
  out, with every interrupt off
- confirms its slot (OK record) when it starts the application or has started USB
- writes flash only inside `0x08006800` – `0x080E6FFF`; never touches the option bytes
- checks the file size against the target before it erases anything
- takes the largest regular file on the drive (not a macOS "._" file) and only accepts content that
  starts with an application vector table

### Installer (in the application)

Controlled by files on the application's USB drive; the report goes to `BOOTINST.LOG`.

| File | Action |
|---|---|
| `BOOTINST.TXT` | Starter in page 0: writes this build's bootloader into the free slot A / B and records INSTALL. Slot F and page 0 are never written. |
| `BOOTTEST.TXT` | Dry run: all checks, page 0 never written (wins over BOOTINST.TXT). |
| `BOOTDUMP.TXT` | Writes `BOOTDUMP.BIN` (flash 0x08000000 – 0x08006FFF, incl. the calibration page), `SYSINFO.BIN` (option bytes), `FLASHREG.BIN`. |

The first install needs the SWD header: with the vendor's access protection on, the chip refuses to
erase page 0 (the installer then changes nothing).

---

## Building

Requires the GNU Arm Embedded toolchain (`arm-none-eabi-as`, `-ld`, `-objcopy`), binutils 2.39 or
newer.

```sh
make                       # build/APP_2C53T.bin (also builds starter/ and bootloader/)
make -C bootloader vendor-data DUMP=BOOTDUMP.BIN && make -C bootloader check
                           # byte proof of the stock bootloader port (data from your own dump)
make -C swd                # SWD loader for the first bootloader install
```

## Installing the application

1. Switch the meter off and connect it by USB.
2. Hold **MENU** and press **Power**: "Firmware upgrade" appears, and a USB drive named `IAP`.
3. Copy the application `.bin` onto the drive. The meter installs it and starts it.

File names in the vendor pattern (`APP_2C53T_V1.2.5_261117.bin`) are accepted by both bootloaders.

**macOS:** with the stock bootloader, copying with Finder or `cp` did not work. The stock bootloader
takes the first file entry followed by an unused one, which fits the macOS "._" file being taken
instead of the firmware (the order macOS writes them in is not proven). What worked: unmount the
drive, read the volume with `dd`, add the file with `mcopy` (mtools, `MTOOLS_SKIP_CHECK=1`), remove
the macOS entries, and write back only the changed 2048-byte sectors with `dd`. The new bootloader
ignores "._" files by their content.

### User-interface pictures

The menus, buttons and dialogs are JPEG pictures that the firmware loads from the meter's own drive
`3:/System file/NNN.jpg`; the meter keeps them there, they are not part of the application image.
`assets/ui/` holds our own set (151 pictures: the numbers and sizes the firmware draws; the vendor's 1, 81,
83, 85, 121, 141, 144, 151 and 152 are never drawn and are not kept). With
application 1.4.0 or later each one can be written over USB with FILE_WRITE to
`3:/System file/NNN.jpg` and read back with FILE_READ to check it (`PROTOCOL.md` 4.10).

---

## Repository layout

| Path | Contents |
|---|---|
| `src/` | application: vector table, functions by subsystem, fixed data, installer, flash dump |
| `src/parts/` | continuation parts of very large functions |
| `assets/` | binary data included by the sources |
| `assets/fonts/` | application fonts: DejaVu Sans Condensed 2.37 rendered at 4 bpp (`LICENSE-DejaVu.txt`), own 7-segment font |
| `assets/pictures/` | own boot logo, boot animation sprites, trigger icons, value panel and message box frames |
| `assets/tables/` | computed tables (sine, FFT twiddles and swap order, JPEG IDCT scale and clamp, signal generator waveforms) and the FatFs code page / case tables (`LICENSE-FatFs.txt`) |
| `assets/ui/` | own user-interface pictures for the meter's drive 3: (`3:/System file/NNN.jpg`) |
| `assets/vendor_kept/` | `fpga.bin` (FPGA configuration stream) and `filter_bank.bin` (filter coefficients): the vendor's data, kept for now |
| `bootloader/` | stock bootloader port (`make check`) and its slot build (`make slot`) |
| `starter/` | the starter (page 0) |
| `common/` | flash layout and record code shared by starter, bootloader and installer |
| `bootloader/assets/` | bootloader font: Terminus Font 12x24 (OFL 1.1, `OFL.txt`), converted to the glyph layout |
| `docs/screenshots/` | screenshots of the meter's pages and a sheet of all user-interface pictures |
| `swd/` | SWD loader and OpenOCD scripts for the first bootloader install |
| `FLASHING_BOOTLOADER.md` | step-by-step bootloader flashing guide |
| `link.ld`, `Makefile` | memory layout, build |
| `.github/workflows/` | continuous build |

## License

Free for **personal, home, hobby and enthusiast** use that is not commercial: use, study, modify and
share free of charge, with the license kept. **Not permitted without written authorization** from the
author: use by companies or for commercial purposes, selling or reselling, bundling or pre-installing
with hardware or other products, and paid flashing services. Full terms: [LICENSE](LICENSE).

The bootloader font is Terminus Font 4.49.1, Copyright (C) 2020 Dimitar Toshkov Zhekov, under the
SIL Open Font License 1.1 (`bootloader/assets/OFL.txt`).

The application's text fonts (`assets/fonts/`) are rendered from DejaVu Sans Condensed 2.37: Bitstream
Vera Fonts Copyright (c) 2003 by Bitstream, Inc., Arev Fonts Copyright (c) 2006 by Tavmjong Bah,
DejaVu changes in the public domain; license text in `assets/fonts/LICENSE-DejaVu.txt`. The words drawn
into the user-interface pictures (`assets/ui/`) use the same fonts.

The file system code page and case conversion tables (`assets/tables/fat_*.bin`) are data of FatFs
R0.15, Copyright (C) ChaN, under the FatFs license (`assets/tables/LICENSE-FatFs.txt`).

This is an independent project, not affiliated with or endorsed by FNIRSI. FNIRSI and the product
names are trademarks of their owners. Content derived from the vendor's firmware (the application
port, the stock bootloader port, and `assets/vendor_kept/`) is not licensed by
this project.
