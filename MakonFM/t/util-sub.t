#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use File::Basename qw(dirname);
my $PATH;
BEGIN { $PATH = sub { dirname( (caller)[1] ) }->(); }
use lib "$PATH/../lib";

use_ok('MakonFM');
use_ok('MakonFM::Util::Subs');

my $sub = MakonFM::Util::Subs::get_subs_local("85-05A");
ok($sub->{data}, 'subs loaded');

my $word = MakonFM::Util::Subs::get_word_by_timestamp($sub,941.57);
ok($word, 'word retrieved');
