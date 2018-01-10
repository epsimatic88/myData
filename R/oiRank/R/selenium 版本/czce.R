################################################################################
## czce.R
## 用于下载郑商所期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("czce.R")

# setwd('/home/fl/myData/')
if (class(try(setwd('/home/fl/myData/'))) == 'try-error') {
  setwd('/run/user/1000/gvfs/sftp:host=192.168.1.166,user=fl/home/fl/myData')
}

suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(RSelenium)
Sys.setlocale("LC_ALL", 'en_US.UTF-8')

ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days"))) %>% 
                              .[days < format(Sys.Date(),'%Y%m%d')]

exchCalendar <- ChinaFuturesCalendar[,":="(calendarYear = substr(days,1,4),
                                           calendarYearMonth = substr(days,1,6),
                                           calendarMonth = substr(days,5,6),
                                           calendarDay = substr(days,7,8))]
dataPath <- '/home/william/Documents/oiRank/CZCE/'
# dataPath <- "./data/Bar/Exchange/CZCE/"

##------------------------------------------------------------------------------
if(Sys.info()['sysname'] == 'Windows'){
  Sys.setenv("R_ZIPCMD" = "D:/Program Files/Rtools/bin/zip.exe") ## path to zip.exe
}
##------------------------------------------------------------------------------

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


czceData <- function(i) {
  tempDir <- paste0(dataPath,exchCalendar[i,calendarYear])

  if (!dir.exists(tempDir)) dir.create(tempDir, recursive = TRUE)

  tempYear <- exchCalendar[i,calendarYear]
  tempTradingDay <- exchCalendar[i,days]
      
  tempURL <- ifelse(tempTradingDay < '20151001',
                    paste0(exchURL1, tempYear, '/datatradeholding/', tempTradingDay, '.txt'),
                    paste0(exchURL2, tempYear, '/', tempTradingDay, '/FutureDataHolding.xls'))
  
  destFile <-  paste0(dataPath, '/', exchCalendar[i,calendarYear],
                      "/", tempTradingDay,
                      ifelse(tempTradingDay < '20151001','.txt','.xls'))

  tryNo <- 0
  ## ---------------------------------------------------------------------------
  while( (!file.exists(destFile) | file.size(destFile) < 1000) & (tryNo < 20)){
    if (class(try(download.file(tempURL, destFile, mode = 'wb'))) == 'try-error') {
      tempPage <- paste0('http://www.czce.com.cn/portal/exchange/jyxx/pm/pm', tempTradingDay, '.html')
      
      webData <- tempPage %>% 
                  read_html(encoding = 'GB18030') %>% 
                  html_nodes('table') %>% 
                  html_table(fill=TRUE, header=FALSE) %>% 
                  .[-1] %>% 
                  .[[1]] %>% 
                  as.data.table() %>% 
                  rbind(data.table(X1 = c('','')), ., fill = TRUE)
      webData[1, X1 := paste0('郑州商品交易所持仓排行表(',
                               as.Date(as.character(tempTradingDay), format = '%Y%m%d'),
                               ')')]

      cols <- colnames(webData)[2:ncol(webData)]
      webData[, (cols) := lapply(.SD, function(x){
        gsub(',','',x)
      }), .SDcols = cols]

      # grep("名次", tempData$X1) %>% length()

      webTitle <- tempPage %>% 
                  read_html(encoding = 'GB18030') %>% 
                  html_nodes('font') %>% 
                  html_text() %>% 
                  .[grep('品种|合约代码',.)]

      for (j in 1:length(webTitle)) {
        tempRow <- grep("名次", webData$X1)[j] - 1
        webData[tempRow, X1 := webTitle[j]]
      }

      print(webData)

      fwrite(webData, destFile, col.names = FALSE)
    }
    tryNo <- tryNo + 1
  }
  ## ---------------------------------------------------------------------------
}

################################################################################
## STEP 2: 开启并行计算模式，下载数据 
################################################################################
cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
parSapply(cl, 1:nrow(ChinaFuturesCalendar), function(i){
  ## ---------------------------------------------------------------------------
  try(czceData(i))
  ## ---------------------------------------------------------------------------
})
stopCluster(cl)


# ## =============================================================================
# sapply(1:nrow(ChinaFuturesCalendar), function(i){
#   try(czceData(i))
# })
# ## =============================================================================
