package Msm;
use Parse::RecDescent;

my $grammar = <<'EOG';

program: sexp(s?)
    { $item[1]; }

sexp: '(' operator item(s?) ')'
    { [ $item[2], @{$item[3]} ] }

item: integer | sexp
    { $item[1]; }

integer: m{\d+}
    { [@item[0..$#item]] }

operator: m{[a-z\d_+\-*/]+}
    { [@item[0..$#item]] }

EOG

$::RD_ERRORS=1;
#$::RD_WARN=1;
my $PARSER;
sub parser {
    $PARSER //= Parse::RecDescent->new($grammar);
    return $PARSER;
}

1;
