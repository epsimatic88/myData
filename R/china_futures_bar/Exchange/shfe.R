################################################################################
##! shfe.R
## 这是主函数:
## 用于从 上期所 网站爬虫期货交易的日行情数据
## daily
##
##
## 注意:
##
## Author: fl@hicloud-investment.com
## CreateDate: 2017-10-16
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
dataPath <- '/home/william/Documents/CZCE/'
# dataPath <- "./data/Bar/Exchange/CZCE/"

##------------------------------------------------------------------------------
if(Sys.info()['sysname'] == 'Windows'){
  Sys.setenv("R_ZIPCMD" = "D:/Program Files/Rtools/bin/zip.exe") ## path to zip.exe
}
##------------------------------------------------------------------------------

dataPath <- '/home/william/Documents/Exchange/SHFE/'
# dataPath <- "./data/Bar/Exchange/SHFE/"

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
################################################################################

shfeData <- function(i) {
  ## ===========================================================================
  tempDir <- paste0(dataPath,exchCalendar[i,calendarYear])

  if (!dir.exists(tempDir)) dir.create(tempDir)
  ## ===========================================================================

  tempURL <- paste0(exchURL, ChinaFuturesCalendar[i,days])

  ## ===========================================================================
  ## 判断文件是不是已经下载了
  ## ---------------------------------------------------------------------------
  destFile <- paste0(tempDir, "/",
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
  Sys.sleep(0.5)
  temp <- remDr$findElements(using = 'id', value = 'li_all')[[1]]

  #-- 点击选择全部合约
  tempWeb <- temp$clickElement()
  Sys.sleep(0.5)
  #-- 找到数据
  tempData <- remDr$findElements(using = 'id', value = 'addedtable')[[1]]
  
  webData <- tempData$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_node('table') %>% 
    html_table(fill = TRUE)

  print(webData)
  
  tryNo <- 0
  while( (!file.exists(destFile) | file.size(destFile) < 1000) & (tryNo < 10) ){
    openxlsx::write.xlsx(webData, file = destFile,
                         colNames = FALSE, rowNames = FALSE)
    tryNo <- tryNo + 1
  }
  
  ## ===========================================================================
  ## 关闭浏览器
  # 等待 10 seconds
  # Sys.sleep(3)
  # remDr$quit()
  try({
    system('pkill -f firefox')
    system('pkill -f geckodriver')
    system('rm -rf /tmp/rust_mozprofile*')
  })
  ## ===========================================================================
}

################################################################################
## STEP 2: 开启并行计算模式，下载数据 
################################################################################
# cl <- makeCluster(max(round(detectCores()*3/4),4), type='FORK')
# parSapply(cl, 1:10, function(i){
#   ## ---------------------------------------------------------------------------
#   try(shfeData(i))
#   ## ---------------------------------------------------------------------------
# })
# stopCluster(cl)


## =============================================================================
sapply(1:nrow(ChinaFuturesCalendar), function(i){
  try(shfeData(i))
})
## =============================================================================
