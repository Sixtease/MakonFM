package MakonFM::Util::Subs;

use strict;
use utf8;
use JSON ();
use Template;

sub merge {
    my ($s) = @_;
    my $stem = $s->{filestem};
    
    my $old_subs = get_subs_local($stem);
    my $use_local = $old_subs ? 1 : 0;
    if (!$use_local) {
        $old_subs = get_subs_gs($stem);
    }
    if (!$old_subs) {
        die "Could not get subtitles either from local disk or from GS"
    }
    
    my $merged = merge_subs($s, $old_subs);
    my $merged_jsonp = subs_to_jsonp($merged);
    
    if ($use_local) {
        save_subs_local($merged);
    }
    save_subs_gs($merged, $stem);
}

sub get_subs_local {
    my ($stem) = @_;
    my $path = MakonFM->econf(qw(subs path));
    my $fn = "$path/$stem.sub.js";
    open my $fh, '<:utf8', $fn or do {
        warn("Failed to open file '$fn': $!");
        return
    };
    my $subs_str = do { local $/; <$fh> };
    return subs_from_jsonp($subs_str)
}

sub get_subs_gs {
    my ($stem) = @_;
    my $c = MakonFM->config;
    my $url = $c->{subs}{gs_root} . "$stem.sub.js";
    my $get_subs_command = qq($c->{paths}{gsutil}gsutil cat "$url");
    my $subs_str = `$get_subs_command`;
    if (!$subs_str) {
        warn "Failed to get subs from GS: $!";
        return
    }
    return subs_from_jsonp($subs_str)
}

sub save_subs_local {
    my ($subs) = @_;
    my $stem = $subs->{filestem};
    my $subs_jsonp = subs_to_jsonp($subs);
    my $path = MakonFM->econf(qw(subs path));
    my $fn = "$path/$stem.sub.js";
    open my $fh, '>:utf8', $fn or do {
        die("Failed to open file '$fn' for writing: $!");
        return
    };
    print {$fh} $subs_jsonp;
    close $fh;
}

sub save_subs_gs {
    my ($subs) = @_;
    my $stem = $subs->{filestem};
    my $subs_jsonp = subs_to_jsonp($subs);
    my $c = MakonFM->config;
    my $url = $c->{subs}{gs_root} . "$stem.sub.js";
    
    $SIG{CHLD} = 'IGNORE'; # FIXME
    my $forked = fork();
    if (not defined $forked) {
        die "Fork failed: $!"
    }
    elsif ($forked == 0) {
        open my $gs_fh, '|-', qq($c->{paths}{gsutil}gsutil cp - "$url") or do {
            warn 'Failed to open gsutil command for piping';
            return
        };
        print {$gs_fh} $subs_jsonp;
        close $gs_fh;
    }
}

sub merge_subs {
    my ($new_subs, $old_subs) = @_;
    my $start = $new_subs->{start};
    my $end   = $new_subs->{end};
    if ($new_subs->{data}[0]{timestamp} < $start) {
        die 'New sub start before chunk start'
    }
    if ($new_subs->{data}[-1]{timestamp} >= $end) {
        die 'New sub end not before chunk end'
    }
    my $prev = -1;
    my $already_printed_new = 0;
    my @new_sublist = map {
        my $ts = $_->{timestamp};
        if ($ts >= $start and $ts < $end) {
            unless ($already_printed_new) {
                $already_printed_new = 1;
                @{$new_subs->{data}}
            }
            else {
                ()
            }
        }
        else {
            $_
        }
    } @{ $old_subs->{data} };

    return { %$new_subs, data => \@new_sublist }
}

sub subs_to_jsonp {
    my ($subs) = @_;
    my $jsonp_start = MakonFM->config->{subs}{jsonp_start};
    my $jsonp_end   = MakonFM->config->{subs}{jsonp_end};
    my $jsonp_start_exp;
    Template->new->process(
        \$jsonp_start,
        { stem => $subs->{filestem} },
        \$jsonp_start_exp,
    );
    return join '', $jsonp_start_exp, JSON->new->pretty->encode($subs->{data}), $jsonp_end
}

sub subs_from_jsonp {
    my ($subs_jsonp) = @_;
    $subs_jsonp =~ s/^[^{]+//;
    $subs_jsonp =~ s/[^}]+$//;
    undef $@;
    my $subs = eval { JSON->new->decode($subs_jsonp) };
    if (not $subs) {
        die ("JSON parse failed: $@");
    }
    return $subs
}

1
