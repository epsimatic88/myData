## =============================================================================
## myFread.R
##
## 用于读取数据　csv 文件
##
## 1.FUN: myFreadHFT
## 用于处理　HFT 高频数据
##
## 2.FUN: myFreadBar
## 用于处理　Bar 数据
##
## 3.FUN: myFreadFromDC
## 用于处理　FromDC 的那份数据
##
## Input:
## data.csv
##
## Outpus:
## data.table::dt
## =============================================================================

## =============================================================================
## FUN: myFread
myFreadHFT <- function(x){
  ## -- 如果使用　fread 可以正常读取数据文件
  if(class(try(fread(x, showProgress = FALSE, fill = TRUE, nrows = 10000),
               silent = TRUE))[1] != "try-error"){
    dt <- fread(x, showProgress = FALSE, fill = TRUE,
                select = c('Timestamp','TradingDay','UpdateTime','UpdateMillisec'
                           ,'InstrumentID','LastPrice','Volume','Turnover','OpenInterest'
                           ,'UpperLimitPrice','LowerLimitPrice'
                           ,'BidPrice1','BidVolume1','BidPrice2','BidVolume2'
                           ,'BidPrice3','BidVolume3','BidPrice4','BidVolume4'
                           ,'BidPrice5','BidVolume5'
                           ,'AskPrice1','AskVolume1','AskPrice2','AskVolume2'
                           ,'AskPrice3','AskVolume3','AskPrice4','AskVolume4'
                           ,'AskPrice5','AskVolume5'
                ),
                colClasses = list(character = c("TradingDay","InstrumentID","UpdateTime"),
                                  numeric   = c("Volume","Turnover") )) %>%
      .[grep("^[0-9]{8}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{4,6}$", Timestamp)]
      ## 考虑到部分文件可能使用的　Timestamp 是乱码
  }else{
  ## -- 如果使用　fread 读取失败，则使用　read_csv
    dt <- read_csv(x,
                   col_types = list(TradingDay   = col_character(),
                                    InstrumentID = col_character(),
                                    UpdateTime   = col_character(),
                                    Volume       = col_number(),
                                    Turnover     = col_number())
                   ) %>% as.data.table() %>%
      .[grep("^[0-9]{8}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{4,6}$", Timestamp)] %>%
      .[,.(Timestamp, TradingDay, UpdateTime, UpdateMillisec
           ,InstrumentID,LastPrice
           ,Volume,Turnover,OpenInterest
           ,UpperLimitPrice,LowerLimitPrice
           ,BidPrice1,BidVolume1,BidPrice2,BidVolume2
           ,BidPrice3,BidVolume3,BidPrice4,BidVolume4
           ,BidPrice5,BidVolume5
           ,AskPrice1,AskVolume1,AskPrice2,AskVolume2
           ,AskPrice3,AskVolume3,AskPrice4,AskVolume4
           ,AskPrice5,AskVolume5)]
  }
  ##----------------------------------------------------------------------------
  return(dt)
}


## =============================================================================
## FUN: myFreadBar
## 用于制作 bar
myFreadBar <- function(x){
  ## -- 如果使用　fread 可以正常读取数据文件
  if(class(try(fread(x, showProgress = FALSE, fill = TRUE, nrows = 10000),
               silent = TRUE))[1] != "try-error"){
    dt <- fread(x, showProgress = FALSE, fill = TRUE,
                select = c('Timestamp','TradingDay','UpdateTime','UpdateMillisec'
                           ,'InstrumentID','LastPrice'
                           ,"OpenPrice", "HighestPrice", "LowestPrice","ClosePrice"
                           ,'Volume','Turnover','OpenInterest'
                           ,'SettlementPrice','UpperLimitPrice','LowerLimitPrice'
                           ,'BidPrice1','BidVolume1','BidPrice2','BidVolume2'
                           ,'BidPrice3','BidVolume3','BidPrice4','BidVolume4'
                           ,'BidPrice5','BidVolume5'
                           ,'AskPrice1','AskVolume1','AskPrice2','AskVolume2'
                           ,'AskPrice3','AskVolume3','AskPrice4','AskVolume4'
                           ,'AskPrice5','AskVolume5'
                ),
                colClasses = list(character = c("TradingDay","InstrumentID","UpdateTime"),
                                  numeric   = c("Volume","Turnover") )) %>%
      .[grep("^[0-9]{8}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{4,6}$", Timestamp)]
  }else{
  ## -- 如果使用　fread 读取失败，则使用　read_csv
    dt <- read_csv(x,
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
  ##----------------------------------------------------------------------------
  return(dt)
}

## =============================================================================
## FUN: myFreadBarCTP
## 用于制作 bar
myFreadBarCTP <- function(x){
  ## -- 如果使用　fread 可以正常读取数据文件
  if(class(try(fread(x, showProgress = FALSE, fill = TRUE, nrows = 10000),
               silent = TRUE))[1] != "try-error"){
    dt <- fread(x, showProgress = FALSE, fill = TRUE,
                select = c('TimeStamp','TradingDay','UpdateTime','UpdateMillisec'
                           ,'InstrumentID','LastPrice'
                           ,"OpenPrice", "HighestPrice", "LowestPrice","ClosePrice"
                           ,'Volume','Turnover','OpenInterest'
                           ,'SettlementPrice','UpperLimitPrice','LowerLimitPrice'
                           ,'BidPrice1','BidVolume1','BidPrice2','BidVolume2'
                           ,'BidPrice3','BidVolume3','BidPrice4','BidVolume4'
                           ,'BidPrice5','BidVolume5'
                           ,'AskPrice1','AskVolume1','AskPrice2','AskVolume2'
                           ,'AskPrice3','AskVolume3','AskPrice4','AskVolume4'
                           ,'AskPrice5','AskVolume5'
                ),
                colClasses = list(character = c("TradingDay","InstrumentID","UpdateTime"),
                                  numeric   = c("Volume","Turnover") )) %>%
      .[grep("^[0-9]{8}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{4,6}$", TimeStamp)]
  }else{
  ## -- 如果使用　fread 读取失败，则使用　read_csv
    dt <- read_csv(x,
                   col_types = list(TradingDay   = col_character(),
                                    InstrumentID = col_character(),
                                    UpdateTime   = col_character(),
                                    Volume       = col_number(),
                                    Turnover     = col_number())
    ) %>% as.data.table() %>%
      .[grep("^[0-9]{8}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{4,6}$", TimeStamp)] %>%
      .[,.(TimeStamp, TradingDay, UpdateTime, UpdateMillisec
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
  ##----------------------------------------------------------------------------
  return(dt)
}


## =============================================================================
## FUN: myFreadBar
## 从　DC 那份数据文件读取数据，用于制作　Bar
myFreadFromDC <- function(x){
  ## -- 如果使用　fread 可以正常读取数据文件
  if (class(try(fread(x, showProgress = FALSE, fill = TRUE, nrows = 10000),
               silent = TRUE))[1] != "try-error") {
    dt <- fread(x, showProgress = FALSE, fill = TRUE,
                select = c('TradingDay','UpdateTime','UpdateMillisec'
                           ,'InstrumentID','LastPrice'
                           ,"OpenPrice", "HighestPrice", "LowestPrice","ClosePrice"
                           ,'Volume','Turnover','OpenInterest'
                           ,'SettlementPrice','UpperLimitPrice','LowerLimitPrice'
                           ,'BidPrice1','BidVolume1','BidPrice2','BidVolume2'
                           ,'BidPrice3','BidVolume3','BidPrice4','BidVolume4'
                           ,'BidPrice5','BidVolume5'
                           ,'AskPrice1','AskVolume1','AskPrice2','AskVolume2'
                           ,'AskPrice3','AskVolume3','AskPrice4','AskVolume4'
                           ,'AskPrice5','AskVolume5','AveragePrice'
                ),
                colClasses = list(character = c("TradingDay","InstrumentID","UpdateTime"),
                                  numeric   = c("Volume","Turnover") ))
  } else {
  ## -- 如果使用　fread 读取失败，则使用　read_csv
    dt <- read_csv(x,
                   col_types = list(TradingDay   = col_character(),
                                    InstrumentID = col_character(),
                                    UpdateTime   = col_character(),
                                    Volume       = col_number(),
                                    Turnover     = col_number())
    ) %>% as.data.table() %>%
      .[,.(TradingDay, UpdateTime, UpdateMillisec
           ,InstrumentID,LastPrice
           ,OpenPrice, HighestPrice, LowestPrice,ClosePrice
           ,Volume,Turnover,OpenInterest
           ,SettlementPrice,UpperLimitPrice,LowerLimitPrice
           ,BidPrice1,BidVolume1,BidPrice2,BidVolume2
           ,BidPrice3,BidVolume3,BidPrice4,BidVolume4
           ,BidPrice5,BidVolume5
           ,AskPrice1,AskVolume1,AskPrice2,AskVolume2
           ,AskPrice3,AskVolume3,AskPrice4,AskVolume4
           ,AskPrice5,AskVolume5,AveragePrice)]
  }
  ##----------------------------------------------------------------------------
  return(dt)
}


## =============================================================================
## FUN: myFreadvnpy
myFreadvnpy <- function(x){
  ## -- 如果使用　fread 可以正常读取数据文件
  if(class(try(fread(x, showProgress = FALSE, fill = TRUE, nrows = 100000),
               silent = TRUE))[1] != "try-error"){
    dt <- fread(x, showProgress = FALSE, fill = TRUE,
                select = c('timeStamp','date','time'
                           ,'symbol','lastPrice'
                           ,"openPrice", "highestPrice", "lowestPrice","closePrice"
                           ,'volume','turnover','openInterest'
                           ,'settlementPrice','upperLimit','lowerLimit'
                           ,'bidPrice1','bidVolume1','bidPrice2','bidVolume2'
                           ,'bidPrice3','bidVolume3','bidPrice4','bidVolume4'
                           ,'bidPrice5','bidVolume5'
                           ,'askPrice1','askVolume1','askPrice2','askVolume2'
                           ,'askPrice3','askVolume3','askPrice4','askVolume4'
                           ,'askPrice5','askVolume5'
                ),
                colClasses = list(character = c("date","symbol","time"),
                                  numeric   = c("volume","turnover") )) %>%
      .[grep("^[0-9]{8} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{4,6}$", timeStamp)]
      ## 考虑到部分文件可能使用的　Timestamp 是乱码
  }else{
  ## -- 如果使用　fread 读取失败，则使用　read_csv
    dt <- read_csv(x,
                   col_types = list(timeStamp = col_character(),
                                    date      = col_character(),
                                    symbol    = col_character(),
                                    time      = col_character(),
                                    volume    = col_number(),
                                    turnover  = col_number())
                   ) %>% as.data.table() %>%
      .[grep("^[0-9]{8} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{4,6}$", timeStamp)] %>%
      .[,.(timeStamp, date, time
           ,symbol,lastPrice
           ,openPrice,highestPrice,lowestPrice,closePrice
           ,volume,turnover,openInterest
           ,settlementPrice,upperLimit,lowerLimit
           ,bidPrice1,bidVolume1,bidPrice2,bidVolume2
           ,bidPrice3,bidVolume3,bidPrice4,bidVolume4
           ,bidPrice5,bidVolume5
           ,askPrice1,askVolume1,askPrice2,askVolume2
           ,askPrice3,askVolume3,askPrice4,askVolume4
           ,askPrice5,askVolume5)]
  }
  ##----------------------------------------------------------------------------
  return(dt)
}


## =============================================================================
## 处理 FromDC 数据
## =============================================================================
## =============================================================================
readDataFile <- function(xDay) {
    if ( xDay %in% list.files(paste0(dataPath,'/',yearID)) ) {
        allDataFile <- list.files(paste(dataPath, yearID, xDay, sep='/')) %>%
                        .[grep("\\.txt || \\.csv", .)]
        ## ---------------------------------------------------------------------
        res <- lapply(1:length(allDataFile), function(i){
                tempDataPath <- paste(dataPath, yearID, xDay, allDataFile[i], sep='/')
                if (yearID == '2010') {
                    tempInstrumentID <- gsub('\\.csv','',allDataFile[i])
                    # suppressWarnings(
                    #     suppressMessages({
                    #         tempRes <- read_csv(tempDataPath, locale=locale(encoding='GB18030'),
                    #                             progress = FALSE) %>% as.data.table()
                    #     })
                    # )
                    if (any(class(try(
                        tempRes <- suppFunction(fread(tempDataPath, 
                                                      encoding = 'unknown'))
                        )) == 'try-error')) {
                                tempRes <- suppFunction(read_csv(tempDataPath, 
                                  locale = locale(encoding='GB18030'),
                                  progress = FALSE)) %>% as.data.table()
                    }
                    tempRes[, InstrumentID := tempInstrumentID]
                } else {
                    tempRes <- myFreadFromDC(tempDataPath)
                    ## ---------------------------------------------------------
                    ## 郑商所有时候会抽风，以下代码专治郑商所
                    ## eg, 2013-05-30 把第二天的数据放在了昨天
                    ## eg, 2012-09-21
                    if (length(unique(tempRes$TradingDay)) == 1) {
                      if (length(unique(tempRes$UpperLimitPrice)) == 2) {
                        if (nrow(tempRes[UpperLimitPrice == unique(tempRes$UpperLimitPrice)[1]]) >=
                            nrow(tempRes[UpperLimitPrice == unique(tempRes$UpperLimitPrice)[2]])) {
                          tempRes <- tempRes[UpperLimitPrice == unique(tempRes$UpperLimitPrice)[1]]
                        } else {
                          tempRes <- tempRes[UpperLimitPrice == unique(tempRes$UpperLimitPrice)[2]]
                        }
                      }
                    } else {
                      if (length(unique(tempRes$TradingDay)) == 2) {
                        if (nrow(tempRes[TradingDay == unique(tempRes$TradingDay)[1]]) >=
                            nrow(tempRes[TradingDay == unique(tempRes$TradingDay)[2]]) |
                            nrow(tempRes[TradingDay == unique(tempRes$TradingDay)[1]][grepl('14:5.',UpdateTime)]) != 0) {
                          tempRes <- tempRes[TradingDay == unique(tempRes$TradingDay)[1]]
                        } else {
                          tempRes <- tempRes[TradingDay == unique(tempRes$TradingDay)[2]]
                        }
                      }
                    }
                    ## ---------------------------------------------------------
                }
                if (yearID == '2010') {
                    if (nrow(tempRes) != 0 & 'V11' %in% colnames(tempRes)) {
                      tempRes[, ":="(V10 = as.numeric(V10),
                                     V11 = as.numeric(V11))]
                      try(tempRes[, V19 := NULL])
                    } else {
                      tempRes <- data.table()
                    }
                }
                return(tempRes)
                }) %>% rbindlist()
        ## ---------------------------------------------------------------------
        if (as.numeric(yearID) == 2010) {
            colnames(res) <- c('TradingDay','Date','UpdateTime',
                               'LastPrice','OpenPrice','HighestPrice','LowestPrice',
                               'PreClosePrice',
                               'Volume','DeltaVolume',
                               'Turnover','DeltaTurnover',
                               'OpenInterest','DeltaOpenInterest',
                               'BidPrice1','BidVolume1',
                               'AskPrice1','AskVolume1',
                               'InstrumentID')
            res[, ':='(
                PreClosePrice = NULL,
                Date = NULL,
                DeltaVolume = NULL,
                DeltaTurnover = NULL,
                DeltaOpenInterest = NULL,
                UpdateTime = paste(sprintf("%09.f", as.numeric(UpdateTime)) %>% substr(.,1,2),
                                   sprintf("%09.f", as.numeric(UpdateTime)) %>% substr(.,3,4),
                                   sprintf("%09.f", as.numeric(UpdateTime)) %>% substr(.,5,6),
                                   sep=':'),
                UpdateMillisec = sprintf("%09.f", as.numeric(UpdateTime)) %>% substr(.,7,9),
                ClosePrice = 0,
                SettlementPrice = 0,
                UpperLimitPrice = 0,
                LowerLimitPrice = 0,
                ## -----------------------------
                BidPrice2 = 0, BidVolume2 = 0,
                BidPrice3 = 0, BidVolume3 = 0,
                BidPrice4 = 0, BidVolume4 = 0,
                BidPrice5 = 0, BidVolume5 = 0,
                ## -----------------------------
                AskPrice2 = 0, AskVolume2 = 0,
                AskPrice3 = 0, AskVolume3 = 0,
                AskPrice4 = 0, AskVolume4 = 0,
                AskPrice5 = 0, AskVolume5 = 0
                )]
            setcolorder(res,
                c('TradingDay','UpdateTime','UpdateMillisec','InstrumentID',
                  'LastPrice','OpenPrice','HighestPrice','LowestPrice','ClosePrice',
                  'Volume','Turnover','OpenInterest','SettlementPrice',
                  'UpperLimitPrice','LowerLimitPrice',
                  'BidPrice1','BidVolume1',
                  'BidPrice2','BidVolume2',
                  'BidPrice3','BidVolume3',
                  'BidPrice4','BidVolume4',
                  'BidPrice5','BidVolume5',
                  'AskPrice1','AskVolume1',
                  'AskPrice2','AskVolume2',
                  'AskPrice3','AskVolume3',
                  'AskPrice4','AskVolume4',
                  'AskPrice5','AskVolume5'
                  ))
        }
        ## ---------------------------------------------------------------------
    } else {
        res <- data.table()
    }
    ## -------------------------------------------------------------------------
    return(res)
    ## -------------------------------------------------------------------------
}
## =============================================================================
