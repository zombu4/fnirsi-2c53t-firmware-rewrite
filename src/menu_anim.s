@ menu_anim.s - animated icon of the selected entry on the main menu. Part of the FNIRSI 2C53T firmware
@ rewrite (hand-written Thumb-2 assembly).
@
@ The main menu (UI page byte 0x20001060 = 0) shows the selected entry's icon, picture 51 + entry
@ (fn_08010200, src/ui_pages_69.s: "3:/System file/%d.jpg" at (0x6a, 0x4b), 108 x 70, drawn straight
@ to the display with the pixel writer write_pixel_window_to_port). This adds eight frames per entry,
@ pictures ANIM_FIRST + 8 * entry + frame (168..199, made by tools/make_ui.py; frame 0 is the still
@ icon), drawn the same way one after the other while the display task has nothing else to do.
@
@ The display task (fn_0803da50, src/ui_keys_68.s) waits for its next message with menu_anim_wait's
@ timeout: ANIM_TICKS on the main menu, else forever as in V1.2.0. When the wait ends without a
@ message it calls menu_anim_frame. Any message (a key, a page change, a USB job) is handled first,
@ so the animation never delays the user interface; a new entry starts at its frame 1.
@ State: V_ANFRAME (frame shown last, 0..7) and V_ANENTRY (entry it belongs to), src/parts/usb_ctl.inc;
@ both 0 after start (usb_ctl_install clears V).

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

	.include "src/parts/usb_ctl.inc"

	.equ	ANIM_FIRST,	168		@ first frame picture (entry 0 frame 0)
	.equ	ANIM_TICKS,	125		@ kernel ticks between frames (1 tick = 1 ms: the STREAM period in
						@ ms is counted in TICKS 0x200062D4, PROTOCOL.md 4.6)
	.equ	MENU_SEL,	0x20001061	@ selected main-menu entry 0..3 (fn_08010200: picture 51 + it)
	.equ	PIXEL_WRITER,	0x20036B80	@ pixel-writer pointer used by decode_image_file_with_offset
	.equ	NAME_BUF,	0x20008360	@ text buffer of the display task (fn_08010200 uses it the same way)

	.section .text.menu_anim,"ax",%progbits
	.p2align 2

@ menu_anim_wait - returns r0 = the display task's wait in ticks: ANIM_TICKS on the main menu, else
@ 0xFFFFFFFF (wait forever). Changes r0, r1.
	.global	menu_anim_wait
	.thumb_func
	.type	menu_anim_wait, %function
menu_anim_wait:
	ldr	r1, =UI_PAGE
	ldrb	r1, [r1]
	movs	r0, #ANIM_TICKS
	cmp	r1, #0
	it	ne
	movne	r0, #-1
	bx	lr

@ menu_anim_frame - on the main menu: draws the next frame of the selected entry's icon. Nothing on
@ any other page or for an entry above 3. Changes r0..r3, r12.
	.global	menu_anim_frame
	.thumb_func
	.type	menu_anim_frame, %function
menu_anim_frame:
	push	{r4, r5, r6, lr}
	ldr	r0, =UI_PAGE
	ldrb	r0, [r0]
	cbnz	r0, 9f
	ldr	r0, =MENU_SEL
	ldrb	r0, [r0]			@ r0 = entry
	cmp	r0, #3
	bhi	9f
	ldr	r4, =V
	ldrb	r1, [r4, #V_ANENTRY]
	ldrb	r2, [r4, #V_ANFRAME]
	cmp	r1, r0
	it	ne
	movne	r2, #0				@ another entry: its frame 0 (the still icon) is on screen
	adds	r2, #1
	and	r2, r2, #7			@ r2 = frame to draw
	strb	r0, [r4, #V_ANENTRY]
	strb	r2, [r4, #V_ANFRAME]
	add	r2, r2, r0, lsl #3
	adds	r2, #ANIM_FIRST			@ r2 = picture number
	ldr	r5, =PIXEL_WRITER
	ldr	r1, =write_pixel_window_to_port
	str	r1, [r5]
	ldr	r6, =NAME_BUF
	mov	r0, r6
	ldr	r1, =t_080bc681			@ "3:/System file/%d.jpg"
	bl	format_to_buffer_080073b4
	mov	r0, r6
	movs	r1, #0x6a
	movs	r2, #0x4b
	bl	decode_image_file_with_offset
	ldr	r1, =copy_rect_into_clip_buffer
	str	r1, [r5]
9:	pop	{r4, r5, r6, pc}
	.ltorg
	.size	menu_anim_frame, . - menu_anim_frame
