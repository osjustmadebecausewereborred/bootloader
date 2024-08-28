enable_unreal:
	mov si, unreal_msg
	call print

	push ds
	cli

	mov ax, 0x2401
	int 0x15
	jc error

	lgdt [es:gdtinfo]
	mov eax, cr0
	or al, 1
	mov cr0, eax

	mov bx, 0x08
	mov ds, bx

	and al, 0xfe
	mov cr0, eax
	jmp 0x1000:.unreal

	.unreal:
	pop ds

	mov si, unreal_enabled_msg
	call print

	; clear all registers except stack pointer, base pointer and segment registers
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	xor esi, esi
	xor edi, edi

	jmp 0x1000:unreal

unreal_msg			db "Enabling unreal mode...", 0xA, 0xD, 0x0
unreal_enabled_msg	db "Enabled unreal mode!", 0xA, 0xD, 0x0

gdtinfo:
   dw gdt_end - gdt - 1   ;last byte in table
   dd gdt                 ;start of table

gdt:        dd 0,0        ; entry 0 is always unused
flatcode    db 0xff, 0xff, 0, 0, 0, 10011010b, 10001111b, 0
flatdata    db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
gdt_end: