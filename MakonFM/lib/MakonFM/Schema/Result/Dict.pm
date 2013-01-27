package MakonFM::Schema::Result::Dict;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

MakonFM::Schema::Result::Dict

=cut

__PACKAGE__->table("dict");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'dict_id_seq'

=head2 form

  data_type: 'varchar'
  is_nullable: 0
  size: 63

=head2 pron

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "dict_id_seq",
  },
  "form",
  { data_type => "varchar", is_nullable => 0, size => 63 },
  "pron",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("dict_form_pron_key", ["form", "pron"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-01-27 12:18:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:djpivw7SeHtSYX8ZefI6lQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
