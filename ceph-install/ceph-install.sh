#!/bin/bash
set -x

export host1=controller1
export host2=controller2
export host3=controller3
export ip1=10.40.73.252
export ip2=10.40.73.251
export ip3=10.40.73.249



ansible ceph -m script -a "ceph-pre.sh"
ansible ceph -m shell -a "yum install -y ceph-mon"

uuid=9bf24809-220b-4910-b384-c1f06ea80728
cat >> /etc/ceph/ceph.conf <<EOF
[global]
fsid = 9bf24809-220b-4910-b384-c1f06ea80728
mon_initial_members = $host1,$host2,$host3
mon_host = $ip1,$ip2,$ip3
public_network = 10.180.208.0/22
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
osd_journal_size = 1024
osd_pool_default_size = 3
osd_pool_default_min_size = 2
osd_pool_default_pg_num = 64
osd_pool_default_pgp_num = 64
osd_crush_chooseleaf_type = 1
EOF
ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
monmaptool --create --add $host1 $ip1 --add $host2 $ip2 --add $host3 $ip3  --fsid $uuid /tmp/monmap

ansible ceph -m synchronize  -a "src=/etc/ceph/ceph.client.admin.keyring dest=/etc/ceph/"
ansible ceph -m synchronize  -a "src=/var/lib/ceph/bootstrap-osd/ceph.keyring dest=/var/lib/ceph/bootstrap-osd/"
ansible ceph -m synchronize  -a "src=/tmp/ceph.mon.keyring dest=/tmp/"
ansible ceph -m synchronize  -a "src=/tmp/monmap dest=/tmp/"
ansible ceph -m synchronize  -a "src=/etc/ceph/ceph.conf dest=/etc/ceph/"

#install mon and mgr
ansible ceph -m script -a "ceph-post.sh"

#install dashboard
ceph config set mon auth_allow_insecure_global_id_reclaim false
ceph mon enable-msgr2

ceph mgr module enable dashboard
ceph dashboard create-self-signed-cert
ceph config set mgr mgr/dashboard/server_addr $ip1
ceph config set mgr mgr/dashboard/server_port 8080
ceph config set mgr mgr/dashboard/ssl_server_port 8443
echo '123456' > password.txt
ceph dashboard ac-user-create admin  administrator -i password.txt
ceph mgr services
