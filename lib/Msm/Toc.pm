package Msm::Toc;
use Modern::Perl;
use Moose;

use File::Temp qw(tempfile);

my $result_name_suffix = '0';
my @RESULT_VAR_NAMES;

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
    package Msm::AST::Identifier;

    sub to_c { return $_[0]->val; }
}
{
    package Msm::AST::Sexp;

    sub to_c { 
        my ($self) = @_;

        my $result;
        my @items = @{$self->items};
        my $op = shift @items;
        my $opval = $op->val;

        return $self->_toc_let(@items) if $opval eq 'let';

        my @args = map { $_->to_c } @items;
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
            when ('eq?')    {
                die "eq? requires 2 arguments" unless scalar @args == 2;
                $result = "($args[0] == $args[1]) ? 1 : 0";
            }
            default { die "Unsupported op: " . $op->val; }
        }
        return '(' . $result . ')';
    }

    sub _toc_let {
        my ($self, @items) = @_;
        my $bindings = shift @items;
        my $result = Msm::Toc->_push_result_name . "\n{";
        foreach my $binding (@{$bindings->items}) {
            # TODO - make c-safe identifier from scheme-safe identifier
            my $identifier = $binding->items->[0]->val;
            my $value      = $binding->items->[1];
            $result .= <<"EOVAR";
    int $identifier;
    $identifier = 
EOVAR
            $result .= $value->to_c;
            $result .= ';';
        }
        my $this_result_name = Msm::Toc->_pop_result_name;
        $result .= $this_result_name . " = " . $_->to_c . ";" for @items;
        $result .= "}";
        my $containing_result_name = $RESULT_VAR_NAMES[0];
        $result .= "$containing_result_name = $this_result_name;\n";
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
        $result .= Msm::Toc->_push_result_name;
        my @expressions = map { $_->to_c } @{$self->sexps};
        $result .= join(",", @expressions);
        my $printf_result_name = Msm::Toc->_pop_result_name;
        $result .= <<"EOPOSTAMBLE";
;
    printf("%d\\n", $printf_result_name);
    return 0;
}
EOPOSTAMBLE
        return $result;
    }
}

sub _push_result_name {
    my ($class) = @_;
    my $name = "result" . ++$result_name_suffix;
    push @RESULT_VAR_NAMES, $name;
    return "\tint $name;"
}

sub _pop_result_name {
    my ($class) = @_;
    return pop @RESULT_VAR_NAMES;
}

1;
