#1 controller1
yum install -y keepalived rsyslog
cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.backup
export interface=enp1s0


#master
cat > /etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived

global_defs {
   notification_email {
     root@localhost
   }
   notification_email_from keepalived@localhost
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id haproxy1
}

vrrp_instance VI_1 {
    state BACKUP
    interface  $interface
    virtual_router_id 57
    nopreempt
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        $vip
    }
}

EOF
sed -i '/KEEPALIVED_OPTIONS/d' /etc/sysconfig/keepalived
echo 'KEEPALIVED_OPTIONS="-D -d -S 0"' >> /etc/sysconfig/keepalived
echo "local0.* /var/log/keepalived/keepalived.log" >> /etc/rsyslog.conf 
systemctl enable keepalived.service rsyslog
systemctl start keepalived.service  rsyslog

# #三 修改log地址
# #修改keepalive log地址
# # 1
# # 修改/etc/sysconfig/keepalived
# # 把KEEPALIVED_OPTIONS="-D" 修改为：
# KEEPALIVED_OPTIONS="-D -d -S 0"


# # 2在/etc/rsyslog.conf 末尾添加
# # [root@lb01 /]# vim /etc/rsyslog.conf 
#  local0.* /var/log/keepalived/keepalived.log

# # 3重启服务
#  systemctl restart rsyslog
#  systemctl restart keepalived