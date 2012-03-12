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

    $self->server($server);
    $self->cli( Unicorn::Manager::CLI->new( username => $self->user ) );

}

sub run {
    my ($self) = @_;

    $self->server->add(
        {
            server_name  => 'ucd.pl',
            local_port   => $self->port,
            timeout      => 10,
            delimiter    => "\r\n",
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

                chomp for @params;
                say for @params;

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

=head1 WARNING

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.006000

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
