; ---------------------------------------------------------------------------
; 32-bit Multiboot bootstrap for a bare-metal kernel.
;
; QEMU loads this image through the -kernel option, finds the Multiboot header,
; switches the CPU into 32-bit protected mode and jumps to _start.  All this
; assembly does is set up a stack and call the C function kernel_main().  This
; is the "ASM initializes the environment, then calls a C function" part of the
; bare-metal experiment described in ../裸机程序.txt.
;
; Build:
;     nasm -felf32 start.asm -o start.o
;     gcc -m32 -ffreestanding -nostdlib -O2 -c kernel.c -o kernel.o
;     ld -m elf_i386 -T link.ld -o kernel.elf start.o kernel.o
;     qemu-system-i386 -kernel kernel.elf -serial file:serial.out -display none
; ---------------------------------------------------------------------------

bits 32

section .text

; --- Multiboot header (must be within the first 8 KiB, 32-bit aligned) ---
MB_MAGIC    equ 0x1BADB002
MB_FLAGS    equ 0x00000000          ; no optional features requested
MB_CHECKSUM equ 0x10000000 - (MB_MAGIC + MB_FLAGS)

align 4
dd MB_MAGIC
dd MB_FLAGS
dd MB_CHECKSUM

global _start
extern kernel_main

_start:
    ; The Multiboot loader already put us in 32-bit protected mode with paging
    ; disabled, so a flat 4 GiB address space is available.  Point ESP at the
    ; top of a statically reserved stack buffer.
    mov     esp, stack_top
    call    kernel_main

    ; kernel_main never returns; if it does, freeze the CPU.
.hang:
    cli
    hlt
    jmp     .hang

section .bss
align 16
resb 16384                           ; 16 KiB stack
stack_top:
