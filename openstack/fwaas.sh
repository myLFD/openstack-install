

yum install -y openstack-neutron-fwaas.noarch python3-neutron-fwaas.noarch 
#neutron.conf
openstack-config --set /etc/neutron/neutron.conf  DEFAULT                  service_plugins  router,neutron.services.qos.qos_plugin.QoSPlugin,firewall_v2
openstack-config --set /etc/neutron/neutron.conf  service_providers        service_provider FIREWALL_V2:fwaas_db:neutron_fwaas.services.firewall.service_drivers.agents.agents.FirewallAgentDriver:default
openstack-config --set /etc/neutron/neutron.conf  fwaas                    agent_version    v2
openstack-config --set /etc/neutron/neutron.conf  fwaas                    driver           neutron_fwaas.services.firewall.service_drivers.agents.drivers.linux.iptables_fwaas_v2.IptablesFwaasDriver
openstack-config --set /etc/neutron/neutron.conf  fwaas                    enabled          True
#l3 agent
openstack-config --set /etc/neutron/l3_agent.ini  AGENT extensions fwaas_v2

#ml2
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini  agent extensions         fwaas_v2
openstack-config --set  /etc/neutron/plugins/ml2/ml2_conf.ini  fwaas firewall_l2_driver noop

neutron-db-manage --subproject neutron-fwaas upgrade head

cd ~

git clone https://opendev.org/openstack/neutron-fwaas-dashboard
cd neutron-fwaas-dashboard/
sed -i 's/3.8/3.6/g' setup.cfg  
sed -i '/horizon/d' requirements.txt
sed -i '/python-neutronclient/d' requirements.txt
pip3 install .
cp /root/neutron-fwaas-dashboard/neutron_fwaas_dashboard/enabled/_70*_*.py    /usr/share/openstack-dashboard/openstack_dashboard/local/enabled/

cd /usr/local/lib/python3.6/site-packages/neutron_fwaas_dashboard/locale
cp -r zh_Hans zh_CN
cd zh_CN/LC_MESSAGES
msgfmt --statistics --verbose -o django.mo django.po

systemctl restart httpd memcached
#policy
#openstack firewall group policy create --firewall-rule "FIREWALL_RULE_IDS_OR_NAMES" myfirewallpolicy
#openstack firewall group policy add rule policy-id rule-id
#openstack firewall group policy remove rule policy-id rule-id

#group
#openstack firewall group create --ingress-firewall-policy "FIREWALL_POLICY_IDS_OR_NAMES" --egress-firewall-policy "FIREWALL_POLICY_IDS_OR_NAMES" --port "PORT_IDS_OR_NAMES"
#openstack firewall group set --port portid  firewall group id
#openstack firewall group set firewall group id --share
#openstack firewall group set firewall group id --ingress-firewall-policy --egress-firewall-policy
#openstack firewall group unset firewall group id --ingress-firewall-policy --egress-firewall-policy

#rule
#openstack firewall group rule set rule-id --action deny
#openstack firewall group rule set rule-id --source-ip-address --destination-ip-address --protocol 


