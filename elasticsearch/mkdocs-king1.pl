#!/usr/bin/perl

# export.pl *.sub.js
# creates a page with all the transcriptions aligned with the recordings

use 5.010;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use Template;
use File::Basename qw(dirname);

my $PATH;
BEGIN { $PATH = (sub { dirname( (caller)[1] ) })->(); }
use lib $PATH;

use Subs qw(decode_subs);

my $tt = Template->new({
    INCLUDE_PATH => "$PATH",
    ENCODING => 'UTF-8',
});

my %is_sent_end_char = (
    '.' => 1,
    '?' => 1,
    '!' => 1,
);

sub looks_like_sent_end {
    my $word = shift;
    return 0 if not $word;
    my $occ = $word->{occurrence};
    my $last_char = substr($occ, -1);
    return $is_sent_end_char{$last_char};
}

sub looks_like_sent_start {
    my $word = shift;
    return 0 if not $word;
    my $occ = $word->{occurrence};
    return $occ =~ /^[[:upper:]]/;
}

sub is_sentence_boundary {
    my ($current, $next) = @_;
    return 1 if not defined $next;
    my $rv = (looks_like_sent_end($current) and looks_like_sent_start($next)) ? 1 : 0;
    return $rv;
}

sub should_flush {
    my ($word, $lookahead, $last_flush) = @_;
    return 1 if is_sentence_boundary($word, $lookahead);
    return 1 if $word->{timestamp} - $last_flush > 15;
    return 0;
}

sub main {
    for my $sub_fn (@_) {
        say STDERR $sub_fn;
        my ($sub) = decode_subs($sub_fn);
        my $stem = $sub->{filestem};
        my @sentence;
        my $has_humanic = 0;
        my $has_non_humanic = 0;
        my $words = $sub->{data};
        my $last_flush = 0;
        for my $i (0 .. $#$words) {
            my $word = $words->[$i];
            $word->{fonet} =~ s/\s*\b(sil|sp)\b//g if $word->{fonet};
            $word->{occurrence} =~ s/"/\\"/g;
            $word->{occurrence} =~ s/'/'\\''/g;
            if ($word->{humanic}) {
                $has_humanic = 1;
                $word->{cmscore} = 1;
            }
            else {
                $has_non_humanic = 1;
            }
            push @sentence, $word;
            my $lookahead = $words->[$i+1];
            if (should_flush($word, $lookahead, $last_flush)) {
                $last_flush = $word->{timestamp};
                my $sent_ts = $sentence[0]{timestamp};
                my $id = "$stem--$sent_ts";
                my $out_fn = "$id.sh";
                open my $out_fh, '>:utf8', $out_fn;
                my $humanicity = 'none';
                if ($has_humanic) {
                    if ($has_non_humanic) {
                        $humanicity = 'partial';
                    }
                    else {
                        $humanicity = 'complete';
                    }
                }
                $tt->process('mkdoc-king1.tt', {
                    id => $id,
                    words => \@sentence,
                    humanicity => $humanicity,
                }, $out_fh);
                close $out_fh;
                @sentence = ();
                $has_humanic = 0;
                $has_non_humanic = 0;
            }
        }
    }
}

main(@ARGV);
