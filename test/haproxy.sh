yum install -y haproxy
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup
export controller1=$1
export controller2=$2
export controller3=$3

cat > /etc/haproxy/haproxy.cfg <<EOF
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     20000
    user        haproxy
    group       haproxy
    daemon
    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats
    # utilize system-wide crypto-policies
    ssl-default-bind-ciphers PROFILE=SYSTEM
    ssl-default-server-ciphers PROFILE=SYSTEM
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
# frontend main 
#    bind *:8080
#    mode http
#    default_backend webservers
# backend webservers
#     balance roundrobin
#     # 后端业务服务器清单
#     server web1 $controller1:80 check rise 2 fall 1 weight 2
#     server web2 $controller2:80 check rise 2 fall 1 weight 2
listen http-server
    bind 0.0.0.0:8080
    balance roundrobin
    option tcpka
    option httpchk get  /dashboard
    option tcplog
    server controller1 $controller1:80/dashboard check port 80 inter 2000 rise 2 fall 5
    server controller2 $controller2:80/dashboard check port 80 inter 2000 rise 2 fall 5
    server controller3 $controller3:80/dashboard check port 80 inter 2000 rise 2 fall 5
listen stats
    mode http
    bind 0.0.0.0:8090                # 监控网站地址
    option httpchk GET /info.txt     # 后端真实主机监控检查方式
    stats enable
    stats refresh 60s
    stats hide-version
    stats uri   /mornitor               # 监控网站 URI
    stats realm Haproxy\ allen
    stats auth  admin:admin
    stats admin if TRUE
listen mariadb
    bind *:3307
    balance roundrobin
    mode tcp
    option tcpka
    option mysql-check user haproxy
    stick-table type ip size 1000
    stick on dst
    timeout client 3600s
    timeout server 3600s
    server controller1 $controller1:3306 check  inter 2000 on-marked-down shutdown-sessions rise 2 fall 5 backup
    server controller2 $controller2:3306 check  inter 2000 on-marked-down shutdown-sessions rise 2 fall 5 backup
    server controller3 $controller3:3306 check  inter 2000 on-marked-down shutdown-sessions rise 2 fall 5 backup

listen rabbitmq
    bind *:5673
    balance leastconn
    option tcplog
    timeout client 3h
    timeout server 3h
    mode tcp
    server controller1 $controller1:5672 check  inter 2000 rise 2 fall 5
    server controller2 $controller2:5672 check  inter 2000 rise 2 fall 5
    server controller3 $controller3:5672 check  inter 2000 rise 2 fall 5
   
listen rabbitmqAdmin
    bind *:15673
    server controller1 $controller1:15672 check  inter 2000 rise 2 fall 5
    server controller2 $controller2:15672 check  inter 2000 rise 2 fall 5
    server controller3 $controller3:15672 check  inter 2000 rise 2 fall 5

listen keystone
    bind *:5001
    balance source
    option tcpka
    option httpchk
    option tcplog
    server controller1 $controller1:5000 check  inter 2000 rise 2 fall 5
    server controller2 $controller2:5000 check  inter 2000 rise 2 fall 5
    server controller3 $controller3:5000 check  inter 2000 rise 2 fall 5
listen glance-api
    bind *:9293
    balance source
    option tcpka
    option httpchk
    option tcplog
    server controller1 $controller1:9292 check  inter 2000 rise 2 fall 5
    server controller2 $controller2:9292 check  inter 2000 rise 2 fall 5
    server controller3 $controller3:9292 check  inter 2000 rise 2 fall 5
listen nova-api
    bind *:8784
    balance source
    option tcpka
    option httpchk
    option tcplog
    server controller1 $controller1:8774 check  inter 2000 rise 2 fall 5
    server controller2 $controller2:8774 check  inter 2000 rise 2 fall 5
    server controller3 $controller3:8774 check  inter 2000 rise 2 fall 5
listen nova_novncproxy
    bind *:6090
    balance source
    option tcpka
    option tcplog
    timeout client 3600s
    timeout server 3600s
    server controller1 $controller1:6080 check  inter 2000 rise 2 fall 5
    server controller2 $controller2:6080 check  inter 2000 rise 2 fall 5
    server controller3 $controller3:6080 check  inter 2000 rise 2 fall 5

listen nova_placement
    bind *:8789
    balance source
    option tcpka
    option tcplog
    server controller1 $controller1:8778 check  inter 2000 rise 2 fall 5
    server controller2 $controller2:8778 check  inter 2000 rise 2 fall 5
    server controller3 $controller3:8778 check  inter 2000 rise 2 fall 5

listen neutron
    bind *:9606
    balance source
    option tcpka
    option tcplog
    server controller1 $controller1:9696 check  inter 2000 rise 2 fall 5
    server controller2 $controller2:9696 check  inter 2000 rise 2 fall 5
    server controller3 $controller3:9696 check  inter 2000 rise 2 fall 5

listen cinder
    bind *:8777
    balance source
    option tcpka
    option tcplog
    server controller1 $controller1:8776 check  inter 2000 rise 2 fall 5
    server controller2 $controller2:8776 check  inter 2000 rise 2 fall 5
    server controller3 $controller3:8776 check  inter 2000 rise 2 fall 5


EOF
#访问链接:ip:8090/mornitor
systemctl enable haproxy
systemctl restart haproxy

#netstat -ntpl | grep haproxy
# tcp        0      0 0.0.0.0:9606            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:8777            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:5001            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:5673            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:6090            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:3307            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:9293            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:8784            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:8789            0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:15673           0.0.0.0:*               LISTEN      5510/haproxy        
# tcp        0      0 0.0.0.0:8090            0.0.0.0:*               LISTEN      5510/haproxy 

