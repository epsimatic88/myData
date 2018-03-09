## =============================================================================
## sina.R
## 从新浪财经下载 龙虎榜 数据
## 
## DATE     : 2018-03-05
## AUTHOR   : fl@hicloud-investment.com
## =============================================================================

source("/home/fl/myData/R/Rconfig/myInit.R")
library(httr)
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2000-01-01']
options(width = 200)


sinaClass <- data.table(className = c("涨幅偏离值达7%的证券", "跌幅偏离值达7%的证券",
                                      "振幅值达15%的证券", "换手率达20%的证券",
                                      "连续三个交易日内，涨幅偏离值累计达20%的证券",
                                      "连续三个交易日内，跌幅偏离值累计达20%的证券",
                                      "连续三个交易日内，涨幅偏离值累计达到15%的ST证券、*ST证券和未完成股改证券", # 07
                                      "连续三个交易日内，跌幅偏离值累计达到15%的ST证券、*ST证券和未完成股改证券", # 08
                                      "连续三个交易日内，日均换手率与前五个交易日的日均换手率的比值达到30倍，且换手率累计达20%的股票", # 09
                                      "无价格涨跌幅限制的证券", # 11
                                      "连续三个交易日收盘价达到涨幅限制价格的ST证券、*ST证券和未完成股改证券", # 15
                                      "连续三个交易日收盘价达到跌幅限制价格的ST证券、*ST证券和未完成股改证券", # 16
                                      "当日无价格涨跌幅限制的股票,其盘中交易价格较当日开盘价上涨100%以上的股票", # 17
                                      "当日有涨跌幅限制的A股,连续2个交易日触及涨幅限制,在这2个交易日中同一营业部净买入股数占当日总成交股数的比重30%以上,且上市公司未有重大事项公告的股票", # 19
                                      "当日有涨跌幅限制的A股,连续2个交易日触及跌幅限制,在这2个交易日中同一营业部净卖出股数占当日总成交股数的比重30%以上,且上市公司未有重大事项公告的股票", # 20
                                      "ST股票、*ST股票和S股连续三个交易日触及涨(跌)幅限制的股票", # 21
                                      "ST股票、*ST股票和S股连续三个交易日触及涨幅限制的股票", # 22
                                      "ST股票、*ST股票和S股连续三个交易日触及跌幅限制的股票", # 23
                                      "连续三个交易日内，涨幅偏离值累计达到12%的ST证券、*ST证券和未完成股改证券", # 24
                                      "连续三个交易日内，跌幅偏离值累计达到12%的ST证券、*ST证券和未完成股改证券", # 25
                                      "当日无价格涨跌幅限制的股票，其盘中交易价格较当日开盘价上涨30%以上的股票", # 26
                                      "当日无价格涨跌幅限制的股票，其盘中交易价格较当日开盘价下跌30%以上的股票", # 27
                                      "单只标的证券的当日融资买入数量达到当日该证券总交易量的50%以上", # 28
                                      ""),
                        classID = c('01','02',
                                    '03','04',
                                    '05','06',
                                    '07', '08', '09',
                                    '11',
                                    '15', '16', '17', '19', '20', '21',
                                    '22', '23', '24', '25', '26', '27', '28', '33' ## 退市
                                    ))


fetch_stocks_info <- function(tradingDay) {
    # tradingDay <- '2018-02-27'
    # print(tradingDay)

    URL <- "http://vip.stock.finance.sina.com.cn/q/go.php/vInvestConsult/kind/lhb/index.phtml"
    payload <- list(tradedate = tradingDay)
    r <- GET(URL, query = payload)
    p <- content(r, as = 'text', encoding = 'GB18030')
    tbls <- p %>%
        read_html(encoding = 'GB18030') %>%
        html_nodes('#dataTable') %>%
        html_table(fill = T)
    if (length(tbls) == 0) return(data.table())

    ##　获取股票代码和名称
    stockData <- lapply(1:length(tbls), function(i){
        res <- tbls[i] %>%
            as.data.table() %>%
            .[grep("[0-9]{6}", X2)] %>%  ## 获取股票代码
            .[, .(X2, X3)]
    }) %>% rbindlist()
    colnames(stockData) <- c("stockID", "stockName")

    ## 获取网页数据
    webData <- lapply(1:length(tbls), function(i){
        res <- tbls[i] %>%
            as.data.table() %>%
            .[grep("上榜原因", X1)]
    }) %>% rbindlist()

    ## 清理数据
    infoData <- lapply(1:nrow(webData), function(i){
        temp <- webData[i,X1]
        temp <- unlist(strsplit(temp, "\\r\\n"))
        u <- grep("上榜原因", temp, value = T) %>%
               gsub("上榜原因：|\\s", "", .)
        v <- grep("查看.*股票行情", temp, value = T) %>%
               gsub("查看|股票行情|\\s", "", .)
        res <- data.table(stockName = v,
                          className = u)
    }) %>% rbindlist()

    ## 得到新浪查询的关键字段
    res <- merge(infoData, stockData, by = 'stockName',
                 all.x = T, allow.cartesian=TRUE) %>%
           .[!duplicated(.)] %>%
           merge(., sinaClass, by = 'className', all.x = T) %>%
           .[, .(stockID, stockName, classID, className)] %>%
           .[!is.na(stockID)]
    return(res)
}

getValue <- function(x, info) {
    # x <- "SYMBOL"
    temp <- grep(x, info, value = T)
    u <- strsplit(temp, ":") %>% unlist()
    v <- gsub("\"", "", u)
    return(v[2])
}

## =============================================================================
## 用于测试 className 和 classID
## 新浪财经需要传递的参数: classID
if (F) {
    for (d in 1:nrow(ChinaStocksCalendar)) {
        tradingDay <- ChinaStocksCalendar[d, days]
        print(tradingDay)

        infoData <- fetch_stocks_info(tradingDay)
        if (nrow(infoData) == 0) next

        ## ---------------------------------------------------------------------
        for (i in 1:nrow(infoData)) {
            if (! infoData[i, className] %in% sinaClass$className) {
                print(infoData[i])
                print('hello')
                print(tradingDay)
                ChinaStocksCalendar <- ChinaStocksCalendar[days >= tradingDay]
                stop("hello")
            }
        }
        ## ---------------------------------------------------------------------
    }
}
## =============================================================================

## =============================================================================

fetch_lhb_data <- function(tradingDay) {

    # tradingDay <- '2018-02-27'
    # print(tradingDay)
    infoData <- fetch_stocks_info(tradingDay)

    if (nrow(infoData) == 0) {
        print("找不到数据")
        return(data.table())
    }

    pb <- txtProgressBar(min = 0, max = nrow(infoData), style = 3)
    dt <- lapply(1:nrow(infoData), function(i){
        # print(i)
        setTxtProgressBar(pb, i)
        payload <- list(symbol = infoData[i,stockID],
                        tradedate = tradingDay,
                        type = infoData[i, classID])
        url <- 'http://vip.stock.finance.sina.com.cn/q/api/jsonp.php/var%20details=/InvestConsultService.getLHBComBSData'
        r <- GET(url, query = payload)
        p <- content(r, as = 'text', encoding = 'GB18030')

        buyInfo <- gsub(".*buy:(.*),sell:.*", "\\1", p)
        # print(buyInfo)

        sellInfo <- gsub(".*sell:(.*)\\}\\)\\)", "\\1", p)
        # print(sellInfo)

        buyInfo <- strsplit(buyInfo, '\\},\\{|\\[\\{|\\}\\]\\}\\)\\)') %>%
                unlist() %>%
                grep('SYMBOL', ., value = T) %>%
                gsub("\\}\\]", "", .)
        sellInfo <- strsplit(sellInfo, '\\},\\{|\\[\\{|\\}\\]\\}\\)\\)') %>%
                unlist() %>%
                grep('SYMBOL', ., value = T) %>%
                gsub("\\}\\]", "", .)

        if (length(buyInfo) == 0) {
            dtBuy <- data.table()
        } else {
            dtBuy <- lapply(buyInfo, function(x){
                temp <- strsplit(x, ",") %>% unlist()

                res <- data.table(
                    stockID = getValue("SYMBOL", temp),
                    stockName = infoData[i, stockName],
                    classID = getValue("type", temp),
                    className = infoData[i, className],
                    BranchID = getValue("comCode", temp),
                    DeptName = getValue("comName", temp),
                    buyAmount = getValue("buyAmount", temp),
                    sellAmount = getValue("sellAmount", temp),
                    netAmount = getValue("netAmount", temp))
            }) %>% rbindlist()
            dtBuy[, ":="(
                    buyAmount = as.numeric(buyAmount) * 10000,
                    sellAmount = as.numeric(sellAmount) * 10000,
                    netAmount = as.numeric(netAmount) * 10000
                )]
        }

        if (length(sellInfo) == 0) {
            dtSell <- data.table()
        } else {
            dtSell <- lapply(sellInfo, function(x){
                temp <- strsplit(x, ",") %>% unlist()

                res <- data.table(
                    stockID = getValue("SYMBOL", temp),
                    stockName = infoData[i, stockName],
                    classID = getValue("type", temp),
                    className = infoData[i, className],
                    DeptID = getValue("comCode", temp),
                    DeptName = getValue("comName", temp),
                    buyAmount = getValue("buyAmount", temp),
                    sellAmount = getValue("sellAmount", temp),
                    netAmount = getValue("netAmount", temp))
            }) %>% rbindlist()
            dtSell[, ":="(
                    buyAmount = as.numeric(buyAmount) * 10000,
                    sellAmount = as.numeric(sellAmount) * 10000,
                    netAmount = as.numeric(netAmount) * 10000
                )]
        }

        dt <- list(dtBuy, dtSell) %>% rbindlist() %>%
            .[!duplicated(.)]

        return(dt)
    }) %>% rbindlist()

    ## -------------------------------------------------------------------------
    dt[, ":="(classID = NULL, DeptID = NULL)]
    colnames(dt) <- c("股票代码", "股票名称", "上榜原因", "营业部名称",
                      "买入金额(元)", "卖出金额(元)", "净额(元)")
    ## -------------------------------------------------------------------------

    return(dt)
}
## =============================================================================

## 2004 年之后才有 龙虎榜 数据
ChinaStocksCalendar <- ChinaStocksCalendar[days >= '2004-01-01'][days < Sys.Date()]
## =============================================================================
while (T) {
for (i in 1:nrow(ChinaStocksCalendar)) {
    tradingDay <- ChinaStocksCalendar[i, days]
    print(tradingDay)

    tempYear <- substr(tradingDay, 1, 4)
    tempPath <- paste0("/home/fl/myData/data/ChinaStocks/LHB/FromSina/", tempYear)
    if (!dir.exists(tempPath)) dir.create(tempPath, recursive = T)

    tempFile <- paste0(tempPath, "/", tradingDay, ".csv")
    if (file.exists(tempFile)) {
        print("数据已下载")
        next
    }

    ## -------------------------------------------------------------------------
    if (any(class(try(
              dt <- fetch_lhb_data(tradingDay)
              ))  == 'try-error')) {
        # ChinaStocksCalendar <- ChinaStocksCalendar[days >= tradingDay]
        Sys.sleep(100)
    } else if (nrow(dt) != 0) {
        cat("\n")
        print(dt)
        cat("\n")
        fwrite(dt, tempFile)
        Sys.sleep(10)
    }
    ## -------------------------------------------------------------------------

}
}
## =============================================================================
