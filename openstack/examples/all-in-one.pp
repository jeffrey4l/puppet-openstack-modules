Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
$verbose = true
# A http proxy to speed up the repos
# $apt_proxy = false
$apt_proxy = 'http://172.16.0.1:3128'

## -- NETWORK START -- ##
$public_address = '172.16.0.100'
$public_interface = 'eth0'
$private_interface = 'eth1'

$internal_address = '10.0.0.0/24'
## --  NETWORK END  -- ##

## -- CREDENTIAL START -- ##
$admin_email = 'zhang.lei.fly@gmail.com'
$default_password = 'password'
$admin_password = $default_password
$rabbit_password = $default_password
$keystone_db_password = $default_password
$keystone_admin_token = $default_password
$glance_db_password = $default_password
$glance_user_password = $default_password
$nova_db_password = $default_password
$nova_user_password = $default_password
$secret_key = 'SECRET_KEY'
$cinder_user_password    = $default_password
$cinder_db_password      = $default_password
$quantum_user_password   = $default_password
$quantum_db_password     = $default_password
# mysql
$mysql_root_password = 'admin'
## --  CREDENTIAL END  -- ##

## -- OPENSTACK NETWORK START -- ##
$network_manager         = 'nova.network.manager.FlatDHCPManager'
## --  OPENSTACK NETWORK END  -- ##
## -- HYPERVISOR START -- ##
$libvirt_type = 'qemu'
## --  HYPERVISOR END  -- ##

## -- PUPPET START -- ##
stage{"repos": }
stage{"pre-main": }
stage{'post-main': }
Stage['repos'] -> Stage['pre-main'] -> Stage['main'] -> Stage['post-main']
class {'openstack::repos': 
    latest_mysql => false,
    apt_proxy => $apt_proxy,
    stage        => "repos",
}

node /all-in-one/ {

    class {'openstack::all':
        public_address    => $public_address,
        public_interface  => $public_interface,
        private_interface => $private_interface,
        # credential
        admin_email          => $admin_email,
        admin_password       => $admin_password,
        rabbit_password      => $rabbit_password,
        keystone_db_password => $keystone_db_password,
        keystone_admin_token => $keystone_admin_token,
        glance_db_password   => $glance_db_password,
        glance_user_password => $glance_user_password,
        nova_db_password     => $nova_db_password,
        nova_user_password   => $nova_user_password,
        secret_key           => $secret_key,
        cinder_user_password => $cinder_user_password,
        cinder_db_password   => $cinder_db_password,
        # database
        mysql_root_password => $mysql_root_password,
        # network 
        network_manager => 'nova.network.manager.FlatDHCPManager',
        quantum         => false,
        libvirt_type    => $libvirt_type,
    }

   class{'openstack::auth_file':
       admin_password       => $admin_password,
       keystone_admin_token => $keystone_admin_token,
       controller_node      => $public_address,
   }

}
