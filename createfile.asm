; ----------------------------------------------------------------------------------------
; Win32 x86 exclusive file create with kernel32 APIs, no libc.
; Equivalent of C: CreateFileA("test.txt", GENERIC_WRITE, 0, NULL,
;                              CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL)
;                  WriteFile(handle, "a", 1, &bytesWritten, NULL)
;                  CloseHandle(handle)
; Returns 0 on success, 1 when any step fails (e.g. test.txt already exists).
;
;     nasm -fwin32 createfile.asm
;     link /entry:main createfile.obj /subsystem:console /nodefaultlib kernel32.lib
; ----------------------------------------------------------------------------------------

GENERIC_WRITE        equ 0x40000000
CREATE_NEW           equ 1
FILE_ATTRIBUTE_NORMAL equ 0x80
INVALID_HANDLE_VALUE equ -1

    extern  _CreateFileA@28
    extern  _WriteFile@20
    extern  _CloseHandle@4
    extern  _ExitProcess@4

    global  _main

    section .text

_main:
    ; local variable: bytesWritten for WriteFile
bytesWritten equ -4
    mov     ebp, esp
    sub     esp, 4

    ; handle = CreateFileA("test.txt", GENERIC_WRITE, 0 /*no sharing*/,
    ;                      NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL)
    push    0                               ; hTemplateFile
    push    FILE_ATTRIBUTE_NORMAL           ; dwFlagsAndAttributes
    push    CREATE_NEW                      ; dwCreationDisposition: fail if exists
    push    0                               ; lpSecurityAttributes
    push    0                               ; dwShareMode
    push    GENERIC_WRITE                   ; dwDesiredAccess
    push    filename                        ; lpFileName
    call    _CreateFileA@28

    cmp     eax, INVALID_HANDLE_VALUE
    je      error                           ; failed, e.g. test.txt already exists

    ; WriteFile(handle, "a", 1, &bytesWritten, NULL)
    mov     ebx, eax                        ; save the handle for CloseHandle
    push    0                               ; lpOverlapped
    lea     eax, [ebp + bytesWritten]
    push    eax                             ; lpNumberOfBytesWritten
    push    1                               ; nNumberOfBytesToWrite
    push    content                         ; lpBuffer
    push    ebx                             ; hFile
    call    _WriteFile@20

    or      eax, eax                        ; WriteFile returns BOOL
    jz      close_error

    ; CloseHandle(handle)
    push    ebx
    call    _CloseHandle@4

    ; ExitProcess(0)
    push    0
    call    _ExitProcess@4

close_error:
    push    ebx                             ; still close the handle we opened
    call    _CloseHandle@4

error:
    ; ExitProcess(1)
    push    1
    call    _ExitProcess@4

    section .data

filename:
    db      'test.txt', 0                   ; C string needs a zero byte
content:
    db      'a'
