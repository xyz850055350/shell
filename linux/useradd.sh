devkey="ssh-rsa <公钥>"
yunweikey="ssh-rsa <公钥>"

CrePubKey(){
  useradd $1
  HOME=/home/$1
  IDCMD=id; [ -x /usr/xpg4/bin/id ] && IDCMD=/usr/xpg4/bin/id
  if [ `$IDCMD -un` = "root" ];then
    if [ -f $HOME/.ssh/authorized_keys ];then
      echo  $2 >> $HOME/.ssh/authorized_keys
    else
      mkdir -p $HOME/.ssh chmod 700 $HOME/.ssh
      echo $2 >> $HOME/.ssh/authorized_keys
      chmod 600 $HOME/.ssh/authorized_keys
      chown ${1}:${1} -R $HOME/.ssh 
    fi
  else 
    echo "Error: must be run by root" 
  fi
}
CreSu(){
  echo "start cresu"
  grep "$1" /etc/sudoers |grep "su"  > /dev/null
  if [ "$?" != 0 ];then 
    echo "$1 ALL=(ALL) NOPASSWD: /usr/bin/su"  >> /etc/sudoers
  else
    echo "$1 已有su权限"
  fi
}

CrePubKey  yunwei "$yunweikey"
CrePubKey  dev    "$devkey"

CreSu  yunwei
