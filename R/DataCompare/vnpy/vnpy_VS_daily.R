mysql <- mysqlFetch('vnpy', host = '192.168.1.166')
vnpy <- dbGetQuery(mysql, "
                   select * from daily
                   where tradingday = 20170830") %>% as.data.table()
dt <- merge(daily, vnpy, by = c('TradingDay','Sector','InstrumentID'))

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


dt[errVolume != 0][Sector == 'allday']

dt[errTurnover != 0][Sector == 'allday']

temp <- dt[errClose!= 0 | errOpen != 0 | errHigh != 0 | errLow != 0 | errVolume != 0 | errTurnover != 0][Sector == 'allday']

fwrite(temp, '~/err.csv')


