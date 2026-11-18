@ fault.s - fault record: the fault exceptions (vectors 3..6) note where the processor stopped and
@ restart the meter at once. Part of the FNIRSI 2C53T firmware rewrite.
@
@ Why: V1.2.0's fault vectors were endless loops (halt_loop_0800fd34, halt_forever_08020e90,
@ halt_loop_080092d8, halt_forever_0802f310). In such a loop the timer interrupt that reloads the
@ independent watchdog (fn_0802e78c, src/system_62.s) no longer runs, so the watchdog (prescaler 4,
@ reload 0x4E1, src/system_58.s) restarted the meter about two seconds later with no trace of the
@ cause. Now the cause is kept and can be read over USB (MEM_READ, PROTOCOL.md).
@
@ Record at FAULT_ADDR (common/layout.inc; RAM that no start-up initialises, so it survives the
@ restart; lost when the power goes):
@   +0  FAULT_MAGIC              +4  IPSR (exception number: 3 hard, 4 memory, 5 bus, 6 usage fault)
@   +8  stacked PC               +12 stacked LR             +16 stacked xPSR
@   +20 CFSR 0xE000ED28          +24 HFSR 0xE000ED2C        +28 MMFAR 0xE000ED34
@   +32 BFAR 0xE000ED38          +36 stack pointer of the frame (MSP or PSP by EXC_RETURN bit 2)
@   +40 current task record (word 0x200061E0)               +44 faults counted since the record
@                                                               was first written (power-on)
@ The stack pointer, exception number and status registers are written before the frame is read:
@ when the frame itself cannot be read (stack pointer outside RAM) the processor locks up and the
@ watchdog restarts it, and the record still names the stack pointer and the cause.

	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

	.include "common/layout.inc"

	.equ	SCB_AIRCR,	0xE000ED0C
	.equ	SCB_CFSR,	0xE000ED28	@ HFSR +4, MMFAR +0x0C, BFAR +0x10
	.equ	CURRENT_TASK,	0x200061E0	@ kernel: current task record (src/storage.s)

	.section .text.fault_handler,"ax",%progbits
	.p2align 2
	.global	fault_handler
	.thumb_func
	.type	fault_handler, %function
fault_handler:
	cpsid	i
	tst	lr, #4				@ EXC_RETURN bit 2: frame on the process stack
	ite	eq
	mrseq	r0, msp
	mrsne	r0, psp				@ r0 = stacked frame r0, r1, r2, r3, r12, lr, pc, xpsr
	ldr	r1, =FAULT_ADDR
	ldr	r2, [r1, #0]			@ counter: kept while the record is valid
	ldr	r3, =FAULT_MAGIC
	cmp	r2, r3
	ite	eq
	ldreq	r2, [r1, #44]
	movne	r2, #0
	adds	r2, #1
	str	r2, [r1, #44]
	str	r3, [r1, #0]
	mrs	r2, ipsr
	str	r2, [r1, #4]
	str	r0, [r1, #36]
	ldr	r2, =CURRENT_TASK
	ldr	r2, [r2]
	str	r2, [r1, #40]
	ldr	r3, =SCB_CFSR
	ldr	r2, [r3, #0]
	str	r2, [r1, #20]
	ldr	r2, [r3, #4]
	str	r2, [r1, #24]
	ldr	r2, [r3, #0x0C]
	str	r2, [r1, #28]
	ldr	r2, [r3, #0x10]
	str	r2, [r1, #32]
	ldr	r2, [r0, #24]			@ the frame last: it may be unreadable
	str	r2, [r1, #8]
	ldr	r2, [r0, #20]
	str	r2, [r1, #12]
	ldr	r2, [r0, #28]
	str	r2, [r1, #16]
	dsb	sy
	ldr	r0, =SCB_AIRCR			@ restart now (the watchdog would do it two seconds later)
	ldr	r1, =0x05FA0004			@ VECTKEY | SYSRESETREQ
	str	r1, [r0]
	dsb	sy
1:	b	1b
	.ltorg
	.size	fault_handler, . - fault_handler
