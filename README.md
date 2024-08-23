# osjustmadebecausewereborred's bootloader (maybe more like bootsector but idk)
Simple bootsector which can load "unlimited" (limited by 16-bit addressed memory, so up to 640KB of data) number of sectors from disk.
Main purpose are floppy disks or vintage legacy disks, where SPT is not more than 63 sectors (limited by `ah=0x2, int 0x13`, LBA not supported).

### Your lack of rights
Bootsector is licensed under BSD3 license.