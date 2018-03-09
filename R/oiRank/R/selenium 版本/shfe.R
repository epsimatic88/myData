################################################################################
## shfe.R
## 用于下载上期所期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################


################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("shfe.R")

if (class(try(setwd('/home/fl/myData/'))) == 'try-error') {
  setwd('/run/user/1000/gvfs/sftp:host=192.168.1.166,user=fl/home/fl/myData')
}
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(RSelenium)
################################################################################
## STEP 1: 获取对应的交易日期
################################################################################
ChinaFuturesCalendar <- fread("./data/ChinaFuturesCalendar/ChinaFuturesCalendar.csv",
                              colClasses = list(character = c("nights","days"))) %>% 
                              .[days < format(Sys.Date(),'%Y%m%d')]

exchCalendar <- ChinaFuturesCalendar[,":="(calendarYear = substr(days,1,4),
                                           calendarYearMonth = substr(days,1,6),
                                           calendarMonth = substr(days,5,6),
                                           calendarDay = substr(days,7,8))]
dataPath <- '/home/william/Documents/oiRank/SHFE/'
# dataPath <- "./data/Bar/oiRank/SHFE/"

##------------------------------------------------------------------------------
if(Sys.info()['sysname'] == 'Windows'){
  Sys.setenv("R_ZIPCMD" = "D:/Program Files/Rtools/bin/zip.exe") ## path to zip.exe
}
##------------------------------------------------------------------------------


################################################################################
## SHFE: 上期所
exchURL <- "http://www.shfe.com.cn/statements/dataview.html?paramid=pm&paramdate="
################################################################################


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
################################################################################

shfeData <- function(i) {
  ## ===========================================================================
  tempDir <- paste0(dataPath,exchCalendar[i,calendarYear])

  if (!dir.exists(tempDir)) dir.create(tempDir, recursive = TRUE)
  ## ===========================================================================
  tempURL <- paste0(exchURL, exchCalendar[i,days])

  ## ===========================================================================
  ## 判断文件是不是已经下载了
  ## ---------------------------------------------------------------------------
  destFile <- paste0(tempDir, "/",
                     ChinaFuturesCalendar[i,days],".xlsx")

  if (file.exists(destFile)) return(NULL)
  ## ===========================================================================
  
  ## ===========================================================================
  ## 开始准备下载数据
  # 需要保持开启
  # ----------------------------------------------------------------------------
  remDr$open(silent = TRUE)
  remDr$navigate(tempURL)
  Sys.sleep(1)

  ## ---------------------------------------------------------------------------
  tempTitle <- remDr$findElements(using = 'id', value = 'datatitle')[[1]]
  tempQueryDay <- tempTitle$getElementAttribute('outerHTML')[[1]] %>% 
    read_html(encoding = 'GB18030') %>% 
    html_nodes('table') %>% 
    html_table() %>% 
    .[[1]] %>% 
    .[2, 'X1'] %>% 
    gsub('-','',.)
  if (tempQueryDay != exchCalendar[i,days]) return(NULL)
  ## ---------------------------------------------------------------------------

  temp <- remDr$findElements(using = 'id', value = 'li_all')[[1]]
  #-- 点击选择全部合约
  tempWeb <- temp$clickElement()
  Sys.sleep(1)
  #-- 找到数据
  tempData <- remDr$findElements(using = 'id', value = 'addedtable')[[1]]
  
  webData <- tempData$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_node('table') %>% 
    html_table(fill = TRUE)

  tryNo <- 0
  while ( (!file.exists(destFile) | file.size(destFile) < 1000) & (tryNo < 10) ){
    openxlsx::write.xlsx(webData, file = destFile,
                         colNames = FALSE, rowNames = FALSE)
    tryNo <- tryNo + 1
  }
  
  ## ===========================================================================
  ## 关闭浏览器
  try({
    system('pkill -f firefox')
    system('pkill -f geckodriver')
    system('rm -rf /tmp/rust_mozprofile*')
  })
  ## ===========================================================================
}

## =============================================================================
sapply(1:nrow(ChinaFuturesCalendar),shfeData)
## =============================================================================
