@ ui_pages_73.s - draw_panels_by_selector_20001062 (part 1 of 3; parts 2 and 3 are included at the end)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ draw_panels_by_selector_20001062 - No parameters, no return value.
@ Draws into the current region buffer ([0x20008350..58]); all pixel writes are
@ bounds tested against the region record.
@ Switch on [0x20001062]&0xf, cases 0..7; other values draw nothing.
@
@ Common pieces: panel fill = 0x18c3 on columns 0x7a..0x12f of the listed rows;
@ selected panel = image "3:/System file/72.jpg" instead of the fill; label colour =
@ halfword at 0x0804c180+2*k (k=1 normal, k=2 selected); labels are drawn with
@ 0800f154(x,y,w,h,text,0x20001114,colour,flag); images with 08039f6c.
@
@ case 0: panel 1 rows 0x3e..0x5d, selected when [0x20001061]!=0 and
@ [0x20001063]==0: unselected draws the fill and 74.jpg (77.jpg when [0x2000012c]!=0)
@ at (0xa6,0x47), selected draws 72.jpg at (0x79,0x3d) and 75.jpg (78.jpg when
@ [0x2000012c]!=0) at (0xa6,0x45) resp. (0xa5,0x45); label "Y-T" at
@ (0xb6,0x3d,0x5c,0x22) flag 1.
@ panel 2 rows 0x86..0xa5, selected when [0x20001061]!=0 and [0x20001063]==1, images
@ at (0xa6,0x8f)/(0xa6|0xa5,0x8d) with 74/75 when [0x2000012c]==1 else 77/78, 72.jpg
@ at (0x79,0x85), label "X-Y" (string at 0x0801573c) at (0xb6,0x85,0x5c,0x22).
@
@ case 1: same two panels, 74/75 chosen by bit0 of [0x20000332] (panel 1) and bit1
@ (panel 2) (77/78 when the bit is clear), labels "X1-X2" and "Y1-Y2".
@
@ case 2: image at (0x72,0x1b): when [0x20001058]==1: 81.jpg if [0x20001061]==0, else
@ 85.jpg (83.jpg when [0x20001063]&0xf==0); otherwise 82.jpg / 86.jpg / 84.jpg
@ likewise. Boxes 08020ce8(x,y,0x36,0x12,0x2965,colour) with colour = halfword at
@ 0x080bb40c (or 0x080bb40e for the second group)+4*[0x20001058+3].
@ If [0x20001063]&0xf==0: box (0xbb,0x26) when [0x20000144]&0xfff==0xfff, box
@ (0xf9,0x26) when it is 0, boxes for each set bit i of [0x20000144] bits 0..11 at
@ x=0x7d+62*(i>>2), y=0x40+0x1a*(i&3); when [0x20001061]==2 two cursor outlines
@ draw_rounded_rect_outline 08020c48(x,y,4) and (x,y,3) with (x,y) from [0x20001063]
@ (v<0xc0: x=0x7d+62*(v>>6), y=0x40+0x1a*((v>>4)&3); else y=0x26, x=0xbb when
@ v>>4==0xc else 0xf9); second group: ([0x20000144]&0xfff0000)==0xfff0000 box
@ (0xbb,0xbc), ==0 box (0xf9,0xbc), bit16 (0x7d,0xd6), bit20 (0xbb,0xd6), bit24
@ (0xf9,0xd6).
@ Else (low nibble of [0x20001063] nonzero): bits 2,6,10 of [0x20000144] boxes
@ (0x7d|0xbb|0xf9,0x20), bits 3,7,11 boxes at y=0x3a, group 2: ==0xfff0000 (0xbb,0x68),
@ ==0 (0xf9,0x68), bits 16..19 (0x7d,0x82|0x9c|0xb6|0xd0), bits 20..23 (0xbb,same y),
@ bits 24..27 (0xf9,same y), and when [0x20001061]==2 the cursor outlines at
@ y=0x82+0x1a*((v>>4)&3) (v<0xc0) or y=0x68.
@
@ cases 3 and 4: loop i=0..3 (row offset 0x24*i): panel rows 0x24*i+0x3e..0x24*i+0x5d,
@ fill unless ([0x20001061]!=0 and i==[0x20001063]) which draws 72.jpg at
@ (0x79,0x24*i+0x3d); colour index 2 when i==[0x20001063], else 1 when
@ (([0x20001062]&0xf)-2)&[0x2000010c]!=0, else 0; label pointer from the array
@ 0x08014198 at index i (+5 when [0x20001058]!=1) drawn at (0x80,0x24*i+0x3e,100,0x20)
@ flag 0; image path from the array 0x080141c0[colour index] (79.jpg, 79.jpg, 80.jpg)
@ at (0xe4,0x24*i+0x45); value text at (0xe4,0x24*i+0x44,0x42,0x14) flag 1: m=1
@ (case 3) or 2 (case 4): i=0 "ON"/"OFF" by [0x2000010c]&m, i=1 pointer array
@ 0x0804c7bc[byte 0x200000fd+m], i=2 0x0804c7c4[byte 0x200000f7+m], i=3
@ 0x080141cc[byte 0x20000101+m].
@
@ case 5: three panels, k=0 when [0x20001058]==1 else 3: panel 1 rows 0x4c..0x6b
@ (selected when [0x20001061]!=0 and [0x20001063]==0 draws 72.jpg at (0x79,0x4b)):
@ label word 0x0804c7cc+4k at (0x80,0x4c,100,0x20) flag 0, image 80.jpg if
@ [0x20001063]==0 else 79.jpg at (0xe4,0x53), value word
@ 0x0804c7e4+4k+4*[0x2000010f] at (0xe4,0x52,0x42,0x14) flag 1.
@ panel 2 rows 0x70..0x8f (selected with [0x20001063]==1, 72.jpg at (0x79,0x6f)):
@ label word 0x0804c7d0+4k at (0x80,0x70,100,0x20), image 80/79.jpg at (0xe4,0x77), a
@ 16x16 one-bit bitmap from the table at 0x0804d7d3+0x20*[0x20000110] (32 bytes, MSB
@ first) drawn in the label colour at x 0xfd..0x10c, y 0x78..0x87.
@ panel 3 rows 0x94..0xb3 (selected with [0x20001063]==2, 72.jpg at (0x79,0x93)):
@ label word 0x0804c7d4+4k at (0x80,0x94,100,0x20), image 80/79.jpg at (0xe4,0x9b),
@ value word 0x0804c7fc+4*[0x2000010e] at (0xe4,0x9a,0x42,0x14) flag 1.
@
@ case 6: four panels, rows 0x3e..0x5d, 0x62..0x81, 0x86..0xa5, 0xaa..0xc9, panel j
@ selected when [0x20001061]!=0 and [0x20001063]==j, marker image 74/77 (unselected,
@ at (0xa6,0x47|0x6b|0x8f|0xb3)) or 72.jpg at (0x79,0x3d|0x61|0x85|0xa9) plus 75/78 at
@ (0xa6|0xa5,0x45|0x69|0x8d|0xb1); 74/75 when [0x20000134]==j else 77/78; labels
@ "OFF", "500mS", "1S" and the string at 0x08015734 (UTF-8 bytes e2 88 9e) at
@ (0xb6,0x3d|0x61|0x85|0xa9,0x5c,0x22) flag 1.
@
@ case 7: panel 0 rows 0x30..0x4f with marker 74/77 (75/78 selected) chosen by
@ [0x2000012d]==0, label "OFF" at (0xb6,0x2f,0x5c,0x22), then loop i=1..8: i<5 left
@ column (columns 0x7a..0xd8, rows 0x24*i+0x30..0x24*i+0x4f, selected image 73.jpg at
@ (0x79,0x24*i+0x2f)) and i>=5 right column (columns 0xe2..0x12f, rows
@ 0x24*i-0x60..0x24*i-0x41, selected image 76.jpg at (0xe1,0x24*i-0x61)), marker
@ 74.jpg/77.jpg (75/78 when selected, selected when [0x20001061]!=0 and
@ i==[0x20001063]) chosen by i==[0x2000012d] at x=(i/5)*0x6b+0x7f,
@ y=0x24*i-(i/5)*0x90+0x39, text pointer from the word table at 0x08015714+4*(i-1)
@ drawn at (0x8e+(i/5)*0x6b, 0x24*i-(i/5)*0x90+0x30, 0x4a-(i/5)*0x10, 0x20) flag 1.
@ Purpose not determined from the code (the selector [0x20001062]&0xf and the items
@ are not identified).
@ ----------------------------------------------------------------------------
	.section .text.draw_panels_by_selector_20001062,"ax",%progbits
	.p2align 2
	.global draw_panels_by_selector_20001062
	.thumb_func
	.type draw_panels_by_selector_20001062, %function
draw_panels_by_selector_20001062:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0x1c
	movw	r12, #0xf8
	movt	r12, #0x2000
	ldrb.w	r0, [r12, #0xf6a]
	and	r0, r0, #0xf
	cmp	r0, #7
	bhi.w	.L080156de
	tbh	[pc, r0, lsl #1]
.L08013358:
	.short	(.L080135ba - .L08013358)/2
	.short	(.L080135fe - .L08013358)/2
	.short	(.L08013642 - .L08013358)/2
	.short	(.L08013368 - .L08013358)/2
	.short	(.L08013368 - .L08013358)/2
	.short	(.L08013674 - .L08013358)/2
	.short	(.L080138ae - .L08013358)/2
	.short	(.L080138f2 - .L08013358)/2
.L08013368:
	movw	r9, #0x8350
	movt	r9, #0x2000
	movw	r8, #0x131
	movw	r11, #0x18c3
	mov.w	r10, #0
	movs	r4, #0
	b.n	.L080133be
.L08013380:
	ldr.w	r0, [r1, r0, lsl #2]
	add.w	r1, r6, #0x44
	str	r0, [sp, #0]
	movw	r0, #0x1114
	movt	r0, #0x2000
	sxth	r1, r1
	strd	r0, r5, [sp, #4]
.L08013398:
	movs	r0, #0xe4
	movs	r2, #0x42
	movs	r3, #0x14
	movs	r7, #1
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r12, #0xf8
	movt	r12, #0x2000
.L080133ae:
	add.w	r10, r10, #1
	cmp.w	r10, #4
	add.w	r4, r4, #1
	beq.w	.L080156de
.L080133be:
	ldrb.w	r0, [r12, #0xf69]
	add.w	r1, r10, r10, lsl #3
	lsl.w	r1, r1, #2
	str	r4, [sp, #0x18]
	str	r1, [sp, #0x14]
	cbz	r0, .L08013400
	ldrb.w	r0, [r12, #0xf6b]
	cmp	r10, r0
	bne.n	.L08013400
	add.w	r0, r1, #0x3d
	uxth	r2, r0
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	bl	decode_image_file_with_offset
.L080133ec:
	movw	r12, #0xf8
	movt	r12, #0x2000
.L080133f4:
	ldrb.w	r0, [r12, #0xf6b]
	cmp	r10, r0
	bne.n	.L080134bc
	movs	r6, #2
	b.n	.L080134d2
.L08013400:
	add.w	r0, r1, #0x3e
	adds	r1, #0x5d
	sxth	r1, r1
	b.n	.L08013414
	.short	0xbf00	@ padding
.L0801340c:
	adds	r0, #1
	sxth	r0, r0
	cmp	r0, r1
	bgt.n	.L080133f4
.L08013414:
	sxth	r2, r0
	movs	r3, #0x7b
	b.n	.L08013422
	.short	0xbf00	@ padding
.L0801341c:
	adds	r3, #2
	cmp	r3, r8
	beq.n	.L0801340c
.L08013422:
	ldrh.w	r5, [r9, #0]
	subs	r6, r3, #1
	cmp	r6, r5
	bcc.n	.L08013470
	ldrh.w	r5, [r9, #0]
	ldrh.w	r7, [r9, #4]
	add	r7, r5
	cmp	r7, r6
	bls.n	.L08013470
	ldrh.w	r7, [r9, #2]
	cmp	r2, r7
	blt.n	.L08013470
	ldrh.w	r7, [r9, #2]
	ldrh.w	r6, [r9, #6]
	add	r7, r6
	cmp	r7, r2
	ble.n	.L08013470
	ldr.w	r7, [r9, #8]
	ldrh.w	r6, [r9, #0]
	ldrh.w	r5, [r9, #2]
	ldrh.w	r4, [r9, #4]
	subs	r5, r2, r5
	muls	r5, r4, r5
	subs	r6, r5, r6
	add	r6, r3
	add.w	r7, r7, r6, lsl #1
	strh.w	r11, [r7, #-2]
.L08013470:
	ldrh.w	r7, [r9, #0]
	cmp	r3, r7
	bcc.n	.L0801341c
	ldrh.w	r7, [r9, #0]
	ldrh.w	r6, [r9, #4]
	add	r7, r6
	cmp	r7, r3
	bls.n	.L0801341c
	ldrh.w	r7, [r9, #2]
	cmp	r2, r7
	blt.n	.L0801341c
	ldrh.w	r7, [r9, #2]
	ldrh.w	r6, [r9, #6]
	add	r7, r6
	cmp	r7, r2
	ble.n	.L0801341c
	ldr.w	r7, [r9, #8]
	ldrh.w	r6, [r9, #0]
	ldrh.w	r5, [r9, #2]
	ldrh.w	r4, [r9, #4]
	subs	r5, r2, r5
	muls	r5, r4, r5
	subs	r6, r5, r6
	add	r6, r3
	strh.w	r11, [r7, r6, lsl #1]
	b.n	.L0801341c
	.short	0xbf00	@ padding
.L080134bc:
	ldrb.w	r0, [r12, #0xf6a]
	ldrb.w	r1, [r12, #0x14]
	and	r0, r0, #0xf
	adds	r0, #0xfe
	ands.w	r6, r0, r1
	it	ne
	movne	r6, #1
.L080134d2:
	ldrb.w	r0, [r12, #0xf60]
	adr.w	r1, .L08014198
	subs	r0, #1
	it	ne
	movne	r0, #1
	orr.w	r0, r0, r0, lsl #2
	add.w	r0, r1, r0, lsl #2
	ldr.w	r0, [r0, r10, lsl #2]
	movw	r1, #:lower16:d_0804c180
	movt	r1, #:upper16:d_0804c180
	ldr	r4, [sp, #0x14]
	ldrh.w	r5, [r1, r6, lsl #1]
	str	r0, [sp, #0]
	movw	r0, #0x1114
	add.w	r1, r4, #0x3e
	movt	r0, #0x2000
	strd	r0, r5, [sp, #4]
	sxth	r1, r1
	movs	r0, #0x80
	movs	r2, #0x64
	movs	r3, #0x20
	movs	r7, #0
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	adr.w	r0, .L080141c0
	ldr.w	r0, [r0, r6, lsl #2]
	add.w	r1, r4, #0x45
	uxth	r2, r1
	movs	r1, #0xe4
	mov	r6, r4
	bl	decode_image_file_with_offset
	movw	r12, #0xf8
	movt	r12, #0x2000
	ldrb.w	r0, [r12, #0xf6a]
	and	r0, r0, #0xf
	cmp	r0, #3
	mov.w	r0, #2
	it	eq
	moveq	r0, #1
	ldr	r4, [sp, #0x18]
	and	r1, r4, #0x7f
	cmp	r1, #3
	bhi.w	.L080133ae
	tbb	[pc, r1]
.L0801355c:
	.byte	(.L0801356a - .L0801355c)/2
	.byte	(.L08013580 - .L0801355c)/2
	.byte	(.L08013590 - .L0801355c)/2
	.byte	(.L08013560 - .L0801355c)/2
.L08013560:
	add	r0, r12
	ldrb	r0, [r0, #9]
	adr.w	r1, .L080141cc
	b.n	.L08013380
.L0801356a:
	ldrb.w	r1, [r12, #0x14]
	tst	r1, r0
	add.w	r0, r6, #0x44
	beq.n	.L080135a0
	movw	r1, #:lower16:d_080bbc54+1
	movt	r1, #:upper16:d_080bbc54+1
	b.n	.L080135a8
.L08013580:
	add	r0, r12
	ldrb	r0, [r0, #5]
	movw	r1, #:lower16:d_0804c7bc
	movt	r1, #:upper16:d_0804c7bc
	b.n	.L08013380
	.short	0xbf00	@ padding
.L08013590:
	add	r0, r12
	ldrb.w	r0, [r0, #-1]
	movw	r1, #:lower16:d_0804c7c4
	movt	r1, #:upper16:d_0804c7c4
	b.n	.L08013380
.L080135a0:
	movw	r1, #:lower16:d_080bbc36+1
	movt	r1, #:upper16:d_080bbc36+1
.L080135a8:
	str	r1, [sp, #0]
	movw	r1, #0x1114
	movt	r1, #0x2000
	strd	r1, r5, [sp, #4]
	sxth	r1, r0
	b.n	.L08013398
.L080135ba:
	ldrb.w	r0, [r12, #0xf69]
	cmp	r0, #0
	beq.w	.L080139ec
	ldrb.w	r0, [r12, #0xf6b]
	cmp	r0, #0
	bne.w	.L080139ec
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x3d
	bl	decode_image_file_with_offset
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x34]
	cmp	r0, #0
	beq.w	.L08014a5c
	movw	r0, #:lower16:d_080bc5fc
	movt	r0, #:upper16:d_080bc5fc
	movs	r1, #0xa5
	b.w	.L08014a66
.L080135fe:
	ldrb.w	r0, [r12, #0xf69]
	cmp	r0, #0
	beq.w	.L08013b12
	ldrb.w	r0, [r12, #0xf6b]
	cmp	r0, #0
	bne.w	.L08013b12
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x3d
	bl	decode_image_file_with_offset
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x23a]
	lsls	r0, r0, #0x1f
	bne.w	.L08014308
	movw	r0, #:lower16:d_080bc5fc
	movt	r0, #:upper16:d_080bc5fc
	movs	r1, #0xa5
	b.w	.L08014312
.L08013642:
	ldrb.w	r1, [r12, #0xf60]
	ldrb.w	r0, [r12, #0xf69]
	cmp	r1, #1
	bne.w	.L08013c3a
	cmp	r0, #0
	beq.w	.L080144fa
	ldrb.w	r0, [r12, #0xf6b]
	movw	r1, #:lower16:d_080bc4dc
	lsls	r0, r0, #0x1c
	movw	r0, #:lower16:d_080bc560
	movt	r0, #:upper16:d_080bc560
	movt	r1, #:upper16:d_080bc4dc
	it	eq
	moveq	r0, r1
	b.w	.L0801450c
.L08013674:
	ldrb.w	r0, [r12, #0xf69]
	cmp	r0, #0
	beq.w	.L08013c60
	ldrb.w	r0, [r12, #0xf6b]
	cmp	r0, #0
	bne.w	.L08013c60
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x4b
	bl	decode_image_file_with_offset
.L08013698:
	movw	r4, #0xf8
	movt	r4, #0x2000
	ldrb.w	r7, [r4, #0xf6b]
	ldrb.w	r0, [r4, #0xf60]
	movs	r1, #2
	cmp	r7, #0
	it	eq
	moveq	r1, #4
	subs	r0, #1
	movw	r10, #:lower16:d_0804c7cc
	it	ne
	movne	r0, #1
	orr.w	r6, r0, r0, lsl #1
	movt	r10, #:upper16:d_0804c7cc
	movw	r2, #:lower16:d_0804c180
	ldr.w	r0, [r10, r6, lsl #2]
	movt	r2, #:upper16:d_0804c180
	movw	r11, #0x1114
	ldrh	r5, [r2, r1]
	movs	r1, #0
	movt	r11, #0x2000
	strd	r0, r11, [sp, #0]
	str	r1, [sp, #0xc]
	movs	r0, #0x80
	movs	r1, #0x4c
	movs	r2, #0x64
	movs	r3, #0x20
	str	r5, [sp, #8]
	bl	draw_wrapped_text_in_box
	movw	r8, #:lower16:d_080bc63e+1
	movw	r1, #:lower16:d_080bc428+1
	movt	r8, #:upper16:d_080bc63e+1
	movt	r1, #:upper16:d_080bc428+1
	mov	r0, r8
	cmp	r7, #0
	it	eq
	moveq	r0, r1
	movs	r1, #0xe4
	movs	r2, #0x53
	bl	decode_image_file_with_offset
	movw	r1, #:lower16:d_0804c7e4
	ldrb	r0, [r4, #0x17]
	movt	r1, #:upper16:d_0804c7e4
	add.w	r1, r1, r6, lsl #2
	ldr.w	r0, [r1, r0, lsl #2]
	movs	r1, #1
	str	r0, [sp, #0]
	strd	r5, r1, [sp, #8]
	movs	r0, #0xe4
	movs	r1, #0x52
	movs	r2, #0x42
	movs	r3, #0x14
	str.w	r11, [sp, #4]
	bl	draw_wrapped_text_in_box
	ldrb.w	r0, [r4, #0xf69]
	cmp	r0, #0
	beq.w	.L08013d86
	ldrb.w	r0, [r4, #0xf6b]
	cmp	r0, #1
	bne.w	.L08013d86
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x6f
	bl	decode_image_file_with_offset
.L0801375c:
	movw	r5, #0xf8
	movt	r5, #0x2000
	ldrb.w	r4, [r5, #0xf6b]
	ldrb.w	r0, [r5, #0xf60]
	movs	r1, #2
	cmp	r4, #1
	it	eq
	moveq	r1, #4
	subs	r0, #1
	it	ne
	movne	r0, #1
	orr.w	r0, r0, r0, lsl #1
	add.w	r0, r10, r0, lsl #2
	movw	r2, #:lower16:d_0804c180
	ldr	r0, [r0, #4]
	movt	r2, #:upper16:d_0804c180
	ldrh.w	r9, [r2, r1]
	movs	r7, #0
	strd	r0, r11, [sp, #0]
	movs	r0, #0x80
	movs	r1, #0x70
	movs	r2, #0x64
	movs	r3, #0x20
	str.w	r9, [sp, #8]
	str	r7, [sp, #0xc]
	bl	draw_wrapped_text_in_box
	movw	r1, #:lower16:d_080bc428+1
	mov	r0, r8
	movt	r1, #:upper16:d_080bc428+1
	cmp	r4, #1
	it	eq
	moveq	r0, r1
	movs	r1, #0xe4
	movs	r2, #0x77
	bl	decode_image_file_with_offset
	ldrb	r0, [r5, #0x18]
	movw	r2, #:lower16:d_0804d7d2+1
	movt	r2, #:upper16:d_0804d7d2+1
	add.w	r2, r2, r0, lsl #5
	movw	r0, #0x8350
	mov.w	r12, #0x78
	movt	r0, #0x2000
	b.n	.L080137e8
.L080137dc:
	add.w	r12, r12, #1
	cmp.w	r12, #0x88
	beq.w	.L0801393e
.L080137e8:
	movs	r5, #0
	movs	r3, #0xfe
	b.n	.L08013806
	.short	0xbf00	@ padding
.L080137f0:
	adds	r5, #1
	uxtb	r1, r5
	cmp	r1, #7
	add.w	r3, r3, #2
	itt	hi
	addhi	r7, #1
	movhi	r5, #0
	cmp.w	r3, #0x10e
	beq.n	.L080137dc
.L08013806:
	uxth	r4, r7
	ldrb	r4, [r2, r4]
	uxtb	r6, r5
	rsb.w	r6, r6, #7
	lsr.w	r6, r4, r6
	lsls	r6, r6, #0x1f
	beq.n	.L08013858
	ldrh	r6, [r0, #0]
	subs	r4, r3, #1
	cmp	r4, r6
	bcc.n	.L08013858
	ldrh	r6, [r0, #0]
	ldrh	r1, [r0, #4]
	add	r1, r6
	cmp	r1, r4
	bls.n	.L08013858
	ldrh	r1, [r0, #2]
	cmp	r12, r1
	bcc.n	.L08013858
	ldrh	r1, [r0, #2]
	ldrh	r6, [r0, #6]
	add	r1, r6
	cmp	r1, r12
	bls.n	.L08013858
	ldr.w	lr, [r0, #8]
	ldrh	r6, [r0, #0]
	ldrh	r4, [r0, #2]
	ldrh	r1, [r0, #4]
	sub.w	r4, r12, r4
	muls	r1, r4, r1
	subs	r1, r1, r6
	add	r1, r3
	add.w	r1, lr, r1, lsl #1
	strh.w	r9, [r1, #-2]
	nop
.L08013858:
	adds	r5, #1
	uxtb	r1, r5
	cmp	r1, #7
	itt	hi
	addhi	r7, #1
	movhi	r5, #0
	uxth	r1, r7
	ldrb	r1, [r2, r1]
	uxtb	r6, r5
	rsb.w	r6, r6, #7
	lsrs	r1, r6
	lsls	r1, r1, #0x1f
	beq.n	.L080137f0
	ldrh	r1, [r0, #0]
	cmp	r3, r1
	bcc.n	.L080137f0
	ldrh	r1, [r0, #0]
	ldrh	r6, [r0, #4]
	add	r1, r6
	cmp	r1, r3
	bls.n	.L080137f0
	ldrh	r1, [r0, #2]
	cmp	r12, r1
	bcc.n	.L080137f0
	ldrh	r1, [r0, #2]
	ldrh	r6, [r0, #6]
	add	r1, r6
	cmp	r1, r12
	bls.n	.L080137f0
	ldr.w	lr, [r0, #8]
	ldrh	r6, [r0, #0]
	ldrh	r4, [r0, #2]
	ldrh	r1, [r0, #4]
	sub.w	r4, r12, r4
	muls	r1, r4, r1
	subs	r1, r1, r6
	add	r1, r3
	strh.w	r9, [lr, r1, lsl #1]
	b.n	.L080137f0
.L080138ae:
	ldrb.w	r0, [r12, #0xf69]
	cmp	r0, #0
	beq.w	.L08013eae
	ldrb.w	r0, [r12, #0xf6b]
	cmp	r0, #0
	bne.w	.L08013eae
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x3d
	bl	decode_image_file_with_offset
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x3c]
	cmp	r0, #0
	beq.w	.L08014c56
	movw	r0, #:lower16:d_080bc5fc
	movt	r0, #:upper16:d_080bc5fc
	movs	r1, #0xa5
	b.w	.L08014c60
.L080138f2:
	ldrb.w	r0, [r12, #0xf69]
	movw	r7, #0x8350
	cmp	r0, #0
	movt	r7, #0x2000
	beq.w	.L08013fd6
	ldrb.w	r0, [r12, #0xf6b]
	cmp	r0, #0
	bne.w	.L08013fd6
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x2f
	bl	decode_image_file_with_offset
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x35]
	cmp	r0, #0
	beq.w	.L08015204
	movw	r0, #:lower16:d_080bc5fc
	movt	r0, #:upper16:d_080bc5fc
	movs	r1, #0xb2
	b.w	.L0801520e
.L0801393e:
	movw	r2, #0xf8
	movt	r2, #0x2000
	ldrb.w	r1, [r2, #0xf69]
	cmp	r1, #0
	beq.w	.L080140f6
	ldrb.w	r1, [r2, #0xf6b]
	cmp	r1, #2
	bne.w	.L080140f6
	movw	r0, #:lower16:d_080bc498+1
	movt	r0, #:upper16:d_080bc498+1
	movs	r1, #0x79
	movs	r2, #0x93
	bl	decode_image_file_with_offset
.L0801396a:
	movw	r6, #0xf8
	movt	r6, #0x2000
	ldrb.w	r4, [r6, #0xf6b]
	ldrb.w	r0, [r6, #0xf60]
	movs	r1, #2
	cmp	r4, #2
	it	eq
	moveq	r1, #4
	subs	r0, #1
	it	ne
	movne	r0, #1
	orr.w	r0, r0, r0, lsl #1
	add.w	r0, r10, r0, lsl #2
	movw	r2, #:lower16:d_0804c180
	ldr	r0, [r0, #8]
	movt	r2, #:upper16:d_0804c180
	ldrh	r5, [r2, r1]
	movs	r1, #0
	strd	r0, r11, [sp, #0]
	str	r1, [sp, #0xc]
	movs	r0, #0x80
	movs	r1, #0x94
	movs	r2, #0x64
	movs	r3, #0x20
	str	r5, [sp, #8]
	bl	draw_wrapped_text_in_box
	movw	r0, #:lower16:d_080bc428+1
	movt	r0, #:upper16:d_080bc428+1
	cmp	r4, #2
	it	eq
	moveq	r8, r0
	mov	r0, r8
	movs	r1, #0xe4
	movs	r2, #0x9b
	bl	decode_image_file_with_offset
	ldrb	r0, [r6, #0x16]
	movw	r1, #:lower16:d_0804c7fc
	movt	r1, #:upper16:d_0804c7fc
	ldr.w	r0, [r1, r0, lsl #2]
	movs	r7, #1
	strd	r0, r11, [sp, #0]
	str	r5, [sp, #8]
	movs	r0, #0xe4
	movs	r1, #0x9a
	movs	r2, #0x42
	movs	r3, #0x14
	b.w	.L080151f8
.L080139ec:
	movw	r2, #0x8350
	movs	r0, #0x3e
	mov.w	lr, #0x3f
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L08013a10
.L08013a04:
	adds	r0, #2
	cmp	r0, #0x5e
	add.w	lr, lr, #2
	beq.w	.L08014252
.L08013a10:
	movs	r6, #0x7b
	b.n	.L08013a1a
.L08013a14:
	adds	r6, #2
	cmp	r6, r3
	beq.n	.L08013a8c
.L08013a1a:
	ldrh	r4, [r2, #0]
	subs	r5, r6, #1
	cmp	r5, r4
	bcc.n	.L08013a54
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r4
	cmp	r7, r5
	bls.n	.L08013a54
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	bcc.n	.L08013a54
	ldrh	r7, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L08013a54
	ldr	r7, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r6
	add.w	r1, r7, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013a54:
	ldrh	r1, [r2, #0]
	cmp	r6, r1
	bcc.n	.L08013a14
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013a14
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L08013a14
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L08013a14
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r5, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r5, r0, r5
	muls	r5, r7, r5
	subs	r4, r5, r4
	add	r4, r6
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L08013a14
	.short	0xbf00	@ padding
.L08013a8c:
	orr.w	r6, r0, #1
	movs	r5, #0x7b
	b.n	.L08013a9a
.L08013a94:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L08013a04
.L08013a9a:
	ldrh	r1, [r2, #0]
	subs	r4, r5, #1
	cmp	r4, r1
	bcc.n	.L08013ad8
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r4
	bls.n	.L08013ad8
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L08013ad8
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013ad8
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	add.w	r1, r8, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013ad8:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	bcc.n	.L08013a94
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L08013a94
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L08013a94
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013a94
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	strh.w	r12, [r8, r1, lsl #1]
	b.n	.L08013a94
.L08013b12:
	movw	r2, #0x8350
	movs	r0, #0x3e
	mov.w	lr, #0x3f
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L08013b38
	.short	0xbf00	@ padding
.L08013b2c:
	adds	r0, #2
	cmp	r0, #0x5e
	add.w	lr, lr, #2
	beq.w	.L0801427e
.L08013b38:
	movs	r6, #0x7b
	b.n	.L08013b42
.L08013b3c:
	adds	r6, #2
	cmp	r6, r3
	beq.n	.L08013bb4
.L08013b42:
	ldrh	r4, [r2, #0]
	subs	r5, r6, #1
	cmp	r5, r4
	bcc.n	.L08013b7c
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r4
	cmp	r7, r5
	bls.n	.L08013b7c
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	bcc.n	.L08013b7c
	ldrh	r7, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L08013b7c
	ldr	r7, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r6
	add.w	r1, r7, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013b7c:
	ldrh	r1, [r2, #0]
	cmp	r6, r1
	bcc.n	.L08013b3c
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013b3c
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L08013b3c
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L08013b3c
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r5, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r5, r0, r5
	muls	r5, r7, r5
	subs	r4, r5, r4
	add	r4, r6
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L08013b3c
	.short	0xbf00	@ padding
.L08013bb4:
	orr.w	r6, r0, #1
	movs	r5, #0x7b
	b.n	.L08013bc2
.L08013bbc:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L08013b2c
.L08013bc2:
	ldrh	r1, [r2, #0]
	subs	r4, r5, #1
	cmp	r4, r1
	bcc.n	.L08013c00
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r4
	bls.n	.L08013c00
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L08013c00
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013c00
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	add.w	r1, r8, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013c00:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	bcc.n	.L08013bbc
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L08013bbc
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L08013bbc
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013bbc
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	strh.w	r12, [r8, r1, lsl #1]
	b.n	.L08013bbc
.L08013c3a:
	cmp	r0, #0
	beq.w	.L08014504
	ldrb.w	r0, [r12, #0xf6b]
	movw	r1, #:lower16:d_080bc508
	lsls	r0, r0, #0x1c
	movw	r0, #:lower16:d_080bc5a2
	movt	r0, #:upper16:d_080bc5a2
	mov	r4, r12
	movt	r1, #:upper16:d_080bc508
	it	eq
	moveq	r0, r1
	b.w	.L0801450e
.L08013c60:
	movw	r2, #0x8350
	movs	r0, #0x4c
	mov.w	lr, #0x4d
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L08013c84
.L08013c78:
	adds	r0, #2
	cmp	r0, #0x6c
	add.w	lr, lr, #2
	beq.w	.L08013698
.L08013c84:
	movs	r6, #0x7b
	b.n	.L08013c8e
.L08013c88:
	adds	r6, #2
	cmp	r6, r3
	beq.n	.L08013d00
.L08013c8e:
	ldrh	r4, [r2, #0]
	subs	r5, r6, #1
	cmp	r5, r4
	bcc.n	.L08013cc8
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r4
	cmp	r7, r5
	bls.n	.L08013cc8
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	bcc.n	.L08013cc8
	ldrh	r7, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L08013cc8
	ldr	r7, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r6
	add.w	r1, r7, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013cc8:
	ldrh	r1, [r2, #0]
	cmp	r6, r1
	bcc.n	.L08013c88
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013c88
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L08013c88
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L08013c88
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r5, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r5, r0, r5
	muls	r5, r7, r5
	subs	r4, r5, r4
	add	r4, r6
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L08013c88
	.short	0xbf00	@ padding
.L08013d00:
	orr.w	r6, r0, #1
	movs	r5, #0x7b
	b.n	.L08013d0e
.L08013d08:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L08013c78
.L08013d0e:
	ldrh	r1, [r2, #0]
	subs	r4, r5, #1
	cmp	r4, r1
	bcc.n	.L08013d4c
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r4
	bls.n	.L08013d4c
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L08013d4c
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013d4c
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	add.w	r1, r8, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013d4c:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	bcc.n	.L08013d08
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L08013d08
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L08013d08
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013d08
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	strh.w	r12, [r8, r1, lsl #1]
	b.n	.L08013d08
.L08013d86:
	movw	r2, #0x8350
	movs	r0, #0x70
	mov.w	lr, #0x71
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L08013dac
	.short	0xbf00	@ padding
.L08013da0:
	adds	r0, #2
	cmp	r0, #0x90
	add.w	lr, lr, #2
	beq.w	.L0801375c
.L08013dac:
	movs	r7, #0x7b
	b.n	.L08013db6
.L08013db0:
	adds	r7, #2
	cmp	r7, r3
	beq.n	.L08013e28
.L08013db6:
	ldrh	r4, [r2, #0]
	subs	r5, r7, #1
	cmp	r5, r4
	bcc.n	.L08013df0
	ldrh	r4, [r2, #0]
	ldrh	r6, [r2, #4]
	add	r6, r4
	cmp	r6, r5
	bls.n	.L08013df0
	ldrh	r6, [r2, #2]
	cmp	r0, r6
	bcc.n	.L08013df0
	ldrh	r6, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r6, r5
	cmp	r6, r0
	bls.n	.L08013df0
	ldr	r6, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r7
	add.w	r1, r6, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013df0:
	ldrh	r1, [r2, #0]
	cmp	r7, r1
	bcc.n	.L08013db0
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r7
	bls.n	.L08013db0
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L08013db0
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L08013db0
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r5, [r2, #2]
	ldrh	r6, [r2, #4]
	subs	r5, r0, r5
	muls	r5, r6, r5
	subs	r4, r5, r4
	add	r4, r7
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L08013db0
	.short	0xbf00	@ padding
.L08013e28:
	orr.w	r7, r0, #1
	movs	r5, #0x7b
	b.n	.L08013e36
.L08013e30:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L08013da0
.L08013e36:
	ldrh	r1, [r2, #0]
	subs	r4, r5, #1
	cmp	r4, r1
	bcc.n	.L08013e74
	ldrh	r1, [r2, #0]
	ldrh	r6, [r2, #4]
	add	r1, r6
	cmp	r1, r4
	bls.n	.L08013e74
	ldrh	r1, [r2, #2]
	cmp	r7, r1
	bcc.n	.L08013e74
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r7
	bls.n	.L08013e74
	ldr.w	r9, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r6, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r6, lr, r6
	muls	r1, r6, r1
	subs	r1, r1, r4
	add	r1, r5
	add.w	r1, r9, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013e74:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	bcc.n	.L08013e30
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L08013e30
	ldrh	r1, [r2, #2]
	cmp	r7, r1
	bcc.n	.L08013e30
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r7
	bls.n	.L08013e30
	ldr.w	r9, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r6, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r6, lr, r6
	muls	r1, r6, r1
	subs	r1, r1, r4
	add	r1, r5
	strh.w	r12, [r9, r1, lsl #1]
	b.n	.L08013e30
.L08013eae:
	movw	r2, #0x8350
	movs	r0, #0x3e
	mov.w	lr, #0x3f
	movt	r2, #0x2000
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L08013ed4
	.short	0xbf00	@ padding
.L08013ec8:
	adds	r0, #2
	cmp	r0, #0x5e
	add.w	lr, lr, #2
	beq.w	.L080142ac
.L08013ed4:
	movs	r6, #0x7b
	b.n	.L08013ede
.L08013ed8:
	adds	r6, #2
	cmp	r6, r3
	beq.n	.L08013f50
.L08013ede:
	ldrh	r4, [r2, #0]
	subs	r5, r6, #1
	cmp	r5, r4
	bcc.n	.L08013f18
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r7, r4
	cmp	r7, r5
	bls.n	.L08013f18
	ldrh	r7, [r2, #2]
	cmp	r0, r7
	bcc.n	.L08013f18
	ldrh	r7, [r2, #2]
	ldrh	r5, [r2, #6]
	add	r7, r5
	cmp	r7, r0
	bls.n	.L08013f18
	ldr	r7, [r2, #8]
	ldrh	r5, [r2, #0]
	ldrh	r4, [r2, #2]
	ldrh	r1, [r2, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r6
	add.w	r1, r7, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013f18:
	ldrh	r1, [r2, #0]
	cmp	r6, r1
	bcc.n	.L08013ed8
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013ed8
	ldrh	r1, [r2, #2]
	cmp	r0, r1
	bcc.n	.L08013ed8
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r0
	bls.n	.L08013ed8
	ldr	r1, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r5, [r2, #2]
	ldrh	r7, [r2, #4]
	subs	r5, r0, r5
	muls	r5, r7, r5
	subs	r4, r5, r4
	add	r4, r6
	strh.w	r12, [r1, r4, lsl #1]
	b.n	.L08013ed8
	.short	0xbf00	@ padding
.L08013f50:
	orr.w	r6, r0, #1
	movs	r5, #0x7b
	b.n	.L08013f5e
.L08013f58:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L08013ec8
.L08013f5e:
	ldrh	r1, [r2, #0]
	subs	r4, r5, #1
	cmp	r4, r1
	bcc.n	.L08013f9c
	ldrh	r1, [r2, #0]
	ldrh	r7, [r2, #4]
	add	r1, r7
	cmp	r1, r4
	bls.n	.L08013f9c
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L08013f9c
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013f9c
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	add.w	r1, r8, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08013f9c:
	ldrh	r1, [r2, #0]
	cmp	r5, r1
	bcc.n	.L08013f58
	ldrh	r1, [r2, #0]
	ldrh	r4, [r2, #4]
	add	r1, r4
	cmp	r1, r5
	bls.n	.L08013f58
	ldrh	r1, [r2, #2]
	cmp	r6, r1
	bcc.n	.L08013f58
	ldrh	r1, [r2, #2]
	ldrh	r4, [r2, #6]
	add	r1, r4
	cmp	r1, r6
	bls.n	.L08013f58
	ldr.w	r8, [r2, #8]
	ldrh	r4, [r2, #0]
	ldrh	r7, [r2, #2]
	ldrh	r1, [r2, #4]
	sub.w	r7, lr, r7
	muls	r1, r7, r1
	subs	r1, r1, r4
	add	r1, r5
	strh.w	r12, [r8, r1, lsl #1]
	b.n	.L08013f58
.L08013fd6:
	movs	r0, #0x30
	mov.w	lr, #0x31
	movw	r2, #0x131
	movw	r12, #0x18c3
	b.n	.L08013ff4
	.short	0xbf00	@ padding
.L08013fe8:
	adds	r0, #2
	cmp	r0, #0x50
	add.w	lr, lr, #2
	beq.w	.L080142da
.L08013ff4:
	movs	r6, #0x7b
	b.n	.L08013ffe
.L08013ff8:
	adds	r6, #2
	cmp	r6, r2
	beq.n	.L08014070
.L08013ffe:
	ldrh	r4, [r7, #0]
	subs	r5, r6, #1
	cmp	r5, r4
	bcc.n	.L08014038
	ldrh	r4, [r7, #0]
	ldrh	r3, [r7, #4]
	add	r3, r4
	cmp	r3, r5
	bls.n	.L08014038
	ldrh	r3, [r7, #2]
	cmp	r0, r3
	bcc.n	.L08014038
	ldrh	r3, [r7, #2]
	ldrh	r5, [r7, #6]
	add	r3, r5
	cmp	r3, r0
	bls.n	.L08014038
	ldr	r3, [r7, #8]
	ldrh	r5, [r7, #0]
	ldrh	r4, [r7, #2]
	ldrh	r1, [r7, #4]
	subs	r4, r0, r4
	muls	r1, r4, r1
	subs	r1, r1, r5
	add	r1, r6
	add.w	r1, r3, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L08014038:
	ldrh	r1, [r7, #0]
	cmp	r6, r1
	bcc.n	.L08013ff8
	ldrh	r1, [r7, #0]
	ldrh	r3, [r7, #4]
	add	r1, r3
	cmp	r1, r6
	bls.n	.L08013ff8
	ldrh	r1, [r7, #2]
	cmp	r0, r1
	bcc.n	.L08013ff8
	ldrh	r1, [r7, #2]
	ldrh	r3, [r7, #6]
	add	r1, r3
	cmp	r1, r0
	bls.n	.L08013ff8
	ldr	r1, [r7, #8]
	ldrh	r3, [r7, #0]
	ldrh	r4, [r7, #2]
	ldrh	r5, [r7, #4]
	subs	r4, r0, r4
	muls	r4, r5, r4
	subs	r3, r4, r3
	add	r3, r6
	strh.w	r12, [r1, r3, lsl #1]
	b.n	.L08013ff8
	.short	0xbf00	@ padding
.L08014070:
	orr.w	r6, r0, #1
	movs	r5, #0x7b
	b.n	.L0801407e
.L08014078:
	adds	r5, #2
	cmp	r5, r2
	beq.n	.L08013fe8
.L0801407e:
	ldrh	r1, [r7, #0]
	subs	r4, r5, #1
	cmp	r4, r1
	bcc.n	.L080140bc
	ldrh	r1, [r7, #0]
	ldrh	r3, [r7, #4]
	add	r1, r3
	cmp	r1, r4
	bls.n	.L080140bc
	ldrh	r1, [r7, #2]
	cmp	r6, r1
	bcc.n	.L080140bc
	ldrh	r1, [r7, #2]
	ldrh	r3, [r7, #6]
	add	r1, r3
	cmp	r1, r6
	bls.n	.L080140bc
	ldr.w	r8, [r7, #8]
	ldrh	r3, [r7, #0]
	ldrh	r4, [r7, #2]
	ldrh	r1, [r7, #4]
	sub.w	r4, lr, r4
	muls	r1, r4, r1
	subs	r1, r1, r3
	add	r1, r5
	add.w	r1, r8, r1, lsl #1
	strh.w	r12, [r1, #-2]
.L080140bc:
	ldrh	r1, [r7, #0]
	cmp	r5, r1
	bcc.n	.L08014078
	ldrh	r1, [r7, #0]
	ldrh	r3, [r7, #4]
	add	r1, r3
	cmp	r1, r5
	bls.n	.L08014078
	ldrh	r1, [r7, #2]
	cmp	r6, r1
	bcc.n	.L08014078
	ldrh	r1, [r7, #2]
	ldrh	r3, [r7, #6]
	add	r1, r3
	cmp	r1, r6
	bls.n	.L08014078
	ldr.w	r8, [r7, #8]
	ldrh	r3, [r7, #0]
	ldrh	r4, [r7, #2]
	ldrh	r1, [r7, #4]
	sub.w	r4, lr, r4
	muls	r1, r4, r1
	subs	r1, r1, r3
	add	r1, r5
	strh.w	r12, [r8, r1, lsl #1]
	b.n	.L08014078
.L080140f6:
	movs	r1, #0x94
	mov.w	lr, #0x95
	movw	r3, #0x131
	movw	r12, #0x18c3
	b.n	.L08014114
	.short	0xbf00	@ padding
.L08014108:
	adds	r1, #2
	cmp	r1, #0xb4
	add.w	lr, lr, #2
	beq.w	.L0801396a
.L08014114:
	movs	r7, #0x7b
	b.n	.L0801411e
.L08014118:
	adds	r7, #2
	cmp	r7, r3
	beq.n	.L08014190
.L0801411e:
	ldrh	r4, [r0, #0]
	subs	r5, r7, #1
	cmp	r5, r4
	bcc.n	.L08014158
	ldrh	r4, [r0, #0]
	ldrh	r6, [r0, #4]
	add	r6, r4
	cmp	r6, r5
	bls.n	.L08014158
	ldrh	r6, [r0, #2]
	cmp	r1, r6
	bcc.n	.L08014158
	ldrh	r6, [r0, #2]
	ldrh	r5, [r0, #6]
	add	r6, r5
	cmp	r6, r1
	bls.n	.L08014158
	ldr	r6, [r0, #8]
	ldrh	r5, [r0, #0]
	ldrh	r4, [r0, #2]
	ldrh	r2, [r0, #4]
	subs	r4, r1, r4
	muls	r2, r4, r2
	subs	r2, r2, r5
	add	r2, r7
	add.w	r2, r6, r2, lsl #1
	strh.w	r12, [r2, #-2]
.L08014158:
	ldrh	r2, [r0, #0]
	cmp	r7, r2
	bcc.n	.L08014118
	ldrh	r2, [r0, #0]
	ldrh	r4, [r0, #4]
	add	r2, r4
	cmp	r2, r7
	bls.n	.L08014118
	ldrh	r2, [r0, #2]
	cmp	r1, r2
	bcc.n	.L08014118
	ldrh	r2, [r0, #2]
	ldrh	r4, [r0, #6]
	add	r2, r4
	cmp	r2, r1
	bls.n	.L08014118
	ldr	r2, [r0, #8]
	ldrh	r4, [r0, #0]
	ldrh	r5, [r0, #2]
	ldrh	r6, [r0, #4]
	subs	r5, r1, r5
	muls	r5, r6, r5
	subs	r4, r5, r4
	add	r4, r7
	strh.w	r12, [r2, r4, lsl #1]
	b.n	.L08014118
	.short	0xbf00	@ padding
.L08014190:
	orr.w	r7, r1, #1
	movs	r5, #0x7b
	b.n	.L080141da
.L08014198:
	.word	0x080bbb5d
	.word	0x080bbae8
	.word	0x080bbada
	.word	0x080bba25
	.word	0x080bbb6b
	.word	0x080bba5a
	.word	0x080bba2a
	.word	0x080bba3d
	.word	0x080bba25
	.word	0x080bbaac
.L080141c0:
	.word	0x080bc63f
	.word	0x080bc63f
	.word	0x080bc429
.L080141cc:
	.word	0x080bbc37
	.word	0x080bbc55
.L080141d4:
	adds	r5, #2
	cmp	r5, r3
	beq.n	.L08014108
.L080141da:
	ldrh	r2, [r0, #0]
	subs	r4, r5, #1
	cmp	r4, r2
	bcc.n	.L08014218
	ldrh	r2, [r0, #0]
	ldrh	r6, [r0, #4]
	add	r2, r6
	cmp	r2, r4
	bls.n	.L08014218
	ldrh	r2, [r0, #2]
	cmp	r7, r2
	bcc.n	.L08014218
	ldrh	r2, [r0, #2]
	ldrh	r4, [r0, #6]
	add	r2, r4
	cmp	r2, r7
	bls.n	.L08014218
	ldr.w	r9, [r0, #8]
	ldrh	r4, [r0, #0]
	ldrh	r6, [r0, #2]
	ldrh	r2, [r0, #4]
	sub.w	r6, lr, r6
	muls	r2, r6, r2
	subs	r2, r2, r4
	add	r2, r5
	add.w	r2, r9, r2, lsl #1
	strh.w	r12, [r2, #-2]
.L08014218:
	ldrh	r2, [r0, #0]
	cmp	r5, r2
	bcc.n	.L080141d4
	ldrh	r2, [r0, #0]
	ldrh	r4, [r0, #4]
	add	r2, r4
	cmp	r2, r5
	bls.n	.L080141d4
	ldrh	r2, [r0, #2]
	cmp	r7, r2
	bcc.n	.L080141d4
	ldrh	r2, [r0, #2]
	ldrh	r4, [r0, #6]
	add	r2, r4
	cmp	r2, r7
	bls.n	.L080141d4
	ldr.w	r9, [r0, #8]
	ldrh	r4, [r0, #0]
	ldrh	r6, [r0, #2]
	ldrh	r2, [r0, #4]
	sub.w	r6, lr, r6
	muls	r2, r6, r2
	subs	r2, r2, r4
	add	r2, r5
	strh.w	r12, [r9, r2, lsl #1]
	b.n	.L080141d4
.L08014252:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x34]
	movs	r1, #0xa6
	movs	r2, #0x47
	cmp	r0, #0
	ittee	ne
	movwne	r0, #:lower16:d_080bc5ce+1
	movtne	r0, #:upper16:d_080bc5ce+1
	movweq	r0, #:lower16:d_080bc4f2
	movteq	r0, #:upper16:d_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.n	.L08014a6e
.L0801427e:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x23a]
	movs	r1, #0xa6
	lsls	r0, r0, #0x1f
	mov.w	r2, #0x47
	ittee	eq
	movweq	r0, #:lower16:d_080bc5ce+1
	movteq	r0, #:upper16:d_080bc5ce+1
	movwne	r0, #:lower16:d_080bc4f2
	movtne	r0, #:upper16:d_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.n	.L0801431a
.L080142ac:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x3c]
	movs	r1, #0xa6
	movs	r2, #0x47
	cmp	r0, #0
	ittee	ne
	movwne	r0, #:lower16:d_080bc5ce+1
	movtne	r0, #:upper16:d_080bc5ce+1
	movweq	r0, #:lower16:d_080bc4f2
	movteq	r0, #:upper16:d_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.w	.L08014c68
.L080142da:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x35]
	movs	r1, #0xb3
	movs	r2, #0x39
	cmp	r0, #0
	ittee	ne
	movwne	r0, #:lower16:d_080bc5ce+1
	movtne	r0, #:upper16:d_080bc5ce+1
	movweq	r0, #:lower16:d_080bc4f2
	movteq	r0, #:upper16:d_080bc4f2
	bl	decode_image_file_with_offset
	movs	r0, #1
	b.w	.L08015216
.L08014308:
	movw	r0, #:lower16:d_080bc54a
	movt	r0, #:upper16:d_080bc54a
	movs	r1, #0xa6
.L08014312:
	movs	r2, #0x45
	bl	decode_image_file_with_offset
	movs	r0, #2
.L0801431a:
	movw	r9, #:lower16:d_0804c180
	movt	r9, #:upper16:d_0804c180
	ldrh.w	r0, [r9, r0, lsl #1]
	movs	r1, #1
	movw	r8, #0x1114
	adr.w	r2, .L0801509c
	movt	r8, #0x2000
	str	r2, [sp, #0]
	strd	r0, r1, [sp, #8]
	.include "src/parts/draw_panels_by_selector_20001062_p2.inc"
	.include "src/parts/draw_panels_by_selector_20001062_p3.inc"
