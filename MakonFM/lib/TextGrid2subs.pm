package TextGrid2subs;

use strict;
use warnings;
use 5.010;
use utf8;
use Exporter qw(import);
use File::Basename qw(basename);
use Subs qw(encode_subs);

our @EXPORT_OK = qw(files2sub tg2subwords);

sub tg2subwords {
  my ($in_fh, $offset, $humanicity) = @_;
  my ($start, $end, $text);
  my @subwords;
  while (<$in_fh>) {
    next unless /name = "words"/ .. /class = "IntervalTier"/;
    /xmin = ([\d.]+)/ and $start = $1;
    /xmax = ([\d.]+)/ and $end   = $1;
    if (/text = "([^:]+)"/) {
      $text = $1;
      my $len = int(100 * $end - 100 * $start) / 100;
      push @subwords, {
        occurrence => $text,
        wordform => $text,
        timestamp => $start + $offset,
        length => $len,
        ($humanicity ? 'humanic' : 'automatic') => 1,
      };
    }
  }
  return @subwords;
}

sub fn2offset {
  my ($fn) = @_;
  $fn =~ /--from-([^-]+)/;
  if (not $1) {
    warn "unexpected file name '$fn'";
    return 0;
  }
  return $1;
}

sub fn2stem {
  my ($fn) = @_;
  $fn =~ s/--.*//;
  return basename $fn;
}

sub files2sub {
  my ($outdir, @tgfiles) = @_;
  my $prevstem = '';
  my @subwords;
  for my $tgfile (@tgfiles) {
    my $stem = fn2stem($tgfile);
    if ($stem ne $prevstem) {
      flush($outdir, $prevstem, \@subwords);
      @subwords = ();
    }
    my $offset = fn2offset($tgfile);
    open my $tgfh, '<:utf8', $tgfile or die;
    push @subwords, tg2subwords($tgfh, $offset);
    $prevstem = $stem;
  }
  flush($outdir, $prevstem, \@subwords);
}

sub flush {
  my ($outdir, $stem, $words) = @_;
  return if not $stem or not @$words;
  open my $ofh, '>:utf8', "$outdir/$stem.sub.js";
  print {$ofh} encode_subs($words, $stem);
}

'IHS';
