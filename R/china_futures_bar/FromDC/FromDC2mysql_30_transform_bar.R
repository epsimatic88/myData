##! FromDC2mysql_30_transform_bar.R
#-----------------------------------------------------------------------------
print(paste0("#---------- Calculating numeric ExchTime! ------------------------#"))
#-----------------------------------------------------------------------------
#-------------------------------------------------------------------------------
temp <- dt$UpdateTime
v1 <- substr(temp,1,2) %>% as.numeric() * 3600
v1[v1 > 18*3600] <- (v1[v1 > 18*3600] - 86400)
v2 <- substr(temp,4,5) %>% as.numeric() * 60
v3 <- substr(temp,7,8) %>% as.numeric() * 1
v4 <- dt$UpdateMillisec  %>% as.numeric() / 1000
v <- v1 + v2 + v3 + v4
dt[, NumericExchTime := v]

#-----------------------------------------------------------------------------
# 先做排序处理
#  dt <- dt[,.SD[order(NumericExchTime, Volume, Turnover)],
#       by=.(TradingDay, InstrumentID)]
dt <- dt[,.SD[order(NumericExchTime, Volume, Turnover)],
         by=.(TradingDay, InstrumentID)]

# 处理每个合约的异常排除
not_mono_increasing <- dt[, .SD[!(
  NumericExchTime == cummax(NumericExchTime) &
    Volume          == cummax(Volume) &
    Turnover        == cummax(Turnover)
)], by = .(TradingDay, InstrumentID)]

# mono_increasing
dt <- dt[, .SD[
  NumericExchTime == cummax(NumericExchTime) &
    Volume          == cummax(Volume) &
    Turnover        >= cummax(Turnover) * 0.99
  ], by = .(TradingDay, InstrumentID)]

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
temp <- not_mono_increasing
if(nrow(temp) !=0){
  info <- data.table(status = paste("            (5) [清除数据]: 成交量、成交额非单调递增                :==> Rows:",
                                    nrow(temp),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- data.table(status = paste("            (5) [清除数据]: 成交量、成交额非单调递增                :==> Rows:",
                                    0,sep=" ")
  ) %>% rbind(info,.)
}
##############################################################################
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
setcolorder(dt,c("TradingDay","Minute","UpdateTime","UpdateMillisec"
                 ,"InstrumentID",
                 colnames(dt)[5:(ncol(dt)-1)])
)
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
##############################################################################
########## Tick data 转化为 Minute data
##############################################################################
#-----------------------------------------------------------------------------
if(args_input[3] == "minute"){
  print(paste0("#---------- Transforming 1 minute data ! -------------------------#"))
  #-----------------------------------------------------------------------------
  setkey(dt,InstrumentID)
  temp <- lapply(unique(dt$InstrumentID), function(ii){ dt[ii] })

  ## no.cores <- detectCores() / 4
  no.cores <- 6
  cl <- makeCluster(no.cores, type="FORK")
  clusterExport(cl, c("dt","temp"))
  clusterEvalQ(cl,{library(data.table);library(magrittr)})
  dt_1m <- parLapply(cl, 1:length(temp), function(ii){
    temp[[ii]] %>%
      .[, .SD[,.(
        #-----------------------------------------------------------------------------
        NumericExchTime = .SD[1,NumericExchTime],
        #-----------------------------------------------------------------------------
        OpenPrice = .SD[DeltaVolume !=0][1,LastPrice],
        HighPrice = max(.SD[DeltaVolume !=0][LastPrice !=0]$LastPrice, na.rm = TRUE),
        LowPrice  = min(.SD[DeltaVolume !=0][LastPrice !=0]$LastPrice, na.rm = TRUE),
        #ClosePrice = .SD[nrow(.SD),LastPrice],
        ClosePrice = .SD[.N,LastPrice],
        #-----------------------------------------------------------------------------
        Volume = sum(.SD$DeltaVolume, na.rm=TRUE),
        Turnover = sum(.SD$DeltaTurnover, na.rm=TRUE),
        #-----------------------------------------------------------------------------
        OpenOpenInterest = .SD[1,OpenInterest],
        HighOpenInterest = max(.SD$OpenInterest, na.rm = TRUE),
        LowOpenInterest = min(.SD$OpenInterest, na.rm = TRUE),
        CloseOpenInterest = .SD[.N,OpenInterest],
        #-----------------------------------------------------------------------------
        UpperLimitPrice = unique(na.omit(.SD$UpperLimitPrice)),
        LowerLimitPrice = unique(na.omit(.SD$LowerLimitPrice)),
        SettlementPrice = .SD[.N, SettlementPrice]
      )], by = .(TradingDay, InstrumentID, Minute)] %>%
      .[Volume != 0 & Turnover != 0]
  }) %>% rbindlist()
  stopCluster(cl)
  ##############################################################################
  info <- data.table(status = paste("            (6) [数据统计]: 1 分钟入库数据共计有:                   :==> Rows:",
                                    nrow(dt_1m),sep=" ")) %>% rbind(info,.)
  ##############################################################################
}else{
  ##############################################################################
  #-----------------------------------------------------------------------------
  print(paste0("#---------- Transforming Daily data ! ----------------------------#"))
  #-----------------------------------------------------------------------------

  suppressWarnings({
    dt_allday <- dt2DailyBar(dt,"allday")
    dt_day    <- dt2DailyBar(dt,"day")
    dt_night  <- dt2DailyBar(dt,"night")
  })
  ##############################################################################
  ##########
  ##############################################################################
  info <- data.table(status = c(paste("            (6) [数据统计]: 全天的入库数据共计有:                   :==> Rows:",
                                      nrow(dt_allday),sep=" "),
                                paste("            (7) [数据统计]: 日盘的入库数据共计有:                   :==> Rows:",
                                      nrow(dt_day),sep=" "),
                                paste("            (8) [数据统计]: 夜盘的入库数据共计有:                   :==> Rows:",
                                      nrow(dt_night),sep=" "))
  ) %>% rbind(info,.)
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
}

################################################################################
# print(paste(the_data_file,
#             ":==> Data File is Finished at", Sys.time()))
