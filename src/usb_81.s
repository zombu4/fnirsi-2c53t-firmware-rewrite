@ usb_81.s - the USB device event handler (endpoint transfer events, setup requests, bus reset / suspend / resume)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ usb_device_event_handler - device-side event and control-transfer handler.
@ No parameters, no return value.
@
@ Data it works on:
@   device block pointer = word at 0x20002b24 (kept in r11; flags word at +0x44,
@   mask word at +0x40, endpoint register words at +idx*4). The structure at
@   0x20002b24 (r10) is also passed as first argument to every callback.
@   word at 0x20002b28 = callback table (slots 0..8 are called here).
@   word at 0x20002b2c = descriptor-getter table (slots 0, 2, 4, 5, 6, 7, 8, 9
@   are called).
@   0x20-byte endpoint records: IN at 0x20002b30+n*0x20, OUT at
@   0x20002c30+n*0x20 (record byte +0 = endpoint register index, byte +0xb =
@   halt flag).
@   packet RAM 0x40006000, buffer-descriptor index word 0x40005c50, endpoint
@   registers 0x40005c00+idx*4.
@
@ Loop while flag bit15 is set: idx = endpoint register index (flags & 0xf).
@  (a) endpoint-word bit7 = IN complete: clears it with mask 0x8f0f, stores the
@      count (low 10 bits of the word at 0x40006004+(word 0x40005c50+idx*8)*2)
@      in halfword 0x20002b40+idx*0x20 and adds it to the pointer word
@      0x20002b44+idx*0x20.
@      idx != 0 with halfword 0x20002b3e+idx*0x20 != 0 continues with
@      08040eb4(dev,idx,pointer,halfword); idx != 0 with that halfword 0 calls
@      table slot 5(dev,idx) when the slot is nonzero and state 0x20002d48 == 3.
@      idx 0 with state 0x20002d44 == 2: while halfword 0x20002b4a > halfword
@      0x20002b38 it subtracts 0x20002b38 from 0x20002b4a and continues with
@      08040eb4; otherwise, when 0x20002b48 == 0x20002b38 and 0x20002b4c >=
@      0x20002b38 and 0x20002b4c < 0x20002d46, it sends the zero-length packet
@      08040eb4(dev,0,0,0), clears 0x20002b48, 0x20002c44, 0x20002c3e and
@      re-arms with (x & 0x3f0f) ^ 0xb080, else it calls table slot 3(dev)
@      (slot nonzero and state 0x20002d48 == 3), sets 0x20002d44 = 5, clears
@      0x20002c44 and 0x20002c3e and re-arms the same way.
@      Applies a pending address (0x20002d4a & 0x7f into +0x4c, bit 0x80 set)
@      when state 2.
@  (b) endpoint-word bit11 clear and bit15 set = OUT complete: clears with mask
@      0xf8f, copies the received halfwords from 0x40006000 into the record
@      buffer (4-way unrolled halfword loops), re-arms with 0xf0f|0x80c0 or
@      (x&0x3f0f)^0xb080, adds the received count (low 10 bits of the word at
@      0x4000600c+(word 0x40005c50+idx*8)*2) to halfword 0x20002c40+idx*0x20
@      and to pointer word 0x20002c44+idx*0x20 and updates halfword
@      0x20002c3e+idx*0x20. Calls table slot 4(dev) (idx 0, state 0x20002d44
@      == 3, halfword 0x20002c4a <= halfword 0x20002c38, slot nonzero) or slot
@      6(dev,idx) (other idx, slot nonzero, state 0x20002d48 == 3) when the
@      transfer is complete.
@  (c) endpoint-word bit11 set = setup packet: copies (count+1)>>1 halfwords
@      (count = low 10 bits of the word at 0x4000600c+(word 0x40005c50+idx*8)*2)
@      from packet RAM to 0x20002d38, then builds the request record 0x20002d30
@      from the bytes 0x20002d38..0x20002d3f (type, request, wValue d32, wIndex
@      d34, wLength d36/d46), state 0x20002d44 = 1.
@      Recipient (type&0x1f) 2 = endpoint: class requests (type&0x60 == 0x20)
@      go to table slot 2(dev,&d30); request 3/1 set/clear the endpoint halt
@      (masks 0x3f0f/0xf3f with 0x9080/0x8090/0x80b0/0xb080, record byte +0xb);
@      request 0 returns the halt state via 08040eb4.
@      Recipient 1 = interface: table slot 2 when state 3.
@      Recipient 0 with type&0x60 != 0: table slot 2.
@      Recipient 0 base requests (switch on byte 0x20002d39):
@        0 returns device status word 0x20002d4e (bit1 from 0x20002d4b);
@        1/3 with wValue 1 clear/set remote-wakeup flag 0x20002d4b and call
@          slot 2;
@        5 stores address wValue&0x7f in 0x20002d4a and sets state 0x20002d48 =
@          2 (1 when address 0);
@        6 get-descriptor by wValue high byte: 1 -> table2[0], 2 -> table2[2],
@          3 -> table2[4,5,6,7,9,8] by low byte 0..5; replies min(wLength,
@          descriptor halfword[0]) bytes from the pointer at descriptor+4 via
@          08040eb4;
@        8 returns configuration byte 0x20002d4d (or 0 in state 2);
@        9 stores the value byte (wValue low) in 0x20004e72 and stalls when
@          wIndex or wLength is nonzero, else: state 3 with value != 0 calls
@          slot 1, sets 0x20002d4d = byte 0x20004e72 and calls slot 0 only when
@          the value equals the current byte 0x20002d4d; state 3 with value 0
@          sets state 2, 0x20002d4d = 0 and calls slot 1; state 2 with value
@          != 0 sets 0x20002d4d = value, state 3 and calls slot 0; any other
@          state stalls.
@      The handled cases then send the zero-length status via
@      08040eb4(dev,0,0,0) with 0x20002d44 = 4. Any other request stalls
@      endpoint 0 (registers idx byte 0x20002c30 and 0x20002b30 with
@      0x3f0f^0x9080 and 0xf3f^0x8090, flags 0x20002c3b/0x20002b3b = 1).
@
@ After the loop, on the saved flags:
@   bit10 (reset) writes 0xfffffbff to +0x44, sets 0x20000010 = 0x40, calls
@     08040990(), 08040b24(dev,0,0), 08040b24(dev,0x80,0), clears the address
@     field in +0x4c and sets its bit 0x80, state 0x20002d48 = 1, calls slot
@     8(dev,1);
@   (flags & mask) bit9 writes 0xfffffdff and calls slot 7(dev);
@   bit8 writes 0xfffffeff;
@   bit11 writes 0xfffff7ff, saves state to 0x20002d49, state = 4, ORs 8 then 4
@     into +0x40, calls slot 8(dev,2);
@   bit12 clears the values 8 and 4 (bits 3 and 2) of +0x40, restores state
@     from 0x20002d49, calls slot 8(dev,3) and writes 0xffffefff.
@
@ Purpose: device-side event and control-transfer handler (the request numbers
@ 0/1/3/5/6/8/9 and descriptor types 1/2/3 in the switch are the device-request
@ set).
@ ----------------------------------------------------------------------------
	.section .text.usb_device_event_handler,"ax",%progbits
	.p2align 2
	.global usb_device_event_handler
	.thumb_func
	.type usb_device_event_handler, %function
usb_device_event_handler:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0xc
	movw	r10, #0x2b24
	movt	r10, #0x2000
	ldr.w	r11, [r10, #0x0]	@ device block pointer
	ldr.w	r0, [r11, #0x44]	@ flags word
	ldr.w	r1, [r11, #0x40]	@ mask word
	strd	r1, r0, [sp, #0x4]
	lsls	r0, r0, #0x10
	itt	mi
	ldrmi.w	r0, [r11, #0x44]
	lslsmi.w	r1, r0, #0x10
	bmi.w	.L0802ea1a		@ flag bit15 set: endpoint loop
.L0802e912:
	ldr	r4, [sp, #0x8]
	lsls	r0, r4, #0x15
	bpl.n	.L0802e96e
	mvn	r0, #0x400		@ bit10 (reset): write 0xfffffbff
	str.w	r0, [r11, #0x44]
	movw	r0, #0x10
	movt	r0, #0x2000
	movs	r1, #0x40
	strh	r1, [r0, #0x0]		@ 0x20000010 = 0x40
	bl	fn_08040990
	mov	r0, r10
	movs	r1, #0x0
	movs	r2, #0x0
	bl	fn_08040b24
	mov	r0, r10
	movs	r1, #0x80
	movs	r2, #0x0
	bl	fn_08040b24
	ldrd	r0, r1, [r10, #0x0]
	ldr	r2, [r0, #0x4c]
	bic	r2, r2, #0x7f		@ clear the address field
	str	r2, [r0, #0x4c]
	ldr	r2, [r0, #0x4c]
	orr	r2, r2, #0x80
	str	r2, [r0, #0x4c]
	ldr	r2, [r1, #0x20]		@ callback table slot 8
	movs	r0, #0x1
	strb.w	r0, [r10, #0x224]	@ state 0x20002d48 = 1
	cbz	r2, .L0802e96e
	movw	r0, #0x2b24
	movt	r0, #0x2000
	movs	r1, #0x1
	blx	r2			@ slot 8(dev,1)
.L0802e96e:
	ldr	r0, [sp, #0x4]
	and.w	r5, r0, r4
	lsls	r0, r5, #0x16
	bpl.n	.L0802e992
	mvn	r0, #0x200		@ bit9: write 0xfffffdff
	str.w	r0, [r11, #0x44]
	ldr.w	r0, [r10, #0x4]
	ldr	r1, [r0, #0x1c]		@ callback table slot 7
	cbz	r1, .L0802e992
	movw	r0, #0x2b24
	movt	r0, #0x2000
	blx	r1			@ slot 7(dev)
.L0802e992:
	lsls	r0, r5, #0x17
	itt	mi
	mvnmi	r0, #0x100		@ bit8: write 0xfffffeff
	strmi.w	r0, [r11, #0x44]
	lsls	r0, r5, #0x14
	bpl.n	.L0802e9dc
	mvn	r0, #0x800		@ bit11: write 0xfffff7ff
	str.w	r0, [r11, #0x44]
	ldrb.w	r0, [r10, #0x224]
	strb.w	r0, [r10, #0x225]	@ save state to 0x20002d49
	movs	r0, #0x4
	strb.w	r0, [r10, #0x224]	@ state = 4
	ldrd	r0, r1, [r10, #0x0]
	ldr	r2, [r0, #0x40]
	orr	r2, r2, #0x8
	str	r2, [r0, #0x40]
	ldr	r2, [r0, #0x40]
	orr	r2, r2, #0x4
	str	r2, [r0, #0x40]
	ldr	r2, [r1, #0x20]		@ callback table slot 8
	cbz	r2, .L0802e9dc
	movw	r0, #0x2b24
	movt	r0, #0x2000
	movs	r1, #0x2
	blx	r2			@ slot 8(dev,2)
.L0802e9dc:
	lsls	r0, r5, #0x13
	bpl.n	.L0802ea14
	ldrd	r0, r1, [r10, #0x0]
	ldr	r2, [r0, #0x40]
	bic	r2, r2, #0x8
	str	r2, [r0, #0x40]
	ldr	r2, [r0, #0x40]
	bic	r2, r2, #0x4
	str	r2, [r0, #0x40]
	ldr	r2, [r1, #0x20]		@ callback table slot 8
	ldrb.w	r0, [r10, #0x225]
	strb.w	r0, [r10, #0x224]	@ restore state from 0x20002d49
	cbz	r2, .L0802ea0c
	movw	r0, #0x2b24
	movt	r0, #0x2000
	movs	r1, #0x3
	blx	r2			@ slot 8(dev,3)
.L0802ea0c:
	mvn	r0, #0x1000		@ bit12: write 0xffffefff
	str.w	r0, [r11, #0x44]
.L0802ea14:
	add	sp, #0xc
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L0802ea1a:
	movw	r9, #0x5c00
	movt	r9, #0x4000
	mov	r1, r11
.L0802ea24:
	and	r5, r0, #0xf		@ idx = flags & 0xf
	ldr.w	r1, [r1, r5, lsl #0x2]	@ endpoint register word
	lsls	r0, r1, #0x18
	bmi.n	.L0802ead4		@ bit7: IN complete
	lsls	r0, r1, #0x14
	bmi.w	.L0802eb58		@ bit11: setup packet
	lsls	r0, r1, #0x10
	bpl.w	.L0802f200
	ldr.w	r0, [r9, r5, lsl #0x2]	@ OUT complete: clear with mask 0xf8f
	movw	r2, #0xf8f
	ands	r0, r2
	str.w	r0, [r9, r5, lsl #0x2]
	add.w	r0, r10, r5, lsl #0x5
	ldrb.w	r2, [r0, #0x116]
	cmp	r2, #0x0
	beq.w	.L0802ed18
	ldr.w	r2, [r9, #0x50]
	lsls	r1, r1, #0x11
	add.w	r1, r2, r5, lsl #0x3
	movw	r2, #0x600c
	movt	r2, #0x4000
	bmi.w	.L0802ed9c
	ldr.w	r1, [r2, r1, lsl #0x1]
	movs	r2, #0x0
	bfc	r1, #0xa, #0x16		@ count = low 10 bits
	adds	r7, r1, #0x1
	cmp.w	r2, r7, lsr #0x1
	beq.w	.L0802ee16
	ldrh.w	r3, [r0, #0x112]
	lsr.w	r12, r7, #0x1
	ldr.w	r2, [r0, #0x120]
	add.w	r3, r9, r3, lsl #0x1
	sub.w	r6, r12, #0x1
	cmp	r6, #0x3
	add.w	r3, r3, #0x400
	bcc.w	.L0802edfc
	mvn	r6, #0x3
	and.w	r7, r6, r7, lsr #0x1
	rsbs	r7, r7, #0
	nop
.L0802eaac:
	ldrh.w	r6, [r3], #0x10		@ 4-way unrolled halfword copy
	adds	r7, #0x4
	strh	r6, [r2], #0x8
	ldrh.w	r6, [r3, #-0xc]
	strh	r6, [r2, #-0x6]
	ldrh.w	r6, [r3, #-0x8]
	strh	r6, [r2, #-0x4]
	ldrh.w	r6, [r3, #-0x4]
	strh	r6, [r2, #-0x2]
	bne.n	.L0802eaac
	b.n	.L0802edfc
	.byte	0x00, 0xbf		@ padding
.L0802ead4:
	ldr.w	r0, [r9, r5, lsl #0x2]	@ IN complete: clear bit7 with mask 0x8f0f
	movw	r1, #0x8f0f
	ands	r0, r1
	str.w	r0, [r9, r5, lsl #0x2]
	ldr.w	r0, [r9, #0x50]
	movw	r1, #0x600c
	add.w	r0, r0, r5, lsl #0x3
	movt	r1, #0x4000
	add.w	r0, r1, r0, lsl #0x1
	ldr.w	r0, [r0, #-0x8]
	add.w	r8, r10, r5, lsl #0x5
	ldr.w	r1, [r8, #0x20]
	bfc	r0, #0xa, #0x16		@ count = low 10 bits
	adds	r2, r1, r0
	cmp	r5, #0x0
	strh.w	r0, [r8, #0x1c]
	str.w	r2, [r8, #0x20]
	beq.w	.L0802ec60
	ldrh.w	r3, [r8, #0x1a]
	cmp	r3, #0x0
	beq.w	.L0802ec60
	mov	r0, r10
	mov	r1, r5
.L0802eb24:
	bl	fn_08040eb4
.L0802eb28:
	ldrb.w	r0, [r10, #0x224]
.L0802eb2c:
	cmp	r0, #0x2
	bne.w	.L0802f200
	ldrb.w	r0, [r10, #0x226]
	cmp	r0, #0x0
	beq.w	.L0802f200
	ldr.w	r1, [r10, #0x0]
	ldr	r2, [r1, #0x4c]
	bfi	r2, r0, #0, #7		@ pending address into +0x4c
	str	r2, [r1, #0x4c]
	ldr	r0, [r1, #0x4c]
	orr	r0, r0, #0x80
	str	r0, [r1, #0x4c]
	movs	r0, #0x0
	strb.w	r0, [r10, #0x226]
	b.n	.L0802f200
.L0802eb58:
	ldr.w	r0, [r9, #0x50]		@ setup packet
	movw	r1, #0x600c
	add.w	r0, r0, r5, lsl #0x3
	movt	r1, #0x4000
	ldr.w	r1, [r1, r0, lsl #0x1]
	movs	r2, #0x0
	bfc	r1, #0xa, #0x16		@ count = low 10 bits
	adds	r3, r1, #0x1
	add.w	r0, r10, r5, lsl #0x5
	cmp.w	r2, r3, lsr #0x1
	strh.w	r1, [r0, #0x11c]
	beq.n	.L0802ebe4
	ldrh.w	r0, [r0, #0x112]
	lsrs	r2, r3, #0x1
	add.w	r0, r9, r0, lsl #0x1
	subs	r1, r2, #0x1
	add.w	r0, r0, #0x400
	cmp	r1, #0x3
	add.w	r1, r10, #0x214		@ destination 0x20002d38
	blo.n	.L0802ebc8
	mvn	r7, #0x3
	and.w	r3, r7, r3, lsr #0x1
	rsbs	r3, r3, #0
.L0802eba4:
	ldrh	r7, [r0], #0x10
	adds	r3, #0x4
	strh	r7, [r1], #0x8
	ldrh	r7, [r0, #-0xc]
	strh	r7, [r1, #-0x6]
	ldrh	r7, [r0, #-0x8]
	strh	r7, [r1, #-0x4]
	ldrh	r7, [r0, #-0x4]
	strh	r7, [r1, #-0x2]
	bne.n	.L0802eba4
.L0802ebc8:
	ands.w	r2, r2, #0x3
	beq.n	.L0802ebe4
	ldrh	r3, [r0, #0x0]
	cmp	r2, #0x1
	strh	r3, [r1, #0x0]
	beq.n	.L0802ebe4
	ldrh	r3, [r0, #0x4]
	cmp	r2, #0x2
	strh	r3, [r1, #0x2]
	itt	ne
	ldrhne	r0, [r0, #0x8]
	strhne	r0, [r1, #0x4]
	nop
.L0802ebe4:
	ldr.w	r0, [r9, #0x0]
	movw	r1, #0xf8f
	ands	r0, r1
	str.w	r0, [r9, #0x0]
	ldrb.w	r4, [r10, #0x214]	@ request type
	ldrb.w	r8, [r10, #0x218]
	ldrb.w	r7, [r10, #0x219]
	ldrb.w	r0, [r10, #0x216]
	ldrb.w	r3, [r10, #0x217]
	movs	r5, #0x1
	ldrb.w	r1, [r10, #0x215]	@ request
	orr.w	r6, r8, r7, lsl #0x8	@ wIndex
	ldrh.w	r7, [r10, #0x21a]	@ wLength
	strb.w	r5, [r10, #0x220]	@ state 0x20002d44 = 1
	and	r5, r4, #0x1f		@ recipient
	orr.w	r2, r0, r3, lsl #0x8	@ wValue
	cmp	r5, #0x2
	strb.w	r4, [r10, #0x20c]	@ request record 0x20002d30
	strb.w	r1, [r10, #0x20d]
	strh.w	r2, [r10, #0x20e]
	strh.w	r6, [r10, #0x210]
	strh.w	r7, [r10, #0x212]
	strh.w	r7, [r10, #0x222]
	beq.n	.L0802ecae
	cmp	r5, #0x1
	beq.n	.L0802ecf4
	cmp	r5, #0x0
	bne.w	.L0802f200
	tst.w	r4, #0x60
	beq.w	.L0802eedc
.L0802ec4e:
	ldr.w	r0, [r10, #0x4]
	add.w	r1, r10, #0x20c
	ldr	r2, [r0, #0x8]		@ callback table slot 2
	mov	r0, r10
	blx	r2			@ slot 2(dev,&d30)
	b.n	.L0802f200
	.byte	0x00, 0xbf		@ padding
.L0802ec60:
	cbz	r5, .L0802ec80
	ldr.w	r0, [r10, #0x4]
	ldr	r2, [r0, #0x14]		@ callback table slot 5
	cmp	r2, #0x0
	beq.w	.L0802eb28
	ldrb.w	r0, [r10, #0x224]
	cmp	r0, #0x3
	bne.w	.L0802eb2c
	mov	r0, r10
	mov	r1, r5
	blx	r2			@ slot 5(dev,idx)
	b.n	.L0802eb28
.L0802ec80:
	ldrb.w	r0, [r10, #0x220]
	cmp	r0, #0x2
	bne.w	.L0802eb28
	mov	r1, r8
	ldrh	r3, [r1, #0x26]!
	ldrh	r0, [r1, #-0x12]
	cmp	r3, r0
	bls.w	.L0802ef2a
	subs	r3, r3, r0
	uxth	r7, r3
	strh	r3, [r1, #0x0]
	cmp	r7, r0
	it	lo
	movlo	r0, r3
	uxth	r3, r0
	mov	r0, r10
	movs	r1, #0x0
	b.n	.L0802eb24
.L0802ecae:
	and	r0, r4, #0x60		@ recipient endpoint
	cmp	r0, #0x20
	bne.n	.L0802ecc8
	ldr.w	r0, [r10, #0x4]
	add.w	r1, r10, #0x20c
	ldr	r2, [r0, #0x8]		@ callback table slot 2
	mov	r0, r10
	blx	r2
	ldrb.w	r1, [r10, #0x20d]
.L0802ecc8:
	cmp	r1, #0x3
	beq.w	.L0802efac
	cmp	r1, #0x1
	beq.w	.L0802f00e
	cmp	r1, #0x0
	bne.w	.L0802f1c6
	ldrb.w	r0, [r10, #0x224]
	cmp	r0, #0x3
	beq.w	.L0802f084
	cmp	r0, #0x2
	bne.w	.L0802f1c6
	lsls.w	r0, r8, #0x19
	bne.w	.L0802f026
	b.n	.L0802f200
.L0802ecf4:
	ldrb.w	r0, [r10, #0x224]	@ recipient interface
	cmp	r0, #0x3
	bne.w	.L0802f1c6
	ldr.w	r0, [r10, #0x4]
	add.w	r1, r10, #0x20c
	ldr	r2, [r0, #0x8]		@ callback table slot 2
	mov	r0, r10
	blx	r2
	ldrh.w	r0, [r10, #0x212]
	cmp	r0, #0x0
	bne.w	.L0802f200
	b.n	.L0802f070
.L0802ed18:
	ldr.w	r1, [r9, #0x50]
	movw	r2, #0x600c
	add.w	r1, r1, r5, lsl #0x3
	movt	r2, #0x4000
	ldr.w	r1, [r2, r1, lsl #0x1]
	movs	r2, #0x0
	bfc	r1, #0xa, #0x16		@ count = low 10 bits
	adds	r7, r1, #0x1
	cmp.w	r2, r7, lsr #0x1
	beq.n	.L0802ee2a
	ldrh.w	r3, [r0, #0x112]
	lsrs	r6, r7, #0x1
	ldr.w	r2, [r0, #0x120]
	add.w	r3, r9, r3, lsl #0x1
	subs	r4, r6, #0x1
	cmp	r4, #0x3
	add.w	r3, r3, #0x400
	blo.n	.L0802ed80
	mvn	r4, #0x3
	and.w	r7, r4, r7, lsr #0x1
	rsbs	r7, r7, #0
.L0802ed5c:
	ldrh	r4, [r3], #0x10
	adds	r7, #0x4
	strh	r4, [r2], #0x8
	ldrh	r4, [r3, #-0xc]
	strh	r4, [r2, #-0x6]
	ldrh	r4, [r3, #-0x8]
	strh	r4, [r2, #-0x4]
	ldrh	r4, [r3, #-0x4]
	strh	r4, [r2, #-0x2]
	bne.n	.L0802ed5c
.L0802ed80:
	ands.w	r7, r6, #0x3
	beq.n	.L0802ee2a
	ldrh	r6, [r3, #0x0]
	cmp	r7, #0x1
	strh	r6, [r2, #0x0]
	beq.n	.L0802ee2a
	ldrh	r6, [r3, #0x4]
	cmp	r7, #0x2
	strh	r6, [r2, #0x2]
	beq.n	.L0802ee2a
	ldrh	r3, [r3, #0x8]
	strh	r3, [r2, #0x4]
	b.n	.L0802ee2a
.L0802ed9c:
	add.w	r1, r2, r1, lsl #0x1
	ldr	r1, [r1, #-0x8]
	movs	r2, #0x0
	bfc	r1, #0xa, #0x16		@ count = low 10 bits
	adds	r7, r1, #0x1
	cmp.w	r2, r7, lsr #0x1
	beq.n	.L0802ee16
	ldrh.w	r3, [r0, #0x110]
	lsr.w	r12, r7, #0x1
	ldr.w	r2, [r0, #0x120]
	add.w	r3, r9, r3, lsl #0x1
	sub.w	r6, r12, #0x1
	cmp	r6, #0x3
	add.w	r3, r3, #0x400
	blo.n	.L0802edfc
	mvn	r6, #0x3
	and.w	r7, r6, r7, lsr #0x1
	rsbs	r7, r7, #0
.L0802edd8:
	ldrh	r6, [r3], #0x10
	adds	r7, #0x4
	strh	r6, [r2], #0x8
	ldrh	r6, [r3, #-0xc]
	strh	r6, [r2, #-0x6]
	ldrh	r6, [r3, #-0x8]
	strh	r6, [r2, #-0x4]
	ldrh	r6, [r3, #-0x4]
	strh	r6, [r2, #-0x2]
	bne.n	.L0802edd8
.L0802edfc:
	ands.w	r7, r12, #0x3
	beq.n	.L0802ee16
	ldrh	r6, [r3, #0x0]
	cmp	r7, #0x1
	strh	r6, [r2, #0x0]
	beq.n	.L0802ee16
	ldrh	r6, [r3, #0x4]
	cmp	r7, #0x2
	strh	r6, [r2, #0x2]
	itt	ne
	ldrhne	r3, [r3, #0x8]
	strhne	r3, [r2, #0x4]
.L0802ee16:
	ldr.w	r2, [r9, r5, lsl #0x2]	@ re-arm with 0xf0f | 0x80c0
	movw	r3, #0xf0f
	ands	r2, r3
	movw	r3, #0x80c0
	orrs	r2, r3
	str.w	r2, [r9, r5, lsl #0x2]
.L0802ee2a:
	ldr.w	r7, [r0, #0x120]
	ldrh.w	r2, [r0, #0x11c]
	adds	r6, r7, r1
	ldrh.w	r7, [r0, #0x11a]
	add	r2, r1
	add.w	r3, r0, #0x11c
	strh.w	r2, [r0, #0x11c]
	cmp	r7, #0x0
	add.w	r2, r0, #0x11a
	str.w	r6, [r0, #0x120]
	it	ne
	cmpne	r5, #0x0
	bne.n	.L0802ee72
.L0802ee52:
	cbz	r5, .L0802ee8e
	ldr.w	r0, [r10, #0x4]
	ldr	r2, [r0, #0x18]		@ callback table slot 6
	cmp	r2, #0x0
	beq.w	.L0802f200
	ldrb.w	r0, [r10, #0x224]
	cmp	r0, #0x3
	bne.w	.L0802f200
	mov	r0, r10
	mov	r1, r5
	blx	r2			@ slot 6(dev,idx)
	b.n	.L0802f200
.L0802ee72:
	ldrh.w	r4, [r0, #0x114]
	cmp	r1, r4
	blo.n	.L0802ee52
	add.w	r0, r0, #0x120
	str	r6, [r0, #0x0]
	movs	r0, #0x0
	strh	r0, [r3, #0x0]
	cmp	r7, r4
	it	ls
	movls	r7, r4
	subs	r0, r7, r4
	b.n	.L0802eec4
.L0802ee8e:
	ldrb.w	r1, [r10, #0x220]
	cmp	r1, #0x3
	bne.w	.L0802f200
	ldrh.w	r7, [r0, #0x126]
	ldrh.w	r1, [r0, #0x114]
	cmp	r7, r1
	bls.w	.L0802f064
	subs	r7, r7, r1
	add.w	r0, r0, #0x126
	uxth	r6, r7
	strh	r7, [r0, #0x0]
	cmp	r6, r1
	it	hs
	movhs	r7, r1
	uxth	r0, r7
	movs	r7, #0x0
	strh	r7, [r3, #0x0]
	cmp	r0, r1
	it	ls
	movls	r0, r1
	subs	r0, r0, r1
.L0802eec4:
	strh	r0, [r2, #0x0]
	ldr.w	r0, [r9, r5, lsl #0x2]	@ re-arm with (x & 0x3f0f) ^ 0xb080
	movw	r1, #0x3f0f
	ands	r0, r1
	movw	r1, #0xb080
	eors	r0, r1
	str.w	r0, [r9, r5, lsl #0x2]
	b.n	.L0802f200
.L0802eedc:
	cmp	r1, #0x9
	bhi.w	.L0802f1c6
	tbh	[pc, r1, lsl #1]
.L0802eee6:
	.short	(.L0802eefa - .L0802eee6)/2
	.short	(.L0802f114 - .L0802eee6)/2
	.short	(.L0802f1c6 - .L0802eee6)/2
	.short	(.L0802f13e - .L0802eee6)/2
	.short	(.L0802f1c6 - .L0802eee6)/2
	.short	(.L0802f150 - .L0802eee6)/2
	.short	(.L0802f174 - .L0802eee6)/2
	.short	(.L0802f1c6 - .L0802eee6)/2
	.short	(.L0802f18e - .L0802eee6)/2
	.short	(.L0802f1b6 - .L0802eee6)/2
.L0802eefa:
	ldrb.w	r0, [r10, #0x224]	@ request 0: get status
	and	r0, r0, #0xfe
	cmp	r0, #0x2
	bne.w	.L0802f1c6
	ldrb.w	r0, [r10, #0x227]
	cbz	r0, .L0802ef1a
	ldrh.w	r0, [r10, #0x22a]
	orr	r0, r0, #0x2
	strh.w	r0, [r10, #0x22a]
.L0802ef1a:
	mov.w	r0, #0x20002
	str.w	r0, [r10, #0x26]
	movs	r0, #0x2
	addw	r2, r10, #0x22a
	b.n	.L0802f0b2
.L0802ef2a:
	mov	r1, r8
	ldrh	r2, [r1, #0x24]!
	cmp	r2, r0
	bne.n	.L0802ef72
	ldrh.w	r2, [r8, #0x28]
	cmp	r2, r0
	blo.n	.L0802ef72
	ldrh.w	r0, [r10, #0x222]
	cmp	r2, r0
	bhs.n	.L0802ef72
	movs	r4, #0x0
	strh	r4, [r1, #0x0]
	mov	r0, r10
	movs	r1, #0x0
	movs	r2, #0x0
	movs	r3, #0x0
	bl	fn_08040eb4		@ zero-length packet
	str.w	r4, [r8, #0x120]
	str.w	r4, [r8, #0x11a]
	ldr.w	r0, [r9, r5, lsl #0x2]
	movw	r1, #0x3f0f
	ands	r0, r1
	movw	r1, #0xb080
	eors	r0, r1
	str.w	r0, [r9, r5, lsl #0x2]
	b.n	.L0802eb28
.L0802ef72:
	ldr.w	r0, [r10, #0x4]
	ldr	r1, [r0, #0xc]		@ callback table slot 3
	cbz	r1, .L0802ef86
	ldrb.w	r0, [r10, #0x224]
	cmp	r0, #0x3
	bne.n	.L0802ef86
	mov	r0, r10
	blx	r1			@ slot 3(dev)
.L0802ef86:
	movs	r0, #0x5
	strb.w	r0, [r10, #0x220]	@ state 0x20002d44 = 5
	movs	r0, #0x0
	str.w	r0, [r10, #0x120]
	str.w	r0, [r10, #0x11a]
	ldr.w	r0, [r9, #0x0]
	movw	r1, #0x3f0f
	ands	r0, r1
	movw	r1, #0xb080
	eors	r0, r1
	str.w	r0, [r9, #0x0]
	b.n	.L0802eb28
.L0802efac:
	ldrb.w	r0, [r10, #0x224]	@ request 3: set feature
	cmp	r0, #0x3
	bne.n	.L0802f016
	ldrh.w	r0, [r10, #0x20e]
	cbnz	r0, .L0802effe
	orr	r0, r8, #0x80
	cmp	r0, #0x80
	beq.n	.L0802effe
	ands	r0, r8, #0x80
	and	r0, r8, #0x7f
	add.w	r0, r10, r0, lsl #0x5
	add.w	r1, r0, #0xc
	it	eq
	addeq.w	r1, r0, #0x10c
	movw	r0, #0xf3f
	it	eq
	movweq	r0, #0x3f0f
	ldrb	r2, [r1, #0x0]
	movw	r3, #0x8090
	ldr.w	r7, [r9, r2, lsl #0x2]
	it	eq
	movweq	r3, #0x9080
	ands	r0, r7
	eors	r0, r3
	str.w	r0, [r9, r2, lsl #0x2]	@ stall the endpoint
	movs	r0, #0x1
	strb	r0, [r1, #0xb]		@ halt flag = 1
.L0802effe:
	ldr.w	r0, [r10, #0x4]
.L0802f002:
	ldr	r2, [r0, #0x8]		@ callback table slot 2
.L0802f004:
	add.w	r1, r10, #0x20c
	mov	r0, r10
	blx	r2
	b.n	.L0802f070
.L0802f00e:
	ldrb.w	r0, [r10, #0x224]	@ request 1: clear feature
	cmp	r0, #0x3
	beq.n	.L0802f0c2
.L0802f016:
	cmp	r0, #0x2
	bne.w	.L0802f1c6
	orr	r0, r8, #0x80
	cmp	r0, #0x80
	beq.w	.L0802f200
.L0802f026:
	ands	r0, r8, #0x80
	and	r0, r8, #0x7f
	add.w	r0, r10, r0, lsl #0x5
	add.w	r1, r0, #0xc
	it	eq
	addeq.w	r1, r0, #0x10c
	movw	r0, #0xf3f
	it	eq
	movweq	r0, #0x3f0f
	ldrb	r2, [r1, #0x0]
	movw	r3, #0x8090
	ldr.w	r7, [r9, r2, lsl #0x2]
	it	eq
	movweq	r3, #0x9080
	ands	r0, r7
	eors	r0, r3
	str.w	r0, [r9, r2, lsl #0x2]
	movs	r0, #0x1
	strb	r0, [r1, #0xb]
	b.n	.L0802f200
.L0802f064:
	ldr.w	r0, [r10, #0x4]
	ldr	r1, [r0, #0x10]		@ callback table slot 4
	cbz	r1, .L0802f070
.L0802f06c:
	mov	r0, r10
	blx	r1
.L0802f070:
	movs	r0, #0x4
	strb.w	r0, [r10, #0x220]	@ state 0x20002d44 = 4
	mov	r0, r10
	movs	r1, #0x0
	movs	r2, #0x0
	movs	r3, #0x0
	bl	fn_08040eb4		@ zero-length status packet
	b.n	.L0802f200
.L0802f084:
	and	r0, r8, #0x7f
	add.w	r0, r10, r0, lsl #0x5
	add.w	r2, r0, #0xc
	lsls.w	r1, r8, #0x18
	it	pl
	addpl.w	r2, r0, #0x10c
	ldrb	r0, [r2, #0xb]
	subs	r0, #0x1
	clz	r0, r0
	lsrs	r0, r0, #0x5
	strh	r0, [r2, #0xc]!		@ halt state as the reply word
	mov.w	r0, #0x20002
	str.w	r0, [r10, #0x26]
	movs	r0, #0x2
.L0802f0b2:
	strb.w	r0, [r10, #0x220]
	mov	r0, r10
	movs	r1, #0x0
	movs	r3, #0x2
	bl	fn_08040eb4
	b.n	.L0802f200
.L0802f0c2:
	ldrh.w	r0, [r10, #0x20e]
	cmp	r0, #0x0
	bne.w	.L0802f200
	lsls.w	r0, r8, #0x19
	beq.n	.L0802f070
	ands	r0, r8, #0x80
	and	r0, r8, #0x7f
	add.w	r0, r10, r0, lsl #0x5
	add.w	r1, r0, #0xc
	it	eq
	addeq.w	r1, r0, #0x10c
	movw	r0, #0xf3f
	it	eq
	movweq	r0, #0x3f0f
	ldrb	r2, [r1, #0x0]
	movw	r3, #0x80b0
	ldr.w	r7, [r9, r2, lsl #0x2]
	it	eq
	movweq	r3, #0xb080
	ands	r0, r7
	eors	r0, r3
	str.w	r0, [r9, r2, lsl #0x2]
	ldr.w	r0, [r10, #0x4]
	movs	r2, #0x0
	strb	r2, [r1, #0xb]		@ halt flag = 0
	b.n	.L0802f002
.L0802f114:
	ldrb.w	r0, [r10, #0x224]	@ request 1 (device): clear remote wakeup
	and	r0, r0, #0xfe
	cmp	r0, #0x2
	bne.n	.L0802f1c6
	cmp	r2, #0x1
	bne.n	.L0802f200
	movs	r0, #0x0
	strb.w	r0, [r10, #0x227]
	ldrh.w	r0, [r10, #0x22a]
	ldr.w	r1, [r10, #0x4]
	bic	r0, r0, #0x2
	ldr	r2, [r1, #0x8]
	strh.w	r0, [r10, #0x22a]
	b.n	.L0802f004
.L0802f13e:
	cmp	r2, #0x1		@ request 3 (device): set remote wakeup
	bne.n	.L0802f200
	ldr.w	r0, [r10, #0x4]
	ldr	r2, [r0, #0x8]
	movs	r0, #0x1
	strb.w	r0, [r10, #0x227]
	b.n	.L0802f004
.L0802f150:
	orrs.w	r1, r6, r7		@ request 5: set address
	bne.n	.L0802f1c6
	ldrb.w	r1, [r10, #0x224]
	cmp	r1, #0x3
	beq.n	.L0802f1c6
	ands	r0, r0, #0x7f
	strb.w	r0, [r10, #0x226]
	mov.w	r0, #0x2
	it	eq
	moveq	r0, #0x1
	strb.w	r0, [r10, #0x224]
	b.n	.L0802f070
.L0802f174:
	subs	r1, r3, #0x1		@ request 6: get descriptor
	cmp	r1, #0x6
	bhi.n	.L0802f1c6
	tbb	[pc, r1]
.L0802f17e:
	.byte	(.L0802f186 - .L0802f17e)/2
	.byte	(.L0802f236 - .L0802f17e)/2
	.byte	(.L0802f270 - .L0802f17e)/2
	.byte	(.L0802f1c6 - .L0802f17e)/2
	.byte	(.L0802f1c6 - .L0802f17e)/2
	.byte	(.L0802f1c6 - .L0802f17e)/2
	.byte	(.L0802f1c6 - .L0802f17e)/2
	.byte	0x00			@ padding
.L0802f186:
	ldr.w	r0, [r10, #0x8]
	ldr	r0, [r0, #0x0]		@ descriptor getter table slot 0
	b.n	.L0802f23c
.L0802f18e:
	cmp	r7, #0x1		@ request 8: get configuration
	bne.n	.L0802f1c6
	ldrb.w	r0, [r10, #0x224]
	cmp	r0, #0x3
	beq.w	.L0802f288
	cmp	r0, #0x2
	bne.n	.L0802f1c6
	movs	r0, #0x0
	strb.w	r0, [r10, #0x228]
	mov.w	r0, #0x10001
	str.w	r0, [r10, #0x26]
	movs	r0, #0x2
	add.w	r2, r10, #0x228
	b.n	.L0802f296
.L0802f1b6:
	orrs.w	r1, r6, r7		@ request 9: set configuration
	movw	r1, #0x4e72
	movt	r1, #0x2000
	strb	r0, [r1, #0x0]		@ 0x20004e72 = value byte
	beq.n	.L0802f212
.L0802f1c6:
	ldrb.w	r0, [r10, #0x10c]	@ stall endpoint 0 (OUT register index)
	movw	r2, #0x3f0f
	ldr.w	r1, [r9, r0, lsl #0x2]
	movw	r3, #0xf3f
	ands	r1, r2
	movw	r2, #0x9080
	eors	r1, r2
	str.w	r1, [r9, r0, lsl #0x2]
	ldrb.w	r0, [r10, #0xc]		@ stall endpoint 0 (IN register index)
	movs	r2, #0x1
	strb.w	r2, [r10, #0x117]
	ldr.w	r1, [r9, r0, lsl #0x2]
	ands	r1, r3
	movw	r3, #0x8090
	eors	r1, r3
	str.w	r1, [r9, r0, lsl #0x2]
	strb.w	r2, [r10, #0x17]
.L0802f200:
	ldr.w	r0, [r11, #0x44]	@ loop while flag bit15 is set
	lsls	r1, r0, #0x10
	bpl.w	.L0802e912
	ldr.w	r1, [r10, #0x0]
	b.w	.L0802ea24
.L0802f212:
	ldrb.w	r1, [r10, #0x224]
	cmp	r1, #0x3
	beq.n	.L0802f2a6
	cmp	r1, #0x2
	bne.n	.L0802f1c6
	cmp	r0, #0x0
	beq.w	.L0802f070
	ldr.w	r1, [r10, #0x4]
	strb.w	r0, [r10, #0x229]
	ldr	r1, [r1, #0x0]		@ callback table slot 0
	movs	r0, #0x3
	strb.w	r0, [r10, #0x224]	@ state = 3
	b.n	.L0802f06c
.L0802f236:
	ldr.w	r0, [r10, #0x8]
	ldr	r0, [r0, #0x8]		@ descriptor getter table slot 2
.L0802f23c:
	blx	r0
	cmp	r0, #0x0
	beq.n	.L0802f200
	ldrh	r1, [r0, #0x0]
	cmp	r1, #0x0
	beq.n	.L0802f200
	ldrh.w	r3, [r10, #0x212]
	cmp	r3, #0x0
	beq.n	.L0802f200
	cmp	r1, r3
	it	lo
	movlo	r3, r1
	ldr	r2, [r0, #0x4]
	movs	r0, #0x2
	strb.w	r0, [r10, #0x220]
	mov	r0, r10
	movs	r1, #0x0
	strh.w	r3, [r10, #0x28]
	strh.w	r3, [r10, #0x26]
	bl	fn_08040eb4
	b.n	.L0802f200
.L0802f270:
	cmp	r0, #0x5		@ string descriptor index
	bhi.w	.L0802ec4e
	tbb	[pc, r0]
.L0802f27a:
	.byte	(.L0802f280 - .L0802f27a)/2
	.byte	(.L0802f2e8 - .L0802f27a)/2
	.byte	(.L0802f2f0 - .L0802f27a)/2
	.byte	(.L0802f2f8 - .L0802f27a)/2
	.byte	(.L0802f300 - .L0802f27a)/2
	.byte	(.L0802f308 - .L0802f27a)/2
.L0802f280:
	ldr.w	r0, [r10, #0x8]
	ldr	r0, [r0, #0x10]		@ descriptor getter table slot 4
	b.n	.L0802f23c
.L0802f288:
	mov.w	r0, #0x10001
	str.w	r0, [r10, #0x26]
	movs	r0, #0x2
	addw	r2, r10, #0x229
.L0802f296:
	strb.w	r0, [r10, #0x220]
	mov	r0, r10
	movs	r1, #0x0
	movs	r3, #0x1
	bl	fn_08040eb4
	b.n	.L0802f200
.L0802f2a6:
	cbz	r0, .L0802f2d6
	ldrb.w	r1, [r10, #0x229]
	cmp	r1, r0
	bne.w	.L0802f070
	ldr.w	r0, [r10, #0x4]
	ldr	r1, [r0, #0x4]		@ callback table slot 1
	mov	r0, r10
	blx	r1
	ldr.w	r0, [r10, #0x4]
	movw	r1, #0x4e72
	movt	r1, #0x2000
	ldrb	r1, [r1, #0x0]
	ldr	r2, [r0, #0x0]		@ callback table slot 0
	mov	r0, r10
	strb.w	r1, [r10, #0x229]
	blx	r2
	b.n	.L0802f070
.L0802f2d6:
	ldr.w	r1, [r10, #0x4]
	movs	r2, #0x2
	ldr	r1, [r1, #0x4]		@ callback table slot 1
	strb.w	r2, [r10, #0x224]	@ state = 2
	strb.w	r0, [r10, #0x229]
	b.n	.L0802f06c
.L0802f2e8:
	ldr.w	r0, [r10, #0x8]
	ldr	r0, [r0, #0x14]		@ descriptor getter table slot 5
	b.n	.L0802f23c
.L0802f2f0:
	ldr.w	r0, [r10, #0x8]
	ldr	r0, [r0, #0x18]		@ descriptor getter table slot 6
	b.n	.L0802f23c
.L0802f2f8:
	ldr.w	r0, [r10, #0x8]
	ldr	r0, [r0, #0x1c]		@ descriptor getter table slot 7
	b.n	.L0802f23c
.L0802f300:
	ldr.w	r0, [r10, #0x8]
	ldr	r0, [r0, #0x24]		@ descriptor getter table slot 9
	b.n	.L0802f23c
.L0802f308:
	ldr.w	r0, [r10, #0x8]
	ldr	r0, [r0, #0x20]		@ descriptor getter table slot 8
	b.n	.L0802f23c
