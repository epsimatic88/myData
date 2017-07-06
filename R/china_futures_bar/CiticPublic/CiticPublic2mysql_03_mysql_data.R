#! citic2mysql_03_mysql.R
#
################################################################################~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## =============================================================================
## dtTick 写入数据库
mysql <- mysqlFetch('china_futures_HFT')
mysqlDBname <- paste(dbGetInfo(mysql)$dbname,
                           gsub("/data/ChinaFuturesTickData/(.*)", "\\1", getwd()),
                           sep = ".")
dbWriteTable(mysql, "CiticPublic",
             dtTick, row.name = FALSE, append = T)
dbDisconnect(mysql)
## =============================================================================


## =============================================================================
## 写入 Bar 数据
mysql <- mysqlFetch('china_futures_bar')

## Delete night minute data
dbSendQuery(mysql,paste0("DELETE FROM minute
            WHERE TradingDay = ", dtMinute[,unique(TradingDay)])
            )
dbWriteTable(mysql,"minute",
             dtMinute, row.name　=　FALSE, append = T)

## -- DailyBar
dbWriteTable(mysql, "daily",
             dt_allday, row.name　=　FALSE, append = T)
## -- DayBar
dbWriteTable(mysql, "daily",
             dt_day, row.name　=　FALSE, append = T)

## -- NightBar
if(nrow(dt_night) != 0){  #--- 如果非空，则录入 MySQL 数据库
  dbWriteTable(mysql, "daily",
               dt_night, row.name　=　FALSE, append = T)
}

print("#---------- WRITTING DATA INTO MySQL! ----------------------------#")
dbDisconnect(mysql)
## =============================================================================


## =============================================================================
if(nrow(info) == 1){
  info[1, status := "[错误提示]: 该文件没有数据."]
}
#-------------------------------------------------------------------------------
logInfo <- data.table(TradingDay  = unique(dt$TradingDay)
                       ,User       = Sys.info() %>% t() %>% data.table() %>% .[,user]
                       ,MysqlDB    = mysqlDBname
                       ,DataSource = gsub("/data/ChinaFuturesTickData/(.*)", "\\1", getwd())
                       ,DataFile   = logDataFile
                       ,RscriptMain = logMainScript
                       ,RscriptSub = NA
                       ,ProgBeginTime = logBeginTime
                       ,ProgEndTime   = Sys.time()
                       ,Results    = NA
                       ,Remarks    = NA
)

logInfo$RscriptSub  <- paste('(1) CiticPublic2mysql_01_read_data.R',
                              '            : (2) CiticPublic2mysql_02_manipulate_data.R',
                              '            : (3) CiticPublic2mysql_03_mysql_data.R',
                              '            : (4) CiticPublic2mysql_04_NA.R',
                              sep = " \n ")
logInfo$Results     <- paste(info$status,collapse = "\n ")
## =============================================================================


## =============================================================================
mysql <- mysqlFetch('dev')

if(exists('break_time_detector')){
  dbWriteTable(mysql,'CiticPublic_break_time',
               break_time_detector, row.name=FALSE, append = T)
}
print("#---------- WRITTING break_time_detector into MySQL! -------------#")

dbWriteTable(mysql, "CiticPublic_log",
             logInfo, row.name = FALSE, append = T)
print("#---------- WRITTING processing log into MySQL! ------------------#")
## =============================================================================

################################################################################
dbDisconnect(mysql)
for(conn in dbListConnections(MySQL()) )
  dbDisconnect(conn)
################################################################################
