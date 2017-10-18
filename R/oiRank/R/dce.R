################################################################################
## dce.R
## 用于下载大商所期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################
rm(list = ls())

################################################################################
setwd("/home/william/Documents/oiRank")
################################################################################


################################################################################
source("./R/Rconfig/myInit.R")
################################################################################

ChinaFuturesCalendar <- fread("./R/ChinaFuturesCalendar.csv") %>% 
  .[days <= gsub("-","",Sys.Date() - 1)] %>% 
  .[,.(days)]

calendarYear <- ChinaFuturesCalendar[, unique(substr(days,1,4))]
##------------------------------------------------------------------------------
if(Sys.info()['sysname'] == 'Windows'){
  Sys.setenv("R_ZIPCMD" = "D:/Program Files/Rtools/bin/zip.exe") ## path to zip.exe
}
##------------------------------------------------------------------------------

################################################################################
## DCE: 大商所
## 需要用到 javascript 爬虫

remDr <- remoteDriver(remoteServerAddr ='localhost'
                      ,port = 4444
                      ,browserName = 'firefox')
remDr$getStatus()

################################################################################


################################################################################
## 开始下载数据
## 1.持仓排名
## 2.仓单日报
################################################################################
exchURL <- "http://www.dce.com.cn/publicweb/quotesdata/memberDealPosiQuotes.html"
#-------------------------------------------------------------------------------
# 1.持仓排名
for(i in calendarYear){
  ## ===========================================================================
  tempTradingDays <- ChinaFuturesCalendar[substr(days,1,4) == i, .(TradingDay = days)] %>% 
    .[,":="(year  = substr(TradingDay,1,4),
            month = substr(TradingDay,5,6),
            day   = substr(TradingDay,7,8))]

  ## ===========================================================================
  ## 设置路径
  ## ---------------------------------------------------------------------------
  tempPath <- "./data/DCE"
  if (!dir.exists(tempPath)) dir.create(tempPath)
  setwd(tempPath)
  if(!dir.exists(i)) dir.create(i)
  ## ===========================================================================
  
  tempPP <- data.table(id = seq(1:16),
                     conName = c('a','b','m','y','p','c','cs','jd',
                                 'fb','bb','l','v','pp','j','jm','i')
                     )

  ## ===========================================================================
  ## 以下开始循环下载数据
  ##----------------------------------------------------------------------------
  for(k in 1:nrow(tempTradingDays)){
    ############################################################################ 
    ## 跑两次程序，保证数据下载到
    if (class(try( source('../../R/dce_02.R', encoding = 'UTF-8', echo=TRUE) )) == 'try-error') {
      remDr$close()
      try(
        source('../../R/dce_02.R', encoding = 'UTF-8', echo=TRUE)
      )
    }
    ############################################################################ 

    ## =========================================================================
    if (i == '2010') {
      mysql <- mysqlFetch('FromDC', host = '192.168.1.166')
    } else {
      mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')
    }
    
    allInstrumentIDNum <- dbGetQuery(mysql, paste("
                                                  select distinct InstrumentID
                                                  from minute
                                                  where tradingday = ",tempTradingDays[k,as.numeric(TradingDay)],
                                                  "and closeopeninterest != 0")) %>% as.data.table() %>%
      .[,":="(ContractID = gsub("[0-9]","",InstrumentID))] %>%
      merge(.,tempPP, by.x = 'ContractID', by.y = 'conName')
    ## =========================================================================

    tempPreviousDay <- ChinaFuturesCalendar[days < tempTradingDays[k,TradingDay]][.N]
    tempCurrFileNo <- list.files(paste0("./",i,"/"), pattern = 
                                paste0(tempTradingDays[k,TradingDay],".*")) %>% length()
    if (nrow(tempPreviousDay) != 0) {
    tempLastFileNo <- list.files(paste0("./",i,"/"), pattern = 
                                paste0(tempPreviousDay[.N,days],".*")) %>% length()
    } else {
      tempLastFileNo <- 0
    }

    tryNo <- 0
    while( ((tempCurrFileNo < nrow(allInstrumentIDNum) * 0.99) | 
          (tempCurrFileNo < tempLastFileNo * 0.95)) & (tryNo < 20) ){
      try(
        source('../../R/dce_02.R', encoding = 'UTF-8', echo=TRUE)
      )

      tryNo <- tryNo + 1
      ## updating
      tempCurrFileNo <- list.files(paste0("./",i,"/"), pattern = 
                            paste0(tempTradingDays[k,TradingDay],".*")) %>% length()
    }
    ## =========================================================================
    # remDr$quit()
    ## =========================================================================
  }
  
  ##############################################################################
  dbDisconnect(mysql)
  for(mysql_conn in dbListConnections(MySQL()) )
    dbDisconnect(mysql_conn)
  ##############################################################################

  ##--- 返回上一层目录
  setwd("../..")
}

################################################################################
################################################################################
