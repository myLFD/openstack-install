#!/bin/bash -e
set -x


yum install -y lvm2 device-mapper-persistent-data 


source openstack-rc



yum install -y openstack-cinder targetcli 



cp  /etc/cinder/cinder.conf  /etc/cinder/cinder.conf.bak
openstack-config --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:loongson@$vip:3307/cinder

openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,openstack:loongson@controller2:5672,openstack:loongson@controller3:5672
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy  keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip $controller
openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends  ceph
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers  http://$vip:9293

openstack-config --set /etc/cinder/cinder.conf keystone_authtoken www_authenticate_uri  http://$vip:5001
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url  http://$vip:5001
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers  controller1:11211,controller2:11211,controller3:11211
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_type  password
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name  default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name  default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name  service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username  cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password  loongson

openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

openstack-config --set /etc/cinder/cinder.conf lvm volume_driver  cinder.volume.drivers.lvm.LVMVolumeDriver
openstack-config --set /etc/cinder/cinder.conf lvm volume_group  cinder-volumes
openstack-config --set /etc/cinder/cinder.conf lvm target_protocol  iscsi
openstack-config --set /etc/cinder/cinder.conf lvm target_helper  lioadm
openstack-config --set /etc/cinder/cinder.conf lvm volume_backend_name LVM



#Populate the Block Storage database


egrep -v "^#|^$" /etc/cinder/cinder.conf

openstack-config --set /etc/nova/nova.conf cinder os_region_name  RegionOne
systemctl restart openstack-nova-api.service

systemctl enable openstack-cinder-volume.service target.service openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl restart openstack-cinder-volume.service target.service openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl is-active openstack-cinder-volume.service target.service openstack-cinder-api.service openstack-cinder-scheduler.service

#创建一个volume type并关联到volume_backend_name
# cinder type-create LVM
# cinder type-key LVM set volume_backend_name=LVM
# cinder extra-specs-list
# +--------------------------------------+-------------+--------------------------------+
# | ID                                   | Name        | extra_specs                    |
# +--------------------------------------+-------------+--------------------------------+
# | 17fcfe8d-e863-4133-aa84-3f05ed031bb2 | __DEFAULT__ | {}                             |
# | ff4e854b-e17a-42e1-b202-4b15148dbc14 | LVM         | {'volume_backend_name': 'LVM'} |
# +--------------------------------------+-------------+--------------------------------+
