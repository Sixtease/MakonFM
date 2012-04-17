package MakonFM::Controller::Root;
use Moose;
use namespace::autoclean;
use JSON ();

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

MakonFM::Controller::Root - Root Controller for MakonFM

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) { }

sub subversions :Local {
    my ($self, $c) = @_;
    my %sub_versions = map {; $_->key => $_->value } $c->model->resultset('Version')->all();
    $c->response->content_type('text/javascript');
    $c->response->body( 'jQuery(document).trigger("subversions_arrived", ' . JSON->new->encode(\%sub_versions) . ');' );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Jan Oldrich Kruza <sixtease@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
