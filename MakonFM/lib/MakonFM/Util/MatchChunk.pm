package MakonFM::Util::MatchChunk;

use strict;
use utf8;
use open qw(:std :utf8);

use File::Basename;
my $PATH;
BEGIN { $PATH = sub { dirname ( (caller)[1] ) }->(); }
use lib $PATH;

use Vyslov qw(vyslov);

my $htk_path = '';
sub import {
    my ($package, %options) = @_;
    if ($options{})
}

my $trans_fn = shift;
my $wav_fn = shift;

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

my $mfc_fn = 'chunk0.mfc';
system(qq{HCopy -C config0 $wav_fn $mfc_fn});

system(qq{LANG=C HVite -l '*' -b silence -C config1 -a -H hmmmacros -H hmmdefs -i aligned.mlf -m -t 250.0 -I "$trans_mlf_fn" -y lab "$dict_fn" monophones1 "$mfc_fn"});

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
