#!/bin/bash
export PATH=$PATH:/sbin
check_node_and_evacuate (){
  echo "check_node_and_evacuate"
  ip a|grep 234
  ret=$?
  if [ $ret -ne 0 ]
  then 
      return
  fi
  source /root/openstack-rc
  num=`openstack hypervisor list -f value|grep up|wc -l`
  if [ $num -lt 2 ]
  then
     echo "live node < 2, do not execute evacuate"
    return
  fi

  openstack hypervisor list -f value| while read line
  do
    node=`echo $line|cut -d " " -f 2 `
    status=`echo $line|cut -d " " -f 5 `
    echo $name:$status
    if [ $status ==  "down" ]
    then
    echo $node is down, execute evacuate
    nova host-evacuate $node
    fi
  done

}
check_node_and_evacuate