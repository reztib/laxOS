section .text
[bits 16]

global kernel_start
extern kernel_main

kernel_start:
    cli                         ; Interrupts deaktivieren
    
    lgdt [gdt_descriptor]       ; GDT laden
    
    ; Protected Mode aktivieren
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; WICHTIG: 'dword' zwingt NASM, den Sprungbefehl so zu codieren,
    ; dass er aus dem 16-Bit-Modus heraus das 32-Bit-Ziel sauber anspringt!
    jmp 0x08:dword init_32bit

[bits 32]
init_32bit:
    ; Segmente auf den 32-Bit-Datenselektor (0x10) einstellen
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Stack sicher bei 0x80000 platzieren
    mov esp, 0x80000

    ; Ruft die C-Funktion direkt auf
    call kernel_main

.hang:
    hlt
    jmp .hang

; Macht den Wrapper für den C-Linker sichtbar
global keyboard_handler_asm
; Teilt NASM mit, dass diese Funktion in kernel.c existiert
extern keyboard_handler_c

[bits 32]
keyboard_handler_asm:
    pusha                    ; Sichert alle allgemeinen Register (EAX, ECX, etc.)
    push ds                  ; Sichert die Segmentregister
    push es
    push fs
    push gs

    mov ax, 0x10             ; Kernel-Datensegment laden
    mov ds, ax
    mov es, ax

    call keyboard_handler_c  ; Ruft die eigentliche C-Funktion auf

    pop gs                   ; Stellt die Segmentregister wieder her
    pop fs
    pop es
    pop ds
    popa                     ; Stellt die allgemeinen Register wieder her
    iret                     ; Interrupt Return (Zwingend erforderlich!)


; =============================================================================
; Global Descriptor Table (GDT)
; =============================================================================
align 4
gdt_start:
    dd 0x00000000, 0x00000000   ; Null-Deskriptor

gdt_code:
    dw 0xFFFF, 0x0000           ; Limit 0-15, Base 0-15
    db 0x00, 0x9A, 0xCF, 0x00   ; Base 16-23, Access, Flags+Limit, Base 24-31

gdt_data:
    dw 0xFFFF, 0x0000           ; Limit 0-15, Base 0-15
    db 0x00, 0x92, 0xCF, 0x00   ; Base 16-23, Access, Flags+Limit, Base 24-31
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1   ; GDT-Größe
    dd gdt_start                ; Absolute Adresse (berechnet ab 0x9000)

; Sektoren-Padding für das BIOS beibehalten
;times 2560 - ($ - $$) db 0
