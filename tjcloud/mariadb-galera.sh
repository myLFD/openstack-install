#搭建3个节点的mariadb集群
#controller1 192.168.200.208
#controller2 192.168.200.96
#controller3 192.168.200.56
export hostname1=controller1
export hostname2=controller2
export hostname3=controller3
export ip1=10.10.130.226
export ip2=10.10.130.227
export ip3=10.10.130.228

#1 controller1
systemctl disable --now firewalld
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config && setenforce 0


# hostnamectl set-hostname $hostname1
# exec bash
# echo "192.168.200.208 $hostname1" >>  /etc/hosts
# echo "192.168.200.96  $hostname2" >>  /etc/hosts
# echo "192.168.200.56  $hostname3" >>  /etc/hosts

# yum remove -y mate-screensaver
# yum update -y libxcrypt
# yum install -y http://pkg.loongnix.cn:8080/loongnix-server/8.3/AppStream/loongarch64/release/Packages/mariadb-server-10.3.28-1.1.module_lns8+757+d382997d.loongarch64.rpm  http://pkg.loongnix.cn:8080/loongnix-server/8.3/AppStream/loongarch64/release/Packages/mariadb-common-10.3.28-1.1.module_lns8+757+d382997d.loongarch64.rpm

yum install -y mariadb mariadb-server python2-PyMySQL galera  mariadb-server-galera
tee /etc/my.cnf.d/openstack.cnf <<EOF
[mysqld]
default-storage-engine = innodb
innodb_file_per_table = on
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
innodb_buffer_pool_size=128M
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
max_allowed_packet = 256M
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
bind-address=0.0.0.0
user=mysql

binlog_format=ROW

[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so

wsrep_node_name='$hostname1'
wsrep_node_address="$ip1"
wsrep_cluster_name='galera-cluster'
wsrep_cluster_address="gcomm://$ip1,$ip2,$ip3"

wsrep_provider_options="gcache.size=300M; gcache.page_size=300M"
wsrep_slave_threads=4
wsrep_sst_method=rsync
EOF

#controller2

systemctl disable --now firewalld
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config && setenforce 0

# hostnamectl set-hostname $hostname2
# exec bash
# echo "192.168.200.208 $hostname1" >>  /etc/hosts
# echo "192.168.200.96  $hostname2" >>  /etc/hosts
# echo "192.168.200.56  $hostname3" >>  /etc/hosts

yum install -y mariadb mariadb-server python2-PyMySQL galera.loongarch64  mariadb-server-galera.loongarch64 rsync
tee /etc/my.cnf.d/openstack.cnf <<EOF
[mysqld]
default-storage-engine = innodb
innodb_file_per_table = on
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
innodb_buffer_pool_size=128M
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
max_allowed_packet = 256M
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
bind-address=0.0.0.0
user=mysql

binlog_format=ROW


[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so

wsrep_node_name='$hostname2'
wsrep_node_address="$ip2"
wsrep_cluster_name='galera-cluster'
wsrep_cluster_address="gcomm://$ip1,$ip2,$ip3"

wsrep_provider_options="gcache.size=300M; gcache.page_size=300M"
wsrep_slave_threads=4
wsrep_sst_method=rsync
EOF

#controller3

systemctl disable --now firewalld
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config && setenforce 0


# hostnamectl set-hostname $hostname3
# exec bash
# echo "192.168.200.208 $hostname1" >>  /etc/hosts
# echo "192.168.200.96  $hostname2" >>  /etc/hosts
# echo "192.168.200.56  $hostname3" >>  /etc/hosts

yum install -y mariadb mariadb-server python2-PyMySQL galera mariadb-server-galera rsync
tee /etc/my.cnf.d/openstack.cnf <<EOF
[mysqld]
default-storage-engine = innodb
innodb_file_per_table = on
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
innodb_buffer_pool_size=128M
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
max_allowed_packet = 256M
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
bind-address=0.0.0.0
user=mysql

binlog_format=ROW


[galera]
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so

wsrep_node_name='$hostname3'
wsrep_node_address="$ip3"
wsrep_cluster_name='galera-cluster'
wsrep_cluster_address="gcomm://$ip1,$ip2,$ip3"

wsrep_provider_options="gcache.size=300M; gcache.page_size=300M"
wsrep_slave_threads=4
wsrep_sst_method=rsync
EOF

#4 controller1
galera_new_cluster
systemctl enable mariadb
 mysql -uroot -ploongson -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
#5 controlle2
systemctl enable --now mariadb

#6 controller3
systemctl enable --now mariadb

#7  设置root密码和远程登录
# mysql -uroot -e "set password for root@localhost = password('loongson');"
# mysql -uroot -ploongson -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'loongson'; "
# mysql -uroot -ploongson -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'loongson';"
# mysql -uroot -ploongson -e "flush privileges; "

# #8 验证
# [root@galera1 ~]
#  mysql -uroot -p -e "create database galera_test"

# # [root@galera2 ~]
#  mysql -uroot -p -e "show databases;"

# mysql -uroot -p -e "drop database galera_test"

#9  使用haproxy必须创建harpoxy的用户
mysql -uroot -p -e "CREATE USER 'haproxy'@'%';"

#mysql -uroot -p$password -h192.168.200.17 -P 3307


