#!/bin/bash -e
set -x

HEAT_PASS=loongson
source opentack-rc
source variable.sh
mysql -uroot -p$mysql_root_pass -e "CREATE DATABASE heat;"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '$HEAT_PASS';"
mysql -uroot -p$mysql_root_pass -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%'  IDENTIFIED BY '$HEAT_PASS';"


expect <<EOF
  set timeout 300
  spawn  bash -c "openstack user create --domain default --password-prompt heat"
  expect {
    "*Password*" {send "$HEAT_PASS\r";exp_continue}
    "*Password*" {send "$HEAT_PASS\r";}
   }
  
EOF

openstack role add --project service --user heat admin
openstack service create --name heat  --description "Orchestration" orchestration
openstack service create --name heat-cfn --description "Orchestration"  cloudformation
openstack endpoint create --region RegionOne  orchestration public http://controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  orchestration internal http://controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  orchestration admin http://controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne  cloudformation public http://controller:8000/v1
openstack endpoint create --region RegionOne  cloudformation internal http://controller:8000/v1
openstack endpoint create --region RegionOne  cloudformation admin http://controller:8000/v1
openstack domain create --description "Stack projects and users" heat
expect <<EOF
  set timeout 300
  spawn  bash -c " openstack user create --domain heat --password-prompt heat_domain_admin"
  expect {
    "*Password*" {send "$HEAT_PASS\r";exp_continue}
    "*Password*" {send "$HEAT_PASS\r";}
   }
  
EOF
openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
openstack role create heat_stack_owner
openstack role add --project admin --user admin heat_stack_owner
openstack role create heat_stack_user
yum install -y openstack-heat-api openstack-heat-api-cfn   openstack-heat-engine
pip3 install  python-ironicclient
pip3 install python-blazarclient
pip3 install python-vitrageclient
pip3 install python-zunclient

openstack-config --set /etc/heat/heat.conf DEFAULT debug false
openstack-config --set /etc/heat/heat.conf DEFAULT heat_metadata_server_url  http://controller:8000
openstack-config --set /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url  http://controller:8000/v1/waitcondition
openstack-config --set /etc/heat/heat.conf DEFAULT stack_domain_admin  heat_domain_admin
openstack-config --set /etc/heat/heat.conf DEFAULT stack_domain_admin_password   $HEAT_PASS
openstack-config --set /etc/heat/heat.conf DEFAULT stack_user_domain_name  heat

openstack-config --set /etc/heat/heat.conf database connection mysql+pymysql://heat:$HEAT_DBPASS@controller/heat
openstack-config --set /etc/heat/heat.conf DEFAULT  transport_url rabbit://openstack:$rabbitmq_pass@$controller:5672
openstack-config --set /etc/heat/heat.conf keystone_authtoken www_authenticate_uri http://controller:5000
openstack-config --set /etc/heat/heat.conf keystone_authtoken auth_url http://controller:5000
openstack-config --set /etc/heat/heat.conf keystone_authtoken memcached_servers controller:11211
openstack-config --set /etc/heat/heat.conf keystone_authtoken auth_type password
openstack-config --set /etc/heat/heat.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/heat/heat.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/heat/heat.conf keystone_authtoken project_name service
openstack-config --set /etc/heat/heat.conf keystone_authtoken username heat
openstack-config --set /etc/heat/heat.conf keystone_authtoken password $HEAT_PASS

openstack-config --set /etc/heat/heat.conf trustee auth_type  password
openstack-config --set /etc/heat/heat.conf trustee auth_url  http://controller:5000
openstack-config --set /etc/heat/heat.conf trustee username  heat
openstack-config --set /etc/heat/heat.conf trustee password  $HEAT_PASS
openstack-config --set /etc/heat/heat.conf trustee user_domain_name  default

openstack-config --set /etc/heat/heat.conf  clients_keystone auth_uri  http://controller:5000
su -s /bin/sh -c "heat-manage db_sync" heat
 systemctl enable openstack-heat-api.service \
  openstack-heat-api-cfn.service openstack-heat-engine.service
 systemctl restart openstack-heat-api.service \
  openstack-heat-api-cfn.service openstack-heat-engine.service
yum install -y openstack-heat-ui
systemctl restart httpd
