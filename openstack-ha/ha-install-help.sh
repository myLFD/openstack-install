#3控制节点部署步骤
#
配置hostname和免密登录
controller1 
controller2
controller3
#
3个控制节点分别执行per_install.sh
#
3个控制节点分别参照keepalived.sh部署keepalived  
#
3个控制节点分别参照haproxy.sh部署haproxy
#
3个控制节点分别参照mariadb-galera.sh部署mariadb集群
#
3个控制节点分别参照rabbitmq.sh部署rabbitmq集群
#


