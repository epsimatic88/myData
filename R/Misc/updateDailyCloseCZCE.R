################################################################################
##! updateDailyCloseCZCE.R
##
##  主要功能
##  用于更新郑商所在 2017-01 之后出现的 ClosePrice 出现的错误
## 
## 焕耿今天(2017-07-11)发现，对于郑商所的合约，从2017年1月开始，\red{ClosePrice} 出现错误。这个是由于郑商所把当天的夜盘最后一天价格，当作了当天的 \red{ClosePrice}，所以原来的算法使用的收盘价实际上只是夜盘的收盘价，而不是全天的收盘价。需要在算法上做改进，针对郑商所的合约，当天的 \red{ClosePrice} 要使用最后一天 Tick 的 \red{LastPrice}
## 
## 因此，这个脚本用于针对郑商所的合约，重新修改 ClosePrice, 将其替换为分钟数据的，最后一分钟的 ClosePrice
##  
## Author: fl@hicloud-investment.com
## CreateDate: 2017-07-11
## 
##
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("updateDailyCloseCZCE.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  #source('./R/Rconfig/myFread.R')
  #source('./R/Rconfig/myDay.R')
  #source('./R/Rconfig/myBreakTime.R')
  #source('./R/Rconfig/dt2DailyBar.R')
  #source('./R/Rconfig/dt2MinuteBar.R')
})
################################################################################


################################################################################
mysql <- mysqlFetch('china_futures_bar')
dtMinute <- dbGetQuery(mysql,"
            SELECT TradingDay, InstrumentID, Minute, NumericExchTime,
                   ClosePrice as mClosePrice
            FROM minute
            WHERE TradingDay >= 20170101
") %>% as.data.table() %>% 
    .[, .SD[order(NumericExchTime)], by = c('TradingDay', 'InstrumentID')]

## 取当前最后一分钟的价格数据
dtMinuteLast <- dtMinute[,.SD[.N,], by = c('TradingDay', 'InstrumentID')]
################################################################################


################################################################################
dtDaily <- dbGetQuery(mysql, "
            SELECT * 
            FROM daily
            WHERE TradingDay >= 20170101
") %>% as.data.table()
################################################################################


################################################################################
## 全天的 daily 数据
################################################################################
dtAllDay <- dtDaily[Sector == 'allday'] %>% 
    merge(., dtMinuteLast, by = c('TradingDay','InstrumentID')) %>% 
    .[nchar(gsub('[a-zA-Z]','',InstrumentID)) == 3, ClosePrice := mClosePrice]

## 检测数据情况
dtAllDay[, err := ClosePrice - mClosePrice]
dtAllDay[abs(err) > 5]

dtAllDay[, errPct := err/ClosePrice]
dtAllDay[abs(errPct) > 0.01]

## 去掉这些字段
dtAllDay[,c('Minute','NumericExchTime','mClosePrice','err','errPct') := NULL]
## =============================================================================
## 开始更新
## 1.先把原来的数据剔除
## 2.然后以 append 的格式添加进去
mysql <- mysqlFetch('china_futures_bar')
dbSendQuery(mysql, "
            DELETE FROM daily 
            WHERE Sector = 'allday'
            AND TradingDay >= 20170101
")
dbWriteTable(mysql, 'daily', dtAllDay, row.name　=　FALSE, append = TRUE)
## =============================================================================


################################################################################
## 日盘的数据
################################################################################
dtDay <- dtDaily[Sector == 'day'] %>% 
    merge(., dtMinuteLast, by = c('TradingDay','InstrumentID')) %>% 
    .[nchar(gsub('[a-zA-Z]','',InstrumentID)) == 3, ClosePrice := mClosePrice]

dtDay[, err := ClosePrice - mClosePrice]
dtDay[abs(err) > 5]

dtDay[, errPct := err/ClosePrice]
dtDay[abs(errPct) > 0.01]

dtDay[,c('Minute','NumericExchTime','mClosePrice','err','errPct') := NULL]
## =============================================================================
mysql <- mysqlFetch('china_futures_bar')
dbSendQuery(mysql, "
            DELETE FROM daily 
            WHERE Sector = 'day'
            AND TradingDay >= 20170101
")
dbWriteTable(mysql, 'daily', dtDay, row.name　=　FALSE, append = TRUE)
## =============================================================================
