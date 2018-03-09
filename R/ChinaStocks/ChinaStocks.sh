#!/bin/bash
# 处理 ChinaStocks 中国股票数据
LOG_FILE=$(date +"%Y%m%d_ChinaStocks.txt")
exec 3>&1 1>>/home/fl/myLog/${LOG_FILE} 2>&1
echo -e "\n--------------------------------------------------------------------------------"
echo -e ">> $(date +'%Y-%m-%d %H:%M:%S') << ChinaStocks.sh"
echo -e  "--------------------------------------------------------------------------------"


