#!/bin/bash
#nginx日志切割

#日期格式 YYYY-MM-DD
day=`date +%F`
#切割日志存储路径
logs_backup_path="/data/nginx/logs/his-logs/$day"
#nginx日志路径
logs_path="/data/nginx/logs/"
#访问日志文件名
#logs_access='access'
#错误日志文件名
#logs_error="error"
#nginx的pid
pid_path="/data/nginx/nginx.pid"

#按天创建备份目录
[ -d $logs_backup_path ]||mkdir -p $logs_backup_path

mv ${logs_path}/*.log ${logs_backup_path}

kill -USR1 $(cat $pid_path )

cd ${logs_backup_path} && for i in `ls`;do tar -czf $i.tar.gz $i;done && rm -f *.log

#清理一个月前日志
DATA1=`date +%F -d'-30 day'`
rm -fr ${logs_path}/his-logs/${DATA1}
