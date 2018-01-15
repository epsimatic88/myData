################################################################################
## nanhuaIndex.R
## 获取南华商品指数
##
## Author: William Fang
## Date  : 2017-08-21
################################################################################
# rm(list = ls())

Sys.setlocale(locale = 'Chinese')
################################################################################
ROOT_PATH <- '/home/fl/myData'
DATA_PATH <- '/home/fl/myData/R/MarketIndex/data/pudong'

setwd(ROOT_PATH)
source('./R/Rconfig/myInit.R')
################################################################################


##------------------------------------------------------------------------------
if(Sys.info()['sysname'] == 'Windows'){
  Sys.setenv("R_ZIPCMD" = "D:/Program Files/Rtools/bin/zip.exe") ## path to zip.exe
}
##------------------------------------------------------------------------------

if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1,days]) stop('NOT TradingDay!!!')

## -----------------------------------------------------------------------------
library(httr)
## 浦东金融网
## http://www.ifsp.org.cn/SITE_KGJ_WEB/zshq/gpzs.html
url <- 'http://180.96.8.44/pfsb/ashx/StockAjaxHandler.ashx'
postData <- list(type = "eg",
             key  = 'NHQHSPZS')
r <- POST("http://180.96.8.44/pfsb/ashx/StockAjaxHandler.ashx", 
          body = postData)
page <- content(r, 'text')
## -----------------------------------------------------------------------------

resTable <- page %>% 
            read_html(encoding = 'utf8') %>% 
            html_nodes('table') %>% 
            html_table() %>% 
            .[[1]] %>% 
            as.data.table()


if (! resTable[grep('南华商品指数',名称), grepl('15:00',时间)] |
      resTable[grep('南华沪锌指数',名称), grepl('00:00',时间)]) stop('NOT 15:00！！！')

resTable[grep(':', 时间), 时间 := as.character(currTradingDay[1,days],'%Y%m%d')]
resTable[grep('/', 时间), 时间 := as.character(lastTradingDay[1,days],'%Y%m%d')]
print(resTable)
## =============================================================================
fwrite(resTable, paste0(DATA_PATH,'/',
                        currTradingDay[1,gsub('-','',days)],
                        '_NanhuaIndex.csv'))
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

if (F) {
  ## 从南华期货网站下载 商品指数
  url <- "https://www.nanhua.net/ianalysis/varietyindex/index/NHCI.json"
  r <- httr::GET(url)
  page <- content(r, 'text')

  data <- strsplit(page, "\\],\\[") %>% 
      unlist() %>% 
      gsub('\\[|\\]', '', .)
  res <- lapply(1:length(data), function(i){
      temp <- data[i] %>% strsplit(., ',') %>% unlist()
      
      tempDate <- as.POSIXct(as.numeric(temp[1])/1000, origin = '1970-01-01')
      tempIndex <- temp[2]
      tempData <- data.table(TradingDay = tempDate, close = tempIndex)
  }) %>% rbindlist()

  print(res)
}



