## =============================================================================
## CiticPublic2mysql_05_night_minute.R
##
## 用于处理夜盘的分钟数据
## =============================================================================


## =============================================================================
rm(list = ls())
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
  source('/home/fl/myData/R/Rconfig/myFread.R')
  source('/home/fl/myData/R/Rconfig/myDay.R')
  source('/home/fl/myData/R/Rconfig/myBreakTime.R')
  source('/home/fl/myData/R/Rconfig/dt2DailyBar.R')
  source('/home/fl/myData/R/Rconfig/dt2MinuteBar.R')
})
## =============================================================================


## =============================================================================
## GTJAPublic
## CiticPublic
setwd("/data/ChinaFuturesTickData/CiticPublic")
##
allDataFiles <- list.files(pattern = '\\.csv')
## =============================================================================


## =============================================================================
## STEP 1:
## -----------------------------------------------------------------------------
ChinaFuturesCalendar <- fread("/home/fl/myData/data/ChinaFuturesCalendar/ChinaFuturesCalendar_2011_2017.csv",
                              colClasses = list(character = c("nights","days"))) %>%
  .[days >= '20170101']

## -----------------------------------------------------------------------------
# nrow(futures_calendar)
if(as.numeric(format(Sys.time(),"%H")) > 6){
  stop("No Correct Time!!!")
}
## =============================================================================


## =============================================================================
logTradingDay <- ChinaFuturesCalendar[nights == format(Sys.Date()-1,"%Y%m%d"), days]
tempFile <- format(Sys.Date()-1,"%Y%m%d")

if(is.na(tempFile) | nchar(tempFile) == 0){
  stop("No night market!!!")
}
## =============================================================================


## =============================================================================
dataFile <- grep(tempFile,allDataFiles, value = TRUE)
logDataFile <- dataFile
info <- data.table()

myDay <- myDay[!trading_period %between% c("08:00:00", "16:00:00")]
myDayPlus <- myDayPlus[!trading_period %between% c("08:00:00", "16:00:00")]
## =============================================================================


## =============================================================================
dt <- dataFile %>% myFreadBar() %>%
  .[! substr(Timestamp,10,11) %between% c('08','15')] %>%
  .[UpdateTime %between% c("20:58:00","24:00:00") | UpdateTime %between% c("00:00:00","02:35:00")]

## -----------------------------------------------------------------------------
dt <- dt %>%
  .[nchar(InstrumentID) < 8] %>%
  .[UpperLimitPrice >= 0.0 & LowerLimitPrice >= 0.0] %>%
  .[Volume < 1000000000] %>%  ## 设定 volume 不超过 1,000,000,000，否则是系统的错误
  .[, ':='(TradingDay = as.character(logTradingDay))]

## -----------------------------------------------------------------------------
# 清除数据为 1.797693e+308 的交易所测试数据,
# 我的做法是将其转化为 NA.
cols <- colnames(dt)[6:ncol(dt)]
dt[, (cols) := lapply(.SD, function(x){
  y <- ifelse(x >= 1.797693e+308, NA, x)
  }), .SDcols = cols]
## =============================================================================


## =============================================================================
#-------------------------------------------------------------------------------
## 清除重复的数据行
the_duplicated_dt <- duplicated(dt[,.(TradingDay,UpdateTime, UpdateMillisec, InstrumentID
                                  ,LastPrice, Volume, Turnover
                                  ,OpenInterest, UpperLimitPrice, LowerLimitPrice
                                  ,BidPrice1, BidVolume1, BidPrice2, BidVolume2
                                  ,BidPrice3, BidVolume3, BidPrice4, BidVolume4
                                  ,BidPrice5, BidVolume5
                                  ,AskPrice1, AskVolume1,  AskPrice2, AskVolume2
                                  ,AskPrice3, AskVolume3,  AskPrice4, AskVolume4
                                  ,AskPrice5, AskVolume5)
                               ])
## =============================================================================

## =============================================================================
dt <- dt[!the_duplicated_dt] %>%
      .[UpdateTime %in% myDayPlus$trading_period | is.na(UpdateTime) ]
## =============================================================================

source('/home/fl/myData/R/china_futures_bar/CiticPublic/CiticPublic2mysql_02_manipulate_data.R')

################################################################################~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mysql <- mysqlFetch("china_futures_bar")
dbWriteTable(mysql,"minute",
             dtMinute, row.name = FALSE, append = T)
################################################################################~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
