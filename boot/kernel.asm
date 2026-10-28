; =============================================================================
; laxOS Kernel - Hauptprogramm & Loader
; =============================================================================

section .text       ; Definiert die Code-Sektion für das ELF32-Format

[bits 16]           ; Erzwingt 16-Bit-Codegenerierung in der ELF-Sektion

global kernel_start ; Macht den Einstiegspunkt für den Linker sichtbar
extern kernel_main  ; Deklariert die externe C-Funktion

kernel_start:
    ; -------------------------------------------------------------------------
    ; 1. Register- und Stack-Initialisierung
    ; -------------------------------------------------------------------------
    mov ax, cs      ; Kopiert den aktuellen Segmentwert (0x1000) nach AX
    mov ds, ax      ; Setzt das Datensegment (DS) auf 0x1000
    mov es, ax      ; Setzt das Extrasegment (ES) auf 0x1000
    mov ss, ax      ; Setzt das Stack-Segment (SS) auf 0x1000
    mov sp, 0xFFFF  ; Setzt den Stack-Pointer auf das Maximum des Segments

    ; -------------------------------------------------------------------------
    ; 2. Assembler-Seitiger Bildschirm-Reset und Begrüßung
    ; -------------------------------------------------------------------------
    call clear_screen

    mov si, kernel_msg
    call print_messageOnScreen

    ; -------------------------------------------------------------------------
    ; 3. Übergabe an das C-Hauptprogramm (TODO 3)
    ; -------------------------------------------------------------------------
    call kernel_main

kernel_hang:
    hlt             ; Sicherheitsnetz, falls der C-Kernel jemals beendet wird
    jmp kernel_hang

; ==============================================================================
; Hilfsfunktionen (Garantieren die korrekte Stack-Struktur im Speicher)
; ==============================================================================
print_messageOnScreen:
    mov al, [si]
    cmp al, 0
    je .done

    mov ah, 0x0E
    int 0x10
    inc si
    jmp print_messageOnScreen
.done:
    ret

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07      ; Hintergrundfarbe: Schwarz, Vordergrundfarbe: Weiß
    mov cx, 0         ; Startzeile (0)
    mov dx, 0x184F    ; Endzeile (24), Endspalte (79)
    int 0x10

    ; Cursor auf 0,0 setzen
    mov dx, 0x0000
    mov bh, 0x00
    mov ah, 0x02
    int 0x10
    ret

; -------------------------------------------------------------------------
; Datenbereich des Loaders
; -------------------------------------------------------------------------
kernel_msg db "laxOS Kernel erfolgreich geladen. Starte C-Subsystem...", 13, 10, 0

; Sektoren-Padding bleibt hier, damit die Datei groß genug für das BIOS ist
times 2560 - ($ - $$) db 0
