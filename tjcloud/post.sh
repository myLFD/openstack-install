systemctl disable openstack-nova-api.service \
  openstack-nova-consoleauth openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service \

systemctl disable neutron-server.service \
  neutron-linuxbridge-agent.service \
  neutron-dhcp-agent.service \
  neutron-metadata-agent.service \
  neutron-l3-agent.service

systemctl disable mariadb

cp openstack-rc /root
cp variable-ha.sh /root

# 修改nova glance cinder workers数量

openstack-config --set /etc/nova/nova.conf  DEFAULT osapi_compute_workers 1
openstack-config --set /etc/nova/nova.conf  DEFAULT  metadata_workers 1
openstack-config --set /etc/nova/nova.conf conductor workers 1
openstack-config --set /etc/nova/nova.conf scheduler workers 1
 systemctl restart openstack-nova-api.service \
  openstack-nova-consoleauth openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service

openstack-config --set /etc/cinder/cinder.conf cinder osapi_volume_workers  1 osapi_volume_workers  1
systemctl restart openstack-cinder-volume.service target.service openstack-cinder-api.service openstack-cinder-scheduler.service

openstack-config --set /etc/glance/glance-api.conf DEFAULT workers  1
systemctl restart openstack-glance-api.service

openstack-config --set /etc/neutron/neutron.conf DEFAULT api_workers 1
systemctl restart neutron-server.service 