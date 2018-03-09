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
logMainScript <- c("FromDC_vs_bar.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
options(width = 120)
################################################################################
## STEP 1: 获取对应的交易日期
################################################################################

## =============================================================================
## dtBar
mysql <- mysqlFetch('FromDC', host = '192.168.1.166')
dtFromDC <- dbGetQuery(mysql,"
                       select * from daily
                       where Sector = 'allday'
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
                         ")  %>% as.data.table() %>%
  .[, .(TradingDay, InstrumentID,
        OpenPrice, HighPrice, LowPrice, ClosePrice,
        Volume, Turnover,
        CloseOpenInterest, SettlementPrice)]
## =============================================================================




## =============================================================================
## dt
dt <- merge(dtFromDC, dtExchange, by = c('TradingDay','InstrumentID'),
            all = TRUE) %>%
  .[TradingDay %between% c(max(dtFromDC[,min(TradingDay)],dtExchange[,min(TradingDay)]),
                           min(dtFromDC[,max(TradingDay)],dtExchange[,max(TradingDay)]))]

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

## =============================================================================
dt[errOpen != 0][OpenPrice.y != 0]
dt[errHigh != 0][HighPrice.y != 0]
dt[errVolume != 0]

y <- dt[errLow != 0][LowPrice.y != 0] %>%
  .[!grep('WS|WT|RO|ER|TF|IF|^T[0-9]{4}',InstrumentID)]

# y <- dt[errClose != 0][ClosePrice.x != 0][ClosePrice.y != 0][!grep('IF|TF',InstrumentID)]
print(y)

yearIDs <- y[, unique(substr(TradingDay,1,4))]

dataPath <- '/data/ChinaFuturesTickData/TickData'
suppressMessages({
  source('./R/Rconfig/myInit.R')
  source('./R/Rconfig/myFread.R')
  source('./R/Rconfig/myDay.R')
  source('./R/Rconfig/myBreakTime.R')
  source('./R/Rconfig/dt2DailyBar.R')
  source('./R/Rconfig/dt2MinuteBar.R')
  source('./R/Rconfig/priceTick.R')
})


for (yearID in yearIDs) {
  ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv", 
                                showProgress = TRUE,
                                colClasses = list(character = c("nights","days"))
  ) %>%
    .[(which(substr(days, 1, 4) == yearID) %>% .[1]) :                   ## 第一个
        (which(substr(days, 1, 4) == yearID) %>% .[length(.)])] %>%      ## 最后一个
    .[, nights := paste0(nights, "_night")]


  if(as.numeric(yearID) == 2016){
    ## 2016年的截止到 20161103
    ChinaFuturesCalendar <- ChinaFuturesCalendar[1: which(days == 20161103)]
  }

  temp <- y[,.(TradingDay)][substr(TradingDay,1,4) == yearID][, TradingDay := gsub('-','',TradingDay)] %>%
    .[!duplicated(TradingDay)]
  ChinaFuturesCalendar <- merge(temp, ChinaFuturesCalendar, by.x = 'TradingDay', by.y = 'days') %>%
    .[,.(nights, days = TradingDay)] %>%
    .[!duplicated(days)]
  ################################################################################
  ## STEP 2:
  ################################################################################
  for (k in 1:nrow(ChinaFuturesCalendar)) {
    ## source('./R/Rconfig/myDay.R')
    print(paste0("#-----------------------------------------------------------------#"))
    ## ===========================================================================
    ## 开始时间标记
    beginTime <- Sys.time()

    ## 交易日期
    tradingDay <- ChinaFuturesCalendar[k, days]

    ## 夜盘数据
    if (grepl('[0-9]', ChinaFuturesCalendar[k, nights])) {
      dataNightPath <- ChinaFuturesCalendar[k, nights]
    } else {
      dataNightPath <- NA
    }

    ## 日盘数据
    dataDayPath <- ChinaFuturesCalendar[k, days]
    ## ===========================================================================

    ## ---------------------------------------------------------------------------
    print(
      paste(
        yearID, ":==> Trading Day :==>", tradingDay, "at", Sys.time()
      )
    )
    ## ---------------------------------------------------------------------------

    ## -------------------------------------------------------------------------
    source('./R/FromDC/FromDC2mysql_01_read_data.R')
    ## -------------------------------------------------------------------------

    ## =========================================================================
    if (nrow(dt) != 0) {
      ## -----------------------------------------------------------------------
      source('./R/FromDC/FromDC2mysql_02_manipulate_data.R')
      source('./R/FromDC/FromDC2mysql_03_transform_bar.R')
      source('./R/FromDC/FromDC2mysql_04_mysql_data.R')
      ## -----------------------------------------------------------------------
    } else {
      ## -----------------------------------------------------------------------
      source('./R/FromDC/FromDC2mysql_05_NA_data.R')
      ## -----------------------------------------------------------------------
    }
    ## =========================================================================
  }
  ##############################################################################
  print(paste0("# <", tradingDay, "> <--: at ", Sys.time()))
}




y <- dt[errOpen != 0][OpenPrice.y != 0] %>%
  .[!grep('WS|WT|RO|ER|TF|IF|^T[0-9]{4}',InstrumentID)]
print(y)


y <- dt[errClose != 0][ClosePrice.y != 0][Volume.y != 0] %>%
  .[!grep('WS|WT|RO|ER|TF|IF|^T[0-9]{4}',InstrumentID)]
print(y)













