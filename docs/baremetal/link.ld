/* Linker script for the Multiboot bare-metal kernel.
 * QEMU's -kernel loader places a Multiboot image at 0x100000 (1 MiB) by
 * default, so we link the image there to keep every address consistent. */

ENTRY(_start)

SECTIONS
{
    . = 0x100000;

    .text   : { *(.text) }
    .rodata : { *(.rodata .rodata.*) }
    .data   : { *(.data .data.*) }
    .bss    : { *(.bss .bss.* COMMON) }
}
