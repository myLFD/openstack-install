#!/bin/bash -e
set -x
#TODO 增加cloud yum源
#安装和配置计算节点
yum install -y openstack-nova-compute openstack-selinux openstack-utils

cp /etc/nova/nova.conf /etc/nova/nova.conf.bac
#请根据实际情况自行修改my_ip的值
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $compute
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
#请根据实际情况自行修改rabbitmq对应服务的ip
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,openstack:loongson@controller2:5672,openstack:loongson@controller3:5672
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/nova/nova.conf DEFAULT start_guests_on_host_boot True
openstack-config --set /etc/nova/nova.conf DEFAULT resume_guests_state_on_host_boot True
openstack-config --set /etc/nova/nova.conf DEFAULT resize_confirm_window 5
openstack-config --set /etc/nova/nova.conf DEFAULT cpu_allocation_ratio 4
openstack-config --set /etc/nova/nova.conf DEFAULT ram_allocation_ratio 1
openstack-config --set /etc/nova/nova.conf DEFAULT vif_plugging_is_fatal true
openstack-config --set /etc/nova/nova.conf api auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://$vip:5001
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://$vip:5001
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller1:11211,controller2:11211,controller3:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password $nova_pass
openstack-config --set /etc/nova/nova.conf vnc enabled true
openstack-config --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf vnc server_proxyclient_address "\$my_ip"
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://$vip:6080/vnc_auto.html
openstack-config --set /etc/nova/nova.conf consoleauth  token_ttl 2595600
openstack-config --set /etc/nova/nova.conf glance api_servers http://$vip:9293
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
openstack-config --set /etc/nova/nova.conf placement region_name RegionOne
openstack-config --set /etc/nova/nova.conf placement project_domain_name default
openstack-config --set /etc/nova/nova.conf placement project_name service
openstack-config --set /etc/nova/nova.conf placement auth_type password
openstack-config --set /etc/nova/nova.conf placement user_domain_name default
openstack-config --set /etc/nova/nova.conf placement auth_url http://$vip:5001/v3
openstack-config --set /etc/nova/nova.conf placement username placement
openstack-config --set /etc/nova/nova.conf placement password $placement_pass
openstack-config --set /etc/nova/nova.conf consoleauth token_ttl 2595600
openstack-config --set /etc/nova/nova.conf libvirt virt_type kvm
openstack-config --set /etc/nova/nova.conf libvirt use_virtio_for_bridges true
#如果需要通过iso起虚拟机，需要设置images_type = raw，默认是qcow2
#openstack-config --set /etc/nova/nova.conf libvirt images_type raw

openstack-config --set /etc/nova/nova.conf neutron url http://$vip:9606
openstack-config --set /etc/nova/nova.conf neutron auth_url http://$vip:5001
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password $neutron_pass
openstack-config --set /etc/nova/nova.conf spice enabled true
openstack-config --set /etc/nova/nova.conf cinder os_region_name  RegionOne
#查看并核实已经修改的配置是否存在问题
egrep -v "^#|^$" /etc/nova/nova.conf



#安装dmidecode
yum install -y dmidecode

#安装虚拟化相关组件
#yum module install virt:rhel -y
yum install -y libvirt-client libvirt-daemon-config-network libvirt-daemon-kvm 

#支持冷迁移
usermod -s /bin/bash nova

#4.启动计算服务并配置为开机自启
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start openstack-nova-compute.service libvirtd.service 
#systemctl status libvirtd.service openstack-nova-compute.service

#将计算节点添加到cell数据库中(在控制节点中执行)
#openstack compute service list --service nova-compute
#su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
