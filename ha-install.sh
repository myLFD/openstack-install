1 控制节点
所有节点按照 openstack/0环境准备 配置hostname和免密登录， 控制节点名称分别为controller1， controller2， controller3
所有控制节点执行pre-install.sh
按照keepalived.sh安装keepalived
按照haproxy.sh安装haproxy
按照mariadb-galera.sh安装数据库集群
按照rabbitmq.sh 安装消息队列
在控制节点1 配置vairable-ha.sh, 然后执行controller-install-master.sh
在控制节点2和3， 配置vairable-ha.sh, 然后执行controller-install-backup.sh

2 分布式存储
按照tools/ecph-openstack.sh使用分布式存储
