all: vbr.bin

%.bin: %.asm
	nasm -f bin -o $@ $^

clean:
	rm -rf *.bin

qemu: vbr.bin
	qemu-system-i386 -m 1M -smp 1 -cpu 486 -fda vbr.bin $(QEMU_FLAGS)