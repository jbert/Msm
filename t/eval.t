#!/usr/bin/perl
use Test::More tests => 1;
use Msm;
use Msm::Evaluator;

#my $prog = '(+ 2 3)';
#my $prog = '(lambda () (begin (+ 1 11) (- 10 10))';
my $prog = '(+ (+ 1 2) (- 2 3))';
#my $prog = '(lambda () (begin (+ 1 11) (- 10 10)))';

my $parser = Msm::Parser->parser;
my $ast = $parser->sexp($prog);

my $evaluator = Msm::Evaluator->new;
my $result = $ast->eval;

my $expected = mzscheme_eval($prog);
is($result, $expected, "prog [$prog] evals same as mzscheme");

sub mzscheme_eval {
    my ($prog) = @_;
    my ($result) = `mzscheme -e '$prog'`;
    chomp $result;
    return $result;
}
