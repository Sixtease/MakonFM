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

sub init :Local {
    my ($self, $c) = @_;
    my %sub_versions = map {; $_->key => $_->value } $c->model->resultset('Version')->all();
    my $data = {
        subversions => \%sub_versions,
    };
    $c->session->{foo} = 1;
    $c->response->content_type('text/javascript');
    $c->response->body( 'jQuery(document).trigger("init_arrived", ' . JSON->new->encode($data) . ');' );
    $c->response->header('Access-Control-Allow-Origin' => '*');
}

sub req :Local {
    my ($self, $c) = @_;
    my $req = $c->request;
    my $ip = $req->address;
    my $ua = $req->user_agent;
    my $username = $req->param('username') || '';
    my $session = $req->param('session') || $c->sessionid || '';
    $c->model->resultset('PageLoad')->create({
        username => $username,
        ip => $ip,
        useragent => $ua,
        session => $session,
    });
    $c->response->header('Access-Control-Allow-Origin' => '*');
    $c->response->content_type('text/json');
    $c->response->body('{"status":"OK"}');
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
