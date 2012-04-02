#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Basename;
my $PATH;
BEGIN { $PATH = sub { dirname((caller)[1]) }->() }
use lib $PATH;
my $ROOT = "$PATH/..";

my $gs_prefix = 'gs://karel-makon-sub';

open my $get_subs_fh, '-|', "gsutil ls $gs_prefix";
my @gs_subs = <$get_subs_fh>;
close $get_subs_fh;
chomp @gs_subs;

my %gs_stems = map {; substr($_, length("$gs_prefix/")) => 1 } @gs_subs;

chdir "$ROOT/root/static/subs";
my @to_upload;

for my $sub (glob('*')) {
    chomp $sub;
    if ($gs_stems{$sub}) {
        print STDERR "skipping already-present '$sub'\n";
    }
    else {
        push @to_upload, $sub;
    }
}

my $quoted_file_list = join ' ', map "'$_'", @to_upload;
system "gsutil cp $quoted_file_list $gs_prefix";
