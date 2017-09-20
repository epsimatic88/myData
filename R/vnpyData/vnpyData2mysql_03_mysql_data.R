#! citic2mysql_03_mysql.R
#
################################################################################~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## =============================================================================
## dtTick 写入数据库
mysql <- mysqlFetch('vnpy', host = '192.168.1.166')
mysqlDBname <- paste(dbGetInfo(mysql)$dbname, dataPath, sep = ".")

print("#---------- WRITTING Bar INTO MySQL! -----------------------------#")
## =============================================================================
## 写入 Bar 数据
## Delete night minute data
dbSendQuery(mysql,paste0("DELETE FROM minute_",coloSource,
            " WHERE TradingDay = ", logTradingDay))
dbWriteTable(mysql,paste0("minute_",coloSource),
             dtMinute %>% .[nchar(InstrumentID) < 8], row.name　=　FALSE, append = T)

## -----------------------------------------------------------------------------
dbSendQuery(mysql,paste0("DELETE FROM minute_",coloSource,"_options",
            " WHERE TradingDay = ", logTradingDay))
dbWriteTable(mysql,paste0("minute_",coloSource,"_options"),
             dtMinute %>% 
             .[grep("-P-|-C-|[0-9]{2,3}P[0-9]{2,3}|[0-9]{2,3}C[0-9]{2,3}", InstrumentID)]
             , row.name　=　FALSE, append = T)


dbSendQuery(mysql,paste0("DELETE FROM daily_",coloSource,
            " WHERE TradingDay = ", logTradingDay))
## -----------------------------------------------------------------------------
dbSendQuery(mysql,paste0("DELETE FROM daily_",coloSource,"_options",
            " WHERE TradingDay = ", logTradingDay))

if ( tempHour %between% c(15,19) | includeHistory) {
  ## -- DailyBar
  dbWriteTable(mysql, paste0("daily_",coloSource),
               rbind(dt_allday, dt_day, fill = TRUE) %>% .[nchar(InstrumentID) < 8]
               , row.name　=　FALSE, append = T)
  ## -- DailyBar
  dbWriteTable(mysql, paste0("daily_",coloSource,"_options"),
               rbind(dt_allday, dt_day, fill = TRUE) %>% 
               .[grep("-P-|-C-|[0-9]{2,3}P[0-9]{2,3}|[0-9]{2,3}C[0-9]{2,3}", InstrumentID)]
               , row.name　=　FALSE, append = T)
}

## -- NightBar
if(nrow(dt_night) != 0){  #--- 如果非空，则录入 MySQL 数据库
  dbWriteTable(mysql, paste0("daily_",coloSource),
               dt_night %>% .[nchar(InstrumentID) < 8], row.name　=　FALSE, append = T)

  dbWriteTable(mysql, paste0("daily_",coloSource,"_options"),
               dt_night %>% 
               .[grep("-P-|-C-|[0-9]{2,3}P[0-9]{2,3}|[0-9]{2,3}C[0-9]{2,3}", InstrumentID)]
               , row.name　=　FALSE, append = T)
}

print("#---------- WRITTING Tick INTO MySQL! ----------------------------#")
## =============================================================================
dbSendQuery(mysql,paste0("DELETE FROM tick_",coloSource,
            " WHERE TradingDay = ", logTradingDay))
dbWriteTable(mysql, paste0("tick_",coloSource),
             dtTick %>% .[nchar(InstrumentID) < 8], row.name = FALSE, append = T)

## -----------------------------------------------------------------------------
dbSendQuery(mysql,paste0("DELETE FROM tick_",coloSource,"_options",
            " WHERE TradingDay = ", logTradingDay))
dbWriteTable(mysql, paste0("tick_",coloSource,"_options"),
             dtTick %>% 
             .[grep("-P-|-C-|[0-9]{2,3}P[0-9]{2,3}|[0-9]{2,3}C[0-9]{2,3}", InstrumentID)]
             , row.name = FALSE, append = T)
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

logInfo$RscriptSub  <- paste('(1) vnpyData2mysql_01_read_data.R',
                              '            : (2) vnpyData2mysql_02_manipulate_data.R',
                              '            : (3) vnpyData2mysql_03_mysql_data.R',
                              '            : (4) vnpyData2mysql_04_NA.R',
                              sep = " \n ")
logInfo$Results     <- paste(info$status,collapse = "\n ")
## =============================================================================

if ( tempHour %between% c(15,19) | includeHistory) {
  mysql <- mysqlFetch('vnpy', host = '192.168.1.166')
  ## =============================================================================
  if(exists('break_time_detector')){
    dbWriteTable(mysql,paste0('breakTime_',coloSource),
                 break_time_detector, row.name=FALSE, append = T)
    print("#---------- WRITTING break_time_detector into MySQL! -------------#")
  }
  
  dbWriteTable(mysql, paste0("log_",coloSource),
               logInfo, row.name = FALSE, append = T)
  print("#---------- WRITTING processing log into MySQL! ------------------#")
  ## =============================================================================
}

################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
################################################################################
