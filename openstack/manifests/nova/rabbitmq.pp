# This file is copied from nova::rabbitmq. And add the ability to 
# config the rabbit cluster. 
# In the future, may be this is not needed. 

class openstack::nova::rabbitmq(
  $userid       ='guest',
  $password     ='guest',
  $port         ='5672',
  $virtual_host ='/',
  $enabled      = true,
  $cluster = false,
  $cluster_disk_nodes = [],
  $bind_address = 'UNSET',
) {

  # only configure nova after the queue is up
  Class['rabbitmq::service'] -> Anchor<| title == 'nova-start' |>

  if ($enabled) {
    if $userid == 'guest' {
      $delete_guest_user = false
    } else {
      $delete_guest_user = true
      rabbitmq_user { $userid:
        admin     => true,
        password  => $password,
        provider => 'rabbitmqctl',
        require   => Class['rabbitmq::server'],
      }
      # I need to figure out the appropriate permissions
      rabbitmq_user_permissions { "${userid}@${virtual_host}":
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
      }->Anchor<| title == 'nova-start' |>
    }
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  class { 'rabbitmq::server':
    service_ensure           => $service_ensure,
    port                     => $port,
    delete_guest_user        => $delete_guest_user,
    config_cluster           => $cluster,
    cluster_disk_nodes       => $cluster_disk_nodes,
    node_ip_address          => $bind_address,
    wipe_db_on_cookie_change => $cluster,
  }

  if ($cluster) {
       exec{'enable-rabbitmq-ha-policy':
           command  => "rabbitmqctl set_policy ha-all \".*\" '{\"ha-mode\":\"all\"}'",
           require  => Class['rabbitmq::server'],
       }
  }

  if ($enabled) {
    rabbitmq_vhost { $virtual_host:
      provider => 'rabbitmqctl',
      require => Class['rabbitmq::server'],
    }
  }
}
