################################################################################
##! vnpyData2mysql_05_info.R
## 这是主函数:
## 用于录入 vnpyData 的数据到 MySQL 数据库
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-08-24
################################################################################

################################################################################
## 读取合约信息
################################################################################
print(paste0("#---------- WRITTING info INTO MySQL -----------------------------#"))

readInfo <- function(dataFile) {
  res <- read_csv(dataFile) %>%
    as.data.table() %>%
    .[, ":="(
      vtSymbol = NULL,
      gatewayName = NULL,
      TradingDay = logTradingDay)]
}

dataPathInfo <- dataPath  %>%
    gsub('TickData$', 'ContractInfo', .)
allDataFilesInfo <- list.files(dataPathInfo, pattern = '\\.csv')

if (logTradingDay <= '20171128') {
  suppressMessages({
    if (futuresCalendar[k, nchar(nights) < 1 | is.na(nights)]) {
      dtInfoNight <- data.table()
    } else {
      dtInfoNight <- grep(futuresCalendar[k,nights], allDataFilesInfo, value = T) %>%
        paste(dataPathInfo, ., sep = '/') %>%
        readInfo()
    }

    dtInfoDay <- grep(futuresCalendar[k,days], allDataFilesInfo, value = T) %>%
      paste(dataPathInfo, ., sep = '/') %>%
      readInfo()
  })
  dtInfo <- rbind(dtInfoNight, dtInfoDay) %>% .[!duplicated(symbol)]
} else {
  suppressMessages({
    dtInfo <- grep(futuresCalendar[k,days], allDataFilesInfo, value = T) %>%
      paste(dataPathInfo, ., sep = '/') %>% 
      readInfo()
  })
}

colnames(dtInfo) <- c('InstrumentID','InstrumentName','ProductClass','ExchangeID',
                      'PriceTick','VolumeMultiple','ShortMarginRatio','LongMarginRatio',
                      'OptionType','Underlying','StrikePrice','TradingDay')
setcolorder(dtInfo, c('TradingDay',colnames(dtInfo)[1:(ncol(dtInfo)-1)]))

## =============================================================================
mysql <- mysqlFetch('vnpy', host = '192.168.1.166')
dbSendQuery(mysql,paste0("DELETE FROM info_",coloSource,
             " WHERE TradingDay = ", logTradingDay))
dbWriteTable(mysql, paste0("info_",coloSource),
             dtInfo, row.name　=　FALSE, append = T)
print(paste0("#---------- Info has already been written in MySQL!!! ------------#"))
## =============================================================================

resInfo <- dtInfo[,.(TradingDay,InstrumentID,ExchangeID,
                     ProductID = gsub('[0-9]','',InstrumentID),
                     VolumeMultiple, PriceTick,
                     LongMarginRatio, ShortMarginRatio)]
resVolumeMultiple <- dtInfo[,.(TradingDay, InstrumentID, VolumeMultiple)]

## =============================================================================
mysql <- mysqlFetch('china_futures_info', host = '192.168.1.166')
dbSendQuery(mysql,paste0("DELETE FROM Instrument_info",
            " WHERE TradingDay = ", logTradingDay))
dbSendQuery(mysql,paste0("DELETE FROM VolumeMultiple",
            " WHERE TradingDay = ", logTradingDay))

dbWriteTable(mysql, "Instrument_info",
             resInfo, row.name　=　FALSE, append = T)

dbWriteTable(mysql, "VolumeMultiple",
             resVolumeMultiple, row.name　=　FALSE, append = T)

print(paste0("#---------- Volume Multiple has been written into MySQL! ---------#"))
## =============================================================================
