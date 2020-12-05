#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;
use Encode qw(encode_utf8 decode_utf8);
use Subs qw(decode_subs);

my $humanic = 1;
my $machine = 1;
if ($ARGV[0] eq '-h') {
  $machine = 0;
  shift;
}
if ($ARGV[0] eq '-m') {
  $humanic = 0;
  shift;
}

my $pattern = decode_utf8 shift;

for my $subfn (@ARGV) {
  my $subs = decode_subs($subfn);
  for my $token (@{ $subs->{data} }) {
    next if not $humanic and $token->{humanic};
    next if not $machine and not $token->{humanic};
    next if $token->{occurrence} !~ /$pattern/i;
    say join(':',
      $subs->{filestem},
      $token->{timestamp},
      ($token->{humanic} ? 'h' : 'm'),
      encode_utf8($token->{occurrence}),
    );
  }
}
