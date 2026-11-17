@ settings_54.s - two routines that program the register block at 0x40022000 and the halfwords at 0x1ffff800 / 0x1ffff810.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ fn_080363e4 - reads 0x4002201c into a saved value first (r12 = value & 2), writes
@ the keys 0x45670123 and 0xcdef89ab to 0x40022008, waits until bit 9 of 0x40022010
@ is set, sets bit 5 and then bit 6 of 0x40022010, waits for bit 0 of 0x4002200c to
@ clear (up to 0x40000000 reads); status bit 2 gives result 1, else bit 4 gives 2,
@ else 3; clears bit 5 of 0x40022010 (on poll expiry only this clear follows).
@ When bit 1 of the saved 0x4002201c value was clear and the result was 3 it sets
@ bit 4 of 0x40022010, writes halfword 0xa5 to 0x1ffff800, waits on bit 0 of
@ 0x4002200c (up to 0x100000 reads) and clears bit 4.
@ Purpose not determined from the code (register block 0x40022000 and the halfword
@ at 0x1ffff800 are named by address only).
@ ----------------------------------------------------------------------------
	.section .text.fn_080363e4,"ax",%progbits
	.global fn_080363e4
	.thumb_func
	.type fn_080363e4, %function
fn_080363e4:
	movw	r0, #0x200c
	movt	r0, #0x4002
	ldr	r1, [r0, #0x10]
	and.w	r12, r1, #0x2
	movw	r1, #0x123
	movt	r1, #0x4567
	str.w	r1, [r0, #-0x4]
	movw	r1, #0x89ab
	movt	r1, #0xcdef
	str.w	r1, [r0, #-0x4]
	nop
.L0803640c:
	ldr	r1, [r0, #0x4]
	lsls	r1, r1, #0x16
	itttt	pl
	ldrpl	r1, [r0, #0x4]
	lslspl.w	r1, r1, #0x16
	ldrpl	r1, [r0, #0x4]
	lslspl.w	r1, r1, #0x16
	bmi.n	.L08036426
	ldr	r1, [r0, #0x4]
	lsls	r1, r1, #0x16
	bpl.n	.L0803640c
.L08036426:
	ldr	r1, [r0, #0x4]
	movs	r2, #0x0
	orr.w	r1, r1, #0x20
	str	r1, [r0, #0x4]
	ldr	r1, [r0, #0x4]
	cmp.w	r12, #0x0
	orr.w	r1, r1, #0x40
	str	r1, [r0, #0x4]
	ldr	r1, [r0, #0x0]
	it	eq
	moveq	r2, #0xa5
	lsls	r1, r1, #0x1f
	bne.n	.L0803645a
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1d
	bmi.n	.L080364c8
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1b
	mov.w	r1, #0x2
	it	pl
	movpl	r1, #0x3
	b.n	.L0803651e
.L0803645a:
	mov.w	r3, #0x40000000
.L0803645e:
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L08036508
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364ce
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364d2
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364d6
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364da
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364de
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364e2
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364e6
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364ea
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364ee
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364f2
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364f6
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364fa
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L080364fe
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L08036502
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	beq.n	.L08036506
	subs	r3, #0x10
	bne.n	.L0803645e
	mvn	r2, #0x20
	b.n	.L08036562
.L080364c8:
	mvn	r2, #0x20
	b.n	.L08036562
.L080364ce:
	subs	r3, #0x1
	b.n	.L08036508
.L080364d2:
	subs	r3, #0x2
	b.n	.L08036508
.L080364d6:
	subs	r3, #0x3
	b.n	.L08036508
.L080364da:
	subs	r3, #0x4
	b.n	.L08036508
.L080364de:
	subs	r3, #0x5
	b.n	.L08036508
.L080364e2:
	subs	r3, #0x6
	b.n	.L08036508
.L080364e6:
	subs	r3, #0x7
	b.n	.L08036508
.L080364ea:
	subs	r3, #0x8
	b.n	.L08036508
.L080364ee:
	subs	r3, #0x9
	b.n	.L08036508
.L080364f2:
	subs	r3, #0xa
	b.n	.L08036508
.L080364f6:
	subs	r3, #0xb
	b.n	.L08036508
.L080364fa:
	subs	r3, #0xc
	b.n	.L08036508
.L080364fe:
	subs	r3, #0xd
	b.n	.L08036508
.L08036502:
	subs	r3, #0xe
	b.n	.L08036508
.L08036506:
	subs	r3, #0xf
.L08036508:
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1d
	bmi.n	.L08036532
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1b
	mov.w	r1, #0x2
	it	pl
	movpl	r1, #0x3
	cmp	r3, #0x1
	beq.n	.L08036538
.L0803651e:
	ldr	r3, [r0, #0x4]
	cmp.w	r12, #0x0
	bic.w	r3, r3, #0x20
	str	r3, [r0, #0x4]
	it	eq
	cmpeq	r1, #0x3
	beq.n	.L0803653e
	bx	lr
.L08036532:
	movs	r1, #0x1
	cmp	r3, #0x1
	bne.n	.L0803651e
.L08036538:
	mvn	r2, #0x20
	b.n	.L08036562
.L0803653e:
	ldr	r1, [r0, #0x4]
	orr.w	r1, r1, #0x10
	str	r1, [r0, #0x4]
	movw	r1, #0xf800
	movt	r1, #0x1fff
	strh	r2, [r1, #0x0]
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	bne.n	.L0803656a
.L08036556:
	ldr	r1, [r0, #0x0]
	mvn	r2, #0x10
	lsls	r1, r1, #0x1d
	it	pl
	ldrpl	r1, [r0, #0x0]
.L08036562:
	ldr	r1, [r0, #0x4]
	ands	r1, r2
	str	r1, [r0, #0x4]
	bx	lr
.L0803656a:
	movs	r1, #0x0
	movt	r1, #0xfff0
.L08036570:
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L08036556
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L08036556
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L08036556
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L08036556
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L08036556
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L08036556
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L08036556
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L08036556
	adds	r1, #0x10
	mvn	r2, #0x10
	bne.n	.L08036570
	b.n	.L08036562
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ fn_080365ec - writes keys 0x45670123 and 0xcdef89ab to 0x40022008, waits until
@ bit 9 of 0x40022010 is set, sets bit 4 of 0x40022010, writes halfword 0xfe to
@ 0x1ffff810, waits on bit 0 of 0x4002200c to clear (up to 0x100000 reads, bit 2
@ is read but its value is not used) and clears bit 4 of 0x40022010.
@ Called by 08033f7c, which runs it when the halfword at 0x1ffff810 has a low
@ byte other than 0xfe.
@ Purpose not determined from the code (register block 0x40022000 and the halfword
@ at 0x1ffff810 are named by address only).
@ ----------------------------------------------------------------------------
	.section .text.fn_080365ec,"ax",%progbits
	.global fn_080365ec
	.thumb_func
	.type fn_080365ec, %function
fn_080365ec:
	movw	r0, #0x200c
	movw	r1, #0x123
	movt	r0, #0x4002
	movt	r1, #0x4567
	str.w	r1, [r0, #-0x4]
	movw	r1, #0x89ab
	movt	r1, #0xcdef
	str.w	r1, [r0, #-0x4]
.L0803660c:
	ldr	r1, [r0, #0x4]
	lsls	r1, r1, #0x16
	itttt	pl
	ldrpl	r1, [r0, #0x4]
	lslspl.w	r1, r1, #0x16
	ldrpl	r1, [r0, #0x4]
	lslspl.w	r1, r1, #0x16
	bmi.n	.L08036626
	ldr	r1, [r0, #0x4]
	lsls	r1, r1, #0x16
	bpl.n	.L0803660c
.L08036626:
	ldr	r1, [r0, #0x4]
	movs	r2, #0xfe
	orr.w	r1, r1, #0x10
	str	r1, [r0, #0x4]
	movw	r1, #0xf810
	movt	r1, #0x1fff
	strh	r2, [r1, #0x0]
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1f
	bne.n	.L0803664a
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1d
	it	pl
	ldrpl	r1, [r0, #0x0]
	b.n	.L080366ce
.L0803664a:
	movs	r1, #0x0
	movt	r1, #0xfff0
.L08036650:
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L080366c6
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L080366c6
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L080366c6
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L080366c6
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L080366c6
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L080366c6
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L080366c6
	ldr	r2, [r0, #0x0]
	lsls	r2, r2, #0x1f
	itt	ne
	ldrne	r2, [r0, #0x0]
	lslsne.w	r2, r2, #0x1f
	beq.n	.L080366c6
	adds	r1, #0x10
	bne.n	.L08036650
	b.n	.L080366ce
.L080366c6:
	ldr	r1, [r0, #0x0]
	lsls	r1, r1, #0x1d
	it	pl
	ldrpl	r1, [r0, #0x0]
.L080366ce:
	ldr	r1, [r0, #0x4]
	bic.w	r1, r1, #0x10
	str	r1, [r0, #0x4]
	bx	lr
