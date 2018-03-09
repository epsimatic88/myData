################################################################################
## dce.R
## 用于下载大商所期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################

################################################################################
## STEP 0: 初始化，载入包，设定初始条件
################################################################################
rm(list = ls())
logMainScript <- c("dce.R")

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
dataPath <- '/home/william/Documents/oiRank/DCE/'
# dataPath <- "./data/Bar/Exchange/DCE/"

##------------------------------------------------------------------------------
if(Sys.info()['sysname'] == 'Windows'){
  Sys.setenv("R_ZIPCMD" = "D:/Program Files/Rtools/bin/zip.exe") ## path to zip.exe
}
##------------------------------------------------------------------------------


################################################################################
## 开始下载数据
## 1.持仓排名
## 2.仓单日报
################################################################################
exchURL <- "http://www.dce.com.cn/publicweb/quotesdata/memberDealPosiQuotes.html"
#-------------------------------------------------------------------------------


################################################################################
## DCE: 大商所
## 需要用到 javascript 爬虫

remDr <- remoteDriver(remoteServerAddr ='localhost'
                      ,port = 4444
                      ,browserName = 'firefox')
remDr$getStatus()
################################################################################



identifyTradingDay <- function(year, month, day, tryNo) {
  tempYear  <- year
  tempMonth <- month
  tempDay   <- day

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
  # Sys.sleep(ifelse(tryNo <= 3, 2, sqrt(tryNo)+2))
  Sys.sleep(1)
  ## ---------------------------------------------------------------------------
  tempHeader <- remDr$findElement(using = 'class', value = 'tradeResult02')
  tempQueryDay <- tempHeader$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('p span') %>% 
    html_text() %>% 
    gsub('.*([0-9]{8}).*','\\1',.)

  if (tempQueryDay != paste0(tempYear, tempMonth, tempDay)) return(data.table())
  ## ---------------------------------------------------------------------------
}


dceData <- function(i) {
  ## ---------------------------------------------------------------------------
  remDr$open(silent = T)
  remDr$navigate(exchURL)
  Sys.sleep(1)
  ## ---------------------------------------------------------------------------

  ## ===========================================================================
  product <- c('a','b','m','y','p','c','cs','jd',
               'fb','bb','l','v','pp','j','jm','i')
  ## ===========================================================================

  ## ===========================================================================
  identifyTradingDay(exchCalendar[i,calendarYear], exchCalendar[i,calendarMonth],
                   exchCalendar[i,calendarDay], tryNo = 2)
  ## ===========================================================================

    ## =========================================================================
    if (exchCalendar[i, calendarYear] == '2010') {
      mysql <- mysqlFetch('FromDC', host = '192.168.1.166')
    } else {
      mysql <- mysqlFetch('china_futures_bar', host = '192.168.1.166')
    }
    
    allInstrumentIDNum <- dbGetQuery(mysql, paste("
                                                  select distinct InstrumentID
                                                  from minute
                                                  where tradingday = ",exchCalendar[i, days],
                                                  "and closeopeninterest != 0")) %>% as.data.table() %>%
      .[,":="(ProductID = gsub("[0-9]","",InstrumentID))]
    ## =========================================================================

    tempPreviousDay <- ChinaFuturesCalendar[days < exchCalendar[i,days]][.N]
    tempCurrFileNo <- list.files(paste0(dataPath, exchCalendar[i, calendarYear]), pattern = 
                                paste0(exchCalendar[i,days],".*")) %>% length()
    if (nrow(tempPreviousDay) != 0) {
    tempLastFileNo <- list.files(paste0(dataPath, exchCalendar[i, calendarYear]), pattern = 
                                paste0(tempPreviousDay[.N,days],".*")) %>% length()
    } else {
      tempLastFileNo <- 0
    }

    tryNo <- 0
    while ( ((tempCurrFileNo < nrow(allInstrumentIDNum) * 0.99) | 
          (tempCurrFileNo < tempLastFileNo * 0.95)) & (tryNo < 20) ){
      ## =======================================================================
      for (k in 1:length(product)) {
        productID <- product[k]
        try(
          source(paste0(getwd(),'/R/oiRank/R/dce_app.R'), encoding = 'UTF-8', echo=TRUE)
        )
      }
      ## =======================================================================

      tryNo <- tryNo + 1
      ## updating
      tempCurrFileNo <- list.files(paste0(dataPath, exchCalendar[i, calendarYear]), pattern = 
                            paste0(exchCalendar[i, days],".*")) %>% length()
    }

  ## ===========================================================================
  ## 关闭浏览器
  try({
    system('pkill -f firefox')
    system('pkill -f geckodriver')
    system('rm -rf /tmp/rust_mozprofile*')
  })
  ## ===========================================================================

  ##############################################################################
  dbDisconnect(mysql)
  for(mysql_conn in dbListConnections(MySQL()) )
    dbDisconnect(mysql_conn)
  ##############################################################################
}

## =============================================================================
for (i in 1:nrow(exchCalendar)) {
  try(
      dceData(i)
    )
}
## =============================================================================
