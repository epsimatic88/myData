## =============================================================================
## jrj.R
##
## 下载 金融界 股票历史涨跌停 次数统计
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-06
## =============================================================================

## =============================================================================
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(httr)
library(rjson)
## =============================================================================


## -----------------------------------------------------------------------------
allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]
SAVE_PATH <- "/home/fl/myData/data/ChinaStocks/Limit/FromJRJ"
## -----------------------------------------------------------------------------


fetch_limit_data_from_JRJ <- function(stockID) {
    url <- "http://stock.jrj.com.cn/action/zdt/queryHisZdtByStock.jspa"
    dt <- lapply(c(-1, 1), function(zdt){
        payload <- list(
        vname     = "stockHisZt",
        zdtType   = zdt,        ## 1: 涨停, -1: 跌停
        ps        = "100000",
        pn        = "1",
        sort      = "date",
        order     = "asc",      ## desc: 降序， asc: 升序
        stockcode = stockID)

        r <- GET(url, query = payload)
        p <- content(r, as = "text")
        infoData <- gsub("var stockHisZt =|;", "", p) %>% 
            fromJSON()

        if (infoData$summary$total == 0) {
            webData <- data.table()
        } else {
            webData <- infoData$data %>% 
                as.data.table()
        }
    }) %>% rbindlist()

    if (nrow(dt) == 0) return(data.table())

    dt[, stockID := stockID]
    setcolorder(dt, c('date', 'stockID', 
                      colnames(dt)[2:(ncol(dt)-1)]))
    dt <- dt[order(date)]
    return(dt)
}

# dt <- fetch_limit_data_from_JRJ('000025')

## =============================================================================
for (stock in allStocks$stockID) {
    print(stock)

    tempFile <- paste0(SAVE_PATH, '/', stock, '.csv')
    if (file.exists(tempFile)) next

    dt <- fetch_limit_data_from_JRJ(stock)
    if (nrow(dt) != 0) {
        fwrite(dt, tempFile)
    }

}
## =============================================================================
