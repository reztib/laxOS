# target (output file): prerequisites (input file(s))
# 						 recipe (what to do)

# assembling the bootloader
build/boot.bin: boot/boot.asm
	nasm -f bin boot/boot.asm -o build/boot.bin

run: build/boot.bin
	qemu-system-x86_64 -drive format=raw,file=build/boot.bin

.PHONY : clean
clean:
	rm -rf build/boot.bin