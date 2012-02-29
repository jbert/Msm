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
}
{
    package Msm::AST::Integer;
    use Moose;
    extends 'Msm::AST::Atom';
}
{
    package Msm::AST::Operator;
    use Moose;
    extends 'Msm::AST::Atom';
}
{
    package Msm::AST::Expression;
    use Moose;
    extends 'Msm::AST::Node';
    has 'op', is => 'rw';
    has 'args', is => 'rw';
}

1;
