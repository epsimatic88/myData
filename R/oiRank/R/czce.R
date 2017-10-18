################################################################################
## czce.R
## 用于下载郑商所期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################
rm(list = ls())

library(data.table)
library(magrittr)
library(RSelenium)
library(parallel)
library(rvest)
Sys.setlocale("LC_ALL", 'en_US.UTF-8')

################################################################################
setwd("/home/william/Documents/oiRank")
################################################################################

ChinaFuturesCalendar <- fread("./R/ChinaFuturesCalendar.csv") %>% 
  .[days <= gsub("-","",Sys.Date() - 1)] %>% 
  .[,.(days)]

calendarYear <- ChinaFuturesCalendar[, unique(substr(days,1,4))]
################################################################################
## CZCE: 郑商所
## 1.持仓排名
## 2.仓单日报
################################################################################
## 在 2015-10-01 之前
exchURL1 <- "http://www.czce.com.cn/portal/exchange/"

## 在 2015-10-01 之后
exchURL2 <- "http://www.czce.com.cn/portal/DFSStaticFiles/Future/"
## =============================================================================


## =============================================================================
## 
## -----------------------------------------------------------------------------
for(tempYear in calendarYear){
  
  tempDays <- ChinaFuturesCalendar[substr(days,1,4) == tempYear]
  
  ## ===========================================================================
  ## 设置路径
  ## ---------------------------------------------------------------------------
  tempPath <- "./data/CZCE/"
  if (!dir.exists(tempPath)) dir.create(tempPath)

  setwd(tempPath)
  if(!dir.exists(tempYear)) dir.create(tempYear)
  ## ===========================================================================
  
  ## ===========================================================================
  # for(k in 1:nrow(tempDays)){
  #   x <- tempDays[k,days]
  #   tempURL <- ifelse(x < '20151001',
  #                     paste0(exchURL1, tempYear, '/datatradeholding/', x, '.txt'),
  #                     paste0(exchURL2, tempYear, '/', x, '/FutureDataHolding.xls'))
    
  #   destFile <-  paste0("./",tempYear,"/",x,
  #                       ifelse(x < '20151001','.txt','.xls'))
  #   ## -------------------------------------------------------------------------
  #   while(!file.exists(destFile) | file.size(destFile) < 1000){
  #     try(download.file(tempURL, destFile, mode = 'wb'))
  #   }
  #   ## -------------------------------------------------------------------------
  # }

    cl <- makeCluster(round(detectCores()/4*3), type = 'FORK')
    parSapply(cl, 1:nrow(tempDays), function(k){
      x <- tempDays[k,days]
      tempURL <- ifelse(x < '20151001',
                        paste0(exchURL1, tempYear, '/datatradeholding/', x, '.txt'),
                        paste0(exchURL2, tempYear, '/', x, '/FutureDataHolding.xls'))
      
      destFile <-  paste0("./",tempYear,"/",x,
                          ifelse(x < '20151001','.txt','.xls'))
      ## -------------------------------------------------------------------------
      while(!file.exists(destFile) | file.size(destFile) < 1000){
        if (class(try(download.file(tempURL, destFile, mode = 'wb'))) == 'try-error') {
          tempPage <- paste0('http://www.czce.com.cn/portal/exchange/jyxx/pm/pm', x, '.html')
          
          tempData <- tempPage %>% 
                      read_html(encoding = 'GB18030') %>% 
                      html_nodes('table') %>% 
                      html_table(fill=TRUE, header=FALSE) %>% 
                      .[-1] %>% 
                      .[[1]] %>% 
                      as.data.table() %>% 
                      rbind(data.table(X1 = c('','')), ., fill = TRUE)
          tempData[1, X1 := paste0('郑州商品交易所持仓排行表(',
                                   as.Date(as.character(tempDays[k,days]), format = '%Y%m%d'),
                                   ')')]
          cols <- colnames(tempData)[2:ncol(tempData)]
          tempData[, (cols) := lapply(.SD, function(x){
            gsub(',','',x)
          }), .SDcols = cols]

          # grep("名次", tempData$X1) %>% length()

          tempTitle <- tempPage %>% 
                      read_html(encoding = 'GB18030') %>% 
                      html_nodes('font') %>% 
                      html_text() %>% 
                      .[grep('品种|合约代码',.)]
          # length(tempTitle)

          for (j in 1:length(tempTitle)) {
            tempRow <- grep("名次", tempData$X1)[j] - 1
            tempData[tempRow, X1 := tempTitle[j]]
          }

          fwrite(tempData, destFile, col.names = FALSE)
        }
      }
      ## -------------------------------------------------------------------------
    })
    stopCluster(cl)
  ## ===========================================================================

  ## ===========================================================================
  
  ## ===========================================================================
  ##--- 返回上一层目录
  setwd("../..")
  ## ===========================================================================
}
