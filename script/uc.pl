#!/usr/bin/perl

use strict;
use warnings;
use v5.0010;
use Getopt::Long;

use Unicorn;

my $HELP = <<'END';
Synopsis
    unicorn.pl [options]

Options
    -u, --user
        username of unicorns owner
    -a, --action
        action to perform, see section Actions for valid actions
    -c, --config
        path to the unicorn config file
    --args
        optional additional arguments used with action 'start'
        overrides options of the config file
        see section Examples for proper usage
        "-D" is an additional argument you most likely want to provide
    --debug
        flag to enable debug output

Actions
    show
        dumps a YAML structure of user ids and the process ids of masters
        and their children
    start
        starts a users unicorn server, requires --config to be specified
    stop
        stops unicorn
    restart
        gracefully restarts unicorn
    reload
        reload unicorn
    add_worker
        adds a unicorn worker
    rm_worker
        removes a unicorn worker

Examples
    unicorn.pl -a show
    unicorn.pl -u railsuser -a start -c /home/railsuser/app/unicorn.rb --args "--listen 0.0.0.0:80, -D"
    unicorn.pl -u railsuser -a restart --debug
    unicorn.pl -u railsuser -a add_worker

END

my $action;
my $user;
my $config;
my $args;
my $DEBUG = 0;

my $result = GetOptions(
    'action|a=s' => \$action,
    'user|u=s'   => \$user,
    'config|c=s' => \$config,
    'args=s'     => \$args,
    'debug'      => \$DEBUG,
);

if ($action eq 'show'){
    my $uc = Unicorn->new(
        username => 'nobody',
        DEBUG => $DEBUG,
    );

    my $uidref = $uc->proc->process_table->ptable;

    for (keys %{$uidref}){
        my $username = getpwuid $_;
        my $pidref = $uidref->{$_};

        print "$username:\n";

        for my $master (keys %{$pidref}){
            print "    master: $master\n";
            for my $worker (@{$pidref->{$master}}){
                if (ref($worker) ~~ 'HASH'){
                    for (keys %$worker){
                        print "        new master: " . $_ . "\n";
                        print "            new worker: $_\n" for @{$worker->{$_}}
                    }
                }
                else {
                    print "        worker: $worker\n";
                }
            }
        }
    }

    exit 0;
}

if ($> > 0){
    $user = getpwuid $> unless $user;
}

unless ( $user && $action ) {
    print $HELP;
    die "Missing arguments. username and action are required\n";
}

my $arg_ref = [];

$arg_ref = [ split ',', $args ] if $args;

my $unicorn = Unicorn->new(
    username => $user,
    DEBUG    => $DEBUG,
);

if ( $action eq 'start' ) {
    unless ($config) {
        print $HELP;
        die "Action 'start' requires a config file.\n";
    }
    if ($DEBUG) {
        print "\$unicorn->start( config => \$config, args => \$arg_ref )\n";
        print " -> \$config => $config\n";
        use Data::Dumper;
        print " -> \$arg_ref => " . Dumper($arg_ref);
    }
    $unicorn->start( config => $config, args => $arg_ref );
}
elsif ( $action eq 'stop' ) {
    print "\$unicorn->stop()\n" if $DEBUG;
    $unicorn->stop();

}
elsif ( $action eq 'restart' ) {
    print "\$unicorn->restart( mode => 'graceful' )\n" if $DEBUG;
    $unicorn->restart( mode => 'graceful' );
}
elsif ( $action eq 'reload' ) {
    print "\$unicorn->reload()\n" if $DEBUG;
    $unicorn->reload();
}
elsif ( $action eq 'add_worker' ) {
    print "\$unicorn->add_worker( num => 1 )\n" if $DEBUG;
    $unicorn->add_worker( num => 1 );
}
elsif ( $action eq 'rm_worker' ) {
    print "\$unicorn->remove_worker( num => 1 )\n" if $DEBUG;
    $unicorn->remove_worker( num => 1 );
}
else {
    die "No such action\n";
}

exit 0;

