bits 16
org 0x7c00

jmp short 0x3c
nop

OEMIdentifier 		dq 0x0
BytesPerSector 		dw 0x0
SectorsPerCluster	db 0x0
NOfReservedSectors	dw 0x0
NOfFATs				db 0x0
NOfRootDirEntries	dw 0x0
TotalSectorCount	dw 0x0
MediaDescriptorType	db 0x0
NOfSectorsPerFAT	dw 0x0
NOfSectorsPerTrack	dw 0x0
NOfHeads			dw 0x0
NOfHiddenSectors	dd 0x0
LargeSectorCount	dd 0x0

DriveNumber			db 0x0
FlagsNTOrReserved	db 0x0
Signature			db 0x0
VolumeSerialNumber	dd 0x0
VolumeLabelString	times 11 db 0x0
SystemIdentifier	times 8 db 0x0

_start:
	; clear registers
	xor ax, ax
	mov ds, ax
	cld

	; print message
	mov si, loading_msg
	call print

	; load kernel
	call read_kernel
	jc .error

	; print message
	mov si, booting_msg
	call print

	jmp 0x7e00

	.error: ; if we are here, an error has occured
		mov si, error_msg
		call print
		jmp halt

halt: 	hlt
		jmp halt

print:
	mov ah, 0xE
	.print_loop:
		lodsb
		or al, al
		jz .ret
		int 0x10
		jmp .print_loop
	.ret:
		ret

read_kernel:
	; set up destination memory address
	mov ax, 0x0
	mov [DestSegment], ax
	mov ax, 0x7e00
	mov [DestOffset], ax

	call read_disk_geometry ; read disk geometry
	jc .return

	xor si, si ; clear index register
	.read_loop:
		; check if all required sectors have been read
		mov ax, [SectorsRead] 
		mov bx, [kernel_nsectors]
		cmp ax, bx
		jae .return

		; check if kernel sector if higher than drive's SPT
		; if it is, we need to recalculate CHS
		mov al, [kernel_sector]
		mov ah, [SectorsPerTrack]
		cmp al, ah
		jbe .continue

		; so we need to recalculate CHS, let's start with oneing sector
		mov al, 0x01
		mov [kernel_sector], al

		; now increment heads and check if kernel head doesn't overflow drive's heads amount
		mov al, [kernel_head]
		inc al
		mov [kernel_head], al
		mov ah, [Heads]
		cmp al, ah
		jb .continue

		; if we're here, cylinders also doesn't match and heads need to be zeroed
		xor al, al
		mov [kernel_head], al

		; and let's adjust cylinders
		mov al, [kernel_cylinder]
		inc al
		mov [kernel_cylinder], al
		mov ah, [Cylinders]
		cmp al, ah
		jae .error ; we cannot read more cylinders than the drive has

		.continue:
			; read sector
			call read_sector
			jc .error

			; increment kernel sector
			mov cl, [kernel_sector]
			add cl, al
			mov [kernel_sector], cl

			; increment number of read sectors and memory index
			xor ah, ah
			mov cx, [SectorsRead]
			add cx, ax
			mov [SectorsRead], cx
			mov cx, 512 ; sector size
			mul cx
			add si, ax

			jmp .read_loop

	.error:
		stc
	.return:
		ret

read_sector:
	mov dl, [Drive] 			; drive numer
	mov dh, [kernel_head] 		; head
	mov ch, [kernel_cylinder] 	; cylinder
	mov cl, [kernel_sector] 	; sector
	and cl, 0x3f 				; cut last two bits of sector
								; (last to bits are part of cylinder value)

	; set up memory destination address
	mov es, [DestSegment]
	mov bx, [DestOffset]
	add bx, si
	
	; we must be sure that bx doesn't overflow memory segment
	cmp bx, 0
	ja .finish

	; if it does, use next memory segment and zero offset and index
	xor bx, bx
	mov si, bx
	mov [DestOffset], bx
	add bx, 0x1000
	mov es, bx
	mov [DestSegment], es

	.finish:
		mov ah, 0x02 				; ah=0x2 -> read disk
		mov al, 0x01				; sectors count
		clc 						; clear carry flag
		int 0x13 					; call bios
		ret

read_disk_geometry:
	; backup drive number
	mov [Drive], dl

	; call bios
	xor bx, bx
	mov es, bx
	mov ah, 0x8
	clc
	int 0x13
	jc .error

	; ah contains error code, 0x0 means success
	cmp ah, 0x0
	jne .error

	; increment heads (bios returns last index instead of amount)
	inc dh
	mov [Heads], dh

	; decode cylinders number (value is split between ch and last two bits of cl register)
	inc ch
	mov [Cylinders], ch

	; decode spt number (value is first 6 bits of cl register)
	and cl, 0x3f
	mov [SectorsPerTrack], cl

	; print nice message on success
	mov si, geometry_msg
	call print

	clc
	ret

	.error:
		stc
		ret

loading_msg	db "Loading kernel...", 0xD, 0xA, 0x0
booting_msg	db "Booting kernel...", 0xD, 0xA, 0x0
error_msg	db "Error. Sorry, cannot continue.", 0xD, 0xA, 0x0
geometry_msg db "Disk geometry read.", 0xD, 0xA, 0x0

Cylinders 		equ 0x500
Heads			equ Cylinders + 0x1
SectorsPerTrack equ Heads + 0x1
Drive			equ SectorsPerTrack + 0x1
SectorsRead		equ Drive + 0x1
DestSegment		equ SectorsRead + 0x2
DestOffset		equ DestSegment + 0x2

times 504 - ($ - $$) db 0x0

; to be filled with kernel's physicall address on the disk
kernel_cylinder		db 0x0
kernel_head			db 0x0
kernel_sector		db 0x0
kernel_nsectors		dw 0x0
kernel_offset		db 0x0

dw 0xaa55

; times 1474560 - ($ - $$) db 0x0