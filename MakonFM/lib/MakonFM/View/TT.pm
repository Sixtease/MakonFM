package MakonFM::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

MakonFM::View::TT - TT View for MakonFM

=head1 DESCRIPTION

TT View for MakonFM.

=head1 SEE ALSO

L<MakonFM>

=head1 AUTHOR

Jan Oldrich Kruza <sixtease@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
