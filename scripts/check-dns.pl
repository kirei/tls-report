#!/usr/bin/perl
#
# Copyright (c) 2015 Kirei AB. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
######################################################################
#
# Check various domain DNS properties

use strict;
use warnings;
use Net::DNS;
use JSON -support_by_pp;
use Data::Dumper;

my $resolver = new Net::DNS::Resolver;
$resolver->dnssec(1);
$resolver->adflag(1);
$resolver->usevc(0);
$resolver->persistent_tcp(1);
$resolver->persistent_udp(1);

sub check_dns {
    my $qname = shift;

    my $ipv4 = query_qtype($qname, 'A');
    my $ipv6 = query_qtype($qname, 'AAAA');

    my $tlsa = query_qtype("_443._tcp.$qname", 'TLSA');

    my $dnssec = ($ipv4 and $ipv4->header->ad) or ($ipv6 and $ipv6->header->ad);

    return {
        ipv4   => ($ipv4   ? 1 : 0),
        ipv6   => ($ipv6   ? 1 : 0),
        tlsa   => ($tlsa   ? 1 : 0),
        dnssec => ($dnssec ? 1 : 0),
    };
}

sub query_qtype {
    my $qname = shift;
    my $qtype = shift;

    my $packet = $resolver->query($qname, $qtype);

    if ($packet && $packet->answer) {
        foreach my $rr ($packet->answer) {
            return $packet if ($rr->type eq $qtype);
        }
    }

    return undef;
}

sub check_domain {
    my $domain = shift;

    my $bare = check_dns($domain);
    my $www  = check_dns("www.$domain");

    printf STDERR (
        "ipv4:%d/%d ipv6:%d/%d tlsa:%d/%d dnssec:%d/%d %s\n",
        $bare->{ipv4},   $www->{ipv4},   $bare->{ipv6},
        $www->{ipv6},    $bare->{tlsa},  $www->{tlsa},
        $bare->{dnssec}, $www->{dnssec}, $domain
    );

    return {
        ipv4   => ($bare->{ipv4}   or $www->{ipv4}),
        ipv6   => ($bare->{ipv6}   or $www->{ipv6}),
        tlsa   => ($bare->{tlsa}   or $www->{tlsa}),
        dnssec => ($bare->{dnssec} or $www->{dnssec})
    };
}

my @domains = ();
my $dns     = {};

while (<>) {
    chomp;
    push @domains, $_;
}

foreach my $domain (@domains) {
    $dns->{$domain} = check_domain($domain);
}

print to_json($dns, { pretty => 1 });
