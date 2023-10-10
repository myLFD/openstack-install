#!/bin/bash -e
set -x
#安装和配置计算节点
#安装组件¶
yum install openstack-neutron-openvswitch ebtables ipset -y
         
#配置通用组件
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bac
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
#请根据实际情况自行修改rabbitmq对应服务的ip
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:$rabbitmq_pass@$controller:5672

openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$neutron_pass@controller:3306/neutron

openstack-config --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $neutron_pass

openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

#查看并核实已经修改的配置是否存在问题
egrep -v "^#|^$" /etc/neutron/neutron.conf

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan 
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
                                                           
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver  iptables_hybrid



#请根据实际情况自行修改local_ip的值
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $compute
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings provider:br-ex

egrep -v "^#|^$" /etc/neutron/plugins/ml2/openvswitch_agent.ini

ovs-vsctl add-br br-ex
# ovs-vsctl add-port br-ex $compute_interface

#重启neutron-agent服务，并配置开机启动:
systemctl enable neutron-openvswitch-agent.service
systemctl start neutron-openvswitch-agent.service 
#systemctl status neutron-linuxbridge-agent 




