mkdir /opt/localrepo
cd /opt/localrepo
yum install yum-utils  -y
yumdownloader --resolve --alldeps  git
yumdownloader --resolve --alldeps lvm2 device-mapper-persistent-data 
yumdownloader --resolve --alldeps openstack-cinder targetcli 
yumdownloader --resolve --alldeps  python3-openstackclient openstack-utils
yumdownloader --resolve --alldeps openstack-dashboard mod_ssl
yumdownloader --resolve --alldeps openstack-glance
yumdownloader --resolve --alldeps  openstack-keystone httpd mod_wsgi
yumdownloader --resolve --alldeps openstack-keystone httpd python3-mod_wsgi
yumdownloader --resolve --alldeps  openstack-neutron-linuxbridge ebtables ipset openstack-neutron openstack-neutron-ml2
yumdownloader --resolve --alldeps  openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables
yumdownloader --resolve --alldeps  openstack-neutron-linuxbridge ebtables ipset
yumdownloader --resolve --alldeps openstack-nova-compute openstack-selinux openstack-utils
yumdownloader --resolve --alldeps  dmidecode
yumdownloader --resolve --alldeps  libvirt-client libvirt-daemon-config-network libvirt-daemon-kvm 
yumdownloader --resolve --alldeps  openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler
yumdownloader --resolve --alldeps  openstack-placement-api
yumdownloader --resolve --alldeps  python3-openstackclient openstack-utils
yumdownloader --resolve --alldeps  mariadb mariadb-server python3-PyMySQL
yumdownloader --resolve --alldeps  rabbitmq-server.loongarch64
yumdownloader --resolve --alldeps  memcached python3-memcached
yumdownloader --resolve --alldeps yum-utils expect
yumdownloader --resolve --alldeps ansible

cd /opt
tar -czvf localrepo.tar.gz /opt/localrepo




