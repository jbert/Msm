#!/usr/bin/perl
use Modern::Perl;
use Msm;

#my $prog = '(+ 2 3)';
#my $prog = '(lambda () (begin (+ 1 11) (- 10 10))';
my $prog = '(+ (+ 1 2) (- 2 3))';
#my $prog = '(lambda () (begin (+ 1 11) (- 10 10)))';

my $parser = Msm->parser;
my $result = $parser->program($prog);

use Data::Dumper;
say "Result is: " . Data::Dumper::Dumper($result);
