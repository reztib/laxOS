; =============================================================================
; laxOS Kernel - Hauptprogramm
; =============================================================================

bits 16
org 0x0000

kernel_start:
    ; -------------------------------------------------------------------------
    ; TODO: 1. Register- und Stack-Initialisierung
    ; -------------------------------------------------------------------------
    ; - Segmentregister DS und ES an das aktuelle CS-Segment (0x1000) angleichen
    ; - Separaten Kernel-Stack über SS und SP definieren to verhindern von Overflows


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
