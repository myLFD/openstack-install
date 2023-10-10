#!/bin/bash -e
set -x
#一、创建placement相关数据库、凭据与API端点
#1.创建placement数据库并授权
mysql -uroot -p$mysql_root_pass -e "CREATE DATABASE placement;"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '$placement_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '$placement_pass';"

#创建placement-common并赋予其权限，否则数据库同步时将失败
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement-common'@'localhost' IDENTIFIED BY '$placement_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement-common'@'%' IDENTIFIED BY '$placement_pass';"

#配置用户和端点
#以下命令需要输入密码
#2.创建服务凭据

expect <<EOF
 set timeout 300
  
  spawn  bash -c "openstack user create --domain default --password-prompt placement"
  expect {
    "*Password*" {send "$placement_pass\r";exp_continue}
    "*Password*" {send "$placement_pass\r";}
   }
  
EOF

openstack role add --project service --user placement admin
openstack service create --name placement   --description "Placement API" placement
#3.创建placement项目的endpoint（API端口）
openstack endpoint create --region RegionOne   placement public http://$vip:8789
openstack endpoint create --region RegionOne   placement internal http://$vip:8789
openstack endpoint create --region RegionOne   placement admin http://$vip:8789
openstack endpoint list
#二、placement相关软件安装与配置
#1.安装placement软件
yum install -y openstack-placement-api python3-osc-placement.noarch

#2.配置文件修改

cp /etc/placement/placement.conf /etc/placement/placement.conf.bac
openstack-config --set /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:$placement_pass@$vip:3307/placement
openstack-config --set /etc/placement/placement.conf api auth_strategy keystone
openstack-config --set /etc/placement/placement.conf keystone_authtoken auth_url http://$vip:5001/v3
openstack-config --set /etc/placement/placement.conf keystone_authtoken memcached_servers controller1:11211,controller2:11211,controller3:11211,controller3:11211
openstack-config --set /etc/placement/placement.conf keystone_authtoken auth_type password
openstack-config --set /etc/placement/placement.conf keystone_authtoken project_domain_name Default
openstack-config --set /etc/placement/placement.conf keystone_authtoken user_domain_name Default
openstack-config --set /etc/placement/placement.conf keystone_authtoken project_name service
openstack-config --set /etc/placement/placement.conf keystone_authtoken username placement
openstack-config --set /etc/placement/placement.conf keystone_authtoken password $placement_pass



#3.同步placement数据库
#（1）同步并初始化
su -s /bin/sh -c "placement-manage db sync" placement

#5.重启Apache服务（httpd）
systemctl restart httpd

#placement验证
placement-status upgrade check




