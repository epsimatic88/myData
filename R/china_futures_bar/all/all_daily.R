################################################################################
## FromDC_vs_Exchange.R
## 这是主函数:
## 从数据库提取所以的历史数据
##
## 注意:
## Exchange: 2009-01-01 ~ 2010-04-15
## FromDC  : 2010-04-16 ~ 2016-10-25
## Citic   : 2016-10-26 ~ 2017-08-21  
## vnpy    : 2017-08-22 ~ Now
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-12-01
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("all_daily.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
options(width = 130)
################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days")))

dataPath <- './data/Bar/Daily'

## =============================================================================
## 保存数据
saveDaily <- function(dt) {
    setkey(dt, 'TradingDay')
    sapply(1:nrow(calendar), function(i) {
        tempYear <- calendar[i, substr(days,1,4)]
        tempTradingDay <- calendar[i, days]
        tempDir <- paste0(dataPath, '/', tempYear)
        tempFile <- paste0(tempDir, '/', tempTradingDay, '.csv')
        if (!dir.exists(tempDir)) dir.create(tempDir, recursive = TRUE)
        tempData <- dt[tempTradingDay]
        fwrite(tempData, tempFile)
    })
}
## =============================================================================

## =============================================================================
## dtBar
mysql <- mysqlFetch('Exchange')
startDay <- 20090101
endDay   <- 20100415
calendar <- ChinaFuturesCalendar[days %between% c(startDay, endDay)]
dt <- dbGetQuery(mysql, paste("
    select * from daily
    where TradingDay between", startDay, "and", endDay
  )) %>% as.data.table() %>% 
  .[, ":="(
    TradingDay = gsub('-','',TradingDay),
    Sector = 'allday',
    ExchangeID = NULL
    )]
setcolorder(dt,c("TradingDay","Sector",colnames(dt)[2:(ncol(dt)-1)]))
saveDaily(dt)

## =============================================================================
## dtBar
mysql <- mysqlFetch('FromDC')
startDay <- 20100416
endDay   <- 20161025
calendar <- ChinaFuturesCalendar[days %between% c(startDay, endDay)]
dt <- dbGetQuery(mysql, paste("
    select * from daily
    where TradingDay between", startDay, "and", endDay, 
    "and Sector = 'allday'"
  )) %>% as.data.table() %>% 
  .[, ":="(
    TradingDay = gsub('-','',TradingDay)
    )]
saveDaily(dt)

## =============================================================================
## dtBar
mysql <- mysqlFetch('CiticPublic')
startDay <- 20161026
endDay   <- 20170821
calendar <- ChinaFuturesCalendar[days %between% c(startDay, endDay)]
dt <- dbGetQuery(mysql, paste("
    select * from daily
    where TradingDay between", startDay, "and", endDay, 
    "and Sector = 'allday'"
  )) %>% as.data.table() %>% 
  .[, ":="(
    TradingDay = gsub('-','',TradingDay)
    )]
saveDaily(dt)

## =============================================================================
## dtBar
mysql <- mysqlFetch('vnpy')
startDay <- 20161026
endDay   <- 20170821
calendar <- ChinaFuturesCalendar[days %between% c(startDay, endDay)]
dt <- dbGetQuery(mysql, paste("
    select * from daily
    where TradingDay between", startDay, "and", endDay, 
    "and Sector = 'allday'"
  )) %>% as.data.table() %>% 
  .[, ":="(
    TradingDay = gsub('-','',TradingDay)
    )]
saveDaily(dt)
