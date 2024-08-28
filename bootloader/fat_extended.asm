%include "shared/fat.asm"

; some extra fat functions will be added in the future

; ax -> cluster number
; edi -> destination address
; fs -> fat segment
read_file_high:
	; save es segment register
	push es
	; set destination to 0x3000:0x0
	mov bx, 0x3000
	mov es, bx
	xor ebx, ebx
	call read_cluster

	; set size of cluster, sectorsPerCluster * size of sector
	xor eax, eax
	mov al, [fs:SectorsPerCluster]
	xor edx, edx
	mov edx, 512
	mul edx

	; copy read cluster to [edi] (edi will be automatically incremented)
	push ecx
	push ds
	mov eax, ecx
	xor eax, eax
	call copy_higher
	pop ds
	pop ecx

	; restore segment register
	pop es

	; check if cluster is bad, last or unused
	cmp cx, 0x0
	je error
	cmp cx, 0xff7
	je error
	cmp cx, 0xff8
	jb read_file_high

	ret

; es:ebx -> source
; edi -> destination
; ecx -> n of bytes
; eax -> must be zero
copy_higher:
	; set destination segment to 0x0
	xor edx, edx
	mov ds, dx

	; copy byte from es:ebx to ds:edi
	push eax
	mov al, [es:ebx]
	mov [ds:edi], al
	pop eax

	; increment counter and pointers
	inc eax
	inc edi
	inc ebx

	; check if we copied enough bytes
	cmp eax, ecx
	jb copy_higher

	ret