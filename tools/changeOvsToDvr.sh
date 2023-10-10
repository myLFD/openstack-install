##controller
openstack-config --set /etc/neutron/neutron.conf DEFAULT router_distributed True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini DEFAULT enable_distributed_routing True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT agent_mode dvr_snat
systemctl restart neutron-server.service \
 neutron-dhcp-agent.service \
  neutron-metadata-agent.service  \
  neutron-l3-agent.service \
   neutron-openvswitch-agent.service





##computer
yum install -y openstack-neutron
ovs-vsctl add-port br-ex $compute_interface
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini DEFAULT enable_distributed_routing True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver openvswitch
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT agent_mode  dvr
systemctl enable neutron-l3-agent
systemctl restart  neutron-l3-agent.service neutron-openvswitch-agent.service
