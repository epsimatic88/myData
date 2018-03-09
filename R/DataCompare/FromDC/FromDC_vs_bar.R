################################################################################
## FromDC_vs_bar.R
## 这是主函数:
## 对比 FromDC 日行情数据 与 china_futures_bar.daily 数据质量
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-20
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("FromDC_vs_bar.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
options(width = 150)
################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days")))



## =============================================================================
## dtBar
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')
dtBar <- dbGetQuery(mysql,"
        select * from daily
        where Turnover != 0
    ")  %>% as.data.table() %>%
    .[, .(TradingDay, InstrumentID, Sector,
          OpenPrice, HighPrice, LowPrice, ClosePrice,
          Volume, Turnover,
          CloseOpenInterest, SettlementPrice)]
## =============================================================================


## =============================================================================
## dtBar
mysql <- mysqlFetch('FromDC', host = '192.168.1.166')
dtFromDC <- dbGetQuery(mysql,"
        select * from daily
        where Turnover != 0
    ")  %>% as.data.table() %>%
    .[, .(TradingDay, InstrumentID, Sector,
          OpenPrice, HighPrice, LowPrice, ClosePrice,
          Volume, Turnover,
          CloseOpenInterest, SettlementPrice)]
## =============================================================================

## =============================================================================
## dtExchange
mysql <- mysqlFetch('Exchange', host = '192.168.1.166')
dtExchange <- dbGetQuery(mysql,"
        select * from daily
        where Turnover != 0
    ")  %>% as.data.table() %>%
    .[, .(TradingDay, InstrumentID,
          OpenPrice, HighPrice, LowPrice, ClosePrice,
          Volume, Turnover,
          CloseOpenInterest, SettlementPrice)]
## =============================================================================




## =============================================================================
## dt
dt <- merge(dtBar, dtFromDC, by = c('TradingDay','InstrumentID','Sector'))

cols <- colnames(dt)[4:ncol(dt)]
dt[, (cols) := lapply(.SD, function(x){
    ifelse(is.na(x), 0, x)
}), .SDcols = cols]
## =============================================================================

dt[, ":="(
    errOpen = OpenPrice.x - OpenPrice.y,
    errHigh = HighPrice.x - HighPrice.y,
    errLow  = LowPrice.x - LowPrice.y,
    errClose = ClosePrice.x - ClosePrice.y,
    errVolume = Volume.x - Volume.y,
    errTurnover = Turnover.x - Turnover.y,
    errOI = CloseOpenInterest.x - CloseOpenInterest.y,
    errStl = SettlementPrice.x - SettlementPrice.y
)]

dt[errOpen != 0]

## =============================================================================
temp <- dt[errOpen != 0][Sector == 'allday']
# print(temp)
tempX <- merge(temp, dtExchange, by = c('TradingDay', 'InstrumentID'))
tempX[OpenPrice.x != OpenPrice]
tempX[OpenPrice.y != OpenPrice]
## =============================================================================


## =============================================================================
temp <- dt[errHigh != 0][Sector == 'allday']
# print(temp)
tempX <- merge(temp, dtExchange, by = c('TradingDay', 'InstrumentID'))
tempX[HighPrice.x != HighPrice]
tempX[HighPrice.y != HighPrice]
## =============================================================================


## =============================================================================
temp <- dt[errLow != 0][Sector == 'allday']
# print(temp)
tempX <- merge(temp, dtExchange, by = c('TradingDay', 'InstrumentID'))
tempX[LowPrice.x != LowPrice]
tempX[LowPrice.y != LowPrice]
## =============================================================================

## =============================================================================
temp <- dt[errClose != 0][Sector == 'allday']
# print(temp)
tempX <- merge(temp, dtExchange, by = c('TradingDay', 'InstrumentID'))
tempX[ClosePrice.x != ClosePrice]
tempX[ClosePrice.y != ClosePrice]
## =============================================================================




## =============================================================================
temp <- dt[TradingDay %between% c('2010-01-01', '2010-12-31')]

temp[errOpen != 0][Volume.x > 10000]

temp[errClose != 0][Volume.x > 5000]

temp[abs(errTurnover / Turnover.x) > 0.1][Volume.x > 5000][!grep('[A-Z]{2}',InstrumentID)]
