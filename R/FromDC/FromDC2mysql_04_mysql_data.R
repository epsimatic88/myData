################################################################################
## FromDC2mysql_03_mysql_data.R
################################################################################

## =============================================================================
dbName <- 'FromDC'
mysql <- mysqlFetch(dbName, host = '192.168.1.166')

print("#---------- WRITTING Bar INTO MySQL! -----------------------------#")
## =============================================================================
print(dtMinute)
print(dt_allday)
print(dt_day)
print(dt_night)

dbSendQuery(mysql,paste0("DELETE FROM minute",
                         " WHERE TradingDay = ", tradingDay))
dbSendQuery(mysql,paste0("DELETE FROM daily",
                         " WHERE TradingDay = ", tradingDay))
## =============================================================================
## Minute bar
dbWriteTable(mysql, "minute",
             dtMinute, row.name=FALSE, append = T)
## =============================================================================


## =============================================================================
## Daily bar
dbWriteTable(mysql, "daily",
             rbind(dt_allday, dt_day),
             row.name = FALSE, append = T)

if (nrow(dt_night) != 0) {
  dbWriteTable(mysql, "daily",
               dt_night, row.name = FALSE, append = T)
}
## =============================================================================

## =============================================================================
## info
dbWriteTable(mysql, "info",
             dtPriceTick, row.name = FALSE, append = T)
## =============================================================================


print("#---------- Finished Writing data! -------------------------------#")



if(exists('break_time_detector')){
  dbWriteTable(mysql,
               'breakTime',
               break_time_detector, row.name=FALSE, append = T)
}
print("#---------- WRITTING break_time_detector into MySQL! -------------#")
#-------------------------------------------------------------------------------
if(nrow(info) == 1){
  info[1, status := "[错误提示]: 该文件没有数据."]
}
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
logInfo <- data.table(TradingDay   = tradingDay
                       ,User       = Sys.info() %>% t() %>% data.table() %>% .[,user]
                       ,MysqlDB    = dbName
                       ,DataSource = 'FromDC'
                       ,DataFile   = paste(yearID, tradingDay, sep = '-')
                       ,RscriptMain = logMainScript
                       ,RscriptSub = NA
                       ,ProgBeginTime = beginTime
                       ,ProgEndTime   = Sys.time()
                       ,Results    = NA
                       ,Remarks    = NA
)

logInfo$RscriptSub  <- paste('(1) FromDC2mysql_01_read_data.R',
                              '             : (2) FromDC2mysql_02_manipulate_data.R',
                              '             : (3) FromDC2mysql_03_transform_data.R',
                              '             : (4) FromDC2mysql_04_mysql_data.R',
                              '             : (5) FromDC2mysql_05_NA.R',
                              sep = " \n ")
logInfo$results     <- paste(info$status,collapse = "\n ")
#-------------------------------------------------------------------------------
dbWriteTable(mysql,"log",
             logInfo, row.name=FALSE, append = T)

print("#---------- WRITTING processing log into MySQL! ------------------#")
################################################################################
dbDisconnect(mysql)
for(mysql_conn in dbListConnections(MySQL()) )
  dbDisconnect(mysql_conn)
################################################################################
