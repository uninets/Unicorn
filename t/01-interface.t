use strict;
use warnings;

use Test::More tests => 12;

my @methods = ( 'start', 'stop', 'restart', 'read_config', 'write_config' );
my @attributes = ( 'username', 'group', 'config', 'DEBUG' );

BEGIN {
    use_ok 'Unicorn::Manager';
}

ok ( my $unicorn = Unicorn::Manager->new( username => 'nobody' ));

isa_ok ( $unicorn, 'Unicorn::Manager' );

for (@attributes){
    can_ok ( $unicorn, $_ );
}

for (@methods){
    can_ok ( $unicorn, $_ );
}

