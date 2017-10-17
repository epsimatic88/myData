################################################################################
##! cffex.R
## 这是主函数:
## 用于从 中金所 网站爬虫期货交易的日行情数据
## daily
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-16
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("cffex.R")

setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})

################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days"))) %>% 
                              .[days < format(Sys.Date(),'%Y%m%d')]

exchCalendar <- ChinaFuturesCalendar[,":="(calendarYear = substr(days,1,4),
                                           calendarYearMonth = substr(days,1,6),
                                           calendarDay = substr(days,7,8))]
exchURL <- "http://www.cffex.com.cn/sj/hqsj/rtj/"

dataPath <- '/home/william/Documents/Exchange/CFFEX/'
# dataPath <- "./data/Bar/Exchange/CFFEX/"
################################################################################


################################################################################
## STEP 2: 开启并行计算模式，下载数据 
################################################################################
cl <- makeCluster(round(detectCores()/4), type='FORK')
parSapply(cl, 1:nrow(ChinaFuturesCalendar), function(i){
    tempDir <- paste0(dataPath,exchCalendar[i,calendarYear])

    if (!dir.exists(tempDir)) dir.create(tempDir)

    tempURL <- paste0(exchURL, exchCalendar[i,calendarYearMonth],'/',
                      exchCalendar[i,calendarDay],'/',
                      exchCalendar[i,days],'_1.csv')
    destFile <-  paste0(tempDir,'/',exchCalendar[i,days],'.csv')

    while ( !file.exists(destFile) | file.size(destFile) < 200) {
      try(download.file(tempURL, destFile, mode = 'wb'))
    }
})
stopCluster(cl)
