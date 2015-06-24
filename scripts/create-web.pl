#!/usr/bin/perl

use strict;
use warnings;
use JSON -support_by_pp;
use Getopt::Long;
use Data::Dumper;

sub output_table {
    my $summary      = shift;
    my $language     = shift;
    my $translations = shift;

    $language = "en" unless ($language);

    binmode(STDOUT, ":utf8");

    foreach my $entry (@{$summary}) {
        my $grade         = $entry->{grade};
        my $grade_class   = undef;
        my $general_class = undef;

        if ($grade =~ /^A/) {
            $grade_class = "grade-a";
        } elsif ($grade =~ /^B/) {
            $grade_class = "grade-b";
        } elsif ($grade =~ /^C/) {
            $grade_class = "grade-c";
        } elsif ($grade =~ /^F/) {
            $grade_class = "grade-f";
        } elsif ($grade =~ /^T/) {
            $grade_class = "grade-t";
        } else {
            $grade_class = "grade-x";
            $grade       = "X";
        }

        if ($entry->{https} == 1 and $entry->{force} == 1) {
            $general_class = "green";
        } elsif ($entry->{https} == 1 and $entry->{force} == 0) {
            $general_class = "yellow";
        } elsif ($entry->{https} == 0 and $entry->{force} == 0) {
            $general_class = "red";
        } else {
            $general_class = "unknown";
        }

        printf("<tr>\n");
        printf("<td>%s</td>\n", $entry->{domain});
        printf("<td>%s</td>\n", $entry->{org});

        my $type = $entry->{type};
        if ($translations and $translations->{$language}->{$type}) {
            $type = $translations->{$language}->{$type};
        }
        printf("<td>%s</td>\n", $type);

        printf("<td><div class=\"%s\">%s</div></td>\n",
            $general_class, yes_or_no($language, $entry->{https}));
        printf("<td><div class=\"%s\">%s</div></td>\n",
            $general_class, yes_or_no($language, $entry->{force}));

        printf("<td><div class=\"%s\"><a href=\"%s\">%s</a></div></td>\n",
            $grade_class, ssllabs_link($entry->{fqdn}), $grade);

        printf("</tr>\n");
    }
}

sub yes_or_no {
    my $lang = shift;
    my $arg  = shift;

    if (defined $arg) {
        if ($lang eq "en") {
            return $arg ? "Yes" : "No";
        } elsif ($lang eq "sv") {
            return $arg ? "Ja" : "Nej";
        } else {
            return $arg;
        }
    } else {
        return "";
    }
}

sub ssllabs_link {
    my $domain = shift;

    my $href =
      sprintf("https://www.ssllabs.com/ssltest/analyze.html?d=%s", $domain);

    return $href;
}

my $template = undef;
my $summary  = undef;
my $language = undef;
my $i18n     = undef;

GetOptions(
    "template=s" => \$template,
    "summary=s"  => \$summary,
    "language=s" => \$language,
    "i18n=s"     => \$i18n,
) or die "Error in command line arguments";

my $json = "";
open(SUMMARY, "<", $summary) or die "Failed to open summary";
while (<SUMMARY>) {
    $json .= $_;
}
close(SUMMARY);
my $data = decode_json($json);

my $translations = undef;
if ($i18n and -f $i18n) {
    my $json = "";
    open(I18N, "<", $i18n) or die "Failed to open i18n";
    while (<I18N>) {
        $json .= $_;
    }
    close(I18N);
    $translations = decode_json($json);
}

open(TEMPLATE, "<", $template) or die "Failed to open template";
while (<TEMPLATE>) {
    if (/REPORT_PLACEHOLDER/) {
        output_table($data->{reports}, $language, $translations);
    } elsif (/DATE_PLACEHOLDER/) {
        print $data->{date}, "\n";
    } else {
        print;
    }
}
close(TEMPLATE);
