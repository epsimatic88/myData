################################################################################
## FromDC2mysql_03_transform_bar.R
################################################################################


## -----------------------------------------------------------------------------
print(paste0("#---------- Calculating numeric ExchTime! ------------------------#"))
## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------
temp <- dt$UpdateTime
v1 <- substr(temp,1,2) %>% as.numeric() * 3600
v1[v1 > 18*3600] <- (v1[v1 > 18*3600] - 86400)
v2 <- substr(temp,4,5) %>% as.numeric() * 60
v3 <- substr(temp,7,8) %>% as.numeric() * 1
v4 <- dt$UpdateMillisec  %>% as.numeric() / 1000
v <- v1 + v2 + v3 + v4
dt[, NumericExchTime := v]

## -----------------------------------------------------------------------------
# 先做排序处理
#  dt <- dt[,.SD[order(NumericExchTime, Volume, Turnover)],
#       by=.(TradingDay, InstrumentID)]
dt <- dt[,.SD[order(NumericExchTime, Volume, Turnover)],
         by=.(TradingDay, InstrumentID)]
##############################################################################

# 处理每个合约的异常排除
not_mono_increasing <- dt[, .SD[!(
  NumericExchTime == cummax(NumericExchTime)
  & Volume        >= cummax(Volume)
  & Turnover      >= cummax(Turnover) * 0.99
)], by = .(TradingDay, InstrumentID)]

# mono_increasing
dt <- dt[, .SD[
  NumericExchTime == cummax(NumericExchTime)
  & Volume        >= cummax(Volume)
  & Turnover      >= cummax(Turnover) * 0.99
  ], by = .(TradingDay, InstrumentID)]

dt <- dt[,.SD[,
              .(UpdateTime,UpdateMillisec
                ,LastPrice, OpenPrice, HighestPrice, LowestPrice, Volume
                ,Turnover, OpenInterest, ClosePrice
                ,SettlementPrice, UpperLimitPrice, LowerLimitPrice
                ,BidPrice1, BidVolume1
                ,AskPrice1, AskVolume1
                ,NumericExchTime
                ,DeltaVolume = c(.SD[1,Volume], diff(as.numeric(Volume)))
                ,DeltaTurnover = c(.SD[1,Turnover], diff(as.numeric(Turnover)))
                ,DeltaOpenInterest = c(.SD[1,OpenInterest], diff(as.numeric(OpenInterest)))
              )
              ],by=.(TradingDay, InstrumentID)] %>%
  .[,":="(Minute = substr(UpdateTime, 1,5))]

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
temp <- not_mono_increasing
if(nrow(temp) !=0){
  info <- data.table(status = paste("               (5) [清除数据]: 成交量、成交额非单调递增                :==> Rows:",
                                    nrow(temp),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- data.table(status = paste("               (5) [清除数据]: 成交量、成交额非单调递增                :==> Rows:",
                                    0,sep=" ")
  ) %>% rbind(info,.)
}
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
setcolorder(dt,c("TradingDay","Minute","UpdateTime","UpdateMillisec"
                 ,"InstrumentID", colnames(dt)[5:(ncol(dt)-1)])
)
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
##############################################################################
########## Tick data 转化为 Minute data
##############################################################################
## -----------------------------------------------------------------------------
##    if(args_input[3] == "minute"){
print(paste0("#---------- Transforming 1 minute data ! -------------------------#"))
## -----------------------------------------------------------------------------

## =============================================================================
dtMinute <- dt2MinuteBar(dt)
## =============================================================================
## -----------------------------------------------------------------------------
temp <- dtMinute$Minute
v1 <- substr(temp,1,2) %>% as.numeric() * 3600
v1[v1 > 18*3600] <- (v1[v1 > 18*3600] - 86400)
v2 <- substr(temp,4,5) %>% as.numeric() * 60
v <- v1 + v2
dtMinute[, NumericExchTime := v]
## -----------------------------------------------------------------------------


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
setcolorder(dtMinute,c("TradingDay","Minute", "NumericExchTime","InstrumentID"
                    ,colnames(dtMinute)[5:(ncol(dtMinute))]))
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
##############################################################################
info <- data.table(status = paste("               (6) [数据统计]: 1 分钟入库数据共计有:                   :==> Rows:",
                                  nrow(dtMinute),sep=" ")) %>% rbind(info,.)

## -----------------------------------------------------------------------------
print(paste0("#---------- Transforming Daily data ! ----------------------------#"))
## -----------------------------------------------------------------------------

suppressMessages({
    suppressWarnings({
      dt_allday <- dt2DailyBar(dt,"allday")
      dt_day    <- dt2DailyBar(dt,"day")
      dt_night  <- dt2DailyBar(dt,"night")
    })
})

##############################################################################
##########
##############################################################################
info <- data.table(status = c(paste("               (7) [数据统计]: 全天的入库数据共计有:                   :==> Rows:",
                                    nrow(dt_allday),sep=" "),
                              paste("               (8) [数据统计]: 日盘的入库数据共计有:                   :==> Rows:",
                                    nrow(dt_day),sep=" "),
                              paste("               (9) [数据统计]: 夜盘的入库数据共计有:                   :==> Rows:",
                                    nrow(dt_night),sep=" "))
) %>% rbind(info,.)
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
##

################################################################################
# print(paste(tradingDay,
#             ":==> Data File is Finished at", Sys.time()))
print(paste0("#---------- Data File is Finished at ", Sys.time()))

print(paste0("#---------- Ready to insert into MySQL DATABASE! -----------------#"))
################################################################################
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
