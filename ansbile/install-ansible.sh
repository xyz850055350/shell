#! /bin/bash

set -e

yum_path="/opt/ansible"
tar_name="ansible-2.9.21.tgz"
ansible_path="/data"
soft_name="ansible"

# install package
package="vim-enhanced bash-completion bind-utils git glibc glibc-devel iotop lrzsz lsof make mutt net-tools nfs-utils nmap-ncat ntpdate numactl pciutils psmisc rsync sysstat telnet unzip vim wget expect chrony zip"

# check package--->检查是否安装
install_package(){
  for name in ${package}
  do
    if [ `rpm -qa|grep ${name}|wc -l` -gt 0 ];then 
      echo "${name}	该软件包已安装" >> check.txt
    else
      echo "${name}	该软件包还没有安装，正在安装中..."
      yum -y install ${name}
    fi
  done
}

install_yum(){
  cd /opt/ && wget http://www.xyz.con/ansible/${tar_name}
  tar -xvf ${tar_name}
  sleep 3
cat > /etc/yum.repos.d/ansible.repo << end
[ansible]
name = ansible
baseurl = file://${yum_path}
enabled = 1
gpgcheck = 0
end
}

install_ansible(){
  yum -y install ${soft_name}
  sleep 4
  rm -f /etc/yum.repos.d/ansible.repo
  rm -rf /opt/ansible*
}

install_package
install_yum
install_ansible
