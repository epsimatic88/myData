#!/bin/bash
# 把运行结果保存到
# LOG_FILE=$(date +"%Y%m%d.txt")
# # exec 2>&1 >> /home/fl/myLog/$logFile
# exec 3>&1 1>>/home/fl/myLog/${LOG_FILE} 2>&1
echo -e "\n--------------------------------------------------------------------------------"
echo -e ">> $(date +'%Y-%m-%d %H:%M:%S') << FromAli.sh"
echo -e  "--------------------------------------------------------------------------------"

sshpass -p "******" ssh fl@47.93.200.243 "bash /home/fl/myShell/tar_FromAli.sh"

for colo in TianMi1 TianMi3 YunYang1 XiFu;
do
    for info in ContractInfo TickData;
    do 
        dataFile=$(sshpass -p "******" ssh fl@47.93.200.243 "ls /home/fl/myVnpy/vn.data/$colo/$info/ | grep 'csv' | tail -1")
        tradingDay=${dataFile/.csv/''}
        # ----------------------------------------------------------------------
        if [ "$info" = "TickData" ]
            then
            dataFile=$tradingDay.tar.bz2
        fi
        # ----------------------------------------------------------------------
        # dataFile=$tradingDay.tar.bz2
        echo -e "\n$colo :==> $info :==> $dataFile"
        rsync -vr -e 'sshpass -p "******" ssh' fl@47.93.200.243:/home/fl/myVnpy/vn.data/$colo/$info/$dataFile /data/ChinaFuturesTickData/FromAli/vn.data/$colo/$info/
        # ----------------------------------------------------------------------
        if [ "$colo" = "TianMi1" ] && [ "$info" = "TickData" ]  
            then
            /usr/bin/Rscript /home/fl/myData/R/vnpyData/vnpyData2mysql_00_main.R "/data/ChinaFuturesTickData/FromAli/vn.data/${colo}/TickData" "${colo}_FromAli"
        fi
        # ----------------------------------------------------------------------
        ## =========================================================================================
        # for i in {-1..2}
        # do
        # dataFile=$(date -d "-$i days" +"%Y%m%d.csv")
        # # if [ "$info" = "TickData" ] 
        # # then
        # #     dataFile=$(date -d "$i days" +"%Y%m%d.tar.bz2")
        # # else
        # #     dataFile=$(date -d "$i days" +"%Y%m%d.csv")
        # # fi
        # echo -e "\n$colo :==> $info :==> $dataFile"
        # rsync -vr -e 'sshpass -p "******" ssh' fl@47.93.200.243:/home/fl/myVnpy/vn.data/$colo/$info/$dataFile /data/ChinaFuturesTickData/FromAli/vn.data/$colo/$info/
        # done
        ## =========================================================================================
    done
done
