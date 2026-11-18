# FNIRSI 2C53T USB control protocol (protocol version 1)

This document specifies the control channel of this firmware: a USB serial port (CDC ACM), with the
meter's USB drive next to it while the drive is shared. It covers reading and controlling every
function of the meter, file access and firmware updates, for test tools and for a companion
application. Implemented in `src/usb_ctl.s` (transport, device, state, generator, drive, firmware
update) and `src/usb_remote.s` (multimeter, oscilloscope, settings, screen, files, events) since
firmware 1.3.0. The host side is `tools/fnirsi_ctl.py` in the development tree.

## 1. Transport

- USB device: VID `0x2E3C`, PID `0x2C53`, manufacturer "F\*\*\*nirsi", product "2C53T". Two
  configurations: CDC ACM only (interfaces 0 + 1), or, while the drive is shared (UI page 7, menu
  "USB Sharing" or the DRIVE command), mass storage (interface 0) + CDC ACM (interfaces 1 + 2). A
  change between them re-enumerates (the port disappears for about a second).
- The control channel is available whenever the meter is on and USB is connected; no menu setting is
  needed. Line settings (baud rate etc.) are accepted and ignored.
- The host opens the port and sets DTR. While DTR is set the meter does not switch itself off (the
  auto-shutdown counter is held at 0) and sends event frames. Without DTR it only answers requests
  (and stream frames when STREAM was started).

## 2. Frames

All multi-byte numbers are little-endian.

| Field | Size | Content |
|---|---|---|
| sync | 1 | `0xA5` |
| length | 2 | number of bytes from `seq` to the end of `payload` (3..515) |
| seq | 1 | request: chosen by the host; answer: the same value; stream / event: running counter |
| type | 1 | `0x01` request, `0x02` answer, `0x03` stream, `0x04` event |
| cmd | 1 | command number (section 4) |
| payload | n | command data, at most 512 bytes |
| crc | 2 | CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF) over `length` .. `payload` |

- Every request gets exactly one answer with the same `seq` and `cmd`. The first payload byte of an
  answer is a status (section 3); data follows it.
- The host sends the next request only after the answer of the previous one. Most answers come
  within 500 ms; commands that press keys repeatedly (section 4.0) can take several seconds (each step
  waits for the meter's own handling and redraw), the screenshot about a second.
- Receivers resynchronise by searching for `0xA5` and checking the CRC; a frame with a bad CRC is
  dropped without an answer.

## 3. Status codes

| Code | Meaning |
|---|---|
| 0 | OK |
| 1 | unknown command |
| 2 | bad length or argument |
| 3 | not allowed in the current state (wrong page, drive shared, value the meter refuses) |
| 4 | busy (the meter is in a state in which it ignores keys, e.g. autoset running; try again) |
| 5 | file system error |
| 6 | refused for safety |
| 7 | CRC or length mismatch of transferred data |

## 4. Commands

### 4.0 How settings are changed

Commands that change a function of the meter are carried out by the meter's own key handlers, in the
meter's key task, exactly as the keys would do it (including the meter-chip and FPGA commands and
the redraws): the USB task posts a job to the key task, which runs it at its next key. While the
meter ignores keys (autoset or auto-correction running, a screenshot being saved to its drive) the
job is not run and the answer is status 4. Values are reached by pressing the step keys until the
value matches (the selection on the scope page is moved there with key 5, as a user would). Scope
menu entries (channel on / off, probe, coupling, FFT, trigger mode / edge / source) are applied
through the menu's own handler, then the scope page is redrawn completely.

### 4.1 Device

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x00 | INFO | - | protocol version (u8), capability bits (u32, below), firmware version text (16 bytes), chip UID (12 bytes), bootloader slot (u8: 0 F, 1 A, 2 B, 0xFF unknown), bootloader version (u32), application size (u32), result of the last staged update (u32: 0 none, 1 OK, 2 no file, 3 image does not match, 4 programmed image does not compare) |
| 0x01 | PING | any bytes | the same bytes |
| 0x02 | RESET | - | answer, then the meter restarts (no charging screen after a software restart) |
| 0x03 | BATTERY | - | battery level (u8, 5..100 as shown by the meter), charging flag (u8, 0: not established) |
| 0x04 | KEEP_AWAKE | on (u8) | - (auto power-off held while on, independent of DTR) |

Capability bits: 0 STATE, 1 STREAM, 2 PAGE, 3 KEY, 4 GEN_SET, 5 CAL_READ, 6 DRIVE, 7 firmware
update, 8 BATTERY, 9 KEEP_AWAKE, 10 MEM_READ, 11 DMM_*, 12 SCOPE_* settings, 13 SCOPE_WAVE,
14 SETTINGS_*, 15 SCREENSHOT, 16 FILE_*, 17 events, 18 FLASH_READ, 19 METER_LOG, 20 FLASH_ID.
Firmware 1.3.0: 0x7FFFF; 1.4.8: 0x1FFFFF.

### 4.2 State and keys

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x10 | STATE | - | the STATE record (4.6) |
| 0x11 | STREAM | period in ms (u16, 0 = stop) | - ; then STATE records as stream frames (cmd 0x10) at that period |
| 0x12 | PAGE | page (u8: 0 menu, 1 meter, 2 scope, 3 generator) | resulting STATE record (keys 22 / 17 / 18 / 19) |
| 0x13 | KEY | key code (u8, 1..23, table 4.7) | resulting STATE record |

### 4.3 Multimeter (meter page open, else status 3)

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x20 | DMM_FUNCTION | function (u8): 0 auto, 1 V DC, 2 V AC, 3 continuity, 4 diode, 5 resistance, 6 capacitance, 7 temperature °C, 8 temperature °F, 9 small DC current, 10 small AC current, 11 large DC current, 12 large AC current | STATE record |
| 0x21 | DMM_HOLD | on (u8) | STATE record (key 15) |
| 0x22 | DMM_RELATIVE | on (u8) | STATE record (key 7: the reading becomes value minus the reading at switch-on); status 3 where the meter refuses it (auto, diode / continuity, temperature, no reading) |

The meter's function index (0 auto, 1 voltage, 2 diode / continuity, 3 resistance, 4 capacitance,
5 temperature, 6 small current, 7 large current) is stepped with keys 14 / 13 the short way round,
the second function of an index (AC, continuity, °F) with key 4. While the meter's automatic
detection runs it ignores these keys: status 4.

### 4.4 Oscilloscope (scope page open, else status 3)

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x30 | SCOPE_TIMEBASE | index (u8, 0..28: 10 ns .. 20 s per division, texts from SCOPE_TABLES) | STATE record |
| 0x31 | SCOPE_CHANNEL | channel (u8 0 / 1), enabled (u8), V/div step (u8 0..9), offset (s8 -100..100), coupling (u8 0 AC / 1 DC), probe (u8 0 x1 / 1 x10), FFT (u8) | STATE record; status 3 when V/div or offset differ on a channel that stays off |
| 0x32 | SCOPE_TRIGGER | source (u8 0 CH1 / 1 CH2), edge (u8 0 / 1), level (s16 -100..100), mode (u8 0 normal / 1 auto / 2 single) | STATE record; status 3 for a source change unless both channels are on (as in the menu) |
| 0x33 | SCOPE_TABLES | - | timebase count (u8, 29), V/div count (u8, 13), then the timebase texts and the V/div texts, each zero-terminated (the meter's own texts; the V/div text of a channel is entry probe × 3 + step) |
| 0x34 | SCOPE_RUN | 0 stop, 1 run | STATE record (key 15); a single shot is mode 2 + run |
| 0x35 | SCOPE_AUTOSET | - | STATE record (key 2: autoset started; the meter finishes it by itself) |
| 0x36 | SCOPE_WAVE | channel (u8) | channel, timebase, V/div step, probe, coupling, offset (s8), enabled, running (u8 each), start (u16), count (u16), then the 301 display samples (u8, 128 = centre line, screen row = 248 - sample), copied as one consistent set |
| 0x37 | SCOPE_AUTOCORRECT | - | STATE record (key 16: the meter's zero / offset auto-correction started) |

### 4.5 Signal generator

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x40 | GEN_SET | output on (u8), waveform (u8, 0..12, the meter's waveform list), frequency (u32 Hz, 1..50000), duty (u8 %, 0..100), amplitude (u8, 1..30 = 0.1..3.0 V) | STATE record |

### 4.6 STATE record (44 bytes)

| Offset | Field | Type | Content |
|---|---|---|---|
| 0 | page | u8 | UI page: 0 menu, 1 meter, 2 scope, 3 generator, 4 settings, 7 drive shared, 9 scope menu; other values as the meter has them |
| 1 | flags | u16 | bit 0 hold, 1 relative, 2 scope running, 3 generator output on, 4 drive shared, 5 external power, 6 battery low, 7 DTR set by the host |
| 3 | battery | u8 | level 5..100 |
| 4 | dmm.function | u8 | as DMM_FUNCTION |
| 5 | dmm.value | f32 | the reading as the meter has it |
| 9 | dmm.unit | u8 | 0 none, 1 V, 2 A, 3 Ω, 4 F, 5 °C, 6 °F |
| 10 | dmm.decimals | u8 | digits after the point as shown |
| 11 | reserved | u8 | 0 |
| 12 | scope.timebase | u8 | index |
| 13 | scope.ch1 | {u8 enabled, u8 V/div step, s16 offset} | |
| 17 | scope.ch2 | same | |
| 21 | scope.trigger | {u8 source, u8 edge, s16 level, u8 mode} | |
| 26 | gen | {u8 on, u8 waveform, u32 frequency, u8 duty, u8 amplitude} | |
| 34 | time | u32 | milliseconds since the meter started |
| 38 | scope.ch1 extra | {u8 coupling, u8 probe, u8 FFT} | |
| 41 | scope.ch2 extra | same | |

### 4.7 Key codes (KEY)

Codes as the meter's key scanner produces them (1..15 short press, 16..23 long press). The names of
the physical keys are not part of the firmware; this table gives the function on each page.

| Code | Menu | Meter | Scope | Generator | Settings |
|---|---|---|---|---|---|
| 1 | power off (saves settings) | same | same | same | same |
| 2 | | auto function | autoset | | |
| 4 | | DC/AC (or °C/°F) | other channel | | |
| 5 | | | next selection (V/div + timebase, offset, trigger level, cursors) | | |
| 7 | | relative | | | |
| 9 | | | screenshot to the drive | | |
| 10 | | | open / close the scope menu | back | back |
| 11 / 12 | | | selected value + / - (menu: item up / down) | value up / down | value up / down |
| 13 / 14 | item up / down | function back / next | timebase + / - | digit left / right | field edit |
| 15 | open item | hold | run / stop (menu: enter / apply) | next field | apply |
| 16 | | | auto-correction | | |
| 17 / 18 / 19 | meter / scope / generator page | | | | |
| 22 | | menu | menu | menu | menu |
| 23 | | | | output on / off | |

### 4.8 Settings

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x50 | SETTINGS_GET | - | backlight (u8 25..100), sound (u8 0..10), auto shutdown (u8 0 off, 1..3 the menu's three times), startup option (u8 0..2, the menu's three entries) |
| 0x51 | SETTINGS_SET | the same four bytes | the settings now in effect (in RAM, backlight applied at once; not saved) |
| 0x52 | SETTINGS_SAVE | - | answer; then the meter writes its settings page (the same routine as when it powers off) and restarts; the port goes away and comes back |
| 0x53 | CAL_READ | offset (u32) | total (u32), up to 256 bytes of the settings / calibration page 0x08006000..0x080067FF |

### 4.9 Screen

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x60 | SCREENSHOT | - | first 480 stream frames (cmd 0x60): offset (u32) + 320 bytes, half a row each, rows top to bottom, RGB565 little-endian per pixel, read back from the display; then the answer: total (u32, 153600), width (u16, 320), height (u16, 240), format (u8, 0 = RGB565). The display is not drawn while it is read, so the picture is consistent. |

### 4.10 Files and drive (drive 2:, system pictures on 3:; status 3 while the drive is shared)

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x70 | FILE_LIST | first entry (u16), directory path (text, e.g. `2:/` or `3:/System file`) | next entry (u16, 0xFFFF = no more), then entries {size u32, attribute u8, name length u8, name} as many as fit |
| 0x71 | FILE_READ | offset (u32), path (at most 95 characters) | file size (u32), then up to 500 bytes from the offset; the file stays open while the host reads it in order (same path, next offset) and is closed at its end or by any other command |
| 0x72 | FILE_WRITE | offset (u32), total (u32), path (zero-terminated), data | - ; offset 0 creates or truncates the file; each further chunk continues at the bytes written so far; the file is closed when the total is reached; status 6 for a path that is neither on `2:` nor exactly `3:/System file/` + a picture number 1..167 without leading zero + `.jpg` |
| 0x73 | FILE_DELETE | path (at most 95 characters) | - (a file or an empty directory on `2:`, or a picture `3:/System file/NNN.jpg` named as for FILE_WRITE; status 5 when it is still there afterwards, 6 for any other path) |
| 0x74 | DRIVE | on (u8) | - (shares the drive with the host: UI page 7 and the configuration with mass storage) |

Paths: `2:/DIR/NAME.EXT`, long names allowed. Drive 3: holds the meter's own system files: FILE_LIST
and FILE_READ may read all of it; FILE_WRITE and FILE_DELETE may only write or delete the user-interface pictures
`3:/System file/NNN.jpg` (NNN 1..167, no leading zero; baseline JPEG, what the meter's decoder accepts
is in `src/image_20.s`). Nothing else on 3: can be written or deleted: `3:/System file/9999.bin` must
stay, because at start-up its presence selects drive 2: as the USB drive (`filesystem_startup_setup`,
src/filesystem_08.s); without it the computer would get drive 3:.

While the drive is shared the host owns it: the meter writes nothing into it (its own writes to that
drive are refused) and re-reads it from the flash when it gets it back. Eject the drive on the host
before ending the sharing; a host that is cut off in the middle of its own updates can still leave
its file system inconsistent.

### 4.11 Firmware update

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x80 | FW_BEGIN | total length (u32), CRC-32 (u32) of the image | - (creates `2:/UPDATE/APP.BIN`) |
| 0x81 | FW_DATA | offset (u32), chunk | - |
| 0x82 | FW_END | - | - (the meter checks length and CRC-32 of the staged file) |
| 0x83 | FW_INSTALL | - | answer, then the meter restarts into the bootloader, which programs the staged image only if it is still complete and correct, and starts it; refused (status 6) unless the running bootloader supports staged updates (INFO bootloader version ≥ 2) |

The host confirms the result afterwards with INFO (new firmware version, last update OK).

### 4.12 Events (type 0x04, only while DTR is set)

| cmd | Event | Data |
|---|---|---|
| 0x90 | KEY_PRESSED | key code (u8), for every key the key task carries out (also those of KEY) |
| 0x91 | PAGE_CHANGED | page (u8, as in STATE) |
| 0x92 | BATTERY_LOW | level (u8); sent once when the meter enters its low-battery state (below level 6) |

### 4.13 Diagnostics

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0xF0 | MEM_READ | address (u32), length (u16, at most 256) | bytes; read-only, only internal flash 0x08000000..0x080FFFFF and the RAM words 0x20037FB0..0x20037FFF (fault record, then the bootloader words) (status 6 otherwise) |
| 0xF2 | FLASH_READ | address (u32), length (u16, 1..256), address + length at most 16 MB | bytes of the external SPI flash (drive 3: from 0, drive 2: from 0x200000); read-only |
| 0xF3 | METER_LOG | op (u8): 1 start, 0 stop, 2 read + offset (u16) | read: count (u16), then up to 256 recorded bytes from the offset. Records the bytes the multimeter chip sends to the application (USART2, 9600 baud) into a 2048-byte buffer from the allocator, until it is full or stopped; nothing is sent to the chip; status 3 for read while not recording, 5 when no buffer is free |
| 0xF4 | FLASH_ID | - | JEDEC identification of the external SPI flash (command 0x9F): manufacturer, memory type, capacity (3 bytes); read-only |

Fault record (MEM_READ 0x20037FB0, 48 bytes, little-endian words; `src/fault.s`): +0 magic 0xFA017EC0
when valid, +4 exception number (3: hard fault; memory management, bus and usage faults are not enabled
separately (SHCSR is left at its reset value), so they arrive as hard faults with CFSR naming the cause), +8 stacked
PC, +12 stacked LR, +16 stacked xPSR, +20 CFSR, +24 HFSR, +28 MMFAR, +32 BFAR, +36 stack pointer of the
frame, +40 current task record, +44 faults since the record was first written. The meter restarts right
after writing it; the record survives restarts, not power-off.
