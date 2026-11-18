@ waveform_85.s - part 1 of 7 of draw_waveform_display (graticule, persistence, traces, cursors, pop-ups)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ draw_waveform_display - draws the waveform display (graticule, live and
@ persistence traces, cursors, measurement text, pop-ups) into the frame buffer.
@ No parameters (r0/r1 are not read; the C param_2 is a VFP artefact), no return
@ value; ends with byte 0x20001068 += 1.
@ Grid: if byte 0x2000012c==0 draw_line(0801fda0, colour 0x3a29) frame
@ (9,0x14)-(0x135,0x14), (9,0xdc)-(0x135,0xdc), (9,0x14)-(9,0xdc),
@ (0x135,0x14)-(0x135,0xdc), centre lines y=0x78 and x=0x9f; then dotted pixels
@ (every 5th pixel, colour 0x3a29, clipped to rectangle halfwords
@ 0x20008350/52/54/56, buffer word 0x20008358) on rows y=0x2d,0x46,0x5f,0x78,
@ 0x91,0xaa,0xc3 (x 9..0x135), columns x=0x22+0x19*k, k=0..10 (y 0x14..0xdc),
@ rows y=0x76,0x77,0x79,0x7a and columns x=0x9d,0x9e,0xa0,0xa1.
@ If byte 0x2000012c!=0: frame (0x3b,0x14)-(0x103,0xdc) with centre lines y=0x78,
@ x=0x9f, dotted rows y=0x2d..0xc3 step 0x19 (x 0x3b..0x103), columns
@ x=0x54,0x6d,0x86,0x9f,0xb8,0xd1,0xea, columns x=0x9d,0x9e,0xa0,0xa1 and rows
@ y=0x76,0x77,0x79,0x7a.
@ Persistence list: list head word 0x20000138 (node: byte [0]=brightness, words
@ [4] and [8]=channel 0 and 1 buffer pointers, halfwords [0xc]=start and
@ [0xe]=length, word [0x10]=next), mode byte 0x20000134, enabled when
@ 0x20000134!=0 and byte 0x20000126!=0. Mode 3 with head!=0: normal view
@ (0x2000012c==0) draws for each channel from nibble hi to nibble lo of byte
@ 0x2000010d (pointer at node+4+ch*4 != 0 and length != 0) a 1-bit column bitmap
@ (26 bytes per column, bit i = pixel y 0xdc-i, x = column+9) in the channel
@ colour (halfword at 0x080bb40c+ch*2+byte(0x2000105b)*4 scaled by node[0]/255);
@ XY view draws the 201x201 bitmap of node+4 at x=0x3b+column in a colour scaled
@ from node[0]*31/255 (red and blue fields).
@ Other modes: byte 0x20000136=byte 0x20000135, byte 0x20000137=(0x20000135
@ (+100 when <= old 0x20000136)) - old 0x20000136; per node
@ d=(double)byte 0x20000137*2.55*(3-mode); if 08045df0(d, node[0]) returns 0 then
@ node[0]=(byte)(node[0]-d) (08045b94, 08045450) and the node trace is drawn
@ (0801fea8 segments (x=start+i+9, y=0xf8-sample) per channel, or draw_line
@ (ch1+0x1f, 0xf8-ch2) in XY view); otherwise the buffers node[4] and node[8] of
@ the current node are released (801b0f8..801b264), then the node at the
@ list-head word 0x20000138 is released and the head word is set to the current
@ node's [0x10] (801b264..801aff4); each release calls the callback word
@ 0x20001070(0) when byte 0x20001080==0, else when (pointer-word 0x20001078)>>10
@ < 0xaf it clears 2*h bytes at word 0x2000107c + 2*((pointer-word 0x20001078)>>5)
@ with zero_bytes 080082bc, h being the halfword there when nonzero.
@ Live traces: sample count at 0x20000eae (0: skip the traces), start halfword
@ 0x20000eac; channels from nibble hi to lo of byte at (0x2000010c if byte
@ 0x20000126!=0 else 0x20000eb6)+1; samples at 0x2000044e+ch*0x12d (ch1
@ 0x2000044e, ch2 0x2000057b); normal view draws 0801fea8(i+9, 0xf8-s[i], i+10,
@ 0xf8-s[i+1], channel colour) for i from start; when byte 0x20000126==0 and the
@ 64-bit value 0x20000f04:0x20000f00 > 999 the x position is
@ i/((f00/1000)*scale)+start+9 with scale=value at 0x20000efc (1 when word
@ 0x20000ef4+ch*4 is 0), and the loop runs for i < min(0x12d-value at 0x20000ed8,
@ (0x20000f00*count/1000)*scale)-1 (divide_u64 08008642); XY view (0x2000012c!=0)
@ draws draw_line(ch1[i]+0x1f, 0xf8-ch2[i], ch1[i+1]+0x1f, 0xf8-ch2[i+1]) the
@ same way.
@ In normal view also: for each channel with byte 0x20000102+ch != 0 and pointer
@ word 0x20000104+ch*4 != 0 a 128-column bar strip (x uses the channel number
@ itself) 0801fea8(x=ch*0xad+9+k, 0x46, x, 0x46-byte[k]) k=0..0x7f; then the
@ marker fill_triangle (08020af8, colour 0x7e2) from signed halfword 0x20000112:
@ (v+0x9a,0x14),(v+0xa4,0x14),(v+0x9f,0x1b), clamped to
@ (0x12e,0x14),(0x12e,0x1e),(0x135,0x19) for v>=0x92 and
@ (0x10,0x14),(0x10,0x1e),(9,0x19) for v<-0x91.
@ Measurement list: when word 0x20000144 != 0, byte 0x2000010c != 0, byte
@ 0x20000140==0 and 0x2000012c==0, counts the set bits of word 0x20000144 (bit0
@ of byte 0x2000010c selects bits 0..15, bit1 selects bits 16..31) and draws them
@ from y=0xcc-15*((n-1)/3) step 0xf, x=0xc step 100, three per row with the first
@ row holding n%3 items when n%3 != 0 (801ba2c..801ba34): value int from word
@ 0x20000208[i] (i<16) or 0x20000238[i-16] (i is the bit number of word
@ 0x20000144; for bits 16..31 the /100 and /1000 tests, the label index and the
@ unit index below use i-16), divided by 1000 up to three times while
@ |v|>999999, to float, /100 for i=2,3, /1000 for i=6..11, /1000 again with unit
@ index+1 when |f|>=1000; text "%s%.2f%s" when |f|<100 else "%s%.1f%s" (label
@ from the English label table d_0804bf28 word i, unit from the
@ two-level table at 0x0801ca18/0x0801ca24: Hz/KHz/MHz, nS/uS/mS/S, %, mV/V),
@ drawn with 0800f154(x,y,100,0xf,font 0x200010b4,colour from halfword table,0).
@ Cursor lines and their label list (only when byte 0x2000012c==0): byte
@ 0x20000332 bit0: 0801fea8 vertical lines at x=halfword 0x2000032a+0x9f and
@ halfword 0x2000032c+0x9f (y 0x14..0xdc); bit1: draw_line horizontal at
@ y=0x78-halfword 0x2000032e and 0x78-halfword 0x20000330 (x 9..0x135); when byte
@ 0x20000332 != 0 a label list from y=0x19 step 0xc: label word from 0x0801ca7c
@ table ("X1:","X2:","X1-X2:","Y1:","Y2:","Y1-Y2:","1/d|X|:") at
@ (0xe,y,0x32,0x10, font 0x200010e4, colour 0xf81f) and "%.2f%s" of float
@ 0x20000334+idx*4 with a unit word from the table at 0x0804bf88 (row = byte at
@ 0x0801ca98+idx, column = byte 0x20000350+idx) at (0x40,y,100,0x10, same font
@ and colour) (items 0-2 when bit0, 3-5 when bit1, item 6 when bit0 is set or
@ bit1 clear).
@ Reference trace: when byte 0x2000012d != 0, word 0x20000130 != 0, 0x2000012c==0
@ and 0x20000eae > 1: 0801fea8(x, 0x78-(signed byte)ref[i], x+1,
@ 0x78-ref[i+1]) with the same x scaling as the live trace.
@ Vertical cursor (halfword 0x20000122 != 0, 0x2000012c==0): dotted line colour
@ 0x7e2 (3 on, 2 off) across x 9..0x135 at the row derived from halfword
@ 0x20000114 (clamped 0x14..0xdc), and a voltage label "%.2fmV" (|v|<1000) or
@ "%.2fV" computed as the product of the halfword at
@ 0x0804bfb8+((byte 0x200000fa[ch] % 3))*2 (values 0x190,0x320,0x7d0), two
@ 080438e0 power results (exponents byte 0x200000fa[ch]/3 and byte
@ 0x200000fe[ch]), division by 1000.0 and (halfword 0x20000114 - signed byte
@ 0x200000fc[ch]) with ch=byte 0x2000010e (080455da, 0804577c, 08045124,
@ 08045d70, 08044f48), with y=rowY-10 clamped to 0xca above 0xd6 and to 0x14
@ below 0x1e, drawn with 0800f154(0xa0,y,0x7d,0x14,font 0x20001144,0xffff,2).
@ Horizontal cursor (halfword 0x20000120 != 0, 0x2000012c==0): dotted vertical
@ line colour 0x7e2 at x=halfword 0x20000112+0x9f (y 0x1c..0xdc) and a time label
@ "%.2f%s" from -(signed 64-bit 0x20000118:0x2000011c)/2.5 divided by 1000.0
@ (08045124) until 08045e0c(|v|,1000.0) returns nonzero (08045538 converts the
@ 64-bit value), drawn with 0800f154(0,0xb4,0x140,0x14,font 0x20001144,0xffff,1).
@ When byte 0x2000012c != 0 it calls 08028b40; after that call 0x2000012c is read
@ again (08028b40 has no store to that byte, it only reads it at 08028b4e and
@ 08028c36) and only if it is then 0 is the triangle
@ fill_triangle(0x136,y,0x13d,y+5,0x13d,y-5,0x7e2) drawn (y=0x78-halfword
@ 0x20000114, or 0x14 when (that halfword+100)&0xffff > 200).
@ Pop-ups: drawn when (byte 0x20000f08 not 0 and not 0xff) or byte 0x20000127 or
@ 0x20000128 or 0x2000012b != 0 or (byte 0x2000010f==2 and byte 0x20000126 != 0)
@ or (byte 0x20000126==0 and 0x20000f04==0 and 0x20000f00 < 10): six black
@ (colour 0) fill_triangles (0xea,0x51,0x45,0x51,0xef,0x55),
@ (0x45,0x51,0xef,0x55,0x3e,0x59), (0xef,0x55,0x3e,0x59,0x101,0x55),
@ (0x3e,0x59,0x101,0x55,0x3e,0xa1), (0x101,0x55,0x3e,0xa1,0x101,0x98),
@ (0x3e,0xa1,0x101,0x98,0xfa,0xa1) and draw_4bpp_bitmap
@ 0801ffcc(0x3d,0x50,0xc6,0x53,bitmap 0x0804fd00,0x55f).
@ Pop-up texts (0800f154, font 0x20001174, colour 0x55f, English text named
@ directly; V1.2.0 read them from 8-word language rows): byte 0x20000f08==3
@ "Save failed" and ==2 "Saved" at (0x3f,0x50,0xc2,0x53,flag 1); ==1: byte
@ 0x20000f13=0803b878("2:/Screenshot simple file"), "Saving..." at
@ (0x3f,0x60,0xc2,0x19,flag 1), "%d.bmp" of byte 0x20000f09 at
@ (0x3f,0x76,0xc2,0x19,flag 1), byte 0x20000f08=0xff, byte 0x20001060=10, then
@ 08041cf0(word 0x20002d6c, &byte, -1) with byte 0x24 and again with byte 3;
@ byte 0x2000010f==2 and 0x20000126!=0: "Await Trigger..." at
@ (0x3f,0x50,0xc2,0x53,1); byte 0x20000127: "Awaiting Auto Measurement...", byte
@ 0x20000128: "Awaiting auto-correction...", (0x20000126==0 and 0x20000f04==0 and
@ 0x20000f00<10): "Exceeded Limit", byte 0x2000012b: "Waiting for automatic
@ amplitude calibration", each at (0x3f,0x58,0xc2,0x4b,flag 0x81).
@ ----------------------------------------------------------------------------
	.section .text.draw_waveform_display,"ax",%progbits
	.p2align 2
	.global draw_waveform_display
	.thumb_func
	.type draw_waveform_display, %function
draw_waveform_display:
	push.w {r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub sp, #4
	vpush {d8, d9, d10, d11, d12}
	sub sp, #0x40
	movw r8, #0xf8
	movt r8, #0x2000
	ldrb.w r0, [r8, #0x34]
	movw r5, #0x8350
	cmp r0, #0
	movt r5, #0x2000
	movw r4, #0x3a29
	beq.w .L08018484
	movs r0, #0x3b
	movs r1, #0x14
	movw r2, #0x103
	movs r3, #0x14
	str r4, [sp]
	bl draw_line
	movs r0, #0x3b
	movs r1, #0xdc
	movw r2, #0x103
	movs r3, #0xdc
	str r4, [sp]
	bl draw_line
	movs r0, #0x3b
	movs r1, #0x14
	movs r2, #0x3b
	movs r3, #0xdc
	str r4, [sp]
	bl draw_line
	movw r0, #0x103
	movs r1, #0x14
	movw r2, #0x103
	movs r3, #0xdc
	str r4, [sp]
	bl draw_line
	movs r0, #0x3b
	movs r1, #0x78
	movw r2, #0x103
	movs r3, #0x78
	str r4, [sp]
	bl draw_line
	movs r0, #0x9f
	movs r1, #0x14
	movs r2, #0x9f
	movs r3, #0xdc
	str r4, [sp]
	bl draw_line
	movs r1, #0
	movs r0, #0x3d
	b.n .L0801664e
	.byte 0x00, 0xbf	@ padding
.L08016638:
	adds r1, #1
	uxth r2, r1
	cmp r2, #4
	add.w r0, r0, #3
	it hi
	movhi r1, #0
	cmp.w r0, #0x106
	beq.w .L08016756
.L0801664e:
	lsls r2, r1, #0x10
	bne.n .L080166a0
	ldrh r3, [r5]
	subs r2, r0, #2
	cmp r2, r3
	bcc.n .L080166a0
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r2
	bls.n .L080166a0
	ldrh r2, [r5, #2]
	cmp r2, #0x2d
	bhi.n .L080166a0
	ldrh r2, [r5, #2]
	ldrh r3, [r5, #6]
	add r2, r3
	cmp r2, #0x2e
	bcc.n .L080166a0
	movw r6, #0x8350
	ldr r2, [r5, #8]
	ldrh r3, [r5]
	ldrh r7, [r5, #2]
	movt r6, #0x2000
	ldrh r6, [r6, #4]
	rsb.w r7, r7, #0x2d
	muls r7, r6, r7
	subs r3, r7, r3
	movw r5, #0x8350
	add r3, r0
	movt r5, #0x2000
	add.w r2, r2, r3, lsl #1
	strh r4, [r2, #-4]
	nop
.L080166a0:
	adds r1, #1
	uxth r2, r1
	cmp r2, #4
	it hi
	movhi r1, #0
	lsls r2, r1, #0x10
	bne.n .L080166fc
	ldrh r3, [r5]
	subs r2, r0, #1
	cmp r2, r3
	bcc.n .L080166fc
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r2
	bls.n .L080166fc
	ldrh r2, [r5, #2]
	cmp r2, #0x2d
	bhi.n .L080166fc
	ldrh r2, [r5, #2]
	ldrh r3, [r5, #6]
	add r2, r3
	cmp r2, #0x2e
	bcc.n .L080166fc
	movw r6, #0x8350
	ldr r2, [r5, #8]
	ldrh r3, [r5]
	ldrh r7, [r5, #2]
	movt r6, #0x2000
	ldrh r6, [r6, #4]
	rsb.w r7, r7, #0x2d
	muls r7, r6, r7
	subs r3, r7, r3
	movw r5, #0x8350
	add r3, r0
	movt r5, #0x2000
	add.w r2, r2, r3, lsl #1
	strh r4, [r2, #-2]
	nop
.L080166fc:
	adds r1, #1
	uxth r2, r1
	cmp r2, #4
	it hi
	movhi r1, #0
	lsls r2, r1, #0x10
	bne.n .L08016638
	ldrh r2, [r5]
	cmp r0, r2
	bcc.n .L08016638
	ldrh r2, [r5]
	ldrh r3, [r5, #4]
	add r2, r3
	cmp r2, r0
	bls.n .L08016638
	ldrh r2, [r5, #2]
	cmp r2, #0x2d
	bhi.w .L08016638
	ldrh r2, [r5, #2]
	ldrh r3, [r5, #6]
	add r2, r3
	cmp r2, #0x2e
	bcc.w .L08016638
	movw r6, #0x8350
	ldr r2, [r5, #8]
	ldrh r3, [r5]
	ldrh r7, [r5, #2]
	movt r6, #0x2000
	ldrh r6, [r6, #4]
	rsb.w r7, r7, #0x2d
	muls r7, r6, r7
	movw r5, #0x8350
	subs r3, r7, r3
	movt r5, #0x2000
	add r3, r0
	strh.w r4, [r2, r3, lsl #1]
	b.n .L08016638
.L08016756:
	movs r2, #0
	movs r0, #0x3d
	movw r1, #0x3a29
	b.n .L08016776
.L08016760:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp.w r0, #0x106
	beq.w .L080168bc
.L08016776:
	lsls r3, r2, #0x10
	bne.n .L080167e0
	ldrh r7, [r5]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L080167e0
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L080167e0
	ldrh r3, [r5, #2]
	cmp r3, #0x46
	bhi.n .L080167e0
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x47
	bcc.n .L080167e0
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x46
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-4]
	nop
.L080167e0:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L08016854
	ldrh r7, [r5]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L08016854
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016854
	ldrh r3, [r5, #2]
	cmp r3, #0x46
	bhi.n .L08016854
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x47
	bcc.n .L08016854
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x46
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-2]
	nop
.L08016854:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L08016760
	ldrh r3, [r5]
	cmp r0, r3
	bcc.w .L08016760
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r0
	bls.w .L08016760
	ldrh r3, [r5, #2]
	cmp r3, #0x46
	bhi.w .L08016760
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x47
	bcc.w .L08016760
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x46
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L08016760
.L080168bc:
	movs r2, #0
	movs r0, #0x3d
	movw r1, #0x3a29
	b.n .L080168de
	.byte 0x00, 0xbf	@ padding
.L080168c8:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp.w r0, #0x106
	beq.w .L08016a24
.L080168de:
	lsls r3, r2, #0x10
	bne.n .L08016948
	ldrh r7, [r5]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08016948
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016948
	ldrh r3, [r5, #2]
	cmp r3, #0x5f
	bhi.n .L08016948
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x60
	bcc.n .L08016948
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x5f
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-4]
	nop
.L08016948:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L080169bc
	ldrh r7, [r5]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L080169bc
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L080169bc
	ldrh r3, [r5, #2]
	cmp r3, #0x5f
	bhi.n .L080169bc
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x60
	bcc.n .L080169bc
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x5f
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-2]
	nop
.L080169bc:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L080168c8
	ldrh r3, [r5]
	cmp r0, r3
	bcc.w .L080168c8
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r0
	bls.w .L080168c8
	ldrh r3, [r5, #2]
	cmp r3, #0x5f
	bhi.w .L080168c8
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x60
	bcc.w .L080168c8
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x5f
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L080168c8
.L08016a24:
	movs r2, #0
	movs r0, #0x3d
	movw r1, #0x3a29
	b.n .L08016a46
	.byte 0x00, 0xbf	@ padding
.L08016a30:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp.w r0, #0x106
	beq.w .L08016b8c
.L08016a46:
	lsls r3, r2, #0x10
	bne.n .L08016ab0
	ldrh r7, [r5]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08016ab0
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016ab0
	ldrh r3, [r5, #2]
	cmp r3, #0x78
	bhi.n .L08016ab0
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x79
	bcc.n .L08016ab0
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x78
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-4]
	nop
.L08016ab0:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L08016b24
	ldrh r7, [r5]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L08016b24
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016b24
	ldrh r3, [r5, #2]
	cmp r3, #0x78
	bhi.n .L08016b24
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x79
	bcc.n .L08016b24
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x78
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-2]
	nop
.L08016b24:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L08016a30
	ldrh r3, [r5]
	cmp r0, r3
	bcc.w .L08016a30
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r0
	bls.w .L08016a30
	ldrh r3, [r5, #2]
	cmp r3, #0x78
	bhi.w .L08016a30
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x79
	bcc.w .L08016a30
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x78
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L08016a30
.L08016b8c:
	movs r2, #0
	movs r0, #0x3d
	movw r1, #0x3a29
	b.n .L08016bae
	.byte 0x00, 0xbf	@ padding
.L08016b98:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp.w r0, #0x106
	beq.w .L08016cf4
.L08016bae:
	lsls r3, r2, #0x10
	bne.n .L08016c18
	ldrh r7, [r5]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08016c18
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016c18
	ldrh r3, [r5, #2]
	cmp r3, #0x91
	bhi.n .L08016c18
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x92
	bcc.n .L08016c18
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x91
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-4]
	nop
.L08016c18:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L08016c8c
	ldrh r7, [r5]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L08016c8c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016c8c
	ldrh r3, [r5, #2]
	cmp r3, #0x91
	bhi.n .L08016c8c
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x92
	bcc.n .L08016c8c
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x91
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-2]
	nop
.L08016c8c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L08016b98
	ldrh r3, [r5]
	cmp r0, r3
	bcc.w .L08016b98
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r0
	bls.w .L08016b98
	ldrh r3, [r5, #2]
	cmp r3, #0x91
	bhi.w .L08016b98
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0x92
	bcc.w .L08016b98
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0x91
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L08016b98
.L08016cf4:
	movs r2, #0
	movs r0, #0x3d
	movw r1, #0x3a29
	b.n .L08016d16
	.byte 0x00, 0xbf	@ padding
.L08016d00:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp.w r0, #0x106
	beq.w .L08016e5c
.L08016d16:
	lsls r3, r2, #0x10
	bne.n .L08016d80
	ldrh r7, [r5]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08016d80
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016d80
	ldrh r3, [r5, #2]
	cmp r3, #0xaa
	bhi.n .L08016d80
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0xab
	bcc.n .L08016d80
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0xaa
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-4]
	nop
.L08016d80:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L08016df4
	ldrh r7, [r5]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L08016df4
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016df4
	ldrh r3, [r5, #2]
	cmp r3, #0xaa
	bhi.n .L08016df4
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0xab
	bcc.n .L08016df4
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0xaa
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-2]
	nop
.L08016df4:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L08016d00
	ldrh r3, [r5]
	cmp r0, r3
	bcc.w .L08016d00
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r0
	bls.w .L08016d00
	ldrh r3, [r5, #2]
	cmp r3, #0xaa
	bhi.w .L08016d00
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0xab
	bcc.w .L08016d00
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0xaa
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L08016d00
.L08016e5c:
	movs r2, #0
	movs r0, #0x3d
	movw r1, #0x3a29
	b.n .L08016e7e
	.byte 0x00, 0xbf	@ padding
.L08016e68:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp.w r0, #0x106
	beq.w .L08016fc4
.L08016e7e:
	lsls r3, r2, #0x10
	bne.n .L08016ee8
	ldrh r7, [r5]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L08016ee8
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016ee8
	ldrh r3, [r5, #2]
	cmp r3, #0xc3
	bhi.n .L08016ee8
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0xc4
	bcc.n .L08016ee8
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0xc3
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-4]
	nop
.L08016ee8:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L08016f5c
	ldrh r7, [r5]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L08016f5c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5]
	ldrh r6, [r6, #4]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L08016f5c
	ldrh r3, [r5, #2]
	cmp r3, #0xc3
	bhi.n .L08016f5c
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0xc4
	bcc.n .L08016f5c
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0xc3
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	add r7, r0
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh r1, [r3, #-2]
	nop
.L08016f5c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L08016e68
	ldrh r3, [r5]
	cmp r0, r3
	bcc.w .L08016e68
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, r0
	bls.w .L08016e68
	ldrh r3, [r5, #2]
	cmp r3, #0xc3
	bhi.w .L08016e68
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, #0xc4
	bcc.w .L08016e68
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	rsb.w r6, r6, #0xc3
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add r7, r0
	strh.w r1, [r3, r7, lsl #1]
	b.n .L08016e68
.L08016fc4:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08016fe4
	.byte 0x00, 0xbf	@ padding
.L08016fd0:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L08017124
.L08016fe4:
	lsls r3, r2, #0x10
	bne.n .L0801704c
	ldrh r3, [r5]
	cmp r3, #0x54
	bhi.n .L0801704c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x55
	bcc.n .L0801704c
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L0801704c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801704c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0xa8]
	nop
.L0801704c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L080170bc
	ldrh r3, [r5]
	cmp r3, #0x54
	bhi.n .L080170bc
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x55
	bcc.n .L080170bc
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L080170bc
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L080170bc
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0xa8]
.L080170bc:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L08016fd0
	ldrh r3, [r5]
	cmp r3, #0x54
	bhi.w .L08016fd0
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x55
	bcc.w .L08016fd0
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L08016fd0
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L08016fd0
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0xa8]
	b.n .L08016fd0
.L08017124:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08017144
	.byte 0x00, 0xbf	@ padding
.L08017130:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L08017284
.L08017144:
	lsls r3, r2, #0x10
	bne.n .L080171ac
	ldrh r3, [r5]
	cmp r3, #0x6d
	bhi.n .L080171ac
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x6e
	bcc.n .L080171ac
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L080171ac
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L080171ac
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0xda]
	nop
.L080171ac:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L0801721c
	ldrh r3, [r5]
	cmp r3, #0x6d
	bhi.n .L0801721c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x6e
	bcc.n .L0801721c
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L0801721c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801721c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0xda]
.L0801721c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L08017130
	ldrh r3, [r5]
	cmp r3, #0x6d
	bhi.w .L08017130
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x6e
	bcc.w .L08017130
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L08017130
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L08017130
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0xda]
	b.n .L08017130
.L08017284:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L080172a4
	.byte 0x00, 0xbf	@ padding
.L08017290:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L080173e4
.L080172a4:
	lsls r3, r2, #0x10
	bne.n .L0801730c
	ldrh r3, [r5]
	cmp r3, #0x86
	bhi.n .L0801730c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x87
	bcc.n .L0801730c
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L0801730c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801730c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x10c]
	nop
.L0801730c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L0801737c
	ldrh r3, [r5]
	cmp r3, #0x86
	bhi.n .L0801737c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x87
	bcc.n .L0801737c
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L0801737c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801737c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x10c]
.L0801737c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L08017290
	ldrh r3, [r5]
	cmp r3, #0x86
	bhi.w .L08017290
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0x87
	bcc.w .L08017290
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L08017290
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L08017290
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x10c]
	b.n .L08017290
.L080173e4:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08017404
	.byte 0x00, 0xbf	@ padding
.L080173f0:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L08017544
.L08017404:
	lsls r3, r2, #0x10
	bne.n .L0801746c
	ldrh r3, [r5]
	cmp r3, #0x9f
	bhi.n .L0801746c
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xa0
	bcc.n .L0801746c
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L0801746c
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L0801746c
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	subs r6, r0, r6
	ldrh r5, [r5, #4]
	subs r6, #2
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13e]
	nop
.L0801746c:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.n .L080174dc
	ldrh r3, [r5]
	cmp r3, #0x9f
	bhi.n .L080174dc
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xa0
	bcc.n .L080174dc
	ldrh r7, [r5, #2]
	subs r3, r0, #1
	cmp r3, r7
	bcc.n .L080174dc
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L080174dc
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	movw r5, #0x8350
	movt r5, #0x2000
	mvns r6, r6
	ldrh r5, [r5, #4]
	add r6, r0
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13e]
.L080174dc:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	it hi
	movhi r2, #0
	lsls r3, r2, #0x10
	bne.w .L080173f0
	ldrh r3, [r5]
	cmp r3, #0x9f
	bhi.w .L080173f0
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xa0
	bcc.w .L080173f0
	ldrh r3, [r5, #2]
	cmp r0, r3
	bcc.w .L080173f0
	ldrh r3, [r5, #2]
	ldrh r7, [r5, #6]
	add r3, r7
	cmp r3, r0
	bls.w .L080173f0
	movw r6, #0x8350
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	movt r6, #0x2000
	movw r5, #0x8350
	ldrh r6, [r6, #2]
	movt r5, #0x2000
	ldrh r5, [r5, #4]
	subs r6, r0, r6
	muls r6, r5, r6
	subs r7, r6, r7
	movw r5, #0x8350
	movt r5, #0x2000
	add.w r3, r3, r7, lsl #1
	strh.w r1, [r3, #0x13e]
	b.n .L080173f0
.L08017544:
	movs r2, #0
	movs r0, #0x16
	movw r1, #0x3a29
	b.n .L08017564
	.byte 0x00, 0xbf	@ padding
.L08017550:
	adds r2, #1
	uxth r3, r2
	cmp r3, #4
	add.w r0, r0, #3
	it hi
	movhi r2, #0
	cmp r0, #0xdf
	beq.w .L080176a4
.L08017564:
	lsls r3, r2, #0x10
	bne.n .L080175cc
	ldrh r3, [r5]
	cmp r3, #0xb8
	bhi.n .L080175cc
	ldrh r3, [r5]
	ldrh r7, [r5, #4]
	add r3, r7
	cmp r3, #0xb9
	bcc.n .L080175cc
	ldrh r7, [r5, #2]
	subs r3, r0, #2
	cmp r3, r7
	bcc.n .L080175cc
	movw r6, #0x8350
	movt r6, #0x2000
	ldrh r7, [r5, #2]
	ldrh r6, [r6, #6]
	movw r5, #0x8350
	add r7, r6
	movt r5, #0x2000
	cmp r7, r3
	bls.n .L080175cc
	movw r6, #0x8350
	movt r6, #0x2000
	ldr r3, [r5, #8]
	ldrh r7, [r5]
	ldrh r6, [r6, #2]
	.include "src/parts/draw_waveform_display_p2.inc"
	.include "src/parts/draw_waveform_display_p3.inc"
	.include "src/parts/draw_waveform_display_p4.inc"
	.include "src/parts/draw_waveform_display_p5.inc"
	.include "src/parts/draw_waveform_display_p6.inc"
	.include "src/parts/draw_waveform_display_p7.inc"
