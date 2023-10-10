##change linuxbridge to ovs
##controller
rpm -e openstack-neutron-linuxbridge --nodeps
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ebtables ipset -y
openstack-config --set /etc/neutron/neutron.conf DEFAULT  allow_overlapping_ips True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver  iptables_hybrid

cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.bac
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings provider:br-ex
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $controller
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup #firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini  agent tunnel_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver

openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver

systemctl enable openvswitch && systemctl restart openvswitch
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $ext_interface
systemctl enable neutron-server.service \
   neutron-openvswitch-agent.service \
  neutron-dhcp-agent.service \
  neutron-metadata-agent.service \
  neutron-l3-agent.service
systemctl restart neutron-server.service \
 neutron-dhcp-agent.service \
  neutron-metadata-agent.service  \
  neutron-l3-agent.service \
   neutron-openvswitch-agent.service

#computer
rpm -e openstack-neutron-linuxbridge --nodeps
cd /root/openstack-install/openstack-ha/
source variable-ha.sh 
yum install openstack-neutron-openvswitch ebtables ipset -y
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





#change ovs to linuxbridge
yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers local,flat,vlan,gre,vxlan,geneve
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges provider

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $controller
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population true

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group false
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup #firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver iptables

openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:$ext_interface
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router,neutron.services.qos.qos_plugin.QoSPlugin
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security,qos
openstack-config --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini agent extensions  qos

openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq

openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge

yum install -y openstack-neutron-linuxbridge ebtables ipset

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