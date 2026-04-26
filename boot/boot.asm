; Bootloader laxOS
org 0x7c00
bits 16     ; 16 bit real mode

Start:
    ; -------------------------
    ; set segmentation registers
    ; -------------------------
    xor ax, ax
    mov ds, ax

    ; -------------------------
    ; video mode 80x25 text
    ; -------------------------
    mov ax, 0x0003
    int 0x10

    ; -------------------------
    ; calculate cursor position in relation to msg length
    ; -------------------------
    mov si, greetingMsg
    call get_length      ; CX = Länge

    mov ax, 80
    sub ax, cx
    shr ax, 1            ; (80 - len) / 2

    mov dh, 0            ; row 0
    mov dl, al           ; column
    mov bh, 0

    mov ah, 0x02
    int 0x10

    ; -------------------------
    ; print string
    ; -------------------------
    mov si, greetingMsg
    call print_startupMessages

    mov si, questionMsg
    call get_length

    mov ax, 80
    sub ax, cx
    shr ax, 1

    mov dh, 2
    mov dl, al
    mov bh, 0

    mov ah, 0x02
    int 0x10

    mov si, questionMsg
    call print_startupMessages

    ; set cursor position
    mov dh, 8
    mov dl, 8
    mov ah, 0x02
    int 0x10

    mov si, menuSelection_1
    call print_menu


    mov dh, 10
    mov dl, 8
    mov ah, 0x02
    int 0x10
    
    mov si, menuSelection_2
    call print_menu

    jmp hang

; ==================================================
; get_length: CX = string length
; Input:  SI = String
; Output: CX = length
; ==================================================
get_length:
    xor cx, cx

    .len_loop:
        mov al, [si]
        cmp al, 0
        je .done

        inc cx
        inc si
        jmp .len_loop

    .done:
        ret

; ==================================================
; print_startupMessages: prints startup messages (duh) (BIOS teletype)
; Input: SI = String
; ==================================================
print_startupMessages:
    .print_loop:
        mov al, [si]

        cmp al, 0
        je .done

        mov ah, 0x0E
        int 0x10

        inc si
        jmp .print_loop

    .done:
        ret


print_menu:
    .print_loop:
        mov al, [si]
        cmp al, 0
        je .done

        mov ah, 0x0E
        int 0x10

        inc si
        jmp .print_loop

    .done:
        ret

; -------------------------
; start up messages
; -------------------------
greetingMsg db "Willkommen zu laxOS v0.0.1!", 13, 10, 0

questionMsg db "Was willst du tun?", 13, 10, 0

; -------------------------
; menu
; -------------------------
menuSelection_1 db "laxOS starten", 13, 10, 0
menuSelection_2 db "Shutdown", 13, 10, 0

        

; -------------------------
; Hang
; -------------------------
hang:
    jmp hang

; boot signature
times 510 - ($ - $$) db 0
dw 0xAA55