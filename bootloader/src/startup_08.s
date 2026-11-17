@ startup_08.s - scatter loader, start-up chain, reset handler, fault / exception handlers, FPU+clock+VTOR init, main, NVIC / SCB helpers
@ Part of the FNIRSI 2C53T firmware rewrite: port of the stock bootloader (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ scatter_load_then_start - first code after the vector table.
@ bl 0x0800018C (region-table loop, scatter_load_regions), then bl 0x08000244
@ (enter_main). 0x0800018C ends in a call to 0x08000244 which never returns, so
@ the second bl is not reached by a return. Called by Reset_Handler through bx
@ to the literal 0x08000185 at 0x080002B0. No parameters, never returns.
@ ----------------------------------------------------------------------------
	.section .text.scatter_load_then_start,"ax",%progbits
	.p2align 2
	.global scatter_load_then_start
	.thumb_func
	.type scatter_load_then_start, %function
scatter_load_then_start:
	bl	scatter_load_regions
	bl	enter_main

@ ----------------------------------------------------------------------------
@ scatter_load_regions - region-table loop.
@ adr r0 = 0x080001B8; loads the words 0x558C (at 0x080001B8) and 0x55AC (at
@ 0x080001BC) and adds r0 = 0x080001B8 to both: table start sl = 0x08005744,
@ end fp = 0x08005764. r7 = sl-1. When sl == fp: bl 0x08000244 (0x0800019E),
@ never returns. Per entry ldmia sl!,{r0..r3} = src, dst, size, handler;
@ lr = 0x0800019B (subw lr,pc,#9 at 0x080001A2 is the adr form:
@ Align(0x080001A6,4) - 9 = 0x0800019B) so the handler returns (bx lr, bit 0
@ set) to the cmp at 0x0800019A. If handler bit0 is set it becomes r7-handler
@ (0x080001B0) else it is used as is; orr 1; bx r3. The table at 0x08005744 has
@ two entries (0x08005764,0x20000000,0x1C8,0x080001C0) and
@ (0x08005874,0x200001C8,0x1840,0x0800021C); both handlers have bit0 clear, so
@ the subne at 0x080001B0 is never executed for this image; the C shows only
@ the first call (the 0x5583 block is that never-taken relative path).
@ Clobbers r0-r3, r7, sl, fp, lr.
@ ----------------------------------------------------------------------------
	.global scatter_load_regions
	.thumb_func
	.type scatter_load_regions, %function
scatter_load_regions:
	adr	r0, .L080001b8
	ldm.w	r0, {r10, r11}
	add	r10, r0
	add	r11, r0
	sub.w	r7, r10, #1
.L0800019a:
	cmp	r10, r11
	bne.n	.L080001a2
	bl	enter_main
.L080001a2:
	adr.w	lr, .L0800019a+1
	ldm.w	r10!, {r0, r1, r2, r3}
	tst.w	r3, #1
	it	ne
	subne	r3, r7, r3
	orr.w	r3, r3, #1
	bx	r3
.L080001b8:
	.word	region_table - .L080001b8	@ 0x0000558C in the stock image
	.word	region_table_end - .L080001b8	@ 0x000055AC in the stock image

@ ----------------------------------------------------------------------------
@ unpack_literal_run_stream - decompressor handler of region table entry 0.
@ r0 = source, r1 = destination, r2 = byte count (r2 += r1 = end, ip = 0).
@ Loop per control byte c = *src++: L = c&7 (if 0 then L = *src++ at
@ 0x080001D0), R = c>>4 (if 0 then R = *src++ at 0x080001D8). Copies L-1
@ literal bytes src to dst (loop 0x080001E0). If c&8: off = *src++, copies R+2
@ bytes from dst-off to dst (0x08000210, overlapping forward byte copy); else
@ writes R zero bytes (0x080001FC). Repeats while dst < end (cmp r1,r2 at
@ 0x08000214). Returns by bx lr. Used for table entry 0 (0x08005764 ->
@ 0x20000000, 0x1C8 bytes). Clobbers r0-r6, ip.
@ unpack_literal_run_stream_addr is a plain global label on the same address:
@ the scatter-load region table holds this address as an even value.
@ ----------------------------------------------------------------------------
	.section .text.unpack_literal_run_stream,"ax",%progbits
	.p2align 2
	.global unpack_literal_run_stream
	.thumb_func
	.type unpack_literal_run_stream, %function
unpack_literal_run_stream:
	.global unpack_literal_run_stream_addr
unpack_literal_run_stream_addr:
	add	r2, r1
	mov.w	r12, #0
.L080001c6:
	ldrb.w	r3, [r0], #1
	ands.w	r4, r3, #7
	it	eq
	ldrbeq.w	r4, [r0], #1
	asrs	r5, r3, #4
	it	eq
	ldrbeq.w	r5, [r0], #1
	.inst.n	0x1e64	@ subs r4, r4, #1
	beq.n	.L080001ec
.L080001e0:
	ldrb.w	r6, [r0], #1
	.inst.n	0x1e64	@ subs r4, r4, #1
	strb.w	r6, [r1], #1
	bne.n	.L080001e0
.L080001ec:
	tst.w	r3, #8
	ittt	ne
	ldrbne.w	r4, [r0], #1
	.inst.n	0x1cad	@ addne r5, r5, #2 (16-bit T1 form, inside the IT block)
	subne	r4, r1, r4
	bne.n	.L08000210
.L080001fc:
	.inst.n	0x1e6d	@ subs r5, r5, #1
	it	pl
	strbpl.w	r12, [r1], #1
	bpl.n	.L080001fc
	b.n	.L08000214
.L08000208:
	ldrb.w	r6, [r4], #1
	strb.w	r6, [r1], #1
.L08000210:
	.inst.n	0x1e6d	@ subs r5, r5, #1
	bpl.n	.L08000208
.L08000214:
	cmp	r1, r2
	blo.n	.L080001c6
	bx	lr
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ zero_fill_region - zero-init handler of region table entry 1.
@ r1 = destination (word aligned), r2 = byte count; r0 unused (the source word
@ of the table entry). Loop at 0x08000224: subs r2,#16; if no borrow
@ stmia r1!,{r3..r6} (r3=r4=r5=r6=0) 16 zero bytes; repeats while result > 0
@ (bhi). Then lsls r2,#29: carry (bit 3) stores two zero words (stmiacs
@ r1!,{r4,r5} at 0x08000230), minus flag (bit 2) stores one zero word (strmi
@ r3,[r1] at 0x08000234). bx lr. Used for table entry 1 (0x200001C8, 0x1840
@ bytes up to 0x20001A07). Clobbers r1-r6 (r1 advances with the stores).
@ zero_fill_region_addr is a plain global label on the same address: the
@ scatter-load region table holds this address as an even value.
@ ----------------------------------------------------------------------------
	.section .text.zero_fill_region,"ax",%progbits
	.p2align 2
	.global zero_fill_region
	.thumb_func
	.type zero_fill_region, %function
zero_fill_region:
	.global zero_fill_region_addr
zero_fill_region_addr:
	movs	r3, #0
	movs	r4, #0
	movs	r5, #0
	movs	r6, #0
.L08000224:
	subs	r2, #0x10
	it	cs
	stmiacs	r1!, {r3, r4, r5, r6}
	bhi.n	.L08000224
	lsls	r2, r2, #0x1d
	it	cs
	stmiacs	r1!, {r4, r5}
	it	mi
	strmi	r3, [r1]
	bx	lr

@ ----------------------------------------------------------------------------
@ call_set_fpscr - push {r0-r4,lr}; bl 0x0800499A; pop {r0-r4,pc}.
@ 0x0800499A is mov.w r0,#0x3000000; vmsr fpscr,r0; bx lr, so FPSCR =
@ 0x03000000. r0-r4 are returned unchanged (C result CONCAT44(r1,r0)). Called
@ once from 0x0800024A with r0 = r1 = 0x20001608.
@ ----------------------------------------------------------------------------
	.section .text.call_set_fpscr,"ax",%progbits
	.p2align 2
	.global call_set_fpscr
	.thumb_func
	.type call_set_fpscr, %function
call_set_fpscr:
	push	{r0, r1, r2, r3, r4, lr}
	bl	set_fpscr_3000000
	pop	{r0, r1, r2, r3, r4, pc}

@ ----------------------------------------------------------------------------
@ return_only - push {r4,lr}; pop {r4,pc}: empty body, no memory access.
@ Called from 0x08000258 inside 0x08000256.
@ ----------------------------------------------------------------------------
	.section .text.return_only,"ax",%progbits
	.p2align 2
	.global return_only
	.thumb_func
	.type return_only, %function
return_only:
	push	{r4, lr}
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ enter_main - bl 0x080002CA (stack / heap set-up, returns r0 = r2 =
@ 0x20001608); mov r1,r2; bl 0x08000238 (FPSCR); bl 0x08002938 (main). Falls
@ through into 0x08000252 (bl 0x08000314) only if main returns. Reached from
@ 0x0800018C (end of region table) and the bl at 0x08000188. Does not return.
@ ----------------------------------------------------------------------------
	.section .text.enter_main,"ax",%progbits
	.p2align 2
	.global enter_main
	.thumb_func
	.type enter_main, %function
enter_main:
	bl	setup_stack_and_clear_16_words
	mov	r1, r2
	bl	call_set_fpscr
	bl	fn_08002938

@ ----------------------------------------------------------------------------
@ fn_08000252 - single instruction bl 0x08000314, placed directly after the bl
@ to main in 0x08000244. No flow or pointer reaches it except fall-through
@ when main returns (main 0x08002938 is a proven no-return function). Forwards
@ r0 (main's result) to 0x08000314. Never returns. Exit path after main;
@ purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.global fn_08000252
	.thumb_func
	.type fn_08000252, %function
fn_08000252:
	bl	fn_08000314

@ ----------------------------------------------------------------------------
@ fn_08000256 - push {r0,r1}; bl 0x08000240; pop {r0,r1}; bl 0x08000A04 (nop;
@ bx lr); then falls through the halfword 0x0000 at 0x08000262 into
@ Reset_Handler 0x08000264, so it restarts the whole start-up. Only caller:
@ b.w at 0x08000322 in 0x08000314, which is reached only from the unreached
@ 0x08000252. Parameters r0, r1 are saved and restored and unused. Never
@ returns. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.global fn_08000256
	.thumb_func
	.type fn_08000256, %function
fn_08000256:
	push	{r0, r1}
	bl	return_only
	pop	{r0, r1}
	bl	return_only_a04
	movs	r0, r0

@ ----------------------------------------------------------------------------
@ reset_handler - vector word 1 = 0x08000265.
@ movw/movt r0 = 0x20001000, mov sp,r0; blx [0x080002A8] = 0x08001939
@ (function 0x08001938, option-byte check per BOOTLOADER.md); ldr.w
@ sp,[0x08000000] = 0x20001A08; blx [0x080002AC] = 0x08000981 (function
@ 0x08000980, init_fpu_clock_vtor); bx [0x080002B0] = 0x08000185 (function
@ 0x08000184, scatter_load_then_start). Never returns.
@ ----------------------------------------------------------------------------
	.global reset_handler
	.thumb_func
	.type reset_handler, %function
reset_handler:
.ifndef SLOT
	movw	r0, #0x1000
	movt	r0, #0x2000
	mov	sp, r0
	ldr	r0, .L080002a8
	blx	r0
.endif
@ Slot build: the option-byte check fn_08001938 is not called (BOOTLOADER_DESIGN.md rev 2 (7): only
@ the application checks the option bytes, 0x08033F7C); the stack pointer comes from the vector table.
	movw	r0, #:lower16:vectors+0x0
	movt	r0, #:upper16:vectors+0x0
	ldr.w	sp, [r0, #0]
	ldr	r0, .L080002ac
	blx	r0
	ldr	r0, .L080002b0
	bx	r0

@ ----------------------------------------------------------------------------
@ halt_loop_286 - single instruction b . (e7fe) at its own address: infinite
@ loop. No vector word and no branch references it (vector words use
@ 0x08000299 = 0x08000298 only). Unreached, never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_286
	.thumb_func
	.type halt_loop_286, %function
halt_loop_286:
	b.n	halt_loop_286

@ ----------------------------------------------------------------------------
@ halt_loop_288 - single instruction b . (e7fe) at its own address: infinite
@ loop. No vector word and no branch references it. Unreached, never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_288
	.thumb_func
	.type halt_loop_288, %function
halt_loop_288:
	b.n	halt_loop_288

@ ----------------------------------------------------------------------------
@ halt_loop_28a - single instruction b . (e7fe) at its own address: infinite
@ loop. No vector word and no branch references it. Unreached, never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_28a
	.thumb_func
	.type halt_loop_28a, %function
halt_loop_28a:
	b.n	halt_loop_28a

@ ----------------------------------------------------------------------------
@ halt_loop_28c - single instruction b . (e7fe) at its own address: infinite
@ loop. No vector word and no branch references it. Unreached, never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_28c
	.thumb_func
	.type halt_loop_28c, %function
halt_loop_28c:
	b.n	halt_loop_28c

@ ----------------------------------------------------------------------------
@ halt_loop_28e - single instruction b . (e7fe) at its own address: infinite
@ loop. No vector word and no branch references it. Unreached, never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_28e
	.thumb_func
	.type halt_loop_28e, %function
halt_loop_28e:
	b.n	halt_loop_28e

@ ----------------------------------------------------------------------------
@ halt_loop_290 - single instruction b . (e7fe) at its own address: infinite
@ loop. No vector word and no branch references it. Unreached, never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_290
	.thumb_func
	.type halt_loop_290, %function
halt_loop_290:
	b.n	halt_loop_290

@ ----------------------------------------------------------------------------
@ halt_loop_292 - single instruction b . (e7fe) at its own address: infinite
@ loop. No vector word and no branch references it. Unreached, never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_292
	.thumb_func
	.type halt_loop_292, %function
halt_loop_292:
	b.n	halt_loop_292

@ ----------------------------------------------------------------------------
@ halt_loop_294 - single instruction b . (e7fe) at its own address: infinite
@ loop. No vector word and no branch references it. Unreached, never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_294
	.thumb_func
	.type halt_loop_294, %function
halt_loop_294:
	b.n	halt_loop_294

@ ----------------------------------------------------------------------------
@ halt_loop_296 - single instruction b . (e7fe) at its own address: infinite
@ loop. No vector word and no branch references it. Unreached, never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_296
	.thumb_func
	.type halt_loop_296, %function
halt_loop_296:
	b.n	halt_loop_296

@ ----------------------------------------------------------------------------
@ default_irq_handler - single instruction b . (e7fe): infinite loop, never
@ returns. Target of the 76 vector table words equal to 0x08000299 (NOTES.md
@ vector-table section; xxd of 0x08000000..0x08000183).
@ ----------------------------------------------------------------------------
	.global default_irq_handler
	.thumb_func
	.type default_irq_handler, %function
default_irq_handler:
	b.n	default_irq_handler
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ heap_stack_constants - ldr r0,[0x080002B4]=0x20001608; ldr
@ r1,[0x080002B8]=0x20001A08; ldr r2,[0x080002B4]=0x20001608; ldr
@ r3,[0x080002BC]=0x20001608; bx lr. Returns four values in r0..r3 (C shows a
@ 64-bit return). 0x20001A08 is also vector word 0 (initial SP). Only caller
@ 0x080002E2 in 0x080002CA. Purpose of each of the four values not determined
@ from the code. The literal words 0x080002A8..0x080002BC that follow are read
@ by Reset_Handler (function pointers at 0x080002A8, 0x080002AC, 0x080002B0)
@ and by this function (0x080002B4, 0x080002B8, 0x080002BC).
@ ----------------------------------------------------------------------------
	.global heap_stack_constants
	.thumb_func
	.type heap_stack_constants, %function
heap_stack_constants:
	ldr	r0, .L080002b4
	ldr	r1, .L080002b8
	ldr	r2, .L080002b4
	ldr	r3, .L080002bc
	bx	lr
	.short	0x0000	@ padding
.ifndef SLOT
.L080002a8:
	.word	fn_08001938	@ function pointer 0x08001939
.endif
.L080002ac:
	.word	init_fpu_clock_vtor	@ function pointer 0x08000981
.L080002b0:
	.word	scatter_load_then_start	@ function pointer 0x08000185
.L080002b4:
	.word	0x20001608
.L080002b8:
	.word	0x20001a08
.L080002bc:
	.word	0x20001608

@ ----------------------------------------------------------------------------
@ return_only_2c0 - single instruction bx lr (4770). No flow or pointer
@ reaches it (unreached). No memory access.
@ ----------------------------------------------------------------------------
	.section .text.return_only_2c0,"ax",%progbits
	.global return_only_2c0
	.thumb_func
	.type return_only_2c0, %function
return_only_2c0:
	bx	lr

@ ----------------------------------------------------------------------------
@ return_only_2c2 - single instruction bx lr (4770). No flow or pointer
@ reaches it (unreached). No memory access.
@ ----------------------------------------------------------------------------
	.section .text.return_only_2c2,"ax",%progbits
	.global return_only_2c2
	.thumb_func
	.type return_only_2c2, %function
return_only_2c2:
	bx	lr

@ ----------------------------------------------------------------------------
@ return_only_2c4 - single instruction bx lr (4770). No flow or pointer
@ reaches it (unreached). No memory access.
@ ----------------------------------------------------------------------------
	.section .text.return_only_2c4,"ax",%progbits
	.global return_only_2c4
	.thumb_func
	.type return_only_2c4, %function
return_only_2c4:
	bx	lr

@ ----------------------------------------------------------------------------
@ return_only_2c6 - single instruction bx lr (4770). No flow or pointer
@ reaches it (unreached). No memory access.
@ ----------------------------------------------------------------------------
	.section .text.return_only_2c6,"ax",%progbits
	.global return_only_2c6
	.thumb_func
	.type return_only_2c6, %function
return_only_2c6:
	bx	lr

@ ----------------------------------------------------------------------------
@ return_only_2c8 - single instruction bx lr (4770). No flow or pointer
@ reaches it (unreached). No memory access.
@ ----------------------------------------------------------------------------
	.section .text.return_only_2c8,"ax",%progbits
	.global return_only_2c8
	.thumb_func
	.type return_only_2c8, %function
return_only_2c8:
	bx	lr

@ ----------------------------------------------------------------------------
@ setup_stack_and_clear_16_words - r5 = lr; bl 0x08000328 (returns
@ 0x200015A4); lr = r5; r5 = 0x200015A4; r1 = sp; sp = (0x200015A4 & ~7) + 0x60
@ = 0x20001600. push {r5,lr}; bl 0x0800029C (r0 = r2 = r3 = 0x20001608, r1 =
@ 0x20001A08); pop {r5,lr}. r1 &= ~7 = 0x20001A08. Writes 16 zero words (stmia
@ ip!,{r6,r7,r8,fp} four times, 0x08000300..0x0800030C) at
@ 0x200015A4..0x200015E3. sp = r1 = 0x20001A08. bx lr with r0 = r2 = r3 =
@ 0x20001608. Called from 0x08000244. The C text (writes to word 0x58 / 0x5C
@ offsets) is a decompiler artefact; the instructions are the facts.
@ ----------------------------------------------------------------------------
	.section .text.setup_stack_and_clear_16_words,"ax",%progbits
	.global setup_stack_and_clear_16_words
	.thumb_func
	.type setup_stack_and_clear_16_words, %function
setup_stack_and_clear_16_words:
	mov	r5, lr
	bl	get_address_200015a4
	mov	lr, r5
	movs	r5, r0
	mov	r1, sp
	mov	r3, r10
	bic.w	r0, r0, #7
	mov	sp, r0
	add	sp, #0x60
	push	{r5, lr}
	bl	heap_stack_constants
	pop.w	{r5, lr}
	mov.w	r6, #0
	mov.w	r7, #0
	mov.w	r8, #0
	mov.w	r11, #0
	bic.w	r1, r1, #7
	mov	r12, r5
	stm.w	r12!, {r6, r7, r8, r11}
	stm.w	r12!, {r6, r7, r8, r11}
	stm.w	r12!, {r6, r7, r8, r11}
	stm.w	r12!, {r6, r7, r8, r11}
	mov	sp, r1
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08000314 - push {r4,lr}; r4 = r0; nop.w at 0x08000318; r0 = r4; pop
@ {r4,lr}; b.w 0x08000256. Only caller is the unreached bl at 0x08000252.
@ Never returns (ends in 0x08000256). Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_08000314,"ax",%progbits
	.p2align 2
	.global fn_08000314
	.thumb_func
	.type fn_08000314, %function
fn_08000314:
	push	{r4, lr}
	mov	r4, r0
	nop.w
	mov	r0, r4
	pop.w	{r4, lr}
	b.w	fn_08000256
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ get_address_200015a4 - ldr r0,[0x0800032C] = 0x200015A4; bx lr. Returns the
@ constant 0x200015A4. Only caller 0x080002CC.
@ ----------------------------------------------------------------------------
	.section .text.get_address_200015a4,"ax",%progbits
	.p2align 2
	.global get_address_200015a4
	.thumb_func
	.type get_address_200015a4, %function
get_address_200015a4:
	ldr	r0, .L0800032c
	bx	lr
.L0800032c:
	.word	0x200015a4

@ ----------------------------------------------------------------------------
@ bus_fault_handler - nop; falls into 0x08000332 (b . loop). Vector word 5
@ (offset 0x14) = 0x08000331. Never returns.
@ ----------------------------------------------------------------------------
	.section .text.bus_fault_handler,"ax",%progbits
	.global bus_fault_handler
	.thumb_func
	.type bus_fault_handler, %function
bus_fault_handler:
	nop

@ ----------------------------------------------------------------------------
@ halt_loop_332 - b . (e7fe): infinite loop, reached only by fall-through from
@ 0x08000330. Never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_332
	.thumb_func
	.type halt_loop_332, %function
halt_loop_332:
	b.n	halt_loop_332

@ ----------------------------------------------------------------------------
@ debug_monitor_handler - bx lr, no memory access. Vector word 12 (offset
@ 0x30) = 0x08000335.
@ ----------------------------------------------------------------------------
	.section .text.debug_monitor_handler,"ax",%progbits
	.global debug_monitor_handler
	.thumb_func
	.type debug_monitor_handler, %function
debug_monitor_handler:
	bx	lr

@ ----------------------------------------------------------------------------
@ hard_fault_handler - nop; falls into 0x08000338 (b . loop). Vector word 3
@ (offset 0x0C) = 0x08000337. Never returns.
@ ----------------------------------------------------------------------------
	.section .text.hard_fault_handler,"ax",%progbits
	.global hard_fault_handler
	.thumb_func
	.type hard_fault_handler, %function
hard_fault_handler:
	nop

@ ----------------------------------------------------------------------------
@ halt_loop_338 - b . (e7fe): infinite loop, reached only by fall-through from
@ 0x08000336. Never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_338
	.thumb_func
	.type halt_loop_338, %function
halt_loop_338:
	b.n	halt_loop_338
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ mem_manage_handler - nop; falls into 0x0800092E (b . loop). Vector word 4
@ (offset 0x10) = 0x0800092D. Never returns.
@ ----------------------------------------------------------------------------
	.section .text.mem_manage_handler,"ax",%progbits
	.global mem_manage_handler
	.thumb_func
	.type mem_manage_handler, %function
mem_manage_handler:
	nop

@ ----------------------------------------------------------------------------
@ halt_loop_92e - b . (e7fe): infinite loop, reached only by fall-through from
@ 0x0800092C. Never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_92e
	.thumb_func
	.type halt_loop_92e, %function
halt_loop_92e:
	b.n	halt_loop_92e

@ ----------------------------------------------------------------------------
@ nmi_handler - bx lr, no memory access. Vector word 2 (offset 0x08) =
@ 0x08000931.
@ ----------------------------------------------------------------------------
	.section .text.nmi_handler,"ax",%progbits
	.global nmi_handler
	.thumb_func
	.type nmi_handler, %function
nmi_handler:
	bx	lr

@ ----------------------------------------------------------------------------
@ pendsv_handler - bx lr, no memory access. Vector word 14 (offset 0x38) =
@ 0x08000933.
@ ----------------------------------------------------------------------------
	.section .text.pendsv_handler,"ax",%progbits
	.global pendsv_handler
	.thumb_func
	.type pendsv_handler, %function
pendsv_handler:
	bx	lr

@ ----------------------------------------------------------------------------
@ svcall_handler - bx lr, no memory access. Vector word 11 (offset 0x2C) =
@ 0x0800097D.
@ ----------------------------------------------------------------------------
	.section .text.svcall_handler,"ax",%progbits
	.global svcall_handler
	.thumb_func
	.type svcall_handler, %function
svcall_handler:
	bx	lr

@ ----------------------------------------------------------------------------
@ systick_handler - bx lr, no memory access. Vector word 15 (offset 0x3C) =
@ 0x0800097F.
@ ----------------------------------------------------------------------------
	.section .text.systick_handler,"ax",%progbits
	.global systick_handler
	.thumb_func
	.type systick_handler, %function
systick_handler:
	bx	lr

@ ----------------------------------------------------------------------------
@ init_fpu_clock_vtor - no parameters, no return value. Called from
@ Reset_Handler through the literal 0x08000981.
@ 0xE000ED88 |= 0xF00000 (CPACR, full access to coprocessors 10 and 11).
@ Word 0x40021000: clear bit 0 then add 1 (set bit 0), wait until bit 1 reads 1
@ (0x0800099C loop). Word 0x40021004 &= ~3, wait until bits 2..3 read 0
@ (0x080009B6 loop). 0x40021000 &= 0xFEF2FFFF. 0x40021004 = 0, 0x40021030 = 0,
@ 0x40021008 = 0x9F0000. 0xE000ED08 (VTOR) = 0x08000000 (r0 = r1<<15 with
@ r1 = 0x40021000).
@ ----------------------------------------------------------------------------
	.section .text.init_fpu_clock_vtor,"ax",%progbits
	.p2align 2
	.global init_fpu_clock_vtor
	.thumb_func
	.type init_fpu_clock_vtor, %function
init_fpu_clock_vtor:
	ldr	r0, .L080009e4
	ldr	r0, [r0, #0]
	orr.w	r0, r0, #0xf00000
	ldr	r1, .L080009e4
	str	r0, [r1, #0]
	ldr	r0, .L080009e8
	ldr	r0, [r0, #0]
	bic.w	r0, r0, #1
	.inst.n	0x1c40	@ adds r0, r0, #1
	ldr	r1, .L080009e8
	str	r0, [r1, #0]
	nop
.L0800099c:
	ldr	r0, .L080009e8
	ldr	r0, [r0, #0]
	ubfx	r0, r0, #1, #1
	cmp	r0, #0
	beq.n	.L0800099c
	ldr	r0, .L080009e8
	ldr	r0, [r0, #4]
	bic.w	r0, r0, #3
	ldr	r1, .L080009e8
	str	r0, [r1, #4]
	nop
.L080009b6:
	ldr	r0, .L080009e8
	ldr	r0, [r0, #4]
	ubfx	r0, r0, #2, #2
	cmp	r0, #0
	bne.n	.L080009b6
	ldr	r0, .L080009e8
	ldr	r0, [r0, #0]
	ldr	r1, .L080009ec
	ands	r0, r1
	ldr	r1, .L080009e8
	str	r0, [r1, #0]
	movs	r0, #0
	str	r0, [r1, #4]
	str	r0, [r1, #0x30]
	mov.w	r0, #0x9f0000
	str	r0, [r1, #8]
.ifdef SLOT
	ldr	r0, =vectors		@ slot build: VTOR = this image's own vector table (slot + 0x200)
.else
	lsls	r0, r1, #0xf
.endif
	ldr	r1, .L080009e4
	subs	r1, #0x80
	str	r0, [r1, #0]
	bx	lr
.L080009e4:
	.word	0xe000ed88
.L080009e8:
	.word	0x40021000
.L080009ec:
	.word	0xfef2ffff
.ifdef SLOT
	.ltorg
.endif

@ ----------------------------------------------------------------------------
@ usage_fault_handler - nop; falls into 0x08000A02 (b . loop). Vector word 6
@ (offset 0x18) = 0x08000A01. Never returns.
@ ----------------------------------------------------------------------------
	.section .text.usage_fault_handler,"ax",%progbits
	.global usage_fault_handler
	.thumb_func
	.type usage_fault_handler, %function
usage_fault_handler:
	nop

@ ----------------------------------------------------------------------------
@ halt_loop_a02 - b . (e7fe): infinite loop, reached only by fall-through from
@ 0x08000A00. Never returns.
@ ----------------------------------------------------------------------------
	.global halt_loop_a02
	.thumb_func
	.type halt_loop_a02, %function
halt_loop_a02:
	b.n	halt_loop_a02

@ ----------------------------------------------------------------------------
@ return_only_a04 - nop; bx lr. Called from 0x0800025E inside 0x08000256.
@ ----------------------------------------------------------------------------
	.section .text.return_only_a04,"ax",%progbits
	.p2align 2
	.global return_only_a04
	.thumb_func
	.type return_only_a04, %function
return_only_a04:
	nop
	bx	lr

@ ----------------------------------------------------------------------------
@ fn_08002938 - main, never returns; called from the reset path at 0x0800024e.
@ Order: 0x08002ba4(3), 0x08002bf8, 0x08001cd8, 0x0800188c, 0x0800033c,
@ 0x08000934, 0x080004b0.
@ r4 = 8 when 0x08002726(0x40011800, 4) is 0; then (r4 == 8) 0x080003f8 and
@ 0x08002726(0x40011800, 8): 0 gives r4 = 0xff, else r4 = 0.
@ When r4 == 0 calls 0x08002784(word 0x20000418). Otherwise, or when
@ 0x08002784 returns (update mode): 0x080006e0; draws "Firmware upgrade" (text
@ at 0x08002a34) with 0x080028cc(0x40, 0x6c, 0xc0, 0x18, 0x18, text, 0);
@ 0x08000564; 0x08002664(0x40011000, 0x200); waits for bit 0x100 of
@ [0x40011008] (0x08002726); 0x080018c4(10); waits for the same bit again;
@ 0x08002da8(1); 0x080016dc(0x001c0017, 1); 0x08002adc(0x14, 0, 0);
@ 0x08003886(0x200001c8, 0x40005c00, 0x200000fc, 0x20000124, 0);
@ 0x080037c0(0x200001c8).
@ Endless loop (0x08002a10..0x08002a2a): each pass calls 0x08001d2c, then when
@ bit 0x100 of [0x40011008] is clear writes 0x200 to [0x40011014]
@ (0x08002660), then repeats from the top regardless.
@ ----------------------------------------------------------------------------
	.section .text.fn_08002938,"ax",%progbits
	.p2align 2
	.global fn_08002938
	.thumb_func
	.type fn_08002938, %function
fn_08002938:
	push	{r1, r2, r3, lr}
	movs	r4, #0
	movs	r0, #3
	bl	scb_set_priority_grouping
	bl	fn_08002bf8
	bl	fn_08001cd8
	bl	fn_0800188c
	bl	gpio_init_33c
	bl	gpio_40011000_pin9_config_write_14
	bl	gpio_init_4b0
	movs	r1, #4
	ldr	r0, .L08002a2c
	bl	reg8_all_bits_set
	cbnz	r0, .L08002968
	movs	r0, #1
	b.n	.L0800296a
.L08002968:
	movs	r0, #0
.L0800296a:
	orr.w	r4, r4, r0, lsl #3
	cmp	r4, #8
	bne.n	.L08002986
	bl	gpio_init_3f8
	movs	r1, #8
	ldr	r0, .L08002a2c
	bl	reg8_all_bits_set
	cbnz	r0, .L08002984
	movs	r4, #0xff
	b.n	.L08002986
.L08002984:
	movs	r4, #0
.L08002986:
	cbnz	r4, .L08002990
	ldr	r1, .L08002a30
	ldr	r0, [r1, #4]
	bl	fn_08002784
.L08002990:
	bl	send_init_sequence_6001fffe
	movs	r0, #0
	adr	r1, .L08002a34
	movs	r2, #0x18
	mov	r3, r2
	strd	r2, r1, [sp, #0]
	str	r0, [sp, #8]
	movs	r2, #0xc0
	movs	r1, #0x6c
	movs	r0, #0x40
	bl	draw_string
	bl	gpio_40010c00_pin8_config_write_10
	mov.w	r1, #0x200
	ldr	r0, .L08002a48
	bl	write_reg_0x10
	nop
.L080029bc:
	mov.w	r1, #0x100
	ldr	r0, .L08002a48
	bl	reg8_all_bits_set
	cmp	r0, #0
	beq.n	.L080029bc
	movs	r0, #0xa
	bl	systick_delay
	nop
.L080029d2:
	mov.w	r1, #0x100
	ldr	r0, .L08002a48
	bl	reg8_all_bits_set
	cmp	r0, #0
	beq.n	.L080029d2
	movs	r0, #1
	bl	fn_08002da8
	movs	r1, #1
	ldr	r0, .L08002a4c
	bl	set_or_clear_bit_40021000_offset
	movs	r2, #0
	mov	r1, r2
	movs	r0, #0x14
	bl	nvic_set_priority_enable
	movs	r0, #0
	ldr	r3, .L08002a50
	ldr	r2, .L08002a54
	ldr	r1, .L08002a58
	str	r0, [sp, #0]
	ldr	r0, .L08002a5c
	bl	fn_08003886
	ldr	r0, .L08002a5c
	bl	fn_080037c0
.ifdef SLOT
	bl	slot_confirm		@ slot build: USB started, confirm the slot (TRIAL -> OK)
.endif
	b.n	.L08002a2a
.L08002a10:
	bl	fn_08001d2c
	mov.w	r1, #0x100
	ldr	r0, .L08002a48
	bl	reg8_all_bits_set
	cbnz	r0, .L08002a2a
	mov.w	r1, #0x200
	ldr	r0, .L08002a48
	bl	write_reg_0x14
.L08002a2a:
	b.n	.L08002a10
.L08002a2c:
	.word	0x40011800
.L08002a30:
	.word	0x20000414
.L08002a34:
	.asciz	"Firmware upgrade"
	.byte	0x00, 0x00, 0x00	@ padding
.L08002a48:
	.word	0x40011000
.L08002a4c:
	.word	0x001c0017
.L08002a50:
	.word	0x20000124
.L08002a54:
	.word	0x200000fc
.L08002a58:
	.word	0x40005c00
.L08002a5c:
	.word	0x200001c8

@ ----------------------------------------------------------------------------
@ nvic_set_priority_enable - r0 = interrupt number (signed), r1 = preemption
@ part, r2 = sub part.
@ Reads the priority grouping field (bits 10..8 of 0xe000ed0c) g; preemption
@ bits = min(7 - g, 4); sub bits = 0 when g + 4 < 7 else g - 3; value =
@ ((1 << preemption bits) - 1 & r1) << sub bits | ((1 << sub bits) - 1 & r2).
@ r0 < 0: byte at 0xe000ed14 + (r0 & 0xf) = (value & 0xf) << 4.
@ r0 >= 0: byte at 0xe000e400 + r0 = (value & 0xf) << 4 and word 0xe000e100 +
@ (r0 >> 5) * 4 = 1 << (r0 & 31).
@ Caller: 0x080029f4 (r0 = 0x14, r1 = r2 = 0).
@ ----------------------------------------------------------------------------
	.section .text.nvic_set_priority_enable,"ax",%progbits
	.p2align 2
	.global nvic_set_priority_enable
	.thumb_func
	.type nvic_set_priority_enable, %function
nvic_set_priority_enable:
	push.w	{r4, r5, r6, r7, r8, r9, r10, lr}
	mov	r3, r1
	mov	r4, r2
	mov.w	r12, #0
	nop
	ldr	r2, .L08002b9c
	ldr	r2, [r2, #0]
	ubfx	r1, r2, #8, #3
	mov	r5, r3
	mov	r6, r4
	mov	r2, r1
	rsb.w	r9, r2, #7
	cmp.w	r9, #4
	bls.n	.L08002b08
	mov.w	r9, #4
	b.n	.L08002b0c
.L08002b08:
	rsb.w	r9, r2, #7
.L08002b0c:
	mov	r8, r9
	add.w	r9, r2, #4
	cmp.w	r9, #7
	bcs.n	.L08002b1e
	mov.w	r9, #0
	b.n	.L08002b22
.L08002b1e:
	sub.w	r9, r2, #3
.L08002b22:
	mov	r7, r9
	mov.w	r9, #1
	lsl.w	r9, r9, r8
	sub.w	r9, r9, #1
	and.w	r9, r9, r5
	lsl.w	r9, r9, r7
	mov.w	r10, #1
	lsl.w	r10, r10, r7
	sub.w	r10, r10, #1
	and.w	r10, r10, r6
	orr.w	r9, r9, r10
	mov	r12, r9
	mov	r1, r0
	mov	r2, r12
	cmp	r1, #0
	blt.n	.L08002b60
	lsls	r5, r2, #0x1c
	lsrs	r6, r5, #0x18
	ldr	r5, .L08002ba0
	strb	r6, [r5, r1]
	b.n	.L08002b70
.L08002b60:
	lsls	r5, r2, #0x1c
	lsrs	r7, r5, #0x18
	ldr	r5, .L08002b9c
	adds	r5, #0xc
	and.w	r6, r1, #0xf
	.inst.n	0x1f36	@ subs r6, r6, #4
	strb	r7, [r5, r6]
.L08002b70:
	nop
	mov	r1, r0
	cmp	r1, #0
	blt.n	.L08002b94
	nop
	nop
	and.w	r5, r1, #0x1f
	movs	r2, #1
	lsls	r2, r5
	lsrs	r5, r1, #5
	lsls	r5, r5, #2
	add.w	r5, r5, #0xe000e000
	str.w	r2, [r5, #0x100]
	nop
	nop
.L08002b94:
	nop
	pop.w	{r4, r5, r6, r7, r8, r9, r10, pc}
	.short	0x0000	@ padding
.L08002b9c:
	.word	0xe000ed0c
.L08002ba0:
	.word	0xe000e400

@ ----------------------------------------------------------------------------
@ scb_set_priority_grouping - r0 = group: 0xe000ed0c = (old & 0xf8ff) |
@ 0x05fa0000 | ((r0 & 7) << 8). Caller: 0x0800293e (r0 = 3).
@ ----------------------------------------------------------------------------
	.section .text.scb_set_priority_grouping,"ax",%progbits
	.p2align 2
	.global scb_set_priority_grouping
	.thumb_func
	.type scb_set_priority_grouping, %function
scb_set_priority_grouping:
	nop
	and.w	r2, r0, #7
	ldr	r3, .L08002bc4
	ldr	r1, [r3, #0]
	movw	r3, #0xf8ff
	ands	r1, r3
	ldr	r3, .L08002bc8
	orrs	r3, r1
	orr.w	r1, r3, r2, lsl #8
	ldr	r3, .L08002bc4
	str	r1, [r3, #0]
	nop
	bx	lr
.L08002bc4:
	.word	0xe000ed0c
.L08002bc8:
	.word	0x05fa0000

.ifndef SLOT		@ not in the slot build (no option-byte code there)
@ ----------------------------------------------------------------------------
@ system_reset - dsb, then 0xe000ed0c = (old & 0x700) | 0x05fa0000 + 4
@ (request system reset), dsb, then branches to itself forever (never
@ returns). Caller: 0x08001954.
@ ----------------------------------------------------------------------------
	.section .text.system_reset,"ax",%progbits
	.p2align 2
	.global system_reset
	.thumb_func
	.type system_reset, %function
system_reset:
	nop
	dsb	sy
	ldr	r0, .L08002bf0
	ldr	r0, [r0, #0]
	and.w	r0, r0, #0x700
	ldr	r1, .L08002bf4
	orrs	r0, r1
	.inst.n	0x1d00	@ adds r0, r0, #4
	ldr	r1, .L08002bf0
	str	r0, [r1, #0]
	dsb	sy
	nop
	nop
.L08002bec:
	nop
	b.n	.L08002bec
.L08002bf0:
	.word	0xe000ed0c
.L08002bf4:
	.word	0x05fa0000
.endif

@ ----------------------------------------------------------------------------
@ set_fpscr_3000000 - writes the value 0x03000000 to the FPSCR with vmsr (sets
@ bits 25 and 24). Takes no parameter and returns nothing (the decompiled
@ return of 0x3000000 is not in the instructions: 0x0800499e vmsr fpscr, r0;
@ 0x080049a2 bx lr).
@ ----------------------------------------------------------------------------
	.section .text.set_fpscr_3000000,"ax",%progbits
	.global set_fpscr_3000000
	.thumb_func
	.type set_fpscr_3000000, %function
set_fpscr_3000000:
	mov.w	r0, #0x3000000
	vmsr	fpscr, r0
	bx	lr
