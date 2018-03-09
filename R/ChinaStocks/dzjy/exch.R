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
## 
## http://www.sse.com.cn/disclosure/diclosure/block/deal/
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
        res[, ":="(tradeqty = as.numeric(tradeqty) * 10000,
                   tradeamount = as.numeric(tradeamount) * 10000)]
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


## =============================================================================
## SZSE
## 深交所大宗交易统计数据从  开始正式公布
## ---
url <- "http://www.szse.cn/szseWeb/FrontController.szse"

## 搜索页面
payload_search <- list(
    ACTIONID      = '7'
    # ,AJAX          = 'AJAX-TRUE'
    ,CATALOGID     = '1932_phqzzqdzjy'
    ,TABKEY        = 'tab1'
    ,REPORT_ACTION = 'search'
    ,txtStart      = '2000-01-01'
    ,txtEnd        = Sys.Date()
    )
r <- GET(url, query = payload_search)
p <- content(r, 'text')
info <- p %>% 
    read_html() %>% 
    html_nodes(xpath = "//*[contains(text(),'当前第')]") %>% 
    html_text()
pageNo <- unlist(strsplit(info, ' ')) %>% 
    grep('共',., value = T) %>% 
    gsub('\\D', '', .) %>% 
    as.numeric()

tbls <- lapply(1:pageNo, function(i){
    payload_tbl <- list(
        ACTIONID        = '7'
        # ,AJAX            = 'AJAX-TRUE'
        ,CATALOGID       = '1932_phqzzqdzjy'
        ,TABKEY          = 'tab1'
        ,txtStart        = '2000-01-01'
        ,txtEnd          = Sys.Date()
        ,tab1PAGENO      = as.character(i)  ## 第几页
        # ,tab1PAGECOUNT   = '6'
        # ,tab1RECORDCOUNT = '128'
        # ,REPORT_ACTION   = 'navigate'
        )

    r <- GET(url, query = payload_tbl)
    p <- content(r, 'text')
    if (grepl("没有找到符合条件的数据", p)) {
        res <- data.table()
    } else {
        res <- p %>% 
            read_html() %>% 
            html_nodes('#REPORTID_tab1') %>% 
            html_table(fill = T) %>% 
            .[[1]] %>% 
            as.data.table() %>% 
            .[, 证券代码 := sprintf('%06d', 证券代码)]
    }

    return(res)
}) %>% rbindlist()

dt <- lapply(1:nrow(tbls), function(i){
    payload_data <- list(
        ACTIONID = '7'
        ,SOURCECATALOGID = '1932_phqzzqdzjy'
        ,CATALOGID = '1932_dzjyhz'
        ,TABKEY = 'tab1'
        ,DQRQ = tbls[i, 当前日期]
        ,ZQDM = tbls[i, 证券代码]
        ,JYLX = '000'
        )
    r <- GET(url, query = payload_data)
    p <- content(r, 'text')
    res <- p %>% 
        read_html() %>% 
        html_nodes('#REPORTID_tab2') %>% 
        html_table(fill = T) %>% 
        .[[1]] %>% 
        as.data.table()
    colnames(res) <- c('direction','DeptName','buyAmount','sellAmount')
    res[, ":="(
            buyAmount = gsub(',', '', buyAmount),
            sellAmount = gsub(',', '', sellAmount),
            TradingDay = tbls[i, 当前日期], 
            stockID = tbls[i, 证券代码],
            stockName = tbls[i, 证券简称]
            )]
    setcolorder(res, c('TradingDay', 'stockID', 'stockName',
                       colnames(res)[1:(ncol(res) - 3)]))
    return(res)
}) %>% rbindlist()

tempFile <- paste(SAVE_PATH, 'szse.csv', sep = '/')
fwrite(dt, tempFile)
## =============================================================================

