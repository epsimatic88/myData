## =============================================================================
## fromSW_stocks_class.R
## 
## 从 申万宏远 网站下载股票行业分类
## http://www.swsindex.com/IdxMain.aspx
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
## =============================================================================

if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1, days]) stop('Not TradignDay !!!')

## =============================================================================
headers <- c(
            "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding" = "gzip, deflate",
            "Accept-Language" = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"      = "keep-alive",
            "DNT"             = "1",
            "Host"            = "www.swsindex.com",
            "Referer"         = "http://www.swsindex.com/idx0560.aspx?columnid=8905",
            "User-Agent"      = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            )
## =============================================================================

## =============================================================================
## 申万行业分类
url <- "http://www.swsindex.com/downloadfiles.aspx"
payload <- list(
  swindexcode= "SwClass",
  type       = "530",
  columnid   = "8892")

r <- GET(url, add_headers(headers), query = payload)

if (r$status_code == '200') {
  destFile <- paste0("/home/fl/myData/data/ChinaStocks/info/sw_class_",
                     currTradingDay[1, gsub('-','', days)], ".xls")
  writeBin(content(r, 'raw'), destFile)
}

