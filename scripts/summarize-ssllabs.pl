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

use strict;
use warnings;
use JSON -support_by_pp;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use Getopt::Long;
use Net::IP qw(:PROC);

sub summarize_report {
    my $report   = shift;
    my $domains  = shift;
    my $redirect = shift;
    my $dns      = shift;

    my @summary = ();

    foreach my $r (@{$report}) {
        my $entry = {};

        my $domain = $r->{host};

        $entry->{fqdn}   = $domain;
        $entry->{domain} = $domains->{$domain}->{domain};
        $entry->{type}   = $domains->{$domain}->{type};
        $entry->{org}    = $domains->{$domain}->{org};

        $entry->{ipv6_warning} = 0;

        my @all_https  = ();
        my @all_grades = ();
        my @all_sts    = ();

        foreach my $endpoint (@{ $r->{endpoints} }) {

            # skip unreachable IPv6 targets
            if ($endpoint->{progress} == -1) {
                if (ip_is_ipv6($endpoint->{ipAddress})) {
                    $entry->{ipv6_warning} = 1;
                    next;
                }
            }

            if ($endpoint->{progress} == 100) {
                push @all_https, 1;
            } else {
                push @all_https, 0;
            }

            if ($endpoint->{grade}) {
                push @all_grades, $endpoint->{grade};
            } else {
                push @all_grades, "";
            }

            if ($endpoint->{details}->{stsResponseHeader}) {
                push @all_sts, 1;
            } else {
                push @all_sts, 0;
            }
        }

        $entry->{https} = get_coherent(1, \@all_https) ? 1 : 0;
        $entry->{grade} = get_coherent(1, \@all_grades);
        $entry->{sts}   = get_coherent(0, \@all_sts) ? 1 : 0;

        if ($entry->{https} == 0 && $entry->{ipv6_warning} == 1) {
            $entry->{ipv6_warning} = 0;
        }

        if ($entry->{ipv6_warning}) {
            print STDERR "$domain IPv6 warning\n";
        }

        if (defined $redirect->{$domain}->{'force_https'}) {
            if ($redirect->{$domain}->{'force_https'} == 1) {
                $entry->{force} = 1;
            } else {
                $entry->{force} = 0;
            }
        }

        if (defined $dns->{$domain}) {
            $entry->{dns} = $dns->{$domain};
        }

        push @summary, $entry;
    }

    return \@summary;
}

sub get_coherent {
    my $exact = shift;
    my $list  = shift;

    my $n = uniq(@{$list});

    if ($exact && $n == 1) {
        return $list->[0];
    }
    if ($n >= 1) {
        return $list->[0];
    }
    return undef;
}

my $report_filename   = undef;
my $domains_filename  = undef;
my $redirect_filename = undef;
my $dns_filename      = undef;

GetOptions(
    "report=s"   => \$report_filename,
    "redirect=s" => \$redirect_filename,
    "dns=s"      => \$dns_filename,
    "domains=s"  => \$domains_filename,
) or die "Error in command line arguments";

my $json = undef;

open(DOMAINS, "<", $domains_filename) or die "Failed to open domains";
$json = "";
while (<DOMAINS>) {
    $json .= $_;
}
close(DOMAINS);
my $domains = decode_json($json);

open(REDIRECT, "<", $redirect_filename) or die "Failed to open redirect";
$json = "";
while (<REDIRECT>) {
    $json .= $_;
}
close(REDIRECT);
my $redirect = decode_json($json);

open(DNS, "<", $dns_filename) or die "Failed to open dns";
$json = "";
while (<DNS>) {
    $json .= $_;
}
close(DNS);
my $dns = decode_json($json);

open(REPORT, "<", $report_filename) or die "Failed to open report";
$json = "";
while (<REPORT>) {
    $json .= $_;
}
close(REPORT);
my $report = decode_json($json);

my $date = $report_filename;
$date =~ s/(.+\/)?(\d{4})(\d{2})(\d{2})-.+/$2-$3-$4/;

my $summary = summarize_report($report, $domains, $redirect, $dns);

print to_json({ date => $date, reports => $summary },
    { pretty => 1, utf8 => 1 });
