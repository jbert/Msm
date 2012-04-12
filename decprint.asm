section .data
    sieve_size:     equ 150
    newline         db 10

section .bss
    ; 64bit integer has <= 20 decimal digits
    ; plus one for sign
    ; plus one for luck
    decprint_buf:   resb 22
    n:              resd 1

section .text
    global  _start

_start:
    mov     rax, 13
    call    decprint
    call    print_newline

    mov     rax, 13
    neg     eax
    call    decprint
    call    print_newline

    mov     eax, 2
    neg     eax
    call    decprint
    call    print_newline

    ; exit
    mov     rbx, rax
    mov     rax, 1
    int     80h


decprint:
    mov     rbx, decprint_buf

    mov     r8, 0

    cmp     eax, 0x80000000
    jc      .not_neg
    mov     ecx, eax
    neg     eax
    mov     r8, 1

.not_neg:

.next_digit:
    mov     rdx, 0
    mov     ecx, 10
    idiv    ecx

    add     dl, '0'
    mov     [rbx], dl
    inc     rbx

    cmp     rax, 0
    jnz      .next_digit

    cmp     r8, 1
    jnz     .dont_print_sign
    mov     byte [rbx], '-'
    inc     rbx
.dont_print_sign:


    dec     rbx
    mov     rcx, rbx
.print_digit:

    mov     rax, 4
    mov     rbx, 1
;    mov     rcx, newline
    mov     rdx, 1
    int     80h
    dec     rcx
    cmp     rcx, decprint_buf
    jnc     .print_digit

    ret

print_newline:
    push    rax
    push    rbx
    push    rcx
    push    rdx

    mov     rax, 4
    mov     rbx, 1
    mov     rcx, newline
    mov     rdx, 1
    int     80h


    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret
    

