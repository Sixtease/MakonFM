package MakonFM::Schema::Result::SubInfo;

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

MakonFM::Schema::Result::SubInfo

=cut

__PACKAGE__->table("sub_info");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sub_info_id_seq'

=head2 submission

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 31

=head2 value

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sub_info_id_seq",
  },
  "submission",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 31 },
  "value",
  { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  "submission_has_max_1_field_of_a_name",
  ["submission", "name"],
);

=head1 RELATIONS

=head2 submission

Type: belongs_to

Related object: L<MakonFM::Schema::Result::Submission>

=cut

__PACKAGE__->belongs_to(
  "submission",
  "MakonFM::Schema::Result::Submission",
  { id => "submission" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-06 13:04:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lAdO1ncNnLj8HA9KWwhIbQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
