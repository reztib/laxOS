; Bootloader laxOS
org 0x7c00
bits 16 ;16 bit real mode

Start:
    mov ah, 0x0E
    mov al, 'L'
    int 0x10

hang:
    jmp hang
    

; nothing after this gets run in the binary!
times 510 - ($-$$) db 0
dw 0xAA55