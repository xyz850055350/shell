#!/bin/bash
# elasticserach-shell启动脚本
# chkconfig:   2345 80 20
# description: Starts and stops a single elasticsearch instance on this system

# 启用用户
ES_USER="app" 
ES_HOME=/app/es/elasticsearch/
PID_PATH_NAME=$ES_HOME/elasticsearch.pid

# 启动命令
d_start() {
  echo -en "\033[36mStarting elasticsearch ...\033[0m"
su $ES_USER<<EOF
cd $ES_HOME
./bin/elasticsearch -d
exit
EOF
  ps -ef|grep elasticsearch |grep -Ev "grep|bash"|awk '{print $2}' > $PID_PATH_NAME
  sleep 3
  if [ -s $PID_PATH_NAME ]; then
    echo -e "\033[36m         [OK]\033[0m"
  else
    echo -e "\033[31m            [Faild]\033[0m"
  fi
}

# 停止命令
d_stop() {
  echo -ne "\033[36mStopping elasticsearch              \033[0m"
  ps -ef|grep elasticsearch |grep -Ev "bash|grep"|awk '{print $2}'|xargs kill -9
  if [ -e $PID_PATH_NAME ]; then
    rm -f $PID_PATH_NAME
  fi
  sleep 1
  echo -e "\033[36m  [OK]\033[0m"
  #action "Stopping elasticsearch" /bin/true
}

# 查看状态
d_status() {
  curl http://127.0.0.1:9200 > /dev/null 2>&1
}

# 重启命令
d_restart() {
  d_status
  if [ $? -eq 0 ]; then
    d_stop
    sleep 1
    d_start
  else
    echo -e "\033[36melasticsearch is not running...\033[0m"
    d_start
  fi
}

# 条件判断
case $1 in
  start)
    d_status && echo -e "\033[36melasticsearch is running.\033[0m" && exit 0
    d_start
    ;;
  stop)
    d_status
    if [ $? -eq 0 ]; then
      d_stop
    else
      echo -e "\033[31melasticsearch is not running.\033[0m"
      exit 0
    fi
    ;;
  restart)
    d_restart
    ;;
  status)
    ps -ef|grep elasticsearch|grep -Ev "bash|grep"|grep . --color=auto
    [ $? -ne 0 ] && echo -e "\033[31melasticsearch is not running...\033[0m"
    ;;
  *)
    echo -e "\033[31;5musage: $0 {start|stop|restart|status}\033[0m"
    exit 1
    ;;
esac

exit 0
