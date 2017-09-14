################################################################################
##! from_vnpy.R
## 这是主函数:
## 从 MySQL 数据库提取需要的数据
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-09-10
################################################################################

## /usr/bin/Rscript /home/fl/myData/R/FetchMysQL/from_vnpy.R "XiFu_From135"

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


args <- commandArgs(trailingOnly = TRUE)
# coloSource <- 'XiFu_From135'
coloSource <- args[1]
## =============================================================================
## 参数设置

## 是否要包含历史的数据
## 如果想要包含所有的历史数据，请把 include_history 设置为 TRUE
includeHistory <- FALSE


ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv")

## 计算交易日历
if (as.numeric(format(Sys.time(),'%H')) < 20) {
    currTradingDay <- ChinaFuturesCalendar[days <= format(Sys.Date(),'%Y%m%d')][.N]
} else {
    currTradingDay <- ChinaFuturesCalendar[nights <= format(Sys.Date(),'%Y%m%d')][.N]
}
lastTradingday <- ChinaFuturesCalendar[days < currTradingDay[.N, days]][.N]
## =============================================================================


## =============================================================================
mysql <- mysqlFetch('vnpy', host = '192.168.1.166')

if (includeHistory) {
    dtDaily <- dbGetQuery(mysql, paste0(
            "select * from daily_", coloSource
        )) %>% as.data.table() %>% 
        .[order(TradingDay)]
        
    dtMinute <-  dbGetQuery(mysql, paste0(
            "select * from minute_", coloSource
        )) %>% as.data.table() %>% 
        .[order(TradingDay)]

    dtDaily_options <- dbGetQuery(mysql, paste0(
            "select * from daily_", coloSource, "_options"
        )) %>% as.data.table() %>% 
        .[order(TradingDay)]
        
    dtMinute_options <-  dbGetQuery(mysql, paste0(
            "select * from minute_", coloSource, "_options"
        )) %>% as.data.table() %>% 
        .[order(TradingDay)]

} else {
    dtDaily <- dbGetQuery(mysql, paste0(
            "select * from daily_", coloSource,
            " where TradingDay = ", currTradingDay[,days]
        )) %>% as.data.table()
        
    dtMinute <-  dbGetQuery(mysql, paste0(
            "select * from minute_", coloSource,
            " where TradingDay = ", currTradingDay[,days]
        )) %>% as.data.table()

    dtDaily_options <- dbGetQuery(mysql, paste0(
            "select * from daily_", coloSource, "_options", 
            " where TradingDay = ", currTradingDay[,days]
        )) %>% as.data.table()
        
    dtMinute_options <-  dbGetQuery(mysql, paste0(
            "select * from minute_", coloSource, "_options" ,
            " where TradingDay = ", currTradingDay[,days]
        )) %>% as.data.table()

}
## =============================================================================


## =============================================================================
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')

## -----------------------------------------------------------------------------
dbSendQuery(mysql, paste0(
  "delete from daily 
  where TradingDay = ", currTradingDay[,days]
  ))
dbSendQuery(mysql, paste0(
  "delete from minute 
  where TradingDay = ", currTradingDay[,days]
  ))

dbWriteTable(mysql, "daily",
             dtDaily, row.name = FALSE, append = T)

dbWriteTable(mysql, "minute",
             dtMinute, row.name = FALSE, append = T)

## -----------------------------------------------------------------------------
dbSendQuery(mysql, paste0(
  "delete from daily_options
  where TradingDay = ", currTradingDay[,days]
  ))
dbSendQuery(mysql, paste0(
  "delete from minute_options
  where TradingDay = ", currTradingDay[,days]
  ))

dbWriteTable(mysql, "daily_options",
             dtDaily_options, row.name = FALSE, append = T)

dbWriteTable(mysql, "minute_options",
             dtMinute_options, row.name = FALSE, append = T)
## =============================================================================

################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
################################################################################
