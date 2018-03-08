## =============================================================================
## exch.R
## 从 上交所、深交所 下载 大宗交易 数据
## 
## AUTHOR   : fl@hicloud-investment.com
## DATE     : 2018-03-08
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
library(httr)
library(rjson)
library(downloader)

SAVE_PATH <- "/home/fl/myData/data/ChinaStocks/DZJY/FromExch"
if (!dir.exists(SAVE_PATH)) dir.create(SAVE_PATH, recursive = T)

## =============================================================================
## SSE
## 上交所大宗交易统计数据从 2003-01-20 开始正式公布
## ---
url <- "http://query.sse.com.cn/commonQuery.do"
urlHeaders = c("Accept" = "*/*",
"Accept-Encoding" = "gzip, deflate",
"Accept-Language" = "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6",
"Connection" = "keep-alive",
"DNT" = "1",
"Host" = "query.sse.com.cn",
"Referer" = "http://www.sse.com.cn/disclosure/diclosure/public/",
"User-Agent" = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3298.3 Safari/537.36")

payload <- list(
    sqlId              = 'COMMON_SSE_XXPL_JYXXPL_DZJYXX_L_1'
    # ,stockId            = ''
    ,startDate          = '1990-01-01'
    ,endDate            = format(Sys.Date(), '%Y-%m-%d')
    ,isPagination       = 'true'
    ,pageHelp.pageSize  = '50'
    ,pageHelp.pageNo    = '1'
    ,pageHelp.beginPage = '1'
    ,pageHelp.endPage   = '11'
    ,pageHelp.cacheSize = '1'
    )
r <- GET(url, query = payload, add_headers(urlHeaders))
p <- content(r, 'text')
info <- fromJSON(p) %>% 
    .$pageHelp

totalNo <- info$total
totalPage <- info$pageCount

dt <- lapply(1:totalPage, function(i){
    
    ## ------------------------------------------------
    payload$pageHelp.pageNo <- as.character(i)
    payload$pageHelp.beginPage <- as.character(i)
    ## 乘以 10 然后再加 1
    payload$pageHelp.endPage <- as.character(i*10 + 1)
    ## ------------------------------------------------

    ## ------------------------------------------------
    r <- GET(url, query = payload, add_headers(urlHeaders))
    p <- content(r, 'text')
    webData <- fromJSON(p) %>% 
        .$pageHelp %>% 
        .$data
    ## ------------------------------------------------

    ## ------------------------------------------------
    if (length(webData) != 0) {
        res <- lapply(webData, as.data.table) %>% rbindlist()
    } else {
        res <- data.table()
    }
    ## ------------------------------------------------

    return(res)
}) %>% rbindlist()

dt[, NUM := NULL]    ## 序号
setcolorder(dt, c('tradedate', 'stockid','abbrname',
                  'tradeprice','tradeamount','tradeqty',
                  'branchbuy','branchsell','ifZc'))

tempFile <- paste(SAVE_PATH, 'sse.csv', sep = '/')
fwrite(dt, tempFile)
## =============================================================================


