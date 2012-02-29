#!/usr/bin/perl
my @progs;
BEGIN {
    @progs = (
            '(+ 2 3)',
            '(+ (+ 1 2) (- 2 3))',
            '(- 6 1 1 1 1 1 1 1 1 1 1 1 1)',
            '(- 6 1 0 1 0 1 0 1 0 1 0 1 0)',

            '(* 2 3)',
        );
}

use Test::More tests => scalar @progs;
use Msm;
use Msm::Evaluator;

foreach my $prog (@progs) {
    test_prog($prog);
}
exit 0;

sub test_prog {
    my ($prog) = @_;

    my $parser = Msm::Parser->parser;
    my $ast = $parser->sexp($prog);

    my $evaluator = Msm::Evaluator->new;
    my $result = $ast->eval;

    my $expected = mzscheme_eval($prog);
    is($result, $expected, "prog [$prog] evals same as mzscheme");
}

sub mzscheme_eval {
    my ($prog) = @_;
    my ($result) = `mzscheme -e '$prog'`;
    chomp $result;
    return $result;
}
