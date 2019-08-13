#!/bin/bash

:'
#快速安装open_office
#curl http://10.10.10.10/install_openoffice.sh |bash
启动方式：
nohup /opt/openoffice4/program/soffice -headless -accept="socket,host=127.0.0.1,port=8800;urp;" -nofirststartwizard >> /data/openoffice.log &
'

whoami | grep root
if [[ $? -ne 0 ]];then
  echo "请在root用户下运行"
  exit 1
fi

down_url="http://10.10.10.10/package/"
tar_name="Apache_OpenOffice_4.1.6_Linux_x86-64_install-rpm_zh-CN.tar.gz"

yum -y groupinstall "X Window System"
yum -y install libXext

cd /usr/local/src
wget ${down_url}/${tar_name}
tar xf ${tar_name}
cd /usr/local/src/zh-CN/RPMS
yum -y  install *.rpm

wget -P /usr/share/fonts ${down_url}/fonts/simhei.ttf
wget -P /usr/share/fonts ${down_url}/fonts/simsun.ttc

fc-cache

cat > /opt/check_openoffice.sh << EOF
#!/bin/bash

netstat -tanpl | grep -v grep | grep 8800 >> /dev/null
if [[ $? -ne 0 ]] ;then
  nohup /opt/openoffice4/program/soffice -headless -accept="socket,host=127.0.0.1,port=8800;urp;" -nofirststartwizard  >> /data/openoffice.log &
fi
EOF

chmod u+x /opt/check_openoffice.sh
echo '*/5 * * * *  /opt/check_openoffice.sh' >> /var/spool/cron/root
echo 'nohup /opt/openoffice4/program/soffice -headless -accept="socket,host=127.0.0.1,port=8800;urp;" -nofirststartwizard &' >> /etc/rc.local
nohup /opt/openoffice4/program/soffice -headless -accept="socket,host=127.0.0.1,port=8800;urp;" -nofirststartwizard &
