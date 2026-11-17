@ kernel_23.s - kernel exception handlers (PendSV-style context switch, SVC restore, SysTick), task delay / ready registration, timer service init, terminated-task cleanup and queue item copy routines.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ psp_context_save_restore - context switch exception handler (exception slot 14).
@ No parameters in the C view; entered through the word 0x08028d51 stored at image
@ offset 0x38 (address 0x08007038, exception slot 14) and leaves through bx lr with
@ the exception return value; r0 holds the new process stack pointer at the end.
@ Reads the process stack pointer (mrs r0,psp), loads the constant 0x200061e0
@ (literal at 0x08028db0) into r3 and the word stored at that address into r2,
@ pushes s16..s31 when bit 4 of lr is 0 (vstmdbeq), pushes r4-r11 and lr (stmdb)
@ and stores the new stack top through r2.
@ Pushes r0 and r3 on the main stack, sets BASEPRI to 0x10, dsb, isb, calls
@ 0x08041914, sets BASEPRI to 0, pops r0/r3, reloads the stack top from the record
@ the pointer at 0x200061e0 now designates, pops r4-r11 and lr (ldmia), pops
@ s16..s31 when bit 4 of the loaded lr is 0 (vldmiaeq), writes msr psp, isb, bx lr.
@ Purpose: stores r4-r11, lr (and s16..s31) below the process stack pointer and the
@ new stack top through the record designated by the word at 0x200061e0, calls
@ 0x08041914, then reloads r4-r11, lr (and s16..s31) and the process stack pointer
@ from the record designated by the word at 0x200061e0 after the call (the
@ privileged tests in the decompiled C are not in the disassembly).
@ ----------------------------------------------------------------------------
	.section .text.psp_context_save_restore,"ax",%progbits
	.p2align 2
	.global psp_context_save_restore
	.thumb_func
	.type psp_context_save_restore, %function
psp_context_save_restore:
	mrs r0, psp
	isb sy
	ldr r3, .L08028db0
	ldr r2, [r3, #0]
	tst.w lr, #0x10
	it eq
	vstmdbeq r0!, {s16-s31}
	stmdb r0!, {r4-r11, lr}
	str r0, [r2, #0]
	push.w {r0, r3}
	mov.w r0, #0x10
	msr basepri, r0
	dsb sy
	isb sy
	bl fn_08041914
	mov.w r0, #0
	msr basepri, r0
	pop.w {r0, r3}
	ldr r1, [r3, #0]
	ldr r0, [r1, #0]
	ldm.w r0!, {r4-r11, lr}
	tst.w lr, #0x10
	it eq
	vldmiaeq r0!, {s16-s31}
	msr psp, r0
	isb sy
	bx lr
	.short 0xbf00	@ padding
	.short 0xbf00	@ padding
.L08028db0:
	.word 0x200061e0
	.short 0x0000	@ padding
	.short 0x0000	@ padding
	.short 0x0000	@ padding
	.short 0x0000	@ padding
	.short 0x0000	@ padding
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ svc_restore_context - SVC exception handler (exception slot 11) that restores a task context.
@ No parameters; exception handler entered through the word 0x08028dc1 stored at
@ image offset 0x2c (address 0x0800702c, exception slot 11); r0 is 0 at bx lr.
@ Loads the pointer at word 0x200061e0, the stack top it designates, pops r4-r11
@ and lr with ldmia, writes the process stack pointer (msr psp), isb, sets BASEPRI
@ to 0 and executes bx lr.
@ Purpose: loads r4-r11, lr and the process stack pointer from the record
@ designated by the word at 0x200061e0 and returns from the exception (no float
@ registers are restored here).
@ ----------------------------------------------------------------------------
	.section .text.svc_restore_context,"ax",%progbits
	.p2align 2
	.global svc_restore_context
	.thumb_func
	.type svc_restore_context, %function
svc_restore_context:
	ldr r3, .L08028de0
	ldr r1, [r3, #0]
	ldr r0, [r1, #0]
	ldm.w r0!, {r4-r11, lr}
	msr psp, r0
	isb sy
	mov.w r0, #0
	msr basepri, r0
	bx lr
	.short 0xbf00	@ padding
	.short 0xbf00	@ padding
.L08028de0:
	.word 0x200061e0

@ ----------------------------------------------------------------------------
@ systick_handler - SysTick exception handler (exception slot 15).
@ No parameters; entered through the word 0x0802a995 stored at image offset 0x3c
@ (address 0x0800703c, exception slot 15); returns 0 in r0.
@ Sets BASEPRI to 0x10, isb, dsb, calls 0x0804277c (tick increment, returns 1 when
@ a reschedule is needed); when it returns non-zero writes 0x10000000 to
@ 0xE000ED04 (ICSR bit 28); sets BASEPRI to 0.
@ Purpose: advances the tick through 0x0804277c and raises the pending-switch
@ exception when that call asks for a reschedule.
@ ----------------------------------------------------------------------------
	.section .text.systick_handler,"ax",%progbits
	.global systick_handler
	.thumb_func
	.type systick_handler, %function
systick_handler:
	push {r7, lr}
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	bl fn_0804277c
	cbz r0, .L0802a9ba
	movw r0, #0xed04
	movt r0, #0xe000
	mov.w r1, #0x10000000
	str r1, [r0, #0]
.L0802a9ba:
	movs r0, #0
	msr basepri, r0
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ task_delay_current - move the current task into a delay list.
@ Params r0=signed tick offset, r1=flag; no return value.
@ Reads the tick word 0x200062d4; unlinks the current task's list node (current =
@ word 0x200061e0, node at +4) with 08041024, and when that returns 0 clears bit
@ (word[0x2c]&0xff) of the ready bitmap 0x200061ec.
@ If r0==-1 and r1!=0 inserts the node into the list at 0x200062b0 with 08041118.
@ Otherwise stores tick+r0 as the node key at current+4 and inserts it with
@ 080410ac into the list pointed to by 0x200062c8 when the sum is below the old
@ tick (overflow), else into the list pointed to by 0x200062c4 and lowers the word
@ 0x200062d0 when the new key is smaller.
@ ----------------------------------------------------------------------------
	.section .text.task_delay_current,"ax",%progbits
	.global task_delay_current
	.thumb_func
	.type task_delay_current, %function
task_delay_current:
	push {r7, lr}
	sub sp, #0x10
	str r0, [sp, #0xc]
	str r1, [sp, #8]
	movw r0, #0x62d4
	movt r0, #0x2000
	ldr r0, [r0, #0]
	str r0, [sp, #0]
	movw r0, #0x61e0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	adds r0, #4
	bl list_unlink_node
	cbnz r0, .L0803ba04
	b.n .L0803b9e0
.L0803b9e0:
	movw r0, #0x61e0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0x2c]
	movs r1, #1
	lsl.w r0, r1, r0
	movw r1, #0x61ec
	movt r1, #0x2000
	ldr r2, [r1, #0]
	bic.w r0, r2, r0
	str r0, [r1, #0]
	b.n .L0803ba06
.L0803ba04:
	b.n .L0803ba06
.L0803ba06:
	ldr r0, [sp, #0xc]
	adds r0, #1
	cbnz r0, .L0803ba2e
	b.n .L0803ba0e
.L0803ba0e:
	ldr r0, [sp, #8]
	cbz r0, .L0803ba2e
	b.n .L0803ba14
.L0803ba14:
	movw r0, #0x61e0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	adds r1, r0, #4
	movw r0, #0x62b0
	movt r0, #0x2000
	bl list_insert_before_cursor
	b.n .L0803baaa
.L0803ba2e:
	ldr r0, [sp, #0]
	ldr r1, [sp, #0xc]
	add r0, r1
	str r0, [sp, #4]
	ldr r0, [sp, #4]
	movw r1, #0x61e0
	movt r1, #0x2000
	ldr r1, [r1, #0]
	str r0, [r1, #4]
	ldr r0, [sp, #4]
	ldr r1, [sp, #0]
	cmp r0, r1
	bcs.n .L0803ba6a
	b.n .L0803ba4e
.L0803ba4e:
	movw r0, #0x62c8
	movt r0, #0x2000
	ldr r0, [r0, #0]
	movw r1, #0x61e0
	movt r1, #0x2000
	ldr r1, [r1, #0]
	adds r1, #4
	bl list_insert_sorted
	b.n .L0803baa8
.L0803ba6a:
	movw r0, #0x62c4
	movt r0, #0x2000
	ldr r0, [r0, #0]
	movw r1, #0x61e0
	movt r1, #0x2000
	ldr r1, [r1, #0]
	adds r1, #4
	bl list_insert_sorted
	ldr r0, [sp, #4]
	movw r1, #0x62d0
	movt r1, #0x2000
	ldr r1, [r1, #0]
	cmp r0, r1
	bcs.n .L0803baa4
	b.n .L0803ba96
.L0803ba96:
	ldr r0, [sp, #4]
	movw r1, #0x62d0
	movt r1, #0x2000
	str r0, [r1, #0]
	b.n .L0803baa6
.L0803baa4:
	b.n .L0803baa6
.L0803baa6:
	b.n .L0803baa8
.L0803baa8:
	b.n .L0803baaa
.L0803baaa:
	add sp, #0x10
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ task_register_ready - register a task record as ready to run.
@ Param r0=pointer to a task record; no return value.
@ Calls 08041168 (critical section enter), increments the word 0x20006254; if the
@ current task word 0x200061e0 is 0 it sets it to r0 and, when 0x20006254 became 1,
@ calls 0803c0d0 (list initialisation); otherwise when 0x20006258 is 0 and the
@ priority word (+0x2c) of the current task <= that of r0 it sets 0x200061e0=r0.
@ Increments 0x2000625c, sets bit (r0[0x2c]&0xff) in the ready bitmap 0x200061ec,
@ inserts r0+4 with 08041118 into the list at 0x200061f0+r0[0x2c]*20, calls
@ 080411b0 (critical section exit).
@ When 0x20006258 is nonzero and the current task's +0x2c is below r0's +0x2c it
@ writes 0x10000000 to 0xE000ED04 (ICSR) followed by DSB and ISB.
@ ----------------------------------------------------------------------------
	.section .text.task_register_ready,"ax",%progbits
	.global task_register_ready
	.thumb_func
	.type task_register_ready, %function
task_register_ready:
	push {r7, lr}
	sub sp, #8
	str r0, [sp, #4]
	bl enter_critical
	movw r0, #0x6254
	movt r0, #0x2000
	ldr r1, [r0, #0]
	adds r1, #1
	str r1, [r0, #0]
	movw r0, #0x61e0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	cbnz r0, .L0803bafc
	b.n .L0803bad6
.L0803bad6:
	ldr r0, [sp, #4]
	movw r1, #0x61e0
	movt r1, #0x2000
	str r0, [r1, #0]
	movw r0, #0x6254
	movt r0, #0x2000
	ldr r0, [r0, #0]
	cmp r0, #1
	bne.n .L0803baf8
	b.n .L0803baf2
.L0803baf2:
	bl task_lists_init
	b.n .L0803bafa
.L0803baf8:
	b.n .L0803bafa
.L0803bafa:
	b.n .L0803bb36
.L0803bafc:
	movw r0, #0x6258
	movt r0, #0x2000
	ldr r0, [r0, #0]
	cbnz r0, .L0803bb32
	b.n .L0803bb0a
.L0803bb0a:
	movw r0, #0x61e0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0x2c]
	ldr r1, [sp, #4]
	ldr r1, [r1, #0x2c]
	cmp r0, r1
	bhi.n .L0803bb2e
	b.n .L0803bb20
.L0803bb20:
	ldr r0, [sp, #4]
	movw r1, #0x61e0
	movt r1, #0x2000
	str r0, [r1, #0]
	b.n .L0803bb30
.L0803bb2e:
	b.n .L0803bb30
.L0803bb30:
	b.n .L0803bb34
.L0803bb32:
	b.n .L0803bb34
.L0803bb34:
	b.n .L0803bb36
.L0803bb36:
	movw r0, #0x625c
	movt r0, #0x2000
	ldr r1, [r0, #0]
	adds r1, #1
	str r1, [r0, #0]
	ldr r0, [sp, #4]
	ldr r0, [r0, #0x2c]
	movs r1, #1
	lsl.w r0, r1, r0
	movw r1, #0x61ec
	movt r1, #0x2000
	ldr r2, [r1, #0]
	orrs r0, r2
	str r0, [r1, #0]
	ldr r1, [sp, #4]
	ldr r0, [r1, #0x2c]
	add.w r0, r0, r0, lsl #2
	movw r2, #0x61f0
	movt r2, #0x2000
	add.w r0, r2, r0, lsl #2
	adds r1, #4
	bl list_insert_before_cursor
	bl exit_critical
	movw r0, #0x6258
	movt r0, #0x2000
	ldr r0, [r0, #0]
	cbz r0, .L0803bbba
	b.n .L0803bb88
.L0803bb88:
	movw r0, #0x61e0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0x2c]
	ldr r1, [sp, #4]
	ldr r1, [r1, #0x2c]
	cmp r0, r1
	bcs.n .L0803bbb6
	b.n .L0803bb9e
.L0803bb9e:
	movw r0, #0xed04
	movt r0, #0xe000
	mov.w r1, #0x10000000
	str r1, [r0, #0]
	dsb sy
	isb sy
	b.n .L0803bbb8
.L0803bbb6:
	b.n .L0803bbb8
.L0803bbb8:
	b.n .L0803bbbc
.L0803bbba:
	b.n .L0803bbbc
.L0803bbbc:
	add sp, #8
	pop {r7, pc}

@ ----------------------------------------------------------------------------
@ timer_service_init - one-time initialisation of the timer service lists and queue.
@ No params; no return value.
@ Calls 08041168; when the word 0x200062e4 is 0 it initialises two list headers
@ with 0804106c at 0x200062f8 and 0x2000630c, sets 0x200062f0=0x200062f8,
@ 0x200062ec=0x2000630c and 0x200062e4=08041b74(0xf,0xc,0) (queue of 0xf items of
@ 0xc bytes); then calls 080411b0.
@ ----------------------------------------------------------------------------
	.section .text.timer_service_init,"ax",%progbits
	.global timer_service_init
	.thumb_func
	.type timer_service_init, %function
timer_service_init:
	push {r4, r5, r7, lr}
	bl enter_critical
	movw r0, #0x62e4
	movt r0, #0x2000
	ldr r0, [r0, #0]
	cbnz r0, .L0803bc1a
	b.n .L0803bbd4
.L0803bbd4:
	movw r4, #0x62f8
	movt r4, #0x2000
	mov r0, r4
	bl list_init
	movw r5, #0x630c
	movt r5, #0x2000
	mov r0, r5
	bl list_init
	movw r0, #0x62f0
	movt r0, #0x2000
	str r4, [r0, #0]
	movw r0, #0x62ec
	movt r0, #0x2000
	str r5, [r0, #0]
	movs r0, #0xf
	movs r1, #0xc
	movs r2, #0
	bl fn_08041b74
	movw r1, #0x62e4
	movt r1, #0x2000
	str r0, [r1, #0]
	b.n .L0803bc1c
.L0803bc1a:
	b.n .L0803bc1c
.L0803bc1c:
	bl exit_critical
	pop {r4, r5, r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ free_terminated_tasks - release the records of terminated tasks.
@ No params; no return value.
@ While the word 0x200062cc is nonzero: calls 08041168, takes
@ item=*(*(0x200062a8)+0xc) (owner of the first node of the list headed at
@ 0x2000629c), unlinks item+4 with 08041024, decrements 0x20006254 and 0x200062cc,
@ calls 080411b0, then 0803bd90(item) (frees stack block and record).
@ ----------------------------------------------------------------------------
	.section .text.free_terminated_tasks,"ax",%progbits
	.global free_terminated_tasks
	.thumb_func
	.type free_terminated_tasks, %function
free_terminated_tasks:
	push {r7, lr}
	sub sp, #8
	b.n .L0803bc2a
.L0803bc2a:
	movw r0, #0x62cc
	movt r0, #0x2000
	ldr r0, [r0, #0]
	cbz r0, .L0803bc7a
	b.n .L0803bc38
.L0803bc38:
	bl enter_critical
	movw r0, #0x629c
	movt r0, #0x2000
	ldr r0, [r0, #0xc]
	ldr r0, [r0, #0xc]
	str r0, [sp, #4]
	ldr r0, [sp, #4]
	adds r0, #4
	bl list_unlink_node
	movw r0, #0x6254
	movt r0, #0x2000
	ldr r1, [r0, #0]
	subs r1, #1
	str r1, [r0, #0]
	movw r0, #0x62cc
	movt r0, #0x2000
	ldr r1, [r0, #0]
	subs r1, #1
	str r1, [r0, #0]
	bl exit_critical
	ldr r0, [sp, #4]
	bl free_task_memory
	b.n .L0803bc2a
.L0803bc7a:
	add sp, #8
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ queue_copy_out_item - copy one item out of a queue record.
@ Params r0=pointer to a queue record, r1=destination buffer; no return value.
@ If field[0x10] (item size) is nonzero: advances the read pointer field[3] by
@ field[0x10]; when field[3]>=field[2] (end) it is reset to field[0] (start); then
@ calls 080087a6(r1, field[3], field[0x10]) which copies one item from the new
@ read position into r1.
@ ----------------------------------------------------------------------------
	.section .text.queue_copy_out_item,"ax",%progbits
	.global queue_copy_out_item
	.thumb_func
	.type queue_copy_out_item, %function
queue_copy_out_item:
	push {r7, lr}
	sub sp, #8
	str r0, [sp, #4]
	str r1, [sp, #0]
	ldr r0, [sp, #4]
	ldr r0, [r0, #0x40]
	cbz r0, .L0803bcbe
	b.n .L0803bc90
.L0803bc90:
	ldr r0, [sp, #4]
	ldr r1, [r0, #0xc]
	ldr r2, [r0, #0x40]
	add r1, r2
	str r1, [r0, #0xc]
	ldr r0, [sp, #4]
	ldr r1, [r0, #8]
	ldr r0, [r0, #0xc]
	cmp r0, r1
	bcc.n .L0803bcae
	b.n .L0803bca6
.L0803bca6:
	ldr r0, [sp, #4]
	ldr r1, [r0, #0]
	str r1, [r0, #0xc]
	b.n .L0803bcb0
.L0803bcae:
	b.n .L0803bcb0
.L0803bcb0:
	ldr r0, [sp, #0]
	ldr r2, [sp, #4]
	ldr r1, [r2, #0xc]
	ldr r2, [r2, #0x40]
	bl copy_bytes_forward
	b.n .L0803bcbe
.L0803bcbe:
	add sp, #8
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ queue_copy_in_item - copy one item into a queue record.
@ Params r0=pointer to a queue record, r1=source item buffer, r2=mode; returns 0,
@ or the result of 08042934 when the item size is 0.
@ Local count = field[0xe]; if field[0x10] (item size)==0: when field[0]==0 it
@ calls 08042934(field[2]) and clears field[2], returning its result.
@ If r2==0: calls 080087a6(field[1], r1, field[0x10]) (copies the item from r1 to
@ the write pointer) and advances field[1] by field[0x10], wrapping to field[0]
@ when >=field[2].
@ Otherwise: copies the item from r1 to the read pointer field[3] with 080087a6,
@ decreases field[3] by field[0x10] and when it is below field[0] sets it to
@ field[2]-field[0x10]; when r2==2 and the count is nonzero the count is
@ decremented first.
@ Stores field[0xe]=count+1.
@ ----------------------------------------------------------------------------
	.section .text.queue_copy_in_item,"ax",%progbits
	.global queue_copy_in_item
	.thumb_func
	.type queue_copy_in_item, %function
queue_copy_in_item:
	push {r7, lr}
	sub sp, #0x18
	str r0, [sp, #0x14]
	str r1, [sp, #0x10]
	str r2, [sp, #0xc]
	movs r0, #0
	str r0, [sp, #8]
	ldr r0, [sp, #0x14]
	ldr r0, [r0, #0x38]
	str r0, [sp, #4]
	ldr r0, [sp, #0x14]
	ldr r0, [r0, #0x40]
	cbnz r0, .L0803bcfe
	b.n .L0803bce0
.L0803bce0:
	ldr r0, [sp, #0x14]
	ldr r0, [r0, #0]
	cbnz r0, .L0803bcfa
	b.n .L0803bce8
.L0803bce8:
	ldr r0, [sp, #0x14]
	ldr r0, [r0, #8]
	bl fn_08042934
	str r0, [sp, #8]
	ldr r0, [sp, #0x14]
	movs r1, #0
	str r1, [r0, #8]
	b.n .L0803bcfc
.L0803bcfa:
	b.n .L0803bcfc
.L0803bcfc:
	b.n .L0803bd82
.L0803bcfe:
	ldr r0, [sp, #0xc]
	cbnz r0, .L0803bd32
	b.n .L0803bd04
.L0803bd04:
	ldr r2, [sp, #0x14]
	ldr r1, [sp, #0x10]
	ldr r0, [r2, #4]
	ldr r2, [r2, #0x40]
	bl copy_bytes_forward
	ldr r0, [sp, #0x14]
	ldr r1, [r0, #4]
	ldr r2, [r0, #0x40]
	add r1, r2
	str r1, [r0, #4]
	ldr r0, [sp, #0x14]
	ldr r1, [r0, #4]
	ldr r0, [r0, #8]
	cmp r1, r0
	bcc.n .L0803bd2e
	b.n .L0803bd26
.L0803bd26:
	ldr r0, [sp, #0x14]
	ldr r1, [r0, #0]
	str r1, [r0, #4]
	b.n .L0803bd30
.L0803bd2e:
	b.n .L0803bd30
.L0803bd30:
	b.n .L0803bd80
.L0803bd32:
	ldr r2, [sp, #0x14]
	ldr r1, [sp, #0x10]
	ldr r0, [r2, #0xc]
	ldr r2, [r2, #0x40]
	bl copy_bytes_forward
	ldr r0, [sp, #0x14]
	ldr r1, [r0, #0xc]
	ldr r2, [r0, #0x40]
	subs r1, r1, r2
	str r1, [r0, #0xc]
	ldr r0, [sp, #0x14]
	ldr r1, [r0, #0]
	ldr r0, [r0, #0xc]
	cmp r0, r1
	bcs.n .L0803bd60
	b.n .L0803bd54
.L0803bd54:
	ldr r0, [sp, #0x14]
	ldr r1, [r0, #8]
	ldr r2, [r0, #0x40]
	subs r1, r1, r2
	str r1, [r0, #0xc]
	b.n .L0803bd62
.L0803bd60:
	b.n .L0803bd62
.L0803bd62:
	ldr r0, [sp, #0xc]
	cmp r0, #2
	bne.n .L0803bd7c
	b.n .L0803bd6a
.L0803bd6a:
	ldr r0, [sp, #4]
	cbz r0, .L0803bd78
	b.n .L0803bd70
.L0803bd70:
	ldr r0, [sp, #4]
	subs r0, #1
	str r0, [sp, #4]
	b.n .L0803bd7a
.L0803bd78:
	b.n .L0803bd7a
.L0803bd7a:
	b.n .L0803bd7e
.L0803bd7c:
	b.n .L0803bd7e
.L0803bd7e:
	b.n .L0803bd80
.L0803bd80:
	b.n .L0803bd82
.L0803bd82:
	ldr r0, [sp, #4]
	adds r0, #1
	ldr r1, [sp, #0x14]
	str r0, [r1, #0x38]
	ldr r0, [sp, #8]
	add sp, #0x18
	pop {r7, pc}

@ ----------------------------------------------------------------------------
@ waiting_list_top_priority - priority of the first waiting node of a record.
@ Param r0=record pointer; returns an int.
@ Returns 0 if the word at r0+0x24 (item count of the list header at r0+0x24) is
@ 0, otherwise 5 minus the first word of the node pointed to by the word at r0+0x30
@ (list header field [3]), i.e. the priority of the first waiting node when the
@ node key is 5-priority (0803bf44 stores 5-priority at +0x18).
@ ----------------------------------------------------------------------------
	.section .text.waiting_list_top_priority,"ax",%progbits
	.global waiting_list_top_priority
	.thumb_func
	.type waiting_list_top_priority, %function
waiting_list_top_priority:
	sub sp, #8
	str r0, [sp, #4]
	ldr r0, [sp, #4]
	ldr r0, [r0, #0x24]
	cbz r0, .L0803bdc2
	b.n .L0803bdb4
.L0803bdb4:
	ldr r0, [sp, #4]
	ldr r0, [r0, #0x30]
	ldr r0, [r0, #0]
	rsb.w r0, r0, #5
	str r0, [sp, #0]
	b.n .L0803bdc8
.L0803bdc2:
	movs r0, #0
	str r0, [sp, #0]
	b.n .L0803bdc8
.L0803bdc8:
	ldr r0, [sp, #0]
	add sp, #8
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ timer_list_next_expiry - next expiry time of the active timer list.
@ Param r0=pointer to a word; returns a time or 0.
@ Stores (*0x200062f0 == 0) into *r0 (1 when the active timer list pointed to by
@ 0x200062f0 has no items, its item count is the list's word 0); returns 0 when
@ that flag is 1, else the key (word 0) of the first node, read as
@ *(*(0x200062f0+0xc)).
@ ----------------------------------------------------------------------------
	.section .text.timer_list_next_expiry,"ax",%progbits
	.global timer_list_next_expiry
	.thumb_func
	.type timer_list_next_expiry, %function
timer_list_next_expiry:
	sub sp, #8
	str r0, [sp, #4]
	movw r0, #0x62f0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0]
	clz r0, r0
	lsrs r0, r0, #5
	ldr r1, [sp, #4]
	str r0, [r1, #0]
	ldr r0, [sp, #4]
	ldr r0, [r0, #0]
	cbnz r0, .L0803be04
	b.n .L0803bdf2
.L0803bdf2:
	movw r0, #0x62f0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0xc]
	ldr r0, [r0, #0]
	str r0, [sp, #0]
	b.n .L0803be0a
.L0803be04:
	movs r0, #0
	str r0, [sp, #0]
	b.n .L0803be0a
.L0803be0a:
	ldr r0, [sp, #0]
	add sp, #8
	bx lr

@ ----------------------------------------------------------------------------
@ idle_task_loop - body of the idle task; never returns.
@ No params; never returns.
@ Loop: calls 0803bc24 (free terminated tasks) while the item count word
@ 0x200061f0 (priority 0 ready list) is below 2; when it is 2 or more it writes
@ 0x10000000 to 0xE000ED04 (ICSR) with DSB and ISB and repeats.
@ ----------------------------------------------------------------------------
	.section .text.idle_task_loop,"ax",%progbits
	.global idle_task_loop
	.thumb_func
	.type idle_task_loop, %function
idle_task_loop:
	sub sp, #8
	str r0, [sp, #4]
	b.n .L0803bed2
.L0803bed2:
	bl free_terminated_tasks
	movw r0, #0x61f0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	cmp r0, #2
	bcc.n .L0803befe
	b.n .L0803bee6
.L0803bee6:
	movw r0, #0xed04
	movt r0, #0xe000
	mov.w r1, #0x10000000
	str r1, [r0, #0]
	dsb sy
	isb sy
	b.n .L0803bf00
.L0803befe:
	b.n .L0803bf00
.L0803bf00:
	b.n .L0803bed2
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ queue_init_fields - initialise the fields of a queue record.
@ Params r0=item count (stored at record[0xf]), r1=item size (stored at
@ record[0x10]), r2=storage base, r3 unused, stack param_5=queue record; no
@ return value.
@ Sets record[0]=record when r1==0 else r2; then calls 08041c38(record,1) (reset
@ pointers and lists).
@ ----------------------------------------------------------------------------
	.section .text.queue_init_fields,"ax",%progbits
	.global queue_init_fields
	.thumb_func
	.type queue_init_fields, %function
queue_init_fields:
	push {r7, lr}
	sub sp, #0x10
	ldr.w r12, [sp, #0x18]
	str r0, [sp, #0xc]
	str r1, [sp, #8]
	str r2, [sp, #4]
	strb.w r3, [sp, #3]
	ldr r0, [sp, #8]
	cbnz r0, .L0803bf22
	b.n .L0803bf1c
.L0803bf1c:
	ldr r0, [sp, #0x18]
	str r0, [r0, #0]
	b.n .L0803bf2a
.L0803bf22:
	ldr r0, [sp, #4]
	ldr r1, [sp, #0x18]
	str r0, [r1, #0]
	b.n .L0803bf2a
.L0803bf2a:
	ldr r0, [sp, #0xc]
	ldr r1, [sp, #0x18]
	str r0, [r1, #0x3c]
	ldr r0, [sp, #8]
	ldr r1, [sp, #0x18]
	str r0, [r1, #0x40]
	ldr r0, [sp, #0x18]
	movs r1, #1
	bl queue_reset
	add sp, #0x10
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ task_init_record - fill in a task record and build its initial stack frame.
@ Params r0=entry function, r1=name pointer, r2=stack depth in words, r3=argument,
@ stack param_5=priority, param_6=output pointer, param_7=task record (its word
@ [0xc] holds the stack block); no return value.
@ Copies up to 0x10 name bytes from r1 into record+0x34 (stopping after the zero
@ byte, byte +0x43 forced 0) or clears byte +0x34 if r1==0. Limits the priority to
@ 4 and stores it at fields 0xb and 0x11; field[0x12]=0; calls 0804109c on
@ record+4 and record+0x18; sets field[4]=field[9]=record, field[6]=5-priority,
@ field[0x13]=0, byte +0x50=0.
@ Stores 0803ceac(((field[0xc]+r2*4)-4)&~7, r0, r3) (initial stack frame, returns
@ the saved stack pointer) into field[0]; if param_6!=0 stores the record pointer
@ at *param_6.
@ Three decompiler-unreachable blocks (0x0803bf7e, 0x0803bf80, 0x0803bf94: one msr
@ basepri,#0x10, ISB, DSB, endless-loop sequence guarded by cbz at 0x0803bf7c,
@ which is always taken because the stack word was masked with bic #7) are kept in
@ place; the function contains exactly one msr basepri sequence.
@ ----------------------------------------------------------------------------
	.section .text.task_init_record,"ax",%progbits
	.global task_init_record
	.thumb_func
	.type task_init_record, %function
task_init_record:
	push {r4, lr}
	sub sp, #0x20
	ldr.w r12, [sp, #0x30]
	ldr.w r12, [sp, #0x2c]
	ldr.w r12, [sp, #0x28]
	str r0, [sp, #0x18]
	str r1, [sp, #0x14]
	str r2, [sp, #0x10]
	str r3, [sp, #0xc]
	movs r0, #0
	str r0, [sp, #8]
	ldr r0, [sp, #0x30]
	ldr r0, [r0, #0x30]
	ldr r1, [sp, #0x10]
	add.w r0, r0, r1, lsl #2
	subs r0, #4
	str r0, [sp, #4]
	ldr r0, [sp, #4]
	bic.w r0, r0, #7
	str r0, [sp, #4]
	ldrb.w r0, [sp, #4]
	lsls r0, r0, #0x1d
	cbz r0, .L0803bf96
	b.n .L0803bf80
.L0803bf80:
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	str r0, [sp, #0x1c]
	b.n .L0803bf94
.L0803bf94:
	b.n .L0803bf94
.L0803bf96:
	ldr r0, [sp, #0x14]
	cbz r0, .L0803bfdc
	b.n .L0803bf9c
.L0803bf9c:
	movs r0, #0
	str r0, [sp, #0]
	b.n .L0803bfa2
.L0803bfa2:
	ldr r0, [sp, #0]
	cmp r0, #0xf
	bhi.n .L0803bfd0
	b.n .L0803bfaa
.L0803bfaa:
	ldr r0, [sp, #0x14]
	ldr r1, [sp, #0]
	ldrb r0, [r0, r1]
	ldr r2, [sp, #0x30]
	add r1, r2
	strb.w r0, [r1, #0x34]
	ldr r0, [sp, #0x14]
	ldr r1, [sp, #0]
	ldrb r0, [r0, r1]
	cbnz r0, .L0803bfc4
	b.n .L0803bfc2
.L0803bfc2:
	b.n .L0803bfd2
.L0803bfc4:
	b.n .L0803bfc6
.L0803bfc6:
	b.n .L0803bfc8
.L0803bfc8:
	ldr r0, [sp, #0]
	adds r0, #1
	str r0, [sp, #0]
	b.n .L0803bfa2
.L0803bfd0:
	b.n .L0803bfd2
.L0803bfd2:
	ldr r0, [sp, #0x30]
	movs r1, #0
	strb.w r1, [r0, #0x43]
	b.n .L0803bfe6
.L0803bfdc:
	ldr r0, [sp, #0x30]
	movs r1, #0
	strb.w r1, [r0, #0x34]
	b.n .L0803bfe6
.L0803bfe6:
	ldr r0, [sp, #0x28]
	cmp r0, #5
	bcc.n .L0803bff4
	b.n .L0803bfee
.L0803bfee:
	movs r0, #4
	str r0, [sp, #0x28]
	b.n .L0803bff6
.L0803bff4:
	b.n .L0803bff6
.L0803bff6:
	ldr r0, [sp, #0x28]
	ldr r1, [sp, #0x30]
	str r0, [r1, #0x2c]
	ldr r0, [sp, #0x28]
	ldr r1, [sp, #0x30]
	str r0, [r1, #0x44]
	ldr r0, [sp, #0x30]
	movs r4, #0
	str r4, [r0, #0x48]
	ldr r0, [sp, #0x30]
	adds r0, #4
	bl fn_0804109c
	ldr r0, [sp, #0x30]
	adds r0, #0x18
	bl fn_0804109c
	ldr r0, [sp, #0x30]
	str r0, [r0, #0x10]
	ldr r0, [sp, #0x28]
	rsb.w r0, r0, #5
	ldr r1, [sp, #0x30]
	str r0, [r1, #0x18]
	ldr r0, [sp, #0x30]
	str r0, [r0, #0x24]
	ldr r0, [sp, #0x30]
	str r4, [r0, #0x4c]
	ldr r0, [sp, #0x30]
	strb.w r4, [r0, #0x50]
	ldr r0, [sp, #4]
	ldr r1, [sp, #0x18]
	ldr r2, [sp, #0xc]
	bl task_stack_init_frame
	ldr r1, [sp, #0x30]
	str r0, [r1, #0]
	ldr r0, [sp, #0x2c]
	cbz r0, .L0803c050
	b.n .L0803c048
.L0803c048:
	ldr r0, [sp, #0x30]
	ldr r1, [sp, #0x2c]
	str r0, [r1, #0]
	b.n .L0803c052
.L0803c050:
	b.n .L0803c052
.L0803c052:
	add sp, #0x20
	pop {r4, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ timer_init_record - fill in a timer record.
@ Params r0=name pointer, r1=period (zero loops forever), r2=reload flag,
@ r3=timer id, stack param_5=callback, stack param_6=timer record; no return value.
@ If r1==0: raises BASEPRI to 0x10 when privileged, ISB, DSB and loops forever.
@ Otherwise when the record pointer is nonzero: calls 0803bbc0, stores record[0]=r0,
@ record[6]=r1 (period), record[7]=r3, record[8]=stack param_5 (the callback,
@ ldr r0,[sp,#32] at 0x0803c0a4; r4 is not used), calls 0804109c(record+4); when
@ r2!=0 sets bit 2 (mask 4, auto-reload) in the byte at record+0x24.
@ ----------------------------------------------------------------------------
	.section .text.timer_init_record,"ax",%progbits
	.global timer_init_record
	.thumb_func
	.type timer_init_record, %function
timer_init_record:
	push {r7, lr}
	sub sp, #0x18
	ldr.w r12, [sp, #0x24]
	ldr.w r12, [sp, #0x20]
	str r0, [sp, #0x10]
	str r1, [sp, #0xc]
	str r2, [sp, #8]
	str r3, [sp, #4]
	ldr r0, [sp, #0xc]
	cbnz r0, .L0803c088
	b.n .L0803c072
.L0803c072:
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	str r0, [sp, #0x14]
	b.n .L0803c086
.L0803c086:
	b.n .L0803c086
.L0803c088:
	ldr r0, [sp, #0x24]
	cbz r0, .L0803c0ca
	b.n .L0803c08e
.L0803c08e:
	bl timer_service_init
	ldr r0, [sp, #0x10]
	ldr r1, [sp, #0x24]
	str r0, [r1, #0]
	ldr r0, [sp, #0xc]
	ldr r1, [sp, #0x24]
	str r0, [r1, #0x18]
	ldr r0, [sp, #4]
	ldr r1, [sp, #0x24]
	str r0, [r1, #0x1c]
	ldr r0, [sp, #0x20]
	ldr r1, [sp, #0x24]
	str r0, [r1, #0x20]
	ldr r0, [sp, #0x24]
	adds r0, #4
	bl fn_0804109c
	ldr r0, [sp, #8]
	cbz r0, .L0803c0c8
	b.n .L0803c0b8
.L0803c0b8:
	ldr r0, [sp, #0x24]
	ldrb.w r1, [r0, #0x24]
	orr.w r1, r1, #4
	strb.w r1, [r0, #0x24]
	b.n .L0803c0c8
.L0803c0c8:
	b.n .L0803c0ca
.L0803c0ca:
	add sp, #0x18
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ task_lists_init - initialise all task list headers.
@ No params; no return value.
@ Calls list_init (0804106c) on the five ready-list headers at 0x200061f0+i*20 for
@ i=0..4, then on 0x20006260, 0x20006274 (delayed lists), 0x20006288
@ (pending-ready list), 0x2000629c (terminated list) and 0x200062b0 (suspended
@ list); sets 0x200062c4=0x20006260 and 0x200062c8=0x20006274.
@ ----------------------------------------------------------------------------
	.section .text.task_lists_init,"ax",%progbits
	.global task_lists_init
	.thumb_func
	.type task_lists_init, %function
task_lists_init:
	push {r4, r5, r7, lr}
	sub sp, #8
	movs r0, #0
	str r0, [sp, #4]
	b.n .L0803c0da
.L0803c0da:
	ldr r0, [sp, #4]
	cmp r0, #4
	bhi.n .L0803c102
	b.n .L0803c0e2
.L0803c0e2:
	ldr r0, [sp, #4]
	add.w r0, r0, r0, lsl #2
	movw r1, #0x61f0
	movt r1, #0x2000
	add.w r0, r1, r0, lsl #2
	bl list_init
	b.n .L0803c0fa
.L0803c0fa:
	ldr r0, [sp, #4]
	adds r0, #1
	str r0, [sp, #4]
	b.n .L0803c0da
.L0803c102:
	movw r4, #0x6260
	movt r4, #0x2000
	mov r0, r4
	bl list_init
	movw r5, #0x6274
	movt r5, #0x2000
	mov r0, r5
	bl list_init
	movw r0, #0x6288
	movt r0, #0x2000
	bl list_init
	movw r0, #0x629c
	movt r0, #0x2000
	bl list_init
	movw r0, #0x62b0
	movt r0, #0x2000
	bl list_init
	movw r0, #0x62c4
	movt r0, #0x2000
	str r4, [r0, #0]
	movw r0, #0x62c8
	movt r0, #0x2000
	str r5, [r0, #0]
	add sp, #8
	pop {r4, r5, r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ timer_insert_active - insert a timer record into the active or overflow list.
@ Params r0=timer record, r1=expiry time, r2=current time, r3=command time;
@ returns bool (1 = expiry already reached).
@ Stores r1 at record+4 and the record pointer at record+0x10.
@ If r2<r1: returns 1 when r2<r3<=r1, else inserts record+4 with 080410ac into the
@ list pointed to by 0x200062f0 and returns 0.
@ Else (r1<=r2): flag=(r2-r3 < record[0x18] period); when flag is set inserts
@ record+4 into the list pointed to by 0x200062ec; returns !flag.
@ ----------------------------------------------------------------------------
	.section .text.timer_insert_active,"ax",%progbits
	.global timer_insert_active
	.thumb_func
	.type timer_insert_active, %function
timer_insert_active:
	push {r7, lr}
	sub sp, #0x18
	str r0, [sp, #0x14]
	str r1, [sp, #0x10]
	str r2, [sp, #0xc]
	str r3, [sp, #8]
	movs r0, #0
	str r0, [sp, #4]
	ldr r0, [sp, #0x10]
	ldr r1, [sp, #0x14]
	str r0, [r1, #4]
	ldr r0, [sp, #0x14]
	str r0, [r0, #0x10]
	ldr r0, [sp, #0x10]
	ldr r1, [sp, #0xc]
	cmp r0, r1
	bhi.n .L0803c274
	b.n .L0803c248
.L0803c248:
	ldr r0, [sp, #0xc]
	ldr r1, [sp, #8]
	subs r0, r0, r1
	ldr r1, [sp, #0x14]
	ldr r1, [r1, #0x18]
	cmp r0, r1
	bcc.n .L0803c25e
	b.n .L0803c258
.L0803c258:
	movs r0, #1
	str r0, [sp, #4]
	b.n .L0803c272
.L0803c25e:
	movw r0, #0x62ec
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r1, [sp, #0x14]
	adds r1, #4
	bl list_insert_sorted
	b.n .L0803c272
.L0803c272:
	b.n .L0803c2a4
.L0803c274:
	ldr r0, [sp, #0xc]
	ldr r1, [sp, #8]
	cmp r0, r1
	bcs.n .L0803c28e
	b.n .L0803c27e
.L0803c27e:
	ldr r0, [sp, #0x10]
	ldr r1, [sp, #8]
	cmp r0, r1
	bcc.n .L0803c28e
	b.n .L0803c288
.L0803c288:
	movs r0, #1
	str r0, [sp, #4]
	b.n .L0803c2a2
.L0803c28e:
	movw r0, #0x62f0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r1, [sp, #0x14]
	adds r1, #4
	bl list_insert_sorted
	b.n .L0803c2a2
.L0803c2a2:
	b.n .L0803c2a4
.L0803c2a4:
	ldr r0, [sp, #4]
	add sp, #0x18
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ queue_is_empty - test whether a queue holds no items.
@ Param r0=queue record pointer; returns bool.
@ Calls 08041168, reads the word at r0+0x38 (items waiting), calls 080411b0,
@ returns whether it was 0.
@ ----------------------------------------------------------------------------
	.section .text.queue_is_empty,"ax",%progbits
	.global queue_is_empty
	.thumb_func
	.type queue_is_empty, %function
queue_is_empty:
	push {r7, lr}
	sub sp, #8
	str r0, [sp, #4]
	bl enter_critical
	ldr r0, [sp, #4]
	ldr r0, [r0, #0x38]
	cbnz r0, .L0803c2c4
	b.n .L0803c2be
.L0803c2be:
	movs r0, #1
	str r0, [sp, #0]
	b.n .L0803c2ca
.L0803c2c4:
	movs r0, #0
	str r0, [sp, #0]
	b.n .L0803c2ca
.L0803c2ca:
	bl exit_critical
	ldr r0, [sp, #0]
	add sp, #8
	pop {r7, pc}

@ ----------------------------------------------------------------------------
@ queue_is_full - test whether a queue is at capacity.
@ Param r0=queue record pointer; returns bool.
@ Calls 08041168, reads the words at r0+0x38 (items waiting) and r0+0x3c
@ (capacity), calls 080411b0, returns whether they are equal.
@ ----------------------------------------------------------------------------
	.section .text.queue_is_full,"ax",%progbits
	.global queue_is_full
	.thumb_func
	.type queue_is_full, %function
queue_is_full:
	push {r7, lr}
	sub sp, #8
	str r0, [sp, #4]
	bl enter_critical
	ldr r0, [sp, #4]
	ldr r0, [r0, #0x38]
	ldr r1, [sp, #4]
	ldr r1, [r1, #0x3c]
	cmp r0, r1
	bne.n .L0803c2f2
	b.n .L0803c2ec
.L0803c2ec:
	movs r0, #1
	str r0, [sp, #0]
	b.n .L0803c2f8
.L0803c2f2:
	movs r0, #0
	str r0, [sp, #0]
	b.n .L0803c2f8
.L0803c2f8:
	bl exit_critical
	ldr r0, [sp, #0]
	add sp, #8
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ reset_msp_and_call_svc0 - reload the main stack pointer and enter the scheduler through SVC 0.
@ No parameters.
@ Loads the word at 0xE000ED08 (VTOR; ldr r0 via the literal at 0x0803c328), then
@ the word it points to (vector-table word 0), and writes that to MSP (msr). Writes
@ 0 to CONTROL. Enables interrupts and faults (cpsie i, cpsie f), dsb, isb, then
@ executes svc #0, followed by two nop and the literal word 0xE000ED08.
@ The code gives no continuation after the svc; whether control returns there is
@ not determined by this function.
@ ----------------------------------------------------------------------------
	.section .text.reset_msp_and_call_svc0,"ax",%progbits
	.p2align 2
	.global reset_msp_and_call_svc0
	.thumb_func
	.type reset_msp_and_call_svc0, %function
reset_msp_and_call_svc0:
	ldr r0, .L0803c328
	ldr r0, [r0, #0]
	ldr r0, [r0, #0]
	msr msp, r0
	mov.w r0, #0
	msr control, r0
	cpsie i
	cpsie f
	dsb sy
	isb sy
	svc 0
	nop
	nop
.L0803c328:
	.word 0xe000ed08	@ literal read as data by reset_msp_and_call_svc0

@ ----------------------------------------------------------------------------
@ timer_expire_first - process the first timer of the active list.
@ Params r0=expiry time of the timer, r1=current time; no return value.
@ item=*(*(0x200062f0+0xc)+0xc) (owner of the first node of the active list);
@ unlinks item+4 with 08041024.
@ If bit 2 (mask 4, auto-reload) of byte item+0x24 is set: calls
@ 0803c224(item, item[0x18]+r0, r1, r0) (r3 = r0, ldr r3,[sp,#16] at 0x0803c35c)
@ and when that returns nonzero and 08042e38(item,0,r0) returns 0 it raises
@ BASEPRI to 0x10 (when privileged), ISB, DSB and loops forever.
@ Else clears bit 0 of byte item+0x24.
@ Then calls the function pointer at item+0x20.
@ ----------------------------------------------------------------------------
	.thumb_func
	.global timer_expire_first
	.type timer_expire_first, %function
timer_expire_first:
	push {r7, lr}
	sub sp, #0x18
	str r0, [sp, #0x10]
	str r1, [sp, #0xc]
	movw r0, #0x62f0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0xc]
	ldr r0, [r0, #0xc]
	str r0, [sp, #4]
	ldr r0, [sp, #4]
	adds r0, #4
	bl list_unlink_node
	ldr r0, [sp, #4]
	ldrb.w r0, [r0, #0x24]
	lsls r0, r0, #0x1d
	cmp r0, #0
	bpl.n .L0803c39a
	b.n .L0803c35a
.L0803c35a:
	ldr r0, [sp, #4]
	ldr r3, [sp, #0x10]
	ldr r1, [r0, #0x18]
	add r1, r3
	ldr r2, [sp, #0xc]
	bl timer_insert_active
	cbz r0, .L0803c396
	b.n .L0803c36c
.L0803c36c:
	ldr r0, [sp, #4]
	ldr r2, [sp, #0x10]
	movs r1, #0
	bl fn_08042e38
	str r0, [sp, #8]
	ldr r0, [sp, #8]
	cbnz r0, .L0803c394
	b.n .L0803c37e
.L0803c37e:
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	str r0, [sp, #0x14]
	b.n .L0803c392
.L0803c392:
	b.n .L0803c392
.L0803c394:
	b.n .L0803c398
.L0803c396:
	b.n .L0803c398
.L0803c398:
	b.n .L0803c3aa
.L0803c39a:
	ldr r0, [sp, #4]
	ldrb.w r1, [r0, #0x24]
	and.w r1, r1, #0xfe
	strb.w r1, [r0, #0x24]
	b.n .L0803c3aa
.L0803c3aa:
	ldr r0, [sp, #4]
	ldr r1, [r0, #0x20]
	blx r1
	add sp, #0x18
	pop {r7, pc}

@ ----------------------------------------------------------------------------
@ timer_process_commands - timer service task: receive and execute timer commands.
@ No params; loops forever unless 080421d8(*0x200062e4,&msg,0) returns 0 (then
@ returns).
@ Message layout on the stack: local_1c=code, local_18=argument, local_14=timer
@ record; skips messages with a negative code; for each timer record calls
@ 08041024(item+4) if item[0x14]!=0, calls 0803c5dc (current time) then switches on
@ the code:
@  0,1,2,6,7 set bit 0 of byte item+0x24 and call 0803c224(item, item[0x18]+arg,
@  now, arg); when it returns nonzero the function pointer at item+0x20 is called
@  and, when bit 2 (auto-reload) of the byte is set, 08042e38(item,0,item[0x18]+arg)
@  is called (returns 0: BASEPRI 0x10 and endless loop).
@  3,8 clear bit 0.
@  4,9 set bit 0, store arg to item[0x18] (0 raises BASEPRI to 0x10 and loops
@  forever) and call 0803c224(item, arg+now, now, now).
@  5 clears bit 0 if bit 1 of byte +0x24 is set, else calls heap_free (080411e0) on
@  item.
@ ----------------------------------------------------------------------------
	.section .text.timer_process_commands,"ax",%progbits
	.global timer_process_commands
	.thumb_func
	.type timer_process_commands, %function
timer_process_commands:
	push {r7, lr}
	sub sp, #0x28
	b.n .L0803c3ba
.L0803c3ba:
	movw r0, #0x62e4
	movt r0, #0x2000
	ldr r0, [r0, #0]
	add r1, sp, #0x14
	movs r2, #0
	bl queue_receive_timeout
	cmp r0, #0
	beq.w .L0803c4fe
	b.n .L0803c3d4
.L0803c3d4:
	ldr r0, [sp, #0x14]
	cmp r0, #0
	bmi.w .L0803c4fc
	b.n .L0803c3de
.L0803c3de:
	ldr r0, [sp, #0x1c]
	str r0, [sp, #0x10]
	ldr r0, [sp, #0x10]
	ldr r0, [r0, #0x14]
	cbz r0, .L0803c3f4
	b.n .L0803c3ea
.L0803c3ea:
	ldr r0, [sp, #0x10]
	adds r0, #4
	bl list_unlink_node
	b.n .L0803c3f6
.L0803c3f4:
	b.n .L0803c3f6
.L0803c3f6:
	add r0, sp, #0xc
	bl timer_get_time_detect_wrap
	str r0, [sp, #4]
	ldr r0, [sp, #0x14]
	cmp r0, #9
	bhi.w .L0803c4f8
	tbb [pc, r0]
.L0803c40a:
	.byte (.L0803c414 - .L0803c40a)/2
	.byte (.L0803c414 - .L0803c40a)/2
	.byte (.L0803c414 - .L0803c40a)/2
	.byte (.L0803c47e - .L0803c40a)/2
	.byte (.L0803c48e - .L0803c40a)/2
	.byte (.L0803c4d0 - .L0803c40a)/2
	.byte (.L0803c414 - .L0803c40a)/2
	.byte (.L0803c414 - .L0803c40a)/2
	.byte (.L0803c47e - .L0803c40a)/2
	.byte (.L0803c48e - .L0803c40a)/2
.L0803c414:
	ldr r0, [sp, #0x10]
	ldrb.w r1, [r0, #0x24]
	orr.w r1, r1, #1
	strb.w r1, [r0, #0x24]
	ldr r0, [sp, #0x10]
	ldr r3, [sp, #0x18]
	ldr r1, [r0, #0x18]
	add r1, r3
	ldr r2, [sp, #4]
	bl timer_insert_active
	cbz r0, .L0803c47a
	b.n .L0803c434
.L0803c434:
	ldr r0, [sp, #0x10]
	ldr r1, [r0, #0x20]
	blx r1
	ldr r0, [sp, #0x10]
	ldrb.w r0, [r0, #0x24]
	lsls r0, r0, #0x1d
	cmp r0, #0
	bpl.n .L0803c476
	b.n .L0803c448
.L0803c448:
	ldr r0, [sp, #0x10]
	ldr r1, [sp, #0x18]
	ldr r2, [r0, #0x18]
	add r2, r1
	movs r1, #0
	bl fn_08042e38
	str r0, [sp, #8]
	ldr r0, [sp, #8]
	cbnz r0, .L0803c474
	b.n .L0803c45e
.L0803c45e:
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	str r0, [sp, #0x20]
	b.n .L0803c472
.L0803c472:
	b.n .L0803c472
.L0803c474:
	b.n .L0803c478
.L0803c476:
	b.n .L0803c478
.L0803c478:
	b.n .L0803c47c
.L0803c47a:
	b.n .L0803c47c
.L0803c47c:
	b.n .L0803c4fa
.L0803c47e:
	ldr r0, [sp, #0x10]
	ldrb.w r1, [r0, #0x24]
	and.w r1, r1, #0xfe
	strb.w r1, [r0, #0x24]
	b.n .L0803c4fa
.L0803c48e:
	ldr r0, [sp, #0x10]
	ldrb.w r1, [r0, #0x24]
	orr.w r1, r1, #1
	strb.w r1, [r0, #0x24]
	ldr r0, [sp, #0x18]
	ldr r1, [sp, #0x10]
	str r0, [r1, #0x18]
	ldr r0, [sp, #0x10]
	ldr r0, [r0, #0x18]
	cbnz r0, .L0803c4c0
	b.n .L0803c4aa
.L0803c4aa:
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	str r0, [sp, #0x24]
	b.n .L0803c4be
.L0803c4be:
	b.n .L0803c4be
.L0803c4c0:
	ldr r0, [sp, #0x10]
	ldr r2, [sp, #4]
	ldr r1, [r0, #0x18]
	add r1, r2
	mov r3, r2
	bl timer_insert_active
	b.n .L0803c4fa
.L0803c4d0:
	ldr r0, [sp, #0x10]
	ldrb.w r0, [r0, #0x24]
	lsls r0, r0, #0x1e
	cmp r0, #0
	bmi.n .L0803c4e6
	b.n .L0803c4de
.L0803c4de:
	ldr r0, [sp, #0x10]
	bl heap_free
	b.n .L0803c4f6
.L0803c4e6:
	ldr r0, [sp, #0x10]
	ldrb.w r1, [r0, #0x24]
	and.w r1, r1, #0xfe
	strb.w r1, [r0, #0x24]
	b.n .L0803c4f6
.L0803c4f6:
	b.n .L0803c4fa
.L0803c4f8:
	b.n .L0803c4fa
.L0803c4fa:
	b.n .L0803c4fc
.L0803c4fc:
	b.n .L0803c3ba
.L0803c4fe:
	add sp, #0x28
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ timer_service_step - one step of the timer service for a target time.
@ Params r0=target time, r1=flag; no return value.
@ Calls 08041904, then now=0803c5dc(&wrapped); if wrapped==0: when r1==0 and
@ r0<=now it calls 08042c10 and 0803c32c(r0,now); otherwise (when r1!=0 it first
@ sets r1=(*0x200062ec==0)) it calls 0804132c(*0x200062e4, r0-now, r1) and 08042c10,
@ and when that returned 0 writes 0x10000000 to 0xE000ED04 with DSB/ISB.
@ If wrapped!=0 it only calls 08042c10.
@ ----------------------------------------------------------------------------
	.section .text.timer_service_step,"ax",%progbits
	.global timer_service_step
	.thumb_func
	.type timer_service_step, %function
timer_service_step:
	push {r7, lr}
	sub sp, #0x10
	str r0, [sp, #0xc]
	str r1, [sp, #8]
	bl increment_word_200061e4
	mov r0, sp
	bl timer_get_time_detect_wrap
	str r0, [sp, #4]
	ldr r0, [sp, #0]
	cbnz r0, .L0803c594
	b.n .L0803c51e
.L0803c51e:
	ldr r0, [sp, #8]
	cbnz r0, .L0803c53c
	b.n .L0803c524
.L0803c524:
	ldr r0, [sp, #0xc]
	ldr r1, [sp, #4]
	cmp r0, r1
	bhi.n .L0803c53c
	b.n .L0803c52e
.L0803c52e:
	bl fn_08042c10
	ldr r0, [sp, #0xc]
	ldr r1, [sp, #4]
	bl timer_expire_first
	b.n .L0803c592
.L0803c53c:
	ldr r0, [sp, #8]
	cbz r0, .L0803c558
	b.n .L0803c542
.L0803c542:
	movw r0, #0x62ec
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0]
	clz r0, r0
	lsrs r0, r0, #5
	str r0, [sp, #8]
	b.n .L0803c558
.L0803c558:
	movw r0, #0x62e4
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r1, [sp, #0xc]
	ldr r2, [sp, #4]
	subs r1, r1, r2
	ldr r2, [sp, #8]
	bl fn_0804132c
	bl fn_08042c10
	cbnz r0, .L0803c58e
	b.n .L0803c576
.L0803c576:
	movw r0, #0xed04
	movt r0, #0xe000
	mov.w r1, #0x10000000
	str r1, [r0, #0]
	dsb sy
	isb sy
	b.n .L0803c590
.L0803c58e:
	b.n .L0803c590
.L0803c590:
	b.n .L0803c592
.L0803c592:
	b.n .L0803c59a
.L0803c594:
	bl fn_08042c10
	b.n .L0803c59a
.L0803c59a:
	add sp, #0x10
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ update_next_unblock_time - refresh the next unblock time word.
@ No params; no return value.
@ Sets the word 0x200062d0 to 0xffffffff when the item count (*0x200062c4) is 0,
@ else to the key (word 0) of the first node, *(0x200062c4[3]).
@ ----------------------------------------------------------------------------
	.section .text.update_next_unblock_time,"ax",%progbits
	.global update_next_unblock_time
	.thumb_func
	.type update_next_unblock_time, %function
update_next_unblock_time:
	movw r0, #0x62c4
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0]
	cbnz r0, .L0803c5c0
	b.n .L0803c5b0
.L0803c5b0:
	movw r0, #0x62d0
	movt r0, #0x2000
	mov.w r1, #0xffffffff
	str r1, [r0, #0]
	b.n .L0803c5da
.L0803c5c0:
	movw r0, #0x62c4
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0xc]
	ldr r0, [r0, #0]
	movw r1, #0x62d0
	movt r1, #0x2000
	str r0, [r1, #0]
	b.n .L0803c5da
.L0803c5da:
	bx lr

@ ----------------------------------------------------------------------------
@ timer_get_time_detect_wrap - read the current time and detect a counter wrap.
@ Param r0=pointer to a flag word; returns the current time.
@ Gets the value from 08042768 (the word at 0x200062d4); when it is below the
@ stored 0x200062f4 it calls 0803c620 and sets *r0=1, else *r0=0; stores the value
@ to 0x200062f4 and returns it.
@ ----------------------------------------------------------------------------
	.section .text.timer_get_time_detect_wrap,"ax",%progbits
	.global timer_get_time_detect_wrap
	.thumb_func
	.type timer_get_time_detect_wrap, %function
timer_get_time_detect_wrap:
	push {r7, lr}
	sub sp, #8
	str r0, [sp, #4]
	bl get_word_200062d4
	str r0, [sp, #0]
	ldr r0, [sp, #0]
	movw r1, #0x62f4
	movt r1, #0x2000
	ldr r1, [r1, #0]
	cmp r0, r1
	bcs.n .L0803c606
	b.n .L0803c5fa
.L0803c5fa:
	bl timer_process_wrap
	ldr r0, [sp, #4]
	movs r1, #1
	str r1, [r0, #0]
	b.n .L0803c60e
.L0803c606:
	ldr r0, [sp, #4]
	movs r1, #0
	str r1, [r0, #0]
	b.n .L0803c60e
.L0803c60e:
	ldr r0, [sp, #0]
	movw r1, #0x62f4
	movt r1, #0x2000
	str r0, [r1, #0]
	ldr r0, [sp, #0]
	add sp, #8
	pop {r7, pc}

@ ----------------------------------------------------------------------------
@ timer_process_wrap - process the active timer list after the time counter wrapped.
@ No params; no return value.
@ Loop: when the item count *0x200062f0 is 0 it swaps the pointers 0x200062f0 and
@ 0x200062ec and returns.
@ Otherwise takes the first node (time=*(0x200062f0[3]),
@ item=*(0x200062f0[3]+0xc)), unlinks item+4 with 08041024 and calls the function
@ pointer at item+0x20. When bit 2 (mask 4, auto-reload) of byte item+0x24 is clear
@ it continues with the next node.
@ Else computes next=time+item[0x18]; when next>time stores it at item+4,
@ item[0x10]=item and inserts item+4 with 080410ac into the list pointed to by
@ 0x200062f0; otherwise (wrap) calls 08042e38(item,0,time) and when that returns 0
@ raises BASEPRI to 0x10 (when privileged), ISB, DSB and loops forever.
@ ----------------------------------------------------------------------------
	.section .text.timer_process_wrap,"ax",%progbits
	.global timer_process_wrap
	.thumb_func
	.type timer_process_wrap, %function
timer_process_wrap:
	push {r7, lr}
	sub sp, #0x18
	b.n .L0803c626
.L0803c626:
	movw r0, #0x62f0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r0, [r0, #0]
	cmp r0, #0
	beq.n .L0803c6ce
	b.n .L0803c638
.L0803c638:
	movw r0, #0x62f0
	movt r0, #0x2000
	ldr r1, [r0, #0]
	ldr r1, [r1, #0xc]
	ldr r1, [r1, #0]
	str r1, [sp, #0x10]
	ldr r0, [r0, #0]
	ldr r0, [r0, #0xc]
	ldr r0, [r0, #0xc]
	str r0, [sp, #4]
	ldr r0, [sp, #4]
	adds r0, #4
	bl list_unlink_node
	ldr r0, [sp, #4]
	ldr r1, [r0, #0x20]
	blx r1
	ldr r0, [sp, #4]
	ldrb.w r0, [r0, #0x24]
	lsls r0, r0, #0x1d
	cmp r0, #0
	bpl.n .L0803c6ca
	b.n .L0803c66c
.L0803c66c:
	ldr r0, [sp, #0x10]
	ldr r1, [sp, #4]
	ldr r1, [r1, #0x18]
	add r0, r1
	str r0, [sp, #0xc]
	ldr r0, [sp, #0xc]
	ldr r1, [sp, #0x10]
	cmp r0, r1
	bls.n .L0803c69e
	b.n .L0803c680
.L0803c680:
	ldr r0, [sp, #0xc]
	ldr r1, [sp, #4]
	str r0, [r1, #4]
	ldr r0, [sp, #4]
	str r0, [r0, #0x10]
	movw r0, #0x62f0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r1, [sp, #4]
	adds r1, #4
	bl list_insert_sorted
	b.n .L0803c6c8
.L0803c69e:
	ldr r0, [sp, #4]
	ldr r2, [sp, #0x10]
	movs r1, #0
	bl fn_08042e38
	str r0, [sp, #0]
	ldr r0, [sp, #0]
	cbnz r0, .L0803c6c6
	b.n .L0803c6b0
.L0803c6b0:
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	str r0, [sp, #0x14]
	b.n .L0803c6c4
.L0803c6c4:
	b.n .L0803c6c4
.L0803c6c6:
	b.n .L0803c6c8
.L0803c6c8:
	b.n .L0803c6cc
.L0803c6ca:
	b.n .L0803c6cc
.L0803c6cc:
	b.n .L0803c626
.L0803c6ce:
	movw r0, #0x62f0
	movt r0, #0x2000
	ldr r1, [r0, #0]
	str r1, [sp, #8]
	movw r1, #0x62ec
	movt r1, #0x2000
	ldr r2, [r1, #0]
	str r2, [r0, #0]
	ldr r0, [sp, #8]
	str r0, [r1, #0]
	add sp, #0x18
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ task_return_trap - landing point for a task function that returns; never returns.
@ No params; never returns.
@ The address 0x0803c6f1 is stored by 0803ceac in the link register slot of every
@ new task frame, so it is reached when a task function returns.
@ Writes 0 to a local, loads the word 0x20000000, executes msr BASEPRI,#0x10, ISB,
@ DSB (unconditionally), then adds 1 to the loaded word: when the result is 0 (word
@ was 0xffffffff) it enters a loop at 0x0803c718 that tests the local, which is
@ always 0; otherwise it spins at 0x0803c714 (b .).
@ The return path at 0x0803c72a (add sp,#4; bx lr) is reachable only when the local
@ is nonzero, which cannot happen; the decompiler keeps one such block.
@ ----------------------------------------------------------------------------
	.section .text.task_return_trap,"ax",%progbits
	.global task_return_trap
	.thumb_func
	.type task_return_trap, %function
task_return_trap:
	sub sp, #4
	movs r0, #0
	str r0, [sp, #0]
	movw r0, #0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	mov.w r1, #0x10
	msr basepri, r1
	isb sy
	dsb sy
	adds r0, #1
	beq.n .L0803c724
.L0803c714:
	b.n .L0803c714
	.short 0xbf00	@ padding
.L0803c718:
	ldr r0, [sp, #0]
	cbnz r0, .L0803c72a
	ldr r0, [sp, #0]
	cbnz r0, .L0803c72a
	ldr r0, [sp, #0]
	cbnz r0, .L0803c72a
.L0803c724:
	ldr r0, [sp, #0]
	cmp r0, #0
	beq.n .L0803c718
.L0803c72a:
	add sp, #4
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ task_is_suspended - test whether a task is in the suspended list.
@ Param r0=task record pointer; returns bool.
@ If r0==0 raises BASEPRI to 0x10 (when privileged), ISB, DSB and loops forever.
@ Returns 0 unless r0[0x14] (container of the state node at +4) equals 0x200062b0
@ (suspended list) and r0[0x28] (container of the event node at +0x18) is not
@ 0x20006288 (pending-ready list); then returns (r0[0x28]==0).
@ ----------------------------------------------------------------------------
	.section .text.task_is_suspended,"ax",%progbits
	.global task_is_suspended
	.thumb_func
	.type task_is_suspended, %function
task_is_suspended:
	sub sp, #0x10
	str r0, [sp, #8]
	movs r0, #0
	str r0, [sp, #4]
	ldr r0, [sp, #8]
	str r0, [sp, #0]
	ldr r0, [sp, #8]
	cbnz r0, .L0803c758
	b.n .L0803c742
.L0803c742:
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	str r0, [sp, #0xc]
	b.n .L0803c756
.L0803c756:
	b.n .L0803c756
.L0803c758:
	ldr r0, [sp, #0]
	ldr r0, [r0, #0x14]
	movw r1, #0x62b0
	movt r1, #0x2000
	cmp r0, r1
	bne.n .L0803c792
	b.n .L0803c76a
.L0803c76a:
	ldr r0, [sp, #0]
	ldr r0, [r0, #0x28]
	movw r1, #0x6288
	movt r1, #0x2000
	cmp r0, r1
	beq.n .L0803c78e
	b.n .L0803c77c
.L0803c77c:
	ldr r0, [sp, #0]
	ldr r0, [r0, #0x28]
	cbnz r0, .L0803c78a
	b.n .L0803c784
.L0803c784:
	movs r0, #1
	str r0, [sp, #4]
	b.n .L0803c78c
.L0803c78a:
	b.n .L0803c78c
.L0803c78c:
	b.n .L0803c790
.L0803c78e:
	b.n .L0803c790
.L0803c790:
	b.n .L0803c794
.L0803c792:
	b.n .L0803c794
.L0803c794:
	ldr r0, [sp, #4]
	add sp, #0x10
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ timer_service_task - body of the timer service task; never returns.
@ Param r0 (unused); never returns.
@ Loop forever: t=0803bdd0(&flag); 0803c504(t,flag); 0803c3b4().
@ ----------------------------------------------------------------------------
	.section .text.timer_service_task,"ax",%progbits
	.global timer_service_task
	.thumb_func
	.type timer_service_task, %function
timer_service_task:
	sub sp, #0x10
	str r0, [sp, #0xc]
	b.n .L0803c7a2
.L0803c7a2:
	add r0, sp, #4
	bl timer_list_next_expiry
	str r0, [sp, #8]
	ldr r0, [sp, #8]
	ldr r1, [sp, #4]
	bl timer_service_step
	bl timer_process_commands
	b.n .L0803c7a2

@ ----------------------------------------------------------------------------
@ queue_unlock - release the lock counters of a queue and wake waiting tasks.
@ Param r0=queue record pointer; no return value.
@ Calls 08041168; count=signed byte at r0+0x45; while count>0 and the word r0[0x24]
@ (item count of the list at r0+0x24) is nonzero calls 08042b4c(r0+0x24) and, when
@ it returns nonzero, 08041424 (writes 1 to 0x200061e8), decrementing count; stores
@ 0xff to byte +0x45; calls 080411b0.
@ Repeats the same under 08041168/080411b0 with signed byte +0x44 and the list at
@ r0+0x10 (word r0[0x10]), ending with byte +0x44=0xff.
@ ----------------------------------------------------------------------------
	.section .text.queue_unlock,"ax",%progbits
	.global queue_unlock
	.thumb_func
	.type queue_unlock, %function
queue_unlock:
	push {r7, lr}
	sub sp, #8
	str r0, [sp, #4]
	bl enter_critical
	ldr r0, [sp, #4]
	ldrb.w r0, [r0, #0x45]
	strb.w r0, [sp, #3]
	b.n .L0803c7ce
.L0803c7ce:
	ldrsb.w r0, [sp, #3]
	cmp r0, #1
	blt.n .L0803c804
	b.n .L0803c7d8
.L0803c7d8:
	ldr r0, [sp, #4]
	ldr r0, [r0, #0x24]
	cbz r0, .L0803c7f6
	b.n .L0803c7e0
.L0803c7e0:
	ldr r0, [sp, #4]
	adds r0, #0x24
	bl fn_08042b4c
	cbz r0, .L0803c7f2
	b.n .L0803c7ec
.L0803c7ec:
	bl set_flag_200061e8
	b.n .L0803c7f4
.L0803c7f2:
	b.n .L0803c7f4
.L0803c7f4:
	b.n .L0803c7f8
.L0803c7f6:
	b.n .L0803c806
.L0803c7f8:
	ldrb.w r0, [sp, #3]
	subs r0, #1
	strb.w r0, [sp, #3]
	b.n .L0803c7ce
.L0803c804:
	b.n .L0803c806
.L0803c806:
	ldr r0, [sp, #4]
	movs r1, #0xff
	strb.w r1, [r0, #0x45]
	bl exit_critical
	bl enter_critical
	ldr r0, [sp, #4]
	ldrb.w r0, [r0, #0x44]
	strb.w r0, [sp, #2]
	b.n .L0803c822
.L0803c822:
	ldrsb.w r0, [sp, #2]
	cmp r0, #1
	blt.n .L0803c858
	b.n .L0803c82c
.L0803c82c:
	ldr r0, [sp, #4]
	ldr r0, [r0, #0x10]
	cbz r0, .L0803c854
	b.n .L0803c834
.L0803c834:
	ldr r0, [sp, #4]
	adds r0, #0x10
	bl fn_08042b4c
	cbz r0, .L0803c846
	b.n .L0803c840
.L0803c840:
	bl set_flag_200061e8
	b.n .L0803c848
.L0803c846:
	b.n .L0803c848
.L0803c848:
	ldrb.w r0, [sp, #2]
	subs r0, #1
	strb.w r0, [sp, #2]
	b.n .L0803c856
.L0803c854:
	b.n .L0803c85a
.L0803c856:
	b.n .L0803c822
.L0803c858:
	b.n .L0803c85a
.L0803c85a:
	ldr r0, [sp, #4]
	movs r1, #0xff
	strb.w r1, [r0, #0x44]
	bl exit_critical
	add sp, #8
	pop {r7, pc}
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ current_task_increment_field_0x48 - count an event on the current task and return it.
@ No params; returns the current task record.
@ If the word 0x200061e0 (current task) is nonzero increments the word at
@ 0x200061e0+0x48; returns 0x200061e0 (the word's value, the current task record).
@ ----------------------------------------------------------------------------
	.section .text.current_task_increment_field_0x48,"ax",%progbits
	.global current_task_increment_field_0x48
	.thumb_func
	.type current_task_increment_field_0x48, %function
current_task_increment_field_0x48:
	movw r0, #0x61e0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	cbz r0, .L0803cea0
	b.n .L0803ce8e
.L0803ce8e:
	movw r0, #0x61e0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	ldr r1, [r0, #0x48]
	adds r1, #1
	str r1, [r0, #0x48]
	b.n .L0803cea0
.L0803cea0:
	movw r0, #0x61e0
	movt r0, #0x2000
	ldr r0, [r0, #0]
	bx lr

@ ----------------------------------------------------------------------------
@ task_stack_init_frame - build the initial exception frame of a new task.
@ Params r0=stack top address, r1=entry function, r2=argument; returns the saved
@ stack pointer r0-0x44.
@ Builds the initial exception frame below r0: [r0-4]=0x01000000 (xPSR),
@ [r0-8]=r1&~1 (PC), [r0-0xc]=0x0803c6f1 (LR, task_return_trap 0x0803c6f0 with the
@ Thumb bit), [r0-0x20]=r2 (R0), [r0-0x24]=0xfffffffd (exception return value); the
@ eight words r0-0x44..r0-0x24 are left untouched.
@ ----------------------------------------------------------------------------
	.section .text.task_stack_init_frame,"ax",%progbits
	.global task_stack_init_frame
	.thumb_func
	.type task_stack_init_frame, %function
task_stack_init_frame:
	mov r3, r0
	movw r0, #:lower16:task_return_trap
	movt r0, #:upper16:task_return_trap
	mov.w r12, #0x1000000
	bic.w r1, r1, #1
	stmdb r3, {r0, r1, r12}
	mvn.w r0, #2
	str.w r0, [r3, #-0x24]
	sub.w r0, r3, #0x44
	str.w r2, [r3, #-0x20]
	bx lr

@ ----------------------------------------------------------------------------
@ list_unlink_node - remove a node from its list.
@ Param r0=list node. Unlinks the node: sets node[1]->[2]=node[2] and
@ node[2]->[1]=node[1]; if the list header (node[4]) field [1] equals the node it
@ is moved to node[2]; clears node[4]; decrements the header count word; returns
@ the new count.
@ ----------------------------------------------------------------------------
	.section .text.list_unlink_node,"ax",%progbits
	.global list_unlink_node
	.thumb_func
	.type list_unlink_node, %function
list_unlink_node:
	sub sp, #8
	str r0, [sp, #4]
	ldr r0, [sp, #4]
	ldr r0, [r0, #0x10]
	str r0, [sp, #0]
	ldr r0, [sp, #4]
	ldr r1, [r0, #4]
	ldr r0, [r0, #8]
	str r0, [r1, #8]
	ldr r0, [sp, #4]
	ldr r1, [r0, #4]
	ldr r0, [r0, #8]
	str r1, [r0, #4]
	ldr r0, [sp, #0]
	ldr r0, [r0, #4]
	ldr r1, [sp, #4]
	cmp r0, r1
	bne.n .L08041054
	b.n .L0804104a
.L0804104a:
	ldr r0, [sp, #4]
	ldr r0, [r0, #8]
	ldr r1, [sp, #0]
	str r0, [r1, #4]
	b.n .L08041056
.L08041054:
	b.n .L08041056
.L08041056:
	ldr r0, [sp, #4]
	movs r1, #0
	str r1, [r0, #0x10]
	ldr r0, [sp, #0]
	ldr r1, [r0, #0]
	subs r1, #1
	str r1, [r0, #0]
	ldr r0, [sp, #0]
	ldr r0, [r0, #0]
	add sp, #8
	bx lr

@ ----------------------------------------------------------------------------
@ list_init - initialise an empty list header.
@ Param r0=list header. Sets header[1]=header[3]=header[4]=r0+8,
@ header[2]=0xffffffff, header[0]=0 (empty list with sentinel at r0+8).
@ ----------------------------------------------------------------------------
	.section .text.list_init,"ax",%progbits
	.global list_init
	.thumb_func
	.type list_init, %function
list_init:
	sub sp, #4
	str r0, [sp, #0]
	ldr r0, [sp, #0]
	add.w r1, r0, #8
	str r1, [r0, #4]
	ldr r0, [sp, #0]
	mov.w r1, #0xffffffff
	str r1, [r0, #8]
	ldr r0, [sp, #0]
	add.w r1, r0, #8
	str r1, [r0, #0xc]
	ldr r0, [sp, #0]
	add.w r1, r0, #8
	str r1, [r0, #0x10]
	ldr r0, [sp, #0]
	movs r1, #0
	str r1, [r0, #0]
	add sp, #4
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_0804109c - clear the owner-list field of a list node.
@ Param r0=node. Writes 0 to the word at r0+0x10.
@ ----------------------------------------------------------------------------
	.section .text.fn_0804109c,"ax",%progbits
	.global fn_0804109c
	.thumb_func
	.type fn_0804109c, %function
fn_0804109c:
	sub sp, #4
	str r0, [sp, #0]
	ldr r0, [sp, #0]
	movs r1, #0
	str r1, [r0, #0x10]
	add sp, #4
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ list_insert_sorted - insert a node into a list ordered by key.
@ Params r0=list header, r1=node. Sorted insert: if node[0]==0xffffffff inserts
@ after header[4]; else walks from header+8 following word [1] until the next
@ node's key (word 0) is greater than node[0]; links the node (words 1,2), sets
@ node[4]=header and increments header[0].
@ ----------------------------------------------------------------------------
	.section .text.list_insert_sorted,"ax",%progbits
	.global list_insert_sorted
	.thumb_func
	.type list_insert_sorted, %function
list_insert_sorted:
	sub sp, #0x10
	str r0, [sp, #0xc]
	str r1, [sp, #8]
	ldr r0, [sp, #8]
	ldr r0, [r0, #0]
	str r0, [sp, #0]
	ldr r0, [sp, #0]
	adds r0, #1
	cbnz r0, .L080410c8
	b.n .L080410c0
.L080410c0:
	ldr r0, [sp, #0xc]
	ldr r0, [r0, #0x10]
	str r0, [sp, #4]
	b.n .L080410ea
.L080410c8:
	ldr r0, [sp, #0xc]
	adds r0, #8
	str r0, [sp, #4]
	b.n .L080410d0
.L080410d0:
	ldr r0, [sp, #4]
	ldr r0, [r0, #4]
	ldr r0, [r0, #0]
	ldr r1, [sp, #0]
	cmp r0, r1
	bhi.n .L080410e8
	b.n .L080410de
.L080410de:
	b.n .L080410e0
.L080410e0:
	ldr r0, [sp, #4]
	ldr r0, [r0, #4]
	str r0, [sp, #4]
	b.n .L080410d0
.L080410e8:
	b.n .L080410ea
.L080410ea:
	ldr r0, [sp, #4]
	ldr r0, [r0, #4]
	ldr r1, [sp, #8]
	str r0, [r1, #4]
	ldr r0, [sp, #8]
	ldr r1, [r0, #4]
	str r0, [r1, #8]
	ldr r0, [sp, #4]
	ldr r1, [sp, #8]
	str r0, [r1, #8]
	ldr r0, [sp, #8]
	ldr r1, [sp, #4]
	str r0, [r1, #4]
	ldr r0, [sp, #0xc]
	ldr r1, [sp, #8]
	str r0, [r1, #0x10]
	ldr r0, [sp, #0xc]
	ldr r1, [r0, #0]
	adds r1, #1
	str r1, [r0, #0]
	add sp, #0x10
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ list_insert_before_cursor - insert a node just before the list cursor.
@ Params r0=list header, r1=node. With c=header[1]: node[1]=c, node[2]=c[2],
@ c[2][1]=node, c[2]=node (inserts the node just before c in the circular list),
@ node[4]=header, increments header[0].
@ ----------------------------------------------------------------------------
	.section .text.list_insert_before_cursor,"ax",%progbits
	.global list_insert_before_cursor
	.thumb_func
	.type list_insert_before_cursor, %function
list_insert_before_cursor:
	sub sp, #0xc
	str r0, [sp, #8]
	str r1, [sp, #4]
	ldr r0, [sp, #8]
	ldr r0, [r0, #4]
	str r0, [sp, #0]
	ldr r0, [sp, #0]
	ldr r1, [sp, #4]
	str r0, [r1, #4]
	ldr r0, [sp, #0]
	ldr r0, [r0, #8]
	ldr r1, [sp, #4]
	str r0, [r1, #8]
	ldr r0, [sp, #4]
	ldr r1, [sp, #0]
	ldr r1, [r1, #8]
	str r0, [r1, #4]
	ldr r0, [sp, #4]
	ldr r1, [sp, #0]
	str r0, [r1, #8]
	ldr r0, [sp, #8]
	ldr r1, [sp, #4]
	str r0, [r1, #0x10]
	ldr r0, [sp, #8]
	ldr r1, [r0, #0]
	adds r1, #1
	str r1, [r0, #0]
	add sp, #0xc
	bx lr
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ enter_critical - enter a critical section (BASEPRI 0x10, nesting counter).
@ No params. Raises BASEPRI to 0x10 (msr BASEPRI at 0x0804116c, unconditional, no
@ privilege test in the code), ISB, DSB, then increments the nesting word at
@ 0x20000000. If the old nesting value was nonzero it returns; if it was 0 and
@ (word 0xE000ED04 & 0xff) is 0 it returns; if it was 0 and the low byte of
@ 0xE000ED04 (active exception number) is nonzero it raises BASEPRI to 0x10 again
@ and loops forever. Counterpart: 080411b0.
@ ----------------------------------------------------------------------------
	.section .text.enter_critical,"ax",%progbits
	.global enter_critical
	.thumb_func
	.type enter_critical, %function
enter_critical:
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	movw r0, #0
	movt r0, #0x2000
	ldr r1, [r0, #0]
	adds r2, r1, #1
	str r2, [r0, #0]
	cbz r1, .L0804118a
	bx lr
.L0804118a:
	movw r0, #0xed04
	movt r0, #0xe000
	ldr r0, [r0, #0]
	lsls r0, r0, #0x18
	it eq
	bxeq lr
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
	nop
.L080411ac:
	b.n .L080411ac
	.short 0x0000	@ padding

@ ----------------------------------------------------------------------------
@ exit_critical - leave a critical section (counterpart of enter_critical).
@ No params. If the nesting word 0x20000000 is 0 it raises BASEPRI to 0x10 (msr at
@ 0x080411d0, unconditional), ISB, DSB and loops forever. Otherwise it decrements
@ 0x20000000; when the result is nonzero it returns the value 0x20000000 (the
@ address left in r0; not a count); when the result is 0 it writes BASEPRI = 0 (msr
@ at 0x080411c6, unconditional) and returns 0. Counterpart of 08041168.
@ ----------------------------------------------------------------------------
	.section .text.exit_critical,"ax",%progbits
	.global exit_critical
	.thumb_func
	.type exit_critical, %function
exit_critical:
	movw r0, #0
	movt r0, #0x2000
	ldr r1, [r0, #0]
	cbz r1, .L080411cc
	subs r1, #1
	str r1, [r0, #0]
	it ne
	bxne lr
	movs r0, #0
	msr basepri, r0
	bx lr
.L080411cc:
	mov.w r0, #0x10
	msr basepri, r0
	isb sy
	dsb sy
.L080411dc:
	b.n .L080411dc
	.short 0x0000	@ padding

