################################################################################
##! vnpy_XiFu_From135.R
## 这是主函数:
## 从 MySQL 数据库提取需要的数据
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-09-10
################################################################################

# logTradingDay <- '20170915'
# coloSource <- 'XiFu_From135'

## =============================================================================
mysql <- mysqlFetch('vnpy', host = '192.168.1.166')

dtDaily <- dbGetQuery(mysql, paste0(
        "select * from daily_", coloSource,
        " where TradingDay = ", logTradingDay
    )) %>% as.data.table()
    
dtMinute <-  dbGetQuery(mysql, paste0(
        "select * from minute_", coloSource,
        " where TradingDay = ", logTradingDay
    )) %>% as.data.table()

dtDaily_options <- dbGetQuery(mysql, paste0(
        "select * from daily_", coloSource, "_options", 
        " where TradingDay = ", logTradingDay
    )) %>% as.data.table()
    
dtMinute_options <-  dbGetQuery(mysql, paste0(
        "select * from minute_", coloSource, "_options" ,
        " where TradingDay = ", logTradingDay
    )) %>% as.data.table()
## =============================================================================


## =============================================================================
mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')

## -----------------------------------------------------------------------------
dbSendQuery(mysql, paste0(
  "delete from daily 
  where TradingDay = ", logTradingDay
  ))
dbSendQuery(mysql, paste0(
  "delete from minute 
  where TradingDay = ", logTradingDay
  ))

dbWriteTable(mysql, "daily",
             dtDaily, row.name = FALSE, append = T)

dbWriteTable(mysql, "minute",
             dtMinute, row.name = FALSE, append = T)

## -----------------------------------------------------------------------------
dbSendQuery(mysql, paste0(
  "delete from daily_options
  where TradingDay = ", logTradingDay
  ))
dbSendQuery(mysql, paste0(
  "delete from minute_options
  where TradingDay = ", logTradingDay
  ))

dbWriteTable(mysql, "daily_options",
             dtDaily_options, row.name = FALSE, append = T)

dbWriteTable(mysql, "minute_options",
             dtMinute_options, row.name = FALSE, append = T)
## =============================================================================

################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
################################################################################
