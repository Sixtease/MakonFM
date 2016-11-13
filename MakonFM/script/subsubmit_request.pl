#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use URI::Escape qw(uri_escape_utf8);

sub get_command_from_params {
    my ($stem, $start, $end, $trans) = @_;
    $trans = uri_escape_utf8($trans);
    return qq(curl 'http://rwis.cz:8080/subsubmit/' -H 'Host: rwis.cz:8080' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Accept-Language: en-US,en;q=0.8,cs;q=0.5,de;q=0.3' -H 'Accept-Encoding: gzip, deflate' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Referer: http://makon.positron.cz/' -H 'Origin: http://makon.positron.cz' --data 'filestem=$stem&start=$start&end=$end&trans=$trans&author=subbot');
}

sub get_params_from_line {
    my ($line) = @_;
    chomp $line;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    my ($filestem, $start, $end, $trans) = split /\s*\|\s*/, $line;
    return ($filestem, $start, $end, $trans);
}

sub get_params_from_copy {
    my ($line) = @_;
    my (undef, $stem, undef, $start, $end, $trans) = split /\t/, $line;
    return ($stem, $start, $end, $trans);
}

sub req {
    my ($line) = @_;
    my @params = get_params_from_copy($line);
    my $command = get_command_from_params(@params);
    system $command;
}

while (<>) {
    req($_);
}
