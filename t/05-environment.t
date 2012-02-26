#!perl

use 5.010;
use warnings;

use Test::More;                      # last test to print

my $unicorn;
my $unicorn_rails;

if (-x 'unicorn' && -x 'unicorn_rails'){
    $unicorn = qx'which unicorn';
    chomp $unicorn;
    $unicorn_rails = qx'which unicorn_rails';
    chomp $unicorn_rails;
}

SKIP: {
    skip 'unicorn seems not to be installed. run `gem install unicorn` or fix yout $PATH', 1
        unless ($unicorn && $unicorn_rails);

    ok $unicorn, "unicorn is in your \$PATH ($unicorn)";
    ok $unicorn_rails, "unicorn is in your \$PATH ($unicorn_rails)";
}

done_testing;
