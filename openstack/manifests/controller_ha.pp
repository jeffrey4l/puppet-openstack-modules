class openstack::controller_ha (
    $public_virtual_ip,
    $internal_virtual_ip,
    $controller_internal_addresses,
    $primary_controller,
    $public_interface,
    $internal_interface,
    # Required Network
    $public_address, 
    $internal_address,
    $public_interface,
    $private_interface,
    $fixed_range,
    $admin_email,
    $bind_address,
    # Deploy Structure
    $multi_host,
    # required password
    $admin_password,
    $mysql_root_password,
    $keystone_db_password,
    $keystone_admin_token,
    $glance_db_password,
    $glance_user_password,
    $nova_db_password,
    $nova_user_password,
    $secret_key,
    # glance 
    $glance_api_servers,
    # RabbitMQ
    $rabbit_hosts = ['127.0.0.1'],
    $rabbit_password,
    $verbose = false,
) {


    # set the global Exec path
    Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }


    Exec['wait-mysql-sync-state'] -> Exec['wait-for-haproxy-mysql-backend']
    Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'keystone-manage db_sync' |>
    Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'glance-manage db_sync' |>
    Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'cinder-manage db_sync' |>
    Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'nova-db-sync' |>
    Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-scheduler' |>
    Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-volume' |>
    Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-api' |>


    package { 'socat': ensure => present }
    exec { 'wait-for-haproxy-mysql-backend':
      command   => "echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep -q '^mysqld,BACKEND,.*,UP,'",
      path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
      require   => [Service['haproxy'], Package['socat']],
      try_sleep => 5,
      tries     => 60,
    }


    class {'openstack::controller':
      # Required Network
      public_address    => $public_virtual_ip,
      internal_address  => $internal_virtual_ip,
      admin_address     => $internal_virtual_ip,
      public_interface  => $public_interface,
      private_interface => $private_interface,
      admin_email       => $admin_email,
      bind_address      => $bind_address,
      # required password
      admin_password       => $admin_password,
      rabbit_password      => $rabbit_password,
      keystone_db_password => $keystone_db_password,
      keystone_admin_token => $keystone_admin_token,
      glance_db_password   => $glance_db_password,
      glance_user_password => $glance_user_password,
      nova_db_password     => $nova_db_password,
      nova_user_password   => $nova_user_password,
      secret_key           => $secret_key,
      # Database
      db_host             => $internal_virtual_ip,
      mysql_bind_address  => $internal_address,
      mysql_root_password => $mysql_root_password,
      enabled_ha          => true,
      # VNC
      vncproxy_host        => $bind_address,
#      # cinder and quantum password are not required b/c they are
#      # optional. Not sure what to do about this.
#      $cinder_user_password    = 'cinder_pass',
#      $cinder_db_password      = 'cinder_pass',
#      $quantum_user_password   = 'quantum_pass',
#      $quantum_db_password     = 'quantum_pass',
#      # Keystone
#      $keystone_db_user        = 'keystone',
#      $keystone_db_dbname      = 'keystone',
#      $keystone_admin_tenant   = 'admin',
#      $region                  = 'RegionOne',
#      # Glance
#      $glance_db_user          = 'glance',
#      $glance_db_dbname        = 'glance',
       glance_api_servers      => $glance_api_servers,
#      # Nova
#      $nova_admin_tenant_name  = 'services',
#      $nova_admin_user         = 'nova',
#      $nova_db_user            = 'nova',
#      $nova_db_dbname          = 'nova',
#      $purge_nova_config       = true,
#      $enabled_apis            = 'ec2,osapi_compute,metadata',
#      # Network
#      $internal_address        = false,
#      $admin_address           = false,
#      $network_manager         = 'nova.network.manager.FlatDHCPManager',
       fixed_range              => $fixed_range,
#      $floating_range          = false,
#      $create_networks         = true,
#      $num_networks            = 1,
       multi_host               => $multi_host,
#      $auto_assign_floating_ip = false,
#      $network_config          = {},
       # Rabbit
#      $rabbit_user             = 'nova',
#      $rabbit_virtual_host     = '/',
       rabbit_hosts         => $rabbit_hosts,
       cluster              => true,
       cluster_disk_nodes   => keys($controller_internal_addresses),
#      # Horizon
#      $horizon                 = true,
#      $cache_server_ip         = '127.0.0.1',
#      $cache_server_port       = '11211',
#      $horizon_app_links       = undef,
#      $swift                   = false,
#      # VNC
#      $vnc_enabled             = true,
#      # General
       verbose                 => $verbose,
#      # cinder
#      # if the cinder management components should be installed
#      $cinder                  = true,
#      $cinder_db_user          = 'cinder',
#      $cinder_db_dbname        = 'cinder',
#      # quantum
#      $quantum                 = false,
#      $quantum_db_user         = 'quantum',
#      $quantum_db_dbname       = 'quantum',
#      $enabled                 = true
       primary_controller => $primary_controller,
       node_addresses     =>  hash_values($controller_internal_addresses),
       cluster_name       => 'mysql_cluster',
       node_address       => $bind_address,
    }

}
