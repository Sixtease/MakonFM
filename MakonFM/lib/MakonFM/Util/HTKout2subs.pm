package MakonFM::Util::HTKout2subs;

# converts from <>

use strict;
use utf8;
use JSON ();
use Encode;
use open qw(:std :utf8);

our $quiet = 0;

sub get_subs {

    my ($splits, $htk_fh) = @_;

    my @chunk_offsets = (0);
    if (ref $splits eq 'ARRAY') {
        @chunk_offsets = @$splits
    }
    elsif (ref $splits eq 'GLOB') {
        while (<$splits>) {
            chomp;
            $chunk_offsets[$.] = $_;
        }
    }


    my $offset = $chunk_offsets[0];
    my @subs;
    my $sent_start = 0;
    HTKLINE:
    while (<$htk_fh>) {
        if (my ($chunk_no) = /^".*?(\d+)/) {
            $offset = $chunk_offsets[$chunk_no];
            print STDERR unless $quiet;
            next HTKLINE
        }
        if (my ($start, $word) = /^(\d+)(?:\s+\S+){3}\s+(\S+)/) {
            my %cur;
            if ($word eq '!!UNK') {
                next HTKLINE
            }
            if ($word eq '!ENTER') {
                $sent_start = 1;
                next HTKLINE
            }
            if ($word eq '!EXIT') {
                $subs[-1]{occurrence} .= '.' if @subs;
                next HTKLINE
            }
            else {
                (my $st = ('0'x7).$start) =~ s/(?=\d{7}$)/./;
                $cur{timestamp} = $offset + $st;
                $cur{occurrence} = $cur{wordform} = lc decode('iso-8859-2', eval qq{"$word"});
                if ($sent_start) {
                    $cur{occurrence} = ucfirst $cur{occurrence};
                    $sent_start = 0;
                }
            }
            push @subs, \%cur if %cur;
        }
        if (my ($phoneme) = /^(?:\d+\s+){2}(\w+)/) {
            $subs[-1]{fonet} .= $phoneme . ' ' unless $phoneme eq 'sil';
            if ($phoneme eq 'sp') {
                my ($start, $stop) = /^(\d+)\s+(\d+)/;
                $subs[-1]{slen} = ($stop - $start) / 1e7 if $start != $stop;
            }
        }
    }
    chop $_->{fonet} for @subs;
    return \@subs
}

sub convert {
    #...; # pass a HTK-out filehandle to get_subs or remove this function
    die('yadda yadda yadda');
    my ($splits_fn, $subfn) = @_;
    
    open my $splits_fh, '<', $splits_fn or die "Couldn't open $splits_fn: $!";
    my @subs = @{get_subs($splits_fh)};
    close $splits_fh;
    
    my $json = JSON->new->pretty;
    my $jsonp_start = MakonFM->config->{subs}{jsonp_start};
    my $jsonp_end   = MakonFM->config->{subs}{jsonp_end};
    $jsonp_start =~ s/\Q[% stem %]/$subfn/;
    print $jsonp_start, $json->encode(\@subs), $jsonp_end;
}

1

__END__
