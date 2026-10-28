#include "idt.h"

struct idt_entry_struct idt_table[256];
struct idt_ptr_struct   idt_ptr;

extern void keyboard_handler_asm(void);

/* 
   CLI-Zustandsvariablen 
*/
char cli_buffer[256]; 
int cli_buffer_index = 0;
int command_ready = 0; 

/*
   VGA-Textmodus-Koordinaten (X auf 7 wegen Eingabe-Prompt "laxOS> ")
*/
int cursor_x = 7;   // Spalte (0-79)
int cursor_y = 0;   // Zeile (0-24)

/*
    Vollständige Funktionsprototypen (Forward Declarations)
*/
// Screen & Text I/O
void clear_screen(void);
void kprint(const char* str, unsigned int line);
void putchar(char c);
void print(const char* str);
void update_hardware_cursor(int x, int y);

// Hardware I/O Ports
static inline void outb(unsigned short port, unsigned char value);
static inline unsigned char inb(unsigned short port);

// Interrupt Handling (IDT & PIC)
void idt_set_gate(uint8_t num, uint32_t base, uint16_t sel, uint8_t flags);
void init_idt(void);
void pic_remap(void);

// Tastatur & CLI
void keyboard_handler_c(void);
int laxOS_strcmp(const char *a, const char *b);
void execute_command(const char *cmd);

typedef unsigned char  uint8_t;   // Exakt 1 Byte (0-255)
typedef unsigned short uint16_t;  // Exakt 2 Bytes
typedef unsigned int   uint32_t;  // Exakt 4 Bytes

// =============================================================================
// SCREEN & TEXT I/O IMPLEMENTIERUNG
// =============================================================================
void clear_screen() {
    char* video_memory = (char*) 0xB8000;
    
    // Kompletten Bildschirm mit Leerzeichen füllen
    for (int i = 0; i < 80 * 25 * 2; i += 2) {
        video_memory[i]     = ' ';   
        video_memory[i + 1] = 0x07;  
    }
    
    cursor_x = 7; // Setze den Cursor auf die X-Position nach dem Prompt
    cursor_y = 0;
    
    // Hardware-Cursor nach oben links zwingen
    update_hardware_cursor(cursor_x, cursor_y);
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

void putchar (char c) {
    /*/
    int cursor_x = 0;   // Spalte (0-79)
    int cursor_y = 0;   // Zeile (0-24)
    
    VGA_Index = (cursor_y * 80 + cursor_x) * 2
    */ 

    /*
        1. Zeichen an berechnete VGA_Index schreiben
        2. cursor_x um 1 erhöhen: der Cursor wandert nach rechts
        3. Zeilenumbruch: wenn cursor_x >= 80 -> cursor_x = 7 (Eingabeprompt("laxOS> ")), cursor_y + 1
        4. Sonderzeichen: Wenn das Zeichen ein \n ist, cursor_x = 7, cursor_y + 1 OHNE Zeichen zu drucken
        5. Scrolling prüfen: Wenn cursor_y >= 25 erreicht (Bildschirm voll),
        alle Zeilen im Speicher um eine Zeile nach oben kopieren und die unterste Zeile leeren.
        cursor_y = 24
    */
    char* video_memory = (char*) 0xB8000;

    // 1. Zeichen an berechnete Stelle (VGA_Index) schreiben
    int VGA_Index = (cursor_y * 80 + cursor_x) * 2;
    video_memory[VGA_Index] = c; 
    video_memory[VGA_Index + 1] = 0x0A; // Hellgrün auf Schwarz

    // 2. cursor_x um 1 erhöhen
    cursor_x++;

    // 3. Zeilenumbruch prüfen
    if (c == '\n') {
        cursor_x = 7; // Setze den Cursor auf die Spalte nach dem Prompt "laxOS> "
        cursor_y++;
        kprint("laxOS> ", cursor_y); // Prompt auf der neuen Zeile ausgeben
    }
    // Rechter Bildschirmrand erreicht, Zeilenumbruch erzwingen
    else if (cursor_x >= 80) {
        cursor_x = 7;
        cursor_y++;
    }

    // TODO: 5. Scrolling prüfen

    update_hardware_cursor(cursor_x, cursor_y);
}

void update_hardware_cursor(int x, int y) {
    // Berechne lineare Position auf dem Bildschirm
    uint16_t pos = y * 80 + x;

    // Cursor Location High Register (0x0E)
    outb(0x3D4, 0x0E);
    // oberen acht Bits an DS (0x3D5) senden
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));

    // Cursor Location Low Register (0x0F)
    outb(0x3D4, 0x0F);
    // unteren acht Bits an DS (0x3D5) senden
    outb(0x3D5, (uint8_t)(pos & 0xFF));
}

// =============================================================================
// HARDWARE I/O PORTS
// =============================================================================
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

// =============================================================================
// INTERRUPT HANDLING (IDT & PIC
// =============================================================================
// IDT (Interrupt Descriptor Table)
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

// PIC (Programmable Interrupt Controller) Remapping
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

// =============================================================================
// TASTATUR & CLI IMPLEMENTIERUNG
// =============================================================================
// Scancode -> ASCII
// Index des Arrays entspricht dem Scancode
// Gibt an, ob Shift (links oder rechts) aktuell gedrückt gehalten wird
int shift_pressed = 0;

// Ebene 1: Normal (Kleinschreibung) - Bereits auf deutsches QWERTZ angepasst (Z und Y getauscht)
const char kbd_de_main[128] = {
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 0xE1, '`', '\b',  // 0xE1 = ß
  '\t', 'q', 'w', 'e', 'r', 't', 'z', 'u', 'i', 'o', 'p', 0x81, '+', '\n',      // 0x81 = ü
    0,  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 0x94, 0x84, '^',   0,      // 0x94 = ö, 0x84 = ä
  '#', 'y', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '-',   0, '*',   0, ' '
};

// Ebene 2: Shift gedrückt (Großschreibung & obere Sonderzeichen)
const char kbd_de_shift[128] = {
    0,  27, '!', '"', 0,   '$', '%', '&', '/', '(', ')', '=', '?', '`', '\b',
  '\t', 'Q', 'W', 'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P', 0x9A, '*', '\n',      // 0x9A = Ü
    0,  'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 0x99, 0x8E, 0xF8, 0,       // 0x99 = Ö, 0x8E = Ä, 0xF8 = °
  '\'', 'Y', 'X', 'C', 'V', 'B', 'N', 'M', ';', ':', '_',   0, '*',   0, ' '
};

__attribute__((force_align_arg_pointer)) void keyboard_handler_c(void) {
    uint8_t scancode = inb(0x60);
    outb(0x20, 0x20); // EOI an den PIC senden

    // 1. SHIFT-TASTEN ABFANGEN (Sowohl Drücken als auch Loslassen)
    if (scancode == 0x2A || scancode == 0x36) {
        shift_pressed = 1; // Eine der Shift-Tasten wird gehalten
        return;
    }
    if (scancode == 0xAA || scancode == 0xB6) {
        shift_pressed = 0; // Shift wurde wieder losgelassen
        return;
    }

    // 2. Reguläres Loslassen anderer Tasten ignorieren
    if (scancode & 0x80) {
        return;
    }

    // 3. Dynamische Tabellen-Auswahl basierend auf dem Shift-Zustand
    char ascii;
    if (shift_pressed) {
        ascii = kbd_de_shift[scancode];
    } else {
        ascii = kbd_de_main[scancode];
    }

    if (ascii == 0) return; // Nicht druckbares Zeichen, ignorieren

    // 4. Zeichenverarbeitung für den CLI-Puffer
    if (ascii == '\n') {
        cli_buffer[cli_buffer_index] = '\0'; 
        command_ready = 1; 
        putchar('\n'); 
    }
    else if (ascii == '\b') {
        if (cli_buffer_index > 0) {
            cli_buffer_index--;      
            if (cursor_x > 0) {
                cursor_x--;          
                int index = (cursor_y * 80 + cursor_x) * 2;
                char* video_memory = (char*) 0xB8000;
                video_memory[index] = ' '; 
                update_hardware_cursor(cursor_x, cursor_y);
            }
        }
    }
    else {
        if (cli_buffer_index < 255) {
            cli_buffer[cli_buffer_index++] = ascii; 
            putchar(ascii); 
        }
    }
}

int laxOS_strcmp(const char *a, const char *b)
{
    while (*a && *a == *b) { ++a; ++b; }
    return (int)(unsigned char)(*a) - (int)(unsigned char)(*b);
}

void print(const char* str) {
    int i = 0;
    while (str[i] != '\0') {
        putchar(str[i]);
        i++;
    }
}

void execute_command(const char *cmd) {
    if (laxOS_strcmp(cmd, "hilfe") == 0) {
        print("Befehls\x81""bersicht:\n");
        print("hilfe - Diese Nachricht\n");
        print("clear - Bildschirm l\x94""schen\n");
        // HINWEIS: Das letzte \n hier triggert automatisch das neue "laxOS> " über putchar!
    } 
    else if (laxOS_strcmp(cmd, "clear") == 0) {
        clear_screen();
        // Da clear_screen alles löscht und x=7, y=0 setzt, schreiben wir das Prompt direkt in Zeile 0
        kprint("laxOS> ", 0); 
    } 
    else if (laxOS_strcmp(cmd, "") == 0) {
        // Wenn nur ENTER gedrückt wurde, simulieren wir einfach einen leeren Zeilenumbruch,
        // welcher über putchar('\n') ein neues Prompt in der nächsten Zeile erzeugt.
        putchar('\n');
    } 
    else {
        print("Unbekannter Befehl (Tipp: 'hilfe').\n");
    }
}

// =============================================================================
// KERNEL ENTRY POINT
// =============================================================================
void kernel_main(void) {
    clear_screen();
    
    init_idt();   // 1. IDT laden
    pic_remap();  // 2. PIC umprogrammieren
    asm volatile("sti"); // 3. Interrupts in der CPU global aktivieren (STI-Befehl)
    
    kprint("laxOS> ", 0); // Prompt ausgeben

    while(1) {
        if (command_ready == 1) {
            execute_command(cli_buffer); // Befehl auswerten

            cli_buffer_index = 0; // Puffer zurücksetzen
            command_ready = 0;    // Flag zurücksetzen

            //kprint("laxOS> ", 0); // Prompt erneut ausgeben
        }
    }
}