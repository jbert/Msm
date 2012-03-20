package Msm::Toc;
use Modern::Perl;
use Moose;

# Inject 'toc' methods
{
    package Msm::AST::node;

    sub to_c { die "Don't know how to to_c: " . ref $_[0]; }
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
