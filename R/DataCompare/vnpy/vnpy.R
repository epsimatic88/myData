################################################################################
## 数据对比
## vnpy.data VS CiticPublic
################################################################################

rm(list = ls())

setwd('/home/fl/myData')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

coloSource1 <- 'TianMi1_FromPC'
coloSource2 <- 'TianMi1_FromAli'
startDay <- 20171205
endDay   <- 20171205
## =============================================================================
## fetchData
## 获取数据
## -----------------------------------------------------------------------------
fetchData <- function(db, tbl, start, end) {
    mysql <- mysqlFetch(db)
    query <- paste("
    SELECT TradingDay, Sector,
           InstrumentID as id,
           OpenPrice as open,
           HighPrice as high,
           LowPrice as low,
           ClosePrice as close,
           Volume as volume,
           Turnover as turnover,
           SettlementPrice as stl",
    "FROM", tbl,
    "WHERE TradingDay BETWEEN", start,
    "AND", end)

    if (grepl('minute',tbl)) query <- gsub("Sector", 'Minute', query)

    tempRes <- dbGetQuery(mysql, query) %>% as.data.table() %>%
                .[order(TradingDay)]
    return(tempRes)
}
## =============================================================================

## =============================================================================
dtDaily_coloSource1 <- fetchData(db = 'vnpy', tbl = paste0('daily_', coloSource1),
                         start = startDay,
                         end   = endDay)
## =============================================================================


## =============================================================================
dtDaily_coloSource2 <- fetchData(db = 'vnpy', tbl = paste0('daily_', coloSource2),
                         start = startDay,
                         end   = endDay)
## =============================================================================

x <- dtDaily_coloSource1[, unique(id)]
y <- dtDaily_coloSource2[, unique(id)]

x[! x %in% y]
y[! y %in% x]


dt <- merge(dtDaily_coloSource1, dtDaily_coloSource2,
    by = c('TradingDay', 'Sector', 'id'), all = T)

## =============================================================================
dt[, ":="(
    errOpen = (open.x - open.y)/open.y,
    errHigh = (high.x - high.y)/high.y,
    errLow  = (low.x - low.y)/low.y,
    errClose = (close.x - close.y)/close.y,
    errVolume = (volume.x - volume.y)/volume.y,
    errTurnover = (turnover.x - turnover.y)/turnover.y)]

sigValue = 0.001

print("## ------------------------------------------------------------------")
print('## errOpen')
dt[abs(errOpen) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errHigh')
dt[abs(errHigh) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errLow')
dt[abs(errLow) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errClose')
dt[abs(errClose) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errVolume')
dt[abs(errVolume) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errTurnover')
dt[abs(errTurnover) > sigValue]
print("## ------------------------------------------------------------------")
## =============================================================================


## =============================================================================
## vnpy.data
## -----------------------------------------------------------------------------
dtMinute_coloSource1 <- fetchData(db = 'vnpy', tbl = paste0('minute_',coloSource1),
                         start = startDay,
                         end   = endDay)
## =============================================================================

## =============================================================================
## CiticPublic
## -----------------------------------------------------------------------------
dtMinute_coloSource2 <- fetchData(db = 'vnpy', tbl = paste0('minute_',coloSource2),
                         start = startDay,
                         end   = endDay)
## =============================================================================
dt <- merge(dtMinute_coloSource1, dtMinute_coloSource2,
    by = c('TradingDay', 'Minute', 'id'), all = T)

## =============================================================================
dt[, ":="(
    errOpen = (open.x - open.y)/open.y,
    errHigh = (high.x - high.y)/high.y,
    errLow  = (low.x - low.y)/low.y,
    errClose = (close.x - close.y)/close.y,
    errVolume = (volume.x - volume.y)/volume.y,
    errTurnover = (turnover.x - turnover.y)/turnover.y)]

sigValue = 0.001

print("## ------------------------------------------------------------------")
print('## errOpen')
dt[abs(errOpen) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errHigh')
dt[abs(errHigh) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errLow')
dt[abs(errLow) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errClose')
dt[abs(errClose) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errVolume')
dt[abs(errVolume) > sigValue]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errTurnover')
dt[abs(errTurnover) > sigValue]
print("## ------------------------------------------------------------------")
## =============================================================================

mysql <- mysqlFetch('vnpy')
dtTick_coloSource1 <- dbGetQuery(mysql, paste(
  "select * from", paste0("tick_", coloSource1),
  "where TradingDay =", startDay
  )) %>% as.data.table() %>% 
  .[order(NumericRecvTime)]

dtTick_coloSource2 <- dbGetQuery(mysql, paste(
  "select * from", paste0("tick_", coloSource2),
  "where TradingDay =", startDay
  )) %>% as.data.table() %>% 
  .[order(NumericRecvTime)]

cols <- c('OpenInterest','UpperLimitPrice','LowerLimitPrice',
          'DeltaOpenInterest',
          'BidPrice2','BidPrice3','BidPrice4','BidPrice5',
          'BidVolume2','BidVolume3','BidVolume4','BidVolume5',
          'AskPrice2','AskPrice3','AskPrice4','AskPrice5',
          'AskVolume2','AskVolume3','AskVolume4','AskVolume5')
dtTick_coloSource1[, (cols) := NULL]
dtTick_coloSource2[, (cols) := NULL]

dtTick_coloSource1[, UpdateTimeSeq := as.double(1:nrow(.SD)), 
                   by = .(InstrumentID, UpdateTime)]
dtTick_coloSource2[, UpdateTimeSeq := as.double(1:nrow(.SD)), 
                      by = .(InstrumentID, UpdateTime)]

## =============================================================================
dt <- merge(dtTick_coloSource1, dtTick_coloSource2,
    by = c('TradingDay', 'UpdateTime', 'UpdateTimeSeq', 'InstrumentID'), all = T) %>% 
    .[, .SD[order(Turnover.x, Turnover.y)], keyby = .(InstrumentID)]
## =============================================================================
dt[, ":="(
    # errLast = (LastPrice.x - LastPrice.y)/LastPrice.y,
    # errVolume = (Volume.x - Volume.y)/Volume.y,
    # errTurnover = (Turnover.x - Turnover.y)/Turnover.y,
    # errBidPrice1 = (BidPrice1.x - BidPrice1.y)/BidPrice1.y,
    # errBidVolume1 = (BidVolume1.x - BidVolume1.y)/BidVolume1.y,
    # errAskPrice1 = (AskPrice1.x - AskPrice1.y)/AskPrice1.y,
    # errAskVolume1 = (AskVolume1.x - AskVolume1.y)/AskVolume1.y
    ## -------------------------------------------------------------------------
    errLast = (LastPrice.x - LastPrice.y),
    errVolume = (Volume.x - Volume.y),
    errTurnover = (Turnover.x - Turnover.y),
    errBidPrice1 = (BidPrice1.x - BidPrice1.y),
    errBidVolume1 = (BidVolume1.x - BidVolume1.y),
    errAskPrice1 = (AskPrice1.x - AskPrice1.y),
    errAskVolume1 = (AskVolume1.x - AskVolume1.y)
    )]
cols <- colnames(dt)[5:ncol(dt)]
dt[, (cols) := lapply(.SD, function(x){
    ifelse(is.na(x), 0, x)
}), .SDcols = cols]

print("## ------------------------------------------------------------------")
print('## errLast')
dt[errLast != 0]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errVolume')
dt[errVolume!= 0]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errTurnover')
dt[errTurnover != 0]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errBidPrice1')
dt[errBidPrice1 != 0]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errBidVolume1')
dt[errBidVolume1 != 0]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errAskPrice1')
dt[errAskPrice1 != 0]
print("## ------------------------------------------------------------------")

print("## ------------------------------------------------------------------")
print('## errAskVolume1')
dt[errAskVolume1 != 0]
print("## ------------------------------------------------------------------")

temp1 <- dtTick_coloSource1[, .(recdNo = nrow(.SD)), by = .(TradingDay, UpdateTime, InstrumentID)]
temp2 <- dtTick_coloSource2[, .(recdNo = nrow(.SD)), by = .(TradingDay, UpdateTime, InstrumentID)]

temp <- merge(temp1, temp2, by = c('TradingDay', 'UpdateTime', 'InstrumentID'), all = TRUE)
cols <- c('recdNo.x', 'recdNo.y')
temp[, (cols) := lapply(.SD, function(x) {
  ifelse(is.na(x), 0, x)
}), .SDcols = cols]
temp[recdNo.x != recdNo.y]
