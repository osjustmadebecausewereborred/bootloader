# osjustmadebecausewereborred's bootloader
Simple bootloader. Main purpose are floppy disks.

## Special features
Contains read-only FAT12 driver, but there are few bad things:
- Size of BPB and FAT tables (combined) should not be more than 27KB, because BPB and FAT table is loaded to `0x0:0x1000`.
- Do not load anything to an address lower than `0x20000 + size of configuration file`. It is reserved area for bootloader.
- For now does not support partitions.

## Setup
1. Install NASM and run `make`.
2. Write bootsector to the FAT12 formatted (floppy) disk. You can use dd:
```bash
dd if=vbr/vbr.bin of=/dev/fd0 skip=62c seek=62c bs=1c count=450 conv=notrunc
```
3. Put `bootloader/boot.bin` and kernel into the root directory.
4. Create `btconfig.cfg` file there and write configuration.  Here are commands used to generate proper configuration file:
```bash
# Placing destination address needs to be done in little endian. For example 0x00030000 will be 0x00, 0x00, 0x00, 0x30 and combined "\x00\x00\x00\0x30".
printf "F<FAT12 filename><address in format described above>\x0a" >> btconfig.cfg
# If you need, you can of course load more files than 1. Use the same method.
printf "J<11 spaces><address in the same format>\x0a" >> btconfig.cfg
printf "\x00" >> btconfig.cfg
```

## FAT12 driver
If you want to use this FAT12 driver in your second stage bootloader or bootsector, read license, take `shared/fat.asm` and go working, but do not forget; you should add some honorable mentions.

## Wanna know how FAT12 works?
If you want to know how data is stored on FAT12 filesystem, check `parsefat.c`. It is a simple C program which reads FAT12 disk image, searches for specified file and displays content of each cluster assigned to this file.

## Your lack of rights
Bootloader is licensed under BSD3 license.