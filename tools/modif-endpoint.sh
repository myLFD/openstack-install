 grep -r -i "openstack endpoint create --region RegionOne" *|cut -d ":" -f 2,3,4

 openstack endpoint create --region RegionOne   volumev2 public http://$vip:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev2 internal http://$vip:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev2 admin http://$vip:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 public http://$vip:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 internal http://$vip:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne   volumev3 admin http://$vip:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne image public http://$vip:9292
openstack endpoint create --region RegionOne image internal http://$vip:9292
openstack endpoint create --region RegionOne image admin http://$vip:9292
openstack endpoint create --region RegionOne   network public http://$vip:9696
openstack endpoint create --region RegionOne   network internal http://$vip:9696
openstack endpoint create --region RegionOne   network admin http://$vip:9696
openstack endpoint create --region RegionOne   compute public http://$vip:8774/v2.1
openstack endpoint create --region RegionOne   compute internal http://$vip:8774/v2.1
openstack endpoint create --region RegionOne   compute admin http://$vip:8774/v2.1
openstack endpoint create --region RegionOne   placement public http://$vip:8778
openstack endpoint create --region RegionOne   placement internal http://$vip:8778
openstack endpoint create --region RegionOne   placement admin http://$vip:8778

openstack-config --set /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri http://$vip:5001
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://$vip:5001
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://$vip:5001
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$vip:5001
openstack-config --set /etc/neutron/neutron.conf nova auth_url http://$vip:5001
openstack-config --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://$vip:5001
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://$vip:5001
openstack-config --set /etc/nova/nova.conf neutron auth_url http://$vip:5001
openstack-config --set /etc/nova/nova.conf placement auth_url http://$vip:5001/v3
openstack-config --set /etc/placement/placement.conf keystone_authtoken auth_url http://$vip:5001/v3


openstack-config --set /etc/nova/nova.conf glance api_servers http://$vip:9293


