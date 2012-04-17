package Msm::Parser;
use Parse::RecDescent;
use Msm::AST;

my $grammar = <<'EOG';

program: sexp(s?)
    { Msm::AST::Program->new({exps => $item[1]}) }

sexp: '(' operator item(s?) ')'
    { Msm::AST::Expression->new({op => $item[2], args => $item[3]})  }

item: integer | boolean | sexp
    { $item[1]; }

boolean: m{^#[tf]}
    { Msm::AST::Boolean->new({val => $item[1]}) }

integer: m{[+-]?\d+}
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
