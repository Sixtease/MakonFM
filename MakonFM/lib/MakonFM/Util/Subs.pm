package MakonFM::Util::Subs;

use strict;
use utf8;
use JSON ();
use Template;

sub merge {
    my ($s) = @_;
    my $stem = $s->{filestem};
    my $subconf = MakonFM->config->{subs};
    
    # local
    my $path = MakonFM->econf(qw(subs path));
    my $old_subs = get_subs_local($path, $stem);
    my $merged = merge_subs($s, $old_subs);
    save_subs_local($merged, $path, $stem, $subconf->{jsonp_start}, $subconf->{jsonp_end});
    
    # gs
}

sub get_subs_local {
    my ($path, $stem) = @_;
    my $fn = "$path/$stem.sub.js";
    open my $fh, '<:utf8', $fn or do {
        die("Failed to open file '$fn': $!");
        return
    };
    my $subs_str = do { local $/; <$fh> };
    $subs_str =~ s/.*$/[/m;
    $subs_str =~ s/\}\);\s*\z//;
    undef $@;
    my $subs = eval { JSON->new->decode($subs_str) };
    if (not $subs) {
        die ("JSON parse failed for '$fn': $@");
    }
    return $subs
}

sub save_subs_local {
    my ($subs, $path, $stem, @jsonp) = @_;
    my $fn = "$path/$stem.sub.js";
    open my $fh, '>:utf8', $fn or do {
        die("Failed to open file '$fn' for writing: $!");
        return
    };
    my $jsonp_start;
    Template->new->process(
        \$jsonp[0],
        { stem => $stem },
        \$jsonp_start,
    );
    print {$fh} $jsonp_start, JSON->new->pretty->encode($subs), $jsonp[1];
    close $fh;
}

sub merge_subs {
    my ($s, $old_subs) = @_;
    my $start = $s->{start};
    my $end   = $s->{end};
    if ($s->{subs}[0]{timestamp} < $start) {
        die 'New sub start before chunk start'
    }
    if ($s->{subs}[-1]{timestamp} >= $end) {
        die 'New sub end not before chunk end'
    }
    my $prev = -1;
    my $already_printed_new = 0;
    my @new_subs = map {
        my $ts = $_->{timestamp};
        if ($ts >= $start and $ts < $end) {
            unless ($already_printed_new) {
                $already_printed_new = 1;
                @{$s->{subs}}
            }
            else {
                ()
            }
        }
        else {
            $_
        }
    } @$old_subs;

    return \@new_subs
}

1
