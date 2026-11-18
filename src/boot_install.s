@ boot_install.s - the start-up hook of this rewrite and the installer of the two-part bootloader
@ (BOOTLOADER_DESIGN.md revision 2, section 6).  Part of the FNIRSI 2C53T firmware rewrite
@ (hand-written Thumb-2 assembly).
@
@ boot_hook_then_file_open is entered instead of the file_open call that opens
@ "2:/LOGO/LOGO2C53T.jpg" in system_bring_up (system_58.s), with that call's arguments; drive "2:" is
@ the storage the meter shares over USB.  It runs, each only when its trigger file exists:
@   2:/BOOTDUMP.TXT  -> boot_dump (boot_dump.s): copies of the flash below 0x08007000 and of system words
@   2:/BOOTTEST.TXT  -> boot_install dry run: every check, slots F / A and records written in a
@                       first install, page 0 never; report in 2:/BOOTINST.LOG (wins over BOOTINST)
@   2:/BOOTINST.TXT  -> boot_install: installs or updates the two-part bootloader, report in
@                       2:/BOOTINST.LOG
@ and then jumps to file_open with the original arguments, so the start-up continues as before.
@
@ boot_install, by the content of flash page 0 (0x08000000..0x080007FF):
@ - the stock page 0 (equal to the dump, embedded below) and the rest of the stock bootloader
@   0x08000800..0x08005873 with CRC-32 0x64266A45 (dumps/BOOTDUMP_2026-11-17.bin): first install.
@   Slot F and slot A get the embedded images (each erased, image programmed and compared, header
@   programmed last), the record pages get one record INSTALL A, and only then page 0 is replaced by
@   the starter, by p0_code running from RAM with interrupts off (erase first: a refused erase leaves
@   the stock bootloader untouched; any later failure puts the stock page 0 back).
@ - the starter (embedded image, rest of the page erased): bootloader update.  The slot of the
@   newest record (A without records) is the running one; when it already holds the embedded image
@   nothing is written; otherwise the other one of A / B gets the embedded image and an INSTALL record
@   is appended (the starter tries it at the next start, rolls back when it does not confirm).  Slot
@   F and page 0 are never written in this case.
@ - anything else: nothing is written.
@ Running it again changes nothing once a step is done (a slot that holds its image is not written
@ again), so the trigger file may stay; the log is written at every start while it exists.
@ Flash writes: only the slots, the record pages (bank 2, common/records.inc primitives) and page 0
@ (p0_code); the "8KTA" page, the settings / calibration page 0x08006000 and the application are not
@ touched.  The independent watchdog (key register 0x40003000, the application starts it) is fed
@ before every page erase and every 128 programmed words.
@ Not assembled for the vendor-text build (make check, VENDOR_V120).

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

	.ifndef	VENDOR_V120

	.include "common/layout.inc"

	.equ	IWDG_KR,	0x40003000	@ independent watchdog key register (0xAAAA = reload)
	.equ	FLASH_SIZE_KB,	0x1FFFF7E0	@ flash size in KB (halfword; 0x0400 on the owner's meter)
	.equ	STOCK_REST_CRC,	0x64266A45	@ CRC-32 of 0x08000800..0x08005873 of the stock bootloader
	.equ	STOCK_END,	0x08005874	@ end of the stock bootloader image (0x5874 bytes)
	.equ	LOG_SIZE,	1024		@ report buffer, first word = write pointer
	.equ	BATTERY_MIN_RAW, 2128		@ lowest battery reading accepted for a first install, see
						@ battery_read

	.section .text.boot_install,"ax",%progbits
	.p2align 2

@ ----------------------------------------------------------------------------
@ boot_hook_then_file_open - r0 = file object, r1 = path, r2 = mode of the logo open (kept).
@ Allocates a file object of its own (0x102C bytes, the size the firmware uses), runs boot_dump /
@ boot_install when their trigger files open (mode 1: read, existing file only), frees the object
@ and tail-jumps to file_open(r0, r1, r2).  Stack: r0..r4, lr (24 bytes).
@ ----------------------------------------------------------------------------
	.global	boot_hook_then_file_open
	.thumb_func
	.type	boot_hook_then_file_open, %function
boot_hook_then_file_open:
	push	{r0, r1, r2, r3, r4, lr}
	movw	r0, #0x102c
	bl	alloc_units_of_32_bytes
	movs	r4, r0			@ r4 = own file object
	beq	.Lhook_done		@ no memory: nothing runs
	mov	r0, r4
	ldr	r1, =s_dump_trigger
	movs	r2, #1			@ read, existing file only
	bl	file_open
	cbnz	r0, 1f
	mov	r0, r4
	bl	file_close
	mov	r0, r4
	bl	boot_dump
1:	mov	r0, r4			@ the dry run first: with both files only the dry run happens
	ldr	r1, =s_test_trigger
	movs	r2, #1
	bl	file_open
	cbnz	r0, 2f
	mov	r0, r4
	bl	file_close
	mov	r0, r4
	movs	r1, #1			@ dry run
	bl	boot_install
	b	3f
2:	mov	r0, r4
	ldr	r1, =s_install_trigger
	movs	r2, #1
	bl	file_open
	cbnz	r0, 3f
	mov	r0, r4
	bl	file_close
	mov	r0, r4
	movs	r1, #0			@ real install
	bl	boot_install
3:	mov	r0, r4
	bl	free_units_of_32_bytes
.Lhook_done:
	pop	{r0, r1, r2, r3, r4, lr}
	b.w	file_open		@ the original call, arguments unchanged

@ ----------------------------------------------------------------------------
@ boot_install - r0 = file object (not open), r1 = 1 for the dry run (BOOTTEST.TXT), 0 for the real
@ install (BOOTINST.TXT).  See the file header.  The dry run does every check and, in a first
@ install, writes slots F and A and the records (bank 2, nothing the stock bootloader uses) but
@ never page 0; in an update it writes nothing and reports the slot it would write.  The report
@ goes to the buffer at r11 (LOG_SIZE bytes, [r11] = write pointer) and is written to
@ 2:/BOOTINST.LOG at the end.
@ Frame: [sp + 0..15] scan state of rec_scan, [sp + 16] byte count of file_write.
@ Registers: r4 file object, r5 / r6 / r7 work, r10 dry-run flag, r11 report buffer.
@ ----------------------------------------------------------------------------
	.thumb_func
	.type	boot_install, %function
boot_install:
	push	{r3, r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #24
	mov	r4, r0
	mov	r10, r1			@ r10 = 1: dry run
	mov	r0, #LOG_SIZE
	bl	alloc_units_of_32_bytes
	cmp	r0, #0
	beq	.Li_return		@ no memory: no report, nothing done
	mov	r11, r0
	add	r1, r0, #4
	str	r1, [r0]		@ write pointer
	ldr	r0, =s_title
	bl	log_str
	cmp	r10, #0
	beq	1f
	ldr	r0, =s_dry_title
	bl	log_str
1:

	ldr	r0, =FLASH_SIZE_KB	@ the layout needs 1024 KB
	ldrh	r0, [r0]
	cmp	r0, #0x400
	beq	1f
	ldr	r0, =s_flash_size
	bl	log_str
	b	.Li_finish
1:	ldr	r0, =0x08000000
	ldr	r1, =img_stock_page0
	mov	r2, #0x800
	bl	mem_equal
	cbnz	r0, .Li_stock
	bl	page0_is_starter
	cmp	r0, #0
	bne	.Li_update
	ldr	r0, =s_page0_unknown
	bl	log_str
	b	.Li_finish

@ --- first install (stock bootloader present)
.Li_stock:
	ldr	r0, =0x08000800
	ldr	r1, =(STOCK_END - 0x08000800)
	bl	crc32
	ldr	r1, =STOCK_REST_CRC
	cmp	r0, r1
	beq	1f
	ldr	r0, =s_stock_differs
	bl	log_str
	b	.Li_finish
1:	ldr	r0, =s_stock
	bl	log_str
	bl	battery_read		@ the page 0 step must not lose power: battery first
	mov	r5, r0
	ldr	r0, =s_battery
	bl	log_str
	mov	r0, r5
	bl	log_hex
	ldr	r0, =s_crlf
	bl	log_str
	cmp	r5, #0x10000		@ 0x10000: the converter did not finish
	bhs	2f
	movw	r0, #BATTERY_MIN_RAW
	cmp	r5, r0
	bhs	3f
2:	ldr	r0, =s_battery_low
	bl	log_str
	b	.Li_finish
3:	movs	r0, #SLOT_ID_F
	bl	install_slot
	cmp	r0, #0
	bne	.Li_finish
	movs	r0, #SLOT_ID_A
	bl	install_slot
	cmp	r0, #0
	bne	.Li_finish
	mov	r0, sp			@ records: one INSTALL A, unless the newest record already is
	bl	rec_scan
	ldr	r0, [sp, #0]
	cbz	r0, 2f
	ldrb	r1, [r0, #REC_STATE_OFS]
	cmp	r1, #ST_INSTALL
	bne	2f
	ldrb	r1, [r0, #REC_SLOT_OFS]
	cmp	r1, #SLOT_ID_A
	beq	3f
2:	bl	records_fresh
	cmp	r0, #0
	bne	.Li_rec_fail
	mov	r0, sp
	bl	rec_scan
	movs	r0, #ST_INSTALL
	movs	r1, #SLOT_ID_A
	movs	r2, #1
	mov	r3, sp
	bl	rec_append
	mov	r0, sp
	bl	rec_scan
	ldr	r0, [sp, #0]
	cmp	r0, #0
	beq	.Li_rec_fail
	ldrb	r1, [r0, #REC_STATE_OFS]
	cmp	r1, #ST_INSTALL
	bne	.Li_rec_fail
	ldrb	r1, [r0, #REC_SLOT_OFS]
	cmp	r1, #SLOT_ID_A
	bne	.Li_rec_fail
3:	ldr	r0, =s_records_ok
	bl	log_str
	cmp	r10, #0
	beq	4f
	ldr	r0, =s_dry_page0	@ dry run: page 0 is not touched
	bl	log_str
	b	.Li_finish
4:	bl	page0_install		@ r0 = result 0..4
	ldr	r1, =page0_texts
	ldr	r0, [r1, r0, lsl #2]
	bl	log_str
	b	.Li_finish
.Li_rec_fail:
	ldr	r0, =s_records_fail
	bl	log_str
	b	.Li_finish

@ --- bootloader update (starter present)
.Li_update:
	ldr	r0, =s_starter
	bl	log_str
	mov	r0, sp
	bl	rec_scan
	ldr	r5, [sp, #0]		@ r5 = newest record or 0
	movs	r6, #SLOT_ID_A		@ r6 = running slot: A when there is no record
	cbz	r5, 1f
	ldrb	r0, [r5, #REC_STATE_OFS]
	ldrb	r6, [r5, #REC_SLOT_OFS]
	cmp	r0, #ST_OK
	beq	1f
	ldr	r0, =s_pending		@ INSTALL / TRIAL: the starter has not decided yet
	bl	log_str
	b	.Li_finish
1:	cmp	r6, #SLOT_ID_F
	bne	2f
	movs	r7, #SLOT_ID_A		@ running F (rolled back): the image goes to A, unless A already
	mov	r0, r7			@ holds it (that image was the one rolled back)
	bl	slot_holds_image
	cmp	r0, #0
	beq	4f
	ldr	r0, =s_rolled_back
	bl	log_str
	b	.Li_finish
2:	mov	r0, r6			@ running A or B: nothing to do when it holds its embedded image
	bl	slot_holds_image
	cmp	r0, #0
	beq	3f
	ldr	r0, =s_up_to_date
	bl	log_str
	b	.Li_finish
3:	movs	r7, #SLOT_ID_A		@ r7 = target: the other one of A / B
	cmp	r6, #SLOT_ID_A
	it	eq
	moveq	r7, #SLOT_ID_B
4:	cmp	r10, #0
	beq	5f
	ldr	r1, =slot_names		@ dry run: report the slot, write nothing
	ldr	r0, [r1, r7, lsl #2]
	bl	log_str
	ldr	r0, =s_dry_update
	bl	log_str
	b	.Li_finish
5:	mov	r0, r7
	bl	install_slot
	cmp	r0, #0
	bne	.Li_finish
	ldr	r2, [sp, #4]		@ sequence of the newest record (0 without records) + 1
	adds	r2, r2, #1
	movs	r0, #ST_INSTALL
	mov	r1, r7
	mov	r3, sp			@ scan state from above: install_slot wrote no record
	bl	rec_append
	mov	r0, sp
	bl	rec_scan
	ldr	r0, [sp, #0]
	cmp	r0, #0
	beq	.Li_rec_fail
	ldrb	r1, [r0, #REC_STATE_OFS]
	cmp	r1, #ST_INSTALL
	bne	.Li_rec_fail
	ldrb	r1, [r0, #REC_SLOT_OFS]
	cmp	r1, r7
	bne	.Li_rec_fail
	ldr	r0, =s_update_done
	bl	log_str

@ --- report
.Li_finish:
	mov	r0, r4
	ldr	r1, =s_log_file
	movs	r2, #10			@ write, create / truncate
	bl	file_open
	cbnz	r0, 1f
	mov	r0, r4
	add	r1, r11, #4
	ldr	r2, [r11]
	subs	r2, r2, r1		@ report length
	add	r3, sp, #16
	bl	file_write
	mov	r0, r4
	bl	file_close
1:	mov	r0, r11
	bl	free_units_of_32_bytes
.Li_return:
	add	sp, #24
	pop	{r3, r4, r5, r6, r7, r8, r9, r10, r11, pc}

@ ----------------------------------------------------------------------------
@ log_str - r0 = zero-terminated text; appends it to the report at r11 (stops one byte before the
@ end of the buffer).  Clobbers r0-r3.
@ ----------------------------------------------------------------------------
	.thumb_func
log_str:
	ldr	r1, [r11]		@ write pointer
	add	r2, r11, #(LOG_SIZE - 1)	@ last usable byte + 1
1:	ldrb	r3, [r0], #1
	cbz	r3, 2f
	cmp	r1, r2
	bhs	2f
	strb	r3, [r1], #1
	b	1b
2:	str	r1, [r11]
	bx	lr

@ ----------------------------------------------------------------------------
@ log_hex - r0 = value; appends it as 8 hexadecimal digits.  Clobbers r0-r3.
@ ----------------------------------------------------------------------------
	.thumb_func
log_hex:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r5, #28			@ shift of the next digit
	sub	sp, #16
1:	lsr	r0, r4, r5
	and	r0, r0, #0xF
	cmp	r0, #10
	ite	lo
	addlo	r0, r0, #0x30		@ '0'..'9'
	addhs	r0, r0, #0x37		@ 'A'..'F'
	rsb	r1, r5, #28
	lsrs	r1, r1, #2		@ digit index 0..7
	strb	r0, [sp, r1]
	subs	r5, #4
	bpl	1b
	movs	r0, #0
	strb	r0, [sp, #8]
	mov	r0, sp
	bl	log_str
	add	sp, #16
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ battery_read - one reading of the converter the application uses for its battery level, taken
@ the way the application takes it; returns the 16-bit reading, or 0x10000 when the converter does
@ not finish.  At this point of the start-up the application has not set the converter up yet
@ (its set-up, decompiled.c 32290..32340, runs after the logo open this hook replaces), so this
@ makes the same writes in the same order: 0x40021018 |= 0x200; 0x40021004 bits 15:14 = 2, bit 28
@ clear; 0x40012404 &= ~0xF0000, |= 0x100; 0x40012408 |= 2, &= ~0x800; 0x4001242C &= ~0xF00000;
@ 0x40012410 |= 0x38000000; 0x40012434 bits 4:0 = 9; 0x40012408 &= ~0x2000000, |= 0xE0000,
@ |= 0x100000, |= 0x100, |= 1, |= 8 (wait until bit 3 reads clear), |= 4 (wait until bit 2 reads
@ clear).  The reading as FUN_08009c78 (0x08009D14..0x08009D3E): 0x40012408 |= 0x400000, wait until
@ bit 1 of 0x40012400 is set, low 16 bits of 0x4001244C.  Afterwards every register it changed gets
@ its value from before back (converter registers saved after their clock is on).
@ The application turns the reading into its battery level with v = reading * 0.0017578125 and
@ the limits 4.06 .. 3.68 (FUN_08009c78): level 30 needs v > 3.74, i.e. a reading of 2128 or more
@ (BATTERY_MIN_RAW); its "battery low" dialog comes at level 5 (v <= 3.68).
@ Registers: r4 0x40021018, r5 converter base 0x40012400, r6 / r7 saved clock words, r8 reading.
@ Frame: saved 0x40012404, 0x40012408, 0x40012410, 0x4001242C, 0x40012434.
@ ----------------------------------------------------------------------------
	.thumb_func
battery_read:
	push	{r4, r5, r6, r7, r8, lr}
	sub	sp, #24
	ldr	r4, =0x40021018
	ldr	r5, =0x40012400
	ldr	r6, [r4]		@ r6 = 0x40021018 as found
	ldr	r7, [r4, #-0x14]	@ r7 = 0x40021004 as found
	orr	r0, r6, #0x200
	str	r0, [r4]
	ldr	r0, [r5, #0x04]
	str	r0, [sp, #0]
	ldr	r0, [r5, #0x08]
	str	r0, [sp, #4]
	ldr	r0, [r5, #0x10]
	str	r0, [sp, #8]
	ldr	r0, [r5, #0x2C]
	str	r0, [sp, #12]
	ldr	r0, [r5, #0x34]
	str	r0, [sp, #16]
	ldr	r0, [r4, #-0x14]
	bic	r0, r0, #0xC000
	orr	r0, r0, #0x8000
	str	r0, [r4, #-0x14]
	ldr	r0, [r4, #-0x14]
	bic	r0, r0, #0x10000000
	str	r0, [r4, #-0x14]
	ldr	r0, [r5, #0x04]
	bic	r0, r0, #0xF0000
	str	r0, [r5, #0x04]
	ldr	r0, [r5, #0x04]
	orr	r0, r0, #0x100
	str	r0, [r5, #0x04]
	ldr	r0, [r5, #0x08]
	orr	r0, r0, #2
	str	r0, [r5, #0x08]
	ldr	r0, [r5, #0x08]
	bic	r0, r0, #0x800
	str	r0, [r5, #0x08]
	ldr	r0, [r5, #0x2C]
	bic	r0, r0, #0xF00000
	str	r0, [r5, #0x2C]
	ldr	r0, [r5, #0x10]
	orr	r0, r0, #0x38000000
	str	r0, [r5, #0x10]
	ldr	r0, [r5, #0x34]
	bic	r0, r0, #0x1F
	orr	r0, r0, #9
	str	r0, [r5, #0x34]
	ldr	r0, [r5, #0x08]
	bic	r0, r0, #0x2000000
	str	r0, [r5, #0x08]
	ldr	r0, [r5, #0x08]
	orr	r0, r0, #0xE0000
	str	r0, [r5, #0x08]
	ldr	r0, [r5, #0x08]
	orr	r0, r0, #0x100000
	str	r0, [r5, #0x08]
	ldr	r0, [r5, #0x08]
	orr	r0, r0, #0x100
	str	r0, [r5, #0x08]
	ldr	r0, [r5, #0x08]
	orr	r0, r0, #1
	str	r0, [r5, #0x08]
	ldr	r0, [r5, #0x08]
	orr	r0, r0, #8
	str	r0, [r5, #0x08]
	mov	r1, #0x100000		@ poll limit
1:	ldr	r0, [r5, #0x08]
	tst	r0, #8
	beq	2f
	subs	r1, #1
	bne	1b
	b	.Lbat_timeout
2:	ldr	r0, [r5, #0x08]
	orr	r0, r0, #4
	str	r0, [r5, #0x08]
	mov	r1, #0x100000
3:	ldr	r0, [r5, #0x08]
	tst	r0, #4
	beq	4f
	subs	r1, #1
	bne	3b
	b	.Lbat_timeout
4:	ldr	r0, [r5, #0x08]
	orr	r0, r0, #0x400000
	str	r0, [r5, #0x08]
	mov	r1, #0x100000
5:	ldr	r0, [r5, #0x00]
	tst	r0, #2
	bne	6f
	subs	r1, #1
	bne	5b
	b	.Lbat_timeout
6:	ldr	r0, [r5, #0x4C]
	uxth	r8, r0
	b	.Lbat_restore
.Lbat_timeout:
	mov	r8, #0x10000
.Lbat_restore:
	ldr	r0, [sp, #4]		@ 0x40012408 first: the converter stops with its old value
	str	r0, [r5, #0x08]
	ldr	r0, [sp, #0]
	str	r0, [r5, #0x04]
	ldr	r0, [sp, #8]
	str	r0, [r5, #0x10]
	ldr	r0, [sp, #12]
	str	r0, [r5, #0x2C]
	ldr	r0, [sp, #16]
	str	r0, [r5, #0x34]
	ldr	r0, [r4, #-0x14]	@ 0x40021004: bits 15:14 and 28 as found
	bic	r0, r0, #0xC000
	bic	r0, r0, #0x10000000
	and	r1, r7, #0xC000
	orr	r0, r0, r1
	and	r1, r7, #0x10000000
	orr	r0, r0, r1
	str	r0, [r4, #-0x14]
	str	r6, [r4]		@ 0x40021018 as found
	mov	r0, r8
	add	sp, #24
	pop	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ iwdg_feed - reloads the independent watchdog (0xAAAA to 0x40003000; no effect on a watchdog
@ that was never started).  Clobbers r0, r1.
@ ----------------------------------------------------------------------------
	.thumb_func
iwdg_feed:
	ldr	r1, =IWDG_KR
	movw	r0, #0xAAAA
	str	r0, [r1]
	bx	lr

@ ----------------------------------------------------------------------------
@ mem_equal - r0, r1 = word-aligned addresses, r2 = byte count (multiple of 4); returns 1 when the
@ two areas are equal, else 0.  Clobbers r0-r3, r12.
@ ----------------------------------------------------------------------------
	.thumb_func
mem_equal:
1:	cbz	r2, 2f
	ldr	r3, [r0], #4
	ldr	r12, [r1], #4
	cmp	r3, r12
	bne	3f
	subs	r2, #4
	b	1b
2:	movs	r0, #1
	bx	lr
3:	movs	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ mem_erased - r0 = word-aligned address, r1 = byte count (multiple of 4); returns 1 when every
@ word reads 0xFFFFFFFF, else 0.  Clobbers r0-r2.
@ ----------------------------------------------------------------------------
	.thumb_func
mem_erased:
1:	cbz	r1, 2f
	ldr	r2, [r0], #4
	adds	r2, #1
	bne	3f
	subs	r1, #4
	b	1b
2:	movs	r0, #1
	bx	lr
3:	movs	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ page0_is_starter - returns 1 when page 0 holds the embedded starter and the rest of the page is
@ erased, else 0.
@ ----------------------------------------------------------------------------
	.thumb_func
page0_is_starter:
	push	{r4, lr}
	ldr	r0, =0x08000000
	ldr	r1, =img_starter
	ldr	r2, =STARTER_LEN
	bl	mem_equal
	cbz	r0, 1f
	ldr	r0, =STARTER_END_ADDR
	ldr	r1, =STARTER_PAD_LEN
	bl	mem_erased
1:	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ slot_info - r0 = slot id; returns r0 = slot base, r1 = embedded image, r2 = image length, or
@ r0 = 0 for an unknown id.
@ ----------------------------------------------------------------------------
	.thumb_func
slot_info:
	cmp	r0, #SLOT_ID_F
	beq	1f
	cmp	r0, #SLOT_ID_A
	beq	2f
	cmp	r0, #SLOT_ID_B
	beq	3f
	movs	r0, #0
	bx	lr
1:	ldr	r0, =SLOT_F_BASE
	ldr	r1, =img_f
	ldr	r2, =IMG_F_LEN
	bx	lr
2:	ldr	r0, =SLOT_A_BASE
	ldr	r1, =img_a
	ldr	r2, =IMG_A_LEN
	bx	lr
3:	ldr	r0, =SLOT_B_BASE
	ldr	r1, =img_b
	ldr	r2, =IMG_B_LEN
	bx	lr

@ ----------------------------------------------------------------------------
@ build_header - r0 = 28-byte buffer, r1 = slot base, r2 = image, r3 = image length; writes the slot
@ header (layout.inc): magic, format, link address = slot base, length, CRC-32 of the image,
@ SLOT_IMAGE_VERSION, CRC-32 of the first 24 bytes.
@ ----------------------------------------------------------------------------
	.thumb_func
build_header:
	push	{r4, lr}
	mov	r4, r0
	str	r1, [r4, #HDR_LINK]
	str	r3, [r4, #HDR_LENGTH]
	ldr	r0, =SLOT_MAGIC
	str	r0, [r4, #HDR_MAGIC]
	movs	r0, #SLOT_FORMAT
	str	r0, [r4, #HDR_FORMAT]
	movs	r0, #SLOT_IMAGE_VERSION
	str	r0, [r4, #HDR_VERSION]
	mov	r0, r2
	mov	r1, r3
	bl	crc32
	str	r0, [r4, #HDR_IMAGE_CRC]
	mov	r0, r4
	movs	r1, #HDR_CRC
	bl	crc32
	str	r0, [r4, #HDR_CRC]
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ slot_holds_image - r0 = slot id; returns 1 when the slot holds exactly the header build_header
@ makes for its embedded image and the image itself, else 0.
@ ----------------------------------------------------------------------------
	.thumb_func
slot_holds_image:
	push	{r4, r5, r6, lr}
	sub	sp, #32
	bl	slot_info
	cbz	r0, 9f
	mov	r4, r0
	mov	r5, r1
	mov	r6, r2
	mov	r0, sp
	mov	r1, r4
	mov	r2, r5
	mov	r3, r6
	bl	build_header
	mov	r0, r4
	mov	r1, sp
	movs	r2, #28
	bl	mem_equal
	cbz	r0, 9f
	add	r0, r4, #SLOT_IMAGE_OFS
	mov	r1, r5
	mov	r2, r6
	bl	mem_equal
9:	add	sp, #32
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ install_slot - r0 = slot id; reports "slot X: ..." and writes the embedded image into the slot
@ unless it already holds it.  Returns 0 when the slot holds the image afterwards, else the
@ write_slot error (1 erase, 2 image, 3 header).
@ ----------------------------------------------------------------------------
	.thumb_func
install_slot:
	push	{r4, lr}
	mov	r4, r0
	ldr	r1, =slot_names
	ldr	r0, [r1, r4, lsl #2]
	bl	log_str
	mov	r0, r4
	bl	slot_holds_image
	cbz	r0, 1f
	ldr	r0, =s_slot_same
	bl	log_str
	movs	r0, #0
	pop	{r4, pc}
1:	mov	r0, r4
	bl	write_slot
	mov	r4, r0
	ldr	r1, =slot_results
	ldr	r0, [r1, r4, lsl #2]
	bl	log_str
	mov	r0, r4
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ write_slot - r0 = slot id (F, A or B: any other id writes nothing and returns 1).  Erases the 16
@ pages of the slot and checks they read erased (else 1), programs the embedded image at slot +
@ 0x200 and compares it (else 2), then programs the header and compares it (else 3); returns 0.
@ Flash locked again on every return.
@ Registers: r4 slot base, r5 image, r6 length, r7 / r8 work.  Frame: 32-byte header buffer.
@ ----------------------------------------------------------------------------
	.thumb_func
write_slot:
	push	{r4, r5, r6, r7, r8, lr}
	sub	sp, #32
	bl	slot_info
	cmp	r0, #0
	beq	.Lws_bad_id
	mov	r4, r0
	mov	r5, r1
	mov	r6, r2
	bl	flash_unlock2
	mov	r7, r4			@ r7 = page
	add	r8, r4, #SLOT_SIZE	@ r8 = end of the slot
1:	bl	iwdg_feed
	mov	r0, r7
	bl	flash_erase_page2
	add	r7, r7, #REC_PAGE_SIZE	@ 2 KB pages
	cmp	r7, r8
	blo	1b
	mov	r0, r4
	mov	r1, #SLOT_SIZE
	bl	mem_erased
	cbz	r0, .Lws_erase_fail
	movs	r7, #0			@ r7 = byte offset in the image
2:	cmp	r7, r6
	bhs	3f
	tst	r7, #0x1FC		@ every 128 words
	bne	4f
	bl	iwdg_feed
4:	add	r0, r4, #SLOT_IMAGE_OFS
	add	r0, r0, r7
	ldr	r1, [r5, r7]
	bl	flash_program_word2
	adds	r7, #4
	b	2b
3:	add	r0, r4, #SLOT_IMAGE_OFS
	mov	r1, r5
	mov	r2, r6
	bl	mem_equal
	cbz	r0, .Lws_image_fail
	mov	r0, sp
	mov	r1, r4
	mov	r2, r5
	mov	r3, r6
	bl	build_header
	movs	r7, #0
5:	add	r0, r4, r7		@ header words, the mark of a valid slot, last
	ldr	r1, [sp, r7]
	bl	flash_program_word2
	adds	r7, #4
	cmp	r7, #28
	blo	5b
	mov	r0, r4
	mov	r1, sp
	movs	r2, #28
	bl	mem_equal
	cbz	r0, .Lws_header_fail
	bl	flash_lock2
	movs	r0, #0
	b	.Lws_out
.Lws_erase_fail:
	bl	flash_lock2
	movs	r0, #1
	b	.Lws_out
.Lws_image_fail:
	bl	flash_lock2
	movs	r0, #2
	b	.Lws_out
.Lws_header_fail:
	bl	flash_lock2
	movs	r0, #3
	b	.Lws_out
.Lws_bad_id:
	movs	r0, #1
.Lws_out:
	add	sp, #32
	pop	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ records_fresh - erases both record pages and checks they read erased; returns 0, else 1.
@ ----------------------------------------------------------------------------
	.thumb_func
records_fresh:
	push	{r4, lr}
	bl	flash_unlock2
	bl	iwdg_feed
	ldr	r0, =REC_PAGE0
	bl	flash_erase_page2
	bl	iwdg_feed
	ldr	r0, =REC_PAGE1
	bl	flash_erase_page2
	bl	flash_lock2
	ldr	r0, =REC_PAGE0
	mov	r1, #(2 * REC_PAGE_SIZE)
	bl	mem_erased
	eor	r0, r0, #1		@ 1 erased -> 0
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ page0_install - copies p0_code, the starter and the stock page 0 into one heap block (RAM) and
@ runs p0_code there.  Returns its result 0..3, or 4 when there is no memory (page 0 not touched).
@ ----------------------------------------------------------------------------
	.thumb_func
page0_install:
	push	{r4, r5, r6, r7, r8, lr}
	ldr	r0, =(P0_CODE_SIZE + 0x800 + 0x800)
	bl	alloc_units_of_32_bytes
	cbz	r0, 9f
	mov	r4, r0			@ r4 = code copy (32-byte aligned)
	ldr	r1, =p0_code
	ldr	r2, =P0_CODE_SIZE
	bl	copy_words
	ldr	r5, =P0_CODE_SIZE
	add	r5, r5, r4		@ r5 = starter copy
	mov	r0, r5
	ldr	r1, =img_starter
	ldr	r2, =STARTER_LEN
	bl	copy_words
	add	r6, r5, #0x800		@ r6 = stock page 0 copy
	mov	r0, r6
	ldr	r1, =img_stock_page0
	mov	r2, #0x800
	bl	copy_words
	dsb
	isb
	mov	r0, r5
	ldr	r1, =STARTER_WORDS
	mov	r2, r6
	orr	r3, r4, #1		@ Thumb entry
	blx	r3
	mov	r7, r0
	mov	r0, r4
	bl	free_units_of_32_bytes
	mov	r0, r7
	pop	{r4, r5, r6, r7, r8, pc}
9:	movs	r0, #4
	pop	{r4, r5, r6, r7, r8, pc}

@ copy_words - r0 = destination, r1 = source, r2 = byte count (multiple of 4).  Clobbers r0-r3.
	.thumb_func
copy_words:
1:	cbz	r2, 2f
	ldr	r3, [r1], #4
	str	r3, [r0], #4
	subs	r2, #4
	b	1b
2:	bx	lr

@ ----------------------------------------------------------------------------
@ p0_code - runs from RAM (copied by page0_install; position independent: only PC-relative branches
@ inside it, registers built with movw / movt, no literal pool).  r0 = starter words (RAM), r1 =
@ starter word count, r2 = stock page 0 (RAM, 512 words).  Interrupts off for the whole run, the
@ watchdog fed at the start, before every erase and every 128 words.  Flash bank 1 controller
@ 0x40022000 (keys +4, status +0xC: bit 0 busy, bit 2 program error, bit 4 write-protection
@ error, bit 5 end of operation; control +0x10: bit 0 PG, bit 1 PER, bit 6 STRT, bit 7 LOCK;
@ address +0x14), used as the stock bootloader uses it (0x08002170, 0x080023C4).
@ Returns 0: page 0 erased, starter programmed and compared.
@         1: the erase was refused (error flags) and page 0 still holds the stock page: unchanged.
@         2: the starter could not be written; the stock page 0 is back (programmed and compared).
@         3: neither: page 0 is not usable (three restore attempts failed).
@ ----------------------------------------------------------------------------
	.p2align 2
p0_code:
	push	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r4, r0			@ r4 = starter words
	mov	r5, r1			@ r5 = starter word count
	mov	r6, r2			@ r6 = stock page words
	cpsid	i
	movw	r7, #0x2000
	movt	r7, #0x4002		@ r7 = flash controller, bank 1
	movw	r8, #0x3000
	movt	r8, #0x4000		@ r8 = watchdog key register
	bl	.Lp0_feed
	movw	r0, #0x0123
	movt	r0, #0x4567
	str	r0, [r7, #4]
	movw	r0, #0x89AB
	movt	r0, #0xCDEF
	str	r0, [r7, #4]
	bl	.Lp0_erase
	cbz	r0, 1f
	mov	r0, r6			@ error flags: is page 0 still the stock page?
	mov	r1, #512
	bl	.Lp0_cmp
	cmp	r0, #0
	bne	.Lp0_restore
	movs	r0, #1
	b	.Lp0_out
1:	bl	.Lp0_blank
	cmp	r0, #0
	bne	.Lp0_restore
	mov	r0, r4
	mov	r1, r5
	bl	.Lp0_prog
	cmp	r0, #0
	bne	.Lp0_restore
	mov	r0, r4
	mov	r1, r5
	bl	.Lp0_cmp
	cmp	r0, #0
	bne	.Lp0_restore
	movs	r0, #0
	b	.Lp0_out
.Lp0_restore:
	movs	r9, #3			@ r9 = attempts left
2:	bl	.Lp0_feed
	bl	.Lp0_erase
	mov	r0, r6
	mov	r1, #512
	bl	.Lp0_prog
	mov	r0, r6
	mov	r1, #512
	bl	.Lp0_cmp
	cbz	r0, 3f
	subs	r9, r9, #1
	bne	2b
	movs	r0, #3
	b	.Lp0_out
3:	movs	r0, #2
.Lp0_out:
	mov	r10, r0
	ldr	r1, [r7, #0x10]
	orr	r1, r1, #0x80		@ LOCK
	str	r1, [r7, #0x10]
	bl	.Lp0_feed
	cpsie	i
	mov	r0, r10
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}

@ .Lp0_feed - watchdog reload.  Clobbers r0.
.Lp0_feed:
	movw	r0, #0xAAAA
	str	r0, [r8]
	bx	lr

@ .Lp0_wait - waits while the busy bit is set, at most 0x02000000 polls.  Clobbers r0, r1.
.Lp0_wait:
	mov	r1, #0x02000000
1:	ldr	r0, [r7, #0x0C]
	tst	r0, #1
	beq	2f
	subs	r1, #1
	bne	1b
2:	bx	lr

@ .Lp0_erase - erases the page at 0x08000000; returns the error flags (status bits 2 and 4).
@ Clobbers r0, r1.
.Lp0_erase:
	push	{r3, lr}
	bl	.Lp0_feed
	bl	.Lp0_wait
	movs	r0, #0x34		@ clear program error, write-protection error, end of operation
	str	r0, [r7, #0x0C]
	ldr	r0, [r7, #0x10]
	orr	r0, r0, #0x02		@ PER
	str	r0, [r7, #0x10]
	mov	r0, #0x08000000
	str	r0, [r7, #0x14]
	ldr	r0, [r7, #0x10]
	orr	r0, r0, #0x40		@ STRT
	str	r0, [r7, #0x10]
	bl	.Lp0_wait
	ldr	r0, [r7, #0x10]
	bic	r0, r0, #0x02
	str	r0, [r7, #0x10]
	ldr	r0, [r7, #0x0C]
	and	r0, r0, #0x14
	pop	{r3, pc}

@ .Lp0_blank - returns 0 when 0x08000000..0x080007FF reads all 0xFFFFFFFF, else 1.  Clobbers r0-r2.
.Lp0_blank:
	mov	r0, #0x08000000
	add	r1, r0, #0x800
1:	ldr	r2, [r0], #4
	adds	r2, #1
	bne	2f
	cmp	r0, r1
	blo	1b
	movs	r0, #0
	bx	lr
2:	movs	r0, #1
	bx	lr

@ .Lp0_prog - r0 = source words, r1 = word count; programs them from 0x08000000.  Returns 0, or the
@ error flags (status bits 2, 4) of the first word that failed.  Clobbers r0-r3.
.Lp0_prog:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	mov	r6, #0x08000000
1:	cbz	r5, 3f
	tst	r5, #0x7F
	bne	2f
	bl	.Lp0_feed
2:	bl	.Lp0_wait
	ldr	r0, [r7, #0x10]
	orr	r0, r0, #0x01		@ PG
	str	r0, [r7, #0x10]
	ldr	r0, [r4], #4
	str	r0, [r6], #4
	bl	.Lp0_wait
	ldr	r0, [r7, #0x10]
	bic	r0, r0, #0x01
	str	r0, [r7, #0x10]
	ldr	r0, [r7, #0x0C]
	ands	r0, r0, #0x14
	bne	4f
	subs	r5, #1
	b	1b
3:	movs	r0, #0
4:	pop	{r4, r5, r6, pc}

@ .Lp0_cmp - r0 = source words, r1 = word count; returns 0 when 0x08000000.. holds them, else 1.
@ Clobbers r0-r3, r12.
.Lp0_cmp:
	mov	r2, #0x08000000
1:	cbz	r1, 2f
	ldr	r3, [r0], #4
	ldr	r12, [r2], #4
	cmp	r3, r12
	bne	3f
	subs	r1, #1
	b	1b
2:	movs	r0, #0
	bx	lr
3:	movs	r0, #1
	bx	lr
	.p2align 2
p0_end:
	.equ	P0_CODE_SIZE, p0_end - p0_code

	.include "common/records.inc"

	.ltorg

@ ----------------------------------------------------------------------------
@ Texts of the report and the trigger / report file names.
@ ----------------------------------------------------------------------------
	.p2align 2
page0_texts:
	.word	s_p0_ok, s_p0_refused, s_p0_restored, s_p0_broken, s_p0_nomem
slot_names:
	.word	s_slot_f, s_slot_a, s_slot_b
slot_results:
	.word	s_slot_written, s_slot_erase_fail, s_slot_image_fail, s_slot_header_fail
s_dump_trigger:		.asciz	"2:/BOOTDUMP.TXT"
s_install_trigger:	.asciz	"2:/BOOTINST.TXT"
s_test_trigger:		.asciz	"2:/BOOTTEST.TXT"
s_dry_title:		.asciz	"dry run (BOOTTEST.TXT): page 0 is not written\r\n"
s_dry_page0:		.asciz	"dry run: page 0 not touched; BOOTINST.TXT (and no BOOTTEST.TXT) does the real install\r\n"
s_dry_update:		.asciz	"would get the embedded image and an INSTALL record (dry run: nothing written)\r\n"
s_log_file:		.asciz	"2:/BOOTINST.LOG"
s_title:		.asciz	"FNIRSI 2C53T two-part bootloader installer\r\n"
s_flash_size:		.asciz	"flash size is not 1024 KB: nothing written\r\n"
s_page0_unknown:	.asciz	"page 0 holds neither the stock bootloader nor the starter: nothing written\r\n"
s_stock_differs:	.asciz	"stock bootloader 0x08000800..0x08005873 has another CRC-32: nothing written\r\n"
s_stock:		.asciz	"page 0: stock bootloader: first install\r\n"
s_battery:		.asciz	"battery reading: 0x"
s_crlf:			.asciz	"\r\n"
s_battery_low:		.asciz	"battery reading below 0x00000850 (the application's level 30) or no reading: charge, nothing written\r\n"
s_starter:		.asciz	"page 0: starter: bootloader update\r\n"
s_pending:		.asciz	"newest record is INSTALL or TRIAL: restart the meter first; nothing written\r\n"
s_rolled_back:		.asciz	"running slot F after a roll-back; slot A already holds this image: nothing written\r\n"
s_up_to_date:		.asciz	"running slot holds this bootloader: nothing written\r\n"
s_update_done:		.asciz	"INSTALL record written: the new bootloader is tried at the next start\r\n"
s_records_ok:		.asciz	"records: INSTALL A\r\n"
s_records_fail:		.asciz	"records: FAILED, page 0 not touched\r\n"
s_slot_f:		.asciz	"slot F: "
s_slot_a:		.asciz	"slot A: "
s_slot_b:		.asciz	"slot B: "
s_slot_same:		.asciz	"holds this image already\r\n"
s_slot_written:		.asciz	"written and compared\r\n"
s_slot_erase_fail:	.asciz	"FAILED (erase), nothing else written\r\n"
s_slot_image_fail:	.asciz	"FAILED (image compare), nothing else written\r\n"
s_slot_header_fail:	.asciz	"FAILED (header compare), nothing else written\r\n"
s_p0_ok:		.asciz	"page 0: starter written and compared: the new chain runs from the next start\r\n"
s_p0_refused:		.asciz	"page 0: erase refused by the flash controller: stock bootloader unchanged\r\n"
s_p0_restored:		.asciz	"page 0: starter not written, stock page 0 written back and compared\r\n"
s_p0_broken:		.asciz	"page 0: FAILED, neither starter nor stock page: keep the meter powered, report this\r\n"
s_p0_nomem:		.asciz	"page 0: no memory for the RAM routine: not touched\r\n"

@ ----------------------------------------------------------------------------
@ Embedded images (make builds them first): the starter, the slot builds of the bootloader for F, A
@ and B, and the stock page 0 (the first 2 KB of the stock bootloader, rebuilt from source and equal
@ to the meter's dump: bootloader make check).
@ ----------------------------------------------------------------------------
	.section .rodata.boot_install,"a",%progbits
	.p2align 2
img_starter:
	.incbin	"starter/build/STARTER.bin"
img_starter_end:
	.p2align 2
img_f:
	.incbin	"bootloader/build/slot/BOOT_F.bin"
img_f_end:
	.p2align 2
img_a:
	.incbin	"bootloader/build/slot/BOOT_A.bin"
img_a_end:
	.p2align 2
img_b:
	.incbin	"bootloader/build/slot/BOOT_B.bin"
img_b_end:
	.p2align 2
img_stock_page0:
	.incbin	"bootloader/build/BOOT.bin", 0, 0x800
img_stock_page0_end:

	.equ	STARTER_LEN,	img_starter_end - img_starter
	.equ	STARTER_WORDS,	STARTER_LEN / 4
	.equ	STARTER_END_ADDR, 0x08000000 + STARTER_LEN	@ first byte of page 0 after the starter
	.equ	STARTER_PAD_LEN, 0x800 - STARTER_LEN		@ rest of page 0, erased
	.equ	IMG_F_LEN,	img_f_end - img_f
	.equ	IMG_A_LEN,	img_a_end - img_a
	.equ	IMG_B_LEN,	img_b_end - img_b

	.if	(img_starter_end - img_starter) & 3 || (img_starter_end - img_starter) > 0x800
	.error	"starter image: length must be a multiple of 4 and at most 2048"
	.endif
	.if	(img_f_end - img_f) & 3 || (img_f_end - img_f) > (SLOT_SIZE - SLOT_IMAGE_OFS)
	.error	"slot F image: length must be a multiple of 4 and fit the slot"
	.endif
	.if	(img_a_end - img_a) & 3 || (img_a_end - img_a) > (SLOT_SIZE - SLOT_IMAGE_OFS)
	.error	"slot A image: length must be a multiple of 4 and fit the slot"
	.endif
	.if	(img_b_end - img_b) & 3 || (img_b_end - img_b) > (SLOT_SIZE - SLOT_IMAGE_OFS)
	.error	"slot B image: length must be a multiple of 4 and fit the slot"
	.endif
	.if	(img_stock_page0_end - img_stock_page0) != 0x800
	.error	"stock page 0: must be 2048 bytes"
	.endif

	.endif
