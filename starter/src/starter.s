@ starter.s - the first stage of the two-part bootloader: page 0 (0x08000000..0x080007FF), written
@ once by the installer and never updated.  It chooses a bootloader slot and starts it; nothing else.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
@
@ At every reset:
@  1. Fault flag (FAULT_FLAG at FAULT_FLAG_ADDR, set by starter_fault before it resets the core):
@     clear it and start slot F (factory) without reading the records.
@  2. Update key held (the PE2 / PE3 key the stock bootloader tests): start slot F.  F is written
@     once and never erased, so the key always reaches a known update mode.
@  3. Otherwise read both record pages and take the valid record with the highest sequence number:
@     none -> slot A; OK -> its slot; INSTALL -> its slot, append TRIAL; TRIAL (that slot was started
@     once and never confirmed) -> the slot of the newest OK record of another slot (else F), append
@     OK for it (the rollback is recorded, so the failed slot is not tried again).
@  4. The chosen slot's header must be valid (magic, format, link address = slot base, length inside
@     the slot, header CRC-32, stack pointer in RAM, reset vector odd and inside the image); else F;
@     if F is not valid either, wait forever (the update path is gone: only a debug probe helps).
@  5. Start the slot: VTOR = slot + 0x200, MSP and PC from its vector table.  Flash is locked again
@     after any record write; no clock, pin or register is left changed (the key test restores port E
@     and its clock as found).
@ Timing: no full-image CRC at start (as on the 121GW): only the header (24 bytes) and the records
@ are checked, so the start is not slower than the stock bootloader's by more than microseconds.
@ The full image CRC is checked by whoever writes a slot, before its header (the mark) is written.

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb
	.include "src/layout.inc"

@ ----------------------------------------------------------------------------
@ Vector table at 0x08000000: initial SP as the stock bootloader (0x20001A08), reset, and every other
@ entry the fault handler (also used by the application between its two VTOR writes, 0x0802AA46 and
@ 0x0803A506: an exception there now records a fault and restarts through slot F).
@ ----------------------------------------------------------------------------
	.section .vectors,"a",%progbits
	.global	vectors
vectors:
	.word	0x20001A08
	.word	starter_reset
	.rept	95
	.word	starter_fault
	.endr

	.section .text.starter,"ax",%progbits
	.p2align 2

@ ----------------------------------------------------------------------------
@ starter_fault - any exception: set the fault flag, request a system reset, wait.
@ ----------------------------------------------------------------------------
	.global	starter_fault
	.thumb_func
	.type	starter_fault, %function
starter_fault:
	ldr	r0, =FAULT_FLAG_ADDR
	ldr	r1, =FAULT_FLAG
	str	r1, [r0]
	dsb
	ldr	r0, =0xE000ED0C		@ AIRCR
	ldr	r1, =0x05FA0004		@ VECTKEY | SYSRESETREQ
	str	r1, [r0]
	dsb
1:	b	1b

@ ----------------------------------------------------------------------------
@ starter_reset - entry after reset.
@ Frame (sp): [0] best record address (0 none), [4] best sequence, [8] last used cell of page 0
@ (0 none), [12] last used cell of page 1, [16..31] record buffer for an append.
@ ----------------------------------------------------------------------------
	.global	starter_reset
	.thumb_func
	.type	starter_reset, %function
starter_reset:
	sub	sp, #32
	@ 1. fault flag
	ldr	r0, =FAULT_FLAG_ADDR
	ldr	r1, [r0]
	ldr	r2, =FAULT_FLAG
	cmp	r1, r2
	bne	.Lno_fault
	movs	r1, #0
	str	r1, [r0]
	b	.Lstart_f
.Lno_fault:
	@ 2. update key
	bl	key_pressed
	cmp	r0, #0
	bne	.Lstart_f
	@ 3. records
	movs	r0, #0
	str	r0, [sp, #0]
	str	r0, [sp, #4]
	str	r0, [sp, #8]
	str	r0, [sp, #12]
	ldr	r0, =REC_PAGE0
	add	r1, sp, #8
	bl	scan_page
	ldr	r0, =REC_PAGE1
	add	r1, sp, #12
	bl	scan_page
	ldr	r4, [sp, #0]		@ r4 = best record or 0
	cbnz	r4, .Lhave_record
	movs	r0, #SLOT_ID_A		@ no record: slot A
	b	.Lstart_id
.Lhave_record:
	ldrb	r5, [r4, #REC_STATE_OFS]
	ldrb	r6, [r4, #REC_SLOT_OFS]
	ldr	r7, [r4, #REC_SEQ_OFS]
	cmp	r5, #ST_OK
	bne	.Lnot_ok
	mov	r0, r6
	b	.Lstart_id
.Lnot_ok:
	cmp	r5, #ST_INSTALL
	bne	.Lnot_install
	movs	r0, #ST_TRIAL		@ INSTALL: start it once, record TRIAL
	mov	r1, r6
	adds	r2, r7, #1
	bl	append_record
	mov	r0, r6
	b	.Lstart_id
.Lnot_install:
	cmp	r5, #ST_TRIAL
	bne	.Lstart_f		@ unknown state: factory
	mov	r0, r6			@ TRIAL: roll back to the newest OK slot of another slot
	bl	newest_ok_other
	mov	r6, r0
	movs	r0, #ST_OK
	mov	r1, r6
	adds	r2, r7, #1
	bl	append_record
	mov	r0, r6
	@ fall through
.Lstart_id:
	@ 4. header check of the slot r0, factory on failure
	mov	r6, r0
	bl	slot_base_of
	mov	r4, r0			@ r4 = slot base or 0 for an unknown id
	cbz	r4, .Lstart_f
	mov	r0, r4
	mov	r1, r6
	bl	header_ok
	cbnz	r0, .Ljump
.Lstart_f:
	ldr	r4, =SLOT_F_BASE
	mov	r0, r4
	movs	r1, #SLOT_ID_F
	bl	header_ok
	cbnz	r0, .Ljump
.Lno_slot:
	wfi				@ no valid bootloader anywhere: wait (debug probe)
	b	.Lno_slot
.Ljump:
	@ 5. start the slot at r4
	add	r0, r4, #SLOT_IMAGE_OFS
	ldr	r1, =0xE000ED08		@ VTOR
	str	r0, [r1]
	dsb
	isb
	ldr	r1, [r0, #0]		@ initial SP of the slot
	ldr	r2, [r0, #4]		@ reset vector of the slot
	msr	msp, r1
	bx	r2

@ ----------------------------------------------------------------------------
@ slot_base_of - r0 = slot id; returns the slot base in r0, or 0 for an unknown id.
@ ----------------------------------------------------------------------------
	.thumb_func
slot_base_of:
	cmp	r0, #SLOT_ID_F
	beq	1f
	cmp	r0, #SLOT_ID_A
	beq	2f
	cmp	r0, #SLOT_ID_B
	beq	3f
	movs	r0, #0
	bx	lr
1:	ldr	r0, =SLOT_F_BASE
	bx	lr
2:	ldr	r0, =SLOT_A_BASE
	bx	lr
3:	ldr	r0, =SLOT_B_BASE
	bx	lr

@ ----------------------------------------------------------------------------
@ header_ok - r0 = slot base, r1 = slot id; returns 1 when the header and the image's first two
@ vector words are valid, else 0.
@ ----------------------------------------------------------------------------
	.thumb_func
header_ok:
	push	{r4, r5, lr}
	mov	r4, r0
	ldr	r5, =SLOT_AB_SIZE	@ r5 = slot size
	cmp	r1, #SLOT_ID_F
	bne	1f
	ldr	r5, =SLOT_F_SIZE
1:	ldr	r0, [r4, #HDR_MAGIC]
	ldr	r1, =SLOT_MAGIC
	cmp	r0, r1
	bne	.Lhdr_bad
	ldr	r0, [r4, #HDR_FORMAT]
	cmp	r0, #SLOT_FORMAT
	bne	.Lhdr_bad
	ldr	r0, [r4, #HDR_LINK]
	cmp	r0, r4
	bne	.Lhdr_bad
	ldr	r0, [r4, #HDR_LENGTH]
	cmp	r0, #8			@ at least SP and reset vector
	blo	.Lhdr_bad
	sub	r1, r5, #SLOT_IMAGE_OFS
	cmp	r0, r1
	bhi	.Lhdr_bad
	mov	r0, r4			@ header CRC over 0x00..0x17
	movs	r1, #HDR_CRC
	bl	crc32
	ldr	r1, [r4, #HDR_CRC]
	cmp	r0, r1
	bne	.Lhdr_bad
	add	r0, r4, #SLOT_IMAGE_OFS
	ldr	r1, [r0, #0]		@ stack pointer: RAM_LO < sp <= RAM_HI
	ldr	r2, =RAM_LO
	cmp	r1, r2
	bls	.Lhdr_bad
	ldr	r2, =RAM_HI
	cmp	r1, r2
	bhi	.Lhdr_bad
	ldr	r1, [r0, #4]		@ reset vector: odd, inside slot + 0x200 .. slot + length
	tst	r1, #1
	beq	.Lhdr_bad
	bic	r1, r1, #1
	cmp	r1, r0
	blo	.Lhdr_bad
	ldr	r2, [r4, #HDR_LENGTH]
	add	r2, r2, r0
	cmp	r1, r2
	bhs	.Lhdr_bad
	movs	r0, #1
	pop	{r4, r5, pc}
.Lhdr_bad:
	movs	r0, #0
	pop	{r4, r5, pc}

@ ----------------------------------------------------------------------------
@ crc32 - r0 = address, r1 = length in bytes; returns the CRC-32 (reflected polynomial 0xEDB88320,
@ initial value and final xor 0xFFFFFFFF, the CRC of zlib) in r0.  Bitwise, no table, no clock.
@ ----------------------------------------------------------------------------
	.thumb_func
crc32:
	mvn	r2, #0
	ldr	r12, =0xEDB88320
1:	cbz	r1, 3f
	ldrb	r3, [r0], #1
	eors	r2, r2, r3
	movs	r3, #8
2:	lsrs	r2, r2, #1		@ carry = bit shifted out
	it	cs
	eorcs	r2, r2, r12
	subs	r3, #1
	bne	2b
	subs	r1, #1
	b	1b
3:	mvn	r0, r2
	bx	lr

@ ----------------------------------------------------------------------------
@ record_valid - r0 = cell address; returns 1 when the magic halfword is 0xB007 and the CRC-32 of
@ bytes 0..11 equals the word at 12, else 0.
@ ----------------------------------------------------------------------------
	.thumb_func
record_valid:
	push	{r4, lr}
	mov	r4, r0
	ldrh	r1, [r4, #REC_MAGIC_OFS]
	movw	r2, #REC_MAGIC
	cmp	r1, r2
	bne	1f
	mov	r0, r4
	movs	r1, #REC_CRC_OFS
	bl	crc32
	ldr	r1, [r4, #REC_CRC_OFS]
	cmp	r0, r1
	bne	1f
	movs	r0, #1
	pop	{r4, pc}
1:	movs	r0, #0
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ scan_page - r0 = record page, r1 = address of that page's "last used cell" word in the frame of
@ starter_reset (frame + 8 for page 0, frame + 12 for page 1, so the frame base is r1 - 8 or r1 - 12;
@ frame [0] = best record, [4] = its sequence number).  A cell is used when any of its four words is
@ not 0xFFFFFFFF (the last used cell is stored); it is a candidate when record_valid; a candidate
@ with a higher sequence number than the best so far becomes the best record (the first one wins on
@ equal numbers).
@ ----------------------------------------------------------------------------
	.thumb_func
scan_page:
	push	{r4, r5, r6, r7, lr}
	mov	r4, r0			@ r4 = cell
	add	r5, r0, #REC_PAGE_SIZE	@ r5 = page end
	mov	r6, r1			@ r6 = last-used word
	ldr	r7, =REC_PAGE0		@ frame base = r6 - 8 for page 0, r6 - 12 for page 1
	cmp	r4, r7
	ite	eq
	subeq	r7, r6, #8
	subne	r7, r6, #12		@ r7 = frame base ([0] best, [4] best sequence)
.Lscan_cell:
	cmp	r4, r5
	bhs	.Lscan_done
	ldr	r0, [r4, #0]		@ used: any word not erased
	ldr	r1, [r4, #4]
	ands	r0, r0, r1
	ldr	r1, [r4, #8]
	ands	r0, r0, r1
	ldr	r1, [r4, #12]
	ands	r0, r0, r1
	adds	r0, r0, #1		@ 0 only when all four words were 0xFFFFFFFF
	beq	.Lscan_next
	str	r4, [r6]		@ last used cell of this page
	mov	r0, r4
	bl	record_valid
	cbz	r0, .Lscan_next
	ldr	r0, [r4, #REC_SEQ_OFS]
	ldr	r1, [r7, #0]
	cbz	r1, .Lscan_take		@ no best yet
	ldr	r1, [r7, #4]
	cmp	r0, r1
	bls	.Lscan_next		@ not newer
.Lscan_take:
	str	r4, [r7, #0]
	str	r0, [r7, #4]
.Lscan_next:
	adds	r4, #16
	b	.Lscan_cell
.Lscan_done:
	pop	{r4, r5, r6, r7, pc}

@ ----------------------------------------------------------------------------
@ newest_ok_other - r0 = slot id to avoid; returns the slot id of the valid OK record with the
@ highest sequence number whose slot differs, or SLOT_ID_F when there is none.
@ ----------------------------------------------------------------------------
	.thumb_func
newest_ok_other:
	push	{r4, r5, r6, r7, r8, lr}
	mov	r8, r0			@ r8 = slot to avoid
	movs	r6, #SLOT_ID_F		@ r6 = result
	movs	r7, #0			@ r7 = best sequence + 1 (0 = none)
	ldr	r4, =REC_PAGE0
	add	r5, r4, #(2 * REC_PAGE_SIZE)	@ both pages are consecutive
.Lok_cell:
	cmp	r4, r5
	bhs	.Lok_done
	mov	r0, r4
	bl	record_valid
	cbz	r0, .Lok_next
	ldrb	r0, [r4, #REC_STATE_OFS]
	cmp	r0, #ST_OK
	bne	.Lok_next
	ldrb	r0, [r4, #REC_SLOT_OFS]
	cmp	r0, r8
	beq	.Lok_next
	ldr	r1, [r4, #REC_SEQ_OFS]
	adds	r1, r1, #1
	cmp	r1, r7
	bls	.Lok_next
	mov	r7, r1
	mov	r6, r0
.Lok_next:
	adds	r4, #16
	b	.Lok_cell
.Lok_done:
	mov	r0, r6
	pop	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ append_record - r0 = state, r1 = slot id, r2 = sequence number.  Uses the caller's frame of
@ starter_reset ([0] best record, [8] / [12] last used cells, [16..31] buffer): found at sp + 24
@ after the push below (4 words pushed + the caller's sp).  Builds the 16-byte record (version from
@ the slot's header, 0 if the slot id is unknown), chooses the cell after the last used cell of the
@ page that holds the best record (page 0 when there is none); when that page is full it erases the
@ other page first and uses its first cell.  Programs the four words, locks the flash.  A failed or
@ interrupted write leaves a cell that fails record_valid and is skipped.
@ ----------------------------------------------------------------------------
	.thumb_func
append_record:
	push	{r4, r5, r6, r7, r8, lr}
	add	r8, sp, #24		@ r8 = frame of starter_reset
	mov	r4, r0
	mov	r5, r1
	mov	r6, r2
	@ build the record in [r8 + 16]
	add	r7, r8, #16
	movw	r0, #REC_MAGIC
	strh	r0, [r7, #REC_MAGIC_OFS]
	strb	r4, [r7, #REC_STATE_OFS]
	strb	r5, [r7, #REC_SLOT_OFS]
	str	r6, [r7, #REC_SEQ_OFS]
	mov	r0, r5
	bl	slot_base_of
	cbz	r0, 1f
	ldr	r0, [r0, #HDR_VERSION]
1:	str	r0, [r7, #REC_VERSION_OFS]
	mov	r0, r7
	movs	r1, #REC_CRC_OFS
	bl	crc32
	str	r0, [r7, #REC_CRC_OFS]
	@ choose the cell
	ldr	r0, [r8, #0]		@ best record
	ldr	r4, =REC_PAGE0		@ r4 = page
	cbz	r0, 2f
	lsrs	r4, r0, #11		@ page of the best record: clear the low 11 bits (0x800 pages)
	lsls	r4, r4, #11
2:	ldr	r1, =REC_PAGE0
	cmp	r4, r1
	ite	eq
	ldreq	r5, [r8, #8]		@ r5 = last used cell of that page (0 none)
	ldrne	r5, [r8, #12]
	cbz	r5, 3f
	adds	r5, #16
	b	4f
3:	mov	r5, r4
4:	add	r0, r4, #REC_PAGE_SIZE
	cmp	r5, r0
	blo	5f
	ldr	r1, =REC_PAGE0		@ page full: erase the other page, use its first cell
	cmp	r4, r1
	ite	eq
	ldreq	r5, =REC_PAGE1
	ldrne	r5, =REC_PAGE0
	bl	flash_unlock2
	mov	r0, r5
	bl	flash_erase_page2
	b	6f
5:	bl	flash_unlock2
6:	mov	r0, r5
	ldr	r1, [r7, #0]
	bl	flash_program_word2
	add	r0, r5, #4
	ldr	r1, [r7, #4]
	bl	flash_program_word2
	add	r0, r5, #8
	ldr	r1, [r7, #8]
	bl	flash_program_word2
	add	r0, r5, #12
	ldr	r1, [r7, #12]
	bl	flash_program_word2
	bl	flash_lock2
	pop	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ Bank-2 flash primitives (registers as the stock bootloader uses them).
@ ----------------------------------------------------------------------------
	.thumb_func
flash_unlock2:
	ldr	r0, =FLASH_KEYR2
	ldr	r1, =FLASH_KEY1
	str	r1, [r0]
	ldr	r1, =FLASH_KEY2
	str	r1, [r0]
	bx	lr

	.thumb_func
flash_lock2:
	ldr	r0, =FLASH_CTRL2
	ldr	r1, [r0]
	orr	r1, r1, #0x80
	str	r1, [r0]
	bx	lr

@ flash_wait2 - waits while bit 0 (busy) of FLASH_STS2 is set, at most 0x00400000 polls.
	.thumb_func
flash_wait2:
	ldr	r0, =FLASH_STS2
	ldr	r1, =0x00400000
1:	ldr	r2, [r0]
	tst	r2, #1
	beq	2f
	subs	r1, #1
	bne	1b
2:	bx	lr

@ flash_erase_page2 - r0 = page address (bank 2).
	.thumb_func
flash_erase_page2:
	push	{r4, lr}
	mov	r4, r0
	bl	flash_wait2
	ldr	r0, =FLASH_CTRL2
	ldr	r1, [r0]
	orr	r1, r1, #0x02		@ PER
	str	r1, [r0]
	ldr	r1, =FLASH_ADDR2
	str	r4, [r1]
	ldr	r1, [r0]
	orr	r1, r1, #0x40		@ STRT
	str	r1, [r0]
	bl	flash_wait2
	ldr	r0, =FLASH_CTRL2
	ldr	r1, [r0]
	bic	r1, r1, #0x02
	str	r1, [r0]
	pop	{r4, pc}

@ flash_program_word2 - r0 = address (bank 2), r1 = word.
	.thumb_func
flash_program_word2:
	push	{r4, r5, lr}
	mov	r4, r0
	mov	r5, r1
	bl	flash_wait2
	ldr	r0, =FLASH_CTRL2
	ldr	r1, [r0]
	orr	r1, r1, #0x01		@ PG
	str	r1, [r0]
	str	r5, [r4]
	bl	flash_wait2
	ldr	r0, =FLASH_CTRL2
	ldr	r1, [r0]
	bic	r1, r1, #0x01
	str	r1, [r0]
	pop	{r4, r5, pc}

@ ----------------------------------------------------------------------------
@ key_pressed - returns 1 when the PE2 / PE3 key is held, else 0.  Port E clock on (RCC_APB2EN bit 6),
@ PE2 input with pull-up (configuration 8, output bit 1) and PE3 output low (configuration 2): read
@ PE2; then PE3 input with pull-up and PE2 output low: read PE3; both low = pressed.  Restores the
@ configuration word, the output word and the clock bit as found.
@ ----------------------------------------------------------------------------
	.thumb_func
key_pressed:
	push	{r4, r5, r6, r7, lr}
	ldr	r4, =RCC_APB2EN
	ldr	r5, [r4]		@ r5 = clock word as found
	orr	r0, r5, #0x40
	str	r0, [r4]
	ldr	r6, =GPIOE_CFGLR
	ldr	r7, [r6]		@ r7 = configuration as found
	ldr	r3, [r6, #(GPIOE_ODR - GPIOE_CFGLR)]
	push	{r3}			@ output word as found
	@ PE2 input pull-up, PE3 output low
	bic	r0, r7, #0xFF00		@ pins 2 and 3 = bits 8..15
	orr	r0, r0, #0x2800		@ pin 3 = 2 (output), pin 2 = 8 (input with pull)
	str	r0, [r6]
	ldr	r1, [r6, #(GPIOE_ODR - GPIOE_CFGLR)]
	orr	r1, r1, #0x04		@ PE2 pull-up
	bic	r1, r1, #0x08		@ PE3 low
	str	r1, [r6, #(GPIOE_ODR - GPIOE_CFGLR)]
	bl	settle
	ldr	r1, [r6, #(GPIOE_IDR - GPIOE_CFGLR)]
	and	r2, r1, #0x04		@ r2 = PE2 level (0 = connected to PE3)
	@ PE3 input pull-up, PE2 output low
	bic	r0, r7, #0xFF00
	orr	r0, r0, #0x8200		@ pin 3 = 8 (input with pull), pin 2 = 2 (output)
	str	r0, [r6]
	ldr	r1, [r6, #(GPIOE_ODR - GPIOE_CFGLR)]
	orr	r1, r1, #0x08		@ PE3 pull-up
	bic	r1, r1, #0x04		@ PE2 low
	str	r1, [r6, #(GPIOE_ODR - GPIOE_CFGLR)]
	push	{r2}
	bl	settle
	pop	{r2}
	ldr	r1, [r6, #(GPIOE_IDR - GPIOE_CFGLR)]
	and	r3, r1, #0x08		@ r3 = PE3 level
	@ restore
	str	r7, [r6]
	pop	{r0}
	str	r0, [r6, #(GPIOE_ODR - GPIOE_CFGLR)]
	str	r5, [r4]
	orrs	r2, r2, r3
	ite	eq
	moveq	r0, #1			@ both low: pressed
	movne	r0, #0
	pop	{r4, r5, r6, r7, pc}

@ settle - about 2000 cycles of delay for the pins to settle after a configuration change.
	.thumb_func
settle:
	movw	r0, #1000
1:	subs	r0, #1
	bne	1b
	bx	lr

	.ltorg
