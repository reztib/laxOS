__asm__(".code16gcc\n");

void print_char(char c);
void print_string(const char* str);

void kernel_main(void) {
    /* Signalisiere die erfolgreiche Ausführung des C-Codes */
    print_string("C-Infrastruktur aktiv. Bereit fuer Befehle.\r\n");

    // -------------------------------------------------------------------------
    // TODO 3: AB HIER DEINE IMPLEMENTIERUNG IN C
    // -------------------------------------------------------------------------

    while(1) {
        // Hält die CPU stabil im Leerlauf, bis eine Taste gedrückt wird
        __asm__ __volatile__("hlt");
    }
}

void print_char(char c) {
    __asm__ __volatile__(
        "int $0x10"
        :
        : "a"((0x0E << 8) | (unsigned char)c), "b"(0x0007)
    );
}

void print_string(const char* str) {
    while (*str) {
        print_char(*str++);
    }
}
