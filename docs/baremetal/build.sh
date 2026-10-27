#!/usr/bin/env bash
# Build the bare-metal kernel and run it inside QEMU, capturing the serial
# output to serial.out so the execution result can be printed (e.g. by CI).
#
# The bare-metal kernel has no operating system to return to, so it spins in a
# halt loop after printing its result; QEMU is therefore stopped by `timeout`.
# Exit code 124 from `timeout` is expected; any other non-zero code means a
# real QEMU error (bad kernel, missing device, ...) and must fail the build.
set -euo pipefail
cd "$(dirname "$0")"

echo "== Assemble bootstrap (start.asm) =="
nasm -felf32 start.asm -o start.o

echo "== Compile C kernel (kernel.c) =="
gcc -m32 -ffreestanding -nostdlib -fno-pie -no-pie -O2 -c kernel.c -o kernel.o

echo "== Link (link.ld) =="
ld -N -m elf_i386 -T link.ld -o kernel.elf start.o kernel.o

echo "== Convert to raw binary (QEMU -kernel wants a flat image) =="
objcopy -O binary kernel.elf kernel.bin

echo "== Segments (debug) =="
readelf -l kernel.elf | head -12

echo "== Run in QEMU; serial -> stdout (captured by tee) =="
: > serial.out
set +e
timeout 10 qemu-system-i386 \
    -kernel kernel.bin \
    -nographic -monitor none -no-reboot \
    | tee serial.out
rc=${PIPESTATUS[0]}
set -e

if [ "$rc" -ne 0 ] && [ "$rc" -ne 124 ]; then
    echo "ERROR: QEMU exited with code $rc"
    exit "$rc"
fi

echo "== QEMU finished (rc=$rc; 124 = stopped by timeout, which is expected) =="
echo "== Program execution result =="
cat serial.out
