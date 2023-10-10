#!/bin/bash -e
set -x

#需要手动执行的步骤
#/////////////////////////////////////////////////////////////////////////////////
#storage node (没有存储节点,使用controller上的存储 )
#1   在选定磁盘上创建一个lvm的分区
#fdisk /dev/sba
#fdisk -l
#Disk /dev/sda
#设备             起点       末尾       扇区  大小 类型
#/dev/sda1        2048 3400000000 3399997953  1.6T Linux 文件系统
#/dev/sda2  3400001536 7812939742 4412938207  2.1T Linux LVM
#2  安装lvm, 然后编辑/etc/lvm/lvm.conf 
yum install -y lvm2 device-mapper-persistent-data 

# edit /etc/lvm/lvm.conf 
#in the devices section, add a filter that accepts the /dev/sda2 device and rejects all other devices:
 #其实默认接受所有也可以
 # This configuration option has an automatic default value.
 # filter = [ "a|.*|" ]
#devices {
# ...
# filter = [ "a/sdb1/", "r/.*/"]
 #/////////////////////////////////////////////////////////////////////////////////
source openstack-rc



# systemctl enable lvm2-lvmetad.service
# systemctl start lvm2-lvmetad.service
#Create the LVM physical volume /dev/sda2:
pvcreate /dev/sdb1
#Create the LVM volume group cinder-volumes
vgcreate cinder-volumes /dev/sdb1



yum install -y openstack-cinder targetcli 

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
openstack endpoint create --region RegionOne   volumev2 public http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev2 internal http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev2 admin http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 admin http://controller:8776/v3/%\(project_id\)s

cp  /etc/cinder/cinder.conf  /etc/cinder/cinder.conf.bak
openstack-config --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:loongson@controller:3306/cinder

openstack-config --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:$rabbitmq_pass@$controller:5672
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy  keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip $controller
openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends  lvm
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers  http://controller:9292

openstack-config --set /etc/cinder/cinder.conf keystone_authtoken www_authenticate_uri  http://controller:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url  http://controller:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers  controller:11211
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_type  password
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name  default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name  default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name  service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username  cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password  loongson

openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

openstack-config --set /etc/cinder/cinder.conf lvm volume_driver  cinder.volume.drivers.lvm.LVMVolumeDriver
openstack-config --set /etc/cinder/cinder.conf lvm volume_group  cinder-volumes
openstack-config --set /etc/cinder/cinder.conf lvm target_protocol  iscsi
openstack-config --set /etc/cinder/cinder.conf lvm target_helper  lioadm
openstack-config --set /etc/cinder/cinder.conf lvm volume_backend_name LVM



#Populate the Block Storage database
su -s /bin/sh -c "cinder-manage db sync" cinder

egrep -v "^#|^$" /etc/cinder/cinder.conf

openstack-config --set /etc/nova/nova.conf cinder os_region_name  RegionOne
systemctl restart openstack-nova-api.service

systemctl enable openstack-cinder-volume.service target.service openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl restart openstack-cinder-volume.service target.service openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl status openstack-cinder-volume.service target.service openstack-cinder-api.service openstack-cinder-scheduler.service

#创建一个volume type并关联到volume_backend_name
# cinder type-create LVM
# cinder type-key LVM set volume_backend_name=LVM
# cinder extra-specs-list
# +--------------------------------------+-------------+--------------------------------+
# | ID                                   | Name        | extra_specs                    |
# +--------------------------------------+-------------+--------------------------------+
# | 17fcfe8d-e863-4133-aa84-3f05ed031bb2 | __DEFAULT__ | {}                             |
# | ff4e854b-e17a-42e1-b202-4b15148dbc14 | LVM         | {'volume_backend_name': 'LVM'} |
# +--------------------------------------+-------------+--------------------------------+
