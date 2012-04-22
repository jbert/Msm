package Msm::Evaluator;
use Modern::Perl;
use Moose;

my @BINDINGS;

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
    package Msm::AST::Identifier;

    sub eval { 
        my ($self) = @_;
        foreach my $binding (@BINDINGS) {
            my $value = $binding->{$self->val};
            return $value if defined $value;
        }
        die "Unbound variable: $self";
    }
}
{
    package Msm::AST::Sexp;

    sub eval { 
        my ($self) = @_;

        my $result;
        my @items = @{$self->items};
        my $op = shift @items;

        die "Sexp in op position not yet supported" unless $op->isa('Msm::AST::Atom');
        my $opval = $op->val;

        return $self->_eval_let(@items) if $opval eq 'let';

        my @args = map { $_->eval } @items;
        given ($opval) {
            when ('+')    {
                $result = 0;
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
                my $condition = shift @args;
                my $is_true = ($condition->isa('Msm::AST::Boolean') && $condition->val eq '#t');
                $result = $is_true ? $args[0]: $args[1];
            }
            when ('eq?')    {
                my $is_true = $args[0]->eq($args[1]);
                return Msm::AST::Boolean->new({val => $is_true ? '#t' : '#f'});
            }
            default { die "Unsupported op: " . $op->val; }
        }
        return $result;
    }

    sub _eval_let {
        my ($self, @items) = @_;
        my $bindings = shift @items;
        my %new_binding;
        foreach my $binding (@{$bindings->items}) {
            my $identifier = $binding->items->[0];
            my $value      = $binding->items->[1];
            $new_binding{$identifier->val} = $value->eval;
        }
        unshift @BINDINGS, \%new_binding;
        my @vals = map { $_->eval } @items;
        shift @BINDINGS;
        return $vals[-1];
    }
}
{
    package Msm::AST::Program;

    sub eval { 
        my ($self) = @_;

#        use Data::Dumper;
#        warn Data::Dumper::Dumper($self->sexps);
        my @vals = map { $_->eval } @{$self->sexps};
#        use Data::Dumper;
#        warn Data::Dumper::Dumper(\@vals);
        return $vals[-1]->val;
    }
}

1;
