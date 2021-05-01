#!/usr/bin/perl

# merge_subtitles.pl new.sub.js old.sub.js > merged.sub.js

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use File::Basename qw(dirname);
my $PATH;
BEGIN { $PATH = (sub { dirname( (caller)[1] ) })->(); }
use lib $PATH;
use Subs qw(decode_subs encode_subs);

my $sub2_depleted = 0;
my ($subs1, $subs2);

sub merge2 {
    ($subs1, $subs2) = @_;
    add_index_info($_) for $subs1, $subs2;
    my $rv = [];
    my $pos = 0;
    my $skip_first_asr_word = 0;
    CHUNK:
    while (1) {
        my ($start_ts, $end_ts, $sub1_chunk, $sub2_chunk) = get_asr_chunk($pos);
        
        if (@$sub2_chunk) {
            my $last_asr_w_1 = $sub1_chunk->[-1];
            my $first_hum_w_2 = next_word($sub2_chunk->[-1], $subs2);
            if ($skip_first_asr_word) {
                shift @$sub1_chunk;
                $skip_first_asr_word = 0;
            }
            if (are_identical_words($last_asr_w_1, $first_hum_w_2)) {
                pop @$sub1_chunk;
            }
            
            push @$rv, @$sub1_chunk;
            last CHUNK if $sub2_depleted;
        }
        
        ($start_ts, $end_ts, $sub1_chunk, $sub2_chunk) = get_humanic_chunk($end_ts);
        push @$rv, @$sub2_chunk;
        
        my $first_asr_w_1 = next_word($sub1_chunk->[-1]);
        my $last_hum_w_2 = $sub2_chunk->[-1];
        if (are_identical_words($first_asr_w_1, $last_hum_w_2)) {
            $skip_first_asr_word = 1;
        }
        
        $pos = $last_hum_w_2->{timestamp} + 0.01;
        last CHUNK if $sub2_depleted;
    }
    clean_temp_info($rv);
    return $rv
}

sub get_asr_chunk {
    my ($ts) = @_;
    return get_chunk(0, $ts)
}
sub get_humanic_chunk {
    my ($ts) = @_;
    return get_chunk(1, $ts)
}

sub get_chunk {
    my ($test, $pos) = @_;
    my $chunk1 = [];
    my $chunk2 = [];
    my $start;
    my $end;
    my $too_far = 1;
    SUB:
    for my $sub2 (@$subs2) {
        next if $sub2->{timestamp} < $pos;
        $too_far = 0;
        if ($sub2->{humanic} xor $test) {
            $end = $sub2->{timestamp};
            last SUB
        }
        push @$chunk2, $sub2;
    }
    return if $too_far;
    return $pos, $pos, [], [] if not @$chunk2;
    $start = $chunk2->[0]{timestamp};
    if (not $end) {
        $sub2_depleted = 1;
        $end = 'inf';
    }
    SUB:
    for my $sub1 (@$subs1) {
        next SUB if $sub1->{timestamp} < $start;
        last SUB if $sub1->{timestamp} > $end;
        push @$chunk1, $sub1;
    }
    return $start, $end, $chunk1, $chunk2
}

sub word_length {
    my ($sub, $subs) = @_;
    my $n = next_word($sub, $subs);
    if ($n) {
        return $n->{timestamp} - $sub->{timestamp}
    }
    else {
        return 0.2 * split /[aáeéěiíoóuúůyý]/, $sub->{wordform}
    }
}

sub are_identical_words {
    my ($sub1, $sub2) = @_;
    if (not defined $sub1 or not defined $sub2) {
        return 0
    }
    no warnings 'shadow';
    my ($sub1, $subs1, $sub2, $subs2) = ($sub1->{timestamp} < $sub2->{timestamp})
    ?  ($sub1, $subs1, $sub2, $subs2) : ($sub1->{timestamp} > $sub2->{timestamp})
    ?  ($sub2, $subs2, $sub1, $subs1) : return 1
    ;
    use warnings;
    my $l = word_length($sub1, $subs1);
    my $tolerance = $l/4;
    my ($pre1, $pre2);
    if ($sub1->{wordform} eq $sub2->{wordform}) {
        $tolerance = $l/2;
    }
    elsif ($pre1 = prev_word($sub1, $subs1) and $pre2 = prev_word($sub2, $subs2) and $pre1->{wordform} eq $pre2->{wordform}) {
        $tolerance = $l;
    }
    
    if (($sub2->{timestamp} - $sub1->{timestamp}) < $tolerance) {
        return 1
    }
    else {
        return 0
    }
}

sub add_index_info {
    my ($subs) = @_;
    for my $i (0 .. $#$subs) {
        $subs->[$i]{_i} = $i;
    }
}

sub clean_temp_info {
    my ($subs) = @_;
    for (@$subs) {
        delete $_->{_i};
    }
}

sub prev_word {
    my ($word, $subs) = @_;
    return $subs->[ $word->{_i} - 1 ]
}

sub next_word {
    my ($word, $subs) = @_;
    return $subs->[ $word->{_i} + 1 ]
}

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
    my ($sub1_fn, $sub2_fn) = @_;
    my ($sub1, $sub1_jsonp) = eval { decode_subs($sub1_fn, include_jsonp => 1) };
    my ($sub2, $sub2_jsonp) = eval { decode_subs($sub2_fn, include_jsonp => 1) };
    if (not $sub1 and not $sub2) {
        die "could open neither '$sub1_fn' nor '$sub2_fn'";
    }
    elsif ($sub1 and not $sub2) {
        print $sub1_jsonp;
        exit 0;
    }
    elsif ($sub2 and not $sub1) {
        print $sub2_jsonp;
        exit 0;
    }
    
    unless ($sub2_jsonp =~ /\bhumanic\b/) {
        print $sub1_jsonp;
        exit 0;
    }
    
    my $merged = merge2($sub1->{data}, $sub2->{data});
    delete $sub1->{data};
    my $filestem = delete $sub1->{filestem};
    if (keys %$sub1) {
        die "sub has more JSON fields than data and filestem";
    }
    print encode_subs($merged, $filestem);
}

main(@ARGV);
