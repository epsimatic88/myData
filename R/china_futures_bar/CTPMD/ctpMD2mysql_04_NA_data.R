#! CiticPublic2mysql_40_NA_data.R

break_time_detector <- data.table(BreakBeginTime = c("21:00:00","00:00:00","09:00:00","13:00:00"),
                                  BreakEndTime   = c("23:59:59","02:30:00","11:30:00","15:15:00")
                                  )
break_time_detector[,':='(
  TradingDay   = currTradingDay[1,days]
  ,DataSource = coloID[k,colo]
  ,DataFile = logDataFile
)]

#-----------------------------------------------------------------------------
setcolorder(break_time_detector, c('TradingDay',"BreakBeginTime", "BreakEndTime",
                                   'DataSource','DataFile'))
#-----------------------------------------------------------------------------

################################################################################~~~~~~~~~~~~~~~~~~~~~~~~~~~
mysql <- mysqlFetch("china_futures_HFT")
mysqlDBname <- paste(dbGetInfo(mysql)$dbname,
                           coloID[k,colo],
                           sep = ".")

print("#---------- NO DATA WRITTEN INTO MySQL! --------------------------#")
#-------------------------------------------------------------------------------
dbWriteTable(mysql, "CTPMD1_break_time",
             break_time_detector, row.name = FALSE, append = T)
print("#---------- WRITTING break_time_detector into MySQL! -------------#")

dbDisconnect(mysql)
################################################################################
if(nrow(info) == 1 | nrow(dt) == 0){
  info <- data.table(status = "[错误提示]: 该文件没有数据.")
}
#-------------------------------------------------------------------------------
logInfo <- data.table(TradingDay  = logTradingDay
                       ,User       = Sys.info() %>% t() %>% data.table() %>% .[,user]
                       ,MysqlDB    = mysqlDBname
                       ,DataSource = coloID[k,colo]
                       ,DataFile   = logDataFile
                       ,RscriptMain = logMainScript
                       ,RscriptSub = NA
                       ,ProgBeginTime = begin_time_marker
                       ,ProgEndTime   = Sys.time()
                       ,Results    = NA
                       ,Remarks    = NA
                       )

logInfo$RscriptSub  <- paste('(1) ctpMD2mysql_01_read_data.R',
                              '            : (2) ctpMD2mysql_02_manipulate_data.R',
                              '            : (3) ctpMD2mysql_03_mysql_data.R',
                              '            : (4) ctpMD2mysql_04_NA.R',
                              sep = " \n ")
logInfo$Results     <- paste(info$status,collapse = "\n ")
################################################################################~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mysql <- mysqlFetch("dev")
dbWriteTable(mysql, "CTPMD_log",
             logInfo, row.name = FALSE, append = T)
print("#---------- WRITTING processing log into MySQL! ------------------#")
#-------------------------------------------------------------------------------
dbDisconnect(mysql)
