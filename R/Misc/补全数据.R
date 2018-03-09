rm(list = ls())
logMainScript <- c("CiticPublic2mysql_00_main.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(fst)

################################################################################
tradingDay <- '20171026'
################################################################################



################################################################################
## FromHF
################################################################################
mysql <- mysqlFetch('china_futures_bar')
dbSendQuery(mysql, paste('delete from daily where tradingday = ',tradingDay))
dbSendQuery(mysql, paste('delete from minute where tradingday = ',tradingDay))

tempTradingDay <- as.Date(tradingDay, '%Y%m%d') %>% as.character()

daily <- fread(paste0('/data/FromHF/daily/', tempTradingDay,'.csv'), drop = 1)
dbWriteTable(mysql, 'daily',
             daily, row.name=FALSE, append=T)

minute <- fread(paste0('/data/FromHF/minute/', tempTradingDay,'.csv'), drop = 1)
dbWriteTable(mysql, 'minute',
             minute, row.name=FALSE, append=T)

source('/home/fl/myData/R/Rconfig/MainContract_00_main.R')
