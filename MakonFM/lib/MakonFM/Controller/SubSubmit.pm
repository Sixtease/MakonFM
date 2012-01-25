package MakonFM::Controller::SubSubmit;
use Moose;
use namespace::autoclean;
use Encode;
use MakonFM::Util::MatchChunk;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    
    my $trans = decode_utf8 $c->request->parameters->{trans};
    my $audio_fn = 
        $c->econf(qw{paths audio mp3})
        . $c->request->parameters->{filestem}
        . '.mp3'
    ;
    my $start = $c->request->parameters->{start};
    my $end   = $c->request->parameters->{ end };
    
    $c->response->content_type('text/json');
    $c->response->body(encode_utf8 MakonFM::Util::MatchChunk::get_subs(\$trans, $audio_fn, $start, $end));
}

__PACKAGE__->meta->make_immutable;

1

__END__
