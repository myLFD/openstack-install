#!/bin/bash
export PATH=$PATH:/sbin
#vip=10.10.130.234
echo $(date +%F%T)
source /root/variable-ha.sh
echo $vip
ping $vip -c 1
ret=$?
if [ $ret -ne 0 ]
then 
     echo "vip not ready,quit"
     return
fi


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

}
checkVmStatus(){
  ip a|grep $vip
  ret=$?
  if [ $ret -ne 0 ]
  then 
      return
  fi
  source /root/openstack-rc
  openstack server list --long -f value -c ID -c "Power State" -c Status -c "Task State" -c "Networks" -c "Host"| while read line
  do
   
    id=`echo $line|cut -d " " -f 1 `
    status=`echo $line|cut -d " " -f 2 `
    taskState=`echo $line|cut -d " " -f 3`
    powerState=`echo $line|cut -d " " -f 4 `
#using public network
    ip=`echo $line|cut -d " " -f 5|cut -d "=" -f 2 `
    host=`echo $line|cut -d " " -f 6 `
#using private network
   # ip=`echo $line|cut -d " " -f 6 `
   # host=`echo $line|cut -d " " -f 7 `

    echo $id:$status:$taskState:$powerState:$ip:$host
    if [ $status ==  "HARD_REBOOT" ] || [ $status ==  "rebuilding" ] || [ $status ==  "RESIZE" ]
    then
        echo "$id status is $status"
        continue
    fi

    if [ $powerState ==  "NOSTATE" ] || [ $powerState ==  "Paused" ] || [ $powerState ==  "Shutdown" ]
    then
        echo "$id powerState is $powerState"
        nova reboot $id  --hard
    fi
 
    if [ $taskState == "powering-off" ]
    then
        echo "$id is down, modify state"
        mysql -uroot -ploongson -e "use nova;update instances set task_state=NULL where uuid='$id';"
        nova reboot $id --hard
    fi
    if [ $status == "ERROR" ]
    then
        echo "$id is error, reset status"
        nova reset-state $id --active
        nova reboot $id  --hard
    fi
  ping $ip -c 1
  ret=$?
  if [ $ret -ne 0 ] && [ $powerState = "Running" ] && [ $status == "ACTIVE" ]
  then
     echo "$ip can not be ping reboot"
     num=`openstack hypervisor list -f value|grep up|wc -l`
     if [ $num -lt 2 ]
     then
        echo "live node < 2, do nothing"
        return
     fi 
     ping $host -c 1
     ret=$?
     if [ $ret -ne 0 ]
     then
       return
     fi
     echo "vm is down reboot"
     nova reboot $id  --hard
     return
  fi

   done

}


checkProviderEth(){
ifconfig enp0s3f1|grep -i running
ret=$?
if [ $ret -ne 0 ]
then  
      reboot
fi
}


checkRabbitmqCluster(){
  ip a|grep $vip
  ret=$?
  if [ $ret -eq 0 ]
  then 
      
      return
  fi
  rabbitmqctl cluster_status|grep partitions|grep controller
  ret=$?
  if [ $ret -eq 0 ]
  then 
    echo "rabbitmq occurs partitions, reset"
    ansible controller -m shell -a "systemctl restart rabbitmq-server"
  fi
}

for service in  memcached rabbitmq-server mariadb httpd openstack-glance-api \
    neutron-linuxbridge-agent neutron-server neutron-metadata-agent neutron-dhcp-agent  neutron-l3-agent \
    openstack-nova-scheduler openstack-nova-api openstack-nova-novncproxy  openstack-nova-conductor.service \
    openstack-cinder-volume openstack-cinder-api openstack-cinder-scheduler openstack-nova-compute
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
    elif [ $service == "rabbitmq-server" ]
    then
      rabbitmqctl force_boot
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
checkVmStatus
checkProviderEth
checkRabbitmqCluster