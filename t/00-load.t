#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Msm' ) || print "Bail out!\n";
}

diag( "Testing Msm $Msm::VERSION, Perl $], $^X" );
