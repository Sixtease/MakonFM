#!/usr/bin/perl

# export.pl *.sub.js
# creates a page with all the transcriptions aligned with the recordings

use 5.010;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use JSON ();
use Template;

sub read_file {
  my ($fn) = @_;
  local $/;
  open my $fh, '<:utf8', $fn or die;
  return <$fh>;
}

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
        say STDERR $sub_fn;
        my $sub_jsonp = read_file($sub_fn, {binmode => ':utf8'});
        my ($sub) = load_sub($sub_jsonp);
        my $stem = $sub->{filestem};
        my $audiofn = "$ENV{MAKONFM_MP3_DIR}/$stem.mp3";
        my $audiolen = `soxi -D "$audiofn"`;
        chomp $audiolen;
        my $out_fn = "$stem.trs";
        $sub->{audiolen} = $audiolen;
        $tt->process('trs-export.tt', $sub, $out_fn, { binmode => 'utf8' });
    }
}

main();
