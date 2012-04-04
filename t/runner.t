#!/usr/bin/perl
my @engine_types;
BEGIN {
    @engine_types = qw(Evaluator Toc);
}

use lib ('t', '../t');
use Msm::Test::Data;
use Test::More tests => 2 * scalar(@engine_types) * scalar Msm::Test::Data->progs;
use Msm::Runner;
use Msm::Parser;
use Modern::Perl;
use File::Temp qw(tempfile);

#foreach my $engine_type (qw(Toc Eval)) {
foreach my $engine_type (@engine_types) {
    my $runner = Msm::Runner->new(engine_type => $engine_type);
    foreach my $prog (Msm::Test::Data->progs) {
        test_prog($prog, $runner);
    }
}
exit 0;

sub test_prog {
    my ($prog, $runner) = @_;

    my $parser = Msm::Parser->parser;
    my $ast = $parser->program($prog);

    my $result = $runner->run_ast($ast);

    ok(defined $result, "got a result");

    my $expected = mzscheme_eval($prog);
    is($result, $expected, "prog [$prog] evals same as mzscheme");
}

sub mzscheme_eval {
    my ($prog) = @_;
    my ($result) = `mzscheme -e '$prog'`;
    chomp $result;
    return $result;
}

