1通过nova命令来查看现有的availability zone
nova availability-zone-list
会看到有两个 az
internel: nova服务
nova: 默认计算节点az

2 创建aggregate来关联az
nova aggregate-create azone wqtest
+----+-------+-------------------+-------+----------------------------+--------------------------------------+
| Id | Name | Availability Zone | Hosts | Metadata | UUID |
+----+-------+-------------------+-------+----------------------------+--------------------------------------+
| 3 | azone | wqtest | | 'availability_zone=wqtest' | 393a0840-ceff-458a-9eb3-3f4fce8f46d9 |
+----+-------+-------------------+-------+----------------------------+--------------------------------------+

3 创建完aggregate后查看az list时不会显示新创建的az，因为没有为azone添加主机, 但是可以通过
aggregate-list 查到

4 为azone添加主机

nova aggregate-add-host 3 compute1
Host compute1 has been successfully added for aggregate 3
+----+-------+-------------------+------------+----------------------------+--------------------------------------+
| Id | Name | Availability Zone | Hosts | Metadata | UUID |
+----+-------+-------------------+------------+----------------------------+--------------------------------------+
| 3 | azone | wqtest | 'compute1' | 'availability_zone=wqtest' | 393a0840-ceff-458a-9eb3-3f4fce8f46d9 |
+----+-------+-------------------+------------+----------------------------+--------------------------------------+

5 查看az
nova availability-zone-list
+---------------------+----------------------------------------+
| Name | Status |
+---------------------+----------------------------------------+
| internal | available |
| |- controller | |
| | |- nova-conductor | enabled :-) 2022-05-07T01:15:10.000000 |
| | |- nova-scheduler | enabled :-) 2022-05-07T01:15:10.000000 |
| nova | available |
| |- compute2 | |
| | |- nova-compute | enabled :-) 2022-05-07T01:15:10.000000 |
| wqtest | available |
| |- compute1 | |
| | |- nova-compute | enabled :-) 2022-05-07T01:15:10.000000 |

6 最后在创建新的虚机的时候就可以选择azone这个zone来创建vm

7 移除host并删除az
可以通过aggregate-remove-host 将计算节点移除这个AZ,这个计算节点会自动回到默认的nova这个AZ中。
nova aggregate-remove-host 3 compute1
只有移除出AZ后才可以删除创建的aggregate
nova aggregate-delete 3