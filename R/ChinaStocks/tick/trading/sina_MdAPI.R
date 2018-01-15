## =============================================================================
## sina_bAdj.R
##
## 用于获取 新浪财经 后复权因子
## http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/600008.phtml?year=2017&jidu=1
##
## Author : fl@hicloud-investment.com
## Date   : 2018-10-10
## =============================================================================

## =============================================================================
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(httr)
library(rjson)

headers_ip <- c(
  "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
  "Accept-Encoding" = "gzip, deflate",
  "Accept-Language" = "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6",
  "Cache-Control" = "max-age=0",
  "Connection" = "keep-alive",
  "DNT" = "1",
  "Host" = "www.xicidaili.com",
  "Referer" = "http://www.xicidaili.com/nn",
  "Upgrade-Insecure-Requests" = "1",
  "User-Agent" = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36"
  )

## =============================================================================
headers <- c(
            "Accept"                    = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
            "Accept-Encoding"           = "gzip, deflate",
            "Accept-Language"           = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"                = "keep-alive",
            "DNT"                       = "1",
            "Host"                      = "vip.stock.finance.sina.com.cn",
            "Referer"                   = "http://vip.stock.finance.sina.com.cn/corp/go.php/vMS_FuQuanMarketHistory/stockid/600482.phtml?year=2004&jidu=2",
            "Upgrade-Insecure-Requests" = "1",
            "User-Agent"                = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            )
## =============================================================================

getIpTables <- function(url) {
      if (class(try(r <- GET(url))) == 'try-error') {
        ip <- list()
      } else {
        page <- content(r, 'text')
        ip <- page %>%
          read_html() %>%
          html_nodes('table') %>%
          html_table() %>%
          .[[1]] %>%
          as.data.table()
      }
      return(ip)
}



fetchIp <- function(x) {
    ipTables_xici <- lapply(1:x, function(i){
      url <- paste0('http://www.xicidaili.com/nn/',i)

      ip <- getIpTables(url)
      return(ip)
    }) %>% rbindlist()
    ipTables_xici <- ipTables_xici[, .(url = IP地址,
                                       port = 端口)]



    ipTables <- ipTables_xici

    cl <- makeCluster(10, type = 'FORK')
    ipAvailable <- parSapply(cl, 1:nrow(ipTables), function(i){
      ip <- ipTables[i]
      if (class(try(r <- GET('http://vip.stock.finance.sina.com.cn/quotes_service/view/vMS_tradehistory.php?symbol=sh600156',
                        query = list(year = '2018-01-11',
                                     page = '1'),
                        add_headers(headers),
                        use_proxy(ip[1, url], ip[1, port]),
                        timeout(3))
      )) != "try-error") {
        return(i)
      }
    }) %>% unlist()
    stopCluster(cl)

    ipTables <- ipTables[ipAvailable]
    ipTables[, tryNo := 0]
    return(ipTables)
}

ipTables <- suppressMessages({
    suppressMessages({
        fetchIp(1)
    })
})

ipUseful <- FALSE


## =============================================================================

# if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1, days]) stop('Not TradingDay !!!')

## -----------------------------------------------------------------------------
allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]
tradingDay <- currTradingDay[1, gsub('-','',days)]
DATA_PATH <- paste0("/home/fl/myData/data/ChinaStocks/TradingData/FromSina/", 
                    tradingDay)
if (!dir.exists(DATA_PATH)) dir.create(DATA_PATH)
## -----------------------------------------------------------------------------


for (i in 1:nrow(allStocks)) {
  ## -------------------------------------------------------------------------
  stockID <- allStocks[i, stockID]
  destFile <- paste0(DATA_PATH, '/', stockID, '.xls')
  if (file.exists(destFile)) next

  if (!ipUseful) ip <- ipTables[sample(1:nrow(ipTables),1)]

  url <- paste0('http://market.finance.sina.com.cn/downxls.php?', 'date=', ymd(tradingDay), "&symbol=", allStocks[i, paste0(exchID, stockID)])
  GET(url, write_disk(destFile, overwrite = TRUE))
}
