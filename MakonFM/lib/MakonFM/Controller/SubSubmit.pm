package MakonFM::Controller::SubSubmit;
use Moose;
use namespace::autoclean;
use Encode;
use MakonFM::Util::MatchChunk;
use MakonFM::Util::Subs;
use JSON ();
use URL::Encode ();

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    
    my $param = $c->request->parameters;
    if ($c->request->user_agent =~ /MSIE/
        and keys(%{ $c->request->parameters }) == 0
        and ref($c->request->body) =~ /File/
    ) {
        my $handle = $c->request->body();
        my $body = join '', <$handle>;
        $param = URL::Encode::url_params_mixed($body);
    }
    
    my $trans = decode_utf8 $param->{trans};
    my $filestem = $param->{filestem};
    my $mfcc_fn = 
        $c->econf(qw{paths audio mfcc})
        . $filestem
        . '.mfcc'
    ;
    my $start = $param->{start};
    my $end   = $param->{ end };
    
    my $mp3_fn;
    if ($c->config->{mkwav}) {
        $mp3_fn =
            $c->econf(qw{paths audio mp3})
            . $filestem
            . '.mp3'
        ;
    }
    
    my $subs = MakonFM::Util::MatchChunk::get_subs(\$trans, $mfcc_fn, $start, $end, $mp3_fn);
    $subs->{filestem} = $filestem;
    $subs->{start} = $start;
    $subs->{end} = $end;
    $_->{humanic} = 1 for @{ $subs->{data} };
    
    my $author = $param->{'author'} || '';
    my $session = $param->{session} || $c->sessionid || '';
    
    $c->model->resultset('Submission')->create({
        filestem => $filestem,
        start_ts => $start,
        end_ts   => $end,
        transcription => $trans,
        matched_ok => $subs->{success},
        sub_infos => [
            {
                name => 'ip_address',
                value => $c->request->address,
            },
            {
                name => 'author',
                value => $author,
            },
            {
                name => 'session',
                value => $session,
            },
        ],
    });
    
    if ($subs->{success}) {
        MakonFM::Util::Subs::merge($subs);
    }
    
    $c->response->content_type('text/json');
    $c->response->header('Access-Control-Allow-Origin' => '*');
    $c->response->body(encode_utf8(JSON->new->pretty->encode($subs)));
}

__PACKAGE__->meta->make_immutable;

1

__END__
