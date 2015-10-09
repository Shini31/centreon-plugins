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

package network::a10::mode::storage;

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
            "warning:s"     => { name => 'warning' },
            "critical:s"    => { name => 'critical' },
        });

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

    my $oid_axSysDiskTotalSpace = '.1.3.6.1.4.1.22610.2.4.1.4.1.0'; # in MBytes
    my $oid_axSysDiskFreeSpace = '.1.3.6.1.4.1.22610.2.4.1.4.2.0'; # in MBytes

    my $result = $self->{snmp}->get_leef(oids => [$oid_axSysDiskFreeSpace, $oid_axSysDiskTotalSpace],
                                         nothing_quit => 1);
    my $disk_free = ($result->{$oid_axSysDiskFreeSpace} * 1024) * 1024;
    my $disk_total = ($result->{$oid_axSysDiskTotalSpace} * 1024) * 1024;
    my $disk_used = $disk_total - $disk_free;

    my $disk_percent_used = ($disk_used / $disk_total) * 100;

    my $exit = $self->{perfdata}->threshold_check(value => $disk_percent_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($disk_used_value, $disk_used_unit) = $self->{perfdata}->change_bytes(value => $disk_used);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Storage used %s (%.2f%%)",
                                $disk_used_value . " " . $disk_used_unit, $disk_percent_used));

    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $disk_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $disk_total, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $disk_total, cast_int => 1),
                                  min => 0, max => $disk_total,
                                  );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check storage usage (A10-AX-MIB).

=over 8

=item B<--warning>

Threshold warning in %.

=item B<--critical>

Threshold critical in %.

=back

=cut
