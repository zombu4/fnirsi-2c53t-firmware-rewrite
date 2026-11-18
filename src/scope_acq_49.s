@ scope_acq_49.s - part 1 of 2 of fn_0803e454, the acquisition task body (0x0803e454..0x0803f454).
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0803e454 - acquisition task body. No parameters; never returns (no return
@ instruction; calls only queue_receive_timeout (080421d8), 08041390, 08041cf0 and
@ 0803b078).
@
@ Task body: waits for one command byte with 080421d8(*0x20002d78, &cmd, 0xffffffff),
@ retrying until it returns 1. u0 = signed halfword 0x20000114 xor 0xffffff80 (kept
@ unchanged in r0) and u = u0 (r2). When bytes 0x2000044a and 0x2000044b are neither
@ 0 nor 0xff and byte 0x2000012b is 0, u is replaced by ((s-28)/150)*(h-e)+e+128 as
@ float, clamped to 0..255 and truncated, with s = the byte at address
@ 0x2000044a+byte[0x2000010e], h = signed halfword 0x20000114 and e = signed byte
@ 0x200000fc+byte[0x2000010e]. Then it writes 0x40 to 0x40010c14, waits until bit1 of
@ 0x40003c08 is set, writes the command to 0x40003c0c, waits until bit0 of 0x40003c08
@ is set and reads 0x40003c0c. Then switch(cmd) for cmd 1..9 (cmd 0 and cmd above 9
@ do nothing further). An 'exchange' below means: wait until bit1 of 0x40003c08 is
@ set, write a byte to 0x40003c0c, wait until bit0 is set, read 0x40003c0c.
@
@ cmd 1: sends byte 0x20000125 (idx) when halfword 0x20000eb0 < byte table
@   0x0804d833[idx]+0x32, else clears halfword 0x20000eb0 and sends idx+1 (idx<0x13)
@   or 0x12.
@ cmd 2: sends 3 when byte 0x2000010c==0 else that byte.
@ cmd 6: sends byte 0x2000010e.
@ cmd 7: sends byte 0x20000110.
@ cmd 8: sends the low byte of u (the scaled value when the scaling above applied).
@   Each of cmd 1, 2, 6, 7, 8 is one exchange followed by a read of 0x40003c0c.
@ cmd 3: decrements ushort 0x20000eac when nonzero; with n = ushort 0x20000eae
@   incremented up to 0x12d (not incremented above 0x12c), unless the old n was 0 it
@   moves the last n bytes of each of the two 0x12d-byte arrays 0x2000044e..0x2000057a
@   and 0x2000057b..0x200006a7 down by one (n-1 byte moves each, dest 0x2000057b-n+i
@   and 0x200006a8-n+i, i=0..n-2); then four exchanges of 0xff: replies 1 and 3 are
@   discarded, reply 2 is stored to 0x2000057a and reply 4 to 0x200006a7. When byte
@   0x2000012b==0 and bytes 0x2000044a and 0x2000044b are neither 0 nor 0xff,
@   0x2000057a is replaced (only when byte 0x2000044a>0xdc) by
@   ((v-128-e)/((s-28)/192))+128+e (float, clamped 0..255, truncated) with v = the
@   stored value, s = byte 0x2000044a, e = signed byte 0x200000fc, and likewise
@   0x200006a7 (only when byte 0x2000044b>0xdc) with s = byte 0x2000044b and
@   e = signed byte 0x200000fd. Then when ushort 0x20000eae==0x12d and byte
@   0x2000010f!=1 it tests p=(u0&0xff) (the unscaled value, uxtb r6,r0 at 0x0803ec68)
@   against the byte pair 0x200000f8+k+0x3eb (first) and 0x200000f8+k+0x3ec (second)
@   with k=(short)0x20000112+0x12d*byte 0x2000010e: byte 0x20000110 in {0,2}: trigger
@   when first<=p<second; byte 0x20000110 in {1,2}: trigger when second<p<=first. On
@   trigger with byte 0x2000010f==0 the word 0x20000eac is set to 0x12d (ushort
@   0x20000eae becomes 0), otherwise it clears byte 0x20000126, clears bit0 of
@   0x40000400, posts byte 2 with 08041cf0(*0x20002d6c, &2, 0xffffffff), calls
@   0803b078 and, when ushort 0x20000eae!=0, copies for j=0x20000eac up to (not
@   including) 0x20000eac+0x20000eae the bytes 0x2000044e+j to 0x200006a8+j and
@   0x2000057b+j to 0x20000aa8+j.
@ cmd 4: one exchange of 0xff (reply discarded) then 0x400 exchanges of 0xff, the
@   replies stored in order to 0x200006a8..0x200006a8+0x3ff; then, when byte
@   0x2000012b==0, bytes 0x2000044a and 0x2000044b are neither 0 nor 0xff and (byte
@   0x2000010c==3 or byte 0x20000125>3), every one of these 0x400 bytes v becomes
@   ((v-128-e)/((s-28)/150))+128+e (float, clamped 0..255, truncated) with
@   s = byte 0x2000044a and e = signed byte 0x200000fc; then, when byte
@   0x2000010f==2, the outlier pass below runs on 0x200006a8; finally byte
@   0x20000ea8 is incremented when byte 0x2000010c==1 and byte 0x20000125>4 (also
@   when the pass did not run).
@ cmd 5: same with 0x400 bytes at 0x20000aa8 (0x400 exchanges after one discarded
@   exchange), scale byte 0x2000044b and e = signed byte 0x200000fd (the not-0/0xff
@   condition covers both 0x2000044a and 0x2000044b), byte 0x20000ea8 is always
@   incremented right after the scaling (before the pass), and the outlier pass runs
@   on 0x20000aa8 when byte 0x2000010f==2.
@ Outlier pass (cmd 4 and 5), i=0..0x3ff: with sample S_k = sample(i+k) for k=0..4,
@   when |S0-S1|<8 and |S1-S2|>10 and |S2-S3|>10 and |S3-S1|<8 and |S4-S3|<8 (|.| of
@   byte differences; the fourth compares sample i+3 with i+1, not neighbours),
@   element (i+2) mod 0x400 of the target array (0x200006a8 for cmd 4, 0x20000aa8 for
@   cmd 5) is set to S3+trunc((S1-S3)/2) (halving truncates toward zero, the result
@   is stored as a byte); the pass edits the target array in place so later i see
@   earlier replacements. Mode A (byte 0x2000010c==3 or byte 0x20000125>3):
@   sample(j)=target array[j mod 0x400], reads wrap at 0x400. Mode B (byte
@   0x2000010c!=3 and byte 0x20000125<=3): sample(j) is interleaved, j even reads
@   byte 0x200006a8+j/2 and j odd reads byte 0x20000aa8+j/2, with indices wrapping at
@   0x800 (not reached since j<=0x403), and when byte 0x2000010c==1 the odd samples
@   are reduced by byte 0x20000448 (mod 256, even samples unchanged) while when byte
@   0x2000010c!=1 the even samples are reduced by byte 0x20000449 (odd samples
@   unchanged); in mode B the result is still written to element (i+2) mod 0x400 of
@   the target array (cmd 4: 0x200006a8, cmd 5: 0x20000aa8).
@ cmd 9: exchange of 0xff (reply discarded), exchange of 0xff (reply low byte stored
@   to halfword 0x2000013e), writes 0x40 to 0x40010c10, calls 08041390(1), writes
@   0x40 to 0x40010c14, sends 10 (reply discarded), exchange of 0xff (reply
@   discarded), halfword 0x2000013e is shifted left by 8, exchange of 0xff and
@   halfword 0x2000013e = (0x2000013e<<8) | low byte of that reply, then byte
@   0x20000ea8 is incremented.
@ Every command (and an unknown command) ends by writing 0x40 to 0x40010c10 and
@ returning to the wait for the next command byte. Reads but never writes the scale
@ bytes 0x2000044a/0x2000044b. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0803e454,"ax",%progbits
	.global fn_0803e454
	.thumb_func
	.type fn_0803e454, %function
fn_0803e454:
	sub	sp, #0x38
	movw	r7, #0x3c08
	movw	r4, #0x2d78
	movw	r9, #0xf8
	vldr	s18, .L0803e674
	vldr	s20, .L0803e678
	vldr	s22, .L0803e67c
	vldr	s24, .L0803e680
	vldr	s26, .L0803e684
	vldr	s28, .L0803e688
	movt	r7, #0x4000
	movs	r0, #0
	movt	r4, #0x2000
	add.w	r5, sp, #0x36
	movt	r9, #0x2000
	vmov.f32	s16, #-28.0
	strb.w	r0, [sp, #0x36]
	b.n	.L0803e4b2
	.byte	0x00, 0xbf	@ padding, never reached
.L0803e498:
	ldr	r0, [r7, #4]
.L0803e49a:
	movw	r0, #0xc10
	movt	r0, #0x4001
	movs	r1, #0x40
	movw	r4, #0x2d78
	str	r1, [r0, #0]
	movt	r4, #0x2000
	add.w	r5, sp, #0x36
.L0803e4b2:
	ldr	r0, [r4, #0]
	mov	r1, r5
	mov.w	r2, #0xffffffff
	bl	queue_receive_timeout
	cmp	r0, #1
	bne.n	.L0803e4b2
	ldrb.w	r2, [r9, #0x352]
	ldrsh.w	r3, [r9, #0x1c]
	ldrb.w	r1, [sp, #0x36]
	mvn	r0, #0x7f
	eor.w	r0, r0, r3
	cbz	r2, .L0803e4e8
	cmp	r2, #0xff
	beq.n	.L0803e4e8
	ldrb.w	r2, [r9, #0x353]
	cbz	r2, .L0803e4e8
	cmp	r2, #0xff
	bne.w	.L0803e8fe
.L0803e4e8:
	mov	r2, r0
.L0803e4ea:
	movw	r3, #0xc10
	movt	r3, #0x4001
	movs	r6, #0x40
	str	r6, [r3, #4]
	nop
.L0803e4f8:
	ldr	r3, [r7, #0]
	lsls	r3, r3, #0x1e
	itttt	pl
	ldrpl	r3, [r7, #0]
	lslspl.w	r3, r3, #0x1e
	ldrpl	r3, [r7, #0]
	lslspl.w	r3, r3, #0x1e
	bmi.n	.L0803e512
	ldr	r3, [r7, #0]
	lsls	r3, r3, #0x1e
	bpl.n	.L0803e4f8
.L0803e512:
	str	r1, [r7, #4]
.L0803e514:
	ldr	r3, [r7, #0]
	lsls	r3, r3, #0x1f
	itttt	eq
	ldreq	r3, [r7, #0]
	lslseq.w	r3, r3, #0x1f
	ldreq	r3, [r7, #0]
	lslseq.w	r3, r3, #0x1f
	bne.n	.L0803e52e
	ldr	r3, [r7, #0]
	lsls	r3, r3, #0x1f
	beq.n	.L0803e514
.L0803e52e:
	subs	r1, #1
	ldr	r3, [r7, #4]
	cmp	r1, #8
	bhi.n	.L0803e49a
	tbh	[pc, r1, lsl #1]
.L0803e53a:
	.short	(.L0803e54c - .L0803e53a)/2
	.short	(.L0803e970 - .L0803e53a)/2
	.short	(.L0803e9f2 - .L0803e53a)/2
	.short	(.L0803e5a4 - .L0803e53a)/2
	.short	(.L0803e68c - .L0803e53a)/2
	.short	(.L0803ed1c - .L0803e53a)/2
	.short	(.L0803ed5c - .L0803e53a)/2
	.short	(.L0803e75c - .L0803e53a)/2
	.short	(.L0803e79c - .L0803e53a)/2
.L0803e54c:
	ldrb.w	r0, [r9, #0x2d]
	movw	r1, #:lower16:d_0804d833	@ own label of the byte table at 0x0804d833 (was d_0804d832+1)
	movt	r1, #:upper16:d_0804d833	@ own label of the byte table at 0x0804d833 (was d_0804d832+1)
	ldrb	r1, [r1, r0]
	ldrh.w	r2, [r9, #0xdb8]
	adds	r1, #0x32
	cmp	r1, r2
	bls.w	.L0803ff70
	nop
.L0803e568:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803e582
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803e568
.L0803e582:
	str	r0, [r7, #4]
.L0803e584:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.w	.L0803e498
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e584
	b.n	.L0803e498
	.byte	0x00, 0xbf	@ padding, never reached
.L0803e5a4:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0803e5be
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	bpl.n	.L0803e5a4
.L0803e5be:
	movs	r3, #0xff
	str	r3, [r7, #4]
	nop
.L0803e5c4:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0803e5de
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e5c4
.L0803e5de:
	ldr	r0, [r7, #4]
	movs	r0, #0
	b.n	.L0803e5f8
.L0803e5e4:
	ldr	r2, [r7, #4]
	adds	r0, #2
	add	r1, r9
	cmp.w	r0, #0x400
	strb.w	r2, [r1, #0x5b0]
	beq.w	.L0803ed9c
	nop
.L0803e5f8:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803e612
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803e5f8
.L0803e612:
	str	r3, [r7, #4]
.L0803e614:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	itttt	eq
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	bne.n	.L0803e62e
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	beq.n	.L0803e614
.L0803e62e:
	ldr	r1, [r7, #4]
	add.w	r2, r9, r0
	strb.w	r1, [r2, #0x5b0]
	orr	r1, r0, #1
.L0803e63c:
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1e
	bmi.n	.L0803e656
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1e
	itt	pl
	ldrpl	r2, [r7, #0]
	lslspl.w	r2, r2, #0x1e
	bmi.n	.L0803e656
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1e
	bpl.n	.L0803e63c
.L0803e656:
	str	r3, [r7, #4]
.L0803e658:
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1f
	bne.n	.L0803e5e4
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1f
	itt	eq
	ldreq	r2, [r7, #0]
	lslseq.w	r2, r2, #0x1f
	bne.n	.L0803e5e4
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1f
	beq.n	.L0803e658
	b.n	.L0803e5e4
.L0803e674:
	.word	0x43400000	@ 192.0f
.L0803e678:
	.word	0xc3000000	@ -128.0f
.L0803e67c:
	.word	0x43000000	@ 128.0f
.L0803e680:
	.word	0x437f0000	@ 255.0f
.L0803e684:
	.word	0x00000000	@ 0.0f
.L0803e688:
	.word	0x43160000	@ 150.0f
.L0803e68c:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0803e6a6
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	bpl.n	.L0803e68c
.L0803e6a6:
	movs	r3, #0xff
	str	r3, [r7, #4]
	nop
.L0803e6ac:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0803e6c6
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e6ac
.L0803e6c6:
	ldr	r0, [r7, #4]
	mov.w	r0, #0x400
	b.n	.L0803e6e0
.L0803e6ce:
	ldr	r2, [r7, #4]
	adds	r0, #2
	add	r1, r9
	cmp.w	r0, #0x800
	strb.w	r2, [r1, #0x5b0]
	beq.w	.L0803f06c
.L0803e6e0:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803e6fa
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803e6e0
.L0803e6fa:
	str	r3, [r7, #4]
.L0803e6fc:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	itttt	eq
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	bne.n	.L0803e716
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	beq.n	.L0803e6fc
.L0803e716:
	ldr	r1, [r7, #4]
	add.w	r2, r9, r0
	strb.w	r1, [r2, #0x5b0]
	orr	r1, r0, #1
.L0803e724:
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1e
	bmi.n	.L0803e73e
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1e
	itt	pl
	ldrpl	r2, [r7, #0]
	lslspl.w	r2, r2, #0x1e
	bmi.n	.L0803e73e
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1e
	bpl.n	.L0803e724
.L0803e73e:
	str	r3, [r7, #4]
.L0803e740:
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1f
	bne.n	.L0803e6ce
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1f
	itt	eq
	ldreq	r2, [r7, #0]
	lslseq.w	r2, r2, #0x1f
	bne.n	.L0803e6ce
	ldr	r2, [r7, #0]
	lsls	r2, r2, #0x1f
	beq.n	.L0803e740
	b.n	.L0803e6ce
.L0803e75c:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0803e776
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	bpl.n	.L0803e75c
.L0803e776:
	uxtb	r0, r2
	str	r0, [r7, #4]
	nop
.L0803e77c:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.w	.L0803e498
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e77c
	b.n	.L0803e498
	.byte	0x00, 0xbf	@ padding, never reached
.L0803e79c:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0803e7b6
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	bpl.n	.L0803e79c
.L0803e7b6:
	movs	r1, #0xff
	str	r1, [r7, #4]
	nop
.L0803e7bc:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0803e7d6
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e7bc
.L0803e7d6:
	ldr	r0, [r7, #4]
.L0803e7d8:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0803e7f2
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	bpl.n	.L0803e7d8
.L0803e7f2:
	str	r1, [r7, #4]
.L0803e7f4:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0803e80e
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e7f4
.L0803e80e:
	ldr	r0, [r7, #4]
	movw	r4, #0xc10
	uxtb	r0, r0
	strh.w	r0, [r9, #0x46]
	movt	r4, #0x4001
	movs	r5, #0x40
	movs	r0, #1
	str	r5, [r4, #0]
	bl	fn_08041390
	str	r5, [r4, #4]
	nop
.L0803e82c:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0803e846
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	bpl.n	.L0803e82c
.L0803e846:
	movs	r0, #0xa
	str	r0, [r7, #4]
	nop
.L0803e84c:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0803e866
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e84c
.L0803e866:
	ldr	r0, [r7, #4]
	movs	r1, #0xff
	nop
.L0803e86c:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0803e886
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	bpl.n	.L0803e86c
.L0803e886:
	str	r1, [r7, #4]
.L0803e888:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0803e8a2
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e888
.L0803e8a2:
	ldr	r0, [r7, #4]
	ldrh.w	r0, [r9, #0x46]
	lsls	r0, r0, #8
	strh.w	r0, [r9, #0x46]
	nop
.L0803e8b0:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0803e8ca
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	bpl.n	.L0803e8b0
.L0803e8ca:
	str	r1, [r7, #4]
.L0803e8cc:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0803e8e6
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e8cc
.L0803e8e6:
	ldr	r0, [r7, #4]
	ldrh.w	r1, [r9, #0x46]
	uxtb	r0, r0
	orrs	r0, r1
	ldrb.w	r1, [r9, #0xdb0]
	strh.w	r0, [r9, #0x46]
	adds	r0, r1, #1
	b.w	.L0803ff68
.L0803e8fe:
	ldrb.w	r2, [r9, #0x33]
	cmp	r2, #0
	mov	r2, r0
	bne.w	.L0803e4ea
	ldrb.w	r2, [r9, #0x16]
	add	r2, r9
	ldrb.w	r6, [r2, #0x352]
	ldrsb.w	r2, [r2, #4]
	vmov	s0, r6
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vdiv.f32	s0, s0, s28
	subs	r3, r3, r2
	vmov	s2, r3
	vcvt.f32.s32	s2, s2
	vmul.f32	s0, s0, s2
	vmov	s2, r2
	vcvt.f32.s32	s2, s2
	vadd.f32	s0, s0, s2
	vadd.f32	s0, s0, s22
	vcmp.f32	s0, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s2, s24
	bgt.n	.L0803e966
	vcmp.f32	s0, #0
	vmov.f32	s2, s0
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s2, s26
.L0803e966:
	vcvt.s32.f32	s0, s2
	vmov	r2, s0
	b.n	.L0803e4ea
.L0803e970:
	ldrb.w	r0, [r9, #0x14]
	cbz	r0, .L0803e9b4
	nop
.L0803e978:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803e992
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803e978
.L0803e992:
	str	r0, [r7, #4]
.L0803e994:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.w	.L0803e498
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e994
	b.n	.L0803e498
	.byte	0x00, 0xbf	@ padding, never reached
.L0803e9b4:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r7, #0]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0803e9ce
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1e
	bpl.n	.L0803e9b4
.L0803e9ce:
	movs	r0, #3
	str	r0, [r7, #4]
	nop
.L0803e9d4:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.w	.L0803e498
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803e9d4
	b.n	.L0803e498
.L0803e9f2:
	ldrh.w	r1, [r9, #0xdb4]
	cmp	r1, #0
	itt	ne
	subne	r1, #1
	strhne.w	r1, [r9, #0xdb4]
	ldrh.w	r1, [r9, #0xdb6]
	cmp.w	r1, #0x12c
	bhi.n	.L0803ea16
	cmp	r1, #0
	add.w	r1, r1, #1
	strh.w	r1, [r9, #0xdb6]
	beq.n	.L0803ea4c
.L0803ea16:
	movs	r3, #0
	movs	r2, #0
	nop
.L0803ea1c:
	subs	r1, r3, r1
	addw	r6, r9, #0x356
	add	r1, r6
	ldrb.w	r5, [r1, #0x12e]
	adds	r2, #1
	strb.w	r5, [r1, #0x12d]
	ldrh.w	r1, [r9, #0xdb6]
	subs	r1, r3, r1
	add	r1, r6
	ldrb.w	r3, [r1, #0x25b]
	strb.w	r3, [r1, #0x25a]
	ldrh.w	r1, [r9, #0xdb6]
	uxth	r3, r2
	subs	r6, r1, #1
	cmp	r6, r3
	bgt.n	.L0803ea1c
	nop
.L0803ea4c:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803ea66
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803ea4c
.L0803ea66:
	movs	r2, #0xff
	str	r2, [r7, #4]
	nop
.L0803ea6c:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	itttt	eq
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	bne.n	.L0803ea86
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	beq.n	.L0803ea6c
.L0803ea86:
	ldr	r1, [r7, #4]
.L0803ea88:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803eaa2
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803ea88
.L0803eaa2:
	str	r2, [r7, #4]
.L0803eaa4:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	itttt	eq
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	bne.n	.L0803eabe
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	beq.n	.L0803eaa4
.L0803eabe:
	ldr	r1, [r7, #4]
	strb.w	r1, [r9, #0x482]
.L0803eac4:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803eade
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803eac4
.L0803eade:
	str	r2, [r7, #4]
.L0803eae0:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	itttt	eq
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	bne.n	.L0803eafa
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	beq.n	.L0803eae0
.L0803eafa:
	ldr	r1, [r7, #4]
.L0803eafc:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803eb16
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803eafc
.L0803eb16:
	str	r2, [r7, #4]
.L0803eb18:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	itttt	eq
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	ldreq	r1, [r7, #0]
	lslseq.w	r1, r1, #0x1f
	bne.n	.L0803eb32
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1f
	beq.n	.L0803eb18
.L0803eb32:
	ldr	r1, [r7, #4]
	ldrb.w	r3, [r9, #0x352]
	strb.w	r1, [r9, #0x5af]
	cmp	r3, #0
	beq.n	.L0803ec2e
	cmp	r3, #0xff
	beq.n	.L0803ec2e
	ldrb.w	r2, [r9, #0x353]
	cmp	r2, #0
	beq.n	.L0803ec2e
	cmp	r2, #0xff
	beq.n	.L0803ec2e
	ldrb.w	r6, [r9, #0x33]
	cmp	r6, #0
	bne.n	.L0803ec2e
	cmp	r3, #0xdd
	bcc.n	.L0803ebc4
	vmov	s0, r3
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vdiv.f32	s0, s0, s18
	ldrb.w	r3, [r9, #0x482]
	vmov	s2, r3
	ldrsb.w	r3, [r9, #4]
	vcvt.f32.u32	s2, s2
	vmov	s4, r3
	vadd.f32	s2, s2, s20
	vcvt.f32.s32	s4, s4
	vsub.f32	s2, s2, s4
	vdiv.f32	s0, s2, s0
	vmov.f32	s2, s24
	vadd.f32	s0, s0, s22
	vadd.f32	s0, s0, s4
	vcmp.f32	s0, s24
	vmrs	APSR_nzcv, fpscr
	bgt.n	.L0803ebb8
	vcmp.f32	s0, #0
	vmov.f32	s2, s0
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s2, s26
.L0803ebb8:
	vcvt.s32.f32	s0, s2
	vmov	r3, s0
	strb.w	r3, [r9, #0x482]
.L0803ebc4:
	cmp	r2, #0xdc
	bls.n	.L0803ec2e
	vmov	s0, r2
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vdiv.f32	s0, s0, s18
	uxtb	r1, r1
	vmov	s2, r1
	ldrsb.w	r1, [r9, #5]
	vcvt.f32.u32	s2, s2
	vmov	s4, r1
	vadd.f32	s2, s2, s20
	vcvt.f32.s32	s4, s4
	vsub.f32	s2, s2, s4
	vdiv.f32	s0, s2, s0
	vmov.f32	s2, s24
	vadd.f32	s0, s0, s22
	vadd.f32	s0, s0, s4
	vcmp.f32	s0, s24
	vmrs	APSR_nzcv, fpscr
	bgt.n	.L0803ec22
	vcmp.f32	s0, #0
	vmov.f32	s2, s0
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s2, s26
.L0803ec22:
	vcvt.s32.f32	s0, s2
	vmov	r1, s0
	strb.w	r1, [r9, #0x5af]
.L0803ec2e:
	ldrh.w	r1, [r9, #0xdb6]
	movw	r2, #0x12d
	cmp	r1, r2
	bne.w	.L0803e49a
	ldrb.w	r1, [r9, #0x17]
	cmp	r1, #1
	beq.w	.L0803e49a
	ldrb.w	r2, [r9, #0x18]
	orr	r3, r2, #2
	cmp	r3, #2
	bne.n	.L0803ec76
	ldrb.w	r3, [r9, #0x16]
	ldrsh.w	r6, [r9, #0x1a]
	movw	r5, #0x12d
	smlabb	r3, r3, r5, r9
	add	r3, r6
	ldrb.w	r5, [r3, #0x3eb]
	uxtb	r6, r0	@ p = unscaled value (u0 & 0xff)
	cmp	r5, r6
	bhi.n	.L0803ec76
	ldrb.w	r3, [r3, #0x3ec]
	cmp	r3, r6
	bhi.n	.L0803eca6
.L0803ec76:
	subs	r2, #1
	cmp	r2, #1
	bhi.w	.L0803e49a
	ldrb.w	r2, [r9, #0x16]
	ldrsh.w	r3, [r9, #0x1a]
	movw	r6, #0x12d
	smlabb	r2, r2, r6, r9
	add	r2, r3
	ldrb.w	r3, [r2, #0x3eb]
	uxtb	r0, r0
	cmp	r3, r0
	bcc.w	.L0803e49a
	ldrb.w	r2, [r2, #0x3ec]
	cmp	r2, r0
	bcs.w	.L0803e49a
.L0803eca6:
	cmp	r1, #0
	beq.w	.L0803fffc
	movs	r0, #0
	movw	r1, #0x400
	strb.w	r0, [r9, #0x2e]
	movt	r1, #0x4000
	ldr	r0, [r1, #0]
	mov.w	r2, #0xffffffff
	bic	r0, r0, #1
	str	r0, [r1, #0]
	movw	r0, #0x2d6c
	movt	r0, #0x2000
	ldr	r0, [r0, #0]
	movs	r1, #2
	strb.w	r1, [sp, #0x37]
	add.w	r1, sp, #0x37
	bl	queue_send_timeout
	bl	fn_0803b078
	ldrh.w	r0, [r9, #0xdb6]
	cmp	r0, #0
	beq.w	.L0803e49a
	ldrh.w	r1, [r9, #0xdb4]
	mov	r0, r1
	nop
.L0803ecf4:
	add	r1, r9
	ldrb.w	r2, [r1, #0x356]
	ldrb.w	r3, [r1, #0x483]
	strb.w	r2, [r1, #0x5b0]
	strb.w	r3, [r1, #0x9b0]
	ldrh.w	r2, [r9, #0xdb4]
	ldrh.w	r3, [r9, #0xdb6]
	adds	r0, #1
	uxth	r1, r0
	add	r2, r3
	cmp	r2, r1
	bhi.n	.L0803ecf4
	b.w	.L0803e49a
.L0803ed1c:
	ldrb.w	r0, [r9, #0x16]
.L0803ed20:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803ed3a
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803ed20
.L0803ed3a:
	str	r0, [r7, #4]
.L0803ed3c:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.w	.L0803e498
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803ed3c
	b.w	.L0803e498
.L0803ed5c:
	ldrb.w	r0, [r9, #0x18]
.L0803ed60:
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	itttt	pl
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	ldrpl	r1, [r7, #0]
	lslspl.w	r1, r1, #0x1e
	bmi.n	.L0803ed7a
	ldr	r1, [r7, #0]
	lsls	r1, r1, #0x1e
	bpl.n	.L0803ed60
.L0803ed7a:
	str	r0, [r7, #4]
.L0803ed7c:
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r7, #0]
	lslseq.w	r0, r0, #0x1f
	bne.w	.L0803e498
	ldr	r0, [r7, #0]
	lsls	r0, r0, #0x1f
	beq.n	.L0803ed7c
	b.w	.L0803e498
.L0803ed9c:
	ldrb.w	lr, [r9, #0x14]
	ldrb.w	r1, [r9, #0x2d]
	ldrb.w	r3, [r9, #0x33]
	subs.w	r0, lr, #3
	it	ne
	movne	r0, #1
	cmp	r1, #4
	mov.w	r2, #0
	it	cc
	movcc	r2, #1
	cmp	r3, #0
	bne.w	.L0803f33c
	ldrb.w	r3, [r9, #0x353]
	adds	r3, #1
	uxtb	r3, r3
	cmp	r3, #2
	bcc.w	.L0803f33c
	ands	r0, r2
	bne.w	.L0803f33c
	ldrb.w	r0, [r9, #0x352]
	adds	r2, r0, #1
	uxtb	r2, r2
	cmp	r2, #2
	bcc.w	.L0803f33c
	vmov	s0, r0
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vdiv.f32	s0, s0, s28
	ldrsb.w	r0, [r9, #4]
	movs	r2, #0
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	b.n	.L0803ee18
	.byte	0x00, 0xbf	@ padding, never reached
.L0803ee04:
	vcvt.s32.f32	s4, s4
	adds	r2, #8
	vmov	r3, s4
	cmp.w	r2, #0x400
	strb	r3, [r0, #7]
	beq.w	.L0803f33c
.L0803ee18:
	add.w	r3, r9, r2
	ldrb.w	r0, [r3, #0x5b0]
	vmov	s4, r0
	vcvt.f32.u32	s4, s4
	vadd.f32	s4, s4, s20
	vsub.f32	s4, s4, s2
	vdiv.f32	s4, s4, s0
	vadd.f32	s4, s4, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803ee5c
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803ee5c:
	ldrb.w	r0, [r3, #0x5b1]
	vcvt.s32.f32	s4, s4
	vmov	s6, r0
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r0, s4
	strb.w	r0, [r3, #0x5b0]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803eea8
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803eea8:
	ldrb.w	r0, [r3, #0x5b2]
	vcvt.s32.f32	s4, s4
	vmov	s6, r0
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	add.w	r0, r3, #0x5b0
	strb	r6, [r0, #1]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803eef6
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803eef6:
	ldrb.w	r6, [r3, #0x5b3]
	vcvt.s32.f32	s4, s4
	vmov	s6, r6
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	strb	r6, [r0, #2]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803ef40
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803ef40:
	ldrb.w	r6, [r3, #0x5b4]
	vcvt.s32.f32	s4, s4
	vmov	s6, r6
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	strb	r6, [r0, #3]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803ef8a
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803ef8a:
	ldrb.w	r6, [r3, #0x5b5]
	vcvt.s32.f32	s4, s4
	vmov	s6, r6
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	strb	r6, [r0, #4]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803efd4
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803efd4:
	ldrb.w	r6, [r3, #0x5b6]
	vcvt.s32.f32	s4, s4
	vmov	s6, r6
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	strb	r6, [r0, #5]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803f01e
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803f01e:
	ldrb.w	r3, [r3, #0x5b7]
	vcvt.s32.f32	s4, s4
	vmov	s6, r3
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r3, s4
	strb	r3, [r0, #6]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.w	.L0803ee04
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
	b.n	.L0803ee04
.L0803f06c:
	ldrb.w	r10, [r9, #0x14]
	ldrb.w	r1, [r9, #0x2d]
	ldrb.w	r0, [r9, #0x33]
	subs.w	r2, r10, #3
	it	ne
	movne	r2, #1
	cmp	r1, #4
	mov.w	r3, #0
	it	cc
	movcc	r3, #1
	cmp	r0, #0
	bne.w	.L0803f936
	ldrb.w	r0, [r9, #0x353]
	adds	r6, r0, #1
	uxtb	r6, r6
	cmp	r6, #2
	bcc.w	.L0803f936
	ands	r2, r3
	bne.w	.L0803f936
	ldrb.w	r2, [r9, #0x352]
	adds	r2, #1
	uxtb	r2, r2
	cmp	r2, #2
	bcc.w	.L0803f936
	vmov	s0, r0
	vcvt.f32.u32	s0, s0
	vadd.f32	s0, s0, s16
	vdiv.f32	s0, s0, s28
	ldrsb.w	r0, [r9, #5]
	movs	r2, #0
	vmov	s2, r0
	vcvt.f32.s32	s2, s2
	b.n	.L0803f0e8
	.byte	0x00, 0xbf	@ padding, never reached
.L0803f0d4:
	vcvt.s32.f32	s4, s4
	adds	r2, #8
	vmov	r3, s4
	cmp.w	r2, #0x400
	strb	r3, [r0, #7]
	beq.w	.L0803f936
.L0803f0e8:
	add.w	r3, r9, r2
	ldrb.w	r0, [r3, #0x9b0]
	vmov	s4, r0
	vcvt.f32.u32	s4, s4
	vadd.f32	s4, s4, s20
	vsub.f32	s4, s4, s2
	vdiv.f32	s4, s4, s0
	vadd.f32	s4, s4, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803f12c
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803f12c:
	ldrb.w	r0, [r3, #0x9b1]
	vcvt.s32.f32	s4, s4
	vmov	s6, r0
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r0, s4
	strb.w	r0, [r3, #0x9b0]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803f178
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803f178:
	ldrb.w	r0, [r3, #0x9b2]
	vcvt.s32.f32	s4, s4
	vmov	s6, r0
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	add.w	r0, r3, #0x9b0
	strb	r6, [r0, #1]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803f1c6
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803f1c6:
	ldrb.w	r6, [r3, #0x9b3]
	vcvt.s32.f32	s4, s4
	vmov	s6, r6
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	strb	r6, [r0, #2]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803f210
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803f210:
	ldrb.w	r6, [r3, #0x9b4]
	vcvt.s32.f32	s4, s4
	vmov	s6, r6
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	strb	r6, [r0, #3]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803f25a
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803f25a:
	ldrb.w	r6, [r3, #0x9b5]
	vcvt.s32.f32	s4, s4
	vmov	s6, r6
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	strb	r6, [r0, #4]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803f2a4
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803f2a4:
	ldrb.w	r6, [r3, #0x9b6]
	vcvt.s32.f32	s4, s4
	vmov	s6, r6
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r6, s4
	strb	r6, [r0, #5]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.n	.L0803f2ee
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
.L0803f2ee:
	ldrb.w	r3, [r3, #0x9b7]
	vcvt.s32.f32	s4, s4
	vmov	s6, r3
	vcvt.f32.u32	s6, s6
	vadd.f32	s6, s6, s20
	vsub.f32	s6, s6, s2
	vdiv.f32	s6, s6, s0
	vmov	r3, s4
	strb	r3, [r0, #6]
	vadd.f32	s4, s6, s22
	vadd.f32	s6, s4, s2
	vcmp.f32	s6, s24
	vmrs	APSR_nzcv, fpscr
	vmov.f32	s4, s24
	bgt.w	.L0803f0d4
	vcmp.f32	s6, #0
	vmov.f32	s4, s6
	vmrs	APSR_nzcv, fpscr
	it	lt
	vmovlt.f32	s4, s26
	b.n	.L0803f0d4
.L0803f33c:
	ldrb.w	r0, [r9, #0x17]
	cmp	r0, #2
	bne.w	.L0803ff54
	mov.w	r8, #0
	b.n	.L0803f3ac
.L0803f34c:
	ldr	r5, [sp, #0x1c]
	movw	r0, #0x3fe
	cmp	r5, r0
	mov	r0, r8
	movw	r1, #0xfc01
	it	hi
	addhi	r0, r5, r1
	ldr	r6, [sp, #0x30]
	uxth	r0, r0
	add.w	r1, r9, #0x5b0
	uxth	r2, r6
	movs	r3, #0
	ldrb	r0, [r1, r0]
	cmp.w	r3, r2, lsr #10
	it	ne
	subwne	r6, r5, #0x3fd
	uxth	r2, r6
	ldrb	r2, [r1, r2]
	ldr	r6, [sp, #0x20]
	subs	r0, r0, r2
	uxth	r1, r0
	add.w	r0, r0, r1, lsr #15
	asrs	r0, r0, #1
.L0803f386:
	movw	r1, #0x3fd
	add	r0, r2
	cmp	r5, r1
	it	hi
	subwhi	r6, r5, #0x3fe
	add.w	r1, r9, r6
	strb.w	r0, [r1, #0x5b0]
.L0803f39c:
	ldrb.w	lr, [r9, #0x14]
	ldrb.w	r1, [r9, #0x2d]
	cmp.w	r8, #0x400
	beq.w	.L0803ff54
.L0803f3ac:
	sub.w	r0, lr, #3
	clz	r0, r0
	lsrs	r0, r0, #5
	cmp	r1, #3
	mov.w	r1, #0
	it	hi
	movhi	r1, #1
	orrs.w	r2, r0, r1
	mov	r5, r8
	uxth.w	r4, r8
	mov.w	r0, #0
	strd	r2, lr, [sp, #0x24]
	str.w	r8, [sp, #0x1c]
	beq.w	.L0803f518
	adds	r6, r5, #1
	cmp.w	r0, r4, lsr #10
	mov	r10, r5
	movw	r2, #0x3fe
	mov	r1, r6
	it	ne
	addne.w	r10, r10, #0xfc00
	cmp	r4, r2
	it	hi
	subwhi	r1, r5, #0x3ff
	add.w	r0, r9, #0x5b0
	uxth	r1, r1
	ldrb.w	r9, [r0, r1]
	adds	r3, r5, #2
	movw	r1, #0x3fd
	cmp	r4, r1
	mov	r8, r3
	add.w	r11, r5, #3
	it	hi
	subwhi	r8, r5, #0x3fe
	cmp.w	r4, #0x3fc
	mov	r12, r11
	lsr.w	r4, r4, #2
	subw	lr, r5, #0x3fd
	it	hi
	movhi	r12, lr
	adds	r1, r5, #4
	cmp	r4, #0xfe
	it	hi
	subhi.w	r1, r5, #0x3fc
	cmp	r5, r2
	mov	r4, r6
	movw	r2, #0xfc01
	str	r6, [sp, #0x2c]
	it	hi
	addhi	r4, r5, r2
	movw	r2, #0x3fd
	cmp	r5, r2
	str	r3, [sp, #0x20]
	movw	r6, #0xfc02
	it	hi
	addhi	r3, r5, r6
	uxth	r2, r3
	ldrb	r2, [r0, r2]
	movs	r3, #0
	.include "src/parts/fn_0803e454_p2.inc"
