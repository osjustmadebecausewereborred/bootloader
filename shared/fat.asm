%include "shared/disk_geometry.asm"

FATHeader				equ 0x1000
StartInstructions		equ FATHeader ;times 3 db 0x0
OEMIdentifier 			equ StartInstructions + 0x3 ;dq 0x0
BytesPerSector 			equ OEMIdentifier + 0x8 ;dw 0x0
SectorsPerCluster		equ BytesPerSector + 0x2 ;db 0x0
NOfReservedSectors		equ SectorsPerCluster + 0x1 ;dw 0x0
NOfFATs					equ NOfReservedSectors + 0x2 ;db 0x0
NOfRootDirEntries		equ NOfFATs + 0x1 ;dw 0x0
TotalSectorCount		equ NOfRootDirEntries + 0x2 ;dw 0x0
MediaDescriptorType		equ TotalSectorCount + 0x2 ;db 0x0
NOfSectorsPerFAT		equ MediaDescriptorType + 0x1 ;dw 0x0
NOfSectorsPerTrack		equ NOfSectorsPerFAT + 0x2 ;dw 0x0
NOfHeads				equ NOfSectorsPerTrack + 0x2 ;dw 0x0
NOfHiddenSectors		equ NOfHeads + 0x2 ;dd 0x0
LargeSectorCount		equ NOfHiddenSectors + 0x4 ;dd 0x0

DriveNumber			equ LargeSectorCount + 0x4 ;db 0x0
FlagsNTOrReserved	equ DriveNumber + 0x1;db 0x0
Signature			equ FlagsNTOrReserved + 0x1 ;db 0x0
VolumeSerialNumber	equ Signature + 0x1 ;dd 0x0
VolumeLabelString	equ VolumeSerialNumber + 0x4 ;times 11 db 0x0
SystemIdentifier	equ VolumeLabelString + 0xa;times 8 db 0x0

%define FirstFATSector		bp + 10
%define FirstRootDirSector	bp + 12
%define FirstDataSector		bp + 14

load_fat:
	call read_disk_geometry

	; read bpb
	; sector number 1 = lba 0
	xor bx, bx
	mov es, bx
	mov bx, FATHeader
	mov dx, 0x0
	mov al, 0x1
	call read_sectors

	; get offset of FAT table
	; fat offset = n of reserved sectors
	mov cx, [fs:NOfReservedSectors]
	mov [FirstFATSector], cx

	; get offset of root directory
	; root dir offset = fat offset + (n of sectors per fat table * n of fat tables)
	mov ax, [fs:NOfSectorsPerFAT]
	xor dx, dx
	mov dl, [fs:NOfFATs]
	; n of sectors * n of fats
	mul dx
	; += fat offset (is already stored in cx)
	add ax, cx
	mov [FirstRootDirSector], ax

	; get offset of first data sector
	; first data sector = root dir offset + (n of root dir entries * 32 / sector size (assuming it's 512 bytes))
	mov di, ax ; backup first root dir sector offset
	mov ax, [fs:NOfRootDirEntries]
	mov cx, 32
	; n of root dir entries * 32
	mul cx
	mov cx, 512
	; /= 512
	div cx
	; += first root dir sector offset
	add ax, di
	mov [FirstDataSector], ax

	; read all sectors required to interpret filesystem (bpb, fat table and root directory entries)
	xor bx, bx
	mov es, bx
	mov bx, FATHeader
	mov dx, 0x0
	call read_sectors

	ret

; ds:si -> filename
; ax <- first cluster number
find_file:
	; get offset to first root directory entry
	mov ax, [FirstRootDirSector]
	mov cx, 512
	mul cx

	; set up es:di as address to first root directory entry (clear segment, mov fat header address to di and add offset from ax)
	mov bx, fs
	mov es, bx
	mov di, FATHeader
	add di, ax

	; make a copies of di and si, because repe cmpsb will increment those pointers
	mov bx, si
	mov dx, di
	.loop:
		; set string length to 11 (max length of filename)
		mov cx, 11
		; clear direction flag
		cld

		; compare strings and if they are equal, jump to .ret
		repe cmpsb
		jz .ret

		; add 32 to directory entry pointer and restore it to di register
		add dx, 32
		mov di, dx
		; restore filename's pointer to si
		mov si, bx

		; check if pointer overflows bootsector
		cmp di, 0x7c00
		jae error

		; again do the same, until we find matching filename
		jmp .loop
	.ret:
		; get offset to cluster number, di has been already incremented by 11 with repe cmpsb, so we need to add 15 to it (offset of cluster number is 26)
		add di, 15
		; store cluster number in ax by dereferencing es:di and return function
		mov ax, [fs:di]
		ret

; ax -> cluster number
; es:bx -> dst
; fs -> fat header segment
; cx <- next cluster
read_cluster:
	push ax
	
	; physicall cluster = logical - 2
	sub ax, 2
	xor cx, cx
	; multiplicate by n of sectors per cluster
	mov cl, [fs:SectorsPerCluster]
	mul cx
	; add offset to first data sector
	mov cx, [FirstDataSector]
	add ax, cx

	; read cluster from disk
	mov dx, ax
	mov al, [fs:SectorsPerCluster]
	call read_sectors

	; get offset to first fat table sector and multiply it by 512 (sector size)
	mov ax, [FirstFATSector]
	mov cx, 512
	mul cx
	
	; set up fs:si as a pointer to new cluster value (add offset to fat header memory address)
	mov si, FATHeader
	add si, ax

	; multiply cluster number by 1.5 (16 * 1.5 = 12)
	xor dx, dx
	pop ax
	push ax
	mov cx, 0x2
	div cx
	pop dx
	add ax, dx
	; and add it to si to make it offset to new cluster value
	add si, ax

	; get cluster value
	mov cx, [fs:si]
	
	; check if this is even cluster
	test dx, 0x1
	jz .even
	; if it is, shift 4 lower bits
	shr cx, 0x4
	jmp .odd

	.even:
	; if not, zero 4 higher bits
	and cx, 0xfff
	
	.odd:
	; now we have 12bit value

	ret

; ax -> first cluster number
; fs -> fat header segment
; es:bx -> dst
read_file:
	call read_cluster

	; check if cluster is usuned
	cmp cx, 0x0
	je error
	; check if cluster is bad
	cmp cx, 0xff7
	je error

	; add memory offset
	; memory += sectors per cluster * sector size (assuming it's 512 bytes)
	xor ax, ax
	mov al, [fs:SectorsPerCluster]
	mov dx, 512
	; sectors per cluster * sector size
	mul dx
	; += memory
	add bx, ax

	; check if this is the last cluster of the file
	mov ax, cx
	cmp ax, 0xff8
	jb read_file ; if not, read next cluster

	ret

; es:bx -> dst
; al -> n of sectors
; dx -> lba
read_sectors:
	; same number of sectors to be read
	push ax
	; convert lba to chs
	call lba_to_chs
	; restore amount of sectors to be read
	pop ax
	; get disk number
	mov dl, [fs:Drive]
	; sectors is a 6 bit value so we need to cut off first 2 bits
	and cl, 0x3f
	; ah=0x2 is bios read with chs addressing
	mov ah, 0x2
	; call bios
	int 0x13
	jc error
	ret
	.al equ 0x8200

; dx -> lba
; fs -> fat header segment
lba_to_chs:
	; save lba
	push dx

	; C, temp = lba / (heads * spt)
	xor dx, dx
	xor cx, cx
	mov al, [Heads]
	mov cl, [SectorsPerTrack]
	mul cx ; heads * spt
	mov cx, ax
	xor dx, dx
	pop ax
	div cx ; lba / (heads * spt)
	push ax

	; H, S - 1 = temp / spt
	mov ax, dx
	xor dx, dx
	xor cx, cx
	mov cl, [SectorsPerTrack]
	div cx

	pop cx
	mov ch, cl
	mov cl, dl
	inc cl ; S = S - 1 + 1
	mov dh, al

	ret
