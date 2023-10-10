#!/bin/bash
set -x
yum install -y loongnix-release-ceph-nautilus
systemctl disable --now firewalld
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
yum install -y chrony
sed -i '/^pool/d' /etc/chrony.conf
sed -i '/^server/d' /etc/chrony.conf
echo "pool ntp.aliyun.com iburst" >> /etc/chrony.conf
systemctl restart chronyd.service && systemctl enable chronyd.service
timedatectl status
chronyc sources
