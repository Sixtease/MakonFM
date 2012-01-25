package MakonFM::Controller::SubSubmit;
use Moose;
use namespace::autoclean;
use Encode;
use MakonFM::Util::MatchChunk;
use JSON ();

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    
    my $trans = decode_utf8 $c->request->parameters->{trans};
    my $filestem = $c->request->parameters->{filestem};
    my $audio_fn = 
        $c->econf(qw{paths audio mp3})
        . $filestem
        . '.mp3'
    ;
    my $start = $c->request->parameters->{start};
    my $end   = $c->request->parameters->{ end };
    
    my $rv = MakonFM::Util::MatchChunk::get_subs(\$trans, $audio_fn, $start, $end);
    $rv->{filestem} = $filestem;
    $rv->{start} = $start;
    $rv->{end} = $end;
    
    $c->response->content_type('text/json');
    $c->response->body(encode_utf8(JSON->new->pretty->encode($rv)));
}

__PACKAGE__->meta->make_immutable;

1

__END__
