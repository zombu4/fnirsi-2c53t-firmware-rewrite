@ text.s - every text the firmware shows or uses (English only), NUL-terminated, UTF-8.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
@
@ Labels: t_<8 hex digits> = the address of the same English string in the vendor image V1.2.0
@ (reference only: nothing depends on that address; it ties each label to the vendor slot or code
@ literal that used it). Each string is its own .asciz (V1.2.0 shared tails between strings, e.g.
@ "Hz" inside "MHz"; here every label has its own bytes).
@ Users: the text pointer tables of src/rodata.s (d_0804bf28 .. d_0804c988, one word per item)
@ and the code (movw / movt pairs and literal words).
@ Characters: ASCII plus U+03A9 (Ohm), U+2103 (degree C), U+2109 (degree F) of the unit table.
@ (V1.2.0's language page and its names "中文" / "English", the menu item "Language" and the
@ pictures of the Chinese layout, 81 / 83 / 85 / 152.jpg, are removed with the language choice.)
@ No string contains "FNIRSI" (none in V1.2.0's text either).
@ Section .rodata.text, placed by link.ld after .rodata.fixed (src/rodata.s); byte alignment.
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb
	.section .rodata.text,"a",%progbits

@ ----------------------------------------------------------------------------
@ Measurement labels (table d_0804bf28, draw_waveform_display)
@ ----------------------------------------------------------------------------
	.global t_080bbaa0
t_080bbaa0:	.asciz "Freq:"
	.global t_080bba4c
t_080bba4c:	.asciz "Peri:"
	.global t_080bb9f8
t_080bb9f8:	.asciz "Duty+:"
	.global t_080bba05
t_080bba05:	.asciz "Duty-:"
	.global t_080bb9f2
t_080bb9f2:	.asciz "Wid+:"
	.global t_080bb9ff
t_080bb9ff:	.asciz "Wid-:"
	.global t_080bbab7
t_080bbab7:	.asciz "Vmax:"
	.global t_080bba6b
t_080bba6b:	.asciz "Vmin:"
	.global t_080bba95
t_080bba95:	.asciz "Vp-p:"
	.global t_080bba9b
t_080bba9b:	.asciz "Amp:"
	.global t_080bbaa6
t_080bbaa6:	.asciz "Vrms:"
	.global t_080bba47
t_080bba47:	.asciz "Avg:"

@ ----------------------------------------------------------------------------
@ Units: frequency, time (upper and lower case S), voltage, the unit table d_0804c404
@ ----------------------------------------------------------------------------
	.global t_080bcee6
t_080bcee6:	.asciz "Hz"
	.global t_080bcee1
t_080bcee1:	.asciz "KHz"
	.global t_080bcee5
t_080bcee5:	.asciz "MHz"
	.global t_080bbcc5
t_080bbcc5:	.asciz "nS"
	.global t_080bbcf2
t_080bbcf2:	.asciz "uS"
	.global t_080bbca4
t_080bbca4:	.asciz "mS"
	.global t_080bbcf3
t_080bbcf3:	.asciz "S"
	.global t_080bcd62
t_080bcd62:	.asciz "ns"
	.global t_080bcda8
t_080bcda8:	.asciz "us"
	.global t_080bcd4a
t_080bcd4a:	.asciz "ms"
	.global t_080bcda9
t_080bcda9:	.asciz "s"
	.global t_080bbd2d
t_080bbd2d:	.asciz "mV"
	.global t_080bbd2e
t_080bbd2e:	.asciz "V"
	.global t_080bd8cb
t_080bd8cb:	.asciz "Ω"
	.global t_080bd8ca
t_080bd8ca:	.asciz "kΩ"
	.global t_080bd8c6
t_080bd8c6:	.asciz "MΩ"
	.global t_080bbc3e
t_080bbc3e:	.asciz "nF"
	.global t_080bbc41
t_080bbc41:	.asciz "uF"
	.global t_080bbc3b
t_080bbc3b:	.asciz "mF"
	.global t_080bbc42
t_080bbc42:	.asciz "F"
	.global t_080bd03d
t_080bd03d:	.asciz "℃"
	.global t_080bbc02
t_080bbc02:	.asciz "uA"
	.global t_080bbbff
t_080bbbff:	.asciz "mA"
	.global t_080bbc03
t_080bbc03:	.asciz "A"
	.global t_080bd0d6
t_080bd0d6:	.asciz "℉"
	.global t_080bb5ef
t_080bb5ef:	.asciz "%"

@ ----------------------------------------------------------------------------
@ Status messages (named directly by draw_waveform_display and the page routines)
@ ----------------------------------------------------------------------------
	.global t_080bb68e
t_080bb68e:	.asciz "Saving..."
	.global t_080bc05b
t_080bc05b:	.asciz "Saved"
	.global t_080bc04f
t_080bc04f:	.asciz "Save failed"
	.global t_080bb712
t_080bb712:	.asciz "Await Trigger..."
	.global t_080bb779
t_080bb779:	.asciz "Awaiting Auto Measurement..."
	.global t_080bb6c7
t_080bb6c7:	.asciz "Awaiting auto-correction..."
	.global t_080bcde0
t_080bcde0:	.asciz "Exceeded Limit"
	.global t_080bc87a
t_080bc87a:	.asciz "Waiting for automatic amplitude calibration"
	.global t_080bb682
t_080bb682:	.asciz "Deleting..."
	.global t_080bcb6e
t_080bcb6e:	.asciz "Image Viewer"
	.global t_080bceb4
t_080bceb4:	.asciz "Battery low, charge now"
	.global t_080bc8ae
t_080bc8ae:	.asciz "Auto shutdown soon"

@ ----------------------------------------------------------------------------
@ About page labels (d_0804c218) and system settings menu items (d_0804c258)
@ ----------------------------------------------------------------------------
	.global t_080bba71
t_080bba71:	.asciz "Version:"
	.global t_080bba52
t_080bba52:	.asciz " Model:"
	.global t_080bcdd0
t_080bcdd0:	.asciz "Sound and light"
	.global t_080bce6b
t_080bce6b:	.asciz "Startup on Boot"
	.global t_080bc8de
t_080bc8de:	.asciz "Auto Shutdown"
	.global t_080bc35e
t_080bc35e:	.asciz "USB Sharing"
	.global t_080bce87
t_080bce87:	.asciz "About"
	.global t_080bcdab
t_080bcdab:	.asciz "Factory Reset"

@ ----------------------------------------------------------------------------
@ Page titles and choice texts (named directly by the page routines, and tables d_0804c208,
@ d_0804c924 of src/rodata.s)
@ ----------------------------------------------------------------------------
	.global t_080bc220
t_080bc220:	.asciz "None"
	.global t_080bcb54
t_080bcb54:	.asciz "Multimeter"
	.global t_080bc225
t_080bc225:	.asciz "Oscilloscope"
	.global t_080bcbab
t_080bcbab:	.asciz "Signal Generator"
	.global t_080bccfe
t_080bccfe:	.asciz "System Settings"
	.global t_080bcce8
t_080bcce8:	.asciz "Oscilloscope Settings"
	.global t_080bcd16
t_080bcd16:	.asciz "Settings"

@ ----------------------------------------------------------------------------
@ Value panel: MAX / MEAN / MIN (d_0804c3d8), number formats (d_0804c3f0)
@ ----------------------------------------------------------------------------
	.global t_080bbd30
t_080bbd30:	.asciz "MAX"
	.global t_080bbc4c
t_080bbc4c:	.asciz "MEAN"
	.global t_080bbc51
t_080bbc51:	.asciz "MIN"
	.global t_080bcc03
t_080bcc03:	.asciz "%.0f%s"
	.global t_080bcc0a
t_080bcc0a:	.asciz "%.1f%s"
	.global t_080bcc11
t_080bcc11:	.asciz "%.2f%s"
	.global t_080bcc18
t_080bcc18:	.asciz "%.3f%s"
	.global t_080bcc1f
t_080bcc1f:	.asciz "%.4f%s"

@ ----------------------------------------------------------------------------
@ Multimeter function names (d_0804c43c)
@ ----------------------------------------------------------------------------
	.global t_080bc02e
t_080bc02e:	.asciz "Automatic"
	.global t_080bc15d
t_080bc15d:	.asciz "DC Voltage"
	.global t_080bc152
t_080bc152:	.asciz "AC Voltage"
	.global t_080bced6
t_080bced6:	.asciz "Continuity"
	.global t_080bc111
t_080bc111:	.asciz "Diode"
	.global t_080bc0d6
t_080bc0d6:	.asciz "Resistance"
	.global t_080bc0ca
t_080bc0ca:	.asciz "Capacitance"
	.global t_080bc238
t_080bc238:	.asciz "Temperature"
	.global t_080bce4b
t_080bce4b:	.asciz "Small DC current"
	.global t_080bce29
t_080bce29:	.asciz "Small AC current"
	.global t_080bce3a
t_080bce3a:	.asciz "Large DC current"
	.global t_080bce18
t_080bce18:	.asciz "Large AC current"

@ ----------------------------------------------------------------------------
@ Signal generator: value names (d_0804c5bc) and waveform names (d_0804c61c). The waveform names say
@ what the generator puts out (fill_output_waveform_table, src/siggen_55.s; tables waves.bin): V1.2.0
@ called the duty-shaped triangle "Sawtooth wave", the exponentials "Index Up / Decrease", the sum of
@ harmonics "Multi-audio" and the sinc pulse "Sink Pulse"; all fit the list's 100-pixel box.
@ ----------------------------------------------------------------------------
	.global t_080bcecc
t_080bcecc:	.asciz "Frequency"
	.global t_080bc179
t_080bc179:	.asciz "Duty Cycle"
	.global t_080bc117
t_080bc117:	.asciz "Amplitude"
	.global t_080bc2ab
t_080bc2ab:	.asciz "Sine"
	.global t_080bc2b5
t_080bc2b5:	.asciz "Square"
	.global t_080bc2dd
t_080bc2dd:	.asciz "Ramp"
	.global t_080bc2eb
t_080bc2eb:	.asciz "Half Wave"
	.global t_080bc2c1
t_080bc2c1:	.asciz "Full Wave"
	.global t_080bc2d3
t_080bc2d3:	.asciz "Step Up"
	.global t_080bc2cb
t_080bc2cb:	.asciz "Step Down"
	.global t_080bcac9
t_080bcac9:	.asciz "Exp Rise"
	.global t_080bc244
t_080bc244:	.asciz "Exp Fall"
	.global t_080bce5c
t_080bce5c:	.asciz "DC"
	.global t_080bc9b5
t_080bc9b5:	.asciz "Harmonics"
	.global t_080bc253
t_080bc253:	.asciz "Sinc Pulse"
	.global t_080bccc0
t_080bccc0:	.asciz "Lorentz"

@ ----------------------------------------------------------------------------
@ Oscilloscope: probe / coupling (d_0804c7bc), trigger labels (d_0804c7cc) and modes
@ (d_0804c7e4), channels (d_0804c7fc), settings items (d_0804c804; short names: the list box is
@ 0x4c pixels wide and the text is wrapped by characters, V1.2.0's long names broke inside words)
@ ----------------------------------------------------------------------------
	.global t_080bb979
t_080bb979:	.asciz "X1"
	.global t_080bb92f
t_080bb92f:	.asciz "X10"
	.global t_080bbc28
t_080bbc28:	.asciz "AC"
	.global t_080bbc2b
t_080bbc2b:	.asciz "DC"
	.global t_080bba31
t_080bba31:	.asciz "Mode:"
	.global t_080bba37
t_080bba37:	.asciz "Edge:"
	.global t_080bba5a
t_080bba5a:	.asciz "Channel:"
	.global t_080bc707
t_080bc707:	.asciz "Normal"
	.global t_080bca92
t_080bca92:	.asciz "Auto"
	.global t_080bc184
t_080bc184:	.asciz "Single"
	.global t_080bb975
t_080bb975:	.asciz "CH1"
	.global t_080bb9e0
t_080bb9e0:	.asciz "CH2"
	.global t_080bc104
t_080bc104:	.asciz "Display"
	.global t_080bce05
t_080bce05:	.asciz "Cursors"
	.global t_080bcdef
t_080bcdef:	.asciz "Measure"
	.global t_080bccce
t_080bccce:	.asciz "Channel 1"
	.global t_080bccdb
t_080bccdb:	.asciz "Channel 2"
	.global t_080bcd0e
t_080bcd0e:	.asciz "Trigger"
	.global t_080bc0e1
t_080bc0e1:	.asciz "Persistence"
	.global t_080bcc33
t_080bcc33:	.asciz "Math"

@ ----------------------------------------------------------------------------
@ Volts per division (d_0804c954)
@ ----------------------------------------------------------------------------
	.global t_080bbd21
t_080bbd21:	.asciz "10mV"
	.global t_080bbd26
t_080bbd26:	.asciz "20mV"
	.global t_080bbd2b
t_080bbd2b:	.asciz "50mV"
	.global t_080bbd0f
t_080bbd0f:	.asciz "100mV"
	.global t_080bbd15
t_080bbd15:	.asciz "200mV"
	.global t_080bbd1b
t_080bbd1b:	.asciz "500mV"
	.global t_080bbd06
t_080bbd06:	.asciz "1V"
	.global t_080bbd09
t_080bbd09:	.asciz "2V"
	.global t_080bbd0c
t_080bbd0c:	.asciz "5V"
	.global t_080bbcfa
t_080bbcfa:	.asciz "10V"
	.global t_080bbcfe
t_080bbcfe:	.asciz "20V"
	.global t_080bbd02
t_080bbd02:	.asciz "50V"
	.global t_080bbcf5
t_080bbcf5:	.asciz "100V"

@ ----------------------------------------------------------------------------
@ Time per division (d_0804c988)
@ ----------------------------------------------------------------------------
	.global t_080bbcb9
t_080bbcb9:	.asciz "10nS"
	.global t_080bbcbe
t_080bbcbe:	.asciz "20nS"
	.global t_080bbcc3
t_080bbcc3:	.asciz "50nS"
	.global t_080bbca7
t_080bbca7:	.asciz "100nS"
	.global t_080bbcad
t_080bbcad:	.asciz "200nS"
	.global t_080bbcb3
t_080bbcb3:	.asciz "500nS"
	.global t_080bbce9
t_080bbce9:	.asciz "1uS"
	.global t_080bbced
t_080bbced:	.asciz "2uS"
	.global t_080bbcf1
t_080bbcf1:	.asciz "5uS"
	.global t_080bbcda
t_080bbcda:	.asciz "10uS"
	.global t_080bbcdf
t_080bbcdf:	.asciz "20uS"
	.global t_080bbce4
t_080bbce4:	.asciz "50uS"
	.global t_080bbcc8
t_080bbcc8:	.asciz "100uS"
	.global t_080bbcce
t_080bbcce:	.asciz "200uS"
	.global t_080bbcd4
t_080bbcd4:	.asciz "500uS"
	.global t_080bbc9b
t_080bbc9b:	.asciz "1mS"
	.global t_080bbc9f
t_080bbc9f:	.asciz "2mS"
	.global t_080bbca3
t_080bbca3:	.asciz "5mS"
	.global t_080bbc8c
t_080bbc8c:	.asciz "10mS"
	.global t_080bbc91
t_080bbc91:	.asciz "20mS"
	.global t_080bbc96
t_080bbc96:	.asciz "50mS"
	.global t_080bbc7a
t_080bbc7a:	.asciz "100mS"
	.global t_080bbc80
t_080bbc80:	.asciz "200mS"
	.global t_080bbc86
t_080bbc86:	.asciz "500mS"
	.global t_080bbc6d
t_080bbc6d:	.asciz "1S"
	.global t_080bbc70
t_080bbc70:	.asciz "2S"
	.global t_080bbc73
t_080bbc73:	.asciz "5S"
	.global t_080bbc65
t_080bbc65:	.asciz "10S"
	.global t_080bbc69
t_080bbc69:	.asciz "20S"

@ ----------------------------------------------------------------------------
@ Oscilloscope panels (draw_panels_by_selector_20001062): math channel names, channel
@ panel labels, switch states
@ ----------------------------------------------------------------------------
	.global t_080bb9cc
t_080bb9cc:	.asciz "CH1+CH2"
	.global t_080bb9d4
t_080bb9d4:	.asciz "CH1-CH2"
	.global t_080bb9c4
t_080bb9c4:	.asciz "CH1*CH2"
	.global t_080bb9dc
t_080bb9dc:	.asciz "CH1/CH2"
	.global t_080bb974
t_080bb974:	.asciz "-CH1"
	.global t_080bb9d7
t_080bb9d7:	.asciz "-CH2"
	.global t_080bcf1a
t_080bcf1a:	.asciz "|CH1|"
	.global t_080bcf20
t_080bcf20:	.asciz "|CH2|"
	.global t_080bba25
t_080bba25:	.asciz "FFT:"
	.global t_080bba2a
t_080bba2a:	.asciz "Probe:"
	.global t_080bba3d
t_080bba3d:	.asciz "Coupling:"
	.global t_080bbaac
t_080bbaac:	.asciz "20M Limit:"
	.global t_080bbc37
t_080bbc37:	.asciz "OFF"
	.global t_080bbc55
t_080bbc55:	.asciz "ON"

@ ----------------------------------------------------------------------------
@ Cursor labels (draw_waveform_display, fn_08012ff4)
@ ----------------------------------------------------------------------------
	.global t_080bba0c
t_080bba0c:	.asciz "X1:"
	.global t_080bba17
t_080bba17:	.asciz "X2:"
	.global t_080bba14
t_080bba14:	.asciz "X1-X2:"
	.global t_080bba10
t_080bba10:	.asciz "Y1:"
	.global t_080bba1e
t_080bba1e:	.asciz "Y2:"
	.global t_080bba1b
t_080bba1b:	.asciz "Y1-Y2:"
	.global t_080bbabd
t_080bbabd:	.asciz "1/d|X|:"
	.global t_080bb97c
t_080bb97c:	.asciz "Y1"
	.global t_080bb9e4
t_080bb9e4:	.asciz "X2"
	.global t_080bb9e7
t_080bb9e7:	.asciz "Y2"

@ ----------------------------------------------------------------------------
@ Multimeter gauge (draw_arc_gauge): range / state texts and number formats
@ ----------------------------------------------------------------------------
	.global t_080bbc60
t_080bbc60:	.asciz "AUTO"
	.global t_080bbc48
t_080bbc48:	.asciz ".OL"
	.global t_080bb414
t_080bb414:	.asciz " "
	.global t_080bbc44
t_080bbc44:	.asciz "CAL"
	.global t_080bbc76
t_080bbc76:	.asciz "PAS"
	.global t_080bb97f
t_080bb97f:	.asciz "Er1"
	.global t_080bb9ea
t_080bb9ea:	.asciz "Er2"
	.global t_080bb9ee
t_080bb9ee:	.asciz "Er3"
	.global t_080bbc2e
t_080bbc2e:	.asciz "ErC"
	.global t_080bc32c
t_080bc32c:	.asciz "%.0f"
	.global t_080bc331
t_080bc331:	.asciz "%.1f"
	.global t_080bc336
t_080bc336:	.asciz "%.2f"
	.global t_080bc33b
t_080bc33b:	.asciz "%.3f"
	.global t_080bc340
t_080bc340:	.asciz "%.4f"
	.global t_080bc040
t_080bc040:	.asciz "%d"
	.global t_080bcc3f
t_080bcc3f:	.asciz "%ds"

@ ----------------------------------------------------------------------------
@ Dialogs: factory reset warning, delete confirmation (draw_page_by_selector_nibble,
@ draw_image_and_three_texts)
@ ----------------------------------------------------------------------------
	.global t_080bc8a6
t_080bc8a6:	.asciz "Caution"
	.global t_080bb479
t_080bb479:	.asciz "Settings return to defaults."	@ one line in the 190-pixel box: the drawn text breaks inside words (V1.2.0's "Factory reset will undo all previous changes!" showed "previ / ous" with this rewrite's fonts, 1.4.3)
	.global t_080bc8d7
t_080bc8d7:	.asciz "Return"
	.global t_080bc25e
t_080bc25e:	.asciz "Delete"
	.global t_080bc767
t_080bc767:	.asciz "Confirm"
	.global t_080bc70e
t_080bc70e:	.asciz "Cancel"

@ ----------------------------------------------------------------------------
@ Kernel task names (create_idle_and_tmr_svc_tasks, create_tmr_svc_record_or_halt)
@ ----------------------------------------------------------------------------
	.global t_080bbc32
t_080bbc32:	.asciz "IDLE"
	.global t_080bc038
t_080bc038:	.asciz "Tmr Svc"

@ ----------------------------------------------------------------------------
@ Drives, folders and files (users: filesystem_startup_setup_unlocked, capture_io_01.s, the UI pages; picture
@ files NN.jpg drawn by the UI pages, screenshot and capture files)
@ ----------------------------------------------------------------------------
	.global t_080bba1f
t_080bba1f:	.asciz "2:"
	.global t_080bba22
t_080bba22:	.asciz "3:"
	.global t_080bb927
t_080bb927:	.asciz "2:/"
	.global t_080bb92b
t_080bb92b:	.asciz "3:/"
	.global t_080bbc58
t_080bbc58:	.asciz "2:/LOGO"
	.global t_080bc66b
t_080bc66b:	.asciz "2:/LOGO/LOGO2C53T.jpg"
	.global t_080bc18b
t_080bc18b:	.asciz "2:/Screenshot simple file"
	.global t_080bc859
t_080bc859:	.asciz "2:/Screenshot simple file/%d.bin"
	.global t_080bc1b4
t_080bc1b4:	.asciz "2:/Screenshot file"
	.global t_080bcad2
t_080bcad2:	.asciz "2:/Screenshot file/%d.bmp"
	.global t_080bcae5
t_080bcae5:	.asciz "%d.bmp"
	.global t_080bc1a5
t_080bc1a5:	.asciz "3:/System file"
	.global t_080bc841
t_080bc841:	.asciz "3:/System file/9999.bin"
	.global t_080bc681
t_080bc681:	.asciz "3:/System file/%d.jpg"
	.global t_080bc51e
t_080bc51e:	.asciz "3:/System file/5.jpg"
	.global t_080bc576
t_080bc576:	.asciz "3:/System file/6.jpg"
	.global t_080bc456
t_080bc456:	.asciz "3:/System file/71.jpg"
	.global t_080bc499
t_080bc499:	.asciz "3:/System file/72.jpg"
	.global t_080bc4f2
t_080bc4f2:	.asciz "3:/System file/74.jpg"
	.global t_080bc54a
t_080bc54a:	.asciz "3:/System file/75.jpg"
	.global t_080bc5cf
t_080bc5cf:	.asciz "3:/System file/77.jpg"
	.global t_080bc5fc
t_080bc5fc:	.asciz "3:/System file/78.jpg"
	.global t_080bc63f
t_080bc63f:	.asciz "3:/System file/79.jpg"
	.global t_080bc429
t_080bc429:	.asciz "3:/System file/80.jpg"
	.global t_080bc4af
t_080bc4af:	.asciz "3:/System file/82.jpg"
	.global t_080bc508
t_080bc508:	.asciz "3:/System file/84.jpg"
	.global t_080bc5a2
t_080bc5a2:	.asciz "3:/System file/86.jpg"
	.global t_080bc612
t_080bc612:	.asciz "3:/System file/88.jpg"
	.global t_080bc655
t_080bc655:	.asciz "3:/System file/89.jpg"
	.global t_080bc3fb
t_080bc3fb:	.asciz "3:/System file/120.jpg"
	.global t_080bc58b
t_080bc58b:	.asciz "3:/System file/136.jpg"
	.global t_080bc5b8
t_080bc5b8:	.asciz "3:/System file/137.jpg"
	.global t_080bc5e5
t_080bc5e5:	.asciz "3:/System file/138.jpg"
	.global t_080bc628
t_080bc628:	.asciz "3:/System file/139.jpg"
	.global t_080bc412
t_080bc412:	.asciz "3:/System file/140.jpg"
	.global t_080bc4c5
t_080bc4c5:	.asciz "3:/System file/143.jpg"
	.global t_080bc533
t_080bc533:	.asciz "3:/System file/145.jpg"
