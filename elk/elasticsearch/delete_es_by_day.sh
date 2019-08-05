#!/bin/bash
###***es定期清理数据脚本***###
DATE=`date +%Y.%m.%d.%I`
DATA0=`date +%Y.%m.%d -d'-3 day'`
DATA1=`date +%Y.%m.%d -d'-7 day'`
DATA2=`date +%Y.%m.%d -d'-15 day'`
DATA3=`date +%Y.%m.%d -d'-30 day'`

index0_list='.monitoring-es-6 .monitoring-kibana-6 .monitoring-logstash-6 .reporting .watcher-history-7 elasticsearch_metrics'
index1_list='call'
index2_list='iis'

#删除3天前的数据
for index0 in ${index0_list}
do
  curl -XDELETE -u elastic:elastic "http://10.10.10.10:9200/${index0}*${DATA0}*"
done

#删除7天前的数据
for index1 in ${index1_list}
do
  curl -XDELETE -u elastic:elastic "http://10.10.10.10:9200/${index1}*${DATA1}*"
done

#删除15天前的数据
for index1 in ${index2_list}
do
  curl -XDELETE -u elastic:elastic "http://10.10.10.10:9200/${index1}*${DATA2}"
done

#删除30天前的所有数据
curl -XDELETE -u elastic:elastic "http://10.10.10.10:9200/*${DATA3}"
