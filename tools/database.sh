set -x

mysql -uroot -e "set password for root@localhost = password('$mysql_root_pass');"
mysql -uroot -p$mysql_root_pass -e 'CREATE DATABASE keystone;'
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$keystone_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$keystone_pass';"
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage bootstrap --bootstrap-password $keystone_pass \
  --bootstrap-admin-url http://$vip:5001/v3/ \
  --bootstrap-internal-url http://$vip:5001/v3/ \
  --bootstrap-public-url http://$vip:5001/v3/ \
  --bootstrap-region-id RegionOne
  #创建名为service的项目，在default域中
openstack project create --domain default   --description "Service Project" service
#创建名为myproject项目，在default域中
openstack project create --domain default   --description "Demo Project" myproject

expect <<EOF
 set timeout 300
  
  spawn  bash -c "openstack user create --domain default   --password-prompt myuser "
  expect {
    "*Password*" {send "$keystone_pass\r";exp_continue}
    "*Password*" {send "$keystone_pass\r"}
   }

EOF
#创建myrole角色，在role表中
openstack role create myrole
#将myrole角色添加到myproject项目和myuser用户
openstack role add --project myproject --user myuser myrole

mysql -uroot -p$mysql_root_pass -e "CREATE DATABASE glance;"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$glance_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$glance_pass';"

#2.创建服务凭据
#（1）在keystone上创建glance用户
#以下命令在local_user表创建glance用户
#注意以下命令需要输入密码

expect <<EOF 
set timeout 300 
  spawn  bash -c "openstack user create --domain default --password-prompt glance"
  expect {
    "*Password*" {send "$glance_pass\r";exp_continue}
    "*Password*" {send "$glance_pass\r";}
   } 
EOF

openstack role add --project service --user glance admin
#（3）创建glance镜像服务的实体
#以下命令在service表中增加glance项目
openstack service create --name glance --description "OpenStack Image" image
#3.创建镜像服务的 API 端点（endpoint）
openstack endpoint create --region RegionOne image public http://$vip:9292
openstack endpoint create --region RegionOne image internal http://$vip:9292
openstack endpoint create --region RegionOne image admin http://$vip:9292
#查看API端点
openstack endpoint list

su -s /bin/sh -c "glance-manage db_sync" glance

mysql -uroot -p$mysql_root_pass -e "CREATE DATABASE placement;"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '$placement_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '$placement_pass';"

#创建placement-common并赋予其权限，否则数据库同步时将失败
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement-common'@'localhost' IDENTIFIED BY '$placement_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement-common'@'%' IDENTIFIED BY '$placement_pass';"



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
openstack endpoint create --region RegionOne   placement public http://$vip:8778
openstack endpoint create --region RegionOne   placement internal http://$vip:8778
openstack endpoint create --region RegionOne   placement admin http://$vip:8778
openstack endpoint list

su -s /bin/sh -c "placement-manage db sync" placement

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
openstack endpoint create --region RegionOne   compute public http://$vip:8774/v2.1
openstack endpoint create --region RegionOne   compute internal http://$vip:8774/v2.1
openstack endpoint create --region RegionOne   compute admin http://$vip:8774/v2.1

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

#创建flavor
nova flavor-create --is-public true tiny tiny 2048 60 2

#验证
openstack compute service list
openstack catalog list
#openstack image list
nova-status upgrade check

mysql -uroot -p$mysql_root_pass -e "CREATE DATABASE neutron;"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$neutron_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$neutron_pass';"

#要创建服务凭证
#以下命令需要输入密码

expect <<EOF
set timeout 300
  
  spawn  bash -c "openstack user create --domain default --password-prompt neutron"
  expect {
    "*Password*" {send "$neutron_pass\r";exp_continue}
    "*Password*" {send "$neutron_pass\r";}
   }
  
EOF
openstack role add --project service --user neutron admin
openstack service create --name neutron   --description "OpenStack Networking" network

#创建网络服务 API 端点
openstack endpoint create --region RegionOne   network public http://$vip:9696
openstack endpoint create --region RegionOne   network internal http://$vip:9696
openstack endpoint create --region RegionOne   network admin http://$vip:9696
openstack endpoint list

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron


mysql -uroot -ploongson -e 'CREATE DATABASE cinder;'
mysql -uroot -ploongson -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'loongson';"
mysql -uroot -ploongson -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'loongson';"

#create the service credentials and enter the password loongson

expect <<EOF
 set timeout 300
  
  spawn  bash -c "openstack user create --domain default --password-prompt cinder "
  expect {
    "*Password*" {send "$cinder_pass\r";exp_continue}
    "*Password*" {send "$cinder_pass\r";}
   }
  
EOF

#Add the admin role to the cinder user:
openstack role add --project service --user cinder admin

#Create the cinderv2 and cinderv3 service entities:
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

#Create the Block Storage service API endpoints:
openstack endpoint create --region RegionOne   volumev2 public http://$vip:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev2 internal http://$vip:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev2 admin http://$vip:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 public http://$vip:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 internal http://$vip:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 admin http://$vip:8776/v3/%\(project_id\)s
su -s /bin/sh -c "cinder-manage db sync" cinder

egrep -v "^#|^$" /etc/cinder/cinder.conf

openstack-config --set /etc/nova/nova.conf cinder os_region_name  RegionOne
systemctl restart openstack-nova-api.service