net=`ifconfig|grep RUNNING|grep enp |cut -d ":" -f 1|grep -v lo`
filename=`grep -l $net /etc/sysconfig/network-scripts/*`
echo $filename
ip=`grep IPADDR $filename|cut -d "=" -f 2`
echo $net
echo $ip
sed -i '/compute/d' /root/openstack-install/openstack/variable.sh
echo "export compute=$ip" >> /root/openstack-install/openstack/variable.sh
echo "export compute_interface=$net" >> /root/openstack-install/openstack/variable.sh
cat /root/openstack-install/openstack/variable.sh
chmod +x /root/openstack-install/openstack/*.sh
systemctl is-active openstack-nova-compute
res=$?
if [ $res -eq 0 ]
then
 echo "Already running"
 exit 0;
fi
cd /root/openstack-install/openstack/
/root/openstack-install/openstack/compute-install.sh >>/root/install.log