################################################################################
##! FromDC2mysql_00_main.R
## 这是主函数:
## 用于录入 FromDC 的数据到 MySQL 数据库
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-10
################################################################################
## Rscript /home/fl/myData/R/FromDC/FromDC2mysql_00_main.R 2016


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("FromDC2mysql_00_main.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  source('./R/Rconfig/myFread.R')
  source('./R/Rconfig/myDay.R')
  source('./R/Rconfig/myBreakTime.R')
  source('./R/Rconfig/dt2DailyBar.R')
  source('./R/Rconfig/dt2MinuteBar.R')
  source('./R/Rconfig/priceTick.R')
})
options(width = 140)
args_input <- commandArgs(trailingOnly = TRUE)

yearID <- args_input[1]
dataPath <- '/data/ChinaFuturesTickData/TickData'

################################################################################
## STEP 1:
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv", 
                              showProgress=TRUE,
                              colClasses = list(character = c("nights","days"))
                          ) %>%
  .[(which(substr(days, 1, 4) == yearID) %>% .[1]) :                 ## 第一个
    (which(substr(days, 1, 4) == yearID) %>% .[length(.)])] %>%      ## 最后一个
  .[, nights := paste0(nights, "_night")]

if(as.numeric(yearID) == 2016){
   ## 2016年的截止到 20161103
  ChinaFuturesCalendar <- ChinaFuturesCalendar[1: which(days == 20161103)]
}
# if(as.numeric(yearID) == 2013){
#   ## 2013年的开始于
#   ChinaFuturesCalendar <- ChinaFuturesCalendar[which(substr(ChinaFuturesCalendar$nights,1,8) %>%
#                                               as.numeric() == 20130705) :
#                                               nrow(ChinaFuturesCalendar)]
# }
################################################################################

## k <- which(ChinaFuturesCalendar$days == 20111125) 
################################################################################
## STEP 2:
################################################################################
for (k in 1:nrow(ChinaFuturesCalendar)) {
  ## source('./R/Rconfig/myDay.R')
  print(paste0("#-----------------------------------------------------------------#"))
  ## ===========================================================================
  ## 开始时间标记
  beginTime <- Sys.time()

  ## 交易日期
  tradingDay <- ChinaFuturesCalendar[k, days]

  ## 夜盘数据
  if (grepl('[0-9]', ChinaFuturesCalendar[k, nights])) {
    dataNightPath <- ChinaFuturesCalendar[k, nights]
  } else {
    dataNightPath <- NA
  }

  ## 日盘数据
  dataDayPath <- ChinaFuturesCalendar[k, days]
  ## ===========================================================================

  ## ---------------------------------------------------------------------------
  print(
      paste(
        yearID, ":==> Trading Day :==>", tradingDay, "at", Sys.time()
      )
  )
  ## ---------------------------------------------------------------------------

  ## ===========================================================================
  mysql <- mysqlFetch('FromDC')
  mysqlDataFile <- dbGetQuery(mysql,
                                paste("SELECT TradingDay FROM", "log",
                                      "WHERE year(TradingDay) = ", yearID)
                                ) %>% as.data.table() %>%
                                .[, TradingDay := gsub('-','',TradingDay)]
  ## ===========================================================================

  ##############################################################################
  if ( tradingDay %in% mysqlDataFile$TradingDay) {
    print(paste0("#---------- Data has already been written in MySQL!!! ------------#"))
    print(paste0("# <", tradingDay, "> <--: at ", Sys.time()))
    print(paste0("#-----------------------------------------------------------------#"))
    next
  } else {
    ## -------------------------------------------------------------------------
    source('./R/FromDC/FromDC2mysql_01_read_data.R')
    ## -------------------------------------------------------------------------

    ## =========================================================================
    if (nrow(dt) != 0) {
      ## -----------------------------------------------------------------------
      source('./R/FromDC/FromDC2mysql_02_manipulate_data.R')
      source('./R/FromDC/FromDC2mysql_03_transform_bar.R')
      source('./R/FromDC/FromDC2mysql_04_mysql_data.R')
      ## -----------------------------------------------------------------------
    } else {
      ## -----------------------------------------------------------------------
      source('./R/FromDC/FromDC2mysql_05_NA_data.R')
      ## -----------------------------------------------------------------------
    }
    ## =========================================================================
  }
  ##############################################################################
  print(paste0("# <", tradingDay, "> <--: at ", Sys.time()))
}


################################################################################
## log
## 2011-10-10: 数据接收在 14:55 后断线了，所以和交易所公布的收盘价格可能有出入
################################################################################
