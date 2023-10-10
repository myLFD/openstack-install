#!/bin/bash -e
set -x
#环境变量
source variable.sh


./compute-pre.sh
./variable.sh
./nova-compute.sh
./neutron-compute.sh
#如果需要支持热迁移, 打开下面配置
#./live-migration.sh
