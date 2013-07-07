define haproxy_service($order, $balancers, $virtual_ips, $port, $define_cookies = false, $define_backend = false) {

    case $name {
        "mysqld": {
            $haproxy_config_options = { 'option' => ['mysql-check user cluster_watcher', 'tcplog','clitcpka','srvtcpka'], 'balance' => 'roundrobin', 'mode' => 'tcp', 'timeout server' => '28801s', 'timeout client' => '28801s' }
            $balancermember_options = 'check inter 15s fastinter 2s downinter 1s rise 5 fall 3'
            $balancer_port = 3306
        }

        "vnc-proxy":{
            $haproxy_config_options = { 'option' => ['tcpka'], 'mode' => 'tcp', 
                    'timeout client' => '48h', 'timeout server' => '48h', 
                    'balance' => 'roundrobin'
            }
            $balancermember_options = 'check'
            $balancer_port = 6080
        }

        "horizon": {
            $haproxy_config_options = {
                'option'  => ['forwardfor', 'httpchk', 'httpclose', 'httplog'],
                'rspidel' => '^Set-cookie:\ IP=',
                'balance' => 'roundrobin',
                'cookie'  => 'SERVERID insert indirect nocache',
                'capture' => 'cookie vgnvisitor= len 32'
            }
            $balancermember_options = 'check inter 2000 fall 3'
            $balancer_port = 80
        }
        default: {
            $haproxy_config_options = { 'option' => ['httplog'], 'balance' => 'roundrobin' }
            $balancermember_options = 'check'
            $balancer_port = $port
        }
    }

    haproxy::listen { $name:
        ipaddress        => $virtual_ips,
        ports            => $port,
        options          => $haproxy_config_options,
        collect_exported => false
    }
    haproxy::balancermember { $name:
        listening_service => $name,
        server_names      => hash_keys($balancers),
        ipaddresses       => hash_values($balancers),
        ports             => $balancer_port,
        options           => $balancermember_options,
        define_cookies    => $define_cookies,
    }

}
class openstack::ha_base(
    $controller_internal_addresses,    
    $public_virtual_ip,
    $internal_virtual_ip,
    $public_interface,
    $internal_interface,
    $primary_controller,
)
{
    include haproxy::params
    Haproxy_service {
        balancers => $controller_internal_addresses
    }

    file { '/etc/rsyslog.d/haproxy.conf':
      ensure => present,
      content => '$ModLoad imudp
$UDPServerRun 514
local0.* -/var/log/haproxy.log'
    }
    sysctl::value { 'net.ipv4.ip_nonlocal_bind': value => '1' }

    haproxy_service { 'keystone-admin': order => 20, port => 5000, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'keystone-pub': order => 30, port => 35357, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'nova-ec2-api': order => 40, port => 8773, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'nova-api': order => 50, port => 8774, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }

    if ! $multi_host {
      haproxy_service { 'nova-metadata-api': order => 60, port => 8775, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    }

    haproxy_service { 'cinder-api': order => 70, port => 8776, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'glance-api': order => 80, port => 9292, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }

    if $quantum {
      haproxy_service { 'quantum': order => 85, port => 9696, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    }

    haproxy_service { 'glance-reg': order => 90, port => 9191, virtual_ips => [$internal_virtual_ip]  }
    haproxy_service { 'mysqld': order => 95, port => 3306, virtual_ips => [$public_virtual_ip, $internal_virtual_ip], define_backend => true }
    haproxy_service { 'vnc-proxy': order => 100 , port => 6080, virtual_ips => [$public_virtual_ip] }
    haproxy_service { 'horizon':    order => 15, port => 80, virtual_ips => [$public_virtual_ip], define_cookies => true  }

    if $primary_controller {
      exec { 'create-public-virtual-ip':
        command => "ip addr add ${public_virtual_ip} dev ${public_interface} label ${public_interface}:ka",
        unless  => "ip addr show dev ${public_interface} | grep -w ${public_virtual_ip}",
        before  => Service['keepalived'],
      }

      exec { 'create-internal-virtual-ip':
        command => "ip addr add ${internal_virtual_ip} dev ${internal_interface} label ${internal_interface}:ka",
        unless  => "ip addr show dev ${internal_interface} | grep -w ${internal_virtual_ip}",
        before  => Service['keepalived'],
      }
    }

    class { 'haproxy':
      enable           => true,
      global_options   => $::haproxy::params::global_options,
      defaults_options => merge($::haproxy::params::defaults_options, {'mode' => 'http'}),
      require          => Sysctl::Value['net.ipv4.ip_nonlocal_bind'],
    }

    class { 'keepalived':
      require => Service['haproxy'],
    }

    # TODO: should this be change?
    $public_vrid   = 1
    $internal_vrid = 2

    keepalived::instance { $public_vrid:
      interface => $public_interface,
      virtual_ips => [$public_virtual_ip],
      state    => $primary_controller ? { true => 'MASTER', default => 'BACKUP' },
      priority => $primary_controller ? { true => 101,      default => 100      },
    }
    keepalived::instance { $internal_vrid:
      interface => $internal_interface,
      virtual_ips => [$internal_virtual_ip],
      state    => $primary_controller ? { true => 'MASTER', default => 'BACKUP' },
      priority => $primary_controller ? { true => 101,      default => 100      },
    }
}
