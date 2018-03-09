################################################################################
##! CiticPublic2mysql_00_main.R
## 这是主函数:
## 用于录入 CiticPublic 的数据到 MySQL 数据库
##
## 包括:
## 1. /Data/ChinaFuturesTickData/CiticPublic
##
## 也可用于 GTJAPublic
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-01-16
## UpdateDate: 2017-07-10
################################################################################
# Rscript /home/fl/William/Codes/CiticPublic/CiticPublic2mysql_00_main.R

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("CiticPublic2mysql_00_main.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  source('./R/Rconfig/myFread.R')
  source('./R/Rconfig/myDay.R')
  source('./R/Rconfig/myBreakTime.R')
  source('./R/Rconfig/dt2DailyBar.R')
  source('./R/Rconfig/dt2MinuteBar.R')
})
## =============================================================================
## 是否要包含历史的数据
## 如果想要包含所有的历史数据，请把 include_history 设置为 TRUE
includeHistory <- TRUE
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
## GTJAPublic
## CiticPublic
dataPath <- "/data/ChinaFuturesTickData/CiticPublic"
##
allDataFiles <- list.files(dataPath, pattern = '\\.csv')
################################################################################
## 数据文件的最早时间
startDay <- sapply(1:length(allDataFiles), function(i){
  strsplit(allDataFiles[i], "\\.") %>%
    unlist() %>% .[1] %>% substr(.,1,8)
}) %>% min()

## 数据文件的最早时间
endDay <- sapply(1:length(allDataFiles), function(i){
  strsplit(allDataFiles[i], "\\.") %>%
    unlist() %>% .[1] %>% substr(.,1,8)
}) %>% max()


## 需要更新到的最新日期的倒数
lastDay <- ifelse(as.numeric(format(Sys.time(), "%H")) %between% c(15, 20), 0, 1)
#
#
################################################################################
## STEP 1: 获取对应的
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days"))) %>% 
                          .[(days > startDay) & (days < endDay)]

## =============================================================================
## 判断当天是不是交易的日期
## 如果不是，则停止程序
# if(!format(Sys.Date(), "%Y%m%d") %in% ChinaFuturesCalendar[,days]){
#   stop("亲：不好意思，今天不是赚钱的日子哦！！！")
# }
## =============================================================================


## =============================================================================
## 判断是不是需要处理历史的数据，还是只需要处理最新的数据
if(includeHistory){
  futuresCalendar <- ChinaFuturesCalendar
}else{##-- NOT INCLUDE HIOSTORY DATA
  futuresCalendar <- ChinaFuturesCalendar[.N]
}
## =============================================================================


################################################################################
# nrow(futures_calendar)
for(k in 1:nrow(futuresCalendar)){
  print(paste0("#-----------------------------------------------------------------#"))
  print(paste('#', futuresCalendar[k,days]))
  ## ===========================================================================
  ## 用于记录日志：Log
  ## 1.程序开始执行的时间
  logBeginTime  <- Sys.time()
  ## 2.当天的交易日其
  logTradingDay <- futuresCalendar[k, days]
  ## 当天处理的文件名称
  logDataFile   <- ifelse(nchar(futuresCalendar[k,nights]) == 0,
                          ##-- 如果当天没有夜盘
                          futuresCalendar[k, paste0(days,".csv")],
                          futuresCalendar[k, paste(paste0(nights,".csv"),
                                                    paste0(days,".csv"),
                                                    sep = ' :==> ')])
  ## ===========================================================================


  ## ===========================================================================
  mysql <- mysqlFetch('CiticPublic')
  ## 获取历史的日志，
  ## 判断是不是已经处理过数据文件了
  mysqlDataFile <- dbGetQuery(mysql, "
    SELECT DataFile FROM log") %>% as.data.table()
  ## ===========================================================================


  ## ===========================================================================
  ## 判断已经在处理的系统日志里面
  ## 则不需要再处理数据文件了
  if ( logDataFile %in% mysqlDataFile$DataFile ) {
    print(paste0("#---------- Data has already been written in MySQL!!! ------------#"))
    print(paste0("# <", k, "> <--: at ", Sys.time()))
    print(paste0("#-----------------------------------------------------------------#"))
    next
  } else {
  ## 如果数据文件还没有处理过
  ## 则开始运行下面的脚本
    print(paste0("# <", k, "> -->: at ", Sys.time()))

    ## -------------------------------------------------------------------------
    ## 1. 读取数据
    ## Input: data.csv
    ## Output: dt
    source('./R/CiticPublic/CiticPublic2mysql_01_read_data.R')
    ## -------------------------------------------------------------------------

    ############################################################################
    if (nrow(dt) != 0) {
      source('./R/CiticPublic/CiticPublic2mysql_02_manipulate_data.R')
      source('./R/CiticPublic/CiticPublic2mysql_03_mysql_data.R')
    } else {##---------- NA Data
      source('./R/CiticPublic/CiticPublic2mysql_40_NA_data.R')
    }
    ############################################################################
  }
  print(paste0("#-----------------------------------------------------------------#"))
  print(paste0("# The CiticPublic Data is already inserted into MySQL Databases! -#"))
  print(paste0("#-----------------------------------------------------------------#"))
  print(paste0("# <", k, "> <--: at ", Sys.time()))
}
