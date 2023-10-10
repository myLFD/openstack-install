计算节点
fdiks -L
fdisk /dev/sda 
mkfs.ext4 /dev/sda1  

ls -l /dev/disk/by-uuid

mkdir -p  /openstack

echo "UUID= /openstack ext4 defaults 1 2" >> /etc/fstab
mount -a
mkdir -p /openstack/instances
rm -rf /var/lib/nova/instances
ln -s -f /openstack/instances /var/lib/nova/instances
chown nova:nova /var/lib/nova/instances

#控制节点
mkdir -p  /openstack
mount /dev/sda1 /openstack
echo " /dev/sda1 /openstack ext4 defaults 1 2" >> /etc/fstab
rm -rf /var/lib/glance/images
mkdir -p /openstack/images
ln -s -f /openstack/images /var/lib/glance/images
chown glance:glance /var/lib/glance/images


