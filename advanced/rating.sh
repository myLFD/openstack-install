docker pull cr.loongnix.cn/library/influxdb:1.8.10
docker run -itd -p 8083:8083 -p 8086:8086 --name influxdb  $imged_id
docker exec -ti $containerid bash
#进入容器，执行influx后 输入下面两条命令创建数据库
create database cloudkitty
create user cloudkitty with password '000000' with all privileges

