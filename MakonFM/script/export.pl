#!/usr/bin/perl

# export.pl *.sub.js
# creates a page with all the transcriptions aligned with the recordings

use 5.010;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use JSON ();
use File::Slurp;
use Template;

my $PATH;
use File::Basename qw(dirname);
BEGIN { $PATH = sub { dirname((caller)[1]) }->() }

my $tt = Template->new({
    INCLUDE_PATH => "$PATH/../root",
});

sub load_sub {
    my ($sub_jsonp) = @_;
    $sub_jsonp =~ s/^([^{]+)//;
    my $head = $1;
    $sub_jsonp =~ s/([^}]+)$//;
    my $foot = $1;
    my $subs = JSON->new->decode($sub_jsonp);
    return $subs, $head, $foot
}

sub main {
    for my $sub_fn (@ARGV) {
        my $sub_jsonp = read_file($sub_fn, {binmode => ':utf8'});
        my ($sub) = load_sub($sub_jsonp);
        my $stem = $sub->{filestem};
        my $out_fn = "$stem.html";
        $tt->process('export.tt', $sub, $out_fn);
    }
}

main();
