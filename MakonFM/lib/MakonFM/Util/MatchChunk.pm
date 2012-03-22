package MakonFM::Util::MatchChunk;

use strict;
use utf8;
use open qw(:std :utf8);
use File::chdir;
use MakonFM::Util::Vyslov qw(vyslov);
use MakonFM::Util::HTKout2subs;

our $HTKpath  = MakonFM->econf(qw{paths HTK});
our $soxpath  = MakonFM->econf(qw{paths sox});
our $workpath = MakonFM->econf(qw{Util MatchChunk workpath});

sub import {
    my ($class, %arg) = @_;
    if (exists $arg{workpath}) {
        $workpath = $arg{workpath};
        $workpath =~ s{(?<=[^/])/*$}{/};
    }
    if (exists $arg{HTKpath}) {
        $HTKpath = $arg{HTKpath};
    }
    if (exists $arg{soxpath}) {
        $soxpath = $arg{soxpath};
    }
}

$MakonFM::Util::HTKout2subs::quiet = 1;

sub get_subs {

    my ($trans_fn, $audio_fn, $start_pos, $end_pos) = @_;

    local $CWD = $workpath if $workpath;

    open my $trans_fh, '<:utf8', $trans_fn or die "Couldn't open '$trans_fn': $!";

    my @words = parse_words($trans_fh);

    my $trans_mlf = txt2mlf(@words);
    my $trans_mlf_fn = 'trans.mlf';
    open my $trans_mlf_fh, '>:encoding(iso-8859-2)', $trans_mlf_fn or die "Couldn't open $trans_mlf_fn for writing: $!";
    print {$trans_mlf_fh} $trans_mlf;
    close $trans_mlf_fh;

    my $dict = txt2dict(@words);
    my $dict_fn = 'dict';
    open my $dict_fh, '>:encoding(iso-8859-2)', $dict_fn or die "Couldn't open '$dict_fn': $!";
    print {$dict_fh} $dict;
    close $dict_fh;

    my $wav_fn = 'chunk0.wav';
    unlink $wav_fn;
    system(qq(${soxpath}sox "$audio_fn" "$wav_fn" trim $start_pos =$end_pos));

    my $mfc_fn = 'chunk0.mfc';
    unlink $mfc_fn;
    system(qq(${HTKpath}HCopy -C config0 "$wav_fn" "$mfc_fn"));

    my $aligned_fn = 'aligned.mlf';
    unlink $aligned_fn;
    system(qq(LANG=C ${HTKpath}HVite -l '*' -b silence -C config1 -a -H hmmmacros -H hmmdefs -i $aligned_fn -m -t 500.0 -I "$trans_mlf_fn" -y lab "$dict_fn" monophones1 "$mfc_fn"));

    my @subs = do {
        open my $aligned_fh, '<', $aligned_fn or die "Couldn't open '$aligned_fn': $!";
        my $splits = [0+$start_pos];
        grep {;
            $_->{wordform} ne 'silence'
        } @{ MakonFM::Util::HTKout2subs::get_subs($splits, $aligned_fh) }
    };
    
    # prefer human-given occurrences when word forms corresponding
    for my $i (0 .. $#subs) {
        next if not exists $words[$i];
        my $s = $subs[$i];
        my $w = $words[$i];
        if ($s->{wordform} eq lc($w->{ucform})) {
            $s->{occurrence} = $w->{occurrence};
        }
    }

    my $success = 1;
    if (scalar(@words) xor scalar(@subs)) {
        $success = 0;
    }

    return {
        subs => \@subs,
        success => $success,
    }

}

sub txt2dict {
    my $dict = '';
    my %words;
    $dict .= "silence       sil\n";
    $dict .= "!ENTER       sil\n";
    $dict .= "!EXIT       sil\n";
    for (@_) {
        next if $words{$_->{occurrence}}++;
        $dict .= $_->{ucform} . '       ' . $_->{fonet} . "\n";
    }
    return $dict
}

sub txt2mlf {
    my $rv = '';
    $rv .= "#!MLF!#\n";
    $rv .= qq{"chunk0.lab"\n};
    $rv .= "!ENTER\n";
    for (@_) {
        $rv .=  $_->{ucform} . "\n";
    }
    $rv .= "!EXIT";
    return $rv
}

sub parse_words {
    my ($fh) = @_;
    my @words;
    while (<$fh>) {
        for (split /\s+/) {
            my $ucform = uc occ2form($_);
            push @words, {
                occurrence => $_,
                fonet => vyslov($ucform),
                ucform => $ucform,
            };
        }
    }
    return @words
}

sub occ2form {
    for (my ($tmp) = @_) {
        s/\W+//g;
        return lc
    }
}

1
