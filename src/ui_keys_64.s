@ ui_keys_64.s - key handler fn_0800a900: the "lower values" function on the state byte [0x20001060].
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_0800a900 - No parameters. Function on the state byte [0x20001060] that
@ lowers values (the mirror of 0800a148, which raises them). Queue sends use
@ queue_send_timeout (08041cf0)(queue, &item, 0xffffffff).
@ State 1: when [0x20001025]==5 and the high nibble of [0x20001055]==0xb sends
@   halfword 0x509 to queue [0x20002d74], otherwise clears [0x20001055] unless
@   its high nibble is 0xb.
@ State 2: switch on [0x2000044c]&0xf with ch=[0x2000044c]>>7:
@   0: decrements counter [0x200000fa+ch] (stops at 0; reaching 4 sets
@      [0x20000eb3]=10), re-applies with 08008a58([0x200000fb]) or
@      080088a4([0x200000fa]), sends 4 and calls 08025fc0, then only when
@      [0x2000010e]==ch (otherwise returns) rescales halfword [0x20000114] with
@      the float table at 0x0800b1e4 indexed by counter%3 (clamped +-100) and
@      sends 8 to queue [0x20002d78] when [0x2000010f]==2 and [0x20000126]!=0,
@      sends 6 when [0x2000012c]==0.
@   1: decrements offset byte [0x200000fc+ch] (min -100) and recomputes
@      0x40001c34 or 0x40007408/0x40007404 as in 0800a148, calls
@      queue_send_timeout(queue [0x20002d80],0,0), sends 5 when [0x2000012c]==0,
@      then when [0x2000010e]==ch and [0x20000114]>-100 decrements
@      [0x20000114], sends 8 to queue [0x20002d78] when [0x2000010f]==2 and
@      [0x20000126]!=0 and 6 when [0x2000012c]==0.
@   2: decrements halfword [0x20000114] to at least -100, sets
@      [0x20000122]=300, calls queue_send_timeout(queue [0x20002d80],0,0), then
@      sends 8 to queue [0x20002d78] when [0x2000010f]==2 and [0x20000126]!=0
@      and 6 when [0x2000012c]==0.
@   3: decrements by 1 a halfword selected by [0x20000332]: ==1 [0x2000032a]
@      (not below -150), ==2 [0x2000032e] (not below -100), ==3 [0x20000330]
@      when bit7 of [0x2000044c] is set else [0x2000032e] (not below -100),
@      other values return; then calls 08025fc0.
@ State 3: sub-state [0x20001061]:
@   2: with n=[0x20001063]>>4 and p=080438e0 of 10.0 and n: low nibble 2: when
@      p+1.0 (08044fac) is greater (08045de2) than [0x20000f59] stores 1 there,
@      else subtracts p from it (08045b94); nibble 1: when p is greater than
@      [0x20000f58] stores 0 there, else subtracts p; nibble 0: when p+1.0 is
@      greater than word [0x20000f54] stores 1 there, else subtracts p and
@      calls 08029d40; other nibbles change nothing; nibbles 1 and 2 then call
@      08029e14; 1 returns when [0x20001063]>1, else [0x20001063] becomes
@      [0x20001063]+1 when [0x20000f51]-1<2 and 2 otherwise.
@   0: returns when [0x20000f51]>11, else increments it, raises [0x20001062]
@      by 1 when [0x20001062]+5 is below the new value, sends 8,0x17,0x18,0x19
@      and tail-calls 08029e14.
@   Sub-states 1 and 2 then send 0x19.
@ State 4 (system settings menu, items 0..5: Sound and light, Startup on Boot,
@   Auto Shutdown, USB Sharing, About, Factory Reset): sub 0 moves the item
@   [0x20001062] down to at most 5 (V1.2.0: 6, with the language item 0), sub 1
@   raises the value [0x20001063] up to the item's limit (table .L0800b1d8);
@   codes 0x20,0x21.
@ State 5: [0x20000f14]==0 raises [0x20000f15] by 3 up to [0x20000f13]-1,
@   sends 0x27,0x28; ==1 sets [0x20000f14]=2, sends 0x2a.
@ State 6: [0x20000f14]==1 sets 2, sends 0x2a.
@ State 8: returns (V1.2.0: the language page, incremented byte [0x20001058] up
@   to 2 and sent 0x2c; there is no language page any more).
@ State 9: edits [0x20001061..63] upward (limits table 0x0800b1f0) with codes
@   0x13,0x14.
@ Other states return. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800a900,"ax",%progbits
	.p2align 2
	.global fn_0800a900
	.thumb_func
	.type fn_0800a900, %function
fn_0800a900:
	push {r4, r5, r6, r7, lr}
	sub sp, #4
	vpush {d8}
	movw r6, #0xf8
	movt r6, #0x2000
	ldrb.w r0, [r6, #0xf68]
	subs r0, #1
	cmp r0, #8
	bhi.w .L0800b1b2
	tbh [pc, r0, lsl #1]
.L0800a920:
	.short (.L0800a932 - .L0800a920)/2
	.short (.L0800a956 - .L0800a920)/2
	.short (.L0800a9a8 - .L0800a920)/2
	.short (.L0800aa3c - .L0800a920)/2
	.short (.L0800aa9a - .L0800a920)/2
	.short (.L0800aaec - .L0800a920)/2
	.short (.L0800b1b2 - .L0800a920)/2	@ state 7: return
	.short (.L0800b1b2 - .L0800a920)/2	@ state 8: return (no such page; V1.2.0: language page)
	.short (.L0800ab38 - .L0800a920)/2	@ state 9
.L0800a932:
	ldrb.w r0, [r6, #0xf2d]
	ldrb.w r1, [r6, #0xf5d]
	cmp r0, #5
	and.w r0, r1, #0xf0
	it eq
	cmpeq r0, #0xb0
	beq.w .L0800aba4
	cmp r0, #0xb0
	itt ne
	movne r0, #0
	strbne.w r0, [r6, #0xf5d]
	b.w .L0800b1b2
.L0800a956:
	ldrb.w r0, [r6, #0x354]
	and.w r1, r0, #0xf
	cmp r1, #3
	bhi.w .L0800b1b2
	tbh [pc, r1, lsl #1]
.L0800a968:
	.short (.L0800a970 - .L0800a968)/2
	.short (.L0800acca - .L0800a968)/2
	.short (.L0800ad04 - .L0800a968)/2
	.short (.L0800ad36 - .L0800a968)/2
.L0800a970:
	add.w r0, r6, r0, lsr #7
	ldrb.w r1, [r0, #2]!
	cmp r1, #0
	beq.w .L0800b1b2
	subs r1, #1
	strb r1, [r0]
	ldrb.w r0, [r6, #0x354]
	add.w r1, r6, r0, lsr #7
	ldrb r1, [r1, #2]
	sxtb r0, r0
	cmp r1, #4
	itt eq
	moveq r1, #0xa
	strbeq.w r1, [r6, #0xdbb]
	cmp.w r0, #-1
	ble.w .L0800ae38
	ldrb r0, [r6, #2]
	bl fn_080088a4
	b.n .L0800ae3e
.L0800a9a8:
	ldrb.w r0, [r6, #0xf69]
	cmp r0, #2
	beq.w .L0800abf6
	cmp r0, #1
	beq.w .L0800ac50
	cmp r0, #0
	bne.w .L0800b1b2
	ldrb.w r0, [r6, #0xe59]
	cmp r0, #0xb
	bhi.w .L0800b1b2
	ldrb.w r1, [r6, #0xf6a]
	adds r0, #1
	adds r2, r1, #5
	movw r5, #0x2d6c
	cmp r2, r0
	strb.w r0, [r6, #0xe59]
	itt cc
	addcc r0, r1, #1
	strbcc.w r0, [r6, #0xf6a]
	movw r4, #0x2d53
	movt r5, #0x2000
	movt r4, #0x2000
	movs r1, #8
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x17
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x18
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x19
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	vpop {d8}
	add sp, #4
	pop.w {r4, r5, r6, r7, lr}
	b.w fill_output_waveform_table
.L0800aa3c:
	ldrb.w r0, [r6, #0xf69]
	cmp r0, #1
	beq.w .L0800abc2
	cmp r0, #0
	bne.w .L0800b1b2
	ldrb.w r0, [r6, #0xf6a]
	and.w r1, r0, #0xf		@ system settings item 0..5
	cmp r1, #4			@ item 5 (Factory Reset) is the last
	bhi.w .L0800b1b2
	adds r1, r0, #1
	uxtb r2, r1
	movs r3, #5
	add.w r2, r3, r2, lsr #4
	and.w r3, r1, #0xf
	movw r5, #0x2d6c
	cmp r2, r3
	it cc
	addcc.w r1, r0, #0x11
	movw r4, #0x2d53
	movt r5, #0x2000
	strb.w r1, [r6, #0xf6a]
	movt r4, #0x2000
	movs r1, #0x20
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x21
	b.n .L0800ab9a
.L0800aa9a:
	ldrb.w r0, [r6, #0xe1c]
	cmp r0, #1
	beq.n .L0800aaf6
	cmp r0, #0
	bne.w .L0800b1b2
	ldrb.w r1, [r6, #0xe1d]
	ldrb.w r0, [r6, #0xe1b]
	adds r2, r1, #1
	cmp r2, r0
	bhs.w .L0800b1b2
	adds r1, #3
	uxtb r2, r1
	movw r5, #0x2d6c
	cmp r2, r0
	it cs
	subcs r1, r0, #1
	movw r4, #0x2d53
	movt r5, #0x2000
	strb.w r1, [r6, #0xe1d]
	movt r4, #0x2000
	movs r1, #0x27
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x28
	b.n .L0800ab9a
.L0800aaec:
	ldrb.w r0, [r6, #0xe1c]
	cmp r0, #1
	bne.w .L0800b1b2
.L0800aaf6:
	movs r0, #2
	strb.w r0, [r6, #0xe1c]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x2a
	b.n .L0800b00e
.L0800ab38:
	ldrb.w r0, [r6, #0xf69]
	cmp r0, #2
	beq.w .L0800ac6e
	cmp r0, #1
	beq.w .L0800ac9e
	cmp r0, #0
	bne.w .L0800b1b2
	ldrb.w r0, [r6, #0xf6a]
	and.w r1, r0, #0xf
	cmp r1, #6
	bhi.w .L0800b1b2
	adds r1, r0, #1
	uxtb r2, r1
	movs r3, #5
	add.w r2, r3, r2, lsr #4
	and.w r3, r1, #0xf
	movw r5, #0x2d6c
	cmp r2, r3
	it cc
	addcc.w r1, r0, #0x11
	movw r4, #0x2d53
	movt r5, #0x2000
	strb.w r1, [r6, #0xf6a]
	movt r4, #0x2000
	movs r1, #0x13
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x14
.L0800ab9a:
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	b.n .L0800b014
.L0800aba4:
	movw r0, #0x2d74
	movw r1, #0x2d54
	movt r0, #0x2000
	movt r1, #0x2000
	ldr r0, [r0]
	movw r3, #0x509
	mov.w r2, #0xffffffff
	strh r3, [r1]
	b.n .L0800b014
.L0800abc2:
	ldrb.w r1, [r6, #0xf6a]
	adr.w r2, .L0800b1d8
	and.w r1, r1, #0xf
	ldrb.w r0, [r6, #0xf6b]
	ldrb r1, [r2, r1]
	cmp r0, r1
	bhs.w .L0800b1b2
	adds r0, #1
	strb.w r0, [r6, #0xf6b]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x21
	b.n .L0800b00e
.L0800abf6:
	ldrb.w r7, [r6, #0xf6b]
	and.w r0, r7, #0xf
	cmp r0, #2
	beq.w .L0800ad60
	cmp r0, #1
	beq.w .L0800ada0
	cmp r0, #0
	bne.w .L0800affa
	ldr.w r0, [r6, #0xe5c]
	bl u32_to_double
	mov r4, r0
	lsrs r0, r7, #4
	mov r5, r1
	bl i32_to_double
	vmov d1, r0, r1
	vldr d0, .L0800afb0
	bl double_pow
	vmov r0, r1, d0
	vldr d0, .L0800afb8
	vmov r2, r3, d0
	bl double_add
	mov r2, r4
	mov r3, r5
	bl double_gt
	cmp r0, #0
	beq.w .L0800af1c
	movs r0, #1
	b.n .L0800af4e
.L0800ac50:
	ldrb.w r0, [r6, #0xf6b]
	cmp r0, #1
	bhi.w .L0800b1b2
	ldrb.w r1, [r6, #0xe59]
	movs r2, #2
	subs r1, #1
	cmp r1, #2
	it cc
	addcc r2, r0, #1
	strb.w r2, [r6, #0xf6b]
	b.n .L0800affa
.L0800ac6e:
	ldrb.w r0, [r6, #0xf6b]
	mvn r1, #2
	add.w r1, r1, r0, lsr #4
	cmp r1, #0xa
	bhi.w .L0800ade2
	tbh [pc, r1, lsl #1]
.L0800ac84:
	.short (.L0800b1b2 - .L0800ac84)/2
	.short (.L0800ade2 - .L0800ac84)/2
	.short (.L0800ade2 - .L0800ac84)/2
	.short (.L0800ade2 - .L0800ac84)/2
	.short (.L0800b1b2 - .L0800ac84)/2
	.short (.L0800ade2 - .L0800ac84)/2
	.short (.L0800ade2 - .L0800ac84)/2
	.short (.L0800ade2 - .L0800ac84)/2
	.short (.L0800ade2 - .L0800ac84)/2
	.short (.L0800ac9a - .L0800ac84)/2
	.short (.L0800adec - .L0800ac84)/2
.L0800ac9a:
	movs r1, #4
	b.n .L0800adee
.L0800ac9e:
	ldrb.w r1, [r6, #0xf6a]
	adr.w r2, .L0800b1f0
	and.w r1, r1, #0xf
	ldrb.w r0, [r6, #0xf6b]
	ldrb r2, [r2, r1]
	cmp r0, r2
	bhs.w .L0800b1b2
	subs r3, r1, #3
	ldrb r2, [r6, #0x14]
	cmp r3, #1
	bhi.w .L0800add4
	adds r1, #0xfe
	tst r1, r2
	bne.w .L0800adde
	b.n .L0800b1b2
.L0800acca:
	add.w r0, r6, r0, lsr #7
	ldrsb.w r1, [r0, #4]!
	cmn.w r1, #0x63
	blt.w .L0800b1b2
	subs r1, #1
	strb r1, [r0]
	ldrsb.w r0, [r6, #0x354]
	cmp.w r0, #-1
	ble.w .L0800af02
	ldrb.w r1, [r6, #0x2d]
	ldrb r0, [r6, #2]
	cmp r1, #5
	blo.w .L0800af58
	add.w r1, r6, r0, lsl #1
	add.w r0, r1, #0x29c
	add.w r1, r1, #0x260
	b.n .L0800b06c
.L0800ad04:
	ldrsh.w r0, [r6, #0x1c]
	cmn.w r0, #0x63
	blt.w .L0800b1b2
	subs r0, #1
	strh r0, [r6, #0x1c]
	movw r0, #0x2d80
	movt r0, #0x2000
	mov.w r1, #0x12c
	ldr r0, [r0]
	strh r1, [r6, #0x2a]
	movs r1, #0
	movs r2, #0
	bl queue_send_timeout
	ldrb r0, [r6, #0x17]
	cmp r0, #2
	beq.w .L0800b188
	b.n .L0800b1ac
.L0800ad36:
	ldrb.w r1, [r6, #0x23a]
	cmp r1, #3
	beq.n .L0800ae0c
	cmp r1, #2
	beq.n .L0800ae24
	cmp r1, #1
	bne.w .L0800b1b2
	ldrsh.w r0, [r6, #0x232]
	mvn r1, #0x63
	subs r1, #0x32
	cmp r0, r1
	ble.w .L0800b1b2
	subs r0, #1
	strh.w r0, [r6, #0x232]
	b.n .L0800b032
.L0800ad60:
	ldrb.w r0, [r6, #0xe61]
	bl u32_to_double
	mov r4, r0
	lsrs r0, r7, #4
	mov r5, r1
	bl i32_to_double
	vmov d1, r0, r1
	vldr d0, .L0800afb0
	bl double_pow
	vmov r0, r1, d0
	vldr d0, .L0800afb8
	vmov r2, r3, d0
	bl double_add
	mov r2, r4
	mov r3, r5
	bl double_gt
	cmp r0, #0
	beq.w .L0800af72
	movs r0, #1
	b.n .L0800afa4
.L0800ada0:
	ldrb.w r0, [r6, #0xe60]
	bl u32_to_double
	mov r4, r0
	lsrs r0, r7, #4
	mov r5, r1
	bl i32_to_double
	vmov d1, r0, r1
	vldr d0, .L0800afb0
	bl double_pow
	vmov r0, r1, d0
	mov r2, r4
	mov r3, r5
	bl double_gt
	cmp r0, #0
	beq.w .L0800afc0
	movs r0, #0
	b.n .L0800aff2
.L0800add4:
	cmp r0, #1
	it eq
	cmpeq r1, #5
	beq.w .L0800b040
.L0800adde:
	adds r0, #1
	b.n .L0800adf2
.L0800ade2:
	cmp r0, #0xaf
	bhi.w .L0800b1b2
	adds r0, #0x10
	b.n .L0800adf2
.L0800adec:
	movs r1, #8
.L0800adee:
	bfi r0, r1, #4, #0x1c
.L0800adf2:
	strb.w r0, [r6, #0xf6b]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x14
	b.n .L0800b00e
.L0800ae0c:
	lsls r0, r0, #0x18
	mvn r0, #0x63
	bmi.w .L0800b022
	ldrsh.w r1, [r6, #0x236]
	cmp r1, r0
	ble.w .L0800b1b2
	subs r0, r1, #1
	b.n .L0800ae32
.L0800ae24:
	ldrsh.w r0, [r6, #0x236]
	cmn.w r0, #0x63
	blt.w .L0800b1b2
	subs r0, #1
.L0800ae32:
	strh.w r0, [r6, #0x236]
	b.n .L0800b032
.L0800ae38:
	ldrb r0, [r6, #3]
	bl fn_08008a58
.L0800ae3e:
	movw r5, #0x2d6c
	movw r4, #0x2d53
	movt r5, #0x2000
	movt r4, #0x2000
	movs r1, #4
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	bl fn_08025fc0
	ldrb r0, [r6, #0x16]
	ldrb.w r1, [r6, #0x354]
	cmp.w r0, r1, lsr #7
	bne.w .L0800b1b2
	add r0, r6
	ldrsb.w r2, [r0, #4]
	ldrb r0, [r0, #2]
	movw r3, #0xaaab
	movt r3, #0xaaaa
	umull r3, r7, r0, r3
	ldrh r1, [r6, #0x1c]
	lsrs r3, r7, #1
	add.w r3, r3, r3, lsl #1
	subs r1, r1, r2
	subs r0, r0, r3
	adr r3, .L0800b1e4
	sxth r1, r1
	add.w r0, r3, r0, lsl #2
	vldr s0, [r0]
	vmov s2, r1
	vcvt.f32.s32 s2, s2
	vmul.f32 s0, s0, s2
	vcvt.s32.f32 s0, s0
	vmov r0, s0
	add r0, r2
	sxth r1, r0
	cmp r1, #0x64
	it ge
	movge r0, #0x64
	sxth r1, r0
	cmn.w r1, #0x64
	ldrb r1, [r6, #0x17]
	it le
	mvnle r0, #0x63
	cmp r1, #2
	strh r0, [r6, #0x1c]
	bne.n .L0800aef2
	ldrb.w r0, [r6, #0x2e]
	cbz r0, .L0800aef2
	movw r0, #0x2d78
	movw r1, #0x2d52
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #8
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L0800aef2:
	ldrb.w r0, [r6, #0x34]
	cmp r0, #0
	bne.w .L0800b1b2
	ldr r0, [r5]
	movs r3, #6
	b.n .L0800ab9a
.L0800af02:
	ldrb.w r1, [r6, #0x2d]
	ldrb r0, [r6, #3]
	cmp r1, #5
	blo.w .L0800b048
	add.w r1, r6, r0, lsl #1
	add.w r0, r1, #0x314
	add.w r1, r1, #0x2d8
	b.n .L0800b0d0
.L0800af1c:
	ldrb.w r0, [r6, #0xf6b]
	lsrs r0, r0, #4
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0800b1d0
	bl double_pow
	ldr.w r0, [r6, #0xe5c]
	vmov.f32 s16, s0
	vmov.f32 s17, s1
	bl u32_to_double
	vmov r2, r3, d8
	bl double_sub
	bl double_to_u32
.L0800af4e:
	str.w r0, [r6, #0xe5c]
	bl fn_08029d40
	b.n .L0800affa
.L0800af58:
	cmp r1, #4
	beq.w .L0800b060
	ldrb r1, [r6, #0x14]
	cmp r1, #3
	beq.n .L0800b060
	add.w r1, r6, r0, lsl #1
	add.w r0, r1, #0x2c4
	add.w r1, r1, #0x288
	b.n .L0800b06c
.L0800af72:
	ldrb.w r0, [r6, #0xf6b]
	lsrs r0, r0, #4
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0800b1d0
	bl double_pow
	ldrb.w r0, [r6, #0xe61]
	vmov.f32 s16, s0
	vmov.f32 s17, s1
	bl u32_to_double
	vmov r2, r3, d8
	bl double_sub
	bl double_to_i32
.L0800afa4:
	strb.w r0, [r6, #0xe61]
	b.n .L0800aff6
	.short 0xbf00	@ padding
	.short 0xbf00	@ padding
	.short 0xbf00	@ padding
.L0800afb0:
	.word 0x00000000, 0x40240000	@ double 10.0
.L0800afb8:
	.word 0x00000000, 0x3ff00000	@ double 1.0
.L0800afc0:
	ldrb.w r0, [r6, #0xf6b]
	lsrs r0, r0, #4
	bl u32_to_double
	vmov d1, r0, r1
	vldr d0, .L0800b1d0
	bl double_pow
	ldrb.w r0, [r6, #0xe60]
	vmov.f32 s16, s0
	vmov.f32 s17, s1
	bl u32_to_double
	vmov r2, r3, d8
	bl double_sub
	bl double_to_i32
.L0800aff2:
	strb.w r0, [r6, #0xe60]
.L0800aff6:
	bl fill_output_waveform_table
.L0800affa:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x19
.L0800b00e:
	mov.w r2, #0xffffffff
	strb r3, [r1]
.L0800b014:
	vpop {d8}
	add sp, #4
	pop.w {r4, r5, r6, r7, lr}
	b.w queue_send_timeout
.L0800b022:
	ldrsh.w r1, [r6, #0x238]
	cmp r1, r0
	ble.w .L0800b1b2
	subs r0, r1, #1
	strh.w r0, [r6, #0x238]
.L0800b032:
	vpop {d8}
	add sp, #4
	pop.w {r4, r5, r6, r7, lr}
	b.w fn_08025fc0
.L0800b040:
	cmp r2, #3
	bne.w .L0800b1b2
	b.n .L0800adde
.L0800b048:
	cmp r1, #4
	beq.n .L0800b0c4
	ldrb r1, [r6, #0x14]
	cmp r1, #3
	beq.n .L0800b0c4
	add.w r1, r6, r0, lsl #1
	add.w r0, r1, #0x33c
	add.w r1, r1, #0x300
	b.n .L0800b0d0
.L0800b060:
	add.w r1, r6, r0, lsl #1
	add.w r0, r1, #0x2b0
	add.w r1, r1, #0x274
.L0800b06c:
	ldrh r0, [r0]
	ldrh r1, [r1]
	vldr s2, .L0800b1e0
	subs r0, r0, r1
	vmov s0, r0
	vcvt.f32.s32 s0, s0
	vdiv.f32 s0, s0, s2
	ldrsb.w r0, [r6, #4]
	adds r0, #0x64
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	movw r0, #0x7404
	movt r0, #0x4000
	vmul.f32 s0, s0, s2
	vmov s2, r1
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	ldr r1, [r0, #4]
	vcvt.u32.f32 s0, s0
	vmov r2, s0
	lsrs r1, r1, #0xc
	bfi r2, r1, #0xc, #0x14
	str r2, [r0, #4]
	ldr r1, [r0]
	orr.w r1, r1, #1
	str r1, [r0]
	b.n .L0800b114
.L0800b0c4:
	add.w r1, r6, r0, lsl #1
	add.w r0, r1, #0x328
	add.w r1, r1, #0x2ec
.L0800b0d0:
	ldrh r0, [r0]
	ldrh r1, [r1]
	vldr s2, .L0800b1e0
	subs r0, r0, r1
	vmov s0, r0
	vcvt.f32.s32 s0, s0
	vdiv.f32 s0, s0, s2
	ldrsb.w r0, [r6, #5]
	adds r0, #0x64
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	movw r0, #0x1c34
	movt r0, #0x4000
	vmul.f32 s0, s0, s2
	vmov s2, r1
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vstr s0, [r0]
.L0800b114:
	ldrb.w r0, [r6, #0x2e]
	cbz r0, .L0800b130
	ldrb.w r0, [r6, #0x2d]
	movs r1, #0x64
	cmp r0, #0x14
	strb.w r1, [r6, #0x2c]
	itt cs
	movwcs r0, #0x12d
	strcs.w r0, [r6, #0xdb4]
.L0800b130:
	movw r0, #0x2d80
	movt r0, #0x2000
	ldr r0, [r0]
	movs r1, #0
	movs r2, #0
	bl queue_send_timeout
	ldrb.w r0, [r6, #0x34]
	cbnz r0, .L0800b166
	movw r0, #0x2d6c
	movw r1, #0x2d53
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #5
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L0800b166:
	ldrb.w r0, [r6, #0x354]
	ldrb r1, [r6, #0x16]
	cmp.w r1, r0, lsr #7
	bne.n .L0800b1b2
	ldrsh.w r0, [r6, #0x1c]
	mvn r1, #0x63
	cmp r0, r1
	ble.n .L0800b1b2
	ldrb r1, [r6, #0x17]
	subs r0, #1
	cmp r1, #2
	strh r0, [r6, #0x1c]
	bne.n .L0800b1ac
.L0800b188:
	ldrb.w r0, [r6, #0x2e]
	cbz r0, .L0800b1ac
	movw r0, #0x2d78
	movw r1, #0x2d52
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #8
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L0800b1ac:
	ldrb.w r0, [r6, #0x34]
	cbz r0, .L0800b1ba
.L0800b1b2:
	vpop {d8}
	add sp, #4
	pop {r4, r5, r6, r7, pc}
.L0800b1ba:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #6
	b.n .L0800b00e
.L0800b1d0:
	.word 0x00000000, 0x40240000	@ double 10.0
.L0800b1d8:
	@ limit table (state 4, indexed by the system settings item [0x20001062]&0xf):
	@ highest value [0x20001063] of item 0 Sound and light (row 0 / 1), 1 Startup on
	@ Boot (4 choices), 2 Auto Shutdown (4 choices), 3 USB Sharing, 4 About, 5 Factory
	@ Reset (2 buttons); bytes 6, 7 belong to no item (V1.2.0 had the language item 0,
	@ limit 1, in front)
	.byte 0x01, 0x03, 0x03, 0x00, 0x00, 0x01, 0x00, 0x00
.L0800b1e0:
	.word 0x43480000	@ float 200.0
.L0800b1e4:
	.word 0x40000000, 0x40200000, 0x40000000	@ floats 2.0, 2.5, 2.0 (indexed by counter%3)
.L0800b1f0:
	.byte 0x01, 0x01, 0x01, 0x03, 0x03, 0x02, 0x03, 0x08	@ limit table (state 9, indexed by [0x20001062]&0xf)

@ ----------------------------------------------------------------------------
@ fn_0800b1f8 - No parameters. Function on the state byte [0x20001060]; the
@ mirror of 0800b7cc (this one moves indices down in states 0/1, up in
@ state 2 sub 0). Queue sends use queue_send_timeout (08041cf0).
@ State 0: decrements [0x20001061] (0 wraps to 3), sends 0xb,0xc,0xf,0x10,0x11
@   to queue [0x20002d6c].
@ State 1: returns when the high nibble of [0x20001055] is 0xb; idx=
@   [0x20001025]-1 (0 wraps to 7), sends the halfword (table byte at
@   0x080bb3fc+idx plus 0x500) to queue [0x20002d74], clears [0x20001055],
@   stores idx in [0x20001025], sends 0x1d and 0x1b, sets [0x2000102e]=idx if
@   idx==2 else 1, [0x20001040..48]=0x7fc00000, clears [0x20001034] and
@   [0x20001035] (sending 0x1a when it was set) and tail-calls 080098e0.
@ State 2: [0x2000044c]&0xf = 1 or 2: 0803b2f8(-1,-1) then 08025fc0; =3:
@   lowers by 1 a halfword selected by [0x20000332]: ==1 [0x2000032c] (not
@   below -150), ==2 [0x20000330] (not below -100), ==3 [0x2000032c] when bit7
@   of [0x2000044c] is set else [0x2000032a] (not below -150), other values
@   return; then calls queue_send_timeout(queue [0x20002d80],0,0) and
@   08025fc0; =0: when [0x20000125]<=0x1b increments it, recomputes
@   0x40007408/0x40007404 and 0x40001c34 from the halfword tables, when
@   [0x20000126]!=0 programs 0x40000400, 0x40000414, 0x40000424..0x4000042c
@   and [0x20000eac] (with 08031430 and table 0x080465a4 for index>=0x14),
@   calls 08030a70 and 0803b2f8(0,0), writes 4 to 0x40011410, sends 2 to queue
@   [0x20002d6c] and 1 to queue [0x20002d78], then 08025fc0.
@ State 3: when [0x20001061]==2 adds 0x10 to [0x20001063] within limits
@   (0x40, 0x20) and sends 0x19.
@ State 4: when [0x20001061]==1 and [0x20001062]&0xf==0 (system settings item
@   Sound and light; 1 in V1.2.0, which had the language item 0) lowers byte
@   [0x2000105a] by 1 when nonzero ([0x20001063]==0) or otherwise byte
@   [0x20001059] by 5 when it is at least 26 (written to 0x40015034) and
@   sends 0x21.
@ State 5: lowers [0x20000f15] (sends 0x27,0x28).
@ State 6: lowers [0x20000f15] (sends 0x29).
@ State 9: lowers [0x20001063] (by 0x40 or 4) and sends 0x14.
@ Other states return. Purpose not determined from the code.
@ ----------------------------------------------------------------------------
	.section .text.fn_0800b1f8,"ax",%progbits
	.p2align 2
	.global fn_0800b1f8
	.thumb_func
	.type fn_0800b1f8, %function
fn_0800b1f8:
	push {r4, r5, r6, r7, lr}
	sub sp, #0x14
	movw r5, #0xf8
	movt r5, #0x2000
	ldrb.w r0, [r5, #0xf68]
	cmp r0, #9
	bhi.w .L0800b7c4
	tbh [pc, r0, lsl #1]
.L0800b212:
	.short (.L0800b226 - .L0800b212)/2
	.short (.L0800b2d4 - .L0800b212)/2
	.short (.L0800b3a6 - .L0800b212)/2
	.short (.L0800b3e8 - .L0800b212)/2
	.short (.L0800b428 - .L0800b212)/2
	.short (.L0800b28c - .L0800b212)/2
	.short (.L0800b466 - .L0800b212)/2
	.short (.L0800b7c4 - .L0800b212)/2
	.short (.L0800b7c4 - .L0800b212)/2
	.short (.L0800b496 - .L0800b212)/2
.L0800b226:
	ldrb.w r0, [r5, #0xf69]
	movw r4, #0x2d53
	subs r1, r0, #1
	cmp r0, #0
	it eq
	moveq r1, #3
	strb.w r1, [r5, #0xf69]
	movw r5, #0x2d6c
	movt r5, #0x2000
	movt r4, #0x2000
	movs r1, #0xb
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0xc
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0xf
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x10
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x11
	b.n .L0800b2ca
.L0800b28c:
	ldrb.w r0, [r5, #0xe1c]
	cmp r0, #0
	bne.w .L0800b7c4
	ldrb.w r0, [r5, #0xe1d]
	cmp r0, #0
	beq.w .L0800b7c4
	subs r0, #1
	strb.w r0, [r5, #0xe1d]
	movw r5, #0x2d6c
	movw r4, #0x2d53
	movt r5, #0x2000
	movt r4, #0x2000
	movs r1, #0x27
	ldr r0, [r5]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldr r0, [r5]
	movs r3, #0x28
.L0800b2ca:
	mov r1, r4
	mov.w r2, #0xffffffff
	strb r3, [r4]
	b.n .L0800b562
.L0800b2d4:
	ldrb.w r0, [r5, #0xf5d]
	and.w r0, r0, #0xf0
	cmp r0, #0xb0
	beq.w .L0800b7c4
	ldrb.w r0, [r5, #0xf2d]
	movw r2, #:lower16:d_080bb3fc
	subs r1, r0, #1
	cmp r0, #0
	it eq
	moveq r1, #7
	uxtb r0, r1
	movt r2, #:upper16:d_080bb3fc
	ldrb r0, [r2, r0]
	strb.w r1, [r5, #0xf2d]
	movw r1, #0x2d54
	add.w r0, r0, #0x500
	movt r1, #0x2000
	strh r0, [r1]
	movw r0, #0x2d74
	movt r0, #0x2000
	ldr r0, [r0]
	movs r6, #0
	mov.w r2, #0xffffffff
	strb.w r6, [r5, #0xf5d]
	bl queue_send_timeout
	movw r7, #0x2d6c
	movw r4, #0x2d53
	movt r7, #0x2000
	movt r4, #0x2000
	movs r1, #0x1d
	ldr r0, [r7]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movs r1, #0x1b
	ldr r0, [r7]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	ldrb.w r0, [r5, #0xf2d]
	ldrb.w r1, [r5, #0xf3c]
	cmp r0, #2
	it ne
	movne r0, #1
	strb.w r0, [r5, #0xf36]
	movs r0, #0
	movt r0, #0x7fc0
	str.w r0, [r5, #0xf48]
	str.w r0, [r5, #0xf4c]
	cmp r1, #0
	str.w r0, [r5, #0xf50]
	it ne
	strbne.w r6, [r5, #0xf3c]
	ldrb.w r0, [r5, #0xf3d]
	cbz r0, .L0800b39c
	movs r0, #0
	strb.w r0, [r5, #0xf3d]
	movs r1, #0x1a
	ldr r0, [r7]
	strb r1, [r4]
	mov r1, r4
	mov.w r2, #0xffffffff
	bl queue_send_timeout
.L0800b39c:
	add sp, #0x14
	pop.w {r4, r5, r6, r7, lr}
	b.w fn_080098e0
.L0800b3a6:
	ldrb.w r0, [r5, #0x354]
	and.w r1, r0, #0xf
	subs r2, r1, #1
	cmp r2, #2
	blo.w .L0800b4c0
	cmp r1, #3
	beq.w .L0800b4e2
	cmp r1, #0
	bne.w .L0800b7c4
	ldrb.w r1, [r5, #0x2d]
	cmp r1, #0x1b
	bhi.w .L0800b7c4
	ldrb r0, [r5, #2]
	adds r2, r1, #1
	cmp r1, #4
	strb.w r2, [r5, #0x2d]
	blo.w .L0800b58e
	add.w r1, r5, r0, lsl #1
	add.w r0, r1, #0x29c
	add.w r1, r1, #0x260
	b.n .L0800b5d8
.L0800b3e8:
	ldrb.w r0, [r5, #0xf69]
	cmp r0, #2
	bne.w .L0800b7c4
	ldrb.w r0, [r5, #0xf6b]
	and.w r1, r0, #0xf
	cmp r1, #2
	beq.w .L0800b526
	cmp r1, #1
	beq.w .L0800b530
	cbnz r1, .L0800b412
	cmp r0, #0x3f
	bhi.n .L0800b412
.L0800b40c:
	adds r0, #0x10
	strb.w r0, [r5, #0xf6b]
.L0800b412:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x19
	b.n .L0800b55c
.L0800b428:
	ldrb.w r0, [r5, #0xf69]
	cmp r0, #1
	bne.w .L0800b7c4
	ldrb.w r0, [r5, #0xf6a]
	and.w r0, r0, #0xf
	cmp r0, #0			@ system settings item 0 = Sound and light
	bne.w .L0800b7c4
	ldrb.w r0, [r5, #0xf6b]
	cmp r0, #0
	beq.n .L0800b538
	ldrb.w r0, [r5, #0xf61]
	cmp r0, #0x1a
	blo.w .L0800b7c4
	subs r0, #5
	movw r1, #0x5034
	strb.w r0, [r5, #0xf61]
	uxtb r0, r0
	movt r1, #0x4001
	str r0, [r1]
	b.n .L0800b548
.L0800b466:
	ldrb.w r0, [r5, #0xe1c]
	cmp r0, #0
	bne.w .L0800b7c4
	ldrb.w r0, [r5, #0xe1d]
	cmp r0, #0
	beq.w .L0800b7c4
	subs r0, #1
	strb.w r0, [r5, #0xe1d]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x29
	b.n .L0800b55c
.L0800b496:
	ldrb.w r0, [r5, #0xf69]
	cmp r0, #2
	beq.n .L0800b4ce
	cmp r0, #1
	bne.w .L0800b7c4
	ldrb.w r0, [r5, #0xf6a]
	and.w r0, r0, #0xf
	cmp r0, #7
	bne.w .L0800b7c4
	ldrb.w r0, [r5, #0xf6b]
	cmp r0, #5
	blo.w .L0800b7c4
	subs r0, #4
	b.n .L0800b50c
.L0800b4c0:
	mov.w r0, #0xffffffff
	mov.w r1, #0xffffffff
	bl fn_0803b2f8
	b.n .L0800b7ba
.L0800b4ce:
	ldrb.w r0, [r5, #0xf6b]
	and.w r1, r0, #0xf0
	cmp r1, #0xd0
	bne.n .L0800b504
	movs r1, #0xc
	bfi r0, r1, #4, #0x1c
	b.n .L0800b50c
.L0800b4e2:
	ldrb.w r1, [r5, #0x23a]
	cmp r1, #3
	beq.n .L0800b5a6
	cmp r1, #2
	beq.n .L0800b56c
	cmp r1, #1
	bne.w .L0800b7c4
	ldrsh.w r0, [r5, #0x234]
	cmn.w r0, #0x95
	blt.w .L0800b7c4
	subs r1, r0, #1
	b.n .L0800b7a4
.L0800b504:
	cmp r0, #0x40
	blo.w .L0800b7c4
	subs r0, #0x40
.L0800b50c:
	strb.w r0, [r5, #0xf6b]
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x14
	b.n .L0800b55c
.L0800b526:
	tst.w r0, #0xf0
	bne.w .L0800b412
	b.n .L0800b40c
.L0800b530:
	cmp r0, #0x1f
	bls.w .L0800b40c
	b.n .L0800b412
.L0800b538:
	ldrb.w r0, [r5, #0xf62]
	cmp r0, #0
	beq.w .L0800b7c4
	subs r0, #1
	strb.w r0, [r5, #0xf62]
.L0800b548:
	movw r0, #0x2d6c
	movt r0, #0x2000
	movw r1, #0x2d53
	ldr r0, [r0]
	movt r1, #0x2000
	movs r3, #0x21
.L0800b55c:
	mov.w r2, #0xffffffff
	strb r3, [r1]
.L0800b562:
	add sp, #0x14
	pop.w {r4, r5, r6, r7, lr}
	b.w queue_send_timeout
.L0800b56c:
	ldrsh.w r0, [r5, #0x238]
	mvn r1, #0x95
	adds r1, #0x32
	cmp r0, r1
	ble.w .L0800b7c4
	subs r1, r0, #1
	movw r0, #0x2d80
	movt r0, #0x2000
	ldr r0, [r0]
	strh.w r1, [r5, #0x238]
	b.n .L0800b7b2
.L0800b58e:
	cmp r2, #4
	beq.n .L0800b5cc
	ldrb r1, [r5, #0x14]
	cmp r1, #3
	beq.n .L0800b5cc
	add.w r1, r5, r0, lsl #1
	add.w r0, r1, #0x2c4
	add.w r1, r1, #0x288
	b.n .L0800b5d8
.L0800b5a6:
	lsls r0, r0, #0x18
	mvn r0, #0x95
	bmi.w .L0800b79a
	ldrsh.w r1, [r5, #0x232]
	cmp r1, r0
	ble.w .L0800b7c4
	movw r0, #0x2d80
	movt r0, #0x2000
	subs r1, #1
	ldr r0, [r0]
	strh.w r1, [r5, #0x232]
	b.n .L0800b7b2
.L0800b5cc:
	add.w r1, r5, r0, lsl #1
	add.w r0, r1, #0x2b0
	add.w r1, r1, #0x274
.L0800b5d8:
	ldrh r0, [r0]
	ldrh r1, [r1]
	vldr s0, .L0800b7c8
	subs r0, r0, r1
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s2, s2, s0
	ldrsb.w r0, [r5, #4]
	adds r0, #0x64
	vmov s4, r0
	vcvt.f32.s32 s4, s4
	movw r0, #0x7404
	movt r0, #0x4000
	vmul.f32 s2, s2, s4
	vmov s4, r1
	vcvt.f32.u32 s4, s4
	vadd.f32 s2, s2, s4
	ldr r1, [r0, #4]
	vcvt.u32.f32 s2, s2
	vmov r2, s2
	lsrs r1, r1, #0xc
	bfi r2, r1, #0xc, #0x14
	str r2, [r0, #4]
	ldr r1, [r0]
	orr.w r1, r1, #1
	str r1, [r0]
	ldrb.w r1, [r5, #0x2d]
	ldrb r0, [r5, #3]
	cmp r1, #5
	blo.n .L0800b646
	add.w r1, r5, r0, lsl #1
	add.w r0, r1, #0x314
	add.w r1, r1, #0x2d8
	b.n .L0800b66a
.L0800b646:
	cmp r1, #4
	beq.n .L0800b65e
	ldrb r1, [r5, #0x14]
	cmp r1, #3
	beq.n .L0800b65e
	add.w r1, r5, r0, lsl #1
	add.w r0, r1, #0x33c
	add.w r1, r1, #0x300
	b.n .L0800b66a
.L0800b65e:
	add.w r1, r5, r0, lsl #1
	add.w r0, r1, #0x328
	add.w r1, r1, #0x2ec
.L0800b66a:
	ldrh r0, [r0]
	ldrh r1, [r1]
	subs r0, r0, r1
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	vdiv.f32 s0, s2, s0
	ldrsb.w r0, [r5, #5]
	adds r0, #0x64
	vmov s2, r0
	vcvt.f32.s32 s2, s2
	movw r0, #0x1c34
	movt r0, #0x4000
	vmul.f32 s0, s0, s2
	vmov s2, r1
	vcvt.f32.u32 s2, s2
	vadd.f32 s0, s0, s2
	vcvt.u32.f32 s0, s0
	vstr s0, [r0]
	ldrb.w r0, [r5, #0x2e]
	cmp r0, #0
	beq.n .L0800b748
	ldrb.w r0, [r5, #0x2d]
	cmp r0, #0x14
	blo.n .L0800b724
	movw r0, #0x12d
	movw r4, #0x400
	str.w r0, [r5, #0xdb4]
	movs r6, #0
	mov r0, sp
	movt r4, #0x4000
	str r6, [sp, #0x10]
	strd r6, r6, [sp, #8]
	strd r6, r6, [sp]
	bl compute_clock_frequencies
	ldrb.w r0, [r5, #0x2d]
	subs r0, #0x14
	uxtb r1, r0
	cmp r1, #8
	bhi.n .L0800b718
	ldr r1, [sp, #4]
	movw r2, #0x1759
	movt r2, #0xd1b7
	umull r1, r2, r1, r2
	movw r1, #:lower16:d_080465a4
	sxtb r0, r0
	movt r1, #:upper16:d_080465a4
	ldr.w r0, [r1, r0, lsl #2]
	mov.w r1, #0xffffffff
	add.w r1, r1, r2, lsr #13
	str r0, [r4, #0x2c]
	str r1, [r4, #0x28]
	ldr r0, [r4, #0x14]
	orr.w r0, r0, #1
	str r0, [r4, #0x14]
.L0800b718:
	str r6, [r4, #0x24]
	ldr r0, [r4]
	orr.w r0, r0, #1
	str r0, [r4]
	b.n .L0800b748
.L0800b724:
	movw r0, #0x400
	movt r0, #0x4000
	ldr r1, [r0]
	bic.w r1, r1, #1
	str r1, [r0]
	ldrb r0, [r5, #0x17]
	cmp r0, #1
	itee ne
	movwne r0, #0x12d
	moveq r0, #0
	movteq r0, #0x12d
	str.w r0, [r5, #0xdb4]
.L0800b748:
	bl fn_08030a70
	movs r0, #0
	movs r1, #0
	bl fn_0803b2f8
	movw r0, #0x1410
	movt r0, #0x4001
	movs r1, #4
	str r1, [r0]
	movw r0, #0x2d6c
	movw r1, #0x2d53
	movt r0, #0x2000
	movt r1, #0x2000
	ldr r0, [r0]
	movs r2, #2
	strb r2, [r1]
	mov.w r2, #0xffffffff
	bl queue_send_timeout
	movw r0, #0x2d78
	movw r1, #0x2d52
	movt r0, #0x2000
	movt r1, #0x2000
	movs r2, #1
	ldr r0, [r0]
	strb r2, [r1]
	mov.w r2, #0xffffffff
	b.n .L0800b7b6
.L0800b79a:
	ldrsh.w r1, [r5, #0x234]
	cmp r1, r0
	ble.n .L0800b7c4
	subs r1, #1
.L0800b7a4:
	movw r0, #0x2d80
	movt r0, #0x2000
	ldr r0, [r0]
	strh.w r1, [r5, #0x234]
.L0800b7b2:
	movs r1, #0
	movs r2, #0
.L0800b7b6:
	bl queue_send_timeout
.L0800b7ba:
	add sp, #0x14
	pop.w {r4, r5, r6, r7, lr}
	b.w fn_08025fc0
.L0800b7c4:
	add sp, #0x14
	pop {r4, r5, r6, r7, pc}
.L0800b7c8:
	.word 0x43480000	@ float 200.0
