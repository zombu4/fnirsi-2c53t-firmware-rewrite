@ parse_jpeg_header_p2.inc - part 2 of 2 of parse_jpeg_header (0x08039f20..0x08039f6c):
@ tail blocks that load fields of the decoder context in r8 and rejoin the
@ main loop at .L08039d78. Included by part 1; no header or section lines.
@ r8 is the base of the structure being stored to; the function pointer at
@ [r8, #0x74] is called as r3(r8, r5) with r2 = 0x200 - r4.
	movs	r0, #0
	str.w	r0, [r8, #0x68]
	movs	r7, #3
	b.n	.L08039d78
.L08039f2a:
	movs	r7, #3
	b.n	.L08039d78
.L08039f2e:
	bfc	r4, #9, #0x17		@ clear bits 9..31 of r4
	subs	r1, r1, r0
	add	r0, r2
	movs	r7, #0
	cmp	r4, #0
	strd	r2, r0, [r8, #0x68]
	str.w	r1, [r8, #0x70]
	strd	r7, r9, [r8]
	strb.w	r7, [r8, #0xc]
	beq.w	.L08039d78
	ldr.w	r3, [r8, #0x74]
	add.w	r5, r9, r4
	rsb.w	r2, r4, #0x200
	mov	r0, r8
	mov	r1, r5
	blx	r3			@ call the function pointer stored in the context
	subs	r1, r5, #1
	strd	r0, r1, [r8]
	movs	r7, #0
	b.n	.L08039d78
	.short	0x0000			@ padding
