package MakonFM::Controller::Search;
use Moose;
use namespace::autoclean;
use Search::Elasticsearch ();
use utf8;
use JSON::XS qw(encode_json);
use Encode qw(decode_utf8);

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    ;;; my $results = q({"took":222,"hits":{"hits":[{"_id":"82-17--5679.62","_source":{"occurrences":"Tak to do mě ne si vytvořil by byl ve své představě duchu duchy země duchy body duchy oheň mě.","cmscore":[0.212,0.226,0.126,0.264,0.172,0.434,0.441,0.855,0.288,0.782,0.176,0.052,0.292,0.876,0.383,0.842,0.497,0.312,0.111,0.263],"humanicity":"none","phonet":"t a k t o d o m nj e n e s i v i t v o rzh i l b i b i l v e s v ee p rsh e d s t a v j e d u x u d u x i z e m nj e d u x i b o d i d u x i o h e nj m nj e"},"_type":"veta","_score":7.489885,"_index":"tking","highlight":{"occurrences":["Tak to do mě ne si vytvořil by byl ve své představě <em>duchu</em> <em>duchy</em> země <em>duchy</em> body <em>duchy</em> oheň mě."]}},{"_score":7.2927866,"_index":"tking","highlight":{"occurrences":["Není to špatné, ale není v tom <em>duch</em>, <em>duch</em> z toho vyprchal."]},"_id":"87-14A--2095.25","_source":{"humanicity":"complete","phonet":"n e nj ii t o sh p a t n ee a l e n e nj ii f t o m d u x d u x s t o h o v i p r x a l","cmscore":[1,1,1,1,1,1,1,1,1,1,1,1],"occurrences":"Není to špatné, ale není v tom duch, duch z toho vyprchal."},"_type":"veta"},{"_type":"veta","_source":{"humanicity":"complete","phonet":"r o z u m ii t e t a m s e s t ii k aa m e j a k o d u x s d u x e m","cmscore":[1,1,1,1,1,1,1,1],"occurrences":"Rozumíte, tam se stýkáme jako duch s duchem."},"_id":"82-06--2862.11","highlight":{"occurrences":["Rozumíte, tam se stýkáme jako <em>duch</em> s <em>duchem</em>."]},"_index":"tking","_score":7.0495996},{"_score":7.0051904,"highlight":{"occurrences":["A co už dalších neomaleností provedli lidé, který se dovolávali <em>duchem</em>- <em>duchu</em>- <em>Ducha</em> svatého."]},"_index":"tking","_source":{"cmscore":[1,1,1,1,1,1,1,1,1,1,1,1,1,1],"phonet":"a c o u sh d a l sh ii x n e o m a l e n o s tj ii p r o v e d l i l i d ee k t e r ii s e d o v o l aa v a l i d u x e m d u x u d u x a s v a t ee h o","humanicity":"complete","occurrences":"A co už dalších neomaleností provedli lidé, který se dovolávali duchem- duchu- Ducha svatého."},"_id":"82-04--5434.87","_type":"veta"},{"_score":7.0051904,"highlight":{"occurrences":["Tady je ovšem problém, jak mít toho <em>Ducha</em> svatého, jednat v tom <em>duchu</em> Božím, v tom pravém <em>duchu</em>."]},"_index":"tking","_id":"kotouc-T01-metoda-b--2568.36","_source":{"occurrences":"Tady je ovšem problém, jak mít toho Ducha svatého, jednat v tom duchu Božím, v tom pravém duchu.","humanicity":"complete","phonet":"t a d i j e o f sh e m p r o b l ee m j a k m ii t t o h o d u x a s v a t ee h o j e d n a t v t o m d u x u b o zh ii m v t o m p r a v ee m d u x u","cmscore":[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]},"_type":"veta"},{"highlight":{"occurrences":["Co je to ten <em>duch</em>?"]},"_index":"tking","_score":6.8839374,"_type":"veta","_id":"82-09--3326.97","_source":{"humanicity":"complete","phonet":"c o j e t o t e n d u x","cmscore":[1,1,1,1,1],"occurrences":"Co je to ten duch?"}},{"_type":"veta","_source":{"cmscore":[0.455,0.935,0.099],"phonet":"t a k t e n d u x","humanicity":"none","occurrences":"Tak ten duch."},"_id":"91-26A--2226.91","_index":"tking","highlight":{"occurrences":["Tak ten <em>duch</em>."]},"_score":6.8839374},{"_source":{"cmscore":[0.533,0.858,0.385],"humanicity":"none","phonet":"t a k t e n t o d u x","occurrences":"Tak tento duch."},"_id":"91-26A--2248.62","_type":"veta","_score":6.8839374,"highlight":{"occurrences":["Tak tento <em>duch</em>."]},"_index":"tking"},{"_index":"tking","highlight":{"occurrences":["Ale ten <em>duch</em>."]},"_score":6.8839374,"_type":"veta","_id":"kotouc-S01-c--2228.01","_source":{"occurrences":"Ale ten duch.","cmscore":[1,1,1],"humanicity":"complete","phonet":"a l e t e n d u x"}},{"_source":{"cmscore":[0.648,0.635,0.348,0.977,0.072,0.591,0.399,0.286,0.856,0.373,0.984,0.551,0.082,0.278],"humanicity":"none","phonet":"t o m u rzh e k l d u x g d i sh m u t a k l e j a k m n e t o m u ch l o v j e k u t e n d u x k s","occurrences":"Tomu řekl duch když mu takle jak mne tomu člověku ten duch k s."},"_id":"84-07B--2040.46","_type":"veta","_score":6.705106,"highlight":{"occurrences":["Tomu řekl <em>duch</em> když mu takle jak mne tomu člověku ten <em>duch</em> k s."]},"_index":"tking"}],"total":979,"max_score":7.489885},"_shards":{"successful":1,"total":1,"failed":0},"timed_out":false})
    ;;; $c->response->content_type('text/json');
    ;;; $c->response->header('Access-Control-Allow-Origin' => '*');
    ;;; $c->response->body($results);
    ;;; return;
    
    my $param = $c->request->parameters;
    
    my $query = $param->{query};
    my $from = $param->{from} || 0;

    my %es_query = (
        query => {
            #bool => {
            #    must => [
            #        {
                        match => {
                            occurrences => $query,
                        },
            #        },
            #        {
            #            match => {
            #                phonet =>"aw r o"
            #            },
            #        },
            #    ],
            #    filter => [
            #        {
            #            term => {
            #                humanicity => "complete"
            #            },
            #        },
            #    ],
            #},
        },
        highlight => {
            fields  => {
                occurrences  => {},
            },
            pre_tags  => ['**'],
            post_tags => ['**'],
        },
    );

    my $es = Search::Elasticsearch->new;

    my $results = $es->search(
        index => 'tking',
        from => $from,
        body => \%es_query,
    );

    $c->response->content_type('text/json');
    $c->response->header('Access-Control-Allow-Origin' => '*');
    $c->response->body(decode_utf8(encode_json($results)));
}

__PACKAGE__->meta->make_immutable;

1

__END__
