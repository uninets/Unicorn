package Unicorn::Manager::Server;

use 5.010;
use feature 'say';
use strict;
use warnings;
use autodie;
use Moo;
use IO::Socket;
use Net::Server::NonBlocking;
use Unicorn::Manager::CLI;

has listen => ( is => 'rw', default => sub { return 'localhost' } );
has port   => ( is => 'rw', default => sub { return 4242 } );
has user   => ( is => 'rw', default => sub { return 'nobody' } );
has group  => ( is => 'rw', default => sub { return 'nobody' } );
has server => ( is => 'rw' );
has cli    => ( is => 'rw' );

sub BUILD {
    my $self = shift;

    my $server = Net::Server::NonBlocking->new();

    $self->server($server) unless $self->server;
    $self->cli( Unicorn::Manager::CLI->new( username => $self->user ) ) unless $self->cli;

}

sub run {
    my ($self) = @_;

    $self->server->add(
        {
            server_name  => 'ucd.pl',
            local_port   => $self->port,
            timeout      => 10,
            delimiter    => "\n",
            on_connected => sub {
                my $self   = shift;
                my $client = shift;

                print $client "welcome to ucd.pl\n";
            },
            on_disconnected => sub {
                my $self   = shift;
                my $client = shift;

                print $client "bye\n";
            },
            on_recv_msg => sub {
                my $this    = shift;
                my $client  = shift;
                my @params  = @_;

                if ($params[0] ~~ /exit/){
                    $this->erase_client( 'ucd.pl', $client ) if $params[0] ~~ /exit/;
                    return 1;
                }

                # for telnet compatibility
                ($_ = $_) =~ s/\r// for @params;

                print $client $self->cli->query(@params)
            },
        }
    );

    $self->server->start;
}

1;

__END__

=head1 NAME

Unicorn::Manager::Server - A Perl interface to the Unicorn webserver

=head1 WARNING!

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.006000

=head1 SYNOPSIS

The Unicorn::Manager::Server module provides a json interface to query information about running unicorn processes and users.

Also some assumption are made about your environment:
    you use Linux (the module relies on /proc)
    you use the bash shell
    your unicorn config is located in your apps root directory
    every user is running one single application

I will add and improve what is needed though. Requests and patches are
welcome.

=head1 ATTRIBUTES/CONSTRUCTION

=head2 listen

Address to listen on. Defaults to localhost.

=head2 port

Port to bind to.

=head2 user

Username to use for Unicorn::Manager::CLI instances.

=head2 group

Not in use yet.

=head2 server

A Net::Server::NonBlocking instance. Will be created automatically unless provided in construction.

=head2 cli

A Unicorn::Manager::CLI instance. Will be created automatically unless provided in construction.

=head1 METHODS

=head2 run

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Unicorn::Manager::CLI issue tracker

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
