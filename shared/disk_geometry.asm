read_disk_geometry:
	; backup drive number
	mov [Drive], dl

	; call bios
	xor bx, bx
	mov es, bx
	mov ah, 0x8
	int 0x13
	jc error

	; increment heads (bios returns last index instead of amount)
	inc dh
	mov [Heads], dh

	; decode cylinders number (value is split between ch and last two bits of cl register)
	inc ch
	mov [Cylinders], ch

	; decode spt number (value is first 6 bits of cl register)
	and cl, 0x3f
	mov [SectorsPerTrack], cl

	ret

Cylinders		equ 0x500
Heads			equ Cylinders + 0x1
SectorsPerTrack	equ Heads + 0x1
Drive			equ SectorsPerTrack + 0x1
