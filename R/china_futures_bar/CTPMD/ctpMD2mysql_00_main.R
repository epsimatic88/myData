################################################################################
##! ctpMD2mysql_00_main.R
## 
## 这是主函数:
## 用于录入 ChinaFuturesTickData/CTPMD 的数据到 MySQL 数据库
## 这一份脚本用于处理日常的更新维护
##
## 包括:
## 1. /Data/ChinaFuturesTickData/Colo1: ctpmdprod1, ctp1, guavaMD
## 2. /Data/ChinaFuturesTickData/Colo5: ctpmdprod1, ctpmdprod2, DceL2, ctp1, ctp2
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-01-16
## UpdateDate: 2017-07-17
################################################################################
#-------------------------------------------------------------------------------
## Rscript /home/fl/William/Codes/china_futures_HFT/ChinaFuturesTickData2mysql_01_main_crontab.R
#-------------------------------------------------------------------------------
#


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("ctpMD2mysql_00_main.R")

## =============================================================================
## 需要输入的参数
## 
dataPath <- "/data/ChinaFuturesTickData/CTPMD1"

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  source('./R/Rconfig/myFread.R')
  source('./R/Rconfig/myDay.R')
  source('./R/Rconfig/myBreakTime.R')
  source('./R/Rconfig/dt2DailyBar.R')
  source('./R/Rconfig/dt2MinuteBar.R')
})

coloID <- data.table(colo = c('CTPMD1'),
                     csv  = c('ctp1'))
allDataFiles <- list.files(dataPath, pattern = '.*\\.csv$')

ChinaFuturesCalendar <- fread("/home/fl/myData/data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
  colClasses = list(character = c("nights","days")))
## =============================================================================


## =============================================================================
## 是否要包含历史的数据
## 如果想要包含所有的历史数据，请把 include_history 设置为 TRUE
includeHistory <- FALSE

if (! includeHistory) {
  ## =============================================================================
  ## 以下都不需要修改
  ## =============================================================================
  if (! format(Sys.Date()-0, '%Y%m%d') %in% ChinaFuturesCalendar[,days] & 
      ! format(Sys.Date()-1, '%Y%m%d') %in% ChinaFuturesCalendar[,nights]) {
    stop('圣上，今天赌场关门哦！！！')
  }
}
#-------------------------------------------------------------------------------
tempHour <- as.numeric(format(Sys.time(), "%H"))

## =============================================================================
if (includeHistory) {
    # coloID <- data.table(colo = c('colo1', 'colo1', 'colo1',
    #                               'colo5', 'colo5'),
    #                      csv  = c('ctpmdprod1', 'guavaMD', 'ctp1',
    #                               'ctp1', 'ctp2'))
    # allDataFiles <- list.files(pattern = paste0("^",args_input[2], '.*\\.csv$'))
    
    ############################################################################
    #
    #
    startDay <- sapply(1:length(allDataFiles), function(i){
      strsplit(allDataFiles[i], "\\.") %>%
        unlist() %>% .[2] %>% substr(.,1,8)
    }) %>% min()

    endDay <- sapply(1:length(allDataFiles), function(i){
      strsplit(allDataFiles[i], "\\.") %>%
        unlist() %>% .[2] %>% substr(.,1,8)
    }) %>% max()

    currTradingDay <- ChinaFuturesCalendar[days %between% c(startDay, endDay)] %>% 
                      .[-.N]
} else {
  if ( tempHour %between% c(8,19) ) {
      currTradingDay <- ChinaFuturesCalendar[days == format(Sys.Date(),'%Y%m%d')]
  } else {
      currTradingDay <- ChinaFuturesCalendar[nights == format(Sys.Date()-1,'%Y%m%d')]
  }
}
## =============================================================================



## =============================================================================
for (k in 1:nrow(coloID)) {
  ## ===========================================================================
  for (i in 1:nrow(currTradingDay)) {
    print(paste0("#-----------------------------------------------------------------#"))
    print(paste0("#---------- TradingDay :==> ", currTradingDay[i,days], 
      " -----------------------------#"))

    ## =========================================================================
    ## 用于记录日志：Log
    ## 1.程序开始执行的时间
    logBeginTime  <- Sys.time()
    ## 2.当天的交易日其
    logTradingDay <- currTradingDay[i, days]
    ## =========================================================================
    
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ## 先判断是否在正常的期货交易日期内
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # 1.判断是 “日盘” 还是 “夜盘”
    # 根据程序运行的时间来判断：format(Sys.time(), "%H")
    # 2.然后判断是否在交易日历内
    # 根据程序运行的日期来判断：format(Sys.Date(), "%Y%m%d")
    #---------------------------------------------------------------------------
    
    ## -------------------------------------------------------------------------
    ## 夜盘
    dataFile <- list.files(dataPath, pattern = '.csv') %>%
          .[grep(paste0("^", coloID[k,csv], "\\.",
                        currTradingDay[i, format(as.Date(nights, '%Y%m%d') + 1, '%Y%m%d')]),
                        .)]
    temp <- strsplit(dataFile,"\\.") %>% unlist() %>% .[c(2,5)] %>% substr(., 9, 10) %>% as.numeric()
    dataFileNight <- dataFile[!is.na(temp) & !(temp %between% c(6, 18))]

    ## 日盘
    dataFile <- list.files(dataPath, pattern = '.csv') %>%
          .[grep(paste0("^", coloID[k,csv], "\\.",
                        currTradingDay[i, days]),
                        .)]
    temp <- strsplit(dataFile,"\\.") %>% unlist() %>% .[c(2,5)] %>% substr(., 9, 10) %>% as.numeric()
    dataFileDay <- dataFile[!is.na(temp) & (temp %between% c(6, 18))]

    ## 当天处理的文件名称
    logDataFile <- ifelse(identical(dataFileNight,character(0)),
                          ##-- 如果当天没有夜盘
                          coloID[k, paste(colo, dataFileDay, sep = '.')],
                          currTradingDay[k, paste(coloID[k, paste(colo, dataFileNight, sep = '.')],
                                                  coloID[k, paste(colo, dataFileDay, sep = '.')],
                                                  sep = ' :==> ')])
    ## =========================================================================

    ## =========================================================================
    mysql <- mysqlFetch('CTPMD')
    ## 获取历史的日志，
    ## 判断是不是已经处理过数据文件了
    mysqlDataFile <- dbGetQuery(mysql, "
      SELECT DataFile FROM log") %>% as.data.table()
    ## =========================================================================

    ## =========================================================================
    if (logDataFile %in% mysqlDataFile[,DataFile]) {
      print(paste0("#---------- Data has already been written in MySQL!!! ------------#"))
      print(paste0("# <", k, "> <--: at ", Sys.time()))
      print(paste0("#-----------------------------------------------------------------#"))
      next
    } else {
      print(paste0("# <", k, "> -->: at ", Sys.time()))
      source('./R/china_futures_bar/CTPMD/ctpMD2mysql_01_read_data.R')

      ## =======================================================================
      if (nrow(dt) != 0){
        source('./R/china_futures_bar/CTPMD/ctpMD2mysql_02_manipulate_data.R')
        source('./R/china_futures_bar/CTPMD/ctpMD2mysql_03_mysql_data.R')
      } else {
        source('./R/china_futures_bar/CTPMD/ctpMD2mysql_04_NA_data.R')
      }
      ## =======================================================================
    }

    ## =========================================================================
    print(paste0("#-----------------------------------------------------------------#"))
    print(paste0("# The CTPMD1 Data is already inserted into MySQL Databases!      -#"))
    print(paste0("#-----------------------------------------------------------------#"))

    print(paste0("#-----------------------------------------------------------------#"))
    print(paste0("# Update MainContract Infomation  --------------------------------#"))
    # source('./R/Rconfig/MainContract_00_main.R')
    print(paste0("#-----------------------------------------------------------------#"))

    print(paste0("# <", k, "> <--: at ", Sys.time()))
    ## =========================================================================
  }
  ## ===========================================================================
}
