bits 16

MemSegment equ 0x1000

org 0x0

_start:
	; clear segment registers
	mov ax, MemSegment
	mov es, ax
	mov ds, ax
	mov fs, ax
	mov gs, ax
	
	; set up stack (0x0:0x9000)
	xor ax, ax
	mov ss, ax
	mov sp, 0x9000
	mov bp, sp

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