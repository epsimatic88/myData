################################################################################
## cffex2mysql.R
## 这是主函数:
## 读取 中金所 下载得到的日行情数据，
## 并录入 MySQL 数据库
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-16
## -----------------------------------------------------------------------------
## 说明：(1) 成交量、持仓量：手（按单边计算）
##      (2) 成交额：万元（按单边计算）
##      (3) 涨跌1＝今收盘价－前结算价
##      (4) 涨跌2＝今结算价－前结算价
##      (5) 交割日今结算价为现货指数交割结算价
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("cffex2mysql.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days"))) %>% 
                              .[days < format(Sys.Date(),'%Y%m%d')]
## CFFEX 从 2010-04-16 开始交易
ChinaFuturesCalendar <- ChinaFuturesCalendar[days >= 20100416]
exchCalendar <- ChinaFuturesCalendar[,":="(calendarYear = substr(days,1,4),
                                           calendarYearMonth = substr(days,1,6),
                                           calendarMonth = substr(days,5,6),
                                           calendarDay = substr(days,7,8))]

dataPath <- './data/Bar/Exchange/CFFEX'
## =============================================================================


## =============================================================================
fetchData <- function(i) {
    tempTradingDay <- exchCalendar[i,days]
    tempFile <- paste0(dataPath, '/', 
                       exchCalendar[i, calendarYear], '/',
                       exchCalendar[i, days], '.csv')
    if (!file.exists(tempFile)) return(data.table())
      
    res <- suppressMessages(read_csv(tempFile, locale = locale(encoding='GB18030'))) %>% 
            as.data.table() %>% 
            .[-grep('小计|合计',合约代码), 1:9] %>% 
            .[, TradingDay := tempTradingDay]
}
## =============================================================================


################################################################################
## STEP 2: 开启并行计算模式
################################################################################
cl <- makeCluster(max(round(detectCores()*2/4),16), type='FORK')
dt <- parLapply(cl, 1:nrow(ChinaFuturesCalendar), fetchData) %>% rbindlist()
stopCluster(cl)

colnames(dt) <- c('InstrumentID','OpenPrice','HighPrice','LowPrice',
                  'Volume','Turnover','CloseOpenInterest',
                  'ClosePrice','SettlementPrice','TradingDay')
dt[, ":="(Turnover = as.numeric(Turnover) * 10000,
          ExchangeID = 'CFFEX')]

## =============================================================================


## =============================================================================
mysql <- mysqlFetch('Exchange')
dbSendQuery(mysql, "delete from daily where ExchangeID = 'CFFEX'")
dbWriteTable(mysql, 'daily', dt, row.name　=　FALSE, append = T)
## =============================================================================


################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
################################################################################
