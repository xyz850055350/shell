#!/bin/bash
#mongodb单机版安装
#wget -P /usr/local/src http://10.10.10.10/package/mongo/mongodb-linux-x86_64-rhel70-4.2.0.tgz
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-4.2.0.tgz

username=app
file_source=/usr/local/src/mongodb-linux-x86_64-rhel70-4.2.0.tgz
mongo_ver=mongodb-linux-x86_64-rhel70-4.2.0

if [ `whoami` != "root" ]; then
    echo "需使用root用户执行"
    exit 1
fi

#文件是否存在
[ -e $file_source ]
if [ $? -eq 0 ];then
  tar -xf $file_source -C /usr/local/
  ln -s /usr/local/$mongo_ver /usr/local/mongodb
else
  echo -e "\033[31m文件不存在\033[0m"
  exit 1
fi

#导入配置文件
cat > /etc/mongodb.conf<< EOF
bind_ip=0.0.0.0
fork=true
dbpath=/data/mongodb/data/
logpath=/data/mongodb/logs/mongodb.log
logappend=true
EOF

#导入service启动文件
cat > /usr/lib/systemd/system/mongodb.service <<EOF
[Unit]
Description=mongodb
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
User=$username
ExecStart=/usr/local/mongodb/bin/mongod --config /etc/mongodb.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/usr/local/mongodb/bin/mongod --shutdown --config /etc/mongodb.conf
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

#添加mongo环境变量
echo 'export PATH=/usr/local/mongodb/bin:$PATH' >> /etc/profile
source /etc/profile

#创建目录
mkdir -p /data/mongodb/{logs,data}

#检查启动用户并授权
id $username > /dev/null 2>&1 || useradd $username
chown -R $username.$username /usr/local/mongodb* /data/{mongodb,logs}

#启动
systemctl daemon-reload
systemctl enable mongodb > /dev/null 2>&1

systemctl start mongodb
systemctl status mongodb
