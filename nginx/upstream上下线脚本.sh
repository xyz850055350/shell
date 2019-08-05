#!/bin/bash
#-----------desc-----------------------
# desc   : nginx script
# update : 2018-11-11
# version: 1.0.0
#-----------desc-----------------------

# $1 add-添加注释  del-删除注释
# $2 ip地址尾数
# $3 端口

ip=10.10.10.$2
port=$3

#only root user can run
if [ `whoami` != "root" ]; then
    echo "only root user can run !!!"
    exit 1
fi

#帮助信息
help(){
    echo -e "\033[0m参数: $0
        add IP PORT   #注释节点
        del IP PORT   #取消注释
        \033[0m"
}

#需接收3个参数
if [ $# -ne 3 ];then
  help
  exit 1
fi

#添加注释
add(){
sed -i  "s/server $ip:$port/#server $ip:$port/g"  up.conf
#echo "sed -i  "s/server $ip:$port/#server $ip:$port/g"  *.conf"
}

#取消注释
del(){
sed -i "s/#server $ip:$port/server $ip:$port/g" up.conf
}

#判断ip格式
local_ip(){
  #判断是否内网地址
  echo $ip |grep "^10\.10[0-9]\.[0-9]\{1,3\}\.[0-9]\{1,3\}" > /dev/null
  if [ $? -ne 0 ];then
    echo "内网地址不正确$ip"
    exit 1
  fi

  #判断配置文件中是否有代理信息
  grep $ip:$port up.conf > /dev/null 2>&1
  if [ $? -ne 0 ];then
    echo "serer $ip:$port 代理未找到"
    exit 1
  fi
}

case $1 in
  add)
    local_ip $ip $port
    add $ip $port
    [ $? -eq 0 ] && nginx -t || exit 1
    sleep 3
    [ $? -eq 0 ] && nginx -s reload || exit 1
  ;;
  del)
    local_ip $ip $port
    del $ip $port
    [ $? -eq 0 ] && nginx -t || exit 1
    sleep 3
    [ $? -eq 0 ] && nginx -s reload || exit 1
  ;;
  *)
    help
  ;;
esac
