rm(list = ls())

suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})

print(currTradingDay)
print(lastTradingDay)


# fundID <- "TianMi3"
fundID <- "HanFeng"

dtSignal <- mysqlQuery(db = fundID,
                       query = "select * from tradingSignal")
print(dtSignal)

dtPositionInfo <- mysqlQuery(db = fundID,
                             query = "select * from positionInfo")
print(dtPositionInfo)


dtFailedInfo <- data.table(strategyID = '',
                           InstrumentID = '',
                           TradingDay = '',
                           direction = '',
                           offset = '',
                           volume = 0)
print(dtFailedInfo)

for (i in 1:nrow(dtPositionInfo)) {
  tempInstrumentID <- dtPositionInfo[i, InstrumentID]
  tempDirection <- ifelse(dtPositionInfo[i, InstrumentID] == 'long', 1, -1)

  if (tempInstrumentID %in% dtSignal$InstrumentID) {
    tempSignal <- dtSignal[InstrumentID == tempInstrumentID]

    if (tempDirection == tempSignal[1, direction]) {
      diffVolume <- dtPositionInfo[i, volume] - tempSignal[1, volume]
      if (diffVolume >= 0) {
        res <- dtPositionInfo[i, .(strategyID, InstrumentID = tempInstrumentID,
                                   TradingDay, direction = ifelse(tempDirection == 'long', 'short', 'long'),
                                   offset = '平仓',
                                   volume = abs(diffVolume))]
        dtFailedInfo <- rbind(dtFailedInfo, res)
        dtPositionInfo[i, ":="(
          volume = tempSignal[1,volume],
          TradingDay = currTradingDay[1,days]
        )]
      } else {
        dtPositionInfo[i, ":="(
          TradingDay = currTradingDay[1,days]
        )]
      }
    } else {
      res <- dtPositionInfo[i, .(strategyID, InstrumentID,
                                 TradingDay, direction = ifelse(tempDirection == 'long', 'short', 'long'),
                                 offset = '平仓',
                                 volume)]
      dtFailedInfo <- rbind(dtFailedInfo, res)
    }
  } else {
    res <- dtPositionInfo[i, .(strategyID, InstrumentID,
                               TradingDay, direction = ifelse(tempDirection == 'long', 'short', 'long'),
                               offset = '平仓',
                               volume)]
    dtFailedInfo <- rbind(dtFailedInfo, res)
  }

}

dtFailedInfo <- dtFailedInfo[volume != 0]
dtPositionInfo <- dtPositionInfo[TradingDay == currTradingDay[1,days]]

print(dtSignal)
print(dtFailedInfo)
print(dtPositionInfo)

mysql <- mysqlFetch(db = fundID)
dbSendQuery(mysql, "truncate table positionInfo")
dbWriteTable(mysql, 'positionInfo', dtPositionInfo, row.name = F, append = T)

dbSendQuery(mysql, "truncate table failedInfo")
dbWriteTable(mysql, 'failedInfo', dtFailedInfo, row.name = F, append = T)



