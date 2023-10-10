#!/bin/bash -e
set -x


#1安装openstack-glance
yum install -y openstack-glance

#2.配置文件修改
#（1）glance-api.conf
#文件路径：/etc/glance/glance-api.conf
#修改前先备份
cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bac

openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,openstack:loongson@controller2:5672,openstack:loongson@controller3:5672
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true
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


systemctl enable openstack-glance-api.service
systemctl start openstack-glance-api.service

#3只需要将master上目录下/var/lib/glance/images/所有文件copy到备份服务器, 然后chown -R glance:glance  /var/lib/glance/即可



