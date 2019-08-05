#!/bin/bash

#1.定义基础信息
zk_version=3.4.13
kafka_version=2.11-1.1.0
soft_dir=/usr/local/src
install_dir=/usr/local
data_dir=/data
zk_data_dir=$data_dir/zookeeper
kafka_data_dir=$data_dir/kafka
run_user=app

#2.显示执行方式
help(){
#  cat <<EOF
echo -e "\033[33m
  命令：
        install                 安装单机版,默认参数值可省略
        参数:
                partition       分区数量(默认1)
                hours           数据持久化时间(默认168小时,一周)
                replication     副本数量(单节点都为1)
                jvm             kafka运行jvm大小(默认4G)
        示例:
                install partition=1 hours=168 replication=1 jvm=4

  命令：  
        cluster                 安装集群版,默认参数值可省略
        参数:
                partition       分区数量(默认1)
                hours           数据持久化时间(默认168小时,一周)
                replication     副本数量(默认1,副本数不能超过kafka节点数)
                jvm             kafka运行jvm大小(默认4G)
                ips             IP列表(集群参数必填,如:1.1.1.1,2.2.2.2,3.3.3.3)
        示例:
                cluster partition=1 hours=168 replication=1 jvm=4 ips=1.1.1.1,2.2.2.2,3.3.3.3
\033[0m"
#EOF
}

#3.基础环境检测及目录创建
check_run(){
  #3.1需root用户执行
  user=`whoami`
  if [ $user != "root" ];then
    echo "需要root权限运行"
    exit 1
  fi
  #3.2检测java
  which java > /dev/null 2>&1
  if [ $? -ne 0  ]; then
    echo -e "\033[31m未检测到java环境,下载jdk安装中……\033[0m"
    wget -q http://10.10.10.10/package/jdk.bin -P $soft_dir > /dev/null
    sh $soft_dir/jdk.bin
    source /etc/profile
    ln -s `which java`/usr/bin/java
  fi
  #3.3获取本地IP
  export local_ip=`ifconfig -a|grep '255.255.255'|grep -E 'inet addr|inet'|grep -v '127'|awk -F " " '{print $2}'`
  #3.4创建数据目录 
  mkdir -p $zk_data_dir $kafka_data_dir
}

#4.生成配置文件
install(){

  #4.1处理参数格式
  args=$*
  for i in ${args[@]};do
    tmp=`echo $i|grep partition`
    if [ $? -eq 0 ];then
      partition=`echo $i| grep partition | awk -F '=' '{print $2}'`
    fi
    
    tmp=`echo $i|grep hours`
    if [ $? -eq 0 ];then
      hours=`echo $i| grep hours | awk -F '=' '{print $2}'`
    fi
    
    tmp=`echo $i|grep replication`
    if [ $? -eq 0 ];then
      replication=`echo $i| grep replication | awk -F '=' '{print $2}'`
    fi
    
    tmp=`echo $i|grep jvm`
    if [ $? -eq 0 ];then
      jvm=`echo $i| grep jvm | awk -F '=' '{print $2}'`
    fi

    tmp=`echo $i|grep ips`
    if [ $? -eq 0 ];then
      ips=`echo $i| grep ips | awk -F '=' '{print $2}'`
    fi
  done
  
  #写入默认值
  hours=${hours:-168}
  partition=${partition:-1}
  replication=${replication:-1}
  jvm=${jvm:-4}

  #4.2下载安装包,解压,建立软链接
  echo -e "\033[32m下载安装包中……\033[0m"
  [ ! -f "$soft_dir/zookeeper-${zk_version}.tar.gz" ] && wget -q http://10.10.10.10/package/zookeeper-${zk_version}.tar.gz -P $soft_dir
  [ ! -f "$soft_dir/kafka_${kafka_version}.tgz" ]     && wget -q http://10.10.10.10/package/kafka_${kafka_version}.tgz     -P $soft_dir

  [ -f $soft_dir/zookeeper-${zk_version}.tar.gz ] && tar -xf $soft_dir/zookeeper-${zk_version}.tar.gz -C $install_dir
  [ -f $soft_dir/kafka_${kafka_version}.tgz ]     && tar -xf $soft_dir/kafka_${kafka_version}.tgz     -C $install_dir

  ln -s $install_dir/kafka_${kafka_version}  $install_dir/kafka
  ln -s $install_dir/zookeeper-${zk_version} $install_dir/zookeeper
  

#4.3生成zk配置文件
echo -e "========================================\n\033[32m生成zk配置文件……\033[0m"
echo "$install_dir/zookeeper/conf/zoo.cfg"
tee $install_dir/zookeeper/conf/zoo.cfg << EOF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=$zk_data_dir
clientPort=2181
EOF

#4.4修改zk启动日志文件路径  
sed -i "s#ZOO_LOG_DIR=\".\"#ZOO_LOG_DIR=\"${zk_data_dir}\"#g" $install_dir/zookeeper/bin/zkEnv.sh

#4.5生成kafka配置文件
sleep 3 && echo -e "========================================\n\033[32m生成kafka配置文件……\033[0m"
echo "$install_dir/kafka/config/server.properties"
tee $install_dir/kafka/config/server.properties << EOF
#broker.id值
broker.id=0
#监听地址
listeners=PLAINTEXT://${local_ip}:9092
#默认partitions数量
num.partitions=${partition}
#数据保留时间
log.retention.hours=${hours}
#副本数量
default.replication.factor=${replication}
offsets.topic.replication.factor=${replication}
transaction.state.log.replication.factor=${replication}
transaction.state.log.min.isr=${replication}
#zk连接地址及目录
zookeeper.connect=${local_ip}:2181
#持久化目录
log.dirs=${kafka_data_dir}
num.network.threads=5
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
num.recovery.threads.per.data.dir=1
auto.create.topics.enable=true
delete.topic.enable=true
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
EOF

#4.6修改kafka jvm参数
sed -i '29s/^/#/g' $install_dir/kafka/bin/kafka-server-start.sh 
a="export KAFKA_HEAP_OPTS=\"-Xmx${jvm}G -Xms${jvm}G -Xmn2G -XX:PermSize=64m -XX:MaxPermSize=128m -XX:SurvivorRatio=6 -XX:CMSInitiatingOccupancyFraction=70 -XX:+UseCMSInitiatingOccupancyOnly\""
sed -i "29a$a" $install_dir/kafka/bin/kafka-server-start.sh

#4.7集群配置信息
if [ $1 == cluster ];then
  if [ ! "$ips" == "" ];then
    ips=`echo $ips | sed 's/,/ /g'`
  else
    rock
    echo -e "\033[31m集群配置ip节点不能为空\033[0m"
    exit
  fi
  num=0
  for i in ${ips[@]}
  do
    echo $i |grep "^10\.10[0-9]\.[0-9]\{1,3\}\.[0-9]\{1,3\}" > /dev/null
    if [ $? -ne 0 ];then
      echo "内网地址格式不正确$i"
      rock
      exit 1
    fi
    #写入zk server信息
    let num=$num+1	
    echo "server.${num}=${i}:20881:30881" >> $install_dir/zookeeper/conf/zoo.cfg
    all_ip+="$i:2181," 
    if [ $i == $local_ip ];then
      echo $num > ${zk_data_dir}/myid
      sed -i "s#broker.id=0#broker.id=$num#g" $install_dir/kafka/config/server.properties
    fi
  done
  all_ip=`echo $all_ip|sed 's/,$/ /g'`
  sed -i "s/^zookeeper.connect=.*$/zookeeper.connect=$all_ip/g" $install_dir/kafka/config/server.properties
fi

}

#5.创建数据目录及授权
authown(){
  chown -R ${run_user}.${run_user} $install_dir/kafka* $install_dir/zookeeper*
  chown -R ${run_user}.${run_user} $data_dir
}

#6.生成zk、kafka启动文件
start(){
#6.1zk
sleep 2&& echo -e "========================================\n\033[32m生成zk service启动文件……\033[0m"
echo "/usr/lib/systemd/system/zookeeper.service"
tee /usr/lib/systemd/system/zookeeper.service <<EOF
[Unit]
Description=zookeeper
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/usr/local/zookeeper/bin/zkServer.sh start 
ExecStop=/usr/local/zookeeper/bin/zkServer.sh stop
Restart=always
User=$run_user
Group=$run_user

[Install]
WantedBy=multi-user.target
EOF
#6.2kafka
sleep 2 && echo -e "========================================\n\033[32m生成kakfa service启动文件……\033[0m"
echo "/usr/lib/systemd/system/kafka.service"
tee /usr/lib/systemd/system/kafka.service <<EOF
[Unit]
Description=kafka - high performance web server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties 
ExecStop=/usr/local/kafka/bin/kafka-server-stop.sh  
Restart=always
User=$run_user
Group=$run_user

[Install]
WantedBy=multi-user.target
EOF

echo -e "========================================\n" && sleep 2

#6.3启动
#配置kafka环境变量
echo 'export PATH=$PATH:/usr/local/kafka/bin' >> /etc/profile
source /etc/profile

systemctl daemon-reload
systemctl enable zookeeper
systemctl enable kafka
systemctl start zookeeper
[ $? -eq 0 ] && systemctl status zookeeper
sleep 3 && echo -e "========================================\n"
systemctl start kafka
[ $? -eq 0 ] && systemctl status kafka
echo -e "========================================" && sleep 3
echo -e "\033[33m启动方式\nsystemctl start zookeeper\nsystemctl start kafka\033[0m"
}

#7回退
rock(){
  rm -rf $kafka_data_dir $zk_data_dir $install_dir/zookeeper* $install_dir/kafka*
  rm -f /usr/lib/systemd/system/zookeeper.service /usr/lib/systemd/system/kafka.service
  rm -f $soft_dir/kafka_${kafka_version}.tgz $soft_dir/zookeeper-${zk_version}.tar.gz
  systemctl daemon-reload
}

#main
if [ "$1" != "install" -a "$1" != "cluster" ] ;then
  help
else
  check_run
  install $*
  authown
  start  
fi
