section .data
    hexdigits:      db '0123456789abcdef'
    salutation:     db 'abcde', 10
    salutation_len: equ $ - salutation
    sieve_size:     equ 150
    newline         db 10

section .bss
    sieve:          resb sieve_size+1
    n:              resd 1

section .text
    global  _start

_start:
    call    reset_sieve

;    mov     rbx, 0x8a
;    call    print_num_bx
;    call    print_newline
    
    mov     rbx, 1
    call    not_prime

    call    run_sieve

    call    print_sieve

    mov     rbx, [n]
    mov     rax, 1
    int     80h


run_sieve:

    mov     rax, 2
    mov     [n], rax

.next_n:
    call    print_sieve

    call    mark_multiples
    call    find_next_n
    mov     rax, [n]
    inc     rax
    mov     [n], rax
    cmp     rax, sieve_size
    jc     .next_n

    ret

mark_multiples:
    mov     rax, [n]
    mov     rbx, [n]
    mov     rcx, sieve
    add     rcx, rbx
    dec     rcx

.loop:
    add     rax, rbx
    add     rcx, rbx
    cmp     rax, sieve_size
    jnc      .exit
    mov     byte [rcx], ' '
    jmp     .loop

.exit:
    ret

find_next_n:
    mov     rax, [n]
.loop:
    ;;; debug
    ;;push    rbx
    ;;mov     rbx, rax
    ;;call    print_num_bx
    ;;call    print_newline
    ;;pop rbx

    cmp     rax, sieve_size
    jnc      .exit
    mov     rbx, sieve
    add     rbx, rax
    cmp     byte [rbx], 'x'
    jz      .exit
    inc     rax
    jmp     .loop

.exit:
    mov     [n], rax
    ret


print_sieve:

    mov     rax, 4
    mov     rbx, 1
    mov     rcx, sieve
    mov     rdx, sieve_size
    int     80h

    mov     rax, 4
    mov     rbx, 1
    mov     rcx, newline
    mov     rdx, 1
    int     80h
    ret

not_prime:
    add     rbx, sieve
    dec     rbx
    mov     byte [rbx], ' '
    ret

reset_sieve:
    mov rbx, sieve
    mov rcx, sieve_size

.loop:
    mov     byte [rbx], 'x'
    inc     rbx
    loop    .loop
    ret




print_hexdigit_rbx:
    push    rax
    push    rbx
    push    rcx
    push    rdx


    add     rbx, hexdigits
    mov     rcx, rbx

    mov     rax, 4
    mov     rbx, 1
    mov     rdx, 1
    int     80h

    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret

print_num_bx:
    push    rax
    push    rbx
    push    rcx
    push    rdx

    mov     cx, bx

    mov     ax, 0xf000
    and     bx, ax
    shr     bx, 12
    call print_hexdigit_rbx

    mov     bx, cx
    shr     ax, 4
    and     bx, ax
    shr     bx, 8
    call print_hexdigit_rbx

    mov     bx, cx
    shr     ax, 4
    and     bx, ax
    shr     bx, 4
    call print_hexdigit_rbx

    mov     bx, cx
    shr     ax, 4
    and     bx, ax
    call print_hexdigit_rbx

    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
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
    

