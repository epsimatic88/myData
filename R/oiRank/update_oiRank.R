## =============================================================================
## update.oiRank.R
##
## 每日更新 oiRank 数据
## =============================================================================
rm(list = ls())
source('/home/fl/myData/R/Rconfig/myInit.R')

if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1, days]) stop('NOT TradingDay')

## =============================================================================
tradingDay <- currTradingDay[, gsub('-', '', days)]

mysql <- mysqlFetch('china_futures_bar')
dbSendQuery(mysql, paste0("delete from oiRank where TradingDay = ",
                          tradingDay))
dbDisconnect(mysql)
## =============================================================================

rm(list = ls())
source("/home/fl/myData/R/oiRank/czce.R")

rm(list = ls())
source("/home/fl/myData/R/oiRank/dce.R")

rm(list = ls())
source("/home/fl/myData/R/oiRank/shfe.R")

rm(list = ls())
source("/home/fl/myData/R/oiRank/cffex.R")
