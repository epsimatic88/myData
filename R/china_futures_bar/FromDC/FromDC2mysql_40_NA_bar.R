##! FromDC2mysql_40_NA_bar

if(args_input[3] == "daily"){##---- 主需要在 daily 看 breakTime
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  info <- data.table(status = paste("(1) [读入数据]: 原始数据                                :==> Rows:", 0,
                                    "/ Columns:", 0, sep=" ")
  )
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  break_time_detector <- data.table(BreakBeginTime = c("21:00:00","00:00:00","09:00:00","13:00:00"),
                                    BreakEndTime   = c("23:59:59","02:30:00","11:30:00","15:15:00")
                                    )
  break_time_detector[,':='(
    TradingDay   = futures_calendar[k,days],
    DataSource = paste(gsub("/data/ChinaFuturesTickData/(.*)", "\\1", getwd()),
                   c(data_file_1, data_file_1, data_file_2, data_file_2),
                   sep = "/"),
    DataFile = c(data_file_1, data_file_1, data_file_2, data_file_2)
  )]
  #-----------------------------------------------------------------------------
  setcolorder(break_time_detector, c('TradingDay',"BreakBeginTime", "BreakEndTime",
                                     'DataSource','DataFile'))
  #-----------------------------------------------------------------------------
}

################################################################################
#
print("#---------- NO DATA WRITTEN INTO MySQL! --------------------------#")

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
                              '            : (3) FromDC2mysql_20_manipulate_data.R',
                              '            : (4) FromDC2mysql_40_NA_data.R',
                              sep = " \n ")
log_info$results     <- paste(info$status,collapse = "\n ")
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
mysql <- dbConnect(MySQL(), dbname = "dev", host="127.0.0.1",
                   user = mysql_user, password = mysql_pw)

if(exists('break_time_detector')){
  dbWriteTable(mysql,
               'FromDC_breakTime',
               break_time_detector, row.name=FALSE, append = T)
}
print("#---------- WRITTING break_time_detector into MySQL! -------------#")

dbWriteTable(mysql,
             "FromDC_log",
             log_info, row.name=FALSE, append = T)
print("#---------- WRITTING processing log into MySQL! ------------------#")
################################################################################
dbDisconnect(mysql)
for(mysql_conn in dbListConnections(MySQL()) )
  dbDisconnect(mysql_conn)
################################################################################
