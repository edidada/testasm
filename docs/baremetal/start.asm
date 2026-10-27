; ---------------------------------------------------------------------------
; 32-bit Multiboot bootstrap for a bare-metal kernel.
;
; QEMU loads this image through the -kernel option, finds the Multiboot header
; (placed at the very start of the raw binary), switches the CPU into 32-bit
; protected mode and jumps to the load/entry address.  All this assembly does
; is set up a stack and call the C function kernel_main().  This is the
; "ASM initializes the environment, then calls a C function" part of the
; bare-metal experiment described in ../裸机程序.txt.
;
; Build:
;     nasm -felf32 start.asm -o start.o
;     gcc -m32 -ffreestanding -nostdlib -fno-pie -no-pie -O2 -c kernel.c -o kernel.o
;     ld -N -m elf_i386 -T link.ld -o kernel.elf start.o kernel.o
;     objcopy -O binary kernel.elf kernel.bin
;     qemu-system-i386 -kernel kernel.bin -serial file:serial.out -display none
; ---------------------------------------------------------------------------

bits 32

section .text

; --- Multiboot header (must be within the first 8 KiB, 4-byte aligned) ---
; QEMU's load_multiboot takes the "raw" branch when MULTIBOOT_HEADER_HAS_ADDR
; (bit 16) is set, so we must provide the address fields.  The checksum must
; satisfy:  magic + flags + checksum == 0  (mod 2^32).
MB_MAGIC        equ 0x1BADB002
MB_FLAGS        equ 0x00030000   ; bit16: HAS_ADDR, bit17: HAS_ENTRY
MB_CHECKSUM     equ 0xE44F4FFE   ; -(MB_MAGIC + MB_FLAGS)
MB_HEADER_ADDR  equ 0x100000
MB_LOAD_ADDR     equ 0x100000
MB_LOAD_END_ADDR equ 0x00000000   ; 0 => load the whole rest of the file
MB_BSS_END_ADDR  equ 0x00000000   ; bss is already zeroed inside the image
MB_ENTRY_ADDR    equ 0x100020     ; _start sits right after the 32-byte header

align 4
dd MB_MAGIC
dd MB_FLAGS
dd MB_CHECKSUM
dd MB_HEADER_ADDR
dd MB_LOAD_ADDR
dd MB_LOAD_END_ADDR
dd MB_BSS_END_ADDR
dd MB_ENTRY_ADDR

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
