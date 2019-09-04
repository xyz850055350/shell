#!/bin/bash
#kafka进程信息采集脚本

. /etc/profile

echo_json(){
  OLD_IFS="$IFS"
  IFS=';'
  tmp=$*
  echo "{"
  for i in ${tmp[@]}
  do
    echo -e '\033[31m"'${i}'",\033[0m' | sed 's/:/":"/g'
  done
  echo '"time":"'`date +%F_%T`'"'
  echo "}"
  IFS="$OLD_IFS"
}
#本机地址
ka_ip_addr=`ifconfig -a|grep 255.255.255|grep -E 'inet addr|inet'|grep -Ev "127|0.0.0.0"|awk -F " " '{print $2}'`

#pid进程号
pid=`jps -l|grep kafka.Kafka|awk '{print $1}'`

#基础目录
base_dir=`lsof -a -p $pid|grep cwd|awk '{print $9}'`

#安装目录
ka_app_homedir=`dirname $base_dir`

#配置文件路径
ka_config_dir="$ka_app_homedir/config/server.properties"

#启动命令
ka_start_command="$base_dir/kafka-server-start.sh -daemon $ka_config_dir"

#停止命令
ka_stop_command="$base_dir/kafka-server-stop.sh"

#kafka版本
kafka_jar_path=`find $ka_app_homedir/libs/ -name \*kafka_\* |head -1`
ka_app_version=`basename $kafka_jar_path|awk -F 'kafka_|.jar' '{print $2}'`

#jdk版本
java_path=`lsof -a -p $pid |grep txt|awk '{print $9}'`
ka_jdk_version=`$java_path -version 2>&1 |awk 'NR==1{ gsub(/"/,""); print $3 }'`

#kafka服务端口
ka_app_service_port=`grep ^listeners= $ka_config_dir | awk -F ':' '{print $3}'`

#kafka状态

if [ -n ka_app_service_port ] && [ -n pid ];then
  ka_app_status="kafka is ok"
else
  ka_app_status="status check fail"
fi

#kafka监听端口
for i in `netstat -tnpl|grep $pid|grep -v $ka_app_service_port|awk -F ':' '{print $2}'|awk '{print $1}'`
do
  ka_cluster_port=`echo $ka_cluster_port $i | sed 's/ /,/g'`
done

#日志或数据持久化目录
ka_app_datadir=`grep ^log.dirs $ka_config_dir|awk -F '=' '{print $2}'`

#主机名
ka_host_name=`hostname`

#kafka进程所属者
ka_app_user=`ps -ef|grep -v grep|grep $pid|awk '{print $1}'`

#kafka进程所属组
ka_app_group=`ps -eo pid,user,group,cmd|grep -v grep |grep $pid|awk '{print $3}'`

echo_json "\
ka_ip_addr:$ka_ip_addr;\
ka_host_name:$ka_host_name;\
ka_app_status:$ka_app_status;\
ka_app_service_port:$ka_app_service_port;\
ka_cluster_port:$ka_cluster_port;\
ka_jdk_version:$ka_jdk_version;\
ka_app_version:$ka_app_version;\
ka_app_group:$ka_app_group;\
ka_app_user:$ka_app_user;\
ka_config_dir:$ka_config_dir;\
ka_app_homedir:$ka_app_homedir;\
ka_app_datadir:$ka_app_datadir;\
ka_start_command:$ka_start_command;\
ka_stop_command:$ka_stop_command\
"

exit
