################################################################################
##! signal_from_mysql.R
##
## 从　MySQL 数据库提取 策略信号 数据
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-11-14
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
# rm(list = ls())

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})


## =============================================================================
## FL_SimNow =====> TianMi1
fetchSignal <- function(fromDB, toDB,
                        fromHost = '192.168.1.166', toHost = '192.168.1.166') {
  mysql <- mysqlFetch(fromDB, host = fromHost)
  fromSignal <- dbGetQuery(mysql, "select * from tradingSignal") %>%
    as.data.table() %>%
    .[, TradingDay := gsub('-','',TradingDay)] %>%
    .[TradingDay == gsub('-','',currTradingDay[1,nights])]
  if (toDB == 'SimNow_LXO') {
    fromSignal[, volume := volume * 3]
  }

  if (nrow(fromSignal) == 0) return(NULL)

  mysql <- mysqlFetch(toDB, host = toHost)
  dbSendQuery(mysql, "truncate table tradingSignal")
  dbWriteTable(mysql, 'tradingSignal',
               fromSignal, row.names = FALSE, append = TRUE)
}
## =============================================================================

# fetchSignal(fromDB = 'YunYang1', toDB = 'SimNow_LXO')
# fetchSignal(fromDB = 'YunYang1', toDB = 'SimNow_FL')
# fetchSignal(fromDB = 'YunYang1', toDB = 'SimNow_YY')

fetchSignal(fromDB = 'TianMi3', toDB = 'SimNow_LXO', 
            fromHost = '192.168.1.135', toHost = '192.168.1.135')
# fetchSignal(fromDB = 'YunYang1', toDB = 'SimNow_FL', toHost = '192.168.1.135')
# fetchSignal(fromDB = 'SimNow_FL', toDB = 'SimNow_YY', toHost = '192.168.1.135')
fetchSignal(fromDB = 'SimNow_YY', toDB = 'SimNow_FL', 
            fromHost = '192.168.1.135', toHost = '192.168.1.135')

## =============================================================================
xifu <- mysqlQuery(db = 'china_futures_bar',
                  query = paste0('select TradingDay, Main_contract as InstrumentID from main_contract_daily where TradingDay = ', lastTradingDay[1, gsub('-', '', days)]))
xifu[, ':='(
  strategyID = 'OIStrategy'
  ,volume = 0
  ,direction = 0
  ,param = 0
  )]
xifu <- xifu[!grepl("IC|IH|IF|TF|^[T]|wr", InstrumentID)]
mysql <- mysqlFetch(db = 'XiFu', host = '192.168.1.135')
dbSendQuery(mysql, 'truncate table tradingSignal')
dbWriteTable(mysql, 'tradingSignal', xifu, row.names = F, append = T)
dbDisconnect(mysql)
## =============================================================================
