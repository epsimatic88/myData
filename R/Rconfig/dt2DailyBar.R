##! dt2DailyBar.R
##
## 功能：
## 用于把 tick data 的数据转化为 daily 的数据，
## 1. dt2DailyBar(dt,"allday")：全天的数据
## 2. dt2DailyBar(dt,"day")：日盘的数据
## 3. dt2DailyBar(dt,"night")：夜盘的数据
##############################################################################
##----------------------------------------------------------------------------
## 全天
## dt_1d    <- dt2DailyBar(dt,"allday")
## 日盘
## dt_day   <- dt2DailyBar(dt,"day")
## 夜盘
## dt_night <- dt2DailyBar(dt,"night")
dt2DailyBar <- function(x, daySector){
  #-----------------------------------------------------------------------------
  if(daySector == "allday"){
    temp <- x
  }else{
    if(daySector == "day"){##-------------- dn == "night"
      temp <- x[UpdateTime %between% c("08:30:00", "15:30:00")]
    }else{##-------------- dn == "night"
      temp <- x[!(UpdateTime %between% c("08:30:00", "15:30:00"))]
    }
  }
  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  tempRes <- temp %>%
    .[,.SD[,.(
      OpenPrice = .SD[Volume != 0][1, ifelse(is.na(OpenPrice) | OpenPrice == 0, LastPrice, OpenPrice)],
      HighPrice = ifelse(all(is.na(.SD$HighestPrice)) | sum(.SD$HighestPrice, na.rm=TRUE) == 0,
                         max(.SD[Volume != 0]$LastPrice, na.rm=TRUE),
                         max(.SD[Volume != 0]$HighestPrice, na.rm=TRUE)),
      LowPrice  = ifelse(all(is.na(.SD$LowestPrice)) | sum(.SD$LowestPrice, na.rm=TRUE) == 0,
                         min(.SD[Volume != 0][LastPrice !=0]$LastPrice, na.rm=TRUE),
                         min(.SD[Volume != 0][LowestPrice !=0]$LowestPrice, na.rm=TRUE)),
      ClosePrice = ifelse(all(is.na(.SD$ClosePrice)) | sum(.SD$ClosePrice, na.rm=TRUE) == 0,
                          .SD[Volume != 0][.N,LastPrice],
                          .SD[Volume != 0][.N,ClosePrice]),
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
    )], by = .(TradingDay, InstrumentID)] %>%
    .[Volume != 0 & Turnover != 0] %>%
    .[, Sector := daySector]
  #-----------------------------------------------------------------------------
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  setcolorder(tempRes, c('TradingDay', 'Sector',
                          colnames(tempRes)[2:(ncol(tempRes)-1)]))
  return(tempRes)
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
}
##############################################################################
