#!/bin/bash -e
set -x
source variable-ha.sh
./pre_install.sh
./keystone-master.sh
source openstack-rc
./glance-master.sh
./placement_master.sh
./nova-controller-master.sh
./neutron-controller-master.sh
./dashboard-master.sh

#运行cinder.sh需要先手动执行两个步骤, 详见cinder.sh
#./cinder.sh

#status check
./status-check.sh
#crontab crontab.cron

