##! ChinaFuturesTickData2mysql_20_manipulate_data.R
#
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
temp <- dt[!(UpperLimitPrice >= 0.0 & LowerLimitPrice >= 0.0)]
info <- data.table(status = paste("              (2) [清除数据]: 价格为负数                              :==> Rows:",
                                  nrow(temp),sep=" ")

                   ) %>% rbind(info,.)

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#
#
#
################################################################################
##: STEP 4: Cleaning Data
##: 过滤价格为负数的数据
##: 删除不需要的数据列
##:````````````````````````````````````````````````````````````````````````````
dt <- dt[UpperLimitPrice >= 0.0 & LowerLimitPrice >= 0.0 &
      nchar(InstrumentID) <= 8] %>%
  .[,':='(
    TradingDay = the_trading_day
  )]

#-----------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# 清除数据为 1.797693e+308 的交易所测试数据,
# 我的做法是将其转化为 NA.
cols <- colnames(dt)[6:ncol(dt)]

dt[, (cols) := lapply(.SD, function(x){
  y <- ifelse(x >= 1.797693e+308, NA, x)
  }), .SDcols = cols]

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

#-------------------------------------------------------------------------------
#
#
#
################################################################################
##: STEP 4: Cleaning Data
##: 清洗重复数据
##:-----------------------------------------------------------------------------

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

if(sum(the_duplicated_dt)){
  info <- data.table(status = paste("              (3) [清除数据]: 重复的数据行                            :==> Rows:",
                                    sum(the_duplicated_dt),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- data.table(status = paste("              (3) [清除数据]: 重复的数据行                            :==> Rows:",
                                    0,sep=" ")
  ) %>% rbind(info,.)
}
#
#
#
dt <- dt[!the_duplicated_dt]
#
#
#
################################################################################
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
temp <- dt[!(UpdateTime %in% myDay$trading_period)]
if(nrow(temp) !=0){
  info <- data.table(status = paste("              (4) [清除数据]: 不在正常交易期间内                      :==> Rows:",
                                    nrow(temp),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- data.table(status = paste("              (4) [清除数据]: 不在正常交易期间内                      :==> Rows:",
                                    0,sep=" ")
  ) %>% rbind(info,.)
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
dt <- dt[UpdateTime %in% myDay$trading_period]
#
#-------------------------------------------------------------------------------
#
print(paste0("#---------- Dealing with Numeric Transformation! -----------------#"))
#-------------------------------------------------------------------------------
# 处理 NumericTime
# 处理 Timestamp 格式
#-------------------------------------------------------------------------------
temp <- dt$Timestamp
v1 <- substr(temp,10,11) %>% as.numeric() * 3600
v1[v1 > 18*3600] <- (v1[v1 > 18*3600] - 86400)
v2 <- substr(temp,13,14) %>% as.numeric() * 60
v3 <- substr(temp,16,17) %>% as.numeric() * 1
v4 <- substr(temp,19,24) %>% as.numeric() / 1000000
v <- v1 + v2 + v3 + v4
dt[, NumericRecvTime := v]

#-------------------------------------------------------------------------------
temp <- dt$UpdateTime
v1 <- substr(temp,1,2) %>% as.numeric() * 3600
v1[v1 > 18*3600] <- (v1[v1 > 18*3600] - 86400)
v2 <- substr(temp,4,5) %>% as.numeric() * 60
v3 <- substr(temp,7,8) %>% as.numeric() * 1
v4 <- dt$UpdateMillisec  %>% as.numeric() / 1000
v <- v1 + v2 + v3 + v4
dt[, NumericExchTime := v]

#-------------------------------------------------------------------------------
#
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
temp <- dt[abs(NumericRecvTime - NumericExchTime) > 1*60]
if(nrow(temp) != 0){
  info <- data.table(status = paste("              (5) [清除数据]: Timestamp 与 UpdateTime 相差超过 1 分钟 :==> Rows:",
                                    nrow(temp),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- data.table(status = paste("              (5) [清除数据]: Timestamp 与 UpdateTime 相差超过 1 分钟 :==> Rows:",
                                    0,sep=" ")
  ) %>% rbind(info,.)
}
#
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#-------------------------------------------------------------------------------
# 如果 Timestamp 与 UpdateTime 相差 大于 1分钟，则清洗                ## 1 minute
# before breaktime.
dt <- dt[abs(NumericRecvTime - NumericExchTime) <= 1*60]
#-------------------------------------------------------------------------------
#

breakTime <- myDay[!myDay$trading_period %in% dt[,UpdateTime]]          ## breakTime
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

if(nrow(breakTime) > 1){
  #-----------------------------------------------------------------------------
  temp <- diff(breakTime[,id]) %>% find_bt()
  break_time_detector <- data.table()
  for(i in 1:nrow(temp)){
    break_time_detector <- rbind(break_time_detector,
                                 cbind(breakTime[temp[i,1],trading_period], breakTime[temp[i,2],trading_period])
    )
  }
  colnames(break_time_detector) <- c("BreakBeginTime", "BreakEndTime")

  break_time_detector[,TradingDay := the_trading_day]

  break_time_detector[, DataSource := paste(args_input[1],args_input[2], sep = "_")]
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if(grepl('history', the_script_main)){##-- 历史的
    break_time_detector[, DataFile := c(data_file_1,data_file_2,data_file_3)  %>% .[!is.na(.)]  %>% paste(.,collapse = ' & ')
                        ]
  }else{##-- crontab
    break_time_detector[, DataFile := ifelse(length(data_file)!=0, data_file, NA)]
  }
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  setcolorder(break_time_detector, c('TradingDay',"BreakBeginTime", "BreakEndTime",
                                     'DataSource','DataFile'))
  #-----------------------------------------------------------------------------
  info <- info <- data.table(status = paste("              (6) [检测数据]: 连续 60secs 断点的次数                  :==> Rows:",
                                            nrow(break_time_detector),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- info <- data.table(status = paste("              (6) [检测数据]: 连续 60secs 断点的次数                  :==> Rows:",
                                            0,sep=" ")
  ) %>% rbind(info,.)
}
################################################################################
