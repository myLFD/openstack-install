yum install xfsprogs rsync
mkfs.xfs /dev/sdb1
mkfs.xfs /dev/sdc1

mkdir -p /srv/node/sdb
mkdir -p /srv/node/sdc

blkid

 /etc/fstab
UUID="<UUID-from-output-above>" /srv/node/sdb xfs noatime,nodiratime,logbufs=8 0 2
UUID="<UUID-from-output-above>" /srv/node/sdc xfs noatime,nodiratime,logbufs=8 0 2

mount /srv/node/sdb
mount /srv/node/sdc

#/etc/rsyncd.conf
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = MANAGEMENT_INTERFACE_IP_ADDRESS

[account]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/object.lock

systemctl enable rsyncd.service
systemctl start rsyncd.service

yum install openstack-swift-account openstack-swift-container \
  openstack-swift-object

curl -o /etc/swift/account-server.conf https://opendev.org/openstack/swift/raw/branch/master/etc/account-server.conf-sample
curl -o /etc/swift/container-server.conf https://opendev.org/openstack/swift/raw/branch/master/etc/container-server.conf-sample
curl -o /etc/swift/object-server.conf https://opendev.org/openstack/swift/raw/branch/master/etc/object-server.conf-sample

chown -R swift:swift /srv/node
mkdir -p /var/cache/swift
chown -R root:swift /var/cache/swift
chmod -R 775 /var/cache/swift

cd /etc/swift

sudo swift-ring-builder account.builder remove -u 0
sudo swift-ring-builder account.builder remove -u 1
sudo swift-ring-builder account.builder remove -u 2

sudo swift-ring-builder container.builder remove -u 0
sudo swift-ring-builder container.builder remove -u 1
sudo swift-ring-builder container.builder remove -u 2

sudo swift-ring-builder object.builder remove -u 0
sudo swift-ring-builder object.builder remove -u 1
sudo swift-ring-builder object.builder remove -u 2

rm -f *.gz

sudo swift-ring-builder account.builder create 10 1 1
sudo swift-ring-builder account.builder add --region 1 --zone 1 --ip 10.40.65.244 --port 6202 --device sdb --weight 100
sudo swift-ring-builder account.builder add --region 1 --zone 2 --ip 10.40.65.244 --port 6202 --device sdc --weight 100
sudo swift-ring-builder account.builder add --region 1 --zone 3 --ip 10.40.65.244 --port 6202 --device sdd --weight 100
swift-ring-builder account.builder rebalance



sudo swift-ring-builder container.builder create 10 1 1
sudo swift-ring-builder container.builder add --region 1 --zone 1 --ip 10.40.65.244 --port 6201 --device sdb --weight 100
sudo swift-ring-builder container.builder add --region 1 --zone 2 --ip 10.40.65.244 --port 6201 --device sdc --weight 100
sudo swift-ring-builder container.builder add --region 1 --zone 3 --ip 10.40.65.244 --port 6201 --device sdd --weight 100
swift-ring-builder container.builder rebalance


sudo swift-ring-builder object.builder create 10 1 1
sudo swift-ring-builder object.builder add --region 1 --zone 1 --ip 10.40.65.244 --port 6200 --device sdb --weight 100
sudo swift-ring-builder object.builder add --region 1 --zone 2 --ip 10.40.65.244 --port 6200 --device sdc --weight 100
sudo swift-ring-builder object.builder add --region 1 --zone 3 --ip 10.40.65.244 --port 6200 --device sdd --weight 100
swift-ring-builder object.builder rebalance

sudo swift-ring-builder account.builder
sudo swift-ring-builder container.builder
sudo swift-ring-builder object.builder
