; you exactly know what this does
print:
	mov ah, 0xE
	.loop:
		lodsb
		or al, al
		je .ret
		int 0x10
		jmp .loop
	.ret:
		ret