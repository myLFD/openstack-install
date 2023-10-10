chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
systemctl stop rabbitmq-server
systemctl start rabbitmq-server
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@controller1
rabbitmqctl start_app
rabbitmqctl cluster_status
rabbitmq-plugins enable rabbitmq_management
