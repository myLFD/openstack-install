#!/bin/bash -e
set -x
#安装和配置计算节点
#安装组件¶
yum install -y openstack-neutron-linuxbridge ebtables ipset openstack-neutron openstack-neutron-ml2



#配置通用组件
#如果是控制节点, 屏蔽下面一行,
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bac
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
#请根据实际情况自行修改rabbitmq对应服务的ip
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,openstack:loongson@controller2:5672,openstack:loongson@controller3:5672
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true

openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$neutron_pass@$vip:3307/neutron

openstack-config --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://$vip:5001
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$vip:5001
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller1:11211,controller2:11211,controller3:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $neutron_pass

openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

#查看并核实已经修改的配置是否存在问题
egrep -v "^#|^$" /etc/neutron/neutron.conf

#配置网络选项

cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bac
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
#请根据实际情况自行修改local_ip的值
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $compute
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group false
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver iptables
#请根据实际情况自行修改provider的值
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$compute_interface

egrep -v "^#|^$" /etc/neutron/plugins/ml2/linuxbridge_agent.ini


#重启neutron-agent服务，并配置开机启动:
systemctl enable neutron-linuxbridge-agent
systemctl restart neutron-linuxbridge-agent 
#systemctl status neutron-linuxbridge-agent 




