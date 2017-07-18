################################################################################
##! vnpyData2mysql_00_main.R
## 这是主函数:
## 用于录入 vnpyData 的数据到 MySQL 数据库
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-07-12
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("vnpyData2mysql_00_main.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  # source('./R/Rconfig/myFread.R')
  # source('./R/Rconfig/myDay.R')
  # source('./R/Rconfig/myBreakTime.R')
  # source('./R/Rconfig/dt2DailyBar.R')
  # source('./R/Rconfig/dt2MinuteBar.R')
})

dataPath <- "/shared/public/fl/Tick"

dtNight <- fread(paste(dataPath, "20170703.csv", sep = '/')) %>% 
            .[time %between% c('20:58:00', '23:59:59') | 
              time %between% c('00:00:00','02:32:00')]
dtDay <- fread(paste(dataPath, "20170704.csv", sep = '/')) %>% 
            .[time %between% c('08:58:00', '15:32:00')]





