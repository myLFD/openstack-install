#!/bin/bash -e
set -x
#创建glance数据库并授权
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

#（2）在keystone上将glance用户添加为service项目的admin角色(权限)
#以下命令无输出
openstack role add --project service --user glance admin
#（3）创建glance镜像服务的实体
#以下命令在service表中增加glance项目
openstack service create --name glance --description "OpenStack Image" image
#3.创建镜像服务的 API 端点（endpoint）
openstack endpoint create --region RegionOne image public http://$vip:9293
openstack endpoint create --region RegionOne image internal http://$vip:9293
openstack endpoint create --region RegionOne image admin http://$vip:9293
#查看API端点
openstack endpoint list


#2安装openstack-glance
yum install -y openstack-glance

#3.配置文件修改
#（1）glance-api.conf
#文件路径：/etc/glance/glance-api.conf
#修改前先备份
cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bac

openstack-config --set /etc/glance/glance-api.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,openstack:loongson@controller2:5672,openstack:loongson@controller3:5672
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$glance_pass@$vip:3307/glance
openstack-config --set /etc/glance/glance-api.conf glance_store stores file,http
openstack-config --set /etc/glance/glance-api.conf glance_store default_store file
openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri http://$vip:5001
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://$vip:5001
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers controller1:11211,controller2:11211,controller3:11211
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken password $glance_pass
openstack-config --set /etc/glance/glance-api.conf oslo_concurrency lock_path /var/lock/glance
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone



#4同步数据库
#(1)为glance镜像服务初始化同步数据库
#生成的相关表
su -s /bin/sh -c "glance-manage db_sync" glance
#（2）同步完成进行连接测试
#保证所有需要的表已经建立，否则后面可能无法进行下去
mysql -h$vip -P 3307 -uglance -p$glance_pass -e "use glance;show tables;"
#5.glance镜像服务启动并设置开机自启
systemctl enable openstack-glance-api.service
systemctl restart openstack-glance-api.service
#6.验证glance操作
#下载loongnix镜像
#wget http://pkg.loongnix.cn:8080/loongnix-server/8.3/isos/loongarch64/Loongnix-server-8.3.loongarch64.qcow2
#上传镜像(qcow2格式)
#glance image-create --name "loongnix-server-mini" --file Loongnix-server-8.3.loongarch64.qcow2 --disk-format qcow2 --container-format bare --visibility=public
#glance image-create --name "loongnix-server" --fileloongnix-server-new.qcow2 --disk-format qcow2 --container-format bare --visibility=public
#查看镜像
#glance image-list


#上传镜像(iso格式)
#glance image-create --name "loongnix-iso" --file livecd-loongnix-server-20-mini-loongarch64-beta8-202107120440.iso --disk-format iso --container-format bare --visibility=public 



