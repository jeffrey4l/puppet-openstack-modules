## -- COMMON SETTING -- ##
Exec { 
    path      => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
    logoutput => true,
}
$verbose = true
$apt_proxy = false
## -- NETWORK START --  ##
$public_interface = 'eth0'
$internal_interface = 'eth1'
$fixed_range = '10.0.0.0/24'
 # reuse the internal interface. In practice, this interface should use another
 # one.
$private_interface = $internal_interface
$public_virtual_ip = '172.16.0.10'
$internal_virtual_ip = '10.1.0.10'
## -- NETWORK END --  ##

## -- IP SETTING START -- ##
$mysql_address=$internal_virtual_ip
$keystone_address=$public_virtual_ip
$vncproxy_host=$public_virtual_ip

## -- IP SETTING END -- ##


## -- CREDENTIAL START -- ## 
$admin_email = 'zhang.lei.fly@gmail.com'
$admin_password = 'password'
$rabbit_password = 'rabbit'
$mysql_root_password = 'admin'
$keystone_db_password = 'keystone'
$keystone_admin_token = 'keystone'
$glance_db_password = 'glance'
$glance_user_password = 'glance'
$nova_db_password = 'nova'
$nova_user_password = 'nova'
$secret_key = "ADMIN"
## -- CREDENTIAL END -- ##

## -- OPENSTACK START -- ##
$network_manager = 'nova.network.manager.FlatDHCPManager'
$libvirt_type = 'qemu'
## --  OPENSTACK END  -- ##

## -- DEPLOY STRUCTURE START -- ##
$multi_host = true
## -- DEPLOY STRUCTURE END -- ##


## -- NODE INFOS -- ##
$nodes = [
  {
    'name' => 'controller1',
    'role' => 'primary-controller',
    'internal_address' => '10.1.0.11',
    'public_address'   => '172.16.0.11',
  },
  {
    'name' => 'controller2',
    'role' => 'controller',
    'internal_address' => '10.1.0.12',
    'public_address'   => '172.16.0.12',
  },
  {
    'name' => 'controller3',
    'role' => 'controller',
    'internal_address' => '10.1.0.13',
    'public_address'   => '172.16.0.13',
  },
  {
    'name' => 'compute1',
    'role' => 'compute',
    'internal_address' => '10.1.0.20',
    'public_address'   => '172.16.0.20',
  },
  {
    'name' => 'compute2',
    'role' => 'compute',
    'internal_address' => '10.1.0.21',
    'public_address'   => '172.16.0.21',
  },
]
$node = filter_nodes($nodes,'name',$::hostname)

if empty($node) {
  fail("Node $::hostname is not defined in the hash structure")
}
$controllers = merge_arrays(filter_nodes($nodes,'role','primary-controller'), 
    filter_nodes($nodes,'role','controller'))
$controller_public_addresses = nodes_to_hash($controllers,'name','public_address')
$controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
$controller_hostnames = keys($controller_internal_addresses)
$controller_addresses = values($controller_internal_addresses)

if $node[0]['role'] == 'primary-controller' {
    $primary_controller = true
} else {
    $primary_controller = false
}
 # address that openstack service/middleware bind to
$bind_address = $node[0]['internal_address']

$rabbit_hosts = $controller_addresses
$glance_api_servers = "${public_virtual_ip}:9292"
## -- NODE INFOS -- ##


## -- CONFIGURE END -- ##


## -- PUPPET START -- ##
stage{"repos": }
stage{"pre-main": }
stage{'post-main': }
Stage['repos'] -> Stage['pre-main'] -> Stage['main'] -> Stage['post-main']
class {'openstack::repos': 
    stage     => "repos",
    apt_proxy => $apt_proxy,
}
    
node /controller/{

    class{'openstack::ha_base':
        controller_internal_addresses => $controller_internal_addresses,
        public_virtual_ip             => $public_virtual_ip,
        internal_virtual_ip           => $internal_virtual_ip,
        public_interface              => $public_interface,
        internal_interface            => $internal_interface,
        primary_controller            => $primary_controller,
        stage                         => 'pre-main',
    }
   class{'openstack::controller_ha':
       public_virtual_ip             => $public_virtual_ip,
       internal_virtual_ip           => $internal_virtual_ip,
       internal_interface            => $internal_interface,
       controller_internal_addresses => $controller_internal_addresses,
       primary_controller            => $primary_controller,

       public_address    => $node[0]['public_address'],
       internal_address  => $node[0]['internal_address'],
       fixed_range       => $fixed_range,
       public_interface  => $public_interface,
       private_interface => $private_interface,
       admin_email       => $admin_email,
       bind_address      => $bind_address,
       # Deploy Structure
       multi_host        => $multi_host,
       # Password Required
       admin_password       => $admin_password,
       mysql_root_password  => $mysql_root_password,
       keystone_db_password => $keystone_db_password ,
       keystone_admin_token => $keystone_admin_token ,
       glance_db_password   => $glance_db_password ,
       glance_user_password => $glance_user_password ,
       nova_db_password     => $nova_db_password ,
       nova_user_password   => $nova_user_password ,
       secret_key           => $secret_key ,
       glance_api_servers   => $glance_api_servers,
       # RabbitMQ
       rabbit_password      => $rabbit_password ,
       rabbit_hosts         => $rabbit_hosts,
   }

   class{'openstack::auth_file':
       admin_password       => $admin_password,
       keystone_admin_token => $keystone_admin_token,
       controller_node      => $public_virtual_ip,
   }

}

node /compute/{

    class{"openstack::compute":
        # network
        internal_address  => $node[0]['internal_address'],
        public_interface  => $public_interface,
        private_interface => $private_interface,
        network_manager   => $network_manager,
        # glance
        glance_api_servers => $glance_api_servers,
        # nova
        nova_user_password => $nova_user_password,
        sql_connection     => "mysql://nova:${nova_db_password}@${mysql_address}/nova",
        multi_host         => $multi_host,
        fixed_range        => $fixed_range,
        # keystone
        keystone_host => $keystone_address,
        # rabbitmq
        rabbit_hosts  => $rabbit_hosts,
        rabbit_password    => $rabbit_password,
        # virtualization
        libvirt_type => $libvirt_type,
        # vnc
        vncproxy_host     => $vncproxy_host,
        vncserver_listen  => '0.0.0.0',
        # general 
        migration_support => true,
        verbose           => $verbose,
    }
}
