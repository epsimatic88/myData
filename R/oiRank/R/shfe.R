################################################################################
## shfe.R
## 用于下载上期所期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################
rm(list = ls())

library(methods)
library(data.table)
library(magrittr)
library(RSelenium)
library(parallel)
library(rvest)

################################################################################
setwd("/home/william/Documents/oiRank")
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
# for(i in 1:nrow(ChinaFuturesCalendar)){

#   tempURL <- paste0(exchURL, ChinaFuturesCalendar[i,days])

#   ## ===========================================================================
#   ## 设置路径
#   ## ---------------------------------------------------------------------------
#   tempPath <- "./data/SHFE/"
#   if (!dir.exists(tempPath)) dir.create(tempPath)

#   setwd(tempPath)
#   if(!dir.exists(ChinaFuturesCalendar[i,substr(days,1,4)])){
#     dir.create(ChinaFuturesCalendar[i,substr(days,1,4)])
#   }
#   ## ===========================================================================

#   ## ===========================================================================
#   ## 判断文件是不是已经下载了
#   ## ---------------------------------------------------------------------------
#   destFile <- paste0(ChinaFuturesCalendar[i,substr(days,1,4)], "/",
#                      ChinaFuturesCalendar[i,days],".xlsx")

#   if(file.exists(destFile)){
#     ##--- 返回上一层目录
#     setwd("../..")
#     next
#   }
#   ## ===========================================================================
  
#   ## ===========================================================================
#   ## 开始准备下载数据
#   # 需要保持开启
#   # ----------------------------------------------------------------------------
#   remDr$open()
#   remDr$navigate(tempURL)
#   Sys.sleep(1)
#   temp <- remDr$findElements(using = 'id', value = 'li_all')[[1]]
  
#   #-- 点击选择全部合约
#   #-- 看看是不是已经选择了
#   #-  for(k in seq(k,20)){
#   #-    temp$highlightElement()
#   #-  }

#   #-- 点击选择全部合约
#   tempWeb <- temp$clickElement()
#   Sys.sleep(2)
#   #-- 找到数据
#   tempData <- remDr$findElements(using = 'id', value = 'addedtable')[[1]]
  
#   webData <- tempData$getElementAttribute('outerHTML')[[1]] %>% 
#     read_html() %>% 
#     html_node('table') %>% 
#     html_table(fill = TRUE)
  
#   if(!file.exists(destFile)){
#     openxlsx::write.xlsx(webData, file = destFile,
#                          colNames = FALSE, rowNames = FALSE)
#   }
  
  
#   # 等待 10 seconds
#   # Sys.sleep(3)
#   # remDr$quit()
#   try(
#     system('pkill -f firefox')
#   )

#   ##--- 返回上一层目录
#   setwd("../..")
  
#   ## Progress bar
#   pb <- txtProgressBar(min = 0, max = nrow(ChinaFuturesCalendar), style = 3)
#   # update progress bar
#   setTxtProgressBar(pb, i)
# }


shfeData <- function(i) {
  tempURL <- paste0(exchURL, ChinaFuturesCalendar[i,days])

  ## ===========================================================================
  ## 设置路径
  ## ---------------------------------------------------------------------------
  tempPath <- "./data/SHFE/"
  if (!dir.exists(tempPath)) dir.create(tempPath)

  setwd(tempPath)
  if(!dir.exists(ChinaFuturesCalendar[i,substr(days,1,4)])){
    dir.create(ChinaFuturesCalendar[i,substr(days,1,4)])
  }
  ## ===========================================================================

  ## ===========================================================================
  ## 判断文件是不是已经下载了
  ## ---------------------------------------------------------------------------
  destFile <- paste0(ChinaFuturesCalendar[i,substr(days,1,4)], "/",
                     ChinaFuturesCalendar[i,days],".xlsx")

  if(file.exists(destFile)){
    ##--- 返回上一层目录
    # setwd("../..")
    # next
    return(NULL)
  }
  ## ===========================================================================
  
  ## ===========================================================================
  ## 开始准备下载数据
  # 需要保持开启
  # ----------------------------------------------------------------------------
  remDr$open(silent = TRUE)
  remDr$navigate(tempURL)
  Sys.sleep(1)
  temp <- remDr$findElements(using = 'id', value = 'li_all')[[1]]
  
  #-- 点击选择全部合约
  #-- 看看是不是已经选择了
  #-  for(k in seq(k,20)){
  #-    temp$highlightElement()
  #-  }

  #-- 点击选择全部合约
  tempWeb <- temp$clickElement()
  Sys.sleep(1)
  #-- 找到数据
  tempData <- remDr$findElements(using = 'id', value = 'addedtable')[[1]]
  
  webData <- tempData$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_node('table') %>% 
    html_table(fill = TRUE)
  
  if(!file.exists(destFile) | file.size(destFile) < 1000){
    openxlsx::write.xlsx(webData, file = destFile,
                         colNames = FALSE, rowNames = FALSE)
  }
  
  
  ## ===========================================================================
  ## 关闭浏览器
  # 等待 10 seconds
  # Sys.sleep(3)
  # remDr$quit()
  try({
    system('pkill -f firefox')
    system('rm -rf /tmp/rust_mozprofile*')
  })
  ## ===========================================================================

  # ## ===========================================================================
  # ##--- 返回上一层目录
  # setwd("../..")
  # ## ===========================================================================
}

## =============================================================================
sapply(1:nrow(ChinaFuturesCalendar), function(i){
  try(
    shfeData(i)
    )
  setwd("../..")
})
## =============================================================================
