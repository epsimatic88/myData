## =============================================================================
## exch.R
## 从 上交所、深交所 下载 龙虎榜 数据
## 
## DATE     : 2018-03-05
## AUTHOR   : fl@hicloud-investment.com
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
library(httr)
library(downloader)

## =============================================================================
## SSE
## ---
url <- "http://query.sse.com.cn/infodisplay/showTradePublicFile.do"
headers = c("Accept" = "*/*",
"Accept-Encoding" = "gzip, deflate",
"Accept-Language" = "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6",
"Connection" = "keep-alive",
"DNT" = "1",
"Host" = "query.sse.com.cn",
"Referer" = "http://www.sse.com.cn/disclosure/diclosure/public/",
"User-Agent" = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3298.3 Safari/537.36")

fetch_lhb_data_sse <- function(tradingDay) {
    # tradingDay <- '2018-02-27'
    # print(tradingDay)

    payload <- list(
        dateTx = tradingDay
        )

    r <- GET(url, query = payload, add_headers(headers))
    p <- content(r, 'parsed')

    webData <- p[which.max(sapply(p, length))] %>% 
        .[[1]] %>% 
        unlist() %>% 
        .[!grepl("\\\032", .)]
    return(webData)
}

## 2003-01-01
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2003-01-01'][days < Sys.Date()]
## =============================================================================
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/LHB/FromExch/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    tempFile <- paste0(tempPath, "/", tradingDay, "_sse.txt")
    if (file.exists(tempFile)) {
        print("数据已下载")
        next
    }

    dt <- fetch_lhb_data_sse(tradingDay)
    if (length(dt) > 10) {
        # print(dt)
        fwrite(as.data.table(dt), tempFile, col.names = F)
    }
}
## =============================================================================



## =============================================================================
## SZSE
## ---
## 2003-09-01
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2003-09-01'][days < Sys.Date()]
## =============================================================================
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)
    tempTradingDay <- format(as.Date(tradingDay), "%y%m%d")

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/LHB/FromExch/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    ## -------------------------------------------------------------------------
    tempFile_00 <- paste0(tempPath, "/", tradingDay, "_szse_00.txt")
    if (file.exists(tempFile_00)) {
        print("数据已下载")
        next
    }

    url_00 <- paste0("http://www.szse.cn/szseWeb/common/szse/files/text/jy/jy",
                    tempTradingDay, ".txt")
    download(url_00, tempFile_00)
    ## -------------------------------------------------------------------------

}
## =============================================================================

## 2007-07-01
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2007-07-01'][days < Sys.Date()]
## =============================================================================
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)
    tempTradingDay <- format(as.Date(tradingDay), "%y%m%d")

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/LHB/FromExch/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    ## -------------------------------------------------------------------------
    tempFile_02 <- paste0(tempPath, "/", tradingDay, "_szse_02.txt")
    if (file.exists(tempFile_02)) {
        print("数据已下载")
        next
    }

    url_02 <- paste0("http://www.szse.cn/szseWeb/common/szse/files/text/smeTxt/gk/sme_jy",
                    tempTradingDay, ".txt")
    download(url_02, tempFile_02)
    ## -------------------------------------------------------------------------

}
## =============================================================================

## 2009-10-30
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2009-10-30'][days < Sys.Date()]
## =============================================================================
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)
    tempTradingDay <- format(as.Date(tradingDay), "%y%m%d")

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/LHB/FromExch/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    ## -------------------------------------------------------------------------
    tempFile_30 <- paste0(tempPath, "/", tradingDay, "_szse_30.txt")
    if (file.exists(tempFile_30)) {
        print("数据已下载")
        next
    }

    url_30 <- paste0("http://www.szse.cn/szseWeb/common/szse/files/text/nmTxt/gk/nm_jy",
                    tempTradingDay, ".txt")
    download(url_30, tempFile_30)
    ## -------------------------------------------------------------------------

}
## =============================================================================
