package Msm::Asm;
use Modern::Perl;
use Moose;

has '_bss_section', is => 'rw';
has '_text_section', is => 'rw';
has '_data_section', is => 'rw';

use File::Temp qw(tempfile);

sub run_ast {
    my ($self, $ast) = @_;

    $self->_data_section('');
    $self->_bss_section('');
    $self->_text_section('');

    $self->_emit_text($ast->to_asm($self));
    $self->_emit_text($self->_lib_text);
    $self->_emit_bss($self->_lib_bss);
    $self->_emit_data($self->_lib_data);

    my ($asm_fh, $asm_file) = tempfile('/tmp/asmXXXX', SUFFIX => '.asm', UNLINK => 0);
    print $asm_fh "section .data\n" . $self->_data_section;
    print $asm_fh "section .bss\n" . $self->_bss_section;
    print $asm_fh "section .text\n" . $self->_text_section;
    close $asm_fh or die "can't close asm fh $asm_file : $!";

    my ($exe_fh, $exe_file) = tempfile('/tmp/asmXXXX', UNLINK => 1);
    close $exe_fh;
    $self->_compile_asm($asm_file, $exe_file);

#    my $result = system($exe_file);
#    $result >>= 8; # get exit code
    my ($result) = `$exe_file`;
    chomp $result;
    return $result;
}

sub _emit_data {
    my ($self, $data) = @_;
    $self->_data_section($self->_data_section . $data);
}

sub _emit_text {
    my ($self, $text) = @_;
    $self->_text_section($self->_text_section . $text);
}

sub _emit_bss {
    my ($self, $text) = @_;
    $self->_bss_section($self->_bss_section . $text);
}

sub _compile_asm {
    my ($self, $asm_file, $exe_file) = @_;
    my $obj_file = $asm_file;
    $obj_file =~ s/\.asm/\.o/;
    my $rc;
    $rc = system("nasm -f elf64 $asm_file -o $obj_file");
    die "Can't assemble" unless $rc == 0;
    $rc = system("ld $obj_file -o $exe_file");
    die "Can't link" unless $rc == 0;
    return 1;
}

my @BINDINGS;

sub _find_lexical {
    my ($class, $name) = @_;
    foreach my $frame (@BINDINGS) {
        return $frame->{$name} if exists $frame->{$name};
    }
    die "Can't find lexical var [$name]";
}

# Inject 'to_asm' methods
{
    package Msm::AST::Node;

    sub to_asm { die "Don't know how to to_asm: " . ref $_[0]; }
}
{
    package Msm::AST::Integer;

    sub to_asm {
        my $val = $_[0]->val;
        return <<"EOASM";
    ; Integer $val
    mov     rax, $val
    push    rax
EOASM
    }
}
{
    package Msm::AST::Boolean;

    sub to_asm {
        my $val = $_[0]->val;
        my $asm_val = $val eq '#t' ? 1 : 0;
        return <<"EOASM";
    ; Boolean $val
    mov     rax, $asm_val
    push    rax
EOASM
    }
}
{
    package Msm::AST::Identifier;

    sub to_asm {
        my ($self, $runner) = @_;
        my $val = $_[0]->val;
        my $label = $runner->_find_lexical($val);
        return <<"EOASM";
    ; Identifier $val
    mov     rax, [$label]
    push    rax
EOASM
    }
}
{
    package Msm::AST::Sexp;

    sub to_asm { 
        my ($self, $runner) = @_;

        my @items = @{$self->items};
        my $op = shift @items;
        my $opval = $op->val;

        my $result = <<"EOASM";
    ; OP Expression $opval
EOASM

        if ($opval eq 'if') {
            return $self->_if_to_asm($runner, @items);
        }
        elsif ($opval eq 'eq?') {
            return $self->_eq_to_asm($runner, @items);
        }
        elsif ($opval eq 'let') {
            return $self->_let_to_asm($runner, $result, @items);
        }
        my $asm_instruction;
        given ($opval) {
            when ('+')    {
                $asm_instruction = 'add';
            }
            when ('-')    {
                $asm_instruction = 'sub';
            }
            when ('*')    {
                $asm_instruction = 'imul';
            }
            default { die "Unsupported op: " . $op->val; }
        }

        my $have_two_args = 0;
        foreach my $arg (@items) {
            $result .= $arg->to_asm($runner);
            if ($have_two_args) {
                $result .= <<"EOASM";
    pop rbx
    pop rax
    $asm_instruction rax, rbx
    push rax
EOASM
            }
            $have_two_args = 1;

        }
        return $result;
    }

    sub _let_to_asm {
        my ($self, $runner, $result, @items) = @_;

        my $bindings = shift @items;
        my %new_binding;
        foreach my $binding (@{$bindings->items}) {
            my $identifier = $binding->items->[0];
            my $label = Msm::Asm->_make_label;
            $runner->_emit_bss(<<"EOBSS");
    $label:      resb 8
EOBSS
            $result .= $binding->items->[1]->to_asm($runner);
            $result .= <<"EOASM";
    pop     rax
    mov     [$label], rax
EOASM
            $new_binding{$identifier->val} = $label;
        }
        unshift @BINDINGS, \%new_binding;
        $result .= $items[0]->to_asm($runner);        # Only one expression in let
        shift @BINDINGS;
        return $result;
    }

    sub _eq_to_asm {
        my ($self, $runner, @items) = @_;

        my $result = <<"EOASM";
    ; eq OP
EOASM
        $result .= join ("\n", map { $_->to_asm($runner) } @items);
        my $label_suffix = int(rand(1_000_000));
        $result .= <<"EOASM";
    pop     rbx
    pop     rax
    cmp     rax, rbx

    mov     rax, 0      ; Not equal, leave z flag alone
    jnz     .if_diff_$label_suffix
    mov     rax, 1
.if_diff_$label_suffix:
    push    rax

EOASM
    }

    sub _if_to_asm {
        my ($self, $runner, @items) = @_;

        my $condition = shift @items;
        # Push condition
        my $result = <<"EOASM";
    ; if OP
EOASM
        $result .= $condition->to_asm($runner);
        my $if_true_asm = $items[0]->to_asm($runner);
        my $if_false_asm = $items[1]->to_asm($runner);

        my $label_suffix = int(rand(1_000_000));
        $result .= <<"EOASM";
    pop     rax
    cmp     rax, 0
    jnz     .if_true_$label_suffix
.if_false_$label_suffix:
    $if_false_asm
    jmp     .if_cont_$label_suffix

.if_true_$label_suffix:
    $if_true_asm
.if_cont_$label_suffix:
EOASM
    }
}
{
    package Msm::AST::Program;

    sub to_asm { 
        my ($self, $runner) = @_;

        my $result = <<"EOPREAMBLE";
    global  _start

_start:
EOPREAMBLE
        my @code = map { $_->to_asm($runner) } @{$self->sexps};
        $result .= join("\n", @code);
        $result .= <<"EOPOSTAMBLE";
    call    print_decimal
    pop     rbx
    mov     rax, 1
    int     80h
EOPOSTAMBLE
    }
}

sub _lib_text {
    my ($self) = @_;
    return << "EOLIB";
;
; Msm library code
;
print_decimal:
    mov     rbx, print_decimal_buf

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
    mov     rdx, 1
    int     80h
    dec     rcx
    cmp     rcx, print_decimal_buf
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
    
EOLIB
}

sub _lib_bss {
    my ($self) = @_;
    return << "EOBSS";
    print_decimal_buf:      resb 22
EOBSS
}

sub _lib_data {
    my ($self) = @_;
    return << "EODATA";
    newline         db 10
EODATA
}

my $LABEL_COUNTER = 1;
sub _make_label {
    my ($class) = @_;
    return "result" . $LABEL_COUNTER++;
}


1;
