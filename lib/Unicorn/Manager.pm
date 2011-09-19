use MooseX::Declare;

class Unicorn::Manager {

    use Carp;           # for sane error reporting
    use File::Basename; # to strip the config file from the path

    our $VERSION = '0.03.03';

    use Unicorn::Manager::Proc;

    has username => ( is => 'rw', isa => 'Str', required => 1 );
    has group    => ( is => 'rw', isa => 'Str' );
    has config   => ( is => 'rw', isa => 'HashRef' );
    has DEBUG    => ( is => 'rw', isa => 'Bool', default => 0 );
    has proc     => ( is => 'rw', isa => 'Unicorn::Manager::Proc' );
    has uid      => ( is => 'rw', isa => 'Num' );
    has rails    => ( is => 'rw', isa => 'Bool', default => 0 );

    method start ( Str :config($config_file), ArrayRef :$args? ) {
        my $timeout = 20;
        if ( -f $config_file ){
            if (my $pid = fork()){
                my $spawned = 0;
                while ( $spawned == 0 && $timeout > 0 ){
                    sleep 2;
                    $self->proc->refresh;
                    $spawned = 1 if $self->proc->process_table->ptable->{$self->uid};
                    $timeout--;
                }
                croak "Failed to start unicorn. Timed out.\n" if $timeout <= 0;

            }
            else {
                # 0 => name
                # 2 => uid
                # 3 => gid
                # 7 => home dir
                my @passwd = getpwnam($self->username);

                # drop rights:
                # group rights first because we can not drop group rights
                # after user rights
                # set $HOME to our users home directory
                $ENV{'HOME'} = $passwd[7];
                $( = $) = $passwd[3];
                $< = $> = $passwd[2];

                my $appdir = '';
                my $conf_file;
                my $conf_dir;

                if ( defined $config_file && $config_file ne '' ){
                    $conf_dir = dirname($config_file);
                    $conf_file = basename($config_file);

                    if ( $self->_is_abspath($conf_dir) ){
                        $appdir = $conf_dir;
                    }
                    else {
                        $appdir = $passwd[7] . '/' . $conf_dir;
                    }
                }

                $self->_change_dir ( $appdir );

                my $argstring;

                $argstring .= $_ . ' ' for @{ $args };

                # dirty hack. remove this!
                $ENV{'RAILS_ENV'} = 'production';

                # spawn the unicorn
                if ($self->rails){
                    # start unicorn_rails
                    exec "/bin/bash --login -c \"unicorn_rails -c $conf_file $argstring\"";
                }
                else {
                    # start unicorn
                    exec "/bin/bash --login -c \"unicorn -c $conf_file $argstring\"";
                }
            }
        }
        else {
            return 0;
        }
        return 1;
    }

    method stop {
        my $master = ( keys %{ $self->proc->process_table->ptable->{$self->uid} } )[0];

        $self->_send_signal('QUIT', $master) if $master;

        return 1;
    }

    method restart ( Str :$mode? = 'graceful' ) {

        my @signals = ( 'USR2', 'WINCH', 'QUIT');
        my $master = ( keys %{ $self->proc->process_table->ptable->{$self->uid} } )[0];

        my $err = 0;

        for (@signals){
            $err += $self->_send_signal ($_, $master);
            sleep 5;
        }

        if ( (defined $mode && $mode eq 'hard') || $err ){
            $err = 0;
            $err += $self->stop;
            sleep 3;
            $err += $self->start;
        }

        if ($err){
            carp "error restarting unicorn! error code: $err\n";
            return 0;
        }
        else {
            return 1;
        }
    }

    method reload {
        my $err;

        for my $pid (keys %{ $self->proc->process_table->ptable->{$self->uid} }){
            $err = $self->_send_signal( 'HUP', $pid );
        }

        $err > 0 ? return 0 : return 1;
    }

    method read_config ( Str $filename ) {
        # TODO
        # should return a config object
        #
        # all config related stuff should go into a seperate class anyway: Unicorn::Manager::Config
        return 0;
    }

    method write_config ( Str $filename ) {
        # TODO
        # this one wont be fun ..
        # create a unicorn.conf from config hash
        # this is basically ruby code, so an idea could be to build it from
        # heredoc snippets
        #
        # should return a string. could be written to file or screen.
        #
        # all config related stuff should go into a seperate class anyway: Unicorn::Manager::Config
        return 0;
    }

    method add_worker ( Num :$num? = 1 ) {
        # return error on non positive number
        return 0 unless $num > 0;

        my $err = 0;

        for ( 1 .. $num ){
            my $master = ( keys %{ $self->proc->process_table->ptable->{$self->uid} } )[0];

            $err += $self->_send_signal( 'TTIN', $master );
        }

        $err > 0 ? return 0 : return 1;
    }

    method remove_worker ( Num :$num? = 1 ){
        # return error on non positive number
        return 0 unless $num > 0;

        my $err = 0;
        my $master = ( keys %{ $self->proc->process_table->ptable->{$self->uid} } )[0];
        my $count = @{ $self->proc->process_table->ptable->{$self->uid}->{$master} };

        # save at least one worker
        $num = $count - 1 if $num >= $count;

        if ($self->DEBUG){
            print "\$count => $count\n";
            print "\$num   => $num\n";
        }

        for ( 1 .. $num ){
            $err += $self->_send_signal( 'TTOU', $master );
        }

        $err > 0 ? return 0 : return 1;
    }

    #
    # send a signal to a pid
    #
    method _send_signal (Str $signal!, Num $pid!) {
        (kill $signal => $pid) ? return 0 : return 1;
    }

    #
    # small piece to check if a path is starting at root
    #
    method _is_abspath ( Str $path! ) {
        return 0 unless $path =~ /^\//;
        return 1;
    }

    #
    # cd into the given dir
    # requires an absolute path
    #
    method _change_dir ( Str $dir! ) {

        # requires abs path
        return 0 unless $self->_is_abspath($dir);

        my $dh;

        opendir $dh, $dir;
        chdir $dh;
        closedir $dh;

        use Cwd;

        cwd() eq $dir ? return 1 : return 0;
    }

    method BUILD {
        # does username exist?
        if ($self->DEBUG){
            print "Initializing object with username: " . $self->username . "\n";
        }
        croak "no such username\n" unless getpwnam($self->username);

        $self->uid((getpwnam($self->username))[2]);
        $self->proc(Unicorn::Manager::Proc->new) unless $self->proc;

    }
}


=head1 NAME

Unicorn::Manager - A Perl interface to the Unicorn webserver

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

The Unicorn::Manager module aimes to provide methods to start, stop and
gracefully restart the server. You can add and remove workers on the fly.

TODO:
Unicorn::Manager::Config should provide methods to create config files and
offer an OO interface to the config object.

Until now basically only unicorn_rails is supported. This Lib is a quick hack
to integrate management of rails apps with rvm and unicorn into perl scripts.

Also some assumption are made about your environment:
    you use Linux (the module relies on /proc)
    you use the bash shell
    your unicorn config is located in your apps root directory
    every user is running one single application

I will add and improve what is needed though. Requests and patches are
welcome.

=head1 ATTRIBUTES/CONSTRUCTION

Unicorn::Manager has following attributes:

=head2 username

Username of the user that owns the Unicorn process that will be operated
on.

The username is a required attribute.

=head2 group

Groupname of the Unicorn process. Defaults to the users primary group.

=head2 config

A HashRef containing the information to create a Unicorn::Config object.
See perldoc Unicon::Config for more information.

=head2 DEBUG

Is a Bool type attribute. Defaults to 'false' and prints additional
information if set 'true'.

TODO: Needs to be improved.

=head2 Contruction

    my $unicorn = Unicorn->new(
        username => 'myuser',
        group    => 'mygroup',
    );

=head1 METHODS

=head2 start

    $unicorn->start(
        config => '/path/to/my/config',
        args => ['-D', '--host 127.0.0.1'],
    );

Parameters are the path to the config file and an optional ArrayRef with
additional arguments.
These will override the arguments defined in the config file.

This method needs more love and will be rethought and rewritten. Now it
assumes the config file is located in the rails apps root directory. It
changes into this directory and drops rights to start unicorn.

=head2 stop

    $unicorn->stop;

Sends SIGQUIT to the unicorn master. This will gracefully shut down the
workers and then quit the master.

If graceful stop will not work SIGKILL will be send.

If no master is running nothing will be happening.

=head2 restart

    my $result = $unicorn->restart( mode => 'hard');

Mode defaults to 'graceful'.

If mode is set 'hard' graceful restart will be tried first and
$unicorn->stop plus $unicorn->start if that fails.

returns true on success, false on error.

=head2 reload

    my $result = $unicorn->reload;

Reloads the users unicorn. Reloads the config file. Code changes are
reloaded unless app_preload is set.

Basically a SIGHUP will be send to the unicorn master.

=head2 read_config

NOT YET IMPLEMENTED

    $unicorn->read_config('/path/to/config');

Reads the configuration from a unicorn config file.

=head2 write_config

NOT YET IMPLEMENTED

    $unicorn->make_config('/path/to/config');

Writes the configuration into a unicorn config file.

=head2 add_worker

    my $result = $unicorn->add_worker( num => 3 );

Adds num workers to the users unicorn. num defaults to 1.

=head2 remove_worker

    my $result = $unicorn->remove_worker( num => 3 );

Removes num workers but maximum of workers count -1. num defaults to 1.

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Unicorn::Manager issue tracker

L<https://github.com/mugenken/Unicorn/issues>

=item * support at uninets.eu

C<< <mugen.kenichi at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <mugen.kenichi at uninets.eu> >>

=back

=cut

