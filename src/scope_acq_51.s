@ scope_acq_51.s - task body fn_0804009c: runs fn_08020e98 once per take of a semaphore
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0804009c - task body, no parameters, never returns.
@ Loop: semaphore_take_timeout(*0x20002d80, 0xffffffff) (blocking take with no
@ time limit) is repeated until it returns 1, then fn_08020e98() is called with
@ no arguments, then the wait starts again.
@ Purpose: runs fn_08020e98 once for every take of the semaphore-type object
@ whose handle is stored at 0x20002d80 (who gives it is not in this function).
@ ----------------------------------------------------------------------------
	.section .text.fn_0804009c,"ax",%progbits
	.global fn_0804009c
	.thumb_func
	.type fn_0804009c, %function
fn_0804009c:
	movw	r4, #0x2d80
	movt	r4, #0x2000
.L080400a4:
	ldr	r0, [r4, #0]	@ handle stored at 0x20002d80
	mov.w	r1, #0xffffffff	@ no time limit
	bl	semaphore_take_timeout
	cmp	r0, #1
	bne.n	.L080400a4	@ not taken: wait again
	bl	fn_08020e98
	b.n	.L080400a4
