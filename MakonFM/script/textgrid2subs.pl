#!/usr/bin/env perl

# textgrid2subs.pl outdir textGridFiles...

use utf8;
use strict;
use warnings;
use 5.010;

use TextGrid2subs qw(files2sub);

my $outdir = shift;

my @files;
while (<>) {
  chomp;
  push @files, $_;
}

@files = sort @files;

files2sub($outdir, @files);
