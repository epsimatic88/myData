rm(list = ls())
logMainScript <- c("CiticPublic2mysql_00_main.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  source('./R/Rconfig/myFread.R')
  source('./R/Rconfig/myDay.R')
  source('./R/Rconfig/myBreakTime.R')
  source('./R/Rconfig/dt2DailyBar.R')
  source('./R/Rconfig/dt2MinuteBar.R')
})
library(fst)

mysql <- mysqlFetch('china_futures_bar')
dbListTables(mysql)
dbListFields(mysql,'daily')

dataPath <- './R/china_futures_bar/CiticPublic/data/20170726'
list.files(dataPath)


## =============================================================================
dt_night <- read.fst(paste0(dataPath, '/', '20170726_dt_night.fst'), as.data.table = T)
dt_night[, SettlementPrice := 0]
dbWriteTable(mysql, 'daily',
             dt_night, row.name=FALSE, append=T)

dt_day <- read.fst(paste0(dataPath, '/', '20170726_dt_day.fst'), as.data.table = T)
dt_day[, SettlementPrice := 0]
dbWriteTable(mysql, 'daily',
             dt_day, row.name=FALSE, append=T)

dt_allday <- read.fst(paste0(dataPath, '/', '20170726_dt_allday.fst'), as.data.table = T)
dt_allday[, SettlementPrice := 0]
dbWriteTable(mysql, 'daily',
             dt_allday, row.name=FALSE, append=T)

## =============================================================================
dbListFields(mysql, 'minute')
dtMinute <- read.fst(paste0(dataPath, '/', '20170726_dtMinute.fst'), as.data.table = T)
dtMinute[, SettlementPrice := 0]
dbWriteTable(mysql, 'minute',
             dtMinute, row.name=FALSE, append=T)

## =============================================================================
mysql <- mysqlFetch('china_futures_HFT')
dbListFields(mysql,'CiticPublic')
dbSendQuery(mysql,"delete from CiticPublic where tradingday = 20170726;")
dtTick <- read.fst(paste0(dataPath, '/', '20170726_dtTick.fst'), as.data.table = T)
str(dtTick)
dbWriteTable(mysql, 'CiticPublic',
             dtTick, row.name=FALSE, append=T)


