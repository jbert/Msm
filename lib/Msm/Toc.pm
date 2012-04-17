package Msm::Toc;
use Modern::Perl;
use Moose;

use File::Temp qw(tempfile);

sub run_ast {
    my ($self, $ast) = @_;

    my $c_code = $ast->to_c;
    my ($c_fh, $c_file) = tempfile('/tmp/tocXXXX', SUFFIX => '.c', UNLINK => 1);
    print $c_fh $c_code;
    close $c_fh or die "can't close c fh $c_file : $!";

    my ($exe_fh, $exe_file) = tempfile('/tmp/tocXXXX', UNLINK => 1);
    close $exe_fh;
    $self->_compile_c($c_file, $exe_file);

    my $result = `$exe_file`;
    chomp $result;
    return $result;
}

sub _compile_c {
    my ($self, $c_file, $exe_file) = @_;
    my $rc = system("gcc $c_file -o $exe_file");
    return $rc == 0;
}

# Inject 'toc' methods
{
    package Msm::AST::Node;

    sub to_c { die "Don't know how to to_c: " . ref $_[0]; }
}
{
    package Msm::AST::Boolean;

    sub to_c { 
        my ($self) = @_;
        return $self->val eq '#t' ? 1 : 0;
    }
}
{
    package Msm::AST::Integer;

    sub to_c { return $_[0]->val; }
}
{
    package Msm::AST::Expression;

    sub to_c { 
        my ($self) = @_;

        my $result;
        my $op = $self->op;
        my $opval = $self->op->val;
        my @args = map { $_->to_c } @{$self->args};
        given ($opval) {
            when ('+')    {
                $result = join(" $opval ", @args);
            }
            when ('-')    {
                $result = join(" $opval ", @args);
            }
            when ('*')    {
                $result = join(" $opval ", @args);
            }
            when ('if')    {
                die "if requires 3 arguments" unless scalar @args == 3;
                $result = "($args[0] ? $args[1] : $args[2])";
            }
            default { die "Unsupported op: " . $op->val; }
        }
        return '(' . $result . ')';
    }
}
{
    package Msm::AST::Program;

    sub to_c { 
        my ($self) = @_;

        my $result = <<"EOPREAMBLE";
#include <stdio.h>

int main() {
    int result = 
EOPREAMBLE
        my @expressions = map { $_->to_c } @{$self->exps};
        $result .= join(",", @expressions);
        $result .= <<"EOPOSTAMBLE";
;
    printf("%d\\n", result);
    return 0;
}
EOPOSTAMBLE
        return $result;
    }
}
1;
