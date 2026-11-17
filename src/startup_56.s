@ startup_56.s - reset entry glue, scatter loader, region decompressors, printf conversion dispatcher, C runtime start-up and idle loops.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_08007184 - entry glue (group 0, shares one section with scatter_load_regions).
@ bl scatter_load_regions (0800718c), then bl fn_080072f0 (080072f0). The 8-byte
@ body ends without a branch, so execution continues into 0800718c.
@ ----------------------------------------------------------------------------
	.section .text.fn_08007184,"ax",%progbits
	.global fn_08007184
	.thumb_func
	.type fn_08007184, %function
fn_08007184:
	bl	scatter_load_regions
	bl	fn_080072f0

@ ----------------------------------------------------------------------------
@ scatter_load_regions - scatter loader.
@ adr r0 at 0800718c gives 0x080071b8, whose two words 0x000b715c and 0x000b717c
@ make r10=0x080be314 and r11=0x080be334. The table has two 16-byte entries
@ {r0,r1,r2,r3}: {0x080be480,0x20000000,0x1240,0x080071c0} and
@ {0x080be680,0x20001240,0x35d50,0x0800721c}. Per entry lr=0x0800719d (subw lr,pc,#9
@ at 080071a2), ldm r10!,{r0-r3} at 080071a6, tst r3,#1; if set r3=(r10start-1)-r3,
@ orr r3,#1, bx r3 at 080071b6. So 080071c0 (unpack_token_stream) runs on the first
@ entry and 0800721c (zero_fill_words) on the second; when r10==r11 (cmp at
@ 0800719a) the bl fn_080072f0 at 0800719e is reached.
@ Decompiler note: the indirect jump 'bx r3' at 080071b6 was treated as a call.
@ ----------------------------------------------------------------------------
	.global scatter_load_regions
	.thumb_func
	.type scatter_load_regions, %function
scatter_load_regions:
	adr	r0, .L080071b8
	ldm.w	r0, {r10, r11}
	add	r10, r0
	add	r11, r0
	sub.w	r7, r10, #1
.L0800719a:
	cmp	r10, r11
	bne.n	.L080071a2
	bl	fn_080072f0
.L080071a2:
	adr.w	lr, .L0800719a+1
	ldm.w	r10!, {r0, r1, r2, r3}
	tst.w	r3, #1
	it	ne
	subne	r3, r7, r3
	orr.w	r3, r3, #1
	bx	r3
.L080071b8:
	.word	0x000b715c
	.word	0x000b717c

@ ----------------------------------------------------------------------------
@ unpack_token_stream - token-stream unpacker (group 1).
@ r0=source, r1=destination, r2=length; unpacks until destination reaches r1+r2.
@ Token byte: low 3 bits = literal count (0 means the next byte is the count),
@ high nibble = run length (0 means the next byte is the length). Copies
@ (count-1) literal bytes, then if token bit3 is clear writes run zero bytes,
@ else copies run+2 bytes from destination minus the next source byte (back
@ reference).
@ unpack_token_stream_addr is a plain global label on the same address: the
@ scatter-load region table holds this address as an even value.
@ ----------------------------------------------------------------------------
	.section .text.unpack_token_stream,"ax",%progbits
	.global unpack_token_stream
	.thumb_func
	.type unpack_token_stream, %function
	.global unpack_token_stream_addr
unpack_token_stream:
unpack_token_stream_addr:		@ plain label after the function label (.thumb_func applies to the first)
	add	r2, r1
	mov.w	r12, #0
.L080071c6:
	ldrb.w	r3, [r0], #1
	ands.w	r4, r3, #7
	it	eq
	ldrbeq.w	r4, [r0], #1
	asrs	r5, r3, #4
	it	eq
	ldrbeq.w	r5, [r0], #1
	.inst.n	0x1e64	@ subs r4, r4, #1
	beq.n	.L080071ec
.L080071e0:
	ldrb.w	r6, [r0], #1
	.inst.n	0x1e64	@ subs r4, r4, #1
	strb.w	r6, [r1], #1
	bne.n	.L080071e0
.L080071ec:
	tst.w	r3, #8
	ittt	ne
	ldrbne.w	r4, [r0], #1
	.inst.n	0x1cad	@ adds r5, r5, #2 (inside the IT block)
	subne	r4, r1, r4
	bne.n	.L08007210
.L080071fc:
	.inst.n	0x1e6d	@ subs r5, r5, #1
	it	pl
	strbpl.w	r12, [r1], #1
	bpl.n	.L080071fc
	b.n	.L08007214
.L08007208:
	ldrb.w	r6, [r4], #1
	strb.w	r6, [r1], #1
.L08007210:
	.inst.n	0x1e6d	@ subs r5, r5, #1
	bpl.n	.L08007208
.L08007214:
	cmp	r1, r2
	bcc.n	.L080071c6
	bx	lr
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ zero_fill_words - zero fill by words (group 2).
@ r1=destination, r2=byte count; stores zero words 16 bytes per loop pass while
@ count>=16, then 8 bytes if bit3 of the count is set, then 4 bytes if bit2 is
@ set. Only whole words are written (count bits 1..0 are ignored).
@ zero_fill_words_addr is a plain global label on the same address: the
@ scatter-load region table holds this address as an even value.
@ ----------------------------------------------------------------------------
	.section .text.zero_fill_words,"ax",%progbits
	.global zero_fill_words
	.thumb_func
	.type zero_fill_words, %function
	.global zero_fill_words_addr
zero_fill_words:
zero_fill_words_addr:		@ plain label after the function label (.thumb_func applies to the first)
	movs	r3, #0
	movs	r4, #0
	movs	r5, #0
	movs	r6, #0
.L08007224:
	subs	r2, #0x10
	it	cs
	stmiacs	r1!, {r3, r4, r5, r6}
	bhi.n	.L08007224
	lsls	r2, r2, #0x1d
	it	cs
	stmiacs	r1!, {r4, r5}
	it	mi
	strmi	r3, [r1, #0]
	bx	lr

@ ----------------------------------------------------------------------------
@ format_one_conversion - printf-style conversion dispatcher.
@ r0=format context, r1=conversion character, r2=pointer to argument slot. The
@ function's own code is the dispatcher 08007238..080072c7 plus the small cases at
@ 080074f8..0800751f, 08007592..080075af, 080080d6..080080ef, 080082a8..080082b3 and
@ 08008430..08008447; all other work is in split-off functions entered by branches.
@ Dispatch (cmp r1 / beq): 'n' 0x6e beq.w 080074f8 (08007238); 'p' 0x70 beq.w
@ 0800759e (0800723e); 'f' 0x66, 'e' 0x65, 'g' 0x67 beq.w 0804615c at 08007246,
@ 0800724a and 08007250 (b.w 08007b20 at 0804615c); 'a' 0x61 beq.w 08046160 at
@ 08007258 (b.w 08007d8c at 08046160); then r1 is or-ed with 0x80 when bit 7 of the
@ flag word [r0] is set (lsrs #8 / orrcs at 0800725e..08007262); 'i' 0x69, 'd' 0x64,
@ 'u' 0x75 beq.w 08007480 at 08007268, 0800726e, 08007274; 'o' 0x6f beq.w 08008290
@ at 0800727a; 'x' 0x78 beq.w 08007576 at 08007280; 0xe9, 0xe4, 0xf5 (64-bit 'i',
@ 'd','u') beq.w 080081d0 at 08007286, 0800728c, 08007292; 0xef (64-bit 'o') beq.w
@ 080082a8 at 08007298; 0xf8 (64-bit 'x') beq.w 08007592 at 0800729e; then r1 is
@ or-ed with 0x80 when bit 6 of [r0] is set (080072a2..080072a8); 'c' 0x63 beq.w
@ 080080d6 at 080072ae; 's' 0x73 beq.w 080080e6 at 080072b4; 0xe3 (wide 'c') beq.w
@ 08008430 at 080072ba; 0xf3 (wide 's') beq.w 08008440 at 080072c0; any other
@ character returns 0 (movs r0,#0; bx lr at 080072c4/080072c6).
@ Own cases: 'n' (080074f8) stores the output count [r0+0x20] through the pointer
@ [r2] as a byte when flag bit 10 is set, a halfword when bit 8 is set, a
@ sign-extended 64-bit value when bit 7 is set, else a word, and returns 1
@ (080074fc..0800751e); 'p' (0800759e) sets flag bit 5 of [r0], [r0+0x1c]=8,
@ r2=[r2], r3=0 and branches b.n 08007520 (080075ae); 0xf8 (08007592) aligns r2 up
@ to 8, loads r2:r3 from it and branches b.n 08007520 (0800759c); 0xef (080082a8)
@ does the same and branches b.n 0800824c (080082b2); 'c' (080080d6) stores the byte
@ [r2] at [r0+0x24], a NUL at +0x25, r2=1 and branches b.n 080080c2 (080080e4); 's'
@ (080080e6) r1=[r2], r2=-1, b.n 080080c2 (080080ec); wide 'c' (08008430) stores the
@ halfword [r2] at [r0+0x24], halfword 0 at +0x26, r2=1, b.n 0800841c (0800843e);
@ wide 's' (08008440) r1=[r2], r2=-1, b.n 0800841c (08008446).
@ Split-off functions (entry: what it does): 08007480 'i','d','u' 32-bit: value from
@ 0800789a (signed) or 080078ac ('u'), sign prefix from the table at 080074e8,
@ decimal digits by udiv 10 into [r0+0x24+n], ends b.w 080078be (080074e4);
@ 08007b20 'e','f','g': reads an 8-byte aligned double, calls 080437d8, 0800839c,
@ 08007970, 080073e0, 0800740c, returns 3 (08007d86, b.n 08007a10 at 08007d8a);
@ 08007d8c 'a': calls 080437d8, 0800839c, 080073e0, 0800740c, returns 3 (08008064,
@ ldmia pc at 08008066); 080081d0 64-bit decimal: prefix table at 0800823c, digits
@ by 08008310, ends b.w 080078be (08008238); 0800824c octal digits (and #7, lsr #3),
@ ends b.w 080078be (0800828c); 08008290 'o': value via 080078ac then b.n 0800824c
@ (080082a6); 080080c2 and 0800841c: when [r0+0x14] is zero call 0800742e / 08008114
@ respectively, return 1; 08007576 'x': value via 080078ac then b.n 08007520
@ (08007590), where format_hex_u64 produces hex digits from the strings
@ '0123456789abcdef@0x' / '0123456789ABCDEF@0X' and ends b.w 080078be (0800756c);
@ 080078be (reached from 080074e4, 08008238, 0800828c, 0800756c) emits characters
@ through the callback at [r0+4] with argument [r0+8], pads via 080073e0 and
@ 0800740c and returns 1 or 2 (08007966/0800796c), count in [r0+0x20].
@ ----------------------------------------------------------------------------
	.section .text.format_one_conversion,"ax",%progbits
	.global format_one_conversion
	.thumb_func
	.type format_one_conversion, %function
format_one_conversion:
	cmp	r1, #0x6e
	beq.w	L_080074f8
	cmp	r1, #0x70
	beq.w	L_0800759e
	cmp	r1, #0x66
	beq.w	L_0804615c
	cmp	r1, #0x65
	beq.w	L_0804615c
	cmp	r1, #0x67
	beq.w	L_0804615c
	cmp	r1, #0x61
	beq.w	L_08046160
	ldr	r3, [r0, #0]
	lsrs	r3, r3, #8
	it	cs
	orrcs.w	r1, r1, #0x80
	cmp	r1, #0x69
	beq.w	format_decimal_32
	cmp	r1, #0x64
	beq.w	format_decimal_32
	cmp	r1, #0x75
	beq.w	format_decimal_32
	cmp	r1, #0x6f
	beq.w	format_octal_32
	cmp	r1, #0x78
	beq.w	format_hex_u32
	cmp	r1, #0xe9
	beq.w	format_decimal_64
	cmp	r1, #0xe4
	beq.w	format_decimal_64
	cmp	r1, #0xf5
	beq.w	format_decimal_64
	cmp	r1, #0xef
	beq.w	L_080082a8
	cmp	r1, #0xf8
	beq.w	L_08007592
	ldr	r3, [r0, #0]
	lsrs	r3, r3, #7
	it	cs
	orrcs.w	r1, r1, #0x80
	cmp	r1, #0x63
	beq.w	L_080080d6
	cmp	r1, #0x73
	beq.w	L_080080e6
	cmp	r1, #0xe3
	beq.w	L_08008430
	cmp	r1, #0xf3
	beq.w	L_08008440
	movs	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_080072c8 - calls fpscr_set_fz_dn_round_nearest (08045f06), then writes
@ (result of fn_08044f04(0,0))+1 to [0x20001264] and the result of
@ fn_08044ed8(0,0) to [0x2000126c] (base from fn_08008300 = 0x20001260); r0 and
@ r1 are returned unchanged (saved on the stack and restored).
@ ----------------------------------------------------------------------------
	.section .text.fn_080072c8,"ax",%progbits
	.global fn_080072c8
	.thumb_func
	.type fn_080072c8, %function
fn_080072c8:
	push	{r0, r1, r2, r3, r4, lr}
	bl	fpscr_set_fz_dn_round_nearest
	bl	fn_08008300
	movs	r4, r0
	movs	r0, #0
	movs	r1, #0
	bl	fn_08044f04
	.inst.n	0x1c40	@ adds r0, r0, #1
	str	r0, [r4, #4]
	movs	r0, #0
	movs	r1, #0
	bl	fn_08044ed8
	str	r0, [r4, #0xc]
	pop	{r0, r1, r2, r3, r4, pc}

@ ----------------------------------------------------------------------------
@ nop_return_080072ec - pushes r4 and lr (push {r4, lr} at 0x080072ec) and pops
@ them back into r4 and pc (pop {r4, pc} at 0x080072ee): returns with no other
@ effect.
@ ----------------------------------------------------------------------------
	.section .text.nop_return_080072ec,"ax",%progbits
	.global nop_return_080072ec
	.thumb_func
	.type nop_return_080072ec, %function
nop_return_080072ec:
	push	{r4, lr}
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_080072f0 - (group 6, one section with fn_08007302, Reset_Handler, the idle
@ loops and fn_08007348.)
@ Body 080072f0..08007301 (18 bytes): bl fn_080085d4 (080072f0), mov r1,r2
@ (080072f4), bl fn_080072c8 (080072f6), bl init_system_clock (080072fa), bl
@ fn_08008630 (080072fe, sets lr=08007302). fn_08008630 pushes r4,lr, copies r0
@ to r4 and back, pops r4,lr and does b.w 08007302 (0800863e), so execution
@ continues in the split-off function fn_08007302 (push {r0,r1}, bl
@ nop_return_080072ec, pop {r0,r1}, nop.w, halfword 0x0000 at 0800730e), which has
@ no branch at its end and runs on into 08007310. This function itself has no
@ branch or return after 080072fe; it ends at 08007301 and the code at 08007302
@ is fn_08007302, not part of this body. The 08033f7d / 0802a9c5 / 08007185
@ sequence at 08007310 belongs to the function at 08007310.
@ ----------------------------------------------------------------------------
	.section .text.fn_080072f0,"ax",%progbits
	.p2align 2
	.global fn_080072f0
	.thumb_func
	.type fn_080072f0, %function
fn_080072f0:
	bl	fn_080085d4
	mov	r1, r2
	bl	fn_080072c8
	bl	init_system_clock
	bl	fn_08008630

@ ----------------------------------------------------------------------------
@ fn_08007302 - code piece after the bl fn_08008630 at 080072fe in fn_080072f0:
@ push {r0,r1} (08007302), bl nop_return_080072ec (push {r4,lr}; pop {r4,pc}:
@ does nothing), pop {r0,r1} (08007308), nop.w (0800730a), halfword 0x0000 =
@ movs r0,r0 at 0800730e (sets N/Z from r0, nothing else), then runs on without a
@ branch into Reset_Handler at 08007310 (movw/movt sp=0x20001000, blx
@ [08007354]=0x08033f7d, sp=[0x08000000] via ldr.w at 08007326, blx
@ [08007358]=0x0802a9c5, bx [0800735c]=0x08007185).
@ Entered from fn_08008630 by b.w at 0800863e (08008630 does push {r4,lr}, mov
@ r4,r0, nop.w, mov r0,r4, pop.w {r4,lr}), and from fn_080072f0 whose bl
@ fn_08008630 at 080072fe sets lr=08007302. Expects on entry: r0 and r1 any value
@ (saved and restored by push/pop), stack balanced, no flag or other register
@ requirement (Reset_Handler reloads sp at 08007318). Purpose: re-enters the
@ Reset_Handler start-up sequence after the calls of fn_080072f0 (flow proven by
@ the fall-through into 08007310).
@ ----------------------------------------------------------------------------
	.global fn_08007302
	.thumb_func
	.type fn_08007302, %function
fn_08007302:
	push	{r0, r1}
	bl	nop_return_080072ec
	pop	{r0, r1}
	nop.w
	movs	r0, r0

@ ----------------------------------------------------------------------------
@ Reset_Handler - reset vector body (word at 0x08007004 is 0x08007311).
@ sp=0x20001000 (movw/movt at 08007310/08007314, mov sp,r0), blx 0x08033f7d
@ (literal at 08007354), sp=[0x08000000] (ldr.w sp,[r0] at 08007326), blx
@ 0x0802a9c5 (literal at 08007358), then bx 0x08007185 (literal at 0800735c): a
@ branch to 08007184, not a call.
@ ----------------------------------------------------------------------------
	.global Reset_Handler
	.thumb_func
	.type Reset_Handler, %function
Reset_Handler:
	movw	r0, #0x1000
	movt	r0, #0x2000
	mov	sp, r0
	ldr	r0, .L08007354
	blx	r0
	movw	r0, #0x0
	movt	r0, #0x800
	ldr.w	sp, [r0, #0]
	ldr	r0, .L08007358
	blx	r0
	ldr	r0, .L0800735c
	bx	r0

@ ----------------------------------------------------------------------------
@ halt_loop_08007332 - infinite loop (branch to itself); never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_08007332
	.thumb_func
	.type halt_loop_08007332, %function
halt_loop_08007332:
	b.n	halt_loop_08007332

@ ----------------------------------------------------------------------------
@ halt_loop_08007334 - infinite loop (branch to itself); never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_08007334
	.thumb_func
	.type halt_loop_08007334, %function
halt_loop_08007334:
	b.n	halt_loop_08007334

@ ----------------------------------------------------------------------------
@ halt_loop_08007336 - infinite loop (branch to itself); never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_08007336
	.thumb_func
	.type halt_loop_08007336, %function
halt_loop_08007336:
	b.n	halt_loop_08007336

@ ----------------------------------------------------------------------------
@ halt_loop_08007338 - infinite loop (branch to itself); never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_08007338
	.thumb_func
	.type halt_loop_08007338, %function
halt_loop_08007338:
	b.n	halt_loop_08007338

@ ----------------------------------------------------------------------------
@ halt_loop_0800733a - infinite loop (branch to itself); never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_0800733a
	.thumb_func
	.type halt_loop_0800733a, %function
halt_loop_0800733a:
	b.n	halt_loop_0800733a

@ ----------------------------------------------------------------------------
@ halt_loop_0800733c - infinite loop (branch to itself); never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_0800733c
	.thumb_func
	.type halt_loop_0800733c, %function
halt_loop_0800733c:
	b.n	halt_loop_0800733c

@ ----------------------------------------------------------------------------
@ halt_loop_0800733e - infinite loop (branch to itself); never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_0800733e
	.thumb_func
	.type halt_loop_0800733e, %function
halt_loop_0800733e:
	b.n	halt_loop_0800733e

@ ----------------------------------------------------------------------------
@ halt_loop_08007340 - infinite loop (branch to itself); never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_08007340
	.thumb_func
	.type halt_loop_08007340, %function
halt_loop_08007340:
	b.n	halt_loop_08007340

@ ----------------------------------------------------------------------------
@ halt_loop_08007342 - infinite loop (branch to itself); never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_08007342
	.thumb_func
	.type halt_loop_08007342, %function
halt_loop_08007342:
	b.n	halt_loop_08007342

@ ----------------------------------------------------------------------------
@ halt_loop_08007344 - infinite loop (branch to itself); never returns. The 2
@ padding bytes after it are never reached and align fn_08007348.
@ ----------------------------------------------------------------------------
	.global halt_loop_08007344
	.thumb_func
	.type halt_loop_08007344, %function
halt_loop_08007344:
	b.n	halt_loop_08007344
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08007348 - sets r0=0x20036b90, r1=0x20036f90, r2=0x20036b90 and
@ r3=0x20036b90 from literals and returns (bx lr). Followed by the literal pool
@ of Reset_Handler: 0x08033f7d (fn_08033f7c), 0x0802a9c5 (fn_0802a9c4),
@ 0x08007185 (fn_08007184) and the three RAM addresses loaded above.
@ ----------------------------------------------------------------------------
	.global fn_08007348
	.thumb_func
	.type fn_08007348, %function
fn_08007348:
	ldr	r0, .L08007360
	ldr	r1, .L08007364
	ldr	r2, .L08007360
	ldr	r3, .L08007368
	bx	lr
	.short	0x0000	@ padding
.L08007354:
	.word	fn_08033f7c
.L08007358:
	.word	fn_0802a9c4
.L0800735c:
	.word	fn_08007184
.L08007360:
	.word	0x20036b90
.L08007364:
	.word	0x20036f90
.L08007368:
	.word	0x20036b90

@ ----------------------------------------------------------------------------
@ nop_return_0800736c - returns immediately; no flow or pointer reaches this
@ address. The 2 padding bytes after it are never reached.
@ ----------------------------------------------------------------------------
	.section .text.nop_return_0800736c,"ax",%progbits
	.global nop_return_0800736c
	.thumb_func
	.type nop_return_0800736c, %function
nop_return_0800736c:
	bx	lr
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ halt_loop_080092d8 - infinite loop (branch to itself); never returns. The 2
@ padding bytes after it are never reached.
@ ----------------------------------------------------------------------------
	.section .text.halt_loop_080092d8,"ax",%progbits
	.global halt_loop_080092d8
	.thumb_func
	.type halt_loop_080092d8, %function
halt_loop_080092d8:
	b.n	halt_loop_080092d8
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ nop_return_080097e4 - returns immediately; no instructions besides the return.
@ The 2 padding bytes after it are never reached.
@ ----------------------------------------------------------------------------
	.section .text.nop_return_080097e4,"ax",%progbits
	.global nop_return_080097e4
	.thumb_func
	.type nop_return_080097e4, %function
nop_return_080097e4:
	bx	lr
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ halt_loop_0800fd34 - infinite loop (branch to itself); never returns. The 2
@ padding bytes after it are never reached.
@ ----------------------------------------------------------------------------
	.section .text.halt_loop_0800fd34,"ax",%progbits
	.global halt_loop_0800fd34
	.thumb_func
	.type halt_loop_0800fd34, %function
halt_loop_0800fd34:
	b.n	halt_loop_0800fd34
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ halt_forever_0802f310 - no parameters; a single b.n branching to itself at
@ 0x0802f310, never returns. The 2 padding bytes after it are never reached.
@ ----------------------------------------------------------------------------
	.section .text.halt_forever_0802f310,"ax",%progbits
	.global halt_forever_0802f310
	.thumb_func
	.type halt_forever_0802f310, %function
halt_forever_0802f310:
	b.n	halt_forever_0802f310
	.short	0x0000	@ padding
