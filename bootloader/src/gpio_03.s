@ gpio_03.s - GPIO pin setup routines of the stock bootloader (port groups 0x40010800..0x40011800) and the register / configuration-record helpers they use.
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ gpio_init_33c - first GPIO setup routine, called once from main at 0x0800294E.
@ No parameters, no return value. Uses a 16-byte local struct at sp: word 0 =
@ pin mask, bytes 4..7 = fields written by config_record_init_default (0x08002668)
@ and read by config_record_apply_nibbles (0x0800267E).
@ Calls set_or_clear_bit_40021000_offset (0x080016DC) with r1 = 1 four times,
@ r0 = 0x180002, 0x180003, 0x180004, 0x180006: each sets bit (r0 & 31) in the
@ word 0x40021000 + (r0 >> 16) = 0x40021018 (bits 2, 3, 4, 6).
@ config_record_init_default fills the struct (mask 0xFFFF, [4]=0, [5]=4, [6]=0,
@ [7]=1), then [4]=0, [7]=1, [6]=0 are written again.
@ Step 1: [5]=0x28, mask 0x80 on 0x40010C00 via config_record_apply_nibbles
@ (field [6]=0 path: 4-bit config 8, writes the mask to [port+0x14]).
@ Step 2: [5]=0x18, mask 0x2100 on 0x40011000 (config 8, writes the mask to
@ [port+0x10]).
@ Step 3: [6]=0x10, [7]=2: mask 0x180 on 0x40010800, mask 1 on 0x40010C00,
@ mask 0x420 on 0x40011000, mask 0xC on 0x40011800, each with config
@ (0x10 & 8) | ([4] & 4) | ([7] & 3) = 2. No [port+0x10] / [port+0x14] write
@ happens in the field [6] != 0 path of config_record_apply_nibbles, so no output
@ level is written for these pins.
@ Purpose beyond the register writes not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.gpio_init_33c,"ax",%progbits
	.p2align 2
	.global gpio_init_33c
	.thumb_func
	.type gpio_init_33c, %function
gpio_init_33c:
	push	{r2, r3, r4, lr}
	movs	r1, #1
	ldr	r0, .L080003e4
	bl	set_or_clear_bit_40021000_offset
	movs	r1, #1
	ldr	r0, .L080003e4
	.inst.n 0x1c40	@ adds r0, r0, #1
	bl	set_or_clear_bit_40021000_offset
	movs	r1, #1
	ldr	r0, .L080003e4
	.inst.n 0x1c80	@ adds r0, r0, #2
	bl	set_or_clear_bit_40021000_offset
	movs	r1, #1
	ldr	r0, .L080003e4
	.inst.n 0x1d00	@ adds r0, r0, #4
	bl	set_or_clear_bit_40021000_offset
	mov	r0, sp
	bl	config_record_init_default
	movs	r0, #0
	strb.w	r0, [sp, #4]
	movs	r0, #1
	strb.w	r0, [sp, #7]
	movs	r0, #0
	strb.w	r0, [sp, #6]
	movs	r0, #0x28		@ step 1: config byte 0x28, mask 0x80 on 0x40010C00
	strb.w	r0, [sp, #5]
	movs	r0, #0x80
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080003e8
	bl	config_record_apply_nibbles
	movs	r0, #0x18		@ step 2: config byte 0x18, mask 0x2100 on 0x40011000
	strb.w	r0, [sp, #5]
	mov.w	r0, #0x2100
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080003ec
	bl	config_record_apply_nibbles
	movs	r0, #0x10		@ step 3: [6] = 0x10, [7] = 2
	strb.w	r0, [sp, #6]
	movs	r0, #2
	strb.w	r0, [sp, #7]
	mov.w	r0, #0x180
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080003f0
	bl	config_record_apply_nibbles
	movs	r0, #1
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080003e8
	bl	config_record_apply_nibbles
	mov.w	r0, #0x420
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080003ec
	bl	config_record_apply_nibbles
	movs	r0, #0xc
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080003f4
	bl	config_record_apply_nibbles
	pop	{r2, r3, r4, pc}
.L080003e4:
	.word 0x00180002	@ argument base of the four set_or_clear_bit calls
.L080003e8:
	.word 0x40010c00	@ GPIO port base
.L080003ec:
	.word 0x40011000	@ GPIO port base
.L080003f0:
	.word 0x40010800	@ GPIO port base
.L080003f4:
	.word 0x40011800	@ GPIO port base

@ ----------------------------------------------------------------------------
@ gpio_init_3f8 - second GPIO setup routine, called once from main at 0x08002972,
@ only when reg8_all_bits_set(0x40011800, 4) at 0x0800295E returned 0 (r4 == 8
@ at 0x0800296E). No parameters, no return value.
@ Struct as in gpio_init_33c ([4]=0, [7]=1), 16 bytes at sp.
@ Inputs, [6]=0, [5]=0x18: mask 0x100 on 0x40010800, 0x400 on 0x40011000, 0x8 on
@ 0x40011800, config 8 and the mask written to [port+0x10].
@ Outputs, [6]=0x10, [5]=0x28 (config (0x10 & 8) | 0 | 1 = 1): mask 0x80 on
@ 0x40010800, 1 on 0x40010C00, 0x20 on 0x40011000, 0x4 on 0x40011800.
@ Then write_reg_0x14 (0x08002660) writes [port+0x14] = 0x80 (0x40010800),
@ 0x20 (0x40011000), 1 (0x40010C00), 4 (0x40011800).
@ The same pins as gpio_init_4b0 with input and output roles swapped.
@ ----------------------------------------------------------------------------
	.section .text.gpio_init_3f8,"ax",%progbits
	.p2align 2
	.global gpio_init_3f8
	.thumb_func
	.type gpio_init_3f8, %function
gpio_init_3f8:
	push	{r2, r3, r4, lr}
	mov	r0, sp
	bl	config_record_init_default
	movs	r0, #0
	strb.w	r0, [sp, #4]
	movs	r0, #1
	strb.w	r0, [sp, #7]
	movs	r0, #0
	strb.w	r0, [sp, #6]
	movs	r0, #0x18		@ inputs: config byte 0x18
	strb.w	r0, [sp, #5]
	mov.w	r0, #0x100
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080004a0
	bl	config_record_apply_nibbles
	mov.w	r0, #0x400
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080004a4
	bl	config_record_apply_nibbles
	movs	r0, #8
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080004a8
	bl	config_record_apply_nibbles
	movs	r0, #0x10		@ outputs: [6] = 0x10, config byte 0x28
	strb.w	r0, [sp, #6]
	movs	r0, #0x28
	strb.w	r0, [sp, #5]
	movs	r0, #0x80
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080004a0
	bl	config_record_apply_nibbles
	movs	r0, #1
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080004ac
	bl	config_record_apply_nibbles
	movs	r0, #0x20
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080004a4
	bl	config_record_apply_nibbles
	movs	r0, #4
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080004a8
	bl	config_record_apply_nibbles
	movs	r1, #0x80		@ output levels via [port+0x14]
	ldr	r0, .L080004a0
	bl	write_reg_0x14
	movs	r1, #0x20
	ldr	r0, .L080004a4
	bl	write_reg_0x14
	movs	r1, #1
	ldr	r0, .L080004ac
	bl	write_reg_0x14
	movs	r1, #4
	ldr	r0, .L080004a8
	bl	write_reg_0x14
	pop	{r2, r3, r4, pc}
	.short 0x0000		@ padding
.L080004a0:
	.word 0x40010800	@ GPIO port base
.L080004a4:
	.word 0x40011000	@ GPIO port base
.L080004a8:
	.word 0x40011800	@ GPIO port base
.L080004ac:
	.word 0x40010c00	@ GPIO port base

@ ----------------------------------------------------------------------------
@ gpio_init_4b0 - third GPIO setup routine, called once from main at 0x08002956;
@ main then reads one pin of 0x40011800 (mask 4) with reg8_all_bits_set.
@ No parameters, no return value.
@ Struct as in gpio_init_33c ([4]=0, [7]=1), 16 bytes at sp.
@ Inputs, [6]=0, [5]=0x18: mask 0x80 on 0x40010800, 1 on 0x40010C00, 0x20 on
@ 0x40011000, 0x4 on 0x40011800, config 8, mask written to [port+0x10].
@ Outputs, [6]=0x10, [5]=0x28 (config 1): mask 0x100 on 0x40010800, 0x400 on
@ 0x40011000, 0x8 on 0x40011800.
@ Then write_reg_0x14 (0x08002660) writes [port+0x14] = 8 (0x40011800),
@ 0x100 (0x40010800), 0x400 (0x40011000).
@ ----------------------------------------------------------------------------
	.section .text.gpio_init_4b0,"ax",%progbits
	.p2align 2
	.global gpio_init_4b0
	.thumb_func
	.type gpio_init_4b0, %function
gpio_init_4b0:
	push	{r2, r3, r4, lr}
	mov	r0, sp
	bl	config_record_init_default
	movs	r0, #0
	strb.w	r0, [sp, #4]
	movs	r0, #1
	strb.w	r0, [sp, #7]
	movs	r0, #0
	strb.w	r0, [sp, #6]
	movs	r0, #0x18		@ inputs: config byte 0x18
	strb.w	r0, [sp, #5]
	movs	r0, #0x80
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L08000554
	bl	config_record_apply_nibbles
	movs	r0, #1
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L08000558
	bl	config_record_apply_nibbles
	movs	r0, #0x20
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L0800055c
	bl	config_record_apply_nibbles
	movs	r0, #4
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L08000560
	bl	config_record_apply_nibbles
	movs	r0, #0x10		@ outputs: [6] = 0x10, config byte 0x28
	strb.w	r0, [sp, #6]
	movs	r0, #0x28
	strb.w	r0, [sp, #5]
	mov.w	r0, #0x100
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L08000554
	bl	config_record_apply_nibbles
	mov.w	r0, #0x400
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L0800055c
	bl	config_record_apply_nibbles
	movs	r0, #8
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L08000560
	bl	config_record_apply_nibbles
	movs	r1, #8			@ output levels via [port+0x14]
	ldr	r0, .L08000560
	bl	write_reg_0x14
	mov.w	r1, #0x100
	ldr	r0, .L08000554
	bl	write_reg_0x14
	mov.w	r1, #0x400
	ldr	r0, .L0800055c
	bl	write_reg_0x14
	pop	{r2, r3, r4, pc}
	.short 0x0000		@ padding
.L08000554:
	.word 0x40010800	@ GPIO port base
.L08000558:
	.word 0x40010c00	@ GPIO port base
.L0800055c:
	.word 0x40011000	@ GPIO port base
.L08000560:
	.word 0x40011800	@ GPIO port base

@ ----------------------------------------------------------------------------
@ gpio_40010c00_pin8_config_write_10 - configures pin 8 of port 0x40010C00 and
@ writes its output register. Called once from main at 0x080029AC. No
@ parameters, no return value.
@ set_or_clear_bit_40021000_offset(0x180003, 1) sets bit 3 of 0x40021018.
@ The struct comes from config_record_init_default with [4]=0, [7]=1, [5]=0x18,
@ [6]=0x10, mask 0x100.
@ config_record_apply_nibbles(0x40010C00, &struct) gives pin 8 the config
@ (0x10 & 8) | 0 | 1 = 1.
@ write_reg_0x10 (0x08002664) writes [0x40010C00 + 0x10] = 0x100.
@ Purpose of the pin not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.gpio_40010c00_pin8_config_write_10,"ax",%progbits
	.p2align 2
	.global gpio_40010c00_pin8_config_write_10
	.thumb_func
	.type gpio_40010c00_pin8_config_write_10, %function
gpio_40010c00_pin8_config_write_10:
	push	{r2, r3, r4, lr}
	movs	r1, #1
	ldr	r0, .L080005a4
	bl	set_or_clear_bit_40021000_offset
	mov	r0, sp
	bl	config_record_init_default
	movs	r0, #0
	strb.w	r0, [sp, #4]
	movs	r0, #1
	strb.w	r0, [sp, #7]
	movs	r0, #0x18
	strb.w	r0, [sp, #5]
	movs	r0, #0x10
	strb.w	r0, [sp, #6]
	lsls	r0, r0, #4		@ 0x10 << 4 = 0x100, pin 8 mask
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L080005a8
	bl	config_record_apply_nibbles
	mov.w	r1, #0x100
	ldr	r0, .L080005a8
	bl	write_reg_0x10
	pop	{r2, r3, r4, pc}
.L080005a4:
	.word 0x00180003	@ argument of set_or_clear_bit_40021000_offset
.L080005a8:
	.word 0x40010c00	@ GPIO port base

@ ----------------------------------------------------------------------------
@ gpio_40011000_pin9_config_write_14 - configures pin 9 of port 0x40011000 and
@ writes its output register. Called once from main at 0x08002952. No
@ parameters, no return value.
@ set_or_clear_bit_40021000_offset(0x180004, 1) sets bit 4 of 0x40021018.
@ The struct comes from config_record_init_default with [4]=0, [7]=1, [5]=0x18,
@ [6]=0x10, mask 0x200.
@ config_record_apply_nibbles(0x40011000, &struct) gives pin 9 config 1.
@ write_reg_0x14 (0x08002660) writes [0x40011000 + 0x14] = 0x200.
@ Purpose of the pin not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.gpio_40011000_pin9_config_write_14,"ax",%progbits
	.p2align 2
	.global gpio_40011000_pin9_config_write_14
	.thumb_func
	.type gpio_40011000_pin9_config_write_14, %function
gpio_40011000_pin9_config_write_14:
	push	{r2, r3, r4, lr}
	movs	r1, #1
	ldr	r0, .L08000974
	bl	set_or_clear_bit_40021000_offset
	mov	r0, sp
	bl	config_record_init_default
	movs	r0, #0
	strb.w	r0, [sp, #4]
	movs	r0, #1
	strb.w	r0, [sp, #7]
	movs	r0, #0x18
	strb.w	r0, [sp, #5]
	movs	r0, #0x10
	strb.w	r0, [sp, #6]
	lsls	r0, r0, #5		@ 0x10 << 5 = 0x200, pin 9 mask
	str	r0, [sp, #0]
	mov	r1, sp
	ldr	r0, .L08000978
	bl	config_record_apply_nibbles
	mov.w	r1, #0x200
	ldr	r0, .L08000978
	bl	write_reg_0x14
	pop	{r2, r3, r4, pc}
.L08000974:
	.word 0x00180004	@ argument of set_or_clear_bit_40021000_offset
.L08000978:
	.word 0x40011000	@ GPIO port base

@ ----------------------------------------------------------------------------
@ write_reg_0x14 - stores r1 at [r0 + 0x14].
@ Callers: 0x08000480, 0x08000488, 0x08000490, 0x08000498, 0x08000538,
@ 0x08000542, 0x0800054c, 0x080006f8, 0x0800096e and 0x08002a26 (main loop, base
@ 0x40011000, value 0x200).
@ ----------------------------------------------------------------------------
	.section .text.write_reg_0x14,"ax",%progbits
	.p2align 2
	.global write_reg_0x14
	.thumb_func
	.type write_reg_0x14, %function
write_reg_0x14:
	str	r1, [r0, #0x14]
	bx	lr

@ ----------------------------------------------------------------------------
@ write_reg_0x10 - stores r1 at [r0 + 0x10].
@ Callers: 0x0800059e, 0x080006ea, 0x08000706, 0x080029b6 (main, base 0x40011000,
@ value 0x200).
@ ----------------------------------------------------------------------------
	.section .text.write_reg_0x10,"ax",%progbits
	.p2align 2
	.global write_reg_0x10
	.thumb_func
	.type write_reg_0x10, %function
write_reg_0x10:
	str	r1, [r0, #0x10]
	bx	lr

@ ----------------------------------------------------------------------------
@ config_record_init_default - initialises the configuration record at r0 (the
@ record read by config_record_apply_nibbles): word [r0] = 0xffff, byte [r0+4] = 0,
@ byte [r0+5] = 4, byte [r0+6] = 0, byte [r0+7] = 1.
@ Callers: 0x08000366, 0x080003fc, 0x080004b4, 0x08000570, 0x08000940.
@ ----------------------------------------------------------------------------
	.section .text.config_record_init_default,"ax",%progbits
	.global config_record_init_default
	.thumb_func
	.type config_record_init_default, %function
config_record_init_default:
	movw	r1, #0xffff
	str	r1, [r0, #0]
	movs	r1, #0
	strb	r1, [r0, #6]
	strb	r1, [r0, #4]
	movs	r1, #4
	strb	r1, [r0, #5]
	movs	r1, #1
	strb	r1, [r0, #7]
	bx	lr

@ ----------------------------------------------------------------------------
@ config_record_apply_nibbles - applies a configuration record to a 4-bit-per-pin
@ register pair at r0. r0 = base, r1 = record (halfword [0] pin mask, bytes [4]
@ [5] [6] [7]).
@ Nibble value v (kept in r4): [6] == 3 gives 0; [6] == 0 gives [5] & 0xf and,
@ when [5] == 0x18, stores the pin mask at [r0 + 0x10], when [5] == 0x28 stores it
@ at [r0 + 0x14]; any other [6] gives ([6] & 8) | ([4] & 4) | ([7] & 3).
@ For each bit i of the low mask byte (when that byte is not 0): clears nibble i
@ in [r0] and ORs v << (4 * i).
@ When the mask is above 0xff: same for bits of mask >> 8 in [r0 + 4].
@ No return value.
@ Callers: 0x0800038a, 0x0800039e, 0x080003b8, 0x080003c4, 0x080003d2, 0x080003de,
@ 0x08000422, 0x08000430 and others.
@ ----------------------------------------------------------------------------
	.section .text.config_record_apply_nibbles,"ax",%progbits
	.global config_record_apply_nibbles
	.thumb_func
	.type config_record_apply_nibbles, %function
config_record_apply_nibbles:
	push	{r4, r5, r6, r7, lr}
	mov	r2, r1
	ldrh	r5, [r2, #0]
	uxth	r3, r5			@ r3 = pin mask
	ldrb	r5, [r2, #6]
	cmp	r5, #3
	bne.n	.L08002690
	movs	r4, #0			@ [6] == 3: v = 0
	b.n	.L080026c6
.L08002690:
	ldrb	r5, [r2, #6]
	cbnz	r5, .L080026ae
	ldrb	r5, [r2, #5]		@ [6] == 0: v = [5] & 0xf
	and.w	r4, r5, #0xf
	ldrb	r5, [r2, #5]
	cmp	r5, #0x18
	bne.n	.L080026a4
	str	r3, [r0, #0x10]		@ [5] == 0x18: mask to [r0 + 0x10]
	b.n	.L080026c6
.L080026a4:
	ldrb	r5, [r2, #5]
	cmp	r5, #0x28
	bne.n	.L080026c6
	str	r3, [r0, #0x14]		@ [5] == 0x28: mask to [r0 + 0x14]
	b.n	.L080026c6
.L080026ae:
	ldrb	r5, [r2, #6]		@ other [6]: v = ([6] & 8) | ([4] & 4) | ([7] & 3)
	and.w	r5, r5, #8
	ldrb	r6, [r2, #4]
	and.w	r6, r6, #4
	orrs	r5, r6
	ldrb	r6, [r2, #7]
	and.w	r6, r6, #3
	orr.w	r4, r5, r6
.L080026c6:
	uxtb	r5, r3			@ low mask byte
	cbz	r5, .L080026f4
	movs	r1, #0
	b.n	.L080026f0
.L080026ce:
	movs	r5, #1
	lsls	r5, r1
	ands	r5, r3
	cbz	r5, .L080026ee
	ldr	r5, [r0, #0]
	lsls	r7, r1, #2
	movs	r6, #0xf
	lsls	r6, r7
	bics	r5, r6
	str	r5, [r0, #0]
	ldr	r5, [r0, #0]
	lsls	r6, r1, #2
	lsl.w	r6, r4, r6
	orrs	r5, r6
	str	r5, [r0, #0]
.L080026ee:
	.inst.n 0x1c49		@ adds r1, r1, #1
.L080026f0:
	cmp	r1, #8
	bcc.n	.L080026ce
.L080026f4:
	cmp	r3, #0xff
	ble.n	.L08002724
	asrs	r3, r3, #8		@ high mask byte
	movs	r1, #0
	b.n	.L08002720
.L080026fe:
	movs	r5, #1
	lsls	r5, r1
	ands	r5, r3
	cbz	r5, .L0800271e
	ldr	r5, [r0, #4]
	lsls	r7, r1, #2
	movs	r6, #0xf
	lsls	r6, r7
	bics	r5, r6
	str	r5, [r0, #4]
	ldr	r5, [r0, #4]
	lsls	r6, r1, #2
	lsl.w	r6, r4, r6
	orrs	r5, r6
	str	r5, [r0, #4]
.L0800271e:
	.inst.n 0x1c49		@ adds r1, r1, #1
.L08002720:
	cmp	r1, #8
	bcc.n	.L080026fe
.L08002724:
	pop	{r4, r5, r6, r7, pc}

@ ----------------------------------------------------------------------------
@ reg8_all_bits_set - returns 1 when ([r0 + 8] & r1) == r1, else 0.
@ Callers: 0x0800295e (r0 = 0x40011800, r1 = 4), 0x0800297a (0x40011800, 8),
@ 0x080029c2, 0x080029d8, 0x08002a1a (0x40011000, 0x100).
@ ----------------------------------------------------------------------------
	.section .text.reg8_all_bits_set,"ax",%progbits
	.global reg8_all_bits_set
	.thumb_func
	.type reg8_all_bits_set, %function
reg8_all_bits_set:
	mov	r2, r0
	movs	r0, #0
	ldr	r3, [r2, #8]
	ands	r3, r1
	cmp	r3, r1
	beq.n	.L08002734
	b.n	.L08002736
.L08002734:
	movs	r0, #1
.L08002736:
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08002738 - sets or clears a bit field in a word of the 0x40010000 block.
@ r0 packs the offset (bits 31..24, added to 0x40010000), shift s (bits 23..16),
@ width w (bits 15..8) and value (bits 7..0); r1 = flag.
@ Computes the mask of w bits at s and clears it; when r1 != 0 ORs (value << s)
@ (value is not masked to w).
@ Caller: 0x080046e2 (inside 0x080046b0).
@ Purpose not determined from the code (which register is at 0x40010000 + offset
@ is not shown here).
@ ----------------------------------------------------------------------------
	.section .text.fn_08002738,"ax",%progbits
	.p2align 2
	.global fn_08002738
	.thumb_func
	.type fn_08002738, %function
fn_08002738:
	push	{r4, r5, r6, r7, lr}
	mov	r4, r1
	ldr	r7, .L08002780
	add.w	r2, r7, r0, lsr #24
	ubfx	r1, r0, #16, #8
	ubfx	r5, r0, #8, #8
	uxtb	r6, r0
	rsb.w	r7, r5, #0x20
	sub.w	r12, r7, r1
	mov.w	r7, #0xffffffff
	lsl.w	r3, r7, r12
	rsb.w	r7, r5, #0x20
	subs	r7, r7, r1
	lsrs	r3, r7
	lsrs	r3, r1
	lsls	r3, r1
	ldr	r7, [r2, #0]
	bics	r7, r3
	str	r7, [r2, #0]
	cbz	r4, .L0800277c
	lsl.w	r12, r6, r1
	ldr	r7, [r2, #0]
	orr.w	r7, r7, r12
	str	r7, [r2, #0]
.L0800277c:
	pop	{r4, r5, r6, r7, pc}
	.short 0x0000		@ padding
.L08002780:
	.word 0x40010000	@ base of the register block
