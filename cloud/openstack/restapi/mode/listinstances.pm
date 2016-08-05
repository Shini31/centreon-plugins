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

package cloud::openstack::restapi::mode::listinstances;

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
            "exclude:s"     => { name => 'exclude' },
            "tenant-id:s"   => { name => 'tenant_id' },
        });

    $self->{instance_infos} = ();
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{tenant_id}) || $self->{option_results}->{tenant_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --tenant-id option.");
        $self->{output}->option_exit();
    }
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{status}}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping ${options{status}} instance."));
        return 1;
    }
    return 0;
}

sub listinstance_request {
    my ($self, %options) = @_;

    my $urlpath = "/v2/".$self->{option_results}->{tenant_id}."/servers/detail";
    my $port = '8774';

    my $instanceapi = $options{custom};
    my $webcontent = $instanceapi->api_request(urlpath => $urlpath,
                                                port => $port,);

    foreach my $val (@{$webcontent->{servers}}) {
        my $instancestate;
        if ($val->{status} eq "ACTIVE") {
            next if ($self->check_exclude(status => 'Running'));
            $instancestate = $val->{status};
        } elsif ($val->{status} eq "SUSPENDED" || $val->{status} eq "PAUSED") {
            next if ($self->check_exclude(status => 'Paused'));
            $instancestate = $val->{status};
        } elsif ($val->{status} eq  "SHUTOFF") {
            next if ($self->check_exclude(status => 'Off'));
            $instancestate = $val->{status};
        } elsif ($val->{status} eq "REBUILD" || $val->{status} eq "HARD_REBOOT") {
            next if ($self->check_exclude(status => 'Reboot'));
            $instancestate = $val->{status};
        }
        my $instancename = $val->{name};
        $self->{instance_infos}->{$instancename}->{id} = $val->{id};
        $self->{instance_infos}->{$instancename}->{zone} = $val->{'OS-EXT-AZ:availability_zone'};
        $self->{instance_infos}->{$instancename}->{compute} = $val->{'OS-EXT-SRV-ATTR:host'};
        $self->{instance_infos}->{$instancename}->{osname} = $val->{'OS-EXT-SRV-ATTR:instance_name'};
        $self->{instance_infos}->{$instancename}->{state} = $instancestate;
    }
}

sub disco_format {
    my ($self, %options) = @_;

    my $names = ['name', 'id', 'zone', 'compute', 'osname', 'state'];
    $self->{output}->add_disco_format(elements => $names);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->listinstance_request(%options);

    foreach my $instancename (keys %{$self->{instance_infos}}) {
        $self->{output}->add_disco_entry(name => $instancename,
                                         id => $self->{instance_infos}->{$instancename}->{id},
                                         zone => $self->{instance_infos}->{$instancename}->{zone},
                                         compute => $self->{instance_infos}->{$instancename}->{compute},
                                         osname => $self->{instance_infos}->{$instancename}->{osname},
                                         state => $self->{instance_infos}->{$instancename}->{state},
                                        );
    }
}

sub run {
    my ($self, %options) = @_;

    $self->listinstance_request(%options);

    foreach my $instancename (keys %{$self->{instance_infos}}) {
        $self->{output}->output_add(long_msg => sprintf("%s [id = %s, zone = %s, compute = %s, osname = %s, state = %s]",
                                                        $instancename,
                                                        $self->{instance_infos}->{$instancename}->{id},
                                                        $self->{instance_infos}->{$instancename}->{zone},
                                                        $self->{instance_infos}->{$instancename}->{compute},
                                                        $self->{instance_infos}->{$instancename}->{osname},
                                                        $self->{instance_infos}->{$instancename}->{state}));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List instances:');

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();

    exit 0;
}

1;

__END__

=head1 MODE

List OpenStack instances through Compute API V2

=over 8

=item B<--tenant-id>

Set Tenant's ID

=item B<--exlude>

Exclude specific instance's state (comma seperated list) (Example: --exclude=Running)

=back

=cut
