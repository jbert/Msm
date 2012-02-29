#!/usr/bin/perl
use Modern::Perl;
use Msm;
use Msm::Evaluator;

#my $prog = '(+ 2 3)';
#my $prog = '(lambda () (begin (+ 1 11) (- 10 10))';
my $prog = '(+ (+ 1 2) (- 2 3))';
#my $prog = '(lambda () (begin (+ 1 11) (- 10 10)))';

my $parser = Msm::Parser->parser;
my $ast = $parser->sexp($prog);

use Data::Dumper;
say "Parse tree is: " . Data::Dumper::Dumper($ast);

my $evaluator = Msm::Evaluator->new;
my $result = $ast->eval;

say "Eval result is $result";
$result = mzscheme_eval($prog);
say "Mzscheme result is $result";

sub mzscheme_eval {
    my ($prog) = @_;
    my ($result) = `mzscheme -e '$prog'`;
    chomp $result;
    return $result;
}
