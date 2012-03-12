#!/usr/bin/perl

use 5.010;
use warnings;
use Getopt::Long qw(:config pass_through);

use Unicorn::Manager::Server;

my $HELP = <<"END";
Synopsis
    $0 [options]

Options
    -u, --user
        username of unicorns owner (can be ommited if user is not root)
    -p, --port
        port to listen on

END

my $user;
my $port;

my $result = GetOptions(
    'user|u=s'   => \$user,
    'port|p=s' => \$port,
);

my $server = Unicorn::Manager::Server->new(
    user => $user,
);

$server->run();

