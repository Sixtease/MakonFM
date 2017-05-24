package MakonFM::Controller::SubSubmit;
use Moose;
use namespace::autoclean;
use Encode qw(encode_utf8);
use MakonFM::Util::MatchChunk;
use MakonFM::Util::Vyslov;
use MakonFM::Util::Subs;
use JSON ();
use URL::Encode ();

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    $c->response->content_type('text/json');
    $c->response->header('Access-Control-Allow-Origin' => '*');
    $c->response->header('Access-Control-Allow-Methods' => 'POST');
    $c->response->header('Access-Control-Allow-Headers' => 'Content-Type');
    if ($c->request->method eq 'OPTIONS') {
        $c->response->body('');
        $c->detach;
    }
    
    my $param = $c->request->parameters;
    if ($c->request->user_agent =~ /MSIE/
        and keys(%{ $c->request->parameters }) == 0
        and ref($c->request->body) =~ /File/
    ) {
        my $handle = $c->request->body();
        my $body = join '', <$handle>;
        $param = URL::Encode::url_params_mixed($body);
    }
    
    my $trans = $param->{trans};
    my $trans_bytes = encode_utf8 $trans;
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
    
    MakonFM::Util::Vyslov::set_dict($c->model->resultset('Dict'));
    my $subs = MakonFM::Util::MatchChunk::get_subs(\$trans_bytes, $mfcc_fn, $start, $end, $mp3_fn);
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
        transcription => $trans_bytes,
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
            {
                name => 'user_agent',
                value => $c->request->user_agent,
            },
        ],
    });
    
    if ($subs->{success}) {
        MakonFM::Util::Subs::merge($subs);
    }
    
    $c->response->body(JSON->new->pretty->encode($subs));
}

__PACKAGE__->meta->make_immutable;

1

__END__
