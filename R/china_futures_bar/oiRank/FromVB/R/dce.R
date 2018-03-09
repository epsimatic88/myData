rm(list = ls())

library(data.table)
library(magrittr)
library(RSelenium)
library(rvest)

################################################################################
setwd("C:/Users/Administrator/Desktop/ExchDataFetch")
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
## SHFE: 上期所
## 需要用到 javascript 爬虫
## 1. RSelenium
## 2. rvest
## 3. XML
################################################################################
exchURL <- "http://www.dce.com.cn/publicweb/quotesdata/memberDealPosiQuotes.html"

################################################################################
## 后台开启一下命令
## 
## cd Desktop
## java -jar selenium-server-standalone-3.0.0.jar
## 
################################################################################
remDr <- remoteDriver(remoteServerAddr ='localhost'
                      ,port = 4444
                      ,browserName = 'firefox')
remDr$getStatus()
# 需要保持开启
# remDr$open()
################################################################################
## 
################################################################################

# remDr$navigate(exchURL)



################################################################################
## 开始下载数据
## 1.持仓排名
## 2.仓单日报
################################################################################
exchURL <- "http://www.dce.com.cn/publicweb/quotesdata/memberDealPosiQuotes.html"
#-------------------------------------------------------------------------------
# 1.持仓排名
for(i in calendarYear){
  
  tempTradingDays <- ChinaFuturesCalendar[substr(days,1,4) == i, .(TradingDay = days)] %>% 
    .[,":="(year  = substr(TradingDay,1,4),
            month = substr(TradingDay,5,6),
            day   = substr(TradingDay,7,8))]
  
  
  setwd("./data/positionRank/DCE")
  if(!dir.exists(i)){
    dir.create(i)
  }
  
  for(k in 1:nrow(tempTradingDays)){
    # 需要保持开启
    # remDr$open(silent = TRUE)
    #remDr$open()
    #remDr$deleteAllCookies()
    #remDr$navigate(exchURL)
    # remDr$refresh()
    
    ##--------------------------------------------------------------------------
    ## 以下用于选择交易日期
    ##--------------------------------------------------------------------------
    ##
    ## source('../../dce_01.R', encoding = 'UTF-8', echo=TRUE)
    
    ##--------------------------------------------------------------------------
    ## 以下开始循环下载数据
    ##--------------------------------------------------------------------------
   
    ########################################################################## 
    for(kk in 1:1){
      ## 跑两次程序，保证数据下载到
      if(class(try( source('../../../R/dce_02.R', encoding = 'UTF-8', echo=TRUE) )) == 'try-error'){
        remDr$close()
        try(
          source('../../../R/dce_02.R', encoding = 'UTF-8', echo=TRUE)
        )
      }else{
        try(
          source('../../../R/dce_02.R', encoding = 'UTF-8', echo=TRUE)
        )
      }
    }
    ########################################################################## 
    

    # 等待 10 seconds
    # Sys.sleep(3)
    try(
      remDr$deleteAllCookies()
    )
    ## remDr$close()
      remDr$quit()
    
  }
  
  
  ##--- 返回上一层目录
  setwd("../../..")
}

################################################################################
################################################################################

################################################################################
exchURL <- "http://www.dce.com.cn/publicweb/quotesdata/wbillWeeklyQuotes.html"
#-------------------------------------------------------------------------------
# 2.仓单日报
for(i in calendarYear){
  
  tempTradingDays <- ChinaFuturesCalendar[substr(days,1,4) == i, .(TradingDay = days)] %>% 
    .[,":="(year  = substr(TradingDay,1,4),
            month = substr(TradingDay,5,6),
            day   = substr(TradingDay,7,8))]
  
  setwd("./data/warehouseReceipt/DCE")
  if(!dir.exists(i)){
    dir.create(i)
  }
  
  for(k in 1:nrow(tempTradingDays)){
    ############################################################################
    destFile <- paste0('./',tempTradingDays[k,year],'/',
                       tempTradingDays[k,TradingDay],'.xlsx')
    
    if(file.exists(destFile)){
      next
    }
    ########################################################################## 
    remDr$open()
    remDr$deleteAllCookies()
    remDr$navigate(exchURL)
    
    tempYear <- remDr$findElement(using = 'xpath', 
                                  value = paste0("//*/option[@value='",
                                                 tempTradingDays[k,year],"']")
    )
    tempYear$clickElement()
    
    if(tempTradingDays[k,as.numeric(month)] == 2){##当前月份
      for(mm in 1:2){
        ##-- 选择月份
        tempMonth <- remDr$findElement(using = 'xpath', 
                                       value = paste0("//*/option[@value='",
                                                      tempTradingDays[k,as.numeric(month)-1],"']"))
        tempMonth$clickElement()  
      }
    }else{
      ##-- 选择月份
      tempMonth <- remDr$findElement(using = 'xpath', 
                                     value = paste0("//*/option[@value='",
                                                    tempTradingDays[k,as.numeric(month)-1],"']"))
      tempMonth$clickElement()  
    }

    tempDay <- remDr$findElements(using = 'xpath', value = "//*/tbody/tr/td")
    
    ## 
    tempTable <- remDr$findElements(using = 'id', value = "calender")
    #R> length(tempTable)
    #R> tempTable[[1]]$highlightElement()
    tempCalendar <- tempTable[[1]]$getElementAttribute('outerHTML')[[1]] %>% 
      read_html() %>% 
      html_nodes('table') %>% 
      html_table(fill = TRUE) %>% 
      .[[1]]
    
    tempDayID <- unlist(t(tempCalendar))
    tempDayClick <- which(tempDayID == tempTradingDays[k,day])

    ## 最后确定选择的 Day
    tempDay[[tempDayClick]]$clickElement()
    Sys.sleep(1)
    
    tempAll <- remDr$findElements(using = 'xpath', value = "//*/input[contains(@onclick,'all')]")
    tempAll[[1]]$clickElement()
    Sys.sleep(1)
    ########################################################################## 
    ## 查看是否网页有更新
    ## 
    tempCheck <- remDr$findElements(using = "xpath",
                                    value = "//*/span")
    tempCheckInfo <- sapply(1:length(tempCheck), function(ii){
      y <- tempCheck[[ii]]$getElementAttribute('outerHTML')[[1]] %>% 
        read_html() %>% 
        html_nodes('span') %>% 
        html_text() %>% 
        gsub("\\n|\\t","",.) %>% 
        strsplit(.," |：") %>% 
        unlist()
    }) %>% unlist()
    
    ##-- 如果数据表格没有更新，则跳过
    if(!any(grepl(tempTradingDays[k,TradingDay],tempCheckInfo))){
      remDr$close()
      next
    }
    ########################################################################## 
    #-- 找到数据
    tempData <- remDr$findElement(using = 'class', value = 'dataArea')
    Sys.sleep(1)
    
    webData <- tempData$getElementAttribute('outerHTML')[[1]] %>% 
      read_html() %>% 
      html_nodes('table') %>% 
      html_table(fill = TRUE) %>% 
      .[[1]]
    
    print(head(webData,20))
    
    ##======================================================================
    if(!file.exists(destFile) & nrow(webData) != 0){
      openxlsx::write.xlsx(webData, file = destFile,
                           colNames = TRUE, rowNames = FALSE)
    }
    ##======================================================================
    Sys.sleep(1)
    remDr$close()
    
    ## Progress bar
    pb <- txtProgressBar(min = 0, max = nrow(tempTradingDays), style = 3)
    # update progress bar
    setTxtProgressBar(pb, k)
  }
  
  ##--- 返回上一层目录
  setwd("../../..")
}
