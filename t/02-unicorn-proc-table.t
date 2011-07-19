use strict;
use warnings;

use Test::More;
use Unicorn::Proc;

my $u_p_table = Unicorn::Proc::Table->new;

isa_ok $u_p_table, 'Unicorn::Proc::Table';

done_testing;
