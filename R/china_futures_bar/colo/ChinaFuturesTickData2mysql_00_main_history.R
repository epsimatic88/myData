################################################################################
##! ChinaFuturesTickData2mysql_00_main_history.R
## 这是主函数:
## 用于录入 ChinaFuturesTickData 的数据到 MySQL 数据库
##
## 包括:
## 1. /Data/ChinaFuturesTickData/Colo1: ctpmdprod1, ctp1, guavaMD
## 2. /Data/ChinaFuturesTickData/Colo5: ctpmdprod1, ctpmdprod2, DceL2, ctp1, ctp2
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-01-16
## UpdateDate: 2017-01-16
################################################################################
#-------------------------------------------------------------------------------
# args_input <- c('colo1', 'ctpmdprod1')
# args_input <- c('colo1', 'ctp1')
# args_input <- c('colo1', 'guavaMD')
#-------------------------------------------------------------------------------
# args_input <- c('colo5', 'ctpmdprod1')
# args_input <- c('colo5', 'ctpmdprod2')
# args_input <- c('colo5', 'ctp1')         #------------------------------------
# args_input <- c('colo5', 'ctp2')         #------------------------------------
# args_input <- c('colo5', 'DceL2')
#
#
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_00_main_history.R colo1 ctpmdprod1
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_00_main_history.R colo1 ctp1
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_00_main_history.R colo1 guavaMD
#-------------------------------------------------------------------------------
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_00_main_history.R colo5 ctpmdprod1
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_00_main_history.R colo5 ctpmdprod2
##
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_00_main_history.R colo5 ctp1
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_00_main_history.R colo5 ctp2
##
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_00_main_history.R colo5 DceL2
#
################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
args_input <- commandArgs(TRUE)
# Sys.setlocale("LC_ALL", "C")
##
## 是否要包含历史的数据
## 如果想要包含所有的历史数据，请把 include_history 设置为 TRUE
includeHistory <- TRUE


the_script_main <- c("ChinaFuturesTickData2mysql_00_main_history.R")
source('/home/fl/William/Codes/Rsettings/myInitial.R')
source('/home/fl/William/Codes/Rsettings/myFread.R')
source('/home/fl/William/Codes/Rsettings/myDay.R')
source('/home/fl/William/Codes/Rsettings/myBreakTime.R')

setwd(paste0('/data/ChinaFuturesTickData/',
             str_to_title(args_input[1]))
      )

all_data_files <- list.files(pattern = paste0("^",args_input[2], '.*\\.csv$'))

if(includeHistory){
  args_input <- c(args_input,1,length(all_data_files))
}
################################################################################
#
#
startDay <- sapply(1:length(all_data_files), function(i){
  strsplit(all_data_files[i], "\\.") %>%
    unlist() %>% .[2] %>% substr(.,1,8)
  }) %>% min()

lastDay <- ifelse(as.numeric(format(Sys.time(), "%H")) %between% c(16, 23), 0, 1)
#
#
################################################################################
## STEP 1:
################################################################################
if(0){
futures_calendar <- fread("/home/fl/William/Codes/ChinaFuturesCalendar.csv",
                          colClasses = list(character = c("nights","days"))
                          ) %>%
  .[(which(days >=  max(gsub("-","",(Sys.Date() - 250) %>% as.character()),
                        startDay) ) %>% .[1])
    :  ## 半年以内的数据
    (which(days <=  gsub("-","",(Sys.Date() -   lastDay ) %>% as.character()) ) %>% .[length(.)])
    ]
}

################################################################################
temp <- lapply(1:length(all_data_files), function(ii){
  temp <- strsplit(all_data_files[ii],"\\.")[[1]]
  temp <- data.table(coloName = temp[1], coloDate = temp[2]) %>%
    .[,coloDate2 := substr(coloDate,1,8)]
}) %>% rbindlist()

futures_calendar <- fread("/home/fl/William/Codes/ChinaFuturesCalendar.csv",
                          colClasses = list(character = c("nights","days"))
                          ) %>%
  .[(which(days == as.character(min(temp$coloDate2)))) :
      (which(days == as.character(max(temp$coloDate2))))]

if(args_input[1] == 'colo5' & (args_input[2] == 'ctp1' | args_input[2] == 'ctp2')){
  ##-- colo5 的 ctp1 和 ctp2 前面几天是测试数据，可能不正确
  futures_calendar <- futures_calendar[4:.N]
}
################################################################################
#
#
#
#
mysql_user <- 'fl'
mysql_pw   <- 'abc@123'
#
#
#
################################################################################
## STEP 2:
################################################################################
for(k in 1:nrow(futures_calendar) ){
  ## 开始执行时间
  begin_time_marker <- Sys.time()
  the_trading_day <- as.character(futures_calendar[k,days])
  data_file_info <- paste(paste(args_input[1], args_input[2],sep="_"),
                          ":==>",
                          paste(paste0(futures_calendar[k,nights], "_night"),
                                paste0(futures_calendar[k,days], "_day"), sep = " & "),
                          sep = " ")
  print(paste0("#-----------------------------------------------------------------#"))
  print(paste0("# <", k, "> ", data_file_info))
  print(paste0("# <", k, "> :--> at ", Sys.time()))
  ################################################################################
  mysql <- dbConnect(MySQL(), dbname = "dev", host="127.0.0.1",
                     user = mysql_user, password = mysql_pw)

  mysql_data_file <- dbGetQuery(mysql,
                                paste("SELECT Sector FROM ",
                                      "HFT_log")
                                ) %>% as.data.table()
  ################################################################################
  if( data_file_info %in% mysql_data_file$Sector ){
    print(paste0("#---------- Data has already been written in MySQL!!! ------------#"))
    print(paste0("# <", k, "> <--: at ", Sys.time()))
    print(paste0("#-----------------------------------------------------------------#"))

    next
  }else{
    source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_10_read_data.R')
    ################################################################################
    ## STEP #3：
    ################################################################################
    if(nrow(dt) !=0){
      #-----------------------------------------------------------------------------
      print(paste0("#---------- Data file has been loaded! ---------------------------#"))
      #-----------------------------------------------------------------------------
      source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_20_manipulate_data.R')
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      if(nrow(dt) !=0){
        source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_30_insert_data.R')
        source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_50_mysql_data.R')
      }else{
        #-----------------------------------------------------------------------------
        source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_40_NA_data.R')
        #-----------------------------------------------------------------------------
      }
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    }else{                        #-- 如果 dt 是空的 ---------------------------##
      #-----------------------------------------------------------------------------
      source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_40_NA_data.R')
      #-----------------------------------------------------------------------------
    }
    ################################################################################
    ## END of Programm：
    ################################################################################
    print(paste0("# <", k, "> <--: at ", Sys.time()))
    print(paste0("#-----------------------------------------------------------------#"))
  }
}
#
#
#
#
