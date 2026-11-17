@ filesystem_02.s - eight sorted-table pointer lookups, eight sorted-table record lookups, boot sector validation, cluster chain follow/allocate
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_ptr_0802f340 - table lookup by key, returns pointer or 0.
@ r0 = object; ctx = word at r0+0x10; ctx[0] = base address, ctx[1] = pointer to
@ 8-byte entries, ctx[2] = descriptor d, ctx[5] = cached key, ctx[6] = cached index.
@ d: word at d+0 = low bound, halfword at d+4 = high bound, word at d+8 = pointer
@ to sorted ushort key array, halfword at d+0x10 = count.  r1 = key.
@ Returns 0 unless d[0] <= key <= (ushort)d[4 bytes].  If ctx[5] == key the index
@ ctx[6] is reused (index -1 gives 0), else binary search of key & 0xffff over the
@ ushort array (lo = 0, hi = count-1, probe at byte offset (lo+hi) & ~1; count 0
@ gives 0).  On a hit stores ctx[5] = key, ctx[6] = index i and returns
@ (word at ctx[1]+i*8 & 0xfffff) + ctx[0]; not found returns 0.  No memory outside
@ the context is written.  The 8 functions at 0802f340, 0802f3b4, 0802f428,
@ 0802f49c, 0802f510, 0802f584, 0802f5f8, 0802f66c have identical bodies.
@ What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_ptr_0802f340,"ax",%progbits
	.global lookup_sorted_table_ptr_0802f340
	.thumb_func
	.type lookup_sorted_table_ptr_0802f340, %function
lookup_sorted_table_ptr_0802f340:
	push	{r4, r5, r7, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r2, [r0, #0x0]	@ low bound
	cmp	r2, r1
	bhi.n	.L0802f356
	ldrh	r2, [r0, #0x4]	@ high bound
	cmp	r2, r1
	bcs.n	.L0802f35a
.L0802f356:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r7, pc}
.L0802f35a:
	ldr.w	r2, [r12, #0x14]	@ cached key
	cmp	r2, r1
	bne.n	.L0802f382
	ldr.w	r4, [r12, #0x18]	@ cached index
.L0802f366:
	adds	r0, r4, #0x1
	beq.n	.L0802f356	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r1, r4, [r12, #0x14]	@ cache key and index
	ldr.w	r0, [r0, r4, lsl #0x3]
	ldr.w	r1, [r12, #0x0]	@ base address
	bfc	r0, #0x14, #0xc	@ keep low 20 bits
	add	r0, r1
	pop	{r4, r5, r7, pc}
.L0802f382:
	ldrh	r2, [r0, #0x10]	@ count
	cmp	r2, #0x0
	beq.n	.L0802f356
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r3, r1
	subs	r0, r2, #0x1	@ hi = count - 1
	movs	r2, #0x0	@ lo = 0
	b.n	.L0802f39a
.L0802f394:
	subs	r0, r4, #0x1	@ hi = mid - 1
	cmp	r2, r0
	bgt.n	.L0802f356
.L0802f39a:
	adds	r4, r2, r0
	bic	r5, r4, #0x1
	ldrh.w	r5, [lr, r5]
	asrs	r4, r4, #0x1	@ mid
	cmp	r5, r3
	bhi.n	.L0802f394
	bcs.n	.L0802f366
	adds	r2, r4, #0x1	@ lo = mid + 1
	cmp	r2, r0
	ble.n	.L0802f39a
	b.n	.L0802f356

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_ptr_0802f3b4 - table lookup by key, returns pointer or 0.
@ r0 = object; ctx = word at r0+0x10; ctx[0] = base address, ctx[1] = pointer to
@ 8-byte entries, ctx[2] = descriptor d, ctx[5] = cached key, ctx[6] = cached index.
@ d: word at d+0 = low bound, halfword at d+4 = high bound, word at d+8 = pointer
@ to sorted ushort key array, halfword at d+0x10 = count.  r1 = key.
@ Returns 0 unless d[0] <= key <= (ushort)d[4 bytes].  If ctx[5] == key the index
@ ctx[6] is reused (index -1 gives 0), else binary search of key & 0xffff over the
@ ushort array (lo = 0, hi = count-1, probe at byte offset (lo+hi) & ~1; count 0
@ gives 0).  On a hit stores ctx[5] = key, ctx[6] = index i and returns
@ (word at ctx[1]+i*8 & 0xfffff) + ctx[0]; not found returns 0.  No memory outside
@ the context is written.  Body identical to the other 7 functions of this group.
@ What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_ptr_0802f3b4,"ax",%progbits
	.global lookup_sorted_table_ptr_0802f3b4
	.thumb_func
	.type lookup_sorted_table_ptr_0802f3b4, %function
lookup_sorted_table_ptr_0802f3b4:
	push	{r4, r5, r7, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r2, [r0, #0x0]	@ low bound
	cmp	r2, r1
	bhi.n	.L0802f3ca
	ldrh	r2, [r0, #0x4]	@ high bound
	cmp	r2, r1
	bcs.n	.L0802f3ce
.L0802f3ca:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r7, pc}
.L0802f3ce:
	ldr.w	r2, [r12, #0x14]	@ cached key
	cmp	r2, r1
	bne.n	.L0802f3f6
	ldr.w	r4, [r12, #0x18]	@ cached index
.L0802f3da:
	adds	r0, r4, #0x1
	beq.n	.L0802f3ca	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r1, r4, [r12, #0x14]	@ cache key and index
	ldr.w	r0, [r0, r4, lsl #0x3]
	ldr.w	r1, [r12, #0x0]	@ base address
	bfc	r0, #0x14, #0xc	@ keep low 20 bits
	add	r0, r1
	pop	{r4, r5, r7, pc}
.L0802f3f6:
	ldrh	r2, [r0, #0x10]	@ count
	cmp	r2, #0x0
	beq.n	.L0802f3ca
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r3, r1
	subs	r0, r2, #0x1	@ hi = count - 1
	movs	r2, #0x0	@ lo = 0
	b.n	.L0802f40e
.L0802f408:
	subs	r0, r4, #0x1	@ hi = mid - 1
	cmp	r2, r0
	bgt.n	.L0802f3ca
.L0802f40e:
	adds	r4, r2, r0
	bic	r5, r4, #0x1
	ldrh.w	r5, [lr, r5]
	asrs	r4, r4, #0x1	@ mid
	cmp	r5, r3
	bhi.n	.L0802f408
	bcs.n	.L0802f3da
	adds	r2, r4, #0x1	@ lo = mid + 1
	cmp	r2, r0
	ble.n	.L0802f40e
	b.n	.L0802f3ca

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_ptr_0802f428 - table lookup by key, returns pointer or 0.
@ r0 = object; ctx = word at r0+0x10; ctx[0] = base address, ctx[1] = pointer to
@ 8-byte entries, ctx[2] = descriptor d, ctx[5] = cached key, ctx[6] = cached index.
@ d: word at d+0 = low bound, halfword at d+4 = high bound, word at d+8 = pointer
@ to sorted ushort key array, halfword at d+0x10 = count.  r1 = key.
@ Returns 0 unless d[0] <= key <= (ushort)d[4 bytes].  If ctx[5] == key the index
@ ctx[6] is reused (index -1 gives 0), else binary search of key & 0xffff over the
@ ushort array (lo = 0, hi = count-1, probe at byte offset (lo+hi) & ~1; count 0
@ gives 0).  On a hit stores ctx[5] = key, ctx[6] = index i and returns
@ (word at ctx[1]+i*8 & 0xfffff) + ctx[0]; not found returns 0.  No memory outside
@ the context is written.  Body identical to the other 7 functions of this group.
@ What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_ptr_0802f428,"ax",%progbits
	.global lookup_sorted_table_ptr_0802f428
	.thumb_func
	.type lookup_sorted_table_ptr_0802f428, %function
lookup_sorted_table_ptr_0802f428:
	push	{r4, r5, r7, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r2, [r0, #0x0]	@ low bound
	cmp	r2, r1
	bhi.n	.L0802f43e
	ldrh	r2, [r0, #0x4]	@ high bound
	cmp	r2, r1
	bcs.n	.L0802f442
.L0802f43e:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r7, pc}
.L0802f442:
	ldr.w	r2, [r12, #0x14]	@ cached key
	cmp	r2, r1
	bne.n	.L0802f46a
	ldr.w	r4, [r12, #0x18]	@ cached index
.L0802f44e:
	adds	r0, r4, #0x1
	beq.n	.L0802f43e	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r1, r4, [r12, #0x14]	@ cache key and index
	ldr.w	r0, [r0, r4, lsl #0x3]
	ldr.w	r1, [r12, #0x0]	@ base address
	bfc	r0, #0x14, #0xc	@ keep low 20 bits
	add	r0, r1
	pop	{r4, r5, r7, pc}
.L0802f46a:
	ldrh	r2, [r0, #0x10]	@ count
	cmp	r2, #0x0
	beq.n	.L0802f43e
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r3, r1
	subs	r0, r2, #0x1	@ hi = count - 1
	movs	r2, #0x0	@ lo = 0
	b.n	.L0802f482
.L0802f47c:
	subs	r0, r4, #0x1	@ hi = mid - 1
	cmp	r2, r0
	bgt.n	.L0802f43e
.L0802f482:
	adds	r4, r2, r0
	bic	r5, r4, #0x1
	ldrh.w	r5, [lr, r5]
	asrs	r4, r4, #0x1	@ mid
	cmp	r5, r3
	bhi.n	.L0802f47c
	bcs.n	.L0802f44e
	adds	r2, r4, #0x1	@ lo = mid + 1
	cmp	r2, r0
	ble.n	.L0802f482
	b.n	.L0802f43e

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_ptr_0802f49c - table lookup by key, returns pointer or 0.
@ r0 = object; ctx = word at r0+0x10; ctx[0] = base address, ctx[1] = pointer to
@ 8-byte entries, ctx[2] = descriptor d, ctx[5] = cached key, ctx[6] = cached index.
@ d: word at d+0 = low bound, halfword at d+4 = high bound, word at d+8 = pointer
@ to sorted ushort key array, halfword at d+0x10 = count.  r1 = key.
@ Returns 0 unless d[0] <= key <= (ushort)d[4 bytes].  If ctx[5] == key the index
@ ctx[6] is reused (index -1 gives 0), else binary search of key & 0xffff over the
@ ushort array (lo = 0, hi = count-1, probe at byte offset (lo+hi) & ~1; count 0
@ gives 0).  On a hit stores ctx[5] = key, ctx[6] = index i and returns
@ (word at ctx[1]+i*8 & 0xfffff) + ctx[0]; not found returns 0.  No memory outside
@ the context is written.  Body identical to the other 7 functions of this group.
@ What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_ptr_0802f49c,"ax",%progbits
	.global lookup_sorted_table_ptr_0802f49c
	.thumb_func
	.type lookup_sorted_table_ptr_0802f49c, %function
lookup_sorted_table_ptr_0802f49c:
	push	{r4, r5, r7, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r2, [r0, #0x0]	@ low bound
	cmp	r2, r1
	bhi.n	.L0802f4b2
	ldrh	r2, [r0, #0x4]	@ high bound
	cmp	r2, r1
	bcs.n	.L0802f4b6
.L0802f4b2:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r7, pc}
.L0802f4b6:
	ldr.w	r2, [r12, #0x14]	@ cached key
	cmp	r2, r1
	bne.n	.L0802f4de
	ldr.w	r4, [r12, #0x18]	@ cached index
.L0802f4c2:
	adds	r0, r4, #0x1
	beq.n	.L0802f4b2	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r1, r4, [r12, #0x14]	@ cache key and index
	ldr.w	r0, [r0, r4, lsl #0x3]
	ldr.w	r1, [r12, #0x0]	@ base address
	bfc	r0, #0x14, #0xc	@ keep low 20 bits
	add	r0, r1
	pop	{r4, r5, r7, pc}
.L0802f4de:
	ldrh	r2, [r0, #0x10]	@ count
	cmp	r2, #0x0
	beq.n	.L0802f4b2
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r3, r1
	subs	r0, r2, #0x1	@ hi = count - 1
	movs	r2, #0x0	@ lo = 0
	b.n	.L0802f4f6
.L0802f4f0:
	subs	r0, r4, #0x1	@ hi = mid - 1
	cmp	r2, r0
	bgt.n	.L0802f4b2
.L0802f4f6:
	adds	r4, r2, r0
	bic	r5, r4, #0x1
	ldrh.w	r5, [lr, r5]
	asrs	r4, r4, #0x1	@ mid
	cmp	r5, r3
	bhi.n	.L0802f4f0
	bcs.n	.L0802f4c2
	adds	r2, r4, #0x1	@ lo = mid + 1
	cmp	r2, r0
	ble.n	.L0802f4f6
	b.n	.L0802f4b2

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_ptr_0802f510 - table lookup by key, returns pointer or 0.
@ r0 = object; ctx = word at r0+0x10; ctx[0] = base address, ctx[1] = pointer to
@ 8-byte entries, ctx[2] = descriptor d, ctx[5] = cached key, ctx[6] = cached index.
@ d: word at d+0 = low bound, halfword at d+4 = high bound, word at d+8 = pointer
@ to sorted ushort key array, halfword at d+0x10 = count.  r1 = key.
@ Returns 0 unless d[0] <= key <= (ushort)d[4 bytes].  If ctx[5] == key the index
@ ctx[6] is reused (index -1 gives 0), else binary search of key & 0xffff over the
@ ushort array (lo = 0, hi = count-1, probe at byte offset (lo+hi) & ~1; count 0
@ gives 0).  On a hit stores ctx[5] = key, ctx[6] = index i and returns
@ (word at ctx[1]+i*8 & 0xfffff) + ctx[0]; not found returns 0.  No memory outside
@ the context is written.  Body identical to the other 7 functions of this group.
@ What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_ptr_0802f510,"ax",%progbits
	.global lookup_sorted_table_ptr_0802f510
	.thumb_func
	.type lookup_sorted_table_ptr_0802f510, %function
lookup_sorted_table_ptr_0802f510:
	push	{r4, r5, r7, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r2, [r0, #0x0]	@ low bound
	cmp	r2, r1
	bhi.n	.L0802f526
	ldrh	r2, [r0, #0x4]	@ high bound
	cmp	r2, r1
	bcs.n	.L0802f52a
.L0802f526:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r7, pc}
.L0802f52a:
	ldr.w	r2, [r12, #0x14]	@ cached key
	cmp	r2, r1
	bne.n	.L0802f552
	ldr.w	r4, [r12, #0x18]	@ cached index
.L0802f536:
	adds	r0, r4, #0x1
	beq.n	.L0802f526	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r1, r4, [r12, #0x14]	@ cache key and index
	ldr.w	r0, [r0, r4, lsl #0x3]
	ldr.w	r1, [r12, #0x0]	@ base address
	bfc	r0, #0x14, #0xc	@ keep low 20 bits
	add	r0, r1
	pop	{r4, r5, r7, pc}
.L0802f552:
	ldrh	r2, [r0, #0x10]	@ count
	cmp	r2, #0x0
	beq.n	.L0802f526
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r3, r1
	subs	r0, r2, #0x1	@ hi = count - 1
	movs	r2, #0x0	@ lo = 0
	b.n	.L0802f56a
.L0802f564:
	subs	r0, r4, #0x1	@ hi = mid - 1
	cmp	r2, r0
	bgt.n	.L0802f526
.L0802f56a:
	adds	r4, r2, r0
	bic	r5, r4, #0x1
	ldrh.w	r5, [lr, r5]
	asrs	r4, r4, #0x1	@ mid
	cmp	r5, r3
	bhi.n	.L0802f564
	bcs.n	.L0802f536
	adds	r2, r4, #0x1	@ lo = mid + 1
	cmp	r2, r0
	ble.n	.L0802f56a
	b.n	.L0802f526

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_ptr_0802f584 - table lookup by key, returns pointer or 0.
@ r0 = object; ctx = word at r0+0x10; ctx[0] = base address, ctx[1] = pointer to
@ 8-byte entries, ctx[2] = descriptor d, ctx[5] = cached key, ctx[6] = cached index.
@ d: word at d+0 = low bound, halfword at d+4 = high bound, word at d+8 = pointer
@ to sorted ushort key array, halfword at d+0x10 = count.  r1 = key.
@ Returns 0 unless d[0] <= key <= (ushort)d[4 bytes].  If ctx[5] == key the index
@ ctx[6] is reused (index -1 gives 0), else binary search of key & 0xffff over the
@ ushort array (lo = 0, hi = count-1, probe at byte offset (lo+hi) & ~1; count 0
@ gives 0).  On a hit stores ctx[5] = key, ctx[6] = index i and returns
@ (word at ctx[1]+i*8 & 0xfffff) + ctx[0]; not found returns 0.  No memory outside
@ the context is written.  Body identical to the other 7 functions of this group.
@ What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_ptr_0802f584,"ax",%progbits
	.global lookup_sorted_table_ptr_0802f584
	.thumb_func
	.type lookup_sorted_table_ptr_0802f584, %function
lookup_sorted_table_ptr_0802f584:
	push	{r4, r5, r7, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r2, [r0, #0x0]	@ low bound
	cmp	r2, r1
	bhi.n	.L0802f59a
	ldrh	r2, [r0, #0x4]	@ high bound
	cmp	r2, r1
	bcs.n	.L0802f59e
.L0802f59a:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r7, pc}
.L0802f59e:
	ldr.w	r2, [r12, #0x14]	@ cached key
	cmp	r2, r1
	bne.n	.L0802f5c6
	ldr.w	r4, [r12, #0x18]	@ cached index
.L0802f5aa:
	adds	r0, r4, #0x1
	beq.n	.L0802f59a	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r1, r4, [r12, #0x14]	@ cache key and index
	ldr.w	r0, [r0, r4, lsl #0x3]
	ldr.w	r1, [r12, #0x0]	@ base address
	bfc	r0, #0x14, #0xc	@ keep low 20 bits
	add	r0, r1
	pop	{r4, r5, r7, pc}
.L0802f5c6:
	ldrh	r2, [r0, #0x10]	@ count
	cmp	r2, #0x0
	beq.n	.L0802f59a
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r3, r1
	subs	r0, r2, #0x1	@ hi = count - 1
	movs	r2, #0x0	@ lo = 0
	b.n	.L0802f5de
.L0802f5d8:
	subs	r0, r4, #0x1	@ hi = mid - 1
	cmp	r2, r0
	bgt.n	.L0802f59a
.L0802f5de:
	adds	r4, r2, r0
	bic	r5, r4, #0x1
	ldrh.w	r5, [lr, r5]
	asrs	r4, r4, #0x1	@ mid
	cmp	r5, r3
	bhi.n	.L0802f5d8
	bcs.n	.L0802f5aa
	adds	r2, r4, #0x1	@ lo = mid + 1
	cmp	r2, r0
	ble.n	.L0802f5de
	b.n	.L0802f59a

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_ptr_0802f5f8 - table lookup by key, returns pointer or 0.
@ r0 = object; ctx = word at r0+0x10; ctx[0] = base address, ctx[1] = pointer to
@ 8-byte entries, ctx[2] = descriptor d, ctx[5] = cached key, ctx[6] = cached index.
@ d: word at d+0 = low bound, halfword at d+4 = high bound, word at d+8 = pointer
@ to sorted ushort key array, halfword at d+0x10 = count.  r1 = key.
@ Returns 0 unless d[0] <= key <= (ushort)d[4 bytes].  If ctx[5] == key the index
@ ctx[6] is reused (index -1 gives 0), else binary search of key & 0xffff over the
@ ushort array (lo = 0, hi = count-1, probe at byte offset (lo+hi) & ~1; count 0
@ gives 0).  On a hit stores ctx[5] = key, ctx[6] = index i and returns
@ (word at ctx[1]+i*8 & 0xfffff) + ctx[0]; not found returns 0.  No memory outside
@ the context is written.  Body identical to the other 7 functions of this group.
@ What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_ptr_0802f5f8,"ax",%progbits
	.global lookup_sorted_table_ptr_0802f5f8
	.thumb_func
	.type lookup_sorted_table_ptr_0802f5f8, %function
lookup_sorted_table_ptr_0802f5f8:
	push	{r4, r5, r7, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r2, [r0, #0x0]	@ low bound
	cmp	r2, r1
	bhi.n	.L0802f60e
	ldrh	r2, [r0, #0x4]	@ high bound
	cmp	r2, r1
	bcs.n	.L0802f612
.L0802f60e:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r7, pc}
.L0802f612:
	ldr.w	r2, [r12, #0x14]	@ cached key
	cmp	r2, r1
	bne.n	.L0802f63a
	ldr.w	r4, [r12, #0x18]	@ cached index
.L0802f61e:
	adds	r0, r4, #0x1
	beq.n	.L0802f60e	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r1, r4, [r12, #0x14]	@ cache key and index
	ldr.w	r0, [r0, r4, lsl #0x3]
	ldr.w	r1, [r12, #0x0]	@ base address
	bfc	r0, #0x14, #0xc	@ keep low 20 bits
	add	r0, r1
	pop	{r4, r5, r7, pc}
.L0802f63a:
	ldrh	r2, [r0, #0x10]	@ count
	cmp	r2, #0x0
	beq.n	.L0802f60e
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r3, r1
	subs	r0, r2, #0x1	@ hi = count - 1
	movs	r2, #0x0	@ lo = 0
	b.n	.L0802f652
.L0802f64c:
	subs	r0, r4, #0x1	@ hi = mid - 1
	cmp	r2, r0
	bgt.n	.L0802f60e
.L0802f652:
	adds	r4, r2, r0
	bic	r5, r4, #0x1
	ldrh.w	r5, [lr, r5]
	asrs	r4, r4, #0x1	@ mid
	cmp	r5, r3
	bhi.n	.L0802f64c
	bcs.n	.L0802f61e
	adds	r2, r4, #0x1	@ lo = mid + 1
	cmp	r2, r0
	ble.n	.L0802f652
	b.n	.L0802f60e

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_ptr_0802f66c - table lookup by key, returns pointer or 0.
@ r0 = object; ctx = word at r0+0x10; ctx[0] = base address, ctx[1] = pointer to
@ 8-byte entries, ctx[2] = descriptor d, ctx[5] = cached key, ctx[6] = cached index.
@ d: word at d+0 = low bound, halfword at d+4 = high bound, word at d+8 = pointer
@ to sorted ushort key array, halfword at d+0x10 = count.  r1 = key.
@ Returns 0 unless d[0] <= key <= (ushort)d[4 bytes].  If ctx[5] == key the index
@ ctx[6] is reused (index -1 gives 0), else binary search of key & 0xffff over the
@ ushort array (lo = 0, hi = count-1, probe at byte offset (lo+hi) & ~1; count 0
@ gives 0).  On a hit stores ctx[5] = key, ctx[6] = index i and returns
@ (word at ctx[1]+i*8 & 0xfffff) + ctx[0]; not found returns 0.  No memory outside
@ the context is written.  Body identical to the other 7 functions of this group.
@ What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_ptr_0802f66c,"ax",%progbits
	.global lookup_sorted_table_ptr_0802f66c
	.thumb_func
	.type lookup_sorted_table_ptr_0802f66c, %function
lookup_sorted_table_ptr_0802f66c:
	push	{r4, r5, r7, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r2, [r0, #0x0]	@ low bound
	cmp	r2, r1
	bhi.n	.L0802f682
	ldrh	r2, [r0, #0x4]	@ high bound
	cmp	r2, r1
	bcs.n	.L0802f686
.L0802f682:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r7, pc}
.L0802f686:
	ldr.w	r2, [r12, #0x14]	@ cached key
	cmp	r2, r1
	bne.n	.L0802f6ae
	ldr.w	r4, [r12, #0x18]	@ cached index
.L0802f692:
	adds	r0, r4, #0x1
	beq.n	.L0802f682	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r1, r4, [r12, #0x14]	@ cache key and index
	ldr.w	r0, [r0, r4, lsl #0x3]
	ldr.w	r1, [r12, #0x0]	@ base address
	bfc	r0, #0x14, #0xc	@ keep low 20 bits
	add	r0, r1
	pop	{r4, r5, r7, pc}
.L0802f6ae:
	ldrh	r2, [r0, #0x10]	@ count
	cmp	r2, #0x0
	beq.n	.L0802f682
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r3, r1
	subs	r0, r2, #0x1	@ hi = count - 1
	movs	r2, #0x0	@ lo = 0
	b.n	.L0802f6c6
.L0802f6c0:
	subs	r0, r4, #0x1	@ hi = mid - 1
	cmp	r2, r0
	bgt.n	.L0802f682
.L0802f6c6:
	adds	r4, r2, r0
	bic	r5, r4, #0x1
	ldrh.w	r5, [lr, r5]
	asrs	r4, r4, #0x1	@ mid
	cmp	r5, r3
	bhi.n	.L0802f6c0
	bcs.n	.L0802f692
	adds	r2, r4, #0x1	@ lo = mid + 1
	cmp	r2, r0
	ble.n	.L0802f6c6
	b.n	.L0802f682

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_fields_0802f6e0 - table lookup by key that fills a record;
@ returns 1 found / 0 not found.
@ r0 = object; ctx = word at r0+0x10; ctx[1] = pointer to 8-byte entries,
@ ctx[2] = descriptor d (word d+0 low bound, halfword d+4 high bound, word d+8
@ pointer to sorted ushort keys, halfword d+0x10 count), ctx[5] = cached key,
@ ctx[6] = cached index.  r1 = output ushort array; r2 = key.
@ Returns 0 unless d[0] <= key <= halfword d+4.  Cache: ctx[5] == key reuses index
@ ctx[6]; otherwise binary search of key & 0xffff over the ushort array.
@ On a hit e = ctx[1]+i*8, stores ctx[5] = key, ctx[6] = i and writes
@ out[0] = word(e) >> 20, out[1] = byte e[4], out[2] = byte e[5],
@ out[3] = signed byte e[6], out[4] = signed byte e[7], byte at out+10 =
@ (halfword at ctx+0x12 & 0x1fff) >> 9; returns 1.  The 8 functions at 0802f6e0,
@ 0802f774, 0802f808, 0802f89c, 0802f930, 0802f9c4, 0802fa58, 0802faec have
@ identical bodies.  What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_fields_0802f6e0,"ax",%progbits
	.global lookup_sorted_table_fields_0802f6e0
	.thumb_func
	.type lookup_sorted_table_fields_0802f6e0, %function
lookup_sorted_table_fields_0802f6e0:
	push	{r4, r5, r6, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r3, [r0, #0x0]	@ low bound
	cmp	r3, r2
	bhi.n	.L0802f6f6
	ldrh	r3, [r0, #0x4]	@ high bound
	cmp	r3, r2
	bcs.n	.L0802f6fa
.L0802f6f6:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r6, pc}
.L0802f6fa:
	ldr.w	r3, [r12, #0x14]	@ cached key
	cmp	r3, r2
	bne.n	.L0802f740
	ldr.w	r5, [r12, #0x18]	@ cached index
.L0802f706:
	adds	r0, r5, #0x1
	beq.n	.L0802f6f6	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r2, r5, [r12, #0x14]	@ cache key and index
	ldr.w	r2, [r0, r5, lsl #0x3]
	add.w	r0, r0, r5, lsl #0x3	@ e = entry address
	lsrs	r2, r2, #0x14
	strh	r2, [r1, #0x0]	@ out[0] = word(e) >> 20
	ldrb	r2, [r0, #0x5]
	ldrb	r3, [r0, #0x4]
	strh	r2, [r1, #0x4]	@ out[2] = e[5]
	ldrsb.w	r2, [r0, #0x6]
	ldrsb.w	r0, [r0, #0x7]
	strh	r3, [r1, #0x2]	@ out[1] = e[4]
	strh	r2, [r1, #0x6]	@ out[3] = signed e[6]
	strh	r0, [r1, #0x8]	@ out[4] = signed e[7]
	ldrh.w	r0, [r12, #0x12]
	ubfx	r0, r0, #0x9, #0x4	@ (halfword & 0x1fff) >> 9
	strb	r0, [r1, #0xa]
	movs	r0, #0x1	@ found
	pop	{r4, r5, r6, pc}
.L0802f740:
	ldrh	r3, [r0, #0x10]	@ count
	cmp	r3, #0x0
	beq.n	.L0802f6f6
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r0, r2
	subs	r3, #0x1	@ hi = count - 1
	movs	r4, #0x0	@ lo = 0
	b.n	.L0802f75a
	.byte	0x00, 0xbf	@ padding
.L0802f754:
	subs	r3, r5, #0x1	@ hi = mid - 1
	cmp	r4, r3
	bgt.n	.L0802f6f6
.L0802f75a:
	adds	r5, r4, r3
	bic	r6, r5, #0x1
	ldrh.w	r6, [lr, r6]
	asrs	r5, r5, #0x1	@ mid
	cmp	r6, r0
	bhi.n	.L0802f754
	bcs.n	.L0802f706
	adds	r4, r5, #0x1	@ lo = mid + 1
	cmp	r4, r3
	ble.n	.L0802f75a
	b.n	.L0802f6f6

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_fields_0802f774 - table lookup by key that fills a record;
@ returns 1 found / 0 not found.
@ r0 = object; ctx = word at r0+0x10; ctx[1] = pointer to 8-byte entries,
@ ctx[2] = descriptor d (word d+0 low bound, halfword d+4 high bound, word d+8
@ pointer to sorted ushort keys, halfword d+0x10 count), ctx[5] = cached key,
@ ctx[6] = cached index.  r1 = output ushort array; r2 = key.
@ Returns 0 unless d[0] <= key <= halfword d+4.  Cache: ctx[5] == key reuses index
@ ctx[6]; otherwise binary search of key & 0xffff over the ushort array.
@ On a hit e = ctx[1]+i*8, stores ctx[5] = key, ctx[6] = i and writes
@ out[0] = word(e) >> 20, out[1] = byte e[4], out[2] = byte e[5],
@ out[3] = signed byte e[6], out[4] = signed byte e[7], byte at out+10 =
@ (halfword at ctx+0x12 & 0x1fff) >> 9; returns 1.  Body identical to the other
@ 7 functions of this group.  What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_fields_0802f774,"ax",%progbits
	.global lookup_sorted_table_fields_0802f774
	.thumb_func
	.type lookup_sorted_table_fields_0802f774, %function
lookup_sorted_table_fields_0802f774:
	push	{r4, r5, r6, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r3, [r0, #0x0]	@ low bound
	cmp	r3, r2
	bhi.n	.L0802f78a
	ldrh	r3, [r0, #0x4]	@ high bound
	cmp	r3, r2
	bcs.n	.L0802f78e
.L0802f78a:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r6, pc}
.L0802f78e:
	ldr.w	r3, [r12, #0x14]	@ cached key
	cmp	r3, r2
	bne.n	.L0802f7d4
	ldr.w	r5, [r12, #0x18]	@ cached index
.L0802f79a:
	adds	r0, r5, #0x1
	beq.n	.L0802f78a	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r2, r5, [r12, #0x14]	@ cache key and index
	ldr.w	r2, [r0, r5, lsl #0x3]
	add.w	r0, r0, r5, lsl #0x3	@ e = entry address
	lsrs	r2, r2, #0x14
	strh	r2, [r1, #0x0]	@ out[0] = word(e) >> 20
	ldrb	r2, [r0, #0x5]
	ldrb	r3, [r0, #0x4]
	strh	r2, [r1, #0x4]	@ out[2] = e[5]
	ldrsb.w	r2, [r0, #0x6]
	ldrsb.w	r0, [r0, #0x7]
	strh	r3, [r1, #0x2]	@ out[1] = e[4]
	strh	r2, [r1, #0x6]	@ out[3] = signed e[6]
	strh	r0, [r1, #0x8]	@ out[4] = signed e[7]
	ldrh.w	r0, [r12, #0x12]
	ubfx	r0, r0, #0x9, #0x4	@ (halfword & 0x1fff) >> 9
	strb	r0, [r1, #0xa]
	movs	r0, #0x1	@ found
	pop	{r4, r5, r6, pc}
.L0802f7d4:
	ldrh	r3, [r0, #0x10]	@ count
	cmp	r3, #0x0
	beq.n	.L0802f78a
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r0, r2
	subs	r3, #0x1	@ hi = count - 1
	movs	r4, #0x0	@ lo = 0
	b.n	.L0802f7ee
	.byte	0x00, 0xbf	@ padding
.L0802f7e8:
	subs	r3, r5, #0x1	@ hi = mid - 1
	cmp	r4, r3
	bgt.n	.L0802f78a
.L0802f7ee:
	adds	r5, r4, r3
	bic	r6, r5, #0x1
	ldrh.w	r6, [lr, r6]
	asrs	r5, r5, #0x1	@ mid
	cmp	r6, r0
	bhi.n	.L0802f7e8
	bcs.n	.L0802f79a
	adds	r4, r5, #0x1	@ lo = mid + 1
	cmp	r4, r3
	ble.n	.L0802f7ee
	b.n	.L0802f78a

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_fields_0802f808 - table lookup by key that fills a record;
@ returns 1 found / 0 not found.
@ r0 = object; ctx = word at r0+0x10; ctx[1] = pointer to 8-byte entries,
@ ctx[2] = descriptor d (word d+0 low bound, halfword d+4 high bound, word d+8
@ pointer to sorted ushort keys, halfword d+0x10 count), ctx[5] = cached key,
@ ctx[6] = cached index.  r1 = output ushort array; r2 = key.
@ Returns 0 unless d[0] <= key <= halfword d+4.  Cache: ctx[5] == key reuses index
@ ctx[6]; otherwise binary search of key & 0xffff over the ushort array.
@ On a hit e = ctx[1]+i*8, stores ctx[5] = key, ctx[6] = i and writes
@ out[0] = word(e) >> 20, out[1] = byte e[4], out[2] = byte e[5],
@ out[3] = signed byte e[6], out[4] = signed byte e[7], byte at out+10 =
@ (halfword at ctx+0x12 & 0x1fff) >> 9; returns 1.  Body identical to the other
@ 7 functions of this group.  What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_fields_0802f808,"ax",%progbits
	.global lookup_sorted_table_fields_0802f808
	.thumb_func
	.type lookup_sorted_table_fields_0802f808, %function
lookup_sorted_table_fields_0802f808:
	push	{r4, r5, r6, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r3, [r0, #0x0]	@ low bound
	cmp	r3, r2
	bhi.n	.L0802f81e
	ldrh	r3, [r0, #0x4]	@ high bound
	cmp	r3, r2
	bcs.n	.L0802f822
.L0802f81e:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r6, pc}
.L0802f822:
	ldr.w	r3, [r12, #0x14]	@ cached key
	cmp	r3, r2
	bne.n	.L0802f868
	ldr.w	r5, [r12, #0x18]	@ cached index
.L0802f82e:
	adds	r0, r5, #0x1
	beq.n	.L0802f81e	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r2, r5, [r12, #0x14]	@ cache key and index
	ldr.w	r2, [r0, r5, lsl #0x3]
	add.w	r0, r0, r5, lsl #0x3	@ e = entry address
	lsrs	r2, r2, #0x14
	strh	r2, [r1, #0x0]	@ out[0] = word(e) >> 20
	ldrb	r2, [r0, #0x5]
	ldrb	r3, [r0, #0x4]
	strh	r2, [r1, #0x4]	@ out[2] = e[5]
	ldrsb.w	r2, [r0, #0x6]
	ldrsb.w	r0, [r0, #0x7]
	strh	r3, [r1, #0x2]	@ out[1] = e[4]
	strh	r2, [r1, #0x6]	@ out[3] = signed e[6]
	strh	r0, [r1, #0x8]	@ out[4] = signed e[7]
	ldrh.w	r0, [r12, #0x12]
	ubfx	r0, r0, #0x9, #0x4	@ (halfword & 0x1fff) >> 9
	strb	r0, [r1, #0xa]
	movs	r0, #0x1	@ found
	pop	{r4, r5, r6, pc}
.L0802f868:
	ldrh	r3, [r0, #0x10]	@ count
	cmp	r3, #0x0
	beq.n	.L0802f81e
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r0, r2
	subs	r3, #0x1	@ hi = count - 1
	movs	r4, #0x0	@ lo = 0
	b.n	.L0802f882
	.byte	0x00, 0xbf	@ padding
.L0802f87c:
	subs	r3, r5, #0x1	@ hi = mid - 1
	cmp	r4, r3
	bgt.n	.L0802f81e
.L0802f882:
	adds	r5, r4, r3
	bic	r6, r5, #0x1
	ldrh.w	r6, [lr, r6]
	asrs	r5, r5, #0x1	@ mid
	cmp	r6, r0
	bhi.n	.L0802f87c
	bcs.n	.L0802f82e
	adds	r4, r5, #0x1	@ lo = mid + 1
	cmp	r4, r3
	ble.n	.L0802f882
	b.n	.L0802f81e

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_fields_0802f89c - table lookup by key that fills a record;
@ returns 1 found / 0 not found.
@ r0 = object; ctx = word at r0+0x10; ctx[1] = pointer to 8-byte entries,
@ ctx[2] = descriptor d (word d+0 low bound, halfword d+4 high bound, word d+8
@ pointer to sorted ushort keys, halfword d+0x10 count), ctx[5] = cached key,
@ ctx[6] = cached index.  r1 = output ushort array; r2 = key.
@ Returns 0 unless d[0] <= key <= halfword d+4.  Cache: ctx[5] == key reuses index
@ ctx[6]; otherwise binary search of key & 0xffff over the ushort array.
@ On a hit e = ctx[1]+i*8, stores ctx[5] = key, ctx[6] = i and writes
@ out[0] = word(e) >> 20, out[1] = byte e[4], out[2] = byte e[5],
@ out[3] = signed byte e[6], out[4] = signed byte e[7], byte at out+10 =
@ (halfword at ctx+0x12 & 0x1fff) >> 9; returns 1.  Body identical to the other
@ 7 functions of this group.  What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_fields_0802f89c,"ax",%progbits
	.global lookup_sorted_table_fields_0802f89c
	.thumb_func
	.type lookup_sorted_table_fields_0802f89c, %function
lookup_sorted_table_fields_0802f89c:
	push	{r4, r5, r6, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r3, [r0, #0x0]	@ low bound
	cmp	r3, r2
	bhi.n	.L0802f8b2
	ldrh	r3, [r0, #0x4]	@ high bound
	cmp	r3, r2
	bcs.n	.L0802f8b6
.L0802f8b2:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r6, pc}
.L0802f8b6:
	ldr.w	r3, [r12, #0x14]	@ cached key
	cmp	r3, r2
	bne.n	.L0802f8fc
	ldr.w	r5, [r12, #0x18]	@ cached index
.L0802f8c2:
	adds	r0, r5, #0x1
	beq.n	.L0802f8b2	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r2, r5, [r12, #0x14]	@ cache key and index
	ldr.w	r2, [r0, r5, lsl #0x3]
	add.w	r0, r0, r5, lsl #0x3	@ e = entry address
	lsrs	r2, r2, #0x14
	strh	r2, [r1, #0x0]	@ out[0] = word(e) >> 20
	ldrb	r2, [r0, #0x5]
	ldrb	r3, [r0, #0x4]
	strh	r2, [r1, #0x4]	@ out[2] = e[5]
	ldrsb.w	r2, [r0, #0x6]
	ldrsb.w	r0, [r0, #0x7]
	strh	r3, [r1, #0x2]	@ out[1] = e[4]
	strh	r2, [r1, #0x6]	@ out[3] = signed e[6]
	strh	r0, [r1, #0x8]	@ out[4] = signed e[7]
	ldrh.w	r0, [r12, #0x12]
	ubfx	r0, r0, #0x9, #0x4	@ (halfword & 0x1fff) >> 9
	strb	r0, [r1, #0xa]
	movs	r0, #0x1	@ found
	pop	{r4, r5, r6, pc}
.L0802f8fc:
	ldrh	r3, [r0, #0x10]	@ count
	cmp	r3, #0x0
	beq.n	.L0802f8b2
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r0, r2
	subs	r3, #0x1	@ hi = count - 1
	movs	r4, #0x0	@ lo = 0
	b.n	.L0802f916
	.byte	0x00, 0xbf	@ padding
.L0802f910:
	subs	r3, r5, #0x1	@ hi = mid - 1
	cmp	r4, r3
	bgt.n	.L0802f8b2
.L0802f916:
	adds	r5, r4, r3
	bic	r6, r5, #0x1
	ldrh.w	r6, [lr, r6]
	asrs	r5, r5, #0x1	@ mid
	cmp	r6, r0
	bhi.n	.L0802f910
	bcs.n	.L0802f8c2
	adds	r4, r5, #0x1	@ lo = mid + 1
	cmp	r4, r3
	ble.n	.L0802f916
	b.n	.L0802f8b2

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_fields_0802f930 - table lookup by key that fills a record;
@ returns 1 found / 0 not found.
@ r0 = object; ctx = word at r0+0x10; ctx[1] = pointer to 8-byte entries,
@ ctx[2] = descriptor d (word d+0 low bound, halfword d+4 high bound, word d+8
@ pointer to sorted ushort keys, halfword d+0x10 count), ctx[5] = cached key,
@ ctx[6] = cached index.  r1 = output ushort array; r2 = key.
@ Returns 0 unless d[0] <= key <= halfword d+4.  Cache: ctx[5] == key reuses index
@ ctx[6]; otherwise binary search of key & 0xffff over the ushort array.
@ On a hit e = ctx[1]+i*8, stores ctx[5] = key, ctx[6] = i and writes
@ out[0] = word(e) >> 20, out[1] = byte e[4], out[2] = byte e[5],
@ out[3] = signed byte e[6], out[4] = signed byte e[7], byte at out+10 =
@ (halfword at ctx+0x12 & 0x1fff) >> 9; returns 1.  Body identical to the other
@ 7 functions of this group.  What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_fields_0802f930,"ax",%progbits
	.global lookup_sorted_table_fields_0802f930
	.thumb_func
	.type lookup_sorted_table_fields_0802f930, %function
lookup_sorted_table_fields_0802f930:
	push	{r4, r5, r6, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r3, [r0, #0x0]	@ low bound
	cmp	r3, r2
	bhi.n	.L0802f946
	ldrh	r3, [r0, #0x4]	@ high bound
	cmp	r3, r2
	bcs.n	.L0802f94a
.L0802f946:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r6, pc}
.L0802f94a:
	ldr.w	r3, [r12, #0x14]	@ cached key
	cmp	r3, r2
	bne.n	.L0802f990
	ldr.w	r5, [r12, #0x18]	@ cached index
.L0802f956:
	adds	r0, r5, #0x1
	beq.n	.L0802f946	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r2, r5, [r12, #0x14]	@ cache key and index
	ldr.w	r2, [r0, r5, lsl #0x3]
	add.w	r0, r0, r5, lsl #0x3	@ e = entry address
	lsrs	r2, r2, #0x14
	strh	r2, [r1, #0x0]	@ out[0] = word(e) >> 20
	ldrb	r2, [r0, #0x5]
	ldrb	r3, [r0, #0x4]
	strh	r2, [r1, #0x4]	@ out[2] = e[5]
	ldrsb.w	r2, [r0, #0x6]
	ldrsb.w	r0, [r0, #0x7]
	strh	r3, [r1, #0x2]	@ out[1] = e[4]
	strh	r2, [r1, #0x6]	@ out[3] = signed e[6]
	strh	r0, [r1, #0x8]	@ out[4] = signed e[7]
	ldrh.w	r0, [r12, #0x12]
	ubfx	r0, r0, #0x9, #0x4	@ (halfword & 0x1fff) >> 9
	strb	r0, [r1, #0xa]
	movs	r0, #0x1	@ found
	pop	{r4, r5, r6, pc}
.L0802f990:
	ldrh	r3, [r0, #0x10]	@ count
	cmp	r3, #0x0
	beq.n	.L0802f946
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r0, r2
	subs	r3, #0x1	@ hi = count - 1
	movs	r4, #0x0	@ lo = 0
	b.n	.L0802f9aa
	.byte	0x00, 0xbf	@ padding
.L0802f9a4:
	subs	r3, r5, #0x1	@ hi = mid - 1
	cmp	r4, r3
	bgt.n	.L0802f946
.L0802f9aa:
	adds	r5, r4, r3
	bic	r6, r5, #0x1
	ldrh.w	r6, [lr, r6]
	asrs	r5, r5, #0x1	@ mid
	cmp	r6, r0
	bhi.n	.L0802f9a4
	bcs.n	.L0802f956
	adds	r4, r5, #0x1	@ lo = mid + 1
	cmp	r4, r3
	ble.n	.L0802f9aa
	b.n	.L0802f946

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_fields_0802f9c4 - table lookup by key that fills a record;
@ returns 1 found / 0 not found.
@ r0 = object; ctx = word at r0+0x10; ctx[1] = pointer to 8-byte entries,
@ ctx[2] = descriptor d (word d+0 low bound, halfword d+4 high bound, word d+8
@ pointer to sorted ushort keys, halfword d+0x10 count), ctx[5] = cached key,
@ ctx[6] = cached index.  r1 = output ushort array; r2 = key.
@ Returns 0 unless d[0] <= key <= halfword d+4.  Cache: ctx[5] == key reuses index
@ ctx[6]; otherwise binary search of key & 0xffff over the ushort array.
@ On a hit e = ctx[1]+i*8, stores ctx[5] = key, ctx[6] = i and writes
@ out[0] = word(e) >> 20, out[1] = byte e[4], out[2] = byte e[5],
@ out[3] = signed byte e[6], out[4] = signed byte e[7], byte at out+10 =
@ (halfword at ctx+0x12 & 0x1fff) >> 9; returns 1.  Body identical to the other
@ 7 functions of this group.  What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_fields_0802f9c4,"ax",%progbits
	.global lookup_sorted_table_fields_0802f9c4
	.thumb_func
	.type lookup_sorted_table_fields_0802f9c4, %function
lookup_sorted_table_fields_0802f9c4:
	push	{r4, r5, r6, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r3, [r0, #0x0]	@ low bound
	cmp	r3, r2
	bhi.n	.L0802f9da
	ldrh	r3, [r0, #0x4]	@ high bound
	cmp	r3, r2
	bcs.n	.L0802f9de
.L0802f9da:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r6, pc}
.L0802f9de:
	ldr.w	r3, [r12, #0x14]	@ cached key
	cmp	r3, r2
	bne.n	.L0802fa24
	ldr.w	r5, [r12, #0x18]	@ cached index
.L0802f9ea:
	adds	r0, r5, #0x1
	beq.n	.L0802f9da	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r2, r5, [r12, #0x14]	@ cache key and index
	ldr.w	r2, [r0, r5, lsl #0x3]
	add.w	r0, r0, r5, lsl #0x3	@ e = entry address
	lsrs	r2, r2, #0x14
	strh	r2, [r1, #0x0]	@ out[0] = word(e) >> 20
	ldrb	r2, [r0, #0x5]
	ldrb	r3, [r0, #0x4]
	strh	r2, [r1, #0x4]	@ out[2] = e[5]
	ldrsb.w	r2, [r0, #0x6]
	ldrsb.w	r0, [r0, #0x7]
	strh	r3, [r1, #0x2]	@ out[1] = e[4]
	strh	r2, [r1, #0x6]	@ out[3] = signed e[6]
	strh	r0, [r1, #0x8]	@ out[4] = signed e[7]
	ldrh.w	r0, [r12, #0x12]
	ubfx	r0, r0, #0x9, #0x4	@ (halfword & 0x1fff) >> 9
	strb	r0, [r1, #0xa]
	movs	r0, #0x1	@ found
	pop	{r4, r5, r6, pc}
.L0802fa24:
	ldrh	r3, [r0, #0x10]	@ count
	cmp	r3, #0x0
	beq.n	.L0802f9da
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r0, r2
	subs	r3, #0x1	@ hi = count - 1
	movs	r4, #0x0	@ lo = 0
	b.n	.L0802fa3e
	.byte	0x00, 0xbf	@ padding
.L0802fa38:
	subs	r3, r5, #0x1	@ hi = mid - 1
	cmp	r4, r3
	bgt.n	.L0802f9da
.L0802fa3e:
	adds	r5, r4, r3
	bic	r6, r5, #0x1
	ldrh.w	r6, [lr, r6]
	asrs	r5, r5, #0x1	@ mid
	cmp	r6, r0
	bhi.n	.L0802fa38
	bcs.n	.L0802f9ea
	adds	r4, r5, #0x1	@ lo = mid + 1
	cmp	r4, r3
	ble.n	.L0802fa3e
	b.n	.L0802f9da

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_fields_0802fa58 - table lookup by key that fills a record;
@ returns 1 found / 0 not found.
@ r0 = object; ctx = word at r0+0x10; ctx[1] = pointer to 8-byte entries,
@ ctx[2] = descriptor d (word d+0 low bound, halfword d+4 high bound, word d+8
@ pointer to sorted ushort keys, halfword d+0x10 count), ctx[5] = cached key,
@ ctx[6] = cached index.  r1 = output ushort array; r2 = key.
@ Returns 0 unless d[0] <= key <= halfword d+4.  Cache: ctx[5] == key reuses index
@ ctx[6]; otherwise binary search of key & 0xffff over the ushort array.
@ On a hit e = ctx[1]+i*8, stores ctx[5] = key, ctx[6] = i and writes
@ out[0] = word(e) >> 20, out[1] = byte e[4], out[2] = byte e[5],
@ out[3] = signed byte e[6], out[4] = signed byte e[7], byte at out+10 =
@ (halfword at ctx+0x12 & 0x1fff) >> 9; returns 1.  Body identical to the other
@ 7 functions of this group.  What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_fields_0802fa58,"ax",%progbits
	.global lookup_sorted_table_fields_0802fa58
	.thumb_func
	.type lookup_sorted_table_fields_0802fa58, %function
lookup_sorted_table_fields_0802fa58:
	push	{r4, r5, r6, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r3, [r0, #0x0]	@ low bound
	cmp	r3, r2
	bhi.n	.L0802fa6e
	ldrh	r3, [r0, #0x4]	@ high bound
	cmp	r3, r2
	bcs.n	.L0802fa72
.L0802fa6e:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r6, pc}
.L0802fa72:
	ldr.w	r3, [r12, #0x14]	@ cached key
	cmp	r3, r2
	bne.n	.L0802fab8
	ldr.w	r5, [r12, #0x18]	@ cached index
.L0802fa7e:
	adds	r0, r5, #0x1
	beq.n	.L0802fa6e	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r2, r5, [r12, #0x14]	@ cache key and index
	ldr.w	r2, [r0, r5, lsl #0x3]
	add.w	r0, r0, r5, lsl #0x3	@ e = entry address
	lsrs	r2, r2, #0x14
	strh	r2, [r1, #0x0]	@ out[0] = word(e) >> 20
	ldrb	r2, [r0, #0x5]
	ldrb	r3, [r0, #0x4]
	strh	r2, [r1, #0x4]	@ out[2] = e[5]
	ldrsb.w	r2, [r0, #0x6]
	ldrsb.w	r0, [r0, #0x7]
	strh	r3, [r1, #0x2]	@ out[1] = e[4]
	strh	r2, [r1, #0x6]	@ out[3] = signed e[6]
	strh	r0, [r1, #0x8]	@ out[4] = signed e[7]
	ldrh.w	r0, [r12, #0x12]
	ubfx	r0, r0, #0x9, #0x4	@ (halfword & 0x1fff) >> 9
	strb	r0, [r1, #0xa]
	movs	r0, #0x1	@ found
	pop	{r4, r5, r6, pc}
.L0802fab8:
	ldrh	r3, [r0, #0x10]	@ count
	cmp	r3, #0x0
	beq.n	.L0802fa6e
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r0, r2
	subs	r3, #0x1	@ hi = count - 1
	movs	r4, #0x0	@ lo = 0
	b.n	.L0802fad2
	.byte	0x00, 0xbf	@ padding
.L0802facc:
	subs	r3, r5, #0x1	@ hi = mid - 1
	cmp	r4, r3
	bgt.n	.L0802fa6e
.L0802fad2:
	adds	r5, r4, r3
	bic	r6, r5, #0x1
	ldrh.w	r6, [lr, r6]
	asrs	r5, r5, #0x1	@ mid
	cmp	r6, r0
	bhi.n	.L0802facc
	bcs.n	.L0802fa7e
	adds	r4, r5, #0x1	@ lo = mid + 1
	cmp	r4, r3
	ble.n	.L0802fad2
	b.n	.L0802fa6e

@ ----------------------------------------------------------------------------
@ lookup_sorted_table_fields_0802faec - table lookup by key that fills a record;
@ returns 1 found / 0 not found.
@ r0 = object; ctx = word at r0+0x10; ctx[1] = pointer to 8-byte entries,
@ ctx[2] = descriptor d (word d+0 low bound, halfword d+4 high bound, word d+8
@ pointer to sorted ushort keys, halfword d+0x10 count), ctx[5] = cached key,
@ ctx[6] = cached index.  r1 = output ushort array; r2 = key.
@ Returns 0 unless d[0] <= key <= halfword d+4.  Cache: ctx[5] == key reuses index
@ ctx[6]; otherwise binary search of key & 0xffff over the ushort array.
@ On a hit e = ctx[1]+i*8, stores ctx[5] = key, ctx[6] = i and writes
@ out[0] = word(e) >> 20, out[1] = byte e[4], out[2] = byte e[5],
@ out[3] = signed byte e[6], out[4] = signed byte e[7], byte at out+10 =
@ (halfword at ctx+0x12 & 0x1fff) >> 9; returns 1.  Body identical to the other
@ 7 functions of this group.  What the table holds is not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.lookup_sorted_table_fields_0802faec,"ax",%progbits
	.global lookup_sorted_table_fields_0802faec
	.thumb_func
	.type lookup_sorted_table_fields_0802faec, %function
lookup_sorted_table_fields_0802faec:
	push	{r4, r5, r6, lr}
	ldr.w	r12, [r0, #0x10]	@ ctx
	ldr.w	r0, [r12, #0x8]	@ descriptor d
	ldr	r3, [r0, #0x0]	@ low bound
	cmp	r3, r2
	bhi.n	.L0802fb02
	ldrh	r3, [r0, #0x4]	@ high bound
	cmp	r3, r2
	bcs.n	.L0802fb06
.L0802fb02:
	movs	r0, #0x0	@ not found
	pop	{r4, r5, r6, pc}
.L0802fb06:
	ldr.w	r3, [r12, #0x14]	@ cached key
	cmp	r3, r2
	bne.n	.L0802fb4c
	ldr.w	r5, [r12, #0x18]	@ cached index
.L0802fb12:
	adds	r0, r5, #0x1
	beq.n	.L0802fb02	@ index -1: not found
	ldr.w	r0, [r12, #0x4]	@ entries
	strd	r2, r5, [r12, #0x14]	@ cache key and index
	ldr.w	r2, [r0, r5, lsl #0x3]
	add.w	r0, r0, r5, lsl #0x3	@ e = entry address
	lsrs	r2, r2, #0x14
	strh	r2, [r1, #0x0]	@ out[0] = word(e) >> 20
	ldrb	r2, [r0, #0x5]
	ldrb	r3, [r0, #0x4]
	strh	r2, [r1, #0x4]	@ out[2] = e[5]
	ldrsb.w	r2, [r0, #0x6]
	ldrsb.w	r0, [r0, #0x7]
	strh	r3, [r1, #0x2]	@ out[1] = e[4]
	strh	r2, [r1, #0x6]	@ out[3] = signed e[6]
	strh	r0, [r1, #0x8]	@ out[4] = signed e[7]
	ldrh.w	r0, [r12, #0x12]
	ubfx	r0, r0, #0x9, #0x4	@ (halfword & 0x1fff) >> 9
	strb	r0, [r1, #0xa]
	movs	r0, #0x1	@ found
	pop	{r4, r5, r6, pc}
.L0802fb4c:
	ldrh	r3, [r0, #0x10]	@ count
	cmp	r3, #0x0
	beq.n	.L0802fb02
	ldr.w	lr, [r0, #0x8]	@ ushort key array
	uxth	r0, r2
	subs	r3, #0x1	@ hi = count - 1
	movs	r4, #0x0	@ lo = 0
	b.n	.L0802fb66
	.byte	0x00, 0xbf	@ padding
.L0802fb60:
	subs	r3, r5, #0x1	@ hi = mid - 1
	cmp	r4, r3
	bgt.n	.L0802fb02
.L0802fb66:
	adds	r5, r4, r3
	bic	r6, r5, #0x1
	ldrh.w	r6, [lr, r6]
	asrs	r5, r5, #0x1	@ mid
	cmp	r6, r0
	bhi.n	.L0802fb60
	bcs.n	.L0802fb12
	adds	r4, r5, #0x1	@ lo = mid + 1
	cmp	r4, r3
	ble.n	.L0802fb66
	b.n	.L0802fb02

@ ----------------------------------------------------------------------------
@ validate_boot_sector - check the boot sector of a volume.
@ r0 = volume context, r1 = block number or -1.  Returns 0 = valid, 2 = signature
@ 0xaa55 present but fields invalid, 3 = signature missing and fields invalid,
@ 4 = bad medium byte.
@ Sets byte [ctx+3] = 0 (dirty flag cleared, no flush) and dword [ctx+0x30] =
@ 0xffffffff (cached block invalid).  If the block number != -1: medium byte
@ [ctx+1] == 3 reads address block << 12, == 2 reads block * 0x1000 + 0x200000,
@ any other value stores 0xffffffff at +0x30 and returns 4.  The read is
@ serial_device_read(ctx+0x34, address, 0x1000), then [ctx+0x30] = block.
@ Checks the 0x1000-byte block at ctx+0x34: first byte - 0xe8 < 4 and != 2 (first
@ byte 0xe8, 0xe9 or 0xeb), and either (ushort at +0x232 (block offset 0x1fe) ==
@ 0xaa55 and compare_bytes(ctx+0x86 (block offset 0x52), "FAT32   ", 8) == 0) or
@ the field checks: byte +0x41 (offset 0xd) nonzero power of two (population
@ count <= 1 and nonzero), ushort +0x3f (offset 0xb) == 0x1000, ushort +0x42 != 0,
@ byte +0x44 in 1..2, ushort +0x45 != 0, ushort +0x47 >= 0x80 or byte +0x56 /
@ +0x57 nonzero, ushort +0x4a != 0.
@ ----------------------------------------------------------------------------
	.section .text.validate_boot_sector,"ax",%progbits
	.global validate_boot_sector
	.thumb_func
	.type validate_boot_sector, %function
validate_boot_sector:
	push	{r4, r5, r6, r7, lr}
	sub	sp, #0x4
	mov	r4, r0	@ ctx
	movs	r0, #0x0
	mov	r5, r1	@ block number
	strb	r0, [r4, #0x3]	@ dirty flag cleared
	mov.w	r0, #0xffffffff
	adds	r1, #0x1
	str	r0, [r4, #0x30]	@ cached block invalid
	beq.n	.L08030bca	@ block == -1: use the data already in the buffer
	ldrb	r0, [r4, #0x1]	@ medium byte
	cmp	r0, #0x3
	beq.n	.L08030bae
	cmp	r0, #0x2
	bne.n	.L08030c88
	nop.w
	mov.w	r0, #0x200000
	add.w	r6, r0, r5, lsl #0xc	@ address = block * 0x1000 + 0x200000
	b.n	.L08030bb4
.L08030bae:
	nop.w
	lsls	r6, r5, #0xc	@ address = block << 12
.L08030bb4:
	add.w	r7, r4, #0x34	@ buffer
	nop.w
	mov	r0, r7
	mov	r1, r6
	mov.w	r2, #0x1000
	bl	serial_device_read
	str	r5, [r4, #0x30]	@ cached block = block number
.L08030bca:
	ldrb.w	r0, [r4, #0x34]	@ first byte of the block
	ldrh.w	r5, [r4, #0x232]	@ signature at block offset 0x1fe
	subs	r0, #0xe8
	cmp	r0, #0x3
	movw	r6, #0xaa55
	bhi.n	.L08030c7c
	cmp	r0, #0x2
	beq.n	.L08030c7c
	cmp	r5, r6
	bne.n	.L08030bf4
	add.w	r0, r4, #0x86
	adr	r1, .L08030c94	@ "FAT32   "
	movs	r2, #0x8
	bl	compare_bytes
	cmp	r0, #0x0
	beq.n	.L08030c76	@ FAT32 id string matches: valid
.L08030bf4:
	ldrb.w	r0, [r4, #0x41]
	subs	r1, r0, #0x1
	ands	r1, r0	@ r1 = x & (x - 1)
	clz	r0, r0
	lsr.w	r0, r0, #0x5	@ 1 if x == 0
	it	ne
	movne	r1, #0x1
	orrs	r0, r1
	bne.n	.L08030c7c	@ zero or not a power of two
	ldrh.w	r0, [r4, #0x3f]
	cmp.w	r0, #0x1000
	bne.n	.L08030c7c
	movw	r1, #0x5555	@ population count of the halfword
	and.w	r1, r1, r0, lsr #0x1
	subs	r0, r0, r1
	mov.w	r1, #0x33333333
	and.w	r1, r1, r0, lsr #0x2
	bic	r0, r0, #0xcccccccc
	add	r0, r1
	add.w	r0, r0, r0, lsr #0x4
	bic	r0, r0, #0xf0f0f0f0
	mov.w	r1, #0x1010101
	muls	r0, r1
	lsrs	r0, r0, #0x18
	cmp	r0, #0x1
	bhi.n	.L08030c7c
	ldrh.w	r0, [r4, #0x42]
	cbz	r0, .L08030c7c
	ldrb.w	r0, [r4, #0x44]
	subs	r0, #0x1
	cmp	r0, #0x1
	bhi.n	.L08030c7c
	ldrh.w	r0, [r4, #0x45]
	cbz	r0, .L08030c7c
	ldrh.w	r0, [r4, #0x47]
	cmp	r0, #0x7f
	bhi.n	.L08030c70
	ldrb.w	r0, [r4, #0x56]
	ldrb.w	r1, [r4, #0x57]
	lsls	r0, r0, #0x10
	orr.w	r0, r0, r1, lsl #0x18
	cbz	r0, .L08030c7c
.L08030c70:
	ldrh.w	r0, [r4, #0x4a]
	cbz	r0, .L08030c7c
.L08030c76:
	movs	r0, #0x0	@ valid
	add	sp, #0x4
	pop	{r4, r5, r6, r7, pc}
.L08030c7c:
	movs	r0, #0x3	@ fields invalid, signature missing
	cmp	r5, r6
	it	eq
	moveq	r0, #0x2	@ signature 0xaa55 present
	add	sp, #0x4
	pop	{r4, r5, r6, r7, pc}
.L08030c88:
	mov.w	r0, #0xffffffff
	str	r0, [r4, #0x30]	@ cached block invalid
	movs	r0, #0x4	@ bad medium byte
	add	sp, #0x4
	pop	{r4, r5, r6, r7, pc}
.L08030c94:
	.asciz	"FAT32   "
	.byte	0x00, 0x00, 0x00	@ padding

@ ----------------------------------------------------------------------------
@ next_or_allocate_cluster - follow or extend a cluster chain of an allocation
@ table.
@ r0 = pointer to an object whose first word is the volume context ctx, r1 =
@ cluster number (0 = none yet).  Returns the cluster number (>= 2), 0 = no free
@ cluster, 1 = error (bad chain entry, or a fat_set_entry result other than 0
@ and 1), 0xffffffff = read error or a fat_set_entry result of 1.
@ Uses allocation_table_read(ctx, c) to read an allocation-table entry (1 for
@ c < 2 or c >= ctx[0x18], -1 on failure) and fat_set_entry(ctx, c, v) to write
@ one; ctx[0x18] = cluster limit, ctx[0x10] = allocation hint, ctx[0x14] = free
@ count, byte ctx[4] bit0 = dirty.
@ Cluster != 0: entry e = read(cluster); e < 2 returns 1, -1 returns -1, e <
@ ctx[0x18] returns e (the next cluster of the chain).  When the chain ends
@ (e >= ctx[0x18]) or cluster == 0: returns 0 if ctx[0x14] == 0; otherwise: with
@ cluster != 0 the entry cluster+1 (2 when cluster+1 >= ctx[0x18]) is tried first
@ (read -1 returns 0xffffffff, 0 selects it, 1 returns 1); then a circular search
@ (index+1, wrapping to 2 when >= ctx[0x18]; read -1 returns 0xffffffff, 0 selects
@ the index, 1 returns 1; returns 0 after the start index was visited again)
@ starts at the hint ctx[0x10] when 2 <= hint < ctx[0x18], else at cluster when
@ cluster >= 2.  With cluster == 0 it is the circular search from the hint when
@ 2 <= hint < ctx[0x18], else a linear search from 2 up to ctx[0x18]-1 (returns 0
@ at the limit, 0xffffffff on read -1, 1 on an entry of 1).
@ On a free entry f: fat_set_entry(ctx, f, 0xffffffff) marks it last, and if
@ cluster != 0, fat_set_entry(ctx, cluster, f) links it; error 1 returns
@ 0xffffffff, other errors return 1; then ctx[0x10] = f, ctx[0x14] decremented
@ when <= ctx[0x18]-2, byte ctx[4] |= 1, returns f.
@ ----------------------------------------------------------------------------
	.section .text.next_or_allocate_cluster,"ax",%progbits
	.global next_or_allocate_cluster
	.thumb_func
	.type next_or_allocate_cluster, %function
next_or_allocate_cluster:
	push.w	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
	sub	sp, #0x4
	ldr.w	r8, [r0, #0x0]	@ ctx
	mov	r10, r1	@ cluster
	mov	r6, r0
	cbz	r1, .L080312f4
	mov	r0, r8
	mov	r1, r10
	bl	allocation_table_read
	cmp	r0, #0x2
	bcs.n	.L08031310
	movs	r7, #0x1	@ entry < 2: error
	b.n	.L08031426
.L080312f4:
	ldr.w	r0, [r8, #0x10]	@ allocation hint
	cbz	r0, .L08031302
	ldr.w	r1, [r8, #0x18]	@ cluster limit
	cmp	r0, r1
	bcc.n	.L08031322
.L08031302:
	mov	r9, r8
	ldr.w	r0, [r9, #0x14]!	@ free count
	cbz	r0, .L0803136c
	add.w	r5, r8, #0x18	@ &cluster limit
	b.n	.L080313b0
.L08031310:
	mov	r7, r0
	adds	r0, #0x1
	beq.n	.L08031366
	ldr.w	r1, [r8, #0x18]
	mov	r0, r10
	cmp	r7, r1
	bcc.w	.L08031426	@ chain continues: return next cluster
.L08031322:
	mov	r9, r8
	ldr.w	r2, [r9, #0x14]!	@ free count
	cbz	r2, .L08031370
	cmp	r0, r10
	bne.n	.L080313a6
	add.w	r4, r10, #0x1	@ try cluster + 1 first
	ldr	r0, [r6, #0x0]
	cmp	r4, r1
	it	cs
	movcs	r4, #0x2
	mov	r1, r4
	bl	allocation_table_read
	mov	r7, r0
	adds	r0, #0x1
	beq.n	.L08031426
	cbz	r7, .L08031374
	cmp	r7, #0x1
	beq.n	.L08031426
	ldr.w	r11, [r8, #0x10]	@ hint
	mov	r0, r10
	cmp.w	r11, #0x2
	bcc.n	.L080313a6
	add.w	r5, r8, #0x18
	ldr	r0, [r5, #0x0]
	cmp	r11, r0
	mov	r0, r10
	bcs.n	.L080313a6
	b.n	.L080313d8
.L08031366:
	mov.w	r7, #0xffffffff	@ read error
	b.n	.L08031426
.L0803136c:
	movs	r7, #0x0	@ no free cluster
	b.n	.L08031426
.L08031370:
	movs	r7, #0x0	@ no free cluster
	b.n	.L08031426
.L08031374:
	mov	r0, r10
	cbz	r4, .L080313a6
.L08031378:
	mov	r0, r8	@ free entry found: mark it last
	mov	r1, r4
	mov.w	r2, #0xffffffff
	mov	r7, r4
	bl	fat_set_entry
	cmp.w	r10, #0x0
	beq.n	.L08031398
	cbnz	r0, .L08031398
	mov	r0, r8	@ link the old cluster to the new one
	mov	r1, r10
	mov	r2, r7
	bl	fat_set_entry
.L08031398:
	cbz	r0, .L08031406
	movs	r7, #0x1	@ set error: return 1
	cmp	r0, #0x1
	it	eq
	moveq.w	r7, #0xffffffff	@ set result 1: return 0xffffffff
	b.n	.L08031426
.L080313a6:
	add.w	r5, r8, #0x18
	cmp	r0, #0x2
	mov	r11, r0
	bcs.n	.L080313d8
.L080313b0:
	movs	r4, #0x1	@ linear search from 2
	nop
.L080313b4:
	ldr	r0, [r5, #0x0]
	adds	r4, #0x1
	cmp	r4, r0
	bcs.n	.L080313d4
	ldr	r0, [r6, #0x0]
	mov	r1, r4
	bl	allocation_table_read
	mov	r7, r0
	adds	r0, #0x1
	beq.n	.L08031426
	cmp	r7, #0x0
	beq.n	.L08031378
	cmp	r7, #0x1
	bne.n	.L080313b4
	b.n	.L08031426
.L080313d4:
	movs	r7, #0x0	@ limit reached: no free cluster
	b.n	.L08031426
.L080313d8:
	mov	r4, r11	@ circular search from the start index
	nop
.L080313dc:
	ldr	r0, [r5, #0x0]
	adds	r4, #0x1
	cmp	r4, r0
	ldr	r0, [r6, #0x0]
	it	cs
	movcs	r4, #0x2	@ wrap to 2
	mov	r1, r4
	bl	allocation_table_read
	mov	r7, r0
	adds	r0, #0x1
	beq.n	.L08031426
	cmp	r7, #0x0
	beq.n	.L08031378
	cmp	r7, #0x1
	beq.n	.L08031426
	cmp	r4, r11
	mov.w	r7, #0x0
	bne.n	.L080313dc
	b.n	.L08031426
.L08031406:
	ldrd	r0, r1, [r8, #0x14]	@ r0 = free count, r1 = cluster limit
	str.w	r7, [r8, #0x10]	@ hint = new cluster
	subs	r1, #0x2
	cmp	r0, r1
	itt	ls
	subls	r0, #0x1
	strls.w	r0, [r9, #0x0]	@ free count decremented
	ldrb.w	r0, [r8, #0x4]
	orr	r0, r0, #0x1
	strb.w	r0, [r8, #0x4]	@ dirty
.L08031426:
	mov	r0, r7
	add	sp, #0x4
	pop.w	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
	.byte	0x00, 0x00	@ padding
