
mysqldump -uroot -ploongson cinder glance keystone neutron nova nova_api nova_cell0 placement >  "mysql.`date +%Y-%m-%d-%H:%M:%S`.sql"
#mysqldump -uroot -ploongson -all-databases
mysql -uroot -ploongson -e "source mysql.*.sql


