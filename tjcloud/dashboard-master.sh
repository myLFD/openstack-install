#!/bin/bash -e
set -x
#安装和配置组件
yum install -y openstack-dashboard mod_ssl

#配置dashboard
cp /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.bac

#在/etc/openstack-dashboard/local_settings中配置以下内容
sed -i '/OPENSTACK_KEYSTONE_URL/d' /etc/openstack-dashboard/local_settings
sed -i '/^OPENSTACK_HOST/d' /etc/openstack-dashboard/local_settings
sed -i '/^ALLOWED_HOSTS/d' /etc/openstack-dashboard/local_settings
cat<<EOF >>/etc/openstack-dashboard/local_settings

OPENSTACK_HOST = "$vip"

ALLOWED_HOSTS = ['*',]


SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': 'controller1:11211,controller2:11211,controller3:11211',
    },
}

OPENSTACK_KEYSTONE_URL = "http://%s:5001/v3" % OPENSTACK_HOST

OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True

OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}

OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"

OPENSTACK_KEYSTONE_DEFAULT_ROLE = "reader"
POLICY_FILES_PATH = '/etc/openstack-dashboard'
#如果您选择网络选项 1，请禁用对第 3 层网络服务的支持：
OPENSTACK_NEUTRON_NETWORK = {
    'enable_distributed_router': False,
    'enable_firewall': False,
    'enable_ha_router': True,
    'enable_lb': False,
    'enable_quotas': True,
    'enable_security_group': True,
    'enable_vpn': False,
    'profile_support': None,
}
EOF

# vim /etc/httpd/conf.d/openstack-dashboard.conf

# 在 WSGISocketPrefix run/wsgi 下面添加：

# WSGIApplicationGroup %{GLOBAL}

#完成安装
 systemctl restart httpd.service memcached.service


