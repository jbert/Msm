#!/usr/bin/perl
use lib ('t', '../t');
use Msm::Test::Data;
use Test::More tests => 6 * scalar Msm::Test::Data->progs;
use Msm;
use Msm::Toc;
use Modern::Perl;
use File::Temp qw(tempfile);

foreach my $prog (Msm::Test::Data->progs) {
    test_prog($prog);
}
exit 0;

sub test_prog {
    my ($prog) = @_;

    my $parser = Msm::Parser->parser;
    my $ast = $parser->program($prog);

    my $c_code = $ast->to_c;
    ok($c_code, "got some code");
    my ($c_fh, $c_file) = tempfile('/tmp/tocXXXX', SUFFIX => '.c', UNLINK => 1);
    print $c_fh $c_code;
    close $c_fh or die "can't close c fh $c_file : $!";

    my ($exe_fh, $exe_file) = tempfile('/tmp/tocXXXX', UNLINK => 1);
    close $exe_fh;
    ok(compile_c($c_file, $exe_file), "can compile c file [$c_file] to exe [$exe_file]");
    ok(-f $exe_file, "exe file $exe_file exists");
    ok(-s $exe_file, "and is $exe_file non-zero");

    my $result = `$exe_file`;
    ok(defined $result, "got a result");
    chomp $result;

    my $expected = mzscheme_eval($prog);
    is($result, $expected, "prog [$prog] evals same as mzscheme");
}

sub compile_c {
    my ($c_file, $exe_file) = @_;
    my $rc = system("gcc $c_file -o $exe_file");
    return $rc == 0;
}

sub mzscheme_eval {
    my ($prog) = @_;
    my ($result) = `mzscheme -e '$prog'`;
    chomp $result;
    return $result;
}

