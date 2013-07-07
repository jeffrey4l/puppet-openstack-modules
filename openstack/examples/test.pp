Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

stage{'stage1':
    before => Stage['main'],
}
node /controller/ {

    class{"openstack::ha_base":
        controller_internal_addresses => "10.1.0.10",
        public_virtual_ip             => '172.16.0.10',
        internal_virtual_ip           => '10.1.0.10',
        public_interface              => 'eth0',
        internal_interface            => 'eth1',
        primary_controller            => true,
        stage                         => 'stage1',
    }

}
