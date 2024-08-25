; this is unused function, but will be used in the future

%include "shared/disk_geometry.asm"

read_data:
	xor ax, ax
	mov si, ax
	mov [SectorsRead], ax

	.read_loop:
		; check if all required sectors have been read
		mov ax, [SectorsRead] 
		mov bx, [TotalSectorCountToBeRead]
		cmp ax, bx
		jae .return

		; check if kernel sector if higher than drive's SPT
		; if it is, we need to recalculate CHS
		mov al, [SectorToRead]
		mov ah, [SectorsPerTrack]
		cmp al, ah
		jbe .continue

		; so we need to recalculate CHS, let's start with oneing sector
		mov al, 0x01
		mov [SectorToRead], al

		; now increment heads and check if kernel head doesn't overflow drive's heads amount
		mov al, [HeadToRead]
		inc al
		mov [HeadToRead], al
		mov ah, [Heads]
		cmp al, ah
		jb .continue

		; if we're here, cylinders also doesn't match and heads need to be zeroed
		xor al, al
		mov [HeadToRead], al

		; and let's adjust cylinders
		mov al, [CylinderToRead]
		inc al
		mov [CylinderToRead], al
		mov ah, [Cylinders]
		cmp al, ah
		jae .error ; we cannot read more cylinders than the drive has

		.continue:
			; read sector
			call read_sector
			jc .error

			; increment kernel sector
			mov cl, [SectorToRead]
			add cl, al
			mov [SectorToRead], cl

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
	mov dh, [HeadToRead] 		; head
	mov ch, [CylinderToRead] 	; cylinder
	mov cl, [SectorToRead] 	; sector
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
		mov dl, [Drive] 			; drive numer
		clc 						; clear carry flag
		int 0x13 					; call bios
		ret


SectorsRead		equ Drive + 0x1

DestSegment					equ SectorsRead + 0x2
DestOffset					equ DestSegment + 0x2
CylinderToRead				equ DestOffset + 0x2
HeadToRead					equ CylinderToRead + 0x1
SectorToRead				equ HeadToRead + 0x1
TotalSectorCountToBeRead	equ SectorToRead + 0x1