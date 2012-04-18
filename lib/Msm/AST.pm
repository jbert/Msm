package Msm::AST;
use Modern::Perl;
{
    package Msm::AST::Node;
    use Moose;
}
{
    package Msm::AST::Atom;
    use Moose;
    extends 'Msm::AST::Node';
    has 'val', is => 'rw';
    use overload '""' => sub { return $_[0]->val; };

    sub eq {
        my ($self, $other) = @_;
        return unless ref $other eq ref $self;      # Must be same type
        return unless $other->val eq $self->val;    # Must be same val
        return 1;                                   # All ok
    }

    sub validate { return 1; }
}
{
    package Msm::AST::Boolean;
    use Moose;
    extends 'Msm::AST::Atom';

    sub validate { 
        my ($self) = @_;
        my $val = $self->val;
        die "Invalid boolean $val" unless $val eq '#f' || $val eq '#t';
    }
}
{
    package Msm::AST::Integer;
    use Moose;
    extends 'Msm::AST::Atom';

    sub validate { 
        my ($self) = @_;
        my $val = $self->val;
        die "Invalid integer $val" unless $val =~ m{^[+-]?\d+$}
    }
}
{
    package Msm::AST::Identifier;
    use Moose;
    extends 'Msm::AST::Atom';
}
{
    package Msm::AST::Sexp;
    use Moose;
    extends 'Msm::AST::Node';
    has 'items', is => 'rw';

    use overload '""' => sub { return "(" . join(" " , @{$_[0]->items}) . ")" };

    sub validate { 
        my ($self) = @_;
        my @items = @{$self->items};
        my $op = shift @items;
        if ($op->isa('Msm::AST::Identifier')) {
            my $opval = $op->val;
            given ($opval) {
                when ('let') {
                    die "let must have at least 2 arguments" unless scalar @items >= 2;
                    my $bindings = $items[0];
                    die "1st arg to let must be a sexp" unless $bindings->isa('Msm::AST::Sexp');
                    foreach my $binding (@{$bindings->items}) {
                        die "All bindings must be sexps" unless $binding->isa('Msm::AST::Sexp');
                        die "All bindings must be sexps with 2 items"
                            unless scalar @{$binding->items} == 2;
                        die "Each binding must begin with an identifier: " . ref $binding->items->[0]
                            unless $binding->items->[0]->isa('Msm::AST::Identifier');
                    }

                }
                when ('if') {
                    die "if requires 3 args" unless scalar @items == 3;
                }
                when ('eq?')    {
                    die "eq? requires 2 args" unless scalar @items == 2;
                }
            }
        }
    }
}
{
    package Msm::AST::Program;
    use Moose;
    has 'sexps', is => 'rw';

    use overload '""' => sub { return join("\n" , @{$_[0]->sexps}); };

    sub validate {
        my ($self) = @_;
        $_->validate for @{$self->sexps};
    }
}

1;

1;
