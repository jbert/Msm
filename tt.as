section .data
    salutation:     db 'abcde', 10
    salutation_len: equ $ - salutation
    sieve_size:     equ 10

section .bss
    sieve:          resb sieve_size
    loop_count:     resd 1

section .text
    global  _start

_start:
    call    clear_sieve

    mov     ecx, sieve_size

.jb_loop:
    mov     [loop_count], ecx
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, salutation
    mov     edx, salutation_len
    int     80h

    mov     ecx, [loop_count]
    loop    .jb_loop

    mov     eax, 1
    mov     ebx, 11
    int     80h

clear_sieve:
    mov ebx, sieve
    mov ecx, sieve_size

.loop:
    mov     byte [ebx], 'x'
    loop    .loop
    ret
