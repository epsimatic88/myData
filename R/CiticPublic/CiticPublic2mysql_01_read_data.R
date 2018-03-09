##! citicPublic2mysql_10_read_data.R
##
source('./R/Rconfig/myDay.R')
if(futuresCalendar[k, length(grep("[0-9]",nights)) == 0]){
  ##-- 如果没有夜盘的话，则需要去掉 myDay
  myDay <- myDay[trading_period %between% c("08:00:00", "16:00:00")]
  myDayPlus <- myDayPlus[trading_period %between% c("08:00:00", "16:00:00")]
}

readDataFile <- function(x) {
    read_csv(x,
                   col_types = list(TradingDay   = col_character(),
                                    InstrumentID = col_character(),
                                    UpdateTime   = col_character(),
                                    Volume       = col_number(),
                                    Turnover     = col_number())
    ) %>% as.data.table() %>%
      .[grep("^[0-9]{8}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{4,6}$", Timestamp)] %>%
      .[,.(Timestamp, TradingDay, UpdateTime, UpdateMillisec
           ,InstrumentID,LastPrice
           ,OpenPrice, HighestPrice, LowestPrice,ClosePrice
           ,Volume,Turnover,OpenInterest
           ,SettlementPrice,UpperLimitPrice,LowerLimitPrice
           ,BidPrice1,BidVolume1,BidPrice2,BidVolume2
           ,BidPrice3,BidVolume3,BidPrice4,BidVolume4
           ,BidPrice5,BidVolume5
           ,AskPrice1,AskVolume1,AskPrice2,AskVolume2
           ,AskPrice3,AskVolume3,AskPrice4,AskVolume4
           ,AskPrice5,AskVolume5)]
}

##
##
#-----------------------------------------------------------------------------
# 提取夜盘数据
# 20170504 的夜盘因为上海服务器断电，所以需要从高池那里复制一份数据
# 存储在 /CiticPublic/data/ctpmdprod1.20170504023201.csv
#
## 再次悲剧了....
# 20170511:的数据因为高池重新更改了密码,也是没有接收到数据呀......MD
## 夜盘数据
if ( futuresCalendar[k,days] %in% c('20170504','20170511') ){
  if ( futuresCalendar[k,days] == '20170504' ){
    tempDataFile <- "/home/fl/myData/R/CiticPublic/data/ctpmdprod1.20170504023201.csv"
    dtNight <- tempDataFile %>%
          myFreadBar() %>%
          .[! substr(Timestamp,10,11) %between% c('08','15')] %>%
          .[UpdateTime %between% c("20:58:00","24:00:00") | UpdateTime %between% c("00:00:00","02:35:00")]
  }
  if(futuresCalendar[k,days] == '20170511'){
    tempDataFile <- "/home/fl/myData/R/CiticPublic/data/ctpmdprod1.20170511023201.csv"
    dtNight <- tempDataFile %>%
          myFreadBar() %>%
          .[! substr(Timestamp,10,11) %between% c('08','15')] %>%
          .[UpdateTime %between% c("20:58:00","24:00:00") | UpdateTime %between% c("00:00:00","02:35:00")]
  }
} else {
    if (futuresCalendar[k, days] %in% c('20170801','20170811','20170814')) {
      temp <- grep(futuresCalendar[k,nights], allDataFiles, value = T) %>%
        paste0(dataPath, '/', .) %>%
        readDataFile()
      dtNight <- temp %>%
        .[! substr(Timestamp,10,11) %between% c('08','15')] %>%
        .[UpdateTime %between% c("20:58:00","24:00:00") | UpdateTime %between% c("00:00:00","02:35:00")]
    } else {
      if ( nchar(futuresCalendar[k,nights]) == 0 ){
        ##-- 如果没有夜盘
        dtNight <- data.table()
      } else {
      dtNight <- grep(futuresCalendar[k,nights], allDataFiles, value = T) %>%
        paste0(dataPath, '/', .) %>%
        myFreadBar() %>%
        .[! substr(Timestamp,10,11) %between% c('08','15')] %>%
        .[UpdateTime %between% c("20:58:00","24:00:00") | UpdateTime %between% c("00:00:00","02:35:00")]
        }
    }
}

#-----------------------------------------------------------------------------
# 提取日盘数据
if (futuresCalendar[k,days] == '20170511') {
    tempDataFile <- "/home/fl/myData/R/CiticPublic/data/ctpmdprod1.20170511151701.csv"
    dtDay <- tempDataFile %>%
          myFreadBar() %>%
          .[substr(Timestamp,10,11) %between% c('08','15')] %>%
          .[UpdateTime %between% c("08:58:00","15:35:00")]
} else {
  if (futuresCalendar[k, days] %in% c('20170503','20170731','20170801','20170811','20170814')) {
    temp <- grep(futuresCalendar[k,days], allDataFiles, value = T) %>%
      paste0(dataPath, '/', .) %>%
      readDataFile()
    dtDay <- temp %>%
      .[substr(Timestamp,10,11) %between% c('08','15')] %>%
      .[UpdateTime %between% c("08:58:00","15:35:00")]
    } else {
      dtDay <- grep(futuresCalendar[k,days], allDataFiles, value = T) %>%
      paste0(dataPath, '/', .) %>%
      myFreadBar() %>%
      .[substr(Timestamp,10,11) %between% c('08','15')] %>%
      .[UpdateTime %between% c("08:58:00","15:35:00")]
    }
}


## =============================================================================
## 合并数据
## 1.去除 nchar 超过 8 的，比如 spd 套利合约
## 2.去除期权的数据
dt <- list(dtNight, dtDay) %>% rbindlist()
## =============================================================================


## =============================================================================
##! dc2mysql_20_dt.R
dt <- dt %>%
  .[UpperLimitPrice >= 0 & LowerLimitPrice >= 0] %>%
  .[Volume < 10000000000] %>%  ## 设定 volume 不超过 1,000,000,000，否则是系统的错误
  .[BidVolume1 < 999999] %>%
  .[AskVolume1 < 999999] %>%
  .[, ':='(TradingDay = as.character(logTradingDay))]
## =============================================================================


#-----------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# 清除数据为 1.797693e+308 的交易所测试数据,
# 我的做法是将其转化为 NA.
cols <- colnames(dt)[6:ncol(dt)]
dt[, (cols) := lapply(.SD, function(x){
  tempRes <- ifelse(x >= 1.797693e+300, NA, x)
}), .SDcols = cols]
dt <- dt[!is.na(LastPrice)]
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
info <- data.table(status = paste("(1) [读入数据]: 原始数据                                :==> Rows:", nrow(dt),
                                  "/ Columns:", ncol(dt), sep=" ")
)
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#-------------------------------------------------------------------------------
# 清除重复的数据行
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
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
if(sum(the_duplicated_dt)){
  info <- data.table(status = paste("               (2) [清除数据]: 重复的数据行                            :==> Rows:",
                                    sum(the_duplicated_dt),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- data.table(status = paste("               (2) [清除数据]: 重复的数据行                            :==> Rows:",
                                    0,sep=" ")
  ) %>% rbind(info,.)
}
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#-----------------------------------------------------------------------------
dt <- dt[!the_duplicated_dt]
#-----------------------------------------------------------------------------
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
temp <- dt[!(UpdateTime %in% myDayPlus$trading_period | is.na(UpdateTime))]
if(nrow(temp) !=0){
  info <- data.table(status = paste("               (3) [清除数据]: 不在正常交易期间内                      :==> Rows:",
                                    nrow(temp),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- data.table(status = paste("               (3) [清除数据]: 不在正常交易期间内                      :==> Rows:",
                                    0,sep=" ")
  ) %>% rbind(info,.)
}
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#-----------------------------------------------------------------------------
dt <- dt[UpdateTime %in% myDayPlus$trading_period | is.na(UpdateTime) ]
#-------------------------------------------------------------------------------

