package MakonFM::Controller::Root;
use Moose;
use namespace::autoclean;
use JSON ();
use File::Basename qw(fileparse dirname);
use Encode qw(encode_utf8);

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
    $c->response->body( 'jsonp_init(' . JSON->new->encode($data) . ');' );
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
        username => encode_utf8($username),
        ip => $ip,
        useragent => $ua,
        session => $session,
    });
    $c->response->header('Access-Control-Allow-Origin' => '*');
    $c->response->content_type('text/json');
    $c->response->body('{"status":"OK"}');
}

sub lssub :Local {
    my ($self, $c) = @_;
    my $PATH = sub { dirname((caller)[1]) }->();
    my %subs = map {; scalar(fileparse $_, '.sub.js') => ((stat)[9])} glob("$PATH/../../../root/static/subs/*.sub.js");
    $c->response->header('Access-Control-Allow-Origin' => '*');
    $c->response->content_type('text/plain');
    $c->response->body(JSON->new->utf8->encode(\%subs));
}

sub humpart :Local {
    my ($self, $c) = @_;
    my $PATH = sub { dirname((caller)[1]) }->();
    my %subs;
    for my $subfn (glob("$PATH/../../../root/static/subs/*.sub.js")) {
        open my $subfh, '<', $subfn or next;
        my $all = 0;
        my $hum = 0;
        while (<$subfh>) {
            ++$all if /\boccurrence\b/;
            ++$hum if /\bhumanic\b/;
        }
        my $stem = fileparse $subfn, '.sub.js';
        $subs{$stem} = { human => $hum, total => $all };
    }
    $c->response->header('Access-Control-Allow-Origin' => '*');
    $c->response->content_type('text/plain');
    $c->response->body(JSON->new->utf8->encode(\%subs));
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;

1;
