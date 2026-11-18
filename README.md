# FNIRSI 2C53T firmware rewrite

Hand-written Thumb-2 assembly source for the FNIRSI 2C53T (oscilloscope / multimeter / signal
generator): the application firmware, the meter's stock bootloader, and a new two-part bootloader
that makes the meter recoverable whatever happens to its flash.

## Status

| Part | State |
|---|---|
| Application (`make`) | Complete hand-written port of the vendor application V1.2.0, with symbolic addresses and comments. `make check` builds the same source with the vendor version text and verifies it is byte-identical to the vendor V1.2.0 image. This build (About shows "V1.2.4") adds only a start-up hook for the bootloader installer and the flash dump (`src/boot_install.s`, `src/boot_dump.s`). It behaves like V1.2.0: a faithful rewrite, not yet a redesign. Installed and running on a meter. |
| Stock bootloader (`bootloader/`, `make -C bootloader check`) | Hand-written port of the meter's bootloader, byte-identical to a dump of it. |
| Two-part bootloader (`starter/`, `make -C bootloader slot`, `common/`) | Starter in flash page 0 plus the bootloader in slot F, with safety changes (below). Installed and running on a meter, written through the SWD header: **[FLASHING_BOOTLOADER.md](FLASHING_BOOTLOADER.md)**. |
| CI (`.github/workflows/build.yml`) | Builds everything and runs both byte proofs on every push; a version tag makes a release. |

Code addresses are symbols. Some pointers into the fixed data (texts, tables) and the pointers inside
`assets/rodata.bin` are still plain numbers; this is correct while the data stays at its original
address (0x08046254) and is the next thing to change before data is moved.

Next steps: smaller and faster replacements for the compiler-generated code, debug output and
device control over USB, and self-update over USB.

## Hardware

- MCU: Artery AT32F403A, Cortex-M4F. Chip ID 0x70050344 (debug register 0xE0042000; "AT32F403AVGT7"
  in Artery's ID tables), 1024 KB flash in 2 KB pages, two banks (0x08000000, 0x08080000), 224 KB
  RAM selected by the option byte at 0x1FFFF810 (value FE). The vendor firmware leaves the flash
  access protection on; the two-part bootloader install turns it off.
- Board marking "2C53T-V1.4_20250507". SWD header, from the square pad: 3V3, SWDIO, GND, SWCLK.
- The meter stays on only while its firmware drives the power-hold line (port C pin 9); without
  firmware it is on only while the power button is held.

Flash layout with the two-part bootloader (`common/layout.inc`):

| Address | Contents |
|---|---|
| 0x08000000..0x080007FF | page 0: the starter |
| 0x08006000..0x080067FF | the meter's settings / calibration page (individual to each meter) |
| 0x08006800 | "8KTA" mark: written by the bootloader when an application update is complete |
| 0x08007000..0x080E6FFF | application area (vector table at 0x08007000) |
| 0x080E7000, 0x080E7800 | record pages: append-only records INSTALL / TRIAL / OK with CRC-32 |
| 0x080E8000, 0x080F0000, 0x080F8000 | slots F (factory, written once), A, B: 32 KB each, header + image |

RAM `0x20000000..0x20036F8F`, application stack top `0x20036F90`.

## Two-part bootloader

- **Starter** (page 0, about 1.4 KB, written once): at every reset it starts slot F when the update
  key (MENU, PE2 / PE3) is held or a fault flag is set; otherwise it reads the records: none -> slot
  A, OK -> that slot, INSTALL -> start that slot once and record TRIAL, TRIAL (started once, never
  confirmed) -> record OK for the newest previously confirmed slot and start it. A slot is started
  only when its header (magic, link address, length, CRC-32, stack pointer, reset vector) checks out,
  else slot F.
- **Slot bootloader**: the stock bootloader's code, linked for slot + 0x200, with these changes:
  relocatable vector table and RAM image; no option-byte code; the application is started only when
  "8KTA", its stack pointer and its reset vector check out, with every interrupt off; it records OK
  for its slot when it starts the application or has started USB; flash writes only inside
  0x08006800..0x080E6FFF; the file size is checked against the target before anything is erased;
  the update file is the largest regular file on the drive (not a macOS "._" file) and must start
  with an application vector table.
- **Installer** (in the application), driven by files on the application's USB drive, report in
  `BOOTINST.LOG`:
  - `BOOTINST.TXT`: with the starter in page 0, writes the bootloader of this application build into
    the free slot A / B and records INSTALL (slot F and page 0 are never written). With the stock
    bootloader in page 0 it would install the whole chain, but only on a meter whose access
    protection is off: the chip refuses to erase page 0 under protection (then nothing is changed).
    The first install therefore goes through the SWD header (FLASHING_BOOTLOADER.md).
  - `BOOTTEST.TXT`: dry run of the same (all checks; page 0 never written); wins over BOOTINST.TXT.
  - `BOOTDUMP.TXT`: writes `BOOTDUMP.BIN` (flash 0x08000000..0x08006FFF: bootloader and calibration
    page), `SYSINFO.BIN` (option bytes) and `FLASHREG.BIN` (flash controller registers) to the drive.
  Running the installer again writes nothing once a step is done.

## Layout

| Path | Contents |
|---|---|
| `src/vectors.s` | exception vector table |
| `src/<module>_NN.s` | functions, grouped by subsystem (file system, graphics, USB, measurement, ...) |
| `src/parts/*.inc` | continuation parts of very large functions, included by their first part |
| `src/rodata.s` | fixed data: tables, text in every language, fonts, pictures, initial RAM image |
| `src/boot_install.s`, `src/boot_dump.s` | start-up hook, bootloader installer, flash dump |
| `assets/` | binary data included by the sources (`.incbin`) |
| `bootloader/` | stock bootloader port (`make check`) and its slot build (`make slot`) |
| `starter/` | the starter (page 0) |
| `common/` | flash layout and record code shared by starter, slot bootloader and installer |
| `swd/` | SWD loader and OpenOCD scripts for the first install through a debug probe |
| `FLASHING_BOOTLOADER.md` | step-by-step guide for flashing the new bootloader |
| `link.ld`, `Makefile` | memory layout, build |

## Build

Requires the GNU Arm Embedded toolchain (`arm-none-eabi-as`, `arm-none-eabi-ld`,
`arm-none-eabi-objcopy`), binutils 2.39 or newer (for `--no-warn-rwx-segments`).

    make                       # build/APP_2C53T.bin; builds starter/ and bootloader/ first
    make check                 # vendor-text build in build/vendor/, SHA-256 compared with vendor V1.2.0
    make -C bootloader check   # stock bootloader port compared with the dump (SHA-256)
    make -C swd                # SWD loader for the first bootloader install

## Installing the application

1. Switch the meter off and connect it to a computer by USB.
2. Hold MENU and press Power: "Firmware upgrade" appears and a USB drive "IAP".
3. Copy the application `.bin` onto that drive. The meter installs it and starts it. Files named in
   the vendor pattern (`APP_2C53T_V1.2.4_261117.bin`) were accepted by both bootloaders.

With the stock bootloader on macOS, copying with Finder or `cp` did not work: the stock bootloader
takes the first file entry followed by an unused entry, which fits the macOS "._" file being taken
instead of the firmware file (the order macOS writes the entries in is not proven). What worked: unmount the drive, read the
volume with `dd` from the raw device, add the file with `mcopy` (mtools, `MTOOLS_SKIP_CHECK=1`),
remove the macOS entries, and write back only the changed 2048-byte sectors with `dd`. The new
bootloader chooses the largest regular file and refuses a "._" file by its content; it was used
with the `mcopy` method so far.

## Continuous build and releases

Every push to `main` builds the application, the bootloader images and the SWD loader on GitHub
Actions and runs both byte proofs; the files are attached to the run. A tag `v<version>` matching the
About text in the source (for example `v1.2.4`) also creates a release with
`APP_2C53T_V<version>_<yymmdd>.bin`, `STARTER.bin`, `BOOT_F/A/B.bin`, `swd_loader.bin` and
`SHA256SUMS`.

## Legal

This is an independent project, not affiliated with or endorsed by FNIRSI. FNIRSI and the product
names are trademarks of their owners. Both the assembly source (written from the disassembly of
the vendor application) and the binary data in `assets/` (fonts, pictures, text) are derived from
the vendor's firmware; no licence for that vendor-derived content is granted here.
