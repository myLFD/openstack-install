
配置zabbix server端：
systemctl stop firewalld.service
setenforce 0
yum install zabbix-sender zabbix-agent zabbix-get
dnf install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-agent
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
mysql -uroot -e "set password for root@localhost = password('loongson');"

#要创建服务凭证

创建库及授权操作:
create database zabbix character set utf8 collate utf8_bin;
create user zabbix@localhost identified by 'password';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%' IDENTIFIED BY 'password';
flush privileges;

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p"password" zabbix
systemctl restart mysqld

更改/etc/php.ini配置文件的设置，去掉date.timezone的注释，将时区改为Asia/Shanghai

如果不是本地数据库和默认端口， 修改配置文件

vi /etc/zabbix/zabbix_server.conf
#需要修改数据库用户名密码
#DBName=zabbix
#DBUser=zabbix
#DBPassword=password
# StartHTTPPollers=10
# StartDiscoverers=10

systemctl restart zabbix-server zabbix-agent httpd php-fpm
systemctl enable zabbix-server zabbix-agent httpd php-fpm

访问:ip/zabbix
用户名密码:Admin/zabbix

#中文字符乱码解决办法
# 将simhei.ttf 拷贝到/usr/share/zabbix/assets/fonts
# 更改权限  chmod 777 simhei.ttf
# rm -f /etc/alternatives/zabbix-web-font
# ln -s -f simhei.ttf /etc/alternatives/zabbix-web-font
# 修改/usr/share/zabbix/include目录下的defines.inc.php文件，将graphfont修改为simhei
# 无需重启服务, 刷新页面即可

配置zabbix 客户端：
agent端安装配置：
yum -y install zabbix-agent -y

#8.3  8.4 zabbix读取的配置文件位置不一样
if [ -f /etc/zabbix_agentd.conf ]
then
    sed -i '/^Server/d' /etc/zabbix_agentd.conf
    sed -i '/^ServerActive/d' /etc/zabbix_agentd.conf
    sed -i '/^Hostname/d' /etc/zabbix_agentd.conf

    echo "Server=10.180.209.248" >>  /etc/zabbix_agentd.conf     #被动模式 zabbix-server-ip*         (服务端ip)
    echo "ServerActive=10.180.209.248" >>  /etc/zabbix_agentd.conf    #主动模式 zabbix-server-ip(服务端ip)
    echo "Hostname=`hostname`"  >>  /etc/zabbix_agentd.conf                                  #客户端主机名称
    echo "UnsafeUserParameters=1"   >>  /etc/zabbix_agentd.conf  
    egrep -v "^#|^$"  /etc/zabbix_agentd.conf                        
    systemctl start zabbix-agent
    systemctl enable zabbix-agent
elif [ -f /etc/zabbix/zabbix_agentd.conf ]
then
    sed -i '/^Server/d' /etc/zabbix/zabbix_agentd.conf
    sed -i '/^ServerActive/d' /etc/zabbix/zabbix_agentd.conf
    sed -i '/^Hostname/d' /etc/zabbix/zabbix_agentd.conf

    echo "Server=10.180.209.248" >>  /etc/zabbix/zabbix_agentd.conf     #被动模式 zabbix-server-ip*         (服务端ip)
    echo "ServerActive=10.180.209.248" >>  /etc/zabbix/zabbix_agentd.conf    #主动模式 zabbix-server-ip(服务端ip)
    echo "Hostname=`hostname`"  >>  /etc/zabbix/zabbix_agentd.conf                                  #客户端主机名称
    echo "UnsafeUserParameters=1"   >>  /etc/zabbix/zabbix_agentd.conf  
    egrep -v "^#|^$"  /etc/zabbix/zabbix_agentd.conf                        
fi
    systemctl start zabbix-agent
    systemctl enable zabbix-agent

