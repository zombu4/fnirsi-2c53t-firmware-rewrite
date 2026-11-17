@ records.inc - control records of the two-part bootloader: CRC-32, record check, scan, append, and the
@ bank-2 flash primitives they need.  Included (into the current text section) by the starter and by
@ the slot build of the bootloader, so both use one implementation.  Needs common/layout.inc first.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
@
@ Scan state (16 bytes, owned by the caller):
@   [0]  address of the valid record with the highest sequence number (0: none)
@   [4]  its sequence number
@   [8]  last used cell of record page 0 (0: page empty)
@   [12] last used cell of record page 1 (0: page empty)
@ A cell is used when any of its four words is not 0xFFFFFFFF; a used cell is never programmed again
@ (a torn record stays where it is and fails rec_valid).

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
@ crc32 - r0 = address, r1 = length in bytes; returns the CRC-32 (reflected polynomial 0xEDB88320,
@ initial value and final xor 0xFFFFFFFF, the CRC of zlib) in r0.  Bitwise, no table, no clock.
@ Clobbers r1-r3, r12.
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
@ rec_valid - r0 = cell address; returns 1 when the magic halfword is 0xB007 and the CRC-32 of
@ bytes 0..11 equals the word at 12, else 0.
@ ----------------------------------------------------------------------------
	.thumb_func
rec_valid:
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
@ rec_scan - r0 = scan state (16 bytes, see the file header).  Reads both record pages (page 0 first,
@ cells in address order) and fills the state.  On equal sequence numbers the first one found stays.
@ ----------------------------------------------------------------------------
	.thumb_func
rec_scan:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r0			@ r7 = scan state
	movs	r0, #0
	str	r0, [r7, #0]
	str	r0, [r7, #4]
	str	r0, [r7, #8]
	str	r0, [r7, #12]
	ldr	r4, =REC_PAGE0		@ r4 = cell
	add	r5, r4, #(2 * REC_PAGE_SIZE)	@ r5 = end of page 1 (the pages are consecutive)
	ldr	r6, =REC_PAGE1		@ r6 = first cell of page 1
.Lrs_cell:
	cmp	r4, r5
	bhs	.Lrs_done
	ldr	r0, [r4, #0]		@ used: any word not erased
	ldr	r1, [r4, #4]
	ands	r0, r0, r1
	ldr	r1, [r4, #8]
	ands	r0, r0, r1
	ldr	r1, [r4, #12]
	ands	r0, r0, r1
	adds	r0, r0, #1		@ 0 only when all four words were 0xFFFFFFFF
	beq	.Lrs_next
	cmp	r4, r6			@ last used cell of the page that holds r4
	ite	lo
	strlo	r4, [r7, #8]
	strhs	r4, [r7, #12]
	mov	r0, r4
	bl	rec_valid
	cbz	r0, .Lrs_next
	ldr	r0, [r4, #REC_SEQ_OFS]
	ldr	r1, [r7, #0]
	cbz	r1, .Lrs_take		@ no best record yet
	ldr	r1, [r7, #4]
	cmp	r0, r1
	bls	.Lrs_next		@ not newer
.Lrs_take:
	str	r4, [r7, #0]
	str	r0, [r7, #4]
.Lrs_next:
	adds	r4, #16
	b	.Lrs_cell
.Lrs_done:
	pop	{r4, r5, r6, r7, pc}

@ ----------------------------------------------------------------------------
@ rec_append - r0 = state, r1 = slot id, r2 = sequence number, r3 = scan state filled by rec_scan.
@ Builds the 16-byte record (version from the slot's header, 0 for an unknown slot id) and programs
@ it into the cell after the last used cell of the page that holds the best record (page 0 when
@ there is none, its first cell when that page is empty).  When that page is full the other page is
@ erased first and its first cell is used.  Programs the four words in order and locks the flash.
@ A failed or interrupted write leaves a cell that fails rec_valid; the next scan skips it.
@ ----------------------------------------------------------------------------
	.thumb_func
rec_append:
	push	{r4, r5, r6, r7, r8, lr}
	sub	sp, #16			@ record buffer
	mov	r7, sp			@ r7 = record buffer
	mov	r8, r3			@ r8 = scan state
	mov	r4, r0
	mov	r5, r1
	mov	r6, r2
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
	add	sp, #16
	pop	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ Bank-2 flash primitives (registers as the stock bootloader uses them: 0x080022A4 keys, 0x08002170
@ erase, 0x080023C4 program).  Only rec_append calls them, only for the two record pages.
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
