# target (output file): prerequisites (input file(s))
# 						 recipe (what to do)

# make takes the first argument from the top, which in this case is all
all: build/laxOS.img

# creating build/ folder (if it does not already exist), assembling the bootloader
build/boot.bin : boot/boot.asm
	mkdir -p build; \
	nasm -f bin boot/boot.asm -o build/boot.bin;

# assembling the kernel
build/kernel.bin : boot/kernel.asm
	mkdir -p build; \
	nasm -f bin boot/kernel.asm -o build/kernel.bin;

# combining bootloader and kernel into a raw 1.44MB floppy image
build/laxOS.img : build/boot.bin build/kernel.bin
	dd if=/dev/zero of=build/laxOS.img bs=1024 count=1440; \
	dd if=build/boot.bin of=build/laxOS.img conv=notrunc bs=512 count=1; \
	dd if=build/kernel.bin of=build/laxOS.img conv=notrunc bs=512 seek=1;

# separation of building and running for structural purposes and control
# running the combined OS image in qemu
run : build/laxOS.img
	qemu-system-x86_64 -drive format=raw,file=build/laxOS.img

.PHONY : clean
clean :
	rm -rf build
