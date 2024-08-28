all: bootloader/boot.bin vbr/vbr.bin

%.bin: %.asm
	nasm -f bin -o $@ $^

clean:
	find . -name '*.bin' -delete
	find . -name '*.img' -delete
