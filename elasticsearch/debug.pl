#!/usr/bin/perl

# export.pl *.sub.js
# creates a page with all the transcriptions aligned with the recordings

use 5.010;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use Template;
use Encode qw(encode_utf8);

my $PATH;
use File::Basename qw(dirname);
BEGIN { $PATH = sub { dirname((caller)[1]) }->() }

my $tt = Template->new({
    INCLUDE_PATH => "$PATH",
    ENCODING => 'UTF-8',
});

my $sentence = [
          {
            'occurrence' => 'A',
            'fonet' => 'a',
            'cmscore' => 1,
            'wordform' => 'a',
            'humanic' => 1,
            'timestamp' => '124.25'
          },
          {
            'fonet' => 't a h l e t a',
            'occurrence' => 'tahleta',
            'timestamp' => '124.79',
            'wordform' => 'tahleta',
            'humanic' => 1,
            'cmscore' => 1
          },
          {
            'occurrence' => '(nebo',
            'fonet' => 'n e b o',
            'wordform' => 'nebo',
            'humanic' => 1,
            'cmscore' => 1,
            'timestamp' => '125.78'
          },
          {
            'timestamp' => '125.97',
            'humanic' => 1,
            'wordform' => "sv\x{e9}mu",
            'cmscore' => 1,
            'fonet' => 's v ee m u',
            'occurrence' => "sv\x{e9}mu"
          },
          {
            'fonet' => 'v o k o l ii t a h l e t a',
            'occurrence' => "okol\x{ed}),tahleta",
            'timestamp' => '126.3',
            'wordform' => "okol\x{ed}tahleta",
            'humanic' => 1,
            'cmscore' => 1
          },
          {
            'occurrence' => 'oddanost',
            'fonet' => 'o d d a n o s t',
            'humanic' => 1,
            'wordform' => 'oddanost',
            'cmscore' => 1,
            'timestamp' => '129.22'
          },
          {
            'occurrence' => "m\x{e1}",
            'fonet' => 'm aa',
            'cmscore' => 1,
            'humanic' => 1,
            'wordform' => "m\x{e1}",
            'timestamp' => '130.83'
          },
          {
            'humanic' => 1,
            'wordform' => "sv\x{e9}",
            'cmscore' => 1,
            'timestamp' => '131.4',
            'occurrence' => "sv\x{e9}",
            'fonet' => 's v ee'
          },
          {
            'occurrence' => "v\x{fd}vojov\x{e9}",
            'fonet' => 'v ii v o j o v ee',
            'humanic' => 1,
            'wordform' => "v\x{fd}vojov\x{e9}",
            'cmscore' => 1,
            'timestamp' => '132.07'
          },
          {
            'fonet' => 'f aa z e',
            'occurrence' => "f\x{e1}ze,",
            'timestamp' => '132.89',
            'cmscore' => 1,
            'wordform' => "f\x{e1}ze",
            'humanic' => 1
          },
          {
            'occurrence' => 'jak',
            'fonet' => 'j a k',
            'cmscore' => 1,
            'wordform' => 'jak',
            'humanic' => 1,
            'timestamp' => '133.38'
          },
          {
            'wordform' => 'se',
            'humanic' => 1,
            'cmscore' => 1,
            'timestamp' => '133.54',
            'occurrence' => 'se',
            'fonet' => 's e'
          },
          {
            'occurrence' => 'tam',
            'fonet' => 't a m',
            'wordform' => 'tam',
            'humanic' => 1,
            'cmscore' => 1,
            'timestamp' => '133.65'
          },
          {
            'occurrence' => "dov\x{ed}d\x{e1}te.",
            'fonet' => 'd o v ii d aa t e',
            'humanic' => 1,
            'wordform' => "dov\x{ed}d\x{e1}te",
            'cmscore' => 1,
            'timestamp' => '133.88'
          }
];

sub main {
    open my $fh, '>:utf8', 'debug.out';
                $tt->process('mkdoc-king1.tt', {
                    id => 'badex',
                    words => $sentence,
                    humanicity => 'complete',
                }, $fh);# if 0;
}

main();
