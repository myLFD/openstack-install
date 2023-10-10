systemctl stop firewalld
yum install -y rabbitmq-server.loongarch64
systemctl enable rabbitmq-server
systemctl start rabbitmq-server


echo "fs.file-max=655350" >> /etc/sysctl.conf
echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf
echo "* soft nproc 65535" >> /etc/security/limits.conf
echo "* hard nproc 65535" >> /etc/security/limits.conf

sed -i '/\[Service\]/aLimitNOFILE=16384'  /usr/lib/systemd/system/rabbitmq-server.service

echo "cluster_partition_handling = autoheal"  >> /etc/rabbitmq/rabbitmq.conf

systemctl daemon-reload
systemctl restart rabbitmq-server
