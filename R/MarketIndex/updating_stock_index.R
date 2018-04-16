## =============================================================================
## updating_stocks_index.R
## 每日更新 股票市场指数 数据
## 
## AUTHOR   : fl@hicloud-investment.com
## DATE     : 2018-04-15
## =============================================================================


suppressMessages({
    suppressMessages({
        source("/home/fl/myData/R/Rconfig/myInit.R")
    })
})

## =============================================================================
## from 163
allIndex <- mysqlQuery(db = 'china_stocks_info',
                       query = 'select * from index_list
                                order by indexID')
pb <- txtProgressBar(min = 1, max = nrow(allIndex), style = 1)
cat("\n开始下载 163 股票市场指数 数据.\n")
dt163 <- lapply(1:nrow(allIndex), function(i){
    setTxtProgressBar(pb, i)

    tmp <- allIndex[i]
    res <- fetch_market_index_from_163_updating(tmp[1, indexID])
}) %>% rbindlist()
cat("\n完成下载 163 股票市场指数 数据.\n")

mysqlWrite(db = 'market_index', tbl = 'stocks_index',
           data = dt163)
## =============================================================================

if (F) {
    ## 下载历史数据
    cl <- makeCluster(4, type = "FORK")
    parSapply(cl, 1:nrow(allIndex), function(i){
        tmp <- allIndex[i]
        fetch_market_index_from_163_historical(
            indexID = tmp[1, indexID],
            exchID = tmp[1, exchID],
            startDate = '1990-01-01')
    })
    stopCluster(cl)

    ## =========================================================================
    DATA_PATH <- "/home/fl/myData/data/MarketIndex/stocks_index/from163"
    dataFiles <- list.files(DATA_PATH)
    dt <- lapply(dataFiles, function(f){
      f <- paste0(DATA_PATH, '/', f)
      res <- fread(f, colClasses = c(指数代码="character")) %>% 
        .[, ":="(成交量 = as.numeric(成交量),
                 成交金额 = as.numeric(成交金额))]
    }) %>% rbindlist()
    dt <- dt[, .(日期, 指数代码, 名称,
                 开盘价, 最高价, 最低价, 收盘价,
                 成交量, 成交金额)]
    colnames(dt) <- c('TradingDay','indexID','indexName',
                      'open','high','low','close',
                      'volume','turnover')
    ## =========================================================================

    ## =========================================================================
    mysqlWrite(db = 'market_index', tbl = 'stocks_index',
               data = dt)
    ## =========================================================================

}


## =============================================================================
## SW 申万行业指数
dtSW1 <- fetch_market_data_from_sw()
mysqlWrite(db = 'market_index', tbl = 'sw1_index',
           data = dtSW1)

if (F) {
    # "2000-02-01" ## 开始日期
    dtSW1 <- fetch_market_data_from_sw(startDate = "2000-02-01",
                                       endDate = Sys.Date())
    mysqlWrite(db = 'market_index', tbl = 'sw1_index',
               data = dtSW1)
}
## =============================================================================
