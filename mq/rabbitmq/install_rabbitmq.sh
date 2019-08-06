#!/bin/bash
wget -P /usr/local/src http://10.10.10.10/package/rabbitmq-server-3.6.12.tar.gz
packge_name='rabbitmq-server-3.6.12.tar.gz'
cd /usr/local/src
#wget $(down_url)/package/$packge_name
tar zxvf $packge_name
yum install -y rabbitmq/*.rpm
mkdir -p /data/rabbitmq
mkdir -p /data/logs

cat > /etc/rabbitmq/rabbitmq-env.conf <<EOF
RABBITMQ_MNESIA_BASE=/data/rabbitmq
RABBITMQ_LOG_BASE=/data/logs
EOF

chown rabbitmq:rabbitmq /data/rabbitmq
chown rabbitmq:rabbitmq /data/logs

systemctl enable rabbitmq-server >/dev/null
systemctl start rabbitmq-server  

rabbitmqctl add_user admin admin
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin '.*' '.*' '.*'
rabbitmq-plugins enable rabbitmq_management

systemctl restart rabbitmq-server
sleep 2
systemctl status rabbitmq-server

echo -e "\033[31m=================集群命令===========================\033[0m"
echo "同步文件 400 rabbitmq.rabbitmq权限 /var/lib/rabbitmq/.erlang.cookie"
echo "rabbitmqctl stop_app"
echo "rabbitmqctl join_cluster rabbit@hostname --ram"
echo "rabbitmqctl start_app"
echo "rabbitmqctl set_policy -p / ha-all \"^\" '{\"ha-mode\":\"all\"}'"
echo "rabbitmqctl set_policy -p / ha-all \"^\" '{\"ha-mode\":\"exactly\",\"ha-params\":2,\"ha-sync-mode\":\"automatic\"}'"
echo -e "\033[31m=================集群命令===========================\033[0m"
