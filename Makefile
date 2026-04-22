# target (output file): prerequisites (input file(s))
# 						 recipe (what to do)

# make takes the first argument from the top, which in this case is build

# creating build/ folder (if it does not already exist), assembling the bootloader
build/boot.bin : boot/boot.asm
	mkdir -p build; \
	nasm -f bin boot/boot.asm -o build/boot.bin;

# separation of building and running for structural purposes and control
# running the bootloader in qemu
run : build/boot.bin
	qemu-system-x86_64 -drive format=raw,file=build/boot.bin

.PHONY : clean
clean :
	rm -rf build