#!perl

use 5.012;
use warnings;

use Test::More;                      # last test to print

my $unicorn = qx'which unicorn';
chomp $unicorn;
my $unicorn_rails = qx'which unicorn_rails';
chomp $unicorn_rails;

ok $unicorn, "unicorn is in your \$PATH ($unicorn)";
ok $unicorn_rails, "unicorn is in your \$PATH ($unicorn_rails)";

done_testing;
