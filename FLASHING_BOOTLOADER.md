# Flashing the new bootloader (two-part bootloader) onto a FNIRSI 2C53T

This replaces the meter's stock bootloader by the two-part bootloader of this project: a small
**starter** in flash page 0 that is written once, and the bootloader proper in **slot F** (factory)
at 0x080E8000, with room for two update slots (A, B). Afterwards:

- MENU + Power still starts the update mode ("Firmware upgrade", USB drive "IAP"), now through
  slot F, which is never overwritten by any update;
- the bootloader checks an application before it starts it (completion mark "8KTA", stack pointer,
  reset vector) and stays in update mode otherwise;
- the meter's flash access protection is off, so the SWD header can always reach the chip: whatever
  happens to the flash later, the meter can be rewritten through the header.

It was done this way on one meter (board "2C53T-V1.4_20250507", MCU chip ID 0x70050344) on
2026-11-17. Read the whole page first.

## Why a debug probe is needed

The stock firmware leaves the chip's flash **access protection** on. With it on, the chip itself
refuses to erase or program flash sectors 0 and 1 (0x08000000..0x08000FFF, Artery reference manual
RM_AT32F403A_407 section 5.5.2), and page 0 is where the starter has to go. The installer in the
application (`BOOTINST.TXT`, see below) therefore stops on a protected meter with "erase refused by the
flash controller: stock bootloader unchanged" and changes nothing.

Removing the protection is only possible by rewriting the option bytes, and the chip then **erases
its whole main flash** (RM section 5.5.1): the stock bootloader, the application **and the meter's
individual calibration page at 0x08006000**. After that the chip is blank and only a debug probe on
the SWD header can write it again. So: probe first, calibration backup first.

## What you need

- A debug probe that speaks CMSIS-DAP over SWD at 3.3 V: a USB CMSIS-DAP / DAPLink adapter, or a
  CMSIS-DAP over TCP probe (the meter here was flashed with an ESP32 running a CMSIS-DAP TCP firmware:
  SWCLK on GPIO22, SWDIO on GPIO23).
- Three jumper wires.
- OpenOCD built from current git (the release 0.12.0 is too old for the CMSIS-DAP TCP backend):
  e.g. `brew install --HEAD open-ocd` on macOS. Tested with 0.12.0+dev-02815-g83e3febc6.
- The GNU Arm Embedded toolchain and Python 3, to build this repository.
- A charged meter. The power button must be **held down for the whole probe procedure** (about two
  minutes): the meter only stays on by itself when its firmware sets the power-hold line, and during
  the procedure there is no firmware.

## Step 1 - build

    make                 # application with the installer; also builds starter/ and bootloader/
    make -C swd          # swd/build/swd_loader.bin

## Step 2 - put application V1.2.4 (or later) on the meter

With the stock bootloader: meter off, USB connected, hold MENU and press Power, copy
`build/APP_2C53T.bin` onto the drive "IAP" (see README "Flashing", including the macOS notes).
Check About: "V1.2.4".

## Step 3 - back up this meter's calibration

1. Switch on the meter normally and turn on USB sharing; its drive appears.
2. Create an empty file `BOOTDUMP.TXT` on that drive, eject the drive, restart the meter.
3. Turn on USB sharing again: the drive now holds `BOOTDUMP.BIN` (0x7000 bytes: stock bootloader and
   the calibration page at offset 0x6000), `SYSINFO.BIN` (option bytes) and `FLASHREG.BIN`.
4. Copy the three files to your computer and keep several copies. **Without `BOOTDUMP.BIN` of this
   meter, do not continue**: the calibration of another meter is not yours.
5. Delete `BOOTDUMP.TXT` from the drive.

Then build the images for the probe from your dump:

    python3 swd/make_images.py /path/to/BOOTDUMP.BIN

It checks the dump (size 0x7000, stock bootloader at the start, a non-erased page at 0x6000) and writes
`swd/build/` with `plan.txt` listing the four blocks: calibration page 0x08006000, slot F image
0x080E8200, slot F header 0x080E8000, starter 0x08000000.

## Step 4 - wiring

Open the meter. The SWD header is a row of four holes labelled, from the square pad: **3V3, SWDIO,
GND, SWCLK**. Connect:

| Probe | Meter header |
|---|---|
| GND | GND |
| SWDIO | SWDIO |
| SWCLK | SWCLK |

Leave 3V3 unconnected (do not power the meter from the probe) and leave the probe's reset line
unconnected (the header has none).

## Step 5 - check the connection

All commands run in `swd/`. For a TCP probe set its address first (`export DAP_HOST=<probe ip>`); the
commands below use `-f probe-cmsis-dap-tcp.cfg`. For a USB probe replace that part with
`-f interface/cmsis-dap.cfg -c "transport select swd" -c "adapter speed 200"`.

Switch the meter on normally, then:

    openocd -f probe-cmsis-dap-tcp.cfg -f at32-noHalt.cfg -f swd_install.tcl -c init -c p1_check -c shutdown

Expected:

    Info : SWD DPIDR 0x2ba01477 DPv1
    chip ID 0xE0042000 = 0x70050344
    0x4002201C = 0x03fffffe (bit 1 protection = 1)

**The meter switches off or freezes at its logo after this.** That is expected: with the protection
on, a debug connection stops the firmware from reading its own flash. Nothing is written. Switch it
off and on again and it starts normally. If the chip ID differs from 0x70050344, stop: this guide and
`swd_loader.s` were made for that chip (AT32F403A, 1024 KB, 2 KB pages, flash banks at 0x08000000 and
0x08080000).

## Step 6 - remove the protection and write the bootloader

From here on, **press and hold the power button until step 6.5**.

1. Remove the protection:

        openocd -f probe-cmsis-dap-tcp.cfg -f at32-noHalt.cfg -f swd_install.tcl -c init -c p1_fap_disable -c shutdown

   Expected: `control after keys = 0x00000200`, `status after option erase = 0x00000020`,
   `writing FAP 0xA5 ...`, then `SWD WAIT` / `DAPABORT` warnings and an error at 0x1ffff802: the chip
   resets in the middle of that write.

   If power is lost after the option-area erase but before the FAP write, the protection stays on and
   the stock bootloader restores the RAM option byte at the next start (its own check of 0x1FFFF810):
   start again at step 5.

2. Reset and check that the chip is blank and unprotected:

        openocd -f probe-cmsis-dap-tcp.cfg -f at32-core.cfg -f swd_install.tcl -c init -c "reset halt" -c p2_check -c shutdown

   Expected: `0x4002201C = 0x03fffffc (bit 1 protection = 0)`, `pc: 0xfffffffe` and 0xffffffff at
   0x08000000, 0x08006000, 0x08007000, 0x080e8000. If bit 1 is still 1, run this command again (the new
   option value is loaded by a reset).

3. Write the starter, slot F and your calibration page:

        openocd -f probe-cmsis-dap-tcp.cfg -f at32-core.cfg -f swd_install.tcl -c init -c p2_program -c shutdown

   Expected: `loader result 0, address 0x00000000, blocks done 4` and `0x1FFFF810 = 0xffff01fe`
   (the RAM option byte back at 224 KB; the application needs it). The loader erases the pages it
   writes first, so this command can simply be repeated if it fails.

4. Read everything back:

        openocd -f probe-cmsis-dap-tcp.cfg -f at32-core.cfg -f swd_install.tcl -c init -c p2_verify -c shutdown

   Expected: `verified 2048 bytes`, `verified 23480 bytes`, `verified 28 bytes`,
   `verified 1436 bytes` (the slot F size may differ for a different build).

5. Start it:

        openocd -f probe-cmsis-dap-tcp.cfg -f at32-core.cfg -f swd_install.tcl -c init -c p2_start -c shutdown

   The meter shows **"Firmware upgrade"**: the starter found no records and no slot A and started
   slot F, which now holds the power itself. **Release the power button.**

## Step 7 - install the application

Connect USB: the drive "IAP" appears ("AT32 Mass Storage"). Copy `build/APP_2C53T.bin` onto it as in
step 2. Slot F programs it, writes the "8KTA" mark and starts it. Check MENU + Power once more: it must
show "Firmware upgrade" again.

The probe can stay connected or be removed. With the protection off it no longer disturbs the
firmware, so it can read the flash at any time (e.g. `-f at32-noHalt.cfg -c init -c "at32.ap mdw
0x08006800"` shows 0x41544b38, "8KTA").

## Afterwards

- **Application updates:** as before, MENU + Power and copy the file. The bootloader now picks the
  largest regular file on the drive (not the macOS "._" copy), refuses files that do not start with
  an application vector table or that would not fit below 0x080E7000, and checks the size before it
  erases anything.
- **Bootloader updates:** create `BOOTINST.TXT` on the application's drive and restart. The installer
  writes the bootloader of that application build into the free slot A or B and records INSTALL; the
  starter tries it at the next start and falls back when it does not confirm. Slot F and page 0 are
  never written again by it. The report is in `BOOTINST.LOG`; `BOOTTEST.TXT` does a dry run.
- **If anything goes wrong later**, hold the power button and use step 6.3 to 6.5 again: the chip is
  unprotected, the probe reaches it whatever is in the flash.
- Erasing the option area turns the protection on again (RM Table 5-5: FAP 0xFF = enabled), which
  closes the probe path; this project leaves it off.

## Files

| Path | What it is |
|---|---|
| `starter/` | the starter (page 0) |
| `bootloader/` | stock bootloader port (`make check`) and its slot build (`make slot`) |
| `common/` | flash layout and record code shared by starter, slot bootloader and installer |
| `src/boot_install.s` | installer in the application (BOOTINST.TXT / BOOTTEST.TXT / BOOTDUMP.TXT) |
| `swd/swd_loader.s` | RAM program run through the probe: erases and programs the blocks, sets the RAM option byte, compares, reports |
| `swd/swd_install.tcl` | OpenOCD procedures p1_check, p1_fap_disable, p2_check, p2_program, p2_verify, p2_start |
| `swd/at32-noHalt.cfg`, `swd/at32-core.cfg` | OpenOCD targets: without and with the Cortex-M core |
| `swd/probe-cmsis-dap-tcp.cfg` | OpenOCD interface for a CMSIS-DAP TCP probe (address from DAP_HOST) |
| `swd/make_images.py` | builds `swd/build/` from your BOOTDUMP.BIN |

OpenOCD's own `artery` flash driver is not used: it does not list chip ID 0x70050344 and programs
only through the first bank's flash controller, while slot F is in the second bank (controller
registers at 0x40022040..).
