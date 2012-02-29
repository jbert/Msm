package Msm::Parser;
use Parse::RecDescent;
use Msm::AST;

my $grammar = <<'EOG';

program: sexp(s?)
    { $item[1]; }

sexp: '(' operator item(s?) ')'
    { Msm::AST::Expression->new({op => $item[2], vals => $item[3]})  }

item: integer | sexp
    { $item[1]; }

integer: m{\d+}
    { Msm::AST::Integer->new({val => $item[1]}) }

operator: m{[a-z\d_+\-*/]+}
    { Msm::AST::Operator->new({val => $item[1]}) }

EOG

$::RD_ERRORS=1;
#$::RD_WARN=1;
my $PARSER;
sub parser {
    $PARSER //= Parse::RecDescent->new($grammar);
    return $PARSER;
}

1;