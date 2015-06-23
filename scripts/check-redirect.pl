#!/usr/bin/perl
#
# Check if domains redirect to HTTPS (failure is allowed)

use strict;
use warnings;
use JSON -support_by_pp;
use LWP::UserAgent;
use Data::Dumper;

use threads;
use Thread::Queue;

my $count        = undef;
my $thread_limit = 1;
my $user_agent   = "Chrome 41.0.2228.0";

sub check_redirect {
    my $host = shift;

    my $ua = LWP::UserAgent->new(requests_redirectable => []);
    $ua->agent($user_agent);

    my $req = HTTP::Request->new(GET => "http://$host/");
    my $res = $ua->request($req);

    if ($res) {
        if ($res->code >= 300 or $res->code <= 399) {
            return ($res->code, $res->header('Location'));
        } else {
            return ($res->code, undef);
        }
    } else {
        return (undef, undef);
    }
}

sub derive_state {
    my $domain   = shift;
    my $code     = shift;
    my $location = shift;

    return 'none' if ($code >= 200 and $code <= 299);
    return 'fail' if ($code >= 500 and $code <= 599);

    if ($code >= 300 and $code <= 399) {
        return 'https' if ($location && $location =~ /^https:/);
        return 'self'
          if ($location && $location =~ /^http:\/\/(www\.)?$domain/);
        return 'http' if ($location && $location =~ /^http:/);
    }

    return "unknown";
}

sub check_domain {
    my $domain = shift;

    my $https = 0;

    my $d1 = $domain;
    my $d2 = "www.$domain";

    my ($ret1, $loc1) = check_redirect($d1);
    my ($ret2, $loc2) = check_redirect($d2);

    my $state1 = derive_state($domain, $ret1, $loc1);
    my $state2 = derive_state($domain, $ret2, $loc2);

    if ($state1 eq "https" and $state2 eq "https") {
        $https = 1;
    } elsif ($state1 eq "https" and $state2 eq "fail") {
        $https = 1;
    } elsif ($state1 eq "fail" and $state2 eq "https") {
        $https = 1;
    } elsif ($state1 eq "https" and $state2 eq "self") {
        $https = 1;
    } elsif ($state1 eq "self" and $state2 eq "https") {
        $https = 1;
    }

    my $status = "$state1/$state2";

    my $result = {
        'https' => $https,
        'hosts' => {
            $d1 => { code => $ret1, location => $loc1 },
            $d2 => { code => $ret2, location => $loc2 }
        },
        'status' => $status
    };

    printf STDERR ("%d: %-50s %d/%d %s\n", $https, $domain, $ret1, $ret2,
        $status);
    return $result;
}

my @domains   = ();
my $redirects = {};

while (<>) {
    chomp;
    push @domains, $_;
}

if ($thread_limit == 1) {

    foreach my $domain (@domains) {
        $redirects->{$domain} = check_domain($domain);
        $count--;
        last if ($count == 0);
    }

} else {

    my $queue   = Thread::Queue->new();
    my @threads = map {
        threads->create(
            sub {
                my $redirects = {};
                while (my $item = $queue->dequeue()) {
                    $redirects->{$item} = check_domain($item);
                }
                return $redirects;
            }
        );
    } 1 .. $thread_limit;

    foreach my $domain (@domains) {
        $queue->enqueue($domain);
        $count--;
        last if ($count == 0);
    }

    $queue->enqueue(undef) for 1 .. $thread_limit;

    foreach my $t (@threads) {
        my $r = $t->join();
        foreach my $d (keys %{$r}) {
            $redirects->{$d} = $r->{$d};
        }
    }
}

print to_json($redirects, { pretty => 1 });
