#!/bin/bash -e
set -x
#一、创建Nova相关数据库、凭据与API端点
#1.创建数据库并授权
#nova-controller先决条件
mysql -uroot -p$mysql_root_pass -e "CREATE DATABASE nova_api;"
mysql -uroot -p$mysql_root_pass -e "CREATE DATABASE nova;"
mysql -uroot -p$mysql_root_pass -e "CREATE DATABASE nova_cell0;"

mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$nova_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$nova_pass';"

mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$nova_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$nova_pass';"

mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$nova_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$nova_pass';"

#2.创建计算服务凭据
#以下命令需要输入密码
expect <<EOF
  set timeout 300
  spawn  bash -c "openstack user create --domain default --password-prompt nova"
  expect {
    "*Password*" {send "$nova_pass\r";exp_continue}
    "*Password*" {send "$nova_pass\r";}
   }
  
EOF

openstack role add --project service --user nova admin
openstack service create --name nova   --description "OpenStack Compute" compute
#3.创建compute API服务端点
openstack endpoint create --region RegionOne   compute public http://$vip:8784/v2.1
openstack endpoint create --region RegionOne   compute internal http://$vip:8784/v2.1
openstack endpoint create --region RegionOne   compute admin http://$vip:8784/v2.1

#二、nova相关软件安装与配置
#1.安装nova相关软件
yum install -y openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler

#2.配置文件修改
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


#3.同步创建相关数据库（注意顺序）
#（1）填充nova-api数据库
su -s /bin/sh -c "nova-manage api_db sync" nova
#验证数据库
mysql -unova -p$nova_pass -e "use nova_api;show tables;"
#（2）注册cell0数据库
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
#（3）创建cell1单元
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

#（4）初始化nova数据库
su -s /bin/sh -c "nova-manage db sync" nova

#（5）检查确认cell0和cell1注册成功
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

#（6）验证数据库
mysql -unova -p$nova_pass -e "use nova_api;show tables;"
mysql -uplacement -p$placement_pass -e "use placement;show tables;"

#启动计算服并设置开机自启
systemctl enable \
    openstack-nova-api.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service
systemctl restart \
    openstack-nova-api.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service
# systemctl status \
#     openstack-nova-api.service \
#     openstack-nova-scheduler.service \
#     openstack-nova-conductor.service \
#     openstack-nova-novncproxy.service |grep running

#创建flavor
nova flavor-create --is-public true tiny tiny 2048 60 2

#验证
openstack compute service list
openstack catalog list
#openstack image list
nova-status upgrade check

