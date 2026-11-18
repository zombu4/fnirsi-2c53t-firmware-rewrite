@ usb_remote.s - remote control of the meter functions over the USB control channel (PROTOCOL.md
@ sections 4.3 .. 4.10 and 4.12): multimeter, oscilloscope, settings, screenshot, files and events.
@ Part of the FNIRSI 2C53T firmware rewrite.
@
@ Jobs. A command that changes what the meter does runs in the task that owns that state, the same
@ way a key press does:
@ - the usb task stores a job function in V_KJOB (key task) or V_DJOB (display task) and posts the
@   code REMOTE_CODE (0x80) to that task's queue (key queue *0x20002D70, display queue *0x20002D6C);
@ - the key task's dispatcher (fn_08040008, keys_26.s) and the display task's dispatcher (fn_0803da50,
@   ui_keys_68.s) call key_task_dispatch / display_task_dispatch instead of their table lookup; for
@   REMOTE_CODE these take the job (interrupts off while it is read and cleared, so it runs once) and
@   run it on the private stack JOB_STACK_TOP (the tasks' own stacks are 0x80 / 0x180 words and their
@   free margin is not measured), store its status in V_JRES and return to the dispatcher's loop;
@   every other code goes to the vendor table exactly as before;
@ - the key task skips its dispatch while autoset / auto-correction run (bytes 0x20000127, 0x20000128,
@   0x2000012B, 0x20001024) and while a screenshot is saved (0x20000F08 1 or 0xFF): a job posted then is
@   dropped by the dispatcher, the usb task takes it back after 500 ms and answers status 4 (busy).
@ Jobs change settings through the vendor key handlers (the functions of the key table d_08046548), so
@ every change has the vendor's side effects (meter-chip commands, FPGA commands, redraws); scope menu
@ items are applied through the menu's own handler (menu_apply).
@
@ Facts used (research 2026-11-18, file:line in the vendor-port sources):
@ - Meter page (UI page 1): index 0x20001025 (0 auto, 1 voltage, 2 diode / continuity, 3 resistance,
@   4 capacitance, 5 temperature, 6 small current, 7 large current), sub-function 0x2000102E (1 / 2),
@   temperature unit 0x20001031, hold 0x20001034 (key 15, fn_0800bd60; page 1 draws "HOLD" from it,
@   waveform_84.s), relative 0x20001035 (key 7, fn_0800d548; reading = value - reference, misc_40.s),
@   keys 13 / 14 (fn_0800b1f8 / fn_0800b7cc) index - 1 / + 1, key 2 (fn_0800cb50) auto, key 4
@   (fn_0800d120) toggles the sub-function or the temperature unit; all six do nothing while the high
@   nibble of 0x20001055 is 0xB (ui_keys_64..67.s).
@ - Scope page (UI page 2): selection 0x2000044C (low nibble 0 V/div + timebase, 1 offset, 2 trigger
@   level, 3 cursors; bit 7 channel), key 5 (fn_0800d2f8) cycles it, key 4 toggles bit 7 when both
@   channels are on; keys 11 / 12 (fn_0800a148 / fn_0800a900) + 1 / - 1 of the selected value; keys
@   13 / 14 (fn_0800b1f8 / fn_0800b7cc) timebase + 1 / - 1 at selection 0; key 15 (fn_0800bd60) run /
@   stop; key 2 (fn_0800cb50) autoset; key 16 (fn_0800df58) auto-correction.  Per channel n: coupling
@   0x200000F8 + n (0 AC, 1 DC), V/div step 0x200000FA + n (0..9), offset 0x200000FC + n (s8,
@   -100..100), probe 0x200000FE + n (0 x1, 1 x10), FFT 0x20000102 + n; channel enable bits 0x2000010C;
@   timebase 0x20000125 (0..28); running 0x20000126; trigger source 0x2000010E, mode 0x2000010F (0
@   normal, 1 auto, 2 single), edge 0x20000110, level 0x20000114 (s16, -100..100); display samples
@   0x2000044E + 0x12D * n (301 bytes), start / count halfwords 0x20000EAC / 0x20000EAE.
@ - Scope menu = UI page 9: 0x20001061 sub-mode (1 = choosing a value), 0x20001062 item, 0x20001063
@   value; key 15 at sub-mode 1 applies (item 3 / 4 = CH1 / CH2: value 0 enable, 1 probe, 2 coupling,
@   3 FFT; item 5 trigger: 0 mode, 1 edge, 2 source); the menu redraws (display codes 0x13 / 0x14,
@   fn_080103f4 / fn_08010584) return at once unless the page is 9.
@ - Settings: backlight 0x20001059 (25..100, also written to 0x40015034), sound 0x2000105A (0..10),
@   startup option 0x2000105C (0..2, the menu's three entries), auto shutdown 0x2000105D (0 off,
@   1..3); save_settings_to_flash (settings_53.s) writes the settings page and ends in
@   settings_saved.
@ - Screen read-back: fn_080097e8 (lcd_hw_27.s) reads the rectangle of the record 0x20008350 (x, y,
@   w, h halfwords, +8 buffer) from the LCD as RGB565.
@ - Files: file_open (mode 1 read, 10 write + create / truncate), file_read / file_write (r3 = count),
@   file_seek, file_close, dir_open, dir_read_entry (record: +0 size, +8 attribute, +0x16 long name,
@   empty name = end), object_release (directory close), path_delete (path at 0x20008360; 96 bytes
@   below the 32-byte pool at 0x200083C0); file object 0x102C bytes (+0x0C size), directory object
@   0x30, entry record 0x118 (filesystem_06..08.s).

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb


	.include "common/layout.inc"
	.include "src/parts/usb_ctl.inc"

	.equ	DMM_INDEX,	0x20001025
	.equ	DMM_SUB,	0x2000102E
	.equ	DMM_TUNIT,	0x20001031
	.equ	DMM_HOLD_B,	0x20001034
	.equ	DMM_REL_B,	0x20001035
	.equ	DMM_DETECT,	0x20001055
	.equ	SC_SEL,		0x2000044C
	.equ	SC_COUPLING,	0x200000F8
	.equ	SC_VDIV,	0x200000FA
	.equ	SC_OFFSET,	0x200000FC
	.equ	SC_PROBE,	0x200000FE
	.equ	SC_FFT,		0x20000102
	.equ	SC_ENABLE,	0x2000010C
	.equ	SC_TSOURCE,	0x2000010E
	.equ	SC_TMODE,	0x2000010F
	.equ	SC_TEDGE,	0x20000110
	.equ	SC_TLEVEL,	0x20000114
	.equ	SC_TIMEBASE,	0x20000125
	.equ	SC_RUNNING,	0x20000126
	.equ	SC_SAMPLES,	0x2000044E
	.equ	SC_START,	0x20000EAC
	.equ	SET_BACKLIGHT,	0x20001059
	.equ	SET_SOUND,	0x2000105A
	.equ	SET_STARTUP,	0x2000105C
	.equ	SET_AUTOOFF,	0x2000105D
	.equ	BACKLIGHT_PWM,	0x40015034
	.equ	BATTERY_LEVEL,	0x2000105F
	.equ	LCD_RECT,	0x20008350
	.equ	PATH_BUF,	0x20008360
	.equ	PATH_BUF_SIZE,	96
	.equ	FILE_CHUNK,	500		@ file bytes per FILE_READ answer (status + total + 500 <= 512)

	.section .text.usb_ctl,"ax",%progbits
	.p2align 2

@ ============================================================================
@ Task side: dispatcher hooks and job execution
@ ============================================================================

@ key_task_dispatch - called by the key task's dispatcher with r0 = received code (keys_26.s).
@ REMOTE_CODE runs the posted job; other codes are recorded for the KEY_PRESSED event and go to the
@ vendor handler of the key table d_08046548 (code n -> word n - 1), as the dispatcher did itself.
	.global	key_task_dispatch
	.thumb_func
	.type	key_task_dispatch, %function
key_task_dispatch:
	cmp	r0, #REMOTE_CODE
	bne	1f
	movs	r0, #V_KJOB
	b	run_posted_job
1:	push	{r0, lr}
	bl	key_event_record
	pop	{r0, lr}
	ldr	r1, =d_08046548 - 4
	ldr	r1, [r1, r0, lsl #2]
	bx	r1

@ display_task_dispatch - called by the display task's dispatcher with r0 = received code
@ (ui_keys_68.s). REMOTE_CODE runs the posted job; other codes go to the vendor table d_0804be74
@ (code n -> word n), as the dispatcher did itself.
	.global	display_task_dispatch
	.thumb_func
	.type	display_task_dispatch, %function
display_task_dispatch:
	cmp	r0, #REMOTE_CODE
	bne	1f
	movs	r0, #V_DJOB
	b	run_posted_job
1:	ldr	r1, =d_0804be74
	ldr	r1, [r1, r0, lsl #2]
	bx	r1

@ run_posted_job - r0 = offset of the job word in V. Takes the job (read and cleared with interrupts
@ off), runs it on the job stack with r0 = request payload, stores its status in V_JRES.
	.thumb_func
run_posted_job:
	push	{r4, lr}
	ldr	r4, =V
	cpsid	i
	ldr	r3, [r4, r0]
	movs	r1, #0
	str	r1, [r4, r0]
	cpsie	i
	cbz	r3, 9f
	mov	r1, sp
	ldr	r2, =JOB_STACK_TOP
	mov	sp, r2
	push	{r1, r2}			@ the task's stack pointer, kept on the job stack
	ldr	r0, =FRAME + 5
	blx	r3
	pop	{r1, r2}
	mov	sp, r1
	strb	r0, [r4, #V_JRES]
9:	pop	{r4, pc}

@ key_event_record - r0 = key code; appends it to the key event ring while DTR is set (dropped
@ when the ring is full). Key task only (single writer of V_EVKH).
	.thumb_func
key_event_record:
	ldr	r3, =V
	ldrb	r1, [r3, #V_DTR]
	cbz	r1, 9f
	ldrb	r1, [r3, #V_EVKH]
	adds	r2, r1, #1
	and	r2, r2, #7
	ldrb	r12, [r3, #V_EVKT]
	cmp	r2, r12
	beq	9f
	add	r12, r3, #V_EVK
	strb	r0, [r12, r1]
	strb	r2, [r3, #V_EVKH]
9:	bx	lr

@ ============================================================================
@ usb task side
@ ============================================================================

@ run_job - r0 = job function, r1 = 0 key task / 1 display task. Posts the job and waits for its
@ status. Returns the status, or 4 when the task did not take the job within 500 ms (the job is
@ taken back; once taken it is always waited for).
	.thumb_func
run_job:
	push	{r3, r4, r5, r6, r7, lr}
	ldr	r4, =V
	mov	r5, r1
	movs	r2, #0xFF
	strb	r2, [r4, #V_JRES]
	cbnz	r1, 1f
	str	r0, [r4, #V_KJOB]
	ldr	r0, =KEY_QUEUE
	b	2f
1:	str	r0, [r4, #V_DJOB]
	ldr	r0, =DISPLAY_QUEUE
2:	ldr	r0, [r0]
	movs	r1, #REMOTE_CODE
	str	r1, [sp]
	mov	r1, sp
	movs	r2, #0
	bl	queue_send_timeout
	cmp	r0, #1
	bne	6f
	movw	r6, #500
3:	movs	r0, #1
	bl	fn_08041390
	bl	msc_service			@ the drive is served while the job runs
	ldrb	r0, [r4, #V_JRES]
	cmp	r0, #0xFF
	bne	9f
	subs	r6, #1
	bne	3b
6:	cpsid	i				@ not posted / not finished: take the job back unless the
						@ task has it already (a code left from an earlier attempt)
	cmp	r5, #0
	ite	eq
	moveq	r7, #V_KJOB
	movne	r7, #V_DJOB
	ldr	r0, [r4, r7]
	cbz	r0, 4f
	movs	r0, #0
	str	r0, [r4, r7]
	cpsie	i
	movs	r0, #4
	b	9f
4:	cpsie	i				@ taken: it runs to its end
5:	movs	r0, #1
	bl	fn_08041390
	bl	msc_service
	ldrb	r0, [r4, #V_JRES]
	cmp	r0, #0xFF
	beq	5b
9:	pop	{r3, r4, r5, r6, r7, pc}

@ job_then_state - r0 = job function, r1 = task. Runs the job; status 0 answers with the STATE
@ record, any other status answers that status alone.
	.thumb_func
job_then_state:
	push	{r4, lr}
	bl	run_job
	cbnz	r0, 1f
	ldr	r0, =ANSWER + 1
	bl	build_state
	add	r1, r0, #1
	movs	r0, #0
	bl	answer
	pop	{r4, pc}
1:	movs	r1, #1
	bl	answer
	pop	{r4, pc}

@ answer_status - r0 = status; answers it with no data.
	.thumb_func
answer_status:
	movs	r1, #1
	b	answer

@ ============================================================================
@ Multimeter (PROTOCOL.md 4.3); jobs run in the key task
@ ============================================================================

@ DMM_FUNCTION: function 0..12.
	.global	cmd_dmm_function
	.thumb_func
cmd_dmm_function:
	cmp	r6, #1
	bne	9f
	ldrb	r0, [r5]
	cmp	r0, #12
	bhi	9f
	ldr	r0, =job_dmm_function
	movs	r1, #0
	b	job_then_state
9:	movs	r0, #2
	b	answer_status

@ DMM_HOLD / DMM_RELATIVE: on 0 / 1.
	.global	cmd_dmm_hold
	.thumb_func
cmd_dmm_hold:
	ldr	r0, =job_dmm_hold
	b	1f
	.global	cmd_dmm_relative
	.thumb_func
cmd_dmm_relative:
	ldr	r0, =job_dmm_relative
1:	cmp	r6, #1
	bne	9f
	ldrb	r1, [r5]
	cmp	r1, #1
	bhi	9f
	movs	r1, #0
	b	job_then_state
9:	movs	r0, #2
	b	answer_status

@ dmm_ready - 0 when the meter page is open and no automatic detection runs, else the status (3 other
@ page, 4 detection: the key handlers do nothing then).
	.thumb_func
dmm_ready:
	ldr	r0, =UI_PAGE
	ldrb	r0, [r0]
	cmp	r0, #1
	bne	1f
	ldr	r0, =DMM_DETECT
	ldrb	r0, [r0]
	lsrs	r0, r0, #4
	cmp	r0, #0xB
	beq	2f
	movs	r0, #0
	bx	lr
1:	movs	r0, #3
	bx	lr
2:	movs	r0, #4
	bx	lr

@ byte_is_set - r0 = address; returns 1 when the byte is non-zero, else 0.
	.thumb_func
byte_is_set:
	ldrb	r0, [r0]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	bx	lr

@ job_dmm_function - r0 = payload {function}. Steps the meter index with keys 14 / 13 the short way
@ round (at most 8 steps), then sets the sub-function or temperature unit with key 4; verifies the
@ result with dmm_function_code. Function 0 (auto) is key 2.
	.thumb_func
job_dmm_function:
	push	{r4, r5, r6, lr}
	ldrb	r4, [r0]			@ r4 = requested function
	bl	dmm_ready
	cmp	r0, #0
	bne	9f
	cbnz	r4, 1f
	ldr	r0, =DMM_INDEX			@ auto
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	7f
	bl	fn_0800cb50
	b	7f
1:	adr	r0, dmm_index_of
	ldrb	r5, [r0, r4]			@ r5 = target index
	movs	r6, #8
2:	ldr	r0, =DMM_INDEX
	ldrb	r0, [r0]
	cmp	r0, r5
	beq	3f
	subs	r6, #1
	bmi	7f
	sub	r1, r5, r0
	and	r1, r1, #7
	cmp	r1, #4
	bhi	21f
	bl	fn_0800b7cc			@ key 14: index + 1
	b	2b
21:	bl	fn_0800b1f8			@ key 13: index - 1
	b	2b
3:	adr	r0, dmm_sub_of
	ldrb	r1, [r0, r4]			@ r1 = sub-function wanted, 0 = none
	cbz	r1, 4f
	ldr	r0, =DMM_SUB
	ldrb	r0, [r0]
	cmp	r0, r1
	beq	7f
	bl	fn_0800d120			@ key 4: the other sub-function
	b	7f
4:	cmp	r4, #7				@ temperature: 7 C (unit byte 0), 8 F (non-zero)
	blo	7f
	cmp	r4, #8
	bhi	7f
	ldr	r0, =DMM_TUNIT
	bl	byte_is_set
	sub	r1, r4, #7
	cmp	r0, r1
	beq	7f
	bl	fn_0800d120			@ key 4: the other unit
7:	bl	dmm_function_code
	cmp	r0, r4
	ite	eq
	moveq	r0, #0
	movne	r0, #4
9:	pop	{r4, r5, r6, pc}

dmm_index_of:					@ meter index per PROTOCOL.md function 0..12
	.byte	0, 1, 1, 2, 2, 3, 4, 5, 5, 6, 6, 7, 7
dmm_sub_of:					@ sub-function per function (1 DC / diode, 2 AC / continuity)
	.byte	0, 1, 2, 2, 1, 0, 0, 0, 0, 1, 2, 1, 2
	.p2align 1

@ job_dmm_hold / job_dmm_relative - r0 = payload {on}. Presses key 15 / 7 when the flag differs;
@ status 3 when the key handler did not change it (relative is refused by the meter for auto, diode /
@ continuity and temperature, and while it has no reading).
	.thumb_func
job_dmm_hold:
	push	{r4, r5, r6, lr}
	ldr	r5, =DMM_HOLD_B
	ldr	r6, =fn_0800bd60
	b	1f
	.thumb_func
job_dmm_relative:
	push	{r4, r5, r6, lr}
	ldr	r5, =DMM_REL_B
	ldr	r6, =fn_0800d548
1:	ldrb	r4, [r0]
	bl	dmm_ready
	cbnz	r0, 9f
	mov	r0, r5
	bl	byte_is_set
	cmp	r0, r4
	beq	8f
	blx	r6
	mov	r0, r5
	bl	byte_is_set
	cmp	r0, r4
	beq	8f
	movs	r0, #3
	b	9f
8:	movs	r0, #0
9:	pop	{r4, r5, r6, pc}

@ ============================================================================
@ Oscilloscope (PROTOCOL.md 4.4); jobs run in the key task
@ ============================================================================

@ scope_ready - 0 when the scope page is open, else 3.
	.thumb_func
scope_ready:
	ldr	r0, =UI_PAGE
	ldrb	r0, [r0]
	cmp	r0, #2
	ite	eq
	moveq	r0, #0
	movne	r0, #3
	bx	lr

@ read_var - r0 = address, r1 = kind (0 u8, 1 s8, 2 s16); returns the value sign-extended.
	.thumb_func
read_var:
	cmp	r1, #1
	beq	1f
	bhi	2f
	ldrb	r0, [r0]
	bx	lr
1:	ldrsb	r0, [r0]
	bx	lr
2:	ldrsh	r0, [r0]
	bx	lr

@ step_to - r0 = variable address, r1 = target, r2 = kind (read_var), r3 = 0 keys 11 / 12, 1 keys
@ 13 / 14. Presses the + 1 key (11 / 13) or the - 1 key (12 / 14) until the variable equals the
@ target. Returns 0, or 4 when a press left the variable unchanged (the handler refused) or after
@ 256 presses (the largest range, -100..100, needs 200).
	.thumb_func
step_to:
	push	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r4, r0
	mov	r5, r1
	mov	r6, r2
	mov	r7, r3
	mov	r10, #256
1:	subs	r10, r10, #1
	bmi	7f
	mov	r0, r4
	mov	r1, r6
	bl	read_var
	cmp	r0, r5
	beq	8f
	mov	r8, r0
	bgt	3f
	cbnz	r7, 2f
	bl	fn_0800a148			@ key 11: + 1
	b	5f
2:	bl	fn_0800b1f8			@ key 13: timebase + 1
	b	5f
3:	cbnz	r7, 4f
	bl	fn_0800a900			@ key 12: - 1
	b	5f
4:	bl	fn_0800b7cc			@ key 14: timebase - 1
5:	mov	r0, r4
	mov	r1, r6
	bl	read_var
	cmp	r0, r8
	bne	1b
7:	movs	r0, #4
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}
8:	movs	r0, #0
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}

@ select_value - r0 = selection 0..2, r1 = channel 0 / 1 or 0xFF (any). Presses key 5 until the
@ selection is reached (at most 4 presses) and key 4 when the other channel is selected. Returns 0;
@ 3 when the channel is not enabled alone and cannot be selected; 4 when the keys did not get there.
	.thumb_func
select_value:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	movs	r6, #5
1:	ldr	r0, =SC_SEL
	ldrb	r0, [r0]
	and	r0, r0, #0xF
	cmp	r0, r4
	beq	2f
	subs	r6, #1
	beq	7f
	bl	fn_0800d2f8			@ key 5: next selection
	b	1b
2:	cmp	r5, #0xFF
	beq	8f
	ldr	r0, =SC_SEL
	ldrb	r0, [r0]
	lsrs	r0, r0, #7
	cmp	r0, r5
	beq	8f
	ldr	r0, =SC_ENABLE
	ldrb	r0, [r0]
	cmp	r0, #3
	bne	6f
	bl	fn_0800d120			@ key 4: other channel
	ldr	r0, =SC_SEL
	ldrb	r0, [r0]
	lsrs	r0, r0, #7
	cmp	r0, r5
	beq	8f
7:	movs	r0, #4
	pop	{r4, r5, r6, pc}
6:	movs	r0, #3
	pop	{r4, r5, r6, pc}
8:	movs	r0, #0
	pop	{r4, r5, r6, pc}

@ menu_apply - r0 = menu item (3 CH1, 4 CH2, 5 trigger), r1 = value index. Applies that menu entry
@ through the menu's handler (key 15 on page 9, sub-mode 1): page 9, sub-mode 1, item and value are
@ set, fn_0800bd60 runs, then the page byte (bit 7, the low-battery flag, as it is now) and the three
@ menu bytes are put back. The menu's own redraws do nothing once the page is no longer 9.
	.thumb_func
menu_apply:
	push	{r4, r5, r6, lr}
	ldr	r4, =UI_PAGE
	ldr	r5, [r4]			@ page, sub-mode, item, value (0x20001060..63)
	movs	r2, #9
	strb	r2, [r4, #0]
	movs	r2, #1
	strb	r2, [r4, #1]
	strb	r0, [r4, #2]
	strb	r1, [r4, #3]
	bl	fn_0800bd60
	ldrb	r0, [r4, #0]
	and	r0, r0, #0x80
	and	r1, r5, #0x7F
	orr	r0, r0, r1
	bfi	r5, r0, #0, #8
	str	r5, [r4]
	pop	{r4, r5, r6, pc}

@ SCOPE_TIMEBASE: index 0..28.
	.global	cmd_scope_timebase
	.thumb_func
cmd_scope_timebase:
	cmp	r6, #1
	bne	9f
	ldrb	r0, [r5]
	cmp	r0, #28
	bhi	9f
	ldr	r0, =job_scope_timebase
	movs	r1, #0
	b	job_then_state
9:	movs	r0, #2
	b	answer_status

	.thumb_func
job_scope_timebase:
	push	{r4, lr}
	ldrb	r4, [r0]
	bl	scope_ready
	cbnz	r0, 9f
	movs	r0, #0
	movs	r1, #0xFF
	bl	select_value
	cbnz	r0, 9f
	ldr	r0, =SC_TIMEBASE
	mov	r1, r4
	movs	r2, #0
	movs	r3, #1
	bl	step_to
9:	pop	{r4, pc}

@ SCOPE_CHANNEL: channel 0 / 1, enabled 0 / 1, V/div step 0..9, offset s8 -100..100, coupling 0 AC /
@ 1 DC, probe 0 x1 / 1 x10, FFT 0 / 1.
	.global	cmd_scope_channel
	.thumb_func
cmd_scope_channel:
	cmp	r6, #7
	bne	9f
	ldrb	r0, [r5, #0]
	cmp	r0, #1
	bhi	9f
	ldrb	r0, [r5, #1]
	cmp	r0, #1
	bhi	9f
	ldrb	r0, [r5, #2]
	cmp	r0, #9
	bhi	9f
	ldrsb	r0, [r5, #3]
	cmn	r0, #100
	blt	9f
	cmp	r0, #100
	bgt	9f
	ldrb	r0, [r5, #4]
	ldrb	r1, [r5, #5]
	orrs	r0, r0, r1
	ldrb	r1, [r5, #6]
	orrs	r0, r0, r1
	cmp	r0, #1
	bhi	9f
	ldr	r0, =job_scope_channel
	movs	r1, #0
	b	job_then_state
9:	movs	r0, #2
	b	answer_status

@ job_scope_channel - r0 = payload. Enables the channel first (menu entry 0), sets probe, coupling
@ and FFT (menu entries 1..3, each a toggle, applied only when the value differs), the V/div step
@ (selection 0) and the offset (selection 1) with keys 11 / 12 while the channel is on (status 3 when
@ they differ on a channel that is off), and disables the channel last. A menu change ends with
@ send_state_message_sequence, the scope page's full redraw (as when the menu is closed).
	.thumb_func
job_scope_channel:
	push	{r4, r5, r6, r7, r8, lr}
	mov	r4, r0				@ r4 = payload
	movs	r8, #0				@ r8 = 1 once a menu entry was applied
	bl	scope_ready
	cmp	r0, #0
	bne	9f
	ldrb	r5, [r4, #0]			@ r5 = channel
	add	r6, r5, #3			@ r6 = menu item 3 / 4
	movs	r7, #1
	lsl	r7, r7, r5			@ r7 = enable bit
	ldrb	r0, [r4, #1]
	cbz	r0, 1f
	ldr	r0, =SC_ENABLE
	ldrb	r0, [r0]
	tst	r0, r7
	bne	1f
	mov	r0, r6
	movs	r1, #0
	bl	menu_apply			@ enable
	movs	r8, #1
1:	ldr	r0, =SC_PROBE
	ldrb	r0, [r0, r5]
	ldrb	r1, [r4, #5]
	cmp	r0, r1
	beq	2f
	mov	r0, r6
	movs	r1, #1
	bl	menu_apply			@ probe
	movs	r8, #1
2:	ldr	r0, =SC_COUPLING
	ldrb	r0, [r0, r5]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	ldrb	r1, [r4, #4]
	cmp	r0, r1
	beq	3f
	mov	r0, r6
	movs	r1, #2
	bl	menu_apply			@ coupling
	movs	r8, #1
3:	ldr	r0, =SC_FFT
	ldrb	r0, [r0, r5]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	ldrb	r1, [r4, #6]
	cmp	r0, r1
	beq	4f
	mov	r0, r6
	movs	r1, #3
	bl	menu_apply			@ FFT
	movs	r8, #1
4:	cmp	r8, #0
	beq	41f
	bl	scope_redraw
41:	ldr	r0, =SC_ENABLE
	ldrb	r0, [r0]
	tst	r0, r7
	beq	6f
	movs	r0, #0				@ V/div step at selection 0
	mov	r1, r5
	bl	select_value
	cbnz	r0, 9f
	ldr	r0, =SC_VDIV
	add	r0, r0, r5
	ldrb	r1, [r4, #2]
	movs	r2, #0
	movs	r3, #0
	bl	step_to
	cbnz	r0, 9f
	movs	r0, #1				@ offset at selection 1
	mov	r1, r5
	bl	select_value
	cbnz	r0, 9f
	ldr	r0, =SC_OFFSET
	add	r0, r0, r5
	ldrsb	r1, [r4, #3]
	movs	r2, #1
	movs	r3, #0
	bl	step_to
	cbnz	r0, 9f
	ldrb	r0, [r4, #1]			@ disable last
	cbnz	r0, 8f
	mov	r0, r6
	movs	r1, #0
	bl	menu_apply
	bl	scope_redraw
	b	8f
6:	ldr	r0, =SC_VDIV			@ channel off: V/div and offset cannot be changed
	ldrb	r0, [r0, r5]
	ldrb	r1, [r4, #2]
	cmp	r0, r1
	bne	7f
	ldr	r0, =SC_OFFSET
	ldrsb	r0, [r0, r5]
	ldrsb	r1, [r4, #3]
	cmp	r0, r1
	beq	8f
7:	movs	r0, #3
	b	9f
8:	movs	r0, #0
9:	pop	{r4, r5, r6, r7, r8, pc}

@ scope_redraw - the scope page's full redraw: send_state_message_sequence for the current page.
	.thumb_func
scope_redraw:
	b	send_state_message_sequence

@ SCOPE_TRIGGER: source 0 CH1 / 1 CH2, edge 0 / 1, level s16 -100..100, mode 0 normal / 1 auto /
@ 2 single.
	.global	cmd_scope_trigger
	.thumb_func
cmd_scope_trigger:
	cmp	r6, #5
	bne	9f
	ldrb	r0, [r5, #0]
	ldrb	r1, [r5, #1]
	orrs	r0, r0, r1
	cmp	r0, #1
	bhi	9f
	ldrsh	r0, [r5, #2]
	cmn	r0, #100
	blt	9f
	cmp	r0, #100
	bgt	9f
	ldrb	r0, [r5, #4]
	cmp	r0, #2
	bhi	9f
	ldr	r0, =job_scope_trigger
	movs	r1, #0
	b	job_then_state
9:	movs	r0, #2
	b	answer_status

@ job_scope_trigger - r0 = payload. Source (menu entry 2; only while both channels are on, as in the
@ menu: status 3 otherwise), edge (entry 1, toggles 0 / 1), mode (entry 0, cycles 0 -> 1 -> 2), then
@ the level (selection 2, keys 11 / 12).
	.thumb_func
job_scope_trigger:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r6, #0				@ r6 = 1 once a menu entry was applied
	bl	scope_ready
	cmp	r0, #0
	bne	9f
	ldr	r0, =SC_TSOURCE
	ldrb	r0, [r0]
	ldrb	r1, [r4, #0]
	cmp	r0, r1
	beq	1f
	ldr	r0, =SC_ENABLE
	ldrb	r0, [r0]
	cmp	r0, #3
	bne	7f
	movs	r0, #5
	movs	r1, #2
	bl	menu_apply			@ source
	movs	r6, #1
1:	movs	r5, #3				@ edge: at most 2 toggles
2:	ldr	r0, =SC_TEDGE
	ldrb	r0, [r0]
	ldrb	r1, [r4, #1]
	cmp	r0, r1
	beq	3f
	subs	r5, #1
	beq	6f
	movs	r0, #5
	movs	r1, #1
	bl	menu_apply
	movs	r6, #1
	b	2b
3:	movs	r5, #4				@ mode: at most 3 steps
4:	ldr	r0, =SC_TMODE
	ldrb	r0, [r0]
	ldrb	r1, [r4, #4]
	cmp	r0, r1
	beq	5f
	subs	r5, #1
	beq	6f
	movs	r0, #5
	movs	r1, #0
	bl	menu_apply
	movs	r6, #1
	b	4b
5:	cbz	r6, 51f
	bl	scope_redraw
51:	movs	r0, #2				@ level at selection 2
	movs	r1, #0xFF
	bl	select_value
	cbnz	r0, 9f
	ldr	r0, =SC_TLEVEL
	ldrsh	r1, [r4, #2]
	movs	r2, #2
	movs	r3, #0
	bl	step_to
	b	9f
6:	movs	r0, #4
	b	9f
7:	movs	r0, #3
9:	pop	{r4, r5, r6, pc}

@ SCOPE_TABLES: the timebase texts (29, index order) and the V/div texts (13, index probe * 3 +
@ step), each zero-terminated, after the two counts. From the firmware's own text tables
@ (d_0804c988 timebase, 29 words; d_0804c954 V/div, 13 words).
	.global	cmd_scope_tables
	.thumb_func
cmd_scope_tables:
	push	{r4, r5, r6, r7, r8, lr}
	ldr	r4, =ANSWER + 1
	movs	r0, #29
	strb	r0, [r4], #1
	movs	r0, #13
	strb	r0, [r4], #1
	ldr	r5, =d_0804c988
	movs	r6, #29
	bl	copy_texts
	ldr	r5, =d_0804c954
	movs	r6, #13
	bl	copy_texts
	ldr	r1, =ANSWER
	sub	r1, r4, r1
	movs	r0, #0
	bl	answer
	pop	{r4, r5, r6, r7, r8, pc}

@ copy_texts - r5 = word table, r6 = count, r4 = output (advanced): copies each text with its zero.
	.thumb_func
copy_texts:
1:	ldr	r0, [r5], #4
2:	ldrb	r1, [r0], #1
	strb	r1, [r4], #1
	cmp	r1, #0
	bne	2b
	subs	r6, #1
	bne	1b
	bx	lr

@ SCOPE_RUN: 0 stop, 1 run (key 15 when it differs). Single shots are trigger mode 2 + run.
	.global	cmd_scope_run
	.thumb_func
cmd_scope_run:
	cmp	r6, #1
	bne	9f
	ldrb	r0, [r5]
	cmp	r0, #1
	bhi	9f
	ldr	r0, =job_scope_run
	movs	r1, #0
	b	job_then_state
9:	movs	r0, #2
	b	answer_status

	.thumb_func
job_scope_run:
	push	{r4, lr}
	ldrb	r4, [r0]
	bl	scope_ready
	cbnz	r0, 9f
	ldr	r0, =SC_RUNNING
	bl	byte_is_set
	cmp	r0, r4
	beq	8f
	bl	fn_0800bd60			@ key 15: run / stop
8:	movs	r0, #0
9:	pop	{r4, pc}

@ SCOPE_AUTOSET (key 2) / SCOPE_AUTOCORRECT (key 16): started; the scope runs them by itself (STATE
@ shows the page; other scope commands answer status 4 until they are done).
	.global	cmd_scope_autoset
	.thumb_func
cmd_scope_autoset:
	ldr	r0, =job_scope_autoset
	b	1f
	.global	cmd_scope_autocorrect
	.thumb_func
cmd_scope_autocorrect:
	ldr	r0, =job_scope_autocorrect
1:	cbnz	r6, 9f
	movs	r1, #0
	b	job_then_state
9:	movs	r0, #2
	b	answer_status

	.thumb_func
job_scope_autoset:
	push	{r4, lr}
	ldr	r4, =fn_0800cb50
	b	1f
	.thumb_func
job_scope_autocorrect:
	push	{r4, lr}
	ldr	r4, =fn_0800df58
1:	bl	scope_ready
	cbnz	r0, 9f
	blx	r4
	movs	r0, #0
9:	pop	{r4, pc}

@ SCOPE_WAVE: channel 0 / 1. Answer: channel, timebase, V/div step, probe, coupling, offset (s8),
@ enabled, running, start (u16), count (u16), the 301 display samples (128 = centre). Copied with the
@ scheduler suspended, so the samples are one consistent set.
	.global	cmd_scope_wave
	.thumb_func
cmd_scope_wave:
	push	{r4, r5, r6, lr}
	cmp	r6, #1
	bne	9f
	ldrb	r5, [r5]
	cmp	r5, #1
	bhi	9f
	ldr	r4, =ANSWER
	bl	sched_suspend
	strb	r5, [r4, #1]
	ldr	r0, =SC_TIMEBASE
	ldrb	r0, [r0]
	strb	r0, [r4, #2]
	ldr	r0, =SC_VDIV
	ldrb	r0, [r0, r5]
	strb	r0, [r4, #3]
	ldr	r0, =SC_PROBE
	ldrb	r0, [r0, r5]
	strb	r0, [r4, #4]
	ldr	r0, =SC_COUPLING
	ldrb	r0, [r0, r5]
	strb	r0, [r4, #5]
	ldr	r0, =SC_OFFSET
	ldrb	r0, [r0, r5]
	strb	r0, [r4, #6]
	ldr	r0, =SC_ENABLE
	ldrb	r0, [r0]
	lsrs	r0, r0, r5
	and	r0, r0, #1
	strb	r0, [r4, #7]
	ldr	r0, =SC_RUNNING
	bl	byte_is_set
	strb	r0, [r4, #8]
	ldr	r0, =SC_START
	ldrh	r1, [r0, #0]
	strh	r1, [r4, #9]
	ldrh	r1, [r0, #2]
	strh	r1, [r4, #11]
	ldr	r0, =SC_SAMPLES
	movw	r1, #0x12D
	mla	r0, r1, r5, r0
	add	r2, r4, #13
	movw	r3, #0x12D
1:	ldrb	r1, [r0], #1
	strb	r1, [r2], #1
	subs	r3, #1
	bne	1b
	bl	sched_resume
	movs	r0, #0
	movw	r1, #13 + 0x12D
	bl	answer
	pop	{r4, r5, r6, pc}
9:	movs	r0, #2
	bl	answer_status
	pop	{r4, r5, r6, pc}

@ ============================================================================
@ Settings (PROTOCOL.md 4.8)
@ ============================================================================

@ SETTINGS_GET: backlight, sound, auto shutdown, startup option.
	.global	cmd_settings_get
	.thumb_func
cmd_settings_get:
	push	{r4, lr}
	bl	settings_answer
	pop	{r4, pc}

@ settings_answer - answers status 0 and the four settings.
	.thumb_func
settings_answer:
	ldr	r2, =ANSWER
	ldr	r0, =SET_BACKLIGHT
	ldrb	r1, [r0, #0]
	strb	r1, [r2, #1]
	ldrb	r1, [r0, #1]			@ 0x2000105A sound
	strb	r1, [r2, #2]
	ldrb	r1, [r0, #4]			@ 0x2000105D auto shutdown
	strb	r1, [r2, #3]
	ldrb	r1, [r0, #3]			@ 0x2000105C startup option
	strb	r1, [r2, #4]
	movs	r0, #0
	movs	r1, #5
	b	answer

@ SETTINGS_SET: the same four values (backlight 25..100, sound 0..10, auto shutdown 0..3, startup
@ option 0..2), in effect at once (backlight register written as the backlight keys do), not saved.
	.global	cmd_settings_set
	.thumb_func
cmd_settings_set:
	push	{r4, lr}
	cmp	r6, #4
	bne	9f
	ldrb	r0, [r5, #0]
	cmp	r0, #25
	blo	9f
	cmp	r0, #100
	bhi	9f
	ldrb	r0, [r5, #1]
	cmp	r0, #10
	bhi	9f
	ldrb	r0, [r5, #2]
	cmp	r0, #3
	bhi	9f
	ldrb	r0, [r5, #3]
	cmp	r0, #2
	bhi	9f
	ldr	r4, =SET_BACKLIGHT
	ldrb	r0, [r5, #0]
	strb	r0, [r4, #0]
	ldr	r1, =BACKLIGHT_PWM
	str	r0, [r1]
	ldrb	r0, [r5, #1]
	strb	r0, [r4, #1]
	ldrb	r0, [r5, #2]
	strb	r0, [r4, #4]
	ldrb	r0, [r5, #3]
	strb	r0, [r4, #3]
	bl	settings_answer
	pop	{r4, pc}
9:	movs	r0, #2
	bl	answer_status
	pop	{r4, pc}

@ SETTINGS_SAVE: answers, takes the meter off the bus and calls save_settings_to_flash(0x55), the
@ vendor's settings write (it never returns); its end, settings_saved, restarts the meter instead of
@ switching it off because V_SAVERST is set.
	.global	cmd_settings_save
	.thumb_func
cmd_settings_save:
	cbnz	r6, 9f
	push	{r4, lr}
	movs	r0, #0
	bl	answer_status
	bl	drain_and_disconnect
	ldr	r0, =V
	movs	r1, #1
	strb	r1, [r0, #V_SAVERST]
	movs	r0, #0x55
	bl	save_settings_to_flash
1:	b	1b				@ not reached
9:	movs	r0, #2
	b	answer_status

@ settings_saved - the end of save_settings_to_flash (settings_53.s, interrupts off, page written):
@ restart when the save came from SETTINGS_SAVE (PC9, the power hold, stays high, so the meter stays
@ on also on battery); else PC9 low (0x40011014 = bit 9, the vendor's power off) and power_off_wait as
@ for the power key.
	.global	settings_saved
	.thumb_func
	.type	settings_saved, %function
settings_saved:
	ldr	r0, =V
	ldrb	r1, [r0, #V_SAVERST]
	cbz	r1, 1f
	movs	r1, #0
	strb	r1, [r0, #V_SAVERST]
	ldr	r0, =0xE000ED0C			@ AIRCR: VECTKEY | SYSRESETREQ
	ldr	r1, =0x05FA0004
	dsb
	str	r1, [r0]
	dsb
2:	b	2b
1:	ldr	r0, =0x40011014			@ port C bit clear: PC9 low
	mov	r1, #0x200
	str	r1, [r0]
	b	power_off_wait

@ ============================================================================
@ Screen (PROTOCOL.md 4.9); the job runs in the display task
@ ============================================================================

@ SCREENSHOT: the display task (the only writer of the LCD) reads the screen back half a row at a
@ time and sends each as a stream frame (cmd 0x60: offset u32, 320 bytes RGB565); nothing is drawn
@ meanwhile, so the image is one consistent picture. Then the answer: total (u32, 153600), width
@ (u16 320), height (u16 240), format (u8 0 = RGB565).
	.global	cmd_screenshot
	.thumb_func
cmd_screenshot:
	push	{r4, lr}
	cbnz	r6, 9f
	ldr	r0, =job_screenshot
	movs	r1, #1
	bl	run_job
	cbnz	r0, 8f
	ldr	r2, =ANSWER
	movs	r0, #0
	movt	r0, #2				@ 0x00025800 = 153600 bytes
	movw	r1, #0x5800
	orr	r0, r0, r1
	str	r0, [r2, #1]
	movw	r0, #320
	strh	r0, [r2, #5]
	movs	r0, #240
	strh	r0, [r2, #7]
	movs	r0, #0
	strb	r0, [r2, #9]
	movs	r1, #10
	bl	answer
	pop	{r4, pc}
8:	bl	answer_status
	pop	{r4, pc}
9:	movs	r0, #2
	bl	answer_status
	pop	{r4, pc}

@ job_screenshot - display task. For y = 0..239, x = 0 / 160: rectangle (x, y, 160, 1) through
@ fn_080097e8 into ANSWER + 4 (free while the usb task waits), offset in front, stream frame.
	.thumb_func
job_screenshot:
	push	{r4, r5, r6, r7, r8, lr}
	ldr	r4, =LCD_RECT
	ldr	r5, =ANSWER
	movs	r6, #0				@ r6 = y
	movs	r7, #0				@ r7 = byte offset in the image
1:	movs	r8, #0				@ r8 = x
2:	strh	r8, [r4, #0]
	strh	r6, [r4, #2]
	movs	r0, #160
	strh	r0, [r4, #4]
	movs	r0, #1
	strh	r0, [r4, #6]
	add	r0, r5, #4
	str	r0, [r4, #8]
	bl	fn_080097e8
	str	r7, [r5, #0]
	bl	tx_room_or_timeout		@ the host stopped reading: give up (status 4)
	cbz	r0, 9f
	movs	r0, #3				@ stream frame, cmd 0x60
	movs	r1, #0x60
	mov	r2, r5
	movw	r3, #4 + 320
	bl	send_frame
	add	r7, r7, #320
	add	r8, r8, #160
	cmp	r8, #320
	blo	2b
	adds	r6, #1
	cmp	r6, #240
	blo	1b
	movs	r0, #0
	pop	{r4, r5, r6, r7, r8, pc}
9:	movs	r0, #4
	pop	{r4, r5, r6, r7, r8, pc}

@ tx_room_or_timeout - waits (1 tick at a time, at most 1000) until the tx ring has room for one
@ screenshot frame (332 bytes) or the host is no longer configured; r0 = 1 room, 0 timeout.
	.thumb_func
tx_room_or_timeout:
	push	{r4, r5, r6, lr}
	ldr	r4, =V
	movw	r5, #1000
1:	ldrb	r0, [r4, #V_CONF]
	cbz	r0, 8f				@ not configured: send_frame drops the frame, no wait
	ldr	r0, [r4, #V_TXH]		@ free = tail - head - 1 (mod 1024)
	ldr	r1, [r4, #V_TXT]
	sub	r1, r1, r0
	subs	r1, #1
	bfc	r1, #10, #22
	cmp	r1, #332
	bhs	8f
	subs	r5, #1
	beq	9f
	movs	r0, #1
	bl	fn_08041390
	b	1b
8:	movs	r0, #1
	pop	{r4, r5, r6, pc}
9:	movs	r0, #0
	pop	{r4, r5, r6, pc}

@ ============================================================================
@ Files (PROTOCOL.md 4.10); usb task, multi-call sequences under the storage lock (src/storage.s)
@ ============================================================================

@ path_arg - r0 = text, r1 = its length (from the payload). Zero-terminates it in place (the frame
@ buffer has room after the payload: the CRC is already checked). Returns r0 = the path, or 0 when
@ it is empty or the drive is not "2:" (drive 3: holds the firmware's system files; 0: and 1: are
@ not mounted). Used by FILE_DELETE and FILE_WRITE.
@ path_arg_read - the same, but drive "3:" is allowed too (FILE_LIST, FILE_READ: reading the system
@ files changes nothing).
@ Both change r0..r3 only.
	.thumb_func
path_arg:
	movs	r2, #'2'			@ r2 = highest drive digit allowed
	b	1f
	.thumb_func
path_arg_read:
	movs	r2, #'3'
1:	cbz	r1, 9f
	movs	r3, #0
	strb	r3, [r0, r1]
	ldrb	r3, [r0, #0]
	cmp	r3, #'2'
	blo	9f
	cmp	r3, r2
	bhi	9f
	ldrb	r3, [r0, #1]
	cmp	r3, #':'
	bne	9f
	bx	lr
9:	movs	r0, #0
	bx	lr

@ path_arg_write - FILE_WRITE's path check: r0 = text, r1 = its length. Returns r0 = the path when
@ path_arg accepts it (drive 2:) or when it is exactly "3:/System file/" followed by 1 to 3 decimal
@ digits and ".jpg" (the user-interface pictures the firmware draws, NNN.jpg; nothing else on
@ drive 3: can be written, so the directory, 9999.bin and the volume itself stay as they are);
@ else 0. Changes r0..r3, r12.
	.thumb_func
path_arg_write:
	push	{r4, r5, r6, lr}
	mov	r4, r0				@ r4 = scan pointer
	mov	r5, r0				@ r5 = the text
	bl	path_arg			@ zero-terminates the text
	cbnz	r0, 8f
	ldr	r1, =sysjpg_prefix		@ r1 = "3:/System file/", compared up to its zero
1:	ldrb	r2, [r1], #1
	cbz	r2, 2f
	ldrb	r3, [r4], #1
	cmp	r2, r3
	bne	9f
	b	1b
2:	mov	r12, #0				@ r12 = digits
3:	ldrb	r3, [r4]
	sub	r2, r3, #'0'
	cmp	r2, #9
	bhi	4f
	adds	r4, #1
	add	r12, r12, #1
	b	3b
4:	cmp	r12, #1
	blo	9f
	cmp	r12, #3
	bhi	9f
	ldr	r1, =sysjpg_suffix		@ ".jpg" and the terminating zero
5:	ldrb	r2, [r1], #1
	ldrb	r3, [r4], #1
	cmp	r2, r3
	bne	9f
	cmp	r2, #0
	bne	5b
	mov	r0, r5				@ r0 = the path
8:	pop	{r4, r5, r6, pc}
9:	movs	r0, #0
	pop	{r4, r5, r6, pc}

sysjpg_prefix:	.asciz	"3:/System file/"
sysjpg_suffix:	.asciz	".jpg"
	.p2align 1

@ files_ready - 0 when file access is allowed, else 3 (drive shared with the host).
	.thumb_func
files_ready:
	ldr	r0, =V
	ldrb	r0, [r0, #V_SHARED]
	cmp	r0, #0
	it	ne
	movne	r0, #3
	bx	lr

@ FILE_LIST: first entry index (u16), directory path. Answer: next index (u16, 0xFFFF = no more
@ entries), then entries {size u32, attribute u8, name length u8, name} until the frame is full.
	.global	cmd_file_list
	.thumb_func
cmd_file_list:
	push	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #4
	bl	files_ready
	cmp	r0, #0
	bne	90f
	cmp	r6, #3
	blo	92f
	ldrh	r9, [r5, #0]			@ r9 = entries to skip
	add	r0, r5, #2
	sub	r1, r6, #2
	bl	path_arg_read
	cmp	r0, #0
	beq	92f
	mov	r10, r0				@ r10 = path
	movs	r0, #0x30			@ directory object
	bl	alloc_units_of_32_bytes
	mov	r7, r0
	cmp	r0, #0
	beq	95f
	movw	r0, #0x118			@ entry record
	bl	alloc_units_of_32_bytes
	mov	r8, r0
	cmp	r0, #0
	beq	94f
	ldr	r4, =ANSWER + 3			@ r4 = output, entries
	movs	r11, #0				@ r11 = index of the entry being read
	bl	storage_lock
	mov	r0, r7
	mov	r1, r10
	bl	dir_open
	cmp	r0, #0
	bne	93f
1:	mov	r0, r7				@ next entry
	mov	r1, r8
	bl	dir_read_entry
	cmp	r0, #0
	bne	6f
	ldrb	r0, [r8, #0x16]
	cbz	r0, 5f				@ end of directory
	cmp	r11, r9
	blo	4f				@ still skipping
	add	r0, r8, #0x16			@ name length
	movs	r1, #0
2:	ldrb	r2, [r0, r1]
	cbz	r2, 3f
	adds	r1, #1
	cmp	r1, #255
	blo	2b
3:	ldr	r2, =ANSWER + 512
	sub	r2, r2, r4
	add	r3, r1, #6
	cmp	r3, r2
	bhi	7f				@ does not fit: the next answer starts here
	ldr	r2, [r8, #0]
	str	r2, [r4, #0]
	ldrb	r2, [r8, #8]
	strb	r2, [r4, #4]
	strb	r1, [r4, #5]
	adds	r4, #6
	add	r0, r8, #0x16
21:	cbz	r1, 4f
	ldrb	r2, [r0], #1
	strb	r2, [r4], #1
	subs	r1, #1
	b	21b
4:	add	r11, r11, #1
	b	1b
5:	movw	r11, #0xFFFF			@ no more entries
7:	mov	r0, r7
	bl	object_release
	bl	storage_unlock
	ldr	r0, =ANSWER
	strh	r11, [r0, #1]
	mov	r0, r8
	bl	free_units_of_32_bytes
	mov	r0, r7
	bl	free_units_of_32_bytes
	ldr	r1, =ANSWER
	sub	r1, r4, r1
	movs	r0, #0
	bl	answer
	b	99f
6:	mov	r0, r7				@ read error
	bl	object_release
93:	bl	storage_unlock			@ open error
	mov	r0, r8
	bl	free_units_of_32_bytes
94:	mov	r0, r7
	bl	free_units_of_32_bytes
95:	movs	r0, #5
	bl	answer_status
	b	99f
92:	movs	r0, #2
90:	bl	answer_status
99:	add	sp, #4
	pop	{r4, r5, r6, r7, r8, r9, r10, r11, pc}

@ FILE_READ: offset (u32), path (at most 95 characters). Answer: total (u32, the file size), then up
@ to 500 bytes from the offset (none at or past the end). The file stays open (V_ROBJ, its path kept
@ behind the file object) while the host reads it in order: a request for the same path at the next
@ offset continues without opening and seeking again. It is closed at the end of the file, by any
@ other command (dispatch), when the drive is shared and before power-off / reset.
	.equ	RPATH,		0x102C		@ path copy behind the file object
	.global	cmd_file_read
	.thumb_func
cmd_file_read:
	push	{r4, r5, r6, r7, r8, lr}
	sub	sp, #8
	bl	files_ready
	cmp	r0, #0
	bne	90f
	cmp	r6, #5
	blo	92f
	ldr	r8, [r5, #0]			@ r8 = offset
	sub	r1, r6, #4
	cmp	r1, #PATH_BUF_SIZE
	bhs	92f
	add	r0, r5, #4
	bl	path_arg_read
	cmp	r0, #0
	beq	92f
	mov	r6, r0				@ r6 = path
	ldr	r4, =V				@ r4 = V
	ldr	r7, [r4, #V_ROBJ]		@ r7 = file object
	cbz	r7, 10f
	movw	r0, #RPATH			@ open already: same file at this offset?
	add	r0, r0, r7
	mov	r1, r6
	bl	str_equal
	cbz	r0, 5f
	ldr	r0, [r4, #V_RPOS]
	cmp	r0, r8
	bne	5f
	bl	storage_lock
	b	30f
5:	bl	read_close
10:	movw	r0, #RPATH + PATH_BUF_SIZE
	bl	alloc_units_of_32_bytes
	mov	r7, r0
	cmp	r0, #0
	beq	95f
	movw	r0, #RPATH			@ keep the path
	add	r0, r0, r7
	movs	r1, #0
11:	ldrb	r2, [r6, r1]
	strb	r2, [r0, r1]
	adds	r1, #1
	cmp	r2, #0
	bne	11b
	bl	storage_lock
	mov	r0, r7
	mov	r1, r6
	movs	r2, #1				@ read
	bl	file_open
	cmp	r0, #0
	bne	93f
	str	r7, [r4, #V_ROBJ]
	cmp	r8, #0
	beq	30f
	ldr	r5, [r7, #0x0C]
	cmp	r8, r5
	bhs	30f
	mov	r0, r7
	mov	r1, r8
	bl	file_seek
	cmp	r0, #0
	bne	94f
30:	ldr	r5, [r7, #0x0C]			@ r5 = size
	ldr	r0, =ANSWER
	str	r5, [r0, #1]
	movs	r0, #0
	str	r0, [sp]
	cmp	r8, r5
	bhs	40f
	sub	r2, r5, r8
	cmp	r2, #FILE_CHUNK
	it	hi
	movhi	r2, #FILE_CHUNK
	mov	r0, r7
	ldr	r1, =ANSWER + 5
	mov	r3, sp
	bl	file_read
	cmp	r0, #0
	bne	94f
40:	ldr	r0, [sp]
	add	r8, r8, r0
	str	r8, [r4, #V_RPOS]
	cmp	r8, r5
	blo	41f
	bl	read_close			@ end of the file
41:	bl	storage_unlock
	ldr	r1, [sp]
	adds	r1, #5
	movs	r0, #0
	bl	answer
	b	99f
94:	bl	read_close			@ seek / read error
	bl	storage_unlock
	b	95f
93:	bl	storage_unlock			@ open error
	mov	r0, r7
	bl	free_units_of_32_bytes
95:	movs	r0, #5
	bl	answer_status
	b	99f
92:	movs	r0, #2
90:	bl	answer_status
99:	add	sp, #8
	pop	{r4, r5, r6, r7, r8, pc}

@ read_close - closes and frees the FILE_READ file (nothing when none). Any task context.
	.global	read_close
	.thumb_func
read_close:
	push	{r4, lr}
	ldr	r4, =V
	ldr	r0, [r4, #V_ROBJ]
	cbz	r0, 1f
	bl	file_close
	ldr	r0, [r4, #V_ROBJ]
	bl	free_units_of_32_bytes
	movs	r0, #0
	str	r0, [r4, #V_ROBJ]
1:	pop	{r4, pc}

@ str_equal - r0, r1 = zero-terminated texts; r0 = 1 when equal, else 0.
	.thumb_func
str_equal:
1:	ldrb	r2, [r0], #1
	ldrb	r3, [r1], #1
	cmp	r2, r3
	bne	2f
	cmp	r2, #0
	bne	1b
	movs	r0, #1
	bx	lr
2:	movs	r0, #0
	bx	lr

@ FILE_WRITE: offset (u32), total (u32), path (zero-terminated), chunk. Offset 0 creates / truncates
@ the file and keeps it open (on drive 3: only a picture that is already there: status 6 otherwise,
@ so the names with leading zeros and new files cannot fill the system drive); each further chunk must continue at the bytes written so far; the file
@ is closed when the total is reached (or by a new offset 0, or by FILE_DELETE).
	.global	cmd_file_write
	.thumb_func
cmd_file_write:
	push	{r4, r5, r6, r7, r8, lr}
	sub	sp, #8
	ldr	r4, =V
	bl	files_ready
	cmp	r0, #0
	bne	90f
	cmp	r6, #10
	blo	92f
	add	r7, r5, #8			@ r7 = path
	sub	r1, r6, #8			@ path length up to its zero
	movs	r2, #0
1:	cmp	r2, r1
	bhs	92f				@ no zero: bad request
	ldrb	r3, [r7, r2]
	cbz	r3, 2f
	adds	r2, #1
	b	1b
2:	add	r8, r7, r2
	add	r8, r8, #1			@ r8 = chunk
	sub	r6, r1, r2
	subs	r6, #1				@ r6 = chunk length
	ldr	r0, [r5, #0]
	cbnz	r0, 4f
	mov	r0, r7				@ offset 0: open
	mov	r1, r2
	bl	path_arg_write			@ drive 2:, or 3:/System file/NNN.jpg
	cmp	r0, #0
	beq	96f
	bl	write_close
	ldr	r0, [r5, #4]
	str	r0, [r4, #V_WTOT]
	movs	r0, #0
	str	r0, [r4, #V_WPOS]
	movw	r0, #0x102C
	bl	alloc_units_of_32_bytes
	cmp	r0, #0
	beq	95f
	str	r0, [r4, #V_WOBJ]
	bl	storage_lock
	ldrb	r0, [r7]			@ drive 3: only pictures that exist are replaced, none added
	cmp	r0, #'3'
	bne	3f
	ldr	r0, [r4, #V_WOBJ]
	mov	r1, r7
	movs	r2, #1				@ read, open existing: fails when the file is not there
	bl	file_open
	cmp	r0, #0
	bne	97f
	ldr	r0, [r4, #V_WOBJ]
	bl	file_close
3:	ldr	r0, [r4, #V_WOBJ]
	mov	r1, r7
	movs	r2, #10				@ write, create / truncate
	bl	file_open
	mov	r7, r0
	bl	storage_unlock
	cbz	r7, 5f
	bl	write_free
	b	95f
4:	ldr	r1, [r4, #V_WOBJ]		@ continuation
	cmp	r1, #0
	beq	91f
	ldr	r1, [r4, #V_WPOS]
	cmp	r0, r1
	bne	92f
5:	ldr	r0, [r4, #V_WPOS]
	add	r0, r0, r6
	ldr	r1, [r4, #V_WTOT]
	cmp	r0, r1
	bhi	92f
	cbz	r6, 6f
	bl	storage_lock
	ldr	r0, [r4, #V_WOBJ]
	mov	r1, r8
	mov	r2, r6
	mov	r3, sp
	bl	file_write
	mov	r7, r0
	bl	storage_unlock
	cmp	r7, #0
	bne	94f
	ldr	r0, [sp]
	cmp	r0, r6
	bne	94f
	ldr	r0, [r4, #V_WPOS]
	add	r0, r0, r6
	str	r0, [r4, #V_WPOS]
6:	ldr	r0, [r4, #V_WPOS]
	ldr	r1, [r4, #V_WTOT]
	cmp	r0, r1
	bne	7f
	bl	write_close			@ complete
7:	movs	r0, #0
	b	90f
94:	bl	write_close
95:	movs	r0, #5
	b	90f
97:	bl	storage_unlock			@ no such picture on 3:
	bl	write_free
96:	movs	r0, #6				@ path not allowed
	b	90f
91:	movs	r0, #3				@ no file open
	b	90f
92:	movs	r0, #2
90:	bl	answer_status
	add	sp, #8
	pop	{r4, r5, r6, r7, r8, pc}

@ write_close - closes and frees the FILE_WRITE file (nothing when none). write_free - frees only.
	.global	write_close
	.thumb_func
write_close:
	push	{r4, lr}
	ldr	r4, =V
	ldr	r0, [r4, #V_WOBJ]
	cbz	r0, 1f
	bl	storage_lock
	ldr	r0, [r4, #V_WOBJ]
	bl	file_close
	bl	storage_unlock
	bl	write_free
1:	pop	{r4, pc}

	.thumb_func
write_free:
	push	{r4, lr}
	ldr	r4, =V
	ldr	r0, [r4, #V_WOBJ]
	cbz	r0, 1f
	bl	free_units_of_32_bytes
	movs	r0, #0
	str	r0, [r4, #V_WOBJ]
1:	pop	{r4, pc}

@ FILE_DELETE: path (a file or an empty directory on drive 2:, at most 95 characters). Runs as a
@ display-task job: path_delete takes its path from the buffer 0x20008360, which the vendor's
@ display-task code fills outside any file call, so only that task may use it. OK when afterwards
@ neither file_open nor dir_open finds the path; status 5 otherwise (e.g. a directory that is not
@ empty).
	.global	cmd_file_delete
	.thumb_func
cmd_file_delete:
	push	{r4, lr}
	bl	files_ready
	cmp	r0, #0
	bne	90f
	cmp	r6, #PATH_BUF_SIZE
	bhs	92f
	mov	r0, r5
	mov	r1, r6
	bl	path_arg			@ zero-terminates the path in the frame buffer
	cmp	r0, #0
	beq	96f
	ldr	r0, =job_file_delete
	movs	r1, #1
	bl	run_job
	b	90f
96:	movs	r0, #6
	b	90f
92:	movs	r0, #2
90:	bl	answer_status
	pop	{r4, pc}

@ job_file_delete - display task, r0 = zero-terminated path. Closes an open FILE_WRITE file, copies
@ the path to 0x20008360 and deletes it under the storage lock, then checks it is gone.
	.thumb_func
job_file_delete:
	push	{r4, r5, r6, r7, r8, lr}
	mov	r4, r0				@ r4 = path
	bl	write_close
	movw	r0, #0x102C			@ object for the checks (also large enough for a directory)
	bl	alloc_units_of_32_bytes
	mov	r7, r0
	cmp	r0, #0
	beq	95f
	bl	storage_lock
	ldr	r0, =PATH_BUF
	movs	r1, #0
1:	ldrb	r2, [r4, r1]
	strb	r2, [r0, r1]
	adds	r1, #1
	cmp	r2, #0
	bne	1b
	bl	path_delete
	mov	r0, r7
	mov	r1, r4
	movs	r2, #1
	bl	file_open
	mov	r5, r0
	cmp	r0, #0
	bne	2f
	mov	r0, r7
	bl	file_close
	b	3f
2:	mov	r0, r7
	mov	r1, r4
	bl	dir_open
	mov	r6, r0
	cmp	r0, #0
	bne	3f
	mov	r0, r7
	bl	object_release
3:	bl	storage_unlock
	mov	r0, r7
	bl	free_units_of_32_bytes
	cmp	r5, #4				@ file_open: not found (or a directory)
	bne	95f
	cmp	r6, #0				@ dir_open found it: still there
	beq	95f
	movs	r0, #0
	b	9f
95:	movs	r0, #5
9:	pop	{r4, r5, r6, r7, r8, pc}

@ FLASH_READ (diagnostics): address (u32, below 16 MB), length (u16, 1..256) of the external SPI flash
@ (drive 3: from 0, drive 2: from 0x200000); read-only, through serial_device_read (storage lock).
	.global	cmd_flash_read
	.thumb_func
cmd_flash_read:
	push	{r4, lr}
	cmp	r6, #6
	bne	9f
	ldr	r1, [r5, #0]			@ address
	ldrh	r2, [r5, #4]			@ length
	cbz	r2, 9f
	cmp	r2, #256
	bhi	9f
	cmp	r1, #0x1000000
	bhs	9f
	add	r0, r1, r2
	cmp	r0, #0x1000000
	bhi	9f
	mov	r4, r2
	ldr	r0, =ANSWER + 1
	bl	serial_device_read
	movs	r0, #0
	add	r1, r4, #1
	bl	answer
	pop	{r4, pc}
9:	movs	r0, #2
	bl	answer_status
	pop	{r4, pc}

@ ============================================================================
@ Events (PROTOCOL.md 4.12): called by the usb task every tick
@ ============================================================================

@ events_tick - while DTR is set: key codes from the ring (KEY_PRESSED 0x90), a change of the UI
@ page (PAGE_CHANGED 0x91, page without the low-battery bit), the low-battery state (bit 7 of the
@ page byte, set by the battery handler below level 6: BATTERY_LOW 0x92 with the level, once per
@ state). Without DTR the page and battery state are followed silently and keys are not recorded.
	.global	events_tick
	.thumb_func
events_tick:
	push	{r4, r5, r6, lr}
	ldr	r4, =V
	ldrb	r6, [r4, #V_DTR]
1:	ldrb	r0, [r4, #V_EVKT]		@ keys
	ldrb	r1, [r4, #V_EVKH]
	cmp	r0, r1
	beq	2f
	add	r1, r4, #V_EVK
	ldrb	r1, [r1, r0]
	adds	r0, #1
	and	r0, r0, #7
	strb	r0, [r4, #V_EVKT]
	movs	r0, #0x90
	bl	send_event
	b	1b
2:	ldr	r0, =UI_PAGE
	ldrb	r5, [r0]
	and	r0, r5, #0x7F
	ldrb	r1, [r4, #V_LPAGE]
	cmp	r0, r1
	beq	3f
	strb	r0, [r4, #V_LPAGE]
	cbz	r6, 3f
	mov	r1, r0
	movs	r0, #0x91
	bl	send_event
3:	ands	r5, r5, #0x80
	ldrb	r1, [r4, #V_LBATT]
	bne	4f
	movs	r0, #0				@ not low (any more)
	strb	r0, [r4, #V_LBATT]
	b	9f
4:	cbnz	r1, 9f
	movs	r0, #1
	strb	r0, [r4, #V_LBATT]
	cbz	r6, 9f
	ldr	r1, =BATTERY_LEVEL
	ldrb	r1, [r1]
	movs	r0, #0x92
	bl	send_event
9:	pop	{r4, r5, r6, pc}

@ send_event - r0 = event cmd, r1 = data byte: one event frame (type 4).
	.thumb_func
send_event:
	push	{r1, lr}
	mov	r1, r0
	movs	r0, #4
	mov	r2, sp
	movs	r3, #1
	bl	send_frame
	pop	{r1, pc}

	.ltorg

	.if	JOB_STACK_TOP - (LOCK_VARS + 8) < 752		@ deepest use measured: 488 bytes (NOTES.md)
	.error	"job stack below 752 bytes"
	.endif
	.if	JOB_STACK_TOP > FAULT_ADDR
	.error	"job stack overlaps the fault record"
	.endif

