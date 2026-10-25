; ----------------------------------------------------------------------------------------
; macOS x86_64 console program that writes "Hello, World" and exits.
; Uses puts() from the C library.  To assemble, link and run:
;
;     nasm -fmacho64 helloworld.asm -o helloworld.o
;     gcc helloworld.o -o helloworld
;     ./helloworld
; ----------------------------------------------------------------------------------------
        global  _main
        extern  _puts
        section .text
_main:
        sub     rsp, 8                          ; Align stack to 16 bytes before call
        lea     rdi, [rel message]              ; First argument: address of message
        call    _puts                           ; puts(message)
        add     rsp, 8
        xor     eax, eax                        ; Return 0 from main
        ret
message:
        db      'Hello, World', 0               ; C strings need a zero byte at the end
