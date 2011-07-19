use strict;
use warnings;

use Test::More tests => 2;
use Unicorn::Proc;

my $u_p_table = Unicorn::Proc::Table->new;

isa_ok $u_p_table, 'Unicorn::Proc::Table';

