##! dt2MinuteBar.R
##
## 功能：
## 用于把 tick data 的数据转化为 分钟 的数据，
## 1. dt2MinuteBar(dt)
##############################################################################
##----------------------------------------------------------------------------
dt2MinuteBar <- function(dt){
  setkey(dt,InstrumentID)
  temp <- lapply(unique(dt$InstrumentID), function(ii){ dt[ii] })

  no.cores <- max(round(detectCores()/3), 4)
  # no.cores <- max(round(detectCores()/4), 4)
  cl <- makeCluster(no.cores, type="FORK")
  # clusterExport(cl, c("dt","temp"))
  # clusterEvalQ(cl,{library(data.table);library(magrittr)})
  dtMinute <- parLapply(cl, 1:length(temp), function(ii){
    temp[[ii]] %>%
      .[, .SD[,.(
        #-----------------------------------------------------------------------------
        NumericExchTime = .SD[1,NumericExchTime],
        #-----------------------------------------------------------------------------
        OpenPrice = .SD[DeltaVolume !=0][1,LastPrice],
        HighPrice = max(.SD[DeltaVolume !=0][LastPrice !=0]$LastPrice, na.rm=TRUE),
        LowPrice  = min(.SD[DeltaVolume !=0][LastPrice !=0]$LastPrice, na.rm=TRUE),
        ClosePrice = .SD[.N,LastPrice],
        #-----------------------------------------------------------------------------
        Volume = sum(.SD$DeltaVolume, na.rm=TRUE),
        Turnover = sum(.SD$DeltaTurnover, na.rm=TRUE),
        #-----------------------------------------------------------------------------
        OpenOpenInterest = .SD[1,OpenInterest],
        HighOpenInterest = max(.SD$OpenInterest, na.rm=TRUE),
        LowOpenInterest = min(.SD$OpenInterest, na.rm=TRUE),
        CloseOpenInterest = .SD[.N,OpenInterest],
        #-----------------------------------------------------------------------------
        UpperLimitPrice = unique(na.omit(.SD$UpperLimitPrice)),
        LowerLimitPrice = unique(na.omit(.SD$LowerLimitPrice)),
        SettlementPrice = .SD[.N, SettlementPrice]
      )], by = .(TradingDay, InstrumentID, Minute)] %>%
      .[Volume != 0 & Turnover != 0]
  }) %>% rbindlist()
  stopCluster(cl)

  return(dtMinute)
}
##############################################################################
