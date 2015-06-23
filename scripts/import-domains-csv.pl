#!/usr/bin/perl

use strict;
use warnings;
use JSON -support_by_pp;
use Net::IDN::Encode ':all';

my $header = <>;

my %domains = ();

while (<>) {
    chomp;

    my @data = split(/\t/);

    my $key = domain_to_ascii($data[0]);

    $domains{$key}{'domain'} = $data[0];
    $domains{$key}{'org'}    = $data[1];
    $domains{$key}{'type'}   = $data[2];
}

print to_json(\%domains, { pretty => 1 });
