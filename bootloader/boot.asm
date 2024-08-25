bits 16
org 0x9000

_start:
	; clear segment registers and set up stack
	xor ax, ax
	mov si, ax
	mov di, ax
	mov es, ax
	mov ds, ax
	mov ss, ax
	mov bp, 0x600
	mov sp, bp

	mov ax, 69

	; print message indicating that we have loaded ourselves
	mov si, stage2_msg
	call print

	jmp morethan1

	; read disk geometry
	; call read_disk_geometry
	; jc error

	jmp halt

error:
	mov si, error_msg
	call print
	jmp halt

%include "shared/print.asm"
; %include "shared/read.asm"

stage2_msg 			db "Now at first cluster", 0xD, 0xA, 0x0
error_msg			db "Error has occured, cannot continue. Sorry.", 0xD, 0xA, 0x0

times 512 			db 0x0
morethan1_msg		db "If this string is visible, it means it is in the 3rd cluster, BUT if it is printable, the currently running code is from 5th cluster", 0xD, 0xA, 0x0
times 512 			db 0x0

morethan1:
	mov si, morethan1_msg
	call print
	jmp halt

halt:
	hlt
	jmp halt