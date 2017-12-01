################################################################################
## CiticiPublic_vs_Exchange.R
## 这是主函数:
## 对比 CiticPulic 日行情数据 与 china_futures_bar.daily 数据质量
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-11-31
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("CiticPublic_vs_Exchange.R")

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


## =============================================================================
## dtBar
mysql <- mysqlFetch('CiticPublic', host = '192.168.1.166')
dtCitic <- dbGetQuery(mysql,"
        select * from daily
        where Sector = 'allday'
        and Volume != 0
    ")  %>% as.data.table() %>%
    .[, .(TradingDay, InstrumentID,
          OpenPrice, HighPrice, LowPrice, ClosePrice,
          Volume, Turnover,
          CloseOpenInterest, SettlementPrice)]
## =============================================================================

## =============================================================================
## dtExchange
mysql <- mysqlFetch('Exchange', host = '192.168.1.166')
dtExchange <- dbGetQuery(mysql,"
        select * from daily
        where Volume != 0
    ")  %>% as.data.table() %>%
    .[, .(TradingDay, InstrumentID,
          OpenPrice, HighPrice, LowPrice, ClosePrice,
          Volume, Turnover,
          CloseOpenInterest, SettlementPrice)]
## =============================================================================




## =============================================================================
## dt
dt <- merge(dtCitic, dtExchange, by = c('TradingDay','InstrumentID'), all = TRUE) %>%
    .[TradingDay %between% c(max(dtCitic[,min(TradingDay)],dtExchange[,min(TradingDay)]),
                             min(dtCitic[,max(TradingDay)],dtExchange[,max(TradingDay)]))]

cols <- colnames(dt)[3:ncol(dt)]
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

## =============================================================================
dt[errOpen != 0][OpenPrice.y != 0]
dt[errHigh != 0][HighPrice.y != 0]
dt[errLow != 0][LowPrice.y != 0]


dt[errOpen != 0][OpenPrice.x != 0][OpenPrice.y != 0][!grep('IF|TF',InstrumentID)]
dt[errHigh != 0][HighPrice.x != 0][HighPrice.y != 0][!grep('IF|TF',InstrumentID)]
dt[errLow != 0][LowPrice.x != 0][LowPrice.y != 0][!grep('IF|TF',InstrumentID)]
dt[errClose != 0][ClosePrice.x != 0][ClosePrice.y != 0][!grep('IF|TF',InstrumentID)]

dt[errClose != 0 & ClosePrice.x != 0 & ClosePrice.y != 0, ":="(
  ClosePrice.x = ClosePrice.y
  )]

dt[errVolume != 0][Volume.x != 0]
## =============================================================================
