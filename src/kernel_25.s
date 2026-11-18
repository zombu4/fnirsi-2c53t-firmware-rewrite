@ kernel_25.s - kernel: queue_receive_timeout, semaphore_take_timeout and the units that follow them.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ queue_receive_timeout - removes one item from a queue, waiting up to r2 ticks.
@ Params: r0 = queue record, r1 = destination buffer, r2 = timeout ticks.
@ Returns 1 when an item was copied out, 0 when the queue stayed empty / timed out.
@ Loops forever (BASEPRI set to 0x10) if r0 == 0, if r1 == 0 and word +0x40 != 0,
@ or if fn_08042730() == 0 and r2 != 0.
@ Loop: enter_critical (08041168); if word +0x38 (item count) != 0:
@ queue_copy_out_item (0803bc80)(r0, r1) copies one item out, word +0x38 is
@ decremented, and when word +0x10 != 0 and fn_08042b4c(r0+0x10) returns nonzero
@ it writes 0x10000000 to 0xE000ED04 (pend a context switch) with DSB/ISB;
@ exit_critical (080411b0); returns 1.
@ If empty and r2 == 0: exit_critical, returns 0.
@ Otherwise: the first pass stores the time stamp with fn_08041400, then
@ exit_critical, increment_word_200061e4 (08041904), enter_critical, clears
@ bytes +0x44/+0x45 when they are 0xff, exit_critical, then
@ fn_080425cc(&stamp, &timeout): 0 (not timed out) -> if queue_is_empty (0803c2ac)
@ (r0) == 0 it calls queue_unlock (0803c7b8), fn_08042c10 and retries, else
@ fn_08041434(r0+0x24, timeout), queue_unlock, fn_08042c10 (0x10000000 to
@ 0xE000ED04 when it returned 0) and retries; nonzero (timed out) ->
@ queue_unlock, fn_08042c10, returns 0 when queue_is_empty(r0) != 0, else
@ retries. (0xffffffff never expires, see 080425cc.)
@ Stack: [sp+0x1c] queue, [sp+0x18] buffer, [sp+0x14] timeout, [sp+0x10] first-pass
@ flag, [sp+0x8] time stamp, [sp+0x4] queue copy, [sp+0x0] item count,
@ [sp+0x20] result.
@ ----------------------------------------------------------------------------
	.section .text.queue_receive_timeout,"ax",%progbits
	.global queue_receive_timeout
	.thumb_func
	.type queue_receive_timeout, %function
queue_receive_timeout:
	push	{r7, lr}
	sub	sp, #0x30
	str	r0, [sp, #0x1c]
	str	r1, [sp, #0x18]
	str	r2, [sp, #0x14]
	movs	r0, #0
	str	r0, [sp, #0x10]
	ldr	r0, [sp, #0x1c]
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	cbnz	r0, .L08042206
	b.n	.L080421f0
.L080421f0:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x24]
	b.n	.L08042204
.L08042204:
	b.n	.L08042204
.L08042206:
	ldr	r1, [sp, #0x18]
	movs	r0, #0
	cbnz	r1, .L0804221a
	b.n	.L0804220e
.L0804220e:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x40]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	b.n	.L0804221a
.L0804221a:
	lsls	r0, r0, #0x1f
	cbz	r0, .L08042236
	b.n	.L08042220
.L08042220:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x28]
	b.n	.L08042234
.L08042234:
	b.n	.L08042234
.L08042236:
	bl	fn_08042730
	movs	r1, #0
	cbnz	r0, .L0804224a
	b.n	.L08042240
.L08042240:
	ldr	r1, [sp, #0x14]
	cmp	r1, #0
	it	ne
	movne	r1, #1
	b.n	.L0804224a
.L0804224a:
	lsls	r0, r1, #0x1f
	cbz	r0, .L08042266
	b.n	.L08042250
.L08042250:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x2c]
	b.n	.L08042264
.L08042264:
	b.n	.L08042264
.L08042266:
	b.n	.L08042268
.L08042268:
	bl	enter_critical
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x38]
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0x0]
	cbz	r0, .L080422c4
	b.n	.L08042278
.L08042278:
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp, #0x18]
	bl	queue_copy_out_item
	ldr	r0, [sp, #0x0]
	subs	r0, #1
	ldr	r1, [sp, #0x4]
	str	r0, [r1, #0x38]
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x10]
	cbz	r0, .L080422b8
	b.n	.L08042290
.L08042290:
	ldr	r0, [sp, #0x4]
	adds	r0, #0x10
	bl	fn_08042b4c
	cbz	r0, .L080422b4
	b.n	.L0804229c
.L0804229c:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0, #0x0]
	dsb	sy
	isb	sy
	b.n	.L080422b6
.L080422b4:
	b.n	.L080422b6
.L080422b6:
	b.n	.L080422ba
.L080422b8:
	b.n	.L080422ba
.L080422ba:
	bl	exit_critical
	movs	r0, #1
	str	r0, [sp, #0x20]
	b.n	.L080423a0
.L080422c4:
	ldr	r0, [sp, #0x14]
	cbnz	r0, .L080422d4
	b.n	.L080422ca
.L080422ca:
	bl	exit_critical
	movs	r0, #0
	str	r0, [sp, #0x20]
	b.n	.L080423a0
.L080422d4:
	ldr	r0, [sp, #0x10]
	cbnz	r0, .L080422e6
	b.n	.L080422da
.L080422da:
	add	r0, sp, #0x8
	bl	fn_08041400
	movs	r0, #1
	str	r0, [sp, #0x10]
	b.n	.L080422e8
.L080422e6:
	b.n	.L080422e8
.L080422e8:
	b.n	.L080422ea
.L080422ea:
	b.n	.L080422ec
.L080422ec:
	bl	exit_critical
	bl	increment_word_200061e4
	bl	enter_critical
	ldr	r0, [sp, #0x4]
	ldrsb.w	r0, [r0, #0x44]
	adds	r0, #1
	cbnz	r0, .L0804230e
	b.n	.L08042304
.L08042304:
	ldr	r0, [sp, #0x4]
	movs	r1, #0
	strb.w	r1, [r0, #0x44]
	b.n	.L0804230e
.L0804230e:
	ldr	r0, [sp, #0x4]
	ldrsb.w	r0, [r0, #0x45]
	adds	r0, #1
	cbnz	r0, .L08042324
	b.n	.L0804231a
.L0804231a:
	ldr	r0, [sp, #0x4]
	movs	r1, #0
	strb.w	r1, [r0, #0x45]
	b.n	.L08042324
.L08042324:
	bl	exit_critical
	add	r0, sp, #0x8
	add	r1, sp, #0x14
	bl	fn_080425cc
	cbnz	r0, .L08042380
	b.n	.L08042334
.L08042334:
	ldr	r0, [sp, #0x4]
	bl	queue_is_empty
	cbz	r0, .L08042372
	b.n	.L0804233e
.L0804233e:
	ldr	r0, [sp, #0x4]
	adds	r0, #0x24
	ldr	r1, [sp, #0x14]
	bl	fn_08041434
	ldr	r0, [sp, #0x4]
	bl	queue_unlock
	bl	fn_08042c10
	cbnz	r0, .L0804236e
	b.n	.L08042356
.L08042356:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0, #0x0]
	dsb	sy
	isb	sy
	b.n	.L08042370
.L0804236e:
	b.n	.L08042370
.L08042370:
	b.n	.L0804237e
.L08042372:
	ldr	r0, [sp, #0x4]
	bl	queue_unlock
	bl	fn_08042c10
	b.n	.L0804237e
.L0804237e:
	b.n	.L0804239e
.L08042380:
	ldr	r0, [sp, #0x4]
	bl	queue_unlock
	bl	fn_08042c10
	ldr	r0, [sp, #0x4]
	bl	queue_is_empty
	cbz	r0, .L0804239a
	b.n	.L08042394
.L08042394:
	movs	r0, #0
	str	r0, [sp, #0x20]
	b.n	.L080423a0
.L0804239a:
	b.n	.L0804239c
.L0804239c:
	b.n	.L0804239e
.L0804239e:
	b.n	.L08042268
.L080423a0:
	ldr	r0, [sp, #0x20]
	add	sp, #0x30
	pop	{r7, pc}
	.short	0x0000	@ padding (never reached, after pop {r7,pc})

@ ----------------------------------------------------------------------------
@ semaphore_take_timeout - takes one count from a zero-item-size queue record,
@ waiting up to r1 ticks.
@ Params: r0 = queue record, r1 = timeout ticks.
@ Returns 1 when a count was taken, 0 on timeout / empty.
@ Loops forever (BASEPRI 0x10) if r0 == 0, if word +0x40 != 0, or if
@ fn_08042730() == 0 and r1 != 0.
@ Loop: enter_critical (08041168); if word +0x38 != 0: decrements it; if r0[0]
@ == 0 stores current_task_increment_field_0x48 (0803ce80) result in r0[2]; if
@ word +0x10 != 0 and fn_08042b4c(r0+0x10) returns nonzero writes 0x10000000
@ to 0xE000ED04 with DSB/ISB; exit_critical (080411b0); returns 1.
@ If empty and r1 == 0: when fn_08042a2c had made an adjustment (flag set) it
@ loops forever, else exit_critical and returns 0.
@ Otherwise as in queue_receive_timeout (stamp fn_08041400,
@ increment_word_200061e4, byte fixups, fn_080425cc); in the not-timed-out
@ case with queue_is_empty(r0) != 0: when r0[0] == 0 it runs fn_08042a2c(r0[2])
@ under enter_critical / exit_critical and keeps its result, then
@ fn_08041434(r0+0x24, timeout), queue_unlock (0803c7b8), fn_08042c10
@ (0x10000000 to 0xE000ED04 when it returned 0); after a timeout with
@ queue_is_empty(r0) != 0 and the adjustment flag set it calls
@ fn_080414cc(r0[2], 0803bda8(r0)) under enter_critical / exit_critical, then
@ returns 0.
@ ----------------------------------------------------------------------------
	.section .text.semaphore_take_timeout,"ax",%progbits
	.global semaphore_take_timeout
	.thumb_func
	.type semaphore_take_timeout, %function
semaphore_take_timeout:
	push	{r7, lr}
	sub	sp, #0x38
	str	r0, [sp, #0x20]
	str	r1, [sp, #0x1c]
	movs	r0, #0
	str	r0, [sp, #0x18]
	ldr	r1, [sp, #0x20]
	str	r1, [sp, #0xc]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0xc]
	cbnz	r0, .L080423d6
	b.n	.L080423c0
.L080423c0:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x28]
	b.n	.L080423d4
.L080423d4:
	b.n	.L080423d4
.L080423d6:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x40]
	cbz	r0, .L080423f4
	b.n	.L080423de
.L080423de:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x2c]
	b.n	.L080423f2
.L080423f2:
	b.n	.L080423f2
.L080423f4:
	bl	fn_08042730
	movs	r1, #0
	cbnz	r0, .L08042408
	b.n	.L080423fe
.L080423fe:
	ldr	r1, [sp, #0x1c]
	cmp	r1, #0
	it	ne
	movne	r1, #1
	b.n	.L08042408
.L08042408:
	lsls	r0, r1, #0x1f
	cbz	r0, .L08042424
	b.n	.L0804240e
.L0804240e:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x30]
	b.n	.L08042422
.L08042422:
	b.n	.L08042422
.L08042424:
	b.n	.L08042426
.L08042426:
	bl	enter_critical
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x38]
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	cbz	r0, .L0804248e
	b.n	.L08042436
.L08042436:
	ldr	r0, [sp, #0x4]
	subs	r0, #1
	ldr	r1, [sp, #0xc]
	str	r0, [r1, #0x38]
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x0]
	cbnz	r0, .L08042450
	b.n	.L08042446
.L08042446:
	bl	current_task_increment_field_0x48
	ldr	r1, [sp, #0xc]
	str	r0, [r1, #0x8]
	b.n	.L08042452
.L08042450:
	b.n	.L08042452
.L08042452:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x10]
	cbz	r0, .L08042482
	b.n	.L0804245a
.L0804245a:
	ldr	r0, [sp, #0xc]
	adds	r0, #0x10
	bl	fn_08042b4c
	cbz	r0, .L0804247e
	b.n	.L08042466
.L08042466:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0, #0x0]
	dsb	sy
	isb	sy
	b.n	.L08042480
.L0804247e:
	b.n	.L08042480
.L08042480:
	b.n	.L08042484
.L08042482:
	b.n	.L08042484
.L08042484:
	bl	exit_critical
	movs	r0, #1
	str	r0, [sp, #0x24]
	b.n	.L080425c6
.L0804248e:
	ldr	r0, [sp, #0x1c]
	cbnz	r0, .L080424ba
	b.n	.L08042494
.L08042494:
	ldr	r0, [sp, #0x8]
	cbz	r0, .L080424b0
	b.n	.L0804249a
.L0804249a:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x34]
	b.n	.L080424ae
.L080424ae:
	b.n	.L080424ae
.L080424b0:
	bl	exit_critical
	movs	r0, #0
	str	r0, [sp, #0x24]
	b.n	.L080425c6
.L080424ba:
	ldr	r0, [sp, #0x18]
	cbnz	r0, .L080424cc
	b.n	.L080424c0
.L080424c0:
	add	r0, sp, #0x10
	bl	fn_08041400
	movs	r0, #1
	str	r0, [sp, #0x18]
	b.n	.L080424ce
.L080424cc:
	b.n	.L080424ce
.L080424ce:
	b.n	.L080424d0
.L080424d0:
	b.n	.L080424d2
.L080424d2:
	bl	exit_critical
	bl	increment_word_200061e4
	bl	enter_critical
	ldr	r0, [sp, #0xc]
	ldrsb.w	r0, [r0, #0x44]
	adds	r0, #1
	cbnz	r0, .L080424f4
	b.n	.L080424ea
.L080424ea:
	ldr	r0, [sp, #0xc]
	movs	r1, #0
	strb.w	r1, [r0, #0x44]
	b.n	.L080424f4
.L080424f4:
	ldr	r0, [sp, #0xc]
	ldrsb.w	r0, [r0, #0x45]
	adds	r0, #1
	cbnz	r0, .L0804250a
	b.n	.L08042500
.L08042500:
	ldr	r0, [sp, #0xc]
	movs	r1, #0
	strb.w	r1, [r0, #0x45]
	b.n	.L0804250a
.L0804250a:
	bl	exit_critical
	add	r0, sp, #0x10
	add	r1, sp, #0x1c
	bl	fn_080425cc
	cbnz	r0, .L08042584
	b.n	.L0804251a
.L0804251a:
	ldr	r0, [sp, #0xc]
	bl	queue_is_empty
	cbz	r0, .L08042576
	b.n	.L08042524
.L08042524:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x0]
	cbnz	r0, .L08042540
	b.n	.L0804252c
.L0804252c:
	bl	enter_critical
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x8]
	bl	fn_08042a2c
	str	r0, [sp, #0x8]
	bl	exit_critical
	b.n	.L08042542
.L08042540:
	b.n	.L08042542
.L08042542:
	ldr	r0, [sp, #0xc]
	adds	r0, #0x24
	ldr	r1, [sp, #0x1c]
	bl	fn_08041434
	ldr	r0, [sp, #0xc]
	bl	queue_unlock
	bl	fn_08042c10
	cbnz	r0, .L08042572
	b.n	.L0804255a
.L0804255a:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0, #0x0]
	dsb	sy
	isb	sy
	b.n	.L08042574
.L08042572:
	b.n	.L08042574
.L08042574:
	b.n	.L08042582
.L08042576:
	ldr	r0, [sp, #0xc]
	bl	queue_unlock
	bl	fn_08042c10
	b.n	.L08042582
.L08042582:
	b.n	.L080425c4
.L08042584:
	ldr	r0, [sp, #0xc]
	bl	queue_unlock
	bl	fn_08042c10
	ldr	r0, [sp, #0xc]
	bl	queue_is_empty
	cbz	r0, .L080425c0
	b.n	.L08042598
.L08042598:
	ldr	r0, [sp, #0x8]
	cbz	r0, .L080425ba
	b.n	.L0804259e
.L0804259e:
	bl	enter_critical
	ldr	r0, [sp, #0xc]
	bl	waiting_list_top_priority
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x8]
	ldr	r1, [sp, #0x0]
	bl	fn_080414cc
	bl	exit_critical
	b.n	.L080425ba
.L080425ba:
	movs	r0, #0
	str	r0, [sp, #0x24]
	b.n	.L080425c6
.L080425c0:
	b.n	.L080425c2
.L080425c2:
	b.n	.L080425c4
.L080425c4:
	b.n	.L08042426
.L080425c6:
	ldr	r0, [sp, #0x24]
	add	sp, #0x38
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ fn_080425cc - checks and updates a timeout against the kernel tick counter.
@ Params: r0 = pointer to a time stamp (word 0 = overflow count, word 1 = tick),
@ r1 = pointer to the remaining ticks.
@ Returns 1 when timed out, 0 otherwise.
@ Loops forever (BASEPRI 0x10) if either pointer is 0. Calls enter_critical
@ (08041168). If *r1 == 0xffffffff it returns 0 (never times out, *r1
@ unchanged). Else if word 0x200062dc == stamp[0] or 0x200062d4 < stamp[1]
@ (beq at 0x08042646, bcc at 0x08042652): elapsed = 0x200062d4 - stamp[1];
@ if *r1 <= elapsed then *r1 = 0, result 1 (timed out), else *r1 -= elapsed,
@ fn_08041400(r0) refreshes the stamp, result 0. Otherwise (overflow count
@ differs and the tick is not below the stamp) *r1 = 0 and result 1.
@ Calls exit_critical (080411b0) and returns the result.
@ ----------------------------------------------------------------------------
	.section .text.fn_080425cc,"ax",%progbits
	.global fn_080425cc
	.thumb_func
	.type fn_080425cc, %function
fn_080425cc:
	push	{r7, lr}
	sub	sp, #0x20
	str	r0, [sp, #0x14]
	str	r1, [sp, #0x10]
	ldr	r0, [sp, #0x14]
	cbnz	r0, .L080425f0
	b.n	.L080425da
.L080425da:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x18]
	b.n	.L080425ee
.L080425ee:
	b.n	.L080425ee
.L080425f0:
	ldr	r0, [sp, #0x10]
	cbnz	r0, .L0804260c
	b.n	.L080425f6
.L080425f6:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x1c]
	b.n	.L0804260a
.L0804260a:
	b.n	.L0804260a
.L0804260c:
	bl	enter_critical
	movw	r0, #0x62d4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	ldr	r1, [sp, #0x14]
	ldr	r1, [r1, #0x4]
	subs	r0, r0, r1
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x10]
	ldr	r0, [r0, #0x0]
	adds	r0, #1
	cbnz	r0, .L08042636
	b.n	.L08042630
.L08042630:
	movs	r0, #0
	str	r0, [sp, #0xc]
	b.n	.L08042694
.L08042636:
	movw	r0, #0x62dc
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r1, [sp, #0x14]
	ldr	r1, [r1, #0x0]
	cmp	r0, r1
	beq.n	.L08042662
	b.n	.L0804264a
.L0804264a:
	ldr	r0, [sp, #0x8]
	ldr	r1, [sp, #0x14]
	ldr	r1, [r1, #0x4]
	cmp	r0, r1
	bcc.n	.L08042662
	b.n	.L08042656
.L08042656:
	movs	r0, #1
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0x10]
	movs	r1, #0
	str	r1, [r0, #0x0]
	b.n	.L08042692
.L08042662:
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp, #0x10]
	ldr	r1, [r1, #0x0]
	cmp	r0, r1
	bcs.n	.L08042684
	b.n	.L0804266e
.L0804266e:
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp, #0x10]
	ldr	r2, [r1, #0x0]
	subs	r0, r2, r0
	str	r0, [r1, #0x0]
	ldr	r0, [sp, #0x14]
	bl	fn_08041400
	movs	r0, #0
	str	r0, [sp, #0xc]
	b.n	.L08042690
.L08042684:
	ldr	r0, [sp, #0x10]
	movs	r1, #0
	str	r1, [r0, #0x0]
	movs	r0, #1
	str	r0, [sp, #0xc]
	b.n	.L08042690
.L08042690:
	b.n	.L08042692
.L08042692:
	b.n	.L08042694
.L08042694:
	bl	exit_critical
	ldr	r0, [sp, #0xc]
	add	sp, #0x20
	pop	{r7, pc}
	.short	0x0000	@ padding (never reached, after pop {r7,pc})

@ ----------------------------------------------------------------------------
@ fn_080426a0 - creates a task record with its own stack block and registers it.
@ Params: r0 = entry function, r1 = name string, r2 = 16-bit stack length in
@ words, r3 = value passed on (10 in the caller 08042dd4), 5th argument on the
@ stack ([sp+0x38] after the prologue) = pointer passed on (&0x200062e8 in
@ 08042dd4).
@ Allocates r2*4 bytes with heap_alloc_first_fit (0803cc64) (n); when that
@ works allocates 0x54 bytes (t); when t fails it releases n with heap_free
@ (080411e0); when both work stores n at t+0x30. If t == 0 it returns
@ 0xffffffff. Else calls task_init_record (0803bf44)(r0, r1, r2, 0, r3, stack
@ argument, t) and task_register_ready (0803bab0)(t) and returns 1.
@ ----------------------------------------------------------------------------
	.section .text.fn_080426a0,"ax",%progbits
	.global fn_080426a0
	.thumb_func
	.type fn_080426a0, %function
fn_080426a0:
	push	{r4, lr}
	sub	sp, #0x30
	ldr.w	r12, [sp, #0x38]
	str	r0, [sp, #0x2c]
	str	r1, [sp, #0x28]
	strh.w	r2, [sp, #0x26]
	movs	r0, #0
	str	r0, [sp, #0x20]
	str	r3, [sp, #0x1c]
	ldrh.w	r0, [sp, #0x26]
	lsls	r0, r0, #2
	bl	heap_alloc_first_fit
	str	r0, [sp, #0x10]
	ldr	r0, [sp, #0x10]
	cbz	r0, .L080426e8
	b.n	.L080426c8
.L080426c8:
	movs	r0, #0x54
	bl	heap_alloc_first_fit
	str	r0, [sp, #0x18]
	ldr	r0, [sp, #0x18]
	cbz	r0, .L080426de
	b.n	.L080426d6
.L080426d6:
	ldr	r0, [sp, #0x10]
	ldr	r1, [sp, #0x18]
	str	r0, [r1, #0x30]
	b.n	.L080426e6
.L080426de:
	ldr	r0, [sp, #0x10]
	bl	heap_free
	b.n	.L080426e6
.L080426e6:
	b.n	.L080426ee
.L080426e8:
	movs	r0, #0
	str	r0, [sp, #0x18]
	b.n	.L080426ee
.L080426ee:
	ldr	r0, [sp, #0x18]
	cbz	r0, .L08042722
	b.n	.L080426f4
.L080426f4:
	ldr	r0, [sp, #0x2c]
	ldr	r1, [sp, #0x28]
	ldrh.w	r2, [sp, #0x26]
	ldr	r3, [sp, #0x20]
	ldr.w	r12, [sp, #0x1c]
	ldr.w	lr, [sp, #0x38]
	ldr	r4, [sp, #0x18]
	str	r4, [sp, #0x8]
	str.w	lr, [sp, #0x4]
	str.w	r12, [sp, #0x0]
	bl	task_init_record
	ldr	r0, [sp, #0x18]
	bl	task_register_ready
	movs	r0, #1
	str	r0, [sp, #0x14]
	b.n	.L0804272a
.L08042722:
	mov.w	r0, #0xffffffff
	str	r0, [sp, #0x14]
	b.n	.L0804272a
.L0804272a:
	ldr	r0, [sp, #0x14]
	add	sp, #0x30
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08042730 - classifies the state of the words 0x20006258 and 0x200061e4.
@ No params. Returns 1 if word 0x20006258 == 0, else 2 if word 0x200061e4 == 0,
@ else 0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08042730,"ax",%progbits
	.global fn_08042730
	.thumb_func
	.type fn_08042730, %function
fn_08042730:
	sub	sp, #4
	movw	r0, #0x6258
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbnz	r0, .L08042746
	b.n	.L08042740
.L08042740:
	movs	r0, #1
	str	r0, [sp, #0x0]
	b.n	.L08042762
.L08042746:
	movw	r0, #0x61e4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbnz	r0, .L0804275a
	b.n	.L08042754
.L08042754:
	movs	r0, #2
	str	r0, [sp, #0x0]
	b.n	.L08042760
.L0804275a:
	movs	r0, #0
	str	r0, [sp, #0x0]
	b.n	.L08042760
.L08042760:
	b.n	.L08042762
.L08042762:
	ldr	r0, [sp, #0x0]
	add	sp, #4
	bx	lr

@ ----------------------------------------------------------------------------
@ get_word_200062d4 - returns the word at 0x200062d4 (the counter that
@ fn_0804277c increments and fn_080425cc compares time stamps with).
@ No params. Returns the word at 0x200062d4.
@ ----------------------------------------------------------------------------
	.section .text.get_word_200062d4,"ax",%progbits
	.global get_word_200062d4
	.thumb_func
	.type get_word_200062d4, %function
get_word_200062d4:
	sub	sp, #4
	movw	r0, #0x62d4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0x0]
	add	sp, #4
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_0804277c - increments the counter at 0x200062d4 and moves due list items
@ to the lists at 0x200061f0; returns 1 when a reschedule is needed.
@ No params; returns 1 when a reschedule is needed, else 0 (local result
@ starts 0).
@ If word 0x200061e4 == 0: tick = ++word 0x200062d4; when the tick wraps to 0
@ it loops forever (BASEPRI 0x10) if the count word *0x200062c4 != 0, else
@ swaps the list pointers 0x200062c4 / 0x200062c8, increments 0x200062dc and
@ calls update_next_unblock_time (0803c5a0).
@ If 0x200062d0 <= tick: while the count of list *0x200062c4 != 0,
@ item = *(list[3]+0xc); wake = word item+4; if tick < wake it stops
@ (0x200062d0 = wake); else list_unlink_node (08041024)(item+4),
@ list_unlink_node(item+0x18) when item[0x28] != 0, sets bit item[0x2c] in
@ 0x200061ec, list_insert_before_cursor (08041118)(0x200061f0 + item[0x2c]*20,
@ item+4), and result 1 when word 0x200061e0[0x2c] <= item[0x2c]; when the
@ list is empty 0x200062d0 = 0xffffffff.
@ Result is also 1 when the list at 0x200061f0 + (0x200061e0[0x2c])*20 has a
@ count above 1 or word 0x200061e8 != 0.
@ If 0x200061e4 != 0 it only increments word 0x200062d8.
@ ----------------------------------------------------------------------------
	.section .text.fn_0804277c,"ax",%progbits
	.global fn_0804277c
	.thumb_func
	.type fn_0804277c, %function
fn_0804277c:
	push	{r7, lr}
	sub	sp, #0x18
	movs	r0, #0
	str	r0, [sp, #0x8]
	movw	r0, #0x61e4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cmp	r0, #0
	bne.w	.L0804291e
	b.n	.L08042796
.L08042796:
	movw	r0, #0x62d4
	movt	r0, #0x2000
	ldr	r1, [r0, #0x0]
	adds	r1, #1
	str	r1, [sp, #0x4]
	ldr	r1, [sp, #0x4]
	str	r1, [r0, #0x0]
	ldr	r0, [sp, #0x4]
	cbnz	r0, .L08042804
	b.n	.L080427ae
.L080427ae:
	movw	r0, #0x62c4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r0, [r0, #0x0]
	cbz	r0, .L080427d4
	b.n	.L080427be
.L080427be:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x14]
	b.n	.L080427d2
.L080427d2:
	b.n	.L080427d2
.L080427d4:
	movw	r0, #0x62c4
	movt	r0, #0x2000
	ldr	r1, [r0, #0x0]
	str	r1, [sp, #0x0]
	movw	r1, #0x62c8
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	str	r2, [r0, #0x0]
	ldr	r0, [sp, #0x0]
	str	r0, [r1, #0x0]
	movw	r0, #0x62dc
	movt	r0, #0x2000
	ldr	r1, [r0, #0x0]
	adds	r1, #1
	str	r1, [r0, #0x0]
	bl	update_next_unblock_time
	b.n	.L08042806
.L08042804:
	b.n	.L08042806
.L08042806:
	ldr	r0, [sp, #0x4]
	movw	r1, #0x62d0
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	cmp	r0, r1
	bcc.n	.L080428dc
	b.n	.L08042818
.L08042818:
	b.n	.L0804281a
.L0804281a:
	movw	r0, #0x62c4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r0, [r0, #0x0]
	cbnz	r0, .L0804283a
	b.n	.L0804282a
.L0804282a:
	movw	r0, #0x62d0
	movt	r0, #0x2000
	mov.w	r1, #0xffffffff
	str	r1, [r0, #0x0]
	b.n	.L080428da
.L0804283a:
	movw	r0, #0x62c4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r0, [r0, #0xc]
	ldr	r0, [r0, #0xc]
	str	r0, [sp, #0x10]
	ldr	r0, [sp, #0x10]
	ldr	r0, [r0, #0x4]
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp, #0xc]
	cmp	r0, r1
	bcs.n	.L08042868
	b.n	.L0804285a
.L0804285a:
	ldr	r0, [sp, #0xc]
	movw	r1, #0x62d0
	movt	r1, #0x2000
	str	r0, [r1, #0x0]
	b.n	.L080428da
.L08042868:
	b.n	.L0804286a
.L0804286a:
	ldr	r0, [sp, #0x10]
	adds	r0, #4
	bl	list_unlink_node
	ldr	r0, [sp, #0x10]
	ldr	r0, [r0, #0x28]
	cbz	r0, .L08042884
	b.n	.L0804287a
.L0804287a:
	ldr	r0, [sp, #0x10]
	adds	r0, #0x18
	bl	list_unlink_node
	b.n	.L08042886
.L08042884:
	b.n	.L08042886
.L08042886:
	ldr	r0, [sp, #0x10]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	orrs	r0, r2
	str	r0, [r1, #0x0]
	ldr	r1, [sp, #0x10]
	ldr	r0, [r1, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r2, #0x61f0
	movt	r2, #0x2000
	add.w	r0, r2, r0, lsl #2
	adds	r1, #4
	bl	list_insert_before_cursor
	ldr	r0, [sp, #0x10]
	ldr	r0, [r0, #0x2c]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	ldr	r1, [r1, #0x2c]
	cmp	r0, r1
	bcc.n	.L080428d4
	b.n	.L080428ce
.L080428ce:
	movs	r0, #1
	str	r0, [sp, #0x8]
	b.n	.L080428d6
.L080428d4:
	b.n	.L080428d6
.L080428d6:
	b.n	.L080428d8
.L080428d8:
	b.n	.L0804281a
.L080428da:
	b.n	.L080428dc
.L080428dc:
	movw	r0, #0x61e0
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r0, [r0, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r1, #0x61f0
	movt	r1, #0x2000
	ldr.w	r0, [r1, r0, lsl #2]
	cmp	r0, #2
	bcc.n	.L08042904
	b.n	.L080428fe
.L080428fe:
	movs	r0, #1
	str	r0, [sp, #0x8]
	b.n	.L08042906
.L08042904:
	b.n	.L08042906
.L08042906:
	movw	r0, #0x61e8
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbz	r0, .L0804291a
	b.n	.L08042914
.L08042914:
	movs	r0, #1
	str	r0, [sp, #0x8]
	b.n	.L0804291c
.L0804291a:
	b.n	.L0804291c
.L0804291c:
	b.n	.L0804292e
.L0804291e:
	movw	r0, #0x62d8
	movt	r0, #0x2000
	ldr	r1, [r0, #0x0]
	adds	r1, #1
	str	r1, [r0, #0x0]
	b.n	.L0804292e
.L0804292e:
	ldr	r0, [sp, #0x8]
	add	sp, #0x18
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08042934 - decrements r0[0x48] and, at 0, re-links the record with the
@ priority r0[0x44].
@ Param: r0 = record pointer. Returns 0 if r0 == 0. Loops forever (BASEPRI
@ 0x10) if r0 is not the current record 0x200061e0 or r0[0x48] == 0.
@ Decrements r0[0x48]; if r0[0x2c] != r0[0x44] and r0[0x48] == 0: unlinks
@ r0+4 (list_unlink_node 08041024, clearing the bit of 0x200061ec if the list
@ emptied), sets r0[0x2c] = r0[0x44], r0[0x18] = 5 - r0[0x2c], sets the new
@ bit in 0x200061ec, inserts with list_insert_before_cursor (08041118) and
@ returns 1; else returns 0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08042934,"ax",%progbits
	.global fn_08042934
	.thumb_func
	.type fn_08042934, %function
fn_08042934:
	push	{r4, lr}
	sub	sp, #0x18
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0xc]
	str	r0, [sp, #0x8]
	movs	r0, #0
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0xc]
	cmp	r0, #0
	beq.n	.L08042a24
	b.n	.L0804294a
.L0804294a:
	ldr	r0, [sp, #0x8]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	cmp	r0, r1
	beq.n	.L08042972
	b.n	.L0804295c
.L0804295c:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x10]
	b.n	.L08042970
.L08042970:
	b.n	.L08042970
.L08042972:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x48]
	cbnz	r0, .L08042990
	b.n	.L0804297a
.L0804297a:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x14]
	b.n	.L0804298e
.L0804298e:
	b.n	.L0804298e
.L08042990:
	ldr	r0, [sp, #0x8]
	ldr	r1, [r0, #0x48]
	subs	r1, #1
	str	r1, [r0, #0x48]
	ldr	r0, [sp, #0x8]
	ldr	r1, [r0, #0x2c]
	ldr	r0, [r0, #0x44]
	cmp	r1, r0
	beq.n	.L08042a20
	b.n	.L080429a4
.L080429a4:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x48]
	cbnz	r0, .L08042a1c
	b.n	.L080429ac
.L080429ac:
	ldr	r0, [sp, #0x8]
	adds	r0, #4
	bl	list_unlink_node
	cbnz	r0, .L080429d4
	b.n	.L080429b8
.L080429b8:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	bic.w	r0, r2, r0
	str	r0, [r1, #0x0]
	b.n	.L080429d6
.L080429d4:
	b.n	.L080429d6
.L080429d6:
	ldr	r0, [sp, #0x8]
	ldr	r1, [r0, #0x44]
	str	r1, [r0, #0x2c]
	ldr	r0, [sp, #0x8]
	ldr	r1, [r0, #0x2c]
	rsb.w	r1, r1, #5
	str	r1, [r0, #0x18]
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x2c]
	movs	r4, #1
	lsl.w	r0, r4, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	orrs	r0, r2
	str	r0, [r1, #0x0]
	ldr	r1, [sp, #0x8]
	ldr	r0, [r1, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r2, #0x61f0
	movt	r2, #0x2000
	add.w	r0, r2, r0, lsl #2
	adds	r1, #4
	bl	list_insert_before_cursor
	str	r4, [sp, #0x4]
	b.n	.L08042a1e
.L08042a1c:
	b.n	.L08042a1e
.L08042a1e:
	b.n	.L08042a22
.L08042a20:
	b.n	.L08042a22
.L08042a22:
	b.n	.L08042a26
.L08042a24:
	b.n	.L08042a26
.L08042a26:
	ldr	r0, [sp, #0x4]
	add	sp, #0x18
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ fn_08042a2c - sets the record's priority [0x2c] to the current record's when
@ it is lower and re-links it.
@ Param: r0 = record pointer; returns bool. Returns 0 if r0 == 0.
@ If r0[0x2c] < current record's [0x2c] (current record = word 0x200061e0):
@ sets r0[0x18] = 5 - current[0x2c] when bit 7 of byte r0+0x1b is clear, then
@ either re-links r0+4 into list 0x200061f0 + newprio*20 (if r0[0x14] equals
@ the old list head, updating 0x200061ec) or just stores the new priority;
@ returns 1. Otherwise returns r0[0x44] < current[0x2c].
@ ----------------------------------------------------------------------------
	.section .text.fn_08042a2c,"ax",%progbits
	.global fn_08042a2c
	.thumb_func
	.type fn_08042a2c, %function
fn_08042a2c:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0xc]
	str	r0, [sp, #0x8]
	movs	r0, #0
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0xc]
	cmp	r0, #0
	beq.w	.L08042b42
	b.n	.L08042a44
.L08042a44:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x2c]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	ldr	r1, [r1, #0x2c]
	cmp	r0, r1
	bcs.n	.L08042b20
	b.n	.L08042a5a
.L08042a5a:
	ldr	r0, [sp, #0x8]
	ldrb	r0, [r0, #0x1b]
	lsls	r0, r0, #0x18
	cmp	r0, #0
	bmi.n	.L08042a7c
	b.n	.L08042a66
.L08042a66:
	movw	r0, #0x61e0
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r0, [r0, #0x2c]
	rsb.w	r0, r0, #5
	ldr	r1, [sp, #0x8]
	str	r0, [r1, #0x18]
	b.n	.L08042a7e
.L08042a7c:
	b.n	.L08042a7e
.L08042a7e:
	ldr	r0, [sp, #0x8]
	ldr	r1, [r0, #0x14]
	ldr	r0, [r0, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r2, #0x61f0
	movt	r2, #0x2000
	add.w	r0, r2, r0, lsl #2
	cmp	r1, r0
	bne.n	.L08042b08
	b.n	.L08042a9a
.L08042a9a:
	ldr	r0, [sp, #0x8]
	adds	r0, #4
	bl	list_unlink_node
	cbnz	r0, .L08042ac2
	b.n	.L08042aa6
.L08042aa6:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	bic.w	r0, r2, r0
	str	r0, [r1, #0x0]
	b.n	.L08042ac4
.L08042ac2:
	b.n	.L08042ac4
.L08042ac4:
	movw	r0, #0x61e0
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r0, [r0, #0x2c]
	ldr	r1, [sp, #0x8]
	str	r0, [r1, #0x2c]
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	orrs	r0, r2
	str	r0, [r1, #0x0]
	ldr	r1, [sp, #0x8]
	ldr	r0, [r1, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r2, #0x61f0
	movt	r2, #0x2000
	add.w	r0, r2, r0, lsl #2
	adds	r1, #4
	bl	list_insert_before_cursor
	b.n	.L08042b1a
.L08042b08:
	movw	r0, #0x61e0
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r0, [r0, #0x2c]
	ldr	r1, [sp, #0x8]
	str	r0, [r1, #0x2c]
	b.n	.L08042b1a
.L08042b1a:
	movs	r0, #1
	str	r0, [sp, #0x4]
	b.n	.L08042b40
.L08042b20:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x44]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	ldr	r1, [r1, #0x2c]
	cmp	r0, r1
	bcs.n	.L08042b3c
	b.n	.L08042b36
.L08042b36:
	movs	r0, #1
	str	r0, [sp, #0x4]
	b.n	.L08042b3e
.L08042b3c:
	b.n	.L08042b3e
.L08042b3e:
	b.n	.L08042b40
.L08042b40:
	b.n	.L08042b44
.L08042b42:
	b.n	.L08042b44
.L08042b44:
	ldr	r0, [sp, #0x4]
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000	@ padding (never reached, after pop {r7,pc})

@ ----------------------------------------------------------------------------
@ fn_08042b4c - takes the first item of a list, unlinks it and inserts it into
@ the lists at 0x200061f0 (or 0x20006288).
@ Param: r0 = list header pointer. Takes item = *(*(r0+0xc)+0xc); loops
@ forever (BASEPRI 0x10) if 0. Unlinks item+0x18 (list_unlink_node 08041024);
@ if 0x200061e4 == 0 unlinks item+4, sets bit item[0x2c] in 0x200061ec and
@ inserts into 0x200061f0 + item[0x2c]*20 with list_insert_before_cursor
@ (08041118); else inserts item+0x18 into list 0x20006288.
@ Returns item[0x2c] > current[0x2c] (and sets 0x200061e8 = 1 in that case).
@ ----------------------------------------------------------------------------
	.section .text.fn_08042b4c,"ax",%progbits
	.global fn_08042b4c
	.thumb_func
	.type fn_08042b4c, %function
fn_08042b4c:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0xc]
	ldr	r0, [r0, #0xc]
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	cbnz	r0, .L08042b76
	b.n	.L08042b60
.L08042b60:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L08042b74
.L08042b74:
	b.n	.L08042b74
.L08042b76:
	ldr	r0, [sp, #0x4]
	adds	r0, #0x18
	bl	list_unlink_node
	movw	r0, #0x61e4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbnz	r0, .L08042bc8
	b.n	.L08042b8c
.L08042b8c:
	ldr	r0, [sp, #0x4]
	adds	r0, #4
	bl	list_unlink_node
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	orrs	r0, r2
	str	r0, [r1, #0x0]
	ldr	r1, [sp, #0x4]
	ldr	r0, [r1, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r2, #0x61f0
	movt	r2, #0x2000
	add.w	r0, r2, r0, lsl #2
	adds	r1, #4
	bl	list_insert_before_cursor
	b.n	.L08042bdc
.L08042bc8:
	ldr	r0, [sp, #0x4]
	add.w	r1, r0, #0x18
	movw	r0, #0x6288
	movt	r0, #0x2000
	bl	list_insert_before_cursor
	b.n	.L08042bdc
.L08042bdc:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x2c]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	ldr	r1, [r1, #0x2c]
	cmp	r0, r1
	bls.n	.L08042c02
	b.n	.L08042bf2
.L08042bf2:
	movs	r0, #1
	str	r0, [sp, #0x0]
	movw	r1, #0x61e8
	movt	r1, #0x2000
	str	r0, [r1, #0x0]
	b.n	.L08042c08
.L08042c02:
	movs	r0, #0
	str	r0, [sp, #0x0]
	b.n	.L08042c08
.L08042c08:
	ldr	r0, [sp, #0x0]
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000	@ padding (never reached, after pop {r7,pc})

@ ----------------------------------------------------------------------------
@ fn_08042c10 - decrements the counter at 0x200061e4 and, when it reaches 0,
@ moves the pending items and requests a reschedule when needed.
@ No params; returns bool. Loops forever (BASEPRI 0x10) if 0x200061e4 == 0.
@ Calls enter_critical (08041168), decrements 0x200061e4; when it reaches 0
@ and 0x20006254 != 0: drains list 0x20006288 (unlink item+0x18 and item+4
@ with list_unlink_node, set priority bit, insert into 0x200061f0 + prio*20
@ with list_insert_before_cursor, set 0x200061e8 = 1 if prio >= current),
@ calls update_next_unblock_time (0803c5a0) if any moved, calls fn_0804277c
@ once per count of 0x200062d8 (setting 0x200061e8 = 1 on nonzero) then
@ clears 0x200062d8; if 0x200061e8 != 0 writes 0x10000000 to 0xE000ED04 with
@ DSB/ISB and returns 1. Calls exit_critical (080411b0).
@ ----------------------------------------------------------------------------
	.section .text.fn_08042c10,"ax",%progbits
	.global fn_08042c10
	.thumb_func
	.type fn_08042c10, %function
fn_08042c10:
	push	{r7, lr}
	sub	sp, #0x10
	movs	r0, #0
	str	r0, [sp, #0x8]
	str	r0, [sp, #0x4]
	movw	r0, #0x61e4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbnz	r0, .L08042c3e
	b.n	.L08042c28
.L08042c28:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L08042c3c
.L08042c3c:
	b.n	.L08042c3c
.L08042c3e:
	bl	enter_critical
	movw	r0, #0x61e4
	movt	r0, #0x2000
	ldr	r1, [r0, #0x0]
	subs	r1, #1
	str	r1, [r0, #0x0]
	ldr	r0, [r0, #0x0]
	cmp	r0, #0
	bne.w	.L08042d7c
	b.n	.L08042c5a
.L08042c5a:
	movw	r0, #0x6254
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cmp	r0, #0
	beq.w	.L08042d7a
	b.n	.L08042c6c
.L08042c6c:
	b.n	.L08042c6e
.L08042c6e:
	movw	r0, #0x6288
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbz	r0, .L08042cf4
	b.n	.L08042c7c
.L08042c7c:
	movw	r0, #0x6288
	movt	r0, #0x2000
	ldr	r0, [r0, #0xc]
	ldr	r0, [r0, #0xc]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	adds	r0, #0x18
	bl	list_unlink_node
	ldr	r0, [sp, #0x8]
	adds	r0, #4
	bl	list_unlink_node
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1, #0x0]
	orrs	r0, r2
	str	r0, [r1, #0x0]
	ldr	r1, [sp, #0x8]
	ldr	r0, [r1, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r2, #0x61f0
	movt	r2, #0x2000
	add.w	r0, r2, r0, lsl #2
	adds	r1, #4
	bl	list_insert_before_cursor
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x2c]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1, #0x0]
	ldr	r1, [r1, #0x2c]
	cmp	r0, r1
	bcc.n	.L08042cf0
	b.n	.L08042ce2
.L08042ce2:
	movw	r0, #0x61e8
	movt	r0, #0x2000
	movs	r1, #1
	str	r1, [r0, #0x0]
	b.n	.L08042cf2
.L08042cf0:
	b.n	.L08042cf2
.L08042cf2:
	b.n	.L08042c6e
.L08042cf4:
	ldr	r0, [sp, #0x8]
	cbz	r0, .L08042d00
	b.n	.L08042cfa
.L08042cfa:
	bl	update_next_unblock_time
	b.n	.L08042d00
.L08042d00:
	movw	r0, #0x62d8
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0x0]
	cbz	r0, .L08042d4a
	b.n	.L08042d12
.L08042d12:
	b.n	.L08042d14
.L08042d14:
	bl	fn_0804277c
	cbz	r0, .L08042d2a
	b.n	.L08042d1c
.L08042d1c:
	movw	r0, #0x61e8
	movt	r0, #0x2000
	movs	r1, #1
	str	r1, [r0, #0x0]
	b.n	.L08042d2c
.L08042d2a:
	b.n	.L08042d2c
.L08042d2c:
	ldr	r0, [sp, #0x0]
	subs	r0, #1
	str	r0, [sp, #0x0]
	b.n	.L08042d34
.L08042d34:
	ldr	r0, [sp, #0x0]
	cmp	r0, #0
	bne.n	.L08042d14
	b.n	.L08042d3c
.L08042d3c:
	movw	r0, #0x62d8
	movt	r0, #0x2000
	movs	r1, #0
	str	r1, [r0, #0x0]
	b.n	.L08042d4c
.L08042d4a:
	b.n	.L08042d4c
.L08042d4c:
	movw	r0, #0x61e8
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbz	r0, .L08042d76
	b.n	.L08042d5a
.L08042d5a:
	movs	r0, #1
	str	r0, [sp, #0x4]
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0, #0x0]
	dsb	sy
	isb	sy
	b.n	.L08042d78
.L08042d76:
	b.n	.L08042d78
.L08042d78:
	b.n	.L08042d7a
.L08042d7a:
	b.n	.L08042d7e
.L08042d7c:
	b.n	.L08042d7e
.L08042d7e:
	bl	exit_critical
	ldr	r0, [sp, #0x4]
	add	sp, #0x10
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08042d88 - allocates a 0x28-byte block and initialises it with
@ timer_init_record.
@ Params: r0, r1, r2. Allocates 0x28 bytes with heap_alloc_first_fit
@ (0803cc64); if nonzero sets byte +0x24 = 0 and calls timer_init_record
@ (0803c058)(r0, r1, 1, 0, r2, block).
@ Returns the block pointer (or 0).
@ ----------------------------------------------------------------------------
	.section .text.fn_08042d88,"ax",%progbits
	.global fn_08042d88
	.thumb_func
	.type fn_08042d88, %function
fn_08042d88:
	push	{r7, lr}
	sub	sp, #0x20
	str	r0, [sp, #0x1c]
	str	r1, [sp, #0x18]
	movs	r0, #1
	str	r0, [sp, #0x14]
	movs	r0, #0
	str	r0, [sp, #0x10]
	str	r2, [sp, #0xc]
	movs	r0, #0x28
	bl	heap_alloc_first_fit
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	cbz	r0, .L08042dce
	b.n	.L08042da8
.L08042da8:
	ldr	r0, [sp, #0x8]
	movs	r1, #0
	strb.w	r1, [r0, #0x24]
	ldr	r0, [sp, #0x1c]
	ldr	r1, [sp, #0x18]
	ldr	r2, [sp, #0x14]
	ldr	r3, [sp, #0x10]
	ldr.w	r12, [sp, #0xc]
	ldr.w	lr, [sp, #0x8]
	str.w	lr, [sp, #0x4]
	str.w	r12, [sp, #0x0]
	bl	timer_init_record
	b.n	.L08042dce
.L08042dce:
	ldr	r0, [sp, #0x8]
	add	sp, #0x20
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ create_tmr_svc_record_or_halt - creates the task named "Tmr Svc".
@ No params. Calls timer_service_init (0803bbc0); when word 0x200062e4 != 0
@ calls fn_080426a0(0x0803c79d (Thumb entry of 0803c79c, timer_service_task),
@ the string "Tmr Svc" at 0x080bc038, 0x80, 10, 0x200062e8).
@ Returns that result when nonzero (1); when it is 0 (or 0x200062e4 == 0) it
@ raises BASEPRI to 0x10 (msr unconditional), ISB, DSB and loops forever.
@ ----------------------------------------------------------------------------
	.section .text.create_tmr_svc_record_or_halt,"ax",%progbits
	.global create_tmr_svc_record_or_halt
	.thumb_func
	.type create_tmr_svc_record_or_halt, %function
create_tmr_svc_record_or_halt:
	push	{r7, lr}
	sub	sp, #0x10
	movs	r0, #0
	str	r0, [sp, #0x8]
	bl	timer_service_init
	movw	r0, #0x62e4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbz	r0, .L08042e14
	b.n	.L08042dee
.L08042dee:
	movw	r0, #0x62e8
	movt	r0, #0x2000
	str	r0, [sp, #0x0]
	movw	r0, #:lower16:timer_service_task
	movt	r0, #:upper16:timer_service_task
	movw	r1, #:lower16:t_080bc038
	movt	r1, #:upper16:t_080bc038
	movs	r2, #0x80
	movs	r3, #0xa
	bl	fn_080426a0
	str	r0, [sp, #0x8]
	b.n	.L08042e16
.L08042e14:
	b.n	.L08042e16
.L08042e16:
	ldr	r0, [sp, #0x8]
	cbnz	r0, .L08042e32
	b.n	.L08042e1c
.L08042e1c:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L08042e30
.L08042e30:
	b.n	.L08042e30
.L08042e32:
	ldr	r0, [sp, #0x8]
	add	sp, #0x10
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08042e38 - posts a command message to the queue whose handle is at
@ 0x200062e4 (the queue read by the task created in
@ create_tmr_svc_record_or_halt).
@ Params: r0 = item, r1 = code, r2 = argument. Loops forever (BASEPRI 0x10) if
@ r0 == 0. If word 0x200062e4 (queue handle) != 0 it builds the 3-word message
@ {code, argument, item} on the stack; if code < 6 (signed compare) it calls
@ queue_send_timeout (08041cf0)(*0x200062e4, &msg, 0) (timeout 0;
@ fn_08042730() == 2 selects the same timeout 0), else queue_send_from_isr
@ (08041f08)(*0x200062e4, &msg, 0).
@ Returns the called function's result, 0 when the queue handle is 0.
@ ----------------------------------------------------------------------------
	.section .text.fn_08042e38,"ax",%progbits
	.global fn_08042e38
	.thumb_func
	.type fn_08042e38, %function
fn_08042e38:
	push	{r7, lr}
	sub	sp, #0x28
	str	r0, [sp, #0x20]
	str	r1, [sp, #0x1c]
	str	r2, [sp, #0x18]
	movs	r0, #0
	str	r0, [sp, #0x14]
	str	r0, [sp, #0x10]
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0x20]
	cbnz	r0, .L08042e66
	b.n	.L08042e50
.L08042e50:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x24]
	b.n	.L08042e64
.L08042e64:
	b.n	.L08042e64
.L08042e66:
	movw	r0, #0x62e4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	cbz	r0, .L08042ed8
	b.n	.L08042e74
.L08042e74:
	ldr	r0, [sp, #0x1c]
	str	r0, [sp, #0x0]
	ldr	r0, [sp, #0x18]
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x20]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x1c]
	cmp	r0, #5
	bgt.n	.L08042ec0
	b.n	.L08042e88
.L08042e88:
	bl	fn_08042730
	cmp	r0, #2
	bne.n	.L08042ea8
	b.n	.L08042e92
.L08042e92:
	movw	r0, #0x62e4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r2, [sp, #0x10]
	mov	r1, sp
	bl	queue_send_timeout
	str	r0, [sp, #0xc]
	b.n	.L08042ebe
.L08042ea8:
	movw	r0, #0x62e4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	mov	r1, sp
	movs	r2, #0
	bl	queue_send_timeout
	str	r0, [sp, #0xc]
	b.n	.L08042ebe
.L08042ebe:
	b.n	.L08042ed6
.L08042ec0:
	movw	r0, #0x62e4
	movt	r0, #0x2000
	ldr	r0, [r0, #0x0]
	ldr	r2, [sp, #0x14]
	mov	r1, sp
	bl	queue_send_from_isr
	str	r0, [sp, #0xc]
	b.n	.L08042ed6
.L08042ed6:
	b.n	.L08042eda
.L08042ed8:
	b.n	.L08042eda
.L08042eda:
	ldr	r0, [sp, #0xc]
	add	sp, #0x28
	pop	{r7, pc}
