yum install docker-ce
systemctl enable --now docker

#/etc/docker/daemon.json 文件中，增加以下内容
#root@loongson:~# cat /etc/docker/daemon.json 
{
    "registry-mirror": ["https://cr.loongnix.cn"]
}
docker pull cr.loongnix.cn/grafana/grafana:9.0.3
# [root@host-10-180-209-248 ~]# docker images
# REPOSITORY                       TAG       IMAGE ID       CREATED        SIZE
# cr.loongnix.cn/grafana/grafana   9.0.3     0a13940ff9d2   8 months ago   586MB


docker run -d --name=grafana -p 3000:3000 358c2ac12143

# [root@host-10-180-209-248 ~]# docker ps
# CONTAINER ID   IMAGE          COMMAND     CREATED          STATUS         PORTS                    NAMES
# 26e841574e05   0a13940ff9d2   "/run.sh"   12 seconds ago   Up 7 seconds   0.0.0.0:3000->3000/tcp   grafana
grafana-cli plugins list-remote |grep zabbix
grafana-cli plugins install alexanderzobnin-zabbix-app

docker cp zabbix-plugin_linux_loong64 26e841574e05:/var/lib/grafana/plugins/alexanderzobnin-zabbix-app/gpx_zabbix-plugin_linux_loong64
docker restart 02cb355cf522

登录:ip:3000  admin/admin

docker cp 02cb355cf522:/etc/grafana/grafana.ini ./
docker cp ./grafana.ini 02cb355cf522:/etc/grafana/grafana.ini

docker cp 02cb355cf522:/usr/share/grafana/conf/defaults.ini ./
docker cp ./defaults.ini 02cb355cf522:/usr/share/grafana/conf/defaults.ini 


# 一、基于命令修改
# 1）修改密码
# grafana-cli admin reset-admin-password admin123
# 注意：admin123表示新密码；
# 2）重启服务
# systemctl restart grafana-server