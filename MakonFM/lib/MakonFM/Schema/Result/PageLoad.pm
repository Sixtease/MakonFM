package MakonFM::Schema::Result::PageLoad;

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

MakonFM::Schema::Result::PageLoad

=cut

__PACKAGE__->table("page_loads");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'page_loads_id_seq'

=head2 username

  data_type: 'text'
  is_nullable: 1

=head2 ip

  data_type: 'inet'
  is_nullable: 1

=head2 useragent

  data_type: 'text'
  is_nullable: 1

=head2 session

  data_type: 'text'
  is_nullable: 1

=head2 sub_ts

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "page_loads_id_seq",
  },
  "username",
  { data_type => "text", is_nullable => 1 },
  "ip",
  { data_type => "inet", is_nullable => 1 },
  "useragent",
  { data_type => "text", is_nullable => 1 },
  "session",
  { data_type => "text", is_nullable => 1 },
  "sub_ts",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2014-02-02 22:08:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gcKhDQ2GIyGq/0MNlFdVHw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
