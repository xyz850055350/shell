#!/bin/bash

#系统初始化,init centos V1.0.0
echo "V1.0.0" > /etc/init_centos_ver

#1.1堡垒机/运维平台/Jenkins平台新建账号,及平台密钥
appkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWG7pFpIaJctqb+updccAHXPjFKrcLLzwmSBJUu91rxAJAbJpVVweknppuHdK5oUEezbDG4P9v2kso0dOGzNgGO62qtrSLDyZDbEPTE3pjIcfFMqEM0Mjx/pPngT2ZnR6M03zTMIVh66u6wdKFG9Z3wLiQpzO1kt1aW7JdhjlX33vTmjWkxIkcngOAGfsAcxoMAsRG3AknkJ1se9YnotiT5DV6EIpZoE7vnD5pt0XoKjPkCe1del8a8elx2t5m1IHs1dxE6JWeHk4CunInUkPMnEWLw7Y7oMmZFUHrDnlvh2JN9goKeNR/uDq31wQ0lg5dDgfqwt7/QUvCRDQ54G6z root@Pre-0-7"
yunweikey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWG7pFpIaJctqb+updccAHXPjFKrcLLzwmSBJUu91rxAJAbJpVVweknppuHdK5oUEezbDG4P9v2kso0dOGzNgGO62qtrSLDyZDbEPTE3pjIcfFMqEM0Mjx/pPngT2ZnR6M03zTMIVh66u6wdKFG9Z3wLiQpzO1kt1aW7JdhjlX33vTmjWkxIkcngOAGfsAcxoMAsRG3AknkJ1se9YnotiT5DV6EIpZoE7vnD5pt0XoKjPkCe1del8a8elx2t5m1IHs1dxE6JWeHk4CunInUkPMnEWLw7Y7oMmZFUHrDnlvh2JN9goKeNR/uDq31wQ0lg5dDgfqwt7/QUvCRDQ54G6z root@Pre-0-7"

CrePubKey(){
    useradd $1
    HOME=/home/$1
    IDCMD=id; [ -x /usr/xpg4/bin/id ] && IDCMD=/usr/xpg4/bin/id
    if [ `$IDCMD -un` = "root" ]
    then
        if [ -f $HOME/.ssh/authorized_keys ]
    then
           echo  $2 >> $HOME/.ssh/authorized_keys
    else
            mkdir -p $HOME/.ssh 
            chmod 700 $HOME/.ssh
            echo  $2 >> $HOME/.ssh/authorized_keys 
            chmod 600 $HOME/.ssh/authorized_keys
            chown ${1}:${1} -R $HOME/.ssh 
        fi
    else 
        echo "Error: must be run by root" 
    fi
}

CreSu(){
     echo "start cresu"
     grep "$1" /etc/sudoers |grep "NOPASSWD: ALL"  > /dev/null
     if [ "$?" != 0 ] 
     then 
         echo "$1 ALL=(ALL) NOPASSWD: ALL"  >> /etc/sudoers
     else 
         echo "$1 已有sudo权限 "
     fi  
}

CrePubKey yunwei "$yunweikey"
CrePubKey app    "$appkey"
CrePubKey dev    "$devkey"
CreSu     yunwei

#1.2删除不必要系统的用户
UserDel="adm lp sync shutdown halt news uucp operator games gopher ftp"
for u in ${UserDel};do userdel ${u};done

#1.3删除不必要系统的用户组
GroupDel="adm lp news uucp games dip pppusers"
for g in ${GroupDel};do groupdel ${g};done

#1.4标准化系统账号,初始化密码
echo 'xydev@2019.com' | passwd --stdin dev
echo 'xyapp@2019.com' | passwd --stdin app

##1.5建立usr01用户组
#groupadd -g 1600 usr01
##系统管理员用
#useradd -u 1601 -o -g usr01 -d /home/kylog kylog
#echo 'kylog@2018.com' | passwd --stdin kylog
#[ ! -d ~kylog/.ssh ] && mkdir -m 700 ~kylog/.ssh
#chmod -R 700 ~kylog/.ssh
#chown -R kylog:usr01 ~kylog/.ssh
##DBA用
#useradd -u 1602 -o -g usr01 -d /home/kydba kydba
#echo 'kydba@2018.com' | passwd --stdin kydba
##普通用户登陆
#useradd -u 1603 -o -g usr01 -d /home/kyapp kyapp
#echo 'kyapp@2018.com' | passwd --stdin kyapp

#1.6关闭DNS解析,限制root用户远程登陆
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
#ssh压缩
sed -i 's/#Compression delayed/Compression yes/' /etc/ssh/sshd_config
#ssh连接取消yes or no
sed -i '/StrictHostKeyChecking/a\    StrictHostKeyChecking no' /etc/ssh/ssh_config
service sshd restart

#1.7添加sudo记录日志
echo "Defaults logfile=/var/log/sudo.log" >> /etc/sudoers

#1.8口令策略
#1.8.1口令最短长度:10个字符
sed -i 's:PASS_MIN_LEN    5:PASS_MIN_LEN    10:g' /etc/login.defs
#1.8.2口令历史:修改密码不得使用最近5次的密码
sed -i 's/use_authtok/use_authtok remember=5/' /etc/pam.d/system-auth
#1.8.3口令复杂度:大写/小写字母、数字、特殊符号任选3种组合
sed -i 's/authtok_type=/authtok_type= minclass=3/' /etc/pam.d/system-auth

#1.9安装基础工具
yum -y install wget vim epel-release lsof lrzsz telnet net-tools openssl openssl-devel openssl-perl \
openssl-static gcc gcc-c++ glibc glibc-devel nethogs psmisc bind-utils ntpdate sudo strace htop \
iftop expect bison patch unzip  bzip2 mlocate sysstat setuptool kernel-headers rsync nc mtr \
traceroute libgcc zlib zlib-devel pcre pcre-devel pcre-static perl-WWW-Curl tree ncurses-devel sl jq

#2.0清除遗留系统服务
yum -y remove telnet-server rsh-server ypbind ypserv tftp tftp-server talk talk-server

#2.1开启必要的服务
StartServiceList="irqbalance kdump udev-post rsyslog"
osrelease=`cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' |awk -F'.' '{print $1}'`
for s in ${StartServerList}
do
  if [ $osrelease == 6 ];then
    chkconfig --level 3 ${s} on > /dev/null 2>&1
  else
    systemctl enable ${s} > /dev/null 2>&1
  fi
done

#2.2关闭不重要的服务
StopServiceList="abrt-ccpp abrtd acpid agentwatch atd auditd blk-availability cpuspeed haldaemon \
iptables ip6tables firewalld lvm2-monitor mdmonitor messagebus netfs nscd ntpd ntpdate postfix \
psacct quota_nld rdisc restorecond rngd saslauthd smartd snmptrapd svnserve NetworkManager telnet \
vsftpd wu-ftpd sendmail tftp"
osrelease=`cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' |awk -F'.' '{print $1}'`
for s in ${StopServerList}
do
if [ $osrelease == 6 ];then    
    chkconfig --level 3 ${s} off > /dev/null 2>&1
else
    systemctl disable ${s} > /dev/null 2>&1
done

#2.3清除防火墙规则
iptables -F
ip6tables -F

#2.4设置登陆警告信息MOTD
cat > /etc/motd <<EOF
**************************************************************************
*                                                                        *
*   Attention: Auditing process will report your every action!           *
*   Warning: Don't delete any files in directory /root/slogs!!           *
*                                                                        *
*                             --Shanghai Gaojing Culture Media Co.,Ltd.  *
**************************************************************************
EOF

#2.5关闭selinux(需要重启服务器生效)
setenforce 0 2> /dev/null
sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
#sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config

#2.6配置系统语言
sed -i 's@LANG=.*$@LANG=en_US.UTF-8@g' /etc/locale.conf
echo 'SYSFONT=latarcyrheb-sun16' >> /etc/locale.conf

#2.7关闭ctrl+alt+del
sed -i "s/ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/#ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/" /etc/inittab
sed -i 's/^id:5:initdefault:/id:3:initdefault:/' /etc/inittab

#2.8配置profile
cat > /etc/profile.d/oneinstack.sh << EOF
HISTSIZE=10000
PS1="\[\e[37;40m\][\[\e[32;40m\]\u\[\e[37;40m\]@\h \[\e[35;40m\]\W\[\e[0m\]]\\\\$ "
HISTTIMEFORMAT="%F %T \$(whoami)"

alias l='ls -AFhlt'
alias lh='l | head'
alias vi=vim
alias cat='cat -n'
GREP_OPTIONS="--color=auto"
alias grep='grep --color'
alias egrep='egrep --color'
alias fgrep='fgrep --color'
EOF

#2.9登录超时设置
echo "TMOUT=1800" >> /etc/profile

#3.0解决每次登陆linux提示:you hava a new mail
echo "unset MAILCHECK" >> /etc/profile  

source /etc/profile

#3.1设置vim配置
grep "set nu" /etc/vimrc > /dev/null || echo "set nu" >> /etc/vimrc

#3.2
[ -z "$(grep ^'PROMPT_COMMAND=' /etc/bashrc)" ] && cat >> /etc/bashrc << EOF
PROMPT_COMMAND='{ msg=\$(history 1 | { read x y; echo \$y; });logger "[euid=\$(whoami)]":\$(who am i):[\`pwd\`]"\$msg"; }'
EOF

#3.3配置文件描述符
[ -e /etc/security/limits.d/*nproc.conf ] && rename nproc.conf nproc.conf_bk /etc/security/limits.d/*nproc.conf
[ -f /etc/security/limits.d/90-nproc.conf ] && sed -i 's/1024/65535/' /etc/security/limits.d/90-nproc.conf
sed -i '/^# End of file/,$d' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
# End of file
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF

#3.4配置host
[ "$(hostname -i | awk '{print $1}')" != "127.0.0.1" ] && sed -i "s@127.0.0.1.*localhost@&\n127.0.0.1 $(hostname)@g" /etc/hosts

#3.5设置时区
/usr/bin/timedatectl set-timezone Asia/Shanghai
##rm -rf /etc/localtime
##ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#3.6ip_conntrack table full dropping packets
[ ! -e "/etc/sysconfig/modules/iptables.modules" ] && { echo -e "modprobe nf_conntrack\nmodprobe nf_conntrack_ipv4" > /etc/sysconfig/modules/iptables.modules; chmod +x /etc/sysconfig/modules/iptables.modules; }
modprobe nf_conntrack
modprobe nf_conntrack_ipv4
echo options nf_conntrack hashsize=131072 > /etc/modprobe.d/nf_conntrack.conf

#3.7时间同步(待确认)
#ntpdate -s pool.ntp.org
#echo "*/30 * * * * $(which ntpdate) pool.ntp.org > /dev/null 2>&1 && hwclock -w" >>/var/spool/cron/root
#chmod 600 /var/spool/cron/root
#系统时钟同步到bios
#hwclock --systohc

#3.8开机启动时间同步服务(适用于腾讯云服务器)
systemctl enable ntpd

#3.9配置dmesg buffer大小
echo "dmesg -s 1048576" >> /etc/rc.d/rc.local

#文件权限
#4.0系统敏感文件权限设置
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 400 /etc/shadow
chmod 400 /etc/gshadow

#4.1系统敏感文件加锁
#for i in /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/services /etc/inittab /etc/rc.local
#do
#  chattr +i $i
#done

#4.2配置内核参数
[ ! -e "/etc/sysctl.conf_bk" ] && /bin/mv /etc/sysctl.conf{,_bk}
cat > /etc/sysctl.conf << EOF
#表示文件句柄的最大数量
fs.file-max = 102400
#使用sysrq组合键是了解系统目前运行情况，为安全起见设为0关闭
kernel.sysrq = 0
#控制core文件的文件名是否添加pid作为扩展
kernel.core_uses_pid = 1
#修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536
#设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
#默认128,最大限制65535,用于设置系统同时发起的TCP连接数,数值较小时,无法应付高并发情形，导致连接超时、重传等问题
net.core.somaxconn = 65535
#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 262144
#未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
#timewait的数量，默认是180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
# 增加TCP最大缓冲区大小
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 60
#内核放弃建立连接之前发送SYNACK/SYN包的数量
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_reuse = 0
#关闭路由转发
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
#开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1
# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1
# 开启SYN泛洪攻击保护
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
#限制仅仅是为了防止简单的DoS攻击
net.ipv4.tcp_max_orphans = 3276800
#允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024 65000
#修改防火墙表大小
net.nf_conntrack_max = 6553500
net.netfilter.nf_conntrack_max = 6553500
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_established = 3600
vm.max_map_count = 262144
kernel.pid_max = 100000
vm.swappiness = 1
#关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
sysctl -p

#4.3安装方式写在镜像的/etc/rc.local文件,初始化成功后删除安装方式
sed -i '/init_centos.sh/d' /etc/rc.local
sed -i '/init_centos.sh/d' /etc/rc.d/rc.local

#4.4配置邮箱地址
cat >> /etc/mail.rc << EOF
set from=server_muchinfo@163.com
set smtp=smtp.163.com
set smtp-auth-user=server_muchinfo
set smtp-auth-password=9k71qc7m
set smtp-auth=login
EOF

echo -e "\033[1;32m 系统初始化完成,如有问题,请联系运维组\033[0m"
