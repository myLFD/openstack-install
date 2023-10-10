openstack user create --domain default --password-prompt swift
openstack role add --project service --user swift admin
openstack service create --name swift \
  --description "OpenStack Object Storage" object-store
  openstack endpoint create --region RegionOne \
  object-store public http://controller:8080/v1/AUTH_%\(project_id\)s
   openstack endpoint create --region RegionOne \
  object-store internal http://controller:8080/v1/AUTH_%\(project_id\)s
  openstack endpoint create --region RegionOne \
  object-store admin http://controller:8080/v1
   yum install openstack-swift-proxy python-swiftclient \
  python-keystoneclient python-keystonemiddleware \
  memcached
  curl -o /etc/swift/proxy-server.conf https://opendev.org/openstack/swift/raw/branch/master/etc/proxy-server.conf-sample