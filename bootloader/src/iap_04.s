@ iap_04.s - IAP / virtual-disk helpers of the stock bootloader: directory-name parser, root-directory scan, flash erase wrapper, flash geometry setup, status display, sector builder, disk write handler.
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb
.ifdef SLOT
	.include "common/layout.inc"
.endif

@ ----------------------------------------------------------------------------
@ fn_08001b74 - parse the hexadecimal load address from a directory entry.
@ r0 = pointer to the 32-byte directory entry copy.
@ Returns 0xFFFFFFFF unless byte 0 is 0x41 ('A'). Reads bytes 1..6 as
@ hexadecimal digits (0-9, A-F, a-f; any other byte returns 0xFFFFFFFF), first
@ digit in bits 23..20 down to the last in bits 3..0. Returns 0xFFFFFFFF when
@ the value is below (word 0x20000418 - word 0x20000414) or above word
@ 0x2000041C; otherwise returns the value. Caller 0x08001F76.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001b74,"ax",%progbits
	.p2align 2
	.global fn_08001b74
	.thumb_func
	.type fn_08001b74, %function
fn_08001b74:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	movs	r5, #0
	movs	r3, #0x14		@ shift for the first digit (bits 23..20)
	movs	r2, #0			@ accumulated value
	mov	r1, r4
	ldrb	r0, [r1]
	cmp	r0, #0x41		@ 'A'
	beq.n	.L08001b8a
	subs	r0, r2, #1		@ return 0xFFFFFFFF
.L08001b88:
	pop	{r4, r5, r6, pc}
.L08001b8a:
	.inst.n	0x1c49		@ adds r1, r1, #1
	movs	r5, #0
	b.n	.L08001be2
.L08001b90:
	ldrb	r0, [r1]
	cmp	r0, #0x30
	blt.n	.L08001ba6
	ldrb	r0, [r1]
	cmp	r0, #0x39
	bgt.n	.L08001ba6
	ldrb	r0, [r1]
	subs	r0, #0x30
	lsls	r0, r3
	orrs	r2, r0
	b.n	.L08001bd8
.L08001ba6:
	ldrb	r0, [r1]
	cmp	r0, #0x41
	blt.n	.L08001bbc
	ldrb	r0, [r1]
	cmp	r0, #0x46
	bgt.n	.L08001bbc
	ldrb	r0, [r1]
	subs	r0, #0x37
	lsls	r0, r3
	orrs	r2, r0
	b.n	.L08001bd8
.L08001bbc:
	ldrb	r0, [r1]
	cmp	r0, #0x61
	blt.n	.L08001bd2
	ldrb	r0, [r1]
	cmp	r0, #0x66
	bgt.n	.L08001bd2
	ldrb	r0, [r1]
	subs	r0, #0x57
	lsls	r0, r3
	orrs	r2, r0
	b.n	.L08001bd8
.L08001bd2:
	mov.w	r0, #0xffffffff		@ not a hex digit
	b.n	.L08001b88
.L08001bd8:
	.inst.n	0x1c49		@ adds r1, r1, #1
	subs	r0, r3, #4
	uxtb	r3, r0
	adds	r0, r5, #1
	uxtb	r5, r0
.L08001be2:
	cmp	r5, #6
	blt.n	.L08001b90
	ldr	r0, .L08001c08
	ldr	r0, [r0, #4]
	ldr	r6, .L08001c08
	ldr	r6, [r6]
	subs	r0, r0, r6
	cmp	r0, r2
	bhi.n	.L08001bfc
	ldr	r0, .L08001c08
	ldr	r0, [r0, #8]
	cmp	r0, r2
	bcs.n	.L08001c02
.L08001bfc:
	mov.w	r0, #0xffffffff		@ out of range
	b.n	.L08001b88
.L08001c02:
	mov	r0, r2
	b.n	.L08001b88
	.short	0x0000			@ padding
.L08001c08:
	.word	0x20000414

@ ----------------------------------------------------------------------------
@ fn_08001c0c - scan the written root-directory data for the first entry and
@ copy it to RAM.
@ r0 = 0x4000 (unused), r1 = buffer holding the written root-directory data,
@ r2 = byte count; returns r2. Starts at entry index 2 (buffer offset 0x40) and
@ steps 32 bytes while index < 0x200 and offset < r2 and not (attribute byte at
@ entry+0xB == 0x20 and the attribute byte of the next entry (entry+0x2B) == 0).
@ If afterwards index+1 < 0x201 and offset < r2: copies that 32-byte entry to
@ RAM 0x200003F4 with 0x08001980; then if byte 0x2000007C == 1 clears it and,
@ when the size word 0x20000410 is nonzero and <= word 0x2000043C, sets
@ 0x2000043C = 0, state byte 0x20000440 = 2 and calls 0x0800208C; finally
@ zeroes halfwords 0x2000040A and 0x2000040C and word 0x2000043C. Otherwise
@ fills 0x200003F4 with 32 zero bytes (0x08001994). Caller 0x080020DA.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001c0c,"ax",%progbits
	.p2align 2
	.global fn_08001c0c
	.thumb_func
	.type fn_08001c0c, %function
fn_08001c0c:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r9, r0
	mov	r7, r1
	mov	r5, r2
	mov	r4, r7
	mov.w	r8, #2			@ entry index
	movs	r6, #0
	adds	r4, #0x20
	adds	r4, #0x20
	adds	r6, #0x40
.ifdef SLOT
@ Slot build: the entry chosen is the regular file with the largest size field (first one on equal
@ size), not the first file followed by an unused entry: a macOS "._" file (4 KB, written after the
@ file with long-name entries between) is no longer chosen instead of the firmware file.  Regular:
@ name byte 0 not 0xE5 (deleted), attribute bits 0x1E clear (not hidden, system, volume label,
@ directory or long-name part 0x0F).  A name byte 0 of 0x00 ends the directory.  r9 (r0 on entry,
@ unused) holds the best size, r10 the best entry (0 none), r7 its buffer offset.
	mov.w	r10, #0
.Lsel_entry:
	cmp	r6, r5
	bhs	.Lsel_done		@ end of the written data
	cmp.w	r6, #0x4000
	bhs	.Lsel_done		@ end of the root directory (512 entries)
	ldrb	r0, [r4, #0]
	cbz	r0, .Lsel_done		@ unused entry: end of the directory
	cmp	r0, #0xe5
	beq	.Lsel_next		@ deleted
	ldrb	r0, [r4, #0xb]
	tst	r0, #0x1e
	bne	.Lsel_next		@ not a regular file
	ldr	r0, [r4, #0x1c]		@ size field
	cmp	r10, #0
	beq	.Lsel_take
	cmp	r0, r9
	bls	.Lsel_next
.Lsel_take:
	mov	r10, r4
	mov	r9, r0
	mov	r7, r6
.Lsel_next:
	adds	r4, #0x20
	adds	r6, #0x20
	b	.Lsel_entry
.Lsel_done:
	movs	r8, #2			@ any index <= 0x200 for the test at .L08001c48
	cmp	r10, #0
	itee	eq
	moveq	r6, r5			@ none: offset = count, so the entry copy is cleared
	movne	r4, r10
	movne	r6, r7
	b	.L08001c48
.else
	b.n	.L08001c38
.L08001c26:
	ldrb	r0, [r4, #0xb]
	cmp	r0, #0x20
	bne.n	.L08001c34
	movs	r0, #0x2b
	ldrb	r0, [r0, r4]
	cbnz	r0, .L08001c34
	b.n	.L08001c48
.L08001c34:
	adds	r4, #0x20
	adds	r6, #0x20
.L08001c38:
	mov	r0, r8
	add.w	r8, r8, #1
	cmp.w	r0, #0x200
	bcs.n	.L08001c48
	cmp	r6, r5
	bcc.n	.L08001c26
.endif
.L08001c48:
	nop
	cmp.w	r8, #0x200
	bhi.n	.L08001c9c
	cmp	r6, r5
	bcs.n	.L08001c9c
	movs	r2, #0x20
	mov	r1, r4
	ldr	r0, .L08001cac
	bl	copy_bytes
	ldr	r0, .L08001cb0
	ldrb	r0, [r0]
	cmp	r0, #1
	bne.n	.L08001c8e
	movs	r0, #0
	ldr	r1, .L08001cb0
	strb	r0, [r1]
	ldr	r0, .L08001cac
	ldr	r0, [r0, #0x1c]
	cbz	r0, .L08001c8e
	ldr	r0, .L08001cb4
	ldr	r0, [r0, #0x28]
	ldr	r1, .L08001cac
	ldr	r1, [r1, #0x1c]
	cmp	r0, r1
	bcc.n	.L08001c8e
	movs	r0, #0
	ldr	r1, .L08001cb4
	str	r0, [r1, #0x28]
	movs	r0, #2
	strb.w	r0, [r1, #0x2c]
	bl	fn_0800208c
.L08001c8e:
	movs	r0, #0
	ldr	r1, .L08001cac
	strh	r0, [r1, #0x18]
	strh	r0, [r1, #0x16]
	ldr	r1, .L08001cb4
	str	r0, [r1, #0x28]
	b.n	.L08001ca6
.L08001c9c:
	movs	r2, #0x20
	movs	r1, #0
	ldr	r0, .L08001cac
	bl	fill_bytes
.L08001ca6:
	mov	r0, r5
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
.L08001cac:
	.word	0x200003f4
.L08001cb0:
	.word	0x2000007c
.L08001cb4:
	.word	0x20000414

@ ----------------------------------------------------------------------------
@ fn_08001cb8 - erase the application area of the flash.
@ Calls 0x080022A4, then 0x08002170(word 0x20000418 - word 0x20000424), then
@ 0x080020F8. Caller 0x08001F94.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001cb8,"ax",%progbits
	.p2align 2
	.global fn_08001cb8
	.thumb_func
	.type fn_08001cb8, %function
fn_08001cb8:
	push	{r4, lr}
	bl	flash_unlock_keys
	ldr	r1, .L08001cd4
	ldr	r1, [r1, #4]
	ldr	r2, .L08001cd4
	ldr	r2, [r2, #0x10]
	subs	r0, r1, r2
	bl	flash_erase_sector
	bl	fn_080020f8
	pop	{r4, pc}
	.short	0x0000			@ padding
.L08001cd4:
	.word	0x20000414

@ ----------------------------------------------------------------------------
@ fn_08001cd8 - set up the flash geometry words in RAM.
@ Reads the word at 0x1FFFF7E0 (v) and stores: 0x20000414 = 0x08000000,
@ 0x20000418 = 0x08007000, 0x20000438 = 0x08007000, 0x2000041C = v << 10,
@ 0x20000420 = (v << 10) - 0x7000; if v <= 0xFF: 0x20000424 = 0x400 and
@ 0x20000428 = 0x3FF, else 0x800 and 0x7FF. Caller 0x08002946.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001cd8,"ax",%progbits
	.p2align 2
	.global fn_08001cd8
	.thumb_func
	.type fn_08001cd8, %function
fn_08001cd8:
	ldr	r1, .L08001d20
	ldr	r0, [r1]
	mov.w	r1, #0x8000000
	ldr	r2, .L08001d24
	str	r1, [r2]
	ldr	r1, .L08001d28
	str	r1, [r2, #4]
	str	r1, [r2, #0x24]
	lsls	r1, r0, #10
.ifdef SLOT
	cmp	r1, #APP_AREA_SIZE	@ slot build: the area ends at APP_END (0x08000000 + 0xE7000), below
	it	hi			@ the record pages and the slots, whatever the flash size word says
	movhi	r1, #APP_AREA_SIZE
.endif
	str	r1, [r2, #8]
	mov	r1, r2
	ldr	r1, [r1, #4]
	ldr	r2, [r2]
	subs	r1, r1, r2
	ldr	r2, .L08001d24
	ldr	r2, [r2, #8]
	subs	r1, r2, r1
	ldr	r2, .L08001d24
	str	r1, [r2, #0xc]
	cmp	r0, #0xff
	bhi.n	.L08001d10
	mov.w	r1, #0x400
	str	r1, [r2, #0x10]
	.inst.n	0x1e49		@ subs r1, r1, #1
	str	r1, [r2, #0x14]
	b.n	.L08001d1c
.L08001d10:
	mov.w	r1, #0x800
	ldr	r2, .L08001d24
	str	r1, [r2, #0x10]
	.inst.n	0x1e49		@ subs r1, r1, #1
	str	r1, [r2, #0x14]
.L08001d1c:
	bx	lr
	.short	0x0000			@ padding
.L08001d20:
	.word	0x1ffff7e0
.L08001d24:
	.word	0x20000414
.L08001d28:
	.word	0x08007000

@ ----------------------------------------------------------------------------
@ fn_08001d2c - show the status text when the state byte changes.
@ Compares state byte 0x20000440 with 0x20000004; if equal returns. Otherwise
@ copies 0x20000440 to 0x20000004 and switches: 0 -> 0x08002058("Ready", 5);
@ 1 -> nothing; 2 -> 0x08002058("Success", 7), 0x20000440 = 6, 0x08003678(),
@ 0x080018C4(1000), 0x08002784(word 0x20000438); 3 -> "Failed" (6),
@ 0x20000440 = 6, 0x08003678(); 4 -> "Large" (5), 0x20000440 = 6,
@ 0x08003678(); 5 -> "Unkown" (6); 6 -> nothing; 7 -> 0x08002058("Jump", 6)
@ (copies the two zero bytes after the string), 0x080018C4(1000),
@ 0x08002784(word 0x20000438). Strings at 0x08001DF4.. . Caller 0x08002A10.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001d2c,"ax",%progbits
	.p2align 2
	.global fn_08001d2c
	.thumb_func
	.type fn_08001d2c, %function
fn_08001d2c:
	push	{r4, lr}
	ldr	r0, .L08001dec
	ldrb.w	r0, [r0, #0x2c]
	ldr	r1, .L08001df0
	ldrb	r1, [r1]
	cmp	r0, r1
	bne.n	.L08001d3e
.L08001d3c:
	pop	{r4, pc}
.L08001d3e:
	ldr	r0, .L08001dec
	ldrb.w	r0, [r0, #0x2c]
	ldr	r1, .L08001df0
	strb	r0, [r1]
	ldr	r0, .L08001dec
	ldrb.w	r0, [r0, #0x2c]
	cmp	r0, #8
	bcs.n	.L08001de2
	tbb	[pc, r0]
.L08001d56:
	.byte	(.L08001d5e - .L08001d56)/2
	.byte	(.L08001d68 - .L08001d56)/2
	.byte	(.L08001d6a - .L08001d56)/2
	.byte	(.L08001d90 - .L08001d56)/2
	.byte	(.L08001da6 - .L08001d56)/2
	.byte	(.L08001dbc - .L08001d56)/2
	.byte	(.L08001dc6 - .L08001d56)/2
	.byte	(.L08001dc8 - .L08001d56)/2
.L08001d5e:
	movs	r1, #5
	adr	r0, .L08001df4
	bl	fn_08002058
	b.n	.L08001de4
.L08001d68:
	b.n	.L08001de4
.L08001d6a:
	movs	r1, #7
	adr	r0, .L08001dfc
	bl	fn_08002058
	movs	r0, #6
	ldr	r1, .L08001dec
	strb.w	r0, [r1, #0x2c]
	bl	fn_08003678
	mov.w	r0, #0x3e8
	bl	systick_delay
	ldr	r1, .L08001dec
	ldr	r0, [r1, #0x24]
	bl	fn_08002784
	b.n	.L08001de4
.L08001d90:
	movs	r1, #6
	adr	r0, .L08001e04
	bl	fn_08002058
	movs	r0, #6
	ldr	r1, .L08001dec
	strb.w	r0, [r1, #0x2c]
	bl	fn_08003678
	b.n	.L08001de4
.L08001da6:
	movs	r1, #5
	adr	r0, .L08001e0c
	bl	fn_08002058
	movs	r0, #6
	ldr	r1, .L08001dec
	strb.w	r0, [r1, #0x2c]
	bl	fn_08003678
	b.n	.L08001de4
.L08001dbc:
	movs	r1, #6
	adr	r0, .L08001e14
	bl	fn_08002058
	b.n	.L08001de4
.L08001dc6:
	b.n	.L08001de4
.L08001dc8:
	movs	r1, #6
	adr	r0, .L08001e1c
	bl	fn_08002058
	mov.w	r0, #0x3e8
	bl	systick_delay
	ldr	r1, .L08001dec
	ldr	r0, [r1, #0x24]
	bl	fn_08002784
	b.n	.L08001de4
.L08001de2:
	nop
.L08001de4:
	nop
	nop
	b.n	.L08001d3c
	.short	0x0000			@ padding
.L08001dec:
	.word	0x20000414
.L08001df0:
	.word	0x20000004
.L08001df4:
	.asciz	"Ready"
	.short	0x0000			@ padding
.L08001dfc:
	.asciz	"Success"
.L08001e04:
	.asciz	"Failed"
	.byte	0x00			@ padding
.L08001e0c:
	.asciz	"Large"
	.short	0x0000			@ padding
.L08001e14:
	.asciz	"Unkown"
	.byte	0x00			@ padding
.L08001e1c:
	.asciz	"Jump"
	.byte	0x00, 0x00, 0x00	@ padding

@ ----------------------------------------------------------------------------
@ fn_08001e24 - build one 2048-byte sector of the virtual disk.
@ r0 = byte offset, r1 = buffer; r2 unused; returns 0x800. Offset 0: copies
@ 0x3E bytes from RAM 0x2000002C, zero fills from buffer offset 0x40 to 0x7FF
@ (bytes 0x3E and 0x3F are not written), stores 0x55 at 0x1FE and 0xAA at
@ 0x1FF. Offset 0x3000 or 0x3800: copies 4 bytes from 0x080049D3 (F8 FF FF FF),
@ zero fills the rest. Offset 0x4000: copies 11 bytes from RAM 0x2000006A
@ (status name field, initially "Ready   "), then 0x2F bytes from 0x080049A4
@ (starts at the string " "), zero fills the rest. Any other offset: 2048 zero
@ bytes. Caller 0x08002AA2.
@ ----------------------------------------------------------------------------
	.section .text.fn_08001e24,"ax",%progbits
	.p2align 2
	.global fn_08001e24
	.thumb_func
	.type fn_08001e24, %function
fn_08001e24:
	push	{r4, r5, r6, r7, lr}
	mov	r6, r0
	mov	r5, r1
	mov	r7, r2
	movs	r4, #0
	cbz	r6, .L08001e44
	cmp.w	r6, #0x3000
	beq.n	.L08001e6c
	cmp.w	r6, #0x3800
	beq.n	.L08001e6e
	cmp.w	r6, #0x4000
	bne.n	.L08001eae
	b.n	.L08001e88
.L08001e44:
	movs	r2, #0x3e
	ldr	r1, .L08001ec8
	mov	r0, r5
	bl	copy_bytes
	add	r4, r0
	.inst.n	0x1ca4		@ adds r4, r4, #2
	rsb.w	r2, r4, #0x800
	adds	r0, r5, r4
	movs	r1, #0
	bl	fill_bytes
	movs	r0, #0x55
	strb.w	r0, [r5, #0x1fe]
	movs	r0, #0xaa
	strb.w	r0, [r5, #0x1ff]
	b.n	.L08001ebe
.L08001e6c:
	nop
.L08001e6e:
	movs	r2, #4
	ldr	r1, .L08001ecc
	mov	r0, r5
	bl	copy_bytes
	add	r4, r0
	rsb.w	r2, r4, #0x800
	adds	r0, r5, r4
	movs	r1, #0
	bl	fill_bytes
	b.n	.L08001ebe
.L08001e88:
	movs	r2, #0xb
	ldr	r1, .L08001ed0
	mov	r0, r5
	bl	copy_bytes
	add	r4, r0
	adds	r0, r5, r4
	movs	r2, #0x2f
	ldr	r1, .L08001ed4
	bl	copy_bytes
	add	r4, r0
	rsb.w	r2, r4, #0x800
	adds	r0, r5, r4
	movs	r1, #0
	bl	fill_bytes
	b.n	.L08001ebe
.L08001eae:
	movs	r4, #0
	rsb.w	r2, r4, #0x800
	adds	r0, r5, r4
	movs	r1, #0
	bl	fill_bytes
	nop
.L08001ebe:
	nop
	mov.w	r0, #0x800
	pop	{r4, r5, r6, r7, pc}
	.short	0x0000			@ padding
.L08001ec8:
	.word	0x2000002c
.L08001ecc:
	.word	d_080049d2+1
.L08001ed0:
	.word	0x2000006a
.L08001ed4:
	.word	d_080049a4

@ ----------------------------------------------------------------------------
@ fn_08001ed8 - handle a write into the data area of the virtual disk.
@ r0 = byte offset (unused here), r1 = data buffer, r2 = byte count; returns r2
@ (clamped, see below) or 0 when state byte 0x20000440 is 6 or 2. If words
@ 0x20000080 and 0x20000084 are both 0 they take the first two words of r1.
@ Accepts when the extension at 0x200003FC equals "BIN" or "bin", or when
@ (word 0x20000080 & 0xF0000000) == 0x20000000 and (word 0x20000084 &
@ 0xFF000000) == 0x08000000; otherwise if the name at 0x200003F4 starts with
@ "JUMP" sets state 0x20000440 = 7. When accepted: if size word 0x20000410 == 0
@ it is set to word 0x20000420 and byte 0x2000007C = 1. State 0: target
@ 0x20000438 = 0x08007000 when 0x08001B74(0x200003F4) returns -1, else word
@ 0x20000414 + result; calls 0x08001CB8; state = 1. If word 0x20000420 < size:
@ state = 4. Else r2 = min(r2, size - word 0x2000043C), calls
@ 0x08002478(0x20000438 + 0x2000043C, r1, r2), adds r2 to 0x2000043C; result 0:
@ when 0x2000043C >= size sets 0x2000043C = 0, state = 2, clears 0x20000080 and
@ 0x20000084, calls 0x0800208C; nonzero: 0x2000043C = 0, state = 3. Epilogue
@ 0x08001F50 / 0x0800202C. Caller 0x080020EC.
@ Group 116: this unit, fn_08001f50, fn_0800200c, fn_08002018 and fn_0800202c
@ share one section (16-bit branches, adr and literal loads between them).
@ ----------------------------------------------------------------------------
	.section .text.fn_08001ed8,"ax",%progbits
	.p2align 2
	.global fn_08001ed8
	.thumb_func
	.type fn_08001ed8, %function
fn_08001ed8:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r9, r0
	mov	r5, r1
	mov	r4, r2
	ldr	r0, .L08002030
	ldr	r6, [r0, #0x1c]
	mov.w	r8, #0
	ldr	r0, .L08002034
	ldr	r0, [r0]
	cbnz	r0, .L08001f02
	ldr	r0, .L08002038
	ldr	r0, [r0]
	cbnz	r0, .L08001f02
	ldr	r1, .L08002034
	ldr	r0, [r5]
	str	r0, [r1]
	ldr	r1, .L08002038
	ldr	r0, [r5, #4]
	str	r0, [r1]
.L08001f02:
.ifdef SLOT
@ Slot build: for the default target (no "A"+hex name, fn_08001b74 returns -1) only content that
@ starts with an application vector table is accepted, whatever the extension: word 0 (0x20000080)
@ a stack pointer RAM_LO < sp <= RAM_HI, word 1 (0x20000084) odd and inside APP_BASE..APP_END
@ (BOOTLOADER_DESIGN.md rev 2 (8); an AppleDouble "._" file starts with 0x00051607).  Anything else
@ goes to the "JUMP" name test as in the stock code.  "A"+hex targets keep the stock rule below.
	ldr	r0, .L08002030
	bl	fn_08001b74
	adds	r0, #1
	bne	.Lacc_stock		@ "A"+hex name
	ldr	r0, .L08002034
	ldr	r0, [r0]		@ word 0
	movw	r1, #:lower16:RAM_LO
	movt	r1, #:upper16:RAM_LO
	cmp	r0, r1
	bls	fn_08002018
	movw	r1, #:lower16:RAM_HI
	movt	r1, #:upper16:RAM_HI
	cmp	r0, r1
	bhi	fn_08002018
	ldr	r0, .L08002038
	ldr	r0, [r0]		@ word 1
	tst	r0, #1
	beq	fn_08002018
	movw	r1, #:lower16:APP_BASE
	movt	r1, #:upper16:APP_BASE
	cmp	r0, r1
	blo	fn_08002018
	movw	r1, #:lower16:APP_END
	movt	r1, #:upper16:APP_END
	cmp	r0, r1
	bhs	fn_08002018
	b	.L08001f3a
.Lacc_stock:
.endif
	movs	r2, #3
	adr	r1, .L0800203c
	ldr	r0, .L08002030
	adds	r0, #8
	bl	compare_bytes
	cbz	r0, .L08001f3a
	movs	r2, #3
	adr	r1, .L08002040
	ldr	r0, .L08002030
	adds	r0, #8
	bl	compare_bytes
	cbz	r0, .L08001f3a
	ldr	r0, .L08002034
	ldr	r0, [r0]
	and.w	r0, r0, #0xf0000000
	cmp.w	r0, #0x20000000
.ifdef SLOT
	bne.w	fn_08002018		@ slot build: the size check at .L08001f94 puts it out of 16-bit reach
.else
	bne.n	fn_08002018
.endif
	ldr	r0, .L08002038
	ldr	r0, [r0]
	and.w	r0, r0, #0xff000000
	cmp.w	r0, #0x8000000
.ifdef SLOT
	bne.w	fn_08002018		@ slot build: the size check at .L08001f94 puts it out of 16-bit reach
.else
	bne.n	fn_08002018
.endif
.L08001f3a:
	ldr	r0, .L08002044
	ldrb.w	r0, [r0, #0x2c]
	cmp	r0, #6
	beq.n	.L08001f4e
	ldr	r0, .L08002044
	ldrb.w	r0, [r0, #0x2c]
	cmp	r0, #2
	bne.n	.L08001f54
.L08001f4e:
	movs	r0, #0

@ ----------------------------------------------------------------------------
@ fn_08001f50 - epilogue and body continuation of fn_08001ed8.
@ Epilogue only at its first instruction: pop {r4-r9, sl, pc}. Reached by
@ fall-through from 0x08001F4E (movs r0,#0: returns r0 = 0 for states 6 and 2,
@ branched to from 0x08001F42 and 0x08001F4C) and by the branch at 0x0800202E
@ (via 0x0800202C); belongs to 0x08001ED8. Caller of 0x08001ED8 is 0x080020EC.
@ The code after the pop (0x08001F54..0x0800200A) is the accepted-write path of
@ fn_08001ed8 (see its header).
@ ----------------------------------------------------------------------------
	.global fn_08001f50
	.thumb_func
	.type fn_08001f50, %function
fn_08001f50:
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
.L08001f54:
	ldr	r0, .L08002030
	ldr	r0, [r0, #0x1c]
	cbnz	r0, .L08001f68
	ldr	r0, .L08002044
	ldr	r0, [r0, #0xc]
	ldr	r1, .L08002030
	str	r0, [r1, #0x1c]
	movs	r0, #1
	ldr	r1, .L08002048
	strb	r0, [r1]
.L08001f68:
	ldr	r0, .L08002030
	ldr	r6, [r0, #0x1c]
	ldr	r0, .L08002044
	ldrb.w	r0, [r0, #0x2c]
	cbnz	r0, .L08001fa0
	ldr	r0, .L08002030
	bl	fn_08001b74
	mov	r8, r0
	add.w	r0, r8, #1
	cbnz	r0, .L08001f8a
	ldr	r0, .L0800204c
	ldr	r1, .L08002044
	str	r0, [r1, #0x24]
	b.n	.L08001f94
.L08001f8a:
	ldr	r0, .L08002044
	ldr	r0, [r0]
	add	r0, r8
	ldr	r1, .L08002044
	str	r0, [r1, #0x24]
.L08001f94:
.ifdef SLOT
	ldr	r0, .L08002044		@ slot build: the size against the room from the target to APP_END
	ldr	r0, [r0, #0x24]		@ before fn_08001cb8 erases the "8KTA" page: a file that is too
	movw	r1, #:lower16:APP_END	@ large leaves the installed application startable
	movt	r1, #:upper16:APP_END
	subs	r0, r1, r0
	ldr	r1, .L08002030
	ldr	r1, [r1, #0x1c]
	cmp	r0, r1
	bcc	.L0800200e		@ state 4 ("Large"), nothing erased
.endif
	bl	fn_08001cb8
	movs	r0, #1
	ldr	r1, .L08002044
	strb.w	r0, [r1, #0x2c]
.L08001fa0:
.ifdef SLOT
	ldr	r0, .L08002044		@ slot build: the size limit is the room from the target address
	ldr	r0, [r0, #0x24]		@ ([0x20000438]) to APP_END, so an "A"+hex target cannot run past
	movw	r1, #:lower16:APP_END	@ the application area (stock: [0x20000420] = flash - 0x7000)
	movt	r1, #:upper16:APP_END
	subs	r0, r1, r0
.else
	ldr	r0, .L08002044
	ldr	r0, [r0, #0xc]
.endif
	ldr	r1, .L08002030
	ldr	r1, [r1, #0x1c]
	cmp	r0, r1
	bcc.n	.L0800200e
	ldr	r0, .L08002044
	ldr	r0, [r0, #0x28]
	add	r0, r4
	cmp	r0, r6
	bcc.n	.L08001fbc
	ldr	r0, .L08002044
	ldr	r0, [r0, #0x28]
	subs	r4, r6, r0
.L08001fbc:
	ldr	r1, .L08002044
	ldr	r1, [r1, #0x24]
	ldr	r2, .L08002044
	ldr	r2, [r2, #0x28]
	adds	r0, r1, r2
	mov	r2, r4
	mov	r1, r5
	bl	fn_08002478
	mov	r7, r0
	ldr	r0, .L08002044
	ldr	r0, [r0, #0x28]
	add	r0, r4
	ldr	r1, .L08002044
	str	r0, [r1, #0x28]
	cbnz	r7, .L08001ffe
	mov	r0, r1
	ldr	r0, [r0, #0x28]
	cmp	r0, r6
	bcc.n	fn_0800202c
	movs	r0, #0
	str	r0, [r1, #0x28]
	movs	r0, #2
	strb.w	r0, [r1, #0x2c]
	movs	r0, #0
	ldr	r1, .L08002034
	str	r0, [r1]
	ldr	r1, .L08002038
	str	r0, [r1]
	bl	fn_0800208c
	b.n	fn_0800202c
.L08001ffe:
	movs	r0, #0
	ldr	r1, .L08002044
	str	r0, [r1, #0x28]
	movs	r0, #3
	strb.w	r0, [r1, #0x2c]
	b.n	fn_0800202c

@ ----------------------------------------------------------------------------
@ fn_0800200c - kept unreachable island (no flow or pointer reaches it): one
@ halfword b 0x08002018. Purpose not determined from the code. The bytes after
@ it (0x0800200E..0x08002016, label .L0800200e) are the state-4 branch of
@ fn_08001ed8 (taken from 0x08001FAA when word 0x20000420 < size): state
@ 0x20000440 = 4, then branch to 0x0800202C.
@ ----------------------------------------------------------------------------
	.global fn_0800200c
	.thumb_func
	.type fn_0800200c, %function
fn_0800200c:
	b.n	fn_08002018
.L0800200e:
	movs	r0, #4
	ldr	r1, .L08002044
	strb.w	r0, [r1, #0x2c]
	b.n	fn_0800202c

@ ----------------------------------------------------------------------------
@ fn_08002018 - check the file name for "JUMP".
@ Compares 4 bytes at RAM 0x200003F4 with "JUMP" (0x08002050) using
@ 0x08001960; when equal sets state byte 0x20000440 = 7, then continues into
@ 0x0800202C (mov r0,r4; branch to 0x08001F50). References: the island branch
@ at 0x0800200C and the branches at 0x08001F2A and 0x08001F38 inside
@ 0x08001ED8 (taken when the extension is not "BIN"/"bin" and the first two
@ data words fail the 0x2/0x08 high-bit tests). Purpose not determined from
@ the code.
@ ----------------------------------------------------------------------------
	.global fn_08002018
	.thumb_func
	.type fn_08002018, %function
fn_08002018:
	movs	r2, #4
	adr	r1, .L08002050
	ldr	r0, .L08002030
	bl	compare_bytes
	cbnz	r0, .L0800202c		@ local alias of fn_0800202c (cbnz cannot use a global symbol)
	movs	r0, #7
	ldr	r1, .L08002044
	strb.w	r0, [r1, #0x2c]

@ ----------------------------------------------------------------------------
@ fn_0800202c - tail stub of fn_08001ed8.
@ mov r0, r4 (the byte count) and branch to the epilogue 0x08001F50. Reached
@ from 0x08001FE2, 0x08001FFC, 0x0800200A, 0x08002016, 0x08002022 and by
@ fall-through from 0x08002018. Followed by the literal pool of the group.
@ ----------------------------------------------------------------------------
	.global fn_0800202c
	.thumb_func
	.type fn_0800202c, %function
fn_0800202c:
.L0800202c:
	mov	r0, r4
	b.n	fn_08001f50
.L08002030:
	.word	0x200003f4
.L08002034:
	.word	0x20000080
.L08002038:
	.word	0x20000084
.L0800203c:
	.asciz	"BIN"
.L08002040:
	.asciz	"bin"
.L08002044:
	.word	0x20000414
.L08002048:
	.word	0x2000007c
.L0800204c:
	.word	0x08007000
.L08002050:
	.asciz	"JUMP"
	.byte	0x00, 0x00, 0x00	@ padding

@ ----------------------------------------------------------------------------
@ fn_08002058 - store the status name into the root-directory entry.
@ r0 = text pointer, r1 = length. Copies min(r1, 8) bytes from the text to RAM
@ 0x2000006A (the name field of the root-directory entry, offset 0x13 of the
@ string at 0x20000057) and fills the remaining of the 8 bytes with 0x20.
@ Callers 0x08001D62, 0x08001D6E, 0x08001D94, 0x08001DAA, 0x08001DC0,
@ 0x08001DCC.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002058,"ax",%progbits
	.p2align 2
	.global fn_08002058
	.thumb_func
	.type fn_08002058, %function
fn_08002058:
	push	{r4, lr}
	mov	r2, r0
	movs	r0, #0
	nop
	b.n	.L0800206c
.L08002062:
	ldrb	r3, [r2, r0]
	ldr	r4, .L08002088
	strb	r3, [r4, r0]
	adds	r3, r0, #1
	uxtb	r0, r3
.L0800206c:
	cmp	r0, r1
	bge.n	.L08002074
	cmp	r0, #8
	blt.n	.L08002062
.L08002074:
	b.n	.L08002080
.L08002076:
	movs	r3, #0x20
	ldr	r4, .L08002088
	strb	r3, [r4, r0]
	adds	r3, r0, #1
	uxtb	r0, r3
.L08002080:
	cmp	r0, #8
	blt.n	.L08002076
	pop	{r4, pc}
	.short	0x0000			@ padding
.L08002088:
	.word	0x2000006a

@ ----------------------------------------------------------------------------
@ fn_0800208c - program the flash marker word at the start of the application
@ area.
@ Calls 0x080022A4, then 0x080023C4(word 0x20000418 - word 0x20000424,
@ 0x41544B38) (the value is the bytes 38 4B 54 41, "8KTA" at 0x080020AC), then
@ 0x080020F8. Callers 0x08001C8A and 0x08001FF8.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800208c,"ax",%progbits
	.p2align 2
	.global fn_0800208c
	.thumb_func
	.type fn_0800208c, %function
fn_0800208c:
	push	{r4, lr}
	bl	flash_unlock_keys
	ldr	r1, .L080020a8
	ldr	r1, [r1, #4]
	ldr	r2, .L080020a8
	ldr	r2, [r2, #0x10]
	subs	r0, r1, r2
	ldr	r1, .L080020ac
	bl	flash_program_word
	bl	fn_080020f8
	pop	{r4, pc}
.L080020a8:
	.word	0x20000414
.L080020ac:
	.word	0x41544b38

@ ----------------------------------------------------------------------------
@ fn_080020b0 - write dispatch for the virtual disk.
@ r0 = byte offset, r1 = buffer, r2 = byte count; returns r2. Offsets 0,
@ 0x3000 and 0x3800: nothing is done. Offset 0x4000: calls
@ 0x08001C0C(0x4000, r1, r2). Other offsets >= 0x8800: calls
@ 0x08001ED8(r0, r1, r2). All other offsets: nothing. Caller 0x08002ACC.
@ ----------------------------------------------------------------------------
	.section .text.fn_080020b0,"ax",%progbits
	.p2align 2
	.global fn_080020b0
	.thumb_func
	.type fn_080020b0, %function
fn_080020b0:
	push	{r4, r5, r6, lr}
	mov	r4, r0
	mov	r6, r1
	mov	r5, r2
	cbz	r4, .L080020ce
	cmp.w	r4, #0x3000
	beq.n	.L080020d0
	cmp.w	r4, #0x3800
	beq.n	.L080020d2
	cmp.w	r4, #0x4000
	bne.n	.L080020e0
	b.n	.L080020d4
.L080020ce:
	nop
.L080020d0:
	nop
.L080020d2:
	b.n	.L080020f2
.L080020d4:
	mov	r2, r5
	mov	r1, r6
	mov	r0, r4
	bl	fn_08001c0c
	b.n	.L080020f2
.L080020e0:
	cmp.w	r4, #0x8800
	bcc.n	.L080020f0
	mov	r2, r5
	mov	r1, r6
	mov	r0, r4
	bl	fn_08001ed8
.L080020f0:
	nop
.L080020f2:
	nop
	mov	r0, r5
	pop	{r4, r5, r6, pc}

@ ----------------------------------------------------------------------------
@ fn_08002784 - hand over to an image.
@ r0 = address of a record {word 0 = stack value, word 1 = entry address} (main
@ passes the word 0x20000418 = 0x08007000). Loads both words, calls
@ 0x080016dc(0x001c0017, 0) twice (clears bit 23 of word 0x4002101c), calls
@ 0x08001720(0x00100017, 1) then (0x00100017, 0) (sets then clears bit 23 of
@ word 0x40021010), writes the stack value to MSP (msr MSP), stores the entry
@ address at 0x20000000, calls it with blx. Returns only if the entry returns
@ (pop {pc}). No check of either word. Callers: 0x08001d8a, 0x08001ddc,
@ 0x0800298c.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002784,"ax",%progbits
	.p2align 2
	.global fn_08002784
	.thumb_func
	.type fn_08002784, %function
fn_08002784:
	push	{r4, r5, r6, lr}
	mov	r4, r0
.ifdef SLOT
	bl	slot_app_ok		@ slot build: r0 = vector table address; 0 = do not start it
	cbnz	r0, 1f
	pop	{r4, r5, r6, pc}	@ refused: back to the caller, which stays in update mode
1:	bl	slot_confirm		@ the bootloader got here: confirm its slot (TRIAL -> OK)
	bl	slot_quiesce		@ every NVIC interrupt and SysTick off, as after a reset
.endif
	ldr	r5, [r4]
	ldr	r6, [r4, #4]
	movs	r1, #0
	ldr	r0, .L080027c0
	bl	set_or_clear_bit_40021000_offset
	movs	r1, #0
	ldr	r0, .L080027c0
	bl	set_or_clear_bit_40021000_offset
	movs	r1, #1
	ldr	r0, .L080027c4
	bl	set_or_clear_bit_40021000_offset_b
	movs	r1, #0
	ldr	r0, .L080027c4
	bl	set_or_clear_bit_40021000_offset_b
	mov	r0, r5
	msr	msp, r0
	nop
	ldr	r0, .L080027c8
	str	r6, [r0]
	ldr	r0, [r0]
	blx	r0
	pop	{r4, r5, r6, pc}
	.short	0x0000			@ padding
.L080027c0:
	.word	0x001c0017
.L080027c4:
	.word	0x00100017
.L080027c8:
	.word	0x20000000

@ ----------------------------------------------------------------------------
@ fn_08002a60 - storage callback with index r0.
@ Callers: 0x08000b46 inside 0x08000b22, 0x08000e04 inside 0x08000dd4. When
@ r0 == 0 stores 0xfff through r1 and 0x800 through r2; r0 1 and 2 do nothing;
@ always returns 0. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002a60,"ax",%progbits
	.p2align 2
	.global fn_08002a60
	.thumb_func
	.type fn_08002a60, %function
fn_08002a60:
	mov	r3, r0
	cbz	r3, .L08002a6e
	cmp	r3, #1
	beq.n	.L08002a7c
	cmp	r3, #2
	bne.n	.L08002a80
	b.n	.L08002a7e
.L08002a6e:
	movw	r0, #0xfff
	str	r0, [r1]
	mov.w	r0, #0x800
	str	r0, [r2]
	b.n	.L08002a82
.L08002a7c:
	b.n	.L08002a82
.L08002a7e:
	b.n	.L08002a82
.L08002a80:
	nop
.L08002a82:
	nop
	movs	r0, #0
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08002a88 - storage callback: sector read.
@ r0 = index, r1, r2, r3 passed on; when r0 == 0 calls 0x08001e24(r1, r2, r3);
@ r0 == 1 does nothing; always returns 0. Caller: 0x0800103e.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002a88,"ax",%progbits
	.global fn_08002a88
	.thumb_func
	.type fn_08002a88, %function
fn_08002a88:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r7, r0
	mov	r4, r1
	mov	r5, r2
	mov	r6, r3
	cbz	r7, .L08002a9c
	cmp	r7, #1
	bne.n	.L08002aaa
	b.n	.L08002aa8
.L08002a9c:
	mov	r2, r6
	mov	r1, r5
	mov	r0, r4
	bl	fn_08001e24
	b.n	.L08002aaa
.L08002aa8:
	nop
.L08002aaa:
	nop
	movs	r0, #0
	pop.w	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ fn_08002ab2 - storage callback: sector write.
@ r0 = index, r1, r2, r3 passed on; when r0 == 0 calls 0x080020b0(r1, r2, r3);
@ r0 == 1 does nothing; always returns 0. Caller: 0x0800136c.
@ BOOTLOADER.md point 6 names 0x080020b0 as the write path that discards
@ boot-sector and FAT writes.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002ab2,"ax",%progbits
	.global fn_08002ab2
	.thumb_func
	.type fn_08002ab2, %function
fn_08002ab2:
	push.w	{r4, r5, r6, r7, r8, lr}
	mov	r7, r0
	mov	r4, r1
	mov	r5, r2
	mov	r6, r3
	cbz	r7, .L08002ac6
	cmp	r7, #1
	bne.n	.L08002ad4
	b.n	.L08002ad2
.L08002ac6:
	mov	r2, r6
	mov	r1, r5
	mov	r0, r4
	bl	fn_080020b0
	b.n	.L08002ad4
.L08002ad2:
	nop
.L08002ad4:
	nop
	movs	r0, #0
	pop.w	{r4, r5, r6, r7, r8, pc}
