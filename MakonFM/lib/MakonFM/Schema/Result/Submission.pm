package MakonFM::Schema::Result::Submission;

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

MakonFM::Schema::Result::Submission

=cut

__PACKAGE__->table("submissions");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'submissions_id_seq'

=head2 filestem

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 sub_ts

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 start_ts

  data_type: 'real'
  is_nullable: 0

=head2 end_ts

  data_type: 'real'
  is_nullable: 0

=head2 transcription

  data_type: 'text'
  is_nullable: 0

=head2 author

  data_type: 'text'
  is_nullable: 1

=head2 matched_ok

  data_type: 'boolean'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "submissions_id_seq",
  },
  "filestem",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "sub_ts",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "start_ts",
  { data_type => "real", is_nullable => 0 },
  "end_ts",
  { data_type => "real", is_nullable => 0 },
  "transcription",
  { data_type => "text", is_nullable => 0 },
  "author",
  { data_type => "text", is_nullable => 1 },
  "matched_ok",
  { data_type => "boolean", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("submissions_author_sub_ts_key", ["author", "sub_ts"]);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-03-05 19:12:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z9jLlaA8d0XD9I/a3fTXMQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
