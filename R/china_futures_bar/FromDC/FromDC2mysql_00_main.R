################################################################################
##! FromDC2mysql_00_main.R
## 这是主函数:
## 用于录入 FromDC 的数据到 MySQL 数据库
##
## 包括:
## 1. /Data/ChinaFuturesTickData/FromDC
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-01-18
## UpdateDate: 2017-01-18
## UpdateDate:2017-01-23
################################################################################
## args_input <- c(2015, "daily")
## args_input <- c(2015, "minute")

## args_input <- c(2016, "daily")
## args_input <- c(2016, "minute")

## args_input <- c(3, 2014)


#

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())

the_script_main <- c("FromDC2mysql_00_main.R")
source('/home/fl/William/Codes/Rsettings/myInitial.R')
source('/home/fl/William/Codes/Rsettings/myFread.R')
source('/home/fl/William/Codes/Rsettings/myDay.R')
source('/home/fl/William/Codes/Rsettings/dt2DailyBar.R')
source('/home/fl/William/Codes/Rsettings/myBreakTime.R')

args_input <- commandArgs(TRUE)
################################################################################

if(args_input[1] %in% c('2015','2016')){
  args_input <- c(4, args_input)
}else{
  if(args_input[1] %in% c('2011','2012')){
    args_input <- c(1, args_input)
  }else{
    if(args_input[1] == '2013'){
      args_input <- c(2, args_input)
    }else{
      args_input <- c(3, args_input)
    }
  }
}
##
##
mysql_user <- 'fl'
mysql_pw   <- 'abc@123'
##
##
################################################################################
## STEP 1:
################################################################################
futures_calendar <- fread("/home/fl/William/Codes/ChinaFuturesCalendar.csv", showProgress=TRUE,
                          colClasses = list(character = c("nights","days"))
                          ) %>%
  .[(which(substr(days, 1, 4) == as.numeric(args_input[2])) %>% .[1]) :                 ## 第一个
      (which(substr(days, 1, 4) == as.numeric(args_input[2])) %>% .[length(.)])] %>%      ## 最后一个
  .[, nights := paste0(nights, "_night")]

if(as.numeric(args_input[2]) == 2016){
  futures_calendar <- futures_calendar[1: which(days == 20161103)]                        ## 2016年的截止到 20161103
}
if(as.numeric(args_input[2]) == 2013){
  futures_calendar <- futures_calendar[which(substr(futures_calendar$nights,1,8) %>% as.numeric() == 20130705) :
                                         nrow(futures_calendar)]              ## 2013年的开始于
}
################################################################################



################################################################################
## STEP 2:
################################################################################
# nrow(futures_calendar)
# 1 150
for(k in 1:nrow(futures_calendar)){
  ## 开始执行时间
  begin_time_marker <- Sys.time()

  print(paste0(as.numeric(args_input[2]), " :==> Trading Day :==> ", k))
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  the_trdingday <- futures_calendar[k, days]
  data_file_1 <- futures_calendar[k, nights]
  data_file_2 <- futures_calendar[k, days]
  ################################################################################
  mysql <- dbConnect(MySQL(), dbname = "dev", host="127.0.0.1",
                     user = mysql_user, password = mysql_pw)
  mysql_data_file <- dbGetQuery(mysql,
                                paste("SELECT DataFile FROM", "FromDC_log",
                                      "WHERE Sector = ", "'",args_input[3],"'")
                                ) %>% as.data.table()

  ################################################################################
  if( paste(data_file_1, data_file_2, sep = " ==> ") %in% mysql_data_file$DataFile ){
    print(paste0("#-----------------------------------------------------------------#"))
    print(paste0("#---------- Data has already been written in MySQL!!! ------------#"))
    next
  }else{
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    source('/home/fl/William/Codes/FromDC/FromDC2mysql_10_read_data.R')#>>>>>>>>>>>>>>>
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    if(nrow(dt) != 0){
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      source('/home/fl/William/Codes/FromDC/FromDC2mysql_20_manipulate_data.R')#
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      if(nrow(dt) != 0){
        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        source('/home/fl/William/Codes/FromDC/FromDC2mysql_30_transform_bar.R')#
        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        print(paste0("#---------- Writting into MySQL DATABASE! ------------------------#"))
        ################################################################################
        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        source('/home/fl/William/Codes/FromDC/FromDC2mysql_50_mysql_data.R')
        ##############################################################################
      }else{
        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        source('/home/fl/William/Codes/FromDC/FromDC2mysql_40_NA_bar.R')#>>>>>>>>>>>>>>
        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      }
    }else{
        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        source('/home/fl/William/Codes/FromDC2mysql_40_NA_bar.R')#>>>>>>>>>>>>>>
        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      }
    }
  #-----------------------------------------------------------------------------
  for(mysql_conn in dbListConnections(MySQL()) )
    dbDisconnect(mysql_conn)
}
