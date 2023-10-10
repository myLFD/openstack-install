cp localrepo.tar.gz /opt
cd  /opt
tar -xzvf localrepo.tar.gz
createrepo /opt/localrepo

cat > /etc/yum.repos.d/local.repo <<EOF
[local-yum]
name=local-yum
baseurl=file:///opt/localrepo
enabled=1
gpgcheck=0
priority=1
EOF