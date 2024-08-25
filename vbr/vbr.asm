bits 16
org 0x7c00

jmp short 0x3c
nop

; fat header
; FATHeader:
; 	.OEMIdentifier 			times 8 db 0x0
; 	.BytesPerSector 		dw 0x0
; 	.SectorsPerCluster		db 0x0
; 	.NOfReservedSectors		dw 0x0
; 	.NOfFATs				db 0x0
; 	.NOfRootDirEntries		dw 0x0
; 	.TotalSectorCount		dw 0x0
; 	.MediaDescriptorType	db 0x0
; 	.NOfSectorsPerFAT		dw 0x0
; 	.NOfSectorsPerTrack		dw 0x0
; 	.NOfHeads				dw 0x0
; 	.NOfHiddenSectors		dd 0x0
; 	.LargeSectorCount		dd 0x0

; 	.DriveNumber		db 0x0
; 	.FlagsNTOrReserved	db 0x0
; 	.Signature			db 0x0
; 	.VolumeSerialNumber	dd 0x0
; 	.VolumeLabelString	times 11 db 0x0
; 	.SystemIdentifier	times 8 db 0x0

times 62 - ($ - $$) db 0x0

_start:
	; clear direction flag
	cld

	call load_fat

	xor si, si
	mov ds, si
	mov si, filename
	call find_file

	xor bx, bx
	mov es, bx
	mov bx, 0x9000
	call read_file

	jmp 0x9000

	jmp error

error:
	mov si, error_msg
	call print
halt:
	hlt
	jmp halt

%include "shared/print.asm"
%include "shared/fat.asm"

error_msg		db "Err", 0x0

times 498 - ($ - $$) db 0x0
filename		db "BOOT    BIN", 0x0

times 510 - ($ - $$) db 0x0
dw 0xaa55