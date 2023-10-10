controllerIp:port=10.40.73.252:6082

 
控制节点
yum install openstack-nova-spicehtml5proxy spice-html5 -y
openstack-config --set /etc/nova/nova.conf  vnc enabled false
openstack-config --set /etc/nova/nova.conf  spice html5proxy_host 0.0.0.0
openstack-config --set /etc/nova/nova.conf  spice html5proxy_port  6082
openstack-config --set /etc/nova/nova.conf  spice enabled True
openstack-config --set /etc/nova/nova.conf  spice html5proxy_base_url http://10.40.65.244:6082/spice_auto.html
openstack-config --set /etc/nova/nova.conf  spice server_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf  spice agent_enabled true
openstack-config --set /etc/nova/nova.conf  spice keymap en-us

iptables -I INPUT -p tcp -m multiport --dports 6082 -m comment --comment "Allow SPICE connections for console access " -j ACCEPT
service httpd restart
service openstack-nova-spicehtml5proxy start

systemctl enable openstack-nova-spicehtml5proxy
  

计算节点
yum install spice-html5 -y
openstack-config --set /etc/nova/nova.conf  vnc enabled false
openstack-config --set /etc/nova/nova.conf  spice enabled True
openstack-config --set /etc/nova/nova.conf  spice html5proxy_base_url http://10.40.65.244:6082/spice_auto.html
openstack-config --set /etc/nova/nova.conf  spice agent_enabled true
openstack-config --set /etc/nova/nova.conf  spice keymap en-us
openstack-config --set /etc/nova/nova.conf  spice server_listen 0.0.0.0
service openstack-nova-compute restart

