rm(list = ls())

library(data.table)
library(magrittr)
library(RSelenium)

################################################################################
## setwd("C:/Users/Administrator/Desktop/ExchDataFetch")
setwd("~/ExchDataFetch")
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

#-------------------------------------------------------------------------------
# 1.持仓排名
for(i in calendarYear){
  
  tempDays <- ChinaFuturesCalendar[substr(days,1,4) == i]
  
  setwd("./data/positionRank/CZCE/")
  if(!dir.exists(i)){
    dir.create(i)
  }
  
  for(k in 1:nrow(tempDays)){
    x <- tempDays[k,days]
    tempURL <- ifelse(x < '20151001',
                      paste0(exchURL1,i,'/datatradeholding/',x,'.txt'),
                      paste0(exchURL2,i,'/',x,'/FutureDataHolding.xls'))
    
    destFile <-  paste0("./",i,"/",x,
                        ifelse(x < '20151001','.txt','.xls'))
    
    if(!file.exists(destFile)){
      try(
        download.file(tempURL, destFile, mode = 'wb')
      )
    }
  }
  
  ##--- 返回上一层目录
  setwd("../../..")

}


#-------------------------------------------------------------------------------
# 1.持仓排名
for(i in calendarYear){
  
  tempDays <- ChinaFuturesCalendar[substr(days,1,4) == i]
  
  setwd("./data/warehouseReceipt/CZCE/")
  if(!dir.exists(i)){
    dir.create(i)
  }
  
  for(k in 1:nrow(tempDays)){
    x <- tempDays[k,days]
    tempURL <- ifelse(x < '20151001',
                      paste0(exchURL1,i,'/datawhsheet/',x,'.txt'),
                      paste0(exchURL2,i,'/',x,'/FutureDataWhsheet.xls'))
    
    destFile <-  paste0("./",i,"/",x,
                        ifelse(x < '20151001','.txt','.xls'))
    
    if(!file.exists(destFile)){
      try(
        download.file(tempURL, destFile, mode = 'wb')
      )
    }
  }
  
  ##--- 返回上一层目录
  setwd("../../..")
  
}