#!/usr/bin/env perl

# textgrid2subs.pl outdir textGridFiles...

use utf8;
use strict;
use warnings;
use 5.010;

use TextGrid2subs qw(files2sub);

files2sub(@ARGV);
