use Test::More tests => 1;

BEGIN {
    use_ok( 'Unicorn::Manager' ) || print "Bail out!";
}

diag( "Testing Unicorn::Manager $Unicorn::Manager::VERSION, Perl $], $^X" );
