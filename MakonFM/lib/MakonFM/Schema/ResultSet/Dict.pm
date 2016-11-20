package MakonFM::Schema::ResultSet::Dict;

use Moose;
use utf8;
use Encode qw(encode_utf8);
use namespace::autoclean;

extends qw(DBIx::Class::ResultSet);

sub add_word {
    my ($self, $word) = @_;
    $self->find_or_create({
        form => encode_utf8($word->{wordform}),
        pron => $word->{fonet},
    });
}

1

__END__
