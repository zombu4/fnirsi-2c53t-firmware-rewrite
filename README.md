# FNIRSI 2C53T firmware rewrite

Hand-written Thumb-2 assembly source for the application firmware of the FNIRSI 2C53T
(oscilloscope / multimeter / signal generator). The source is a port of the vendor application
V1.2.0: every function was typed by hand from the disassembly, with symbolic addresses and comments,
and the build is checked against the original image.

## Status

- Application (`make`): the port with these changes: the version text in About ("V1.2.4") and a
  start-up hook (`src/boot_install.s`) that runs the bootloader installer or the flash dump when
  their trigger files exist on the meter's USB drive. V1.2.1 to V1.2.3 were installed and run on
  a meter; V1.2.4 (with the installer) is tested in an emulator only so far.
- Proof of the port: `make check` builds the same source with the vendor version text and
  verifies it is identical to the vendor V1.2.0 application image, byte for byte. Functions are in
  sections of their own, except small groups of functions that branch into each other with short
  (16-bit) instructions, which share one section.
- Stock bootloader (`bootloader/`, `make -C bootloader check`): hand-written port of the meter's
  bootloader, byte-identical to a dump of it.
- Two-part bootloader (tested in an emulator, not yet installed on a meter): a starter in flash
  page 0 (`starter/`) that is written once and chooses one of three bootloader slots, and the
  bootloader port relinked for those slots (`make -C bootloader slot`) with safety changes (see
  below). The application installs it.
- Code addresses are symbols. Some pointers into the fixed data (texts, tables) and the pointers
  stored inside `assets/rodata.bin` are still plain numbers; this is correct while the data stays
  at its original address (0x08046254) and is the next thing to change before data is moved.

## Hardware facts used by the source

- Core: ARMv7E-M Thumb-2 with a single-precision FPU (`.arch armv7e-m`, `.fpu fpv4-sp-d16`).
- The USB descriptors in the firmware name "Artery" / "AT32 Mass Storage"; the exact
  microcontroller part is not proven by the firmware itself. Flash: 1024 KB (word 0x0400 at
  0x1FFFF7E0), 2 KB pages, two banks (0x08000000.., 0x08080000..).
- Flash layout with the two-part bootloader (`common/layout.inc`):

  | Address | Contents |
  |---|---|
  | 0x08000000..0x080007FF | page 0: stock bootloader start, replaced by the starter on install |
  | 0x08000800..0x08005873 | rest of the stock bootloader (kept, not used by the new chain) |
  | 0x08006000..0x080067FF | the meter's settings / calibration page: never written by any bootloader code here |
  | 0x08006800 | "8KTA" mark: written by the bootloader when an application update is complete |
  | 0x08007000..0x080E6FFF | application area (vector table at 0x08007000) |
  | 0x080E7000, 0x080E7800 | record pages: append-only records INSTALL / TRIAL / OK with CRC-32 |
  | 0x080E8000, 0x080F0000, 0x080F8000 | slots F (factory, written once), A, B: 32 KB each, header + image |

- RAM `0x20000000..0x20036F8F`, stack top `0x20036F90`.

## Two-part bootloader

- Starter (page 0, about 1.4 KB): at every reset it starts slot F when a fault flag is set or the
  update key (MENU, PE2 / PE3) is held; otherwise it reads the records: none -> slot A, OK -> that
  slot, INSTALL -> start that slot once and record TRIAL, TRIAL (started once, never confirmed) ->
  record OK for the newest previously confirmed slot and start it. A slot is started only when
  its header (magic, link address, length, CRC-32 of the header, stack pointer, reset vector)
  checks out, else slot F.
- Slot bootloader: the stock bootloader's code, linked for slot + 0x200, with these changes:
  vector table and RAM image relocatable; no option-byte code; the application is started only
  when "8KTA", its stack pointer and its reset vector check out, with every interrupt off; it
  records OK for its slot when it starts the application or has started USB; flash writes only
  inside 0x08006800..0x080E6FFF; file size checked against the target before anything is erased;
  the update file is the largest regular file on the drive (not the macOS "._" file) and must
  start with an application vector table.
- Installer (in the application): create the file `BOOTINST.TXT` on the meter's drive (the
  storage the application shares over USB) and restart the meter. The report is written to
  `BOOTINST.LOG`. With the stock bootloader in page 0 it checks it (CRC-32), checks the battery
  reading, writes slots F and A and the records, and then replaces page 0 from a routine in RAM
  (erase first; a refused erase leaves the stock bootloader as it was; any later failure writes
  the stock page 0 back). With the starter in page 0 it writes a newer bootloader into the free
  slot A / B and records INSTALL. Running it again writes nothing once done. `BOOTTEST.TXT` runs
  it as a dry run: all checks, slots and records written in a first install, page 0 never (it
  wins when both files exist). `BOOTDUMP.TXT`
  instead writes copies of the flash below 0x08007000 and of system words to the drive.

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
| `link.ld` | memory layout |
| `Makefile` | build |

## Build

Requires the GNU Arm Embedded toolchain (`arm-none-eabi-as`, `arm-none-eabi-ld`,
`arm-none-eabi-objcopy`), binutils 2.39 or newer (for `--no-warn-rwx-segments`).

    make          # build/APP_2C53T.bin (V1.2.4); builds starter/ and bootloader/ first
    make check    # vendor-text build in build/vendor/, SHA-256 compared with vendor V1.2.0
    make -C bootloader check   # stock bootloader port compared with the dump (SHA-256)

## Flashing

The meter's bootloader installs application images:

1. Switch the meter off and connect it to a computer by USB.
2. Hold MENU and press Power: the bootloader starts its update mode and a USB drive appears.
3. Copy the `.bin` file onto that drive. The meter installs it and restarts. A file named in the
   vendor pattern (`APP_2C53T_V1.2.1_261117.bin`) was accepted.

On macOS, copying with Finder or `cp` did not work here: the file disappeared without being
installed. macOS also adds `._` and `.fseventsd` entries to the drive. What worked: unmount the
drive, read the volume with `dd` from the raw device, add the file to that volume image with
`mcopy` (mtools, `MTOOLS_SKIP_CHECK=1`), remove the macOS entries, and write back only the
changed 2048-byte sectors with `dd`.

Restoring the original FNIRSI V1.2.0 file this way has been done on a meter.

## Legal

This is an independent project, not affiliated with or endorsed by FNIRSI. FNIRSI and the product
names are trademarks of their owners. Both the assembly source (written from the disassembly of
the vendor application) and the binary data in `assets/` (fonts, pictures, text) are derived from
the vendor's firmware; no licence for that vendor-derived content is granted here.
