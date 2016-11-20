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

    my ($trans_fn, $mfcc_fn, $start_pos, $end_pos, $audio_fn, $opt) = @_;
    $opt ||= {};

    local $CWD = $workpath if $workpath;

    open my $trans_fh, '<:utf8', $trans_fn or die "Couldn't open '$trans_fn': $!";

    my @words = parse_words($trans_fh);

    my $rand = int(rand(100));

    my $chunk_name = expand_wc('chunkX.lab', $rand);
    my $trans_mlf = txt2mlf($chunk_name, @words);
    my $trans_mlf_fn = expand_wc('transX.mlf', $rand);
    open my $trans_mlf_fh, '>:encoding(iso-8859-2)', $trans_mlf_fn or die "Couldn't open $trans_mlf_fn for writing: $!";
    print {$trans_mlf_fh} $trans_mlf;
    close $trans_mlf_fh;

    my $dict = txt2dict(@words);
    my $dict_fn = expand_wc('dictX', $rand);
    open my $dict_fh, '>:encoding(iso-8859-2)', $dict_fn or die "Couldn't open '$dict_fn': $!";
    print {$dict_fh} $dict;
    close $dict_fh;

    if ($audio_fn) {
        my $wav_chunk_fn = expand_wc('chunkX.wav', $rand);
        unlink $wav_chunk_fn;
        system(qq(sox "$audio_fn" "$wav_chunk_fn" trim "$start_pos" "=$end_pos" norm));
        unlink $wav_chunk_fn unless $opt->{keep_temp};
    }

    my $mfc_chunk_fn = expand_wc('chunkX.mfc', $rand);
    unlink $mfc_chunk_fn;
    system(qq(${HTKpath}HCopy -C config-mfcc2mfcc -s ${start_pos}e7 -e ${end_pos}e7 "$mfcc_fn" "$mfc_chunk_fn"));

    my $aligned_fn = expand_wc('alignedX.mlf', $rand);
    unlink $aligned_fn;
    system(qq(LANG=C ${HTKpath}HVite -l '*' -b silence -C config1 -a -H hmmmodel -i $aligned_fn -m -t 500.0 -I "$trans_mlf_fn" -y lab "$dict_fn" phones "$mfc_chunk_fn"));

    my @subs = do {
        open my $aligned_fh, '<', $aligned_fn or die "Couldn't open '$aligned_fn': $!";
        my $splits = [0+$start_pos];
        $splits->[$rand] = 0+$start_pos;  # since we're assigning chunks random numbers, we need to set the offset to the given chunk number
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

    unlink $mfc_chunk_fn, $aligned_fn, $dict_fn, $trans_mlf_fn unless $opt->{keep_temp};

    return {
        data => \@subs,
        success => $success,
    }

}

sub txt2dict {
    my $dict = '';
    my %words;
    $dict .= "silence       sil\n";
    $dict .= "!ENTER       sil\n";
    $dict .= "!EXIT       sil\n";
    for my $w (@_) {
        my $form = $w->{ucform};
        for my $fonet (@{ $w->{fonet_list} }) {
            next if $words{"$form;$fonet"}++;
            $dict .= "$form       $fonet\n";
        }
    }
    return $dict
}

sub txt2mlf {
    my $chunk = shift;
    my $rv = '';
    $rv .= "#!MLF!#\n";
    $rv .= qq{"$chunk"\n};
    $rv .= "!ENTER\n";
    for (@_) {
        $rv .=  $_->{ucform} . "\n";
    }
    $rv .= "!EXIT";
    return $rv
}

my %allowed_non_word = (
    '-' => 1,
    '--' => 1,
    '..' => 1,
    '...' => 1,
);
my %right_glued_non_word = (
    '(' => 1,   # )
    '[' => 1,   # ]
    '{' => 1,   # }
    '`' => 1,   # '
    '``'=> 1,   # ''
);

sub parse_words {
    my ($fh) = @_;
    my $trans = do { local $/; <$fh> };
    
    $trans =~ s/^\s+|\s+$//g;
    
    if ($trans !~ /\w/ and not $allowed_non_word{$trans}) {
        die "Garbage transcription: '$trans'";
    }
    
    $trans =~ s/(?<=\w[,.!?;:])\b/ /g;      # jeden,dva  => jeden, dva
    $trans =~ s/\b\s+([,.!?;:])\b/$1 /g;    # jeden ,dva => jeden, dva
    $trans =~ s/\b\.\.\.\b/... /g;          # jeden...dva => jeden... dva
    my @w = split /\s+/, $trans;
    
    print STDERR "\n\ntrans:$trans\n\n\@w:@w\n\n";
    
    my @words;
    WORD:
    for my $i (0 .. $#w) {
        my $w = $w[$i];
        
        if ($w !~ /\w/ and not $allowed_non_word{$_}) {
            if ($right_glued_non_word{$w}) {
                if (exists $w[$i+1]) {
                    $w[$i+1] = join(' ', $w, $w[$i+1]);
                }
                elsif (@words) {
                    $words[-1]{occurrence} .= " $w";
                }
                else {
                    die "Algorithmic error: garbage transcription ($trans) caught too late"
                }
            }
            else {
                if (@words) {
                    $words[-1]{occurrence} .= " $w";
                }
                elsif (exists $w[$i+1]) {
                    $w[$i+1] = join(' ', $w, $w[$i+1]);
                }
                else {
                    die "Algorithmic error: garbage transcription ($trans) caught too late"
                }
            }
            next WORD
        }
        
        my $ucform = uc occ2form($w);
        push @words, {
            occurrence => $w,
            fonet_list => vyslov($ucform),
            ucform => $ucform,
        };
    }
    return @words
}

sub occ2form {
    for (my ($tmp) = @_) {
        s/\W+//g;
        if (length == 0) {
            return $_[0] if $allowed_non_word{$_};
            die "Non-allowed non-word: $_"
        }
        return lc
    }
}

sub expand_wc {
    my ($wc, $pat) = @_;
    $wc =~ s/X/$pat/;
    return $wc;
}

1
