class openstack::nagios::hosts(
   $alias, 


)
{
    @@nagios_host { $name:
        ensure     => present,
        #hostgroups => $hostgroup,
        alias      => $::hostname,
        use        => 'default-host',
        address    => $::fqdn,
        host_name  => $::fqdn,
        target     => "/etc/nagios3/conf.d/${::hostname}_hosts.cfg",
    }
}
