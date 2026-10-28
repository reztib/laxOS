#include "idt.h"

struct idt_entry_struct idt_table[256];
struct idt_ptr_struct   idt_ptr;

extern void keyboard_handler_asm(void);

typedef unsigned char  uint8_t;   // Exakt 1 Byte (0-255)
typedef unsigned short uint16_t;  // Exakt 2 Bytes
typedef unsigned int   uint32_t;  // Exakt 4 Bytes

void clear_screen() {
    // Zeiger auf den VGA-Textmodus-Speicher
    char* video_memory = (char*) 0xB8000;
    
    // 80 Spalten * 25 Zeilen = 2000 Zeichen. Jedes Zeichen braucht 2 Bytes.
    for (int i = 0; i < 80 * 25 * 2; i += 2) {
        video_memory[i]     = ' ';   // Zeichen auf Leerzeichen setzen
        video_memory[i + 1] = 0x07;  // Farbe: Hellgrauer Text auf schwarzem Grund
    }
}

void kprint(const char* str, unsigned int line) {
    volatile char* vga = (volatile char*)(0xB8000 + (line * 80 * 2));
    int i = 0;
    while (str[i] != '\0') {
        vga[i * 2] = str[i];
        vga[i * 2 + 1] = 0x0F; // Weiß auf Schwarz
        i++;
    }
}

// Sendet ein Byte an einen Hardware-Port
static inline void outb(unsigned short port, unsigned char value) {
    __asm__ __volatile__("outb %0, %1" : : "a"(value), "Nd"(port));
}

// Liest ein Byte von einem Hardware-Port
static inline unsigned char inb(unsigned short port) {
    unsigned char ret;
    __asm__ __volatile__("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

/* Ziel: Etablierung einer stabilen Ereignissteuerung durch die CPU.
       
   1.2 PIC (Programmable Interrupt Controller)
       - Remapping des Master- und Slave-PIC (IRQs 0-15 auf Interrupts 32-47).
       - Verhindert Konflikte mit den internen CPU-Exceptions.
       
   1.3 Hardware-Treiber (Tastatur & System-Timer)
       - IRQ 1 (Tastatur): Auslesen des Scancodes über I/O-Port 0x60.
       - Implementierung einer Lookup-Tabelle zur Übersetzung in ASCII.
       - IRQ 0 (PIT): System-Timer für deterministische Zeitintervalle.
*/
// 1.1 IDT (Interrupt Descriptor Table)
void idt_set_gate(uint8_t num, uint32_t base, uint16_t sel, uint8_t flags) {
    // Adresse in die obere und untere Hälfte zerteilen
    idt_table[num].base_low  = (base & 0xFFFF);
    idt_table[num].base_high = (base >> 16) & 0xFFFF;

    idt_table[num].sel       = sel;
    idt_table[num].always0   = 0;
    
    // 0x8E ist der Standard-Wert für ein 32-Bit Interrupt Gate:
    // Es bedeutet: Present=1, Ring=0 (Kernel-Modus), Typ=32-bit Interrupt
    idt_table[num].flags     = flags; 
}

void init_idt(void) {
    idt_ptr.limit = (sizeof(struct idt_entry_struct) * 256) - 1;
    idt_ptr.base  = (uint32_t)&idt_table;

    for (int i = 0; i < 256; i++) {
        idt_set_gate(i, 0, 0, 0);
    }

    // TASTATUR REGISTRIEREN: Platz 33, Adresse des Wrappers, Code-Selektor 0x08, Flags 0x8E
    idt_set_gate(33, (uint32_t)keyboard_handler_asm, 0x08, 0x8E);

    asm volatile("lidt %0" : : "m"(idt_ptr));
}

// 1.2 PIC (Programmable Interrupt Controller) Remapping
void pic_remap(void) {
    // ICW1: Initialisierung starten
    outb(0x20, 0x11);
    outb(0xA0, 0x11);

    // ICW2: Master-PIC auf Platz 32 (0x20) und Slave-PIC auf Platz 40 (0x28) schieben
    outb(0x21, 0x20);
    outb(0xA1, 0x28);

    // ICW3: Dem Master sagen, dass der Slave an IRQ 2 hängt
    outb(0x21, 0x04);
    outb(0xA1, 0x02);

    // ICW4: 8086-Modus aktivieren
    outb(0x21, 0x01);
    outb(0xA1, 0x01);

    // Alle Hardware-Interrupts aktivieren (Masken löschen)
    outb(0x21, 0xFD);
    outb(0xA1, 0xFF);
}

__attribute__((force_align_arg_pointer)) void keyboard_handler_c(void) {
    uint8_t scancode = inb(0x60);
    outb(0x20, 0x20);

    char* video_memory = (char*) 0xB8000;
    video_memory[0] = 'L';
    video_memory[1] = 0x0A; 
}


/*
   MEILENSTEIN 2: IMPLEMENTIERUNG DES COMMAND LINE INTERFACES (CLI)
   -----------------------------------------------------------------------------
   Ziel: Interaktive Zeichenverarbeitung und Befehlsauswertung.
   
   2.1 Eingabepuffer und Zeilen-Management
       - Globaler Puffer zur sequentiellen Speicherung von ASCII-Zeichen.
       - Visuelles Feedback (Echo) auf dem Bildschirm bei Tastendruck.
       - Handhabung von Steuerzeichen (Backspace, Enter).
       
   2.2 String-Verarbeitung (Freestanding Hilfsfunktionen)
       - Implementierung von Kernfunktionen: 'strcmp', 'strlen', 'strtok'.
       
   2.3 Befehls-Interpreter (Parser)
       - Evaluierung des Puffers nach dem Empfang eines Line-Feeds (Enter).
       - Tokenisierung des Eingabestrings in Befehl und Argumente.
       - Ausführung assoziierter Subroutinen (z. B. 'help', 'clear', 'reboot').
*/

/*
   MEILENSTEIN 3: ARCHITEKTUR FÜR SYSTEMAUFRUFE UND SPEICHERVERWALTUNG
   -----------------------------------------------------------------------------
   Ziel: Bereitstellung der Infrastruktur für eine Standard-C-Bibliothek.
   
   3.1 Physische und Virtuelle Speicherverwaltung
       - Memory Mapping zur Erfassung des verfügbaren RAM.
       - Page- oder Bitmap-Allocator zur Zuweisung physischer Pages.
       - Kernel-Heap zur dynamischen internen Speicherallokation.
       
   3.2 Systemaufruf-Schnittstelle (Syscall-Interface)
       - Definition eines Software-Interrupts (z. B. 'int 0x80') als Gateway.
       - Mapping von Registern auf Kernel-Funktionen zur Zustandstransmission.
       
   3.3 POSIX-Substrat für die C-Bibliothek (libc-Backend)
       - Implementierung der minimalen POSIX-Schnittstellen:
         * 'sys_brk' / 'sbrk' (Grundlage für 'malloc' und 'free')
         * 'write' (Kanalisierung von 'stdout' in den VGA-Treiber)
         * 'read' (Kanalisierung von 'stdin' aus dem Tastaturbuffer)
       - Einbindung einer schlanken, plattformunabhängigen libc (z. B. Newlib).
============================================================================= */

void kernel_main(void) {
    clear_screen();
    
    init_idt();   // 1. IDT laden
    pic_remap();  // 2. PIC umprogrammieren
    
    // 3. Interrupts in der CPU global aktivieren (STI-Befehl)
    asm volatile("sti");

    // Endlosschleife, damit der Kernel nicht aufhört zu laufen
    while(1) {
        // Hier wartet der Kernel stur, während die Tastatur asynchron dazwischenfunkt!
    }
}