## =============================================================================
## start.R
## 在开盘的时候跑脚本
## 处理不同策略的订单
## =============================================================================

# if (! as.numeric(format(Sys.time(),'%H')) %in% c(8,9,20,21)) {
#   stop("不是开盘时间哦！！！")
# }

rm(list = ls())
accountDB = 'TianMi1'

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  # source('./R/Rconfig/myFread.R')
  # source('./R/Rconfig/myDay.R')
  # source('./R/Rconfig/myBreakTime.R')
  # source('./R/Rconfig/dt2DailyBar.R')
  # source('./R/Rconfig/dt2MinuteBar.R')
})

ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days")))

## 计算交易日历
if (as.numeric(format(Sys.time(),'%H')) < 17) {
  currTradingDay <- ChinaFuturesCalendar[days <= format(Sys.Date(),'%Y%m%d')][.N]
} else {
  currTradingDay <- ChinaFuturesCalendar[nights <= format(Sys.Date(),'%Y%m%d')][.N]
}
lastTradingday <- ChinaFuturesCalendar[days < currTradingDay[.N, days]][.N]

## =============================================================================
## 从 MySQL 数据库提取数据
## =============================================================================
mysql <- mysqlFetch(accountDB, host = '192.168.1.166')
dbSendQuery(mysql,"truncate table tradingOrders;")
# dbListTables(mysql)

tempPosInfo <- dbGetQuery(mysql, "
                          select * from positionInfo
                          where strategyID = 'YYStrategy'
                          ") %>% as.data.table()

if (nrow(tempPosInfo) != 0){
  YYpositionInfo <- tempPosInfo %>%
    .[, TradingDay := ymd(TradingDay)] %>%
    .[, holdingDays := lapply(1:.N, function(i){
      tempRes <- ChinaFuturesCalendar[days %between% c(.SD[i, format(TradingDay,'%Y%m%d')],
                                                       currTradingDay[1,days])]
      return(nrow(tempRes) - 1)
    })] %>% .[holdingDays >= 5]
  YYpositionInfoToday <- tempPosInfo[gsub('-','',TradingDay) == currTradingDay[1,days]]
} else {
  YYpositionInfo <- data.table()
  YYpositionInfoToday <- data.table()
}

OIpositionInfo <- dbGetQuery(mysql, paste0("
                                           select * from positionInfo
                                           where strategyID = 'OIStrategy'
                                           and TradingDay = ",currTradingDay[1,days])) %>% as.data.table()
if (nrow(OIpositionInfo) != 0) {
  OIpositionInfo[, TradingDay := ymd(TradingDay)]
} else {
  OIpositionInfo <- data.table()
}


mysql <- mysqlFetch(accountDB, host = '192.168.1.166')
# dbListTables(mysql)

YYopenInfo <- dbGetQuery(mysql, paste("
                                      select * from signal
                                      where strategyID = 'YYStrategy'
                                      and TradingDay = ", paste0("'",lastTradingday[1,as.character(ymd(days))]),"'")
) %>% as.data.table() %>%
  .[, direction := ifelse(direction == 1, 'long', 'short')] %>%
  .[, TradingDay := NULL] %>%
  .[, TradingDay := ymd(currTradingDay[1,days])] %>%
  .[, strategyID := 'YYStrategy']
if ((nrow(YYopenInfo) != 0) & (nrow(YYpositionInfoToday) != 0)) {
  for (i in 1:nrow(YYopenInfo)) {
    tempInfo <- YYpositionInfoToday[InstrumentID == YYopenInfo[i,InstrumentID]][direction == YYopenInfo[i,direction]]
    if (nrow(tempInfo) != 0) {
      YYopenInfo[i]$volume <- YYopenInfo[i]$volume - tempInfo[1,volume]
    }
  }
}

if (nrow(YYopenInfo) != 0) {
  YYopenInfo <- YYopenInfo[volume != 0]
} else {
  YYopenInfo <- data.table()
}



OIopenInfo <- dbGetQuery(mysql, paste("
                                      select * from signal
                                      where strategyID = 'OIStrategy'
                                      and TradingDay = ",  paste0("'",lastTradingday[1,as.character(ymd(days))]),"'")
) %>% as.data.table() %>%
  .[, direction := ifelse(direction == 1, 'long', 'short')] %>%
  .[, TradingDay := NULL] %>%
  .[, TradingDay := ymd(currTradingDay[1,days])] %>%
  .[, strategyID := 'OIStrategy']
if (nrow(OIpositionInfo) != 0) {
  for (i in 1:nrow(OIopenInfo)) {
    tempInfo <- OIpositionInfo[InstrumentID == OIopenInfo[i,InstrumentID]][direction == OIopenInfo[i,direction]]
    if (nrow(tempInfo) != 0) {
      OIopenInfo[i]$volume <- OIopenInfo[i]$volume - tempInfo[1,volume]
    }
  }
}

if (nrow(OIopenInfo) != 0) {
  OIopenInfo <- OIopenInfo[volume != 0]
} else {
  OIopenInfo <- data.table()
}

## =============================================================================
## 1. 先处理开盘的订单
## =============================================================================
mysql <- mysqlFetch(accountDB, host = '192.168.1.166')

if (nrow(YYpositionInfo) != 0) {
  if (nrow(OIopenInfo) != 0) {
    dtStart <- merge(YYpositionInfo, OIopenInfo,
                     by = c('InstrumentID','direction'), all = TRUE) %>%
      .[, ":="(volume.x = ifelse(is.na(volume.x), 0, volume.x),
               volume.y = ifelse(is.na(volume.y), 0, volume.y))] %>%
      .[, deltaVolume := volume.x - volume.y] %>%
      .[, holdingDays := NULL]
    dtStart

    ## -------------------------------------------------------------------------
    ## 需要更改 strategyID
    ## -------------------------------------------------------------------------
    dtUpdateStrategyID <- dtStart[volume.x != 0 & volume.y != 0]
    if (nrow(dtUpdateStrategyID) != 0) {
      mysql <- mysqlFetch(accountDB)
      for (i in 1:nrow(dtUpdateStrategyID)) {
        if (dtUpdateStrategyID[i, deltaVolume] <= 0) {
          ## -------------------------------------------------------------
          ## 如果持仓不够
          ## 则全部改 ID
          ## -------------------------------------------------------------
          sql <- paste("update positionInfo
                       set strategyID = 'OIStrategy',
                       TradingDay = ",currTradingDay[1,days],
                       "where strategyID = 'YYStrategy'",
                       "and TradingDay = ", dtUpdateStrategyID[i, gsub('-','',TradingDay.x)],
                       "and InstrumentID = ", paste0("'",dtUpdateStrategyID[i,InstrumentID],"'")
          )
          dbSendQuery(mysql,sql)

          ## -------------------------------------------------------------
          ## 把交易的信息写入 tradingInfo
          ## -------------------------------------------------------------
          tempResYY <- data.table(strategyID = 'YYStrategy',
                                  InstrumentID = dtUpdateStrategyID[i,InstrumentID],
                                  TradingDay = currTradingDay[1,days],
                                  tradeTime = format(Sys.time(),'%Y-%m-%d %H:%M:%S'),
                                  direction = ifelse(dtUpdateStrategyID[i,direction == 'long'],
                                                     'short', 'long'),
                                  offset = '平仓',
                                  volume = dtUpdateStrategyID[i,volume.x],
                                  price = -1)
          tempResOI <- data.table(strategyID = 'OIStrategy',
                                  InstrumentID = dtUpdateStrategyID[i,InstrumentID],
                                  TradingDay = currTradingDay[1,days],
                                  tradeTime = format(Sys.time(),'%Y-%m-%d %H:%M:%S'),
                                  direction = dtUpdateStrategyID[i,direction],
                                  offset = '开仓',
                                  volume = dtUpdateStrategyID[i,volume.x],
                                  price = 1)

          dbWriteTable(mysql, 'tradingInfo',
                       rbind(tempResYY, tempResOI), row.names = FALSE, append = TRUE)
        } else {
          ## -----------------------------------------------------------------
          ## 如果持仓足够
          ## 则全部改 ID
          ## -----------------------------------------------------------------
          # sql <- paste("update positionInfo
          #   set volume = ",dtUpdateStrategyID[i, deltaVolume],
          #   ", strategyID = 'OIStrategy',
          #   TradingDay = ",currTradingDay[1,days],
          #   "where strategyID = 'YYStrategy'
          #   and InstrumentID = ", paste0("'",dtUpdateStrategyID[i,InstrumentID],"'",
          #   "and TradingDay = ", dtUpdateStrategyID[i, gsub('-','',TradingDay.x)])
          #   )
          # dbSendQuery(mysql, sql)

          # tempRes <- dtUpdateStrategyID[i,.(strategyID = strategyID.x,InstrumentID,
          #                                  TradingDay = TradingDay.y,
          #                                  direction,
          #                                  volume = volume.y)]
          # sql <- paste("delete from positionInfo
          #                           where strategyID = 'YYStrategy'
          #                           and InstrumentID = ", paste0("'",tempRes[1,InstrumentID],"'"),
          #                           "and TradingDay = ", tempRes[1,gsub('-','',TradingDay)],
          #                           "and direction = ", paste0("'",tempRes[1,direction],"'"))
          # dbSendQuery(mysql, sql)
          # dbWriteTable(mysql, 'positionInfo',
          #             tempRes, row.names = FALSE, append = TRUE)

          ## -------------------------------------------------------------
          sql <- paste("update positionInfo
                       set volume = ",dtUpdateStrategyID[i, deltaVolume],
                       "where strategyID = 'YYStrategy'
                       and InstrumentID = ", paste0("'",dtUpdateStrategyID[i,InstrumentID],"'"),
                       "and TradingDay = ", dtUpdateStrategyID[i, gsub('-','',TradingDay.x)],
                       "and direction = ", paste0("'",dtUpdateStrategyID[i,direction],"'")
          )
          dbSendQuery(mysql, sql)

          tempRes <- dtUpdateStrategyID[i,.(strategyID = strategyID.y, InstrumentID,
                                            TradingDay = TradingDay.y,
                                            direction,
                                            volume = volume.y)]
          dbWriteTable(mysql, 'positionInfo',
                       tempRes, row.names = FALSE, append = TRUE)

          ## -------------------------------------------------------------
          ## 把交易的信息写入 tradingInfo
          ## -------------------------------------------------------------
          tempResYY <- data.table(strategyID = 'YYStrategy',
                                  InstrumentID = dtUpdateStrategyID[i,InstrumentID],
                                  TradingDay = currTradingDay[1,days],
                                  tradeTime = format(Sys.time(),'%Y-%m-%d %H:%M:%S'),
                                  direction = ifelse(dtUpdateStrategyID[i,direction == 'long'],
                                                     'short', 'long'),
                                  offset = '平仓',
                                  volume = dtUpdateStrategyID[i,volume.y],
                                  price = -1)
          tempResOI <- data.table(strategyID = 'OIStrategy',
                                  InstrumentID = dtUpdateStrategyID[i,InstrumentID],
                                  TradingDay = currTradingDay[1,days],
                                  tradeTime = format(Sys.time(),'%Y-%m-%d %H:%M:%S'),
                                  direction = dtUpdateStrategyID[i,direction],
                                  offset = '开仓',
                                  volume = dtUpdateStrategyID[i,volume.y],
                                  price = 1)

          dbWriteTable(mysql, 'tradingInfo',
                       rbind(tempResYY, tempResOI), row.names = FALSE, append = TRUE)
        }
      }
    }

    dtCloseYY <- dtStart[deltaVolume > 0]
    dtOpenOI <- dtStart[deltaVolume < 0] %>%
      .[,":="(TradingDay = currTradingDay[1,days],
              strategyID = 'OIStrategy',
              orderType = ifelse(direction == 'long', 'buy', 'short'),
              volume = abs(deltaVolume),
              stage = 'open')]
    tempRes <- dtOpenOI[,.(TradingDay,strategyID,InstrumentID,
                           orderType,volume,stage)]
    mysql <- mysqlFetch(accountDB)
    dbSendQuery(mysql, paste("
                             delete from tradingOrders where strategyID = ",
                             paste0("'","OIStrategy","'"),
                             "and stage = ",
                             paste0("'","open","'"),
                             "and TradingDay = ", currTradingDay[1,days]))
    dbWriteTable(mysql, 'tradingOrders',
                 tempRes, row.names = FALSE, append = TRUE)
  } else {
    ## 只有 YYStrategy 开盘需要处理平仓的订单
    tempRes <- YYpositionInfo[,.(TradingDay = currTradingDay[1,days],strategyID,
                                 InstrumentID,orderType = ifelse(direction == 'long','sell','cover'),
                                 volume,stage = 'close')]
    mysql <- mysqlFetch(accountDB)
    dbSendQuery(mysql, paste("
                             delete from tradingOrders where strategyID = ",
                             paste0("'","YYStrategy","'"),
                             "and stage = ",
                             paste0("'","close","'"),
                             "and TradingDay = ", currTradingDay[1,days]))
    dbWriteTable(mysql, 'tradingOrders',
                 tempRes, row.names = FALSE, append = TRUE)
  }
} else {
  if (nrow(OIopenInfo) != 0) {
    tempRes <- OIopenInfo[,.(TradingDay,strategyID,InstrumentID,
                             orderType = ifelse(direction == 'long','buy','short'),
                             volume,stage = 'open')]
    mysql <- mysqlFetch(accountDB)
    dbSendQuery(mysql, paste("
                             delete from tradingOrders where strategyID = ",
                             paste0("'","OIStrategy","'"),
                             "and stage = ",
                             paste0("'","open","'"),
                             "and TradingDay = ", currTradingDay[1,days]))
    dbWriteTable(mysql, 'tradingOrders',
                 tempRes, row.names = FALSE, append = TRUE)
  } else {
    NULL
  }
}





## =============================================================================
## 2. 在 YYStrategy 内部先计算开仓、平仓情况
## =============================================================================
if (nrow(YYpositionInfo) != 0) {
  if (nrow(OIopenInfo) != 0) {
    if (nrow(YYopenInfo) != 0) {
      dtYY <- merge(dtCloseYY[,.(strategyID = strategyID.x, InstrumentID,
                                 TradingDay = TradingDay.x, direction,
                                 volume = deltaVolume)],
                    YYopenInfo,
                    by = c('InstrumentID','direction'),
                    all = TRUE)
    } else {
      dtYY <- dtCloseYY
    }
  } else {
    if (nrow(YYopenInfo) != 0) {
      dtYY <- merge(YYpositionInfo,YYopenInfo,
                    by = c('InstrumentID','direction'),
                    all = TRUE)
    } else {
      dtYY <- dtCloseYY
    }
  }

  dtYY[, ":="(volume.x = ifelse(is.na(volume.x), 0, volume.x),
              volume.y = ifelse(is.na(volume.y), 0, volume.y))] %>%
    .[, deltaVolume := volume.x - volume.y]
  print(dtYY)

  ## 开盘的 tradingOrdersOpen
  dtYYtradingOrdersClose <- dtYY[deltaVolume > 0]
  dtYYtradingOrdersClose[,":="(TradingDay = currTradingDay[1,days],
                               strategyID = strategyID.x,
                               orderType = ifelse(direction == 'long', 'sell', 'cover'),
                               volume = deltaVolume,
                               stage = 'close')]
  tempRes <- dtYYtradingOrdersClose[,.(TradingDay,strategyID,InstrumentID,
                                       orderType,volume,stage)]
  mysql <- mysqlFetch(accountDB)
  dbSendQuery(mysql, paste("
                           delete from tradingOrders where strategyID = ",
                           paste0("'","YYStrategy","'"),
                           "and stage = ",
                           paste0("'","close","'"),
                           "and TradingDay = ", currTradingDay[1,days]))
  dbWriteTable(mysql, 'tradingOrders',
               tempRes, row.names = FALSE, append = TRUE)



  ## 更改 TradingDay
  dtUpdateTradingDay <- dtYY[volume.x != 0 & volume.y != 0] %>%
    .[,":="(strategyID = 'YYStrategy',
            TradingDay = currTradingDay[1,days])]
  mysql <- mysqlFetch(accountDB)
  if (nrow(dtUpdateTradingDay) != 0) {
    for (i in 1:nrow(dtUpdateTradingDay)) {
      if (dtUpdateTradingDay[i, deltaVolume] <= 0) {
        sql <- paste("update positionInfo
                     set TradingDay = ",currTradingDay[1,days],
                     "where strategyID = 'YYStrategy'
                     and InstrumentID = ", paste0("'",dtUpdateTradingDay[i,InstrumentID],"'"),
                     "and TradingDay = ", paste0("'",dtUpdateTradingDay[i,gsub('-','',TradingDay.x)],"'"),
                     "and direction = ", paste0("'",dtUpdateTradingDay[i,direction],"'")
        )
        dbSendQuery(mysql, sql)

        ## -------------------------------------------------------------
        ## 把交易的信息写入 tradingInfo
        ## -------------------------------------------------------------
        tempResClose <- data.table(strategyID = 'YYStrategy',
                                   InstrumentID = dtUpdateTradingDay[i,InstrumentID],
                                   TradingDay = currTradingDay[1,days],
                                   tradeTime = format(Sys.time(),'%Y-%m-%d %H:%M:%S'),
                                   direction = ifelse(dtUpdateTradingDay[i,direction == 'long'],
                                                      'short', 'long'),
                                   offset = '平仓',
                                   volume = dtUpdateTradingDay[i,volume.x],
                                   price = -1)
        tempResOpen <- data.table(strategyID = 'YYStrategy',
                                  InstrumentID = dtUpdateTradingDay[i,InstrumentID],
                                  TradingDay = currTradingDay[1,days],
                                  tradeTime = format(Sys.time(),'%Y-%m-%d %H:%M:%S'),
                                  direction = dtUpdateTradingDay[i,direction],
                                  offset = '开仓',
                                  volume = dtUpdateTradingDay[i,volume.x],
                                  price = 1)

        dbWriteTable(mysql, 'tradingInfo',
                     rbind(tempResClose, tempResOpen), row.names = FALSE, append = TRUE)
      } else {
        # sql <- paste("update positionInfo
        #   set volume = ",dtUpdateTradingDay[i, deltaVolume],
        #   "where strategyID = 'YYStrategy'
        #   and InstrumentID = ", paste0("'",dtUpdateTradingDay[i,InstrumentID],"'",
        #   "and TradingDay = ", dtUpdateTradingDay[i, gsub('-','',TradingDay.x)]),
        #   "and direction = ", paste0("'",dtUpdateTradingDay[i,direction],"'")
        #   )
        # dbSendQuery(mysql, sql)

        # tempRes <- dtUpdateTradingDay[i,.(strategyID,InstrumentID,
        #                                                  TradingDay = TradingDay.y,
        #                                                  direction,
        #                                                  volume = volume.y)]
        # sql <- paste("delete from positionInfo
        #                           where strategyID = 'YYStrategy'
        #                           and InstrumentID = ", paste0("'",tempRes[1,InstrumentID],"'"),
        #                           "and TradingDay = ", tempRes[1,gsub('-','',TradingDay)],
        #                           "and direction = ", paste0("'",tempRes[1,direction],"'"))
        # dbSendQuery(mysql, sql)
        # dbWriteTable(mysql, 'positionInfo',
        #             tempRes, row.names = FALSE, append = TRUE)

        ## -------------------------------------------------------------
        ## 把交易的信息写入 tradingInfo
        ## -------------------------------------------------------------
        sql <- paste("update positionInfo
                     set volume = ",dtUpdateTradingDay[i, deltaVolume],
                     "where strategyID = 'YYStrategy'
                     and InstrumentID = ", paste0("'",dtUpdateTradingDay[i,InstrumentID],"'"),
                     "and TradingDay = ", dtUpdateTradingDay[i, gsub('-','',TradingDay.x)],
                     "and direction = ", paste0("'",dtUpdateTradingDay[i,direction],"'")
        )
        dbSendQuery(mysql, sql)

        tempRes <- dtUpdateTradingDay[i,.(strategyID = strategyID.y, InstrumentID,
                                          TradingDay = TradingDay.y,
                                          direction,
                                          volume = volume.y)]
        dbWriteTable(mysql, 'positionInfo',
                     tempRes, row.names = FALSE, append = TRUE)
        ## -------------------------------------------------------------
        ## 把交易的信息写入 tradingInfo
        ## -------------------------------------------------------------
        tempResClose <- data.table(strategyID = 'YYStrategy',
                                   InstrumentID = dtUpdateTradingDay[i,InstrumentID],
                                   TradingDay = currTradingDay[1,days],
                                   tradeTime = format(Sys.time(),'%Y-%m-%d %H:%M:%S'),
                                   direction = ifelse(dtUpdateTradingDay[i,direction == 'long'],
                                                      'short', 'long'),
                                   offset = '平仓',
                                   volume = dtUpdateTradingDay[i,volume.y],
                                   price = -1)
        tempResOpen <- data.table(strategyID = 'YYStrategy',
                                  InstrumentID = dtUpdateTradingDay[i,InstrumentID],
                                  TradingDay = currTradingDay[1,days],
                                  tradeTime = format(Sys.time(),'%Y-%m-%d %H:%M:%S'),
                                  direction = dtUpdateTradingDay[i,direction],
                                  offset = '开仓',
                                  volume = dtUpdateTradingDay[i,volume.y],
                                  price = 1)

        dbWriteTable(mysql, 'tradingInfo',
                     rbind(tempResClose, tempResOpen), row.names = FALSE, append = TRUE)
      }
    }
  }

  ## 收盘的 tradingOrdersClose
  dtYYtradingOrdersOpen <- dtYY[deltaVolume < 0]
  dtYYtradingOrdersOpen[,":="(TradingDay = currTradingDay[1,days],
                              strategyID = "YYStrategy",
                              orderType = ifelse(direction == 'long', 'buy', 'short'),
                              volume = abs(deltaVolume),
                              stage = 'open')]
  tempRes <- dtYYtradingOrdersOpen[,.(TradingDay,strategyID,InstrumentID,
                                      orderType,volume,stage)]
  if (nrow(tempRes) != 0) {
    mysql <- mysqlFetch(accountDB)
    dbSendQuery(mysql, paste("
                             delete from tradingOrders where strategyID = ",
                             paste0("'","YYStrategy","'"),
                             "and stage = ",
                             paste0("'","open","'"),
                             "and TradingDay = ", currTradingDay[1,days]))
    dbWriteTable(mysql, 'tradingOrders',
                 tempRes, row.names = FALSE, append = TRUE)
  }
  ## =============================================================================
  ## 1. 在 OIStrategy 内部先计算开仓、平仓情况
  ## =============================================================================


} else {
  if (nrow(YYopenInfo) != 0) {
    tempRes <- YYopenInfo[,.(TradingDay,strategyID,InstrumentID,
                             orderType = ifelse(direction == 'long','buy','short'),
                             volume,stage = 'open')]
    mysql <- mysqlFetch(accountDB)
    dbSendQuery(mysql, paste("
        delete from tradingOrders where strategyID = ",
                             paste0("'","YYStrategy","'"),
                             "and stage = ",
                             paste0("'","open","'"),
                             "and TradingDay = ", currTradingDay[1,days]))
    dbWriteTable(mysql, 'tradingOrders',
                 tempRes, row.names = FALSE, append = TRUE)
  } else {
    NULL
  }
}


mysql <- mysqlFetch(accountDB)
sql <- "delete from tradingOrders
        where volume = 0;"
dbSendQuery(mysql, sql)
