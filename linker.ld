OUTPUT_FORMAT("binary")
ENTRY(kernel_start)

SECTIONS
{
    /* Der Kernel wird bei Offset 0 innerhalb des Segments 0x1000 ausgeführt */
    . = 0x0000;

    .text : {
        /* 1. Der Assembler-Bootstrap-Code MUSS ganz nach vorne */
        build/kernel_asm.o(.text)
        /* 2. Der C-Code folgt direkt dahinter */
        *(.text)
    }

    /* Alle Daten- und Zeichenketten-Segmente direkt anhängen */
    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}
