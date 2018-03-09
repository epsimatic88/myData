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
for(i in 1:nrow(dataSet)){
  
  tempCalendar <- exchCalendar[days >= dataSet[i,startDate]]
  
  setwd("./data/positionRank/CFFEX/")
  
  #-----------------------------------------------------------------------------
  for(ii in tempCalendar[,unique(calendarYear)]){
    if(!dir.exists(ii)){
      dir.create(ii)
    }
    
    for(k in 1:nrow(tempCalendar[calendarYear == ii])){
      tempURL <- paste0(exchURL, tempCalendar[calendarYear == ii][k,calendarYearMonth],'/',
                        tempCalendar[calendarYear == ii][k,calendarDay],'/',
                        dataSet[i,productID],'_1.csv')
      
      destFile <-  paste0("./",ii,'/',tempCalendar[calendarYear == ii][k,days]
                          ,'_',dataSet[i,productID],'.csv')
      
      if(!file.exists(destFile)){
        try(
          download.file(tempURL, destFile, mode = 'wb')
        )}
    }
    
  }
  #-----------------------------------------------------------------------------
  ##--- 返回上一层目录
  setwd("../../../")
}
