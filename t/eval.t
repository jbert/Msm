#!/usr/bin/perl
use lib ('t', '../t');
use Msm::Test::Data;
use Test::More tests => scalar Msm::Test::Data->progs;
use Msm;
use Msm::Evaluator;
use Modern::Perl;

foreach my $prog (Msm::Test::Data->progs) {
    test_prog($prog);
}
exit 0;

sub test_prog {
    my ($prog) = @_;

    my $parser = Msm::Parser->parser;
    my $ast = $parser->program($prog);

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
