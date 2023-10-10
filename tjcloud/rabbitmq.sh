#controller1 192.168.200.1
#controller2 192.168.200.2
#vip 192.168.200.3


#1 两台机器分别执行
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

cat > /etc/rabbitmq/rabbitmq.config <<EOF
[
 {rabbit, [
           {cluster_partition_handling, autoheal}
          ]
 }

].
EOF

systemctl daemon-reload
systemctl restart rabbitmq-server

#2
#controller1
scp /var/lib/rabbitmq/.erlang.cookie root@controller2:/var/lib/rabbitmq

rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl start_app
rabbitmqctl cluster_status
rabbitmq-plugins enable rabbitmq_management
#controller2
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
systemctl stop rabbitmq-server
systemctl start rabbitmq-server
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@controller1
rabbitmqctl start_app
rabbitmqctl cluster_status
rabbitmq-plugins enable rabbitmq_management
#访问链接: ip:15672
#3
rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
rabbitmqctl add_user openstack loongson
rabbitmqctl set_user_tags openstack administrator
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
rabbitmqctl list_users


#4 配置haproxy

# listen rabbitmq
#     bind *:5673
#     balance leastconn
#     option tcplog
#     timeout client 3h
#     timeout server 3h
#     mode tcp
#     server controller1 192.168.200.224:5672 check  inter 2000 rise 2 fall 5
#     server controller2 192.168.200.70:5672 check  inter 2000 rise 2 fall 5
# listen rabbitmqAdmin
#     bind *:15673
#     server controller1 192.168.200.224:15672 check  inter 2000 rise 2 fall 5
#     server controller2 192.168.200.70:15672 check  inter 2000 rise 2 fall 5
 
 #官方文档没有采用下列方法, 没有使用haproxy
 #rabbit_hosts=rabbit1:5672,rabbit2:5672


sed -i 's/network.target/network-online.target/g' /usr/lib/systemd/system/memcached.service
sed -i 's/network.target/network-online.target/g' /usr/lib/systemd/system/rabbitmq-server.service
