#!/usr/bin/env perl

use warnings;
use strict;

use POE qw(Component::Client::NRPE);
use Time::HiRes ();

use constant NAGIOS_HOST               => $ENV{NAGIOS_HOST} || 'localhost';
use constant NAGIOS_NRPE_CHECK_COMMAND => $ENV{NAGIOS_NRPE_CHECK_COMMAND} || 'check_nagios';

my ($return_code, $result);
my $t0 = [Time::HiRes::gettimeofday];
POE::Session->create(
    inline_states => {
        _start => sub {
            POE::Component::Client::NRPE->check_nrpe(
                host    => NAGIOS_HOST,
                command => NAGIOS_NRPE_CHECK_COMMAND,
                event   => '_result',
            );
            return;
        },
        _result => sub {
            $result = $_[ARG0];
            $return_code = $result->{result};
            return;
        },
    },
);
$poe_kernel->run();

my $status = $return_code =~ /^[01]$/ ? 'OK' : $result->{data};
my $response_time = sprintf('%0.3f', Time::HiRes::tv_interval($t0) * 1000);

print "Content-type: application/xml\n\n";
print "<pingdom_http_custom_check>\n";
print "<status>$status</status>\n";
print "<response_time>$response_time</response_time>\n";
print "</pingdom_http_custom_check>\n";

1; # eof
