#cloud-config
hostname: kvm_host01
fqdn: kvm_host01.example.com
manage_etc_hosts: true
users:
  - name: centos
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: where
    home: /home/centos
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
     - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDuASr3fppVfvcIBNPnQ1526RnToDqwTKfBMG5ZjTqAETFF+U1Ixy2qj/2t+zvodLscV545mPZr7umTh3FIkM4hUoGXRXFqzSS6QVVbPYatUihq/Y62KgBxvzy7dtdgTUXjhHXs+kE+WtlG3n0vP0hkb+w0LBBEZlMMpfX4KWrqUMcRTbYNBgJhT1kgkCvh4GoUILw9qg2eFV5rk2gkTt/B01W1liAmHTwpipYt80WI+QbGl2pbXW1KzuGajsvxnM3toYClmxHDEMnGdNpWNkRcrC6t9205HE5nVrt/QULlQGCCsz5ygf0aBshYpz0gLTXC1PgeDBptBTJ5ujgWGUPT Generated-by-Nova
  - name: root
    ssh_authorized_keys:
     - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDuASr3fppVfvcIBNPnQ1526RnToDqwTKfBMG5ZjTqAETFF+U1Ixy2qj/2t+zvodLscV545mPZr7umTh3FIkM4hUoGXRXFqzSS6QVVbPYatUihq/Y62KgBxvzy7dtdgTUXjhHXs+kE+WtlG3n0vP0hkb+w0LBBEZlMMpfX4KWrqUMcRTbYNBgJhT1kgkCvh4GoUILw9qg2eFV5rk2gkTt/B01W1liAmHTwpipYt80WI+QbGl2pbXW1KzuGajsvxnM3toYClmxHDEMnGdNpWNkRcrC6t9205HE5nVrt/QULlQGCCsz5ygf0aBshYpz0gLTXC1PgeDBptBTJ5ujgWGUPT Generated-by-Nova

# only cert auth via ssh (console access can still login)
ssh_pwauth: true
disable_root: false
chpasswd:
  list: |
     root:q1w2E#R$
  expire: False

package_update: true
packages:
  - vim-enhanced
  - net-tools
  - tcpdump
  - sysstat
timezone: Asia/Shanghai
# manually set BOOTPROTO for static IP
# older cloud-config binary has bug?
runcmd:
    - [ sh, -c, 'sed -i s/BOOTPROTO=static/BOOTPROTO=dhcp/ /etc/sysconfig/network-scripts/ifcfg-eth0' ]
    - [ sh, -c, 'ifdown eth0 && sleep 1 && ifup eth0 && sleep 1 && ip a' ]
# written to /var/log/cloud-init.log, /var/log/messages
final_message: "The system is finally up, after $UPTIME seconds"