@ swd_loader.s - RAM program run through the SWD probe on the blank (unprotected, mass-erased) chip:
@ erases every 2 KB page the blocks cover (all erases first: two blocks may share a page, e.g. the
@ slot F header and image; a retry after a failed run starts from erased pages), then programs the
@ blocks from RAM into flash bank 1 or bank 2, programs the EOPB0 option halfword,
@ compares everything, writes a result code and stops at a breakpoint.  Hand-written Thumb-2.
@
@ Memory (all loaded by the OpenOCD script with load_image before the run):
@   0x20000000  this program (entry loader_start, Thumb)
@   0x20000800  result block: [0] result code, [4] failing address, [8] blocks done
@   0x20000810  block table: {flash address, RAM source, byte count} * n, ended by flash address 0
@   0x20001000.. block data (word aligned, byte counts multiples of 4)
@ Flash controller (RM_AT32F403A_407 5.7, as the stock bootloader uses it): bank 1 0x40022000, bank 2
@ +0x40: keys +4, status +0xC (bit 0 busy, bit 2 program error, bit 4 erase/program protection
@ error, bit 5 done), control +0x10 (bit 0 PG, bit 4 USDPRGM, bit 7 LOCK, bit 9 USDULKS), option
@ keys at 0x40022008 (bank 1 only).
@ Result codes: 0 ok; 1 program error flags (address in [4]); 2 compare mismatch (address in [4]);
@ 3 option halfword: unlock timeout; 4 option halfword compare mismatch; 5 erase error flags
@ (page address in [4]).

	.syntax unified
	.arch armv7e-m
	.thumb

	.equ	RESULT,		0x20000800
	.equ	TABLE,		0x20000810
	.equ	FLASH1,		0x40022000
	.equ	KEY1,		0x45670123
	.equ	KEY2,		0xCDEF89AB
	.equ	EOPB0_ADDR,	0x1FFFF810
	.equ	EOPB0_VALUE,	0x01FE		@ 224 KB SRAM: data FE with its inverse 01, as the meter read
						@ before (SYSINFO: FE 01) and as OpenOCD's artery driver writes
						@ option bytes (artery_usd_write_buffer: data, ~data)

	.text
	.global	loader_start
	.thumb_func
loader_start:
	cpsid	i
	ldr	sp, =0x20000800		@ stack below the result block
	ldr	r0, =FLASH1		@ unlock both banks
	ldr	r1, =KEY1
	ldr	r2, =KEY2
	str	r1, [r0, #0x04]
	str	r2, [r0, #0x04]
	str	r1, [r0, #0x44]
	str	r2, [r0, #0x44]
	ldr	r4, =TABLE		@ erase pass: every page from (address & ~0x7FF) to the block end
.Lerase_block:
	ldr	r5, [r4, #0]
	cbz	r5, .Lerase_done
	ldr	r7, [r4, #8]
	add	r7, r7, r5		@ r7 = block end
	lsrs	r5, r5, #11		@ r5 = first page
	lsls	r5, r5, #11
	ldr	r8, =FLASH1
	ldr	r0, =0x08080000
	cmp	r5, r0
	it	hs
	addhs	r8, r8, #0x40
.Lerase_page:
	cmp	r5, r7
	bhs	.Lerase_next
	bl	wait_busy
	movs	r0, #0x34
	str	r0, [r8, #0x0C]
	ldr	r0, [r8, #0x10]
	orr	r0, r0, #0x02		@ SECERS (page erase)
	str	r0, [r8, #0x10]
	str	r5, [r8, #0x14]		@ page address
	ldr	r0, [r8, #0x10]
	orr	r0, r0, #0x40		@ ERSTR (start)
	str	r0, [r8, #0x10]
	bl	wait_busy
	ldr	r0, [r8, #0x10]
	bic	r0, r0, #0x02
	str	r0, [r8, #0x10]
	ldr	r0, [r8, #0x0C]
	tst	r0, #0x14
	bne	.Lerase_error
	add	r5, r5, #0x800
	b	.Lerase_page
.Lerase_next:
	adds	r4, #12
	b	.Lerase_block
.Lerase_done:
	ldr	r4, =TABLE		@ r4 = table entry
	movs	r9, #0			@ r9 = blocks done
.Lnext_block:
	ldr	r5, [r4, #0]		@ r5 = flash address
	cbz	r5, .Lblocks_done
	ldr	r6, [r4, #4]		@ r6 = source
	ldr	r7, [r4, #8]		@ r7 = byte count
	ldr	r8, =FLASH1		@ r8 = controller of this block: bank 2 from 0x08080000
	ldr	r0, =0x08080000
	cmp	r5, r0
	it	hs
	addhs	r8, r8, #0x40
.Lword:
	cbz	r7, .Lcompare
	bl	wait_busy
	movs	r0, #0x34		@ clear error and done flags
	str	r0, [r8, #0x0C]
	ldr	r0, [r8, #0x10]
	orr	r0, r0, #0x01		@ PG
	str	r0, [r8, #0x10]
	ldr	r0, [r6], #4
	str	r0, [r5], #4
	bl	wait_busy
	ldr	r0, [r8, #0x10]
	bic	r0, r0, #0x01
	str	r0, [r8, #0x10]
	ldr	r0, [r8, #0x0C]
	tst	r0, #0x14
	bne	.Lprog_error
	subs	r7, #4
	b	.Lword
.Lcompare:
	ldr	r5, [r4, #0]		@ compare the whole block
	ldr	r6, [r4, #4]
	ldr	r7, [r4, #8]
1:	cbz	r7, 2f
	ldr	r0, [r5], #4
	ldr	r1, [r6], #4
	cmp	r0, r1
	bne	.Lcompare_error
	subs	r7, #4
	b	1b
2:	adds	r9, #1
	adds	r4, #12
	b	.Lnext_block

.Lblocks_done:
	@ EOPB0: option keys, wait for USDULKS (control bit 9), USDPRGM, halfword, wait, clear USDPRGM
	@ (sequence of the stock bootloader's 0x0800235C; value with its inverse byte)
	ldr	r8, =FLASH1
	ldr	r1, =KEY1
	ldr	r2, =KEY2
	str	r1, [r8, #0x08]
	str	r2, [r8, #0x08]
	ldr	r3, =0x00100000		@ poll limit
3:	ldr	r0, [r8, #0x10]
	tst	r0, #0x200
	bne	4f
	subs	r3, #1
	bne	3b
	movs	r0, #3
	ldr	r5, =EOPB0_ADDR
	b	.Lfinish
4:	bl	wait_busy
	movs	r0, #0x34
	str	r0, [r8, #0x0C]
	ldr	r0, [r8, #0x10]
	orr	r0, r0, #0x10		@ USDPRGM
	str	r0, [r8, #0x10]
	ldr	r5, =EOPB0_ADDR
	movw	r0, #EOPB0_VALUE
	strh	r0, [r5]
	bl	wait_busy
	ldr	r0, [r8, #0x10]
	bic	r0, r0, #0x10
	str	r0, [r8, #0x10]
	ldrh	r0, [r5]		@ option area reads FE 01: halfword 0x01FE
	movw	r1, #0x01FE
	cmp	r0, r1
	beq	5f
	movs	r0, #4
	b	.Lfinish
5:	movs	r0, #0
	movs	r5, #0
	b	.Lfinish

.Lerase_error:
	movs	r0, #5
	movs	r9, #0
	b	.Lfinish
.Lprog_error:
	sub	r5, r5, #4		@ address of the failing word
	movs	r0, #1
	b	.Lfinish
.Lcompare_error:
	sub	r5, r5, #4
	movs	r0, #2
.Lfinish:
	ldr	r1, =RESULT
	str	r0, [r1, #0]
	str	r5, [r1, #4]
	str	r9, [r1, #8]
	ldr	r0, =FLASH1		@ lock both banks
	ldr	r1, [r0, #0x10]
	orr	r1, r1, #0x80
	str	r1, [r0, #0x10]
	ldr	r1, [r0, #0x50]
	orr	r1, r1, #0x80
	str	r1, [r0, #0x50]
	bkpt	#0
	b	.

@ wait_busy - r8 = controller; waits while status bit 0 is set (at most 0x00400000 polls).
@ Clobbers r0, r3.
	.thumb_func
wait_busy:
	ldr	r3, =0x00400000
1:	ldr	r0, [r8, #0x0C]
	tst	r0, #1
	beq	2f
	subs	r3, #1
	bne	1b
2:	bx	lr

	.ltorg
