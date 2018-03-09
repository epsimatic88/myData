################################################################################
##! save_bar.R
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
logMainScript <- c("save_bar.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

library(fst)

## =============================================================================
## ChinaFuturesCalendar
## =============================================================================
mysql <- mysqlFetch('dev')
ChinaFuturesCalendar <- dbGetQuery(mysql, "
            SELECT * FROM ChinaFuturesCalendar"
            ) %>% as.data.table()

if (as.numeric(format(Sys.time(),'%H')) < 21){
  currTradingDay <- ChinaFuturesCalendar[days == format(Sys.Date(),'%Y-%m-%d')]
}else{
  currTradingDay <- ChinaFuturesCalendar[nights == format(Sys.Date(),'%Y-%m-%d')]
}
lastTradingDay <- ChinaFuturesCalendar[days < currTradingDay[1,days]][.N]
tradingDay <- currTradingDay[, gsub('-','',days)]

## =============================================================================
## china_futures_bar
## =============================================================================
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')

## daily
dtDaily <- dbGetQuery(mysql, paste("
                   select * from daily
                   where tradingday = ", tradingDay)) %>% 
          as.data.table()   
fwrite(dtDaily, paste0('./data/Bar/daily/', tradingDay, '.csv'))

## minute
dtMinute <- dbGetQuery(mysql, paste("
                   select * from minute
                   where tradingday = ", tradingDay)) %>% 
          as.data.table()   
fwrite(dtMinute, paste0('./data/Bar/minute/', tradingDay, '.csv'))

## =============================================================================
fwrite(dtDaily, paste0('./data/Bar/tmp/daily_', tradingDay, '.csv'))
fwrite(dtMinute, paste0('./data/Bar/tmp/minute_', tradingDay, '.csv'))

setwd('./data/Bar/tmp')
cmd <- paste("tar zcvf", paste0(tradingDay,'.tar.gz'),
            paste0('daily_',tradingDay,'.csv'),
            paste0('minute_',tradingDay,'.csv')) 
system(cmd)
system("rm -rf *.csv")
setwd('../../../')
