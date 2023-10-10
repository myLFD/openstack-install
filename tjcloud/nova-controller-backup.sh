

yum install -y openstack-nova-api openstack-nova-conductor \
  openstack-nova-console openstack-nova-novncproxy \
  openstack-nova-scheduler openstack-nova-placement-api
#/etc/nova/nova.conf 
cp /etc/nova/nova.conf /etc/nova/nova.conf.bac
openstack-config --set /etc/nova/nova.conf DEFAULT debug false
#请根据实际情况自行修改my_ip的值
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $controller
openstack-config --set /etc/nova/nova.conf DEFAULT pybasedir /usr/lib/python3/dist-packages
openstack-config --set /etc/nova/nova.conf DEFAULT bindir /usr/bin
openstack-config --set /etc/nova/nova.conf DEFAULT state_path /var/lib/nova
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
#请根据实际情况自行修改rabbitmq对应服务的ip
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,openstack:loongson@controller2:5672,openstack:loongson@controller3:5672
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_durable_queues true

openstack-config --set /etc/nova/nova.conf api auth_strategy keystone

openstack-config --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:$nova_pass@$vip:3307/nova_api

openstack-config --set /etc/nova/nova.conf cinder os_region_name RegionOne

openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://nova:$nova_pass@$vip:3307/nova

openstack-config --set /etc/nova/nova.conf glance api_servers http://$vip:9293

openstack-config --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://$vip:5001
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://$vip:5001
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller1:11211,controller2:11211,controller3:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password $nova_pass

openstack-config --set /etc/nova/nova.conf libvirt virt_type kvm 
openstack-config --set /etc/nova/nova.conf libvirt use_virtio_for_bridges true
#如果需要通过iso起虚拟机，需要设置images_type = raw，默认是qcow2
#openstack-config --set /etc/nova/nova.conf libvirt images_type raw

openstack-config --set /etc/nova/nova.conf neutron auth_url http://$vip:5001
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password $neutron_pass

openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy  true
openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret METADATA_SECRET

openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

openstack-config --set /etc/nova/nova.conf placement region_name RegionOne
openstack-config --set /etc/nova/nova.conf placement project_domain_name Default
openstack-config --set /etc/nova/nova.conf placement project_name service
openstack-config --set /etc/nova/nova.conf placement auth_type password
openstack-config --set /etc/nova/nova.conf placement user_domain_name Default
openstack-config --set /etc/nova/nova.conf placement auth_url http://$vip:5001/v3
openstack-config --set /etc/nova/nova.conf placement username placement
openstack-config --set /etc/nova/nova.conf placement password $placement_pass

openstack-config --set /etc/nova/nova.conf vnc enabled true
openstack-config --set /etc/nova/nova.conf vnc server_listen " \$my_ip"
openstack-config --set /etc/nova/nova.conf vnc server_proxyclient_address " \$my_ip"
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://$controller:6090/vnc_auto.html
openstack-config --set /etc/nova/nova.conf vnc enabled true
openstack-config --set /etc/nova/nova.conf spice enabled true
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron true
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf placement_database connection mysql+pymysql://placement:$placement_pass@$vip:3307/placement
openstack-config --set /etc/nova/nova.conf libvirt cpu_mode custom
openstack-config --set /etc/nova/nova.conf libvirt cpu_model Loongson-3A4000-COMP



#/etc/httpd/conf.d/00-nova-placement-api.conf:
cat<<EOF >> /etc/httpd/conf.d/00-nova-placement-api.conf

<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>
EOF
 systemctl restart httpd

 

 systemctl enable openstack-nova-api.service \
  openstack-nova-consoleauth openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service
 systemctl restart openstack-nova-api.service \
  openstack-nova-consoleauth openstack-nova-scheduler.service \
  openstack-nova-conductor.service openstack-nova-novncproxy.service








