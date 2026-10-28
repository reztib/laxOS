#include <stdint.h>

// 1. Einzelner IDT-Eintrag (Gate Descriptor) - 8 Bytes groß
struct idt_entry_struct {
    uint16_t base_low;  // Niedrigstes 16-Bit der Adresse der ISR
    uint16_t sel;       // Kernel-Segment-Selector
    uint8_t  always0;   // Muss immer 0 sein
    uint8_t  flags;     // Typ und Attribute des Gates
    uint16_t base_high; // Höchstes 16-Bit der Adresse der ISR
} __attribute__((packed)); // __attribute__((packed)) verhindert, dass der Compiler Padding-Bytes einfügt

// 2. IDT-Pointer -> wird von assembler-Befehl 'lidt' verwendet - 6 Bytes groß
struct idt_ptr_struct {
    uint16_t limit; // Größe der IDT in Bytes minus 1
    uint32_t base;  // Die absolute Adresse des ersten IDT-Eintrags im RAM
} __attribute__((packed));

// 3. Array von 256 IDT-Einträgen (für alle möglichen Interrupts)
struct idt_entry_struct idt_table[256];
struct idt_ptr_struct   idt_ptr;