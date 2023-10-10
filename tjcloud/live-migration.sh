#!/bin/bash -e
set -x



if [ ! -f "/etc/libvirt/libvirtd.conf.bak" ];
then
    cp  /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.bak
fi

if [ ! -f "/etc/sysconfig/libvirtd.bak" ];
then
   cp  /etc/sysconfig/libvirtd /etc/sysconfig/libvirtd.bak
fi

cat > /etc/libvirt/libvirtd.conf <<EOF
listen_tls = 0
listen_tcp = 1
tcp_port = "16509"
listen_addr = "0.0.0.0"
auth_tcp = "none"
EOF

cat > /etc/sysconfig/libvirtd <<EOF
LIBVIRTD_ARGS="--listen"
LIBVIRTD_CONFIG=/etc/libvirt/libvirtd.conf
EOF
cat /etc/libvirt/libvirtd.conf
cat /etc/sysconfig/libvirtd
systemctl restart libvirtd
systemctl is-active libvirtd

#openstack-config --set /etc/nova/nova.conf libvirt  live_migration_bandwidth 5
