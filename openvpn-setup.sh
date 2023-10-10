#!/bin/bash -e
set -x
yum install -y openvpn easy-rsa iptables iptables-services

cp -r /usr/share/easy-rsa/ /etc/openvpn/

cd /etc/openvpn/easy-rsa/3.0.8/
cat > vars <<EOF
#!/bin/bash
export KEY_COUNTRY="CN" #（国家名称）
export KEY_PROVINCE="BeiJing" #（省份名称）
export KEY_CITY="BeiJing" #（城市名称）
export KEY_ORG="LOONGSON" #（组织机构名称）
export KEY_EMAIL="eco-center@loongson.cn" #（邮件地址）
export EASYRSA_KEY_SIZE=2048 # 密钥长度2048
export EASYRSA_CA_EXPIRE=3650 # CA有效期3650天
export EASYRSA_CERT_EXPIRE=3650 # CERT有效期3650天
EOF

source ./vars
./easyrsa init-pki #初始化 pki 相关目录
./easyrsa build-ca nopass
#Common Name: 必须唯一
./easyrsa build-server-full server nopass
./easyrsa gen-dh # 创建Diffie-Hellman，确保key穿越不安全网络的命令
openvpn --genkey --secret ta.key #生成tls-auth key，为了防止DDOS和TLS攻击，这个属于可选安全配置
./easyrsa build-client-full client nopass
#server端key的整理
mkdir /etc/openvpn/server/certs
cd /etc/openvpn/server/certs/
# SSL 协商时 Diffie-Hellman 算法需要的 key
cp /etc/openvpn/easy-rsa/3/pki/dh.pem ./
# CA 根证书
cp /etc/openvpn/easy-rsa/3/pki/ca.crt ./
# open VPN 服务器证书
cp /etc/openvpn/easy-rsa/3/pki/issued/server.crt ./server.crt
# open VPN 服务器证书 key
cp /etc/openvpn/easy-rsa/3/pki/private/server.key ./server.key
# tls-auth key
cp /etc/openvpn/easy-rsa/3/ta.key ./
#客户端key的整理
mkdir /etc/openvpn/client/certs
cd /etc/openvpn/client/certs
cp /etc/openvpn/easy-rsa/3/pki/ca.crt ./
cp /etc/openvpn/easy-rsa/3/pki/issued/client.crt ./
cp /etc/openvpn//easy-rsa/3/pki/private/client.key ./
cp /etc/openvpn/easy-rsa/3/ta.key ./


systemctl stop firewalld
systemctl disable firewalld
setenforce 0 || echo ok #关闭seliunx
sestatus
#SELinux status: disabled
systemctl start iptables #启用iptables
systemctl enable iptables
iptables -F
iptables -I INPUT -p tcp --dport 1194 -j ACCEPT 
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o tun0 -j MASQUERADE 
iptables -t nat -A POSTROUTING -o enp1s0 -j MASQUERADE
iptables -A FORWARD -i enp1s0 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT

#不允许访问的ip
#iptables -t filter -A FORWARD -s 10.8.0.0/24 -d 10.40.73.250 -j DROP 
#iptables -t filter -A FORWARD -s 10.8.0.0/24 -d 10.40.73.251 -j DROP

#ipbtales需要重启生效
service iptables save
systemctl restart iptables
echo net.ipv4.ip_forward = 1 >>/etc/sysctl.conf 
sysctl -p
mkdir -p  /var/log/openvpn/
cd /etc/openvpn
cat > server.conf <<EOF
#server端配置文件
local 0.0.0.0
port 1194 # 监听的端口号
proto tcp # 服务端用的协议，udp 能快点，所以我选择 udp
dev tun
ca /etc/openvpn/server/certs/ca.crt # CA 根证书路径
cert /etc/openvpn/server/certs/server.crt # open VPN 服务器证书路径
key /etc/openvpn/server/certs/server.key # open VPN 服务器密钥路径，This file should be kept secret
dh /etc/openvpn/server/certs/dh.pem # Diffie-Hellman 算法密钥文件路径
tls-auth /etc/openvpn/server/certs/ta.key 0 # tls-auth key，参数 0 可以省略，如果不省略，那么客户端
# 配置相应的参数该配成 1。如果省略，那么客户端不需要 tls-auth 配置
server 10.8.0.0 255.255.255.0 # 该网段为 open VPN 虚拟网卡网段，不要和内网网段冲突即可。open VPN 默认为 10.8.0.0/24
# 根据实际需求配置需要访问的ip
push "route 10.40.180.204 255.255.255.0"
push "route 192.168.100.0 255.255.255.0"
push "dhcp-option DNS 114.114.114.114"
#push "dhcp-option DNS 8.8.8.8" # DNS 服务器配置，可以根据需要指定其他 ns
#push "dhcp-option DNS 8.8.4.4"

#push "redirect-gateway def1" # 客户端所有流量都通过 open VPN 转发，类似于代理开全局
compress lzo
duplicate-cn # 允许一个用户多个终端连接
keepalive 10 120
#client-config-dir ccd # 用户权限控制目录
comp-lzo
persist-key
persist-tun
user nobody # open VPN 进程启动用户，openvpn 用户在安装完 openvpn 后就自动生成了
group nobody
#log /etc/openvpn/server.log # 指定 log 文件位置
#log-append /etc/openvpn/server.log
status /var/log/openvpn/status.log
verb 3
#用户名密码功能时打开
#script-security 3
#auth-user-pass-verify /etc/openvpn/checkpsw.sh via-env
#username-as-common-name
#屏蔽后同时使用key和用户名密码功能
#verify-client-cert none
EOF


 
cd /etc/openvpn/client/certs
cat > client.conf <<EOF
;# 文件名 windows为client.ovpn，Linux为client.conf
client
dev tun
proto tcp
remote 114.242.206.180 25198
resolv-retry infinite
tls-auth ta.key 1 
nobind
;user nobody
;group nobody
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
remote-cert-tls server
comp-lzo
verb 3
;mute 20
#auth-user-pass 
EOF

