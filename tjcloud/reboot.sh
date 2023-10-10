#!/bin/bash
export PATH=$PATH:/sbin
#vip=10.10.130.234
source /root/openstack-rc
rm -f /var/lib/mysql/gvwstate.dat
rm -f /var/lib/mysql/grastate.dat
reinit_db_cluster(){
  echo "reinit_db_cluster"
  ip a|grep $vip
  ret=$?
  if [ $ret -ne 0 ]
  then 
     return
  fi
  ansible controller1 -m shell  -a "systemctl is-active mariadb"
  dbret1=$?
  ansible controller2 -m shell  -a "systemctl is-active mariadb"
  dbret2=$?
  ansible controller3 -m shell  -a "systemctl is-active mariadb"
  dbret3=$?
  echo "$dbret1,$dbret2,$dbret3"
  ansible controller1 -m shell  -a "ls /var/lib/mysql/gvwstate.dat"
  gvret1=$?
  ansible controller2 -m shell  -a "ls /var/lib/mysql/gvwstate.dat"
  gvret2=$?
  ansible controller3 -m shell  -a "ls /var/lib/mysql/gvwstate.dat"
  gvret3=$?
  echo "$gvret1,$gvret2,$gvret3"
  if [ $dbret1 -ne 0 ] && [ $dbret2 -ne 0 ] && [ $dbret3 -ne 0 ]
  then
    #如果三个gvwstate都存在
    if [ $gvret1 -eq 0 ] && [ $gvret2 -eq 0 ] && [ $gvret3 -eq 0 ]
    then
    　　#删除所有gvwstate
        ansible compute -m shell -a "rm -f /var/lib/mysql/gvwstate.dat"
    fi
        ansible compute -m shell -a "rm -f /var/lib/mysql/grastate.dat"
        ansible compute -m shell -a "pkill mysql"
        galera_new_cluster
  fi
  systemctl is-active mariadb


}

for service in keepalived haproxy memcached  mariadb httpd 
do
echo $(date +%F%T) $service
systemctl  is-active $service  
res=$?
  if [ $res -eq 0 ] 
  then
    echo $service is running
  else
    echo "$service is down, try to restart the service"
    systemctl stop $service
    systemctl start $service
    systemctl   is-active $service 
    res=$?
    if [ $res -eq 0 ] 
    then
      echo restart  success
    elif [ $service == "mariadb" ]
    then
      reinit_db_cluster
    elif [ $service == "haproxy" ]
    then
       echo "haproxy restart failed, restart keepalived "
       systemctl restart keepalived
    else 
      echo restart failed
    fi  
  fi  
  echo "";
done
echo "reboot config finish"
