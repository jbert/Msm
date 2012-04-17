package Msm::Evaluator;
use Modern::Perl;
use Moose;

sub run_ast {
    my ($self, $ast) = @_;

    return $ast->eval;
}

# Inject eval methods
{
    package Msm::AST::Node;

    sub eval { die "Don't know how to eval: " . ref $_[0]; }
}
{
    package Msm::AST::Atom;

    sub eval { return $_[0]; }
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
#                use Data::Dumper;
#                warn Data::Dumper::Dumper(\@args);
                $result += $_->val for @args;
                $result = Msm::AST::Integer->new({val => $result});
            }
            when ('-')    {
                $result = shift @args;
                $result = $result->val;
                $result -= $_->val for @args;
                $result = Msm::AST::Integer->new({val => $result});
            }
            when ('*')    {
                $result = 1;
                $result *= $_->val for @args;
                $result = Msm::AST::Integer->new({val => $result});
            }
            when ('if')    {
                die "if requires 3 args" unless scalar @args == 3;
                my $condition = shift @args;
                my $is_true = ($condition->isa('Msm::AST::Boolean') && $condition->val eq '#t');
                $result = $is_true ? $args[0]: $args[1];
            }
            default { die "Unsupported op: " . $op->val; }
        }
        return $result;
    }
}
{
    package Msm::AST::Program;

    sub eval { 
        my ($self) = @_;

        my @vals = map { $_->eval } @{$self->exps};
#        use Data::Dumper;
#        warn Data::Dumper::Dumper(\@vals);
        return $vals[-1]->val;
    }
}

1;

1;
