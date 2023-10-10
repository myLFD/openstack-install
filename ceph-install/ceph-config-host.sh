#如果安装在opentack节点则不需要做这个，因为openstack节点已经做过
cephip1=10.180.210.99
cephip2=10.180.210.154
cephip3=10.180.210.157

echo "$cephip1 ceph1" >> /etc/hosts
echo "$cephip2 ceph2" >> /etc/hosts
echo "$cephip3 ceph3" >> /etc/hosts

: > /root/init.sh
: > /etc/ansible/hosts
sed -i '/host_key_checking/d' /etc/ansible/ansible.cfg
echo "host_key_checking = False" >> /etc/ansible/ansible.cfg

cat > /etc/ansible/hosts <<eof
ceph1 ansible_ssh_host=$cephip1 ansible_ssh_user="root" ansible_ssh_pass="loong123" ansible_ssh_port=22 name=ceph1
ceph2 ansible_ssh_host=$cephip2 ansible_ssh_user="root" ansible_ssh_pass="loong123" ansible_ssh_port=22 name=ceph2
ceph3 ansible_ssh_host=$cephip3 ansible_ssh_user="root" ansible_ssh_pass="loong123" ansible_ssh_port=22 name=ceph3
[ceph]
ceph1
ceph2
ceph3
[newosd]
eof

echo "sed -i '/ceph/d' /etc/hosts" >> /root/init.sh
echo "echo \"$cephip1 ceph1\"  >> /etc/hosts" >>/root/init.sh;
echo "echo \"$cephip2 ceph2\"  >> /etc/hosts" >>/root/init.sh;
echo "echo \"$cephip3 ceph3\"  >> /etc/hosts" >>/root/init.sh;



if [ ! -f "/root/.ssh/id_rsa.pub" ];then
ssh-keygen
fi
cd ~/.ssh
# 免密推送

cat > ~/.ssh/config <<EOF
Host *
StrictHostKeyChecking no
EOF

cp -fa id_rsa.pub authorized_keys
ansible ceph -m shell -a "hostnamectl set-hostname {{ name }}"

ansible ceph -m script -a "/root/init.sh"
ansible ceph -m synchronize  -a "src=/root/.ssh dest=~/"
ansible ceph -m shell -a "chmod 0600 ~/.ssh/id_rsa"
ansible ceph -m synchronize  -a "src=/root/openstack-install dest=/root"


