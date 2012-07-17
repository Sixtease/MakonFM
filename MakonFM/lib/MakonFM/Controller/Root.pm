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

sub index :Path :Args(0) { }

sub manual :Local { }

sub subversions :Local {
    my ($self, $c) = @_;
    my %sub_versions = map {; $_->key => $_->value } $c->model->resultset('Version')->all();
    $c->response->content_type('text/javascript');
    $c->response->body( 'jQuery(document).trigger("subversions_arrived", ' . JSON->new->encode(\%sub_versions) . ');' );
}

sub setname :Local {
    my ($self, $c) = @_;
    $c->session->{author} = $c->request->param('name');
    $c->response->body('');
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
