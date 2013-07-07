# [debian_sys_username] used by the debian system to access the mysql service
# [debian_sys_password] used by the debian system to access the mysql service
class openstack::db::server(
    $mysql_root_password,
    $mysql_bind_address,
    $node_address = udef,
    $node_addresses = udef,
    $primary_controller = false,
    $skip_name_resolve = true,
    $cluster_name = 'mysql_cluster',
    $debian_sys_username = 'debian-sys-maint',
    $debian_sys_password = 'WUdFVvekQ1mKJJ1d',
    $enabled = true,
    $setup_multiple_gcomm = true,
    $enabled_ha = false,
){
    if $enabled_ha {
        package {"galera":
            ensure => 'present',
        }

        class {'mysql::server':
            config_hash     => {
                'root_password' => $mysql_root_password,
                'bind_address'  => $mysql_bind_address,
            },
            enabled          => $enabled,
            package_name     => 'mariadb-galera-server',
            service_provider => 'init',
        }

        Database_user['cluster_watcher@%'] -> File['/etc/mysql/conf.d/wsrep.cnf'] 
        Database_user['root@%'] -> File['/etc/mysql/conf.d/wsrep.cnf']

        database_user{'cluster_watcher@%':
            ensure  => 'present',
            require => Service['mysqld']
        }

        database_user{'root@%':
            ensure        => 'present',
            password_hash => mysql_password($mysql_root_password),
            require => Service['mysqld']
        }

        database_grant{'root@%':
            privileges => ['all'],
            require    => Database_user['root@%'],
            before     => File['/etc/mysql/conf.d/wsrep.cnf'],
        }

        file {'/etc/mysql/debian.cnf':
            ensure  => 'present',
            mode    => '400',
            content => template('openstack/mysql_debian.cnf.erb'),
            require => Service['mysqld']
        }

        database_user{"${debian_sys_username}@localhost":
            ensure        => 'present',
            password_hash => mysql_password($debian_sys_password),
            before        => File['/etc/mysql/debian.cnf'],
            require => Service['mysqld']
        }
        database_grant{"${debian_sys_username}@localhost":
            privileges => ['all'],
            require    => Database_user["${debian_sys_username}@localhost"],
            before     => File['/etc/mysql/debian.cnf'],
        }


        file {'/etc/mysql/conf.d/wsrep.cnf':
            ensure  => 'present',
            mode    => '640',
            content => template('openstack/wsrep.cnf.erb'),
            require => [File['/etc/mysql/conf.d/'], Package['galera'], File['/etc/mysql/debian.cnf']],
            notify  => Exec['mysqld-restart'],
        }

        exec { "wait-mysql-sync-state":
            logoutput   => true,
            command     => "/usr/bin/mysql -Nbe \"show status like 'wsrep_local_state_comment'\" | /bin/grep -q Synced && sleep 10",
            try_sleep   => 5,
            tries       => 60,
            refreshonly => true,
            require     => File['/etc/mysql/conf.d/wsrep.cnf'],
            subscribe   => Exec['mysqld-restart'],
        }

        }else {

            # Install and configure MySQL Server
            class { 'mysql::server':
                config_hash => {
                    'root_password' => $mysql_root_password,
                    'bind_address'  => $mysql_bind_address,
                },
                enabled     => $enabled,
            }
        }
}
