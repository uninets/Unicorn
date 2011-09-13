use strict;
use warnings;

use Test::More;
use Unicorn::Manager::Proc;

my $u_p_table = Unicorn::Manager::Proc::Table->new;

isa_ok $u_p_table, 'Unicorn::Manager::Proc::Table';

done_testing;
