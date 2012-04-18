package Msm::Parser;
use Parse::RecDescent;
use Msm::AST;

my $grammar = <<'EOG';

program: sexp(s?)
    { Msm::AST::Program->new({sexps => $item[1]}) }

sexp: '(' item(s?) ')'
    { Msm::AST::Sexp->new({items => $item[2]})  }

item: atom | sexp

atom: integer | boolean | identifier
    { $item[1]; }

identifier: m{[a-z\d_+\-*/?]+}
    { Msm::AST::Identifier->new({val => $item[1]}) }

boolean: m{^#[tf]}
    { Msm::AST::Boolean->new({val => $item[1]}) }

integer: m{[+-]?\d+}
    { Msm::AST::Integer->new({val => $item[1]}) }

EOG

$::RD_ERRORS=1;
#$::RD_WARN=1;
my $PARSER;
sub parser {
    $PARSER //= Parse::RecDescent->new($grammar);
    return $PARSER;
}

1;
