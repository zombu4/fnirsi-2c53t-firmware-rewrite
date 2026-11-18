# swd_install.tcl - OpenOCD procedures for installing the starter and slot F on the meter through the
# SWD probe (FLASHING_BOOTLOADER.md). Every step prints what it read; nothing runs by itself.
#
# Phase 1 (protection on, meter powered by holding the power button; config at32-noHalt.cfg, the
# CPU is never halted):
#   p1_check        reads the chip ID 0xE0042000 (expects 0x70050344) and 0x4002201C (bit 1 = protection)
#   p1_fap_disable  the sequence of OpenOCD's artery_disable_fap (src/flash/nor/artery.c): flash keys
#                   (0x40022004), option-area keys (0x40022008), wait for control bit 9 (USDULKS),
#                   control 0x260 (USDULKS|USDERS|ERSTR) = erase the option area, clear PRGMERR,
#                   control 0x210 (USDULKS|USDPRGM), halfword 0x5AA5 to 0x1FFFF800 (FAP 0xA5 + inverse).
#                   RM 5.5.1: the change from protected to unprotected erases the main flash; the
#                   driver's comment: "the device performed a reset anyway".
# Phase 2 (blank chip, button still held; config at32-core.cfg):
#   p2_check        halts, reads 0xE0042000, 0x4002201C (bit 1 must be 0), 0x08000000, 0x08006000,
#                   0x080E8000 (all must read 0xFFFFFFFF after the mass erase)
#   p2_program      loads build/swd_loader.bin to 0x20000000, build/table.bin to 0x20000810, build/data.bin to
#                   0x20001000, presets the result word, runs the loader, waits for its breakpoint,
#                   prints the result block (0 = ok)
#   p2_verify       verify_image of every block (reads the flash back over SWD) and reads 0x1FFFF810
#   p2_start        reset and run: the starter starts slot F (no records, no slot A)

proc rd32 {tgt addr} { return [lindex [$tgt read_memory $addr 32 1] 0] }

proc wait_not_busy {tgt} {
	for {set i 0} {$i < 2000} {incr i} {
		if {([rd32 $tgt 0x4002200C] & 1) == 0} { return 0 }
	}
	echo "flash still busy"
	return 1
}

proc p1_check {} {
	echo [format "chip ID 0xE0042000 = 0x%08x" [rd32 at32.ap 0xE0042000]]
	set usd [rd32 at32.ap 0x4002201C]
	echo [format "0x4002201C = 0x%08x (bit 1 protection = %d)" $usd [expr {($usd >> 1) & 1}]]
}

proc p1_fap_disable {} {
	set t at32.ap
	if {[rd32 $t 0xE0042000] != 0x70050344} { echo "wrong chip ID: stop"; return }
	$t mww 0x40022004 0x45670123
	$t mww 0x40022004 0xCDEF89AB
	$t mww 0x40022008 0x45670123
	$t mww 0x40022008 0xCDEF89AB
	set ctrl [rd32 $t 0x40022010]
	echo [format "control after keys = 0x%08x" $ctrl]
	if {($ctrl & 0x200) == 0} { echo "option area not unlocked (bit 9 clear): stop, nothing erased"; return }
	if {[wait_not_busy $t]} { return }
	$t mww 0x40022010 0x260
	if {[wait_not_busy $t]} { return }
	echo [format "status after option erase = 0x%08x" [rd32 $t 0x4002200C]]
	$t mww 0x4002200C 0x04
	$t mww 0x40022010 0x210
	if {[wait_not_busy $t]} { return }
	echo "writing FAP 0xA5 (0x5AA5 to 0x1FFFF800): the chip resets and erases the main flash"
	catch { $t mwh 0x1FFFF800 0x5AA5 }
	echo "done; keep holding the button"
}

proc p2_check {} {
	halt
	echo [format "chip ID = 0x%08x" [rd32 at32.cpu 0xE0042000]]
	set usd [rd32 at32.cpu 0x4002201C]
	echo [format "0x4002201C = 0x%08x (bit 1 protection = %d)" $usd [expr {($usd >> 1) & 1}]]
	foreach a {0x08000000 0x08006000 0x08007000 0x080E8000} {
		echo [format "0x%08x = 0x%08x" $a [rd32 at32.cpu $a]]
	}
}

proc p2_program {} {
	halt
	if {([rd32 at32.cpu 0x4002201C] >> 1) & 1} { echo "protection still on: stop"; return }
	load_image build/swd_loader.bin 0x20000000 bin
	load_image build/table.bin 0x20000810 bin
	load_image build/data.bin 0x20001000 bin
	at32.cpu mww 0x20000800 0xFFFFFFFF
	reg xpsr 0x01000000
	reg sp 0x20000800
	reg pc 0x20000000
	resume
	wait_halt 60000
	set r [at32.cpu read_memory 0x20000800 32 3]
	echo [format "loader result %d, address 0x%08x, blocks done %d" {*}$r]
}

proc p2_verify {} {
	halt
	verify_image build/cal.bin 0x08006000 bin
	verify_image build/slotf_image.bin 0x080E8200 bin
	verify_image build/slotf_header.bin 0x080E8000 bin
	verify_image build/starter.bin 0x08000000 bin
	echo [format "0x1FFFF810 = 0x%08x" [rd32 at32.cpu 0x1FFFF810]]
}

proc p2_start {} {
	reset run
	echo "reset: the starter runs; slot F should hold the power and show its update mode"
}
