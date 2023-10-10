#!/bin/bash -e
set -x
source variable.sh
./pre_install.sh
./keystone.sh
source openstack-rc
./glance.sh
./placement.sh
./nova-controller.sh
./neutron-controller.sh
./dashboard.sh

#运行cinder.sh需要先手动执行两个步骤, 详见cinder.sh
#./cinder.sh

#status check
./status-check.sh
#crontab crontab.cron

