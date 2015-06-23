#!/usr/bin/perl

use strict;
use warnings;
use JSON -support_by_pp;

my $json = "";
while (<>) {
    $json .= $_;
}
my $domains = decode_json($json);

binmode(STDOUT, ":utf8");

foreach my $key (sort keys $domains) {
    print join("\t",
        $domains->{$key}->{'domain'},
        $domains->{$key}->{'org'},
        $domains->{$key}->{'type'}),
      "\n";
}
