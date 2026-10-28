# target (output file): prerequisites (input file(s))
# 						 recipe (what to do)

all: build/laxOS.img

# creating build/ folder (if it does not already exist), assembling the bootloader
build/boot.bin : boot/boot.asm
	mkdir -p build; \
	nasm -f bin boot/boot.asm -o build/boot.bin;

# assembling the kernel entry bootstrap into an object file
build/kernel_asm.o : boot/kernel.asm
	mkdir -p build; \
	nasm -f elf32 boot/kernel.asm -o build/kernel_asm.o;

# compiling the C kernel into an object file (Native 32-bit, no 16-bit hacks)
build/kernel_c.o : kernel/kernel.c
	mkdir -p build; \
	gcc -m32 -ffreestanding -fno-pie -nostdlib -c kernel/kernel.c -o build/kernel_c.o;

# linking using your linker.ld script (ensuring explicit order)
build/kernel.bin : build/kernel_asm.o build/kernel_c.o linker.ld
	ld -m elf_i386 -T linker.ld -o build/kernel.bin build/kernel_asm.o build/kernel_c.o;

# combining bootloader and kernel into a raw 1.44MB floppy image
build/laxOS.img : build/boot.bin build/kernel.bin
	dd if=/dev/zero of=build/laxOS.img bs=1024 count=1440; \
	dd if=build/boot.bin of=build/laxOS.img conv=notrunc bs=512 count=1; \
	dd if=build/kernel.bin of=build/laxOS.img conv=notrunc bs=512 seek=1;

# running the combined OS image in qemu as a floppy disk
run : build/laxOS.img
	qemu-system-x86_64 -fda build/laxOS.img

.PHONY : clean
clean :
	rm -rf build
