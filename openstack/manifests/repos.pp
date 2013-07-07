class openstack::repos (
    $rabbit_location = "http://www.rabbitmq.com/debian/",
    $mariadb_location = "http://ftp.yz.yamagata-u.ac.jp/pub/dbms/mariadb/repo/5.5/ubuntu",
    $cloud_location  = 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
    # $cloud_location = 'http://aws.xcodest.me:81/ubuntu/',
    $latest_mysql = true,
    $latest_rabbitmq = true,
    $apt_proxy = false,
)
{
    if $apt_proxy{
        file{'/etc/apt/apt.conf.d/00aptproxy':
            ensure  => 'present',
            content => template('openstack/repos/00aptproxy.erb'),
        }

        File['/etc/apt/apt.conf.d/00aptproxy'] -> Apt::Source <| |>
    }

    Apt::Source <| |> -> Apt::Pin <| |> 

    if $latest_rabbitmq {
        apt::source {"rabbitmq-latest":
            location    => $rabbit_location,
            release     => "testing",
            repos       => "main",
            key         => "056E8E56",
            key_content => template('openstack/repos/rabbitmq-pub-key.asc.erb'),
            include_src => false,
        }
    }
    if $latest_mysql {
        apt::source {"mariadb":
            location    => $mariadb_location,
            release     => "precise",
            repos       => "main",
            key         => "1BB943DB",
            key_content => template('openstack/repos/mariadb-pub-key.asc.erb'),
            include_src => false,
        }

        apt::pin {"mariadb-release":
            order      => 20,
            priority   => 1001,
            originator => "MariaDB"
        }
    }

    apt::source {'ubuntu-cloud-archive':
        /*location  => 'http://ppa.launchpad.net/ubuntu-cloud-archive/grizzly-staging/ubuntu',*/
        location    => $cloud_location,
        release     => 'precise-updates/grizzly',
        repos       => 'main',
        key         => '9F68104E',
        key_content => template('openstack/repos/canonical-cloud-archive-pub-key.asc.erb'),
        include_src => false,
    }

      if !defined(Class['apt::update']) {
        class { 'apt::update': stage => $::openstack::repos::stage }
      }
}
