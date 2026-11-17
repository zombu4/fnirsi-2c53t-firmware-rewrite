@ compute_channel_measurements_p2.inc - part 2 of 2 of compute_channel_measurements
@ (0x080276f8..0x08027930): tail of the function. r10 is the base of the
@ measurement structure. The block copies words from offsets 0x70..0x108 of the
@ structure to offsets 0x110..0x168 and accumulates 32-bit values into 64-bit
@ running sums (adds / adc with the sign of the added word, asr #31) stored as
@ low/high pairs at 0x190..0x22c. Values staged by part 1 on the stack
@ ([sp, #0xc]..[sp, #0x34]) are added to words at 0x70..0x84 of the structure
@ and stored as 64-bit pairs at 0x1a0..0x1d8. Finally [r10 + 0x10c] is copied to
@ [r10 + 0x16c], the stack (0x68 bytes, d8-d11, 4 bytes) is released and the
@ function returns by popping r4-r11 and pc. Included by part 1; no header or
@ section lines. Two padding bytes follow the return.
	strd	r11, r1, [r10, #0x190]
	ldr.w	r1, [r10, #0x70]
	str.w	r0, [r10, #0x110]
	ldr	r0, [sp, #0x10]
	strd	r3, r2, [r10, #0x1a0]
	adds.w	r12, r0, r1
	ldr	r0, [sp, #0xc]
	ldr.w	r2, [r10, #0x74]
	adc.w	lr, r0, r1, asr #0x1f
	ldr	r0, [sp, #0x18]
	str.w	r7, [r10, #0x1a8]
	adds	r7, r0, r2
	ldr	r0, [sp, #0x14]
	str.w	r6, [r10, #0x1ac]
	ldr.w	r3, [r10, #0xb4]
	adc.w	r2, r0, r2, asr #0x1f
	ldr.w	r6, [r10, #0x78]
	ldr	r0, [sp, #0x20]
	str.w	r3, [r10, #0x114]
	adds	r3, r0, r6
	ldr	r0, [sp, #0x1c]
	strd	r5, r4, [r10, #0x198]
	adc.w	r6, r0, r6, asr #0x1f
	ldr.w	r5, [r10, #0x7c]
	ldr	r0, [sp, #0x28]
	ldr	r1, [sp, #0x24]
	adds	r0, r0, r5
	adc.w	r5, r1, r5, asr #0x1f
	ldr.w	r1, [r10, #0xc4]
	str.w	r2, [r10, #0x1bc]
	str.w	r1, [r10, #0x124]
	ldr.w	r1, [r10, #0xc8]
	strd	r0, r5, [r10, #0x1c8]
	str.w	r1, [r10, #0x128]
	ldr.w	r1, [r10, #0xcc]
	ldr.w	r0, [r10, #0x80]
	str.w	r1, [r10, #0x12c]
	ldr.w	r1, [r10, #0xd0]
	ldr	r2, [sp, #0x30]
	str.w	r1, [r10, #0x130]
	ldr.w	r1, [r10, #0xd4]
	str.w	r3, [r10, #0x1c0]
	str.w	r1, [r10, #0x134]
	ldr.w	r1, [r10, #0xd8]
	ldr	r3, [sp, #0x2c]
	adds	r2, r2, r0
	str.w	r1, [r10, #0x138]
	ldr.w	r1, [r10, #0xdc]
	adc.w	r0, r3, r0, asr #0x1f
	str.w	r1, [r10, #0x13c]
	strd	r2, r0, [r10, #0x1d0]
	ldr.w	r0, [r10, #0xe0]
	ldr.w	r1, [r10, #0x84]
	str.w	r0, [r10, #0x140]
	adds.w	r0, r8, r1
	ldr	r2, [sp, #0x34]
	str.w	r0, [r10, #0x1d8]
	ldr.w	r0, [r10, #0xe4]
	adc.w	r1, r2, r1, asr #0x1f
	str.w	r1, [r10, #0x1dc]
	str.w	r0, [r10, #0x144]
	ldr.w	r0, [r10, #0x88]
	ldrd	r1, r2, [r10, #0x1e0]
	ldr.w	r4, [r10, #0xb8]
	adds	r1, r1, r0
	str.w	r1, [r10, #0x1e0]
	ldr.w	r1, [r10, #0xe8]
	adc.w	r0, r2, r0, asr #0x1f
	str.w	r0, [r10, #0x1e4]
	str.w	r1, [r10, #0x148]
	ldr.w	r0, [r10, #0x8c]
	ldrd	r1, r2, [r10, #0x1e8]
	str.w	r4, [r10, #0x118]
	adds	r1, r1, r0
	str.w	r1, [r10, #0x1e8]
	ldr.w	r1, [r10, #0xec]
	adc.w	r0, r2, r0, asr #0x1f
	str.w	r0, [r10, #0x1ec]
	str.w	r1, [r10, #0x14c]
	ldr.w	r0, [r10, #0x90]
	ldrd	r1, r2, [r10, #0x1f0]
	ldr.w	r4, [r10, #0xbc]
	adds	r1, r1, r0
	str.w	r1, [r10, #0x1f0]
	ldr.w	r1, [r10, #0xf0]
	adc.w	r0, r2, r0, asr #0x1f
	str.w	r0, [r10, #0x1f4]
	str.w	r1, [r10, #0x150]
	ldr.w	r0, [r10, #0x94]
	ldrd	r1, r2, [r10, #0x1f8]
	str.w	r4, [r10, #0x11c]
	adds	r1, r1, r0
	str.w	r1, [r10, #0x1f8]
	ldr.w	r1, [r10, #0xf4]
	adc.w	r0, r2, r0, asr #0x1f
	str.w	r0, [r10, #0x1fc]
	str.w	r1, [r10, #0x154]
	ldr.w	r0, [r10, #0x98]
	ldrd	r1, r2, [r10, #0x200]
	ldr.w	r4, [r10, #0xc0]
	adds	r1, r1, r0
	str.w	r1, [r10, #0x200]
	ldr.w	r1, [r10, #0xf8]
	adc.w	r0, r2, r0, asr #0x1f
	str.w	r0, [r10, #0x204]
	str.w	r1, [r10, #0x158]
	ldr.w	r0, [r10, #0x9c]
	ldrd	r1, r2, [r10, #0x208]
	str.w	lr, [r10, #0x1b4]
	adds	r1, r1, r0
	str.w	r1, [r10, #0x208]
	ldr.w	r1, [r10, #0xfc]
	adc.w	r0, r2, r0, asr #0x1f
	str.w	r0, [r10, #0x20c]
	str.w	r1, [r10, #0x15c]
	ldr.w	r0, [r10, #0xa0]
	ldrd	r1, r2, [r10, #0x210]
	mov	lr, r10
	adds	r1, r1, r0
	str.w	r1, [r10, #0x210]
	ldr.w	r1, [r10, #0x100]
	adc.w	r0, r2, r0, asr #0x1f
	str.w	r0, [r10, #0x214]
	str.w	r1, [r10, #0x160]
	ldr.w	r0, [r10, #0xa4]
	ldrd	r1, r2, [r10, #0x218]
	str.w	r12, [r10, #0x1b0]
	adds	r1, r1, r0
	str.w	r1, [r10, #0x218]
	ldr.w	r1, [r10, #0x104]
	adc.w	r0, r2, r0, asr #0x1f
	str.w	r0, [r10, #0x21c]
	str.w	r1, [r10, #0x164]
	ldr.w	r0, [r10, #0xa8]
	ldrd	r1, r2, [r10, #0x220]
	str.w	r4, [r10, #0x120]
	adds	r1, r1, r0
	str.w	r1, [r10, #0x220]
	ldr.w	r1, [r10, #0x108]
	adc.w	r0, r2, r0, asr #0x1f
	str.w	r0, [r10, #0x224]
	str.w	r1, [r10, #0x168]
	ldr.w	r0, [r10, #0xac]
	ldrd	r1, r2, [r10, #0x228]
	str.w	r7, [r10, #0x1b8]
	adds	r1, r1, r0
	adc.w	r0, r2, r0, asr #0x1f
	strd	r1, r0, [r10, #0x228]
	add.w	r0, r10, #0x10c
	str.w	r6, [r10, #0x1c4]
.L0802791c:
	ldr	r0, [r0]
	str.w	r0, [lr, #0x16c]
	add	sp, #0x68
	vpop	{d8, d9, d10, d11}
	add	sp, #4
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.short	0x0000	@ padding
