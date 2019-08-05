#!/bin/bash
#filebeat安装配置
if [ `whoami` != "root" ]; then
    echo "需使用root用户执行"
    exit 1
fi

wget -P /usr/local/src/ http://10.10.10.10/package/filebeat-6.2.4-linux-x86_64.tar.gz
username=app
file_source=/usr/local/src/filebeat-6.2.4-linux-x86_64.tar.gz
filebeat_ver=filebeat-6.2.4-linux-x86_64

#文件是否存在
[ -e $file_source ]
if [ $? -eq 0 ];then
  tar -xf $file_source -C /usr/local/
  ln -s /usr/local/$filebeat_ver /usr/local/filebeat
else
  echo -e "\033[31m文件不存在\033[0m"
  exit 1
fi

cp /usr/local/filebeat/filebeat.service /usr/lib/systemd/system

#类型判断
es_or=`hostname | grep -es00 | wc -l`
nginx_or=`hostname | grep nginx`
if [ $? -eq 0 ];then
   mv /usr/local/filebeat/filebeat.yml /usr/local/filebeat/filebeat-bak.yml
   wget http://10.10.10.10/filebeat/filebeat-nginx.yml -O /usr/local/filebeat/filebeat.yml
   nginxtype_or=`hostname | awk -F "-" '{print $4}' | grep nginx`
   if [ $? -eq 0 ];then
       echo "这是前端nginx类型日志"
       System=erp-prd-nginx-front
   else
       echo "这是网关nginx类型日志"
       System=erp-prd-nginx-gateway
   fi
elif [[ $es_or -eq 1 ]];then
   mv /usr/local/filebeat/filebeat.yml /usr/local/filebeat/filebeat-bak.yml
   wget http://10.10.10.10/filebeat/filebeat-es.yml -O /usr/local/filebeat/filebeat.yml
   System=erp-es-slow
else
   echo "这是java类型日志"
   mv /usr/local/filebeat/filebeat.yml /usr/local/filebeat/filebeat-bak.yml
   wget http://10.10.10.10/filebeat/filebeat-java.yml -O /usr/local/filebeat/filebeat.yml
   Systemnum=`find /app/erp/*.jar | awk -F.jar '{print $1}' | awk -Ferp/ '{print $2}'| wc -l`
   if [[ $Systemnum -eq 1 ]];then
        System=`find /app/erp/*.jar | awk -F.jar '{print $1}' | awk -Ferp/ '{print $2}'`
   else
    exit 1
   fi
fi

#topic配置
[ ! -z $System ] && sed -i "s#demo#$System#g" /usr/local/filebeat/filebeat.yml || exit 1
sleep 2

id $username > /dev/null 2>&1 || useradd $username
chown -R $username.$username /usr/local/filebeat*

systemctl daemon-reload
systemctl enable filebeat > /dev/null 2>&1
systemctl start filebeat
systemctl status filebeat
