rm(list = ls())

library(data.table)
library(magrittr)
library(RSelenium)
library(rvest)

################################################################################
## setwd("C:/Users/Administrator/Desktop/ExchDataFetch")
setwd("~/ExchDataFetch")
################################################################################

ChinaFuturesCalendar <- fread("./R/ChinaFuturesCalendar.csv") %>% 
  .[days <= gsub("-","",Sys.Date() - 1)] %>% 
  .[,.(days)]

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
exchURL <- "http://www.shfe.com.cn/statements/dataview.html?paramid=pm&paramdate="

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
# 
# 
################################################################################
## 开始下载数据
## 1.持仓排名
## 2.仓单日报
################################################################################

#-------------------------------------------------------------------------------
# 1.持仓排名
for(i in 1:nrow(ChinaFuturesCalendar)){
  # i = 1
  tempURL <- paste0(exchURL, ChinaFuturesCalendar[i,days])
  
  setwd("./data/positionRank/SHFE")
  if(!dir.exists(ChinaFuturesCalendar[i,substr(days,1,4)])){
    dir.create(ChinaFuturesCalendar[i,substr(days,1,4)])
  }

  destFile <- paste0(ChinaFuturesCalendar[i,substr(days,1,4)], "/",
                     ChinaFuturesCalendar[i,days],".xlsx")
  if(file.exists(destFile)){
    
    ##--- 返回上一层目录
    setwd("../../..")
    next
  }
  
  # 需要保持开启
  # remDr$open(silent = TRUE)
  remDr$open(silent = TRUE)
  remDr$navigate(tempURL)
  Sys.sleep(1)
  temp <- remDr$findElements(using = 'id', value = 'li_all')[[1]]
  
  #-- 看看是不是已经选择了
#-  for(k in seq(k,20)){
#-    temp$highlightElement()
#-  }

  #-- 点击选择全部合约
  tempWeb <- temp$clickElement()
  Sys.sleep(2)
  #-- 找到数据
  tempData <- remDr$findElements(using = 'id', value = 'addedtable')[[1]]
  
  webData <- tempData$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_node('table') %>% 
    html_table(fill = TRUE)
  
  if(!file.exists(destFile)){
    openxlsx::write.xlsx(webData, file = destFile,
                         colNames = FALSE, rowNames = FALSE)
  }
  
  
  # 等待 10 seconds
  # Sys.sleep(3)
  remDr$close()
  
  ##--- 返回上一层目录
  setwd("../../..")
  
  ## Progress bar
  pb <- txtProgressBar(min = 0, max = nrow(ChinaFuturesCalendar), style = 3)
  # update progress bar
  setTxtProgressBar(pb, i)
}

################################################################################
#-------------------------------------------------------------------------------
# 2.仓单日报
# 2.仓单日报

for(i in 1:nrow(ChinaFuturesCalendar)){
  if(ChinaFuturesCalendar[i,days] == 20130821){
    ## no table
    ##--- 返回上一层目录
    next
  }
  # i = 1
  tempURL <- paste0(exchURL, ChinaFuturesCalendar[i,days])
  
  setwd("./data/warehouseReceipt/SHFE")
  if(!dir.exists(ChinaFuturesCalendar[i,substr(days,1,4)])){
    dir.create(ChinaFuturesCalendar[i,substr(days,1,4)])
  }
  
  destFile <- paste0(ChinaFuturesCalendar[i,substr(days,1,4)], "/",
                     ChinaFuturesCalendar[i,days],".xlsx")
  if(file.exists(destFile)){
    
    ##--- 返回上一层目录
    setwd("../../..")
    next
  }
  
  # 需要保持开启
  # remDr$open(silent = TRUE)
  remDr$open()
  remDr$navigate(tempURL)
  ## remDr$maxWindowSize()
  
  tempWarehouse <- remDr$findElements(using = 'id', value = 'dailystock')
  # length(tempWarehouse)
  # tempWarehouse[[1]]$highlightElement()
  #-- 点击选择 仓单日报
  tempWarehouse[[1]]$clickElement()
  Sys.sleep(1)
  ##############################################################################
  ## 上期所在 20140519 这天开始改用新的网页
  ##############################################################################
  if(ChinaFuturesCalendar[i,days] < 20140519){
    #-- 找到数据
    tempData <- remDr$findElements(using = 'tag name', value = 'iframe')
    # length(tempData)
    
    tempTable <- tempData[[1]]$getElementAttribute('outerHTML')[[1]] %>% 
      read_html() %>% 
      html_nodes('iframe') %>% 
      html_attr('src') %>% 
      paste0("http://www.shfe.com.cn/",.)
    
    if(class(try(tempTable %>% 
                 read_html() %>% 
                 html_nodes('table') %>% 
                 html_table(fill = TRUE))) == "try-error"){
      remDr$close()
      ##--- 返回上一层目录
      setwd("../../..")
      next
    }
    
    tempwebData <- tempTable %>% 
      read_html() %>% 
      html_nodes('table') %>% 
      html_tables(fill = TRUE) 
    
    if(length(tempwebData) < 1){
      remDr$close()
      ##--- 返回上一层目录
      setwd("../../..")
      next
    }else{
      webData <- tempwebData[[1]]
    }
    
  }else{
    tempData <- remDr$findElements(using = 'id', value = 'divtable')
    ## length(tempData)  
    
    webData <- tempData[[1]]$getElementAttribute('outerHTML')[[1]] %>% 
      read_html() %>% 
      html_nodes('table') %>% 
      html_table(fill = TRUE) %>% 
      .[[1]] %>% 
      .[,1:4]
  }
  
  if(!file.exists(destFile)){
    openxlsx::write.xlsx(webData, file = destFile,
                         colNames = FALSE, rowNames = FALSE)
  }
  
  # 等待 10 seconds
  # Sys.sleep(3)
  remDr$close()
  try(remDr$quit())
  ##--- 返回上一层目录
  setwd("../../..")
  
  ## Progress bar
  pb <- txtProgressBar(min = 0, max = nrow(ChinaFuturesCalendar), style = 3)
  # update progress bar
  setTxtProgressBar(pb, i)
}
