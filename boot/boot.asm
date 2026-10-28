org 0x7c00
bits 16     ; 16 bit real mode

Start:
    ; -------------------------
    ; Boot-Laufwerk sichern
    ; -------------------------
    mov [boot_drive], dl

    ; -------------------------
    ; Setze Segmentregister
    ; -------------------------
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; -------------------------
    ; video mode 80x25 text
    ; -------------------------
    mov ax, 0x0003
    int 0x10

    ; -------------------------
    ; Berechne Cursor-Position für die Begrüßungsnachricht
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
    ; String ausgeben
    ; -------------------------
    mov si, greetingMsg
    call print_messageOnScreen

    mov si, questionMsg
    call get_length

    mov ax, 80
    sub ax, cx
    shr ax, 1 ; /2

    mov dh, 6
    mov dl, al
    mov ah, 0x02
    int 0x10

    mov si, questionMsg
    call print_messageOnScreen

    ; set cursor position
    mov bh, 0
    mov dh, 8
    mov dl, 8
    mov ah, 0x02
    int 0x10

    mov si, menuSelection_1
    call print_menu

    mov bh, 0
    mov dh, 9
    mov dl, 8
    mov ah, 0x02
    int 0x10

    mov si, menuSelection_2
    call print_menu

; ==================================================
; INTERAKTIVE MENÜ-SCHLEIFE
; ==================================================
menu_loop:
    call draw_pointer       ; Zeichne den Auswahlpfeil

    ; Auf Tastendruck warten (BIOS-Interrupt 0x16, AH=00h)
    mov ah, 0x00
    int 0x16                ; AH = Scancode, AL = ASCII

    ; Überprüfe die Scancodes der Tasten
    cmp ah, 0x48            ; Pfeiltaste NACH OBEN
    je move_up
    cmp ah, 0x50            ; Pfeiltaste NACH UNTEN
    je move_down
    cmp ah, 0x1C            ; ENTER-Taste
    je execute_selection

    jmp menu_loop           ; Ignoriere andere Tasten

move_up:
    mov byte [current_selection], 0
    call clear_pointer_space ; Löscht alten Pfeil
    jmp menu_loop

move_down:
    mov byte [current_selection], 1
    call clear_pointer_space ; Löscht alten Pfeil
    jmp menu_loop

execute_selection:
    mov al, [current_selection]
    cmp al, 0
    je start_laxos          ; Option 0: laxOS starten
    cmp al, 1
    je shutdown_system      ; Option 1: Shutdown
    jmp menu_loop

; ==================================================
; Hilfsfunktionen für das Menü
; ==================================================
draw_pointer:
    mov dh, 8
    add dh, [current_selection]
    mov dl, 7               ; Spalte vor dem Text
    mov bh, 0
    mov ah, 0x02
    int 0x10                ; Cursor setzen

    mov al, '>'
    mov ah, 0x0E
    int 0x10
    ret

clear_pointer_space:
    mov bh, 0
    mov dl, 7

    ; Zeile 8 löschen
    mov dh, 8
    mov ah, 0x02
    int 0x10
    mov al, ' '
    mov ah, 0x0E
    int 0x10

    ; Zeile 9 löschen
    mov dh, 9
    mov ah, 0x02
    int 0x10
    mov al, ' '
    mov ah, 0x0E
    int 0x10
    ret

; ==================================================
; Aktionen der Menüeinträge
; ==================================================
start_laxos:
    cld
    ; Wir bleiben im flachen Segment 0x0000
    xor ax, ax              
    mov es, ax              ; ES = 0x0000
    mov bx, 0x9000          ; BX = 0x9000 -> Zieladresse im RAM ist exakt 0x0000:0x9000

    mov ah, 0x02            ; Sektoren lesen
    mov al, 20              ; Lese 20 Sektoren
    mov ch, 0               ; Cylinder 0
    mov cl, 2               ; Sektor 2 (Direkt nach dem Bootloader)
    mov dh, 0               ; Head 0
    mov dl, [boot_drive]    ; Originallaufwerk nutzen (wird von QEMU als 0x00 übergeben)
    int 0x13
    jc disk_error

    ; WICHTIG: Far Jump mit Segment 0x0000 und Offset 0x9000.
    ; Das matcht perfekt mit der ". = 0x9000;" Anweisung deines Linker-Skripts!
    jmp 0x0000:0x9000       



disk_error:
    ; =================================================
    ; Fehlerbehandlung: Disk-Fehler
    ; =================================================
    mov si, diskErrorMsg
    call print_messageOnScreen

    ; =================================================
    ; Sleep für fünf Millionen Mikrosekunden (what the fuck?) bevor das System heruntergefahren wird
    ; für andere Zeiten einfach gewünschten Wert in µs in https://www.rapidtables.com/convert/number/decimal-to-hex.html?x=5000000 eingeben,
    ; erste Hälfte in CX, zweite Hälfte in DX speichern
    ; =================================================
    mov ah, 0x86
    mov cx, 0x004C          
    mov dx, 0x4B40          ; 0x004C4B40 = 5.000.000 Mikrosekunden = 5 Sekunden
    int 0x15                ; BIOS Sleep für 5 Sekunden (5000 ms)

    jmp shutdown_system

shutdown_system:
    mov ax, 0x5301
    xor bx, bx
    int 0x15                ; APM Verbindung herstellen

    mov ax, 0x530e
    xor bx, bx
    mov cx, 0x0102
    int 0x15                ; APM Treiberversion aktivieren

    mov ax, 0x5307
    mov bx, 0x0001          ; Alle Geräte
    mov cx, 0x0003          ; Zustand: Off
    int 0x15                ; System ausschalten
    jmp hang

; ==================================================
; Vorhandene Hilfsfunktionen
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

print_messageOnScreen:
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
; Datenbereich (Variablen & Texte)
; -------------------------
boot_drive db 0
current_selection db 0

greetingMsg db "Willkommen zu laxOS v0.0.1!", 13, 10, 0
questionMsg db "Was willst du tun?", 13, 10, 0
diskErrorMsg db "Fehler: Konnte Kernel nicht laden.", 13, 10, 0

menuSelection_1 db "laxOS starten", 0
menuSelection_2 db "Shutdown", 0

; -------------------------
; Hang (Endlosschleife)
; -------------------------
hang:
    jmp hang

; Boot-Signatur füllen
times 510 - ($ - $$) db 0
dw 0xAA55
