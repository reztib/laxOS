org 0x7c00
bits 16     ; 16 bit real mode

Start:
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
    ; =================================================
    ; Lade den Kernel in den Speicher
    ; =================================================
    mov ax, 0x1000          ; Segmentadresse für den Kernel
    mov es, ax              ; Setze ES auf das Kernel-Segment, ES = 0x1000
    xor bx, bx              ; BX = 0, RAM-Adresse 0x1000:0000

    ; =================================================
    ; BIOS int 0x13 - Lese Sektoren von der Festplatte
    ; =================================================
    mov ah, 0x02           ; Funktion: Sektoren lesen
    mov al, 5              ; Anzahl der zu lesenden Sektoren (ca. 2,5 KB)
    mov ch, 0              ; Zylinder 0
    mov cl, 2              ; Start-Sektor (Sektor 1 der Bootsektor ist)
    mov dh, 0              ; Head 0
    ; Register DL enthält beim Booten automatisch die ID des aktuellen Boot-Laufwerks.
    ; Da wir DL nicht verändert haben, liest das BIOS vom selben Laufwerk, von dem wir gebootet haben.

    ; =================================================
    ; BIOS Aufruf ausführen und Fehler prüfen
    ; =================================================
    int 0x13
    jc disk_error          ; Wenn Carry-Flag gesetzt ist, gab es einen Fehler

    ; =================================================
    ; Far Jump zum Kernel
    ; =================================================
    jmp 0x1000:0000         ; Sringe zum geladenen Kernel-Code. Goodbye BIOS, hello Kernel!

disk_error:
    ; =================================================
    ; Fehlerbehandlung: Disk-Fehler
    ; =================================================
    mov si, diskErrorMsg
    call print_messageOnScreen

    mov ah, 0x86
    mov cx, 0x004C
    mov dx, 0x4B40
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
