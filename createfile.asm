; ----------------------------------------------------------------------------------------
; macOS x86_64 exclusive file create, straight BSD syscalls, no libc.
; Equivalent of C: open("test.txt", O_WRONLY|O_CREAT|O_EXCL, 0644)
;                  write(fd, "a", 1)
;                  close(fd)
; Returns 0 on success, 1 when any step fails (e.g. test.txt already exists).
;
;     nasm -fmacho64 createfile.asm -o createfile.o
;     gcc createfile.o -o createfile
;
; macOS syscall numbers live in the UNIX domain: 0x2000000 | syscall number.
;   open = 5, write = 4, close = 6, exit = 1
; macOS open flags: O_WRONLY = 0x1, O_CREAT = 0x200, O_EXCL = 0x800
; ----------------------------------------------------------------------------------------

        global  _main

        section .text
_main:
        ; open(filename, O_WRONLY|O_CREAT|O_EXCL, 0644)
        lea     rdi, [rel filename]
        mov     esi, 0xA01                      ; O_WRONLY|O_CREAT|O_EXCL
        mov     edx, 0644o                      ; permissions for new file
        mov     rax, 0x2000005                  ; sys_open
        syscall
        jc     SysError                         ; carry set means syscall failed

        ; write(fd, "a", 1)
        mov     r12, rax                        ; save the fd for close()
        mov     rdi, rax                        ; fd
        lea     rsi, [rel content]
        mov     rdx, 1                          ; byte count
        mov     rax, 0x2000004                  ; sys_write
        syscall
        cmp     rax, 1
        jne     close_error

        ; close(fd)
        mov     rdi, r12
        mov     rax, 0x2000006                  ; sys_close
        syscall

        xor     eax, eax
        ret

close_error:
        mov     rdi, r12                        ; still close the fd we opened
        mov     rax, 0x2000006                  ; sys_close
        syscall
SysError:
        mov     rdi, 1
        mov     rax, 0x2000001                  ; sys_exit(1)
        syscall

        section .data
filename:
        db      'test.txt', 0                   ; C string needs a zero byte
content:
        db      'a'
