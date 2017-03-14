package MakonFM::Controller::Search;
use Moose;
use namespace::autoclean;
use Search::Elasticsearch ();
use JSON::XS qw(encode_json);
use Encode qw(decode_utf8);

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    
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
