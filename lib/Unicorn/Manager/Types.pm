package Unicorn::Manager::Types;

use Moo;
use 5.010;

sub hashref {
    return sub {
        die "Failed type constraint. Should be a HashRef but is a " . ref( $_[0] )
            if ref( $_[0] ) ne 'HASH';
        }
}

1;

__END__

=head1 NAME

Unicorn::Manager::Types - Types to be used by Unicorn

=head1 VERSION

Version 0.006000

=head1 SYNOPSIS

Types used within Unicorn::Manager classes.

=head1 TYPES

=head2 hashref

Attribute has to be a reference to a hash.

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

