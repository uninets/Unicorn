use Test::More;

BEGIN {
    use_ok( 'Unicorn::Manager' ) || print "Bail out!";
    use_ok( 'Unicorn::Manager::Version' || print "No version information!" );
}

my $v = Unicorn::Manager::Version->new;

diag( 'Testing Unicorn::Manager ' . $v->get . ", Perl $], $^X" );

done_testing;
