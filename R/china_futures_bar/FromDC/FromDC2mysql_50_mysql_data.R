#! dc2mysql_03_mysql.R
#
################################################################################~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mysql <- dbConnect(MySQL(), dbname = "china_futures_bar", host="127.0.0.1",   ## china_futures_bar
                   user = mysql_user, password = mysql_pw)
if(args_input[3] == "minute"){
  mysql_info_dbname <- paste(dbGetInfo(mysql)$dbname,
                             "minute",
                             sep = ".")
  dbWriteTable(mysql,
               "minute",
               dt_1m, row.name=FALSE, append = T)
}else{
  mysql_info_dbname <- paste(dbGetInfo(mysql)$dbname,
                             "daily",
                             sep = ".")
  dbWriteTable(mysql, "daily",
               dt_allday, row.name=FALSE, append = T)
  dbWriteTable(mysql, "daily",
               dt_day, row.name=FALSE, append = T)

  if(nrow(dt_night) != 0){  #--- 如果非空，则录入 MySQL 数据库
    dbWriteTable(mysql, "daily",
                 dt_night, row.name=FALSE, append = T)
  }
}

print("#---------- WRITTING DATA INTO MySQL! ----------------------------#")
#-------------------------------------------------------------------------------
dbDisconnect(mysql)
################################################################################
#-------------------------------------------------------------------------------
mysql <- dbConnect(MySQL(), dbname = "dev", host="127.0.0.1",
                   user = mysql_user, password = mysql_pw)
if(exists('break_time_detector')){
  dbWriteTable(mysql,
               'FromDC_breakTime',
               break_time_detector, row.name=FALSE, append = T)
}
print("#---------- WRITTING break_time_detector into MySQL! -------------#")
#-------------------------------------------------------------------------------
if(nrow(info) == 1){
  info[1, status := "[错误提示]: 该文件没有数据."]
}
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
log_info <- data.table(TradingDay  = the_trdingday
                       ,Sector     = args_input[3]
                       ,User       = Sys.info() %>% t() %>% data.table() %>% .[,user]
                       ,MysqlDB    = mysql_info_dbname
                       ,DataSource = gsub("/data/ChinaFuturesTickData/(.*)", "\\1", getwd())
                       ,DataFile   = the_data_file
                       ,RscriptMain = the_script_main
                       ,RscriptSub = NA
                       ,ProgBeginTime = begin_time_marker
                       ,ProgEndTime   = Sys.time()
                       ,Results    = NA
                       ,Remarks    = NA
)

log_info$RscriptSub  <- paste('(1) FromDC2mysql_10_read_data.R',
                              '            : (2) Rsettings/dt2DailyBar.R',
                              '            : (3) FromDC2mysql_30_transform_data.R',
                              '            : (4) FromDC2mysql_50_mysql_data.R',
                              sep = " \n ")
log_info$results     <- paste(info$status,collapse = "\n ")
#-------------------------------------------------------------------------------
mysql <- dbConnect(MySQL(), dbname = "dev", host="127.0.0.1",
                   user = mysql_user, password = mysql_pw)

dbWriteTable(mysql,"FromDC_log",
             log_info, row.name=FALSE, append = T)

print("#---------- WRITTING processing log into MySQL! ------------------#")
################################################################################
dbDisconnect(mysql)
for(mysql_conn in dbListConnections(MySQL()) )
  dbDisconnect(mysql_conn)
################################################################################
