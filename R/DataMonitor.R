#! /usr/bin/Rscript
## =============================================================================
## DataMonitor.R
## 数据监控与管理
##
## =============================================================================

rm(list = ls())
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

## =============================================================================
## ChinaFuturesCalendar
## =============================================================================
mysql <- mysqlFetch('dev')
ChinaFuturesCalendar <- dbGetQuery(mysql, "
            SELECT * FROM ChinaFuturesCalendar"
            ) %>% as.data.table()

if (as.numeric(format(Sys.time(),'%H')) < 17){
  currTradingDay <- ChinaFuturesCalendar[days == format(Sys.Date(),'%Y-%m-%d')]
}else{
  currTradingDay <- ChinaFuturesCalendar[nights == format(Sys.Date(),'%Y-%m-%d')]
}
lastTradingDay <- ChinaFuturesCalendar[days < currTradingDay[1,days]][.N]


sink(paste0("./log/dailyDataLog_", lastTradingDay[1,gsub('-','',days)], ".txt"), append = FALSE)
cat("## ================================================================= ##\n")
cat("## 启禀圣上，以下是今天的数据库情况汇报。请过目！\n")
cat("##                                                                     \n")
cat(paste0("## 当前时间：", Sys.time()), "\n")
cat("## ================================================================= ##\n\n")

cat("## ================================================================= ##\n")
cat(paste0("## 当前交易日期：", lastTradingDay[1,days]), "\n")
print(lastTradingDay)
cat("## ================================================================= ##\n\n")


## =============================================================================
## china_futures_HFT
## =============================================================================
mysql <- mysqlFetch('china_futures_HFT')
dtTick <- dbGetQuery(mysql,paste("
            SELECT TradingDay, count(*) as recordingNo
            FROM vnpy_XiFu
            WHERE TradingDay >= ", format(Sys.Date()-5,"%Y%m%d"),
            "GROUP BY TradingDay")
            ) %>% as.data.table()
cat("## ================================================================= ##\n")
cat("## china_futures_HFT.vnpy_XiFu\n")
cat('## \n')
## -----------------------------------------------------------------------------
## 1. 如果当前交易日不在数据
## 2. 或者当前数据缺失
if (! lastTradingDay[1,days] %in% dtTick[,TradingDay] |
  dtTick[.N, recordingNo < .90 * mean(recordingNo)]) {
  cat('## 当前交易日的数据未入库！！！\n')
  cat('## 请检查程序。\n')
  cat('## 程序脚本位于：==> 192.168.1.135:/home/fl/myData/R/vnpyData/ \n')
  cat("## ================================================================= ##\n\n")
}else{
  cat('## 当前交易日的数据已入库！！！\n')
  cat("## ================================================================= ##\n\n")
}


## =============================================================================
## china_futures_bar
## =============================================================================
mysql <- mysqlFetch('china_futures_bar')
dtDaily <- dbGetQuery(mysql,paste("
            SELECT TradingDay, count(*) as recordingNo
            FROM daily
            WHERE TradingDay >= ", format(Sys.Date()-30,"%Y%m%d"),
            "GROUP BY TradingDay")
            ) %>% as.data.table()

dtMinute <- dbGetQuery(mysql,paste("
            SELECT TradingDay, count(*) as recordingNo
            FROM minute
            WHERE TradingDay >= ", format(Sys.Date()-30,"%Y%m%d"),
            "GROUP BY TradingDay")
            ) %>% as.data.table()
cat("## ================================================================= ##\n")
cat("## china_futures_bar.daily \n")
cat("## china_futures_bar.minute \n")
cat('## \n')
## -----------------------------------------------------------------------------
## 1. 如果当前交易日不在数据
## 2. 或者当前数据缺失
if (! lastTradingDay[1,days] %in% dtDaily[,TradingDay] |
  dtDaily[.N, recordingNo < .90 * mean(recordingNo)] |
  ! lastTradingDay[1,days] %in% dtMinute[,TradingDay] |
  dtMinute[.N, recordingNo < .90 * mean(recordingNo)]) {
  cat('## 当前交易日的数据未入库！！！\n')
  cat('## 请检查程序。\n')
  cat('## 程序脚本位于：==> 192.168.1.135:/home/fl/myData/R/vnpyData/ \n')
  cat("## ================================================================= ##\n\n")
}else{
  cat('## 当前交易日的数据已入库！！！\n')
  cat("## ================================================================= ##\n\n")
}


## =============================================================================
## china_futures_bar
## =============================================================================
mysql <- mysqlFetch('china_futures_bar')
dtOiRank <- dbGetQuery(mysql,paste("
            SELECT TradingDay, count(*) as recordingNo
            FROM oiRank
            WHERE TradingDay >= ", format(Sys.Date()-30,"%Y%m%d"),
            "GROUP BY TradingDay")
            ) %>% as.data.table()
cat("## ================================================================= ##\n")
cat("## china_futures_bar.oiRank \n")
cat('## \n')
## -----------------------------------------------------------------------------
## 1. 如果当前交易日不在数据
## 2. 或者当前数据缺失
if (! lastTradingDay[1,days] %in% dtOiRank[,TradingDay] |
  dtOiRank[.N, recordingNo < .92 * mean(recordingNo)]) {
  cat('## 当前交易日的数据未入库！！！\n')
  cat('## 请检查程序。\n')
  cat('## 程序脚本位于：==> /home/fl/myCodes/ExchDataFetch/ \n')
  cat("## ================================================================= ##\n\n")
}else{
  cat('## 当前交易日的数据已入库！！！\n')
  cat("## ================================================================= ##\n\n")
}


## =============================================================================
## china_futures_info
## =============================================================================
mysql <- mysqlFetch('china_futures_info')
dtVolumeMultiple <- dbGetQuery(mysql, paste("
            SELECT TradingDay, count(*) as recordingNo
            FROM VolumeMultiple
            WHERE TradingDay >= ", format(Sys.Date()-30,"%Y%m%d"),
            "GROUP By  TradingDay")
            ) %>% as.data.table()
cat("## ================================================================= ##\n")
cat("## china_futures_info.VolumeMultiple \n")
cat('## \n')
if (! lastTradingDay[1,days] %in% dtVolumeMultiple[,TradingDay] |
  dtVolumeMultiple[.N, recordingNo < .90 * mean(recordingNo)]) {
  cat('## 当前交易日的数据未入库！！！\n')
  cat('## 请检查程序。\n')
  cat('## 程序脚本位于：==> /home/fl/William/Codes/china_futures_info \n')
  cat("## ================================================================= ##\n\n")
}else{
  cat('## 当前交易日的数据已入库！！！\n')
  cat("## ================================================================= ##\n\n")
}



## =============================================================================
## lhg_trade
## =============================================================================
mysql <- mysqlFetch('lhg_trade')
dtOpenInfo <- dbGetQuery(mysql,"
            SELECT *
            FROM fl_open_t
") %>% as.data.table()
cat("## ================================================================= ##\n")
cat("## lhg_trade.fl_open_t")
knitr::kable(dtOpenInfo)
cat('\n## \n')

if (! lastTradingDay[1,days] %in% dtOpenInfo[,TradingDay]) {
  cat('## 策略的信号数据未入库！！！\n')
  cat('## 请检查程序。\n')
  cat('## 程序脚本位于：==> Lin HuanGeng 策略信号 \n')
  cat("## ================================================================= ##\n\n")
}else{
  cat('## 策略的信号数据已入库！！！\n')
  cat("## ================================================================= ##\n\n")
}


dtOpenInfo2 <- dbGetQuery(mysql,"
            SELECT *
            FROM fl_open_t_2
") %>% as.data.table()
cat("## ================================================================= ##\n")
cat("## lhg_trade.fl_open_t_2")
knitr::kable(dtOpenInfo2)
cat('\n## \n')

if (! lastTradingDay[1,days] %in% dtOpenInfo2[,TradingDay]) {
  cat('## 策略的信号数据未入库！！！\n')
  cat('## 请检查程序。\n')
  cat('## 程序脚本位于：==> Lin HuanGeng 策略信号 \n')
  cat("## ================================================================= ##\n\n")
}else{
  cat('## 策略的信号数据已入库！！！\n')
  cat("## ================================================================= ##\n\n")
}
## =============================================================================
## HiCloud
## =============================================================================


