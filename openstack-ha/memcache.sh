#Memcached是无状态的，各控制节点独立部署，openstack各服务模块统一调用多个控制节点的memcached服务即可。
[memcache]
servers = controller1:11211,controller2:11211,controller3:11211,controller3:11211