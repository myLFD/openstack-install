#controller1 192.168.200.1
#controller2 192.168.200.2
#vip 192.168.200.3
export controller1=10.40.41.13
export controller2=10.40.41.22

#一controller1为主controller2为从
#先在controller1上操作
#1 
yum install -y mariadb mariadb-server python3-PyMySQL
tee /etc/my.cnf.d/openstack.cnf <<-'EOF'
[mysqld]
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
max_allowed_packet = 256M
EOF
systemctl enable mariadb.service
systemctl start mariadb.service








#3
#修改/etc/my.cnf, 增加
[mysqld]
log-bin=mysql-bin 
#启动二进制文件
server-id=1 
systemctl restart mariadb.service
#查看binlog是否开启
mysql -uroot -p$password -e " show variables like '%log_bin%';"

#4 然后在增加一个账号专门用于同步
mysql -uroot -p$password -e "grant replication slave on *.* to 'backup'@'$controller2' identified by 'backup';"
mysql -uroot -p$password -e "flush privileges;"
mysql -uroot -p$password -e "show master status;"
# +------------------+----------+--------------+------------------+
# | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
# +------------------+----------+--------------+------------------+
# | mysql-bin.000014 |      342 |              |                  |
# +------------------+----------+--------------+------------------+

#切换到controller2
#先执行#1 #2 #3 id要与controller1不同
#修改/etc/my.conf, 增加
[mysqld]
log-bin=mysql-bin 
#启动二进制文件
server-id=2
systemctl restart mariadb.service
mysql -uroot -p$password -e "stop slave"
mysql -uroot -p$password -e "change master to master_host='$controller1',master_user='backup',master_password='backup',master_log_file='mysql-bin.000002',master_log_pos=663;"
mysql -uroot -p$password -e "start slave"
mysql -uroot -p$password -e "show slave status \G;"|grep Running


#Slave_IO_Running: Yes            
#Slave_SQL_Running: Yes

#至此controller1为主controller2为从的主从架构数据设置成功！

#二设置controller2为主controller1为从
#在controller2上
mysql -uroot -p$password -e "grant replication slave on *.* to 'backup'@'$controller1' identified by 'backup'; "
mysql -uroot -p$password -e "flush privileges;"
mysql -uroot -p$password -e "show master status;"
#  +------------------+----------+--------------+------------------+
# | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
# +------------------+----------+--------------+------------------+
# | mysql-bin.000003 |      342 |              |                  |
# +------------------+----------+--------------+------------------+

#在controller1上
mysql -uroot -p$password -e "stop slave"
mysql -uroot -p$password -e "change master to master_host='$controller2',master_user='backup',master_password='backup',master_log_file='mysql-bin.000002',master_log_pos=663;"
mysql -uroot -p$password -e "start slave"
mysql -uroot -p$password -e "show slave status \G;"|grep Running
#Slave_IO_Running: Yes            
#Slave_SQL_Running: Yes


#三 配置haproxy

mysql -uroot -p$password -e "CREATE USER 'haproxy'@'%';"

#在/etc/haproxy/haproxy.cfg中增加下列内容并重启 

listen mariadb
    bind *:3307
    balance roundrobin
    mode tcp
    option tcpka
    option mysql-check user haproxy
    server controller1 192.168.200.1:3307 check  inter 2000 rise 2 fall 5
    server controller1 192.168.200.2:3307 check  inter 2000 rise 2 fall 5

systemctl restart haproxy

#四验证通过3307连接
mysql -uroot -p$password -h10.40.40.1 -P 3307
