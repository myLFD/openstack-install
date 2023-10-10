#!/bin/bash -e
set -x



yum install -y openstack-placement-api python3-osc-placement.noarch

#2.配置文件修改

cp /etc/placement/placement.conf /etc/placement/placement.conf.bac
openstack-config --set /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:$placement_pass@$vip:3307/placement
openstack-config --set /etc/placement/placement.conf api auth_strategy keystone
openstack-config --set /etc/placement/placement.conf keystone_authtoken auth_url http://$vip:5001/v3
openstack-config --set /etc/placement/placement.conf keystone_authtoken memcached_servers controller1:11211,controller2:11211,controller3:11211
openstack-config --set /etc/placement/placement.conf keystone_authtoken auth_type password
openstack-config --set /etc/placement/placement.conf keystone_authtoken project_domain_name Default
openstack-config --set /etc/placement/placement.conf keystone_authtoken user_domain_name Default
openstack-config --set /etc/placement/placement.conf keystone_authtoken project_name service
openstack-config --set /etc/placement/placement.conf keystone_authtoken username placement
openstack-config --set /etc/placement/placement.conf keystone_authtoken password $placement_pass

#5.重启Apache服务（httpd）
systemctl restart httpd

#placement验证
placement-status upgrade check




