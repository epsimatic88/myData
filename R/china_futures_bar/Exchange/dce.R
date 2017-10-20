################################################################################
##! dce.R
## 这是主函数:
## 用于从 大商所 网站爬虫期货交易的日行情数据
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
logMainScript <- c("czce.R")

if (class(try(setwd('/home/fl/myData/'))) == 'try-error') {
  setwd('/run/user/1000/gvfs/sftp:host=192.168.1.166,user=fl/home/fl/myData')
}
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(RSelenium)
options(width=150)
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
dataPath <- '/home/william/Documents/Exchange/DCE/'
# dataPath <- "./data/Bar/Exchange/DCE/"

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
exchURL <- "http://www.dce.com.cn/publicweb/quotesdata/dayQuotesCh.html"
#-------------------------------------------------------------------------------


fetchData <- function(year, month, day, exchURL, tryNo) {
  tempYear  <- year
  tempMonth <- month
  tempDay   <- day

  ##-- 品种
  remDr$open(silent = T)
  remDr$deleteAllCookies()
  remDr$navigate(exchURL)
  Sys.sleep(1)

  ##--------------------------------------------------------------------------
  ## 以下用于选择交易日期
  ##--------------------------------------------------------------------------
  ##-- 选择年份
  ##-- 选择年份
  if (tempYear ==  format(Sys.Date(),"%Y")) {
    NULL
  } else {
    temp <- remDr$findElement(using = 'xpath', 
                              value = paste0("//*/option[@value='",
                                             tempYear,"']")
                            )
    temp$clickElement()
  }

  if (tempMonth == as.numeric(format(Sys.Date(),"%m"))) {## 当前月份
    for(mm in 1:2){
      ##-- 选择月份
      ## 如果时当月，需要点击两次
      temp <- remDr$findElement(using = 'xpath', 
                                value = paste0("//*/option[@value='",
                                               as.numeric(tempMonth)-1,"']"))
      temp$clickElement()  
    }
  } else {
    ##-- 选择月份
    temp <- remDr$findElement(using = 'xpath', 
                              value = paste0("//*/option[@value='",
                                             as.numeric(tempMonth)-1,"']"))
    temp$clickElement()  
  }


  ##-- 选择天，需要跑循环
  tempDayInfo <- remDr$findElements(using = 'xpath', value = "//*/tbody/tr/td")

  ## 
  tempTable <- remDr$findElements(using = 'id', value = "calender")

  tempCalendar <- tempTable[[1]]$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('table') %>% 
    html_table(fill = TRUE) %>% 
    .[[1]]

  tempDayID <- unlist(t(tempCalendar))
  tempDayClick <- which(tempDayID == tempDay)

  ## 最后确定选择的 Day
  tempDayInfo[[tempDayClick]]$clickElement()
  Sys.sleep(ifelse(tryNo <= 3, 2, sqrt(tryNo)+2))

  ## ---------------------------------------------------------------------------
  tempHeader <- remDr$findElement(using = 'class', value = 'tradeResult02')
  tempQueryDay <- tempHeader$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('p span') %>% 
    html_text() %>% 
    gsub('.*([0-9]{8}).*','\\1',.)

  if (tempQueryDay != paste0(tempYear, tempMonth, tempDay)) return(data.table())
  ## ---------------------------------------------------------------------------

  ## ---------------------------------------------------------------------------
  tempTableAll <- remDr$findElement(using = 'class', value = 'dataArea')

  webData <- tempTableAll$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('table') %>% 
    html_table(fill = TRUE) %>% 
    .[[1]] 
  ## ---------------------------------------------------------------------------    
  
  remDr$close()
  try({
    system('pkill -f firefox')
    system('pkill -f geckodriver')
    system('rm -rf /tmp/rust_mozprofile*')
  })

  return(webData)
}


dceData <- function(i) {
  ## ===========================================================================
  tempDir <- paste0(dataPath,exchCalendar[i,calendarYear])

  if (!dir.exists(tempDir)) dir.create(tempDir)

  tempTradingDay <- exchCalendar[i,days]
  tempYear <- exchCalendar[i,calendarYear]
  tempMonth <- exchCalendar[i,calendarMonth]
  tempDay <- exchCalendar[i,calendarDay]

  destFile <- paste0(dataPath,'/',tempYear,'/',
                     tempTradingDay,'.xlsx')

  print('## -------------------- ##')
  print(paste0('## i:', i))
  print(tempTradingDay)
  print('## -------------------- ##')

  if (file.exists(destFile)) {
    tempDataFile <- readxl::read_excel(destFile)
    if (nrow(tempDataFile) > 20 & grepl('总计',tempDataFile[nrow(tempDataFile),1])) return(NULL)
  }

  ## ===========================================================================
  ## 开始网页爬虫
  ##--------------------------------------------------------------------------
  ## 以下开始循环下载数据
  ##--------------------------------------------------------------------------

  ## ===========================================================================
  tryNo <- 0
  while( (!file.exists(destFile) | file.size(destFile) < 10000) & (tryNo < 20) ){
    tryNo <- tryNo + 1

    webData <- fetchData(tempYear,tempMonth,tempDay,exchURL,tryNo)

    if (nrow(webData) > 20 & grepl('总计',webData[nrow(webData),1])) {
      print(webData)
      openxlsx::write.xlsx(webData, file = destFile,
                           colNames = TRUE, rowNames = FALSE)
      break
    }
  }
  ## ===========================================================================

}


## =============================================================================
sapply(1:nrow(ChinaFuturesCalendar), function(i){
  try(dceData(i))
})
## =============================================================================

