; ----------------------------------------------------------------------------------------
; Linux x86_64 console program that writes "Hello, World" and exits.
; Uses puts() from the C library.  To assemble, link and run:
;
;     nasm -felf64 helloworld.asm -o helloworld.o
;     gcc helloworld.o -o helloworld
;     ./helloworld
; ----------------------------------------------------------------------------------------
        global  main
        extern  puts
        section .text
main:
        sub     rsp, 8                          ; Align stack to 16 bytes before call
        lea     rdi, [rel message]              ; First argument: address of message
        call    puts                            ; puts(message)
        add     rsp, 8
        ret
message:
        db      'Hello, World', 0               ; C strings need a zero byte at the end
