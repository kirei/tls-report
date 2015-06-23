#!/usr/bin/perl

use strict;
use warnings;
use JSON -support_by_pp;

my $json = "";
while (<>) {
    $json .= $_;
}
my $domains = decode_json($json);

foreach my $domain (sort keys $domains) {
    print $domain, "\n";
}
