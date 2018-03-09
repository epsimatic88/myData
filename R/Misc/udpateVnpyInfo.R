dataPath <- "/data/ChinaFuturesTickData/FromPC/vn.data/YY1/ContractInfo"

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

futuresCalendar <- ChinaFuturesCalendar[days %between% c(startDay, endDay)] %>% .[-1]

for (k in 1:nrow(futuresCalendar)) {
  logTradingDay <- futuresCalendar[k, days]
  print(logTradingDay)
  source('./R/vnpyData/vnpyData2mysql_05_info.R')
}
