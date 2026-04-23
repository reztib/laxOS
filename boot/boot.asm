; Bootloader laxOS
org 0x7c00
bits 16

Start:
    ; -------------------------
    ; Segmentregister setzen
    ; -------------------------
    xor ax, ax
    mov ds, ax

    ; -------------------------
    ; Video Mode 80x25 text
    ; -------------------------
    mov ax, 0x0003
    int 0x10

    ; -------------------------
    ; Cursor Position berechnen
    ; -------------------------
    mov si, msg
    call get_length      ; CX = Länge

    mov ax, 80
    sub ax, cx
    shr ax, 1            ; (80 - len) / 2

    mov dh, 0            ; Zeile 0
    mov dl, al           ; Spalte
    mov bh, 0

    mov ah, 0x02
    int 0x10

    ; -------------------------
    ; String ausgeben
    ; -------------------------
    mov si, msg
    call print_str

    jmp hang

; ==================================================
; get_length: CX = Länge des Strings
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
; print_str: gibt String aus (BIOS teletype)
; Input: SI = String
; ==================================================
print_str:
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
; Daten
; -------------------------
msg db "Willkommen zu laxOS v0.0.1!", 0

; -------------------------
; Hang
; -------------------------
hang:
    jmp hang

; Boot Signature
times 510 - ($ - $$) db 0
dw 0xAA55