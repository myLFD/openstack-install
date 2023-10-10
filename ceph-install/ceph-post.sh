#!/bin/bash
set -x
hostname=`hostname`
sudo -u ceph mkdir -p /var/lib/ceph/mon/ceph-$hostname
chown ceph.ceph -R /var/lib/ceph /etc/ceph /tmp/ceph.mon.keyring /tmp/monmap
sudo -u ceph ceph-mon --mkfs -i $hostname --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
ls /var/lib/ceph/mon/ceph-$hostname
systemctl start ceph-mon@$hostname
systemctl enable ceph-mon@$hostname
systemctl is-active ceph-mon@$hostname

yum install -y ceph-mgr
mkdir -p /var/lib/ceph/mgr/ceph-$hostname
hostname=`hostname`
chown ceph.ceph -R /var/lib/ceph
ceph-authtool --create-keyring /etc/ceph/ceph.mgr.$hostname.keyring --gen-key -n mgr.$hostname --cap mon 'allow profile mgr' --cap osd 'allow *' --cap mds 'allow *'
ceph auth import -i /etc/ceph/ceph.mgr.$hostname.keyring
ceph auth get-or-create mgr.$hostname -o /var/lib/ceph/mgr/ceph-$hostname/keyring
systemctl start ceph-mgr@$hostname
systemctl enable ceph-mgr@$hostname
systemctl is-active ceph-mgr@$hostname
