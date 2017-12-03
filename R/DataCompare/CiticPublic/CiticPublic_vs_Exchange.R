################################################################################
## CiticiPublic_vs_Exchange.R
## 这是主函数:
## 对比 CiticPulic 日行情数据 与 china_futures_bar.daily 数据质量
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-11-31
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("CiticPublic_vs_Exchange.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
options(width = 130)
################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days")))


## =============================================================================
## dtBar
mysql <- mysqlFetch('CiticPublic', host = '192.168.1.166')
dtCitic <- dbGetQuery(mysql,"
        select * from daily
        where Sector = 'allday'
        and Volume != 0
    ")  %>% as.data.table() %>%
    .[, .(TradingDay, InstrumentID,
          OpenPrice, HighPrice, LowPrice, ClosePrice,
          Volume, Turnover,
          CloseOpenInterest, SettlementPrice)]
## =============================================================================

## =============================================================================
## dtExchange
mysql <- mysqlFetch('Exchange', host = '192.168.1.166')
dtExchange <- dbGetQuery(mysql,"
        select * from daily
        where Volume != 0
    ")  %>% as.data.table() %>%
    .[, .(TradingDay, InstrumentID,
          OpenPrice, HighPrice, LowPrice, ClosePrice,
          Volume, Turnover,
          CloseOpenInterest, SettlementPrice)]
## =============================================================================




## =============================================================================
## dt
dt <- merge(dtCitic, dtExchange, by = c('TradingDay','InstrumentID'), all = TRUE) %>%
    .[TradingDay %between% c(max(dtCitic[,min(TradingDay)],dtExchange[,min(TradingDay)]),
                             min(dtCitic[,max(TradingDay)],dtExchange[,max(TradingDay)]))]

cols <- colnames(dt)[3:ncol(dt)]
dt[, (cols) := lapply(.SD, function(x){
    ifelse(is.na(x), 0, x)
}), .SDcols = cols]
## =============================================================================

dt[, ":="(
    errOpen = OpenPrice.x - OpenPrice.y,
    errHigh = HighPrice.x - HighPrice.y,
    errLow  = LowPrice.x - LowPrice.y,
    errClose = ClosePrice.x - ClosePrice.y,
    errVolume = Volume.x - Volume.y,
    errTurnover = Turnover.x - Turnover.y,
    errOI = CloseOpenInterest.x - CloseOpenInterest.y,
    errStl = SettlementPrice.x - SettlementPrice.y
)]

## =============================================================================
dt[errOpen != 0][OpenPrice.y != 0]
dt[errHigh != 0][HighPrice.y != 0]
dt[errLow != 0][LowPrice.y != 0]


dt[errOpen != 0][OpenPrice.x != 0][OpenPrice.y != 0][!grep('IF|TF',InstrumentID)]
dt[errHigh != 0][HighPrice.x != 0][HighPrice.y != 0][!grep('IF|TF',InstrumentID)]
dt[errLow != 0][LowPrice.x != 0][LowPrice.y != 0][!grep('IF|TF',InstrumentID)]
dt[errClose != 0][ClosePrice.x != 0][ClosePrice.y != 0][!grep('IF|TF',InstrumentID)]

dt[errClose != 0 & ClosePrice.x != 0 & ClosePrice.y != 0, ":="(
  ClosePrice.x = ClosePrice.y
  )]

dt[errVolume != 0][Volume.x != 0]
dt[errVolume != 0][Volume.x != 0][abs(errVolume) > 1000 ][,unique(TradingDay)]
## =============================================================================

dt[errClose != 0][ClosePrice.x != 0][ClosePrice.y != 0][!grep('IF|TF|^T[0-9]{4,}',InstrumentID)][,unique(TradingDay)]

## =============================================================================
## 补充数据
dataPath <- '/home/fl/myData/data/CiticPublic'
list.files(dataPath)
suppressMessages({
  source('./R/Rconfig/myInit.R')
  source('./R/Rconfig/myFread.R')
  source('./R/Rconfig/myDay.R')
  source('./R/Rconfig/myBreakTime.R')
  source('./R/Rconfig/dt2DailyBar.R')
  source('./R/Rconfig/dt2MinuteBar.R')
  source('./R/Rconfig/priceTick.R')
})
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              showProgress=TRUE,
                              colClasses = list(character = c("nights","days"))
                          )
## =============================================================================


## =============================================================================
## gaochi-colo
setwd('/home/fl/myData/')
tradingDay <- "2016-11-09"
dataPath <- "/home/fl/myData/data/CiticPublic"  %>% paste0(.,'/',tradingDay)
futures_calendar <- ChinaFuturesCalendar[days == gsub('-','',tradingDay)]
args_input <- c('colo1','ctpmdprod1')
k <- 1

begin_time_marker <- Sys.time()
the_trading_day <- futures_calendar[k, days]
the_script_main <- c("ChinaFuturesTickData2mysql_01_main_crontab.R")
data_file <- 'MissingFile'
source('./R/Rconfig/myDay.R')
if (!futures_calendar[k, grepl("[0-9]",nights)]) {
  ##-- 如果没有夜盘的话，则需要去掉 myDay
  myDay <- myDay[trading_period %between% c("08:00:00", "16:00:00")]
  myDayPlus <- myDayPlus[trading_period %between% c("08:00:00", "16:00:00")]
}

data_file_info <- paste(paste(args_input[1], args_input[2],sep="_"),
                        ":==>",
                        paste(paste0(futures_calendar[k,nights], "_night"),
                              paste0(futures_calendar[k,days], "_day"), sep = " & "),
                        sep = " ")
print(paste0("#-----------------------------------------------------------------#"))
print(paste0("# <", k, "> ", data_file_info))
print(paste0("# <", k, "> :--> at ", Sys.time()))
source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_10_read_data.R')

list.files(dataPath)
dataFileNight <- "ctpmdprod1.20161109023201.csv" %>% paste0(dataPath,'/',.)
dataFileDay   <- "ctpmdprod1.20161109151701.csv" %>% paste0(dataPath,'/',.)

dtNight <- myFreadHFT(dataFileNight) %>%
            .[substr(UpdateTime,1,5) %between% c("20:58","24:00") |
              substr(UpdateTime,1,5) %between% c("00:00","02:35")]
dtDay <- myFreadHFT(dataFileDay) %>%
            .[substr(UpdateTime,1,5) %between% c("08:58","15:35")]

dt <- list(dtNight, dtDay)  %>% rbindlist()
info <- data.table(status = paste("(1) [读入数据]: 原始数据                                :==> Rows:", nrow(dt),
                                  "/ Columns:", ncol(dt), sep=" ")
                   )
source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_20_manipulate_data.R')
print(paste0("#---------- Calculating Delta! -----------------------------------#"))

not_mono_increasing <- dt[, .SD[!(NumericExchTime == cummax(NumericExchTime) &
                                    Volume        >= cummax(Volume) &
                                    Turnover      >= cummax(Turnover) *0.99
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

dt <- dt[order(NumericExchTime),
         .SD[NumericExchTime == cummax(NumericExchTime) &
               Volume        >= cummax(Volume) &
               Turnover      >= cummax(Turnover) *0.99
             ], by = .(TradingDay, InstrumentID)]
setcolorder(dt,c("Timestamp","TradingDay","UpdateTime","UpdateMillisec"
                 ,"InstrumentID", colnames(dt)[6:ncol(dt)]))
dt[,':='(
  DeltaVolume        = c(.SD[1,Volume], diff(Volume,lag=1))
  ,DeltaTurnover     = c(.SD[1,Volume], diff(Turnover,lag=1))
  ,DeltaOpenInterest = c(.SD[1,Volume], diff(OpenInterest,lag=1))
), by = .(TradingDay, InstrumentID)]
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

colo2DailyBar <- function(x, daySector) {
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
  tempRes <- temp %>%
    .[,.SD[,.(
      OpenPrice = .SD[DeltaVolume != 0][1,LastPrice],
      HighPrice = .SD[, max(LastPrice,na.rm=TRUE)],
      LowPrice  = .SD[, min(LastPrice,na.rm=TRUE)],
      ClosePrice = .SD[.N,LastPrice],
      #-----------------------------------------------------------------------------
      # Volume            = sum(.SD$DeltaVolume, na.rm=TRUE),
      # Turnover          = sum(.SD$DeltaTurnover, na.rm=TRUE),
      Volume            = max(.SD[nrow(.SD),Volume], sum(.SD$DeltaVolume, na.rm=TRUE)),
      Turnover          = max(.SD[nrow(.SD),Turnover], sum(.SD$DeltaTurnover, na.rm=TRUE)),
      #                 -----------------------------------------------------------------------------
      OpenOpenInterest  = .SD[1,OpenInterest],
      HighOpenInterest  = .SD[,max(OpenInterest, na.rm=TRUE)],
      LowOpenInterest   = .SD[,min(OpenInterest, na.rm=TRUE)],
      CloseOpenInterest = .SD[.N,OpenInterest],
      #                 -----------------------------------------------------------------------------
      UpperLimitPrice   = unique(na.omit(.SD$UpperLimitPrice)),
      LowerLimitPrice   = unique(na.omit(.SD$LowerLimitPrice)),
      SettlementPrice   = 0
    )], by = .(TradingDay, InstrumentID)] %>%
    .[Volume != 0] %>%
    .[, Sector := daySector]
}
dt_allday <- colo2DailyBar(dt, 'allday')
comp <- merge(dt_allday, dtExchange[TradingDay == 20161109], by = c('TradingDay','InstrumentID'),all=TRUE)
comp[OpenPrice.x != OpenPrice.y]
comp[ClosePrice.x != ClosePrice.y]
comp[HighPrice.x != HighPrice.y]
comp[LowPrice.x != LowPrice.y]
dt_day <- colo2DailyBar(dt, 'day')
dt_night <- colo2DailyBar(dt, 'night')

dt[,":="(Minute = substr(UpdateTime, 1,5))]
colo2MinuteBar <- function(dt) {
  setkey(dt,InstrumentID)
  temp <- lapply(unique(dt$InstrumentID), function(ii){ dt[ii] })

  no.cores <- max(round(detectCores()/4), 8)
  cl <- makeCluster(no.cores, type="FORK")
  dtMinute <- parLapply(cl, 1:length(temp), function(ii){
    ## -------------------------------------------------------------------------
    tempRes <- temp[[ii]] %>%
      .[, .SD[,.(
        #-----------------------------------------------------------------------
        NumericExchTime = .SD[1,NumericExchTime],
        #-----------------------------------------------------------------------
        OpenPrice  = .SD[DeltaVolume != 0][1,LastPrice],
        HighPrice  = .SD[DeltaVolume != 0, max(LastPrice, na.rm=TRUE)],
        LowPrice   = .SD[DeltaVolume != 0, min(LastPrice, na.rm=TRUE)],
        ClosePrice = ifelse(nrow(.SD[DeltaVolume != 0]) != 0,
                      .SD[DeltaVolume != 0][nrow(.SD[DeltaVolume != 0]), LastPrice],
                      .SD[.N,LastPrice]),
        #-----------------------------------------------------------------------
        Volume            = sum(.SD$DeltaVolume, na.rm=TRUE),
        Turnover          = sum(.SD$DeltaTurnover, na.rm=TRUE),
        #                 ------------------------------------------------------
        OpenOpenInterest  = .SD[1,OpenInterest],
        HighOpenInterest  = .SD[,max(OpenInterest, na.rm=TRUE)],
        LowOpenInterest   = .SD[,min(OpenInterest, na.rm=TRUE)],
        CloseOpenInterest = .SD[.N,OpenInterest],
        #                 ------------------------------------------------------
        UpperLimitPrice   = unique(na.omit(.SD$UpperLimitPrice)),
        LowerLimitPrice   = unique(na.omit(.SD$LowerLimitPrice)),
        SettlementPrice   = 0
      )], by = .(TradingDay, InstrumentID, Minute)] %>%
      .[Volume != 0]
    return(tempRes)
    ## -------------------------------------------------------------------------
  }) %>% rbindlist()
  stopCluster(cl)
  return(dtMinute)
}
dtMinute <- colo2MinuteBar(dt)
temp <- dtMinute$Minute
v1 <- substr(temp,1,2) %>% as.numeric() * 3600
v1[v1 > 18*3600] <- (v1[v1 > 18*3600] - 86400)
v2 <- substr(temp,4,5) %>% as.numeric() * 60
v <- v1 + v2
dtMinute[, NumericExchTime := v]
setcolorder(dtMinute,c("TradingDay","Minute", "NumericExchTime","InstrumentID"
                    ,colnames(dtMinute)[5:(ncol(dtMinute))]))

dtDaily <- list(dt_allday, dt_day, dt_night) %>% rbindlist()
setcolorder(dtDaily,c("TradingDay","Sector","InstrumentID"
                    ,colnames(dtDaily)[3:(ncol(dtDaily)-1)]))

fwrite(dtDaily, paste0(dataPath,'/','daily.csv'))
fwrite(dtMinute, paste0(dataPath,'/','minute.csv'))

mysql <- mysqlFetch('CiticPublic')
dbSendQuery(mysql,paste0("DELETE FROM daily",
            " WHERE TradingDay = ", gsub('-','',tradingDay)))
dbSendQuery(mysql,paste0("DELETE FROM minute",
            " WHERE TradingDay = ", gsub('-','',tradingDay)))
dbWriteTable(mysql, "daily",
             dtDaily, row.name　=　FALSE, append = T)
dbWriteTable(mysql, "minute",
             dtMinute, row.name　=　FALSE, append = T)
## =============================================================================


## =============================================================================
setwd('/home/fl/myData/')
## CiticPublic/GTJAPublic
tradingDay <- "2017-01-23"
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              showProgress=TRUE,
                              colClasses = list(character = c("nights","days"))
                          )
dataPath <- "/home/fl/myData/data/CiticPublic"  %>% paste0(.,'/',tradingDay)
futuresCalendar <- ChinaFuturesCalendar[days == gsub('-','',tradingDay)]
k <- 1
print(paste0("#-----------------------------------------------------------------#"))
print(paste('#', futuresCalendar[k,days]))
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
allDataFiles <- list.files(dataPath, pattern = '\\.csv')
source('./R/CiticPublic/CiticPublic2mysql_01_read_data.R')
source('./R/CiticPublic/CiticPublic2mysql_02_manipulate_data.R')

dtDaily <- list(dt_allday, dt_day, dt_night) %>% rbindlist()
fwrite(dtDaily, paste0(dataPath,'/','daily.csv'))
fwrite(dtMinute, paste0(dataPath,'/','minute.csv'))

mysql <- mysqlFetch('CiticPublic')
dbSendQuery(mysql,paste0("DELETE FROM daily",
            " WHERE TradingDay = ", gsub('-','',tradingDay)))
dbSendQuery(mysql,paste0("DELETE FROM minute",
            " WHERE TradingDay = ", gsub('-','',tradingDay)))
dbWriteTable(mysql, "daily",
             dtDaily, row.name　=　FALSE, append = T)
dbWriteTable(mysql, "minute",
             dtMinute, row.name　=　FALSE, append = T)
## =============================================================================



## =============================================================================
setwd('/home/fl/myData/')
## xxf_CTPMD1
tradingDays <- c("2017-06-16","2017-08-04","2017-08-08","2017-08-09")

for (tradingDay in tradingDays) {
  ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                                showProgress=TRUE,
                                colClasses = list(character = c("nights","days"))
                            )
  dataPath <- "/home/fl/myData/data/CiticPublic"  %>% paste0(.,'/',tradingDay)
  list.files(dataPath)

  coloID <- data.table(colo = c('CTPMD1'),
                       csv  = c('ctp1'))
  allDataFiles <- list.files(dataPath, pattern = '.*\\.csv$')
  includeHistory <- TRUE

  startDay <- sapply(1:length(allDataFiles), function(i){
    strsplit(allDataFiles[i], "\\.") %>%
      unlist() %>% .[2] %>% substr(.,1,8)
  }) %>% min()

  endDay <- sapply(1:length(allDataFiles), function(i){
    strsplit(allDataFiles[i], "\\.") %>%
      unlist() %>% .[2] %>% substr(.,1,8)
  }) %>% max()

  currTradingDay <- ChinaFuturesCalendar[days == gsub('-','',tradingDay)]
  k <- 1
  i <- 1
  ## =========================================================================
  ## 用于记录日志：Log
  ## 1.程序开始执行的时间
  logBeginTime  <- Sys.time()
  ## 2.当天的交易日其
  logTradingDay <- currTradingDay[i, days]
  ## =========================================================================

  ## -------------------------------------------------------------------------
  ## 夜盘
  dataFile <- list.files(dataPath, pattern = '.csv') %>%
        .[grep(paste0("^", coloID[k,csv], "\\.",
                      currTradingDay[, as.character(ymd(nights) + 1) %>% gsub('-','',.)]),
                      .)]
  temp <- strsplit(dataFile,"\\.") %>% unlist() %>% .[c(2,5)] %>% substr(., 9, 10) %>% as.numeric()
  dataFileNight <- dataFile[!is.na(temp) & !(temp %between% c(6, 18))]

  ## 日盘
  dataFile <- list.files(dataPath, pattern = '.csv') %>%
        .[grep(paste0("^", coloID[k,csv], "\\.",
                      currTradingDay[i, days]),
                      .)]
  temp <- strsplit(dataFile,"\\.") %>% unlist() %>% .[c(2,5)] %>% substr(., 9, 10) %>% as.numeric()
  dataFileDay <- dataFile[!is.na(temp) & (temp %between% c(6, 18))]

  ## 当天处理的文件名称
  logDataFile <- ifelse(identical(dataFileNight,character(0)),
                        ##-- 如果当天没有夜盘
                        coloID[k, paste(colo, dataFileDay, sep = '.')],
                        currTradingDay[k, paste(coloID[k, paste(colo, dataFileNight, sep = '.')],
                                                coloID[k, paste(colo, dataFileDay, sep = '.')],
                                                sep = ' :==> ')])
  ## =========================================================================
  source('./R/china_futures_bar/CTPMD/ctpMD2mysql_01_read_data.R')
  source('./R/china_futures_bar/CTPMD/ctpMD2mysql_02_manipulate_data.R')

  dtDaily <- list(dt_allday, dt_day, dt_night) %>% rbindlist()
  fwrite(dtDaily, paste0(dataPath,'/','daily.csv'))
  fwrite(dtMinute, paste0(dataPath,'/','minute.csv'))

  mysql <- mysqlFetch('CiticPublic')
  dbSendQuery(mysql,paste0("DELETE FROM daily",
              " WHERE TradingDay = ", gsub('-','',tradingDay)))
  dbSendQuery(mysql,paste0("DELETE FROM minute",
              " WHERE TradingDay = ", gsub('-','',tradingDay)))
  dbWriteTable(mysql, "daily",
               dtDaily, row.name　=　FALSE, append = T)
  dbWriteTable(mysql, "minute",
               dtMinute, row.name　=　FALSE, append = T)
}

## =============================================================================



## =============================================================================
setwd('/home/fl/myData/')
## vnpy
tradingDays <- c("2017-08-02","2017-08-15")
includeHistory <- TRUE
for (tradingDay in tradingDays) {
  # tradingDay <- "2017-08-02"
  dataPath <- "/home/fl/myData/data/CiticPublic"  %>% paste0(.,'/',tradingDay)
  list.files(dataPath)
  coloSource <- "YY1_FromPC"

  allDataFiles <- list.files(dataPath, pattern = '\\.csv')
  futuresCalendar <- ChinaFuturesCalendar[days == gsub('-','',tradingDay)]
  k <- 1
  ## ===========================================================================
  ## 用于记录日志：Log
  ## 1.程序开始执行的时间
  logBeginTime  <- Sys.time()
  ## 2.当天的交易日其
  logTradingDay <- futuresCalendar[k, days]
  tempHour <- as.numeric(format(Sys.time(), "%H"))
  ## 当天处理的文件名称
  logDataFile   <- ifelse(nchar(futuresCalendar[k,nights]) == 0,
                          ##-- 如果当天没有夜盘
                          futuresCalendar[k, paste0(days,".csv")],
                          futuresCalendar[k, paste(paste0(nights,".csv"),
                                                    paste0(days,".csv"),
                                                    sep = ' :==> ')])
  ## ===========================================================================
  if (class(try(source('./R/vnpyData/vnpyData2mysql_01_read_data.R'))) == 'try-error') {
    next
  }
  source('./R/vnpyData/vnpyData2mysql_02_manipulate_data.R')

  dtDaily <- list(dt_allday, dt_day, dt_night) %>% rbindlist()
  fwrite(dtDaily, paste0(dataPath,'/','daily.csv'))
  fwrite(dtMinute, paste0(dataPath,'/','minute.csv'))

  mysql <- mysqlFetch('CiticPublic')
  dbSendQuery(mysql,paste0("DELETE FROM daily",
              " WHERE TradingDay = ", gsub('-','',tradingDay)))
  dbSendQuery(mysql,paste0("DELETE FROM minute",
              " WHERE TradingDay = ", gsub('-','',tradingDay)))
  dbWriteTable(mysql, "daily",
               dtDaily, row.name　=　FALSE, append = T)
  dbWriteTable(mysql, "minute",
               dtMinute, row.name　=　FALSE, append = T)
}
## =============================================================================
