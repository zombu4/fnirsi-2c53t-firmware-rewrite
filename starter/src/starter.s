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
	.include "common/layout.inc"

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

@ Signature right after the vector table (STARTER_SIG_ADDR): the installer recognises page 0 as a
@ starter by it, whatever starter version is installed (the starter is never rewritten).
	.section .signature,"a",%progbits
	.word	STARTER_SIG
	.word	STARTER_SIG_FORMAT

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
@ Frame (sp): the 16-byte scan state of rec_scan / rec_append (common/records.inc).
@ ----------------------------------------------------------------------------
	.global	starter_reset
	.thumb_func
	.type	starter_reset, %function
starter_reset:
	sub	sp, #16
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
	mov	r0, sp
	bl	rec_scan
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
	mov	r3, sp
	bl	rec_append
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
	mov	r3, sp
	bl	rec_append
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
@ header_ok - r0 = slot base (r1 unused); returns 1 when the header and the image's first two
@ vector words are valid, else 0.
@ ----------------------------------------------------------------------------
	.thumb_func
header_ok:
	push	{r4, r5, lr}
	mov	r4, r0
	ldr	r5, =SLOT_SIZE		@ r5 = slot size (the same for every slot)
	ldr	r0, [r4, #HDR_MAGIC]
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
	bl	rec_valid
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
	ldr	r0, [r4]		@ read back and wait: the port is clocked before it is read
	dsb
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

	.include "common/records.inc"

	.ltorg
