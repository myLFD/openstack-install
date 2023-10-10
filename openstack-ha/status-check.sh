for service in keepalived haproxy  memcached rabbitmq-server mariadb httpd openstack-glance-api \
    neutron-openvswitch-agent.service neutron-server neutron-metadata-agent neutron-dhcp-agent  neutron-l3-agent \
    openstack-nova-scheduler openstack-nova-api openstack-nova-novncproxy openstack-nova-conductor.service \
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
    else 
      echo restart failed
    fi  
  fi  
  echo "";
done
