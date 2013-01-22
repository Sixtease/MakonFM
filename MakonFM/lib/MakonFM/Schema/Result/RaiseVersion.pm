package MakonFM::Schema::Result::RaiseVersion;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
BEGIN { extends 'DBIx::Class::Core'; }
 
__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table('versions');
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q[
  SELECT raise_version(?)
]);

1

__END__
