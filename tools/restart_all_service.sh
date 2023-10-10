set -x
for service in memcached rabbitmq-server mariadb httpd openstack-glance-api \
    neutron-linuxbridge-agent neutron-server neutron-metadata-agent neutron-dhcp-agent  neutron-l3-agent \
    openstack-nova-compute openstack-nova-scheduler openstack-nova-api openstack-nova-novncproxy \
    openstack-cinder-volume openstack-cinder-api openstack-cinder-scheduler
do
    systemctl stop $service
    systemctl start $service
    systemctl is-active $service 
done
