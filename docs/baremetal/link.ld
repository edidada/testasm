/* Linker script for the Multiboot bare-metal kernel.
 *
 * QEMU's -kernel loader scans only the first 8 KiB of the *file* for the
 * Multiboot magic.  By default GNU ld aligns the first LOAD segment to the
 * page size (0x1000), pushing the magic to file offset 0x1000 -- right at the
 * edge of (or past) QEMU's scan window, so it never recognizes the image as
 * Multiboot and instead tries to load it as a Linux kernel (-> "PVH ELF
 * Note" error).  We force a tiny file offset with AT() and a small page size
 * while keeping the virtual/load address at 0x100000. */

ENTRY(_start)

SECTIONS
{
    . = 0x100000;

    .text   : AT(0x100) { *(.text) }
    .rodata : { *(.rodata .rodata.*) }
    .data   : { *(.data .data.*) }
    .bss    : { *(.bss .bss.* COMMON) }
}
