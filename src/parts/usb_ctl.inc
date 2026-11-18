@ usb_ctl.inc - addresses and the RAM layout of the USB control channel, shared by src/usb_ctl.s
@ (transport, frames, device commands) and src/usb_remote.s (remote control of the meter functions).

	.equ	USB_DEV,	0x20002B24
	.equ	USB_CB_TABLE,	0x20000030
	.equ	USB_DESC_TABLE,	0x20000058
	.equ	EP0_STAGE,	0x20002D44
	.equ	IN_REC0,	0x20002B30
	.equ	OUT_REC0,	0x20002C30
	.equ	OUT_REC3,	0x20002C90
	.equ	USB_EPR3,	0x40005C0C
	.equ	USB_EPR0,	0x40005C00
	.equ	USB_CNTR,	0x40005C40
	.equ	USB_CFG,	0x40005C60	@ bit 1: D+ pull-up off (PUO)

	.equ	UI_PAGE,	0x20001060
	.equ	KEY_QUEUE,	0x20002D70
	.equ	DISPLAY_QUEUE,	0x20002D6C
	.equ	AUTO_OFF_COUNT,	0x20001064
	.equ	TICKS,		0x200062D4

	.equ	MAX_PAYLOAD,	512
	.equ	STATE_LEN,	44		@ STATE record (PROTOCOL.md 4.6)
	.equ	PROTO_VERSION,	1
	.equ	CAPS,		0x0007FFFF	@ bits: 0 STATE, 1 STREAM, 2 PAGE, 3 KEY, 4 GEN_SET, 5 CAL_READ,
						@ 6 DRIVE, 7 FW update, 8 BATTERY, 9 KEEP_AWAKE, 10 MEM_READ,
						@ 11 DMM_*, 12 SCOPE_* settings, 13 SCOPE_WAVE, 14 SETTINGS_*,
						@ 15 SCREENSHOT, 16 FILE_*, 17 events, 18 FLASH_READ

@ RAM: 0x20036F90..0x20037FDF (above the application's stack top 0x20036F90, below the bootloader
@ words at 0x20037FE0)
	.equ	CTL,		0x20036F90
	.equ	RX_RING,	CTL + 0x000	@ 1024 bytes
	.equ	TX_RING,	CTL + 0x400	@ 1024 bytes
	.equ	FRAME,		CTL + 0x800	@ 528 bytes: request frame being assembled (from length on)
	.equ	PKT_OUT,	CTL + 0xA10	@ 64 bytes: EP3 OUT packet
	.equ	PKT_IN,		CTL + 0xA50	@ 64 bytes: EP3 IN packet
	.equ	ANSWER,		CTL + 0xA90	@ 528 bytes: answer payload being built
	.equ	V,		CTL + 0xCA0	@ variables:
	.equ	V_RXH,		0x00		@ rx head (interrupt)
	.equ	V_RXT,		0x04		@ rx tail (task)
	.equ	V_TXH,		0x08		@ tx head (task)
	.equ	V_TXT,		0x0C		@ tx tail (interrupt)
	.equ	V_INBUSY,	0x10		@ EP3 IN packet in flight
	.equ	V_ZLP,		0x11		@ last packet was 64 bytes: a zero-length packet must follow
	.equ	V_CONF,		0x12		@ configured
	.equ	V_DTR,		0x13
	.equ	V_SHARED,	0x14		@ configuration with the drive
	.equ	V_AWAKE,	0x15
	.equ	V_FWOK,		0x16		@ staged image complete and verified
	.equ	V_PSTATE,	0x17		@ frame parser: 0 wait sync, 1 length low, 2 length high, 3 body
	.equ	V_FLEN,		0x18		@ halfword: frame length (seq .. payload)
	.equ	V_FPOS,		0x1A		@ halfword: bytes of the frame body collected (incl. CRC)
	.equ	V_LINE,		0x1C		@ 8 bytes line coding
	.equ	V_HAND,		0x24		@ 16 bytes copy of the bootloader's hand-over block
	.equ	V_STREAM,	0x34		@ stream period (ms)
	.equ	V_SNEXT,	0x38		@ tick of the next stream frame
	.equ	V_FWOBJ,	0x3C		@ file object of the staged image (0 = none)
	.equ	V_FWTOT,	0x40
	.equ	V_FWCRC,	0x44		@ expected CRC-32
	.equ	V_FWPOS,	0x48		@ bytes written
	.equ	V_FWRUN,	0x4C		@ running CRC register
	.equ	V_TASK,		0x50		@ task handle
	.equ	V_SSEQ,		0x54		@ stream / event counter
	.equ	V_CFGIF,	0x55		@ CDC communication interface number of the active configuration
	.equ	V_KJOB,		0x58		@ job function for the key task (0 = none; src/usb_remote.s)
	.equ	V_DJOB,		0x5C		@ job function for the display task
	.equ	V_JRES,		0x60		@ status of the last job (0xFF while it has not finished)
	.equ	V_SAVERST,	0x61		@ 1: restart (not power off) after the settings are saved
	.equ	V_LPAGE,	0x62		@ UI page last reported (PAGE_CHANGED event)
	.equ	V_LBATT,	0x63		@ 1: BATTERY_LOW reported for the current low-battery state
	.equ	V_EVKH,		0x64		@ key event ring head (key task)
	.equ	V_EVKT,		0x65		@ key event ring tail (usb task)
	.equ	V_EVK,		0x68		@ 8 bytes: key event ring
	.equ	V_WOBJ,		0x70		@ file object of FILE_WRITE (0 = none)
	.equ	V_WPOS,		0x74		@ bytes written to it
	.equ	V_WTOT,		0x78		@ its announced total
	.equ	V_MSCOUT,	0x7C		@ mass-storage OUT event: endpoint index + 1 (0 = none)
	.equ	V_MSCIN,	0x7D		@ mass-storage IN complete event (1)
	.equ	V_HOSTDRV,	0x7E		@ 1 while the host has the drive (no device writes to it)
	.equ	V_INMSC,	0x7F		@ 1 while msc_service runs the vendor mass-storage handler
	.equ	V_END,		0x80

	.equ	REMOTE_CODE,	0x80		@ queue code that runs the posted job in the key or display task
	.equ	LOCK_VARS,	V + V_END	@ 8 bytes: storage lock owner, count (src/storage.s)
	.equ	JOB_STACK_TOP,	0x20037FD8	@ private stack of the jobs, down to LOCK_VARS + 8
