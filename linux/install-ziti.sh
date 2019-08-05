#!/bin/bash
#linux上安装中文字体

if [ `whoami` != "root" ]; then
    echo "需使用root用户执行"
    exit 1
fi

echo -e "\033[32m==============安装字体工具=====================\033[0m"

if [ `rpm -qa|grep -E "fontconfig|ttmkfdir"|wc -l` -ne 2 ];then
  yum -y install fontconfig ttmkfdir >/dev/null 2>&1
  if [ $? -ne 0 ];then
    echo -e "\033[31m工具安装失败，请检查DNS\033[0m"
    exit 1
  fi
fi

mkdir -p /usr/share/fonts/chinese

[ -f /usr/share/fonts/chinese/simsun.ttc ] || wget -P /usr/share/fonts/chinese http://10.10.10.10/package/chinese/simsun.ttc
[ -f /usr/share/fonts/chinese/msyh.ttc ]   || wget -P /usr/share/fonts/chinese http://10.10.10.10/package/chinese/msyh.ttc
[ -f /usr/share/fonts/chinese/msyhbd.ttc ] || wget -P /usr/share/fonts/chinese http://10.10.10.10/package/chinese/msyhbd.ttc
[ -f /usr/share/fonts/chinese/msyhl.ttc ]  || wget -P /usr/share/fonts/chinese http://10.10.10.10/package/chinese/msyhl.ttc

#搜索目录中所有的字体信息，并汇总生成fonts.scale文件
ttmkfdir -e /usr/share/X11/fonts/encodings/encodings.dir

sed -i 'N;26a\        <dir>/usr/share/fonts/chinese</dir>' /etc/fonts/fonts.conf

#刷新内存中的字体缓存
fc-cache

#查看字体列表
echo -e "\033[32m=========查看字体列表============\033[0m"
fc-list
echo -e "\033[32m=================================\033[0m"
