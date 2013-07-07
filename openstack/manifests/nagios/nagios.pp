class openstack::nagios::nagios(
    # required
    $htpasswd = {'nagiosadmin' => 'admin'},
    $hostgroups = ['controller-nodes', 'compute-nodes'],
    $templatehost    = {'name'=> 'openstack_host'},
    $templateservice = {'name'=>'openstack_service'},
)
{
    package{'nagios3':
        ensure => 'present',
    }
    package{'nagios-nrpe-plugin':
        ensure => 'present',
    }
    # PNP is a graphing tool for Nagios
    package{'pnp4nagios-bin':
        ensure => 'present',
    }

    file{'/etc/nagios3/htpasswd.users':
        content => template('openstack/nagios/htpasswd.users.erb'),
        require => Package['nagios3', 'nagios-nrpe-plugin']
    }
    file{'/etc/nagios3/conf.d/services_openstack.cfg':
        content => template('openstack/nagios/services_openstack.cfg.erb'),
        require => Package['nagios3', 'nagios-nrpe-plugin']
    }
    file{'/etc/nagios3/conf.d/hostgroups_openstack.cfg':
        content => template('openstack/nagios/hostgroups_openstack.cfg.erb'),
        require => Package['nagios3', 'nagios-nrpe-plugin']
    }

    file{'/etc/nagios3/conf.d/template_openstack.cfg':
        content => template('openstack/nagios/openstack_templates.cfg.erb'),
        require => Package['nagios3', 'nagios-nrpe-plugin']
    }


}
