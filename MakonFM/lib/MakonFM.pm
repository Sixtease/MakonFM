package MakonFM;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    Session
    Session::State::Cookie
    Session::Store::FastMmap
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in makonfm.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'MakonFM',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

# Start the application
__PACKAGE__->setup();

# takes a list of hash keys to $c->config
# and returns the config value with $foo
# expanded to the config value of foo.
# E.G. given $c->config->{paths}{HTK} eq '$home/HTK',
# $c->econf->('paths', 'HTK') returns
# $c->config->{home} . '/HTK'
sub econf {
    my ($c, @keys) = @_;
    my $conf = my $config = $c->config;
    while (my $key = shift @keys) {
        $conf = $conf->{$key};
    }
    my $rv;
    Template->new->process(
        \$conf,
        $config,
        \$rv,
    );
    return $rv
}

sub v {
    my ($self, $key) = @_;
    return '?v=' . $self->model->get_version($key)
}

=head1 NAME

MakonFM - Catalyst based application

=head1 SYNOPSIS

    script/makonfm_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<MakonFM::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Jan Oldrich Kruza <sixtease@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
