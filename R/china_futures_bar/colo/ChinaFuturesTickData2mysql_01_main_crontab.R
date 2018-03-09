################################################################################
##! ChinaFuturesTickData2mysql_01_main_crontab.R
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
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_01_main_crontab.R
#-------------------------------------------------------------------------------
#
################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
# Sys.setlocale("LC_ALL", "C")
##
## 是否要包含历史的数据
## 如果想要包含所有的历史数据，请把 include_history 设置为 TRUE

the_script_main <- c("ChinaFuturesTickData2mysql_01_main_crontab.R")
source('/home/fl/William/Codes/Rsettings/myInitial.R')
source('/home/fl/William/Codes/Rsettings/myFread.R')
source('/home/fl/William/Codes/Rsettings/myDay.R')
source('/home/fl/William/Codes/Rsettings/myBreakTime.R')

args <- data.table(colo = c('colo1', 'colo1', 'colo1',
                            'colo5', 'colo5'),
                   csv  = c('ctpmdprod1', 'guavaMD', 'ctp1',
                            'ctp1', 'ctp2'))

if( as.numeric(format(Sys.time(), "%H")) %between% c(8, 20) ){##---- 日盘 ----------------##
  myDay <- myDay[trading_period %between% c('08:00:00','16:00:00')]
}else{##------------------------------------------------------------ 夜盘 ----------------##
  myDay <- myDay[!trading_period %between% c('08:00:00','16:00:00')]
}

################################################################################
## STEP 1:
################################################################################
futures_calendar <- fread("/home/fl/William/Codes/ChinaFuturesCalendar.csv",
                          showProgress = TRUE,
                          colClasses = c("character","character"))
################################################################################
#
#
mysql_user <- 'fl'
mysql_pw   <- 'abc@123'
#
#
################################################################################
## STEP 2:
################################################################################
for(k in 1:nrow(args) ){
  ## 开始执行时间
  begin_time_marker <- Sys.time()

  # k=1
  args_input <- c(args[k,colo],args[k,csv])

  print(paste0("#-----------------------------------------------------------------#"))
  print(paste0("# ",args_input[1],".",args_input[2]," is Initiated at ", Sys.time(), " #"))

  str_to_title(args_input[1]) %>%
    paste0('/data/ChinaFuturesTickData/',.) %>%
    setwd()
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  ## 先判断是否在正常的期货交易日期内
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  # 1.判断是 “日盘” 还是 “夜盘”
  # 根据程序运行的时间来判断：format(Sys.time(), "%H")
  # 2.然后判断是否在交易日历内
  # 根据程序运行的日期来判断：format(Sys.Date(), "%Y%m%d")
  #-----------------------------------------------------------------------------
  if( as.numeric(format(Sys.time(), "%H")) %between% c(8, 20) ){##---- 日盘 ----------------##
    if( format(Sys.Date(), "%Y%m%d") %in% futures_calendar$days ){##-- 如果在交易日期内 ----##
      data_file <- list.files() %>%
        .[grep(paste0("^", args[k,csv],
                      "\\.",
                      format(Sys.Date(), "%Y%m%d")
        ),.)
        ]

      temp <- strsplit(data_file,"\\.") %>% unlist() %>% .[c(2,5)] %>% substr(., 9, 10) %>% as.numeric()

      data_file <- data_file[!is.na(temp) & (temp %between% c(8, 20))]  ##------------- 在 c(9,18) ----------##

      the_trading_day <- futures_calendar[days == format(Sys.Date(), "%Y%m%d"),days]
    }else{##---------------------------------------------------------- 如果不在交易日期内 --##
      #      data_file <- NA
      next
    }
  }else{##------------------------------------------------------------ 夜盘 ----------------##
    if( format(Sys.Date()-1, "%Y%m%d") %in% futures_calendar$nights ){## 如果在交易日期内 ----##
      data_file <- list.files() %>%
        .[grep(paste0("^", args[k,csv],
                      "\\.",
                      format(Sys.Date(), "%Y%m%d")
        ),.)]

      temp <- strsplit(data_file,"\\.") %>% unlist() %>% .[c(2,5)] %>% substr(., 9, 10) %>% as.numeric()

      data_file <- data_file[!is.na(temp) & !(temp %between% c(8, 20))] ##------------- 不在 c(9,18) --------##

      the_trading_day <- futures_calendar[nights == format(Sys.Date()-1, "%Y%m%d"), days]
    }else{##---------------------------------------------------------- 如果不在交易日期内 --##
      #      data_file <- NA
      next
    }
  }
  ##############################################################################
  ##
  ##
  ##
  ##
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  ## 1. 判断 data_file 是否是 NA
  ## 2. 然后判断是否文件是空的
  #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  if(length(data_file) != 0){##-------------------------------------------- 如果 data_file 不是 NA   ##

    dt <- myFread(data_file)

    info <- data.table(status = paste("(1) [读入数据]: 原始数据                                :==> Rows:", nrow(dt),
                                      "/ Columns:", ncol(dt), sep=" ")
                       )
    #-----------------------------------------------------------------------------
    print(paste0("#---------- Data file has been loaded! ---------------------------#"))
    #-----------------------------------------------------------------------------
    if(nrow(dt) == 0){
      # 如果是空
      print(paste0("#---------- NO DATA BEEN LOADED !!! ------------------------------#"))

      source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_40_NA_data.R')
    }else{
      ################################################################################
      ## STEP #3：
      ################################################################################
      source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_20_manipulate_data.R')
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      if(nrow(dt) !=0){
        source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_30_insert_data.R')
        source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_50_mysql_data.R')
      }else{
        source('/home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_40_NA_data.R')
      }
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    }
    #-----------------------------------------------------------------------------
  }
  ################################################################################
  ## END of Programm：
  ################################################################################
  print(paste0("# ",args_input[1],".",args_input[2]," is Finished at ", Sys.time(), " #"))
  print(paste0("#-----------------------------------------------------------------#"))
}

