#!perl -T

use strict;
use warnings;

use Test::More tests => 12;
use Test::Moose;

my @methods = ( 'start', 'stop', 'restart', 'read_config', 'write_config' );
my @attributes = ( 'username', 'group', 'config', 'DEBUG' );

BEGIN {
    use_ok 'Unicorn';
}

ok ( my $unicorn = Unicorn->new( username => 'nobody' ));

isa_ok ( $unicorn, 'Unicorn' );

for (@attributes){
    has_attribute_ok ( $unicorn, $_ );
}

for (@methods){
    can_ok ( $unicorn, $_ );
}

