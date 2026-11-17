@ find_directory_entry_by_name_p2.inc - FAT directory search: find_directory_entry_by_name
@ (part 2 of 2, bytes 0x08032664..0x08032de4; a fragment included by
@ filesystem_03.s, it continues the instructions of part 1 inside the same section).
@
@ What this part does (see the header of find_directory_entry_by_name in
@ filesystem_03.s for the whole function):
@ - It finishes the case-folding lookup of the long-name entry character at
@   offset 0x14 (the lookup loop in the range tables 0x080be118 / 0x080be05c:
@   walk the table records, then apply the operation selected by the record's
@   high byte through a tbb jump table: table lookup, alternate step, -0x10,
@   -0x20, -0x30, -0x1a, +8, -0x50, -0x1c60).
@ - It then repeats the same fold-and-compare for the search-name character
@   and the entry character at offsets 0x16, 0x18, 0x1c and 0x1e. Each step
@   reads the UTF-16 entry character (r12 = lo | hi << 8), folds it and the
@   search-name character ldrh [ctx[3] + 2 * r11], and compares them. A
@   mismatch jumps to 0x08032daa. A zero entry character is followed only by
@   0xffff characters; r11 counts the search-name characters (limit 0xff).
@ - 0x08032d80..0x08032da8 checks the last character (offset 0x1e): a match
@   with a nonzero entry character, first-byte bit 0x40 set ([sp,#4] & 0x40)
@   and a nonzero next search-name character counts as a mismatch; otherwise
@   0x08032d9a decrements the expected sequence (r6).
@ - 0x08032daa sets the expected sequence to 0xff; 0x08032dac loads
@   r5 = 0x000fffff and returns to the entry loop at 0x080317c2.
@ - 0x08032db8, 0x08032dc4, 0x08032dd4 and 0x08032ddc are the exit paths:
@   0x08032db8 clears param_1[6] and returns 4 (end of directory);
@   0x08032dc4 stores 0xffffffff in ctx[0x30] and returns 1 (read error);
@   0x08032dd4 returns 0 (found); 0x08032ddc returns 2 (chain entry < 2).
@   Every exit pops {r4-r11, pc} after releasing the 0x1c-byte frame.

@ ---- fold of the entry character, offset 0x14 (continued): tail of the table walk
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L08032642
.L08032674:
	cmp	r3, #0x8
	bhi.n	.L080326c6
	tbb	[pc, r3]
.L0803267c:
	.byte	(.L08032686 - .L0803267c)/2
	.byte	(.L08032690 - .L0803267c)/2
	.byte	(.L0803269e - .L0803267c)/2
	.byte	(.L080326a4 - .L0803267c)/2
	.byte	(.L080326aa - .L0803267c)/2
	.byte	(.L080326b0 - .L0803267c)/2
	.byte	(.L080326b6 - .L0803267c)/2
	.byte	(.L080326bc - .L0803267c)/2
	.byte	(.L080326c2 - .L0803267c)/2
	.byte	0x00	@ padding
.L08032686:
	sub.w	r1, lr, r5
	ldrh.w	r12, [r7, r1, lsl #0x1]
	b.n	.L080326c6
.L08032690:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r12, r12, r1
	b.n	.L080326c6
.L0803269e:
	sub.w	r12, r12, #0x10
	b.n	.L080326c6
.L080326a4:
	sub.w	r12, r12, #0x20
	b.n	.L080326c6
.L080326aa:
	sub.w	r12, r12, #0x30
	b.n	.L080326c6
.L080326b0:
	sub.w	r12, r12, #0x1a
	b.n	.L080326c6
.L080326b6:
	add.w	r12, r12, #0x8
	b.n	.L080326c6
.L080326bc:
	sub.w	r12, r12, #0x50
	b.n	.L080326c6
.L080326c2:
	sub.w	r12, r12, #0x1c60

@ ---- fold of the search-name character ldrh [ctx[3] + 2*r11] (offset 0x14 compare)
.L080326c6:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	r9, [r1, r11, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L080326e6:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r9
	bcs.n	.L0803276a
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, r9
	lsr.w	r3, r1, #0x8
	bhi.n	.L08032718
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L080326e6
.L08032718:
	cmp	r3, #0x8
	bhi.n	.L0803276a
	tbb	[pc, r3]
.L08032720:
	.byte	(.L0803272a - .L08032720)/2
	.byte	(.L08032734 - .L08032720)/2
	.byte	(.L08032742 - .L08032720)/2
	.byte	(.L08032748 - .L08032720)/2
	.byte	(.L0803274e - .L08032720)/2
	.byte	(.L08032754 - .L08032720)/2
	.byte	(.L0803275a - .L08032720)/2
	.byte	(.L08032760 - .L08032720)/2
	.byte	(.L08032766 - .L08032720)/2
	.byte	0x00	@ padding
.L0803272a:
	sub.w	r1, r9, r5
	ldrh.w	r9, [r7, r1, lsl #0x1]
	b.n	.L0803276a
.L08032734:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r9, r9, r1
	b.n	.L0803276a
.L08032742:
	sub.w	r9, r9, #0x10
	b.n	.L0803276a
.L08032748:
	sub.w	r9, r9, #0x20
	b.n	.L0803276a
.L0803274e:
	sub.w	r9, r9, #0x30
	b.n	.L0803276a
.L08032754:
	sub.w	r9, r9, #0x1a
	b.n	.L0803276a
.L0803275a:
	add.w	r9, r9, #0x8
	b.n	.L0803276a
.L08032760:
	sub.w	r9, r9, #0x50
	b.n	.L0803276a
.L08032766:
	sub.w	r9, r9, #0x1c60

@ ---- compare the folded characters; on a match go on with entry offset 0x16
.L0803276a:
	uxth.w	r1, r9
	uxth.w	r2, r12
	cmp	r2, r1
	bne.w	.L08032daa
	clz	r1, lr
	add.w	r11, r11, #0x1
	lsrs	r2, r1, #0x5
.L08032782:
	ldrb.w	r9, [r0, #0x16]
	ldrb	r1, [r0, #0x17]
	orr.w	r12, r9, r1, lsl #0x8
	cbz	r2, .L080327a0
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L08032daa
	movs	r2, #0x1
	b.n	.L08032906

@ ---- fold of the entry character, offset 0x16 (r12 -> lr)
.L080327a0:
	cmp.w	r11, #0xff
	bhi.w	.L08032daa
	movw	r3, #:lower16:d_080be05c
	uxth.w	lr, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L080327c6:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.n	.L0803284a
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L080327f8
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L080327c6
.L080327f8:
	cmp	r3, #0x8
	bhi.n	.L0803284a
	tbb	[pc, r3]
.L08032800:
	.byte	(.L0803280a - .L08032800)/2
	.byte	(.L08032814 - .L08032800)/2
	.byte	(.L08032822 - .L08032800)/2
	.byte	(.L08032828 - .L08032800)/2
	.byte	(.L0803282e - .L08032800)/2
	.byte	(.L08032834 - .L08032800)/2
	.byte	(.L0803283a - .L08032800)/2
	.byte	(.L08032840 - .L08032800)/2
	.byte	(.L08032846 - .L08032800)/2
	.byte	0x00	@ padding
.L0803280a:
	sub.w	r1, lr, r5
	ldrh.w	r12, [r7, r1, lsl #0x1]
	b.n	.L0803284a
.L08032814:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r12, r12, r1
	b.n	.L0803284a
.L08032822:
	sub.w	r12, r12, #0x10
	b.n	.L0803284a
.L08032828:
	sub.w	r12, r12, #0x20
	b.n	.L0803284a
.L0803282e:
	sub.w	r12, r12, #0x30
	b.n	.L0803284a
.L08032834:
	sub.w	r12, r12, #0x1a
	b.n	.L0803284a
.L0803283a:
	add.w	r12, r12, #0x8
	b.n	.L0803284a
.L08032840:
	sub.w	r12, r12, #0x50
	b.n	.L0803284a
.L08032846:
	sub.w	r12, r12, #0x1c60

@ ---- fold of the search-name character (offset 0x16 compare)
.L0803284a:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	r9, [r1, r11, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L0803286a:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r9
	bcs.n	.L080328ee
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, r9
	lsr.w	r3, r1, #0x8
	bhi.n	.L0803289c
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L0803286a
.L0803289c:
	cmp	r3, #0x8
	bhi.n	.L080328ee
	tbb	[pc, r3]
.L080328a4:
	.byte	(.L080328ae - .L080328a4)/2
	.byte	(.L080328b8 - .L080328a4)/2
	.byte	(.L080328c6 - .L080328a4)/2
	.byte	(.L080328cc - .L080328a4)/2
	.byte	(.L080328d2 - .L080328a4)/2
	.byte	(.L080328d8 - .L080328a4)/2
	.byte	(.L080328de - .L080328a4)/2
	.byte	(.L080328e4 - .L080328a4)/2
	.byte	(.L080328ea - .L080328a4)/2
	.byte	0x00	@ padding
.L080328ae:
	sub.w	r1, r9, r5
	ldrh.w	r9, [r7, r1, lsl #0x1]
	b.n	.L080328ee
.L080328b8:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r9, r9, r1
	b.n	.L080328ee
.L080328c6:
	sub.w	r9, r9, #0x10
	b.n	.L080328ee
.L080328cc:
	sub.w	r9, r9, #0x20
	b.n	.L080328ee
.L080328d2:
	sub.w	r9, r9, #0x30
	b.n	.L080328ee
.L080328d8:
	sub.w	r9, r9, #0x1a
	b.n	.L080328ee
.L080328de:
	add.w	r9, r9, #0x8
	b.n	.L080328ee
.L080328e4:
	sub.w	r9, r9, #0x50
	b.n	.L080328ee
.L080328ea:
	sub.w	r9, r9, #0x1c60

@ ---- compare the folded characters; on a match go on with entry offset 0x18
.L080328ee:
	uxth.w	r1, r9
	uxth.w	r2, r12
	cmp	r2, r1
	bne.w	.L08032daa
	clz	r1, lr
	add.w	r11, r11, #0x1
	lsrs	r2, r1, #0x5
.L08032906:
	ldrb.w	r9, [r0, #0x18]
	ldrb	r1, [r0, #0x19]
	orr.w	r12, r9, r1, lsl #0x8
	cbz	r2, .L08032924
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L08032daa
	movs	r2, #0x1
	b.n	.L08032a8a

@ ---- fold of the entry character, offset 0x18 (r12 -> lr)
.L08032924:
	cmp.w	r11, #0xff
	bhi.w	.L08032daa
	movw	r3, #:lower16:d_080be05c
	uxth.w	lr, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L0803294a:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.n	.L080329ce
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L0803297c
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L0803294a
.L0803297c:
	cmp	r3, #0x8
	bhi.n	.L080329ce
	tbb	[pc, r3]
.L08032984:
	.byte	(.L0803298e - .L08032984)/2
	.byte	(.L08032998 - .L08032984)/2
	.byte	(.L080329a6 - .L08032984)/2
	.byte	(.L080329ac - .L08032984)/2
	.byte	(.L080329b2 - .L08032984)/2
	.byte	(.L080329b8 - .L08032984)/2
	.byte	(.L080329be - .L08032984)/2
	.byte	(.L080329c4 - .L08032984)/2
	.byte	(.L080329ca - .L08032984)/2
	.byte	0x00	@ padding
.L0803298e:
	sub.w	r1, lr, r5
	ldrh.w	r12, [r7, r1, lsl #0x1]
	b.n	.L080329ce
.L08032998:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r12, r12, r1
	b.n	.L080329ce
.L080329a6:
	sub.w	r12, r12, #0x10
	b.n	.L080329ce
.L080329ac:
	sub.w	r12, r12, #0x20
	b.n	.L080329ce
.L080329b2:
	sub.w	r12, r12, #0x30
	b.n	.L080329ce
.L080329b8:
	sub.w	r12, r12, #0x1a
	b.n	.L080329ce
.L080329be:
	add.w	r12, r12, #0x8
	b.n	.L080329ce
.L080329c4:
	sub.w	r12, r12, #0x50
	b.n	.L080329ce
.L080329ca:
	sub.w	r12, r12, #0x1c60

@ ---- fold of the search-name character (offset 0x18 compare)
.L080329ce:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	r9, [r1, r11, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L080329ee:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r9
	bcs.n	.L08032a72
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, r9
	lsr.w	r3, r1, #0x8
	bhi.n	.L08032a20
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L080329ee
.L08032a20:
	cmp	r3, #0x8
	bhi.n	.L08032a72
	tbb	[pc, r3]
.L08032a28:
	.byte	(.L08032a32 - .L08032a28)/2
	.byte	(.L08032a3c - .L08032a28)/2
	.byte	(.L08032a4a - .L08032a28)/2
	.byte	(.L08032a50 - .L08032a28)/2
	.byte	(.L08032a56 - .L08032a28)/2
	.byte	(.L08032a5c - .L08032a28)/2
	.byte	(.L08032a62 - .L08032a28)/2
	.byte	(.L08032a68 - .L08032a28)/2
	.byte	(.L08032a6e - .L08032a28)/2
	.byte	0x00	@ padding
.L08032a32:
	sub.w	r1, r9, r5
	ldrh.w	r9, [r7, r1, lsl #0x1]
	b.n	.L08032a72
.L08032a3c:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r9, r9, r1
	b.n	.L08032a72
.L08032a4a:
	sub.w	r9, r9, #0x10
	b.n	.L08032a72
.L08032a50:
	sub.w	r9, r9, #0x20
	b.n	.L08032a72
.L08032a56:
	sub.w	r9, r9, #0x30
	b.n	.L08032a72
.L08032a5c:
	sub.w	r9, r9, #0x1a
	b.n	.L08032a72
.L08032a62:
	add.w	r9, r9, #0x8
	b.n	.L08032a72
.L08032a68:
	sub.w	r9, r9, #0x50
	b.n	.L08032a72
.L08032a6e:
	sub.w	r9, r9, #0x1c60

@ ---- compare the folded characters; on a match go on with entry offset 0x1c
.L08032a72:
	uxth.w	r1, r9
	uxth.w	r2, r12
	cmp	r2, r1
	bne.w	.L08032daa
	clz	r1, lr
	add.w	r11, r11, #0x1
	lsrs	r2, r1, #0x5
.L08032a8a:
	ldrb.w	r9, [r0, #0x1c]
	ldrb	r1, [r0, #0x1d]
	orr.w	r12, r9, r1, lsl #0x8
	cbz	r2, .L08032aa8
	uxth.w	r1, r12
	movw	r2, #0xffff
	cmp	r1, r2
	bne.w	.L08032daa
	movs	r2, #0x1
	b.n	.L08032c0e

@ ---- fold of the entry character, offset 0x1c (r12 -> lr)
.L08032aa8:
	cmp.w	r11, #0xff
	bhi.w	.L08032daa
	movw	r3, #:lower16:d_080be05c
	uxth.w	lr, r12
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	lr, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L08032ace:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, lr
	bcs.n	.L08032b52
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, lr
	lsr.w	r3, r1, #0x8
	bhi.n	.L08032b00
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L08032ace
.L08032b00:
	cmp	r3, #0x8
	bhi.n	.L08032b52
	tbb	[pc, r3]
.L08032b08:
	.byte	(.L08032b12 - .L08032b08)/2
	.byte	(.L08032b1c - .L08032b08)/2
	.byte	(.L08032b2a - .L08032b08)/2
	.byte	(.L08032b30 - .L08032b08)/2
	.byte	(.L08032b36 - .L08032b08)/2
	.byte	(.L08032b3c - .L08032b08)/2
	.byte	(.L08032b42 - .L08032b08)/2
	.byte	(.L08032b48 - .L08032b08)/2
	.byte	(.L08032b4e - .L08032b08)/2
	.byte	0x00	@ padding
.L08032b12:
	sub.w	r1, lr, r5
	ldrh.w	r12, [r7, r1, lsl #0x1]
	b.n	.L08032b52
.L08032b1c:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r12, r12, r1
	b.n	.L08032b52
.L08032b2a:
	sub.w	r12, r12, #0x10
	b.n	.L08032b52
.L08032b30:
	sub.w	r12, r12, #0x20
	b.n	.L08032b52
.L08032b36:
	sub.w	r12, r12, #0x30
	b.n	.L08032b52
.L08032b3c:
	sub.w	r12, r12, #0x1a
	b.n	.L08032b52
.L08032b42:
	add.w	r12, r12, #0x8
	b.n	.L08032b52
.L08032b48:
	sub.w	r12, r12, #0x50
	b.n	.L08032b52
.L08032b4e:
	sub.w	r12, r12, #0x1c60

@ ---- fold of the search-name character (offset 0x1c compare)
.L08032b52:
	ldr	r1, [sp, #0xc]
	movw	r3, #:lower16:d_080be05c
	ldrh.w	r9, [r1, r11, lsl #0x1]
	movt	r3, #:upper16:d_080be05c
	movw	r1, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r1, #:upper16:d_080be118
	it	cc
	movcc	r3, r1
	ldrh	r2, [r3, #0x0]
.L08032b72:
	subs	r1, r2, #0x1
	uxth	r1, r1
	cmp	r1, r9
	bcs.n	.L08032bf6
	ldrh	r1, [r3, #0x2]
	uxth	r5, r2
	adds	r7, r3, #0x4
	uxtab	r3, r5, r1
	cmp	r3, r9
	lsr.w	r3, r1, #0x8
	bhi.n	.L08032ba4
	movs	r2, #0x0
	uxtb	r1, r1
	cmp	r3, #0x0
	it	eq
	moveq	r2, r1
	mov	r3, r7
	ldrh.w	r2, [r7, r2, lsl #0x1]
	it	eq
	addeq.w	r3, r3, r1, lsl #0x1
	b.n	.L08032b72
.L08032ba4:
	cmp	r3, #0x8
	bhi.n	.L08032bf6
	tbb	[pc, r3]
.L08032bac:
	.byte	(.L08032bb6 - .L08032bac)/2
	.byte	(.L08032bc0 - .L08032bac)/2
	.byte	(.L08032bce - .L08032bac)/2
	.byte	(.L08032bd4 - .L08032bac)/2
	.byte	(.L08032bda - .L08032bac)/2
	.byte	(.L08032be0 - .L08032bac)/2
	.byte	(.L08032be6 - .L08032bac)/2
	.byte	(.L08032bec - .L08032bac)/2
	.byte	(.L08032bf2 - .L08032bac)/2
	.byte	0x00	@ padding
.L08032bb6:
	sub.w	r1, r9, r5
	ldrh.w	r9, [r7, r1, lsl #0x1]
	b.n	.L08032bf6
.L08032bc0:
	sub.w	r1, r9, r2
	and	r1, r1, #0x1
	sub.w	r9, r9, r1
	b.n	.L08032bf6
.L08032bce:
	sub.w	r9, r9, #0x10
	b.n	.L08032bf6
.L08032bd4:
	sub.w	r9, r9, #0x20
	b.n	.L08032bf6
.L08032bda:
	sub.w	r9, r9, #0x30
	b.n	.L08032bf6
.L08032be0:
	sub.w	r9, r9, #0x1a
	b.n	.L08032bf6
.L08032be6:
	add.w	r9, r9, #0x8
	b.n	.L08032bf6
.L08032bec:
	sub.w	r9, r9, #0x50
	b.n	.L08032bf6
.L08032bf2:
	sub.w	r9, r9, #0x1c60

@ ---- compare the folded characters; on a match go on with entry offset 0x1e
@ (this last character reuses r0 for the entry halfword and r2/r0/r7 for the lookup)
.L08032bf6:
	uxth.w	r1, r9
	uxth.w	r2, r12
	cmp	r2, r1
	bne.w	.L08032daa
	clz	r1, lr
	add.w	r11, r11, #0x1
	lsrs	r2, r1, #0x5
.L08032c0e:
	ldrb.w	r9, [r0, #0x1e]
	ldrb	r0, [r0, #0x1f]
	orr.w	r12, r9, r0, lsl #0x8
	cbz	r2, .L08032c2a
	uxth.w	r0, r12
	movw	r1, #0xffff
	cmp	r0, r1
	bne.w	.L08032daa
	b.n	.L08032d9a

@ ---- fold of the entry character, offset 0x1e (r12 stays, folded value -> lr)
.L08032c2a:
	cmp.w	r11, #0xff
	bhi.w	.L08032daa
	movw	r2, #:lower16:d_080be05c
	uxth.w	r3, r12
	movt	r2, #:upper16:d_080be05c
	movw	r0, #:lower16:d_080be118
	cmp.w	r3, #0x1000
	movt	r0, #:upper16:d_080be118
	it	cc
	movcc	r2, r0
	ldrh	r7, [r2, #0x0]
.L08032c50:
	subs	r0, r7, #0x1
	uxth	r0, r0
	cmp	r0, r3
	bcs.n	.L08032c82
	ldrh	r1, [r2, #0x2]
	uxth	r5, r7
	adds	r0, r2, #0x4
	uxtab	r2, r5, r1
	cmp	r2, r3
	lsr.w	r2, r1, #0x8
	bhi.n	.L08032cda
	movs	r7, #0x0
	uxtb	r1, r1
	cmp	r2, #0x0
	it	eq
	moveq	r7, r1
	mov	r2, r0
	ldrh.w	r7, [r0, r7, lsl #0x1]
	it	eq
	addeq.w	r2, r2, r1, lsl #0x1
	b.n	.L08032c50
.L08032c82:
	mov	lr, r12

@ ---- fold of the search-name character (offset 0x1e compare)
.L08032c84:
	ldr	r0, [sp, #0xc]
	movw	r7, #:lower16:d_080be05c
	ldrh.w	r9, [r0, r11, lsl #0x1]
	movt	r7, #:upper16:d_080be05c
	movw	r0, #:lower16:d_080be118
	cmp.w	r9, #0x1000
	movt	r0, #:upper16:d_080be118
	it	cc
	movcc	r7, r0
	ldrh	r3, [r7, #0x0]
.L08032ca4:
	subs	r0, r3, #0x1
	uxth	r0, r0
	cmp	r0, r9
	bcs.w	.L08032d80
	ldrh	r1, [r7, #0x2]
	uxth	r5, r3
	uxtab	r2, r5, r1
	adds	r0, r7, #0x4
	cmp	r2, r9
	lsr.w	r2, r1, #0x8
	bhi.n	.L08032cf6
	cmp	r2, #0x0
	mov.w	r2, #0x0
	uxtb	r1, r1
	it	eq
	moveq	r2, r1
	mov	r7, r0
	ldrh.w	r3, [r0, r2, lsl #0x1]
	it	eq
	addeq.w	r7, r7, r1, lsl #0x1
	b.n	.L08032ca4
.L08032cda:
	cmp	r2, #0x8
	mov	lr, r12
	bhi.n	.L08032c84
	tbb	[pc, r2]
.L08032ce4:
	.byte	(.L08032cee - .L08032ce4)/2
	.byte	(.L08032d12 - .L08032ce4)/2
	.byte	(.L08032d20 - .L08032ce4)/2
	.byte	(.L08032d26 - .L08032ce4)/2
	.byte	(.L08032d2c - .L08032ce4)/2
	.byte	(.L08032d32 - .L08032ce4)/2
	.byte	(.L08032d38 - .L08032ce4)/2
	.byte	(.L08032d3e - .L08032ce4)/2
	.byte	(.L08032d44 - .L08032ce4)/2
	.byte	0x00	@ padding
.L08032cee:
	subs	r1, r3, r5
	ldrh.w	lr, [r0, r1, lsl #0x1]
	b.n	.L08032c84
.L08032cf6:
	cmp	r2, #0x8
	bhi.n	.L08032d80
	tbb	[pc, r2]
.L08032cfe:
	.byte	(.L08032d08 - .L08032cfe)/2
	.byte	(.L08032d4a - .L08032cfe)/2
	.byte	(.L08032d58 - .L08032cfe)/2
	.byte	(.L08032d5e - .L08032cfe)/2
	.byte	(.L08032d64 - .L08032cfe)/2
	.byte	(.L08032d6a - .L08032cfe)/2
	.byte	(.L08032d70 - .L08032cfe)/2
	.byte	(.L08032d76 - .L08032cfe)/2
	.byte	(.L08032d7c - .L08032cfe)/2
	.byte	0x00	@ padding
.L08032d08:
	sub.w	r1, r9, r5
	ldrh.w	r9, [r0, r1, lsl #0x1]
	b.n	.L08032d80
.L08032d12:
	sub.w	r0, r9, r7
	and	r0, r0, #0x1
	sub.w	lr, r12, r0
	b.n	.L08032c84
.L08032d20:
	sub.w	lr, r12, #0x10
	b.n	.L08032c84
.L08032d26:
	sub.w	lr, r12, #0x20
	b.n	.L08032c84
.L08032d2c:
	sub.w	lr, r12, #0x30
	b.n	.L08032c84
.L08032d32:
	sub.w	lr, r12, #0x1a
	b.n	.L08032c84
.L08032d38:
	add.w	lr, r12, #0x8
	b.n	.L08032c84
.L08032d3e:
	sub.w	lr, r12, #0x50
	b.n	.L08032c84
.L08032d44:
	sub.w	lr, r12, #0x1c60
	b.n	.L08032c84
.L08032d4a:
	sub.w	r0, r9, r3
	and	r0, r0, #0x1
	sub.w	r9, r9, r0
	b.n	.L08032d80
.L08032d58:
	sub.w	r9, r9, #0x10
	b.n	.L08032d80
.L08032d5e:
	sub.w	r9, r9, #0x20
	b.n	.L08032d80
.L08032d64:
	sub.w	r9, r9, #0x30
	b.n	.L08032d80
.L08032d6a:
	sub.w	r9, r9, #0x1a
	b.n	.L08032d80
.L08032d70:
	add.w	r9, r9, #0x8
	b.n	.L08032d80
.L08032d76:
	sub.w	r9, r9, #0x50
	b.n	.L08032d80
.L08032d7c:
	sub.w	r9, r9, #0x1c60

@ ---- compare the last character; a full match decrements the expected sequence
.L08032d80:
	uxth.w	r0, r9
	uxth.w	r1, lr
	cmp	r1, r0
	bne.n	.L08032daa
	lsls.w	r0, r12, #0x10
	itt	ne
	ldrne	r0, [sp, #0x4]
	andsne	r0, r0, #0x40
	bne.n	.L08032d9e
.L08032d9a:
	subs	r6, #0x1
	b.n	.L08032dac
.L08032d9e:
	ldr	r0, [sp, #0xc]
	add.w	r0, r0, r11, lsl #0x1
	ldrh	r0, [r0, #0x2]
	cmp	r0, #0x0
	beq.n	.L08032d9a
@ mismatch: expected sequence = 0xff
.L08032daa:
	movs	r6, #0xff
.L08032dac:
	movw	r5, #0xffff
	movt	r5, #0xf
	b.w	.L080317c2

@ ---- exit paths of find_directory_entry_by_name
.L08032db8:
	movs	r0, #0x0
.L08032dba:
	str	r0, [r4, #0x18]
.L08032dbc:
	movs	r0, #0x4
	add	sp, #0x1c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08032dc4:
	mov.w	r0, #0xffffffff
	str.w	r0, [r8, #0x30]
.L08032dcc:
	movs	r0, #0x1
	add	sp, #0x1c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08032dd4:
	movs	r0, #0x0
	add	sp, #0x1c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
.L08032ddc:
	movs	r0, #0x2
	add	sp, #0x1c
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
