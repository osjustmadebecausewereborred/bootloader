# osjustmadebecausewereborred's bootloader
Simple bootloader (now only bootsector, but please wait). Main purpose are floppy disks.

## Special features
Contains read-only FAT12 driver, which can load real-mode kernel or second stage bootloader, but there are few bad things:
- Size of BPB and FAT tables (combined) should not be more than 27KB, because BPB and FAT table is loaded to `0x0:0x1000`.
- More than 64KB cannot be loaded in one time by using `read_file` function from `shared/fat.asm`, but it should be enough for second stage bootloader.
- Please do not load anything to `0x0:0xffff` or lower, it can break the loaded data or bootsector. It stores some necessary data used to interpret filesystem and access disks, so do not touch it. Go for `0x1000:0x0` at least, but remember that it is real mode, so total RAM amount is 640KB.
- Does not support partitions (maybe in the future, but unfortunatelly it is very close to 510 bytes limit).
- File must be in the root directory of FAT12 filesystem. If it is missing, bootsector will go into endless loop.
- Filename is statically placed in the bootsector, modify bytes from 498 to 509 to set up custom filename or just modify `vbr/vbr.asm` and recompile bootsector.

## FAT12 driver
If you want to use this FAT12 driver in your second stage bootloader or bootsector, read license, take `shared/fat.asm` and go working, but do not forget; you should add some honorable mentions.

## Wanna know how FAT12 works?
If you want to know how data is stored on FAT12 filesystem, check `parsefat.c`. It is a simple C program which reads FAT12 disk image, searches for specified file and displays content of each cluster assigned to this file.

## Your lack of rights
Bootloader is licensed under BSD3 license.