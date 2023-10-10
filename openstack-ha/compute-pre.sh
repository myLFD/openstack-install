#!/bin/bash

cp ../cloud.repo /etc/yum.repos.d
rpm -e python3-urllib3.noarch --nodeps
yum install python3-urllib3 -y
#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
#关闭SELinux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
#关闭swap分区
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


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
sysctl -p

yum clean all
yum makecache
sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/Loongnix-PowerTools.repo
sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/Loongnix-Plus.repo
#设置时间同步
yum reinstall -y chrony && yum -y autoremove
sed -i '/^pool/d' /etc/chrony.conf
sed -i '/^server/d' /etc/chrony.conf
echo "pool ntp.aliyun.com iburst" >> /etc/chrony.conf
systemctl start chronyd.service && systemctl enable chronyd.service
chronyc sources

#安装openstack命令
yum install -y python3-openstackclient openstack-utils
