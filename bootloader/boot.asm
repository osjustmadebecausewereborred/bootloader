org 0x0

_start:
	; set up segment registers
	mov ax, 0x1000
	mov es, ax
	mov ds, ax

	; set up stack (0x0:0x9000)
	xor ax, ax
	mov fs, ax
	mov ss, ax
	mov sp, 0x9000
	mov bp, ax

	; enable unreal mode
	jmp enable_unreal
unreal:

	; load fat table
	mov si, reading_fat_msg
	call print
	call load_fat

	; reading configuration file
	mov si, config_msg
	call print
	; save segment registers
	push es
	push ds
	mov si, config_filename
	call find_file
	; restore segment registers
	pop ds
	pop es
	; again save es segment, needs to be adjusted for read_file
	push es
	mov bx, 0x2000		; let's load config to 0x2000:0x0
	mov es, bx
	mov gs, bx			; gs will be used as segment to config file
	xor bx, bx
	call read_file
	; restore es segment
	pop es

	; nice message
	mov si, parsing_msg
	call print

	; gs contains segment of config file and the offset is 0x0
	mov di, 0x0
	call parse_config

	; if we're here, no jumps occured
parsedconfig:
; 	mov si, [MemSegment]
; 	mov ds, si
	mov si, parsed_msg
	call print

	jmp 0x1000:halt

error:
	; mov si, [MemSegment]
	; mov ds, si
	mov si, error_msg
	call print

halt:
	hlt
	jmp halt

%include "shared/print.asm"
%include "bootloader/unreal.asm"
%include "bootloader/fat_extended.asm"
%include "bootloader/parse_config.asm"

error_msg					db "An error has occured. Cannot continue :(", 0xA, 0xD, 0x0
reading_fat_msg 			db "Reading BPB, FAT tables and root directory entries...", 0xA, 0xD, 0x0
config_msg					db "Reading configuration file...", 0xA, 0xD, 0x0
parsing_msg					db "Parsing configuration file...", 0xA, 0xD, 0x0
parsed_msg					db "Config parsed. No jump entry. Halting system!", 0xA, 0xD, 0x0

config_filename				db "BTCONFIGCFG", 0x0