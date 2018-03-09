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
# ChinaFuturesCalendar <- dbGetQuery(mysql, "
#             SELECT * FROM ChinaFuturesCalendar"
#             ) %>% as.data.table()
#
# if (as.numeric(format(Sys.time(),'%H')) < 17){
#   currTradingDay <- ChinaFuturesCalendar[days <= format(Sys.Date(),'%Y-%m-%d')][.N]
# }else{
#   currTradingDay <- ChinaFuturesCalendar[days > format(Sys.Date(),'%Y-%m-%d')][1]
# }
# lastTradingDay <- ChinaFuturesCalendar[days < currTradingDay[1,days]][.N]


sink(paste0("./log/dailyDataLog/", lastTradingDay[1,gsub('-','',days)], ".txt"), append = FALSE)
cat("## ====================================== ##\n")
cat("## 启禀大王，以下是今天的数据库汇报。请过目！\n")
cat("##                                                                     \n")
cat(paste0("## 当前时间：", Sys.time()), "\n")
cat("## ====================================== ##\n\n")

cat("## ====================================== ##\n")
cat(paste0("## 当前交易日期：", lastTradingDay[1,days]), "\n")
print(lastTradingDay)
cat("## ====================================== ##\n\n")


## =============================================================================
## china_futures_HFT
## =============================================================================
# mysql <- mysqlFetch('vnpy')
# dtTick <- dbGetQuery(mysql,paste("
#             SELECT TradingDay, count(*) as recordingNo
#             FROM tick_XiFu_FromPC
#             WHERE TradingDay >= ", format(Sys.Date()-5,"%Y%m%d"),
#             "GROUP BY TradingDay")
#             ) %>% as.data.table()
# cat("## ====================================== ##\n")
# cat("## vnpy.tick_XiFu_FromPC\n")
# cat('## \n')
# ## -----------------------------------------------------------------------------
# ## 1. 如果当前交易日不在数据
# ## 2. 或者当前数据缺失
# if (! lastTradingDay[1,days] %in% dtTick[,TradingDay] |
#   dtTick[.N, recordingNo < .95 * mean(recordingNo)]) {
#   cat('## 当前交易日的数据未入库！！！\n')
#   cat('## 请检查程序。\n')
#   # cat('## 程序脚本位于：==> 192.168.1.135:/home/fl/myData/R/vnpyData/ \n')
#   cat('## 程序脚本位于：==> william-PC:/home/william/Documents/myData/R/vnpyData/ \n')
#   cat("## ====================================== ##\n\n")
# }else{
#   cat('## 当前交易日的数据已入库！！！\n')
#   cat("## ====================================== ##\n\n")
# }


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

mysql <- mysqlFetch('vnpy')
dtBreakTime <- dbGetQuery(mysql, "
            SELECT *
            FROM breakTime_TianMi1_FromAli"
            ) %>% as.data.table() %>%
            .[TradingDay == currTradingDay[1,days]]
if (nrow(dtBreakTime) != 0) {
  dtBreakTime <- dtBreakTime[!grep('08:59:|20:59:', beginTime)]
}
cat("## ====================================== ##\n")
cat("## china_futures_bar.daily \n")
cat("## china_futures_bar.minute \n")
cat('## \n')
## -----------------------------------------------------------------------------
## 1. 如果当前交易日不在数据
## 2. 或者当前数据缺失
if (! lastTradingDay[1,days] %in% dtDaily[,TradingDay] |
  dtDaily[.N, recordingNo < .95 * mean(recordingNo)] |
  ! lastTradingDay[1,days] %in% dtMinute[,TradingDay] |
  dtMinute[.N, recordingNo < .95 * mean(recordingNo)]) {
  cat('## 当前交易日的数据未入库！！！\n')
  cat('## 请检查程序。\n')
  cat('## 程序脚本位于：==> 192.168.1.135:/home/fl/myData/R/vnpyData/ \n')
  cat("## ====================================== ##\n\n")
}else{
  cat('## 当前交易日的数据已入库！！！\n')
  cat("## -------------------------------------- ##\n\n")
  cat('## Daily ##\n\n')
  print(dtDaily)
  cat("## -------------------------------------- ##\n\n")
  cat('## Minute ##\n\n')
  print(dtMinute)
  cat("## ====================================== ##\n\n")
}

if (nrow(dtBreakTime) != 0) {
  cat('## 当前交易日的数据有间断！！！\n')
  cat('## 请检查程序。\n')
  cat('## 程序脚本位于：==> 192.168.1.135:/home/fl/myData/R/vnpyData/ \n')
  cat("## ====================================== ##\n\n")
  cat('## BreakTime ##\n\n')
  print(dtBreakTime)
  cat("## -------------------------------------- ##\n\n")
} else {
  cat('## 当前交易日的数据无间断！！！\n')
  cat("## ====================================== ##\n\n")
}

## =============================================================================
## china_futures_bar
## =============================================================================
# mysql <- mysqlFetch('china_futures_bar')
# dtOiRank <- dbGetQuery(mysql,paste("
#             SELECT TradingDay, count(*) as recordingNo
#             FROM oiRank
#             WHERE TradingDay >= ", format(Sys.Date()-30,"%Y%m%d"),
#             "GROUP BY TradingDay")
#             ) %>% as.data.table()
# cat("## ====================================== ##\n")
# cat("## china_futures_bar.oiRank \n")
# cat('## \n')

# mysql <- mysqlFetch('china_futures_bar')
# dceProducts <- data.table(id = seq(1:16),
#                      conName = c('a','b','m','y','p','c','cs','jd',
#                                  'fb','bb','l','v','pp','j','jm','i')
#                      )
# allInstrumentIDNum <- dbGetQuery(mysql,
# paste("select distinct InstrumentID
#        from minute
#        where tradingday = ", gsub('-','',lastTradingDay[1,days]),
#       "and (volume != 0 or closeopeninterest != 0)")) %>% as.data.table() %>%
#   .[,":="(ContractID = gsub("[0-9]","",InstrumentID))] %>%
#   merge(.,dceProducts, by.x = 'ContractID', by.y = 'conName')
# tempCurrFiles <- list.files(paste0("~/myCodes/ExchDataFetch/data/positionRank/DCE/",
#                                   substr(lastTradingDay[1,days], 1,4),"/"), pattern =
#                              paste0(lastTradingDay[1,gsub('-','',days)],".*")) %>%
#   gsub(as.character(lastTradingDay[1,gsub('-','',days)]), '', .) %>%
#   gsub('_|\\.xlsx','',.)
# notInFiles <- rep(NA,nrow(allInstrumentIDNum))
# for (i in 1:nrow(allInstrumentIDNum)) {
#   if (!(allInstrumentIDNum[i, InstrumentID] %in% tempCurrFiles))
#     notInFiles[i] <- allInstrumentIDNum[i, InstrumentID]
# }
# ## -----------------------------------------------------------------------------
# ## 1. 如果当前交易日不在数据
# ## 2. 或者当前数据缺失
# if (! lastTradingDay[1,days] %in% dtOiRank[,TradingDay] |
#   dtOiRank[.N, recordingNo < .95 * mean(recordingNo)] |
#   len(notInFiles[!is.na(notInFiles)]) != 0) {
#   cat('## 当前交易日的数据未入库！！！\n')
#   cat('## 请检查程序。\n')
#   cat('## DCE 未入库数据含：')
#   print(data.table(InstrumentID = notInFiles[!is.na(notInFiles)]))
#   cat('## 程序脚本位于：==> /home/fl/myCodes/ExchDataFetch/ \n')
#   cat("## ====================================== ##\n\n")
# }else{
#   cat('## 当前交易日的数据已入库！！！\n')
#   print(dtOiRank)
#   cat('\n')
#   cat("## ====================================== ##\n\n")
# }


cat("## ====================================== ##\n")
cat("## china_futures_bar.oiRank \n")
cat('## \n')

tempTradingDay <- lastTradingDay[1, gsub('-', '', days)]
check_oi <- function(exchID) {
  tempDir <- paste0("/home/fl/myData/data/oiRank/data/", toupper(exchID), "/2018")
  tempPattern <- ifelse(exchID == 'czce', '\\.xls', '\\.csv')
  tempFiles <- list.files(tempDir, pattern = tempPattern) %>% grep(tempTradingDay, .)

  cat("\n## ====================================== ##\n")
  if (length(tempFiles) == 0) {
    cat(paste(exchID, '数据未入库'))
  } else {
    cat(paste(exchID, '数据已入库'))
  }
  cat("\n## ====================================== ##\n")
}

for (id in c('cffex','czce','dce','shfe')) {
  check_oi(id)
}

mysql <- mysqlFetch('china_futures_bar')
dtOiRank <- dbGetQuery(mysql,paste("
            SELECT TradingDay, count(*) as recordingNo
            FROM oiRank
            WHERE TradingDay >= ", format(Sys.Date()-30,"%Y%m%d"),
            "GROUP BY TradingDay")
            ) %>% as.data.table()

allInstrumentID_today <- mysqlQuery(db = 'china_futures_bar',
                              query = paste("select distinct InstrumentID
                                            from minute where TradingDay =",
                                            tempTradingDay,
                                            "and (volume != 0 or closeopeninterest != 0)"))
dtOiRank_today <- mysqlQuery(db = 'china_futures_bar',
                             query = paste("select distinct InstrumentID
                                     from oiRank where TradingDay = ",
                                     tempTradingDay))
if (nrow(dtOiRank_today) < nrow(allInstrumentID_today)*.7) {
  cat('## 当前交易日的数据似乎不全！！！\n')
  cat('## allInstrumentID_today')
  print(allInstrumentID_today)
  cat('\n## dtOiRank_today')
  print(dtOiRank_today)
  cat("\n## ====================================== ##\n")
}

cat('\n')
print(dtOiRank)
cat("\n## ====================================== ##\n")

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
cat("\n## ====================================== ##\n")
cat("## china_futures_info.VolumeMultiple \n")
cat('## \n')
if (! lastTradingDay[1,days] %in% dtVolumeMultiple[,TradingDay] |
  dtVolumeMultiple[.N, recordingNo < .90 * mean(recordingNo)]) {
  cat('## 当前交易日的数据未入库！！！\n')
  cat('## 请检查程序。\n')
  cat('## 程序脚本位于：==> /home/fl/William/Codes/china_futures_info \n')
  cat("## ====================================== ##\n")
}else{
  cat('## 当前交易日的数据已入库！！！\n')
  cat("## ====================================== ##\n")
}



## =============================================================================
## lhg_trade
## =============================================================================
# mysql <- mysqlFetch('lhg_trade')
#
# dtOpenInfo2 <- dbGetQuery(mysql,"
#             SELECT *
#             FROM fl_open_t_2
# ") %>% as.data.table()
# cat("## ====================================== ##\n")
# cat("## lhg_trade.fl_open_t_2")
#
# if (! lastTradingDay[1,days] %in% dtOpenInfo2[,TradingDay]) {
#   cat('## 策略的信号数据未入库！！！\n')
#   cat('## 请检查程序。\n')
#   cat('## 程序脚本位于：==> Lin HuanGeng 策略信号 \n')
#   cat("## ====================================== ##\n\n")
# }else{
#   cat('\n## 策略的信号数据已入库！！！\n')
#   print(dtOpenInfo2)
#   cat("## ====================================== ##\n")
# }
## =============================================================================
## HiCloud
## =============================================================================

accountInfo <- data.table(accountID = c('TianMi1','TianMi2','TianMi3',
                                        'YunYang1', 'HanFeng'))

checkSignal <- function(accountID) {
  mysql <- mysqlFetch(accountID)
  tradingSignal <- dbGetQuery(mysql, "select * from tradingSignal order by InstrumentID") %>%
    as.data.table()

  ## ===========================================================================
  if (nrow(tradingSignal) == 0) {
    cat("\n")
    print(paste0('## 今天策略没有信号：==> ', accountID))
    cat("## ====================================== ##\n\n")
  } else {
    if (! lastTradingDay[1,days] %in% tradingSignal[,TradingDay]) {
      cat('## 策略的信号数据未入库！！！\n')
      cat('## 请检查程序。\n')
      print(paste0('## 程序脚本定位于：==> ', accountID))
      cat("## ====================================== ##\n\n")
    }else{
      cat(paste0('\n\n## 信号数据已入库：==> ', accountID))
      cat("\n## ====================================== ##\n\n")
      print(tradingSignal)
    }
  }
  ## ===========================================================================
}

for (i in 1:nrow(accountInfo)) {
  checkSignal(accountInfo[i, accountID])
}


