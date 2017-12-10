#!/bin/bash
# 把运行结果保存到
# LOG_FILE=$(date +"%Y%m%d.txt")
# # exec 2>&1 >> /home/fl/myLog/$logFile
# exec 3>&1 1>>/home/fl/myLog/${LOG_FILE} 2>&1
echo -e "\n--------------------------------------------------------------------------------"
echo -e ">> $(date +'%Y-%m-%d %H:%M:%S') << FromAliAll.sh"
echo -e  "--------------------------------------------------------------------------------"

# rsync -vr -e 'sshpass -p "abc@123" ssh' fl@47.93.200.243:/home/fl/myVnpy/vn.data /data/ChinaFuturesTickData/FromAli

for colo in YunYang1 XiFu TianMi1 TianMi3;
do
    for info in ContractInfo TickData;
    do 
        tarFile=$(sshpass -p "******" ssh fl@47.93.200.243 "ls /home/fl/myVnpy/vn.data/$colo/$info/ | grep '.tar.bz2'")
        tradingDay=${tarFile/.csv/''}
        for dataFile in $tarFile
        do
        echo -e "\n$colo :==> $info :==> $dataFile"
        rsync -vr -e 'sshpass -p "******" ssh' fl@47.93.200.243:/home/fl/myVnpy/vn.data/$colo/$info/$dataFile /data/ChinaFuturesTickData/FromAli/vn.data/$colo/$info/
        done
    done
done
