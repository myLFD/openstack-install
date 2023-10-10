#!/bin/bash -e
set -x

#安装openstack-keystone相关软件
#yum install -y openstack-keystone httpd mod_wsgi
yum install -y openstack-keystone httpd mod_wsgi

cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bac

#配置keystone
openstack-config --set /etc/keystone/keystone.conf DEFAULT log_file keystone.log
openstack-config --set /etc/keystone/keystone.conf DEFAULT log_dir /var/log/keystone
openstack-config --set /etc/keystone/keystone.conf catalog template_file /etc/keystone/default_catalog.templates
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:$keystone_pass@$vip:3307/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet



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


