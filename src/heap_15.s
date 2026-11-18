@ heap_15.s - heap and fixed-block allocator routines: the 32-byte-unit allocation table (init, usage, alloc, free), the first-fit heap (init, insert, alloc, free) and free_task_memory.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ init_alloc_table - Param r0 = index; no return value.
@ Clears 0x2bc0 bytes (0x15e0 halfword entries) at the table pointer word read
@ from 0x2000107c + 4*index with zero_bytes (080082bc) and writes 1 to the byte
@ 0x20001080 + index (the flag read by 0803acbc, 0803acfc and 08039f6c).
@ The byte address 0x20001080+index and the word 0x2000107c+4*index overlap
@ only for index 1 (word 0x20001080..0x20001083, byte 0x20001081); for index 0
@ the byte is 0x20001080, beyond the word 0x2000107c..0x2000107f; for index>=2
@ the byte 0x20001080+index lies below the word 0x2000107c+4*index.
@ Code at 0x0803ab1c..0x0803ab2e. r5 = 0x20001070 (base of the allocator state).
@ ----------------------------------------------------------------------------
	.section .text.init_alloc_table,"ax",%progbits
	.global init_alloc_table
	.thumb_func
	.type init_alloc_table, %function
init_alloc_table:
	push	{r4, r5, r7, lr}
	movw	r5, #0x1070
	movt	r5, #0x2000
	mov	r4, r0
	add.w	r0, r5, r0, lsl #2
	ldr	r0, [r0, #0xc]		@ table pointer word at 0x2000107c + 4*index
	mov.w	r1, #0x2bc0
	bl	zero_bytes
	adds	r0, r5, r4
	movs	r1, #0x1
	strb	r1, [r0, #0x10]		@ flag byte 0x20001080 + index = 1
	pop	{r4, r5, r7, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ alloc_table_used_permille - Param r0 = index; returns the usage of the
@ allocation table.
@ Counts the nonzero halfword entries among the 0x15e0 entries of the table
@ whose base is the word at 0x2000107c + 4*index (loop of 0x1c entries per
@ pass, 0x15e0 down by 0x1c) and returns
@ (count*1000*0x5d9f7391 >> 32 & 0x7ffffff) >> 11, which is count*1000/0x15e0
@ (reciprocal multiply), i.e. used units per thousand.
@ ----------------------------------------------------------------------------
	.section .text.alloc_table_used_permille,"ax",%progbits
	.global alloc_table_used_permille
	.thumb_func
	.type alloc_table_used_permille, %function
alloc_table_used_permille:
	movw	r1, #0x1070
	movt	r1, #0x2000
	add.w	r0, r1, r0, lsl #2
	ldr	r0, [r0, #0xc]		@ table base
	mov.w	r2, #0x15e0		@ entries left
	sub.w	r1, r0, #0x1c
	movs	r0, #0x0		@ count of nonzero entries
.L0803ab4c:
	ldrh.w	r12, [r1, #0x38]!
	ldrh.w	r3, [r1, #-0x1c]
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x1a]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x18]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x16]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x14]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x12]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x10]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0xe]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0xc]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0xa]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x8]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x6]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x4]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh.w	r3, [r1, #-0x2]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	it	ne
	addne	r0, #0x1
	ldrh	r3, [r1, #0x2]
	cmp.w	r12, #0x0
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0x4]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0x6]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0x8]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0xa]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0xc]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0xe]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0x10]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0x12]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0x14]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0x16]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0x18]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	ldrh	r3, [r1, #0x1a]
	it	ne
	addne	r0, #0x1
	cmp	r3, #0x0
	it	ne
	addne	r0, #0x1
	subs	r2, #0x1c
	bne.w	.L0803ab4c
	mov.w	r1, #0x3e8
	muls	r0, r1, r0
	movw	r1, #0x7391
	movt	r1, #0x5d9f
	umull	r0, r1, r0, r1
	ubfx	r0, r1, #0xb, #0x10
	bx	lr
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ free_units_of_32_bytes - Param r0 = pointer to a block previously returned by
@ 0803acfc (alloc_units_of_32_bytes); no return value.
@ r0 == 0: nothing. Byte 0x20001080 == 0: calls the function pointer at
@ 0x20001070 with 0 and returns. Otherwise offset = r0 - word 0x20001078; when
@ offset>>10 < 0xaf: unit = offset>>5, count = halfword at
@ (word 0x2000107c) + unit*2; when the count is nonzero it clears count*2 bytes
@ of the table from that entry with zero_bytes (080082bc), which frees the
@ block; when the count is 0 nothing happens.
@ ----------------------------------------------------------------------------
	.section .text.free_units_of_32_bytes,"ax",%progbits
	.global free_units_of_32_bytes
	.thumb_func
	.type free_units_of_32_bytes, %function
free_units_of_32_bytes:
	push	{r7, lr}
	cbz	r0, .L0803acee
	movw	r1, #0x1070
	movt	r1, #0x2000
	ldrb	r2, [r1, #0x10]		@ flag byte 0x20001080
	cbz	r2, .L0803acf0
	ldr	r2, [r1, #0x8]		@ pool base word 0x20001078
	subs	r0, r0, r2
	lsrs	r2, r0, #0xa
	cmp	r2, #0xae
	bhi.n	.L0803acee
	ldr	r2, [r1, #0xc]		@ table base word 0x2000107c
	lsrs	r0, r0, #0x5
	ldrh.w	r1, [r2, r0, lsl #1]
	cmp	r1, #0x0
	it	eq
	popeq	{r7, pc}
	add.w	r0, r2, r0, lsl #1
	lsls	r1, r1, #0x1
	bl	zero_bytes
.L0803acee:
	pop	{r7, pc}
.L0803acf0:
	ldr	r1, [r1, #0x0]		@ function pointer at 0x20001070
	movs	r0, #0x0
	pop.w	{r7, lr}
	bx	r1
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ alloc_units_of_32_bytes - Param r0 = size in bytes; returns a pointer or 0.
@ If byte 0x20001080 is 0 it first calls the function pointer at 0x20001070
@ with 0. Size 0 returns 0. Rounds the size up to 32-byte units (0x0803ad28..
@ 0x0803ad2c). Scans the halfword table whose base is the word stored at
@ 0x2000107c (ldr ip,[r8,#12] at 0x0803ad30, r8 = 0x20001070) backwards from
@ byte offset 0x2bbe (0x0803ad34), 16 entries per pass for 350 passes (counter
@ 0x15d0 down by 16 until -16, 0x0803ad3c..0x0803ae5e), i.e. 0x15e0 entries,
@ for a run of that many zero halfwords; returns 0 if none (0x0803ae62).
@ Writes the unit count into every entry of the run and returns the word
@ stored at 0x20001078 plus index*0x20, index = lowest entry of the run
@ (0x0803aeec..0x0803aef0).
@ ----------------------------------------------------------------------------
@ This rewrite: the allocation runs with interrupts masked (PRIMASK saved and restored), so a task
@ switch cannot fall between the scan for a free run and the writing of its unit counts. V1.2.0 had
@ no lock although several tasks allocate and free (display, measurement, acquisition, keys, and the
@ USB file commands of this rewrite): two tasks could take the same run, and a later free then
@ cleared past its block (the table ends at 0x20036B7F, directly below the pixel-writer pointer
@ 0x20036B80: a null call from image_rect_callback, fault record 2026-11-18). The clears of the
@ table (every free, also the copies inlined in the callers) are masked in zero_bytes
@ (src/runtime_lib_41.s).
	.section .text.alloc_units_of_32_bytes,"ax",%progbits
	.global alloc_units_of_32_bytes
	.thumb_func
	.type alloc_units_of_32_bytes, %function
alloc_units_of_32_bytes:
	push	{r4, lr}
	mrs	r4, primask
	cpsid	i
	bl	alloc_units_body
	msr	primask, r4
	pop	{r4, pc}
	.size	alloc_units_of_32_bytes, . - alloc_units_of_32_bytes

	.thumb_func
	.type alloc_units_body, %function
alloc_units_body:
	push.w	{r4, r5, r6, r7, r8, lr}
	movw	r8, #0x1070
	movt	r8, #0x2000
	ldrb.w	r1, [r8, #0x10]		@ flag byte 0x20001080
	mov	r4, r0
	cbnz	r1, .L0803ad18
	ldr.w	r1, [r8, #0x0]		@ function pointer at 0x20001070
	movs	r0, #0x0
	blx	r1
.L0803ad18:
	cmp	r4, #0x0
	mov.w	r0, #0x0
	it	eq
	popeq.w	{r4, r5, r6, r7, r8, pc}
	lsrs	r1, r4, #0x5
	movs	r2, #0x1
	lsls	r3, r4, #0x1b
	it	ne
	addne.w	r1, r2, r4, lsr #0x5	@ r1 = units needed (size rounded up to 32 bytes)
	ldr.w	r12, [r8, #0xc]		@ table base
	movw	r2, #0x2bbe
	add.w	r4, r12, r2
	movw	r2, #0x15d0
.L0803ad40:
	ldrh	r7, [r4, #0x0]
	cmp	r7, #0x0
	mov.w	r7, #0x0
	it	eq
	addeq	r7, r0, #0x1
	cmp	r7, r1
	beq.w	.L0803ae68
	ldrh.w	r0, [r4, #-0x2]
	cmp	r0, #0x0
	mov.w	r0, #0x0
	it	eq
	addeq	r0, r7, #0x1
	cmp	r0, r1
	beq.w	.L0803ae6c
	ldrh.w	r3, [r4, #-0x4]
	movs	r7, #0x0
	cmp	r3, #0x0
	it	eq
	addeq	r7, r0, #0x1
	cmp	r7, r1
	beq.n	.L0803ae70
	ldrh.w	r0, [r4, #-0x6]
	cmp	r0, #0x0
	mov.w	r0, #0x0
	it	eq
	addeq	r0, r7, #0x1
	cmp	r0, r1
	beq.n	.L0803ae74
	ldrh.w	r3, [r4, #-0x8]
	movs	r7, #0x0
	cmp	r3, #0x0
	it	eq
	addeq	r7, r0, #0x1
	cmp	r7, r1
	beq.n	.L0803ae78
	ldrh.w	r0, [r4, #-0xa]
	cmp	r0, #0x0
	mov.w	r0, #0x0
	it	eq
	addeq	r0, r7, #0x1
	cmp	r0, r1
	beq.n	.L0803ae7c
	ldrh.w	r3, [r4, #-0xc]
	movs	r7, #0x0
	cmp	r3, #0x0
	it	eq
	addeq	r7, r0, #0x1
	cmp	r7, r1
	beq.n	.L0803ae80
	ldrh.w	r0, [r4, #-0xe]
	cmp	r0, #0x0
	mov.w	r0, #0x0
	it	eq
	addeq	r0, r7, #0x1
	cmp	r0, r1
	beq.n	.L0803ae84
	ldrh.w	r3, [r4, #-0x10]
	movs	r7, #0x0
	cmp	r3, #0x0
	it	eq
	addeq	r7, r0, #0x1
	cmp	r7, r1
	beq.n	.L0803ae88
	ldrh.w	r0, [r4, #-0x12]
	cmp	r0, #0x0
	mov.w	r0, #0x0
	it	eq
	addeq	r0, r7, #0x1
	cmp	r0, r1
	beq.n	.L0803ae8c
	ldrh.w	r3, [r4, #-0x14]
	movs	r7, #0x0
	cmp	r3, #0x0
	it	eq
	addeq	r7, r0, #0x1
	cmp	r7, r1
	beq.n	.L0803ae90
	ldrh.w	r0, [r4, #-0x16]
	cmp	r0, #0x0
	mov.w	r0, #0x0
	it	eq
	addeq	r0, r7, #0x1
	cmp	r0, r1
	beq.n	.L0803ae94
	ldrh.w	r3, [r4, #-0x18]
	movs	r7, #0x0
	cmp	r3, #0x0
	it	eq
	addeq	r7, r0, #0x1
	cmp	r7, r1
	beq.n	.L0803ae98
	ldrh.w	r0, [r4, #-0x1a]
	cmp	r0, #0x0
	mov.w	r0, #0x0
	it	eq
	addeq	r0, r7, #0x1
	cmp	r0, r1
	beq.n	.L0803ae9c
	ldrh.w	r3, [r4, #-0x1c]
	movs	r7, #0x0
	cmp	r3, #0x0
	it	eq
	addeq	r7, r0, #0x1
	cmp	r7, r1
	beq.n	.L0803aea0
	ldrh.w	r0, [r4, #-0x1e]
	cmp	r0, #0x0
	mov.w	r0, #0x0
	it	eq
	addeq	r0, r7, #0x1
	cmp	r0, r1
	beq.n	.L0803aea2
	subs	r2, #0x10
	adds.w	r3, r2, #0x10
	sub.w	r4, r4, #0x20
	bne.w	.L0803ad40
	movs	r0, #0x0		@ no run found
	pop.w	{r4, r5, r6, r7, r8, pc}
.L0803ae68:
	adds	r2, #0xf
	b.n	.L0803aea2
.L0803ae6c:
	adds	r2, #0xe
	b.n	.L0803aea2
.L0803ae70:
	adds	r2, #0xd
	b.n	.L0803aea2
.L0803ae74:
	adds	r2, #0xc
	b.n	.L0803aea2
.L0803ae78:
	adds	r2, #0xb
	b.n	.L0803aea2
.L0803ae7c:
	adds	r2, #0xa
	b.n	.L0803aea2
.L0803ae80:
	adds	r2, #0x9
	b.n	.L0803aea2
.L0803ae84:
	adds	r2, #0x8
	b.n	.L0803aea2
.L0803ae88:
	adds	r2, #0x7
	b.n	.L0803aea2
.L0803ae8c:
	adds	r2, #0x6
	b.n	.L0803aea2
.L0803ae90:
	adds	r2, #0x5
	b.n	.L0803aea2
.L0803ae94:
	adds	r2, #0x4
	b.n	.L0803aea2
.L0803ae98:
	adds	r2, #0x3
	b.n	.L0803aea2
.L0803ae9c:
	adds	r2, #0x2
	b.n	.L0803aea2
.L0803aea0:
	adds	r2, #0x1
.L0803aea2:
	cbz	r1, .L0803aeec
	subs	r0, r1, #0x1
	cmp	r0, #0x3
	and	r0, r1, #0x3
	bcs.n	.L0803aeb2
	movs	r4, #0x0
	b.n	.L0803aed4
.L0803aeb2:
	add.w	r6, r12, r2, lsl #0x1
	bic	r5, r1, #0x3
	subs	r7, r6, #0x2
	movs	r4, #0x0
	nop
.L0803aec0:
	add.w	r3, r6, r4, lsl #0x1
	adds	r4, #0x4
	strh	r1, [r7, #0x2]
	strh	r1, [r3, #0x2]
	strh	r1, [r3, #0x4]
	cmp	r5, r4
	strh.w	r1, [r7, #8]!
	bne.n	.L0803aec0
.L0803aed4:
	cbz	r0, .L0803aeec
	adds	r7, r4, r2
	cmp	r0, #0x1
	strh.w	r1, [r12, r7, lsl #1]
	beq.n	.L0803aeec
	add.w	r3, r12, r7, lsl #1
	cmp	r0, #0x2
	strh	r1, [r3, #0x2]
	it	ne
	strhne	r1, [r3, #0x4]
.L0803aeec:
	ldr.w	r0, [r8, #0x8]		@ pool base word 0x20001078
	add.w	r0, r0, r2, lsl #5
	pop.w	{r4, r5, r6, r7, r8, pc}

@ ----------------------------------------------------------------------------
@ free_task_memory - Param r0 = pointer to a task record; no return value.
@ Calls heap_free (080411e0) on the pointer stored at r0+0x30 (stack block) and
@ then on r0.
@ ----------------------------------------------------------------------------
	.section .text.free_task_memory,"ax",%progbits
	.global free_task_memory
	.thumb_func
	.type free_task_memory, %function
free_task_memory:
	push	{r7, lr}
	sub	sp, #0x8
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x30]
	bl	heap_free
	ldr	r0, [sp, #0x4]
	bl	heap_free
	add	sp, #0x8
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ heap_init_free_list - No params; no return value.
@ Initialises the free-block list of the heap used by 0803cc64
@ (heap_alloc_first_fit): 0x2000632c = 0x20006340 (list head next),
@ 0x20006330 = 0, end marker block at 0x20008330 (words 0x20008330 = 0 next and
@ 0x20008334 = 0 size), first block at 0x20006340 with next = 0x20008330 and
@ size 0x20006344 = 0x1ff0 (heap bytes 0x20006340..0x20008330),
@ 0x20006334 = 0x1ff0 (minimum free ever), 0x20006328 = 0x1ff0 (free bytes),
@ byte 0x20006324 = 1 (allocated-bit flag), 0x20006320 = 0x20008330 (end marker
@ pointer).
@ ----------------------------------------------------------------------------
	.section .text.heap_init_free_list,"ax",%progbits
	.global heap_init_free_list
	.thumb_func
	.type heap_init_free_list, %function
heap_init_free_list:
	sub	sp, #0x10
	mov.w	r0, #0x2000
	str	r0, [sp, #0x0]
	movw	r0, #0x633c
	movt	r0, #0x2000
	str	r0, [sp, #0x4]
	ldrb.w	r0, [sp, #0x4]
	lsls	r0, r0, #0x1d
	cbz	r0, .L0803be4e
	b.n	.L0803be2c
.L0803be2c:
	ldr	r0, [sp, #0x4]
	adds	r0, #0x7
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	bic	r0, r0, #0x7
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	movw	r1, #0x633c
	movt	r1, #0x2000
	ldr	r2, [sp, #0x0]
	subs	r0, r1, r0
	add	r0, r2
	str	r0, [sp, #0x0]
	b.n	.L0803be4e
.L0803be4e:
	ldr	r0, [sp, #0x4]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	movw	r1, #0x632c
	movt	r1, #0x2000
	str	r0, [r1, #0x0]		@ list head next = first block
	movs	r0, #0x0
	str	r0, [r1, #0x4]		@ list head size = 0
	ldr	r1, [sp, #0x8]
	ldr	r2, [sp, #0x0]
	add	r1, r2
	str	r1, [sp, #0x4]
	ldr	r1, [sp, #0x4]
	subs	r1, #0x8
	str	r1, [sp, #0x4]
	ldr	r1, [sp, #0x4]
	bic	r1, r1, #0x7
	str	r1, [sp, #0x4]
	ldr	r1, [sp, #0x4]
	movw	r2, #0x6320
	movt	r2, #0x2000
	str	r1, [r2, #0x0]		@ end marker pointer
	ldr	r1, [r2, #0x0]
	str	r0, [r1, #0x4]		@ end marker size = 0
	ldr	r1, [r2, #0x0]
	str	r0, [r1, #0x0]		@ end marker next = 0
	ldr	r0, [sp, #0x8]
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp, #0xc]
	subs	r0, r0, r1
	str	r0, [r1, #0x4]		@ first block size
	ldr	r0, [r2, #0x0]
	ldr	r1, [sp, #0xc]
	str	r0, [r1, #0x0]		@ first block next = end marker
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x4]
	movw	r1, #0x6334
	movt	r1, #0x2000
	str	r0, [r1, #0x0]		@ minimum free ever
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x4]
	movw	r1, #0x6328
	movt	r1, #0x2000
	str	r0, [r1, #0x0]		@ free bytes
	movw	r0, #0x6324
	movt	r0, #0x2000
	movs	r1, #0x1
	strb	r1, [r0, #0x0]		@ allocated-bit flag
	add	sp, #0x10
	bx	lr
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ heap_insert_free_block - Param r0 = block pointer; no return value.
@ Address-ordered free-list insert with coalescing: starts at the head
@ 0x2000632c, follows the next pointers (word 0) while next < r0; merges r0 into
@ the previous block when previous + size (word 1) == r0; when the (merged)
@ block end equals the next block it merges with it (size added, next taken)
@ unless the next block is the end marker held at 0x20006320, in which case it
@ links to the marker; otherwise links to the next block; then relinks the
@ previous block to the result when the two differ.
@ ----------------------------------------------------------------------------
	.section .text.heap_insert_free_block,"ax",%progbits
	.global heap_insert_free_block
	.thumb_func
	.type heap_insert_free_block, %function
heap_insert_free_block:
	sub	sp, #0xc
	str	r0, [sp, #0x8]
	movw	r0, #0x632c
	movt	r0, #0x2000
	str	r0, [sp, #0x4]
	b.n	.L0803c16c
.L0803c16c:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x0]
	ldr	r1, [sp, #0x8]
	cmp	r0, r1
	bcs.n	.L0803c182
	b.n	.L0803c178
.L0803c178:
	b.n	.L0803c17a
.L0803c17a:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x0]
	str	r0, [sp, #0x4]
	b.n	.L0803c16c
.L0803c182:
	ldr	r0, [sp, #0x4]
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0x0]
	ldr	r1, [sp, #0x4]
	ldr	r1, [r1, #0x4]
	add	r0, r1
	ldr	r1, [sp, #0x8]
	cmp	r0, r1
	bne.n	.L0803c1a8
	b.n	.L0803c196
.L0803c196:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x4]
	ldr	r1, [sp, #0x4]
	ldr	r2, [r1, #0x4]
	add	r0, r2
	str	r0, [r1, #0x4]
	ldr	r0, [sp, #0x4]
	str	r0, [sp, #0x8]
	b.n	.L0803c1aa
.L0803c1a8:
	b.n	.L0803c1aa
.L0803c1aa:
	ldr	r0, [sp, #0x8]
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0x0]
	ldr	r1, [sp, #0x8]
	ldr	r1, [r1, #0x4]
	add	r0, r1
	ldr	r1, [sp, #0x4]
	ldr	r1, [r1, #0x0]
	cmp	r0, r1
	bne.n	.L0803c200
	b.n	.L0803c1c0
.L0803c1c0:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x0]
	movw	r1, #0x6320
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	cmp	r0, r1
	beq.n	.L0803c1ee
	b.n	.L0803c1d4
.L0803c1d4:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x0]
	ldr	r0, [r0, #0x4]
	ldr	r1, [sp, #0x8]
	ldr	r2, [r1, #0x4]
	add	r0, r2
	str	r0, [r1, #0x4]
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x0]
	ldr	r0, [r0, #0x0]
	ldr	r1, [sp, #0x8]
	str	r0, [r1, #0x0]
	b.n	.L0803c1fe
.L0803c1ee:
	movw	r0, #0x6320
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r1, [sp, #0x8]
	str	r0, [r1, #0x0]
	b.n	.L0803c1fe
.L0803c1fe:
	b.n	.L0803c20a
.L0803c200:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x0]
	ldr	r1, [sp, #0x8]
	str	r0, [r1, #0x0]
	b.n	.L0803c20a
.L0803c20a:
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp, #0x8]
	cmp	r0, r1
	beq.n	.L0803c21c
	b.n	.L0803c214
.L0803c214:
	ldr	r0, [sp, #0x8]
	ldr	r1, [sp, #0x4]
	str	r0, [r1, #0x0]
	b.n	.L0803c21e
.L0803c21c:
	b.n	.L0803c21e
.L0803c21e:
	add	sp, #0xc
	bx	lr
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ heap_alloc_first_fit - Param r0 = size; returns the block pointer + 8 or 0.
@ Calls increment_word_200061e4 (08041904); if 0x20006320 == 0 calls
@ heap_init_free_list (0803be10). Rounds size+8 up to a multiple of 8, rejects
@ size 0, overflow, a size with the top bit set when byte 0x20006324 is set, and
@ sizes larger than 0x20006328 (free bytes). First-fit walk of the list from
@ 0x2000632c (next in word 0, size in word 1) until a block with size >= need
@ is found or the end marker 0x20006320 is reached; unlinks it, splits it with
@ heap_insert_free_block (0803c15c) when the remainder exceeds 0x10, subtracts
@ the size from 0x20006328, tracks the minimum in 0x20006334, marks the size
@ word with bit 31 (if byte 0x20006324), clears word 0, increments 0x20006338,
@ calls fn_08042c10 (08042c10) and returns block+8 (or 0). If the result is not
@ 8-aligned (or the split address is not 8-aligned) it raises BASEPRI to 0x10
@ and loops forever. Three decompiler-unreachable blocks (0x0803cce6, 0x0803cce8,
@ 0x0803ccfc: the msr basepri sequence at 0x0803cce8 guarded by cbz at
@ 0x0803cce4) are kept in place; the msr sequences at 0x0803cdae and 0x0803ce64
@ are not unreachable.
@ ----------------------------------------------------------------------------
	.section .text.heap_alloc_first_fit,"ax",%progbits
	.global heap_alloc_first_fit
	.thumb_func
	.type heap_alloc_first_fit, %function
heap_alloc_first_fit:
	push	{r7, lr}
	sub	sp, #0x20
	str	r0, [sp, #0x10]
	movs	r0, #0x0
	str	r0, [sp, #0x0]
	bl	increment_word_200061e4
	movw	r0, #0x6320
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbnz	r0, .L0803cc86
	b.n	.L0803cc80
.L0803cc80:
	bl	heap_init_free_list
	b.n	.L0803cc88
.L0803cc86:
	b.n	.L0803cc88
.L0803cc88:
	ldr	r0, [sp, #0x10]
	movw	r1, #0x6324
	movt	r1, #0x2000
	ldrb	r1, [r1, #0x0]
	cmp	r1, #0x0
	it	ne
	movne.w	r1, #0x80000000
	tst	r0, r1
	bne.w	.L0803ce54
	b.n	.L0803cca4
.L0803cca4:
	ldr	r0, [sp, #0x10]
	cbz	r0, .L0803cd0c
	b.n	.L0803ccaa
.L0803ccaa:
	ldr	r0, [sp, #0x10]
	add.w	r1, r0, #0x8
	cmp	r1, r0
	bls.n	.L0803cd0c
	b.n	.L0803ccb6
.L0803ccb6:
	ldr	r0, [sp, #0x10]
	adds	r0, #0x8
	str	r0, [sp, #0x10]
	ldrb.w	r0, [sp, #0x10]
	lsls	r0, r0, #0x1d
	cbz	r0, .L0803cd08
	b.n	.L0803ccc6
.L0803ccc6:
	ldr	r0, [sp, #0x10]
	bic	r1, r0, #0x7
	adds	r1, #0x8
	cmp	r1, r0
	bls.n	.L0803cd00
	b.n	.L0803ccd4
.L0803ccd4:
	ldr	r0, [sp, #0x10]
	bic	r0, r0, #0x7
	adds	r0, #0x8
	str	r0, [sp, #0x10]
	ldrb.w	r0, [sp, #0x10]
	lsls	r0, r0, #0x1d
	cbz	r0, .L0803ccfe
	b.n	.L0803cce8
.L0803cce8:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x14]
	b.n	.L0803ccfc
.L0803ccfc:
	b.n	.L0803ccfc
.L0803ccfe:
	b.n	.L0803cd06
.L0803cd00:
	movs	r0, #0x0
	str	r0, [sp, #0x10]
	b.n	.L0803cd06
.L0803cd06:
	b.n	.L0803cd0a
.L0803cd08:
	b.n	.L0803cd0a
.L0803cd0a:
	b.n	.L0803cd12
.L0803cd0c:
	movs	r0, #0x0
	str	r0, [sp, #0x10]
	b.n	.L0803cd12
.L0803cd12:
	ldr	r0, [sp, #0x10]
	cmp	r0, #0x0
	beq.w	.L0803ce50
	b.n	.L0803cd1c
.L0803cd1c:
	ldr	r0, [sp, #0x10]
	movw	r1, #0x6328
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	cmp	r0, r1
	bhi.w	.L0803ce50
	b.n	.L0803cd30
.L0803cd30:
	movw	r0, #0x632c
	movt	r0, #0x2000
	str	r0, [sp, #0x8]
	ldr	r0, [r0, #0x0]
	str	r0, [sp, #0xc]
	b.n	.L0803cd40
.L0803cd40:
	ldr	r0, [sp, #0xc]
	ldr	r1, [r0, #0x4]
	ldr	r2, [sp, #0x10]
	movs	r0, #0x0
	cmp	r1, r2
	bcs.n	.L0803cd5a
	b.n	.L0803cd4e
.L0803cd4e:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x0]
	cmp	r0, #0x0
	it	ne
	movne	r0, #0x1
	b.n	.L0803cd5a
.L0803cd5a:
	lsls	r0, r0, #0x1f
	cbz	r0, .L0803cd6c
	b.n	.L0803cd60
.L0803cd60:
	ldr	r0, [sp, #0xc]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x0]
	str	r0, [sp, #0xc]
	b.n	.L0803cd40
.L0803cd6c:
	ldr	r0, [sp, #0xc]
	movw	r1, #0x6320
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	cmp	r0, r1
	beq.n	.L0803ce4c
	b.n	.L0803cd7e
.L0803cd7e:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x0]
	adds	r0, #0x8
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x0]
	ldr	r1, [sp, #0x8]
	str	r0, [r1, #0x0]
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x4]
	ldr	r1, [sp, #0x10]
	subs	r0, r0, r1
	cmp	r0, #0x11
	bcc.n	.L0803cdde
	b.n	.L0803cd9c
.L0803cd9c:
	ldr	r0, [sp, #0xc]
	ldr	r1, [sp, #0x10]
	add	r0, r1
	str	r0, [sp, #0x4]
	ldrb.w	r0, [sp, #0x4]
	lsls	r0, r0, #0x1d
	cbz	r0, .L0803cdc4
	b.n	.L0803cdae
.L0803cdae:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x18]
	b.n	.L0803cdc2
.L0803cdc2:
	b.n	.L0803cdc2
.L0803cdc4:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x4]
	ldr	r1, [sp, #0x10]
	subs	r0, r0, r1
	ldr	r1, [sp, #0x4]
	str	r0, [r1, #0x4]
	ldr	r0, [sp, #0x10]
	ldr	r1, [sp, #0xc]
	str	r0, [r1, #0x4]
	ldr	r0, [sp, #0x4]
	bl	heap_insert_free_block
	b.n	.L0803cde0
.L0803cdde:
	b.n	.L0803cde0
.L0803cde0:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x4]
	movw	r1, #0x6328
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	subs	r0, r2, r0
	str	r0, [r1, #0x0]
	ldr	r0, [r1, #0x0]
	movw	r1, #0x6334
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	cmp	r0, r1
	bcs.n	.L0803ce1a
	b.n	.L0803ce04
.L0803ce04:
	movw	r0, #0x6328
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	movw	r1, #0x6334
	movt	r1, #0x2000
	str	r0, [r1, #0x0]
	b.n	.L0803ce1c
.L0803ce1a:
	b.n	.L0803ce1c
.L0803ce1c:
	movw	r0, #0x6324
	movt	r0, #0x2000
	ldrb	r0, [r0, #0x0]
	ldr	r1, [sp, #0xc]
	ldr	r2, [r1, #0x4]
	orr	r3, r2, #0x80000000
	cmp	r0, #0x0
	it	ne
	movne	r2, r3
	str	r2, [r1, #0x4]
	ldr	r0, [sp, #0xc]
	movs	r1, #0x0
	str	r1, [r0, #0x0]
	movw	r0, #0x6338
	movt	r0, #0x2000
	ldr	r1, [r0, #0x0]
	adds	r1, #0x1
	str	r1, [r0, #0x0]
	b.n	.L0803ce4e
.L0803ce4c:
	b.n	.L0803ce4e
.L0803ce4e:
	b.n	.L0803ce52
.L0803ce50:
	b.n	.L0803ce52
.L0803ce52:
	b.n	.L0803ce56
.L0803ce54:
	b.n	.L0803ce56
.L0803ce56:
	bl	fn_08042c10
	ldrb.w	r0, [sp, #0x0]
	lsls	r0, r0, #0x1d
	cbz	r0, .L0803ce7a
	b.n	.L0803ce64
.L0803ce64:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x1c]
	b.n	.L0803ce78
.L0803ce78:
	b.n	.L0803ce78
.L0803ce7a:
	ldr	r0, [sp, #0x0]
	add	sp, #0x20
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ heap_free - Param r0 = pointer returned by the allocator 0803cc64
@ (heap_alloc_first_fit); r0 == 0 does nothing. Block header = r0-8 (word
@ r0[-2]), size word = r0[-1]. Mask m = 0x80000000 when byte 0x20006324 != 0
@ else 0 (movne at 0x0804120e). If (size word & m) == 0 (this includes byte
@ 0x20006324 == 0) it raises BASEPRI to 0x10 and loops forever; it also loops
@ forever when word r0[-2] != 0. Otherwise: clears bit 31 of the size word (only
@ when byte 0x20006324 != 0), calls increment_word_200061e4 (08041904), adds the
@ size word to 0x20006328, calls heap_insert_free_block (0803c15c) with the
@ header (list insert and merge), increments 0x2000833c and calls fn_08042c10
@ (08042c10).
@ ----------------------------------------------------------------------------
	.section .text.heap_free,"ax",%progbits
	.global heap_free
	.thumb_func
	.type heap_free, %function
heap_free:
	push	{r7, lr}
	sub	sp, #0x18
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0xc]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0xc]
	cmp	r0, #0x0
	beq.n	.L080412c2
	b.n	.L080411f2
.L080411f2:
	ldr	r0, [sp, #0x8]
	subs	r0, #0x8
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x4]
	movw	r1, #0x6324
	movt	r1, #0x2000
	ldrb	r1, [r1, #0x0]
	cmp	r1, #0x0
	it	ne
	movne.w	r1, #0x80000000
	tst	r0, r1
	bne.n	.L0804122e
	b.n	.L08041218
.L08041218:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x10]
	b.n	.L0804122c
.L0804122c:
	b.n	.L0804122c
.L0804122e:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x0]
	cbz	r0, .L0804124c
	b.n	.L08041236
.L08041236:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x14]
	b.n	.L0804124a
.L0804124a:
	b.n	.L0804124a
.L0804124c:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x4]
	movw	r1, #0x6324
	movt	r1, #0x2000
	ldrb	r1, [r1, #0x0]
	cmp	r1, #0x0
	it	ne
	movne.w	r1, #0x80000000
	tst	r0, r1
	beq.n	.L080412be
	b.n	.L08041268
.L08041268:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x0]
	cbnz	r0, .L080412ba
	b.n	.L08041270
.L08041270:
	movw	r0, #0x6324
	movt	r0, #0x2000
	ldrb	r0, [r0, #0x0]
	ldr	r1, [sp, #0x4]
	ldr	r2, [r1, #0x4]
	bic	r3, r2, #0x80000000
	cmp	r0, #0x0
	it	ne
	movne	r2, r3
	str	r2, [r1, #0x4]
	bl	increment_word_200061e4
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x4]
	movw	r1, #0x6328
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	add	r0, r2
	str	r0, [r1, #0x0]
	ldr	r0, [sp, #0x4]
	bl	heap_insert_free_block
	movw	r0, #0x833c
	movt	r0, #0x2000
	ldr	r1, [r0, #0x0]
	adds	r1, #0x1
	str	r1, [r0, #0x0]
	bl	fn_08042c10
	b.n	.L080412bc
.L080412ba:
	b.n	.L080412bc
.L080412bc:
	b.n	.L080412c0
.L080412be:
	b.n	.L080412c0
.L080412c0:
	b.n	.L080412c2
.L080412c2:
	add	sp, #0x18
	pop	{r7, pc}
	.short	0x0000			@ padding
