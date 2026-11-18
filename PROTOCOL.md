# FNIRSI 2C53T USB control protocol (draft, protocol version 1)

This document specifies the control channel of this firmware: a USB serial port (CDC ACM) next to the
meter's USB drive. It covers reading and controlling every function of the meter, file access and
firmware updates, for test tools and for a companion application. Status: **specification, not yet
implemented**; changes until the first release that implements it.

## 1. Transport

- USB device: VID `0x2E3C`, PID `0x2C53`, composite: interface 0 mass storage (the drive), interfaces
  1 + 2 CDC ACM (the control channel). The serial number is the chip's unique ID, so the host port name
  stays the same (macOS: `/dev/cu.usbmodem<serial>`).
- The control channel is available whenever the meter is on and USB is connected; no menu setting is
  needed. Line settings (baud rate etc.) are accepted and ignored.
- The host opens the port and sets DTR. While DTR is set the meter does not switch itself off and may
  send stream and event frames. Without DTR it only answers requests.

## 2. Frames

All multi-byte numbers are little-endian.

| Field | Size | Content |
|---|---|---|
| sync | 1 | `0xA5` |
| length | 2 | number of bytes from `seq` to the end of `payload` |
| seq | 1 | request: chosen by the host; answer: the same value; stream / event: running counter |
| type | 1 | `0x01` request, `0x02` answer, `0x03` stream, `0x04` event |
| cmd | 1 | command number (section 4) |
| payload | n | command data, at most 512 bytes |
| crc | 2 | CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF) over `length` .. `payload` |

- Every request gets exactly one answer with the same `seq` and `cmd`. The first payload byte of an
  answer is a status (section 3); data follows it.
- The host sends the next request only after the answer of the previous one, or after a 500 ms
  timeout.
- Receivers resynchronise by searching for `0xA5` and checking the CRC; a frame with a bad CRC is
  dropped without an answer.
- Data larger than one frame (screenshots, waveforms, files, firmware) is transferred in chunks: each
  chunk request carries `offset` (u32) and the answer carries `total` (u32) and the chunk data.

## 3. Status codes

| Code | Meaning |
|---|---|
| 0 | OK |
| 1 | unknown command |
| 2 | bad length or argument |
| 3 | not allowed in the current state (e.g. a scope command while the meter page is open) |
| 4 | busy (try again) |
| 5 | file system error (detail byte follows) |
| 6 | refused for safety (e.g. memory write outside the test build, write to a protected area) |
| 7 | CRC or length mismatch of transferred data |

## 4. Commands

### 4.1 Device

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x00 | INFO | - | protocol version (u8), capability bits (u32: bit 0 STATE, 1 STREAM, 2 PAGE, 3 KEY, 4 GEN_SET, 5 CAL_READ, 6 DRIVE, 7 firmware update, 8 BATTERY, 9 KEEP_AWAKE; other commands answer status 1 until their bit is set), firmware version text (16 bytes), chip UID (12 bytes), bootloader slot (u8: 0 F, 1 A, 2 B, 0xFF unknown), bootloader version (u32), application size (u32), result of the last staged update (u32: 0 none, 1 OK, 2 no file, 3 image does not match, 4 programmed image does not compare) |
| 0x01 | PING | any bytes | the same bytes (throughput tests) |
| 0x02 | RESET | - | answer, then the meter restarts |
| 0x03 | BATTERY | - | battery level (u8, 5..100 as shown by the meter), charging flag (u8) |
| 0x04 | KEEP_AWAKE | on (u8) | - (auto power-off held while on, independent of DTR) |

### 4.2 State and measurements

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x10 | STATE | - | the STATE record (4.6) |
| 0x11 | STREAM | period in ms (u16, 0 = stop) | - ; then STATE records as stream frames at that period (frames are dropped, not queued, while the host does not read) |
| 0x12 | PAGE | page (u8: 0 menu, 1 meter, 2 scope, 3 generator, 4 settings, 5 screenshot list) | resulting STATE record |
| 0x13 | KEY | key code (u8, 1..23, table 4.7) | resulting STATE record |

### 4.3 Multimeter

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x20 | DMM_FUNCTION | function (u8: 0 auto, 1 V DC, 2 V AC, 3 continuity, 4 diode, 5 resistance, 6 capacitance, 7 temperature °C, 8 temperature °F, 9 small DC current, 10 small AC current, 11 large DC current, 12 large AC current) | STATE record |
| 0x21 | DMM_HOLD | on (u8) | STATE record |
| 0x22 | DMM_RELATIVE | on (u8) | STATE record |

### 4.4 Oscilloscope

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x30 | SCOPE_TIMEBASE | index (u8, 0..27; the table of times is in the INFO capabilities answer of cmd 0x33) | STATE record |
| 0x31 | SCOPE_CHANNEL | channel (u8), enabled (u8), V/div index (u8), offset (s16), coupling (u8) | STATE record |
| 0x32 | SCOPE_TRIGGER | source (u8), edge (u8), level (s16), mode (u8: auto / normal / single) | STATE record |
| 0x33 | SCOPE_TABLES | - | timebase table (28 × u32 ns per division), V/div table |
| 0x34 | SCOPE_RUN | 0 stop, 1 run, 2 single | STATE record |
| 0x35 | SCOPE_AUTOSET | - | STATE record |
| 0x36 | SCOPE_WAVE | offset (u32) | total (u32), chunk: header (timebase, V/div and offset per channel, trigger), then the samples of channel 1 and 2 (u8 each, 1024 per channel) |

### 4.5 Signal generator

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x40 | GEN_SET | output on (u8), waveform (u8, 0..12: sine, square, sawtooth, half wave, full wave, step, reverse step, exponential up, exponential down, DC, multi-tone, sinc pulse, Lorentz), frequency (u32 Hz, 1..50000), duty (u8 %, 0..100, square and sawtooth only), amplitude (u8, 1..30 = 0.1..3.0 V) | STATE record |

### 4.6 STATE record

| Field | Type | Content |
|---|---|---|
| page | u8 | 0 menu, 1 meter, 2 scope, 3 generator, 4 settings, 5 screenshot list, 6 screenshot view, 7 drive shared |
| flags | u16 | bit 0 hold, bit 1 relative, bit 2 scope running, bit 3 generator output on, bit 4 drive shared, bit 5 charging |
| battery | u8 | level 5..100 |
| dmm.function | u8 | as DMM_FUNCTION |
| dmm.value | f32 | reading in the unit below (NaN when no reading, e.g. overload) |
| dmm.unit | u8 | 0 none, 1 V, 2 A, 3 Ω, 4 F, 5 °C, 6 °F, 7 Hz, 8 % |
| dmm.decimals | u8 | digits after the point as shown |
| dmm.range | u8 | range code of the meter chip |
| scope.timebase | u8 | index |
| scope.channels | 2 × {u8 enabled, u8 V/div index, s16 offset} | |
| scope.trigger | {u8 source, u8 edge, s16 level, u8 mode} | |
| gen | {u8 on, u8 waveform, u32 frequency, u8 duty, u8 amplitude} | |
| time | u32 | milliseconds since the meter started |

### 4.7 Key codes (KEY)

Codes as the meter's key scanner produces them (1..15 short press, 16..23 long press). The names of
the physical keys are not part of the firmware; this table gives the function on each page.

| Code | Menu | Meter | Scope | Generator | Settings |
|---|---|---|---|---|---|
| 1 | power off (saves settings, restarts) | same | same | same | same |
| 2 | | auto function | reset view | | |
| 4 | | DC/AC (or °C/°F) | next channel | | |
| 7 | | hold | menu item 2 | | |
| 9 | | | screenshot | | |
| 10 | | | open scope menu | back | back |
| 11 / 12 | | | value up / down | value up / down | value up / down |
| 13 / 14 | item up / down | function back / next | timebase up / down | digit left / right | field edit |
| 15 | open item | relative | run / stop | next field | apply |
| 16 | | | autoset | | |
| 17 / 18 / 19 | meter / scope / generator page | | | | |
| 22 | | menu | menu | menu | menu |
| 23 | | | | output on / off | |

(Codes 3, 5, 6, 8, 20, 21 act on the scope menu and the screenshot pages; full table in the firmware
documentation.)

### 4.8 Settings

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x50 | SETTINGS_GET | - | backlight (u8), auto power-off (u8: 0 off, 1 15 min, 2 30 min, 3 60 min), colour theme (u8), other settings as implemented |
| 0x51 | SETTINGS_SET | same layout | the settings now in effect (in RAM; not saved) |
| 0x52 | SETTINGS_SAVE | - | - (writes the settings page; at most once per 10 s) |
| 0x53 | CAL_READ | offset (u32) | total (u32), up to 256 bytes of the settings / calibration page 0x08006000..0x080067FF |

### 4.9 Screen

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x60 | SCREENSHOT | offset (u32; 0 starts a new capture) | total (u32), chunk of a 320 × 240 RGB565 image, rows top to bottom |

### 4.10 Files and drive

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x70 | FILE_LIST | path (text) | entries: name, size (u32), attributes (u8) |
| 0x71 | FILE_READ | path, offset (u32) | total (u32), chunk |
| 0x72 | FILE_WRITE | path, offset (u32), total (u32), chunk | - (refused under `3:/System file`) |
| 0x73 | FILE_DELETE | path | - (refused under `3:/System file`) |
| 0x74 | DRIVE | on (u8) | - (shares the drive with the host; while shared, the meter itself does not write files and FILE_* answer status 3) |

### 4.11 Firmware update

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0x80 | FW_BEGIN | total length (u32), CRC-32 (u32) of the image | - (creates `2:/UPDATE/APP.BIN`) |
| 0x81 | FW_DATA | offset (u32), chunk | - |
| 0x82 | FW_END | - | - (the meter checks length, CRC-32 and the vector table of the staged file) |
| 0x83 | FW_INSTALL | - | answer, then the meter restarts into the bootloader, which programs the staged image only if it is still complete and correct, and starts it; refused (status 6) unless the running bootloader supports staged updates (INFO bootloader version ≥ 2) |

The host confirms the result afterwards with INFO (new firmware version).

### 4.12 Events (type 0x04, only while DTR is set)

| cmd | Event | Data |
|---|---|---|
| 0x90 | KEY_PRESSED | key code |
| 0x91 | PAGE_CHANGED | page |
| 0x92 | BATTERY_LOW | level |
| 0x93 | POWER_OFF_SOON | seconds |

### 4.13 Test build only

| cmd | Name | Request | Answer data |
|---|---|---|---|
| 0xF0 | MEM_READ | address (u32), length (u16) | bytes |
| 0xF1 | MEM_WRITE | address (u32), bytes | - (only inside the test build's allowed RAM ranges; never flash, flash controller, option bytes or calibration) |

## 5. Open items of this draft

These parts are not yet established from the firmware and are fixed before the implementation:

- DMM_RELATIVE: key 15 on the meter page toggles a flag whose function is not yet proven.
- SCOPE_CHANNEL coupling, SCOPE_TRIGGER source / edge / mode and the V/div table: the variables are
  not yet located.
- Waveform names 7, 8 and 11: the vendor texts are "Index Up", "Index Decrease" and "Sink Pulse"; the
  names above (exponential, sinc) are interpretations until the sample tables are checked.
- STATE dmm.unit / dmm.range: the mapping from the meter chip's range and unit codes is not yet proven.
- Physical key names (labels on the meter) for table 4.7.
