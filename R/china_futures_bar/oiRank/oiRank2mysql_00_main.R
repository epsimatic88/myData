################################################################################
## oiRank2mysql_00_main.R
## 
## 从 4 个交易所爬虫 期货公司持仓排名： oiRank
## 1.CFFEX
## 2.CZCE
## 3.DCE
## 4.SHFE
## 
## Author: fl@hicloud-investment.com
## CreateDate: 2017-07-10
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("oiRank2mysql_00_main.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(RSelenium)

## =============================================================================
## 是否要包含历史的数据
## 如果想要包含所有的历史数据，请把 include_history 设置为 TRUE
includeHistory <- FALSE
#-------------------------------------------------------------------------------
dataPath <- ifelse(includeHistory,
             './data/oiRank/history',
             './data/oiRank/updating'     
 )

## =============================================================================
## 建立数据文件目录
exchID <- c('CFFEX','CZCE','DCE','SHFE')

## -----------------------------------------------------------------------------
for(i in exchID){
  if(!dir.exists(paste(dataPath, i, sep='/')))
    dir.create(paste(dataPath, i, sep='/'))
}
## =============================================================================

## =============================================================================
## 读取交易日历
ChinaFuturesCalendar <- fread("./R/ChinaFuturesCalendar.csv") %>% 
  .[days <= gsub("-","",Sys.Date() - 1)] %>% 
  .[,.(days)]

exchCalendar <- ChinaFuturesCalendar[,":="(calendarYear = substr(days,1,4),
                                           calendarYearMonth = substr(days,1,6),
                                           calendarDay = substr(days,7,8))]
## =============================================================================


