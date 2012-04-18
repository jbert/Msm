package Msm::AST;
{
    package Msm::AST::Node;
    use Moose;

}
{
    package Msm::AST::Atom;
    use Moose;
    extends 'Msm::AST::Node';
    has 'val', is => 'rw';

    sub eq {
        my ($self, $other) = @_;
        return unless ref $other eq ref $self;      # Must be same type
        return unless $other->val eq $self->val;    # Must be same val
        return 1;                                   # All ok
    }
}
{
    package Msm::AST::Boolean;
    use Moose;
    extends 'Msm::AST::Atom';
}
{
    package Msm::AST::Integer;
    use Moose;
    extends 'Msm::AST::Atom';
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
}
{
    package Msm::AST::Program;
    use Moose;
    has 'sexps', is => 'rw';
}

1;

1;
