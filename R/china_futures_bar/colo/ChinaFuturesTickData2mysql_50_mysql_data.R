#! ChinaFuturesTickData2mysql_30_mysql_data.R
#
################################################################################
mysql <- dbConnect(MySQL(), dbname = "china_futures_HFT", host="127.0.0.1",
                   user = mysql_user, password = mysql_pw)
mysql_info_dbname <- paste(dbGetInfo(mysql)$dbname,
                           paste(args_input[1], args_input[2],sep="_"),
                           sep = ".")

dbWriteTable(mysql, paste(args_input[1], args_input[2],sep="_"),
             dt, row.name=FALSE, append = T)

print("#---------- WRITTING DATA INTO MySQL! ----------------------------#")
#-------------------------------------------------------------------------------
if(exists('break_time_detector')){
  dbWriteTable(mysql, 'breakTime',
               break_time_detector, row.name=FALSE, append = T)
}
print("#---------- WRITTING break_time_detector into MySQL! -------------#")

dbDisconnect(mysql)
################################################################################
#
if(nrow(info) == 1){
  info[1, status := "[错误提示]: 该文件没有数据."]
}
#-------------------------------------------------------------------------------
log_info <- data.table(TradingDay  = the_trading_day    ## 日期
                       ,User       = Sys.info() %>% t() %>% data.table() %>% .[,user]
                       ,MysqlDB    = mysql_info_dbname
                       ,DataSource = args_input[1]
                       ,Sector     = NA
                       ,DataFile   = NA
                       ,RscriptMain = the_script_main
                       ,RscriptSub = NA
                       ,ProgBeginTime = begin_time_marker
                       ,ProgEndTime   = Sys.time()
                       ,Results    = NA
                       ,Remarks    = NA
)


if(nrow(myDay) > 20000 | grep('history', the_script_main)){##-- 全天的
  log_info$Sector     <- paste(paste(args_input[1], args_input[2],sep="_"),
                               ":==>",
                               paste(paste0(futures_calendar[k,nights], "_night"),
                                     paste0(futures_calendar[k,days], "_day"), sep = " & "),
                               sep = " ")
  log_info$DataFile   <- ifelse(c(data_file_1,data_file_2,data_file_3)  %>% .[!is.na(.)]  %>% length() != 0,
                                c(data_file_1,data_file_2,data_file_3)  %>% .[!is.na(.)]  %>% paste(.,collapse = ' & '),
                                NA)
}else{##-- crontab
  log_info$Sector     <- paste(paste(args_input[1], args_input[2],sep="_"),
                               ":==>",
                               paste(paste0(futures_calendar[days == the_trading_day,nights], "_night"),
                                     paste0(futures_calendar[days == the_trading_day,days], "_day"), sep = " & "),
                               sep = " ")
  log_info$DataFile <- ifelse(length(data_file)!=0, data_file, NA)
}


log_info$RscriptMain <- the_script_main
log_info$RscriptSub  <- paste('(1) ChinaFuturesTickData2mysql_10_read_data.R',
                              '            : (2) ChinaFuturesTickData2mysql_20_manipulate_data.R',
                              '            : (3) ChinaFuturesTickData2mysql_30_mysql_data.R',
                              sep = " \n ")

log_info$results     <- paste(info$status, collapse = "\n ")
#-------------------------------------------------------------------------------
mysql <- dbConnect(MySQL(), dbname = "dev", host="127.0.0.1",
                   user = mysql_user, password = mysql_pw)
dbWriteTable(mysql, "HFT_log",
             log_info, row.name=FALSE, append = T)
print("#---------- WRITTING processing log into MySQL! ------------------#")
################################################################################
dbDisconnect(mysql)
for(mysql_conn in dbListConnections(MySQL()) )
  dbDisconnect(mysql_conn)
################################################################################
