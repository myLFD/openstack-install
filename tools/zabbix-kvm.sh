
/etc/zabbix/zabbix_agentd.conf AllowRoot=1
cat<<EOF >> /etc/zabbix/zabbix_agentd.conf
UserParameter=kvm.domain.discover,python3 /etc/zabbix/zabbix-kvm.py --item discovery 
UserParameter=kvm.domain.cpu_util[*],python3 /etc/zabbix/zabbix-kvm.py --item cpu --uuid $1
UserParameter=kvm.domain.mem_usage[*],python3 /etc/zabbix/zabbix-kvm.py --item mem --uuid $1
UserParameter=kvm.domain.net_in[*],python3 /etc/zabbix/zabbix-kvm.py --item net_in --uuid $1
UserParameter=kvm.domain.net_out[*],python3 /etc/zabbix/zabbix-kvm.py --item net_out --uuid $1
UserParameter=kvm.domain.rd_bytes[*],python3 /etc/zabbix/zabbix-kvm.py --item rd_bytes --uuid $1
UserParameter=kvm.domain.wr_bytes[*],python3 /etc/zabbix/zabbix-kvm.py --item wr_bytes --uuid $1
EOF
systemctl restart zabbix-agent.service
