@ boot_dump.s - writes copies of the internal flash below the application and of the system memory
@ words to drive "2:" (the storage the meter shares over USB) when the file 2:/BOOTDUMP.TXT exists
@ at start-up (boot_hook_then_file_open in boot_install.s checks for it).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
@
@ Files written (each opened with mode 10 = write, create / truncate):
@   2:/BOOTDUMP.BIN  0x7000 bytes from 0x08000000: the bootloader and the settings / calibration page
@                    at 0x08006000 (the area below the application at 0x08007000)
@   2:/SYSINFO.BIN   0x50 bytes from 0x1FFFF7E0: system memory words around the option bytes; the
@                    application itself reads 0x1FFFF7E8.. (0x08036DB0) and 0x1FFFF810 (0x08033F7C)
@   2:/FLASHREG.BIN  0xA0 bytes: word copy of the flash controller 0x40022000..0x4002209F (status,
@                    control, option byte status 0x4002201C, write protection 0x40022020, the second
@                    register bank at +0x40 and the block at +0x80 that the stock bootloader reads)
@ Only reads the internal flash; nothing in the internal flash is written.  Any failure of a dump
@ file is ignored.
@ Not assembled for the vendor-text build (make check, VENDOR_V120).

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

	.ifndef	VENDOR_V120

	.section .text.boot_dump,"ax",%progbits
	.p2align 2

@ ----------------------------------------------------------------------------
@ boot_dump - r0 = a file object of the caller (0x102C bytes, not open); writes the three dump
@ files with it.  Stack: r4..r6, lr and 8 bytes ([sp] = byte count of file_write): 24 bytes.
@ ----------------------------------------------------------------------------
	.global	boot_dump
	.thumb_func
	.type	boot_dump, %function
boot_dump:
	push	{r4, r5, r6, lr}
	sub	sp, #8
	mov	r4, r0			@ r4 = file object

	movs	r0, #0xA0		@ RAM copy of the flash controller registers
	bl	alloc_units_of_32_bytes
	movs	r6, r0			@ r6 = register copy, 0 if no memory
	beq	.Lregs_done
	ldr	r1, .Lflash_regs	@ 0x40022000: flash controller (both register banks + 0x80..0x9C)
	movs	r2, #0
.Lcopy_reg:
	ldr	r3, [r1, r2]		@ word reads only: no register here changes when read
	str	r3, [r6, r2]
	adds	r2, #4
	cmp	r2, #0xA0
	bne	.Lcopy_reg
.Lregs_done:

	adr	r5, .Ldump_table	@ r5 -> {path, source, length} records, path 0 ends
.Lnext_file:
	ldr	r1, [r5, #0]		@ path
	cbz	r1, .Lfree
	ldr	r0, [r5, #4]		@ source 0 = the register copy in r6
	cbnz	r0, .Lopen
	cbz	r6, .Lskip_file		@ no register copy: skip that file
.Lopen:
	mov	r0, r4
	movs	r2, #10			@ write, create / truncate
	bl	file_open
	cbnz	r0, .Lskip_file		@ open failed: next file
	mov	r0, r4
	ldr	r1, [r5, #4]		@ source address
	cbnz	r1, .Lsrc_ok
	mov	r1, r6			@ source 0: the register copy
.Lsrc_ok:
	ldr	r2, [r5, #8]		@ length in bytes
	mov	r3, sp			@ byte count written
	bl	file_write
	mov	r0, r4
	bl	file_close		@ flushes and updates the directory entry
.Lskip_file:
	adds	r5, #12
	b	.Lnext_file

.Lfree:
	cbz	r6, .Ldone
	mov	r0, r6
	bl	free_units_of_32_bytes
.Ldone:
	add	sp, #8
	pop	{r4, r5, r6, pc}

	.p2align 2
.Lflash_regs:
	.word	0x40022000
.Ldump_table:
	.word	.Lpath_boot, 0x08000000, 0x7000
	.word	.Lpath_sys,  0x1FFFF7E0, 0x50
	.word	.Lpath_regs, 0, 0xA0	@ source 0: the RAM copy of 0x40022000..0x4002209F
	.word	0
.Lpath_boot:
	.asciz	"2:/BOOTDUMP.BIN"
.Lpath_sys:
	.asciz	"2:/SYSINFO.BIN"
.Lpath_regs:
	.asciz	"2:/FLASHREG.BIN"

	.endif
