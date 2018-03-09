################################################################################
## FromDC_vs_Exchange.R
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
logMainScript <- c("FromDC_vs_Exchange.R")

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
mysql <- mysqlFetch('FromDC', host = '192.168.1.166')
dtFromDC <- dbGetQuery(mysql,"
        select * from daily_bk
        where Sector = 'allday'
        and Volume != 0
    ")  %>% as.data.table() %>%
    .[, .(TradingDay, Sector, InstrumentID,
          OpenPrice, HighPrice, LowPrice, ClosePrice,
          Volume, Turnover,
          OpenOpenInterest, HighOpenInterest, LowOpenInterest, CloseOpenInterest,
          UpperLimitPrice, LowerLimitPrice, SettlementPrice)]
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
dt <- merge(dtFromDC, dtExchange, by = c('TradingDay','InstrumentID'), all = TRUE) %>%
    .[TradingDay %between% c(max(dtFromDC[,min(TradingDay)],dtExchange[,min(TradingDay)]),
                             min(dtFromDC[,max(TradingDay)],dtExchange[,max(TradingDay)]))]

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


## =============================================================================
## 更新 CZCE 的 Turnover 为按照 VolumeMultiple 计算的成交额
mysql <- mysqlFetch('vnpy', host = '192.168.1.166')
info <- dbGetQuery(mysql, "
  select * from info_TianMi1_FromAli
  where TradingDay = 20171206
  ") %>% as.data.table() %>% 
  .[, .(ProductID = gsub('[0-9]','',InstrumentID),
        ExchangeID)] %>% 
  .[nchar(ProductID) <= 2] %>% 
  .[!duplicated(ProductID, ExchangeID)]

mysql <- mysqlFetch('FromDC', host = '192.168.1.166')
vm <- dbGetQuery(mysql,"
  select TradingDay, InstrumentID, VolumeMultiple from info
  ") %>% as.data.table() %>% 
  .[, ProductID := gsub('[0-9]','',InstrumentID)] %>% 
  .[nchar(ProductID) <= 2] %>% 
  merge(., info, by = 'ProductID')


## =============================================================================
## dt
dt <- merge(dtFromDC, dtExchange, by = c('TradingDay','InstrumentID'), all = TRUE) %>%
    .[TradingDay %between% c(max(dtFromDC[,min(TradingDay)],dtExchange[,min(TradingDay)]),
                             min(dtFromDC[,max(TradingDay)],dtExchange[,max(TradingDay)]))]

cols <- colnames(dt)[3:ncol(dt)]
dt[, (cols) := lapply(.SD, function(x){
    ifelse(is.na(x), 0, x)
}), .SDcols = cols]
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
dt[errClose != 0 & ClosePrice.x != 0 & ClosePrice.y != 0, ":="(
  ClosePrice.x = ClosePrice.y
  )]
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
dt[errClose != 0][ClosePrice.x != 0][ClosePrice.y != 0][!grep('IF|TF',InstrumentID)]
## =============================================================================

dt <- merge(dtFromDC, dtExchange, by = c('TradingDay','InstrumentID'), all = TRUE) %>%
    .[TradingDay %between% c(max(dtFromDC[,min(TradingDay)],dtExchange[,min(TradingDay)]),
                             min(dtFromDC[,max(TradingDay)],dtExchange[,max(TradingDay)]))]

cols <- colnames(dt)[3:ncol(dt)]
dt[, (cols) := lapply(.SD, function(x){
    ifelse(is.na(x), 0, x)
}), .SDcols = cols]
dt[ClosePrice.x != ClosePrice.y & ClosePrice.x != 0 & ClosePrice.y != 0, ":="(
  ClosePrice.x = ClosePrice.y
  )]
dt[, ProductID := gsub('[0-9]','',InstrumentID)]
dtRes <- merge(dt, vm, by = c('TradingDay','InstrumentID','ProductID'), all.x = TRUE)
dtRes[ExchangeID == 'CZCE', Turnover.x := Turnover.x * VolumeMultiple]
dtRes[ExchangeID == 'CZCE'][abs(Turnover.x - Turnover.y)/Turnover.y > 0.05][Turnover.x != 0]

## 更新 Turnover
dtRes[ExchangeID == 'CZCE' & Turnover.x == 0 & Volume.x == Volume.y, Turnover.x := Turnover.y]
dtRes[ExchangeID == 'CZCE' & 
      (OpenPrice.x == OpenPrice.y & HighPrice.x == HighPrice.y & 
       LowPrice.x == LowPrice.y & ClosePrice.x == ClosePrice.y &
       ClosePrice.x != 0) &
     Turnover.x == 0 & Volume.x != Volume.y, ":="(
      Turnover.x = Turnover.y, Volume.x = Volume.y)]

dtRes[, ":="(
    errOpen = OpenPrice.x - OpenPrice.y,
    errHigh = HighPrice.x - HighPrice.y,
    errLow  = LowPrice.x - LowPrice.y,
    errClose = ClosePrice.x - ClosePrice.y,
    errVolume = Volume.x - Volume.y,
    errTurnover = Turnover.x - Turnover.y,
    errOI = CloseOpenInterest.x - CloseOpenInterest.y
)]

dtRes[errTurnover != 0][Turnover.x != 0][Turnover.y != 0][abs(Turnover.x - Turnover.y) / Turnover.y > 0.01]
dtRes[, ":="(vwap = Turnover.x / Volume.x / VolumeMultiple,
             vwap2 = Turnover.y / Volume.y / VolumeMultiple)]
dtRes[abs(vwap -vwap2)/vwap2 > 0.005][Turnover.x != 0][Volume.x > 1000]
## =============================================================================

mysql <- mysqlFetch('china_futures_bar')
dtMain <- dbGetQuery(mysql, "
  select TradingDay, Main_contract as InstrumentID 
  from main_contract_daily
  ") %>% as.data.table()
temp <- dtRes[abs(vwap -vwap2)/vwap2 > 0.005][Turnover.x != 0] %>% 
        merge(., dtMain, by = c('TradingDay','InstrumentID')) %>% 
        .[TradingDay %between% c('2011-01-05','2016-09-09')]
temp[errVolume == 0]
temp[errVolume != 0]
temp[errOpen != 0]
temp[errHigh != 0]
temp[errLow != 0]
temp[errClose != 0]

## =============================================================================
res <- dtRes[Sector == 'allday', .(TradingDay, Sector, InstrumentID,
                 OpenPrice = OpenPrice.x, 
                 HighPrice = HighPrice.x, 
                 LowPrice  = LowPrice.x, 
                 ClosePrice = ClosePrice.x,
                 Volume = Volume.x, 
                 Turnover = Turnover.x,
                 OpenOpenInterest, HighOpenInterest, LowOpenInterest, 
                 CloseOpenInterest = CloseOpenInterest.x,
                 UpperLimitPrice, LowerLimitPrice, 
                 SettlementPrice = SettlementPrice.x)]
mysql <- mysqlFetch('FromDC')
dbSendQuery(mysql, "delete from daily where Sector = 'allday'")
dbWriteTable(mysql, 'daily', res, row.name=F, append=T)
## =============================================================================
