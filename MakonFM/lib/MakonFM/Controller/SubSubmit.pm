package MakonFM::Controller::SubSubmit;
use Moose;
use namespace::autoclean;
use utf8;
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

    my $start = $param->{start};
    my $end   = $param->{end};
    my $subs;
    my $subs_json = $param->{subs};
    my $is_success;

    my $version_row = $c->model->resultset('Version')->find({key => $filestem});
    my $version = $version_row ? $version_row->get_column('value') : 0;
    if ($version < 0) {
        $is_success = 0;
    }
    elsif ($subs_json) {
      undef $@;
      eval {
        $subs = JSON->new->decode($subs_json);
        $_->{humanic} = 1 for @{$subs->{data}};
        $subs->{success} = 1;
        $is_success = 1;
      };
      if ($@) {
        $is_success = 0;
      }
    }
    else {
        my $mfcc_fn =
            $c->econf(qw{paths audio mfcc})
            . $filestem
            . '.mfcc'
        ;

        my $mp3_fn;
        if ($c->config->{mkwav}) {
            $mp3_fn =
                $c->econf(qw{paths audio mp3})
                . $filestem
                . '.mp3'
            ;
        }

        MakonFM::Util::Vyslov::set_dict($c->model->resultset('Dict'));

        undef $@;
        $subs = eval {
            MakonFM::Util::MatchChunk::get_subs(\$trans_bytes, $mfcc_fn, $start, $end, $mp3_fn);
        };
        if ($@) {
            $c->response->status(400);
            $c->response->body(JSON->new->encode({message=>$@}));
            $c->detach();
        }

        $is_success = $subs->{success};
        $subs->{filestem} = $filestem;
        $subs->{start} = $start;
        $subs->{end} = $end;
        $_->{humanic} = 1 for @{ $subs->{data} };
    }

    my $author = $param->{'author'} || '';
    my $session = $param->{session} || $c->sessionid || '';

    $c->model->resultset('Submission')->create({
        filestem => $filestem,
        start_ts => $start,
        end_ts   => $end,
        transcription => $trans_bytes,
        matched_ok => $is_success,
        sub_infos => [
            {
                name => 'ip_address',
                value => $c->request->address,
            },
            {
                name => 'author',
                value => encode_utf8($author),
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

    if ($is_success) {
        MakonFM::Util::Subs::merge($subs);
    }

    if ($subs) {
        $c->response->body(JSON->new->pretty->encode($subs));
    }
    else {
        $c->response->status(403);
        $c->response->body(JSON->new->encode({
            message => 'Tuto nahrávku již nelze opravovat. Pokud jste našli chybu v přepisu, prosím o zprávu.',
        }));
    }
}

sub save_submission {
}

__PACKAGE__->meta->make_immutable;

1

__END__
