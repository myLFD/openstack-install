
#1 ceph节点
ceph osd pool create volumes 128
ceph osd pool create images 128
#ceph osd pool create backups
ceph osd pool create vms 128

rbd pool init volumes
rbd pool init images
#rbd pool init backups
rbd pool init vms
ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'


for controllerIp in 10.10.130.226 10.10.130.227 10.10.130.228
do
##The nodes running glance-api, cinder-volume, nova-compute and cinder-backup act as Ceph clients. Each requires the ceph.conf file:
  ssh $controllerIp sudo tee /etc/ceph/ceph.conf </etc/ceph/ceph.conf

  #ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'

  ceph auth get-or-create client.glance | ssh $controllerIp sudo tee /etc/ceph/ceph.client.glance.keyring
  ssh $controllerIp sudo chown glance:glance /etc/ceph/ceph.client.glance.keyring
  ceph auth get-or-create client.cinder | ssh $controllerIp sudo tee /etc/ceph/ceph.client.cinder.keyring
  ssh $controllerIp sudo chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring
##ceph auth get-or-create client.cinder-backup | ssh $controllerIp sudo tee /etc/ceph/ceph.client.cinder-backup.keyring
#ssh $controllerIp sudo chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring
done

for computeIp in 10.10.130.226 10.10.130.227 10.10.130.228
do
  ssh $computeIp sudo tee /etc/ceph/ceph.conf </etc/ceph/ceph.conf
  ceph auth get-or-create client.cinder | ssh $computeIp sudo tee /etc/ceph/ceph.client.cinder.keyring
  ceph auth get-key client.cinder | ssh $computeIp tee client.cinder.key
# uuidgen
#    3786b87e-0447-4b47-856a-06f5661213e2
done 
#2 控制节点和计算节点
ansible compute -m shell -a "yum install ceph-common python-rbd -y"
ansible controller -m shell -a "yum install ceph-common python-rbd -y"

#3 计算节点
cat > ./temp.sh <<eof

cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>3786b87e-0447-4b47-856a-06f5661213e2</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF
sudo virsh secret-define --file secret.xml
sudo virsh secret-set-value --secret 3786b87e-0447-4b47-856a-06f5661213e2 --base64 $(cat client.cinder.key) 
eof
ansible compute -m script -a "temp.sh"
4 修改glance的配置文件
#控制节点 Edit /etc/glance/glance-api.conf and add under the [glance_store] section:
# [glance_store]
# stores = rbd
# default_store = rbd
# rbd_store_pool = images
# rbd_store_user = glance
# rbd_store_ceph_conf = /etc/ceph/ceph.conf
# rbd_store_chunk_size = 8
# [DEFAULT]
# show_image_direct_url = True
openstack-config --set /etc/glance/glance-api.conf glance_store stores rbd
openstack-config --set /etc/glance/glance-api.conf glance_store default_store rbd
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_pool images
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_user glance
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_chunk_size 8
openstack-config --set /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
openstack-config --set /etc/glance/glance-api.conf DEFAULT show_multiple_locations  True

systemctl restart openstack-glance-api.service
# We recommend to use the following properties for your images:

# hw_scsi_model=virtio-scsi: add the virtio-scsi controller and get better performance and support for discard operation
# hw_disk_bus=scsi: connect every cinder block devices to that controller
# hw_qemu_guest_agent=yes: enable the QEMU guest agent
# os_require_quiesce=yes: send fs-freeze/thaw calls through the QEMU guest agent

5 配置cinder

# [DEFAULT]
# enabled_backends = ceph
# glance_api_version = 2
# [ceph]
# volume_driver = cinder.volume.drivers.rbd.RBDDriver
# volume_backend_name = ceph
# rbd_pool = volumes
# rbd_ceph_conf = /etc/ceph/ceph.conf
# rbd_flatten_volume_from_snapshot = false
# rbd_max_clone_depth = 5
# rbd_store_chunk_size = 4
# rados_connect_timeout = -1
# rbd_user = cinder
# rbd_secret_uuid = $uuid
export uuid=3786b87e-0447-4b47-856a-06f5661213e2
openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends  ceph
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_version  2
openstack-config --set /etc/cinder/cinder.conf ceph volume_driver  cinder.volume.drivers.rbd.RBDDriver
openstack-config --set /etc/cinder/cinder.conf ceph volume_backend_name  ceph
openstack-config --set /etc/cinder/cinder.conf ceph rbd_pool  volumes
openstack-config --set /etc/cinder/cinder.conf ceph rbd_ceph_conf  /etc/ceph/ceph.conf
openstack-config --set /etc/cinder/cinder.conf ceph rbd_flatten_volume_from_snapshot  false
openstack-config --set /etc/cinder/cinder.conf ceph rbd_max_clone_depth  5
openstack-config --set /etc/cinder/cinder.conf ceph rbd_store_chunk_size 4
openstack-config --set /etc/cinder/cinder.conf ceph rados_connect_timeout -1
openstack-config --set /etc/cinder/cinder.conf ceph rbd_user cinder
openstack-config --set /etc/cinder/cinder.conf ceph rbd_secret_uuid $uuid
systemctl restart openstack-cinder-volume.service target.service openstack-cinder-api.service openstack-cinder-scheduler.service
cinder type-create ceph
cinder type-key ceph set volume_backend_name=ceph

6 配置nova

# [libvirt]
# images_type = rbd
# images_rbd_pool = vms
# images_rbd_ceph_conf = /etc/ceph/ceph.conf
# rbd_user = cinder
# # uuid前后一致
# rbd_secret_uuid = 10744136-583f-4a9c-ae30-9bfb3515526b
# disk_cachemodes="network=writeback"
# live_migration_flag="VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"
# # 禁用文件注入
# inject_password = false
# inject_key = false
# inject_partition = -2
# # 虚拟机临时root磁盘discard功能，”unmap”参数在scsi接口类型磁盘释放后可立即释放空间
# hw_disk_discard = unmap
export uuid=3786b87e-0447-4b47-856a-06f5661213e2
openstack-config --set /etc/nova/nova.conf libvirt images_type rbd
openstack-config --set /etc/nova/nova.conf libvirt images_rbd_pool vms
openstack-config --set /etc/nova/nova.conf libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/nova/nova.conf libvirt rbd_user cinder
openstack-config --set /etc/nova/nova.conf libvirt rbd_secret_uuid  $uuid
openstack-config --set /etc/nova/nova.conf libvirt disk_cachemodes '"network=writeback"'
openstack-config --set /etc/nova/nova.conf libvirt live_migration_flag "VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"
openstack-config --set /etc/nova/nova.conf libvirt inject_password false
openstack-config --set /etc/nova/nova.conf libvirt inject_key false
openstack-config --set /etc/nova/nova.conf libvirt inject_partition -2 
openstack-config --set /etc/nova/nova.conf libvirt hw_disk_discard unmap
systemctl restart openstack-nova-compute.service 