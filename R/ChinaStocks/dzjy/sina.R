## =============================================================================
## sina.R
## 从 新浪财经 下载 大宗交易 数据
##
## AUTHOR   : fl@hicloud-investment.com
## DATE     : 2018-03-08
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
library(httr)
library(rjson)
library(downloader)

SAVE_PATH <- "/home/fl/myData/data/ChinaStocks/DZJY/FromSina"
if (!dir.exists(SAVE_PATH)) dir.create(SAVE_PATH, recursive = T)
## =============================================================================


## =============================================================================
URL <- "http://vip.stock.finance.sina.com.cn/q/go.php/vInvestConsult/kind/dzjy/index.phtml"
payload <- list(
    p   = 10000,
    num = 100
    )
r <- GET(URL, query = payload, timeout(10))
p <- content(r, as = 'text', encoding = 'GB18030')
info <- p %>%
    read_html() %>%
    html_nodes('.pages') %>%
    html_text()
## 获取最大的页数
pageNo <- info %>%
    strsplit(., ' ') %>%
    unlist() %>%
    grep('[0-9]{1,}', ., value = T) %>%
    as.numeric() %>%
    max()

pb <- txtProgressBar(min = 1, max = pageNo, style = 3)
dt <- lapply(1:pageNo, function(i){
    # setTxtProgressBar(pb, i)
    print(i)

    payload$p <- i
    r <- GET(URL, query = payload)
    p <- content(r, as = 'text', encoding = 'GB18030')
    tbl <- p %>%
        read_html(encoding = 'GB18030') %>%
        html_nodes('#dataTable') %>%
        html_table(fill = T) %>%
        as.data.table()
    if (nrow(tbl) < 2) {
      stop("some wrong!")
      # return(data.table())
    }

    # Sys.sleep(1)

    colnames(tbl) <- paste0('X', 1:ncol(tbl))

    res <- tbl[!grepl('交易日期', X1)][!grepl('证券代码', X2)]
    colnames(res) <- unlist(tbl[1])

    return(res)
}) %>% rbindlist()

destFile <- paste(SAVE_PATH, 'sse_szse.csv', sep = '/')
fwrite(dt, destFile)
## =============================================================================
