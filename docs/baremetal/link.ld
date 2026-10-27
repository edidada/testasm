/* Linker script for the Multiboot bare-metal kernel.
 *
 * QEMU's -kernel loader scans only the first 8 KiB of the *file* for the
 * Multiboot magic.  By default GNU ld would place the first segment at the
 * same offset as its virtual address (0x100000), pushing the magic past the
 * 8 KiB window and making QEMU miss it (it then tries to load the image as a
 * Linux kernel and fails with "PVH ELF Note").  We force the segment's file
 * offset low with AT() while keeping the virtual/load address at 0x100000, so
 * the magic is found and the code still runs where it expects to. */

ENTRY(_start)

SECTIONS
{
    . = 0x100000;

    .text   : AT(0x1000) { *(.text) }
    .rodata : { *(.rodata .rodata.*) }
    .data   : { *(.data .data.*) }
    .bss    : { *(.bss .bss.* COMMON) }
}
