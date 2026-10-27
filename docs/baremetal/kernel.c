/* ---------------------------------------------------------------------------
 * Bare-metal C kernel.
 *
 * It runs on top of the Multiboot bootstrap in start.asm.  There is no libc,
 * no operating system and no syscall interface: we talk to the (emulated)
 * hardware directly.  The only device we use is the PC serial port COM1
 * (0x3F8), because QEMU can redirect it to a file with "-serial file:...",
 * which lets a CI job capture and print the program's execution result.
 * ------------------------------------------------------------------------- */

#define COM1 0x3F8

static inline unsigned char inb(unsigned short port)
{
    unsigned char v;
    __asm__ volatile ("inb %1, %0" : "=a"(v) : "Nd"(port));
    return v;
}

static inline void outb(unsigned short port, unsigned char v)
{
    __asm__ volatile ("outb %0, %1" : : "a"(v), "Nd"(port));
}

/* Initialise the 16550 UART on COM1 as 38400 8N1, interrupts disabled. */
static void serial_init(void)
{
    outb(COM1 + 1, 0x00);   /* disable all interrupts            */
    outb(COM1 + 3, 0x80);   /* enable DLAB so we can set baud    */
    outb(COM1 + 0, 0x03);   /* divisor low  byte -> 38400 baud   */
    outb(COM1 + 1, 0x00);   /* divisor high byte                 */
    outb(COM1 + 3, 0x03);   /* 8 data bits, no parity, 1 stop    */
    outb(COM1 + 2, 0xC7);   /* enable FIFO, 14-byte threshold    */
    outb(COM1 + 4, 0x0B);   /* assert RTS/DSR, interrupts off    */
}

static void serial_putc(char c)
{
    while (!(inb(COM1 + 5) & 0x20))   /* wait for THR empty */
        ;
    outb(COM1, (unsigned char)c);
}

static void serial_puts(const char *s)
{
    for (; *s; ++s) {
        if (*s == '\n')
            serial_putc('\r');
        serial_putc(*s);
    }
}

/* Minimal unsigned decimal printer so the kernel can report a real result. */
static void serial_putdec(unsigned n)
{
    char buf[12];
    int i = 0;

    if (n == 0)
        buf[i++] = '0';
    while (n) {
        buf[i++] = (char)('0' + (n % 10));
        n /= 10;
    }
    while (i > 0)
        serial_putc(buf[--i]);
}

/* A small computation that actually runs in C on the bare metal. */
static unsigned sum_to(unsigned n)
{
    unsigned total = 0;
    for (unsigned i = 1; i <= n; ++i)
        total += i;
    return total;
}

void kernel_main(void)
{
    serial_init();

    serial_puts("Hello from bare metal! (ASM bootstrap + C kernel, running in QEMU)\r\n");
    serial_puts("sum(1..100) = ");
    serial_putdec(sum_to(100));
    serial_puts("\r\n");
    serial_puts("Bare-metal program finished.\r\n");

    for (;;) {
        __asm__ volatile ("hlt");
    }
}
