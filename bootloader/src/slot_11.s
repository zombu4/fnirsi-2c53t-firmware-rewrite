@ slot_11.s - code that only the slot build of the bootloader has (make slot): the bootloader started by
@ the starter from slot F, A or B (BOOTLOADER_DESIGN.md revision 2, section 4).  The stock build
@ (make, make check) assembles this file to nothing.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
@
@ Called from the stock code (each call is under .ifdef SLOT there):
@   copy_region   scatter-load handler of region table entry 0 (rodata.s): copies the RAM image
@   slot_app_ok   fn_08002784, before the application is started: checks it
@   slot_confirm  fn_08002784 (application start) and main after the USB start: TRIAL -> OK
@   slot_quiesce  fn_08002784, just before the jump: every NVIC interrupt and SysTick off

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

.ifdef SLOT
	.include "common/layout.inc"

	.section .text.slot,"ax",%progbits
	.p2align 2

@ ----------------------------------------------------------------------------
@ copy_region - scatter-load handler: r0 = source, r1 = destination, r2 = byte count (a multiple
@ of 4, not 0).  Copies word by word.  Clobbers r0-r3.  copy_region_addr is a plain label on the
@ same address: the region table needs the even address (an odd handler word is taken as an offset
@ by scatter_load_regions, 0x080001AA).
@ ----------------------------------------------------------------------------
	.global	copy_region
	.global	copy_region_addr
	.thumb_func
	.type	copy_region, %function
copy_region:
copy_region_addr:
1:	subs	r2, #4
	itt	cs
	ldrcs	r3, [r0], #4
	strcs	r3, [r1], #4
	bhi	1b
	bx	lr

@ ----------------------------------------------------------------------------
@ slot_app_ok - r0 = address of the application's vector table (0x08007000, or the "A"+hex target).
@ Returns 1 when the application may be started, else 0:
@   - the "8KTA" word is at 0x08006800 (the stock bootloader erases it when an update starts and
@     programs it when the whole file is written: an interrupted update leaves it erased);
@   - APP_BASE <= table and table + 8 <= APP_END;
@   - stack pointer (word 0): RAM_LO < sp <= RAM_HI;
@   - reset vector (word 1): odd, and table <= (vector - 1) < APP_END.
@ ----------------------------------------------------------------------------
	.global	slot_app_ok
	.thumb_func
	.type	slot_app_ok, %function
slot_app_ok:
	ldr	r1, =KTA_ADDR
	ldr	r1, [r1]
	ldr	r2, =KTA_WORD
	cmp	r1, r2
	bne	9f
	ldr	r1, =APP_BASE
	cmp	r0, r1
	blo	9f
	ldr	r3, =APP_END		@ r3 = end of the application area
	add	r1, r0, #8
	cmp	r1, r3
	bhi	9f
	ldr	r1, [r0, #0]		@ stack pointer
	ldr	r2, =RAM_LO
	cmp	r1, r2
	bls	9f
	ldr	r2, =RAM_HI
	cmp	r1, r2
	bhi	9f
	ldr	r1, [r0, #4]		@ reset vector
	tst	r1, #1
	beq	9f
	bic	r1, r1, #1
	cmp	r1, r0
	blo	9f
	cmp	r1, r3
	bhs	9f
	movs	r0, #1
	bx	lr
9:	movs	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ slot_confirm - when the newest valid record is TRIAL for the slot this image runs in, appends OK
@ for it (sequence + 1).  Nothing otherwise (no record, OK / INSTALL, another slot, or this image
@ is not in a slot id the records know).  The slot is the one whose image starts at this image's
@ vector table: vectors - SLOT_IMAGE_OFS.
@ ----------------------------------------------------------------------------
	.global	slot_confirm
	.thumb_func
	.type	slot_confirm, %function
slot_confirm:
	push	{r4, r5, r6, lr}
	sub	sp, #16			@ scan state
	mov	r0, sp
	bl	rec_scan
	ldr	r4, [sp, #0]		@ r4 = newest valid record or 0
	cbz	r4, 9f
	ldrb	r0, [r4, #REC_STATE_OFS]
	cmp	r0, #ST_TRIAL
	bne	9f
	ldr	r5, =vectors		@ r5 = this image's slot base
	sub	r5, r5, #SLOT_IMAGE_OFS
	ldrb	r6, [r4, #REC_SLOT_OFS]	@ r6 = slot id of the TRIAL record
	mov	r0, r6
	bl	slot_base_of
	cmp	r0, r5
	bne	9f			@ TRIAL of another slot (or an unknown id: base 0)
	movs	r0, #ST_OK
	mov	r1, r6
	ldr	r2, [r4, #REC_SEQ_OFS]
	adds	r2, r2, #1
	mov	r3, sp
	bl	rec_append
9:	add	sp, #16
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ slot_quiesce - disables and clears every NVIC interrupt (ICER0..7 0xE000E180, ICPR0..7 0xE000E280),
@ stops SysTick (CTRL 0xE000E010 = 0) and clears a pending SysTick (ICSR 0xE000ED04 bit 25), then
@ leaves PRIMASK clear as after a reset.  The application starts with no interrupt of this
@ bootloader enabled or pending (BOOTLOADER_DESIGN.md rev 2 (9)).
@ ----------------------------------------------------------------------------
	.global	slot_quiesce
	.thumb_func
	.type	slot_quiesce, %function
slot_quiesce:
	cpsid	i
	ldr	r0, =0xE000E180		@ ICER0
	mvn	r1, #0
	movs	r2, #8
1:	str	r1, [r0]		@ ICERn: disable
	str	r1, [r0, #0x100]	@ ICPRn: clear pending
	adds	r0, #4
	subs	r2, #1
	bne	1b
	ldr	r0, =0xE000E010		@ SysTick CTRL
	movs	r1, #0
	str	r1, [r0]
	ldr	r0, =0xE000ED04		@ ICSR
	mov	r1, #0x02000000		@ PENDSTCLR
	str	r1, [r0]
	dsb
	isb
	cpsie	i
	bx	lr

	.include "common/records.inc"

	.ltorg
.endif
