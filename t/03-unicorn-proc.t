use strict;
use warnings;

use Test::More tests => 1;
use Unicorn::Proc;

my $uni_proc = Unicorn::Proc->new;

isa_ok $uni_proc, 'Unicorn::Proc';

