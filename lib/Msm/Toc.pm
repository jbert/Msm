package Msm::Toc;
use Modern::Perl;
use Moose;

use File::Temp qw(tempfile);

sub run_ast {
    my ($self, $ast) = @_;

    my $c_code = $ast->to_c;
    my ($c_fh, $c_file) = tempfile('/tmp/tocXXXX', SUFFIX => '.c', UNLINK => 0);
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

    sub declare     { die "Don't know how to declare: " . ref $_[0]; }
    sub expression  { die "Don't know how to expression: " . ref $_[0]; }
}
{
    package Msm::AST::Atom;

    sub declare     { return '' }
    sub expression  { return $_[0]->val; }
}
{
    package Msm::AST::Boolean;

    sub expression {
        my ($self) = @_;
        return $self->val eq '#t' ? 1 : 0;
    }
}
{
    package Msm::AST::Sexp;

    sub declare { 
        my ($self) = @_;
        my $name = Msm::Toc->_new_name;
        my $result = "int $name;\n";
        $self->stash($name);

        my @items = @{$self->items};

        my $op = shift @items;
        my $opval = $op->val;
        return $self->_declare_let($result, @items) if $opval eq 'let';

        $result .= $_->declare for @items;

        $result .= "$name = ";
        my @args = map { $_->expression } @items;
        given ($opval) {
            when ('+')    {
                $result .= join(" $opval ", @args);
            }
            when ('-')    {
                $result .= join(" $opval ", @args);
            }
            when ('*')    {
                $result .= join(" $opval ", @args);
            }
            when ('if')    {
                die "if requires 3 arguments" unless scalar @args == 3;
                $result .= "($args[0] ? $args[1] : $args[2])";
            }
            when ('eq?')    {
                die "eq? requires 2 arguments" unless scalar @args == 2;
                $result .= "($args[0] == $args[1]) ? 1 : 0";
            }
            default { die "Unsupported op: " . $op->val; }
        }
        $result .= ";\n";
        return $result;
    }
    sub expression { return $_[0]->stash; }

    sub _declare_let {
        my ($self, $result, @items) = @_;
        my $name = $self->stash;
        my $bindings = shift @items;
        $result .= "{\n";
        foreach my $binding (@{$bindings->items}) {
            # TODO - make c-safe identifier from scheme-safe identifier
            my $identifier = $binding->items->[0]->val;
            $result .= $binding->items->[1]->declare;
            my $value = $binding->items->[1]->expression;
            $result .= "int $identifier = $value;\n";
        }
        $result .= $_->declare for @items;
        $result .= "$name = " . $items[-1]->expression . ";\n";
        $result .= "}\n";
        return $result;
    }
}
{
    package Msm::AST::Program;

    sub to_c { 
        my ($self) = @_;

        my $result = <<"EOPREAMBLE";
#include <stdio.h>

int main() {
EOPREAMBLE
        $result .= $self->declare;
        my $name = $self->stash;
        my @sexps = @{$self->sexps};
        $result .= $_->declare for @sexps;
        $result .= "$name = " . $sexps[-1]->expression . ";\n";
        $result .= <<"EOPOSTAMBLE";
    printf("%d\\n", $name);
    return 0;
}
EOPOSTAMBLE
        return $result;
    }

    sub declare {
        my ($self) = @_;
        my $name = Msm::Toc->_new_name;
        $self->stash($name);
        return "int $name;\n";
    }

    sub expression { return $_[0]->stash; }
}

my $NAME_COUNTER = 1;
sub _new_name {
    my ($class) = @_;
    return "result" . $NAME_COUNTER++;
}

1;
