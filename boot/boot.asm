; Bootloader laxOS
org 0x7c00

bits 16 ;16 bit real mode

Start:
    cli
    hlt
times 510 - ($-$$) db 0

dw 0xAA55