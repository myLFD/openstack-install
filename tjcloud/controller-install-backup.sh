#!/bin/bash -e
set -x
source variable-ha.sh
./pre_install.sh
./keystone-backup.sh
source openstack-rc
./glance-backup.sh
./placement_backup.sh
./nova-controller-backup.sh
./neutron-controller-backup.sh
./dashboard-master.sh

#运行cinder.sh需要先手动执行两个步骤, 详见cinder.sh
#./cinder.sh

#status check
./status-check.sh
#crontab crontab.cron

