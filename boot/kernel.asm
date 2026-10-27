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
    ; TODO: 2. Bildschirm-Reset und Begrüßung
    ; -------------------------------------------------------------------------
    ; - Videospeicher bereinigen (Bildschirm leeren) via int 0x10
    ; - Ausgabe der Kernel-Willkommensnachricht zur Bestätigung der Ausführung
    

    ; -------------------------------------------------------------------------
    ; TODO: 3. Kernfunktionen und Systemarchitektur
    ; -------------------------------------------------------------------------
    ; - Implementierung der grundlegenden Befehlseingabe (CLI-Schnittstelle)
    ; - Abfrage systemrelevanter Hardware-Informationen über BIOS-Interrupts
    ; - Vorbereitung und Wechsel in den 32-Bit Protected Mode (GDT-Aufbau)
    ; - Entwicklung eines hardwarenahen Tastaturtreibers


kernel_hang:
    hlt
    jmp kernel_hang

; -------------------------------------------------------------------------
; Datenbereich
; -------------------------------------------------------------------------
kernel_msg db "laxOS Kernel erfolgreich geladen.", 13, 10, 0
