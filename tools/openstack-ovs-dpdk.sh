1 安装dpdk
yum install -y dpdk-devel

2 编译安装ovs-dpdk
wget https://download.fedoraproject.org/pub/fedora/linux/releases/36/Everything/source/tree/Packages/o/openvswitch-2.16.0-2.fc36.src.rpm
rpm -ivh openvswitch-2.16.0-2.fc36.src.rpm
cd /root/rpmbuild/SPECS

修改openvswitch.spec
%define dpdkarches aarch64 i686 ppc64le x86_64  
%define dpdkarches aarch64 i686 ppc64le x86_64 loongarch64

yum install -y yum-utils rpm-build
#更新源为最新的源, 否则依赖会安装失败
yum-builddep openvswitch.spec
rpmbuild -ba openvswitch.spec  --with dpdk

cd /root/rpmbuild/RPMS/loongarch64/
rpm -ivh openvswitch-2.16.0-2.lns8.loongarch64.rpm
rpm -ivh openvswitch-devel-2.16.0-2.lns8.loongarch64.rpm

3 开启大页
echo 384 > /sys/devices/system/node/node0/hugepages/hugepages-32768kB/nr_hugepages
grep HugePages_ /proc/meminfo
mount -t hugetlbfs none /dev/hugepages

4 启动ovs-dpdk

mkdir -p /var/run/openvswitch
modprobe openvswitch


 #Clean the environment

killall ovsdb-server ovs-vswitchd
# rm -f /var/run/openvswitch/vhost-user*
# rm -f /etc/openvswitch/conf.db

#Start database server

export DB_SOCK=/var/run/openvswitch/db.sock
ovsdb-tool create /etc/openvswitch/conf.db /usr/share/openvswitch/vswitch.ovsschema
ovsdb-server --remote=punix:$DB_SOCK --remote=db:Open_vSwitch,Open_vSwitch,manager_options --pidfile --detach

#Start OVS

ovs-vsctl --no-wait init
#ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-lcore-mask=0xf
#ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem=1024
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
ovs-vswitchd unix:$DB_SOCK --pidfile --detach --log-file=/var/log/openvswitch/ovs-vswitchd.log

ovs-vswitchd --version
# ovs-vswitchd (Open vSwitch) 2.16.0
# DPDK 20.11.2
ovs-vsctl get Open_vSwitch . dpdk_version
# "DPDK 20.11.2"
ovs-vsctl get Open_vSwitch . dpdk_initialized
#true
modprobe uio
modprobe uio_pci_generic

dpdk-devbind.py -b uio_pci_generic 0000:00:03.1

ovs-vsctl add-br br-ex -- set bridge br-ex datapath_type=netdev
ovs-vsctl add-port br-ex dpdk-eth -- set interface dpdk-eth type=dpdk options:dpdk-devargs=0000:00:03.1


