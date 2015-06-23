#!/usr/bin/perl

use strict;
use warnings;
use JSON -support_by_pp;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use Getopt::Long;

sub summarize_report {
    my $report   = shift;
    my $domains  = shift;
    my $redirect = shift;

    my @summary = ();

    foreach my $r (@{$report}) {
        my $entry = {};

        my $domain = $r->{host};

        $entry->{fqdn}   = $domain;
        $entry->{domain} = $domains->{$domain}->{domain};
        $entry->{type}   = $domains->{$domain}->{type};
        $entry->{org}    = $domains->{$domain}->{org};

        my @all_https  = ();
        my @all_grades = ();
        my @all_sts    = ();

        foreach my $endpoint (@{ $r->{endpoints} }) {
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

        if (defined $redirect->{$domain}->{'force_https'}) {
            if ($redirect->{$domain}->{'force_https'} == 1) {
                $entry->{force} = 1;
            } else {
                $entry->{force} = 0;
            }
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

GetOptions(
    "report=s"   => \$report_filename,
    "redirect=s" => \$redirect_filename,
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

open(REPORT, "<", $report_filename) or die "Failed to open report";
$json = "";
while (<REPORT>) {
    $json .= $_;
}
close(REPORT);
my $report = decode_json($json);

my $date = $report_filename;
$date =~ s/(.+\/)?(\d{4})(\d{2})(\d{2})-.+/$2-$3-$4/;

my $summary = summarize_report($report, $domains, $redirect);

print to_json({ date => $date, reports => $summary },
    { pretty => 1, utf8 => 1 });
