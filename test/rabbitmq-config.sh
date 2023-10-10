rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'
rabbitmqctl add_user openstack loongson
rabbitmqctl set_user_tags openstack administrator
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
rabbitmqctl list_users
