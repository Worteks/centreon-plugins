#
# Copyright 2020 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::bluemind::local::mode::mapi;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;

sub prefix_mapi_output {
    my ($self, %options) = @_;
    
    return 'MAPI requests ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bm_mapi', type => 0, cb_prefix_output => 'prefix_mapi_output' }
    ];
    
    $self->{maps_counters}->{bm_mapi} = [
        { label => 'calls-received-success', nlabel => 'mapi.calls.received.success.count', display_ok => 0, set => {
                key_values => [ { name => 'calls_success', diff => 1 } ],
                output_template => 'success calls received: %s',
                perfdatas => [
                    { value => 'calls_success', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'calls-received-failed', nlabel => 'mapi.calls.received.failure.count', set => {
                key_values => [ { name => 'calls_failure', diff => 1 } ],
                output_template => 'failure calls received: %s',
                perfdatas => [
                    { value => 'calls_failure', template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # bm-mapi.requestCount,status=failure,meterType=Counter count=25
    # bm-mapi.requestCount,status=success,meterType=Counter count=2477
    my $result = $options{custom}->execute_command(
        command => 'curl --unix-socket /var/run/bm-metrics/metrics-bm-mapi.sock http://127.0.0.1/metrics',
        filter => 'requestCount'
    );

    $self->{bm_mapi} = {};
    foreach (keys %$result) {
        $self->{bm_mapi}->{'calls_' . $1} = $result->{$_}->{count} if (/bm-mapi.requestCount.*status=(failure|success)/);
    }

    $self->{cache_name} = 'bluemind_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check MAPI requests.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'calls-received-success', 'calls-received-failed'.

=back

=cut
