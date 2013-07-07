class openstack::nagios::nrpe(
    $allowed_hosts = udef,
    $bind_address = '0.0.0.0',
    $libdir = '/usr/lib/',
    $verbose = true,
)
{
    $debug_str= str2bool($verbose) ?{
        true  => '1',
        false => '0', 
        default => '0',
    }
    package{'nagios-nrpe-server':
        ensure => 'present'
    }

    package{'nagios-plugins-extra':
        ensure => 'present',
    }

    file{'/etc/nagios/nrpe.d/openstack_commands.cfg':
        ensure  => 'present',
        content => template('openstack/nagios/openstack_commands.cfg.erb'),
        require => [Package['nagios-nrpe-server'],Package['nagios-plugins-extra']],
        notify  => Exec['nagios-nrpe-server-reload'],
    }

    file{'/etc/nagios/nrpe.cfg':
        ensure  => 'present',
        content => template('openstack/nagios/nrpe.cfg.erb'),
        require => [Package['nagios-nrpe-server'],Package['nagios-plugins-extra']],
        notify  => Exec['nagios-nrpe-server-reload'],
    }

    file{'/etc/nagios/nrpe.d/common_commands.cfg':
        ensure  => 'present',
        content => template('openstack/nagios/common_commands.cfg.erb'),
        require => [Package['nagios-nrpe-server'],Package['nagios-plugins-extra']],
        notify  => Exec['nagios-nrpe-server-reload'],
    }

    service{'nagios-nrpe-server':
        enable     => true,
        ensure     => 'running',
        require    => [Package['nagios-nrpe-server'],Package['nagios-plugins-extra']]
    }

    exec{'nagios-nrpe-server-reload':
        command     => '/etc/init.d/nagios-nrpe-server reload',
        require     => Service['nagios-nrpe-server'],
        refreshonly => true,
        returns     => [0,1],
    }
} 
