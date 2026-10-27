; =============================================================================
; laxOS Kernel - Hauptprogramm
; =============================================================================
; Dieser Kernel wird vom Bootloader ab der Speicheradresse 0x1000:0000 ausgeführt.
; =============================================================================

bits 16                             ; Wir befinden uns immer noch im 16-Bit Real Mode
org 0x0000                          ; Offset ist 0, da wir über das Segment (0x1000) anspringen

kernel_start:
    ; -------------------------------------------------------------------------
    ; TODO: 1. REGISTER INITIALISIEREN
    ; -------------------------------------------------------------------------
    ; Da wir per Far-Jump (0x1000:0000) hierher gesprungen sind, steht CS auf 0x1000.
    ; Setze die restlichen Segmentregister (DS, ES) ebenfalls auf diesen Wert,
    ; damit deine Daten-Labels korrekt adressiert werden.
    ;
    ; Vergiss nicht, auch einen eigenen Stack (SS, SP) für den Kernel zu definieren,
    ; damit er sicher läuft und keine anderen Speicherbereiche überschreibt.


    ; -------------------------------------------------------------------------
    ; TODO: 2. KERNEL-BEGRÜSSUNG AUSGEBEN
    ; -------------------------------------------------------------------------
    ; Lösche den Bildschirm oder setze eine neue Zeile an, um zu signalisieren,
    ; dass der Kernel erfolgreich geladen wurde und die Kontrolle übernommen hat.
    ; Nutze dafür wieder den vertrauten BIOS Video-Interrupt 'int 0x10'.


    ; -------------------------------------------------------------------------
    ; TODO: 3. ERWEITERTE FUNKTIONEN IMPLEMENTIEREN
    ; -------------------------------------------------------------------------
    ; Hier sind deiner Kreativität keine Grenzen gesetzt:
    ; - Eigene Befehlszeile (Shell / CLI) für Befehle bauen
    ; - Hardware-Informationen über das BIOS auslesen
    ; - In den 32-Bit Protected Mode wechseln (GDT aufsetzen)
    ; - Einen eigenen Tastaturtreiber schreiben


; -------------------------------------------------------------------------
; DATENBEREICH DES KERNELS
; -------------------------------------------------------------------------
; Hier kannst du deine kernel-spezifischen Zeichenketten und Variablen definieren.
