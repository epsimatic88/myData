## =============================================================================
## from163_market_index.R
## 
## 获取 中国股票 市场行情数据
## 
## 从 网易 获取市场指数的所有历史数据
## 
## Author : fl@hicloud-investment.com
## Date   : 2018-01-15
## =============================================================================

## =============================================================================
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(httr)
library(rjson)

SAVE_PATH <- "/home/fl/myData/data/MarketIndex/stocks_index/from163"
## =============================================================================

# if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1, days]) stop('Not TradignDay !!!')

## =============================================================================
headers <- c(
            "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding" = "gzip, deflate",
            "Accept-Language" = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"      = "keep-alive",
            "DNT"             = "1",
            "Host"            = "quotes.money.163.com",
            "Referer"         = "",
            "User-Agent"      = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            )
## =============================================================================


## =============================================================================
allIndex <- mysqlQuery(db = 'china_stocks_info',
                       query = 'select * from index_list
                                order by stockID')
## =============================================================================


fetchIndex <- function(id) {
  ## ------------------------------------------------------
  url <- "http://quotes.money.163.com/service/chddata.html"
  ## ------------------------------------------------------

  # id <- "000001"

  payload <- list(code = paste0(ifelse(allIndex[stockID == id, exchID == 'sh'], 0, 1), id),
                  # start = "19901219",
                  end = format(Sys.Date()-1, '%Y%m%d'),
                  fields = "TCLOSE;HIGH;LOW;TOPEN;LCLOSE;CHG;PCHG;VOTURNOVER;VATURNOVER")
  headers['Referer'] = paste0("http://quotes.money.163.com/trade/lsjysj_zhishu_", id, '.html')
  r <- GET(url, add_headers(headers), query = payload)

  if (r$status_code == '200') {
    destFile <- paste0(SAVE_PATH, '/', id, '.csv')
    writeBin(content(r, 'raw'), destFile)
  } else {
    cat(paste(id, '下载文件失败'))
    return(NA)
  }

  res <- suppressMessages({
    suppressWarnings({
      readr::read_csv(destFile, 
                      locale = locale(encoding = 'GB18030'))
    })}) %>% as.data.table() %>% 
    .[order(日期)]
  res[, 股票代码 := gsub("'", '', 股票代码)]
  ## ------------------------------------------------
  fwrite(res, destFile)
  ## ------------------------------------------------
  # return(res)
}

# temp <- fetchIndex("000001")
# temp <- fetchIndex("399998")

## =============================================================================
if (F) {
  cl <- makeCluster(8, type = "FORK")
  parSapply(cl, allIndex$stockID, fetchIndex)
  stopCluster(cl)
}
## =============================================================================


## =============================================================================
dataFiles <- list.files(SAVE_PATH)
dt <- lapply(dataFiles, function(x){
  f <- paste0(SAVE_PATH, '/', x)
  res <- fread(f) %>% 
    .[, ":="(成交量 = as.numeric(成交量),
             成交金额 = as.numeric(成交金额))]
}) %>% rbindlist()
dt <- dt[, .(日期, 股票代码, 名称,
             开盘价, 最高价, 最低价, 收盘价,
             成交量, 成交金额)]
colnames(dt) <- c('TradingDay','indexID','indexName',
                  'open','high','low','close',
                  'volume','turnover')
## =============================================================================

## =============================================================================
mysql <- mysqlFetch('MarketIndex')
dbSendQuery(mysql, 'truncate table stocks_index_from163;')
dbWriteTable(mysql, 'stocks_index_from163', dt, row.name = F, append = T)
dbDisconnect(mysql)
## =============================================================================
