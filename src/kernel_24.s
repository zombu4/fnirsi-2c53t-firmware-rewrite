@ kernel_24.s - kernel: IRQ priority check, queue/list helpers, task-delay wrappers (0x080412c8..)
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ check_irq_priority_limits - No params. n = IPSR (mrs r0,IPSR, unconditional,
@ no mask instruction). If n > 0xf and the byte at 0xE000E3F0+n (interrupt
@ priority byte of the active exception) is below the byte at 0x200022c0, it
@ raises BASEPRI to 0x10 (msr unconditional), ISB, DSB and loops forever.
@ Then if (word 0xE000ED0C & 0x700) (AIRCR priority grouping field) is greater
@ than the word at 0x200022c4 it does the same. Otherwise it returns with no
@ value.
@ ----------------------------------------------------------------------------
	.section .text.check_irq_priority_limits,"ax",%progbits
	.global check_irq_priority_limits
	.thumb_func
	.type check_irq_priority_limits, %function
check_irq_priority_limits:
	mrs	r0, ipsr
	cmp	r0, #0x10
	bcc.n	.L080412fa
	movw	r1, #0xe3f0
	movt	r1, #0xe000
	ldrb	r0, [r0, r1]
	movw	r1, #0x22c0
	movt	r1, #0x2000
	ldrb	r1, [r1]
	cmp	r0, r1
	bcs.n	.L080412fa
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
.L080412f8:
	b.n	.L080412f8
.L080412fa:
	movw	r0, #0xed0c
	movt	r0, #0xe000
	movw	r1, #0x22c4
	ldr	r0, [r0]
	movt	r1, #0x2000
	ldr	r1, [r1]
	and.w	r0, r0, #0x700
	cmp	r0, r1
	it	ls
	bxls	lr
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
.L08041328:
	b.n	.L08041328
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0804132c - Params r0=record, r1, r2. Calls enter_critical (08041168); if
@ the bytes record+0x44 or record+0x45 equal 0xff (signed -1) it sets them to
@ 0; calls exit_critical (080411b0); if word record+0x38 == 0 it calls
@ fn_08041478 (08041478) with (record+0x24, r1, r2); then calls queue_unlock
@ (0803c7b8) with the record.
@ ----------------------------------------------------------------------------
	.section .text.fn_0804132c,"ax",%progbits
	.global fn_0804132c
	.thumb_func
	.type fn_0804132c, %function
fn_0804132c:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0xc]
	str	r1, [sp, #0x8]
	str	r2, [sp, #0x4]
	ldr	r0, [sp, #0xc]
	str	r0, [sp]
	bl	enter_critical
	ldr	r0, [sp]
	ldrsb.w	r0, [r0, #0x44]
	adds	r0, #1
	cbnz	r0, .L08041354
	b.n	.L0804134a
.L0804134a:
	ldr	r0, [sp]
	movs	r1, #0
	strb.w	r1, [r0, #0x44]
	b.n	.L08041354
.L08041354:
	ldr	r0, [sp]
	ldrsb.w	r0, [r0, #0x45]
	adds	r0, #1
	cbnz	r0, .L0804136a
	b.n	.L08041360
.L08041360:
	ldr	r0, [sp]
	movs	r1, #0
	strb.w	r1, [r0, #0x45]
	b.n	.L0804136a
.L0804136a:
	bl	exit_critical
	ldr	r0, [sp]
	ldr	r0, [r0, #0x38]
	cbnz	r0, .L08041384
	b.n	.L08041376
.L08041376:
	ldr	r0, [sp]
	adds	r0, #0x24
	ldr	r1, [sp, #0x8]
	ldr	r2, [sp, #0x4]
	bl	fn_08041478
	b.n	.L08041386
.L08041384:
	b.n	.L08041386
.L08041386:
	ldr	r0, [sp]
	bl	queue_unlock
	add	sp, #0x10
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08041390 - Param r0=value. Local result = 0. If r0 != 0: if the word at
@ 0x200061e4 != 0 it raises BASEPRI to 0x10 and loops forever; else it calls
@ increment_word_200061e4 (08041904), task_delay_current (0803b9b8) with
@ (r0, 0) and stores the return value of fn_08042c10 (08042c10) as result. If
@ the result is 0 (including r0 == 0) it writes 0x10000000 to 0xE000ED04 (set
@ bit 28: pending-PendSV request) followed by DSB and ISB. No return value.
@ ----------------------------------------------------------------------------
	.section .text.fn_08041390,"ax",%progbits
	.global fn_08041390
	.thumb_func
	.type fn_08041390, %function
fn_08041390:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0x8]
	movs	r0, #0
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x8]
	cbz	r0, .L080413d8
	b.n	.L080413a0
.L080413a0:
	movw	r0, #0x61e4
	movt	r0, #0x2000
	ldr	r0, [r0]
	cbz	r0, .L080413c4
	b.n	.L080413ae
.L080413ae:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L080413c2
.L080413c2:
	b.n	.L080413c2
.L080413c4:
	bl	increment_word_200061e4
	ldr	r0, [sp, #0x8]
	movs	r1, #0
	bl	task_delay_current
	bl	fn_08042c10
	str	r0, [sp, #0x4]
	b.n	.L080413da
.L080413d8:
	b.n	.L080413da
.L080413da:
	ldr	r0, [sp, #0x4]
	cbnz	r0, .L080413f8
	b.n	.L080413e0
.L080413e0:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0]
	dsb	sy
	isb	sy
	b.n	.L080413fa
.L080413f8:
	b.n	.L080413fa
.L080413fa:
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_08041400 - Param r0=pointer to two words. Stores the word read from
@ 0x200062dc into r0[0] and the word read from 0x200062d4 into r0[1].
@ ----------------------------------------------------------------------------
	.section .text.fn_08041400,"ax",%progbits
	.global fn_08041400
	.thumb_func
	.type fn_08041400, %function
fn_08041400:
	sub	sp, #0x4
	str	r0, [sp]
	movw	r0, #0x62dc
	movt	r0, #0x2000
	ldr	r0, [r0]
	ldr	r1, [sp]
	str	r0, [r1]
	movw	r0, #0x62d4
	movt	r0, #0x2000
	ldr	r0, [r0]
	ldr	r1, [sp]
	str	r0, [r1, #0x4]
	add	sp, #0x4
	bx	lr

@ ----------------------------------------------------------------------------
@ set_flag_200061e8 - No params. Writes 1 to the word at 0x200061e8.
@ ----------------------------------------------------------------------------
	.section .text.set_flag_200061e8,"ax",%progbits
	.global set_flag_200061e8
	.thumb_func
	.type set_flag_200061e8, %function
set_flag_200061e8:
	movw	r0, #0x61e8
	movt	r0, #0x2000
	movs	r1, #1
	str	r1, [r0]
	bx	lr
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_08041434 - Params r0=list header, r1=value. If r0 != 0: calls
@ list_insert_sorted (080410ac) with (r0, *0x200061e0 + 0x18), then
@ task_delay_current (0803b9b8) with (r1, 1). If r0 == 0 it raises BASEPRI to
@ 0x10 (msr unconditional), ISB, DSB and loops forever.
@ ----------------------------------------------------------------------------
	.section .text.fn_08041434,"ax",%progbits
	.global fn_08041434
	.thumb_func
	.type fn_08041434, %function
fn_08041434:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0x8]
	str	r1, [sp, #0x4]
	ldr	r0, [sp, #0x8]
	cbnz	r0, .L08041458
	b.n	.L08041442
.L08041442:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L08041456
.L08041456:
	b.n	.L08041456
.L08041458:
	ldr	r0, [sp, #0x8]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1]
	adds	r1, #0x18
	bl	list_insert_sorted
	ldr	r0, [sp, #0x4]
	movs	r1, #1
	bl	task_delay_current
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_08041478 - Params r0=list header, r1=value, r2=flag. If r0 != 0: calls
@ list_insert_before_cursor (08041118) with (r0, *0x200061e0 + 0x18), then
@ task_delay_current (0803b9b8) with (flag != 0 ? 0xffffffff : r1, flag). If
@ r0 == 0 it raises BASEPRI to 0x10 and loops forever.
@ ----------------------------------------------------------------------------
	.section .text.fn_08041478,"ax",%progbits
	.global fn_08041478
	.thumb_func
	.type fn_08041478, %function
fn_08041478:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0x8]
	str	r1, [sp, #0x4]
	str	r2, [sp]
	ldr	r0, [sp, #0x8]
	cbnz	r0, .L0804149e
	b.n	.L08041488
.L08041488:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L0804149c
.L0804149c:
	b.n	.L0804149c
.L0804149e:
	ldr	r0, [sp, #0x8]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1]
	adds	r1, #0x18
	bl	list_insert_before_cursor
	ldr	r0, [sp]
	cbz	r0, .L080414be
	b.n	.L080414b6
.L080414b6:
	mov.w	r0, #0xffffffff
	str	r0, [sp, #0x4]
	b.n	.L080414be
.L080414be:
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp]
	bl	task_delay_current
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_080414cc - Params r0=record pointer, r1=value p. If r0 == 0 it returns.
@ Loops forever (BASEPRI 0x10) if r0[0x12] (word +0x48) == 0. n = max(r0[0x11]
@ (+0x44), p). If n != r0[0xb] (+0x2c) and +0x48 == 1: loops forever if r0 ==
@ word *0x200061e0; else old = +0x2c, stores n at +0x2c, and when bit 7 of
@ byte +0x1b is clear stores 5-n at +0x18. If word +0x14 equals
@ 0x200061f0+old*20 it calls list_unlink_node (08041024) with r0+4; when that
@ returns 0 it clears bit n (the NEW value, read back from +0x2c at
@ 0x080415aa; the bit of old is not cleared here) in 0x200061ec; then sets bit
@ n in 0x200061ec and calls list_insert_before_cursor (08041118) with
@ (0x200061f0+n*20, r0+4). No return value.
@ ----------------------------------------------------------------------------
	.section .text.fn_080414cc,"ax",%progbits
	.global fn_080414cc
	.thumb_func
	.type fn_080414cc, %function
fn_080414cc:
	push	{r7, lr}
	sub	sp, #0x20
	str	r0, [sp, #0x14]
	str	r1, [sp, #0x10]
	ldr	r0, [sp, #0x14]
	str	r0, [sp, #0xc]
	movs	r0, #1
	str	r0, [sp]
	ldr	r0, [sp, #0x14]
	cmp	r0, #0
	beq.w	.L08041608
	b.n	.L080414e6
.L080414e6:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x48]
	cbnz	r0, .L08041504
	b.n	.L080414ee
.L080414ee:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x18]
	b.n	.L08041502
.L08041502:
	b.n	.L08041502
.L08041504:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x44]
	ldr	r1, [sp, #0x10]
	cmp	r0, r1
	bcs.n	.L08041516
	b.n	.L08041510
.L08041510:
	ldr	r0, [sp, #0x10]
	str	r0, [sp, #0x4]
	b.n	.L0804151e
.L08041516:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x44]
	str	r0, [sp, #0x4]
	b.n	.L0804151e
.L0804151e:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x2c]
	ldr	r1, [sp, #0x4]
	cmp	r0, r1
	beq.n	.L08041604
	b.n	.L0804152a
.L0804152a:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x48]
	cmp	r0, #1
	bne.n	.L08041600
	b.n	.L08041534
.L08041534:
	ldr	r0, [sp, #0xc]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1]
	cmp	r0, r1
	bne.n	.L0804155c
	b.n	.L08041546
.L08041546:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x1c]
	b.n	.L0804155a
.L0804155a:
	b.n	.L0804155a
.L0804155c:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x2c]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp, #0xc]
	str	r0, [r1, #0x2c]
	ldr	r0, [sp, #0xc]
	ldrb	r0, [r0, #0x1b]
	lsls	r0, r0, #24
	cmp	r0, #0
	bmi.n	.L08041580
	b.n	.L08041574
.L08041574:
	ldr	r0, [sp, #0x4]
	rsb.w	r0, r0, #5
	ldr	r1, [sp, #0xc]
	str	r0, [r1, #0x18]
	b.n	.L08041582
.L08041580:
	b.n	.L08041582
.L08041582:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x14]
	ldr	r1, [sp, #0x8]
	add.w	r1, r1, r1, lsl #2
	movw	r2, #0x61f0
	movt	r2, #0x2000
	add.w	r1, r2, r1, lsl #2
	cmp	r0, r1
	bne.n	.L080415fc
	b.n	.L0804159e
.L0804159e:
	ldr	r0, [sp, #0xc]
	adds	r0, #4
	bl	list_unlink_node
	cbnz	r0, .L080415c6
	b.n	.L080415aa
.L080415aa:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1]
	bic.w	r0, r2, r0
	str	r0, [r1]
	b.n	.L080415c8
.L080415c6:
	b.n	.L080415c8
.L080415c8:
	ldr	r0, [sp, #0xc]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1]
	orrs	r0, r2
	str	r0, [r1]
	ldr	r1, [sp, #0xc]
	ldr	r0, [r1, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r2, #0x61f0
	movt	r2, #0x2000
	add.w	r0, r2, r0, lsl #2
	adds	r1, #4
	bl	list_insert_before_cursor
	b.n	.L080415fe
.L080415fc:
	b.n	.L080415fe
.L080415fe:
	b.n	.L08041602
.L08041600:
	b.n	.L08041602
.L08041602:
	b.n	.L08041606
.L08041604:
	b.n	.L08041606
.L08041606:
	b.n	.L0804160a
.L08041608:
	b.n	.L0804160a
.L0804160a:
	add	sp, #0x20
	pop	{r7, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_08041610 - Param r0=record pointer. Loops forever (BASEPRI 0x10) if r0 ==
@ 0. If r0 differs from *0x200061e0: calls enter_critical (08041168); if
@ task_is_suspended (0803c730)(r0) != 0 it unlinks r0+4 with list_unlink_node
@ (08041024), sets bit r0[0x2c] in 0x200061ec, inserts with
@ list_insert_before_cursor (08041118)(0x200061f0+r0[0x2c]*20, r0+4) and, if
@ *(0x200061e0)[0x2c] <= r0[0x2c], writes 0x10000000 to 0xE000ED04 with
@ DSB/ISB; then calls exit_critical (080411b0).
@ ----------------------------------------------------------------------------
	.section .text.fn_08041610,"ax",%progbits
	.global fn_08041610
	.thumb_func
	.type fn_08041610, %function
fn_08041610:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x8]
	cbnz	r0, .L08041636
	b.n	.L08041620
.L08041620:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L08041634
.L08041634:
	b.n	.L08041634
.L08041636:
	ldr	r0, [sp, #0x4]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1]
	cmp	r0, r1
	beq.n	.L080416d2
	b.n	.L08041648
.L08041648:
	ldr	r0, [sp, #0x4]
	cmp	r0, #0
	beq.n	.L080416d2
	b.n	.L08041650
.L08041650:
	bl	enter_critical
	ldr	r0, [sp, #0x4]
	bl	task_is_suspended
	cbz	r0, .L080416ca
	b.n	.L0804165e
.L0804165e:
	ldr	r0, [sp, #0x4]
	adds	r0, #4
	bl	list_unlink_node
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1]
	orrs	r0, r2
	str	r0, [r1]
	ldr	r1, [sp, #0x4]
	ldr	r0, [r1, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r2, #0x61f0
	movt	r2, #0x2000
	add.w	r0, r2, r0, lsl #2
	adds	r1, #4
	bl	list_insert_before_cursor
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x2c]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1]
	ldr	r1, [r1, #0x2c]
	cmp	r0, r1
	bcc.n	.L080416c6
	b.n	.L080416ae
.L080416ae:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0]
	dsb	sy
	isb	sy
	b.n	.L080416c8
.L080416c6:
	b.n	.L080416c8
.L080416c8:
	b.n	.L080416cc
.L080416ca:
	b.n	.L080416cc
.L080416cc:
	bl	exit_critical
	b.n	.L080416d4
.L080416d2:
	b.n	.L080416d4
.L080416d4:
	add	sp, #0x10
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ create_idle_and_tmr_svc_tasks - No parameters; entered by tail jump from the
@ function ending at 0x0802e6ca (b.w at 0x0802e6ca only), which has restored
@ its saved registers, so lr is that function's caller. Creates the task
@ 'IDLE' and then calls create_tmr_svc_record_or_halt (08042dd4). On success
@ it ends in fn_080419d4 (080419d4), which does not return; returns r0 = word
@ at 0x0804be70 (value 4) only when task creation returns neither 1 nor -1.
@ Code: push {r7,lr}, sub sp,#16; calls fn_080426a0 (080426a0) with
@ r0 = 0x0803becd (Thumb entry of idle_task_loop 0803becc), r1 = 'IDLE'
@ (0x080bbc32), r2 = 0x80, r3 = 0 and the 5th argument &0x200062e0 on the
@ stack. If the result is 1 it calls 08042dd4, which creates the task named
@ 'Tmr Svc' (name at 0x080bc038, r3 = 10, &0x200062e8) only when word
@ 0x200062e4 is nonzero and otherwise returns 0 and halts (0x08042dea,
@ 0x08042e16..0x08042e30). If the result is then 1: msr BASEPRI = 0x10, isb,
@ dsb, stores 0xffffffff at 0x200062d0, 1 at 0x20006258, 0 at 0x200062d4, and
@ calls 080419d4 (documented there as not returning). If the result is -1:
@ msr BASEPRI = 0x10, isb, dsb and an endless b.n 0x08041778 loop. Otherwise
@ it loads the word at 0x0804be70 and pops {r7,pc}. The msr at 0x0804171e and
@ 0x08041768 are unconditional.
@ ----------------------------------------------------------------------------
	.section .text.create_idle_and_tmr_svc_tasks,"ax",%progbits
	.global create_idle_and_tmr_svc_tasks
	.thumb_func
	.type create_idle_and_tmr_svc_tasks, %function
create_idle_and_tmr_svc_tasks:
	push	{r7, lr}
	sub	sp, #0x10
	movw	r0, #0x62e0
	movt	r0, #0x2000
	str	r0, [sp]
	movw	r0, #:lower16:idle_task_loop
	movt	r0, #:upper16:idle_task_loop
	movw	r1, #:lower16:d_080bbc32
	movt	r1, #:upper16:d_080bbc32
	movs	r2, #0x80
	movs	r3, #0
	bl	fn_080426a0
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	cmp	r0, #1
	bne.n	.L08041710
	b.n	.L08041708
.L08041708:
	bl	create_tmr_svc_record_or_halt
	str	r0, [sp, #0x4]
	b.n	.L08041712
.L08041710:
	b.n	.L08041712
.L08041712:
	ldr	r0, [sp, #0x4]
	cmp	r0, #1
	bne.n	.L0804175c
	b.n	.L0804171a
.L0804171a:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x8]
	movw	r0, #0x62d0
	movt	r0, #0x2000
	mov.w	r1, #0xffffffff
	str	r1, [r0]
	movw	r0, #0x6258
	movt	r0, #0x2000
	movs	r1, #1
	str	r1, [r0]
	movw	r0, #0x62d4
	movt	r0, #0x2000
	movs	r1, #0
	str	r1, [r0]
	bl	fn_080419d4
	b.n	.L08041758
.L08041758:
	b.n	.L0804175a
.L0804175a:
	b.n	.L0804177c
.L0804175c:
	ldr	r0, [sp, #0x4]
	adds	r0, #1
	cbnz	r0, .L0804177a
	b.n	.L08041764
.L08041764:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L08041778
.L08041778:
	b.n	.L08041778
.L0804177a:
	b.n	.L0804177c
.L0804177c:
	movw	r0, #:lower16:d_0804be70
	movt	r0, #:upper16:d_0804be70
	ldr	r0, [r0]
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0804178c - Param r0=record pointer (0 means the record in word
@ 0x200061e0). Calls enter_critical (08041168); unlinks r0+4 with
@ list_unlink_node (08041024) and, when that returns 0 and the list head word
@ 0x200061f0+r0[0x2c]*20 is 0, clears bit r0[0x2c] of 0x200061ec; if r0[0x28]
@ != 0 unlinks r0+0x18; inserts r0+4 into the list at 0x200062b0 with
@ list_insert_before_cursor (08041118); clears byte r0+0x50 when it is 1;
@ calls exit_critical (080411b0); if word 0x20006258 != 0 calls
@ enter_critical, update_next_unblock_time (0803c5a0), exit_critical. If r0
@ equals the record in 0x200061e0: when 0x20006258 == 0 it either stores 0 in
@ 0x200061e0 (if word 0x200062b0 == word 0x20006254) or calls fn_08041914
@ (08041914); when 0x20006258 != 0 it loops forever (BASEPRI 0x10) if
@ 0x200061e4 != 0, else writes 0x10000000 to 0xE000ED04 with DSB/ISB. No
@ return value.
@ ----------------------------------------------------------------------------
	.section .text.fn_0804178c,"ax",%progbits
	.global fn_0804178c
	.thumb_func
	.type fn_0804178c, %function
fn_0804178c:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0x8]
	bl	enter_critical
	ldr	r0, [sp, #0x8]
	cbnz	r0, .L080417a8
	b.n	.L0804179c
.L0804179c:
	movw	r0, #0x61e0
	movt	r0, #0x2000
	ldr	r0, [r0]
	b.n	.L080417ac
.L080417a8:
	ldr	r0, [sp, #0x8]
	b.n	.L080417ac
.L080417ac:
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	adds	r0, #4
	bl	list_unlink_node
	cbnz	r0, .L080417f0
	b.n	.L080417ba
.L080417ba:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x2c]
	add.w	r0, r0, r0, lsl #2
	movw	r1, #0x61f0
	movt	r1, #0x2000
	ldr.w	r0, [r1, r0, lsl #2]
	cbnz	r0, .L080417ee
	b.n	.L080417d2
.L080417d2:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x2c]
	movs	r1, #1
	lsl.w	r0, r1, r0
	movw	r1, #0x61ec
	movt	r1, #0x2000
	ldr	r2, [r1]
	bic.w	r0, r2, r0
	str	r0, [r1]
	b.n	.L080417ee
.L080417ee:
	b.n	.L080417f2
.L080417f0:
	b.n	.L080417f2
.L080417f2:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x28]
	cbz	r0, .L08041804
	b.n	.L080417fa
.L080417fa:
	ldr	r0, [sp, #0x4]
	adds	r0, #0x18
	bl	list_unlink_node
	b.n	.L08041806
.L08041804:
	b.n	.L08041806
.L08041806:
	ldr	r0, [sp, #0x4]
	adds	r1, r0, #4
	movw	r0, #0x62b0
	movt	r0, #0x2000
	bl	list_insert_before_cursor
	movs	r0, #0
	str	r0, [sp]
	b.n	.L0804181c
.L0804181c:
	ldr	r0, [sp]
	cmp	r0, #0
	bgt.n	.L0804184c
	b.n	.L08041824
.L08041824:
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp]
	add	r0, r1
	ldrb.w	r0, [r0, #0x50]
	cmp	r0, #1
	bne.n	.L08041842
	b.n	.L08041834
.L08041834:
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp]
	add	r0, r1
	movs	r1, #0
	strb.w	r1, [r0, #0x50]
	b.n	.L08041842
.L08041842:
	b.n	.L08041844
.L08041844:
	ldr	r0, [sp]
	adds	r0, #1
	str	r0, [sp]
	b.n	.L0804181c
.L0804184c:
	bl	exit_critical
	movw	r0, #0x6258
	movt	r0, #0x2000
	ldr	r0, [r0]
	cbz	r0, .L0804186c
	b.n	.L0804185e
.L0804185e:
	bl	enter_critical
	bl	update_next_unblock_time
	bl	exit_critical
	b.n	.L0804186e
.L0804186c:
	b.n	.L0804186e
.L0804186e:
	ldr	r0, [sp, #0x4]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	ldr	r1, [r1]
	cmp	r0, r1
	bne.n	.L080418fc
	b.n	.L08041880
.L08041880:
	movw	r0, #0x6258
	movt	r0, #0x2000
	ldr	r0, [r0]
	cbz	r0, .L080418ca
	b.n	.L0804188e
.L0804188e:
	movw	r0, #0x61e4
	movt	r0, #0x2000
	ldr	r0, [r0]
	cbz	r0, .L080418b2
	b.n	.L0804189c
.L0804189c:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L080418b0
.L080418b0:
	b.n	.L080418b0
.L080418b2:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0]
	dsb	sy
	isb	sy
	b.n	.L080418fa
.L080418ca:
	movw	r0, #0x62b0
	movt	r0, #0x2000
	ldr	r0, [r0]
	movw	r1, #0x6254
	movt	r1, #0x2000
	ldr	r1, [r1]
	cmp	r0, r1
	bne.n	.L080418f2
	b.n	.L080418e4
.L080418e4:
	movw	r0, #0x61e0
	movt	r0, #0x2000
	movs	r1, #0
	str	r1, [r0]
	b.n	.L080418f8
.L080418f2:
	bl	fn_08041914
	b.n	.L080418f8
.L080418f8:
	b.n	.L080418fa
.L080418fa:
	b.n	.L080418fe
.L080418fc:
	b.n	.L080418fe
.L080418fe:
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ increment_word_200061e4 - No params. Increments the word at 0x200061e4.
@ ----------------------------------------------------------------------------
	.section .text.increment_word_200061e4,"ax",%progbits
	.global increment_word_200061e4
	.thumb_func
	.type increment_word_200061e4, %function
increment_word_200061e4:
	movw	r0, #0x61e4
	movt	r0, #0x2000
	ldr	r1, [r0]
	adds	r1, #1
	str	r1, [r0]
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08041914 - No params. If 0x200061e4 == 0: clears 0x200061e8; takes the
@ highest set bit index n = 31-clz(0x200061ec); loops forever (BASEPRI 0x10)
@ if list head 0x200061f0+n*20 has count 0; otherwise advances that list's
@ cursor (word at 0x200061f4+n*20) to the next entry (skipping the sentinel at
@ +8) and sets 0x200061e0 to the entry's word at +0xc. If 0x200061e4 != 0 sets
@ 0x200061e8 = 1.
@ ----------------------------------------------------------------------------
	.section .text.fn_08041914,"ax",%progbits
	.global fn_08041914
	.thumb_func
	.type fn_08041914, %function
fn_08041914:
	sub	sp, #0x14
	movw	r0, #0x61e4
	movt	r0, #0x2000
	ldr	r0, [r0]
	cbz	r0, .L08041932
	b.n	.L08041924
.L08041924:
	movw	r0, #0x61e8
	movt	r0, #0x2000
	movs	r1, #1
	str	r1, [r0]
	b.n	.L080419ce
.L08041932:
	movw	r0, #0x61e8
	movt	r0, #0x2000
	movs	r1, #0
	str	r1, [r0]
	movw	r0, #0x61ec
	movt	r0, #0x2000
	ldr	r0, [r0]
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0xc]
	clz	r0, r0
	strb.w	r0, [sp, #0xb]
	ldrb.w	r0, [sp, #0xb]
	rsb.w	r0, r0, #0x1f
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	add.w	r0, r0, r0, lsl #2
	movw	r1, #0x61f0
	movt	r1, #0x2000
	ldr.w	r0, [r1, r0, lsl #2]
	cbnz	r0, .L0804198a
	b.n	.L08041974
.L08041974:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x10]
	b.n	.L08041988
.L08041988:
	b.n	.L08041988
.L0804198a:
	ldr	r0, [sp, #0x4]
	add.w	r0, r0, r0, lsl #2
	movw	r1, #0x61f0
	movt	r1, #0x2000
	add.w	r0, r1, r0, lsl #2
	str	r0, [sp]
	ldr	r0, [sp]
	ldr	r1, [r0, #0x4]
	ldr	r1, [r1, #0x4]
	str	r1, [r0, #0x4]
	ldr	r0, [sp]
	ldr	r1, [r0, #0x4]
	adds	r0, #8
	cmp	r1, r0
	bne.n	.L080419bc
	b.n	.L080419b2
.L080419b2:
	ldr	r0, [sp]
	ldr	r1, [r0, #0x4]
	ldr	r1, [r1, #0x4]
	str	r1, [r0, #0x4]
	b.n	.L080419bc
.L080419bc:
	ldr	r0, [sp]
	ldr	r0, [r0, #0x4]
	ldr	r0, [r0, #0xc]
	movw	r1, #0x61e0
	movt	r1, #0x2000
	str	r0, [r1]
	b.n	.L080419ce
.L080419ce:
	add	sp, #0x14
	bx	lr
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_080419d4 - No params; does not return. Loops forever (BASEPRI 0x10) if
@ word 0xE000ED00 equals 0x410fc271 or 0x410fc270. Saves byte 0xE000E400,
@ writes 0xff there and reads it back (b): stores b & 0x10 in 0x200022c0;
@ counts the implemented priority bits of b (shift loop at
@ 0x08041a8c..0x08041ab2); if bit 7 of b is clear or the count is not 3 it
@ raises BASEPRI to 0x10 and loops forever. With count 3: stores 0x300 in
@ 0x200022c4, restores byte 0xE000E400, ORs 0x00f00000 and then 0xf0000000
@ into 0xE000ED20 (system handler priority word), SysTick: 0xE000E010 = 0,
@ 0xE000E018 = 0, 0xE000E014 = 239999 (0x0003a97f), 0xE000E010 = 7; stores 0
@ in 0x20000000; calls enable_fpu_access (08041154); ORs 0xc0000000 into
@ 0xE000EF34; calls reset_msp_and_call_svc0 (0803c304) and fn_08041914
@ (08041914, selects the first current record into 0x200061e0). Then it
@ raises BASEPRI to 0x10 (msr unconditional), ISB, DSB and tests 0x20000000
@ + 1: the value is 0, so the beq at 0x08041b44 is not taken and execution
@ ends in the infinite loop at 0x08041b48. One block the decompiler judges
@ unreachable is kept: the loop at 0x08041b5e..0x08041b6e that tests the zero
@ local [sp+12] and could only return if it were nonzero.
@ ----------------------------------------------------------------------------
	.section .text.fn_080419d4,"ax",%progbits
	.global fn_080419d4
	.thumb_func
	.type fn_080419d4, %function
fn_080419d4:
	push	{r4, r5, r7, lr}
	sub	sp, #0x10
	movw	r0, #0xe400
	movt	r0, #0xe000
	movw	r1, #0xc270
	movt	r1, #0x410f
	ldr.w	r2, [r0, #0x900]
	adds	r3, r1, #1
	cmp	r2, r3
	bne.n	.L08041a06
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	nop
.L08041a04:
	b.n	.L08041a04
.L08041a06:
	ldr.w	r2, [r0, #0x900]
	cmp	r2, r1
	bne.n	.L08041a22
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	nop
.L08041a20:
	b.n	.L08041a20
.L08041a22:
	ldrb	r1, [r0]
	movw	r2, #0x22c0
	str	r1, [sp, #0x8]
	movs	r1, #0xff
	strb	r1, [r0]
	ldrb	r1, [r0]
	movt	r2, #0x2000
	strb.w	r1, [sp, #0x7]
	ldrb.w	r1, [sp, #0x7]
	and.w	r1, r1, #0x10
	strb	r1, [r2]
	movw	r1, #0x22c4
	movt	r1, #0x2000
	movs	r2, #7
	str	r2, [r1]
	ldrsb.w	r2, [sp, #0x7]
	cmp.w	r2, #0xffffffff
	bgt.n	.L08041b4a
	movs	r2, #4
	nop
.L08041a5c:
	ldrb.w	r3, [sp, #0x7]
	lsls	r3, r3, #1
	strb.w	r3, [sp, #0x7]
	ldrsb.w	r3, [sp, #0x7]
	cmp	r3, #0
	bpl.n	.L08041aae
	ldrb.w	r3, [sp, #0x7]
	lsls	r3, r3, #1
	strb.w	r3, [sp, #0x7]
	ldrsb.w	r3, [sp, #0x7]
	cmp.w	r3, #0xffffffff
	bgt.n	.L08041ab2
	ldrb.w	r3, [sp, #0x7]
	lsls	r3, r3, #1
	strb.w	r3, [sp, #0x7]
	ldrsb.w	r3, [sp, #0x7]
	cmp.w	r3, #0xffffffff
	bgt.n	.L08041ab4
	ldrb.w	r3, [sp, #0x7]
	subs	r2, #4
	lsls	r3, r3, #1
	strb.w	r3, [sp, #0x7]
	ldrsb.w	r3, [sp, #0x7]
	cmp	r3, #0
	bmi.n	.L08041a5c
	adds	r2, #3
	b.n	.L08041ab4
.L08041aae:
	adds	r2, #2
	b.n	.L08041ab4
.L08041ab2:
	adds	r2, #1
.L08041ab4:
	cmp	r2, #3
	str	r2, [r1]
	bne.n	.L08041b4a
	mov.w	r2, #0x300
	str	r2, [r1]
	ldr	r1, [sp, #0x8]
	movw	r2, #0xfc18
	strb	r1, [r0]
	ldr.w	r1, [r0, #0x920]
	movs	r4, #0
	orr.w	r1, r1, #0xf00000
	str.w	r1, [r0, #0x920]
	ldr.w	r1, [r0, #0x920]
	movt	r2, #0xffff
	orr.w	r1, r1, #0xf0000000
	str.w	r1, [r0, #0x920]
	movw	r1, #0xfc10
	movt	r1, #0xffff
	str	r4, [r0, r1]
	str	r4, [r0, r2]
	movw	r2, #0xfc14
	movw	r3, #0xa97f
	movt	r2, #0xffff
	movt	r3, #0x3
	movw	r5, #0x0
	str	r3, [r0, r2]
	movs	r2, #7
	movt	r5, #0x2000
	str	r2, [r0, r1]
	str	r4, [r5]
	bl	enable_fpu_access
	movw	r0, #0xef34
	movt	r0, #0xe000
	ldr	r1, [r0]
	orr.w	r1, r1, #0xc0000000
	str	r1, [r0]
	bl	reset_msp_and_call_svc0
	bl	fn_08041914
	str	r4, [sp, #0xc]
	ldr	r0, [r5]
	mov.w	r1, #0x10
	msr	basepri, r1
	isb	sy
	dsb	sy
	adds	r0, #1
	beq.n	.L08041b6a
	nop
.L08041b48:
	b.n	.L08041b48
.L08041b4a:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	nop
.L08041b5c:
	b.n	.L08041b5c
.L08041b5e:
	ldr	r0, [sp, #0xc]
	cbnz	r0, .L08041b70
	ldr	r0, [sp, #0xc]
	cbnz	r0, .L08041b70
	ldr	r0, [sp, #0xc]
	cbnz	r0, .L08041b70
.L08041b6a:
	ldr	r0, [sp, #0xc]
	cmp	r0, #0
	beq.n	.L08041b5e
.L08041b70:
	add	sp, #0x10
	pop	{r4, r5, r7, pc}

@ ----------------------------------------------------------------------------
@ fn_08041b74 - Params r0=count, r1=item size, r2 (byte). Loops forever
@ (BASEPRI 0x10) if r0 == 0, if r1 != 0 and the 32-bit product r0*r1 divided
@ by r1 differs from r0 (overflow), or if product+0x48 wraps (product >=
@ product+0x48). Allocates product+0x48 bytes with heap_alloc_first_fit
@ (0803cc64); if the block is nonzero it calls queue_init_fields (0803bf04)
@ with (r0, r1, block+0x48, r2, block). Returns the block pointer (0 when the
@ allocation failed). Purpose: allocates and initialises a queue record with
@ storage appended after the 0x48-byte header (header size 0x48 from the
@ allocation arithmetic).
@ ----------------------------------------------------------------------------
	.section .text.fn_08041b74,"ax",%progbits
	.global fn_08041b74
	.thumb_func
	.type fn_08041b74, %function
fn_08041b74:
	push	{r7, lr}
	sub	sp, #0x28
	str	r0, [sp, #0x18]
	str	r1, [sp, #0x14]
	strb.w	r2, [sp, #0x13]
	ldr	r0, [sp, #0x18]
	cbnz	r0, .L08041b9c
	b.n	.L08041b86
.L08041b86:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x1c]
	b.n	.L08041b9a
.L08041b9a:
	b.n	.L08041b9a
.L08041b9c:
	ldr	r0, [sp, #0x18]
	ldr	r1, [sp, #0x14]
	muls	r0, r1, r0
	str	r0, [sp, #0x8]
	ldr	r1, [sp, #0x14]
	movs	r0, #1
	cbz	r1, .L08041bc0
	b.n	.L08041bac
.L08041bac:
	ldr	r0, [sp, #0x18]
	ldr	r1, [sp, #0x8]
	ldr	r2, [sp, #0x14]
	udiv	r1, r1, r2
	subs	r0, r0, r1
	clz	r0, r0
	lsrs	r0, r0, #5
	b.n	.L08041bc0
.L08041bc0:
	lsls	r0, r0, #31
	cbnz	r0, .L08041bdc
	b.n	.L08041bc6
.L08041bc6:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x20]
	b.n	.L08041bda
.L08041bda:
	b.n	.L08041bda
.L08041bdc:
	ldr	r0, [sp, #0x8]
	add.w	r1, r0, #0x48
	cmp	r1, r0
	bhi.n	.L08041bfe
	b.n	.L08041be8
.L08041be8:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x24]
	b.n	.L08041bfc
.L08041bfc:
	b.n	.L08041bfc
.L08041bfe:
	ldr	r0, [sp, #0x8]
	adds	r0, #0x48
	bl	heap_alloc_first_fit
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0xc]
	cbz	r0, .L08041c30
	b.n	.L08041c0e
.L08041c0e:
	ldr	r0, [sp, #0xc]
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	adds	r0, #0x48
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x18]
	ldr	r1, [sp, #0x14]
	ldr	r2, [sp, #0x4]
	ldrb.w	r3, [sp, #0x13]
	ldr.w	r12, [sp, #0xc]
	str.w	r12, [sp]
	bl	queue_init_fields
	b.n	.L08041c32
.L08041c30:
	b.n	.L08041c32
.L08041c32:
	ldr	r0, [sp, #0xc]
	add	sp, #0x28
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ queue_reset - Params r0=queue record, r1=flag. Loops forever (BASEPRI 0x10)
@ if r0 == 0. Calls enter_critical (08041168), then r0[2] = r0[0xf]*r0[0x10] +
@ r0[0], r0[0xe] = 0, r0[1] = r0[0], r0[3] = (r0[0xf]-1)*r0[0x10] + r0[0],
@ bytes r0+0x44 and r0+0x45 = 0xff. If r1 == 0: when r0[4] != 0 and
@ fn_08042b4c (08042b4c)(r0+0x10) returns nonzero it writes 0x10000000 to
@ 0xE000ED04 with DSB and ISB. If r1 != 0: list_init (0804106c)(r0+0x10) and
@ list_init(r0+0x24). Calls exit_critical (080411b0). No return value.
@ ----------------------------------------------------------------------------
	.section .text.queue_reset,"ax",%progbits
	.global queue_reset
	.thumb_func
	.type queue_reset, %function
queue_reset:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0x8]
	str	r1, [sp, #0x4]
	ldr	r0, [sp, #0x8]
	str	r0, [sp]
	ldr	r0, [sp]
	cbnz	r0, .L08041c60
	b.n	.L08041c4a
.L08041c4a:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0xc]
	b.n	.L08041c5e
.L08041c5e:
	b.n	.L08041c5e
.L08041c60:
	bl	enter_critical
	ldr	r0, [sp]
	ldr	r1, [r0]
	ldr	r2, [r0, #0x3c]
	ldr	r3, [r0, #0x40]
	mla	r1, r2, r3, r1
	str	r1, [r0, #0x8]
	ldr	r0, [sp]
	movs	r1, #0
	str	r1, [r0, #0x38]
	ldr	r0, [sp]
	ldr	r1, [r0]
	str	r1, [r0, #0x4]
	ldr	r0, [sp]
	ldr	r1, [r0]
	ldr	r2, [r0, #0x3c]
	ldr	r3, [r0, #0x40]
	subs	r2, #1
	mla	r1, r2, r3, r1
	str	r1, [r0, #0xc]
	ldr	r0, [sp]
	movs	r1, #0xff
	strb.w	r1, [r0, #0x44]
	ldr	r0, [sp]
	strb.w	r1, [r0, #0x45]
	ldr	r0, [sp, #0x4]
	cbnz	r0, .L08041cd6
	b.n	.L08041ca2
.L08041ca2:
	ldr	r0, [sp]
	ldr	r0, [r0, #0x10]
	cbz	r0, .L08041cd2
	b.n	.L08041caa
.L08041caa:
	ldr	r0, [sp]
	adds	r0, #0x10
	bl	fn_08042b4c
	cbz	r0, .L08041cce
	b.n	.L08041cb6
.L08041cb6:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0]
	dsb	sy
	isb	sy
	b.n	.L08041cd0
.L08041cce:
	b.n	.L08041cd0
.L08041cd0:
	b.n	.L08041cd4
.L08041cd2:
	b.n	.L08041cd4
.L08041cd4:
	b.n	.L08041ce8
.L08041cd6:
	ldr	r0, [sp]
	adds	r0, #0x10
	bl	list_init
	ldr	r0, [sp]
	adds	r0, #0x24
	bl	list_init
	b.n	.L08041ce8
.L08041ce8:
	bl	exit_critical
	add	sp, #0x10
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ queue_send_timeout - Params r0=queue record, r1=item pointer, r2=timeout
@ ticks. Loops forever (BASEPRI 0x10) if r0 == 0, if r1 == 0 and word r0+0x40
@ != 0, or if fn_08042730 (08042730)() == 0 and r2 != 0. The decompiled mode
@ variable is the constant 0, so the kept blocks that test mode == 2 and word
@ +0x3c != 1 are dead code. Loop: enter_critical (08041168); if word +0x38 <
@ word +0x3c: queue_copy_in_item (0803bcc4)(r0, r1, 0) copies the item; if
@ list count word +0x24 == 0 the result of 0803bcc4 decides, else
@ fn_08042b4c (08042b4c)(r0+0x24) decides: nonzero writes 0x10000000 to
@ 0xE000ED04 with DSB/ISB; exit_critical (080411b0); returns 1. If no space
@ and r2 == 0: 080411b0, returns 0. Otherwise: first pass stores the time
@ stamp with fn_08041400 (08041400), then 080411b0,
@ increment_word_200061e4 (08041904), 08041168, clears bytes +0x44/+0x45 when
@ 0xff, 080411b0, then fn_080425cc (080425cc)(&stamp, &timeout): nonzero ->
@ queue_unlock (0803c7b8)(r0), fn_08042c10 (08042c10), returns 0; zero -> if
@ queue_is_full (0803c2d4)(r0) == 0 it calls 0803c7b8, 08042c10 and retries,
@ else fn_08041434 (08041434)(r0+0x10, timeout), 0803c7b8, 08042c10
@ (0x10000000 written to 0xE000ED04 when that returned 0) and retries.
@ Purpose: copies an item into the queue, waiting up to r2 ticks for space.
@ ----------------------------------------------------------------------------
	.section .text.queue_send_timeout,"ax",%progbits
	.global queue_send_timeout
	.thumb_func
	.type queue_send_timeout, %function
queue_send_timeout:
	push	{r7, lr}
	sub	sp, #0x38
	str	r0, [sp, #0x20]
	str	r1, [sp, #0x1c]
	str	r2, [sp, #0x18]
	movs	r0, #0
	str	r0, [sp, #0x14]
	str	r0, [sp, #0x10]
	ldr	r0, [sp, #0x20]
	str	r0, [sp]
	ldr	r0, [sp]
	cbnz	r0, .L08041d20
	b.n	.L08041d0a
.L08041d0a:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x28]
	b.n	.L08041d1e
.L08041d1e:
	b.n	.L08041d1e
.L08041d20:
	ldr	r1, [sp, #0x1c]
	movs	r0, #0
	cbnz	r1, .L08041d34
	b.n	.L08041d28
.L08041d28:
	ldr	r0, [sp]
	ldr	r0, [r0, #0x40]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	b.n	.L08041d34
.L08041d34:
	lsls	r0, r0, #31
	cbz	r0, .L08041d50
	b.n	.L08041d3a
.L08041d3a:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x2c]
	b.n	.L08041d4e
.L08041d4e:
	b.n	.L08041d4e
.L08041d50:
	ldr	r1, [sp, #0x14]
	movs	r0, #0
	cmp	r1, #2
	bne.n	.L08041d66
	b.n	.L08041d5a
.L08041d5a:
	ldr	r0, [sp]
	ldr	r0, [r0, #0x3c]
	subs	r0, #1
	it	ne
	movne	r0, #1
	b.n	.L08041d66
.L08041d66:
	lsls	r0, r0, #31
	cbz	r0, .L08041d82
	b.n	.L08041d6c
.L08041d6c:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x30]
	b.n	.L08041d80
.L08041d80:
	b.n	.L08041d80
.L08041d82:
	bl	fn_08042730
	movs	r1, #0
	cbnz	r0, .L08041d96
	b.n	.L08041d8c
.L08041d8c:
	ldr	r1, [sp, #0x18]
	cmp	r1, #0
	it	ne
	movne	r1, #1
	b.n	.L08041d96
.L08041d96:
	lsls	r0, r1, #31
	cbz	r0, .L08041db2
	b.n	.L08041d9c
.L08041d9c:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x34]
	b.n	.L08041db0
.L08041db0:
	b.n	.L08041db0
.L08041db2:
	b.n	.L08041db4
.L08041db4:
	bl	enter_critical
	ldr	r0, [sp]
	ldr	r0, [r0, #0x38]
	ldr	r1, [sp]
	ldr	r1, [r1, #0x3c]
	cmp	r0, r1
	bcc.n	.L08041dce
	b.n	.L08041dc6
.L08041dc6:
	ldr	r0, [sp, #0x14]
	cmp	r0, #2
	bne.n	.L08041e36
	b.n	.L08041dce
.L08041dce:
	ldr	r0, [sp]
	ldr	r1, [sp, #0x1c]
	ldr	r2, [sp, #0x14]
	bl	queue_copy_in_item
	str	r0, [sp, #0xc]
	ldr	r0, [sp]
	ldr	r0, [r0, #0x24]
	cbz	r0, .L08041e0a
	b.n	.L08041de2
.L08041de2:
	ldr	r0, [sp]
	adds	r0, #0x24
	bl	fn_08042b4c
	cbz	r0, .L08041e06
	b.n	.L08041dee
.L08041dee:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0]
	dsb	sy
	isb	sy
	b.n	.L08041e08
.L08041e06:
	b.n	.L08041e08
.L08041e08:
	b.n	.L08041e2c
.L08041e0a:
	ldr	r0, [sp, #0xc]
	cbz	r0, .L08041e28
	b.n	.L08041e10
.L08041e10:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0]
	dsb	sy
	isb	sy
	b.n	.L08041e2a
.L08041e28:
	b.n	.L08041e2a
.L08041e2a:
	b.n	.L08041e2c
.L08041e2c:
	bl	exit_critical
	movs	r0, #1
	str	r0, [sp, #0x24]
	b.n	.L08041f02
.L08041e36:
	ldr	r0, [sp, #0x18]
	cbnz	r0, .L08041e46
	b.n	.L08041e3c
.L08041e3c:
	bl	exit_critical
	movs	r0, #0
	str	r0, [sp, #0x24]
	b.n	.L08041f02
.L08041e46:
	ldr	r0, [sp, #0x10]
	cbnz	r0, .L08041e58
	b.n	.L08041e4c
.L08041e4c:
	add	r0, sp, #4
	bl	fn_08041400
	movs	r0, #1
	str	r0, [sp, #0x10]
	b.n	.L08041e5a
.L08041e58:
	b.n	.L08041e5a
.L08041e5a:
	b.n	.L08041e5c
.L08041e5c:
	b.n	.L08041e5e
.L08041e5e:
	bl	exit_critical
	bl	increment_word_200061e4
	bl	enter_critical
	ldr	r0, [sp]
	ldrsb.w	r0, [r0, #0x44]
	adds	r0, #1
	cbnz	r0, .L08041e80
	b.n	.L08041e76
.L08041e76:
	ldr	r0, [sp]
	movs	r1, #0
	strb.w	r1, [r0, #0x44]
	b.n	.L08041e80
.L08041e80:
	ldr	r0, [sp]
	ldrsb.w	r0, [r0, #0x45]
	adds	r0, #1
	cbnz	r0, .L08041e96
	b.n	.L08041e8c
.L08041e8c:
	ldr	r0, [sp]
	movs	r1, #0
	strb.w	r1, [r0, #0x45]
	b.n	.L08041e96
.L08041e96:
	bl	exit_critical
	add	r0, sp, #4
	add	r1, sp, #0x18
	bl	fn_080425cc
	cbnz	r0, .L08041ef0
	b.n	.L08041ea6
.L08041ea6:
	ldr	r0, [sp]
	bl	queue_is_full
	cbz	r0, .L08041ee2
	b.n	.L08041eb0
.L08041eb0:
	ldr	r0, [sp]
	adds	r0, #0x10
	ldr	r1, [sp, #0x18]
	bl	fn_08041434
	ldr	r0, [sp]
	bl	queue_unlock
	bl	fn_08042c10
	cbnz	r0, .L08041ee0
	b.n	.L08041ec8
.L08041ec8:
	movw	r0, #0xed04
	movt	r0, #0xe000
	mov.w	r1, #0x10000000
	str	r1, [r0]
	dsb	sy
	isb	sy
	b.n	.L08041ee0
.L08041ee0:
	b.n	.L08041eee
.L08041ee2:
	ldr	r0, [sp]
	bl	queue_unlock
	bl	fn_08042c10
	b.n	.L08041eee
.L08041eee:
	b.n	.L08041f00
.L08041ef0:
	ldr	r0, [sp]
	bl	queue_unlock
	bl	fn_08042c10
	movs	r0, #0
	str	r0, [sp, #0x24]
	b.n	.L08041f02
.L08041f00:
	b.n	.L08041db4
.L08041f02:
	ldr	r0, [sp, #0x24]
	add	sp, #0x38
	pop	{r7, pc}

@ ----------------------------------------------------------------------------
@ queue_send_from_isr - Params r0=queue record, r1=item pointer, r2=pointer to
@ a wake flag (may be 0). Loops forever (BASEPRI 0x10) if r0 == 0 or (r1 == 0
@ and word +0x40 != 0). Calls check_irq_priority_limits (080412c8), saves
@ BASEPRI (mrs at 0x08041f9c, unconditional) and raises it to 0x10, ISB, DSB.
@ If word +0x38 < word +0x3c: reads byte +0x45 (c), copies the item with
@ queue_copy_in_item (0803bcc4)(r0, r1, 0); c == 0xff: when word +0x24 != 0
@ and fn_08042b4c (08042b4c)(r0+0x24) returns nonzero and r2 != 0 it stores 1
@ at *r2; c == 0x7f: loops forever; else byte +0x45 = c+1; result 1.
@ Otherwise result 0. Restores BASEPRI (msr at 0x08042060, unconditional) and
@ returns the result. Two kept dead blocks (the mode tests as in
@ queue_send_timeout). Purpose: non-blocking send variant of
@ queue_send_timeout for interrupt level.
@ ----------------------------------------------------------------------------
	.section .text.queue_send_from_isr,"ax",%progbits
	.global queue_send_from_isr
	.thumb_func
	.type queue_send_from_isr, %function
queue_send_from_isr:
	push	{r7, lr}
	sub	sp, #0x40
	str	r0, [sp, #0x20]
	str	r1, [sp, #0x1c]
	str	r2, [sp, #0x18]
	movs	r0, #0
	str	r0, [sp, #0x14]
	ldr	r0, [sp, #0x20]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	cbnz	r0, .L08041f36
	b.n	.L08041f20
.L08041f20:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x24]
	b.n	.L08041f34
.L08041f34:
	b.n	.L08041f34
.L08041f36:
	ldr	r1, [sp, #0x1c]
	movs	r0, #0
	cbnz	r1, .L08041f4a
	b.n	.L08041f3e
.L08041f3e:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x40]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	b.n	.L08041f4a
.L08041f4a:
	lsls	r0, r0, #31
	cbz	r0, .L08041f66
	b.n	.L08041f50
.L08041f50:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x28]
	b.n	.L08041f64
.L08041f64:
	b.n	.L08041f64
.L08041f66:
	ldr	r1, [sp, #0x14]
	movs	r0, #0
	cmp	r1, #2
	bne.n	.L08041f7c
	b.n	.L08041f70
.L08041f70:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x3c]
	subs	r0, #1
	it	ne
	movne	r0, #1
	b.n	.L08041f7c
.L08041f7c:
	lsls	r0, r0, #31
	cbz	r0, .L08041f98
	b.n	.L08041f82
.L08041f82:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x2c]
	b.n	.L08041f96
.L08041f96:
	b.n	.L08041f96
.L08041f98:
	bl	check_irq_priority_limits
	mrs	r0, basepri
	mov.w	r1, #0x10
	msr	basepri, r1
	isb	sy
	dsb	sy
	str	r0, [sp, #0x34]
	str	r1, [sp, #0x30]
	ldr	r0, [sp, #0x34]
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x38]
	ldr	r1, [sp, #0x8]
	ldr	r1, [r1, #0x3c]
	cmp	r0, r1
	bcc.n	.L08041fce
	b.n	.L08041fc6
.L08041fc6:
	ldr	r0, [sp, #0x14]
	cmp	r0, #2
	bne.n	.L08042054
	b.n	.L08041fce
.L08041fce:
	ldr	r0, [sp, #0x8]
	ldrb.w	r0, [r0, #0x45]
	strb.w	r0, [sp, #0x7]
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x38]
	str	r0, [sp]
	ldr	r0, [sp, #0x8]
	ldr	r1, [sp, #0x1c]
	ldr	r2, [sp, #0x14]
	bl	queue_copy_in_item
	ldrsb.w	r0, [sp, #0x7]
	adds	r0, #1
	cbnz	r0, .L08042020
	b.n	.L08041ff2
.L08041ff2:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x24]
	cbz	r0, .L0804201c
	b.n	.L08041ffa
.L08041ffa:
	ldr	r0, [sp, #0x8]
	adds	r0, #0x24
	bl	fn_08042b4c
	cbz	r0, .L08042018
	b.n	.L08042006
.L08042006:
	ldr	r0, [sp, #0x18]
	cbz	r0, .L08042014
	b.n	.L0804200c
.L0804200c:
	ldr	r0, [sp, #0x18]
	movs	r1, #1
	str	r1, [r0]
	b.n	.L08042016
.L08042014:
	b.n	.L08042016
.L08042016:
	b.n	.L0804201a
.L08042018:
	b.n	.L0804201a
.L0804201a:
	b.n	.L0804201e
.L0804201c:
	b.n	.L0804201e
.L0804201e:
	b.n	.L0804204e
.L08042020:
	ldrsb.w	r0, [sp, #0x7]
	cmp	r0, #0x7f
	bne.n	.L08042040
	b.n	.L0804202a
.L0804202a:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x38]
	b.n	.L0804203e
.L0804203e:
	b.n	.L0804203e
.L08042040:
	ldrb.w	r0, [sp, #0x7]
	adds	r0, #1
	ldr	r1, [sp, #0x8]
	strb.w	r0, [r1, #0x45]
	b.n	.L0804204e
.L0804204e:
	movs	r0, #1
	str	r0, [sp, #0x10]
	b.n	.L0804205a
.L08042054:
	movs	r0, #0
	str	r0, [sp, #0x10]
	b.n	.L0804205a
.L0804205a:
	ldr	r0, [sp, #0xc]
	str	r0, [sp, #0x3c]
	ldr	r0, [sp, #0x3c]
	msr	basepri, r0
	ldr	r0, [sp, #0x10]
	add	sp, #0x40
	pop	{r7, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ fn_0804206c - Param r0=queue record. Calls enter_critical (08041168);
@ result = r0[2] when r0[0] == 0, else 0; calls exit_critical (080411b0);
@ returns the result.
@ ----------------------------------------------------------------------------
	.section .text.fn_0804206c,"ax",%progbits
	.global fn_0804206c
	.thumb_func
	.type fn_0804206c, %function
fn_0804206c:
	push	{r7, lr}
	sub	sp, #0x10
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0xc]
	str	r0, [sp, #0x4]
	bl	enter_critical
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0]
	cbnz	r0, .L0804208a
	b.n	.L08042082
.L08042082:
	ldr	r0, [sp, #0x4]
	ldr	r0, [r0, #0x8]
	str	r0, [sp, #0x8]
	b.n	.L08042090
.L0804208a:
	movs	r0, #0
	str	r0, [sp, #0x8]
	b.n	.L08042090
.L08042090:
	bl	exit_critical
	ldr	r0, [sp, #0x8]
	add	sp, #0x10
	pop	{r7, pc}
	.short	0x0000			@ padding

@ ----------------------------------------------------------------------------
@ semaphore_give_from_isr - Params r0=queue record, r1=pointer to a wake flag
@ (may be 0). Loops forever (BASEPRI 0x10) if r0 == 0, if word +0x40 != 0, or
@ if r0[0] == 0 and r0[2] != 0. Calls check_irq_priority_limits (080412c8),
@ saves BASEPRI (mrs at 0x08042118, unconditional) and raises it to 0x10, ISB,
@ DSB. If word +0x38 < word +0x3c: reads byte +0x45 (c), increments word
@ +0x38; c == 0xff: when word +0x24 != 0 and fn_08042b4c (08042b4c)(r0+0x24)
@ returns nonzero and r1 != 0 it stores 1 at *r1; c == 0x7f: loops forever;
@ else byte +0x45 = c+1. Restores BASEPRI and returns the saved BASEPRI value
@ (r0 = the saved copy, loaded at 0x080421ce), not a success flag. Purpose:
@ increments the count of a zero-item-size record from interrupt level.
@ ----------------------------------------------------------------------------
	.section .text.semaphore_give_from_isr,"ax",%progbits
	.global semaphore_give_from_isr
	.thumb_func
	.type semaphore_give_from_isr, %function
semaphore_give_from_isr:
	push	{r7, lr}
	sub	sp, #0x38
	str	r0, [sp, #0x18]
	str	r1, [sp, #0x14]
	ldr	r0, [sp, #0x18]
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	cbnz	r0, .L080420c4
	b.n	.L080420ae
.L080420ae:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x1c]
	b.n	.L080420c2
.L080420c2:
	b.n	.L080420c2
.L080420c4:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x40]
	cbz	r0, .L080420e2
	b.n	.L080420cc
.L080420cc:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x20]
	b.n	.L080420e0
.L080420e0:
	b.n	.L080420e0
.L080420e2:
	ldr	r0, [sp, #0x8]
	ldr	r1, [r0]
	movs	r0, #0
	cbnz	r1, .L080420f8
	b.n	.L080420ec
.L080420ec:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x8]
	cmp	r0, #0
	it	ne
	movne	r0, #1
	b.n	.L080420f8
.L080420f8:
	lsls	r0, r0, #31
	cbz	r0, .L08042114
	b.n	.L080420fe
.L080420fe:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x24]
	b.n	.L08042112
.L08042112:
	b.n	.L08042112
.L08042114:
	bl	check_irq_priority_limits
	mrs	r0, basepri
	mov.w	r1, #0x10
	msr	basepri, r1
	isb	sy
	dsb	sy
	str	r0, [sp, #0x2c]
	str	r1, [sp, #0x28]
	ldr	r0, [sp, #0x2c]
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x38]
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	ldr	r1, [sp, #0x8]
	ldr	r1, [r1, #0x3c]
	cmp	r0, r1
	bcs.n	.L080421c4
	b.n	.L08042146
.L08042146:
	ldr	r0, [sp, #0x8]
	ldrb.w	r0, [r0, #0x45]
	strb.w	r0, [sp, #0x3]
	ldr	r0, [sp, #0x4]
	adds	r0, #1
	ldr	r1, [sp, #0x8]
	str	r0, [r1, #0x38]
	ldrsb.w	r0, [sp, #0x3]
	adds	r0, #1
	cbnz	r0, .L08042190
	b.n	.L08042162
.L08042162:
	ldr	r0, [sp, #0x8]
	ldr	r0, [r0, #0x24]
	cbz	r0, .L0804218c
	b.n	.L0804216a
.L0804216a:
	ldr	r0, [sp, #0x8]
	adds	r0, #0x24
	bl	fn_08042b4c
	cbz	r0, .L08042188
	b.n	.L08042176
.L08042176:
	ldr	r0, [sp, #0x14]
	cbz	r0, .L08042184
	b.n	.L0804217c
.L0804217c:
	ldr	r0, [sp, #0x14]
	movs	r1, #1
	str	r1, [r0]
	b.n	.L08042186
.L08042184:
	b.n	.L08042186
.L08042186:
	b.n	.L0804218a
.L08042188:
	b.n	.L0804218a
.L0804218a:
	b.n	.L0804218e
.L0804218c:
	b.n	.L0804218e
.L0804218e:
	b.n	.L080421be
.L08042190:
	ldrsb.w	r0, [sp, #0x3]
	cmp	r0, #0x7f
	bne.n	.L080421b0
	b.n	.L0804219a
.L0804219a:
	mov.w	r0, #0x10
	msr	basepri, r0
	isb	sy
	dsb	sy
	str	r0, [sp, #0x30]
	b.n	.L080421ae
.L080421ae:
	b.n	.L080421ae
.L080421b0:
	ldrb.w	r0, [sp, #0x3]
	adds	r0, #1
	ldr	r1, [sp, #0x8]
	strb.w	r0, [r1, #0x45]
	b.n	.L080421be
.L080421be:
	movs	r0, #1
	str	r0, [sp, #0x10]
	b.n	.L080421ca
.L080421c4:
	movs	r0, #0
	str	r0, [sp, #0x10]
	b.n	.L080421ca
.L080421ca:
	ldr	r0, [sp, #0xc]
	str	r0, [sp, #0x34]
	ldr	r0, [sp, #0x34]
	msr	basepri, r0
	add	sp, #0x38
	pop	{r7, pc}

