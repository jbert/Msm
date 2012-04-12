package Msm::Asm;
use Modern::Perl;
use Moose;

use File::Temp qw(tempfile);

sub run_ast {
    my ($self, $ast) = @_;

    my $asm_code = $ast->to_asm;
    my ($asm_fh, $asm_file) = tempfile('/tmp/asmXXXX', SUFFIX => '.asm', UNLINK => 0);
    print $asm_fh $asm_code;
    close $asm_fh or die "can't close asm fh $asm_file : $!";

    my ($exe_fh, $exe_file) = tempfile('/tmp/asmXXXX', UNLINK => 1);
    close $exe_fh;
    $self->_compile_asm($asm_file, $exe_file);

    my $result = system($exe_file);
    $result >>= 8; # get exit code
    return $result;
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
    mov     rax, $val
    push    rax
EOASM
    }
}
{
    package Msm::AST::Expression;

    sub to_asm { 
        my ($self) = @_;

        my $result;
        my $op = $self->op;
        my $opval = $self->op->val;

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
        foreach my $arg (@{$self->args}) {
            $result .= $arg->to_asm;
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
}
{
    package Msm::AST::Program;

    sub to_asm { 
        my ($self) = @_;

        my $result = <<"EOPREAMBLE";
section .text
    global  _start

_start:
EOPREAMBLE
        my @code = map { $_->to_asm } @{$self->exps};
        $result .= join("\n", @code);
        $result .= <<"EOPOSTAMBLE";
    pop     rbx
    mov     rax, 1
    int     80h
EOPOSTAMBLE
    }
}
1;
