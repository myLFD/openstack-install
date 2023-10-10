#!/bin/bash 
set -x
cp ../cloud.repo /etc/yum.repos.d

rpm -e python3-urllib3.noarch --nodeps
yum install python3-urllib3 -y
#yum install -y loongnix-release-rabbitmq-38.noarch loongnix-release-ceph-nautilus.noarch loongnix-release-openstack-ussuri.noarch loongnix-release-epel.noarch
#关闭防火墙
yum clean all
yum makecache
systemctl stop firewalld
systemctl disable firewalld
#关闭SELinux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
#关闭swap分区
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#设置内核
modprobe bridge
modprobe br_netfilter
cat > /etc/sysconfig/modules/neutron.modules <<EOF
#!/bin/bash
modprobe -- bridge
modprobe -- br_netfilter
EOF
chmod 755 /etc/sysconfig/modules/neutron.modules && bash /etc/sysconfig/modules/neutron.modules
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" >> /etc/sysctl.conf
echo "fs.file-max=655350" >> /etc/sysctl.conf

sysctl -p

#设置时间同步
yum reinstall -y chrony && yum -y autoremove
sed -i '/^pool/d' /etc/chrony.conf
sed -i '/^server/d' /etc/chrony.conf
echo "pool ntp.aliyun.com iburst" >> /etc/chrony.conf
systemctl restart chronyd.service && systemctl enable chronyd.service
timedatectl status
chronyc sources
sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/Loongnix-PowerTools.repo
sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/Loongnix-Plus.repo
#安装openstack命令
yum install -y python3-openstackclient openstack-utils

#安装sql


#消息队列Message queue(本地安装)


#内存缓存
yum install -y memcached python3-memcached
sed -i '/OPTIONS/d' /etc/sysconfig/memcached
echo 'OPTIONS=""' >> /etc/sysconfig/memcached

systemctl enable memcached.service
systemctl restart memcached.service

yum install -y expect

