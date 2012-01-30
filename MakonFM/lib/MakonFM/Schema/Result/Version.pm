package MakonFM::Schema::Result::Version;

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

MakonFM::Schema::Result::Version

=cut

__PACKAGE__->table("versions");

=head1 ACCESSORS

=head2 key

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 value

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "key",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "value",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("key");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-30 18:15:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QRXCIhdDIH1bp8QcbG3VPw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
