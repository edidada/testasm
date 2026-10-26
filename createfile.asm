; ----------------------------------------------------------------------------------------
; Linux x86_64 exclusive file create, straight syscalls, no libc.
; Equivalent of C: open("test.txt", O_WRONLY|O_CREAT|O_EXCL, 0644)
;                  write(fd, "a", 1)
;                  close(fd)
; Exits 0 on success, 1 when any step fails (e.g. test.txt already exists).
;
;     nasm -felf64 createfile.asm -o createfile.o
;     ld createfile.o -o createfile
; ----------------------------------------------------------------------------------------

        global  _start

        section .text
_start:
        ; open(filename, O_WRONLY|O_CREAT|O_EXCL, 0644)
        ; O_WRONLY = 0x1, O_CREAT = 0x40, O_EXCL = 0x80
        lea     rdi, [rel filename]
        mov     esi, 0xC1                       ; O_WRONLY|O_CREAT|O_EXCL
        mov     edx, 0644o                      ; permissions for new file
        mov     eax, 2                          ; sys_open
        syscall
        jc      error                           ; carry set means syscall failed

        ; write(fd, "a", 1)
        mov     rbx, rax                        ; save the fd for close()
        mov     edi, eax                        ; fd
        lea     rsi, [rel content]
        mov     edx, 1                          ; byte count
        mov     eax, 1                          ; sys_write
        syscall
        cmp     rax, 1
        jne     close_error

        ; close(fd)
        mov     edi, ebx
        mov     eax, 3                          ; sys_close
        syscall

        ; exit(0)
        xor     edi, edi
        mov     eax, 60                         ; sys_exit
        syscall

close_error:
        mov     edi, ebx                        ; still close the fd we opened
        mov     eax, 3                          ; sys_close
        syscall

error:
        mov     edi, 1
        mov     eax, 60                         ; sys_exit(1)
        syscall

        section .data
filename:
        db      'test.txt', 0                   ; C string needs a zero byte
content:
        db      'a'
