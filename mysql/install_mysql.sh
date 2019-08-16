#!/bin/bash

#把安装包与sh文件放到同一个目录下

curr_dir=$(pwd)
mysql_dir="/usr/local/mysql"       ##mysql的安装生成文件目录
mysql_data_dir="/data/mysql/data"  ##mysql数据存放目录
mysql_log_dir="/data/mysql/log"    ##mysql日志存放目录
mysql_tmp_dir="/data/mysql/tmp"    ##mysql临时文件存放目录
mysql_tar="mysql-5.7.21-linux-glibc2.12-x86_64.tar.gz"
mysql_error_log_name="error.log"
mysqlrootpwd="123456"              ##mysql的root用户初始密码
server_id=33062
innodb_buffer_pool=6G
repl_net="10.10.10.%"              ##授权网段				

user=`who am i |awk '{print $1}'`
if [ $user != root ];then
    echo "please run this scripts with root"
    exit 1
fi

cat /proc/mounts |grep "/data" 2>&1 >/dev/null

if [ ! $? -eq 0 ];then
    echo "mysql can not install in /,please use a new filesystem,exit"
    exit 1
fi

ps -ef |grep mysqld |grep -v grep 2>&1 >/dev/null

if [ $? -eq 0 ];then
    echo "mysql all already install,exit"
    exit 1
fi

egrep "^mysql" /etc/group 2>&1 >/dev/null
if [ $? -ne 0 ];then
    groupadd -g 503 mysql
fi

egrep "^mysql" /etc/passwd 2>&1 >/dev/null
if [ $? -ne 0 ];then
    useradd -u 503 -g mysql -m -d /home/mysql mysql 2>&1 >/dev/null && echo "ky123456" | passwd --stdin mysql 2>&1 >/dev/null
fi

#grep "${mysql_dir}/bin" /home/mysql/.bash_profile 2>&1 >/dev/null || sed -i '/^PATH/s#$#:'"$mysql_dir"'/bin#g' /home/mysql/.bash_profile

#source /home/mysql/.bash_profile

#install depend package
yum -y install numactl

#yum -y install https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.11/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.11-1.el7.x86_64.rpm

cat >> /etc/profile <<EOF
export PATH=\$PATH:${mysql_dir}/bin
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${mysql_dir}/lib
EOF

source /etc/profile

[ -d ${mysql_dir} ] || mkdir -p $mysql_dir
[ -d ${mysql_data_dir} ] || mkdir -p ${mysql_data_dir}
[ -d ${mysql_log_dir} ] || mkdir -p ${mysql_log_dir}
[ -d ${mysql_tmp_dir} ] || mkdir -p ${mysql_tmp_dir}

if [ -s /etc/my.cnf ]; then
    mv /etc/my.cnf /etc/my.cnf.`date +%Y%m%d%H%M%S`.bak
fi

if [ -s /etc/init.d/mysqld ]; then
	mv /etc/init.d/mysqld /etc/init.d/mysqld.`date +%Y%m%d%H%M%S`.bak
fi

cat >>/etc/my.cnf<<EOF
[client]
port=3306
socket=${mysql_data_dir}/mysql.sock
default-character-set=utf8
 
[mysql]
no-auto-rehash
default-character-set=utf8
 
[mysqld]
bind-addres=0.0.0.0
port=3306
character-set-server=utf8
socket=${mysql_data_dir}/mysql.sock
basedir=${mysql_dir}
datadir=${mysql_data_dir}
explicit_defaults_for_timestamp=true
lower_case_table_names=1
back_log=1000
max_connections=10000
max_connect_errors=100000
table_open_cache=1024
external-locking=FALSE
max_allowed_packet=32M
sort_buffer_size=2M
join_buffer_size=2M
thread_cache_size=51
query_cache_size=0
query_cache_limit=0
transaction_isolation=REPEATABLE-READ
tmp_table_size=96M
max_heap_table_size=96M
 
###***slowqueryparameters
long_query_time=1
slow_query_log = 1
slow_query_log_file=${mysql_log_dir}/slow.log
 
###***binlogparameters
log-bin=mysql-bin
binlog_cache_size=4M
max_binlog_cache_size=4096M
max_binlog_size=1024M
binlog_format=row
expire_logs_days=14
sync_binlog=1
 
###***relay-logparameters
#relay-log=/data/3307/relay-bin
#relay-log-info-file=/data/3307/relay-log.info
#master-info-repository=table
#relay-log-info-repository=table
#relay-log-recovery=1
 
#***MyISAMparameters
key_buffer_size=16M
read_buffer_size=1M
read_rnd_buffer_size=16M
bulk_insert_buffer_size=1M
 
skip-name-resolve
 
###***master-slavereplicationparameters
server-id=${server_id}
#slave-skip-errors=all
 
#***Innodbstorageengineparameters
innodb_buffer_pool_size=${innodb_buffer_pool}
innodb_data_file_path=ibdata1:1024M:autoextend
#innodb_file_io_threads=8
innodb_thread_concurrency=16
innodb_flush_log_at_trx_commit=1
innodb_log_buffer_size=16M
innodb_log_file_size=1024M
innodb_log_files_in_group=3
innodb_max_dirty_pages_pct=75
innodb_buffer_pool_dump_pct=50
innodb_lock_wait_timeout=50
innodb_file_per_table=on

##################Replication#####################
gtid_mode = on
enforce_gtid_consistency = 1
binlog_gtid_simple_recovery = 1
master_info_repository = TABLE
relay_log_info_repository = TABLE
relay_log = relay.log		#路径与文件名
max_relay_log_size = 1024M	#默认就是1G	可不设置
sync_relay_log = 0		#默认值为0	可不设置
sync_relay_log_info = 0	#默认值为0	可不设置
relay_log_recovery = 1
relay-log-purge = 1
log_slave_updates = 1
binlog-checksum = CRC32
master-verify-checksum = 0
slave-sql-verify-checksum = 0
#slave_skip_errors = ddl_exist_errors
skip_slave_start = 1
 
[mysqldump]
quick
max_allowed_packet=32M
 
[myisamchk]
key_buffer=16M
sort_buffer_size=16M
read_buffer=8M
write_buffer=8M
 
[mysqld_safe]
open-files-limit=8192
log-error=${mysql_log_dir}/${mysql_error_log_name}
pid-file=${mysql_data_dir}/mysqld.pid

EOF

cat >>/etc/security/limits.conf<<EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF

#[ -f /etc/my.cnf ] && mv /etc/my.cnf /etc/my.cnf_bak
#wget http://$yum/scripts/my.cnf -O /etc/my.cnf
#wget http://$yum/tools/dba/$mysql_tar -P /data

tar -zxvf /${curr_dir}/$mysql_tar -C ${mysql_dir} --strip-components 1

chown -R mysql:mysql ${mysql_dir}
chown -R mysql:mysql ${mysql_data_dir}
chown -R mysql:mysql ${mysql_log_dir}
chown -R mysql:mysql ${mysql_tmp_dir}

su - mysql -c "${mysql_dir}/bin/mysqld --defaults-file=/etc/my.cnf --user=mysql --datadir=${mysql_data_dir} --basedir=${mysql_dir} --initialize-insecure"

if [ $? -eq 0 ];then
    echo "mysql install sucess"
else
    echo "mysql install fail,exit"
    exit 1
fi

cp ${mysql_dir}/support-files/mysql.server /etc/init.d/mysqld

chmod +x /etc/init.d/mysqld

su - mysql -c "service mysqld start >& /dev/null"

if [ $? -eq 0 ];then
    echo "start mysql sucess"
else
    echo "start mysql fail"
	exit 1
fi

${mysql_dir}/bin/mysqladmin -u root password $mysqlrootpwd

cat > /tmp/mysql_sec_script<<EOF
use mysql;
delete from mysql.user where user!='root' or host!='localhost';
flush privileges;
EOF

${mysql_dir}/bin/mysql -u root -p$mysqlrootpwd -h localhost < /tmp/mysql_sec_script
 
rm -f /tmp/mysql_sec_script
