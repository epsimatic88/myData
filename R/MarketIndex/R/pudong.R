################################################################################
## shfe.R
## 用于下载上期所期货公司持仓排名数据
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################
# rm(list = ls())

Sys.setlocale(locale = 'Chinese')
################################################################################
# ROOT_PATH <- '/home/william/Documents/MarketIndex'
# DATA_PATH <- '/home/william/Documents/MarketIndex/data/pudong'

ROOT_PATH <- 'Y:/myData/R/MarketIndex'
DATA_PATH <- 'Y:/myData/R/MarketIndex/data/pudong'

setwd(ROOT_PATH)
source('./R/myInit.R')
library(RSelenium)
################################################################################


##------------------------------------------------------------------------------
if(Sys.info()['sysname'] == 'Windows'){
  Sys.setenv("R_ZIPCMD" = "D:/Program Files/Rtools/bin/zip.exe") ## path to zip.exe
}
##------------------------------------------------------------------------------

if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1,days]) stop('NOT TradingDay!!!')

################################################################################
## 后台开启一下命令
## 
## cd Desktop
## java -jar selenium-server-standalone-3.0.0.jar
## 
remDr <- remoteDriver(remoteServerAddr ='localhost'
                      ,port = 4444
                      ,browserName = 'firefox')
remDr$getStatus()
remDr$open(silent = TRUE)
################################################################################


## NanhauIndex
url <- "http://180.96.8.44/pfsb/Speed/NHQHIndex.aspx"
remDr$navigate(url)
Sys.sleep(5)

tempPage <- remDr$findElements(using = 'class', value = 'DataContainer')[[1]]
resTable <- tempPage$getElementAttribute('outerHTML')[[1]] %>% 
    read_html() %>% 
    html_nodes('table') %>% 
    html_table() %>% 
    as.data.table()
# print(resTable)

if (! resTable[grep('南华商品指数',名称), grepl('15:00',时间)] |
      resTable[grep('南华沪锌指数',名称), grepl('00:00',时间)]) stop('NOT 15:00！！！')

resTable[grep(':', 时间), 时间 := as.character(currTradingDay[1,days],'%Y%m%d')]
resTable[grep('/', 时间), 时间 := as.character(lastTradingDay[1,days],'%Y%m%d')]
print(resTable)
## =============================================================================
fwrite(resTable, paste0(DATA_PATH,'/',
                        currTradingDay[1,gsub('-','',days)],
                        '_NanhuaIndex.csv'))
remDr$close()
## =============================================================================

## =============================================================================
nanhua <- resTable[grep('南华商品指数',名称)] %>% 
          .[, .(TradingDay = 时间, close = 现价)]
mysql <- mysqlFetch('MarketIndex')
dbWriteTable(mysql, 'Nanhua', nanhua, append = T, row.names = F)
## =============================================================================


## =============================================================================
## 之前有几天没有更新的数据
if (F) {
  allFiles <- list.files(DATA_PATH, pattern = '.NanhuaIndex.csv')
  for (f in allFiles) {
    tradingDay <- substr(f, 1, 8)
    temp <- fread(paste0(DATA_PATH, '/', f)) %>% 
          .[grep('南华商品指数',名称)] %>% 
          .[, .(TradingDay = tradingDay, close = 现价)]
    mysql <- mysqlFetch('MarketIndex')
    dbWriteTable(mysql, 'Nanhua', temp, append = T, row.names = F)
  }
}
## =============================================================================

## =============================================================================
## 历史的数据
if (F) {
  file <- "/home/william/Documents/MarketIndex/data/南华商品指数.xlsx"

  dt <- readxl::read_excel(file) %>% as.data.table() %>% 
          .[!is.na(日期)]
  colnames(dt) <- c('TradingDay','open','high','low','close',
                    'turnover','volume')
  dt <- dt[, .(TradingDay, close)]

  ## ===========================================================================
  source('myInit.R')
  mysql <- mysqlFetch('MarketIndex')
  dbWriteTable(mysql, 'Nanhua', dt, append = T, row.names = F)
  ## ===========================================================================
}

