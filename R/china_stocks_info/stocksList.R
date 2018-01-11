## =============================================================================
## stocksList.R
## 
## 用于获取 上交所 深交所 股票列表
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
## =============================================================================


## =============================================================================
## 上交所
## 
## -----------------------------------------------------------------------------
url <- "http://query.sse.com.cn/security/stock/getStockListData2.do"
headers <- c(
            "Accept"          = "*/*",
            "Accept-Encoding" = "gzip, deflate",
            "Accept-Language" = "zh-CN,en-US;q=0.8,zh;q=0.6,en;q=0.4,zh-TW;q=0.2",
            "Connection"      = "keep-alive",
            "DNT"             = "1",
            "Host"            = "query.sse.com.cn",
            "Referer"         = "http://www.sse.com.cn/assortment/stock/list/share/",
            "User-Agent"      = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36"
            )
stockList <- list(isPagination       = "true",
                  stockCode          = "",
                  csrcCode           = "",
                  areaName           = "",
                  stockType          = "1",
                  ## ----------------------
                  pageHelp.cacheSize = "1",
                  pageHelp.beginPage = "1",
                  pageHelp.pageSize  = "5000", ## 最大到 5000
                  pageHelp.pageNo    = "1",
                  pageHelp.endPage   = "21")
## -----------------------------------------------------------------------------

r <- GET(url, query = stockList, add_headers(headers))
page <- content(r, 'text')
jsonFile <- fromJSON(page)
# summary(jsonFile)

# jsonFile$pageHelp$pageCount
#                  Length Class  Mode     
# areaName          1     -none- character
# csrcCode          1     -none- character
# downloadFileName  0     -none- NULL     
# execlStream       0     -none- NULL     
# jsonCallBack      0     -none- NULL     
# pageHelp         13     -none- list     
# result           25     -none- list     
# stockCode         1     -none- character
# stockType         1     -none- character

temp <- jsonFile$result
dt <- lapply(1:length(temp), function(i){
    as.data.table(temp[[i]])
}) %>% rbindlist()
# print(dt)

dt <- dt[, .(stockID = COMPANY_CODE, stockName = COMPANY_ABBR, 
             stockID_B = SECURITY_CODE_B, stockName_B = SECURITY_ABBR_B,
             listingDate = LISTING_DATE,
             exchID = 'sh'
           )]
dt[stockName_B == '-', ":="(
  stockID_B = NA, stockName_B = NA)] 

mysql <- mysqlFetch('china_stocks_info')
dbSendQuery(mysql, "delete from stocks_list where exchID = 'sh'")
dbWriteTable(mysql, 'stocks_list', dt, row.names = F, append = T)
dbDisconnect(mysql)
## =============================================================================



## =============================================================================
## 深交所
## 
## -----------------------------------------------------------------------------
## A 股票
url_A <- "http://www.szse.cn/szseWeb/ShowReport.szse?SHOWTYPE=xlsx&CATALOGID=1110&tab2PAGENO=1&ENCODE=1&TABKEY=tab2"

suppFunction({
  GET(url_A, write_disk('/home/fl/temp/szA.xlsx', overwrite = TRUE))
  })

dtA <- readxl::read_excel('/home/fl/temp/szA.xlsx') %>% 
    as.data.table() %>% 
    .[, .(stockID = 公司代码,
          stockName = 公司简称,
          listingDate = A股上市日期,
          exchID = 'sz')]

## -----------------------------------------------------------------------------
## B 股票
url_B <- "http://www.szse.cn/szseWeb/ShowReport.szse?SHOWTYPE=xlsx&CATALOGID=1110&tab3PAGENO=1&ENCODE=1&TABKEY=tab3"

suppFunction({
  GET(url_B, write_disk('/home/fl/temp/szB.xlsx', overwrite = TRUE))
  })

dtB <- readxl::read_excel('/home/fl/temp/szB.xlsx') %>% 
    as.data.table() %>% 
    .[, .(stockID = 公司代码,
          stockName = 公司简称,
          stockID_B = B股代码,
          stockName_B = B股简称)]

dt <- merge(dtA, dtB, by = c('stockID','stockName'), all.x = TRUE)

mysql <- mysqlFetch('china_stocks_info')
dbSendQuery(mysql, "delete from stocks_list where exchID = 'sz'")
dbWriteTable(mysql, 'stocks_list', dt, row.names = F, append = T)
dbDisconnect(mysql)
## =============================================================================

