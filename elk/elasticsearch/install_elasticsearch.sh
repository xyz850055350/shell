#!/bin/bash
#Elasticsearch安装脚本

username=app
file_source=/usr/local/src/elasticsearch-5.6.6.tar.gz
es_ver=elasticsearch-5.6.6

if [ `whoami` != "root" ]; then
    echo "需使用root用户执行"
    exit 1
fi

#文件是否存在
[ -e $file_source ]
if [ $? -eq 0 ];then
  tar -xf $file_source -C /usr/local/src
else
  echo -e "\033[31m文件不存在\033[0m"
  exit 1
fi

#处理jvm环境
which java &> /dev/null
if [ $? -ne 0  ];then
  echo "未找到JDK"
  #install_jdk
  exit 1
else
  ln -s `which java` /usr/bin/java > /dev/null 2>&1
fi

#内核参数
if [ `grep vm.max_map_count=262144 /etc/sysctl.conf|wc -l` -eq 0 ];then
  echo vm.max_map_count=262144 >> /etc/sysctl.conf
  sysctl -p > /dev/null
fi

mv /usr/local/src/$es_ver /usr/local/
ln -s /usr/local/$es_ver /usr/local/elasticsearch

echo -e "\033[31m===================配置信息=============================\033[0m"
echo -en "\033[31mJVM内存: \033[0m";read JVM
echo -en "\033[31m集群名称: \033[0m";read Cluster
echo -en "\033[31m节点名称: \033[0m";read Node
echo -en "\033[31m主节点[true/false]: \033[0m";read Master
echo -en "\033[31m数据节点[true/false]: \033[0m";read Data
echo -en "\033[31m集群IP: \033[0m";read Hosts
echo -e "\033[31m========================================================\033[0m"

if [ ! -z $JVM ];then
  sed -i "s#-Xms8g#-Xms${JVM}g#g" /usr/local/elasticsearch/config/jvm.options
  sed -i "s#-Xms8g#-Xms${JVM}g#g" /usr/local/elasticsearch/config/jvm.options
fi

[ ! -z $Cluster ] && sed -i "s#cluster.name: demo-name#cluster.name: $Cluster#g" /usr/local/elasticsearch/config/elasticsearch.yml || exit 1
[ ! -z $Node ]    && sed -i "s#node.name: node#node.name: $Node#g" /usr/local/elasticsearch/config/elasticsearch.yml || exit 1
[ ! -z $Master ]  && sed -i "s#node.master: true#node.master: $Master#g" /usr/local/elasticsearch/config/elasticsearch.yml || exit 1
[ ! -z $Data ]    && sed -i "s#node.data: true#node.data: $Data#g" /usr/local/elasticsearch/config/elasticsearch.yml || exit 1
[ ! -z $Hosts ]   && sed -i "s#discovery.zen.ping.unicast.hosts: ["127.0.0.1"]#discovery.zen.ping.unicast.hosts: ["$Hosts"]#g" /usr/local/elasticsearch/config/elasticsearch.yml

echo -e "\033[32m===================完成配置=============================\033[0m"
sleep 2

cp /usr/local/elasticsearch/config/elasticsearch.service /usr/lib/systemd/system
systemctl daemon-reload
systemctl enable elasticsearch > /dev/null 2>&1

mkdir -p /data/es/{data,logs,backup}

if id $username &> /dev/null; then
    chown -R $username.$username /data/ /usr/local/elasticsearch*
else
    useradd $username
    chown -R $username.$username /data/ /usr/local/elasticsearch*
fi

#安装ik分词插件
/usr/local/elasticsearch/bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.3.2/elasticsearch-analysis-ik-6.3.2.zip

systemctl start elasticsearch
systemctl status elasticsearch
