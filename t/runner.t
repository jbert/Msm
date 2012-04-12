#!/usr/bin/perl
use Modern::Perl;
my (@engine_types, @progs);
BEGIN {
#    @engine_types = qw(Asm);
    @engine_types = qw(Asm Evaluator Toc);
    @engine_types = ($ENV{MSM_TEST_ENGINE}) if $ENV{MSM_TEST_ENGINE};

    @progs = (
        '(+ 2 3)',
        '(+ (+ 1 2) (- 2 3))',
        '(- 6 1 1 1 1 1 1 1 1 1 1 1 1)',
        '(- 6 1 0 1 0 1 0 1 0 1 0 1 0)',

        '(- 0)',
        '(- 0 0)',
        '(+ 0 0)',
        '(+ 0)',

        '(+ 1 -1)',
        '(+ +1 -1)',
        '(+ -1 -1)',
        '(- +1 -1)',

        '(* 2 3)',
    );
    @progs = ($ENV{MSM_TEST_PROG}) if $ENV{MSM_TEST_PROG};
}

use lib ('t', '../t');
use Test::More tests => 2 * scalar(@engine_types) * scalar @progs;
use Msm::Runner;
use Msm::Parser;
use File::Temp qw(tempfile);

#foreach my $engine_type (qw(Toc Eval)) {
foreach my $engine_type (@engine_types) {
    my $runner = Msm::Runner->new(engine_type => $engine_type);
    foreach my $prog (@progs) {
        test_prog($prog, $runner);
    }
}
exit 0;

sub test_prog {
    my ($prog, $runner) = @_;

    my $parser = Msm::Parser->parser;
    note("Prog: $prog");
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

