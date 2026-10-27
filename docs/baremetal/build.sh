#!/usr/bin/env bash
# Build the bare-metal kernel and run it inside QEMU, capturing the serial
# output to serial.out so the execution result can be printed (e.g. by CI).
set -euo pipefail
cd "$(dirname "$0")"

echo "== Assemble bootstrap (start.asm) =="
nasm -felf32 start.asm -o start.o

echo "== Compile C kernel (kernel.c) =="
gcc -m32 -ffreestanding -nostdlib -O2 -c kernel.c -o kernel.o

echo "== Link (link.ld) =="
ld -m elf_i386 -T link.ld -o kernel.elf start.o kernel.o
echo "== Segments (debug) =="
readelf -l kernel.elf | head -20

echo "== Run in QEMU, serial -> serial.out =="
: > serial.out
timeout 10 qemu-system-i386 \
    -kernel kernel.elf \
    -serial file:serial.out \
    -display none -monitor none -no-reboot

echo "== Program execution result =="
cat serial.out
