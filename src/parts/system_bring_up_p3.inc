@ system_bring_up_p3.inc - part 3 of 4 of system_bring_up (bytes 0x0802ca54..0x0802da54).
@ Included by part 1; continues the function body without a header or section line.
@ This part finishes a register block setup (read-modify-write of the block at r4),
@ calls fn_08041b74 (seven times; results stored at 0x20002d6c..0x20002d84),
@ fn_08042d88 (twice; results at 0x20002d88 / 0x20002d8c) and fn_080426a0 (six
@ times; handles at 0x20002d90..0x20002da4), calls queue_send_timeout and
@ semaphore_take_timeout, then copies words loaded from the block at r4 into
@ bytes / half-words of the structure at 0x200000f8 (a magic byte of 0x55 or
@ 0xaa selects this copy, otherwise defaults are written), fills the default
@ constants at 0x200000f8+0x260.., calls set_nibble_fields_from_bit_mask on
@ the GPIO blocks and ends in repeated register wait loops on the block at r5 / r6.
	mov	r0, r6
	str.w	r1, [r0], #0x14
	ldr	r1, [r4]
	bic	r1, r1, #1
	str	r1, [r4]
	str.w	r8, [r4]
	str.w	r8, [r4, #4]
	str.w	r8, [r4, #8]
	str.w	r8, [r4, #0xc]
	ldr.w	r1, [r4, #-0x40]
	orr	r1, r1, #0xf000
	str.w	r1, [r4, #-0x40]
	ldr	r1, [r4]
	ands	r1, r2
	str	r1, [r4]
	ldr	r1, [r4]
	orr	r1, r1, #0x10
	str	r1, [r4]
	ldr	r1, [r4]
	bic	r1, r1, #0x3000
	str	r1, [r4]
	ldr	r1, [r4]
	bfi	r1, r12, #0xa, #2
	str	r1, [r4]
	ldr	r1, [r4]
	bfi	r1, r3, #8, #2
	str	r1, [r4]
	ldr	r1, [r4]
	orr	r1, r1, #0x80
	str	r1, [r4]
	ldr	r1, [r4]
	bic	r1, r1, #0x40
	str	r1, [r4]
	ldr	r1, [r4]
	orr	r1, r1, #0x20
	str	r1, [r4]
	movs	r1, #0x64
	str	r1, [r4, #4]
	str	r0, [r4, #8]
	addw	r0, lr, #0xe62
	str	r0, [r4, #0xc]
	ldr	r0, [r4, #0x60]
	lsls	r0, r0, #7
	bmi.n	.L0802cad6
	ldr	r0, [r4, #0x60]
	orr	r0, r0, #0x1000000
	str	r0, [r4, #0x60]
.L0802cad6:
	ldr	r0, [r4, #0x5c]
	movs	r1, #6
	bfi	r0, r1, #0x18, #8
	str	r0, [r4, #0x5c]
	ldr	r0, [r4]
	movw	r2, #0x5404
	orr	r0, r0, #1
	str	r0, [r4]
	ldr	r0, [r6]
	movt	r2, #0x4001
	orr	r0, r0, #0x10000
	str	r0, [r6]
	ldr.w	r0, [r7, #0x800]
	mov.w	r1, #0x1f40
	orr	r0, r0, #1
	str.w	r0, [r7, #0x800]
	ldr	r0, [r5, #0x18]
	movw	r7, #0x2b24
	orr	r0, r0, #0x2000000
	str	r0, [r5, #0x18]
	ldr	r0, [r5, #0x3c]
	movw	r4, #0x6000
	orr	r0, r0, #0x200
	str	r0, [r5, #0x3c]
	ldr	r0, [r5, #0x3c]
	movt	r7, #0x2000
	orr	r0, r0, #0x100
	str	r0, [r5, #0x3c]
	ldr	r0, [r5]
	movt	r4, #0x800
	orr	r0, r0, #0x400000
	str	r0, [r5]
	movw	r0, #0x1f2c
	str.w	r0, [r2, #0x408]
	movw	r0, #0x5810
	movt	r0, #0x4001
	str	r1, [r0]
	movw	r1, #0x1f54
	str	r1, [r0, #4]
	ldr.w	r0, [r2, #0x400]
	movw	r1, #0xe010
	orr	r0, r0, #2
	str.w	r0, [r2, #0x400]
	ldr.w	r0, [r2, #0x400]
	movt	r1, #0xe000
	orr	r0, r0, #1
	str.w	r0, [r2, #0x400]
	ldr	r0, [r5, #4]
	orr	r0, r0, #0x800000
	str	r0, [r5, #4]
	movw	r0, #0xed0c
	movt	r0, #0xe000
	ldr	r0, [r0]
	strb.w	r8, [r9, #0xb]
	mov.w	r0, #0x100000
	movw	r5, #0x5c40
	str.w	r0, [r1, #0xf0]
	movw	r0, #0x30
	movw	r1, #0x58
	movt	r5, #0x4000
	movt	r0, #0x2000
	movt	r1, #0x2000
	sub.w	r2, r5, #0x40
	strd	r2, r0, [r7]
	str	r1, [r7, #8]
	strb.w	r12, [r7, #0x224]
	bl	fn_08040990
	ldr	r0, [r7]
	movs	r2, #0
	ldr	r1, [r0, #0x40]
	bic	r1, r1, #1
	str	r1, [r0, #0x40]
	movs	r1, #0x80
	str.w	r8, [r0, #0x44]
	str.w	r8, [r0, #0x50]
	str	r1, [r0, #0x4c]
	ldr	r1, [r0, #0x40]
	orr	r1, r1, #0x9e00
	str	r1, [r0, #0x40]
	ldr	r1, [r0, #0x40]
	bic	r1, r1, #2
	str	r1, [r0, #0x40]
	ldr	r1, [r0, #0x60]
	bic	r1, r1, #2
	str	r1, [r0, #0x60]
	ldr	r0, [r5]
	movs	r1, #1
	orr	r0, r0, #2
	str	r0, [r5]
	ldr	r0, [r5, #0x20]
	orr	r0, r0, #2
	str	r0, [r5, #0x20]
	movs	r0, #0x14
	bl	fn_08041b74
	movw	r1, #0x2d6c
	movt	r1, #0x2000
	str	r0, [r1]
	movs	r0, #0xf
	movs	r1, #1
	movs	r2, #0
	bl	fn_08041b74
	movw	r1, #0x2d70
	movt	r1, #0x2000
	str	r0, [r1]
	movs	r0, #0xa
	movs	r1, #2
	movs	r2, #0
	bl	fn_08041b74
	movw	r1, #0x2d74
	movt	r1, #0x2000
	str	r0, [r1]
	movs	r0, #0xf
	movs	r1, #1
	movs	r2, #0
	bl	fn_08041b74
	movw	r1, #0x2d78
	movt	r1, #0x2000
	str	r0, [r1]
	movs	r0, #1
	movs	r1, #0
	movs	r2, #3
	bl	fn_08041b74
	movw	r5, #0x2d7c
	movt	r5, #0x2000
	str	r0, [r5]
	movs	r0, #1
	movs	r1, #0
	movs	r2, #3
	bl	fn_08041b74
	movw	r6, #0x2d80
	movt	r6, #0x2000
	str	r0, [r6]
	movs	r0, #1
	movs	r1, #0
	movs	r2, #3
	bl	fn_08041b74
	movw	r8, #0x2d84
	movt	r8, #0x2000
	movw	r2, #:lower16:fn_080400b8
	str.w	r0, [r8]
	adr.w	r0, .L0802db3c
	movt	r2, #:upper16:fn_080400b8
	movs	r1, #0xa
	bl	fn_08042d88
	movw	r1, #0x2d88
	movt	r1, #0x2000
	movw	r2, #:lower16:fn_080406c8
	str	r0, [r1]
	adr.w	r0, .L0802db44
	movt	r2, #:upper16:fn_080406c8
	mov.w	r1, #0x3e8
	bl	fn_08042d88
	movw	r1, #0x2d8c
	movt	r1, #0x2000
	str	r0, [r1]
	movw	r7, #0x2d90
	movw	r0, #:lower16:fn_0803da50
	movt	r7, #0x2000
	movt	r0, #:upper16:fn_0803da50
	adr.w	r1, .L0802db4c
	mov.w	r2, #0x180
	movs	r3, #1
	str	r7, [sp]
	bl	fn_080426a0
	movw	r7, #0x2d94
	movw	r0, #:lower16:fn_08040008
	movt	r7, #0x2000
	movt	r0, #:upper16:fn_08040008
	adr.w	r1, .L0802db54
	movs	r2, #0x80
	movs	r3, #4
	str	r7, [sp]
	bl	fn_080426a0
	movw	r7, #0x2d98
	movw	r0, #:lower16:fn_0804009c
	movt	r7, #0x2000
	movt	r0, #:upper16:fn_0804009c
	adr.w	r1, .L0802db58
	mov.w	r2, #0x100
	movs	r3, #2
	str	r7, [sp]
	bl	fn_080426a0
	movw	r7, #0x2d9c
	movw	r0, #:lower16:fn_0803e454
	movt	r7, #0x2000
	movt	r0, #:upper16:fn_0803e454
	adr.w	r1, .L0802db5c
	movs	r2, #0x80
	movs	r3, #3
	str	r7, [sp]
	bl	fn_080426a0
	movw	r7, #0x2da0
	movw	r0, #:lower16:fn_0803e3f4
	movt	r7, #0x2000
	movt	r0, #:upper16:fn_0803e3f4
	adr.w	r1, .L0802db64
	movs	r2, #0x40
	movs	r3, #2
	str	r7, [sp]
	bl	fn_080426a0
	movw	r7, #0x2da4
	movw	r0, #:lower16:fn_0803dac0
	movt	r7, #0x2000
	movt	r0, #:upper16:fn_0803dac0
	adr.w	r1, .L0802db6c
	movs	r2, #0x80
	movs	r3, #3
	str	r7, [sp]
	bl	fn_080426a0
	ldr	r0, [r6]
	movs	r1, #0
	movs	r2, #0
	bl	queue_send_timeout
	ldr	r0, [r5]
	movs	r1, #0
	bl	semaphore_take_timeout
	ldr.w	r0, [r8]
	movs	r1, #0
	bl	semaphore_take_timeout
	ldr	r0, [r4]
	movw	r10, #0xf8
	uxtb	r1, r0
	cmp	r1, #0x55
	movt	r10, #0x2000
	beq.n	.L0802cdae
	cmp	r1, #0xaa
	bne.w	.L0802d198
	movs	r1, #8
	strb.w	r1, [r10, #0xf68]
.L0802cdae:
	lsrs	r1, r0, #8
	lsrs	r2, r0, #0x10
	lsrs	r0, r0, #0x18
	strb.w	r1, [r10]
	strb.w	r2, [r10, #1]
	strb.w	r0, [r10, #2]
	ldr	r0, [r4, #4]
	str.w	r0, [r10, #3]
	ldr	r0, [r4, #8]
	lsrs	r1, r0, #8
	lsrs	r2, r0, #0x10
	lsrs	r3, r0, #0x18
	strb.w	r0, [r10, #7]
	strb.w	r1, [r10, #0x14]
	strb.w	r2, [r10, #0x16]
	strb.w	r3, [r10, #0x17]
	add.w	r3, r4, #0xc
	ldmia	r3, {r0, r1, r2, r3}
	str.w	r1, [r10, #0x1a]
	lsrs	r7, r0, #8
	lsrs	r6, r0, #0x10
	lsrs	r5, r0, #0x18
	strb.w	r0, [r10, #0x18]
	strb.w	r7, [r10, #0x2d]
	lsrs	r0, r2, #8
	lsrs	r1, r2, #0x10
	lsrs	r7, r2, #0x18
	strb.w	r6, [r10, #0x34]
	strb.w	r5, [r10, #0x35]
	strb.w	r2, [r10, #0x3c]
	strb.w	r0, [r10, #0x23a]
	strb.w	r1, [r10, #0x354]
	strb.w	r7, [r10, #0xf39]
	str.w	r3, [r10, #0x4c]
	add.w	r3, r4, #0x1c
	ldmia	r3, {r0, r1, r2, r3}
	str.w	r1, [r10, #0x236]
	str.w	r0, [r10, #0x232]
	lsrs	r0, r2, #8
	lsrs	r1, r2, #0x10
	lsrs	r7, r2, #0x18
	strb.w	r2, [r10, #0xe58]
	strb.w	r0, [r10, #0xe59]
	strb.w	r1, [r10, #0xe60]
	strb.w	r7, [r10, #0xe61]
	str.w	r3, [r10, #0xe5c]
	ldrd	r0, r1, [r4, #0x2c]
	add.w	r3, r4, #0x38
	str.w	r0, [r10, #0xf60]
	lsrs	r0, r1, #0x10
	lsrs	r2, r1, #0x18
	strh.w	r1, [r10, #0xf64]
	strb.w	r0, [r10, #8]
	strb.w	r2, [r10, #9]
	ldr	r0, [r4, #0x34]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0xa]
	strb.w	r1, [r10, #0x48]
	ldmia	r3, {r0, r1, r2, r3}
	strh.w	r1, [r10, #0x262]
	lsrs	r7, r0, #0x10
	strh.w	r0, [r10, #0x260]
	lsrs	r0, r1, #0x10
	strh.w	r0, [r10, #0x2da]
	lsrs	r0, r2, #0x10
	strh.w	r0, [r10, #0x2dc]
	lsrs	r0, r3, #0x10
	strh.w	r7, [r10, #0x2d8]
	strh.w	r2, [r10, #0x264]
	strh.w	r3, [r10, #0x266]
	strh.w	r0, [r10, #0x2de]
	ldr	r0, [r4, #0x48]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x268]
	strh.w	r1, [r10, #0x2e0]
	ldr	r0, [r4, #0x4c]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x26a]
	strh.w	r1, [r10, #0x2e2]
	ldr	r0, [r4, #0x50]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x26c]
	strh.w	r1, [r10, #0x2e4]
	ldr	r0, [r4, #0x54]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x26e]
	strh.w	r1, [r10, #0x2e6]
	ldr	r0, [r4, #0x58]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x270]
	strh.w	r1, [r10, #0x2e8]
	ldr	r0, [r4, #0x5c]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x272]
	strh.w	r1, [r10, #0x2ea]
	ldr	r0, [r4, #0x60]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x274]
	strh.w	r1, [r10, #0x2ec]
	ldr	r0, [r4, #0x64]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x276]
	strh.w	r1, [r10, #0x2ee]
	ldr	r0, [r4, #0x68]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x278]
	strh.w	r1, [r10, #0x2f0]
	ldr	r0, [r4, #0x6c]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x27a]
	strh.w	r1, [r10, #0x2f2]
	ldr	r0, [r4, #0x70]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x27c]
	strh.w	r1, [r10, #0x2f4]
	ldr	r0, [r4, #0x74]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x27e]
	strh.w	r1, [r10, #0x2f6]
	ldr	r0, [r4, #0x78]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x280]
	strh.w	r1, [r10, #0x2f8]
	ldr	r0, [r4, #0x7c]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x282]
	strh.w	r1, [r10, #0x2fa]
	ldr.w	r0, [r4, #0x80]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x284]
	strh.w	r1, [r10, #0x2fc]
	ldr.w	r0, [r4, #0x84]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x286]
	strh.w	r1, [r10, #0x2fe]
	ldr.w	r0, [r4, #0x88]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x288]
	strh.w	r1, [r10, #0x300]
	ldr.w	r0, [r4, #0x8c]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x28a]
	strh.w	r1, [r10, #0x302]
	ldr.w	r0, [r4, #0x90]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x28c]
	strh.w	r1, [r10, #0x304]
	ldr.w	r0, [r4, #0x94]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x28e]
	strh.w	r1, [r10, #0x306]
	ldr.w	r0, [r4, #0x98]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x290]
	strh.w	r1, [r10, #0x308]
	ldr.w	r0, [r4, #0x9c]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x292]
	strh.w	r1, [r10, #0x30a]
	ldr.w	r0, [r4, #0xa0]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x294]
	strh.w	r1, [r10, #0x30c]
	ldr.w	r0, [r4, #0xa4]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x296]
	strh.w	r1, [r10, #0x30e]
	ldr.w	r0, [r4, #0xa8]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x298]
	strh.w	r1, [r10, #0x310]
	ldr.w	r0, [r4, #0xac]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x29a]
	strh.w	r1, [r10, #0x312]
	ldr.w	r0, [r4, #0xb0]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x29c]
	strh.w	r1, [r10, #0x314]
	ldr.w	r0, [r4, #0xb4]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x29e]
	strh.w	r1, [r10, #0x316]
	ldr.w	r0, [r4, #0xb8]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2a0]
	strh.w	r1, [r10, #0x318]
	ldr.w	r0, [r4, #0xbc]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2a2]
	strh.w	r1, [r10, #0x31a]
	ldr.w	r0, [r4, #0xc0]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2a4]
	strh.w	r1, [r10, #0x31c]
	ldr.w	r0, [r4, #0xc4]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2a6]
	strh.w	r1, [r10, #0x31e]
	ldr.w	r0, [r4, #0xc8]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2a8]
	strh.w	r1, [r10, #0x320]
	ldr.w	r0, [r4, #0xcc]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2aa]
	strh.w	r1, [r10, #0x322]
	ldr.w	r0, [r4, #0xd0]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2ac]
	strh.w	r1, [r10, #0x324]
	ldr.w	r0, [r4, #0xd4]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2ae]
	strh.w	r1, [r10, #0x326]
	ldr.w	r0, [r4, #0xd8]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2b0]
	strh.w	r1, [r10, #0x328]
	ldr.w	r0, [r4, #0xdc]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2b2]
	strh.w	r1, [r10, #0x32a]
	ldr.w	r0, [r4, #0xe0]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2b4]
	strh.w	r1, [r10, #0x32c]
	ldr.w	r0, [r4, #0xe4]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2b6]
	strh.w	r1, [r10, #0x32e]
	ldr.w	r0, [r4, #0xe8]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2b8]
	strh.w	r1, [r10, #0x330]
	ldr.w	r0, [r4, #0xec]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2ba]
	strh.w	r1, [r10, #0x332]
	ldr.w	r0, [r4, #0xf0]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2bc]
	strh.w	r1, [r10, #0x334]
	ldr.w	r0, [r4, #0xf4]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2be]
	strh.w	r1, [r10, #0x336]
	ldr.w	r0, [r4, #0xf8]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2c0]
	strh.w	r1, [r10, #0x338]
	ldr.w	r0, [r4, #0xfc]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2c2]
	strh.w	r1, [r10, #0x33a]
	ldr.w	r0, [r4, #0x100]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2c4]
	strh.w	r1, [r10, #0x33c]
	ldr.w	r0, [r4, #0x104]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2c6]
	strh.w	r1, [r10, #0x33e]
	ldr.w	r0, [r4, #0x108]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2c8]
	strh.w	r1, [r10, #0x340]
	ldr.w	r0, [r4, #0x10c]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2ca]
	strh.w	r1, [r10, #0x342]
	ldr.w	r0, [r4, #0x110]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2cc]
	strh.w	r1, [r10, #0x344]
	ldr.w	r0, [r4, #0x114]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2ce]
	strh.w	r1, [r10, #0x346]
	ldr.w	r0, [r4, #0x118]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2d0]
	strh.w	r1, [r10, #0x348]
	ldr.w	r0, [r4, #0x11c]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2d2]
	strh.w	r1, [r10, #0x34a]
	ldr.w	r0, [r4, #0x120]
	lsrs	r1, r0, #0x10
	strh.w	r0, [r10, #0x2d4]
	strh.w	r1, [r10, #0x34c]
	ldr.w	r1, [r4, #0x124]
	lsrs	r0, r1, #0x10
	strh.w	r1, [r10, #0x2d6]
	strh.w	r0, [r10, #0x34e]
	ldr.w	r1, [r4, #0x128]
	strh.w	r1, [r10, #0x350]
	ldr.w	r1, [r4, #0x12c]
	strh.w	r1, [r10, #0x352]
	b.n	.L0802d1a8
.L0802d198:
	movs	r0, #8
	strb.w	r0, [r10, #0xf68]
	ldrh.w	r0, [r10, #0x34e]
	movs	r1, #1
	strb.w	r1, [r10, #0xf60]
.L0802d1a8:
	movw	r11, #0x1018
	movw	r1, #0xffff
	movt	r11, #0x4002
	cmp	r0, r1
	beq.n	.L0802d1be
	cmp	r0, #0
	bne.w	.L0802d50a
.L0802d1be:
	movw	lr, #0x65e
	movw	r2, #0xf8
	movt	lr, #0x65b
	movt	r2, #0x2000
	movw	r7, #0x65a
	str.w	lr, [r2, #0x264]
	movw	r2, #0xf8
	movt	r7, #0x669
	movt	r2, #0x2000
	movw	r5, #0x65f
	str.w	r7, [r2, #0x268]
	movw	r2, #0xf8
	movt	r5, #0x65a
	movt	r2, #0x2000
	movw	r1, #0x657
	str.w	r5, [r2, #0x26c]
	movw	r2, #0xf8
	movt	r1, #0x655
	movt	r2, #0x2000
	movw	r6, #0x662
	str.w	r1, [r2, #0x270]
	movw	r1, #0xf8
	movt	r6, #0x663
	movt	r1, #0x2000
	movw	r4, #0x659
	str.w	r6, [r1, #0x274]
	movw	r1, #0xf8
	movt	r4, #0x659
	movt	r1, #0x2000
	movw	r0, #0x657
	str.w	r4, [r1, #0x278]
	movw	r1, #0xf8
	movt	r0, #0x667
	movt	r1, #0x2000
	str.w	r0, [r1, #0x27c]
	movw	r1, #0xf8
	movw	r2, #0x65d
	movt	r1, #0x2000
	movt	r2, #0x64b
	str.w	r2, [r1, #0x2d8]
	movw	r1, #0xf8
	movw	r2, #0x63f
	movt	r1, #0x2000
	movt	r2, #0x63c
	movw	r8, #0x63a
	str.w	r2, [r1, #0x2dc]
	movw	r1, #0xf8
	movt	r8, #0x658
	movt	r1, #0x2000
	movw	r9, #0x648
	str.w	r8, [r1, #0x2e0]
	movw	r1, #0xf8
	movt	r9, #0x63f
	movt	r1, #0x2000
	movw	r3, #0x63a
	str.w	r9, [r1, #0x2e4]
	movw	r1, #0xf8
	movt	r3, #0x639
	movt	r1, #0x2000
	movw	r10, #0x64b
	str.w	r3, [r1, #0x2e8]
	movw	r1, #0xf8
	movt	r10, #0x64a
	movt	r1, #0x2000
	movw	r0, #0x637
	str.w	r10, [r1, #0x2ec]
	movw	r10, #0xf8
	movt	r0, #0x656
	movt	r10, #0x2000
	strd	r3, r0, [r10, #0x2f0]
	movw	r0, #0x65d
	strh.w	r0, [r10, #0x280]
	movw	r0, #0x646
	strh.w	r0, [r10, #0x2f8]
	movw	r0, #0x658
	movt	r0, #0x655
	str.w	r0, [r10, #0x282]
	movw	r0, #0x63f
	movt	r0, #0x639
	str.w	r0, [r10, #0x2fa]
	movw	r0, #0x655
	strh.w	r0, [r10, #0x286]
	movw	r0, #0x637
	strh.w	r0, [r10, #0x2fe]
	movw	r0, #0x665
	movt	r0, #0x65d
	movw	r2, #0x658
	movw	r7, #0x656
	add.w	r9, r10, #0x288
	movt	r2, #0x65a
	movt	r7, #0x666
	movw	r3, #0x63b
	stm.w	r9, {r0, r2, r7}
	movw	r0, #0xcc7
	movw	r5, #0x65c
	movw	r1, #0x655
	movt	r3, #0x639
	movt	r0, #0xcb4
	movt	r5, #0x658
	movt	r1, #0x654
	strd	r3, r0, [r10, #0x310]
	movw	r0, #0xcbc
	strd	r5, r1, [r10, #0x294]
	strh.w	r0, [r10, #0x2a0]
	movw	r0, #0xca7
	movw	r1, #0xcc5
	strh.w	r0, [r10, #0x318]
	movw	r0, #0xcba
	movt	r1, #0xcbb
	movt	r0, #0xcb9
	str.w	r1, [r10, #0x2a6]
	str.w	r1, [r10, #0x2ba]
	movw	r1, #0xcb1
	str.w	r0, [r10, #0x2a2]
	movw	r0, #0xca5
	movt	r1, #0xca8
	movw	r11, #0x667
	movw	r12, #0xf8
	movt	r0, #0xca3
	str.w	r1, [r10, #0x334]
	movw	r1, #0xcb6
	movt	r11, #0x665
	movt	r12, #0x2000
	str.w	r0, [r10, #0x31a]
	movw	r0, #0xcc2
	movt	r1, #0xcb2
	str.w	r11, [r12, #0x260]
	movw	r12, #0x654
	movw	lr, #0x63e
	strh.w	r0, [r10, #0x31e]
	movw	r3, #0xcb6
	movw	r7, #0xcb3
	str.w	r1, [r10, #0x2be]
	movw	r1, #0xca3
	strh.w	r0, [r10, #0x2ce]
	strh.w	r0, [r10, #0x346]
	movw	r0, #0xcb8
	movt	r12, #0x64a
	movt	lr, #0x63a
	movw	r6, #0xcce
	movw	r2, #0xcb2
	movt	r3, #0xcb4
	movt	r7, #0xcc4
	strh.w	r1, [r10, #0x338]
	movw	r1, #0xcb2
	strh.w	r0, [r10, #0x2d0]
	movw	r0, #0xcb3
	movt	r6, #0xcc4
	strd	r12, lr, [r10, #0x300]
	movt	r2, #0xcaa
	str.w	r3, [r10, #0x2aa]
	movw	r3, #0xca4
	str.w	r7, [r10, #0x2ae]
	movw	r7, #0xcf6
	add.w	r12, r10, #0x320
	strh.w	r1, [r10, #0x2c2]
	mov.w	r1, #0xca0
	strh.w	r0, [r10, #0x2d2]
	movw	r0, #0xcab
	str.w	r6, [r10, #0x29c]
	movt	r3, #0xca4
	movt	r7, #0xcb1
	movw	r6, #0xcc2
	movw	r5, #0xcbb
	stm.w	r12, {r2, r3, r7}
	strh.w	r1, [r10, #0x33a]
	movw	r1, #0xccb
	movw	r2, #0xcb9
	strh.w	r0, [r10, #0x34a]
	mov.w	r0, #0xcb0
	movt	r6, #0xcbb
	movt	r5, #0xcb9
	strh.w	r1, [r10, #0x2c4]
	mov.w	r1, #0xcc0
	strh.w	r2, [r10, #0x2c8]
	movw	r2, #0xca9
	strh.w	r0, [r10, #0x2d4]
	movw	r0, #0xcaf
	movw	r11, #0x1018
	movw	r8, #0x63b
	movw	r4, #0x648
	str.w	r6, [r10, #0x2b2]
	movw	r6, #0xca6
	str.w	r5, [r10, #0x2b6]
	movw	r5, #0xca2
	strh.w	r1, [r10, #0x33c]
	movw	r1, #0xcc1
	strh.w	r2, [r10, #0x340]
	movw	r2, #0xcb7
	strh.w	r0, [r10, #0x2d6]
	movw	r0, #0xca4
	movt	r11, #0x4002
	movt	r8, #0x659
	movt	r4, #0x640
	movt	r6, #0xca3
	movt	r5, #0xcc1
	strh.w	r1, [r10, #0x2c6]
	movw	r1, #0xcb4
	strh.w	r2, [r10, #0x2ca]
	movw	r3, #0xca6
	strh.w	r2, [r10, #0x2cc]
	movw	r2, #0xca4
	movt	r0, #0x5fa
	strd	r8, r4, [r10, #0x308]
	strd	r6, r5, [r10, #0x32c]
	strh.w	r1, [r10, #0x33e]
	strh.w	r3, [r10, #0x342]
	strh.w	r2, [r10, #0x344]
	strh.w	r1, [r10, #0x348]
	strh.w	r3, [r10, #0x34c]
	str.w	r0, [r10, #0x34e]
.L0802d50a:
	ldr.w	r0, [r11, #4]
	movs	r2, #8
	orr	r0, r0, #0x8000
	str.w	r0, [r11, #4]
	ldr.w	r0, [r11]
	movt	r2, #0x4001
	orr	r0, r0, #8
	str.w	r0, [r11]
	ldr.w	r0, [r11]
	movs	r1, #2
	orr	r0, r0, #8
	str.w	r0, [r11]
	ldr.w	r0, [r11]
	add	r4, sp, #0x40
	orr	r0, r0, #8
	str.w	r0, [r11]
	ldr.w	r0, [r11]
	movw	r6, #0x3c08
	orr	r0, r0, #8
	str.w	r0, [r11]
	ldr	r0, [r2, #0x28]
	ldr	r5, [sp, #0x10]
	bfi	r0, r1, #0x10, #3
	str	r0, [r2, #0x28]
	movw	r0, #0x1800
	movt	r0, #0x110
	movw	r8, #0x3000
	str	r0, [sp, #0x44]
	mov.w	r9, #0x40
	mov	r0, r5
	mov	r1, r4
	movt	r6, #0x4000
	movt	r8, #0x4000
	str.w	r9, [sp, #0x40]
	bl	set_nibble_fields_from_bit_mask
	movs	r0, #8
	movw	r7, #0x818
	str	r0, [sp, #0x40]
	mov	r0, r5
	mov	r1, r4
	strh.w	r7, [sp, #0x45]
	bl	set_nibble_fields_from_bit_mask
	movs	r0, #0x18
	strh.w	r0, [sp, #0x45]
	movs	r0, #0x10
	str	r0, [sp, #0x40]
	mov	r0, r5
	mov	r1, r4
	bl	set_nibble_fields_from_bit_mask
	movs	r0, #0x20
	str	r0, [sp, #0x40]
	mov	r0, r5
	mov	r1, r4
	strh.w	r7, [sp, #0x45]
	bl	set_nibble_fields_from_bit_mask
	movw	r0, #0xfc10
	movw	r4, #0x1000
	movt	r0, #0xffff
	movt	r4, #0x4001
	str.w	r9, [r4, r0]
	mov.w	r0, #0x100
	str	r0, [sp, #0x60]
	movw	r0, #0x100
	movt	r0, #0x101
	str	r0, [sp, #0x64]
	add.w	r0, r8, #0xc00
	add	r1, sp, #0x60
	bl	fn_0803d848
	ldr.w	r0, [r6, #-4]
	movs	r7, #0
	orr	r0, r0, #2
	str.w	r0, [r6, #-4]
	ldr.w	r0, [r6, #-4]
	add	r1, sp, #0x40
	orr	r0, r0, #1
	str.w	r0, [r6, #-4]
	ldr.w	r0, [r8, #0xc00]
	orr	r0, r0, #0x40
	str.w	r0, [r8, #0xc00]
	ldr.w	r0, [r11]
	orr	r0, r0, #0x10
	str.w	r0, [r11]
	movs	r0, #1
	strb.w	r0, [sp, #0x47]
	movw	r0, #0x1018
	strh.w	r0, [sp, #0x45]
	mov	r0, r4
	strb.w	r7, [sp, #0x44]
	str.w	r9, [sp, #0x40]
	bl	set_nibble_fields_from_bit_mask
	movw	r0, #0x2b1c
	str.w	r9, [r4, #0x10]
	movt	r0, #0x2000
	ldr	r0, [r0]
	movw	r5, #0xe010
	add.w	r0, r0, r0, lsl #2
	lsls	r0, r0, #1
	movt	r5, #0xe000
	str	r0, [r5, #4]
	str	r7, [r5, #8]
	ldr	r0, [r5]
	orr	r0, r0, #1
	str	r0, [r5]
.L0802d660:
	ldr	r0, [r5]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802d688
	ldr	r0, [r5]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802d688
	ldr	r0, [r5]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802d688
	ldr	r0, [r5]
	and	r0, r0, #0x10001
	cmp	r0, #1
	beq.n	.L0802d660
.L0802d688:
	ldr	r0, [r5]
	movw	r1, #0x2b20
	bic	r0, r0, #1
	str	r0, [r5]
	movs	r0, #0
	str	r0, [r5, #8]
	movt	r1, #0x2000
	ldr	r1, [r1]
	movw	r12, #0xfc14
	str	r1, [r5, #4]
	str	r0, [r5, #8]
	ldr	r0, [r5]
	movt	r12, #0xffff
	orr	r0, r0, #1
	str	r0, [r5]
	nop
.L0802d6b4:
	ldr	r0, [r5]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802d6dc
	ldr	r0, [r5]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802d6dc
	ldr	r0, [r5]
	and	r0, r0, #0x10001
	cmp	r0, #1
	bne.n	.L0802d6dc
	ldr	r0, [r5]
	and	r0, r0, #0x10001
	cmp	r0, #1
	beq.n	.L0802d6b4
.L0802d6dc:
	ldr	r0, [r5]
	movw	r9, #0x2d78
	bic	r0, r0, #1
	movw	lr, #0xfc10
	str	r0, [r5]
	movs	r0, #0
	movs	r2, #0x64
	movs	r1, #0x32
	movt	r9, #0x2000
	movt	lr, #0xffff
	str	r0, [r5, #8]
	b.n	.L0802d70e
	.byte	0x00, 0xbf	@ padding
.L0802d700:
	ldr	r3, [r5]
	bic	r3, r3, #1
	str	r3, [r5]
	lsls	r3, r2, #0x10
	str	r0, [r5, #8]
	beq.n	.L0802d76e
.L0802d70e:
	uxth	r3, r2
	cmp	r3, #0x33
	bcc.n	.L0802d728
	movw	r3, #0x2b20
	movt	r3, #0x2000
	ldr	r3, [r3]
	subs	r2, #0x32
	muls	r3, r1
	str	r3, [r5, #4]
	b.n	.L0802d738
	.byte	0x00, 0xbf	@ padding
.L0802d728:
	movw	r2, #0x2b20
	movt	r2, #0x2000
	ldr	r2, [r2]
	muls	r2, r3
	str	r2, [r5, #4]
	movs	r2, #0
.L0802d738:
	str	r0, [r5, #8]
	ldr	r3, [r5]
	orr	r3, r3, #1
	str	r3, [r5]
	nop
.L0802d744:
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802d700
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802d700
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802d700
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	beq.n	.L0802d744
	b.n	.L0802d700
.L0802d76e:
	movs	r0, #0x40
	str.w	r0, [r4, lr]
.L0802d774:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802d78e
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802d774
.L0802d78e:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802d794:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802d7ae
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802d794
.L0802d7ae:
	ldr	r0, [r6, #4]
	movs	r0, #0x40
	str.w	r0, [r4, r12]
	nop
.L0802d7b8:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802d7d2
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802d7b8
.L0802d7d2:
	movs	r0, #5
	str	r0, [r6, #4]
	nop
.L0802d7d8:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802d7f2
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802d7d8
.L0802d7f2:
	ldr	r0, [r6, #4]
.L0802d7f4:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802d80e
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802d7f4
.L0802d80e:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802d814:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802d82e
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802d814
.L0802d82e:
	ldr	r0, [r6, #4]
	movs	r0, #0x40
	str.w	r0, [r4, lr]
	nop
.L0802d838:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802d852
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802d838
.L0802d852:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802d858:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802d872
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802d858
.L0802d872:
	ldr	r0, [r6, #4]
	movs	r2, #0x64
	movs	r0, #0x32
	movs	r1, #0
	b.n	.L0802d88a
.L0802d87c:
	ldr	r3, [r5]
	bic	r3, r3, #1
	str	r3, [r5]
	lsls	r3, r2, #0x10
	str	r1, [r5, #8]
	beq.n	.L0802d8ea
.L0802d88a:
	uxth	r3, r2
	cmp	r3, #0x33
	bcc.n	.L0802d8a4
	movw	r3, #0x2b20
	movt	r3, #0x2000
	ldr	r3, [r3]
	subs	r2, #0x32
	muls	r3, r0
	str	r3, [r5, #4]
	b.n	.L0802d8b4
	.byte	0x00, 0xbf	@ padding
.L0802d8a4:
	movw	r2, #0x2b20
	movt	r2, #0x2000
	ldr	r2, [r2]
	muls	r2, r3
	str	r2, [r5, #4]
	movs	r2, #0
.L0802d8b4:
	str	r1, [r5, #8]
	ldr	r3, [r5]
	orr	r3, r3, #1
	str	r3, [r5]
	nop
.L0802d8c0:
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802d87c
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802d87c
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802d87c
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	beq.n	.L0802d8c0
	b.n	.L0802d87c
.L0802d8ea:
	movs	r0, #0x40
	str.w	r0, [r4, r12]
.L0802d8f0:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802d90a
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802d8f0
.L0802d90a:
	movs	r0, #0x12
	str	r0, [r6, #4]
	nop
.L0802d910:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802d92a
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802d910
.L0802d92a:
	ldr	r0, [r6, #4]
.L0802d92c:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802d946
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802d92c
.L0802d946:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802d94c:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802d966
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802d94c
.L0802d966:
	ldr	r0, [r6, #4]
	movs	r0, #0x40
	str.w	r0, [r4, lr]
	nop
.L0802d970:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802d98a
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802d970
.L0802d98a:
	movs	r0, #0
	str	r0, [r6, #4]
	nop
.L0802d990:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
	bne.n	.L0802d9aa
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	beq.n	.L0802d990
.L0802d9aa:
	ldr	r0, [r6, #4]
	movs	r2, #0x64
	movs	r0, #0x32
	movs	r1, #0
	b.n	.L0802d9c2
.L0802d9b4:
	ldr	r3, [r5]
	bic	r3, r3, #1
	str	r3, [r5]
	lsls	r3, r2, #0x10
	str	r1, [r5, #8]
	beq.n	.L0802da22
.L0802d9c2:
	uxth	r3, r2
	cmp	r3, #0x33
	bcc.n	.L0802d9dc
	movw	r3, #0x2b20
	movt	r3, #0x2000
	ldr	r3, [r3]
	subs	r2, #0x32
	muls	r3, r0
	str	r3, [r5, #4]
	b.n	.L0802d9ec
	.byte	0x00, 0xbf	@ padding
.L0802d9dc:
	movw	r2, #0x2b20
	movt	r2, #0x2000
	ldr	r2, [r2]
	muls	r2, r3
	str	r2, [r5, #4]
	movs	r2, #0
.L0802d9ec:
	str	r1, [r5, #8]
	ldr	r3, [r5]
	orr	r3, r3, #1
	str	r3, [r5]
	nop
.L0802d9f8:
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802d9b4
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802d9b4
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	bne.n	.L0802d9b4
	ldr	r3, [r5]
	and	r3, r3, #0x10001
	cmp	r3, #1
	beq.n	.L0802d9f8
	b.n	.L0802d9b4
.L0802da22:
	movs	r0, #0x40
	str.w	r0, [r4, r12]
.L0802da28:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	itttt	pl
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	ldrpl	r0, [r6]
	lslspl.w	r0, r0, #0x1e
	bmi.n	.L0802da42
	ldr	r0, [r6]
	lsls	r0, r0, #0x1e
	bpl.n	.L0802da28
.L0802da42:
	movs	r0, #0x15
	str	r0, [r6, #4]
	nop
.L0802da48:
	ldr	r0, [r6]
	lsls	r0, r0, #0x1f
	itttt	eq
	ldreq	r0, [r6]
	lslseq.w	r0, r0, #0x1f
