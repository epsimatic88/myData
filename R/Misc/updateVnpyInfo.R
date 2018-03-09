setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  source('./R/Rconfig/myFread.R')
  source('./R/Rconfig/myDay.R')
  source('./R/Rconfig/myBreakTime.R')
  source('./R/Rconfig/dt2DailyBar.R')
  source('./R/Rconfig/dt2MinuteBar.R')
})

dataPath <- "/data/ChinaFuturesTickData/FromPC/vn.data/YY1/ContractInfo"
coloSource <- "YY1_FromPC"

allDataFiles <- list.files(dataPath, pattern = '\\.csv')

## 起始
startDay <- sapply(1:length(allDataFiles), function(i){
  strsplit(allDataFiles[i], "\\.") %>%
    unlist() %>% .[1] %>% substr(.,1,8)
}) %>% min()

endDay <- sapply(1:length(allDataFiles), function(i){
  strsplit(allDataFiles[i], "\\.") %>%
    unlist() %>% .[1] %>% substr(.,1,8)
}) %>% max()

## 需要更新到的最新日期的倒数
tempHour <- as.numeric(format(Sys.time(), "%H"))
# tempHour <- 6
lastDay <- ifelse(tempHour %between% c(2,8) | tempHour %between% c(15,20), 0, 1)
## =============================================================================


################################################################################
## STEP 1: 获取对应的
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days")))

## =============================================================================
#
## =============================================================================
## 判断是不是需要处理历史的数据，还是只需要处理最新的数据
futuresCalendar <- ChinaFuturesCalendar[days %between% c(startDay, endDay)] %>% .[-1]

## =============================================================================

for(k in 1:nrow(futuresCalendar)){
  ## source('./R/Rconfig/myDay.R')
  print(paste0("#-----------------------------------------------------------------#"))
  print(paste0("#---------- ", coloSource))
  print(paste0("#---------- TradingDay :==> ", futuresCalendar[k, days],
               " -----------------------------#"))
  ## ===========================================================================
  ## 用于记录日志：Log
  ## 1.程序开始执行的时间
  logBeginTime  <- Sys.time()
  ## 2.当天的交易日其
  logTradingDay <- futuresCalendar[k, days]
  ## 当天处理的文件名称
  logDataFile   <- ifelse(nchar(futuresCalendar[k,nights]) == 0,
                          ##-- 如果当天没有夜盘
                          futuresCalendar[k, paste0(days,".csv")],
                          futuresCalendar[k, paste(paste0(nights,".csv"),
                                                   paste0(days,".csv"),
                                                   sep = ' :==> ')])
  ## ===========================================================================
  try(
    source('./R/vnpyData/vnpyData2mysql_05_info.R')
  )
}
