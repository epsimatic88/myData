## =============================================================================
## updating_dzjy.R
## 每日更新 股票大宗交易 数据
## 
## AUTHOR   : fl@hicloud-investment.com
## DATE     : 2018-04-15
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

fetch_dzjy_data_from_exch()
