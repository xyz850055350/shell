#!/bin/bash
#mongodb单机版安装
wget -P /usr/local/src http://10.10.10.10/package/mongo/mongodb-linux-x86_64-3.6.3.tgz
#wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-4.0.3.tgz
wget -P /usr/local/src http://10.10.10.10/package/mongo/mongodb.conf
wget -P /usr/local/src http://10.10.10.10/package/mongo/mongodb.service

username=app
file_source=/usr/local/src/mongodb-linux-x86_64-3.6.3.tgz
mongo_ver=mongodb-linux-x86_64-3.6.3

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

cat > /etc/mongodb.conf<< EOF
bind_ip=0.0.0.0
fork=true
dbpath=/data/mongodb
logpath=/data/logs/mongodb.log
logappend=true
EOF

echo 'export PATH=/usr/local/mongodb/bin:$PATH' >> /etc/profile
source /etc/profile

[ $? -eq 0 ] && mv /usr/local/src/mongodb.service /usr/lib/systemd/system
#[ $? -eq 0 ] && mv /usr/local/src/mongodb.conf /etc/

mkdir -p /data/{mongodb,logs}

id $username > /dev/null 2>&1 || useradd $username
chown -R $username.$username /usr/local/mongodb* /data/{mongodb,logs}
[ $username != "app" ] && sed -i "s#User=app#User=${username}#g" /usr/lib/systemd/system/mongodb.service

systemctl daemon-reload
systemctl enable mongodb > /dev/null 2>&1

systemctl start mongodb
systemctl status mongodb
