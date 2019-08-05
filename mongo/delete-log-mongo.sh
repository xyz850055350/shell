#/bin/bash
#分割日志文件
mongo 127.0.0.1:27017/admin --eval "db.runCommand({logRotate:1});"
#查找日志文件并删除
DATA0=`date +%F -d '-1 day'`
log_file=/data/logs/mongodb.log.$DATA0*
[ -f $log_file ] && rm -f $log_file
