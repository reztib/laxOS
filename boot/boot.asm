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
    mov si, msg
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
    mov si, msg
    call print_startupMessage

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
; print_startupMessage: prints startup message (duh) (BIOS teletype)
; Input: SI = String
; ==================================================
print_startupMessage:
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
; start up message
; -------------------------
msg db "Willkommen zu laxOS v0.0.1!", 0

; -------------------------
; Hang
; -------------------------
hang:
    jmp hang

; boot signature
times 510 - ($ - $$) db 0
dw 0xAA55