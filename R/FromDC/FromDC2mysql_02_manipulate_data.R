################################################################################
## FromDC2mysql_02_manipulate_data.R
################################################################################

source('./R/Rconfig/myDay.R')
if (!ChinaFuturesCalendar[k, grepl("[0-9]",nights)]) {
  ##-- 如果没有夜盘的话，则需要去掉 myDay
  myDay <- myDay[trading_period %between% c("08:00:00", "16:00:00")]
  myDayPlus <- myDayPlus[trading_period %between% c("08:00:00", "16:00:00")]
}

## -----------------------------------------------------------------------------
cols <- c('LastPrice','OpenPrice','HighestPrice','LowestPrice','ClosePrice',
          'Volume','Turnover','OpenInterest','SettlementPrice',
          'UpperLimitPrice','LowerLimitPrice',
          'UpdateMillisec',
          'BidPrice1','BidVolume1',
          'AskPrice1','AskVolume1')

dt[, (cols) := lapply(.SD, function(x){
    as.numeric(x)
}), .SDcols = cols]
dt[, TradingDay := as.character(TradingDay)]
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
if (yearID != '2010') {
  try(
    dt <- dt[, .SD[AveragePrice < .SD[AveragePrice != 0, quantile(AveragePrice,0.95) * 1.5]]
             , by = 'InstrumentID'] %>% 
          .[!is.na(LastPrice) & !is.na(Volume)]
  )
  dt[(Turnover == 0 | is.na(Turnover)),
      Turnover := round(Volume * AveragePrice, 2)]
  dt[, AveragePrice := NULL]
} else {
  cols <- c('LastPrice','OpenPrice','HighestPrice','LowestPrice','ClosePrice',
            'BidPrice1','AskPrice1')

  dt[, (cols) := lapply(.SD, function(x){
      as.numeric(x) / 1000
  }), .SDcols = cols]

  dt[, Turnover := Turnover * 100]
}
## -----------------------------------------------------------------------------


## -----------------------------------------------------------------------------
dt <- dt %>%
  .[UpperLimitPrice >= 0.0 & LowerLimitPrice >= 0.0 &
      nchar(InstrumentID) < 8] %>%
  .[grep('[0-9]',InstrumentID)] %>%
  .[Volume < 999999999] %>%  ## 设定 volume 不超过 999999999，否则是系统的错误
  .[BidVolume1 < 999999] %>%
  .[AskVolume1 < 999999] %>%
  .[,':='(
    TradingDay = tradingDay
    ,NumericExchTime = rep(0)          ## 增加 NumericExchTime
  )]
dt[UpdateMillisec > 10000, UpdateMillisec := 0]
## -----------------------------------------------------------------------------


## -----------------------------------------------------------------------------
# 清除数据为 1.797693e+308 的交易所测试数据,
# 我的做法是将其转化为 NA.
cols <- colnames(dt)[5:ncol(dt)]

dt[, (cols) := lapply(.SD, function(x){
    ifelse(x >= 1.797693e+300, NA, x)
}), .SDcols = cols]
## -----------------------------------------------------------------------------

## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
info <- data.table(status = paste("(1) [读入数据]: 原始数据                                :==> Rows:", nrow(dt),
                                  "/ Columns:", ncol(dt), sep=" ")
                   )
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


## -----------------------------------------------------------------------------
# 清除重复的数据行
the_duplicated_dt <- duplicated(dt[,.(InstrumentID, LastPrice,
                                      OpenPrice, HighestPrice, LowestPrice,
                                      Volume, Turnover,
                                      OpenInterest, ClosePrice,
                                      UpdateTime, UpdateMillisec,
                                      BidPrice1, BidVolume1,
                                      BidPrice2, BidVolume2,
                                      AskPrice1, AskVolume1,
                                      AskPrice2, AskVolume2)
                                   ])
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
if(sum(the_duplicated_dt)){
  info <- data.table(status = paste("               (2) [清除数据]: 重复的数据行                            :==> Rows:",
                                    sum(the_duplicated_dt),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- data.table(status = paste("               (2) [清除数据]: 重复的数据行                            :==> Rows:",
                                    0,sep=" ")
  ) %>% rbind(info,.)
}
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
dt <- dt[!the_duplicated_dt]
## -----------------------------------------------------------------------------


## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## -----------------------------------------------------------------------------
dt <- dt[UpdateTime %in% myDayPlus$trading_period | is.na(UpdateTime) ]
## -----------------------------------------------------------------------------


# breakTime
breakTime <- myDay[!myDay$trading_period %in% dt[,UpdateTime]]          ## breakTime
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

if(nrow(breakTime) > 1){
  #-----------------------------------------------------------------------------
  temp <- diff(breakTime[,id]) %>% find_bt()
  if(nrow(temp) != 0){
    break_time_detector <- data.table()
    for(ii in 1:nrow(temp)){
      break_time_detector <- rbind(break_time_detector,
                                   cbind(breakTime[temp[ii,1],trading_period], breakTime[temp[ii,2],trading_period])
      )
    }
    colnames(break_time_detector) <- c("beginTime", "endTime")
    # 根据文件 dataFile 来确定
    break_time_detector[, TradingDay := tradingDay]

    break_time_detector[, DataSource := 'FromDC']
    break_time_detector[, DataFile := paste(yearID, tradingDay, sep = '-')]
    #-----------------------------------------------------------------------------
    info <- data.table(status = paste("               (4) [检测数据]: 连续 10secs 断点的次数                  :==> Rows:",
                                      nrow(break_time_detector),sep=" ")
    ) %>% rbind(info,.)
  }else{
    info <- data.table(status = paste("               (4) [检测数据]: 连续 10secs 断点的次数                  :==> Rows:",
                                      0,sep=" ")
    ) %>% rbind(info,.)
  }
}else{
  info <- data.table(status = paste("               (4) [检测数据]: 连续 10secs 断点的次数                  :==> Rows:",
                                            0,sep=" ")
  ) %>% rbind(info,.)
}
## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
setcolorder(dt,c("TradingDay","UpdateTime","UpdateMillisec","InstrumentID",
                 colnames(dt)[5:ncol(dt)]))
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

## =============================================================================
## PriceTick
dtPriceTick <- calPriceTick(dt)
dtPriceTick[, VolumeMultiple := NA]
## =============================================================================
