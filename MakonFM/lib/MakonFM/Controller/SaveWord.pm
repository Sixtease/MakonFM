package MakonFM::Controller::SaveWord;
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
    
    my $wordform   = decode_utf8 $param->{wordform};
    my $occurrence = decode_utf8 $param->{occurrence};
    my $phonet     =             $param->{phonet};
    my $timestamp  =             $param->{timestamp};
    my $stem       =             $param->{stem};
    
    my $subs = MakonFM::Util::Subs::get_subs_local($stem);
    if (not $subs) {
        die "stem not found: $stem"
    }
    my $word_data = MakonFM::Util::Subs::get_word_by_timestamp($subs, $timestamp);
    if (not $word_data) {
        die "word not found (timestamp $timestamp)"
    }
    my $word = $word_data->{word};
    $word->{wordform}   = $wordform;
    $word->{occurrence} = $occurrence;
    $word->{phonet}     = $phonet;
    
    $subs->{data}[$word_data->{i}] = $word;
    
    die "invalid filestem '$stem'" unless $stem =~ /^[-.!()\w\d]+$/;
    () = $c->model->resultset('RaiseVersion')->search({}, {bind => [$stem]});
    
    $c->response->content_type('text/json');
    $c->response->header('Access-Control-Allow-Origin' => '*');
    $c->response->body(encode_utf8(JSON->new->pretty->encode({success => 1})));
    
    MakonFM::Util::Subs::save_subs_local($subs);
    MakonFM::Util::Subs::save_subs_gs   ($subs);
}

__PACKAGE__->meta->make_immutable;

1

__END__
