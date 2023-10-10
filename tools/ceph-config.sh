#controller
openstack-config --set /etc/glance/glance-api.conf glance_store stores rbd
openstack-config --set /etc/glance/glance-api.conf glance_store default_store rbd
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_pool images
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_user glance
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_chunk_size 8
openstack-config --set /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
openstack-config --set /etc/glance/glance-api.conf DEFAULT show_multiple_locations  True
systemctl restart openstack-glance-api.service

export uuid=3786b87e-0447-4b47-856a-06f5661213e2
openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends  lvm,ceph
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


#compute
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