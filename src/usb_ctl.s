@ usb_ctl.s - USB control channel: a CDC ACM serial port next to the mass-storage drive, and the task
@ that speaks the control protocol (PROTOCOL.md). Part of the FNIRSI 2C53T firmware rewrite.
@
@ Structure (CONTROL_DESIGN.md revision 3):
@ - usb_ctl_install (called by boot_hook_then_file_open, before system_bring_up initialises USB) points
@   the USB driver's callback table 0x20000030 and descriptor-getter table 0x20000058 at the functions
@   below, copies the bootloader's hand-over block and creates the task "usb".
@ - Two configurations, chosen by drive_shared (UI page 7 = "USB sharing"): CDC only (interfaces 0, 1)
@   or mass storage + CDC (interfaces 0 MSC, 1, 2 CDC, interface association). The task switches by
@   re-enumeration (D+ pull-up off 20 ms, 0x40005C60 bit 1).
@ - The USB interrupt (priority 0, above the kernel's limit) only moves bytes: CDC OUT packets into rx
@   ring, tx ring into CDC IN packets (pump on IN done and on every 1 ms start of frame). It never calls
@   the kernel.
@ - The task polls the rx ring every tick, parses frames, runs commands, writes answers into the tx ring.
@ USB driver facts used (research 2026-11-18): device 0x20002B24; IN endpoint records 0x20002B30 + 32 *
@ index, OUT records 0x20002C30 + 32 * index (+0x0E remaining, +0x10 count, +0x14 buffer pointer
@ halfwords / word); EP0 stage byte 0x20002D44 (2 data IN, 3 data OUT); fn_08040b24(dev, address,
@ type 1 bulk / 2 interrupt) sets an endpoint up (OUT armed), fn_08040874(dev, address) disables it,
@ fn_08040eb4(dev, index, buffer, count) sends on an IN endpoint; endpoint register 0x40005C00 + 4 *
@ index, OUT re-arm (x & 0x3F0F) ^ 0xB080.

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb


	.include "common/layout.inc"

	.include "src/parts/usb_ctl.inc"

	.section .text.usb_ctl,"ax",%progbits
	.p2align 2

@ ----------------------------------------------------------------------------
@ usb_ctl_install - see the file header. Clears the RAM area, copies the hand-over block (valid when
@ its magic matches; the block is cleared afterwards so a later reset without bootloader v2 does not
@ show stale data), patches the two tables and creates the task (stack 0x80 words, priority 2).
@ ----------------------------------------------------------------------------
	.global	usb_ctl_install
	.thumb_func
	.type	usb_ctl_install, %function
usb_ctl_install:
	push	{r4, r5, r6, lr}
	ldr	r0, =CTL			@ clear 0x20036F90 .. V + V_END
	ldr	r1, =V + V_END
	movs	r2, #0
1:	str	r2, [r0], #4
	cmp	r0, r1
	blo	1b
	ldr	r4, =V
	ldr	r0, =HANDOVER_ADDR
	ldr	r1, [r0, #0]
	ldr	r2, =HANDOVER_MAGIC
	cmp	r1, r2
	bne	2f
	ldmia	r0, {r1, r2, r3, r5}
	add	r6, r4, #V_HAND
	stmia	r6, {r1, r2, r3, r5}
	movs	r1, #0
	str	r1, [r0, #0]
2:	ldr	r0, =USB_CB_TABLE		@ callback table: our functions, original MSC ones called inside
	ldr	r1, =cdc_set_config
	str	r1, [r0, #0x00]
	ldr	r1, =cdc_deconfig
	str	r1, [r0, #0x04]
	ldr	r1, =cdc_class_request
	str	r1, [r0, #0x08]
	ldr	r1, =cdc_ep0_out_done
	str	r1, [r0, #0x10]
	ldr	r1, =cdc_in_done
	str	r1, [r0, #0x14]
	ldr	r1, =cdc_out_done
	str	r1, [r0, #0x18]
	ldr	r1, =cdc_sof
	str	r1, [r0, #0x1C]
	ldr	r0, =USB_DESC_TABLE		@ descriptor getters: device, configuration, manufacturer, product
	ldr	r1, =get_device_desc
	str	r1, [r0, #0x00]
	ldr	r1, =get_config_desc
	str	r1, [r0, #0x08]
	ldr	r1, =get_manufacturer
	str	r1, [r0, #0x14]
	ldr	r1, =get_product
	str	r1, [r0, #0x18]
	ldr	r0, =usb_ctl_task		@ task "usb": entry, name, 0x80 words, priority 2, handle
	ldr	r1, =s_task_name
	movs	r2, #0x80
	movs	r3, #2
	add	r5, r4, #V_TASK
	sub	sp, #8
	str	r5, [sp]
	bl	fn_080426a0
	add	sp, #8
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ Descriptor getters: return a record {halfword length, pointer at +4} (handler 0x0802E8E4).
@ ----------------------------------------------------------------------------
	.thumb_func
get_device_desc:
	ldr	r0, =rec_device
	bx	lr

	.thumb_func
get_config_desc:
	ldr	r1, =V
	ldrb	r1, [r1, #V_SHARED]
	cmp	r1, #0
	ite	eq
	ldreq	r0, =rec_config_cdc
	ldrne	r0, =rec_config_shared
	bx	lr

	.thumb_func
get_manufacturer:
	ldr	r0, =rec_manufacturer
	bx	lr

	.thumb_func
get_product:
	ldr	r0, =rec_product
	bx	lr

@ ----------------------------------------------------------------------------
@ cdc_set_config - slot 0 (r0 = device). In the shared configuration first the original MSC set-up
@ (init_state_arm_command_receive: endpoint 1); then EP2 interrupt IN, EP3 bulk IN, EP3 bulk OUT
@ armed into PKT_OUT. Returns 0.
@ ----------------------------------------------------------------------------
	.thumb_func
cdc_set_config:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	ldr	r5, =V
	movs	r0, #0				@ drive events of an earlier session are void
	strh	r0, [r5, #V_MSCOUT]
	ldrb	r0, [r5, #V_SHARED]
	cbz	r0, 1f
	mov	r0, r4
	bl	init_state_arm_command_receive
1:	mov	r0, r4
	movs	r1, #0x82
	movs	r2, #2
	bl	fn_08040b24
	mov	r0, r4
	movs	r1, #0x83
	movs	r2, #1
	bl	fn_08040b24
	bl	out3_buffer
	mov	r0, r4
	movs	r1, #3
	movs	r2, #1
	bl	fn_08040b24
	movs	r0, #0
	strb	r0, [r5, #V_INBUSY]
	strb	r0, [r5, #V_ZLP]
	movs	r0, #1
	strb	r0, [r5, #V_CONF]
	movs	r0, #0
	pop	{r4, r5, r6, pc}

@ out3_buffer - EP3 OUT record: buffer PKT_OUT, count 0, remaining 0 (every packet completes).
	.thumb_func
out3_buffer:
	ldr	r0, =OUT_REC3
	ldr	r1, =PKT_OUT
	str	r1, [r0, #0x14]
	movs	r1, #0
	strh	r1, [r0, #0x10]
	strh	r1, [r0, #0x0E]
	bx	lr

@ cdc_deconfig - slot 1: not configured; endpoints 2, 3 off; MSC deconfigure in the shared case.
	.thumb_func
cdc_deconfig:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	ldr	r5, =V
	movs	r0, #0
	strb	r0, [r5, #V_CONF]
	strb	r0, [r5, #V_DTR]
	strh	r0, [r5, #V_MSCOUT]		@ and V_MSCIN: no drive events without configuration
	mov	r0, r4
	movs	r1, #0x82
	bl	fn_08040874
	mov	r0, r4
	movs	r1, #0x83
	bl	fn_08040874
	mov	r0, r4
	movs	r1, #3
	bl	fn_08040874
	ldrb	r0, [r5, #V_SHARED]
	cbz	r0, 1f
	mov	r0, r4
	bl	fn_08030ca0
1:	movs	r0, #0
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ cdc_class_request - slot 2 (r0 = device, r1 = setup record: +0 type, +1 request, +2 wValue, +4
@ wIndex). Interface recipient with wIndex = the CDC communication interface: SET_LINE_CODING (OUT
@ data stage into V_LINE, 7 bytes), GET_LINE_CODING (7 bytes IN), SET_CONTROL_LINE_STATE (DTR = wValue
@ bit 0). Endpoint recipient for endpoint 2 or 3 (CLEAR_FEATURE halt): the endpoint is set up again.
@ Anything else goes to the original MSC handler in the shared configuration. Returns 0.
@ ----------------------------------------------------------------------------
	.thumb_func
cdc_class_request:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r5, r1
	ldr	r6, =V
	ldrb	r0, [r5, #0]
	and	r1, r0, #0x1F
	cmp	r1, #1				@ interface
	bne	5f
	ldrb	r1, [r5, #4]
	ldrb	r2, [r6, #V_CFGIF]
	cmp	r1, r2
	bne	8f
	and	r0, r0, #0x60
	cmp	r0, #0x20			@ class request
	bne	9f
	ldrb	r0, [r5, #1]
	cmp	r0, #0x20
	beq	2f
	cmp	r0, #0x21
	beq	3f
	cmp	r0, #0x22
	bne	9f
	ldrb	r0, [r5, #2]			@ SET_CONTROL_LINE_STATE: wValue bit 0 = DTR
	and	r0, r0, #1
	strb	r0, [r6, #V_DTR]
	b	9f
2:	ldr	r0, =OUT_REC0			@ SET_LINE_CODING: EP0 OUT data stage of 7 bytes into V_LINE
	add	r1, r6, #V_LINE
	str	r1, [r0, #0x14]
	movs	r1, #0
	strh	r1, [r0, #0x10]
	movs	r1, #7
	strh	r1, [r0, #0x1A]
	ldr	r0, =EP0_STAGE
	movs	r1, #3
	strb	r1, [r0]
	ldr	r0, =USB_EPR0			@ EP0 receive valid
	ldr	r1, [r0]
	movw	r2, #0x3F0F
	ands	r1, r1, r2
	eor	r1, r1, #0xB000
	eor	r1, r1, #0x0080
	str	r1, [r0]
	b	9f
3:	ldr	r0, =IN_REC0			@ GET_LINE_CODING: 7 bytes IN
	movs	r1, #7
	strh	r1, [r0, #0x1A]
	strh	r1, [r0, #0x1C]
	ldr	r0, =EP0_STAGE
	movs	r1, #2
	strb	r1, [r0]
	mov	r0, r4
	movs	r1, #0
	add	r2, r6, #V_LINE
	movs	r3, #7
	bl	fn_08040eb4
	b	9f
5:	cmp	r1, #2				@ endpoint recipient: endpoint 2 or 3 of this function
	bne	8f
	ldrb	r0, [r5, #4]
	and	r1, r0, #0x7F
	cmp	r1, #2
	beq	6f
	cmp	r1, #3
	bne	8f
6:	mov	r1, r0				@ set the endpoint up again (clears the halt and the toggle)
	mov	r0, r4
	bl	fn_08040874
	ldrb	r1, [r5, #4]
	and	r0, r1, #0x7F
	cmp	r0, #2
	ite	eq
	moveq	r2, #2
	movne	r2, #1
	cmp	r1, #3
	bne	7f
	bl	out3_buffer
	ldrb	r1, [r5, #4]
	movs	r2, #1
7:	mov	r0, r4
	bl	fn_08040b24
	b	9f
8:	ldrb	r0, [r6, #V_SHARED]
	cbz	r0, 9f
	movs	r0, #0				@ mass-storage reset / clear feature: pending events are void
	strh	r0, [r6, #V_MSCOUT]
	mov	r0, r4
	mov	r1, r5
	bl	msc_control_request_handler
9:	movs	r0, #0
	pop	{r4, r5, r6, pc}

@ cdc_ep0_out_done - slot 4: the EP0 OUT data stage (line coding) is in V_LINE; the driver sends the
@ status stage. Returns 0.
	.thumb_func
cdc_ep0_out_done:
	movs	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ cdc_out_done - slot 6 (r0 = device, r1 = endpoint index). Index 3: copy the packet (count at the
@ record's +0x10) into the rx ring (bytes that do not fit are dropped; the host waits for answers, so
@ the ring holds a full request) and arm the endpoint again. Other indices (mass storage): only
@ recorded in V_MSCOUT; the endpoint stays NAK until msc_service (src/storage.s) runs the vendor
@ handler in the usb task, so the flash is never written from the interrupt.
@ ----------------------------------------------------------------------------
	.thumb_func
cdc_out_done:
	cmp	r1, #3
	beq	1f
	ldr	r2, =V				@ mass storage: recorded, run by the usb task (msc_service)
	adds	r1, #1
	strb	r1, [r2, #V_MSCOUT]
	movs	r0, #0
	bx	lr
1:	push	{r4, r5, r6, lr}
	ldr	r4, =V
	ldr	r0, =OUT_REC3
	ldrh	r5, [r0, #0x10]			@ r5 = byte count
	ldr	r6, =PKT_OUT
	ldr	r2, [r4, #V_RXH]
	ldr	r3, [r4, #V_RXT]
2:	cbz	r5, 3f
	add	r0, r2, #1			@ full when head + 1 == tail
	bfc	r0, #10, #22
	cmp	r0, r3
	beq	3f
	ldrb	r1, [r6], #1
	ldr	r12, =RX_RING
	strb	r1, [r12, r2]
	mov	r2, r0
	subs	r5, #1
	b	2b
3:	str	r2, [r4, #V_RXH]
	bl	out3_buffer
	ldr	r0, =USB_EPR3			@ receive valid again
	ldr	r1, [r0]
	movw	r2, #0x3F0F
	ands	r1, r1, r2
	eor	r1, r1, #0xB000
	eor	r1, r1, #0x0080
	str	r1, [r0]
	movs	r0, #0
	pop	{r4, r5, r6, pc}

@ cdc_in_done - slot 5 (r0 = device, r1 = index). Index 3: packet sent, pump the next. Index 1 (mass
@ storage transfer complete): recorded in V_MSCIN for msc_service. Index 2 (notifications, never
@ sent): nothing.
	.thumb_func
cdc_in_done:
	cmp	r1, #3
	beq	1f
	cmp	r1, #1
	bne	2f
	ldr	r2, =V				@ mass storage: recorded, run by the usb task (msc_service)
	strb	r1, [r2, #V_MSCIN]
	movs	r0, #0
	bx	lr
1:	ldr	r1, =V
	movs	r2, #0
	strb	r2, [r1, #V_INBUSY]
	b	cdc_pump
2:	movs	r0, #0
	bx	lr

@ cdc_sof - slot 7 (start of frame, every 1 ms): pump.
	.thumb_func
cdc_sof:
	b	cdc_pump

@ cdc_pump - r0 = device. When configured and no IN packet is in flight: up to 64 bytes from the tx ring
@ into PKT_IN and send them on endpoint 3; after a full 64-byte packet with the ring empty, a
@ zero-length packet ends the transfer. Interrupt context only. Returns 0.
	.thumb_func
cdc_pump:
	push	{r4, r5, r6, lr}
	mov	r6, r0
	ldr	r4, =V
	ldrb	r0, [r4, #V_CONF]
	cbz	r0, 9f
	ldrb	r0, [r4, #V_INBUSY]
	cbnz	r0, 9f
	ldr	r2, [r4, #V_TXT]
	ldr	r3, [r4, #V_TXH]
	ldr	r5, =PKT_IN
	movs	r1, #0				@ r1 = bytes in this packet
1:	cmp	r2, r3
	beq	2f
	cmp	r1, #64
	beq	2f
	ldr	r12, =TX_RING
	ldrb	r0, [r12, r2]
	strb	r0, [r5, r1]
	adds	r1, #1
	adds	r2, #1
	bfc	r2, #10, #22
	b	1b
2:	str	r2, [r4, #V_TXT]
	cbnz	r1, 3f
	ldrb	r0, [r4, #V_ZLP]		@ nothing to send: a zero-length packet if one is owed
	cbz	r0, 9f
3:	cmp	r1, #64
	ite	eq
	moveq	r0, #1
	movne	r0, #0
	strb	r0, [r4, #V_ZLP]
	movs	r0, #1
	strb	r0, [r4, #V_INBUSY]
	mov	r3, r1
	mov	r0, r6
	movs	r1, #3
	mov	r2, r5
	bl	fn_08040eb4
9:	movs	r0, #0
	pop	{r4, r5, r6, pc}

@ ============================================================================
@ Task "usb" (task context: may call the kernel).
@ ============================================================================

@ ----------------------------------------------------------------------------
@ usb_ctl_task - powers USB up (as fn_0801067C does: clears bit 1 of 0x40005C40 and 0x40005C60),
@ then every tick: configuration follows the UI page (7 = drive shared, re-enumerate on a change),
@ auto power-off held while DTR or KEEP_AWAKE, frames parsed and answered, stream frames sent.
@ ----------------------------------------------------------------------------
	.thumb_func
usb_ctl_task:
	ldr	r4, =V
	bl	usb_power_up
1:	movs	r0, #1
	bl	fn_08041390			@ sleep 1 tick (1 ms)
	ldr	r0, =UI_PAGE			@ drive shared exactly while the UI is on page 7
	ldrb	r0, [r0]
	cmp	r0, #7
	ite	eq
	moveq	r1, #1
	movne	r1, #0
	ldrb	r2, [r4, #V_SHARED]
	cmp	r1, r2
	beq	2f
	strb	r1, [r4, #V_SHARED]
	cbz	r1, 21f
	bl	storage_share			@ file closed, volumes written back before the host gets it
	bl	usb_reenumerate
	b	2f
21:	bl	usb_reenumerate
	bl	storage_unshare			@ the volume the host had is mounted again from the flash
2:	ldrb	r0, [r4, #V_DTR]
	ldrb	r1, [r4, #V_AWAKE]
	orrs	r0, r0, r1
	beq	3f
	ldr	r0, =AUTO_OFF_COUNT
	movs	r1, #0
	strh	r1, [r0]
3:	bl	msc_service			@ mass-storage events (src/storage.s)
	bl	parse_rx
	bl	stream_tick
	bl	events_tick			@ usb_remote.s
	b	1b

@ usb_power_up / usb_reenumerate - pull-up off 20 ms with the device powered, then on; the CDC
@ interface number follows the configuration (0 without, 1 with the drive).
	.thumb_func
usb_power_up:
	push	{r4, lr}
	ldr	r4, =V
	ldrb	r0, [r4, #V_SHARED]
	strb	r0, [r4, #V_CFGIF]
	ldr	r0, =USB_CNTR
	ldr	r1, [r0]
	bic	r1, r1, #2
	str	r1, [r0]
	ldr	r0, =USB_CFG
	ldr	r1, [r0]
	bic	r1, r1, #2
	str	r1, [r0]
	pop	{r4, pc}

	.thumb_func
usb_reenumerate:
	push	{r4, lr}
	ldr	r4, =V
	movs	r0, #0
	strb	r0, [r4, #V_CONF]
	ldr	r0, =USB_CFG			@ D+ pull-up off: the host sees a disconnect
	ldr	r1, [r0]
	orr	r1, r1, #2
	str	r1, [r0]
	movs	r0, #20
	bl	fn_08041390
	bl	usb_power_up			@ pull-up on with the new configuration
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ parse_rx - consumes the rx ring: sync 0xA5, length (2 bytes, 3..MAX_PAYLOAD+3), body + CRC into FRAME
@ (FRAME[0..1] = length, then seq, type, cmd, payload, CRC). A complete frame with a good CRC and type
@ 1 (request) is executed by dispatch; anything else is dropped.
@ ----------------------------------------------------------------------------
	.thumb_func
parse_rx:
	push	{r4, r5, r6, r7, r8, lr}
	ldr	r4, =V
	ldr	r5, =RX_RING
	ldr	r6, =FRAME
1:	ldr	r2, [r4, #V_RXT]
	ldr	r3, [r4, #V_RXH]
	cmp	r2, r3
	beq	9f
	ldrb	r7, [r5, r2]			@ r7 = next byte
	adds	r2, #1
	bfc	r2, #10, #22
	str	r2, [r4, #V_RXT]
	ldrb	r0, [r4, #V_PSTATE]
	cmp	r0, #0
	bne	2f
	cmp	r7, #0xA5
	bne	1b
	movs	r0, #1
	strb	r0, [r4, #V_PSTATE]
	b	1b
2:	cmp	r0, #1
	bne	3f
	strb	r7, [r6, #0]
	movs	r0, #2
	strb	r0, [r4, #V_PSTATE]
	b	1b
3:	cmp	r0, #2
	bne	4f
	strb	r7, [r6, #1]
	ldrh	r0, [r6, #0]
	cmp	r0, #3				@ length out of range: back to sync search
	blo	8f
	movw	r1, #(MAX_PAYLOAD + 3)
	cmp	r0, r1
	bhi	8f
	strh	r0, [r4, #V_FLEN]
	movs	r0, #0
	strh	r0, [r4, #V_FPOS]
	movs	r0, #3
	strb	r0, [r4, #V_PSTATE]
	b	1b
4:	ldrh	r0, [r4, #V_FPOS]		@ body byte
	add	r1, r6, #2
	strb	r7, [r1, r0]
	adds	r0, #1
	strh	r0, [r4, #V_FPOS]
	ldrh	r1, [r4, #V_FLEN]
	adds	r1, #2				@ body + CRC
	cmp	r0, r1
	blo	1b
	ldrh	r1, [r4, #V_FLEN]		@ CRC over length (2) + body
	adds	r1, #2
	mov	r0, r6
	bl	crc16
	ldrh	r1, [r4, #V_FLEN]
	add	r1, r1, r6
	ldrb	r2, [r1, #2]
	ldrb	r3, [r1, #3]
	orr	r2, r2, r3, lsl #8
	cmp	r0, r2
	bne	8f
	ldrb	r0, [r6, #3]			@ type
	cmp	r0, #1
	bne	8f
	bl	dispatch
8:	movs	r0, #0
	strb	r0, [r4, #V_PSTATE]
	b	1b
9:	pop	{r4, r5, r6, r7, r8, pc}

@ crc16 - r0 = data, r1 = length; CRC-16/CCITT-FALSE (0x1021, init 0xFFFF). Clobbers r0-r3.
	.thumb_func
crc16:
	push	{r4, lr}
	movw	r2, #0xFFFF
1:	cbz	r1, 4f
	ldrb	r3, [r0], #1
	eor	r2, r2, r3, lsl #8
	movs	r3, #8
2:	lsls	r2, r2, #1
	tst	r2, #0x10000
	beq	3f
	movw	r4, #0x1021
	eor	r2, r2, r4
3:	uxth	r2, r2
	subs	r3, #1
	bne	2b
	subs	r1, #1
	b	1b
4:	mov	r0, r2
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ send_frame - r0 = type, r1 = cmd, r2 = payload, r3 = payload length; seq: FRAME[2] for answers, the
@ stream counter otherwise. Writes the frame into the tx ring, waiting (1 tick at a time) while the
@ ring has no room. Task context.
@ ----------------------------------------------------------------------------
	.global	send_frame
	.thumb_func
send_frame:
	push	{r4, r5, r6, r7, r8, r9, r10, lr}
	sub	sp, #8
	ldr	r4, =V
	mov	r5, r0
	mov	r6, r1
	mov	r7, r2
	mov	r8, r3
	cmp	r5, #2
	itte	eq
	ldreq	r0, =FRAME
	ldrbeq	r9, [r0, #2]
	ldrbne	r9, [r4, #V_SSEQ]
	beq	1f
	add	r0, r9, #1
	strb	r0, [r4, #V_SSEQ]
1:	add	r10, r8, #8			@ frame size: sync, length 2, seq, type, cmd, payload, CRC 2
2:	ldr	r0, [r4, #V_TXH]		@ free = tail - head - 1 (mod 1024)
	ldr	r1, [r4, #V_TXT]
	sub	r1, r1, r0
	subs	r1, #1
	bfc	r1, #10, #22
	cmp	r1, r10
	bhs	3f
	ldrb	r0, [r4, #V_CONF]		@ not configured: nobody reads; drop the frame
	cbz	r0, 9f
	movs	r0, #1
	bl	fn_08041390
	b	2b
3:	add	r0, r8, #3			@ header bytes into the scratch: length, seq, type, cmd
	strh	r0, [sp, #0]
	strb	r9, [sp, #2]
	strb	r5, [sp, #3]
	strb	r6, [sp, #4]
	mov	r0, sp				@ CRC over length .. cmd, then payload
	movs	r1, #5
	bl	crc16_start
	mov	r1, r7
	mov	r2, r8
	bl	crc16_more
	strh	r0, [sp, #6]
	movs	r0, #0xA5
	bl	tx_put
	mov	r0, sp
	movs	r1, #5
	bl	tx_write
	mov	r0, r7
	mov	r1, r8
	bl	tx_write
	add	r0, sp, #6
	movs	r1, #2
	bl	tx_write
9:	add	sp, #8
	pop	{r4, r5, r6, r7, r8, r9, r10, pc}

@ crc16_start - r0 = data, r1 = length; returns the CRC register. crc16_more - r0 = register, r1 =
@ data, r2 = length; returns the register. Clobber r0-r3, r12.
	.thumb_func
crc16_start:
	mov	r2, r1
	mov	r1, r0
	movw	r0, #0xFFFF
	.thumb_func
crc16_more:
	push	{r4, lr}
1:	cbz	r2, 4f
	ldrb	r3, [r1], #1
	eor	r0, r0, r3, lsl #8
	movs	r3, #8
2:	lsls	r0, r0, #1
	tst	r0, #0x10000
	beq	3f
	movw	r4, #0x1021
	eor	r0, r0, r4
3:	uxth	r0, r0
	subs	r3, #1
	bne	2b
	subs	r2, #1
	b	1b
4:	pop	{r4, pc}

@ tx_put - r0 = byte into the tx ring (room checked by the caller). tx_write - r0 = data, r1 = length.
	.thumb_func
tx_put:
	ldr	r1, =V
	ldr	r2, [r1, #V_TXH]
	ldr	r3, =TX_RING
	strb	r0, [r3, r2]
	adds	r2, #1
	bfc	r2, #10, #22
	dmb
	str	r2, [r1, #V_TXH]
	bx	lr

	.thumb_func
tx_write:
	push	{r4, r5, lr}
	mov	r4, r0
	mov	r5, r1
1:	cbz	r5, 2f
	ldrb	r0, [r4], #1
	bl	tx_put
	subs	r5, #1
	b	1b
2:	pop	{r4, r5, pc}

@ answer - r0 = status, r1 = data length in ANSWER + 1 (ANSWER[0] is overwritten by the status). Sends
@ the answer frame for the request in FRAME.
	.global	answer
	.thumb_func
answer:
	push	{r4, lr}
	ldr	r2, =ANSWER
	strb	r0, [r2]
	mov	r3, r1
	ldr	r1, =FRAME
	ldrb	r1, [r1, #4]			@ cmd
	movs	r0, #2
	bl	send_frame
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ dispatch - FRAME: [0..1] length, [2] seq, [3] type, [4] cmd, [5..] payload (length - 3 bytes).
@ r5 = payload pointer, r6 = payload length for the command functions; each one ends with answer.
@ ----------------------------------------------------------------------------
	.thumb_func
dispatch:
	push	{r4, r5, r6, r7, r8, lr}
	ldr	r4, =V
	ldr	r0, =FRAME
	ldrh	r6, [r0, #0]
	subs	r6, #3
	add	r5, r0, #5
	ldrb	r1, [r0, #4]
	cmp	r1, #0x71			@ any command but FILE_READ ends a FILE_READ sequence
	beq	0f
	bl	read_close			@ usb_remote.s
	ldr	r0, =FRAME
	ldrb	r1, [r0, #4]
0:	adr	r2, cmd_table
1:	ldrb	r3, [r2], #4			@ table: {cmd byte, 3 pad, handler}... ended by 0xFF
	cmp	r3, #0xFF
	beq	2f
	cmp	r3, r1
	beq	3f
	adds	r2, #4
	b	1b
3:	ldr	r3, [r2]
	blx	r3
	pop	{r4, r5, r6, r7, r8, pc}
2:	movs	r0, #1				@ unknown command
	movs	r1, #1
	bl	answer
	pop	{r4, r5, r6, r7, r8, pc}

	.p2align 2
cmd_table:
	.byte	0x00, 0, 0, 0
	.word	cmd_info
	.byte	0x01, 0, 0, 0
	.word	cmd_ping
	.byte	0x02, 0, 0, 0
	.word	cmd_reset
	.byte	0x03, 0, 0, 0
	.word	cmd_battery
	.byte	0x04, 0, 0, 0
	.word	cmd_keep_awake
	.byte	0x10, 0, 0, 0
	.word	cmd_state
	.byte	0x11, 0, 0, 0
	.word	cmd_stream
	.byte	0x12, 0, 0, 0
	.word	cmd_page
	.byte	0x13, 0, 0, 0
	.word	cmd_key
	.byte	0x20, 0, 0, 0
	.word	cmd_dmm_function
	.byte	0x21, 0, 0, 0
	.word	cmd_dmm_hold
	.byte	0x22, 0, 0, 0
	.word	cmd_dmm_relative
	.byte	0x30, 0, 0, 0
	.word	cmd_scope_timebase
	.byte	0x31, 0, 0, 0
	.word	cmd_scope_channel
	.byte	0x32, 0, 0, 0
	.word	cmd_scope_trigger
	.byte	0x33, 0, 0, 0
	.word	cmd_scope_tables
	.byte	0x34, 0, 0, 0
	.word	cmd_scope_run
	.byte	0x35, 0, 0, 0
	.word	cmd_scope_autoset
	.byte	0x36, 0, 0, 0
	.word	cmd_scope_wave
	.byte	0x37, 0, 0, 0
	.word	cmd_scope_autocorrect
	.byte	0x40, 0, 0, 0
	.word	cmd_gen_set
	.byte	0x50, 0, 0, 0
	.word	cmd_settings_get
	.byte	0x51, 0, 0, 0
	.word	cmd_settings_set
	.byte	0x52, 0, 0, 0
	.word	cmd_settings_save
	.byte	0x53, 0, 0, 0
	.word	cmd_cal_read
	.byte	0x60, 0, 0, 0
	.word	cmd_screenshot
	.byte	0x70, 0, 0, 0
	.word	cmd_file_list
	.byte	0x71, 0, 0, 0
	.word	cmd_file_read
	.byte	0x72, 0, 0, 0
	.word	cmd_file_write
	.byte	0x73, 0, 0, 0
	.word	cmd_file_delete
	.byte	0x74, 0, 0, 0
	.word	cmd_drive
	.byte	0x80, 0, 0, 0
	.word	cmd_fw_begin
	.byte	0x81, 0, 0, 0
	.word	cmd_fw_data
	.byte	0x82, 0, 0, 0
	.word	cmd_fw_end
	.byte	0x83, 0, 0, 0
	.word	cmd_fw_install
	.byte	0xF0, 0, 0, 0
	.word	cmd_mem_read
	.byte	0xF2, 0, 0, 0
	.word	cmd_flash_read
	.byte	0xFF, 0, 0, 0

@ ----------------------------------------------------------------------------
@ Commands. In: r4 = V, r5 = payload, r6 = payload length.
@ ----------------------------------------------------------------------------

@ INFO: protocol version, capability bits, firmware version text (16), chip UID (12), bootloader slot,
@ bootloader version (u32), application size (u32), last update result (u32).
	.thumb_func
cmd_info:
	push	{r4, r5, r6, lr}
	ldr	r5, =ANSWER
	movs	r0, #PROTO_VERSION
	strb	r0, [r5, #1]
	ldr	r0, =CAPS
	str	r0, [r5, #2]			@ unaligned store: allowed on this core for str
	add	r0, r5, #6			@ version text, 16 bytes, zero padded
	movs	r1, #0
	movs	r2, #16
	bl	fill_zero
	add	r0, r5, #6
	ldr	r1, =firmware_version_text
	movs	r2, #15
	bl	copy_text
	add	r0, r5, #22			@ UID 0x1FFFF7E8..0x1FFFF7F3
	ldr	r1, =0x1FFFF7E8
	movs	r2, #12
	bl	copy_bytes_n
	ldr	r0, [r4, #V_HAND + 0]		@ hand-over valid: slot and version, else 0xFF / 0
	ldr	r1, =HANDOVER_MAGIC
	cmp	r0, r1
	itete	eq
	ldrbeq	r0, [r4, #V_HAND + 4]
	movne	r0, #0xFF
	ldreq	r1, [r4, #V_HAND + 8]
	movne	r1, #0
	strb	r0, [r5, #34]
	str	r1, [r5, #35]
	ldr	r0, =app_image_end
	sub	r0, r0, #0x08000000
	sub	r0, r0, #0x7000
	str	r0, [r5, #39]
	ldr	r0, [r4, #V_HAND + 12]
	str	r0, [r5, #43]
	movs	r0, #0
	movs	r1, #47
	bl	answer
	pop	{r4, r5, r6, pc}

@ fill_zero - r0 = destination, r2 = count. copy_text - r0 = destination, r1 = zero-terminated text,
@ r2 = at most. copy_bytes_n - r0 = destination, r1 = source, r2 = count.
	.thumb_func
fill_zero:
	movs	r1, #0
1:	cbz	r2, 2f
	strb	r1, [r0], #1
	subs	r2, #1
	b	1b
2:	bx	lr

	.thumb_func
copy_text:
1:	cbz	r2, 2f
	ldrb	r3, [r1], #1
	cbz	r3, 2f
	strb	r3, [r0], #1
	subs	r2, #1
	b	1b
2:	bx	lr

	.thumb_func
copy_bytes_n:
1:	cbz	r2, 2f
	ldrb	r3, [r1], #1
	strb	r3, [r0], #1
	subs	r2, #1
	b	1b
2:	bx	lr

@ PING: answers the payload.
	.thumb_func
cmd_ping:
	push	{r4, lr}
	ldr	r0, =ANSWER + 1
	mov	r1, r5
	mov	r2, r6
	bl	copy_bytes_n
	movs	r0, #0
	add	r1, r6, #1
	bl	answer
	pop	{r4, pc}

@ RESET: answer, wait until it is sent (at most 100 ms), pull-up off, system reset.
	.thumb_func
cmd_reset:
	movs	r0, #0
	movs	r1, #1
	bl	answer
	bl	drain_and_disconnect
	bl	storage_quiesce			@ flash idle and written back before the reset
	ldr	r0, =0xE000ED0C
	ldr	r1, =0x05FA0004
	str	r1, [r0]
	dsb
1:	b	1b

@ drain_and_disconnect - waits until the tx ring is empty and no packet is in flight (at most 100
@ ticks), then takes the D+ pull-up off for 20 ms.
	.global	drain_and_disconnect
	.thumb_func
drain_and_disconnect:
	push	{r4, r5, r6, lr}
	ldr	r4, =V
	movs	r5, #100
1:	ldr	r0, [r4, #V_TXH]
	ldr	r1, [r4, #V_TXT]
	cmp	r0, r1
	bne	2f
	ldrb	r0, [r4, #V_INBUSY]
	cbz	r0, 3f
2:	movs	r0, #1
	bl	fn_08041390
	subs	r5, #1
	bne	1b
3:	ldr	r0, =USB_CFG
	ldr	r1, [r0]
	orr	r1, r1, #2
	str	r1, [r0]
	movs	r0, #20
	bl	fn_08041390
	pop	{r4, r5, r6, pc}

@ BATTERY: level (0x2000105F, the application's battery level), charging (not established: 0).
	.thumb_func
cmd_battery:
	push	{r4, lr}
	ldr	r2, =ANSWER
	ldr	r0, =0x2000105F
	ldrb	r0, [r0]
	strb	r0, [r2, #1]
	movs	r0, #0
	strb	r0, [r2, #2]
	movs	r0, #0
	movs	r1, #3
	bl	answer
	pop	{r4, pc}

@ KEEP_AWAKE: payload byte on/off.
	.thumb_func
cmd_keep_awake:
	push	{r4, lr}
	cmp	r6, #1
	bne	9f
	ldrb	r0, [r5]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	strb	r0, [r4, #V_AWAKE]
	movs	r0, #0
	movs	r1, #1
	bl	answer
	pop	{r4, pc}
9:	movs	r0, #2
	movs	r1, #1
	bl	answer
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ build_state - writes the STATE record (PROTOCOL.md 4.6, STATE_LEN bytes) to r0; returns its length.
@ dmm.range (byte 11) is reserved (0): the meter chip's range code is not established. dmm.function
@ from the meter index 0x20001025 (0..7), sub-function 0x2000102E and 0x20001031 (temperature unit).
@ Page: UI page byte 0x20001060 without bit 7; bit 7 (set by the battery handler fn_08009c78 below
@ level 6) is flag bit 6. Flag bit 5: external power (port C input 0x40011008 bit 7 low: the battery
@ handler then skips the measurement and shows 100). Scope: per channel enable (0x2000010C bit n),
@ V/div step 0x200000FA + n, offset 0x200000FC + n; trigger source 0x2000010E, edge 0x20000110, level
@ 0x20000114, mode 0x2000010F; per channel coupling 0x200000F8 + n, probe 0x200000FE + n, FFT
@ 0x20000102 + n (usb_remote.s header).
@ ----------------------------------------------------------------------------
	.global	build_state
	.thumb_func
build_state:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r1, #STATE_LEN
1:	subs	r1, #1
	movs	r2, #0
	strb	r2, [r4, r1]
	cmp	r1, #0
	bne	1b
	ldr	r0, =UI_PAGE
	ldrb	r0, [r0]
	and	r2, r0, #0x7F
	strb	r2, [r4, #0]
	movs	r1, #0				@ flags
	tst	r0, #0x80			@ low battery
	it	ne
	orrne	r1, r1, #0x40
	ldr	r0, =0x40011008			@ port C input bit 7 low: external power
	ldr	r0, [r0]
	tst	r0, #0x80
	it	eq
	orreq	r1, r1, #0x20
	ldr	r0, =0x20001034			@ hold (key 15; page 1 draws "HOLD" from it)
	ldrb	r0, [r0]
	cmp	r0, #0
	it	ne
	orrne	r1, r1, #1
	ldr	r0, =0x20001035			@ relative (key 7; reading = value - reference)
	ldrb	r0, [r0]
	cmp	r0, #0
	it	ne
	orrne	r1, r1, #2
	ldr	r0, =0x20000126			@ scope running
	ldrb	r0, [r0]
	cmp	r0, #0
	it	ne
	orrne	r1, r1, #4
	ldr	r0, =0x20000F50			@ generator output
	ldrb	r0, [r0]
	cmp	r0, #0
	it	ne
	orrne	r1, r1, #8
	ldr	r0, =V
	ldrb	r2, [r0, #V_SHARED]
	cmp	r2, #0
	it	ne
	orrne	r1, r1, #16
	ldrb	r2, [r0, #V_DTR]		@ the host's DTR as the meter has it
	cmp	r2, #0
	it	ne
	orrne	r1, r1, #0x80
	strh	r1, [r4, #1]
	ldr	r0, =0x2000105F			@ battery
	ldrb	r0, [r0]
	strb	r0, [r4, #3]
	bl	dmm_function_code
	strb	r0, [r4, #4]
	mov	r5, r0
	ldr	r0, =0x20001028			@ value (float)
	ldr	r0, [r0]
	str	r0, [r4, #5]
	adr	r0, unit_by_function		@ unit from the function
	ldrb	r0, [r0, r5]
	strb	r0, [r4, #9]
	ldr	r0, =0x2000102C			@ decimals
	ldrb	r0, [r0]
	strb	r0, [r4, #10]
	ldr	r0, =0x20000125			@ timebase index
	ldrb	r0, [r0]
	strb	r0, [r4, #12]
	ldr	r5, =0x200000F8			@ scope variables base
	ldrb	r0, [r5, #0x14]			@ 0x2000010C enable bits
	and	r1, r0, #1
	strb	r1, [r4, #13]
	lsrs	r0, r0, #1
	and	r1, r0, #1
	strb	r1, [r4, #17]
	ldrb	r0, [r5, #2]			@ V/div steps
	strb	r0, [r4, #14]
	ldrb	r0, [r5, #3]
	strb	r0, [r4, #18]
	ldrsb	r0, [r5, #4]			@ offsets (s8 -> s16)
	strh	r0, [r4, #15]
	ldrsb	r0, [r5, #5]
	strh	r0, [r4, #19]
	ldrb	r0, [r5, #0x16]			@ trigger source 0x2000010E
	strb	r0, [r4, #21]
	ldrb	r0, [r5, #0x18]			@ edge 0x20000110
	strb	r0, [r4, #22]
	ldrh	r0, [r5, #0x1C]			@ level 0x20000114
	strh	r0, [r4, #23]
	ldrb	r0, [r5, #0x17]			@ mode 0x2000010F
	strb	r0, [r4, #25]
	ldrb	r0, [r5, #0]			@ coupling, probe, FFT per channel at 38
	strb	r0, [r4, #38]
	ldrb	r0, [r5, #6]
	strb	r0, [r4, #39]
	ldrb	r0, [r5, #10]
	strb	r0, [r4, #40]
	ldrb	r0, [r5, #1]
	strb	r0, [r4, #41]
	ldrb	r0, [r5, #7]
	strb	r0, [r4, #42]
	ldrb	r0, [r5, #11]
	strb	r0, [r4, #43]
	ldr	r0, =0x20000F50			@ generator {on, waveform, frequency, duty, amplitude} at 26
	ldrb	r1, [r0, #0]
	strb	r1, [r4, #26]
	ldrb	r1, [r0, #1]
	strb	r1, [r4, #27]
	ldr	r1, [r0, #4]
	str	r1, [r4, #28]
	ldrb	r1, [r0, #8]
	strb	r1, [r4, #32]
	ldrb	r1, [r0, #9]
	strb	r1, [r4, #33]
	ldr	r0, =TICKS			@ time (ms) at 34
	ldr	r0, [r0]
	str	r0, [r4, #34]
	movs	r0, #STATE_LEN
	pop	{r4, r5, r6, pc}

	.p2align 2
unit_by_function:				@ PROTOCOL.md dmm.unit per dmm.function 0..12
	.byte	0, 1, 1, 3, 1, 3, 4, 5, 6, 2, 2, 2, 2
	.p2align 1

@ dmm_function_code - returns the PROTOCOL.md function code from 0x20001025 / 0x2000102E / 0x20001031.
	.global	dmm_function_code
	.thumb_func
dmm_function_code:
	ldr	r0, =0x20001025
	ldrb	r0, [r0]
	ldr	r1, =0x2000102E
	ldrb	r1, [r1]
	cmp	r0, #1				@ 0 auto
	bhs	1f
	movs	r0, #0
	bx	lr
1:	bne	2f
	cmp	r1, #2				@ 1 voltage: 1 DC, 2 AC
	ite	eq
	moveq	r0, #2
	movne	r0, #1
	bx	lr
2:	cmp	r0, #2				@ 2 continuity (sub 2) / diode (sub 1)
	bne	3f
	cmp	r1, #2
	ite	eq
	moveq	r0, #3
	movne	r0, #4
	bx	lr
3:	cmp	r0, #3
	itt	eq
	moveq	r0, #5				@ 3 resistance
	bxeq	lr
	cmp	r0, #4
	itt	eq
	moveq	r0, #6				@ 4 capacitance
	bxeq	lr
	cmp	r0, #5
	bne	4f
	ldr	r0, =0x20001031			@ 5 temperature: unit toggle byte
	ldrb	r0, [r0]
	cmp	r0, #0
	ite	eq
	moveq	r0, #7
	movne	r0, #8
	bx	lr
4:	cmp	r0, #6				@ 6 small current, 7 large current; sub 1 DC, 2 AC
	bne	5f
	cmp	r1, #2
	ite	eq
	moveq	r0, #10
	movne	r0, #9
	bx	lr
5:	cmp	r1, #2
	ite	eq
	moveq	r0, #12
	movne	r0, #11
	bx	lr

@ STATE: the STATE record.
	.thumb_func
cmd_state:
	push	{r4, lr}
	ldr	r0, =ANSWER + 1
	bl	build_state
	add	r1, r0, #1
	movs	r0, #0
	bl	answer
	pop	{r4, pc}

@ STREAM: period in ms (u16, 0 = stop).
	.thumb_func
cmd_stream:
	push	{r4, lr}
	cmp	r6, #2
	bne	9f
	ldrh	r0, [r5]
	str	r0, [r4, #V_STREAM]
	ldr	r1, =TICKS
	ldr	r1, [r1]
	str	r1, [r4, #V_SNEXT]
	movs	r0, #0
	movs	r1, #1
	bl	answer
	pop	{r4, pc}
9:	movs	r0, #2
	movs	r1, #1
	bl	answer
	pop	{r4, pc}

@ stream_tick - when a period is set, DTR is set and the tick has come: one stream frame (cmd 0x10).
	.thumb_func
stream_tick:
	push	{r4, r5, r6, lr}
	sub	sp, #STATE_LEN + 4
	ldr	r4, =V
	ldr	r5, [r4, #V_STREAM]
	cbz	r5, 9f
	ldrb	r0, [r4, #V_DTR]
	cbz	r0, 9f
	ldr	r0, =TICKS
	ldr	r0, [r0]
	ldr	r1, [r4, #V_SNEXT]
	subs	r1, r0, r1
	bmi	9f
	add	r0, r0, r5
	str	r0, [r4, #V_SNEXT]
	mov	r0, sp
	bl	build_state
	mov	r3, r0
	movs	r0, #3
	movs	r1, #0x10
	mov	r2, sp
	bl	send_frame
9:	add	sp, #STATE_LEN + 4
	pop	{r4, r5, r6, pc}

@ post_key - r0 = key code; into the key queue (the key task runs it as if the key was pressed).
@ Returns 1 when queued.
	.global	post_key
	.thumb_func
post_key:
	push	{r0, lr}
	ldr	r0, =KEY_QUEUE
	ldr	r0, [r0]
	mov	r1, sp
	movs	r2, #0
	bl	queue_send_timeout
	pop	{r1, pc}

@ KEY: code 1..23.
	.thumb_func
cmd_key:
	push	{r4, lr}
	cmp	r6, #1
	bne	9f
	ldrb	r0, [r5]
	cmp	r0, #1
	blo	9f
	cmp	r0, #23
	bhi	9f
	bl	post_key
	cbz	r0, 8f
	movs	r0, #20				@ let the key task run it, then report the state
	bl	fn_08041390
	ldr	r0, =ANSWER + 1
	bl	build_state
	add	r1, r0, #1
	movs	r0, #0
	bl	answer
	pop	{r4, pc}
8:	movs	r0, #4				@ key queue full
	movs	r1, #1
	bl	answer
	pop	{r4, pc}
9:	movs	r0, #2
	movs	r1, #1
	bl	answer
	pop	{r4, pc}

@ PAGE: 0 menu, 1 meter, 2 scope, 3 generator through their keys (22 long = menu, 17 / 18 / 19 =
@ meter / scope / generator); other pages: status 2.
	.thumb_func
cmd_page:
	push	{r4, lr}
	cmp	r6, #1
	bne	9f
	ldrb	r0, [r5]
	cmp	r0, #3
	bhi	9f
	adr	r1, page_keys
	ldrb	r0, [r1, r0]
	strb	r0, [r5]
	b	cmd_key_body
9:	movs	r0, #2
	movs	r1, #1
	bl	answer
	pop	{r4, pc}
cmd_key_body:
	pop	{r4, lr}
	b	cmd_key

	.p2align 2
page_keys:
	.byte	22, 17, 18, 19

@ ----------------------------------------------------------------------------
@ GEN_SET: on, waveform 0..12, frequency 1..50000 (u32), duty 0..100, amplitude 1..30. Writes the
@ generator variables (0x20000F50 on, F51 waveform, F54 frequency, F58 duty, F59 amplitude), rebuilds
@ the sample table (fill_output_waveform_table 0x08029E14) and applies frequency / output
@ (0x08029D40), as the generator keys do; on the generator page posts the redraw codes 8, 0x17, 0x18,
@ 0x19 to the display queue.
@ ----------------------------------------------------------------------------
	.thumb_func
cmd_gen_set:
	push	{r4, r5, r6, lr}
	cmp	r6, #8
	bne	9f
	ldrb	r0, [r5, #0]
	cmp	r0, #1
	bhi	9f
	ldrb	r0, [r5, #1]
	cmp	r0, #12
	bhi	9f
	ldr	r0, [r5, #2]			@ unaligned load is allowed for ldr
	cmp	r0, #1
	blo	9f
	movw	r1, #50000
	cmp	r0, r1
	bhi	9f
	ldrb	r0, [r5, #6]
	cmp	r0, #100
	bhi	9f
	ldrb	r0, [r5, #7]
	cmp	r0, #1
	blo	9f
	cmp	r0, #30
	bhi	9f
	ldr	r4, =0x20000F50
	ldrb	r0, [r5, #0]
	strb	r0, [r4, #0]
	ldrb	r0, [r5, #1]
	strb	r0, [r4, #1]
	ldr	r0, [r5, #2]
	str	r0, [r4, #4]
	ldrb	r0, [r5, #6]
	strb	r0, [r4, #8]
	ldrb	r0, [r5, #7]
	strb	r0, [r4, #9]
	bl	fill_output_waveform_table
	bl	fn_08029d40
	ldr	r0, =UI_PAGE
	ldrb	r0, [r0]
	cmp	r0, #3
	bne	1f
	movs	r0, #8
	bl	post_display
	movs	r0, #0x17
	bl	post_display
	movs	r0, #0x18
	bl	post_display
	movs	r0, #0x19
	bl	post_display
1:	ldr	r0, =ANSWER + 1
	bl	build_state
	add	r1, r0, #1
	movs	r0, #0
	bl	answer
	pop	{r4, r5, r6, pc}
9:	movs	r0, #2
	movs	r1, #1
	bl	answer
	pop	{r4, r5, r6, pc}

@ post_display - r0 = display code into the display queue (blocking, as the vendor code does).
	.thumb_func
post_display:
	push	{r0, lr}
	ldr	r0, =DISPLAY_QUEUE
	ldr	r0, [r0]
	mov	r1, sp
	mvn	r2, #0
	bl	queue_send_timeout
	pop	{r1, pc}

@ CAL_READ: offset (u32) -> total 0x800 (u32), up to 256 bytes of 0x08006000 + offset.
	.thumb_func
cmd_cal_read:
	push	{r4, r5, r6, lr}
	cmp	r6, #4
	bne	9f
	ldr	r4, [r5]			@ r4 = offset
	cmp	r4, #0x800
	bhs	9f
	ldr	r5, =ANSWER
	mov	r0, #0x800
	str	r0, [r5, #1]
	rsb	r6, r4, #0x800			@ r6 = min(256, 0x800 - offset)
	cmp	r6, #256
	it	hi
	movhi	r6, #256
	add	r0, r5, #5
	ldr	r1, =0x08006000
	add	r1, r1, r4
	mov	r2, r6
	bl	copy_bytes_n
	movs	r0, #0
	add	r1, r6, #5
	bl	answer
	pop	{r4, r5, r6, pc}
9:	movs	r0, #2
	movs	r1, #1
	bl	answer
	pop	{r4, r5, r6, pc}

@ DRIVE: 1 = share the drive (UI page 7, display code 0x15 draws its screen; the task re-enumerates
@ with the drive), 0 = back to the meter page (key 17; leaving page 7 re-enumerates without it).
	.thumb_func
cmd_drive:
	push	{r4, lr}
	cmp	r6, #1
	bne	9f
	ldrb	r0, [r5]
	cbz	r0, 1f
	ldr	r0, =UI_PAGE
	movs	r1, #7
	strb	r1, [r0]
	movs	r0, #0x15
	bl	post_display
	b	2f
1:	ldr	r0, =UI_PAGE
	ldrb	r0, [r0]
	cmp	r0, #7
	bne	2f
	movs	r0, #17
	bl	post_key
2:	movs	r0, #0
	movs	r1, #1
	bl	answer
	pop	{r4, pc}
9:	movs	r0, #2
	movs	r1, #1
	bl	answer
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ Firmware update (PROTOCOL.md 4.11). The file system calls take the storage lock (src/storage.s)
@ themselves; sched_suspend / sched_resume (scheduler suspended) are for short consistent copies of
@ RAM that other tasks change, never around flash or file calls (a lock wait cannot sleep then).
@ ----------------------------------------------------------------------------
	.global	sched_suspend
	.thumb_func
sched_suspend:
	b	increment_word_200061e4

	.global	sched_resume
	.thumb_func
sched_resume:
	push	{r4, lr}
	bl	fn_08042c10			@ resume all; 0 = a switch is owed
	cbnz	r0, 1f
	ldr	r0, =0xE000ED04
	mov	r1, #0x10000000
	str	r1, [r0]
1:	pop	{r4, pc}

@ FW_BEGIN: total (u32), CRC-32 (u32). Refused while the drive is shared. Creates 2:/UPDATE and opens
@ 2:/UPDATE/APP.BIN for writing (create / truncate).
	.thumb_func
cmd_fw_begin:
	push	{r4, r5, r6, lr}
	cmp	r6, #8
	bne	8f
	ldrb	r0, [r4, #V_SHARED]
	cbnz	r0, 7f
	ldr	r0, [r5, #0]
	cmp	r0, #8
	blo	8f
	ldr	r1, =APP_END - APP_BASE
	cmp	r0, r1
	bhi	8f
	tst	r0, #3
	bne	8f
	bl	fw_close			@ a previous transfer is dropped
	ldr	r0, [r5, #0]
	str	r0, [r4, #V_FWTOT]
	ldr	r0, [r5, #4]
	str	r0, [r4, #V_FWCRC]
	movs	r0, #0
	str	r0, [r4, #V_FWPOS]
	strb	r0, [r4, #V_FWOK]
	mvn	r0, #0
	str	r0, [r4, #V_FWRUN]
	movw	r0, #0x102c			@ file object (the size the firmware uses)
	bl	alloc_units_of_32_bytes
	cbz	r0, 6f
	str	r0, [r4, #V_FWOBJ]
	bl	storage_lock
	ldr	r0, =s_update_dir
	bl	dir_create			@ result ignored: the directory may exist
	ldr	r0, [r4, #V_FWOBJ]
	ldr	r1, =s_update_file
	movs	r2, #10				@ write, create / truncate
	bl	file_open
	mov	r5, r0
	bl	storage_unlock
	cbnz	r5, 5f
	movs	r0, #0
	movs	r1, #1
	bl	answer
	pop	{r4, r5, r6, pc}
5:	bl	fw_free
6:	movs	r0, #5
	movs	r1, #1
	bl	answer
	pop	{r4, r5, r6, pc}
7:	movs	r0, #3
	movs	r1, #1
	bl	answer
	pop	{r4, r5, r6, pc}
8:	movs	r0, #2
	movs	r1, #1
	bl	answer
	pop	{r4, r5, r6, pc}

@ fw_close - closes and frees an open staged file (nothing when none). fw_free - frees the object only.
	.global	fw_close
	.thumb_func
fw_close:
	push	{r4, lr}
	ldr	r4, =V
	ldr	r0, [r4, #V_FWOBJ]
	cbz	r0, 1f
	bl	storage_lock
	ldr	r0, [r4, #V_FWOBJ]
	bl	file_close
	bl	storage_unlock
	bl	fw_free
1:	pop	{r4, pc}

	.thumb_func
fw_free:
	push	{r4, lr}
	ldr	r4, =V
	ldr	r0, [r4, #V_FWOBJ]
	cbz	r0, 1f
	bl	free_units_of_32_bytes
	movs	r0, #0
	str	r0, [r4, #V_FWOBJ]
1:	pop	{r4, pc}

@ FW_DATA: offset (u32) + chunk; the offset must equal the bytes written so far, the total must not be
@ exceeded. Writes the chunk and updates the running CRC-32.
	.thumb_func
cmd_fw_data:
	push	{r4, r5, r6, r7, r8, lr}
	sub	sp, #8
	ldr	r0, [r4, #V_FWOBJ]
	cbz	r0, 7f
	cmp	r6, #5
	blo	8f
	ldr	r0, [r5, #0]
	ldr	r1, [r4, #V_FWPOS]
	cmp	r0, r1
	bne	8f
	sub	r7, r6, #4			@ r7 = chunk length
	add	r0, r1, r7
	ldr	r2, [r4, #V_FWTOT]
	cmp	r0, r2
	bhi	8f
	add	r8, r5, #4			@ r8 = chunk
	bl	storage_lock
	ldr	r0, [r4, #V_FWOBJ]
	mov	r1, r8
	mov	r2, r7
	mov	r3, sp
	bl	file_write
	mov	r6, r0
	bl	storage_unlock
	cbnz	r6, 6f
	ldr	r0, [sp]
	cmp	r0, r7
	bne	6f
	ldr	r0, [r4, #V_FWRUN]
	mov	r1, r8
	mov	r2, r7
	bl	crc32_update
	str	r0, [r4, #V_FWRUN]
	ldr	r0, [r4, #V_FWPOS]
	add	r0, r0, r7
	str	r0, [r4, #V_FWPOS]
	movs	r0, #0
	movs	r1, #1
	bl	answer
	add	sp, #8
	pop	{r4, r5, r6, r7, r8, pc}
6:	movs	r0, #5
	movs	r1, #1
	bl	answer
	add	sp, #8
	pop	{r4, r5, r6, r7, r8, pc}
7:	movs	r0, #3
	movs	r1, #1
	bl	answer
	add	sp, #8
	pop	{r4, r5, r6, r7, r8, pc}
8:	movs	r0, #2
	movs	r1, #1
	bl	answer
	add	sp, #8
	pop	{r4, r5, r6, r7, r8, pc}

@ FW_END: closes the file; OK only when all bytes were written and the CRC-32 matches (V_FWOK).
	.thumb_func
cmd_fw_end:
	push	{r4, lr}
	ldr	r0, [r4, #V_FWOBJ]
	cbz	r0, 7f
	bl	fw_close
	ldr	r0, [r4, #V_FWPOS]
	ldr	r1, [r4, #V_FWTOT]
	cmp	r0, r1
	bne	6f
	ldr	r0, [r4, #V_FWRUN]
	mvn	r0, r0
	ldr	r1, [r4, #V_FWCRC]
	cmp	r0, r1
	bne	6f
	movs	r0, #1
	strb	r0, [r4, #V_FWOK]
	movs	r0, #0
	movs	r1, #1
	bl	answer
	pop	{r4, pc}
6:	movs	r0, #7
	movs	r1, #1
	bl	answer
	pop	{r4, pc}
7:	movs	r0, #3
	movs	r1, #1
	bl	answer
	pop	{r4, pc}

@ FW_INSTALL: needs a verified staged image and a bootloader with staged updates (hand-over version >=
@ BOOT_VERSION_STAGED); answers, disconnects, leaves the request {magic, CRC, length, ~magic} at
@ REQ_ADDR and resets: the bootloader installs the image and starts it.
	.thumb_func
cmd_fw_install:
	push	{r4, lr}
	ldrb	r0, [r4, #V_FWOK]
	cbz	r0, 7f
	ldr	r0, [r4, #V_HAND + 0]
	ldr	r1, =HANDOVER_MAGIC
	cmp	r0, r1
	bne	6f
	ldr	r0, [r4, #V_HAND + 8]
	cmp	r0, #BOOT_VERSION_STAGED
	blo	6f
	movs	r0, #0
	movs	r1, #1
	bl	answer
	bl	drain_and_disconnect
	bl	storage_quiesce			@ flash idle and written back before the reset
	ldr	r0, =REQ_ADDR
	ldr	r1, =REQ_MAGIC
	str	r1, [r0, #0]
	ldr	r2, [r4, #V_FWCRC]
	str	r2, [r0, #4]
	ldr	r2, [r4, #V_FWTOT]
	str	r2, [r0, #8]
	mvn	r1, r1
	str	r1, [r0, #12]
	dsb
	ldr	r0, =0xE000ED0C
	ldr	r1, =0x05FA0004
	str	r1, [r0]
	dsb
1:	b	1b
6:	movs	r0, #6
	movs	r1, #1
	bl	answer
	pop	{r4, pc}
7:	movs	r0, #3
	movs	r1, #1
	bl	answer
	pop	{r4, pc}

@ MEM_READ: address (u32), length (u16, at most 256). Read-only, allowed for the internal flash
@ 0x08000000..0x080FFFFF and the RAM words 0x20037FB0..0x20037FFF (fault record, src/fault.s; request /
@ hand-over words; diagnostics); anything else: status 6.
	.thumb_func
cmd_mem_read:
	push	{r4, r5, r6, lr}
	cmp	r6, #6
	bne	8f
	ldr	r4, [r5, #0]			@ r4 = address
	ldrh	r6, [r5, #4]			@ r6 = length
	cmp	r6, #256
	bhi	8f
	adds	r0, r4, r6			@ r0 = end
	bcs	7f				@ the range wraps past 0xFFFFFFFF: outside both windows
	ldr	r1, =0x08000000
	cmp	r4, r1
	blo	1f
	ldr	r1, =0x08100000
	cmp	r0, r1
	bls	2f
1:	ldr	r1, =FAULT_ADDR
	cmp	r4, r1
	blo	7f
	ldr	r1, =0x20038000
	cmp	r0, r1
	bhi	7f
2:	ldr	r0, =ANSWER + 1
	mov	r1, r4
	mov	r2, r6
	bl	copy_bytes_n
	movs	r0, #0
	add	r1, r6, #1
	bl	answer
	pop	{r4, r5, r6, pc}
7:	movs	r0, #6
	movs	r1, #1
	bl	answer
	pop	{r4, r5, r6, pc}
8:	movs	r0, #2
	movs	r1, #1
	bl	answer
	pop	{r4, r5, r6, pc}

@ crc32_update - r0 = register (start 0xFFFFFFFF), r1 = data, r2 = length; zlib CRC-32 register.
	.thumb_func
crc32_update:
	ldr	r12, =0xEDB88320
1:	cbz	r2, 3f
	ldrb	r3, [r1], #1
	eors	r0, r0, r3
	movs	r3, #8
2:	lsrs	r0, r0, #1
	it	cs
	eorcs	r0, r0, r12
	subs	r3, #1
	bne	2b
	subs	r2, #1
	b	1b
3:	bx	lr

	.ltorg

@ ----------------------------------------------------------------------------
@ Descriptors and texts.
@ ----------------------------------------------------------------------------
	.p2align 2
rec_device:
	.short	18, 0
	.word	desc_device
rec_config_cdc:
	.short	75, 0
	.word	desc_config_cdc
rec_config_shared:
	.short	98, 0
	.word	desc_config_shared
rec_manufacturer:
	.short	20, 0
	.word	str_manufacturer
rec_product:
	.short	12, 0
	.word	str_product

desc_device:
	.byte	18, 1, 0x00, 0x02, 0xEF, 0x02, 0x01, 64	@ USB 2.0, class from the interface association
	.short	0x2E3C, 0x2C53, 0x0100			@ VID (Artery), PID 0x2C53 (owner), version 1.00
	.byte	1, 2, 3, 1				@ strings: manufacturer, product, serial; 1 configuration
	.p2align 1
desc_config_cdc:					@ CDC only: interfaces 0 (communication), 1 (data)
	.byte	9, 2, 75, 0, 2, 1, 0, 0x80, 50
	.byte	8, 0x0B, 0, 2, 0x02, 0x02, 0x01, 0		@ interface association: 0..1, CDC ACM
	.byte	9, 4, 0, 0, 1, 0x02, 0x02, 0x01, 0		@ interface 0: communication, ACM, AT commands
	.byte	5, 0x24, 0x00, 0x10, 0x01			@ header, CDC 1.10
	.byte	5, 0x24, 0x01, 0x00, 1				@ call management: data interface 1
	.byte	4, 0x24, 0x02, 0x02				@ ACM: line coding and control line state
	.byte	5, 0x24, 0x06, 0, 1				@ union: master 0, slave 1
	.byte	7, 5, 0x82, 0x03, 16, 0, 16			@ EP2 IN interrupt 16 bytes, 16 ms
	.byte	9, 4, 1, 0, 2, 0x0A, 0, 0, 0			@ interface 1: data
	.byte	7, 5, 0x03, 0x02, 64, 0, 0			@ EP3 OUT bulk 64
	.byte	7, 5, 0x83, 0x02, 64, 0, 0			@ EP3 IN bulk 64
desc_config_shared:					@ drive + CDC: interfaces 0 (MSC), 1, 2 (CDC)
	.byte	9, 2, 98, 0, 3, 1, 0, 0x80, 50
	.byte	9, 4, 0, 0, 2, 0x08, 0x06, 0x50, 0		@ interface 0: mass storage, SCSI, bulk-only
	.byte	7, 5, 0x81, 0x02, 64, 0, 0			@ EP1 IN bulk 64
	.byte	7, 5, 0x01, 0x02, 64, 0, 0			@ EP1 OUT bulk 64
	.byte	8, 0x0B, 1, 2, 0x02, 0x02, 0x01, 0		@ interface association: 1..2, CDC ACM
	.byte	9, 4, 1, 0, 1, 0x02, 0x02, 0x01, 0
	.byte	5, 0x24, 0x00, 0x10, 0x01
	.byte	5, 0x24, 0x01, 0x00, 2
	.byte	4, 0x24, 0x02, 0x02
	.byte	5, 0x24, 0x06, 1, 2
	.byte	7, 5, 0x82, 0x03, 16, 0, 16
	.byte	9, 4, 2, 0, 2, 0x0A, 0, 0, 0
	.byte	7, 5, 0x03, 0x02, 64, 0, 0
	.byte	7, 5, 0x83, 0x02, 64, 0, 0
desc_config_shared_end:
	.p2align 1
str_manufacturer:					@ "F***nirsi" (owner)
	.byte	20, 3
	.short	'F', '*', '*', '*', 'n', 'i', 'r', 's', 'i'
str_product:						@ "2C53T"
	.byte	12, 3
	.short	'2', 'C', '5', '3', 'T'

s_task_name:		.asciz	"usb"
s_update_dir:		.asciz	"2:/UPDATE"
s_update_file:		.asciz	"2:/UPDATE/APP.BIN"

	.if	(desc_config_shared - desc_config_cdc) != 75
	.error	"CDC-only configuration descriptor must be 75 bytes"
	.endif
	.if	(desc_config_shared_end - desc_config_shared) != 98
	.error	"shared configuration descriptor must be 98 bytes"
	.endif
	.if	V + V_END > 0x20037FE0
	.error	"usb_ctl RAM overlaps the bootloader words"
	.endif

