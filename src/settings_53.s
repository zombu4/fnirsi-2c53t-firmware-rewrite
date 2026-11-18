@ settings_53.s - settings page save to flash (save_settings_to_flash, fn_08029d40), flash reset-guard and screenshot attribute helpers, flash_program_halfword
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ save_settings_to_flash - writes the settings page (0x08006000, 0x800 bytes,
@ 0x130 bytes written from RAM, including both 60-entry halfword tables) to
@ flash and then calls the no-return function reset_system (0x0803b070).
@ Parameter: r0 = param_1, compared with 0x55 at 0x08029408. Never returns.
@ Start: sets bit 1 in words 0x40005c40 and 0x40005c60, clears word 0x40015034
@ (0x40015434 - 0x400) and halfword 0x20001064, allocates 0x200 bytes with
@ alloc_units_of_32_bytes (0x0803acfc); when the allocation fails all flash
@ work is skipped.
@ param_1 == 0x55: packs the current RAM values. Any other value first
@ overwrites RAM defaults: 0x200000f8 = 0, 0x200000f9 = 0, 0x200000fa = 5,
@ word 0x200000fb = 0x00ce3205, 0x200000ff = 0, 0x2000010c = 3,
@ 0x2000010e = 0, 0x2000010f = 1, 0x20000110 = 0, 0x20000112 = 0 (s16),
@ 0x20000114 = 0x32 (s16), 0x20000125 = 0xd, 0x20000144 = 0x01050105,
@ s16 0x2000032a = -75, 0x2000032c = 75, 0x2000032e = 50, 0x20000330 = -50,
@ 0x20000f50 = 1, 0x20000f51 = 0, 0x20000f54 = 1000, 0x20000f58 = 0x32,
@ 0x20000f59 = 0x1e, 0x20001058 = 0x00016401, and zeroes halfword 0x20000100,
@ halfword 0x20000102, 0x20000140, 0x2000012c..0x2000012d, 0x20000134,
@ 0x20000332, 0x2000044c, halfword 0x2000105c (the 16-bit tables
@ 0x20000358..0x20000447 and bytes 0x20000448..0x2000044b are not touched by
@ the default branch, so those values stay as in RAM).
@ Packed buffer (word index: content), marker byte = 0x55 or 0xaa in byte 0:
@  w0 = marker | 0x200000f8<<8 | 0x200000f9<<16 | 0x200000fa<<24
@  w1 = word at 0x200000fb
@  w2 = 0x200000ff | 0x2000010c<<8 | 0x2000010e<<16 | 0x2000010f<<24
@  w3 = 0x20000110 | 0x20000125<<8 | 0x2000012c<<16 | 0x2000012d<<24
@  w4 = word at 0x20000112
@  w5 = 0x20000134 | 0x20000332<<8 | 0x2000044c<<16 | 0x20001031<<24
@  w6 = word 0x20000144
@  w7 = s16 0x2000032a | s16 0x2000032c<<16
@  w8 = s16 0x2000032e | s16 0x20000330<<16
@  w9 = 0x20000f50 | 0x20000f51<<8 | 0x20000f58<<16 | 0x20000f59<<24
@  w10 = word 0x20000f54
@  w11 = word 0x20001058
@  w12 = u16 0x2000105c | 0x20000100<<16 | 0x20000101<<24
@  w13 = u16 0x20000102 | 0x20000140<<16 | 0x20000101<<24
@  w14..w73 = u16 0x20000358+2k | u16 0x200003d0+2k<<16 for k = 0..59 (two
@   60-entry halfword tables, ending with 0x200003ce and 0x20000446)
@  w74 = 0x20000448 | 0x20000449<<8 | (u16 0x20000446)<<16
@  w75 = 0x2000044a | 0x2000044b<<8 | (u16 0x20000446)<<16
@   (0x08029a16..0x08029a4a)
@ Only 0x130 of the 0x200 buffer bytes are written by this function (vendor: the rest is whatever
@ the heap held, programmed into 0x08006130..0x080061FF at every save). This firmware:
@ settings_buffer_alloc fills the buffer with the page's first 0x200 bytes first, so only the packed
@ values change, and settings_pack_done skips the whole flash part (erase and program of the page
@ that also holds the calibration) when the packed buffer equals the page.
@ Flash part: disables interrupts (cpsid i, never re-enabled here), writes the
@ keys 0x45670123 and 0xcdef89ab to 0x40022004 and to 0x40022044, copies 0x800
@ bytes from 0x08006000 to RAM 0x200022c8; when all 256 halfwords of the first
@ 0x200 bytes of that copy are 0xffff (check loop 0x08029ac4..0x08029ae8) it
@ programs the 0x200 buffer halfword by halfword with flash_program_halfword
@ (0x08035afc)(0x08006000 + offset, value) and stops on a result other than 3.
@ Otherwise: waits for bit 0 of 0x4002200c to clear (bounded count
@ 0x40000000), writes 0x14 to 0x4002200c when bit 2 or bit 4 is set, sets
@ bit 1 of 0x40022010, writes 0x08006000 to 0x40022014, sets bit 6 of
@ 0x40022010, waits again, aborts (clearing bit 1) on error bits, clears
@ bit 1, overlays the 0x200 buffer on the first 0x200 bytes of the RAM copy
@ and programs all 0x800 bytes with flash_program_halfword, stopping on a
@ result other than 3.
@ After a fully successful program run sets bit 7 of 0x40022010 and of
@ 0x40022050; releases the 0x200 buffer (function pointer 0x20001070 when byte
@ 0x20001080 is 0, else table 0x2000107c/0x20001078 with zero_bytes
@ 0x080082bc).
@ Then: when word 0x40015434 is non-zero increments byte 0x20002d67 and clears
@ both when it reaches 0xb, else clears byte 0x20002d67; writes 0x200 to
@ 0x40011014 and calls reset_system (0x0803b070).
@ ----------------------------------------------------------------------------
	.section .text.save_settings_to_flash,"ax",%progbits
	.global save_settings_to_flash_body
	.thumb_func
	.type save_settings_to_flash_body, %function
save_settings_to_flash_body:
	sub	sp, #0x38
	movw	r1, #0x5c40
	movt	r1, #0x4000
	ldr	r2, [r1]
	mov	r5, r0
	orr.w	r0, r2, #0x2
	str	r0, [r1]
	ldr	r0, [r1, #0x20]
	movw	r4, #0x5434
	orr.w	r0, r0, #0x2
	str	r0, [r1, #0x20]
	movw	r0, #0xfc00
	movt	r4, #0x4001
	movt	r0, #0xffff
	movs	r1, #0x0
	movw	r7, #0xf8
	str	r1, [r4, r0]
	movt	r7, #0x2000
	mov.w	r0, #0x200
	strh.w	r1, [r7, #0xf6c]
	bl	settings_buffer_alloc		@ storage.s: the buffer starts as the page's first 0x200 bytes
	cmp	r0, #0x0
	beq.w	.L08029d0c
	mov	r10, r0
	cmp	r5, #0x55
	movw	r0, #0xffff
	bne.n	.L080294a0
	ldrb	r1, [r7, #0x18]
	ldrb.w	r9, [r7, #0x2d]
	str	r1, [sp, #0x14]
	ldrh	r1, [r7, #0x1a]
	ldrb	r2, [r7]
	str	r1, [sp, #0x18]
	lsl.w	r1, r9, #0x8
	str	r1, [sp, #0x1c]
	ldrh	r1, [r7, #0x1c]
	ldrb	r6, [r7, #0x2]
	lsls	r1, r1, #0x10
	str	r1, [sp, #0x34]
	ldrh.w	r1, [r7, #0x234]
	lsl.w	r12, r2, #0x8
	lsls	r1, r1, #0x10
	str	r1, [sp, #0xc]
	ldrh.w	r1, [r7, #0x232]
	lsls	r2, r6, #0x18
	str	r2, [sp, #0x28]
	ldrb	r2, [r7, #0x17]
	str	r1, [sp, #0x10]
	ldrh.w	r1, [r7, #0x236]
	ldrb	r3, [r7, #0x1]
	ldrb	r5, [r7, #0x14]
	ldrb	r4, [r7, #0x16]
	lsls	r2, r2, #0x18
	str	r1, [sp]
	ldrh.w	r1, [r7, #0x238]
	lsls	r6, r3, #0x10
	lsls	r3, r5, #0x8
	str	r2, [sp, #0x20]
	lsls	r2, r4, #0x10
	ldrb.w	r4, [r7, #0xe60]
	str	r3, [sp, #0x24]
	ldrb.w	r3, [r7, #0x35]
	str	r1, [sp, #0x30]
	ldrb.w	r1, [r7, #0xe58]
	ldrb.w	r8, [r7, #0x34]
	ldrb.w	r11, [r7, #0x23a]
	ldrb.w	lr, [r7, #0x354]
	str	r4, [sp, #0x8]
	ldrb.w	r4, [r7, #0xe61]
	lsls	r5, r3, #0x18
	ldrb.w	r3, [r7, #0x3c]
	str	r1, [sp, #0x2c]
	ldrb.w	r1, [r7, #0xe59]
	lsl.w	r9, r8, #0x10
	lsl.w	r11, r11, #0x8
	lsl.w	r8, lr, #0x10
	str	r4, [sp, #0x4]
	mov.w	lr, #0x55
	b.n	.L0802958a
.L080294a0:
	movs	r1, #0x0
	movt	r1, #0x505
	movw	r2, #0xce32
	strd	r1, r2, [r7]
	movs	r2, #0x3
	strb	r2, [r7, #0x14]
	mov.w	r2, #0x100
	strh	r2, [r7, #0x16]
	movs	r2, #0xd
	strb.w	r2, [r7, #0x2d]
	mov.w	r2, #0x320000
	str	r2, [sp, #0x34]
	movw	r2, #0x105
	movt	r2, #0x105
	str	r2, [r7, #0x4c]
	sub.w	r2, r0, #0x4a
	strh.w	r2, [r7, #0x232]
	movs	r2, #0x4b
	movt	r2, #0x32
	str.w	r2, [r7, #0x234]
	sub.w	r2, r0, #0x31
	str	r2, [sp, #0x30]
	strh.w	r2, [r7, #0x238]
	movs	r2, #0x1
	str	r2, [sp, #0x2c]
	movw	r2, #0x1e32
	strh.w	r2, [r7, #0xe60]
	mov.w	r2, #0x3e8
	str.w	r2, [r7, #0xe5c]
	movw	r2, #0x6401
	movt	r2, #0x1
	str.w	r2, [r7, #0xf60]
	mov.w	r2, #0x5000000
	str	r2, [sp, #0x28]
	mov.w	r2, #0x300
	str	r2, [sp, #0x24]
	mov.w	r2, #0x1000000
	str	r2, [sp, #0x20]
	mov.w	r2, #0xd00
	str	r2, [sp, #0x1c]
	movw	r2, #0xffb5
	str	r2, [sp, #0x10]
	mov.w	r2, #0x4b0000
	str	r2, [sp, #0xc]
	movs	r2, #0x32
	str	r2, [sp, #0x8]
	movs	r2, #0x1e
	str	r2, [sp, #0x4]
	movs	r2, #0x32
	mov.w	r3, #0x320000
	str	r2, [sp]
	movs	r2, #0x0
	str.w	r3, [r7, #0x1a]
	movs	r3, #0x1
	str	r2, [sp, #0x18]
	movs	r2, #0x0
	movs	r1, #0x0
	strh.w	r3, [r7, #0xe58]
	mov.w	lr, #0xaa
	mov.w	r8, #0x0
	mov.w	r11, #0x0
	movs	r3, #0x0
	movs	r5, #0x0
	mov.w	r9, #0x0
	str	r2, [sp, #0x14]
	movs	r2, #0x0
	movs	r6, #0x0
	mov.w	r12, #0x0
	strh	r1, [r7, #0xa]
	strb	r1, [r7, #0x18]
	strh	r1, [r7, #0x34]
	strb.w	r1, [r7, #0x3c]
	strb.w	r1, [r7, #0x23a]
	strb.w	r1, [r7, #0x354]
	strh.w	r1, [r7, #0xf64]
	strh	r1, [r7, #0x8]
	strb.w	r1, [r7, #0x48]
.L0802958a:
	orr.w	r4, r12, lr
	orrs	r6, r4
	ldr	r4, [sp, #0x28]
	orrs	r6, r4
	str.w	r6, [r10]
	ldr.w	r6, [r7, #0x3]
	ldr	r4, [sp, #0x24]
	str.w	r6, [r10, #0x4]
	ldrb	r6, [r7, #0x7]
	orrs	r6, r4
	orrs	r2, r6
	ldr	r6, [sp, #0x20]
	orrs	r2, r6
	str.w	r2, [r10, #0x8]
	ldr	r2, [sp, #0x1c]
	ldr	r6, [sp, #0x14]
	orrs	r2, r6
	orr.w	r2, r2, r9
	orrs	r2, r5
	str.w	r2, [r10, #0xc]
	ldr	r2, [sp, #0x34]
	ldr	r6, [sp, #0x18]
	movw	r5, #0x200c
	orrs	r2, r6
	str.w	r2, [r10, #0x10]
	orr.w	r2, r11, r3
	ldrb.w	r3, [r7, #0xf39]
	orr.w	r2, r2, r8
	orr.w	r2, r2, r3, lsl #0x18
	str.w	r2, [r10, #0x14]
	ldr	r2, [r7, #0x4c]
	movt	r5, #0x4002
	str.w	r2, [r10, #0x18]
	ldrd	r3, r2, [sp, #0xc]
	movw	r6, #0x22c8
	orrs	r2, r3
	str.w	r2, [r10, #0x1c]
	ldr	r2, [sp, #0x30]
	ldr	r3, [sp]
	movt	r6, #0x2000
	orr.w	r2, r3, r2, lsl #0x10
	str.w	r2, [r10, #0x20]
	ldr	r2, [sp, #0x2c]
	orr.w	r1, r2, r1, lsl #0x8
	ldr	r2, [sp, #0x8]
	orr.w	r1, r1, r2, lsl #0x10
	ldr	r2, [sp, #0x4]
	orr.w	r1, r1, r2, lsl #0x18
	str.w	r1, [r10, #0x24]
	ldr.w	r1, [r7, #0xe5c]
	ldrb	r2, [r7, #0x9]
	str.w	r1, [r10, #0x28]
	ldr.w	r1, [r7, #0xf60]
	str.w	r1, [r10, #0x2c]
	ldrb	r1, [r7, #0x8]
	ldrh.w	r3, [r7, #0xf64]
	orr.w	r1, r1, r2, lsl #0x8
	orr.w	r1, r3, r1, lsl #0x10
	str.w	r1, [r10, #0x30]
	ldrb.w	r1, [r7, #0x48]
	ldrh	r3, [r7, #0xa]
	orr.w	r1, r1, r2, lsl #0x8
	orr.w	r1, r3, r1, lsl #0x10
	ldrh.w	r2, [r7, #0x260]
	ldrh.w	r3, [r7, #0x2d8]
	str.w	r1, [r10, #0x34]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x262]
	ldrh.w	r3, [r7, #0x2da]
	str.w	r1, [r10, #0x38]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x264]
	ldrh.w	r3, [r7, #0x2dc]
	str.w	r1, [r10, #0x3c]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x266]
	ldrh.w	r3, [r7, #0x2de]
	str.w	r1, [r10, #0x40]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x268]
	ldrh.w	r3, [r7, #0x2e0]
	str.w	r1, [r10, #0x44]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x26a]
	ldrh.w	r3, [r7, #0x2e2]
	str.w	r1, [r10, #0x48]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x26c]
	ldrh.w	r3, [r7, #0x2e4]
	str.w	r1, [r10, #0x4c]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x26e]
	ldrh.w	r3, [r7, #0x2e6]
	str.w	r1, [r10, #0x50]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x270]
	ldrh.w	r3, [r7, #0x2e8]
	str.w	r1, [r10, #0x54]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x272]
	ldrh.w	r3, [r7, #0x2ea]
	str.w	r1, [r10, #0x58]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x274]
	ldrh.w	r3, [r7, #0x2ec]
	str.w	r1, [r10, #0x5c]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x276]
	ldrh.w	r3, [r7, #0x2ee]
	str.w	r1, [r10, #0x60]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x278]
	ldrh.w	r3, [r7, #0x2f0]
	str.w	r1, [r10, #0x64]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x27a]
	ldrh.w	r3, [r7, #0x2f2]
	str.w	r1, [r10, #0x68]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x27c]
	ldrh.w	r3, [r7, #0x2f4]
	str.w	r1, [r10, #0x6c]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x27e]
	ldrh.w	r3, [r7, #0x2f6]
	str.w	r1, [r10, #0x70]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x280]
	ldrh.w	r3, [r7, #0x2f8]
	str.w	r1, [r10, #0x74]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x282]
	ldrh.w	r3, [r7, #0x2fa]
	str.w	r1, [r10, #0x78]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x284]
	ldrh.w	r3, [r7, #0x2fc]
	str.w	r1, [r10, #0x7c]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x286]
	ldrh.w	r3, [r7, #0x2fe]
	str.w	r1, [r10, #0x80]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x288]
	ldrh.w	r3, [r7, #0x300]
	str.w	r1, [r10, #0x84]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x28a]
	ldrh.w	r3, [r7, #0x302]
	str.w	r1, [r10, #0x88]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x28c]
	ldrh.w	r3, [r7, #0x304]
	str.w	r1, [r10, #0x8c]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x28e]
	ldrh.w	r3, [r7, #0x306]
	str.w	r1, [r10, #0x90]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x290]
	ldrh.w	r3, [r7, #0x308]
	str.w	r1, [r10, #0x94]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x292]
	ldrh.w	r3, [r7, #0x30a]
	str.w	r1, [r10, #0x98]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x294]
	ldrh.w	r3, [r7, #0x30c]
	str.w	r1, [r10, #0x9c]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x296]
	ldrh.w	r3, [r7, #0x30e]
	str.w	r1, [r10, #0xa0]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x298]
	ldrh.w	r3, [r7, #0x310]
	str.w	r1, [r10, #0xa4]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x29a]
	ldrh.w	r3, [r7, #0x312]
	str.w	r1, [r10, #0xa8]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x29c]
	ldrh.w	r3, [r7, #0x314]
	str.w	r1, [r10, #0xac]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x29e]
	ldrh.w	r3, [r7, #0x316]
	str.w	r1, [r10, #0xb0]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2a0]
	ldrh.w	r3, [r7, #0x318]
	str.w	r1, [r10, #0xb4]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2a2]
	ldrh.w	r3, [r7, #0x31a]
	str.w	r1, [r10, #0xb8]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2a4]
	ldrh.w	r3, [r7, #0x31c]
	str.w	r1, [r10, #0xbc]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2a6]
	ldrh.w	r3, [r7, #0x31e]
	str.w	r1, [r10, #0xc0]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2a8]
	ldrh.w	r3, [r7, #0x320]
	str.w	r1, [r10, #0xc4]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2aa]
	ldrh.w	r3, [r7, #0x322]
	str.w	r1, [r10, #0xc8]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2ac]
	ldrh.w	r3, [r7, #0x324]
	str.w	r1, [r10, #0xcc]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2ae]
	ldrh.w	r3, [r7, #0x326]
	str.w	r1, [r10, #0xd0]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2b0]
	ldrh.w	r3, [r7, #0x328]
	str.w	r1, [r10, #0xd4]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2b2]
	ldrh.w	r3, [r7, #0x32a]
	str.w	r1, [r10, #0xd8]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2b4]
	ldrh.w	r3, [r7, #0x32c]
	str.w	r1, [r10, #0xdc]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2b6]
	ldrh.w	r3, [r7, #0x32e]
	str.w	r1, [r10, #0xe0]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2b8]
	ldrh.w	r3, [r7, #0x330]
	str.w	r1, [r10, #0xe4]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2ba]
	ldrh.w	r3, [r7, #0x332]
	str.w	r1, [r10, #0xe8]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2bc]
	ldrh.w	r3, [r7, #0x334]
	str.w	r1, [r10, #0xec]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2be]
	ldrh.w	r3, [r7, #0x336]
	str.w	r1, [r10, #0xf0]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2c0]
	ldrh.w	r3, [r7, #0x338]
	str.w	r1, [r10, #0xf4]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2c2]
	ldrh.w	r3, [r7, #0x33a]
	str.w	r1, [r10, #0xf8]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2c4]
	ldrh.w	r3, [r7, #0x33c]
	str.w	r1, [r10, #0xfc]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2c6]
	ldrh.w	r3, [r7, #0x33e]
	str.w	r1, [r10, #0x100]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2c8]
	ldrh.w	r3, [r7, #0x340]
	str.w	r1, [r10, #0x104]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2ca]
	ldrh.w	r3, [r7, #0x342]
	str.w	r1, [r10, #0x108]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2cc]
	ldrh.w	r3, [r7, #0x344]
	str.w	r1, [r10, #0x10c]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2ce]
	ldrh.w	r3, [r7, #0x346]
	str.w	r1, [r10, #0x110]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2d0]
	ldrh.w	r3, [r7, #0x348]
	str.w	r1, [r10, #0x114]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2d2]
	ldrh.w	r3, [r7, #0x34a]
	str.w	r1, [r10, #0x118]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2d4]
	ldrh.w	r3, [r7, #0x34c]
	str.w	r1, [r10, #0x11c]
	orr.w	r1, r2, r3, lsl #0x10
	ldrh.w	r2, [r7, #0x2d6]
	ldrh.w	r3, [r7, #0x34e]
	str.w	r1, [r10, #0x120]
	orr.w	r1, r2, r3, lsl #0x10
	str.w	r1, [r10, #0x124]
	mov.w	r1, #0xff000000
	and.w	r1, r1, r3, lsl #0x10
	ldrb.w	r2, [r7, #0x350]
	uxtb	r3, r3
	orr.w	r1, r1, r3, lsl #0x10
	ldrb.w	r3, [r7, #0x351]
	add	r2, r1
	orr.w	r2, r2, r3, lsl #0x8
	str.w	r2, [r10, #0x128]
	ldrb.w	r2, [r7, #0x352]
	ldrb.w	r3, [r7, #0x353]
	add	r1, r2
	orr.w	r1, r1, r3, lsl #0x8
	bl	settings_pack_done		@ storage.s: last packed word; Z when the page holds it all
	beq.w	.L08029d0c			@ nothing changed: no erase, no program (r4 set by the call)
	cpsid	i
	movw	r1, #0x123
	movw	r2, #0x89ab
	movw	r7, #0x6000
	movt	r1, #0x4567
	movt	r2, #0xcdef
	movt	r7, #0x800
	str.w	r1, [r5, #-0x8]
	str.w	r2, [r5, #-0x8]
	str	r1, [r5, #0x38]
	movs	r1, #0x0
	str	r2, [r5, #0x38]
.L08029a74:
	ldrh	r2, [r1, r7]
	adds	r3, r1, r7
	strh	r2, [r6, r1]
	ldrh	r4, [r3, #0x2]
	adds	r2, r6, r1
	strh	r4, [r2, #0x2]
	ldrh	r4, [r3, #0x4]
	adds	r1, #0x20
	strh	r4, [r2, #0x4]
	ldrh	r4, [r3, #0x6]
	cmp.w	r1, #0x800
	strh	r4, [r2, #0x6]
	ldrh	r4, [r3, #0x8]
	strh	r4, [r2, #0x8]
	ldrh	r4, [r3, #0xa]
	strh	r4, [r2, #0xa]
	ldrh	r4, [r3, #0xc]
	strh	r4, [r2, #0xc]
	ldrh	r4, [r3, #0xe]
	strh	r4, [r2, #0xe]
	ldrh	r4, [r3, #0x10]
	strh	r4, [r2, #0x10]
	ldrh	r4, [r3, #0x12]
	strh	r4, [r2, #0x12]
	ldrh	r4, [r3, #0x14]
	strh	r4, [r2, #0x14]
	ldrh	r4, [r3, #0x16]
	strh	r4, [r2, #0x16]
	ldrh	r4, [r3, #0x18]
	strh	r4, [r2, #0x18]
	ldrh	r4, [r3, #0x1a]
	strh	r4, [r2, #0x1a]
	ldrh	r4, [r3, #0x1c]
	strh	r4, [r2, #0x1c]
	ldrh	r3, [r3, #0x1e]
	strh	r3, [r2, #0x1e]
	bne.n	.L08029a74
	movs	r1, #0x0
	nop
.L08029ac4:
	ldrh.w	r2, [r6, r1, lsl #0x1]
	cmp	r2, r0
	bne.n	.L08029b06
	add.w	r2, r6, r1, lsl #0x1
	ldrh	r3, [r2, #0x2]
	cmp	r3, r0
	bne.n	.L08029b06
	ldrh	r3, [r2, #0x4]
	cmp	r3, r0
	bne.n	.L08029b06
	ldrh	r2, [r2, #0x6]
	cmp	r2, r0
	bne.n	.L08029b06
	adds	r1, #0x4
	cmp.w	r1, #0x100
	bne.n	.L08029ac4
	movs	r6, #0x0
.L08029aec:
	ldrh.w	r1, [r10, r6]
	adds	r0, r6, r7
	bl	flash_program_halfword
	cmp	r0, #0x3
	bne.w	.L08029cc8
	adds	r6, #0x2
	cmp.w	r6, #0x200
	bne.n	.L08029aec
	b.n	.L08029cac
.L08029b06:
	ldr	r0, [r5]
	lsls	r0, r0, #0x1f
	bne.n	.L08029b4e
	ldr	r0, [r5]
	lsls	r0, r0, #0x1d
	bmi.n	.L08029b18
	ldr	r0, [r5]
	lsls	r0, r0, #0x1b
	bpl.n	.L08029b1c
.L08029b18:
	movs	r0, #0x14
	str	r0, [r5]
.L08029b1c:
	ldr	r0, [r5, #0x4]
	orr.w	r0, r0, #0x2
	str	r0, [r5, #0x4]
	str	r7, [r5, #0x8]
	ldr	r0, [r5, #0x4]
	orr.w	r0, r0, #0x40
	str	r0, [r5, #0x4]
	ldr	r0, [r5]
	lsls	r0, r0, #0x1f
	bne.n	.L08029b72
	ldr	r0, [r5]
	lsls	r0, r0, #0x1d
	itt	pl
	ldrpl	r0, [r5]
	lslspl.w	r0, r0, #0x1b
	bmi.w	.L08029cc0
	ldr	r0, [r5, #0x4]
	bic.w	r0, r0, #0x2
	str	r0, [r5, #0x4]
	b.n	.L08029c70
.L08029b4e:
	mov.w	r0, #0x40000000
	nop
.L08029b54:
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029be8
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029bde
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029be2
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029be6
	subs	r0, #0x4
	bne.n	.L08029b54
	b.n	.L08029cc8
.L08029b72:
	mov.w	r0, #0x40000000
	nop
.L08029b78:
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c4e
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c14
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c18
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c1c
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c20
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c24
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c28
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c2c
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c30
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c34
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c38
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c3c
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c40
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c44
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c48
	ldr	r1, [r5]
	lsls	r1, r1, #0x1f
	beq.n	.L08029c4c
	subs	r0, #0x10
	bne.n	.L08029b78
	b.n	.L08029cc0
.L08029bde:
	subs	r0, #0x1
	b.n	.L08029be8
.L08029be2:
	subs	r0, #0x2
	b.n	.L08029be8
.L08029be6:
	subs	r0, #0x3
.L08029be8:
	ldr	r1, [r5]
	lsls	r1, r1, #0x1d
	bmi.n	.L08029c00
	ldr	r1, [r5]
	lsls	r1, r1, #0x1b
	mov.w	r1, #0x2
	it	pl
	movpl	r1, #0x3
	cmp	r0, #0x1
	bne.n	.L08029c06
	b.n	.L08029cc8
.L08029c00:
	movs	r1, #0x1
	cmp	r0, #0x1
	beq.n	.L08029cc8
.L08029c06:
	subs	r0, r1, #0x1
	and.w	r0, r0, #0x7
	cmp	r0, #0x1
	bls.w	.L08029b18
	b.n	.L08029b1c
.L08029c14:
	subs	r0, #0x1
	b.n	.L08029c4e
.L08029c18:
	subs	r0, #0x2
	b.n	.L08029c4e
.L08029c1c:
	subs	r0, #0x3
	b.n	.L08029c4e
.L08029c20:
	subs	r0, #0x4
	b.n	.L08029c4e
.L08029c24:
	subs	r0, #0x5
	b.n	.L08029c4e
.L08029c28:
	subs	r0, #0x6
	b.n	.L08029c4e
.L08029c2c:
	subs	r0, #0x7
	b.n	.L08029c4e
.L08029c30:
	subs	r0, #0x8
	b.n	.L08029c4e
.L08029c34:
	subs	r0, #0x9
	b.n	.L08029c4e
.L08029c38:
	subs	r0, #0xa
	b.n	.L08029c4e
.L08029c3c:
	subs	r0, #0xb
	b.n	.L08029c4e
.L08029c40:
	subs	r0, #0xc
	b.n	.L08029c4e
.L08029c44:
	subs	r0, #0xd
	b.n	.L08029c4e
.L08029c48:
	subs	r0, #0xe
	b.n	.L08029c4e
.L08029c4c:
	subs	r0, #0xf
.L08029c4e:
	ldr	r1, [r5]
	lsls	r1, r1, #0x1d
	bmi.n	.L08029cbe
	ldr	r1, [r5]
	lsls	r1, r1, #0x1b
	mov.w	r1, #0x2
	it	pl
	movpl	r1, #0x3
	cmp	r0, #0x1
	beq.n	.L08029cc0
	ldr	r0, [r5, #0x4]
	cmp	r1, #0x3
	bic.w	r0, r0, #0x2
	str	r0, [r5, #0x4]
	bne.n	.L08029cc8
.L08029c70:
	movs	r0, #0x0
	nop
.L08029c74:
	ldrh.w	r1, [r10, r0]
	add.w	r2, r10, r0
	strh	r1, [r6, r0]
	ldrh	r1, [r2, #0x2]
	adds	r3, r6, r0
	strh	r1, [r3, #0x2]
	ldrh	r1, [r2, #0x4]
	adds	r0, #0x8
	strh	r1, [r3, #0x4]
	ldrh	r1, [r2, #0x6]
	cmp.w	r0, #0x200
	strh	r1, [r3, #0x6]
	bne.n	.L08029c74
	movs	r4, #0x0
	nop
.L08029c98:
	ldrh	r1, [r6, r4]
	adds	r0, r4, r7
	bl	flash_program_halfword
	cmp	r0, #0x3
	bne.n	.L08029cc8
	adds	r4, #0x2
	cmp.w	r4, #0x800
	bne.n	.L08029c98
.L08029cac:
	ldr	r0, [r5, #0x4]
	orr.w	r0, r0, #0x80
	str	r0, [r5, #0x4]
	ldr	r0, [r5, #0x44]
	orr.w	r0, r0, #0x80
	str	r0, [r5, #0x44]
	b.n	.L08029cc8
.L08029cbe:
	cmp	r0, #0x1
.L08029cc0:
	ldr	r0, [r5, #0x4]
	bic.w	r0, r0, #0x2
	str	r0, [r5, #0x4]
.L08029cc8:
	movw	r0, #0x1070
	movt	r0, #0x2000
	ldrb	r1, [r0, #0x10]
	cbnz	r1, .L08029ce4
	ldr	r1, [r0]
	movs	r0, #0x0
	blx	r1
	movw	r4, #0x5434
	movt	r4, #0x4001
	b.n	.L08029d0c
.L08029ce4:
	ldr	r1, [r0, #0x8]
	movw	r4, #0x5434
	sub.w	r1, r10, r1
	lsrs	r2, r1, #0xa
	cmp	r2, #0xae
	movt	r4, #0x4001
	bhi.n	.L08029d0c
	ldr	r0, [r0, #0xc]
	lsrs	r2, r1, #0x5
	ldrh.w	r1, [r0, r2, lsl #0x1]
	cbz	r1, .L08029d0c
	add.w	r0, r0, r2, lsl #0x1
	lsls	r1, r1, #0x1
	bl	zero_bytes
.L08029d0c:
	ldr	r0, [r4]
	cmp	r0, #0x0
	movw	r0, #0x2d67
	movt	r0, #0x2000
	beq.n	.L08029d2a
	ldrb	r1, [r0]
	adds	r1, #0x1
	strb	r1, [r0]
	ldrb	r1, [r0]
	cmp	r1, #0xb
	blo.n	.L08029d2e
	movs	r1, #0x0
	str	r1, [r4]
.L08029d2a:
	movs	r1, #0x0
	strb	r1, [r0]
.L08029d2e:
	bl	settings_saved			@ usb_remote.s: restart after SETTINGS_SAVE, else PC9 low and
						@ power_off_wait (boot_install.s); not reached:
	nop.w					@ the next function keeps its address (same 18 bytes)
	nop.w
	nop.w
	nop

@ ----------------------------------------------------------------------------
@ fn_08029d40 - no parameters, no return value.
@ If word 0x20000f54 is 0 or byte 0x20000f50 is 0 (the code tests word
@ 0x200000f8+0xe5c and byte 0x200000f8+0xe58): clears bit 0 of 0x40001400,
@ clears the low 12 bits of 0x40007414, sets 0x380000 in 0x40007400, sets
@ bit 1 of 0x40007404, then 0x40007400 = (0x40007400 & 0xffc7ffff) | 0x100000.
@ Otherwise: n = word 0x20000f54 * 200 (unsigned), calls
@ compute_clock_frequencies (0x08031430) on a zeroed 5-word local buffer,
@ clears bit 0 of 0x40001400, writes 0x4000142c = 0x13 when n < 4000 else 1,
@ writes 0x40001428 = truncate(float(first buffer word) / x - 1.0) with
@ x = float(n) (float(n) * 10.0 when n < 4000), sets bit 0 of 0x40001414 and
@ then bit 0 of 0x40001400.
@ Purpose: writes 0x4000142c and 0x40001428 of the register block at
@ 0x40001400 from the word 0x20000f54 and sets bit 0 of 0x40001414 and
@ 0x40001400, or clears bit 0 of 0x40001400 and rewrites
@ 0x40007400..0x40007414; what the blocks do is not determined from the code.
@ ----------------------------------------------------------------------------
	.global fn_08029d40
	.thumb_func
	.type fn_08029d40, %function
fn_08029d40:
	push	{r4, r5, r7, lr}
	vpush	{d8}
	sub	sp, #0x18
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldr.w	r0, [r1, #0xe5c]
	movw	r4, #0x1400
	movt	r4, #0x4000
	cbz	r0, .L08029dd6
	ldrb.w	r1, [r1, #0xe58]
	cbz	r1, .L08029dd6
	movs	r1, #0xc8
	mul	r5, r0, r1
	movs	r0, #0x0
	vmov	s0, r5
	str	r0, [sp, #0x14]
	strd	r0, r0, [sp, #0xc]
	strd	r0, r0, [sp, #0x4]
	add	r0, sp, #0x4
	vcvt.f32.u32	s16, s0
	bl	compute_clock_frequencies
	ldr	r0, [r4]
	vmov.f32	s2, #10.0
	bic.w	r0, r0, #0x1
	str	r0, [r4]
	vldr	s0, [sp, #0x4]
	vmul.f32	s2, s16, s2
	vcvt.f32.u32	s0, s0
	cmp.w	r5, #0xfa0
	it	cc
	vmovcc.f32	s16, s2
	vdiv.f32	s0, s0, s16
	vmov.f32	s2, #-1.0
	mov.w	r0, #0x1
	it	cc
	movcc	r0, #0x13
	str	r0, [r4, #0x2c]
	vadd.f32	s0, s0, s2
	vcvt.u32.f32	s0, s0
	vstr	s0, [r4, #0x28]
	ldr	r0, [r4, #0x14]
	orr.w	r0, r0, #0x1
	str	r0, [r4, #0x14]
	ldr	r0, [r4]
	orr.w	r0, r0, #0x1
	str	r0, [r4]
	b.n	.L08029e0a
.L08029dd6:
	ldr	r0, [r4]
	movw	r2, #0xfff
	bic.w	r0, r0, #0x1
	str	r0, [r4]
	movw	r0, #0x7400
	movt	r0, #0x4000
	ldr	r1, [r0, #0x14]
	bics	r1, r2
	str	r1, [r0, #0x14]
	ldr	r1, [r0]
	movs	r2, #0x2
	orr.w	r1, r1, #0x380000
	str	r1, [r0]
	ldr	r1, [r0, #0x4]
	orr.w	r1, r1, #0x2
	str	r1, [r0, #0x4]
	ldr	r1, [r0]
	bfi	r1, r2, #0x13, #0x3
	str	r1, [r0]
.L08029e0a:
	add	sp, #0x18
	vpop	{d8}
	pop	{r4, r5, r7, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_08033f7c - flash reset guard. No parameters.
@ Reads the halfword at 0x1ffff810; when its low byte != 0xfe it writes
@ 0x45670123 then 0xcdef89ab to 0x40022004 and again to 0x40022044, calls
@ fn_080363e4 (0x080363e4) and fn_080365ec (0x080365ec), then calls
@ reset_system (0x0803b070), which does not return. Otherwise returns.
@ ----------------------------------------------------------------------------
	.section .text.fn_08033f7c,"ax",%progbits
	.global fn_08033f7c
	.thumb_func
	.type fn_08033f7c, %function
fn_08033f7c:
	push	{r7, lr}
	movw	r0, #0xf810
	movt	r0, #0x1fff
	ldrh	r0, [r0]
	uxtb	r0, r0
	cmp	r0, #0xfe
	it	eq
	popeq	{r7, pc}
	movw	r0, #0x2004
	movw	r1, #0x123
	movw	r2, #0x89ab
	movt	r0, #0x4002
	movt	r1, #0x4567
	movt	r2, #0xcdef
	str	r1, [r0]
	str	r2, [r0]
	str	r1, [r0, #0x40]
	str	r2, [r0, #0x40]
	bl	fn_080363e4
	bl	fn_080365ec
	bl	reset_system

@ ----------------------------------------------------------------------------
@ fn_08033fbc - sets attribute bits 0x06 on the entry "2:/Screenshot simple
@ file". No parameters, no return value.
@ Resolves the path "2:/Screenshot simple file" with mount_fat_volume
@ (0x0803a7a0)(&path, &base, 2) and, when that returns 0, looks it up with
@ path_resolve (0x080366d8) on an iterator whose base is the result. The
@ result is 6 when the lookup returned 0 and byte iterator+0x2b & 0xa0 is
@ nonzero; a nonzero lookup result is kept. When the final result is 0 it
@ sets bits 0x06 in byte entry+0xb (entry = iterator[7]), writes 1 to byte
@ base+3 (dirty flag) and calls fat_sync_volume (0x0803d934)(base), which
@ writes the dirty window back.
@ ----------------------------------------------------------------------------
	.global fn_08033fbc_unlocked
	.thumb_func
	.type fn_08033fbc_unlocked, %function
fn_08033fbc_unlocked:
	push	{r4, lr}
	sub	sp, #0x38
	movw	r0, #:lower16:d_080bc18a+1
	movt	r0, #:upper16:d_080bc18a+1
	str	r0, [sp, #0x34]
	add	r0, sp, #0x34
	mov	r1, sp
	movs	r2, #0x2
	bl	mount_fat_volume
	cbz	r0, .L08033fda
.L08033fd6:
	add	sp, #0x38
	pop	{r4, pc}
.L08033fda:
	ldr	r4, [sp]
	ldr	r1, [sp, #0x34]
	add	r0, sp, #0x4
	str	r4, [sp, #0x4]
	bl	path_resolve
	ldrb.w	r1, [sp, #0x2f]
	ands.w	r1, r1, #0xa0
	it	ne
	movne	r1, #0x6
	cmp	r0, #0x0
	it	ne
	movne	r1, r0
	cmp	r1, #0x0
	bne.n	.L08033fd6
	ldr	r0, [sp, #0x20]
	ldrb	r1, [r0, #0xb]
	orr.w	r1, r1, #0x6
	strb	r1, [r0, #0xb]
	movs	r0, #0x1
	strb	r0, [r4, #0x3]
	mov	r0, r4
	bl	fat_sync_volume
	add	sp, #0x38
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ flash_program_halfword - programs halfword r1 at address r0 in
@ memory-mapped flash, chosen by address range.
@ (r0 & 0xfff80000) == 0x08080000 uses registers 0x40022050 (control) and
@ 0x4002204c (status); (r0 & 0xfff80000) == 0x08000000 uses 0x40022010 and
@ 0x4002200c; otherwise r0 < 0x08400000 returns 3; the remaining addresses
@ use 0x40022090 and 0x4002208c.
@ Sets bit 0 of control, stores the halfword at r0, polls status bit 0 up to
@ 0x100000 times, then returns 1 when status bit 2 is set, 3 when bit 4 is
@ clear and bit 2 clear, 2 when bit 4 is set; returns 4 when the poll count
@ ran out; clears control bit 0 on exit.
@ ----------------------------------------------------------------------------
	.section .text.flash_program_halfword,"ax",%progbits
	.global flash_program_halfword
	.thumb_func
	.type flash_program_halfword, %function
flash_program_halfword:
	mov	r2, r0
	movs	r3, #0x0
	bfc	r2, #0x0, #0x13
	movt	r3, #0x808
	cmp	r2, r3
	beq.n	.L08035b48
	cmp.w	r2, #0x8000000
	bne.n	.L08035b70
	movw	r2, #0x200c
	movt	r2, #0x4002
	ldr	r3, [r2, #0x4]
	orr.w	r3, r3, #0x1
	str	r3, [r2, #0x4]
	strh	r1, [r0]
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	bne.n	.L08035bb8
	mov	r1, r2
	ldr.w	r0, [r1], #0x4
	lsls	r0, r0, #0x1d
	bmi.w	.L08035d60
	ldr.w	r0, [r2], #0x4
	lsls	r0, r0, #0x1b
	mov.w	r0, #0x2
	it	pl
	movpl	r0, #0x3
	mov	r1, r2
	b.n	.L08035e92
.L08035b48:
	movw	r2, #0x200c
	movt	r2, #0x4002
	ldr	r3, [r2, #0x44]
	orr.w	r3, r3, #0x1
	str	r3, [r2, #0x44]
	strh	r1, [r0]
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	bne.n	.L08035c42
	ldr	r0, [r2, #0x40]
	add.w	r1, r2, #0x44
	lsls	r0, r0, #0x1d
	bmi.w	.L08035d64
	ldr	r0, [r2, #0x40]
	b.n	.L08035bac
.L08035b70:
	cmp.w	r0, #0x8400000
	itt	cc
	movcc	r0, #0x3
	bxcc	lr
	movw	r2, #0x200c
	movt	r2, #0x4002
	ldr.w	r3, [r2, #0x84]
	orr.w	r3, r3, #0x1
	str.w	r3, [r2, #0x84]
	strh	r1, [r0]
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	bne.w	.L08035ccc
	ldr.w	r0, [r2, #0x80]
	add.w	r1, r2, #0x84
	lsls	r0, r0, #0x1d
	bmi.w	.L08035d68
	ldr.w	r0, [r2, #0x80]
.L08035bac:
	lsls	r0, r0, #0x1b
	mov.w	r0, #0x2
	it	pl
	movpl	r0, #0x3
	b.n	.L08035e92
.L08035bb8:
	mov.w	r1, #0x100000
.L08035bbc:
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dfe
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035d6c
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035d70
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035d84
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035d88
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035d9c
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035da0
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035da4
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dc0
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dc4
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dc8
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dcc
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035df0
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035df4
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035df8
	ldr	r0, [r2]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dfc
	subs	r1, #0x10
	bne.n	.L08035bbc
	b.n	.L08035e1e
.L08035c42:
	mov.w	r1, #0x100000
.L08035c46:
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e30
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035d74
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035d78
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035d8c
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035d90
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035da8
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dac
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035db0
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dd0
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dd4
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035dd8
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035ddc
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e22
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e26
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e2a
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e2e
	subs	r1, #0x10
	bne.n	.L08035c46
	b.n	.L08035e52
.L08035ccc:
	mov.w	r1, #0x100000
.L08035cd0:
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e66
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035d7c
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035d80
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035d94
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035d98
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035db4
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035db8
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035dbc
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035de0
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035de4
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035de8
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.n	.L08035dec
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e58
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e5c
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e60
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1f
	beq.w	.L08035e64
	subs	r1, #0x10
	bne.n	.L08035cd0
	b.n	.L08035e8c
.L08035d60:
	movs	r0, #0x1
	b.n	.L08035e92
.L08035d64:
	movs	r0, #0x1
	b.n	.L08035e92
.L08035d68:
	movs	r0, #0x1
	b.n	.L08035e92
.L08035d6c:
	subs	r1, #0x1
	b.n	.L08035dfe
.L08035d70:
	subs	r1, #0x2
	b.n	.L08035dfe
.L08035d74:
	subs	r1, #0x1
	b.n	.L08035e30
.L08035d78:
	subs	r1, #0x2
	b.n	.L08035e30
.L08035d7c:
	subs	r1, #0x1
	b.n	.L08035e66
.L08035d80:
	subs	r1, #0x2
	b.n	.L08035e66
.L08035d84:
	subs	r1, #0x3
	b.n	.L08035dfe
.L08035d88:
	subs	r1, #0x4
	b.n	.L08035dfe
.L08035d8c:
	subs	r1, #0x3
	b.n	.L08035e30
.L08035d90:
	subs	r1, #0x4
	b.n	.L08035e30
.L08035d94:
	subs	r1, #0x3
	b.n	.L08035e66
.L08035d98:
	subs	r1, #0x4
	b.n	.L08035e66
.L08035d9c:
	subs	r1, #0x5
	b.n	.L08035dfe
.L08035da0:
	subs	r1, #0x6
	b.n	.L08035dfe
.L08035da4:
	subs	r1, #0x7
	b.n	.L08035dfe
.L08035da8:
	subs	r1, #0x5
	b.n	.L08035e30
.L08035dac:
	subs	r1, #0x6
	b.n	.L08035e30
.L08035db0:
	subs	r1, #0x7
	b.n	.L08035e30
.L08035db4:
	subs	r1, #0x5
	b.n	.L08035e66
.L08035db8:
	subs	r1, #0x6
	b.n	.L08035e66
.L08035dbc:
	subs	r1, #0x7
	b.n	.L08035e66
.L08035dc0:
	subs	r1, #0x8
	b.n	.L08035dfe
.L08035dc4:
	subs	r1, #0x9
	b.n	.L08035dfe
.L08035dc8:
	subs	r1, #0xa
	b.n	.L08035dfe
.L08035dcc:
	subs	r1, #0xb
	b.n	.L08035dfe
.L08035dd0:
	subs	r1, #0x8
	b.n	.L08035e30
.L08035dd4:
	subs	r1, #0x9
	b.n	.L08035e30
.L08035dd8:
	subs	r1, #0xa
	b.n	.L08035e30
.L08035ddc:
	subs	r1, #0xb
	b.n	.L08035e30
.L08035de0:
	subs	r1, #0x8
	b.n	.L08035e66
.L08035de4:
	subs	r1, #0x9
	b.n	.L08035e66
.L08035de8:
	subs	r1, #0xa
	b.n	.L08035e66
.L08035dec:
	subs	r1, #0xb
	b.n	.L08035e66
.L08035df0:
	subs	r1, #0xc
	b.n	.L08035dfe
.L08035df4:
	subs	r1, #0xd
	b.n	.L08035dfe
.L08035df8:
	subs	r1, #0xe
	b.n	.L08035dfe
.L08035dfc:
	subs	r1, #0xf
.L08035dfe:
	ldr	r0, [r2]
	lsls	r0, r0, #0x1d
	bmi.n	.L08035e18
	ldr	r0, [r2]
	lsls	r0, r0, #0x1b
	mov.w	r0, #0x2
	it	pl
	movpl	r0, #0x3
	cmp	r1, #0x1
	beq.n	.L08035e1e
.L08035e14:
	adds	r1, r2, #0x4
	b.n	.L08035e92
.L08035e18:
	movs	r0, #0x1
	cmp	r1, #0x1
	bne.n	.L08035e14
.L08035e1e:
	adds	r1, r2, #0x4
	b.n	.L08035e90
.L08035e22:
	subs	r1, #0xc
	b.n	.L08035e30
.L08035e26:
	subs	r1, #0xd
	b.n	.L08035e30
.L08035e2a:
	subs	r1, #0xe
	b.n	.L08035e30
.L08035e2e:
	subs	r1, #0xf
.L08035e30:
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1d
	bmi.n	.L08035e4c
	ldr	r0, [r2, #0x40]
	lsls	r0, r0, #0x1b
	mov.w	r0, #0x2
	it	pl
	movpl	r0, #0x3
	cmp	r1, #0x1
	beq.n	.L08035e52
.L08035e46:
	add.w	r1, r2, #0x44
	b.n	.L08035e92
.L08035e4c:
	movs	r0, #0x1
	cmp	r1, #0x1
	bne.n	.L08035e46
.L08035e52:
	add.w	r1, r2, #0x44
	b.n	.L08035e90
.L08035e58:
	subs	r1, #0xc
	b.n	.L08035e66
.L08035e5c:
	subs	r1, #0xd
	b.n	.L08035e66
.L08035e60:
	subs	r1, #0xe
	b.n	.L08035e66
.L08035e64:
	subs	r1, #0xf
.L08035e66:
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1d
	bmi.n	.L08035e86
	ldr.w	r0, [r2, #0x80]
	lsls	r0, r0, #0x1b
	mov.w	r0, #0x2
	it	pl
	movpl	r0, #0x3
	cmp	r1, #0x1
	beq.n	.L08035e8c
.L08035e80:
	add.w	r1, r2, #0x84
	b.n	.L08035e92
.L08035e86:
	movs	r0, #0x1
	cmp	r1, #0x1
	bne.n	.L08035e80
.L08035e8c:
	add.w	r1, r2, #0x84
.L08035e90:
	movs	r0, #0x4
.L08035e92:
	ldr	r2, [r1]
	bic.w	r2, r2, #0x1
	str	r2, [r1]
	bx	lr
