################################################################################
##! from_bar.R
## 这是主函数:
## 从 MySQL 数据库提取需要的数据
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-09-10
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("from_bar.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  # source('./R/Rconfig/myFread.R')
  # source('./R/Rconfig/myDay.R')
  # source('./R/Rconfig/myBreakTime.R')
  # source('./R/Rconfig/dt2DailyBar.R')
  # source('./R/Rconfig/dt2MinuteBar.R')
})

library(fst)

## =============================================================================
## china_futures_bar
## =============================================================================
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')

## daily
dtDaily <- dbGetQuery(mysql,"
        select * 
        from daily 
        where sector = 'allday'
    ") %>% as.data.table()    
write.fst(dtDaily, './data/FromMySQL/china_futures_bar/daily.fst')

## minute
dtMinute <- dbGetQuery(mysql,"
        select * 
        from minute
    ") %>% as.data.table()    
write.fst(dtMinute, './data/FromMySQL/china_futures_bar/minute.fst')

## mainContracts
dtMain <- dbGetQuery(mysql,"
        select * 
        from main_contract_daily
    ") %>% as.data.table()    
write.fst(dtMain, './data/FromMySQL/china_futures_bar/main.fst')

## oi
dtOI <- dbGetQuery(mysql,"
        select * 
        from oiRank
    ") %>% as.data.table()    
write.fst(dtOI, './data/FromMySQL/china_futures_bar/OI.fst')


## multiplier
mysql <- mysqlFetch('china_futures_info', host = '192.168.1.166')
dtMultiplier <- dbGetQuery(mysql,"
        select * 
        from VolumeMultiple
    ") %>% as.data.table()    
write.fst(dtMultiplier, './data/FromMySQL/china_futures_bar/multiplier.fst')


## =============================================================================
## local
## =============================================================================
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.120')

## daily
dbSendQuery(mysql, "
        truncate table daily
    ")
dbWriteTable(mysql, 'daily',
    dtDaily, row.name = FALSE, append = TRUE)

## minute
dbSendQuery(mysql, "
        truncate table minute
    ")
dbWriteTable(mysql, 'minute',
    dtMinute, row.name = FALSE, append = TRUE)

## minute
dbSendQuery(mysql, "
        truncate table main
    ")
dbWriteTable(mysql, 'main',
    dtMain, row.name = FALSE, append = TRUE)

## OI
dbSendQuery(mysql, "
        truncate table oiRank
    ")
dbWriteTable(mysql, 'oiRank',
    dtOI, row.name = FALSE, append = TRUE)

## OI
dbSendQuery(mysql, "
        truncate table multiplier
    ")
dbWriteTable(mysql, 'multiplier',
    dtMultiplier, row.name = FALSE, append = TRUE)
