################################################################################
## cffex.R
## 用于下载中金所期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################
rm(list = ls())

library(data.table)
library(magrittr)
library(RSelenium)
library(parallel)

################################################################################
setwd("/home/william/Documents/oiRank")
################################################################################

ChinaFuturesCalendar <- fread("./R/ChinaFuturesCalendar.csv") %>% 
  .[days <= gsub("-","",Sys.Date() - 1)] %>% 
  .[,.(days)]

exchCalendar <- ChinaFuturesCalendar[,":="(calendarYear = substr(days,1,4),
                                           calendarYearMonth = substr(days,1,6),
                                           calendarDay = substr(days,7,8))]
################################################################################
## CFFEX: 中期所 
##        
## 1. IC：中证500       --> 2015-04-16
## 2. IF：沪深300       --> 2010-04-16
## 3. IH：上证50        --> 2015-04-16
## 4. T ：10年期国债    --> 2015-03-20
## 5. TF：5年期国债     --> 2013-09-06
################################################################################
exchURL <- "http://www.cffex.com.cn/fzjy/ccpm/"

dataSet <- data.table(productID = c('IC','IF','IH','T','TF'),
                      startDate = c('20150416','20100416','20150416',
                                    '20150320','20130906'))

#-------------------------------------------------------------------------------
# 1.持仓排名
for (i in 1:nrow(dataSet)) {
  
  tempCalendar <- exchCalendar[days >= dataSet[i,startDate]]
  
  ## ===========================================================================
  ## 设置路径
  ## ---------------------------------------------------------------------------
  tempPath <- "./data/CFFEX"
  if (!dir.exists(tempPath)) dir.create(tempPath)
  setwd(tempPath)
  ## ===========================================================================
  
  ## ===========================================================================
  ## 开始下载数据
  ## ---------------------------------------------------------------------------
  for (tempYear in tempCalendar[,unique(calendarYear)]) {
    ## -------------------------------------------------------------------------
    ## 1. 
    ## -------------------------------------------------------------------------
    if(!dir.exists(tempYear)) dir.create(tempYear)
    ## -------------------------------------------------------------------------
    tempYearCalendar <- tempCalendar[calendarYear == tempYear]
    ## =========================================================================
    # for (k in 1:nrow(tempYearCalendar)) {
    #   tempURL <- paste0(exchURL, tempYearCalendar[k,calendarYearMonth],'/',
    #                     tempYearCalendar[k,calendarDay],'/',
    #                     dataSet[i,productID],'_1.csv')

    #   destFile <-  paste0("./",tempYear,'/',tempCalendar[calendarYear == tempYear][k,days]
    #                       ,'_',dataSet[i,productID],'.csv')

    #   ## -----------------------------------------------------------------------
    #   # while(! file.exists(destFile) | file.size(destFile) < 3000){
    #   while(! file.exists(destFile) | file.size(destFile) < 2000){
    #     try(download.file(tempURL, destFile, mode = 'wb'))
    #     # Sys.sleep(10)
    #   }
    #   ## -----------------------------------------------------------------------
    # }

    cl <- makeCluster(round(detectCores()/4*3), type = 'FORK')
    parSapply(cl, 1:nrow(tempYearCalendar), function(k){
      tempURL <- paste0(exchURL, tempYearCalendar[k,calendarYearMonth],'/',
                        tempYearCalendar[k,calendarDay],'/',
                        dataSet[i,productID],'_1.csv')

      destFile <-  paste0("./",tempYear,'/',tempCalendar[calendarYear == tempYear][k,days]
                          ,'_',dataSet[i,productID],'.csv')

      ## -----------------------------------------------------------------------
      # while(! file.exists(destFile) | file.size(destFile) < 3000){
      while(! file.exists(destFile) | file.size(destFile) < 1000){
        try(download.file(tempURL, destFile, mode = 'wb'))
        # Sys.sleep(10)
      }
      ## -----------------------------------------------------------------------
    })
    stopCluster(cl)
  ## ===========================================================================
  }

  ## ===========================================================================
  ##--- 返回上一层目录
  setwd("../..")
  ## ===========================================================================
}
