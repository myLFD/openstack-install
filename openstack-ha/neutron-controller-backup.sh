#!/bin/bash -e
set -x


#二、neutron相关软件安装与配置
#安装neutron相关软件
yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables

#配置服务器组件
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bac
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router 
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,openstack:loongson@controller2:5672,openstack:loongson@controller3:5672
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT l3_ha  True
openstack-config --set /etc/neutron/neutron.conf DEFAULT max_l3_agents_per_router 3
openstack-config --set /etc/neutron/neutron.conf DEFAULT min_l3_agents_per_router 1
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network  3
 
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
 
openstack-config --set /etc/neutron/neutron.conf nova auth_url http://$vip:5001
openstack-config --set /etc/neutron/neutron.conf nova auth_type password
openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova project_name service
openstack-config --set /etc/neutron/neutron.conf nova username nova
openstack-config --set /etc/neutron/neutron.conf nova password $nova_pass
 
openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp


#配置模块化第 2 层 (ML2) 插件
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bac
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers local,flat,vlan,gre,vxlan,geneve
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan 
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
                                                           
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000


#注意网卡名称需要根据实际情况修改
#注意网卡名称需要根据实际情况修改
#配置 Linux 网桥代理
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.bac
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $controller
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population false

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group false
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup #firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver iptables

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$ext_interface



#配置 DHCP 代理
cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.bac
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

#tee /etc/neutron/dhcp_agent.ini <<-'EOF'
#[DEFAULT]
#interface_driver = linuxbridge
#dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
#enable_isolated_metadata = true
#EOF

#配置元数据代理
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bac
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host $controller
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $neutron_pass

#tee /etc/neutron/metadata_agent.ini <<-'EOF'
#[DEFAULT]
#nova_metadata_host = controller
#metadata_proxy_shared_secret = loongson
#EOF

#配置 L3 服务
cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.bak
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge

#安装计算相关网络服务
yum install -y openstack-neutron-linuxbridge ebtables ipset

#完成安装
rm -f /etc/neutron/plugin.ini
ln -s -f /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
systemctl restart openstack-nova-api.service

#使能控制节点网络服务
systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service \
  neutron-dhcp-agent.service \
  neutron-metadata-agent.service \
  neutron-l3-agent.service
systemctl restart neutron-server.service \
 neutron-dhcp-agent.service \
  neutron-metadata-agent.service  \
  neutron-l3-agent.service \
  neutron-linuxbridge-agent.service
# systemctl status neutron-server.service \
#   neutron-dhcp-agent.service \
#   neutron-metadata-agent.service |grep running



