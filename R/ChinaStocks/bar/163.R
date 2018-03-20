## =============================================================================
## 163.R
##
## 从 163 下载股票历史数据
##
## Author : fl@hicloud-investment.com
## Date   : 2018-03-05
## =============================================================================

## =============================================================================
setwd('/home/fl/myData/')
suppressMessages({
  source('./R/Rconfig/myInit.R')
})
library(httr)
library(rjson)
## =============================================================================

allStocks <- mysqlQuery(db = 'china_stocks_info',
                        query = 'select * from stocks_list') %>%
            .[order(stockID)]

SAVE_PATH <- "/home/fl/myData/data/ChinaStocks/Bar/From163"
if (!dir.exists(SAVE_PATH)) dir.create(SAVE_PATH, recursive = T)

## =============================================================================
fetch_bar_from_163 <- function(stockID) {
    ## ----------------------------------
    if (substr(stockID, 1, 2) %in% c('60')) {
        code = paste0(0, stockID)
    } else if (substr(stockID, 1, 3) %in% c('000','001','002','300')) {
        code = paste0(1, stockID)
    }
    ## ----------------------------------

    ## -------------------------------------------------------------------------
    url <- "http://quotes.money.163.com/service/chddata.html"
    headers <- c(
        "Accept"                    = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
        "Accept-Encoding"           = "gzip, deflate",
        "Accept-Language"           = "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6",
        "Connection"                = "keep-alive",
        "DNT"                       = "1",
        "Host"                      = "quotes.money.163.com",
        "Referer"                   = "http://quotes.money.163.com/trade/lsjysj_zhishu_000016.html",
        "Upgrade-Insecure-Requests" = "1",
        "User-Agent"                = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3298.3 Safari/537.36"
        )
    payload <- list(
        code = code,　　　　　
        start = '',    ## 开始时间，一般设置为上市时间
        end = format(Sys.Date(), '%Y%m%d'),　　　　　　## 结束时间，一般设置为当前时间
        fields = 'TOPEN;HIGH;LOW;TCLOSE;LCLOSE;CHG;PCHG;TURNOVER;VOTURNOVER;VATURNOVER;MCAP;TCAP'
        )
    if (class(try(
            r <- GET(url, query = payload, add_headers(headers))
        )) != 'try-error') {
        ## 返回二进制文件
        if (r$status_code == 200) {
            rawData <- content(r, 'raw')
            tempFile <- paste0('/tmp/', '163_', stockID, '.csv')
            writeBin(rawData, tempFile)
            res <- suppFunction(
                    readr::read_csv(tempFile, locale = locale(encoding = 'GB18030'))
                    ) %>% 
                as.data.table() %>% 
                .[, 股票代码 := gsub("'", '', 股票代码)]
        } else {
            res <- data.table()
        }
    } else {
        res <- data.table()
    }

    return(res)
    ## -------------------------------------------------------------------------
}
## =============================================================================

## =============================================================================
if (F) {
for (stock in allStocks$stockID) {
    print(stock)

    tempFile <- paste0(SAVE_PATH, '/', stock, '.csv')
    # if (file.exists(tempFile)) next

    dt <- fetch_bar_from_163(stock)
    if (length(dt) != 0) fwrite(dt, tempFile)
    # Sys.sleep(1)
}
}
## =============================================================================


## =============================================================================
## 删除掉所有文件
system("rm -rf /tmp/163_*")
cl <- makeCluster(4, type = 'FORK')
parSapply(cl, allStocks$stockID, function(stock){
    tempFile <- paste0(SAVE_PATH, '/', stock, '.csv')
    
    if (!file.exists(tempFile)) {
        dt <- fetch_bar_from_163(stock)
        if (length(dt) != 0) fwrite(dt, tempFile)
    }
})
stopCluster(cl)
system("rm -rf /tmp/163_*")
## =============================================================================


## =============================================================================
allFiles <- SAVE_PATH %>% 
    list.files(., pattern = '\\.csv', full.names = T)
cl <- makeCluster(4, type = 'FORK')
dt <- parLapply(cl, allFiles, function(f){
    res <- fread(f, colClass = c(股票代码 = 'character',
                                 成交量 = 'numeric',
                                 成交金额 = 'numeric',
                                 流通市值 = 'numeric',
                                 总市值 = 'numeric'))
}) %>% rbindlist()
stopCluster(cl)

dt[, ":="(
    换手率 = NULL
    )]
colnames(dt) <- c('TradingDay','stockID','stockName',
                  'open','high','low','close','preClose',
                  'chg','pchg',
                  'volume','turnover','mcap','tcap')
dt[, stockName := gsub(' ', '', stockName)]

mysqlWrite(db = 'china_stocks', tbl = 'daily_from_163',
           data = dt, isTruncated = T)
## =============================================================================

if (F) {
    # dt <- mysqlQuery(db = 'china_stocks',
    #                  query = 'select * from daily_from_163
    #                          order by TradingDay, stockID')
    destFile <- '/home/fl/myData/data/ChinaStocks/Bar/163_bar.csv'
    fwrite(dt, destFile)
}
