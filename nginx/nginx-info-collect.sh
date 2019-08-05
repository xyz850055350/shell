#!/bin/bash
#采集nginx进程配置信息

echo_json(){
	OLD_IFS="$IFS"
	IFS=';'
	tmp=$*
	echo "{"
	for i in ${tmp[@]}
	do
		echo '"'${i}'",' | sed 's/:/":"/g'
	done
	echo '"time":"'`date +%F_%T`'"'
	echo "}"
	IFS="$OLD_IFS"
}

pid=`ps -ef | grep -v grep | grep "nginx: master"  | awk  '{print $2}'`

ng_start_command=`readlink /proc/$pid/exe`

ng_config_dir=`$ky_start_command -t 2>&1 | tail -n 1 |awk '{print $4}'`

version=`$ng_start_command -v  2>&1| tail -n 1 |awk -F '/' '{print $NF}'`

for line in `netstat -tnpl | grep nginx | awk -F ':' '{print $2}' | awk '{print $1}'`
do
	ng_port=`echo $ky_port $line | sed 's/ /,/g'`
done

for line in `lsof  -a -p $pid  | grep log$ | awk '{print $NF}'`
do
	line=`dirname $line`
	ng_logs_dir=`echo $ky_logs_dir $line | sed 's/ /,/g'`
done

ng_logs_dir=`echo $ky_logs_dir | tr ',' '\n' | sort -u`
ng_logs_dir=`echo $ky_logs_dir | sed 's/ /,/g'`
bk_inst_name=`hostname`
ng_app_group=`ps -eo pid,user,group,cmd | grep -v grep | grep 'nginx: worker process' |  awk '{print $3}' | tail -n 1`
ng_app_user=`ps -eo pid,user,group,cmd | grep -v grep | grep 'nginx: worker process' |  awk '{print $2}' | tail -n 1`
ng_install_dir=`dirname $ng_start_command`
ng_stop_command="$ng_start_command -s stop"
echo_json "ng_start_command:$ng_start_command;ng_config_dir:$ng_config_dir;version:$version;ng_port:$ng_port;ng_logs_dir:$ng_logs_dir;bk_inst_name:$bk_inst_name;ng_app_group:$ng_app_group;ng_app_user:$ng_app_user;ng_install_dir:$ng_install_dir;ng_stop_command:$ng_stop_command"
exit
