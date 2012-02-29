package Msm::Evaluator;
use Modern::Perl;
use Moose;

# Inject eval methods
{
    package Msm::AST::node;

    sub eval { die "Don't know how to eval: " . ref $_[0]; }
}
{
    package Msm::AST::Atom;

    sub eval { return $_[0]->val; }
}
{
    package Msm::AST::Expression;

    sub eval { 
        my ($self) = @_;

        my $result;
        my $op = $self->op;
        my @args = map { $_->eval } @{$self->args};
        given ($op->val) {
            when ('+')    {
                $result = 0;
                $result += $_ for @args;
            }
            when ('-')    {
                $result = shift @args;
                $result -= $_ for @args;
            }
            when ('*')    {
                $result = 1;
                $result *= $_ for @args;
            }
            default { die "Unsupported op: " . $op->val; }
        }
        return $result;
    }
}

1;
