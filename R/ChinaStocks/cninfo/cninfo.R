## =============================================================================
## cninfo.R
## 下载 巨潮信息网 上市公司相关数据
## 
## AUTHOR   ： fl@hicloud-investment.com
## DATE     ： 2018-03-10
## =============================================================================


## =============================================================================
suppressMessages({
  source('/home/fl/myData/R/Rconfig/myInit.R')
})
library(httr)
library(rjson)
## =============================================================================

## -----------------------------------------------------------------------------
allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]
SAVE_PATH <- "/home/fl/myData/data/ChinaStocks/Transaction/FromSina"
ChinaStocksCalendar <- ChinaStocksCalendar[days %between% c('2004-10-08', format(Sys.Date() -1,'%Y-%m-%d'))]
## -----------------------------------------------------------------------------


## -----------------------------------------------------------------------------
transform_stockID <- function(stockID) {
    if (substr(stockID, 1, 1) == '6' ) {
        mkt <- 'shmb'
    } else if (substr(stockID, 1, 2) == '00' & substr(stockID, 1, 3) != '002') {
        mkt <- 'szmb'
    } else if (substr(stockID, 1, 3) == '002' ) {
        mkt <- 'szsme'
    } else if (substr(stockID, 1, 2) == '30' ) {
        mkt <- 'szcn'
    }

    return(paste0(mkt, stockID))
}

allStocks[, webID := sapply(stockID, transform_stockID)]
## -----------------------------------------------------------------------------

URL_cninfo <- "http://www.cninfo.com.cn/information/companyinfo_n.html"

i <- 1
webID <- allStocks[i, webID]
url_root <- paste0(URL_cninfo, "?fulltext?", webID)

url_basic <- paste0("http://www.cninfo.com.cn/information/brief/", webID, ".html")
r <- GET(url_basic)
p <- content(r, as = 'text', encoding = 'GB18030')
basicInfo <- p %>% 
    read_html(., encoding = 'GB18030') %>% 
    html_nodes('.clear table') %>% 
    html_table(fill = T) %>% 
    .[[1]] %>% 
    as.data.table()

url_issue <- paste0("http://www.cninfo.com.cn/information/issue/", webID, ".html")
r <- GET(url_issue)
p <- content(r, as = 'text', encoding = 'GB18030')
issueInfo <- p %>% 
    read_html(., encoding = 'GB18030') %>% 
    html_nodes('.clear table') %>% 
    html_table(fill = T) %>% 
    .[[1]] %>% 
    as.data.table()

url_divident <- paste0("http://www.cninfo.com.cn/information/dividend/", webID, ".html")
r <- GET(url_divident)
p <- content(r, as = 'text', encoding = 'GB18030')
dividentInfo <- p %>% 
    read_html(., encoding = 'GB18030') %>% 
    html_nodes('.clear2 table') %>% 
    html_table(fill = T) %>% 
    .[[1]] %>% 
    as.data.table()

url_allotment <- paste0("http://www.cninfo.com.cn/information/allotment/", webID, ".html")
r <- GET(url_allotment)
p <- content(r, as = 'text', encoding = 'GB18030')
allotmentInfo <- p %>% 
    read_html(., encoding = 'GB18030') %>% 
    html_nodes('.clear2 table') %>% 
    html_table(fill = T) %>% 
    .[[1]] %>% 
    as.data.table()

url_management <- paste0("http://www.cninfo.com.cn/information/management/", webID, ".html")
r <- GET(url_management)
p <- content(r, as = 'text', encoding = 'GB18030')
managementInfo <- p %>% 
    read_html(., encoding = 'GB18030') %>% 
    html_nodes('.clear2 table') %>% 
    html_table(fill = T) %>% 
    .[[1]] %>% 
    as.data.table()

res <- list(basicInfo = basicInfo, 
            issueInfo = issueInfo, 
            dividentInfo = dividentInfo, 
            allotmentInfo = allotmentInfo, 
            managementInfo = managementInfo)

