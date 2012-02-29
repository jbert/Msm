#!/usr/bin/perl
use Modern::Perl;
use Msm::Parser;

#my $prog = '(+ 2 3)';
#my $prog = '(lambda () (begin (+ 1 11) (- 10 10))';
my $prog = '(+ (+ 1 2) (- 2 3))';
#my $prog = '(lambda () (begin (+ 1 11) (- 10 10)))';

my $parser = Msm::Parser->parser;
my $parse_tree = $parser->program($prog);

use Data::Dumper;
say "Parse tree is: " . Data::Dumper::Dumper($parse_tree);
