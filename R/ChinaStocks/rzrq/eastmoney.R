## =============================================================================
## eastmoney.R
## 从东方财富下载 融资融券 数据
## 
## DATE     : 2018-03-05
## AUTHOR   : fl@hicloud-investment.com
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
library(httr)
library(rjson)
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2000-01-01']
options(width = 200)

fetch_rzrq_data <- function(tradingDay) {
    url <- "http://dcfm.eastmoney.com/em_mutisvcexpandinterface/api/js/get"
    payload <- list(
        type   = "RZRQ_DETAIL_NJ"
        ,token  = "70f12f2f4f091e459a279469fe49eca5"
        ,filter = paste0("(tdate='", tradingDay, "')")
        # ,st     = "rzjmre"
        # ,sr     = "-1"
        ,p      = "1"
        ,ps     = "100000"
        # ,js     = "var voaKXrYn={pages:(tp),data:(x)}"
        # ,time   = "1"
        # ,rt     = "50665418"
        )
    r <- GET(url, query = payload)
    p <- content(r, as = 'parsed')
    info <- gsub('.*data:(.*)\\}\\]\\}', "\\1\\}\\]", p) %>% fromJSON(.)
    if (length(info) == 0) {
        print("找不到数据")
        return(data.table())
    }

    webData <- lapply(info, as.data.table) %>% rbindlist() %>% 
        .[, .(scode, sname, 
              rzye, rzmre, rzche, rzjmre,
              rqye, rqyl, rqmcl, rqchl, rqjmcl,
              rzrqye, rzrqyecz)]
    colnames(webData) <- c("股票代码", "股票名称", 
                           "融资余额(元)", "融资买入额(元)", "融资偿还额(元)", "融资净买入(元)", 
                           "融券余额(元)", "融券余量(股)", "融券卖出量(股)", "融券偿还量(股)", "融券净卖出(股)", 
                           "融资融券余额(元)", "融资融券余额差值(元)")
    return(webData)

    ## =========================================================================
    # var tablelist = new LoadTable({
    #     id: "rzrqjymxTable",
    #     sort: { id: "rzjmre", desc: true },
    #     cells: [{ "n": "序号", "w": 40 },
    #             { "n": "证券<br />代码", "s": "scode", "w": 45 },
    #             { "n": "证券简称", "w": 50 },
    #             { "n": "收盘价(元)", "s": "close", "w": 45 },
    #             { "n": "涨跌幅(%)", "s": "zdf", "w": 45 },
    #             { "n": "相关", "w": 40 },
    #             {
    #                 "n": "融资",
    #                 cells: [
    #                     { "n": "余额(元)", "s": "rzye", "w": 50 },
    #                     { "n": "余额占流通市值比", "s": "rzyezb", "w": 50 },
    #                     { "n": "买入额(元)", "rzmre": "7" },
    #                     { "n": "偿还额(元)", "rzche": "8" },
    #                     { "n": "净买入(元)", "rzjmre": "9" }
    #                 ]
    #             },
    #             {
    #                 "n": "融券",
    #                 cells: [
    #                     { "n": "余额(元)", "s": "rqye" },
    #                     { "n": "余量(股)", "s": "rqyl" },
    #                     { "n": "卖出量(股)", "s": "rqmcl" },
    #                     { "n": "偿还量(股)", "s": "rqchl" },
    #                     { "n": "净卖出(股)", "s": "rqjmcl" }
    #                 ]
    #             },
    #             { "n": "融资融券余额(元)", "s": "rzrqye", "w": 50 },
    #             { "n": "融资融券余额差值(元)", "s": "rzrqyecz", "w": 50 }],
    ## =========================================================================

}

## 融资融券业务于 2010-03-31 正式开始实行
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2010-03-31'][days < Sys.Date()]
## =============================================================================
while (T) {
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/RZRQ/FromEastmoney/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    tempFile <- paste0(tempPath, "/", tradingDay, ".csv")
    if (file.exists(tempFile)) {
        print("数据已下载")
        next
    }

    ## -------------------------------------------------------------------------
    if (any(class(try(
              dt <- fetch_rzrq_data(tradingDay)
              ))  == 'try-error')) {
        # ChinaStocksCalendar <- ChinaStocksCalendar[days >= tradingDay]
        Sys.sleep(60)
    } else if (nrow(dt) != 0) {
        cat("\n")
        print(dt)
        cat("\n")
        fwrite(dt, tempFile)
        Sys.sleep(5)
    }
    ## -------------------------------------------------------------------------

}
}
## =============================================================================


