#!/usr/bin/env python3
"""make_images.py - builds the RAM images that swd_loader.s programs into the blank chip after the
access protection was removed (FLASHING_BOOTLOADER.md).

    python3 make_images.py <BOOTDUMP.BIN of this meter>

<BOOTDUMP.BIN> is the file the application (V1.2.4 or later of this rewrite) writes to its USB drive
when BOOTDUMP.TXT exists: 0x7000 bytes from 0x08000000, the meter's settings / calibration page at
offset 0x6000. The calibration is individual to each meter: use the dump of the meter being flashed.

Output in swd/build/ (run `make` in swd/ first for swd_loader.bin):
  table.bin  block table for 0x20000810: {flash address, RAM source, byte count} per block, 0-ended
  data.bin   block data for 0x20001000 (each block word aligned)
  cal.bin, slotf_image.bin, slotf_header.bin, starter.bin   one file per block (for verify_image)
  plan.txt   the blocks with addresses, sizes and CRC-32
Blocks, in programming order:
  1. 0x08006000  settings / calibration page (dump offset 0x6000..0x67FF)
  2. 0x080E8200  slot F image: bootloader/build/slot/BOOT_F.bin
  3. 0x080E8000  slot F header (28 bytes, as build_header in src/boot_install.s)
  4. 0x08000000  starter: starter/build/STARTER.bin
No records, no slot A and no application: the starter starts slot A when there is no record, finds no
valid header and starts slot F, which finds no "8KTA" mark and stays in its update mode.
"""
import os, struct, sys, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.join(HERE, '..')
OUT = os.path.join(HERE, 'build')
DATA_BASE = 0x20001000
TABLE_BASE = 0x20000810
SLOT_F = 0x080E8000


def read(p):
    with open(p, 'rb') as f:
        return f.read()


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    dump = read(sys.argv[1])
    if len(dump) != 0x7000:
        sys.exit('%s: %d bytes, a BOOTDUMP.BIN has 0x7000 (28672)' % (sys.argv[1], len(dump)))
    if struct.unpack_from('<I', dump, 0)[0] != 0x20001A08:
        sys.exit('%s: word 0 is not the stock bootloader stack pointer 0x20001A08: not a BOOTDUMP.BIN' % sys.argv[1])
    cal = dump[0x6000:0x6800]
    if cal == b'\xff' * 0x800:
        sys.exit('%s: the page at offset 0x6000 is erased: no calibration in this dump' % sys.argv[1])
    img_f = read(os.path.join(REPO, 'bootloader', 'build', 'slot', 'BOOT_F.bin'))
    starter = read(os.path.join(REPO, 'starter', 'build', 'STARTER.bin'))
    hdr = struct.pack('<IIIIII', 0x544F4C53, 1, SLOT_F, len(img_f), zlib.crc32(img_f) & 0xFFFFFFFF, 1)
    hdr += struct.pack('<I', zlib.crc32(hdr) & 0xFFFFFFFF)
    blocks = [('cal', 0x08006000, cal, 'settings / calibration page (dump offset 0x6000)'),
              ('slotf_image', SLOT_F + 0x200, img_f, 'slot F image BOOT_F.bin'),
              ('slotf_header', SLOT_F, hdr, 'slot F header'),
              ('starter', 0x08000000, starter, 'starter STARTER.bin')]
    data, table, lines = b'', b'', []
    for name, addr, blob, what in blocks:
        assert len(blob) % 4 == 0, what
        src = DATA_BASE + len(data)
        table += struct.pack('<III', addr, src, len(blob))
        data += blob
        lines.append('0x%08x  %6d bytes  crc32 %08x  RAM 0x%08x  %s'
                     % (addr, len(blob), zlib.crc32(blob) & 0xFFFFFFFF, src, what))
    table += struct.pack('<III', 0, 0, 0)
    assert TABLE_BASE + len(table) <= DATA_BASE
    assert DATA_BASE + len(data) <= 0x20018000            # inside 96 KB, whatever the RAM option says
    os.makedirs(OUT, exist_ok=True)
    for name, addr, blob, what in blocks:
        with open(os.path.join(OUT, name + '.bin'), 'wb') as f:
            f.write(blob)
    with open(os.path.join(OUT, 'table.bin'), 'wb') as f:
        f.write(table)
    with open(os.path.join(OUT, 'data.bin'), 'wb') as f:
        f.write(data)
    with open(os.path.join(OUT, 'plan.txt'), 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print('\n'.join(lines))
    print('data %d bytes, table %d bytes -> %s' % (len(data), len(table), OUT))


if __name__ == '__main__':
    main()
