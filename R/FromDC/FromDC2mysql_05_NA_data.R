################################################################################
## FromDC2mysql_05_NA_data.R
################################################################################

info <- data.table(status = paste("(1) [读入数据]: 原始数据                                :==> Rows:", 0,
                                "/ Columns:", 0, sep=" ")
)
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
break_time_detector <- data.table(beginTime = c("21:00:00","00:00:00","09:00:00","13:00:00"),
                                  endTime   = c("23:59:59","02:30:00","11:30:00","15:15:00")
                                )
break_time_detector[,':='(
TradingDay   = tradingDay,
DataSource = 'FromDC',
DataFile = paste(yearID, tradingDay, sep = '-')
)]
#-----------------------------------------------------------------------------
setcolorder(break_time_detector, c('TradingDay',"beginTime", "endTime",
                                 'DataSource','DataFile'))
#-----------------------------------------------------------------------------


################################################################################
#
print("#---------- NO DATA WRITTEN INTO MySQL! --------------------------#")

if(nrow(info) == 1){
  info[1, status := "[错误提示]: 该文件没有数据."]
}

#-------------------------------------------------------------------------------
dbName <- 'FromDC'
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
                              '            : (2) FromDC2mysql_02_manipulate_data.R',
                              '            : (3) FromDC2mysql_03_transform_data.R',
                              '            : (4) FromDC2mysql_04_mysql_data.R',
                              '            : (5) FromDC2mysql_05_NA.R',
                              sep = " \n ")
logInfo$results     <- paste(info$status,collapse = "\n ")
#-------------------------------------------------------------------------------
mysql <- mysqlFetch(dbName, host = '192.168.1.166')
dbWriteTable(mysql,"log",
             logInfo, row.name=FALSE, append = T)

print("#---------- WRITTING processing log into MySQL! ------------------#")
################################################################################
dbDisconnect(mysql)
for(mysql_conn in dbListConnections(MySQL()) )
  dbDisconnect(mysql_conn)
################################################################################


