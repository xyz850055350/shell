#!/bin/bash
#zookeeper进程信息采集脚本

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
zk_ip_addr=`ifconfig -a|grep 255.255.255|grep -E 'inet addr|inet'|grep -Ev "127|0.0.0.0"|awk -F " " '{print $2}'`

#pid进程号
pid=`jps -l|grep org.apache.zookeeper.server.quorum.QuorumPeerMain|awk '{print $1}'`

#配置文件路径
zk_config_dir=`ps -ef|grep -v grep |grep $pid|awk '{print $NF}'| sed 's/bin\/\.\.\///g'`

#zk服务端口
zk_app_service_port=`grep clientPort $zk_config_dir|awk -F '=' '{print $2}'`

#运行状态
zk_app_status=`echo ruok |nc localhost $zk_app_service_port`

#基础目录
base_dir=`echo envi|nc localhost $zk_app_service_port|grep java.class.path|awk -F '=' '{print $2}' | awk -F 'bin' '{print $1}'`
echo $base_dir
#启动命令
zk_start_command="$base_dir/zkServer.sh start"

#停止命令
zk_stop_command="$base_dir/zkServer.sh stop"

#zk版本
zk_app_version=`echo envi|nc localhost $zk_app_service_port|grep zookeeper.version|awk -F [=-] '{print $2}'`

#jdk版本
zk_jdk_version=`echo envi|nc localhost $zk_app_service_port|grep java.version|awk -F '=' '{print $2}'`

#zk集群监听端口
for i in `netstat -tnpl|grep $pid|grep -v $zk_app_service_port|awk -F ':' '{print $2}'|awk '{print $1}'`
do
  zk_cluster_port=`echo $zk_cluster_port $i|sed 's/ /,/g'`
done

#数据持久化目录
zk_app_datadir=`echo conf|nc localhost $zk_app_service_port|grep dataLogDir|awk -F '=' '{print $2}'`

#主机名
zk_host_name=`hostname`

#zk进程所属者
zk_app_user=`ps -ef|grep -v grep|grep $pid|awk '{print $1}'`

#zk进程所属组
zk_app_group=`ps -eo pid,user,group,cmd|grep -v grep |grep $pid|awk '{print $3}'`

#安装目录
zk_app_homedir=`dirname $base_dir`

echo_json "\
zk_ip_addr:$zk_ip_addr;\
zk_host_name:$zk_host_name;\
zk_app_status:$zk_app_status;\
zk_app_service_port:$zk_app_service_port;\
zk_cluster_port:$zk_cluster_port;\
zk_jdk_version:$zk_jdk_version;\
zk_app_version:$zk_app_version;\
zk_app_group:$zk_app_group;\
zk_app_user:$zk_app_user;\
zk_config_dir:$zk_config_dir;\
zk_app_homedir:$zk_app_homedir;\
zk_app_datadir:$zk_app_datadir;\
zk_start_command:$zk_start_command;\
zk_stop_command:$zk_stop_command\
"

exit
