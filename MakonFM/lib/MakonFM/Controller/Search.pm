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

    my $param = $c->request->parameters;

    my $query = $param->{query};
    my $from = $param->{from} || 0;
    my @order_by = (parse_order_by($param->{'order_by[]'}), '_score');

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
        sort => \@order_by,
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

sub texty :Path('texty') :Args(0) {
    my ($self, $c) = @_;

    my $param = $c->request->parameters;
    my $query = $param->{query};
    my $from  = $param->{from}  || 0;
    my $size  = $param->{size};

    my @order_by = (parse_order_by($param->{'order_by[]'}), '_score');
    my @filters;
    push @filters, { term => { collection => $param->{collection} } } if $param->{collection};
    push @filters, { term => { book_id    => $param->{book_id} } }    if $param->{book_id};

    my $match_clause = $query
        ? { match => { body => $query } }
        : { match_all => {} };

    my %es_query = (
        query => @filters
            ? {
                bool => {
                    must   => [$match_clause],
                    filter => \@filters,
                },
            }
            : $match_clause,
        highlight => {
            fields  => {
                body  => {},
            },
            pre_tags  => ['**'],
            post_tags => ['**'],
        },
        sort => \@order_by,
    );

    my $es = Search::Elasticsearch->new;

    my %search = (
        index => 'knihy',
        from  => $from,
        body  => \%es_query,
    );
    $search{size} = $size if defined $size;

    my $results = $es->search(%search);

    $c->response->content_type('text/json');
    $c->response->header('Access-Control-Allow-Origin' => '*');
    $c->response->body(decode_utf8(encode_json($results)));
}

sub parse_order_by {
    my ($param) = @_;
    if (ref($param)) {
        return map parse_single_order_by($_), @$param;
    }
    elsif ($param) {
        return parse_single_order_by($param);
    }
    else {
        return ();
    }
}
sub parse_single_order_by {
    my ($param) = @_;
    my ($name, $order) = ((split /,/, $param), 'asc');
    return {
        $name => { order => $order },
    };
}

__PACKAGE__->meta->make_immutable;

1

__END__
