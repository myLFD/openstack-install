#!/bin/bash -e
set -x
#创建keystone数据库并授权
mysql -uroot -e "set password for root@localhost = password('$mysql_root_pass');"
mysql -uroot -p$mysql_root_pass -e 'CREATE DATABASE keystone;'
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$keystone_pass';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$keystone_pass';"

#安装openstack-keystone相关软件
#yum install -y openstack-keystone httpd mod_wsgi
yum install -y openstack-keystone httpd python3-mod_wsgi

cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bac


#配置keystone
openstack-config --set /etc/keystone/keystone.conf DEFAULT log_file keystone.log
openstack-config --set /etc/keystone/keystone.conf DEFAULT log_dir /var/log/keystone
openstack-config --set /etc/keystone/keystone.conf catalog template_file /etc/keystone/default_catalog.templates
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:$keystone_pass@$vip:3307/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet


#初始化同步keystone数据库
su -s /bin/sh -c "keystone-manage db_sync" keystone

#4.同步完成进行连接测试
mysql -h$vip -P 3307 -ukeystone -p$keystone_pass -e "use keystone;show tables;"
mysql -h$vip -P 3307 -ukeystone -p$keystone_pass -e "use keystone;show tables;"|wc -l

#初始化 Fernet 密钥库
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

#配置 Apache HTTP 服务器
#修改httpd主配置文件
sed -i "/#ServerName/a\ServerName $controller" /etc/httpd/conf/httpd.conf
#配置虚拟主机，建立软链接
rm -f /etc/httpd/conf.d/wsgi-keystone.conf
ln -s -f /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
#启动httpd并配置开机自启动
systemctl enable httpd.service
systemctl restart httpd.service
#systemctl status httpd.service|grep running

#引导身份服务
#（1）创建 keystone 用户,初始化的服务实体和API端点
#创建用户：需要创建一个密码ADMIN_PASS，作为登陆openstack的admin管理员用户，
#创建keystone服务实体和身份认证服务，以下三种类型分别为公共的、内部的、管理的。

#在endpoint表增加3个服务实体的API端点
#在local_user表中创建admin用户
#在project表中创建admin和Default项目（默认域）
#在role表创建3种角色，admin，member和reader，即公共的、内部的、管理的。
#在service表中创建identity服务

keystone-manage bootstrap --bootstrap-password $keystone_pass \
  --bootstrap-admin-url http://$vip:5001/v3/ \
  --bootstrap-internal-url http://$vip:5001/v3/ \
  --bootstrap-public-url http://$vip:5001/v3/ \
  --bootstrap-region-id RegionOne


#临时配置管理员账户的相关变量进行管理
cat<<EOF >openstack-rc
export OS_USERNAME=admin
export OS_PASSWORD=$keystone_pass
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$vip:5001/v3
export OS_IDENTITY_API_VERSION=3
EOF

source openstack-rc


#keystone验证

#创建名为service的项目，在default域中
openstack project create --domain default   --description "Service Project" service
#创建名为myproject项目，在default域中
openstack project create --domain default   --description "Demo Project" myproject

#创建myuser用户，在default域中
#注意以下命令需要输入密码

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