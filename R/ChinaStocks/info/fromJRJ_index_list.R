## =============================================================================
## fromJRJ_index_list.R
## 
## 从 金融街 网站获取所有沪深的 市场指数信息
## 
## Author : fl@hicloud-investment.com
## Date   : 2018-01-10
## =============================================================================

## =============================================================================
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(httr)
library(rjson)
## =============================================================================

# if (format(Sys.Date(), '%Y-%m-%d') != currTradingDay[1, days]) stop('Not TradignDay !!!')

## =============================================================================
headers <- c(
            "Accept"          = "*/*",
            "Accept-Encoding" = "gzip, deflate",
            "Accept-Language" = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"      = "keep-alive",
            "DNT"             = "1",
            "Host"            = "q.jrjimg.cn",
            "Referer"         = "",
            "User-Agent"      = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            )
## =============================================================================

## =============================================================================
## 沪市指数
## Column:{id:0,code:1,name:2,lcp:3,op:4,hp:5,lp:6,np:7,ta:8,tm:9,hlp:10,pl:11,pa:12,pm:13},
## 
# url <- "http://summary.jrj.com.cn/zslbsh.shtml"

fetchIndex <- function(url, exchID) {
  payload <- list(
    q = paste0("cn|i|", exchID)
    ,c = "m"
    ,n = "hqa"
    ,o = "pl,d"
    ,p = "1099"
    )

  r <- GET(url, query = payload, add_headers(headers))
  page <- content(r, 'text')

  ## 获取页面数量
  data <- strsplit(page, '\\\n') %>% unlist()
  pageNo <- data[grep('Summary',data)] %>% 
      strsplit(., ',') %>% 
      unlist() %>% 
      .[grep('pages',.)] %>% 
      strsplit(., ':') %>% 
      unlist() %>% 
      .[grep('[0-9]',.)] %>% 
      as.numeric()


  dt <- lapply(1:pageNo, function(p){
    payload['p'] <- paste0(p, substr(payload['p'],2,4))
    r <- GET(url, query = payload, add_headers(headers))
    page <- content(r, 'text')
    data <- strsplit(page, '\\\n') %>% unlist() %>% 
        .[grep('",',.)]

    res <- lapply(1:length(data), function(i){
      temp <- data[i] %>% strsplit(., ",") %>% 
          unlist() %>% 
          gsub('\"|\\[|\\]', '', .)
      res <- data.table(t(temp))
    }) %>% rbindlist()
  }) %>% rbindlist()

  colnames(dt) <- c('exchID','indexID','indexName',
                    'lastClose', 'open', 'high', 'low', 
                    'lastPrice','volume', 'turnover',
                    'chg','pct','pa','pm')
  dt[, exchID := gsub('[0-9]','',exchID)]
  return(dt[, .(indexID, indexName, exchID)])
}

## =============================================================================
url <- "http://summary.jrj.com.cn/zslbsh.shtml"
sh <- fetchIndex(url, exchID = 'sh')

url <- "http://summary.jrj.com.cn/zslbsz.shtml"
sz <- fetchIndex(url, exchID = 'sz')

dt <- list(sh, sz) %>% rbindlist()
mysql <- mysqlFetch('china_stocks_info')
dbWriteTable(mysql, 'index_list', dt, row.names = F, append = T)
dbDisconnect(mysql)
