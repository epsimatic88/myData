#!/bin/bash
# 打包 FromDC 的数据文件
# 
LOG_FILE=tar_FromDC.txt
exec 3>&1 1>> /home/fl/myLog/${LOG_FILE} 2>&1

echo -e "\n==============================================================================="
echo -e ">> $(date +'%Y-%m-%d %H:%M:%S') << tar_FromDC.sh"
echo -e  "================================================================================"

cd /data/ChinaFuturesTickData/TickData

for i in {2010..2016}
do
echo -e  "--------------------------------------------------------------------------------"
echo `date`
echo $i
echo ">>"
XZ_OPT='-9e --threads=12' tar -Jcvf $i.tar.xz $i/
echo -e  "--------------------------------------------------------------------------------"
done
