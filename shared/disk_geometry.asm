Drive					equ 0x7f00

%define Cylinders		bp + 4
%define Heads			bp + 6
%define SectorsPerTrack	bp + 8

read_disk_geometry:
	; backup drive number
	mov [fs:Drive], dl

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
