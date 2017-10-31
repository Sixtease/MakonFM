package MakonFM::Controller::SaveWord;
use Moose;
use namespace::autoclean;
use MakonFM::Util::Subs;
use MakonFM::Util::Vyslov qw(vyslov);
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
    
    my $wordform   = $param->{wordform};
    my $occurrence = $param->{occurrence};
    my $fonet      = $param->{fonet};
    my $timestamp  = $param->{timestamp};
    my $stem       = $param->{stem};
    
    my $subs = MakonFM::Util::Subs::get_subs_local($stem);
    if (not $subs) {
        die "stem not found: $stem"
    }
    my $word_data = MakonFM::Util::Subs::get_word_by_timestamp($subs, $timestamp);
    if (not $word_data) {
        die "word not found (timestamp $timestamp)"
    }
    my $word = $word_data->{word};
    
    if ($word->{wordform} ne $wordform) {
        my $dict_rs = $c->model->resultset('Dict');
        my $ucform = uc $wordform;
        MakonFM::Util::Vyslov::set_dict( $dict_rs );
        my $prons = vyslov($ucform);
        if ( $prons ) {
            if (grep { $fonet eq $_} @$prons ) { } else {
                $dict_rs->add_word({wordform => $ucform, fonet => $fonet});
            }
        }
    }
    
    $word->{wordform}   = $wordform;
    $word->{occurrence} = $occurrence;
    $word->{fonet}      = $fonet;
    
    $subs->{data}[$word_data->{i}] = $word;
    
    die "invalid filestem '$stem'" unless $stem =~ /^[-.!()\w\d]+$/;
    () = $c->model->resultset('RaiseVersion')->search({}, {bind => [$stem]});
    
    $c->response->body(JSON->new->pretty->encode({success => 1}));
    
    MakonFM::Util::Subs::save_subs_local($subs);
    MakonFM::Util::Subs::save_subs_gs   ($subs);
}

__PACKAGE__->meta->make_immutable;

1

__END__
