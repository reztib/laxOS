; Bootloader laxOS
org 0x7c00  ;MBR
bits 16 ;16 bit real mode

Start:
    ; set video mode for clearing version information from the starting screen
    mov ax, 0x0
    int 0x10

    mov al, 0x03
    int 0x10

    ; display letter
    mov ah, 0x0E
    mov al, 'L'
    int 0x10

    mov ah, 0x0E
    mov al, 'A'
    int 0x10

    mov ah, 0x0E
    mov al, 'C'
    int 0x10

    mov ah, 0x0E
    mov al, 'H'
    int 0x10

    mov ah, 0x0E
    mov al, 'S'
    int 0x10

hang:
    jmp hang
    

; nothing after this gets run in the binary!
times 510 - ($-$$) db 0
dw 0xAA55