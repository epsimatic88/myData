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
fetchSignal <- function(fromDB, toDB) {
  # fromDB <- 'TianMi1'
  # toDB   <- 'FL_SimNow'

  mysql <- mysqlFetch(fromDB)
  fromSignal <- dbGetQuery(mysql, "select * from tradingSignal") %>%
    as.data.table() %>%
    .[, TradingDay := gsub('-','',TradingDay)] %>%
    .[TradingDay == gsub('-','',currTradingDay[1,nights])]

  if (nrow(fromSignal) == 0) return(NULL)

  mysql <- mysqlFetch(toDB)
  dbSendQuery(mysql, "truncate table tradingSignal")
  dbWriteTable(mysql, 'tradingSignal',
               fromSignal, row.names = FALSE, append = TRUE)
}
## =============================================================================

# fetchSignal(fromDB = 'TianMi1', toDB = 'LXO_SimNow')
fetchSignal(fromDB = 'TianMi1', toDB = 'SimNow_LXO')
# fetchSignal(fromDB = 'YunYang1', toDB = 'YY_SimNow')
# fetchSignal(fromDB = 'YunYang1', toDB = 'FL_SimNow')
fetchSignal(fromDB = 'YunYang1', toDB = 'SimNow_FL')
fetchSignal(fromDB = 'YunYang1', toDB = 'SimNow_YY')

