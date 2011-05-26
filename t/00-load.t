#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Unicorn' ) || print "Bail out!";
}

diag( "Testing Unicorn $Unicorn::VERSION, Perl $], $^X" );
