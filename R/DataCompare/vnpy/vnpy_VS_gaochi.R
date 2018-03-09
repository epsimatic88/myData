################################################################################
## 数据对比
## vnpy.data VS Gaochi
################################################################################

rm(list = ls())

setwd('/home/fl/myData')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

mysql <- mysqlFetch('vnpy', host = '192.168.1.166')

tradingDay <- 20171129

## =============================================================================
dtVnpy <- dbGetQuery(mysql, paste("
                   select * from daily_YunYang1_FromPC
                   where tradingday = ", tradingDay)) %>%
          as.data.table()

dtGaochi <- tradingDay %>% ymd() %>%
            paste0('/data/FromHF/daily/',.,'.csv') %>%
            fread() %>%
            .[, V1 := NULL]
dtGaochi <- tradingDay %>%
            paste0('/home/fl/temp/',.,'.csv') %>%
            fread() %>%
            .[, V1 := NULL]
## =============================================================================

dt <- merge(dtGaochi, dtVnpy, by = c('TradingDay','Sector','InstrumentID'), all = TRUE)

dt[,":="(
  errOpen = OpenPrice.x - OpenPrice.y,
  errHigh = HighPrice.x - HighPrice.y,
  errLow = LowPrice.x - LowPrice.y,
  errClose = ClosePrice.x - ClosePrice.y,
  errVolume = Volume.x - Volume.y,
  errTurnover = Turnover.x - Turnover.y,
  errOpenOI = OpenOpenInterest.x - OpenOpenInterest.y,
  errHighOI = HighOpenInterest.x - HighOpenInterest.y,
  errLowOI = LowOpenInterest.x - LowOpenInterest.y,
  errCloseOI = CloseOpenInterest.x - CloseOpenInterest.y
)]

dt[errOpen != 0][Sector == 'allday']
dt[errHigh != 0][Sector == 'allday']
dt[errLow != 0][Sector == 'allday']
dt[errClose != 0][Sector == 'allday']

dt[errCloseOI != 0][Sector == 'allday']

dt[errVolume != 0][Sector == 'allday']

dt[errTurnover != 0][Sector == 'allday']

temp <- dt[errClose!= 0 | errOpen != 0 | errHigh != 0 | errLow != 0 | errVolume != 0 | errTurnover != 0][Sector == 'allday']

fwrite(temp, '~/errDaily.csv')

daySector <- 'day'
dt[errOpen != 0][Sector == daySector]
dt[errHigh != 0][Sector == daySector]
dt[errLow != 0][Sector == daySector]
dt[errClose != 0][Sector == daySector]

dt[errCloseOI != 0][Sector == daySector]

dt[errVolume != 0][Sector == daySector]

dt[errTurnover != 0][Sector == daySector]

