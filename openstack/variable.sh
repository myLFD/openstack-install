#!/bin/bash 
#环境变量
export rabbitmq_pass='loongson'
export keystone_pass='loongson'
export mysql_root_pass='loongson'
export glance_pass='loongson'
export nova_pass='loongson'
export placement_pass='loongson'
export neutron_pass='loongson'
export cinder_pass='loongson'
#控制节点的ip
export controller=192.168.100.142
#BOOTPROTO="none"的网卡
export ext_interface=enp0s3f1

#计算节点的ip(控制节点不需要配置)
export compute=192.168.100.142
#BOOTPROTO="none"的网卡
export compute_interface=enp0s3f1
