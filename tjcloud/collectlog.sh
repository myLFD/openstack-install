unalias cp
mkdir -p /var/log/tjlog
rm -f /var/log/tjlog/*
cd /var/log/tjlog
cp /var/log/nova/*.log  /var/log/tjlog
cp /var/log/neutron/*.log  /var/log/tjlog
cp /var/log/glance/*.log  /var/log/tjlog
cp /var/log/httpd/*.log  /var/log/tjlog
cp /var/log/cinder/*.log  /var/log/tjlog
cp /var/log/rabbitmq/*.log  /var/log/tjlog

mv /var/log/nova/*.gz  /var/log/tjlog
mv /var/log/neutron/*.gz  /var/log/tjlog
mv /var/log/glance/*.gz  /var/log/tjlog
mv /var/log/httpd/*.gz  /var/log/tjlog
mv /var/log/cinder/*.gz  /var/log/tjlog
mv /var/log/rabbitmq/*.gz  /var/log/tjlog

cp /var/log/status.log /var/log/tjlog
cp /var/log/restatus.log /var/log/tjlog
cp /var/log/evacuate-node.log /var/log/tjlog
cp /var/log/clean-cache.log /var/log/tjlog
cp /var/log/chronyd_reset.log /var/log/tjlog
cp /var/log/messages  /var/log/tjlog
filename=`date +%Y%m%d%H%M`
tar -czvf $filename.tar.gz * |xargs rm -f
