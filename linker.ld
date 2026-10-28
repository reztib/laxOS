OUTPUT_FORMAT("binary")
ENTRY(kernel_start)

SECTIONS
{
    /* Der Kernel startet absolut bei Adresse 0x9000 */
    . = 0x9000;

    .text : {
        *kernel_asm.o(.text)
        *(.text)
        *(.text*)
    }

    .rodata : {
        *(.rodata)
        *(.rodata*)
    }

    .data : {
        *(.data)
        *(.data*)
    }

    .bss : {
        *(.bss)
        *(COMMON)
    }
}
