systemctl disable --now firewalld
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config && setenforce 0

export hostname=`hostname`
export ip=`hostname -i`


#8.4系统默认装的galera版本26有冲突, 指定安装25版本
yum install -y mariadb mariadb-server python3-PyMySQL galera-25.3.31-1.module+lns8.4.0+10246+c54b81ce.loongarch64  mariadb-server-galera.loongarch64 rsync
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

wsrep_node_name='$hostname'
wsrep_node_address="$ip"
wsrep_cluster_name='galera-cluster'
wsrep_cluster_address="gcomm://controller1,controller2,controller3"

wsrep_provider_options="gcache.size=300M; gcache.page_size=300M"
wsrep_slave_threads=4
wsrep_sst_method=rsync
EOF
