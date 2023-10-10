# 需要现在/etc/ansible/hosts文件里添加需要新增的osd配置
# [newosd]
# osd1
# osd2 dev=/dev/vdc
# [newosd:vars]
# dev=/dev/vdb
ansible newosd -m script -a "ceph-pre.sh"
ansible newosd -m shell -a "yum install -y ceph-osd"
ansible newosd -m synchronize  -a "src=/etc/ceph/ceph.client.admin.keyring dest=/etc/ceph/"
ansible newosd -m synchronize  -a "src=/var/lib/ceph/bootstrap-osd/ceph.keyring dest=/var/lib/ceph/bootstrap-osd/"
ansible newosd -m synchronize  -a "src=/etc/ceph/ceph.conf dest=/etc/ceph/"
ansible newosd -m shell -a  "ceph-volume lvm create --data {{dev}}"


#出现 GPT headers found, they must be removed
#执行 sgdisk --zap-all /dev/sdX