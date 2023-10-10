#1 做raid
number=`storcli64_ls /c0 show | grep "252:"|cut -d " " -f 1|sed 's/\s\+/,/g'`
number=`echo $number |sed 's/\s\+/,/g'`
echo $number
storcli64_ls -CfgClr -aALL
storcli64_ls -CfgForeign -Clear –aALL 
storcli64_ls /c0 add VD r0 Size=all name=raid0 drives=$number
#查看结果
fdisk -l
#根据实际情况修改可能是sdb,sdc等等
block=/dev/sda

#2  
#大于2T的硬盘

parted $block mklabel gpt
parted $block mkpart $block xfs 1 100%
# mklabel gpt
# mkpart /dev/sda
# sdb1
# xfs
# 1
# 100%
# quit

#小于等于2T的硬盘
fdisk -l

3 #做文件系统
mkfs.xfs /dev/sda1
4
id=`ll /dev/disk/by-uuid/|grep sda1|cut -d " " -f 10`
echo $id

5 #计算节点

mkdir /openstack
echo "UUID=$id /openstack xfs defaults 1 2" >> /etc/fstab
mount -a
mkdir -p /openstack/instances
cp -rf /var/lib/nova/instances/* /openstack/instances

rm -rf /var/lib/nova/instances
ln -s -f /openstack/instances /var/lib/nova/instances
chown -R nova:nova /var/lib/nova/instances
chown -R nova:nova /openstack/instances
systemctl restart openstack-nova-compute.service


#控制节点
mkdir -p  /openstack
mount /dev/sda1 /openstack
echo " /dev/sda1 /openstack ext4 defaults 1 2" >> /etc/fstab
rm -rf /var/lib/glance/images
mkdir -p /openstack/images
ln -s -f /openstack/images /var/lib/glance/images
chown glance:glance /var/lib/glance/images

storcli64_ls /c0/v0 delete force
storcli64_ls -CfgClr -aALL
storcli64_ls -CfgForeign -Clear –aALL 
storcli64_ls /c0 set jbod=off
storcli64_ls /c0 set jbod=on
#设置直连模式可以直接看到硬盘, 不用做raid

#删除遗留的ceph lvm
ls  /dev/mapper/ceph* |xargs dmsetup remove

#ceph-volume lvm create: error: GPT headers found, they must be removed on: /dev/sdb
sgdisk --zap-all /dev/sdd