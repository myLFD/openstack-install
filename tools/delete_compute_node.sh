set -x
source /root/openstack-rc
nodename=$1
echo $nodename

id=`nova service-list |grep nova-compute|grep $nodename|cut -d "|" -f 2`
nova service-disable $id

mysql -unova -ploongson -e "use nova;delete from nova.services where host='$nodename';"
mysql -unova -ploongson -e "use nova;delete from compute_nodes where hypervisor_hostname='$nodename'";

providerId=` openstack resource provider list |grep $nodename|cut -d "|" -f 2`
echo $providerId
openstack resource provider delete  $providerId

cellid=`nova-manage cell_v2 list_hosts|grep $nodename|cut -d "|" -f 3`
su -s /bin/sh -c "nova-manage cell_v2 delete_host --cell_uuid $cellid --host $nodename" nova

openstack compute service list --service nova-compute