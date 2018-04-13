## =============================================================================
## updating_lhb.R
## 每日更新 股票龙虎榜 数据
## 
## AUTHOR   : fl@hicloud-investment.com
## DATE     : 2018-04-12
## =============================================================================

suppressMessages({
    suppressMessages({
        source("/home/fl/myData/R/Rconfig/myInit.R")
    })
})

## ----------------------------------
## 18:00 更新数据
tradingDay <- lastTradingDay[1, days]
## ----------------------------------


## =======================
fetch_lhb_data(tradingDay)
## =======================

if (F) {
    for (tradingDay in ChinaStocksCalendar[days >= '2018-01-01' &
                                           days <= Sys.Date()-1, days]) {
        print(tradingDay)
        fetch_lhb_data(tradingDay)
    }

    ## -----------------------------------------------------
    ## 把历史数据补充到数据表
    ## ------------------
    dt <- mysqlQuery(db = 'china_stocks',
                     query = 'select * from lhb_from_exch')
    dt[, ":="(
      buyAmount = ifelse(is.na(buyAmount), -1, buyAmount),
      sellAmount = ifelse(is.na(sellAmount), -1, sellAmount)
      )]
    mysqlWrite(db = 'china_stocks_bar', tbl = 'lhb',
               data = dt)
    ## -----------------------------------------------------

}
