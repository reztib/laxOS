; =============================================================================
; laxOS Kernel - Hauptprogramm
; =============================================================================

bits 16
org 0x0000

kernel_start:
    mov ax, cs      ; Kopiert den aktuellen Segmentwert (0x1000) nach AX
    mov ds, ax      ; Setzt das Datensegment (DS) auf das aktuelle Code-Segment (0x1000)
    mov es, ax      ; Setzt Extrasegment (ES) auf das aktuelle Code-Segment (0x1000)

    mov ss, ax      ; Setzt das Stack-Segment (SS) auf das aktuelle Code-Segment (0x1000)
    mov sp, 0xFFFF  ; Setzt den Stack-Pointer (SP) auf die oberste Adresse des Stacks (0xFFFF)


    ; -------------------------------------------------------------------------
    ; 2. Bildschirm-Reset und Begrüßung
    ; -------------------------------------------------------------------------
    ; 2a) - Videospeicher bereinigen (Bildschirm leeren) via int 0x10
    call clear_screen

    ; 2b) - Begrüßungsnachricht ausgeben
    mov si, kernel_msg
    call print_messageOnScreen

    ; -------------------------------------------------------------------------
    ; KERNEL-STOPP (Verhindert das Hineinlaufen in die Hilfsfunktionen)
    ; -------------------------------------------------------------------------
    jmp kernel_hang

    ; -------------------------------------------------------------------------
    ; @TODO: 3. Kernfunktionen und Systemarchitektur
    ; -------------------------------------------------------------------------
    ; - 3a) Implementierung der grundlegenden Befehlseingabe (CLI-Schnittstelle)
    

    ; - 3b) Abfrage systemrelevanter Hardware-Informationen über BIOS-Interrupts
    ; - 3c) Vorbereitung und Wechsel in den 32-Bit Protected Mode (GDT-Aufbau)
    ; - 3d) Entwicklung eines hardwarenahen Tastaturtreibers



; ==============================================================================
; Hilfsfunktionen
; ==============================================================================
print_messageOnScreen:
    ; Ausgabe der Nachricht auf dem Bildschirm
    mov al, [si]
    cmp al, 0
    je .done                ; GEÄNDERT: Springe zu .done statt direkt in den Hang

    mov ah, 0x0E
    int 0x10
    inc si
    jmp print_messageOnScreen

.done:
    ret                     ; NEU: Kehrt ordnungsgemäß zum Hauptprogramm zurück

kernel_hang:
    hlt
    jmp kernel_hang

sleep:
    ; ================================================= 
    ; Sleep für fünf Millionen Mikrosekunden (what the fuck?)
    ; =================================================
    mov ah, 0x86
    mov cx, 0x004C          
    mov dx, 0x4B40          ; 0x004C4B40 = 5.000.000 Mikrosekunden = 5 Sekunden
    int 0x15                ; BIOS Sleep für 5 Sekunden (5000 ms)
    ret

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07      ; Hintergrundfarbe: Schwarz, Vordergrundfarbe: Weiß
    mov cx, 0         ; Startzeile (0)
    mov dx, 0x184F    ; Endzeile (24), Endspalte (79)
    int 0x10          ; BIOS-Interrupt für Bildschirmoperationen

    ; Cursor auf 0,0 setzen
    mov dx, 0x0000
    mov bh, 0x00
    mov ah, 0x02
    int 0x10
    ret

; -------------------------------------------------------------------------
; Datenbereich
; -------------------------------------------------------------------------
kernel_msg db "laxOS Kernel erfolgreich geladen.", 13, 10, 0

times 2560 - ($ - $$) db 0
