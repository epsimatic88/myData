## =============================================================================
## exch.R
## 从 上交所、深交所 下载 融资融券 数据
## 
## DATE     : 2018-03-05
## AUTHOR   : fl@hicloud-investment.com
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
library(httr)
library(downloader)
# options(width = 200)


## =============================================================================
## SSE
## ---
## 融资融券业务于 2010-03-31 正式开始实行
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2010-03-31'][days < Sys.Date()]
## =============================================================================
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)

    tradingDay <- tradingDay %>% gsub("-", "", .)

    url <- paste0("http://www.sse.com.cn/market/dealingdata/overview/margin/a/rzrqjygk",
                  tradingDay, ".xls")

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/RZRQ/FromExch/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    tempFile <- paste0(tempPath, "/", as.Date(tradingDay, "%Y%m%d"), "_sse", ".xls")
    if (file.exists(tempFile)) {
        print("数据已下载")
        next
    }

    download.file(url, tempFile, mode = 'wb')
}
## =============================================================================


## =============================================================================
## SZSE
## ---
## 融资融券业务于 2010-03-31 正式开始实行
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2010-03-31'][days < Sys.Date()]
## =============================================================================
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)

    url <- paste0("http://www.szse.cn/szseWeb/ShowReport.szse?SHOWTYPE=xlsx&CATALOGID=1837_xxpl&txtDate=",
                  tradingDay, "&tab2PAGENO=1&ENCODE=1&TABKEY=tab2")

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/RZRQ/FromExch/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    tempFile <- paste0(tempPath, "/", tradingDay, "_szse", ".xlsx")
    if (file.exists(tempFile)) {
        print("数据已下载")
        next
    }

    suppFunction({
      GET(url, write_disk(tempFile, overwrite = TRUE))
      })
}
## =============================================================================
