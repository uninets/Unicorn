#!/usr/bin/perl

use 5.010;
use warnings;
use Getopt::Long;

use Unicorn::Manager;

my $HELP = <<"END";
Synopsis
    $0 [action] [options]

Actions
    help
        show this help
    show
        dumps a structure of user ids and the process ids of masters
        and their children
    json
        dumps a structure of user names and the process ids of masters
        and their children as json
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
    version
        print Unicorn::Manager version

Options
    -u, --user
        username of unicorns owner (can be ommited if user is not root)
    -c, --config
        path to the unicorn config file
    --args
        optional additional arguments used with action 'start'
        overrides options of the config file
        see section Examples for proper usage
        "-D" is an additional argument you most likely want to provide
    --debug
        flag to enable debug output
    --rails
        defaults to 1 for now. so it has no effect at all

Examples
    uc.pl show
    uc.pl start -u railsuser -c /home/railsuser/app/unicorn.rb --args "--listen 0.0.0.0:80, -D"
    uc.pl restart -u railsuser
    uc.pl add_worker

END

my $action = shift || 'help';
my $user;
my $config;
my $args = undef;
my $DEBUG = 0;
my $rails = 1;

my $result = GetOptions(
    'user|u=s'   => \$user,
    'config|c=s' => \$config,
    'args=s'     => \$args,
    'debug'      => \$DEBUG,
    'rails'      => \$rails,
);

if ($> > 0){
    $user = getpwuid $> unless $user;
}
else {
    $user = 'nobody' unless $user;
}

unless ( $user && $action ) {
    print $HELP;
    die "Missing arguments. username and action are required\n";
}

my $arg_ref = [];

# make -D default as most of the time you will want to start Unicorn as daemon
$args = "-D" unless defined $args;

$arg_ref = [ split ',', $args ] if $args;

my $unicorn = sub {
    return Unicorn::Manager->new(
        username => $user,
        rails    => $rails,
        DEBUG    => $DEBUG,
    );
};

my $dispatch_table = {
    help => sub {
        say $HELP;
        exit 0;
    },
    json => sub {
        my $uc = Unicorn::Manager->new(
            username => 'nobody',
            DEBUG => $DEBUG,
        );

        print $uc->proc->as_json;

        exit 0;
    },
    show => sub {
        my $uc = Unicorn::Manager->new(
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
    },
    start => sub {
        unless ($config) {
            print $HELP;
            die "Action 'start' requires a config file.\n";
        }
        if ($DEBUG) {
            say "\$unicorn->start( config => \$config, args => \$arg_ref )";
            say " -> \$config => $config";
            use Data::Dumper;
            say " -> \$arg_ref => " . Dumper($arg_ref);
        }
        $unicorn->()->start({config => $config, args => $arg_ref});
    },
    stop => sub {
        $unicorn->()->stop;
    },
    restart => sub {
        $unicorn->()->restart({ mode => 'graceful' });
    },
    reload => sub {
        $unicorn->()->reload;
    },
    add_worker => sub {
        $unicorn->()->add_worker({ num => 1 });
    },
    rm_worker => sub {
        $unicorn->()->remove_worker({ num => 1 });
    },
    version => sub {
        say Unicorn::Manager::Version->get;
    },
    query => sub {
        say 'yes' if $unicorn->()->query('has_unicorn', 'a_user');
    },
};

if (exists $dispatch_table->{$action}){
    $dispatch_table->{$action}->();
}
else {
    say "No action $action defined";
}

exit 0;

