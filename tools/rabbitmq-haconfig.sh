rabbitmqctl set_policy HA '^(?!amq.).*' '{"ha-mode": "all"}'

#nova
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,controller2:5672,controller3:5672
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_durable_queues true
systemctl restart openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service openstack-nova-compute

#cinder
openstack-config --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,controller2:5672,controller3:5672
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_durable_queues true
systemctl restart  openstack-cinder-volume openstack-cinder-api openstack-cinder-scheduler
#neutron
openstack-config --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,controller2:5672,controller3:5672
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true
systemctl restart neutron-linuxbridge-agent neutron-server neutron-metadata-agent neutron-dhcp-agent  neutron-l3-agent
#glance
openstack-config --set /etc/glance/glance-api.conf DEFAULT transport_url rabbit://openstack:loongson@controller1:5672,controller2:5672,controller3:5672
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_durable_queues true
systemctl restart openstack-glance-api 