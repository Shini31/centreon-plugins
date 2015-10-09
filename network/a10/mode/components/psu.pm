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

package network::a10::mode::components::psu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_psu_status = (
    0 => 'off',
    1 => 'on',
    -1 => 'unknown',
);

my $mapping = {
    asSysXPowerSupplyStatus => { map => \%map_psu_status },
};

my $oid_axSysLowerPowerSupplyStatus = '.1.3.6.1.4.1.22610.2.4.1.5.7.0';
my $oid_axSysUpperPowerSupplyStatus = '.1.3.6.1.4.1.22610.2.4.1.5.8.0';

sub load {
    my (%options) = @_;

    push @{$options{request}}, { oid => $oid_axSysLowerPowerSupplyStatus };
    push @{$options{request}}, { oid => $oid_axSysUpperPowerSupplyStatus };
}

sub check {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_axSysLowerPowerSupplyStatus}})) {
        my $instance = 'Lower';
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_axSysLowerPowerSupplyStatus}, instance => $instance);
        next if ($self->check_exclude(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' status is %s.",
                                                        $instance, $result->{asSysXPowerSupplyStatus}));
        my $exit = $self->get_severity(section => 'psu', value => $result->{asSysXPowerSupplyStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' status is %s", $instance, $result->{asSysXPowerSupplyStatus}));
        }
    }
    foreach my $oid (keys %{$self->{results}->{$oid_axSysUpperPowerSupplyStatus}}) {
        my $instance = 'Upper';
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_axSysUpperPowerSupplyStatus}, instance => $instance);
        next if ($self->check_exclude(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' status is %s.",
                                                        $instance, $result->{asSysXPowerSupplyStatus}));
        my $exit = $self->get_severity(section => 'psu', value => $result->{asSysXPowerSupplyStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power Supply '%s' status is %s", $instance, $result->{asSysXPowerSupplyStatus}));
        }
    }
}

1;
