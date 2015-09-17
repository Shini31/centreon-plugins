#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::a10::mode::sessions;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub tcp {
    my ($class, %options) = @_;
    my $self = $class->SUPER::tcp(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning-tcp:s"       => { name => 'warning_tcp' },
                                  "critical-tcp:s"      => { name => 'critical_tcp' },
                                  "warning-udp:s"       => { name => 'warning_udp' },
                                  "critical-udp:s"      => { name => 'critical_udp' },
                                  "warning-other:s"     => { name => 'warning_other' },
                                  "critical-other:s"    => { name => 'critical_other' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-tcp', value => $self->{option_results}->{warning_tcp})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong tcp warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-udp', value => $self->{option_results}->{warning_udp})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong udp warning threshold '" . $self->{option_results}->{warning_udp} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-other', value => $self->{option_results}->{warning_other})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong other warning threshold '" . $self->{option_results}->{warning_other} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-tcp', value => $self->{option_results}->{critical_tcp})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong tcp critical threshold '" . $self->{option_results}->{critical_tcp} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-udp', value => $self->{option_results}->{critical_udp})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong udp critical threshold '" . $self->{option_results}->{critical_udp} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-other', value => $self->{option_results}->{critical_other})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong other critical threshold '" . $self->{option_results}->{critical_other} . "'.");
        $self->{output}->option_exit();
    }

}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_axSessionGlobalStatTCPEstablished = '.1.3.6.1.4.1.22610.2.4.3.19.1.1.0';
    my $oid_axSessionGlobalStatUDP = '.1.3.6.1.4.1.22610.2.4.3.19.1.3.0';
    my $oid_axSessionGlobalStatOther = '.1.3.6.1.4.1.22610.2.4.3.19.1.5.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_axSessionGlobalStatTCPEstablished, $oid_axSessionGlobalStatUDP,
                                                  $oid_axSessionGlobalStatOther], nothing_quit => 1);

    my $exit1 = $self->{perfdata}->threshold_check(value => $result->{$oid_axSessionGlobalStatTCPEstablished},
                                        threshold => [ { label => 'crit_tcp', 'exit_litteral' => 'critical' }, { label => 'warn_tcp', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $result->{$oid_axSessionGlobalStatUDP},
                                        threshold => [ { label => 'crit_udp', 'exit_litteral' => 'critical' }, { label => 'warn_udp', exit_litteral => 'warning' } ]);
    my $exit3 = $self->{perfdata}->threshold_check(value => $result->{$oid_axSessionGlobalStatOther},
                                        threshold => [ { label => 'crit_other', 'exit_litteral' => 'critical' }, { label => 'warn_other', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("TCP Sessions: %d, UDP Sessions: %d, Other Sessions: %d",
                                                    $result->{$oid_axSessionGlobalStatTCPEstablished},
                                                    $result->{$oid_axSessionGlobalStatUDP},
                                                    $result->{$oid_axSessionGlobalStatOther},));

    $self->{output}->perfdata_add(label => "sessions_tcp",
                                  value => $result->{$oid_axSessionGlobalStatTCPEstablished},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_tcp'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_tcp'),
                                  min => 0);
    $self->{output}->perfdata_add(label => "sessions_udp",
                                  value => $result->{$oid_axSessionGlobalStatUDP},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_udp'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_udp'),
                                  min => 0);
    $self->{output}->perfdata_add(label => "sessions_other",
                                  value => $result->{$oid_axSessionGlobalStatOther},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_other'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_other'),
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the number of tcp/udp/other sessions (A10-AX-MIB).

=over 8

=item B<--warning-tcp>

Threshold warning: number of established TCP sessions.

=item B<--critical-tcp>

Threshold critical: number of established TCP sessions.

=item B<--warning-udp>

Threshold warning: number of UDP sessions.

=item B<--critical-udp>

Threshold critical: number of UDP sessions.

=item B<--warning-other>

Threshold warning: number of other sessions.

=item B<--critical-other>

Threshold critical: number of other sessions.

=back

=cut

