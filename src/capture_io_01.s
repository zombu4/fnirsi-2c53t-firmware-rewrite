@ capture_io_01.s - screenshot / capture file helpers: name search in "2:/Screenshot file", numbered .bin read-back, capture directory scan.
@ Part of the FNIRSI 2C53T firmware rewrite (hand-written Thumb-2 assembly).
	.syntax unified
	.arch armv7e-m
	.fpu fpv4-sp-d16
	.thumb

@ ----------------------------------------------------------------------------
@ screenshot_file_find_name - searches the directory "2:/Screenshot file" for an
@ entry whose first 9 name bytes match the string at 0x20008360.
@ Allocates 0x118 and 0x30 bytes with alloc_units_of_32_bytes (0803acfc), opens
@ the directory with dir_open (08034c40), reads entries with dir_read_entry
@ (08034f20), copies 10 bytes of the entry name (entry+0x16) with
@ copy_string_padded (080077a8) into a buffer at sp+1, stores 0 at sp+10 (the
@ tenth byte, so 9 bytes remain) and compares with compare_strings (08007800)
@ (copy, 0x20008360).
@ Returns (r0, byte): 3 on allocation failure, 1 when the directory cannot be
@ opened, 2 when a read fails or the name is empty (end), 0 when a compare
@ returns 0. Buffers are freed with free_units_of_32_bytes (0803acbc) and the
@ directory is closed with object_release (080341c4).
@ ----------------------------------------------------------------------------
	.section .text.screenshot_file_find_name,"ax",%progbits
	.global screenshot_file_find_name
	.thumb_func
	.type screenshot_file_find_name, %function
screenshot_file_find_name:
	push	{r7, lr}
	sub	sp, #0x20
	movw	r0, #:lower16:t_080bc1b4	@ "2:/Screenshot file"
	movt	r0, #:upper16:t_080bc1b4
	str	r0, [sp, #0x18]
	movw	r0, #0x8360	@ name string at 0x20008360
	movt	r0, #0x2000
	str	r0, [sp, #0x14]
	mov.w	r0, #0x118	@ entry buffer size
	bl	alloc_units_of_32_bytes
	str	r0, [sp, #0x10]
	ldr	r0, [sp, #0x10]
	cbnz	r0, .L08035a38
	b.n	.L08035a30
.L08035a30:
	movs	r0, #0x3	@ allocation failure
	strb.w	r0, [sp, #0x1f]
	b.n	.L08035af2
.L08035a38:
	movs	r0, #0x30	@ directory object size
	bl	alloc_units_of_32_bytes
	str	r0, [sp, #0xc]
	ldr	r0, [sp, #0xc]
	cbnz	r0, .L08035a54
	b.n	.L08035a46
.L08035a46:
	ldr	r0, [sp, #0x10]
	bl	free_units_of_32_bytes
	movs	r0, #0x3
	strb.w	r0, [sp, #0x1f]
	b.n	.L08035af2
.L08035a54:
	ldr	r0, [sp, #0xc]
	ldr	r1, [sp, #0x18]
	bl	dir_open
	strb.w	r0, [sp, #0xb]
	ldrb.w	r0, [sp, #0xb]
	cbz	r0, .L08035a7c
	b.n	.L08035a68
.L08035a68:
	ldr	r0, [sp, #0x10]
	bl	free_units_of_32_bytes
	ldr	r0, [sp, #0xc]
	bl	free_units_of_32_bytes
	movs	r0, #0x1	@ directory cannot be opened
	strb.w	r0, [sp, #0x1f]
	b.n	.L08035af2
.L08035a7c:
	b.n	.L08035a7e
.L08035a7e:
	ldr	r0, [sp, #0xc]
	ldr	r1, [sp, #0x10]
	bl	dir_read_entry
	strb.w	r0, [sp, #0xb]
	ldrb.w	r0, [sp, #0xb]
	cbnz	r0, .L08035a9a
	b.n	.L08035a92
.L08035a92:
	ldr	r0, [sp, #0x10]
	ldrb	r0, [r0, #0x16]	@ first name byte
	cbnz	r0, .L08035a9c
	b.n	.L08035a9a
.L08035a9a:
	b.n	.L08035ad8	@ read failed or name empty
.L08035a9c:
	ldr	r0, [sp, #0x10]
	add.w	r1, r0, #0x16
	add.w	r0, sp, #0x1
	movs	r2, #0xa
	bl	copy_string_padded
	movs	r1, #0x0
	strb.w	r1, [sp, #0xa]	@ terminate after 9 bytes
	ldr	r1, [sp, #0x14]
	bl	compare_strings
	cbnz	r0, .L08035ad6
	b.n	.L08035abc
.L08035abc:
	ldr	r0, [sp, #0xc]
	bl	object_release
	ldr	r0, [sp, #0x10]
	bl	free_units_of_32_bytes
	ldr	r0, [sp, #0xc]
	bl	free_units_of_32_bytes
	movs	r0, #0x0	@ match found
	strb.w	r0, [sp, #0x1f]
	b.n	.L08035af2
.L08035ad6:
	b.n	.L08035a7e
.L08035ad8:
	ldr	r0, [sp, #0xc]
	bl	object_release
	ldr	r0, [sp, #0x10]
	bl	free_units_of_32_bytes
	ldr	r0, [sp, #0xc]
	bl	free_units_of_32_bytes
	movs	r0, #0x2	@ end of directory
	strb.w	r0, [sp, #0x1f]
	b.n	.L08035af2
.L08035af2:
	ldrb.w	r0, [sp, #0x1f]
	add	sp, #0x20
	pop	{r7, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ read_numbered_bin_file - reads back the 0x25f-byte capture file
@ "2:/Screenshot simple file/<n>.bin".
@ Parameter r0 (byte) = file number. Returns in r0 a status left there by
@ movs r0,#n before the epilogue: 1 when the 0x102c-byte allocation fails, 2
@ when file_open returns nonzero, 0 when the 0x25f bytes were read, 3 when the
@ buffer is null, the read fails or n != 0x25f.
@ Allocates 0x102c bytes (file object) with alloc_units_of_32_bytes (0803acfc);
@ status 1 and return if that fails. Formats
@ "2:/Screenshot simple file/%d.bin" with format_to_buffer_08007370 into
@ 0x20008360; opens it with file_open (080348b8)(obj, 0x20008360, 1). If that
@ returns 0: when the word 0x20000f18 is 0 it allocates 0x25f bytes with
@ alloc_units_of_32_bytes into it, then reads 0x25f bytes into that buffer with
@ file_read (08034cbc)(obj, 0x20000f18, 0x25f, &n). When the buffer is null, the
@ read fails or n != 0x25f it calls file_close (08034014) and then path_delete
@ (0803512c) (delete of the file named at 0x20008360), otherwise only
@ file_close; then frees the object with free_units_of_32_bytes (0803acbc).
@ When file_open returns nonzero it calls path_delete and frees the object.
@ Reads back the 0x25f bytes (0x25a buffer bytes + 5) that 0803ced4 writes.
@ ----------------------------------------------------------------------------
	.section .text.read_numbered_bin_file,"ax",%progbits
	.global read_numbered_bin_file
	.thumb_func
	.type read_numbered_bin_file, %function
read_numbered_bin_file:
	push	{r4, lr}
	sub	sp, #0x10
	strb.w	r0, [sp, #0xe]
	movw	r0, #0x102c	@ file object size
	bl	alloc_units_of_32_bytes
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	cbnz	r0, .L0803a330
	b.n	.L0803a328
.L0803a328:
	movs	r0, #0x1	@ allocation failed
	strb.w	r0, [sp, #0xf]
	b.n	.L0803a406
.L0803a330:
	ldrb.w	r2, [sp, #0xe]
	movw	r4, #0x8360
	movt	r4, #0x2000
	movw	r1, #:lower16:t_080bc859	@ format string "2:/Screenshot simple file/%d.bin"
	movt	r1, #:upper16:t_080bc859
	mov	r0, r4
	bl	format_to_buffer_08007370
	ldr	r0, [sp, #0x8]
	mov	r1, r4
	movs	r2, #0x1
	bl	file_open
	strb.w	r0, [sp, #0x7]
	ldrb.w	r0, [sp, #0x7]
	cbz	r0, .L0803a372
	b.n	.L0803a360
.L0803a360:
	bl	path_delete
	ldr	r0, [sp, #0x8]
	bl	free_units_of_32_bytes
	movs	r0, #0x2	@ file_open failed
	strb.w	r0, [sp, #0xf]
	b.n	.L0803a406
.L0803a372:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldr.w	r0, [r0, #0xe20]	@ word at 0x20000f18 (read buffer pointer)
	cbnz	r0, .L0803a398
	b.n	.L0803a382
.L0803a382:
	movw	r0, #0x25f
	bl	alloc_units_of_32_bytes
	movw	r1, #0xf8
	movt	r1, #0x2000
	str.w	r0, [r1, #0xe20]
	b.n	.L0803a398
.L0803a398:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldr.w	r0, [r0, #0xe20]
	cbz	r0, .L0803a3ee
	b.n	.L0803a3a8
.L0803a3a8:
	ldr	r0, [sp, #0x8]
	movw	r1, #0xf8
	movt	r1, #0x2000
	ldr.w	r1, [r1, #0xe20]
	mov	r3, sp
	movw	r2, #0x25f
	bl	file_read
	strb.w	r0, [sp, #0x7]
	ldrb.w	r0, [sp, #0x7]
	cbnz	r0, .L0803a3ec
	b.n	.L0803a3cc
.L0803a3cc:
	ldr	r0, [sp, #0x0]
	movw	r1, #0x25f
	cmp	r0, r1
	bne.n	.L0803a3ec
	b.n	.L0803a3d8
.L0803a3d8:
	ldr	r0, [sp, #0x8]
	bl	file_close
	ldr	r0, [sp, #0x8]
	bl	free_units_of_32_bytes
	movs	r0, #0x0	@ 0x25f bytes read
	strb.w	r0, [sp, #0xf]
	b.n	.L0803a406
.L0803a3ec:
	b.n	.L0803a3ee
.L0803a3ee:
	ldr	r0, [sp, #0x8]
	bl	file_close
	bl	path_delete
	ldr	r0, [sp, #0x8]
	bl	free_units_of_32_bytes
	movs	r0, #0x3	@ buffer null, read failed or wrong length
	strb.w	r0, [sp, #0xf]
	b.n	.L0803a406
.L0803a406:
	add	sp, #0x10
	pop	{r4, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ scan_capture_files - scans a directory of captures and builds the sorted list
@ of capture numbers.
@ Parameter r0 = path argument passed to dir_open (08034c40) (directory open).
@ Returns the file count (byte) or 0xff.
@ Allocates 0x30 bytes (directory object) and 0x118 bytes (entry buffer) with
@ alloc_units_of_32_bytes (0803acfc); returns 0xff if an allocation fails
@ (frees the first on second failure). Opens with dir_open(dir, r0); when that
@ returns 0 it loops dir_read_entry (08034f20)(dir, entry) while it returns 0
@ and the name byte entry+0x16 is nonzero: number = parse_signed_decimal
@ (0803012c)(entry+0x16) (low byte); formats "%d.bmp" into 0x20008360 with
@ format_to_buffer_08007370 (08007370) and calls screenshot_file_find_name
@ (08035a08) (search in "2:/Screenshot file"); if that returns 0 the number is
@ stored at 0x20000f1d[count] and count is incremented, else it formats
@ "2:/Screenshot simple file/%d.bin" into 0x20008360 and calls path_delete
@ (0803512c) (delete the .bin).
@ Then calls sort_bytes_ascending (0803085c)(count) (sort over 0x20000f1d), sets
@ byte 0x20000f09 = 1 if count == 0 else byte 0x20000f1c[count] + 1 (largest
@ number + 1), frees both blocks with free_units_of_32_bytes (0803acbc) and
@ returns count.
@ ----------------------------------------------------------------------------
	.section .text.scan_capture_files,"ax",%progbits
	.global scan_capture_files
	.thumb_func
	.type scan_capture_files, %function
scan_capture_files:
	push	{r7, lr}
	sub	sp, #0x18
	str	r0, [sp, #0x10]	@ path argument
	movs	r0, #0x0
	strb.w	r0, [sp, #0xe]	@ count = 0
	movs	r0, #0x30	@ directory object
	bl	alloc_units_of_32_bytes
	str	r0, [sp, #0x8]
	ldr	r0, [sp, #0x8]
	cbnz	r0, .L0803b89a
	b.n	.L0803b892
.L0803b892:
	movs	r0, #0xff	@ allocation failure
	strb.w	r0, [sp, #0x17]
	b.n	.L0803b9ae
.L0803b89a:
	mov.w	r0, #0x118	@ entry buffer
	bl	alloc_units_of_32_bytes
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	cbnz	r0, .L0803b8b8
	b.n	.L0803b8aa
.L0803b8aa:
	ldr	r0, [sp, #0x8]
	bl	free_units_of_32_bytes
	movs	r0, #0xff
	strb.w	r0, [sp, #0x17]
	b.n	.L0803b9ae
.L0803b8b8:
	ldr	r0, [sp, #0x8]
	ldr	r1, [sp, #0x10]
	bl	dir_open
	strb.w	r0, [sp, #0xf]
	ldrb.w	r0, [sp, #0xf]
	cmp	r0, #0x0
	bne.n	.L0803b95e
	b.n	.L0803b8ce
.L0803b8ce:
	b.n	.L0803b8d0
.L0803b8d0:
	ldr	r0, [sp, #0x8]
	ldr	r1, [sp, #0x4]
	bl	dir_read_entry
	strb.w	r0, [sp, #0xf]
	ldrb.w	r0, [sp, #0xf]
	cbnz	r0, .L0803b8ec
	b.n	.L0803b8e4
.L0803b8e4:
	ldr	r0, [sp, #0x4]
	ldrb	r0, [r0, #0x16]	@ first name byte
	cbnz	r0, .L0803b8ee
	b.n	.L0803b8ec
.L0803b8ec:
	b.n	.L0803b95c	@ end of directory
.L0803b8ee:
	ldr	r0, [sp, #0x4]
	adds	r0, #0x16
	bl	parse_signed_decimal
	strb.w	r0, [sp, #0x3]	@ number (low byte)
	ldrb.w	r2, [sp, #0x3]
	movw	r0, #0x8360
	movt	r0, #0x2000
	movw	r1, #:lower16:t_080bcae5	@ format string "%d.bmp"
	movt	r1, #:upper16:t_080bcae5
	bl	format_to_buffer_08007370
	bl	screenshot_file_find_name
	cbnz	r0, .L0803b93c
	b.n	.L0803b91a
.L0803b91a:
	ldrb.w	r0, [sp, #0x3]
	ldrb.w	r1, [sp, #0xe]
	movw	r2, #0xf8
	movt	r2, #0x2000
	add	r1, r2
	strb.w	r0, [r1, #0xe25]	@ 0x20000f1d[count] = number
	ldrb.w	r0, [sp, #0xe]
	adds	r0, #0x1
	strb.w	r0, [sp, #0xe]	@ count++
	b.n	.L0803b95a
.L0803b93c:
	ldrb.w	r2, [sp, #0x3]
	movw	r0, #0x8360
	movt	r0, #0x2000
	movw	r1, #:lower16:t_080bc859	@ format string "2:/Screenshot simple file/%d.bin"
	movt	r1, #:upper16:t_080bc859
	bl	format_to_buffer_08007370
	bl	path_delete	@ delete the .bin without a .bmp
	b.n	.L0803b95a
.L0803b95a:
	b.n	.L0803b8d0
.L0803b95c:
	b.n	.L0803b95e
.L0803b95e:
	ldrb.w	r0, [sp, #0xe]
	bl	sort_bytes_ascending
	ldrb.w	r0, [sp, #0xe]
	cbz	r0, .L0803b988
	b.n	.L0803b96e
.L0803b96e:
	ldrb.w	r0, [sp, #0xe]
	movw	r1, #0xf8
	movt	r1, #0x2000
	add	r0, r1
	ldrb.w	r0, [r0, #0xe24]	@ 0x20000f1c[count] = largest number
	adds	r0, #0x1
	strb.w	r0, [r1, #0xe11]	@ byte 0x20000f09 = largest + 1
	b.n	.L0803b998
.L0803b988:
	movw	r0, #0xf8
	movt	r0, #0x2000
	movs	r1, #0x1
	strb.w	r1, [r0, #0xe11]	@ byte 0x20000f09 = 1 (no files)
	b.n	.L0803b998
.L0803b998:
	ldr	r0, [sp, #0x8]
	bl	free_units_of_32_bytes
	ldr	r0, [sp, #0x4]
	bl	free_units_of_32_bytes
	ldrb.w	r0, [sp, #0xe]
	strb.w	r0, [sp, #0x17]
	b.n	.L0803b9ae
.L0803b9ae:
	ldrb.w	r0, [sp, #0x17]
	add	sp, #0x18
	pop	{r7, pc}
	.short	0x0000	@ padding

@ ----------------------------------------------------------------------------
@ write_numbered_bin_file - writes the 0x25f-byte capture file
@ "2:/Screenshot simple file/<n>.bin".
@ No parameters; returns a status byte: 0 success, 1 allocation failed, 2 open
@ failed, 3 final write failed, 4 seek failed, 5 file size word is -1, 6 first
@ write short or failed.
@ Allocates 0x102c bytes (alloc_units_of_32_bytes, 0803acfc); formats
@ "2:/Screenshot simple file/%d.bin" with byte 0x20000f09 into 0x20008360 (via
@ format_to_buffer_08007370), opens with file_open (080348b8)(buf, path, 10);
@ writes 0x25a bytes from 0x2000044e with file_write (08035530) (count in
@ local); when buf[0xc] (the file size word) is -1 it returns 5, otherwise
@ seeks with file_seek (080341e8)(buf, buf[0xc]) (to the end of the file) and
@ appends 5 bytes: (0x2000012c == 1 ? 4 : byte 0x2000010c), then the high byte
@ 0x20000ead and low byte 0x20000eac of the ushort 0x20000eac, then the high
@ byte 0x20000eaf and low byte 0x20000eae of the ushort 0x20000eae.
@ Error paths call file_close (08034014) and path_delete (0803512c) (delete);
@ every path frees the buffer with free_units_of_32_bytes (0803acbc). The 0x25f
@ bytes are read back by read_numbered_bin_file (0803a310).
@ ----------------------------------------------------------------------------
	.section .text.write_numbered_bin_file,"ax",%progbits
	.global write_numbered_bin_file
	.thumb_func
	.type write_numbered_bin_file, %function
write_numbered_bin_file:
	push	{r4, lr}
	sub	sp, #0x20
	movw	r0, #0x102c	@ file object size
	bl	alloc_units_of_32_bytes
	str	r0, [sp, #0x18]
	ldr	r0, [sp, #0x18]
	cbnz	r0, .L0803cef0
	b.n	.L0803cee8
.L0803cee8:
	movs	r0, #0x1	@ allocation failed
	strb.w	r0, [sp, #0x1f]
	b.n	.L0803d07c
.L0803cef0:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r2, [r0, #0xe11]	@ byte 0x20000f09 = file number
	movw	r4, #0x8360
	movt	r4, #0x2000
	movw	r1, #:lower16:t_080bc859	@ format string "2:/Screenshot simple file/%d.bin"
	movt	r1, #:upper16:t_080bc859
	mov	r0, r4
	bl	format_to_buffer_08007370
	ldr	r0, [sp, #0x18]
	mov	r1, r4
	movs	r2, #0xa
	bl	file_open
	strb.w	r0, [sp, #0x17]
	ldrb.w	r0, [sp, #0x17]
	cbz	r0, .L0803cf3a
	b.n	.L0803cf28
.L0803cf28:
	bl	path_delete
	ldr	r0, [sp, #0x18]
	bl	free_units_of_32_bytes
	movs	r0, #0x2	@ open failed
	strb.w	r0, [sp, #0x1f]
	b.n	.L0803d07c
.L0803cf3a:
	ldr	r0, [sp, #0x18]
	movw	r1, #0xf8
	movt	r1, #0x2000
	addw	r1, r1, #0x356	@ 0x2000044e
	add	r3, sp, #0x10
	movw	r2, #0x25a
	bl	file_write
	strb.w	r0, [sp, #0x17]
	ldrb.w	r0, [sp, #0x17]
	cmp	r0, #0x0
	bne.n	.L0803d050
	b.n	.L0803cf60
.L0803cf60:
	ldr	r0, [sp, #0x10]
	movw	r1, #0x25a
	cmp	r0, r1
	bne.n	.L0803d050
	b.n	.L0803cf6c
.L0803cf6c:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x34]	@ byte 0x2000012c
	cmp	r0, #0x1
	bne.n	.L0803cf86
	b.n	.L0803cf7e
.L0803cf7e:
	movs	r0, #0x4
	strb.w	r0, [sp, #0xb]
	b.n	.L0803cf96
.L0803cf86:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb	r0, [r0, #0x14]	@ byte 0x2000010c
	strb.w	r0, [sp, #0xb]
	b.n	.L0803cf96
.L0803cf96:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r1, [r0, #0xdb5]	@ high byte of ushort 0x20000eac
	strb.w	r1, [sp, #0xc]
	ldrh.w	r1, [r0, #0xdb4]	@ ushort 0x20000eac (low byte stored)
	strb.w	r1, [sp, #0xd]
	ldrb.w	r1, [r0, #0xdb7]	@ high byte of ushort 0x20000eae
	strb.w	r1, [sp, #0xe]
	ldrh.w	r0, [r0, #0xdb6]	@ ushort 0x20000eae (low byte stored)
	strb.w	r0, [sp, #0xf]
	ldr	r0, [sp, #0x18]
	ldr	r0, [r0, #0xc]	@ file size word
	str	r0, [sp, #0x4]
	ldr	r0, [sp, #0x4]
	adds	r0, #0x1	@ sets Z when the size word is -1
	cbz	r0, .L0803d036
	b.n	.L0803cfcc
.L0803cfcc:
	ldr	r0, [sp, #0x18]
	ldr	r1, [sp, #0x4]
	bl	file_seek	@ seek to the end of the file
	strb.w	r0, [sp, #0x17]
	ldrb.w	r0, [sp, #0x17]
	cbnz	r0, .L0803d01c
	b.n	.L0803cfe0
.L0803cfe0:
	ldr	r0, [sp, #0x18]
	add.w	r1, sp, #0xb
	add	r3, sp, #0x10
	movs	r2, #0x5	@ append 5 bytes
	bl	file_write
	strb.w	r0, [sp, #0x17]
	ldrb.w	r0, [sp, #0x17]
	cbnz	r0, .L0803d002
	b.n	.L0803cffa
.L0803cffa:
	ldr	r0, [sp, #0x10]
	cmp	r0, #0x5
	beq.n	.L0803d01a
	b.n	.L0803d002
.L0803d002:
	ldr	r0, [sp, #0x18]
	bl	file_close
	bl	path_delete
	ldr	r0, [sp, #0x18]
	bl	free_units_of_32_bytes
	movs	r0, #0x3	@ final write failed
	strb.w	r0, [sp, #0x1f]
	b.n	.L0803d07c
.L0803d01a:
	b.n	.L0803d034
.L0803d01c:
	ldr	r0, [sp, #0x18]
	bl	file_close
	bl	path_delete
	ldr	r0, [sp, #0x18]
	bl	free_units_of_32_bytes
	movs	r0, #0x4	@ seek failed
	strb.w	r0, [sp, #0x1f]
	b.n	.L0803d07c
.L0803d034:
	b.n	.L0803d04e
.L0803d036:
	ldr	r0, [sp, #0x18]
	bl	file_close
	bl	path_delete
	ldr	r0, [sp, #0x18]
	bl	free_units_of_32_bytes
	movs	r0, #0x5	@ file size word is -1
	strb.w	r0, [sp, #0x1f]
	b.n	.L0803d07c
.L0803d04e:
	b.n	.L0803d068
.L0803d050:
	ldr	r0, [sp, #0x18]
	bl	file_close
	bl	path_delete
	ldr	r0, [sp, #0x18]
	bl	free_units_of_32_bytes
	movs	r0, #0x6	@ first write short or failed
	strb.w	r0, [sp, #0x1f]
	b.n	.L0803d07c
.L0803d068:
	ldr	r0, [sp, #0x18]
	bl	file_close
	ldr	r0, [sp, #0x18]
	bl	free_units_of_32_bytes
	movs	r0, #0x0	@ success
	strb.w	r0, [sp, #0x1f]
	b.n	.L0803d07c
.L0803d07c:
	ldrb.w	r0, [sp, #0x1f]
	add	sp, #0x20
	pop	{r4, pc}

@ ----------------------------------------------------------------------------
@ save_screen_bmp - saves the screen as a 320x240 16-bit BMP file.
@ No parameters; returns 0 on success, 1 on failure.
@ Allocates 0x102c bytes (alloc_units_of_32_bytes, 0803acfc; failure returns 1),
@ opens the file named at 0x20008360 with file_open (080348b8)(buf, 0x20008360,
@ 10), writes a 0x36-byte header with file_write (08035530): 'B','M', file size
@ 0x25836, reserved 0, data offset 0x36, info header size 0x28, width 0x140,
@ height 0xffffff10 (-240, top-down), planes 1, 16 bits per pixel, compression 0,
@ image size 0x25800 (320*240*2), 2835 pixels per metre in both directions,
@ colour counts 0.
@ Then renders three bands into a halfword buffer allocated with
@ alloc_units_of_32_bytes and described by the clip rectangle words
@ 0x20008350/52/54/56 (x, y, w, h) and the buffer word 0x20008358:
@  (0,0,0x140,0x14), 0x3200 bytes: jump_indirect_through_table (08012cd4) with
@   8, 2, 9, then 10 or 7 depending on all_bits_set (080374e0)(0x40011000, 0x80);
@  (0,0x14,0x140,0xc9), 0x1f680 bytes: cleared with fill_halfwords (0803ac6c)
@   (buf, 0, w*h), then jump_indirect_through_table with 3 and, when byte
@   0x2000012c == 0, with 5 and 6;
@  (0,0xdd,0x140,0x13), 0x2f80 bytes: jump_indirect_through_table with 4.
@ Each halfword v is replaced by ((v>>6)<<5)|(v&0x1f) (bits 15..6 move down by
@ one position into bits 14..5, bit 5 is dropped, bits 4..0 are kept); w*h*2
@ bytes are written with file_write and the band buffer is freed with
@ free_units_of_32_bytes (0803acbc) (a band whose allocation fails is skipped).
@ On any write failure it calls file_close (08034014), frees the file buffer and
@ the band buffer and returns 1 (a failed open frees the file buffer and returns
@ 1); success ends with file_close and freeing the file buffer, returns 0.
@ ----------------------------------------------------------------------------
	.section .text.save_screen_bmp,"ax",%progbits
	.global save_screen_bmp
	.thumb_func
	.type save_screen_bmp, %function
save_screen_bmp:
	push	{r4, lr}
	sub	sp, #0x68
	movw	r0, #0x8360
	movt	r0, #0x2000
	str	r0, [sp, #0x60]	@ path at 0x20008360
	movw	r0, #0x102c	@ file object size
	bl	alloc_units_of_32_bytes
	str	r0, [sp, #0x5c]
	ldr	r0, [sp, #0x5c]
	cbnz	r0, .L0803d0aa
	b.n	.L0803d0a2
.L0803d0a2:
	movs	r0, #0x1	@ allocation failed
	strb.w	r0, [sp, #0x67]
	b.n	.L0803d5cc
.L0803d0aa:
	ldr	r0, [sp, #0x5c]
	ldr	r1, [sp, #0x60]
	movs	r2, #0xa
	bl	file_open
	strb.w	r0, [sp, #0x5b]
	ldrb.w	r0, [sp, #0x5b]
	cbz	r0, .L0803d0ce
	b.n	.L0803d0c0
.L0803d0c0:
	ldr	r0, [sp, #0x5c]
	bl	free_units_of_32_bytes
	movs	r0, #0x1	@ open failed
	strb.w	r0, [sp, #0x67]
	b.n	.L0803d5cc
.L0803d0ce:
	mov.w	r0, #0x280	@ row bytes (320*2)
	str	r0, [sp, #0x54]
	ldr	r0, [sp, #0x54]
	rsb	r0, r0, r0, lsl #4	@ *15
	lsls	r0, r0, #0x4	@ *16 -> 0x25800 image size
	str	r0, [sp, #0x50]
	ldr	r0, [sp, #0x50]
	adds	r0, #0x36	@ + header = 0x25836 file size
	str	r0, [sp, #0x4c]
	@ 54-byte BMP header built in the stack at sp+0x16..sp+0x4b
	movs	r0, #0x42	@ 'B'
	strb.w	r0, [sp, #0x16]
	movs	r0, #0x4d	@ 'M'
	strb.w	r0, [sp, #0x17]
	ldr	r0, [sp, #0x4c]	@ file size, bytes 0..3
	strb.w	r0, [sp, #0x18]
	ldr	r0, [sp, #0x4c]
	lsrs	r0, r0, #0x8
	strb.w	r0, [sp, #0x19]
	ldrh.w	r0, [sp, #0x4e]
	strb.w	r0, [sp, #0x1a]
	ldrb.w	r0, [sp, #0x4f]
	strb.w	r0, [sp, #0x1b]
	movs	r0, #0x0
	strb.w	r0, [sp, #0x1c]	@ reserved = 0
	strb.w	r0, [sp, #0x1d]
	strb.w	r0, [sp, #0x1e]
	strb.w	r0, [sp, #0x1f]
	movs	r1, #0x36
	strb.w	r1, [sp, #0x20]	@ data offset = 0x36
	strb.w	r0, [sp, #0x21]
	strb.w	r0, [sp, #0x22]
	strb.w	r0, [sp, #0x23]
	movs	r1, #0x28
	strb.w	r1, [sp, #0x24]	@ info header size = 0x28
	strb.w	r0, [sp, #0x25]
	strb.w	r0, [sp, #0x26]
	strb.w	r0, [sp, #0x27]
	movs	r1, #0x40
	strb.w	r1, [sp, #0x28]	@ width = 0x140
	movs	r1, #0x1
	strb.w	r1, [sp, #0x29]
	strb.w	r0, [sp, #0x2a]
	strb.w	r0, [sp, #0x2b]
	movs	r2, #0x10
	strb.w	r2, [sp, #0x2c]	@ height = 0xffffff10 (-240, top-down)
	movs	r3, #0xff
	strb.w	r3, [sp, #0x2d]
	strb.w	r3, [sp, #0x2e]
	strb.w	r3, [sp, #0x2f]
	strb.w	r1, [sp, #0x30]	@ planes = 1
	strb.w	r0, [sp, #0x31]
	strb.w	r2, [sp, #0x32]	@ 16 bits per pixel
	strb.w	r0, [sp, #0x33]
	strb.w	r0, [sp, #0x34]	@ compression = 0
	strb.w	r0, [sp, #0x35]
	strb.w	r0, [sp, #0x36]
	strb.w	r0, [sp, #0x37]
	ldr	r1, [sp, #0x50]	@ image size 0x25800, bytes 0..3
	strb.w	r1, [sp, #0x38]
	ldr	r1, [sp, #0x50]
	lsrs	r1, r1, #0x8
	strb.w	r1, [sp, #0x39]
	ldrh.w	r1, [sp, #0x52]
	strb.w	r1, [sp, #0x3a]
	ldrb.w	r1, [sp, #0x53]
	strb.w	r1, [sp, #0x3b]
	movs	r1, #0x13	@ 2835 = 0x0b13 pixels per metre (horizontal)
	strb.w	r1, [sp, #0x3c]
	movs	r2, #0xb
	strb.w	r2, [sp, #0x3d]
	strb.w	r0, [sp, #0x3e]
	strb.w	r0, [sp, #0x3f]
	strb.w	r1, [sp, #0x40]	@ 2835 pixels per metre (vertical)
	strb.w	r2, [sp, #0x41]
	strb.w	r0, [sp, #0x42]
	strb.w	r0, [sp, #0x43]
	strb.w	r0, [sp, #0x44]	@ colour counts = 0
	strb.w	r0, [sp, #0x45]
	strb.w	r0, [sp, #0x46]
	strb.w	r0, [sp, #0x47]
	strb.w	r0, [sp, #0x48]
	strb.w	r0, [sp, #0x49]
	strb.w	r0, [sp, #0x4a]
	strb.w	r0, [sp, #0x4b]
	ldr	r0, [sp, #0x5c]
	add.w	r1, sp, #0x16
	add	r3, sp, #0x10
	movs	r2, #0x36
	bl	file_write	@ write the 0x36-byte header
	strb.w	r0, [sp, #0x5b]
	ldrb.w	r0, [sp, #0x5b]
	cbnz	r0, .L0803d210
	b.n	.L0803d208
.L0803d208:
	ldr	r0, [sp, #0x10]
	cmp	r0, #0x36
	beq.n	.L0803d224
	b.n	.L0803d210
.L0803d210:
	ldr	r0, [sp, #0x5c]
	bl	file_close
	ldr	r0, [sp, #0x5c]
	bl	free_units_of_32_bytes
	movs	r0, #0x1	@ header write failed
	strb.w	r0, [sp, #0x67]
	b.n	.L0803d5cc
@ ---- band 1: rectangle (0,0,0x140,0x14) ----
.L0803d224:
	movw	r4, #0x8350	@ clip rectangle words at 0x20008350
	movt	r4, #0x2000
	movs	r0, #0x0
	strh	r0, [r4, #0x0]	@ x = 0
	strh	r0, [r4, #0x2]	@ y = 0
	mov.w	r0, #0x140
	strh	r0, [r4, #0x4]	@ w = 0x140
	movs	r0, #0x14
	strh	r0, [r4, #0x6]	@ h = 0x14
	ldrh	r0, [r4, #0x4]
	ldrh	r1, [r4, #0x6]
	muls	r0, r1
	lsls	r0, r0, #0x1	@ w*h*2 bytes
	bl	alloc_units_of_32_bytes
	str	r0, [r4, #0x8]	@ band buffer at 0x20008358
	ldr	r0, [r4, #0x8]
	cmp	r0, #0x0
	beq.w	.L0803d35c	@ allocation failed: skip band
	b.n	.L0803d254
.L0803d254:
	movs	r0, #0x8
	bl	jump_indirect_through_table
	movs	r0, #0x2
	bl	jump_indirect_through_table
	movs	r0, #0x9
	bl	jump_indirect_through_table
	movw	r0, #0x1000
	movt	r0, #0x4001	@ 0x40011000
	movs	r1, #0x80
	bl	all_bits_set
	cbnz	r0, .L0803d280
	b.n	.L0803d278
.L0803d278:
	movs	r0, #0xa
	bl	jump_indirect_through_table
	b.n	.L0803d288
.L0803d280:
	movs	r0, #0x7
	bl	jump_indirect_through_table
	b.n	.L0803d288
.L0803d288:
	movs	r0, #0x0
	strh.w	r0, [sp, #0xc]	@ i = 0
	b.n	.L0803d290
.L0803d290:
	ldrh.w	r0, [sp, #0xc]	@ i
	movw	r1, #0x8350
	movt	r1, #0x2000
	ldrh	r2, [r1, #0x4]
	ldrh	r1, [r1, #0x6]
	muls	r1, r2
	cmp	r0, r1
	bge.n	.L0803d304	@ i >= w*h: band converted
	b.n	.L0803d2a8
.L0803d2a8:
	movw	r0, #0x8350
	movt	r0, #0x2000
	ldr	r1, [r0, #0x8]
	ldrh.w	r2, [sp, #0xc]
	ldrh.w	r1, [r1, r2, lsl #0x1]
	and	r1, r1, #0x1f	@ low 5 bits kept
	strh.w	r1, [sp, #0xe]
	ldr	r1, [r0, #0x8]
	ldrh.w	r2, [sp, #0xc]
	ldrh.w	r3, [r1, r2, lsl #0x1]
	lsrs	r3, r3, #0x6
	strh.w	r3, [r1, r2, lsl #0x1]	@ v >> 6
	ldr	r1, [r0, #0x8]
	ldrh.w	r2, [sp, #0xc]
	ldrh.w	r3, [r1, r2, lsl #0x1]
	lsls	r3, r3, #0x5
	strh.w	r3, [r1, r2, lsl #0x1]	@ << 5
	ldrh.w	r1, [sp, #0xe]
	ldr	r0, [r0, #0x8]
	ldrh.w	r2, [sp, #0xc]
	ldrh.w	r3, [r0, r2, lsl #0x1]
	orrs	r1, r3	@ | low 5 bits
	strh.w	r1, [r0, r2, lsl #0x1]
	b.n	.L0803d2f8
.L0803d2f8:
	ldrh.w	r0, [sp, #0xc]
	adds	r0, #0x1
	strh.w	r0, [sp, #0xc]
	b.n	.L0803d290
.L0803d304:
	ldr	r0, [sp, #0x5c]
	movw	r2, #0x8350
	movt	r2, #0x2000
	ldr	r1, [r2, #0x8]
	ldrh	r3, [r2, #0x4]
	ldrh	r2, [r2, #0x6]
	muls	r2, r3
	lsls	r2, r2, #0x1
	add	r3, sp, #0x10
	bl	file_write	@ write the band (w*h*2 bytes)
	strb.w	r0, [sp, #0x5b]
	ldrb.w	r0, [sp, #0x5b]
	cbz	r0, .L0803d34c
	b.n	.L0803d32a
.L0803d32a:
	ldr	r0, [sp, #0x5c]
	bl	file_close
	ldr	r0, [sp, #0x5c]
	bl	free_units_of_32_bytes
	movw	r0, #0x8350
	movt	r0, #0x2000
	ldr	r0, [r0, #0x8]
	bl	free_units_of_32_bytes
	movs	r0, #0x1	@ band write failed
	strb.w	r0, [sp, #0x67]
	b.n	.L0803d5cc
.L0803d34c:
	movw	r0, #0x8350
	movt	r0, #0x2000
	ldr	r0, [r0, #0x8]
	bl	free_units_of_32_bytes	@ free the band buffer
	b.n	.L0803d35c
@ ---- band 2: rectangle (0,0x14,0x140,0xc9) ----
.L0803d35c:
	movw	r4, #0x8350
	movt	r4, #0x2000
	movs	r0, #0x0
	strh	r0, [r4, #0x0]	@ x = 0
	movs	r0, #0x14
	strh	r0, [r4, #0x2]	@ y = 0x14
	mov.w	r0, #0x140
	strh	r0, [r4, #0x4]	@ w = 0x140
	movs	r0, #0xc9
	strh	r0, [r4, #0x6]	@ h = 0xc9
	ldrh	r0, [r4, #0x4]
	ldrh	r1, [r4, #0x6]
	muls	r0, r1
	lsls	r0, r0, #0x1	@ w*h*2 bytes
	bl	alloc_units_of_32_bytes
	str	r0, [r4, #0x8]
	ldr	r0, [r4, #0x8]
	cmp	r0, #0x0
	beq.w	.L0803d4ae	@ allocation failed: skip band
	b.n	.L0803d38e
.L0803d38e:
	movw	r1, #0x8350
	movt	r1, #0x2000
	ldr	r0, [r1, #0x8]
	ldrh	r2, [r1, #0x4]
	ldrh	r1, [r1, #0x6]
	muls	r2, r1
	movs	r1, #0x0
	bl	fill_halfwords	@ clear w*h halfwords
	movs	r0, #0x3
	bl	jump_indirect_through_table
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x34]	@ byte 0x2000012c
	cbnz	r0, .L0803d3c2
	b.n	.L0803d3ba
.L0803d3ba:
	movs	r0, #0x5
	bl	jump_indirect_through_table
	b.n	.L0803d3c2
.L0803d3c2:
	movw	r0, #0xf8
	movt	r0, #0x2000
	ldrb.w	r0, [r0, #0x34]
	cbnz	r0, .L0803d3da
	b.n	.L0803d3d2
.L0803d3d2:
	movs	r0, #0x6
	bl	jump_indirect_through_table
	b.n	.L0803d3da
.L0803d3da:
	movs	r0, #0x0
	strh.w	r0, [sp, #0x8]	@ i = 0
	b.n	.L0803d3e2
.L0803d3e2:
	ldrh.w	r0, [sp, #0x8]	@ i
	movw	r1, #0x8350
	movt	r1, #0x2000
	ldrh	r2, [r1, #0x4]
	ldrh	r1, [r1, #0x6]
	muls	r1, r2
	cmp	r0, r1
	bge.n	.L0803d456	@ i >= w*h: band converted
	b.n	.L0803d3fa
.L0803d3fa:
	movw	r0, #0x8350
	movt	r0, #0x2000
	ldr	r1, [r0, #0x8]
	ldrh.w	r2, [sp, #0x8]
	ldrh.w	r1, [r1, r2, lsl #0x1]
	and	r1, r1, #0x1f	@ low 5 bits kept
	strh.w	r1, [sp, #0xa]
	ldr	r1, [r0, #0x8]
	ldrh.w	r2, [sp, #0x8]
	ldrh.w	r3, [r1, r2, lsl #0x1]
	lsrs	r3, r3, #0x6
	strh.w	r3, [r1, r2, lsl #0x1]	@ v >> 6
	ldr	r1, [r0, #0x8]
	ldrh.w	r2, [sp, #0x8]
	ldrh.w	r3, [r1, r2, lsl #0x1]
	lsls	r3, r3, #0x5
	strh.w	r3, [r1, r2, lsl #0x1]	@ << 5
	ldrh.w	r1, [sp, #0xa]
	ldr	r0, [r0, #0x8]
	ldrh.w	r2, [sp, #0x8]
	ldrh.w	r3, [r0, r2, lsl #0x1]
	orrs	r1, r3	@ | low 5 bits
	strh.w	r1, [r0, r2, lsl #0x1]
	b.n	.L0803d44a
.L0803d44a:
	ldrh.w	r0, [sp, #0x8]
	adds	r0, #0x1
	strh.w	r0, [sp, #0x8]
	b.n	.L0803d3e2
.L0803d456:
	ldr	r0, [sp, #0x5c]
	movw	r2, #0x8350
	movt	r2, #0x2000
	ldr	r1, [r2, #0x8]
	ldrh	r3, [r2, #0x4]
	ldrh	r2, [r2, #0x6]
	muls	r2, r3
	lsls	r2, r2, #0x1
	add	r3, sp, #0x10
	bl	file_write	@ write the band (w*h*2 bytes)
	strb.w	r0, [sp, #0x5b]
	ldrb.w	r0, [sp, #0x5b]
	cbz	r0, .L0803d49e
	b.n	.L0803d47c
.L0803d47c:
	ldr	r0, [sp, #0x5c]
	bl	file_close
	ldr	r0, [sp, #0x5c]
	bl	free_units_of_32_bytes
	movw	r0, #0x8350
	movt	r0, #0x2000
	ldr	r0, [r0, #0x8]
	bl	free_units_of_32_bytes
	movs	r0, #0x1	@ band write failed
	strb.w	r0, [sp, #0x67]
	b.n	.L0803d5cc
.L0803d49e:
	movw	r0, #0x8350
	movt	r0, #0x2000
	ldr	r0, [r0, #0x8]
	bl	free_units_of_32_bytes	@ free the band buffer
	b.n	.L0803d4ae
@ ---- band 3: rectangle (0,0xdd,0x140,0x13) ----
.L0803d4ae:
	movw	r4, #0x8350
	movt	r4, #0x2000
	movs	r0, #0x0
	strh	r0, [r4, #0x0]	@ x = 0
	movs	r0, #0xdd
	strh	r0, [r4, #0x2]	@ y = 0xdd
	mov.w	r0, #0x140
	strh	r0, [r4, #0x4]	@ w = 0x140
	movs	r0, #0x13
	strh	r0, [r4, #0x6]	@ h = 0x13
	ldrh	r0, [r4, #0x4]
	ldrh	r1, [r4, #0x6]
	muls	r0, r1
	lsls	r0, r0, #0x1	@ w*h*2 bytes
	bl	alloc_units_of_32_bytes
	str	r0, [r4, #0x8]
	ldr	r0, [r4, #0x8]
	cmp	r0, #0x0
	beq.n	.L0803d5b8	@ allocation failed: skip band
	b.n	.L0803d4de
.L0803d4de:
	movs	r0, #0x4
	bl	jump_indirect_through_table
	movs	r0, #0x0
	strh.w	r0, [sp, #0x4]	@ i = 0
	b.n	.L0803d4ec
.L0803d4ec:
	ldrh.w	r0, [sp, #0x4]	@ i
	movw	r1, #0x8350
	movt	r1, #0x2000
	ldrh	r2, [r1, #0x4]
	ldrh	r1, [r1, #0x6]
	muls	r1, r2
	cmp	r0, r1
	bge.n	.L0803d560	@ i >= w*h: band converted
	b.n	.L0803d504
.L0803d504:
	movw	r0, #0x8350
	movt	r0, #0x2000
	ldr	r1, [r0, #0x8]
	ldrh.w	r2, [sp, #0x4]
	ldrh.w	r1, [r1, r2, lsl #0x1]
	and	r1, r1, #0x1f	@ low 5 bits kept
	strh.w	r1, [sp, #0x6]
	ldr	r1, [r0, #0x8]
	ldrh.w	r2, [sp, #0x4]
	ldrh.w	r3, [r1, r2, lsl #0x1]
	lsrs	r3, r3, #0x6
	strh.w	r3, [r1, r2, lsl #0x1]	@ v >> 6
	ldr	r1, [r0, #0x8]
	ldrh.w	r2, [sp, #0x4]
	ldrh.w	r3, [r1, r2, lsl #0x1]
	lsls	r3, r3, #0x5
	strh.w	r3, [r1, r2, lsl #0x1]	@ << 5
	ldrh.w	r1, [sp, #0x6]
	ldr	r0, [r0, #0x8]
	ldrh.w	r2, [sp, #0x4]
	ldrh.w	r3, [r0, r2, lsl #0x1]
	orrs	r1, r3	@ | low 5 bits
	strh.w	r1, [r0, r2, lsl #0x1]
	b.n	.L0803d554
.L0803d554:
	ldrh.w	r0, [sp, #0x4]
	adds	r0, #0x1
	strh.w	r0, [sp, #0x4]
	b.n	.L0803d4ec
.L0803d560:
	ldr	r0, [sp, #0x5c]
	movw	r2, #0x8350
	movt	r2, #0x2000
	ldr	r1, [r2, #0x8]
	ldrh	r3, [r2, #0x4]
	ldrh	r2, [r2, #0x6]
	muls	r2, r3
	lsls	r2, r2, #0x1
	add	r3, sp, #0x10
	bl	file_write	@ write the band (w*h*2 bytes)
	strb.w	r0, [sp, #0x5b]
	ldrb.w	r0, [sp, #0x5b]
	cbz	r0, .L0803d5a8
	b.n	.L0803d586
.L0803d586:
	ldr	r0, [sp, #0x5c]
	bl	file_close
	ldr	r0, [sp, #0x5c]
	bl	free_units_of_32_bytes
	movw	r0, #0x8350
	movt	r0, #0x2000
	ldr	r0, [r0, #0x8]
	bl	free_units_of_32_bytes
	movs	r0, #0x1	@ band write failed
	strb.w	r0, [sp, #0x67]
	b.n	.L0803d5cc
.L0803d5a8:
	movw	r0, #0x8350
	movt	r0, #0x2000
	ldr	r0, [r0, #0x8]
	bl	free_units_of_32_bytes	@ free the band buffer
	b.n	.L0803d5b8
.L0803d5b8:
	ldr	r0, [sp, #0x5c]
	bl	file_close
	ldr	r0, [sp, #0x5c]
	bl	free_units_of_32_bytes
	movs	r0, #0x0	@ success
	strb.w	r0, [sp, #0x67]
	b.n	.L0803d5cc
.L0803d5cc:
	ldrb.w	r0, [sp, #0x67]
	add	sp, #0x68
	pop	{r4, pc}
