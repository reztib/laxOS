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

void kernel_main(void) {
    clear_screen();
    kprint("laxOS Kernel erfolgreich im 32-Bit Protected Mode gestartet!", 3);
    kprint("C-Infrastruktur steht. Bereit für CLI-Implementierung.", 4);

    while(1) {
        __asm__ __volatile__("hlt");
    }
}
