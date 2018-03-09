#! ChinaFuturesTickData2mysql_30_insert_data.R
#
################################################################################

#-------------------------------------------------------------------------------
#
#dt[,':='(
#  DeltaVolume       = rep(NA),
#  DeltaTurnover     = rep(NA),
#  DeltaOpenInterest =  rep(NA))]
#
#
print(paste0("#---------- Calculating Delta! -----------------------------------#"))
#-------------------------------------------------------------------------------
# 处理每个合约的异常排除
# 1.UpdateTime 单调
# 2.Volume单调
# 3.Turnover单调
#-----------------------------------------------------------------------------
# 先做排序处理
#  dt <- dt[, .SD[order(NumericExchTime, Volume, Turnover)],
#           by = .(InstrumentID)]
#
# 处理每个合约的异常排除
not_mono_increasing <- dt[, .SD[!(NumericExchTime == cummax(NumericExchTime) &
                                    Volume        == cummax(Volume) &
                                    Turnover      == cummax(Turnover)
)], by = .(TradingDay, InstrumentID)]

# mono_increasing
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
temp <- not_mono_increasing
if(nrow(temp) !=0){
  info <- data.table(status = paste("              (7) [清除数据]: 成交量、成交额非单调递增                :==> Rows:",
                                    nrow(temp),sep=" ")
  ) %>% rbind(info,.)
}else{
  info <- data.table(status = paste("             (7) [清除数据]: 成交量、成交额非单调递增                :==> Rows:",
                                    0,sep=" ")
  ) %>% rbind(info,.)
}
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

dt <- dt[order(NumericExchTime),
         .SD[NumericExchTime == cummax(NumericExchTime) &
               Volume        == cummax(Volume) &ing
               Turnover      == cummax(Turnover)
             ], by = .(TradingDay, InstrumentID)]
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
setcolorder(dt,c("Timestamp","TradingDay","UpdateTime","UpdateMillisec"
                 ,"InstrumentID", colnames(dt)[6:ncol(dt)]))
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

if(nrow(myDay) < 20000 & as.numeric(format(Sys.time(), "%H")) %between% c(8, 20)){
  ##-- crontab:##---- 日盘 ----------------##
  mysql <- dbConnect(MySQL(), dbname = "china_futures_HFT", host="127.0.0.1",
                     user = mysql_user, password = mysql_pw)
  suppressWarnings(
    temp <- dbGetQuery(mysql, paste("SELECT ",paste(colnames(dt), collapse = ','),
                                    "FROM ", paste(args_input[1], args_input[2],sep="_"),
                                    'WHERE TradingDay = ', unique(dt$TradingDay),
                                    "AND UpdateTime NOT BETWEEN '08:00:00' AND '16:00:00'")  ## 6*3600
    ) %>% as.data.table() %>% .[,TradingDay := gsub("-","", TradingDay)]
  )

  if(nrow(temp) != 0){##----- 如果有夜盘的话，Delta 计算的时候需要减掉夜盘的数据。
    dt <- list(dt,temp) %>% rbindlist() %>%
      .[order(NumericExchTime),
        .SD[NumericExchTime == cummax(NumericExchTime) &
              Volume        == cummax(Volume) &
              Turnover      == cummax(Turnover)
            ], by = .(TradingDay, InstrumentID)] %>%
      .[,':='(
        DeltaVolume        = c(0, diff(Volume,lag=1))
        ,DeltaTurnover     = c(0, diff(Turnover,lag=1))
        ,DeltaOpenInterest = c(0, diff(OpenInterest,lag=1))
      ), by = .(TradingDay, InstrumentID)] %>%
      .[UpdateTime >= "08:59:00" & UpdateTime <= "15:15:00"]
  }
}else{
  dt[,':='(
    DeltaVolume        = c(0, diff(Volume,lag=1))
    ,DeltaTurnover     = c(0, diff(Turnover,lag=1))
    ,DeltaOpenInterest = c(0, diff(OpenInterest,lag=1))
  ), by = .(TradingDay, InstrumentID)]
}
################################################################################
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
setcolorder(dt,c("Timestamp","TradingDay","UpdateTime","UpdateMillisec"
                 ,"InstrumentID", colnames(dt)[6:ncol(dt)]))
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

################################################################################
print(paste0("#---------- Writting into MySQL DATABASE! ------------------------#"))
################################################################################
