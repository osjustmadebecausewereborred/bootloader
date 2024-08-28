; gs:di -> pointer to config
parse_config:
	; load first character
	xor ax, ax
	mov al, [gs:di]

	; F means file
	cmp al, 'F'
	jne .c1
	; read file with parameters from this config entry
	call config_file_read
	jmp .finish

	.c1:
	; J means jump
	cmp al, 'J'
	jne .c2
	; prepare a jump and jump to address given in config entry
	jmp config_jump

	.c2:
	; zero is just end of config, system will halt after that
	cmp al, 0x0
	jne .c3
	ret

	.c3:
	; if invalid argument is passed, print an error and halt system
	mov si, invalidconfig_msg
	call print
	jmp error

	.finish:
	; if entry was parsed (except jump), we're here. So let's just increment pointer to make it pointing to next config entry
	add di, 17

	; parse next config entry
	jmp parse_config

; gs:di -> pointer to config entry
config_file_read:
	; save pointer to config entry
	push di

	; print a nice message
	mov si, reading_msg
	call print

	; filename starts right after entry type, so pointer needs to be incremented
	inc di
	; again save pointer because find_file operates on di register
	push di
	; save segment registers
	push ds
	push es
	; set address to filename (from gs:di to es:si)
	mov si, gs
	mov ds, si
	mov si, di
	; find file (function will return cluster number)
	call find_file
	; restore segment registers
	pop es
	pop ds
	; restore entry pointer
	pop di

	; save es segment register, because it needs to be used with read_file
	push es
	; get destination memory address
	; first is segment, it is located just after filename (and it's length is 11 bytes)
	add di, 11
	push edi
	; read file
	mov edi, [gs:di]
	call read_file_high
	; restore segment register
	pop edi
	pop es

	; and restore pointer to config entry
	pop di
	ret

; TODO!!!
; gs:di -> pointer to configuration entry
config_jump:
	; print a message
	mov si, jumping_msg
	call print

	; get segment and offset of the address to be jumped to
	add di, 12
	mov edi, [gs:di]

	; clear segment registers
	xor ax, ax
	mov es, ax
	mov ds, ax
	mov ss, ax
	mov sp, ax
	mov gs, ax
	mov fs, ax

	; JUMP
	jmp [ds:edi]

reading_msg				db "Reading file...", 0xA, 0xD, 0x0
jumping_msg				db "Jumping...", 0xA, 0xD, 0x0
invalidconfig_msg		db "Invalid configuration!", 0xA, 0xD, 0x0
