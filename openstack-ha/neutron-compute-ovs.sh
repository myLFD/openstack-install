#!/bin/bash -e
set -x
#安装和配置计算节点
#安装组件¶
yum install -y  ebtables ipset openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch 



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

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan 
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver  iptables_hybrid
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $compute
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings provider:br-ex
egrep -v "^#|^$" /etc/neutron/plugins/ml2/openvswitch_agent.ini

systemctl enable neutron-openvswitch-agent.service
systemctl start neutron-openvswitch-agent.service 
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $compute_interface
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini DEFAULT enable_distributed_routing True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT agent_mode  dvr
systemctl enable neutron-l3-agent
systemctl restart  neutron-l3-agent.service neutron-openvswitch-agent.service







