use MooseX::Declare;

class Unicorn::Manager::Types {

    use Moose::Util::TypeConstraints;

    subtype 'AbsPath'
        => as 'Str'
        => where { $_ ~~ /^(?:\/[^\0^\/]+)+\/?/ }
        => message { 'Argument is no valid absolute Unix path.' };

}

=head1 NAME

Unicorn::Manager::Types - Types inherited of MooseX::Types to be used by Unicorn

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Currently containing a single type.

=head1 TYPES

=head2 AbsPath

Matches absulute unix path.

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

