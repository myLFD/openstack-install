#!/bin/bash -e
set -x
#将hostname , ip, password添加到数组中

node=(
"controller,192.168.200.118,loongson123!@#,enp8s0"
"compute1,192.168.200.19,loongson123!@#,enp8s0"
"compute2,192.168.200.50,loongson123!@#,enp8s0"
)


cp cloud.repo /etc/yum.repos.d
yum install -y ansible


: > /root/init.sh
: > /etc/ansible/hosts
echo "sed -i '/controller/d' /etc/hosts" >> /root/init.sh
echo "sed -i '/compute/d' /etc/hosts" >> /root/init.sh

for value in ${node[@]}
do
hostname=`echo $value | cut -d "," -f1 `
ip=`echo $value | cut -d "," -f2`
pass=`echo $value | cut -d "," -f3`
ext=`echo $value | cut -d "," -f4`

echo "$hostname ansible_ssh_host=$ip ansible_ssh_user=\"root\" ansible_ssh_pass=\"$pass\" ansible_ssh_port=22 name=$hostname ext_interface=$ext" >> /etc/ansible/hosts
echo "echo \"$ip $hostname\"  >> /etc/hosts" >>/root/init.sh;
done
echo "[compute]" >> /etc/ansible/hosts
for value in ${node[@]}
do
hostname=`echo $value | cut -d "," -f1 `
echo $hostname >> /etc/ansible/hosts
done


sed -i '/host_key_checking/d' /etc/ansible/ansible.cfg
echo "host_key_checking = False" >> /etc/ansible/ansible.cfg


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
# 批量设置主机名称
ansible compute -m shell -a "hostnamectl set-hostname {{ name }}"


# 初始化环境--脚本在附录当中

ansible all -m script -a "/root/init.sh"

ansible compute -m synchronize  -a "src=/root/.ssh dest=~/"
ansible compute -m shell -a "chmod 0600 ~/.ssh/id_rsa"
ansible compute -m synchronize  -a "src=/root/openstack-install dest=/root"
ansible compute -m shell -a 'sed -i "/compute/d"  /root/openstack-install/openstack/variable.sh'
ansible compute -m shell -a 'echo "export compute={{ansible_ssh_host}}" >> /root/openstack-install/openstack/variable.sh '
ansible compute -m shell -a 'echo "export compute_interface={{ext_interface}}">> /root/openstack-install/openstack/variable.sh'
cd ~
#exec bash



#查看所有计算节点disk 文件大小
# ansible compute -m shell -a "ls -lha /var/lib/nova/instances/* |grep disk |grep -v info"

#重启所有openstack-nova-compute
# ansible compute -m shell -a "systemctl restart openstack-nova-compute"

#批量在所有计算节点执行文件(文件在ansbile host上)
# ansible compute -m script -a "live-migration.sh"

#执行远程主机的脚本(文件在远程主机上)
# ansible '*' -m shell -a 'ps aux|grep openstack'

#批量发送文件
# ansible compute -m copy -a "src=/root/test.sh dest=/root owner=nova group=nova"

#批量发送目录
# ansible compute -m copy -a "src=/var/lib/nova/.ssh dest=/var/lib/nova/ owner=nova group=nova"
