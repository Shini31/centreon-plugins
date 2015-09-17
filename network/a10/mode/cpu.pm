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

package network::a10::mode::cpu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';

    $options{options}->add_options(arguments =>
            {
                "warning:s"       => { name => 'warning', },
                "critical:s"      => { name => 'critical', },
            });
    }

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_axSysAverageCpuUsage = '.1.3.6.1.4.1.22610.2.4.1.3.3.0';
    my $oid_axSysAverageControlCpuUsage = '.1.3.6.1.4.1.22610.2.4.1.3.4.0';
    my $oid_axSysAverageDataCpuUsage = '.1.3.6.1.4.1.22610.2.4.1.3.5.0',

    my $result = $self->{snmp}->get_leef(oids => [$oid_axSysAverageCpuUsage, $oid_axSysAverageControlCpuUsage, $oid_axSysAverageDataCpuUsage], nothing_quit => 1);

    my $exit = $self->{perfdata}->threshold_check(value => $result->{$oid_axSysAverageCpuUsage},
                                              threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Total CPU Usage: %d (Control: %d Data: %d)", $result->{$oid_axSysAverageCpuUsage}, $result->{$oid_axSysAverageControlCpuUsage}, $result->{$oid_axSysAverageDataCpuUsage} ));

    $self->{output}->perfdata_add(label => "cpuTotal", unit => '%',
                                  value => $result->{$oid_axSysAverageCpuUsage},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "cpuControl", unit => '%',
                                  value => $result->{$oid_axSysAverageControlCpuUsage},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "cpuData", unit => '%',
                                  value => $result->{$oid_axSysAverageDataCpuUsage},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0, max => 100);


    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check average cpu usage (A10-AX-MIB).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
