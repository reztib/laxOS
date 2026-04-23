; Bootloader laxOS
org 0x7c00  ; MBR
bits 16 ;16 bit real mode

Start:
    mov ax, 0x0000
    mov ds, ax

    ; set video mode for clearing version information from the starting screen
    ; 80x25 resolution and color
    mov ah, 0x0
    mov al, 0x03
    int 0x10

    mov ah, 0x2
    mov bh, 0
    mov dh, 0
    mov dl, 29
    int 0x10

    mov si, msg
    call printStr

    jmp hang

printStr:
    psloop:
        ; load letter into lower register
        mov al, [si]

        ; look if character is zero and return if that's the case
        cmp byte [si], 0
        je end

        ; display character, increment the character "position", start over
        mov ah, 0x0E
        int 0x10

        inc si

        jmp psloop
    
    end:
        ret

msg db "Willkommen zu laxOS!", 13, 10, 0 ; carriage return, line feed, null terminator

hang:
    jmp hang
    

; nothing after this gets run in the binary!
times 510 - ($-$$) db 0
dw 0xAA55