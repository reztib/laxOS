; Bootloader laxOS
org 0x7c00  ;MBR
bits 16 ;16 bit real mode

Start:
    ; set video mode for clearing version information from the starting screen
    ; 80x25 resolution and color
    mov ax, 0x0
    mov al, 0x03
    int 0x10

    mov si, msg
    call printStr
    jmp hang

printStr:
    mov ah, 0x0E
    mov al, [si]
    psloop:
        int 0x10
        inc si
        mov al, [si]
        cmp al, 0
        jne psloop
    ret

msg db "LACHS", 13, 10, 0 ; carriage return, line feed, null terminator


hang:
    jmp hang
    

; nothing after this gets run in the binary!
times 510 - ($-$$) db 0
dw 0xAA55