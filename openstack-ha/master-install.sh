source variable-ha.sh
export interface=enp1s0
ansible controller -m script -a "pre_install.sh"
ansible controller -m script -a "keepalived.sh $vip $interface"
ansible controller -m script -a "haproxy.sh controller1 controller2 controller3"
ansible controller -m script -a "mariadb.sh"
galera_new_cluster
ansible controller -m shell -a "systemctl enable --now mariadb"
mysql -uroot  -e "CREATE USER 'haproxy'@'%';"
mysql -uroot  -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
ansible controller -m script -a "rabbitmq-install.sh"
ansible controller -m synchronize  -a "src=/var/lib/rabbitmq/.erlang.cookie dest=/var/lib/rabbitmq/.erlang.cookie"
ansible controller1 -m script -a "rabbitmq-controller1.sh"
ansible controller2 -m script -a "rabbitmq-controller2-3.sh"
ansible controller3 -m script -a "rabbitmq-controller2-3.sh"
ansible controller1 -m script -a "rabbitmq-config.sh"

