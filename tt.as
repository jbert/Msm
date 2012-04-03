section .data
    salutation:     db 'abcde', 10
    salutation_len: equ $ - salutation
    sieve_size:     equ 100
    newline         db 10

section .bss
    sieve:          resb sieve_size
    loop_count:     resd 1

section .text
    global  _start

_start:
    call    reset_sieve

    mov     ebx, 1
    call    not_prime
    mov     ebx, 4
    call    not_prime

    call    print_sieve

    mov     eax, 1
    mov     ebx, 11
    int     80h

print_sieve:

    mov     eax, 4
    mov     ebx, 1
    mov     ecx, sieve
    mov     edx, sieve_size
    int     80h

    mov     eax, 4
    mov     ebx, 1
    mov     ecx, newline
    mov     edx, 1
    int     80h
    ret

not_prime:
    add     ebx, sieve
    dec     ebx
    mov     byte [ebx], ' '
    ret

reset_sieve:
    mov ebx, sieve
    mov ecx, sieve_size

.loop:
    mov     byte [ebx], 'x'
    inc     ebx
    loop    .loop
    ret
