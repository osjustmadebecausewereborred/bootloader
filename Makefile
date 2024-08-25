all: bootloader/boot.bin vbr/vbr.bin

%.bin: %.asm
	nasm -f bin -o $@ $^

clean:
	find . -name '*.bin' -delete
	find . -name '*.img' -delete

FLOPPY_SECTOR_COUNT ?= 2880
qemu: all
	dd if=/dev/zero of=disk.img bs=512 count=$(FLOPPY_SECTOR_COUNT)
	mkfs.fat -F12 -n "BOOTL" disk.img
	mount -o loop disk.img /mnt
	cp bootloader/boot.bin /mnt
	umount /mnt
	dd if=vbr/vbr.bin of=disk.img skip=62c seek=62c bs=1c count=450 conv=notrunc
	# nasm -f bin -o qemu/config.bin qemu/config.asm
	# dd if=qemu/config.bin of=disk.img seek=504c bs=1c conv=notrunc
	qemu-system-i386 -m 1M -smp 1 -cpu 486 ${QEMU_FLAGS} -fda disk.img