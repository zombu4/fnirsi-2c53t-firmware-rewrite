@ meter_link_39.s - byte-wise frame receiver/transmitter for the I/O block at 0x40004400, the digit-code lookup and the frame-decoding task body
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0802e7b4 - byte-wise frame receiver / transmitter for the I/O block at
@ 0x40004400. No parameters, no return value. The meaning of the frames is not
@ determined from the code.
@
@ Receive part (0x0802e7e4): runs when bit5 of word 0x4000440c and bit5 of word
@ 0x40004400 are both set. Byte b = word 0x40004404; b is stored at
@ 0x20004e11[index] (index byte 0x20004e10, incremented afterwards).
@ Frame rules: the first byte must be 0x5a or 0xaa, else the index is reset to
@ 0; at index 2 the pair must be 0x5a,0xa5 or 0xaa,0x55 (byte 0x20004e12), else
@ the index is reset. For 0xaa,0x55 frames at index 10: if byte 0x20004e14 ==
@ byte 0x20000008 and byte 0x20004e18 == 0xaa the index is reset to 0,
@ otherwise collection continues. When the index reaches 12 it is reset to 0
@ and, if byte 0x2000000f == 10 and byte 0x20001034 == 0, it calls
@ 0804209c (semaphore_give_from_isr) with (queue = word at 0x20002d7c, &wake);
@ if wake != 0 it writes 0x10000000 to 0xE000ED04 (ICSR) plus DSB/ISB.
@
@ Transmit part (0x0802e7d0): when bit7 of word 0x4000440c and bit7 of word
@ 0x40004400 are set, writes byte 0x20000005[byte 0x2000000f] to 0x40004404,
@ increments 0x2000000f, and when it reaches 10 clears bit7 of word 0x4000440c
@ (read-modify-write).
@ ----------------------------------------------------------------------------
	.section .text.fn_0802e7b4,"ax",%progbits
	.global fn_0802e7b4
	.thumb_func
	.type fn_0802e7b4, %function
fn_0802e7b4:
	push	{r4, lr}
	sub	sp, #8
	movw	r4, #0x440c
	movt	r4, #0x4000
	ldr	r0, [r4]
	lsls	r0, r0, #0x1a
	itt	mi
	ldrmi.w	r0, [r4, #-0xc]
	lslsmi.w	r0, r0, #0x1a
	bmi.n	.L0802e7e4
.L0802e7d0:
	ldr	r0, [r4]
	lsls	r0, r0, #0x18
	itt	mi
	ldrmi.w	r0, [r4, #-0xc]
	lslsmi.w	r0, r0, #0x18
	bmi.n	.L0802e822
.L0802e7e0:
	add	sp, #8
	pop	{r4, pc}
.L0802e7e4:
	movw	r12, #0x4e10
	movt	r12, #0x2000
	ldr.w	r2, [r4, #-0x8]
	bl	meter_log_byte			@ this rewrite: METER_LOG records r2 (keeps every register)
	ldrb.w	r0, [r12]
	movw	r1, #0x4e11
	movt	r1, #0x2000
	strb	r2, [r1, r0]
	ldrb	r2, [r1]
	adds	r3, r0, #1
	strb.w	r3, [r12]
	cbz	r0, .L0802e850
	uxtb	r3, r3
	cmp	r3, #0x2
	bne.n	.L0802e85a
	ldrb	r1, [r1, #0x1]
	cmp	r2, #0x5a
	bne.n	.L0802e818
	cmp	r1, #0xa5
	bne.n	.L0802e8dc
.L0802e818:
	cmp	r2, #0xaa
	bne.n	.L0802e7d0
	cmp	r1, #0x55
	bne.n	.L0802e8dc
	b.n	.L0802e7d0
.L0802e822:
	movw	r0, #0xf
	movt	r0, #0x2000
	ldrb	r1, [r0]
	adds	r2, r1, #1
	strb	r2, [r0]
	movw	r0, #0x5
	movt	r0, #0x2000
	uxtb	r3, r2
	ldrb	r0, [r0, r1]
	cmp	r3, #0xa
	str.w	r0, [r4, #-0x8]
	bne.n	.L0802e7e0
	ldr	r0, [r4]
	bic.w	r0, r0, #0x80
	str	r0, [r4]
	add	sp, #8
	pop	{r4, pc}
.L0802e850:
	cmp	r2, #0x5a
	beq.n	.L0802e7d0
	cmp	r2, #0xaa
	beq.n	.L0802e7d0
	b.n	.L0802e8dc
.L0802e85a:
	cmp	r2, #0xaa
	it	eq
	cmpeq	r3, #0xa
	beq.n	.L0802e8bc
.L0802e862:
	cmp	r3, #0xc
	bne.n	.L0802e7d0
	movw	r0, #0xf
	movt	r0, #0x2000
	ldrb	r0, [r0]
	movs	r1, #0x0
	cmp	r0, #0xa
	strb.w	r1, [r12]
	bne.n	.L0802e7d0
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0xf3c]
	cmp	r0, #0x0
	bne.n	.L0802e7d0
	movw	r0, #0x2d7c
	movt	r0, #0x2000
	movs	r1, #0x0
	ldr	r0, [r0]
	str	r1, [sp, #0x4]
	add	r1, sp, #0x4
	bl	semaphore_give_from_isr
	ldr	r0, [sp, #0x4]
	cmp	r0, #0x0
	beq.n	.L0802e7d0
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0]
	dsb	sy
	isb	sy
	b.n	.L0802e7d0
.L0802e8bc:
	ldrb	r0, [r1, #0x1]
	cmp	r0, #0x55
	bne.n	.L0802e862
	movw	r0, #0x5
	movt	r0, #0x2000
	ldrb	r0, [r0, #0x3]
	ldrb	r2, [r1, #0x3]
	cmp	r2, r0
	bne.w	.L0802e7d0
	ldrb	r0, [r1, #0x7]
	cmp	r0, #0xaa
	bne.w	.L0802e7d0
.L0802e8dc:
	movs	r0, #0x0
	strb.w	r0, [r12]
	b.n	.L0802e7d0

@ ----------------------------------------------------------------------------
@ map_masked_byte_to_code - maps an 8-bit pattern to a small code.
@ Param r0 = 8-bit pattern; returns a small code in r0; pure lookup, no memory
@ access. r0 is masked with 0xef (bit 4 ignored) and mapped:
@ 0xeb->0, 0x0a->1, 0xad->2, 0x8f->3, 0x4e->4, 0xc7->5, 0xe7->6, 0x8a->7,
@ 0xef->8, 0xcf->9 (ten patterns mapped to the codes 0..9), 0x00->0x10,
@ 0x04->0xf, 0x23->0xb, 0x24->0x14, 0x27->0xd, 0x61->0xe, 0x65->0xc,
@ 0xe1->0x11, 0xe5->0x13, 0xec->0x12, 0xee->10, every other masked value ->0xff.
@ The 0xeb case returns the 0 loaded before the jump table (movs r0,#0 at
@ 0x0803af0c). Caller 0803dac0 (fn_0803dac0) feeds it nibble pairs of the frame
@ bytes at 0x20004e13..0x20004e17.
@ Values above 0x64 use a tbh table (halfword entries, base 0x0803af12, index =
@ masked value - 0x8a); values 0x00..0x64 use a tbb table (byte entries, base
@ 0x0803afea, index = masked value, valid up to 0x27).
@ ----------------------------------------------------------------------------
	.section .text.map_masked_byte_to_code,"ax",%progbits
	.global map_masked_byte_to_code
	.thumb_func
	.type map_masked_byte_to_code, %function
map_masked_byte_to_code:
	and.w	r0, r0, #0xef
	cmp	r0, #0x64
	ble.w	.L0803afe2
	sub.w	r1, r0, #0x8a
	cmp	r1, #0x65
	bhi.w	.L0803b028
	movs	r0, #0x0
	tbh	[pc, r1, lsl #1]
.L0803af12:
	.short	(.L0803afde - .L0803af12)/2	@ index 0x00 (0x8a): code 7
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2	@ 0803af14..0803af1a: 0xff
	.short	(.L0803b048 - .L0803af12)/2	@ 0803af1c (masked 0x8f): code 3
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2	@ 0803af1e..0803af56: 29 entries of 0xff
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2
	.short	(.L0803b04c - .L0803af12)/2	@ 0803af58 (masked 0xad): code 2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2	@ 0803af5a..0803af8a: 25 entries of 0xff
	.short	(.L0803b050 - .L0803af12)/2	@ 0803af8c (masked 0xc7): code 5
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b054 - .L0803af12)/2	@ 0803af9c (masked 0xcf): code 9
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b030 - .L0803af12)/2
	.short	(.L0803b058 - .L0803af12)/2	@ 0803afc0: code 0x11
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b05c - .L0803af12)/2	@ 0803afc8: code 0x13
	.short	(.L0803b030 - .L0803af12)/2
	.short	(.L0803b060 - .L0803af12)/2	@ 0803afcc: code 6
	.short	(.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2, (.L0803b030 - .L0803af12)/2
	.short	(.L0803b032 - .L0803af12)/2	@ 0803afd4 (masked 0xeb): returns the 0 loaded before the jump
	.short	(.L0803b064 - .L0803af12)/2	@ 0803afd6: code 0x12
	.short	(.L0803b030 - .L0803af12)/2
	.short	(.L0803b068 - .L0803af12)/2	@ 0803afda: code 10
	.short	(.L0803b06c - .L0803af12)/2	@ 0803afdc: code 8
.L0803afde:
	movs	r0, #0x7
	bx	lr
.L0803afe2:
	cmp	r0, #0x27
	bhi.n	.L0803b016
	tbb	[pc, r0]
.L0803afea:
	.byte	(.L0803b012 - .L0803afea)/2
	.byte	(.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2
	.byte	(.L0803b034 - .L0803afea)/2
	.byte	(.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2
	.byte	(.L0803b038 - .L0803afea)/2
	.byte	(.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2
	.byte	(.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2
	.byte	(.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2
	.byte	(.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2
	.byte	(.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2
	.byte	(.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2
	.byte	(.L0803b03c - .L0803afea)/2
	.byte	(.L0803b040 - .L0803afea)/2
	.byte	(.L0803b030 - .L0803afea)/2, (.L0803b030 - .L0803afea)/2
	.byte	(.L0803b044 - .L0803afea)/2
.L0803b012:
	movs	r0, #0x10
	bx	lr
.L0803b016:
	cmp	r0, #0x4e
	itt	eq
	moveq	r0, #0x4
	bxeq	lr
	cmp	r0, #0x61
	itt	eq
	moveq	r0, #0xe
	bxeq	lr
	b.n	.L0803b030
.L0803b028:
	cmp	r0, #0x65
	itt	eq
	moveq	r0, #0xc
	bxeq	lr
.L0803b030:
	movs	r0, #0xff
.L0803b032:
	bx	lr
.L0803b034:
	movs	r0, #0xf
	bx	lr
.L0803b038:
	movs	r0, #0x1
	bx	lr
.L0803b03c:
	movs	r0, #0xb
	bx	lr
.L0803b040:
	movs	r0, #0x14
	bx	lr
.L0803b044:
	movs	r0, #0xd
	bx	lr
.L0803b048:
	movs	r0, #0x3
	bx	lr
.L0803b04c:
	movs	r0, #0x2
	bx	lr
.L0803b050:
	movs	r0, #0x5
	bx	lr
.L0803b054:
	movs	r0, #0x9
	bx	lr
.L0803b058:
	movs	r0, #0x11
	bx	lr
.L0803b05c:
	movs	r0, #0x13
	bx	lr
.L0803b060:
	movs	r0, #0x6
	bx	lr
.L0803b064:
	movs	r0, #0x12
	bx	lr
.L0803b068:
	movs	r0, #0xa
	bx	lr
.L0803b06c:
	movs	r0, #0x8
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_0803dac0 - task body that decodes the received frame into a value plus
@ mode bytes and derives three scaled values. No parameters; never returns (no
@ return instruction in 0x0803dac0..0x0803e3c9). Its purpose is not determined
@ from the code.
@
@ Loop: waits with 080423a8 (semaphore_take_timeout)(*0x20002d7c, 0xffffffff)
@ until it returns 1, then writes 0 to byte 0x20001024 and decodes four digit
@ codes with 0803aef8 (map_masked_byte_to_code) from the frame bytes b13..b17 at
@ 0x20004e13..0x20004e17:
@   d0 = (b13 & 0xf0) + (b14 & 0xf)    d1 = (b14 & 0xf0) + (b15 & 0xf)
@   d2 = (b15 & 0xf0) + (b16 & 0xf)    d3 = (b16 & 0xf0) + (b17 & 0xf)
@
@ Digit-code patterns, tested in this order, set the status byte 0x2000102d:
@  - (d0,d1,d2,d3) = (10,0xb,0xc,0xd) gives 1 (also 0x20001027 = 0 and
@    0x2000102e = 0 only when 0x20001025 == 0, float 0x20001028 = 0.0);
@  - d1 == 0 and d2 == 0xe gives 2 with float 0x20001028 = 20.0;
@  - all four 0x10 gives 3 (no value stored);
@  - (0x10,0x11,10,0xe) gives 4, sets mode 0x20001025 = 8 and float
@    0x20001028 = 0.0 and skips the mode dispatch at 0803e1b0;
@  - d1 == 0x12, d2 == 10, d3 == 5 gives 5 and float 0x20001028 = 0.0 and, when
@    byte 0x20001055 is 0xb0, sets it to 0xb1 and the mode 0x20001025 = 1;
@  - d1 == 0x13, d2 == 0x14 gives 9, or d3+5 when d3 is 1..3 (unsigned
@    (d3-1) < 3), float 0x20001028 = 0.0;
@  - when none of d0, d1, d2 is 0xff and d3 is not 0xff the status becomes 0 and
@    the reading is d3 + d0*1000 + d1*100 + d2*10 (code 0x10 counts as 0 for
@    d0, d1 and d2; d3 is added as is) as a float, plus 10000.0 when bit3 of b13
@    is set (stored to 0x20001028), then converted to double and divided by
@    10^places (080438e0 double_pow with 10.0 and places) with places = 4 when
@    bit7 of byte 0x20004e19 is set, else 3 when bit4 of b14, else 2 when bit4
@    of b15, else 1 or 0 from bit4 of b16 (places stored to byte 0x2000102c),
@    converted back to float and negated when bit4 of b13 is set, then
@    x*9.0/5.0+32.0 when mode 0x20001025 == 5 and byte 0x20001031 is nonzero;
@    result stored as float 0x20001028, status 0x2000102d = 0 and byte
@    0x20001027 = 0xff;
@  - when a digit code is 0xff the status and value are left unchanged.
@
@ After every frame (all paths except the NaN copy below) a switch on the mode
@ 0x20001025 (0..7; above 7 nothing) writes byte 0x2000102f from bits 4,5,6 of
@ 0x20004e17, bits 0,2,3,5 of 0x20004e18 and byte 0x20001031 (mode 0 also uses
@ bits 0,1 of b13 and the bytes 0x20001027 and 0x2000102e, and is the only mode
@ that writes 0x2000102e and 0x20001027; mode 2 reads 0x2000102e). When
@ 0x2000102e == 2 and the switch result is 1 (mode 1) or 0 with 0x20001027 == 1
@ (mode 0), halfword 0x20001032 = byte-swapped halfword read at 0x20004e1b.
@ Then it calls 080098e0 (fn_080098e0, no arguments set); when the mode is > 8
@ or not in {0,2,8} (bit mask 0x105) and the status byte 0x2000102d is 0 the
@ following block runs, otherwise the loop restarts at the wait:
@  - if the float 0x20001040 is a NaN pattern (|bits| > 0x7f800000) it copies
@    the bytes 0x2000102c, 0x2000102f, 0x20001030 into three entries each
@    (0x2000104c/4d/4e, 0x2000104f/50/51, 0x20001052/53/54), the float
@    0x20001028 into 0x20001040/44/48 and restarts the wait;
@  - otherwise it forms A = 0x20001028 * 1000^byte 0x2000102f, B = 0x20001040 *
@    1000^byte 0x2000104f and C = 0x20001048 * 1000^byte 0x20001051 as doubles
@    (1000^byte 0x20001050 is also computed by 080438e0 and discarded), then:
@    if A <= B (08045dfe double_le) high = B and low = C, except low = A when
@    A < C (not 08045df0 double_ge (A,C)); if A > B high = A and low = C (B vs
@    C is never compared and B is not used); mid = (high-low)*0.5 + low; for
@    high, mid, low in that order it divides by 1000.0 while the magnitude is
@    not below 1000.0 (compare 08045e0c double_lt, at most 4 divisions), stores
@    the division count in 0x2000104f/50/51, stores 2 when the magnitude is
@    >= 100.0, 3 when >= 10.0, else 4 in 0x2000104c/4d/4e, stores the result as
@    float in 0x20001040/44/48 and stores in 0x20001052/53/54 a byte from the
@    mode and the count: modes 6,7 count+10, mode 1 count, mode 3 count+2,
@    mode 4 count+5, mode 5 9+4*byte 0x20001031, mode 0 by byte 0x2000102f (0
@    gives 0xff, 1 count, 2 or 3 count+2, other none), mode 2 by byte
@    0x2000102e (1 count, 2 count+2, other none), no store above 7; then the
@    loop restarts at the wait.
@ ----------------------------------------------------------------------------
	.section .text.fn_0803dac0,"ax",%progbits
	.global fn_0803dac0
	.thumb_func
	.type fn_0803dac0, %function
fn_0803dac0:
	sub	sp, #0x38
	add	r0, sp, #0x18
	movw	r11, #0x2d7c
	movw	r7, #0xf8
	movw	r6, #0x4e11
	vldr	d8, .L0803dc60
	vldr	d11, .L0803dc68
	vldr	d12, .L0803dc70
	vldr	d13, .L0803dc78
	vldr	d9, .L0803dc80
	adds	r0, #0x8
	movt	r11, #0x2000
	movt	r7, #0x2000
	movs	r4, #0x0
	movt	r6, #0x2000
	str	r0, [sp, #0xc]
	b.n	.L0803db04
.L0803daf8:
	ldrb.w	r0, [r7, #0xf35]
	cmp	r0, #0x0
	beq.w	.L0803dd5e
	nop
.L0803db04:
	ldr.w	r0, [r11]
	mov.w	r1, #0xffffffff
	bl	semaphore_take_timeout
	cmp	r0, #0x1
	bne.n	.L0803db04
	ldrb.w	r8, [r6, #0x2]
	ldrb.w	r10, [r6, #0x3]
	and.w	r0, r8, #0xf0
	and.w	r1, r10, #0xf
	add	r0, r1
	strb.w	r4, [r7, #0xf2c]
	bl	map_masked_byte_to_code
	ldrb	r4, [r6, #0x4]
	mov	r9, r0
	and.w	r0, r10, #0xf0
	and.w	r1, r4, #0xf
	add	r0, r1
	bl	map_masked_byte_to_code
	ldrb	r7, [r6, #0x5]
	mov	r5, r0
	and.w	r0, r4, #0xf0
	and.w	r1, r7, #0xf
	add	r0, r1
	bl	map_masked_byte_to_code
	mov	r11, r0
	ldrb	r0, [r6, #0x6]
	and.w	r1, r7, #0xf0
	and.w	r0, r0, #0xf
	add	r0, r1
	bl	map_masked_byte_to_code
	cmp.w	r9, #0xa
	it	eq
	cmpeq	r5, #0xb
	beq.w	.L0803dc98
.L0803db70:
	cmp	r5, #0x0
	it	eq
	cmpeq.w	r11, #0xe
	beq.w	.L0803dcce
.L0803db7c:
	cmp.w	r9, #0x10
	it	eq
	cmpeq	r5, #0x10
	beq.w	.L0803dce8
.L0803db88:
	cmp.w	r9, #0x10
	it	eq
	cmpeq	r5, #0x11
	beq.w	.L0803dd06
.L0803db94:
	cmp	r5, #0x12
	it	eq
	cmpeq.w	r11, #0xa
	beq.w	.L0803dd30
.L0803dba0:
	cmp	r5, #0x13
	it	eq
	cmpeq.w	r11, #0x14
	beq.w	.L0803de4c
	cmp.w	r9, #0xff
	itt	ne
	cmpne	r5, #0xff
	cmpne.w	r11, #0xff
	beq.w	.L0803dec0
	movw	r6, #0xf8
	cmp	r0, #0xff
	movt	r6, #0x2000
	beq.w	.L0803e1b0
	subs.w	r1, r9, #0x10
	it	ne
	movne	r1, r9
	subs.w	r2, r5, #0x10
	it	ne
	movne	r2, r5
	movs	r5, #0x64
	muls	r2, r5, r2
	mov.w	r5, #0x3e8
	subs.w	r3, r11, #0x10
	smlabb	r1, r1, r5, r2
	it	ne
	movne	r3, r11
	add.w	r2, r3, r3, lsl #0x2
	add	r0, r1
	add.w	r0, r0, r2, lsl #0x1
	vmov	s0, r0
	vldr	s2, .L0803dc88
	vcvt.f32.s32	s0, s0
	movw	r5, #0x4e11
	vadd.f32	s2, s0, s2
	lsls.w	r0, r8, #0x1c
	movt	r5, #0x2000
	it	pl
	vmovpl.f32	s2, s0
	ldrsb.w	r0, [r5, #0x8]
	add.w	r6, r6, #0xf30
	cmp	r0, #0x0
	vstr	s2, [r6]
	bmi.w	.L0803deca
	lsls.w	r0, r10, #0x1b
	mov.w	r9, #0x0
	bmi.w	.L0803e11c
	lsls	r0, r4, #0x1b
	movw	r4, #0xf8
	movt	r4, #0x2000
	bmi.w	.L0803e12c
	adr.w	r0, .L0803e3e0
	tst.w	r7, #0x10
	it	eq
	addeq	r0, #0x8
	vldr	d1, [r0]
	ubfx	r0, r7, #0x4, #0x1
	b.n	.L0803e132
	.short	0xbf00, 0xbf00	@ padding: never reached, aligns the literal at 0803dc60
.L0803dc60:
	.word	0x00000000, 0x408f4000	@ double 1000.0
.L0803dc68:
	.word	0x00000000, 0x3fe00000	@ double 0.5
.L0803dc70:
	.word	0x00000000, 0x00000000	@ double 0.0
.L0803dc78:
	.word	0x00000000, 0x40590000	@ double 100.0
.L0803dc80:
	.word	0x00000000, 0x40240000	@ double 10.0
.L0803dc88:
	.word	0x461c4000	@ float 10000.0
	.short	0xbf00, 0xbf00	@ padding: never reached, aligns the literal at 0803dc90
.L0803dc90:
	.word	0x00000000, 0x40100000	@ double 4.0
.L0803dc98:
	cmp.w	r11, #0xc
	bne.w	.L0803db70
	cmp	r0, #0xd
	bne.w	.L0803db70
	movw	r6, #0xf8
	movt	r6, #0x2000
	ldrb.w	r0, [r6, #0xf2d]
	movs	r1, #0x1
	cmp	r0, #0x0
	mov.w	r0, #0x0
	strb.w	r1, [r6, #0xf35]
	strb.w	r0, [r6, #0xf2f]
	it	eq
	strbeq.w	r0, [r6, #0xf36]
	str.w	r0, [r6, #0xf30]
	b.n	.L0803e1b0
.L0803dcce:
	movw	r6, #0xf8
	movt	r6, #0x2000
	movs	r0, #0x2
	strb.w	r0, [r6, #0xf35]
	movs	r0, #0x0
	movt	r0, #0x41a0
	str.w	r0, [r6, #0xf30]
	b.n	.L0803e1b0
.L0803dce8:
	cmp.w	r11, #0x10
	bne.w	.L0803db88
	cmp	r0, #0x10
	bne.w	.L0803db88
	movw	r6, #0xf8
	movt	r6, #0x2000
	movs	r0, #0x3
	strb.w	r0, [r6, #0xf35]
	b.n	.L0803e1b0
.L0803dd06:
	cmp.w	r11, #0xa
	bne.w	.L0803db94
	cmp	r0, #0xe
	bne.w	.L0803db94
	movw	r7, #0xf8
	movt	r7, #0x2000
	movs	r0, #0x4
	strb.w	r0, [r7, #0xf35]
	movs	r0, #0x8
	movs	r4, #0x0
	strb.w	r0, [r7, #0xf2d]
	str.w	r4, [r7, #0xf30]
	b.n	.L0803e1e8
.L0803dd30:
	cmp	r0, #0x5
	bne.w	.L0803dba0
	movw	r6, #0xf8
	movt	r6, #0x2000
	ldrb.w	r0, [r6, #0xf5d]
	cmp	r0, #0xb0
	mov.w	r0, #0x5
	strb.w	r0, [r6, #0xf35]
	bne.w	.L0803de66
	movs	r0, #0xb1
	strb.w	r0, [r6, #0xf5d]
	movs	r0, #0x1
	strb.w	r0, [r6, #0xf2d]
	b.n	.L0803de66
.L0803dd5e:
	ldr.w	r0, [r7, #0xf48]
	bic.w	r0, r0, #0x80000000
	cmp.w	r0, #0x7f800000
	bhi.w	.L0803de6e
	ldr.w	r0, [r7, #0xf30]
	bl	float_to_double
	mov	r4, r0
	ldrb.w	r0, [r7, #0xf37]
	mov	r5, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r4
	mov	r3, r5
	bl	double_mul
	mov	r8, r0
	vmov	d10, r0, r1
	ldr.w	r0, [r7, #0xf48]
	mov	r9, r1
	vstr	d10, [sp, #0x30]
	bl	float_to_double
	mov	r4, r0
	ldrb.w	r0, [r7, #0xf57]
	mov	r5, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r4
	mov	r3, r5
	bl	double_mul
	mov	r10, r0
	vmov	d15, r0, r1
	ldrb.w	r0, [r7, #0xf58]
	mov	r6, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	ldr.w	r0, [r7, #0xf50]
	bl	float_to_double
	mov	r4, r0
	ldrb.w	r0, [r7, #0xf59]
	mov	r5, r1
	bl	u32_to_double
	vmov	d1, r0, r1
	vmov.f32	s0, s16
	vmov.f32	s1, s17
	bl	double_pow
	vmov	r0, r1, d0
	mov	r2, r4
	mov	r3, r5
	bl	double_mul
	vmov	d14, r0, r1
	mov	r4, r0
	mov	r5, r1
	mov	r0, r8
	mov	r1, r9
	mov	r2, r10
	mov	r3, r6
	vstr	d14, [sp, #0x28]
	bl	double_le
	cmp	r0, #0x0
	bne.n	.L0803dede
	vstr	d10, [sp, #0x18]
	b.n	.L0803df02
.L0803de4c:
	subs	r1, r0, #0x1
	uxtb	r1, r1
	movw	r6, #0xf8
	cmp	r1, #0x3
	mov.w	r1, #0x9
	movt	r6, #0x2000
	it	cc
	addcc	r1, r0, #0x5
	strb.w	r1, [r6, #0xf35]
.L0803de66:
	movs	r0, #0x0
	str.w	r0, [r6, #0xf30]
	b.n	.L0803e1b0
.L0803de6e:
	add.w	r0, r7, #0xf30
	vldr	s0, [r0]
	addw	r3, r7, #0xf48
	ldrb.w	r0, [r7, #0xf34]
	ldrb.w	r1, [r7, #0xf37]
	ldrb.w	r2, [r7, #0xf38]
	vstr	s0, [r3]
	addw	r3, r7, #0xf4c
	vstr	s0, [r3]
	add.w	r3, r7, #0xf50
	strb.w	r0, [r7, #0xf54]
	strb.w	r1, [r7, #0xf57]
	strb.w	r2, [r7, #0xf5a]
	strb.w	r0, [r7, #0xf55]
	strb.w	r1, [r7, #0xf58]
	strb.w	r2, [r7, #0xf5b]
	vstr	s0, [r3]
	strb.w	r0, [r7, #0xf56]
	strb.w	r1, [r7, #0xf59]
	strb.w	r2, [r7, #0xf5c]
	b.n	.L0803db04
.L0803dec0:
	movw	r6, #0xf8
	movt	r6, #0x2000
	b.n	.L0803e1b0
.L0803deca:
	vldr	d1, .L0803dc90
	movw	r4, #0xf8
	movs	r0, #0x4
	movt	r4, #0x2000
	mov.w	r9, #0x0
	b.n	.L0803e132
.L0803dede:
	mov	r0, r8
	mov	r1, r9
	mov	r2, r4
	mov	r3, r5
	bl	double_ge
	cmp	r0, #0x0
	ittt	eq
	vstreq	d10, [sp, #0x28]
	vmoveq.f32	s28, s20
	vmoveq.f32	s29, s21
	vmov.f32	s20, s30
	vmov.f32	s21, s31
.L0803df02:
	vmov	r4, r5, d14
	vmov	r0, r1, d10
	mov	r2, r4
	mov	r3, r5
	bl	double_sub
	vmov	r2, r3, d11
	bl	double_mul
	mov	r2, r0
	mov	r3, r1
	mov	r0, r4
	mov	r1, r5
	bl	double_add
	vmov	d0, r0, r1
	ldrb.w	r0, [r7, #0xf2d]
	ldrb.w	r1, [r7, #0xf36]
	str	r0, [sp, #0x10]
	ldrb.w	r0, [r7, #0xf2f]
	str	r1, [sp, #0x4]
	str	r0, [sp, #0x8]
	ldrb.w	r0, [r7, #0xf39]
	movs	r1, #0x9
	add.w	r0, r1, r0, lsl #0x2
	str	r0, [sp]
	addw	r0, r7, #0xf48
	addw	r10, r7, #0xf5a
	mov.w	r11, #0x0
	vstr	d0, [sp, #0x20]
	str	r0, [sp, #0x14]
	mov	r6, r7
.L0803df5c:
	vmov	r7, r6, d10
	vmov	r0, r1, d12
	lsr.w	r8, r1, #0x1f
	mov	r1, r6
	movs	r0, #0x0
	vmov	r5, r4, d8
	bfi	r1, r8, #0x1f, #0x1
	strb.w	r0, [r10, #-0x3]
	mov	r0, r7
	mov	r2, r5
	mov	r3, r4
	vmov	d15, r7, r1
	bl	double_lt
	mov.w	r9, #0x0
	cbnz	r0, .L0803dfac
	mov.w	r9, #0x1
	mov	r0, r7
	mov	r1, r6
	mov	r2, r5
	mov	r3, r4
	strb.w	r9, [r10, #-0x3]
	bl	double_div
	vmov	d10, r0, r1
	bfi	r1, r8, #0x1f, #0x1
	vmov	d15, r0, r1
.L0803dfac:
	vmov	r0, r1, d15
	mov	r2, r5
	mov	r3, r4
	bl	double_lt
	cbnz	r0, .L0803dfda
	add.w	r9, r9, #0x1
	vmov	r0, r1, d10
	mov	r2, r5
	mov	r3, r4
	strb.w	r9, [r10, #-0x3]
	bl	double_div
	vmov	d10, r0, r1
	bfi	r1, r8, #0x1f, #0x1
	vmov	d15, r0, r1
.L0803dfda:
	vmov	r0, r1, d15
	mov	r2, r5
	mov	r3, r4
	bl	double_lt
	cbnz	r0, .L0803e008
	add.w	r9, r9, #0x1
	vmov	r0, r1, d10
	mov	r2, r5
	mov	r3, r4
	strb.w	r9, [r10, #-0x3]
	bl	double_div
	vmov	d10, r0, r1
	bfi	r1, r8, #0x1f, #0x1
	vmov	d15, r0, r1
.L0803e008:
	vmov	r0, r1, d15
	mov	r2, r5
	mov	r3, r4
	bl	double_lt
	cbnz	r0, .L0803e036
	add.w	r0, r9, #0x1
	strb.w	r0, [r10, #-0x3]
	vmov	r0, r1, d10
	mov	r2, r5
	mov	r3, r4
	bl	double_div
	vmov	d10, r0, r1
	bfi	r1, r8, #0x1f, #0x1
	vmov	d15, r0, r1
.L0803e036:
	ldr	r0, [sp, #0xc]
	vmov	r7, r6, d15
	add.w	r8, r0, r11
	mov	r0, r7
	mov	r1, r6
	mov	r2, r5
	mov	r3, r4
	vstr	d10, [r8, #-0x8]
	bl	double_lt
	cmp	r0, #0x0
	itt	eq
	moveq	r0, #0x1
	strbeq.w	r0, [r10, #-0x6]
	vmov	r2, r3, d13
	mov	r0, r7
	mov	r1, r6
	bl	double_lt
	cbz	r0, .L0803e080
	vmov	r2, r3, d9
	mov	r0, r7
	mov	r1, r6
	bl	double_lt
	cmp	r0, #0x0
	ite	ne
	movne	r0, #0x4
	moveq	r0, #0x3
	b.n	.L0803e082
	.short	0xbf00	@ padding: never reached
.L0803e080:
	movs	r0, #0x2
.L0803e082:
	strb.w	r0, [r10, #-0x6]
	ldr	r4, [sp, #0x14]
	vmov	r0, r1, d10
	bl	double_to_float
	ldr	r1, [sp, #0x10]
	str	r0, [r4]
	cmp	r1, #0x7
	bhi.n	.L0803e0e8
	ldr	r1, [sp, #0x10]
	tbb	[pc, r1]
.L0803e09e:
	.byte	(.L0803e0ae - .L0803e09e)/2
	.byte	(.L0803e0d2 - .L0803e09e)/2
	.byte	(.L0803e0c0 - .L0803e09e)/2
	.byte	(.L0803e0ca - .L0803e09e)/2
	.byte	(.L0803e0d8 - .L0803e09e)/2
	.byte	(.L0803e0e0 - .L0803e09e)/2
	.byte	(.L0803e0a6 - .L0803e09e)/2
	.byte	(.L0803e0a6 - .L0803e09e)/2
.L0803e0a6:
	ldrb.w	r0, [r10, #-0x3]
	adds	r0, #0xa
	b.n	.L0803e0e4
.L0803e0ae:
	ldr	r1, [sp, #0x8]
	subs	r0, r1, #0x2
	cmp	r0, #0x2
	bcc.n	.L0803e0ca
	cmp	r1, #0x1
	beq.n	.L0803e0d2
	cbnz	r1, .L0803e0e8
	movs	r0, #0xff
	b.n	.L0803e0e4
.L0803e0c0:
	ldr	r0, [sp, #0x4]
	cmp	r0, #0x1
	beq.n	.L0803e0d2
	cmp	r0, #0x2
	bne.n	.L0803e0e8
.L0803e0ca:
	ldrb.w	r0, [r10, #-0x3]
	adds	r0, #0x2
	b.n	.L0803e0e4
.L0803e0d2:
	ldrb.w	r0, [r10, #-0x3]
	b.n	.L0803e0e4
.L0803e0d8:
	ldrb.w	r0, [r10, #-0x3]
	adds	r0, #0x5
	b.n	.L0803e0e4
.L0803e0e0:
	ldr	r0, [sp]
	nop
.L0803e0e4:
	strb.w	r0, [r10]
.L0803e0e8:
	cmp.w	r11, #0x10
	beq.n	.L0803e100
	vldr	d10, [r8]
	adds	r4, #0x4
	str	r4, [sp, #0x14]
	add.w	r10, r10, #0x1
	add.w	r11, r11, #0x8
	b.n	.L0803df5c
.L0803e100:
	movw	r11, #0x2d7c
	movw	r7, #0xf8
	movw	r6, #0x4e11
	movt	r11, #0x2000
	movt	r7, #0x2000
	movs	r4, #0x0
	movt	r6, #0x2000
	b.n	.L0803db04
.L0803e11c:
	vldr	d1, .L0803e3d0
	movw	r4, #0xf8
	movs	r0, #0x3
	movt	r4, #0x2000
	b.n	.L0803e132
.L0803e12c:
	vldr	d1, .L0803e3d8
	movs	r0, #0x2
.L0803e132:
	vmov.f32	s0, s18
	vmov.f32	s1, s19
	strb.w	r0, [r4, #0xf34]
	bl	double_pow
	ldr.w	r0, [r4, #0xf30]
	vmov.f32	s20, s0
	vmov.f32	s21, s1
	bl	float_to_double
	vmov	r2, r3, d10
	bl	double_div
	bl	double_to_float
	ldrb.w	r8, [r5, #0x2]
	vmov	s0, r0
	lsls.w	r1, r8, #0x1b
	str.w	r0, [r4, #0xf30]
	itt	mi
	vnegmi.f32	s0, s0
	vstrmi	s0, [r6]
	ldrb.w	r0, [r4, #0xf2d]
	cmp	r0, #0x5
	bne.n	.L0803e1a2
	ldrb.w	r0, [r4, #0xf39]
	cbz	r0, .L0803e1a2
	vmov.f32	s2, #9.0
	vmul.f32	s0, s0, s2
	vmov.f32	s2, #5.0
	vdiv.f32	s0, s0, s2
	vldr	s2, .L0803e3f0
	vadd.f32	s0, s0, s2
	vstr	s0, [r6]
.L0803e1a2:
	movs	r0, #0xff
	mov	r6, r4
	strb.w	r9, [r4, #0xf35]
	strb.w	r0, [r4, #0xf2f]
	nop
.L0803e1b0:
	ldrb.w	r0, [r6, #0xf2d]
	mov	r7, r6
	cmp	r0, #0x7
	bhi.n	.L0803e1e6
	movw	r6, #0x4e11
	movs	r4, #0x0
	movt	r6, #0x2000
	tbb	[pc, r0]
.L0803e1c8:
	.byte	(.L0803e1f2 - .L0803e1c8)/2
	.byte	(.L0803e228 - .L0803e1c8)/2
	.byte	(.L0803e23e - .L0803e1c8)/2
	.byte	(.L0803e25e - .L0803e1c8)/2
	.byte	(.L0803e27a - .L0803e1c8)/2
	.byte	(.L0803e298 - .L0803e1c8)/2
	.byte	(.L0803e1d0 - .L0803e1c8)/2
	.byte	(.L0803e1d0 - .L0803e1c8)/2
.L0803e1d0:
	ldrb	r1, [r6, #0x6]
	lsls	r1, r1, #0x1b
	bmi.n	.L0803e2b6
	ldrb	r1, [r6, #0x7]
	lsls	r1, r1, #0x1f
	ite	eq
	moveq	r1, #0x2
	movne	r1, #0x1
	strb.w	r1, [r7, #0xf37]
	b.n	.L0803e350
.L0803e1e6:
	movs	r4, #0x0
.L0803e1e8:
	movw	r6, #0x4e11
	movt	r6, #0x2000
	b.n	.L0803e350
.L0803e1f2:
	ldrb.w	r0, [r7, #0xf2f]
	cmp	r0, #0x0
	beq.w	.L0803e34c
	ldrb	r1, [r6, #0x7]
	lsls	r0, r1, #0x1a
	bmi.n	.L0803e2e0
	lsls.w	r0, r8, #0x1e
	bmi.w	.L0803e328
	lsls.w	r0, r8, #0x1f
	bne.w	.L0803e338
	movw	r11, #0x2d7c
	lsls	r0, r1, #0x1c
	movt	r11, #0x2000
	bmi.w	.L0803e3a8
	movs	r0, #0x0
	strb.w	r0, [r7, #0xf36]
	b.n	.L0803e358
.L0803e228:
	ldrb	r0, [r6, #0x7]
	movw	r11, #0x2d7c
	lsls	r0, r0, #0x1f
	movt	r11, #0x2000
	bne.n	.L0803e2bc
	movs	r0, #0x1
	strb.w	r0, [r7, #0xf37]
	b.n	.L0803e358
.L0803e23e:
	ldrb.w	r1, [r7, #0xf36]
	ldrb	r0, [r6, #0x7]
	cmp	r1, #0x1
	bne.n	.L0803e2c4
	movw	r11, #0x2d7c
	lsls	r0, r0, #0x1f
	movt	r11, #0x2000
	bne.n	.L0803e320
.L0803e254:
	movs	r0, #0x1
	strb.w	r0, [r7, #0xf37]
	movs	r0, #0x2
	b.n	.L0803e358
.L0803e25e:
	ldrb	r0, [r6, #0x7]
	movw	r11, #0x2d7c
	lsls	r0, r0, #0x1d
	movt	r11, #0x2000
	bmi.n	.L0803e2d4
	ldrb	r0, [r6, #0x6]
	lsls	r0, r0, #0x19
	bmi.n	.L0803e302
	strb.w	r4, [r7, #0xf37]
	movs	r0, #0x3
	b.n	.L0803e358
.L0803e27a:
	ldrb	r0, [r6, #0x6]
	movw	r11, #0x2d7c
	lsls	r1, r0, #0x1a
	movt	r11, #0x2000
	bmi.n	.L0803e2d8
	lsls	r0, r0, #0x1b
	bmi.n	.L0803e30c
	ldrb	r0, [r6, #0x7]
	lsls	r0, r0, #0x1f
	ite	eq
	moveq	r0, #0x3
	movne	r0, #0x2
	b.n	.L0803e30e
.L0803e298:
	ldrb.w	r0, [r7, #0xf39]
	movw	r11, #0x2d7c
	cmp	r0, #0x0
	itee	eq
	strbeq.w	r4, [r7, #0xf37]
	movne	r0, #0x4
	strbne.w	r0, [r7, #0xf37]
	movt	r11, #0x2000
	movs	r0, #0x5
	b.n	.L0803e358
.L0803e2b6:
	strb.w	r4, [r7, #0xf37]
	b.n	.L0803e350
.L0803e2bc:
	strb.w	r4, [r7, #0xf37]
	movs	r0, #0x1
	b.n	.L0803e358
.L0803e2c4:
	movw	r11, #0x2d7c
	lsls	r1, r0, #0x1c
	movt	r11, #0x2000
	bmi.n	.L0803e316
	movs	r0, #0x2
	b.n	.L0803e358
.L0803e2d4:
	movs	r0, #0x2
	b.n	.L0803e304
.L0803e2d8:
	strb.w	r4, [r7, #0xf37]
	movs	r0, #0x4
	b.n	.L0803e358
.L0803e2e0:
	lsls	r1, r1, #0x1d
	mov.w	r0, #0x0
	mov.w	r1, #0x2
	strb.w	r0, [r7, #0xf36]
	ldrb	r2, [r6, #0x6]
	it	pl
	ubfxpl	r1, r2, #0x6, #0x1
	strb.w	r1, [r7, #0xf37]
	movs	r1, #0x3
	strb.w	r1, [r7, #0xf2f]
	b.n	.L0803e350
.L0803e302:
	movs	r0, #0x1
.L0803e304:
	strb.w	r0, [r7, #0xf37]
	movs	r0, #0x3
	b.n	.L0803e358
.L0803e30c:
	movs	r0, #0x1
.L0803e30e:
	strb.w	r0, [r7, #0xf37]
	movs	r0, #0x4
	b.n	.L0803e358
.L0803e316:
	lsls	r0, r0, #0x1d
	bmi.n	.L0803e330
	ldrb	r0, [r6, #0x6]
	lsls	r0, r0, #0x19
	bmi.n	.L0803e254
.L0803e320:
	strb.w	r4, [r7, #0xf37]
	movs	r0, #0x2
	b.n	.L0803e358
.L0803e328:
	movs	r2, #0x1
	strb.w	r2, [r7, #0xf36]
	b.n	.L0803e340
.L0803e330:
	movs	r0, #0x2
	strb.w	r0, [r7, #0xf37]
	b.n	.L0803e358
.L0803e338:
	movs	r0, #0x2
	strb.w	r0, [r7, #0xf36]
	movs	r2, #0x1
.L0803e340:
	bic.w	r0, r2, r1
	strb.w	r0, [r7, #0xf37]
	strb.w	r2, [r7, #0xf2f]
.L0803e34c:
	movs	r0, #0x0
	nop
.L0803e350:
	movw	r11, #0x2d7c
	movt	r11, #0x2000
.L0803e358:
	ldrb.w	r1, [r7, #0xf36]
	cmp	r1, #0x2
	bne.n	.L0803e386
	ldrb.w	r1, [r7, #0xf2f]
	eor.w	r1, r1, #0x1
	orrs	r1, r0
	subs	r0, #0x1
	clz	r1, r1
	clz	r0, r0
	lsrs	r1, r1, #0x5
	lsrs	r0, r0, #0x5
	orrs	r0, r1
	beq.n	.L0803e386
	ldrh	r0, [r6, #0xa]
	rev	r0, r0
	lsrs	r0, r0, #0x10
	strh.w	r0, [r7, #0xf3a]
.L0803e386:
	bl	fn_080098e0
	ldrb.w	r0, [r7, #0xf2d]
	cmp	r0, #0x8
	bhi.w	.L0803daf8
	movs	r1, #0x1
	lsl.w	r0, r1, r0
	movw	r1, #0x105
	tst	r0, r1
	bne.w	.L0803db04
	b.w	.L0803daf8
.L0803e3a8:
	lsls	r1, r1, #0x1d
	mov.w	r2, #0x2
	ldrb	r0, [r6, #0x6]
	mov.w	r1, #0x2
	strb.w	r2, [r7, #0xf36]
	it	pl
	ubfxpl	r1, r0, #0x6, #0x1
	strb.w	r1, [r7, #0xf37]
	strb.w	r2, [r7, #0xf2f]
	movs	r0, #0x0
	b.n	.L0803e358
	.short	0xbf00, 0xbf00, 0xbf00	@ padding: never reached, aligns the literal at 0803e3d0
.L0803e3d0:
	.word	0x00000000, 0x40080000	@ double 3.0
.L0803e3d8:
	.word	0x00000000, 0x40000000	@ double 2.0
.L0803e3e0:
	.word	0x00000000, 0x3ff00000	@ double 1.0
	.word	0x00000000, 0x00000000	@ double 0.0
.L0803e3f0:
	.word	0x42000000	@ float 32.0

@ ----------------------------------------------------------------------------
@ fn_0803e3f4 - task body that forwards a 2-byte message to the I/O block at
@ 0x4000440c. No params; never returns. Its purpose is not determined from the
@ code (the peripheral at 0x4000440c is not identified).
@ Loop: receives a 2-byte message with 080421d8 (queue_receive_timeout)
@ (*0x20002d74, &msg, 0xffffffff) until it returns 1; writes 0 to byte
@ 0x2000000f, msg[0] to byte 0x20000008, msg[1] to byte 0x20000007 and their sum
@ to byte 0x2000000e; sets bit 7 of the word at 0x4000440c; calls 08041390
@ (fn_08041390)(10) (delay of 10 ticks).
@ ----------------------------------------------------------------------------
	.section .text.fn_0803e3f4,"ax",%progbits
	.global fn_0803e3f4
	.thumb_func
	.type fn_0803e3f4, %function
fn_0803e3f4:
	sub	sp, #8
	movw	r5, #0x440c
	movw	r6, #0x2d74
	movw	r7, #0x5
	movw	r8, #0xf
	movt	r5, #0x4000
	movt	r6, #0x2000
	add.w	r4, sp, #0x6
	movt	r7, #0x2000
	movt	r8, #0x2000
	mov.w	r9, #0x0
	nop
.L0803e420:
	ldr	r0, [r6]
	mov	r1, r4
	mov.w	r2, #0xffffffff
	bl	queue_receive_timeout
	cmp	r0, #0x1
	bne.n	.L0803e420
	ldrh.w	r0, [sp, #0x6]
	strb.w	r9, [r8]
	lsrs	r1, r0, #0x8
	strb	r0, [r7, #0x3]
	add.w	r0, r0, r0, lsr #0x8
	strb	r1, [r7, #0x2]
	strb	r0, [r7, #0x9]
	ldr	r0, [r5]
	orr	r0, r0, #0x80
	str	r0, [r5]
	movs	r0, #0xa
	bl	fn_08041390
	b.n	.L0803e420
