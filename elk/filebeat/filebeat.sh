#! /bin/bash
#filebeat-shell启停脚本

agent="/usr/local/filebeat/filebeat"
args="-c /usr/local/filebeat/filebeat.yml -path.home /usr/local/filebeat -path.config /usr/local/filebeat -path.data /usr/local/filebeat/data -path.logs /usr/local/filebeat/logs"
test_args="-e -configtest"
test() {
$agent $args $test_args
}

start() {
    pid=`ps -ef |grep /data/filebeat/filebeat |grep -v grep | awk  '{ print $2}'`
    if [ ! "$pid" ];then
        echo "Starting filebeat... "
        test
        if [ $? -ne 0 ]; then
            echo
            exit 1
        fi
        $agent $args &
        if [ $? == 0 ];then
            echo "start filebeat ok"
        else
            echo "start filebeat failed"
        fi
    else
        echo "filebeat is still running!"
        exit
    fi
}

stop() {
    echo -n $"Stopping filebeat: "
    pid=`ps -ef |grep /data/filebeat/filebeat |grep -v grep | awk  '{ print $2}'`
    if [ ! "$pid" ];then
echo "filebeat is not running"
    else
        kill $pid
echo "stop filebeat ok"
    fi
}

restart() {
    stop
    start
}

status(){
    pid=`ps -ef |grep /data/filebeat/filebeat |grep -v grep | awk  '{ print $2}'`
    if [ ! "$pid" ];then
        echo "filebeat is not running"
    else
        echo "filebeat is running"
    fi
}

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        restart
    ;;
    status)
        status
    ;;
    *)
        echo $"Usage: $0 {start|stop|restart|status}"
        exit 1
esac
