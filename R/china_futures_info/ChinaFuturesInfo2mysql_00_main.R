################################################################################
##! ChinaFuturesInfo2mysql_00_main.R
##
##  主要功能
##  用于录入 "/data/ChinaFuturesInfo/DongZheng_ZGC" 的 Info 信息,
##  该文件未来也可以用于 GTJA_ZGC 的录入，需要更改
##
##  最后得到的输出有：
##  包括：
##  1. Instrument_info
##  2. CommissionRate_info
##  
## Author: fl@hicloud-investment.com
## CreateDate: 2016-10-16
## UpdateDate: 2017-07-10
## 
##
################################################################################
## Rscript ./ChinaFuturesInfo2mysql_00_main.R

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("ChinaFuturesInfo2mysql_00_main.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
  # source('./R/Rconfig/myFread.R')
  # source('./R/Rconfig/myDay.R')
  # source('./R/Rconfig/myBreakTime.R')
  # source('./R/Rconfig/dt2DailyBar.R')
  # source('./R/Rconfig/dt2MinuteBar.R')
})
################################################################################




################################################################################
## 如果需要读取包含中文的 csv 文件，需要增加对 Encoding 的识别。
## guess_encoding(all_data_file[1])
## 特别需要注意中文编码的问题，所以使用 ‘readr' 里面的 guess_encoding
################################################################################
source_zgc <- c('DongZheng_ZGC', 'GTJA_ZGC')
##
## 是否要包含历史的数据
## 如果想要包含所有的历史数据，请把 include_history 设置为 TRUE
include_history <- FALSE


for(j in source_zgc){
  ## ===========================================================================
  ## 数据存储的路径
  ## ---------------------------------------------------------------------------
  dataPath <- paste0("/data/ChinaFuturesInfo/", j)
  ## ===========================================================================

  ## ===========================================================================
  ## ---------------------------------------------------------------------------
  ## read data 
  source('./R/china_futures_info/ChinaFuturesInfo2mysql_01_read_data.R')
  source('./R/china_futures_info/ChinaFuturesInfo2mysql_02_process_Instrument_info.R')
  ## ===========================================================================
  
  ## ===========================================================================
  ## 如果是日盘
  ## 还需要处理 CommissionRate_info
  if(as.numeric(format(Sys.time(), "%H")) %between% c(6, 18)){
    ## ----- 日盘 ----- ##
    source('./R/china_futures_info/ChinaFuturesInfo2mysql_03_process_CommissionRate_info.R')
  }
  ## ===========================================================================
}
