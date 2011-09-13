use strict;
use warnings;

use Test::More tests => 1;
use Unicorn::Manager::Proc;

my $uni_proc = Unicorn::Manager::Proc->new;

isa_ok $uni_proc, 'Unicorn::Manager::Proc';

