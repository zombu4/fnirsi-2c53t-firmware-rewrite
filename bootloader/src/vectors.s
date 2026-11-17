@ vectors.s - the 97-word vector table of the stock bootloader, flash 0x08000000..0x08000183
@ Word 0 is the initial stack pointer, word 1 the reset vector, then the ARMv7-M system exceptions
@ (word 2 NMI .. word 15 SysTick), then IRQ 0 .. IRQ 80 (words 16..96).  Every word that holds a
@ function entry (bit 0 set) is written as the function symbol; the reserved words and IRQ 48..51
@ hold 0 (IRQ 64..67 at 0x140..0x14c).  Every IRQ without its own handler points at default_irq_handler (0x08000299).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

	.section .vectors,"a",%progbits
	.global vectors
vectors:
	.word	0x20001a08		@ 0x00 initial stack pointer (RAM top 0x20001A08)
	.word	reset_handler		@ 0x04 Reset
	.word	nmi_handler		@ 0x08 NMI
	.word	hard_fault_handler	@ 0x0c HardFault
	.word	mem_manage_handler	@ 0x10 MemManage
	.word	bus_fault_handler	@ 0x14 BusFault
	.word	usage_fault_handler	@ 0x18 UsageFault
	.word	0x00000000		@ 0x1c reserved
	.word	0x00000000		@ 0x20 reserved
	.word	0x00000000		@ 0x24 reserved
	.word	0x00000000		@ 0x28 reserved
	.word	svcall_handler		@ 0x2c SVCall
	.word	debug_monitor_handler	@ 0x30 DebugMonitor
	.word	0x00000000		@ 0x34 reserved
	.word	pendsv_handler		@ 0x38 PendSV
	.word	systick_handler		@ 0x3c SysTick
	.word	default_irq_handler	@ 0x40 IRQ 0
	.word	default_irq_handler	@ 0x44 IRQ 1
	.word	default_irq_handler	@ 0x48 IRQ 2
	.word	default_irq_handler	@ 0x4c IRQ 3
	.word	default_irq_handler	@ 0x50 IRQ 4
	.word	default_irq_handler	@ 0x54 IRQ 5
	.word	default_irq_handler	@ 0x58 IRQ 6
	.word	default_irq_handler	@ 0x5c IRQ 7
	.word	default_irq_handler	@ 0x60 IRQ 8
	.word	default_irq_handler	@ 0x64 IRQ 9
	.word	default_irq_handler	@ 0x68 IRQ 10
	.word	default_irq_handler	@ 0x6c IRQ 11
	.word	default_irq_handler	@ 0x70 IRQ 12
	.word	default_irq_handler	@ 0x74 IRQ 13
	.word	default_irq_handler	@ 0x78 IRQ 14
	.word	default_irq_handler	@ 0x7c IRQ 15
	.word	default_irq_handler	@ 0x80 IRQ 16
	.word	default_irq_handler	@ 0x84 IRQ 17
	.word	default_irq_handler	@ 0x88 IRQ 18
	.word	default_irq_handler	@ 0x8c IRQ 19
	.word	irq20_handler		@ 0x90 IRQ 20
	.word	default_irq_handler	@ 0x94 IRQ 21
	.word	default_irq_handler	@ 0x98 IRQ 22
	.word	default_irq_handler	@ 0x9c IRQ 23
	.word	default_irq_handler	@ 0xa0 IRQ 24
	.word	default_irq_handler	@ 0xa4 IRQ 25
	.word	default_irq_handler	@ 0xa8 IRQ 26
	.word	default_irq_handler	@ 0xac IRQ 27
	.word	default_irq_handler	@ 0xb0 IRQ 28
	.word	default_irq_handler	@ 0xb4 IRQ 29
	.word	default_irq_handler	@ 0xb8 IRQ 30
	.word	default_irq_handler	@ 0xbc IRQ 31
	.word	default_irq_handler	@ 0xc0 IRQ 32
	.word	default_irq_handler	@ 0xc4 IRQ 33
	.word	default_irq_handler	@ 0xc8 IRQ 34
	.word	default_irq_handler	@ 0xcc IRQ 35
	.word	default_irq_handler	@ 0xd0 IRQ 36
	.word	default_irq_handler	@ 0xd4 IRQ 37
	.word	default_irq_handler	@ 0xd8 IRQ 38
	.word	default_irq_handler	@ 0xdc IRQ 39
	.word	default_irq_handler	@ 0xe0 IRQ 40
	.word	default_irq_handler	@ 0xe4 IRQ 41
	.word	default_irq_handler	@ 0xe8 IRQ 42
	.word	default_irq_handler	@ 0xec IRQ 43
	.word	default_irq_handler	@ 0xf0 IRQ 44
	.word	default_irq_handler	@ 0xf4 IRQ 45
	.word	default_irq_handler	@ 0xf8 IRQ 46
	.word	default_irq_handler	@ 0xfc IRQ 47
	.word	default_irq_handler	@ 0x100 IRQ 48
	.word	default_irq_handler	@ 0x104 IRQ 49
	.word	default_irq_handler	@ 0x108 IRQ 50
	.word	default_irq_handler	@ 0x10c IRQ 51
	.word	default_irq_handler	@ 0x110 IRQ 52
	.word	default_irq_handler	@ 0x114 IRQ 53
	.word	default_irq_handler	@ 0x118 IRQ 54
	.word	default_irq_handler	@ 0x11c IRQ 55
	.word	default_irq_handler	@ 0x120 IRQ 56
	.word	default_irq_handler	@ 0x124 IRQ 57
	.word	default_irq_handler	@ 0x128 IRQ 58
	.word	default_irq_handler	@ 0x12c IRQ 59
	.word	default_irq_handler	@ 0x130 IRQ 60
	.word	default_irq_handler	@ 0x134 IRQ 61
	.word	default_irq_handler	@ 0x138 IRQ 62
	.word	default_irq_handler	@ 0x13c IRQ 63
	.word	0x00000000		@ 0x140 IRQ 64 (no entry in the stock table)
	.word	0x00000000		@ 0x144 IRQ 65 (no entry in the stock table)
	.word	0x00000000		@ 0x148 IRQ 66 (no entry in the stock table)
	.word	0x00000000		@ 0x14c IRQ 67 (no entry in the stock table)
	.word	default_irq_handler	@ 0x150 IRQ 68
	.word	default_irq_handler	@ 0x154 IRQ 69
	.word	default_irq_handler	@ 0x158 IRQ 70
	.word	default_irq_handler	@ 0x15c IRQ 71
	.word	default_irq_handler	@ 0x160 IRQ 72
	.word	default_irq_handler	@ 0x164 IRQ 73
	.word	default_irq_handler	@ 0x168 IRQ 74
	.word	default_irq_handler	@ 0x16c IRQ 75
	.word	default_irq_handler	@ 0x170 IRQ 76
	.word	default_irq_handler	@ 0x174 IRQ 77
	.word	default_irq_handler	@ 0x178 IRQ 78
	.word	default_irq_handler	@ 0x17c IRQ 79
	.word	default_irq_handler	@ 0x180 IRQ 80
