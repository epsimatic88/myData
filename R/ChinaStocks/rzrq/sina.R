## =============================================================================
## sina.R
## 从新浪财经下载 融资融券 数据
## 
## DATE     : 2018-03-05
## AUTHOR   : fl@hicloud-investment.com
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
library(httr)
# options(width = 200)

fetch_rzrq_data <- function(tradingDay) {
    # tradingDay <- '2018-02-27'
    # print(tradingDay)
    URL <- "http://vip.stock.finance.sina.com.cn/q/go.php/vInvestConsult/kind/rzrq/index.phtml"
    payload <- list(tradedate = tradingDay)
    r <- GET(URL, query = payload)
    p <- content(r, as = 'text', encoding = 'GB18030')

    webData <- p %>%
        read_html(encoding = 'GB18030') %>%
        html_nodes('#dataTable') %>%
        html_table(fill = T) %>% 
        .[[2]] %>% 
        as.data.table()

    if (nrow(webData) < 30) {
        print("数据找不到")
        return(NA)
    }

    colnames(webData) <- paste0("X", 1:ncol(webData))

    cols <- colnames(webData)[3:ncol(webData)]
    webData[, (cols) := lapply(.SD, function(x){
              gsub(",", "", x)
            }), .SDcols = cols]
    webData <- webData[!grep("交易明细|序号", X1)]
    webData[, X1 := NULL]

    colnames(webData) <- c("股票代码","股票名称",
                           "融资余额(元)","融资买入额(元)","融资偿还额(元)",
                           "融券余量金额(元)","融券余量(股)","融券卖出量(股)",
                           "融券偿还量(股)","融资融券余额(元)")
    return(webData)
}

## 融资融券业务于 2010-03-31 正式开始实行
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2010-03-31'][days < Sys.Date()]
## =============================================================================
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/RZRQ/FromSina/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    tempFile <- paste0(tempPath, "/", tradingDay, ".csv")
    if (file.exists(tempFile)) {
        print("数据已下载")
        next
    }

    dt <- fetch_rzrq_data(tradingDay)
    if (!is.na(dt)) {
        print(dt)
        fwrite(dt, tempFile)
        Sys.sleep(10)
    }
}
## =============================================================================
