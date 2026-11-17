@ lcd_hw_27.s - port-pair 0x6001fffe / 0x60020000 helpers and the transfer-programming routines that use them
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08009670 - No parameters, no return. Reads 0x40020000 and acts only when
@ bit5 of it is set.
@ When [0x200000f2] < 2: increments [0x200000f2], writes 0x20 to 0x40020004,
@ sets bit0 of 0x40021014, clears 0x4002001c/20/24/28, then reprograms
@ 0x40020004 (|= 0xf0) and 0x4002001c (field masks 0xbfef, 0x4000, 0xcfff,
@ 0x400, 0x100, 0xff7f, 0xffbf, 0xffdf), writes the count
@ ((u16 [0x20008342] * u16 [0x20008340] & 0x1ffff) >> 1) to 0x40020020,
@ source 0x2000835c to 0x40020024 and destination 0x60020000 to 0x40020028,
@ sets bit1 then (after the AIRCR/NVIC writes) bit0 of 0x4002001c. Also sets
@ AIRCR (0xe000ed0c) = (AIRCR & 0xf8ff) | 0x05fa0300, writes the derived
@ priority byte (((~(-1 << p) & 3) << s) << 4) to 0xe000e40c and 0x1000 to
@ 0xe000e100.
@ Otherwise (when [0x200000f2] >= 2): calls 0804209c (semaphore_give_from_isr)
@ with queue [0x20002d84] and &flag, flag preset 0, writes 0x20 to 0x40020004
@ and, when flag != 0, writes 0x10000000 to 0xe000ed04 followed by DSB and ISB.
@ The destination 0x60020000 is the data address 080097e8 uses with index
@ register 0x6001fffe; purpose beyond this not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08009670,"ax",%progbits
	.global fn_08009670
	.thumb_func
	.type fn_08009670, %function
fn_08009670:
	push {r4, lr}
	sub sp, #8
	movs r4, #0x1c
	movt r4, #0x4002
	ldr.w r0, [r4, #-0x1c]
	lsls r0, r0, #0x1a
	bpl.w .L080097de
	movw r0, #0xf2
	movt r0, #0x2000
	ldrb r1, [r0]
	cmp r1, #1
	bhi.w .L080097a8
	ldrb r1, [r0]
	adds r1, #1
	strb r1, [r0]
	movs r0, #0x20
	str.w r0, [r4, #-0x18]
	movw r0, #0x8340
	movt r0, #0x2000
	ldrh.w r12, [r0]
	ldrh r2, [r0, #2]
	movw r0, #0x1014
	movt r0, #0x4002
	ldr r3, [r0]
	movw r1, #0xbfef
	orr.w r3, r3, #1
	str r3, [r0]
	ldr r0, [r4]
	mul r2, r2, r12
	bic.w r0, r0, #1
	str r0, [r4]
	movs r0, #0
	str r0, [r4]
	str r0, [r4, #4]
	str r0, [r4, #8]
	str r0, [r4, #0xc]
	ldr.w r3, [r4, #-0x18]
	orr.w r3, r3, #0xf0
	str.w r3, [r4, #-0x18]
	ldr r3, [r4]
	ands r1, r3
	str r1, [r4]
	ldr r1, [r4]
	movs r3, #1
	orr.w r1, r1, #0x4000
	str r1, [r4]
	ldr r1, [r4]
	bic.w r1, r1, #0x3000
	str r1, [r4]
	ldr r1, [r4]
	bfi r1, r3, #0xa, #2
	str r1, [r4]
	ldr r1, [r4]
	bfi r1, r3, #8, #2
	str r1, [r4]
	ldr r1, [r4]
	movw r3, #0xf8ff
	bic.w r1, r1, #0x80
	str r1, [r4]
	ldr r1, [r4]
	bic.w r1, r1, #0x40
	str r1, [r4]
	ldr r1, [r4]
	bic.w r1, r1, #0x20
	str r1, [r4]
	ubfx r1, r2, #1, #0x10
	str r1, [r4, #4]
	movw r1, #0x835c
	movt r1, #0x2000
	str r1, [r4, #8]
	movs r1, #0
	movt r1, #0x6002
	str r1, [r4, #0xc]
	ldr r1, [r4]
	orr.w r1, r1, #2
	str r1, [r4]
	movw r1, #0xed0c
	movt r1, #0xe000
	ldr r2, [r1]
	ands r2, r3
	movw r3, #0x300
	movt r3, #0x5fa
	orrs r2, r3
	str r2, [r1]
	ldr r1, [r1]
	mov.w r3, #0xffffffff
	ubfx r1, r1, #8, #3
	eor.w r2, r1, #7
	cmp r2, #4
	it cs
	movcs r2, #4
	lsl.w r2, r3, r2
	movs r3, #3
	subs r1, #3
	bic.w r2, r3, r2
	it cc
	movcc r1, r0
	lsl.w r0, r2, r1
	movw r1, #0xe100
	lsls r0, r0, #4
	movt r1, #0xe000
	strb.w r0, [r1, #0x30c]
	mov.w r0, #0x1000
	str r0, [r1]
	ldr r0, [r4]
	orr.w r0, r0, #1
	str r0, [r4]
	add sp, #8
	pop {r4, pc}
.L080097a8:
	movw r0, #0x2d84
	movt r0, #0x2000
	movs r1, #0
	ldr r0, [r0]
	str r1, [sp, #4]
	add r1, sp, #4
	bl semaphore_give_from_isr
	movs r0, #0x20
	str.w r0, [r4, #-0x18]
	ldr r0, [sp, #4]
	cbz r0, .L080097de
	movw r0, #0xed0c
	movt r0, #0xe000
	mov.w r1, #0x10000000
	str.w r1, [r0, #-8]
	dsb sy
	isb sy
.L080097de:
	add sp, #8
	pop {r4, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080097e8 - No parameters. With x=[0x20008350], y=[0x20008352],
@ w=[0x20008354], h=[0x20008356] (halfwords): writes index [0x2000834a] to
@ 0x6001fffe followed by data halfwords x>>8, x&0xff, (x+w-1)>>8,
@ (x+w-1)&0xff to 0x60020000, writes index [0x2000834c] and the same four
@ values for y/h, writes 0x2e to 0x6001fffe, performs one discarded read with
@ 08020e00 (read_halfword_60020000). Only when w*h != 0 it then loops: each
@ pass reads three halfwords a,b,c with 08020e00 and stores two 16-bit values
@ at [0x20008358] + counter*2 and +2:
@ value0 = (a&0xf800) | ((a&0xfc)<<3) | (b>>11),
@ value1 = ((b&0xf8)<<8) | ((c>>5)&0xffe0) | ((c&0xff)>>3).
@ The counter advances by 2 per pass while it is below w*h (so ceil(w*h/2)
@ passes).
@ ----------------------------------------------------------------------------
	.section .text.fn_080097e8,"ax",%progbits
	.global fn_080097e8
	.thumb_func
	.type fn_080097e8, %function
fn_080097e8:
	push.w {r4, r5, r6, r7, r8, r9, lr}
	sub sp, #4
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r0, [r6]
	ldrh r1, [r6, #2]
	ldrh r2, [r6, #4]
	movw r12, #0x8340
	movt r12, #0x2000
	ldrh r3, [r6, #6]
	add r2, r0
	ldrh.w r4, [r12, #0xa]
	movs r5, #0
	subs r2, #1
	movt r5, #0x6002
	uxth r7, r2
	strh r4, [r5, #-2]
	lsrs r4, r0, #8
	uxtb r0, r0
	strh r4, [r5]
	strh r0, [r5]
	lsrs r0, r7, #8
	strh r0, [r5]
	uxtb r0, r2
	strh r0, [r5]
	ldrh.w r0, [r12, #0xc]
	add r3, r1
	subs r3, #1
	strh r0, [r5, #-2]
	lsrs r0, r1, #8
	uxth r2, r3
	strh r0, [r5]
	uxtb r0, r1
	strh r0, [r5]
	lsrs r0, r2, #8
	strh r0, [r5]
	uxtb r0, r3
	strh r0, [r5]
	movs r0, #0x2e
	strh r0, [r5, #-2]
	bl read_halfword_60020000
	ldrh r0, [r6, #4]
	ldrh r1, [r6, #6]
	muls r0, r1
	cmp r0, #0
	beq.n .L080098da
	movs r7, #0
	mov.w r8, #0xf800
	mvn r9, #0x1f
	nop
.L08009868:
	bl read_halfword_60020000
	mov r4, r0
	bl read_halfword_60020000
	mov r5, r0
	bl read_halfword_60020000
	ldr r1, [r6, #8]
	and r2, r4, #0xf800
	strh.w r2, [r1, r7, lsl #1]
	ldr r1, [r6, #8]
	and r3, r4, #0xfc
	ldrh.w r2, [r1, r7, lsl #1]
	orr.w r2, r2, r3, lsl #3
	strh.w r2, [r1, r7, lsl #1]
	ldr r1, [r6, #8]
	and.w r3, r9, r0, lsr #5
	ldrh.w r2, [r1, r7, lsl #1]
	ubfx r0, r0, #3, #5
	orr.w r2, r2, r5, lsr #11
	strh.w r2, [r1, r7, lsl #1]
	ldr r1, [r6, #8]
	and.w r2, r8, r5, lsl #8
	add.w r1, r1, r7, lsl #1
	strh r2, [r1, #2]
	ldr r1, [r6, #8]
	add.w r1, r1, r7, lsl #1
	ldrh r2, [r1, #2]
	orrs r2, r3
	strh r2, [r1, #2]
	ldr r1, [r6, #8]
	add.w r1, r1, r7, lsl #1
	ldrh r2, [r1, #2]
	adds r7, #2
	orrs r0, r2
	strh r0, [r1, #2]
	ldrh r0, [r6, #4]
	ldrh r1, [r6, #6]
	muls r0, r1
	cmp r7, r0
	bcc.n .L08009868
.L080098da:
	add sp, #4
	pop.w {r4, r5, r6, r7, r8, r9, pc}

@ ----------------------------------------------------------------------------
@ fn_0800fd38 - No parameters, no return value. Writes to the ports
@ 0x6001fffe / 0x60020000: [0x6001fffe]=[0x2000834a] then 0x60020000 gets
@ 0,0,(w-1)>>8,(w-1)&0xff with w=[0x20008340]; [0x6001fffe]=[0x2000834c] then
@ 0,0,(h-1)>>8,(h-1)&0xff with h=[0x20008342]; [0x6001fffe]=[0x20008348].
@ [0x200000f2]=1. Sets bit0 of 0x40021014; clears bit0 of 0x4002001c, writes 0
@ to 0x4002001c, 0x40020020, 0x40020024, 0x40020028; ors 0xf0 into 0x40020004;
@ modifies 0x4002001c (and 0xbfef, or 0x4000, and ~0x3000, and ~0xc00 or
@ 0x400, and ~0x300 or 0x100, clears bits 7,6,5). 0x40020020 =
@ ((w*h)&0x1ffff)>>1, 0x40020024=0x2000835c, 0x40020028=0x60020000,
@ 0x4002001c |= 2. AIRCR 0xe000ed0c = (old&0xf8ff)|0x05fa0300 (priority group
@ 3), writes the priority byte 0xe000e40c computed from the group read back
@ (0x30 for group 3), 0xe000e100=0x1000 (enable interrupt 12),
@ 0x4002001c |= 1. Then tail-calls 080423a8 (semaphore_take_timeout) with
@ ([0x20002d84], 0xffffffff).
@ Purpose: programs a transfer of ((w*h)&0x1ffff)>>1 units from RAM
@ 0x2000835c to 0x60020000 and starts it (register block 0x40020000 and the
@ port 0x60020000 are not identified).
@ ----------------------------------------------------------------------------
	.section .text.fn_0800fd38,"ax",%progbits
	.global fn_0800fd38
	.thumb_func
	.type fn_0800fd38, %function
fn_0800fd38:
	push {r4, r5, r7, lr}
	movw r1, #0x8340
	movt r1, #0x2000
	ldrh r0, [r1]
	ldrh r2, [r1, #2]
	subs r3, r0, #1
	subs r4, r2, #1
	ldrh r5, [r1, #0xa]
	movs r2, #0
	uxth r0, r3
	movt r2, #0x6002
	strh r5, [r2, #-2]
	movs r5, #0
	lsrs r0, r0, #8
	strh r5, [r2]
	strh r5, [r2]
	strh r0, [r2]
	uxtb r0, r3
	strh r0, [r2]
	ldrh r0, [r1, #0xc]
	uxth r3, r4
	strh r0, [r2, #-2]
	lsrs r0, r3, #8
	strh r5, [r2]
	strh r5, [r2]
	strh r0, [r2]
	uxtb r0, r4
	strh r0, [r2]
	ldrh r0, [r1, #8]
	movs r3, #1
	strh r0, [r2, #-2]
	movw r0, #0xf2
	movt r0, #0x2000
	strb r3, [r0]
	movw r0, #0x1014
	movt r0, #0x4002
	ldrh.w r12, [r1]
	ldrh.w lr, [r1, #2]
	ldr r1, [r0]
	movw r4, #0xbfef
	orr.w r1, r1, #1
	str r1, [r0]
	movs r1, #0x1c
	movt r1, #0x4002
	ldr r0, [r1]
	bic.w r0, r0, #1
	str r0, [r1]
	str r5, [r1]
	str r5, [r1, #4]
	str r5, [r1, #8]
	str r5, [r1, #0xc]
	ldr.w r0, [r1, #-0x18]
	orr.w r0, r0, #0xf0
	str.w r0, [r1, #-0x18]
	ldr r0, [r1]
	ands r0, r4
	str r0, [r1]
	ldr r0, [r1]
	orr.w r0, r0, #0x4000
	str r0, [r1]
	ldr r0, [r1]
	bic.w r0, r0, #0x3000
	str r0, [r1]
	ldr r0, [r1]
	bfi r0, r3, #0xa, #2
	str r0, [r1]
	ldr r0, [r1]
	bfi r0, r3, #8, #2
	str r0, [r1]
	ldr r0, [r1]
	mul r3, lr, r12
	bic.w r0, r0, #0x80
	str r0, [r1]
	ldr r0, [r1]
	bic.w r0, r0, #0x40
	str r0, [r1]
	ldr r0, [r1]
	bic.w r0, r0, #0x20
	str r0, [r1]
	ubfx r0, r3, #1, #0x10
	str r0, [r1, #4]
	movw r0, #0x835c
	movt r0, #0x2000
	str r0, [r1, #8]
	str r2, [r1, #0xc]
	ldr r0, [r1]
	movw r3, #0xf8ff
	orr.w r0, r0, #2
	str r0, [r1]
	movw r0, #0xed0c
	movt r0, #0xe000
	ldr r2, [r0]
	ands r2, r3
	movw r3, #0x300
	movt r3, #0x5fa
	orrs r2, r3
	str r2, [r0]
	ldr r0, [r0]
	mov.w r3, #0xffffffff
	ubfx r0, r0, #8, #3
	eor.w r2, r0, #7
	cmp r2, #4
	it cs
	movcs r2, #4
	lsl.w r2, r3, r2
	movs r3, #3
	subs r0, #3
	bic.w r2, r3, r2
	it cc
	movcc r0, r5
	lsl.w r0, r2, r0
	movw r2, #0xe100
	lsls r0, r0, #4
	movt r2, #0xe000
	strb.w r0, [r2, #0x30c]
	mov.w r0, #0x1000
	str r0, [r2]
	ldr r0, [r1]
	orr.w r0, r0, #1
	str r0, [r1]
	movw r0, #0x2d84
	movt r0, #0x2000
	ldr r0, [r0]
	mov.w r1, #0xffffffff
	pop.w {r4, r5, r7, lr}
	b.w semaphore_take_timeout

@ ----------------------------------------------------------------------------
@ read_halfword_60020000 - No parameters; returns the 16-bit value read (ldrh
@ at 0x08020e08) from the I/O address 0x60020000.
@ ----------------------------------------------------------------------------
	.section .text.read_halfword_60020000,"ax",%progbits
	.global read_halfword_60020000
	.thumb_func
	.type read_halfword_60020000, %function
read_halfword_60020000:
	sub sp, #4
	movs r0, #0
	movt r0, #0x6002
	ldrh r0, [r0]
	strh.w r0, [sp, #2]
	ldrh.w r0, [sp, #2]
	add sp, #4
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ write_window_xy_60020000 - Takes x=param_1 (r0), y=param_2 (r1), w=param_3
@ (r2), h=param_4 (r3), no return value. Writes halfword 0x2000834a (ldrh at
@ 0x08020e24) to 0x6001fffe, then to 0x60020000 the four halfwords x>>8,
@ x&0xff, (x+w-1)>>8 (of the low 16 bits), (x+w-1)&0xff. Then writes halfword
@ 0x2000834c (ldrh at 0x08020e4a) to 0x6001fffe, then to 0x60020000 y>>8,
@ y&0xff, (y+h-1)>>8, (y+h-1)&0xff. Writes a start/end pair for the x range
@ and for the y range to the I/O addresses 0x6001fffe / 0x60020000 (command
@ halfwords come from RAM).
@ ----------------------------------------------------------------------------
	.section .text.write_window_xy_60020000,"ax",%progbits
	.global write_window_xy_60020000
	.thumb_func
	.type write_window_xy_60020000, %function
write_window_xy_60020000:
	push {r4, r5, r7, lr}
	movw lr, #0x8340
	movt lr, #0x2000
	add r2, r0
	ldrh.w r4, [lr, #0xa]
	movs r5, #0
	subs r2, #1
	movt r5, #0x6002
	uxth.w r12, r2
	strh r4, [r5, #-2]
	lsrs r4, r0, #8
	uxtb r0, r0
	strh r4, [r5]
	strh r0, [r5]
	lsr.w r0, r12, #8
	strh r0, [r5]
	uxtb r0, r2
	strh r0, [r5]
	ldrh.w r0, [lr, #0xc]
	add r3, r1
	subs r3, #1
	strh r0, [r5, #-2]
	lsrs r0, r1, #8
	uxth r2, r3
	strh r0, [r5]
	uxtb r0, r1
	strh r0, [r5]
	lsrs r0, r2, #8
	strh r0, [r5]
	uxtb r0, r3
	strh r0, [r5]
	pop {r4, r5, r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ write_halfword_60020000 - Writes the 16-bit parameter (r0, strh at
@ 0x08020e72) to the I/O address 0x60020000; no return value.
@ ----------------------------------------------------------------------------
	.section .text.write_halfword_60020000,"ax",%progbits
	.global write_halfword_60020000
	.thumb_func
	.type write_halfword_60020000, %function
write_halfword_60020000:
	movs r1, #0
	movt r1, #0x6002
	strh r0, [r1]
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ write_halfword_6001fffe_from_20008348 - Writes the halfword at 0x20008348
@ (ldrh at 0x08020e80) to the halfword at 0x6001fffe (strh at 0x08020e8a); no
@ parameters, no return value.
@ ----------------------------------------------------------------------------
	.section .text.write_halfword_6001fffe_from_20008348,"ax",%progbits
	.global write_halfword_6001fffe_from_20008348
	.thumb_func
	.type write_halfword_6001fffe_from_20008348, %function
write_halfword_6001fffe_from_20008348:
	movw r0, #0x8340
	movt r0, #0x2000
	ldrh r0, [r0, #8]
	movw r1, #0xfffe
	movt r1, #0x6001
	strh r0, [r1]
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ halt_forever_08020e90 - Endless loop: b.n to itself at 0x08020e90; never
@ returns.
@ ----------------------------------------------------------------------------
	.section .text.halt_forever_08020e90,"ax",%progbits
	.global halt_forever_08020e90
	.thumb_func
	.type halt_forever_08020e90, %function
halt_forever_08020e90:
	b.n halt_forever_08020e90
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ return_void - Returns immediately: its only instruction is bx lr at
@ 0x08020e94.
@ ----------------------------------------------------------------------------
	.section .text.return_void,"ax",%progbits
	.global return_void
	.thumb_func
	.type return_void, %function
return_void:
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ write_pixel_window_to_port - Params r0=x, r1=y, r2=width, r3=height, stack
@ param_5=pointer to 16-bit pixels; no return value. Writes the halfword at
@ 0x2000834a to 0x6001fffe, then four halfwords to 0x60020000: x>>8 (not
@ masked, low 16 bits stored), x&0xff, (((x+width-1)&0xffff)>>8) and
@ ((x+width-1)&0xff). Writes the halfword at 0x2000834c to 0x6001fffe, then
@ y>>8 (not masked, low 16 bits stored), y&0xff, (((y+height-1)&0xffff)>>8),
@ ((y+height-1)&0xff) to 0x60020000. Writes the halfword at 0x20008348 to
@ 0x6001fffe. Then writes width*height halfwords from the source pixels to
@ 0x60020000 (loop unrolled by 4 with 0..3 remainder; nothing is written when
@ the count is 0). The three command halfwords select the two coordinate
@ ranges and the start of the pixel data stream; which device sits at
@ 0x6001fffe/0x60020000 is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.write_pixel_window_to_port,"ax",%progbits
	.global write_pixel_window_to_port
	.thumb_func
	.type write_pixel_window_to_port, %function
write_pixel_window_to_port:
	push {r4, r5, r6, r7, lr}
	movw r6, #0x8340
	movt r6, #0x2000
	movw r12, #0
	add.w lr, r0, r2
	ldrh r7, [r6, #0xa]
	movt r12, #0x6002
	sub.w lr, lr, #1
	uxth.w r4, lr
	strh.w r7, [r12, #-2]
	lsrs r7, r0, #8
	uxtb r0, r0
	strh.w r7, [r12]
	strh.w r0, [r12]
	lsrs r0, r4, #8
	strh.w r0, [r12]
	uxtb.w r0, lr
	strh.w r0, [r12]
	ldrh r0, [r6, #0xc]
	adds r5, r1, r3
	subs r5, #1
	strh.w r0, [r12, #-2]
	lsrs r0, r1, #8
	uxth r7, r5
	strh.w r0, [r12]
	uxtb r0, r1
	strh.w r0, [r12]
	lsrs r0, r7, #8
	strh.w r0, [r12]
	uxtb r0, r5
	strh.w r0, [r12]
	ldrh r1, [r6, #8]
	mul r0, r3, r2
	strh.w r1, [r12, #-2]
	cbz r0, .L0803a30e
	ldr.w lr, [sp, #0x14]
	subs r1, r0, #1
	cmp r1, #3
	and.w r1, r0, #3
	bcs.n .L0803a2bc
	movs r2, #0
	b.n .L0803a2e8
.L0803a2bc:
	bic.w r3, r0, #3
	sub.w r0, lr, #8
	movs r2, #0
	nop
.L0803a2c8:
	ldrh.w r4, [r0, #8]!
	adds r2, #4
	strh.w r4, [r12]
	ldrh r4, [r0, #2]
	cmp r3, r2
	strh.w r4, [r12]
	ldrh r4, [r0, #4]
	strh.w r4, [r12]
	ldrh r4, [r0, #6]
	strh.w r4, [r12]
	bne.n .L0803a2c8
.L0803a2e8:
	cmp r1, #0
	it eq
	popeq {r4, r5, r6, r7, pc}
	ldrh.w r0, [lr, r2, lsl #1]
	cmp r1, #1
	strh.w r0, [r12]
	beq.n .L0803a30e
	add.w r0, lr, r2, lsl #1
	ldrh r2, [r0, #2]
	cmp r1, #2
	strh.w r2, [r12]
	itt ne
	ldrhne r0, [r0, #4]
	strhne.w r0, [r12]
.L0803a30e:
	pop {r4, r5, r6, r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08042ee0 - No params. Writes 16-bit values to the memory-mapped ports
@ 0x6001fffe (first write of each group) and 0x60020000 (following data
@ writes): halfword 0x2000834a to 0x6001fffe; then to 0x60020000 the four
@ byte values x>>8, x&0xff, e>>8, e&0xff with x = halfword 0x20008350 and
@ e = x + halfword 0x20008354 - 1; then halfword 0x2000834c to 0x6001fffe
@ followed by four bytes for y = halfword 0x20008352 and f = y + halfword
@ 0x20008356 - 1; then halfword 0x20008348 to 0x6001fffe. Then: sets bit 0 of
@ 0x40021014; programs the block at 0x40020004..0x40020028: 0x4002001c bit 0
@ cleared and then 0, 0x40020020/24/28 = 0, 0x40020004 |= 0xf0, 0x4002001c
@ masked with 0xbfef then |= 0x4000, &= 0xffffcfff, (&= 0xfffff3ff) | 0x400,
@ (&= 0xfffffcff) | 0x100, &= 0xffffff7f, |= 0x40, &= 0xffffffdf; count
@ 0x40020020 = (ushort)(halfword 0x20008356 * halfword 0x20008354), source
@ 0x40020024 = word 0x20008358, destination 0x40020028 = 0x60020000,
@ 0x4002001c |= 2. Then AIRCR 0xE000ED0C = (AIRCR & 0xf8ff) | 0x05fa0300 (key
@ 0x05fa, grouping field 3); reads the grouping field g back, computes byte
@ ((~(-1 << min(g^7,4)) & 3) << max(g-3,0)) << 4 and writes it to 0xE000E40C
@ (interrupt priority byte of interrupt 12), writes 0x1000 to 0xE000E100
@ (enable interrupt 12), and sets bit 0 of 0x4002001c. No return value.
@ Purpose: sends a rectangle (x, y, width at 0x20008354, height at
@ 0x20008356) as two address-range commands to the port pair
@ 0x6001fffe/0x60020000 and starts a memory-to-port transfer of width*height
@ elements from the buffer pointer at 0x20008358 to 0x60020000; that the port
@ is a display is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08042ee0,"ax",%progbits
	.global fn_08042ee0
	.thumb_func
	.type fn_08042ee0, %function
fn_08042ee0:
	push {r4, r5, r6, lr}
	movw r12, #0x8350
	movt r12, #0x2000
	ldrh.w r2, [r12]
	ldrh.w r3, [r12, #2]
	ldrh.w r1, [r12, #4]
	movw r5, #0x8340
	movt r5, #0x2000
	ldrh.w r0, [r12, #6]
	add r1, r2
	ldrh r6, [r5, #0xa]
	movs r4, #0
	subs r1, #1
	movt r4, #0x6002
	uxth.w lr, r1
	strh r6, [r4, #-2]
	lsrs r6, r2, #8
	uxtb r2, r2
	strh r6, [r4]
	strh r2, [r4]
	lsr.w r2, lr, #8
	uxtb r1, r1
	strh r2, [r4]
	strh r1, [r4]
	ldrh r1, [r5, #0xc]
	add r0, r3
	subs r0, #1
	strh r1, [r4, #-2]
	lsrs r1, r3, #8
	uxth r2, r0
	strh r1, [r4]
	uxtb r1, r3
	strh r1, [r4]
	lsrs r1, r2, #8
	uxtb r0, r0
	strh r1, [r4]
	strh r0, [r4]
	ldrh r0, [r5, #8]
	movs r2, #0
	strh r0, [r4, #-2]
	movw r0, #0x1014
	movt r0, #0x4002
	ldrh.w lr, [r12, #4]
	ldrh.w r3, [r12, #6]
	ldr.w r12, [r12, #8]
	ldr r1, [r0]
	movw r5, #0xbfef
	orr.w r1, r1, #1
	str r1, [r0]
	movs r0, #0x1c
	movt r0, #0x4002
	ldr r1, [r0]
	mul r3, r3, lr
	bic.w r1, r1, #1
	str r1, [r0]
	str r2, [r0]
	str r2, [r0, #4]
	str r2, [r0, #8]
	str r2, [r0, #0xc]
	ldr.w r1, [r0, #-0x18]
	movw r6, #0xf8ff
	orr.w r1, r1, #0xf0
	str.w r1, [r0, #-0x18]
	ldr r1, [r0]
	ands r1, r5
	str r1, [r0]
	ldr r1, [r0]
	movs r5, #1
	orr.w r1, r1, #0x4000
	str r1, [r0]
	ldr r1, [r0]
	bic.w r1, r1, #0x3000
	str r1, [r0]
	ldr r1, [r0]
	bfi r1, r5, #0xa, #2
	str r1, [r0]
	ldr r1, [r0]
	bfi r1, r5, #8, #2
	str r1, [r0]
	ldr r1, [r0]
	bic.w r1, r1, #0x80
	str r1, [r0]
	ldr r1, [r0]
	orr.w r1, r1, #0x40
	str r1, [r0]
	ldr r1, [r0]
	bic.w r1, r1, #0x20
	str r1, [r0]
	uxth r1, r3
	str r1, [r0, #4]
	str.w r12, [r0, #8]
	str r4, [r0, #0xc]
	ldr r1, [r0]
	orr.w r1, r1, #2
	str r1, [r0]
	movw r1, #0xed0c
	movt r1, #0xe000
	ldr r3, [r1]
	ands r3, r6
	movw r6, #0x300
	movt r6, #0x5fa
	orrs r3, r6
	str r3, [r1]
	ldr r1, [r1]
	mov.w r6, #0xffffffff
	ubfx r1, r1, #8, #3
	eor.w r3, r1, #7
	cmp r3, #4
	it cs
	movcs r3, #4
	lsl.w r3, r6, r3
	movs r6, #3
	subs r1, #3
	bic.w r3, r6, r3
	it cc
	movcc r1, r2
	lsl.w r1, r3, r1
	movw r2, #0xe100
	lsls r1, r1, #4
	movt r2, #0xe000
	strb.w r1, [r2, #0x30c]
	mov.w r1, #0x1000
	str r1, [r2]
	ldr r1, [r0]
	orr.w r1, r1, #1
	str r1, [r0]
	pop {r4, r5, r6, pc}
