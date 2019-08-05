#!/bin/bash
#统计TCP状态

netstat -n |awk '/^tcp/{++state[$NF]} END {for(key in state) print key,state[key]}'

ss -ant |awk 'NR>1 {++s[$1]} END {for(k in s) print k,s[k]}'
