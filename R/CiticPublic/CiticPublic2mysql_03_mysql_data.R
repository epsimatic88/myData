#! citic2mysql_03_mysql.R
#
################################################################################~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## =============================================================================
## dtTick 写入数据库
mysqlDBname <- 'CiticPublic'
mysql <- mysqlFetch(mysqlDBname, host = '192.168.1.166')
# mysqlDBname <- paste(dbGetInfo(mysql)$dbname,
#                            gsub("/data/ChinaFuturesTickData/(.*)", "\\1", getwd()),
#                            sep = ".")
print("#---------- WRITTING Bar INTO MySQL! -----------------------------#")
## =============================================================================



## -----------------------------------------------------------------------------
dbSendQuery(mysql,paste0("DELETE FROM minute
            WHERE TradingDay = ", dtMinute[,unique(TradingDay)]))
dbWriteTable(mysql,"minute",
             dtMinute %>% .[nchar(InstrumentID) < 8], 
             row.name　=　FALSE, append = T)
## -----------------------------------------------------------------------------
dbSendQuery(mysql,paste0("DELETE FROM minute_options",
            " WHERE TradingDay = ", logTradingDay))
dbWriteTable(mysql,paste0("minute_options"),
             dtMinute %>%
             .[grep("-P-|-C-|[0-9]{2,3}P[0-9]{2,3}|[0-9]{2,3}C[0-9]{2,3}", InstrumentID)]
             , row.name　=　FALSE, append = T)

## -----------------------------------------------------------------------------
dbSendQuery(mysql,paste0("DELETE FROM daily",
            " WHERE TradingDay = ", logTradingDay))
## -----------------------------------------------------------------------------
dbSendQuery(mysql,paste0("DELETE FROM daily_options",
            " WHERE TradingDay = ", logTradingDay))

## -- DailyBar
dbWriteTable(mysql, "daily",
             rbind(dt_allday, dt_day, fill = TRUE) %>% .[nchar(InstrumentID) < 8], 
             row.name　=　FALSE, append = T)
## -- DayBar
dbWriteTable(mysql, "daily_options",
             rbind(dt_allday, dt_day, fill = TRUE) %>% 
             .[grep("-P-|-C-|[0-9]{2,3}P[0-9]{2,3}|[0-9]{2,3}C[0-9]{2,3}", InstrumentID)],
             row.name　=　FALSE, append = T)

## -- NightBar
if (nrow(dt_night) != 0) {  #--- 如果非空，则录入 MySQL 数据库
  dbWriteTable(mysql, "daily",
               dt_night %>% .[nchar(InstrumentID) < 8], 
               row.name　=　FALSE, append = T)
  dbWriteTable(mysql, "daily_options",
               dt_night %>% 
               .[grep("-P-|-C-|[0-9]{2,3}P[0-9]{2,3}|[0-9]{2,3}C[0-9]{2,3}", InstrumentID)], 
               row.name　=　FALSE, append = T)
}

print("#---------- WRITTING DATA INTO MySQL! ----------------------------#")
dbDisconnect(mysql)
## =============================================================================


## =============================================================================
if(nrow(info) == 1){
  info[1, status := "[错误提示]: 该文件没有数据."]
}
#-------------------------------------------------------------------------------
logInfo <- data.table(TradingDay  = logTradingDay
                       ,User       = Sys.info() %>% t() %>% data.table() %>% .[,user]
                       ,MysqlDB    = mysqlDBname
                       ,DataSource = dataPath
                       ,DataFile   = logDataFile
                       ,RscriptMain = logMainScript
                       ,RscriptSub = NA
                       ,ProgBeginTime = logBeginTime
                       ,ProgEndTime   = Sys.time()
                       ,Results    = NA
                       ,Remarks    = NA
)

logInfo$RscriptSub  <- paste('(1) CiticPublic2mysql_01_read_data.R',
                              '             : (2) CiticPublic2mysql_02_manipulate_data.R',
                              '             : (3) CiticPublic2mysql_03_mysql_data.R',
                              '             : (4) CiticPublic2mysql_04_NA.R',
                              sep = " \n ")
logInfo$Results     <- paste(info$status,collapse = "\n ")
## =============================================================================


## =============================================================================
mysql <- mysqlFetch(mysqlDBname)

if(exists('break_time_detector')){
  dbWriteTable(mysql,'breakTime',
               break_time_detector, row.name=FALSE, append = T)
}
print("#---------- WRITTING break_time_detector into MySQL! -------------#")

dbWriteTable(mysql, "log",
             logInfo, row.name = FALSE, append = T)
print("#---------- WRITTING processing log into MySQL! ------------------#")
## =============================================================================

################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
################################################################################
